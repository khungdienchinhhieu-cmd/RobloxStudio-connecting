--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))

local GtaHud = {}

local RADAR_W = 258
local RADAR_H = 168
local RADAR_SCALE = 0.52 -- tỉ lệ zoom rộng chuẩn GTA V thấy rõ 4 đại lộ + bờ biển xung quanh

local function formatDollars(amount: number): string
	local negative = amount < 0
	local n = math.floor(math.abs(amount))
	local s = tostring(n)
	local formatted = s
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return (if negative then "-$" else "$") .. formatted
end

function GtaHud.mount(localPlayer: Player, hudRemote: RemoteEvent)
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	for _, oldName in ipairs({ "CityInteractiveHud", "GtaVHud" }) do
		local old = playerGui:FindFirstChild(oldName)
		if old then
			old:Destroy()
		end
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "GtaVHud"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = false
	screen.Parent = playerGui

	-- ========================================================================
	-- 1. CỤM RADAR HÌNH CHỮ NHẬT + 3 THANH MÁU / GIÁP / THỂ LỰC (GÓC DƯỚI TRÁI)
	-- ========================================================================
	local radarCluster = Instance.new("Frame")
	radarCluster.Name = "RadarCluster"
	radarCluster.AnchorPoint = Vector2.new(0, 1)
	radarCluster.Position = UDim2.new(0, 22, 1, -20)
	radarCluster.Size = UDim2.fromOffset(RADAR_W, RADAR_H + 32)
	radarCluster.BackgroundTransparency = 1
	radarCluster.Parent = screen

	local radarOuter = Instance.new("Frame")
	radarOuter.Name = "RadarOuter"
	radarOuter.Size = UDim2.fromOffset(RADAR_W, RADAR_H)
	radarOuter.BackgroundColor3 = Color3.fromRGB(16, 21, 28)
	radarOuter.BackgroundTransparency = 0.12
	radarOuter.BorderSizePixel = 0
	radarOuter.ClipsDescendants = true
	radarOuter.Parent = radarCluster

	local radarCorner = Instance.new("UICorner")
	radarCorner.CornerRadius = UDim.new(0, 10)
	radarCorner.Parent = radarOuter

	local radarStroke = Instance.new("UIStroke")
	radarStroke.Color = Color3.fromRGB(6, 8, 12)
	radarStroke.Thickness = 2.5
	radarStroke.Transparency = 0.08
	radarStroke.Parent = radarOuter

	-- Viền kính mảnh bên trong (chi tiết nhỏ tạo cảm giác HUD GTA V thật)
	local radarInner = Instance.new("Frame")
	radarInner.Name = "RadarGlass"
	radarInner.Position = UDim2.fromOffset(1, 1)
	radarInner.Size = UDim2.new(1, -2, 1, -2)
	radarInner.BackgroundTransparency = 1
	radarInner.ZIndex = 8
	radarInner.Parent = radarOuter
	local rgCorner = Instance.new("UICorner")
	rgCorner.CornerRadius = UDim.new(0, 9)
	rgCorner.Parent = radarInner
	local rgStroke = Instance.new("UIStroke")
	rgStroke.Color = Color3.fromRGB(255, 255, 255)
	rgStroke.Transparency = 0.84
	rgStroke.Thickness = 1
	rgStroke.Parent = radarInner

	-- Lớp bản đồ thế giới xoay & cuộn theo tọa độ thực tế từ WorldGrid
	local mapPivot = Instance.new("Frame")
	mapPivot.Name = "MapPivot"
	mapPivot.AnchorPoint = Vector2.new(0.5, 0.5)
	mapPivot.Position = UDim2.fromScale(0.5, 0.56)
	mapPivot.Size = UDim2.fromOffset(0, 0)
	mapPivot.BackgroundTransparency = 1
	mapPivot.Parent = radarOuter

	local mapContent = Instance.new("Frame")
	mapContent.Name = "MapContent"
	mapContent.Size = UDim2.fromOffset(0, 0)
	mapContent.BackgroundTransparency = 1
	mapContent.Parent = mapPivot

	local function addMinimapRect(name: string, cx: number, cz: number, sx: number, sz: number, col: Color3, zIdx: number)
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset(cx * RADAR_SCALE, cz * RADAR_SCALE)
		f.Size = UDim2.fromOffset(math.max(2, sx * RADAR_SCALE), math.max(2, sz * RADAR_SCALE))
		f.BackgroundColor3 = col
		f.BorderSizePixel = 0
		f.ZIndex = zIdx
		f.Parent = mapContent
	end

	-- Vẽ Bờ biển Thái Bình Dương, Cát Vespucci & Đồi Vinewood lên Minimap
	addMinimapRect("Ocean", 0, 305, 720, 120, Color3.fromRGB(36, 128, 198), 2)
	addMinimapRect("BeachSand", 0, 210, 720, 72, Color3.fromRGB(214, 192, 142), 2)
	addMinimapRect("VinewoodHills", 0, -300, 720, 120, Color3.fromRGB(58, 96, 54), 2)

	-- Vẽ 6 Ô đất quy hoạch đối xứng lên Minimap
	for _, plot in ipairs(WorldGrid.PLOTS) do
		local blockCol = if plot.id == "Plot_C2"
			then Color3.fromRGB(78, 146, 84)
			else Color3.fromRGB(52, 60, 72)
		addMinimapRect(plot.id, plot.center.X, plot.center.Z, plot.size.X, plot.size.Z, blockCol, 3)
	end

	-- Vẽ toàn bộ mạng lưới 7 Đại lộ Los Santos sáng rõ chuẩn GTA V trên Minimap
	for _, r in ipairs(WorldGrid.EW_ROADS) do
		local len = r.max - r.min
		local cx = (r.min + r.max) * 0.5
		addMinimapRect(r.id, cx, r.coord, len, r.width, Color3.fromRGB(204, 214, 226), 4)
	end
	for _, r in ipairs(WorldGrid.NS_ROADS) do
		local len = r.max - r.min
		local cz = (r.min + r.max) * 0.5
		addMinimapRect(r.id, r.coord, cz, r.width, len, Color3.fromRGB(204, 214, 226), 4)
	end

	-- Đánh dấu Quảng Trường Trung Tâm Legion Square (lối đi chữ thập + hồ nước + Blip vàng) trên Minimap
	addMinimapRect("PlazaWalkNS_Map", 0, 57, 28, 132, Color3.fromRGB(186, 180, 168), 3)
	addMinimapRect("PlazaWalkEW_Map", 0, 57, 166, 24, Color3.fromRGB(186, 180, 168), 3)
	addMinimapRect("PlazaCourt_Map", 0, 57, 96, 86, Color3.fromRGB(196, 190, 178), 3)
	addMinimapRect("PlazaPool_Map", 0, 49, 40, 28, Color3.fromRGB(46, 168, 206), 4)
	local spawnBlip = Instance.new("Frame")
	spawnBlip.AnchorPoint = Vector2.new(0.5, 0.5)
	spawnBlip.Position = UDim2.fromOffset(0, 49 * RADAR_SCALE)
	spawnBlip.Size = UDim2.fromOffset(9, 9)
	spawnBlip.BackgroundColor3 = Color3.fromRGB(250, 204, 21)
	spawnBlip.ZIndex = 5
	spawnBlip.Parent = mapContent
	local sbCorner = Instance.new("UICorner")
	sbCorner.CornerRadius = UDim.new(1, 0)
	sbCorner.Parent = spawnBlip
	local sbStroke = Instance.new("UIStroke")
	sbStroke.Color = Color3.fromRGB(10, 12, 16)
	sbStroke.Thickness = 1.5
	sbStroke.Parent = spawnBlip

	-- Lớp chớp Xanh-Đỏ cảnh sát khi có Sao Truy Nã (Wanted >= 1)
	local wantedFlash = Instance.new("Frame")
	wantedFlash.Name = "PoliceRadarFlash"
	wantedFlash.Size = UDim2.fromScale(1, 1)
	wantedFlash.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	wantedFlash.BackgroundTransparency = 1
	wantedFlash.BorderSizePixel = 0
	wantedFlash.ZIndex = 7
	wantedFlash.Parent = radarOuter

	-- Mũi tên vị trí người chơi ở tâm Radar
	local playerBlip = Instance.new("Frame")
	playerBlip.Name = "PlayerArrow"
	playerBlip.AnchorPoint = Vector2.new(0.5, 0.5)
	playerBlip.Position = UDim2.fromScale(0.5, 0.56)
	playerBlip.Size = UDim2.fromOffset(12, 12)
	playerBlip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	playerBlip.Rotation = 45
	playerBlip.ZIndex = 9
	playerBlip.Parent = radarOuter

	local pbStroke = Instance.new("UIStroke")
	pbStroke.Color = Color3.fromRGB(10, 12, 16)
	pbStroke.Thickness = 2
	pbStroke.Parent = playerBlip

	-- Huy hiệu chữ 'N' chỉ hướng Bắc bám viền Radar
	local northBadge = Instance.new("TextLabel")
	northBadge.Name = "NorthCompass"
	northBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	northBadge.Position = UDim2.new(0.5, 0, 0, 11)
	northBadge.Size = UDim2.fromOffset(18, 18)
	northBadge.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	northBadge.Font = Enum.Font.GothamBlack
	northBadge.TextSize = 11
	northBadge.TextColor3 = Color3.fromRGB(248, 250, 252)
	northBadge.Text = "N"
	northBadge.ZIndex = 10
	northBadge.Parent = radarCluster
	local nbCorner = Instance.new("UICorner")
	nbCorner.CornerRadius = UDim.new(1, 0)
	nbCorner.Parent = northBadge

	-- 3 Thanh Chỉ Số XẾP CHỒNG Chuẩn GTA V: Máu (xanh) | Giáp (xanh dương) | Thể lực (vàng)
	local barsRow = Instance.new("Frame")
	barsRow.Name = "StatusBarsRow"
	barsRow.Position = UDim2.fromOffset(0, RADAR_H + 7)
	barsRow.Size = UDim2.fromOffset(RADAR_W, 22)
	barsRow.BackgroundTransparency = 1
	barsRow.Parent = radarCluster

	local function makeStatBar(name: string, yPos: number, trackCol: Color3, fillCol: Color3): Frame
		local track = Instance.new("Frame")
		track.Name = name .. "Track"
		track.Position = UDim2.fromOffset(2, yPos)
		track.Size = UDim2.fromOffset(RADAR_W - 4, 5)
		track.BackgroundColor3 = trackCol
		track.BackgroundTransparency = 0.35
		track.BorderSizePixel = 0
		track.Parent = barsRow
		local tCorner = Instance.new("UICorner")
		tCorner.CornerRadius = UDim.new(0, 3)
		tCorner.Parent = track

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = fillCol
		fill.BorderSizePixel = 0
		fill.Parent = track
		local fCorner = Instance.new("UICorner")
		fCorner.CornerRadius = UDim.new(0, 3)
		fCorner.Parent = fill
		return fill
	end

	local healthFill = makeStatBar("Health", 0, Color3.fromRGB(28, 52, 28), Color3.fromRGB(86, 186, 86))
	local armorFill = makeStatBar("Armor", 7, Color3.fromRGB(22, 42, 62), Color3.fromRGB(59, 155, 232))
	local staminaFill = makeStatBar("Stamina", 14, Color3.fromRGB(58, 48, 20), Color3.fromRGB(238, 193, 53))

	-- ========================================================================
	-- 2. HỘP THÔNG BÁO ĐEN MỜ PHÍA TRÊN MINIMAP (GTA V FEED BOX)
	-- ========================================================================
	local feedBox = Instance.new("Frame")
	feedBox.Name = "GtaFeedNotification"
	feedBox.AnchorPoint = Vector2.new(0, 1)
	feedBox.Position = UDim2.new(0, 22, 1, -(RADAR_H + 60))
	feedBox.Size = UDim2.fromOffset(RADAR_W, 56)
	feedBox.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	feedBox.BackgroundTransparency = 0.22
	feedBox.BorderSizePixel = 0
	feedBox.Visible = false
	feedBox.Parent = screen
	local fbCorner = Instance.new("UICorner")
	fbCorner.CornerRadius = UDim.new(0, 7)
	fbCorner.Parent = feedBox
	local fbStroke = Instance.new("UIStroke")
	fbStroke.Color = Color3.fromRGB(0, 0, 0)
	fbStroke.Transparency = 0.55
	fbStroke.Thickness = 1
	fbStroke.Parent = feedBox

	local feedAccent = Instance.new("Frame")
	feedAccent.Size = UDim2.new(0, 4, 1, 0)
	feedAccent.BackgroundColor3 = Color3.fromRGB(86, 186, 86)
	feedAccent.BorderSizePixel = 0
	feedAccent.Parent = feedBox

	local feedText = Instance.new("TextLabel")
	feedText.Position = UDim2.fromOffset(12, 6)
	feedText.Size = UDim2.new(1, -20, 1, -12)
	feedText.BackgroundTransparency = 1
	feedText.Font = Enum.Font.GothamMedium
	feedText.TextSize = 12
	feedText.TextWrapped = true
	feedText.TextXAlignment = Enum.TextXAlignment.Left
	feedText.TextYAlignment = Enum.TextYAlignment.Center
	feedText.TextColor3 = Color3.fromRGB(241, 245, 249)
	feedText.Parent = feedBox

	local feedToken = 0
	local function showFeed(message: string, accentCol: Color3?)
		feedToken += 1
		local myToken = feedToken
		feedAccent.BackgroundColor3 = accentCol or Color3.fromRGB(86, 186, 86)
		feedText.Text = message
		feedBox.Visible = true
		feedBox.BackgroundTransparency = 0.22
		task.delay(4.5, function()
			if feedToken == myToken then
				feedBox.Visible = false
			end
		end)
	end

	-- ========================================================================
	-- 3. CỤM GÓC TRÊN PHẢI: 5 SAO TRUY NÃ + TIỀN MẶT ($) + ĐỒNG HỒ GAME
	-- ========================================================================
	local topRight = Instance.new("Frame")
	topRight.Name = "TopRightCluster"
	topRight.AnchorPoint = Vector2.new(1, 0)
	topRight.Position = UDim2.new(1, -26, 0, 16)
	topRight.Size = UDim2.fromOffset(270, 108)
	topRight.BackgroundTransparency = 1
	topRight.Parent = screen

	-- Dãy 5 Sao Truy Nã (ẩn khi Wanted = 0 giống hệt GTA V!)
	local starsRow = Instance.new("Frame")
	starsRow.Name = "WantedStarsRow"
	starsRow.AnchorPoint = Vector2.new(1, 0)
	starsRow.Position = UDim2.new(1, 4, 0, -2)
	starsRow.Size = UDim2.fromOffset(173, 32)
	starsRow.BackgroundColor3 = Color3.fromRGB(6, 9, 13)
	starsRow.BackgroundTransparency = 0.55
	starsRow.BorderSizePixel = 0
	starsRow.Visible = false
	starsRow.Parent = topRight
	local srCorner = Instance.new("UICorner")
	srCorner.CornerRadius = UDim.new(1, 0)
	srCorner.Parent = starsRow

	local starLabels: { TextLabel } = {}
	for i = 1, 5 do
		local star = Instance.new("TextLabel")
		star.Name = "Star_" .. tostring(i)
		star.Position = UDim2.fromOffset((i - 1) * 33, 0)
		star.Size = UDim2.fromOffset(30, 28)
		star.BackgroundTransparency = 1
		star.Font = Enum.Font.GothamBlack
		star.TextSize = 25
		star.Text = "★"
		star.TextColor3 = Color3.fromRGB(255, 255, 255)
		star.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
		star.TextStrokeTransparency = 0.15
		star.Parent = starsRow
		table.insert(starLabels, star)
	end

	-- Nền kính mờ phía sau số tiền (giúp con số nổi bật trên mọi bối cảnh)
	local cashPanel = Instance.new("Frame")
	cashPanel.Name = "CashPanel"
	cashPanel.AnchorPoint = Vector2.new(1, 0)
	cashPanel.Position = UDim2.new(1, 8, 0, 26)
	cashPanel.Size = UDim2.fromOffset(292, 78)
	cashPanel.BackgroundColor3 = Color3.fromRGB(6, 9, 13)
	cashPanel.BackgroundTransparency = 0.46
	cashPanel.BorderSizePixel = 0
	cashPanel.ZIndex = 0
	cashPanel.Parent = topRight
	local cpc = Instance.new("UICorner")
	cpc.CornerRadius = UDim.new(0, 8)
	cpc.Parent = cashPanel
	local cps = Instance.new("UIStroke")
	cps.Color = Color3.fromRGB(0, 0, 0)
	cps.Transparency = 0.62
	cps.Thickness = 1
	cps.Parent = cashPanel
	local cashAccent = Instance.new("Frame")
	cashAccent.AnchorPoint = Vector2.new(1, 0.5)
	cashAccent.Position = UDim2.new(1, -6, 0.5, 0)
	cashAccent.Size = UDim2.fromOffset(3, 44)
	cashAccent.BackgroundColor3 = Color3.fromRGB(114, 204, 114)
	cashAccent.BackgroundTransparency = 0.15
	cashAccent.BorderSizePixel = 0
	cashAccent.Parent = cashPanel
	local cac = Instance.new("UICorner")
	cac.CornerRadius = UDim.new(1, 0)
	cac.Parent = cashAccent

	-- Hiển thị Tiền Mặt chuẩn xanh lá GTA V
	local cashLabel = Instance.new("TextLabel")
	cashLabel.Name = "CashDisplay"
	cashLabel.AnchorPoint = Vector2.new(1, 0)
	cashLabel.Position = UDim2.new(1, 0, 0, 30)
	cashLabel.Size = UDim2.fromOffset(270, 34)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Font = Enum.Font.GothamBlack
	cashLabel.TextSize = 29
	cashLabel.TextXAlignment = Enum.TextXAlignment.Right
	cashLabel.TextColor3 = Color3.fromRGB(114, 204, 114)
	cashLabel.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
	cashLabel.TextStrokeTransparency = 0.12
	cashLabel.Text = "$5,000"
	cashLabel.Parent = topRight

	-- Hiệu ứng cộng/trừ tiền (+$500 / -$100)
	local cashDeltaLabel = Instance.new("TextLabel")
	cashDeltaLabel.Name = "CashDelta"
	cashDeltaLabel.AnchorPoint = Vector2.new(1, 0)
	cashDeltaLabel.Position = UDim2.new(1, 0, 0, 62)
	cashDeltaLabel.Size = UDim2.fromOffset(220, 22)
	cashDeltaLabel.BackgroundTransparency = 1
	cashDeltaLabel.Font = Enum.Font.GothamBold
	cashDeltaLabel.TextSize = 18
	cashDeltaLabel.TextXAlignment = Enum.TextXAlignment.Right
	cashDeltaLabel.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
	cashDeltaLabel.TextStrokeTransparency = 0.2
	cashDeltaLabel.Text = ""
	cashDeltaLabel.Parent = topRight

	-- Đồng hồ giờ Los Santos nhỏ gọn
	local clockChip = Instance.new("TextLabel")
	clockChip.Name = "GameClock"
	clockChip.AnchorPoint = Vector2.new(1, 0)
	clockChip.Position = UDim2.new(1, 0, 0, 84)
	clockChip.Size = UDim2.fromOffset(180, 18)
	clockChip.BackgroundTransparency = 1
	clockChip.Font = Enum.Font.GothamBold
	clockChip.TextSize = 12
	clockChip.TextXAlignment = Enum.TextXAlignment.Right
	clockChip.TextColor3 = Color3.fromRGB(215, 222, 232)
	clockChip.TextStrokeTransparency = 0.35
	clockChip.Text = "LOS SANTOS • 16:45"
	clockChip.Parent = topRight

	-- ========================================================================
	-- 4. GÓC DƯỚI PHẢI: CHỮ NGHỆ THUẬT TÊN KHU VỰC & ĐƯỜNG PHỐ (STREET & ZONE)
	-- ========================================================================
	local locationCluster = Instance.new("Frame")
	locationCluster.Name = "LocationCluster"
	locationCluster.AnchorPoint = Vector2.new(1, 1)
	locationCluster.Position = UDim2.new(1, -26, 1, -22)
	locationCluster.Size = UDim2.fromOffset(360, 56)
	locationCluster.BackgroundTransparency = 1
	locationCluster.Parent = screen

	local districtLabel = Instance.new("TextLabel")
	districtLabel.Name = "DistrictName"
	districtLabel.Position = UDim2.fromOffset(0, 2)
	districtLabel.Size = UDim2.new(1, 0, 0, 20)
	districtLabel.BackgroundTransparency = 1
	districtLabel.Font = Enum.Font.GothamBold
	districtLabel.TextSize = 15
	districtLabel.TextXAlignment = Enum.TextXAlignment.Right
	districtLabel.TextColor3 = Color3.fromRGB(240, 198, 66)
	districtLabel.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
	districtLabel.TextStrokeTransparency = 0.18
	districtLabel.Text = "LEGION SQUARE"
	districtLabel.Parent = locationCluster

	local streetLabel = Instance.new("TextLabel")
	streetLabel.Name = "StreetName"
	streetLabel.Position = UDim2.fromOffset(0, 24)
	streetLabel.Size = UDim2.new(1, 0, 0, 28)
	streetLabel.BackgroundTransparency = 1
	streetLabel.Font = Enum.Font.GothamBlack
	streetLabel.TextSize = 22
	streetLabel.TextXAlignment = Enum.TextXAlignment.Right
	streetLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
	streetLabel.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
	streetLabel.TextStrokeTransparency = 0.15
	streetLabel.Text = "Power Street"
	streetLabel.Parent = locationCluster

	-- ========================================================================
	-- 5. BẢNG MENU TEST PHONG CÁCH GTA V INTERACTION MENU (MẶC ĐỊNH ẨN — BẤM [H] ĐỂ MỞ)
	-- ========================================================================
	local openHintBtn = Instance.new("TextButton")
	openHintBtn.Name = "OpenTestHint"
	openHintBtn.Position = UDim2.fromOffset(22, 16)
	openHintBtn.Size = UDim2.fromOffset(118, 26)
	openHintBtn.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
	openHintBtn.BackgroundTransparency = 0.34
	openHintBtn.Font = Enum.Font.GothamBold
	openHintBtn.TextSize = 11
	openHintBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
	openHintBtn.Text = "[H]  MENU TEST"
	openHintBtn.AutoButtonColor = false
	openHintBtn.Parent = screen
	local ohCorner = Instance.new("UICorner")
	ohCorner.CornerRadius = UDim.new(0, 6)
	ohCorner.Parent = openHintBtn
	local ohStroke = Instance.new("UIStroke")
	ohStroke.Color = Color3.fromRGB(0, 0, 0)
	ohStroke.Transparency = 0.55
	ohStroke.Thickness = 1
	ohStroke.Parent = openHintBtn
	openHintBtn.MouseEnter:Connect(function()
		TweenService:Create(openHintBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.12 }):Play()
	end)
	openHintBtn.MouseLeave:Connect(function()
		TweenService:Create(openHintBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.34 }):Play()
	end)

	-- Chip nhắc phím [TAB] mở VÒNG CHỌN SÚNG (chuẩn GTA V)
	local weaponHint = Instance.new("TextLabel")
	weaponHint.Name = "WeaponWheelHint"
	weaponHint.Position = UDim2.fromOffset(148, 16)
	weaponHint.Size = UDim2.fromOffset(126, 26)
	weaponHint.BackgroundColor3 = Color3.fromRGB(8, 11, 16)
	weaponHint.BackgroundTransparency = 0.34
	weaponHint.Font = Enum.Font.GothamBold
	weaponHint.TextSize = 11
	weaponHint.TextColor3 = Color3.fromRGB(226, 232, 240)
	weaponHint.Text = "[TAB]  VŨ KHÍ"
	weaponHint.Parent = screen
	local whCorner = Instance.new("UICorner")
	whCorner.CornerRadius = UDim.new(0, 6)
	whCorner.Parent = weaponHint
	local whStroke = Instance.new("UIStroke")
	whStroke.Color = Color3.fromRGB(0, 0, 0)
	whStroke.Transparency = 0.55
	whStroke.Thickness = 1
	whStroke.Parent = weaponHint

	local testBar = Instance.new("Frame")
	testBar.Name = "DevHudTestBar"
	testBar.Position = UDim2.fromOffset(22, 16)
	testBar.Size = UDim2.fromOffset(RADAR_W, 261)
	testBar.BackgroundColor3 = Color3.fromRGB(10, 13, 18)
	testBar.BackgroundTransparency = 0.12
	testBar.BorderSizePixel = 0
	testBar.Visible = false -- Mặc định đóng để HUD sạch chuẩn GTA V, bấm [H] mới hiện!
	testBar.Parent = screen

	local tbStroke = Instance.new("UIStroke")
	tbStroke.Color = Color3.fromRGB(0, 0, 0)
	tbStroke.Thickness = 2
	tbStroke.Transparency = 0.25
	tbStroke.Parent = testBar
	local tbCorner = Instance.new("UICorner")
	tbCorner.CornerRadius = UDim.new(0, 7)
	tbCorner.Parent = testBar

	-- Header xanh đậm đặc trưng của GTA V Interaction Menu
	local menuHeader = Instance.new("Frame")
	menuHeader.Size = UDim2.new(1, 0, 0, 44)
	menuHeader.BackgroundColor3 = Color3.fromRGB(24, 74, 148)
	menuHeader.BorderSizePixel = 0
	menuHeader.Parent = testBar
	local mhCorner = Instance.new("UICorner")
	mhCorner.CornerRadius = UDim.new(0, 7)
	mhCorner.Parent = menuHeader
	-- Dải gradient đậm dần sang phải cho header đỡ phẳng
	local mhGradient = Instance.new("UIGradient")
	mhGradient.Color = ColorSequence.new(Color3.fromRGB(32, 92, 178), Color3.fromRGB(16, 52, 112))
	mhGradient.Rotation = 12
	mhGradient.Parent = menuHeader

	local menuTitle = Instance.new("TextLabel")
	menuTitle.Position = UDim2.fromOffset(12, 4)
	menuTitle.Size = UDim2.new(1, -68, 0, 22)
	menuTitle.BackgroundTransparency = 1
	menuTitle.Font = Enum.Font.GothamBlack
	menuTitle.TextSize = 15
	menuTitle.TextXAlignment = Enum.TextXAlignment.Left
	menuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	menuTitle.Text = "LOS SANTOS"
	menuTitle.Parent = menuHeader

	local menuSub = Instance.new("TextLabel")
	menuSub.Position = UDim2.fromOffset(12, 23)
	menuSub.Size = UDim2.new(1, -24, 0, 15)
	menuSub.BackgroundTransparency = 1
	menuSub.Font = Enum.Font.GothamBold
	menuSub.TextSize = 10
	menuSub.TextXAlignment = Enum.TextXAlignment.Left
	menuSub.TextColor3 = Color3.fromRGB(191, 219, 254)
	menuSub.Text = "MENU KIỂM THỬ HỆ THỐNG"
	menuSub.Parent = menuHeader

	local closeTag = Instance.new("TextButton")
	closeTag.AnchorPoint = Vector2.new(1, 0.5)
	closeTag.Position = UDim2.new(1, -8, 0.5, 0)
	closeTag.Size = UDim2.fromOffset(52, 22)
	closeTag.BackgroundColor3 = Color3.fromRGB(12, 24, 48)
	closeTag.BackgroundTransparency = 0.25
	closeTag.Font = Enum.Font.GothamBold
	closeTag.TextSize = 10
	closeTag.TextColor3 = Color3.fromRGB(226, 232, 240)
	closeTag.Text = "[H] Đóng"
	closeTag.Parent = menuHeader
	local ctCorner = Instance.new("UICorner")
	ctCorner.CornerRadius = UDim.new(0, 4)
	ctCorner.Parent = closeTag

	local function toggleTestMenu()
		testBar.Visible = not testBar.Visible
		openHintBtn.Visible = not testBar.Visible
	end
	openHintBtn.MouseButton1Click:Connect(toggleTestMenu)
	closeTag.MouseButton1Click:Connect(toggleTestMenu)

	local testButtonsSpec = {
		{ label = "▶  Gọi Siêu Xe Trước Mặt", right = "CAR", cmd = "spawn_car", accent = Color3.fromRGB(56, 189, 248) },
		{ label = "★  Tăng +1 Sao Truy Nã", right = "LSPD", cmd = "add_star", accent = Color3.fromRGB(239, 68, 68) },
		{ label = "☆  Xoá Toàn Bộ Truy Nã", right = "0 ★", cmd = "clear_stars", accent = Color3.fromRGB(148, 163, 184) },
		{ label = "$  Nhận +$500 Tiền Mặt", right = "+$500", cmd = "add_cash", accent = Color3.fromRGB(114, 204, 114) },
		{ label = "◆  Nạp / Đổi Áo Giáp", right = "ARMOR", cmd = "add_armor", accent = Color3.fromRGB(59, 155, 232) },
		{ label = "✚  Thử Sát Thương / Hồi Máu", right = "HP", cmd = "test_hp", accent = Color3.fromRGB(245, 158, 11) },
	}
	for idx, bSpec in ipairs(testButtonsSpec) do
		local rowY = 46 + (idx - 1) * 35
		local btn = Instance.new("TextButton")
		btn.Position = UDim2.fromOffset(6, rowY)
		btn.Size = UDim2.new(1, -12, 0, 31)
		btn.BackgroundColor3 = Color3.fromRGB(22, 27, 36)
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextColor3 = Color3.fromRGB(241, 245, 249)
		btn.Text = "   " .. bSpec.label
		btn.AutoButtonColor = false
		btn.Parent = testBar
		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 5)
		bCorner.Parent = btn
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(34, 42, 56) }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(22, 27, 36) }):Play()
		end)

		local barLeft = Instance.new("Frame")
		barLeft.Size = UDim2.new(0, 3, 1, 0)
		barLeft.BackgroundColor3 = bSpec.accent
		barLeft.BorderSizePixel = 0
		barLeft.Parent = btn

		local rightTag = Instance.new("TextLabel")
		rightTag.AnchorPoint = Vector2.new(1, 0.5)
		rightTag.Position = UDim2.new(1, -8, 0.5, 0)
		rightTag.Size = UDim2.fromOffset(54, 18)
		rightTag.BackgroundTransparency = 1
		rightTag.Font = Enum.Font.GothamBlack
		rightTag.TextSize = 10
		rightTag.TextXAlignment = Enum.TextXAlignment.Right
		rightTag.TextColor3 = bSpec.accent
		rightTag.Text = bSpec.right
		rightTag.Parent = btn

		btn.MouseButton1Click:Connect(function()
			hudRemote:FireServer(bSpec.cmd)
		end)
	end

	-- ========================================================================
	-- 6. LOGIC ĐỒNG BỘ DỮ LIỆU THỜI GIAN THỰC (SPRINT, CASH, WANTED, RADAR)
	-- ========================================================================
	local stamina = 100
	local isSprinting = false
	local lastCash = tonumber(localPlayer:GetAttribute("Cash")) or 5000
	local deltaToken = 0
	local lastLocationKey = ""

	cashLabel.Text = formatDollars(lastCash)

	localPlayer:GetAttributeChangedSignal("Cash"):Connect(function()
		local current = tonumber(localPlayer:GetAttribute("Cash")) or 0
		local diff = current - lastCash
		lastCash = current
		cashLabel.Text = formatDollars(current)

		if diff ~= 0 then
			deltaToken += 1
			local myD = deltaToken
			cashDeltaLabel.Text = (if diff > 0 then "+" else "") .. formatDollars(diff)
			cashDeltaLabel.TextColor3 = if diff > 0
				then Color3.fromRGB(240, 253, 244)
				else Color3.fromRGB(248, 113, 113)
			task.delay(2.4, function()
				if deltaToken == myD then
					cashDeltaLabel.Text = ""
				end
			end)
		end
	end)

	local function refreshArmor()
		local armor = math.clamp(tonumber(localPlayer:GetAttribute("Armor")) or 0, 0, 100)
		TweenService:Create(armorFill, TweenInfo.new(0.2), {
			Size = UDim2.fromScale(armor / 100, 1),
		}):Play()
	end
	localPlayer:GetAttributeChangedSignal("Armor"):Connect(refreshArmor)
	refreshArmor()

	hudRemote.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and type(payload.message) == "string" then
			showFeed(payload.message, payload.color)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			isSprinting = true
		elseif input.KeyCode == Enum.KeyCode.H then
			toggleTestMenu()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			isSprinting = false
		end
	end)

	-- Đồng hồ tốc độ xe hơi góc dưới phải (tự hiện khi lên xe, tự ẩn khi xuống xe)
	local speedoCluster = Instance.new("Frame")
	speedoCluster.Name = "VehicleSpeedometer"
	speedoCluster.AnchorPoint = Vector2.new(1, 1)
	speedoCluster.Position = UDim2.new(1, -26, 1, -84)
	speedoCluster.Size = UDim2.fromOffset(196, 52)
	speedoCluster.BackgroundColor3 = Color3.fromRGB(6, 9, 13)
	speedoCluster.BackgroundTransparency = 0.42
	speedoCluster.BorderSizePixel = 0
	speedoCluster.Visible = false
	speedoCluster.Parent = screen
	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(0, 7)
	sCorner.Parent = speedoCluster
	local sStroke = Instance.new("UIStroke")
	sStroke.Color = Color3.fromRGB(0, 0, 0)
	sStroke.Transparency = 0.6
	sStroke.Thickness = 1
	sStroke.Parent = speedoCluster
	local sAccent = Instance.new("Frame")
	sAccent.AnchorPoint = Vector2.new(1, 0.5)
	sAccent.Position = UDim2.new(1, -5, 0.5, 0)
	sAccent.Size = UDim2.fromOffset(3, 30)
	sAccent.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
	sAccent.BorderSizePixel = 0
	sAccent.Parent = speedoCluster
	local saCorner = Instance.new("UICorner")
	saCorner.CornerRadius = UDim.new(1, 0)
	saCorner.Parent = sAccent

	local carNameTag = Instance.new("TextLabel")
	carNameTag.Position = UDim2.fromOffset(0, 0)
	carNameTag.Size = UDim2.new(1, -14, 0, 15)
	carNameTag.Position = UDim2.fromOffset(0, 6)
	carNameTag.BackgroundTransparency = 1
	carNameTag.Font = Enum.Font.GothamBold
	carNameTag.TextSize = 12
	carNameTag.TextXAlignment = Enum.TextXAlignment.Right
	carNameTag.TextColor3 = Color3.fromRGB(56, 189, 248)
	carNameTag.TextStrokeTransparency = 0.2
	carNameTag.Text = "BANSHEE GT"
	carNameTag.Parent = speedoCluster

	local mphLabel = Instance.new("TextLabel")
	mphLabel.Position = UDim2.fromOffset(0, 21)
	mphLabel.Size = UDim2.new(1, -14, 0, 26)
	mphLabel.BackgroundTransparency = 1
	mphLabel.Font = Enum.Font.GothamBlack
	mphLabel.TextSize = 26
	mphLabel.TextXAlignment = Enum.TextXAlignment.Right
	mphLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
	mphLabel.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
	mphLabel.TextStrokeTransparency = 0.14
	mphLabel.Text = "0 MPH"
	mphLabel.Parent = speedoCluster

	showFeed(
		"Los Santos sẵn sàng! Giữ [TAB] mở VÒNG CHỌN SÚNG • [F] lên xe • [R] nạp đạn • [H] Menu Test.",
		Color3.fromRGB(86, 186, 86)
	)

	local lastCarName = ""
	local lastMphText = ""

	-- =====================================================================
	-- TỐI ƯU HIỆU NĂNG: tách nhịp cập nhật HUD
	--   • 60 FPS : chỉ radar xoay/dịch + thanh máu/thể lực (phép tính rẻ, mượt)
	--   •  10 FPS : chữ đồng hồ, sao truy nã, tên xe, số MPH (string.format rất tốn)
	--   •   3 FPS : getLocationInfo() (dò khu vực/tên đường nặng nhất)
	-- Trước đây TOÀN BỘ chạy 60 FPS -> ~180 string.format + 240 FindFirstChild mỗi giây.
	-- =====================================================================
	local TEXT_INTERVAL = 0.1
	local LOCATION_INTERVAL = 0.34
	local textAccum = TEXT_INTERVAL
	local locationAccum = LOCATION_INTERVAL

	-- Cache nhân vật: tránh gọi FindFirstChild/FindFirstChildOfClass mỗi frame
	local cachedChar: Model? = nil
	local cachedHrp: BasePart? = nil
	local cachedHum: Humanoid? = nil

	local function refreshCharacterCache()
		local char = localPlayer.Character
		if char ~= cachedChar then
			cachedChar = char
			cachedHrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			cachedHum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		end
		if cachedHrp and not cachedHrp.Parent then
			cachedChar = nil
			cachedHrp = nil
			cachedHum = nil
		end
	end

	local function updateTextLayer(dt: number, hum: Humanoid, hrp: BasePart)
		-- Đồng hồ giờ game
		local ct = Lighting.ClockTime
		local hh = math.floor(ct)
		local mm = math.floor((ct - hh) * 60)
		clockChip.Text = string.format("LOS SANTOS • %02d:%02d", hh, mm)

		-- Sao truy nã + chớp Xanh-Đỏ
		local wanted = math.clamp(tonumber(localPlayer:GetAttribute("WantedLevel")) or 0, 0, 5)
		starsRow.Visible = wanted > 0
		if wanted > 0 then
			local pulsePhase = math.floor(os.clock() * 4.2) % 2 == 0
			wantedFlash.BackgroundColor3 = if pulsePhase
				then Color3.fromRGB(239, 68, 68)
				else Color3.fromRGB(59, 130, 246)
			wantedFlash.BackgroundTransparency = 0.84
			for i = 1, 5 do
				local st = starLabels[i]
				if i <= wanted then
					st.TextTransparency = 0
					st.TextColor3 = if pulsePhase
						then Color3.fromRGB(255, 255, 255)
						else Color3.fromRGB(191, 219, 254)
				else
					st.TextColor3 = Color3.fromRGB(30, 36, 46)
					st.TextTransparency = 0.42
				end
			end
		else
			wantedFlash.BackgroundTransparency = 1
		end

		-- Đồng hồ tốc độ MPH
		local seatPart = hum.SeatPart
		local activeCar = if seatPart then seatPart:FindFirstAncestorOfClass("Model") else nil
		if activeCar and activeCar:GetAttribute("IsGtaVehicle") == true then
			local mph = tonumber(activeCar:GetAttribute("CurrentMPH")) or 0
			local cname = tostring(activeCar:GetAttribute("VehicleDisplayName") or activeCar.Name)
			if cname ~= lastCarName then
				lastCarName = cname
				carNameTag.Text = string.upper(cname)
			end
			local mphText = string.format("%d MPH", mph)
			if mphText ~= lastMphText then
				lastMphText = mphText
				mphLabel.Text = mphText
			end
			speedoCluster.Visible = true
		else
			speedoCluster.Visible = false
			lastMphText = ""
		end
	end

	RunService.RenderStepped:Connect(function(dt)
		textAccum += dt
		locationAccum += dt
		local doText = textAccum >= TEXT_INTERVAL
		local doLocation = locationAccum >= LOCATION_INTERVAL
		if doText then
			textAccum = 0
		end
		if doLocation then
			locationAccum = 0
		end

		refreshCharacterCache()
		local hrp = cachedHrp
		local hum = cachedHum
		if not hrp or not hum then
			return
		end

		-- Máu (Health) — mượt mỗi frame
		local hpRatio = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
		healthFill.Size = UDim2.fromScale(hpRatio, 1)
		healthFill.BackgroundColor3 = if hpRatio < 0.3
			then Color3.fromRGB(220, 56, 56)
			else Color3.fromRGB(86, 186, 86)

		-- Thể lực chạy nhanh (Stamina) — mượt mỗi frame
		local moving = hum.MoveDirection.Magnitude > 0.05
		if isSprinting and moving and stamina > 1 then
			stamina = math.max(0, stamina - 22 * dt)
			hum.WalkSpeed = 24
		else
			stamina = math.min(100, stamina + 16 * dt)
			hum.WalkSpeed = 16
		end
		staminaFill.Size = UDim2.fromScale(stamina / 100, 1)

		-- Radar xoay/dịch theo Camera — mượt mỗi frame
		local cam = workspace.CurrentCamera
		local camLook = if cam then cam.CFrame.LookVector else Vector3.new(0, 0, -1)
		local camHeadingRad = math.atan2(camLook.X, -camLook.Z)
		local mapRotDeg = -math.deg(camHeadingRad)

		local pos = hrp.Position
		mapPivot.Rotation = mapRotDeg
		mapContent.Position = UDim2.fromOffset(-pos.X * RADAR_SCALE, -pos.Z * RADAR_SCALE)

		local charLook = hrp.CFrame.LookVector
		local charHeadingRad = math.atan2(charLook.X, -charLook.Z)
		playerBlip.Rotation = math.deg(charHeadingRad - camHeadingRad) + 45

		local northAngle = -camHeadingRad - math.pi / 2
		local nx = math.clamp(0.5 + math.cos(northAngle) * 0.46, 0.06, 0.94)
		local ny = math.clamp(0.5 + math.sin(northAngle) * 0.46, 0.07, 0.93)
		northBadge.Position = UDim2.new(nx, 0, 0, ny * RADAR_H)

		-- Tầng chữ: 10 lần/giây
		if doText then
			updateTextLayer(dt, hum, hrp)
		end

		-- Khu vực & tên đường: 3 lần/giây (nặng nhất)
		if doLocation then
			local distName, stName = WorldGrid.getLocationInfo(pos)
			local locKey = distName .. "|" .. stName
			if locKey ~= lastLocationKey then
				lastLocationKey = locKey
				districtLabel.Text = distName
				streetLabel.Text = stName
			end
		end

	end)

	return screen
end

return GtaHud
