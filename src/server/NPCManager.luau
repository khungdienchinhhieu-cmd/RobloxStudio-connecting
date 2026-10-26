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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local VehicleBuilder = require(Shared:WaitForChild("Vehicles"):WaitForChild("VehicleBuilder"))
local NPCAppearance = require(script.Parent:WaitForChild("NPCAppearance"))

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
		walkSpeed = 13,
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
		walkSpeed = 17,
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
		walkSpeed = 13,
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
		walkSpeed = 15,
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

local MAX_NPCS = 150         -- trần NPC cùng lúc (bản đồ rộng gấp 1,6 lần)
local AMBIENT_COUNT = 84     -- số NPC toả khắp thành phố khi khởi động
local TRAFFIC_COUNT = 8      -- số xe có TÀI XẾ NPC chạy vòng quanh phố
local NPC_FOLDER_NAME = "LosSantos_NPCs"
local TRAFFIC_FOLDER_NAME = "LosSantos_Traffic"
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
	animState: string,
	anims: any,
	targetAt: number,
	checkFrom: Vector3,
	pauseUntil: number,
	-- ── LỚP "SỐNG NHƯ NGƯỜI THẬT" (Sync v24) ──────────────────────────────
	routine: string?, -- "IDLE" | "PHONE" | "TALK" | "LOOK" | "WINDOW"
	routineStarted: number,
	routineSteps: number,
	faceGoal: Vector3?,
	jog: boolean?,
	hasPhone: boolean?,
	twin: boolean?,
}

local states: { [Model]: NPCState } = {}
local npcFolder: Folder? = nil
local trafficFolder: Folder? = nil
local traffic: { any } = {}
local hudRemote: RemoteEvent? = nil
local ambientSpawned = false

local function now(): number
	return os.clock()
end

-- Tư thế để CLIENT vẽ animation (client tự xoay Motor6D -> mượt 30 FPS, không tốn băng thông)
local function setAnim(st: NPCState, name: string)
	if st.animState == name then
		return
	end
	st.animState = name
	st.model:SetAttribute("AnimState", name)

	-- Có animation THẬT của Roblox -> phát bài tương ứng.
	-- Không có -> client tự vẽ bằng Motor6D (xem NPCAnimator.luau).
	if not st.anims then
		return
	end
	if name == "WALK" then
		NPCAppearance.playAnim(st.anims, "walk")
	elseif name == "RUN" then
		NPCAppearance.playAnim(st.anims, "run")
	elseif name == "DEAD" then
		NPCAppearance.stopAnim(st.anims)
	elseif name == "IDLE" or name == "SHOOT" or name == "PUNCH" or name == "PHONE" then
		NPCAppearance.playAnim(st.anims, "idle")
	elseif name == "DRIVE" then
		-- Ngồi trong xe: phải DỪNG animation thật thì client mới vẽ được tư thế ngồi
		NPCAppearance.stopAnim(st.anims)
	end
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

-- Tay phải: R15 = RightHand, R6 = "Right Arm"
local function handPart(model: Model): BasePart?
	local r15 = model:FindFirstChild("RightHand")
	if r15 and r15:IsA("BasePart") then
		return r15
	end
	local r6 = model:FindFirstChild("Right Arm")
	if r6 and r6:IsA("BasePart") then
		return r6
	end
	return nil
end

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
	w1.Part1 = handPart(st.model)
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
	w1.Part1 = handPart(st.model)
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

	setAnim(st, if reaction == "FLEE" then "RUN" else if reaction == "MELEE" then "PUNCH" else if reaction == "CALL_POLICE" then "PHONE" else "SHOOT")

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
	setAnim(st, "IDLE")
	st.reaction = nil
	st.attacker = nil
	stowHands(st)
	setBubble(st, nil)
	st.nextPatrolAt = 0
	st.pauseUntil = 0
	st.targetAt = 0
	-- Bị bắn/hoảng loạn giữa lúc đang nghe điện thoại -> xoá luôn hoạt động dở dang,
	-- nếu không NPC sẽ quay lại PATROL mà vẫn còn faceGoal cũ (đứng quay mặt vô tường).
	st.routine = nil
	st.faceGoal = nil
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
	if trafficFolder then
		table.insert(list, trafficFolder)
	end
	local deb = Workspace:FindFirstChild("LosSantos_Debris")
	if deb then
		table.insert(list, deb)
	end
	p.FilterDescendantsInstances = list
	return p
end

-- Mặt trên vỉa hè / nền ô đất (PartBuilder.part: pos.Y 0.575, size.Y 1.15)
local SIDEWALK_TOP_Y = 1.15

--- Cao độ mặt đất HÌNH HỌC (không cần tia chiếu).
--- Toàn bộ vỉa hè & nền ô đất do CityFoundation dựng bằng PartBuilder.part với
--- pos.Y = 0.575, size.Y = 1.15 ⇒ mặt trên luôn ở Y = 1.15. Mặt đường ở Y = 1.0.
local IN_CITY_MIN_Z = -250
local IN_CITY_MAX_Z = 200
local function inCity(x: number, z: number): boolean
	return math.abs(x) <= WorldGrid.MAP_HALF_SIZE and z >= IN_CITY_MIN_Z and z <= IN_CITY_MAX_Z
end

local function findGround(x: number, z: number): Vector3?
	local hit = Workspace:Raycast(Vector3.new(x, 90, z), Vector3.new(0, -120, 0), rayFilter())
	if hit and hit.Position.Y > 0.3 and hit.Position.Y < 4.2 then
		return hit.Position
	end
	-- ⚠️ Sync v24: TRƯỚC ĐÂY trả nil ở đây. Nếu tia chiếu trượt (part nền CanQuery=false,
	-- thành phố chưa dựng xong, hoặc điểm đang bị CityCuller cất) thì TOÀN BỘ vòng sinh
	-- NPC thất bại -> "mất tiêu hết NPC" và NPC đứng yên vì không tìm được đích đi bộ.
	-- Nay dùng cao độ hình học đã biết, nên không bao giờ phụ thuộc tia chiếu nữa.
	if inCity(x, z) then
		return Vector3.new(x, SIDEWALK_TOP_Y, z)
	end
	return nil
end

--- Như `findGround` nhưng KHÔNG BAO GIỜ trả nil: khi tia chiếu trượt (thành phố chưa
--- dựng xong, part nền đang bị cull, hoặc điểm nằm trên mặt nước) thì rơi về đúng cao
--- độ vỉa hè. Nhờ vậy NPC luôn xuất hiện thay vì biến mất cả loạt.
local groundMisses = 0
local groundHits = 0
local function findGroundSoft(x: number, z: number): Vector3
	local g = findGround(x, z)
	if g then
		groundHits += 1
		return g
	end
	groundMisses += 1
	return Vector3.new(x, SIDEWALK_TOP_Y, z)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 8.5. ĐIỂM ĐI BỘ TOÀN THÀNH PHỐ (sinh trực tiếp từ WorldGrid)
-- ══════════════════════════════════════════════════════════════════════════════

-- Trước đây chỉ có 4 cụm quanh vài ô đất. Giờ quét VỈA HÈ CỦA TOÀN BỘ 7 ĐẠI LỘ
-- -> NPC rải khắp thành phố thay vì dồn cục ở giữa.
local function buildSidewalkPoints(): { Vector3 }
	local pts: { Vector3 } = {}

	-- 3 đại lộ Đông–Tây (Vinewood / Olympic / Vespucci): vỉa hè 2 bên
	for _, r in ipairs(WorldGrid.EW_ROADS) do
		-- Tâm vỉa hè = mép đường + nửa chiều rộng vỉa hè (v22: 14 stud = 4,2 m)
		local off = (r.width / 2) + WorldGrid.SIDEWALK_WIDTH * 0.5
		for x = r.min + 14, r.max - 14, 24 do
			table.insert(pts, Vector3.new(x, 0, r.coord + off))
			table.insert(pts, Vector3.new(x + 12, 0, r.coord - off))
		end
	end

	-- 6 đại lộ Bắc–Nam (Pacific Coast / Del Perro / San Andreas / Alta / Elgin / La Mesa)
	for _, r in ipairs(WorldGrid.NS_ROADS) do
		local off = (r.width / 2) + WorldGrid.SIDEWALK_WIDTH * 0.5
		for z = r.min + 14, r.max - 14, 24 do
			table.insert(pts, Vector3.new(r.coord + off, 0, z))
			table.insert(pts, Vector3.new(r.coord - off, 0, z + 12))
		end
	end

	-- Lọc: bỏ điểm rơi ra ngoài mép bản đồ hoặc ra ngoài dải phố đi bộ.
	-- (2 đại lộ mới ở X = ±540 có vỉa hè lấn ra ±561 -> phải cắt lại)
	local maxX = WorldGrid.MAP_HALF_SIZE - 8
	local minZ = WorldGrid.ZONES.VINEWOOD_Z_MAX + 8
	local maxZ = WorldGrid.ZONES.BEACH_BOARDWALK_Z_MIN - 4

	-- Điểm nằm trong LÒNG đường (khi tuyến vỉa hè này cắt ngang tuyến khác) cũng bỏ:
	-- không để NPC đứng giữa đại lộ 14 m.
	local function insideAnyRoad(p: Vector3): boolean
		for _, r in ipairs(WorldGrid.EW_ROADS) do
			if p.Z > r.coord - r.width * 0.5 and p.Z < r.coord + r.width * 0.5 then
				return true
			end
		end
		for _, r in ipairs(WorldGrid.NS_ROADS) do
			if p.X > r.coord - r.width * 0.5 and p.X < r.coord + r.width * 0.5 then
				return true
			end
		end
		return false
	end

	local filtered: { Vector3 } = {}
	for _, p in ipairs(pts) do
		if math.abs(p.X) <= maxX and p.Z >= minZ and p.Z <= maxZ and not insideAnyRoad(p) then
			table.insert(filtered, p)
		end
	end

	return filtered
end

-- Cache toạ độ vỉa hè toàn thành phố (dựng 1 lần)
local sidewalkCache: { Vector3 }? = nil
local function getSidewalkPoints(): { Vector3 }
	if not sidewalkCache then
		sidewalkCache = buildSidewalkPoints()
	end
	return sidewalkCache :: { Vector3 }
end

-- Đích đi bộ MỚI: chọn một điểm vỉa hè CÁCH XA 60–300 stud -> NPC đi xuyên
-- nhiều đại lộ, thay vì loanh quanh 12–34 stud như trước.
local function pickPatrolTarget(st: NPCState): Vector3
	local base = st.hrp.Position
	local pts = getSidewalkPoints()
	local flat = Vector3.new(base.X, 0, base.Z)

	if #pts > 0 then
		for _ = 1, 16 do
			local p = pts[math.random(1, #pts)]
			local d = (Vector3.new(p.X, 0, p.Z) - flat).Magnitude
			if d >= 60 and d <= 300 then
				local g = findGround(p.X, p.Z)
				if g and math.abs(g.Y - base.Y) < 8 then
					return g
				end
			end
		end
	end

	-- dự phòng: quanh chỗ đang đứng
	for _ = 1, 8 do
		local ang = math.random() * math.pi * 2
		local dist = math.random(30, 70)
		local g = findGround(base.X + math.cos(ang) * dist, base.Z + math.sin(ang) * dist)
		if g and math.abs(g.Y - base.Y) < 1.6 then
			return g
		end
	end
	return base
end

-- Đặt đích mới + ghi mốc để phát hiện kẹt đường
local function retarget(st: NPCState, t: number)
	st.patrolTarget = pickPatrolTarget(st)
	st.targetAt = t
	st.checkFrom = st.hrp.Position
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

-- ══════════════════════════════════════════════════════════════════════════════
-- 9.6. LỚP "SỐNG NHƯ NGƯỜI THẬT" (Sync v24)
-- ------------------------------------------------------------------------------
-- NPC không còn chỉ "đi tới đích rồi đứng thở". Sau mỗi chặng đi bộ, nó chọn một
-- HOẠT ĐỘNG có thật ngoài đời và thực hiện nó, rồi mới đi tiếp:
--   IDLE   · đứng ngắm cảnh, liếc quanh (2–6 s)
--   PHONE  · rút điện thoại ra nghe, gật gù (6–14 s)   ← cầm máy thật trong tay
--   TALK   · quay sang nói chuyện với NPC gần nhất (7–15 s), cả hai quay mặt vào nhau
--   LOOK   · quay mặt nhìn theo người chơi đi ngang (3–7 s)
--   WINDOW · đứng ngắm tủ kính cửa hàng rồi gật đầu (4–9 s)
-- Tỉ lệ chọn phụ thuộc tính cách: dân văn phòng nghe điện thoại nhiều, du khách ngắm cảnh,
-- thug thì ít đứng lâu (nhanh chóng đi tiếp).
-- ══════════════════════════════════════════════════════════════════════════════

local ROUTINE_WEIGHTS: { [string]: { [string]: number } } = {
	CIVILIAN = { IDLE = 3, PHONE = 4, TALK = 3, LOOK = 2, WINDOW = 2 },
	BUSINESS = { PHONE = 6, TALK = 3, IDLE = 2, LOOK = 1, WINDOW = 1 },
	TOURIST = { LOOK = 5, IDLE = 3, TALK = 2, WINDOW = 2, PHONE = 1 },
	GANGSTER = { IDLE = 3, TALK = 4, LOOK = 2, PHONE = 2, WINDOW = 0 },
	BRAWLER = { IDLE = 3, TALK = 3, LOOK = 2, PHONE = 1, WINDOW = 0 },
	COP = { LOOK = 5, IDLE = 4, TALK = 1, PHONE = 1, WINDOW = 0 },
	THUG = { IDLE = 3, TALK = 3, LOOK = 2, PHONE = 1, WINDOW = 0 },
}

type Span = { min: number, max: number }
local ROUTINE_DURATION: { [string]: Span } = {
	IDLE = { min = 2, max = 6 },
	PHONE = { min = 6, max = 14 },
	TALK = { min = 7, max = 15 },
	LOOK = { min = 3, max = 7 },
	WINDOW = { min = 4, max = 9 },
}

local function rollRoutine(st: NPCState): string
	local table_ = ROUTINE_WEIGHTS[st.arch.id] or ROUTINE_WEIGHTS.CIVILIAN
	local total = 0
	for _, w in pairs(table_) do
		total += w
	end
	if total <= 0 then
		return "IDLE"
	end
	local roll = math.random() * total
	for name, w in pairs(table_) do
		roll -= w
		if roll <= 0 then
			return name
		end
	end
	return "IDLE"
end

--- NPC gần nhất trong bán kính (dùng cho TALK)
local function nearestNeighbour(st: NPCState, radius: number): NPCState?
	local best: NPCState? = nil
	local bestD = radius
	for _, other in pairs(states) do
		if other ~= st and other.state == "PATROL" and other.model.Parent then
			local d = (other.hrp.Position - st.hrp.Position).Magnitude
			if d < bestD then
				bestD = d
				best = other
			end
		end
	end
	return best
end

--- Người chơi gần nhất (dùng cho LOOK)
local function nearestPlayer(st: NPCState, radius: number): Vector3?
	local best: Vector3? = nil
	local bestD = radius
	for _, pl in ipairs(Players:GetPlayers()) do
		local char = pl.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
		if hrp and hrp:IsA("BasePart") then
			local d = (hrp.Position - st.hrp.Position).Magnitude
			if d < bestD then
				bestD = d
				best = hrp.Position
			end
		end
	end
	return best
end

local function arrive(st: NPCState, t: number)
	local routine = rollRoutine(st)
	local dur: Span = ROUTINE_DURATION[routine] or { min = 2, max = 6 }

	-- Một số hoạt động cần điều kiện: không có điện thoại, không có ai để nói chuyện,
	-- không có người chơi quanh đây -> lùi về IDLE (đứng ngắm cảnh).
	if routine == "PHONE" and not st.hasPhone then
		routine = "IDLE"
	elseif routine == "TALK" then
		local partner = nearestNeighbour(st, 18)
		if not partner then
			-- Đứng một mình thì không "nói chuyện với không khí" — chuyển sang ngắm cảnh.
			routine = "LOOK"
			local ang = math.random() * math.pi * 2
			st.faceGoal = st.hrp.Position + Vector3.new(math.cos(ang) * 10, 0, math.sin(ang) * 10)
		else
			-- Cả hai quay mặt vào nhau: đặt đích "nhìn" cách 1 stud về phía đối phương.
			st.faceGoal = partner.hrp.Position
			partner.faceGoal = st.hrp.Position
			partner.routine = "TALK"
			partner.routineStarted = t
			partner.pauseUntil = math.max(partner.pauseUntil, t + math.random(4, 8))
		end
	elseif routine == "LOOK" then
		local target = nearestPlayer(st, 34)
		if target then
			st.faceGoal = target
		else
			-- Không có ai quanh đây thì vẫn NGẮM CẢNH: quay mặt về một điểm
			-- ngẫu nhiên trên phố. (Trước đây lùi về IDLE -> đứng như tượng.)
			local ang = math.random() * math.pi * 2
			st.faceGoal = st.hrp.Position + Vector3.new(math.cos(ang) * 10, 0, math.sin(ang) * 10)
		end
	elseif routine == "WINDOW" then
		-- Quay mặt ra đường (về phía đại lộ gần nhất)
		st.faceGoal = st.hrp.Position + (st.hrp.CFrame.LookVector * -1) * 6
	end

	if routine == "PHONE" then
		equipPhone(st)
	end

	st.routine = routine
	st.routineStarted = t
	st.routineSteps = 0
	st.pauseUntil = t + math.random(dur.min, dur.max)
	setAnim(st, if routine == "PHONE" or routine == "TALK" then "PHONE" else "IDLE")
end

local function endRoutine(st: NPCState)
	if st.routine == "PHONE" then
		stowHands(st)
	end
	st.routine = nil
	st.faceGoal = nil
	st.routineSteps = 0
end

--- Chạy trong lúc NPC đang "nghỉ". Trả về true nếu vẫn đang bận hoạt động.
local function tickRoutine(st: NPCState, t: number): boolean
	local routine = st.routine
	if not routine then
		return false
	end

	-- Quay mặt về đích "nhìn": Humanoid tự xoay khi có MoveTo, chỉ cần nhích 0,8 stud.
	local face = st.faceGoal
	if face then
		local d = face - st.hrp.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude > 0.6 then
			moveTo(st, st.hrp.Position + flat.Unit * 0.8, t)
		else
			moveTo(st, st.hrp.Position, t)
		end
	else
		moveTo(st, st.hrp.Position, t)
	end

	-- Gật đầu / liếc quanh: đổi tư thế nhẹ mỗi 1,8 s để không đứng như tượng.
	st.routineSteps = (st.routineSteps or 0) + 1

	if routine == "PHONE" and st.phone then
		-- Giơ máy lên sát tai (dịch nhẹ theo chu kỳ cho tự nhiên)
		local bob = math.sin(t * 2.2) * 0.06
		st.phone.CFrame = st.hrp.CFrame * CFrame.new(0.95, 1.32 + bob, -0.55)
	elseif routine == "LOOK" then
		local target = nearestPlayer(st, 40)
		if target then
			st.faceGoal = target
		end
	elseif routine == "TALK" then
		local partner = nearestNeighbour(st, 20)
		if partner then
			st.faceGoal = partner.hrp.Position
		else
			-- Người kia bỏ đi -> kết thúc sớm
			st.pauseUntil = math.min(st.pauseUntil, t + 0.5)
		end
	end

	return t < st.pauseUntil
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
		setAnim(st, "DEAD")
		st.model:SetAttribute("DeathAt", now())
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

	-- TÀI XẾ: ngồi trong xe, không đi bộ; chỉ phản ứng (bong bóng) tại chỗ
	if st.model:GetAttribute("IsDriver") == true then
		if st.state == "PATROL" then
			setAnim(st, "DRIVE")
			return
		end
		if t > st.reactUntil then
			calmDown(st)
		end
		return
	end

	if st.state == "PATROL" then
		local delta = st.patrolTarget - st.hrp.Position
		local flatDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
		local v = st.hrp.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude

		-- 1) ĐANG NGHỈ (vừa tới đích): thực hiện HOẠT ĐỘNG ĐỜI THƯỜNG
		if st.pauseUntil > 0 then
			-- tickRoutine trả false khi NPC KHÔNG còn hoạt động nào (routine = nil) —
			-- ví dụ vừa bị bắn giữa lúc nghỉ. Khi đó phải đi tiếp ngay, không đứng đợi.
			if t < st.pauseUntil and tickRoutine(st, t) then
				return
			end
			endRoutine(st)
			st.pauseUntil = 0
			retarget(st, t)
			-- BẮT BUỘC tính lại: nếu dùng flatDist cũ (=0) thì bước 3 bên dưới
			-- lại tưởng "đã tới nơi" và cho nghỉ tiếp -> NPC đứng im vĩnh viễn.
			delta = st.patrolTarget - st.hrp.Position
			flatDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
		end

		-- 2) KẸT ĐƯỜNG: cứ 6 giây kiểm tra 1 lần, nếu đi được < 8 stud thì đổi đích.
		-- Đo bằng QUÃNG ĐƯỜNG (vị trí) chứ không dùng vận tốc tức thời — vận tốc
		-- có thể tụt về ~0 trong 1 khung hình (va chạm nhẹ) và sẽ làm NPC đổi đích liên tục.
		if st.targetAt > 0 and (t - st.targetAt) > 6 then
			local moved = (st.hrp.Position - st.checkFrom).Magnitude
			if moved < 8 then
				retarget(st, t)
				delta = st.patrolTarget - st.hrp.Position
				flatDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
			else
				st.targetAt = t
				st.checkFrom = st.hrp.Position
			end
		end

		-- 3) TỚI NƠI -> chọn một hoạt động đời thường rồi mới đi tiếp
		if flatDist <= 3 then
			arrive(st, t)
			return
		end

		moveTo(st, st.patrolTarget, t)
		-- Kiểm tra tốc độ THẬT để NPC đứng chờ không bị "đi bộ tại chỗ".
		if speed > 1.2 then
			setAnim(st, if st.jog then "RUN" else "WALK")
		elseif speed > 0.15 then
			-- Đang tăng tốc / bị cản nhẹ: vẫn hiện dáng đi để không "trượt băng"
			setAnim(st, if st.jog then "RUN" else "WALK")
		else
			setAnim(st, "IDLE")
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

local REFILL_INTERVAL = 8
local refillClock = 0
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
			-- ── NẠP LẠI DÂN SỐ (Sync v23) ────────────────────────────────────────
			-- Trước đây NPC chết đi là mất luôn, không ai sinh bù. Giờ mỗi 8 giây kiểm
			-- tra: nếu dân số tụt dưới 70 % mục tiêu thì thả bù (tối đa 10 con/lần),
			-- để thành phố không bao giờ "trống trơn" sau khi bị bắn phá.
			refillClock += HEARTBEAT
			if refillClock >= REFILL_INTERVAL then
				refillClock = 0
				if ambientSpawned then
					local living = 0
					for _, st in pairs(states) do
						if st.model.Parent and st.state ~= "DEAD" then
							living += 1
						end
					end
					local floor = math.floor(AMBIENT_COUNT * 0.7)
					if living < floor then
						local added = NPCManager.spawnAmbient(math.min(10, floor - living))
						if added > 0 then
							print(string.format("[NPC] Nạp lại %d NPC (đang có %d / mục tiêu %d)", added, living + added, AMBIENT_COUNT))
						end
					end
				end
			end
		end
	end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 11. API CÔNG KHAI
-- ══════════════════════════════════════════════════════════════════════════════

function NPCManager.spawn(archetypeId: string, position: Vector3, forceCF: CFrame?): Model?
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
	local baseY = if ground then ground.Y else SIDEWALK_TOP_Y
	-- Rig R6: HumanoidRootPart nằm ngang Torso, chân dài 2 stud ở DƯỚI -> tâm HRP cách đất 3 stud.
	-- Cộng 0,06 để bàn chân không xuyên vào mặt đường ngay khung hình đầu.
	local cf = forceCF
		or (CFrame.new(position.X, baseY + 3.06, position.Z) * CFrame.Angles(0, math.random() * math.pi * 2, 0))

	-- Ưu tiên MODEL ROBLOX THẬT (R15, có animation đi bộ chuẩn)
	-- ⚠️ P0 (v24): trước đây viết `local r15 = NPCAppearance.build(...)` rồi
	-- `model, hum, hrp, head = r15` — hàm trả về NHIỀU giá trị, gán vào một biến
	-- thì chỉ còn cái ĐẦU TIÊN (Model), rồi đem Model ra băm theo chỉ số 1..4
	-- -> hum/hrp/head = nil -> `hrp.Position` nổ ngay -> pcall nuốt lỗi ->
	-- KHÔNG MỘT NPC NÀO ĐƯỢC DỰNG. Đây chính là lý do thành phố trống trơn.
	local model, hum, hrp, head = NPCAppearance.build(arch.id, cf, arch.walkSpeed, arch.health)
	if not model or not hum or not hrp then
		-- Dự phòng: rig R6 tự ghép (nếu Roblox không dựng được model)
		model, hum, hrp, head = buildRig(arch, cf)
	end
	if not model then
		return nil
	end
	model.Parent = npcFolder
	model:SetAttribute("IsGTA_NPC", true)
	model:SetAttribute("Archetype", arch.id)

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
		animState = "IDLE",
		anims = nil,
		targetAt = 0,
		checkFrom = hrp.Position,
		pauseUntil = 0,
		routine = nil,
		routineStarted = 0,
		routineSteps = 0,
		faceGoal = nil,
		jog = (arch.id == "TOURIST" and math.random() < 0.10) or (arch.id == "CIVILIAN" and math.random() < 0.08),
		hasPhone = arch.hasPhone,
		twin = false,
	}
	-- ── NGƯỜI THẬT THÌ AI CŨNG MỘT KHÁC: chiều cao / bề ngang / đầu khác nhau ──
	-- (R15 dùng các thuộc tính Body*Scale của Humanoid; R6 không có nên bỏ qua an toàn)
	pcall(function()
		local height = math.random(90, 110) / 100
		local width = math.random(92, 108) / 100
		hum.BodyHeightScale = height
		hum.BodyWidthScale = width
		hum.BodyDepthScale = width * (math.random(95, 105) / 100)
		hum.BodyTypeScale = math.random(92, 108) / 100
		hum.HeadScale = math.random(94, 106) / 100
	end)

	if st.jog then
		hum.WalkSpeed = math.max(18, arch.walkSpeed + 6)
	end

	st.anims = NPCAppearance.loadAnimations(model, hum)
	if st.anims then
		NPCAppearance.tuneGait(st.anims, if st.jog then hum.WalkSpeed else arch.walkSpeed)
		model:SetAttribute("UsesRealAnims", true)
		NPCAppearance.playAnim(st.anims, "idle", 0)
	else
		model:SetAttribute("UsesRealAnims", false)
	end

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

-- ══════════════════════════════════════════════════════════════════════════════
-- 11. SINH NPC DÂN PHỐ (danh sách điểm vỉa hè nằm ở mục 8.5)
-- ══════════════════════════════════════════════════════════════════════════════

-- Tỉ lệ tính cách xuất hiện trên đường phố
local ARCHETYPE_ROLL = {
	{ id = "CIVILIAN", upTo = 0.34 },
	{ id = "TOURIST", upTo = 0.50 },
	{ id = "BUSINESS", upTo = 0.62 },
	{ id = "COP", upTo = 0.73 },
	{ id = "GANGSTER", upTo = 0.86 },
	{ id = "BRAWLER", upTo = 1.00 },
}

local function rollArchetype(): string
	local r = math.random()
	for _, entry in ipairs(ARCHETYPE_ROLL) do
		if r <= entry.upTo then
			return entry.id
		end
	end
	return "CIVILIAN"
end

function NPCManager.spawnAmbient(count: number?): number
	local target = count or AMBIENT_COUNT
	local points = buildSidewalkPoints()
	if #points == 0 then
		-- Cứu hộ tuyệt đối: nếu vì lý do gì đó lưới đường không sinh được điểm nào,
		-- vẫn thả NPC quanh Quảng trường Legion để thành phố không bao giờ "trống trơn".
		warn("[NPC] Không sinh được điểm vỉa hè — dùng phương án dự phòng quanh Legion Square")
		local c = WorldGrid.SPAWN_POS
		for i = 1, 40 do
			local ang = (i / 40) * math.pi * 2
			table.insert(points, Vector3.new(c.X + math.cos(ang) * (18 + i), 0, c.Z + math.sin(ang) * (18 + i)))
		end
	end

	-- 55 % NPC thả gần khu trung tâm (bán kính 320 stud quanh điểm hồi sinh) để người chơi
	-- luôn thấy phố đông; 45 % còn lại rải đều toàn thành phố.
	local center = WorldGrid.SPAWN_POS
	local near: { Vector3 } = {}
	for _, pt in ipairs(points) do
		if (Vector3.new(pt.X, 0, pt.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude <= 320 then
			table.insert(near, pt)
		end
	end

	local made = 0
	local tries = 0
	local spawnErrors = 0
	local maxTries = target * 12
	local beforeMiss = groundMisses

	while made < target and tries < maxTries do
		tries += 1
		local pool = if #near > 0 and math.random() < 0.55 then near else points
		local pt = pool[math.random(1, #pool)]
		local g = findGroundSoft(pt.X, pt.Z)
		if g then
			-- Không dồn cục: cách NPC khác tối thiểu 9 stud
			local tooClose = false
			for _, other in pairs(states) do
				if other.state ~= "DEAD" and (other.hrp.Position - g).Magnitude < 9 then
					tooClose = true
					break
				end
			end
			if not tooClose then
				local okSpawn, built = pcall(NPCManager.spawn, rollArchetype(), g)
				if okSpawn and built then
					made += 1
				elseif not okSpawn then
					spawnErrors += 1
					if spawnErrors <= 3 then
						warn("[NPC] lỗi khi dựng NPC: " .. tostring(built))
					end
				end
			end
		end
	end

	-- ── CỨU HỘ LẦN CUỐI: nếu vẫn không dựng được con nào thì thả thẳng một vòng
	-- quanh Quảng trường Legion (toạ độ tuyệt đối, không phụ thuộc lưới vỉa hè gì cả).
	if made == 0 then
		warn("[NPC] spawnAmbient thất bại — kích hoạt chế độ cứu hộ quanh Legion Square")
		local c = WorldGrid.SPAWN_POS
		for i = 1, 16 do
			local ang = (i / 16) * math.pi * 2
			local pos = Vector3.new(c.X + math.cos(ang) * (14 + i * 2), SIDEWALK_TOP_Y, c.Z + math.sin(ang) * (14 + i * 2))
			local okSpawn = pcall(function()
				if NPCManager.spawn(rollArchetype(), pos) then
					made += 1
				end
			end)
			if not okSpawn then
				warn("[NPC] spawn cứu hộ lỗi ở vòng " .. i)
			end
		end
		warn(string.format("[NPC] Cứu hộ dựng được %d NPC", made))
	end

	ambientSpawned = true
	print(string.format(
		"[NPC] spawnAmbient: %d/%d NPC · %d điểm vỉa hè (%d gần trung tâm) · tia chiếu trượt %d lần (đã dùng cao độ vỉa hè %.2f)",
		made,
		target,
		#points,
		#near,
		groundMisses - beforeMiss,
		SIDEWALK_TOP_Y
	))
	return made
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 12. GIAO THÔNG — NPC LÁI XE CHẠY VÒNG QUANH THÀNH PHỐ
-- ══════════════════════════════════════════════════════════════════════════════

-- Toạ độ đã canh ĐÚNG LÀN BÊN PHẢI của từng đại lộ trong WorldGrid:
--   Olympic Fwy (Z=-36) · Vespucci Blvd (Z=148) · San Andreas (X=-110) · Alta St (X=110)
--   Vinewood Blvd (Z=-224) · Del Perro (X=-338) · Elgin Ave (X=338)
local TRAFFIC_ROUTES = {
	{
		-- vòng trung tâm
		Vector3.new(-98, 0, -27),
		Vector3.new(98, 0, -27),
		Vector3.new(98, 0, 138),
		Vector3.new(-98, 0, 138),
	},
	{
		-- vòng vành đai giữa (Del Perro X=-338 · Elgin X=+338)
		Vector3.new(338, 0, 154),
		Vector3.new(338, 0, -230),
		Vector3.new(-338, 0, -230),
		Vector3.new(-338, 0, 154),
	},
	{
		-- vòng vành đai ngoài cùng (Pacific Coast X=-556 · La Mesa X=+556)
		Vector3.new(-548, 0, 154),
		Vector3.new(-548, 0, -230),
		Vector3.new(548, 0, -230),
		Vector3.new(548, 0, 154),
	},
}

local TRAFFIC_TRIMS = {
	VehicleBuilder.PRESETS.CrimsonBanshee,
	VehicleBuilder.PRESETS.MidnightBanshee,
	VehicleBuilder.PRESETS.ObsidianGauntlet,
	VehicleBuilder.PRESETS.SunsetComet,
}

local function spawnTrafficCar(routeIdx: number, startIdx: number?)
	if not trafficFolder then
		return nil
	end
	local route = TRAFFIC_ROUTES[routeIdx]
	if not route then
		return nil
	end

	-- startIdx giúp 2 xe cùng tuyến xuất phát lệch nhau, không chồng khít
	local idx = ((startIdx or math.random(1, #route)) - 1) % #route + 1
	local from = route[idx]
	local to = route[(idx % #route) + 1]
	local ground = findGround(from.X, from.Z)
	if not ground then
		return nil
	end

	local pos = Vector3.new(from.X, ground.Y, from.Z)
	local dir = Vector3.new(to.X, 0, to.Z) - Vector3.new(from.X, 0, from.Z)
	if dir.Magnitude < 1 then
		return nil
	end
	dir = dir.Unit

	local cf = CFrame.lookAt(pos, pos + dir)
	local trim = TRAFFIC_TRIMS[math.random(1, #TRAFFIC_TRIMS)]
	local car = VehicleBuilder.spawn(trafficFolder, cf, trim)
	local chassis = car.PrimaryPart
	if not chassis then
		car:Destroy()
		return nil
	end

	-- Gắn cứng toàn bộ xe vào khung sườn, neo khung sườn lại
	-- -> mỗi nhịp chỉ cần đổi ĐÚNG 1 CFrame, không tốn CPU cho 150 part
	chassis.Anchored = true
	chassis.CanCollide = false
	chassis.CanTouch = false
	for _, d in ipairs(car:GetDescendants()) do
		if d:IsA("BasePart") and d ~= chassis then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			-- VehicleBuilder đã hàn sẵn phần lớn chi tiết vào khung sườn rồi;
			-- chỉ hàn thêm chi tiết còn rời (nếu có) để tránh 2 mối hàn chồng nhau.
			if not d:FindFirstChildWhichIsA("WeldConstraint") then
				local w = Instance.new("WeldConstraint")
				w.Part0 = chassis
				w.Part1 = d
				w.Parent = d
			end
		end
	end

	-- TÀI XẾ NPC ngồi trong xe
	-- Rig R6: tâm HumanoidRootPart/Torso nằm trên mặt ghế 1,12 stud (nửa thân trên 1 stud
	-- + 0,12 độ dày ghế) -> đầu không đội mui, chân không xuyên sàn.
	local seat = car:FindFirstChild("DriverSeat", true)
	local seatCF: CFrame
	local seatPos: Vector3
	if seat and seat:IsA("BasePart") then
		seatCF = seat.CFrame * CFrame.new(0, 1.12, 0)
		seatPos = seat.Position
	else
		seatCF = chassis.CFrame * CFrame.new(-1.68, 1.1, 0.48)
		seatPos = seatCF.Position
	end

	local driverId = if math.random() < 0.15 then "GANGSTER" else rollArchetype()
	local driver = NPCManager.spawn(driverId, seatPos, seatCF)
	if driver then
		driver.Parent = car -- nằm gọn trong xe, dọn xe là dọn luôn tài xế
		driver:SetAttribute("IsDriver", true)
		driver:SetAttribute("AnimState", "DRIVE")
		local st = states[driver]
		if st then
			st.animState = "DRIVE"
			st.folder = trafficFolder :: Folder
			if st.anims then
				NPCAppearance.stopAnim(st.anims)
			end
		end
		local hum = driver:FindFirstChildOfClass("Humanoid")
		local hrp = driver:FindFirstChild("HumanoidRootPart")
		if hum then
			hum.WalkSpeed = 0
			hum.JumpPower = 0
			hum.AutoRotate = false
			hum.PlatformStand = true -- tắt máy trạng thái Humanoid, giữ nguyên tư thế ngồi
		end
		if hrp and hrp:IsA("BasePart") then
			local w = Instance.new("WeldConstraint")
			w.Part0 = chassis
			w.Part1 = hrp
			w.Parent = chassis
		end
	end

	local sp = math.random(26, 34)
	table.insert(traffic, {
		car = car,
		chassis = chassis,
		driver = driver,
		route = route,
		idx = (idx % #route) + 1,
		pos = pos,
		heading = dir,
		speed = sp,
		baseSpeed = sp,
	})
	return car
end

local function stepTraffic(dt: number)
	for i = #traffic, 1, -1 do
		local t = traffic[i]
		local car = t.car
		local chassis = t.chassis
		if not car.Parent or not chassis.Parent then
			table.remove(traffic, i)
			continue
		end

		-- Tài xế chết -> xe dừng khựng lại; tài xế hoảng loạn -> tăng tốc bỏ chạy
		local st = if t.driver then states[t.driver] else nil
		if st and (st.state == "DEAD" or st.hum.Health <= 0) then
			t.speed = math.max(0, t.speed - dt * 45)
		elseif st and st.state == "REACT" and st.reaction == "FLEE" then
			t.speed = math.min(t.baseSpeed + 18, t.speed + dt * 24)
		else
			t.speed = math.min(t.baseSpeed, t.speed + dt * 8)
		end

		-- Tiến tới điểm mốc kế tiếp
		local target = Vector3.new(t.route[t.idx].X, t.pos.Y, t.route[t.idx].Z)
		local to = target - t.pos
		local dist = to.Magnitude
		local step = t.speed * dt
		if dist <= step or dist < 0.6 then
			t.pos = target
			t.idx = (t.idx % #t.route) + 1
		else
			t.pos = t.pos + to.Unit * step
		end

		-- Xoay mũi xe mượt về hướng mốc kế tiếp
		local nextPt = Vector3.new(t.route[t.idx].X, t.pos.Y, t.route[t.idx].Z)
		local desired = nextPt - t.pos
		if desired.Magnitude > 0.8 then
			t.heading = t.heading:Lerp(desired.Unit, math.clamp(dt * 2.6, 0, 1))
			if t.heading.Magnitude > 0.01 then
				t.heading = t.heading.Unit
			end
		end

		local basePos = t.pos + Vector3.new(0, 2.36, 0)
		if t.heading.Magnitude > 0.01 then
			chassis.CFrame = CFrame.lookAt(basePos, basePos + t.heading)
		end
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 12.5. NPC MANG SKIN CỦA NGƯỜI CHƠI ("bản sao" đi lại trong thành phố)
-- ══════════════════════════════════════════════════════════════════════════════

--- Dựng một NPC giống hệt avatar của `player`, đứng cách họ 40–160 stud.
function NPCManager.spawnPlayerTwin(player: Player): Model?
	if not npcFolder then
		return nil
	end
	local char = player.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
	if not hrp or not hrp:IsA("BasePart") then
		return nil
	end

	-- Tìm điểm vỉa hè cách người chơi 40–160 stud (không hiện ra ngay trước mặt)
	local pts = getSidewalkPoints()
	local origin = hrp.Position
	local chosen: Vector3? = nil
	for _ = 1, 24 do
		-- ⚠️ math.random(1, 0) NÉM LỖI -> trước đây nếu lưới vỉa hè rỗng thì cả hàm chết
		-- và người chơi không có bản sao nào. Giờ thoát vòng lặp an toàn.
		if #pts == 0 then
			break
		end
		local p = pts[math.random(1, #pts)]
		local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(origin.X, 0, origin.Z)).Magnitude
		if d >= 40 and d <= 160 then
			local g = findGround(p.X, p.Z)
			if g then
				chosen = g
				break
			end
		end
	end
	if not chosen then
		chosen = origin + Vector3.new(math.random(-60, 60), 0, math.random(-60, 60))
	end

	local spot = chosen :: Vector3
	local cf = CFrame.new(spot.X, spot.Y + 3.06, spot.Z) * CFrame.Angles(0, math.random() * math.pi * 2, 0)

	-- ⚠️ P0 (v24): cùng lỗi cũ — fromPlayer trả về (model, humanoid, hrp, head)
	local model, hum, h, head = NPCAppearance.fromPlayer(player, cf)
	if not model or not hum or not h then
		return nil
	end
	model.Parent = npcFolder
	model:SetAttribute("IsGTA_NPC", true)
	model:SetAttribute("Archetype", "CIVILIAN")

	local st: NPCState = {
		model = model,
		hum = hum,
		hrp = h,
		head = head :: any,
		arch = ARCHETYPES.CIVILIAN,
		folder = npcFolder :: Folder,
		state = "PATROL",
		reaction = nil,
		attacker = nil,
		reactUntil = 0,
		nextShot = 0,
		nextMelee = 0,
		patrolTarget = h.Position,
		nextPatrolAt = 0,
		gunModel = nil,
		phone = nil,
		bubble = nil,
		gunFlashAt = 0,
		lastGoal = nil,
		lastMoveAt = 0,
		animState = "IDLE",
		anims = nil,
		targetAt = 0,
		checkFrom = h.Position,
		pauseUntil = 0,
		routine = nil,
		routineStarted = 0,
		routineSteps = 0,
		faceGoal = nil,
		jog = false,
		hasPhone = true,
		twin = true,
	}
	st.anims = NPCAppearance.loadAnimations(model, hum)
	if st.anims then
		NPCAppearance.tuneGait(st.anims, 14)
	end
	model:SetAttribute("UsesRealAnims", st.anims ~= nil)
	states[model] = st
	setBubble(st, nil)
	startLoop()
	print(string.format("[NPC] Đã thả bản sao của %s vào thành phố", player.Name))
	return model
end

local twinsHooked = false
local function hookPlayerTwins()
	if twinsHooked then
		return
	end
	twinsHooked = true

	local function tryTwin(player: Player)
		task.spawn(function()
			-- Chờ nhân vật + mẫu R15 sẵn sàng
			for _ = 1, 60 do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					and NPCAppearance.templateCount() > 0 then
					break
				end
				task.wait(0.5)
			end
			task.wait(1)
			local ok, err = pcall(NPCManager.spawnPlayerTwin, player)
			if not ok then
				warn("[NPC] Không tạo được bản sao người chơi:", err)
			end
		end)
	end

	for _, pl in ipairs(Players:GetPlayers()) do
		tryTwin(pl)
	end
	Players.PlayerAdded:Connect(tryTwin)
end

function NPCManager.spawnTraffic(count: number?): number
	local target = count or TRAFFIC_COUNT
	if not trafficFolder then
		return 0
	end
	local made = 0
	for i = 1, target do
		local routeIdx = ((i - 1) % #TRAFFIC_ROUTES) + 1
		local lap = ((i - 1) // #TRAFFIC_ROUTES) -- xe thứ mấy trên tuyến này
		if spawnTrafficCar(routeIdx, lap * 2 + 1) then
			made += 1
			task.wait(0.15) -- rải đều, tránh dựng 4 xe trong cùng 1 frame
		end
	end
	return made
end

local trafficRunning = false
local function startTrafficLoop()
	if trafficRunning then
		return
	end
	trafficRunning = true
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(0.05)
			local tNow = os.clock()
			local dt = math.min(0.25, tNow - last)
			last = tNow
			local ok, err = pcall(stepTraffic, dt)
			if not ok then
				warn("[NPC] lỗi vòng lặp giao thông:", err)
			end
		end
	end)
end

function NPCManager.init(hud: RemoteEvent?)
	hudRemote = hud

	-- Dọn các lần chạy trước
	for _, folderName in ipairs({ NPC_FOLDER_NAME, TRAFFIC_FOLDER_NAME }) do
		local old = Workspace:FindFirstChild(folderName)
		if old then
			old:Destroy()
		end
	end
	table.clear(states)
	table.clear(traffic)

	local folder = Instance.new("Folder")
	folder.Name = NPC_FOLDER_NAME
	folder.Parent = Workspace
	npcFolder = folder

	local tf = Instance.new("Folder")
	tf.Name = TRAFFIC_FOLDER_NAME
	tf.Parent = Workspace
	trafficFolder = tf

	startLoop()
	startTrafficLoop()

	hookPlayerTwins()

	task.spawn(function()
		task.wait(2)

		-- Dựng mẫu nhân vật R15 của Roblox (chỉ 4 lần; các NPC sau chỉ clone)
		local t0 = os.clock()
		local templates = NPCAppearance.warmTemplates(4)
		if templates > 0 then
			print(string.format("[NPC] Đã dựng %d mẫu nhân vật R15 của Roblox (%.2fs)", templates, os.clock() - t0))
		else
			warn("[NPC] Không dựng được model R15 — tạm dùng rig R6 tự ghép")
		end

		local n = NPCManager.spawnAmbient(AMBIENT_COUNT)
		print(string.format("[NPC] Đã dựng %d NPC rải khắp vỉa hè thành phố", n))

		-- BẢO HIỂM: nếu vì bất kỳ lý do gì dân số vẫn quá thấp (thành phố chưa dựng xong,
		-- streaming chưa nạp, part nền chưa sẵn sàng...) thì thử lại 2 lần nữa.
		for _, delay in ipairs({ 6, 15 }) do
			if n >= 20 then
				break
			end
			task.wait(delay)
			local retry = NPCManager.spawnAmbient(AMBIENT_COUNT - n)
			n += retry
			warn(string.format("[NPC] Thử lại lần nữa sau %ds: +%d NPC (tổng %d)", delay, retry, n))
		end
		if n == 0 then
			warn("[NPC] ⚠️ KHÔNG dựng được NPC nào. Chạy trong Command Bar để chẩn đoán:")
			warn("       print(require(game.ServerScriptService.Server.NPCManager).diagnose())")
		end

		task.wait(1)
		local cars = NPCManager.spawnTraffic(TRAFFIC_COUNT)
		print(string.format("[NPC] Đã thả %d xe có TÀI XẾ NPC chạy vòng quanh phố", cars))
	end)

	return NPCManager
end

--- Chẩn đoán nhanh: gọi trong Command Bar `require(game.ServerScriptService.Server.NPCManager).diagnose()`
function NPCManager.diagnose(): string
	local pts = buildSidewalkPoints()
	local living, routines, joggers = 0, {}, 0
	for _, st in pairs(states) do
		if st.model.Parent and st.state ~= "DEAD" then
			living += 1
			routines[st.routine or "WALKING"] = (routines[st.routine or "WALKING"] or 0) + 1
			if st.jog then
				joggers += 1
			end
		end
	end
	local parts = {}
	for k, v in pairs(routines) do
		table.insert(parts, string.format("%s=%d", k, v))
	end
	table.sort(parts)
	return string.format(
		"[NPC diagnose] sống=%d · điểm vỉa hè=%d · jogger=%d · hoạt động: %s · tia chiếu lỗi=%d/%d",
		living,
		#pts,
		joggers,
		table.concat(parts, ", "),
		groundMisses,
		groundMisses + groundHits
	)
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
	local r15 = 0
	for _, st in pairs(states) do
		if st.anims then
			r15 += 1
		end
	end
	return { alive = alive, reacting = reacting, byReaction = byReaction, max = MAX_NPCS, traffic = #traffic, r15 = r15 }
end

-- Xuất hàm chọn phản ứng để QA/kiểm thử tự động
NPCManager._debugChooseReaction = chooseReaction
NPCManager._debugPickWeighted = pickWeighted

return NPCManager
