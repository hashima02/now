-- File: src/server/Services/HealthService.lua
--!strict
-- HealthService.lua — HP simple

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
-- FIX: requerir Config directo
local Config = require(Shared:WaitForChild("Config"))

local HealthService = {}
HealthService.__index = HealthService

local MAX_HP = 100

local function ensureChar(p: Player)
	if not p.Character then p.CharacterAdded:Wait() end
end

function HealthService.resetAll()
	for _, p in Players:GetPlayers() do
		ensureChar(p)
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.MaxHealth = MAX_HP
			hum.Health = MAX_HP
		end
	end
end

-- Nota: tu WeaponService ya calcula daño por zona (head/torso/limb).
-- Aquí NO volvemos a aplicar multiplicadores para evitar doble conteo.
function HealthService.applyDamage(target: Player, amount: number, info: {headshot: boolean}? )
	ensureChar(target)
	local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local dmg = math.max(0, amount)

	-- Si quisieras forzar un multiplicador global por arma desde Config:
	-- (ejemplo: Config.Deagle.headshotMultiplier)
	-- if info and info.headshot then
	--     local mult = (Config and Config.Deagle and Config.Deagle.headshotMultiplier) or 2
	--     dmg *= mult
	-- end

	hum:TakeDamage(dmg)
	print(string.format("[HEALTH] %s -%.1f (headshot=%s) -> %.1f",
		target.Name, dmg, tostring(info and info.headshot), hum.Health))
end

return HealthService
