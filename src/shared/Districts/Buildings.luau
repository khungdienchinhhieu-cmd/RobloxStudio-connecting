--!strict

local CollectionService = game:GetService("CollectionService")
local CityConfig = require(script.Parent.Parent:WaitForChild("CityConfig"))
local CityUtils = require(script.Parent.Parent:WaitForChild("CityUtils"))

local Buildings = {}

-- Helper dựng vỏ tòa nhà tầng trệt có cửa mở thật để người chơi bước vào trong
local function buildStorefrontShell(
	parent: Instance,
	name: string,
	center: Vector3,
	size: Vector3,
	wallColor: Color3,
	trimColor: Color3,
	doorSide: string -- "South" (+Z), "North" (-Z), "West" (-X), "East" (+X)
): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent

	local halfX = size.X / 2
	local halfZ = size.Z / 2
	local h = size.Y
	local wallThick = 1.2
	local doorWidth = 9
	local doorHeight = 9.5

	-- Sàn lát gạch bên trong
	CityUtils.makePart({
		Name = "InteriorFloor",
		Size = Vector3.new(size.X - 0.4, 0.3, size.Z - 0.4),
		Position = center + Vector3.new(0, 0.15, 0),
		Color = Color3.fromRGB(224, 220, 212),
		Material = Enum.Material.Marble,
		Parent = m,
	})

	-- Mái & viền mái
	CityUtils.makePart({
		Name = "RoofSlab",
		Size = Vector3.new(size.X + 1.4, 1.2, size.Z + 1.4),
		Position = center + Vector3.new(0, h + 0.6, 0),
		Color = trimColor,
		Material = Enum.Material.Concrete,
		Parent = m,
	})

	-- Đèn trần ấm áp bên trong tòa nhà
	local ceilingLamp = CityUtils.makePart({
		Name = "CeilingLight",
		Size = Vector3.new(6, 0.25, 6),
		Position = center + Vector3.new(0, h - 0.2, 0),
		Color = Color3.fromRGB(255, 244, 214),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = m,
	})
	local pLight = Instance.new("PointLight")
	pLight.Range = 36
	pLight.Brightness = 1.6
	pLight.Color = Color3.fromRGB(255, 240, 205)
	pLight.Parent = ceilingLamp

	local function buildWallWithDoorX(zOffset: number, hasDoor: boolean)
		if not hasDoor then
			CityUtils.makePart({
				Name = "Wall",
				Size = Vector3.new(size.X, h, wallThick),
				Position = center + Vector3.new(0, h / 2, zOffset),
				Color = wallColor,
				Material = Enum.Material.Concrete,
				Parent = m,
			})
			return
		end
		local sideW = (size.X - doorWidth) / 2
		-- Hai mảng kính mặt tiền hai bên cửa
		for _, signX in ipairs({ -1, 1 }) do
			local xPos = signX * (doorWidth / 2 + sideW / 2)
			CityUtils.makePart({
				Name = "FrontLowWall",
				Size = Vector3.new(sideW, 2.2, wallThick),
				Position = center + Vector3.new(xPos, 1.1, zOffset),
				Color = wallColor,
				Material = Enum.Material.Concrete,
				Parent = m,
			})
			CityUtils.makePart({
				Name = "FrontShowWindow",
				Size = Vector3.new(sideW - 1.2, doorHeight - 2.2, 0.35),
				Position = center + Vector3.new(xPos, 2.2 + (doorHeight - 2.2) / 2, zOffset),
				Color = Color3.fromRGB(165, 220, 245),
				Material = Enum.Material.Glass,
				Transparency = 0.45,
				Parent = m,
			})
			CityUtils.makePart({
				Name = "FrontUpperWall",
				Size = Vector3.new(sideW, h - doorHeight, wallThick),
				Position = center + Vector3.new(xPos, doorHeight + (h - doorHeight) / 2, zOffset),
				Color = wallColor,
				Material = Enum.Material.Concrete,
				Parent = m,
			})
		end
		-- Đà ngang phía trên cửa chính
		CityUtils.makePart({
			Name = "DoorHeader",
			Size = Vector3.new(doorWidth, h - doorHeight, wallThick),
			Position = center + Vector3.new(0, doorHeight + (h - doorHeight) / 2, zOffset),
			Color = wallColor,
			Material = Enum.Material.Concrete,
			Parent = m,
		})
	end

	local function buildWallWithDoorZ(xOffset: number, hasDoor: boolean)
		if not hasDoor then
			CityUtils.makePart({
				Name = "Wall",
				Size = Vector3.new(wallThick, h, size.Z),
				Position = center + Vector3.new(xOffset, h / 2, 0),
				Color = wallColor,
				Material = Enum.Material.Concrete,
				Parent = m,
			})
			return
		end
		local sideZ = (size.Z - doorWidth) / 2
		for _, signZ in ipairs({ -1, 1 }) do
			local zPos = signZ * (doorWidth / 2 + sideZ / 2)
			CityUtils.makePart({
				Name = "SideLowWall",
				Size = Vector3.new(wallThick, 2.2, sideZ),
				Position = center + Vector3.new(xOffset, 1.1, zPos),
				Color = wallColor,
				Material = Enum.Material.Concrete,
				Parent = m,
			})
			CityUtils.makePart({
				Name = "SideShowWindow",
				Size = Vector3.new(0.35, doorHeight - 2.2, sideZ - 1.2),
				Position = center + Vector3.new(xOffset, 2.2 + (doorHeight - 2.2) / 2, zPos),
				Color = Color3.fromRGB(165, 220, 245),
				Material = Enum.Material.Glass,
				Transparency = 0.45,
				Parent = m,
			})
			CityUtils.makePart({
				Name = "SideUpperWall",
				Size = Vector3.new(wallThick, h - doorHeight, sideZ),
				Position = center + Vector3.new(xOffset, doorHeight + (h - doorHeight) / 2, zPos),
				Color = wallColor,
				Material = Enum.Material.Concrete,
				Parent = m,
			})
		end
		CityUtils.makePart({
			Name = "DoorHeader",
			Size = Vector3.new(wallThick, h - doorHeight, doorWidth),
			Position = center + Vector3.new(xOffset, doorHeight + (h - doorHeight) / 2, 0),
			Color = wallColor,
			Material = Enum.Material.Concrete,
			Parent = m,
		})
	end

	buildWallWithDoorX(halfZ - wallThick / 2, doorSide == "South")
	buildWallWithDoorX(-halfZ + wallThick / 2, doorSide == "North")
	buildWallWithDoorZ(-halfX + wallThick / 2, doorSide == "West")
	buildWallWithDoorZ(halfX - wallThick / 2, doorSide == "East")

	return m
end

-- Helper trang trí các tầng cao ốc có dải cửa sổ phát sáng về đêm
local function addTowerUpperFloors(
	parent: Instance,
	baseCenter: Vector3,
	widthX: number,
	widthZ: number,
	floors: number,
	floorHeight: number,
	facadeColor: Color3,
	windowColor: Color3,
	neonAccent: Color3
): number
	for f = 1, floors do
		local yMid = baseCenter.Y + (f - 0.5) * floorHeight
		CityUtils.makePart({
			Name = "TowerCore_F" .. tostring(f),
			Size = Vector3.new(widthX - 1.2, floorHeight - 0.8, widthZ - 1.2),
			Position = Vector3.new(baseCenter.X, yMid, baseCenter.Z),
			Color = facadeColor,
			Material = Enum.Material.Concrete,
			Parent = parent,
		})
		local winBand = CityUtils.makePart({
			Name = "WindowBand_F" .. tostring(f),
			Size = Vector3.new(widthX, floorHeight * 0.58, widthZ),
			Position = Vector3.new(baseCenter.X, yMid + 0.3, baseCenter.Z),
			Color = windowColor,
			Material = Enum.Material.Glass,
			Reflectance = 0.2,
			Parent = parent,
		})
		CollectionService:AddTag(winBand, CityConfig.WindowGlowTag)

		CityUtils.makePart({
			Name = "FloorLedge_F" .. tostring(f),
			Size = Vector3.new(widthX + 0.8, 0.7, widthZ + 0.8),
			Position = Vector3.new(baseCenter.X, baseCenter.Y + f * floorHeight, baseCenter.Z),
			Color = facadeColor:Lerp(Color3.new(1, 1, 1), 0.15),
			Material = Enum.Material.SmoothPlastic,
			Parent = parent,
		})
	end

	local totalH = floors * floorHeight
	-- 4 dải đèn kiến trúc dọc 4 góc tòa tháp
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			CityUtils.makePart({
				Name = "CornerNeonFin",
				Size = Vector3.new(0.85, totalH, 0.85),
				Position = Vector3.new(
					baseCenter.X + sx * (widthX / 2 + 0.3),
					baseCenter.Y + totalH / 2,
					baseCenter.Z + sz * (widthZ / 2 + 0.3)
				),
				Color = neonAccent,
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = parent,
			})
		end
	end

	return baseCenter.Y + totalH
end

function Buildings.build(cityRoot: Instance)
	local bFolder = Instance.new("Folder")
	bFolder.Name = "CityBuildings"
	bFolder.Parent = cityRoot

	-- ========================================================================
	-- 1. KHU TÀI CHÍNH (BLOCK NW): THÁP SKYTOWER + NGÂN HÀNG NEO BANK
	-- ========================================================================
	-- 1A. Tháp SkyTower (tầng trệt mở + thang máy lên sân thượng Helipad + Bệ Phóng Bay)
	local skyCenter = Vector3.new(-92, 1.2, -92)
	local skyLobby = buildStorefrontShell(
		bFolder,
		"SkyTower",
		skyCenter,
		Vector3.new(48, 16, 48),
		Color3.fromRGB(36, 44, 62),
		Color3.fromRGB(24, 30, 44),
		"South"
	)

	local roofY = addTowerUpperFloors(
		skyLobby,
		skyCenter + Vector3.new(0, 17.2, 0),
		42,
		42,
		6,
		13,
		Color3.fromRGB(34, 42, 58),
		Color3.fromRGB(95, 175, 235),
		Color3.fromRGB(56, 189, 248)
	)

	CityUtils.makeSignBoard(
		skyLobby,
		skyCenter + Vector3.new(0, 14, 24.4),
		Vector3.new(0, 0, 1),
		Vector2.new(26, 3.8),
		"SKYTOWER PLAZA",
		"Tầng Thượng Ngắm Cảnh & Sân Đáp Trực Thăng",
		Color3.fromRGB(15, 23, 42),
		Color3.fromRGB(56, 189, 248)
	)

	-- Thang máy ở sảnh tầng trệt
	local elevGround = CityUtils.makePart({
		Name = "SkyTowerElevator_Ground",
		Size = Vector3.new(6, 10, 1.4),
		Position = skyCenter + Vector3.new(0, 5.2, -21),
		Color = Color3.fromRGB(56, 189, 248),
		Material = Enum.Material.Neon,
		Parent = skyLobby,
	})
	CityUtils.addPrompt(
		elevGround,
		"UseElevator",
		"Đi thang máy lên Sân Thượng (Tầng 7)",
		"Thang Máy SkyTower",
		12,
		{
			DestX = skyCenter.X,
			DestY = roofY + 4,
			DestZ = skyCenter.Z + 12,
			Label = "Sân Thượng SkyTower",
		}
	)

	-- Sân thượng Helipad + Lan can kính + Thang máy xuống + Bệ phóng bay lượn
	CityUtils.makePart({
		Name = "HelipadCircle",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.35, 24, 24),
		CFrame = CFrame.new(skyCenter.X, roofY + 0.3, skyCenter.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(52, 58, 70),
		Material = Enum.Material.Asphalt,
		Parent = skyLobby,
	})
	-- Chữ H phát sáng trên Helipad
	for _, xH in ipairs({ -3.5, 3.5 }) do
		CityUtils.makePart({
			Name = "HelipadH",
			Size = Vector3.new(1.4, 0.15, 9),
			Position = Vector3.new(skyCenter.X + xH, roofY + 0.52, skyCenter.Z),
			Color = Color3.fromRGB(250, 204, 21),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = skyLobby,
		})
	end
	CityUtils.makePart({
		Name = "HelipadH_Cross",
		Size = Vector3.new(8.4, 0.15, 1.4),
		Position = Vector3.new(skyCenter.X, roofY + 0.52, skyCenter.Z),
		Color = Color3.fromRGB(250, 204, 21),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = skyLobby,
	})

	-- Lan can kính an toàn trên đỉnh tháp
	for _, rSpec in ipairs({
		{ s = Vector3.new(42, 3.4, 0.4), p = Vector3.new(0, 1.7, 21) },
		{ s = Vector3.new(42, 3.4, 0.4), p = Vector3.new(0, 1.7, -21) },
		{ s = Vector3.new(0.4, 3.4, 42), p = Vector3.new(21, 1.7, 0) },
		{ s = Vector3.new(0.4, 3.4, 42), p = Vector3.new(-21, 1.7, 0) },
	}) do
		CityUtils.makePart({
			Name = "RoofGlassRail",
			Size = rSpec.s,
			Position = Vector3.new(skyCenter.X, roofY, skyCenter.Z) + rSpec.p,
			Color = Color3.fromRGB(165, 230, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.5,
			Parent = skyLobby,
		})
	end

	local elevRoof = CityUtils.makePart({
		Name = "SkyTowerElevator_Roof",
		Size = Vector3.new(5, 7, 2),
		Position = Vector3.new(skyCenter.X, roofY + 3.5, skyCenter.Z - 17),
		Color = Color3.fromRGB(56, 189, 248),
		Material = Enum.Material.Neon,
		Parent = skyLobby,
	})
	CityUtils.addPrompt(
		elevRoof,
		"UseElevator",
		"Đi thang máy xuống Sảnh Tầng Trệt",
		"Thang Máy SkyTower",
		12,
		{
			DestX = skyCenter.X,
			DestY = 4.5,
			DestZ = skyCenter.Z + 16,
			Label = "Sảnh Trệt SkyTower",
		}
	)

	-- Bệ phóng lượn ngắm toàn cảnh thành phố trên mép Đông-Nam sân thượng
	local skyPad = CityUtils.makePart({
		Name = "SkyGliderPad",
		Size = Vector3.new(6, 0.6, 6),
		Position = Vector3.new(skyCenter.X + 15, roofY + 0.4, skyCenter.Z + 15),
		Color = Color3.fromRGB(168, 85, 247),
		Material = Enum.Material.Neon,
		Parent = skyLobby,
	})
	CityUtils.addPrompt(
		skyPad,
		"SkyLaunch",
		"Bật nhảy Dù Lượn Ngắm Thành Phố!",
		"Bệ Phóng Không Trung",
		11
	)

	-- Điểm nhận hàng SkyTower
	local skyDrop = CityUtils.makePart({
		Name = "DeliveryPoint_SkyTowerLobby",
		Size = Vector3.new(3.5, 3.2, 3.5),
		Position = Vector3.new(-68, 2.8, -68),
		Color = Color3.fromRGB(56, 189, 248),
		Material = Enum.Material.Metal,
		Parent = skyLobby,
	})
	CityUtils.addPrompt(skyDrop, "DeliverOrder", "Giao đơn hàng tại đây", "Sảnh SkyTower", 13, {
		TargetId = "SkyTowerLobby",
	})

	-- 1B. Ngân hàng NEO BANK & Cây ATM
	local bankCenter = Vector3.new(-42, 1.2, -44)
	local bankModel = buildStorefrontShell(
		bFolder,
		"NeoBank",
		bankCenter,
		Vector3.new(34, 15, 30),
		Color3.fromRGB(235, 240, 246),
		Color3.fromRGB(16, 185, 129),
		"South"
	)
	CityUtils.makeSignBoard(
		bankModel,
		bankCenter + Vector3.new(0, 13.2, 15.4),
		Vector3.new(0, 0, 1),
		Vector2.new(22, 3.2),
		"NEO BANK 24/7",
		"Ngân Hàng Trung Tâm • ATM Trợ Cấp Công Dân",
		Color3.fromRGB(12, 42, 36),
		Color3.fromRGB(52, 211, 153)
	)

	-- Quầy giao dịch bên trong ngân hàng
	CityUtils.makePart({
		Name = "TellerCounter",
		Size = Vector3.new(18, 3.8, 2.6),
		Position = bankCenter + Vector3.new(0, 1.9, -6),
		Color = Color3.fromRGB(30, 58, 52),
		Material = Enum.Material.Marble,
		Parent = bankModel,
	})

	-- 2 Cây ATM bên ngoài cửa ngân hàng
	for idx, xAtm in ipairs({ -11, 11 }) do
		local atm = CityUtils.makePart({
			Name = "ATM_" .. tostring(idx),
			Size = Vector3.new(3.2, 6.2, 2.2),
			Position = bankCenter + Vector3.new(xAtm, 3.1, 16.2),
			Color = Color3.fromRGB(22, 38, 48),
			Material = Enum.Material.Metal,
			Parent = bankModel,
		})
		CityUtils.makePart({
			Name = "ATMScreen",
			Size = Vector3.new(2.2, 1.8, 0.15),
			Position = atm.Position + Vector3.new(0, 1.0, 1.08),
			Color = Color3.fromRGB(52, 211, 153),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = bankModel,
		})
		CityUtils.addPrompt(atm, "UseATM", "Rút trợ cấp công dân (+$150)", "Cây ATM Neo Bank", 10)
	end

	local bankDrop = CityUtils.makePart({
		Name = "DeliveryPoint_NeoBank",
		Size = Vector3.new(3.2, 3.0, 3.2),
		Position = Vector3.new(-42, 2.7, -25),
		Color = Color3.fromRGB(52, 211, 153),
		Material = Enum.Material.Metal,
		Parent = bankModel,
	})
	CityUtils.addPrompt(bankDrop, "DeliverOrder", "Giao đơn hàng tại đây", "Ngân Hàng Neo Bank", 13, {
		TargetId = "NeoBank",
	})

	-- ========================================================================
	-- 2. PHỐ ẨM THỰC & THƯƠNG MẠI (BLOCK NE): CAFE + PIZZA 24/7 + CHUNG CƯ VIP
	-- ========================================================================
	-- 2A. Quán Cà Phê "SAIGON CHILL COFFEE"
	local cafeCenter = Vector3.new(46, 1.2, -44)
	local cafeModel = buildStorefrontShell(
		bFolder,
		"SaigonChillCoffee",
		cafeCenter,
		Vector3.new(34, 13.5, 28),
		Color3.fromRGB(168, 118, 82),
		Color3.fromRGB(92, 58, 38),
		"South"
	)
	CityUtils.makeSignBoard(
		cafeModel,
		cafeCenter + Vector3.new(0, 12.2, 14.4),
		Vector3.new(0, 0, 1),
		Vector2.new(24, 3.2),
		"SAIGON CHILL COFFEE",
		"Cà Phê Sữa Đá • Trà Đào Tăng Tốc",
		Color3.fromRGB(54, 32, 20),
		Color3.fromRGB(251, 191, 36)
	)

	-- Mái hiên sọc ấm cúng trước quán
	CityUtils.makePart({
		Name = "CafeAwning",
		Size = Vector3.new(32, 0.6, 6.5),
		CFrame = CFrame.new(cafeCenter + Vector3.new(0, 9.6, 17)) * CFrame.Angles(math.rad(12), 0, 0),
		Color = Color3.fromRGB(194, 65, 45),
		Material = Enum.Material.Fabric,
		Parent = cafeModel,
	})

	-- Quầy pha chế bên trong quán + 2 máy order đồ uống thực tế
	local barCounter = CityUtils.makePart({
		Name = "CoffeeBarCounter",
		Size = Vector3.new(20, 3.6, 3.0),
		Position = cafeCenter + Vector3.new(0, 1.8, -5.5),
		Color = Color3.fromRGB(115, 72, 44),
		Material = Enum.Material.WoodPlanks,
		Parent = cafeModel,
	})

	local coffeeStation = CityUtils.makePart({
		Name = "EspressoMachine",
		Size = Vector3.new(3.2, 2.2, 2.0),
		Position = barCounter.Position + Vector3.new(-4.5, 2.9, 0),
		Color = Color3.fromRGB(185, 48, 48),
		Material = Enum.Material.Metal,
		Parent = cafeModel,
	})
	CityUtils.addPrompt(
		coffeeStation,
		"BuyItem",
		"Mua Cà Phê Sữa Đá ($25)",
		"Quầy Pha Chế Saigon Chill",
		11,
		{ ItemId = "CaPheSuaDa" }
	)

	local teaStation = CityUtils.makePart({
		Name = "PeachTeaDispenser",
		Size = Vector3.new(2.8, 2.4, 1.8),
		Position = barCounter.Position + Vector3.new(4.5, 3.0, 0),
		Color = Color3.fromRGB(245, 158, 11),
		Material = Enum.Material.Glass,
		Parent = cafeModel,
	})
	CityUtils.addPrompt(
		teaStation,
		"BuyItem",
		"Mua Trà Đào Cam Sả ($30)",
		"Quầy Trà Trái Cây",
		11,
		{ ItemId = "TraDaoCamSa" }
	)

	-- Bàn ghế sân hiên trước quán Cafe (ngồi được thật!)
	for _, xTbl in ipairs({ -9, 9 }) do
		local tblCenter = cafeCenter + Vector3.new(xTbl, 0, 20)
		CityUtils.makePart({
			Name = "PatioTableTop",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.35, 4.4, 4.4),
			CFrame = CFrame.new(tblCenter + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(238, 232, 220),
			Material = Enum.Material.Marble,
			Parent = cafeModel,
		})
		CityUtils.makePart({
			Name = "PatioTableLeg",
			Size = Vector3.new(0.5, 2.6, 0.5),
			Position = tblCenter + Vector3.new(0, 1.3, 0),
			Color = Color3.fromRGB(45, 48, 55),
			Material = Enum.Material.Metal,
			Parent = cafeModel,
		})
		for _, chairX in ipairs({ -3.2, 3.2 }) do
			local seat = Instance.new("Seat")
			seat.Name = "CafeChairSeat"
			seat.Anchored = true
			seat.Size = Vector3.new(1.8, 0.4, 1.8)
			seat.Color = Color3.fromRGB(135, 86, 52)
			seat.Material = Enum.Material.Wood
			seat.CFrame = CFrame.lookAt(
				tblCenter + Vector3.new(chairX, 1.6, 0),
				tblCenter + Vector3.new(0, 1.6, 0)
			)
			seat.Parent = cafeModel
		end
	end

	-- 2B. Tiệm Bánh & Siêu Thị 24/7 "PIZZA HOT & MART" (Nhận Việc Giao Hàng!)
	local pizzaCenter = Vector3.new(102, 1.2, -44)
	local pizzaModel = buildStorefrontShell(
		bFolder,
		"PizzaHotAndMart",
		pizzaCenter,
		Vector3.new(38, 14, 28),
		Color3.fromRGB(242, 238, 230),
		Color3.fromRGB(220, 38, 38),
		"South"
	)
	CityUtils.makeSignBoard(
		pizzaModel,
		pizzaCenter + Vector3.new(0, 12.6, 14.4),
		Vector3.new(0, 0, 1),
		Vector2.new(26, 3.2),
		"PIZZA HOT & 24/7 MART",
		"Nhận Việc Giao Hàng Kiếm Tiền • Nước Tăng Lực",
		Color3.fromRGB(68, 16, 16),
		Color3.fromRGB(251, 146, 60)
	)

	local jobDesk = CityUtils.makePart({
		Name = "DeliveryJobCounter",
		Size = Vector3.new(12, 3.8, 2.8),
		Position = pizzaCenter + Vector3.new(-6, 1.9, -5),
		Color = Color3.fromRGB(220, 38, 38),
		Material = Enum.Material.SmoothPlastic,
		Parent = pizzaModel,
	})
	-- Hộp bánh Pizza nóng trên quầy
	local pizzaBox = CityUtils.makePart({
		Name = "HotPizzaStack",
		Size = Vector3.new(3.2, 1.4, 3.2),
		Position = jobDesk.Position + Vector3.new(0, 2.6, 0),
		Color = Color3.fromRGB(245, 158, 11),
		Material = Enum.Material.SmoothPlastic,
		Parent = pizzaModel,
	})
	CityUtils.addPrompt(
		pizzaBox,
		"StartDelivery",
		"Nhận đơn Giao Bánh Pizza (+$80 ~ $120)",
		"Quầy Giao Hàng Pizza Hot",
		12
	)

	-- Tủ lạnh Nước Tăng Lực Neon bên phải cửa hàng
	local energyFridge = CityUtils.makePart({
		Name = "NeonEnergyFridge",
		Size = Vector3.new(5.5, 7.5, 2.4),
		Position = pizzaCenter + Vector3.new(11, 3.75, -8),
		Color = Color3.fromRGB(14, 165, 233),
		Material = Enum.Material.Neon,
		Parent = pizzaModel,
	})
	CityUtils.addPrompt(
		energyFridge,
		"BuyItem",
		"Mua Nước Tăng Lực Neon ($45)",
		"Tủ Lạnh 24/7 Mart",
		11,
		{ ItemId = "NuocTangLuc" }
	)

	-- 2C. Chung Cư Cao Cấp "LUMINA RESIDENCE" (Có Căn Hộ Tầng Trệt Cửa & Đèn Tương Tác!)
	local aptCenter = Vector3.new(76, 1.2, -104)
	local aptModel = buildStorefrontShell(
		bFolder,
		"LuminaResidence",
		aptCenter,
		Vector3.new(68, 14, 32),
		Color3.fromRGB(226, 232, 240),
		Color3.fromRGB(51, 65, 85),
		"South"
	)
	addTowerUpperFloors(
		aptModel,
		aptCenter + Vector3.new(0, 15.2, 0),
		62,
		28,
		4,
		11,
		Color3.fromRGB(215, 222, 232),
		Color3.fromRGB(253, 224, 142),
		Color3.fromRGB(250, 204, 21)
	)
	CityUtils.makeSignBoard(
		aptModel,
		aptCenter + Vector3.new(0, 12.6, 16.4),
		Vector3.new(0, 0, 1),
		Vector2.new(26, 3.0),
		"LUMINA RESIDENCE",
		"Căn Hộ Thông Minh — Mở Cửa & Đổi Đèn Phòng",
		Color3.fromRGB(30, 41, 59),
		Color3.fromRGB(250, 204, 21)
	)

	-- Cửa kính thông minh đóng/mở được ở lối vào căn hộ
	local smartDoor = CityUtils.makePart({
		Name = "SmartApartmentDoor",
		Size = Vector3.new(8.8, 9.2, 0.5),
		Position = aptCenter + Vector3.new(0, 4.6, 15.4),
		Color = Color3.fromRGB(56, 189, 248),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
		Parent = aptModel,
	})
	smartDoor:SetAttribute("ClosedPos", smartDoor.Position)
	smartDoor:SetAttribute("IsOpen", false)
	CityUtils.addPrompt(smartDoor, "ToggleDoor", "Đóng / Mở Cửa Thông Minh", "Căn Hộ Lumina", 11)

	-- Sofa & Công tắc đèn thông minh RGB trong phòng khách căn hộ
	CityUtils.buildBench(aptModel, aptCenter + Vector3.new(-14, 0.2, -6), Vector3.new(0, 0, 1))
	local smartSwitch = CityUtils.makePart({
		Name = "ApartmentLightSwitch",
		Size = Vector3.new(1.8, 2.4, 0.5),
		Position = aptCenter + Vector3.new(12, 4.5, -14.8),
		Color = Color3.fromRGB(250, 204, 21),
		Material = Enum.Material.Neon,
		Parent = aptModel,
	})
	CityUtils.addPrompt(
		smartSwitch,
		"ToggleAptLight",
		"Đổi chế độ đèn Căn Hộ (Ấm / Tím Chill / Xanh Neon)",
		"Công Tắc Nhà Thông Minh",
		11
	)

	local aptDrop = CityUtils.makePart({
		Name = "DeliveryPoint_VipApartment",
		Size = Vector3.new(3.2, 3.0, 3.2),
		Position = Vector3.new(82, 2.7, -84),
		Color = Color3.fromRGB(250, 204, 21),
		Material = Enum.Material.Metal,
		Parent = aptModel,
	})
	CityUtils.addPrompt(aptDrop, "DeliverOrder", "Giao đơn hàng tại đây", "Sảnh Chung Cư Lumina", 13, {
		TargetId = "VipApartment",
	})

	-- ========================================================================
	-- 3. KHU GIẢI TRÍ & SHOWROOM XE (BLOCK SE): CYBER ARCADE + AUTO GARAGE
	-- ========================================================================
	-- 3A. Trung Tâm Giải Trí "CYBER ARCADE"
	local arcadeCenter = Vector3.new(50, 1.2, 52)
	local arcadeModel = buildStorefrontShell(
		bFolder,
		"CyberArcade",
		arcadeCenter,
		Vector3.new(38, 15, 34),
		Color3.fromRGB(22, 24, 38),
		Color3.fromRGB(217, 70, 239),
		"North"
	)
	CityUtils.makeSignBoard(
		arcadeModel,
		arcadeCenter + Vector3.new(0, 13.2, -17.4),
		Vector3.new(0, 0, -1),
		Vector2.new(25, 3.4),
		"CYBER ARCADE CLUB",
		"Mini-Game Vòng Quay May Mắn & Hào Quang Neon",
		Color3.fromRGB(28, 12, 46),
		Color3.fromRGB(232, 121, 249)
	)

	-- 3 Máy chơi game thùng phát sáng bên trong Cyber Arcade
	local cabinetColors = {
		Color3.fromRGB(236, 72, 153),
		Color3.fromRGB(34, 211, 238),
		Color3.fromRGB(168, 85, 247),
	}
	for idx, cCol in ipairs(cabinetColors) do
		local xCab = (idx - 2) * 8
		local cab = CityUtils.makePart({
			Name = "ArcadeCabinet_" .. tostring(idx),
			Size = Vector3.new(4.2, 7.2, 3.6),
			Position = arcadeCenter + Vector3.new(xCab, 3.6, 8),
			Color = Color3.fromRGB(30, 32, 48),
			Material = Enum.Material.Metal,
			Parent = arcadeModel,
		})
		CityUtils.makePart({
			Name = "ArcadeScreen",
			Size = Vector3.new(3.4, 2.8, 0.2),
			Position = cab.Position + Vector3.new(0, 1.2, -1.75),
			Color = cCol,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = arcadeModel,
		})
		CityUtils.addPrompt(
			cab,
			"PlayArcade",
			"Chơi Máy Arcade ($20 — Trúng Thưởng & Hào Quang!)",
			"Máy Arcade #" .. tostring(idx),
			10
		)
	end

	local arcadeDrop = CityUtils.makePart({
		Name = "DeliveryPoint_CyberArcade",
		Size = Vector3.new(3.2, 3.0, 3.2),
		Position = Vector3.new(54, 2.7, 30),
		Color = Color3.fromRGB(232, 121, 249),
		Material = Enum.Material.Metal,
		Parent = arcadeModel,
	})
	CityUtils.addPrompt(arcadeDrop, "DeliverOrder", "Giao đơn hàng tại đây", "Cyber Arcade Club", 13, {
		TargetId = "CyberArcade",
	})

	-- 3B. Showroom & Garage Gọi Xe "AUTO METRO GARAGE"
	local garageCenter = Vector3.new(102, 1.2, 92)
	local garageModel = buildStorefrontShell(
		bFolder,
		"AutoMetroGarage",
		garageCenter,
		Vector3.new(44, 15, 44),
		Color3.fromRGB(40, 48, 62),
		Color3.fromRGB(249, 115, 22),
		"North"
	)
	CityUtils.makeSignBoard(
		garageModel,
		garageCenter + Vector3.new(0, 13.2, -22.4),
		Vector3.new(0, 0, -1),
		Vector2.new(28, 3.4),
		"AUTO METRO GARAGE",
		"Gọi Xe Thể Thao Miễn Phí — Lái Dạo Quanh Thành Phố",
		Color3.fromRGB(36, 22, 14),
		Color3.fromRGB(251, 146, 60)
	)

	-- 2 Trạm Gọi Xe Miễn Phí (Xe Đỏ Thể Thao & Siêu Xe Xanh Neon)
	local carKioskRed = CityUtils.makePart({
		Name = "SpawnCarKiosk_Red",
		Size = Vector3.new(3.6, 5.6, 2.0),
		Position = garageCenter + Vector3.new(-10, 2.8, -24.5),
		Color = Color3.fromRGB(220, 38, 38),
		Material = Enum.Material.Metal,
		Parent = garageModel,
	})
	CityUtils.addPrompt(
		carKioskRed,
		"SpawnVehicle",
		"Gọi Xe Thể Thao Đỏ (Miễn phí)",
		"Trạm Gọi Xe Auto Metro",
		12,
		{ CarStyle = "RedSport" }
	)

	local carKioskCyan = CityUtils.makePart({
		Name = "SpawnCarKiosk_Cyan",
		Size = Vector3.new(3.6, 5.6, 2.0),
		Position = garageCenter + Vector3.new(10, 2.8, -24.5),
		Color = Color3.fromRGB(14, 165, 233),
		Material = Enum.Material.Metal,
		Parent = garageModel,
	})
	CityUtils.addPrompt(
		carKioskCyan,
		"SpawnVehicle",
		"Gọi Siêu Xe Cyber Xanh (Miễn phí)",
		"Trạm Gọi Xe Auto Metro",
		12,
		{ CarStyle = "CyanCyber" }
	)

	local garageDrop = CityUtils.makePart({
		Name = "DeliveryPoint_AutoGarage",
		Size = Vector3.new(3.2, 3.0, 3.2),
		Position = Vector3.new(96, 2.7, 64),
		Color = Color3.fromRGB(251, 146, 60),
		Material = Enum.Material.Metal,
		Parent = garageModel,
	})
	CityUtils.addPrompt(garageDrop, "DeliverOrder", "Giao đơn hàng tại đây", "Auto Metro Garage", 13, {
		TargetId = "AutoGarage",
	})

	-- ========================================================================
	-- 4. CÁC CÔNG TRÌNH NGOẠI VI: TRẠM XĂNG + BỆNH VIỆN + ĐƯỜNG CHÂN TRỜI BẮC
	-- ========================================================================
	-- 4A. Trạm Xăng Phía Tây "PETRO METRO" (X = -196, Z = -36)
	local gasModel = Instance.new("Model")
	gasModel.Name = "PetroMetroStation"
	gasModel.Parent = bFolder

	CityUtils.makePart({
		Name = "GasCanopyRoof",
		Size = Vector3.new(36, 1.8, 44),
		Position = Vector3.new(-192, 16.5, -36),
		Color = Color3.fromRGB(239, 68, 68),
		Material = Enum.Material.SmoothPlastic,
		Parent = gasModel,
	})
	CityUtils.makeSignBoard(
		gasModel,
		Vector3.new(-173.6, 16.5, -36),
		Vector3.new(1, 0, 0),
		Vector2.new(32, 2.6),
		"TRẠM XĂNG PETRO METRO",
		"Tiếp nhiên liệu Nitro Tăng Tốc",
		Color3.fromRGB(68, 14, 14),
		Color3.fromRGB(253, 224, 71)
	)
	for _, zP in ipairs({ -50, -22 }) do
		for _, xP in ipairs({ -204, -180 }) do
			CityUtils.makePart({
				Name = "CanopyPillar",
				Size = Vector3.new(2, 15.5, 2),
				Position = Vector3.new(xP, 8.8, zP),
				Color = Color3.fromRGB(226, 232, 240),
				Material = Enum.Material.Metal,
				Parent = gasModel,
			})
		end
		local pump = CityUtils.makePart({
			Name = "FuelPump",
			Size = Vector3.new(2.8, 6.2, 4.2),
			Position = Vector3.new(-192, 4.3, zP),
			Color = Color3.fromRGB(220, 38, 38),
			Material = Enum.Material.Metal,
			Parent = gasModel,
		})
		CityUtils.addPrompt(
			pump,
			"NitroBoost",
			"Nạp Nhiên Liệu Nitro Tăng Tốc!",
			"Trụ Bơm Petro Metro",
			14
		)
	end

	-- 4B. Bệnh Viện Đa Khoa Phía Đông "METRO MEDICAL" (X = +196, Z = -36)
	local hospCenter = Vector3.new(196, 1.2, -36)
	local hospModel = buildStorefrontShell(
		bFolder,
		"MetroMedicalCenter",
		hospCenter,
		Vector3.new(44, 15, 52),
		Color3.fromRGB(244, 247, 252),
		Color3.fromRGB(14, 165, 233),
		"West"
	)
	addTowerUpperFloors(
		hospModel,
		hospCenter + Vector3.new(0, 16.2, 0),
		38,
		44,
		2,
		11,
		Color3.fromRGB(240, 245, 250),
		Color3.fromRGB(147, 197, 253),
		Color3.fromRGB(56, 189, 248)
	)
	CityUtils.makeSignBoard(
		hospModel,
		hospCenter + Vector3.new(-22.4, 13.2, 0),
		Vector3.new(-1, 0, 0),
		Vector2.new(30, 3.2),
		"✚ BỆNH VIỆN METRO",
		"Trạm Hồi Phục Sức Khoẻ & Năng Lượng Miễn Phí",
		Color3.fromRGB(15, 36, 58),
		Color3.fromRGB(56, 189, 248)
	)
	local healPad = CityUtils.makePart({
		Name = "MedicalHealPad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 8, 8),
		CFrame = CFrame.new(hospCenter + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(52, 211, 153),
		Material = Enum.Material.Neon,
		Parent = hospModel,
	})
	CityUtils.addPrompt(healPad, "HealPlayer", "Hồi đầy 100% Máu & Thể Lực", "Trạm Y Tế Metro", 12)

	-- 4C. Cụm 3 Tòa Tháp Đường Chân Trời Phía Bắc (Z = -196)
	local skylineSpecs = {
		{
			name = "NorthTower_Alpha",
			x = -105,
			floors = 7,
			facade = Color3.fromRGB(44, 52, 68),
			win = Color3.fromRGB(125, 211, 252),
			neon = Color3.fromRGB(56, 189, 248),
		},
		{
			name = "NorthTower_Zenith",
			x = 0,
			floors = 9,
			facade = Color3.fromRGB(38, 40, 56),
			win = Color3.fromRGB(196, 181, 253),
			neon = Color3.fromRGB(168, 85, 247),
		},
		{
			name = "NorthTower_Solaris",
			x = 105,
			floors = 6,
			facade = Color3.fromRGB(52, 58, 66),
			win = Color3.fromRGB(253, 230, 138),
			neon = Color3.fromRGB(251, 191, 36),
		},
	}
	for _, st in ipairs(skylineSpecs) do
		local towerM = Instance.new("Model")
		towerM.Name = st.name
		towerM.Parent = bFolder
		addTowerUpperFloors(
			towerM,
			Vector3.new(st.x, 1.2, -196),
			44,
			40,
			st.floors,
			12,
			st.facade,
			st.win,
			st.neon
		)
	end
end

return Buildings
