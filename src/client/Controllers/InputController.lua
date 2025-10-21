--!strict
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events          = ReplicatedStorage:WaitForChild("Events")
local EVT_ROUND_STATE = Events:WaitForChild("Round:State")

export type RoundState = "WAITING" | "PREPARE" | "COUNTDOWN" | "ACTIVE" | "ROUND_END"

local M = {}
local roundState: RoundState = "WAITING"

local function canShoot(): boolean
	return roundState == "ACTIVE"
end

local function onInputBegan(input: InputObject, gp: boolean)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if canShoot() then
			local WeaponController = require(script.Parent:WaitForChild("WeaponController"))
			WeaponController.shoot("Deagle")
		end
	end
end

local function onInputEnded(_input: InputObject, _gp: boolean)
	-- reservado para automático/hold si lo necesitas
end

local function bindRoundState()
	-- server envía: (state, seed)
	EVT_ROUND_STATE.OnClientEvent:Connect(function(state: RoundState)
		roundState = state
	end)
end

function M.start()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	bindRoundState()
end

return M
