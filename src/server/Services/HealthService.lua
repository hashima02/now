-- ServerScriptService/Services/HealthService.lua
-- Rol: llevar HP propio por jugador, avisar a RoundService al morir.
-- API esperada: applyDamage(player, amount, hitInfo)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local HealthService = {}

function HealthService.start()
	-- TODO: inicializar HP por jugador y limpiar al terminar ronda
end

return HealthService
