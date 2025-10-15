--!strict
-- InputController.lua — habilita click solo en ACTIVE
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local ROUND_STATE_EVENT = Remotes:WaitForChild("Round:State") :: RemoteEvent

local InputController = {}
InputController.__index = InputController

local canShoot = false

function InputController.start()
	print("[INPUT] start()")
	ROUND_STATE_EVENT.OnClientEvent:Connect(function(payload)
		local s = (payload and payload.state) or "?"
		canShoot = (s == "ACTIVE")
	end)

	UserInputService.InputBegan:Connect(function(i, gpe)
		if gpe then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			if canShoot then
				-- Delegamos a WeaponController
				local WeaponController = require(script.Parent:WaitForChild("WeaponController"))
				WeaponController.tryFire()
			else
				print("[INPUT] Click bloqueado (no ACTIVE)")
			end
		end
	end)
end

return InputController
