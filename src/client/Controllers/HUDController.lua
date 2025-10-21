-- File: src/client/Controllers/HUDController.lua
--!strict
-- Escucha estado de ronda y actualiza HUD (Phase + Timer)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remotos: ReplicatedStorage/Events/Remotes
local Events  = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_ROUND_STATE: RemoteEvent = Remotes:WaitForChild("Round:State") :: RemoteEvent

local M = {}

local function setTextSafe(obj: Instance?, text: string)
	if obj and obj:IsA("TextLabel") then
		(obj :: TextLabel).Text = text
	end
end

function M.start()
	-- Ajusta estos paths a tu jerarquía real de GUI si difieren
	local hudGui = PlayerGui:FindFirstChild("HUDGui")
	local inGame = hudGui and hudGui:FindFirstChild("InGameHUD")
	local top    = inGame and inGame:FindFirstChild("Top")
	local phaseLabel = top and top:FindFirstChild("PhaseLabel")
	local timerLabel = top and top:FindFirstChild("TimerLabel")

	EVT_ROUND_STATE.OnClientEvent:Connect(function(payload)
		-- payload: { state: string, endsAt: number? }
		local state = payload.state :: string
		local endsAt = payload.endsAt :: number?

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
end

return M
