--!strict
-- WeaponController.lua — envía Weapon:Fire:v1 con datos básicos
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local FIRE_EVENT = Remotes:WaitForChild("Weapon:Fire:v1") :: RemoteEvent
local HIT_EVENT = Remotes:WaitForChild("Weapon:Hit:v1") :: RemoteEvent

local WeaponController = {}
WeaponController.__index = WeaponController

local function getCameraDir(): Vector3
	local cam = Workspace.CurrentCamera
	return cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
end

local function getMuzzleCF(): CFrame
	-- Por ahora, usa la cámara como origen; si tienes un ViewModel con Muzzle Attachment, cámbialo aquí.
	local cam = Workspace.CurrentCamera
	return cam and cam.CFrame or CFrame.new()
end

function WeaponController.start()
	print("[WEAPON-C] start()")
	HIT_EVENT.OnClientEvent:Connect(function(payload)
		if payload and payload.hit then
			print("[HITMARKER] hit", payload.headshot and "(HEADSHOT)" or "")
		else
			print("[HITMARKER] miss")
		end
	end)
end

function WeaponController.tryFire()
	local originCF = getMuzzleCF()
	local dir = getCameraDir()
	FIRE_EVENT:FireServer({
		originCF = originCF,
		cameraDir = dir,
		timestamp = os.clock(),
		bulletId = tostring(math.random(1, 10^9)),
	})
end

return WeaponController
