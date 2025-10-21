--!strict
-- InputController.lua
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Remotes (directo en Events)
local Events            = ReplicatedStorage:WaitForChild("Events")
local EVT_ROUND_STATE   = Events:WaitForChild("Round:State")

-- Controllers
local WeaponController  = require(script.Parent:WaitForChild("WeaponController"))

export type RoundState = "WAITING" | "PREPARE" | "COUNTDOWN" | "ACTIVE" | "ROUND_END"

local M = {}
local roundState: RoundState = "WAITING"
local mouseDown = false

local function canShoot(): boolean
	return roundState == "ACTIVE"
end

local function onInputBegan(input: InputObject, gp: boolean)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = true
		if canShoot() then
			WeaponController.shoot("Deagle")
		end
	end
end

local function onInputEnded(input: InputObject, gp: boolean)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = false
	end
end

local function bindInputs()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
end

local function bindRoundState()
	-- El servidor envía (state, seed)
	EVT_ROUND_STATE.OnClientEvent:Connect(function(state: RoundState)
		roundState = state
	end)
end

function M.start()
	bindInputs()
	bindRoundState()
end

return M
