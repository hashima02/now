--!strict
-- HealthService.lua — HP simple + señal a RoundService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local HealthService = {}
HealthService.__index = HealthService

local MAX_HP = 100

local function ensureChar(p: Player)
	if not p.Character then
		p.CharacterAdded:Wait()
	end
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

function HealthService.applyDamage(target: Player, amount: number, info: {headshot: boolean}?)
	ensureChar(target)
	local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local dmg = math.max(0, amount)
	if info and info.headshot then
		-- multiplicador opcional desde Config si existiera
		local mult = (Config.Weapon and Config.Weapon.Deagle and Config.Weapon.Deagle.headshotMultiplier) or 2
		dmg *= mult
	end

	hum:TakeDamage(dmg)
	print(string.format("[HEALTH] %s -%.1f (headshot=%s) -> %.1f",
		target.Name, dmg, tostring(info and info.headshot), hum.Health))
end

return HealthService
