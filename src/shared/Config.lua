--!strict
-- Config/Weapon.lua
return {
	Deagle = {
		cooldown = 0.42,
		fovCheckDeg = 20, -- subir/ajustar aquí; el servidor lo leerá desde Config
		-- Daño por zonas (usado por WeaponService)
		damage = {
			head  = 120,
			torso = 60,
			limb  = 40,
		},
		-- Opcional: si no usas tabla damage, el servicio cae a esto:
		-- baseDamage = 60,
		-- headshotMultiplier = 2,
	},
}
