--!strict
--[[
	Plot_D2_MazeBankTower.luau
	THÁP TÀI CHÍNH MAZE BANK PLAZA & TOWER — ô Plot_D2 (PILLBOX HILL)

	Vùng xây: X −83..83 · Z −199..−63 · mặt nền Y = 1.15 (theo WorldGrid.luau).
	Mặt tiền hướng Nam (+Z) nhìn ra Olympic Fwy và Quảng trường Legion Square.

	KIẾN TRÚC
	  • Plaza 2 bậc thang, đài phun nước bán nguyệt, 4 chậu cây, cột cờ, ghế đá, đèn sân.
	  • Sảnh giao dịch thông tầng 19.0 studs: sàn cẩm thạch khảm, quầy lễ tân chữ L,
	    4 thang máy kính + bảng tầng, cổng dò kim loại + turnstile, sofa da, gác lửng có
	    lan can kính, đèn chùm, biển vàng "MAZE BANK", cầu thang đôi.
	  • Thân tháp thu dần 6 tầng kính, mỗi tầng nhỏ hơn 3 studs mỗi cạnh, có trụ góc bậc thang,
	    diềm ngang (spandrel), lam đứng; MỖI Ô KÍNH có máu ẩn riêng (bắn vỡ từng tấm).
	  • Tầng kỹ thuật + sân thượng: bãi đáp trực thăng TRÒN "MAZE BANK" đỏ/trắng, chữ H,
	    đèn hiệu nhấp nháy, cột ăng-ten, lan can an toàn.
	  • 2 cánh đế Đông/Tây: hầm đỗ xe, cửa cuốn ô tô 18 × 12 studs, vạch đỗ + gờ chặn bánh.

	HIỆU NĂNG (docs/PERFORMANCE.md)
	  Mọi part CanTouch = false và EnableFluidForces = false; part < 1.6 stud tắt CanCollide;
	  kính / neon / part nhỏ tắt CastShadow; sàn & mái mỏng rộng LUÔN CanCollide = true;
	  SurfaceGui đặt MaxDistance = 340 với PixelsPerStud giới hạn canvas ≤ 1100 px;
	  KHÔNG dùng TextScaled (dùng TextSize cố định).

	GHI CHÚ: PartBuilder thực tế cung cấp part / wedge / masonryWall / staircase …
	Các tiện ích box / brickWall / segmentedRow bên dưới là lớp bọc cục bộ gọi thẳng
	vào PartBuilder và LUÔN truyền `integrity` → mọi khối đều có máu ẩn phá huỷ được.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartBuilder = require(Shared:WaitForChild("World"):WaitForChild("PartBuilder"))

---------------------------------------------------------------------------------------------------
-- 1. HẰNG SỐ TOẠ ĐỘ (khớp WorldGrid: Plot_D2 = X −92..92, Z −208..−54; trừ vỉa hè 9 → −83..83 / −199..−63)
---------------------------------------------------------------------------------------------------
local V = Vector3.new
local RGB = Color3.fromRGB

local GROUND = 1.15          -- mặt nền ô đất (WorldGrid)
local PAVE_TOP = 1.22        -- mặt sàn plaza (không trùng phẳng 1.15)
local T1_TOP = 2.70          -- bậc plaza thứ nhất
local T2_TOP = 4.14          -- bậc plaza thứ hai (đỉnh đế)
local FLOOR = 4.20           -- mặt sàn hoàn thiện sảnh (cẩm thạch)
local LOBBY_CEIL = 23.20     -- trần sảnh → thông tầng 19.0 studs
local ROOF_TOP = 154.40      -- đỉnh sàn mái (nắp buồng kỹ thuật)
local PAD_TOP = 155.10       -- mặt bãi đáp trực thăng
local MAST_TOP = 164.00      -- đỉnh cột ăng-ten (tổng cao 164 ≫ 120)

-- Khối đế / thân tháp
local TOWER = { x0 = -50, x1 = 50, z0 = -182, z1 = -104 }
local HALF_W = 50

-- Plaza & sân trước
local PLZ = { x0 = -83, x1 = 83, z0 = -104, z1 = -63 }
local T1 = { x0 = -60, x1 = 60, z0 = -188, z1 = -92 }
local T2 = { x0 = -56, x1 = 56, z0 = -186, z1 = -98 }

-- Cánh đế Đông / Tây (hầm đỗ xe)
local EWING = { x0 = 62, x1 = 83, z0 = -178, z1 = -96 }
local WWING = { x0 = -83, x1 = -62, z0 = -178, z1 = -96 }

-- Bãi đáp trực thăng
local HELI = { cx = 0, cz = -143, r = 15 }

-- 6 tầng kính thu dần + tầng kỹ thuật (mỗi tầng nhỏ hơn 3 studs mỗi cạnh)
type Level = {
	name: string,
	x0: number, x1: number,
	z0: number, z1: number,
	y0: number, y1: number,
}

local LEVELS: { Level } = {
	{ name = "L1", x0 = -47, x1 = 47, z0 = -179, z1 = -107, y0 = 23.20, y1 = 43.20 },
	{ name = "L2", x0 = -45, x1 = 45, z0 = -177, z1 = -109, y0 = 43.20, y1 = 63.20 },
	{ name = "L3", x0 = -43, x1 = 43, z0 = -175, z1 = -111, y0 = 63.20, y1 = 83.20 },
	{ name = "L4", x0 = -41, x1 = 41, z0 = -173, z1 = -113, y0 = 83.20, y1 = 103.20 },
	{ name = "L5", x0 = -39, x1 = 39, z0 = -171, z1 = -115, y0 = 103.20, y1 = 123.20 },
	{ name = "L6", x0 = -37, x1 = 37, z0 = -169, z1 = -117, y0 = 123.20, y1 = 143.20 },
}

local MECH: Level = { name = "MECH", x0 = -24, x1 = 24, z0 = -158, z1 = -128, y0 = 143.20, y1 = 153.20 }

---------------------------------------------------------------------------------------------------
-- 2. BẢNG MÀU
---------------------------------------------------------------------------------------------------
local C_GOLD = RGB(198, 160, 62)
local C_GOLD_LT = RGB(236, 202, 112)
local C_GOLD_DK = RGB(146, 114, 38)
local C_GLASS_GOLD = RGB(64, 88, 104)
local C_GLASS = RGB(96, 132, 154)
local C_GLASS_LT = RGB(150, 188, 212)
local C_CHAR = RGB(38, 42, 50)
local C_CHAR_LT = RGB(62, 68, 78)
local C_STEEL = RGB(140, 148, 158)
local C_STEEL_LT = RGB(186, 192, 200)
local C_MARBLE = RGB(238, 234, 226)
local C_MARBLE_DK = RGB(202, 196, 186)
local C_MARBLE_VN = RGB(176, 168, 158)
local C_WHITE = RGB(244, 246, 248)
local C_RED = RGB(198, 42, 40)
local C_NAVY = RGB(26, 38, 66)
local C_NEONW = RGB(232, 240, 255)
local C_NEONB = RGB(96, 176, 255)
local C_WOOD = RGB(108, 78, 52)
local C_LEATHER = RGB(84, 54, 38)
local C_LEAF = RGB(52, 108, 66)
local C_LEAF_DK = RGB(34, 76, 46)
local C_PAVE = RGB(178, 176, 170)
local C_PAVE_DK = RGB(168, 166, 160)
local C_ASPHALT = RGB(54, 56, 62)
local C_WATER = RGB(64, 152, 196)
local C_BRONZE = RGB(150, 104, 58)
local C_YELLOW = RGB(240, 202, 74)

---------------------------------------------------------------------------------------------------
-- 3. TIỆN ÍCH GHÉP KHỐI + TỰ ĐỘNG ÁP LUẬT HIỆU NĂNG
---------------------------------------------------------------------------------------------------
type BoxOpts = {
	material: Enum.Material?,
	transparency: number?,
	reflectance: number?,
	canCollide: boolean?,
	castShadow: boolean?,
	group: string?,
	row: number?,
	structural: boolean?,
	walkable: boolean?,
	query: boolean?,
	shape: Enum.PartType?,
}

type SignText = {
	text: string,
	color: Color3?,
	font: Enum.Font?,
	ths: number?,
	sw: number?,
	sh: number?,
	px: number?,
	py: number?,
}

local function folder(parent: any, name: string): any
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function maxDim(size: Vector3): number
	return math.max(size.X, math.max(size.Y, size.Z))
end

-- Áp đúng 5 quy tắc PerfOptimizer ngay trong module (không chờ lớp tối ưu toàn cục).
local function resolvePerf(size: Vector3, o: BoxOpts): (boolean, boolean, boolean)
	local md: number = maxDim(size)
	local isThin: boolean = size.X <= 1.3 or size.Y <= 1.3 or size.Z <= 1.3
	local isWide: boolean = size.X >= 4.0 and size.Z >= 4.0
	-- Sàn / mái mỏng rộng → LUÔN va chạm để người chơi không rơi xuyên
	local walkable: boolean = (o.walkable == true) or (isThin and isWide and size.Y <= 1.3)
	local isGlass: boolean = o.material == Enum.Material.Glass
	local isNeon: boolean = o.material == Enum.Material.Neon
	local seeThrough: boolean = (o.transparency or 0) > 0.05

	local collide: boolean
	if o.canCollide ~= nil then
		collide = o.canCollide :: boolean
	elseif walkable then
		collide = true
	elseif md < 1.6 then
		collide = false
	elseif isGlass or isNeon then
		collide = false
	else
		collide = true
	end

	local shadow: boolean
	if o.castShadow ~= nil then
		shadow = o.castShadow :: boolean
	else
		shadow = not (md < 3.0 or isGlass or isNeon or seeThrough)
	end

	return collide, shadow, walkable
end

-- box: 1 khối PartBuilder.part CÓ MÁU ẨN. structural = true → móng/kết cấu không phá huỷ.
local function box(
	parent: any,
	name: string,
	pos: Vector3,
	size: Vector3,
	color: Color3,
	integrity: number?,
	opts: BoxOpts?
): any
	local o: BoxOpts = opts or {}
	local structural: boolean = o.structural == true
	local hp: number? = integrity
	if not structural and hp == nil then
		hp = 120
	end

	local collide: boolean, shadow: boolean, walkable: boolean = resolvePerf(size, o)
	if walkable then
		collide = true
	end

	local part = PartBuilder.part({
		name = name,
		parent = parent,
		pos = pos,
		size = size,
		color = color,
		material = o.material,
		transparency = o.transparency,
		reflectance = o.reflectance,
		shape = o.shape,
		canCollide = collide,
		castShadow = shadow,
		destructible = (not structural),
		integrity = hp,
		fractureGroup = o.group or "MazeBank",
		structuralRow = o.row,
	})

	-- Luật cứng: mọi part CanTouch = false; khối phá huỷ luôn CanQuery = true (đạn + quét xe)
	if part then
		part.CanTouch = false
		part.EnableFluidForces = false
		if o.query ~= nil then
			part.CanQuery = o.query
		else
			part.CanQuery = (not structural)
		end
	end
	return part
end

-- brickWall: tường gạch xếp so le từng viên (mỗi viên một bể máu riêng)
local function brickWall(
	parent: any,
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
	group: string,
	blockLen: number?
): any
	local wall = PartBuilder.masonryWall({
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
		blockLength = blockLen or 6.0,
		mortarGap = 0.08,
		baseColor = color,
		material = Enum.Material.Brick,
		colorJitter = 5,
		integrity = integrity,
		fractureGroup = group,
		addCoping = false,
	})
	-- Luật hiệu năng: mọi viên gạch CanTouch = false, CanQuery = true, không đổ bóng
	for _, ch in ipairs(wall:GetChildren()) do
		if ch.ClassName == "Part" then
			ch.Name = name .. "_" .. ch.Name
			ch.CanTouch = false
			ch.EnableFluidForces = false
			ch.CanQuery = true
			ch.CastShadow = false
		end
	end
	return wall
end

-- segmentedRow: dãy khối lặp (ô kính, lam, nan cửa cuốn, sản phẩm…)
local function segmentedRow(
	parent: any,
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

-- signText: SurfaceGui trên 1 mặt tấm biển. Canvas ≤ 1100 px, MaxDistance = 340, KHÔNG TextScaled.
local function signText(panel: any, face: Enum.NormalId, entries: { SignText }): any
	local w: number, h: number
	if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
		w, h = panel.Size.X, panel.Size.Y
	elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		w, h = panel.Size.Z, panel.Size.Y
	else
		w, h = panel.Size.X, panel.Size.Z
	end

	-- PixelsPerStud giới hạn để canvas không vượt 1100 px (docs/PERFORMANCE.md)
	local pps: number = math.min(1100 / math.max(w, 0.1), 1100 / math.max(h, 0.1), 32)
	pps = math.max(4, math.floor(pps * 100) / 100)

	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pps
	gui.MaxDistance = 340
	gui.LightInfluence = 0.12
	gui.Parent = panel

	for _, e in ipairs(entries) do
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.fromScale(e.sw or 0.92, e.sh or 0.5)
		lbl.Position = UDim2.fromScale(e.px or 0.04, e.py or 0.1)
		lbl.Font = e.font or Enum.Font.GothamBlack
		lbl.TextScaled = false
		lbl.TextSize = math.max(8, math.floor((e.ths or 2.0) * pps))
		lbl.TextColor3 = e.color or C_WHITE
		lbl.Text = e.text
		lbl.Parent = gui
	end
	return gui
end

-- signBoard: tấm biển nền + chữ trên nhiều mặt
local function signBoard(
	parent: any,
	name: string,
	pos: Vector3,
	size: Vector3,
	bg: Color3,
	faces: { Enum.NormalId },
	entries: { SignText },
	integrity: number?
): any
	local panel = box(parent, name, pos, size, bg, integrity or 160, {
		material = Enum.Material.Metal,
		group = "Signs",
	})
	for _, face in ipairs(faces) do
		signText(panel, face, entries)
	end
	return panel
end

-- stairs: bậc thang chính xác do mình kiểm soát (không sinh tường má ngoài ý muốn)
local function stairs(
	parent: any,
	name: string,
	cx: number,
	zLow: number,
	width: number,
	baseY: number,
	rise: number,
	run: number,
	steps: number,
	color: Color3
): ()
	local stepRise: number = rise / steps
	local stepRun: number = run / steps
	for s = 1, steps do
		local h: number = stepRise * s
		local zc: number = zLow - (s - 0.5) * stepRun
		box(parent, name .. "_Step" .. s, V(cx, baseY + h * 0.5, zc), V(width, h, stepRun + 0.12), color, 240, {
			material = Enum.Material.Concrete,
			group = "Stairs",
		})
	end
end

---------------------------------------------------------------------------------------------------
-- 4. PLAZA TRƯỚC + ĐÀI PHUN NƯỚC + CÂY XANH
---------------------------------------------------------------------------------------------------
local function buildPlaza(fPlz: any): ()
	-- ===== A. SÂN LÁT ĐÁ (lưới 8 × 7.25 studs, so le 2 màu, mỗi ô một bể máu) =====
	local cols: number = 14
	local rows: number = 3
	local tileW: number = 160 / cols          -- 11.43
	local tileD: number = 29 / rows           -- 9.67
	for c = 1, cols do
		for r = 1, rows do
			local x: number = -80 + (c - 0.5) * tileW
			local z: number = -92 + (r - 0.5) * tileD
			local shade: Color3 = if (c + r) % 2 == 0 then C_PAVE else C_PAVE_DK
			box(fPlz, string.format("Paver_%d_%d", c, r), V(x, 1.185, z), V(tileW - 0.12, 0.07, tileD - 0.12),
				shade, 150, { material = Enum.Material.Sandstone, walkable = true, group = "PlazaPavers" })
		end
	end

	-- Viền đá đậm quanh sân + lối đi trung tâm dẫn vào bậc thang
	box(fPlz, "PlazaBorder_SW", V(-44.25, 1.20, -63.8), V(71.5, 0.1, 1.6), C_MARBLE_DK, 200,
		{ material = Enum.Material.Granite, walkable = true })
	box(fPlz, "PlazaBorder_SE", V(44.25, 1.20, -63.8), V(71.5, 0.1, 1.6), C_MARBLE_DK, 200,
		{ material = Enum.Material.Granite, walkable = true })
	box(fPlz, "PlazaBorder_W", V(-82.2, 1.20, -78), V(1.6, 0.1, 28.4), C_MARBLE_DK, 200,
		{ material = Enum.Material.Granite, walkable = true })
	box(fPlz, "PlazaBorder_E", V(82.2, 1.20, -78), V(1.6, 0.1, 28.4), C_MARBLE_DK, 200,
		{ material = Enum.Material.Granite, walkable = true })

	-- Thảm đá hoa văn (medallion) giữa sân: 3 vòng đồng tâm + 8 cánh sao
	for ring = 1, 3 do
		local rr: number = 4 + ring * 3
		segmentedRow(fPlz, "MedallionRing" .. ring, 12,
			function(i)
				local a: number = (i - 1) / 16 * math.pi * 2
				return V(math.cos(a) * rr, 1.245, -78 + math.sin(a) * rr)
			end,
			function(i) return V(2.0, 0.05, 2.0) end,
			function(i) return if ring == 2 then C_GOLD else C_MARBLE end, 60,
			{ material = Enum.Material.Marble, walkable = true, canCollide = false })
	end
	segmentedRow(fPlz, "MedallionSpoke", 8,
		function(i)
			local a: number = (i - 1) / 8 * math.pi * 2
			return V(math.cos(a) * 8.5, 1.305, -78 + math.sin(a) * 8.5)
		end,
		function(i) return V(6.0, 0.05, 0.7) end,
		function(i) return C_GOLD_LT end, 50,
		{ material = Enum.Material.Marble, walkable = true, canCollide = false })

	-- ===== B. ĐÀI PHUN NƯỚC (bát giác, tâm X=0 Z=-80) =====
	local fx, fz = 0, -80
	local ringR: number = 11.5
	-- 4 cạnh dài
	box(fPlz, "FountainRim_N", V(fx, 1.92, fz - ringR + 0.9), V(2 * ringR - 1.8, 1.44, 1.8), C_MARBLE, 260,
		{ material = Enum.Material.Marble, group = "Fountain" })
	box(fPlz, "FountainRim_S", V(fx, 1.92, fz + ringR - 0.9), V(2 * ringR - 1.8, 1.44, 1.8), C_MARBLE, 260,
		{ material = Enum.Material.Marble, group = "Fountain" })
	box(fPlz, "FountainRim_W", V(fx - ringR + 0.9, 1.90, fz), V(1.8, 1.40, 2 * ringR - 1.8), C_MARBLE, 260,
		{ material = Enum.Material.Marble, group = "Fountain" })
	box(fPlz, "FountainRim_E", V(fx + ringR - 0.9, 1.90, fz), V(1.8, 1.40, 2 * ringR - 1.8), C_MARBLE, 260,
		{ material = Enum.Material.Marble, group = "Fountain" })
	-- 4 góc vát (khối vuông đặt ở góc → đọc thành bát giác)
	for i, sx in ipairs({ -1, 1 }) do
		for j, sz in ipairs({ -1, 1 }) do
			box(fPlz, string.format("FountainCorner_%d_%d", i, j),
				V(fx + sx * (ringR - 2.75), 1.88, fz + sz * (ringR - 2.75)), V(5.0, 1.36, 5.0), C_MARBLE_DK, 240,
				{ material = Enum.Material.Marble, group = "Fountain" })
		end
	end
	-- Mặt nước (trong suốt, phát sáng nhẹ)
	box(fPlz, "FountainWater", V(fx, 1.62, fz), V(2 * ringR - 4.2, 0.12, 2 * ringR - 4.2), C_WATER, 40,
		{ material = Enum.Material.Glass, transparency = 0.25, canCollide = false, castShadow = false,
			group = "Fountain" })
	-- Bệ trung tâm 3 tầng + 4 vòi phun
	box(fPlz, "FountainBase", V(fx, 2.30, fz), V(7.0, 0.6, 7.0), C_MARBLE_DK, 220,
		{ material = Enum.Material.Marble, group = "Fountain" })
	box(fPlz, "FountainPedestal", V(fx, 3.30, fz), V(3.6, 2.0, 3.6), C_MARBLE, 200,
		{ material = Enum.Material.Marble, group = "Fountain" })
	box(fPlz, "FountainBowl", V(fx, 4.55, fz), V(6.2, 0.5, 6.2), C_MARBLE, 180,
		{ material = Enum.Material.Marble, group = "Fountain" })
	box(fPlz, "FountainBowlTop", V(fx, 5.10, fz), V(4.6, 0.6, 4.6), C_MARBLE_DK, 160,
		{ material = Enum.Material.Marble, group = "Fountain" })
	-- Vòi phun nước (4 tia neon xanh) + tia trung tâm
	for i = 0, 3 do
		local a: number = i / 4 * math.pi * 2
		box(fPlz, "FountainJet_" .. (i + 1),
			V(fx + math.cos(a) * 2.6, 6.0, fz + math.sin(a) * 2.6), V(0.55, 2.2, 0.55), C_GLASS_LT, 30,
			{ material = Enum.Material.Glass, transparency = 0.35, canCollide = false, castShadow = false })
	end
	box(fPlz, "FountainJetCenter", V(fx, 6.6, fz), V(0.7, 3.4, 0.7), C_GLASS_LT, 30,
		{ material = Enum.Material.Glass, transparency = 0.35, canCollide = false, castShadow = false })
	box(fPlz, "FountainJetFinial", V(fx, 8.5, fz), V(1.3, 0.7, 1.3), C_GOLD, 70,
		{ material = Enum.Material.Metal, canCollide = false })
	-- Đèn nước dưới đáy (neon xanh)
	segmentedRow(fPlz, "FountainLight", 8,
		function(i)
			local a: number = (i - 1) / 8 * math.pi * 2
			return V(fx + math.cos(a) * 9.0, 1.70, fz + math.sin(a) * 9.0)
		end,
		function(i) return V(1.1, 0.1, 1.1) end,
		function(i) return C_NEONB end, 25,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false })

	-- ===== C. 4 CHẬU CÂY LỚN Ở 4 GÓC SÂN =====
	for i, px in ipairs({ -46, 46 }) do
		for j, pz in ipairs({ -70, -88 }) do
			local pidx: string = string.format("%d_%d", i, j)
			local planter = folder(fPlz, "Planter_" .. pidx)
			box(planter, "Pot_" .. pidx, V(px, 1.85, pz), V(6.2, 1.4, 6.2), C_MARBLE_DK, 220,
				{ material = Enum.Material.Concrete, group = "Planters" })
			box(planter, "PotRim_" .. pidx, V(px, 2.60, pz), V(6.8, 0.30, 6.8), C_MARBLE, 200,
				{ material = Enum.Material.Concrete, group = "Planters" })
			box(planter, "Soil_" .. pidx, V(px, 2.72, pz), V(5.6, 0.20, 5.6), RGB(74, 56, 40), 100,
				{ material = Enum.Material.Ground, canCollide = false })
			-- Thân + 3 tầng tán lá
			box(planter, "Trunk_" .. pidx, V(px, 4.6, pz), V(1.1, 3.8, 1.1), C_BRONZE, 150,
				{ material = Enum.Material.Wood })
			box(planter, "Canopy1_" .. pidx, V(px, 6.9, pz), V(6.4, 2.6, 6.4), C_LEAF_DK, 90,
				{ material = Enum.Material.Grass })
			box(planter, "Canopy2_" .. pidx, V(px, 8.6, pz), V(5.0, 2.2, 5.0), C_LEAF, 80,
				{ material = Enum.Material.Grass })
			box(planter, "Canopy3_" .. pidx, V(px, 10.0, pz), V(3.2, 1.6, 3.2), C_LEAF, 70,
				{ material = Enum.Material.Grass })
			-- Vành đá quanh gốc
			box(planter, "Ring_" .. pidx, V(px, 2.885, pz), V(4.4, 0.08, 4.4), C_PAVE_DK, 60,
				{ material = Enum.Material.Pebble, canCollide = false })
		end
	end

	-- ===== D. GHẾ ĐÁ + THÙNG RÁC DỌC LỐI ĐI =====
	for i, bx in ipairs({ -30, -16, 16, 30 }) do
		box(fPlz, "BenchSeat_" .. i, V(bx, 2.05, -69.2), V(7.4, 0.45, 2.2), C_MARBLE, 160,
			{ material = Enum.Material.Marble, group = "Benches" })
		box(fPlz, "BenchBack_" .. i, V(bx, 2.85, -70.1), V(7.4, 1.3, 0.42), C_MARBLE_DK, 150,
			{ material = Enum.Material.Marble, group = "Benches" })
		for _, lx in ipairs({ bx - 3.0, bx + 3.0 }) do
			box(fPlz, string.format("BenchLeg_%d_%.0f", i, lx), V(lx, 1.62, -69.2), V(0.6, 0.9, 1.9), C_CHAR, 140,
				{ material = Enum.Material.Metal, group = "Benches" })
		end
	end
	for i, tx in ipairs({ -54, 54 }) do
		box(fPlz, "TrashBin_" .. i, V(tx, 2.15, -70), V(2.4, 2.0, 2.4), C_CHAR, 90,
			{ material = Enum.Material.Metal, group = "Props" })
		box(fPlz, "TrashLid_" .. i, V(tx, 3.25, -70), V(2.7, 0.3, 2.7), C_GOLD_DK, 80,
			{ material = Enum.Material.Metal, group = "Props" })
	end

	-- ===== E. 4 CỘT CỜ ĐỐI XỨNG HAI BÊN LỐI VÀO =====
	for i, cx in ipairs({ -70, -56, 56, 70 }) do
		local fdir: number = if cx < 0 then -1 else 1
		local pole = folder(fPlz, "FlagPole_" .. i)
		box(pole, "FlagBase_" .. i, V(cx, 1.55, -69.0), V(2.6, 0.8, 2.6), C_MARBLE_DK, 180,
			{ material = Enum.Material.Concrete, group = "Flags" })
		box(pole, "FlagColumn_" .. i, V(cx, 10.0, -69.0), V(0.55, 16.8, 0.55), C_STEEL_LT, 130,
			{ material = Enum.Material.Metal, group = "Flags" })
		box(pole, "FlagFinial_" .. i, V(cx, 18.75, -69.0), V(0.9, 0.9, 0.9), C_GOLD, 60,
			{ material = Enum.Material.Metal, group = "Flags" })
		-- Lá cờ (2 tấm xếp lớp, mỗi tấm một bể máu)
		local flagCol: Color3 = if i % 2 == 0 then C_RED else C_NAVY
		box(pole, "Flag_" .. i, V(cx + fdir * 3.0, 16.4, -69.0), V(6.0, 3.6, 0.16), flagCol, 45,
			{ material = Enum.Material.Fabric, canCollide = false, castShadow = false, group = "Flags" })
		box(pole, "FlagStripe_" .. i, V(cx + fdir * 3.0, 16.4, -68.91), V(6.0, 0.6, 0.1), C_WHITE, 30,
			{ material = Enum.Material.Fabric, canCollide = false, castShadow = false, group = "Flags" })
	end

	-- ===== F. CỌC CHẮN + ĐÈN SÂN =====
	for bi, bx in ipairs({ -74, -62, -50, -38, -26, 26, 38, 50, 62, 74 }) do
		box(fPlz, "PlazaBollard_" .. bi, V(bx, 2.10, -63.9), V(0.8, 1.9, 0.8), C_CHAR, 80,
			{ material = Enum.Material.Metal, group = "Bollards" })
	end
	for i, lx in ipairs({ -70, -58, 58, 70 }) do
		local lamp = folder(fPlz, "PlazaLamp_" .. i)
		box(lamp, "LampBase_" .. i, V(lx, 1.55, -66), V(1.6, 0.8, 1.6), C_CHAR, 160,
			{ material = Enum.Material.Metal, group = "PlazaLamps" })
		box(lamp, "LampPost_" .. i, V(lx, 7.0, -66), V(0.55, 10.4, 0.55), C_CHAR, 130,
			{ material = Enum.Material.Metal, group = "PlazaLamps" })
		box(lamp, "LampHead_" .. i, V(lx, 12.6, -66), V(2.0, 0.6, 2.0), C_GOLD_DK, 90,
			{ material = Enum.Material.Metal, group = "PlazaLamps" })
		box(lamp, "LampGlobe_" .. i, V(lx, 13.3, -66), V(1.5, 0.9, 1.5), C_NEONW, 50,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "PlazaLamps" })
	end
end

---------------------------------------------------------------------------------------------------
-- 5. CURTAIN WALL DÙNG CHUNG (ô kính rời + trụ nhôm + lam đứng)
---------------------------------------------------------------------------------------------------
-- axis "X": tường chạy dọc X tại Z = fixed. axis "Z": chạy dọc Z tại X = fixed.
-- outSign: hướng mặt ngoài (+1 / −1) theo trục vuông góc, dùng cho lam & diềm nhô ra.
local function curtainLine(
	parent: any,
	tag: string,
	axis: "X" | "Z",
	fixed: number,
	a0: number,
	a1: number,
	y0: number,
	y1: number,
	bayW: number,
	paneHP: number,
	outSign: number,
	glassColor: Color3?
): ()
	local len: number = a1 - a0
	if len <= 0.5 or y1 - y0 <= 0.3 then
		return
	end
	local bays: number = math.max(1, math.floor(len / bayW + 0.5))
	local bw: number = len / bays
	local gc: Color3 = glassColor or C_GLASS
	local cw: number = (a0 + a1) * 0.5
	local yc: number = (y0 + y1) * 0.5
	local hgt: number = y1 - y0

	-- Ô kính rời (mỗi ô một bể máu riêng → bắn vỡ từng tấm)
	for i = 1, bays do
		local c: number = a0 + (i - 0.5) * bw
		local pw: number = bw - 0.5
		if axis == "X" then
			box(parent, string.format("%s_Pane%d", tag, i), V(c, yc, fixed), V(pw, hgt, 0.22), gc, paneHP,
				{ material = Enum.Material.Glass, transparency = 0.42, castShadow = false, group = tag })
		else
			box(parent, string.format("%s_Pane%d", tag, i), V(fixed, yc, c), V(0.22, hgt, pw), gc, paneHP,
				{ material = Enum.Material.Glass, transparency = 0.42, castShadow = false, group = tag })
		end
	end

	-- Trụ nhôm đứng giữa các ô
	for i = 0, bays do
		local c: number = a0 + i * bw
		if axis == "X" then
			box(parent, string.format("%s_Mullion%d", tag, i), V(c, yc, fixed), V(0.42, hgt, 0.80), C_CHAR, 170,
				{ material = Enum.Material.Metal, castShadow = false, group = tag .. "Frame" })
		else
			box(parent, string.format("%s_Mullion%d", tag, i), V(fixed, yc, c), V(0.80, hgt, 0.42), C_CHAR, 170,
				{ material = Enum.Material.Metal, castShadow = false, group = tag .. "Frame" })
		end
	end

	-- Lam đứng (fin) nhô ra ngoài mỗi 2 ô → sọc dọc đặc trưng của tháp tài chính
	local finY0: number = yc - hgt * 0.5
	local finH: number = hgt
	for i = 0, bays, 3 do
		local c: number = a0 + i * bw
		local off: number = outSign * 0.35
		if axis == "X" then
			box(parent, string.format("%s_Fin%d", tag, i), V(c, finY0 + finH * 0.5, fixed + off),
				V(0.62, finH, 1.00), C_GOLD_DK, 150,
				{ material = Enum.Material.Metal, castShadow = false, group = tag .. "Fins" })
		else
			box(parent, string.format("%s_Fin%d", tag, i), V(fixed + off, finY0 + finH * 0.5, c),
				V(1.00, finH, 0.62), C_GOLD_DK, 150,
				{ material = Enum.Material.Metal, castShadow = false, group = tag .. "Fins" })
		end
	end

	-- Diềm ngang trên & dưới (transom / spandrel) — hai mặt phẳng lệch hẳn khỏi kính
	if axis == "X" then
		box(parent, tag .. "_TransomTop", V(cw, y1 - 0.29, fixed), V(len, 0.70, 1.05), C_CHAR_LT, 190,
			{ material = Enum.Material.Metal, group = tag .. "Trim" })
		box(parent, tag .. "_TransomBot", V(cw, y0 + 0.36, fixed), V(len, 0.60, 1.05), C_CHAR_LT, 190,
			{ material = Enum.Material.Metal, group = tag .. "Trim" })
	else
		box(parent, tag .. "_TransomTop", V(fixed, y1 - 0.29, cw), V(1.05, 0.70, len), C_CHAR_LT, 190,
			{ material = Enum.Material.Metal, group = tag .. "Trim" })
		box(parent, tag .. "_TransomBot", V(fixed, y0 + 0.36, cw), V(1.05, 0.60, len), C_CHAR_LT, 190,
			{ material = Enum.Material.Metal, group = tag .. "Trim" })
	end
end

---------------------------------------------------------------------------------------------------
-- 6. KHỐI ĐẾ 2 BẬC THANG + CẦU THANG LÊN SẢNH
---------------------------------------------------------------------------------------------------
local function buildPodium(fPod: any): ()
	-- ===== Bậc 1 (thấp): X −60..60, Z −188..−92 =====
	box(fPod, "Terrace1", V((T1.x0 + T1.x1) * 0.5, (1.30 + T1_TOP) * 0.5, (T1.z0 + T1.z1) * 0.5),
		V(T1.x1 - T1.x0, T1_TOP - 1.30, T1.z1 - T1.z0), C_PAVE, 480,
		{ material = Enum.Material.Concrete, walkable = true, group = "Podium" })
	-- Nẹp đá mép bậc 1
	box(fPod, "Terrace1Nosing_S", V(0, T1_TOP - 0.10, T1.z1 + 0.0), V(T1.x1 - T1.x0, 0.36, 1.0), C_MARBLE_DK, 220,
		{ material = Enum.Material.Granite, walkable = true, group = "Podium" })
	box(fPod, "Terrace1Nosing_W", V(T1.x0, T1_TOP - 0.10, (T1.z0 + T1.z1) * 0.5), V(1.0, 0.36, T1.z1 - T1.z0), C_MARBLE_DK, 220,
		{ material = Enum.Material.Granite, walkable = true, group = "Podium" })
	box(fPod, "Terrace1Nosing_E", V(T1.x1, T1_TOP - 0.10, (T1.z0 + T1.z1) * 0.5), V(1.0, 0.36, T1.z1 - T1.z0), C_MARBLE_DK, 220,
		{ material = Enum.Material.Granite, walkable = true, group = "Podium" })

	-- ===== Bậc 2 (cao): X −56..56, Z −186..−98 =====
	box(fPod, "Terrace2", V((T2.x0 + T2.x1) * 0.5, (T1_TOP + T2_TOP) * 0.5, (T2.z0 + T2.z1) * 0.5),
		V(T2.x1 - T2.x0, T2_TOP - T1_TOP, T2.z1 - T2.z0), C_PAVE_DK, 460,
		{ material = Enum.Material.Concrete, walkable = true, group = "Podium" })
	box(fPod, "Terrace2Nosing_S", V(0, T2_TOP - 0.10, T2.z1), V(T2.x1 - T2.x0, 0.36, 1.0), C_MARBLE_DK, 220,
		{ material = Enum.Material.Granite, walkable = true, group = "Podium" })
	box(fPod, "Terrace2Nosing_W", V(T2.x0, T2_TOP - 0.10, (T2.z0 + T2.z1) * 0.5), V(1.0, 0.36, T2.z1 - T2.z0), C_MARBLE_DK, 220,
		{ material = Enum.Material.Granite, walkable = true, group = "Podium" })
	box(fPod, "Terrace2Nosing_E", V(T2.x1, T2_TOP - 0.10, (T2.z0 + T2.z1) * 0.5), V(1.0, 0.36, T2.z1 - T2.z0), C_MARBLE_DK, 220,
		{ material = Enum.Material.Granite, walkable = true, group = "Podium" })

	-- ===== Sàn cẩm thạch sảnh (mặt trên = FLOOR = 4.20) =====
	box(fPod, "LobbyFloorMarble", V(0, (T2_TOP + FLOOR) * 0.5, (TOWER.z0 + TOWER.z1) * 0.5),
		V(TOWER.x1 - TOWER.x0, FLOOR - T2_TOP, TOWER.z1 - TOWER.z0), C_MARBLE, nil,
		{ material = Enum.Material.Marble, walkable = true, structural = true, group = "LobbyFloor" })

	-- ===== CẦU THANG LỚN: plaza → bậc 1 → bậc 2 =====
	-- Cầu thang giữa (rộng 34) + 2 cầu thang phụ hai bên (rộng 12)
	stairs(fPod, "GrandStairA", 0, -86.0, 34, PAVE_TOP, T1_TOP - PAVE_TOP, 6.0, 4, C_MARBLE_DK)
	stairs(fPod, "GrandStairB", 0, -91.94, 30, T1_TOP, T2_TOP - T1_TOP, 6.0, 4, C_MARBLE)
	for i, sx in ipairs({ -40, 40 }) do
		stairs(fPod, "SideStairA" .. i, sx, -86.0, 12, PAVE_TOP, T1_TOP - PAVE_TOP, 6.0, 4, C_MARBLE_DK)
		stairs(fPod, "SideStairB" .. i, sx, -92.0, 10, T1_TOP, T2_TOP - T1_TOP, 6.0, 4, C_MARBLE)
	end

	-- Lan can đá hai bên cầu thang giữa (mỗi trụ một bể máu)
	for i, sx in ipairs({ -18.4, 18.4 }) do
		box(fPod, "StairRailA" .. i, V(sx, PAVE_TOP + 1.15, -89.0), V(1.0, 2.3, 6.4), C_MARBLE, 200,
			{ material = Enum.Material.Marble, group = "Stairs" })
		box(fPod, "StairRailB" .. i, V(sx, T1_TOP + 1.15, -95.0), V(1.0, 2.3, 6.4), C_MARBLE, 200,
			{ material = Enum.Material.Marble, group = "Stairs" })
	end

	-- ===== ĐẾ 2 BẬC Ở HAI BÊN: bồn hoa + đèn trụ =====
	for i, sx in ipairs({ -1, 1 }) do
		for j, sz in ipairs({ -1, 1 }) do
			local px: number = sx * 52
			local pz: number = -152 + sz * 26
			box(fPod, string.format("TerracePlanter_%d_%d", i, j), V(px, T2_TOP + 0.9, pz), V(4.6, 1.8, 4.6),
				C_MARBLE_DK, 200, { material = Enum.Material.Concrete, group = "Planters" })
			box(fPod, string.format("TerraceShrub_%d_%d", i, j), V(px, T2_TOP + 2.4, pz), V(3.6, 1.4, 3.6),
				C_LEAF, 70, { material = Enum.Material.Grass, group = "Planters" })
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 7. VỎ SẢNH GIAO DỊCH (tường kính + trụ đá + cửa chính)
---------------------------------------------------------------------------------------------------
local function buildLobbyShell(fLob: any): ()
	local zf: number = TOWER.z1          -- −104 (mặt tiền Nam)
	local zb: number = TOWER.z0          -- −182 (tường hậu Bắc)
	local xw: number = TOWER.x0          -- −50
	local xe: number = TOWER.x1          -- +50
	local LOW_TOP: number = 13.00        -- đỉnh tầng kính thấp
	local UP_BOT: number = 13.60         -- đáy tầng kính cao (có diềm ngang ở giữa)

	-- ===== TƯỜNG SAU (Bắc) bằng đá khối — nơi đặt biển vàng + thang máy =====
	brickWall(fLob, "LobbyBackWall", "X", zb + 1.0, xw, xe, FLOOR, 2.0, 10, 1.92, C_MARBLE_DK, 320, "LobbyBackWall", 9.0)
	box(fLob, "LobbyBackPilaster_L", V(xw + 1.80, (T2_TOP + LOBBY_CEIL) * 0.5, zb + 2.6), V(3.2, LOBBY_CEIL - T2_TOP, 2.6),
		C_MARBLE, 300, { material = Enum.Material.Marble, group = "LobbyStructure" })
	box(fLob, "LobbyBackPilaster_R", V(xe - 1.80, (T2_TOP + LOBBY_CEIL) * 0.5, zb + 2.6), V(3.2, LOBBY_CEIL - T2_TOP, 2.6),
		C_MARBLE, 300, { material = Enum.Material.Marble, group = "LobbyStructure" })

	-- ===== TƯỜNG KÍNH MẶT NAM: 2 tầng, chừa khoang cửa chính X −8..8 =====
	curtainLine(fLob, "LobbySWest", "X", zf, xw, -8.0, T2_TOP, LOW_TOP, 5.25, 45, 1, C_GLASS)
	curtainLine(fLob, "LobbySEast", "X", zf, 8.0, xe, T2_TOP, LOW_TOP, 5.25, 45, 1, C_GLASS)
	curtainLine(fLob, "LobbySUpper", "X", zf, xw, xe, UP_BOT, LOBBY_CEIL - 0.12, 5.25, 45, 1, C_GLASS_LT)

	-- ===== TƯỜNG KÍNH HAI BÊN ĐÔNG / TÂY =====
	curtainLine(fLob, "LobbyWLow", "Z", xw, zb, zf, T2_TOP, LOW_TOP, 6.5, 45, -1, C_GLASS)
	curtainLine(fLob, "LobbyWUp", "Z", xw, zb, zf, UP_BOT, LOBBY_CEIL - 0.12, 6.5, 45, -1, C_GLASS_LT)
	curtainLine(fLob, "LobbyELow", "Z", xe, zb, zf, T2_TOP, LOW_TOP, 6.5, 45, 1, C_GLASS)
	curtainLine(fLob, "LobbyEUp", "Z", xe, zb, zf, UP_BOT, LOBBY_CEIL - 0.12, 6.5, 45, 1, C_GLASS_LT)

	-- ===== 8 TRỤ ĐÁ VUÔNG QUANH SẢNH =====
	for i, px in ipairs({ xw, -30, -8, 8, 30, xe }) do
		box(fLob, "LobbyPier_S" .. i, V(px, (T2_TOP + LOBBY_CEIL) * 0.5, zf), V(3.0, LOBBY_CEIL - T2_TOP, 3.0),
			C_MARBLE, 320, { material = Enum.Material.Marble, group = "LobbyStructure" })
	end
	for i, pz in ipairs({ zb + 3.5, -160, -138, -120 }) do
		box(fLob, "LobbyPier_W" .. i, V(xw, (T2_TOP + LOBBY_CEIL) * 0.5, pz), V(3.0, LOBBY_CEIL - T2_TOP, 3.0),
			C_MARBLE, 320, { material = Enum.Material.Marble, group = "LobbyStructure" })
		box(fLob, "LobbyPier_E" .. i, V(xe, (T2_TOP + LOBBY_CEIL) * 0.5, pz), V(3.0, LOBBY_CEIL - T2_TOP, 3.0),
			C_MARBLE, 320, { material = Enum.Material.Marble, group = "LobbyStructure" })
	end

	-- ===== CỬA CHÍNH ĐÔI (rộng 16 × cao 8.8 studs — R15 5.45 đi lọt thoải mái) =====
	box(fLob, "EntryDoorL", V(-4.0, FLOOR + 4.4, zf + 0.05), V(7.6, 8.8, 0.20), C_GLASS_LT, 45,
		{ material = Enum.Material.Glass, transparency = 0.18, castShadow = false, canCollide = false, group = "EntryDoors" })
	box(fLob, "EntryDoorR", V(4.0, FLOOR + 4.4, zf + 0.05), V(7.6, 8.8, 0.20), C_GLASS_LT, 45,
		{ material = Enum.Material.Glass, transparency = 0.18, castShadow = false, canCollide = false, group = "EntryDoors" })
	-- Khung đứng + thanh đẩy inox
	for i, dx in ipairs({ -8.0, -0.15, 0.15, 8.0 }) do
		box(fLob, "EntryDoorPost" .. i, V(dx, FLOOR + 4.4, zf + 0.16), V(0.30, 8.8, 0.42), C_GOLD, 170,
			{ material = Enum.Material.Metal, group = "EntryDoors" })
	end
	box(fLob, "EntryDoorLintel", V(0, FLOOR + 8.95, zf + 0.16), V(16.4, 0.35, 0.42), C_GOLD, 170,
		{ material = Enum.Material.Metal, group = "EntryDoors" })
	for i, dx in ipairs({ -4.2, 4.2 }) do
		box(fLob, "EntryPushBar" .. i, V(dx, FLOOR + 4.2, zf + 0.30), V(5.2, 0.18, 0.18), C_STEEL_LT, 60,
			{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "EntryDoors" })
	end
	-- Mái hiên kính trên cửa (cantilever, có thanh treo)
	-- Mái che lối vào: mép sau cắm vào kính (không trùng phẳng), 2 cột inox đỡ mép trước
	box(fLob, "EntryCanopy", V(0, 14.40, zf + 3.05), V(26, 0.35, 5.90), C_GLASS_LT, 90,
		{ material = Enum.Material.Glass, transparency = 0.35, castShadow = false, group = "EntryCanopy" })
	for i, dx in ipairs({ -11.5, 11.5 }) do
		box(fLob, "EntryCanopyPost" .. i, V(dx, 9.20, zf + 5.55), V(0.55, 10.1, 0.55), C_GOLD, 220,
			{ material = Enum.Material.Metal, group = "EntryCanopy" })
		box(fLob, "EntryCanopyFoot" .. i, V(dx, 4.30, zf + 5.55), V(1.30, 0.36, 1.30), C_MARBLE_DK, 180,
			{ material = Enum.Material.Concrete, group = "EntryCanopy" })
	end
	box(fLob, "EntryCanopyEdge", V(0, 14.62, zf + 5.95), V(26, 0.12, 0.30), C_GOLD, 60,
		{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "EntryCanopy" })

	-- Bảng tên lối vào chính (trên kính, ngay trên khung cửa) + diềm mái che
	box(fLob, "EntryHeaderBack", V(0, 13.71, zf + 0.10), V(21.0, 0.70, 0.22), C_NAVY, 210,
		{ material = Enum.Material.Metal, group = "EntryDoors" })
	signBoard(fLob, "EntryHeaderSign", V(0, 13.70, zf + 0.24), V(20.4, 0.58, 0.20), C_NAVY,
		{ Enum.NormalId.Front }, {
			{ text = "MAZE BANK · LỐI VÀO CHÍNH", color = C_GOLD_LT, ths = 0.40, sw = 0.94, sh = 0.82, px = 0.03, py = 0.09 },
		}, 220)
	box(fLob, "EntryHeaderTrimT", V(0, 14.13, zf + 0.16), V(21.4, 0.14, 0.32), C_GOLD, 120,
		{ material = Enum.Material.Metal, castShadow = false, group = "EntryDoors" })
	-- Diềm mái che (treo dưới mép ngoài, không che bảng tên lối vào)
	box(fLob, "EntryFascia", V(0, 14.42, zf + 5.97), V(26.2, 0.62, 0.26), C_NAVY, 240,
		{ material = Enum.Material.Metal, group = "EntryCanopy" })
	signBoard(fLob, "EntryFasciaSign", V(0, 14.42, zf + 6.12), V(25.6, 0.50, 0.20), C_NAVY,
		{ Enum.NormalId.Front }, {
			{ text = "MAZE BANK", color = C_GOLD_LT, ths = 0.34, sw = 0.94, sh = 0.86, px = 0.03, py = 0.06 },
		}, 240)
	box(fLob, "EntryFasciaTrimL", V(-13.2, 14.42, zf + 5.97), V(0.5, 0.76, 0.34), C_GOLD, 110,
		{ material = Enum.Material.Metal, castShadow = false, group = "EntryCanopy" })
	box(fLob, "EntryFasciaTrimR", V(13.2, 14.42, zf + 5.97), V(0.5, 0.76, 0.34), C_GOLD, 110,
		{ material = Enum.Material.Metal, castShadow = false, group = "EntryCanopy" })
	-- Tay nắm inox 2 cánh + tấm đạp chân + thảm chùi chân trong sảnh
	for i, hx in ipairs({ -1.30, 1.30 }) do
		box(fLob, "EntryHandle" .. i, V(hx, FLOOR + 3.90, zf + 0.32), V(0.22, 3.6, 0.22), C_STEEL_LT, 60,
			{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "EntryDoors" })
	end
	box(fLob, "EntryDoorBase", V(0, FLOOR + 0.42, zf + 0.18), V(15.9, 0.84, 0.26), C_CHAR, 180,
		{ material = Enum.Material.Metal, group = "EntryDoors" })
	box(fLob, "EntryMatA", V(-4.05, FLOOR + 0.115, zf - 1.90), V(6.9, 0.05, 3.0), C_CHAR, 60,
		{ material = Enum.Material.Fabric, walkable = true, canCollide = false, castShadow = false, group = "EntryDoors" })
	box(fLob, "EntryMatB", V(4.05, FLOOR + 0.115, zf - 1.90), V(6.9, 0.05, 3.0), C_CHAR, 60,
		{ material = Enum.Material.Fabric, walkable = true, canCollide = false, castShadow = false, group = "EntryDoors" })

	-- ===== BẬC TAM CẤP TRƯỚC CỬA (3 bậc, từ sân bậc 2 lên sàn sảnh) =====
	for s = 1, 3 do
		box(fLob, "EntryStep" .. s, V(0, T2_TOP + 0.10 * s, zf + 1.6 + (3 - s) * 0.4),
			V(22, 0.20 * s, 0.9), C_MARBLE, 200,
			{ material = Enum.Material.Marble, walkable = true, group = "EntrySteps" })
	end

	-- ===== TRẦN SẢNH: tấm ốp + đèn hắt =====
	box(fLob, "LobbyCeilingSlab", V(0, LOBBY_CEIL - 0.15, (zb + zf) * 0.5 + 1.0), V(xe - xw, 0.30, zf - zb - 2.0),
		C_MARBLE_DK, nil, { material = Enum.Material.Concrete, structural = true, group = "LobbyCeiling" })
end

---------------------------------------------------------------------------------------------------
-- 8. NỘI THẤT SẢNH GIAO DỊCH (thông tầng 19 studs)
---------------------------------------------------------------------------------------------------
local function buildLobbyInterior(fInt: any): ()
	local zb: number = TOWER.z0 + 2.0    -- −180 (mặt trong tường hậu)
	local zf: number = TOWER.z1          -- −104 (mặt kính trước)
	local xw: number = TOWER.x0 + 2.0    -- −48
	local xe: number = TOWER.x1 - 2.0    -- +48
	local cy: number = (FLOOR + LOBBY_CEIL) * 0.5

	-- ===== A. SÀN CẨM THẠCH: ô lát + đường chỉ vàng =====
	local tileN: number = 10
	local zLow: number = math.min(zb, zf)
	local zHigh: number = math.max(zb, zf)
	local spanX: number = xe - xw
	local spanZ: number = zHigh - zLow
	local tw: number = spanX / tileN
	local td: number = spanZ / tileN
	for ix = 1, tileN do
		for iz = 1, tileN do
			local px: number = xw + (ix - 0.5) * tw
			local pz: number = zLow + (iz - 0.5) * td
			local alt: boolean = (ix + iz) % 2 == 0
			box(fInt, string.format("MarbleTile_%d_%d", ix, iz), V(px, FLOOR + 0.035, pz),
				V(tw - 0.22, 0.07, td - 0.22), if alt then C_MARBLE else C_MARBLE_VN, 120,
				{ material = Enum.Material.Marble, walkable = true, castShadow = false, group = "LobbyFloor" })
		end
	end
	-- Đường chỉ vàng chạy dọc tâm sảnh (dẫn từ cửa vào quầy lễ tân), chừa lỗ cho huy hiệu
	local logoHalf: number = 7.4
	local segS0: number = zLow + 1.0
	local segS1: number = -134 - logoHalf - 0.6
	local segN0: number = -134 + logoHalf + 0.6
	local segN1: number = zHigh - 1.0
	box(fInt, "FloorGoldInlayS", V(0, FLOOR + 0.11, (segS0 + segS1) * 0.5), V(1.4, 0.04, segS1 - segS0), C_GOLD, 40,
		{ material = Enum.Material.Metal, walkable = true, castShadow = false, group = "LobbyFloor" })
	box(fInt, "FloorGoldInlayN", V(0, FLOOR + 0.11, (segN0 + segN1) * 0.5), V(1.4, 0.04, segN1 - segN0), C_GOLD, 40,
		{ material = Enum.Material.Metal, walkable = true, castShadow = false, group = "LobbyFloor" })
	-- Huy hiệu logo trên sàn (tấm phẳng có SurfaceGui, viền vàng)
	box(fInt, "FloorLogoBorder", V(0, FLOOR + 0.10, -134), V(14.2, 0.05, 14.2), C_GOLD, 120,
		{ material = Enum.Material.Metal, walkable = true, castShadow = false, group = "LobbyFloor" })
	signBoard(fInt, "FloorLogo", V(0, FLOOR + 0.20, -134), V(13.0, 0.06, 13.0), C_NAVY,
		{ Enum.NormalId.Top }, {
			{ text = "MAZE BANK", color = C_GOLD_LT, ths = 2.9, sw = 0.86, sh = 0.32, px = 0.07, py = 0.24 },
			{ text = "LOS SANTOS · 1972", color = C_GOLD, ths = 1.0, sw = 0.86, sh = 0.14, px = 0.07, py = 0.60 },
		}, 130)

	-- ===== B. 6 CỘT ĐÁ CẨM THẠCH TRONG SẢNH =====
	for i, px in ipairs({ -30, 30 }) do
		for j, pz in ipairs({ -170, -148, -126 }) do
			local col = folder(fInt, string.format("LobbyColumn_%d_%d", i, j))
			box(col, string.format("LobbyColShaft_%d_%d", i, j), V(px, cy, pz), V(2.6, LOBBY_CEIL - FLOOR - 1.2, 2.6), C_MARBLE, 340,
				{ material = Enum.Material.Marble, group = "LobbyStructure" })
			box(col, string.format("LobbyColBase_%d_%d", i, j), V(px, FLOOR + 0.45, pz), V(3.4, 0.9, 3.4), C_MARBLE_DK, 320,
				{ material = Enum.Material.Marble, group = "LobbyStructure" })
			box(col, string.format("LobbyColCapital_%d_%d", i, j), V(px, LOBBY_CEIL - 0.9, pz), V(3.4, 0.9, 3.4), C_GOLD_DK, 300,
				{ material = Enum.Material.Metal, group = "LobbyStructure" })
		end
	end

	-- ===== C. QUẦY LỄ TÂN CHỮ L (đá cẩm thạch + mặt đá granite) =====
	local rec = folder(fInt, "Reception")
	box(rec, "DeskFront", V(0, FLOOR + 1.55, -150), V(22, 3.1, 2.6), C_MARBLE, 300,
		{ material = Enum.Material.Marble, group = "Reception" })
	box(rec, "DeskFrontTop", V(0, FLOOR + 3.20, -150), V(22.6, 0.24, 3.1), C_GOLD_LT, 240,
		{ material = Enum.Material.Granite, group = "Reception" })
	box(rec, "DeskReturn", V(-10.0, FLOOR + 1.55, -155.0), V(2.6, 3.1, 8.0), C_MARBLE, 300,
		{ material = Enum.Material.Marble, group = "Reception" })
	box(rec, "DeskReturnTop", V(-10.0, FLOOR + 3.26, -155.0), V(3.1, 0.24, 8.4), C_GOLD_LT, 240,
		{ material = Enum.Material.Granite, group = "Reception" })
	-- Khoang làm việc phía sau quầy (3 bàn + 3 máy tính)
	for i, dx in ipairs({ -6.0, 0, 6.0 }) do
		box(rec, "BackDesk" .. i, V(dx, FLOOR + 1.4, -156.5), V(4.6, 0.22, 2.4), C_WOOD, 120,
			{ material = Enum.Material.Wood, group = "Reception" })
		box(rec, "BackDeskLeg" .. i .. "L", V(dx - 1.9, FLOOR + 0.7, -156.5), V(0.28, 1.4, 2.2), C_CHAR, 110,
			{ material = Enum.Material.Metal, group = "Reception" })
		box(rec, "BackDeskLeg" .. i .. "R", V(dx + 1.9, FLOOR + 0.7, -156.5), V(0.28, 1.4, 2.2), C_CHAR, 110,
			{ material = Enum.Material.Metal, group = "Reception" })
		box(rec, "ReceptionMonitor" .. i, V(dx, FLOOR + 2.0, -157.0), V(2.0, 1.3, 0.2), C_CHAR, 70,
			{ material = Enum.Material.Metal, group = "Reception" })
		box(rec, "ReceptionScreen" .. i, V(dx, FLOOR + 2.0, -157.12), V(1.8, 1.1, 0.08), C_NEONB, 40,
			{ material = Enum.Material.Neon, castShadow = false, group = "Reception" })
	end
	-- Ghế xoay nhân viên
	for i, dx in ipairs({ -6.0, 0, 6.0 }) do
		box(rec, "StaffChair" .. i, V(dx, FLOOR + 1.05, -159.5), V(1.8, 0.3, 1.8), C_CHAR, 70,
			{ material = Enum.Material.Fabric, group = "Reception" })
		box(rec, "StaffChairBack" .. i, V(dx, FLOOR + 1.95, -160.3), V(1.8, 1.7, 0.28), C_CHAR, 70,
			{ material = Enum.Material.Fabric, group = "Reception" })
	end

	-- ===== D. 4 THANG MÁY KÍNH + BẢNG TẦNG =====
	local elv = folder(fInt, "Elevators")
	for i, dx in ipairs({ -13.5, -4.5, 4.5, 13.5 }) do
		-- Khung vàng: 2 trụ đứng + đà ngang + ngưỡng (KHÔNG phải tấm đặc để còn thấy cửa)
		box(elv, "ElevJambL" .. i, V(dx - 2.2, FLOOR + 4.8, zb + 0.35), V(0.5, 9.6, 0.70), C_GOLD_DK, 300,
			{ material = Enum.Material.Metal, group = "Elevators" })
		box(elv, "ElevJambR" .. i, V(dx + 2.2, FLOOR + 4.8, zb + 0.35), V(0.5, 9.6, 0.70), C_GOLD_DK, 300,
			{ material = Enum.Material.Metal, group = "Elevators" })
		box(elv, "ElevHeader" .. i, V(dx, FLOOR + 8.75, zb + 0.35), V(3.9, 0.85, 0.70), C_GOLD_DK, 300,
			{ material = Enum.Material.Metal, group = "Elevators" })
		box(elv, "ElevSill" .. i, V(dx, FLOOR + 0.10, zb + 0.35), V(3.9, 0.06, 0.70), C_GOLD, 240,
			{ material = Enum.Material.Metal, group = "Elevators" })
		-- 2 cánh cửa inox (mỗi cánh một bể máu)
		box(elv, "ElevDoorL" .. i, V(dx - 0.95, FLOOR + 4.4, zb + 0.30), V(1.85, 8.8, 0.20), C_STEEL_LT, 200,
			{ material = Enum.Material.Metal, group = "Elevators" })
		box(elv, "ElevDoorR" .. i, V(dx + 0.95, FLOOR + 4.4, zb + 0.30), V(1.85, 8.8, 0.20), C_STEEL_LT, 200,
			{ material = Enum.Material.Metal, group = "Elevators" })
		-- Đèn chỉ tầng phía trên + bảng gọi thang trên tường cạnh khung
		box(elv, "ElevIndicator" .. i, V(dx, FLOOR + 9.85, zb + 0.20), V(3.2, 0.62, 0.16), C_NEONW, 45,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Elevators" })
		box(elv, "ElevCallPanel" .. i, V(dx + 2.95, FLOOR + 3.6, zb + 0.11), V(0.45, 1.3, 0.22), C_GOLD, 60,
			{ material = Enum.Material.Metal, canCollide = false, group = "Elevators" })
	end
	-- Bảng danh mục tầng (tiếng Việt có dấu) đặt cạnh thang máy
	signBoard(fInt, "FloorDirectory", V(-24.0, FLOOR + 4.6, zb + 0.55), V(2.2, 9.0, 0.3), C_NAVY,
		{ Enum.NormalId.Front, Enum.NormalId.Back }, {
			{ text = "MAZE BANK", color = C_GOLD_LT, ths = 0.68, sw = 0.92, sh = 0.09, px = 0.04, py = 0.03 },
			{ text = "TẦNG 2 · DỊCH VỤ", color = C_WHITE, ths = 0.5, sw = 0.92, sh = 0.07, px = 0.04, py = 0.18 },
			{ text = "TẦNG 3 · TÍN DỤNG", color = C_WHITE, ths = 0.5, sw = 0.92, sh = 0.07, px = 0.04, py = 0.29 },
			{ text = "TẦNG 4 · ĐẦU TƯ", color = C_WHITE, ths = 0.5, sw = 0.92, sh = 0.07, px = 0.04, py = 0.40 },
			{ text = "TẦNG 5 · TÀI SẢN", color = C_WHITE, ths = 0.5, sw = 0.92, sh = 0.07, px = 0.04, py = 0.51 },
			{ text = "TẦNG 6 · BAN ĐIỀU HÀNH", color = C_WHITE, ths = 0.42, sw = 0.92, sh = 0.09, px = 0.04, py = 0.62 },
			{ text = "TẦNG 7 · KỸ THUẬT", color = C_GOLD_LT, ths = 0.42, sw = 0.92, sh = 0.09, px = 0.04, py = 0.75 },
		}, 120)

	-- ===== E. BIỂN VÀNG "MAZE BANK" TRÊN TƯỜNG HẬU =====
	signBoard(fInt, "LobbyGoldSign", V(0, 17.40, zb + 0.25), V(30.0, 5.2, 0.5), C_NAVY,
		{ Enum.NormalId.Front, Enum.NormalId.Back }, {
			{ text = "MAZE BANK", color = C_GOLD_LT, ths = 2.15, sw = 0.94, sh = 0.46, px = 0.03, py = 0.06 },
			{ text = "TẬP ĐOÀN TÀI CHÍNH LOS SANTOS · TỪ 1972", color = C_GOLD, ths = 0.62, sw = 0.94, sh = 0.20, px = 0.03, py = 0.60 },
		}, 200)

	-- ===== F. CỔNG DÒ KIM LOẠI + TURNSTILE =====
	local sec = folder(fInt, "Security")
	for i, dx in ipairs({ -4.6, 4.6 }) do
		box(sec, "DetectorPost" .. i, V(dx, FLOOR + 4.6, -112.0), V(1.5, 9.2, 1.5), C_STEEL, 200,
			{ material = Enum.Material.Metal, group = "Security" })
		box(sec, "DetectorLamp" .. i, V(dx, FLOOR + 9.5, -112.0), V(1.1, 0.5, 1.1), C_NEONB, 45,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Security" })
	end
	box(sec, "DetectorArch", V(0, FLOOR + 9.5, -112.0), V(10.7, 0.9, 1.5), C_STEEL_LT, 180,
		{ material = Enum.Material.Metal, group = "Security" })
	signBoard(sec, "DetectorSign", V(0, FLOOR + 10.3, -112.0), V(9.4, 0.8, 0.4), C_NAVY,
		{ Enum.NormalId.Front }, {
			{ text = "CỔNG AN NINH · SECURITY", color = C_GOLD_LT, ths = 0.44, sw = 0.94, sh = 0.62, px = 0.03, py = 0.18 },
		}, 110)
	-- Turnstile hai bên
	for i, dx in ipairs({ -13.0, 13.0 }) do
		box(sec, "TurnstileBody" .. i, V(dx, FLOOR + 1.6, -112.0), V(2.2, 3.2, 2.2), C_GOLD_DK, 180,
			{ material = Enum.Material.Metal, group = "Security" })
		box(sec, "TurnstileArm" .. i, V(dx + (if dx > 0 then -1.9 else 1.9), FLOOR + 2.7, -112.0),
			V(2.4, 0.22, 0.22), C_STEEL_LT, 60,
			{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Security" })
		box(sec, "TurnstileLed" .. i, V(dx, FLOOR + 3.35, -112.0), V(1.4, 0.24, 1.4), C_NEONB, 35,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Security" })
	end
	-- Bàn bảo vệ nhỏ góc Tây
	box(sec, "GuardDesk", V(-38.0, FLOOR + 1.5, -116.0), V(5.0, 3.0, 3.0), C_NAVY, 200,
		{ material = Enum.Material.Metal, group = "Security" })
	box(sec, "GuardDeskTop", V(-38.0, FLOOR + 3.1, -116.0), V(5.4, 0.2, 3.4), C_GOLD_LT, 160,
		{ material = Enum.Material.Granite, group = "Security" })
	box(sec, "GuardChair", V(-38.0, FLOOR + 1.0, -118.6), V(1.9, 0.3, 1.9), C_CHAR, 70,
		{ material = Enum.Material.Fabric, group = "Security" })
	box(sec, "GuardChairBack", V(-38.0, FLOOR + 1.9, -119.4), V(1.9, 1.7, 0.28), C_CHAR, 70,
		{ material = Enum.Material.Fabric, group = "Security" })

	-- ===== G. KHU CHỜ: 2 CỤM SOFA DA + BÀN + THẢM =====
	for side, sx in ipairs({ -1, 1 }) do
		local gx: number = sx * 31.0
		local grp = folder(fInt, "Waiting" .. side)
		box(grp, "Rug_" .. side, V(gx, FLOOR + 0.105, -117.0), V(17.0, 0.03, 13.0), C_NAVY, 40,
			{ material = Enum.Material.Fabric, walkable = true, canCollide = false, castShadow = false })
		box(grp, "SofaSeatA_" .. side, V(gx, FLOOR + 0.95, -112.0), V(13.0, 1.3, 4.16), C_LEATHER, 120,
			{ material = Enum.Material.Fabric, group = "Furniture" })
		box(grp, "SofaBackA_" .. side, V(gx, FLOOR + 2.05, -113.7), V(12.72, 2.2, 1.1), C_LEATHER, 110,
			{ material = Enum.Material.Fabric, group = "Furniture" })
		box(grp, "SofaSeatB_" .. side, V(gx, FLOOR + 0.95, -123.0), V(13.0, 1.3, 4.16), C_LEATHER, 120,
			{ material = Enum.Material.Fabric, group = "Furniture" })
		box(grp, "SofaBackB_" .. side, V(gx, FLOOR + 2.05, -121.3), V(12.72, 2.2, 1.1), C_LEATHER, 110,
			{ material = Enum.Material.Fabric, group = "Furniture" })
		box(grp, "CoffeeTable_" .. side, V(gx, FLOOR + 0.85, -117.5), V(6.4, 0.24, 3.4), C_WOOD, 100,
			{ material = Enum.Material.Wood, group = "Furniture" })
		box(grp, "CoffeeTableLegA_" .. side, V(gx - 2.7, FLOOR + 0.42, -117.5), V(0.3, 0.85, 0.3), C_CHAR, 90,
			{ material = Enum.Material.Metal, group = "Furniture" })
		box(grp, "CoffeeTableLegB_" .. side, V(gx + 2.7, FLOOR + 0.42, -117.5), V(0.3, 0.85, 0.3), C_CHAR, 90,
			{ material = Enum.Material.Metal, group = "Furniture" })
		-- Chậu cây trong nhà
		box(grp, "IndoorPot_" .. side, V(gx + (if sx > 0 then 6.6 else -6.6), FLOOR + 1.0, -110.5), V(2.6, 2.0, 2.6),
			C_MARBLE_DK, 160, { material = Enum.Material.Concrete, group = "Planters" })
		box(grp, "IndoorPlant_" .. side, V(gx + (if sx > 0 then 6.6 else -6.6), FLOOR + 3.4, -110.5), V(3.4, 3.0, 3.4),
			C_LEAF, 70, { material = Enum.Material.Grass, group = "Planters" })
	end

	-- ===== H. TRANH ỐP TƯỜNG 2 BÊN =====
	for i, pz in ipairs({ -170, -140 }) do
		for side, px in ipairs({ xw + 0.4, xe - 0.4 }) do
			box(fInt, string.format("WallArt_%d_%d", i, side), V(px, FLOOR + 7.5, pz), V(0.3, 6.0, 9.0),
				C_NAVY, 80, { material = Enum.Material.SmoothPlastic, castShadow = false, group = "Decor" })
			box(fInt, string.format("WallArtFrame_%d_%d", i, side), V(px + (if side == 1 then 0.18 else -0.18), FLOOR + 7.5, pz),
				V(0.12, 6.4, 9.4), C_GOLD_DK, 60,
				{ material = Enum.Material.Metal, castShadow = false, group = "Decor" })
		end
	end

	-- ===== I. ĐÈN CHÙM 3 TẦNG (giữa sảnh) =====
	local chd = folder(fInt, "Chandelier")
	box(chd, "Stem", V(0, 19.9, -134), V(0.45, 6.4, 0.45), C_GOLD, 120,
		{ material = Enum.Material.Metal, canCollide = false, group = "Chandelier" })
	-- Khung chữ nhật lồng nhau (2 tầng) + 8 đèn thả
	for tier = 1, 2 do
		local half: number = if tier == 1 then 5.6 else 3.4
		local yy: number = if tier == 1 then 18.60 else 19.45
		local bar: number = half * 2
		box(chd, "FrameN" .. tier, V(0, yy, -134 - half), V(bar + 0.5, 0.28, 0.5), C_GOLD_LT, 60,
			{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Chandelier" })
		box(chd, "FrameS" .. tier, V(0, yy, -134 + half), V(bar + 0.5, 0.28, 0.5), C_GOLD_LT, 60,
			{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Chandelier" })
		box(chd, "FrameW" .. tier, V(-half, yy, -134), V(0.5, 0.28, bar), C_GOLD_LT, 60,
			{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Chandelier" })
		box(chd, "FrameE" .. tier, V(half, yy, -134), V(0.5, 0.28, bar), C_GOLD_LT, 60,
			{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Chandelier" })
		-- 4 dây treo từ trần
		for k, off in ipairs({ -half, half }) do
			box(chd, "Rod" .. tier .. "_" .. k .. "N", V(off, (LOBBY_CEIL + yy) * 0.5, -134 - half), V(0.14, LOBBY_CEIL - yy, 0.14),
				C_GOLD, 40, { material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Chandelier" })
			box(chd, "Rod" .. tier .. "_" .. k .. "S", V(off, (LOBBY_CEIL + yy) * 0.5, -134 + half), V(0.14, LOBBY_CEIL - yy, 0.14),
				C_GOLD, 40, { material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Chandelier" })
		end
		for k = 1, 4 do
			local px: number = if k == 1 then -half elseif k == 2 then half else 0
			local pz: number = if k == 3 then -half elseif k == 4 then half else 0
			box(chd, "Bulb" .. tier .. "_" .. k, V(px, yy - 0.55, -134 + pz), V(0.62, 0.72, 0.62), C_NEONW, 25,
				{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Chandelier" })
			box(chd, "BulbRod" .. tier .. "_" .. k, V(px, yy - 0.24, -134 + pz), V(0.12, 0.5, 0.12), C_GOLD, 30,
				{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Chandelier" })
		end
	end

	-- ===== J. ĐÈN HẮT TRẦN (lưới 5 × 4 tấm neon chìm) =====
	for ix = 1, 5 do
		for iz = 1, 4 do
			local px: number = -32 + (ix - 1) * 16
			local pz: number = -168 + (iz - 1) * 15
			box(fInt, string.format("CeilingPanel_%d_%d", ix, iz), V(px, LOBBY_CEIL - 0.42, pz),
				V(9.0, 0.22, 9.0), C_NEONW, 35,
				{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "LobbyLights" })
		end
	end
end

---------------------------------------------------------------------------------------------------
-- 9. THÂN THÁP: 6 TẦNG KÍNH THU DẦN + TRỤ GÓC BẬC THANG + LAN CAN SÂN THƯỢNG TỪNG TẦNG
---------------------------------------------------------------------------------------------------
local PIER: number = 4.8          -- cạnh trụ góc (vát góc bậc thang)

local function buildTower(fTw: any): ()
	-- ===== Vành mái quanh sảnh (vì tầng L1 nhỏ hơn sảnh 3 studs mỗi cạnh) =====
	local r0, r1 = TOWER.x0, TOWER.x1
	local rz0, rz1 = TOWER.z0, TOWER.z1
	local l1 = LEVELS[1]
	box(fTw, "LobbyRoofRing_S", V(0, 23.70, (l1.z1 + rz1) * 0.5), V(r1 - r0, 1.0, rz1 - l1.z1), C_MARBLE_DK, nil,
		{ material = Enum.Material.Concrete, structural = true, walkable = true, group = "TowerSlabs" })
	box(fTw, "LobbyRoofRing_N", V(0, 23.70, (rz0 + 0.5 + l1.z0) * 0.5), V(r1 - r0, 1.0, l1.z0 - rz0 - 0.5), C_MARBLE_DK, nil,
		{ material = Enum.Material.Concrete, structural = true, walkable = true, group = "TowerSlabs" })
	box(fTw, "LobbyRoofRing_W", V((r0 + l1.x0) * 0.5, 23.70, (l1.z0 + l1.z1) * 0.5), V(l1.x0 - r0, 1.0, l1.z1 - l1.z0),
		C_MARBLE_DK, nil, { material = Enum.Material.Concrete, structural = true, walkable = true, group = "TowerSlabs" })
	box(fTw, "LobbyRoofRing_E", V((l1.x1 + r1) * 0.5, 23.70, (l1.z0 + l1.z1) * 0.5), V(r1 - l1.x1, 1.0, l1.z1 - l1.z0),
		C_MARBLE_DK, nil, { material = Enum.Material.Concrete, structural = true, walkable = true, group = "TowerSlabs" })
	-- Diềm vàng quanh đỉnh sảnh (dải phân tầng đặc trưng)
	box(fTw, "LobbyCrownBand_S", V(0, 23.05, rz1 + 0.72), V(r1 - r0 + 1.1, 1.5, 0.60), C_GOLD, 260,
		{ material = Enum.Material.Metal, group = "TowerTrim" })
	box(fTw, "LobbyCrownBand_W", V(r0 - 0.72, 23.05, (rz0 + rz1) * 0.5), V(0.7, 1.5, rz1 - rz0), C_GOLD, 260,
		{ material = Enum.Material.Metal, group = "TowerTrim" })
	box(fTw, "LobbyCrownBand_E", V(r1 + 0.72, 23.05, (rz0 + rz1) * 0.5), V(0.7, 1.5, rz1 - rz0), C_GOLD, 260,
		{ material = Enum.Material.Metal, group = "TowerTrim" })

	-- ===== 6 TẦNG KÍNH =====
	for li, lv in ipairs(LEVELS) do
		local w: number = lv.x1 - lv.x0
		local d: number = lv.z1 - lv.z0
		local cx: number = (lv.x0 + lv.x1) * 0.5
		local cz: number = (lv.z0 + lv.z1) * 0.5
		local gy0: number = lv.y0 + 1.0
		local wh: number = lv.y1 - gy0

		-- Sàn tầng (dày 1.0 → luôn CanCollide để không rơi xuyên)
		box(fTw, lv.name .. "_FloorSlab", V(cx, lv.y0 + 0.5, cz), V(w, 1.0, d), C_MARBLE_DK, nil,
			{ material = Enum.Material.Concrete, structural = true, walkable = true, group = "TowerSlabs" })

		-- 4 mặt kính, chừa 4 góc cho trụ (mỗi ô kính một bể máu riêng)
		curtainLine(fTw, lv.name .. "_S", "X", lv.z1, lv.x0 + PIER, lv.x1 - PIER, gy0, lv.y1, 8.0, 45, 1, C_GLASS_GOLD)
		curtainLine(fTw, lv.name .. "_N", "X", lv.z0, lv.x0 + PIER, lv.x1 - PIER, gy0, lv.y1, 8.0, 45, -1, C_GLASS_GOLD)
		curtainLine(fTw, lv.name .. "_W", "Z", lv.x0, lv.z0 + PIER, lv.z1 - PIER, gy0, lv.y1, 8.0, 45, -1, C_GLASS_GOLD)
		curtainLine(fTw, lv.name .. "_E", "Z", lv.x1, lv.z0 + PIER, lv.z1 - PIER, gy0, lv.y1, 8.0, 45, 1, C_GLASS_GOLD)

		-- 4 TRỤ GÓC (mỗi tầng thu vào 3 studs → đọc thành khối tháp vát góc bậc thang)
		for i, sx in ipairs({ lv.x0 + PIER * 0.5, lv.x1 - PIER * 0.5 }) do
			for j, sz in ipairs({ lv.z0 + PIER * 0.5, lv.z1 - PIER * 0.5 }) do
				local pier = box(fTw, string.format("%s_CornerPier_%d_%d", lv.name, i, j),
					V(sx, gy0 + wh * 0.5, sz), V(PIER, wh, PIER), C_GOLD, 320,
					{ material = Enum.Material.Metal, group = "CornerPiers" })
			end
		end

		-- SÂN THƯỢNG: sàn đua ra tới mép tầng dưới (lấp kín mép, đi được) + lan can + đèn viền
		local prev: any = if li > 1 then LEVELS[li - 1] else TOWER
		local py0: number = lv.y1 + 1.0
		local pcy: number = py0 + 0.8
		box(fTw, lv.name .. "_LedgeDeck_S", V((prev.x0 + prev.x1) * 0.5, lv.y1 + 0.5, (lv.z1 + prev.z1) * 0.5),
			V(prev.x1 - prev.x0, 1.0, prev.z1 - lv.z1), C_MARBLE_DK, nil,
			{ material = Enum.Material.Concrete, structural = true, walkable = true, group = "Parapets" })
		box(fTw, lv.name .. "_LedgeDeck_N", V((prev.x0 + prev.x1) * 0.5, lv.y1 + 0.5, (prev.z0 + lv.z0) * 0.5),
			V(prev.x1 - prev.x0, 1.0, lv.z0 - prev.z0), C_MARBLE_DK, nil,
			{ material = Enum.Material.Concrete, structural = true, walkable = true, group = "Parapets" })
		box(fTw, lv.name .. "_LedgeDeck_E", V((lv.x1 + prev.x1) * 0.5, lv.y1 + 0.5, (lv.z0 + lv.z1) * 0.5),
			V(prev.x1 - lv.x1, 1.0, lv.z1 - lv.z0), C_MARBLE_DK, nil,
			{ material = Enum.Material.Concrete, structural = true, walkable = true, group = "Parapets" })
		box(fTw, lv.name .. "_LedgeDeck_W", V((prev.x0 + lv.x0) * 0.5, lv.y1 + 0.5, (lv.z0 + lv.z1) * 0.5),
			V(lv.x0 - prev.x0, 1.0, lv.z1 - lv.z0), C_MARBLE_DK, nil,
			{ material = Enum.Material.Concrete, structural = true, walkable = true, group = "Parapets" })
		-- Lan can bê tông 3 mặt (nam / tây / đông) + mặt bắc
		box(fTw, lv.name .. "_LedgeParapet_S", V((prev.x0 + prev.x1) * 0.5, pcy, prev.z1 - 0.42),
			V(prev.x1 - prev.x0 - 1.2, 1.6, 0.72), C_MARBLE, 200,
			{ material = Enum.Material.Concrete, group = "Parapets" })
		box(fTw, lv.name .. "_LedgeParapet_N", V((prev.x0 + prev.x1) * 0.5, pcy, prev.z0 + 0.42),
			V(prev.x1 - prev.x0 - 1.2, 1.6, 0.72), C_MARBLE, 200,
			{ material = Enum.Material.Concrete, group = "Parapets" })
		box(fTw, lv.name .. "_LedgeParapet_W", V(prev.x0 + 0.42, pcy, (prev.z0 + prev.z1) * 0.5),
			V(0.72, 1.6, prev.z1 - prev.z0 - 2.4), C_MARBLE, 200,
			{ material = Enum.Material.Concrete, group = "Parapets" })
		box(fTw, lv.name .. "_LedgeParapet_E", V(prev.x1 - 0.42, pcy, (prev.z0 + prev.z1) * 0.5),
			V(0.72, 1.6, prev.z1 - prev.z0 - 2.4), C_MARBLE, 200,
			{ material = Enum.Material.Concrete, group = "Parapets" })
		-- Đèn LED vàng trên đỉnh lan can (sáng rõ ban đêm)
		box(fTw, lv.name .. "_LedgeNeon_S", V((prev.x0 + prev.x1) * 0.5, py0 + 1.69, prev.z1 - 0.42),
			V(prev.x1 - prev.x0 - 2.2, 0.18, 0.30), C_GOLD_LT, 40,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Parapets" })
		box(fTw, lv.name .. "_LedgeNeon_N", V((prev.x0 + prev.x1) * 0.5, py0 + 1.69, prev.z0 + 0.42),
			V(prev.x1 - prev.x0 - 2.2, 0.18, 0.30), C_GOLD_LT, 40,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Parapets" })
		box(fTw, lv.name .. "_LedgeNeon_W", V(prev.x0 + 0.42, py0 + 1.69, (prev.z0 + prev.z1) * 0.5),
			V(0.30, 0.18, prev.z1 - prev.z0 - 3.4), C_GOLD_LT, 40,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Parapets" })
		box(fTw, lv.name .. "_LedgeNeon_E", V(prev.x1 - 0.42, py0 + 1.69, (prev.z0 + prev.z1) * 0.5),
			V(0.30, 0.18, prev.z1 - prev.z0 - 3.4), C_GOLD_LT, 40,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Parapets" })

		-- Bảng tên tầng gắn trên mặt ngoài lan can nam (tiếng Việt có dấu)
		local floorLabel: string = if li == 1 then "TẦNG 2 · DỊCH VỤ"
			elseif li == 2 then "TẦNG 3 · TÍN DỤNG"
			elseif li == 3 then "TẦNG 4 · ĐẦU TƯ"
			elseif li == 4 then "TẦNG 5 · TÀI SẢN"
			elseif li == 5 then "TẦNG 6 · BAN ĐIỀU HÀNH"
			else "TẦNG 7 · KỸ THUẬT"
		signBoard(fTw, lv.name .. "_FloorPlaque", V((prev.x0 + prev.x1) * 0.5, pcy, prev.z1 + 0.05),
			V(7.4, 1.14, 0.22), C_NAVY, { Enum.NormalId.Front }, {
				{ text = floorLabel, color = C_GOLD_LT, ths = 0.55, sw = 0.95, sh = 0.76, px = 0.025, py = 0.12 },
			}, 90)
	end

	-- ===== DẢI LED NGANG MỖI TẦNG (sáng rõ ban đêm ở cả 4 mặt) =====
	for li, lv in ipairs(LEVELS) do
		local w: number = lv.x1 - lv.x0 - PIER * 2
		local d: number = lv.z1 - lv.z0 - PIER * 2
		local yy: number = lv.y1 - 1.15
		box(fTw, lv.name .. "_LedS", V((lv.x0 + lv.x1) * 0.5, yy, lv.z1 + 0.46), V(w, 0.16, 0.14), C_GOLD_LT, 30,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "TowerLed" })
		box(fTw, lv.name .. "_LedN", V((lv.x0 + lv.x1) * 0.5, yy, lv.z0 - 0.46), V(w, 0.16, 0.14), C_GOLD_LT, 30,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "TowerLed" })
		box(fTw, lv.name .. "_LedW", V(lv.x0 - 0.46, yy, (lv.z0 + lv.z1) * 0.5), V(0.14, 0.16, d), C_GOLD_LT, 30,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "TowerLed" })
		box(fTw, lv.name .. "_LedE", V(lv.x1 + 0.46, yy, (lv.z0 + lv.z1) * 0.5), V(0.14, 0.16, d), C_GOLD_LT, 30,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "TowerLed" })
	end

	-- ===== TẦNG KỸ THUẬT (MECH) + LOUVERS =====
	local mw: number = MECH.x1 - MECH.x0
	local md: number = MECH.z1 - MECH.z0
	local mcx: number = (MECH.x0 + MECH.x1) * 0.5
	local mcz: number = (MECH.z0 + MECH.z1) * 0.5
	-- Vách bê tông đặc + lam thông gió (không phải kính)
	box(fTw, "MECH_WallS", V(mcx, (MECH.y0 + 1.0 + MECH.y1) * 0.5, MECH.z1), V(mw, MECH.y1 - MECH.y0 - 1.0, 1.6),
		C_CHAR_LT, 320, { material = Enum.Material.Concrete, group = "MechWalls" })
	box(fTw, "MECH_WallN", V(mcx, (MECH.y0 + 1.0 + MECH.y1) * 0.5, MECH.z0), V(mw, MECH.y1 - MECH.y0 - 1.0, 1.6),
		C_CHAR_LT, 320, { material = Enum.Material.Concrete, group = "MechWalls" })
	box(fTw, "MECH_WallW", V(MECH.x0, (MECH.y0 + 1.0 + MECH.y1) * 0.5, mcz), V(1.6, MECH.y1 - MECH.y0 - 1.0, md),
		C_CHAR_LT, 320, { material = Enum.Material.Concrete, group = "MechWalls" })
	box(fTw, "MECH_WallE", V(MECH.x1, (MECH.y0 + 1.0 + MECH.y1) * 0.5, mcz), V(1.6, MECH.y1 - MECH.y0 - 1.0, md),
		C_CHAR_LT, 320, { material = Enum.Material.Concrete, group = "MechWalls" })
	-- Lam thông gió mặt Nam + Bắc (mỗi thanh một bể máu)
	segmentedRow(fTw, "MECH_LouverS", 12,
		function(i) return V(MECH.x0 + 2 + (i - 1) * ((mw - 4) / 11), MECH.y0 + 2.55, MECH.z1 + 0.85) end,
		function(i) return V((mw - 4) / 11 - 0.5, 2.9, 0.35) end,
		function(i) return C_STEEL end, 70,
		{ material = Enum.Material.Metal, group = "MechLouvers" })
	segmentedRow(fTw, "MECH_LouverN", 12,
		function(i) return V(MECH.x0 + 2 + (i - 1) * ((mw - 4) / 11), MECH.y0 + 2.55, MECH.z0 - 0.85) end,
		function(i) return V((mw - 4) / 11 - 0.5, 2.9, 0.35) end,
		function(i) return C_STEEL end, 70,
		{ material = Enum.Material.Metal, group = "MechLouvers" })

	-- ===== BIỂN "MAZE BANK" VÀNG 4 MẶT TRÊN ĐỈNH THÁP (băng chữ lớn, đọc rõ từ xa) =====
	local crownLine: { any } = {
		{ text = "MAZE BANK", color = C_GOLD_LT, ths = 2.9, sw = 0.92, sh = 0.56, px = 0.04, py = 0.06 },
		{ text = "PILLBOX HILL · LOS SANTOS", color = C_GOLD, ths = 0.92, sw = 0.92, sh = 0.26, px = 0.04, py = 0.66 },
	}
	signBoard(fTw, "TowerTopSignS", V(mcx, 148.60, MECH.z1 + 1.02), V(46.0, 6.00, 0.60), C_NAVY,
		{ Enum.NormalId.Front }, crownLine, 260)
	signBoard(fTw, "TowerTopSignN", V(mcx, 148.60, MECH.z0 - 1.02), V(46.0, 6.00, 0.60), C_NAVY,
		{ Enum.NormalId.Back }, crownLine, 260)
	signBoard(fTw, "TowerTopSignW", V(MECH.x0 - 1.02, 148.60, mcz), V(0.60, 6.00, 30.0), C_NAVY,
		{ Enum.NormalId.Left }, crownLine, 260)
	signBoard(fTw, "TowerTopSignE", V(MECH.x1 + 1.02, 148.60, mcz), V(0.60, 6.00, 30.0), C_NAVY,
		{ Enum.NormalId.Right }, crownLine, 260)
	-- Hai dải LED vàng dưới băng chữ (sáng rõ ban đêm)
	box(fTw, "TopLedS", V(mcx, 145.42, MECH.z1 + 1.08), V(44.0, 0.20, 0.22), C_GOLD_LT, 30,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "TowerLed" })
	box(fTw, "TopLedN", V(mcx, 145.42, MECH.z0 - 1.08), V(44.0, 0.20, 0.22), C_GOLD_LT, 30,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "TowerLed" })
	box(fTw, "TopLedW", V(MECH.x0 - 1.20, 145.42, mcz), V(0.22, 0.20, 28.0), C_GOLD_LT, 30,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "TowerLed" })
	box(fTw, "TopLedE", V(MECH.x1 + 1.20, 145.42, mcz), V(0.22, 0.20, 28.0), C_GOLD_LT, 30,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "TowerLed" })

	-- Diềm vàng đỉnh buồng kỹ thuật (đọc thành "vương miện" của toà tháp)
	box(fTw, "MECH_CorniceS", V(mcx, 152.10, MECH.z1 + 0.87), V(mw - 1.0, 1.1, 0.14), C_GOLD, 240,
		{ material = Enum.Material.Metal, group = "TowerTrim" })
	box(fTw, "MECH_CorniceN", V(mcx, 152.00, MECH.z0 - 0.87), V(mw - 1.0, 1.1, 0.14), C_GOLD, 240,
		{ material = Enum.Material.Metal, group = "TowerTrim" })
	box(fTw, "MECH_CorniceW", V(MECH.x0 - 0.87, 152.00, mcz), V(0.14, 1.1, md - 1.0), C_GOLD, 240,
		{ material = Enum.Material.Metal, group = "TowerTrim" })
	box(fTw, "MECH_CorniceE", V(MECH.x1 + 0.87, 152.00, mcz), V(0.14, 1.1, md - 1.0), C_GOLD, 240,
		{ material = Enum.Material.Metal, group = "TowerTrim" })

end

---------------------------------------------------------------------------------------------------
-- 10. SÂN THƯỢNG + NẮP BUỒNG KỸ THUẬT + BÃI ĐÁP TRỰC THĂNG + CỘT ĂNG-TEN
---------------------------------------------------------------------------------------------------
local function buildRoof(fRf: any): ()
	local l6 = LEVELS[6]
	local rx0, rx1 = l6.x0, l6.x1
	local rz0, rz1 = l6.z0, l6.z1
	local TERR: number = l6.y1 + 1.0     -- 117.20 = mặt sàn sân thượng (khớp mép đua tầng L6)
	local CAPY: number = MECH.y1         -- 126.20 = đáy nắp buồng kỹ thuật
	local PADY: number = CAPY + 1.2      -- 127.40 = đáy bãi đáp

	-- ===== A. SÀN SÂN THƯỢNG (dày 1.0 → luôn CanCollide) =====
	box(fRf, "RoofDeck", V(0, l6.y1 + 0.5, (rz0 + rz1) * 0.5), V(rx1 - rx0, 1.0, rz1 - rz0), C_MARBLE_DK, nil,
		{ material = Enum.Material.Concrete, structural = true, walkable = true, group = "RoofDeck" })
	box(fRf, "RoofMembrane", V(0, TERR + 0.04, (rz0 + rz1) * 0.5), V(rx1 - rx0 - 4.0, 0.08, rz1 - rz0 - 4.0),
		C_ASPHALT, nil, { material = Enum.Material.Asphalt, walkable = true, castShadow = false, group = "RoofDeck" })

	-- ===== B. NẮP BUỒNG KỸ THUẬT (đua 2 studs mỗi cạnh) =====
	local capX0, capX1 = MECH.x0 - 2.0, MECH.x1 + 2.0
	local capZ0, capZ1 = MECH.z0 - 2.0, MECH.z1 + 2.0
	box(fRf, "MechCap", V(0, (CAPY + PADY) * 0.5, (capZ0 + capZ1) * 0.5),
		V(capX1 - capX0, PADY - CAPY, capZ1 - capZ0), C_MARBLE_DK, nil,
		{ material = Enum.Material.Concrete, structural = true, walkable = true, group = "RoofDeck" })
	-- Diềm vàng + gờ nắp (parapet thấp quanh nắp)
	local capCY: number = CAPY + 0.75
	box(fRf, "MechCapTrimS", V(0, capCY, capZ1 + 0.30), V(capX1 - capX0 + 1.2, 1.5, 0.60), C_GOLD, 260,
		{ material = Enum.Material.Metal, group = "RoofTrim" })
	box(fRf, "MechCapTrimN", V(0, capCY, capZ0 - 0.30), V(capX1 - capX0 + 1.2, 1.5, 0.60), C_GOLD, 260,
		{ material = Enum.Material.Metal, group = "RoofTrim" })
	box(fRf, "MechCapTrimW", V(capX0 - 0.30, capCY, (capZ0 + capZ1) * 0.5), V(0.60, 1.5, capZ1 - capZ0), C_GOLD, 260,
		{ material = Enum.Material.Metal, group = "RoofTrim" })
	box(fRf, "MechCapTrimE", V(capX1 + 0.30, capCY, (capZ0 + capZ1) * 0.5), V(0.60, 1.5, capZ1 - capZ0), C_GOLD, 260,
		{ material = Enum.Material.Metal, group = "RoofTrim" })

	-- ===== C. BÃI ĐÁP TRỰC THĂNG TRÒN (xấp xỉ 26 dải) =====
	local bands: number = 20
	local bandH: number = (HELI.r * 2) / bands
	for k = 1, bands do
		local zc: number = HELI.cz - HELI.r + (k - 0.5) * bandH
		local dz: number = zc - HELI.cz
		local halfW: number = math.sqrt(math.max(0.25, HELI.r * HELI.r - dz * dz)) - 0.06
		box(fRf, string.format("HelipadBand_%02d", k), V(HELI.cx, (PADY + PAD_TOP) * 0.5, zc),
			V(halfW * 2, PAD_TOP - PADY, bandH + 0.02), C_ASPHALT, 420,
			{ material = Enum.Material.Asphalt, walkable = true, group = "Helipad" })
	end
	-- Viền đỏ + đèn mép + chữ H
	segmentedRow(fRf, "HelipadRedMark", 24,
		function(i)
			local a: number = (i - 1) / 24 * math.pi * 2
			return V(HELI.cx + math.cos(a) * 13.6, PAD_TOP + 0.05, HELI.cz + math.sin(a) * 13.6)
		end,
		function(i) return V(1.9, 0.06, 1.9) end,
		function(i) return C_RED end, 60,
		{ material = Enum.Material.SmoothPlastic, walkable = true, castShadow = false, group = "Helipad" })
	segmentedRow(fRf, "HelipadEdgeLight", 8,
		function(i)
			local a: number = (i - 1) / 8 * math.pi * 2 + 0.39
			return V(HELI.cx + math.cos(a) * 14.3, PAD_TOP + 0.10, HELI.cz + math.sin(a) * 14.3)
		end,
		function(i) return V(0.9, 0.20, 0.9) end,
		function(i) return C_NEONW end, 30,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Helipad" })
	box(fRf, "HelipadH_Left", V(HELI.cx - 5.0, PAD_TOP + 0.03, HELI.cz), V(1.5, 0.06, 12.0), C_WHITE, 50,
		{ material = Enum.Material.SmoothPlastic, walkable = true, castShadow = false, group = "Helipad" })
	box(fRf, "HelipadH_Right", V(HELI.cx + 5.0, PAD_TOP + 0.03, HELI.cz), V(1.5, 0.06, 12.0), C_WHITE, 50,
		{ material = Enum.Material.SmoothPlastic, walkable = true, castShadow = false, group = "Helipad" })
	box(fRf, "HelipadH_Cross", V(HELI.cx, PAD_TOP + 0.09, HELI.cz), V(10.0, 0.06, 1.5), C_WHITE, 50,
		{ material = Enum.Material.SmoothPlastic, walkable = true, castShadow = false, group = "Helipad" })
	for i, amb in ipairs({ { -9.5, -9.5 }, { 9.5, -9.5 }, { -9.5, 9.5 }, { 9.5, 9.5 } }) do
		local bea = box(fRf, "HelipadBeacon" .. i, V(HELI.cx + amb[1], PAD_TOP + 0.34, HELI.cz + amb[2]),
			V(1.0, 1.0, 1.0), C_RED, 35,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, shape = Enum.PartType.Ball,
				group = "Helipad" })
		if bea then
			local l = Instance.new("PointLight")
			l.Color = C_RED
			l.Brightness = 1.6
			l.Range = 22
			l.Parent = bea
		end
	end

	-- ===== D. THIẾT BỊ SÂN THƯỢNG =====
	local eq = folder(fRf, "RoofEquipment")
	for i, zc in ipairs({ -152.0, -144.0, -136.0 }) do
		local g = folder(eq, "AcUnitW" .. i)
		box(g, "AcBody_" .. i .. "_W", V(-28.0, TERR + 1.70, zc), V(7.0, 3.4, 5.4), C_STEEL, 200,
			{ material = Enum.Material.Metal, group = "RoofEquipment" })
		box(g, "AcTop_" .. i .. "_W", V(-28.0, TERR + 3.50, zc), V(7.4, 0.30, 5.8), C_STEEL_LT, 160,
			{ material = Enum.Material.Metal, group = "RoofEquipment" })
		box(g, "AcFan_" .. i .. "_W", V(-28.0, TERR + 3.70, zc), V(3.4, 0.24, 3.4), C_CHAR, 120,
			{ material = Enum.Material.Metal, canCollide = false, group = "RoofEquipment" })
		box(g, "AcGrille_" .. i .. "_W", V(-24.40, TERR + 1.70, zc), V(0.26, 2.2, 4.2), C_CHAR_LT, 90,
			{ material = Enum.Material.Metal, canCollide = false, group = "RoofEquipment" })
	end
	for i, zc in ipairs({ -152.0, -136.0 }) do
		local g = folder(eq, "AcUnitE" .. i)
		box(g, "AcBody_" .. i .. "_E", V(28.0, TERR + 1.70, zc), V(7.0, 3.4, 5.4), C_STEEL, 200,
			{ material = Enum.Material.Metal, group = "RoofEquipment" })
		box(g, "AcTop_" .. i .. "_E", V(28.0, TERR + 3.50, zc), V(7.4, 0.30, 5.8), C_STEEL_LT, 160,
			{ material = Enum.Material.Metal, group = "RoofEquipment" })
		box(g, "AcFan_" .. i .. "_E", V(28.0, TERR + 3.70, zc), V(3.4, 0.24, 3.4), C_CHAR, 120,
			{ material = Enum.Material.Metal, canCollide = false, group = "RoofEquipment" })
		box(g, "AcGrille_" .. i .. "_E", V(24.40, TERR + 1.70, zc), V(0.26, 2.2, 4.2), C_CHAR_LT, 90,
			{ material = Enum.Material.Metal, canCollide = false, group = "RoofEquipment" })
	end
	-- Tháp nước góc tây-bắc
	box(eq, "WaterTank", V(-28.8, TERR + 2.40, -163.0), V(5.2, 4.8, 5.2), C_MARBLE_DK, 220,
		{ material = Enum.Material.Metal, group = "RoofEquipment" })
	box(eq, "WaterTankLid", V(-28.8, TERR + 4.95, -163.0), V(5.8, 0.30, 5.8), C_STEEL, 150,
		{ material = Enum.Material.Metal, group = "RoofEquipment" })
	box(eq, "WaterTankLegA", V(-31.0, TERR + 0.45, -163.0), V(0.5, 0.9, 5.4), C_CHAR, 110,
		{ material = Enum.Material.Metal, group = "RoofEquipment" })
	box(eq, "WaterTankLegB", V(-26.6, TERR + 0.45, -163.0), V(0.5, 0.9, 5.4), C_CHAR, 110,
		{ material = Enum.Material.Metal, group = "RoofEquipment" })
	-- Hộp thông gió + cửa sập mái phía nam
	for i, xc in ipairs({ -10.0, 10.0 }) do
		box(eq, "VentBox" .. i, V(xc, TERR + 0.60, -124.0), V(6.0, 1.2, 3.0), C_STEEL_LT, 120,
			{ material = Enum.Material.Metal, group = "RoofEquipment" })
		box(eq, "VentCap" .. i, V(xc, TERR + 1.28, -124.0), V(6.4, 0.16, 3.4), C_CHAR_LT, 90,
			{ material = Enum.Material.Metal, group = "RoofEquipment" })
	end
	box(eq, "RoofHatch", V(17.0, TERR + 0.55, -120.5), V(5.0, 1.1, 3.6), C_STEEL_LT, 160,
		{ material = Enum.Material.Metal, walkable = true, group = "RoofDeck" })

	-- ===== E. CỘT ĂNG-TEN (đứng trên nắp kỹ thuật) =====
	local mast = folder(fRf, "Antenna")
	box(mast, "Footing", V(-19.5, PADY + 0.25, -156.0), V(3.8, 0.5, 3.8), C_MARBLE_DK, 240,
		{ material = Enum.Material.Concrete, group = "Antenna" })
	box(mast, "Base", V(-19.5, PADY + 1.35, -156.0), V(3.0, 1.7, 3.0), C_STEEL, 260,
		{ material = Enum.Material.Metal, group = "Antenna" })
	box(mast, "MastLow", V(-19.5, PADY + 5.00, -156.0), V(1.0, 6.0, 1.0), C_STEEL_LT, 300,
		{ material = Enum.Material.Metal, group = "Antenna" })
	box(mast, "MastHigh", V(-19.5, (PADY + 8.0 + MAST_TOP) * 0.5, -156.0), V(0.62, MAST_TOP - PADY - 8.0, 0.62),
		C_STEEL_LT, 260, { material = Enum.Material.Metal, group = "Antenna" })
	for i, yc in ipairs({ PADY + 4.0, PADY + 6.0, PADY + 8.0 }) do
		box(mast, "CrossArm" .. i, V(-19.5, yc, -156.0), V(6.6 - i * 1.0, 0.30, 0.30), C_STEEL_LT, 110,
			{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Antenna" })
	end
	box(mast, "DishA", V(-16.8, PADY + 5.0, -156.0), V(0.40, 2.6, 2.6), C_WHITE, 90,
		{ material = Enum.Material.Metal, canCollide = false, group = "Antenna" })
	box(mast, "DishB", V(-22.2, PADY + 3.2, -156.0), V(0.40, 2.2, 2.2), C_WHITE, 90,
		{ material = Enum.Material.Metal, canCollide = false, group = "Antenna" })
	local topBea = box(mast, "TopBeacon", V(-19.5, MAST_TOP + 0.45, -156.0), V(1.1, 1.1, 1.1), C_RED, 30,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false, shape = Enum.PartType.Ball,
			group = "Antenna" })
	if topBea then
		local l = Instance.new("PointLight")
		l.Color = C_RED
		l.Brightness = 2.2
		l.Range = 34
		l.Parent = topBea
	end

	-- ===== F. 4 ĐÈN PHA SÂN THƯỢNG =====
	for i, p in ipairs({ { -34.0, -122.0 }, { 34.0, -122.0 }, { -34.0, -127.0 }, { 34.0, -127.0 } }) do
		box(fRf, "RoofFloodPost" .. i, V(p[1], TERR + 1.1, p[2]), V(0.55, 2.2, 0.55), C_CHAR, 100,
			{ material = Enum.Material.Metal, group = "RoofLights" })
		box(fRf, "RoofFloodHead" .. i, V(p[1], TERR + 2.4, p[2]), V(1.5, 0.7, 1.5), C_NEONW, 40,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "RoofLights" })
	end
end

---------------------------------------------------------------------------------------------------
-- 11. HAI CÁNH ĐẾ ĐÔNG / TÂY: HẦM ĐỖ XE (cửa cuốn 18 × 12 studs)
---------------------------------------------------------------------------------------------------
local function buildWing(par: any, tag: string, xMin: number, xMax: number, outIsMin: boolean): ()
	local ox: number = if outIsMin then xMin else xMax          -- mặt ngoài (hướng ra phố)
	local ix: number = if outIsMin then xMax else xMin          -- mặt trong (hướng vào tháp)
	local s: number = if outIsMin then 1 else -1                -- chiều đi vào trong theo X
	local outFace = if outIsMin then Enum.NormalId.Left else Enum.NormalId.Right
	local wOut: number = ox + s * 1.00                          -- tâm tường ngoài (dày 0.9 → mặt ngoài ±82.45)
	local ofx: number = wOut - s * 0.45                         -- mặt ngoài tường (hướng ra phố)
	local wIn: number = ix - s * 0.45                           -- tâm tường trong
	local z0, z1 = -178.0, -96.0
	local zc: number = (z0 + z1) * 0.5
	local FLOORW: number = 1.75                                 -- mặt sàn hầm
	local WTOP: number = 15.85                                  -- đỉnh tường
	local dC: number = -149.0                                   -- tâm cửa cuốn theo Z
	local dHalf: number = 9.0                                   -- nửa chiều rộng (18)
	local dTop: number = 13.30                                  -- đỉnh cửa (1.30 + 12)
	local wx: number = math.abs(ix - ox)                        -- bề rộng cánh

	-- ===== A. SÀN HẦM (4 mảng + 3 bậc dốc lên từ vỉa hè) =====
	box(par, tag .. "_FloorA", V((ox + ix) * 0.5, (1.15 + FLOORW) * 0.5, (z0 + dC - dHalf) * 0.5 + 0.45),
		V(math.abs(ix - ox) - 1.8, FLOORW - 1.15, math.abs(dC - dHalf - z0) - 0.9), C_ASPHALT, nil,
		{ material = Enum.Material.Asphalt, walkable = true, group = tag .. "Floor" })
	box(par, tag .. "_FloorB", V((ox + ix) * 0.5, (1.15 + FLOORW) * 0.5, (dC + dHalf + z1) * 0.5 - 0.45),
		V(math.abs(ix - ox) - 1.8, FLOORW - 1.15, math.abs(z1 - dC - dHalf) - 0.9), C_ASPHALT, nil,
		{ material = Enum.Material.Asphalt, walkable = true, group = tag .. "Floor" })
	box(par, tag .. "_FloorC", V((ox + s * 7.0 + ix) * 0.5 - s * 0.45, (1.15 + FLOORW) * 0.5, dC),
		V(math.abs(ix - (ox + s * 7.0)) - 0.9, FLOORW - 1.15, dHalf * 2), C_ASPHALT, nil,
		{ material = Enum.Material.Asphalt, walkable = true, group = tag .. "Floor" })
	box(par, tag .. "_Apron", V(ox + s * 2.0, 1.225, dC), V(4.0, 0.15, dHalf * 2), C_PAVE_DK, 220,
		{ material = Enum.Material.Concrete, walkable = true, group = tag .. "Floor" })
	for k = 1, 3 do
		box(par, tag .. "_RampStep" .. k, V(ox + s * (4.0 + (k - 0.5)), 1.15 + (0.15 * (k + 1)) * 0.5, dC),
			V(1.0, 0.15 * (k + 1), dHalf * 2), C_MARBLE_DK, 200,
			{ material = Enum.Material.Concrete, walkable = true, group = tag .. "Floor" })
	end

	-- ===== B. TƯỜNG NGOÀI (chừa cửa cuốn 18 × 12) =====
	local wallH: number = WTOP - 1.15
	local wallCY: number = (1.15 + WTOP) * 0.5
	box(par, tag .. "_OutWallA", V(wOut, wallCY, (z0 + dC - dHalf) * 0.5),
		V(0.9, wallH, math.abs(dC - dHalf - z0)), C_MARBLE_DK, 400,
		{ material = Enum.Material.Concrete, group = tag .. "Walls" })
	box(par, tag .. "_OutWallB", V(wOut, wallCY, (dC + dHalf + z1) * 0.5),
		V(0.9, wallH, math.abs(z1 - dC - dHalf)), C_MARBLE_DK, 400,
		{ material = Enum.Material.Concrete, group = tag .. "Walls" })
	box(par, tag .. "_OutWallHeader", V(wOut, (dTop + WTOP) * 0.5, dC), V(0.9, WTOP - dTop, dHalf * 2),
		C_MARBLE_DK, 380, { material = Enum.Material.Concrete, group = tag .. "Walls" })
	-- 2 mảng kính cao trên tường ngoài (ánh sáng cho hầm)
	for i, zsg in ipairs({ -168.0, -106.0 }) do
		box(par, tag .. "_OutGlass" .. i, V(wOut, 11.60, zsg), V(0.5, 4.2, 12.0), C_GLASS_LT, 90,
			{ material = Enum.Material.Glass, transparency = 0.45, castShadow = false, group = tag .. "Glass" })
		for m = 0, 3 do
			box(par, tag .. "_OutGlassMullion" .. i .. "_" .. m, V(wOut, 11.60, zsg - 6.0 + m * 4.0),
				V(0.66, 4.2, 0.34), C_CHAR, 120,
				{ material = Enum.Material.Metal, castShadow = false, group = tag .. "Glass" })
		end
		box(par, tag .. "_OutGlassSill" .. i, V(wOut, 9.42, zsg), V(0.78, 0.34, 12.3), C_GOLD_DK, 160,
			{ material = Enum.Material.Metal, group = tag .. "Walls" })
		box(par, tag .. "_OutGlassLintel" .. i, V(wOut, 13.78, zsg), V(0.78, 0.34, 12.3), C_GOLD_DK, 160,
			{ material = Enum.Material.Metal, group = tag .. "Walls" })
	end

	-- ===== C. TƯỜNG TRONG + TƯỜNG ĐẦU HỒI =====
	box(par, tag .. "_InWallA", V(wIn, wallCY, (z0 - 172.5) * 0.5), V(0.9, wallH, math.abs(-172.5 - z0)),
		C_MARBLE, 400, { material = Enum.Material.Concrete, group = tag .. "Walls" })
	box(par, tag .. "_InWallB", V(wIn, wallCY, (-167.5 + z1) * 0.5), V(0.9, wallH, math.abs(z1 + 167.5)),
		C_MARBLE, 400, { material = Enum.Material.Concrete, group = tag .. "Walls" })
	box(par, tag .. "_InWallHeader", V(wIn, (10.75 + WTOP) * 0.5, -170.0), V(0.9, WTOP - 10.75, 5.0),
		C_MARBLE, 380, { material = Enum.Material.Concrete, group = tag .. "Walls" })
	-- Cửa đi bộ trong tường (2 cánh + khung vàng)
	box(par, tag .. "_PedDoorL", V(wIn, 6.25, -171.25), V(1.1, 9.0, 2.4), C_STEEL_LT, 240,
		{ material = Enum.Material.Metal, group = tag .. "Doors" })
	box(par, tag .. "_PedDoorR", V(wIn, 6.25, -168.75), V(1.1, 9.0, 2.4), C_STEEL_LT, 240,
		{ material = Enum.Material.Metal, group = tag .. "Doors" })
	box(par, tag .. "_PedDoorPush", V(wIn - s * 0.62, 5.6, -170.0), V(0.16, 0.16, 3.6), C_GOLD_LT, 70,
		{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = tag .. "Doors" })
	-- Tường đầu hồi Bắc / Nam
	box(par, tag .. "_EndWallN", V((ox + ix) * 0.5, wallCY, z0 + 0.42), V(math.abs(ix - ox) - 0.9, wallH - 0.12, 0.96),
		C_MARBLE_DK, 420, { material = Enum.Material.Concrete, group = tag .. "Walls" })
	box(par, tag .. "_EndWallS", V((ox + ix) * 0.5, wallCY, z1 - 0.42), V(math.abs(ix - ox) - 0.9, wallH - 0.12, 0.96),
		C_MARBLE_DK, 420, { material = Enum.Material.Concrete, group = tag .. "Walls" })
	-- Chân tường gạch (viên gạch 5.5 × 1.1) trên mặt hướng ra quảng trường
	local bx0: number = math.min(ox, ix) + 0.4
	local bx1: number = math.max(ox, ix) - 0.4
	brickWall(par, tag .. "_EndBrickS", "X", z1 - 0.92, bx0, bx1, 1.15, 0.55, 4, 1.05, C_PAVE_DK, 150,
		tag .. "Brick")

	-- ===== D. CỬA CUỐN 18 × 12 =====
	local dr = folder(par, tag .. "_RollupDoor")
	local slatH: number = (dTop - 1.30) / 12
	for k = 1, 12 do
		box(dr, tag .. "_Slat" .. k, V(wOut, 1.30 + (k - 0.5) * slatH, dC), V(0.30, slatH - 0.05, dHalf * 2 - 0.5),
			if k % 2 == 0 then C_STEEL_LT else C_STEEL, 480,
			{ material = Enum.Material.Metal, group = tag .. "Rollup" })
	end
	box(dr, tag .. "_GuideL", V(wOut + s * 0.30, 7.30, dC + dHalf - 0.25), V(0.55, 12.28, 0.5), C_CHAR, 300,
		{ material = Enum.Material.Metal, group = tag .. "Rollup" })
	box(dr, tag .. "_GuideR", V(wOut + s * 0.30, 7.30, dC - dHalf + 0.25), V(0.55, 12.28, 0.5), C_CHAR, 300,
		{ material = Enum.Material.Metal, group = tag .. "Rollup" })
	box(dr, tag .. "_HeadBox", V(wOut, 13.42, dC), V(0.70, 0.9, dHalf * 2 + 1.0), C_STEEL, 320,
		{ material = Enum.Material.Metal, group = tag .. "Rollup" })
	box(dr, tag .. "_Motor", V(wOut + s * 0.55, 12.85, dC + dHalf - 2.0), V(0.8, 0.8, 1.4), C_CHAR, 180,
		{ material = Enum.Material.Metal, group = tag .. "Rollup" })
	-- Sọc cảnh báo vàng/đen trên đà cửa
	segmentedRow(par, tag .. "_HazardBand", 9,
		function(i) return V(wOut + s * 0.02, 14.05, dC - dHalf + (i - 0.5) * (dHalf * 2 / 9)) end,
		function(i) return V(0.16, 0.42, dHalf * 2 / 9 - 0.06) end,
		function(i) return if i % 2 == 0 then C_YELLOW else C_CHAR end, 90,
		{ material = Enum.Material.SmoothPlastic, castShadow = false, group = tag .. "Trim" })
	-- ===== E. CỘT + VẠCH ĐỖ XE + GỜ CHẶN BÁNH =====
	local colX1: number = ox + s * 9.5          -- hàng cột ngoài
	local colX2: number = ox + s * 16.5         -- hàng cột trong
	local aisleX: number = (colX1 + colX2) * 0.5
	local bayOutX: number = ox + s * 4.9        -- ô đỗ sát tường ngoài
	local bayInX: number = ox + s * 19.3        -- ô đỗ sát tường trong
	for row, cx in ipairs({ colX1, colX2 }) do
		for j = 1, 6 do
			local cz: number = -171.0 + (j - 1) * 12.0
			local g = folder(par, string.format("%s_Col_%d_%d", tag, row, j))
			box(g, tag .. "_ColBase_" .. row .. "_" .. j, V(cx, FLOORW + 0.25, cz), V(2.2, 0.5, 2.2), C_MARBLE_DK, 300,
				{ material = Enum.Material.Concrete, group = tag .. "Columns" })
			box(g, tag .. "_ColShaft_" .. row .. "_" .. j, V(cx, 8.77, cz), V(1.5, 13.04, 1.5), C_MARBLE, 340,
				{ material = Enum.Material.Concrete, group = tag .. "Columns" })
			box(g, tag .. "_ColCap_" .. row .. "_" .. j, V(cx, 15.54, cz), V(2.2, 0.5, 2.2), C_GOLD_DK, 280,
				{ material = Enum.Material.Metal, group = tag .. "Columns" })
			box(g, tag .. "_ColLamp_" .. row .. "_" .. j, V(cx + s * 0.85, 12.90, cz), V(0.2, 0.9, 1.6), C_NEONW, 35,
				{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = tag .. "Lights" })
			-- Gờ chặn bánh ngay cạnh mỗi cột (ống dừng xe)
			box(g, tag .. "_WheelStop_" .. row .. "_" .. j, V(cx, FLOORW + 0.19, cz), V(1.0, 0.34, 4.6), C_PAVE_DK, 130,
				{ material = Enum.Material.Concrete, group = tag .. "Markings" })
		end
	end
	-- Vạch trắng chia ô đỗ: 2 dãy (ô 5.6 × 6.2), 11 vạch mỗi dãy
	for row, bx in ipairs({ bayOutX, bayInX }) do
		segmentedRow(par, string.format("%s_BayStripe_%d", tag, row), 8,
			function(i) return V(bx, FLOORW + 0.02, z0 + 8.0 + (i - 1) * 8.6) end,
			function(i) return V(if row == 1 then 5.6 else 3.2, 0.04, 0.22) end,
			function(i) return C_WHITE end, 60,
			{ material = Enum.Material.SmoothPlastic, walkable = true, castShadow = false, group = tag .. "Markings" })
	end
	-- Làn xe chạy giữa 2 dãy cột: vạch vàng biên + 3 mũi tên trắng
	box(par, tag .. "_AisleLineA", V(aisleX - s * 3.0, FLOORW + 0.02, -137.0), V(0.24, 0.04, 66.0), C_YELLOW, 60,
		{ material = Enum.Material.SmoothPlastic, walkable = true, castShadow = false, group = tag .. "Markings" })
	box(par, tag .. "_AisleLineB", V(aisleX + s * 3.0, FLOORW + 0.02, -137.0), V(0.24, 0.04, 66.0), C_YELLOW, 60,
		{ material = Enum.Material.SmoothPlastic, walkable = true, castShadow = false, group = tag .. "Markings" })
	for i = 1, 3 do
		box(par, tag .. "_LaneArrow" .. i, V(aisleX, FLOORW + 0.05, -168.0 + (i - 1) * 24.0), V(1.4, 0.05, 3.0),
			C_WHITE, 50, { material = Enum.Material.SmoothPlastic, walkable = true, castShadow = false,
				group = tag .. "Markings" })
	end

	-- ===== F. TRẦN + ĐÈN + QUẠT THÔNG GIÓ =====
	box(par, tag .. "_Ceiling", V((ox + ix) * 0.5, 16.00, zc), V(math.abs(ix - ox) - 1.8, 0.30, math.abs(z1 - z0) - 1.8),
		C_CHAR_LT, nil, { material = Enum.Material.Concrete, structural = true, walkable = true,
			group = tag .. "Ceiling" })
	local CEIL_TOP: number = 16.15
	for i = 1, 6 do
		local cz: number = z0 + 7.0 + (i - 1) * 13.2
		box(par, tag .. "_CeilLight" .. i, V((ox + ix) * 0.5, 15.75, cz), V(9.0, 0.20, 1.4), C_NEONW, 40,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = tag .. "Lights" })
	end
	for i, cz in ipairs({ -165.0, -133.0, -101.0 }) do
		box(par, tag .. "_CeilFan" .. i, V((ox + ix) * 0.5, 15.58, cz), V(6.0, 0.24, 6.0), C_STEEL, 90,
			{ material = Enum.Material.Metal, canCollide = false, group = tag .. "Ceiling" })
	end

	-- ===== G. MÁI + LAN CAN + THIẾT BỊ =====
	box(par, tag .. "_Roof", V((ox + ix) * 0.5, CEIL_TOP + 0.6, zc), V(math.abs(ix - ox), 1.2,
		math.abs(z1 - z0)), C_MARBLE_DK, nil,
		{ material = Enum.Material.Concrete, structural = true, walkable = true, group = tag .. "Roof" })
	local rTop: number = CEIL_TOP + 1.2
	local pcy: number = rTop + 0.85
	box(par, tag .. "_RoofParapetS", V((ox + ix) * 0.5, pcy, z1 - 0.42), V(math.abs(ix - ox) - 0.4, 1.7, 0.72),
		C_MARBLE, 220, { material = Enum.Material.Concrete, group = tag .. "Roof" })
	box(par, tag .. "_RoofParapetN", V((ox + ix) * 0.5, pcy, z0 + 0.42), V(math.abs(ix - ox) - 0.4, 1.7, 0.72),
		C_MARBLE, 220, { material = Enum.Material.Concrete, group = tag .. "Roof" })
	box(par, tag .. "_RoofParapetO", V(ox + s * 0.42, pcy, zc), V(0.72, 1.7, math.abs(z1 - z0) - 1.2),
		C_MARBLE, 220, { material = Enum.Material.Concrete, group = tag .. "Roof" })
	box(par, tag .. "_RoofParapetI", V(ix - s * 0.42, pcy, zc), V(0.72, 1.7, math.abs(z1 - z0) - 1.2),
		C_MARBLE, 220, { material = Enum.Material.Concrete, group = tag .. "Roof" })
	-- Đèn LED viền mái + bảng hiệu hướng phố
	box(par, tag .. "_RoofNeonO", V(ox + s * 0.42, rTop + 1.79, zc), V(0.30, 0.16, math.abs(z1 - z0) - 2.4),
		C_GOLD_LT, 40, { material = Enum.Material.Neon, canCollide = false, castShadow = false,
			group = tag .. "Lights" })
	-- Bảng hiệu mái: 2 cột đỡ trên sàn mái + bảng chữ hai mặt
	local signX: number = ox + s * 2.6
	local signY: number = 20.55
	for _, dz in ipairs({ -11.0, 11.0 }) do
		box(par, string.format("%s_RoofSignPost_%d", tag, (if dz > 0 then 1 else 0)),
			V(signX, 18.24, zc + dz), V(0.46, 1.78, 0.46), C_CHAR, 200,
			{ material = Enum.Material.Metal, group = tag .. "Trim" })
	end
	box(par, tag .. "_RoofSignRailT", V(signX, signY + 1.36, zc), V(0.40, 0.22, 26.6), C_GOLD, 190,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	box(par, tag .. "_RoofSignRailB", V(signX, signY - 1.36, zc), V(0.40, 0.22, 26.6), C_GOLD, 190,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	box(par, tag .. "_RoofSignEndL", V(signX, signY, zc - 13.1), V(0.40, 2.94, 0.24), C_GOLD, 190,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	box(par, tag .. "_RoofSignEndR", V(signX, signY, zc + 13.1), V(0.40, 2.94, 0.24), C_GOLD, 190,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	signBoard(par, tag .. "_RoofSign", V(signX, signY, zc), V(0.30, 2.60, 26.0), C_NAVY,
		{ Enum.NormalId.Left, Enum.NormalId.Right }, {
			{ text = "MAZE BANK · HẦM ĐỖ XE", color = C_GOLD_LT, ths = 1.02, sw = 0.95, sh = 0.56, px = 0.02, py = 0.04 },
			{ text = "VÀO TỪ ĐƯỜNG PHÍA " .. (if outIsMin then "TÂY" else "ĐÔNG"), color = C_GOLD,
				ths = 0.52, sw = 0.95, sh = 0.26, px = 0.02, py = 0.68 },
		}, 200)
	-- 2 cục nóng + ống thông hơi trên mái
	for i, cz in ipairs({ -160.0, -112.0 }) do
		box(par, tag .. "_RoofAc" .. i, V((ox + ix) * 0.5, rTop + 1.0, cz), V(6.0, 2.0, 4.0), C_STEEL, 180,
			{ material = Enum.Material.Metal, group = tag .. "Roof" })
		box(par, tag .. "_RoofAcFan" .. i, V((ox + ix) * 0.5, rTop + 2.1, cz), V(3.0, 0.22, 3.0), C_CHAR, 100,
			{ material = Enum.Material.Metal, canCollide = false, group = tag .. "Roof" })
	end

	-- ===== H. ĐẠO CỤ NHỎ TRONG HẦM =====
	for i, p in ipairs({ { 0.0, -163.0 }, { 1.6, -162.2 }, { 3.2, -163.4 } }) do
		box(par, tag .. "_Cone" .. i, V(ox + s * (6.0 + p[1]), FLOORW + 0.55, p[2]), V(0.9, 1.1, 0.9),
			C_RED, 60, { material = Enum.Material.SmoothPlastic, group = tag .. "Props" })
	end
	for i, p in ipairs({ { -174.0, 1 }, { -174.0, 2 }, { -111.0, 1 } }) do
		box(par, tag .. "_Drum" .. i, V(ox + s * 14.5, FLOORW + 0.75, p[1] + p[2] * 1.6), V(1.5, 1.5, 1.5),
			C_BRONZE, 110, { material = Enum.Material.Metal, group = tag .. "Props" })
	end
	-- Bốt bảo vệ + máy phát vé
	box(par, tag .. "_BoothBase", V(ox + s * 13.0, FLOORW + 0.25, dC + 13.0), V(5.0, 0.5, 5.0), C_MARBLE_DK, 240,
		{ material = Enum.Material.Concrete, group = tag .. "Props" })
	box(par, tag .. "_BoothGlass", V(ox + s * 13.0, FLOORW + 2.2, dC + 13.0), V(4.2, 3.4, 4.2), C_GLASS_LT, 70,
		{ material = Enum.Material.Glass, transparency = 0.45, castShadow = false, group = tag .. "Props" })
	box(par, tag .. "_BoothRoof", V(ox + s * 13.0, FLOORW + 4.05, dC + 13.0), V(5.2, 0.3, 5.2), C_GOLD_DK, 180,
		{ material = Enum.Material.Metal, group = tag .. "Props" })
	box(par, tag .. "_TicketMachine", V(ox + s * 12.4, FLOORW + 1.6, dC + 8.6), V(1.2, 3.2, 1.8), C_CHAR, 160,
		{ material = Enum.Material.Metal, group = tag .. "Props" })
	box(par, tag .. "_TicketScreen", V(ox + s * 12.4, FLOORW + 2.4, dC + 7.66), V(0.9, 1.1, 0.14), C_NEONB, 40,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = tag .. "Props" })

	-- ===== I. MẶT ĐẦU HỒI (quay ra quảng trường) =====
	local wallMidX: number = (ox + ix) * 0.5
	local shelfX: number = ox + s * 0.28                        -- tim các chi tiết ốp trên mặt phố (±82.72)
	for _, face in ipairs({ 1, 2 }) do
		local zOut: number = if face == 1 then z1 else z0
		local zDir2: number = if face == 1 then 1 else -1
		box(par, tag .. "_EndTrim" .. face, V(wallMidX, 14.60, zOut + zDir2 * 0.22),
			V(19.4, 0.55, 0.46), C_GOLD, 200,
			{ material = Enum.Material.Metal, group = tag .. "Trim" })
		box(par, tag .. "_EndBand" .. face, V(wallMidX, 8.65, zOut + zDir2 * 0.24),
			V(19.4, 0.45, 0.50), C_GOLD_DK, 190,
			{ material = Enum.Material.Metal, group = tag .. "Trim" })
		box(par, tag .. "_EndBase" .. face, V(wallMidX, 2.05, zOut + zDir2 * 0.20),
			V(19.6, 1.8, 0.30), C_ASPHALT, 240,
			{ material = Enum.Material.Concrete, group = tag .. "Walls" })
		segmentedRow(par, tag .. "_EndFin" .. face, 8,
			function(i2) return V(ox + s * (1.6 + (i2 - 1) * 2.45), 12.20, zOut + zDir2 * 0.30) end,
			function(i2) return V(0.44, 4.4, 0.50) end,
			function(i2) return C_CHAR_LT end, 130,
			{ material = Enum.Material.Metal, castShadow = false, group = tag .. "Fins" })
	end
	-- Pano "P" lớn ở mặt nam (nhìn từ quảng trường)
	local pSignX: number = wallMidX + s * 3.0
	box(par, tag .. "_EndPBack", V(pSignX, 5.00, z1 + 0.20), V(7.0, 3.6, 0.20), C_GOLD_DK, 190,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	signBoard(par, tag .. "_EndP", V(pSignX, 5.00, z1 + 0.40), V(6.6, 3.2, 0.20), C_NAVY,
		{ Enum.NormalId.Front }, {
			{ text = "P", color = C_GOLD_LT, ths = 1.9, sw = 0.26, sh = 0.80, px = 0.04, py = 0.10 },
			{ text = "HẦM ĐỖ XE", color = C_WHITE, ths = 0.44, sw = 0.60, sh = 0.26, px = 0.36, py = 0.30 },
			{ text = "MAZE BANK", color = C_GOLD, ths = 0.36, sw = 0.60, sh = 0.22, px = 0.36, py = 0.58 },
		}, 190)

	-- ===== J. MẶT PHỐ NGOÀI: NẸP VÀNG + LAM + PANO + BIỂN CỬA CUỐN =====
	-- Mọi chi tiết ốp đều cắm vào mặt tường 0.06–0.12 stud và không vượt mốc ±83.0
	local trimA0, trimA1 = z0 + 1.0, dC - 11.0
	local trimB0, trimB1 = dC + 11.0, z1 - 1.0
	box(par, tag .. "_StrTrimA", V(ofx - s * 0.09, 14.60, (trimA0 + trimA1) * 0.5),
		V(0.30, 0.55, trimA1 - trimA0), C_GOLD, 210,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	box(par, tag .. "_StrTrimB", V(ofx - s * 0.09, 14.60, (trimB0 + trimB1) * 0.5),
		V(0.30, 0.55, trimB1 - trimB0), C_GOLD, 210,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	box(par, tag .. "_StrBand", V(ofx - s * 0.13, 8.65, zc), V(0.38, 0.45, 79.0), C_GOLD_DK, 200,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	box(par, tag .. "_StrBase", V(ofx - s * 0.07, 2.05, zc), V(0.26, 1.8, 79.0), C_ASPHALT, 250,
		{ material = Enum.Material.Concrete, group = tag .. "Walls" })
	segmentedRow(par, tag .. "_StrFin", 10,
		function(i2) return V(ofx - s * 0.20, 12.20, z0 + 6.0 + (i2 - 1) * 7.6) end,
		function(i2) return V(0.52, 4.4, 0.44) end,
		function(i2) return C_CHAR_LT end, 140,
		{ material = Enum.Material.Metal, castShadow = false, group = tag .. "Fins" })
	box(par, tag .. "_StrSignBack", V(ofx - s * 0.08, 5.00, z1 - 12.0), V(0.26, 3.0, 13.0), C_GOLD_DK, 200,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	signBoard(par, tag .. "_StrSign", V(ofx - s * 0.22, 5.00, z1 - 12.0), V(0.34, 2.6, 12.0), C_NAVY,
		{ outFace }, {
			{ text = "MAZE BANK · HẦM ĐỖ XE", color = C_GOLD_LT, ths = 0.80, sw = 0.94, sh = 0.62, px = 0.03, py = 0.18 },
		}, 200)
	-- Đà cửa cuốn: băng neon cảnh báo + biển chữ ngay trên cửa
	box(par, tag .. "_DoorNeon", V(ofx - s * 0.06, 12.98, dC), V(0.20, 0.16, 17.4), C_NEONW, 30,
		{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = tag .. "Lights" })
	box(par, tag .. "_DoorSignBack", V(ofx - s * 0.06, 14.30, dC), V(0.24, 1.36, 15.2), C_NAVY, 210,
		{ material = Enum.Material.Metal, group = tag .. "Trim" })
	signBoard(par, tag .. "_DoorSign", V(ofx - s * 0.20, 14.30, dC), V(0.30, 1.16, 14.6), C_NAVY,
		{ outFace }, {
			{ text = "P   HẦM ĐỖ XE · MAZE BANK", color = C_GOLD_LT, ths = 0.62, sw = 0.94, sh = 0.74, px = 0.03, py = 0.12 },
		}, 230)

	-- Trải nhựa mái + vệt thoát nước
	box(par, tag .. "_RoofMembrane", V((ox + ix) * 0.5, rTop + 0.04, zc), V(wx - 1.6, 0.08, math.abs(z1 - z0) - 1.6),
		RGB(118, 116, 110), nil, { material = Enum.Material.Concrete, walkable = true, castShadow = false, group = tag .. "Roof" })
	-- Chi tiết mái: cửa sập, ống thông hơi, phễu thu nước — tránh mảng phẳng trống
	box(par, tag .. "_RoofHatch", V((ox + ix) * 0.5 - 5.5, rTop + 0.55, zc + 22.0), V(5.6, 1.1, 4.4),
		RGB(146, 148, 150), 180, { material = Enum.Material.Metal, group = tag .. "Roof" })
	box(par, tag .. "_RoofHatchLip", V((ox + ix) * 0.5 - 5.5, rTop + 1.16, zc + 22.0), V(6.0, 0.22, 4.8),
		RGB(96, 100, 106), 160, { material = Enum.Material.Metal, group = tag .. "Roof" })
	for k = 1, 4 do
		local vx: number = (ox + ix) * 0.5 + (if k % 2 == 0 then 4.2 else -4.2)
		local vz: number = zc - 30.0 + (k - 1) * 13.0
		box(par, tag .. "_RoofVent" .. k, V(vx, rTop + 0.62, vz), V(1.5, 1.24, 1.5),
			RGB(126, 130, 134), 90, { material = Enum.Material.Metal, group = tag .. "Roof" })
		box(par, tag .. "_RoofVentCap" .. k, V(vx, rTop + 1.30, vz), V(1.9, 0.16, 1.9),
			RGB(96, 100, 106), 70, { material = Enum.Material.Metal, canCollide = false, castShadow = false, group = tag .. "Roof" })
	end
end


---------------------------------------------------------------------------------------------------
-- 0b. MODULE SPEC (khớp WorldModuleSpec trong DistrictRegistry.luau)
---------------------------------------------------------------------------------------------------
local Module = {
	Id = "Plot_D2_MazeBankTower",
	PlotId = "Plot_D2",
	Order = 40,
	Enabled = true,
}

---------------------------------------------------------------------------------------------------
-- 12. CỔNG CHÍNH + TƯỜNG RANH QUẢNG TRƯỜNG (mặt Nam, Z = −63)
---------------------------------------------------------------------------------------------------
local function buildEntrance(fEnt: any): ()
	local gz: number = PLZ.z1 - 2.0            -- −65.0 : tim tường rào (chừa 1,7 stud cho trụ cổng)
	-- ===== TƯỜNG RANH 2 BÊN (đá + đỉnh vàng) =====
	for side, sgn in ipairs({ -1, 1 }) do
		local x0: number = if sgn < 0 then PLZ.x0 + 1.5 else 9.5
		local x1: number = if sgn < 0 then -9.5 else PLZ.x1 - 1.5
		local cxm: number = (x0 + x1) * 0.5
		local len: number = x1 - x0
		box(fEnt, "FenceWall" .. side, V(cxm, 1.85, gz), V(len, 1.3, 0.62), C_MARBLE_DK, 260,
			{ material = Enum.Material.Concrete, group = "Boundary" })
		box(fEnt, "FenceCoping" .. side, V(cxm, 2.57, gz), V(len + 0.2, 0.14, 0.82), C_GOLD, 140,
			{ material = Enum.Material.Metal, group = "Boundary" })
		-- Trụ đá nhấn mỗi 18 studs
		local nP: number = math.max(1, math.floor(len / 18))
		for i = 1, nP do
			local px: number = x0 + (i - 0.5) * (len / nP)
			box(fEnt, string.format("FencePillar_%d_%d", side, i), V(px, 2.15, gz), V(1.3, 1.9, 1.3), C_MARBLE, 240,
				{ material = Enum.Material.Marble, group = "Boundary" })
			box(fEnt, string.format("FencePillarCap_%d_%d", side, i), V(px, 3.18, gz), V(1.5, 0.18, 1.5), C_GOLD_LT, 120,
				{ material = Enum.Material.Metal, group = "Boundary" })
		end
		-- Hàng rào cây xanh phía trong
		box(fEnt, "Hedge" .. side, V(cxm, 2.45, gz - 1.15), V(len - 1.0, 1.2, 1.4), C_LEAF_DK, 70,
			{ material = Enum.Material.Grass, group = "Boundary" })
	end

	-- ===== 2 TRỤ CỔNG CHÍNH + CỔNG MỞ =====
	for side, sgn in ipairs({ -1, 1 }) do
		local px: number = sgn * 9.6
		box(fEnt, "GatePierBase" .. side, V(px, 1.60, gz), V(3.4, 0.5, 3.4), C_MARBLE_DK, 300,
			{ material = Enum.Material.Concrete, group = "Gate" })
		box(fEnt, "GatePier" .. side, V(px, 4.65, gz), V(2.8, 5.6, 2.8), C_MARBLE, 340,
			{ material = Enum.Material.Marble, group = "Gate" })
		box(fEnt, "GatePierBand" .. side, V(px, 5.15, gz), V(3.0, 0.32, 3.0), C_GOLD_DK, 220,
			{ material = Enum.Material.Metal, group = "Gate" })
		box(fEnt, "GatePierCap" .. side, V(px, 7.72, gz), V(3.3, 0.44, 3.3), C_GOLD_LT, 240,
			{ material = Enum.Material.Metal, group = "Gate" })
		-- Chụp đèn trên trụ
		box(fEnt, "GateLampPost" .. side, V(px, 8.62, gz), V(0.4, 1.4, 0.4), C_GOLD, 90,
			{ material = Enum.Material.Metal, group = "Gate" })
		box(fEnt, "GateLampHead" .. side, V(px, 9.55, gz), V(1.1, 0.8, 1.1), C_NEONW, 40,
			{ material = Enum.Material.Neon, canCollide = false, castShadow = false, group = "Gate" })
		-- Cánh cổng mở vào trong (song sắt dọc)
		local leafX: number = sgn * 7.95
		local lz0, lz1 = gz - 8.4, gz - 0.6
		local leafLen: number = math.abs(lz1 - lz0)
		local leafCZ: number = (lz0 + lz1) * 0.5
		-- Khung cổng: 2 thanh đứng mép + 3 thanh ngang + 9 song sắt rời (nhìn xuyên được)
		box(fEnt, "GateJambIn" .. side, V(leafX, 4.45, lz0 + 0.20), V(0.36, 6.1, 0.40), C_CHAR, 200,
			{ material = Enum.Material.Metal, group = "Gate" })
		box(fEnt, "GateJambOut" .. side, V(leafX, 4.45, lz1 - 0.20), V(0.36, 6.1, 0.40), C_CHAR, 200,
			{ material = Enum.Material.Metal, group = "Gate" })
		for r = 1, 3 do
			box(fEnt, "GateRail" .. side .. "_" .. r, V(leafX, 1.75 + (r - 1) * 2.70, leafCZ),
				V(0.34, 0.30, leafLen - 0.30), C_GOLD_DK, 120,
				{ material = Enum.Material.Metal, group = "Gate" })
		end
		segmentedRow(fEnt, "GateBar" .. side, 9,
			function(i) return V(leafX, 4.45, lz0 + 0.55 + (i - 1) * ((leafLen - 1.1) / 8)) end,
			function(i) return V(0.26, 5.4, 0.20) end,
			function(i) return C_GOLD end, 90,
			{ material = Enum.Material.Metal, canCollide = false, castShadow = false, group = "Gate" })
		box(fEnt, "GateFinial" .. side, V(leafX, 7.72, leafCZ), V(0.42, 0.46, leafLen - 1.4), C_GOLD_LT, 110,
			{ material = Enum.Material.Metal, castShadow = false, group = "Gate" })
	end

	-- ===== ĐÀ NGANG CỔNG + BIỂN "MAZE BANK PLAZA" =====
	box(fEnt, "GateBeam", V(0, 7.95, gz), V(22.4, 1.5, 1.1), C_GOLD_DK, 320,
		{ material = Enum.Material.Metal, group = "Gate" })
	signBoard(fEnt, "GateBeamSign", V(0, 7.95, gz + 0.62), V(20.0, 1.16, 0.24), C_NAVY,
		{ Enum.NormalId.Front }, {
			{ text = "MAZE BANK PLAZA", color = C_GOLD_LT, ths = 0.82, sw = 0.96, sh = 0.78, px = 0.02, py = 0.10 },
		}, 160)
	signBoard(fEnt, "GateBeamSignIn", V(0, 7.95, gz - 0.62), V(20.0, 1.16, 0.24), C_NAVY,
		{ Enum.NormalId.Back }, {
			{ text = "CHÀO MỪNG QUÝ KHÁCH", color = C_GOLD_LT, ths = 0.72, sw = 0.96, sh = 0.78, px = 0.02, py = 0.12 },
		}, 160)

end

---------------------------------------------------------------------------------------------------
-- 13. BUILD — ráp toàn bộ ô đất
---------------------------------------------------------------------------------------------------
function Module.build(modulesContainer: Instance): Instance
	local root = folder(modulesContainer, Module.Id)

	local fPlaza = folder(root, "01_Plaza")
	local fPodium = folder(root, "02_Podium")
	local fLobby = folder(root, "03_Lobby")
	local fTower = folder(root, "04_Tower")
	local fRoof = folder(root, "05_RoofHelipad")
	local fWingE = folder(root, "06_WingEast")
	local fWingW = folder(root, "07_WingWest")
	local fGate = folder(root, "08_Gate")

	buildPlaza(fPlaza)
	buildPodium(fPodium)
	buildLobbyShell(fLobby)
	buildLobbyInterior(fLobby)
	buildTower(fTower)
	buildRoof(fRoof)
	buildWing(fWingE, "EWing", EWING.x0, EWING.x1, false)
	buildWing(fWingW, "WWing", WWING.x0, WWING.x1, true)
	buildEntrance(fGate)

	-- Thuộc tính báo cáo cho Agent Chính / Agent 7 (StreetProps) / Agent 3 (Traffic)
	root:SetAttribute("DestructibleStore", true)
	root:SetAttribute("TowerHeightStuds", MAST_TOP)
	root:SetAttribute("MainEntrance", "X=0, Z=-65 (cổng chính rộng 16.4 studs trên Olympic Fwy)")
	root:SetAttribute("LobbyDoors", "X 0, Z=-104 (cửa đôi kính 16 x 8.8 studs)")
	root:SetAttribute("VehicleRampWest", "X=-83, Z=-149 (cửa cuốn 18 x 12 studs, mặt Tây ra Alta St)")
	root:SetAttribute("VehicleRampEast", "X=+83, Z=-149 (cửa cuốn 18 x 12 studs, mặt Đông ra San Andreas Ave)")
	root:SetAttribute("Helipad", "X=0, Z=-143, đường kính 30 studs, cao độ 155.1")
	root:SetAttribute("PlotId", Module.PlotId)
	root:SetAttribute("ModuleId", Module.Id)

	return root
end

return Module
