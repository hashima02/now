-- File: src/client/Controllers/WeaponController.lua
--!strict
-- Disparo simple: envía evento al server; escucha feedback de hit

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotos: ReplicatedStorage/Events/Remotes
local Events  = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_FIRE: RemoteEvent = Remotes:WaitForChild("Weapon:Fire:v1") :: RemoteEvent
local EVT_HIT:  RemoteEvent = Remotes:WaitForChild("Weapon:Hit:v1")  :: RemoteEvent

local M = {}

local function onClickBegan()
	EVT_FIRE:FireServer({
		weapon = "Deagle",
	})
end

function M.start()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			onClickBegan()
		end
	end)

	EVT_HIT.OnClientEvent:Connect(function(hit, pos)
		-- hit: bool, pos: Vector3
		-- Aquí podrías poner un flash en la mira, sonido, etc.
	end)
end

return M
