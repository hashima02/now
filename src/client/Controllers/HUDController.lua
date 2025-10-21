-- File: src/client/Controllers/HUDController.lua
--!strict
-- Escucha estado de ronda y actualiza HUD básico

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local EVT_ROUND_STATE: RemoteEvent = Remotes:WaitForChild("Round:State") :: RemoteEvent

local M = {}

local function setTextSafe(label: TextLabel?, text: string)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

function M.start()
	-- HUD opcional: HUDGui/InGameHUD/Top/PhaseLabel + TimerLabel (ajusta a tu jerarquía real)
	local hudGui = PlayerGui:FindFirstChild("HUDGui")
	local inGame = hudGui and hudGui:FindFirstChild("InGameHUD")
	local top = inGame and inGame:FindFirstChild("Top")
	local phaseLabel = top and top:FindFirstChild("PhaseLabel") :: TextLabel?
	local timerLabel = top and top:FindFirstChild("TimerLabel") :: TextLabel?

	EVT_ROUND_STATE.OnClientEvent:Connect(function(payload)
		-- payload = { state = "PREPARE"|"COUNTDOWN"|"ACTIVE"|"END", endsAt = tick() }
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
