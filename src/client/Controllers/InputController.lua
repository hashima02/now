-- StarterPlayerScripts/Client/Controllers/InputController.lua
-- Rol: capturar input (click/teclas) y habilitarlo solo en ACTIVE.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Contracts = require(ReplicatedStorage.Shared.Contracts)

local InputController = {}

function InputController.start()
	-- TODO: suscribirse a Round:State y habilitar/bloquear inputs
end

return InputController
