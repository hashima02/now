--!strict
-- init.server.lua — bootstrap de servicios
local ServerScriptService = game:GetService("ServerScriptService")

local ServicesFolder = ServerScriptService:WaitForChild("Services")
local RoundService   = require(ServicesFolder:WaitForChild("RoundService"))
local WeaponService  = require(ServicesFolder:WaitForChild("WeaponService"))
local HealthService  = require(ServicesFolder:WaitForChild("HealthService"))

-- Orden sugerido: primero HP (reset), luego armas (escucha de disparos), y al final rondas (FSM)
HealthService.resetAll()
WeaponService.start()
RoundService.start()

print("[BOOT] Server listo")
