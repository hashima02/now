--!strict
-- WeaponService.lua
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Events            = ReplicatedStorage:WaitForChild("Events")
local EVT_FIRE          = Events:WaitForChild("Weapon:Fire:v1")
local EVT_HIT           = Events:WaitForChild("Weapon:Hit:v1") -- solo para replicar hitmarkers

local Shared            = ReplicatedStorage:WaitForChild("Shared")
local ConfigWeapon      = require(Shared:WaitForChild("Config"):WaitForChild("Weapon"))

local M = {}

local roundState: "WAITING" | "PREPARE" | "COUNTDOWN" | "ACTIVE" | "ROUND_END" = "WAITING"

-- Cooldowns por jugador/arma
local lastShot: {[number]: number} = {} -- key = player.UserId
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

-- FOV de validación más permisivo
local FOV_DEG = 20 -- (antes ~5, muy estricto)

-- Detección de daño: soporta tu tabla damage.{head,torso,limb} o baseDamage+multiplier
local function resolveDamage(weaponName: string, hitPartName: string): number
	local cfg = ConfigWeapon[weaponName]
	if not cfg then
		return 60 -- fallback MVP
	end

	-- Si existe tabla damage por zona, úsala
	if type(cfg.damage) == "table" then
		if hitPartName == "Head" then
			return cfg.damage.head or 90
		end
		-- torso vs extremidades (por simplicidad)
		if hitPartName == "UpperTorso" or hitPartName == "LowerTorso" or hitPartName == "HumanoidRootPart" then
			return cfg.damage.torso or 60
		end
		return cfg.damage.limb or 40
	end

	-- Si no, usa baseDamage * headshotMultiplier
	local base = cfg.baseDamage or 60
	local mult = cfg.headshotMultiplier or 2
	if hitPartName == "Head" then
		return base * mult
	end
	return base
end

local function isWithinFOV(shooterCF: CFrame, targetPos: Vector3): boolean
	local look = shooterCF.LookVector
	local dir = (targetPos - shooterCF.Position)
	if dir.Magnitude <= 0.001 then
		return true
	end
	dir = dir.Unit
	local dot = look:Dot(dir)
	-- cos(FOV/2)
	local cosHalf = math.cos(math.rad(FOV_DEG) / 2)
	return dot >= cosHalf
end

-- Raycast servidor desde la cabeza del tirador
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

function M.setRoundState(s: any)
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
	-- 🔹 Eliminar listener no-op de Round:State (ya no existe aquí)

	EVT_FIRE.OnServerEvent:Connect(function(plr: Player, payload: any)
		-- payload esperado: { weapon = "Deagle" }
		if roundState ~= "ACTIVE" then
			return
		end
		local weaponName = (payload and payload.weapon) or "Deagle"

		local ok, remain = canFire(plr, weaponName)
		if not ok then
			return
		end

		-- Raycast y validaciones
		local hitPart, hitPos = serverRaycastFromPlr(plr, 1000)
		if not hitPart then
			lastShot[plr.UserId] = time()
			EVT_HIT:FireClient(plr, false, hitPos)
			return
		end

		-- FOV check (contra el punto impactado)
		local char = plr.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and not isWithinFOV(hrp.CFrame, hitPos) then
			-- fuera de FOV permitido
			lastShot[plr.UserId] = time()
			EVT_HIT:FireClient(plr, false, hitPos)
			return
		end

		-- Aplicar daño si corresponde
		local dmg = resolveDamage(weaponName, hitPart.Name)
		applyDamage(hitPart, dmg)

		lastShot[plr.UserId] = time()
		EVT_HIT:FireClient(plr, true, hitPos)
	end)
end

return M
