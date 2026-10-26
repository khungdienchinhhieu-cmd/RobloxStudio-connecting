--!strict
--[[
	WorldGrid.luau
	Bảng Tọa Độ Chuẩn Los Santos (Symmetric Master Grid — 0.000-stud gap)
	Mọi module ở các Giai đoạn 1 -> 7 đều đọc chung từ đây để ghép vừa khít 100%.
]]

export type RoadDef = {
	id: string,
	name: string,
	axis: "X" | "Z", -- "X": chạy Đông-Tây, "Z": chạy Bắc-Nam
	coord: number,
	width: number,
	min: number,
	max: number,
	lanes: number,
}

export type PlotDef = {
	id: string,
	district: string,
	subtitle: string,
	center: Vector3,
	size: Vector3,
	reservedForPhase: number,
}

local WorldGrid = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- TỈ LỆ 1:1 VỚI NGOÀI ĐỜI  (Sync v22)
-- ══════════════════════════════════════════════════════════════════════════════
-- Nhân vật Roblox cao ~5 stud ≈ 1,65 m  ->  1 stud ≈ 0,33 m  ->  1 m ≈ 3 stud.
-- Lấy chuẩn 1 m = 3,33 stud (1 stud = 0,30 m) cho dễ tính.
--
-- Kích thước NGOÀI ĐỜI quy đổi:
--   làn xe tiêu chuẩn   3,5 m -> 12 stud      (LANE_WIDTH)
--   vỉa hè              4,2 m -> 14 stud
--   đại lộ 4 làn       14 m   -> 48 stud
--   đại lộ 2 làn + đỗ   12 m  -> 40 stud
--   ô đất / dãy nhà    ~50 m  -> 170 stud
--   chiều cao tầng      3,3 m -> 11 stud
--
-- ⚠ Từ giờ MỌI công trình mới phải dùng WorldGrid.meters() để đổi mét -> stud.
WorldGrid.STUDS_PER_METER = 3.33
WorldGrid.LANE_WIDTH = 12 -- 3,6 m
WorldGrid.SIDEWALK_WIDTH = 14 -- 4,2 m (vỉa hè thật, trước chỉ 9 stud = 2,7 m)

function WorldGrid.meters(m: number): number
	return m * WorldGrid.STUDS_PER_METER
end

-- Bản đồ mở rộng (Sync v22): 1 120 -> 1 160 stud, đủ chỗ cho đường rộng 1:1
WorldGrid.MAP_HALF_SIZE = 580
WorldGrid.MAP_WIDTH = WorldGrid.MAP_HALF_SIZE * 2 -- 1 160 stud, dùng cho mọi dải nền/đồi/bờ biển
WorldGrid.ROAD_Y = 0.5
WorldGrid.ROAD_THICKNESS = 1.0
WorldGrid.SIDEWALK_HEIGHT = 0.65
-- (SIDEWALK_WIDTH nay khai báo phía trên, = 14 stud = 4,2 m)

-- 3 Đại lộ Đông - Tây (trải từ X = -340 đến X = +340)
WorldGrid.EW_ROADS = {
	-- width = 2 làn × 12 stud + 2 làn đỗ 8 stud = 40 stud (12 m) — chuẩn ngoài đời
	{ id = "Road_Vinewood", name = "Vinewood Blvd", axis = "X", coord = -224, width = 40, min = -580, max = 580, lanes = 2 },
	-- 4 làn × 12 stud + 2 làn dừng khẩn cấp = 48 stud (14,4 m) — chuẩn freeway
	{ id = "Road_Olympic",  name = "Olympic Fwy",   axis = "X", coord = -36,  width = 48, min = -580, max = 580, lanes = 4 },
	{ id = "Road_Vespucci", name = "Vespucci Blvd", axis = "X", coord = 148,  width = 40, min = -580, max = 580, lanes = 2 },
} :: { RoadDef }

-- 4 Đại lộ Bắc - Nam đối xứng gương qua X = 0 (trải từ Z = -240 đến Z = +164)
WorldGrid.NS_ROADS = {
	{ id = "Road_PacificCoast", name = "Pacific Coast Hwy", axis = "Z", coord = -556, width = 40, min = -244, max = 168, lanes = 2 },
	{ id = "Road_DelPerro",   name = "Del Perro Fwy",   axis = "Z", coord = -338, width = 40, min = -244, max = 168, lanes = 2 },
	{ id = "Road_SanAndreas", name = "San Andreas Ave", axis = "Z", coord = -110, width = 48, min = -244, max = 168, lanes = 4 },
	{ id = "Road_Alta",       name = "Alta St",         axis = "Z", coord = 110,  width = 48, min = -244, max = 168, lanes = 4 },
	{ id = "Road_Elgin",      name = "Elgin Ave",       axis = "Z", coord = 338,  width = 40, min = -244, max = 168, lanes = 2 },
	{ id = "Road_LaMesa",     name = "La Mesa Ave",     axis = "Z", coord = 556,  width = 40, min = -244, max = 168, lanes = 2 },
} :: { RoadDef }

-- 6 Ô Đất Đô Thị Đối Xứng Khít Tuyệt Đối (0.000-stud gap với toàn bộ mặt đường xung quanh)
WorldGrid.PLOTS = {
	-- Hàng Bắc (Z từ -204 đến -60 => centerZ = -132, sizeZ = 144)
	{
		id = "Plot_D1",
		district = "ROCKFORD HILLS",
		subtitle = "Khu Biệt Thự & Luxury Boutique (Giai đoạn 3)",
		center = Vector3.new(-226, 0, -132),
		size = Vector3.new(184, 1, 144),
		reservedForPhase = 3,
	},
	{
		id = "Plot_D2",
		district = "PILLBOX HILL",
		subtitle = "Tháp Tài Chính Maze Bank Downtown (Giai đoạn 3)",
		center = Vector3.new(0, 0, -132),
		size = Vector3.new(172, 1, 144),
		reservedForPhase = 3,
	},
	{
		id = "Plot_D3",
		district = "DOWNTOWN VINEWOOD",
		subtitle = "Đại Lộ Điện Ảnh & Studio (Giai đoạn 3)",
		center = Vector3.new(226, 0, -132),
		size = Vector3.new(184, 1, 144),
		reservedForPhase = 3,
	},

	-- Hàng Nam (Z từ -12 đến +128 => centerZ = +58, sizeZ = 140)
	{
		id = "Plot_C1",
		district = "DEL PERRO",
		subtitle = "Los Santos Customs & Cửa Hàng Ven Biển (Giai đoạn 3-4)",
		center = Vector3.new(-226, 0, 58),
		size = Vector3.new(184, 1, 140),
		reservedForPhase = 3,
	},
	{
		id = "Plot_C2",
		district = "LEGION SQUARE",
		subtitle = "Quảng Trường Trung Tâm & Điểm Xuất Phát (Giai đoạn 1)",
		center = Vector3.new(0, 0, 58),
		size = Vector3.new(172, 1, 140),
		reservedForPhase = 1,
	},
	{
		id = "Plot_C3",
		district = "MISSION ROW",
		subtitle = "Sở Cảnh Sát LSPD & Khu Thương Mại (Giai đoạn 3-5)",
		center = Vector3.new(226, 0, 58),
		size = Vector3.new(184, 1, 140),
		reservedForPhase = 3,
	},

	-- ▼ 4 Ô ĐẤT MỚI của bản đồ mở rộng (Sync v21) — nằm giữa đường Elgin/PacificCoast
	--   Rìa trong của chúng khít đúng mép vỉa hè cũ, rìa ngoài khít đúng mép đại lộ mới.
	{
		id = "Plot_E1",
		district = "PACIFIC BLUFFS",
		subtitle = "Biệt Thự Ven Vịnh & Bến Tàu (Giai đoạn 4)",
		center = Vector3.new(-447, 0, -132),
		size = Vector3.new(178, 1, 144),
		reservedForPhase = 4,
	},
	{
		id = "Plot_E2",
		district = "LA MESA",
		subtitle = "Khu Công Nghiệp & Garage Độ Xe (Giai đoạn 4)",
		center = Vector3.new(447, 0, -132),
		size = Vector3.new(178, 1, 144),
		reservedForPhase = 4,
	},
	{
		id = "Plot_E3",
		district = "LITTLE SEOUL",
		subtitle = "Phố Ẩm Thực & Chợ Đêm (Giai đoạn 4)",
		center = Vector3.new(-447, 0, 58),
		size = Vector3.new(178, 1, 140),
		reservedForPhase = 4,
	},
	{
		id = "Plot_E4",
		district = "RICHMAN GLEN",
		subtitle = "Khu Mua Sắm Cao Cấp (Giai đoạn 4)",
		center = Vector3.new(447, 0, 58),
		size = Vector3.new(178, 1, 140),
		reservedForPhase = 4,
	},
} :: { PlotDef }

-- ══════════════════════════════════════════════════════════════════════════════
-- BẢNG DI DỜI CÔNG TRÌNH (Sync v22)
-- ------------------------------------------------------------------------------
-- 3 công trình đã nghiệm thu (LS Customs · LSPD + Supermarket · Maze Bank) được dựng ở lưới đường CŨ (mỗi viên gạch đặt theo
-- toạ độ tuyệt đối trong file module 3 000–4 600 dòng). Khi lưới đường đổi kích
-- thước, ta KHÔNG sửa từng file — mà dựng xong rồi biến đổi cả model:
--     CFrame mới = (P - oldCenter) * k + newCenter      (co giãn theo X/Z, giữ nguyên Y)
-- `DistrictRegistry` tự áp dụng cho module nào có mặt trong bảng dưới đây.
WorldGrid.RELOCATION = {
	Plot_C1 = { oldCenter = Vector3.new(-218, 0, 57), oldSize = Vector3.new(180, 1, 150) },
	Plot_C3_West = { oldCenter = Vector3.new(174.5, 0, 57), oldSize = Vector3.new(75, 1, 150) },
	Plot_C3_East = { oldCenter = Vector3.new(260.5, 0, 57), oldSize = Vector3.new(77, 1, 150) },
	Plot_D2 = { oldCenter = Vector3.new(0, 0, -131), oldSize = Vector3.new(184, 1, 154) },
}

local function findPlot(id: string): PlotDef?
	for _, p in ipairs(WorldGrid.PLOTS) do
		if p.id == id then
			return p
		end
	end
	return nil
end

--- Vùng đích (tâm + kích thước) của một nửa ô Plot_C3.
local function halfPlotCenter(side: "WEST" | "EAST")
	local c3 = findPlot("Plot_C3")
	if not c3 then
		return nil
	end
	local sign = if side == "WEST" then -1 else 1
	local center = Vector3.new(c3.center.X + sign * c3.size.X * 0.25, 0, c3.center.Z)
	return center, Vector3.new(c3.size.X * 0.5, 1, c3.size.Z)
end

--- Trả về (oldCenter, newCenter, k) để DistrictRegistry biến đổi model, hoặc nil.
function WorldGrid.relocateTransform(plotId: string?)
	if not plotId then
		return nil
	end
	local rec = WorldGrid.RELOCATION[plotId]
	if not rec then
		return nil
	end

	local newCenter: Vector3
	local newSize: Vector3

	if plotId == "Plot_C3_West" then
		local c, sz = halfPlotCenter("WEST")
		if not c or not sz then
			return nil
		end
		newCenter, newSize = c, sz
	elseif plotId == "Plot_C3_East" then
		local c, sz = halfPlotCenter("EAST")
		if not c or not sz then
			return nil
		end
		newCenter, newSize = c, sz
	else
		local plot = findPlot(plotId)
		if not plot then
			return nil
		end
		newCenter = Vector3.new(plot.center.X, 0, plot.center.Z)
		newSize = plot.size
	end

	local kx = newSize.X / rec.oldSize.X
	local kz = newSize.Z / rec.oldSize.Z
	-- Không bao giờ phóng to quá 2 % (tránh tràn vỉa hè); luôn thu nhỏ được.
	local k = math.min(kx, kz, 1.02)

	return rec.oldCenter, newCenter, k
end

WorldGrid.ZONES = {
	VINEWOOD_Z_MAX = -244, -- mép ngoài đại lộ Vinewood
	BEACH_BOARDWALK_Z_MIN = 168, -- mép ngoài đại lộ Vespucci
	BEACH_SAND_Z_MIN = 190,
	OCEAN_WATER_Z_MIN = 254,
}

-- Điểm hồi sinh chính giữa Quảng Trường Trung Tâm Legion Square (nhìn thẳng về Downtown & Đồi Vinewood)
WorldGrid.SPAWN_POS = Vector3.new(0, 2.2, 92)

function WorldGrid.getLocationInfo(pos: Vector3): (string, string)
	local district = "LOS SANTOS"

	if pos.Z < WorldGrid.ZONES.VINEWOOD_Z_MAX then
		district = "VINEWOOD HILLS"
	elseif pos.Z >= WorldGrid.ZONES.OCEAN_WATER_Z_MIN then
		district = "PACIFIC OCEAN"
	elseif pos.Z >= WorldGrid.ZONES.BEACH_BOARDWALK_Z_MIN then
		district = "VESPUCCI BEACH"
	else
		for _, plot in ipairs(WorldGrid.PLOTS) do
			local hx = plot.size.X * 0.5 + 18
			local hz = plot.size.Z * 0.5 + 18
			if math.abs(pos.X - plot.center.X) <= hx and math.abs(pos.Z - plot.center.Z) <= hz then
				district = plot.district
				break
			end
		end
	end

	local bestStreet = "San Andreas State"
	local bestDist = math.huge
	local secondStreet: string? = nil

	for _, r in ipairs(WorldGrid.EW_ROADS) do
		if pos.X >= r.min - 24 and pos.X <= r.max + 24 then
			local d = math.abs(pos.Z - r.coord)
			if d < bestDist then
				if bestDist < 34 then
					secondStreet = bestStreet
				end
				bestDist = d
				bestStreet = r.name
			elseif d < 34 and r.name ~= bestStreet then
				secondStreet = r.name
			end
		end
	end

	for _, r in ipairs(WorldGrid.NS_ROADS) do
		if pos.Z >= r.min - 24 and pos.Z <= r.max + 24 then
			local d = math.abs(pos.X - r.coord)
			if d < bestDist then
				if bestDist < 34 then
					secondStreet = bestStreet
				end
				bestDist = d
				bestStreet = r.name
			elseif d < 34 and r.name ~= bestStreet then
				secondStreet = r.name
			end
		end
	end

	if secondStreet and bestDist < 30 then
		return district, string.format("%s & %s", bestStreet, secondStreet)
	end
	return district, bestStreet
end

return WorldGrid
