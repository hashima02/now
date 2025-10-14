-- ServerScriptService/Services/RoundService.lua
-- Rol: control de estados de ronda/match y temporizadores.
-- Eventos IN: (ninguno directo; escucha muertes desde HealthService)
-- Eventos OUT: ReplicatedStorage/Events["Round:State"]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Contracts = require(ReplicatedStorage.Shared.Contracts)

local RoundService = {}

function RoundService.start()
	-- TODO: inicializar estado WAITING y emitir Round:State inicial
end

return RoundService
