-- ServerScriptService/Services/WeaponService.lua
-- Rol: validar disparos, raycast server, aplicar daño vía HealthService.
-- Evento IN: ReplicatedStorage/Events["Weapon:Fire:v1"]
-- Evento OUT: ReplicatedStorage/Events["Weapon:Hit:v1"]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Contracts = require(ReplicatedStorage.Shared.Contracts)

local WeaponService = {}

function WeaponService.start()
	-- TODO: conectar Weapon:Fire:v1 y validar disparos según estado de ronda
end

return WeaponService
