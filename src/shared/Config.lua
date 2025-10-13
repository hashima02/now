-- ReplicatedStorage/Shared/Config.lua
-- Números base del MVP (cliente y servidor leen esto)
local Config = {}

Config.Round = {
    firstTo = 6,       -- objetivo base
    cap     = 9,       -- tope duro (win by 2 hasta 8–8 → 9)
    winBy2  = true,

    time = {           -- segundos
        prepare   = 3,
        countdown = 3,
        active    = 45,
        roundEnd  = 3,
        inter     = 2,
    }
}

Config.Weapon = {
    Deagle = {
        cooldown     = 0.42,           -- ~142 RPM
        rangeStuds   = 160,            -- sin dropoff por distancia
        damage       = { head = 100, torso = 55, limb = 35 },
        fovCheckDeg  = 5,              -- validación server anti-snap
        lagWindowMs  = 120,            -- compensación ligera
        inputBufferS = 0.08            -- clicks un poco antes del fin del cooldown
    }
}

return Config
