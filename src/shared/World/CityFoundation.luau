--!strict
--[[
	CityFoundation.luau
	Giai đoạn 1: Dựng NỀN THÀNH PHỐ (City Foundation) chuẩn Los Santos (GTA V) — Đối xứng 100%.
	CHỈ dựng địa hình nền, mặt đường nhựa, vạch kẻ California, vỉa hè, Quảng Trường Trung Tâm Legion Square,
	ô đất sạch chờ Giai đoạn 3, Bãi biển Vespucci & Đồi Vinewood.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = script.Parent.Parent
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local PartBuilder = require(script.Parent:WaitForChild("PartBuilder"))

local CityFoundation = {}

local COLORS = {
	ASPHALT = Color3.fromRGB(38, 41, 47),
	INTERSECTION = Color3.fromRGB(34, 37, 43),
	SIDEWALK = Color3.fromRGB(178, 182, 188),
	CURB = Color3.fromRGB(150, 154, 162),
	RED_CURB = Color3.fromRGB(192, 46, 46),
	YELLOW_LINE = Color3.fromRGB(238, 188, 46),
	WHITE_LINE = Color3.fromRGB(236, 240, 245),
	PLOT_PAD = Color3.fromRGB(142, 148, 158),
	PLAZA_TURF = Color3.fromRGB(78, 134, 72),
	PLAZA_STONE = Color3.fromRGB(206, 200, 188),
	PLAZA_DARK_STONE = Color3.fromRGB(64, 68, 76),
	POOL_WATER = Color3.fromRGB(42, 158, 188),
	SCULPTURE_RED = Color3.fromRGB(206, 48, 48),
	BOARDWALK = Color3.fromRGB(198, 188, 170),
	DRY_SAND = Color3.fromRGB(224, 198, 146),
	WET_SAND = Color3.fromRGB(186, 158, 112),
	SHALLOW_OCEAN = Color3.fromRGB(36, 138, 176),
	DEEP_OCEAN = Color3.fromRGB(20, 88, 142),
	SEA_FOAM = Color3.fromRGB(232, 246, 252),
	HILLS_LOW = Color3.fromRGB(92, 128, 68),
	HILLS_MID = Color3.fromRGB(80, 114, 60),
	HILLS_HIGH = Color3.fromRGB(68, 98, 52),
	MANHOLE = Color3.fromRGB(58, 62, 68),
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
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(76, 82, 98)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 122, 114)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 214, 168)
	Lighting.EnvironmentDiffuseScale = 0.85
	Lighting.EnvironmentSpecularScale = 0.9

	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Density = 0.27
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(246, 206, 168)
	atmo.Decay = Color3.fromRGB(192, 142, 110)
	atmo.Glare = 0.2
	atmo.Haze = 1.15
	atmo.Parent = Lighting
end

local function buildRoadNetwork(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "01_RoadNetwork"
	folder.Parent = parent

	-- 1. Đại lộ Đông-Tây
	for _, r in ipairs(WorldGrid.EW_ROADS) do
		local len = r.max - r.min
		local cx = (r.min + r.max) * 0.5

		PartBuilder.part({
			name = r.id,
			parent = folder,
			pos = Vector3.new(cx, 0, r.coord),
			size = Vector3.new(len, 1.0, r.width),
			color = COLORS.ASPHALT,
			material = Enum.Material.Asphalt,
		})

		local cursor = r.min + 8
		while cursor <= r.max - 8 do
			if not isInsideIntersection(cursor, r.coord, "X", 7) then
				for _, offsetZ in ipairs({ -0.55, 0.55 }) do
					PartBuilder.part({
						name = "DoubleYellow",
						parent = folder,
						pos = Vector3.new(cursor, 0.52, r.coord + offsetZ),
						size = Vector3.new(12, 0.05, 0.38),
						color = COLORS.YELLOW_LINE,
						material = Enum.Material.SmoothPlastic,
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

	-- 2. Đại lộ Bắc-Nam
	for _, r in ipairs(WorldGrid.NS_ROADS) do
		local len = r.max - r.min
		local cz = (r.min + r.max) * 0.5

		PartBuilder.part({
			name = r.id,
			parent = folder,
			pos = Vector3.new(r.coord, 0, cz),
			size = Vector3.new(r.width, 1.0, len),
			color = COLORS.ASPHALT,
			material = Enum.Material.Asphalt,
		})

		local cursor = r.min + 8
		while cursor <= r.max - 8 do
			if not isInsideIntersection(r.coord, cursor, "Z", 7) then
				for _, offsetX in ipairs({ -0.55, 0.55 }) do
					PartBuilder.part({
						name = "DoubleYellow",
						parent = folder,
						pos = Vector3.new(r.coord + offsetX, 0.52, cursor),
						size = Vector3.new(0.38, 0.05, 12),
						color = COLORS.YELLOW_LINE,
						material = Enum.Material.SmoothPlastic,
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

	-- 3. 12 Ngã tư chuẩn xác + Vạch dừng + Vạch đi bộ Zebra + Nắp cống kim loại
	for _, ew in ipairs(WorldGrid.EW_ROADS) do
		for _, ns in ipairs(WorldGrid.NS_ROADS) do
			local ix, iz = ns.coord, ew.coord
			local hw, hd = ns.width * 0.5, ew.width * 0.5

			PartBuilder.part({
				name = string.format("Intersection_%s_%s", ew.id, ns.id),
				parent = folder,
				pos = Vector3.new(ix, 0.01, iz),
				size = Vector3.new(ns.width, 1.0, ew.width),
				color = COLORS.INTERSECTION,
				material = Enum.Material.Asphalt,
			})

			PartBuilder.part({
				name = "ManholeCover",
				parent = folder,
				pos = Vector3.new(ix + 2, 0.52, iz - 2),
				size = Vector3.new(2.8, 0.06, 2.8),
				color = COLORS.MANHOLE,
				material = Enum.Material.DiamondPlate,
				canCollide = false,
				castShadow = false,
			})

			-- Crosswalk Bắc & Nam
			for _, dirZ in ipairs({ -1, 1 }) do
				local cz = iz + dirZ * (hd + 3.2)
				local stripeX = ix - hw + 3.0
				while stripeX <= ix + hw - 3.0 do
					PartBuilder.part({
						name = "CrosswalkNS",
						parent = folder,
						pos = Vector3.new(stripeX, 0.52, cz),
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
					pos = Vector3.new(ix, 0.52, iz + dirZ * (hd + 6.6)),
					size = Vector3.new(ns.width - 3, 0.05, 0.7),
					color = COLORS.WHITE_LINE,
					material = Enum.Material.SmoothPlastic,
					canCollide = false,
					castShadow = false,
				})
			end

			-- Crosswalk Đông & Tây
			for _, dirX in ipairs({ -1, 1 }) do
				local cx = ix + dirX * (hw + 3.2)
				local stripeZ = iz - hd + 3.0
				while stripeZ <= iz + hd - 3.0 do
					PartBuilder.part({
						name = "CrosswalkEW",
						parent = folder,
						pos = Vector3.new(cx, 0.52, stripeZ),
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
					pos = Vector3.new(ix + dirX * (hw + 6.6), 0.52, iz),
					size = Vector3.new(0.7, 0.05, ew.width - 3),
					color = COLORS.WHITE_LINE,
					material = Enum.Material.SmoothPlastic,
					canCollide = false,
					castShadow = false,
				})
			end
		end
	end
end

local function buildPlotsAndSidewalks(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "02_SidewalksAndPlots"
	folder.Parent = parent

	local swW = WorldGrid.SIDEWALK_WIDTH
	local swH = WorldGrid.SIDEWALK_HEIGHT

	for _, plot in ipairs(WorldGrid.PLOTS) do
		local blockFolder = Instance.new("Folder")
		blockFolder.Name = plot.id .. "_" .. string.gsub(plot.district, " ", "")
		blockFolder.Parent = folder

		local cx, cz = plot.center.X, plot.center.Z
		local sx, sz = plot.size.X, plot.size.Z

		-- Bó vỉa hè nâng cao 0.65 stud trên mặt đường nhựa (đỉnh ở Y = 1.15)
		PartBuilder.part({
			name = "SidewalkBase",
			parent = blockFolder,
			pos = Vector3.new(cx, 0.575, cz),
			size = Vector3.new(sx, 1.15, sz),
			color = COLORS.SIDEWALK,
			material = Enum.Material.Concrete,
		})

		-- Bó vỉa sơn đỏ cấm đỗ xe ở 4 góc ngã tư chuẩn California (đỉnh ở Y = 1.20, không Z-fight)
		for _, dx in ipairs({ -1, 1 }) do
			for _, dz in ipairs({ -1, 1 }) do
				PartBuilder.part({
					name = "RedFireLaneCurbX",
					parent = blockFolder,
					pos = Vector3.new(cx + dx * (sx * 0.5 - 5.5), 1.17, cz + dz * (sz * 0.5 - 0.3)),
					size = Vector3.new(11, 0.06, 0.6),
					color = COLORS.RED_CURB,
					material = Enum.Material.SmoothPlastic,
				})
				PartBuilder.part({
					name = "RedFireLaneCurbZ",
					parent = blockFolder,
					pos = Vector3.new(cx + dx * (sx * 0.5 - 0.3), 1.17, cz + dz * (sz * 0.5 - 5.5)),
					size = Vector3.new(0.6, 0.06, 11),
					color = COLORS.RED_CURB,
					material = Enum.Material.SmoothPlastic,
				})
			end
		end

		local innerX = sx - swW * 2
		local innerZ = sz - swW * 2

		if plot.id == "Plot_C2" then
			-- QUẢNG TRƯỜNG TRUNG TÂM LEGION SQUARE (Đối xứng 100%, cao độ tách lớp chống Z-fighting tuyệt đối)
			PartBuilder.part({
				name = "LegionSquareTurf",
				parent = blockFolder,
				pos = Vector3.new(cx, 1.10, cz),
				size = Vector3.new(innerX, 0.18, innerZ),
				color = COLORS.PLAZA_TURF,
				material = Enum.Material.Grass,
			})

			-- Sân đá trung tâm đối xứng + 4 lối dạo chữ thập nối thẳng ra vỉa hè 4 hướng
			PartBuilder.part({
				name = "PlazaWalkNS",
				parent = blockFolder,
				pos = Vector3.new(cx, 1.19, cz),
				size = Vector3.new(28, 0.08, innerZ),
				color = COLORS.PLAZA_STONE,
				material = Enum.Material.Sandstone,
			})
			PartBuilder.part({
				name = "PlazaWalkEW",
				parent = blockFolder,
				pos = Vector3.new(cx, 1.195, cz),
				size = Vector3.new(innerX, 0.08, 24),
				color = COLORS.PLAZA_STONE,
				material = Enum.Material.Sandstone,
			})
			PartBuilder.part({
				name = "PlazaCenterCourt",
				parent = blockFolder,
				pos = Vector3.new(cx, 1.21, cz),
				size = Vector3.new(96, 0.10, 86),
				color = COLORS.PLAZA_STONE,
				material = Enum.Material.Sandstone,
			})

			-- Hồ nước phản chiếu trung tâm (Reflecting Pool) chuẩn Legion Square
			PartBuilder.part({
				name = "ReflectingPoolRim",
				parent = blockFolder,
				pos = Vector3.new(cx, 1.60, cz - 8),
				size = Vector3.new(44, 0.72, 32),
				color = COLORS.PLAZA_DARK_STONE,
				material = Enum.Material.Basalt,
			})
			PartBuilder.part({
				name = "ReflectingPoolWater",
				parent = blockFolder,
				pos = Vector3.new(cx, 1.92, cz - 8),
				size = Vector3.new(39, 0.16, 27),
				color = COLORS.POOL_WATER,
				material = Enum.Material.Glass,
				transparency = 0.18,
			})

			-- Cụm điêu khắc hình học Đỏ/Vàng biểu tượng ở tâm hồ nước Legion Square
			PartBuilder.part({
				name = "SculpturePedestal",
				parent = blockFolder,
				pos = Vector3.new(cx, 2.55, cz - 8),
				size = Vector3.new(9, 1.3, 9),
				color = COLORS.PLAZA_DARK_STONE,
				material = Enum.Material.Marble,
			})
			PartBuilder.part({
				name = "LegionRedTower",
				parent = blockFolder,
				pos = Vector3.new(cx, 7.6, cz - 8),
				size = Vector3.new(3.4, 9.2, 3.4),
				color = COLORS.SCULPTURE_RED,
				material = Enum.Material.SmoothPlastic,
			})
			PartBuilder.part({
				name = "LegionRedWing",
				parent = blockFolder,
				pos = Vector3.new(cx, 7.2, cz - 8),
				size = Vector3.new(9.6, 2.4, 2.4),
				color = COLORS.SCULPTURE_RED,
				material = Enum.Material.SmoothPlastic,
			})
			PartBuilder.part({
				name = "LegionGoldCrown",
				parent = blockFolder,
				pos = Vector3.new(cx, 13.2, cz - 8),
				size = Vector3.new(3.0, 3.0, 3.0),
				color = COLORS.YELLOW_LINE,
				material = Enum.Material.Neon,
			})

			-- 4 Bồn đá nghỉ chân đối xứng ở 4 góc sân đá
			for _, sxSign in ipairs({ -1, 1 }) do
				for _, szSign in ipairs({ -1, 1 }) do
					PartBuilder.part({
						name = "StoneBenchPlanter",
						parent = blockFolder,
						pos = Vector3.new(cx + sxSign * 34, 1.72, cz + szSign * 28),
						size = Vector3.new(14, 0.95, 6),
						color = COLORS.CURB,
						material = Enum.Material.Concrete,
					})
				end
			end

			-- SpawnLocation chính thức cho người chơi vào game (quay mặt về phía Bắc)
			local spawnLoc = Instance.new("SpawnLocation")
			spawnLoc.Name = "LegionSquareSpawn"
			spawnLoc.Anchored = true
			spawnLoc.Neutral = true
			spawnLoc.Size = Vector3.new(14, 0.16, 14)
			spawnLoc.CFrame = CFrame.new(WorldGrid.SPAWN_POS.X, 1.28, WorldGrid.SPAWN_POS.Z)
			spawnLoc.Color = COLORS.BOARDWALK
			spawnLoc.Material = Enum.Material.Marble
			spawnLoc.TopSurface = Enum.SurfaceType.Smooth
			spawnLoc.BottomSurface = Enum.SurfaceType.Smooth
			spawnLoc.Parent = blockFolder

			PartBuilder.groundPlaque(
				blockFolder,
				Vector3.new(cx, 1.30, cz + 20),
				"LEGION SQUARE [C2]",
				plot.subtitle,
				Color3.fromRGB(114, 204, 114)
			)
		else
			-- Ô ĐẤT SẠCH (Clean Development Pad — đỉnh ở Y = 1.20, tách khỏi SidewalkBase Y = 1.15 nên 0% Z-fighting)
			PartBuilder.part({
				name = "DevelopmentPad",
				parent = blockFolder,
				pos = Vector3.new(cx, 1.12, cz),
				size = Vector3.new(innerX, 0.16, innerZ),
				color = COLORS.PLOT_PAD,
				material = Enum.Material.Concrete,
			})

			PartBuilder.groundPlaque(
				blockFolder,
				Vector3.new(cx, 1.25, cz),
				string.format("%s [%s]", plot.district, string.sub(plot.id, -2)),
				plot.subtitle,
				COLORS.YELLOW_LINE
			)
		end
	end

	-- Vỉa hè vành đai ngoài (Tây, Đông, Bắc) bọc khít toàn bộ mạng lưới đường bộ
	PartBuilder.part({
		name = "WestPerimeterSidewalk",
		parent = folder,
		pos = Vector3.new(-350, swH * 0.5, -38),
		size = Vector3.new(20, swH + 1.0, 404),
		color = COLORS.SIDEWALK,
		material = Enum.Material.Concrete,
	})
	PartBuilder.part({
		name = "EastPerimeterSidewalk",
		parent = folder,
		pos = Vector3.new(350, swH * 0.5, -38),
		size = Vector3.new(20, swH + 1.0, 404),
		color = COLORS.SIDEWALK,
		material = Enum.Material.Concrete,
	})
	PartBuilder.part({
		name = "NorthVinewoodWalkway",
		parent = folder,
		pos = Vector3.new(0, swH * 0.5, -245),
		size = Vector3.new(720, swH + 1.0, 10),
		color = COLORS.SIDEWALK,
		material = Enum.Material.Concrete,
	})
end

local function buildCoastAndHills(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "03_NaturalPerimeter"
	folder.Parent = parent

	-- 0. Nền đất tổng thể phủ kín từ Bắc tới tận bờ biển (không còn khe hở ở 4 góc)
	PartBuilder.part({
		name = "FoundationGroundApron",
		parent = folder,
		pos = Vector3.new(0, -1.6, 0),
		size = Vector3.new(720, 2.2, 720),
		color = COLORS.HILLS_LOW,
		material = Enum.Material.Grass,
	})

	-- 1. Phố đi bộ ven biển Vespucci Promenade + Tường chắn cát thấp (Z = 164 -> 186, rộng đủ 720 studs)
	PartBuilder.part({
		name = "VespucciBoardwalk",
		parent = folder,
		pos = Vector3.new(0, 0.32, 175),
		size = Vector3.new(720, 1.65, 22),
		color = COLORS.BOARDWALK,
		material = Enum.Material.Sandstone,
	})
	PartBuilder.part({
		name = "BoardwalkSeawallCoping",
		parent = folder,
		pos = Vector3.new(0, 1.45, 185.4),
		size = Vector3.new(720, 0.7, 1.4),
		color = COLORS.SIDEWALK,
		material = Enum.Material.Concrete,
	})

	-- 2. Bãi cát vàng khô -> Cát ẩm sát mép sóng -> Bọt sóng trắng -> Biển cạn ngọc bích -> Biển Thái Bình Dương sâu
	PartBuilder.part({
		name = "VespucciDrySand",
		parent = folder,
		pos = Vector3.new(0, -0.1, 206),
		size = Vector3.new(720, 1.4, 40),
		color = COLORS.DRY_SAND,
		material = Enum.Material.Sand,
	})
	PartBuilder.wedge({
		name = "VespucciSandSlope",
		parent = folder,
		cframe = CFrame.new(0, 0.2, 206) * CFrame.Angles(0, math.rad(180), 0),
		size = Vector3.new(720, 1.2, 40),
		color = COLORS.DRY_SAND,
		material = Enum.Material.Sand,
	})
	PartBuilder.part({
		name = "VespucciWetShoreSand",
		parent = folder,
		pos = Vector3.new(0, -0.45, 238),
		size = Vector3.new(720, 1.2, 24),
		color = COLORS.WET_SAND,
		material = Enum.Material.Sand,
	})
	PartBuilder.part({
		name = "ShorelineFoam",
		parent = folder,
		pos = Vector3.new(0, -0.18, 250),
		size = Vector3.new(720, 0.25, 5),
		color = COLORS.SEA_FOAM,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.22,
		canCollide = false,
	})
	PartBuilder.part({
		name = "ShallowTurquoiseWater",
		parent = folder,
		pos = Vector3.new(0, -0.55, 268),
		size = Vector3.new(720, 0.9, 36),
		color = COLORS.SHALLOW_OCEAN,
		material = Enum.Material.Glass,
		transparency = 0.16,
	})
	PartBuilder.part({
		name = "PacificDeepOcean",
		parent = folder,
		pos = Vector3.new(0, -0.6, 323),
		size = Vector3.new(720, 1.0, 74),
		color = COLORS.DEEP_OCEAN,
		material = Enum.Material.Glass,
		transparency = 0.14,
	})

	-- 3. Dãy đồi Vinewood Hills phân tầng đối xứng hùng vĩ phía Bắc (Z = -250 -> -360)
	local hillTiers = {
		{ name = "VinewoodFoothillBase", pos = Vector3.new(0, 6, -280),    size = Vector3.new(720, 14, 60), color = COLORS.HILLS_LOW },
		{ name = "VinewoodMidRidge",     pos = Vector3.new(0, 16, -316),   size = Vector3.new(660, 22, 64), color = COLORS.HILLS_MID },
		{ name = "VinewoodWestPeak",     pos = Vector3.new(-200, 27, -338), size = Vector3.new(240, 32, 44), color = COLORS.HILLS_HIGH },
		{ name = "VinewoodCenterSummit", pos = Vector3.new(0, 35, -342),   size = Vector3.new(260, 42, 36), color = COLORS.HILLS_HIGH },
		{ name = "VinewoodEastPeak",     pos = Vector3.new(200, 26, -338), size = Vector3.new(240, 30, 44), color = COLORS.HILLS_MID },
	}
	for _, tier in ipairs(hillTiers) do
		PartBuilder.part({
			name = tier.name,
			parent = folder,
			pos = tier.pos,
			size = tier.size,
			color = tier.color,
			material = Enum.Material.Grass,
		})
	end
end

function CityFoundation.build(forceRebuild: boolean?): Model
	-- Dọn sạch bản thử nghiệm cũ nếu còn tồn tại
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
	buildCoastAndHills(phase1)
	buildRoadNetwork(phase1)
	buildPlotsAndSidewalks(phase1)

	return root :: Model
end

return CityFoundation
