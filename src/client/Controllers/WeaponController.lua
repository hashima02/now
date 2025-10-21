--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events   = ReplicatedStorage:WaitForChild("Events")
local EVT_FIRE = Events:WaitForChild("Weapon:Fire:v1")
local EVT_HIT  = Events:WaitForChild("Weapon:Hit:v1")

local M = {}

function M.shoot(weaponName: string)
	EVT_FIRE:FireServer({ weapon = weaponName or "Deagle" })
end

local function bindHitFeedback()
	EVT_HIT.OnClientEvent:Connect(function(success: boolean, _pos: Vector3)
		-- TODO: hitmarker / sonido / UI
		-- print(success and "[HIT] ✓" or "[HIT] ✗", _pos)
	end)
end

function M.start()
	bindHitFeedback()
end

return M
