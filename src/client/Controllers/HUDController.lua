--!strict
-- HUDController.lua — solo prints por ahora
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = Events:WaitForChild("Remotes")
local ROUND_STATE_EVENT = Remotes:WaitForChild("Round:State") :: RemoteEvent

local HUDController = {}
HUDController.__index = HUDController

function HUDController.start()
	print("[HUD] start()")
	ROUND_STATE_EVENT.OnClientEvent:Connect(function(payload)
		local s = (payload and payload.state) or "?"
		local r = (payload and payload.round) or 0
		local t = (payload and payload.time_left) or 0
		print(string.format("[HUD] Round=%d | %s | t=%.1f", r, s, t))
		-- TODO: actualizar UI real (timer/estado). De momento, solo prints.
	end)
end

return HUDController
