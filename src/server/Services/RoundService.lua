--!strict
-- RoundService.lua — 1v1 FSM mínima
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- Sincroniza el estado con WeaponService para que el servidor acepte/rechace disparos
local ServerScriptService = game:GetService("ServerScriptService")
local WeaponService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("WeaponService"))


local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Contracts = require(Shared:WaitForChild("Contracts"))

local EventsFolder = ReplicatedStorage:WaitForChild("Events")
local Remotes = EventsFolder:WaitForChild("Remotes")

local ROUND_STATE_EVENT = Remotes:WaitForChild("Round:State") :: RemoteEvent

export type RoundState = "WAITING" | "PREPARE" | "COUNTDOWN" | "ACTIVE" | "ROUND_END"

local RoundService = {}
RoundService.__index = RoundService

local state: RoundState = "WAITING"
local roundNumber = 0
local timeLeft = 0
local heartbeatConn: RBXScriptConnection? = nil

local function getSpawnCFForIndex(index: number): CFrame
	local spawns = workspace:FindFirstChild("Spawns")
	if not spawns then
		warn("[ROUND] No existe Workspace.Spawns; crea Parts ancladas 'A' y 'B'")
		return CFrame.new()
	end
	local name = (index == 1) and "A" or "B"
	local p = spawns:FindFirstChild(name)
	if p and p:IsA("BasePart") then
		return p.CFrame + Vector3.new(0, 3, 0)
	end
	warn("[ROUND] Falta Spawn part: ", name)
	return CFrame.new()
end

local function emitState()
	ROUND_STATE_EVENT:FireAllClients({
		state = state,
		round = roundNumber,
		time_left = timeLeft,
	})
	print(string.format("[ROUND] -> %s | Round=%d | t=%.1f", state, roundNumber, timeLeft))
end

local function setState(nextState: RoundState, duration: number?)
	state = nextState
	timeLeft = math.max(0, duration or 0)
	emitState()

	WeaponService.setRoundState(state)
	
end

local function countPlayers(): number
	local n = 0
	for _ in Players:GetPlayers() do
		n += 1
	end
	return n
end

local function cleanPlayer(p: Player)
	local char = p.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		-- HP base 100 (HealthService también hará set, esto es redundancia segura)
		hum.Health = hum.MaxHealth
	end
	-- Reset posición (se hará al entrar a PREPARE)
end

local function teleportPlayers1v1()
	local plist = Players:GetPlayers()
	if #plist == 0 then return end
	if #plist == 1 then
		plist[1].CharacterPivot = getSpawnCFForIndex(1)
		return
	end
	plist[1].CharacterPivot = getSpawnCFForIndex(1)
	plist[2].CharacterPivot = getSpawnCFForIndex(2)
end

local function allButOneDead(): boolean
	-- Si queda 1 o 0 vivos, la ronda termina.
	local alive = 0
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			alive += 1
		end
	end
	return alive <= 1
end

local function tickTimer(dt: number)
	if timeLeft <= 0 then return end
	timeLeft -= dt
	if timeLeft <= 0 then
		timeLeft = 0
		emitState()
	end
end

local function advance()
	if state == "WAITING" then
		if countPlayers() >= 1 then
			roundNumber = 0
			setState("PREPARE", Config.Round.time.prepare or 3)
			for _, p in Players:GetPlayers() do cleanPlayer(p) end
			teleportPlayers1v1()
		else
			task.delay(1, advance)
		end

	elseif state == "PREPARE" then
		setState("COUNTDOWN", Config.Round.time.countdown or 3)

	elseif state == "COUNTDOWN" then
		setState("ACTIVE", Config.Round.time.active or 45)

	elseif state == "ACTIVE" then
		-- Si se agotó el tiempo o ya solo queda 1 vivo, cerramos
		setState("ROUND_END", Config.Round.time.roundEnd or 4)

	elseif state == "ROUND_END" then
		roundNumber += 1
		setState("PREPARE", Config.Round.time.prepare or 3)
		for _, p in Players:GetPlayers() do cleanPlayer(p) end
		teleportPlayers1v1()
	end
end

function RoundService.start()
	if heartbeatConn then heartbeatConn:Disconnect() end

	-- Bucle de tiempo + transiciones automáticas
	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		tickTimer(dt)
		-- Transición por tiempo agotado
		if timeLeft == 0 then
			-- En ACTIVE también se puede cortar por eliminación
			if state == "ACTIVE" and not allButOneDead() then
				-- Se acabó el tiempo: igual cerramos
				setState("ROUND_END", Config.Round.time.roundEnd or 4)
			elseif state ~= "WAITING" then
				advance()
			end
		else
			-- Transición temprana por “todos menos uno muertos”
			if state == "ACTIVE" and allButOneDead() then
				setState("ROUND_END", Config.Round.time.roundEnd or 4)
			end
		end
	end)

	-- Reinicios cuando jugadores entran (útil para 1v1)
	Players.PlayerAdded:Connect(function()
		if state == "WAITING" then
			setState("PREPARE", Config.Round.time.prepare or 3)
			task.defer(teleportPlayers1v1)
		end
	end)

	Players.PlayerRemoving:Connect(function()
		if countPlayers() <= 1 and state ~= "WAITING" then
			setState("WAITING", 0)
		end
	end)

	setState("WAITING", 0)
	print("[ROUND] start() listo")
end

return RoundService
