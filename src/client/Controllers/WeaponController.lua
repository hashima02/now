--!strict
-- WeaponClient.lua
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer       = Players.LocalPlayer
local Events            = ReplicatedStorage:WaitForChild("Events")
local EVT_FIRE          = Events:WaitForChild("Weapon:Fire:v1")
local EVT_HIT           = Events:WaitForChild("Weapon:Hit:v1")
local EVT_ROUND_STATE   = Events:WaitForChild("Round:State")

local roundState: "WAITING" | "PREPARE" | "COUNTDOWN" | "ACTIVE" | "ROUND_END" = "WAITING"
local currentWeapon = "Deagle"
local mouseDown = false

-- FOV cliente (solo visual/UX si lo usabas) más permisivo para alinearse al servidor
local FOV_DEG = 20

local function canShoot(): boolean
	return roundState == "ACTIVE"
end

EVT_ROUND_STATE.OnClientEvent:Connect(function(s: any, seed: number?)
	roundState = s
end)

-- Hit feedback básico
EVT_HIT.OnClientEvent:Connect(function(success: boolean, pos: Vector3)
	if success then
		-- TODO: play hitmarker, sonido, flash UI, etc.
	else
		-- opcional: feedback de fallo
	end
end)

local function tryShoot()
	if not canShoot() then return end
	EVT_FIRE:FireServer({
		weapon = currentWeapon,
	})
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = true
		tryShoot()
	end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = false
	end
end)
