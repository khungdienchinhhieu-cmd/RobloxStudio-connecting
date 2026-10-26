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

-- Bản đồ mở rộng (Sync v21): 720 -> 1 120 stud chiều ngang (+65 %)
WorldGrid.MAP_HALF_SIZE = 560
WorldGrid.MAP_WIDTH = WorldGrid.MAP_HALF_SIZE * 2 -- 1 120 stud, dùng cho mọi dải nền/đồi/bờ biển
WorldGrid.ROAD_Y = 0.5
WorldGrid.ROAD_THICKNESS = 1.0
WorldGrid.SIDEWALK_HEIGHT = 0.65
WorldGrid.SIDEWALK_WIDTH = 9.0

-- 3 Đại lộ Đông - Tây (trải từ X = -340 đến X = +340)
WorldGrid.EW_ROADS = {
	{ id = "Road_Vinewood", name = "Vinewood Blvd", axis = "X", coord = -224, width = 32, min = -560, max = 560, lanes = 2 },
	{ id = "Road_Olympic",  name = "Olympic Fwy",   axis = "X", coord = -36,  width = 36, min = -560, max = 560, lanes = 4 },
	{ id = "Road_Vespucci", name = "Vespucci Blvd", axis = "X", coord = 148,  width = 32, min = -560, max = 560, lanes = 2 },
} :: { RoadDef }

-- 4 Đại lộ Bắc - Nam đối xứng gương qua X = 0 (trải từ Z = -240 đến Z = +164)
WorldGrid.NS_ROADS = {
	{ id = "Road_DelPerro",   name = "Del Perro Fwy",   axis = "Z", coord = -324, width = 32, min = -240, max = 164, lanes = 2 },
	{ id = "Road_SanAndreas", name = "San Andreas Ave", axis = "Z", coord = -110, width = 36, min = -240, max = 164, lanes = 4 },
	{ id = "Road_Alta",       name = "Alta St",         axis = "Z", coord = 110,  width = 36, min = -240, max = 164, lanes = 4 },
	{ id = "Road_Elgin",      name = "Elgin Ave",       axis = "Z", coord = 324,  width = 32, min = -240, max = 164, lanes = 2 },
	-- ▼ 2 đại lộ mới mở rộng thành phố về 2 phía (Sync v21)
	{ id = "Road_PacificCoast", name = "Pacific Coast Hwy", axis = "Z", coord = -540, width = 32, min = -240, max = 164, lanes = 2 },
	{ id = "Road_LaMesa",       name = "La Mesa Ave",       axis = "Z", coord = 540,  width = 32, min = -240, max = 164, lanes = 2 },
} :: { RoadDef }

-- 6 Ô Đất Đô Thị Đối Xứng Khít Tuyệt Đối (0.000-stud gap với toàn bộ mặt đường xung quanh)
WorldGrid.PLOTS = {
	-- Hàng Bắc (Z từ -208 đến -54 => centerZ = -131, sizeZ = 154)
	{
		id = "Plot_D1",
		district = "ROCKFORD HILLS",
		subtitle = "Khu Biệt Thự & Luxury Boutique (Giai đoạn 3)",
		center = Vector3.new(-218, 0, -131),
		size = Vector3.new(180, 1, 154),
		reservedForPhase = 3,
	},
	{
		id = "Plot_D2",
		district = "PILLBOX HILL",
		subtitle = "Tháp Tài Chính Maze Bank Downtown (Giai đoạn 3)",
		center = Vector3.new(0, 0, -131),
		size = Vector3.new(184, 1, 154),
		reservedForPhase = 3,
	},
	{
		id = "Plot_D3",
		district = "DOWNTOWN VINEWOOD",
		subtitle = "Đại Lộ Điện Ảnh & Studio (Giai đoạn 3)",
		center = Vector3.new(218, 0, -131),
		size = Vector3.new(180, 1, 154),
		reservedForPhase = 3,
	},

	-- Hàng Nam (Z từ -18 đến +132 => centerZ = +57, sizeZ = 150)
	{
		id = "Plot_C1",
		district = "DEL PERRO",
		subtitle = "Los Santos Customs & Cửa Hàng Ven Biển (Giai đoạn 3-4)",
		center = Vector3.new(-218, 0, 57),
		size = Vector3.new(180, 1, 150),
		reservedForPhase = 3,
	},
	{
		id = "Plot_C2",
		district = "LEGION SQUARE",
		subtitle = "Quảng Trường Trung Tâm & Điểm Xuất Phát (Giai đoạn 1)",
		center = Vector3.new(0, 0, 57),
		size = Vector3.new(184, 1, 150),
		reservedForPhase = 1,
	},
	{
		id = "Plot_C3",
		district = "MISSION ROW",
		subtitle = "Sở Cảnh Sát LSPD & Khu Thương Mại (Giai đoạn 3-5)",
		center = Vector3.new(218, 0, 57),
		size = Vector3.new(180, 1, 150),
		reservedForPhase = 3,
	},

	-- ▼ 4 Ô ĐẤT MỚI của bản đồ mở rộng (Sync v21) — nằm giữa đường Elgin/PacificCoast
	--   Rìa trong của chúng khít đúng mép vỉa hè cũ, rìa ngoài khít đúng mép đại lộ mới.
	{
		id = "Plot_E1",
		district = "PACIFIC BLUFFS",
		subtitle = "Biệt Thự Ven Vịnh & Bến Tàu (Giai đoạn 4)",
		center = Vector3.new(-432, 0, -131),
		size = Vector3.new(180, 1, 154),
		reservedForPhase = 4,
	},
	{
		id = "Plot_E2",
		district = "LA MESA",
		subtitle = "Khu Công Nghiệp & Garage Độ Xe (Giai đoạn 4)",
		center = Vector3.new(432, 0, -131),
		size = Vector3.new(180, 1, 154),
		reservedForPhase = 4,
	},
	{
		id = "Plot_E3",
		district = "LITTLE SEOUL",
		subtitle = "Phố Ẩm Thực & Chợ Đêm (Giai đoạn 4)",
		center = Vector3.new(-432, 0, 57),
		size = Vector3.new(180, 1, 150),
		reservedForPhase = 4,
	},
	{
		id = "Plot_E4",
		district = "RICHMAN GLEN",
		subtitle = "Khu Mua Sắm Cao Cấp (Giai đoạn 4)",
		center = Vector3.new(432, 0, 57),
		size = Vector3.new(180, 1, 150),
		reservedForPhase = 4,
	},
} :: { PlotDef }

WorldGrid.ZONES = {
	VINEWOOD_Z_MAX = -240,
	BEACH_BOARDWALK_Z_MIN = 164,
	BEACH_SAND_Z_MIN = 186,
	OCEAN_WATER_Z_MIN = 250,
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
				if bestDist < 28 then
					secondStreet = bestStreet
				end
				bestDist = d
				bestStreet = r.name
			elseif d < 28 and r.name ~= bestStreet then
				secondStreet = r.name
			end
		end
	end

	for _, r in ipairs(WorldGrid.NS_ROADS) do
		if pos.Z >= r.min - 24 and pos.Z <= r.max + 24 then
			local d = math.abs(pos.X - r.coord)
			if d < bestDist then
				if bestDist < 28 then
					secondStreet = bestStreet
				end
				bestDist = d
				bestStreet = r.name
			elseif d < 28 and r.name ~= bestStreet then
				secondStreet = r.name
			end
		end
	end

	if secondStreet and bestDist < 24 then
		return district, string.format("%s & %s", bestStreet, secondStreet)
	end
	return district, bestStreet
end

return WorldGrid
