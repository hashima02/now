-- ReplicatedStorage/Shared/Contracts.lua
-- Nombres de eventos y payloads acordados (contratos de red)

local Contracts = {}

Contracts.Events = {
    RoundState   = "Round:State",   -- Server → Clients
    WeaponFire_v1 = "Weapon:Fire:v1", -- Client → Server
    WeaponHit_v1  = "Weapon:Hit:v1",  -- Server → Client (a todos o solo tirador)
}

-- Documentación de payloads (referencia):
-- Round:State
--   { state: "WAITING"|"PREPARE"|"COUNTDOWN"|"ACTIVE"|"ROUND_END"|"MATCH_END",
--     round: number,
--     time_left: number? }
--
-- Weapon:Fire:v1
--   { originCF: CFrame,
--     cameraDir: Vector3,
--     timestamp: number,
--     bulletId: number }
--
-- Weapon:Hit:v1
--   { bulletId: number,
--     hit: boolean,
--     isHeadshot: boolean,
--     targetId: number?,      -- UserId si aplica
--     hitPos: Vector3? }

return Contracts
