--!strict
--[[
	VehicleBuilder.luau (v2 — Taller Profile + Full Cockpit Interior + Hinged Doors)
	Hệ thống lắp ráp Xe Hơi GTA V (Los Santos) theo cấu trúc Module Ghép Khối:
	- Dáng xe cao thoáng chuẩn tỉ lệ nhân vật Roblox (trần xe cao ~5.65 studs so với mặt đường, ngồi rộng rãi không đụng đầu).
	- Khoang nội thất siêu chi tiết (28+ chi tiết): Vô lăng thể thao 3 chấu + lẫy chuyển số + trục lái, chân ga/phanh,
	  bảng đồng hồ tốc độ/tua máy phát sáng, màn hình giải trí trung tâm GPS, 4 cửa gió điều hoà, hộc đồ phụ,
	  bệ tì tay trung tâm + cần số bọc da núm đỏ + phanh tay + khay ly, ghế đua 2 tông màu có gối tựa đầu thanh kim loại,
	  gương chiếu hậu trong xe + tấm che nắng + đèn trần ca-bin tự sáng khi mở cửa!
	- 2 Cánh cửa Trái/Phải gắn khớp bản lề thực (`Weld` tại mép trước cửa) kèm Táp-pi cửa trong, loa cửa, tay nắm,
	  gương chiếu hậu & kính cửa sổ để diễn hoạt mở cửa 64° mượt mà khi bấm [F] lên/xuống xe!
	- MỌI bộ phận vỏ ngoài & kính xe đều gắn MÁU ẨN (`PartHealth`) — xe đụng hoặc bị súng bắn cạn máu sẽ tự vỡ / bung rời!
]]

export type VehicleTrim = {
	id: string,
	modelName: string,
	style: "BansheeGT" | "GauntletGTX",
	bodyColor: Color3,
	stripeColor: Color3,
	interiorAccent: Color3,
	rimColor: Color3,
	maxSpeed: number,
}

local VehicleBuilder = {}

VehicleBuilder.PRESETS = {
	CrimsonBanshee = {
		id = "CrimsonBanshee",
		modelName = "Banshee GT",
		style = "BansheeGT" :: "BansheeGT",
		bodyColor = Color3.fromRGB(206, 28, 36),
		stripeColor = Color3.fromRGB(245, 247, 250),
		interiorAccent = Color3.fromRGB(214, 42, 48),
		rimColor = Color3.fromRGB(218, 224, 232),
		maxSpeed = 96,
	},
	ObsidianGauntlet = {
		id = "ObsidianGauntlet",
		modelName = "Gauntlet GTX",
		style = "GauntletGTX" :: "GauntletGTX",
		bodyColor = Color3.fromRGB(26, 29, 35),
		stripeColor = Color3.fromRGB(238, 186, 44),
		interiorAccent = Color3.fromRGB(234, 179, 8),
		rimColor = Color3.fromRGB(185, 152, 68),
		maxSpeed = 90,
	},
	MidnightBanshee = {
		id = "MidnightBanshee",
		modelName = "Banshee GT",
		style = "BansheeGT" :: "BansheeGT",
		bodyColor = Color3.fromRGB(24, 72, 168),
		stripeColor = Color3.fromRGB(242, 246, 252),
		interiorAccent = Color3.fromRGB(56, 189, 248),
		rimColor = Color3.fromRGB(216, 222, 230),
		maxSpeed = 96,
	},
	SunsetComet = {
		id = "SunsetComet",
		modelName = "Banshee GT",
		style = "BansheeGT" :: "BansheeGT",
		bodyColor = Color3.fromRGB(236, 118, 24),
		stripeColor = Color3.fromRGB(22, 24, 28),
		interiorAccent = Color3.fromRGB(249, 115, 22),
		rimColor = Color3.fromRGB(42, 46, 54),
		maxSpeed = 94,
	},
}

local function weldTo(root: BasePart, part: BasePart): WeldConstraint
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = part
	w.Parent = part
	return w
end

type CarPartSpec = {
	name: string,
	parent: Instance,
	chassis: BasePart,
	weldTarget: BasePart?,
	localCF: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	reflectance: number?,
	canCollide: boolean?,
	isWedge: boolean?,
	hp: number?,
	zone: string?,
}

local function makeCarPart(spec: CarPartSpec): BasePart
	local p: BasePart
	if spec.isWedge then
		local wp = Instance.new("WedgePart")
		wp.BottomSurface = Enum.SurfaceType.Smooth
		p = wp
	else
		local bp = Instance.new("Part")
		bp.TopSurface = Enum.SurfaceType.Smooth
		bp.BottomSurface = Enum.SurfaceType.Smooth
		p = bp
	end

	p.Name = spec.name
	p.Size = spec.size
	p.CFrame = spec.chassis.CFrame * spec.localCF
	p.Color = spec.color
	p.Material = spec.material or Enum.Material.SmoothPlastic
	p.Transparency = spec.transparency or 0
	p.Reflectance = spec.reflectance or 0
	p.Anchored = false
	p.CanCollide = if spec.canCollide ~= nil then spec.canCollide else false
	p.CanQuery = true
	p.Massless = true

	if spec.hp and spec.hp > 0 then
		local h = math.max(1, math.round(spec.hp))
		p:SetAttribute("Destructible", true)
		p:SetAttribute("VehiclePart", true)
		p:SetAttribute("DamageZone", spec.zone or "Body")
		p:SetAttribute("MaxPartHealth", h)
		p:SetAttribute("PartHealth", h)
		p:SetAttribute("MaxIntegrity", h)
		p:SetAttribute("Integrity", h)
	else
		p:SetAttribute("Destructible", false)
	end

	p.Parent = spec.parent
	weldTo(spec.weldTarget or spec.chassis, p)
	return p
end

function VehicleBuilder.spawn(parent: Instance, spawnCF: CFrame, trim: VehicleTrim): Model
	local car = Instance.new("Model")
	car.Name = trim.modelName
	car:SetAttribute("IsGtaVehicle", true)
	car:SetAttribute("VehicleDisplayName", trim.modelName)
	car:SetAttribute("MaxEngineHealth", 700)
	car:SetAttribute("EngineHealth", 700)
	car:SetAttribute("MaxSpeed", trim.maxSpeed)
	car:SetAttribute("CurrentMPH", 0)
	car.Parent = parent

	-- 1. KHUNG SƯỜN GẦM LÕI CAO THOÁNG (Chassis Y = +2.22 trên mặt đường; tổng chiều cao tới mui xe ~5.68 studs)
	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(6.5, 1.05, 14.8)
	chassis.CFrame = spawnCF * CFrame.new(0, 2.22, 0)
	chassis.Color = Color3.fromRGB(26, 28, 34)
	chassis.Material = Enum.Material.Metal
	chassis.TopSurface = Enum.SurfaceType.Smooth
	chassis.BottomSurface = Enum.SurfaceType.Smooth
	chassis.Anchored = false
	chassis.CanCollide = true
	chassis.CustomPhysicalProperties = PhysicalProperties.new(2.2, 0.35, 0.04, 1, 1)
	chassis:SetAttribute("Destructible", false)
	chassis.Parent = car
	car.PrimaryPart = chassis

	-- ========================================================================
	-- 2. NỘI THẤT KHOANG LÁI SIÊU CHI TIẾT (28+ BỘ PHẬN COCKPIT GTA V)
	-- ========================================================================
	local interiorFolder = Instance.new("Folder")
	interiorFolder.Name = "InteriorDetails"
	interiorFolder.Parent = car

	-- Thảm sàn nỉ tối màu + 2 Thảm lót chân viền thể thao + Vách sau ca-bin
	makeCarPart({
		name = "CabinCarpetFloor",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 0.34, 0.15),
		size = Vector3.new(5.95, 0.34, 6.55),
		color = Color3.fromRGB(28, 31, 38),
		material = Enum.Material.Fabric,
	})
	for _, sx in ipairs({ -1.52, 1.52 }) do
		makeCarPart({
			name = "SportFloorMat",
			parent = interiorFolder,
			chassis = chassis,
			localCF = CFrame.new(sx, 0.53, -1.05),
			size = Vector3.new(2.05, 0.05, 2.15),
			color = Color3.fromRGB(18, 20, 25),
			material = Enum.Material.Fabric,
		})
		makeCarPart({
			name = "FloorMatAccentStrip",
			parent = interiorFolder,
			chassis = chassis,
			localCF = CFrame.new(sx, 0.56, -2.02),
			size = Vector3.new(1.85, 0.04, 0.14),
			color = trim.interiorAccent,
		})
	end
	makeCarPart({
		name = "RearCabinBulkhead",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.52, 3.18),
		size = Vector3.new(5.85, 2.15, 0.36),
		color = Color3.fromRGB(25, 28, 34),
		material = Enum.Material.Fabric,
	})

	-- Yên ngựa trung tâm (Center Console) + Tì tay bọc da + Cần số thể thao + Phanh tay + Khay để cốc
	makeCarPart({
		name = "CenterTransmissionTunnel",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 0.84, -0.35),
		size = Vector3.new(0.96, 0.72, 4.85),
		color = Color3.fromRGB(30, 33, 40),
	})
	makeCarPart({
		name = "CenterLeatherArmrest",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.28, 0.88),
		size = Vector3.new(1.04, 0.28, 1.95),
		color = Color3.fromRGB(38, 42, 50),
		material = Enum.Material.Fabric,
	})
	makeCarPart({
		name = "ShifterGateBase",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.23, -1.08),
		size = Vector3.new(0.62, 0.08, 0.72),
		color = Color3.fromRGB(172, 178, 188),
		material = Enum.Material.Metal,
	})
	makeCarPart({
		name = "GearShiftStick",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.52, -1.06) * CFrame.Angles(math.rad(-12), 0, 0),
		size = Vector3.new(0.11, 0.56, 0.11),
		color = Color3.fromRGB(198, 204, 214),
		material = Enum.Material.Metal,
	})
	makeCarPart({
		name = "SportShiftKnob",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.82, -1.00),
		size = Vector3.new(0.24, 0.24, 0.24),
		color = trim.interiorAccent,
	})
	makeCarPart({
		name = "HandbrakeLever",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(-0.28, 1.36, -0.32) * CFrame.Angles(math.rad(24), 0, 0),
		size = Vector3.new(0.10, 0.12, 0.72),
		color = Color3.fromRGB(20, 22, 26),
	})
	for _, cz in ipairs({ -0.22, -0.58 }) do
		makeCarPart({
			name = "CupholderRing",
			parent = interiorFolder,
			chassis = chassis,
			localCF = CFrame.new(0.22, 1.22, cz),
			size = Vector3.new(0.28, 0.06, 0.28),
			color = Color3.fromRGB(14, 16, 20),
		})
	end

	-- Bảng Táp-lô điêu khắc đa tầng + Mái vòm đồng hồ + Màn hình GPS 8-inch + 4 Cửa gió điều hoà + Hộc đồ phụ
	makeCarPart({
		name = "DashboardMain",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.38, -2.42),
		size = Vector3.new(5.85, 1.16, 1.28),
		color = Color3.fromRGB(22, 25, 32),
	})
	makeCarPart({
		name = "DashboardAccentTrim",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.48, -1.77),
		size = Vector3.new(5.72, 0.08, 0.06),
		color = trim.interiorAccent,
	})
	makeCarPart({
		name = "GaugeBinnacleHood",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(-1.52, 2.02, -2.25),
		size = Vector3.new(1.78, 0.22, 0.92),
		color = Color3.fromRGB(18, 20, 26),
	})
	makeCarPart({
		name = "TachometerDialGlow",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(-1.90, 1.78, -1.78),
		size = Vector3.new(0.62, 0.42, 0.06),
		color = Color3.fromRGB(56, 189, 248),
		material = Enum.Material.Neon,
	})
	makeCarPart({
		name = "SpeedometerDialGlow",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(-1.14, 1.78, -1.78),
		size = Vector3.new(0.62, 0.42, 0.06),
		color = Color3.fromRGB(248, 250, 252),
		material = Enum.Material.Neon,
	})
	makeCarPart({
		name = "InfotainmentBezel",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0.15, 1.76, -1.76) * CFrame.Angles(math.rad(-8), math.rad(6), 0),
		size = Vector3.new(1.32, 0.74, 0.10),
		color = Color3.fromRGB(14, 16, 22),
	})
	makeCarPart({
		name = "InfotainmentGpsScreen",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0.15, 1.76, -1.70) * CFrame.Angles(math.rad(-8), math.rad(6), 0),
		size = Vector3.new(1.16, 0.58, 0.04),
		color = Color3.fromRGB(34, 148, 198),
		material = Enum.Material.Neon,
	})
	for _, vx in ipairs({ -2.52, -0.52, 0.98, 2.46 }) do
		makeCarPart({
			name = "DashACVent",
			parent = interiorFolder,
			chassis = chassis,
			localCF = CFrame.new(vx, 1.62, -1.77),
			size = Vector3.new(0.46, 0.22, 0.08),
			color = Color3.fromRGB(48, 54, 64),
			material = Enum.Material.Metal,
		})
	end
	makeCarPart({
		name = "PassengerGlovebox",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(1.68, 1.08, -1.78),
		size = Vector3.new(1.85, 0.56, 0.06),
		color = Color3.fromRGB(28, 32, 40),
	})
	makeCarPart({
		name = "GloveboxChromeLatch",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(1.68, 1.24, -1.74),
		size = Vector3.new(0.34, 0.08, 0.05),
		color = Color3.fromRGB(196, 202, 212),
		material = Enum.Material.Metal,
	})

	-- Vô lăng thể thao 3 chấu đáy phẳng + Trục lái + Lẫy chuyển số +/- + Chân ga & Chân phanh
	local steerCenter = CFrame.new(-1.52, 1.68, -1.32) * CFrame.Angles(math.rad(-20), 0, 0)
	makeCarPart({
		name = "SteeringColumn",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(-1.52, 1.60, -1.62) * CFrame.Angles(math.rad(-20), 0, 0),
		size = Vector3.new(0.32, 0.32, 0.68),
		color = Color3.fromRGB(26, 29, 36),
	})
	makeCarPart({
		name = "SteeringHub",
		parent = interiorFolder,
		chassis = chassis,
		localCF = steerCenter,
		size = Vector3.new(0.42, 0.42, 0.16),
		color = Color3.fromRGB(32, 36, 44),
	})
	-- Vành vô lăng ghép 4 cạnh + vạch đỏ 12 giờ + 3 nan chấu kim loại + 2 lẫy chuyển số
	makeCarPart({
		name = "SteeringRimTop",
		parent = interiorFolder,
		chassis = chassis,
		localCF = steerCenter * CFrame.new(0, 0.52, 0),
		size = Vector3.new(0.96, 0.14, 0.14),
		color = Color3.fromRGB(18, 20, 24),
	})
	makeCarPart({
		name = "SteeringTopMarker",
		parent = interiorFolder,
		chassis = chassis,
		localCF = steerCenter * CFrame.new(0, 0.52, 0),
		size = Vector3.new(0.14, 0.16, 0.16),
		color = trim.interiorAccent,
	})
	makeCarPart({
		name = "SteeringRimBottomFlat",
		parent = interiorFolder,
		chassis = chassis,
		localCF = steerCenter * CFrame.new(0, -0.48, 0),
		size = Vector3.new(0.92, 0.14, 0.14),
		color = Color3.fromRGB(18, 20, 24),
	})
	for _, sgn in ipairs({ -1, 1 }) do
		makeCarPart({
			name = "SteeringRimSide",
			parent = interiorFolder,
			chassis = chassis,
			localCF = steerCenter * CFrame.new(sgn * 0.48, 0.02, 0),
			size = Vector3.new(0.14, 0.98, 0.14),
			color = Color3.fromRGB(18, 20, 24),
		})
		makeCarPart({
			name = "SteeringSpokeSide",
			parent = interiorFolder,
			chassis = chassis,
			localCF = steerCenter * CFrame.new(sgn * 0.26, -0.04, 0),
			size = Vector3.new(0.42, 0.11, 0.10),
			color = Color3.fromRGB(182, 190, 200),
			material = Enum.Material.Metal,
		})
		makeCarPart({
			name = "PaddleShifter",
			parent = interiorFolder,
			chassis = chassis,
			localCF = steerCenter * CFrame.new(sgn * 0.34, 0.14, -0.10),
			size = Vector3.new(0.14, 0.34, 0.05),
			color = trim.interiorAccent,
			material = Enum.Material.Metal,
		})
	end
	makeCarPart({
		name = "SteeringSpokeBottom",
		parent = interiorFolder,
		chassis = chassis,
		localCF = steerCenter * CFrame.new(0, -0.26, 0),
		size = Vector3.new(0.13, 0.42, 0.10),
		color = Color3.fromRGB(182, 190, 200),
		material = Enum.Material.Metal,
	})

	-- Chân ga & chân phanh hợp kim dưới gầm ghế lái
	makeCarPart({
		name = "BrakePedal",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(-1.68, 0.78, -2.02) * CFrame.Angles(math.rad(32), 0, 0),
		size = Vector3.new(0.32, 0.22, 0.06),
		color = Color3.fromRGB(190, 196, 206),
		material = Enum.Material.Metal,
	})
	makeCarPart({
		name = "AcceleratorPedal",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(-1.24, 0.76, -2.06) * CFrame.Angles(math.rad(36), 0, 0),
		size = Vector3.new(0.18, 0.42, 0.06),
		color = Color3.fromRGB(190, 196, 206),
		material = Enum.Material.Metal,
	})

	-- Ghế lái chính thức (VehicleSeat) + Ghế phụ (Seat) + Đệm ôm hông 2 tông màu + Tựa đầu thanh crôm
	local driverSeat = Instance.new("VehicleSeat")
	driverSeat.Name = "DriverSeat"
	driverSeat.Size = Vector3.new(2.05, 0.48, 2.05)
	driverSeat.CFrame = chassis.CFrame * CFrame.new(-1.52, 0.72, 0.22)
	driverSeat.Color = Color3.fromRGB(26, 29, 36)
	driverSeat.Material = Enum.Material.Fabric
	driverSeat.MaxSpeed = trim.maxSpeed
	driverSeat.Torque = 0
	driverSeat.TurnSpeed = 0
	driverSeat.HeadsUpDisplay = false
	driverSeat.TopSurface = Enum.SurfaceType.Smooth
	driverSeat.BottomSurface = Enum.SurfaceType.Smooth
	driverSeat.Massless = true
	driverSeat:SetAttribute("Destructible", false)
	driverSeat.Parent = car
	weldTo(chassis, driverSeat)

	local passSeat = Instance.new("Seat")
	passSeat.Name = "PassengerSeat"
	passSeat.Size = Vector3.new(2.05, 0.48, 2.05)
	passSeat.CFrame = chassis.CFrame * CFrame.new(1.52, 0.72, 0.22)
	passSeat.Color = Color3.fromRGB(26, 29, 36)
	passSeat.Material = Enum.Material.Fabric
	passSeat.TopSurface = Enum.SurfaceType.Smooth
	passSeat.BottomSurface = Enum.SurfaceType.Smooth
	passSeat.Massless = true
	passSeat:SetAttribute("Destructible", false)
	passSeat.Parent = car
	weldTo(chassis, passSeat)

	for _, sx in ipairs({ -1.52, 1.52 }) do
		local backTilt = CFrame.new(sx, 1.68, 1.18) * CFrame.Angles(math.rad(-11), 0, 0)
		makeCarPart({
			name = "SportSeatBack",
			parent = interiorFolder,
			chassis = chassis,
			localCF = backTilt,
			size = Vector3.new(1.88, 1.88, 0.38),
			color = Color3.fromRGB(30, 34, 42),
			material = Enum.Material.Fabric,
		})
		makeCarPart({
			name = "SeatCenterInsert",
			parent = interiorFolder,
			chassis = chassis,
			localCF = backTilt * CFrame.new(0, 0.04, -0.17),
			size = Vector3.new(0.88, 1.48, 0.08),
			color = trim.interiorAccent,
			material = Enum.Material.Fabric,
		})
		for _, bs in ipairs({ -0.82, 0.82 }) do
			makeCarPart({
				name = "SeatSideBolster",
				parent = interiorFolder,
				chassis = chassis,
				localCF = backTilt * CFrame.new(bs, -0.06, -0.16),
				size = Vector3.new(0.32, 1.62, 0.28),
				color = Color3.fromRGB(22, 25, 32),
				material = Enum.Material.Fabric,
			})
		end
		for _, rx in ipairs({ -0.28, 0.28 }) do
			makeCarPart({
				name = "HeadrestChromeRod",
				parent = interiorFolder,
				chassis = chassis,
				localCF = backTilt * CFrame.new(rx, 1.04, 0),
				size = Vector3.new(0.08, 0.34, 0.08),
				color = Color3.fromRGB(196, 202, 212),
				material = Enum.Material.Metal,
			})
		end
		makeCarPart({
			name = "SeatHeadrest",
			parent = interiorFolder,
			chassis = chassis,
			localCF = backTilt * CFrame.new(0, 1.32, -0.04),
			size = Vector3.new(1.06, 0.56, 0.34),
			color = Color3.fromRGB(26, 29, 36),
			material = Enum.Material.Fabric,
		})
	end

	-- Gương chiếu hậu trong xe + 2 Tấm che nắng + Đèn trần ca-bin tự sáng khi mở cửa
	makeCarPart({
		name = "RearviewMirrorStem",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 3.16, -1.22),
		size = Vector3.new(0.10, 0.28, 0.10),
		color = Color3.fromRGB(24, 26, 32),
	})
	makeCarPart({
		name = "InteriorRearviewMirror",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 2.98, -1.26),
		size = Vector3.new(1.05, 0.26, 0.10),
		color = Color3.fromRGB(28, 32, 38),
		reflectance = 0.35,
	})
	for _, vx in ipairs({ -1.52, 1.52 }) do
		makeCarPart({
			name = "SunVisor",
			parent = interiorFolder,
			chassis = chassis,
			localCF = CFrame.new(vx, 3.22, -1.05),
			size = Vector3.new(1.48, 0.06, 0.46),
			color = Color3.fromRGB(28, 31, 38),
		})
	end
	local domeLamp = makeCarPart({
		name = "CabinDomeLight",
		parent = interiorFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 3.26, 0.32),
		size = Vector3.new(0.56, 0.08, 0.38),
		color = Color3.fromRGB(255, 236, 185),
		material = Enum.Material.SmoothPlastic,
	})
	local domePointLight = Instance.new("PointLight")
	domePointLight.Name = "CabinPointLight"
	domePointLight.Color = Color3.fromRGB(255, 234, 186)
	domePointLight.Brightness = 0
	domePointLight.Range = 9
	domePointLight.Parent = domeLamp

	-- ========================================================================
	-- 3. KHOANG ĐỘNG CƠ V8 BÊN DƯỚI NẮP CAPO (Lộ rõ khi nắp capo vỡ bung rời)
	-- ========================================================================
	makeCarPart({
		name = "V8_EngineBlock",
		parent = car,
		chassis = chassis,
		localCF = CFrame.new(0, 0.62, -5.05),
		size = Vector3.new(2.55, 0.98, 2.85),
		color = Color3.fromRGB(58, 62, 70),
		material = Enum.Material.Metal,
	})
	makeCarPart({
		name = "V8_TwinIntake",
		parent = car,
		chassis = chassis,
		localCF = CFrame.new(0, 1.18, -5.05),
		size = Vector3.new(1.78, 0.26, 2.25),
		color = Color3.fromRGB(148, 156, 168),
		material = Enum.Material.Metal,
	})
	for _, sx in ipairs({ -1.18, 1.18 }) do
		makeCarPart({
			name = "ChromeHeaderPipe",
			parent = car,
			chassis = chassis,
			localCF = CFrame.new(sx, 0.78, -5.05),
			size = Vector3.new(0.42, 0.30, 2.35),
			color = Color3.fromRGB(196, 202, 210),
			material = Enum.Material.Metal,
			reflectance = 0.25,
		})
	end

	-- ========================================================================
	-- 4. VỎ NGOÀI CAO THOÁNG + BẢN LỀ CỬA MỞ XOAY 64° + MÁU ẨN (PartHealth)
	-- ========================================================================
	local bodyPartsFolder = Instance.new("Folder")
	bodyPartsFolder.Name = "DestructibleBodywork"
	bodyPartsFolder.Parent = car

	-- Cản trước + Cánh lướt gió gầm + Lưới tản nhiệt + 2 Đèn pha
	makeCarPart({
		name = "FrontBumper",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 0.42, -7.85),
		size = Vector3.new(7.45, 1.36, 1.08),
		color = trim.bodyColor,
		hp = 125,
		zone = "Front",
	})
	makeCarPart({
		name = "FrontCarbonSplitter",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, -0.22, -8.08),
		size = Vector3.new(7.55, 0.22, 1.28),
		color = Color3.fromRGB(22, 24, 28),
		hp = 85,
		zone = "Front",
	})
	makeCarPart({
		name = "FrontRadiatorGrille",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 0.44, -8.36),
		size = Vector3.new(4.38, 0.84, 0.14),
		color = Color3.fromRGB(18, 20, 24),
		material = Enum.Material.DiamondPlate,
		hp = 90,
		zone = "Front",
	})
	for _, side in ipairs({ -1, 1 }) do
		local tag = if side < 0 then "Left" else "Right"
		makeCarPart({
			name = tag .. "Headlight",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 2.78, 0.88, -8.30),
			size = Vector3.new(1.48, 0.46, 0.28),
			color = Color3.fromRGB(238, 248, 255),
			material = Enum.Material.Neon,
			hp = 45,
			zone = "Front",
		})
	end

	-- Nắp Capo cao thoáng dốc nhẹ về phía mũi xe (140 HP)
	local hoodTilt = CFrame.Angles(math.rad(-4.2), 0, 0)
	makeCarPart({
		name = "HoodPanel",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.56, -5.22) * hoodTilt,
		size = Vector3.new(5.18, 0.26, 4.68),
		color = trim.bodyColor,
		hp = 140,
		zone = "Front",
	})
	makeCarPart({
		name = "HoodRacingStripe",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.71, -5.22) * hoodTilt,
		size = Vector3.new(1.36, 0.05, 4.60),
		color = trim.stripeColor,
		hp = 95,
		zone = "Front",
	})
	if trim.style == "GauntletGTX" then
		makeCarPart({
			name = "SuperchargerScoop",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(0, 1.88, -4.95) * hoodTilt,
			size = Vector3.new(1.58, 0.36, 2.20),
			color = Color3.fromRGB(24, 26, 32),
			material = Enum.Material.Metal,
			hp = 110,
			zone = "Front",
		})
	end

	-- Vè chắn bùn hốc bánh trước & sau 2 bên + Bệ bước SideSkirt
	for _, side in ipairs({ -1, 1 }) do
		local tag = if side < 0 then "Left" else "Right"
		makeCarPart({
			name = tag .. "FrontFender",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.18, 1.38, -5.18),
			size = Vector3.new(1.18, 0.72, 4.65),
			color = trim.bodyColor,
			hp = 135,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "FrontFenderNose",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.18, 0.66, -7.02),
			size = Vector3.new(1.18, 0.96, 1.05),
			color = trim.bodyColor,
			hp = 110,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "RearQuarterPanel",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.22, 1.48, 5.12),
			size = Vector3.new(1.24, 0.84, 4.85),
			color = trim.bodyColor,
			hp = 145,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "RearQuarterTail",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.22, 0.72, 7.04),
			size = Vector3.new(1.24, 1.04, 1.08),
			color = trim.bodyColor,
			hp = 115,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "SideSkirt",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.54, 0.02, -0.05),
			size = Vector3.new(0.46, 0.36, 5.48),
			color = Color3.fromRGB(24, 26, 32),
			hp = 95,
			zone = tag,
		})
	end

	-- ========================================================================
	-- 2 CỤM CỬA BẢN LỀ XOAY MỞ THỰC TẾ (LeftDoor / RightDoor + Táp-pi trong + Loa + Tay nắm + Kính + Gương)
	-- ========================================================================
	for _, side in ipairs({ -1, 1 }) do
		local tag = if side < 0 then "Left" else "Right"
		local hingeLocalPos = Vector3.new(side * 3.44, 0.98, -2.72)

		-- Trục bản lề vô hình gắn vào Chassis qua khớp Weld (Tween C0 để xoay mở 64° ra ngoài!)
		local doorHinge = Instance.new("Part")
		doorHinge.Name = tag .. "DoorHinge"
		doorHinge.Size = Vector3.new(0.25, 0.25, 0.25)
		doorHinge.CFrame = chassis.CFrame * CFrame.new(hingeLocalPos)
		doorHinge.Transparency = 1
		doorHinge.CanCollide = false
		doorHinge.CanQuery = false
		doorHinge.Massless = true
		doorHinge:SetAttribute("Destructible", false)
		doorHinge.Parent = car

		local hingeWeld = Instance.new("Weld")
		hingeWeld.Name = "DoorHingeWeld"
		hingeWeld.Part0 = chassis
		hingeWeld.Part1 = doorHinge
		hingeWeld.C0 = CFrame.new(hingeLocalPos)
		hingeWeld.C1 = CFrame.new(0, 0, 0)
		hingeWeld.Parent = doorHinge
		doorHinge:SetAttribute("ClosedX", hingeLocalPos.X)
		doorHinge:SetAttribute("ClosedY", hingeLocalPos.Y)
		doorHinge:SetAttribute("ClosedZ", hingeLocalPos.Z)
		doorHinge:SetAttribute("SideSign", side)

		-- Thân cánh cửa kim loại chính (hàn vào doorHinge -> xoay cùng bản lề; có máu ẩn 140 HP!)
		local doorPanel = makeCarPart({
			name = tag .. "Door",
			parent = bodyPartsFolder,
			chassis = chassis,
			weldTarget = doorHinge,
			localCF = CFrame.new(side * 3.44, 0.98, -0.02),
			size = Vector3.new(0.58, 1.58, 5.42),
			color = trim.bodyColor,
			hp = 140,
			zone = tag,
		})

		-- Tay nắm cửa mạ Crôm bên ngoài + Khung Prompt [F] Mở cửa lên xe chuẩn GTA V
		local handle = makeCarPart({
			name = tag .. "OuterDoorHandle",
			parent = bodyPartsFolder,
			chassis = chassis,
			weldTarget = doorPanel,
			localCF = CFrame.new(side * 3.76, 1.34, 1.62),
			size = Vector3.new(0.14, 0.14, 0.68),
			color = Color3.fromRGB(214, 220, 228),
			material = Enum.Material.Metal,
			reflectance = 0.25,
		})

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EnterDoorPrompt"
		prompt.ActionText = if side < 0 then "Mở Cửa Lái Xe" else "Mở Cửa Ghế Phụ"
		prompt.ObjectText = trim.modelName
		prompt.KeyboardKeyCode = Enum.KeyCode.F
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = handle

		-- Táp-pi da bên trong cánh cửa + Tay vịn kéo cửa + Màng loa tròn (lộ rõ mồn một khi cửa mở!)
		makeCarPart({
			name = tag .. "DoorInnerTrimCard",
			parent = bodyPartsFolder,
			chassis = chassis,
			weldTarget = doorPanel,
			localCF = CFrame.new(side * 3.12, 0.96, -0.02),
			size = Vector3.new(0.10, 1.38, 5.05),
			color = Color3.fromRGB(28, 31, 38),
			material = Enum.Material.Fabric,
		})
		makeCarPart({
			name = tag .. "DoorArmrestPull",
			parent = bodyPartsFolder,
			chassis = chassis,
			weldTarget = doorPanel,
			localCF = CFrame.new(side * 2.98, 1.04, 0.25),
			size = Vector3.new(0.22, 0.16, 1.95),
			color = trim.interiorAccent,
		})
		local speaker = makeCarPart({
			name = tag .. "DoorSpeakerGrille",
			parent = bodyPartsFolder,
			chassis = chassis,
			weldTarget = doorPanel,
			localCF = CFrame.new(side * 3.05, 0.66, -1.55),
			size = Vector3.new(0.08, 0.66, 0.66),
			color = Color3.fromRGB(46, 52, 62),
			material = Enum.Material.DiamondPlate,
		})
		if speaker:IsA("Part") then
			speaker.Shape = Enum.PartType.Cylinder
		end

		-- Gương chiếu hậu & Kính cửa sổ bên (hàn vào doorPanel để đi theo cánh cửa khi mở ra!)
		makeCarPart({
			name = tag .. "SideMirror",
			parent = bodyPartsFolder,
			chassis = chassis,
			weldTarget = doorPanel,
			localCF = CFrame.new(side * 3.98, 1.88, -2.08),
			size = Vector3.new(0.60, 0.34, 0.44),
			color = trim.bodyColor,
			hp = 38,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "SideWindow",
			parent = bodyPartsFolder,
			chassis = chassis,
			weldTarget = doorPanel,
			localCF = CFrame.new(side * 3.14, 2.48, 0.18) * CFrame.Angles(0, 0, side * math.rad(12)),
			size = Vector3.new(0.12, 1.54, 4.45),
			color = Color3.fromRGB(32, 44, 58),
			material = Enum.Material.Glass,
			transparency = 0.54,
			hp = 45,
			zone = "Glass",
		})
	end

	-- Kính chắn gió trước cao thoáng + Cột chữ A 2 bên + Mui xe cao (Y = 3.36) + Kính Fastback sau
	makeCarPart({
		name = "FrontWindshield",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 2.52, -2.28),
		size = Vector3.new(5.68, 1.68, 2.55),
		color = Color3.fromRGB(34, 48, 66),
		material = Enum.Material.Glass,
		transparency = 0.52,
		isWedge = true,
		hp = 55,
		zone = "Glass",
	})
	for _, side in ipairs({ -1, 1 }) do
		local tag = if side < 0 then "Left" else "Right"
		makeCarPart({
			name = tag .. "APillar",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 2.80, 2.52, -2.28) * CFrame.Angles(math.rad(-33.4), 0, 0),
			size = Vector3.new(0.22, 0.22, 3.04),
			color = Color3.fromRGB(24, 27, 34),
			hp = 160,
			zone = "Top",
		})
	end

	makeCarPart({
		name = "RoofPanel",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 3.36, 0.58),
		size = Vector3.new(5.62, 0.24, 3.45),
		color = trim.bodyColor,
		hp = 210,
		zone = "Top",
	})
	makeCarPart({
		name = "RoofStripe",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 3.50, 0.58),
		size = Vector3.new(1.36, 0.05, 3.38),
		color = trim.stripeColor,
		hp = 120,
		zone = "Top",
	})
	makeCarPart({
		name = "RearFastbackWindow",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 2.54, 3.58) * CFrame.Angles(0, math.rad(180), 0),
		size = Vector3.new(5.52, 1.58, 2.65),
		color = Color3.fromRGB(28, 38, 52),
		material = Enum.Material.Glass,
		transparency = 0.50,
		isWedge = true,
		hp = 50,
		zone = "Glass",
	})

	-- Cốp sau + Cánh gió thể thao GT cao ráo + Cản sau + Đèn hậu LED + Ống xả đôi + Biển số San Andreas
	makeCarPart({
		name = "TrunkDeck",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.66, 6.08),
		size = Vector3.new(5.16, 0.38, 2.98),
		color = trim.bodyColor,
		hp = 130,
		zone = "Rear",
	})
	if trim.style == "BansheeGT" then
		makeCarPart({
			name = "RearSpoilerWing",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(0, 2.52, 7.32),
			size = Vector3.new(6.92, 0.18, 1.08),
			color = Color3.fromRGB(22, 24, 30),
			hp = 75,
			zone = "Rear",
		})
		for _, sx in ipairs({ -2.14, 2.14 }) do
			makeCarPart({
				name = "SpoilerPylon",
				parent = bodyPartsFolder,
				chassis = chassis,
				localCF = CFrame.new(sx, 2.14, 7.22),
				size = Vector3.new(0.24, 0.72, 0.76),
				color = Color3.fromRGB(22, 24, 30),
				hp = 70,
				zone = "Rear",
			})
		end
	end

	makeCarPart({
		name = "RearBumper",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 0.56, 7.88),
		size = Vector3.new(7.48, 1.44, 1.08),
		color = trim.bodyColor,
		hp = 125,
		zone = "Rear",
	})
	makeCarPart({
		name = "RearDiffuser",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, -0.14, 8.04),
		size = Vector3.new(6.65, 0.36, 0.92),
		color = Color3.fromRGB(20, 22, 26),
		hp = 90,
		zone = "Rear",
	})
	for _, side in ipairs({ -1, 1 }) do
		local tag = if side < 0 then "Left" else "Right"
		makeCarPart({
			name = tag .. "Taillight",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 2.58, 1.12, 8.38),
			size = Vector3.new(1.78, 0.42, 0.22),
			color = Color3.fromRGB(225, 28, 38),
			material = Enum.Material.Neon,
			hp = 45,
			zone = "Rear",
		})
		makeCarPart({
			name = tag .. "ExhaustTip",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 1.88, -0.12, 8.50),
			size = Vector3.new(0.56, 0.44, 0.56),
			color = Color3.fromRGB(198, 204, 212),
			material = Enum.Material.Metal,
			reflectance = 0.3,
			hp = 80,
			zone = "Rear",
		})
	end

	local plate = makeCarPart({
		name = "LicensePlate",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 0.68, 8.44),
		size = Vector3.new(1.88, 0.64, 0.08),
		color = Color3.fromRGB(242, 245, 250),
		hp = 60,
		zone = "Rear",
	})
	local plateGui = Instance.new("SurfaceGui")
	plateGui.Face = Enum.NormalId.Back
	plateGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	plateGui.PixelsPerStud = 48
	plateGui.Parent = plate
	local plateTop = Instance.new("TextLabel")
	plateTop.BackgroundTransparency = 1
	plateTop.Size = UDim2.fromScale(1, 0.36)
	plateTop.Font = Enum.Font.GothamBlack
	plateTop.TextScaled = true
	plateTop.TextColor3 = Color3.fromRGB(185, 36, 36)
	plateTop.Text = "SAN ANDREAS"
	plateTop.Parent = plateGui
	local plateNum = Instance.new("TextLabel")
	plateNum.BackgroundTransparency = 1
	plateNum.Position = UDim2.fromScale(0, 0.34)
	plateNum.Size = UDim2.fromScale(1, 0.62)
	plateNum.Font = Enum.Font.GothamBlack
	plateNum.TextScaled = true
	plateNum.TextColor3 = Color3.fromRGB(24, 58, 128)
	plateNum.Text = "46GTV88"
	plateNum.Parent = plateGui

	-- ========================================================================
	-- 5. BỐN CỤM BÁNH XE LỚN HƠN (3.06 STUDS) + CẦU LĂN VẬT LÝ LEO VỈA HÈ MƯỢT
	-- ========================================================================
	local wheelsFolder = Instance.new("Folder")
	wheelsFolder.Name = "Wheels"
	wheelsFolder.Parent = car

	local wheelSpecs = {
		{ name = "FL", x = -3.22, z = -5.12 },
		{ name = "FR", x = 3.22, z = -5.12 },
		{ name = "RL", x = -3.22, z = 5.12 },
		{ name = "RR", x = 3.22, z = 5.12 },
	}
	for _, ws in ipairs(wheelSpecs) do
		local sideSign = if ws.x < 0 then -1 else 1
		local ball = Instance.new("Part")
		ball.Name = "WheelCollider_" .. ws.name
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(3.48, 3.48, 3.48)
		ball.CFrame = chassis.CFrame * CFrame.new(ws.x * 0.86, -0.48, ws.z)
		ball.Transparency = 1
		ball.CanCollide = true
		ball.CanQuery = false
		ball.TopSurface = Enum.SurfaceType.Smooth
		ball.BottomSurface = Enum.SurfaceType.Smooth
		ball.CustomPhysicalProperties = PhysicalProperties.new(1.4, 0.08, 0.02, 100, 1)
		ball:SetAttribute("Destructible", false)
		ball.Parent = wheelsFolder
		weldTo(chassis, ball)

		local tire = Instance.new("Part")
		tire.Name = "Tire_" .. ws.name
		tire.Shape = Enum.PartType.Cylinder
		tire.Size = Vector3.new(1.16, 3.06, 3.06)
		tire.CFrame = chassis.CFrame * CFrame.new(ws.x, -0.68, ws.z)
		tire.Color = Color3.fromRGB(22, 24, 28)
		tire.Material = Enum.Material.Rubber
		tire.CanCollide = false
		tire.Massless = true
		tire:SetAttribute("Destructible", false)
		tire.Parent = wheelsFolder
		weldTo(chassis, tire)

		local rim = Instance.new("Part")
		rim.Name = "Rim_" .. ws.name
		rim.Shape = Enum.PartType.Cylinder
		rim.Size = Vector3.new(1.12, 2.04, 2.04)
		rim.CFrame = chassis.CFrame * CFrame.new(ws.x + sideSign * 0.04, -0.68, ws.z)
		rim.Color = trim.rimColor
		rim.Material = Enum.Material.Metal
		rim.Reflectance = 0.22
		rim.CanCollide = false
		rim.Massless = true
		rim:SetAttribute("Destructible", false)
		rim.Parent = wheelsFolder
		weldTo(chassis, rim)

		for _, spokeAng in ipairs({ 0, 45, 90, 135 }) do
			local spoke = Instance.new("Part")
			spoke.Name = "Spoke_" .. ws.name
			spoke.Size = Vector3.new(0.08, 1.86, 0.19)
			spoke.CFrame = chassis.CFrame
				* CFrame.new(ws.x + sideSign * 0.61, -0.68, ws.z)
				* CFrame.Angles(math.rad(spokeAng), 0, 0)
			spoke.Color = Color3.fromRGB(36, 40, 48)
			spoke.Material = Enum.Material.Metal
			spoke.CanCollide = false
			spoke.Massless = true
			spoke:SetAttribute("Destructible", false)
			spoke.Parent = wheelsFolder
			weldTo(chassis, spoke)
		end

		local caliper = Instance.new("Part")
		caliper.Name = "BrakeCaliper_" .. ws.name
		caliper.Size = Vector3.new(0.22, 0.68, 0.42)
		caliper.CFrame = chassis.CFrame * CFrame.new(ws.x + sideSign * 0.28, -0.50, ws.z - 0.52)
		caliper.Color = Color3.fromRGB(220, 36, 36)
		caliper.Material = Enum.Material.Metal
		caliper.CanCollide = false
		caliper.Massless = true
		caliper:SetAttribute("Destructible", false)
		caliper.Parent = wheelsFolder
		weldTo(chassis, caliper)
	end

	-- 6. BỘ ĐỘNG LỰC VẬT LÝ (Attachment + VectorForce + AngularVelocity)
	local rootAtt = Instance.new("Attachment")
	rootAtt.Name = "DriveAttachment"
	rootAtt.Parent = chassis

	local driveForce = Instance.new("VectorForce")
	driveForce.Name = "DriveVectorForce"
	driveForce.Attachment0 = rootAtt
	driveForce.RelativeTo = Enum.ActuatorRelativeTo.World
	driveForce.Force = Vector3.zero
	driveForce.Parent = chassis

	local steerVel = Instance.new("AngularVelocity")
	steerVel.Name = "SteerAngularVelocity"
	steerVel.Attachment0 = rootAtt
	steerVel.RelativeTo = Enum.ActuatorRelativeTo.World
	steerVel.MaxTorque = 0
	steerVel.AngularVelocity = Vector3.zero
	steerVel.Parent = chassis

	return car
end

-- Đội xe GTA V đậu sẵn quanh Quảng trường Legion Square & Đại lộ trung tâm
function VehicleBuilder.spawnDefaultFleet(losSantosRoot: Instance): Folder
	local existing = losSantosRoot:FindFirstChild("Phase2_Vehicles")
	if existing then
		existing:Destroy()
	end

	local fleetFolder = Instance.new("Folder")
	fleetFolder.Name = "Phase2_Vehicles"
	fleetFolder.Parent = losSantosRoot

	local spots = {
		{
			cf = CFrame.new(-24, 0.55, 139) * CFrame.Angles(0, math.rad(-90), 0),
			trim = VehicleBuilder.PRESETS.CrimsonBanshee,
		},
		{
			cf = CFrame.new(-99, 0.55, 78) * CFrame.Angles(0, math.rad(0), 0),
			trim = VehicleBuilder.PRESETS.ObsidianGauntlet,
		},
		{
			cf = CFrame.new(-36, 0.55, -25) * CFrame.Angles(0, math.rad(90), 0),
			trim = VehicleBuilder.PRESETS.MidnightBanshee,
		},
		{
			cf = CFrame.new(42, 0.55, 139) * CFrame.Angles(0, math.rad(90), 0),
			trim = VehicleBuilder.PRESETS.SunsetComet,
		},
	}

	for _, sp in ipairs(spots) do
		VehicleBuilder.spawn(fleetFolder, sp.cf, sp.trim)
	end

	return fleetFolder
end

return VehicleBuilder
