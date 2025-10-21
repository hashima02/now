-- File: src/server/Services/RoundService.lua
--!strict
-- FSM de ronda y broadcast vía Remotes.
-- Cambios:
--  - Requiere WeaponService y le propaga el estado en setState(...)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Remotos (unificado a Events/Remotes)
local Events  = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_ROUND_STATE: RemoteEvent = Remotes:WaitForChild("Round:State") :: RemoteEvent

-- Notificar a WeaponService el estado de la ronda
local WeaponService = require(script.Parent:WaitForChild("WeaponService"))

export type RoundState = "PREPARE" | "COUNTDOWN" | "ACTIVE" | "END"

local M = {}

local ACTIVE_TIME = 60
local COUNTDOWN_TIME = 10

local currentState: RoundState = "PREPARE"
local endsAt: number? = nil

local function broadcast(state: RoundState, endsAtTime: number?)
	EVT_ROUND_STATE:FireAllClients({
		state = state,
		endsAt = endsAtTime,
	})
end

local function setState(state: RoundState, dur: number?)
	currentState = state
	if dur and dur > 0 then
		endsAt = tick() + dur
	else
		endsAt = nil
	end

	-- **NUEVO**: Propaga estado a WeaponService
	WeaponService.setRoundState(state)

	-- Broadcast a clientes
	broadcast(currentState, endsAt)
end

local function getSpawn(name: string): CFrame
	local ws = game:GetService("Workspace")
	local spawns = ws:FindFirstChild("Spawns")
	if not spawns then
		return CFrame.new(0, 5, 0)
	end
	local p = spawns:FindFirstChild(name)
	if p and p:IsA("BasePart") then
		return p.CFrame + Vector3.new(0, 4, 0)
	end
	return CFrame.new(0, 5, 0)
end

local function teleportAllToLobby()
	local cf = getSpawn("Lobby")
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character or plr.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
		hrp.CFrame = cf
	end
end

local function teleportToTrackAlternating()
	local useA = true
	for _, plr in ipairs(Players:GetPlayers()) do
		local cf = getSpawn(useA and "TrackA" or "TrackB")
		useA = not useA
		local char = plr.Character or plr.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
		hrp.CFrame = cf
	end
end

local function runLoop()
	while true do
		-- PREPARE
		teleportAllToLobby()
		setState("PREPARE")
		task.wait(2)

		-- COUNTDOWN
		teleportToTrackAlternating()
		setState("COUNTDOWN", COUNTDOWN_TIME)
		task.wait(COUNTDOWN_TIME)

		-- ACTIVE
		setState("ACTIVE", ACTIVE_TIME)
		task.wait(ACTIVE_TIME)

		-- END
		setState("END")
		task.wait(4)
	end
end

function M.start()
	task.spawn(runLoop)
	print("[RoundService] start OK")
end

return M
