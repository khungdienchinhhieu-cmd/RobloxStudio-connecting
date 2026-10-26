--!nonstrict
--[[
	NPCAppearance.luau  —  NPC DÙNG MODEL ROBLOX THẬT (R15) + SKIN CỦA NGƯỜI CHƠI
	================================================================================
	Trước đây NPC là rig R6 tự ghép bằng 8 Part + 6 Motor6D. Nhìn thô và KHÔNG có
	animation đi bộ thật (chỉ là 2 cánh tay xoay bằng script).

	Module này thay bằng cách Roblox chính thức:

	  1. `Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)`
	     -> trả về một nhân vật R15 **đầy đủ 15 khớp** đúng chuẩn Roblox
	        (Head / UpperTorso / LowerTorso / 2 tay trên-dưới-bàn tay / 2 chân ...).

	  2. Vì hàm trên khá chậm (phải nạp mesh), module chỉ dựng **3–4 MẪU** rồi
	     `:Clone()` cho từng NPC. Mỗi bản clone được **sơn lại màu** (da / áo / quần /
	     giày) nên nhìn vẫn đa dạng mà gần như không tốn thời gian.

	  3. `Animator:LoadAnimation` với **animation gốc của Roblox** (idle / walk / run)
	     -> NPC đi bộ đúng kiểu nhân vật Roblox, không phải đồ giả lập.

	  4. **Skin của người chơi:** mỗi khi có người vào game, lấy
	     `Humanoid:GetAppliedDescription()` của chính họ rồi dựng 1 NPC giống hệt
	     (kể cả phụ kiện, áo quần, khuôn mặt) đi lại trong thành phố.

	Nếu vì lý do nào đó Roblox không dựng được model (mất mạng, Studio chặn asset),
	`build()` trả về `nil` và NPCManager tự lùi về rig R6 cũ -> game không bao giờ mất NPC.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NPCAppearance = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- 1. ANIMATION GỐC CỦA ROBLOX (dùng chung cho mọi game, không cần xin quyền)
-- ══════════════════════════════════════════════════════════════════════════════

local ANIM_R15 = {
	idle = "rbxassetid://507766666",
	walk = "rbxassetid://507777826",
	run = "rbxassetid://507767714",
	jump = "rbxassetid://507765000",
	fall = "rbxassetid://507767968",
}

local ANIM_R6 = {
	idle = "rbxassetid://180435571",
	walk = "rbxassetid://180426354",
	run = "rbxassetid://180426354",
	jump = "rbxassetid://125750702",
	fall = "rbxassetid://180436148",
}

NPCAppearance.ANIM_R15 = ANIM_R15
NPCAppearance.ANIM_R6 = ANIM_R6

-- ══════════════════════════════════════════════════════════════════════════════
-- 2. BẢNG MÀU (da / áo / quần / giày) — đủ để phố đông mà không ai giống ai
-- ══════════════════════════════════════════════════════════════════════════════

local SKIN_TONES = {
	Color3.fromRGB(255, 216, 189),
	Color3.fromRGB(241, 194, 162),
	Color3.fromRGB(224, 172, 133),
	Color3.fromRGB(198, 143, 104),
	Color3.fromRGB(166, 112, 78),
	Color3.fromRGB(124, 82, 56),
	Color3.fromRGB(92, 60, 42),
}

local SHIRT_TONES = {
	Color3.fromRGB(214, 219, 226), -- áo trắng
	Color3.fromRGB(36, 41, 51),    -- áo đen
	Color3.fromRGB(46, 90, 160),   -- xanh dương
	Color3.fromRGB(168, 62, 62),   -- đỏ gạch
	Color3.fromRGB(198, 156, 64),  -- vàng mù tạt
	Color3.fromRGB(52, 118, 96),   -- xanh rêu
	Color3.fromRGB(120, 78, 148),  -- tím
	Color3.fromRGB(226, 132, 64),  -- cam
	Color3.fromRGB(58, 64, 74),    -- xám than
}

local PANTS_TONES = {
	Color3.fromRGB(38, 46, 64),    -- jean xanh đậm
	Color3.fromRGB(58, 58, 62),    -- xám
	Color3.fromRGB(26, 28, 32),    -- đen
	Color3.fromRGB(120, 104, 82),  -- kaki
	Color3.fromRGB(72, 88, 106),   -- xanh nhạt
}

local SHOE_TONES = {
	Color3.fromRGB(20, 21, 24),
	Color3.fromRGB(232, 232, 226),
	Color3.fromRGB(96, 52, 34),
	Color3.fromRGB(180, 60, 60),
}

-- Quần áo theo tính cách: cảnh sát / đầu gấu / doanh nhân ăn mặc khác dân thường
local ARCHETYPE_LOOK = {
	CIVILIAN = { shirt = nil, pants = nil, hat = false, sleeve = false },
	TOURIST = { shirt = Color3.fromRGB(232, 196, 84), pants = Color3.fromRGB(58, 106, 160), hat = true, sleeve = true },
	BUSINESS = { shirt = Color3.fromRGB(236, 240, 246), pants = Color3.fromRGB(32, 36, 46), hat = false, sleeve = true },
	GANGSTER = { shirt = Color3.fromRGB(28, 30, 34), pants = Color3.fromRGB(28, 30, 34), hat = false, sleeve = true },
	BRAWLER = { shirt = Color3.fromRGB(150, 44, 44), pants = Color3.fromRGB(54, 54, 58), hat = false, sleeve = false },
	COP = { shirt = Color3.fromRGB(30, 52, 96), pants = Color3.fromRGB(26, 30, 40), hat = true, sleeve = true },
}

-- Ghép nhóm bộ phận R15 để sơn cho nhanh
local R15_BODY_GROUPS = {
	torso = { "UpperTorso", "LowerTorso" },
	leftArm = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
	rightArm = { "RightUpperArm", "RightLowerArm", "RightHand" },
	leftLeg = { "LeftUpperLeg", "LeftLowerLeg" },
	rightLeg = { "RightUpperLeg", "RightLowerLeg" },
	leftFoot = { "LeftFoot" },
	rightFoot = { "RightFoot" },
}

local function pick(list)
	return list[math.random(1, #list)]
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 3. DỰNG MẪU R15 (chỉ 3–4 lần, sau đó chỉ clone)
-- ══════════════════════════════════════════════════════════════════════════════

local templates: { Model } = {}

local function makeBaseDescription(i: number): HumanoidDescription
	local desc = Instance.new("HumanoidDescription")

	-- Dáng người: mẫu 1 mảnh khảnh, mẫu 2 cân đối, mẫu 3 đầy đặn, mẫu 4 thấp
	local heightScales = { 1.0, 0.97, 0.94, 0.9 }
	local widthScales = { 0.86, 0.94, 1.0, 0.92 }
	local bodyScales = { 0.0, 0.25, 0.6, 0.15 }

	desc.HeightScale = heightScales[i] or 1.0
	desc.WidthScale = widthScales[i] or 1.0
	desc.BodyTypeScale = bodyScales[i] or 0.2
	desc.HeadScale = 1.0
	desc.ProportionScale = 1.0
	desc.DepthScale = 1.0

	-- Màu trung tính; mỗi NPC sẽ được sơn lại riêng sau khi clone
	desc.HeadColor = Color3.fromRGB(224, 172, 133)
	desc.TorsoColor = Color3.fromRGB(214, 219, 226)
	desc.LeftArmColor = Color3.fromRGB(224, 172, 133)
	desc.RightArmColor = Color3.fromRGB(224, 172, 133)
	desc.LeftLegColor = Color3.fromRGB(38, 46, 64)
	desc.RightLegColor = Color3.fromRGB(38, 46, 64)

	return desc
end

--- Dựng sẵn các mẫu R15. Trả về số mẫu dựng được (0 = Roblox không cho dựng -> dùng R6).
function NPCAppearance.warmTemplates(count: number?): number
	local want = count or 4
	if #templates >= want then
		return #templates
	end

	for i = #templates + 1, want do
		local ok, result = pcall(function()
			local desc = makeBaseDescription(i)
			local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
			desc:Destroy()
			return model
		end)

		if ok and result then
			local hum = result:FindFirstChildOfClass("Humanoid")
			local hrp = result:FindFirstChild("HumanoidRootPart")
			if hum and hrp then
				result.Name = "NPCTemplate_" .. i
				-- Giữ mẫu trong ReplicatedStorage (không nằm trong Workspace -> không bị
				-- streaming, không bị người chơi nhìn thấy, không chạy vật lý)
				local holder = ReplicatedStorage:FindFirstChild("NPCTemplateHolder")
				if not holder then
					holder = Instance.new("Folder")
					holder.Name = "NPCTemplateHolder"
					holder.Parent = ReplicatedStorage
				end
				model.Parent = holder
				table.insert(templates, model)
			else
				result:Destroy()
			end
		end
	end

	return #templates
end

NPCAppearance.templateCount = function(): number
	return #templates
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 4. SƠN LẠI + TRANG ĐIỂM
-- ══════════════════════════════════════════════════════════════════════════════

local function setColor(model: Model, groupName: string, color: Color3)
	local names = R15_BODY_GROUPS[groupName]
	if not names then
		return
	end
	for _, n in ipairs(names) do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			p.Color = color
		end
	end
end

local function paint(model: Model, archId: string)
	local look = ARCHETYPE_LOOK[archId] or ARCHETYPE_LOOK.CIVILIAN
	local skin = pick(SKIN_TONES)
	local shirt = look.shirt or pick(SHIRT_TONES)
	local pants = look.pants or pick(PANTS_TONES)
	local shoe = pick(SHOE_TONES)
	local longSleeve = look.sleeve == true

	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		head.Color = skin
	end
	setColor(model, "torso", shirt)
	setColor(model, "leftArm", if longSleeve then shirt else skin)
	setColor(model, "rightArm", if longSleeve then shirt else skin)
	setColor(model, "leftLeg", pants)
	setColor(model, "rightLeg", pants)
	setColor(model, "leftFoot", shoe)
	setColor(model, "rightFoot", shoe)

	-- Mặt cười cổ điển: dùng texture có sẵn trong client Roblox (không cần asset id)
	if head then
		local existing = head:FindFirstChild("NPCPaintedFace")
		if not existing then
			local decal = Instance.new("Decal")
			decal.Name = "NPCPaintedFace"
			decal.Texture = "rbxasset://textures/face.png"
			decal.Face = Enum.NormalId.Front
			local ok = pcall(function()
				decal.Parent = head
			end)
			if not ok then
				decal:Destroy()
			end
		end
	end

	-- Mũ: cảnh sát đội mũ kết, khách du lịch đội mũ vành
	if look.hat and head then
		local hat = Instance.new("Part")
		hat.Name = "NPCHat"
		hat.Size = Vector3.new(1.35, 0.22, 1.35)
		hat.Color = if archId == "COP" then Color3.fromRGB(26, 34, 60) else Color3.fromRGB(214, 178, 96)
		hat.Material = Enum.Material.Fabric
		hat.CanCollide = false
		hat.CanQuery = false
		hat.Massless = true
		hat.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.5 + 0.12, 0)
		local w = Instance.new("WeldConstraint")
		w.Part0 = head
		w.Part1 = hat
		w.Parent = hat
		hat.Parent = model
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 5. BUILD — trả về model R15 hoặc nil (để NPCManager lùi về R6)
-- ══════════════════════════════════════════════════════════════════════════════

local function finish(model: Model, archId: string, walkSpeed: number, maxHealth: number, skipPaint: boolean?)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or not hrp:IsA("BasePart") then
		return nil
	end

	hum.RigType = Enum.HumanoidRigType.R15
	hum.MaxHealth = maxHealth
	hum.Health = maxHealth
	hum.WalkSpeed = walkSpeed
	hum.JumpPower = 0
	hum.AutoRotate = true
	hum.BreakJointsOnDeath = false
	hum.RequiresNeck = false
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.NameDisplayDistance = 0
	hum.PlatformStand = false

	-- Tắt mọi script Animate mặc định: NPCManager tự điều khiển animation
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BaseScript") then
			d:Destroy()
		end
	end

	if not skipPaint then
		paint(model, archId)
	end

	model.PrimaryPart = hrp
	return model, hum, hrp, model:FindFirstChild("Head")
end

--- Dựng một NPC R15 hoàn chỉnh tại `cf`.
--- Trả về (model, humanoid, humanoidRootPart, head) hoặc nil.
function NPCAppearance.build(archId: string, cf: CFrame, walkSpeed: number, maxHealth: number)
	if #templates == 0 then
		return nil
	end

	local template = templates[math.random(1, #templates)]
	local ok, clone = pcall(function()
		return template:Clone()
	end)
	if not ok or not clone then
		return nil
	end

	clone.Name = "NPC_" .. archId .. "_" .. tostring(math.random(1000, 9999))
	clone:PivotTo(cf)

	return finish(clone, archId, walkSpeed, maxHealth)
end

--- Dựng NPC giống HỆT avatar của một người chơi (kể cả phụ kiện, áo quần).
function NPCAppearance.fromPlayer(player: Player, cf: CFrame)
	local character = player.Character
	if not character then
		return nil
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then
		return nil
	end

	local ok, desc = pcall(function()
		return hum:GetAppliedDescription()
	end)
	if not ok or not desc then
		return nil
	end

	local okBuild, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	desc:Destroy()

	if not okBuild or not model then
		return nil
	end

	model.Name = "NPC_TWIN_" .. player.Name
	model:PivotTo(cf)

	-- skipPaint = true: giữ nguyên 100% ngoại hình của người chơi
	local result = finish(model, "CIVILIAN", 14, 100, true)
	if not result then
		model:Destroy()
		return nil
	end
	model:SetAttribute("IsPlayerTwin", true)
	model:SetAttribute("TwinOf", player.Name)
	return result
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 6. ANIMATION THẬT (Animator) — idle / walk / run
-- ══════════════════════════════════════════════════════════════════════════════

export type AnimSet = {
	animator: Animator,
	tracks: { [string]: AnimationTrack },
	playing: string?,
}

--- Nạp bộ animation gốc Roblox cho một model. Trả về AnimSet hoặc nil nếu thất bại.
function NPCAppearance.loadAnimations(model: Model, hum: Humanoid): AnimSet?
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		local okCreate, created = pcall(function()
			local a = Instance.new("Animator")
			a.Parent = hum
			return a
		end)
		if okCreate then
			animator = created
		end
	end
	if not animator then
		return nil
	end

	local ids = if hum.RigType == Enum.HumanoidRigType.R6 then ANIM_R6 else ANIM_R15
	local tracks: { [string]: AnimationTrack } = {}

	for name, id in pairs(ids) do
		if name == "idle" or name == "walk" or name == "run" then
			local ok, track = pcall(function()
				local anim = Instance.new("Animation")
				anim.Name = "NPCAnim_" .. name
				anim.AnimationId = id
				local t = animator:LoadAnimation(anim)
				-- KHÔNG Destroy: giữ Animation làm cha của track cho chắc ăn
				anim.Parent = animator
				return t
			end)
			-- Track nạp hỏng thường có Length = 0 -> loại luôn để client tự vẽ
			if ok and track and track.Length and track.Length > 0.05 then
				track.Looped = true
				track.Priority = Enum.AnimationPriority.Movement
				tracks[name] = track
			end
		end
	end

	if not tracks.idle and not tracks.walk then
		-- Không nạp được animation thật -> báo cho client biết để tự vẽ bằng Motor6D
		return nil
	end

	return { animator = animator, tracks = tracks, playing = nil }
end

--- Chỉnh nhịp chạy của animation cho khớp tốc độ thật.
--- Animation đi bộ gốc của Roblox được làm cho WalkSpeed = 16; NPC đi 11–17 stud/s
--- nếu không chỉnh sẽ bị "trượt băng" (chân bước chậm hơn thân người).
function NPCAppearance.tuneGait(set: AnimSet?, walkSpeed: number)
	if not set then
		return
	end
	local walkRatio = math.clamp(walkSpeed / 16, 0.6, 1.35)
	local runRatio = math.clamp(walkSpeed / 22, 0.7, 1.3)
	if set.tracks.walk then
		pcall(function()
			set.tracks.walk:AdjustSpeed(walkRatio)
		end)
	end
	if set.tracks.run then
		pcall(function()
			set.tracks.run:AdjustSpeed(runRatio)
		end)
	end
end

--- Đổi animation đang chạy (có fade). Bỏ qua nếu đang chạy đúng bài đó rồi.
function NPCAppearance.playAnim(set: AnimSet?, name: string, fade: number?)
	if not set then
		return
	end
	if set.playing == name then
		return
	end
	local fadeTime = fade or 0.18
	local old = if set.playing then set.tracks[set.playing] else nil
	local new = set.tracks[name]
	if old then
		pcall(function()
			old:Stop(fadeTime)
		end)
	end
	if new then
		pcall(function()
			new:Play(fadeTime)
		end)
		set.playing = name
	else
		set.playing = nil
	end
end

function NPCAppearance.stopAnim(set: AnimSet?)
	if not set then
		return
	end
	for _, track in pairs(set.tracks) do
		pcall(function()
			track:Stop(0.15)
		end)
	end
	set.playing = nil
end

return NPCAppearance
