--!strict
-- RoundService.lua
local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local Workspace            = game:GetService("Workspace")
local RunService           = game:GetService("RunService")

local EventsFolder         = ReplicatedStorage:WaitForChild("Events")
local ROUND_STATE_EVENT    = EventsFolder:WaitForChild("Round:State")

local ServerScriptService  = game:GetService("ServerScriptService")
local WeaponService        = require(ServerScriptService.Services:WaitForChild("WeaponService"))
local HealthService        = require(ServerScriptService.Services:WaitForChild("HealthService"))

export type RoundState = "WAITING" | "PREPARE" | "COUNTDOWN" | "ACTIVE" | "ROUND_END"

local M = {}
local state: RoundState = "WAITING"
local seed = 0
local countdownEndT = 0
local ACTIVE_TIME = 60

local function setState(nextState: RoundState)
	state = nextState
	-- broadcast a clientes
	ROUND_STATE_EVENT:FireAllClients(state, seed)
	-- notificar a subs del servidor (WeaponService, etc.)
	if WeaponService and WeaponService.setRoundState then
		WeaponService.setRoundState(state)
	end
end

local function getSpawn(partName: string): CFrame
	local spawns = Workspace:FindFirstChild("Spawns")
	if spawns and spawns:IsA("Folder") then
		local p = spawns:FindFirstChild(partName)
		if p and p:IsA("BasePart") then
			return p.CFrame + Vector3.new(0, 3, 0)
		end
	end
	return CFrame.new(0, 5, 0)
end

local function teleportTeams()
	local aCF = getSpawn("A")
	local bCF = getSpawn("B")
	local toggle = true
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character or plr.CharacterAdded:Wait()
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = (toggle and aCF or bCF)
			toggle = not toggle
		end
	end
end

local function teamOrTwoPlayers(): boolean
	return #Players:GetPlayers() >= 2
end

function M.start()
	print("[ROUND] start()")
	setState("WAITING")

	RunService.Heartbeat:Connect(function()
		if state == "WAITING" then
			if teamOrTwoPlayers() then
				seed = math.random(1, 99999)
				setState("PREPARE")
			end

		elseif state == "PREPARE" then
			HealthService.resetAll()
			teleportTeams()
			countdownEndT = time() + 10
			setState("COUNTDOWN")

		elseif state == "COUNTDOWN" then
			if time() >= countdownEndT then
				setState("ACTIVE")
				countdownEndT = time() + ACTIVE_TIME
			end

		elseif state == "ACTIVE" then
			if time() >= countdownEndT then
				setState("ROUND_END")
			end

		elseif state == "ROUND_END" then
			-- Pequeña pausa y reinicio
			countdownEndT = time() + 3
			setState("WAITING")
		end
	end)
end

return M
