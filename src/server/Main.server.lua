-- File: ServerScriptService/Main.server.lua
--!strict
-- Unifica: Health + Weapon + Round (FSM)
-- Lee config desde ReplicatedStorage/Shared/Config.lua
-- Usa/crea Remotos en ReplicatedStorage/Events/Remotes

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--// Shared Config
local Shared = ReplicatedStorage:FindFirstChild("Shared") or Instance.new("Folder", ReplicatedStorage)
Shared.Name = "Shared"
local Config = require(Shared:WaitForChild("Config")) -- Deagle, cooldown, daños, FOV, etc.

--// Ensure Events/Remotes exist (autoprovision si faltan)
local Events = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder", ReplicatedStorage)
Events.Name = "Events"
local Remotes = Events:FindFirstChild("Remotes") or Instance.new("Folder", Events)
Remotes.Name = "Remotes"

local EVT_ROUND_STATE = Remotes:FindFirstChild("Round:State") :: RemoteEvent
if not EVT_ROUND_STATE then
	EVT_ROUND_STATE = Instance.new("RemoteEvent")
	EVT_ROUND_STATE.Name = "Round:State"
	EVT_ROUND_STATE.Parent = Remotes
end

local EVT_FIRE = Remotes:FindFirstChild("Weapon:Fire:v1") :: RemoteEvent
if not EVT_FIRE then
	EVT_FIRE = Instance.new("RemoteEvent")
	EVT_FIRE.Name = "Weapon:Fire:v1"
	EVT_FIRE.Parent = Remotes
end

local EVT_HIT = Remotes:FindFirstChild("Weapon:Hit:v1") :: RemoteEvent
if not EVT_HIT then
	EVT_HIT = Instance.new("RemoteEvent")
	EVT_HIT.Name = "Weapon:Hit:v1"
	EVT_HIT.Parent = Remotes
end

--// Tipos
type RoundState = "PREPARE" | "COUNTDOWN" | "ACTIVE" | "END"

--// ---------------- Health (simple) ----------------
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

local function canFire(plr: Player, weaponName: string): (boolean, number)
	local now = time()
	local cfg = Config[weaponName]
	local cooldown = (cfg and cfg.cooldown) or 0.4
	local t0 = lastShot[plr.UserId] or 0
	if now - t0 < cooldown then
		return false, cooldown - (now - t0)
	end
	return true, 0
end

local function resolveDamage(weaponName: string, hitPartName: string): number
	local cfg = Config[weaponName]
	if not cfg then return 60 end

	if type(cfg.damage) == "table" then
		if hitPartName == "Head" then
			return cfg.damage.head or 120
		end
		if hitPartName == "UpperTorso" or hitPartName == "LowerTorso" or hitPartName == "HumanoidRootPart" then
			return cfg.damage.torso or 60
		end
		return cfg.damage.limb or 40
	end

	local base = cfg.baseDamage or 60
	local mult = cfg.headshotMultiplier or 2
	if hitPartName == "Head" then
		return base * mult
	end
	return base
end

local function getFovDeg(weaponName: string): number
	local cfg = Config[weaponName]
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
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
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

-- OnServerEvent handler (único)
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
local ACTIVE_TIME = 60
local COUNTDOWN_TIME = 10
local currentState: RoundState = "PREPARE"
local endsAt: number? = nil

local function broadcastRound(state: RoundState, endsAtTime: number?)
	EVT_ROUND_STATE:FireAllClients({
		state = state,
		endsAt = endsAtTime,
	})
end

local function setRoundState(state: RoundState, dur: number?)
	currentState = state
	if dur and dur > 0 then
		endsAt = tick() + dur
	else
		endsAt = nil
	end
	-- Sync con Weapon
	setRoundStateWeapon(state)
	-- Broadcast
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
		-- PREPARE
		resetAllHealth()
		tpAllToLobby()
		setRoundState("PREPARE")
		task.wait(2)

		-- COUNTDOWN
		tpAlternatingTracks()
		setRoundState("COUNTDOWN", COUNTDOWN_TIME)
		task.wait(COUNTDOWN_TIME)

		-- ACTIVE
		setRoundState("ACTIVE", ACTIVE_TIME)
		task.wait(ACTIVE_TIME)

		-- END
		setRoundState("END")
		task.wait(4)
	end
end

--// Boot
task.spawn(roundLoop)
print("[BOOT][SERVER] único script listo")
