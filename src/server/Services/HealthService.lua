-- File: src/server/Services/HealthService.lua
--!strict
-- Reset de HP y aplicación de daño simple.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local M = {}

local MAX_HP = 100

local function getHumanoid(p: Player): Humanoid?
	local char = p.Character or p.CharacterAdded:Wait()
	return char:FindFirstChildOfClass("Humanoid") :: Humanoid?
end

function M.resetAll()
	for _, p in ipairs(Players:GetPlayers()) do
		local hum = getHumanoid(p)
		if hum then
			hum.MaxHealth = MAX_HP
			hum.Health = MAX_HP
		end
	end
	print("[HealthService] resetAll OK")
end

function M.applyDamage(targetPlayer: Player, amount: number, info: {headshot: boolean}? )
	local hum = getHumanoid(targetPlayer)
	if not hum or hum.Health <= 0 then return end
	local dmg = math.max(0, amount)
	-- Si algún flujo aplicara multiplicador extra, hazlo aquí (no duplicamos porque WeaponService ya resuelve por zona)
	hum:TakeDamage(dmg)
end

return M
