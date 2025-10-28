-- File: src/server/Main.server.lua
--!strict
-- Server único: Health + Weapon + Round
-- Lee armas desde Config.Weapon[<name>]
-- Lee tiempos desde Config.Round.time
-- Usa 'time()' para endsAt y cooldowns

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--// Shared & Config
local Shared = ReplicatedStorage:FindFirstChild("Shared") or Instance.new("Folder", ReplicatedStorage)
Shared.Name = "Shared"
local Config = require(Shared:WaitForChild("Config"))

--// Ensure Events/Remotes (autoprovision robusto)
local Events = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder", ReplicatedStorage)
Events.Name = "Events"
local Remotes = Events:FindFirstChild("Remotes") or Instance.new("Folder", Events)
Remotes.Name = "Remotes"

local function ensureRemote(name: string): RemoteEvent
	local ev = Remotes:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then
		return ev
	end
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = Remotes
	return r
end

local EVT_ROUND_STATE = ensureRemote("Round:State")
local EVT_FIRE        = ensureRemote("Weapon:Fire:v1")
local EVT_HIT         = ensureRemote("Weapon:Hit:v1")

--// Tipos
type RoundState = "PREPARE" | "COUNTDOWN" | "ACTIVE" | "END"

--// ---------------- Health ----------------
local MAX_HP = 100

local function getHumanoid(p: Player): Humanoid?
	local char = p.Character or p.CharacterAdded:Wait()
	return char:FindFirstChildOfClass("Humanoid") :: Humanoid?
end

local function resetAllHealth()
	for _, p in ipairs(Players:GetPlayers()) do
		local hum = getHumanoid(p)
		if hum then
			hum.MaxHealth = MAX_HP
			hum.Health = MAX_HP
		end
	end
end

local function applyDamageToInstance(targetPart: Instance, amount: number)
	local model = targetPart:FindFirstAncestorOfClass("Model")
	if not model then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum:TakeDamage(math.max(0, amount))
end

--// ---------------- Weapon ----------------
local roundState: RoundState = "PREPARE"
local lastShot: {[number]: number} = {}

local function getWeaponCfg(weaponName: string)
	local w = (Config and Config.Weapon and Config.Weapon[weaponName]) or nil
	return w
end

local function canFire(plr: Player, weaponName: string): (boolean, number)
	local now = time()
	local cfg = getWeaponCfg(weaponName)
	local cooldown = (cfg and cfg.cooldown) or 0.4
	local t0 = lastShot[plr.UserId] or 0
	if now - t0 < cooldown then
		return false, cooldown - (now - t0)
	end
	return true, 0
end

local function resolveDamage(weaponName: string, hitPartName: string): number
	local cfg = getWeaponCfg(weaponName)
	if not cfg then return 60 end

	-- Tabla de daños detallados
	if type(cfg.damage) == "table" then
		if hitPartName == "Head" then
			return cfg.damage.head or 120
		end
		if hitPartName == "UpperTorso" or hitPartName == "LowerTorso" or hitPartName == "HumanoidRootPart" then
			return cfg.damage.torso or 60
		end
		return cfg.damage.limb or 40
	end

	-- Esquema base + multiplicador
	local base = cfg.baseDamage or 60
	local mult = cfg.headshotMultiplier or 2
	if hitPartName == "Head" then
		return base * mult
	end
	return base
end

local function getFovDeg(weaponName: string): number
	local cfg = getWeaponCfg(weaponName)
	return (cfg and cfg.fovCheckDeg) or 20
end

local function isWithinFOV(shooterCF: CFrame, targetPos: Vector3, fovDeg: number): boolean
	local look = shooterCF.LookVector
	local dir = (targetPos - shooterCF.Position)
	if dir.Magnitude <= 0.001 then return true end
	dir = dir.Unit
	local dot = look:Dot(dir)
	local cosHalf = math.cos(math.rad(fovDeg) / 2)
	return dot >= cosHalf
end

local function serverRaycastFromPlr(plr: Player, maxDistance: number?): (Instance?, Vector3)
	maxDistance = maxDistance or 1000
	local char = plr.Character
	if not char then return nil, Vector3.new() end

	local head = char:FindFirstChild("Head") :: BasePart?
	local hrp  = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not head or not hrp then return nil, Vector3.new() end

	local origin = head.Position
	local dir = hrp.CFrame.LookVector * maxDistance

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {char}

	local rc = Workspace:Raycast(origin, dir, params)
	if rc then
		return rc.Instance, rc.Position
	end
	return nil, origin + dir
end

local function setRoundStateWeapon(s: RoundState)
	roundState = s
end

EVT_FIRE.OnServerEvent:Connect(function(plr: Player, payload: any)
	if roundState ~= "ACTIVE" then return end
	local weaponName = (payload and payload.weapon) or "Deagle"

	local ok = select(1, canFire(plr, weaponName))
	if not ok then return end

	local hitPart, hitPos = serverRaycastFromPlr(plr, 1000)
	lastShot[plr.UserId] = time()

	if not hitPart then
		EVT_HIT:FireClient(plr, false, hitPos)
		return
	end

	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local fov = getFovDeg(weaponName)
	if hrp and not isWithinFOV(hrp.CFrame, hitPos, fov) then
		EVT_HIT:FireClient(plr, false, hitPos)
		return
	end

	local dmg = resolveDamage(weaponName, hitPart.Name)
	applyDamageToInstance(hitPart, dmg)
	EVT_HIT:FireClient(plr, true, hitPos)
end)

--// ---------------- Round FSM ----------------
local currentState: RoundState = "PREPARE"
local endsAt: number? = nil

local function readRoundTimes()
	local t = (Config and Config.Round and Config.Round.time) or {}
	return {
		prepare  = tonumber(t.prepare)  or 3,
		countdown= tonumber(t.countdown)or 3,
		active   = tonumber(t.active)   or 45,
		roundEnd = tonumber(t.roundEnd) or 3,
		inter    = tonumber(t.inter)    or 2,
	}
end

local function broadcastRound(state: RoundState, endsAtTime: number?)
	EVT_ROUND_STATE:FireAllClients({
		state = state,
		endsAt = endsAtTime,
	})
end

local function setRoundState(state: RoundState, dur: number?)
	currentState = state
	if dur and dur > 0 then
		endsAt = time() + dur
	else
		endsAt = nil
	end
	setRoundStateWeapon(state)
	broadcastRound(currentState, endsAt)
end

local function getSpawnCF(name: string): CFrame
	local spawns = Workspace:FindFirstChild("Spawns")
	if not spawns then return CFrame.new(0, 5, 0) end
	local p = spawns:FindFirstChild(name)
	if p and p:IsA("BasePart") then
		return p.CFrame + Vector3.new(0, 4, 0)
	end
	return CFrame.new(0, 5, 0)
end

local function tpAllToLobby()
	local cf = getSpawnCF("Lobby")
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character or plr.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
		hrp.CFrame = cf
	end
end

local function tpAlternatingTracks()
	local useA = true
	for _, plr in ipairs(Players:GetPlayers()) do
		local cf = getSpawnCF(useA and "TrackA" or "TrackB")
		useA = not useA
		local char = plr.Character or plr.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
		hrp.CFrame = cf
	end
end

local function roundLoop()
	while true do
		local T = readRoundTimes()

		-- PREPARE
		resetAllHealth()
		tpAllToLobby()
		setRoundState("PREPARE", T.prepare)
		task.wait(T.prepare)

		-- COUNTDOWN
		tpAlternatingTracks()
		setRoundState("COUNTDOWN", T.countdown)
		task.wait(T.countdown)

		-- ACTIVE
		setRoundState("ACTIVE", T.active)
		task.wait(T.active)

		-- END
		setRoundState("END", T.roundEnd)
		task.wait(T.roundEnd)

		-- INTER (silencio entre rondas)
		task.wait(T.inter)
	end
end

task.spawn(roundLoop)
print("[BOOT][SERVER] único script listo")
