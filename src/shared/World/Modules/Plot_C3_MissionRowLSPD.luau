--!strict
--[[
	Plot_C3_MissionRowLSPD.luau  —  ĐỒN CẢNH SÁT MISSION ROW (LSPD)
	================================================================================
	Tác giả : Worker Agent — nhánh arena/e461e643-robloxstudio-connecting
	Task    : AGENT_3_MISSION_ROW_LSPD   |   Order 40
	Ô đất   : Plot_C3_East  —  Bounds X ∈ [222 .. 299], Z ∈ [-9 .. 123], groundY = 1.15
	Mặt tiền: Nam (+Z) nhìn thẳng ra Vespucci Blvd  •  Hông Đông (+X) ra Elgin Ave

	BỐ CỤC CÔNG TRÌNH (khối nhà X 232..282, Z 4..70 — cao 34.5 studs):
	  • Sân trước (plaza) Z 70..122: 3 bậc tam cấp đá, 4 cột đá vuông, cột cờ, bãi đỗ xe
	    cảnh sát phía Đông (3 ô vạch trắng + gờ chặn bánh), cọc chắn, chậu cây, đèn sân.
	  • Mặt tiền: bảng hiệu huy hiệu "LOS SANTOS POLICE DEPT — OBEY & SURVIVE" chữ nổi Neon,
	    cửa kính đôi tự động cao 9.0 studs, 4 ô kính tầng trệt + 5 ô kính tầng 2.
	  • Khoang xe cảnh sát (Sally Port) ở hông Đông: cửa cuốn 18 × 12 studs (>= 15 × 11).
	  • Tầng trệt: sảnh trực ban + quầy kính chắn, 4 bàn thám tử, bảng truy nã, phòng giam
	    2 buồng song sắt, nhà vệ sinh, phòng nghỉ, phòng vũ khí, phòng sever.
	  • Tầng 2: phòng họp giao ban (ghế xếp bậc), phòng thay đồ + tủ locker, phòng trưởng đồn
	    vách kính, kho hồ sơ; hành lang có lan can nhìn xuống sảnh.
	  • Sân thượng: bãi đáp trực thăng chữ "H" trắng, vòng tròn đáp, lan can an toàn,
	    2 đèn hiệu đỏ/xanh, cụm điều hoà, cột ăng-ten, buồng cầu thang.

	QUY TẮC KỸ THUẬT ĐÃ TUÂN THỦ:
	  • 100% khối dựng bằng PartBuilder.part / PartBuilder.masonryWall / PartBuilder.staircase
	    và LUÔN truyền `integrity` (trừ móng/sàn/mái chịu lực) → máu ẩn Destructible/PartHealth.
	  • Sàn lát riêng mặt trên Y = 2.05 (pad nền 1.20, vỉa hè 1.15) → 0 Z-fighting.
	  • Cửa đi 9.0 studs (>= 8) • trần tầng trệt 14.95 studs (>= 14) • cửa cuốn 18 × 12 (>= 15 × 11).
	  • Hiệu năng (docs/PERFORMANCE.md): pass cuối `applyPerfPass` đặt CanTouch = false toàn bộ,
	    tắt va chạm cho part nhỏ < 1.6 stud, tắt CastShadow cho part nhỏ / kính / Neon,
	    tắt EnableFluidForces. Không dùng SurfaceGui (chữ nổi 3D ghép khối) → không TextScaled.
	  • Không sửa bất kỳ file lõi nào, không chạm studio-sync.json.
	================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartBuilder = require(Shared:WaitForChild("World"):WaitForChild("PartBuilder"))

local V = Vector3.new
local RGB = Color3.fromRGB
local M = Enum.Material

local Module = {
	Id = "Plot_C3_MissionRowLSPD",
	PlotId = "Plot_C3_East",
	Order = 40,
	Enabled = true,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. TOẠ ĐỘ CHUẨN (khớp WorldGrid + AGENT_TASK_BOARD)
-- ═══════════════════════════════════════════════════════════════════════════
local GROUND = 1.15 -- vỉa hè / mặt nền ô đất
local PAD_TOP = 1.20 -- mặt trên tấm EngineeredFoundationPad của CityFoundation
local PLAZA = 1.34 -- mặt sàn sân trước (lệch 0.14 so với pad)
local FLOOR = 2.05 -- mặt sàn trong nhà (bệ đá cao 0.71 so với sân)
local FLR = 2.09 -- mặt sàn hoàn thiện bên trong (lớp gạch 0.04 phía trên)

-- Ranh giới xây lõi Plot_C3_East
local BMIN_X, BMAX_X = 222.0, 299.0
local BMIN_Z, BMAX_Z = -9.0, 123.0

-- Khối nhà chính
local BX0, BX1 = 232.0, 282.0 -- 50 studs
local BZ0, BZ1 = 4.0, 70.0 -- 66 studs
local WT = 1.2
local IN_X0, IN_X1 = BX0 + WT, BX1 - WT -- 233.2 .. 280.8
local IN_Z0, IN_Z1 = BZ0 + WT, BZ1 - WT -- 5.2 .. 68.8
local FRONT_ZC = BZ1 - WT * 0.5 -- 69.4
local BACK_ZC = BZ0 + WT * 0.5 -- 4.6
local WEST_XC = BX0 + WT * 0.5 -- 232.6
local EAST_XC = BX1 - WT * 0.5 -- 281.4

-- Cao độ
local GF_CEIL = 17.00 -- trần tầng trệt (thông thuỷ 14.95)
local F2_FLOOR = 17.35 -- mặt trên sàn tầng 2
local F2_CEIL = 32.00 -- trần tầng 2 (thông thuỷ 14.65)
local ROOF_TOP = 32.50 -- mặt trên sàn mái
local PARAPET_TOP = 34.50 -- đỉnh lan can mái

-- Cửa & lỗ mở mặt tiền Nam
local DOOR_A, DOOR_B = 251.0, 259.0 -- cửa kính đôi rộng 8
local DOOR_TOP = 11.05 -- cao 9.0 studs
-- Cửa cuốn Sally Port hông Đông (mặt phẳng X = BX1)
local SP_Z0, SP_Z1 = 20.0, 38.0 -- rộng 18
local SP_TOP = 14.05 -- cao 12.0 studs

-- Portico (sảnh cột)
local PORCH_X0, PORCH_X1 = 242.0, 272.0
local PORCH_Z0, PORCH_Z1 = 69.2, 76.0 -- ngàm 0.8 vào tường để không đồng phẳng
local PORCH_TOP = FLOOR -- 2.05
local CANOPY_Y = 13.00 -- mặt trên mái portico
local FLR2 = 17.39 -- mặt sàn hoàn thiện tầng 2
local ROOFY = 32.54 -- mặt sàn hoàn thiện mái

-- Sân trước
local PLZ_X0, PLZ_X1 = 224.0, 298.0
local PLZ_Z0, PLZ_Z1 = 76.5, 122.0

-- Bãi đỗ xe cảnh sát (phía Đông sân trước)
local PARK_X0, PARK_X1 = 266.0, 296.0
local PARK_Z0, PARK_Z1 = 80.0, 112.0

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. BẢNG MÀU (chuẩn LSPD — be sáng + navy + kính xanh nhạt)
-- ═══════════════════════════════════════════════════════════════════════════
local C = {
	STONE = RGB(214, 208, 196), -- be sáng chủ đạo
	STONE_DK = RGB(178, 172, 160),
	STONE_LT = RGB(232, 228, 218),
	NAVY = RGB(27, 58, 107),
	NAVY_DK = RGB(17, 38, 72),
	NAVY_LT = RGB(46, 88, 148),
	GLASS = RGB(150, 196, 216),
	GLASS_DK = RGB(96, 148, 176),
	STEEL = RGB(104, 112, 122),
	STEEL_DK = RGB(52, 58, 68),
	STEEL_LT = RGB(160, 168, 178),
	CHROME = RGB(198, 204, 212),
	CONCRETE = RGB(150, 148, 142),
	CONCRETE_DK = RGB(112, 112, 108),
	ASPHALT = RGB(56, 58, 64),
	WHITE = RGB(240, 240, 236),
	BLACK = RGB(26, 28, 32),
	RED = RGB(178, 40, 36),
	RED_NEON = RGB(255, 66, 52),
	BLUE_NEON = RGB(66, 150, 255),
	GREEN = RGB(56, 128, 76),
	YELLOW = RGB(238, 190, 42),
	GOLD = RGB(214, 172, 58),
	WOOD = RGB(140, 100, 66),
	WOOD_DK = RGB(96, 68, 46),
	LEATHER = RGB(52, 56, 64),
	FABRIC = RGB(70, 76, 88),
	TILE = RGB(206, 208, 204),
	TILE_DK = RGB(168, 170, 166),
	NEON_W = RGB(232, 242, 255),
	NEON_B = RGB(96, 170, 255),
	NEON_R = RGB(255, 70, 60),
	OLIVE = RGB(74, 82, 62),
	ORANGE = RGB(224, 118, 40),
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. LỚP TIỆN ÍCH DỰNG KHỐI
-- ═══════════════════════════════════════════════════════════════════════════
type Opts = { [string]: any }

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function merge(into: Opts, from: Opts?): Opts
	if from then
		for k, v in pairs(from) do
			into[k] = v
		end
	end
	return into
end

-- Áp quy tắc hiệu năng cho MỌI BasePart của công trình (kể cả khối gạch do masonryWall sinh ra)
local function applyPerfPass(root: Instance)
	local count = 0
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("BasePart") then
			count += 1
			obj.CanTouch = false
			obj.EnableFluidForces = false
			local p = obj :: BasePart
			local sz = p.Size
			local maxDim = math.max(sz.X, sz.Y, sz.Z)
			local thinWide = sz.Y <= 1.3 and sz.X >= 4 and sz.Z >= 4 -- sàn / mái mỏng rộng
			if not thinWide and maxDim < 1.6 then
				p.CanCollide = false
			end
			if maxDim < 2.6 or p.Transparency > 0.2 or p.Material == M.Neon then
				p.CastShadow = false
			end
		end
	end
	root:SetAttribute("PartCount", count)
	return count
end

-- box: 1 khối hộp có máu ẩn. `structural = true` → móng/sàn/mái chịu lực (không phá huỷ).
local function box(
	parent: Instance,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?,
	opts: Opts?
): Part
	local structural = false
	if opts and opts.structural ~= nil then
		structural = opts.structural == true
	end
	local spec: Opts = {
		name = name,
		parent = parent,
		size = size,
		pos = pos,
		color = color,
		material = material or M.SmoothPlastic,
		destructible = not structural,
		integrity = (if structural then nil else (hp or 130)),
		fractureGroup = group or "LSPD",
		structuralRow = row,
	}
	if opts then
		for k, v in pairs(opts) do
			if k ~= "structural" then
				spec[k] = v
			end
		end
	end
	return PartBuilder.part(spec :: any)
end

-- rbox: khối hộp xoay theo CFrame
local function rbox(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?,
	opts: Opts?
): Part
	local structural = false
	if opts and opts.structural ~= nil then
		structural = opts.structural == true
	end
	local spec: Opts = {
		name = name,
		parent = parent,
		size = size,
		cframe = cf,
		color = color,
		material = material or M.SmoothPlastic,
		destructible = not structural,
		integrity = (if structural then nil else (hp or 120)),
		fractureGroup = group or "LSPD",
		structuralRow = row,
	}
	if opts then
		for k, v in pairs(opts) do
			if k ~= "structural" then
				spec[k] = v
			end
		end
	end
	return PartBuilder.part(spec :: any)
end

-- cyl: trụ tròn nằm ngang theo trục X (mặc định của Part.Shape = Cylinder)
local function cyl(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?,
	opts: Opts?
): Part
	local spec: Opts = {
		name = name,
		parent = parent,
		size = size,
		cframe = cf,
		color = color,
		material = material or M.Metal,
		shape = Enum.PartType.Cylinder,
		destructible = true,
		integrity = hp or 90,
		fractureGroup = group or "LSPD",
		structuralRow = row,
	}
	if opts then
		for k, v in pairs(opts) do
			spec[k] = v
		end
	end
	return PartBuilder.part(spec :: any)
end

-- vcyl: trụ tròn dựng đứng (trục Y)
local function vcyl(
	parent: Instance,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?,
	opts: Opts?
): Part
	return cyl(parent, name, size, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material, hp, group, row, opts)
end

local function ball(
	parent: Instance,
	name: string,
	diameter: number,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?
): Part
	return PartBuilder.part({
		name = name,
		parent = parent,
		size = V(diameter, diameter, diameter),
		pos = pos,
		color = color,
		material = material or M.SmoothPlastic,
		shape = Enum.PartType.Ball,
		destructible = true,
		integrity = hp or 60,
		fractureGroup = group or "LSPD",
		structuralRow = row,
	})
end

-- brickWall: mảng gạch/đá ghép so le (mỗi viên độc lập có máu ẩn)
local function brickWall(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	baseY: number,
	height: number,
	thickness: number,
	color: Color3,
	hp: number,
	group: string,
	material: Enum.Material?
)
	if c1 - c0 < 0.5 or height < 0.4 then
		return
	end
	local courses = math.max(1, math.round(height / 2.75))
	local ch = height / courses
	PartBuilder.masonryWall({
		name = name,
		parent = parent,
		axis = axis,
		fixedCoord = fixed,
		minCoord = c0,
		maxCoord = c1,
		baseY = baseY,
		thickness = thickness,
		courses = courses,
		courseHeight = ch,
		blockLength = if height >= 12 then 6.4 elseif height >= 5 then 5.6 else 4.4,
		mortarGap = 0.09,
		baseColor = color,
		material = material or M.Brick,
		colorJitter = 7,
		integrity = hp,
		fractureGroup = group,
	})
end

-- Tường có khoét lỗ (cửa/cửa sổ) → chia dải ngang + dải đứng, chỉ dùng viên gạch rời
local function wallWithOpenings(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	baseY: number,
	topY: number,
	thickness: number,
	color: Color3,
	hp: number,
	group: string,
	openings: { { a: number, b: number, y0: number, y1: number } },
	material: Enum.Material?
)
	local ys: { number } = { baseY, topY }
	for _, o in ipairs(openings) do
		table.insert(ys, math.clamp(o.y0, baseY, topY))
		table.insert(ys, math.clamp(o.y1, baseY, topY))
	end
	table.sort(ys)
	local bands: { { number } } = {}
	for i = 1, #ys - 1 do
		if ys[i + 1] - ys[i] > 0.12 then
			table.insert(bands, { ys[i], ys[i + 1] })
		end
	end
	for bi, band in ipairs(bands) do
		local cuts: { number } = { c0, c1 }
		local active: { { a: number, b: number, y0: number, y1: number } } = {}
		for _, o in ipairs(openings) do
			if o.y0 <= band[1] + 0.02 and o.y1 >= band[2] - 0.02 then
				table.insert(cuts, math.clamp(o.a, c0, c1))
				table.insert(cuts, math.clamp(o.b, c0, c1))
				table.insert(active, o)
			end
		end
		table.sort(cuts)
		for i = 1, #cuts - 1 do
			local a, b = cuts[i], cuts[i + 1]
			local isHole = false
			for _, o in ipairs(active) do
				if a >= o.a - 0.02 and b <= o.b + 0.02 then
					isHole = true
					break
				end
			end
			if not isHole and b - a > 0.45 then
				brickWall(
					parent,
					string.format("%s_b%d_s%d", name, bi, i),
					axis,
					fixed,
					a,
					b,
					band[1],
					band[2] - band[1],
					thickness,
					color,
					hp,
					group,
					material
				)
			end
		end
	end
end

-- Vách ngăn nội thất: tường thạch cao đúc khối (1 khối/dải, ít part) + len chân tường
local function panelWall(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	baseY: number,
	topY: number,
	thickness: number,
	color: Color3,
	hp: number,
	group: string,
	openings: { { a: number, b: number, y0: number, y1: number } },
	material: Enum.Material?
)
	local ys: { number } = { baseY, topY }
	for _, o in ipairs(openings) do
		table.insert(ys, math.clamp(o.y0, baseY, topY))
		table.insert(ys, math.clamp(o.y1, baseY, topY))
	end
	table.sort(ys)
	local bands: { { number } } = {}
	for i = 1, #ys - 1 do
		if ys[i + 1] - ys[i] > 0.12 then
			table.insert(bands, { ys[i], ys[i + 1] })
		end
	end
	local mat = material or M.Concrete
	for bi, band in ipairs(bands) do
		local cuts: { number } = { c0, c1 }
		local active: { { a: number, b: number, y0: number, y1: number } } = {}
		for _, o in ipairs(openings) do
			if o.y0 <= band[1] + 0.02 and o.y1 >= band[2] - 0.02 then
				table.insert(cuts, math.clamp(o.a, c0, c1))
				table.insert(cuts, math.clamp(o.b, c0, c1))
				table.insert(active, o)
			end
		end
		table.sort(cuts)
		for i = 1, #cuts - 1 do
			local a, b = cuts[i], cuts[i + 1]
			local isHole = false
			for _, o in ipairs(active) do
				if a >= o.a - 0.02 and b <= o.b + 0.02 then
					isHole = true
					break
				end
			end
			if not isHole and b - a > 0.2 then
				local mid = (a + b) * 0.5
				local cy = (band[1] + band[2]) * 0.5
				local size = if axis == "X" then V(b - a, band[2] - band[1], thickness) else V(thickness, band[2] - band[1], b - a)
				local pos = if axis == "X" then V(mid, cy, fixed) else V(fixed, cy, mid)
				box(parent, string.format("%s_b%d_s%d", name, bi, i), size, pos, color, mat, hp, group, bi)
				-- len chân tường cho dải thấp nhất
				if bi == 1 then
					local skSize = if axis == "X" then V(b - a, 0.55, thickness + 0.14) else V(thickness + 0.14, 0.55, b - a)
					local skPos = if axis == "X" then V(mid, baseY + 0.28, fixed) else V(fixed, baseY + 0.28, mid)
					box(parent, string.format("%s_sk%d", name, i), skSize, skPos, C.NAVY_DK, M.SmoothPlastic, math.max(60, hp * 0.4), group .. "_Skirt" .. tostring(i), bi + 1)
				end
			end
		end
	end
end

-- Dãy khối rời dùng chung fracture group (nan cửa cuốn, vách kính, sọc mái hiên)
local function segmentedRow(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	centerY: number,
	height: number,
	thickness: number,
	segLen: number,
	color: Color3,
	material: Enum.Material?,
	hp: number,
	group: string,
	row: number,
	opts: Opts?
)
	local cursor = c0
	local idx = 1
	while cursor < c1 - 0.05 do
		local segEnd = math.min(c1, cursor + segLen)
		local ln = segEnd - cursor - 0.08
		if ln > 0.1 then
			local mid = (cursor + segEnd) * 0.5
			local pos = if axis == "X" then V(mid, centerY, fixed) else V(fixed, centerY, mid)
			local size = if axis == "X" then V(ln, height, thickness) else V(thickness, height, ln)
			box(parent, string.format("%s_%d", name, idx), size, pos, color, material, hp, group, row, opts)
		end
		cursor = segEnd
		idx += 1
	end
end

-- Ô kính có máu ẩn riêng (bắn vỡ từng tấm)
local function glassPane(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	y0: number,
	y1: number,
	hp: number,
	group: string,
	row: number,
	tint: Color3?
)
	local size = if axis == "X" then V(c1 - c0, y1 - y0, 0.20) else V(0.20, y1 - y0, c1 - c0)
	local pos = if axis == "X"
		then V((c0 + c1) * 0.5, (y0 + y1) * 0.5, fixed)
		else V(fixed, (y0 + y1) * 0.5, (c0 + c1) * 0.5)
	box(parent, name, size, pos, tint or C.GLASS, M.Glass, hp, group, row, {
		transparency = 0.55,
		reflectance = 0.18,
		castShadow = false,
		canCollide = false,
	})
end

-- Thanh nối 2 điểm bất kỳ (ty giằng, lan can, ống, dây, tay vịn)
local function strut(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	thick: number,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?,
	opts: Opts?
): Part
	local d = b - a
	local len = d.Magnitude
	local mid = (a + b) * 0.5
	local yaw = math.atan2(d.X, d.Z)
	local flat = math.sqrt(d.X * d.X + d.Z * d.Z)
	local pitch = math.atan2(flat, d.Y)
	local cf = CFrame.new(mid) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	return rbox(parent, name, V(thick, len, thick), cf, color, material, hp, group, row, opts)
end

local function jitter(base: Color3, seed: number, amount: number): Color3
	local n = ((seed * 37) % 11) - 5
	local d = (n / 5) * (amount / 255)
	return Color3.new(math.clamp(base.R + d, 0, 1), math.clamp(base.G + d, 0, 1), math.clamp(base.B + d * 0.9, 0, 1))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. CHỮ NỔI 3D GHÉP KHỐI (không dùng SurfaceGui → không TextScaled)
-- ═══════════════════════════════════════════════════════════════════════════
local FONT5X7: { [string]: { string } } = {
	A = { "01110", "10001", "10001", "11111", "10001", "10001", "10001" },
	B = { "11110", "10001", "10001", "11110", "10001", "10001", "11110" },
	C = { "01110", "10001", "10000", "10000", "10000", "10001", "01110" },
	D = { "11110", "10001", "10001", "10001", "10001", "10001", "11110" },
	E = { "11111", "10000", "10000", "11110", "10000", "10000", "11111" },
	F = { "11111", "10000", "10000", "11110", "10000", "10000", "10000" },
	G = { "01110", "10001", "10000", "10111", "10001", "10001", "01111" },
	H = { "10001", "10001", "10001", "11111", "10001", "10001", "10001" },
	I = { "11111", "00100", "00100", "00100", "00100", "00100", "11111" },
	J = { "00111", "00010", "00010", "00010", "00010", "10010", "01100" },
	K = { "10001", "10010", "10100", "11000", "10100", "10010", "10001" },
	L = { "10000", "10000", "10000", "10000", "10000", "10000", "11111" },
	M = { "10001", "11011", "10101", "10101", "10001", "10001", "10001" },
	N = { "10001", "11001", "10101", "10011", "10001", "10001", "10001" },
	O = { "01110", "10001", "10001", "10001", "10001", "10001", "01110" },
	P = { "11110", "10001", "10001", "11110", "10000", "10000", "10000" },
	Q = { "01110", "10001", "10001", "10001", "10101", "10010", "01101" },
	R = { "11110", "10001", "10001", "11110", "10100", "10010", "10001" },
	S = { "01111", "10000", "10000", "01110", "00001", "00001", "11110" },
	T = { "11111", "00100", "00100", "00100", "00100", "00100", "00100" },
	U = { "10001", "10001", "10001", "10001", "10001", "10001", "01110" },
	V = { "10001", "10001", "10001", "10001", "10001", "01010", "00100" },
	W = { "10001", "10001", "10001", "10101", "10101", "11011", "10001" },
	X = { "10001", "10001", "01010", "00100", "01010", "10001", "10001" },
	Y = { "10001", "10001", "01010", "00100", "00100", "00100", "00100" },
	Z = { "11111", "00001", "00010", "00100", "01000", "10000", "11111" },
	["0"] = { "01110", "10001", "10011", "10101", "11001", "10001", "01110" },
	["1"] = { "00100", "01100", "00100", "00100", "00100", "00100", "01110" },
	["2"] = { "01110", "10001", "00001", "00010", "00100", "01000", "11111" },
	["3"] = { "11110", "00001", "00001", "01110", "00001", "00001", "11110" },
	["4"] = { "00010", "00110", "01010", "10010", "11111", "00010", "00010" },
	["5"] = { "11111", "10000", "11110", "00001", "00001", "10001", "01110" },
	["6"] = { "00110", "01000", "10000", "11110", "10001", "10001", "01110" },
	["7"] = { "11111", "00001", "00010", "00100", "01000", "01000", "01000" },
	["8"] = { "01110", "10001", "10001", "01110", "10001", "10001", "01110" },
	["9"] = { "01110", "10001", "10001", "01111", "00001", "00010", "01100" },
	["-"] = { "00000", "00000", "00000", "11111", "00000", "00000", "00000" },
	["."] = { "00000", "00000", "00000", "00000", "00000", "01100", "01100" },
	["&"] = { "01100", "10010", "10100", "01000", "10101", "10010", "01101" },
	[":"] = { "00000", "01100", "01100", "00000", "01100", "01100", "00000" },
	["'"] = { "00100", "00100", "00000", "00000", "00000", "00000", "00000" },
	["/"] = { "00001", "00010", "00010", "00100", "01000", "01000", "10000" },
	[" "] = { "00000", "00000", "00000", "00000", "00000", "00000", "00000" },
}

local ADVANCE = 7 -- 5 cột glyph + 2 cột khoảng cách

local function textWidth(text: string, px: number): number
	return math.max(0, #text * ADVANCE * px - 2 * px)
end

-- Chữ nổi trên mặt phẳng Z (nhìn từ +Z). leftX = mép trái, bottomY = mép dưới.
local function drawText(
	parent: Instance,
	name: string,
	text: string,
	leftX: number,
	bottomY: number,
	planeZ: number,
	depth: number,
	px: number,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?,
	opts: Opts?
): number
	local upper = string.upper(text)
	local cursor = 0
	for i = 1, #upper do
		local ch = string.sub(upper, i, i)
		local glyph = FONT5X7[ch]
		if glyph then
			for r = 1, 7 do
				local line = glyph[r]
				local col = 1
				while col <= 5 do
					if string.sub(line, col, col) == "1" then
						local runStart = col
						while col <= 5 and string.sub(line, col, col) == "1" do
							col += 1
						end
						local runLen = col - runStart
						box(
							parent,
							string.format("%s_%s_%d_%d", name, ch, r, runStart),
							V(runLen * px - 0.1, px - 0.1, depth),
							V(leftX + (cursor + runStart - 1) * px + runLen * px * 0.5, bottomY + (7 - r) * px + px * 0.5, planeZ),
							color,
							material or M.Neon,
							hp,
							group,
							row,
							merge({ canCollide = false, castShadow = false }, opts)
						)
					else
						col += 1
					end
				end
			end
			cursor += ADVANCE
		else
			cursor += ADVANCE
		end
	end
	return cursor * px - 2 * px
end

-- Chữ nổi nằm phẳng trên mặt sàn (mặt phẳng XZ) — cho chữ "H" sân đáp & vạch sơn chữ
local function drawTextFlat(
	parent: Instance,
	name: string,
	text: string,
	centerX: number,
	topZ: number,
	topY: number,
	px: number,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?
): number
	local upper = string.upper(text)
	local totalW = textWidth(upper, px)
	local leftX = centerX - totalW * 0.5
	local cursor = 0
	for i = 1, #upper do
		local ch = string.sub(upper, i, i)
		local glyph = FONT5X7[ch]
		if glyph then
			for r = 1, 7 do
				local line = glyph[r]
				local col = 1
				while col <= 5 do
					if string.sub(line, col, col) == "1" then
						local runStart = col
						while col <= 5 and string.sub(line, col, col) == "1" do
							col += 1
						end
						local runLen = col - runStart
						box(
							parent,
							string.format("%s_%s_%d_%d", name, ch, r, runStart),
							V(runLen * px - 0.12, 0.04, px - 0.12),
							V(leftX + (cursor + runStart - 1) * px + runLen * px * 0.5, topY, topZ + (r - 0.5) * px),
							color,
							material or M.SmoothPlastic,
							hp,
							group,
							row,
							{ canCollide = false, castShadow = false }
						)
					else
						col += 1
					end
				end
			end
			cursor += ADVANCE
		else
			cursor += ADVANCE
		end
	end
	return totalW
end

-- Chữ nổi trên mặt phẳng X (tường hướng Đông/Tây, chạy dọc trục Z)
local function drawTextZ(
	parent: Instance,
	name: string,
	text: string,
	planeX: number,
	topZ: number,
	bottomY: number,
	depth: number,
	px: number,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?
): number
	local upper = string.upper(text)
	local cursor = 0
	for i = 1, #upper do
		local ch = string.sub(upper, i, i)
		local glyph = FONT5X7[ch]
		if glyph then
			for r = 1, 7 do
				local line = glyph[r]
				local col = 1
				while col <= 5 do
					if string.sub(line, col, col) == "1" then
						local runStart = col
						while col <= 5 and string.sub(line, col, col) == "1" do
							col += 1
						end
						local runLen = col - runStart
						box(
							parent,
							string.format("%s_%s_%d_%d", name, ch, r, runStart),
							V(depth, px - 0.1, runLen * px - 0.1),
							V(planeX, bottomY + (7 - r) * px + px * 0.5, topZ - (cursor + runStart - 1) * px - runLen * px * 0.5),
							color,
							material or M.Neon,
							hp,
							group,
							row,
							{ canCollide = false, castShadow = false }
						)
					else
						col += 1
					end
				end
			end
			cursor += ADVANCE
		else
			cursor += ADVANCE
		end
	end
	return cursor * px - 2 * px
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 4b. TIỆN ÍCH KIẾN TRÚC DÙNG LẠI (lan can, khung cửa, song sắt, vách kính)
-- ═══════════════════════════════════════════════════════════════════════════

-- Lan can: trụ đứng + tay vịn trên + thanh giữa + con tiện
local function railingRun(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	yBase: number,
	height: number,
	color: Color3,
	group: string,
	row: number,
	opts: Opts?
)
	local len = c1 - c0
	if len < 0.5 then
		return
	end
	local thick = 0.30
	local function put(nm: string, size: Vector3, mid: number, y: number, col: Color3, mat: Enum.Material?, hp: number?, o: Opts?)
		local pos = if axis == "X" then V(mid, y, fixed) else V(fixed, y, mid)
		local sz = if axis == "X" then V(size.X, size.Y, size.Z) else V(size.Z, size.Y, size.X)
		box(parent, nm, sz, pos, col, mat, hp, group, row, o)
	end
	local posts = math.max(2, math.ceil(len / 2.6) + 1)
	for i = 0, posts - 1 do
		local mid = c0 + (len / (posts - 1)) * i
		put(string.format("%s_Post%d", name, i + 1), V(0.26, height, 0.26), mid, yBase + height * 0.5, color, M.Metal, 90, { canCollide = false })
	end
	put(name .. "_TopRail", V(len, 0.24, thick), (c0 + c1) * 0.5, yBase + height - 0.12, color, M.Metal, 130, nil)
	put(name .. "_MidRail", V(len, 0.16, thick * 0.7), (c0 + c1) * 0.5, yBase + height * 0.52, color, M.Metal, 90, { canCollide = false })
	local balusters = math.max(2, math.floor(len / 0.85))
	for i = 1, balusters - 1 do
		local mid = c0 + (len / balusters) * i
		put(string.format("%s_Bal%d", name, i), V(0.11, height - 0.3, 0.11), mid, yBase + height * 0.5, color, M.Metal, 40, { canCollide = false })
	end
	if opts and opts.kick then
		put(name .. "_Kick", V(len, 0.35, 0.14), (c0 + c1) * 0.5, yBase + 0.18, color, M.Metal, 80, { canCollide = false })
	end
end

-- Khung cửa: 2 trụ + thanh đà trên, dày hơn tường để nổi khối
local function doorFrame(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	y0: number,
	y1: number,
	depth: number,
	color: Color3,
	group: string,
	row: number
)
	for i, cx in ipairs({ c0 + 0.20, c1 - 0.20 }) do
		local size = if axis == "X" then V(0.40, y1 - y0, depth) else V(depth, y1 - y0, 0.40)
		local pos = if axis == "X" then V(cx, (y0 + y1) * 0.5, fixed) else V(fixed, (y0 + y1) * 0.5, cx)
		box(parent, string.format("%s_Jamb%d", name, i), size, pos, color, M.Metal, 160, group, row)
	end
	local headSize = if axis == "X" then V(c1 - c0, 0.44, depth) else V(depth, 0.44, c1 - c0)
	box(parent, name .. "_Head", headSize, if axis == "X" then V((c0 + c1) * 0.5, y1 + 0.08, fixed) else V(fixed, y1 + 0.08, (c0 + c1) * 0.5), color, M.Metal, 170, group, row)
end

-- Song sắt buồng giam (thanh dọc + 3 thanh ngang + khung)
local function barredPanel(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	y0: number,
	y1: number,
	color: Color3,
	group: string,
	row: number
)
	local len = c1 - c0
	local h = y1 - y0
	local bars = math.max(2, math.floor(len / 0.82))
	for i = 0, bars do
		local mid = c0 + (len / bars) * i
		local size = if axis == "X" then V(0.15, h, 0.15) else V(0.15, h, 0.15)
		local pos = if axis == "X" then V(mid, (y0 + y1) * 0.5, fixed) else V(fixed, (y0 + y1) * 0.5, mid)
		box(parent, string.format("%s_Bar%d", name, i), size, pos, color, M.Metal, 120, group, row, { canCollide = false })
	end
	for i, ry in ipairs({ 0.25, 0.55, 0.85 }) do
		local size = if axis == "X" then V(len + 0.1, 0.16, 0.16) else V(0.16, 0.16, len + 0.1)
		local pos = if axis == "X" then V((c0 + c1) * 0.5, y0 + h * ry, fixed) else V(fixed, y0 + h * ry, (c0 + c1) * 0.5)
		box(parent, string.format("%s_Cross%d", name, i), size, pos, color, M.Metal, 110, group, row, { canCollide = false })
	end
end

-- Vách kính chia ô (mỗi ô 1 tấm có máu riêng) + khung nhôm
local function glassWall(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	y0: number,
	y1: number,
	paneMax: number,
	group: string,
	rowStart: number
)
	local len = c1 - c0
	local panes = math.max(1, math.ceil(len / paneMax))
	local step = len / panes
	box(parent, name .. "_Sill", if axis == "X" then V(len, 0.16, 0.42) else V(0.42, 0.16, len), if axis == "X" then V((c0 + c1) * 0.5, y0 + 0.08, fixed) else V(fixed, y0 + 0.08, (c0 + c1) * 0.5), C.STEEL_LT, M.Metal, 90, group, rowStart)
	for i = 0, panes do
		local mid = c0 + step * i
		local size = if axis == "X" then V(0.16, y1 - y0, 0.34) else V(0.34, y1 - y0, 0.16)
		local pos = if axis == "X" then V(mid, (y0 + y1) * 0.5, fixed) else V(fixed, (y0 + y1) * 0.5, mid)
		box(parent, string.format("%s_Mullion%d", name, i), size, pos, C.STEEL_LT, M.Metal, 110, group, rowStart + 1, { canCollide = false })
	end
	for i = 1, panes do
		glassPane(
			parent,
			string.format("%s_Pane%d", name, i),
			axis,
			fixed,
			c0 + step * (i - 1) + 0.12,
			c0 + step * i - 0.12,
			y0 + 0.16,
			y1 - 0.08,
			70,
			group,
			rowStart + 2
		)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. SÂN TRƯỚC: SÂN ĐÁ, BẬC TAM CẤP, BÃI XE CẢNH SÁT, CỘT CỜ, ĐÈN
-- ═══════════════════════════════════════════════════════════════════════════
local function buildSite(root: Instance)
	local f = folder(root, "00_SiteWorks")

	-- ── Nền sân liền khối (mặt trên 1.24) + ô lát đá nổi (mặt trên PLAZA) ──
	box(f, "PlazaBase", V(PLZ_X1 - PLZ_X0 + 1.0, 0.16, PLZ_Z1 - PLZ_Z0 + 0.4), V((PLZ_X0 + PLZ_X1) * 0.5, 1.23, (PLZ_Z0 + PLZ_Z1) * 0.5 + 0.3), C.CONCRETE_DK, M.Concrete, 460, "LSPD_PlazaBase", 0, { structural = true })
	-- dải sân giữa porch và bậc thềm (Z 70.0..82.2) — nối liền nền
	box(f, "PlazaApron", V(PLZ_X1 - PLZ_X0, 0.16, 12.4), V((PLZ_X0 + PLZ_X1) * 0.5, 1.245, 76.0), C.CONCRETE_DK, M.Concrete, 460, "LSPD_PlazaApron", 0, { structural = true })

	local nx, nz = 7, 4
	local cw = (PLZ_X1 - PLZ_X0) / nx
	local cd = (PLZ_Z1 - 82.4) / nz -- 9.9
	for ix = 0, nx - 1 do
		for iz = 0, nz - 1 do
			local x0 = PLZ_X0 + ix * cw
			local z0 = 82.4 + iz * cd
			box(
				f,
				string.format("PlazaTile_%d_%d", ix, iz),
				V(cw - 0.34, 0.14, cd - 0.34),
				V(x0 + cw * 0.5, 1.27, z0 + cd * 0.5),
				jitter(C.CONCRETE, ix * 5 + iz * 3, 8),
				M.Concrete,
				300,
				string.format("LSPD_Plaza_%d_%d", ix, iz),
				1,
				{ castShadow = false }
			)
		end
	end

	-- ── Bệ đá sảnh (porch) + 2 bậc tam cấp ──
	box(f, "PorchPlinth", V(PORCH_X1 - PORCH_X0, PORCH_TOP - PLAZA, PORCH_Z1 - PORCH_Z0), V((PORCH_X0 + PORCH_X1) * 0.5, (PLAZA + PORCH_TOP) * 0.5, (PORCH_Z0 + PORCH_Z1) * 0.5), C.STONE_DK, M.Sandstone, 520, "LSPD_Porch", 1)
	-- viền đá sáng quanh mép bệ (nổi 0.10, không đồng phẳng)
	for _, side in ipairs({ "W", "E", "S" }) do
		local x, z = (PORCH_X0 + PORCH_X1) * 0.5, (PORCH_Z0 + PORCH_Z1) * 0.5
		local size = V(0.9, 0.30, PORCH_Z1 - PORCH_Z0)
		local pos = V(PORCH_X0 + 0.52, PORCH_TOP - 0.03, z)
		if side == "E" then
			pos = V(PORCH_X1 - 0.52, PORCH_TOP - 0.03, z)
		elseif side == "S" then
			size = V(PORCH_X1 - PORCH_X0 - 1.8, 0.30, 0.9)
			pos = V(x, PORCH_TOP - 0.03, PORCH_Z1 - 0.35)
		end
		box(f, "PorchEdge" .. side, size, pos, C.STONE_LT, M.Marble, 180, "LSPD_PorchEdge" .. side, 2, { castShadow = false })
	end
	-- 2 bậc tam cấp (mặt trên bệ sảnh là bậc thứ 3)
	local rise = (PORCH_TOP - PLAZA) / 3
	for s = 1, 2 do
		local topY = PORCH_TOP - rise * s
		local zC = PORCH_Z1 + (s - 0.5) * 1.7
		local grp = "LSPD_Step" .. tostring(s)
		box(f, "StepRiser" .. s, V(27.0, topY - PLAZA + 0.06, 1.7), V(257.0, PLAZA + (topY - PLAZA) * 0.5 - 0.03, zC), C.STONE, M.Sandstone, 380, grp, s)
		box(f, "StepNosing" .. s, V(27.2, 0.10, 0.30), V(257.0, topY + 0.09, zC - 0.72), C.STONE_LT, M.Marble, 120, grp .. "_Nosing", s + 1, { canCollide = false, castShadow = false })
	end
	-- Tay vịn 2 bên bậc
	for _, sx in ipairs({ 243.8, 270.2 }) do
		local tag = tostring(math.floor(sx))
		local grp = "LSPD_StepRail" .. tag
		box(f, "StepRailPostA" .. tag, V(0.34, 3.6, 0.34), V(sx, PLAZA + 1.8, 80.6), C.STEEL, M.Metal, 120, grp .. "_A", 1)
		box(f, "StepRailPostB" .. tag, V(0.34, 3.6, 0.34), V(sx, PLAZA + 1.8, 71.2), C.STEEL, M.Metal, 120, grp .. "_B", 1)
		strut(f, "StepHandRail" .. tag, V(sx, PLAZA + 3.5, 80.6), V(sx, PORCH_TOP + 3.5, 71.2), 0.30, C.CHROME, M.Metal, 90, grp .. "_Rail", 2)
	end

	-- ── Bãi đậu xe cảnh sát phía Đông (3 ô, vạch trắng + gờ chặn bánh) ──
	local stallX = { 267.0, 276.6, 286.2, 295.8 }
	box(f, "ParkApron", V(31.0, 0.20, 34.0), V(281.4, 1.32, 97.0), C.ASPHALT, M.Asphalt, 340, "LSPD_ParkApron", 1, { castShadow = false })
	for i, lx in ipairs(stallX) do
		box(f, "ParkLine" .. i, V(0.32, 0.06, 29.0), V(lx, 1.45, 99.5), C.WHITE, M.SmoothPlastic, 60, "LSPD_ParkLine" .. tostring(i), 1, { canCollide = false, castShadow = false })
	end
	for i = 1, 3 do
		local cx = (stallX[i] + stallX[i + 1]) * 0.5
		local grp = "LSPD_ParkBay" .. tostring(i)
		box(f, "WheelStop" .. i, V(7.0, 0.80, 0.95), V(cx, 1.82, 111.0), C.CONCRETE_DK, M.Concrete, 160, grp .. "_Stop", 1)
		box(f, "WheelStopStripe" .. i, V(7.0, 0.14, 1.0), V(cx, 2.28, 111.0), C.YELLOW, M.SmoothPlastic, 60, grp .. "_Stripe", 2, { canCollide = false })
		box(f, "StallPatch" .. i, V(7.6, 0.04, 6.0), V(cx, 1.44, 88.0), RGB(72, 74, 80), M.Asphalt, 40, grp .. "_Patch", 1, { castShadow = false })
		drawTextFlat(f, "StallDigit" .. i, tostring(i), cx, 87.0, 1.48, 1.05, C.WHITE, M.SmoothPlastic, 30, grp .. "_Digit", 1)
	end
	drawTextFlat(f, "ParkLabel", "POLICE", 281.4, 116.4, 1.47, 0.70, C.WHITE, M.SmoothPlastic, 50, "LSPD_ParkLabel", 1)

	-- ── Cổng vào bãi xe: 2 trụ đá + barie ──
	for i, gx in ipairs({ 264.6, 296.6 }) do
		local grp = "LSPD_LotGatePier" .. tostring(i)
		brickWall(f, "LotGatePier" .. i, "X", 116.0, gx - 1.4, gx + 1.4, 1.20, 7.0, 2.8, C.STONE_DK, 300, grp .. "_Brick")
		box(f, "LotGatePierCap" .. i, V(3.4, 0.45, 3.4), V(gx, 8.42, 116.0), C.STONE_LT, M.Marble, 180, grp .. "_Cap", 5)
		ball(f, "LotGateLamp" .. i, 1.9, V(gx, 9.4, 116.0), C.NEON_B, M.Neon, 30, grp .. "_Lamp", 1)
	end
	box(f, "LotBoomCabinet", V(1.7, 3.0, 1.7), V(267.0, 2.82, 114.4), C.NAVY, M.Metal, 120, "LSPD_LotBoom", 1)
	box(f, "LotBoomArm", V(0.50, 16.0, 0.50), V(267.0, 10.6, 114.4), C.WHITE, M.SmoothPlastic, 130, "LSPD_LotBoom_Arm", 2)
	for i = 1, 4 do
		box(f, "LotBoomStripe" .. i, V(0.58, 1.6, 0.58), V(267.0, 5.2 + i * 3.0, 114.4), C.RED, M.SmoothPlastic, 40, "LSPD_LotBoom_Arm", 3, { canCollide = false })
	end

	-- ── Cột cờ trước sảnh ──
	local fx, fz = 235.0, 90.0
	vcyl(f, "FlagPoleBase", V(1.8, 3.4, 3.4), V(fx, 3.0, fz), C.STONE_DK, M.Marble, 220, "LSPD_FlagPole", 1)
	vcyl(f, "FlagPole", V(26.0, 1.0, 1.0), V(fx, 14.4, fz), C.CHROME, M.Metal, 260, "LSPD_FlagPole", 2)
	ball(f, "FlagPoleFinial", 1.3, V(fx, 27.9, fz), C.GOLD, M.Metal, 70, "LSPD_FlagPole", 3)
	for i = 1, 6 do
		box(f, "FlagStripe" .. i, V(0.14, 1.05, 11.0), V(fx + 0.1, 25.9 - (i - 1) * 2.1, fz + 5.6), if i % 2 == 1 then C.RED else C.WHITE, M.Fabric, 30, "LSPD_FlagStripes" .. tostring(i), 1, { canCollide = false, castShadow = false })
	end
	box(f, "FlagCanton", V(0.18, 4.2, 5.4), V(fx + 0.14, 23.8, fz + 2.8), C.NAVY, M.Fabric, 30, "LSPD_FlagCanton", 1, { canCollide = false, castShadow = false })
	for i = 1, 5 do
		ball(f, "FlagStar" .. i, 0.55, V(fx + 0.24, 25.3 - (i - 1) * 0.85, fz + 1.6 + (i % 2) * 1.6), C.WHITE, M.SmoothPlastic, 12, "LSPD_FlagStar" .. tostring(i), 1)
	end

	-- ── Cọc chắn bảo vệ mặt tiền (húc bay được) ──
	PartBuilder.bollardLine({
		name = "FacadeBollards",
		parent = f,
		startPos = V(234.0, PLAZA, 73.6),
		endPos = V(280.0, PLAZA, 73.6),
		count = 8,
		fractureGroup = "LSPD_FacadeBollard",
	})

	-- ── 2 đèn cột sân trước ──
	for i, p in ipairs({ { 227.5, 108.0 }, { 293.5, 78.0 } }) do
		local grp = "LSPD_YardLamp" .. tostring(i)
		local armX = if p[1] < 260 then 1.7 else -1.7
		box(f, "YardLampBase" .. i, V(2.6, 1.0, 2.6), V(p[1], 1.84, p[2]), C.CONCRETE, M.Concrete, 200, grp .. "_Base", 1)
		vcyl(f, "YardLampPole" .. i, V(18.0, 0.9, 0.9), V(p[1], 10.3, p[2]), C.STEEL_DK, M.Metal, 240, grp .. "_Pole", 2)
		box(f, "YardLampArm" .. i, V(3.4, 0.4, 0.4), V(p[1] + armX, 18.8, p[2]), C.STEEL_DK, M.Metal, 90, grp .. "_Arm", 3)
		box(f, "YardLampHead" .. i, V(2.6, 0.8, 1.9), V(p[1] + armX * 2.0, 18.4, p[2]), C.STEEL_DK, M.Metal, 80, grp .. "_Head", 3)
		box(f, "YardLampLens" .. i, V(2.1, 0.24, 1.5), V(p[1] + armX * 2.0, 17.9, p[2]), C.NEON_W, M.Neon, 30, grp .. "_Lens", 4, { canCollide = false, castShadow = false })
	end

	-- ── Chậu cây, băng ghế, thùng rác, trụ nước cứu hoả ──
	for i, p in ipairs({ { 245.0, 84.0 }, { 269.0, 84.0 }, { 229.0, 79.0 } }) do
		local grp = "LSPD_Planter" .. tostring(i)
		box(f, "PlanterBox" .. i, V(5.0, 1.9, 5.0), V(p[1], 2.24, p[2]), C.CONCRETE, M.Concrete, 200, grp .. "_Box", 1)
		box(f, "PlanterSoil" .. i, V(4.4, 0.16, 4.4), V(p[1], 3.14, p[2]), C.OLIVE, M.Ground, 60, grp .. "_Soil", 2, { castShadow = false })
		ball(f, "PlanterBush" .. i, 3.8, V(p[1], 4.6, p[2]), C.GREEN, M.Grass, 50, grp .. "_Bush", 3)
		ball(f, "PlanterBushB" .. i, 2.6, V(p[1] - 0.9, 5.6, p[2] + 0.7), RGB(64, 140, 78), M.Grass, 40, grp .. "_BushB", 4)
	end
	for i, p in ipairs({ { 239.5, 101.0 }, { 252.0, 101.0 } }) do
		local grp = "LSPD_Bench" .. tostring(i)
		box(f, "BenchSeat" .. i, V(7.0, 0.35, 1.9), V(p[1], 1.86, p[2]), C.WOOD, M.WoodPlanks, 90, grp .. "_Seat", 1)
		box(f, "BenchBack" .. i, V(7.0, 1.7, 0.28), V(p[1], 2.86, p[2] + 0.8), C.WOOD, M.WoodPlanks, 80, grp .. "_Back", 2)
		for li, lx in ipairs({ -2.7, 2.7 }) do
			box(f, string.format("BenchLeg%d_%d", i, li), V(0.3, 0.44, 1.7), V(p[1] + lx, 1.55, p[2]), C.STEEL_DK, M.Metal, 80, grp .. "_Leg" .. tostring(li), 1)
		end
	end
	vcyl(f, "TrashBin", V(2.4, 2.4, 2.4), V(284.0, 2.54, 79.0), C.STEEL, M.Metal, 110, "LSPD_TrashBin", 1)
	vcyl(f, "TrashLid", V(0.36, 2.8, 2.8), V(284.0, 3.80, 79.0), C.STEEL_DK, M.Metal, 60, "LSPD_TrashBin", 2)
	vcyl(f, "Hydrant", V(2.6, 1.2, 1.2), V(225.5, 2.6, 96.0), C.RED, M.Metal, 110, "LSPD_Hydrant", 1)
	box(f, "HydrantCap", V(1.5, 0.6, 1.5), V(225.5, 4.1, 96.0), C.RED, M.Metal, 60, "LSPD_Hydrant", 2)
end

-- Cầu thang bộ dựng tay (bậc khít, không chồng mặt phẳng) + 2 dầm nghiêng
local function stairRun(
	parent: Instance,
	name: string,
	origin: Vector3,
	dir: Vector3,
	width: number,
	steps: number,
	totalRise: number,
	totalRun: number,
	color: Color3,
	group: string,
	rowStart: number,
	material: Enum.Material?
)
	local rise = totalRise / steps
	local run = totalRun / steps
	local isZ = math.abs(dir.Z) > 0.5
	for s = 1, steps do
		local topH = s * rise
		local off = (s - 0.5) * run
		local pos = V(origin.X + dir.X * off, origin.Y + topH * 0.5, origin.Z + dir.Z * off)
		local size = if isZ then V(width, topH, run) else V(run, topH, width)
		box(parent, string.format("%s_Step%d", name, s), size, pos, if s % 2 == 0 then color else jitter(color, s, 6), material or M.Marble, 170, string.format("%s_Step%d", name, s), rowStart + (s % 3))
	end
	local half = if isZ then V(width * 0.5 + 0.35, 0, 0) else V(0, 0, width * 0.5 + 0.35)
	local a = V(origin.X + dir.X * 0.4 + half.X, origin.Y + 1.2, origin.Z + dir.Z * 0.4 + half.Z)
	local b = V(origin.X + dir.X * (totalRun - 0.4) + half.X, origin.Y + totalRise + 1.2, origin.Z + dir.Z * (totalRun - 0.4) + half.Z)
	for _, sgn in ipairs({ -1, 1 }) do
		local off = if isZ then V(0, 0, sgn * (width * 0.5 + 0.35)) else V(sgn * (width * 0.5 + 0.35), 0, 0)
		strut(
			parent,
			string.format("%s_Stringer%d", name, sgn < 0 and 1 or 2),
			a + off,
			b + off,
			0.55,
			C.STEEL_DK,
			M.Metal,
			140,
			string.format("%s_Stringer%d", name, sgn < 0 and 1 or 2),
			rowStart
		)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. KẾT CẤU VỎ CÔNG TRÌNH: MÓNG, SÀN, TƯỜNG GẠCH SO LE, LAN CAN MÁI
-- ═══════════════════════════════════════════════════════════════════════════
local function buildShell(root: Instance)
	local f = folder(root, "01_Shell")

	-- ── Bệ móng / nền đá (mặt trên 2.05) ──
	box(f, "BuildingPlinth", V(BX1 - BX0 + 0.8, 0.89, BZ1 - BZ0 + 0.8), V((BX0 + BX1) * 0.5, 1.595, (BZ0 + BZ1) * 0.5), C.STONE_DK, M.Sandstone, 600, "LSPD_Plinth", 0, { structural = true })
	-- gờ chân tường nổi quanh móng (không đồng phẳng)
	box(f, "PlinthCapFront", V(BX1 - BX0 + 1.3, 0.26, 0.9), V((BX0 + BX1) * 0.5, 1.98, BZ1 + 0.2), C.STONE_LT, M.Marble, 240, "LSPD_PlinthCap", 1)
	box(f, "PlinthCapBack", V(BX1 - BX0 + 1.3, 0.26, 0.9), V((BX0 + BX1) * 0.5, 1.98, BZ0 - 0.2), C.STONE_LT, M.Marble, 240, "LSPD_PlinthCap", 1)
	box(f, "PlinthCapWest", V(0.9, 0.26, BZ1 - BZ0), V(BX0 - 0.2, 1.98, (BZ0 + BZ1) * 0.5), C.STONE_LT, M.Marble, 240, "LSPD_PlinthCapW", 1)
	box(f, "PlinthCapEast", V(0.9, 0.26, BZ1 - BZ0), V(BX1 + 0.2, 1.98, (BZ0 + BZ1) * 0.5), C.STONE_LT, M.Marble, 240, "LSPD_PlinthCapE", 1)

	-- ── Sàn tầng trệt: ô gạch granite (mặt trên FLR = 2.09) ──
	local gx, gz = 8, 11
	local tw = (IN_X1 - IN_X0) / gx
	local td = (IN_Z1 - IN_Z0) / gz
	for ix = 0, gx - 1 do
		for iz = 0, gz - 1 do
			local cx = IN_X0 + tw * (ix + 0.5)
			local cz = IN_Z0 + td * (iz + 0.5)
			local inGarage = cx > 261.5 and cz > 19.5 and cz < 38.5
			box(
				f,
				string.format("GFFloor_%d_%d", ix, iz),
				V(tw - 0.22, 0.06, td - 0.22),
				V(cx, 2.06, cz),
				if inGarage then jitter(C.ASPHALT, ix + iz * 3, 6) else jitter(C.TILE, ix * 3 + iz, 5),
				if inGarage then M.Asphalt else M.Marble,
				220,
				string.format("LSPD_GFFloor_%d_%d", ix, iz),
				1,
				{ castShadow = false }
			)
		end
	end
	-- ngưỡng cửa chính (nối sân 2.05 ↔ sàn trong 2.09)
	box(f, "LobbyThreshold", V(9.4, 0.16, 2.4), V(255.0, 2.06, 69.6), C.STONE_LT, M.Marble, 260, "LSPD_Threshold", 1, { castShadow = false })
	box(f, "BackThreshold", V(6.4, 0.16, 2.4), V(271.9, 2.06, 4.4), C.STONE_LT, M.Marble, 240, "LSPD_ThresholdB", 1, { castShadow = false })
	box(f, "WestThreshold", V(2.4, 0.16, 5.4), V(232.4, 2.06, 66.0), C.STONE_LT, M.Marble, 240, "LSPD_ThresholdW", 1, { castShadow = false })

	-- ── Sàn tầng 2 (vách sàn chia 4 mảng, chừa lỗ thang X 234.85..248.5, Z 46.1..53.9) ──
	local slabY = (16.85 + 17.35) * 0.5
	local function slab(nm: string, x0: number, x1: number, z0: number, z1: number)
		box(f, nm, V(x1 - x0, 0.50, z1 - z0), V((x0 + x1) * 0.5, slabY, (z0 + z1) * 0.5), C.STONE_DK, M.Concrete, 600, "LSPD_F2Slab", 6, { structural = true })
	end
	slab("F2SlabA", 231.8, 282.2, 3.8, 46.1)
	slab("F2SlabB", 231.8, 282.2, 53.9, 70.2)
	slab("F2SlabC", 231.8, 234.85, 46.1, 53.9)
	slab("F2SlabD", 248.5, 282.2, 46.1, 53.9)
	-- dầm bo quanh lỗ thang (dày hơn sàn → không đồng phẳng)
	box(f, "StairVoidBeamN", V(14.1, 0.62, 0.55), V(241.7, slabY, 46.1), C.STONE, M.Concrete, 520, "LSPD_StairBeam", 7)
	box(f, "StairVoidBeamS", V(14.1, 0.62, 0.55), V(241.7, slabY, 53.9), C.STONE, M.Concrete, 520, "LSPD_StairBeam", 7)
	box(f, "StairVoidBeamW", V(0.55, 0.62, 7.8), V(234.85, slabY, 50.0), C.STONE, M.Concrete, 520, "LSPD_StairBeam", 7)

	-- ── Sàn tầng 2 hoàn thiện (gạch) ──
	local f2x, f2z = 7, 9
	local f2w = (IN_X1 - IN_X0) / f2x
	local f2d = (IN_Z1 - IN_Z0) / f2z
	for ix = 0, f2x - 1 do
		for iz = 0, f2z - 1 do
			local cx = IN_X0 + f2w * (ix + 0.5)
			local cz = IN_Z0 + f2d * (iz + 0.5)
			local inVoid = cx > 234.85 and cx < 248.5 and cz > 46.1 and cz < 53.9
			if not inVoid then
				box(
					f,
					string.format("F2Floor_%d_%d", ix, iz),
					V(f2w - 0.26, 0.06, f2d - 0.26),
					V(cx, 17.36, cz),
					jitter(C.TILE_DK, ix * 2 + iz * 5, 6),
					M.Marble,
					220,
					string.format("LSPD_F2Floor_%d_%d", ix, iz),
					7,
					{ castShadow = false }
				)
			end
		end
	end

	-- ── TƯỜNG NGOÀI TẦNG TRỆT (gạch so le, khoét cửa + 4 ô kính mỗi mặt) ──
	-- Mặt tiền Nam (hướng Vespucci Blvd)
	wallWithOpenings(f, "FrontWallGF", "X", FRONT_ZC, BX0, BX1, FLOOR, 17.00, WT, C.STONE, 190, "LSPD_FrontGF", {
		{ a = DOOR_A, b = DOOR_B, y0 = FLOOR, y1 = DOOR_TOP },
		{ a = 234.0, b = 237.4, y0 = 4.6, y1 = 12.6 },
		{ a = 237.8, b = 241.5, y0 = 4.6, y1 = 12.6 },
		{ a = 272.6, b = 276.3, y0 = 4.6, y1 = 12.6 },
		{ a = 276.7, b = 280.0, y0 = 4.6, y1 = 12.6 },
	}, M.Brick)
	-- Mặt hông Đông (Elgin Ave) + cửa cuốn Sally Port
	wallWithOpenings(f, "EastWallGF", "Z", EAST_XC, IN_Z0, IN_Z1 - WT, FLOOR, 17.00, WT, C.STONE, 190, "LSPD_EastGF", {
		{ a = SP_Z0, b = SP_Z1, y0 = FLOOR, y1 = SP_TOP },
		{ a = 44.0, b = 48.4, y0 = 4.6, y1 = 12.6 },
		{ a = 48.9, b = 53.3, y0 = 4.6, y1 = 12.6 },
		{ a = 58.0, b = 62.4, y0 = 4.6, y1 = 12.6 },
		{ a = 62.9, b = 67.3, y0 = 4.6, y1 = 12.6 },
	}, M.Brick)
	-- Mặt hông Tây (hẻm kỹ thuật) + cửa phụ
	wallWithOpenings(f, "WestWallGF", "Z", WEST_XC, IN_Z0, IN_Z1 - WT, FLOOR, 17.00, WT, C.STONE, 190, "LSPD_WestGF", {
		{ a = 40.0, b = 44.4, y0 = 4.6, y1 = 12.6 },
		{ a = 44.9, b = 49.3, y0 = 4.6, y1 = 12.6 },
		{ a = 52.0, b = 56.4, y0 = 4.6, y1 = 12.6 },
		{ a = 56.9, b = 61.3, y0 = 4.6, y1 = 12.6 },
		{ a = 63.4, b = 68.2, y0 = FLOOR, y1 = 10.55 },
	}, M.Brick)
	-- Mặt hậu Bắc + cửa hậu
	wallWithOpenings(f, "BackWallGF", "X", BACK_ZC, BX0, BX1, FLOOR, 17.00, WT, C.STONE, 190, "LSPD_BackGF", {
		{ a = 240.0, b = 248.0, y0 = 4.6, y1 = 12.6 },
		{ a = 256.0, b = 264.0, y0 = 4.6, y1 = 12.6 },
		{ a = 269.0, b = 274.8, y0 = FLOOR, y1 = 10.55 },
	}, M.Brick)

	-- ── TƯỜNG NGOÀI TẦNG 2 ──
	wallWithOpenings(f, "FrontWallF2", "X", FRONT_ZC, BX0, BX1, F2_FLOOR, 32.30, WT, C.STONE, 190, "LSPD_FrontF2", {
		{ a = 237.9, b = 244.9, y0 = 19.8, y1 = 28.6 },
		{ a = 245.7, b = 252.7, y0 = 19.8, y1 = 28.6 },
		{ a = 253.5, b = 260.5, y0 = 19.8, y1 = 28.6 },
		{ a = 261.3, b = 268.3, y0 = 19.8, y1 = 28.6 },
		{ a = 269.1, b = 276.1, y0 = 19.8, y1 = 28.6 },
	}, M.Brick)
	wallWithOpenings(f, "EastWallF2", "Z", EAST_XC, IN_Z0, IN_Z1 - WT, F2_FLOOR, 32.30, WT, C.STONE, 190, "LSPD_EastF2", {
		{ a = 22.0, b = 30.0, y0 = 19.8, y1 = 28.6 },
		{ a = 32.0, b = 40.0, y0 = 19.8, y1 = 28.6 },
		{ a = 44.0, b = 52.0, y0 = 19.8, y1 = 28.6 },
		{ a = 56.0, b = 64.0, y0 = 19.8, y1 = 28.6 },
	}, M.Brick)
	wallWithOpenings(f, "WestWallF2", "Z", WEST_XC, IN_Z0, IN_Z1 - WT, F2_FLOOR, 32.30, WT, C.STONE, 190, "LSPD_WestF2", {
		{ a = 40.0, b = 48.0, y0 = 19.8, y1 = 28.6 },
		{ a = 50.0, b = 58.0, y0 = 19.8, y1 = 28.6 },
		{ a = 60.0, b = 66.0, y0 = 19.8, y1 = 28.6 },
		{ a = 10.0, b = 18.0, y0 = 19.8, y1 = 28.6 },
	}, M.Brick)
	wallWithOpenings(f, "BackWallF2", "X", BACK_ZC, BX0, BX1, F2_FLOOR, 32.30, WT, C.STONE, 190, "LSPD_BackF2", {
		{ a = 238.0, b = 246.0, y0 = 19.8, y1 = 28.6 },
		{ a = 248.0, b = 256.0, y0 = 19.8, y1 = 28.6 },
		{ a = 258.0, b = 266.0, y0 = 19.8, y1 = 28.6 },
		{ a = 268.0, b = 276.0, y0 = 19.8, y1 = 28.6 },
	}, M.Brick)

	-- ── Trụ góc đá (quoin) + gờ đai + diềm mái ──
	for i, cnr in ipairs({ { 231.8, 70.7 }, { 282.2, 70.7 }, { 231.8, 3.3 }, { 282.2, 3.3 } }) do
		local grp = "LSPD_Quoin" .. tostring(i)
		box(f, "CornerPier" .. i, V(2.6, 31.2, 2.6), V(cnr[1], 16.94, cnr[2]), C.STONE_LT, M.Sandstone, 620, grp .. "_Body", 2, { structural = true })
		for k = 1, 9 do
			box(f, "CornerQuoin" .. i .. "_" .. k, V(2.9, 0.62, 2.9), V(cnr[1], 3.6 + (k - 1) * 3.4, cnr[2]), C.STONE, M.Sandstone, 300, grp .. "_Q" .. tostring(k), 3)
		end
	end
	-- gờ đai tầng trệt
	box(f, "BeltFront", V(BX1 - BX0 + 1.4, 0.70, 1.3), V((BX0 + BX1) * 0.5, 16.70, BZ1 + 0.05), C.STONE_LT, M.Marble, 420, "LSPD_Belt", 4)
	box(f, "BeltBack", V(BX1 - BX0 + 1.4, 0.70, 1.3), V((BX0 + BX1) * 0.5, 16.70, BZ0 - 0.05), C.STONE_LT, M.Marble, 420, "LSPD_BeltB", 4)
	box(f, "BeltWest", V(1.3, 0.70, BZ1 - BZ0 - 1.2), V(BX0 - 0.05, 16.70, (BZ0 + BZ1) * 0.5), C.STONE_LT, M.Marble, 420, "LSPD_BeltW", 4)
	box(f, "BeltEast", V(1.3, 0.70, BZ1 - BZ0 - 1.2), V(BX1 + 0.05, 16.70, (BZ0 + BZ1) * 0.5), C.STONE_LT, M.Marble, 420, "LSPD_BeltE", 4)
	-- diềm mái (cornice)
	box(f, "CorniceFront", V(BX1 - BX0 + 1.6, 1.00, 1.7), V((BX0 + BX1) * 0.5, 32.30, BZ1 + 0.25), C.STONE_LT, M.Marble, 480, "LSPD_Cornice", 12)
	box(f, "CorniceBack", V(BX1 - BX0 + 1.6, 1.00, 1.7), V((BX0 + BX1) * 0.5, 32.30, BZ0 - 0.25), C.STONE_LT, M.Marble, 480, "LSPD_CorniceB", 12)
	box(f, "CorniceWest", V(1.7, 1.00, BZ1 - BZ0 - 1.8), V(BX0 - 0.25, 32.30, (BZ0 + BZ1) * 0.5), C.STONE_LT, M.Marble, 480, "LSPD_CorniceW", 12)
	box(f, "CorniceEast", V(1.7, 1.00, BZ1 - BZ0 - 1.8), V(BX1 + 0.25, 32.30, (BZ0 + BZ1) * 0.5), C.STONE_LT, M.Marble, 480, "LSPD_CorniceE", 12)

	-- ── Sàn mái bê tông + lớp phủ chống thấm + lan can mái ──
	-- sàn mái chia 4 mảng, chừa lỗ cầu thang lên mái (X 252..264, Z 26..38)
	local function roofSlab(nm: string, x0: number, x1: number, z0: number, z1: number)
		box(f, nm, V(x1 - x0, 0.50, z1 - z0), V((x0 + x1) * 0.5, 32.25, (z0 + z1) * 0.5), C.CONCRETE_DK, M.Concrete, 640, "LSPD_RoofSlab", 13, { structural = true })
	end
	roofSlab("RoofSlabA", BX0 - 0.2, BX1 + 0.2, BZ0 - 0.2, 26.0)
	roofSlab("RoofSlabB", BX0 - 0.2, BX1 + 0.2, 38.0, BZ1 + 0.2)
	roofSlab("RoofSlabC", BX0 - 0.2, 252.0, 26.0, 38.0)
	roofSlab("RoofSlabD", 264.0, BX1 + 0.2, 26.0, 38.0)
	local rx, rz = 6, 8
	local rw = (BX1 - BX0) / rx
	local rd = (BZ1 - BZ0) / rz
	for ix = 0, rx - 1 do
		for iz = 0, rz - 1 do
			local dcx = BX0 + rw * (ix + 0.5)
			local dcz = BZ0 + rd * (iz + 0.5)
			if not (dcx > 251.9 and dcx < 264.1 and dcz > 25.9 and dcz < 38.1) then
				box(
					f,
					string.format("RoofDeck_%d_%d", ix, iz),
					V(rw - 0.3, 0.10, rd - 0.3),
					V(dcx, 32.49, dcz),
					jitter(C.CONCRETE, ix * 4 + iz, 7),
					M.Concrete,
					300,
					string.format("LSPD_RoofDeck_%d_%d", ix, iz),
					14,
					{ castShadow = false }
				)
			end
		end
	end
	-- tường chắn mái (parapet) + nắp đá
	brickWall(f, "ParapetFront", "X", 69.4, BX0, BX1, 32.40, 2.10, 1.2, C.STONE, 260, "LSPD_ParapetF")
	brickWall(f, "ParapetBack", "X", 4.6, BX0, BX1, 32.40, 2.10, 1.2, C.STONE, 260, "LSPD_ParapetB")
	brickWall(f, "ParapetWest", "Z", 232.6, IN_Z0, IN_Z1 - WT, 32.40, 2.10, 1.2, C.STONE, 260, "LSPD_ParapetW")
	brickWall(f, "ParapetEast", "Z", 281.4, IN_Z0, IN_Z1 - WT, 32.40, 2.10, 1.2, C.STONE, 260, "LSPD_ParapetE")
	box(f, "CopingFront", V(BX1 - BX0 + 0.9, 0.35, 1.6), V((BX0 + BX1) * 0.5, 34.58, 69.4), C.STONE_LT, M.Marble, 300, "LSPD_Coping", 16)
	box(f, "CopingBack", V(BX1 - BX0 + 0.9, 0.35, 1.6), V((BX0 + BX1) * 0.5, 34.58, 4.6), C.STONE_LT, M.Marble, 300, "LSPD_CopingB", 16)
	box(f, "CopingWest", V(1.6, 0.35, BZ1 - BZ0 - 1.6), V(232.6, 34.58, (BZ0 + BZ1) * 0.5), C.STONE_LT, M.Marble, 300, "LSPD_CopingW", 16)
	box(f, "CopingEast", V(1.6, 0.35, BZ1 - BZ0 - 1.6), V(281.4, 34.58, (BZ0 + BZ1) * 0.5), C.STONE_LT, M.Marble, 300, "LSPD_CopingE", 16)

	-- ── Cầu thang bộ lên tầng 2 (mỗi bậc 1 khối, có lan can) ──
	stairRun(f, "MainStaircase", V(234.9, FLOOR, 50.0), V(1, 0, 0), 7.6, 16, F2_FLOOR - FLOOR, 13.6, C.STONE_LT, "LSPD_Stair", 2, M.Marble)
	-- lan can nghiêng 2 bên thang
	for _, sideZ in ipairs({ 46.4, 53.6 }) do
		local tag = if sideZ < 50 then "N" else "S"
		local grp = "LSPD_StairRail" .. tag
		for i = 0, 7 do
			local ax = 235.4 + i * 1.9
			local ay = FLOOR + ((ax - 234.9) / 13.6) * (F2_FLOOR - FLOOR)
			box(f, string.format("StairRailPost%s_%d", tag, i + 1), V(0.22, 3.0, 0.22), V(ax, ay + 1.5, sideZ), C.STEEL, M.Metal, 70, grp .. "_P" .. tostring(i + 1), 2, { canCollide = false })
		end
		strut(f, "StairHandRail" .. tag, V(235.4, FLOOR + 3.05, sideZ), V(248.4, F2_FLOOR + 3.05, sideZ), 0.26, C.CHROME, M.Metal, 110, grp .. "_Top", 3)
	end
	-- lan can quanh lỗ thang trên tầng 2
	railingRun(f, "VoidRailN", "X", 46.1, 234.85, 248.5, F2_FLOOR, 3.4, C.STEEL_LT, "LSPD_VoidRailN", 8, { kick = true })
	railingRun(f, "VoidRailS", "X", 53.9, 234.85, 248.5, F2_FLOOR, 3.4, C.STEEL_LT, "LSPD_VoidRailS", 8, { kick = true })
	railingRun(f, "VoidRailW", "Z", 234.85, 46.4, 53.6, F2_FLOOR, 3.4, C.STEEL_LT, "LSPD_VoidRailW", 8, { kick = true })

	-- ── Hành lang ban công tầng 2 nhìn xuống sảnh (mặt trước) ──
	-- (sàn tầng 2 đã che sảnh; lan can dưới đây là lan can kính nội bộ dọc Z = 56.4)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. MẶT TIỀN: PORTICO 4 CỘT ĐÁ, CỬA KÍNH ĐÔI, BẢNG HIỆU NEON, CỬA CUỐN
-- ═══════════════════════════════════════════════════════════════════════════

-- Cụm cửa sổ: khung đá + đố nhôm + từng ô kính có máu riêng
local function windowUnit(
	parent: Instance,
	axis: "X" | "Z",
	fixed: number,
	a: number,
	b: number,
	y0: number,
	y1: number,
	cols: number,
	rows: number,
	tag: string,
	group: string,
	rowBase: number
)
	local len = b - a
	local h = y1 - y0
	-- trụ khung 2 bên
	for i, c in ipairs({ a + 0.15, b - 0.15 }) do
		local size = if axis == "X" then V(0.30, h + 0.3, 1.75) else V(1.75, h + 0.3, 0.30)
		local pos = if axis == "X" then V(c, (y0 + y1) * 0.5, fixed) else V(fixed, (y0 + y1) * 0.5, c)
		box(parent, string.format("%s_Jamb%d", tag, i), size, pos, C.STONE_LT, M.Concrete, 170, group, rowBase + 1)
	end
	-- bệ đá + thanh đà trên
	local sillSize = if axis == "X" then V(len + 0.8, 0.32, 2.15) else V(2.15, 0.32, len + 0.8)
	local sillPos = if axis == "X" then V((a + b) * 0.5, y0 - 0.10, fixed) else V(fixed, y0 - 0.10, (a + b) * 0.5)
	box(parent, tag .. "_Sill", sillSize, sillPos, C.STONE_LT, M.Marble, 190, group, rowBase + 1)
	local headSize = if axis == "X" then V(len + 0.9, 0.42, 1.9) else V(1.9, 0.42, len + 0.9)
	local headPos = if axis == "X" then V((a + b) * 0.5, y1 + 0.16, fixed) else V(fixed, y1 + 0.16, (a + b) * 0.5)
	box(parent, tag .. "_Head", headSize, headPos, C.STONE_LT, M.Marble, 190, group, rowBase + 2)
	-- đố dọc
	local step = len / cols
	for i = 1, cols - 1 do
		local c = a + step * i
		local size = if axis == "X" then V(0.16, h, 0.30) else V(0.30, h, 0.16)
		local pos = if axis == "X" then V(c, (y0 + y1) * 0.5, fixed) else V(fixed, (y0 + y1) * 0.5, c)
		box(parent, string.format("%s_Mull%d", tag, i), size, pos, C.STEEL_LT, M.Metal, 110, group, rowBase + 2, { canCollide = false })
	end
	-- đố ngang (transom)
	local rowH = h / rows
	for i = 1, rows - 1 do
		local cy = y0 + rowH * i
		local size = if axis == "X" then V(len, 0.14, 0.30) else V(0.30, 0.14, len)
		local pos = if axis == "X" then V((a + b) * 0.5, cy, fixed) else V(fixed, cy, (a + b) * 0.5)
		box(parent, string.format("%s_Trans%d", tag, i), size, pos, C.STEEL_LT, M.Metal, 110, group, rowBase + 3, { canCollide = false })
	end
	-- từng ô kính (máu riêng theo ô)
	for ci = 1, cols do
		for ri = 1, rows do
			local pa = a + step * (ci - 1) + 0.12
			local pb = a + step * ci - 0.12
			local py0 = y0 + rowH * (ri - 1) + 0.10
			local py1 = y0 + rowH * ri - 0.10
			glassPane(parent, string.format("%s_G%d_%d", tag, ci, ri), axis, fixed, pa, pb, py0, py1, 55, group .. "_Pane", rowBase + 4)
		end
	end
end

local function buildFacade(root: Instance)
	local f = folder(root, "02_Facade")

	-- ── 4 cột đá vuông của portico ──
	for i, cx in ipairs({ 242.8, 248.6, 265.4, 271.2 }) do
		local grp = "LSPD_PorticoCol" .. tostring(i)
		box(f, "ColBase" .. i, V(3.0, 1.05, 3.0), V(cx, PORCH_TOP + 0.47, 72.6), C.STONE_DK, M.Sandstone, 320, grp .. "_Base", 2)
		box(f, "ColBaseCap" .. i, V(2.7, 0.28, 2.7), V(cx, PORCH_TOP + 1.12, 72.6), C.STONE_LT, M.Marble, 200, grp .. "_BaseCap", 3)
		for d = 1, 4 do
			local y0 = PORCH_TOP + 1.24 + (d - 1) * 2.42
			box(f, "ColDrum" .. i .. "_" .. d, V(2.1, 2.30, 2.1), V(cx, y0 + 1.15, 72.6), if d % 2 == 0 then C.STONE else C.STONE_LT, M.Sandstone, 260, grp .. "_Drum" .. tostring(d), 3)
		end
		box(f, "ColCapital" .. i, V(2.7, 0.55, 2.7), V(cx, 12.12, 72.6), C.STONE_LT, M.Marble, 240, grp .. "_Cap", 4)
		box(f, "ColAbacus" .. i, V(3.1, 0.34, 3.1), V(cx, 12.66, 72.6), C.STONE, M.Marble, 200, grp .. "_Abacus", 5)
	end
	-- móng cột (bệ đá dưới chân, nổi khỏi sàn porch 0.28)
	for i, cx in ipairs({ 242.8, 248.6, 265.4, 271.2 }) do
		box(f, "ColPlinth" .. i, V(3.6, 0.30, 3.6), V(cx, PORCH_TOP + 0.09, 72.6), C.STONE, M.Marble, 220, "LSPD_PorticoCol" .. tostring(i) .. "_Plinth", 1)
	end

	-- ── Mái portico + dầm fascia + đèn soffit ──
	box(f, "CanopySlab", V(33.4, 0.44, 7.7), V(257.0, 12.84, 72.85), C.STONE_LT, M.Concrete, 480, "LSPD_Canopy", 6)
	box(f, "CanopyFascia", V(33.8, 2.95, 0.75), V(257.0, 12.10, 76.35), C.NAVY, M.SmoothPlastic, 420, "LSPD_CanopyFascia", 7)
	box(f, "CanopyTrimTop", V(34.0, 0.30, 0.95), V(257.0, 13.62, 76.35), C.STONE_LT, M.Marble, 260, "LSPD_CanopyTrim", 8)
	box(f, "CanopyTrimBot", V(34.0, 0.24, 0.95), V(257.0, 10.70, 76.35), C.STONE_LT, M.Marble, 260, "LSPD_CanopyTrimB", 8)
	for i = 0, 6 do
		local lx = 243.0 + i * 4.6
		box(f, "SoffitLamp" .. i, V(2.6, 0.20, 1.5), V(lx, 12.52, 73.2), C.NEON_W, M.Neon, 40, "LSPD_SoffitLamp" .. tostring(i), 9, { canCollide = false, castShadow = false })
	end
	-- đèn lồng gắn mặt trước 4 cột portico
	for i, cx in ipairs({ 242.8, 248.6, 265.4, 271.2 }) do
		box(f, "ColLantern" .. i, V(0.62, 1.30, 0.62), V(cx, 8.60, 73.92), C.STEEL_DK, M.Metal, 80, "LSPD_ColLantern" .. tostring(i), 9)
		box(f, "ColLanternLens" .. i, V(0.40, 0.92, 0.14), V(cx, 8.60, 74.28), C.NEON_W, M.Neon, 25, "LSPD_ColLanternLens" .. tostring(i), 10, { canCollide = false, castShadow = false })
		box(f, "ColLanternCap" .. i, V(0.78, 0.18, 0.78), V(cx, 9.34, 73.92), C.STEEL_DK, M.Metal, 40, "LSPD_ColLanternCap" .. tostring(i), 10, { canCollide = false })
	end

	-- ── Cửa kính đôi tự động (rộng 8, cao 9) ──
	doorFrame(f, "MainDoor", "X", FRONT_ZC, DOOR_A, DOOR_B, FLOOR, DOOR_TOP, 1.6, C.STEEL_LT, "LSPD_MainDoor", 2)
	box(f, "DoorCenterPost", V(0.32, DOOR_TOP - FLOOR, 1.5), V(255.0, (FLOOR + DOOR_TOP) * 0.5, FRONT_ZC), C.STEEL_LT, M.Metal, 260, "LSPD_DoorCenter", 3)
	for i, side in ipairs({ -1, 1 }) do
		local grp = "LSPD_DoorLeaf" .. tostring(i)
		local inner = if side < 0 then DOOR_A + 0.42 else 255.32
		local outer = if side < 0 then 254.68 else DOOR_B - 0.42
		-- khung cánh cửa (rail trên/dưới + 2 thanh đứng)
		box(f, "LeafRailTop" .. i, V(outer - inner, 0.55, 0.24), V((inner + outer) * 0.5, DOOR_TOP - 0.42, FRONT_ZC), C.STEEL_LT, M.Metal, 150, grp .. "_RailT", 4)
		box(f, "LeafRailBot" .. i, V(outer - inner, 0.65, 0.24), V((inner + outer) * 0.5, FLOOR + 0.34, FRONT_ZC), C.STEEL_LT, M.Metal, 150, grp .. "_RailB", 4)
		box(f, "LeafStileIn" .. i, V(0.22, DOOR_TOP - FLOOR, 0.24), V(if side < 0 then 254.79 else 255.21, (FLOOR + DOOR_TOP) * 0.5, FRONT_ZC), C.STEEL_LT, M.Metal, 140, grp .. "_StileI", 4)
		box(f, "LeafStileOut" .. i, V(0.22, DOOR_TOP - FLOOR, 0.24), V(if side < 0 then DOOR_A + 0.5 else DOOR_B - 0.5, (FLOOR + DOOR_TOP) * 0.5, FRONT_ZC), C.STEEL_LT, M.Metal, 140, grp .. "_StileO", 4)
		-- 2 ô kính mỗi cánh
		glassPane(f, "LeafGlassLow" .. i, "X", FRONT_ZC, inner + 0.15, outer - 0.15, FLOOR + 0.7, FLOOR + 4.3, 90, grp .. "_PaneLow", 5)
		glassPane(f, "LeafGlassHigh" .. i, "X", FRONT_ZC, inner + 0.15, outer - 0.15, FLOOR + 4.45, DOOR_TOP - 0.72, 90, grp .. "_PaneHigh", 5)
		-- thanh đẩy ngang
		box(f, "LeafPushBar" .. i, V(outer - inner - 0.5, 0.16, 0.16), V((inner + outer) * 0.5, FLOOR + 3.7, FRONT_ZC + 0.28), C.CHROME, M.Metal, 60, grp .. "_Bar", 5, { canCollide = false })
		for _, bx in ipairs({ -1.0, 1.0 }) do
			box(f, "LeafBarArm" .. i .. tostring(bx), V(0.12, 0.12, 0.26), V((inner + outer) * 0.5 + bx, FLOOR + 3.7, FRONT_ZC + 0.16), C.CHROME, M.Metal, 40, grp .. "_BarArm" .. tostring(bx), 5, { canCollide = false })
		end
	end
	-- tấm chắn gió + thảm chùi chân trong sảnh
	box(f, "VestibuleMat", V(8.4, 0.10, 4.6), V(255.0, FLR + 0.03, 66.4), C.NAVY_DK, M.Fabric, 60, "LSPD_Mat", 1, { castShadow = false })
	-- biển đồng "LSPD" gắn trên 2 cột giữa (không bị khuất như panel trên tường)
	for i, cx in ipairs({ 248.6, 265.4 }) do
		box(f, "ColPlaque" .. i, V(1.5, 3.4, 0.20), V(cx, 5.20, 73.72), C.GOLD, M.Metal, 110, "LSPD_ColPlaque" .. tostring(i), 4)
		box(f, "ColPlaqueFace" .. i, V(1.2, 3.0, 0.12), V(cx, 5.20, 73.86), C.NAVY_DK, M.SmoothPlastic, 60, "LSPD_ColPlaqueFace" .. tostring(i), 5, { canCollide = false })
		drawText(f, "ColPlaqueText" .. i, "LSPD", cx - textWidth("LSPD", 0.09) * 0.5, 4.60, 73.94, 0.10, 0.09, C.NEON_W, M.Neon, 20, "LSPD_ColPlaqueText" .. tostring(i), 5)
	end

	-- ── Bảng hiệu huy hiệu: dải navy + chữ neon xanh ──
	-- hộp bảng hiệu nhô 1.2 studs ra trước đai đá → chữ không bị đai che
	box(f, "SignFascia", V(34.0, 6.0, 1.6), V(257.0, 16.60, 70.36), C.NAVY, M.SmoothPlastic, 560, "LSPD_SignFascia", 10)
	box(f, "SignFasciaBevel", V(34.6, 0.36, 1.94), V(257.0, 19.75, 70.36), C.STONE_LT, M.Marble, 300, "LSPD_SignBevel", 11)
	box(f, "SignFasciaBevelB", V(34.6, 0.36, 1.94), V(257.0, 13.45, 70.36), C.STONE_LT, M.Marble, 300, "LSPD_SignBevelB", 11)
	drawText(f, "SignLine1", "LOS SANTOS", 257.0 - textWidth("LOS SANTOS", 0.34) * 0.5, 17.05, 71.62, 0.34, 0.34, C.NEON_B, M.Neon, 60, "LSPD_SignLine1", 12)
	drawText(f, "SignLine2", "POLICE DEPT", 257.0 - textWidth("POLICE DEPT", 0.34) * 0.5, 14.30, 71.62, 0.34, 0.34, C.NEON_B, M.Neon, 60, "LSPD_SignLine2", 12)
	-- huy hiệu tròn 2 bên bảng hiệu
	for i, bx in ipairs({ 241.6, 272.4 }) do
		local grp = "LSPD_SignBadge" .. tostring(i)
		for k = 0, 11 do
			local ang = math.floor(k) * math.pi / 6
			box(f, string.format("BadgeSeg%d_%d", i, k), V(0.4, 0.62, 0.30), V(bx + math.cos(ang) * 1.45, 16.55 + math.sin(ang) * 1.45, 71.68), C.GOLD, M.Metal, 40, grp .. "_Seg" .. tostring(k), 12, { canCollide = false })
		end
		cyl(f, "BadgeStar" .. i, V(0.44, 2.9, 2.9), CFrame.new(V(bx, 16.55, 71.68)) * CFrame.Angles(0, math.rad(90), 0), C.NAVY_LT, M.SmoothPlastic, 60, grp .. "_Core", 13)
		drawText(f, "BadgeText" .. i, "LSPD", bx - textWidth("LSPD", 0.10) * 0.5, 16.20, 71.98, 0.20, 0.10, C.NEON_W, M.Neon, 25, grp .. "_Text", 14)
	end
	-- đèn rọi bảng hiệu
	for i, lx in ipairs({ 248.0, 266.0 }) do
		box(f, "SignSpotArm" .. i, V(0.5, 0.5, 1.6), V(lx, 20.35, 70.9), C.STEEL_DK, M.Metal, 100, "LSPD_SignSpot" .. tostring(i), 13, { canCollide = false })
		box(f, "SignSpotHead" .. i, V(1.0, 0.7, 1.4), V(lx, 20.35, 71.7), C.STEEL_DK, M.Metal, 90, "LSPD_SignSpotHead" .. tostring(i), 14)
	end
	-- "OBEY & SURVIVE" trên dầm mái portico
	drawText(f, "MottoLine", "OBEY & SURVIVE", 257.0 - textWidth("OBEY & SURVIVE", 0.30) * 0.5, 11.00, 77.06, 0.32, 0.30, C.NEON_B, M.Neon, 60, "LSPD_Motto", 8)

	-- ── Cửa sổ tầng trệt (4 ô mặt tiền, 4 hông Đông, 4 hông Tây, 2 hậu) ──
	windowUnit(f, "X", FRONT_ZC, 234.0, 237.4, 4.6, 12.6, 2, 2, "WinF1", "LSPD_WinF1", 2)
	windowUnit(f, "X", FRONT_ZC, 237.8, 241.5, 4.6, 12.6, 2, 2, "WinF2", "LSPD_WinF2", 2)
	windowUnit(f, "X", FRONT_ZC, 272.6, 276.3, 4.6, 12.6, 2, 2, "WinF3", "LSPD_WinF3", 2)
	windowUnit(f, "X", FRONT_ZC, 276.7, 280.0, 4.6, 12.6, 2, 2, "WinF4", "LSPD_WinF4", 2)
	windowUnit(f, "Z", EAST_XC, 44.0, 48.4, 4.6, 12.6, 2, 2, "WinE1", "LSPD_WinE1", 2)
	windowUnit(f, "Z", EAST_XC, 48.9, 53.3, 4.6, 12.6, 2, 2, "WinE2", "LSPD_WinE2", 2)
	windowUnit(f, "Z", EAST_XC, 58.0, 62.4, 4.6, 12.6, 2, 2, "WinE3", "LSPD_WinE3", 2)
	windowUnit(f, "Z", EAST_XC, 62.9, 67.3, 4.6, 12.6, 2, 2, "WinE4", "LSPD_WinE4", 2)
	windowUnit(f, "Z", WEST_XC, 40.0, 44.4, 4.6, 12.6, 2, 2, "WinW1", "LSPD_WinW1", 2)
	windowUnit(f, "Z", WEST_XC, 44.9, 49.3, 4.6, 12.6, 2, 2, "WinW2", "LSPD_WinW2", 2)
	windowUnit(f, "Z", WEST_XC, 52.0, 56.4, 4.6, 12.6, 2, 2, "WinW3", "LSPD_WinW3", 2)
	windowUnit(f, "Z", WEST_XC, 56.9, 61.3, 4.6, 12.6, 2, 2, "WinW4", "LSPD_WinW4", 2)
	windowUnit(f, "X", BACK_ZC, 240.0, 248.0, 4.6, 12.6, 3, 2, "WinB1", "LSPD_WinB1", 2)
	windowUnit(f, "X", BACK_ZC, 256.0, 264.0, 4.6, 12.6, 3, 2, "WinB2", "LSPD_WinB2", 2)

	-- ── Cửa sổ tầng 2 (dải kính rộng) ──
	windowUnit(f, "X", FRONT_ZC, 237.9, 244.9, 19.8, 28.6, 3, 2, "Win2F1", "LSPD_Win2F1", 18)
	windowUnit(f, "X", FRONT_ZC, 245.7, 252.7, 19.8, 28.6, 3, 2, "Win2F2", "LSPD_Win2F2", 18)
	windowUnit(f, "X", FRONT_ZC, 253.5, 260.5, 19.8, 28.6, 3, 2, "Win2F3", "LSPD_Win2F3", 18)
	windowUnit(f, "X", FRONT_ZC, 261.3, 268.3, 19.8, 28.6, 3, 2, "Win2F4", "LSPD_Win2F4", 18)
	windowUnit(f, "X", FRONT_ZC, 269.1, 276.1, 19.8, 28.6, 3, 2, "Win2F5", "LSPD_Win2F5", 18)
	windowUnit(f, "Z", EAST_XC, 22.0, 30.0, 19.8, 28.6, 3, 2, "Win2E1", "LSPD_Win2E1", 18)
	windowUnit(f, "Z", EAST_XC, 32.0, 40.0, 19.8, 28.6, 3, 2, "Win2E2", "LSPD_Win2E2", 18)
	windowUnit(f, "Z", EAST_XC, 44.0, 52.0, 19.8, 28.6, 3, 2, "Win2E3", "LSPD_Win2E3", 18)
	windowUnit(f, "Z", EAST_XC, 56.0, 64.0, 19.8, 28.6, 3, 2, "Win2E4", "LSPD_Win2E4", 18)
	windowUnit(f, "Z", WEST_XC, 40.0, 48.0, 19.8, 28.6, 3, 2, "Win2W1", "LSPD_Win2W1", 18)
	windowUnit(f, "Z", WEST_XC, 50.0, 58.0, 19.8, 28.6, 3, 2, "Win2W2", "LSPD_Win2W2", 18)
	windowUnit(f, "Z", WEST_XC, 60.0, 66.0, 19.8, 28.6, 2, 2, "Win2W3", "LSPD_Win2W3", 18)
	windowUnit(f, "Z", WEST_XC, 10.0, 18.0, 19.8, 28.6, 3, 2, "Win2W4", "LSPD_Win2W4", 18)
	windowUnit(f, "X", BACK_ZC, 238.0, 246.0, 19.8, 28.6, 3, 2, "Win2B1", "LSPD_Win2B1", 18)
	windowUnit(f, "X", BACK_ZC, 248.0, 256.0, 19.8, 28.6, 3, 2, "Win2B2", "LSPD_Win2B2", 18)
	windowUnit(f, "X", BACK_ZC, 258.0, 266.0, 19.8, 28.6, 3, 2, "Win2B3", "LSPD_Win2B3", 18)
	windowUnit(f, "X", BACK_ZC, 268.0, 276.0, 19.8, 28.6, 3, 2, "Win2B4", "LSPD_Win2B4", 18)

	-- ── Cửa cuốn Sally Port hông Đông (18 × 12, mở) ──
	doorFrame(f, "SallyPort", "Z", EAST_XC, SP_Z0, SP_Z1, FLOOR, SP_TOP, 1.7, C.STEEL_DK, "LSPD_SallyFrame", 2)
	box(f, "SallyDrum", V(1.5, 1.0, SP_Z1 - SP_Z0 + 0.6), V(281.0, SP_TOP + 0.45, 29.0), C.STEEL_DK, M.Metal, 400, "LSPD_SallyDrum", 3)
	for i = 1, 4 do
		box(f, "SallyDrumBand" .. i, V(1.7, 0.18, SP_Z1 - SP_Z0 + 0.7), V(281.0, SP_TOP + 0.12 + i * 0.22, 29.0), C.STEEL, M.Metal, 60, "LSPD_SallyDrumBand" .. tostring(i), 4, { canCollide = false })
	end
	-- ray dẫn hướng 2 bên + gờ cao su
	for i, sz in ipairs({ SP_Z0 + 0.3, SP_Z1 - 0.3 }) do
		box(f, "SallyGuide" .. i, V(1.2, SP_TOP - FLOOR, 0.5), V(281.2, (FLOOR + SP_TOP) * 0.5, sz), C.STEEL_DK, M.Metal, 220, "LSPD_SallyGuide" .. tostring(i), 3)
	end
	-- vạch cảnh báo sàn + chữ SALLY PORT
	box(f, "SallyWarnStrip", V(2.0, 0.05, 15.0), V(280.6, FLR + 0.03, 29.0), C.YELLOW, M.SmoothPlastic, 40, "LSPD_SallyStrip", 1, { canCollide = false, castShadow = false })
	box(f, "SallyWarnStrip2", V(0.4, 0.05, 15.0), V(279.3, FLR + 0.05, 29.0), C.BLACK, M.SmoothPlastic, 30, "LSPD_SallyStrip2", 1, { canCollide = false, castShadow = false })
	box(f, "SallySignPanel", V(0.34, 1.70, 16.8), V(282.02, 15.32, 29.0), C.NAVY, M.SmoothPlastic, 240, "LSPD_SallySignPanel", 4)
	drawTextZ(f, "SallySignText", "SALLY PORT", 282.58, 34.44, 14.76, 0.20, 0.16, C.NEON_B, M.Neon, 40, "LSPD_SallySign", 5)

	-- ── Cửa hậu Bắc + cửa hông Tây ──
	doorFrame(f, "BackDoor", "X", BACK_ZC, 269.0, 274.8, FLOOR, 10.55, 1.4, C.STEEL, "LSPD_BackDoor", 2)
	glassPane(f, "BackDoorGlass", "X", BACK_ZC, 269.5, 274.3, FLOOR + 0.6, 9.9, 90, "LSPD_BackDoorGlass", 3)
	box(f, "BackStoop1", V(7.4, 0.62, 3.2), V(271.9, 1.62, 2.0), C.CONCRETE, M.Concrete, 220, "LSPD_BackStoop1", 1)
	box(f, "BackStoop2", V(7.4, 0.30, 2.4), V(271.9, 1.32, 0.2), C.CONCRETE, M.Concrete, 200, "LSPD_BackStoop2", 1)
	doorFrame(f, "WestDoor", "Z", WEST_XC, 63.4, 68.2, FLOOR, 10.55, 1.4, C.STEEL, "LSPD_WestDoor", 2)
	glassPane(f, "WestDoorGlass", "Z", WEST_XC, 63.9, 67.7, FLOOR + 0.6, 9.9, 90, "LSPD_WestDoorGlass", 3)
	box(f, "WestStoop1", V(3.2, 0.62, 5.6), V(230.6, 1.62, 65.8), C.CONCRETE, M.Concrete, 220, "LSPD_WestStoop1", 1)
	box(f, "WestStoop2", V(2.4, 0.30, 5.6), V(228.8, 1.32, 65.8), C.CONCRETE, M.Concrete, 200, "LSPD_WestStoop2", 1)

	-- ── Dốc dẫn xe vào Sally Port (mặt Đông) ──
	for i = 1, 4 do
		local x0 = 282.4 + (i - 1) * 2.0
		local topY = 2.05 - (i - 1) * 0.21
		box(f, "SallyApron" .. i, V(2.0, topY - 1.15, 22.0), V(x0 + 1.0, (1.15 + topY) * 0.5, 29.0), jitter(C.CONCRETE, i, 8), M.Concrete, 280, "LSPD_SallyApron" .. tostring(i), 1)
	end

	-- ── Huy hiệu trên tường hông Đông (dải tường trống giữa 2 ô kính) ──
	local EB_Y, EB_Z = 23.60, 42.00
	for k = 0, 13 do
		local ang = k * math.pi / 7
		box(f, "EastBadgeSeg" .. k, V(0.24, 0.62, 0.48), V(282.10, EB_Y + math.sin(ang) * 1.66, EB_Z + math.cos(ang) * 1.66), C.GOLD, M.Metal, 45, "LSPD_EastBadge" .. tostring(k), 20, { canCollide = false })
	end
	cyl(f, "EastBadgeCore", V(0.5, 3.5, 3.5), CFrame.new(V(282.10, EB_Y, EB_Z)), C.NAVY_LT, M.SmoothPlastic, 90, "LSPD_EastBadgeCore", 19)
	drawTextZ(f, "EastBadgeText", "LSPD", 282.58, EB_Z + 1.56, EB_Y - 0.42, 0.20, 0.12, C.NEON_W, M.Neon, 40, "LSPD_EastBadgeText", 21)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 8. NỘI THẤT TẦNG TRỆT: SẢNH TRỰC BAN, BÀN THÁM TỬ, PHÒNG GIAM, KHO VŨ KHÍ
-- ═══════════════════════════════════════════════════════════════════════════

-- Ghế văn phòng xoay (đế 5 chân + trụ + tựa)
local function officeChair(
	parent: Instance,
	name: string,
	cx: number,
	cz: number,
	yaw: number,
	group: string,
	row: number,
	col: Color3?,
	baseY: number?
)
	local y0 = baseY or FLR
	local c = col or C.LEATHER
	local cfSeat = CFrame.new(V(cx, y0 + 1.35, cz)) * CFrame.Angles(0, yaw, 0)
	rbox(parent, name .. "_Seat", V(1.9, 0.28, 1.9), cfSeat, c, M.Fabric, 70, group .. "_Seat", row)
	rbox(parent, name .. "_Back", V(1.9, 2.0, 0.30), cfSeat * CFrame.new(0, 1.0, 0.82) * CFrame.Angles(math.rad(-8), 0, 0), c, M.Fabric, 70, group .. "_Back", row + 1)
	vcyl(parent, name .. "_Post", V(1.5, 0.32, 0.32), V(cx, y0 + 0.72, cz), C.STEEL_DK, M.Metal, 60, group .. "_Post", row)
	for i = 0, 4 do
		local a = i * math.pi * 0.4
		rbox(
			parent,
			string.format("%s_Leg%d", name, i),
			V(1.55, 0.16, 0.24),
			CFrame.new(V(cx + math.cos(a) * 0.78, y0 + 0.30, cz + math.sin(a) * 0.78)) * CFrame.Angles(0, -a, 0),
			C.STEEL_DK,
			M.Metal,
			40,
			group .. "_Leg" .. tostring(i),
			row,
			{ canCollide = false }
		)
	end
end

-- Bàn làm việc + máy tính + giấy tờ
local function workstation(
	parent: Instance,
	name: string,
	cx: number,
	cz: number,
	yaw: number,
	group: string,
	row: number,
	baseY: number?
)
	local y0 = baseY or FLR
	local cf = CFrame.new(V(cx, y0, cz)) * CFrame.Angles(0, yaw, 0)
	local function at(dx: number, dy: number, dz: number): CFrame
		return cf * CFrame.new(dx, dy, dz)
	end
	rbox(parent, name .. "_Top", V(6.0, 0.24, 3.2), at(0, 2.62, 0), C.WOOD, M.WoodPlanks, 110, group .. "_Top", row + 1)
	rbox(parent, name .. "_PanelL", V(0.22, 2.5, 3.0), at(-2.75, 1.35, 0), C.WOOD_DK, M.WoodPlanks, 90, group .. "_PanelL", row)
	rbox(parent, name .. "_PanelR", V(0.22, 2.5, 3.0), at(2.75, 1.35, 0), C.WOOD_DK, M.WoodPlanks, 90, group .. "_PanelR", row)
	rbox(parent, name .. "_Modesty", V(5.4, 1.7, 0.18), at(0, 1.6, -0.6), C.WOOD_DK, M.WoodPlanks, 80, group .. "_Modesty", row)
	-- ngăn kéo
	for k = 1, 3 do
		rbox(parent, string.format("%s_Drawer%d", name, k), V(1.9, 0.62, 0.16), at(1.6, 0.55 + k * 0.66, 1.52), C.WOOD_DK, M.WoodPlanks, 60, string.format("%s_Drawer%d", name, k), row, { canCollide = false })
		rbox(parent, string.format("%s_Handle%d", name, k), V(0.6, 0.10, 0.14), at(1.6, 0.55 + k * 0.66, 1.63), C.CHROME, M.Metal, 30, string.format("%s_Handle%d", name, k), row, { canCollide = false })
	end
	-- màn hình + bàn phím + chuột
	rbox(parent, name .. "_MonStand", V(0.5, 0.7, 0.5), at(-0.9, 3.1, -0.7), C.STEEL_DK, M.Metal, 50, group .. "_Mon", row, { canCollide = false })
	rbox(parent, name .. "_MonBody", V(2.5, 1.6, 0.22), at(-0.9, 4.1, -0.7), C.BLACK, M.SmoothPlastic, 70, group .. "_Mon", row, { canCollide = false })
	rbox(parent, name .. "_MonScreen", V(2.25, 1.35, 0.10), at(-0.9, 4.1, -0.56), RGB(74, 118, 168), M.Neon, 40, group .. "_MonScreen", row + 1, { canCollide = false, castShadow = false })
	rbox(parent, name .. "_Keyboard", V(1.7, 0.10, 0.62), at(-0.6, 2.80, 0.55), C.BLACK, M.SmoothPlastic, 30, group .. "_Kb", row, { canCollide = false })
	rbox(parent, name .. "_Mouse", V(0.34, 0.12, 0.5), at(0.6, 2.80, 0.6), C.BLACK, M.SmoothPlastic, 25, group .. "_Mouse", row, { canCollide = false })
	-- giấy tờ, cốc, đèn bàn
	rbox(parent, name .. "_Papers", V(1.1, 0.06, 1.4), at(1.7, 2.78, 0.3), C.WHITE, M.SmoothPlastic, 25, group .. "_Paper", row, { canCollide = false, castShadow = false })
	rbox(parent, name .. "_Mug", V(0.36, 0.5, 0.36), at(2.2, 2.99, -0.6), C.RED, M.SmoothPlastic, 25, group .. "_Mug", row, { canCollide = false })
	rbox(parent, name .. "_LampArm", V(0.16, 1.9, 0.16), at(-2.3, 3.6, -0.5), C.STEEL_DK, M.Metal, 40, group .. "_Lamp", row, { canCollide = false })
	rbox(parent, name .. "_LampHead", V(0.9, 0.24, 0.5), at(-2.3, 4.55, -0.5), C.STEEL_DK, M.Metal, 40, group .. "_LampHead", row, { canCollide = false })
	officeChair(parent, name .. "_Chair", cx + math.sin(yaw) * 2.6, cz + math.cos(yaw) * 2.6, yaw + math.pi, group .. "_Chair", row + 1, nil, y0)
end

-- Tủ hồ sơ / tủ locker (2 cánh, có tay nắm)
local function lockerBank(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	y0: number,
	height: number,
	depth: number,
	doors: number,
	color: Color3,
	group: string,
	row: number
)
	local len = c1 - c0
	local bodySize = if axis == "X" then V(len, height, depth) else V(depth, height, len)
	local bodyPos = if axis == "X" then V((c0 + c1) * 0.5, y0 + height * 0.5, fixed) else V(fixed, y0 + height * 0.5, (c0 + c1) * 0.5)
	box(parent, name .. "_Body", bodySize, bodyPos, color, M.Metal, 200, group .. "_Body", row)
	local step = len / doors
	for i = 1, doors do
		local mid = c0 + step * (i - 0.5)
		local faceOff = depth * 0.5 + 0.06
		local dSize = if axis == "X" then V(step - 0.12, height - 0.30, 0.12) else V(0.12, height - 0.30, step - 0.12)
		local dPos = if axis == "X"
			then V(mid, y0 + height * 0.5, fixed + faceOff)
			else V(fixed + faceOff, y0 + height * 0.5, mid)
		box(parent, string.format("%s_Door%d", name, i), dSize, dPos, color, M.Metal, 70, string.format("%s_Door%d", name, i), row + 1, { canCollide = false })
		local hSize = if axis == "X" then V(0.5, 0.10, 0.16) else V(0.16, 0.10, 0.5)
		local hPos = if axis == "X"
			then V(mid + step * 0.22, y0 + height * 0.62, fixed + faceOff + 0.06)
			else V(fixed + faceOff + 0.06, y0 + height * 0.62, mid + step * 0.22)
		box(parent, string.format("%s_Handle%d", name, i), hSize, hPos, C.CHROME, M.Metal, 25, string.format("%s_Handle%d", name, i), row + 1, { canCollide = false })
		-- khe thông gió
		local vSize = if axis == "X" then V(step - 0.7, 0.16, 0.06) else V(0.06, 0.16, step - 0.7)
		for k = 1, 3 do
			local vPos = if axis == "X"
				then V(mid, y0 + height - 0.55 - k * 0.28, fixed + faceOff + 0.04)
				else V(fixed + faceOff + 0.04, y0 + height - 0.55 - k * 0.28, mid)
			box(parent, string.format("%s_Vent%d_%d", name, i, k), vSize, vPos, C.STEEL_DK, M.Metal, 15, string.format("%s_Vent%d_%d", name, i, k), row + 1, { canCollide = false, castShadow = false })
		end
	end
end

-- Đèn trần tuýp (khung + tấm phát sáng) treo dưới trần
local function ceilingLight(parent: Instance, name: string, cx: number, cz: number, ceilY: number, len: number, alongX: boolean, group: string)
	local w = if alongX then V(len, 0.35, 1.5) else V(1.5, 0.35, len)
	box(parent, name .. "_Frame", w, V(cx, ceilY - 0.125, cz), C.STEEL_LT, M.Metal, 70, group .. "_Frame", 2, { canCollide = false })
	local lens = if alongX then V(len - 0.5, 0.16, 1.1) else V(1.1, 0.16, len - 0.5)
	box(parent, name .. "_Lens", lens, V(cx, ceilY - 0.36, cz), C.NEON_W, M.Neon, 30, group .. "_Lens", 2, { canCollide = false, castShadow = false })
end

-- Buồng giam: giường sắt, bồn cầu inox, vòi nước, cửa sổ song sắt
local function jailCell(parent: Instance, tag: string, x0: number, x1: number, z0: number, z1: number, row: number)
	local cx = (x0 + x1) * 0.5
	-- giường tầng sắt dọc tường Tây
	local bx = x0 + 1.6
	local grp = "LSPD_Cell" .. tag .. "_Bed"
	box(parent, "CellBedFrame" .. tag, V(3.4, 0.30, 7.0), V(bx, FLR + 1.55, (z0 + z1) * 0.5), C.STEEL_DK, M.Metal, 120, grp .. "_Frame", row)
	box(parent, "CellMattress" .. tag, V(3.0, 0.55, 6.6), V(bx, FLR + 1.95, (z0 + z1) * 0.5), RGB(196, 198, 190), M.Fabric, 60, grp .. "_Mattress", row + 1)
	box(parent, "CellPillow" .. tag, V(2.4, 0.45, 1.5), V(bx, FLR + 2.35, z0 + 1.6), C.WHITE, M.Fabric, 40, grp .. "_Pillow", row + 1)
	for i, lz in ipairs({ z0 + 1.0, z1 - 1.0 }) do
		box(parent, "CellBedLeg" .. tag .. i, V(0.30, 1.55, 0.30), V(bx + 1.5, FLR + 0.78, lz), C.STEEL_DK, M.Metal, 50, grp .. "_Leg" .. tostring(i), row)
	end
	-- bồn cầu + bệ inox góc Đông Nam
	vcyl(parent, "CellToilet" .. tag, V(1.5, 1.5, 1.5), V(x1 - 1.5, FLR + 0.75, z1 - 1.8), C.WHITE, M.CeramicTiles, 70, "LSPD_Cell" .. tag .. "_Toilet", row)
	box(parent, "CellToiletTank" .. tag, V(1.3, 1.9, 0.7), V(x1 - 1.5, FLR + 1.9, z1 - 1.0), C.WHITE, M.CeramicTiles, 60, "LSPD_Cell" .. tag .. "_Tank", row)
	box(parent, "CellSink" .. tag, V(1.3, 0.35, 1.5), V(x1 - 0.6, FLR + 2.4, z1 - 1.0), C.CHROME, M.Metal, 60, "LSPD_Cell" .. tag .. "_Sink", row)
	box(parent, "CellBench" .. tag, V(2.8, 0.30, 1.6), V(cx + 2.0, FLR + 1.5, z0 + 0.95), C.STEEL_DK, M.Metal, 90, "LSPD_Cell" .. tag .. "_Bench", row)
	-- cửa sổ hẹp có song sắt trên tường hậu
	box(parent, "CellWin" .. tag, V(2.6, 1.5, 0.22), V(cx, FLR + 9.2, z0 + 0.11), C.GLASS_DK, M.Glass, 40, "LSPD_Cell" .. tag .. "_Win", row, { transparency = 0.5, canCollide = false, castShadow = false })
	for i = 0, 3 do
		box(parent, string.format("CellWinBar%s_%d", tag, i), V(0.12, 1.5, 0.14), V(cx - 0.9 + i * 0.6, FLR + 9.2, z0 + 0.2), C.STEEL_DK, M.Metal, 40, "LSPD_Cell" .. tag .. "_WinBar", row, { canCollide = false })
	end
	-- đèn trần + camera
	box(parent, "CellLamp" .. tag, V(1.4, 0.18, 1.4), V(cx, FLR + 14.6, (z0 + z1) * 0.5), C.NEON_W, M.Neon, 25, "LSPD_Cell" .. tag .. "_Lamp", row, { canCollide = false, castShadow = false })
	ball(parent, "CellCam" .. tag, 0.7, V(x1 - 0.4, FLR + 10.2, z0 + 0.4), C.BLACK, M.SmoothPlastic, 30, "LSPD_Cell" .. tag .. "_Cam", row)
end

local function buildGroundFloor(root: Instance)
	local f = folder(root, "03_GroundFloor")

	-- ═══ VÁCH NGĂN: KHOANG XE SALLY PORT (hông Đông) ═══
	-- (tường Đông dày 0.9, cửa người 4.6 × 8.5)
	panelWall(f, "GarageWallW", "Z", 261.7, 19.55, 38.45, FLOOR, 16.85, 0.9, C.CONCRETE, 240, "LSPD_GarageWallW", {
		{ a = 27.8, b = 32.4, y0 = FLOOR, y1 = 10.55 },
	}, M.Concrete)
	panelWall(f, "GarageWallN", "X", 20.0, 262.15, 280.9, FLOOR, 16.85, 0.9, C.CONCRETE, 240, "LSPD_GarageWallN", {}, M.Concrete)
	panelWall(f, "GarageWallS", "X", 38.0, 262.15, 280.9, FLOOR, 16.85, 0.9, C.CONCRETE, 240, "LSPD_GarageWallS", {}, M.Concrete)
	doorFrame(f, "GaragePedDoor", "Z", 261.7, 27.8, 32.4, FLOOR, 10.55, 1.2, C.STEEL_DK, "LSPD_GaragePedDoor", 2)
	box(f, "GaragePedDoorLeaf", V(0.14, 8.2, 4.2), V(261.66, FLOOR + 4.2, 30.1), C.STEEL, M.Metal, 180, "LSPD_GaragePedLeaf", 3)
	box(f, "GaragePedDoorGlass", V(0.10, 3.4, 2.6), V(261.58, FLOOR + 6.0, 30.1), C.GLASS_DK, M.Glass, 60, "LSPD_GaragePedGlass", 3, { transparency = 0.45, canCollide = false, castShadow = false })
	box(f, "GaragePedPush", V(0.20, 0.16, 1.4), V(261.50, FLOOR + 3.6, 30.1), C.CHROME, M.Metal, 30, "LSPD_GaragePedPush", 3, { canCollide = false })

	-- ═══ VÁCH NGĂN: KHU GIAM GIỮ (Tây Bắc) ═══
	panelWall(f, "JailWallS", "X", 24.2, 233.2, 250.3, FLOOR, 16.85, 0.9, C.CONCRETE, 260, "LSPD_JailWallS", {
		{ a = 246.3, b = 250.3, y0 = FLOOR, y1 = 10.55 },
	}, M.Concrete)
	panelWall(f, "JailBarsX", "Z", 245.6, 5.2, 23.75, FLOOR, 16.85, 0.9, C.CONCRETE, 260, "LSPD_JailBarsX", {
		{ a = 8.4, b = 12.4, y0 = FLOOR, y1 = 10.05 },
		{ a = 16.6, b = 20.6, y0 = FLOOR, y1 = 10.05 },
	}, M.Concrete)
	panelWall(f, "JailWallE", "Z", 250.75, 5.2, 23.75, FLOOR, 16.85, 0.9, C.CONCRETE, 260, "LSPD_JailWallE", {}, M.Concrete)
	panelWall(f, "JailCellDiv", "X", 14.2, 233.2, 245.15, FLOOR, 16.85, 0.9, C.CONCRETE, 260, "LSPD_JailCellDiv", {}, M.Concrete)
	-- song sắt 2 cửa buồng giam + khung + bản lề
	for i, zc in ipairs({ 10.4, 18.6 }) do
		local z0, z1 = zc - 2.0, zc + 2.0
		doorFrame(f, "CellDoorFrame" .. i, "Z", 245.6, z0, z1, FLOOR, 10.05, 1.2, C.STEEL_DK, "LSPD_CellDoor" .. tostring(i), 2)
		barredPanel(f, "CellDoor" .. i, "Z", 245.6, z0 + 0.2, z1 - 0.2, FLOOR + 0.1, 9.95, C.STEEL_DK, "LSPD_CellDoorBars" .. tostring(i), 3)
		for h = 1, 3 do
			box(f, string.format("CellHinge%d_%d", i, h), V(0.30, 0.55, 0.30), V(245.42, FLOOR + 1.0 + (h - 1) * 3.6, z0 + 0.1), C.STEEL, M.Metal, 50, string.format("LSPD_CellHinge%d_%d", i, h), 4)
		end
		box(f, "CellLockPlate" .. i, V(0.34, 0.9, 0.7), V(245.40, FLOOR + 4.6, z1 - 0.55), C.CHROME, M.Metal, 60, "LSPD_CellLock" .. tostring(i), 4)
		box(f, "CellSlot" .. i, V(0.20, 0.35, 1.1), V(245.40, FLOOR + 6.6, zc), C.STEEL_DK, M.Metal, 30, "LSPD_CellSlot" .. tostring(i), 4, { canCollide = false })
	end
	doorFrame(f, "JailEntryDoor", "X", 24.2, 246.3, 250.3, FLOOR, 10.55, 1.2, C.STEEL_DK, "LSPD_JailEntry", 2)
	box(f, "JailEntryLeaf", V(3.9, 8.2, 0.14), V(248.3, FLOOR + 4.2, 24.2), C.STEEL, M.Metal, 180, "LSPD_JailEntryLeaf", 3)
	box(f, "JailEntryVision", V(1.8, 2.0, 0.10), V(248.3, FLOOR + 6.6, 24.2), C.GLASS_DK, M.Glass, 50, "LSPD_JailEntryGlass", 3, { transparency = 0.45, canCollide = false, castShadow = false })
	jailCell(f, "A", 233.2, 245.15, 5.2, 13.75, 2)
	jailCell(f, "B", 233.2, 245.15, 14.65, 23.75, 2)
	-- bảng quy định trong buồng giam
	box(f, "CellRulesBoard", V(3.4, 2.0, 0.16), V(249.6, FLR + 8.4, 5.35), C.WHITE, M.SmoothPlastic, 40, "LSPD_CellRules", 3)

	-- ═══ VÁCH NGĂN: NHÀ VỆ SINH ═══
	panelWall(f, "RestWallN", "X", 26.4, 233.2, 241.05, FLOOR, 16.85, 0.9, C.CONCRETE, 230, "LSPD_RestWallN", {}, M.Concrete)
	panelWall(f, "RestWallS", "X", 34.4, 233.2, 241.05, FLOOR, 16.85, 0.9, C.CONCRETE, 230, "LSPD_RestWallS", {}, M.Concrete)
	panelWall(f, "RestWallE", "Z", 241.5, 26.4, 34.4, FLOOR, 16.85, 0.9, C.CONCRETE, 230, "LSPD_RestWallE", {
		{ a = 29.2, b = 33.2, y0 = FLOOR, y1 = 10.05 },
	}, M.Concrete)
	doorFrame(f, "RestDoor", "Z", 241.5, 29.2, 33.2, FLOOR, 10.05, 1.1, C.STEEL_LT, "LSPD_RestDoor", 2)
	-- 2 buồng vệ sinh + bồn cầu + lavabo + gương + khay đựng
	for i, zc in ipairs({ 28.4, 32.0 }) do
		local grp = "LSPD_Restroom" .. tostring(i)
		box(f, "StallDivider" .. i, V(4.4, 5.4, 0.2), V(IN_X0 + 2.2, FLR + 2.7, zc), C.STONE_LT, M.CeramicTiles, 90, grp .. "_Div", 2)
		box(f, "StallDoor" .. i, V(0.18, 5.0, 2.6), V(IN_X0 + 4.4, FLR + 2.6, zc - 0.2), C.STONE_LT, M.CeramicTiles, 70, grp .. "_Door", 2, { canCollide = false })
		vcyl(f, "Toilet" .. i, V(1.7, 1.6, 1.6), V(IN_X0 + 1.4, FLR + 0.8, zc), C.WHITE, M.CeramicTiles, 70, grp .. "_Toilet", 1)
		box(f, "ToiletTank" .. i, V(1.4, 2.0, 0.8), V(IN_X0 + 1.4, FLR + 2.0, zc - 0.9), C.WHITE, M.CeramicTiles, 60, grp .. "_Tank", 1)
	end
	box(f, "RestSinkCounter", V(5.6, 0.35, 1.8), V(238.4, FLR + 2.5, 33.0), C.STONE_LT, M.Marble, 120, "LSPD_RestSink", 2)
	for i, sx in ipairs({ 236.6, 238.6, 240.4 }) do
		box(f, "RestBasin" .. i, V(1.1, 0.5, 1.2), V(sx, FLR + 2.35, 33.0), C.WHITE, M.CeramicTiles, 40, "LSPD_RestBasin" .. tostring(i), 2, { canCollide = false })
		vcyl(f, "RestTap" .. i, V(0.9, 0.16, 0.16), V(sx, FLR + 2.9, 33.5), C.CHROME, M.Metal, 20, "LSPD_RestTap" .. tostring(i), 3, { canCollide = false })
	end
	box(f, "RestMirror", V(6.4, 3.4, 0.16), V(238.4, FLR + 5.6, 34.0), C.CHROME, M.Metal, 60, "LSPD_RestMirror", 3, { reflectance = 0.6, canCollide = false })
	box(f, "RestMirrorFrame", V(6.9, 3.9, 0.12), V(238.4, FLR + 5.6, 34.12), C.STEEL_DK, M.Metal, 70, "LSPD_RestMirrorFrame", 2)
	box(f, "RestUrinal", V(1.8, 3.0, 1.1), V(233.9, FLR + 3.6, 30.0), C.WHITE, M.CeramicTiles, 50, "LSPD_RestUrinal", 2)
	box(f, "RestFloorDrain", V(1.0, 0.10, 1.0), V(237.0, FLR + 0.04, 30.5), C.STEEL_DK, M.Metal, 20, "LSPD_RestDrain", 1, { canCollide = false, castShadow = false })

	-- ═══ VÁCH NGĂN KHO VŨ KHÍ (Đông Nam) ═══
	panelWall(f, "ArmoryWallN", "X", 44.2, 268.95, 280.9, FLOOR, 16.85, 0.9, C.CONCRETE, 300, "LSPD_ArmoryWallN", {
		{ a = 271.4, b = 276.4, y0 = FLOOR, y1 = 10.55 },
	}, M.Concrete)
	panelWall(f, "ArmoryWallS", "X", 54.6, 268.95, 280.9, FLOOR, 16.85, 0.9, C.CONCRETE, 300, "LSPD_ArmoryWallS", {}, M.Concrete)
	panelWall(f, "ArmoryWallW", "Z", 268.5, 44.2, 54.6, FLOOR, 16.85, 0.9, C.CONCRETE, 300, "LSPD_ArmoryWallW", {}, M.Concrete)
	doorFrame(f, "ArmoryDoor", "X", 44.2, 271.4, 276.4, FLOOR, 10.55, 1.2, C.STEEL_DK, "LSPD_ArmoryDoor", 2)
	box(f, "ArmoryDoorLeaf", V(4.6, 8.2, 0.4), V(273.9, FLOOR + 4.2, 44.2), C.STEEL, M.Metal, 320, "LSPD_ArmoryLeaf", 3)
	box(f, "ArmoryDoorLock", V(0.9, 1.2, 0.7), V(272.2, FLOOR + 4.4, 43.85), C.CHROME, M.Metal, 90, "LSPD_ArmoryLock", 4)
	box(f, "ArmoryDoorKeypad", V(0.9, 1.3, 0.3), V(276.9, FLOOR + 4.8, 43.95), C.BLACK, M.SmoothPlastic, 60, "LSPD_ArmoryKeypad", 4)
	-- giá súng + tủ đạn + kệ
	for i = 1, 3 do
		local rz = 45.0 + (i - 1) * 2.9
		box(f, "GunRack" .. i, V(0.8, 6.0, 2.7), V(279.4, FLR + 3.0, rz), C.WOOD_DK, M.WoodPlanks, 140, "LSPD_GunRack" .. tostring(i), 3)
		for k = 1, 4 do
			box(f, string.format("GunRackBarrel%d_%d", i, k), V(0.34, 3.0, 0.34), V(278.9, FLR + 4.4, rz - 1.05 + (k - 1) * 0.7), C.BLACK, M.Metal, 40, string.format("LSPD_Gun%d_%d", i, k), 4, { canCollide = false })
		end
	end
	lockerBank(f, "ArmoryLocker", "Z", 268.9, 46.0, 53.6, FLR, 7.0, 1.6, 4, C.NAVY_DK, "LSPD_ArmoryLocker", 3)
	box(f, "AmmoCrate1", V(2.6, 1.8, 2.2), V(272.4, FLR + 0.9, 50.4), C.OLIVE, M.Metal, 100, "LSPD_AmmoCrate1", 1)
	box(f, "AmmoCrate2", V(2.6, 1.6, 2.2), V(272.4, FLR + 2.6, 50.4), C.OLIVE, M.Metal, 90, "LSPD_AmmoCrate2", 2)
	box(f, "ArmoryCounter", V(4.4, 0.3, 2.2), V(274.4, FLR + 2.4, 48.0), C.STEEL_LT, M.Metal, 110, "LSPD_ArmoryCounter", 2)
	for i, lx in ipairs({ 272.6, 276.2 }) do
		box(f, "ArmoryCounterLeg" .. i, V(0.26, 2.3, 0.26), V(lx, FLR + 1.15, 48.0), C.STEEL_DK, M.Metal, 50, "LSPD_ArmoryLeg" .. tostring(i), 1)
	end
	box(f, "ArmorySafe", V(3.0, 4.6, 2.4), V(279.2, FLR + 2.3, 53.0), C.STEEL_DK, M.Metal, 400, "LSPD_ArmorySafe", 1)
	ceilingLight(f, "ArmoryLight", 274.5, 49.4, 16.85, 5.0, false, "LSPD_ArmoryLight")

	-- ═══ KHU LÀM VIỆC THÁM TỬ (bullpen) ═══
	local bpZ = 33.0
	panelWall(f, "BullpenWall", "X", 44.2, 233.2, 268.05, FLOOR, 16.85, 0.9, C.CONCRETE, 240, "LSPD_BullpenWall", {
		{ a = 251.6, b = 259.6, y0 = FLOOR, y1 = 12.05 },
	}, M.Concrete)
	doorFrame(f, "LobbyToBullpen", "X", 44.2, 251.6, 259.6, FLOOR, 12.05, 1.4, C.STEEL_LT, "LSPD_LobbyArch", 2)
	box(f, "LobbyArchHead", V(9.0, 0.66, 1.6), V(255.6, FLOOR + 10.28, 44.2), C.NAVY, M.SmoothPlastic, 240, "LSPD_LobbyArchHead", 3)
	drawText(f, "ArchText", "DETECTIVES", 255.6 - textWidth("DETECTIVES", 0.16) * 0.5, FLOOR + 9.35, 45.04, 0.2, 0.16, C.NEON_B, M.Neon, 30, "LSPD_ArchText", 4)
	-- 4 bàn thám tử
	workstation(f, "DeskA", 246.5, bpZ - 3.0, 0, "LSPD_DeskA", 2)
	workstation(f, "DeskB", 260.5, bpZ - 3.0, 0, "LSPD_DeskB", 2)
	workstation(f, "DeskC", 246.5, bpZ + 5.6, math.pi, "LSPD_DeskC", 2)
	workstation(f, "DeskD", 260.5, bpZ + 5.6, math.pi, "LSPD_DeskD", 2)
	-- bảng truy nã (wanted board) trên vách bullpen
	box(f, "WantedBoardFrame", V(13.0, 6.4, 0.30), V(244.0, FLR + 7.4, 43.62), C.WOOD_DK, M.WoodPlanks, 260, "LSPD_WantedBoardFrame", 4)
	box(f, "WantedBoardCork", V(12.3, 5.6, 0.18), V(244.0, FLR + 7.4, 43.42), RGB(168, 132, 88), M.Fabric, 120, "LSPD_WantedBoardCork", 5)
	drawText(f, "WantedTitle", "WANTED", 244.0 - textWidth("WANTED", 0.28) * 0.5, FLR + 10.0, 43.30, 0.14, 0.28, C.NEON_R, M.Neon, 40, "LSPD_WantedTitle", 6)
	for i = 0, 4 do
		local px = 238.9 + i * 2.55
		box(f, "Mugshot" .. i, V(2.2, 3.0, 0.10), V(px, FLR + 6.6, 43.30), C.WHITE, M.SmoothPlastic, 40, "LSPD_Mugshot" .. tostring(i), 6, { canCollide = false, castShadow = false })
		box(f, "MugshotFace" .. i, V(1.4, 1.8, 0.06), V(px, FLR + 6.9, 43.24), RGB(150, 140, 130), M.SmoothPlastic, 20, "LSPD_MugshotFace" .. tostring(i), 6, { canCollide = false, castShadow = false })
		box(f, "MugshotTag" .. i, V(1.9, 0.5, 0.06), V(px, FLR + 5.4, 43.24), C.WHITE, M.SmoothPlastic, 20, "LSPD_MugshotTag" .. tostring(i), 6, { canCollide = false, castShadow = false })
	end
	-- tủ hồ sơ dọc vách phía Nam khu thám tử
	lockerBank(f, "FileCabinets", "X", 43.6, 261.6, 267.4, FLR, 6.2, 1.5, 3, C.STEEL_LT, "LSPD_FileCab", 2)
	box(f, "PrinterTable", V(4.4, 0.28, 2.4), V(235.6, FLR + 2.5, 41.0), C.WOOD_DK, M.WoodPlanks, 100, "LSPD_PrinterTable", 1)
	box(f, "Printer", V(3.0, 1.6, 2.0), V(235.6, FLR + 3.4, 41.0), C.STEEL_LT, M.SmoothPlastic, 90, "LSPD_Printer", 2)
	box(f, "PrinterPaper", V(1.6, 0.12, 1.4), V(235.6, FLR + 4.25, 41.0), C.WHITE, M.SmoothPlastic, 25, "LSPD_PrinterPaper", 3, { canCollide = false, castShadow = false })
	-- cột kết cấu giữa sàn (2 cột vuông bê tông)
	for i, cp in ipairs({ { 239.0, 28.0 }, { 265.6, 40.6 } }) do
		box(f, "IntColumn" .. i, V(1.6, 14.8, 1.6), V(cp[1], FLOOR + 7.4, cp[2]), C.CONCRETE, M.Concrete, 420, "LSPD_IntColumn" .. tostring(i), 2, { structural = true })
		box(f, "IntColumnBase" .. i, V(2.2, 0.4, 2.2), V(cp[1], FLR + 0.2, cp[2]), C.STONE_DK, M.Concrete, 200, "LSPD_IntColBase" .. tostring(i), 1)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 9. SẢNH TRỰC BAN + KHOANG XE CẢNH SÁT (nội thất tầng trệt, phần 2)
-- ═══════════════════════════════════════════════════════════════════════════
local function buildLobbyAndGarage(root: Instance)
	local f = folder(root, "04_LobbyGarage")

	-- ── Quầy trực ban có kính chắn đạn ──
	local deskZ = 52.4
	box(f, "DutyCounterBody", V(16.0, 3.5, 1.7), V(259.0, FLR + 1.75, deskZ), C.NAVY, M.SmoothPlastic, 380, "LSPD_DutyCounter", 2)
	box(f, "DutyCounterKick", V(16.2, 0.55, 1.9), V(259.0, FLR + 0.27, deskZ), C.STEEL_DK, M.Metal, 160, "LSPD_DutyKick", 1)
	box(f, "DutyCounterTop", V(16.6, 0.28, 2.4), V(259.0, FLR + 3.50, deskZ), C.STONE_LT, M.Marble, 300, "LSPD_DutyTop", 3)
	box(f, "DutyLedger", V(1.5, 0.16, 1.2), V(258.0, FLR + 3.72, deskZ + 0.2), C.WHITE, M.SmoothPlastic, 40, "LSPD_DutyLedger", 4, { canCollide = false, castShadow = false })
	box(f, "DutyBelt", V(2.2, 0.55, 1.0), V(261.6, FLR + 3.9, deskZ), C.LEATHER, M.Leather, 60, "LSPD_DutyBelt", 4, { canCollide = false })
	box(f, "DutyRadio", V(0.7, 0.9, 0.5), V(263.2, FLR + 4.05, deskZ - 0.3), C.BLACK, M.SmoothPlastic, 40, "LSPD_DutyRadio", 4, { canCollide = false })
	-- kính chắn + khung nhôm + khe nói
	for _, side in ipairs({ { 252.2, 256.6 }, { 257.6, 262.0 }, { 263.0, 267.4 } }) do
		local grp = string.format("LSPD_DutyGlass_%d", math.floor(side[1]))
		box(f, "DutyGlass_" .. math.floor(side[1]) .. "_PostL", V(0.22, 4.2, 0.30), V(side[1] - 0.11, FLR + 5.4, deskZ - 0.95), C.STEEL_LT, M.Metal, 90, grp .. "_PostL", 5, { canCollide = false })
		box(f, "DutyGlass_" .. math.floor(side[1]) .. "_PostR", V(0.22, 4.2, 0.30), V(side[2] + 0.11, FLR + 5.4, deskZ - 0.95), C.STEEL_LT, M.Metal, 90, grp .. "_PostR", 5, { canCollide = false })
		glassPane(f, "DutyGlassPane_" .. math.floor(side[1]), "X", deskZ - 0.95, side[1], side[2], FLR + 3.72, FLR + 7.30, 110, grp .. "_Pane", 5)
		box(f, "DutyGlassRail_" .. math.floor(side[1]), V(side[2] - side[1] + 0.5, 0.20, 0.34), V((side[1] + side[2]) * 0.5, FLR + 7.42, deskZ - 0.95), C.STEEL_LT, M.Metal, 90, grp .. "_Rail", 6, { canCollide = false })
	end
	box(f, "DutySpeakHole", V(1.0, 0.9, 0.10), V(257.3, FLR + 5.4, deskZ - 1.06), C.STEEL, M.Metal, 60, "LSPD_DutySpeak", 6, { canCollide = false })
	box(f, "DutyPassTray", V(1.5, 0.16, 0.9), V(257.3, FLR + 3.8, deskZ + 0.1), C.CHROME, M.Metal, 40, "LSPD_DutyTray", 6, { canCollide = false })
	-- bàn làm việc sau quầy (2 chỗ) + màn hình + ghế
	box(f, "DutyOfficerDeskTop", V(15.6, 0.24, 2.6), V(259.2, FLR + 2.6, deskZ - 2.6), C.WOOD, M.WoodPlanks, 130, "LSPD_DutyOfficerDesk", 2)
	for i, mx in ipairs({ 255.2, 259.2, 263.2 }) do
		box(f, "DutyMonitor" .. i, V(2.4, 1.5, 0.2), V(mx, FLR + 3.9, deskZ - 3.2), C.BLACK, M.SmoothPlastic, 60, "LSPD_DutyMon" .. tostring(i), 3, { canCollide = false })
		box(f, "DutyScreen" .. i, V(2.15, 1.28, 0.09), V(mx, FLR + 3.9, deskZ - 3.31), RGB(56, 128, 96), M.Neon, 35, "LSPD_DutyScreen" .. tostring(i), 3, { canCollide = false, castShadow = false })
		box(f, "DutyMonFoot" .. i, V(1.0, 0.34, 0.7), V(mx, FLR + 2.85, deskZ - 3.2), C.STEEL_DK, M.Metal, 30, "LSPD_DutyFoot" .. tostring(i), 3, { canCollide = false })
	end
	officeChair(f, "DutyChair1", 256.4, deskZ - 1.2, 0, "LSPD_DutyChair1", 2)
	officeChair(f, "DutyChair2", 262.0, deskZ - 1.2, 0, "LSPD_DutyChair2", 2)
	-- tủ hồ sơ sau quầy
	lockerBank(f, "DutyCabinet", "X", deskZ - 4.4, 252.0, 266.0, FLR, 5.8, 1.4, 5, C.STEEL_LT, "LSPD_DutyCabinet", 2)

	-- ── Huy hiệu khảm sàn sảnh + vòng tròn đá ──
	for k = 0, 23 do
		local ang = k * math.pi / 12
		box(f, "FloorEmblemRing" .. k, V(1.35, 0.05, 0.42), V(257.0 + math.cos(ang) * 5.2, FLR + 0.03, 62.0 + math.sin(ang) * 5.2), C.NAVY, M.Marble, 30, "LSPD_EmblemRing" .. tostring(k), 1, { canCollide = false, castShadow = false })
	end
	box(f, "FloorEmblemDisc", V(9.2, 0.04, 9.2), V(257.0, FLR + 0.025, 62.0), C.STONE_LT, M.Marble, 40, "LSPD_EmblemDisc", 1, { castShadow = false })
	drawTextFlat(f, "EmblemText", "LSPD", 257.0, 60.9, FLR + 0.05, 0.34, C.NAVY, M.SmoothPlastic, 20, "LSPD_EmblemText", 1)

	-- ── Hàng rào xếp hàng (cọc + dây) ──
	for i, px in ipairs({ 250.0, 254.6, 259.2, 263.8, 268.4 }) do
		for j, pz in ipairs({ 56.6, 59.4 }) do
			local grp = string.format("LSPD_Stanchion%d_%d", i, j)
			vcyl(f, string.format("StanchionBase%d_%d", i, j), V(0.35, 1.5, 1.5), V(px, FLR + 0.15, pz), C.STEEL_DK, M.Metal, 60, grp .. "_Base", 1)
			vcyl(f, string.format("StanchionPole%d_%d", i, j), V(3.2, 0.18, 0.18), V(px, FLR + 1.75, pz), C.CHROME, M.Metal, 50, grp .. "_Pole", 2, { canCollide = false })
			ball(f, string.format("StanchionKnob%d_%d", i, j), 0.4, V(px, FLR + 3.42, pz), C.CHROME, M.Metal, 20, grp .. "_Knob", 2)
		end
		-- dây nối 2 cọc
		strut(f, "StanchionRope" .. i, V(px, FLR + 3.0, 56.6), V(px, FLR + 3.0, 59.4), 0.13, C.RED, M.Fabric, 20, "LSPD_Rope" .. tostring(i), 2, { canCollide = false })
	end

	-- ── Ghế chờ (2 dãy 4 chỗ phía Đông sảnh) ──
	for r, pz in ipairs({ 58.4, 62.6 }) do
		local grp = "LSPD_WaitSeat" .. tostring(r)
		box(f, "WaitBeam" .. r, V(9.6, 0.30, 0.9), V(272.6, FLR + 1.55, pz), C.STEEL_LT, M.Metal, 100, grp .. "_Beam", 1)
		for s = 0, 3 do
			local sx = 268.6 + s * 2.6
			box(f, string.format("WaitCush%d_%d", r, s), V(2.2, 0.34, 2.0), V(sx, FLR + 1.85, pz), C.NAVY_LT, M.Fabric, 60, string.format("LSPD_WaitCush%d_%d", r, s), 2)
			box(f, string.format("WaitBack%d_%d", r, s), V(2.2, 1.9, 0.28), V(sx, FLR + 2.9, pz + 0.9), C.NAVY_LT, M.Fabric, 60, string.format("LSPD_WaitBack%d_%d", r, s), 2)
		end
		for s = 0, 3 do
			box(f, string.format("WaitLeg%d_%d", r, s), V(0.22, 1.4, 0.22), V(268.6 + s * 2.6 - 1.0, FLR + 0.7, pz), C.STEEL_DK, M.Metal, 40, string.format("LSPD_WaitLeg%d_%d", r, s), 1, { canCollide = false })
		end
	end
	-- thảm chờ + bàn nước
	box(f, "LobbyRug", V(12.0, 0.05, 8.0), V(272.0, FLR + 0.02, 60.5), RGB(46, 58, 82), M.Carpet, 40, "LSPD_LobbyRug", 1, { castShadow = false })
	box(f, "WaterTable", V(2.2, 2.2, 2.2), V(278.6, FLR + 1.1, 55.6), C.WOOD_DK, M.WoodPlanks, 70, "LSPD_WaterTable", 1)
	vcyl(f, "WaterJug", V(1.5, 1.4, 1.4), V(278.6, FLR + 2.8, 55.6), C.GLASS, M.Glass, 30, "LSPD_WaterJug", 2)
	box(f, "CupsStack", V(0.5, 0.7, 0.5), V(277.9, FLR + 2.6, 55.6), C.WHITE, M.SmoothPlastic, 20, "LSPD_Cups", 2, { canCollide = false })

	-- ── Cây cảnh, thùng rác, bình cứu hoả, bảng tin ──
	for i, p in ipairs({ { 234.6, 67.2 }, { 279.6, 67.2 }, { 235.2, 45.6 }, { 267.4, 66.8 } }) do
		local grp = "LSPD_LobbyPlant" .. tostring(i)
		vcyl(f, "LobbyPot" .. i, V(2.2, 2.2, 2.2), V(p[1], FLR + 1.1, p[2]), C.CONCRETE, M.Concrete, 80, grp .. "_Pot", 1)
		ball(f, "LobbyBush" .. i, 3.4, V(p[1], FLR + 3.9, p[2]), C.GREEN, M.Grass, 50, grp .. "_Bush", 2)
		ball(f, "LobbyBushB" .. i, 2.2, V(p[1] + 0.8, FLR + 4.9, p[2] - 0.6), RGB(64, 140, 78), M.Grass, 40, grp .. "_BushB", 3)
	end
	vcyl(f, "LobbyBin", V(2.4, 2.0, 2.0), V(233.9, FLR + 1.2, 63.4), C.STEEL, M.Metal, 60, "LSPD_LobbyBin", 1)
	box(f, "ExtinguisherCab", V(0.9, 3.2, 1.6), V(233.6, FLR + 3.4, 50.6), C.RED, M.Metal, 80, "LSPD_Extinguisher", 2)
	-- bảng tin cộng đồng (tường Tây)
	box(f, "NoticeBoardFrame", V(0.34, 6.0, 8.4), V(233.34, FLR + 7.2, 59.4), C.WOOD_DK, M.WoodPlanks, 160, "LSPD_NoticeBoard", 3)
	box(f, "NoticeBoardCork", V(0.16, 5.2, 7.6), V(233.56, FLR + 7.2, 59.4), RGB(168, 132, 88), M.Fabric, 80, "LSPD_NoticeCork", 4)
	for i = 1, 4 do
		box(f, "NoticePaper" .. i, V(0.08, 1.5, 1.5), V(233.68, FLR + 8.2 - (i % 2) * 1.8, 56.4 + i * 1.5), C.WHITE, M.SmoothPlastic, 25, "LSPD_NoticePaper" .. tostring(i), 5, { canCollide = false, castShadow = false })
	end
	-- đồng hồ treo tường mặt tiền trong
	cyl(f, "WallClock", V(0.42, 1.9, 1.9), CFrame.new(V(257.0, 10.8, 68.58)) * CFrame.Angles(0, math.rad(90), 0), C.WHITE, M.SmoothPlastic, 40, "LSPD_WallClock", 6)
	cyl(f, "WallClockFace", V(0.10, 1.6, 1.6), CFrame.new(V(257.0, 10.8, 68.32)) * CFrame.Angles(0, math.rad(90), 0), C.STONE_LT, M.SmoothPlastic, 25, "LSPD_WallClockFace", 6, { canCollide = false, castShadow = false })
	box(f, "WallClockHandH", V(0.06, 0.10, 0.62), V(257.0, 10.86, 68.22), C.BLACK, M.SmoothPlastic, 10, "LSPD_ClockHandH", 6, { canCollide = false, castShadow = false })
	box(f, "WallClockHandM", V(0.06, 0.72, 0.10), V(257.0, 11.12, 68.22), C.BLACK, M.SmoothPlastic, 10, "LSPD_ClockHandM", 6, { canCollide = false, castShadow = false })

	-- ── Đèn trần + ống gió sảnh ──
	ceilingLight(f, "LobbyLight1", 240.0, 47.5, 16.85, 6.0, true, "LSPD_LobbyLight1")
	ceilingLight(f, "LobbyLight2", 240.0, 57.6, 16.85, 6.0, true, "LSPD_LobbyLight2")
	ceilingLight(f, "LobbyLight3", 240.0, 65.0, 16.85, 6.0, true, "LSPD_LobbyLight3")
	ceilingLight(f, "LobbyLight4", 259.0, 62.0, 16.85, 7.0, true, "LSPD_LobbyLight4")
	ceilingLight(f, "LobbyLight5", 272.0, 58.6, 16.85, 6.0, false, "LSPD_LobbyLight5")
	ceilingLight(f, "LobbyLight6", 272.0, 64.4, 16.85, 6.0, false, "LSPD_LobbyLight6")
	ceilingLight(f, "BullpenLight1", 248.0, 34.0, 16.85, 6.0, true, "LSPD_BullpenLight1")
	ceilingLight(f, "BullpenLight2", 260.0, 34.0, 16.85, 6.0, true, "LSPD_BullpenLight2")
	ceilingLight(f, "BullpenLight3", 248.0, 40.5, 16.85, 6.0, true, "LSPD_BullpenLight3")
	ceilingLight(f, "JailLight", 248.2, 14.0, 16.85, 6.0, false, "LSPD_JailLight")
	box(f, "DuctMain", V(27.0, 1.6, 2.0), V(262.0, 16.08, 66.6), C.STEEL_LT, M.Metal, 200, "LSPD_DuctMain", 8)
	for i = 0, 5 do
		box(f, "DuctVent" .. i, V(0.9, 1.7, 2.1), V(250.0 + i * 4.6, 15.86, 66.6), C.STEEL, M.Metal, 60, "LSPD_DuctVent" .. tostring(i), 9, { canCollide = false, castShadow = false })
	end
	box(f, "DuctBranch", V(2.0, 1.6, 9.0), V(275.5, 16.08, 61.0), C.STEEL_LT, M.Metal, 140, "LSPD_DuctBranch", 8)

	-- ═══════════════════════════════════════════════════════════════════════
	-- KHOANG XE CẢNH SÁT (Sally Port) — X 262.15..280.8, Z 20.45..37.55
	-- ═══════════════════════════════════════════════════════════════════════
	local g = folder(f, "Garage")
	-- ô sơn vàng + chữ POLICE + mũi tên sàn
	for i = 1, 4 do
		local sz = if i == 1 then V(15.0, 0.06, 0.34) elseif i == 2 then V(15.0, 0.06, 0.34) else V(0.34, 0.06, 14.0)
		local pos = if i == 1 then V(271.0, FLR + 0.03, 22.6) elseif i == 2 then V(271.0, FLR + 0.03, 35.4) else V(if i == 3 then 263.8 else 278.2, FLR + 0.03, 29.0)
		box(g, "GarageBayLine" .. i, sz, pos, C.YELLOW, M.SmoothPlastic, 30, "LSPD_GarageBay" .. tostring(i), 1, { canCollide = false, castShadow = false })
	end
	drawTextFlat(g, "GaragePoliceText", "POLICE", 270.0, 26.2, FLR + 0.06, 0.30, C.YELLOW, M.SmoothPlastic, 25, "LSPD_GarageText", 1)
	for i = 0, 2 do
		box(g, "GarageArrow" .. i, V(0.55, 0.05, 1.4 - i * 0.2), V(270.0, FLR + 0.04, 31.0 + i * 1.3), C.YELLOW, M.SmoothPlastic, 20, "LSPD_GarageArrow" .. tostring(i), 1, { canCollide = false, castShadow = false })
	end
	-- vết dầu + vạch kẻ an toàn
	for i, p in ipairs({ { 269.0, 32.0, 3.6 }, { 273.0, 24.5, 2.8 } }) do
		box(g, "OilStain" .. i, V(p[3], 0.05, p[3] * 0.8), V(p[1], FLR + 0.02, p[2]), RGB(38, 38, 42), M.Asphalt, 20, "LSPD_OilStain" .. tostring(i), 1, { canCollide = false, castShadow = false })
	end
	-- bàn thợ + bảng dụng cụ (tường Đông)
	box(g, "WorkbenchTop", V(9.6, 0.28, 1.9), V(268.6, FLR + 2.5, 36.30), C.WOOD_DK, M.WoodPlanks, 130, "LSPD_Workbench", 2)
	for i, lx in ipairs({ 264.6, 272.6 }) do
		box(g, "WorkbenchLeg" .. i, V(0.3, 2.2, 1.6), V(lx, FLR + 1.1, 36.30), C.STEEL_DK, M.Metal, 60, "LSPD_WorkbenchLeg" .. tostring(i), 1)
	end
	box(g, "PegBoard", V(9.2, 4.4, 0.28), V(268.6, FLR + 5.8, 37.28), RGB(178, 146, 104), M.WoodPlanks, 160, "LSPD_Pegboard", 3)
	for i = 1, 8 do
		box(g, "Tool" .. i, V(0.55, 1.7, 0.14), V(265.45 + i * 0.86, FLR + 7.5 - (i % 3) * 1.35, 37.02), C.STEEL, M.Metal, 24, "LSPD_Tool" .. tostring(i), 4, { canCollide = false, castShadow = false })
	end
	box(g, "ToolChest", V(2.6, 3.4, 4.2), V(276.4, FLR + 1.7, 35.6), C.RED, M.Metal, 180, "LSPD_ToolChest", 1)
	for i = 1, 3 do
		box(g, "ToolChestDrawer" .. i, V(2.7, 0.18, 4.3), V(276.4, FLR + 0.8 + i * 0.8, 35.6), C.STEEL_DK, M.Metal, 30, "LSPD_ToolChestDrawer" .. tostring(i), 2, { canCollide = false })
	end
	-- lốp xe + bình xăng + thùng phuy
	for i, p in ipairs({ { 264.8, 22.8 }, { 266.6, 22.8 }, { 264.8, 35.0 } }) do
		local grp = "LSPD_Tire" .. tostring(i)
		for k = 1, 3 do
			cyl(g, string.format("Tire%d_%d", i, k), V(1.0, 2.5, 2.5), CFrame.new(V(p[1], FLR + 0.45 + (k - 1) * 0.95, p[2])) * CFrame.Angles(0, math.rad(90), 0), C.BLACK, M.SmoothPlastic, 50, grp .. "_T" .. tostring(k), 1, { canCollide = false })
		end
	end
	for i = 1, 2 do
		box(g, "OilDrum" .. i, V(2.2, 3.0, 2.2), V(263.6, FLR + 1.5, 32.2 + (i - 1) * 2.8), C.ORANGE, M.Metal, 90, "LSPD_OilDrum" .. tostring(i), 1)
		vcyl(g, "OilDrumLid" .. i, V(0.3, 2.3, 2.3), V(263.6, FLR + 3.05, 32.2 + (i - 1) * 2.8), C.STEEL_DK, M.Metal, 40, "LSPD_OilDrumLid" .. tostring(i), 2)
	end
	box(g, "JerryCan1", V(1.1, 1.6, 1.8), V(275.0, FLR + 0.8, 21.4), C.RED, M.Metal, 50, "LSPD_JerryCan1", 1)
	box(g, "JerryCan2", V(1.1, 1.6, 1.8), V(276.4, FLR + 0.8, 21.4), C.RED, M.Metal, 50, "LSPD_JerryCan2", 1)
	-- locker cảnh sát + ghế bench + kệ
	lockerBank(g, "GarageLocker", "X", 20.9, 264.0, 272.0, FLR, 6.6, 1.4, 4, C.NAVY_DK, "LSPD_GarageLocker", 1)
	box(g, "GarageBench", V(6.0, 0.35, 1.7), V(268.0, FLR + 1.5, 22.4), C.WOOD, M.WoodPlanks, 80, "LSPD_GarageBench", 1)
	box(g, "GarageShelf", V(1.6, 7.0, 5.6), V(280.2, FLR + 3.5, 21.8), C.STEEL, M.Metal, 150, "LSPD_GarageShelf", 1)
	for i = 1, 3 do
		box(g, "ShelfLevel" .. i, V(1.8, 0.16, 5.8), V(280.2, FLR + 1.2 + (i - 1) * 2.2, 21.8), C.STEEL_DK, M.Metal, 40, "LSPD_ShelfLevel" .. tostring(i), 2)
	end
	box(g, "Compressor", V(2.6, 2.8, 3.0), V(263.0, FLR + 1.4, 27.0), C.RED, M.Metal, 140, "LSPD_Compressor", 1)
	vcyl(g, "AirTank", V(4.6, 1.7, 1.7), V(265.0, FLR + 4.2, 20.9), C.STEEL, M.Metal, 120, "LSPD_AirTank", 2)
	box(g, "ExtinguisherGarage", V(1.0, 2.8, 1.0), V(263.4, FLR + 1.4, 37.0), C.RED, M.Metal, 60, "LSPD_ExtGarage", 1)
	-- ống xả khí thải treo trần + 2 đèn
	vcyl(g, "ExhaustReel", V(1.6, 3.2, 3.2), V(272.0, 14.4, 29.0), C.STEEL_DK, M.Metal, 80, "LSPD_ExhaustReel", 6)
	strut(g, "ExhaustReelMount", V(272.0, 16.85, 29.0), V(272.0, 14.2, 29.0), 0.4, C.STEEL_DK, M.Metal, 90, "LSPD_ExhaustReelMount", 7)
	strut(g, "ExhaustHose", V(272.0, 13.6, 29.0), V(272.0, 10.2, 33.2), 0.35, C.STEEL_DK, M.SmoothPlastic, 50, "LSPD_ExhaustHose", 6, { canCollide = false })
	ceilingLight(g, "GarageLight1", 270.0, 24.4, 16.85, 6.0, true, "LSPD_GarageLight1")
	ceilingLight(g, "GarageLight2", 270.0, 33.0, 16.85, 6.0, true, "LSPD_GarageLight2")
	-- biển cảnh báo trong khoang xe
	box(g, "GarageWarnSign", V(5.6, 1.9, 0.18), V(266.0, FLR + 9.4, 20.55), C.YELLOW, M.SmoothPlastic, 50, "LSPD_GarageWarnSign", 4)
	drawTextZ(g, "GarageBaySignText", "BAY 1", 262.62, 30.0, 12.0, 0.22, 0.18, C.NEON_W, M.Neon, 25, "LSPD_GarageBaySign", 5)
	box(g, "GarageBaySignPanel", V(0.26, 2.4, 7.0), V(262.38, 13.0, 29.0), C.NAVY, M.SmoothPlastic, 140, "LSPD_GarageBaySignPanel", 4)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 10. NỘI THẤT TẦNG 2: PHÒNG HỌP GIAO BAN, PHÒNG THAY ĐỒ, PHÒNG TRƯỞNG ĐỒN
-- ═══════════════════════════════════════════════════════════════════════════

-- Cửa kính đơn (cánh + khung + tay nắm) cho vách ngăn nội bộ
local function glassDoorLeaf(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	fixed: number,
	c0: number,
	c1: number,
	y0: number,
	y1: number,
	group: string,
	row: number
)
	local len = c1 - c0
	box(parent, name .. "_RailTop", if axis == "X" then V(len, 0.32, 0.20) else V(0.20, 0.32, len), if axis == "X" then V((c0 + c1) * 0.5, y1 - 0.2, fixed) else V(fixed, y1 - 0.2, (c0 + c1) * 0.5), C.STEEL_LT, M.Metal, 110, group .. "_RailT", row)
	box(parent, name .. "_RailBot", if axis == "X" then V(len, 0.42, 0.20) else V(0.20, 0.42, len), if axis == "X" then V((c0 + c1) * 0.5, y0 + 0.25, fixed) else V(fixed, y0 + 0.25, (c0 + c1) * 0.5), C.STEEL_LT, M.Metal, 110, group .. "_RailB", row)
	glassPane(parent, name .. "_Glass", axis, fixed, c0 + 0.14, c1 - 0.14, y0 + 0.48, y1 - 0.38, 80, group .. "_Pane", row + 1)
	local hx = if axis == "X" then c1 - 0.42 else fixed + 0.25
	local hz = if axis == "X" then fixed + 0.25 else c1 - 0.42
	box(parent, name .. "_Handle", V(0.14, 1.1, 0.14), V(hx, y0 + 3.4, hz), C.CHROME, M.Metal, 30, group .. "_Handle", row + 1, { canCollide = false })
end

-- Kệ hồ sơ treo tường (khung + 4 tầng + hộp hồ sơ)
local function recordShelves(parent: Instance, name: string, axis: "X" | "Z", fixed: number, c0: number, c1: number, y0: number, height: number, group: string, row: number)
	local len = c1 - c0
	local d = 1.6
	local bodySize = if axis == "X" then V(len, height, d) else V(d, height, len)
	local bodyPos = if axis == "X" then V((c0 + c1) * 0.5, y0 + height * 0.5, fixed) else V(fixed, y0 + height * 0.5, (c0 + c1) * 0.5)
	box(parent, name .. "_Back", bodySize, bodyPos, C.STEEL_DK, M.Metal, 180, group .. "_Back", row)
	local levels = 3
	for i = 1, levels do
		local ly = y0 + (height / levels) * i
		local sz = if axis == "X" then V(len - 0.2, 0.16, d + 0.2) else V(d + 0.2, 0.16, len - 0.2)
		local pos = if axis == "X" then V((c0 + c1) * 0.5, ly, fixed) else V(fixed, ly, (c0 + c1) * 0.5)
		box(parent, string.format("%s_Level%d", name, i), sz, pos, C.STEEL_LT, M.Metal, 70, string.format("%s_Lvl%d", name, i), row + 1)
		-- hộp hồ sơ trên mỗi tầng
		local boxes = math.max(2, math.floor(len / 1.9))
		for b = 1, boxes do
			local mid = c0 + (len / boxes) * (b - 0.5)
			local bs = if axis == "X" then V(len / boxes - 0.35, 0.9, 1.2) else V(1.2, 0.9, len / boxes - 0.35)
			local bp = if axis == "X" then V(mid, ly + 0.55, fixed) else V(fixed, ly + 0.55, mid)
			box(parent, string.format("%s_Box%d_%d", name, i, b), bs, bp, if (b + i) % 2 == 0 then C.WOOD_DK else C.STEEL, M.Cardboard, 30, string.format("%s_BoxG%d_%d", name, i, b), row + 2, { canCollide = false })
		end
	end
end

local function buildUpperFloor(root: Instance)
	local f = folder(root, "05_UpperFloor")
	local T = 0.9

	-- ═══ VÁCH NGĂN TẦNG 2 ═══
	-- tường trục giữa (phân khu văn phòng mở / hành lang phía Nam)
	panelWall(f, "SpineWallF2", "X", 42.4, 233.2, 280.8, F2_FLOOR, 32.00, T, C.CONCRETE, 250, "LSPD_SpineF2", {
		{ a = 236.4, b = 242.4, y0 = F2_FLOOR, y1 = 26.39 },
		{ a = 253.6, b = 261.6, y0 = F2_FLOOR, y1 = 26.39 },
	}, M.Concrete)
	doorFrame(f, "SpineDoorW", "X", 42.4, 236.4, 242.4, FLR2, 26.39, 1.2, C.STEEL_LT, "LSPD_SpineDoorW", 20)
	doorFrame(f, "SpineDoorE", "X", 42.4, 253.6, 261.6, FLR2, 26.39, 1.2, C.STEEL_LT, "LSPD_SpineDoorE", 20)
	box(f, "SpineHeaderW", V(6.6, 0.5, 1.4), V(239.4, 26.0, 42.4), C.NAVY, M.SmoothPlastic, 200, "LSPD_SpineHeaderW", 21)
	box(f, "SpineHeaderE", V(8.6, 0.5, 1.4), V(257.6, 26.0, 42.4), C.NAVY, M.SmoothPlastic, 200, "LSPD_SpineHeaderE", 21)
	drawText(f, "SpineSignW", "BRIEFING", 239.4 - textWidth("BRIEFING", 0.17) * 0.5, 26.65, 43.16, 0.2, 0.17, C.NEON_B, M.Neon, 25, "LSPD_SpineSignW", 22)
	drawText(f, "SpineSignE", "OFFICES", 257.6 - textWidth("OFFICES", 0.17) * 0.5, 26.65, 43.16, 0.2, 0.17, C.NEON_B, M.Neon, 25, "LSPD_SpineSignE", 22)

	-- tường Nam Z = 56.6 (3 lỗ cửa: giao ban, thay đồ, trưởng đồn)
	panelWall(f, "SouthWallF2", "X", 56.6, 233.2, 280.8, F2_FLOOR, 32.00, T, C.CONCRETE, 250, "LSPD_SouthF2", {
		{ a = 239.2, b = 247.2, y0 = F2_FLOOR, y1 = 26.39 },
		{ a = 256.0, b = 260.0, y0 = F2_FLOOR, y1 = 25.39 },
		{ a = 271.6, b = 276.0, y0 = F2_FLOOR, y1 = 25.39 },
	}, M.Concrete)
	doorFrame(f, "BriefingDoor", "X", 56.6, 239.2, 247.2, FLR2, 26.39, 1.3, C.STEEL_LT, "LSPD_BriefingDoor", 20)
	glassDoorLeaf(f, "BriefingDoorLeafL", "X", 56.6, 239.5, 243.1, FLR2, 26.2, "LSPD_BriefingLeafL", 21)
	glassDoorLeaf(f, "BriefingDoorLeafR", "X", 56.6, 243.3, 246.9, FLR2, 26.2, "LSPD_BriefingLeafR", 21)
	doorFrame(f, "LockerDoor", "X", 56.6, 256.0, 260.0, FLR2, 25.39, 1.2, C.STEEL, "LSPD_LockerDoor", 20)
	glassDoorLeaf(f, "LockerDoorLeaf", "X", 56.6, 256.2, 259.8, FLR2, 25.2, "LSPD_LockerLeaf", 21)
	doorFrame(f, "ChiefDoor", "X", 56.6, 271.6, 276.0, FLR2, 25.39, 1.2, C.WOOD_DK, "LSPD_ChiefDoor", 20)
	box(f, "ChiefDoorLeaf", V(4.0, 7.6, 0.22), V(273.8, FLR2 + 3.8, 56.6), C.WOOD, M.WoodPlanks, 200, "LSPD_ChiefLeaf", 21)
	box(f, "ChiefDoorGlass", V(2.6, 4.4, 0.10), V(273.8, FLR2 + 4.6, 56.72), C.GLASS_DK, M.Glass, 60, "LSPD_ChiefLeafGlass", 22, { transparency = 0.5, canCollide = false, castShadow = false })

	-- vách dọc chia 3 phòng phía Nam
	panelWall(f, "DivX252F2", "Z", 252.0, 57.05, 68.8, F2_FLOOR, 32.00, T, C.CONCRETE, 240, "LSPD_DivX252", {}, M.Concrete)
	panelWall(f, "DivX266F2", "Z", 266.0, 57.05, 68.8, F2_FLOOR, 32.00, T, C.CONCRETE, 240, "LSPD_DivX266", {}, M.Concrete)

	-- vách thang bộ lên mái (X 251.8..264.2, Z 25.8..38.2)
	panelWall(f, "ShaftWallW", "Z", 251.8, 25.8, 38.2, F2_FLOOR, 32.00, T, C.CONCRETE, 320, "LSPD_ShaftW", {}, M.Concrete)
	panelWall(f, "ShaftWallE", "Z", 264.2, 25.8, 38.2, F2_FLOOR, 32.00, T, C.CONCRETE, 320, "LSPD_ShaftE", {}, M.Concrete)
	panelWall(f, "ShaftWallN", "X", 25.8, 251.8, 264.2, F2_FLOOR, 32.00, T, C.CONCRETE, 320, "LSPD_ShaftN", {}, M.Concrete)
	panelWall(f, "ShaftWallS", "X", 38.2, 251.8, 264.2, F2_FLOOR, 32.00, T, C.CONCRETE, 320, "LSPD_ShaftS", {
		{ a = 253.6, b = 258.6, y0 = F2_FLOOR, y1 = 25.9 },
	}, M.Concrete)
	doorFrame(f, "ShaftDoor", "X", 38.2, 253.6, 258.6, FLR2, 25.9, 1.2, C.STEEL_DK, "LSPD_ShaftDoor", 22)
	box(f, "ShaftDoorLeaf", V(4.6, 8.2, 0.20), V(256.1, FLR2 + 4.1, 38.2), C.STEEL, M.Metal, 260, "LSPD_ShaftLeaf", 23)
	box(f, "ShaftDoorSign", V(3.0, 0.9, 0.14), V(256.1, FLR2 + 9.2, 38.5), C.NAVY, M.SmoothPlastic, 40, "LSPD_ShaftSign", 23)
	drawText(f, "ShaftSignText", "ROOF", 256.1 - textWidth("ROOF", 0.16) * 0.5, FLR2 + 9.35, 38.62, 0.16, 0.16, C.NEON_W, M.Neon, 20, "LSPD_ShaftSignText", 24)

	-- ═══ PHÒNG PHỎNG VẤN (2 phòng vách kính, phía Đông Bắc) ═══
	for r = 1, 2 do
		local z0 = if r == 1 then 5.2 else 18.0
		local z1 = if r == 1 then 16.6 else 28.6
		local grp = "LSPD_Interview" .. tostring(r)
		panelWall(f, "IntRoomWallN" .. r, "X", z0 + if r == 1 then 0 else 0, 266.95, 280.8, F2_FLOOR, 32.00, T, C.CONCRETE, 220, grp .. "_N", {}, M.Concrete)
		panelWall(f, "IntRoomWallS" .. r, "X", z1, 266.95, 280.8, F2_FLOOR, 32.00, T, C.CONCRETE, 220, grp .. "_S", {}, M.Concrete)
		-- vách kính hướng Tây + cửa
		panelWall(f, "IntRoomWallW" .. r, "Z", 266.5, z0, z1, F2_FLOOR, 32.00, T, C.CONCRETE, 220, grp .. "_W", {
			{ a = z0 + 5.0, b = z0 + 9.0, y0 = F2_FLOOR, y1 = 25.39 },
		}, M.Concrete)
		doorFrame(f, "IntRoomDoor" .. r, "Z", 266.5, z0 + 5.0, z0 + 9.0, FLR2, 25.39, 1.2, C.STEEL_LT, grp .. "_Door", 21)
		glassDoorLeaf(f, "IntRoomLeaf" .. r, "Z", 266.5, z0 + 5.2, z0 + 8.8, FLR2, 25.2, grp .. "_Leaf", 22)
		-- bàn phỏng vấn + 2 ghế + kính một chiều + camera + máy ghi âm
		box(f, "IntTable" .. r, V(5.6, 0.26, 2.6), V(274.0, FLR2 + 2.5, (z0 + z1) * 0.5), C.STEEL_LT, M.Metal, 130, grp .. "_Table", 22)
		box(f, "IntTableLeg" .. r, V(0.3, 2.4, 0.3), V(274.0, FLR2 + 1.2, (z0 + z1) * 0.5), C.STEEL_DK, M.Metal, 60, grp .. "_TableLeg", 21)
		officeChair(f, "IntChairA" .. r, 274.0, (z0 + z1) * 0.5 - 2.4, 0, grp .. "_ChairA", 22, nil, FLR2)
		officeChair(f, "IntChairB" .. r, 274.0, (z0 + z1) * 0.5 + 2.4, math.pi, grp .. "_ChairB", 22, nil, FLR2)
		box(f, "IntMirror" .. r, V(0.16, 3.6, 6.0), V(280.5, FLR2 + 6.4, (z0 + z1) * 0.5), C.CHROME, M.Metal, 90, grp .. "_Mirror", 23, { reflectance = 0.55, canCollide = false })
		box(f, "IntMirrorFrame" .. r, V(0.12, 4.1, 6.5), V(280.62, FLR2 + 6.4, (z0 + z1) * 0.5), C.STEEL_DK, M.Metal, 80, grp .. "_MirrorFrame", 22)
		ball(f, "IntCam" .. r, 0.65, V(280.4, FLR2 + 10.4, z0 + 1.2), C.BLACK, M.SmoothPlastic, 30, grp .. "_Cam", 24)
		box(f, "IntRecorder" .. r, V(1.2, 0.5, 1.0), V(274.0, FLR2 + 2.9, (z0 + z1) * 0.5), C.BLACK, M.SmoothPlastic, 30, grp .. "_Rec", 23, { canCollide = false })
		box(f, "IntLamp" .. r, V(1.2, 0.16, 1.2), V(274.0, 31.82, (z0 + z1) * 0.5), C.NEON_W, M.Neon, 20, grp .. "_Lamp", 25, { canCollide = false, castShadow = false })
		box(f, "IntSign" .. r, V(2.6, 0.8, 0.14), V(268.8, FLR2 + 8.6, z0 + 0.0), C.NAVY, M.SmoothPlastic, 40, grp .. "_Sign", 23)
		drawTextZ(f, "IntSignText" .. r, "INTERVIEW", 268.9, z0 + 1.2, FLR2 + 8.7, 0.16, 0.14, C.NEON_B, M.Neon, 20, grp .. "_SignText", 24)
	end

	-- ═══ VĂN PHÒNG MỞ: 4 bàn + kệ hồ sơ + máy in ═══
	workstation(f, "F2DeskA", 239.0, 19.5, 0, "LSPD_F2DeskA", 21, FLR2)
	workstation(f, "F2DeskB", 239.0, 29.5, 0, "LSPD_F2DeskB", 21, FLR2)
	workstation(f, "F2DeskC", 246.4, 19.5, 0, "LSPD_F2DeskC", 21, FLR2)
	workstation(f, "F2DeskD", 246.4, 29.5, 0, "LSPD_F2DeskD", 21, FLR2)
	recordShelves(f, "F2RecordNorth", "X", 6.0, 236.0, 262.0, FLR2, 9.0, "LSPD_F2RecordN", 22)
	recordShelves(f, "F2RecordWest", "Z", 233.9, 8.0, 24.0, FLR2, 9.0, "LSPD_F2RecordW", 22)
	lockerBank(f, "F2FileCab", "Z", 233.9, 30.0, 40.0, FLR2, 6.4, 1.5, 4, C.STEEL_LT, "LSPD_F2FileCab", 21)
	box(f, "F2PrinterTable", V(4.6, 0.28, 2.4), V(246.0, FLR2 + 2.5, 40.6), C.WOOD_DK, M.WoodPlanks, 90, "LSPD_F2PrinterTable", 21)
	box(f, "F2Printer", V(3.0, 1.7, 2.0), V(246.0, FLR2 + 3.4, 40.6), C.STEEL_LT, M.SmoothPlastic, 80, "LSPD_F2Printer", 22)
	box(f, "F2PrinterPapers", V(1.6, 0.14, 1.4), V(246.0, FLR2 + 4.32, 40.6), C.WHITE, M.SmoothPlastic, 20, "LSPD_F2PrinterPaper", 23, { canCollide = false, castShadow = false })
	-- khu nghỉ: quầy cà phê + tủ lạnh + bàn nhỏ
	box(f, "BreakCounter", V(1.9, 3.4, 8.0), V(279.8, FLR2 + 1.7, 35.0), C.WOOD, M.WoodPlanks, 160, "LSPD_BreakCounter", 21)
	box(f, "BreakCounterTop", V(2.4, 0.26, 8.4), V(279.7, FLR2 + 3.5, 35.0), C.STONE_LT, M.Marble, 120, "LSPD_BreakTop", 22)
	box(f, "CoffeeMachine", V(1.5, 2.0, 1.8), V(279.7, FLR2 + 4.6, 32.6), C.STEEL_DK, M.Metal, 60, "LSPD_Coffee", 23)
	box(f, "CoffeeCups", V(0.7, 0.9, 0.7), V(279.7, FLR2 + 4.0, 34.2), C.WHITE, M.SmoothPlastic, 20, "LSPD_CoffeeCups", 23, { canCollide = false })
	box(f, "Microwave", V(1.6, 1.4, 1.9), V(279.7, FLR2 + 4.3, 37.6), C.STEEL_LT, M.Metal, 60, "LSPD_Microwave", 23)
	box(f, "Fridge", V(2.4, 6.4, 3.0), V(279.5, FLR2 + 3.2, 40.6), C.WHITE, M.Metal, 180, "LSPD_Fridge", 21)
	box(f, "BreakTable", V(4.6, 0.26, 3.0), V(274.0, FLR2 + 2.5, 40.2), C.WOOD, M.WoodPlanks, 90, "LSPD_BreakTable", 21)
	box(f, "BreakTableLeg", V(0.3, 2.4, 0.3), V(274.0, FLR2 + 1.2, 40.2), C.STEEL_DK, M.Metal, 50, "LSPD_BreakTableLeg", 21)
	officeChair(f, "BreakChairA", 271.6, 40.2, math.pi * 0.5, "LSPD_BreakChairA", 22, nil, FLR2)
	officeChair(f, "BreakChairB", 276.4, 40.2, -math.pi * 0.5, "LSPD_BreakChairB", 22, nil, FLR2)

	-- ═══ PHÒNG HỌP GIAO BAN (bậc ghế + bục + màn hình) ═══
	local brGrp = "LSPD_Briefing"
	for t = 1, 3 do
		local baseZ = 66.6 - (t - 1) * 3.0
		local platY = FLR2 + (t - 1) * 0.85
		box(f, "BriefTier" .. t, V(17.4, 0.85 * t + 0.2, 3.0), V(242.6, FLR2 + (0.85 * t) * 0.5 - 0.1, baseZ + 1.5), C.STONE_DK, M.Concrete, 200, brGrp .. "_Tier" .. tostring(t), 21)
		box(f, "BriefBenchSeat" .. t, V(16.4, 0.34, 1.5), V(242.6, platY + 1.5, baseZ + 1.0), C.NAVY, M.Fabric, 70, brGrp .. "_Seat" .. tostring(t), 22)
		box(f, "BriefBenchBack" .. t, V(16.4, 1.8, 0.26), V(242.6, platY + 2.4, baseZ + 1.8), C.NAVY, M.Fabric, 70, brGrp .. "_Back" .. tostring(t), 23)
		box(f, "BriefBenchFoot" .. t, V(16.4, 0.7, 0.3), V(242.6, platY + 0.35, baseZ - 0.1), C.STEEL_DK, M.Metal, 50, brGrp .. "_Foot" .. tostring(t), 21)
		-- ngăn ghế
		for s = 0, 6 do
			box(f, string.format("BriefDiv%d_%d", t, s), V(0.16, 1.3, 1.5), V(234.6 + s * 2.7, platY + 0.9, baseZ + 1.0), C.STEEL_DK, M.Metal, 25, string.format("LSPD_BriefDiv%d_%d", t, s), 23, { canCollide = false })
		end
	end
	box(f, "BriefPodium", V(3.2, 0.24, 2.0), V(249.4, FLR2 + 3.4, 58.6), C.WOOD_DK, M.WoodPlanks, 100, brGrp .. "_Podium", 21)
	box(f, "BriefPodiumBody", V(2.6, 3.2, 1.4), V(249.4, FLR2 + 1.6, 58.6), C.WOOD, M.WoodPlanks, 110, brGrp .. "_PodiumBody", 21)
	box(f, "BriefPodiumMouth", V(0.4, 1.2, 0.4), V(249.4, FLR2 + 4.1, 58.9), C.BLACK, M.SmoothPlastic, 30, brGrp .. "_Mic", 22)
	box(f, "BriefScreen", V(15.0, 7.0, 0.28), V(242.6, FLR2 + 9.4, 68.6), C.BLACK, M.SmoothPlastic, 130, brGrp .. "_Screen", 22)
	box(f, "BriefScreenFace", V(14.2, 6.4, 0.10), V(242.6, FLR2 + 9.4, 68.44), RGB(48, 92, 132), M.Neon, 60, brGrp .. "_ScreenFace", 23, { canCollide = false, castShadow = false })
	box(f, "BriefScreenFrame", V(15.8, 7.6, 0.16), V(242.6, FLR2 + 9.4, 68.7), C.STEEL_DK, M.Metal, 110, brGrp .. "_ScreenFrame", 22)
	-- bảng tên phòng + cờ + bình nước
	box(f, "BriefRoomSign", V(9.0, 1.5, 0.16), V(242.6, FLR2 + 5.7, 57.1), C.NAVY, M.SmoothPlastic, 50, brGrp .. "_Sign", 22)
	drawText(f, "BriefRoomSignText", "BRIEFING", 242.6 - textWidth("BRIEFING", 0.22) * 0.5, FLR2 + 5.85, 57.24, 0.2, 0.22, C.NEON_W, M.Neon, 25, brGrp .. "_SignText", 23)
	for i, fx in ipairs({ 235.4, 237.6 }) do
		vcyl(f, "BriefFlagPole" .. i, V(7.0, 0.25, 0.25), V(fx, FLR2 + 3.5, 58.6), C.CHROME, M.Metal, 40, "LSPD_BriefFlagPole" .. tostring(i), 22)
		box(f, "BriefFlag" .. i, V(1.6, 2.2, 0.10), V(fx + 0.85, FLR2 + 5.9, 58.6), if i == 1 then C.NAVY else C.RED, M.Fabric, 30, "LSPD_BriefFlag" .. tostring(i), 23, { canCollide = false, castShadow = false })
	end
	box(f, "BriefWaterCooler", V(1.8, 4.6, 1.8), V(251.0, FLR2 + 2.3, 67.6), C.WHITE, M.SmoothPlastic, 90, brGrp .. "_Water", 21)
	ceilingLight(f, "BriefLight1", 242.6, 61.0, 32.00, 8.0, true, "LSPD_BriefLight1")
	ceilingLight(f, "BriefLight2", 242.6, 66.0, 32.00, 8.0, true, "LSPD_BriefLight2")

	-- ═══ PHÒNG THAY ĐỒ + TỦ LOCKER ═══
	lockerBank(f, "ChangeLockerW", "Z", 253.2, 58.0, 68.2, FLR2, 8.4, 1.6, 6, C.NAVY_DK, "LSPD_ChangeLockerW", 21)
	lockerBank(f, "ChangeLockerE", "Z", 264.6, 58.0, 68.2, FLR2, 8.4, 1.6, 6, C.NAVY_DK, "LSPD_ChangeLockerE", 21)
	box(f, "ChangeBench", V(8.0, 0.35, 2.2), V(258.9, FLR2 + 1.5, 62.0), C.WOOD, M.WoodPlanks, 80, "LSPD_ChangeBench", 21)
	for i, lx in ipairs({ 255.6, 262.2 }) do
		box(f, "ChangeBenchLeg" .. i, V(0.28, 1.45, 2.0), V(lx, FLR2 + 0.72, 62.0), C.STEEL_DK, M.Metal, 40, "LSPD_ChangeLeg" .. tostring(i), 21, { canCollide = false })
	end
	box(f, "ChangeMirror", V(6.2, 4.4, 0.16), V(258.9, FLR2 + 5.6, 68.6), C.CHROME, M.Metal, 60, "LSPD_ChangeMirror", 22, { reflectance = 0.55, canCollide = false })
	box(f, "ChangeMirrorFrame", V(6.7, 4.9, 0.12), V(258.9, FLR2 + 5.6, 68.7), C.STEEL_DK, M.Metal, 60, "LSPD_ChangeMirrorFrame", 21)
	box(f, "ChangeSink", V(4.6, 0.34, 1.6), V(259.0, FLR2 + 2.5, 67.6), C.STONE_LT, M.Marble, 80, "LSPD_ChangeSink", 22)
	for i, sx in ipairs({ 257.6, 260.4 }) do
		box(f, "ChangeBasin" .. i, V(1.2, 0.5, 1.2), V(sx, FLR2 + 2.35, 67.6), C.WHITE, M.CeramicTiles, 30, "LSPD_ChangeBasin" .. tostring(i), 22, { canCollide = false })
	end
	for i = 1, 3 do
		box(f, "TowelHook" .. i, V(0.24, 0.24, 0.6), V(266.5 - 0.3, FLR2 + 6.2, 59.4 + i * 2.2), C.CHROME, M.Metal, 15, "LSPD_TowelHook" .. tostring(i), 22, { canCollide = false })
	end
	ceilingLight(f, "ChangeLight", 258.9, 63.0, 32.00, 7.0, false, "LSPD_ChangeLight")

	-- ═══ PHÒNG TRƯỞNG ĐỒN (vách kính, bàn gỗ lớn) ═══
	box(f, "ChiefGlassWall", V(0.16, 5.2, 10.4), V(272.6, FLR2 + 4.5, 62.2), C.GLASS, M.Glass, 70, "LSPD_ChiefGlass", 21, { transparency = 0.55, canCollide = false, castShadow = false })
	for i = 0, 4 do
		box(f, "ChiefGlassMullion" .. i, V(0.20, 5.4, 0.16), V(272.6, FLR2 + 4.5, 57.0 + i * 2.6), C.STEEL_LT, M.Metal, 25, "LSPD_ChiefMull" .. tostring(i), 22, { canCollide = false })
	end
	box(f, "ChiefDeskTop", V(8.0, 0.30, 3.6), V(276.0, FLR2 + 2.7, 64.4), C.WOOD_DK, M.WoodPlanks, 140, "LSPD_ChiefDeskTop", 21)
	box(f, "ChiefDeskPanel", V(7.2, 2.4, 0.3), V(276.0, FLR2 + 1.35, 62.7), C.WOOD, M.WoodPlanks, 110, "LSPD_ChiefDeskPanel", 21)
	box(f, "ChiefDeskPanelL", V(0.3, 2.4, 3.2), V(272.3, FLR2 + 1.35, 64.4), C.WOOD, M.WoodPlanks, 110, "LSPD_ChiefDeskPanelL", 21)
	box(f, "ChiefDeskPanelR", V(0.3, 2.4, 3.2), V(279.7, FLR2 + 1.35, 64.4), C.WOOD, M.WoodPlanks, 110, "LSPD_ChiefDeskPanelR", 21)
	box(f, "ChiefMonitor", V(2.4, 1.5, 0.2), V(276.0, FLR2 + 4.0, 64.6), C.BLACK, M.SmoothPlastic, 60, "LSPD_ChiefMon", 22, { canCollide = false })
	box(f, "ChiefMonitorScreen", V(2.15, 1.28, 0.09), V(276.0, FLR2 + 4.0, 64.49), RGB(70, 110, 160), M.Neon, 30, "LSPD_ChiefMonScreen", 23, { canCollide = false, castShadow = false })
	box(f, "ChiefNameplate", V(2.6, 0.5, 0.7), V(278.6, FLR2 + 3.55, 64.4), C.GOLD, M.Metal, 40, "LSPD_ChiefNameplate", 23, { canCollide = false })
	box(f, "ChiefPapers", V(1.4, 0.08, 1.8), V(274.0, FLR2 + 2.88, 64.4), C.WHITE, M.SmoothPlastic, 20, "LSPD_ChiefPapers", 23, { canCollide = false, castShadow = false })
	officeChair(f, "ChiefChair", 276.0, 66.4, math.pi, "LSPD_ChiefChair", 22, C.LEATHER, FLR2)
	officeChair(f, "ChiefGuestA", 274.2, 61.6, 0, "LSPD_ChiefGuestA", 22, C.FABRIC, FLR2)
	officeChair(f, "ChiefGuestB", 277.8, 61.6, 0, "LSPD_ChiefGuestB", 22, C.FABRIC, FLR2)
	box(f, "ChiefBookcase", V(1.7, 8.6, 8.0), V(280.0, FLR2 + 4.3, 60.6), C.WOOD_DK, M.WoodPlanks, 170, "LSPD_ChiefBookcase", 21)
	for i = 1, 4 do
		box(f, "ChiefShelf" .. i, V(1.9, 0.16, 8.2), V(280.0, FLR2 + 1.0 + (i - 1) * 2.1, 60.6), C.WOOD, M.WoodPlanks, 40, "LSPD_ChiefShelf" .. tostring(i), 22)
		for b = 1, 6 do
			box(f, string.format("ChiefBook%d_%d", i, b), V(1.2, 1.3, 0.22), V(280.0, FLR2 + 1.72 + (i - 1) * 2.1, 57.4 + b * 1.15), if b % 2 == 0 then C.RED else C.NAVY_LT, M.SmoothPlastic, 15, string.format("LSPD_ChiefBook%d_%d", i, b), 23, { canCollide = false, castShadow = false })
		end
	end
	box(f, "ChiefSafe", V(3.0, 4.6, 3.0), V(279.2, FLR2 + 2.3, 67.2), C.STEEL_DK, M.Metal, 300, "LSPD_ChiefSafe", 21)
	box(f, "ChiefSafeDial", V(0.3, 1.2, 1.2), V(277.5, FLR2 + 2.6, 67.2), C.CHROME, M.Metal, 40, "LSPD_ChiefSafeDial", 22, { canCollide = false })
	box(f, "ChiefBlinds", V(0.14, 5.4, 8.6), V(280.5, FLR2 + 6.2, 63.0), C.STONE_LT, M.Fabric, 60, "LSPD_ChiefBlinds", 22, { canCollide = false })
	vcyl(f, "ChiefPot", V(2.0, 2.2, 2.2), V(267.6, FLR2 + 1.1, 67.4), C.CONCRETE, M.Concrete, 60, "LSPD_ChiefPot", 21)
	ball(f, "ChiefBush", 3.2, V(267.6, FLR2 + 3.8, 67.4), C.GREEN, M.Grass, 40, "LSPD_ChiefBush", 22)
	ceilingLight(f, "ChiefLight", 276.0, 63.4, 32.00, 7.0, true, "LSPD_ChiefLight")

	-- ═══ HÀNH LANG: đèn, cây, bình cứu hoả, biển chỉ dẫn ═══
	ceilingLight(f, "HallLight1", 244.0, 44.4, 32.00, 6.0, true, "LSPD_HallLight1")
	ceilingLight(f, "HallLight2", 257.0, 44.4, 32.00, 6.0, true, "LSPD_HallLight2")
	ceilingLight(f, "HallLight3", 270.0, 44.4, 32.00, 6.0, true, "LSPD_HallLight3")
	ceilingLight(f, "OfficeLight1", 240.0, 22.0, 32.00, 7.0, true, "LSPD_OfficeLight1")
	ceilingLight(f, "OfficeLight2", 240.0, 32.0, 32.00, 7.0, true, "LSPD_OfficeLight2")
	ceilingLight(f, "OfficeLight3", 258.0, 20.0, 32.00, 7.0, true, "LSPD_OfficeLight3")
	ceilingLight(f, "OfficeLight4", 274.0, 12.0, 32.00, 7.0, true, "LSPD_OfficeLight4")
	vcyl(f, "F2PlantPot1", V(2.2, 2.4, 2.4), V(235.0, FLR2 + 1.2, 44.6), C.CONCRETE, M.Concrete, 60, "LSPD_F2Pot1", 21)
	ball(f, "F2PlantBush1", 3.4, V(235.0, FLR2 + 4.2, 44.6), C.GREEN, M.Grass, 40, "LSPD_F2Bush1", 22)
	vcyl(f, "F2PlantPot2", V(2.2, 2.4, 2.4), V(279.0, FLR2 + 1.2, 44.6), C.CONCRETE, M.Concrete, 60, "LSPD_F2Pot2", 21)
	ball(f, "F2PlantBush2", 3.4, V(279.0, FLR2 + 4.2, 44.6), C.GREEN, M.Grass, 40, "LSPD_F2Bush2", 22)
	box(f, "F2Extinguisher", V(1.0, 2.8, 1.0), V(233.6, FLR2 + 1.4, 54.4), C.RED, M.Metal, 60, "LSPD_F2Ext", 21)
	box(f, "F2ExitSign", V(3.0, 0.9, 0.14), V(247.0, FLR2 + 8.6, 42.9), C.GREEN, M.Neon, 30, "LSPD_F2Exit", 22, { canCollide = false, castShadow = false })
	drawText(f, "F2ExitText", "EXIT", 247.0 - textWidth("EXIT", 0.16) * 0.5, FLR2 + 8.75, 43.0, 0.14, 0.16, C.WHITE, M.Neon, 20, "LSPD_F2ExitText", 23)
	box(f, "F2WaterCooler", V(1.8, 4.6, 1.8), V(252.6, FLR2 + 2.3, 44.6), C.WHITE, M.SmoothPlastic, 90, "LSPD_F2Water", 21)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 11. SÂN THƯỢNG: BÃI ĐÁP TRỰC THĂNG, BUỒNG THANG, THIẾT BỊ KỸ THUẬT
-- ═══════════════════════════════════════════════════════════════════════════
local function buildRoof(root: Instance)
	local f = folder(root, "06_Roof")
	local HX, HZ = 257.0, 15.5
	local DECK = 32.82

	-- ═══ BUỒNG THANG LÊN MÁI (nhà chòi cầu thang) ═══
	brickWall(f, "PenthouseWallN", "X", 25.8, 251.8, 264.2, 32.54, 8.66, 0.9, C.STONE, 240, "LSPD_PenthouseN")
	brickWall(f, "PenthouseWallW", "Z", 251.8, 26.25, 37.75, 32.54, 8.66, 0.9, C.STONE, 240, "LSPD_PenthouseW")
	brickWall(f, "PenthouseWallE", "Z", 264.2, 26.25, 37.75, 32.54, 8.66, 0.9, C.STONE, 240, "LSPD_PenthouseE")
	-- tường Nam có cửa ra sân thượng
	for _, seg in ipairs({ { 251.8, 253.5 }, { 258.5, 264.2 } }) do
		brickWall(f, "PenthouseWallS_" .. math.floor(seg[1]), "X", 38.2, seg[1], seg[2], 32.54, 8.66, 0.9, C.STONE, 240, "LSPD_PenthouseS" .. math.floor(seg[1]))
	end
	box(f, "PenthouseHeader", V(5.4, 0.8, 1.2), V(256.0, 40.74, 38.2), C.STONE_LT, M.Marble, 240, "LSPD_PentHeader", 18)
	doorFrame(f, "RoofDoor", "X", 38.2, 253.5, 258.5, 32.54, 40.74, 1.4, C.STEEL_DK, "LSPD_RoofDoor", 17)
	box(f, "RoofDoorLeaf", V(4.6, 7.9, 0.22), V(256.0, 36.5, 38.2), C.STEEL, M.Metal, 280, "LSPD_RoofDoorLeaf", 18)
	box(f, "RoofDoorGlass", V(2.6, 3.0, 0.12), V(256.0, 37.8, 38.06), C.GLASS_DK, M.Glass, 60, "LSPD_RoofDoorGlass", 19, { transparency = 0.45, canCollide = false, castShadow = false })
	box(f, "PenthouseRoof", V(13.4, 0.5, 13.4), V(258.0, 41.06, 32.0), C.CONCRETE_DK, M.Concrete, 420, "LSPD_PentRoof", 19, { structural = true })
	box(f, "PenthouseCornice", V(14.2, 0.42, 14.2), V(258.0, 40.62, 32.0), C.STONE_LT, M.Marble, 260, "LSPD_PentCornice", 19)
	box(f, "PentLamp", V(2.0, 0.2, 2.0), V(258.0, 41.34, 32.0), C.NEON_W, M.Neon, 25, "LSPD_PentLamp", 20, { canCollide = false, castShadow = false })
	for i, wy in ipairs({ 35.6, 38.6 }) do
		box(f, "PentWindow" .. i, V(0.22, 1.6, 3.0), V(251.6, wy, 32.0), C.GLASS_DK, M.Glass, 40, "LSPD_PentWindow" .. tostring(i), 18, { transparency = 0.5, canCollide = false, castShadow = false })
	end
	-- cầu thang từ tầng 2 lên mái
	stairRun(f, "RoofStaircase", V(258.0, F2_FLOOR, 37.4), V(0, 0, -1), 7.4, 15, 32.50 - F2_FLOOR, 10.8, C.CONCRETE, "LSPD_RoofStair", 18, M.Concrete)
	-- chiếu nghỉ nhỏ trên mái + lan can
	box(f, "RoofStairLanding", V(7.6, 0.22, 2.6), V(258.0, 32.56, 25.2), C.CONCRETE, M.Concrete, 160, "LSPD_RoofLanding", 18)
	railingRun(f, "RoofLandingRail", "X", 24.0, 254.2, 261.8, 32.62, 3.2, C.STEEL_LT, "LSPD_RoofLandingRail", 19, { kick = true })

	-- ═══ BÃI ĐÁP TRỰC THĂNG ═══
	box(f, "HelipadDeck", V(24.0, 0.32, 18.0), V(HX, 32.66, HZ), C.ASPHALT, M.Asphalt, 600, "LSPD_Helipad", 15, { structural = true })
	box(f, "HelipadEdgeN", V(24.6, 0.16, 0.7), V(HX, 32.90, HZ - 8.9), C.WHITE, M.SmoothPlastic, 90, "LSPD_HelipadEdgeN", 16, { canCollide = false })
	box(f, "HelipadEdgeS", V(24.6, 0.16, 0.7), V(HX, 32.90, HZ + 8.9), C.WHITE, M.SmoothPlastic, 90, "LSPD_HelipadEdgeS", 16, { canCollide = false })
	box(f, "HelipadEdgeW", V(0.7, 0.16, 18.0), V(HX - 11.9, 32.90, HZ), C.WHITE, M.SmoothPlastic, 90, "LSPD_HelipadEdgeW", 16, { canCollide = false })
	box(f, "HelipadEdgeE", V(0.7, 0.16, 18.0), V(HX + 11.9, 32.90, HZ), C.WHITE, M.SmoothPlastic, 90, "LSPD_HelipadEdgeE", 16, { canCollide = false })
	-- vòng tròn đáp (24 đoạn) + vạch chữ H
	for k = 0, 23 do
		local ang = k * math.pi / 12
		box(f, "HelipadRing" .. k, V(1.55, 0.06, 0.62), V(HX + math.cos(ang) * 6.6, DECK + 0.03, HZ + math.sin(ang) * 6.6), C.WHITE, M.SmoothPlastic, 30, "LSPD_HelipadRing" .. tostring(k), 16, { canCollide = false, castShadow = false })
	end
	drawTextFlat(f, "HelipadH", "H", HX, HZ - 4.2, DECK + 0.04, 1.20, C.WHITE, M.SmoothPlastic, 40, "LSPD_HelipadH", 16)
	drawTextFlat(f, "HelipadLSPD", "LSPD", HX, HZ + 5.4, DECK + 0.04, 0.34, C.WHITE, M.SmoothPlastic, 25, "LSPD_HelipadLSPD", 16)
	-- đèn tiếp cận 8 hướng
	for k = 0, 7 do
		local ang = k * math.pi / 4
		box(f, "HelipadLight" .. k, V(0.8, 0.22, 0.8), V(HX + math.cos(ang) * 8.6, DECK + 0.10, HZ + math.sin(ang) * 7.2), C.NEON_B, M.Neon, 20, "LSPD_HelipadLight" .. tostring(k), 17, { canCollide = false, castShadow = false })
	end
	-- lan can an toàn quanh bãi đáp (chừa lối vào phía Nam)
	railingRun(f, "HelipadRailN", "X", HZ - 8.6, HX - 12.0, HX + 12.0, DECK, 3.2, C.STEEL_LT, "LSPD_HelipadRailN", 16, { kick = true })
	railingRun(f, "HelipadRailW", "Z", HX - 12.0, HZ - 8.3, HZ + 8.6, DECK, 3.2, C.STEEL_LT, "LSPD_HelipadRailW", 16, { kick = true })
	railingRun(f, "HelipadRailE", "Z", HX + 12.0, HZ - 8.3, HZ - 1.5, DECK, 3.2, C.STEEL_LT, "LSPD_HelipadRailE", 16, { kick = true })
	railingRun(f, "HelipadRailE2", "Z", HX + 12.0, HZ + 1.5, HZ + 8.6, DECK, 3.2, C.STEEL_LT, "LSPD_HelipadRailE2", 16, { kick = true })
	-- đèn hiệu đỏ / xanh bốn góc sân đáp
	for i, p in ipairs({ { HX - 12.6, HZ - 9.0, "R" }, { HX - 12.6, HZ + 9.0, "R" }, { HX + 12.6, HZ - 9.0, "B" }, { HX + 12.6, HZ + 9.0, "B" } }) do
		local grp = "LSPD_Beacon" .. tostring(i)
		vcyl(f, "BeaconPost" .. i, V(3.4, 0.32, 0.32), V(p[1], 33.34, p[2]), C.STEEL_DK, M.Metal, 60, grp .. "_Post", 16)
		ball(f, "BeaconLamp" .. i, 1.15, V(p[1], 35.25, p[2]), if p[3] == "R" then C.NEON_R else C.NEON_B, M.Neon, 40, grp .. "_Lamp", 17, { castShadow = false })
		box(f, "BeaconHood" .. i, V(1.5, 0.24, 1.5), V(p[1], 35.86, p[2]), C.STEEL_DK, M.Metal, 30, grp .. "_Hood", 17, { canCollide = false })
	end
	-- hộp điều khiển đèn sân đáp + biển HELIPAD
	box(f, "HelipadControl", V(2.4, 3.2, 1.6), V(HX - 10.2, 34.16, HZ + 10.6), C.NAVY, M.Metal, 120, "LSPD_HelipadControl", 15)
	box(f, "HelipadSignPanel", V(9.0, 2.0, 0.22), V(HX + 3.0, 34.4, HZ - 9.6), C.NAVY, M.SmoothPlastic, 110, "LSPD_HelipadSign", 16)
	for i, sx in ipairs({ HX - 1.0, HX + 7.0 }) do
		box(f, "HelipadSignPost" .. i, V(0.34, 1.8, 0.34), V(sx, 33.5, HZ - 9.6), C.STEEL_DK, M.Metal, 60, "LSPD_HelipadSignPost" .. tostring(i), 15)
	end
	drawTextZ(f, "HelipadSignText", "HELIPAD", HX + 3.0, HZ + 7.4, 33.7, 0.2, 0.2, C.NEON_W, M.Neon, 30, "LSPD_HelipadSignText", 17)
	vcyl(f, "WindsockPole", V(9.0, 0.34, 0.34), V(HX + 13.4, 36.5, HZ - 11.0), C.STEEL, M.Metal, 70, "LSPD_WindsockPole", 16)
	for i = 1, 4 do
		box(f, "Windsock" .. i, V(0.9, 0.9, 1.5), V(HX + 13.4 - i * 0.9, 40.6, HZ - 11.0), if i % 2 == 0 then C.WHITE else C.ORANGE, M.Fabric, 20, "LSPD_Windsock" .. tostring(i), 17, { canCollide = false, castShadow = false })
	end

	-- ═══ THIẾT BỊ KỸ THUẬT MÁI ═══
	for i, p in ipairs({ { 240.0, 45.0 }, { 247.5, 45.0 }, { 240.0, 54.0 } }) do
		local grp = "LSPD_ACUnit" .. tostring(i)
		box(f, "ACUnitBody" .. i, V(6.0, 3.6, 5.0), V(p[1], 34.52, p[2]), C.STEEL_LT, M.Metal, 260, grp .. "_Body", 15)
		box(f, "ACUnitPad" .. i, V(6.6, 0.24, 5.6), V(p[1], 32.62, p[2]), C.CONCRETE_DK, M.Concrete, 200, grp .. "_Pad", 14)
		cyl(f, "ACUnitFan" .. i, V(0.22, 4.0, 4.0), CFrame.new(V(p[1], 36.40, p[2])), C.STEEL_DK, M.Metal, 60, grp .. "_Fan", 16, { canCollide = false })
		for k = 1, 3 do
			box(f, "ACUnitFin" .. i .. "_" .. k, V(3.0, 0.14, 5.0), V(p[1] - 1.4, 33.0 + k * 0.9, p[2]), C.STEEL, M.Metal, 30, grp .. "_Fin" .. tostring(k), 16, { canCollide = false, castShadow = false })
		end
	end
	for i, p in ipairs({ { 270.0, 45.0 }, { 276.0, 52.0 } }) do
		vcyl(f, "VentStack" .. i, V(4.0, 1.3, 1.3), V(p[1], 34.5, p[2]), C.STEEL_DK, M.Metal, 90, "LSPD_Vent" .. tostring(i), 15)
		vcyl(f, "VentCap" .. i, V(0.5, 2.0, 2.0), V(p[1], 36.5, p[2]), C.STEEL, M.Metal, 50, "LSPD_VentCap" .. tostring(i), 16)
	end
	-- tháp nước + cột ăng-ten + chảo vệ tinh
	box(f, "WaterTankBase", V(7.0, 0.5, 7.0), V(272.0, 32.79, 62.0), C.CONCRETE_DK, M.Concrete, 240, "LSPD_WaterTankBase", 14)
	vcyl(f, "WaterTank", V(9.0, 6.2, 6.2), V(272.0, 37.5, 62.0), C.STONE_LT, M.Metal, 320, "LSPD_WaterTank", 15)
	vcyl(f, "WaterTankTop", V(1.2, 6.4, 6.4), V(272.0, 42.3, 62.0), C.STEEL, M.Metal, 90, "LSPD_WaterTankTop", 16)
	for i, lx in ipairs({ -2.2, 2.2 }) do
		for j, lz in ipairs({ -2.2, 2.2 }) do
			strut(f, "TankLeg" .. i .. "_" .. j, V(272.0 + lx, 32.6, 62.0 + lz), V(272.0 + lx * 0.75, 34.0, 62.0 + lz * 0.75), 0.34, C.STEEL_DK, M.Metal, 70, string.format("LSPD_TankLeg%d_%d", i, j), 15, { canCollide = false })
		end
	end
	vcyl(f, "AntennaMast", V(16.0, 0.5, 0.5), V(236.0, 40.5, 60.0), C.STEEL, M.Metal, 220, "LSPD_Antenna", 15)
	for i = 1, 3 do
		strut(f, "AntennaGuy" .. i, V(236.0, 45.0, 60.0), V(236.0 + math.cos(i * 2.1) * 4.0, 32.6, 60.0 + math.sin(i * 2.1) * 4.0), 0.12, C.STEEL_DK, M.Metal, 30, "LSPD_AntennaGuy" .. tostring(i), 15, { canCollide = false })
	end
	ball(f, "AntennaLight", 0.7, V(236.0, 48.7, 60.0), C.NEON_R, M.Neon, 20, "LSPD_AntennaLight", 16, { canCollide = false, castShadow = false })
	cyl(f, "SatDish", V(0.5, 4.4, 4.4), CFrame.new(V(278.0, 35.6, 26.0)) * CFrame.Angles(0, 0, math.rad(38)), C.STONE_LT, M.Metal, 90, "LSPD_SatDish", 16)
	strut(f, "SatDishArm", V(278.0, 32.6, 26.0), V(278.0, 34.4, 26.0), 0.35, C.STEEL_DK, M.Metal, 50, "LSPD_SatDishArm", 15)
	-- giếng trời kính trên sảnh
	box(f, "Skylight", V(12.0, 0.36, 8.0), V(258.0, 32.72, 54.0), C.GLASS, M.Glass, 90, "LSPD_Skylight", 15, { transparency = 0.5, reflectance = 0.2 })
	for i = 0, 4 do
		box(f, "SkylightBar" .. i, V(12.4, 0.20, 0.28), V(258.0, 32.92, 50.2 + i * 1.9), C.STEEL_DK, M.Metal, 40, "LSPD_SkylightBar" .. tostring(i), 16, { canCollide = false })
	end
	-- 4 đèn pha trên lan can mái
	for i, p in ipairs({ { 235.0, 40.0 }, { 279.0, 40.0 }, { 235.0, 60.0 }, { 279.0, 60.0 } }) do
		box(f, "FloodBase" .. i, V(0.5, 1.4, 0.5), V(p[1], 35.2, p[2]), C.STEEL_DK, M.Metal, 50, "LSPD_FloodBase" .. tostring(i), 16)
		box(f, "FloodHead" .. i, V(1.8, 1.0, 1.2), V(p[1], 36.2, p[2]), C.STEEL_DK, M.Metal, 60, "LSPD_FloodHead" .. tostring(i), 17)
		box(f, "FloodLens" .. i, V(1.5, 0.7, 0.22), V(p[1], 36.2, p[2] + 0.65), C.NEON_W, M.Neon, 25, "LSPD_FloodLens" .. tostring(i), 17, { canCollide = false, castShadow = false })
	end
	-- thang sắt lên đỉnh buồng thang (bảo trì)
	for i = 1, 8 do
		box(f, "PentLadderRung" .. i, V(2.2, 0.14, 0.16), V(264.9, 32.54 + i * 1.0, 32.0), C.STEEL_DK, M.Metal, 20, "LSPD_PentRung" .. tostring(i), 18, { canCollide = false })
	end
	strut(f, "PentLadderR1", V(264.9, 32.6, 31.3), V(264.9, 41.0, 31.3), 0.14, C.STEEL_DK, M.Metal, 30, "LSPD_PentLadderR1", 18, { canCollide = false })
	strut(f, "PentLadderR2", V(264.9, 32.6, 32.7), V(264.9, 41.0, 32.7), 0.14, C.STEEL_DK, M.Metal, 30, "LSPD_PentLadderR2", 18, { canCollide = false })
	-- ống thông hơi nhỏ + nắp ga kỹ thuật
	for i = 1, 5 do
		vcyl(f, "RoofPipe" .. i, V(1.4, 0.5, 0.5), V(266.0 + i * 1.2, 33.2, 8.0 + i * 1.6), C.STEEL, M.Metal, 40, "LSPD_RoofPipe" .. tostring(i), 15)
	end
	for i = 1, 3 do
		box(f, "RoofHatch" .. i, V(2.4, 0.14, 2.4), V(244.0 + i * 9.0, 32.60, 66.0), C.STEEL_DK, M.Metal, 60, "LSPD_RoofHatch" .. tostring(i), 15, { canCollide = false })
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 12. ĐIỂM VÀO MODULE — Master gọi Module.build(container)
-- ═══════════════════════════════════════════════════════════════════════════
function Module.build(container: Instance): Folder
	local root = folder(container, "LSPD_MissionRow")
	buildSite(root)
	buildShell(root)
	buildFacade(root)
	buildGroundFloor(root)
	buildLobbyAndGarage(root)
	buildUpperFloor(root)
	buildRoof(root)
	local count = applyPerfPass(root)
	root:SetAttribute("ModuleId", Module.Id)
	root:SetAttribute("PlotId", Module.PlotId)
	root:SetAttribute("PartCount", count)
	root:SetAttribute("GroundY", GROUND)
	root:SetAttribute("MainGateX", 255.0)
	root:SetAttribute("MainGateZ", 69.4)
	root:SetAttribute("SallyPortZ", 29.0)
	root:SetAttribute("PoliceParkingX0", PARK_X0)
	root:SetAttribute("PoliceParkingX1", PARK_X1)
	root:SetAttribute("PoliceParkingZ0", PARK_Z0)
	root:SetAttribute("PoliceParkingZ1", PARK_Z1)
	return root
end

return Module
