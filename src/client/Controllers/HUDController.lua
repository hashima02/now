--!strict
-- HUDController.lua
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Remotes
local Events          = ReplicatedStorage:WaitForChild("Events")
local EVT_ROUND_STATE = Events:WaitForChild("Round:State")

-- Constantes (deben coincidir con RoundService)
local COUNTDOWN_DURATION = 10
local ACTIVE_DURATION    = 60

-- Estado local
local roundState: "WAITING" | "PREPARE" | "COUNTDOWN" | "ACTIVE" | "ROUND_END" = "WAITING"
local phaseEndT = 0

-- UI mínima (se autocrea si no existe)
local function ensureUI()
	local hud = PlayerGui:FindFirstChild("HUDGui") :: ScreenGui?
	if not hud then
		hud = Instance.new("ScreenGui")
		hud.Name = "HUDGui"
		hud.ResetOnSpawn = false
		hud.IgnoreGuiInset = true
		hud.Parent = PlayerGui
	end

	local stateLabel = hud:FindFirstChild("StateLabel") :: TextLabel?
	if not stateLabel then
		stateLabel = Instance.new("TextLabel")
		stateLabel.Name = "StateLabel"
		stateLabel.Size = UDim2.new(0, 220, 0, 32)
		stateLabel.Position = UDim2.new(0, 16, 0, 16)
		stateLabel.BackgroundTransparency = 0.25
		stateLabel.TextScaled = true
		stateLabel.Font = Enum.Font.GothamBold
		stateLabel.TextColor3 = Color3.new(1, 1, 1)
		stateLabel.Parent = hud
	end

	local timerLabel = hud:FindFirstChild("TimerLabel") :: TextLabel?
	if not timerLabel then
		timerLabel = Instance.new("TextLabel")
		timerLabel.Name = "TimerLabel"
		timerLabel.Size = UDim2.new(0, 120, 0, 32)
		timerLabel.Position = UDim2.new(0, 16, 0, 56)
		timerLabel.BackgroundTransparency = 0.25
		timerLabel.TextScaled = true
		timerLabel.Font = Enum.Font.Gotham
		timerLabel.TextColor3 = Color3.new(1, 1, 1)
		timerLabel.Parent = hud
	end

	return hud :: ScreenGui, stateLabel :: TextLabel, timerLabel :: TextLabel
end

local HUD, StateLabel, TimerLabel = ensureUI()

local function setStateUI(s: string)
	StateLabel.Text = ("STATE: %s"):format(s)
	-- Colores simples por estado
	local colors = {
		WAITING   = Color3.fromRGB(120,120,120),
		PREPARE   = Color3.fromRGB(0,170,255),
		COUNTDOWN = Color3.fromRGB(255,170,0),
		ACTIVE    = Color3.fromRGB(0,200,0),
		ROUND_END = Color3.fromRGB(255,70,70),
	}
	StateLabel.BackgroundColor3 = colors[s] or Color3.fromRGB(60,60,60)
end

local function setTimerUI(secLeft: number?)
	if not secLeft then
		TimerLabel.Text = "T: --"
		TimerLabel.BackgroundColor3 = Color3.fromRGB(60,60,60)
		return
	end
	if secLeft < 0 then secLeft = 0 end
	TimerLabel.Text = ("T: %d"):format(math.floor(secLeft + 0.5))
	TimerLabel.BackgroundColor3 = (roundState == "COUNTDOWN") and Color3.fromRGB(255,170,0) or Color3.fromRGB(60,60,60)
end

-- Reacción a cambios de estado (server → client)
EVT_ROUND_STATE.OnClientEvent:Connect(function(s: any, _seed: number?)
	roundState = s
	setStateUI(s)

	if s == "COUNTDOWN" then
		phaseEndT = time() + COUNTDOWN_DURATION
	elseif s == "ACTIVE" then
		phaseEndT = time() + ACTIVE_DURATION
	else
		phaseEndT = 0
		setTimerUI(nil)
	end
end)

-- Loop visual del timer
RunService.Heartbeat:Connect(function()
	if roundState == "COUNTDOWN" or roundState == "ACTIVE" then
		local remain = phaseEndT - time()
		setTimerUI(remain)
	else
		setTimerUI(nil)
	end
end)
