--!strict
--[[
	CityFoundation.luau (v2 — Ultra-Meticulous Destructible Modular Foundation)
	Đại tu toàn bộ NỀN THÀNH PHỐ Los Santos (GTA V):
	- Hạ tầng đường nhựa nhiều lớp (vệt bánh xe, rãnh thoát nước Gutter, song chắn rác kim loại,
	  đinh phản quang Botts' Dots, dốc người khuyết tật ADA vàng tại mọi góc ngã tư).
	- Đại lộ trung tâm Olympic Fwy có dải phân cách bê tông K-Rail (Jersey Barriers) ghép khối phá huỷ.
	- Bờ biển Vespucci có bờ kè đá ghép so le từng viên (Destructible), 3 cầu thang đá xuống cát,
	  đường ván gỗ Teak, 2 mỏm đá chắn sóng vươn ra biển và 3 tầng màu nước Thái Bình Dương.
	- Đồi Vinewood vát dốc đa diện tự nhiên bằng WedgePart + vách đá sa thạch + tường kè ghép khối.
	- Quảng trường bậc cấp Legion Square ghép đá thật + 5 ô móng công trình kỹ thuật có tường bao thấp ghép khối.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = script.Parent.Parent
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local PartBuilder = require(script.Parent:WaitForChild("PartBuilder"))

local CityFoundation = {}

local COLORS = {
	ASPHALT_BASE = Color3.fromRGB(34, 37, 43),
	ASPHALT_WEAR = Color3.fromRGB(44, 48, 55),
	INTERSECTION = Color3.fromRGB(31, 34, 40),
	GUTTER = Color3.fromRGB(134, 138, 146),
	DRAIN_GRATE = Color3.fromRGB(48, 52, 58),
	SIDEWALK = Color3.fromRGB(182, 185, 190),
	SIDEWALK_SEAM = Color3.fromRGB(148, 152, 160),
	ADA_TACTILE = Color3.fromRGB(232, 186, 38),
	RED_CURB = Color3.fromRGB(194, 44, 44),
	YELLOW_LINE = Color3.fromRGB(240, 190, 44),
	WHITE_LINE = Color3.fromRGB(238, 242, 247),
	LOT_SLAB = Color3.fromRGB(138, 144, 154),
	LOT_JOINT = Color3.fromRGB(106, 112, 122),
	LOT_WALL = Color3.fromRGB(164, 168, 174),
	PLAZA_GRASS = Color3.fromRGB(72, 132, 68),
	TRAVERTINE_A = Color3.fromRGB(212, 204, 190),
	TRAVERTINE_B = Color3.fromRGB(194, 185, 170),
	SANDSTONE_WALL = Color3.fromRGB(188, 174, 152),
	BASALT = Color3.fromRGB(54, 58, 66),
	POOL_WATER = Color3.fromRGB(38, 164, 196),
	SCULPTURE_RED = Color3.fromRGB(210, 44, 44),
	TEAK_WOOD = Color3.fromRGB(138, 96, 62),
	SEAWALL_STONE = Color3.fromRGB(186, 178, 164),
	JETTY_ROCK = Color3.fromRGB(96, 98, 104),
	DRY_SAND = Color3.fromRGB(228, 202, 150),
	MID_SAND = Color3.fromRGB(212, 184, 132),
	WET_SAND = Color3.fromRGB(174, 146, 104),
	SEA_FOAM = Color3.fromRGB(238, 248, 255),
	LAGOON_WATER = Color3.fromRGB(34, 152, 182),
	COAST_WATER = Color3.fromRGB(24, 114, 164),
	DEEP_OCEAN = Color3.fromRGB(16, 76, 130),
	HILL_FOOTHILL = Color3.fromRGB(94, 128, 66),
	HILL_CHAPARRAL = Color3.fromRGB(80, 112, 58),
	HILL_SUMMIT = Color3.fromRGB(68, 96, 50),
	CLIFF_ROCK = Color3.fromRGB(142, 130, 112),
	TRAIL_DIRT = Color3.fromRGB(168, 144, 110),
}

local function isInsideIntersection(x: number, z: number, axis: "X" | "Z", margin: number): boolean
	if axis == "X" then
		for _, ns in ipairs(WorldGrid.NS_ROADS) do
			if math.abs(x - ns.coord) <= (ns.width * 0.5 + margin) then
				return true
			end
		end
	else
		for _, ew in ipairs(WorldGrid.EW_ROADS) do
			if math.abs(z - ew.coord) <= (ew.width * 0.5 + margin) then
				return true
			end
		end
	end
	return false
end

local function configureGoldenHourLighting()
	Lighting.ClockTime = 16.8
	Lighting.Brightness = 2.65
	Lighting.Ambient = Color3.fromRGB(74, 80, 96)
	Lighting.OutdoorAmbient = Color3.fromRGB(130, 122, 112)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 214, 168)
	Lighting.EnvironmentDiffuseScale = 0.88
	Lighting.EnvironmentSpecularScale = 0.92

	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Density = 0.26
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(246, 206, 168)
	atmo.Decay = Color3.fromRGB(190, 140, 108)
	atmo.Glare = 0.22
	atmo.Haze = 1.1
	atmo.Parent = Lighting
end

-- ============================================================================
-- 1. HẠ TẦNG ĐẠI LỘ, RÃNH NƯỚC, CỐNG NGẦM & DẢI PHÂN CÁCH BÊ TÔNG PHÁ HUỶ
-- ============================================================================
local function buildRoadInfrastructure(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "01_RoadInfrastructure"
	folder.Parent = parent

	-- A. 3 Đại lộ Đông - Tây
	for _, r in ipairs(WorldGrid.EW_ROADS) do
		local len = r.max - r.min
		local cx = (r.min + r.max) * 0.5

		PartBuilder.part({
			name = r.id .. "_Roadbed",
			parent = folder,
			pos = Vector3.new(cx, 0, r.coord),
			size = Vector3.new(len, 1.0, r.width),
			color = COLORS.ASPHALT_BASE,
			material = Enum.Material.Asphalt,
		})

		-- Vệt mòn lốp xe thực tế trên từng làn + Rãnh bê tông thoát nước sát mép vỉa hè (Gutter)
		for _, side in ipairs({ -1, 1 }) do
			PartBuilder.part({
				name = "TireWearStrip",
				parent = folder,
				pos = Vector3.new(cx, 0.505, r.coord + side * (r.width * 0.23)),
				size = Vector3.new(len - 8, 0.02, 5.2),
				color = COLORS.ASPHALT_WEAR,
				material = Enum.Material.Asphalt,
				canCollide = false,
				castShadow = false,
			})
			PartBuilder.part({
				name = "ConcreteGutterEW",
				parent = folder,
				pos = Vector3.new(cx, 0.508, r.coord + side * (r.width * 0.5 - 0.7)),
				size = Vector3.new(len, 0.03, 1.4),
				color = COLORS.GUTTER,
				material = Enum.Material.Concrete,
				canCollide = false,
				castShadow = false,
			})
		end

		local cursor = r.min + 8
		while cursor <= r.max - 8 do
			if not isInsideIntersection(cursor, r.coord, "X", 7.5) then
				for _, offsetZ in ipairs({ -0.6, 0.6 }) do
					PartBuilder.part({
						name = "DoubleYellow",
						parent = folder,
						pos = Vector3.new(cursor, 0.52, r.coord + offsetZ),
						size = Vector3.new(11.8, 0.05, 0.36),
						color = COLORS.YELLOW_LINE,
						material = Enum.Material.SmoothPlastic,
						canCollide = false,
						castShadow = false,
					})
				end

				-- Đinh phản quang mặt đường California (Botts' Dots) cách đều 24 studs
				if math.floor((cursor - r.min) / 12) % 2 == 0 then
					PartBuilder.part({
						name = "BottsDot",
						parent = folder,
						pos = Vector3.new(cursor, 0.54, r.coord),
						size = Vector3.new(0.42, 0.08, 0.42),
						color = COLORS.YELLOW_LINE,
						material = Enum.Material.Neon,
						canCollide = false,
						castShadow = false,
					})
				end

				if r.lanes >= 4 and (math.floor((cursor - r.min) / 12) % 2 == 0) then
					local laneOff = r.width * 0.25
					for _, side in ipairs({ -1, 1 }) do
						PartBuilder.part({
							name = "LaneDash",
							parent = folder,
							pos = Vector3.new(cursor, 0.52, r.coord + side * laneOff),
							size = Vector3.new(7.5, 0.05, 0.35),
							color = COLORS.WHITE_LINE,
							material = Enum.Material.SmoothPlastic,
							canCollide = false,
							castShadow = false,
						})
					end
				end
			end
			cursor += 12
		end
	end

	-- Dải phân cách bê tông K-Rail (Jersey Barriers — Destructible = true!) dọc Đại lộ Olympic Fwy (Z = -36)
	local medianSpans = {
		{ name = "OlympicMedian_West", minX = -296, maxX = -138 },
		{ name = "OlympicMedian_Center", minX = -82, maxX = 82 },
		{ name = "OlympicMedian_East", minX = 138, maxX = 296 },
	}
	for _, sp in ipairs(medianSpans) do
		PartBuilder.jerseyBarrierRun({
			name = sp.name,
			parent = folder,
			axis = "X",
			fixedCoord = -36,
			minCoord = sp.minX,
			maxCoord = sp.maxX,
			baseY = 0.5,
			segmentLength = 14,
			fractureGroup = sp.name,
		})
	end

	-- B. 4 Đại lộ Bắc - Nam đối xứng
	for _, r in ipairs(WorldGrid.NS_ROADS) do
		local len = r.max - r.min
		local cz = (r.min + r.max) * 0.5

		PartBuilder.part({
			name = r.id .. "_Roadbed",
			parent = folder,
			pos = Vector3.new(r.coord, 0, cz),
			size = Vector3.new(r.width, 1.0, len),
			color = COLORS.ASPHALT_BASE,
			material = Enum.Material.Asphalt,
		})

		for _, side in ipairs({ -1, 1 }) do
			PartBuilder.part({
				name = "TireWearStripNS",
				parent = folder,
				pos = Vector3.new(r.coord + side * (r.width * 0.23), 0.505, cz),
				size = Vector3.new(5.2, 0.02, len - 8),
				color = COLORS.ASPHALT_WEAR,
				material = Enum.Material.Asphalt,
				canCollide = false,
				castShadow = false,
			})
			PartBuilder.part({
				name = "ConcreteGutterNS",
				parent = folder,
				pos = Vector3.new(r.coord + side * (r.width * 0.5 - 0.7), 0.508, cz),
				size = Vector3.new(1.4, 0.03, len),
				color = COLORS.GUTTER,
				material = Enum.Material.Concrete,
				canCollide = false,
				castShadow = false,
			})
		end

		local cursor = r.min + 8
		while cursor <= r.max - 8 do
			if not isInsideIntersection(r.coord, cursor, "Z", 7.5) then
				for _, offsetX in ipairs({ -0.6, 0.6 }) do
					PartBuilder.part({
						name = "DoubleYellow",
						parent = folder,
						pos = Vector3.new(r.coord + offsetX, 0.52, cursor),
						size = Vector3.new(0.36, 0.05, 11.8),
						color = COLORS.YELLOW_LINE,
						material = Enum.Material.SmoothPlastic,
						canCollide = false,
						castShadow = false,
					})
				end

				if math.floor((cursor - r.min) / 12) % 2 == 0 then
					PartBuilder.part({
						name = "BottsDotNS",
						parent = folder,
						pos = Vector3.new(r.coord, 0.54, cursor),
						size = Vector3.new(0.42, 0.08, 0.42),
						color = COLORS.YELLOW_LINE,
						material = Enum.Material.Neon,
						canCollide = false,
						castShadow = false,
					})
				end

				if r.lanes >= 4 and (math.floor((cursor - r.min) / 12) % 2 == 0) then
					local laneOff = r.width * 0.25
					for _, side in ipairs({ -1, 1 }) do
						PartBuilder.part({
							name = "LaneDash",
							parent = folder,
							pos = Vector3.new(r.coord + side * laneOff, 0.52, cursor),
							size = Vector3.new(0.35, 0.05, 7.5),
							color = COLORS.WHITE_LINE,
							material = Enum.Material.SmoothPlastic,
							canCollide = false,
							castShadow = false,
						})
					end
				end
			end
			cursor += 12
		end
	end

	-- C. 12 Ngã tư chuẩn kỹ thuật + Song chắn rác thoát nước mưa + Vạch đi bộ Zebra
	for _, ew in ipairs(WorldGrid.EW_ROADS) do
		for _, ns in ipairs(WorldGrid.NS_ROADS) do
			local ix, iz = ns.coord, ew.coord
			local hw, hd = ns.width * 0.5, ew.width * 0.5

			PartBuilder.part({
				name = string.format("Intersection_%s_%s", ew.id, ns.id),
				parent = folder,
				pos = Vector3.new(ix, 0.015, iz),
				size = Vector3.new(ns.width, 1.0, ew.width),
				color = COLORS.INTERSECTION,
				material = Enum.Material.Asphalt,
			})

			-- Nắp cống tròn/vuông trung tâm + 2 song chắn rác kim loại sát mép cống ngã tư
			PartBuilder.part({
				name = "ManholeCover",
				parent = folder,
				pos = Vector3.new(ix + 2.2, 0.525, iz - 2.2),
				size = Vector3.new(2.8, 0.05, 2.8),
				color = COLORS.DRAIN_GRATE,
				material = Enum.Material.DiamondPlate,
				canCollide = false,
				castShadow = false,
			})
			for _, sxSign in ipairs({ -1, 1 }) do
				PartBuilder.part({
					name = "StormDrainGrate",
					parent = folder,
					pos = Vector3.new(ix + sxSign * (hw - 0.8), 0.52, iz + sxSign * (hd + 8.5)),
					size = Vector3.new(1.3, 0.04, 3.4),
					color = COLORS.DRAIN_GRATE,
					material = Enum.Material.DiamondPlate,
					canCollide = false,
					castShadow = false,
				})
			end

			for _, dirZ in ipairs({ -1, 1 }) do
				local cz = iz + dirZ * (hd + 3.2)
				local stripeX = ix - hw + 3.0
				while stripeX <= ix + hw - 3.0 do
					PartBuilder.part({
						name = "CrosswalkNS",
						parent = folder,
						pos = Vector3.new(stripeX, 0.525, cz),
						size = Vector3.new(1.7, 0.05, 5.2),
						color = COLORS.WHITE_LINE,
						material = Enum.Material.SmoothPlastic,
						canCollide = false,
						castShadow = false,
					})
					stripeX += 3.8
				end
				PartBuilder.part({
					name = "StopLineNS",
					parent = folder,
					pos = Vector3.new(ix, 0.525, iz + dirZ * (hd + 6.6)),
					size = Vector3.new(ns.width - 3.2, 0.05, 0.72),
					color = COLORS.WHITE_LINE,
					material = Enum.Material.SmoothPlastic,
					canCollide = false,
					castShadow = false,
				})
			end

			for _, dirX in ipairs({ -1, 1 }) do
				local cx = ix + dirX * (hw + 3.2)
				local stripeZ = iz - hd + 3.0
				while stripeZ <= iz + hd - 3.0 do
					PartBuilder.part({
						name = "CrosswalkEW",
						parent = folder,
						pos = Vector3.new(cx, 0.525, stripeZ),
						size = Vector3.new(5.2, 0.05, 1.7),
						color = COLORS.WHITE_LINE,
						material = Enum.Material.SmoothPlastic,
						canCollide = false,
						castShadow = false,
					})
					stripeZ += 3.8
				end
				PartBuilder.part({
					name = "StopLineEW",
					parent = folder,
					pos = Vector3.new(ix + dirX * (hw + 6.6), 0.525, iz),
					size = Vector3.new(0.72, 0.05, ew.width - 3.2),
					color = COLORS.WHITE_LINE,
					material = Enum.Material.SmoothPlastic,
					canCollide = false,
					castShadow = false,
				})
			end
		end
	end
end

-- ============================================================================
-- 2. VỈA HÈ CHIA Ô, DỐC KHUYẾT TẬT ADA, QUẢNG TRƯỜNG LEGION SQUARE & 5 Ô MÓNG
-- ============================================================================
local function buildLegionSquareTerracedPlaza(blockFolder: Instance, cx: number, cz: number, innerX: number, innerZ: number, subtitle: string)
	-- Thảm cỏ xanh ngọc làm nền công viên (đỉnh ở Y = 1.19)
	PartBuilder.part({
		name = "LegionGrassBase",
		parent = blockFolder,
		pos = Vector3.new(cx, 1.10, cz),
		size = Vector3.new(innerX, 0.18, innerZ),
		color = COLORS.PLAZA_GRASS,
		material = Enum.Material.Grass,
	})

	-- 4 Đại lộ đi bộ lát đá Travertine dẫn từ 4 phía vào thềm bậc cấp trung tâm
	PartBuilder.part({
		name = "PromenadeNS",
		parent = blockFolder,
		pos = Vector3.new(cx, 1.19, cz),
		size = Vector3.new(30, 0.08, innerZ),
		color = COLORS.TRAVERTINE_A,
		material = Enum.Material.Sandstone,
	})
	PartBuilder.part({
		name = "PromenadeEW",
		parent = blockFolder,
		pos = Vector3.new(cx, 1.195, cz),
		size = Vector3.new(innerX, 0.08, 26),
		color = COLORS.TRAVERTINE_A,
		material = Enum.Material.Sandstone,
	})

	-- 4 Bồn cỏ góc công viên xây kè đá sa thạch hình chữ L ghép từng viên (Destructible = true!), tách hẳn khỏi thềm trung tâm
	for _, sxSign in ipairs({ -1, 1 }) do
		for _, szSign in ipairs({ -1, 1 }) do
			local cornerGroup = string.format("LegionPlanter_%d_%d", sxSign, szSign)
			local minX = if sxSign < 0 then (cx - innerX * 0.5 + 6) else (cx + 50)
			local maxX = if sxSign < 0 then (cx - 50) else (cx + innerX * 0.5 - 6)
			local wallZ = cz + szSign * 18

			PartBuilder.masonryWall({
				name = cornerGroup .. "_WallX",
				parent = blockFolder,
				axis = "X",
				fixedCoord = wallZ,
				minCoord = minX,
				maxCoord = maxX,
				baseY = 1.18,
				thickness = 1.5,
				courses = 2,
				courseHeight = 0.52,
				blockLength = 6.0,
				baseColor = COLORS.SANDSTONE_WALL,
				material = Enum.Material.Sandstone,
				integrity = 120,
				fractureGroup = cornerGroup,
				addCoping = true,
			})

			local minZ = if szSign < 0 then (cz - innerZ * 0.5 + 6) else (wallZ + 1.2)
			local maxZ = if szSign < 0 then (wallZ - 1.2) else (cz + innerZ * 0.5 - 6)
			PartBuilder.masonryWall({
				name = cornerGroup .. "_WallZ",
				parent = blockFolder,
				axis = "Z",
				fixedCoord = cx + sxSign * 50,
				minCoord = minZ,
				maxCoord = maxZ,
				baseY = 1.18,
				thickness = 1.5,
				courses = 2,
				courseHeight = 0.52,
				blockLength = 6.0,
				baseColor = COLORS.SANDSTONE_WALL,
				material = Enum.Material.Sandstone,
				integrity = 120,
				fractureGroup = cornerGroup,
				addCoping = true,
			})
		end
	end

	-- Thềm quảng trường trung tâm nâng cao (Raised Civic Terrace — đỉnh ở Y = 2.35)
	PartBuilder.part({
		name = "RaisedCivicTerrace",
		parent = blockFolder,
		pos = Vector3.new(cx, 1.75, cz - 4),
		size = Vector3.new(88, 1.2, 74),
		color = COLORS.TRAVERTINE_B,
		material = Enum.Material.Sandstone,
	})
	-- Họa tiết gạch đá chạy viền hai bên ngoài hồ nước (không chạy xuyên dưới đáy hồ!)
	for _, i in ipairs({ -3, -2, 2, 3 }) do
		PartBuilder.part({
			name = "TerraceInlayBand_" .. tostring(i),
			parent = blockFolder,
			pos = Vector3.new(cx + i * 11.5, 2.365, cz - 4),
			size = Vector3.new(4.8, 0.03, 68),
			color = COLORS.TRAVERTINE_A,
			material = Enum.Material.Sandstone,
			canCollide = false,
			castShadow = false,
		})
	end

	-- 4 Cụm bậc tam cấp đá (Walkable Staircases) bước lên thềm trung tâm từ Bắc, Nam, Đông, Tây
	PartBuilder.staircase({
		name = "LegionStairs_South",
		parent = blockFolder,
		origin = Vector3.new(cx, 1.18, cz + 38),
		dir = Vector3.new(0, 0, -1),
		width = 24,
		steps = 4,
		totalRise = 1.18,
		totalRun = 5.2,
		color = COLORS.TRAVERTINE_A,
		fractureGroup = "LegionStairsS",
	})
	PartBuilder.staircase({
		name = "LegionStairs_North",
		parent = blockFolder,
		origin = Vector3.new(cx, 1.18, cz - 46),
		dir = Vector3.new(0, 0, 1),
		width = 24,
		steps = 4,
		totalRise = 1.18,
		totalRun = 5.2,
		color = COLORS.TRAVERTINE_A,
		fractureGroup = "LegionStairsN",
	})
	PartBuilder.staircase({
		name = "LegionStairs_West",
		parent = blockFolder,
		origin = Vector3.new(cx - 49, 1.18, cz - 4),
		dir = Vector3.new(1, 0, 0),
		width = 20,
		steps = 4,
		totalRise = 1.18,
		totalRun = 5.2,
		color = COLORS.TRAVERTINE_A,
		fractureGroup = "LegionStairsW",
	})
	PartBuilder.staircase({
		name = "LegionStairs_East",
		parent = blockFolder,
		origin = Vector3.new(cx + 49, 1.18, cz - 4),
		dir = Vector3.new(-1, 0, 0),
		width = 20,
		steps = 4,
		totalRise = 1.18,
		totalRun = 5.2,
		color = COLORS.TRAVERTINE_A,
		fractureGroup = "LegionStairsE",
	})

	-- Hồ nước phản chiếu xây bằng đá Basalt ghép khối có thể phá huỷ (Destructible Pool Rim!)
	local poolZ = cz - 6
	PartBuilder.masonryWall({
		name = "PoolRim_North",
		parent = blockFolder,
		axis = "X",
		fixedCoord = poolZ - 15,
		minCoord = cx - 22,
		maxCoord = cx + 22,
		baseY = 2.35,
		thickness = 1.8,
		courses = 2,
		courseHeight = 0.55,
		blockLength = 5.5,
		baseColor = COLORS.BASALT,
		material = Enum.Material.Basalt,
		integrity = 160,
		fractureGroup = "LegionPoolN",
	})
	PartBuilder.masonryWall({
		name = "PoolRim_South",
		parent = blockFolder,
		axis = "X",
		fixedCoord = poolZ + 15,
		minCoord = cx - 22,
		maxCoord = cx + 22,
		baseY = 2.35,
		thickness = 1.8,
		courses = 2,
		courseHeight = 0.55,
		blockLength = 5.5,
		baseColor = COLORS.BASALT,
		material = Enum.Material.Basalt,
		integrity = 160,
		fractureGroup = "LegionPoolS",
	})
	PartBuilder.masonryWall({
		name = "PoolRim_West",
		parent = blockFolder,
		axis = "Z",
		fixedCoord = cx - 21.1,
		minCoord = poolZ - 14.1,
		maxCoord = poolZ + 14.1,
		baseY = 2.35,
		thickness = 1.8,
		courses = 2,
		courseHeight = 0.55,
		blockLength = 5.5,
		baseColor = COLORS.BASALT,
		material = Enum.Material.Basalt,
		integrity = 160,
		fractureGroup = "LegionPoolW",
	})
	PartBuilder.masonryWall({
		name = "PoolRim_East",
		parent = blockFolder,
		axis = "Z",
		fixedCoord = cx + 21.1,
		minCoord = poolZ - 14.1,
		maxCoord = poolZ + 14.1,
		baseY = 2.35,
		thickness = 1.8,
		courses = 2,
		courseHeight = 0.55,
		blockLength = 5.5,
		baseColor = COLORS.BASALT,
		material = Enum.Material.Basalt,
		integrity = 160,
		fractureGroup = "LegionPoolE",
	})

	-- Lòng đáy hồ lát đá Basalt đen tuyền giúp mặt nước xanh ngọc sâu thẳm, không lộ nền dưới
	PartBuilder.part({
		name = "ReflectingPoolBasinFloor",
		parent = blockFolder,
		pos = Vector3.new(cx, 2.42, poolZ),
		size = Vector3.new(41.0, 0.14, 28.8),
		color = COLORS.BASALT,
		material = Enum.Material.Slate,
	})
	PartBuilder.part({
		name = "ReflectingPoolWater",
		parent = blockFolder,
		pos = Vector3.new(cx, 3.02, poolZ),
		size = Vector3.new(40.4, 0.35, 28.2),
		color = COLORS.POOL_WATER,
		material = Enum.Material.Glass,
		transparency = 0.16,
	})

	-- Tượng đài nghệ thuật Đỏ-Vàng giữa hồ ghép từ 7 tầng khối rời (Destructible = true theo StructuralRow 1->7!)
	PartBuilder.part({
		name = "SculpturePedestal",
		parent = blockFolder,
		pos = Vector3.new(cx, 3.2, poolZ),
		size = Vector3.new(8.5, 1.4, 8.5),
		color = COLORS.BASALT,
		material = Enum.Material.Marble,
		destructible = true,
		integrity = 260,
		fractureGroup = "LegionMonument",
		structuralRow = 1,
	})
	for tier = 1, 5 do
		local ty = 3.9 + (tier - 0.5) * 2.1
		local shiftX = math.sin(tier * 0.65) * 1.1
		PartBuilder.part({
			name = "SculptureSpineBlock_" .. tostring(tier),
			parent = blockFolder,
			pos = Vector3.new(cx + shiftX, ty, poolZ),
			size = Vector3.new(3.4 - tier * 0.2, 2.02, 3.0),
			color = COLORS.SCULPTURE_RED,
			material = Enum.Material.SmoothPlastic,
			destructible = true,
			integrity = 150,
			fractureGroup = "LegionMonument",
			structuralRow = tier + 1,
		})
	end
	PartBuilder.part({
		name = "SculptureGoldBeacon",
		parent = blockFolder,
		pos = Vector3.new(cx, 15.2, poolZ),
		size = Vector3.new(2.8, 2.8, 2.8),
		color = COLORS.YELLOW_LINE,
		material = Enum.Material.Neon,
		destructible = true,
		integrity = 100,
		fractureGroup = "LegionMonument",
		structuralRow = 7,
	})

	-- Hàng cọc thép chống xe lao vào khu đi bộ (Destructible Bollards!) ở lối vào Nam & Bắc
	PartBuilder.bollardLine({
		name = "SouthPlazaBollards",
		parent = blockFolder,
		startPos = Vector3.new(cx - 12, 1.18, cz + innerZ * 0.5 - 2.5),
		endPos = Vector3.new(cx + 12, 1.18, cz + innerZ * 0.5 - 2.5),
		count = 5,
		fractureGroup = "LegionBollardsS",
	})
	PartBuilder.bollardLine({
		name = "NorthPlazaBollards",
		parent = blockFolder,
		startPos = Vector3.new(cx - 12, 1.18, cz - innerZ * 0.5 + 2.5),
		endPos = Vector3.new(cx + 12, 1.18, cz - innerZ * 0.5 + 2.5),
		count = 5,
		fractureGroup = "LegionBollardsN",
	})

	-- Điểm xuất phát người chơi (SpawnLocation) lát đá cẩm thạch âm phẳng phiu trước bậc tam cấp Nam
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "LegionSquareSpawn"
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.Size = Vector3.new(12, 0.14, 12)
	spawnLoc.CFrame = CFrame.new(WorldGrid.SPAWN_POS.X, 1.26, WorldGrid.SPAWN_POS.Z)
	spawnLoc.Color = COLORS.TRAVERTINE_B
	spawnLoc.Material = Enum.Material.Marble
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.BottomSurface = Enum.SurfaceType.Smooth
	spawnLoc.Parent = blockFolder

	PartBuilder.surveyMonument(
		blockFolder,
		Vector3.new(cx + 22, 1.15, cz + innerZ * 0.5 - 3),
		"LEGION SQUARE [C2]",
		subtitle,
		Color3.fromRGB(114, 204, 114)
	)
end

local function buildSidewalksAndLots(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "02_SidewalksAndLots"
	folder.Parent = parent

	local swW = WorldGrid.SIDEWALK_WIDTH

	for _, plot in ipairs(WorldGrid.PLOTS) do
		local blockFolder = Instance.new("Folder")
		blockFolder.Name = plot.id .. "_" .. string.gsub(plot.district, " ", "")
		blockFolder.Parent = folder

		local cx, cz = plot.center.X, plot.center.Z
		local sx, sz = plot.size.X, plot.size.Z

		-- Nền vỉa hè bê tông cao 0.65 stud trên mặt đường (đỉnh ở Y = 1.15)
		PartBuilder.part({
			name = "SidewalkSlab",
			parent = blockFolder,
			pos = Vector3.new(cx, 0.575, cz),
			size = Vector3.new(sx, 1.15, sz),
			color = COLORS.SIDEWALK,
			material = Enum.Material.Concrete,
		})

		-- Khe co giãn chia ô gạch vỉa hè dọc 4 cạnh cho cảm giác bê tông thật
		local seamX = cx - sx * 0.5 + 18
		while seamX <= cx + sx * 0.5 - 18 do
			for _, dz in ipairs({ -1, 1 }) do
				PartBuilder.part({
					name = "SidewalkJointX",
					parent = blockFolder,
					pos = Vector3.new(seamX, 1.155, cz + dz * (sz * 0.5 - swW * 0.5)),
					size = Vector3.new(0.22, 0.02, swW - 0.6),
					color = COLORS.SIDEWALK_SEAM,
					material = Enum.Material.Concrete,
					canCollide = false,
					castShadow = false,
				})
			end
			seamX += 18
		end

		-- 4 Góc ngã tư: Bó vỉa sơn đỏ cấm đỗ + Tấm lát nổi màu vàng cho người đi bộ (ADA Tactile Ramp)
		for _, dx in ipairs({ -1, 1 }) do
			for _, dz in ipairs({ -1, 1 }) do
				PartBuilder.part({
					name = "RedFireLaneCurbX",
					parent = blockFolder,
					pos = Vector3.new(cx + dx * (sx * 0.5 - 6.0), 1.17, cz + dz * (sz * 0.5 - 0.35)),
					size = Vector3.new(12, 0.06, 0.7),
					color = COLORS.RED_CURB,
					material = Enum.Material.SmoothPlastic,
				})
				PartBuilder.part({
					name = "RedFireLaneCurbZ",
					parent = blockFolder,
					pos = Vector3.new(cx + dx * (sx * 0.5 - 0.35), 1.17, cz + dz * (sz * 0.5 - 6.0)),
					size = Vector3.new(0.7, 0.06, 12),
					color = COLORS.RED_CURB,
					material = Enum.Material.SmoothPlastic,
				})
				PartBuilder.part({
					name = "AdaTactilePad",
					parent = blockFolder,
					pos = Vector3.new(cx + dx * (sx * 0.5 - 2.4), 1.16, cz + dz * (sz * 0.5 - 2.4)),
					size = Vector3.new(3.6, 0.03, 3.6),
					color = COLORS.ADA_TACTILE,
					material = Enum.Material.DiamondPlate,
					canCollide = false,
					castShadow = false,
				})
			end
		end

		local innerX = sx - swW * 2
		local innerZ = sz - swW * 2

		if plot.id == "Plot_C2" then
			buildLegionSquareTerracedPlaza(blockFolder, cx, cz, innerX, innerZ, plot.subtitle)
		else
			-- Ô MÓNG CÔNG TRÌNH KỸ THUẬT (Engineered Structural Pad — sẵn sàng xây từng tòa nhà 1-by-1!)
			PartBuilder.part({
				name = "EngineeredFoundationPad",
				parent = blockFolder,
				pos = Vector3.new(cx, 1.12, cz),
				size = Vector3.new(innerX, 0.16, innerZ),
				color = COLORS.LOT_SLAB,
				material = Enum.Material.Concrete,
			})

			-- Đường chia lưới khe lún kỹ thuật trên mặt móng bê tông
			for _, frac in ipairs({ -0.25, 0, 0.25 }) do
				PartBuilder.part({
					name = "SlabExpansionSeamX",
					parent = blockFolder,
					pos = Vector3.new(cx + innerX * frac, 1.205, cz),
					size = Vector3.new(0.3, 0.02, innerZ - 4),
					color = COLORS.LOT_JOINT,
					material = Enum.Material.Concrete,
					canCollide = false,
					castShadow = false,
				})
				PartBuilder.part({
					name = "SlabExpansionSeamZ",
					parent = blockFolder,
					pos = Vector3.new(cx, 1.205, cz + innerZ * frac),
					size = Vector3.new(innerX - 4, 0.02, 0.3),
					color = COLORS.LOT_JOINT,
					material = Enum.Material.Concrete,
					canCollide = false,
					castShadow = false,
				})
			end

			-- Lối xe ra vào ô đất (Asphalt Driveway Apron) quay mặt về Đại lộ trung tâm Olympic Fwy
			local frontSignZ = if cz < 0 then 1 else -1
			local frontEdgeZ = cz + frontSignZ * (sz * 0.5)
			PartBuilder.part({
				name = "ServiceDrivewayApron",
				parent = blockFolder,
				pos = Vector3.new(cx, 1.16, frontEdgeZ - frontSignZ * (swW * 0.5)),
				size = Vector3.new(26, 0.05, swW + 0.4),
				color = COLORS.ASPHALT_WEAR,
				material = Enum.Material.Asphalt,
			})

			-- Tường bao thấp quanh ranh giới ô đất ghép từ từng viên bê tông đúc sẵn (Destructible = true!)
			local lotGroup = "LotWall_" .. plot.id
			local backZ = cz - frontSignZ * (innerZ * 0.5 - 0.8)
			local frontWallZ = cz + frontSignZ * (innerZ * 0.5 - 0.8)

			PartBuilder.masonryWall({
				name = "PerimeterWall_Back",
				parent = blockFolder,
				axis = "X",
				fixedCoord = backZ,
				minCoord = cx - innerX * 0.5,
				maxCoord = cx + innerX * 0.5,
				baseY = 1.20,
				thickness = 1.4,
				courses = 2,
				courseHeight = 0.55,
				blockLength = 12,
				baseColor = COLORS.LOT_WALL,
				material = Enum.Material.Concrete,
				integrity = 115,
				fractureGroup = lotGroup .. "_Back",
			})
			-- Cạnh trước chừa cổng rộng 28 studs ngay lối xe chạy vào!
			PartBuilder.masonryWall({
				name = "PerimeterWall_FrontLeft",
				parent = blockFolder,
				axis = "X",
				fixedCoord = frontWallZ,
				minCoord = cx - innerX * 0.5,
				maxCoord = cx - 14,
				baseY = 1.20,
				thickness = 1.4,
				courses = 2,
				courseHeight = 0.55,
				blockLength = 11,
				baseColor = COLORS.LOT_WALL,
				material = Enum.Material.Concrete,
				integrity = 115,
				fractureGroup = lotGroup .. "_FL",
			})
			PartBuilder.masonryWall({
				name = "PerimeterWall_FrontRight",
				parent = blockFolder,
				axis = "X",
				fixedCoord = frontWallZ,
				minCoord = cx + 14,
				maxCoord = cx + innerX * 0.5,
				baseY = 1.20,
				thickness = 1.4,
				courses = 2,
				courseHeight = 0.55,
				blockLength = 11,
				baseColor = COLORS.LOT_WALL,
				material = Enum.Material.Concrete,
				integrity = 115,
				fractureGroup = lotGroup .. "_FR",
			})
			for _, sideX in ipairs({ -1, 1 }) do
				PartBuilder.masonryWall({
					name = "PerimeterWall_Side_" .. tostring(sideX),
					parent = blockFolder,
					axis = "Z",
					fixedCoord = cx + sideX * (innerX * 0.5 - 0.8),
					minCoord = cz - innerZ * 0.5 + 1.6,
					maxCoord = cz + innerZ * 0.5 - 1.6,
					baseY = 1.20,
					thickness = 1.4,
					courses = 2,
					courseHeight = 0.55,
					blockLength = 12,
					baseColor = COLORS.LOT_WALL,
					material = Enum.Material.Concrete,
					integrity = 115,
					fractureGroup = lotGroup .. "_Side" .. tostring(sideX),
				})
			end

			-- Bia mốc tên khu vực gọn đẹp ngay cạnh cổng vào ô đất
			PartBuilder.surveyMonument(
				blockFolder,
				Vector3.new(cx + 22, 1.20, frontWallZ - frontSignZ * 2.5),
				string.format("%s [%s]", plot.district, string.sub(plot.id, -2)),
				plot.subtitle,
				COLORS.YELLOW_LINE
			)
		end
	end

	-- Vỉa hè vành đai ngoài (Tây, Đông, Bắc)
	PartBuilder.part({
		name = "WestPerimeterSidewalk",
		parent = folder,
		pos = Vector3.new(-350, 0.575, -38),
		size = Vector3.new(20, 1.15, 404),
		color = COLORS.SIDEWALK,
		material = Enum.Material.Concrete,
	})
	PartBuilder.part({
		name = "EastPerimeterSidewalk",
		parent = folder,
		pos = Vector3.new(350, 0.575, -38),
		size = Vector3.new(20, 1.15, 404),
		color = COLORS.SIDEWALK,
		material = Enum.Material.Concrete,
	})
	PartBuilder.part({
		name = "NorthVinewoodWalkway",
		parent = folder,
		pos = Vector3.new(0, 0.575, -245),
		size = Vector3.new(720, 1.15, 10),
		color = COLORS.SIDEWALK,
		material = Enum.Material.Concrete,
	})
end

-- ============================================================================
-- 3. BỜ BIỂN VESPUCCI BEACH: KÈ ĐÁ GHÉP KHỐI, CẦU THANG, VÁN GỖ & MỎM ĐÁ SÓNG
-- ============================================================================
local function buildVespucciCoastline(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "03_VespucciCoastline"
	folder.Parent = parent

	-- Cốt địa chất sâu chống thủng đáy toàn bản đồ (Destructible = false)
	PartBuilder.part({
		name = "BedrockApron",
		parent = folder,
		pos = Vector3.new(0, -2.0, -50),
		size = Vector3.new(720, 3.0, 620),
		color = COLORS.HILL_FOOTHILL,
		material = Enum.Material.Grass,
	})

	-- Phố đi bộ ven biển Vespucci Promenade + Đường ván gỗ Teak chạy dọc bờ kè (Z = 164 -> 186)
	PartBuilder.part({
		name = "VespucciStonePromenade",
		parent = folder,
		pos = Vector3.new(0, 0.575, 175),
		size = Vector3.new(720, 1.15, 22),
		color = COLORS.TRAVERTINE_A,
		material = Enum.Material.Sandstone,
	})
	PartBuilder.part({
		name = "VespucciTeakBoardwalk",
		parent = folder,
		pos = Vector3.new(0, 1.16, 180.5),
		size = Vector3.new(700, 0.06, 7.5),
		color = COLORS.TEAK_WOOD,
		material = Enum.Material.WoodPlanks,
	})

	-- Tường kè đá chắn biển Vespucci ghép từ từng viên đá vôi có thể phá huỷ (chừa 3 cổng cầu thang tại -218, 0, +218)
	local seawallSpans = {
		{ name = "Seawall_FarWest", minX = -358, maxX = -231 },
		{ name = "Seawall_MidWest", minX = -205, maxX = -13 },
		{ name = "Seawall_MidEast", minX = 13, maxX = 205 },
		{ name = "Seawall_FarEast", minX = 231, maxX = 358 },
	}
	for _, sw in ipairs(seawallSpans) do
		PartBuilder.masonryWall({
			name = sw.name,
			parent = folder,
			axis = "X",
			fixedCoord = 185.6,
			minCoord = sw.minX,
			maxCoord = sw.maxX,
			baseY = 0.2,
			thickness = 1.8,
			courses = 3,
			courseHeight = 0.62,
			blockLength = 11.0,
			baseColor = COLORS.SEAWALL_STONE,
			material = Enum.Material.Sandstone,
			integrity = 175,
			fractureGroup = sw.name,
			addCoping = true,
			copingColor = COLORS.TRAVERTINE_A,
		})
	end

	-- 3 Cụm Cầu thang đá lớn từ Phố đi bộ bước thẳng xuống bãi cát vàng Vespucci (lộ rõ toàn bộ 5 bậc đá!)
	for _, stairX in ipairs({ -218, 0, 218 }) do
		PartBuilder.staircase({
			name = "BeachAccessStairs_" .. tostring(stairX),
			parent = folder,
			origin = Vector3.new(stairX, -0.05, 195.0),
			dir = Vector3.new(0, 0, -1),
			width = 22,
			steps = 5,
			totalRise = 1.22,
			totalRun = 9.0,
			color = COLORS.TRAVERTINE_A,
			cheekColor = COLORS.SEAWALL_STONE,
			fractureGroup = "BeachStairs_" .. tostring(stairX),
		})
	end

	-- Bãi cát thoải dần 3 tầng (tách sườn cát theo đúng 4 nhịp bờ kè để không lấp bậc cầu thang xuống biển!)
	PartBuilder.part({
		name = "UpperBeachSandBase",
		parent = folder,
		pos = Vector3.new(0, -0.60, 206),
		size = Vector3.new(720, 1.1, 40),
		color = COLORS.DRY_SAND,
		material = Enum.Material.Sand,
	})
	for _, sw in ipairs(seawallSpans) do
		local spanW = sw.maxX - sw.minX
		local spanMidX = (sw.minX + sw.maxX) * 0.5
		PartBuilder.wedge({
			name = "UpperBeachSandSlope_" .. sw.name,
			parent = folder,
			cframe = CFrame.new(spanMidX, 0.48, 204) * CFrame.Angles(0, math.rad(180), 0),
			size = Vector3.new(spanW, 1.06, 36),
			color = COLORS.DRY_SAND,
			material = Enum.Material.Sand,
		})
	end
	PartBuilder.part({
		name = "MidBeachSunSand",
		parent = folder,
		pos = Vector3.new(0, -0.65, 232),
		size = Vector3.new(720, 1.1, 20),
		color = COLORS.MID_SAND,
		material = Enum.Material.Sand,
	})
	PartBuilder.part({
		name = "WetTidalShoreSand",
		parent = folder,
		pos = Vector3.new(0, -0.88, 249),
		size = Vector3.new(720, 0.95, 18),
		color = COLORS.WET_SAND,
		material = Enum.Material.Sand,
	})

	-- 2 Mỏm kè đá chắn sóng (Rock Breakwater Jetties) vươn ra biển tại X = -150 và X = +150 (ghép khối đá rời!)
	for _, jx in ipairs({ -150, 150 }) do
		local jFolder = Instance.new("Folder")
		jFolder.Name = "RockJetty_" .. tostring(jx)
		jFolder.Parent = folder
		for seg = 1, 9 do
			local jz = 232 + seg * 7.2
			local w = 9.5 - seg * 0.45
			PartBuilder.part({
				name = "JettyBoulder_" .. tostring(seg),
				parent = jFolder,
				pos = Vector3.new(jx + ((seg % 2 == 0) and 0.6 or -0.6), -0.15, jz),
				size = Vector3.new(w, 1.9, 6.8),
				color = COLORS.JETTY_ROCK,
				material = Enum.Material.Slate,
				destructible = true,
				integrity = 300,
				fractureGroup = "Jetty_" .. tostring(jx),
				structuralRow = 1,
			})
		end
	end

	-- 2 Lớp bọt sóng trắng vỗ bờ + 3 Tầng độ sâu nước biển Thái Bình Dương
	PartBuilder.part({
		name = "InnerSurfFoam",
		parent = folder,
		pos = Vector3.new(0, -0.46, 256),
		size = Vector3.new(720, 0.16, 4.2),
		color = COLORS.SEA_FOAM,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.22,
		canCollide = false,
	})
	PartBuilder.part({
		name = "OuterWaveCrest",
		parent = folder,
		pos = Vector3.new(0, -0.48, 270),
		size = Vector3.new(720, 0.12, 2.6),
		color = COLORS.SEA_FOAM,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.42,
		canCollide = false,
	})
	PartBuilder.part({
		name = "ShallowTurquoiseLagoon",
		parent = folder,
		pos = Vector3.new(0, -0.95, 272),
		size = Vector3.new(720, 0.9, 34),
		color = COLORS.LAGOON_WATER,
		material = Enum.Material.Glass,
		transparency = 0.16,
	})
	PartBuilder.part({
		name = "MidCoastalAzureWater",
		parent = folder,
		pos = Vector3.new(0, -1.02, 306),
		size = Vector3.new(720, 0.95, 36),
		color = COLORS.COAST_WATER,
		material = Enum.Material.Glass,
		transparency = 0.14,
	})
	PartBuilder.part({
		name = "DeepPacificSapphire",
		parent = folder,
		pos = Vector3.new(0, -1.1, 344),
		size = Vector3.new(720, 1.0, 42),
		color = COLORS.DEEP_OCEAN,
		material = Enum.Material.Glass,
		transparency = 0.12,
	})
end

-- ============================================================================
-- 4. ĐỒI VINEWOOD HILLS ĐIÊU KHẮC VÁT NGHIÊNG TỰ NHIÊN + TƯỜNG KÈ GHÉP KHỐI
-- ============================================================================
local function buildSculptedVinewoodHills(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "04_VinewoodHills"
	folder.Parent = parent

	-- Tường kè đá chống sạt lở chân đồi dọc suốt Vinewood Blvd (ghép khối đá rời Destructible = true!)
	PartBuilder.masonryWall({
		name = "VinewoodFoothillRetainingWall",
		parent = folder,
		axis = "X",
		fixedCoord = -250.8,
		minCoord = -356,
		maxCoord = 356,
		baseY = 0.6,
		thickness = 2.2,
		courses = 4,
		courseHeight = 0.85,
		blockLength = 13.5,
		baseColor = COLORS.SANDSTONE_WALL,
		material = Enum.Material.Sandstone,
		integrity = 200,
		fractureGroup = "VinewoodRetainingWall",
		addCoping = true,
	})

	-- Dải sườn đồi thấp vát nghiêng mượt từ đỉnh tường kè (Z=-252, Y=4) lên đường mòn ngắm cảnh (Z=-292, Y=15)
	PartBuilder.wedge({
		name = "FoothillFrontSlope",
		parent = folder,
		cframe = CFrame.new(0, 9.5, -272) * CFrame.Angles(0, math.rad(180), 0),
		size = Vector3.new(720, 11.0, 40),
		color = COLORS.HILL_FOOTHILL,
		material = Enum.Material.Grass,
	})
	PartBuilder.part({
		name = "FoothillUnderBase",
		parent = folder,
		pos = Vector3.new(0, 2.0, -272),
		size = Vector3.new(720, 4.0, 40),
		color = COLORS.HILL_FOOTHILL,
		material = Enum.Material.Grass,
	})
	PartBuilder.part({
		name = "ScenicTrailBench",
		parent = folder,
		pos = Vector3.new(0, 7.5, -299),
		size = Vector3.new(720, 15.0, 14),
		color = COLORS.HILL_FOOTHILL,
		material = Enum.Material.Grass,
	})
	-- Đường mòn đất cát đỏ Hollywood / Vinewood chạy ngang lưng chừng đồi + bệ ngắm toàn cảnh thành phố
	PartBuilder.part({
		name = "VinewoodHikingTrail",
		parent = folder,
		pos = Vector3.new(0, 15.08, -298),
		size = Vector3.new(560, 0.16, 8.0),
		color = COLORS.TRAIL_DIRT,
		material = Enum.Material.Sandstone,
	})

	-- 5 Mỏm đá vách núi sa thạch tự nhiên trồi ra khỏi sườn cỏ
	for _, rx in ipairs({ -245, -115, 18, 135, 255 }) do
		PartBuilder.part({
			name = "CliffOutcrop_" .. tostring(rx),
			parent = folder,
			pos = Vector3.new(rx, 11.2, -284),
			size = Vector3.new(34, 6.5, 11),
			color = COLORS.CLIFF_ROCK,
			material = Enum.Material.Slate,
		})
	end

	-- Tầng núi trung tâm và 3 đỉnh núi vát chéo đa diện bằng WedgePart (West Peak, Central Vinewood Crest, East Peak)
	local peaks = {
		{ name = "WestPeak", cx = -232, coreW = 140, flankW = 55, baseH = 15, peakH = 34, col = COLORS.HILL_CHAPARRAL },
		{ name = "CentralVinewoodSummit", cx = 0, coreW = 168, flankW = 64, baseH = 15, peakH = 46, col = COLORS.HILL_SUMMIT },
		{ name = "EastPeak", cx = 232, coreW = 140, flankW = 55, baseH = 15, peakH = 36, col = COLORS.HILL_CHAPARRAL },
	}
	for _, pk in ipairs(peaks) do
		-- Bệ chân đỉnh núi (từ Y = 0 đến baseH = 15 để không hở gầm sườn dốc)
		PartBuilder.part({
			name = pk.name .. "_Pedestal",
			parent = folder,
			pos = Vector3.new(pk.cx, pk.baseH * 0.5, -333),
			size = Vector3.new(pk.coreW + pk.flankW * 2, pk.baseH, 54),
			color = COLORS.HILL_FOOTHILL,
			material = Enum.Material.Grass,
		})
		-- Lõi đỉnh núi cao (nơi đặt chữ VINEWOOD ở bước tiếp theo!)
		PartBuilder.part({
			name = pk.name .. "_Core",
			parent = folder,
			pos = Vector3.new(pk.cx, pk.baseH + (pk.peakH - pk.baseH) * 0.5, -346),
			size = Vector3.new(pk.coreW, pk.peakH - pk.baseH, 28),
			color = pk.col,
			material = Enum.Material.Grass,
		})
		-- Sườn dốc phía Nam vát mượt từ đường mòn (Z=-306, Y=15) lên đỉnh núi (Z=-332, Y=peakH)!
		PartBuilder.wedge({
			name = pk.name .. "_SouthSlope",
			parent = folder,
			cframe = CFrame.new(pk.cx, pk.baseH + (pk.peakH - pk.baseH) * 0.5, -319) * CFrame.Angles(0, math.rad(180), 0),
			size = Vector3.new(pk.coreW, pk.peakH - pk.baseH, 26),
			color = pk.col,
			material = Enum.Material.Grass,
		})
		-- Sườn dốc vát sang cánh Tây
		PartBuilder.wedge({
			name = pk.name .. "_WestFlank",
			parent = folder,
			cframe = CFrame.new(pk.cx - (pk.coreW * 0.5 + pk.flankW * 0.5), pk.baseH + (pk.peakH - pk.baseH) * 0.5, -333)
				* CFrame.Angles(0, math.rad(90), 0),
			size = Vector3.new(54, pk.peakH - pk.baseH, pk.flankW),
			color = COLORS.HILL_CHAPARRAL,
			material = Enum.Material.Grass,
		})
		-- Sườn dốc vát sang cánh Đông
		PartBuilder.wedge({
			name = pk.name .. "_EastFlank",
			parent = folder,
			cframe = CFrame.new(pk.cx + (pk.coreW * 0.5 + pk.flankW * 0.5), pk.baseH + (pk.peakH - pk.baseH) * 0.5, -333)
				* CFrame.Angles(0, math.rad(-90), 0),
			size = Vector3.new(54, pk.peakH - pk.baseH, pk.flankW),
			color = COLORS.HILL_CHAPARRAL,
			material = Enum.Material.Grass,
		})
	end
end

function CityFoundation.build(forceRebuild: boolean?): Model
	local legacy = Workspace:FindFirstChild("InteractiveCity")
	if legacy then
		legacy:Destroy()
	end
	local defaultBaseplate = Workspace:FindFirstChild("Baseplate")
	if defaultBaseplate and defaultBaseplate:IsA("BasePart") then
		defaultBaseplate:Destroy()
	end

	local root = Workspace:FindFirstChild("LosSantos") :: Model?
	if root and not forceRebuild then
		if root:FindFirstChild("Phase1_CityFoundation") then
			return root
		end
	end

	if not root then
		local newRoot = Instance.new("Model")
		newRoot.Name = "LosSantos"
		newRoot.Parent = Workspace
		root = newRoot
	end

	local existingPhase1 = (root :: Model):FindFirstChild("Phase1_CityFoundation")
	if existingPhase1 then
		existingPhase1:Destroy()
	end

	local phase1 = Instance.new("Folder")
	phase1.Name = "Phase1_CityFoundation"
	phase1.Parent = root

	configureGoldenHourLighting()
	buildVespucciCoastline(phase1)
	buildSculptedVinewoodHills(phase1)
	buildRoadInfrastructure(phase1)
	buildSidewalksAndLots(phase1)

	return root :: Model
end

return CityFoundation
