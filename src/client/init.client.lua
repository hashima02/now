--!strict
-- init.client.lua — bootstrap de controladores
local Controllers = script:WaitForChild("Controllers")

require(Controllers:WaitForChild("HUDController")).start()
require(Controllers:WaitForChild("WeaponController")).start()
require(Controllers:WaitForChild("InputController")).start()

print("[BOOT] Client listo")
