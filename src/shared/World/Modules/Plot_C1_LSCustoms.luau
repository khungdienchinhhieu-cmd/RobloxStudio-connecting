--!strict
--[[
	Plot_C1_LSCustoms.luau
	================================================================================
	LOS SANTOS CUSTOMS — Garage Độ Xe & Performance (GTA V) — Ô đất Plot_C1 (DEL PERRO)
	Agent Phụ: arena/e461e643-robloxstudio-connecting  •  Task: AGENT_1_LS_CUSTOMS
	================================================================================
	Toạ độ ô đất : X ∈ [-299 .. -137] | Z ∈ [-9 .. 123] | Nền Y = 1.15 (mặt pad kỹ thuật 1.20)
	Mặt tiền    : Nam (+Z) nhìn thẳng ra Vespucci Blvd
	Cổng xe vào : Z = +120, X ∈ [-268 .. -208] (2 khoang cửa cuốn 20.5 × 13.5 studs)
	Cửa đi bộ   : (X ≈ -206.5, Z = 51.0) cao 9.5 studs  •  Cửa hông EXIT: (X ≈ -200, Z = -8.5)

	QUY TẮC ĐÃ TUÂN THỦ:
	• 100% khối nằm trong Buildable Bounds của Plot_C1.
	• Sàn lát riêng đặt mặt trên Y = 1.30 (không trùng phẳng 1.15/1.20 -> 0 Z-fighting).
	• Mọi viên gạch / ô kính / biển hiệu / đồ nội thất đều ghép từ khối rời và gắn máu ẩn
	  (PartHealth / MaxPartHealth / StructuralRow / FractureGroup) để xe tông hoặc súng bắn
	  hết máu là tự vỡ vụn, sập dây chuyền.
	• Chỉ dùng API công khai của PartBuilder: part / wedge / masonryWall / staircase / bollardLine.
	  (Các shim cục bộ `box`, `segmentedRow`, `brickWall` bên dưới gói lại PartBuilder.part +
	  PartBuilder.masonryWall đúng như hợp đồng MULTI_AGENT_SYSTEM.md yêu cầu.)
	• KHÔNG sửa bất kỳ file lõi nào và KHÔNG chạm studio-sync.json.
	================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartBuilder = require(Shared:WaitForChild("World"):WaitForChild("PartBuilder"))

local Module = {
	Id = "Plot_C1_LSCustoms",
	PlotId = "Plot_C1",
	Order = 20,
	Enabled = true,
}

-- =============================================================================
-- 0. HẰNG SỐ TOẠ ĐỘ (KHỚP 100% VỚI WorldGrid + AGENT_TASK_BOARD)
-- =============================================================================
local GROUND_Y = 1.15 -- cao độ vỉa hè / pad gốc
local PAD_TOP = 1.20 -- mặt trên tấm EngineeredFoundationPad có sẵn của CityFoundation
local FLOOR_TOP = 1.30 -- mặt sàn lát riêng của công trình (né Z-fighting tuyệt đối)

-- Ranh giới xây lõi Plot_C1
local BOUND_MIN_X, BOUND_MAX_X = -299.0, -137.0
local BOUND_MIN_Z, BOUND_MAX_Z = -9.0, 123.0

-- Vỏ nhà chính
local BX0, BX1 = -271.5, -164.5 -- 107 studs rộng
local BZ0, BZ1 = -8.3, 51.0 -- 59.5 studs sâu, mặt tiền ở Z = 51.0
local WT = 1.2 -- dày tường ngoài

local FACADE_TOP = 26.90
local CEIL_Y = 23.30 -- trần trong nhà cao 22 studs
local ROOF_TOP = 24.10
local PARAPET_TOP = 26.90

local IN_X0, IN_X1 = BX0 + WT, BX1 - WT -- -270.3 .. -165.7
local IN_Z0, IN_Z1 = BZ0 + WT, BZ1 - WT -- -7.3 .. 49.8

local FRONT_ZC = BZ1 - WT * 0.5 -- 50.4
local BACK_ZC = BZ0 + WT * 0.5 -- -7.9
local WEST_XC = BX0 + WT * 0.5 -- -270.9
local EAST_XC = BX1 - WT * 0.5 -- -165.1

-- Mặt tiền chia nhịp (X)
local P1A, P1B = -271.5, -266.5 -- trụ góc Tây
local BAY1A, BAY1B = -266.5, -246.0 -- khoang cửa cuốn 1 (rộng 20.5)
local P2A, P2B = -246.0, -241.0 -- trụ giữa
local BAY2A, BAY2B = -241.0, -220.5 -- khoang cửa cuốn 2 (rộng 20.5)
local P3A, P3B = -220.5, -215.5 -- trụ Đông
local SHOWA, SHOWB = -215.5, -176.5 -- khu showroom / lối vào khách (39 wide)
local P4A, P4B = -176.5, -164.5 -- trụ góc Đông

local BAY_HEAD_Y = 14.80 -- đỉnh thông thuỷ 2 khoang cửa cuốn (cao 13.5)
local SHOW_KICK_Y = 3.40 -- chân tường ốp kim loại dưới kính
local SHOW_HEAD_Y = 12.80 -- đỉnh vách kính showroom
local DOOR_A, DOOR_B = -209.5, -203.5 -- cửa đôi đi bộ rộng 6, cao 9.5
local DOOR_TOP = 10.80

-- Khu nội thất
local LIFT1_X, LIFT1_Z = -256.25, 24.0
local LIFT2_X, LIFT2_Z = -230.75, 27.0
local MEZZ_TOP = 15.55 -- mặt trên sàn mezzanine
local MEZZ_BOT = 15.00
local MEZZ_X0, MEZZ_X1 = IN_X0, -190.0
local MEZZ_Z0, MEZZ_Z1 = IN_Z0, 12.0

-- Sân trước (forecourt)
local FC_X0, FC_X1 = -297.5, -139.5
local FC_Z0, FC_Z1 = 51.2, 120.5
local FC_TOP = 1.28

-- =============================================================================
-- 1. BẢNG MÀU / VẬT LIỆU CHUẨN GTA V
-- =============================================================================
local M = Enum.Material

local C = {
	BRICK = Color3.fromRGB(154, 108, 88),
	BRICK_DARK = Color3.fromRGB(104, 72, 62),
	CONCRETE = Color3.fromRGB(158, 156, 150),
	CONCRETE_DARK = Color3.fromRGB(112, 112, 110),
	ASPHALT = Color3.fromRGB(58, 60, 64),
	STEEL = Color3.fromRGB(104, 110, 120),
	DARK_STEEL = Color3.fromRGB(52, 56, 64),
	GALV = Color3.fromRGB(176, 180, 186),
	LSC_BLUE = Color3.fromRGB(26, 62, 96),
	LSC_BLUE_LIGHT = Color3.fromRGB(40, 92, 138),
	NEON_YELLOW = Color3.fromRGB(255, 214, 66),
	NEON_ORANGE = Color3.fromRGB(255, 126, 32),
	NEON_WHITE = Color3.fromRGB(238, 246, 255),
	NEON_RED = Color3.fromRGB(255, 62, 48),
	NEON_GREEN = Color3.fromRGB(64, 255, 150),
	RED = Color3.fromRGB(178, 40, 36),
	RED_DARK = Color3.fromRGB(126, 28, 26),
	YELLOW = Color3.fromRGB(238, 190, 42),
	WHITE = Color3.fromRGB(238, 238, 232),
	BLACK = Color3.fromRGB(28, 30, 34),
	TIRE = Color3.fromRGB(36, 36, 40),
	CHROME = Color3.fromRGB(198, 204, 212),
	GLASS = Color3.fromRGB(150, 200, 216),
	GLASS_BLUE = Color3.fromRGB(104, 158, 190),
	WOOD = Color3.fromRGB(146, 104, 66),
	LEATHER = Color3.fromRGB(48, 50, 56),
	GRANITE = Color3.fromRGB(74, 78, 86),
	OIL = Color3.fromRGB(26, 24, 26),
	ORANGE_TOOL = Color3.fromRGB(214, 96, 30),
	GREEN_DRUM = Color3.fromRGB(58, 96, 66),
	BLUE_DRUM = Color3.fromRGB(38, 74, 140),
}

-- Màu sơn xe trưng bày / vỏ đồ nghề
local TOOL_RED = Color3.fromRGB(168, 32, 30)

-- =============================================================================
-- 2. SHIM DỰNG KHỐI (BẮT BUỘC ĐI QUA PartBuilder ĐỂ GẮN MÁU ẨN)
-- =============================================================================
local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- `box`  : 1 khối hộp có máu ẩn (PartBuilder.part)
-- `rbox` : khối hộp xoay theo CFrame
-- `segmentedRow` : hàng khối rời cùng fractureGroup (tường kính, lam che nắng, slat cửa cuốn)
-- `brickWall`    : mảng gạch ghép so le (PartBuilder.masonryWall)
local function mergeOpts(spec: { [string]: any }, opts: { [string]: any }?)
	if opts then
		for k, v in pairs(opts) do
			spec[k] = v
		end
	end
	return spec
end

local function box(
	parent: Instance,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material,
	integrity: number?,
	group: string?,
	row: number?,
	opts: { [string]: any }?
): Part
	local spec: { [string]: any } = {
		name = name,
		parent = parent,
		size = size,
		pos = pos,
		color = color,
		material = material,
		destructible = integrity ~= nil,
		integrity = integrity,
		fractureGroup = group,
		structuralRow = row,
	}
	mergeOpts(spec, opts)
	return PartBuilder.part(spec :: any)
end

local function rbox(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	integrity: number?,
	group: string?,
	row: number?,
	opts: { [string]: any }?
): Part
	local spec: { [string]: any } = {
		name = name,
		parent = parent,
		size = size,
		cframe = cf,
		color = color,
		material = material,
		destructible = integrity ~= nil,
		integrity = integrity,
		fractureGroup = group,
		structuralRow = row,
	}
	mergeOpts(spec, opts)
	return PartBuilder.part(spec :: any)
end

local function cyl(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	integrity: number?,
	group: string?,
	row: number?,
	opts: { [string]: any }?
): Part
	local spec: { [string]: any } = {
		name = name,
		parent = parent,
		size = size,
		cframe = cf,
		color = color,
		material = material,
		shape = Enum.PartType.Cylinder,
		destructible = integrity ~= nil,
		integrity = integrity,
		fractureGroup = group,
		structuralRow = row,
	}
	mergeOpts(spec, opts)
	return PartBuilder.part(spec :: any)
end

-- Trụ tròn DỰNG ĐỨNG (axis Y) — Part.Shape Cylinder mặc định nằm ngang theo trục X
local function vcyl(
	parent: Instance,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material,
	integrity: number?,
	group: string?,
	row: number?,
	opts: { [string]: any }?
): Part
	return cyl(parent, name, size, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material, integrity, group, row, opts)
end

local function ball(
	parent: Instance,
	name: string,
	diameter: number,
	pos: Vector3,
	color: Color3,
	material: Enum.Material,
	integrity: number?,
	group: string?,
	row: number?
): Part
	return PartBuilder.part({
		name = name,
		parent = parent,
		size = Vector3.new(diameter, diameter, diameter),
		pos = pos,
		color = color,
		material = material,
		shape = Enum.PartType.Ball,
		destructible = integrity ~= nil,
		integrity = integrity,
		fractureGroup = group,
		structuralRow = row,
	})
end

-- Mảng gạch ghép so le (Running-Bond) — mỗi viên là 1 khối vật lý có máu ẩn riêng
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
	group: string
)
	if c1 - c0 < 0.5 or height < 0.4 then
		return
	end
	local courses = math.max(1, math.round(height / 1.9))
	local ch = height / courses
	local blockLen = if height >= 14 then 4.6 elseif height >= 6 then 4.2 else 3.4
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
		blockLength = blockLen,
		mortarGap = 0.09,
		baseColor = color,
		material = M.Brick,
		colorJitter = 9,
		integrity = hp,
		fractureGroup = group,
	})
end

-- Tường có khoét lỗ (cửa/cửa sổ): tự chia dải ngang + dải đứng, chỉ dùng khối gạch rời
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
	openings: { { a: number, b: number, y0: number, y1: number } }
)
	local ys: { number } = { baseY, topY }
	for _, o in ipairs(openings) do
		table.insert(ys, math.clamp(o.y0, baseY, topY))
		table.insert(ys, math.clamp(o.y1, baseY, topY))
	end
	table.sort(ys)
	local bands: { { number } } = {}
	for i = 1, #ys - 1 do
		if ys[i + 1] - ys[i] > 0.08 then
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
					group
				)
			end
		end
	end
end

-- Hàng khối rời dùng chung 1 FractureGroup (kính, lam, slat) -> vỡ từng ô
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
	material: Enum.Material,
	hp: number,
	group: string,
	row: number,
	opts: { [string]: any }?
)
	local cursor = c0
	local idx = 1
	while cursor < c1 - 0.05 do
		local segEnd = math.min(c1, cursor + segLen)
		local ln = segEnd - cursor - 0.06
		if ln > 0.1 then
			local mid = (cursor + segEnd) * 0.5
			local pos = if axis == "X"
				then Vector3.new(mid, centerY, fixed)
				else Vector3.new(fixed, centerY, mid)
			local size = if axis == "X"
				then Vector3.new(ln, height, thickness)
				else Vector3.new(thickness, height, ln)
			box(parent, string.format("%s_%d", name, idx), size, pos, color, material, hp, group, row, opts)
		end
		cursor = segEnd
		idx += 1
	end
end

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
	local size = if axis == "X"
		then Vector3.new(c1 - c0, y1 - y0, 0.22)
		else Vector3.new(0.22, y1 - y0, c1 - c0)
	local pos = if axis == "X"
		then Vector3.new((c0 + c1) * 0.5, (y0 + y1) * 0.5, fixed)
		else Vector3.new(fixed, (y0 + y1) * 0.5, (c0 + c1) * 0.5)
	box(parent, name, size, pos, tint or C.GLASS, M.Glass, hp, group, row, {
		transparency = 0.55,
		reflectance = 0.22,
		castShadow = false,
	})
end

-- =============================================================================
-- 3. BỘ CHỮ NỔI 3D (NEON LETTERING) — font 5x7, gộp pixel theo hàng
-- =============================================================================
local FONT5X7: { [string]: { string } } = {
	A = { "01110", "10001", "10001", "11111", "10001", "10001", "10001" },
	B = { "11110", "10001", "10001", "11110", "10001", "10001", "11110" },
	C = { "01110", "10001", "10000", "10000", "10000", "10001", "01110" },
	D = { "11110", "10001", "10001", "10001", "10001", "10001", "11110" },
	E = { "11111", "10000", "10000", "11110", "10000", "10000", "11111" },
	F = { "11111", "10000", "10000", "11110", "10000", "10000", "10000" },
	G = { "01110", "10001", "10000", "10111", "10001", "10001", "01110" },
	H = { "10001", "10001", "10001", "11111", "10001", "10001", "10001" },
	I = { "11111", "00100", "00100", "00100", "00100", "00100", "11111" },
	K = { "10001", "10010", "10100", "11000", "10100", "10010", "10001" },
	L = { "10000", "10000", "10000", "10000", "10000", "10000", "11111" },
	M = { "10001", "11011", "10101", "10101", "10001", "10001", "10001" },
	N = { "10001", "11001", "10101", "10011", "10001", "10001", "10001" },
	O = { "01110", "10001", "10001", "10001", "10001", "10001", "01110" },
	P = { "11110", "10001", "10001", "11110", "10000", "10000", "10000" },
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
	[" "] = { "00000", "00000", "00000", "00000", "00000", "00000", "00000" },
}

local LETTER_ADVANCE = 7 -- 5 cột glyph + 1 cột đệm + 1 cột rời chữ kế tiếp

local function textWidth(text: string, pixel: number): number
	return math.max(0, #text * LETTER_ADVANCE * pixel - 2 * pixel)
end

-- Vẽ chữ nổi 3D. leftX = mép trái, bottomY = mép dưới, axis="X" -> chữ nằm trên mặt phẳng Z
local function drawText(
	parent: Instance,
	name: string,
	text: string,
	leftX: number,
	bottomY: number,
	planeZ: number,
	depth: number,
	pixel: number,
	color: Color3,
	material: Enum.Material,
	hp: number?,
	group: string?,
	row: number?,
	opts: { [string]: any }?
): number
	local upper = string.upper(text)
	local cursorPx = 0
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
						local w = runLen * pixel - 0.08
						local h = pixel - 0.08
						local cx = leftX + (cursorPx + runStart - 1) * pixel + (runLen * pixel) * 0.5
						local cy = bottomY + ((7 - r) * pixel) + pixel * 0.5
						box(
							parent,
							string.format("%s_%s_%d_%d", name, ch, r, runStart),
							Vector3.new(w, h, depth),
							Vector3.new(cx, cy, planeZ),
							color,
							material,
							hp,
							group,
							row,
							mergeOpts({ canCollide = false, castShadow = false }, opts)
						)
					else
						col += 1
					end
				end
			end
			cursorPx += LETTER_ADVANCE
		else
			cursorPx += LETTER_ADVANCE
		end
	end
	return cursorPx * pixel - 2 * pixel
end

-- Chữ nổi trên mặt phẳng X (tường hướng Đông/Tây): chạy dọc trục Z
local function drawTextZ(
	parent: Instance,
	name: string,
	text: string,
	planeX: number,
	topZ: number,
	bottomY: number,
	depth: number,
	pixel: number,
	color: Color3,
	material: Enum.Material,
	hp: number?,
	group: string?,
	row: number?
)
	local upper = string.upper(text)
	local cursorPx = 0
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
						local w = runLen * pixel - 0.08
						local h = pixel - 0.08
						local cz = topZ - (cursorPx + runStart - 1) * pixel - (runLen * pixel) * 0.5
						local cy = bottomY + ((7 - r) * pixel) + pixel * 0.5
						box(
							parent,
							string.format("%s_%s_%d_%d", name, ch, r, runStart),
							Vector3.new(depth, h, w),
							Vector3.new(planeX, cy, cz),
							color,
							material,
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
			cursorPx += LETTER_ADVANCE
		else
			cursorPx += LETTER_ADVANCE
		end
	end
	return cursorPx * pixel - 2 * pixel
end

-- Chữ nổi nằm PHẲNG trên mặt sàn (XZ plane) — dùng cho số khoang / chữ sơn nền
local function drawTextFlat(
	parent: Instance,
	name: string,
	text: string,
	centerX: number,
	topZ: number,
	topY: number,
	pixel: number,
	color: Color3,
	material: Enum.Material,
	hp: number?,
	group: string?,
	row: number?
)
	local upper = string.upper(text)
	local totalW = textWidth(upper, pixel)
	local leftX = centerX - totalW * 0.5
	local cursorPx = 0
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
						local w = runLen * pixel - 0.1
						local d = pixel - 0.1
						local cx = leftX + (cursorPx + runStart - 1) * pixel + (runLen * pixel) * 0.5
						local cz = topZ + (r - 0.5) * pixel
						box(
							parent,
							string.format("%s_%s_%d_%d", name, ch, r, runStart),
							Vector3.new(w, 0.04, d),
							Vector3.new(cx, topY, cz),
							color,
							material,
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
			cursorPx += LETTER_ADVANCE
		else
			cursorPx += LETTER_ADVANCE
		end
	end
	return totalW
end

-- Thanh nối 2 điểm bất kỳ (ty giằng, lan can, ống, dây điện, tay đòn cầu nâng)
local function strut(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	thick: number,
	color: Color3,
	material: Enum.Material,
	hp: number?,
	group: string?,
	row: number?,
	opts: { [string]: any }?
): Part
	local d = b - a
	local len = d.Magnitude
	local mid = (a + b) * 0.5
	local yaw = math.atan2(d.X, d.Z)
	local flat = math.sqrt(d.X * d.X + d.Z * d.Z)
	local pitch = math.atan2(flat, d.Y)
	local cf = CFrame.new(mid) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	return rbox(parent, name, Vector3.new(thick, len, thick), cf, color, material, hp, group, row, opts)
end

local function jitter(base: Color3, seed: number, amount: number): Color3
	local n = ((seed * 37) % 11) - 5
	local d = (n / 5) * (amount / 255)
	return Color3.new(
		math.clamp(base.R + d, 0, 1),
		math.clamp(base.G + d, 0, 1),
		math.clamp(base.B + d * 0.9, 0, 1)
	)
end

-- =============================================================================
-- 4. TIỆN ÍCH ĐỒ NGHỀ (BÁNH XE, THÙNG PHUY, KỆ, ĐÈN TUÝP...)
-- =============================================================================
local function tire(parent: Instance, name: string, pos: Vector3, diameter: number, width: number, lying: boolean, group: string, hp: number?)
	local cf = if lying
		then CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
		else CFrame.new(pos) * CFrame.Angles(math.rad(90), 0, math.rad(90))
	cyl(parent, name .. "_Rubber", Vector3.new(width, diameter, diameter), cf, C.TIRE, M.Rubber, hp, group, 1)
	cyl(
		parent,
		name .. "_Rim",
		Vector3.new(width * 1.02, diameter * 0.58, diameter * 0.58),
		cf,
		C.CHROME,
		M.Metal,
		hp,
		group,
		1,
		{ reflectance = 0.25 }
	)
	cyl(
		parent,
		name .. "_Hub",
		Vector3.new(width * 1.1, diameter * 0.2, diameter * 0.2),
		cf,
		C.DARK_STEEL,
		M.Metal,
		hp,
		group,
		1
	)
end

local function oilDrum(parent: Instance, name: string, pos: Vector3, color: Color3, group: string, hp: number?, lying: boolean?)
	if lying then
		-- Thùng nằm ngang (trục Z)
		local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0)
		cyl(parent, name .. "_Body", Vector3.new(3.4, 2.3, 2.3), cf, color, M.Metal, hp, group, 1, { reflectance = 0.05 })
		for i, dz in ipairs({ -0.75, 0.75 }) do
			cyl(parent, name .. "_Rib" .. tostring(i), Vector3.new(0.24, 2.42, 2.42), CFrame.new(pos.X, pos.Y, pos.Z + dz) * CFrame.Angles(0, math.rad(90), 0), C.CHROME, M.Metal, hp, group, 2)
		end
		cyl(parent, name .. "_Lid", Vector3.new(0.12, 2.16, 2.16), CFrame.new(pos.X, pos.Y, pos.Z + 1.72) * CFrame.Angles(0, math.rad(90), 0), C.DARK_STEEL, M.Metal, hp, group, 2)
	else
		-- Thùng dựng đứng (trục Y)
		vcyl(parent, name .. "_Body", Vector3.new(3.4, 2.3, 2.3), pos, color, M.Metal, hp, group, 1, { reflectance = 0.05 })
		for i, dy in ipairs({ -0.75, 0.75 }) do
			vcyl(parent, name .. "_Rib" .. tostring(i), Vector3.new(0.24, 2.42, 2.42), Vector3.new(pos.X, pos.Y + dy, pos.Z), C.CHROME, M.Metal, hp, group, 2)
		end
		vcyl(parent, name .. "_Lid", Vector3.new(0.12, 2.16, 2.16), Vector3.new(pos.X, pos.Y + 1.72, pos.Z), C.DARK_STEEL, M.Metal, hp, group, 2)
		vcyl(parent, name .. "_Spout", Vector3.new(0.5, 0.55, 0.55), Vector3.new(pos.X + 0.8, pos.Y + 1.78, pos.Z), C.DARK_STEEL, M.Metal, hp, group, 3)
	end
end

local function tireStack(parent: Instance, name: string, basePos: Vector3, count: number, group: string, hp: number)
	for i = 1, count do
		tire(
			parent,
			string.format("%s_%d", name, i),
			Vector3.new(basePos.X, basePos.Y + (i - 0.5) * 0.95, basePos.Z),
			2.7,
			0.92,
			true,
			group .. "_" .. tostring(i),
			hp
		)
	end
end

local function trafficCone(parent: Instance, name: string, pos: Vector3, group: string)
	box(parent, name .. "_Base", Vector3.new(2.0, 0.24, 2.0), pos + Vector3.new(0, 0.12, 0), C.ORANGE_TOOL, M.SmoothPlastic, 25, group, 1)
	box(parent, name .. "_Cone", Vector3.new(1.0, 2.6, 1.0), pos + Vector3.new(0, 1.5, 0), C.ORANGE_TOOL, M.SmoothPlastic, 25, group, 2)
	box(parent, name .. "_Band", Vector3.new(1.06, 0.45, 1.06), pos + Vector3.new(0, 1.9, 0), C.WHITE, M.SmoothPlastic, 20, group, 3, { canCollide = false })
end

local function stripLight(parent: Instance, name: string, pos: Vector3, alongZ: boolean, length: number, group: string)
	local housing = if alongZ then Vector3.new(1.6, 0.42, length) else Vector3.new(length, 0.42, 1.6)
	local tube = if alongZ then Vector3.new(1.05, 0.34, length - 1.2) else Vector3.new(length - 1.2, 0.34, 1.05)
	box(parent, name .. "_Housing", housing, pos, C.GALV, M.Metal, 55, group, 3, { canCollide = false })
	box(parent, name .. "_Tube", tube, pos + Vector3.new(0, -0.3, 0), C.NEON_WHITE, M.Neon, 30, group, 4, {
		canCollide = false,
		castShadow = false,
	})
	-- dây treo
	for _, off in ipairs({ -1, 1 }) do
		local d = if alongZ then Vector3.new(0, 0, off * (length * 0.4)) else Vector3.new(off * (length * 0.4), 0, 0)
		box(parent, name .. "_Wire" .. tostring(off), Vector3.new(0.1, 1.1, 0.1), pos + d + Vector3.new(0, 0.7, 0), C.DARK_STEEL, M.Metal, nil, group, nil, { canCollide = false })
	end
end

-- =============================================================================
-- 5. NỀN / SÀN LÁT RIÊNG (mặt trên Y = 1.30 — không trùng phẳng 1.15)
-- =============================================================================
local function buildFloor(root: Instance)
	local f = folder("00_FloorAndMarkings", root)

	-- Tấm sàn bê tông đánh bóng trong nhà (kết cấu chịu lực -> không gắn máu ẩn)
	box(
		f,
		"WorkshopFloorSlab",
		Vector3.new(BX1 - BX0 + 0.2, 0.22, BZ1 - BZ0 + 0.2),
		Vector3.new((BX0 + BX1) * 0.5, FLOOR_TOP - 0.11, (BZ0 + BZ1) * 0.5),
		C.CONCRETE_DARK,
		M.Concrete,
		nil,
		nil,
		nil,
		{ castShadow = false }
	)

	-- Sàn epoxy xanh xám 2 khoang sửa chữa (nổi 0.02 studs, né Z-fighting)
	for i, bay in ipairs({ { BAY1A, BAY1B }, { BAY2A, BAY2B } }) do
		box(
			f,
			"EpoxyBayFloor" .. tostring(i),
			Vector3.new(bay[2] - bay[1] - 1.0, 0.04, 52.0),
			Vector3.new((bay[1] + bay[2]) * 0.5, FLOOR_TOP + 0.02, 23.5),
			Color3.fromRGB(92, 104, 116),
			M.SmoothPlastic,
			260,
			"LSC_FloorEpoxy" .. tostring(i),
			1,
			{ castShadow = false }
		)
	end

	-- Vạch sơn an toàn vàng quanh 2 cầu nâng + lối đi bộ
	local safety = folder("FloorSafetyLines", f)
	local function stripe(name: string, size: Vector3, pos: Vector3, color: Color3, grp: string)
		box(safety, name, size, Vector3.new(pos.X, FLOOR_TOP + 0.05, pos.Z), color, M.SmoothPlastic, 40, grp, 1, {
			canCollide = false,
			castShadow = false,
		})
	end
	for _, lift in ipairs({ { LIFT1_X, LIFT1_Z }, { LIFT2_X, LIFT2_Z } }) do
		local x, z = lift[1], lift[2]
		local tag = string.format("LiftMark_%d", math.floor(math.abs(x)))
		stripe(tag .. "_N", Vector3.new(17.0, 0.05, 0.55), Vector3.new(x, 0, z - 7.0), C.YELLOW, tag)
		stripe(tag .. "_S", Vector3.new(17.0, 0.05, 0.55), Vector3.new(x, 0, z + 7.0), C.YELLOW, tag)
		stripe(tag .. "_W", Vector3.new(0.55, 0.05, 14.5), Vector3.new(x - 8.2, 0, z), C.YELLOW, tag)
		stripe(tag .. "_E", Vector3.new(0.55, 0.05, 14.5), Vector3.new(x + 8.2, 0, z), C.YELLOW, tag)
		-- Số khoang sơn phẳng trên sàn
		local idx = if x == LIFT1_X then "1" else "2"
		drawTextFlat(safety, "BayNumber_" .. idx, idx, x, 44.0, FLOOR_TOP + 0.07, 2.4, C.YELLOW, M.SmoothPlastic, 22, "BayNumber" .. idx, 1)
	end

	-- Đường tim xe chạy vào từ cổng tới 2 cầu nâng
	for i, cx in ipairs({ LIFT1_X, LIFT2_X }) do
		local grp = "DriveLane" .. tostring(i)
		local z = 51.0
		while z < 118.0 do
			box(
				safety,
				string.format("LaneDash_%d_%d", i, math.floor(z)),
				Vector3.new(0.5, 0.05, 3.2),
				Vector3.new(cx, FC_TOP + 0.03, z),
				C.YELLOW,
				M.SmoothPlastic,
				30,
				grp,
				1,
				{ canCollide = false, castShadow = false }
			)
			z += 6.4
		end
	end

	-- Vết dầu loang & vũng nước (decal mỏng, bắn vỡ được như sàn bẩn)
	local stains = { { -258.0, 31.0, 5.2 }, { -232.5, 20.0, 4.4 }, { -250.0, 39.0, 3.6 }, { -243.0, 12.5, 3.0 } }
	for i, s in ipairs(stains) do
		box(
			f,
			"OilStain" .. tostring(i),
			Vector3.new(s[3], 0.03, s[3] * 0.72),
			Vector3.new(s[1], FLOOR_TOP + 0.055, s[2]),
			C.OIL,
			M.Slate,
			15,
			"OilStain" .. tostring(i),
			1,
			{ canCollide = false, castShadow = false, transparency = 0.25 }
		)
	end

	-- Hố thu nước + nắp gang 2 khoang
	for i, cx in ipairs({ LIFT1_X, LIFT2_X }) do
		box(f, "FloorDrain_" .. tostring(i), Vector3.new(2.4, 0.1, 2.4), Vector3.new(cx, FLOOR_TOP + 0.02, 40.0), C.DARK_STEEL, M.DiamondPlate, 60, "FloorDrain" .. tostring(i), 1, { castShadow = false })
		box(f, "DrainCover_" .. tostring(i), Vector3.new(2.0, 0.12, 2.0), Vector3.new(cx, FLOOR_TOP + 0.06, 40.0), C.STEEL, M.DiamondPlate, 45, "FloorDrain" .. tostring(i), 2)
	end
end

-- =============================================================================
-- 6. KẾT CẤU VỎ NHÀ: TƯỜNG GẠCH GHÉP KHỐI QUANH 4 MẶT
-- =============================================================================
local function buildShell(root: Instance)
	local f = folder("01_BuildingShell", root)

	-- ---------- MẶT TIỀN NAM (+Z) ----------
	wallWithOpenings(
		f,
		"SouthFacade",
		"X",
		FRONT_ZC,
		BX0,
		BX1,
		FLOOR_TOP,
		FACADE_TOP,
		WT,
		C.BRICK,
		175,
		"LSC_SouthFacade",
		{
			{ a = BAY1A, b = BAY1B, y0 = FLOOR_TOP, y1 = BAY_HEAD_Y },
			{ a = BAY2A, b = BAY2B, y0 = FLOOR_TOP, y1 = BAY_HEAD_Y },
			{ a = SHOWA, b = SHOWB, y0 = FLOOR_TOP, y1 = SHOW_HEAD_Y },
		}
	)

	-- ---------- TƯỜNG HẬU BẮC (-Z) ----------
	wallWithOpenings(
		f,
		"NorthBackWall",
		"X",
		BACK_ZC,
		BX0,
		BX1,
		FLOOR_TOP,
		FACADE_TOP,
		WT,
		C.BRICK_DARK,
		190,
		"LSC_BackWall",
		{
			{ a = -216.0, b = -209.5, y0 = FLOOR_TOP, y1 = 9.90 }, -- cửa hông EXIT
			{ a = -258.0, b = -250.0, y0 = 8.6, y1 = 14.6 },
			{ a = -238.0, b = -230.0, y0 = 8.6, y1 = 14.6 },
			{ a = -190.0, b = -182.0, y0 = 8.6, y1 = 14.6 },
		}
	)

	-- ---------- TƯỜNG TÂY (-X) ----------
	wallWithOpenings(
		f,
		"WestWall",
		"Z",
		WEST_XC,
		BZ0,
		BZ1,
		FLOOR_TOP,
		FACADE_TOP,
		WT,
		C.BRICK,
		175,
		"LSC_WestWall",
		{
			{ a = 2.0, b = 10.0, y0 = 9.0, y1 = 15.4 },
			{ a = 20.0, b = 28.0, y0 = 9.0, y1 = 15.4 },
			{ a = 37.0, b = 45.0, y0 = 9.0, y1 = 15.4 },
		}
	)

	-- ---------- TƯỜNG ĐÔNG (+X) ----------
	wallWithOpenings(
		f,
		"EastWall",
		"Z",
		EAST_XC,
		BZ0,
		BZ1,
		FLOOR_TOP,
		FACADE_TOP,
		WT,
		C.BRICK,
		175,
		"LSC_EastWall",
		{
			{ a = 0.0, b = 7.6, y0 = FLOOR_TOP, y1 = 9.90 }, -- cửa hông kỹ thuật
			{ a = 18.0, b = 26.0, y0 = 9.0, y1 = 15.4 },
			{ a = 33.0, b = 41.0, y0 = 9.0, y1 = 15.4 },
		}
	)

	-- ---------- KHUNG KÍNH CHO CÁC Ô CỬA SỔ CAO ----------
	local wins = folder("ClerestoryWindows", f)
	local function windowUnit(name: string, axis: "X" | "Z", fixed: number, a: number, b: number, y0: number, y1: number, grp: string)
		local isX = axis == "X"
		-- khung thép trên + dưới
		local frameSize = if isX then Vector3.new(b - a + 0.5, 0.36, WT + 0.22) else Vector3.new(WT + 0.22, 0.36, b - a + 0.5)
		local posY0 = if isX then Vector3.new((a + b) * 0.5, y0 - 0.18, fixed) else Vector3.new(fixed, y0 - 0.18, (a + b) * 0.5)
		local posY1 = if isX then Vector3.new((a + b) * 0.5, y1 + 0.18, fixed) else Vector3.new(fixed, y1 + 0.18, (a + b) * 0.5)
		box(wins, name .. "_Sill", frameSize, posY0, C.GALV, M.Metal, 110, grp, 1)
		box(wins, name .. "_Lintel", frameSize, posY1, C.GALV, M.Metal, 110, grp, 3)
		-- 2 ô kính + thanh đứng giữa
		glassPane(wins, name .. "_GlassA", axis, fixed, a + 0.2, (a + b) * 0.5 - 0.25, y0, y1, 45, grp .. "_A", 2)
		glassPane(wins, name .. "_GlassB", axis, fixed, (a + b) * 0.5 + 0.25, b - 0.2, y0, y1, 45, grp .. "_B", 2)
		local mullSize = if isX then Vector3.new(0.34, y1 - y0, WT * 0.8) else Vector3.new(WT * 0.8, y1 - y0, 0.34)
		local mullPos = if isX then Vector3.new((a + b) * 0.5, (y0 + y1) * 0.5, fixed) else Vector3.new(fixed, (y0 + y1) * 0.5, (a + b) * 0.5)
		box(wins, name .. "_Mullion", mullSize, mullPos, C.GALV, M.Metal, 90, grp, 2)
	end
	windowUnit("WinBack1", "X", BACK_ZC, -258.0, -250.0, 8.6, 14.6, "LSC_WinBack1")
	windowUnit("WinBack2", "X", BACK_ZC, -238.0, -230.0, 8.6, 14.6, "LSC_WinBack2")
	windowUnit("WinBack3", "X", BACK_ZC, -190.0, -182.0, 8.6, 14.6, "LSC_WinBack3")
	windowUnit("WinWest1", "Z", WEST_XC, 2.0, 10.0, 9.0, 15.4, "LSC_WinWest1")
	windowUnit("WinWest2", "Z", WEST_XC, 20.0, 28.0, 9.0, 15.4, "LSC_WinWest2")
	windowUnit("WinWest3", "Z", WEST_XC, 37.0, 45.0, 9.0, 15.4, "LSC_WinWest3")
	windowUnit("WinEast1", "Z", EAST_XC, 18.0, 26.0, 9.0, 15.4, "LSC_WinEast1")
	windowUnit("WinEast2", "Z", EAST_XC, 33.0, 41.0, 9.0, 15.4, "LSC_WinEast2")

	-- ---------- TRỤ ỐP GÓC + GIẰNG TƯỜNG ----------
	local pil = folder("CornerPilasters", f)
	for i, corner in ipairs({
		{ BX0 + 0.5, BZ0 + 0.5 },
		{ BX1 - 0.5, BZ0 + 0.5 },
		{ BX0 + 0.5, BZ1 - 0.5 },
		{ BX1 - 0.5, BZ1 - 0.5 },
	}) do
		brickWall(pil, "Pilaster" .. tostring(i), "X", corner[2] + (if corner[2] < 0 then 0.65 else -0.65), corner[1] - 1.5, corner[1] + 1.5, FLOOR_TOP, FACADE_TOP - FLOOR_TOP, 2.2, C.BRICK_DARK, 210, "LSC_Pilaster" .. tostring(i))
		box(pil, "PilasterCap" .. tostring(i), Vector3.new(3.6, 0.5, 3.6), Vector3.new(corner[1], FACADE_TOP + 0.25, corner[2] + (if corner[2] < 0 then 0.9 else -0.9)), C.CONCRETE, M.Concrete, 170, "LSC_Pilaster" .. tostring(i), 14)
	end

	-- ---------- MÁNG XỐI NƯỚC MƯA + ỐNG THOÁT ----------
	for i, x in ipairs({ BX0 + 1.4, -218.0, BX1 - 1.4 }) do
		local p = Vector3.new(x, 12.0, BZ1 + 0.75)
		box(f, "DownpipeZ" .. tostring(i), Vector3.new(0.55, 20.0, 0.55), p, C.GALV, M.Metal, 80, "LSC_Downpipe" .. tostring(i), 1)
		box(f, "DownpipeShoe" .. tostring(i), Vector3.new(0.75, 1.4, 1.6), Vector3.new(x, FLOOR_TOP + 1.0, BZ1 + 1.2), C.GALV, M.Metal, 60, "LSC_Downpipe" .. tostring(i), 2)
	end
	-- Máng treo ngang mái
	box(f, "GutterSouth", Vector3.new(BX1 - BX0, 0.8, 0.9), Vector3.new((BX0 + BX1) * 0.5, PARAPET_TOP - 0.4, BZ1 + 0.6), C.GALV, M.Metal, 90, "LSC_Gutter", 1)
	box(f, "GutterNorth", Vector3.new(BX1 - BX0, 0.8, 0.9), Vector3.new((BX0 + BX1) * 0.5, PARAPET_TOP - 0.4, BZ0 - 0.1), C.GALV, M.Metal, 90, "LSC_Gutter", 1)

	-- ---------- ĐÈN HẮT TƯỜNG (GOOSENECK) TRÊN MẶT TIỀN ----------
	for i = 1, 5 do
		local x = BAY1A + 3.0 + (i - 1) * 20.0
		if x > BX1 - 2.0 then
			x = BX1 - 3.0
		end
		local grp = "LSC_Gooseneck" .. tostring(i)
		box(f, "SconceArm" .. tostring(i), Vector3.new(0.34, 0.34, 2.6), Vector3.new(x, 15.6, BZ1 + 1.1), C.DARK_STEEL, M.Metal, 45, grp, 2, { canCollide = false })
		box(f, "SconceShade" .. tostring(i), Vector3.new(1.9, 0.5, 1.3), Vector3.new(x, 15.6, BZ1 + 2.35), C.DARK_STEEL, M.Metal, 45, grp, 3)
		box(f, "SconceLamp" .. tostring(i), Vector3.new(1.6, 0.22, 1.0), Vector3.new(x, 15.32, BZ1 + 2.35), C.NEON_WHITE, M.Neon, 25, grp, 4, {
			canCollide = false,
			castShadow = false,
		})
	end
end

-- =============================================================================
-- 7. CỬA CUỐN Ô TÔ (2 KHOANG 20.5 × 13.5 — lọt xe rộng 8.2 cao 7.0)
-- =============================================================================
local function buildBayDoors(root: Instance)
	local f = folder("02_RollUpBayDoors", root)
	for i, bay in ipairs({ { BAY1A, BAY1B }, { BAY2A, BAY2B } }) do
		local a, b = bay[1], bay[2]
		local grp = "LSC_Bay" .. tostring(i)
		local w = b - a
		local doorZ = 50.4

		-- Khung thép 2 bên (trụ jamb) + dầm đầu cửa
		box(f, "BayJambW" .. i, Vector3.new(0.75, BAY_HEAD_Y - FLOOR_TOP + 0.1, 1.7), Vector3.new(a + 0.37, (FLOOR_TOP + BAY_HEAD_Y) * 0.5, doorZ), C.DARK_STEEL, M.Metal, 300, grp .. "_JambW", 1)
		box(f, "BayJambE" .. i, Vector3.new(0.75, BAY_HEAD_Y - FLOOR_TOP + 0.1, 1.7), Vector3.new(b - 0.37, (FLOOR_TOP + BAY_HEAD_Y) * 0.5, doorZ), C.DARK_STEEL, M.Metal, 300, grp .. "_JambE", 1)
		box(f, "BayHeaderBeam" .. i, Vector3.new(w - 1.4, 0.5, 1.55), Vector3.new((a + b) * 0.5, BAY_HEAD_Y - 0.25, doorZ), C.DARK_STEEL, M.Metal, 280, grp .. "_Header", 2)

		-- Sọc cảnh báo vàng-đen trên 2 trụ jamb
		for s = 1, 6 do
			local y = FLOOR_TOP + 0.9 + (s - 1) * 1.05
			local col = if s % 2 == 0 then C.YELLOW else C.BLACK
			box(f, "JambStripeW" .. i .. "_" .. s, Vector3.new(0.78, 0.5, 1.74), Vector3.new(a + 0.37, y, doorZ), col, M.SmoothPlastic, 40, grp .. "_StripeW", 3, { canCollide = false })
			box(f, "JambStripeE" .. i .. "_" .. s, Vector3.new(0.78, 0.5, 1.74), Vector3.new(b - 0.37, y, doorZ), col, M.SmoothPlastic, 40, grp .. "_StripeE", 3, { canCollide = false })
		end

		-- Cửa cuốn ĐANG MỞ: 3 lam nhôm cuộn treo sát dầm (thông thuỷ thực 11.35 studs)
		for s = 1, 3 do
			segmentedRow(
				f,
				string.format("BaySlat%d_%d", i, s),
				"X",
				50.2,
				a + 0.8,
				b - 0.8,
				BAY_HEAD_Y - 0.5 - (s - 0.5) * 0.56,
				0.5,
				0.45,
				5.2,
				C.GALV,
				M.Metal,
				85,
				grp .. "_Slat" .. tostring(s),
				10 - s
			)
		end

		-- Trục cuốn + 2 thanh ray trượt chạy sâu vào trong
		cyl(f, "BayCoil" .. i, Vector3.new(w - 1.6, 1.1, 1.1), CFrame.new((a + b) * 0.5, BAY_HEAD_Y - 0.15, 48.6), C.CHROME, M.Metal, 120, grp .. "_Coil", 9)
		for _, sx in ipairs({ 1, -1 }) do
			local x = (a + b) * 0.5 + sx * (w * 0.5 - 1.0)
			box(f, "BayRail" .. i .. tostring(sx), Vector3.new(0.26, 0.26, 7.0), Vector3.new(x, BAY_HEAD_Y - 0.55, 47.0), C.GALV, M.Metal, 70, grp .. "_Rail" .. tostring(sx), 9, { canCollide = false })
			box(f, "BayRailBracket" .. i .. tostring(sx), Vector3.new(0.2, 1.6, 0.2), Vector3.new(x, PARAPET_TOP - 1.2, 47.0), C.GALV, M.Metal, 60, grp .. "_Rail" .. tostring(sx), 9, { canCollide = false })
		end
		-- Động cơ cửa cuốn
		box(f, "BayMotor" .. i, Vector3.new(2.2, 1.7, 1.7), Vector3.new(b - 2.6, BAY_HEAD_Y - 0.9, 48.4), C.STEEL, M.Metal, 110, grp .. "_Motor", 9)

		-- Bảng treo "BAY 1 / BAY 2" dưới trần
		local plateY = 19.4
		box(f, "BayHangPlate" .. i, Vector3.new(12.0, 3.6, 0.3), Vector3.new((a + b) * 0.5, plateY, 44.0), C.LSC_BLUE, M.Metal, 90, grp .. "_HangSign", 1)
		drawText(f, "BayHangText" .. i, "BAY " .. tostring(i), (a + b) * 0.5 - 5.95, plateY - 1.3, 44.32, 0.16, 0.36, C.NEON_WHITE, M.Neon, 40, grp .. "_HangSign", 2)
		for _, sx in ipairs({ -4.6, 4.6 }) do
			box(f, "BayHangWire" .. i .. tostring(sx), Vector3.new(0.1, 2.4, 0.1), Vector3.new((a + b) * 0.5 + sx, plateY + 3.0, 44.0), C.DARK_STEEL, M.Metal, 25, grp .. "_HangSign", 3, { canCollide = false })
		end

		-- Cầu chắn bê tông thấp 2 bên mép cửa (chống xe leo vỉa)
		box(f, "BayKerbW" .. i, Vector3.new(1.2, 1.0, 5.0), Vector3.new(a - 1.0, FLOOR_TOP + 0.5, 47.0), C.CONCRETE, M.Concrete, 180, grp .. "_KerbW", 1)
		box(f, "BayKerbE" .. i, Vector3.new(1.2, 1.0, 5.0), Vector3.new(b + 1.0, FLOOR_TOP + 0.5, 47.0), C.CONCRETE, M.Concrete, 180, grp .. "_KerbE", 1)
	end
end

-- =============================================================================
-- 8. SHOWROOM MẶT KÍNH + CỬA ĐÔI ĐI BỘ (cao 9.5 studs)
-- =============================================================================
local function buildStorefront(root: Instance)
	local f = folder("03_ShowroomStorefront", root)
	local grp = "LSC_Storefront"

	-- Chân tường ốp kim loại gân sóng
	segmentedRow(f, "KickPanelW", "X", FRONT_ZC, SHOWA, DOOR_A, FLOOR_TOP + (SHOW_KICK_Y - FLOOR_TOP) * 0.5, SHOW_KICK_Y - FLOOR_TOP, 0.7, 3.0, C.LSC_BLUE, M.Metal, 150, grp .. "_KickW", 1)
	segmentedRow(f, "KickPanelE", "X", FRONT_ZC, DOOR_B, SHOWB, FLOOR_TOP + (SHOW_KICK_Y - FLOOR_TOP) * 0.5, SHOW_KICK_Y - FLOOR_TOP, 0.7, 3.0, C.LSC_BLUE, M.Metal, 150, grp .. "_KickE", 1)
	box(f, "KickDadoStripW", Vector3.new(DOOR_A - SHOWA, 0.22, 0.85), Vector3.new((SHOWA + DOOR_A) * 0.5, SHOW_KICK_Y, FRONT_ZC), C.CHROME, M.Metal, 90, grp .. "_DadoW", 2, { canCollide = false })
	box(f, "KickDadoStripE", Vector3.new(SHOWB - DOOR_B, 0.22, 0.85), Vector3.new((DOOR_B + SHOWB) * 0.5, SHOW_KICK_Y, FRONT_ZC), C.CHROME, M.Metal, 90, grp .. "_DadoE", 2, { canCollide = false })

	-- Thanh đứng (mullion) chia ô kính
	local mullions = { SHOWA, DOOR_A, DOOR_B, -196.0, -189.0, -182.0, SHOWB }
	for i, x in ipairs(mullions) do
		box(f, "Mullion" .. tostring(i), Vector3.new(0.55, SHOW_HEAD_Y - FLOOR_TOP, 0.9), Vector3.new(x, (FLOOR_TOP + SHOW_HEAD_Y) * 0.5, FRONT_ZC), C.DARK_STEEL, M.Metal, 200, grp .. "_Mullion" .. tostring(i), 1)
	end

	-- Ô kính lớn (mỗi ô 1 khối có máu ẩn 45 -> bắn vỡ từng tấm)
	local panes = {
		{ SHOWA + 0.3, DOOR_A - 0.3, FLOOR_TOP + 0.1, SHOW_HEAD_Y - 0.4 },
		{ DOOR_B + 0.3, -196.0 - 0.3, SHOW_KICK_Y, SHOW_HEAD_Y - 0.4 },
		{ -196.0 + 0.3, -189.0 - 0.3, SHOW_KICK_Y, SHOW_HEAD_Y - 0.4 },
		{ -189.0 + 0.3, -182.0 - 0.3, SHOW_KICK_Y, SHOW_HEAD_Y - 0.4 },
		{ -182.0 + 0.3, SHOWB - 0.3, SHOW_KICK_Y, SHOW_HEAD_Y - 0.4 },
		{ DOOR_A + 0.2, DOOR_B - 0.2, DOOR_TOP, SHOW_HEAD_Y - 0.4 },
	}
	for i, p in ipairs(panes) do
		glassPane(f, "ShopGlass" .. tostring(i), "X", FRONT_ZC, p[1], p[2], p[3], p[4], 45, grp .. "_Glass" .. tostring(i), 3, C.GLASS_BLUE)
	end
	-- Dầm ngang trên + dưới vách kính
	box(f, "TransomBar", Vector3.new(SHOWB - SHOWA, 0.45, 0.95), Vector3.new((SHOWA + SHOWB) * 0.5, SHOW_HEAD_Y - 0.15, FRONT_ZC), C.DARK_STEEL, M.Metal, 190, grp .. "_Transom", 4)
	box(f, "SillBar", Vector3.new(SHOWB - SHOWA, 0.3, 0.9), Vector3.new((SHOWA + SHOWB) * 0.5, SHOW_HEAD_Y - 0.4, FRONT_ZC), C.CHROME, M.Metal, 120, grp .. "_Sill", 4, { canCollide = false })

	-- Cửa đôi đi bộ (2 cánh kính khung nhôm, cao 9.5)
	local doorGrp = "LSC_FrontDoors"
	box(f, "DoorThreshold", Vector3.new(DOOR_B - DOOR_A + 0.7, 0.16, 1.6), Vector3.new((DOOR_A + DOOR_B) * 0.5, FLOOR_TOP + 0.06, FRONT_ZC), C.GALV, M.DiamondPlate, 120, doorGrp .. "_Threshold", 1, { castShadow = false })
	for leaf = 1, 2 do
		local lx0 = if leaf == 1 then DOOR_A + 0.15 else (DOOR_A + DOOR_B) * 0.5 + 0.1
		local lx1 = if leaf == 1 then (DOOR_A + DOOR_B) * 0.5 - 0.1 else DOOR_B - 0.15
		local cx = (lx0 + lx1) * 0.5
		local lg = doorGrp .. "_Leaf" .. tostring(leaf)
		-- khung cánh
		box(f, "Leaf" .. leaf .. "_Top", Vector3.new(lx1 - lx0, 0.45, 0.28), Vector3.new(cx, DOOR_TOP - 0.3, FRONT_ZC), C.DARK_STEEL, M.Metal, 110, lg, 2)
		box(f, "Leaf" .. leaf .. "_Bottom", Vector3.new(lx1 - lx0, 0.7, 0.28), Vector3.new(cx, FLOOR_TOP + 0.9, FRONT_ZC), C.DARK_STEEL, M.Metal, 110, lg, 1)
		box(f, "Leaf" .. leaf .. "_W", Vector3.new(0.3, DOOR_TOP - FLOOR_TOP - 0.2, 0.28), Vector3.new(lx0 + 0.15, (FLOOR_TOP + DOOR_TOP) * 0.5, FRONT_ZC), C.DARK_STEEL, M.Metal, 100, lg, 2)
		box(f, "Leaf" .. leaf .. "_E", Vector3.new(0.3, DOOR_TOP - FLOOR_TOP - 0.2, 0.28), Vector3.new(lx1 - 0.15, (FLOOR_TOP + DOOR_TOP) * 0.5, FRONT_ZC), C.DARK_STEEL, M.Metal, 100, lg, 2)
		-- kính cánh
		box(f, "Leaf" .. leaf .. "_Glass", Vector3.new(lx1 - lx0 - 0.5, DOOR_TOP - FLOOR_TOP - 1.9, 0.16), Vector3.new(cx, (FLOOR_TOP + DOOR_TOP) * 0.5, FRONT_ZC), C.GLASS, M.Glass, 45, lg .. "_Glass", 2, {
			transparency = 0.5,
			canCollide = false,
			castShadow = false,
		})
		-- tay nắm inox dọc
		local hx = if leaf == 1 then lx1 - 0.9 else lx0 + 0.9
		vcyl(f, "Leaf" .. leaf .. "_Handle", Vector3.new(2.6, 0.22, 0.22), Vector3.new(hx, 6.4, FRONT_ZC + 0.35), C.CHROME, M.Metal, 60, lg .. "_Handle", 3)
		box(f, "Leaf" .. leaf .. "_HandleBar", Vector3.new(0.3, 0.3, 0.6), Vector3.new(hx, 7.6, FRONT_ZC + 0.2), C.CHROME, M.Metal, 60, lg .. "_Handle", 3, { canCollide = false })
		-- decal giờ mở cửa
		box(f, "Leaf" .. leaf .. "_Decal", Vector3.new(2.2, 1.1, 0.06), Vector3.new(cx, 5.6, FRONT_ZC + 0.18), C.WHITE, M.SmoothPlastic, 20, lg .. "_Decal", 3, { canCollide = false, castShadow = false })
	end

	-- Mái hiên nhô ra + ty giằng + đèn neon dưới hiên
	local canopy = folder("EntranceCanopy", f)
	box(canopy, "CanopySlab", Vector3.new(46.0, 0.45, 6.0), Vector3.new(-196.0, 13.85, 53.8), C.LSC_BLUE, M.Metal, 260, "LSC_Canopy", 1)
	box(canopy, "CanopyFascia", Vector3.new(46.0, 1.5, 0.4), Vector3.new(-196.0, 13.3, 56.7), C.LSC_BLUE_LIGHT, M.Metal, 150, "LSC_Canopy", 2)
	box(canopy, "CanopyNeon", Vector3.new(44.0, 0.35, 0.28), Vector3.new(-196.0, 12.7, 56.75), C.NEON_WHITE, M.Neon, 40, "LSC_CanopyNeon", 3, { canCollide = false, castShadow = false })
	for i = 1, 4 do
		local cx = -214.0 + (i - 1) * 12.0
		strut(canopy, "CanopyRod" .. i, Vector3.new(cx, 18.9, 51.4), Vector3.new(cx, 14.1, 55.9), 0.26, C.DARK_STEEL, M.Metal, 70, "LSC_CanopyRod" .. i, 1)
		box(canopy, "CanopyRodPlate" .. i, Vector3.new(0.9, 0.9, 0.2), Vector3.new(cx, 18.9, 51.15), C.DARK_STEEL, M.Metal, 50, "LSC_CanopyRod" .. i, 2)
	end
	-- Cột chống hiên phía ngoài
	for _, cx in ipairs({ -214.5, -177.5 }) do
		local grp2 = "LSC_CanopyPost" .. tostring(math.floor(math.abs(cx)))
		box(canopy, "CanopyPost" .. tostring(math.floor(math.abs(cx))), Vector3.new(0.85, 12.3, 0.85), Vector3.new(cx, FLOOR_TOP + 6.15, 55.9), C.DARK_STEEL, M.Metal, 220, grp2, 1)
		box(canopy, "CanopyPostBase" .. tostring(math.floor(math.abs(cx))), Vector3.new(1.8, 0.6, 1.8), Vector3.new(cx, FLOOR_TOP + 0.3, 55.9), C.CONCRETE, M.Concrete, 190, grp2, 1)
	end

	-- Doormat + bảng OPEN + chuông gió
	box(f, "DoorMat", Vector3.new(9.0, 0.1, 4.0), Vector3.new(-206.5, FLOOR_TOP + 0.05, 53.0), C.LEATHER, M.Fabric, 25, "LSC_Doormat", 1, { canCollide = false, castShadow = false })
	box(f, "OpenSignPlate", Vector3.new(11.5, 2.6, 0.25), Vector3.new(-213.5, 11.4, 49.9), C.BLACK, M.Metal, 60, "LSC_OpenSign", 1)
	drawText(f, "OpenSignText", "OPEN", -218.25, 10.55, 50.15, 0.14, 0.38, C.NEON_RED, M.Neon, 30, "LSC_OpenSign", 2)
end

-- =============================================================================
-- 9. BẢNG HIỆU NEON CHỮ NỔI 3D (mặt tiền + nóc + cột pylon ngoài đường)
-- =============================================================================
local function buildSignage(root: Instance)
	local f = folder("04_SignageNeon", root)

	-- ---------- BẢNG CHÍNH MẶT TIỀN ----------
	local signGrp = "LSC_MainSign"
	local panelY0, panelY1 = 15.1, 25.5
	local panelX0, panelX1 = -268.0, -168.0
	box(f, "MainSignBacking", Vector3.new(panelX1 - panelX0, panelY1 - panelY0, 1.2), Vector3.new((panelX0 + panelX1) * 0.5, (panelY0 + panelY1) * 0.5, 51.3), C.LSC_BLUE, M.Metal, 320, signGrp .. "_Backing", 1)
	box(f, "MainSignTopTrim", Vector3.new(panelX1 - panelX0 + 1.2, 0.55, 1.7), Vector3.new((panelX0 + panelX1) * 0.5, panelY1 + 0.28, 51.3), C.CHROME, M.Metal, 150, signGrp .. "_Trim", 2)
	box(f, "MainSignBottomTrim", Vector3.new(panelX1 - panelX0 + 1.2, 0.55, 1.7), Vector3.new((panelX0 + panelX1) * 0.5, panelY0 - 0.28, 51.3), C.CHROME, M.Metal, 150, signGrp .. "_Trim", 2)

	local mainText = "LOS SANTOS CUSTOMS"
	local pixel = 0.72
	local tw = textWidth(mainText, pixel)
	drawText(f, "MainSignLetters", mainText, -218.0 - tw * 0.5, 18.4, 52.55, 0.55, pixel, C.NEON_YELLOW, M.Neon, 55, signGrp .. "_Letters", 3)
	-- 2 dải neon gạch chân
	for i, yy in ipairs({ 16.6, 16.15 }) do
		box(f, "MainSignUnderline" .. i, Vector3.new(tw * 0.82, 0.28, 0.35), Vector3.new(-218.0, yy, 52.55), if i == 1 then C.NEON_ORANGE else C.NEON_RED, M.Neon, 40, signGrp .. "_Underline" .. i, 3, { canCollide = false, castShadow = false })
	end
	-- Đèn rọi bảng hiệu
	for i = 1, 3 do
		local x = -252.0 + (i - 1) * 34.0
		box(f, "SignFloodArm" .. i, Vector3.new(0.28, 0.28, 2.4), Vector3.new(x, 25.9, 52.2), C.DARK_STEEL, M.Metal, 40, "LSC_SignFlood" .. i, 2, { canCollide = false })
		box(f, "SignFloodBody" .. i, Vector3.new(1.8, 0.7, 1.1), Vector3.new(x, 25.5, 53.3), C.DARK_STEEL, M.Metal, 45, "LSC_SignFlood" .. i, 3)
		box(f, "SignFloodLens" .. i, Vector3.new(1.5, 0.5, 0.25), Vector3.new(x, 25.2, 53.3), C.NEON_WHITE, M.Neon, 25, "LSC_SignFlood" .. i, 4, { canCollide = false, castShadow = false })
	end

	-- ---------- BẢNG HIỆU TRÊN NÓC "CUSTOMS" ----------
	local roofGrp = "LSC_RoofSign"
	local rx0, rx1 = -241.0, -195.0
	local ry0, ry1 = 27.4, 35.6
	box(f, "RoofSignBacking", Vector3.new(rx1 - rx0, ry1 - ry0, 1.4), Vector3.new((rx0 + rx1) * 0.5, (ry0 + ry1) * 0.5, 51.6), C.LSC_BLUE, M.Metal, 300, roofGrp .. "_Backing", 1)
	box(f, "RoofSignFrameT", Vector3.new(rx1 - rx0 + 1.0, 0.5, 1.9), Vector3.new((rx0 + rx1) * 0.5, ry1 + 0.25, 51.6), C.CHROME, M.Metal, 140, roofGrp .. "_Frame", 2)
	box(f, "RoofSignFrameB", Vector3.new(rx1 - rx0 + 1.0, 0.5, 1.9), Vector3.new((rx0 + rx1) * 0.5, ry0 - 0.25, 51.6), C.CHROME, M.Metal, 140, roofGrp .. "_Frame", 2)
	local roofText = "CUSTOMS"
	local rpx = 0.95
	local rtw = textWidth(roofText, rpx)
	drawText(f, "RoofSignLetters", roofText, -218.0 - rtw * 0.5, 28.2, 52.85, 0.5, rpx, C.NEON_ORANGE, M.Neon, 60, roofGrp .. "_Letters", 3)
	-- Chân đế + ty giằng xuống mái
	for i = 1, 3 do
		local x = -232.0 + (i - 1) * 14.0
		box(f, "RoofSignBase" .. i, Vector3.new(1.6, 4.4, 1.6), Vector3.new(x, 25.6, 51.6), C.DARK_STEEL, M.Metal, 180, roofGrp .. "_Base" .. i, 1)
		strut(f, "RoofSignGuy" .. i, Vector3.new(x, 27.6, 51.6), Vector3.new(x + (if i == 1 then -6.0 else (if i == 3 then 6.0 else 0.0)), 24.3, 47.5), 0.22, C.DARK_STEEL, M.Metal, 60, roofGrp .. "_Guy" .. i, 1)
	end

	-- ---------- CỘT PYLON NGOÀI ĐƯỜNG "LSC" ----------
	local pyGrp = "LSC_PylonSign"
	local px, pz = -150.0, 113.0
	box(f, "PylonFooting", Vector3.new(6.0, 0.8, 6.0), Vector3.new(px, FC_TOP + 0.4, pz), C.CONCRETE, M.Concrete, 220, pyGrp .. "_Footing", 1)
	box(f, "PylonPole", Vector3.new(2.2, 15.0, 2.2), Vector3.new(px, FC_TOP + 8.3, pz), C.DARK_STEEL, M.Metal, 240, pyGrp .. "_Pole", 2)
	box(f, "PylonCabinet", Vector3.new(16.0, 9.4, 1.4), Vector3.new(px, FC_TOP + 20.5, pz), C.LSC_BLUE, M.Metal, 260, pyGrp .. "_Cabinet", 3)
	box(f, "PylonNeonTop", Vector3.new(15.2, 0.4, 1.6), Vector3.new(px, FC_TOP + 25.2, pz), C.NEON_YELLOW, M.Neon, 35, pyGrp .. "_NeonTop", 4, { canCollide = false, castShadow = false })
	box(f, "PylonNeonBottom", Vector3.new(15.2, 0.4, 1.6), Vector3.new(px, FC_TOP + 15.8, pz), C.NEON_YELLOW, M.Neon, 35, pyGrp .. "_NeonBottom", 4, { canCollide = false, castShadow = false })
	local pText = "LSC"
	local ppx = 0.85
	local ptw = textWidth(pText, ppx)
	drawText(f, "PylonLetters", pText, px - ptw * 0.5, FC_TOP + 19.1, pz + 1.05, 0.4, ppx, C.NEON_YELLOW, M.Neon, 45, pyGrp .. "_Letters", 4)
	-- chữ nhỏ dưới pylon
	local subText = "REPAIR"
	local spx = 0.30
	local stw = textWidth(subText, spx)
	drawText(f, "PylonSubText", subText, px - stw * 0.5, FC_TOP + 16.7, pz + 1.05, 0.3, spx, C.NEON_WHITE, M.Neon, 25, pyGrp .. "_SubText", 4)
end

-- =============================================================================
-- 10. MÁI NHÀ + THIẾT BỊ KỸ THUẬT TRÊN NÓC
-- =============================================================================
local function buildRoof(root: Instance)
	local f = folder("05_RoofAndRooftopEquipment", root)

	-- Sàn mái bê tông (kết cấu chịu lực -> không gắn máu ẩn)
	box(f, "RoofSlab", Vector3.new(BX1 - BX0 + 0.4, 0.8, BZ1 - BZ0 + 0.4), Vector3.new((BX0 + BX1) * 0.5, ROOF_TOP - 0.4, (BZ0 + BZ1) * 0.5), C.CONCRETE, M.Concrete, nil, nil, nil, { castShadow = false })

	-- Mũ chụp bờ tường (coping) 4 cạnh
	local copGrp = "LSC_ParapetCoping"
	box(f, "CopingSouth", Vector3.new(BX1 - BX0 + 1.6, 0.5, WT + 0.9), Vector3.new((BX0 + BX1) * 0.5, PARAPET_TOP + 0.25, BZ1 - WT * 0.5), C.CONCRETE, M.Concrete, 220, copGrp, 1)
	box(f, "CopingNorth", Vector3.new(BX1 - BX0 + 1.6, 0.5, WT + 0.9), Vector3.new((BX0 + BX1) * 0.5, PARAPET_TOP + 0.25, BZ0 + WT * 0.5), C.CONCRETE, M.Concrete, 220, copGrp, 1)
	box(f, "CopingWest", Vector3.new(WT + 0.9, 0.5, BZ1 - BZ0 - 2.4), Vector3.new(BX0 + WT * 0.5, PARAPET_TOP + 0.25, (BZ0 + BZ1) * 0.5), C.CONCRETE, M.Concrete, 220, copGrp, 1)
	box(f, "CopingEast", Vector3.new(WT + 0.9, 0.5, BZ1 - BZ0 - 2.4), Vector3.new(BX1 - WT * 0.5, PARAPET_TOP + 0.25, (BZ0 + BZ1) * 0.5), C.CONCRETE, M.Concrete, 220, copGrp, 1)

	-- 3 cụm điều hoà rooftop (giàn nóng + quạt + ống gas)
	for i, hp in ipairs({ { -252.0, 18.0 }, { -196.0, 34.0 }, { -238.0, 40.0 } }) do
		local x, z = hp[1], hp[2]
		local grp = "LSC_RooftopHVAC" .. tostring(i)
		box(f, "HVACPad" .. i, Vector3.new(11.0, 0.5, 7.0), Vector3.new(x, ROOF_TOP + 0.25, z), C.CONCRETE_DARK, M.Concrete, 200, grp .. "_Pad", 1)
		box(f, "HVACBody" .. i, Vector3.new(10.0, 4.6, 6.0), Vector3.new(x, ROOF_TOP + 2.8, z), C.GALV, M.Metal, 260, grp .. "_Body", 2)
		box(f, "HVACTop" .. i, Vector3.new(10.4, 0.4, 6.4), Vector3.new(x, ROOF_TOP + 5.3, z), C.STEEL, M.Metal, 180, grp .. "_Top", 3)
		-- quạt giàn nóng
		local fanZ = z - 3.15
		cyl(f, "HVACFan" .. i, Vector3.new(0.4, 4.6, 4.6), CFrame.new(x, ROOF_TOP + 2.8, fanZ) * CFrame.Angles(0, math.rad(90), 0), C.DARK_STEEL, M.Metal, 120, grp .. "_Fan", 3)
		for bl = 1, 4 do
			local ang = (bl - 1) * math.pi * 0.5
			box(
				f,
				"HVACFanBlade" .. i .. "_" .. bl,
				Vector3.new(0.3, 3.6, 1.2),
				Vector3.new(x, ROOF_TOP + 2.8 + math.cos(ang) * 1.7, fanZ + math.sin(ang) * 1.7),
				C.GALV,
				M.Metal,
				60,
				grp .. "_Fan",
				4,
				{ canCollide = false, castShadow = false }
			)
		end
		-- ống môi chất chạy xuống
		strut(f, "HVACLine" .. i, Vector3.new(x + 4.4, ROOF_TOP + 1.2, z), Vector3.new(x + 4.4, ROOF_TOP - 0.4, z + 5.0), 0.34, C.CHROME, M.Metal, 70, grp .. "_Line", 2)
	end

	-- 2 giếng trời kính + khung thép
	for i, pos in ipairs({ { -262.0, 4.0 }, { -176.0, 4.0 } }) do
		local grp = "LSC_Skylight" .. tostring(i)
		box(f, "SkylightCurb" .. i, Vector3.new(11.0, 1.4, 11.0), Vector3.new(pos[1], ROOF_TOP + 0.7, pos[2]), C.CONCRETE, M.Concrete, 240, grp .. "_Curb", 1)
		box(f, "SkylightGlass" .. i, Vector3.new(10.2, 0.25, 10.2), Vector3.new(pos[1], ROOF_TOP + 1.5, pos[2]), C.GLASS_BLUE, M.Glass, 40, grp .. "_Glass", 2, {
			transparency = 0.45,
			canCollide = false,
			castShadow = false,
		})
		for _, d in ipairs({ { 5.3, 0 }, { -5.3, 0 }, { 0, 5.3 }, { 0, -5.3 } }) do
			box(f, "SkylightBar" .. i .. tostring(d[1]) .. tostring(d[2]), Vector3.new(if d[1] == 0 then 11.4 else 0.4, 0.35, if d[2] == 0 then 11.4 else 0.4), Vector3.new(pos[1] + d[1], ROOF_TOP + 1.6, pos[2] + d[2]), C.DARK_STEEL, M.Metal, 60, grp .. "_Bar", 3, { canCollide = false })
		end
	end

	-- Buồng cầu thang xuống mái (stair bulkhead) + cửa thép
	local bx, bz = -186.0, -2.0
	box(f, "BulkheadBody", Vector3.new(13.0, 9.0, 10.0), Vector3.new(bx, ROOF_TOP + 4.5, bz), Color3.fromRGB(168, 164, 156), M.Concrete, 320, "LSC_Bulkhead", 1)
	box(f, "BulkheadRoof", Vector3.new(13.8, 0.5, 10.8), Vector3.new(bx, ROOF_TOP + 9.2, bz), C.CONCRETE_DARK, M.Concrete, 200, "LSC_BulkheadRoof", 2)
	box(f, "BulkheadDoor", Vector3.new(4.6, 8.0, 0.4), Vector3.new(bx, ROOF_TOP + 4.0, bz + 5.2), C.DARK_STEEL, M.Metal, 180, "LSC_BulkheadDoor", 2)
	box(f, "BulkheadDoorBar", Vector3.new(4.2, 0.35, 0.5), Vector3.new(bx, ROOF_TOP + 4.4, bz + 5.5), C.CHROME, M.Metal, 90, "LSC_BulkheadDoor", 3, { canCollide = false })
	box(f, "BulkheadLamp", Vector3.new(1.2, 0.35, 0.5), Vector3.new(bx, ROOF_TOP + 8.4, bz + 5.2), C.NEON_WHITE, M.Neon, 25, "LSC_BulkheadLamp", 1, { canCollide = false, castShadow = false })

	-- Ống thông hơi + quạt hút gió thải
	for i, vx in ipairs({ -256.0, -246.0, -220.0, -210.0 }) do
		vcyl(f, "VentStack" .. i, Vector3.new(3.2, 1.5, 1.5), Vector3.new(vx, ROOF_TOP + 1.6, 30.0), C.GALV, M.Metal, 120, "LSC_VentStack" .. i, 1)
		vcyl(f, "VentCap" .. i, Vector3.new(0.5, 2.2, 2.2), Vector3.new(vx, ROOF_TOP + 3.3, 30.0), C.STEEL, M.Metal, 70, "LSC_VentStack" .. i, 2)
	end
	for i, vx in ipairs({ -262.0, -186.0 }) do
		local grp = "LSC_ExhaustFan" .. tostring(i)
		box(f, "ExhaustBase" .. i, Vector3.new(4.4, 1.0, 4.4), Vector3.new(vx, ROOF_TOP + 0.5, 42.0), C.GALV, M.Metal, 160, grp .. "_Base", 1)
		vcyl(f, "ExhaustDrum" .. i, Vector3.new(2.6, 3.2, 3.2), Vector3.new(vx, ROOF_TOP + 2.2, 42.0), C.STEEL, M.Metal, 140, grp .. "_Drum", 2)
		vcyl(f, "ExhaustBlade" .. i, Vector3.new(0.3, 3.0, 3.0), Vector3.new(vx, ROOF_TOP + 3.6, 42.0), C.DARK_STEEL, M.Metal, 70, grp .. "_Blade", 3)
	end

	-- Lan can an toàn mép mái phía sau
	local railGrp = "LSC_RoofRail"
	for i = 0, 12 do
		local x = BX0 + 4.0 + i * 8.2
		if x < BX1 - 2.0 then
			box(f, "RoofRailPost" .. i, Vector3.new(0.28, 3.2, 0.28), Vector3.new(x, ROOF_TOP + 1.6, BZ0 + 2.4), C.GALV, M.Metal, 60, railGrp .. "_Post" .. i, 1, { canCollide = false })
		end
	end
	box(f, "RoofRailTop", Vector3.new(BX1 - BX0 - 4.0, 0.2, 0.2), Vector3.new((BX0 + BX1) * 0.5, ROOF_TOP + 3.1, BZ0 + 2.4), C.GALV, M.Metal, 60, railGrp .. "_Top", 2, { canCollide = false })
	box(f, "RoofRailMid", Vector3.new(BX1 - BX0 - 4.0, 0.16, 0.16), Vector3.new((BX0 + BX1) * 0.5, ROOF_TOP + 2.0, BZ0 + 2.4), C.GALV, M.Metal, 60, railGrp .. "_Mid", 2, { canCollide = false })

	-- Cột thu lôi + đèn báo mái
	vcyl(f, "LightningRod", Vector3.new(9.0, 0.35, 0.35), Vector3.new(-232.0, ROOF_TOP + 5.0, -6.0), C.CHROME, M.Metal, 60, "LSC_LightningRod", 1)
	box(f, "RoofBeacon", Vector3.new(1.1, 0.9, 1.1), Vector3.new(-232.0, ROOF_TOP + 9.8, -6.0), C.NEON_RED, M.Neon, 30, "LSC_RoofBeacon", 1, { canCollide = false, castShadow = false })
end

-- =============================================================================
-- 11. NỘI THẤT XƯỞNG: CẦU NÂNG 2 TRỤ THUỶ LỰC
-- =============================================================================
local function buildLifts(root: Instance)
	local f = folder("06_HydraulicLifts", root)
	for li, spec in ipairs({ { LIFT1_X, LIFT1_Z, 1 }, { LIFT2_X, LIFT2_Z, 2 } }) do
		local cx, cz, idx = spec[1], spec[2], spec[3]
		local grp = "LSC_Lift" .. tostring(idx)
		for si, sx in ipairs({ -6.6, 6.6 }) do
			local postX = cx + sx
			local pg = grp .. "_Post" .. tostring(si)
			box(f, "LiftBase" .. idx .. si, Vector3.new(3.6, 0.35, 3.6), Vector3.new(postX, FLOOR_TOP + 0.175, cz), C.DARK_STEEL, M.DiamondPlate, 380, pg, 1)
			box(f, "LiftPost" .. idx .. si, Vector3.new(1.25, 13.2, 1.9), Vector3.new(postX, FLOOR_TOP + 6.6, cz), C.STEEL, M.Metal, 460, pg, 2)
			box(f, "LiftPostCap" .. idx .. si, Vector3.new(1.45, 0.5, 2.1), Vector3.new(postX, FLOOR_TOP + 13.4, cz), C.DARK_STEEL, M.Metal, 240, pg, 3)
			cyl(f, "LiftRam" .. idx .. si, Vector3.new(9.4, 0.8, 0.8), CFrame.new(postX, FLOOR_TOP + 6.4, cz + 0.6) * CFrame.Angles(0, 0, math.rad(90)), C.CHROME, M.Metal, 260, pg .. "_Ram", 2)
			-- 2 tay đòn + đệm cao su đỡ gầm xe
			for ai, az in ipairs({ -3.6, 3.6 }) do
				local inner = if sx < 0 then 1 else -1
				local ag = pg .. "_Arm" .. tostring(ai)
				box(f, "LiftArm" .. idx .. si .. ai, Vector3.new(3.6, 0.36, 0.9), Vector3.new(postX + inner * 2.0, FLOOR_TOP + 5.3, cz + az), C.STEEL, M.Metal, 160, ag, 3)
				box(f, "LiftArmPad" .. idx .. si .. ai, Vector3.new(0.95, 0.5, 1.0), Vector3.new(postX + inner * 3.6, FLOOR_TOP + 5.65, cz + az), C.YELLOW, M.Rubber, 90, ag, 4)
			end
			-- bơm thuỷ lực đặt sau trụ
			box(f, "LiftPump" .. idx .. si, Vector3.new(2.2, 2.0, 1.6), Vector3.new(postX + sx * 0.18, FLOOR_TOP + 1.0, cz - 2.6), C.RED_DARK, M.Metal, 150, pg .. "_Pump", 1)
			-- ốp che cáp
			box(f, "LiftCableCover" .. idx .. si, Vector3.new(1.35, 11.2, 0.3), Vector3.new(postX, FLOOR_TOP + 7.0, cz + 1.05), C.DARK_STEEL, M.Metal, 120, pg .. "_Cover", 3, { canCollide = false })
		end
		-- Dầm nối trên đỉnh 2 trụ
		box(f, "LiftCrossbar" .. idx, Vector3.new(14.6, 1.0, 1.1), Vector3.new(cx, FLOOR_TOP + 13.1, cz), C.STEEL, M.Metal, 340, grp .. "_Crossbar", 4)
		box(f, "LiftCrossbarLabel" .. idx, Vector3.new(6.0, 1.6, 0.2), Vector3.new(cx, FLOOR_TOP + 13.1, cz + 0.65), C.LSC_BLUE, M.Metal, 60, grp .. "_Crossbar", 4)
		drawText(f, "LiftBrandText" .. idx, "LSC", cx - 3.1, FLOOR_TOP + 12.5, cz + 0.78, 0.12, 0.2, C.NEON_WHITE, M.Neon, 25, grp .. "_Brand", 5)
		-- Bảng điều khiển trên 1 trụ
		box(f, "LiftControlBox" .. idx, Vector3.new(1.9, 3.0, 0.7), Vector3.new(cx + 6.6 + 0.2, FLOOR_TOP + 4.4, cz + 1.5), C.RED, M.Metal, 130, grp .. "_Control", 3)
		for bi, bc in ipairs({ C.NEON_GREEN, C.NEON_YELLOW, C.NEON_RED }) do
			box(f, "LiftButton" .. idx .. bi, Vector3.new(0.5, 0.5, 0.18), Vector3.new(cx + 6.6 + 0.2, FLOOR_TOP + 5.2 - (bi - 1) * 0.8, cz + 1.9), bc, M.Neon, 15, grp .. "_Control", 4, { canCollide = false, castShadow = false })
		end
		-- Ống dầu thuỷ lực chạy trên sàn
		strut(f, "LiftHose" .. idx, Vector3.new(cx - 6.6, FLOOR_TOP + 0.6, cz - 2.6), Vector3.new(cx + 6.6, FLOOR_TOP + 0.6, cz - 2.6), 0.22, C.BLACK, M.Rubber, 40, grp .. "_Hose", 1, { canCollide = false })

		-- Dụng cụ kê dưới gầm: giá đỡ trục, kích cá sấu, thùng hứng dầu
		box(f, "LiftOilDrain" .. idx, Vector3.new(2.6, 2.0, 2.2), Vector3.new(cx, FLOOR_TOP + 1.0, cz + 9.4), C.RED, M.Metal, 110, grp .. "_OilDrain", 1)
		vcyl(f, "LiftOilDrainTank" .. idx, Vector3.new(2.0, 1.6, 1.6), Vector3.new(cx, FLOOR_TOP + 2.3, cz + 9.4), C.DARK_STEEL, M.Metal, 80, grp .. "_OilDrain", 2)
		for ai, ax in ipairs({ -4.2, 4.2 }) do
			box(f, "JackStand" .. idx .. ai, Vector3.new(0.9, 3.4, 0.9), Vector3.new(cx + ax, FLOOR_TOP + 1.7, cz + 11.6), C.YELLOW, M.Metal, 90, grp .. "_JackStand" .. tostring(ai), 1)
			box(f, "JackStandFoot" .. idx .. ai, Vector3.new(2.0, 0.3, 1.8), Vector3.new(cx + ax, FLOOR_TOP + 0.15, cz + 11.6), C.DARK_STEEL, M.Metal, 70, grp .. "_JackStand" .. tostring(ai), 1)
		end
		box(f, "FloorJack" .. idx, Vector3.new(4.2, 0.9, 1.8), Vector3.new(cx - 7.6, FLOOR_TOP + 0.55, cz + 12.2), C.RED, M.Metal, 100, grp .. "_FloorJack", 1)
		cyl(f, "FloorJackHandle" .. idx, Vector3.new(3.8, 0.2, 0.2), CFrame.new(cx - 9.2, FLOOR_TOP + 2.25, cz + 12.2) * CFrame.Angles(0, 0, math.rad(58)), C.CHROME, M.Metal, 50, grp .. "_FloorJack", 2)
	end
end

-- =============================================================================
-- 12. GÓC ĐỒ NGHỀ TƯỜNG TÂY (BÀN THỢ, TỦ ĐỎ, PÉGBOARD, MÁY NÉN KHÍ...)
-- =============================================================================
local function buildToolWall(root: Instance)
	local f = folder("07_ToolWallWest", root)
	local wx = IN_X0 -- -270.3 (mặt trong tường Tây)

	-- Bàn thợ dài 13 studs
	local benchGrp = "LSC_Workbench"
	box(f, "BenchTop", Vector3.new(2.9, 0.4, 13.0), Vector3.new(wx + 1.5, 3.95, 26.5), C.WOOD, M.Wood, 150, benchGrp .. "_Top", 1)
	box(f, "BenchFrame", Vector3.new(2.5, 0.3, 12.4), Vector3.new(wx + 1.5, 2.35, 26.5), C.DARK_STEEL, M.Metal, 130, benchGrp .. "_Frame", 1)
	box(f, "BenchShelf", Vector3.new(2.5, 0.22, 12.4), Vector3.new(wx + 1.5, 2.2, 26.5), C.GALV, M.Metal, 110, benchGrp .. "_Shelf", 1)
	for i = 1, 4 do
		local z = 20.9 + (i - 1) * 3.7
		box(f, "BenchLeg" .. i, Vector3.new(0.24, 3.6, 0.24), Vector3.new(wx + 0.35, FLOOR_TOP + 1.8, z), C.DARK_STEEL, M.Metal, 100, benchGrp .. "_Leg" .. i, 1)
		box(f, "BenchLegOuter" .. i, Vector3.new(0.24, 3.6, 0.24), Vector3.new(wx + 2.65, FLOOR_TOP + 1.8, z), C.DARK_STEEL, M.Metal, 100, benchGrp .. "_Leg" .. i, 1)
	end

	-- Ê-tô + máy mài 2 đá
	box(f, "BenchVise", Vector3.new(1.5, 1.1, 2.6), Vector3.new(wx + 1.4, 4.7, 21.6), C.STEEL, M.Metal, 90, "LSC_Vise", 2)
	box(f, "BenchViseJaw", Vector3.new(1.6, 0.5, 0.4), Vector3.new(wx + 0.9, 4.9, 21.6), C.CHROME, M.Metal, 60, "LSC_Vise", 3)
	box(f, "BenchGrinder", Vector3.new(1.3, 1.2, 2.4), Vector3.new(wx + 1.5, 4.75, 31.0), C.DARK_STEEL, M.Metal, 80, "LSC_Grinder", 2)
	cyl(f, "BenchGrinderWheelA", Vector3.new(0.6, 1.8, 1.8), CFrame.new(wx + 1.0, 4.7, 30.3), C.CONCRETE_DARK, M.Concrete, 50, "LSC_Grinder", 3)
	cyl(f, "BenchGrinderWheelB", Vector3.new(0.6, 1.8, 1.8), CFrame.new(wx + 1.0, 4.7, 31.7), C.CONCRETE_DARK, M.Concrete, 50, "LSC_Grinder", 3)

	-- Pégbard treo dụng cụ + cờ lê, tua vít, búa
	box(f, "Pegboard", Vector3.new(0.26, 4.6, 13.0), Vector3.new(wx + 0.15, 6.6, 26.5), Color3.fromRGB(196, 190, 176), M.WoodPlanks, 120, "LSC_Pegboard", 2)
	for i = 1, 10 do
		local z = 20.9 + (i - 1) * 1.24
		box(f, "Wrench" .. i, Vector3.new(0.16, 2.1, 0.34), Vector3.new(wx + 0.36, 7.0, z), C.CHROME, M.Metal, 25, "LSC_Wrench" .. i, 3, { canCollide = false, castShadow = false })
		box(f, "WrenchHead" .. i, Vector3.new(0.16, 0.4, 0.7), Vector3.new(wx + 0.36, 8.15, z), C.CHROME, M.Metal, 25, "LSC_Wrench" .. i, 3, { canCollide = false, castShadow = false })
	end
	for i = 1, 6 do
		local z = 21.4 + (i - 1) * 2.1
		box(f, "Screwdriver" .. i, Vector3.new(0.14, 1.5, 0.2), Vector3.new(wx + 0.36, 5.5, z), if i % 2 == 0 then C.RED else C.YELLOW, M.SmoothPlastic, 20, "LSC_Tools" .. i, 3, { canCollide = false, castShadow = false })
	end
	box(f, "Hammer", Vector3.new(0.18, 1.9, 0.28), Vector3.new(wx + 0.36, 5.9, 32.0), C.WOOD, M.Wood, 25, "LSC_Hammer", 3, { canCollide = false, castShadow = false })
	box(f, "HammerHead", Vector3.new(0.3, 0.45, 1.1), Vector3.new(wx + 0.36, 6.85, 32.0), C.STEEL, M.Metal, 30, "LSC_Hammer", 3, { canCollide = false, castShadow = false })

	-- Khoang kệ nhựa đựng ốc vít (3 hàng x 5 ô)
	for r = 1, 3 do
		for c = 1, 5 do
			local z = 20.6 + (c - 1) * 2.55
			local y = 9.7 + (r - 1) * 1.9
			box(f, "Bin" .. r .. "_" .. c, Vector3.new(1.0, 1.6, 2.3), Vector3.new(wx + 0.55, y, z), Color3.fromRGB(186, 192, 200), M.SmoothPlastic, 35, "LSC_Bins" .. r .. "_" .. c, 4)
			box(f, "BinLabel" .. r .. "_" .. c, Vector3.new(0.1, 0.5, 1.6), Vector3.new(wx + 1.06, y, z), if c % 2 == 0 then C.YELLOW else C.WHITE, M.SmoothPlastic, 15, "LSC_Bins" .. r .. "_" .. c, 5, { canCollide = false, castShadow = false })
		end
	end

	-- 3 tủ đồ nghề đỏ GTA (Snap-on style) + tay kéo
	for i = 1, 3 do
		local z = 35.2 + (i - 1) * 5.2
		local grp = "LSC_ToolChest" .. tostring(i)
		box(f, "ChestBody" .. i, Vector3.new(2.9, 4.8, 4.6), Vector3.new(wx + 1.6, FLOOR_TOP + 2.4, z), TOOL_RED, M.Metal, 220, grp .. "_Body", 1)
		box(f, "ChestTop" .. i, Vector3.new(3.05, 0.3, 4.75), Vector3.new(wx + 1.6, FLOOR_TOP + 4.95, z), C.DARK_STEEL, M.DiamondPlate, 120, grp .. "_Top", 2)
		for d = 1, 4 do
			box(f, "ChestDrawer" .. i .. "_" .. d, Vector3.new(0.16, 0.82, 4.2), Vector3.new(wx + 3.08, FLOOR_TOP + 0.9 + (d - 1) * 1.05, z), C.RED_DARK, M.Metal, 70, grp .. "_Drawer" .. d, 2, { canCollide = false })
			box(f, "ChestHandle" .. i .. "_" .. d, Vector3.new(0.14, 0.14, 2.6), Vector3.new(wx + 3.2, FLOOR_TOP + 0.9 + (d - 1) * 1.05, z), C.CHROME, M.Metal, 25, grp .. "_Drawer" .. d, 3, { canCollide = false, castShadow = false })
		end
		for _, wz in ipairs({ -1, 1 }) do
			box(f, "ChestWheel" .. i .. tostring(wz), Vector3.new(0.7, 0.7, 0.4), Vector3.new(wx + 1.6 + wz * 1.1, FLOOR_TOP + 0.35, z + 2.1), C.BLACK, M.Rubber, 45, grp .. "_Wheel" .. tostring(wz), 1)
			box(f, "ChestWheel2" .. i .. tostring(wz), Vector3.new(0.7, 0.7, 0.4), Vector3.new(wx + 1.6 + wz * 1.1, FLOOR_TOP + 0.35, z - 2.1), C.BLACK, M.Rubber, 45, grp .. "_Wheel" .. tostring(wz), 1)
		end
	end

	-- Xe đẩy đồ nghề 4 tầng + kích
	local cg = "LSC_ToolCart"
	box(f, "ToolCartBody", Vector3.new(2.6, 3.6, 4.2), Vector3.new(-263.4, FLOOR_TOP + 1.9, 30.5), C.RED, M.Metal, 140, cg .. "_Body", 1)
	box(f, "ToolCartTop", Vector3.new(2.9, 0.25, 4.5), Vector3.new(-263.4, FLOOR_TOP + 3.85, 30.5), C.DARK_STEEL, M.DiamondPlate, 90, cg .. "_Top", 2)
	for d = 1, 3 do
		box(f, "ToolCartDrawer" .. d, Vector3.new(2.75, 0.72, 3.9), Vector3.new(-263.4, FLOOR_TOP + 0.85 + (d - 1) * 1.0, 30.5), C.RED_DARK, M.Metal, 55, cg .. "_Drawer" .. d, 2, { canCollide = false })
	end
	for i = 1, 4 do
		local dx = if i <= 2 then -1 else 1
		local dz = if i % 2 == 0 then -1 else 1
		cyl(f, "CartWheel" .. i, Vector3.new(0.35, 0.8, 0.8), CFrame.new(-263.4 + dx * 1.05, FLOOR_TOP + 0.4, 30.5 + dz * 1.75), C.BLACK, M.Rubber, 40, cg .. "_Wheel" .. i, 1)
	end

	-- Máy nén khí đặt góc sau Tây
	local acGrp = "LSC_AirCompressor"
	cyl(f, "CompressorTank", Vector3.new(6.4, 2.6, 2.6), CFrame.new(wx + 1.8, FLOOR_TOP + 1.9, -3.0) * CFrame.Angles(0, math.rad(90), 0), C.RED, M.Metal, 260, acGrp .. "_Tank", 1)
	box(f, "CompressorMotor", Vector3.new(2.2, 2.0, 2.2), Vector3.new(wx + 1.8, FLOOR_TOP + 3.6, -1.0), C.DARK_STEEL, M.Metal, 180, acGrp .. "_Motor", 2)
	cyl(f, "CompressorPulley", Vector3.new(0.5, 1.6, 1.6), CFrame.new(wx + 1.8, FLOOR_TOP + 3.6, -2.2) * CFrame.Angles(0, math.rad(90), 0), C.CHROME, M.Metal, 80, acGrp .. "_Pulley", 3)
	box(f, "CompressorGauge", Vector3.new(0.2, 1.0, 1.0), Vector3.new(wx + 2.7, FLOOR_TOP + 3.0, 0.2), C.GALV, M.Metal, 40, acGrp .. "_Gauge", 3, { canCollide = false })
	strut(f, "CompressorHose", Vector3.new(wx + 1.8, FLOOR_TOP + 4.4, -3.0), Vector3.new(wx + 1.8, 12.2, -3.0), 0.22, C.BLACK, M.Rubber, 30, acGrp .. "_Hose", 4, { canCollide = false })

	-- Máy khoan bàn (drill press)
	local dpGrp = "LSC_DrillPress"
	box(f, "DrillBase", Vector3.new(2.6, 0.5, 2.8), Vector3.new(wx + 1.5, FLOOR_TOP + 0.25, 16.5), C.DARK_STEEL, M.Metal, 160, dpGrp .. "_Base", 1)
	vcyl(f, "DrillColumn", Vector3.new(6.4, 0.7, 0.7), Vector3.new(wx + 1.2, FLOOR_TOP + 3.5, 16.5), C.CHROME, M.Metal, 140, dpGrp .. "_Column", 2)
	box(f, "DrillHead", Vector3.new(2.2, 1.8, 3.4), Vector3.new(wx + 1.4, FLOOR_TOP + 6.4, 16.5), C.STEEL, M.Metal, 130, dpGrp .. "_Head", 3)
	vcyl(f, "DrillChuck", Vector3.new(1.4, 0.5, 0.5), Vector3.new(wx + 1.5, FLOOR_TOP + 5.3, 16.5), C.CHROME, M.Metal, 50, dpGrp .. "_Chuck", 4)
	box(f, "DrillTable", Vector3.new(2.0, 0.28, 2.0), Vector3.new(wx + 1.8, FLOOR_TOP + 3.4, 16.5), C.DARK_STEEL, M.DiamondPlate, 70, dpGrp .. "_Table", 2)

	-- Bình chữa cháy + bảng điện + bộ sơ cứu
	vcyl(f, "FireExtinguisher", Vector3.new(2.6, 1.1, 1.1), Vector3.new(wx + 0.55, 2.9, 44.0), C.RED, M.Metal, 90, "LSC_FireExtinguisher", 1)
	box(f, "FireExtPlate", Vector3.new(0.2, 1.6, 1.6), Vector3.new(wx + 0.2, 4.6, 44.0), C.RED, M.Metal, 30, "LSC_FireExtSign", 1, { canCollide = false })
	box(f, "BreakerPanel", Vector3.new(0.5, 5.4, 4.0), Vector3.new(wx + 0.35, 8.4, 46.0), C.GALV, M.Metal, 110, "LSC_BreakerPanel", 1)
	for i = 1, 6 do
		box(f, "Breaker" .. i, Vector3.new(0.14, 0.5, 0.7), Vector3.new(wx + 0.62, 9.6 - (i - 1) * 0.55, 46.0), C.BLACK, M.SmoothPlastic, 20, "LSC_BreakerPanel", 2, { canCollide = false })
	end
	box(f, "FirstAidBox", Vector3.new(0.4, 2.4, 2.6), Vector3.new(wx + 0.3, 4.6, 40.0), C.WHITE, M.SmoothPlastic, 40, "LSC_FirstAid", 1)
	box(f, "FirstAidCross", Vector3.new(0.16, 0.9, 0.28), Vector3.new(wx + 0.52, 4.6, 40.0), C.RED, M.SmoothPlastic, 15, "LSC_FirstAid", 2, { canCollide = false })
	box(f, "FirstAidCrossH", Vector3.new(0.16, 0.28, 0.9), Vector3.new(wx + 0.52, 4.6, 40.0), C.RED, M.SmoothPlastic, 15, "LSC_FirstAid", 2, { canCollide = false })
end

-- =============================================================================
-- 13. KHO PHỤ TÙNG TƯỜNG HẬU + GIÁ LỐP + THÙNG PHUY
-- =============================================================================
local function buildBackStorage(root: Instance)
	local f = folder("08_BackStorageAndTires", root)

	-- 3 cụm kệ sắt 4 tầng đầy phụ tùng
	for u = 1, 3 do
		local x0 = -266.0 + (u - 1) * 10.5
		local grp = "LSC_ShelfUnit" .. tostring(u)
		box(f, "ShelfUprightA" .. u, Vector3.new(0.3, 11.0, 2.4), Vector3.new(x0, FLOOR_TOP + 5.5, IN_Z0 + 1.4), C.STEEL, M.Metal, 200, grp .. "_UprightA", 1)
		box(f, "ShelfUprightB" .. u, Vector3.new(0.3, 11.0, 2.4), Vector3.new(x0 + 9.0, FLOOR_TOP + 5.5, IN_Z0 + 1.4), C.STEEL, M.Metal, 200, grp .. "_UprightB", 1)
		for s = 1, 4 do
			local y = FLOOR_TOP + 1.0 + (s - 1) * 3.1
			box(f, "ShelfPlank" .. u .. "_" .. s, Vector3.new(9.3, 0.24, 2.3), Vector3.new(x0 + 4.5, y, IN_Z0 + 1.4), C.GALV, M.Metal, 110, grp .. "_Plank" .. s, s)
			-- hộp phụ tùng trên kệ
			for b = 1, 3 do
				local bx = x0 + 1.5 + (b - 1) * 3.0
				local bcol = if (b + s) % 3 == 0 then C.YELLOW elseif (b + s) % 3 == 1 then C.LSC_BLUE_LIGHT else C.WHITE
				box(f, "ShelfBox" .. u .. "_" .. s .. "_" .. b, Vector3.new(2.4, 1.7, 1.9), Vector3.new(bx, y + 0.97, IN_Z0 + 1.4), bcol, M.Cardboard, 60, grp .. "_Box" .. s .. b, s + 1)
			end
		end
	end

	-- Hàng 4 thùng phuy dầu (xanh/vằn) + bệ đỡ chống tràn
	local drumZ = -3.4
	box(f, "DrumBund", Vector3.new(11.0, 0.5, 5.0), Vector3.new(-227.0, FLOOR_TOP + 0.25, drumZ), C.CONCRETE_DARK, M.Concrete, 220, "LSC_DrumBund", 1)
	for i = 1, 4 do
		local dx = -231.5 + (i - 1) * 3.0
		local col = if i % 2 == 0 then C.BLUE_DRUM else C.GREEN_DRUM
		oilDrum(f, "OilDrum" .. i, Vector3.new(dx, FLOOR_TOP + 2.2, drumZ), col, "LSC_OilDrum" .. tostring(i), 130)
	end
	-- Thùng phuy nằm ngang làm giá đỡ (góc Đông)
	oilDrum(f, "OilDrumLying1", Vector3.new(-200.0, FLOOR_TOP + 1.15, -2.0), C.RED, "LSC_OilDrumLying1", 110, true)

	-- Giá lốp đứng: 3 cụm x 4 lốp
	for r = 1, 3 do
		local x0 = -220.0 + (r - 1) * 7.6
		local grp = "LSC_TireRack" .. tostring(r)
		box(f, "TireRackPostA" .. r, Vector3.new(0.28, 9.0, 0.28), Vector3.new(x0, FLOOR_TOP + 4.5, IN_Z0 + 8.6), C.ORANGE_TOOL, M.Metal, 140, grp .. "_PostA", 1)
		box(f, "TireRackPostB" .. r, Vector3.new(0.28, 9.0, 0.28), Vector3.new(x0 + 6.8, FLOOR_TOP + 4.5, IN_Z0 + 8.6), C.ORANGE_TOOL, M.Metal, 140, grp .. "_PostB", 1)
		for lv = 1, 3 do
			local y = FLOOR_TOP + 1.4 + (lv - 1) * 3.0
			box(f, "TireRackBeam" .. r .. "_" .. lv, Vector3.new(7.2, 0.2, 0.24), Vector3.new(x0 + 3.4, y, IN_Z0 + 8.6), C.ORANGE_TOOL, M.Metal, 90, grp .. "_Beam" .. lv, lv)
			for t = 1, 2 do
				tire(
					f,
					"RackTire" .. r .. "_" .. lv .. "_" .. t,
					Vector3.new(x0 + 1.9 + (t - 1) * 3.2, y + 1.35, IN_Z0 + 8.6),
					2.65,
					0.92,
					false,
					grp .. "_Tire" .. lv .. t,
					70
				)
			end
		end
	end

	-- Máy rửa phụ tùng + bồn dầu thải + tủ sạc ắc quy
	box(f, "PartsWasher", Vector3.new(4.6, 4.4, 3.2), Vector3.new(-244.0, FLOOR_TOP + 2.2, -2.4), Color3.fromRGB(70, 96, 110), M.Metal, 180, "LSC_PartsWasher", 1)
	box(f, "PartsWasherLid", Vector3.new(4.8, 0.3, 3.4), Vector3.new(-244.0, FLOOR_TOP + 4.5, -2.4), C.DARK_STEEL, M.Metal, 110, "LSC_PartsWasher", 2)
	vcyl(f, "WasteOilTank", Vector3.new(5.2, 3.4, 3.4), Vector3.new(-190.0, FLOOR_TOP + 2.65, -3.0), C.DARK_STEEL, M.Metal, 220, "LSC_WasteOilTank", 1)
	box(f, "BatteryCabinet", Vector3.new(3.4, 5.6, 2.6), Vector3.new(-182.0, FLOOR_TOP + 2.8, -2.6), C.STEEL, M.Metal, 160, "LSC_BatteryCabinet", 1)
	box(f, "BatteryCabinetDoor", Vector3.new(3.0, 4.6, 0.16), Vector3.new(-182.0, FLOOR_TOP + 2.9, -1.25), C.GALV, M.Metal, 70, "LSC_BatteryCabinet", 2)

	-- Cửa hông EXIT tường Bắc + thanh đẩy + đèn EXIT
	local eg = "LSC_ExitDoor"
	box(f, "ExitDoorLeaf", Vector3.new(6.5, 8.4, 0.4), Vector3.new(-212.75, FLOOR_TOP + 4.2, BACK_ZC + 0.2), Color3.fromRGB(140, 148, 150), M.Metal, 240, eg .. "_Leaf", 1)
	box(f, "ExitDoorPushBar", Vector3.new(5.7, 0.36, 0.4), Vector3.new(-212.75, FLOOR_TOP + 3.4, BACK_ZC + 0.55), C.CHROME, M.Metal, 90, eg .. "_Bar", 2)
	box(f, "ExitDoorFrameT", Vector3.new(7.5, 0.5, 0.7), Vector3.new(-212.75, FLOOR_TOP + 8.65, BACK_ZC + 0.2), C.DARK_STEEL, M.Metal, 140, eg .. "_Frame", 1)
	box(f, "ExitSignBox", Vector3.new(10.0, 1.6, 0.5), Vector3.new(-212.75, 12.4, BACK_ZC + 0.45), C.BLACK, M.Metal, 40, "LSC_ExitSign", 1, { canCollide = false })
	drawText(f, "ExitSignText", "EXIT", -218.1, 11.75, BACK_ZC + 0.63, 0.14, 0.32, C.NEON_GREEN, M.Neon, 20, "LSC_ExitSign", 2)

	-- Bảng treo "PARTS DEPT" trên kệ
	box(f, "PartsDeptBoard", Vector3.new(14.0, 3.2, 0.3), Vector3.new(-252.0, 14.6, -5.6), C.LSC_BLUE, M.Metal, 70, "LSC_PartsBoard", 1)
	drawText(f, "PartsDeptText", "PARTS", -258.75, 13.75, -5.4, 0.14, 0.36, C.NEON_WHITE, M.Neon, 25, "LSC_PartsBoard", 2)
end

-- =============================================================================
-- 14. KHU TIẾP KHÁCH SAU VÁCH KÍNH (QUẦY THU NGÂN, SOFA, TV, MÁY BÁN HÀNG)
-- =============================================================================
local function buildCustomerLounge(root: Instance)
	local f = folder("09_CustomerLounge", root)
	local px = -217.0 -- mặt phẳng vách kính ngăn xưởng

	-- Vách kính ngăn xưởng: trụ thép + ô kính rời + ô cửa thông 7.6 studs
	local postZ = { 18.0, 25.5, 33.7, 41.3, 49.8 }
	for i, z in ipairs(postZ) do
		box(f, "PartitionPost" .. i, Vector3.new(0.7, 11.5, 0.7), Vector3.new(px, FLOOR_TOP + 5.75, z), C.DARK_STEEL, M.Metal, 210, "LSC_PartitionPost" .. i, 1)
		box(f, "PartitionPostBase" .. i, Vector3.new(1.1, 0.5, 1.1), Vector3.new(px, FLOOR_TOP + 0.25, z), C.STEEL, M.Metal, 160, "LSC_PartitionPost" .. i, 1)
	end
	local panes = { { 18.4, 25.1 }, { 34.1, 41.0 }, { 41.6, 49.4 } }
	for i, p in ipairs(panes) do
		glassPane(f, "PartitionGlass" .. i, "Z", px, p[1], p[2], FLOOR_TOP + 0.5, 12.8, 45, "LSC_PartitionGlass" .. i, 2, C.GLASS)
		box(f, "PartitionRail" .. i, Vector3.new(0.9, 0.4, p[2] - p[1]), Vector3.new(px, FLOOR_TOP + 0.4, (p[1] + p[2]) * 0.5), C.DARK_STEEL, M.Metal, 120, "LSC_PartitionRail" .. i, 1)
	end
	-- Dầm trên + ô kính trên cửa thông
	box(f, "PartitionHeader", Vector3.new(0.8, 0.55, 31.8), Vector3.new(px, 12.95, 33.9), C.DARK_STEEL, M.Metal, 180, "LSC_PartitionHeader", 3)
	glassPane(f, "PartitionGlassDoorTop", "Z", px, 25.8, 33.5, 9.9, 12.7, 45, "LSC_PartitionTop", 3, C.GLASS)
	box(f, "PartitionDoorHead", Vector3.new(0.85, 0.5, 7.7), Vector3.new(px, 9.9, 29.65), C.DARK_STEEL, M.Metal, 140, "LSC_PartitionTop", 3)

	-- QUẦY THU NGÂN chữ L
	local cg = "LSC_ReceptionCounter"
	box(f, "CounterFront", Vector3.new(13.0, 4.2, 3.0), Vector3.new(-204.5, FLOOR_TOP + 2.1, 42.5), C.LSC_BLUE, M.Metal, 240, cg .. "_Front", 1)
	box(f, "CounterReturn", Vector3.new(3.0, 4.2, 6.5), Vector3.new(-212.5, FLOOR_TOP + 2.1, 39.0), C.LSC_BLUE, M.Metal, 240, cg .. "_Return", 1)
	box(f, "CounterTop", Vector3.new(13.8, 0.35, 3.6), Vector3.new(-204.5, FLOOR_TOP + 4.35, 42.4), C.GRANITE, M.Granite, 200, cg .. "_Top", 2)
	box(f, "CounterTopReturn", Vector3.new(3.6, 0.32, 7.0), Vector3.new(-212.4, FLOOR_TOP + 4.32, 39.0), C.GRANITE, M.Granite, 200, cg .. "_Top", 2)
	box(f, "CounterKick", Vector3.new(12.6, 0.9, 0.3), Vector3.new(-204.5, FLOOR_TOP + 0.45, 44.1), C.CHROME, M.Metal, 90, cg .. "_Kick", 1, { canCollide = false })
	-- Logo LSC trên mặt quầy
	drawText(f, "CounterLogo", "LSC", -210.35, FLOOR_TOP + 1.5, 44.16, 0.14, 0.45, C.NEON_WHITE, M.Neon, 30, cg .. "_Logo", 3)

	-- Máy tính tiền, màn hình, điện thoại, chuông, đầu đọc thẻ
	box(f, "RegisterBase", Vector3.new(2.4, 1.3, 2.0), Vector3.new(-200.5, FLOOR_TOP + 5.15, 42.4), C.DARK_STEEL, M.Metal, 70, "LSC_Register", 3)
	box(f, "RegisterScreen", Vector3.new(2.1, 1.3, 0.2), Vector3.new(-200.5, FLOOR_TOP + 6.6, 41.9), C.LSC_BLUE_LIGHT, M.Glass, 30, "LSC_Register", 4, { canCollide = false })
	box(f, "RegisterKeypad", Vector3.new(1.8, 0.2, 1.3), Vector3.new(-200.5, FLOOR_TOP + 5.9, 42.9), C.BLACK, M.SmoothPlastic, 20, "LSC_Register", 4, { canCollide = false })
	box(f, "MonitorStan", Vector3.new(0.6, 1.4, 0.6), Vector3.new(-208.5, FLOOR_TOP + 5.2, 42.4), C.DARK_STEEL, M.Metal, 30, "LSC_Monitor", 3)
	box(f, "MonitorScreen", Vector3.new(5.0, 3.0, 0.25), Vector3.new(-208.5, FLOOR_TOP + 6.9, 42.3), C.BLACK, M.SmoothPlastic, 40, "LSC_Monitor", 4)
	box(f, "MonitorGlow", Vector3.new(4.6, 2.6, 0.1), Vector3.new(-208.5, FLOOR_TOP + 6.9, 42.15), Color3.fromRGB(58, 96, 132), M.Neon, 20, "LSC_Monitor", 5, { canCollide = false, castShadow = false })
	box(f, "Keyboard", Vector3.new(3.0, 0.18, 1.2), Vector3.new(-208.5, FLOOR_TOP + 4.6, 43.6), C.BLACK, M.SmoothPlastic, 20, "LSC_Keyboard", 3, { canCollide = false })
	box(f, "DeskPhone", Vector3.new(1.6, 0.5, 1.0), Vector3.new(-204.5, FLOOR_TOP + 4.7, 42.0), C.BLACK, M.SmoothPlastic, 20, "LSC_Phone", 3, { canCollide = false })
	box(f, "ServiceBell", Vector3.new(0.8, 0.6, 0.8), Vector3.new(-197.5, FLOOR_TOP + 4.8, 43.2), C.YELLOW, M.Metal, 20, "LSC_ServiceBell", 3, { canCollide = false })
	box(f, "CardReader", Vector3.new(1.1, 1.6, 0.6), Vector3.new(-196.0, FLOOR_TOP + 5.1, 42.6), C.DARK_STEEL, M.Metal, 25, "LSC_CardReader", 3)
	box(f, "ReceiptPrinter", Vector3.new(1.8, 1.2, 1.6), Vector3.new(-202.5, FLOOR_TOP + 5.1, 43.3), C.GALV, M.Metal, 30, "LSC_Printer", 3)
	-- Ghế nhân viên + tủ hồ sơ sau quầy
	vcyl(f, "CounterStoolPost", Vector3.new(1.9, 0.35, 0.35), Vector3.new(-206.0, FLOOR_TOP + 1.25, 39.6), C.CHROME, M.Metal, 40, "LSC_CounterStool", 1)
	box(f, "CounterStoolSeat", Vector3.new(2.2, 0.4, 2.2), Vector3.new(-206.0, FLOOR_TOP + 2.5, 39.6), C.LEATHER, M.Fabric, 40, "LSC_CounterStool", 2)
	box(f, "CounterStoolBack", Vector3.new(2.2, 1.8, 0.3), Vector3.new(-206.0, FLOOR_TOP + 3.4, 38.6), C.LEATHER, M.Fabric, 40, "LSC_CounterStool", 2)
	box(f, "FileCabinet", Vector3.new(3.6, 6.0, 2.6), Vector3.new(-214.6, FLOOR_TOP + 3.0, 45.6), C.STEEL, M.Metal, 180, "LSC_FileCabinet", 1)
	for d = 1, 3 do
		box(f, "FileDrawer" .. d, Vector3.new(3.2, 1.5, 0.18), Vector3.new(-214.6, FLOOR_TOP + 1.4 + (d - 1) * 1.8, 44.25), C.GALV, M.Metal, 60, "LSC_FileCabinet" .. d, 2, { canCollide = false })
		box(f, "FileHandle" .. d, Vector3.new(1.4, 0.16, 0.16), Vector3.new(-214.6, FLOOR_TOP + 1.4 + (d - 1) * 1.8, 44.1), C.CHROME, M.Metal, 20, "LSC_FileCabinet" .. d, 3, { canCollide = false })
	end

	-- SOFA CHỜ 2 bộ đối diện + bàn cà phê + thảm
	box(f, "LoungeRug", Vector3.new(21.0, 0.06, 15.0), Vector3.new(-186.0, FLOOR_TOP + 0.06, 40.0), Color3.fromRGB(58, 62, 74), M.Fabric, 30, "LSC_LoungeRug", 1, { canCollide = false, castShadow = false })
	local function sofa(name: string, cx: number, cz: number, w: number, faceZ: number)
		local grp = "LSC_Sofa_" .. name
		box(f, name .. "Seat", Vector3.new(w, 1.3, 3.4), Vector3.new(cx, FLOOR_TOP + 0.85, cz), C.LEATHER, M.Fabric, 130, grp .. "_Seat", 1)
		box(f, name .. "Back", Vector3.new(w, 3.0, 1.0), Vector3.new(cx, FLOOR_TOP + 2.4, cz - faceZ * 1.3), C.LEATHER, M.Fabric, 130, grp .. "_Back", 2)
		for _, sx in ipairs({ -1, 1 }) do
			box(f, name .. "Arm" .. tostring(sx), Vector3.new(1.0, 2.0, 3.4), Vector3.new(cx + sx * (w * 0.5 - 0.5), FLOOR_TOP + 1.5, cz), C.LEATHER, M.Fabric, 100, grp .. "_Arm" .. tostring(sx), 2)
		end
		box(f, name .. "Base", Vector3.new(w - 1.4, 0.5, 2.8), Vector3.new(cx, FLOOR_TOP + 0.3, cz), C.DARK_STEEL, M.Metal, 80, grp .. "_Base", 1)
		for p = 1, 2 do
			box(f, name .. "Cushion" .. p, Vector3.new(w * 0.42, 0.9, 0.5), Vector3.new(cx + (p - 1.5) * (w * 0.22), FLOOR_TOP + 2.0, cz - faceZ * 0.75), Color3.fromRGB(64, 68, 78), M.Fabric, 60, grp .. "_Cushion" .. p, 3)
		end
	end
	sofa("SofaA", -186.0, 45.6, 9.0, 1)
	sofa("SofaB", -186.0, 34.4, 9.0, -1)
	box(f, "CoffeeTableTop", Vector3.new(8.0, 0.3, 4.6), Vector3.new(-186.0, FLOOR_TOP + 2.25, 40.0), C.WOOD, M.Wood, 110, "LSC_CoffeeTable", 1)
	box(f, "CoffeeTableBase", Vector3.new(3.2, 2.1, 2.0), Vector3.new(-186.0, FLOOR_TOP + 1.05, 40.0), C.DARK_STEEL, M.Metal, 90, "LSC_CoffeeTable", 1)
	for i = 1, 3 do
		box(f, "Magazine" .. i, Vector3.new(2.0, 0.12, 2.6), Vector3.new(-188.5 + (i - 1) * 2.4, FLOOR_TOP + 2.45, 39.8), if i == 2 then C.NEON_ORANGE else C.WHITE, M.SmoothPlastic, 15, "LSC_Magazine" .. i, 2, { canCollide = false, castShadow = false })
	end
	-- Ghế đơn góc
	for i, pos in ipairs({ { -174.5, 44.0 }, { -174.5, 36.5 } }) do
		local grp = "LSC_ArmChair" .. i
		box(f, "ArmChair" .. i .. "Seat", Vector3.new(3.4, 1.3, 3.4), Vector3.new(pos[1], FLOOR_TOP + 0.85, pos[2]), Color3.fromRGB(92, 74, 58), M.Fabric, 110, grp .. "_Seat", 1)
		box(f, "ArmChair" .. i .. "Back", Vector3.new(3.4, 2.8, 1.0), Vector3.new(pos[1], FLOOR_TOP + 2.4, pos[2] + (if i == 1 then 1.3 else -1.3)), Color3.fromRGB(92, 74, 58), M.Fabric, 110, grp .. "_Back", 2)
	end

	-- TV treo tường Đông + kệ loa + bảng poster
	box(f, "TVBracket", Vector3.new(0.5, 1.4, 3.0), Vector3.new(EAST_XC - 0.15, 9.6, 41.0), C.DARK_STEEL, M.Metal, 60, "LSC_WallTV", 1)
	box(f, "TVFrame", Vector3.new(0.45, 9.0, 15.0), Vector3.new(EAST_XC - 0.55, 9.6, 41.0), C.BLACK, M.SmoothPlastic, 110, "LSC_WallTV", 2)
	box(f, "TVScreen", Vector3.new(0.14, 8.2, 14.2), Vector3.new(EAST_XC - 0.8, 9.6, 41.0), Color3.fromRGB(30, 48, 72), M.Glass, 45, "LSC_WallTV", 3, { canCollide = false, castShadow = false, reflectance = 0.15 })
	drawTextZ(f, "TVLogo", "LSC", EAST_XC - 1.05, 33.6, 6.4, 0.12, 0.5, C.NEON_YELLOW, M.Neon, 20, "LSC_WallTV", 4)
	for i, z in ipairs({ 33.0, 49.0 }) do
		box(f, "TVSpeaker" .. i, Vector3.new(0.5, 2.2, 1.6), Vector3.new(EAST_XC - 0.4, 4.2, z), C.BLACK, M.SmoothPlastic, 40, "LSC_TVSpeaker" .. i, 1)
	end

	-- Máy bán nước tự động phát sáng + bình nước nóng lạnh + máy cà phê
	local vg = "LSC_VendingMachine"
	box(f, "VendingBody", Vector3.new(4.0, 7.6, 3.6), Vector3.new(-170.5, FLOOR_TOP + 3.8, 24.0), C.RED, M.Metal, 260, vg .. "_Body", 1)
	box(f, "VendingGlass", Vector3.new(0.2, 5.6, 3.0), Vector3.new(-168.4, FLOOR_TOP + 4.4, 24.0), C.GLASS, M.Glass, 45, vg .. "_Glass", 2, { transparency = 0.4, canCollide = false })
	box(f, "VendingGlow", Vector3.new(0.12, 6.0, 3.2), Vector3.new(-168.3, FLOOR_TOP + 4.4, 24.0), C.NEON_WHITE, M.Neon, 25, vg .. "_Glow", 3, { canCollide = false, castShadow = false })
	for r = 1, 4 do
		for c = 1, 4 do
			local col = if (r + c) % 4 == 0 then C.NEON_RED elseif (r + c) % 4 == 1 then C.NEON_GREEN elseif (r + c) % 4 == 2 then C.YELLOW else C.NEON_ORANGE
			box(f, "SodaCan" .. r .. "_" .. c, Vector3.new(0.7, 1.1, 0.7), Vector3.new(-168.6, FLOOR_TOP + 2.6 + (r - 1) * 1.35, 22.8 + (c - 1) * 0.78), col, M.Metal, 15, vg .. "_Can" .. r .. c, 2, { canCollide = false, castShadow = false })
		end
	end
	box(f, "VendingSlot", Vector3.new(0.3, 0.9, 2.0), Vector3.new(-168.3, FLOOR_TOP + 1.2, 24.0), C.BLACK, M.SmoothPlastic, 25, vg .. "_Slot", 1, { canCollide = false })
	box(f, "WaterCooler", Vector3.new(2.0, 4.6, 2.0), Vector3.new(-169.0, FLOOR_TOP + 2.3, 30.5), C.WHITE, M.SmoothPlastic, 110, "LSC_WaterCooler", 1)
	vcyl(f, "WaterBottle", Vector3.new(2.4, 1.8, 1.8), Vector3.new(-169.0, FLOOR_TOP + 5.6, 30.5), Color3.fromRGB(140, 196, 216), M.Glass, 40, "LSC_WaterCooler", 2, { transparency = 0.3 })
	box(f, "CoffeeCounter", Vector3.new(3.0, 3.6, 6.0), Vector3.new(-169.5, FLOOR_TOP + 1.8, 18.0), C.WOOD, M.Wood, 150, "LSC_CoffeeCounter", 1)
	box(f, "CoffeeCounterTop", Vector3.new(3.3, 0.28, 6.3), Vector3.new(-169.5, FLOOR_TOP + 3.74, 18.0), C.GRANITE, M.Granite, 100, "LSC_CoffeeCounter", 2)
	box(f, "CoffeeMachine", Vector3.new(2.2, 2.2, 2.4), Vector3.new(-169.5, FLOOR_TOP + 5.0, 16.8), C.DARK_STEEL, M.Metal, 60, "LSC_CoffeeMachine", 3)
	box(f, "CoffeeMachinePanel", Vector3.new(0.2, 1.0, 1.6), Vector3.new(-168.4, FLOOR_TOP + 5.2, 16.8), C.NEON_GREEN, M.Neon, 20, "LSC_CoffeeMachine", 4, { canCollide = false, castShadow = false })
	vcyl(f, "CoffeeCupStack", Vector3.new(1.2, 0.9, 0.9), Vector3.new(-169.5, FLOOR_TOP + 4.4, 19.4), C.WHITE, M.SmoothPlastic, 15, "LSC_CoffeeCounter", 3, { canCollide = false })
	box(f, "SugarBox", Vector3.new(1.2, 0.8, 1.2), Vector3.new(-170.2, FLOOR_TOP + 4.3, 20.6), C.WHITE, M.SmoothPlastic, 15, "LSC_CoffeeCounter", 3, { canCollide = false })

	-- Giá trưng bày lazăng + kệ cúp
	local rg = "LSC_WheelDisplayRack"
	box(f, "WheelRackFrame", Vector3.new(0.8, 9.0, 8.0), Vector3.new(EAST_XC - 0.6, FLOOR_TOP + 4.5, 15.0), C.DARK_STEEL, M.Metal, 190, rg .. "_Frame", 1)
	for i = 1, 2 do
		for j = 1, 2 do
			local y = FLOOR_TOP + 2.4 + (i - 1) * 4.2
			local z = 13.0 + (j - 1) * 4.0
			cyl(f, "DisplayWheel" .. i .. j, Vector3.new(0.9, 2.9, 2.9), CFrame.new(EAST_XC - 1.2, y, z), C.CHROME, M.Metal, 70, rg .. "_Wheel" .. i .. j, 2, { reflectance = 0.3 })
			cyl(f, "DisplayWheelHub" .. i .. j, Vector3.new(1.0, 1.1, 1.1), CFrame.new(EAST_XC - 1.2, y, z), C.DARK_STEEL, M.Metal, 40, rg .. "_Wheel" .. i .. j, 3)
		end
	end
	box(f, "TrophyShelf", Vector3.new(1.6, 0.25, 6.0), Vector3.new(EAST_XC - 0.9, 7.2, 8.0), C.WOOD, M.Wood, 60, "LSC_TrophyShelf", 1)
	for i = 1, 3 do
		local z = 6.0 + (i - 1) * 2.0
		box(f, "TrophyBase" .. i, Vector3.new(1.1, 0.4, 1.1), Vector3.new(EAST_XC - 0.9, 7.5, z), C.BLACK, M.SmoothPlastic, 15, "LSC_Trophy" .. i, 2, { canCollide = false })
		vcyl(f, "TrophyStem" .. i, Vector3.new(1.2, 0.25, 0.25), Vector3.new(EAST_XC - 0.9, 8.2, z), C.YELLOW, M.Metal, 15, "LSC_Trophy" .. i, 2, { canCollide = false })
		ball(f, "TrophyCup" .. i, 1.1, Vector3.new(EAST_XC - 0.9, 9.0, z), C.YELLOW, M.Metal, 15, "LSC_Trophy" .. i, 3)
	end

	-- Chậu cây + kệ tạp chí
	for i, pos in ipairs({ { -211.5, 47.6 }, { -167.5, 47.0 }, { -216.0, 32.5 } }) do
		vcyl(f, "PlanterPot" .. i, Vector3.new(2.4, 2.2, 2.2), Vector3.new(pos[1], FLOOR_TOP + 1.2, pos[2]), Color3.fromRGB(120, 82, 62), M.Concrete, 70, "LSC_Planter" .. i, 1)
		ball(f, "PlanterBush" .. i, 3.2, Vector3.new(pos[1], FLOOR_TOP + 3.4, pos[2]), Color3.fromRGB(56, 108, 62), M.Grass, 40, "LSC_Planter" .. i, 2)
		ball(f, "PlanterBushB" .. i, 2.2, Vector3.new(pos[1] - 0.9, FLOOR_TOP + 4.5, pos[2] + 0.6), Color3.fromRGB(72, 128, 72), M.Grass, 35, "LSC_Planter" .. i, 3)
	end
end

-- =============================================================================
-- 15. TRẦN XƯỞNG: GIÀN THÉP, ĐÈN TUÝP, ỐNG HƠI, QUẠT TRẦN, BANNER
-- =============================================================================
local function buildCeiling(root: Instance)
	local f = folder("10_CeilingWorkshop", root)
	local spanX = IN_X1 - IN_X0
	local midX = (IN_X0 + IN_X1) * 0.5

	-- 6 giàn thép I-beam bắc ngang
	for i, z in ipairs({ -2.0, 8.0, 18.0, 28.0, 38.0, 46.0 }) do
		local grp = "LSC_Truss" .. tostring(i)
		box(f, "TrussBottom" .. i, Vector3.new(spanX, 0.55, 0.55), Vector3.new(midX, 22.5, z), C.DARK_STEEL, M.Metal, 320, grp .. "_Bottom", 1)
		box(f, "TrussTop" .. i, Vector3.new(spanX, 0.45, 0.45), Vector3.new(midX, 23.1, z), C.DARK_STEEL, M.Metal, 300, grp .. "_Top", 2)
		for b = 0, 6 do
			local bx = IN_X0 + 5.0 + b * 15.0
			if bx < IN_X1 - 2.0 then
				strut(f, "TrussWeb" .. i .. "_" .. b, Vector3.new(bx, 22.5, z), Vector3.new(bx + 7.5, 23.1, z), 0.22, C.DARK_STEEL, M.Metal, 80, grp .. "_Web" .. b, 2, { canCollide = false })
			end
		end
		-- Bản mã + bu-lông
		box(f, "TrussPlate" .. i, Vector3.new(1.6, 0.7, 0.7), Vector3.new(IN_X0 + 1.0, 22.5, z), C.STEEL, M.Metal, 120, grp .. "_Plate", 1)
		box(f, "TrussPlateE" .. i, Vector3.new(1.6, 0.7, 0.7), Vector3.new(IN_X1 - 1.0, 22.5, z), C.STEEL, M.Metal, 120, grp .. "_Plate", 1)
	end

	-- 3 xà gồ chạy dọc + máng kỹ thuật
	for i, gx in ipairs({ -262.0, -244.0, -226.0, -200.0, -182.0 }) do
		box(f, "Purlin" .. i, Vector3.new(0.4, 0.4, IN_Z1 - IN_Z0), Vector3.new(gx, 22.9, (IN_Z0 + IN_Z1) * 0.5), C.DARK_STEEL, M.Metal, 220, "LSC_Purlin" .. i, 1, { canCollide = false })
	end
	box(f, "CableTray", Vector3.new(spanX - 6.0, 0.55, 1.6), Vector3.new(midX, 22.0, 2.0), C.GALV, M.Metal, 140, "LSC_CableTray", 1, { canCollide = false })
	box(f, "SprinklerMain", Vector3.new(spanX - 6.0, 0.5, 0.5), Vector3.new(midX, 21.9, 26.0), C.RED_DARK, M.Metal, 120, "LSC_SprinklerMain", 1, { canCollide = false })
	for i = 1, 8 do
		local sx = IN_X0 + 6.0 + (i - 1) * 12.0
		if sx < IN_X1 - 3.0 then
			cyl(f, "SprinklerHead" .. i, Vector3.new(0.9, 0.34, 0.34), CFrame.new(sx, 21.5, 26.0), C.CHROME, M.Metal, 35, "LSC_Sprinkler" .. i, 2, { canCollide = false })
			box(f, "SprinklerDeflector" .. i, Vector3.new(0.7, 0.12, 0.7), Vector3.new(sx, 21.05, 26.0), C.RED, M.Metal, 20, "LSC_Sprinkler" .. i, 3, { canCollide = false })
		end
	end

	-- Đèn tuýp trần (2 dãy dọc theo 2 khoang + 3 đèn khu khách)
	local lightRows = {
		{ -256.0, { 6.0, 16.0, 26.0, 36.0, 44.0 } },
		{ -230.5, { 6.0, 16.0, 26.0, 36.0, 44.0 } },
		{ -205.0, { 22.0, 32.0, 42.0 } },
		{ -186.0, { 24.0, 34.0, 44.0 } },
	}
	for ri, row in ipairs(lightRows) do
		for li, z in ipairs(row[2]) do
			stripLight(f, string.format("WorkshopLight_%d_%d", ri, li), Vector3.new(row[1], 21.2, z), true, 9.0, string.format("LSC_Light_%d_%d", ri, li))
		end
	end

	-- Quạt trần công nghiệp
	for i, qx in ipairs({ -256.0, -230.5 }) do
		local grp = "LSC_CeilingFan" .. tostring(i)
		vcyl(f, "FanDropRod" .. i, Vector3.new(2.6, 0.3, 0.3), Vector3.new(qx, 21.9, 20.0), C.GALV, M.Metal, 60, grp .. "_Rod", 1, { canCollide = false })
		ball(f, "FanHub" .. i, 1.6, Vector3.new(qx, 20.6, 20.0), C.STEEL, M.Metal, 60, grp .. "_Hub", 2, { canCollide = false })
		for b = 1, 4 do
			local ang = (b - 1) * math.pi * 0.5 + 0.4
			rbox(
				f,
				"FanBlade" .. i .. "_" .. b,
				Vector3.new(6.0, 0.14, 1.5),
				CFrame.new(qx + math.cos(ang) * 3.2, 20.5, 20.0 + math.sin(ang) * 3.2) * CFrame.Angles(0, -ang, math.rad(8)),
				C.GALV,
				M.Metal,
				25,
				grp .. "_Blade" .. b,
				3,
				{ canCollide = false, castShadow = false }
			)
		end
	end

	-- Ống hút khí thải treo + reo cuộn dây hơi
	for i, hx in ipairs({ -264.0, -238.5 }) do
		local grp = "LSC_ExhaustHose" .. tostring(i)
		cyl(f, "ExhaustReel" .. i, Vector3.new(1.0, 2.2, 2.2), CFrame.new(hx, 19.6, 38.0) * CFrame.Angles(0, math.rad(90), 0), C.DARK_STEEL, M.Metal, 70, grp .. "_Reel", 1, { canCollide = false })
		local prev = Vector3.new(hx, 19.6, 38.0)
		for s = 1, 5 do
			local nxt = Vector3.new(hx + s * 0.35, 19.6 - s * 1.15, 38.0 + s * 0.25)
			strut(f, "ExhaustHoseSeg" .. i .. "_" .. s, prev, nxt, 0.55, C.BLACK, M.Rubber, 25, grp .. "_Hose" .. s, 2, { canCollide = false })
			prev = nxt
		end
		box(f, "ExhaustNozzle" .. i, Vector3.new(1.1, 0.8, 1.1), Vector3.new(prev.X, prev.Y - 0.4, prev.Z), C.GALV, M.Metal, 25, grp .. "_Nozzle", 3, { canCollide = false })
	end
	-- Reo cuộn dây hơi
	for i, hx in ipairs({ -266.0, -244.0 }) do
		cyl(f, "HoseReel" .. i, Vector3.new(1.2, 1.8, 1.8), CFrame.new(hx, 17.4, 12.0) * CFrame.Angles(0, math.rad(90), 0), C.ORANGE_TOOL, M.Metal, 50, "LSC_HoseReel" .. i, 1, { canCollide = false })
		strut(f, "HoseDrop" .. i, Vector3.new(hx, 16.6, 12.0), Vector3.new(hx + 0.2, 11.0, 12.0), 0.36, C.BLACK, M.Rubber, 20, "LSC_HoseReel" .. i, 2, { canCollide = false })
	end

	-- Banner vải treo "LOS SANTOS CUSTOMS"
	box(f, "HangingBanner", Vector3.new(22.0, 4.6, 0.18), Vector3.new(-244.0, 18.6, 30.0), C.LSC_BLUE, M.Fabric, 45, "LSC_Banner", 1, { canCollide = false })
	drawText(f, "BannerText", "CUSTOMS", -250.4, 17.4, 30.15, 0.1, 0.35, C.NEON_YELLOW, M.Neon, 20, "LSC_Banner", 2)
	for _, sx in ipairs({ -9.0, 9.0 }) do
		box(f, "BannerWire" .. tostring(sx), Vector3.new(0.1, 2.0, 0.1), Vector3.new(-244.0 + sx, 21.9, 30.0), C.DARK_STEEL, M.Metal, 15, "LSC_Banner", 1, { canCollide = false })
	end

	-- Ống gió HVAC chạy dọc + miệng gió
	box(f, "HVACDuct", Vector3.new(2.6, 2.2, IN_Z1 - IN_Z0 - 4.0), Vector3.new(IN_X0 + 2.6, 20.6, (IN_Z0 + IN_Z1) * 0.5), C.GALV, M.Metal, 200, "LSC_Duct", 1)
	for i = 1, 6 do
		local z = -4.0 + (i - 1) * 9.0
		box(f, "DuctGrille" .. i, Vector3.new(0.2, 1.4, 2.2), Vector3.new(IN_X0 + 3.95, 20.6, z), C.DARK_STEEL, M.Metal, 40, "LSC_DuctGrille" .. i, 2, { canCollide = false })
	end
end

-- =============================================================================
-- 16. MEZZANINE THÉP + CẦU THANG + VĂN PHÒNG QUẢN LÝ
-- =============================================================================
local function railingRun(parent: Instance, name: string, a: Vector3, b: Vector3, group: string)
	local d = b - a
	local len = d.Magnitude
	local dir = d.Unit
	local posts = math.max(2, math.floor(len / 5.0) + 1)
	for i = 0, posts - 1 do
		local alpha = if posts <= 1 then 0 else i / (posts - 1)
		local p = a + d * alpha
		local g = "LSC_Rail_" .. name .. "_post" .. tostring(i)
		box(parent, "RailPost" .. name .. "_" .. i, Vector3.new(0.18, 4.2, 0.18), Vector3.new(p.X, a.Y + 2.1, p.Z), C.DARK_STEEL, M.Metal, 70, g, 1, { canCollide = false })
	end
	strut(parent, "RailTop" .. name, Vector3.new(a.X, a.Y + 4.1, a.Z), Vector3.new(b.X, b.Y + 4.1, b.Z), 0.22, C.DARK_STEEL, M.Metal, 90, "LSC_Rail_" .. name .. "_top", 2, { canCollide = false })
	strut(parent, "RailMid" .. name, Vector3.new(a.X, a.Y + 2.4, a.Z), Vector3.new(b.X, b.Y + 2.4, b.Z), 0.16, C.DARK_STEEL, M.Metal, 70, "LSC_Rail_" .. name .. "_mid", 2, { canCollide = false })
	strut(parent, "RailKick" .. name, Vector3.new(a.X, a.Y + 0.35, a.Z), Vector3.new(b.X, b.Y + 0.35, b.Z), 0.2, C.YELLOW, M.Metal, 60, "LSC_Rail_" .. name .. "_kick", 1, { canCollide = false })
end

local function buildMezzanine(root: Instance)
	local f = folder("11_MezzanineAndOffice", root)
	local deckY = MEZZ_BOT + 0.275

	-- 4 tấm sàn thép (chừa lỗ cầu thang X -201.4..-194.4, Z -6.2..12)
	local decks = {
		{ IN_X0, -201.4, IN_Z0, 12.0 },
		{ -194.4, -190.0, IN_Z0, 12.0 },
		{ -201.4, -194.4, IN_Z0, -6.2 },
		{ -201.4, -194.4, 11.6, 12.0 },
	}
	for i, d in ipairs(decks) do
		box(
			f,
			"MezzDeck" .. i,
			Vector3.new(d[2] - d[1], 0.55, d[4] - d[3]),
			Vector3.new((d[1] + d[2]) * 0.5, deckY, (d[3] + d[4]) * 0.5),
			C.DARK_STEEL,
			M.DiamondPlate,
			nil,
			nil,
			nil,
			{ castShadow = false }
		)
	end

	-- 6 cột thép + dầm chính
	for ci, cx in ipairs({ -268.0, -244.0, -218.0 }) do
		for zi, cz in ipairs({ -2.0, 10.0 }) do
			local grp = string.format("LSC_MezzColumn_%d_%d", ci, zi)
			box(f, "MezzColumn" .. ci .. "_" .. zi, Vector3.new(1.0, MEZZ_BOT - FLOOR_TOP, 1.0), Vector3.new(cx, (FLOOR_TOP + MEZZ_BOT) * 0.5, cz), C.DARK_STEEL, M.Metal, 420, grp .. "_Col", 1)
			box(f, "MezzColumnBase" .. ci .. "_" .. zi, Vector3.new(2.0, 0.4, 2.0), Vector3.new(cx, FLOOR_TOP + 0.2, cz), C.STEEL, M.Metal, 300, grp .. "_Base", 1)
			box(f, "MezzColumnCap" .. ci .. "_" .. zi, Vector3.new(1.8, 0.5, 1.8), Vector3.new(cx, MEZZ_BOT - 0.25, cz), C.STEEL, M.Metal, 260, grp .. "_Cap", 2)
		end
	end
	for i, cz in ipairs({ -2.0, 10.0 }) do
		box(f, "MezzGirder" .. i, Vector3.new(MEZZ_X1 - MEZZ_X0 - 2.0, 1.1, 0.8), Vector3.new((MEZZ_X0 + MEZZ_X1) * 0.5, MEZZ_BOT - 0.75, cz), C.DARK_STEEL, M.Metal, 460, "LSC_MezzGirder" .. i, 1)
	end
	box(f, "MezzEdgeBeam", Vector3.new(MEZZ_X1 - MEZZ_X0 - 2.0, 1.2, 0.9), Vector3.new((MEZZ_X0 + MEZZ_X1) * 0.5, MEZZ_BOT - 0.85, MEZZ_Z1 - 0.45), C.DARK_STEEL, M.Metal, 460, "LSC_MezzEdgeBeam", 1)

	-- Cầu thang lên mezzanine
	PartBuilder.staircase({
		name = "MezzStaircase",
		parent = f,
		origin = Vector3.new(-197.9, FLOOR_TOP, 10.6),
		dir = Vector3.new(0, 0, -1),
		width = 4.4,
		steps = 14,
		totalRise = MEZZ_TOP - FLOOR_TOP,
		totalRun = 17.5,
		color = C.CONCRETE,
		cheekColor = C.DARK_STEEL,
		material = M.DiamondPlate,
		fractureGroup = "LSC_MezzStairs",
	})
	-- Tay vịn cầu thang
	local railA = Vector3.new(-200.0, FLOOR_TOP, 10.6)
	local railB = Vector3.new(-200.0, MEZZ_TOP, -6.5)
	for i = 0, 6 do
		local t = i / 6
		local p = railA:Lerp(railB, t)
		box(f, "StairRailPost" .. i, Vector3.new(0.16, 4.0, 0.16), Vector3.new(p.X, p.Y + 2.0, p.Z), C.YELLOW, M.Metal, 55, "LSC_StairRailPost" .. i, 1, { canCollide = false })
	end
	strut(f, "StairHandRail", Vector3.new(railA.X, railA.Y + 4.0, railA.Z), Vector3.new(railB.X, railB.Y + 4.0, railB.Z), 0.22, C.YELLOW, M.Metal, 80, "LSC_StairHandRail", 2, { canCollide = false })

	-- Lan can mezzanine
	railingRun(f, "FrontWest", Vector3.new(MEZZ_X0 + 0.4, MEZZ_TOP, MEZZ_Z1 - 0.3), Vector3.new(-201.4, MEZZ_TOP, MEZZ_Z1 - 0.3), "LSC_RailFrontW")
	railingRun(f, "FrontEast", Vector3.new(-194.4, MEZZ_TOP, MEZZ_Z1 - 0.3), Vector3.new(-190.2, MEZZ_TOP, MEZZ_Z1 - 0.3), "LSC_RailFrontE")
	railingRun(f, "EastEdge", Vector3.new(-190.2, MEZZ_TOP, MEZZ_Z1 - 0.3), Vector3.new(-190.2, MEZZ_TOP, IN_Z0 + 0.4), "LSC_RailEast")
	railingRun(f, "StairWellEast", Vector3.new(-194.6, MEZZ_TOP, MEZZ_Z1 - 0.3), Vector3.new(-194.6, MEZZ_TOP, -6.0), "LSC_RailStairWell")

	-- VÁCH KÍNH VĂN PHÒNG QUẢN LÝ (góc Tây mezzanine)
	local og = "LSC_Office"
	glassPane(f, "OfficeFrontGlassA", "X", 4.0, MEZZ_X0 + 0.2, -258.0, MEZZ_TOP + 0.2, MEZZ_TOP + 9.0, 50, og .. "_FrontA", 1, C.GLASS)
	glassPane(f, "OfficeFrontGlassB", "X", 4.0, -252.0, -250.0, MEZZ_TOP + 0.2, MEZZ_TOP + 9.0, 50, og .. "_FrontB", 1, C.GLASS)
	box(f, "OfficeHeader", Vector3.new(21.0, 0.6, 0.6), Vector3.new(-260.1, MEZZ_TOP + 9.3, 4.0), C.DARK_STEEL, M.Metal, 150, og .. "_Header", 2)
	box(f, "OfficeDoorFrameW", Vector3.new(0.5, 8.6, 0.6), Vector3.new(-258.2, MEZZ_TOP + 4.3, 4.0), C.DARK_STEEL, M.Metal, 120, og .. "_DoorFrame", 1)
	box(f, "OfficeDoorFrameE", Vector3.new(0.5, 8.6, 0.6), Vector3.new(-251.8, MEZZ_TOP + 4.3, 4.0), C.DARK_STEEL, M.Metal, 120, og .. "_DoorFrame", 1)
	box(f, "OfficeDoorHeader", Vector3.new(6.9, 0.6, 0.6), Vector3.new(-255.0, MEZZ_TOP + 8.6, 4.0), C.DARK_STEEL, M.Metal, 120, og .. "_DoorFrame", 2)
	box(f, "OfficeDoorGlass", Vector3.new(5.4, 7.8, 0.2), Vector3.new(-255.0, MEZZ_TOP + 4.1, 4.0), C.GLASS, M.Glass, 45, og .. "_Door", 1, { transparency = 0.5, canCollide = false })
	box(f, "OfficeDoorHandle", Vector3.new(0.2, 0.2, 1.6), Vector3.new(-252.4, MEZZ_TOP + 3.8, 4.3), C.CHROME, M.Metal, 40, og .. "_Door", 2, { canCollide = false })
	box(f, "OfficeSign", Vector3.new(15.0, 2.4, 0.25), Vector3.new(-255.0, MEZZ_TOP + 10.2, 4.3), C.LSC_BLUE, M.Metal, 60, og .. "_Sign", 3)
	drawText(f, "OfficeSignText", "OFFICE", -260.7, MEZZ_TOP + 9.5, 4.55, 0.12, 0.32, C.NEON_WHITE, M.Neon, 20, og .. "_Sign", 4)

	-- Bàn làm việc quản lý + ghế + tủ hồ sơ + bảng trắng + máy in + cây cảnh
	box(f, "OfficeDeskTop", Vector3.new(9.0, 0.35, 4.0), Vector3.new(-264.0, MEZZ_TOP + 3.1, 0.0), C.WOOD, M.Wood, 130, og .. "_Desk", 1)
	box(f, "OfficeDeskPanelW", Vector3.new(0.3, 2.9, 3.8), Vector3.new(-268.3, MEZZ_TOP + 1.5, 0.0), C.WOOD, M.Wood, 100, og .. "_Desk", 1)
	box(f, "OfficeDeskPanelE", Vector3.new(0.3, 2.9, 3.8), Vector3.new(-259.7, MEZZ_TOP + 1.5, 0.0), C.WOOD, M.Wood, 100, og .. "_Desk", 1)
	box(f, "OfficeMonitor", Vector3.new(3.4, 2.2, 0.25), Vector3.new(-264.0, MEZZ_TOP + 4.7, -1.0), C.BLACK, M.SmoothPlastic, 40, og .. "_Monitor", 2)
	box(f, "OfficeMonitorGlow", Vector3.new(3.0, 1.8, 0.1), Vector3.new(-264.0, MEZZ_TOP + 4.7, -1.15), Color3.fromRGB(60, 110, 150), M.Neon, 20, og .. "_Monitor", 3, { canCollide = false, castShadow = false })
	box(f, "OfficeKeyboard", Vector3.new(2.6, 0.15, 1.0), Vector3.new(-264.0, MEZZ_TOP + 3.35, 0.4), C.BLACK, M.SmoothPlastic, 15, og .. "_Keyboard", 2, { canCollide = false })
	box(f, "OfficeChairSeat", Vector3.new(2.4, 0.4, 2.4), Vector3.new(-264.0, MEZZ_TOP + 1.9, 1.6), C.LEATHER, M.Fabric, 45, og .. "_Chair", 1)
	box(f, "OfficeChairBack", Vector3.new(2.4, 2.8, 0.4), Vector3.new(-264.0, MEZZ_TOP + 3.2, 2.6), C.LEATHER, M.Fabric, 45, og .. "_Chair", 2)
	vcyl(f, "OfficeChairPost", Vector3.new(1.6, 0.3, 0.3), Vector3.new(-264.0, MEZZ_TOP + 0.9, 1.6), C.CHROME, M.Metal, 30, og .. "_Chair", 1)
	box(f, "OfficeCabinet", Vector3.new(3.0, 6.4, 2.0), Vector3.new(-269.4, MEZZ_TOP + 3.2, -5.0), C.STEEL, M.Metal, 170, og .. "_Cabinet", 1)
	for d = 1, 4 do
		box(f, "OfficeDrawer" .. d, Vector3.new(0.15, 1.3, 1.8), Vector3.new(-267.85, MEZZ_TOP + 1.1 + (d - 1) * 1.55, -5.0), C.GALV, M.Metal, 50, og .. "_CabinetDrawer" .. d, 2, { canCollide = false })
	end
	box(f, "Whiteboard", Vector3.new(11.0, 5.4, 0.22), Vector3.new(-262.0, MEZZ_TOP + 5.6, -7.0), C.WHITE, M.SmoothPlastic, 55, og .. "_Whiteboard", 1)
	box(f, "WhiteboardFrame", Vector3.new(11.6, 6.0, 0.12), Vector3.new(-262.0, MEZZ_TOP + 5.6, -7.12), C.GALV, M.Metal, 40, og .. "_WhiteboardFrame", 1, { canCollide = false })
	box(f, "PrinterBody", Vector3.new(3.0, 2.2, 2.6), Vector3.new(-253.0, MEZZ_TOP + 1.3, -5.0), C.GALV, M.Metal, 60, og .. "_Printer", 1)
	box(f, "PrinterTray", Vector3.new(2.6, 0.3, 1.2), Vector3.new(-253.0, MEZZ_TOP + 2.5, -4.2), C.DARK_STEEL, M.Metal, 25, og .. "_Printer", 2, { canCollide = false })
	vcyl(f, "OfficePlantPot", Vector3.new(2.2, 2.0, 2.0), Vector3.new(-269.0, MEZZ_TOP + 1.1, 7.5), Color3.fromRGB(126, 88, 66), M.Concrete, 60, og .. "_Plant", 1)
	ball(f, "OfficePlantLeaf", 3.4, Vector3.new(-269.0, MEZZ_TOP + 3.4, 7.5), Color3.fromRGB(52, 104, 58), M.Grass, 35, og .. "_Plant", 2)

	-- Kho phụ tùng mezzanine + góc nghỉ nhân viên
	for u = 1, 2 do
		local x0 = -246.0 + (u - 1) * 11.0
		local grp = "LSC_MezzShelf" .. tostring(u)
		box(f, "MezzShelfPostA" .. u, Vector3.new(0.3, 9.0, 2.2), Vector3.new(x0, MEZZ_TOP + 4.5, 2.0), C.STEEL, M.Metal, 170, grp .. "_PostA", 1)
		box(f, "MezzShelfPostB" .. u, Vector3.new(0.3, 9.0, 2.2), Vector3.new(x0 + 9.5, MEZZ_TOP + 4.5, 2.0), C.STEEL, M.Metal, 170, grp .. "_PostB", 1)
		for s = 1, 3 do
			local y = MEZZ_TOP + 1.2 + (s - 1) * 2.9
			box(f, "MezzShelfPlank" .. u .. "_" .. s, Vector3.new(9.8, 0.22, 2.1), Vector3.new(x0 + 4.75, y, 2.0), C.GALV, M.Metal, 90, grp .. "_Plank" .. s, s)
			for b = 1, 3 do
				box(f, "MezzShelfBox" .. u .. "_" .. s .. "_" .. b, Vector3.new(2.6, 1.8, 1.8), Vector3.new(x0 + 1.6 + (b - 1) * 3.2, y + 1.0, 2.0), if (b + s) % 2 == 0 then C.YELLOW else C.WHITE, M.Cardboard, 45, grp .. "_Box" .. s .. b, s + 1)
			end
		end
	end
	-- Góc nghỉ: tủ lạnh mini + lò vi sóng + bàn + 4 ghế
	local bg = "LSC_BreakRoom"
	box(f, "FridgeBody", Vector3.new(3.4, 6.6, 3.0), Vector3.new(-212.0, MEZZ_TOP + 3.3, 8.0), C.WHITE, M.Metal, 190, bg .. "_Fridge", 1)
	box(f, "FridgeDoorTop", Vector3.new(0.2, 2.6, 2.7), Vector3.new(-210.25, MEZZ_TOP + 4.9, 8.0), C.WHITE, M.SmoothPlastic, 70, bg .. "_Fridge", 2, { canCollide = false })
	box(f, "FridgeDoorBottom", Vector3.new(0.2, 3.2, 2.7), Vector3.new(-210.25, MEZZ_TOP + 1.9, 8.0), C.WHITE, M.SmoothPlastic, 70, bg .. "_Fridge", 2, { canCollide = false })
	box(f, "FridgeHandle", Vector3.new(0.16, 2.2, 0.2), Vector3.new(-210.1, MEZZ_TOP + 4.6, 6.9), C.CHROME, M.Metal, 25, bg .. "_Fridge", 3, { canCollide = false })
	box(f, "Microwave", Vector3.new(2.4, 1.8, 2.4), Vector3.new(-220.0, MEZZ_TOP + 4.2, 6.0), C.BLACK, M.SmoothPlastic, 50, bg .. "_Microwave", 1)
	box(f, "BreakTable", Vector3.new(7.0, 0.3, 4.0), Vector3.new(-225.0, MEZZ_TOP + 2.9, 6.0), C.WOOD, M.Wood, 90, bg .. "_Table", 1)
	vcyl(f, "BreakTableLeg", Vector3.new(2.7, 0.4, 0.4), Vector3.new(-225.0, MEZZ_TOP + 1.4, 6.0), C.DARK_STEEL, M.Metal, 60, bg .. "_Table", 1)
	for i = 1, 4 do
		local ang = (i - 1) * math.pi * 0.5
		box(f, "BreakChair" .. i, Vector3.new(1.6, 0.35, 1.6), Vector3.new(-225.0 + math.cos(ang) * 3.2, MEZZ_TOP + 1.7, 6.0 + math.sin(ang) * 2.6), C.LSC_BLUE_LIGHT, M.SmoothPlastic, 40, bg .. "_Chair" .. i, 1)
		box(f, "BreakChairLeg" .. i, Vector3.new(0.2, 1.6, 0.2), Vector3.new(-225.0 + math.cos(ang) * 3.2, MEZZ_TOP + 0.8, 6.0 + math.sin(ang) * 2.6), C.DARK_STEEL, M.Metal, 30, bg .. "_Chair" .. i, 1)
	end
	box(f, "BreakCounter", Vector3.new(4.0, 3.2, 2.4), Vector3.new(-232.0, MEZZ_TOP + 1.6, 8.0), C.WOOD, M.Wood, 120, bg .. "_Counter", 1)

	-- Đèn + ổ cắm trên mezzanine
	for i, z in ipairs({ 0.0, 6.0 }) do
		stripLight(f, "MezzLight" .. i, Vector3.new(-230.0, 22.6, z), false, 12.0, "LSC_MezzLight" .. i)
		stripLight(f, "MezzLightOffice" .. i, Vector3.new(-260.0, 22.6, z), false, 10.0, "LSC_MezzLightOffice" .. i)
	end
	for i, x in ipairs({ -262.0, -240.0, -218.0 }) do
		stripLight(f, "UnderMezzLight" .. i, Vector3.new(x, 14.4, 4.0), false, 10.0, "LSC_UnderMezzLight" .. i)
	end
end

-- =============================================================================
-- 17. SÂN TRƯỚC: BÃI ĐỖ XE, CỔNG SOÁT VÉ, CỘT ĐÈN PHA, HÀNG RÀO
-- =============================================================================
local function buildForecourt(root: Instance)
	local f = folder("12_ForecourtAndGate", root)

	-- Tấm bê tông sân trước chia khe co giãn (né Z-fighting với pad 1.20)
	local nx, nz = 7, 5
	local cellW = (FC_X1 - FC_X0) / nx
	local cellD = (FC_Z1 - FC_Z0) / nz
	for ix = 0, nx - 1 do
		for iz = 0, nz - 1 do
			local x0 = FC_X0 + ix * cellW + 0.16
			local z0 = FC_Z0 + iz * cellD + 0.16
			box(
				f,
				string.format("ForecourtSlab_%d_%d", ix, iz),
				Vector3.new(cellW - 0.32, 0.22, cellD - 0.32),
				Vector3.new(x0 + (cellW - 0.32) * 0.5, FC_TOP - 0.11, z0 + (cellD - 0.32) * 0.5),
				jitter(C.CONCRETE, ix * 7 + iz * 3, 2),
				M.Concrete,
				380,
				string.format("LSC_ForecourtSlab_%d_%d", ix, iz),
				1,
				{ castShadow = false }
			)
		end
	end

	-- Dốc hạ lề + vạch dừng trước cổng
	box(f, "DrivewayApron", Vector3.new(60.0, 0.2, 2.6), Vector3.new(-238.0, FC_TOP - 0.1, 121.6), C.ASPHALT, M.Asphalt, 380, "LSC_DrivewayApron", 1, { castShadow = false })
	box(f, "DrivewayStopLine", Vector3.new(58.0, 0.05, 0.5), Vector3.new(-238.0, FC_TOP + 0.03, 118.6), C.WHITE, M.SmoothPlastic, 40, "LSC_StopLine", 1, { canCollide = false, castShadow = false })

	-- Logo "LSC" sơn phẳng giữa sân — MỘT dòng duy nhất, gọn mắt (bỏ dòng CUSTOMS chồng chéo cũ)
	drawTextFlat(f, "ForecourtLogo", "LSC", -238.0, 82.0, FC_TOP + 0.06, 2.15, C.WHITE, M.SmoothPlastic, 60, "LSC_PavementLogo", 1)
	-- 2 mũi tên chỉ hướng vào 2 khoang: thân thẳng + 2 cánh chéo 45° (sơn vàng phẳng)
	for i, ax in ipairs({ -256.25, -230.75 }) do
		box(f, "LaneArrowShaft" .. i, Vector3.new(1.5, 0.05, 12.0), Vector3.new(ax, FC_TOP + 0.05, 104.0), C.YELLOW, M.SmoothPlastic, 45, "LSC_LaneArrow" .. i, 1, { canCollide = false, castShadow = false })
		for k, sgn in ipairs({ -1, 1 }) do
			rbox(
				f,
				"LaneArrowWing" .. i .. "_" .. k,
				Vector3.new(1.4, 0.05, 6.6),
				CFrame.new(ax + sgn * 1.85, FC_TOP + 0.05, 99.4) * CFrame.Angles(0, math.rad(sgn * 42), 0),
				C.YELLOW,
				M.SmoothPlastic,
				45,
				"LSC_LaneArrow" .. i,
				2,
				{ canCollide = false, castShadow = false }
			)
		end
	end

	-- Bãi đỗ khách phía Tây + Đông (vạch sơn trắng + gờ chặn bánh)
	for side, sx in ipairs({ { -296.0, -274.0, -1 }, { -163.0, -141.0, 1 } }) do
		local xA, xB, inward = sx[1], sx[2], sx[3]
		local grp = "LSC_ParkingSide" .. tostring(side)
		-- 3 vạch ô đỗ gọn gàng (bỏ mảng nhựa tối StallNumber cho đỡ rối mắt)
		for i = 0, 2 do
			local z = 60.0 + i * 24.0
			box(f, "StallLine" .. side .. "_" .. i, Vector3.new(xB - xA, 0.05, 0.4), Vector3.new((xA + xB) * 0.5, FC_TOP + 0.04, z), C.WHITE, M.SmoothPlastic, 45, grp .. "_Line" .. i, 1, { canCollide = false, castShadow = false })
		end
		-- 2 gờ chặn bánh mỗi bên
		for i = 0, 1 do
			local z = 72.0 + i * 24.0
			local wheelX = if inward < 0 then xB - 1.4 else xA + 1.4
			box(f, "WheelStop" .. side .. "_" .. i, Vector3.new(2.6, 0.7, 8.0), Vector3.new(wheelX, FC_TOP + 0.35, z), C.CONCRETE_DARK, M.Concrete, 90, grp .. "_WheelStop" .. i, 1)
		end
	end

	-- Cổng soát vé: 2 trụ gạch + thanh chắn dựng đứng + đèn neon
	for i, gx in ipairs({ -270.0, -206.0 }) do
		local grp = "LSC_GatePier" .. tostring(i)
		brickWall(f, "GatePier" .. i, "X", 120.6, gx - 1.8, gx + 1.8, FC_TOP, 11.0, 3.6, C.BRICK, 260, grp .. "_Brick")
		box(f, "GatePierCap" .. i, Vector3.new(4.6, 0.7, 4.6), Vector3.new(gx, FC_TOP + 11.35, 120.6), C.CONCRETE, M.Concrete, 180, grp .. "_Cap", 6)
		ball(f, "GatePierLamp" .. i, 1.2, Vector3.new(gx, FC_TOP + 12.4, 120.6), C.NEON_YELLOW, M.Neon, 25, grp .. "_Lamp", 1)
		box(f, "GatePierSign" .. i, Vector3.new(3.0, 1.4, 0.16), Vector3.new(gx, FC_TOP + 8.6, 122.3), C.LSC_BLUE, M.Metal, 40, grp .. "_Sign", 4)
		drawText(f, "GatePierText" .. i, "LSC", gx - 1.75, FC_TOP + 8.2, 122.5, 0.08, 0.2, C.NEON_WHITE, M.Neon, 15, grp .. "_Sign", 5)
	end
	-- Thanh chắn (đang mở dựng đứng) + hộp điều khiển
	local bg = "LSC_BoomBarrier"
	box(f, "BoomControlBox", Vector3.new(2.0, 3.0, 2.0), Vector3.new(-204.4, FC_TOP + 1.5, 119.6), C.YELLOW, M.Metal, 90, bg .. "_Box", 1)
	box(f, "BoomPivot", Vector3.new(1.6, 1.6, 1.6), Vector3.new(-204.4, FC_TOP + 3.6, 119.6), C.DARK_STEEL, M.Metal, 70, bg .. "_Pivot", 1)
	box(f, "BoomArm", Vector3.new(0.7, 11.4, 0.7), Vector3.new(-204.4, FC_TOP + 9.4, 119.6), C.WHITE, M.SmoothPlastic, 110, bg .. "_Arm", 2)
	for i = 1, 4 do
		box(f, "BoomStripe" .. i, Vector3.new(0.78, 1.05, 0.78), Vector3.new(-204.4, FC_TOP + 4.9 + i * 2.35, 119.6), C.RED, M.SmoothPlastic, 30, bg .. "_Arm", 3, { canCollide = false })
	end
	box(f, "BoomCounterweight", Vector3.new(1.8, 2.0, 1.8), Vector3.new(-204.4, FC_TOP + 4.2, 118.2), C.DARK_STEEL, M.Metal, 110, bg .. "_Counter", 1)

	-- 4 cột đèn pha sân trước
	for i, p in ipairs({ { -292.0, 116.0 }, { -146.0, 116.0 }, { -292.0, 56.0 }, { -146.0, 56.0 } }) do
		local grp = "LSC_FloodPole" .. tostring(i)
		box(f, "FloodBase" .. i, Vector3.new(3.2, 0.9, 3.2), Vector3.new(p[1], FC_TOP + 0.45, p[2]), C.CONCRETE, M.Concrete, 240, grp .. "_Base", 1)
		vcyl(f, "FloodPole" .. i, Vector3.new(19.0, 1.1, 1.1), Vector3.new(p[1], FC_TOP + 10.0, p[2]), C.GALV, M.Metal, 260, grp .. "_Pole", 2)
		box(f, "FloodArm" .. i, Vector3.new(3.4, 0.35, 0.35), Vector3.new(p[1] + (if p[1] < -218 then 1.6 else -1.6), FC_TOP + 19.2, p[2]), C.GALV, M.Metal, 90, grp .. "_Arm", 3)
		box(f, "FloodHead" .. i, Vector3.new(2.2, 0.9, 3.2), Vector3.new(p[1] + (if p[1] < -218 then 3.0 else -3.0), FC_TOP + 18.9, p[2]), C.DARK_STEEL, M.Metal, 80, grp .. "_Head", 3)
		box(f, "FloodLens" .. i, Vector3.new(1.8, 0.3, 2.8), Vector3.new(p[1] + (if p[1] < -218 then 3.0 else -3.0), FC_TOP + 18.4, p[2]), C.NEON_WHITE, M.Neon, 30, grp .. "_Lens", 4, { canCollide = false, castShadow = false })
	end

	-- Hàng rào lưới B40 quanh sân (chừa cổng xe 60 studs)
	local function fenceRun(name: string, axis: "X" | "Z", fixed: number, c0: number, c1: number)
		local grp = "LSC_Fence_" .. name
		local cursor = c0
		local idx = 1
		while cursor < c1 - 0.5 do
			local seg = math.min(c1, cursor + 8.0)
			local len = seg - cursor
			local mid = (cursor + seg) * 0.5
			local pos = if axis == "X" then Vector3.new(mid, FC_TOP + 2.0, fixed) else Vector3.new(fixed, FC_TOP + 2.0, mid)
			local size = if axis == "X" then Vector3.new(len - 0.3, 3.8, 0.12) else Vector3.new(0.12, 3.8, len - 0.3)
			box(f, name .. "_Mesh" .. idx, size, pos, Color3.fromRGB(150, 156, 162), M.DiamondPlate, 70, grp .. "_Mesh" .. idx, 1, { transparency = 0.35 })
			local pp = if axis == "X" then Vector3.new(seg, FC_TOP + 2.0, fixed) else Vector3.new(fixed, FC_TOP + 2.0, seg)
			box(f, name .. "_Post" .. idx, Vector3.new(0.28, 4.2, 0.28), pp, C.GALV, M.Metal, 110, grp .. "_Post" .. idx, 1)
			cursor = seg
			idx += 1
		end
		-- thanh giằng trên
		local rp = if axis == "X" then Vector3.new((c0 + c1) * 0.5, FC_TOP + 4.1, fixed) else Vector3.new(fixed, FC_TOP + 4.1, (c0 + c1) * 0.5)
		local rs = if axis == "X" then Vector3.new(c1 - c0, 0.22, 0.22) else Vector3.new(0.22, 0.22, c1 - c0)
		box(f, name .. "_TopRail", rs, rp, C.GALV, M.Metal, 90, grp .. "_TopRail", 2, { canCollide = false })
	end
	fenceRun("WestFence", "Z", FC_X0 + 0.3, 54.0, 119.5)
	fenceRun("EastFence", "Z", FC_X1 - 0.3, 54.0, 119.5)
	fenceRun("SouthWestFence", "X", 119.5, FC_X0 + 0.3, -270.5)
	fenceRun("SouthEastFence", "X", 119.5, -205.5, FC_X1 - 0.3)

	-- Cọc chắn bảo vệ mặt tiền (húc bay được)
	PartBuilder.bollardLine({
		name = "FacadeBollards",
		parent = f,
		startPos = Vector3.new(-220.0, FC_TOP, 58.5),
		endPos = Vector3.new(-176.0, FC_TOP, 58.5),
		count = 8,
		fractureGroup = "LSC_FacadeBollard",
	})

	-- Đồ nghề ngoài sân: lốp, phuy, pallet, cọc nón, băng ghế khách
	-- Góc đồ nghề ngoài sân gọn gàng: 1 chồng lốp + 2 phuy dầu (bớt 60% vật dụng lặt vặt)
	tireStack(f, "ForecourtTireStack1", Vector3.new(-283.0, FC_TOP + 0.5, 110.0), 4, "LSC_OutdoorTires1", 70)
	for i, dp in ipairs({ { -287.6, 104.0 }, { -284.2, 104.0 } }) do
		oilDrum(f, "OutdoorDrum" .. i, Vector3.new(dp[1], FC_TOP + 1.7, dp[2]), if i == 2 then C.BLUE_DRUM else C.GREEN_DRUM, "LSC_OutdoorDrum" .. tostring(i), 110)
	end
	-- 3 cọc tiêu đặt thẳng hàng trước 3 trụ nhà (không còn cọc nằm giữa làn xe)
	local conePositions = { { -266.0, 108.0 }, { -243.5, 108.0 }, { -218.0, 108.0 } }
	for i, cp in ipairs(conePositions) do
		trafficCone(f, "Cone" .. i, Vector3.new(cp[1], FC_TOP, cp[2]), "LSC_Cone" .. tostring(i))
	end
	-- 1 băng ghế khách ngoài trời đặt chính giữa dưới mái hiên kính
	for i, bx in ipairs({ -190.0 }) do
		local grp = "LSC_OutdoorBench" .. tostring(i)
		box(f, "BenchSeat" .. i, Vector3.new(9.0, 0.4, 2.2), Vector3.new(bx, FC_TOP + 2.0, 59.6), C.WOOD, M.WoodPlanks, 80, grp .. "_Seat", 1)
		box(f, "BenchBack" .. i, Vector3.new(9.0, 2.0, 0.3), Vector3.new(bx, FC_TOP + 3.1, 58.6), C.WOOD, M.WoodPlanks, 70, grp .. "_Back", 2)
		for _, lx in ipairs({ -3.6, 3.6 }) do
			box(f, "BenchLeg" .. i .. tostring(lx), Vector3.new(0.35, 2.0, 2.0), Vector3.new(bx + lx, FC_TOP + 1.0, 59.6), C.DARK_STEEL, M.Metal, 70, grp .. "_Leg" .. tostring(lx), 1)
		end
	end
	-- 2 chậu cây đối xứng 2 bên cửa đi bộ (bỏ chậu lẻ ở góc Đông cho gọn mắt)
	for i, p in ipairs({ { -213.5, 56.5 }, { -199.5, 56.5 } }) do
		vcyl(f, "OutdoorPlanter" .. i, Vector3.new(3.2, 3.4, 3.4), Vector3.new(p[1], FC_TOP + 1.6, p[2]), C.CONCRETE, M.Concrete, 150, "LSC_OutdoorPlanter" .. i, 1)
		ball(f, "OutdoorBush" .. i, 4.4, Vector3.new(p[1], FC_TOP + 4.4, p[2]), Color3.fromRGB(58, 112, 64), M.Grass, 60, "LSC_OutdoorPlanter" .. i, 2)
	end
	-- 1 thùng rác duy nhất sát trụ Đông
	for i, p in ipairs({ { -218.0, 56.0 } }) do
		vcyl(f, "TrashBin" .. i, Vector3.new(3.4, 2.6, 2.6), Vector3.new(p[1], FC_TOP + 1.7, p[2]), C.STEEL, M.Metal, 90, "LSC_TrashBin" .. i, 1)
		vcyl(f, "TrashLid" .. i, Vector3.new(0.4, 2.9, 2.9), Vector3.new(p[1], FC_TOP + 3.6, p[2]), C.DARK_STEEL, M.Metal, 50, "LSC_TrashBin" .. i, 2)
	end
	-- Camera an ninh + đèn gắn tường 2 góc mặt tiền
	for i, cx in ipairs({ BX0 + 3.0, BX1 - 3.0 }) do
		local grp = "LSC_SecurityCam" .. tostring(i)
		box(f, "CamArm" .. i, Vector3.new(0.25, 0.25, 1.8), Vector3.new(cx, 20.0, BZ1 + 0.6), C.GALV, M.Metal, 40, grp .. "_Arm", 1, { canCollide = false })
		box(f, "CamBody" .. i, Vector3.new(0.8, 0.8, 1.6), Vector3.new(cx, 19.6, BZ1 + 1.4), C.WHITE, M.SmoothPlastic, 40, grp .. "_Body", 2)
		box(f, "CamLens" .. i, Vector3.new(0.55, 0.55, 0.2), Vector3.new(cx, 19.6, BZ1 + 2.2), C.BLACK, M.Glass, 25, grp .. "_Lens", 3, { canCollide = false })
		box(f, "WallPack" .. i, Vector3.new(1.2, 0.7, 1.2), Vector3.new(cx, 14.6, BZ1 + 0.6), C.DARK_STEEL, M.Metal, 40, grp .. "_WallPack", 1)
		box(f, "WallPackLens" .. i, Vector3.new(1.0, 0.2, 1.0), Vector3.new(cx, 14.2, BZ1 + 0.6), C.NEON_WHITE, M.Neon, 20, grp .. "_WallPack", 2, { canCollide = false, castShadow = false })
	end
	-- Vòi nước + ống tưới rửa sân
	box(f, "HoseBib", Vector3.new(0.6, 0.6, 1.2), Vector3.new(-176.0, FC_TOP + 1.6, BZ1 + 0.7), C.CHROME, M.Metal, 25, "LSC_HoseBib", 1, { canCollide = false })

	-- =========================================================================
	-- [CHỨC NĂNG THẬT] 2 KHOANG ĐỘ XE: VÙNG KÍCH HOẠT + ĐÈN BÁO TRẠNG THÁI
	-- LSCustomsService (server) sẽ dùng các part này để biết xe nào đang nằm
	-- trong khoang, bật đèn Xanh và mở bảng độ xe [E] cho người chơi.
	-- =========================================================================
	local fnFolder = folder("90_BayInteractions", f)
	local baySpans = { { BAY1A, BAY1B }, { BAY2A, BAY2B } }
	for i, span in ipairs(baySpans) do
		local x0, x1 = span[1], span[2]
		local xc = (x0 + x1) * 0.5
		local halfW = (x1 - x0) * 0.5

		-- Vùng kích hoạt vô hình (quét xe chạy vào khoang)
		local zone = box(fnFolder, "BayZone" .. i, Vector3.new(halfW * 2 - 1.2, 13.0, 46.0), Vector3.new(xc, FLOOR_TOP + 6.5, 25.0), Color3.fromRGB(0, 255, 140), M.SmoothPlastic, nil, nil, nil, { canCollide = false, transparency = 1, castShadow = false })
		zone.CanTouch = true
		zone.CanQuery = false
		zone:SetAttribute("BayIndex", i)
		zone:SetAttribute("LSCustomsTrigger", true)
		zone:SetAttribute("BayCenter", Vector3.new(xc, FLOOR_TOP, 24.0))

		-- Dải đèn neon mặt sàn ngay trong cửa cuốn (Đỏ = trống / Xanh = có xe)
		box(fnFolder, "BayStatusStrip" .. i, Vector3.new(halfW * 2 - 2.6, 0.16, 1.20), Vector3.new(xc, FLOOR_TOP + 0.08, 49.40), Color3.fromRGB(220, 42, 42), M.Neon, 220, "LSC_BayStatus" .. i, 1, { canCollide = false, castShadow = false })

		-- Đèn cầu treo trong khoang (sáng lên khi khoang có xe)
		local lamp = ball(fnFolder, "BayStatusLamp" .. i, 1.60, Vector3.new(xc, 13.10, 49.20), Color3.fromRGB(220, 42, 42), M.Neon, 220, "LSC_BayStatus" .. i, 2)
		lamp.CanCollide = false
		lamp.CanQuery = false
		box(fnFolder, "BayLampHousing" .. i, Vector3.new(2.40, 0.30, 2.40), Vector3.new(xc, 13.85, 49.20), C.DARK_STEEL, M.Metal, 200, "LSC_BayStatus" .. i, 2, { canCollide = false, castShadow = false })
	end
	-- Bảng tên dịch vụ "MOD SHOP" gắn sát đỉnh vách kính (không che tầm nhìn vào phòng chờ)
	box(f, "ServicePlaque", Vector3.new(9.0, 1.4, 0.16), Vector3.new(-190.0, FC_TOP + 10.32, BZ1 + 1.05), C.LSC_BLUE, M.Metal, 90, "LSC_ServicePlaque", 1, { canCollide = false, castShadow = false })
	local plaqueText = "MOD SHOP"
	local plaquePixel = 0.15
	local plaqueWidth = textWidth(plaqueText, plaquePixel)
	drawText(f, "ServicePlaqueText", plaqueText, -190.0 - plaqueWidth * 0.5, FC_TOP + 10.32, BZ1 + 1.16, 0.06, plaquePixel, C.NEON_WHITE, M.Neon, 40, "LSC_ServicePlaque", 2)
end

-- =============================================================================
-- 18. SÂN HÔNG TÂY (đỗ xe nhân viên) & ĐÔNG (rác thải, bình gas, giàn nóng)
-- =============================================================================
local function buildSideYards(root: Instance)
	local f = folder("13_SideYards", root)

	-- Sân hông Tây — CHỈ lát dải phía Bắc (Z < 51), không chồng lấn ô sân trước nữa
	box(f, "WestYardSlab", Vector3.new(26.0, 0.22, 58.7), Vector3.new(-284.5, FC_TOP - 0.14, 21.85), C.CONCRETE_DARK, M.Asphalt, 380, "LSC_WestYardSlab", 1, { castShadow = false })
	for i = 0, 2 do
		local z = 70.0 + i * 17.0
		box(f, "WestStallLine" .. i, Vector3.new(24.0, 0.05, 0.4), Vector3.new(-284.5, FC_TOP + 0.03, z), C.WHITE, M.SmoothPlastic, 40, "LSC_WestStallLine" .. i, 1, { canCollide = false, castShadow = false })
	end
	box(f, "BikeRackBar", Vector3.new(0.4, 0.4, 10.0), Vector3.new(-295.0, FC_TOP + 1.6, 34.0), C.GALV, M.Metal, 70, "LSC_BikeRack", 1)
	for i = 1, 5 do
		box(f, "BikeRackLoop" .. i, Vector3.new(0.24, 2.2, 0.24), Vector3.new(-295.0, FC_TOP + 1.1, 30.0 + (i - 1) * 2.0), C.GALV, M.Metal, 45, "LSC_BikeRackLoop" .. i, 1)
		box(f, "BikeRackTop" .. i, Vector3.new(1.2, 0.24, 0.24), Vector3.new(-295.0, FC_TOP + 2.1, 30.0 + (i - 1) * 2.0), C.GALV, M.Metal, 45, "LSC_BikeRackLoop" .. i, 2)
	end
	cyl(f, "WestPropaneTank", Vector3.new(6.0, 2.4, 2.4), CFrame.new(-284.0, FC_TOP + 1.4, 10.0) * CFrame.Angles(0, math.rad(90), 0), C.WHITE, M.Metal, 200, "LSC_WestPropaneTank", 1)
	box(f, "WestUtilityCabinet", Vector3.new(4.0, 6.0, 3.0), Vector3.new(-294.0, FC_TOP + 3.0, 4.0), C.GALV, M.Metal, 170, "LSC_WestUtilityCabinet", 1)
	vcyl(f, "FireHydrant", Vector3.new(2.6, 1.3, 1.3), Vector3.new(-296.5, FC_TOP + 1.3, 60.0), C.RED, M.Metal, 90, "LSC_FireHydrant", 1)

	-- Sân hông Đông — CHỈ lát dải phía Bắc (Z < 51), không chồng lấn ô sân trước nữa
	box(f, "EastYardSlab", Vector3.new(26.0, 0.22, 58.7), Vector3.new(-151.5, FC_TOP - 0.14, 21.85), C.CONCRETE_DARK, M.Concrete, 380, "LSC_EastYardSlab", 1, { castShadow = false })
	local dg = "LSC_Dumpster"
	box(f, "DumpsterBody", Vector3.new(9.0, 5.2, 6.0), Vector3.new(-153.0, FC_TOP + 2.6, 30.0), Color3.fromRGB(46, 84, 60), M.Metal, 260, dg .. "_Body", 1)
	box(f, "DumpsterLidA", Vector3.new(4.5, 0.3, 6.2), Vector3.new(-155.2, FC_TOP + 5.4, 30.0), Color3.fromRGB(40, 72, 52), M.Metal, 110, dg .. "_LidA", 2)
	box(f, "DumpsterLidB", Vector3.new(4.5, 0.3, 6.2), Vector3.new(-150.8, FC_TOP + 5.4, 30.0), Color3.fromRGB(40, 72, 52), M.Metal, 110, dg .. "_LidB", 2)
	for i = 1, 4 do
		local dx = if i <= 2 then -1 else 1
		local dz = if i % 2 == 0 then -1 else 1
		cyl(f, "DumpsterWheel" .. i, Vector3.new(0.5, 1.2, 1.2), CFrame.new(-153.0 + dx * 3.6, FC_TOP + 0.6, 30.0 + dz * 2.4) * CFrame.Angles(0, math.rad(90), 0), C.BLACK, M.Rubber, 60, dg .. "_Wheel" .. i, 1)
	end
	for i = 1, 3 do
		local zp = 44.0 + (i - 1) * 4.0
		cyl(f, "EastPropaneTank" .. i, Vector3.new(5.6, 2.2, 2.2), CFrame.new(-146.0, FC_TOP + 1.3, zp) * CFrame.Angles(0, math.rad(90), 0), C.WHITE, M.Metal, 170, "LSC_EastPropane" .. i, 1)
		box(f, "PropaneCage" .. i, Vector3.new(6.6, 3.4, 0.2), Vector3.new(-146.0, FC_TOP + 1.7, zp + 2.0), C.GALV, M.DiamondPlate, 90, "LSC_EastPropane" .. i, 2, { transparency = 0.3 })
	end
	for i = 1, 2 do
		local zp = 62.0 + (i - 1) * 8.0
		local grp = "LSC_WallACU" .. tostring(i)
		box(f, "ACUFrame" .. i, Vector3.new(2.4, 4.4, 5.0), Vector3.new(EAST_XC + 1.6, FC_TOP + 2.4, zp), C.GALV, M.Metal, 150, grp .. "_Frame", 1)
		cyl(f, "ACUFan" .. i, Vector3.new(0.4, 3.6, 3.6), CFrame.new(EAST_XC + 2.9, FC_TOP + 2.4, zp), C.DARK_STEEL, M.Metal, 90, grp .. "_Fan", 2)
		box(f, "ACUPad" .. i, Vector3.new(3.0, 0.4, 5.4), Vector3.new(EAST_XC + 1.6, FC_TOP + 0.2, zp), C.CONCRETE_DARK, M.Concrete, 120, grp .. "_Pad", 1)
	end
	-- =========================================================================
	-- Giá kệ sắt HỞ 3 tầng: 4 chân đứng + dầm ngang, thùng gỗ NẰM TRÊN dầm
	-- (bản cũ là 1 khối đặc 2×8×9 bị thùng gỗ xuyên qua -> đã sửa 100% chồng lấn)
	-- =========================================================================
	local rackZ0, rackZ1 = 81.6, 90.4
	local rackXA, rackXB = -142.55, -140.45
	local rackZc = (rackZ0 + rackZ1) * 0.5
	local upIdx = 1
	for _, zz in ipairs({ rackZ0, rackZ1 }) do
		for _, xx in ipairs({ rackXA, rackXB }) do
			box(f, "EastRackUpright" .. upIdx, Vector3.new(0.26, 8.40, 0.26), Vector3.new(xx, FC_TOP + 4.20, zz), C.ORANGE_TOOL, M.Metal, 110, "LSC_EastRackFrame", 1)
			upIdx += 1
		end
	end
	local shelfY = { FC_TOP + 1.45, FC_TOP + 3.95, FC_TOP + 6.45 }
	for i, sy in ipairs(shelfY) do
		for k, xx in ipairs({ rackXA + 0.14, rackXB - 0.14 }) do
			box(f, "EastRackRail" .. i .. "_" .. k, Vector3.new(0.14, 0.18, rackZ1 - rackZ0 + 0.42), Vector3.new(xx, sy, rackZc), C.ORANGE_TOOL, M.Metal, 70, "LSC_EastRackShelf" .. i, 2)
		end
		for k, zz in ipairs({ rackZ0, rackZ1 }) do
			box(f, "EastRackCross" .. i .. "_" .. k, Vector3.new(rackXB - rackXA + 0.30, 0.18, 0.14), Vector3.new((rackXA + rackXB) * 0.5, sy, zz), C.ORANGE_TOOL, M.Metal, 70, "LSC_EastRackShelf" .. i, 2)
		end
		box(f, "EastRackBox" .. i, Vector3.new(1.50, 1.50, 3.00), Vector3.new((rackXA + rackXB) * 0.5, sy + 0.84, rackZc), C.WOOD, M.WoodPlanks, 60, "LSC_EastRackBox" .. i, 3)
	end
	-- Hàng rào sân hông Đông
	local cursor = -6.0
	local idx = 1
	while cursor < 118.0 do
		local seg = math.min(118.0, cursor + 9.0)
		box(f, "EastYardFenceMesh" .. idx, Vector3.new(0.12, 4.0, seg - cursor - 0.3), Vector3.new(-139.8, FC_TOP + 2.0, (cursor + seg) * 0.5), Color3.fromRGB(150, 156, 162), M.DiamondPlate, 70, "LSC_EastYardFence" .. idx, 1, { transparency = 0.35 })
		box(f, "EastYardFencePost" .. idx, Vector3.new(0.3, 4.4, 0.3), Vector3.new(-139.8, FC_TOP + 2.2, seg), C.GALV, M.Metal, 110, "LSC_EastYardFencePost" .. idx, 1)
		cursor = seg
		idx += 1
	end
end

-- =============================================================================
-- 19. LẮP RÁP TOÀN BỘ CÔNG TRÌNH
-- =============================================================================
function Module.build(modulesContainer: Instance): Instance
	local root = folder("Plot_C1_LSCustoms", modulesContainer)
	root:SetAttribute("WorldModuleId", "Plot_C1_LSCustoms")
	root:SetAttribute("PlotId", "Plot_C1")
	root:SetAttribute("District", "DEL PERRO")
	root:SetAttribute("GroundY", GROUND_Y)
	root:SetAttribute("FloorTopY", FLOOR_TOP)
	root:SetAttribute("MainGatePosition", Vector3.new(-238.0, FC_TOP, 118.0))
	root:SetAttribute("VehicleGateZ", 119.5)
	root:SetAttribute("PedestrianDoorPosition", Vector3.new(-206.5, FLOOR_TOP, BZ1))
	root:SetAttribute("Agent", "arena/e461e643-robloxstudio-connecting")

	buildFloor(root)
	buildShell(root)
	buildBayDoors(root)
	buildStorefront(root)
	buildSignage(root)
	buildRoof(root)
	buildLifts(root)
	buildToolWall(root)
	buildBackStorage(root)
	buildCustomerLounge(root)
	buildCeiling(root)
	buildMezzanine(root)
	buildForecourt(root)
	buildSideYards(root)

	return root
end

return Module
