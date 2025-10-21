-- File: src/client/Controllers/InputController.lua
--!strict
-- Gestiona toggles básicos según estado de ronda (si lo necesitas)

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotos: ReplicatedStorage/Events/Remotes
local Events  = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_ROUND_STATE: RemoteEvent = Remotes:WaitForChild("Round:State") :: RemoteEvent

local M = {}

local function setInputEnabled(enabled: boolean)
	UserInputService.MouseIconEnabled = enabled
end

function M.start()
	EVT_ROUND_STATE.OnClientEvent:Connect(function(payload)
		local state = payload.state :: string
		-- Ejemplo simple: deshabilitar algo en END si quisieras
		if state == "END" then
			setInputEnabled(false)
		else
			setInputEnabled(true)
		end
	end)
end

return M
