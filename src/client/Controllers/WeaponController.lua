-- File: src/client/Controllers/WeaponController.lua
--!strict
-- Maneja input de disparo y notificaciones visuales de hit

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_FIRE: RemoteEvent = Remotes:WaitForChild("Weapon:Fire:v1") :: RemoteEvent
local EVT_HIT: RemoteEvent = Remotes:WaitForChild("Weapon:Hit:v1") :: RemoteEvent

local LocalPlayer = Players.LocalPlayer

local M = {}

local firing = false

local function onClickBegan()
	firing = true
	-- Disparo simple: Delegamos toda la lógica de validación al servidor
	EVT_FIRE:FireServer({
		weapon = "Deagle",
		-- Puedes enviar origen/dirección si tu server lo requiere
	})
end

local function onClickEnded()
	firing = false
end

function M.start()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			onClickBegan()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			onClickEnded()
		end
	end)

	-- Feedback de hits (si el server lo reemite a clientes)
	EVT_HIT.OnClientEvent:Connect(function(data)
		-- data = { target=Player/UserId, headshot=bool, damage=number }
		-- Aquí podrías reproducir sonido/flash en mira, etc.
		-- print(("[HIT] target=%s head=%s dmg=%d"):format(tostring(data.target), tostring(data.headshot), data.damage or 0))
	end)
end

return M
