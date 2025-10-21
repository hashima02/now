-- File: src/server/Services/WeaponService.lua
--!strict
-- Procesa disparos, determina impactos y notifica al HealthService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_FIRE: RemoteEvent = Remotes:WaitForChild("Weapon:Fire:v1") :: RemoteEvent
local EVT_HIT: RemoteEvent = Remotes:WaitForChild("Weapon:Hit:v1") :: RemoteEvent

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) -- ← usa Config directo (sin .Weapon)

local HealthService = require(script.Parent:WaitForChild("HealthService"))

local M = {}

-- Raycast muy básico placeholder (ajústalo a tu pipeline real)
local function simpleRaycastFromPlayer(player: Player)
	-- En un sistema real obtén CFrame de cámara del cliente validado/replicado
	-- Aquí solo simulamos un impacto al jugador frente (si existiera).
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			return other, false -- target, isHeadshot
		end
	end
	return nil, false
end

local function processFire(player: Player, req: { weapon: string? })
	local weaponName = req.weapon or "Deagle"
	local weaponCfg = Config[weaponName]
	if not weaponCfg then
		warn(("[WeaponService] Config no encontrada para '%s'"):format(weaponName))
		return
	end

	local targetPlayer, isHeadshot = simpleRaycastFromPlayer(player)
	if targetPlayer then
		local baseDamage = weaponCfg.baseDamage or 50
		local dmg = baseDamage
		if isHeadshot then
			local mult = weaponCfg.headshotMultiplier or 2
			dmg = math.floor(baseDamage * mult)
		end

		-- Aplica daño
		HealthService.applyDamage(targetPlayer, dmg, isHeadshot, weaponName, player)

		-- Opcional: reemitir a clientes para feedback
		EVT_HIT:FireAllClients({
			target = targetPlayer.UserId,
			headshot = isHeadshot,
			damage = dmg,
			weapon = weaponName,
			attacker = player.UserId,
		})
	end
end

function M.start()
	EVT_FIRE.OnServerEvent:Connect(function(player, payload)
		-- payload = { weapon="Deagle", ... }
		processFire(player, payload or {})
	end)
	print("[WeaponService] start OK")
end

return M
