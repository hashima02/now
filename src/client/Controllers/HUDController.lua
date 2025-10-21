--!strict
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Events          = ReplicatedStorage:WaitForChild("Events")
local EVT_ROUND_STATE = Events:WaitForChild("Round:State")

local COUNTDOWN_DURATION = 10
local ACTIVE_DURATION    = 60

export type RoundState = "WAITING" | "PREPARE" | "COUNTDOWN" | "ACTIVE" | "ROUND_END"

local M = {}
local roundState: RoundState = "WAITING"
local phaseEndT = 0
local HUD: ScreenGui
local StateLabel: TextLabel
local TimerLabel: TextLabel

local function ensureUI()
	HUD = PlayerGui:FindFirstChild("HUDGui") :: ScreenGui
	if not HUD then
		HUD = Instance.new("ScreenGui")
		HUD.Name = "HUDGui"
		HUD.ResetOnSpawn = false
		HUD.IgnoreGuiInset = true
		HUD.Parent = PlayerGui
	end
	StateLabel = HUD:FindFirstChild("StateLabel") :: TextLabel
	if not StateLabel then
		StateLabel = Instance.new("TextLabel")
		StateLabel.Name = "StateLabel"
		StateLabel.Size = UDim2.new(0, 220, 0, 32)
		StateLabel.Position = UDim2.new(0, 16, 0, 16)
		StateLabel.BackgroundTransparency = 0.25
		StateLabel.TextScaled = true
		StateLabel.Font = Enum.Font.GothamBold
		StateLabel.TextColor3 = Color3.new(1, 1, 1)
		StateLabel.Parent = HUD
	end
	TimerLabel = HUD:FindFirstChild("TimerLabel") :: TextLabel
	if not TimerLabel then
		TimerLabel = Instance.new("TextLabel")
		TimerLabel.Name = "TimerLabel"
		TimerLabel.Size = UDim2.new(0, 120, 0, 32)
		TimerLabel.Position = UDim2.new(0, 16, 0, 56)
		TimerLabel.BackgroundTransparency = 0.25
		TimerLabel.TextScaled = true
		TimerLabel.Font = Enum.Font.Gotham
		TimerLabel.TextColor3 = Color3.new(1, 1, 1)
		TimerLabel.Parent = HUD
	end
end

local function setStateUI(s: string)
	StateLabel.Text = ("STATE: %s"):format(s)
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
	TimerLabel.BackgroundColor3 =
		(roundState == "COUNTDOWN") and Color3.fromRGB(255,170,0) or Color3.fromRGB(60,60,60)
end

local function bindRoundState()
	EVT_ROUND_STATE.OnClientEvent:Connect(function(s: RoundState)
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
end

local function tickTimer()
	RunService.Heartbeat:Connect(function()
		if roundState == "COUNTDOWN" or roundState == "ACTIVE" then
			setTimerUI(phaseEndT - time())
		else
			setTimerUI(nil)
		end
	end)
end

function M.start()
	ensureUI()
	bindRoundState()
	tickTimer()
end

return M
