--!strict
-- WeaponController.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotos (directo en Events)
local Events   = ReplicatedStorage:WaitForChild("Events")
local EVT_FIRE = Events:WaitForChild("Weapon:Fire:v1")
local EVT_HIT  = Events:WaitForChild("Weapon:Hit:v1")

local M = {}

-- Disparo básico: el servidor valida FOV/CD y aplica daño
function M.shoot(weaponName: string)
	weaponName = weaponName or "Deagle"
	EVT_FIRE:FireServer({
		weapon = weaponName,
	})
end

-- Feedback de impacto
local function bindHitFeedback()
	EVT_HIT.OnClientEvent:Connect(function(success: boolean, pos: Vector3)
		-- Aquí puedes integrar tu HUD/sonidos/retícula
		-- Ejemplo mínimo (coméntalo si no quieres prints):
		-- print(success and "[HIT] ✓" or "[HIT] ✗", pos)
	end)
end

function M.start()
	bindHitFeedback()
end

return M
