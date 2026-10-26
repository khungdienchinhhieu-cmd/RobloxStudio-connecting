--!strict
--[=[
	Plot_D1_RockfordShowroom.luau
	================================================================================
	LUXURY AUTOS — Showroom siêu xe Rockford Hills (GTA V) — Ô đất Plot_D1
	Task      : A1_ROCKFORD_LUXURY_AUTOS
	Branch    : arena/f3da0fbe-robloxstudio-connecting
	Bounds    : X ∈ [-318 .. -134]  |  Z ∈ [-204 .. -60]  |  Nền Y = 1.15
	Mặt tiền : Nam (+Z) — kính cong 2 lớp nhìn ra Olympic Fwy (Z = -36)
	Quy mô   : 2 tầng + tầng lửng, sảnh thông tầng ~38 stud, sân 6 ô đỗ.

	QUY TẮC ĐÃ TUÂN THỦ
	• Dựng TRỰC TIẾP ở toạ độ lưới v22 (KHÔNG dùng WorldGrid.RELOCATION).
	• Tỉ lệ 1:1: dùng WorldGrid.meters() (1 m = 3.33 stud). Tầng 11 stud,
	  cửa đi bộ 16 × 8.5 stud, trần thông thuỷ ≥ 14.24 stud, cửa cuốn 18 × 12.
	• Mọi khối (trừ 13 tấm móng/sàn/mái chịu lực) đi qua PartBuilder.part với
	  integrity > 0 -> Destructible = true, PartHealth/MaxPartHealth/StructuralRow.
	• Mỗi ô kính mặt tiền là 1 khối RIÊNG, integrity = 40, CanCollide = false
	  -> XE TÔNG XUYÊN KÍNH như pha mở đầu GTA V.
	• Khối nhỏ < 1.6 stud CanCollide = false; mọi part CanTouch = false,
	  CanQuery = true; kính/Neon CastShadow = false; SurfaceGui MaxDistance = 340,
	  không TextScaled, PixelsPerStud ≤ 32.
	• Chỉ tạo file module này — KHÔNG sửa file lõi, KHÔNG đụng studio-sync.json.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local PartBuilder = require(Shared:WaitForChild("World"):WaitForChild("PartBuilder"))

local Module = {
	Id = "Plot_D1_RockfordShowroom",
	PlotId = "Plot_D1",
	Order = 50,
	Enabled = true,
}

-- =============================================================================
-- 0. HẰNG SỐ — TOẠ ĐỘ THẬT CỦA PLOT_D1 (lưới v22)
-- =============================================================================
local GROUND = 1.15
local APRON_TOP = 1.30 -- mặt sân trước
local FLOOR_TOP = 1.36 -- mặt đá bóng trong showroom
local MEZZ_TOP = 16.20 -- sàn tầng lửng (thông thuỷ tầng trệt 14.24 stud)
local L2_TOP = 28.00 -- sàn tầng 2
local ROOF_BOT = 39.20 -- trần trong tầng 2 (thông thuỷ 11.2 stud)
local ROOF_TOP = 40.00
local WALL_TOP = ROOF_TOP
local PARAPET_TOP = 42.20

local BX0, BX1 = -302.0, -150.0 -- vỏ nhà rộng 152 stud (≈ 45.6 m)
local BZ0, BZ1 = -190.0, -110.0 -- sâu 80 stud (≈ 24 m)
local WT = 1.2

-- Mặt tiền kính cong (parabol, 2 lớp cách nhau 2.6 stud)
local GX0, GX1 = -296.0, -156.0
local ARC_CX, ARC_HALF = -226.0, 70.0
local ARC_Z0, ARC_BULGE = -110.0, 10.0
local GLASS_Y0, GLASS_H = 1.50, 26.0
local GLASS_Y1 = GLASS_Y0 + GLASS_H
local BAYS, ROWS = 24, 6
local BAY_W = (GX1 - GX0) / BAYS
local ROW_H = GLASS_H / ROWS
local LAYER_GAP = 2.6
-- Tỉ lệ 1:1 lấy trực tiếp từ WorldGrid (1 m = 3.33 stud)
local SPM = WorldGrid.STUDS_PER_METER
local MULLION_W = WorldGrid.meters(0.10) -- 0.333 stud ≈ 10 cm
local TRANSOM_H = WorldGrid.meters(0.09) -- 0.300 stud ≈ 9 cm

-- Sân trước
local FC_X0, FC_X1 = -316.0, -136.0
local FC_Z0, FC_Z1 = -108.0, -62.0

local M = Enum.Material
local C = {
	WHITE = Color3.fromRGB(238, 240, 238),
	STEEL = Color3.fromRGB(216, 222, 226),
	STEEL_DK = Color3.fromRGB(120, 130, 140),
	CHARCOAL = Color3.fromRGB(38, 42, 48),
	BLACK = Color3.fromRGB(22, 24, 28),
	GLASS = Color3.fromRGB(146, 204, 224),
	GLASS_DK = Color3.fromRGB(88, 142, 170),
	MARBLE = Color3.fromRGB(216, 216, 210),
	MARBLE2 = Color3.fromRGB(196, 199, 196),
	CONCRETE = Color3.fromRGB(150, 152, 150),
	CONCRETE2 = Color3.fromRGB(132, 135, 134),
	ASPHALT = Color3.fromRGB(54, 56, 60),
	YELLOW = Color3.fromRGB(244, 198, 46),
	RED = Color3.fromRGB(208, 48, 44),
	NEON = Color3.fromRGB(238, 248, 255),
	GREEN = Color3.fromRGB(48, 122, 76),
	GREEN2 = Color3.fromRGB(62, 146, 88),
	WOOD = Color3.fromRGB(126, 86, 54),
	LEATHER = Color3.fromRGB(48, 50, 58),
	GOLD = Color3.fromRGB(214, 176, 92),
	CAR_RED = Color3.fromRGB(196, 36, 34),
	CAR_YELLOW = Color3.fromRGB(238, 182, 36),
	CAR_BLUE = Color3.fromRGB(34, 92, 166),
	CAR_GREY = Color3.fromRGB(174, 178, 184),
	TIRE = Color3.fromRGB(28, 28, 32),
	CHROME = Color3.fromRGB(202, 208, 214),
}

-- =============================================================================
-- 1. SHIM DỰNG KHỐI — LUÔN ĐI QUA PartBuilder.part ĐỂ GẮN MÁU ẨN
-- =============================================================================
local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function merge(spec: { [string]: any }, opts: { [string]: any }?)
	if opts then
		for k, v in pairs(opts) do
			spec[k] = v
		end
	end
	return spec
end

local function box(
	parent: Instance, name: string, size: Vector3, pos: Vector3,
	color: Color3, mat: Enum.Material, hp: number?, grp: string?, row: number?,
	opts: { [string]: any }?
): Part
	local spec: { [string]: any } = {
		name = name, parent = parent, size = size, pos = pos,
		color = color, material = mat,
		destructible = hp ~= nil, integrity = hp,
		fractureGroup = grp or "Rockford", structuralRow = row or 1,
	}
	merge(spec, opts)
	return PartBuilder.part(spec :: any)
end

local function rbox(
	parent: Instance, name: string, size: Vector3, cf: CFrame,
	color: Color3, mat: Enum.Material, hp: number?, grp: string?, row: number?,
	opts: { [string]: any }?
): Part
	local spec: { [string]: any } = {
		name = name, parent = parent, size = size, cframe = cf,
		color = color, material = mat,
		destructible = hp ~= nil, integrity = hp,
		fractureGroup = grp or "Rockford", structuralRow = row or 1,
	}
	merge(spec, opts)
	return PartBuilder.part(spec :: any)
end

local function cfAt(x: number, y: number, z: number, yaw: number): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
end

-- Trụ tròn đứng (Part.Shape=Cylinder mặc định nằm ngang trục X -> quay 90° quanh Z)
local function vcyl(
	parent: Instance, name: string, size: Vector3, pos: Vector3,
	color: Color3, mat: Enum.Material, hp: number?, grp: string?, row: number?,
	opts: { [string]: any }?
): Part
	local o = merge({
		shape = Enum.PartType.Cylinder,
	}, opts)
	return rbox(parent, name, size, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		color, mat, hp, grp, row, o)
end

-- Bánh xe (trục quay nằm ngang theo Z)
local function wheel(parent: Instance, name: string, pos: Vector3, hp: number, grp: string): Part
	return rbox(parent, name, Vector3.new(1.25, 2.7, 2.7),
		CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0),
		C.TIRE, M.Rubber or M.SmoothPlastic, hp, grp, 1,
		{ shape = Enum.PartType.Cylinder })
end

local function ball(parent: Instance, name: string, d: number, pos: Vector3,
	color: Color3, hp: number, grp: string): Part
	return box(parent, name, Vector3.new(d, d, d), pos, color, M.SmoothPlastic, hp, grp, 1,
		{ shape = Enum.PartType.Ball })
end

local function gui(part: Instance, text: string, pps: number, textSize: number, face: Enum.NormalId?)
	local sg = Instance.new("SurfaceGui")
	sg.Name = part.Name .. "_Gui"
	sg.Face = face or Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pps
	sg.MaxDistance = 340
	sg.LightInfluence = 0.15
	sg.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Label"
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Position = UDim2.fromScale(0, 0)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = false
	lbl.TextSize = textSize
	lbl.TextColor3 = C.NEON
	lbl.Text = text
	lbl.Parent = sg
	return sg
end

local GLASS_OPTS = {
	transparency = 0.32,
	canCollide = false,
	castShadow = false,
	reflectance = 0.12,
}
local NEON_OPTS = { canCollide = false, castShadow = false }
local SMALL_OPTS = { canCollide = false, castShadow = false }

-- =============================================================================
-- 2. HÀM HÌNH HỌC DÙNG CHUNG
-- =============================================================================
local function arcZ(x: number): number
	local t = (x - ARC_CX) / ARC_HALF
	return ARC_Z0 + ARC_BULGE * (1 - t * t)
end
local function arcYaw(x: number): number
	local t = (x - ARC_CX) / ARC_HALF
	local slope = -2 * ARC_BULGE * t / ARC_HALF
	return -math.atan(slope)
end

-- Tường ghép khối so le, có thể khoét lỗ bằng hàm skip(coord, y)
local function wallRun(
	parent: Instance, name: string, axis: "X" | "Z", fixed: number,
	c0: number, c1: number, y0: number, y1: number, thick: number,
	colA: Color3, colB: Color3, hp: number, grp: string,
	skip: ((number, number) -> boolean)?
)
	local courses = math.max(1, math.floor((y1 - y0) / 3.6 + 0.5))
	local ch = (y1 - y0) / courses
	local blockLen = 7.4
	local nSeg = math.max(1, math.floor((c1 - c0) / blockLen + 0.5))
	local segLen = (c1 - c0) / nSeg
	for row = 1, courses do
		local cy = y0 + (row - 0.5) * ch
		local stagger = (row % 2 == 0) and segLen * 0.5 or 0
		local idx = 0
		for seg = 1, nSeg do
			local a = c0 + (seg - 1) * segLen + stagger
			if a >= c1 - 0.05 then break end
			local b = math.min(c1, a + segLen)
			if b - a < 0.4 then break end
			idx += 1
			local mid = (a + b) * 0.5
			if not (skip and skip(mid, cy)) then
				local drawC = math.max(0.3, (b - a) - 0.12)
				local drawH = math.max(0.3, ch - 0.12)
				local pos = if axis == "X"
					then Vector3.new(mid, cy, fixed)
					else Vector3.new(fixed, cy, mid)
				local sz = if axis == "X"
					then Vector3.new(drawC, drawH, thick)
					else Vector3.new(thick, drawH, drawC)
				box(parent, string.format("%s_R%d_C%d", name, row, idx),
					sz, pos, if (row + seg) % 3 == 0 then colB else colA,
					M.Concrete, hp, grp, row)
			end
		end
	end
end

-- Lát sàn caro đá bóng: các tấm rời, khe 0.08 -> 0 Z-fighting
local function tileField(
	parent: Instance, name: string,
	x0: number, x1: number, z0: number, z1: number,
	top: number, thick: number, cols: number, rows: number,
	colA: Color3, colB: Color3, hp: number, grp: string
)
	local dx = (x1 - x0) / cols
	local dz = (z1 - z0) / rows
	for i = 0, cols - 1 do
		for j = 0, rows - 1 do
			local cx = x0 + (i + 0.5) * dx
			local cz = z0 + (j + 0.5) * dz
			box(parent, string.format("%s_%02d_%02d", name, i + 1, j + 1),
				Vector3.new(dx - 0.09, thick, dz - 0.09),
				Vector3.new(cx, top - thick * 0.5, cz),
				if (i + j) % 2 == 0 then colA else colB,
				M.Marble, hp, grp, 1,
				{ reflectance = 0.30, canCollide = true })
		end
	end
end

-- =============================================================================
-- 3. BUILD
-- =============================================================================
function Module.build(modulesContainer: Instance): Instance
	local root = folder("Plot_D1_RockfordShowroom", modulesContainer)
	root:SetAttribute("PlotId", "Plot_D1")
	root:SetAttribute("ModuleId", "Plot_D1_RockfordShowroom")
	root:SetAttribute("MainEntrance", "X=-226, Z=-99 (cửa đôi kính 16 × 8.5)")
	root:SetAttribute("VehicleGate", "Z=-63, X=-242..-210 (barrier đỏ-trắng)")
	root:SetAttribute("GarageDoor", "X=-302, Z=-172..-154 (18 × 12)")
	root:SetAttribute("GlassIntegrity", 40)
	root:SetAttribute("DestructibleStore", true)
	root:SetAttribute("StudsPerMeter", SPM)
	root:SetAttribute("GroundFloorClear_Studs", MEZZ_TOP - FLOOR_TOP)
	root:SetAttribute("UpperFloorClear_Studs", ROOF_BOT - L2_TOP)

	-- 3.1 ───────────────────────── SÂN TRƯỚC / FORECOURT ───────────────────
	local fc = folder("01_Forecourt", root)

	box(fc, "ForecourtBaseSlab", Vector3.new(FC_X1 - FC_X0, 0.07, FC_Z1 - FC_Z0),
		Vector3.new((FC_X0 + FC_X1) * 0.5, GROUND + 0.035, (FC_Z0 + FC_Z1) * 0.5),
		C.CONCRETE2, M.Concrete, nil, nil, nil, { canCollide = true })

	tileField(fc, "ForecourtPaver", FC_X0, FC_X1, FC_Z0, FC_Z1,
		APRON_TOP, 0.09, 12, 4, C.CONCRETE, C.CONCRETE2, 130, "ForecourtPaver")

	-- 6 ô đỗ xe: vạch vàng + gờ chặn bánh + số ô (SurfaceGui trên bảng nhỏ)
	local pk = folder("02_Parking", fc)
	local stallX0, stallW, stallGap = -287.5, 18.0, 3.0
	local stallZ0, stallZ1 = -92.0, -72.0
	for i = 0, 6 do
		local x = stallX0 + i * (stallW + stallGap) - stallGap * 0.5
		box(pk, string.format("ParkLine_%02d", i + 1),
			Vector3.new(0.34, 0.045, stallZ1 - stallZ0),
			Vector3.new(x, APRON_TOP + 0.045, (stallZ0 + stallZ1) * 0.5),
			C.YELLOW, M.SmoothPlastic, 40, "ParkLine", 1, SMALL_OPTS)
	end
	box(pk, "ParkLine_Back", Vector3.new(6 * (stallW + stallGap) - stallGap, 0.045, 0.34),
		Vector3.new(stallX0 + (6 * (stallW + stallGap) - stallGap) * 0.5 - stallW * 0.5 - stallGap * 0.5 + stallW * 0.5,
			APRON_TOP + 0.045, stallZ0 + 0.2),
		C.YELLOW, M.SmoothPlastic, 40, "ParkLine", 1, SMALL_OPTS)
	for i = 0, 5 do
		local sx = stallX0 + i * (stallW + stallGap) + stallW * 0.5
		box(pk, string.format("WheelStop_%02d", i + 1), Vector3.new(stallW - 1.2, 0.55, 0.9),
			Vector3.new(sx, APRON_TOP + 0.28, stallZ0 + 1.9),
			C.WHITE, M.Concrete, 120, "WheelStop", 1)
		box(pk, string.format("WheelStopStripe_%02d", i + 1), Vector3.new(stallW - 1.6, 0.06, 0.30),
			Vector3.new(sx, APRON_TOP + 0.58, stallZ0 + 1.9),
			C.YELLOW, M.SmoothPlastic, 35, "WheelStop", 2, SMALL_OPTS)
		local num = box(pk, string.format("StallNumberPlate_%02d", i + 1),
			Vector3.new(2.4, 0.06, 1.6), Vector3.new(sx, APRON_TOP + 0.06, stallZ0 + 4.0),
			C.CHARCOAL, M.SmoothPlastic, 30, "StallNumber", 1, SMALL_OPTS)
		gui(num, tostring(i + 1), 24, 40, Enum.NormalId.Top)
	end
	-- 2 mũi tên dẫn làn (thân + 2 cánh)
	for a, ax in ipairs({ -266.0, -186.0 }) do
		box(pk, string.format("LaneArrow_%d_Shaft", a), Vector3.new(2.0, 0.05, 9.0),
			Vector3.new(ax, APRON_TOP + 0.055, -68.0), C.WHITE, M.SmoothPlastic, 30, "LaneArrow", 1, SMALL_OPTS)
		for s, sgn in ipairs({ -1, 1 }) do
			rbox(pk, string.format("LaneArrow_%d_Wing%d", a, s), Vector3.new(1.4, 0.05, 5.0),
				cfAt(ax + sgn * 2.4, APRON_TOP + 0.055, -73.0, sgn * math.rad(38)),
				C.WHITE, M.SmoothPlastic, 30, "LaneArrow", 1, SMALL_OPTS)
		end
	end

	-- Cổng barrier đỏ-trắng (đang nâng 12° — CFrame tĩnh lúc build)
	local gate = folder("03_BarrierGate", fc)
	for s, gx in ipairs({ -240.5, -211.5 }) do
		box(gate, string.format("GatePost_%d_Base", s), Vector3.new(2.6, 0.7, 2.6),
			Vector3.new(gx, APRON_TOP + 0.35, -63.2), C.CHARCOAL, M.Metal, 180, "GatePost", 1)
		box(gate, string.format("GatePost_%d_Shaft", s), Vector3.new(1.5, 5.6, 1.5),
			Vector3.new(gx, APRON_TOP + 3.5, -63.2), C.WHITE, M.Metal, 160, "GatePost", 2)
		for k = 0, 3 do
			box(gate, string.format("GatePost_%d_Band%d", s, k + 1), Vector3.new(1.56, 0.45, 1.56),
				Vector3.new(gx, APRON_TOP + 1.6 + k * 1.35, -63.2), C.RED, M.SmoothPlastic, 60, "GatePost", 3, SMALL_OPTS)
		end
		box(gate, string.format("GatePost_%d_Lamp", s), Vector3.new(0.9, 0.5, 0.9),
			Vector3.new(gx, APRON_TOP + 6.55, -63.2), C.NEON, M.Neon, 35, "GatePost", 4, NEON_OPTS)
	end
	local armLen = 30.0
	local arm = rbox(gate, "BarrierArm_Core", Vector3.new(armLen, 0.8, 0.8),
		CFrame.new(-226.0, APRON_TOP + 6.0, -63.2) * CFrame.Angles(0, 0, math.rad(12)),
		C.WHITE, M.Metal, 90, "BarrierArm", 2)
	for k = 0, 9 do
		local t = -armLen * 0.5 + (k + 0.5) * (armLen / 10)
		local c = CFrame.new(-226.0, APRON_TOP + 6.0, -63.2) * CFrame.Angles(0, 0, math.rad(12))
		local off = c:PointToWorldSpace(Vector3.new(t, 0, 0.42))
		rbox(gate, string.format("BarrierArm_Stripe_%02d", k + 1),
			Vector3.new(armLen / 10 - 0.10, 0.82, 0.06),
			CFrame.new(off) * CFrame.Angles(0, 0, math.rad(12)),
			if k % 2 == 0 then C.RED else C.WHITE, M.SmoothPlastic, 45, "BarrierArm", 3, SMALL_OPTS)
	end
	box(gate, "GateSignBoard", Vector3.new(15.0, 2.4, 0.4),
		Vector3.new(-226.0, APRON_TOP + 9.2, -63.2), C.CHARCOAL, M.Metal, 110, "GateSign", 2)
	gui(gate:FindFirstChild("GateSignBoard") :: Instance, "LUXURY AUTOS  ·  ROCKFORD HILLS", 20, 38, Enum.NormalId.Back)

	-- 4 cột đèn sân
	local lamps = folder("04_YardLamps", fc)
	for i, lp in ipairs({ { -306.0, -68.0 }, { -146.0, -68.0 }, { -306.0, -96.0 }, { -146.0, -96.0 } }) do
		local g = "YardLamp" .. i
		box(lamps, g .. "_Foot", Vector3.new(2.4, 0.8, 2.4),
			Vector3.new(lp[1], APRON_TOP + 0.4, lp[2]), C.CHARCOAL, M.Metal, 180, g, 1)
		vcyl(lamps, g .. "_Pole", Vector3.new(11.0, 0.62, 0.62),
			Vector3.new(lp[1], APRON_TOP + 6.3, lp[2]), C.STEEL, M.Metal, 190, g, 2)
		box(lamps, g .. "_CrossArm", Vector3.new(4.4, 0.45, 0.45),
			Vector3.new(lp[1], APRON_TOP + 12.0, lp[2]), C.STEEL, M.Metal, 90, g, 3)
		for s, sgn in ipairs({ -1, 1 }) do
			box(lamps, string.format("%s_Head%d", g, s), Vector3.new(1.8, 0.55, 1.4),
				Vector3.new(lp[1] + sgn * 1.9, APRON_TOP + 11.6, lp[2]),
				C.NEON, M.Neon, 40, g, 4, NEON_OPTS)
		end
	end

	-- Cây cọ California (thân đốt + tán lá xoè) + bồn hoa
	local green = folder("05_Landscaping", fc)
	local function palm(idx: number, px: number, pz: number, h: number)
		local g = "Palm" .. idx
		box(green, g .. "_Pot", Vector3.new(5.2, 1.0, 5.2),
			Vector3.new(px, APRON_TOP + 0.5, pz), C.CONCRETE, M.Concrete, 150, g, 1)
		box(green, g .. "_Soil", Vector3.new(4.4, 0.22, 4.4),
			Vector3.new(px, APRON_TOP + 1.06, pz), C.WOOD, M.SmoothPlastic, 60, g, 2)
		for s = 1, 6 do
			local yy = APRON_TOP + 1.1 + (s - 0.5) * (h / 6)
			local xo = math.sin(s * 0.55) * 0.55
			vcyl(green, string.format("%s_Trunk%d", g, s), Vector3.new(h / 6 + 0.06, 1.55 - s * 0.09, 1.55 - s * 0.09),
				Vector3.new(px + xo, yy, pz), C.WOOD, M.Wood or M.SmoothPlastic, 110, g, 2)
		end
		local topY = APRON_TOP + 1.1 + h
		for f = 0, 6 do
			local a = (f / 7) * math.pi * 2
			rbox(green, string.format("%s_Frond%d", g, f + 1), Vector3.new(7.2, 0.22, 1.5),
				cfAt(px + math.cos(a) * 3.4, topY - 0.5 + f * 0.045, pz + math.sin(a) * 3.4, -a),
				if f % 2 == 0 then C.GREEN else C.GREEN2, M.SmoothPlastic, 45, g, 3,
				{ canCollide = false })
		end
		ball(green, g .. "_Crown", 1.6, Vector3.new(px, topY, pz), C.GREEN, 55, g)
	end
	palm(1, -306.0, -84.0, 11.5)
	palm(2, -146.0, -84.0, 11.5)
	palm(3, -296.0, -70.0, 9.5)
	palm(4, -156.0, -70.0, 9.5)

	for i, pp in ipairs({ { -272.0, -64.5 }, { -180.0, -64.5 }, { -306.0, -104.0 },
		{ -146.0, -104.0 }, { -258.0, -104.0 }, { -194.0, -104.0 } }) do
		local g = "Planter" .. i
		box(green, g .. "_Box", Vector3.new(7.0, 1.5, 3.2),
			Vector3.new(pp[1], APRON_TOP + 0.75, pp[2]), C.WHITE, M.Concrete, 140, g, 1)
		box(green, g .. "_Soil", Vector3.new(6.3, 0.2, 2.6),
			Vector3.new(pp[1], APRON_TOP + 1.58, pp[2]), C.WOOD, M.SmoothPlastic, 50, g, 2, SMALL_OPTS)
		for k = 0, 3 do
			ball(green, string.format("%s_Bush%d", g, k + 1), 1.5 + (k % 2) * 0.35,
				Vector3.new(pp[1] - 2.4 + k * 1.6, APRON_TOP + 2.2 + (k % 2) * 0.25, pp[2]),
				if k % 2 == 0 then C.GREEN else C.GREEN2, 40, g)
		end
	end

	for i, bx in ipairs({ -286.0, -166.0 }) do
		local g = "Bench" .. i
		box(green, g .. "_Seat", Vector3.new(6.0, 0.45, 1.8),
			Vector3.new(bx, APRON_TOP + 1.5, -103.0), C.WOOD, M.Wood or M.SmoothPlastic, 80, g, 2)
		box(green, g .. "_Back", Vector3.new(6.0, 1.6, 0.35),
			Vector3.new(bx, APRON_TOP + 2.5, -103.8), C.WOOD, M.Wood or M.SmoothPlastic, 80, g, 3)
		for s = -1, 1, 2 do
			box(green, string.format("%s_Leg%d", g, s), Vector3.new(0.4, 1.5, 1.4),
				Vector3.new(bx + s * 2.4, APRON_TOP + 0.75, -103.0), C.CHARCOAL, M.Metal, 90, g, 1)
		end
	end
	for i, tx in ipairs({ -296.0, -156.0 }) do
		local g = "Bin" .. i
		vcyl(green, g .. "_Body", Vector3.new(2.6, 1.5, 1.5),
			Vector3.new(tx, APRON_TOP + 1.3, -101.0), C.CHARCOAL, M.Metal, 90, g, 1)
		vcyl(green, g .. "_Lid", Vector3.new(0.35, 1.7, 1.7),
			Vector3.new(tx, APRON_TOP + 2.75, -101.0), C.STEEL, M.Metal, 50, g, 2)
	end

	-- Viền bó vỉa + vạch sang đường
	local curb = folder("06_Curb", fc)
	for i = 0, 17 do
		box(curb, string.format("CurbStone_%02d", i + 1), Vector3.new(9.6, 0.5, 1.2),
			Vector3.new(FC_X0 + (i + 0.5) * 9.99, GROUND + 0.30, -61.7),
			C.WHITE, M.Concrete, 150, "Curb", 1)
	end
	for i = 0, 5 do
		box(curb, string.format("Crosswalk_%02d", i + 1), Vector3.new(2.2, 0.05, 7.0),
			Vector3.new(-238.0 + i * 4.8, APRON_TOP + 0.055, -66.0),
			C.WHITE, M.SmoothPlastic, 35, "Crosswalk", 1, SMALL_OPTS)
	end

	-- 3.2 ───────────────────────── VỎ NHÀ / STRUCTURE ───────────────────────
	local shell = folder("07_Structure", root)

	box(shell, "ShowroomFloorBase", Vector3.new(BX1 - BX0, 0.11, BZ1 - BZ0),
		Vector3.new((BX0 + BX1) * 0.5, GROUND + 0.055, (BZ0 + BZ1) * 0.5),
		C.CONCRETE2, M.Concrete, nil, nil, nil, { canCollide = true })
	tileField(shell, "ShowroomFloorTile", BX0 + 1, BX1 - 1, BZ0 + 1, BZ1 - 1,
		FLOOR_TOP, 0.08, 14, 8, C.MARBLE, C.MARBLE2, 140, "ShowroomFloor")

	-- Tường Tây (có cửa cuốn xe), tường Đông, tường Bắc, 2 đoạn tường Nam
	wallRun(shell, "WestWall", "Z", BX0, BZ0, BZ1, FLOOR_TOP, WALL_TOP, WT,
		C.WHITE, C.STEEL, 190, "WestWall", function(c, y)
			return c > -172.0 and c < -154.0 and y < 13.6
		end)
	wallRun(shell, "EastWall", "Z", BX1, BZ0, BZ1, FLOOR_TOP, WALL_TOP, WT,
		C.WHITE, C.STEEL, 190, "EastWall")
	wallRun(shell, "BackWall", "X", BZ0, BX0, BX1, FLOOR_TOP, WALL_TOP, WT,
		C.WHITE, C.STEEL, 190, "BackWall")
	wallRun(shell, "FrontPierWestWall", "X", BZ1, BX0, GX0, FLOOR_TOP, WALL_TOP, WT,
		C.WHITE, C.STEEL, 190, "FrontPierWestWall")
	wallRun(shell, "FrontPierEastWall", "X", BZ1, GX1, BX1, FLOOR_TOP, WALL_TOP, WT,
		C.WHITE, C.STEEL, 190, "FrontPierEastWall")
	-- Dải tường phía trên vách kính (Y 27.6 → 39.2)
	wallRun(shell, "FrontSpandrel", "X", BZ1 + 0.25, BX0 + 1.0, BX1 - 1.0, GLASS_Y1 + 0.1, ROOF_BOT, 0.9,
		C.STEEL, C.WHITE, 170, "FrontSpandrel")

	-- Cột góc + cột nhịp mặt tiền (bọc thép trắng)
	for i, col in ipairs({ { BX0, BZ0 }, { BX1, BZ0 }, { BX0, BZ1 }, { BX1, BZ1 } }) do
		local g = "CornerColumn" .. i
		box(shell, g .. "_Core", Vector3.new(2.6, WALL_TOP - FLOOR_TOP - 0.12, 2.6),
			Vector3.new(col[1], (FLOOR_TOP + WALL_TOP - 0.12) * 0.5, col[2]),
			C.WHITE, M.Metal, 300, g, 1)
		for k = 0, 5 do
			box(shell, string.format("%s_Ring%d", g, k + 1), Vector3.new(2.9, 0.28, 2.9),
				Vector3.new(col[1], FLOOR_TOP + 3.0 + k * 6.2, col[2]),
				C.CHROME, M.Metal, 80, g, 2, SMALL_OPTS)
		end
	end

	-- Cửa cuốn xe 18 × 12 stud (10 nan, mỗi nan một bể máu)
	local garage = folder("08_GarageDoor", shell)
	for k = 0, 9 do
		box(garage, string.format("GarageRollupSlat_%02d", k + 1),
			Vector3.new(0.30, 1.2, 18.0),
			Vector3.new(BX0 - 0.05, FLOOR_TOP + 0.6 + k * 1.2, -163.0),
			if k % 2 == 0 then C.STEEL else C.WHITE, M.Metal, 70, "GarageDoor", k + 1)
	end
	for s, gz in ipairs({ -172.4, -153.6 }) do
		box(garage, string.format("GarageRail_%d", s), Vector3.new(0.7, 12.6, 0.7),
			Vector3.new(BX0 - 0.85, FLOOR_TOP + 6.3, gz), C.CHARCOAL, M.Metal, 210, "GarageDoor", 1)
	end
	box(garage, "GarageHeader", Vector3.new(1.6, 1.2, 19.4),
		Vector3.new(BX0 - 0.55, FLOOR_TOP + 12.9, -163.0), C.CHARCOAL, M.Metal, 240, "GarageDoor", 1)
		box(garage, "GarageMotor", Vector3.new(2.2, 1.8, 2.6),
			Vector3.new(BX0 - 1.3, FLOOR_TOP + 13.3, -153.0), C.STEEL_DK, M.Metal, 130, "GarageDoor", 2)
	local gsign = box(garage, "GarageSign", Vector3.new(0.35, 2.2, 12.0),
		Vector3.new(BX0 - 0.75, FLOOR_TOP + 15.0, -163.0), C.CHARCOAL, M.Metal, 90, "GarageDoor", 3)
	gui(gsign, "GIAO NHẬN XE  ·  DELIVERY", 20, 36, Enum.NormalId.Left)

	-- 3.3 ─────────────────── MẶT TIỀN KÍNH CONG 2 LỚP ──────────────────────
	local facade = folder("09_CurvedGlassFacade", root)
	local DOOR_X0, DOOR_X1 = -234.0, -218.0
	local DOOR_TOP = GLASS_Y0 + 2 * ROW_H
	local DOOR_H = 8.5
	local CRASH_X0, CRASH_X1 = -296.0, -272.0

	for layer = 1, 2 do
		local lz = if layer == 1 then 0.0 else -LAYER_GAP
		local lp = "L" .. layer
		-- 2 dầm cong đáy / đỉnh
		for edge = 0, 1 do
			local ey = if edge == 0 then GLASS_Y0 + 0.22 else GLASS_Y1 - 0.22
			for b = 0, BAYS - 1 do
				local cx = GX0 + (b + 0.5) * BAY_W
				rbox(facade, string.format("FacadeBeam_%s_E%d_B%02d", lp, edge, b + 1),
					Vector3.new(BAY_W - 0.02, 0.55, 0.72),
					cfAt(cx, ey, arcZ(cx) + lz + 0.10, arcYaw(cx)),
					C.WHITE, M.Metal, 220, "FacadeFrame_" .. lp, 1)
			end
		end
		-- Trụ đứng (mullion) — bỏ đoạn dưới ở CrashLane cho xe tông xuyên
		for i = 0, BAYS do
			local x = GX0 + i * BAY_W
			local inCrash = x >= CRASH_X0 and x <= CRASH_X1
			if inCrash then
				rbox(facade, string.format("FacadeMullion_%s_%02d_Upper", lp, i + 1),
					Vector3.new(MULLION_W, GLASS_Y1 - (GLASS_Y0 + 3 * ROW_H), 0.50),
					cfAt(x, (GLASS_Y1 + GLASS_Y0 + 3 * ROW_H) * 0.5, arcZ(x) + lz, arcYaw(x)),
					C.WHITE, M.Metal, 180, "FacadeFrame_" .. lp, 2)
			else
				rbox(facade, string.format("FacadeMullion_%s_%02d", lp, i + 1),
					Vector3.new(MULLION_W, GLASS_H, 0.50),
					cfAt(x, (GLASS_Y0 + GLASS_Y1) * 0.5, arcZ(x) + lz, arcYaw(x)),
					C.WHITE, M.Metal, 210, "FacadeFrame_" .. lp, 2)
			end
		end
		-- Thanh ngang (transom) theo từng nhịp
		for r = 0, ROWS do
			local ry = GLASS_Y0 + r * ROW_H
			for b = 0, BAYS - 1 do
				local cx = GX0 + (b + 0.5) * BAY_W
				local inDoor = cx > DOOR_X0 - 2.0 and cx < DOOR_X1 + 2.0 and r <= 2
				local inCrash = cx >= CRASH_X0 and cx <= CRASH_X1 and r <= 3
				if not inDoor then
					local hp = if inCrash then 40 else 150
					rbox(facade, string.format("FacadeTransom_%s_R%d_B%02d", lp, r, b + 1),
						Vector3.new(BAY_W - 0.10, TRANSOM_H, 0.44),
						cfAt(cx, ry, arcZ(cx) + lz + 0.18, arcYaw(cx)),
						C.WHITE, M.Metal, hp, "FacadeFrame_" .. lp, 2)
				end
			end
		end
		-- Ô kính: MỖI Ô 1 KHỐI, integrity = 40, CanCollide = false
		for b = 0, BAYS - 1 do
			local cx = GX0 + (b + 0.5) * BAY_W
			for r = 0, ROWS - 1 do
				local cy = GLASS_Y0 + (r + 0.5) * ROW_H
				local inDoor = cx > DOOR_X0 - 2.0 and cx < DOOR_X1 + 2.0 and r < 2
				if not inDoor then
					rbox(facade, string.format("FacadeGlass_%s_B%02d_R%d", lp, b + 1, r + 1),
						Vector3.new(BAY_W - 0.44, ROW_H - 0.34, 0.16),
						cfAt(cx, cy, arcZ(cx) + lz, arcYaw(cx)),
						if layer == 1 then C.GLASS else C.GLASS_DK, M.Glass, 40,
						"FacadeGlass_" .. lp .. "_B" .. (b + 1), r + 1, GLASS_OPTS)
				end
			end
		end
	end

	-- Cửa đi bộ đôi kính 16 × 8.5 (mỗi cánh riêng, máu 40 -> đẩy/xe tông vỡ)
	local doors = folder("10_Entrance", root)
	local doorZ = arcZ(-226.0) + 0.55
	for s, sx in ipairs({ -230.0, -222.0 }) do
		box(doors, if s == 1 then "MainDoorLeaf_L" else "MainDoorLeaf_R",
			Vector3.new(7.85, DOOR_H, 0.24),
			Vector3.new(sx, GLASS_Y0 + DOOR_H * 0.5, doorZ),
			C.GLASS, M.Glass, 40, "MainDoor", 1, GLASS_OPTS)
		box(doors, string.format("DoorFrameV_%d", s), Vector3.new(0.30, DOOR_H + 0.8, 0.42),
			Vector3.new(sx + (s == 1 and -4.05 or 4.05), GLASS_Y0 + (DOOR_H + 0.8) * 0.5, doorZ + 0.18),
			C.WHITE, M.Metal, 160, "MainDoor", 2)
		vcyl(doors, string.format("DoorHandle_%d", s), Vector3.new(0.5, 0.24, 0.24),
			Vector3.new(sx + (s == 1 and 3.1 or -3.1), GLASS_Y0 + 4.1, doorZ + 0.36),
			C.CHROME, M.Metal, 45, "MainDoor", 3, SMALL_OPTS)
	end
	box(doors, "MainDoor_Header", Vector3.new(16.8, 0.55, 0.5),
		Vector3.new(-226.0, GLASS_Y0 + DOOR_H + 0.3, doorZ + 0.2),
		C.WHITE, M.Metal, 170, "MainDoor", 2)
	box(doors, "MainDoor_Threshold", Vector3.new(17.0, 0.18, 3.4),
		Vector3.new(-226.0, FLOOR_TOP + 0.09, doorZ + 1.9),
		C.CHARCOAL, M.Metal, 120, "MainDoor", 1)
	-- Mái hiên kính + 2 cột inox
	local canopy = folder("11_Canopy", root)
	for s, cx in ipairs({ -240.0, -212.0 }) do
		vcyl(canopy, string.format("CanopyColumn_%d", s), Vector3.new(10.6, 0.75, 0.75),
			Vector3.new(cx, APRON_TOP + 5.3, arcZ(cx) + 7.2), C.CHROME, M.Metal, 200, "Canopy", 1)
	end
	for i = 0, 5 do
		local cx = -244.0 + (i + 0.5) * 6.0
		box(canopy, string.format("CanopyGlass_%02d", i + 1), Vector3.new(5.7, 0.16, 8.2),
			Vector3.new(cx, GLASS_Y0 + 10.48, arcZ(cx) + 3.6),
			C.GLASS, M.Glass, 40, "Canopy", 2, GLASS_OPTS)
	end
	box(canopy, "CanopyFrontBeam", Vector3.new(38.0, 0.6, 0.6),
		Vector3.new(-226.0, GLASS_Y0 + 10.12, arcZ(-226.0) + 7.8),
		C.WHITE, M.Metal, 190, "Canopy", 2)

	-- 3.4 ───────────────────── BIỂN HIỆU NEON + PYLON ───────────────────────
	local sign = folder("12_NeonSign", root)
	local SIGN_Y = 31.2
	local SIGN_Z = arcZ(-226.0) + 2.4
	for s, px in ipairs({ -270.0, -182.0 }) do
		box(sign, string.format("SignPylon_%d_Foot", s), Vector3.new(3.4, 1.0, 3.4),
			Vector3.new(px, APRON_TOP + 0.5, SIGN_Z - 0.4), C.CHARCOAL, M.Metal, 260, "SignPylon", 1)
		box(sign, string.format("SignPylon_%d_Shaft", s), Vector3.new(1.5, SIGN_Y - APRON_TOP - 1.0, 1.5),
			Vector3.new(px, (SIGN_Y + APRON_TOP + 1.0) * 0.5, SIGN_Z - 0.4),
			C.WHITE, M.Metal, 260, "SignPylon", 2)
		box(sign, string.format("SignPylon_%d_Cap", s), Vector3.new(2.0, 0.5, 2.0),
			Vector3.new(px, SIGN_Y + 0.25, SIGN_Z - 0.4), C.CHROME, M.Metal, 120, "SignPylon", 3)
	end
	box(sign, "SignTruss", Vector3.new(90.0, 1.0, 1.0),
		Vector3.new(-226.0, SIGN_Y + 0.4, SIGN_Z - 0.4), C.STEEL, M.Metal, 260, "SignTruss", 2)
	for i = 0, 5 do
		box(sign, string.format("SignStrut_%02d", i + 1), Vector3.new(0.5, 0.5, 2.6),
			Vector3.new(-263.0 + i * 14.8, SIGN_Y + 0.4, SIGN_Z - 0.8),
			C.STEEL_DK, M.Metal, 120, "SignTruss", 3)
	end
	local board = box(sign, "SignBoard_LuxuryAutos", Vector3.new(76.0, 7.2, 0.55),
		Vector3.new(-226.0, SIGN_Y, SIGN_Z + 0.6), C.CHARCOAL, M.Metal, 240, "SignBoard", 2)
	gui(board, "LUXURY AUTOS  ·  ROCKFORD HILLS  ·  OLYMPIC FWY", 12, 54, Enum.NormalId.Back)
	box(sign, "SignBoard_UpperTrim", Vector3.new(76.6, 0.30, 0.85),
		Vector3.new(-226.0, SIGN_Y + 3.75, SIGN_Z + 0.6), C.CHROME, M.Metal, 110, "SignBoard", 3)
	box(sign, "SignBoard_LowerTrim", Vector3.new(76.6, 0.30, 0.85),
		Vector3.new(-226.0, SIGN_Y - 3.75, SIGN_Z + 0.6), C.CHROME, M.Metal, 110, "SignBoard", 3)

	-- Chữ nổi Neon trắng "LUXURY AUTOS" — font 3×5, mỗi pixel 1 khối có máu ẩn
	local FONT = {
		A = { "010", "101", "111", "101", "101" },
		L = { "100", "100", "100", "100", "111" },
		U = { "101", "101", "101", "101", "111" },
		X = { "101", "101", "010", "101", "101" },
		R = { "110", "101", "110", "101", "101" },
		Y = { "101", "101", "010", "010", "010" },
		T = { "111", "010", "010", "010", "010" },
		O = { "111", "101", "101", "101", "111" },
		S = { "111", "100", "111", "001", "111" },
	}
	local word = "LUXURY AUTOS"
	local cellW, cellH = 1.42, 0.84
	local stepW, stepH = 1.52, 0.92
	local charW = 3 * stepW + 0.9
	local totalW = #word * charW - 0.9
	local startX = -226.0 - totalW * 0.5 + charW * 0.5
	local letterCount = 0
	for ci = 1, #word do
		local ch = string.sub(word, ci, ci)
		local pat = FONT[ch]
		if pat then
			letterCount += 1
			local lx = startX + (ci - 1) * charW
			for r = 1, 5 do
				local rowStr = pat[r]
				for col = 1, 3 do
					if string.sub(rowStr, col, col) == "1" then
						box(sign, string.format("NeonLetter_%02d_%d_%d", letterCount, r, col),
							Vector3.new(cellW, cellH, 0.28),
							Vector3.new(lx + (col - 2) * stepW, SIGN_Y + (3 - r) * stepH,
								SIGN_Z + 0.6 + 0.275 + 0.22),
							C.NEON, M.Neon, 25, "NeonSign", 3, NEON_OPTS)
					end
				end
			end
		end
	end

	-- Biển pylon đứng ngoài sân (2 mặt)
	local pylon = folder("13_PylonSign", root)
	for s, px in ipairs({ -256.0, -196.0 }) do
		box(pylon, string.format("Pylon_%d_Foot", s), Vector3.new(3.0, 1.0, 3.0),
			Vector3.new(px, APRON_TOP + 0.5, -66.0), C.CHARCOAL, M.Metal, 220, "Pylon", 1)
		box(pylon, string.format("Pylon_%d_Shaft", s), Vector3.new(1.2, 15.0, 1.2),
			Vector3.new(px, APRON_TOP + 8.0, -66.0), C.WHITE, M.Metal, 220, "Pylon", 2)
	end
	local pboard = box(pylon, "Pylon_Board", Vector3.new(64.0, 4.2, 0.6),
		Vector3.new(-226.0, APRON_TOP + 14.0, -66.0), C.CHARCOAL, M.Metal, 200, "Pylon", 3)
	gui(pboard, "LUXURY AUTOS  ·  PREMIUM MOTORS  ·  SIMEON YETARIAN", 12, 46, Enum.NormalId.Back)
	for i = 0, 15 do
		box(pylon, string.format("Pylon_Bulb_%02d", i + 1), Vector3.new(0.7, 0.7, 0.25),
			Vector3.new(-257.0 + i * 4.1, APRON_TOP + 16.3, -66.0 + 0.42),
			C.NEON, M.Neon, 25, "Pylon", 4, NEON_OPTS)
	end

	-- 3.5 ───────────────── SẢNH TRƯNG BÀY + 2 BỤC XOAY + 3 XE ─────────────
	local hall = folder("14_ShowroomHall", root)

	-- Bục xoay tròn (đĩa + 16 mảnh vành + LED + trục tâm)
	local TT_TOP = 2.10
	local function turntable(idx: number, cx: number, cz: number, accent: Color3)
		local g = "Turntable" .. idx
		local f = folder(g, hall)
		vcyl(f, g .. "_Disc", Vector3.new(0.75, 20.0, 20.0),
			Vector3.new(cx, TT_TOP - 0.375, cz), C.CHARCOAL, M.Metal, 300, g, 1,
			{ reflectance = 0.25, canCollide = true })
		vcyl(f, g .. "_Inlay", Vector3.new(0.10, 17.6, 17.6),
			Vector3.new(cx, TT_TOP + 0.05, cz), accent, M.Neon, 60, g, 2,
			{ canCollide = false, castShadow = false })
		vcyl(f, g .. "_Hub", Vector3.new(0.30, 4.0, 4.0),
			Vector3.new(cx, TT_TOP + 0.15, cz), C.CHROME, M.Metal, 120, g, 3)
		for k = 0, 15 do
			local a = (k / 16) * math.pi * 2
			local rx, rz = cx + math.cos(a) * 9.3, cz + math.sin(a) * 9.3
			rbox(f, string.format("%s_Rim_%02d", g, k + 1), Vector3.new(2.1, 0.42, 0.85),
				cfAt(rx, TT_TOP + 0.21, rz, -a),
				C.WHITE, M.Metal, 90, g, 2)
			box(f, string.format("%s_LED_%02d", g, k + 1), Vector3.new(1.0, 0.16, 0.30),
				Vector3.new(cx + math.cos(a) * 8.7, TT_TOP + 0.18, cz + math.sin(a) * 8.7),
				accent, M.Neon, 30, g, 3, NEON_OPTS)
		end
	end
	turntable(1, -248.0, -152.0, C.CAR_RED)
	turntable(2, -204.0, -152.0, C.CAR_YELLOW)

	-- Xe mô hình tĩnh dựng bằng khối (KHÔNG spawn VehicleBuilder)
	local function car(name: string, cx: number, cz: number, baseY: number, paint: Color3, yaw: number)
		local f = folder(name, hall)
		local g = name
		local function cbox(nm: string, sz: Vector3, off: Vector3, col: Color3, mat: Enum.Material, hp: number, opts: { [string]: any }?)
			local rotated = CFrame.new(cx, baseY, cz) * CFrame.Angles(0, yaw, 0)
			local p = rotated * off
			return rbox(f, g .. "_" .. nm, sz, CFrame.new(p.X, p.Y, p.Z) * CFrame.Angles(0, yaw, 0),
				col, mat, hp, g, 1, opts)
		end
		cbox("Chassis", Vector3.new(15.0, 1.0, 7.0), Vector3.new(0, 1.1, 0), C.CHARCOAL, M.Metal, 150)
		cbox("Body", Vector3.new(13.6, 1.8, 6.7), Vector3.new(0, 2.25, 0), paint, M.SmoothPlastic, 130,
			{ reflectance = 0.35 })
		cbox("Hood", Vector3.new(4.2, 0.55, 6.4), Vector3.new(4.9, 3.25, 0), paint, M.SmoothPlastic, 90,
			{ reflectance = 0.35 })
		cbox("Cabin", Vector3.new(6.6, 1.9, 5.9), Vector3.new(-0.9, 3.6, 0), C.GLASS_DK, M.Glass, 45, GLASS_OPTS)
		cbox("Roof", Vector3.new(5.2, 0.35, 5.6), Vector3.new(-1.1, 4.65, 0), paint, M.SmoothPlastic, 80)
		cbox("Windshield", Vector3.new(0.18, 1.5, 5.4), Vector3.new(2.45, 3.7, 0), C.GLASS, M.Glass, 40, GLASS_OPTS)
		cbox("RearGlass", Vector3.new(0.18, 1.4, 5.2), Vector3.new(-4.0, 3.7, 0), C.GLASS, M.Glass, 40, GLASS_OPTS)
		for s, sx in ipairs({ 4.7, -4.7 }) do
			for t, sz in ipairs({ 3.5, -3.5 }) do
				local rotated = CFrame.new(cx, baseY, cz) * CFrame.Angles(0, yaw, 0)
				local p = rotated * Vector3.new(sx, 1.35, sz)
				wheel(f, string.format("%s_Wheel_%d_%d", g, s, t), Vector3.new(p.X, p.Y, p.Z), 90, g)
			end
		end
		for s, sz in ipairs({ 2.2, -2.2 }) do
			cbox(string.format("Headlight_%d", s), Vector3.new(0.25, 0.55, 1.5),
				Vector3.new(7.0, 2.45, sz), C.NEON, M.Neon, 30, NEON_OPTS)
			cbox(string.format("Taillight_%d", s), Vector3.new(0.25, 0.55, 1.4),
				Vector3.new(-7.0, 2.45, sz), C.RED, M.Neon, 30, NEON_OPTS)
			cbox(string.format("DoorPanel_%d", s), Vector3.new(5.6, 1.2, 0.18),
				Vector3.new(-0.4, 2.6, sz * 1.62), paint, M.SmoothPlastic, 70)
			cbox(string.format("Mirror_%d", s), Vector3.new(0.8, 0.4, 0.55),
				Vector3.new(1.9, 3.85, sz * 1.32), C.CHARCOAL, M.Metal, 35, SMALL_OPTS)
		end
		cbox("FrontBumper", Vector3.new(0.7, 0.7, 6.8), Vector3.new(7.2, 1.55, 0), C.CHARCOAL, M.Metal, 90)
		cbox("RearBumper", Vector3.new(0.7, 0.7, 6.8), Vector3.new(-7.2, 1.55, 0), C.CHARCOAL, M.Metal, 90)
		cbox("Grille", Vector3.new(0.16, 0.8, 4.2), Vector3.new(7.55, 2.2, 0), C.BLACK, M.Metal, 50, SMALL_OPTS)
		cbox("SpoilerPost_L", Vector3.new(0.3, 0.9, 0.3), Vector3.new(-6.3, 3.5, 2.2), C.CHARCOAL, M.Metal, 45, SMALL_OPTS)
		cbox("SpoilerPost_R", Vector3.new(0.3, 0.9, 0.3), Vector3.new(-6.3, 3.5, -2.2), C.CHARCOAL, M.Metal, 45, SMALL_OPTS)
		cbox("SpoilerWing", Vector3.new(1.6, 0.25, 6.2), Vector3.new(-6.3, 4.05, 0), C.CHARCOAL, M.Metal, 60)
		cbox("RoofStripe", Vector3.new(5.4, 0.06, 0.7), Vector3.new(-1.1, 4.85, 0), C.WHITE, M.SmoothPlastic, 25, SMALL_OPTS)
		cbox("Exhaust_L", Vector3.new(0.6, 0.45, 0.45), Vector3.new(-7.5, 1.4, 1.8), C.CHROME, M.Metal, 35, SMALL_OPTS)
		cbox("Exhaust_R", Vector3.new(0.6, 0.45, 0.45), Vector3.new(-7.5, 1.4, -1.8), C.CHROME, M.Metal, 35, SMALL_OPTS)
	end
	car("Car_01_RedSupercar", -248.0, -152.0, TT_TOP, C.CAR_RED, math.rad(12))
	car("Car_02_YellowSupercar", -204.0, -152.0, TT_TOP, C.CAR_YELLOW, math.rad(-16))
	car("Car_03_BlueSedan", -226.0, -128.0, FLOOR_TOP, C.CAR_BLUE, math.rad(0))

	-- Đèn rọi trần chiếu vào 2 bục + xe giữa (mỗi bộ: đế + cần + chụp + bóng)
	local spots = folder("15_Spotlights", root)
	for i, sp in ipairs({ { -248.0, -152.0 }, { -204.0, -152.0 }, { -226.0, -128.0 },
		{ -272.0, -138.0 }, { -180.0, -138.0 }, { -226.0, -170.0 },
		{ -260.0, -120.0 }, { -192.0, -120.0 }, { -226.0, -116.0 },
		{ -280.0, -168.0 }, { -172.0, -168.0 }, { -226.0, -186.0 } }) do
		local g = "Spot" .. i
		-- Ty treo xuyên qua giếng trời tới kính mái (đèn không bị lơ lửng)
		box(spots, g .. "_Hanger", Vector3.new(0.24, 0.75, 0.24),
			Vector3.new(sp[1], ROOF_BOT + 0.30, sp[2]), C.STEEL_DK, M.Metal, 70, g, 1, SMALL_OPTS)
		box(spots, g .. "_Rod", Vector3.new(0.35, 0.6, 0.35),
			Vector3.new(sp[1], ROOF_BOT - 0.3, sp[2]), C.STEEL_DK, M.Metal, 70, g, 1, SMALL_OPTS)
		vcyl(spots, g .. "_Housing", Vector3.new(1.4, 1.5, 1.5),
			Vector3.new(sp[1], ROOF_BOT - 1.3, sp[2]), C.CHARCOAL, M.Metal, 80, g, 2)
		box(spots, g .. "_Bulb", Vector3.new(0.9, 0.25, 0.9),
			Vector3.new(sp[1], ROOF_BOT - 2.05, sp[2]), C.NEON, M.Neon, 25, g, 3, NEON_OPTS)
	end

	-- 3.6 ─────────────────── CẦU THANG CONG LÊN TẦNG LỬNG ──────────────────
	local stairs = folder("16_CurvedStaircase", root)
	local SC_X, SC_Z, SC_R = -263.0, -134.0, 10.5
	local STEPS = 18
	local rise = MEZZ_TOP - FLOOR_TOP - 0.06
	for s = 1, STEPS do
		local t = (s - 1) / (STEPS - 1)
		local a = math.rad(-35) + t * math.rad(205)
		local sx, sz = SC_X + math.cos(a) * SC_R, SC_Z + math.sin(a) * SC_R
		local h = FLOOR_TOP + rise * (s / STEPS)
		-- Đáy mỗi bậc nhích 0.03 stud so với bậc trước -> không có mặt đồng phẳng
		local stepBot = FLOOR_TOP + (s - 1) * 0.03
		-- Mỗi bậc là khối ĐẶC từ đáy lên tới mặt bậc -> tự đỡ, 0 lơ lửng
		rbox(stairs, string.format("CurvedStep_%02d", s), Vector3.new(6.2, h - stepBot, 2.3),
			cfAt(sx, (stepBot + h) * 0.5, sz, -a - math.pi * 0.5),
			if s % 2 == 0 then C.MARBLE else C.MARBLE2, M.Marble, 150, "CurvedStair", s,
			{ canCollide = true })
		-- Lan can kính + tay vịn inox
		local outerR = SC_R + 1.1
		local ox, oz = SC_X + math.cos(a) * outerR, SC_Z + math.sin(a) * outerR
		rbox(stairs, string.format("CurvedGlassBalustrade_%02d", s), Vector3.new(2.2, 2.6, 0.16),
			cfAt(ox, h + 1.3, oz, -a - math.pi * 0.5),
			C.GLASS, M.Glass, 40, "CurvedStair", s, GLASS_OPTS)
		rbox(stairs, string.format("CurvedHandrail_%02d", s), Vector3.new(2.35, 0.18, 0.30),
			cfAt(ox, h + 2.72, oz, -a - math.pi * 0.5),
			C.CHROME, M.Metal, 70, "CurvedStair", s, SMALL_OPTS)
	end

	-- 3.7 ─────────────────────── TẦNG LỬNG / MEZZANINE ─────────────────────
	local mezz = folder("17_Mezzanine", root)
	local MEZZ_DECK = 0.60
	local mezzZones = {
		{ "West", -300.0, -266.0, BZ0 + 1, BZ1 - 1 },
		{ "East", -186.0, -152.0, BZ0 + 1, BZ1 - 1 },
		{ "North", -266.0, -186.0, -188.0, -174.0 },
	}
	for i, z in ipairs(mezzZones) do
		box(mezz, "MezzDeckBase_" .. z[1], Vector3.new(z[3] - z[2], MEZZ_DECK - 0.08, z[5] - z[4]),
			Vector3.new((z[2] + z[3]) * 0.5, MEZZ_TOP - 0.08 - (MEZZ_DECK - 0.08) * 0.5, (z[4] + z[5]) * 0.5),
			C.CONCRETE2, M.Concrete, nil, nil, nil, { canCollide = true })
		tileField(mezz, "MezzTile_" .. z[1], z[2], z[3], z[4], z[5],
			MEZZ_TOP, 0.07, math.max(2, math.floor((z[3] - z[2]) / 8)),
			math.max(2, math.floor((z[5] - z[4]) / 8)),
			C.MARBLE2, C.MARBLE, 130, "MezzTile")
	end

	-- Lan can kính dọc 3 mép thông tầng
	local rail = folder("18_MezzRailing", root)
	local function railing(prefix: string, x0: number, x1: number, z0: number, z1: number, baseY: number, count: number, skipEnds: boolean?)
		for i = 0, count do
			local t = i / count
			local px, pz = x0 + (x1 - x0) * t, z0 + (z1 - z0) * t
			if not (skipEnds and (i == 0 or i == count)) then
				box(rail, string.format("%s_Post_%02d", prefix, i + 1), Vector3.new(0.35, 3.5, 0.35),
					Vector3.new(px, baseY + 1.75, pz), C.CHROME, M.Metal, 110, prefix, 1, SMALL_OPTS)
			end
			if i < count then
				local nx, nz = x0 + (x1 - x0) * ((i + 1) / count), z0 + (z1 - z0) * ((i + 1) / count)
				local dx, dz = nx - px, nz - pz
				local ln = math.sqrt(dx * dx + dz * dz)
				local yaw = -math.atan2(dz, dx)
				rbox(rail, string.format("%s_Glass_%02d", prefix, i + 1), Vector3.new(ln - 0.12, 2.9, 0.16),
					cfAt((px + nx) * 0.5, baseY + 1.55, (pz + nz) * 0.5, yaw),
					C.GLASS, M.Glass, 40, prefix, 2, GLASS_OPTS)
				rbox(rail, string.format("%s_Rail_%02d", prefix, i + 1), Vector3.new(ln, 0.16, 0.28),
					cfAt((px + nx) * 0.5, baseY + 3.45, (pz + nz) * 0.5, yaw),
					C.CHROME, M.Metal, 80, prefix, 3, SMALL_OPTS)
			end
		end
	end
	railing("MezzRailWest", -266.0, -266.0, -174.0, -112.0, MEZZ_TOP, 8)
	railing("MezzRailEast", -186.0, -186.0, -174.0, -112.0, MEZZ_TOP, 8)
	railing("MezzRailNorth", -266.0, -186.0, -174.0, -174.0, MEZZ_TOP, 10, true)

	-- Phòng làm việc kính của quản lý (tầng lửng cánh Tây)
	local office = folder("19_ManagerOffice", root)
	local OFX0, OFX1, OFZ0, OFZ1 = -298.0, -270.0, -184.0, -158.0
	for i = 0, 5 do
		local gx = OFX0 + (i + 0.5) * ((OFX1 - OFX0) / 6)
		box(office, string.format("OfficeGlassSouth_%02d", i + 1),
			Vector3.new((OFX1 - OFX0) / 6 - 0.16, 9.6, 0.16),
			Vector3.new(gx, MEZZ_TOP + 4.8, OFZ1), C.GLASS, M.Glass, 40, "OfficeGlass", 1, GLASS_OPTS)
		box(office, string.format("OfficeMullionSouth_%02d", i + 1),
			Vector3.new(0.22, 9.8, 0.34), Vector3.new(gx + 2.3, MEZZ_TOP + 4.9, OFZ1 + 0.12),
			C.WHITE, M.Metal, 120, "OfficeGlass", 2, SMALL_OPTS)
	end
	for i = 0, 4 do
		local gz = OFZ0 + (i + 0.5) * ((OFZ1 - OFZ0) / 5)
		box(office, string.format("OfficeGlassEast_%02d", i + 1),
			Vector3.new(0.16, 9.6, (OFZ1 - OFZ0) / 5 - 0.16),
			Vector3.new(OFX1, MEZZ_TOP + 4.8, gz), C.GLASS, M.Glass, 40, "OfficeGlass", 1, GLASS_OPTS)
	end
	box(office, "OfficeDoorFrame", Vector3.new(0.4, 9.8, 3.4),
		Vector3.new(OFX1, MEZZ_TOP + 4.9, -161.0), C.WHITE, M.Metal, 130, "OfficeGlass", 2)
	local oSign = box(office, "OfficeSign", Vector3.new(11.0, 1.6, 0.25),
		Vector3.new(-284.0, MEZZ_TOP + 10.6, OFZ1 + 0.2), C.CHARCOAL, M.Metal, 80, "OfficeGlass", 3)
	gui(oSign, "QUẢN LÝ  ·  MANAGER", 24, 40, Enum.NormalId.Back)

	-- Bàn giám đốc + ghế + màn hình + tủ hồ sơ
	box(office, "ManagerDesk_Top", Vector3.new(11.0, 0.45, 4.2),
		Vector3.new(-284.0, MEZZ_TOP + 2.9, -178.0), C.WOOD, M.Wood or M.SmoothPlastic, 140, "ManagerDesk", 2,
		{ reflectance = 0.18 })
	for s, sx in ipairs({ -289.0, -279.0 }) do
		box(office, string.format("ManagerDesk_Leg%d", s), Vector3.new(0.7, 2.9, 3.8),
			Vector3.new(sx, MEZZ_TOP + 1.45, -178.0), C.CHARCOAL, M.Metal, 130, "ManagerDesk", 1)
	end
	for i = 0, 2 do
		box(office, string.format("DeskMonitor_%d", i + 1), Vector3.new(2.6, 1.7, 0.18),
			Vector3.new(-288.0 + i * 3.8, MEZZ_TOP + 4.2, -179.4), C.BLACK, M.Metal, 45, "ManagerDesk", 3)
		box(office, string.format("DeskMonitorStand_%d", i + 1), Vector3.new(0.3, 0.8, 0.3),
			Vector3.new(-288.0 + i * 3.8, MEZZ_TOP + 3.5, -179.4), C.STEEL, M.Metal, 35, "ManagerDesk", 3, SMALL_OPTS)
	end
	box(office, "ManagerChair_Seat", Vector3.new(2.6, 0.5, 2.6),
		Vector3.new(-284.0, MEZZ_TOP + 1.9, -173.0), C.LEATHER, M.Leather or M.SmoothPlastic, 90, "ManagerChair", 2)
	box(office, "ManagerChair_Back", Vector3.new(2.6, 3.0, 0.45),
		Vector3.new(-284.0, MEZZ_TOP + 3.4, -171.8), C.LEATHER, M.Leather or M.SmoothPlastic, 90, "ManagerChair", 3)
	vcyl(office, "ManagerChair_Post", Vector3.new(1.5, 0.4, 0.4),
		Vector3.new(-284.0, MEZZ_TOP + 0.75, -173.0), C.CHROME, M.Metal, 60, "ManagerChair", 1)
	for i = 0, 3 do
		box(office, string.format("FilingCabinet_%d", i + 1), Vector3.new(2.6, 3.4, 2.2),
			Vector3.new(-295.0 + i * 2.8, MEZZ_TOP + 1.7, -181.0),
			C.STEEL_DK, M.Metal, 110, "FilingCabinet", 1)
		box(office, string.format("FilingHandle_%d", i + 1), Vector3.new(1.2, 0.18, 0.15),
			Vector3.new(-295.0 + i * 2.8, MEZZ_TOP + 2.3, -179.85), C.CHROME, M.Metal, 30, "FilingCabinet", 2, SMALL_OPTS)
	end

	-- Sofa da + bàn cà phê + thảm + cây cảnh trong nhà
	local lounge = folder("20_MezzLounge", root)
	box(lounge, "LoungeRug", Vector3.new(18.0, 0.08, 11.0),
		Vector3.new(-170.0, MEZZ_TOP + 0.06, -150.0), C.CHARCOAL, M.SmoothPlastic, 60, "Lounge", 1, SMALL_OPTS)
	for s, sz in ipairs({ -156.0, -144.0 }) do
		box(lounge, string.format("Sofa_%d_Base", s), Vector3.new(10.0, 1.8, 3.4),
			Vector3.new(-170.0, MEZZ_TOP + 0.9, sz), C.LEATHER, M.Leather or M.SmoothPlastic, 120, "Lounge", 1)
		box(lounge, string.format("Sofa_%d_Back", s), Vector3.new(10.0, 2.6, 0.7),
			Vector3.new(-170.0, MEZZ_TOP + 2.7, sz + (s == 1 and -1.35 or 1.35)),
			C.LEATHER, M.Leather or M.SmoothPlastic, 120, "Lounge", 2)
		for a = -1, 1, 2 do
			box(lounge, string.format("Sofa_%d_Arm%d", s, a), Vector3.new(0.7, 2.2, 3.4),
				Vector3.new(-170.0 + a * 4.5, MEZZ_TOP + 1.15, sz),
				C.LEATHER, M.Leather or M.SmoothPlastic, 100, "Lounge", 2)
		end
	end
	box(lounge, "CoffeeTable_Top", Vector3.new(7.0, 0.35, 3.4),
		Vector3.new(-170.0, MEZZ_TOP + 1.6, -150.0), C.WHITE, M.Marble, 90, "Lounge", 2,
		{ reflectance = 0.3 })
	for a = -1, 1, 2 do
		for b = -1, 1, 2 do
			box(lounge, string.format("CoffeeTable_Leg_%d_%d", a, b), Vector3.new(0.3, 1.6, 0.3),
				Vector3.new(-170.0 + a * 2.9, MEZZ_TOP + 0.8, -150.0 + b * 1.2),
				C.CHROME, M.Metal, 45, "Lounge", 1, SMALL_OPTS)
		end
	end
	for i = 0, 2 do
		ball(lounge, string.format("LoungePlant_%d_Pot", i + 1), 2.0,
			Vector3.new(-183.0 + i * 13.0, MEZZ_TOP + 1.0, -166.0), C.WHITE, 70, "LoungePlant")
		ball(lounge, string.format("LoungePlant_%d_Leaf", i + 1), 3.0,
			Vector3.new(-183.0 + i * 13.0, MEZZ_TOP + 3.0, -166.0), C.GREEN, 45, "LoungePlant")
	end

	-- Quầy cà phê + máy pha + ly + 3 ghế đôn
	local cafe = folder("21_CoffeeCounter", root)
	box(cafe, "CafeCounter_Body", Vector3.new(20.0, 2.6, 3.2),
		Vector3.new(-169.0, MEZZ_TOP + 1.3, -174.0), C.WOOD, M.Wood or M.SmoothPlastic, 160, "Cafe", 1)
	box(cafe, "CafeCounter_Top", Vector3.new(21.0, 0.35, 3.8),
		Vector3.new(-169.0, MEZZ_TOP + 2.75, -174.0), C.WHITE, M.Marble, 130, "Cafe", 2,
		{ reflectance = 0.30 })
	box(cafe, "EspressoMachine", Vector3.new(4.2, 2.4, 2.2),
		Vector3.new(-174.0, MEZZ_TOP + 4.1, -174.0), C.CHROME, M.Metal, 110, "Cafe", 3)
	box(cafe, "EspressoDisplay", Vector3.new(1.8, 0.8, 0.12),
		Vector3.new(-174.0, MEZZ_TOP + 4.7, -172.85), C.NEON, M.Neon, 30, "Cafe", 4, NEON_OPTS)
	for i = 0, 5 do
		vcyl(cafe, string.format("CoffeeCup_%02d", i + 1), Vector3.new(0.9, 0.7, 0.7),
			Vector3.new(-164.0 + (i % 3) * 1.8, MEZZ_TOP + 3.35 + math.floor(i / 3) * 0.9, -174.0),
			C.WHITE, M.SmoothPlastic, 20, "Cafe", 4, SMALL_OPTS)
	end
	for i = 0, 2 do
		local sx = -176.0 + i * 7.0
		vcyl(cafe, string.format("CafeStool_%d_Post", i + 1), Vector3.new(2.4, 0.4, 0.4),
			Vector3.new(sx, MEZZ_TOP + 1.2, -170.0), C.CHROME, M.Metal, 60, "Cafe", 1)
		vcyl(cafe, string.format("CafeStool_%d_Seat", i + 1), Vector3.new(0.45, 2.2, 2.2),
			Vector3.new(sx, MEZZ_TOP + 2.6, -170.0), C.LEATHER, M.Leather or M.SmoothPlastic, 60, "Cafe", 2)
	end
	local cafeSign = box(cafe, "CafeSign", Vector3.new(13.0, 1.8, 0.25),
		Vector3.new(-169.0, MEZZ_TOP + 8.6, -175.7), C.CHARCOAL, M.Metal, 80, "Cafe", 3)
	gui(cafeSign, "CAFÉ  ·  LUXURY LOUNGE", 24, 40, Enum.NormalId.Back)
	for s, sx in ipairs({ -174.5, -163.5 }) do
		box(cafe, string.format("CafeSign_Post_%d", s), Vector3.new(0.32, 2.6, 0.32),
			Vector3.new(sx, MEZZ_TOP + 10.35, -175.7), C.STEEL_DK, M.Metal, 70, "Cafe", 3, SMALL_OPTS)
	end

	-- Kệ mô hình xe (2 kệ × 6 xe mini, mỗi xe 5 khối)
	local shelf = folder("22_ModelCarShelves", root)
	for s, sx in ipairs({ -250.0, -202.0 }) do
		local g = "ModelShelf" .. s
		for lvl = 0, 2 do
			box(shelf, string.format("%s_Board_%d", g, lvl + 1), Vector3.new(22.0, 0.35, 3.4),
				Vector3.new(sx, MEZZ_TOP + 2.0 + lvl * 3.2, -186.0), C.WHITE, M.Marble, 100, g, 1,
				{ reflectance = 0.25 })
		end
		for a = -1, 1, 2 do
			for b = -1, 1, 2 do
				box(shelf, string.format("%s_Upright_%d_%d", g, a, b), Vector3.new(0.35, 9.6, 0.35),
					Vector3.new(sx + a * 10.5, MEZZ_TOP + 4.8, -186.0 + b * 1.3),
					C.CHROME, M.Metal, 100, g, 1, SMALL_OPTS)
			end
		end
		for lvl = 0, 2 do
			for i = 0, 5 do
				local mx = sx - 9.0 + i * 3.6
				local my = MEZZ_TOP + 2.18 + lvl * 3.2
				local mz = -186.0
				local cols = { C.CAR_RED, C.CAR_YELLOW, C.CAR_BLUE, C.WHITE, C.CHARCOAL, C.GOLD }
				local col = cols[((i + lvl + s) % 6) + 1]
				box(shelf, string.format("%s_Car%d_%d_Body", g, lvl + 1, i + 1),
					Vector3.new(3.0, 0.7, 1.5), Vector3.new(mx, my + 0.35, mz), col, M.SmoothPlastic, 35, g, 2,
					{ reflectance = 0.25 })
				box(shelf, string.format("%s_Car%d_%d_Cabin", g, lvl + 1, i + 1),
					Vector3.new(1.5, 0.6, 1.3), Vector3.new(mx - 0.2, my + 0.95, mz), C.GLASS_DK, M.Glass, 30, g, 3, GLASS_OPTS)
				for w = -1, 1, 2 do
					box(shelf, string.format("%s_Car%d_%d_Wheel%d", g, lvl + 1, i + 1, w),
						Vector3.new(0.5, 0.5, 0.22), Vector3.new(mx + w * 0.9, my + 0.25, mz + 0.82),
						C.TIRE, M.SmoothPlastic, 20, g, 2, SMALL_OPTS)
					box(shelf, string.format("%s_Car%d_%d_Wheel%d_B", g, lvl + 1, i + 1, w),
						Vector3.new(0.5, 0.5, 0.22), Vector3.new(mx + w * 0.9, my + 0.25, mz - 0.82),
						C.TIRE, M.SmoothPlastic, 20, g, 2, SMALL_OPTS)
				end
			end
		end
	end

	-- 3.8 ─────────────────────── TẦNG 2 / SECOND FLOOR ─────────────────────
	local f2 = folder("23_SecondFloor", root)
	local F2_DECK = 0.60
	local f2Zones = {
		{ "West", BX0 + 1, -260.0, BZ0 + 1, BZ1 - 1 },
		{ "East", -192.0, BX1 - 1, BZ0 + 1, BZ1 - 1 },
		{ "North", -260.0, -192.0, -188.0, -172.0 },
		{ "South", -260.0, -192.0, -126.0, BZ1 - 1 },
	}
	for i, z in ipairs(f2Zones) do
		box(f2, "F2DeckBase_" .. z[1], Vector3.new(z[3] - z[2], F2_DECK - 0.08, z[5] - z[4]),
			Vector3.new((z[2] + z[3]) * 0.5, L2_TOP - 0.08 - (F2_DECK - 0.08) * 0.5, (z[4] + z[5]) * 0.5),
			C.CONCRETE2, M.Concrete, nil, nil, nil, { canCollide = true })
		tileField(f2, "F2Tile_" .. z[1], z[2], z[3], z[4], z[5],
			L2_TOP, 0.07, math.max(2, math.floor((z[3] - z[2]) / 8)),
			math.max(2, math.floor((z[5] - z[4]) / 8)),
			C.MARBLE, C.MARBLE2, 130, "F2Tile")
	end
	railing("F2RailWest", -260.0, -260.0, -172.0, -126.0, L2_TOP, 6)
	railing("F2RailEast", -192.0, -192.0, -172.0, -126.0, L2_TOP, 6)
	railing("F2RailNorth", -260.0, -192.0, -172.0, -172.0, L2_TOP, 9, true)
	railing("F2RailSouth", -260.0, -192.0, -126.0, -126.0, L2_TOP, 9, true)

	-- Phòng trưng bày tầng 2 + bảng thông tin + 2 xe mini lớn
	local f2deco = folder("24_F2Display", root)
	for i = 0, 3 do
		local bx = -294.0 + i * 9.0
		box(f2deco, string.format("F2Pedestal_%d", i + 1), Vector3.new(8.0, 1.6, 6.0),
			Vector3.new(bx, L2_TOP + 0.8, -148.0), C.WHITE, M.Marble, 150, "F2Display", 1)
		box(f2deco, string.format("F2MiniCar_%d_Body", i + 1), Vector3.new(5.6, 1.2, 2.8),
			Vector3.new(bx, L2_TOP + 2.3, -148.0), C.CAR_RED, M.SmoothPlastic, 50, "F2Display", 2,
			{ reflectance = 0.3 })
		box(f2deco, string.format("F2MiniCar_%d_Cabin", i + 1), Vector3.new(2.8, 1.0, 2.5),
			Vector3.new(bx - 0.4, L2_TOP + 3.3, -148.0), C.GLASS_DK, M.Glass, 40, "F2Display", 3, GLASS_OPTS)
		for w = -1, 1, 2 do
			box(f2deco, string.format("F2MiniCar_%d_Wheel%d", i + 1, w), Vector3.new(0.9, 0.9, 0.35),
				Vector3.new(bx + w * 1.8, L2_TOP + 2.05, -149.3), C.TIRE, M.SmoothPlastic, 30, "F2Display", 2, SMALL_OPTS)
		end
	end
	for i = 0, 2 do
		local board2 = box(f2deco, string.format("F2InfoBoard_%d", i + 1), Vector3.new(13.0, 4.2, 0.3),
			Vector3.new(-226.0 + (i - 1) * 18.0, L2_TOP + 5.6, -187.2),
			C.CHARCOAL, M.Metal, 90, "F2Display", 2)
		gui(board2, if i == 1 then "LUXURY AUTOS  ·  TẦNG 2" else "PREMIUM MOTORS  ·  SINCE 1972",
			20, 38, Enum.NormalId.Back)
		for s = 0, 1 do
			box(f2deco, string.format("F2InfoBoard_%d_Post_%d", i + 1, s + 1),
				Vector3.new(0.35, 3.5, 0.35),
				Vector3.new(-226.0 + (i - 1) * 18.0 + (s == 0 and -5.0 or 5.0), L2_TOP + 1.75, -187.2),
				C.CHROME, M.Metal, 80, "F2Display", 1, SMALL_OPTS)
		end
	end
	for i = 0, 5 do
		ball(f2deco, string.format("F2Planter_%d_Pot", i + 1), 2.4,
			Vector3.new(-252.0 + i * 10.4, L2_TOP + 1.2, -120.0), C.WHITE, 70, "F2Planter")
		ball(f2deco, string.format("F2Planter_%d_Leaf", i + 1), 3.4,
			Vector3.new(-252.0 + i * 10.4, L2_TOP + 3.4, -120.0), C.GREEN, 45, "F2Planter")
	end

	-- 3.9 ───────────────────────── MÁI / ROOF ───────────────────────────────
	local roof = folder("25_Roof", root)
	local ROOF_T = ROOF_TOP - ROOF_BOT
	local roofZones = {
		{ "West", BX0, -270.0, BZ0, BZ1 },
		{ "East", -182.0, BX1, BZ0, BZ1 },
		{ "North", -270.0, -182.0, BZ0, -176.0 },
		{ "South", -270.0, -182.0, -124.0, BZ1 },
	}
	for i, z in ipairs(roofZones) do
		box(roof, "RoofSlab_" .. z[1], Vector3.new(z[3] - z[2], ROOF_T - 0.08, z[5] - z[4]),
			Vector3.new((z[2] + z[3]) * 0.5, ROOF_TOP - 0.08 - (ROOF_T - 0.08) * 0.5, (z[4] + z[5]) * 0.5),
			C.CONCRETE2, M.Concrete, nil, nil, nil, { canCollide = true })
		tileField(roof, "RoofPanel_" .. z[1], z[2], z[3], z[4], z[5],
			ROOF_TOP, 0.06, math.max(2, math.floor((z[3] - z[2]) / 7)),
			math.max(2, math.floor((z[5] - z[4]) / 7)),
			C.CONCRETE, C.CONCRETE2, 120, "RoofPanel")
	end
	-- Giếng trời mái kính 8 × 4 ô
	local sky = folder("26_Skylight", root)
	local SKY_X0, SKY_X1, SKY_Z0, SKY_Z1 = -270.0, -182.0, -176.0, -124.0
	local skyCols, skyRows = 8, 4
	local sdx, sdz = (SKY_X1 - SKY_X0) / skyCols, (SKY_Z1 - SKY_Z0) / skyRows
	for i = 0, skyCols - 1 do
		for j = 0, skyRows - 1 do
			box(sky, string.format("SkylightGlass_%02d_%02d", i + 1, j + 1),
				Vector3.new(sdx - 0.22, 0.14, sdz - 0.22),
				Vector3.new(SKY_X0 + (i + 0.5) * sdx, ROOF_TOP - 0.38, SKY_Z0 + (j + 0.5) * sdz),
				C.GLASS, M.Glass, 40, "Skylight", 1, GLASS_OPTS)
		end
	end
	for i = 0, skyCols do
		box(sky, string.format("SkylightMullionX_%02d", i + 1), Vector3.new(0.30, 0.45, SKY_Z1 - SKY_Z0),
			Vector3.new(SKY_X0 + i * sdx, ROOF_TOP - 0.20, (SKY_Z0 + SKY_Z1) * 0.5),
			C.WHITE, M.Metal, 150, "Skylight", 2)
	end
	for j = 0, skyRows do
		box(sky, string.format("SkylightMullionZ_%02d", j + 1), Vector3.new(SKY_X1 - SKY_X0, 0.45, 0.30),
			Vector3.new((SKY_X0 + SKY_X1) * 0.5, ROOF_TOP - 0.20, SKY_Z0 + j * sdz),
			C.WHITE, M.Metal, 150, "Skylight", 2)
	end
	-- Lan can mái / diềm trang trí
	local parapet = folder("27_Parapet", root)
	box(parapet, "Parapet_South", Vector3.new(BX1 - BX0, PARAPET_TOP - ROOF_TOP, WT),
		Vector3.new((BX0 + BX1) * 0.5, (ROOF_TOP + PARAPET_TOP) * 0.5, BZ1),
		C.WHITE, M.Metal, 240, "Parapet", 1)
	box(parapet, "Parapet_North", Vector3.new(BX1 - BX0, PARAPET_TOP - ROOF_TOP, WT),
		Vector3.new((BX0 + BX1) * 0.5, (ROOF_TOP + PARAPET_TOP) * 0.5, BZ0),
		C.WHITE, M.Metal, 240, "Parapet", 1)
	box(parapet, "Parapet_West", Vector3.new(WT, PARAPET_TOP - ROOF_TOP, BZ1 - BZ0),
		Vector3.new(BX0, (ROOF_TOP + PARAPET_TOP) * 0.5, (BZ0 + BZ1) * 0.5),
		C.WHITE, M.Metal, 240, "Parapet", 1)
	box(parapet, "Parapet_East", Vector3.new(WT, PARAPET_TOP - ROOF_TOP, BZ1 - BZ0),
		Vector3.new(BX1, (ROOF_TOP + PARAPET_TOP) * 0.5, (BZ0 + BZ1) * 0.5),
		C.WHITE, M.Metal, 240, "Parapet", 1)
	for i = 0, 19 do
		local px = BX0 + (i + 0.5) * ((BX1 - BX0) / 20)
		box(parapet, string.format("ParapetCap_S_%02d", i + 1), Vector3.new(6.6, 0.35, 1.5),
			Vector3.new(px, PARAPET_TOP + 0.175, BZ1 + 0.05), C.CHROME, M.Metal, 80, "Parapet", 2)
	end
	for i = 0, 9 do
		local pz = BZ0 + (i + 0.5) * ((BZ1 - BZ0) / 10)
		box(parapet, string.format("ParapetCap_W_%02d", i + 1), Vector3.new(1.5, 0.35, 6.6),
			Vector3.new(BX0 - 0.05, PARAPET_TOP + 0.175, pz), C.CHROME, M.Metal, 80, "Parapet", 2)
		box(parapet, string.format("ParapetCap_E_%02d", i + 1), Vector3.new(1.5, 0.35, 6.6),
			Vector3.new(BX1 + 0.05, PARAPET_TOP + 0.175, pz), C.CHROME, M.Metal, 80, "Parapet", 2)
	end

	-- Cục nóng + quạt + cột ăng-ten trên mái
	local mech = folder("28_RoofMechanical", root)
	for i = 0, 2 do
		local mx = -260.0 + i * 34.0
		box(mech, string.format("HVAC_%d_Body", i + 1), Vector3.new(9.0, 3.2, 7.0),
			Vector3.new(mx, ROOF_TOP + 1.6, -168.0), C.STEEL, M.Metal, 160, "HVAC", 1)
		vcyl(mech, string.format("HVAC_%d_Fan", i + 1), Vector3.new(0.4, 4.6, 4.6),
			Vector3.new(mx, ROOF_TOP + 3.4, -168.0), C.CHARCOAL, M.Metal, 60, "HVAC", 2)
		for k = 0, 3 do
			rbox(mech, string.format("HVAC_%d_Blade%d", i + 1, k + 1), Vector3.new(3.8, 0.12, 0.9),
				cfAt(mx, ROOF_TOP + 3.66 + k * 0.05, -168.0, math.rad(k * 45)),
				C.STEEL_DK, M.Metal, 35, "HVAC", 3, SMALL_OPTS)
		end
	end
	for s, ax in ipairs({ -290.0, -162.0 }) do
		vcyl(mech, string.format("RoofAntenna_%d_Mast", s), Vector3.new(6.0, 0.45, 0.45),
			Vector3.new(ax, ROOF_TOP + 3.0, -182.0), C.CHROME, M.Metal, 120, "RoofAntenna", 1)
		box(mech, string.format("RoofAntenna_%d_Light", s), Vector3.new(1.0, 0.8, 1.0),
			Vector3.new(ax, ROOF_TOP + 6.4, -182.0), C.RED, M.Neon, 25, "RoofAntenna", 2, NEON_OPTS)
	end

	-- 3.10 ───────────── LƯỚI ĐÈN TRẦN + CHI TIẾT TƯỜNG ────────────────────
	local lights = folder("29_CeilingLights", root)
	for i = 0, 11 do
		local lx = BX0 + 8.0 + i * 12.0
		box(lights, string.format("CeilingNeonStrip_%02d", i + 1), Vector3.new(9.0, 0.18, 0.55),
			Vector3.new(lx, ROOF_BOT - 0.12, -150.0), C.NEON, M.Neon, 30, "CeilingNeon", 1, NEON_OPTS)
		box(lights, string.format("CeilingNeonStrip_%02d_Hanger", i + 1), Vector3.new(0.20, 0.75, 0.20),
			Vector3.new(lx, ROOF_BOT + 0.30, -150.0), C.STEEL_DK, M.Metal, 40, "CeilingNeon", 1, SMALL_OPTS)
	end
	for i = 0, 7 do
		local lz = BZ0 + 8.0 + i * 9.0
		box(lights, string.format("CeilingNeonCross_%02d", i + 1), Vector3.new(0.55, 0.18, 5.0),
			Vector3.new(-226.0, ROOF_BOT - 0.12, lz), C.NEON, M.Neon, 30, "CeilingNeon", 1, NEON_OPTS)
		box(lights, string.format("CeilingNeonCross_%02d_Hanger", i + 1), Vector3.new(0.20, 0.75, 0.20),
			Vector3.new(-226.0, ROOF_BOT + 0.30, lz), C.STEEL_DK, M.Metal, 40, "CeilingNeon", 1, SMALL_OPTS)
	end
	-- Tranh + bảng chỉ dẫn trên tường Bắc / Đông
	local deco = folder("30_WallDecor", root)
	for i = 0, 4 do
		local wx = -286.0 + i * 30.0
		box(deco, string.format("WallArt_%d_Frame", i + 1), Vector3.new(11.0, 6.0, 0.35),
			Vector3.new(wx, FLOOR_TOP + 20.0, BZ0 + 0.8), C.CHROME, M.Metal, 70, "WallArt", 1)
		box(deco, string.format("WallArt_%d_Canvas", i + 1), Vector3.new(10.0, 5.0, 0.12),
			Vector3.new(wx, FLOOR_TOP + 20.0, BZ0 + 1.05),
			if i % 2 == 0 then C.CAR_RED else C.CAR_BLUE, M.SmoothPlastic, 45, "WallArt", 2, SMALL_OPTS)
	end
	for i = 0, 3 do
		local wz = -178.0 + i * 16.0
		local wb = box(deco, string.format("ShowroomBanner_%d", i + 1), Vector3.new(0.30, 5.0, 9.0),
			Vector3.new(BX1 - 0.9, FLOOR_TOP + 20.0, wz), C.CHARCOAL, M.Metal, 70, "Banner", 1)
		gui(wb, if i % 2 == 0 then "LUXURY" else "AUTOS", 20, 44, Enum.NormalId.Right)
	end
	-- Quầy lễ tân sảnh
	local recept = folder("31_Reception", root)
	box(recept, "Reception_Body", Vector3.new(14.0, 3.0, 3.2),
		Vector3.new(-226.0, FLOOR_TOP + 1.5, -116.0), C.WHITE, M.Marble, 160, "Reception", 1,
		{ reflectance = 0.25 })
	box(recept, "Reception_Top", Vector3.new(15.0, 0.35, 3.8),
		Vector3.new(-226.0, FLOOR_TOP + 3.15, -116.0), C.CHARCOAL, M.Marble, 120, "Reception", 2)
	for i = 0, 2 do
		box(recept, string.format("Reception_Screen_%d", i + 1), Vector3.new(2.6, 1.6, 0.18),
			Vector3.new(-230.0 + i * 4.0, FLOOR_TOP + 4.2, -117.2), C.BLACK, M.Metal, 40, "Reception", 3)
	end
	local rsign = box(recept, "Reception_Sign", Vector3.new(17.0, 2.4, 0.3),
		Vector3.new(-226.0, FLOOR_TOP + 8.0, -117.4), C.CHARCOAL, M.Metal, 90, "Reception", 3)
	gui(rsign, "CHÀO MỪNG ĐẾN VỚI LUXURY AUTOS", 18, 40, Enum.NormalId.Back)
	for s, sx in ipairs({ -231.0, -221.0 }) do
		box(recept, string.format("Reception_SignPost_%d", s), Vector3.new(0.35, 3.8, 0.35),
			Vector3.new(sx, FLOOR_TOP + 4.9, -117.4), C.CHROME, M.Metal, 80, "Reception", 2, SMALL_OPTS)
	end

	-- 3.11 ─────────────── PASS HIỆU NĂNG (docs/PERFORMANCE.md) ──────────────
	local function perfPass(node: Instance)
		for _, o in ipairs(node:GetDescendants()) do
			if o:IsA("BasePart") then
				o.CanTouch = false
				o.EnableFluidForces = false
				o.CanQuery = true
				local md = math.max(o.Size.X, o.Size.Y, o.Size.Z)
				if md < 1.6 then
					o.CanCollide = false
				end
				if o.Transparency > 0 or o.Material == Enum.Material.Neon or o.Material == Enum.Material.Glass then
					o.CastShadow = false
				end
				if md < 2.6 and o.Transparency == 0 and o.Material ~= Enum.Material.Neon then
					o.CastShadow = false
				end
			end
		end
		for _, o in ipairs(node:GetDescendants()) do
			if o:IsA("SurfaceGui") then
				o.MaxDistance = 340
				if o.PixelsPerStud > 32 then
					o.PixelsPerStud = 32
				end
			elseif o:IsA("TextLabel") then
				o.TextScaled = false
			end
		end
	end
	perfPass(root)

	return root
end

return Module
