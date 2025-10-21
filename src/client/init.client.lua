--!strict
local ControllersFolder = script:WaitForChild("Controllers")

local function safeStart(moduleName: string)
	local ok, modOrErr = pcall(function()
		return require(ControllersFolder:WaitForChild(moduleName))
	end)
	if not ok then
		warn(("[BOOT][CLIENT] require(%s) falló: %s"):format(moduleName, tostring(modOrErr)))
		return
	end
	local mod = modOrErr
	if type(mod) == "table" and type(mod.start) == "function" then
		local ok2, err = pcall(mod.start)
		if not ok2 then
			warn(("[BOOT][CLIENT] %s.start() falló: %s"):format(moduleName, tostring(err)))
		end
	else
		warn(("[BOOT][CLIENT] %s no exporta start()"):format(moduleName))
	end
end

safeStart("HUDController")
safeStart("WeaponController")
safeStart("InputController")

print("[BOOT][CLIENT] listo")
