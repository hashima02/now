-- StarterPlayerScripts/Client/Controllers/HUDController.lua
-- Rol: marcador, temporizador, banners; solo escucha Round:State.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Contracts = require(ReplicatedStorage.Shared.Contracts)

local HUDController = {}

function HUDController.start()
	-- TODO: suscribirse a Round:State y actualizar UI
end

return HUDController
