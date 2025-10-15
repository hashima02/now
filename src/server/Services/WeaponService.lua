--!strict
-- WeaponService.lua — valida disparos y decide hits
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Contracts = require(Shared:WaitForChild("Contracts"))

local EventsFolder = ReplicatedStorage:WaitForChild("Events")
local Remotes = EventsFolder:WaitForChild("Remotes")
local FIRE_EVENT = Remotes:WaitForChild("Weapon:Fire:v1") :: RemoteEvent
local HIT_EVENT = Remotes:WaitForChild("Weapon:Hit:v1") :: RemoteEvent
local ROUND_STATE_EVENT = Remotes:WaitForChild("Round:State") :: RemoteEvent

local currentRoundState: string = "WAITING"
ROUND_STATE_EVENT.OnServerEvent:Connect(function() end) -- no-op (client-only); mantenemos variable con un listener indirecto:
-- Mejor: reflejar el estado vía un BindableEvent interno o exponer getter de RoundService.
-- Para mantenerlo simple aquí, actualizaremos por un “proxy” manual desde RoundService si decides luego.

-- Cooldown por jugador
local lastShot: {[Player]: number} = {}

-- Raycast params básicos (ignora personaje del tirador)
local function buildRaycastParams(ignore: Instance)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {ignore}
	params.IgnoreWater = true
	return params
end

-- Checa FOV simple entre mirada del personaje y dirección del tiro
local function withinFOV(p: Player, dir: Vector3): boolean
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart") :: BasePart
	if not hrp then return true end
	local look = hrp.CFrame.LookVector
	local angle = math.deg(math.acos(math.clamp(look:Dot(dir.Unit), -1, 1)))
	local limit = (Config.Weapon and Config.Weapon.Deagle and Config.Weapon.Deagle.fovCheckDeg) or 90
	return angle <= limit
end

-- Determina si fue headshot simple (impactó en un MeshPart/Part con "Head" en el nombre)
local function isHead(part: BasePart?): boolean
	if not part then return false end
	local n = string.lower(part.Name)
	return n == "head" or n:find("head") ~= nil
end

local function currentTime()
	return os.clock()
end

-- Exponer setter sencillo para que RoundService nos diga el estado actual
local WeaponService = {}
function WeaponService.setRoundState(s: string)
	currentRoundState = s
end

local function onFire(player: Player, payload: {originCF: CFrame?, cameraDir: Vector3?, timestamp: number?, bulletId: string?})
	-- Validaciones mínimas
	if currentRoundState ~= "ACTIVE" then
		print("[WEAPON] Ignorado (estado no ACTIVE)")
		return
	end

	local now = currentTime()
	local cd = (Config.Weapon and Config.Weapon.Deagle and Config.Weapon.Deagle.cooldown) or 0.2
	local last = lastShot[player] or 0
	if now - last < cd then
		print("[WEAPON] Cooldown")
		return
	end
	lastShot[player] = now

	local dir = (payload and payload.cameraDir) or Vector3.new(0,0,-1)
	if not withinFOV(player, dir) then
		print("[WEAPON] Fuera de FOV")
		return
	end

	-- Raycast server
	local character = player.Character
	if not character then return end
	local origin = (payload and payload.originCF and payload.originCF.Position) or (character:FindFirstChild("Head") and (character.Head :: BasePart).Position) or Vector3.zero
	local params = buildRaycastParams(character)
	local rayResult = Workspace:Raycast(origin, dir.Unit * 1000, params)

	local hitPlayer: Player? = nil
	local headshot = false
	if rayResult then
		local inst = rayResult.Instance
		local model = inst:FindFirstAncestorOfClass("Model")
		if model then
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum then
				hitPlayer = Players:GetPlayerFromCharacter(model)
				headshot = isHead(inst)
			end
		end
	end

	-- Notifica al cliente del tirador (hitmarker básico) y aplica daño si procede
	HIT_EVENT:FireClient(player, {
		hit = hitPlayer and true or false,
		headshot = headshot,
	})

	if hitPlayer then
		local base = (Config.Weapon and Config.Weapon.Deagle and Config.Weapon.Deagle.baseDamage) or 60
		local HealthService = require(script.Parent:WaitForChild("HealthService"))
		HealthService.applyDamage(hitPlayer, base, {headshot = headshot})
	end
end

function WeaponService.start()
	FIRE_EVENT.OnServerEvent:Connect(onFire)
	print("[WEAPON] start() listo")
end

return WeaponService
