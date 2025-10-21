-- File: src/server/Services/WeaponService.lua
--!strict
-- WeaponService.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = ReplicatedStorage:WaitForChild("Events")
local EVT_FIRE = Events:WaitForChild("Weapon:Fire:v1")
local EVT_HIT  = Events:WaitForChild("Weapon:Hit:v1")

local Shared = ReplicatedStorage:WaitForChild("Shared")
-- FIX: Config es un módulo único (no carpeta con submódulo Weapon)
local ConfigWeapon = require(Shared:WaitForChild("Config"))

export type RoundState = "WAITING" | "PREPARE" | "COUNTDOWN" | "ACTIVE" | "ROUND_END"

local M = {}
local roundState: RoundState = "WAITING"

-- cooldowns por jugador
local lastShot: {[number]: number} = {}

local function canFire(plr: Player, weaponName: string): (boolean, number)
	local now = time()
	local cfg = ConfigWeapon[weaponName]
	local cooldown = (cfg and cfg.cooldown) or 0.4
	local t0 = lastShot[plr.UserId] or 0
	if now - t0 < cooldown then
		return false, cooldown - (now - t0)
	end
	return true, 0
end

local function getFovDeg(weaponName: string): number
	local cfg = ConfigWeapon[weaponName]
	return (cfg and cfg.fovCheckDeg) or 20
end

local function resolveDamage(weaponName: string, hitPartName: string): number
	local cfg = ConfigWeapon[weaponName]
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

function M.setRoundState(s: RoundState)
	roundState = s
end

local function applyDamage(target: Instance, dmg: number)
	local model = target:FindFirstAncestorOfClass("Model")
	if not model then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum:TakeDamage(dmg)
end

function M.start()
	print("[WEAPON] start()")
	EVT_FIRE.OnServerEvent:Connect(function(plr: Player, payload: any)
		if roundState ~= "ACTIVE" then return end

		local weaponName = (payload and payload.weapon) or "Deagle"
		local ok = canFire(plr, weaponName)
		if not ok then return end

		local hitPart, hitPos = serverRaycastFromPlr(plr, 1000)
		if not hitPart then
			lastShot[plr.UserId] = time()
			EVT_HIT:FireClient(plr, false, hitPos)
			return
		end

		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local fov = getFovDeg(weaponName)
		if hrp and not isWithinFOV(hrp.CFrame, hitPos, fov) then
			lastShot[plr.UserId] = time()
			EVT_HIT:FireClient(plr, false, hitPos)
			return
		end

		applyDamage(hitPart, resolveDamage(weaponName, hitPart.Name))
		lastShot[plr.UserId] = time()
		EVT_HIT:FireClient(plr, true, hitPos)
	end)
end

return M
