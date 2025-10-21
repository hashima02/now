-- File: src/server/Services/HealthService.lua
--!strict
-- Control simple de salud + cálculo de headshot con Config.Deagle.headshotMultiplier

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local M = {}

local DEFAULT_HP = 100

local function getLeaderstatsHumanoid(player: Player): Humanoid?
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
	return hum
end

function M.resetAll()
	for _, plr in ipairs(Players:GetPlayers()) do
		local hum = getLeaderstatsHumanoid(plr)
		if hum then
			hum.Health = hum.MaxHealth
		end
	end
	print("[HealthService] resetAll OK")
end

function M.applyDamage(targetPlayer: Player, damage: number, isHeadshot: boolean?, weaponName: string?, attacker: Player?)
	local hum = getLeaderstatsHumanoid(targetPlayer)
	if not hum then return end

	local dmg = damage
	-- Por si algún flujo usa directamente el mult desde Config.Deagle:
	if isHeadshot and weaponName == "Deagle" then
		local mult = (Config and Config.Deagle and Config.Deagle.headshotMultiplier) or 2
		-- Si el daño ya venía multiplicado, no volver a multiplicar. Aquí solo ejemplo.
		-- dmg = math.floor(dmg * mult)
		-- En este template asumimos que WeaponService ya aplicó el multiplicador,
		-- así que NO lo duplicamos. Deja la línea comentada como referencia.
	end

	hum:TakeDamage(dmg)
	if hum.Health <= 0 then
		-- Aquí podrías sumar kills/assists, etc.
	end
end

return M
