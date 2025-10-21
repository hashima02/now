--!strict
-- File: src/server/Services/WeaponService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local ServicesFolder    = script.Parent
local RoundService      = require(ServicesFolder:WaitForChild("RoundService"))
local HealthService     = require(ServicesFolder:WaitForChild("HealthService"))

-- Contracts opcional
local Contracts = nil
pcall(function()
	Contracts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Contracts"))
end)

-- Config opcional (para tomar el rango del arma)
local Config = nil
pcall(function()
	Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
end)

local REMOTES = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local EVT_WEAPON_FIRE = (Contracts and Contracts.Events and Contracts.Events.WeaponFireV1) and Contracts.Events.WeaponFireV1 or "Weapon:Fire:v1"
local EVT_WEAPON_HIT  = (Contracts and Contracts.Events and Contracts.Events.WeaponHitV1)  and Contracts.Events.WeaponHitV1  or "Weapon:Hit:v1"

local WeaponFireRE = REMOTES:FindFirstChild(EVT_WEAPON_FIRE)
local WeaponHitRE  = REMOTES:FindFirstChild(EVT_WEAPON_HIT)
assert(WeaponFireRE and WeaponFireRE:IsA("RemoteEvent"), "[WeaponService] RemoteEvent '"..EVT_WEAPON_FIRE.."' no encontrado")
assert(WeaponHitRE  and WeaponHitRE:IsA("RemoteEvent"),  "[WeaponService] RemoteEvent '"..EVT_WEAPON_HIT.."' no encontrado")

local M = {}

-- Estado local para habilitar/bloquear disparos según la ronda
local allowFire = false
function M.setRoundState(s: "PREPARE" | "COUNTDOWN" | "ACTIVE" | "POST")
	allowFire = (s == "ACTIVE")
end

local function isHead(part: BasePart?): boolean
	if not part then return false end
	return part.Name:lower():find("head") ~= nil
end

local function doServerRay(origin: Vector3, direction: Vector3, ignore: {Instance})
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	return Workspace:Raycast(origin, direction, params)
end

local function getRange(): number
	-- Usa tu config si existe (ajusta la ruta al arma que estés usando)
	if Config and Config.Weapon and Config.Weapon.Deagle and typeof(Config.Weapon.Deagle.rangeStuds) == "number" then
		return Config.Weapon.Deagle.rangeStuds
	end
	return 300 -- fallback razonable
end

function M.start()
	print("[WeaponService] start()")

	-- inicia el flag según el estado actual
	if RoundService and RoundService.getState then
		M.setRoundState(RoundService.getState() :: any)
	end

	WeaponFireRE.OnServerEvent:Connect(function(player: Player, payload)
		-- payload esperado: {origin:Vector3, dir:Vector3 (unit), range:number?}
		if not allowFire then return end

		if typeof(payload) ~= "table" then return end
		local origin = payload.origin
		local dir    = payload.dir
		local range  = payload.range
		if typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" then return end

		-- normaliza por si vienen magnitudes distintas de 1
		if dir.Magnitude < 0.99 or dir.Magnitude > 1.01 then
			dir = dir.Unit
		end

		range = (typeof(range) == "number" and range or getRange())

		local char = player.Character
		if not char then return end

		local result = doServerRay(origin, dir * range, {char})

		if result and result.Instance then
			local hitPart: BasePart = result.Instance
			local hitPos: Vector3   = result.Position
			local targetModel = hitPart:FindFirstAncestorOfClass("Model")
			local isHS = isHead(hitPart)

			local damage = isHS and 100 or 35
			local killed = false
			local targetId: number? = nil

			if targetModel then
				-- intenta mapear a jugador objetivo
				local targetHum = targetModel:FindFirstChildOfClass("Humanoid")
				local targetPlr = targetHum and game.Players:GetPlayerFromCharacter(targetModel) or nil
				targetId = targetPlr and targetPlr.UserId or nil
				killed = HealthService.applyDamage(targetModel, damage)
			end

			WeaponHitRE:FireAllClients({
				from = player.UserId,
				target = targetId,    -- ✅ para HUD/FX (marcador de impacto/killfeed)
				at = hitPos,          -- ✅ posición exacta del impacto
				part = hitPart.Name,
				isHeadshot = isHS,
				damage = damage,
				killed = killed,
			})
		else
			-- “fallo”: manda punto máximo para trazar líneas/bullet holes client
			WeaponHitRE:FireAllClients({
				from = player.UserId,
				target = nil,
				at = origin + dir * range,
				part = "None",
				isHeadshot = false,
				damage = 0,
				killed = false,
			})
		end
	end)
end

return M
