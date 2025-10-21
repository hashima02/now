-- File: src/server/init.server.lua
--!strict
-- Bootstrap de servicios en orden sugerido

local ServerScriptService = game:GetService("ServerScriptService")

local ServicesFolder = ServerScriptService:WaitForChild("Services")
local RoundService   = require(ServicesFolder:WaitForChild("RoundService"))
local WeaponService  = require(ServicesFolder:WaitForChild("WeaponService"))
local HealthService  = require(ServicesFolder:WaitForChild("HealthService"))

-- Orden: reset HP -> armas -> rondas
HealthService.resetAll()
WeaponService.start()
RoundService.start()

print("[BOOT] Server listo")
