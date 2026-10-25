--!strict
--[[
	VehicleBuilder.luau
	Dựng siêu xe thể thao GTA V Los Santos cực kỳ chỉnh chu ("Banshee GT" & "Gauntlet GTX")
	từ các bộ phận rời (Cản trước/sau, Nắp capo, Khoang máy V8 bên trong, Kính chắn gió, Cửa trái/phải,
	Gương chiếu hậu, Đèn pha/hậu, Cánh gió sau, Biển số San Andreas, Mâm hợp kim & Heo dầu phanh).
	MỖI BỘ PHẬN VỎ XE ĐỀU CÓ MÁU ẨN (PartHealth) — Bị súng bắn hoặc đâm xe sẽ sẫm màu/nứt và tự bung vỡ!
]]

local VehicleBuilder = {}

export type VehicleTrim = {
	modelName: string,
	style: "BansheeGT" | "GauntletGTX",
	bodyColor: Color3,
	stripeColor: Color3,
	rimColor: Color3,
	maxSpeed: number,
}

VehicleBuilder.PRESETS = {
	CrimsonBanshee = {
		modelName = "Banshee GT",
		style = "BansheeGT",
		bodyColor = Color3.fromRGB(196, 26, 36),
		stripeColor = Color3.fromRGB(244, 246, 250),
		rimColor = Color3.fromRGB(212, 218, 226),
		maxSpeed = 94,
	} :: VehicleTrim,
	MidnightBanshee = {
		modelName = "Banshee GT",
		style = "BansheeGT",
		bodyColor = Color3.fromRGB(22, 64, 148),
		stripeColor = Color3.fromRGB(238, 242, 248),
		rimColor = Color3.fromRGB(220, 224, 232),
		maxSpeed = 94,
	} :: VehicleTrim,
	ObsidianGauntlet = {
		modelName = "Gauntlet GTX",
		style = "GauntletGTX",
		bodyColor = Color3.fromRGB(28, 31, 38),
		stripeColor = Color3.fromRGB(238, 186, 42),
		rimColor = Color3.fromRGB(198, 162, 58),
		maxSpeed = 88,
	} :: VehicleTrim,
	SunsetComet = {
		modelName = "Banshee GT",
		style = "BansheeGT",
		bodyColor = Color3.fromRGB(234, 118, 24),
		stripeColor = Color3.fromRGB(24, 28, 34),
		rimColor = Color3.fromRGB(44, 48, 56),
		maxSpeed = 96,
	} :: VehicleTrim,
}

local function weldTo(root: BasePart, part: BasePart): WeldConstraint
	local wc = Instance.new("WeldConstraint")
	wc.Name = "PanelWeld"
	wc.Part0 = root
	wc.Part1 = part
	wc.Parent = part
	return wc
end

local function makeCarPart(spec: {
	name: string,
	parent: Instance,
	chassis: BasePart,
	localCF: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	hp: number?, -- nil => khung gầm lõi không vỡ rời (tính vào EngineHealth)
	zone: string?, -- "Front" | "Rear" | "Left" | "Right" | "Top" | "Glass"
	isWedge: boolean?,
	shape: Enum.PartType?,
	canCollide: boolean?,
}): BasePart
	local inst: BasePart
	if spec.isWedge then
		inst = Instance.new("WedgePart")
	else
		local p = Instance.new("Part")
		if spec.shape then
			p.Shape = spec.shape
		end
		inst = p
	end

	inst.Name = spec.name
	inst.Size = spec.size
	inst.CFrame = spec.chassis.CFrame * spec.localCF
	inst.Color = spec.color
	inst.Material = spec.material or Enum.Material.SmoothPlastic
	inst.Transparency = spec.transparency or 0
	inst.TopSurface = Enum.SurfaceType.Smooth
	inst.BottomSurface = Enum.SurfaceType.Smooth
	inst.Anchored = false
	inst.Massless = true
	inst.CanCollide = if spec.canCollide ~= nil then spec.canCollide else false
	inst.CanQuery = true
	inst.CanTouch = true

	if spec.hp ~= nil then
		inst:SetAttribute("Destructible", true)
		inst:SetAttribute("VehiclePart", true)
		inst:SetAttribute("MaxPartHealth", spec.hp)
		inst:SetAttribute("PartHealth", spec.hp)
		inst:SetAttribute("MaxIntegrity", spec.hp)
		inst:SetAttribute("Integrity", spec.hp)
		inst:SetAttribute("DamageZone", spec.zone or "Body")
	else
		inst:SetAttribute("Destructible", false)
	end

	inst.Parent = spec.parent
	weldTo(spec.chassis, inst)
	return inst
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

	-- 1. KHUNG SƯỜN GẦM LÕI (Chassis — Tâm ở độ cao +2.05 trên mặt đất để 4 bánh cầu R=1.65 chạm sát mặt đường)
	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(6.4, 1.1, 14.4)
	chassis.CFrame = spawnCF * CFrame.new(0, 2.05, 0)
	chassis.Color = Color3.fromRGB(28, 30, 36)
	chassis.Material = Enum.Material.Metal
	chassis.TopSurface = Enum.SurfaceType.Smooth
	chassis.BottomSurface = Enum.SurfaceType.Smooth
	chassis.Anchored = false
	chassis.CanCollide = true
	chassis.CustomPhysicalProperties = PhysicalProperties.new(2.2, 0.35, 0.05, 1, 1)
	chassis:SetAttribute("Destructible", false)
	chassis.Parent = car
	car.PrimaryPart = chassis

	-- Sàn nội thất ca-bin tối màu + Bảng táp-lô + Vô lăng thể thao
	makeCarPart({
		name = "CabinTub",
		parent = car,
		chassis = chassis,
		localCF = CFrame.new(0, 0.35, 0.1),
		size = Vector3.new(5.8, 0.5, 6.2),
		color = Color3.fromRGB(34, 37, 44),
		material = Enum.Material.Fabric,
	})
	makeCarPart({
		name = "DashboardConsole",
		parent = car,
		chassis = chassis,
		localCF = CFrame.new(0, 1.15, -2.35),
		size = Vector3.new(5.6, 0.95, 1.1),
		color = Color3.fromRGB(24, 27, 34),
		material = Enum.Material.SmoothPlastic,
	})
	makeCarPart({
		name = "DigitalGaugeCluster",
		parent = car,
		chassis = chassis,
		localCF = CFrame.new(-1.45, 1.42, -1.78),
		size = Vector3.new(1.3, 0.36, 0.08),
		color = Color3.fromRGB(56, 189, 248),
		material = Enum.Material.Neon,
	})
	makeCarPart({
		name = "SteeringWheel",
		parent = car,
		chassis = chassis,
		localCF = CFrame.new(-1.45, 1.32, -1.45) * CFrame.Angles(math.rad(-22), 0, 0),
		size = Vector3.new(1.15, 1.15, 0.18),
		color = Color3.fromRGB(20, 22, 26),
		material = Enum.Material.SmoothPlastic,
	})

	-- Ghế lái chính thức (VehicleSeat — bên trái chuẩn Mỹ) + Ghế phụ bên phải
	local driverSeat = Instance.new("VehicleSeat")
	driverSeat.Name = "DriverSeat"
	driverSeat.Size = Vector3.new(2.1, 0.55, 2.1)
	driverSeat.CFrame = chassis.CFrame * CFrame.new(-1.45, 0.62, 0.15)
	driverSeat.Color = Color3.fromRGB(26, 28, 34)
	driverSeat.Material = Enum.Material.Fabric
	driverSeat.MaxSpeed = trim.maxSpeed
	driverSeat.Torque = 0 -- Điều khiển qua VectorForce mượt mà trong VehicleManager
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
	passSeat.Size = Vector3.new(2.1, 0.55, 2.1)
	passSeat.CFrame = chassis.CFrame * CFrame.new(1.45, 0.62, 0.15)
	passSeat.Color = Color3.fromRGB(26, 28, 34)
	passSeat.Material = Enum.Material.Fabric
	passSeat.TopSurface = Enum.SurfaceType.Smooth
	passSeat.BottomSurface = Enum.SurfaceType.Smooth
	passSeat.Massless = true
	passSeat:SetAttribute("Destructible", false)
	passSeat.Parent = car
	weldTo(chassis, passSeat)

	for _, sx in ipairs({ -1.45, 1.45 }) do
		makeCarPart({
			name = "SportSeatBack",
			parent = car,
			chassis = chassis,
			localCF = CFrame.new(sx, 1.45, 1.05) * CFrame.Angles(math.rad(-10), 0, 0),
			size = Vector3.new(1.85, 1.85, 0.42),
			color = Color3.fromRGB(32, 35, 42),
			material = Enum.Material.Fabric,
		})
	end

	-- 2. KHOANG ĐỘNG CƠ V8 BÊN DƯỚI NẮP CAPO (Nằm gọn bên dưới HoodPanel, lộ rõ khi nắp capo bung rời!)
	makeCarPart({
		name = "V8_EngineBlock",
		parent = car,
		chassis = chassis,
		localCF = CFrame.new(0, 0.48, -4.9),
		size = Vector3.new(2.5, 0.88, 2.8),
		color = Color3.fromRGB(58, 62, 70),
		material = Enum.Material.Metal,
	})
	makeCarPart({
		name = "V8_TwinIntake",
		parent = car,
		chassis = chassis,
		localCF = CFrame.new(0, 0.94, -4.9),
		size = Vector3.new(1.75, 0.24, 2.2),
		color = Color3.fromRGB(148, 156, 168),
		material = Enum.Material.Metal,
	})
	for _, sx in ipairs({ -1.15, 1.15 }) do
		makeCarPart({
			name = "ChromeHeaderPipe",
			parent = car,
			chassis = chassis,
			localCF = CFrame.new(sx, 0.60, -4.9),
			size = Vector3.new(0.42, 0.28, 2.3),
			color = Color3.fromRGB(196, 202, 210),
			material = Enum.Material.Metal,
			reflectance = 0.25,
		})
	end

	-- 3. CÁC BỘ PHẬN VỎ NGOÀI CÓ MÁU ẨN (PartHealth) — TỰ VỠ / BUNG RỜI KHI HẾT MÁU!
	local bodyPartsFolder = Instance.new("Folder")
	bodyPartsFolder.Name = "DestructibleBodywork"
	bodyPartsFolder.Parent = car

	-- Cản trước + Cánh lướt gió gầm + Lưới tản nhiệt + 2 Đèn pha
	makeCarPart({
		name = "FrontBumper",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 0.28, -7.65),
		size = Vector3.new(7.35, 1.15, 1.05),
		color = trim.bodyColor,
		hp = 125,
		zone = "Front",
	})
	makeCarPart({
		name = "FrontCarbonSplitter",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, -0.22, -7.88),
		size = Vector3.new(7.45, 0.22, 1.25),
		color = Color3.fromRGB(22, 24, 28),
		hp = 85,
		zone = "Front",
	})
	makeCarPart({
		name = "FrontRadiatorGrille",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 0.28, -8.14),
		size = Vector3.new(4.3, 0.72, 0.14),
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
			localCF = CFrame.new(side * 2.75, 0.68, -8.08),
			size = Vector3.new(1.45, 0.42, 0.28),
			color = Color3.fromRGB(238, 248, 255),
			material = Enum.Material.Neon,
			hp = 45,
			zone = "Front",
		})
	end

	-- Nắp Capo khí động học dốc nhẹ về phía mũi xe (che kín khoang máy V8 khi lành lặn — 140 HP)
	local hoodTilt = CFrame.Angles(math.rad(-4.6), 0, 0)
	makeCarPart({
		name = "HoodPanel",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.28, -5.08) * hoodTilt,
		size = Vector3.new(5.14, 0.24, 4.55),
		color = trim.bodyColor,
		hp = 140,
		zone = "Front",
	})
	makeCarPart({
		name = "HoodRacingStripe",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.42, -5.08) * hoodTilt,
		size = Vector3.new(1.35, 0.05, 4.48),
		color = trim.stripeColor,
		hp = 95,
		zone = "Front",
	})
	if trim.style == "GauntletGTX" then
		makeCarPart({
			name = "SuperchargerScoop",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(0, 1.56, -4.85) * hoodTilt,
			size = Vector3.new(1.55, 0.34, 2.15),
			color = Color3.fromRGB(24, 26, 32),
			material = Enum.Material.Metal,
			hp = 110,
			zone = "Front",
		})
	end

	-- Vè chắn bùn hốc bánh trước & sau 2 bên (Fenders cao thoáng ôm tròn bánh xe, không đâm xuyên lốp!)
	for _, side in ipairs({ -1, 1 }) do
		local tag = if side < 0 then "Left" else "Right"
		makeCarPart({
			name = tag .. "FrontFender",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.14, 1.16, -5.05),
			size = Vector3.new(1.16, 0.58, 4.55),
			color = trim.bodyColor,
			hp = 135,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "FrontFenderNose",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.14, 0.56, -6.82),
			size = Vector3.new(1.16, 0.78, 1.05),
			color = trim.bodyColor,
			hp = 110,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "RearQuarterPanel",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.18, 1.24, 4.95),
			size = Vector3.new(1.22, 0.68, 4.75),
			color = trim.bodyColor,
			hp = 145,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "RearQuarterTail",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.18, 0.58, 6.82),
			size = Vector3.new(1.22, 0.84, 1.05),
			color = trim.bodyColor,
			hp = 115,
			zone = tag,
		})
	end

	-- 2 Cánh cửa xe + Gương chiếu hậu + Kính cửa sổ hai bên
	for _, side in ipairs({ -1, 1 }) do
		local tag = if side < 0 then "Left" else "Right"
		makeCarPart({
			name = tag .. "Door",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.38, 0.78, -0.05),
			size = Vector3.new(0.62, 1.32, 5.35),
			color = trim.bodyColor,
			hp = 135,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "SideSkirt",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.52, -0.02, -0.05),
			size = Vector3.new(0.45, 0.34, 5.4),
			color = Color3.fromRGB(24, 26, 32),
			hp = 95,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "SideMirror",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.92, 1.54, -2.05),
			size = Vector3.new(0.58, 0.32, 0.42),
			color = trim.bodyColor,
			hp = 38,
			zone = tag,
		})
		makeCarPart({
			name = tag .. "SideWindow",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 3.08, 1.98, 0.15) * CFrame.Angles(0, 0, side * math.rad(14)),
			size = Vector3.new(0.14, 1.08, 4.25),
			color = Color3.fromRGB(28, 38, 52),
			material = Enum.Material.Glass,
			transparency = 0.42,
			hp = 45,
			zone = "Glass",
		})
	end

	-- Kính chắn gió trước + Mui xe + Kính vát Fastback phía sau
	makeCarPart({
		name = "FrontWindshield",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.98, -2.15),
		size = Vector3.new(5.65, 1.28, 2.35),
		color = Color3.fromRGB(32, 46, 62),
		material = Enum.Material.Glass,
		transparency = 0.38,
		isWedge = true,
		hp = 55,
		zone = "Glass",
	})
	makeCarPart({
		name = "RoofPanel",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 2.58, 0.55),
		size = Vector3.new(5.55, 0.22, 3.2),
		color = trim.bodyColor,
		hp = 210,
		zone = "Top",
	})
	makeCarPart({
		name = "RoofStripe",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 2.70, 0.55),
		size = Vector3.new(1.35, 0.05, 3.15),
		color = trim.stripeColor,
		hp = 120,
		zone = "Top",
	})
	makeCarPart({
		name = "RearFastbackWindow",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 2.02, 3.35) * CFrame.Angles(0, math.rad(180), 0),
		size = Vector3.new(5.45, 1.15, 2.45),
		color = Color3.fromRGB(26, 36, 48),
		material = Enum.Material.Glass,
		transparency = 0.40,
		isWedge = true,
		hp = 50,
		zone = "Glass",
	})

	-- Cốp sau + Cánh gió thể thao GT + Cản sau + Đèn hậu LED + Ống xả đôi + Biển số San Andreas
	makeCarPart({
		name = "TrunkDeck",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, 1.34, 5.85),
		size = Vector3.new(5.1, 0.36, 2.95),
		color = trim.bodyColor,
		hp = 130,
		zone = "Rear",
	})
	if trim.style == "BansheeGT" then
		makeCarPart({
			name = "RearSpoilerWing",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(0, 2.12, 7.15),
			size = Vector3.new(6.85, 0.18, 1.05),
			color = Color3.fromRGB(22, 24, 30),
			hp = 75,
			zone = "Rear",
		})
		for _, sx in ipairs({ -2.1, 2.1 }) do
			makeCarPart({
				name = "SpoilerPylon",
				parent = bodyPartsFolder,
				chassis = chassis,
				localCF = CFrame.new(sx, 1.78, 7.05),
				size = Vector3.new(0.24, 0.65, 0.75),
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
		localCF = CFrame.new(0, 0.42, 7.68),
		size = Vector3.new(7.4, 1.25, 1.05),
		color = trim.bodyColor,
		hp = 125,
		zone = "Rear",
	})
	makeCarPart({
		name = "RearDiffuser",
		parent = bodyPartsFolder,
		chassis = chassis,
		localCF = CFrame.new(0, -0.15, 7.82),
		size = Vector3.new(6.6, 0.34, 0.9),
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
			localCF = CFrame.new(side * 2.55, 0.92, 8.16),
			size = Vector3.new(1.75, 0.38, 0.22),
			color = Color3.fromRGB(225, 28, 38),
			material = Enum.Material.Neon,
			hp = 45,
			zone = "Rear",
		})
		makeCarPart({
			name = tag .. "ExhaustTip",
			parent = bodyPartsFolder,
			chassis = chassis,
			localCF = CFrame.new(side * 1.85, -0.14, 8.28),
			size = Vector3.new(0.55, 0.42, 0.55),
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
		localCF = CFrame.new(0, 0.52, 8.22),
		size = Vector3.new(1.85, 0.62, 0.08),
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

	-- 4. BỐN CỤM BÁNH XE VẬT LÝ HÌNH CẦU LEO VỈA HÈ MƯỢT + LỐP CAO SU & MÂM HỢP KIM
	local wheelsFolder = Instance.new("Folder")
	wheelsFolder.Name = "Wheels"
	wheelsFolder.Parent = car

	local wheelSpecs = {
		{ name = "FL", x = -3.18, z = -4.95 },
		{ name = "FR", x = 3.18, z = -4.95 },
		{ name = "RL", x = -3.18, z = 4.95 },
		{ name = "RR", x = 3.18, z = 4.95 },
	}
	for _, ws in ipairs(wheelSpecs) do
		local sideSign = if ws.x < 0 then -1 else 1
		-- Khối cầu vật lý vô hình đường kính 3.3 studs giúp xe lăn êm qua bó vỉa 0.65 stud & bậc cầu thang!
		local ball = Instance.new("Part")
		ball.Name = "WheelCollider_" .. ws.name
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(3.3, 3.3, 3.3)
		ball.CFrame = chassis.CFrame * CFrame.new(ws.x * 0.86, -0.4, ws.z)
		ball.Transparency = 1
		ball.CanCollide = true
		ball.CanQuery = false
		ball.TopSurface = Enum.SurfaceType.Smooth
		ball.BottomSurface = Enum.SurfaceType.Smooth
		ball.CustomPhysicalProperties = PhysicalProperties.new(1.4, 0.08, 0.02, 100, 1)
		ball:SetAttribute("Destructible", false)
		ball.Parent = wheelsFolder
		weldTo(chassis, ball)

		-- Lốp cao su đen & Mâm hợp kim (PartType.Cylinder có trục lăn dọc trục X cục bộ -> KHÔNG xoay Z 90 độ!)
		local tire = Instance.new("Part")
		tire.Name = "Tire_" .. ws.name
		tire.Shape = Enum.PartType.Cylinder
		tire.Size = Vector3.new(1.12, 2.86, 2.86)
		tire.CFrame = chassis.CFrame * CFrame.new(ws.x, -0.60, ws.z)
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
		rim.Size = Vector3.new(1.18, 1.90, 1.90)
		rim.CFrame = chassis.CFrame * CFrame.new(ws.x + sideSign * 0.02, -0.60, ws.z)
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
			spoke.Size = Vector3.new(0.08, 1.72, 0.18)
			spoke.CFrame = chassis.CFrame
				* CFrame.new(ws.x + sideSign * 0.59, -0.60, ws.z)
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
		caliper.Size = Vector3.new(0.22, 0.64, 0.40)
		caliper.CFrame = chassis.CFrame * CFrame.new(ws.x + sideSign * 0.26, -0.44, ws.z - 0.48)
		caliper.Color = Color3.fromRGB(220, 36, 36)
		caliper.Material = Enum.Material.Metal
		caliper.CanCollide = false
		caliper.Massless = true
		caliper:SetAttribute("Destructible", false)
		caliper.Parent = wheelsFolder
		weldTo(chassis, caliper)
	end

	-- 5. GẮN BỘ ĐỘNG LỰC VẬT LÝ (Attachment + VectorForce + AngularVelocity) ĐỂ LÁI SIÊU MƯỢT
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
		-- Ngay sảnh Nam Quảng trường Legion Square (cách điểm Spawn vài bước chân!)
		{
			cf = CFrame.new(-24, 0.55, 139) * CFrame.Angles(0, math.rad(-90), 0),
			preset = VehicleBuilder.PRESETS.CrimsonBanshee,
		},
		-- Đậu sát lề đường San Andreas Ave cạnh rào cọc tiêu Legion Square
		{
			cf = CFrame.new(-99, 0.55, 78) * CFrame.Angles(0, 0, 0),
			preset = VehicleBuilder.PRESETS.ObsidianGauntlet,
		},
		-- Đậu dọc Đại lộ trung tâm Olympic Fwy (gần dải phân cách K-Rail để test đâm xe!)
		{
			cf = CFrame.new(-36, 0.55, -25) * CFrame.Angles(0, math.rad(-90), 0),
			preset = VehicleBuilder.PRESETS.MidnightBanshee,
		},
		-- Đậu sát lối đi bộ biển Vespucci Blvd
		{
			cf = CFrame.new(42, 0.55, 139) * CFrame.Angles(0, math.rad(90), 0),
			preset = VehicleBuilder.PRESETS.SunsetComet,
		},
	}

	for idx, sp in ipairs(spots) do
		local v = VehicleBuilder.spawn(fleetFolder, sp.cf, sp.preset)
		v:SetAttribute("SpawnSlotIndex", idx)
	end

	return fleetFolder
end

return VehicleBuilder
