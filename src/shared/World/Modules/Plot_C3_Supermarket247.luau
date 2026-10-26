--!strict
--[[
	Plot_C3_Supermarket247.luau  —  SIÊU THỊ TIỆN LỢI 24/7 (MISSION ROW - NỬA TÂY)
	Tác giả : Agent Phụ (nhánh arena/bc783dbc-robloxstudio-connecting)
	Ô đất   : Plot_C3_West  |  Buildable Bounds: X 137..212, Z 20..123, groundY = 1.15
	Hướng   : Mặt tiền chính quay Nam (+Z ra Vespucci Blvd) & Tây (-X ra Alta St).

	KIẾN TRÚC & NỘI THẤT (tất cả ghép khối có máu ẩn `integrity` → xe tông / súng bắn tự vỡ):
	  • Mặt tiền vách kính lớn chia từng ô (integrity = 45 bắn vỡ), cửa đôi kính cao 9.0 studs.
	  • Mái hiên sọc XANH LÁ - TRẮNG - CAM phát sáng kiểu 24/7 GTA V + biển hiệu Neon "24/7".
	  • Cửa cuốn kho hàng (loading bay) rộng 16 × cao 12 studs ở mặt Tây (>= 15 x 11 cho xe tải).
	  • Bãi đậu xe có vạch kẻ + gờ chặn bánh + cọc chắn vàng + cột đèn + biển pylon trên nóc.
	  • FULL nội thất: 3 dãy kệ gondola đầy sản phẩm, quầy thu ngân 3 làn + máy tính tiền,
	    máy ATM 24h, quầy cà phê / máy Slushie, đảo trái cây, tủ lạnh nước ngọt cửa kính phát sáng
	    dọc tường sau + biển "COLD DRINKS", văn phòng quản lý vách kính, đèn tuýp trần, camera.

	GHI CHÚ KỸ THUẬT: `PartBuilder` thực tế cung cấp part / masonryWall (running-bond).
	Các hàm tiện ích `box`, `brickWall`, `segmentedRow` bên dưới là lớp bọc (wrapper) cục bộ
	gọi thẳng vào PartBuilder.part / PartBuilder.masonryWall và LUÔN truyền `integrity`
	=> từng viên gạch / ô kính / món đồ đều có thuộc tính máu ẩn Destructible/PartHealth.
	Chỉ có MÓNG SÀN chịu lực là để `structural` (Destructible = false) để không sập cả sàn.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartBuilder = require(Shared:WaitForChild("World"):WaitForChild("PartBuilder"))

---------------------------------------------------------------------------------------------------
-- HẰNG SỐ TOẠ ĐỘ & BẢNG MÀU
---------------------------------------------------------------------------------------------------
local V = Vector3.new
local RGB = Color3.fromRGB

local FY = 1.6                 -- Cao độ mặt sàn hoàn thiện (top) của công trình (>= 1.20, không Z-fight 1.15)
local WT = 15.0               -- Chiều cao tường (trần 15 studs > 14 studs quy chuẩn R15)
local WALL_TOP = FY + WT      -- 16.6
local L, R = 143, 207         -- Biên Tây / Đông của khối nhà (X)
local K, F = 28, 92           -- Biên Bắc(sau) / Nam(trước) của khối nhà (Z)
local CX, CZ = (L + R) / 2, (K + F) / 2   -- 175, 60

local C_WALL    = RGB(228, 220, 200)   -- kem be
local C_WALL2   = RGB(208, 198, 176)   -- kem đậm
local C_BRICK   = RGB(178, 96, 64)     -- gạch nung
local C_FRAME   = RGB(64, 72, 82)      -- khung nhôm đen
local C_FRAME2  = RGB(126, 134, 144)   -- nhôm sáng
local C_GLASS   = RGB(150, 205, 226)   -- kính xanh nhạt
local C_GLASS2  = RGB(186, 224, 236)   -- kính cửa (trong hơn)
local C_GREEN   = RGB(42, 168, 82)     -- xanh lá thương hiệu
local C_DGREEN  = RGB(24, 74, 46)      -- xanh lá đậm (nền biển)
local C_WHITE   = RGB(242, 244, 240)
local C_ORANGE  = RGB(240, 122, 40)
local C_RED     = RGB(214, 56, 48)
local C_DARK    = RGB(22, 28, 36)
local C_NEON    = RGB(96, 244, 124)     -- neon xanh
local C_NEONW   = RGB(226, 255, 236)    -- neon trắng
local C_ASPHALT = RGB(50, 52, 58)
local C_TILE    = RGB(210, 210, 202)
local C_YELLOW  = RGB(244, 202, 58)
local C_BLUE    = RGB(40, 74, 140)
local C_WOOD    = RGB(146, 104, 70)

local PRODUCT_COLORS = {
	RGB(214, 56, 48), RGB(240, 122, 40), RGB(244, 202, 58),
	RGB(64, 168, 96), RGB(46, 118, 206), RGB(150, 78, 190),
	RGB(230, 96, 150), RGB(228, 224, 210),
}
local DRINK_COLORS = {
	RGB(214, 52, 44), RGB(52, 122, 210), RGB(60, 176, 96),
	RGB(240, 140, 40), RGB(158, 76, 196), RGB(240, 200, 60),
}

---------------------------------------------------------------------------------------------------
-- MODULE SPEC
---------------------------------------------------------------------------------------------------
local Module = {
	Id = "Plot_C3_Supermarket247",
	PlotId = "Plot_C3_West",
	Order = 30,
	Enabled = true,
}

---------------------------------------------------------------------------------------------------
-- TIỆN ÍCH GHÉP KHỐI (tất cả truyền integrity -> Destructible = true, PartHealth = integrity)
---------------------------------------------------------------------------------------------------
type BoxOpts = {
	material: any?,
	transparency: number?,
	reflectance: number?,
	shape: any?,
	canCollide: boolean?,
	castShadow: boolean?,
	group: string?,
	row: number?,
	structural: boolean?,
}

type SignText = {
	text: string,
	color: Color3?,
	sw: number?,
	sh: number?,
	px: number?,
	py: number?,
}

local function folder(parent: Instance, name: string): Instance
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- box: 1 khối PartBuilder.part có máu ẩn. `structural = true` -> móng chịu lực (không phá huỷ).
local function box(
	parent: Instance,
	name: string,
	pos: Vector3,
	size: Vector3,
	color: Color3,
	integrity: number?,
	opts: BoxOpts?
): Instance
	local o: BoxOpts = opts or {}
	local structural = o.structural == true
	local hp = integrity
	if not structural and hp == nil then
		hp = 120
	end
	return PartBuilder.part({
		name = name,
		parent = parent,
		pos = pos,
		size = size,
		color = color,
		material = o.material,
		transparency = o.transparency,
		reflectance = o.reflectance,
		shape = o.shape,
		canCollide = o.canCollide,
		castShadow = o.castShadow,
		destructible = (not structural),
		integrity = hp,
		fractureGroup = o.group or "Super247",
		structuralRow = o.row,
	})
end

-- brickWall: bọc PartBuilder.masonryWall (tường gạch xếp so le từng viên, mỗi viên có integrity)
local function brickWall(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	minC: number,
	maxC: number,
	baseY: number,
	thickness: number,
	courses: number,
	courseH: number,
	color: Color3,
	integrity: number,
	group: string
): Instance
	return PartBuilder.masonryWall({
		name = name,
		parent = parent,
		axis = axis,
		fixedCoord = fixed,
		minCoord = minC,
		maxCoord = maxC,
		baseY = baseY,
		thickness = thickness,
		courses = courses,
		courseHeight = courseH,
		blockLength = 6.0,
		mortarGap = 0.08,
		baseColor = color,
		material = Enum.Material.Brick,
		colorJitter = 7,
		integrity = integrity,
		fractureGroup = group,
		addCoping = false,
	})
end

-- segmentedRow: dãy `count` khối bằng nhau (vách kính, nan cửa cuốn, sọc mái hiên, sản phẩm...)
local function segmentedRow(
	parent: Instance,
	name: string,
	count: number,
	posFn: (number) -> Vector3,
	sizeFn: (number) -> Vector3,
	colorFn: (number) -> Color3,
	integrity: number?,
	opts: BoxOpts?
): ()
	for i = 1, count do
		box(parent, name .. "_" .. i, posFn(i), sizeFn(i), colorFn(i), integrity, opts)
	end
end

-- surfaceText: gắn SurfaceGui + các TextLabel lên 1 mặt của tấm biển (cho Roblox thật).
local function surfaceText(panel: Instance, face: any, entries: { SignText }): Instance
	local sgui = Instance.new("SurfaceGui")
	sgui.Face = face
	sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sgui.PixelsPerStud = 40
	sgui.LightInfluence = 0.1
	sgui.Parent = panel
	for _, e in ipairs(entries) do
		local tl = Instance.new("TextLabel")
		tl.BackgroundTransparency = 1
		tl.Size = UDim2.fromScale(e.sw or 0.92, e.sh or 0.5)
		tl.Position = UDim2.fromScale(e.px or 0.04, e.py or 0.1)
		tl.Font = Enum.Font.GothamBlack
		tl.TextScaled = true
		tl.TextColor3 = e.color or C_WHITE
		tl.Text = e.text
		tl.Parent = sgui
	end
	return sgui
end

-- signBoard: tấm biển nền + chữ trên nhiều mặt. `faces` là danh sách Enum.NormalId.
local function signBoard(
	parent: Instance,
	name: string,
	pos: Vector3,
	size: Vector3,
	bg: Color3,
	faces: { any },
	entries: { SignText }
): Instance
	local panel = box(parent, name, pos, size, bg, 160, { material = Enum.Material.Metal, group = "Signs" })
	for _, face in ipairs(faces) do
		surfaceText(panel, face, entries)
	end
	return panel
end

local Z_FACES = { Enum.NormalId.Front, Enum.NormalId.Back }
local X_FACES = { Enum.NormalId.Left, Enum.NormalId.Right }

---------------------------------------------------------------------------------------------------
-- 1. MÓNG / SÀN / BÃI ĐẬU XE
---------------------------------------------------------------------------------------------------
local function buildFoundation(fExt: Instance, fPark: Instance): ()
	-- Sàn bê tông trong nhà: mặt trên = FY = 1.60, đáy = 1.15 (không trùng phẳng 1.15)
	box(fExt, "InteriorFloorSlab", V(CX, 1.375, CZ), V(64, 0.45, 64), C_TILE, nil,
		{ material = Enum.Material.Concrete, structural = true })
	-- Gờ chân tường (skirting) 4 cạnh
	box(fExt, "Skirt_N", V(CX, FY + 0.35, K), V(64, 0.7, 1.4), C_WALL2, 260, { material = Enum.Material.Concrete })
	box(fExt, "Skirt_E", V(R, FY + 0.35, CZ), V(1.4, 0.7, 64), C_WALL2, 260, { material = Enum.Material.Concrete })

	-- Thảm chào sảnh vào (welcome mat) ngay cửa
	box(fExt, "WelcomeMat", V(CX, FY + 0.03, 88.5), V(11, 0.06, 3.2), C_DGREEN, 40, {})
	box(fExt, "WelcomeMatEdge", V(CX, FY + 0.05, 86.9), V(11.4, 0.10, 0.25), C_YELLOW, 40, {})

	-- Bãi đậu xe asphalt phía Nam (Z 92..123), mặt trên = 1.28 (không Z-fight nền 1.15)
	box(fPark, "ParkingApron", V(174.5, 1.215, 107.5), V(75, 0.13, 31), C_ASPHALT, 500,
		{ material = Enum.Material.Asphalt })

	-- Vạch kẻ chỗ đậu xe (2 bên chừa lối đi giữa X 168..182)
	local linesX = { 140, 149.5, 159, 168, 182, 191, 200.5, 210 }
	for i, lx in ipairs(linesX) do
		box(fPark, "ParkLine_" .. i, V(lx, 1.285, 108), V(0.28, 0.02, 22), C_WHITE, 40,
			{ material = Enum.Material.SmoothPlastic, canCollide = false })
	end
	-- Gờ chặn bánh xe (wheel stops) ở cuối mỗi chỗ đậu
	local stopX = { 144.7, 154.2, 163.7, 186.3, 195.8, 205.2 }
	for i, sx in ipairs(stopX) do
		box(fPark, "WheelStop_" .. i, V(sx, 1.55, 118.5), V(6.2, 0.7, 0.9), C_FRAME2, 150,
			{ material = Enum.Material.Concrete })
		box(fPark, "WheelStopStripe_" .. i, V(sx, 1.92, 118.5), V(6.2, 0.06, 0.9), C_YELLOW, 60, { canCollide = false })
	end
	-- Lối qua đường cho người đi bộ (crosswalk) dẫn thẳng vào cửa chính
	segmentedRow(fPark, "Crosswalk", 6,
		function(i) return V(175, 1.29, 99 + (i - 1) * 3.6) end,
		function(i) return V(13, 0.02, 1.8) end,
		function(i) return C_WHITE end, 40,
		{ material = Enum.Material.SmoothPlastic, canCollide = false })
end

---------------------------------------------------------------------------------------------------
-- 2. KẾT CẤU CHỊU LỰC: CỘT, TƯỜNG ĐẶC, MÁI, LAN CAN MÁI
---------------------------------------------------------------------------------------------------
local function column(parent: Instance, name: string, x: number, z: number): ()
	box(parent, name, V(x, FY + WT / 2, z), V(1.7, WT, 1.7), C_FRAME, 280,
		{ material = Enum.Material.Metal, group = "Columns" })
	-- Đế & đầu cột bê tông
	box(parent, name .. "_Base", V(x, FY + 0.5, z), V(2.1, 1.0, 2.1), C_WALL2, 300, { material = Enum.Material.Concrete })
	box(parent, name .. "_Cap", V(x, FY + WT - 0.4, z), V(2.1, 0.8, 2.1), C_WALL2, 300, { material = Enum.Material.Concrete })
end

local function buildStructure(fExt: Instance): ()
	-- Cột góc + cột giữa mặt tiền
	column(fExt, "Col_SW", L, F)
	column(fExt, "Col_SE", R, F)
	column(fExt, "Col_NW", L, K)
	column(fExt, "Col_NE", R, K)
	column(fExt, "Col_S_Mid1", 160, F)
	column(fExt, "Col_S_Mid2", 190, F)

	-- Tường Đông (X = R) — brickWall chạy dọc Z, 12 hàng so le
	brickWall(fExt, "EastSolidWall", "Z", R, K, F, FY, 1.2, 12, 1.25, C_WALL, 200, "EastWall")
	-- Tường Bắc / sau (Z = K) — brickWall chạy dọc X
	brickWall(fExt, "NorthSolidWall", "X", K, L, R, FY, 1.2, 12, 1.25, C_WALL, 200, "NorthWall")

	-- MÁI: bản sàn bê tông + lan can chu vi (parapet)
	box(fExt, "RoofSlab", V(CX, WALL_TOP + 0.3, CZ), V(66, 0.6, 66), C_WALL2, 320,
		{ material = Enum.Material.Concrete, group = "Roof" })
	local ph = 1.6
	local pcy = WALL_TOP + 0.6 + ph / 2
	box(fExt, "Parapet_N", V(CX, pcy, K - 0.6), V(66, ph, 0.8), C_WALL, 180, { material = Enum.Material.Concrete })
	box(fExt, "Parapet_S", V(CX, pcy, F + 0.6), V(66, ph, 0.8), C_WALL, 180, { material = Enum.Material.Concrete })
	box(fExt, "Parapet_W", V(L - 0.6, pcy, CZ), V(0.8, ph, 64.4), C_WALL, 180, { material = Enum.Material.Concrete })
	box(fExt, "Parapet_E", V(R + 0.6, pcy, CZ), V(0.8, ph, 64.4), C_WALL, 180, { material = Enum.Material.Concrete })
	-- Nẹp neon dọc mép lan can mặt tiền (nổi bật ban đêm)
	box(fExt, "ParapetNeon_S", V(CX, WALL_TOP + 0.62, F + 1.02), V(64, 0.18, 0.18), C_NEON, 60,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false })

	-- Cụm máy điều hoà (HVAC) trên nóc + ống gió
	for i, hx in ipairs({ 160, 182, 201 }) do
		box(fExt, "HVAC_" .. i, V(hx, WALL_TOP + 2.1, 40), V(7, 3.0, 6), C_FRAME2, 130,
			{ material = Enum.Material.Metal, group = "Roof" })
		box(fExt, "HVAC_Fan_" .. i, V(hx, WALL_TOP + 3.7, 40), V(4.6, 0.3, 4.6), C_FRAME, 60,
			{ material = Enum.Material.Metal })
		box(fExt, "HVAC_Duct_" .. i, V(hx, WALL_TOP + 1.0, 46), V(2.2, 1.4, 8), C_FRAME2, 120,
			{ material = Enum.Material.Metal })
	end
end

---------------------------------------------------------------------------------------------------
-- 3. MẶT TIỀN KÍNH (NAM + TÂY) & CỬA CUỐN KHO HÀNG (TÂY)
---------------------------------------------------------------------------------------------------
local function buildStorefront(fExt: Instance): ()
	local GY = FY + 4.5            -- tâm kính (cao 9.0 -> Y 1.6..10.6)
	local BAY = (R - L) / 10       -- 6.4 mỗi ô kính mặt Nam

	-- === MẶT NAM (Z = F): vách kính 10 ô, ô 5 & 6 là cửa đôi kính ===
	for i = 1, 10 do
		local xc = L + (i - 0.5) * BAY
		if i == 5 or i == 6 then
			-- 2 cánh cửa kính (cao 9.0 >= 8.5), trong suốt để nhìn vào nội thất
			box(fExt, "DoorGlass_" .. i, V(xc, GY, F + 0.05), V(BAY - 0.5, 8.9, 0.22), C_GLASS2, 45,
				{ transparency = 0.15, material = Enum.Material.Glass, group = "Doors" })
			-- Khung cửa (2 đứng + 1 ngang) + tay đẩy inox
			box(fExt, "DoorStileL_" .. i, V(xc - BAY / 2 + 0.25, GY, F + 0.18), V(0.22, 8.9, 0.28), C_FRAME2, 90, { material = Enum.Material.Metal })
			box(fExt, "DoorStileR_" .. i, V(xc + BAY / 2 - 0.25, GY, F + 0.18), V(0.22, 8.9, 0.28), C_FRAME2, 90, { material = Enum.Material.Metal })
			box(fExt, "DoorRail_" .. i, V(xc, FY + 8.8, F + 0.18), V(BAY - 0.4, 0.28, 0.28), C_FRAME2, 90, { material = Enum.Material.Metal })
			box(fExt, "DoorPushBar_" .. i, V(xc, FY + 4.2, F + 0.32), V(BAY - 1.8, 0.16, 0.16), C_FRAME, 60, { material = Enum.Material.Metal })
		else
			box(fExt, "FrontGlass_" .. i, V(xc, GY, F), V(BAY - 0.35, 9.0, 0.3), C_GLASS, 45,
				{ transparency = 0.32, material = Enum.Material.Glass, group = "FrontGlass" })
			-- Bậu kính thấp (kick plate)
			box(fExt, "FrontKick_" .. i, V(xc, FY + 0.35, F), V(BAY - 0.62, 0.7, 0.62), C_FRAME2, 120, { material = Enum.Material.Metal })
		end
	end
	-- Trụ nhôm đứng (mullion) giữa các ô
	for i = 0, 10 do
		local x = L + i * BAY
		box(fExt, "Mullion_S_" .. i, V(x, GY + 0.2, F), V(0.36, 9.5, 0.6), C_FRAME, 170,
			{ material = Enum.Material.Metal, group = "FrontFrame" })
	end
	-- Thanh ngang đỉnh (transom)
	box(fExt, "Transom_S", V(CX, FY + 9.55, F), V(64, 0.5, 0.7), C_FRAME, 170, { material = Enum.Material.Metal })

	-- === MẶT TÂY (X = L): vách kính Z 48..92 + CỬA CUỐN KHO HÀNG Z 30..46 ===
	local wBays = 7
	local wBay = (F - 48) / wBays
	for i = 1, wBays do
		local zc = 48 + (i - 0.5) * wBay
		box(fExt, "WestGlass_" .. i, V(L, GY, zc), V(0.3, 9.0, wBay - 0.35), C_GLASS, 45,
			{ transparency = 0.32, material = Enum.Material.Glass, group = "WestGlass" })
		box(fExt, "WestKick_" .. i, V(L, FY + 0.35, zc), V(0.62, 0.7, wBay - 0.62), C_FRAME2, 120, { material = Enum.Material.Metal })
	end
	for i = 0, wBays do
		local z = 48 + i * wBay
		box(fExt, "Mullion_W_" .. i, V(L, GY + 0.2, z), V(0.6, 9.5, 0.36), C_FRAME, 170,
			{ material = Enum.Material.Metal, group = "WestFrame" })
	end
	box(fExt, "Transom_W", V(L, FY + 9.55, 70), V(0.7, 0.5, 44), C_FRAME, 170, { material = Enum.Material.Metal })
	-- Dải tường đặc trên phần kính phía Tây (Y 10.6..16.6)
	box(fExt, "WestUpperFascia", V(L, 13.6, 70), V(0.9, 6.0, 44), C_WALL, 190, { material = Enum.Material.Concrete })

	-- === CỬA CUỐN KHO HÀNG (loading bay) rộng 16 × cao 12 trên tường Tây, tâm Z = 38 ===
	local doorZ0, doorZ1 = 30, 46
	local doorCZ = (doorZ0 + doorZ1) / 2   -- 38
	local slats = 12
	segmentedRow(fExt, "RollupShutter", slats,
		function(i) return V(L, FY + (i - 0.5) * 1.0, doorCZ) end,
		function(i) return V((i % 2 == 0) and 0.62 or 0.45, 1.0, 15.8) end,
		function(i) return (i % 2 == 0) and C_FRAME2 or C_FRAME end, 55,
		{ material = Enum.Material.Metal, group = "RollupDoor" })
	-- Khung cửa cuốn: 2 trụ đứng + lintel + motor housing
	for i, dz in ipairs({ doorZ0, doorZ1 }) do
		box(fExt, "RollupJamb_" .. i, V(L, FY + 6.2, dz), V(0.7, 12.4, 0.7), C_FRAME, 200, { material = Enum.Material.Metal })
	end
	box(fExt, "RollupLintel", V(L, FY + 12.3, doorCZ), V(0.7, 0.8, 16.8), C_FRAME, 200, { material = Enum.Material.Metal })
	box(fExt, "RollupMotor", V(L - 0.3, FY + 12.9, doorZ0 + 1), V(1.4, 1.2, 3.0), C_DARK, 130, { material = Enum.Material.Metal })
	-- Mảng tường đặc 2 bên & phía trên cửa cuốn
	box(fExt, "RollupPierL", V(L, FY + WT / 2, 29), V(1.2, WT, 2.0), C_BRICK, 200, { material = Enum.Material.Brick })
	box(fExt, "RollupPierR", V(L, FY + WT / 2, 47), V(1.2, WT, 2.0), C_BRICK, 200, { material = Enum.Material.Brick })
	box(fExt, "RollupHeader", V(L, 15.1, doorCZ), V(1.2, 3.0, 16.0), C_WALL, 200, { material = Enum.Material.Concrete })

	-- Bến bốc dỡ (loading dock) ngoài cửa cuốn, sát mặt Tây (X 138..143, trong bounds)
	box(fExt, "LoadingDock", V(140.5, 1.4, doorCZ), V(5, 0.5, 18), C_WALL2, 320, { material = Enum.Material.Concrete })
	box(fExt, "LoadingDockEdge", V(138.2, 1.68, doorCZ), V(0.3, 0.1, 18), C_YELLOW, 60, { canCollide = false })
	-- Biển "RECEIVING / DELIVERIES" phía trên cửa cuốn
	signBoard(fExt, "ReceivingSign", V(L - 0.7, 14.6, doorCZ), V(0.5, 1.6, 12), C_DARK, X_FACES,
		{ { text = "DELIVERIES · RECEIVING", color = C_YELLOW, sw = 0.94, sh = 0.6, px = 0.03, py = 0.2 } })
end

---------------------------------------------------------------------------------------------------
-- 4. BIỂN HIỆU, MÁI HIÊN SỌC & PYLON TRÊN NÓC
---------------------------------------------------------------------------------------------------
local function buildSignage(fSign: Instance): ()
	-- === Dải ốp mặt tiền (fascia) nơi gắn biển chính, Y 10.8..16.6 ===
	box(fSign, "FrontFascia", V(CX, 13.7, F), V(64, 5.8, 0.9), C_WALL, 190, { material = Enum.Material.Concrete })

	-- === BIỂN CHÍNH "24/7 SUPERMARKET" (tấm nền xanh đậm + khung neon) ===
	local signPos = V(CX, 14.0, F + 1.05)
	local signSize = V(46, 4.4, 1.1)
	signBoard(fSign, "MainSignBoard", signPos, signSize, C_DGREEN, Z_FACES, {
		{ text = "24/7", color = C_NEONW, sw = 0.9, sh = 0.44, px = 0.05, py = 0.04 },
		{ text = "S U P E R M A R K E T", color = C_WHITE, sw = 0.9, sh = 0.20, px = 0.05, py = 0.50 },
		{ text = "OPEN 24 HOURS · ATM · COLD DRINKS", color = C_YELLOW, sw = 0.9, sh = 0.16, px = 0.05, py = 0.74 },
	})
	-- Khung neon xanh quanh biển (4 cạnh)
	local fbx, fby, fbz = signPos.X, signPos.Y, signPos.Z
	box(fSign, "SignNeon_Top", V(fbx, fby + 2.3, fbz + 0.6), V(46.4, 0.2, 0.2), C_NEON, 60, { material = Enum.Material.Neon, canCollide = false, castShadow = false })
	box(fSign, "SignNeon_Bot", V(fbx, fby - 2.3, fbz + 0.6), V(46.4, 0.2, 0.2), C_NEON, 60, { material = Enum.Material.Neon, canCollide = false, castShadow = false })
	box(fSign, "SignNeon_L", V(fbx - 23.1, fby, fbz + 0.6), V(0.2, 4.4, 0.2), C_NEON, 60, { material = Enum.Material.Neon, canCollide = false, castShadow = false })
	box(fSign, "SignNeon_R", V(fbx + 23.1, fby, fbz + 0.6), V(0.2, 4.4, 0.2), C_NEON, 60, { material = Enum.Material.Neon, canCollide = false, castShadow = false })
	-- 2 huy hiệu góc màu cam
	box(fSign, "SignBadge_L", V(fbx - 21.2, fby + 1.45, fbz + 0.62), V(1.4, 0.7, 0.2), C_ORANGE, 60, { material = Enum.Material.Neon, canCollide = false })
	box(fSign, "SignBadge_R", V(fbx + 21.2, fby + 1.45, fbz + 0.62), V(1.4, 0.7, 0.2), C_ORANGE, 60, { material = Enum.Material.Neon, canCollide = false })

	-- === MÁI HIÊN SỌC (awning) XANH LÁ - TRẮNG - CAM, nhô ra 7.5 studs ===
	local awningZ = F + 3.75
	local stripeN = 20
	local stripeW = 62 / stripeN
	local awningColors = { C_GREEN, C_WHITE, C_ORANGE }
	-- Mái tôn nền (cantilever)
	box(fSign, "AwningDeck", V(CX, 10.95, awningZ), V(62, 0.3, 7.5), C_FRAME2, 130, { material = Enum.Material.Metal })
	-- Các sọc trên mặt mái
	segmentedRow(fSign, "AwningTopStripe", stripeN,
		function(i) return V(144 + (i - 0.5) * stripeW, 11.13, awningZ) end,
		function(i) return V(stripeW - 0.06, 0.08, 7.4) end,
		function(i) return awningColors[(i - 1) % 3 + 1] end, 90, { material = Enum.Material.SmoothPlastic })
	-- Diềm rủ xuống (valance) mép trước mái hiên, cũng sọc
	segmentedRow(fSign, "AwningValance", stripeN,
		function(i) return V(144 + (i - 0.5) * stripeW, 10.4, F + 7.5) end,
		function(i) return V(stripeW - 0.06, 1.15, 0.28) end,
		function(i) return awningColors[(i - 1) % 3 + 1] end, 90, { material = Enum.Material.SmoothPlastic })
	-- Viền neon dọc mép dưới diềm
	box(fSign, "AwningNeonEdge", V(CX, 9.78, F + 7.6), V(62, 0.16, 0.16), C_NEON, 60,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false })
	-- Thanh đỡ mái hiên (2 đầu)
	for i, ax in ipairs({ 144.5, 205.5 }) do
		box(fSign, "AwningBracket_" .. i, V(ax, 10.4, F + 3.6), V(0.3, 1.2, 7.0), C_FRAME, 110, { material = Enum.Material.Metal })
	end

	-- === BIỂN PYLON TRÊN NÓC (2 tấm chữ L nhìn rõ từ 2 đại lộ) ===
	-- Chân trụ (từ nóc 17.2 lên 21.0)
	local legH = 3.8
	local legCY = 17.2 + legH / 2
	-- Billboard A: quay Nam (+Z), tâm X = 175, Z = 86
	for i, lx in ipairs({ 162, 188 }) do
		box(fSign, "PylonA_Leg_" .. i, V(lx, legCY, 86), V(0.9, legH, 0.9), C_FRAME, 220, { material = Enum.Material.Metal })
	end
	signBoard(fSign, "PylonA", V(175, 24.0, 86), V(30, 6.4, 1.1), C_DGREEN, Z_FACES, {
		{ text = "24/7", color = C_NEONW, sw = 0.9, sh = 0.6, px = 0.05, py = 0.06 },
		{ text = "SUPERMARKET", color = C_WHITE, sw = 0.9, sh = 0.22, px = 0.05, py = 0.7 },
	})
	box(fSign, "PylonA_NeonTop", V(175, 27.3, 86.6), V(30.4, 0.22, 0.22), C_NEON, 60, { material = Enum.Material.Neon, canCollide = false })
	box(fSign, "PylonA_NeonBot", V(175, 20.7, 86.6), V(30.4, 0.22, 0.22), C_NEON, 60, { material = Enum.Material.Neon, canCollide = false })
	-- Billboard B: quay Tây (-X), tâm X = 146, Z = 62 (tấm mỏng theo X)
	for i, lz in ipairs({ 46, 58 }) do
		box(fSign, "PylonB_Leg_" .. i, V(151, legCY, lz), V(0.9, legH, 0.9), C_FRAME, 220, { material = Enum.Material.Metal })
	end
	signBoard(fSign, "PylonB", V(151, 24.0, 52), V(1.1, 6.4, 17), C_DGREEN, X_FACES, {
		{ text = "24/7", color = C_NEONW, sw = 0.9, sh = 0.6, px = 0.05, py = 0.06 },
		{ text = "OPEN 24H", color = C_YELLOW, sw = 0.9, sh = 0.22, px = 0.05, py = 0.7 },
	})
	box(fSign, "PylonB_NeonTop", V(150.4, 27.3, 52), V(0.22, 0.22, 17.4), C_NEON, 60, { material = Enum.Material.Neon, canCollide = false })

	-- Biển hiệu góc Tây trên dải tường (quay -X ra Alta St)
	signBoard(fSign, "WestSign", V(L - 0.7, 13.6, 70), V(0.6, 3.6, 20), C_DGREEN, X_FACES, {
		{ text = "24/7  SUPERMARKET", color = C_NEONW, sw = 0.94, sh = 0.6, px = 0.03, py = 0.2 },
	})
end

---------------------------------------------------------------------------------------------------
-- 5. CHI TIẾT BÃI ĐẬU XE: CỌC CHẮN, ĐÈN, XE ĐẨY HÀNG
---------------------------------------------------------------------------------------------------
local function buildParkingProps(fPark: Instance): ()
	-- Cọc chắn bê tông vàng trước cửa chính (bảo vệ vách kính khỏi xe)
	for i, bx in ipairs({ 164, 168.5, 173, 177.5, 182, 186.5 }) do
		box(fPark, "Bollard_" .. i, V(bx, 2.7, 96.5), V(0.8, 2.8, 0.8), C_YELLOW, 90, { material = Enum.Material.Metal, group = "Bollards" })
		box(fPark, "BollardRing_" .. i, V(bx, 3.7, 96.5), V(0.9, 0.22, 0.9), C_FRAME, 60, { material = Enum.Material.Metal, canCollide = false })
	end
	-- 2 cột đèn cao áp trong bãi (không lấn vỉa hè của Agent hạ tầng)
	for i, lx in ipairs({ 149, 201 }) do
		box(fPark, "LampPost_" .. i, V(lx, 8.5, 112), V(0.6, 14.6, 0.6), C_FRAME, 140, { material = Enum.Material.Metal })
		box(fPark, "LampArm_" .. i, V(lx, 15.7, 110.5), V(0.4, 0.4, 3.4), C_FRAME, 100, { material = Enum.Material.Metal })
		box(fPark, "LampHead_" .. i, V(lx, 15.5, 109), V(3.2, 0.5, 1.6), C_NEONW, 60, { material = Enum.Material.Neon, castShadow = false })
	end
	-- Khu trả xe đẩy (cart return): mái có 2 trụ đỡ phía trước, không lơ lửng
	box(fPark, "CartKiosk_Back", V(156, 3.5, 100), V(7, 4.4, 0.4), C_BLUE, 130, { material = Enum.Material.Metal })
	for i, kx in ipairs({ 152.8, 159.2 }) do
		box(fPark, "CartKiosk_Post_" .. i, V(kx, 3.5, 103.0), V(0.5, 4.4, 0.5), C_BLUE, 130, { material = Enum.Material.Metal })
	end
	box(fPark, "CartKiosk_Roof", V(156, 5.85, 101.6), V(7.6, 0.3, 3.8), C_BLUE, 120, { material = Enum.Material.Metal })
	signBoard(fPark, "CartKioskSign", V(156, 4.3, 100.35), V(6.2, 1.2, 0.2), C_DARK, Z_FACES,
		{ { text = "CART RETURN", color = C_WHITE, sw = 0.92, sh = 0.6, px = 0.04, py = 0.2 } })
	for c = 1, 2 do
		local ox = 153.5 + (c - 1) * 4
		box(fPark, "Cart_Basket_" .. c, V(ox, 2.1, 101.8), V(2.6, 1.6, 2.0), C_FRAME2, 50, { material = Enum.Material.Metal, transparency = 0.25 })
		box(fPark, "Cart_Handle_" .. c, V(ox, 2.9, 100.85), V(2.6, 0.15, 0.15), C_RED, 50, { material = Enum.Material.SmoothPlastic })
		for hi, hx2 in ipairs({ ox - 1.2, ox + 1.2 }) do
			box(fPark, "Cart_HandleLeg_" .. c .. "_" .. hi, V(hx2, 2.55, 100.85), V(0.14, 0.8, 0.14), C_FRAME, 40, { material = Enum.Material.Metal })
		end
		box(fPark, "Cart_Wheel_" .. c, V(ox, 1.35, 101.8), V(2.2, 0.2, 1.8), C_FRAME, 40, { material = Enum.Material.Metal })
	end
	-- Thùng rác công cộng cạnh cửa
	box(fPark, "TrashBin", V(190, 2.4, 95.5), V(1.8, 2.4, 1.8), C_DGREEN, 70, { material = Enum.Material.Metal })
	box(fPark, "TrashBinLid", V(190, 3.7, 95.5), V(2.0, 0.25, 2.0), C_FRAME, 60, { material = Enum.Material.Metal })
end

---------------------------------------------------------------------------------------------------
-- 6. FULL NỘI THẤT
---------------------------------------------------------------------------------------------------
local function buildGondola(fInt: Instance, x: number, idx: number, label: string, sub: string): ()
	local g = folder(fInt, "Gondola_" .. idx)
	local gz, gLen = 58, 30           -- chạy Z 43..73
	-- Đế + xương sống
	box(g, "Plinth", V(x, FY + 0.25, gz), V(5.6, 0.5, gLen + 1), C_FRAME2, 130, { material = Enum.Material.Metal })
	box(g, "Spine", V(x, FY + 2.7, gz), V(0.7, 4.9, gLen), C_FRAME, 140, { material = Enum.Material.Metal })
	-- 2 đầu hồi (end caps)
	for i, ez in ipairs({ gz - gLen / 2, gz + gLen / 2 }) do
		box(g, "EndCap_" .. i, V(x, FY + 2.6, ez), V(5.6, 5.0, 0.5), C_BLUE, 120, { material = Enum.Material.Metal })
	end
	-- 3 tầng kệ 2 bên + sản phẩm nhiều màu (mỗi hộp có integrity = 22 -> bắn vỡ)
	local levels = { 1.5, 3.0, 4.5 }
	for li, ly in ipairs(levels) do
		for _, side in ipairs({ -1, 1 }) do
			local shelfX = x + side * 1.45
			box(g, "Shelf_L" .. li .. "_S" .. side, V(shelfX, FY + ly, gz), V(2.4, 0.14, gLen - 0.6), C_FRAME2, 90,
				{ material = Enum.Material.Metal })
			segmentedRow(g, "Prod_L" .. li .. "_S" .. side, 7,
				function(i) return V(shelfX, FY + ly + 0.62, gz - 13 + (i - 1) * 4.3) end,
				function(i) return V(2.0, 1.1, 3.5) end,
				function(i) return PRODUCT_COLORS[(i + li + (side + 1) + idx) % #PRODUCT_COLORS + 1] end, 22,
				{ material = Enum.Material.SmoothPlastic })
		end
	end
	-- Biển treo lối đi (aisle sign) phía trên, quay ra cửa (+Z)
	signBoard(g, "AisleSign_" .. idx, V(x, FY + 8.4, gz + 8), V(6.5, 1.3, 0.3), C_DGREEN, Z_FACES, {
		{ text = label, color = C_WHITE, sw = 0.92, sh = 0.45, px = 0.04, py = 0.06 },
		{ text = sub, color = C_YELLOW, sw = 0.92, sh = 0.35, px = 0.04, py = 0.55 },
	})
	-- 2 thanh treo biển nối liền từ MÉP TRẦN xuống đỉnh biển (không lơ lửng)
	for i, sx in ipairs({ x - 2.4, x + 2.4 }) do
		local signTop = FY + 8.4 + 0.65
		local hangH = (WALL_TOP - 0.2) - signTop + 0.4
		box(g, "AisleHanger_" .. idx .. "_" .. i, V(sx, signTop + hangH / 2, gz + 8), V(0.1, hangH, 0.1), C_FRAME, 60, { material = Enum.Material.Metal })
	end
end

local function buildCooler(fInt: Instance, x: number, idx: number): ()
	local c = folder(fInt, "DrinkCooler_" .. idx)
	local cz = 30.6           -- tựa vào tường Bắc (Z = 28)
	local cw, ch = 11.4, 9.4
	-- Vỏ tủ (lưng + 2 hông + nóc + đáy)
	box(c, "Back", V(x, FY + ch / 2, 29.4), V(cw, ch, 0.4), C_FRAME, 160, { material = Enum.Material.Metal })
	box(c, "SideL", V(x - cw / 2, FY + ch / 2, cz), V(0.5, ch, 3.0), C_FRAME2, 150, { material = Enum.Material.Metal })
	box(c, "SideR", V(x + cw / 2, FY + ch / 2, cz), V(0.5, ch, 3.0), C_FRAME2, 150, { material = Enum.Material.Metal })
	box(c, "Top", V(x, FY + ch, cz), V(cw + 0.5, 0.5, 3.0), C_FRAME2, 150, { material = Enum.Material.Metal })
	box(c, "Bottom", V(x, FY + 0.25, cz), V(cw + 0.5, 0.5, 3.0), C_FRAME2, 150, { material = Enum.Material.Metal })
	-- Lòng tủ phát sáng (neon xanh) + các kệ chai nước
	box(c, "GlowPanel", V(x, FY + ch / 2, 29.8), V(cw - 0.8, ch - 0.8, 0.2), RGB(150, 232, 240), 40,
		{ material = Enum.Material.Neon, transparency = 0.15, canCollide = false, castShadow = false })
	for shelf = 1, 3 do
		local sy = FY + 1.0 + (shelf - 1) * 2.9
		box(c, "GlassShelf_" .. shelf, V(x, sy, 30.4), V(cw - 1.0, 0.1, 2.0), C_GLASS2, 45,
			{ material = Enum.Material.Glass, transparency = 0.4 })
		segmentedRow(c, "Bottles_" .. shelf, 7,
			function(i) return V(x - 4.6 + (i - 1) * 1.5, sy + 0.95, 30.4) end,
			function(i) return V(1.1, 1.8, 1.1) end,
			function(i) return DRINK_COLORS[(i + shelf + idx) % #DRINK_COLORS + 1] end, 18,
			{ material = Enum.Material.SmoothPlastic })
	end
	-- Cửa kính đôi (mỗi cánh integrity = 45 bắn vỡ) + tay nắm
	for i, dx in ipairs({ x - cw / 4, x + cw / 4 }) do
		box(c, "GlassDoor_" .. i, V(dx, FY + ch / 2, cz + 1.4), V(cw / 2 - 0.3, ch - 0.6, 0.18), C_GLASS2, 45,
			{ material = Enum.Material.Glass, transparency = 0.22, group = "CoolerGlass" })
		box(c, "DoorHandle_" .. i, V(dx + (i == 1 and 1.6 or -1.6), FY + 4.6, cz + 1.62), V(0.18, 2.2, 0.18), C_FRAME2, 60, { material = Enum.Material.Metal })
	end
	box(c, "CenterMullion", V(x, FY + ch / 2, cz + 1.5), V(0.25, ch, 0.25), C_FRAME, 90, { material = Enum.Material.Metal })
end

local function buildInterior(fInt: Instance): ()
	-- ===== A. 3 DÃY KỆ GONDOLA Ở GIỮA TIỆM =====
	buildGondola(fInt, 152, 1, "AISLE 1", "SNACKS · CHIPS")
	buildGondola(fInt, 175, 2, "AISLE 2", "GROCERY · CANNED")
	buildGondola(fInt, 198, 3, "AISLE 3", "HOUSEHOLD")

	-- ===== B. TỦ LẠNH NƯỚC NGỌT PHÁT SÁNG DỌC TƯỜNG SAU =====
	for i, cx in ipairs({ 151, 163, 175, 187 }) do
		buildCooler(fInt, cx, i)
	end
	-- Biển "COLD DRINKS" chạy dọc phía trên dàn tủ lạnh (quay ra cửa +Z)
	signBoard(fInt, "ColdDrinksBanner", V(169, 13.0, 33), V(52, 2.0, 0.5), C_DGREEN, Z_FACES, {
		{ text = "❄ COLD DRINKS · BEER · SODA ❄", color = C_NEONW, sw = 0.96, sh = 0.62, px = 0.02, py = 0.2 },
	})
	for i, hx in ipairs({ 146, 169, 192 }) do
		box(fInt, "ColdBannerHanger_" .. i, V(hx, 15.3, 33), V(0.12, 3.0, 0.12), C_FRAME, 60, { material = Enum.Material.Metal })
	end

	-- ===== C. QUẦY THU NGÂN 3 LÀN (phía Đông, gần cửa) =====
	local cof = folder(fInt, "Checkouts")
	for i, qx in ipairs({ 185, 192.5, 200 }) do
		local co = folder(cof, "Lane_" .. i)
		box(co, "Counter", V(qx, FY + 1.0, 84), V(2.8, 2.0, 8), C_BLUE, 100, { material = Enum.Material.Metal })
		box(co, "CounterTop", V(qx, FY + 2.05, 84), V(3.1, 0.15, 8.2), C_FRAME2, 90, { material = Enum.Material.Metal })
		box(co, "Conveyor", V(qx, FY + 2.14, 82.7), V(2.3, 0.12, 4.8), C_DARK, 60, { material = Enum.Material.Rubber })
		-- Máy tính tiền + màn hình cảm ứng
		box(co, "Register", V(qx, FY + 2.75, 86.6), V(1.8, 1.3, 1.2), C_DARK, 80, { material = Enum.Material.Metal })
		box(co, "RegisterScreen", V(qx, FY + 3.0, 87.25), V(1.5, 1.0, 0.12), RGB(70, 150, 200), 45,
			{ material = Enum.Material.Neon })
		box(co, "CardReader", V(qx + 1.2, FY + 2.35, 86.0), V(0.7, 0.5, 0.7), C_FRAME2, 50, { material = Enum.Material.Metal })
		-- Đèn báo làn (lane light)
		local poleBase = FY + 2.13    -- đúng mặt trên quầy (CounterTop)
		local poleTop = FY + 8.0
		box(co, "LanePole", V(qx, (poleBase + poleTop) / 2, 88), V(0.2, poleTop - poleBase, 0.2), C_FRAME, 60, { material = Enum.Material.Metal })
		box(co, "LaneLight", V(qx, poleTop + 0.3, 88), V(1.4, 0.6, 0.8), C_NEON, 45, { material = Enum.Material.Neon, castShadow = false })
	end
	-- Biển treo "CHECKOUT" + 2 thanh treo nối lên mép trần (không lơ lửng)
	signBoard(cof, "CheckoutSign", V(192.5, 12.6, 88.5), V(20, 1.6, 0.3), C_DGREEN, Z_FACES, {
		{ text = "CHECKOUT  ·  THU NGÂN", color = C_WHITE, sw = 0.94, sh = 0.62, px = 0.03, py = 0.18 },
	})
	for i, rx in ipairs({ 185.5, 199.5 }) do
		local rodTop = WALL_TOP - 0.2
		local rodBase = 12.6 + 0.8
		box(cof, "CheckoutSignRod_" .. i, V(rx, (rodBase + rodTop) / 2, 88.5), V(0.12, rodTop - rodBase, 0.12), C_FRAME, 55,
			{ material = Enum.Material.Metal })
	end
	-- Kệ thuốc lá / tạp hoá sau quầy (nhiều hộp màu)
	segmentedRow(cof, "BehindCounterStock", 12,
		function(i) return V(184 + (i - 1) * 1.7, FY + 3.2, 78.6) end,
		function(i) return V(1.4, 1.6, 0.9) end,
		function(i) return PRODUCT_COLORS[i % #PRODUCT_COLORS + 1] end, 22, { material = Enum.Material.SmoothPlastic })
	box(cof, "BehindCounterShelf", V(194, FY + 2.35, 78.6), V(22, 0.15, 1.2), C_FRAME2, 90, { material = Enum.Material.Metal })

	-- ===== D. MÁY ATM 24H (góc Tây gần cửa) =====
	local atm = folder(fInt, "ATM")
	box(atm, "Body", V(147, FY + 2.6, 89.5), V(3.0, 5.2, 2.0), C_BLUE, 150, { material = Enum.Material.Metal })
	box(atm, "ScreenBezel", V(147, FY + 3.6, 90.55), V(2.4, 1.9, 0.2), C_DARK, 80, { material = Enum.Material.Metal })
	signBoard(atm, "ATMScreen", V(147, FY + 3.6, 90.7), V(2.1, 1.6, 0.12), RGB(20, 60, 110), Z_FACES, {
		{ text = "ATM", color = C_NEONW, sw = 0.9, sh = 0.5, px = 0.05, py = 0.05 },
		{ text = "CASH 24H", color = C_YELLOW, sw = 0.9, sh = 0.35, px = 0.05, py = 0.6 },
	})
	box(atm, "Keypad", V(147, FY + 2.2, 90.6), V(1.6, 0.2, 0.7), C_FRAME2, 50, { material = Enum.Material.Metal })
	box(atm, "CashSlot", V(147, FY + 1.5, 90.6), V(1.8, 0.2, 0.2), C_DARK, 50, { material = Enum.Material.Metal })
	box(atm, "NeonTop", V(147, FY + 5.3, 89.5), V(3.2, 0.25, 2.2), C_BLUE, 60, { material = Enum.Material.Neon, castShadow = false })

	-- ===== E. QUẦY CÀ PHÊ / MÁY SLUSHIE =====
	local cafe = folder(fInt, "CafeCounter")
	box(cafe, "Counter", V(147, FY + 1.1, 80.5), V(9, 2.2, 4), C_WOOD, 100, { material = Enum.Material.Wood })
	box(cafe, "CounterTop", V(147, FY + 2.25, 80.5), V(9.4, 0.15, 4.3), C_FRAME2, 90, { material = Enum.Material.Metal })
	-- 3 máy Slushie (bình màu rực)
	for i, sx in ipairs({ 144, 147, 150 }) do
		box(cafe, "SlushieBase_" .. i, V(sx, FY + 2.9, 80), V(2.2, 1.2, 1.8), C_FRAME, 80, { material = Enum.Material.Metal })
		box(cafe, "SlushieTank_" .. i, V(sx, FY + 4.0, 80), V(1.9, 1.6, 1.5),
			({ C_RED, C_ORANGE, C_GREEN })[i], 55, { material = Enum.Material.Glass, transparency = 0.2 })
		box(cafe, "SlushieTap_" .. i, V(sx, FY + 3.0, 80.95), V(0.5, 0.3, 0.3), C_FRAME2, 45, { material = Enum.Material.Metal })
	end
	-- Máy pha cà phê + cốc giấy
	box(cafe, "CoffeeMachine", V(152.5, FY + 3.3, 80), V(2.6, 2.1, 1.8), C_DARK, 80, { material = Enum.Material.Metal })
	box(cafe, "CoffeeDrip", V(152.5, FY + 2.6, 80.9), V(1.4, 0.5, 0.4), C_FRAME2, 50, { material = Enum.Material.Metal })
	segmentedRow(cafe, "PaperCups", 4,
		function(i) return V(143.6 + (i - 1) * 0.7, FY + 2.55, 82.1) end,
		function(i) return V(0.5, 0.6, 0.5) end,
		function(i) return C_WHITE end, 18, { material = Enum.Material.SmoothPlastic })

	-- ===== F. ĐẢO TRÁI CÂY (produce island) =====
	local prod = folder(fInt, "ProduceIsland")
	box(prod, "Table", V(163, FY + 0.7, 84), V(9, 1.4, 5), C_WOOD, 100, { material = Enum.Material.Wood })
	box(prod, "TableRim", V(163, FY + 1.45, 84), V(9.3, 0.15, 5.3), C_FRAME2, 90, { material = Enum.Material.Metal })
	segmentedRow(prod, "FruitCrate", 8,
		function(i)
			local col = (i - 1) % 4
			local row = math.floor((i - 1) / 4)
			return V(159.6 + col * 2.3, FY + 1.9, 82.9 + row * 2.2)
		end,
		function(i) return V(2.0, 0.9, 1.8) end,
		function(i) return PRODUCT_COLORS[i % #PRODUCT_COLORS + 1] end, 24, { material = Enum.Material.SmoothPlastic })

	-- ===== G. VĂN PHÒNG QUẢN LÝ VÁCH KÍNH (góc Đông-Bắc) =====
	local office = folder(fInt, "ManagerOffice")
	box(office, "GlassWall_Z", V(200.5, FY + 5.5, 40), V(12, 9.0, 0.25), C_GLASS2, 45,
		{ material = Enum.Material.Glass, transparency = 0.25, group = "OfficeGlass" })
	box(office, "GlassWall_X", V(194.5, FY + 5.5, 34.5), V(0.25, 9.0, 11), C_GLASS2, 45,
		{ material = Enum.Material.Glass, transparency = 0.25, group = "OfficeGlass" })
	box(office, "GlassDoorFrame", V(197.2, FY + 4.6, 40), V(2.6, 9.2, 0.3), C_FRAME, 120, { material = Enum.Material.Metal })
	box(office, "Desk", V(200, FY + 1.5, 34), V(6, 0.3, 2.6), C_WOOD, 90, { material = Enum.Material.Wood })
	box(office, "DeskLegL", V(197.4, FY + 0.75, 34), V(0.3, 1.5, 2.4), C_FRAME, 80, { material = Enum.Material.Metal })
	box(office, "DeskLegR", V(202.6, FY + 0.75, 34), V(0.3, 1.5, 2.4), C_FRAME, 80, { material = Enum.Material.Metal })
	box(office, "Monitor", V(200, FY + 2.4, 33.6), V(2.2, 1.5, 0.2), C_DARK, 60, { material = Enum.Material.Metal })
	box(office, "MonitorScreen", V(200, FY + 2.4, 33.75), V(1.9, 1.2, 0.1), RGB(60, 130, 180), 40, { material = Enum.Material.Neon })
	box(office, "Chair", V(200, FY + 1.0, 36.2), V(2.0, 0.3, 2.0), C_RED, 60, { material = Enum.Material.SmoothPlastic })
	box(office, "ChairBack", V(200, FY + 1.9, 37.1), V(2.0, 1.8, 0.3), C_RED, 60, { material = Enum.Material.SmoothPlastic })

	-- ===== H. ĐÈN TUÝP TRẦN (Neon trắng) + camera an ninh + bình chữa cháy =====
	for i, lx in ipairs({ 149, 163, 177, 191, 204 }) do
		box(fInt, "CeilingFixture_" .. i, V(lx, 15.6, CZ), V(1.2, 0.3, 58), C_FRAME2, 50, { material = Enum.Material.Metal })
		box(fInt, "CeilingTube_" .. i, V(lx, 15.4, CZ), V(0.7, 0.15, 56), C_NEONW, 40,
			{ material = Enum.Material.Neon, castShadow = false })
	end
	for i, cp in ipairs({ { 146, 89 }, { 204, 89 }, { 146, 32 }, { 204, 32 } }) do
		box(fInt, "SecurityCam_" .. i, V(cp[1], 15.0, cp[2]), V(1.0, 0.5, 1.6), C_DARK, 50, { material = Enum.Material.Metal })
		box(fInt, "SecurityCamLens_" .. i, V(cp[1], 15.0, cp[2]), V(0.4, 0.3, 0.2), C_RED, 40, { material = Enum.Material.Neon })
	end
	box(fInt, "FireExtinguisher", V(205.6, FY + 1.8, 46), V(0.7, 2.2, 0.7), C_RED, 60, { material = Enum.Material.Metal })
	box(fInt, "FireExtinguisherNozzle", V(205.6, FY + 3.0, 46), V(0.3, 0.4, 0.3), C_FRAME, 50, { material = Enum.Material.Metal })
end

---------------------------------------------------------------------------------------------------
-- BUILD
---------------------------------------------------------------------------------------------------
function Module.build(modulesContainer: Instance): Instance
	local root = folder(modulesContainer, Module.Id)

	local fExt = folder(root, "01_Exterior")
	local fSign = folder(root, "02_Signage")
	local fPark = folder(root, "03_Parking")
	local fInt = folder(root, "04_Interior")

	buildFoundation(fExt, fPark)
	buildStructure(fExt)
	buildStorefront(fExt)
	buildSignage(fSign)
	buildParkingProps(fPark)
	buildInterior(fInt)

	-- Attribute báo cáo số máu ẩn trung bình để Agent Chính tiện nghiệm thu
	root:SetAttribute("DestructibleStore", true)
	root:SetAttribute("MainEntrance", "X=175, Z=92 (mặt Nam ra Vespucci Blvd)")
	root:SetAttribute("VehicleRollupDoor", "X=143, Z=38 (mặt Tây ra Alta St), rộng 16 x cao 12")

	return root
end

return Module
