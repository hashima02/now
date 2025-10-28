-- File: src/client/Main.client.lua
--!strict
-- Client único: HUD + Input + Weapon
-- Usa 'time()' para countdown (consistente con el server)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remotos
local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_ROUND_STATE: RemoteEvent = Remotes:WaitForChild("Round:State")
local EVT_FIRE: RemoteEvent        = Remotes:WaitForChild("Weapon:Fire:v1")
local EVT_HIT: RemoteEvent         = Remotes:WaitForChild("Weapon:Hit:v1")

-- ---------- HUD helpers ----------
local function setTextSafe(obj: Instance?, text: string)
	if obj and obj:IsA("TextLabel") then
		(obj :: TextLabel).Text = text
	end
end

local function getHUD()
	local hudGui = PlayerGui:FindFirstChild("HUDGui")
	local inGame = hudGui and hudGui:FindFirstChild("InGameHUD")
	local top = inGame and inGame:FindFirstChild("Top")
	local phaseLabel = top and top:FindFirstChild("PhaseLabel")
	local timerLabel = top and top:FindFirstChild("TimerLabel")
	return (phaseLabel :: Instance?), (timerLabel :: Instance?)
end

-- ---------- INPUT ----------
local inputEnabled = true
local function setInputEnabled(enabled: boolean)
	inputEnabled = enabled
	UserInputService.MouseIconEnabled = enabled
end

-- ---------- Round:State (unificado HUD + input) ----------
EVT_ROUND_STATE.OnClientEvent:Connect(function(payload)
	local state = (payload and payload.state) or "PREPARE"
	local endsAt = payload and payload.endsAt

	-- HUD
	local phaseLabel, timerLabel = getHUD()
	setTextSafe(phaseLabel, ("Phase: %s"):format(state))

	-- Timer
	if endsAt then
		task.spawn(function()
			while time() < endsAt do
				local remain = math.max(0, math.floor(endsAt - time()))
				setTextSafe(timerLabel, tostring(remain))
				task.wait(0.25)
			end
			setTextSafe(timerLabel, "0")
		end)
	else
		setTextSafe(timerLabel, "")
	end

	-- Input
	if state == "END" then
		setInputEnabled(false)
	else
		setInputEnabled(true)
	end
end)

-- ---------- Shoot ----------
UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not inputEnabled then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		EVT_FIRE:FireServer({
			weapon = "Deagle",
		})
	end
end)

-- ---------- Hit feedback (placeholder) ----------
EVT_HIT.OnClientEvent:Connect(function(hit: boolean, pos: Vector3)
	-- Aquí puedes agregar efectos (mira, sonido, marcador de impacto, etc.)
	-- print(("[HIT] %s @ %s"):format(tostring(hit), tostring(pos)))
end)

print("[BOOT][CLIENT] único LocalScript listo")
