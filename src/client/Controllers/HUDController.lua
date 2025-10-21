--!strict
-- File: src/client/Controllers/HUDController.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Contracts opcional (usa tus nombres si existen)
local Contracts = nil
pcall(function()
	Contracts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Contracts"))
end)

local REMOTES = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

local EVT_ROUND_STATE = (Contracts and Contracts.Events and Contracts.Events.RoundState)
	and Contracts.Events.RoundState
	or "Round:State"

local EVT_WEAPON_HIT = (Contracts and Contracts.Events and Contracts.Events.WeaponHitV1)
	and Contracts.Events.WeaponHitV1
	or "Weapon:Hit:v1"

local RoundStateRE = REMOTES:FindFirstChild(EVT_ROUND_STATE)
local WeaponHitRE  = REMOTES:FindFirstChild(EVT_WEAPON_HIT)

assert(RoundStateRE and RoundStateRE:IsA("RemoteEvent"), "[HUDController] RemoteEvent '"..EVT_ROUND_STATE.."' no encontrado")
assert(WeaponHitRE  and WeaponHitRE:IsA("RemoteEvent"),  "[HUDController] RemoteEvent '"..EVT_WEAPON_HIT.."' no encontrado")

local M = {}

-- Helpers mínimos de UI (placeholders): sustituye con tu ScreenGui/TextLabels reales
local function updateRoundHud(payload: {state: string, round: number?, time_left: number?, config: any?})
	local s = payload.state
	local r = payload.round or 0
	local t = math.max(0, math.floor((payload.time_left or 0) + 0.5))
	-- TODO: vincula con tus TextLabels/Barras
	print(("[HUD] Round=%d | State=%s | T=%ds"):format(r, tostring(s), t))
end

local function showHitMarker(data: {
	from: number, target: number?, at: Vector3, part: string,
	isHeadshot: boolean, damage: number, killed: boolean
})
	-- TODO: dispara tu FX: crosshair flash, sonido “hit”, marcador en pantalla, etc.
	local tagSelf = data.from == LocalPlayer.UserId and "[YOU]" or "[ALLY/OTHER]"
	local targetStr = data.target and tostring(data.target) or "nil"
	print(("[HIT] %s -> part=%s hs=%s dmg=%d killed=%s target=%s at=(%.1f,%.1f,%.1f)")
		:format(tagSelf, data.part, tostring(data.isHeadshot), data.damage, tostring(data.killed), targetStr,
			data.at.X, data.at.Y, data.at.Z))
end

function M.start()
	print("[HUD] start()")

	-- Estado de ronda → timer / textos / indicadores
	RoundStateRE.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then return end
		updateRoundHud(payload)
	end)

	-- Impactos de arma → marcador de golpe / killfeed / trazadores
	WeaponHitRE.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end
		-- Campos esperados: from, target?, at(Vector3), part, isHeadshot, damage, killed
		if typeof(data.at) ~= "Vector3" then return end
		showHitMarker(data)
	end)
end

return M
