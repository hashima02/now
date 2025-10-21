-- File: src/client/Controllers/InputController.lua
--!strict
-- Enruta inputs de jugador (ej. bloquear inputs por estado de ronda si así lo decides)

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_ROUND_STATE: RemoteEvent = Remotes:WaitForChild("Round:State") :: RemoteEvent

local M = {}

local currentState: string = "PREPARE"

local function setInputEnabled(enabled: boolean)
	UserInputService.MouseIconEnabled = enabled
	-- Aquí puedes deshabilitar más cosas según tu sistema (ej. construcción, tienda, etc.)
end

function M.start()
	EVT_ROUND_STATE.OnClientEvent:Connect(function(payload)
		currentState = payload.state :: string
		-- Ejemplo: en COUNTDOWN/ACTIVE dejamos inputs on; en END/PREPARE podrías limitar.
		if currentState == "END" then
			setInputEnabled(false)
		else
			setInputEnabled(true)
		end
	end)
end

return M
