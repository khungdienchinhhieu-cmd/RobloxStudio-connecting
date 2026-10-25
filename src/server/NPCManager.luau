--!nonstrict
--[[
	NPCManager.luau  —  HỆ THỐNG NPC PHẢN ỨNG (GTA V STYLE)
	================================================================================
	NPC đi lại trên vỉa hè. Khi bị người chơi tấn công (đấm, bắn, nổ RPG),
	NPC sẽ CHỌN MỘT trong 4 phản ứng tuỳ theo "tính cách" + loại vũ khí:

	  1. SHOOT        — rút súng bắn trả (hạ súng, nhắm, bắn từng loạt)
	  2. FLEE         — hoảng loạn bỏ chạy khỏi kẻ tấn công
	  3. CALL_POLICE  — rút điện thoại QUAY VIDEO rồi gọi cảnh sát
	                    (tăng WantedLevel + điều 2 cảnh sát tới hiện trường)
	  4. MELEE        — lao vào đánh tay không

	NPC có 2 tư thế: ĐI TUẦN (patrol) và PHẢN ỨNG (react).
	Sau khi hết thời gian phản ứng, NPC bình tĩnh lại và đi tiếp.

	TÍCH HỢP
	  • WeaponManager gọi `NPCManager.notifyAttacked(model, player, hitPos)` khi đạn trúng.
	  • RPG gọi `NPCManager.notifyExplosion(center, radius, player)` khi nổ.
	  • Mọi NPC có attribute `IsGTA_NPC = true` và Humanoid (nên đạn thường đã gây sát thương).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local NPCManager = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- 1. BẢNG TÍNH CÁCH NPC
-- ══════════════════════════════════════════════════════════════════════════════

export type Archetype = {
	id: string,
	label: string,
	skin: Color3,
	shirt: Color3,
	pants: Color3,
	hair: Color3,
	health: number,
	walkSpeed: number,
	bravery: number, -- 0 = hèn nhát, 1 = liều mạng
	armed: boolean, -- có súng trong người
	hasPhone: boolean,
	weights: { [string]: number }, -- trọng số phản ứng gốc
}

local ARCHETYPES: { [string]: Archetype } = {
	CIVILIAN = {
		id = "CIVILIAN",
		label = "Dân thường",
		skin = Color3.fromRGB(206, 160, 118),
		shirt = Color3.fromRGB(72, 96, 132),
		pants = Color3.fromRGB(58, 62, 72),
		hair = Color3.fromRGB(52, 38, 28),
		health = 100,
		walkSpeed = 9,
		bravery = 0.2,
		armed = false,
		hasPhone = true,
		weights = { SHOOT = 0, FLEE = 62, CALL_POLICE = 30, MELEE = 8 },
	},
	BUSINESS = {
		id = "BUSINESS",
		label = "Doanh nhân",
		skin = Color3.fromRGB(224, 182, 140),
		shirt = Color3.fromRGB(34, 40, 54),
		pants = Color3.fromRGB(28, 32, 42),
		hair = Color3.fromRGB(38, 34, 30),
		health = 100,
		walkSpeed = 10,
		bravery = 0.35,
		armed = false,
		hasPhone = true,
		-- Doanh nhân giàu: ưu tiên quay video/gọi cảnh sát hơn là bỏ chạy
		weights = { SHOOT = 0, FLEE = 28, CALL_POLICE = 62, MELEE = 10 },
	},
	TOURIST = {
		id = "TOURIST",
		label = "Khách du lịch",
		skin = Color3.fromRGB(232, 196, 160),
		shirt = Color3.fromRGB(214, 120, 76),
		pants = Color3.fromRGB(198, 196, 190),
		hair = Color3.fromRGB(186, 148, 82),
		health = 90,
		walkSpeed = 8,
		bravery = 0.1,
		armed = false,
		hasPhone = true,
		weights = { SHOOT = 0, FLEE = 48, CALL_POLICE = 46, MELEE = 6 },
	},
	GANGSTER = {
		id = "GANGSTER",
		label = "Đầu gấu đường phố",
		skin = Color3.fromRGB(150, 108, 74),
		shirt = Color3.fromRGB(146, 40, 44),
		pants = Color3.fromRGB(44, 46, 54),
		hair = Color3.fromRGB(26, 24, 24),
		health = 140,
		walkSpeed = 12,
		bravery = 0.85,
		armed = true,
		hasPhone = false,
		-- Tay anh chị: gần như luôn bắn trả hoặc lao vào
		weights = { SHOOT = 58, FLEE = 4, CALL_POLICE = 0, MELEE = 38 },
	},
	BRAWLER = {
		id = "BRAWLER",
		label = "Dân anh chị",
		skin = Color3.fromRGB(190, 146, 106),
		shirt = Color3.fromRGB(196, 190, 178),
		pants = Color3.fromRGB(38, 44, 60),
		hair = Color3.fromRGB(30, 28, 26),
		health = 125,
		walkSpeed = 11,
		bravery = 0.9,
		armed = false,
		hasPhone = false,
		-- chỉ biết đánh tay không
		weights = { SHOOT = 0, FLEE = 5, CALL_POLICE = 0, MELEE = 95 },
	},
	COP = {
		id = "COP",
		label = "Cảnh sát LSPD",
		skin = Color3.fromRGB(210, 166, 124),
		shirt = Color3.fromRGB(28, 46, 88),
		pants = Color3.fromRGB(24, 34, 62),
		hair = Color3.fromRGB(34, 32, 30),
		health = 200,
		walkSpeed = 14,
		bravery = 1.0,
		armed = true,
		hasPhone = true,
		weights = { SHOOT = 92, FLEE = 0, CALL_POLICE = 3, MELEE = 5 },
	},
}

NPCManager.ARCHETYPES = ARCHETYPES

-- ══════════════════════════════════════════════════════════════════════════════
-- 2. HẰNG SỐ HÀNH VI
-- ══════════════════════════════════════════════════════════════════════════════

local REACTION_LABEL = {
	SHOOT = "🔫 BẮN TRẢ",
	FLEE = "🏃 CHẠY TRỐN",
	CALL_POLICE = "📱 ĐANG QUAY VIDEO",
	MELEE = "👊 ĐÁNH TAY KHÔNG",
}

local REACTION_COLOR = {
	SHOOT = Color3.fromRGB(248, 113, 113),
	FLEE = Color3.fromRGB(251, 191, 36),
	CALL_POLICE = Color3.fromRGB(56, 189, 248),
	MELEE = Color3.fromRGB(251, 146, 60),
}

local MAX_NPCS = 26
local NPC_FOLDER_NAME = "LosSantos_NPCs"
local HEARTBEAT = 0.12

-- ══════════════════════════════════════════════════════════════════════════════
-- 3. TRẠNG THÁI
-- ══════════════════════════════════════════════════════════════════════════════

type NPCState = {
	model: Model,
	hum: Humanoid,
	hrp: BasePart,
	head: BasePart,
	arch: Archetype,
	folder: Folder,
	state: string, -- "PATROL" | "REACT" | "DEAD"
	reaction: string?,
	attacker: Player?,
	reactUntil: number,
	nextShot: number,
	nextMelee: number,
	patrolTarget: Vector3,
	nextPatrolAt: number,
	gunModel: Model?,
	phone: BasePart?,
	bubble: BillboardGui?,
	gunFlashAt: number,
	lastGoal: Vector3?,
	lastMoveAt: number,
}

local states: { [Model]: NPCState } = {}
local npcFolder: Folder? = nil
local hudRemote: RemoteEvent? = nil
local ambientSpawned = false

local function now(): number
	return os.clock()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 4. DỰNG RIG R6
-- ══════════════════════════════════════════════════════════════════════════════

local function mkPart(name: string, size: Vector3, color: Color3, parent: Instance, collide: boolean?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = collide == true
	p.CanTouch = false
	p.CanQuery = true
	p.Parent = parent
	return p
end

local function mkMotor(name: string, p0: BasePart, p1: BasePart, c0: CFrame, c1: CFrame, parent: Instance)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = c0
	m.C1 = c1
	m.Parent = parent
end

local function buildRig(arch: Archetype, cf: CFrame): (Model, Humanoid, BasePart, BasePart)
	local model = Instance.new("Model")
	model.Name = "NPC_" .. arch.id .. "_" .. tostring(math.random(1000, 9999))

	local hrp = mkPart("HumanoidRootPart", Vector3.new(2, 2, 1), arch.shirt, model, false)
	hrp.Transparency = 1
	local torso = mkPart("Torso", Vector3.new(2, 2, 1), arch.shirt, model, true)
	local head = mkPart("Head", Vector3.new(1.4, 1.4, 1.4), arch.skin, model, false)
	local larm = mkPart("Left Arm", Vector3.new(1, 2, 1), arch.shirt, model, false)
	local rarm = mkPart("Right Arm", Vector3.new(1, 2, 1), arch.shirt, model, false)
	-- Chân PHẢI va chạm: đây là bộ phận đỡ cả rig đứng trên mặt đất (giống R6 thật).
	-- Nếu để false, chỉ còn Torso va chạm -> thân tụt xuống, chân lún 2 stud vào mặt đường.
	local lleg = mkPart("Left Leg", Vector3.new(1, 2, 1), arch.pants, model, true)
	local rleg = mkPart("Right Leg", Vector3.new(1, 2, 1), arch.pants, model, true)

	-- tóc / mũ (đặt trên ĐỈNH đầu: đầu cao 1,4 -> đỉnh đầu ở +2,4 so với HumanoidRootPart)
	local hair = mkPart("Hair", Vector3.new(1.5, 0.44, 1.5), arch.hair, model, false)
	hair.CanQuery = false
	hair.Massless = true
	hair.CFrame = cf * CFrame.new(0, 2.19, 0)

	hrp.CFrame = cf
	torso.CFrame = cf
	head.CFrame = cf * CFrame.new(0, 1.7, 0)
	larm.CFrame = cf * CFrame.new(-1.5, 0, 0)
	rarm.CFrame = cf * CFrame.new(1.5, 0, 0)
	lleg.CFrame = cf * CFrame.new(-0.5, -2, 0)
	rleg.CFrame = cf * CFrame.new(0.5, -2, 0)

	mkMotor("RootJoint", hrp, torso, CFrame.new(), CFrame.new(), hrp)
	mkMotor("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.7, 0), torso)
	mkMotor("Right Shoulder", torso, rarm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0), torso)
	mkMotor("Left Shoulder", torso, larm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0), torso)
	mkMotor("Right Hip", torso, rleg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0), torso)
	mkMotor("Left Hip", torso, lleg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0), torso)

	-- mặt: mắt
	local function eye(dx: number)
		local e = mkPart("Eye", Vector3.new(0.22, 0.22, 0.06), Color3.fromRGB(20, 20, 24), model, false)
		e.CanQuery = false
		e.Massless = true
		e.CFrame = cf * CFrame.new(dx, 1.78, -0.71)
		return e
	end
	local e1 = eye(-0.26)
	local e2 = eye(0.26)
	mkMotor("EyeL", head, e1, CFrame.new(-0.26, 0.08, -0.71), CFrame.new(), head)
	mkMotor("EyeR", head, e2, CFrame.new(0.26, 0.08, -0.71), CFrame.new(), head)
	-- tóc phải có khớp, nếu không sẽ RƠI khỏi đầu khi chạy (part không neo + không weld)
	mkMotor("HairJoint", head, hair, CFrame.new(0, 0.49, 0), CFrame.new(), head)

	-- Humanoid
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.RigType = Enum.HumanoidRigType.R6
	hum.MaxHealth = arch.health
	hum.Health = arch.health
	hum.WalkSpeed = arch.walkSpeed
	hum.JumpPower = 0
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	model.PrimaryPart = hrp
	model:SetAttribute("IsGTA_NPC", true)
	model:SetAttribute("Archetype", arch.id)

	return model, hum, hrp, head
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 5. BONG BÓNG PHẢN ỨNG (BILLBOARD)
-- ══════════════════════════════════════════════════════════════════════════════

local function setBubble(st: NPCState, text: string?, color: Color3?)
	local head = st.head
	local gui = st.bubble
	if not text then
		if gui then
			gui.Enabled = false
		end
		return
	end
	if not gui then
		local bb = Instance.new("BillboardGui")
		bb.Name = "NPCTag"
		bb.Size = UDim2.fromOffset(190, 54)
		bb.StudsOffset = Vector3.new(0, 2.0, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 120
		bb.Adornee = head
		bb.Parent = head

		local lbl = Instance.new("TextLabel")
		lbl.Name = "Tag"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
		lbl.BackgroundTransparency = 0.25
		lbl.BorderSizePixel = 0
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = false
		lbl.TextSize = 17
		lbl.TextColor3 = Color3.fromRGB(241, 245, 249)
		lbl.Text = ""
		lbl.Parent = bb

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = lbl

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(38, 48, 64)
		stroke.Parent = lbl

		st.bubble = bb
		gui = bb
	end
	gui.Enabled = true
	local lbl = gui:FindFirstChild("Tag") :: TextLabel
	lbl.Text = text
	lbl.TextColor3 = color or Color3.fromRGB(241, 245, 249)
	local stroke = lbl:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color or Color3.fromRGB(38, 48, 64)
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 6. SÚNG / ĐIỆN THOẠI CẦM TAY
-- ══════════════════════════════════════════════════════════════════════════════

local function equipGun(st: NPCState)
	if st.gunModel then
		return
	end
	local model = Instance.new("Model")
	model.Name = "NPCPistol"
	model.Parent = st.model

	local body = mkPart("Body", Vector3.new(0.24, 0.34, 1.0), Color3.fromRGB(38, 40, 46), model, false)
	body.CanQuery = false
	body.CFrame = st.hrp.CFrame * CFrame.new(0.9, 1.2, -0.9)
	local grip = mkPart("Grip", Vector3.new(0.22, 0.44, 0.3), Color3.fromRGB(26, 28, 34), model, false)
	grip.CanQuery = false
	grip.CFrame = body.CFrame * CFrame.new(0, -0.3, 0.28)
	local muzzle = mkPart("Muzzle", Vector3.new(0.1, 0.1, 0.1), Color3.fromRGB(255, 214, 120), model, false)
	muzzle.CanQuery = false
	muzzle.Transparency = 1
	muzzle.CFrame = body.CFrame * CFrame.new(0, 0, -0.58)

	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = body
	w1.Part1 = st.model:FindFirstChild("Right Arm") :: BasePart
	w1.Parent = body
	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = body
	w2.Part1 = grip
	w2.Parent = grip
	local w3 = Instance.new("WeldConstraint")
	w3.Part0 = body
	w3.Part1 = muzzle
	w3.Parent = muzzle

	st.gunModel = model
end

local function equipPhone(st: NPCState)
	if st.phone then
		return st.phone
	end
	local p = mkPart("Phone", Vector3.new(0.42, 0.78, 0.08), Color3.fromRGB(16, 18, 24), st.model, false)
	p.CanQuery = false
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = st.hrp.CFrame * CFrame.new(0.95, 1.3, -0.6)

	local screen = mkPart("PhoneScreen", Vector3.new(0.36, 0.68, 0.02), Color3.fromRGB(56, 189, 248), p.Parent, false)
	screen.CanQuery = false
	screen.Material = Enum.Material.Neon
	screen.CFrame = p.CFrame * CFrame.new(0, 0, -0.05)

	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = p
	w1.Part1 = st.model:FindFirstChild("Right Arm") :: BasePart
	w1.Parent = p
	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = p
	w2.Part1 = screen
	w2.Parent = screen

	st.phone = p
	return p
end

local function stowHands(st: NPCState)
	if st.gunModel then
		st.gunModel:Destroy()
		st.gunModel = nil
	end
	if st.phone then
		st.phone:Destroy()
		st.phone = nil
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 7. CHỌN PHẢN ỨNG
-- ══════════════════════════════════════════════════════════════════════════════

local function pickWeighted(weights: { [string]: number }): string
	local total = 0
	for _, w in pairs(weights) do
		total += math.max(0, w)
	end
	if total <= 0 then
		return "FLEE"
	end
	local roll = math.random() * total
	local acc = 0
	for key, w in pairs(weights) do
		acc += math.max(0, w)
		if roll <= acc then
			return key
		end
	end
	return "FLEE"
end

-- kind: "BULLET" | "MELEE" | "EXPLOSION"
local function chooseReaction(arch: Archetype, kind: string, healthFrac: number): string
	local w: { [string]: number } = {}
	for k, v in pairs(arch.weights) do
		w[k] = v
	end

	if not arch.armed then
		w.SHOOT = 0
	end
	if not arch.hasPhone then
		w.CALL_POLICE = 0
	end

	if kind == "BULLET" then
		-- bị bắn: bỏ chạy và gọi cảnh sát tăng vọt
		w.FLEE = (w.FLEE or 0) * 1.35
		w.CALL_POLICE = (w.CALL_POLICE or 0) * 1.6
		w.MELEE = (w.MELEE or 0) * 0.35
	elseif kind == "MELEE" then
		-- bị đấm: dễ đánh trả tay không hơn
		w.MELEE = (w.MELEE or 0) * 1.8 + 18
		w.FLEE = (w.FLEE or 0) * 0.85
	elseif kind == "EXPLOSION" then
		-- tiếng nổ: hoảng loạn tối đa
		w.FLEE = (w.FLEE or 0) + 90
		w.CALL_POLICE = (w.CALL_POLICE or 0) + 30
		w.MELEE = 0
		w.SHOOT = (w.SHOOT or 0) * 0.3
	end

	-- máu thấp thì ưu tiên chạy
	if healthFrac < 0.35 then
		w.FLEE = (w.FLEE or 0) + 70
		w.MELEE = (w.MELEE or 0) * 0.3
	end

	-- cảnh sát : không bao giờ chạy
	if arch.id == "COP" then
		w.FLEE = 0
	end

	return pickWeighted(w)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 8. HÀNH ĐỘNG
-- ══════════════════════════════════════════════════════════════════════════════

local function dirTo(hrp: BasePart, target: Vector3): CFrame
	local flat = Vector3.new(target.X, hrp.Position.Y, target.Z)
	if (flat - hrp.Position).Magnitude < 0.1 then
		return hrp.CFrame
	end
	return CFrame.lookAt(hrp.Position, flat)
end

local function npcShoot(st: NPCState, targetPos: Vector3)
	local hrp = st.hrp
	local origin = (st.head and st.head.Position or hrp.Position) + Vector3.new(0, -0.3, 0)
	local aim = targetPos + Vector3.new(0, 1.2, 0)
	local dir = (aim - origin)
	if dir.Magnitude < 1 then
		return
	end
	dir = dir.Unit

	st.model:PivotTo(dirTo(hrp, targetPos))

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { st.model }

	local result = Workspace:Raycast(origin, dir * 160, params)
	if result and result.Instance then
		local part = result.Instance
		local model = part:FindFirstAncestorOfClass("Model")
		local hum = if model then model:FindFirstChildOfClass("Humanoid") else nil
		if hum and hum.Health > 0 then
			hum:TakeDamage(math.random(7, 12))
		end
	end

	if st.gunModel then
		local muzzle = st.gunModel:FindFirstChild("Muzzle")
		if muzzle and muzzle:IsA("BasePart") then
			local flash = Instance.new("Part")
			flash.Name = "NPCBoom"
			flash.Shape = Enum.PartType.Ball
			flash.Size = Vector3.new(1.1, 1.1, 1.1)
			flash.Color = Color3.fromRGB(255, 226, 150)
			flash.Material = Enum.Material.Neon
			flash.CanCollide = false
			flash.CanTouch = false
			flash.CanQuery = false
			flash.Transparency = 0.2
			flash.CFrame = muzzle.CFrame
			flash.Parent = npcFolder
			Debris:AddItem(flash, 0.08)
		end
	end
end

local function policeDispatch(attacker: Player)
	if not attacker.Character then
		return
	end
	local pos = attacker.Character:GetPivot().Position
	local current = attacker:GetAttribute("WantedLevel")
	local lvl = if type(current) == "number" then current else 0
	lvl = math.min(5, lvl + 1)
	attacker:SetAttribute("WantedLevel", lvl)
	attacker:SetAttribute("WantedUntil", now() + 90)

	-- dời tối đa 2 cảnh sát tới
	local count = 0
	for _, st in pairs(states) do
		if count >= 2 then
			break
		end
		if st.arch.id == "COP" and st.state ~= "DEAD" then
			st.state = "REACT"
			st.reaction = "SHOOT"
			st.attacker = attacker
			st.reactUntil = now() + 40
			st.nextShot = now() + 0.4
			equipGun(st)
			setBubble(st, "🚨 TỚI HIỆN TRƯỜNG", Color3.fromRGB(96, 165, 250))
			count += 1
		end
	end

	if hudRemote then
		hudRemote:FireClient(attacker, {
			message = string.format("LSPD ALERT: Nhân chứng đã gọi 911 — %d Sao, %d cảnh sát đang tới!", lvl, count),
			color = Color3.fromRGB(56, 189, 248),
		})
	end

	print(string.format("[NPC] 📞 Cảnh sát được gọi! WantedLevel = %d · điều %d cảnh sát tới (%.0f, %.0f)", lvl, count, pos.X, pos.Z))
end

local function startReaction(st: NPCState, reaction: string, attacker: Player?)
	st.state = "REACT"
	st.reaction = reaction
	st.attacker = attacker
	st.gunFlashAt = 0

	if reaction == "SHOOT" then
		equipGun(st)
		st.reactUntil = now() + math.random(8, 14)
		st.nextShot = now() + 0.6
		setBubble(st, REACTION_LABEL.SHOOT, REACTION_COLOR.SHOOT)
	elseif reaction == "FLEE" then
		stowHands(st)
		st.reactUntil = now() + math.random(6, 10)
		setBubble(st, REACTION_LABEL.FLEE, REACTION_COLOR.FLEE)
	elseif reaction == "CALL_POLICE" then
		stowHands(st)
		equipPhone(st)
		st.reactUntil = now() + 3.4
		setBubble(st, REACTION_LABEL.CALL_POLICE, REACTION_COLOR.CALL_POLICE)
		task.delay(2.4, function()
			if st.state == "REACT" and st.reaction == "CALL_POLICE" and attacker then
				setBubble(st, "📞 ĐÃ GỌI 911", Color3.fromRGB(96, 165, 250))
				policeDispatch(attacker)
			end
		end)
	elseif reaction == "MELEE" then
		stowHands(st)
		st.reactUntil = now() + math.random(7, 11)
		st.nextMelee = now() + 0.4
		setBubble(st, REACTION_LABEL.MELEE, REACTION_COLOR.MELEE)
	end
end

local function calmDown(st: NPCState)
	st.state = "PATROL"
	st.reaction = nil
	st.attacker = nil
	stowHands(st)
	setBubble(st, nil)
	st.nextPatrolAt = 0
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 9. ĐI TUẦN
-- ══════════════════════════════════════════════════════════════════════════════

local function rayFilter(): RaycastParams
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local list: { Instance } = {}
	if npcFolder then
		table.insert(list, npcFolder)
	end
	local deb = Workspace:FindFirstChild("LosSantos_Debris")
	if deb then
		table.insert(list, deb)
	end
	p.FilterDescendantsInstances = list
	return p
end

local function findGround(x: number, z: number): Vector3?
	local hit = Workspace:Raycast(Vector3.new(x, 90, z), Vector3.new(0, -120, 0), rayFilter())
	if hit and hit.Position.Y > 0.3 and hit.Position.Y < 4.2 then
		return hit.Position
	end
	return nil
end

local function pickPatrolTarget(st: NPCState): Vector3
	local base = st.hrp.Position
	for _ = 1, 8 do
		local ang = math.random() * math.pi * 2
		local dist = math.random(12, 34)
		local gx = base.X + math.cos(ang) * dist
		local gz = base.Z + math.sin(ang) * dist
		local g = findGround(gx, gz)
		if g and math.abs(g.Y - base.Y) < 1.6 then
			return g
		end
	end
	return base
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 10. VÒNG LẶP CHÍNH
-- ══════════════════════════════════════════════════════════════════════════════

-- Gọi Humanoid:MoveTo CÓ TIẾT CHẾ: gọi mỗi 0,12 s làm NPC giật và tốn CPU.
-- Chỉ gọi lại khi đổi đích > 6 stud hoặc đã quá 1,1 s.
local function moveTo(st: NPCState, goal: Vector3, t: number)
	local last = st.lastGoal
	if last and (last - goal).Magnitude < 6 and (t - st.lastMoveAt) < 1.1 then
		return
	end
	st.lastGoal = goal
	st.lastMoveAt = t
	st.hum:MoveTo(goal)
end

local function tickOne(st: NPCState)
	if st.state == "DEAD" then
		-- model đã bị Debris dọn -> xoá khỏi bảng để không rò rỉ / chặn trần NPC
		if not st.model.Parent then
			states[st.model] = nil
		end
		return
	end
	local hum = st.hum
	if not st.model.Parent or hum.Health <= 0 then
		st.state = "DEAD"
		setBubble(st, nil)
		stowHands(st)
		Debris:AddItem(st.model, 8)
		return
	end

	local t = now()

	-- giảm wanted level
	if st.attacker and st.attacker:GetAttribute("WantedUntil") then
		local untilT = st.attacker:GetAttribute("WantedUntil") :: number
		if type(untilT) == "number" and t > untilT then
			st.attacker:SetAttribute("WantedLevel", 0)
		end
	end

	if st.state == "PATROL" then
		if t >= st.nextPatrolAt then
			st.nextPatrolAt = t + math.random(4, 9)
			st.patrolTarget = pickPatrolTarget(st)
		end
		if (st.patrolTarget - st.hrp.Position).Magnitude > 2.5 then
			moveTo(st, st.patrolTarget, t)
		else
			moveTo(st, st.hrp.Position, t)
		end
		return
	end

	-- REACT
	local att = st.attacker
	local attPos: Vector3? = nil
	if att and att.Character then
		local c = att.Character
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			attPos = hrp.Position
		end
	end

	if t > st.reactUntil or not attPos then
		calmDown(st)
		return
	end

	local ap = attPos :: Vector3
	local dist = (ap - st.hrp.Position).Magnitude

	if st.reaction == "SHOOT" then
		local desired = math.clamp(dist, 14, 30)
		local toAtt = (ap - st.hrp.Position)
		if toAtt.Magnitude > 0.1 then
			local back = st.hrp.Position + (toAtt.Unit * -1) * (desired - dist)
			moveTo(st, back, t)
		end
		-- KHÔNG xoay mỗi tick ở đây: Humanoid.AutoRotate đang bật, xoay 8 lần/giây
		-- sẽ giằng co với AutoRotate -> NPC rung lắc. Việc ngắm đã nằm trong npcShoot().
		if t >= st.nextShot and dist < 90 then
			st.nextShot = t + math.random(11, 19) / 10
			npcShoot(st, ap)
		end
	elseif st.reaction == "FLEE" then
		local away = (st.hrp.Position - ap)
		if away.Magnitude > 0.1 then
			local goal = st.hrp.Position + away.Unit * 30
			moveTo(st, goal, t)
		end
	elseif st.reaction == "CALL_POLICE" then
		moveTo(st, st.hrp.Position, t)
		st.model:PivotTo(dirTo(st.hrp, ap))
	elseif st.reaction == "MELEE" then
		moveTo(st, ap, t)
		if dist < 4.6 and t >= st.nextMelee then
			st.nextMelee = t + 0.95
			local victim = att.Character and att.Character:FindFirstChildOfClass("Humanoid")
			if victim then
				victim:TakeDamage(math.random(6, 10))
			end
			setBubble(st, "👊", REACTION_COLOR.MELEE)
		end
	end
end

local loopRunning = false
local function startLoop()
	if loopRunning then
		return
	end
	loopRunning = true
	task.spawn(function()
		while true do
			task.wait(HEARTBEAT)
			for _, st in pairs(states) do
				local ok, err = pcall(tickOne, st)
				if not ok then
					warn("[NPC] lỗi tick:", err)
				end
			end
		end
	end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 11. API CÔNG KHAI
-- ══════════════════════════════════════════════════════════════════════════════

function NPCManager.spawn(archetypeId: string, position: Vector3): Model?
	local arch = ARCHETYPES[archetypeId]
	if not arch then
		return nil
	end
	if not npcFolder then
		return nil
	end
	-- Trần NPC: đếm các NPC còn sống (xác đang chờ Debris dọn không tính)
	local living = 0
	for _, other in pairs(states) do
		if other.model.Parent and other.state ~= "DEAD" then
			living += 1
		end
	end
	if living >= MAX_NPCS then
		return nil
	end

	local ground = findGround(position.X, position.Z)
	local baseY = if ground then ground.Y else position.Y
	-- Rig R6: HumanoidRootPart nằm ngang Torso, chân dài 2 stud ở DƯỚI -> tâm HRP cách đất 3 stud.
	-- Cộng 0,06 để bàn chân không xuyên vào mặt đường ngay khung hình đầu.
	local cf = CFrame.new(position.X, baseY + 3.06, position.Z) * CFrame.Angles(0, math.random() * math.pi * 2, 0)

	local model, hum, hrp, head = buildRig(arch, cf)
	model.Parent = npcFolder

	local st: NPCState = {
		model = model,
		hum = hum,
		hrp = hrp,
		head = head,
		arch = arch,
		folder = npcFolder :: Folder,
		state = "PATROL",
		reaction = nil,
		attacker = nil,
		reactUntil = 0,
		nextShot = 0,
		nextMelee = 0,
		patrolTarget = hrp.Position,
		nextPatrolAt = 0,
		gunModel = nil,
		phone = nil,
		bubble = nil,
		gunFlashAt = 0,
		lastGoal = nil,
		lastMoveAt = 0,
	}
	states[model] = st

	setBubble(st, nil)
	startLoop()
	return model
end

--- Gọi khi NPC bị trúng đạn / đấm.
function NPCManager.notifyAttacked(model: Model, attacker: Player?, kind: string?)
	local st = states[model]
	if not st or st.state == "DEAD" then
		return
	end
	local hum = st.hum
	if hum.Health <= 0 then
		return
	end

	-- đang phản ứng rồi thì chỉ gia hạn, không đổi phản ứng
	if st.state == "REACT" and st.attacker == attacker then
		st.reactUntil = math.max(st.reactUntil, now() + 6)
		return
	end

	local reaction = chooseReaction(st.arch, kind or "BULLET", hum.Health / math.max(1, hum.MaxHealth))
	startReaction(st, reaction, attacker)
end

--- Nổ RPG: mọi NPC trong bán kính đều phản ứng (hoảng loạn dây chuyền).
function NPCManager.notifyExplosion(center: Vector3, radius: number, attacker: Player?)
	for _, st in pairs(states) do
		if st.state ~= "DEAD" then
			local d = (st.hrp.Position - center).Magnitude
			if d <= radius + 12 then
				local hum = st.hum
				if d <= radius then
					hum:TakeDamage(60)
				end
				if hum.Health > 0 then
					local reaction = chooseReaction(st.arch, "EXPLOSION", hum.Health / math.max(1, hum.MaxHealth))
					startReaction(st, reaction, attacker)
				end
			end
		end
	end
end

--- Cảnh sát tới hiện trường ngay (dùng cho RPG hoặc wanted level cao).
function NPCManager.dispatchTo(attacker: Player)
	policeDispatch(attacker)
end

function NPCManager.spawnAmbient(count: number?)
	local wanted = count or 14
	-- 3 cụm quanh các ô đất chính
	local zones = {
		{ x = 258, z = 96, r = 26 }, -- sân trước LSPD Mission Row
		{ x = 180, z = 70, r = 30 }, -- vỉa hè Plot_C3 West
		{ x = 0, z = -60, r = 34 }, -- trước Legion Square / Maze Bank plaza
		{ x = -210, z = 60, r = 30 }, -- LS Customs
	}
	local ids = { "CIVILIAN", "CIVILIAN", "BUSINESS", "TOURIST", "GANGSTER", "BRAWLER" }

	local made = 0
	for i = 1, wanted do
		local zone = zones[((i - 1) % #zones) + 1]
		local got = nil
		for _ = 1, 10 do
			local ang = math.random() * math.pi * 2
			local rad = math.random() * zone.r
			local gx = zone.x + math.cos(ang) * rad
			local gz = zone.z + math.sin(ang) * rad
			local g = findGround(gx, gz)
			if g then
				got = g
				break
			end
		end
		if got then
			-- Cứ 6 NPC thì có 1 cảnh sát tuần tra -> "gọi 911" luôn có người tới
			local id = if i % 6 == 0 then "COP" else ids[math.random(1, #ids)]
			if NPCManager.spawn(id, got) then
				made += 1
			end
		end
	end
	ambientSpawned = true
	return made
end

function NPCManager.init(hud: RemoteEvent?)
	hudRemote = hud
	local existing = Workspace:FindFirstChild(NPC_FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = NPC_FOLDER_NAME
	folder.Parent = Workspace
	npcFolder = folder

	startLoop()

	task.spawn(function()
		task.wait(2)
		local n = NPCManager.spawnAmbient(14)
		print(string.format("[NPC] Đã dựng %d NPC dân thường trên đường phố", n))
	end)

	return NPCManager
end

function NPCManager.getStats()
	local byReaction: { [string]: number } = {}
	local alive = 0
	local reacting = 0
	for _, st in pairs(states) do
		if st.state ~= "DEAD" then
			alive += 1
			if st.state == "REACT" and st.reaction then
				reacting += 1
				byReaction[st.reaction] = (byReaction[st.reaction] or 0) + 1
			end
		end
	end
	return { alive = alive, reacting = reacting, byReaction = byReaction, max = MAX_NPCS }
end

-- Xuất hàm chọn phản ứng để QA/kiểm thử tự động
NPCManager._debugChooseReaction = chooseReaction
NPCManager._debugPickWeighted = pickWeighted

return NPCManager
