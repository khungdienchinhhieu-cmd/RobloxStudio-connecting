--!strict
--[[
	CarryManager.luau  (Sync v25 — CƠ CHẾ TAY: NHẶT · THA · NÉM)
	================================================================================
	Người chơi nhặt đồ bằng TAY rồi tha đi khắp thành phố:

	    [E] Nhặt      → món đồ dính vào trước ngực, hai tay nâng lên (client vẽ)
	    [G] Thả       → đặt xuống đất ngay trước mặt
	    [Chuột trái / F] Ném → bay theo hướng nhìn; trúng tường thì trừ PartHealth,
	                            trúng NPC / người chơi thì trừ máu, chạm đất thì nằm đó

	Món đồ ném đi sẽ được **tự xếp lại lên kệ sau 20 giây** để cửa hàng không bao giờ
	hết hàng.

	Kệ hàng lấy từ `Shared/Carryables.luau` (bảng RACKS) và neo theo quầy dịch vụ của
	`BuildingServices` — nên đồ luôn nằm ở chỗ thoáng, không lọt vào trong khối nhà.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Carryables = require(Shared:WaitForChild("Carryables"))
local World = Shared:WaitForChild("World")
local BuildingServices = require(World:WaitForChild("BuildingServices"))

local DestructionManager = require(script.Parent:WaitForChild("DestructionManager"))

local CarryManager = {}

local hudRemote: RemoteEvent? = nil
local carryStateRemote: RemoteEvent? = nil
local carryActionRemote: RemoteEvent? = nil
local carryFolder: Folder? = nil

-- player -> { part = BasePart, kind = Kind, weld = Weld, rackAt = Vector3 }
local carried: { [Player]: any } = {}
-- mọi món đồ đang tồn tại (để xếp lại kệ)
local racks: { { anchor: string, kind: string, positions: { Vector3 } } } = {}
local respawnQueue: { { kindId: string, cframe: CFrame } } = {}

local CARRY_OFFSET = CFrame.new(0, 0.55, -2.35)
local THROW_MIN_SPEED = 26

-- ══════════════════════════════════════════════════════════════════════════════
-- TIỆN ÍCH
-- ══════════════════════════════════════════════════════════════════════════════

local function toast(player: Player, message: string, color: Color3?)
	if hudRemote then
		hudRemote:FireClient(player, {
			message = message,
			color = color or Color3.fromRGB(250, 204, 21),
		})
	end
end

local function pushState(player: Player)
	if not carryStateRemote then
		return
	end
	local c = carried[player]
	if c then
		carryStateRemote:FireClient(player, {
			action = "grab",
			kind = c.kind.id,
			display = c.kind.display,
			icon = c.kind.icon,
		})
	else
		carryStateRemote:FireClient(player, { action = "release" })
	end
	player:SetAttribute("Carrying", c ~= nil)
end

local function humanoidOf(player: Player): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function rootPartOf(player: Player): BasePart?
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return if hrp and hrp:IsA("BasePart") then hrp else nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TẠO MÓN ĐỒ
-- ══════════════════════════════════════════════════════════════════════════════

local function makeItem(kindId: string, cframe: CFrame, anchored: boolean): Part?
	local kind = Carryables.get(kindId)
	if not kind then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = "Carry_" .. kind.id .. "_" .. tostring(math.random(1000, 9999))
	p.Size = kind.size
	p.Color = kind.color
	p.Material = kind.material
	if kind.shape then
		p.Shape = kind.shape
	end
	p.CFrame = cframe
	p.Anchored = anchored
	p.CanCollide = anchored
	p.CanQuery = true
	p.CanTouch = true
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p:SetAttribute("CarryKind", kind.id)
	p:SetAttribute("CarryDisplay", kind.display)
	p:SetAttribute("Destructible", false)
	p:SetAttribute("Pickupable", true)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Nhặt " .. kind.display
	prompt.ObjectText = kind.display
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = p

	prompt.Triggered:Connect(function(player)
		CarryManager.grab(player, p)
	end)

	if carryFolder then
		p.Parent = carryFolder
	end
	return p
end

local function spawnRack(rack: any): number
	local service = nil
	for _, s in ipairs(BuildingServices.LIST) do
		if s.id == rack.anchor then
			service = s
			break
		end
	end
	if not service then
		return 0
	end
	local anchorPos = BuildingServices.worldPosition(service)
	if not anchorPos then
		return 0
	end
	local kind = Carryables.get(rack.kind)
	if not kind then
		return 0
	end

	local positions: { Vector3 } = {}
	local made = 0
	for i = 1, rack.count do
		local angle = (i / rack.count) * math.pi * 2
		local r = rack.spread * (0.55 + 0.45 * math.random())
		local pos = anchorPos + Vector3.new(math.cos(angle) * r, 0.6 + (kind.size.Y * 0.5), math.sin(angle) * r)
		local tilt = Vector3.new(0, math.random(0, 359), 0)
		if kind.carryTilt then
			tilt = tilt + kind.carryTilt
		end
		local cf = CFrame.new(pos) * CFrame.Angles(math.rad(tilt.X), math.rad(tilt.Y), math.rad(tilt.Z))
		local item = makeItem(rack.kind, cf, true)
		if item then
			item:SetAttribute("RackAnchor", rack.anchor)
			table.insert(positions, pos)
			made += 1
		end
	end
	if made > 0 then
		table.insert(racks, { anchor = rack.anchor, kind = rack.kind, positions = positions })
	end
	return made
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NHẶT / THẢ / NÉM
-- ══════════════════════════════════════════════════════════════════════════════

local function detach(c: any)
	if c.weld then
		c.weld:Destroy()
		c.weld = nil
	end
end

function CarryManager.grab(player: Player, part: Part): boolean
	if not part or not part.Parent then
		return false
	end
	if carried[player] then
		CarryManager.drop(player)
	end
	local kind = Carryables.get(part:GetAttribute("CarryKind") or "")
	local hrp = rootPartOf(player)
	local hum = humanoidOf(player)
	if not kind or not hrp or not hum then
		return false
	end

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end

	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = hrp.CFrame * CARRY_OFFSET

	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = hrp
	weld.Part1 = part
	local base = kind.carryTilt
	if base then
		weld.C0 = CARRY_OFFSET * CFrame.Angles(math.rad(base.X), math.rad(base.Y), math.rad(base.Z))
	else
		weld.C0 = CARRY_OFFSET
	end
	weld.Parent = part

	-- Đang vác đồ thì cất súng đi (GTA: hai tay bận)
	pcall(function()
		hum:UnequipTools()
	end)

	carried[player] = { part = part, kind = kind, weld = weld }
	pushState(player)
	toast(player, string.format("%s Đã nhặt %s · G để thả · chuột trái/F để ném", kind.icon, kind.display))
	return true
end

function CarryManager.drop(player: Player): boolean
	local c = carried[player]
	if not c then
		return false
	end
	carried[player] = nil
	local part = c.part
	detach(c)
	if not part.Parent then
		pushState(player)
		return false
	end
	local hrp = rootPartOf(player)
	local pos = if hrp then hrp.Position + hrp.CFrame.LookVector * 3.2 else part.Position
	local cf = CFrame.new(pos.X, math.max(pos.Y, 2.0), pos.Z) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0)
	part.CFrame = cf
	part.Anchored = false
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	part.Massless = false
	part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = true
	end

	pushState(player)
	toast(player, string.format("%s Đã thả %s", c.kind.icon, c.kind.display), Color3.fromRGB(148, 163, 184))
	return true
end

local function armImpact(part: Part, kind: any, bornAt: number)
	local spent = false
	part.Touched:Connect(function(hit)
		if spent or not part.Parent then
			return
		end
		if os.clock() - bornAt < 0.12 then
			return
		end
		local speed = part.AssemblyLinearVelocity.Magnitude
		if speed < THROW_MIN_SPEED then
			return
		end

		-- 1. Trúng người (NPC hoặc người chơi) -> trừ máu
		local model = hit:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			hum:TakeDamage(kind.damage)
		end

		-- 2. Trúng khối phá huỷ -> trừ PartHealth (gạch làm nứt tường!)
		if hit:GetAttribute("Destructible") == true then
			local impulse = part.AssemblyLinearVelocity.Unit * (kind.damage * 3)
			pcall(function()
				DestructionManager.damagePart(hit, kind.damage * 2.2, hit.Position, impulse)
			end)
			spent = true
			part:Destroy()
			return
		end

		-- 3. Trúng vật cứng -> dừng lại, nằm đó
		if hit.Material ~= Enum.Material.Air and hit.Material ~= Enum.Material.Water then
			part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			part.CanCollide = true
		end
	end)
end

function CarryManager.throw(player: Player, power: number?): boolean
	local c = carried[player]
	if not c then
		return false
	end
	carried[player] = nil
	local part = c.part
	local kind = c.kind
	detach(c)
	if not part.Parent then
		pushState(player)
		return false
	end
	local hrp = rootPartOf(player)
	local look = if hrp then hrp.CFrame.LookVector else Vector3.new(0, 0, -1)
	local base = if hrp then hrp.Position + look * 2.4 + Vector3.new(0, 0.6, 0) else part.Position
	part.CFrame = CFrame.new(base) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0)
	part.Anchored = false
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	part.Massless = false

	local mult = math.clamp(power or 1, 0.6, 1.6)
	local speed = kind.throwSpeed * mult
	part.AssemblyLinearVelocity = look * speed + Vector3.new(0, 7, 0)
	part.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))

	local bornAt = os.clock()
	armImpact(part, kind, bornAt)

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = true
	end

	pushState(player)
	toast(player, string.format("%s Đã ném %s", kind.icon, kind.display), Color3.fromRGB(251, 146, 60))

	-- Xếp lại kệ sau 20 giây để cửa hàng luôn có hàng
	task.delay(20, function()
		if part.Parent then
			part:Destroy()
		end
	end)
	return true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- KHỞI TẠO
-- ══════════════════════════════════════════════════════════════════════════════

function CarryManager.init(remotes: Instance, hud: RemoteEvent, root: Instance)
	hudRemote = hud

	local existing = root:FindFirstChild("Carryables")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Carryables"
	folder.Parent = root
	carryFolder = folder

	local cr = remotes:FindFirstChild("CarryAction") :: RemoteEvent?
	if not cr then
		local created = Instance.new("RemoteEvent")
		created.Name = "CarryAction"
		created.Parent = remotes
		cr = created
	end
	carryActionRemote = cr :: RemoteEvent

	local stateRemote = remotes:FindFirstChild("CarryState") :: RemoteEvent?
	if not stateRemote then
		local created = Instance.new("RemoteEvent")
		created.Name = "CarryState"
		created.Parent = remotes
		stateRemote = created
	end
	carryStateRemote = stateRemote :: RemoteEvent

	(carryActionRemote :: RemoteEvent).OnServerEvent:Connect(function(player, action, arg)
		if action == "drop" then
			CarryManager.drop(player)
		elseif action == "throw" then
			CarryManager.throw(player, tonumber(arg))
		elseif action == "sync" then
			-- client vừa hồi sinh / mới vào: gửi lại trạng thái thật từ server
			pushState(player)
		end
	end)

	local total = 0
	for _, rack in ipairs(Carryables.RACKS) do
		total += spawnRack(rack)
	end

	Players.PlayerRemoving:Connect(function(player)
		local c = carried[player]
		if c then
			carried[player] = nil
			detach(c)
			if c.part.Parent then
				c.part:Destroy()
			end
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.4)
			pushState(player)
		end)
	end)

	print(string.format("[CarryManager] Đã xếp %d món đồ ở %d kệ (lốp · gạch · thùng · cọc · chai)", total, #racks))
	return total
end

function CarryManager.getCarriedKind(player: Player): string?
	local c = carried[player]
	return if c then c.kind.id else nil
end

return CarryManager
