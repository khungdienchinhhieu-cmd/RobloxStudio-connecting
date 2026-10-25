--!strict
--[[
	GtaWeaponWheel.luau
	================================================================================
	VÒNG CHỌN SÚNG CHUẨN GTA V  (giữ TAB để mở, thả TAB để trang bị)
	--------------------------------------------------------------------------------
	• 8 ô vũ khí xếp vòng tròn, ô TRÊN CÙNG = ô số 1, đi theo chiều kim đồng hồ.
	• Rê chuột ra khỏi tâm -> ô theo hướng chuột sáng lên, tâm hiện tên + đạn.
	• Chết giữa vùng tâm -> giữ nguyên ô đang chọn (giống hệt GTA V).
	• Phím 1..8 đổi súng nhanh khi KHÔNG mở vòng.
	• Thẻ vũ khí góc dưới phải: tên súng + ĐẠN TRONG BĂNG / DỰ TRỮ + nhắc [R].
	• Icon súng được vẽ 100% bằng Frame (không cần asset ngoài, không tốn texture).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GtaWeaponWheel = {}

--============================================================================
-- BẢNG MÀU DÙNG CHUNG (khớp GtaHud)
--============================================================================
local C = {
	panel = Color3.fromRGB(10, 12, 16),
	panelLight = Color3.fromRGB(18, 23, 31),
	line = Color3.fromRGB(38, 48, 64),
	text = Color3.fromRGB(241, 245, 249),
	dim = Color3.fromRGB(148, 163, 184),
	white = Color3.fromRGB(255, 255, 255),
	danger = Color3.fromRGB(239, 68, 68),
}

local SLOT_GAP = math.pi / 4 -- 8 ô = 45°
local RING_RADIUS = 196
local SLOT_SIZE = 108

local FALLBACK_WEAPONS = {
	{ name = "Unarmed", display = "TAY KHÔNG", icon = "fist", slot = 1, category = "KHÔNG VŨ KHÍ", magSize = 0, accent = { 148, 163, 184 } },
	{ name = "Baseball Bat", display = "GẬY BÓNG CHÀY", icon = "bat", slot = 2, category = "CẬN CHIẾN", magSize = 0, accent = { 245, 158, 11 } },
	{ name = "Pistol 9mm", display = "PISTOL 9MM", icon = "pistol", slot = 3, category = "SÚNG NGẮN", magSize = 12, accent = { 96, 165, 250 } },
	{ name = "AP Pistol", display = "AP PISTOL", icon = "appistol", slot = 4, category = "SÚNG NGẮN TỰ ĐỘNG", magSize = 18, accent = { 56, 189, 248 } },
	{ name = "Micro SMG", display = "MICRO SMG", icon = "smg", slot = 5, category = "TIỂU LIÊN", magSize = 30, accent = { 45, 212, 191 } },
	{ name = "Carbine Rifle", display = "CARBINE RIFLE", icon = "rifle", slot = 6, category = "SÚNG TRƯỜNG", magSize = 30, accent = { 74, 222, 128 } },
	{ name = "Assault Shotgun", display = "ASSAULT SHOTGUN", icon = "shotgun", slot = 7, category = "SÚNG SHOTGUN", magSize = 8, accent = { 251, 146, 60 } },
	{ name = "Sniper Rifle", display = "SNIPER RIFLE", icon = "sniper", slot = 8, category = "SÚNG BẮN TỈA", magSize = 5, accent = { 192, 132, 252 } },
}

local function accentOf(list: { number }?): Color3
	if list and #list >= 3 then
		return Color3.fromRGB(list[1], list[2], list[3])
	end
	return Color3.fromRGB(148, 163, 184)
end

--============================================================================
-- BỘ VẼ ICON BẰNG FRAME
--============================================================================
local function newRect(parent: Instance, w: number, h: number, x: number, y: number, rot: number?, col: Color3?): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = col or C.text
	f.BorderSizePixel = 0
	f.Rotation = rot or 0
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, math.min(w, h) * 0.24)
	c.Parent = f
	return f
end

-- Mỗi icon vẽ trong khung 64 × 64 (tâm 32,32)
local function buildIcon(kind: string, parent: Instance, scale: number?): Frame
	local box = Instance.new("Frame")
	box.Name = "Icon_" .. kind
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.44)
	box.Size = UDim2.fromOffset(64, 64) -- luôn vẽ trên lưới 64×64 rồi thu nhỏ bằng UIScale
	box.BackgroundTransparency = 1
	box.Parent = parent
	if scale and scale ~= 1 then
		local s = Instance.new("UIScale")
		s.Scale = scale
		s.Parent = box
	end

	local body = C.text

	if kind == "fist" then
		newRect(box, 30, 25, 32, 34, 0, body)
		for i = 0, 3 do
			newRect(box, 7, 12, 22 + i * 7, 22, 0, body)
		end
		newRect(box, 11, 9, 18, 34, -20, body)
		newRect(box, 22, 8, 32, 48, 0, Color3.fromRGB(203, 213, 225))
	elseif kind == "bat" then
		newRect(box, 9, 40, 36, 30, -38, Color3.fromRGB(214, 168, 108))
		newRect(box, 13, 12, 21, 47, -38, Color3.fromRGB(240, 205, 150))
		local knob = newRect(box, 10, 10, 44, 15, 0, Color3.fromRGB(120, 84, 46))
		local kc = Instance.new("UICorner")
		kc.CornerRadius = UDim.new(1, 0)
		kc.Parent = knob
	elseif kind == "pistol" then
		newRect(box, 34, 10, 32, 26, 0, body)
		newRect(box, 10, 19, 21, 40, 14, body)
		newRect(box, 8, 5, 50, 26, 0, Color3.fromRGB(203, 213, 225))
		newRect(box, 10, 3, 32, 20, 0, Color3.fromRGB(120, 132, 148))
	elseif kind == "appistol" then
		newRect(box, 38, 11, 32, 25, 0, body)
		newRect(box, 10, 20, 21, 41, 14, body)
		newRect(box, 7, 15, 24, 47, 0, Color3.fromRGB(203, 213, 225))
		newRect(box, 8, 5, 52, 25, 0, Color3.fromRGB(203, 213, 225))
	elseif kind == "smg" then
		newRect(box, 32, 12, 32, 28, 0, body)
		newRect(box, 9, 20, 30, 44, 6, body)
		newRect(box, 12, 4, 51, 28, 0, Color3.fromRGB(203, 213, 225))
		newRect(box, 14, 3, 16, 28, 0, Color3.fromRGB(148, 163, 184))
	elseif kind == "rifle" then
		newRect(box, 44, 9, 32, 29, 0, body)
		newRect(box, 17, 3, 56, 29, 0, Color3.fromRGB(203, 213, 225))
		newRect(box, 9, 16, 34, 43, 6, body)
		newRect(box, 13, 5, 12, 30, 0, Color3.fromRGB(148, 163, 184))
		newRect(box, 14, 3, 32, 23, 0, Color3.fromRGB(203, 213, 225))
	elseif kind == "shotgun" then
		newRect(box, 40, 11, 30, 27, 0, body)
		newRect(box, 20, 6, 54, 24, 0, Color3.fromRGB(203, 213, 225))
		newRect(box, 16, 7, 44, 33, 0, Color3.fromRGB(148, 163, 184))
		newRect(box, 15, 8, 10, 31, 0, Color3.fromRGB(160, 120, 80))
	elseif kind == "sniper" then
		newRect(box, 48, 6, 32, 32, 0, body)
		newRect(box, 18, 8, 32, 22, 0, Color3.fromRGB(203, 213, 225))
		newRect(box, 8, 4, 32, 18, 0, Color3.fromRGB(148, 163, 184))
		newRect(box, 14, 8, 10, 34, 0, Color3.fromRGB(160, 168, 180))
		newRect(box, 4, 12, 20, 44, 12, body)
	end

	return box
end

--============================================================================
-- MOUNT
--============================================================================
function GtaWeaponWheel.mount(localPlayer: Player, syncRemote: RemoteEvent, reloadRemote: RemoteEvent)
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("GtaWeaponWheelGui")
	if old then
		old:Destroy()
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "GtaWeaponWheelGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 40
	screen.Parent = playerGui

	--=======================================================================
	-- A. THẺ VŨ KHÍ GÓC DƯỚI PHẢI (luôn hiển thị khi đang cầm súng)
	--=======================================================================
	local card = Instance.new("Frame")
	card.Name = "WeaponCard"
	card.AnchorPoint = Vector2.new(1, 1)
	card.Position = UDim2.new(1, -26, 1, -86)
	card.Size = UDim2.fromOffset(252, 76)
	card.BackgroundColor3 = C.panel
	card.BackgroundTransparency = 0.22
	card.BorderSizePixel = 0
	card.Visible = false
	card.Parent = screen

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(0, 0, 0)
	cardStroke.Transparency = 0.45
	cardStroke.Thickness = 1.5
	cardStroke.Parent = card

	local cardAccent = Instance.new("Frame")
	cardAccent.AnchorPoint = Vector2.new(1, 0)
	cardAccent.Position = UDim2.new(1, 0, 0, 10)
	cardAccent.Size = UDim2.new(0, 3, 1, -20)
	cardAccent.BackgroundColor3 = Color3.fromRGB(96, 165, 250)
	cardAccent.BorderSizePixel = 0
	cardAccent.Parent = card
	local caCorner = Instance.new("UICorner")
	caCorner.CornerRadius = UDim.new(1, 0)
	caCorner.Parent = cardAccent

	local iconBox = Instance.new("Frame")
	iconBox.Name = "IconBox"
	iconBox.AnchorPoint = Vector2.new(0, 0.5)
	iconBox.Position = UDim2.new(0, 10, 0.5, 0)
	iconBox.Size = UDim2.fromOffset(58, 58)
	iconBox.BackgroundColor3 = C.panelLight
	iconBox.BackgroundTransparency = 0.35
	iconBox.BorderSizePixel = 0
	iconBox.Parent = card
	local ibCorner = Instance.new("UICorner")
	ibCorner.CornerRadius = UDim.new(0, 6)
	ibCorner.Parent = iconBox

	local equippedIcon = buildIcon("pistol", iconBox, 0.72)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "WeaponName"
	nameLabel.AnchorPoint = Vector2.new(1, 0)
	nameLabel.Position = UDim2.new(1, -12, 0, 8)
	nameLabel.Size = UDim2.fromOffset(168, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Right
	nameLabel.TextColor3 = C.dim
	nameLabel.Text = "PISTOL 9MM"
	nameLabel.Parent = card

	local magLabel = Instance.new("TextLabel")
	magLabel.Name = "MagCount"
	magLabel.AnchorPoint = Vector2.new(1, 0)
	magLabel.Position = UDim2.new(1, -12, 0, 24)
	magLabel.Size = UDim2.fromOffset(120, 32)
	magLabel.BackgroundTransparency = 1
	magLabel.Font = Enum.Font.GothamBlack
	magLabel.TextSize = 30
	magLabel.TextXAlignment = Enum.TextXAlignment.Right
	magLabel.TextColor3 = C.white
	magLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	magLabel.TextStrokeTransparency = 0.55
	magLabel.Text = "12"
	magLabel.Parent = card

	local reserveLabel = Instance.new("TextLabel")
	reserveLabel.Name = "ReserveCount"
	reserveLabel.AnchorPoint = Vector2.new(1, 0)
	reserveLabel.Position = UDim2.new(1, -14, 0, 52)
	reserveLabel.Size = UDim2.fromOffset(120, 16)
	reserveLabel.BackgroundTransparency = 1
	reserveLabel.Font = Enum.Font.GothamBold
	reserveLabel.TextSize = 12
	reserveLabel.TextXAlignment = Enum.TextXAlignment.Right
	reserveLabel.TextColor3 = C.dim
	reserveLabel.Text = "/ 120"
	reserveLabel.Parent = card

	local reloadHint = Instance.new("TextLabel")
	reloadHint.Name = "ReloadHint"
	reloadHint.AnchorPoint = Vector2.new(0, 1)
	reloadHint.Position = UDim2.new(0, 76, 1, -6)
	reloadHint.Size = UDim2.fromOffset(140, 14)
	reloadHint.BackgroundTransparency = 1
	reloadHint.Font = Enum.Font.GothamBlack
	reloadHint.TextSize = 10
	reloadHint.TextXAlignment = Enum.TextXAlignment.Left
	reloadHint.TextColor3 = C.danger
	reloadHint.Text = "[R] NẠP ĐẠN"
	reloadHint.Visible = false
	reloadHint.Parent = card

	--=======================================================================
	-- B. VÒNG CHỌN SÚNG
	--=======================================================================
	local overlay = Instance.new("Frame")
	overlay.Name = "WheelOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Active = true
	overlay.Parent = screen

	local wheelRoot = Instance.new("Frame")
	wheelRoot.Name = "WheelRoot"
	wheelRoot.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelRoot.Position = UDim2.fromScale(0.5, 0.5)
	wheelRoot.Size = UDim2.fromOffset(620, 620)
	wheelRoot.BackgroundTransparency = 1
	wheelRoot.Parent = overlay

	local rootScale = Instance.new("UIScale")
	rootScale.Scale = 1
	rootScale.Parent = wheelRoot

	-- Vòng ngoài mảnh + 24 vạch chia trang trí
	local outerRing = Instance.new("Frame")
	outerRing.Name = "OuterRing"
	outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
	outerRing.Position = UDim2.fromScale(0.5, 0.5)
	outerRing.Size = UDim2.fromOffset(560, 560)
	outerRing.BackgroundTransparency = 1
	outerRing.Parent = wheelRoot
	local orRing = Instance.new("UICorner")
	orRing.CornerRadius = UDim.new(1, 0)
	orRing.Parent = outerRing
	local orStroke = Instance.new("UIStroke")
	orStroke.Color = Color3.fromRGB(255, 255, 255)
	orStroke.Transparency = 0.86
	orStroke.Thickness = 1.5
	orStroke.Parent = outerRing

	for i = 0, 23 do
		-- vạch chia mảnh quanh vành ngoài (bán kính 268px tính từ tâm)
		local rad = math.rad(i * 15)
		local line = Instance.new("Frame")
		line.Name = "Tick_" .. tostring(i)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.new(0.5, math.sin(rad) * 268, 0.5, -math.cos(rad) * 268)
		line.Size = UDim2.fromOffset(2, 10)
		line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		line.BackgroundTransparency = 0.74
		line.BorderSizePixel = 0
		line.Rotation = i * 15
		line.Parent = wheelRoot
	end

	-- Tâm: danh mục + tên súng + đạn
	local hub = Instance.new("Frame")
	hub.Name = "Hub"
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Position = UDim2.fromScale(0.5, 0.5)
	hub.Size = UDim2.fromOffset(206, 206)
	hub.BackgroundColor3 = C.panel
	hub.BackgroundTransparency = 0.14
	hub.BorderSizePixel = 0
	hub.Parent = wheelRoot
	local hubCorner = Instance.new("UICorner")
	hubCorner.CornerRadius = UDim.new(1, 0)
	hubCorner.Parent = hub
	local hubStroke = Instance.new("UIStroke")
	hubStroke.Color = Color3.fromRGB(255, 255, 255)
	hubStroke.Transparency = 0.8
	hubStroke.Thickness = 1.5
	hubStroke.Parent = hub

	local hubCategory = Instance.new("TextLabel")
	hubCategory.AnchorPoint = Vector2.new(0.5, 0)
	hubCategory.Position = UDim2.new(0.5, 0, 0, 44)
	hubCategory.Size = UDim2.fromOffset(180, 14)
	hubCategory.BackgroundTransparency = 1
	hubCategory.Font = Enum.Font.GothamBold
	hubCategory.TextSize = 10
	hubCategory.TextColor3 = C.dim
	hubCategory.Text = "SÚNG NGẮN"
	hubCategory.Parent = hub

	local hubName = Instance.new("TextLabel")
	hubName.AnchorPoint = Vector2.new(0.5, 0)
	hubName.Position = UDim2.new(0.5, 0, 0, 60)
	hubName.Size = UDim2.fromOffset(188, 44)
	hubName.BackgroundTransparency = 1
	hubName.Font = Enum.Font.GothamBlack
	hubName.TextSize = 17
	hubName.TextWrapped = true
	hubName.TextColor3 = C.white
	hubName.Text = "PISTOL 9MM"
	hubName.Parent = hub

	local hubAmmo = Instance.new("TextLabel")
	hubAmmo.AnchorPoint = Vector2.new(0.5, 0)
	hubAmmo.Position = UDim2.new(0.5, 0, 0, 106)
	hubAmmo.Size = UDim2.fromOffset(180, 24)
	hubAmmo.BackgroundTransparency = 1
	hubAmmo.Font = Enum.Font.GothamBlack
	hubAmmo.TextSize = 20
	hubAmmo.TextColor3 = Color3.fromRGB(96, 165, 250)
	hubAmmo.Text = "12 / 120"
	hubAmmo.Parent = hub

	local hubHint = Instance.new("TextLabel")
	hubHint.AnchorPoint = Vector2.new(0.5, 0)
	hubHint.Position = UDim2.new(0.5, 0, 0, 146)
	hubHint.Size = UDim2.fromOffset(180, 14)
	hubHint.BackgroundTransparency = 1
	hubHint.Font = Enum.Font.GothamBold
	hubHint.TextSize = 9
	hubHint.TextColor3 = Color3.fromRGB(120, 132, 148)
	hubHint.Text = "THẢ TAB ĐỂ TRANG BỊ"
	hubHint.Parent = hub

	-- 8 ô vũ khí quanh vòng
	type SlotView = {
		button: TextButton,
		stroke: UIStroke,
		scale: UIScale,
		icon: Frame,
		label: TextLabel,
		ammoTag: TextLabel,
		accent: Color3,
	}

	local slots: { SlotView } = {}
	local slotButtons: { TextButton } = {}

	for i = 1, 8 do
		local angle = -math.pi / 2 + (i - 1) * SLOT_GAP
		local sx = math.cos(angle) * RING_RADIUS
		local sy = math.sin(angle) * RING_RADIUS

		local btn = Instance.new("TextButton")
		btn.Name = "Slot_" .. tostring(i)
		btn.AnchorPoint = Vector2.new(0.5, 0.5)
		btn.Position = UDim2.new(0.5, sx, 0.5, sy)
		btn.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
		btn.BackgroundColor3 = C.panelLight
		btn.BackgroundTransparency = 0.18
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Parent = wheelRoot

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 18)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Transparency = 0.72
		stroke.Thickness = 1.5
		stroke.Parent = btn

		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = btn

		local keyBadge = Instance.new("TextLabel")
		keyBadge.AnchorPoint = Vector2.new(0, 0)
		keyBadge.Position = UDim2.fromOffset(8, 6)
		keyBadge.Size = UDim2.fromOffset(18, 18)
		keyBadge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		keyBadge.BackgroundTransparency = 0.86
		keyBadge.Font = Enum.Font.GothamBlack
		keyBadge.TextSize = 10
		keyBadge.TextColor3 = C.white
		keyBadge.Text = tostring(i)
		keyBadge.BorderSizePixel = 0
		keyBadge.Parent = btn
		local kbCorner = Instance.new("UICorner")
		kbCorner.CornerRadius = UDim.new(1, 0)
		kbCorner.Parent = keyBadge

		local icon = buildIcon("pistol", btn, 0.8)
		icon.Position = UDim2.fromScale(0.5, 0.42)

		local label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Position = UDim2.new(0.5, 0, 1, -8)
		label.Size = UDim2.new(1, -12, 0, 14)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 9
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.TextColor3 = C.dim
		label.Text = "VŨ KHÍ"
		label.Parent = btn

		local ammoTag = Instance.new("TextLabel")
		ammoTag.AnchorPoint = Vector2.new(1, 0)
		ammoTag.Position = UDim2.new(1, -7, 0, 6)
		ammoTag.Size = UDim2.fromOffset(46, 14)
		ammoTag.BackgroundTransparency = 1
		ammoTag.Font = Enum.Font.GothamBlack
		ammoTag.TextSize = 10
		ammoTag.TextXAlignment = Enum.TextXAlignment.Right
		ammoTag.TextColor3 = C.dim
		ammoTag.Text = ""
		ammoTag.Parent = btn

		table.insert(slots, {
			button = btn,
			stroke = stroke,
			scale = scale,
			icon = icon,
			label = label,
			ammoTag = ammoTag,
			accent = C.dim,
		})
		table.insert(slotButtons, btn)

		btn.MouseEnter:Connect(function()
			if overlay.Visible then
				GtaWeaponWheel._select(i)
			end
		end)
		btn.MouseButton1Click:Connect(function()
			if overlay.Visible then
				GtaWeaponWheel._select(i)
				GtaWeaponWheel._equip(i)
				GtaWeaponWheel._close(true)
			end
		end)
	end

	--=======================================================================
	-- C. DỮ LIỆU VŨ KHÍ
	--=======================================================================
	local weapons: { any } = table.clone(FALLBACK_WEAPONS)
	local bySlot: { [number]: any } = {}
	local ammoBySlot: { [number]: { mag: number, reserve: number, magSize: number } } = {}
	local selectedSlot = 3
	local wheelOpen = false
	local equippedName = ""

	local function rebuildIndex()
		bySlot = {}
		for _, w in ipairs(weapons) do
			bySlot[w.slot] = w
		end
	end
	rebuildIndex()

	local function updateCard()
		local active = bySlot[selectedSlot]
		if not active then
			return
		end
		nameLabel.Text = tostring(active.display)
		local accent = accentOf(active.accent)
		cardAccent.BackgroundColor3 = accent
		iconBox.BackgroundColor3 = C.panelLight
		local ammo = ammoBySlot[active.slot]
		if ammo and ammo.magSize > 0 then
			magLabel.Text = tostring(ammo.mag)
			reserveLabel.Text = "/ " .. tostring(ammo.reserve)
			magLabel.TextColor3 = if ammo.mag == 0 then C.danger else C.white
			reloadHint.Visible = ammo.mag == 0
		else
			magLabel.Text = ""
			reserveLabel.Text = if active.slot <= 2 then "CẬN CHIẾN" else ""
			reloadHint.Visible = false
		end
	end

	local function refreshSlotVisuals()
		for slotIdx, view in ipairs(slots) do
			local w = bySlot[slotIdx]
			if w then
				view.label.Text = string.upper(tostring(w.display))
				local ammo = ammoBySlot[slotIdx]
				if ammo and ammo.magSize > 0 then
					view.ammoTag.Text = tostring(ammo.mag) .. "/" .. tostring(ammo.reserve)
					view.ammoTag.TextColor3 = if ammo.mag == 0 then C.danger else C.dim
				else
					view.ammoTag.Text = if slotIdx <= 2 then "∞" else ""
					view.ammoTag.TextColor3 = C.dim
				end
				view.accent = accentOf(w.accent)
				-- Vẽ lại icon theo đúng loại súng (xoá hẳn khung cũ để không rò rỉ Frame)
				if view.icon.Parent then
					view.icon:Destroy()
				end
				local rebuilt = buildIcon(tostring(w.icon), view.button, 0.8)
				rebuilt.Position = UDim2.fromScale(0.5, 0.40)
				view.icon = rebuilt
			end
		end
	end

	--========================================================================
	-- D. CHỌN Ô
	--========================================================================
	local function setSelected(index: number)
		selectedSlot = index
		for i, view in ipairs(slots) do
			local on = i == index
			local w = bySlot[i]
			local accent = if w then accentOf(w.accent) else C.dim
			view.stroke.Color = if on then accent else Color3.fromRGB(255, 255, 255)
			view.stroke.Transparency = if on then 0 else 0.72
			view.stroke.Thickness = if on then 3 else 1.5
			view.button.BackgroundColor3 = if on then accent:Lerp(C.panel, 0.72) else C.panelLight
			view.button.BackgroundTransparency = if on then 0.02 else 0.18
			TweenService:Create(view.scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {
				Scale = if on then 1.09 else 1,
			}):Play()
			view.label.TextColor3 = if on then C.white else C.dim
		end
		local w = bySlot[index]
		if w then
			hubCategory.Text = string.upper(tostring(w.category or ""))
			hubName.Text = string.upper(tostring(w.display))
			local accent = accentOf(w.accent)
			hubAmmo.TextColor3 = accent
			hubStroke.Color = accent
			hubStroke.Transparency = 0.55
			local ammo = ammoBySlot[index]
			if ammo and ammo.magSize > 0 then
				hubAmmo.Text = tostring(ammo.mag) .. " / " .. tostring(ammo.reserve)
			else
				hubAmmo.Text = if index <= 2 then "∞" else "—"
			end
		end
		updateCard()
	end

	--========================================================================
	-- E. TRANG BỊ
	--========================================================================
	local function equipSlot(index: number)
		local w = bySlot[index]
		if not w then
			return
		end
		local char = localPlayer.Character
		local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		if not hum then
			return
		end
		if w.name == "Unarmed" then
			hum:UnequipTools()
			equippedName = "Unarmed"
		else
			local backpack = localPlayer:FindFirstChild("Backpack")
			local tool = (char and char:FindFirstChild(w.name)) or (backpack and backpack:FindFirstChild(w.name))
			if tool and tool:IsA("Tool") then
				hum:EquipTool(tool)
				equippedName = w.name
			end
		end
		updateCard()
	end

	--========================================================================
	-- F. MỞ / ĐÓNG
	--========================================================================
	local function openWheel()
		if wheelOpen then
			return
		end
		wheelOpen = true
		overlay.Visible = true
		overlay.BackgroundTransparency = 1
		rootScale.Scale = 0.9
		TweenService:Create(overlay, TweenInfo.new(0.16), { BackgroundTransparency = 0.45 }):Play()
		TweenService:Create(rootScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
		-- Bắt đầu từ súng đang cầm
		local char = localPlayer.Character
		local tool = if char then char:FindFirstChildOfClass("Tool") else nil
		local startSlot = selectedSlot
		if tool and tool:GetAttribute("IsGtaWeapon") == true then
			local slotNum = tonumber(tool:GetAttribute("WeaponSlot"))
			if slotNum then
				startSlot = slotNum
			end
		end
		setSelected(startSlot)
		localPlayer:SetAttribute("WeaponWheelOpen", true)
	end

	local function closeWheel(equip: boolean)
		if not wheelOpen then
			return
		end
		wheelOpen = false
		localPlayer:SetAttribute("WeaponWheelOpen", false)
		TweenService:Create(overlay, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(rootScale, TweenInfo.new(0.12), { Scale = 0.92 }):Play()
		task.delay(0.13, function()
			if not wheelOpen then
				overlay.Visible = false
			end
		end)
		if equip then
			equipSlot(selectedSlot)
		end
	end

	GtaWeaponWheel._select = setSelected
	GtaWeaponWheel._equip = equipSlot
	GtaWeaponWheel._close = closeWheel

	--========================================================================
	-- G. ĐỒNG BỘ TỪ SERVER
	--========================================================================
	local function applyState(payload: any)
		if type(payload) ~= "table" then
			return
		end
		if payload.type == "state" then
			if type(payload.weapons) == "table" and #payload.weapons > 0 then
				weapons = payload.weapons
				rebuildIndex()
				ammoBySlot = {}
				for _, w in ipairs(weapons) do
					if type(w.magSize) == "number" and w.magSize > 0 then
						ammoBySlot[w.slot] = {
							mag = tonumber(w.mag) or 0,
							reserve = tonumber(w.reserve) or 0,
							magSize = w.magSize,
						}
					end
				end
				refreshSlotVisuals()
				setSelected(selectedSlot)
			end
			equippedName = tostring(payload.equipped or "")
		elseif payload.type == "ammo" then
			for _, w in ipairs(weapons) do
				if w.name == payload.name then
					ammoBySlot[w.slot] = {
						mag = tonumber(payload.mag) or 0,
						reserve = tonumber(payload.reserve) or 0,
						magSize = tonumber(payload.magSize) or w.magSize or 0,
					}
					break
				end
			end
			refreshSlotVisuals()
			updateCard()
		end
	end

	syncRemote.OnClientEvent:Connect(applyState)

	--========================================================================
	-- H. PHÍM TẮT
	--========================================================================
	local function otherUiOpen(): boolean
		return localPlayer:GetAttribute("UIMenuOpen") == true
	end

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.Tab then
			if not otherUiOpen() then
				openWheel()
			end
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			reloadRemote:FireServer()
			return
		end
		if wheelOpen then
			if input.KeyCode == Enum.KeyCode.Escape then
				closeWheel(false)
			end
			return
		end
		if otherUiOpen() then
			return
		end
		local keySlots: { [Enum.KeyCode]: number } = {
			[Enum.KeyCode.One] = 1,
			[Enum.KeyCode.Two] = 2,
			[Enum.KeyCode.Three] = 3,
			[Enum.KeyCode.Four] = 4,
			[Enum.KeyCode.Five] = 5,
			[Enum.KeyCode.Six] = 6,
			[Enum.KeyCode.Seven] = 7,
			[Enum.KeyCode.Eight] = 8,
		}
		local slot = keySlots[input.KeyCode]
		if slot then
			setSelected(slot)
			equipSlot(slot)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Tab and wheelOpen then
			closeWheel(true)
		end
	end)

	--========================================================================
	-- I. CHỌN THEO HƯỚNG CHUỘT (mỗi frame khi mở)
	--========================================================================
	local function updateSelectionFromMouse()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local vp = cam.ViewportSize
		local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
		local mouse = UserInputService:GetMouseLocation()
		local delta = mouse - center
		local dist = delta.Magnitude
		if dist < 54 then
			return -- vùng chết ở tâm: giữ nguyên ô đang chọn
		end
		local deg = math.deg(math.atan2(delta.Y, delta.X))
		local normalized = (deg + 90 + 22.5) % 360
		local idx = math.floor(normalized / 45) + 1
		idx = math.clamp(idx, 1, 8)
		if idx ~= selectedSlot then
			setSelected(idx)
		end
	end

	--========================================================================
	-- J. THẺ VŨ KHÍ: ẨN KHI LÁI XE / KHI TAY KHÔNG
	--========================================================================
	local cardAccum = 0
	local lastEquippedKey = ""

	RunService.RenderStepped:Connect(function(dt)
		if wheelOpen then
			updateSelectionFromMouse()
			return
		end

		cardAccum += dt
		if cardAccum < 0.12 then
			return
		end
		cardAccum = 0

		local char = localPlayer.Character
		local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		local tool = if char then char:FindFirstChildOfClass("Tool") else nil
		local armed = tool ~= nil and tool:GetAttribute("IsGtaWeapon") == true and tool.Name ~= "Baseball Bat"
		local inVehicle = hum ~= nil and hum.SeatPart ~= nil

		if not armed or inVehicle then
			card.Visible = false
			return
		end
		card.Visible = true

		local slotNum = tonumber(tool and tool:GetAttribute("WeaponSlot")) or selectedSlot
		local key = tostring(tool and tool.Name) .. "|" .. tostring(slotNum)
		if key ~= lastEquippedKey then
			lastEquippedKey = key
			selectedSlot = slotNum
			updateCard()
		end
	end)

	-- Khởi tạo hiển thị
	refreshSlotVisuals()
	setSelected(3)

	return screen
end

return GtaWeaponWheel
