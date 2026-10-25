--!strict

local CityUtils = require(script.Parent.Parent:WaitForChild("CityUtils"))

local RoadsAndPark = {}

local function drawDashedLineZ(parent: Instance, xPos: number, zStart: number, zEnd: number, color: Color3)
	local z = zStart
	while z + 6 <= zEnd do
		CityUtils.makePart({
			Name = "LaneDash",
			Size = Vector3.new(0.45, 0.05, 6),
			Position = Vector3.new(xPos, 0.52, z + 3),
			Color = color,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = parent,
		})
		z += 12
	end
end

local function drawDashedLineX(parent: Instance, zPos: number, xStart: number, xEnd: number, color: Color3)
	local x = xStart
	while x + 6 <= xEnd do
		CityUtils.makePart({
			Name = "LaneDash",
			Size = Vector3.new(6, 0.05, 0.45),
			Position = Vector3.new(x + 3, 0.52, zPos),
			Color = color,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = parent,
		})
		x += 12
	end
end

local function drawCrosswalkAcrossX(parent: Instance, centerZ: number, halfWidth: number)
	local x = -halfWidth + 2.5
	while x <= halfWidth - 2.5 do
		CityUtils.makePart({
			Name = "CrosswalkStripe",
			Size = Vector3.new(1.8, 0.06, 6.5),
			Position = Vector3.new(x, 0.525, centerZ),
			Color = Color3.fromRGB(242, 244, 248),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = parent,
		})
		x += 3.8
	end
end

local function drawCrosswalkAcrossZ(parent: Instance, centerX: number, halfWidth: number)
	local z = -halfWidth + 2.5
	while z <= halfWidth - 2.5 do
		CityUtils.makePart({
			Name = "CrosswalkStripe",
			Size = Vector3.new(6.5, 0.06, 1.8),
			Position = Vector3.new(centerX, 0.525, z),
			Color = Color3.fromRGB(242, 244, 248),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = parent,
		})
		z += 3.8
	end
end

function RoadsAndPark.build(cityRoot: Instance)
	local infraFolder = Instance.new("Folder")
	infraFolder.Name = "RoadsAndInfrastructure"
	infraFolder.Parent = cityRoot

	-- Nền đất đô thị rộng lớn
	CityUtils.makePart({
		Name = "UrbanFoundation",
		Size = Vector3.new(540, 4, 540),
		Position = Vector3.new(0, -2, 0),
		Color = Color3.fromRGB(62, 118, 68),
		Material = Enum.Material.Grass,
		Parent = infraFolder,
	})

	local roadColor = Color3.fromRGB(38, 40, 46)
	local dashYellow = Color3.fromRGB(245, 198, 54)
	local sidewalkColor = Color3.fromRGB(168, 172, 180)
	local curbColor = Color3.fromRGB(132, 136, 145)

	-- ========================================================================
	-- 1. MẠNG LƯỚI ĐƯỜNG NHỰA (ASPHALT ROADS)
	-- ========================================================================
	-- Đại lộ Bắc-Nam trung tâm (X = 0)
	CityUtils.makePart({
		Name = "MainBoulevard_NS",
		Size = Vector3.new(32, 0.5, 392),
		Position = Vector3.new(0, 0.25, -32),
		Color = roadColor,
		Material = Enum.Material.Asphalt,
		Parent = infraFolder,
	})

	-- Đại lộ Đông-Tây trung tâm (Z = 0)
	CityUtils.makePart({
		Name = "MainBoulevard_EW",
		Size = Vector3.new(456, 0.5, 32),
		Position = Vector3.new(0, 0.25, 0),
		Color = roadColor,
		Material = Enum.Material.Asphalt,
		Parent = infraFolder,
	})

	-- Đường vành đai Bắc (Z = -150) & Nam (Z = +150)
	for _, zRing in ipairs({ -150, 150 }) do
		CityUtils.makePart({
			Name = "RingRoad_EW_" .. tostring(zRing),
			Size = Vector3.new(456, 0.5, 28),
			Position = Vector3.new(0, 0.25, zRing),
			Color = roadColor,
			Material = Enum.Material.Asphalt,
			Parent = infraFolder,
		})
	end

	-- Đường vành đai Tây (X = -150) & Đông (X = +150)
	for _, xRing in ipairs({ -150, 150 }) do
		CityUtils.makePart({
			Name = "RingRoad_NS_" .. tostring(xRing),
			Size = Vector3.new(28, 0.5, 392),
			Position = Vector3.new(xRing, 0.25, -32),
			Color = roadColor,
			Material = Enum.Material.Asphalt,
			Parent = infraFolder,
		})
	end

	-- Vạch kẻ tim đường màu vàng
	drawDashedLineZ(infraFolder, 0, -132, -24, dashYellow)
	drawDashedLineZ(infraFolder, 0, 24, 132, dashYellow)
	drawDashedLineX(infraFolder, 0, -132, -24, dashYellow)
	drawDashedLineX(infraFolder, 0, 24, 132, dashYellow)
	drawDashedLineX(infraFolder, -150, -132, -20, dashYellow)
	drawDashedLineX(infraFolder, -150, 20, 132, dashYellow)
	drawDashedLineX(infraFolder, 150, -132, -20, dashYellow)
	drawDashedLineX(infraFolder, 150, 20, 132, dashYellow)
	drawDashedLineZ(infraFolder, -150, -132, -20, dashYellow)
	drawDashedLineZ(infraFolder, -150, 20, 132, dashYellow)
	drawDashedLineZ(infraFolder, 150, -132, -20, dashYellow)
	drawDashedLineZ(infraFolder, 150, 20, 132, dashYellow)

	-- Vạch qua đường (Zebra Crosswalks) ở Ngã Tư Trung Tâm & các nút giao
	drawCrosswalkAcrossX(infraFolder, -20, 15)
	drawCrosswalkAcrossX(infraFolder, 20, 15)
	drawCrosswalkAcrossZ(infraFolder, -20, 15)
	drawCrosswalkAcrossZ(infraFolder, 20, 15)
	drawCrosswalkAcrossX(infraFolder, 132, 15)
	drawCrosswalkAcrossX(infraFolder, -132, 15)

	-- ========================================================================
	-- 2. VỈA HÈ 4 KHU PHỐ CHÍNH & CÁC KHU NGOẠI VI
	-- ========================================================================
	local innerBlocks = {
		{ name = "Block_NW_Finance", pos = Vector3.new(-76, 0.6, -76), size = Vector3.new(120, 1.2, 120) },
		{ name = "Block_NE_Commercial", pos = Vector3.new(76, 0.6, -76), size = Vector3.new(120, 1.2, 120) },
		{ name = "Block_SW_CentralPark", pos = Vector3.new(-76, 0.6, 76), size = Vector3.new(120, 1.2, 120) },
		{ name = "Block_SE_Entertainment", pos = Vector3.new(76, 0.6, 76), size = Vector3.new(120, 1.2, 120) },
		{ name = "Plaza_West_Service", pos = Vector3.new(-196, 0.6, 0), size = Vector3.new(64, 1.2, 272) },
		{ name = "Plaza_East_Civic", pos = Vector3.new(196, 0.6, 0), size = Vector3.new(64, 1.2, 272) },
		{ name = "Plaza_North_Skyline", pos = Vector3.new(0, 0.6, -196), size = Vector3.new(328, 1.2, 64) },
	}

	for _, blk in ipairs(innerBlocks) do
		CityUtils.makePart({
			Name = blk.name .. "_Curb",
			Size = blk.size + Vector3.new(0.8, -0.05, 0.8),
			Position = blk.pos,
			Color = curbColor,
			Material = Enum.Material.Concrete,
			Parent = infraFolder,
		})
		CityUtils.makePart({
			Name = blk.name,
			Size = blk.size,
			Position = blk.pos,
			Color = sidewalkColor,
			Material = Enum.Material.Concrete,
			Parent = infraFolder,
		})
	end

	-- ========================================================================
	-- 3. ĐÈN TÍN HIỆU GIAO THÔNG & ĐÈN ĐƯỜNG THÔNG MINH
	-- ========================================================================
	-- 4 cột đèn giao thông tại Ngã Tư Trung Tâm
	CityUtils.buildTrafficLight(infraFolder, Vector3.new(-18, 1.2, -18), Vector3.new(0, 0, -1), "NS")
	CityUtils.buildTrafficLight(infraFolder, Vector3.new(18, 1.2, 18), Vector3.new(0, 0, 1), "NS")
	CityUtils.buildTrafficLight(infraFolder, Vector3.new(18, 1.2, -18), Vector3.new(1, 0, 0), "EW")
	CityUtils.buildTrafficLight(infraFolder, Vector3.new(-18, 1.2, 18), Vector3.new(-1, 0, 0), "EW")

	-- Hệ thống đèn đường dọc hai bên đại lộ
	for _, zLamp in ipairs({ -115, -75, -38, 38, 75, 115 }) do
		CityUtils.buildStreetLamp(infraFolder, Vector3.new(-17.5, 1.2, zLamp), Vector3.new(1, 0, 0))
		CityUtils.buildStreetLamp(infraFolder, Vector3.new(17.5, 1.2, zLamp), Vector3.new(-1, 0, 0))
	end
	for _, xLamp in ipairs({ -115, -75, -38, 38, 75, 115 }) do
		CityUtils.buildStreetLamp(infraFolder, Vector3.new(xLamp, 1.2, -17.5), Vector3.new(0, 0, 1))
		CityUtils.buildStreetLamp(infraFolder, Vector3.new(xLamp, 1.2, 17.5), Vector3.new(0, 0, -1))
	end

	-- ========================================================================
	-- 4. CÔNG VIÊN TRUNG TÂM, QUẢNG TRƯỜNG SPAWN & ĐÀI PHUN NƯỚC TƯƠNG TÁC
	-- ========================================================================
	local parkFolder = Instance.new("Folder")
	parkFolder.Name = "CentralParkAndSpawn"
	parkFolder.Parent = cityRoot

	-- Thảm cỏ xanh công viên
	CityUtils.makePart({
		Name = "ParkLawn",
		Size = Vector3.new(104, 0.25, 104),
		Position = Vector3.new(-76, 1.3, 76),
		Color = Color3.fromRGB(74, 158, 84),
		Material = Enum.Material.Grass,
		Parent = parkFolder,
	})

	-- Lối đi lát đá chéo và quảng trường tròn giữa công viên
	CityUtils.makePart({
		Name = "CentralPlazaCircle",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.32, 42, 42),
		CFrame = CFrame.new(-76, 1.35, 76) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(205, 208, 216),
		Material = Enum.Material.Marble,
		Parent = parkFolder,
	})
	CityUtils.makePart({
		Name = "ParkWalkway_NS",
		Size = Vector3.new(10, 0.3, 104),
		Position = Vector3.new(-76, 1.34, 76),
		Color = Color3.fromRGB(196, 200, 208),
		Material = Enum.Material.Cobblestone,
		Parent = parkFolder,
	})
	CityUtils.makePart({
		Name = "ParkWalkway_EW",
		Size = Vector3.new(104, 0.3, 10),
		Position = Vector3.new(-76, 1.34, 76),
		Color = Color3.fromRGB(196, 200, 208),
		Material = Enum.Material.Cobblestone,
		Parent = parkFolder,
	})

	-- Điểm xuất hiện chính của người chơi (SpawnLocation) hướng ra Ngã Tư Trung Tâm
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "CityMainSpawn"
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.Duration = 0
	spawnLoc.Size = Vector3.new(14, 0.4, 14)
	spawnLoc.CFrame = CFrame.lookAt(Vector3.new(-32, 1.4, 32), Vector3.new(0, 1.4, 0))
	spawnLoc.Color = Color3.fromRGB(228, 234, 245)
	spawnLoc.Material = Enum.Material.Marble
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.Parent = parkFolder

	CityUtils.makePart({
		Name = "SpawnNeonRing",
		Size = Vector3.new(15.2, 0.25, 15.2),
		CFrame = spawnLoc.CFrame * CFrame.new(0, -0.05, 0),
		Color = Color3.fromRGB(56, 189, 248),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parkFolder,
	})

	-- Cổng chào Quảng Trường Ánh Sáng
	for _, offset in ipairs({ Vector3.new(-8, 5.5, 0), Vector3.new(8, 5.5, 0) }) do
		CityUtils.makePart({
			Name = "WelcomeArchPillar",
			Size = Vector3.new(1.6, 11, 1.6),
			CFrame = spawnLoc.CFrame * CFrame.new(offset.X, offset.Y, -7),
			Color = Color3.fromRGB(38, 44, 58),
			Material = Enum.Material.Metal,
			Parent = parkFolder,
		})
	end
	local archHeaderPos = (spawnLoc.CFrame * CFrame.new(0, 11.8, -7)).Position
	local archDir = (Vector3.new(0, 1.4, 0) - Vector3.new(-32, 1.4, 32)).Unit
	CityUtils.makeSignBoard(
		parkFolder,
		archHeaderPos,
		-archDir,
		Vector2.new(19, 3.2),
		"THÀNH PHỐ ÁNH SÁNG",
		"Khám phá • Lái xe • Giao hàng • Tương tác",
		Color3.fromRGB(20, 26, 42),
		Color3.fromRGB(56, 189, 248)
	)

	-- Trụ Điều Khiển Thời Gian / Bầu Trời (Ngày / Hoàng Hôn / Đêm Neon)
	local timeKiosk = CityUtils.makePart({
		Name = "TimeWeatherKiosk",
		Size = Vector3.new(3.2, 5.4, 1.8),
		CFrame = CFrame.lookAt(Vector3.new(-24, 3.9, 44), Vector3.new(-32, 3.9, 32)),
		Color = Color3.fromRGB(30, 36, 52),
		Material = Enum.Material.Metal,
		Parent = parkFolder,
	})
	CityUtils.makePart({
		Name = "KioskScreen",
		Size = Vector3.new(2.6, 2.2, 0.2),
		CFrame = timeKiosk.CFrame * CFrame.new(0, 0.9, -0.86),
		Color = Color3.fromRGB(99, 102, 241),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parkFolder,
	})
	CityUtils.addPrompt(
		timeKiosk,
		"CycleTime",
		"Đổi thời gian (Ngày / Hoàng Hôn / Đêm)",
		"Trụ Điều Khiển Bầu Trời",
		12
	)

	-- Đài phun nước Nhạc Nước Ánh Sáng ở tâm công viên (-76, 1.4, 76)
	local fountainModel = Instance.new("Model")
	fountainModel.Name = "IlluminatedFountain"
	fountainModel.Parent = parkFolder

	CityUtils.makePart({
		Name = "OuterBasinRim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.2, 20, 20),
		CFrame = CFrame.new(-76, 2.3, 76) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(215, 220, 230),
		Material = Enum.Material.Marble,
		Parent = fountainModel,
	})
	local waterPool = CityUtils.makePart({
		Name = "FountainWater",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.8, 17.6, 17.6),
		CFrame = CFrame.new(-76, 2.65, 76) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(34, 211, 238),
		Material = Enum.Material.Neon,
		Transparency = 0.25,
		CanCollide = false,
		Parent = fountainModel,
	})
	CityUtils.makePart({
		Name = "CenterColumn",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(5.5, 4.2, 4.2),
		CFrame = CFrame.new(-76, 4.2, 76) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(230, 234, 242),
		Material = Enum.Material.Marble,
		Parent = fountainModel,
	})
	local crystal = CityUtils.makePart({
		Name = "FountainCrystal",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3.2, 3.2, 3.2),
		Position = Vector3.new(-76, 8.2, 76),
		Color = Color3.fromRGB(56, 189, 248),
		Material = Enum.Material.Neon,
		Parent = fountainModel,
	})
	local fLight = Instance.new("PointLight")
	fLight.Range = 36
	fLight.Brightness = 2.4
	fLight.Color = Color3.fromRGB(56, 189, 248)
	fLight.Parent = crystal

	local sprayAtt = Instance.new("Attachment")
	sprayAtt.Position = Vector3.new(0, 1.2, 0)
	sprayAtt.Parent = crystal

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(165, 243, 252), Color3.fromRGB(255, 255, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.7, 1.1),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	emitter.Transparency = NumberSequence.new(0.15, 0.9)
	emitter.Lifetime = NumberRange.new(1.4, 2.0)
	emitter.Rate = 45
	emitter.Speed = NumberRange.new(14, 19)
	emitter.SpreadAngle = Vector2.new(22, 22)
	emitter.Acceleration = Vector3.new(0, -24, 0)
	emitter.Parent = sprayAtt

	CityUtils.addPrompt(
		waterPool,
		"FountainWish",
		"Đổi màu nhạc nước & Ước nguyện",
		"Đài Phun Nước Ánh Sáng",
		15
	)

	-- Cây xanh đa sắc (xanh lá & hoa anh đào hồng) + ghế đá quanh công viên
	local parkTrees = {
		{ pos = Vector3.new(-114, 1.4, 38), color = Color3.fromRGB(64, 156, 80), scale = 1.1 },
		{ pos = Vector3.new(-114, 1.4, 114), color = Color3.fromRGB(244, 143, 177), scale = 1.05 },
		{ pos = Vector3.new(-38, 1.4, 114), color = Color3.fromRGB(68, 162, 86), scale = 1.1 },
		{ pos = Vector3.new(-118, 1.4, 76), color = Color3.fromRGB(82, 170, 92), scale = 0.95 },
		{ pos = Vector3.new(-76, 1.4, 118), color = Color3.fromRGB(244, 143, 177), scale = 1.0 },
		{ pos = Vector3.new(-52, 1.4, 52), color = Color3.fromRGB(72, 160, 88), scale = 0.9 },
	}
	for _, t in ipairs(parkTrees) do
		CityUtils.buildTree(parkFolder, t.pos, t.color, t.scale)
	end

	CityUtils.buildBench(parkFolder, Vector3.new(-60, 1.4, 76), Vector3.new(-1, 0, 0))
	CityUtils.buildBench(parkFolder, Vector3.new(-92, 1.4, 76), Vector3.new(1, 0, 0))
	CityUtils.buildBench(parkFolder, Vector3.new(-76, 1.4, 60), Vector3.new(0, 0, 1))
	CityUtils.buildBench(parkFolder, Vector3.new(-76, 1.4, 92), Vector3.new(0, 0, -1))

	-- ========================================================================
	-- 5. PHỐ ĐI BỘ VEN BIỂN & BẾN CẢNG PHÍA NAM (Z > 164)
	-- ========================================================================
	local harborFolder = Instance.new("Folder")
	harborFolder.Name = "SouthWaterfrontHarbor"
	harborFolder.Parent = cityRoot

	-- Phố đi bộ lát đá sát bờ biển
	CityUtils.makePart({
		Name = "BoardwalkPromenade",
		Size = Vector3.new(456, 1.4, 24),
		Position = Vector3.new(0, 0.7, 176),
		Color = Color3.fromRGB(190, 186, 178),
		Material = Enum.Material.Sandstone,
		Parent = harborFolder,
	})

	-- Mặt biển xanh ngọc lấp lánh
	CityUtils.makePart({
		Name = "OceanWater",
		Size = Vector3.new(540, 3, 105),
		Position = Vector3.new(0, -0.8, 240),
		Color = Color3.fromRGB(14, 145, 188),
		Material = Enum.Material.Glass,
		Transparency = 0.22,
		Reflectance = 0.25,
		Parent = harborFolder,
	})

	-- Cầu cảng gỗ vươn ra biển (X = 0, Z = 188..232)
	local pier = CityUtils.makePart({
		Name = "WoodenPierDeck",
		Size = Vector3.new(24, 0.9, 46),
		Position = Vector3.new(0, 1.35, 210),
		Color = Color3.fromRGB(138, 92, 56),
		Material = Enum.Material.WoodPlanks,
		Parent = harborFolder,
	})
	for _, zPillar in ipairs({ 194, 208, 222, 230 }) do
		for _, xPillar in ipairs({ -10.5, 10.5 }) do
			CityUtils.makePart({
				Name = "PierPost",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(6, 1.4, 1.4),
				CFrame = CFrame.new(xPillar, 0.8, zPillar) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(98, 66, 40),
				Material = Enum.Material.Wood,
				Parent = harborFolder,
			})
		end
	end

	CityUtils.makeSignBoard(
		harborFolder,
		Vector3.new(0, 8.5, 188),
		Vector3.new(0, 0, -1),
		Vector2.new(18, 2.8),
		"BẾN CẢNG ÁNH SÁNG",
		"Điểm giao hàng VIP & Ngắm hoàng hôn",
		Color3.fromRGB(18, 32, 48),
		Color3.fromRGB(45, 212, 191)
	)

	-- Điểm nhận hàng ở cuối cầu cảng cho nhiệm vụ Giao Hàng
	local pierDrop = CityUtils.makePart({
		Name = "DeliveryPoint_HarborPier",
		Size = Vector3.new(4, 3.2, 4),
		Position = Vector3.new(0, 3.2, 196),
		Color = Color3.fromRGB(45, 212, 191),
		Material = Enum.Material.Metal,
		Parent = harborFolder,
	})
	CityUtils.addPrompt(pierDrop, "DeliverOrder", "Giao đơn hàng tại đây", "Bến Cảng Ánh Sáng", 14, {
		TargetId = "HarborPier",
	})

	CityUtils.buildBench(harborFolder, Vector3.new(-8, 1.8, 218), Vector3.new(1, 0, 0))
	CityUtils.buildBench(harborFolder, Vector3.new(8, 1.8, 218), Vector3.new(-1, 0, 0))

	for _, xWalk in ipairs({ -90, -45, 45, 90 }) do
		CityUtils.buildTree(harborFolder, Vector3.new(xWalk, 1.4, 175), Color3.fromRGB(58, 152, 85), 0.95)
		CityUtils.buildBench(harborFolder, Vector3.new(xWalk + 12, 1.4, 183), Vector3.new(0, 0, 1))
	end
	local _ = pier
end

return RoadsAndPark
