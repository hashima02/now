-- StarterPlayerScripts/Client/Controllers/WeaponController.lua
-- Rol: predicción visual y envío de Weapon:Fire:v1.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Contracts = require(ReplicatedStorage.Shared.Contracts)

local WeaponController = {}

function WeaponController.start()
	-- TODO: escuchar input y mandar Weapon:Fire:v1; escuchar Weapon:Hit:v1 para hitmarker
end

return WeaponController
