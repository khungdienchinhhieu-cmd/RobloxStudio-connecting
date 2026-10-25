--!strict
--[[
	WeaponManager.luau  (v2 — ARSENAL 8 Ô CHUẨN GTA V)
	================================================================================
	• 8 ô vũ khí khớp đúng VÒNG CHỌN SÚNG GTA V:
	    1. Tay Không      2. Gậy Bóng Chày   3. Pistol 9mm     4. AP Pistol
	    5. Micro SMG      6. Carbine Rifle   7. Assault Shotgun 8. Sniper Rifle
	• Mỗi súng có ĐẠN THẬT (băng / dự trữ), tốc độ bắn, độ giãn, số viên / phát.
	• Bắn trúng Part có máu ẩn -> DestructionManager trừ PartHealth -> hết máu TỰ VỠ.
	• Server giữ TRẠNG THÁI ĐẠN và đồng bộ về client qua RemoteEvent `WeaponSync`.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DestructionManager = require(script.Parent:WaitForChild("DestructionManager"))

local WeaponManager = {}

-- Thứ tự 8 ô theo chiều kim đồng hồ, bắt đầu từ ô TRÊN CÙNG của vòng chọn
local WEAPON_ORDER: { string } = {
	"Unarmed", -- 1  ↑
	"Baseball Bat", -- 2  ↗
	"Pistol 9mm", -- 3  →
	"AP Pistol", -- 4  ↘
	"Micro SMG", -- 5  ↓
	"Carbine Rifle", -- 6  ↙
	"Assault Shotgun", -- 7  ←
	"Sniper Rifle", -- 8  ↖
}

type Spec = {
	display: string,
	icon: string,
	slot: number,
	category: string,
	damage: number,
	cooldown: number,
	range: number,
	impulse: number,
	auto: boolean,
	melee: boolean,
	pellets: number,
	spread: number,
	mag: number,
	reserve: number,
	reloadTime: number,
	accent: { number },
}

local SPECS: { [string]: Spec } = {
	Unarmed = {
		display = "TAY KHÔNG",
		icon = "fist",
		slot = 1,
		category = "KHÔNG VŨ KHÍ",
		damage = 12,
		cooldown = 0.5,
		range = 4.5,
		impulse = 14,
		auto = false,
		melee = true,
		pellets = 1,
		spread = 0,
		mag = 0,
		reserve = 0,
		reloadTime = 0,
		accent = { 148, 163, 184 },
	},
	["Baseball Bat"] = {
		display = "GẬY BÓNG CHÀY",
		icon = "bat",
		slot = 2,
		category = "CẬN CHIẾN",
		damage = 34,
		cooldown = 0.6,
		range = 6.5,
		impulse = 62,
		auto = false,
		melee = true,
		pellets = 1,
		spread = 0,
		mag = 0,
		reserve = 0,
		reloadTime = 0,
		accent = { 245, 158, 11 },
	},
	["Pistol 9mm"] = {
		display = "PISTOL 9MM",
		icon = "pistol",
		slot = 3,
		category = "SÚNG NGẮN",
		damage = 38,
		cooldown = 0.16,
		range = 300,
		impulse = 36,
		auto = false,
		melee = false,
		pellets = 1,
		spread = 0.6,
		mag = 12,
		reserve = 120,
		reloadTime = 1.5,
		accent = { 96, 165, 250 },
	},
	["AP Pistol"] = {
		display = "AP PISTOL",
		icon = "appistol",
		slot = 4,
		category = "SÚNG NGẮN TỰ ĐỘNG",
		damage = 24,
		cooldown = 0.075,
		range = 280,
		impulse = 28,
		auto = true,
		melee = false,
		pellets = 1,
		spread = 1.6,
		mag = 18,
		reserve = 180,
		reloadTime = 1.7,
		accent = { 56, 189, 248 },
	},
	["Micro SMG"] = {
		display = "MICRO SMG",
		icon = "smg",
		slot = 5,
		category = "TIỂU LIÊN",
		damage = 20,
		cooldown = 0.07,
		range = 260,
		impulse = 26,
		auto = true,
		melee = false,
		pellets = 1,
		spread = 2.3,
		mag = 30,
		reserve = 240,
		reloadTime = 1.9,
		accent = { 45, 212, 191 },
	},
	["Carbine Rifle"] = {
		display = "CARBINE RIFLE",
		icon = "rifle",
		slot = 6,
		category = "SÚNG TRƯỜNG",
		damage = 30,
		cooldown = 0.095,
		range = 380,
		impulse = 44,
		auto = true,
		melee = false,
		pellets = 1,
		spread = 1.2,
		mag = 30,
		reserve = 240,
		reloadTime = 2.0,
		accent = { 74, 222, 128 },
	},
	["Assault Shotgun"] = {
		display = "ASSAULT SHOTGUN",
		icon = "shotgun",
		slot = 7,
		category = "SÚNG SHOTGUN",
		damage = 16,
		cooldown = 0.62,
		range = 140,
		impulse = 52,
		auto = false,
		melee = false,
		pellets = 8,
		spread = 6.5,
		mag = 8,
		reserve = 64,
		reloadTime = 2.4,
		accent = { 251, 146, 60 },
	},
	["Sniper Rifle"] = {
		display = "SNIPER RIFLE",
		icon = "sniper",
		slot = 8,
		category = "SÚNG BẮN TỈA",
		damage = 160,
		cooldown = 1.35,
		range = 900,
		impulse = 90,
		auto = false,
		melee = false,
		pellets = 1,
		spread = 0.15,
		mag = 5,
		reserve = 30,
		reloadTime = 2.6,
		accent = { 192, 132, 252 },
	},
}

-- Kiểu dáng 3D từng khẩu (handle + các mảnh hàn vào)
local GUN_MODELS: { [string]: any } = {
	["Pistol 9mm"] = {
		handle = { size = Vector3.new(0.26, 0.78, 0.32), color = Color3.fromRGB(34, 36, 42) },
		parts = {
			{ name = "Slide", size = Vector3.new(0.28, 0.30, 1.12), off = Vector3.new(0, 0.40, -0.32), color = Color3.fromRGB(58, 62, 72) },
			{ name = "Grip", size = Vector3.new(0.24, 0.50, 0.34), off = Vector3.new(0, 0.06, 0.24), color = Color3.fromRGB(26, 28, 34) },
			{ name = "Muzzle", size = Vector3.new(0.15, 0.15, 0.26), off = Vector3.new(0, 0.40, -0.92), color = Color3.fromRGB(18, 20, 24) },
		},
	},
	["AP Pistol"] = {
		handle = { size = Vector3.new(0.26, 0.80, 0.34), color = Color3.fromRGB(32, 34, 40) },
		parts = {
			{ name = "Slide", size = Vector3.new(0.28, 0.32, 1.30), off = Vector3.new(0, 0.42, -0.38), color = Color3.fromRGB(64, 70, 82) },
			{ name = "Grip", size = Vector3.new(0.24, 0.52, 0.36), off = Vector3.new(0, 0.04, 0.26), color = Color3.fromRGB(24, 26, 32) },
			{ name = "Mag", size = Vector3.new(0.20, 0.62, 0.26), off = Vector3.new(0, -0.30, 0.16), color = Color3.fromRGB(20, 22, 28) },
			{ name = "Muzzle", size = Vector3.new(0.16, 0.16, 0.40), off = Vector3.new(0, 0.42, -1.10), color = Color3.fromRGB(18, 20, 24) },
		},
	},
	["Micro SMG"] = {
		handle = { size = Vector3.new(0.28, 0.72, 0.36), color = Color3.fromRGB(30, 32, 38) },
		parts = {
			{ name = "Receiver", size = Vector3.new(0.30, 0.44, 1.10), off = Vector3.new(0, 0.46, -0.34), color = Color3.fromRGB(44, 48, 58) },
			{ name = "Mag", size = Vector3.new(0.22, 0.86, 0.30), off = Vector3.new(0, -0.16, -0.10), color = Color3.fromRGB(22, 24, 30) },
			{ name = "Stock", size = Vector3.new(0.22, 0.20, 0.72), off = Vector3.new(0, 0.46, 0.62), color = Color3.fromRGB(26, 28, 34) },
			{ name = "Barrel", size = Vector3.new(0.16, 0.16, 0.52), off = Vector3.new(0, 0.46, -1.10), color = Color3.fromRGB(18, 20, 24) },
		},
	},
	["Carbine Rifle"] = {
		handle = { size = Vector3.new(0.30, 0.86, 0.44), color = Color3.fromRGB(28, 30, 36) },
		parts = {
			{ name = "Receiver", size = Vector3.new(0.34, 0.42, 1.70), off = Vector3.new(0, 0.48, -0.60), color = Color3.fromRGB(40, 44, 52) },
			{ name = "Barrel", size = Vector3.new(0.18, 0.18, 1.05), off = Vector3.new(0, 0.50, -1.95), color = Color3.fromRGB(20, 22, 26) },
			{ name = "Mag", size = Vector3.new(0.24, 0.80, 0.38), off = Vector3.new(0, -0.06, -0.72), color = Color3.fromRGB(22, 24, 30) },
			{ name = "Stock", size = Vector3.new(0.24, 0.34, 0.96), off = Vector3.new(0, 0.46, 0.86), color = Color3.fromRGB(26, 28, 34) },
			{ name = "Rail", size = Vector3.new(0.22, 0.10, 1.30), off = Vector3.new(0, 0.72, -0.60), color = Color3.fromRGB(52, 58, 68) },
		},
	},
	["Assault Shotgun"] = {
		handle = { size = Vector3.new(0.30, 0.84, 0.46), color = Color3.fromRGB(46, 36, 26) },
		parts = {
			{ name = "Receiver", size = Vector3.new(0.34, 0.40, 1.30), off = Vector3.new(0, 0.48, -0.50), color = Color3.fromRGB(58, 44, 30) },
			{ name = "Barrel", size = Vector3.new(0.24, 0.24, 1.55), off = Vector3.new(0, 0.52, -1.80), color = Color3.fromRGB(24, 26, 30) },
			{ name = "Pump", size = Vector3.new(0.30, 0.26, 0.62), off = Vector3.new(0, 0.30, -1.45), color = Color3.fromRGB(66, 50, 34) },
			{ name = "Stock", size = Vector3.new(0.24, 0.36, 0.92), off = Vector3.new(0, 0.44, 0.78), color = Color3.fromRGB(52, 38, 26) },
		},
	},
	["Sniper Rifle"] = {
		handle = { size = Vector3.new(0.30, 0.84, 0.44), color = Color3.fromRGB(26, 30, 28) },
		parts = {
			{ name = "Receiver", size = Vector3.new(0.32, 0.38, 1.60), off = Vector3.new(0, 0.48, -0.60), color = Color3.fromRGB(38, 44, 40) },
			{ name = "Barrel", size = Vector3.new(0.16, 0.16, 2.20), off = Vector3.new(0, 0.50, -2.30), color = Color3.fromRGB(20, 22, 20) },
			{ name = "Scope", size = Vector3.new(0.26, 0.26, 1.05), off = Vector3.new(0, 0.80, -0.55), color = Color3.fromRGB(30, 34, 32) },
			{ name = "ScopeLens", size = Vector3.new(0.22, 0.22, 0.06), off = Vector3.new(0, 0.80, -1.10), color = Color3.fromRGB(120, 200, 230) },
			{ name = "Stock", size = Vector3.new(0.24, 0.34, 1.05), off = Vector3.new(0, 0.44, 0.92), color = Color3.fromRGB(28, 32, 30) },
			{ name = "Bipod", size = Vector3.new(0.10, 0.44, 0.10), off = Vector3.new(0, 0.10, -1.30), color = Color3.fromRGB(24, 26, 24) },
		},
	},
	["Baseball Bat"] = {
		handle = { size = Vector3.new(0.22, 0.92, 0.22), color = Color3.fromRGB(120, 84, 46) },
		parts = {
			{ name = "Barrel", size = Vector3.new(0.30, 1.55, 0.30), off = Vector3.new(0, 0.98, 0), color = Color3.fromRGB(168, 120, 66) },
			{ name = "Tip", size = Vector3.new(0.34, 0.22, 0.34), off = Vector3.new(0, 1.82, 0), color = Color3.fromRGB(186, 140, 82) },
			{ name = "Grip", size = Vector3.new(0.24, 0.34, 0.24), off = Vector3.new(0, -0.52, 0), color = Color3.fromRGB(38, 38, 40) },
		},
	},
}

type AmmoEntry = { mag: number, reserve: number }
type PlayerState = {
	ammo: { [string]: AmmoEntry },
	lastShotAt: number,
	lastReloadAt: number,
}

local stateByPlayer: { [Player]: PlayerState } = {}

local function freshAmmo(): { [string]: AmmoEntry }
	local ammo: { [string]: AmmoEntry } = {}
	for name, spec in pairs(SPECS) do
		if spec.mag > 0 then
			ammo[name] = { mag = spec.mag, reserve = spec.reserve }
		end
	end
	return ammo
end

local function getState(player: Player): PlayerState
	local st = stateByPlayer[player]
	if st then
		return st
	end
	local created: PlayerState = { ammo = freshAmmo(), lastShotAt = 0, lastReloadAt = 0 }
	stateByPlayer[player] = created
	return created
end

--=====================================================================
-- DỰNG TOOL 3D
--=====================================================================
local function weldTo(handle: BasePart, child: BasePart)
	child.CanCollide = false
	child.Massless = true
	child.Anchored = false
	local wc = Instance.new("WeldConstraint")
	wc.Part0 = handle
	wc.Part1 = child
	wc.Parent = child
end

local function buildWeaponTool(toolName: string, spec: Spec): Tool
	local tool = Instance.new("Tool")
	tool.Name = toolName
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = spec.display
	tool:SetAttribute("IsGtaWeapon", true)
	tool:SetAttribute("IsMelee", spec.melee)
	tool:SetAttribute("WeaponSlot", spec.slot)
	tool:SetAttribute("WeaponDisplay", spec.display)
	tool:SetAttribute("AutoFire", spec.auto)
	tool:SetAttribute("FireCooldown", spec.cooldown)
	tool:SetAttribute("Pellets", spec.pellets)

	local model = GUN_MODELS[toolName]
	if not model then
		return tool
	end

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = model.handle.size
	handle.Color = model.handle.color
	handle.Material = Enum.Material.Metal
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	for _, pSpec in ipairs(model.parts) do
		local p = Instance.new("Part")
		p.Name = pSpec.name
		p.Size = pSpec.size
		p.Color = pSpec.color
		p.Material = if pSpec.name == "ScopeLens" then Enum.Material.Glass else Enum.Material.Metal
		p.CFrame = handle.CFrame * CFrame.new(pSpec.off)
		p.Parent = tool
		weldTo(handle, p)
	end

	return tool
end

local function giveLoadout(player: Player)
	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then
		return
	end
	for _, name in ipairs(WEAPON_ORDER) do
		local spec = SPECS[name]
		if spec and name ~= "Unarmed" and not backpack:FindFirstChild(name) then
			local t = buildWeaponTool(name, spec)
			t.Parent = backpack
		end
	end
end

--=====================================================================
-- ĐỒNG BỘ ĐẠN VỀ CLIENT
--=====================================================================
local function makeWeaponList(st: PlayerState)
	local list = {}
	for _, name in ipairs(WEAPON_ORDER) do
		local spec = SPECS[name]
		if spec then
			local ammo = st.ammo[name]
			table.insert(list, {
				name = name,
				display = spec.display,
				icon = spec.icon,
				slot = spec.slot,
				category = spec.category,
				auto = spec.auto,
				melee = spec.melee,
				mag = if ammo then ammo.mag else 0,
				magSize = spec.mag,
				reserve = if ammo then ammo.reserve else 0,
				accent = spec.accent,
			})
		end
	end
	return list
end

function WeaponManager.init(remotesFolder: Instance)
	local fireRemote = remotesFolder:FindFirstChild("WeaponFire") :: RemoteEvent?
	if not fireRemote then
		local created = Instance.new("RemoteEvent")
		created.Name = "WeaponFire"
		created.Parent = remotesFolder
		fireRemote = created
	end
	local activeFireRemote = fireRemote :: RemoteEvent

	local reloadRemote = remotesFolder:FindFirstChild("WeaponReload") :: RemoteEvent?
	if not reloadRemote then
		local created = Instance.new("RemoteEvent")
		created.Name = "WeaponReload"
		created.Parent = remotesFolder
		reloadRemote = created
	end
	local activeReloadRemote = reloadRemote :: RemoteEvent

	local syncRemote = remotesFolder:FindFirstChild("WeaponSync") :: RemoteEvent?
	if not syncRemote then
		local created = Instance.new("RemoteEvent")
		created.Name = "WeaponSync"
		created.Parent = remotesFolder
		syncRemote = created
	end
	local activeSyncRemote = syncRemote :: RemoteEvent

	local function pushState(player: Player)
		local st = getState(player)
		local equipped = ""
		local char = player.Character
		if char then
			local tool = char:FindFirstChildOfClass("Tool")
			if tool and tool:GetAttribute("IsGtaWeapon") == true then
				equipped = tool.Name
			end
		end
		activeSyncRemote:FireClient(player, {
			type = "state",
			weapons = makeWeaponList(st),
			equipped = equipped,
		})
	end

	local function pushAmmo(player: Player, name: string, empty: boolean?)
		local st = getState(player)
		local ammo = st.ammo[name]
		if not ammo then
			return
		end
		activeSyncRemote:FireClient(player, {
			type = "ammo",
			name = name,
			mag = ammo.mag,
			reserve = ammo.reserve,
			magSize = SPECS[name].mag,
			empty = empty == true,
		})
	end

	local function hookPlayer(player: Player)
		local function onChar()
			task.wait(0.15)
			-- Hồi đầy đạn khi hồi sinh
			local st = getState(player)
			st.lastShotAt = 0
			st.lastReloadAt = 0
			for name, spec in pairs(SPECS) do
				if spec.mag > 0 then
					st.ammo[name] = { mag = spec.mag, reserve = spec.reserve }
				end
			end
			giveLoadout(player)
			pushState(player)
		end
		player.CharacterAdded:Connect(onChar)
		if player.Character then
			task.spawn(onChar)
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		hookPlayer(p)
	end
	Players.PlayerAdded:Connect(hookPlayer)
	Players.PlayerRemoving:Connect(function(p)
		stateByPlayer[p] = nil
	end)

	--=================================================================
	-- NẠP ĐẠN
	--=================================================================
	activeReloadRemote.OnServerEvent:Connect(function(player)
		local char = player.Character
		if not char then
			return
		end
		local tool = char:FindFirstChildOfClass("Tool")
		if not tool or tool:GetAttribute("IsGtaWeapon") ~= true then
			return
		end
		local spec = SPECS[tool.Name]
		if not spec or spec.mag <= 0 then
			return
		end
		local st = getState(player)
		local ammo = st.ammo[tool.Name]
		if not ammo then
			return
		end
		local now = os.clock()
		if now - st.lastReloadAt < spec.reloadTime then
			return
		end
		if ammo.mag >= spec.mag or ammo.reserve <= 0 then
			return
		end
		st.lastReloadAt = now

		task.delay(spec.reloadTime, function()
			local cur = st.ammo[tool.Name]
			if not cur then
				return
			end
			local need = spec.mag - cur.mag
			local take = math.min(need, cur.reserve)
			cur.mag += take
			cur.reserve -= take
			pushAmmo(player, tool.Name, false)
		end)
	end)

	--=================================================================
	-- BẮN / CHÉM
	--=================================================================
	activeFireRemote.OnServerEvent:Connect(function(player, originPos, aimPos)
		if typeof(originPos) ~= "Vector3" or typeof(aimPos) ~= "Vector3" then
			return
		end

		local char = player.Character
		if not char then
			return
		end
		local tool = char:FindFirstChildOfClass("Tool")
		if not tool or tool:GetAttribute("IsGtaWeapon") ~= true then
			return
		end
		local spec = SPECS[tool.Name]
		if not spec then
			return
		end

		local st = getState(player)
		local now = os.clock()
		if now - st.lastShotAt < spec.cooldown * 0.75 then
			return
		end

		-- Kiểm tra đạn
		local ammo = st.ammo[tool.Name]
		if ammo then
			if ammo.mag <= 0 then
				pushAmmo(player, tool.Name, true)
				return
			end
		end

		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp or (originPos - hrp.Position).Magnitude > 26 then
			return
		end

		local dirVec = aimPos - originPos
		if dirVec.Magnitude < 0.05 then
			return
		end

		st.lastShotAt = now

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local deb = Workspace:FindFirstChild("LosSantos_Debris")
		params.FilterDescendantsInstances = if deb then { char, deb } else { char }

		local hitSomething = false
		local shatteredAny = false
		local pellets = math.max(1, spec.pellets)

		for i = 1, pellets do
			local shotDir = dirVec.Unit
			if pellets > 1 or spec.spread > 0 then
				local spreadRad = math.rad(spec.spread)
				shotDir = (dirVec.Unit + Vector3.new(
					(math.random() - 0.5) * 2 * spreadRad,
					(math.random() - 0.5) * 2 * spreadRad,
					(math.random() - 0.5) * 2 * spreadRad
				)).Unit
			end

			local result = Workspace:Raycast(originPos, shotDir * spec.range, params)
			if result and result.Instance and result.Instance:IsA("BasePart") then
				local hitPart = result.Instance
				local hitModel = hitPart:FindFirstAncestorOfClass("Model")
				local hitHum = if hitModel then hitModel:FindFirstChildOfClass("Humanoid") else nil

				if hitHum and hitModel ~= char then
					hitHum:TakeDamage(spec.damage * 0.7)
					hitSomething = true
				else
					local shattered = DestructionManager.damagePart(
						hitPart,
						spec.damage,
						result.Position,
						shotDir * spec.impulse + Vector3.new(0, 8, 0)
					)
					if shattered then
						shatteredAny = true
					end
					if hitPart:GetAttribute("Destructible") == true or shattered or (hitModel and hitModel:GetAttribute("IsGtaVehicle") == true) then
						hitSomething = true
					end
				end
			end
		end

		if ammo then
			ammo.mag = math.max(0, ammo.mag - 1)
			pushAmmo(player, tool.Name, ammo.mag <= 0)
		end

		if hitSomething then
			activeFireRemote:FireClient(player, "hit", shatteredAny)
		end
	end)
end

WeaponManager.SPECS = SPECS
WeaponManager.WEAPON_ORDER = WEAPON_ORDER

return WeaponManager
