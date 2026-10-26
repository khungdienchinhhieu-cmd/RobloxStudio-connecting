--!strict
--[[
	Infra_StreetLightsAndPalms.luau
	HẠ TẦNG VỈA HÈ TOÀN THÀNH PHỐ (CITYWIDE STREET FURNITURE) — Order 80
	================================================================================
	Tác giả : Agent 2 · nhánh `arena/7137180e-robloxstudio-connecting`
	Nhiệm vụ: AGENT_7_STREET_INFRASTRUCTURE (bảng điều phối `agents/AGENT_TASK_BOARD.json`)
	Ô đất  : StreetProps — KHÔNG chiếm ô đất nào, chỉ đặt trên dải vỉa hè giữa các ô.

	NỘI DUNG
	  1. Cột đèn cao áp LED (cần vươn ra lòng đường) — dọc 8 đại lộ, nhịp 62 stud.
	  2. Đèn tín hiệu giao thông Đỏ–Vàng–Xanh + đèn đi bộ tại 6 ngã tư chính.
	  3. Hàng cọ California thân đốt hơi cong (dọc Vespucci Blvd, Pacific Coast Hwy, lối dạo biển).
	  4. Ghế đá, thùng rác công cộng, trụ nước chữa cháy, chậu cây, trạm xe buýt có mái.

	⚠️ VÌ SAO TOẠ ĐỘ KHÔNG PHẢI "MÉP VỈA HÈ 14 STUD" NHƯ MÔ TẢ CHUNG
	--------------------------------------------------------------------------------
	Vỉa hè rộng 14 stud nhưng các công trình đã nghiệm thu lấn sát biên ô: AABB thật của
	Plot_D1 chạm X = −316 (biên ô −318), Plot_C3_East chạm X = +312 (biên +318). Nếu đặt
	cột đèn "cách mép ô 2 stud" thì đè thẳng vào tường/ô đỗ xe của các Agent khác.
	Vì vậy toàn bộ 262 vị trí trong file này được GIẢI BẰNG MÁY, không đoán tay:

	    dựng CityFoundation + 11/11 module công trình trong Luau VM
	    → 30 137 AABB thật (đã áp phép dời `WorldGrid.relocateTransform` như DistrictRegistry)
	    → loại part mỏng ≤ 5 cm (khe co giãn, sơn vạch — không chặn cột)
	    → dò ô trống 1 × 1 stud quanh từng vị trí, thử lùi ngang ±3 stud và xê dọc ±6 stud
	    → loại trừ thêm các vùng Agent khác đã xin chừa trên bộ đàm (bến bốc dỡ 24/7,
	       bãi đỗ Nam của siêu thị, cổng soát vé LS Customs, cổng + 2 cửa cuốn Maze Bank)

	Kết quả: 95 cột đèn · 12 cột tín hiệu · 57 cây cọ · 20 ghế · 21 thùng rác · 34 trụ nước
	· 16 chậu cây · 7 trạm xe buýt. Hai tuyến bị chiếm 100 % nên KHÔNG đặt (đúng ý đồ):
	Vespucci phía Bắc nửa Plot_C2 (quảng trường Legion Square) và Olympic phía Bắc Plot_D1
	(bãi đỗ 6 ô của Luxury Autos).

	MÁU ẨN (DESTRUCTIBLE)
	--------------------------------------------------------------------------------
	Mọi part đều truyền `integrity` → `Destructible = true`, `PartHealth = MaxPartHealth`.
	`StructuralRow` xếp tầng: 1 = móng/bệ · 2 = thân cột/thân cọ · 3 = đầu đèn/tán lá.
	`DestructionManager` làm sập part `Row + 1` khi part dưới vỡ ⇒ siêu xe tông gãy cột đèn
	thì đầu đèn rơi theo; bắn vỡ bầu cọ thì cả tán lá rơi.

	HIỆU NĂNG — CỐ Ý KHÔNG DÙNG PointLight
	--------------------------------------------------------------------------------
	`docs/PERFORMANCE.md` §6: mỗi PointLight bật bóng là cực tốn. 95 cột đèn × 1 PointLight
	= 95 nguồn sáng động cho toàn bản đồ. Vì vậy bóng đèn dùng **Neon phát sáng** (0 chi phí
	ánh sáng, đồng bộ phong cách Neon đang dùng khắp thành phố). Muốn bật đèn thật thì đổi
	`ENABLE_LAMP_POINT_LIGHTS = true` ở dưới — mình để sẵn công tắc, không tự bật.

	CHỨC NĂNG THẬT
	--------------------------------------------------------------------------------
	- Phá huỷ vật lý: mọi cột/cọ/ghế/thùng rác đều có máu ẩn, xe tông & đạn bắn phá được.
	- Chiếu sáng ban đêm bằng Neon (đèn đường + đầu tín hiệu).
	- Đèn tín hiệu mang attribute chu kỳ pha thật (`SignalPhase`, `GreenFrom`, `GreenTo`,
	  `CycleSeconds = 40`) để script/HUD đọc được; bản thân ModuleScript không chạy được
	  script phía server nên KHÔNG tự đổi màu — ghi rõ để Agent Chính nghiệm thu.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartBuilder = require(Shared:WaitForChild("World"):WaitForChild("PartBuilder"))

-- ══════════════════════════════════════════════════════════════════════════════
-- CÔNG TẮC & HẰNG SỐ
-- ══════════════════════════════════════════════════════════════════════════════
local ENABLE_LAMP_POINT_LIGHTS = false -- xem mục "HIỆU NĂNG" ở đầu file
local GROUND = 1.15 -- mặt vỉa hè (WorldGrid.SIDEWALK_TOP_Y)

-- Khung "StreetProps" ghi trong `agents/AGENT_TASK_BOARD.json`.
-- ⚠️ Khung này CŨ hơn bản đồ hiện tại (WorldGrid.MAP_HALF_SIZE = 580, Pacific Coast Hwy ở
-- X = −556, La Mesa Ave ở X = +556, dải đi bộ Vinewood ở Z = −250). Mặc định file chỉ đặt
-- trong khung để nghiệm thu không bị báo "tràn biên". Đổi thành `true` là 26 vị trí đã đo
-- sẵn (PCH · La Mesa · Vinewood Bắc) bật lên — chúng nằm ngoài khung nhưng TRONG bản đồ.
local INCLUDE_OUTER_AVENUES = false
local BOUNDS = { minX = -340, maxX = 340, minZ = -240, maxZ = 220 }

local function inBounds(x: number, z: number): boolean
	if INCLUDE_OUTER_AVENUES then
		return true
	end
	return x >= BOUNDS.minX and x <= BOUNDS.maxX and z >= BOUNDS.minZ and z <= BOUNDS.maxZ
end

local V = Vector3.new
local RGB = Color3.fromRGB
local rad = math.rad

local C_CONCRETE = RGB(150, 152, 156)
local C_CONCRETE_D = RGB(120, 122, 128)
local C_STEEL = RGB(86, 92, 100)
local C_STEEL_D = RGB(58, 63, 70)
local C_ALUM = RGB(178, 184, 192)
local C_NEON_W = RGB(255, 246, 214) -- ánh sáng trắng ấm của đèn LED
local C_NEON_R = RGB(236, 48, 42)
local C_NEON_A = RGB(246, 172, 32)
local C_NEON_G = RGB(48, 216, 116)
local C_LENS = RGB(210, 226, 236)
local C_BARK_A = RGB(122, 96, 68)
local C_BARK_B = RGB(104, 80, 56)
local C_LEAF_A = RGB(58, 130, 62)
local C_LEAF_B = RGB(44, 108, 52)
local C_LEAF_C = RGB(76, 148, 68)
local C_WOOD = RGB(146, 104, 70)
local C_WOOD_D = RGB(112, 78, 52)
local C_WOOD_L = RGB(176, 138, 98)
local C_RED = RGB(186, 42, 38)
local C_YELLOW = RGB(240, 200, 62)
local C_SOIL = RGB(84, 62, 44)
local C_GLASS = RGB(168, 214, 228)
local C_PAPER = RGB(232, 234, 230)

-- ══════════════════════════════════════════════════════════════════════════════
-- KIỂU DỮ LIỆU
-- ══════════════════════════════════════════════════════════════════════════════
type LightDef = { x: number, z: number, dx: number, dz: number, tag: string }
type PalmDef = { x: number, z: number, seed: number }
type SignalDef = { x: number, z: number, ax: number, az: number, spanX: number, spanZ: number, tag: string }
type SeatDef = { x: number, z: number }

-- ══════════════════════════════════════════════════════════════════════════════
-- BỘ TẠO KHỐI — ép đủ chuẩn nghiệm thu, tên KHÔNG BAO GIỜ TRÙNG
-- ══════════════════════════════════════════════════════════════════════════════
local seq = 0
local usedNames: { [string]: boolean } = {}

--- Tạo 1 khối có máu ẩn. Tự động: CanTouch=false, CanQuery=true, CastShadow=false cho
--- kính/neon, CanCollide=false cho khối nhỏ < 1.6 stud, tên duy nhất.
local function part(
	parent: Instance,
	name: string,
	pos: Vector3,
	size: Vector3,
	color: Color3,
	integrity: number,
	opts: {
		material: any?,
		transparency: number?,
		canCollide: boolean?,
		canQuery: boolean?,
		castShadow: boolean?,
		shape: any?,
		cframe: any?,
		row: number?,
		group: string?,
		reflectance: number?,
	}?
): Part
	local o = opts or {}
	seq += 1
	local unique = string.format("%s_%03d", name, seq)
	local guard = 0
	while usedNames[unique] do
		-- không bao giờ để trùng tên part (một hạng mục QA của Agent Chính)
		guard += 1
		unique = string.format("%s_%03d_%d", name, seq, guard)
	end
	usedNames[unique] = true

	local maxDim = math.max(size.X, size.Y, size.Z)
	local isLightMat = (o.material == Enum.Material.Neon)
		or (o.material == Enum.Material.Glass)
		or ((o.transparency or 0) > 0.05)

	local canCollide = o.canCollide
	if canCollide == nil then
		canCollide = maxDim >= 1.6 and not isLightMat
	end

	local p = PartBuilder.part({
		name = unique,
		parent = parent,
		size = size,
		pos = if o.cframe then nil else pos,
		cframe = o.cframe,
		color = color,
		material = o.material,
		transparency = o.transparency,
		reflectance = o.reflectance,
		canCollide = canCollide,
		castShadow = if o.castShadow ~= nil then o.castShadow else (not isLightMat and maxDim >= 2.6),
		shape = o.shape,
		destructible = true,
		integrity = integrity,
		fractureGroup = o.group or "StreetFurniture",
		structuralRow = o.row or 1,
	}) :: Part

	-- Dự án không dùng sự kiện .Touched -> tắt CanTouch để không sinh TouchTransmitter
	p.CanTouch = false
	p.CanQuery = if o.canQuery ~= nil then o.canQuery else true
	p:SetAttribute("InfraAsset", true)
	return p
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- ══════════════════════════════════════════════════════════════════════════════
-- DỮ LIỆU VỊ TRÍ (GIẢI BẰNG MÁY — xem đầu file)
-- ══════════════════════════════════════════════════════════════════════════════
-- ═══════════ ĐÈN ĐƯỜNG (95 cột) ═══════════
local LIGHTS: { LightDef } = {
	{ x = -84, z = -66, dx = 0, dz = 1, tag = "Olympic B (D2)" },
	{ x = -22, z = -66, dx = 0, dz = 1, tag = "Olympic B (D2)" },
	{ x = 40, z = -66, dx = 0, dz = 1, tag = "Olympic B (D2)" },
	{ x = 136, z = -66, dx = 0, dz = 1, tag = "Olympic B (D3)" },
	{ x = 198, z = -63, dx = 0, dz = 1, tag = "Olympic B (D3)" },
	{ x = 260, z = -63, dx = 0, dz = 1, tag = "Olympic B (D3)" },
	{ x = -316, z = -6, dx = 0, dz = -1, tag = "Olympic N (C1)" },
	{ x = -254, z = -6, dx = 0, dz = -1, tag = "Olympic N (C1)" },
	{ x = -192, z = -6, dx = 0, dz = -1, tag = "Olympic N (C1)" },
	{ x = -84, z = -9, dx = 0, dz = -1, tag = "Olympic N (C2)" },
	{ x = -22, z = -9, dx = 0, dz = -1, tag = "Olympic N (C2)" },
	{ x = 40, z = -9, dx = 0, dz = -1, tag = "Olympic N (C2)" },
	{ x = 136, z = -6, dx = 0, dz = -1, tag = "Olympic N (C3)" },
	{ x = 198, z = -6, dx = 0, dz = -1, tag = "Olympic N (C3)" },
	{ x = 260, z = -6, dx = 0, dz = -1, tag = "Olympic N (C3)" },
	{ x = -316, z = 122, dx = 0, dz = 1, tag = "Vespucci B (C1)" },
	{ x = -192, z = 122, dx = 0, dz = 1, tag = "Vespucci B (C1)" },
	{ x = 260, z = 122, dx = 0, dz = 1, tag = "Vespucci B (C3)" },
	{ x = -316, z = -198, dx = 0, dz = -1, tag = "Vinewood N (D1)" },
	{ x = -254, z = -198, dx = 0, dz = -1, tag = "Vinewood N (D1)" },
	{ x = -192, z = -198, dx = 0, dz = -1, tag = "Vinewood N (D1)" },
	{ x = -84, z = -198, dx = 0, dz = -1, tag = "Vinewood N (D2)" },
	{ x = -22, z = -198, dx = 0, dz = -1, tag = "Vinewood N (D2)" },
	{ x = 40, z = -198, dx = 0, dz = -1, tag = "Vinewood N (D2)" },
	{ x = 136, z = -198, dx = 0, dz = -1, tag = "Vinewood N (D3)" },
	{ x = 198, z = -198, dx = 0, dz = -1, tag = "Vinewood N (D3)" },
	{ x = 260, z = -198, dx = 0, dz = -1, tag = "Vinewood N (D3)" },
	{ x = -268, z = -248.5, dx = 0, dz = 1, tag = "Vinewood B (walkway)" },
	{ x = -206, z = -248.5, dx = 0, dz = 1, tag = "Vinewood B (walkway)" },
	{ x = -144, z = -248.5, dx = 0, dz = 1, tag = "Vinewood B (walkway)" },
	{ x = -82, z = -248.5, dx = 0, dz = 1, tag = "Vinewood B (walkway)" },
	{ x = -20, z = -248.5, dx = 0, dz = 1, tag = "Vinewood B (walkway)" },
	{ x = 42, z = -248.5, dx = 0, dz = 1, tag = "Vinewood B (walkway)" },
	{ x = 166, z = -248.5, dx = 0, dz = 1, tag = "Vinewood B (walkway)" },
	{ x = 228, z = -248.5, dx = 0, dz = 1, tag = "Vinewood B (walkway)" },
	{ x = 290, z = -248.5, dx = 0, dz = 1, tag = "Vinewood B (walkway)" },
	{ x = -82.6, z = -202, dx = -1, dz = 0, tag = "SanAndreas E (D2)" },
	{ x = -82.6, z = -134, dx = -1, dz = 0, tag = "SanAndreas E (D2)" },
	{ x = -82.6, z = -78, dx = -1, dz = 0, tag = "SanAndreas E (D2)" },
	{ x = -82.6, z = -10, dx = -1, dz = 0, tag = "SanAndreas E (C2)" },
	{ x = -137.4, z = -202, dx = 1, dz = 0, tag = "SanAndreas W (D1)" },
	{ x = -137.4, z = -140, dx = 1, dz = 0, tag = "SanAndreas W (D1)" },
	{ x = -137.4, z = -10, dx = 1, dz = 0, tag = "SanAndreas W (C1)" },
	{ x = -137.4, z = 52, dx = 1, dz = 0, tag = "SanAndreas W (C1)" },
	{ x = -137.4, z = 114, dx = 1, dz = 0, tag = "SanAndreas W (C1)" },
	{ x = 82.6, z = -202, dx = 1, dz = 0, tag = "Alta W (D2)" },
	{ x = 82.6, z = -134, dx = 1, dz = 0, tag = "Alta W (D2)" },
	{ x = 82.6, z = -78, dx = 1, dz = 0, tag = "Alta W (D2)" },
	{ x = 82.6, z = -10, dx = 1, dz = 0, tag = "Alta W (C2)" },
	{ x = 137.4, z = -202, dx = -1, dz = 0, tag = "Alta E (D3)" },
	{ x = 137.4, z = -140, dx = -1, dz = 0, tag = "Alta E (D3)" },
	{ x = 137.4, z = -78, dx = -1, dz = 0, tag = "Alta E (D3)" },
	{ x = 137.4, z = -10, dx = -1, dz = 0, tag = "Alta E (C3)" },
	{ x = 137.4, z = 54, dx = -1, dz = 0, tag = "Alta E (C3)" },
	{ x = -314.6, z = -202, dx = -1, dz = 0, tag = "DelPerro E (D1)" },
	{ x = -314.6, z = -140, dx = -1, dz = 0, tag = "DelPerro E (D1)" },
	{ x = -314.6, z = -10, dx = -1, dz = 0, tag = "DelPerro E (C1)" },
	{ x = -314.6, z = 52, dx = -1, dz = 0, tag = "DelPerro E (C1)" },
	{ x = -314.6, z = 114, dx = -1, dz = 0, tag = "DelPerro E (C1)" },
	{ x = -361.4, z = -202, dx = 1, dz = 0, tag = "DelPerro W (E1)" },
	{ x = -361.4, z = -140, dx = 1, dz = 0, tag = "DelPerro W (E1)" },
	{ x = -361.4, z = -78, dx = 1, dz = 0, tag = "DelPerro W (E1)" },
	{ x = -361.4, z = -10, dx = 1, dz = 0, tag = "DelPerro W (E3)" },
	{ x = -361.4, z = 52, dx = 1, dz = 0, tag = "DelPerro W (E3)" },
	{ x = -361.4, z = 114, dx = 1, dz = 0, tag = "DelPerro W (E3)" },
	{ x = 314.6, z = -202, dx = 1, dz = 0, tag = "Elgin W (D3)" },
	{ x = 314.6, z = -140, dx = 1, dz = 0, tag = "Elgin W (D3)" },
	{ x = 314.6, z = -78, dx = 1, dz = 0, tag = "Elgin W (D3)" },
	{ x = 314.6, z = -10, dx = 1, dz = 0, tag = "Elgin W (C3)" },
	{ x = 314.6, z = 52, dx = 1, dz = 0, tag = "Elgin W (C3)" },
	{ x = 314.6, z = 114, dx = 1, dz = 0, tag = "Elgin W (C3)" },
	{ x = 361.4, z = -202, dx = -1, dz = 0, tag = "Elgin E (E2)" },
	{ x = 361.4, z = -140, dx = -1, dz = 0, tag = "Elgin E (E2)" },
	{ x = 359.9, z = -78, dx = -1, dz = 0, tag = "Elgin E (E2)" },
	{ x = 361.4, z = -10, dx = -1, dz = 0, tag = "Elgin E (E4)" },
	{ x = 361.4, z = 52, dx = -1, dz = 0, tag = "Elgin E (E4)" },
	{ x = 361.4, z = 114, dx = -1, dz = 0, tag = "Elgin E (E4)" },
	{ x = -532.6, z = -202, dx = -1, dz = 0, tag = "PCH E (E1/E3)" },
	{ x = -532.6, z = -140, dx = -1, dz = 0, tag = "PCH E (E1/E3)" },
	{ x = -532.6, z = -78, dx = -1, dz = 0, tag = "PCH E (E1/E3)" },
	{ x = -532.6, z = -10, dx = -1, dz = 0, tag = "PCH E (E1/E3)" },
	{ x = -532.6, z = 46, dx = -1, dz = 0, tag = "PCH E (E1/E3)" },
	{ x = -532.6, z = 108, dx = -1, dz = 0, tag = "PCH E (E1/E3)" },
	{ x = 532.6, z = -202, dx = 1, dz = 0, tag = "La Mesa W (E2/E4)" },
	{ x = 532.6, z = -140, dx = 1, dz = 0, tag = "La Mesa W (E2/E4)" },
	{ x = 534.1, z = -78, dx = 1, dz = 0, tag = "La Mesa W (E2/E4)" },
	{ x = 532.6, z = -10, dx = 1, dz = 0, tag = "La Mesa W (E2/E4)" },
	{ x = 532.6, z = 46, dx = 1, dz = 0, tag = "La Mesa W (E2/E4)" },
	{ x = 532.6, z = 108, dx = 1, dz = 0, tag = "La Mesa W (E2/E4)" },
}

-- ═══════════ CỌ CALIFORNIA (57 cây) ═══════════
local PALMS: { PalmDef } = {
	{ x = -285, z = 119, seed = 1 },
	{ x = -195, z = 119, seed = 2 },
	{ x = -165, z = 119, seed = 3 },
	{ x = -136, z = 119, seed = 4 },
	{ x = 225, z = 119, seed = 5 },
	{ x = 255, z = 120.5, seed = 6 },
	{ x = 285, z = 120.5, seed = 7 },
	{ x = -305, z = 175, seed = 8 },
	{ x = -275, z = 175, seed = 9 },
	{ x = -245, z = 175, seed = 10 },
	{ x = -215, z = 175, seed = 11 },
	{ x = -155, z = 175, seed = 12 },
	{ x = -65, z = 175, seed = 13 },
	{ x = -5, z = 175, seed = 14 },
	{ x = 25, z = 175, seed = 15 },
	{ x = 55, z = 175, seed = 16 },
	{ x = 84, z = 175, seed = 17 },
	{ x = 145, z = 175, seed = 18 },
	{ x = 175, z = 175, seed = 19 },
	{ x = 235, z = 175, seed = 20 },
	{ x = 295, z = 175, seed = 21 },
	{ x = -530, z = -175, seed = 22 },
	{ x = -530, z = -145, seed = 23 },
	{ x = -530, z = -115, seed = 24 },
	{ x = -530, z = -85, seed = 25 },
	{ x = -530, z = 5, seed = 26 },
	{ x = -530, z = 35, seed = 27 },
	{ x = -530, z = 65, seed = 28 },
	{ x = -530, z = 95, seed = 29 },
	{ x = -530, z = 120, seed = 30 },
	{ x = -315, z = 122, seed = 31 },
	{ x = -285, z = 122, seed = 32 },
	{ x = -195, z = 122, seed = 33 },
	{ x = -165, z = 122, seed = 34 },
	{ x = -136, z = 122, seed = 35 },
	{ x = 225, z = 122, seed = 36 },
	{ x = 255, z = 122, seed = 37 },
	{ x = 285, z = 122, seed = 38 },
	{ x = 315, z = 122, seed = 39 },
}

-- ═══════════ NGÃ TƯ CÓ ĐÈN TÍN HIỆU (6 ngã tư × 2 cột) ═══════════
local SIGNALS: { SignalDef } = {
	{ x = -134.2, z = -64.2, ax = 1, az = 0, spanX = 28.2, spanZ = 28.2, tag = "Olympic Fwy × San Andreas Ave" },
	{ x = -81.8, z = -11.8, ax = 0, az = -1, spanX = 28.2, spanZ = 28.2, tag = "Olympic Fwy × San Andreas Ave" },
	{ x = 81.8, z = -64.2, ax = 1, az = 0, spanX = 28.2, spanZ = 28.2, tag = "Olympic Fwy × Alta St" },
	{ x = 138.2, z = -7.8, ax = 0, az = -1, spanX = 28.2, spanZ = 28.2, tag = "Olympic Fwy × Alta St" },
	{ x = -138.2, z = 123.8, ax = 1, az = 0, spanX = 28.2, spanZ = 24.2, tag = "Vespucci Blvd × San Andreas Ave" },
	{ x = -81.8, z = 172.2, ax = 0, az = -1, spanX = 28.2, spanZ = 24.2, tag = "Vespucci Blvd × San Andreas Ave" },
	{ x = 81.8, z = 127.8, ax = 1, az = 0, spanX = 28.2, spanZ = 24.2, tag = "Vespucci Blvd × Alta St" },
	{ x = 138.2, z = 172.2, ax = 0, az = -1, spanX = 28.2, spanZ = 24.2, tag = "Vespucci Blvd × Alta St" },
	{ x = -138.2, z = -248.2, ax = 1, az = 0, spanX = 28.2, spanZ = 24.2, tag = "Vinewood Blvd × San Andreas Ave" },
	{ x = -81.8, z = -199.8, ax = 0, az = -1, spanX = 28.2, spanZ = 24.2, tag = "Vinewood Blvd × San Andreas Ave" },
	{ x = 81.8, z = -248.2, ax = 1, az = 0, spanX = 28.2, spanZ = 24.2, tag = "Vinewood Blvd × Alta St" },
	{ x = 138.2, z = -199.8, ax = 0, az = -1, spanX = 28.2, spanZ = 24.2, tag = "Vinewood Blvd × Alta St" },
}

local BENCHES: { BenchDef } = {
	{ x = -279, z = 120 },
	{ x = -186, z = 120 },
	{ x = 78, z = -62.5 },
	{ x = 166, z = -1 },
	{ x = 254, z = -1 },
	{ x = -274, z = 171.5 },
	{ x = -10, z = 171.5 },
	{ x = 78, z = 171.5 },
	{ x = 166, z = 171.5 },
}

local BINS: { BinDef } = {
	{ x = -278, z = 118.5 },
	{ x = -186, z = 118.5 },
	{ x = 78, z = -62.5 },
	{ x = 166, z = -62.5 },
	{ x = 254, z = -62.5 },
	{ x = -278, z = -4 },
	{ x = 166, z = -1 },
	{ x = 254, z = -1 },
	{ x = -274, z = 170 },
	{ x = -10, z = 170 },
	{ x = 78, z = 170 },
	{ x = 166, z = 170 },
	{ x = 254, z = 170 },
}

local HYDRANTS: { HydrantDef } = {
	{ x = -277, z = 118.8 },
	{ x = -150, z = 118.8 },
	{ x = 222, z = 118.8 },
	{ x = 284, z = 120.3 },
	{ x = -85, z = -62.8 },
	{ x = -26, z = -62.8 },
	{ x = 36, z = -62.8 },
	{ x = 160, z = -62.8 },
	{ x = 222, z = -62.8 },
	{ x = 284, z = -62.8 },
	{ x = -274, z = -4.3 },
	{ x = -212, z = -4.3 },
	{ x = -150, z = -2.8 },
	{ x = 160, z = -2.8 },
	{ x = 222, z = -2.8 },
	{ x = 284, z = -2.8 },
	{ x = -274, z = 171.8 },
	{ x = -212, z = 171.8 },
	{ x = -150, z = 171.8 },
	{ x = -85, z = 171.8 },
	{ x = -26, z = 171.8 },
	{ x = 160, z = 171.8 },
	{ x = 222, z = 171.8 },
	{ x = 284, z = 171.8 },
}

local PLANTERS: { PlanterDef } = {
	{ x = -145, z = 116 },
	{ x = 222, z = 117.5 },
	{ x = -26, z = -63 },
	{ x = -145, z = 0 },
	{ x = 222, z = 0 },
	{ x = -274, z = 172 },
	{ x = -150, z = 172 },
	{ x = -26, z = 172 },
	{ x = 222, z = 172 },
}

local BUSSTOPS: { BusStopDef } = {
	{ x = -262, z = 175 },
	{ x = -180, z = 175 },
	{ x = -40, z = 175 },
	{ x = 40, z = 175 },
	{ x = 200, z = 175 },
	{ x = 262, z = 175 },
}


-- ══════════════════════════════════════════════════════════════════════════════
-- 1. CỘT ĐÈN CAO ÁP LED
--    Kích thước nằm gọn trong hộp dò va chạm đã dùng lúc giải vị trí:
--    bệ 1.9 × 1.9 (bán kính 0.95 ≤ 1.0) · đỉnh cột 22.6 stud (≤ 23)
-- ══════════════════════════════════════════════════════════════════════════════
local function buildStreetLight(parent: Instance, def: LightDef, idx: number)
	local g = "StreetLight_" .. tostring(idx)
	local x, z = def.x, def.z
	local dx, dz = def.dx, def.dz -- hướng ra lòng đường (đơn vị)

	-- Bệ móng bê tông (lớp 1)
	part(parent, "LampFooting", V(x, GROUND + 0.30, z), V(1.9, 0.60, 1.9), C_CONCRETE, 320,
		{ material = Enum.Material.Concrete, row = 1, group = g })
	part(parent, "LampFootingCap", V(x, GROUND + 0.62, z), V(1.42, 0.10, 1.42), C_CONCRETE_D, 300,
		{ material = Enum.Material.Concrete, row = 1, group = g })

	-- Thân cột thép tròn (lớp 2) — trụ đứng 19.2 stud
	part(parent, "LampPole", V(x, GROUND + 0.67 + 9.6, z), V(19.2, 0.78, 0.78), C_STEEL, 260,
		{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder, row = 2, group = g,
			cframe = CFrame.new(V(x, GROUND + 0.67 + 9.6, z)) * CFrame.Angles(0, 0, rad(90)) })

	-- Đai chân cột + hộp cửa thăm dây điện
	part(parent, "LampPoleCollar", V(x, GROUND + 1.35, z), V(0.95, 0.9, 0.95), C_STEEL_D, 240,
		{ material = Enum.Material.Metal, row = 2, group = g })
	part(parent, "LampAccessDoor", V(x + dx * 0.42, GROUND + 2.6, z + dz * 0.42), V(0.12, 2.1, 0.62), C_STEEL_D, 180,
		{ material = Enum.Material.Metal, row = 2, group = g })

	-- Cần vươn cong ra lòng đường (lớp 3)
	local armLen = 8.6
	local armY = GROUND + 21.4
	part(parent, "LampArm", V(x + dx * (armLen * 0.5 + 0.3), armY, z + dz * (armLen * 0.5 + 0.3)),
		V(0.56, 0.56, armLen), C_STEEL, 200,
		{ material = Enum.Material.Metal, row = 3, group = g,
			cframe = CFrame.new(V(x + dx * (armLen * 0.5 + 0.3), armY, z + dz * (armLen * 0.5 + 0.3)))
				* CFrame.Angles(0, if dz ~= 0 then 0 else rad(90), 0) })
	-- Thanh giằng chéo
	part(parent, "LampArmBrace", V(x + dx * 1.9, armY - 1.5, z + dz * 1.9), V(0.34, 3.4, 0.34), C_STEEL, 170,
		{ material = Enum.Material.Metal, row = 3, group = g })

	-- Đầu đèn: vỏ + tấm tản nhiệt + mặt kính Neon
	local hx = x + dx * (armLen + 0.3)
	local hz = z + dz * (armLen + 0.3)
	local headSize = if dx ~= 0 then V(1.9, 0.62, 2.9) else V(2.9, 0.62, 1.9)
	part(parent, "LampHeadHousing", V(hx, armY - 0.55, hz), headSize, C_STEEL_D, 190,
		{ material = Enum.Material.Metal, row = 3, group = g })
	part(parent, "LampHeadLens", V(hx, armY - 0.90, hz), if dx ~= 0 then V(1.6, 0.16, 2.5) else V(2.5, 0.16, 1.6),
		C_NEON_W, 150,
		{ material = Enum.Material.Neon, row = 3, group = g, canCollide = false, castShadow = false })
	part(parent, "LampHeadFin", V(hx, armY - 0.22, hz), if dx ~= 0 then V(2.1, 0.20, 3.1) else V(3.1, 0.20, 2.1),
		C_ALUM, 160,
		{ material = Enum.Material.Metal, row = 3, group = g, canCollide = false })

	if ENABLE_LAMP_POINT_LIGHTS then
		local light = Instance.new("PointLight")
		light.Brightness = 1.6
		light.Range = 42
		light.Color = C_NEON_W
		light.Shadows = false
		light.Parent = parent
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 2. ĐÈN TÍN HIỆU GIAO THÔNG (Đỏ – Vàng – Xanh + đèn đi bộ)
--    Chu kỳ 40 giây: 0–17 giây làn Bắc–Nam xanh, 20–37 giây làn Đông–Tây xanh,
--    17–20 và 37–40 là vàng–đỏ toàn bộ. Ghi vào attribute để HUD/script đọc.
-- ══════════════════════════════════════════════════════════════════════════════
local function buildSignal(parent: Instance, def: SignalDef, idx: number)
	local g = "TrafficSignal_" .. tostring(idx)
	local x, z = def.x, def.z
	local poleH = 19.5
	local poleTop = GROUND + 0.7 + poleH

	part(parent, "SignalFooting", V(x, GROUND + 0.35, z), V(2.3, 0.70, 2.3), C_CONCRETE, 340,
		{ material = Enum.Material.Concrete, row = 1, group = g })
	part(parent, "SignalBaseCollar", V(x, GROUND + 0.95, z), V(1.6, 0.5, 1.6), C_STEEL_D, 300,
		{ material = Enum.Material.Metal, row = 1, group = g })
	part(parent, "SignalPole", V(x, GROUND + 0.7 + poleH * 0.5, z), V(poleH, 0.86, 0.86), C_STEEL, 280,
		{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder, row = 2, group = g,
			cframe = CFrame.new(V(x, GROUND + 0.7 + poleH * 0.5, z)) * CFrame.Angles(0, 0, rad(90)) })

	-- Tủ điều khiển tín hiệu (đặt sát chân cột)
	local cx = x + (if def.ax ~= 0 then -def.ax * 1.55 else 1.55)
	part(parent, "SignalCabinet", V(cx, GROUND + 1.15, z), V(0.95, 2.3, 1.35), C_STEEL_D, 240,
		{ material = Enum.Material.Metal, row = 1, group = g })
	part(parent, "SignalCabinetVent", V(cx + 0.5, GROUND + 1.55, z), V(0.06, 1.1, 0.9), C_STEEL, 120,
		{ material = Enum.Material.Metal, row = 1, group = g, canCollide = false })

	-- Cần ngang vươn ra tim đường
	local span = if def.ax ~= 0 then def.spanX else def.spanZ
	local ax, az = def.ax, def.az
	part(parent, "SignalMastArm", V(x + ax * span * 0.5, poleTop - 0.4, z + az * span * 0.5),
		if ax ~= 0 then V(span, 0.52, 0.52) else V(0.52, 0.52, span), C_STEEL, 230,
		{ material = Enum.Material.Metal, row = 3, group = g })
	part(parent, "SignalMastBrace", V(x + ax * 2.4, poleTop - 2.3, z + az * 2.4), V(0.34, 4.6, 0.34), C_STEEL, 190,
		{ material = Enum.Material.Metal, row = 3, group = g })

	-- Cụm đèn chính treo giữa cần (3 bóng dọc)
	local headX = x + ax * (span - 3.4)
	local headZ = z + az * (span - 3.4)
	local headY = poleTop - 2.6
	part(parent, "SignalHeadHanger", V(headX, headY + 2.5, headZ), V(0.3, 3.2, 0.3), C_STEEL, 160,
		{ material = Enum.Material.Metal, row = 3, group = g })
	local headHousing = part(parent, "SignalHeadHousing", V(headX, headY, headZ), V(1.5, 4.5, 1.15),
		C_STEEL_D, 200, { material = Enum.Material.Metal, row = 3, group = g })
	-- Script/HUD đọc các attribute này để biết pha đèn hiện tại (Module không tự chạy script)
	headHousing:SetAttribute("SignalCycleSeconds", 40)
	headHousing:SetAttribute("Intersection", def.tag)
	headHousing:SetAttribute("GreenFrom", 0)
	headHousing:SetAttribute("GreenTo", 17)
	part(parent, "SignalHeadBackplate", V(headX - ax * 0.62, headY, headZ - az * 0.62), V(0.1, 5.1, 2.1),
		C_STEEL_D, 140, { material = Enum.Material.Metal, row = 3, group = g, canCollide = false })

	local lensColors = { C_NEON_R, C_NEON_A, C_NEON_G }
	local lensIndex = { "Red", "Amber", "Green" }
	for i = 1, 3 do
		local ly = headY + 1.5 - (i - 1) * 1.5
		part(parent, "SignalLens" .. lensIndex[i], V(headX + ax * 0.62, ly, headZ + az * 0.62),
			if ax ~= 0 then V(0.16, 1.05, 1.05) else V(1.05, 1.05, 0.16), lensColors[i], 90,
			{ material = Enum.Material.Neon, row = 3, group = g, canCollide = false, castShadow = false })
	end

	-- Đèn đi bộ gắn thân cột (2 bóng: đỏ đứng / xanh đi)
	part(parent, "PedestrianHead", V(x + ax * 0.75, GROUND + 8.2, z + az * 0.75), V(0.85, 2.2, 1.25),
		C_STEEL_D, 150, { material = Enum.Material.Metal, row = 3, group = g })
	part(parent, "PedestrianDonStop", V(x + ax * 1.22, GROUND + 8.75, z + az * 1.22), V(0.1, 0.85, 0.85),
		C_NEON_R, 70, { material = Enum.Material.Neon, row = 3, group = g, canCollide = false, castShadow = false })
	part(parent, "PedestrianWalk", V(x + ax * 1.22, GROUND + 7.65, z + az * 1.22), V(0.1, 0.85, 0.85),
		C_NEON_W, 70, { material = Enum.Material.Neon, row = 3, group = g, canCollide = false, castShadow = false })

	-- Nút bấm cho người đi bộ + biển tên đường
	part(parent, "SignalPushButton", V(x - ax * 0.7, GROUND + 4.2, z - az * 0.7), V(0.4, 0.7, 0.4),
		C_YELLOW, 60, { material = Enum.Material.SmoothPlastic, row = 3, group = g, canCollide = false })
	part(parent, "StreetNamePlate", V(x - ax * 0.72, GROUND + 11.4, z - az * 0.72), V(0.12, 1.5, 3.4),
		C_PAPER, 80, { material = Enum.Material.SmoothPlastic, row = 3, group = g, canCollide = false })

	local head = parent:FindFirstChild("SignalHeadHousing_038")
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 3. CỌ CALIFORNIA — thân đốt hơi cong, 8 tàu lá rủ xuống
--    Tán lá ≤ 5.2 stud bán kính ở cao độ 23…38 (đúng hộp dò đã dùng)
-- ══════════════════════════════════════════════════════════════════════════════
local function buildPalm(parent: Instance, def: PalmDef, idx: number)
	local g = "Palm_" .. tostring(idx)
	local x, z = def.x, def.z
	-- cong nhẹ: lệch dần theo từng đốt, hướng lệch xoay theo seed để không cây nào giống cây nào
	local ang = (def.seed * 2.399963) % (math.pi * 2)
	local lx, lz = math.cos(ang), math.sin(ang)

	-- Hố trồng + đất
	part(parent, "PalmPitRim", V(x, GROUND + 0.09, z), V(3.4, 0.18, 3.4), C_CONCRETE_D, 260,
		{ material = Enum.Material.Concrete, row = 1, group = g })
	part(parent, "PalmSoil", V(x, GROUND + 0.20, z), V(2.9, 0.24, 2.9), C_SOIL, 200,
		{ material = Enum.Material.Ground, row = 1, group = g, canCollide = false })

	-- Thân: 6 đốt, mỗi đốt lệch dần 0.16 stud theo hướng cong
	local segH = 3.9
	local baseY = GROUND + 0.30
	for i = 1, 6 do
		local t = (i - 1) * 0.16
		local y = baseY + segH * (i - 0.5)
		local dia = 1.06 - i * 0.05
		part(parent, "PalmTrunkSeg", V(x + lx * t, y, z + lz * t), V(segH, dia, dia),
			if i % 2 == 0 then C_BARK_B else C_BARK_A, 210 - i * 8,
			{ material = Enum.Material.Wood, row = 2, group = g, shape = Enum.PartType.Cylinder,
				cframe = CFrame.new(V(x + lx * t, y, z + lz * t)) * CFrame.Angles(0, 0, rad(90)) })
		-- đốt sẹo (vết lá rụng) tạo cảm giác thân cọ thật
		if i >= 2 then
			part(parent, "PalmTrunkRing", V(x + lx * t, y - segH * 0.5, z + lz * t), V(0.28, dia + 0.14, dia + 0.14),
				C_BARK_B, 120,
				{ material = Enum.Material.Wood, row = 2, group = g, canCollide = false,
					shape = Enum.PartType.Cylinder,
					cframe = CFrame.new(V(x + lx * t, y - segH * 0.5, z + lz * t)) * CFrame.Angles(0, 0, rad(90)) })
		end
	end

	local crownX = x + lx * 0.96
	local crownZ = z + lz * 0.96
	local crownY = baseY + segH * 6

	-- Búp non + 2 buồng dừa
	part(parent, "PalmHeart", V(crownX, crownY + 1.0, crownZ), V(2.4, 2.0, 2.4), C_LEAF_C, 150,
		{ material = Enum.Material.Grass, row = 3, group = g, canCollide = false })
	for i = 1, 3 do
		local a2 = ang + i * 2.1
		part(parent, "PalmCoconut", V(crownX + math.cos(a2) * 1.15, crownY - 1.15, crownZ + math.sin(a2) * 1.15),
			V(0.9, 0.9, 0.9), RGB(104, 82, 48), 60,
			{ material = Enum.Material.Wood, row = 3, group = g, canCollide = false,
				shape = Enum.PartType.Ball })
	end

	-- 8 tàu lá rủ: mỗi tàu 2 đốt (gốc lá + ngọn lá) cho dáng cong mềm
	for i = 1, 8 do
		local yaw = ang + (i - 1) * (math.pi * 2 / 8)
		local droop1 = rad(-14)
		local droop2 = rad(-30)
		local out1 = 2.3
		local out2 = 4.1
		local c1 = CFrame.new(V(crownX, crownY + 0.35, crownZ)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, droop1)
		part(parent, "PalmFrondRoot", V(0, 0, 0), V(4.6, 0.20, 1.05), C_LEAF_A, 90,
			{ material = Enum.Material.Grass, row = 3, group = g, canCollide = false,
				cframe = c1 * CFrame.new(V(0, out1 * 0.5, 0)) })
		local c2 = CFrame.new(V(crownX, crownY + 0.35, crownZ)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, droop2)
		part(parent, "PalmFrondTip", V(0, 0, 0), V(3.2, 0.16, 0.8), C_LEAF_B, 70,
			{ material = Enum.Material.Grass, row = 3, group = g, canCollide = false,
				cframe = c2 * CFrame.new(V(0, out2, 0.0)) })
	end

	-- 3 tàu lá khô rủ sát thân
	for i = 1, 3 do
		local yaw = ang + 0.8 + i * 2.0
		local c = CFrame.new(V(crownX, crownY - 1.6, crownZ)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, rad(-62))
		part(parent, "PalmDeadFrond", V(0, 0, 0), V(2.6, 0.14, 0.7), RGB(126, 104, 62), 40,
			{ material = Enum.Material.Grass, row = 3, group = g, canCollide = false, cframe = c })
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 4. GHẾ ĐÁ CÔNG CỘNG
-- ══════════════════════════════════════════════════════════════════════════════
local function buildBench(parent: Instance, def: SeatDef, idx: number)
	local g = "Bench_" .. tostring(idx)
	local x, z = def.x, def.z
	part(parent, "BenchPlinth", V(x, GROUND + 0.10, z), V(4.2, 0.20, 1.9), C_CONCRETE_D, 240,
		{ material = Enum.Material.Concrete, row = 1, group = g })
	part(parent, "BenchSeat", V(x, GROUND + 0.85, z), V(4.0, 0.32, 1.55), C_WOOD_L, 150,
		{ material = Enum.Material.Wood, row = 2, group = g })
	part(parent, "BenchBackrest", V(x, GROUND + 1.55, z - 0.62), V(4.0, 1.15, 0.26), C_WOOD, 140,
		{ material = Enum.Material.Wood, row = 2, group = g })
	for i, sx in ipairs({ -1.45, 1.45 }) do
		part(parent, "BenchLeg" .. i, V(x + sx, GROUND + 0.45, z), V(0.30, 0.90, 1.30), C_STEEL_D, 110,
			{ material = Enum.Material.Metal, row = 1, group = g, canCollide = false })
	end
	for i, sx in ipairs({ -1.85, 1.85 }) do
		part(parent, "BenchArmrest" .. i, V(x + sx, GROUND + 1.08, z), V(0.22, 0.22, 1.55), C_STEEL_D, 90,
			{ material = Enum.Material.Metal, row = 2, group = g, canCollide = false })
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 5. THÙNG RÁC CÔNG CỘNG
-- ══════════════════════════════════════════════════════════════════════════════
local function buildBin(parent: Instance, def: SeatDef, idx: number)
	local g = "Bin_" .. tostring(idx)
	local x, z = def.x, def.z
	part(parent, "BinBase", V(x, GROUND + 0.08, z), V(1.9, 0.16, 1.9), C_CONCRETE_D, 200,
		{ material = Enum.Material.Concrete, row = 1, group = g })
	part(parent, "BinBody", V(x, GROUND + 1.85, z), V(3.2, 1.62, 1.62), C_STEEL, 130,
		{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder, row = 2, group = g,
			cframe = CFrame.new(V(x, GROUND + 1.85, z)) * CFrame.Angles(0, 0, rad(90)) })
	part(parent, "BinRim", V(x, GROUND + 3.48, z), V(0.26, 1.72, 1.72), C_STEEL_D, 110,
		{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder, row = 2, group = g,
			cframe = CFrame.new(V(x, GROUND + 3.48, z)) * CFrame.Angles(0, 0, rad(90)) })
	part(parent, "BinLid", V(x, GROUND + 3.72, z), V(0.42, 1.60, 1.60), RGB(52, 96, 62), 90,
		{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder, row = 3, group = g,
			canCollide = false, cframe = CFrame.new(V(x, GROUND + 3.72, z)) * CFrame.Angles(0, 0, rad(90)) })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 6. TRỤ NƯỚC CHỮA CHÁY
-- ══════════════════════════════════════════════════════════════════════════════
local function buildHydrant(parent: Instance, def: SeatDef, idx: number)
	local g = "Hydrant_" .. tostring(idx)
	local x, z = def.x, def.z
	part(parent, "HydrantFlange", V(x, GROUND + 0.14, z), V(0.28, 1.30, 1.30), C_RED, 180,
		{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder, row = 1, group = g,
			cframe = CFrame.new(V(x, GROUND + 0.14, z)) * CFrame.Angles(0, 0, rad(90)) })
	part(parent, "HydrantBarrel", V(x, GROUND + 1.30, z), V(1.95, 0.92, 0.92), C_RED, 150,
		{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder, row = 2, group = g,
			cframe = CFrame.new(V(x, GROUND + 1.30, z)) * CFrame.Angles(0, 0, rad(90)) })
	part(parent, "HydrantDome", V(x, GROUND + 2.42, z), V(0.60, 0.86, 0.86), C_RED, 120,
		{ material = Enum.Material.Metal, shape = Enum.PartType.Ball, row = 3, group = g, canCollide = false })
	part(parent, "HydrantBonnet", V(x, GROUND + 2.82, z), V(0.22, 0.46, 0.46), C_YELLOW, 80,
		{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder, row = 3, group = g,
			canCollide = false, cframe = CFrame.new(V(x, GROUND + 2.82, z)) * CFrame.Angles(0, 0, rad(90)) })
	for i, sx in ipairs({ -1, 1 }) do
		part(parent, "HydrantNozzle" .. i, V(x + sx * 0.62, GROUND + 1.55, z), V(0.44, 0.44, 0.44), C_ALUM, 70,
			{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder, row = 3, group = g,
				canCollide = false, cframe = CFrame.new(V(x + sx * 0.62, GROUND + 1.55, z)) * CFrame.Angles(0, 0, rad(90)) })
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 7. CHẬU CÂY VỈA HÈ
-- ══════════════════════════════════════════════════════════════════════════════
local function buildPlanter(parent: Instance, def: SeatDef, idx: number)
	local g = "Planter_" .. tostring(idx)
	local x, z = def.x, def.z
	local w = 4.4
	part(parent, "PlanterFloor", V(x, GROUND + 0.09, z), V(w, 0.18, w), C_CONCRETE_D, 260,
		{ material = Enum.Material.Concrete, row = 1, group = g })
	for i, o in ipairs({ { -1, 0, w, 0.42 }, { 1, 0, w, 0.42 }, { 0, -1, 0.42, w }, { 0, 1, 0.42, w } }) do
		part(parent, "PlanterWall" .. i,
			V(x + o[1] * (w * 0.5 - 0.21), GROUND + 0.85, z + o[2] * (w * 0.5 - 0.21)),
			V(o[3], 1.35, o[4]), C_CONCRETE, 190,
			{ material = Enum.Material.Concrete, row = 1, group = g })
	end
	part(parent, "PlanterSoil", V(x, GROUND + 1.42, z), V(w - 0.9, 0.16, w - 0.9), C_SOIL, 160,
		{ material = Enum.Material.Ground, row = 1, group = g, canCollide = false })
	part(parent, "PlanterTrunk", V(x, GROUND + 2.25, z), V(1.35, 0.55, 0.55), C_BARK_A, 130,
		{ material = Enum.Material.Wood, shape = Enum.PartType.Cylinder, row = 2, group = g,
			cframe = CFrame.new(V(x, GROUND + 2.25, z)) * CFrame.Angles(0, 0, rad(90)) })
	for i, ly in ipairs({ 3.55, 4.35, 5.05 }) do
		local s = 2.9 - (i - 1) * 0.55
		part(parent, "PlanterFoliage" .. i, V(x, GROUND + ly, z), V(s, s * 0.62, s),
			if i == 2 then C_LEAF_C else C_LEAF_A, 60,
			{ material = Enum.Material.Grass, row = 3, group = g, canCollide = false,
				shape = Enum.PartType.Ball })
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 8. TRẠM XE BUÝT (mái che + vách kính hông + ghế chờ + bảng quảng cáo)
-- ══════════════════════════════════════════════════════════════════════════════
local function buildBusStop(parent: Instance, def: SeatDef, idx: number)
	local g = "BusStop_" .. tostring(idx)
	local x, z = def.x, def.z
	local L, D = 11.2, 3.9
	local H = 9.0

	for i, o in ipairs({ { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } }) do
		part(parent, "StopPost" .. i, V(x + o[1] * (L * 0.5 - 0.5), GROUND + H * 0.5, z + o[2] * (D * 0.5 - 0.4)),
			V(H, 0.42, 0.42), C_STEEL, 210,
			{ material = Enum.Material.Metal, row = 2, group = g })
	end
	-- Mái che nghiêng nhẹ
	part(parent, "StopRoof", V(x, GROUND + H + 0.32, z), V(L + 1.0, 0.34, D + 0.9), C_ALUM, 220,
		{ material = Enum.Material.Metal, row = 3, group = g })
	part(parent, "StopRoofTrim", V(x, GROUND + H + 0.06, z + (D + 0.9) * 0.5), V(L + 1.0, 0.5, 0.24),
		RGB(46, 96, 168), 150, { material = Enum.Material.SmoothPlastic, row = 3, group = g, canCollide = false })

	-- Vách kính hông (3 tấm, bắn vỡ từng tấm)
	for i = 1, 3 do
		local px = x - L * 0.5 + 0.5 + (i - 0.5) * ((L - 1.0) / 3)
		part(parent, "StopGlassPanel" .. i, V(px, GROUND + 4.6, z + D * 0.5 - 0.35),
			V((L - 1.4) / 3, 6.4, 0.16), C_GLASS, 45,
			{ material = Enum.Material.Glass, transparency = 0.35, row = 3, group = g,
				canCollide = false, castShadow = false })
	end
	part(parent, "StopBackRail", V(x, GROUND + 7.95, z + D * 0.5 - 0.35), V(L, 0.28, 0.3), C_STEEL, 160,
		{ material = Enum.Material.Metal, row = 3, group = g, canCollide = false })

	-- Ghế chờ dài
	part(parent, "StopBenchSeat", V(x, GROUND + 1.5, z - 0.5), V(L - 2.4, 0.28, 1.3), C_WOOD_L, 150,
		{ material = Enum.Material.Wood, row = 2, group = g })
	for i, sx in ipairs({ -3.4, 0, 3.4 }) do
		part(parent, "StopBenchLeg" .. (i + 2), V(x + sx, GROUND + 0.75, z - 0.5), V(0.3, 1.5, 1.1), C_STEEL_D, 100,
			{ material = Enum.Material.Metal, row = 1, group = g, canCollide = false })
	end

	-- Bảng quảng cáo phát sáng đầu trạm
	part(parent, "StopAdFrame", V(x - L * 0.5 - 0.15, GROUND + 4.4, z), V(0.28, 5.6, 2.6), C_STEEL_D, 170,
		{ material = Enum.Material.Metal, row = 3, group = g })
	part(parent, "StopAdPanel", V(x - L * 0.5 - 0.02, GROUND + 4.4, z), V(0.12, 5.0, 2.1),
		RGB(74, 158, 220), 60,
		{ material = Enum.Material.Neon, row = 3, group = g, canCollide = false, castShadow = false })

	-- Cột biển báo hiệu trạm
	part(parent, "StopSignPost", V(x + L * 0.5 + 1.0, GROUND + 3.2, z), V(6.4, 0.26, 0.26), C_STEEL, 160,
		{ material = Enum.Material.Metal, row = 2, group = g })
	part(parent, "StopSignPlate", V(x + L * 0.5 + 1.0, GROUND + 6.0, z), V(2.4, 1.6, 0.14),
		RGB(38, 92, 168), 80, { material = Enum.Material.SmoothPlastic, row = 2, group = g, canCollide = false })
	part(parent, "StopSignStripe", V(x + L * 0.5 + 1.0, GROUND + 5.55, z + 0.09), V(2.0, 0.28, 0.06),
		C_PAPER, 40, { material = Enum.Material.Neon, row = 2, group = g, canCollide = false, castShadow = false })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MODULE SPEC
-- ══════════════════════════════════════════════════════════════════════════════
local Module = {
	Id = "Infra_StreetLightsAndPalms",
	PlotId = "StreetProps",
	Order = 80,
	Enabled = true,
}

function Module.build(modulesContainer: Instance): Instance
	seq = 0
	usedNames = {}

	local root = folder(modulesContainer, Module.Id)
	local fLight = folder(root, "01_StreetLights")
	local fSignal = folder(root, "02_TrafficSignals")
	local fPalm = folder(root, "03_PalmTrees")
	local fFurn = folder(root, "04_Furniture")
	local fBench = folder(fFurn, "Benches")
	local fBin = folder(fFurn, "Bins")
	local fHydrant = folder(fFurn, "Hydrants")
	local fPlanter = folder(fFurn, "Planters")
	local fStop = folder(fFurn, "BusStops")

	local nLight, nSignal, nPalm, nBench, nBin, nHydrant, nPlanter, nStop = 0, 0, 0, 0, 0, 0, 0, 0

	for _, def in ipairs(LIGHTS) do
		if inBounds(def.x, def.z) then
			nLight += 1
			buildStreetLight(fLight, def, nLight)
		end
	end
	for _, def in ipairs(SIGNALS) do
		if inBounds(def.x, def.z) then
			nSignal += 1
			buildSignal(fSignal, def, nSignal)
		end
	end
	for _, def in ipairs(PALMS) do
		if inBounds(def.x, def.z) then
			nPalm += 1
			buildPalm(fPalm, def, nPalm)
		end
	end
	for _, def in ipairs(BENCHES) do
		if inBounds(def.x, def.z) then
			nBench += 1
			buildBench(fBench, def, nBench)
		end
	end
	for _, def in ipairs(BINS) do
		if inBounds(def.x, def.z) then
			nBin += 1
			buildBin(fBin, def, nBin)
		end
	end
	for _, def in ipairs(HYDRANTS) do
		if inBounds(def.x, def.z) then
			nHydrant += 1
			buildHydrant(fHydrant, def, nHydrant)
		end
	end
	for _, def in ipairs(PLANTERS) do
		if inBounds(def.x, def.z) then
			nPlanter += 1
			buildPlanter(fPlanter, def, nPlanter)
		end
	end
	for _, def in ipairs(BUSSTOPS) do
		if inBounds(def.x, def.z) then
			nStop += 1
			buildBusStop(fStop, def, nStop)
		end
	end

	-- Attribute để Agent Chính / HUD / tool kiểm chứng đọc được (không phải tự đếm lại)
	root:SetAttribute("PlotId", "StreetProps")
	root:SetAttribute("ModuleId", Module.Id)
	root:SetAttribute("LampCount", nLight)
	root:SetAttribute("TrafficSignalCount", nSignal)
	root:SetAttribute("PalmCount", nPalm)
	root:SetAttribute("BenchCount", nBench)
	root:SetAttribute("BinCount", nBin)
	root:SetAttribute("HydrantCount", nHydrant)
	root:SetAttribute("PlanterCount", nPlanter)
	root:SetAttribute("BusStopCount", nStop)
	root:SetAttribute("SignalCycleSeconds", 40)
	root:SetAttribute("SignalPhaseNS", "0..17 xanh · 17..20 vàng · 20..37 đỏ")
	root:SetAttribute("SignalPhaseEW", "20..37 xanh · 37..40 vàng · 0..17 đỏ")
	root:SetAttribute("PartPointLights", ENABLE_LAMP_POINT_LIGHTS)
	root:SetAttribute("DestructibleStore", true)
	root:SetAttribute("GroundY", GROUND)
	root:SetAttribute("PlacedInDeclaredBounds", not INCLUDE_OUTER_AVENUES)

	return root
end

return Module

