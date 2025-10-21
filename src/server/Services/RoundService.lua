--!strict
-- File: src/server/Services/RoundService.lua

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")

local ServicesFolder     = script.Parent
local WeaponService      = require(ServicesFolder:WaitForChild("WeaponService"))

-- Contracts opcional
local Contracts = nil
pcall(function()
	Contracts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Contracts"))
end)

local REMOTES = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")
local EVT_ROUND_STATE = (Contracts and Contracts.Events and Contracts.Events.RoundState) and Contracts.Events.RoundState or "Round:State"

export type RoundState = "PREPARE" | "COUNTDOWN" | "ACTIVE" | "POST"

local M = {}

-- Config simple; si ya tienes Shared/Config, puedes leerlo ahí y mapear estos valores
local CFG = {
	countdown_seconds = 10,
	active_seconds    = 90,
	post_seconds      = 5,
	firstTo           = 4,
	cap               = 13,
	winBy2            = true,
}

local state: RoundState = "PREPARE"
local roundNumber = 1
local timeLeft = 0
local running = false

local RoundStateRE = REMOTES:FindFirstChild(EVT_ROUND_STATE)
assert(RoundStateRE and RoundStateRE:IsA("RemoteEvent"), "[RoundService] RemoteEvent '"..EVT_ROUND_STATE.."' no encontrado")

local heartbeatConn: RBXScriptConnection? = nil

-- Helpers
local function broadcastState()
	RoundStateRE:FireAllClients({
		state = state,
		round = roundNumber,
		time_left = timeLeft,
		config = CFG,
	})
	-- Notifica al WeaponService para habilitar/bloquear disparos según estado
	if WeaponService and WeaponService.setRoundState then
		WeaponService.setRoundState(state)
	end
end

local function characterReady(plr: Player): boolean
	local char = plr.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil
end

local function teleportPlayers1v1()
	local spawnsFolder = workspace:FindFirstChild("Spawns")
	if not spawnsFolder then
		warn("[RoundService] Falta Workspace.Spawns con Parts 'A' y 'B'")
		return
	end
	local spawnA = spawnsFolder:FindFirstChild("A")
	local spawnB = spawnsFolder:FindFirstChild("B")
	if not (spawnA and spawnB and spawnA:IsA("BasePart") and spawnB:IsA("BasePart")) then
		warn("[RoundService] Spawns inválidos (se esperan Parts A y B ancladas)")
		return
	end

	local index = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if characterReady(plr) then
			local target = (index % 2 == 0) and spawnA or spawnB
			local char = plr.Character
			if char then
				char:PivotTo(target.CFrame) -- ✅ fix: usar :PivotTo
			end
			index += 1
		end
	end
end

local function aliveCount(): number
	local alive = 0
	for _, plr in ipairs(Players:GetPlayers()) do -- ✅ fix: iterar con ipairs
		local char = plr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			alive += 1
		end
	end
	return alive
end

local function allButOneDead(): boolean
	return aliveCount() <= 1
end

local function setState(newState: RoundState, duration: number)
	state = newState
	timeLeft = duration
	broadcastState()
end

local function runLoop()
	if heartbeatConn then heartbeatConn:Disconnect() end
	heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		if not running then return end

		timeLeft = math.max(0, timeLeft - dt)

		if state == "COUNTDOWN" then
			if timeLeft <= 0 then
				setState("ACTIVE", CFG.active_seconds)
				teleportPlayers1v1()
			end
		elseif state == "ACTIVE" then
			if timeLeft <= 0 or allButOneDead() then
				setState("POST", CFG.post_seconds)
			end
		elseif state == "POST" then
			if timeLeft <= 0 then
				roundNumber += 1
				setState("PREPARE", 0)
				setState("COUNTDOWN", CFG.countdown_seconds)
			end
		end

		-- Update “vivo” del contador para el HUD
		if state ~= "PREPARE" then
			broadcastState()
		end
	end)
end

-- API pública
function M.start()
	if running then return end
	running = true
	print("[RoundService] start()")
	setState("PREPARE", 0)
	setState("COUNTDOWN", CFG.countdown_seconds)
	runLoop()
end

function M.stop()
	running = false
	if heartbeatConn then heartbeatConn:Disconnect() end
end

function M.getState(): RoundState
	return state
end

return M
