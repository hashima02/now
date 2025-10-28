-- File: StarterPlayerScripts/Main.client.lua
--!strict
-- Unifica: HUD + Input + Weapon (cliente)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remotos
local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_ROUND_STATE: RemoteEvent = Remotes:WaitForChild("Round:State")
local EVT_FIRE: RemoteEvent = Remotes:WaitForChild("Weapon:Fire:v1")
local EVT_HIT: RemoteEvent = Remotes:WaitForChild("Weapon:Hit:v1")

-- ---------- HUD ----------
local function setTextSafe(obj: Instance?, text: string)
	if obj and obj:IsA("TextLabel") then
		(obj :: TextLabel).Text = text
	end
end

-- Ajusta estos paths si tu GUI difiere
local function getHUD()
	local hudGui = PlayerGui:FindFirstChild("HUDGui")
	local inGame = hudGui and hudGui:FindFirstChild("InGameHUD")
	local top = inGame and inGame:FindFirstChild("Top")
	local phaseLabel = top and top:FindFirstChild("PhaseLabel")
	local timerLabel = top and top:FindFirstChild("TimerLabel")
	return (phaseLabel :: Instance?), (timerLabel :: Instance?)
end

EVT_ROUND_STATE.OnClientEvent:Connect(function(payload)
	local state = (payload and payload.state) or "PREPARE"
	local endsAt = payload and payload.endsAt

	local phaseLabel, timerLabel = getHUD()
	setTextSafe(phaseLabel, ("Phase: %s"):format(state))

	if endsAt then
		task.spawn(function()
			while tick() < endsAt do
				local remain = math.max(0, math.floor(endsAt - tick()))
				setTextSafe(timerLabel, tostring(remain))
				task.wait(0.25)
			end
			setTextSafe(timerLabel, "0")
		end)
	else
		setTextSafe(timerLabel, "")
	end
end)

-- ---------- INPUT + WEAPON ----------
local inputEnabled = true

local function setInputEnabled(enabled: boolean)
	inputEnabled = enabled
	UserInputService.MouseIconEnabled = enabled
end

-- Habilitar/Deshabilitar según estado (ejemplo simple)
EVT_ROUND_STATE.OnClientEvent:Connect(function(payload)
	local state = (payload and payload.state) or "PREPARE"
	if state == "END" then
		setInputEnabled(false)
	else
		setInputEnabled(true)
	)
end)

-- Disparo con click izquierdo
UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not inputEnabled then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		EVT_FIRE:FireServer({
			weapon = "Deagle",
		})
	end
end)

-- Feedback de impacto (placeholder)
EVT_HIT.OnClientEvent:Connect(function(hit: boolean, pos: Vector3)
	-- Aquí puedes agregar partícula, sonido, o flash en la mira
	-- print(("[HIT] %s at %s"):format(tostring(hit), tostring(pos)))
end)

print("[BOOT][CLIENT] único LocalScript listo")
