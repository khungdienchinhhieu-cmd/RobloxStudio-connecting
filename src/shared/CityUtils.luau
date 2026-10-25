--!strict

local CollectionService = game:GetService("CollectionService")
local CityConfig = require(script.Parent:WaitForChild("CityConfig"))

local CityUtils = {}

export type PartProps = {
	Name: string?,
	Size: Vector3?,
	Position: Vector3?,
	CFrame: CFrame?,
	Color: Color3?,
	Material: Enum.Material?,
	Transparency: number?,
	Reflectance: number?,
	CanCollide: boolean?,
	Shape: Enum.PartType?,
	CastShadow: boolean?,
	Parent: Instance?,
}

function CityUtils.makePart(props: PartProps): Part
	local p = Instance.new("Part")
	p.Name = props.Name or "Part"
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Size = props.Size or Vector3.new(4, 1, 4)
	if props.CFrame then
		p.CFrame = props.CFrame
	elseif props.Position then
		p.Position = props.Position
	end
	p.Color = props.Color or Color3.fromRGB(200, 200, 205)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Transparency = props.Transparency or 0
	p.Reflectance = props.Reflectance or 0
	if props.CanCollide ~= nil then
		p.CanCollide = props.CanCollide
	end
	if props.CastShadow ~= nil then
		p.CastShadow = props.CastShadow
	end
	if props.Parent then
		p.Parent = props.Parent
	end
	return p
end

function CityUtils.makeWedge(props: PartProps): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = props.Name or "Wedge"
	w.Anchored = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Size = props.Size or Vector3.new(4, 2, 4)
	if props.CFrame then
		w.CFrame = props.CFrame
	elseif props.Position then
		w.Position = props.Position
	end
	w.Color = props.Color or Color3.fromRGB(180, 180, 185)
	w.Material = props.Material or Enum.Material.SmoothPlastic
	w.Transparency = props.Transparency or 0
	if props.CanCollide ~= nil then
		w.CanCollide = props.CanCollide
	end
	if props.Parent then
		w.Parent = props.Parent
	end
	return w
end

function CityUtils.makeSignBoard(
	parent: Instance,
	centerPos: Vector3,
	facingDir: Vector3,
	size: Vector2,
	titleText: string,
	subText: string?,
	bgColor: Color3,
	accentColor: Color3
): Part
	local dir = if facingDir.Magnitude > 0.001 then facingDir.Unit else Vector3.new(0, 0, 1)
	local board = CityUtils.makePart({
		Name = "SignBoard_" .. titleText,
		Size = Vector3.new(size.X, size.Y, 0.45),
		CFrame = CFrame.lookAt(centerPos, centerPos + dir),
		Color = bgColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = parent,
	})

	-- Viền đèn neon xung quanh bảng hiệu
	CityUtils.makePart({
		Name = "SignNeonTrim",
		Size = Vector3.new(size.X + 0.3, size.Y + 0.3, 0.25),
		CFrame = board.CFrame * CFrame.new(0, 0, 0.12),
		Color = accentColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parent,
	})

	local sgui = Instance.new("SurfaceGui")
	sgui.Face = Enum.NormalId.Front
	sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sgui.PixelsPerStud = 36
	sgui.LightInfluence = 0.15
	sgui.Brightness = 1.6
	sgui.Parent = board

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = sgui

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = if subText and subText ~= "" then UDim2.fromScale(0.94, 0.62) else UDim2.fromScale(0.94, 0.84)
	title.Position = if subText and subText ~= "" then UDim2.fromScale(0.03, 0.06) else UDim2.fromScale(0.03, 0.08)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeColor3 = accentColor
	title.TextStrokeTransparency = 0.55
	title.Text = titleText
	title.Parent = frame

	if subText and subText ~= "" then
		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.Size = UDim2.fromScale(0.92, 0.28)
		sub.Position = UDim2.fromScale(0.04, 0.66)
		sub.Font = Enum.Font.GothamBold
		sub.TextScaled = true
		sub.TextColor3 = accentColor
		sub.Text = subText
		sub.Parent = frame
	end

	return board
end

function CityUtils.addPrompt(
	parent: Instance,
	actionType: string,
	actionText: string,
	objectText: string,
	maxDist: number?,
	attrs: { [string]: any }?
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CityPrompt_" .. actionType
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = maxDist or 11
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt:SetAttribute("ActionType", actionType)
	if attrs then
		for k, v in pairs(attrs) do
			prompt:SetAttribute(k, v)
		end
	end
	prompt.Parent = parent
	CollectionService:AddTag(prompt, CityConfig.PromptTag)
	return prompt
end

function CityUtils.buildStreetLamp(parent: Instance, basePos: Vector3, armDir: Vector3)
	local model = Instance.new("Model")
	model.Name = "StreetLamp"
	model.Parent = parent

	local dir = if armDir.Magnitude > 0.01 then Vector3.new(armDir.X, 0, armDir.Z).Unit else Vector3.new(1, 0, 0)
	local baseCf = CFrame.lookAt(basePos, basePos + dir)

	CityUtils.makePart({
		Name = "Pedestal",
		Size = Vector3.new(1.4, 1.4, 1.4),
		CFrame = baseCf * CFrame.new(0, 0.7, 0),
		Color = Color3.fromRGB(48, 52, 62),
		Material = Enum.Material.Metal,
		Parent = model,
	})

	CityUtils.makePart({
		Name = "Pole",
		Size = Vector3.new(0.55, 15, 0.55),
		CFrame = baseCf * CFrame.new(0, 8.5, 0),
		Color = Color3.fromRGB(58, 64, 76),
		Material = Enum.Material.Metal,
		Parent = model,
	})

	CityUtils.makePart({
		Name = "Arm",
		Size = Vector3.new(0.45, 0.45, 4.2),
		CFrame = baseCf * CFrame.new(0, 15.8, -1.8),
		Color = Color3.fromRGB(58, 64, 76),
		Material = Enum.Material.Metal,
		Parent = model,
	})

	CityUtils.makePart({
		Name = "Hood",
		Size = Vector3.new(1.5, 0.35, 2.2),
		CFrame = baseCf * CFrame.new(0, 15.95, -3.4),
		Color = Color3.fromRGB(42, 46, 56),
		Material = Enum.Material.Metal,
		Parent = model,
	})

	local bulb = CityUtils.makePart({
		Name = "Bulb",
		Size = Vector3.new(1.15, 0.25, 1.75),
		CFrame = baseCf * CFrame.new(0, 15.7, -3.4),
		Color = Color3.fromRGB(255, 232, 185),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})

	local light = Instance.new("SpotLight")
	light.Name = "StreetLightEmitter"
	light.Face = Enum.NormalId.Bottom
	light.Angle = 115
	light.Range = 42
	light.Brightness = 1.9
	light.Color = Color3.fromRGB(255, 228, 180)
	light.Shadows = false
	light.Parent = bulb

	CollectionService:AddTag(bulb, CityConfig.StreetLightTag)
	return model
end

function CityUtils.buildTrafficLight(parent: Instance, basePos: Vector3, roadDir: Vector3, axisName: string)
	local model = Instance.new("Model")
	model.Name = "TrafficLight_" .. axisName
	model:SetAttribute("Axis", axisName)
	model.Parent = parent

	local dir = Vector3.new(roadDir.X, 0, roadDir.Z).Unit
	local baseCf = CFrame.lookAt(basePos, basePos + dir)

	CityUtils.makePart({
		Name = "Post",
		Size = Vector3.new(0.7, 15.5, 0.7),
		CFrame = baseCf * CFrame.new(0, 7.75, 0),
		Color = Color3.fromRGB(45, 48, 56),
		Material = Enum.Material.Metal,
		Parent = model,
	})

	-- Tay vươn ngang ra mặt đường
	CityUtils.makePart({
		Name = "Cantilever",
		Size = Vector3.new(7.5, 0.5, 0.5),
		CFrame = baseCf * CFrame.new(3.5, 14.8, 0),
		Color = Color3.fromRGB(45, 48, 56),
		Material = Enum.Material.Metal,
		Parent = model,
	})

	local box = CityUtils.makePart({
		Name = "SignalBox",
		Size = Vector3.new(1.5, 3.8, 1.1),
		CFrame = baseCf * CFrame.new(6.2, 13.5, 0),
		Color = Color3.fromRGB(26, 28, 34),
		Material = Enum.Material.Metal,
		Parent = model,
	})

	local colors = {
		{ name = "Red", offset = 1.1, onColor = Color3.fromRGB(255, 50, 50), offColor = Color3.fromRGB(70, 22, 22) },
		{ name = "Yellow", offset = 0, onColor = Color3.fromRGB(255, 205, 40), offColor = Color3.fromRGB(75, 62, 18) },
		{ name = "Green", offset = -1.1, onColor = Color3.fromRGB(45, 245, 110), offColor = Color3.fromRGB(18, 68, 34) },
	}

	for _, c in ipairs(colors) do
		local lens = CityUtils.makePart({
			Name = c.name,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.85, 0.85, 0.85),
			CFrame = box.CFrame * CFrame.new(0, c.offset, -0.42),
			Color = if (axisName == "NS" and c.name == "Green") or (axisName == "EW" and c.name == "Red")
				then c.onColor
				else c.offColor,
			Material = if (axisName == "NS" and c.name == "Green") or (axisName == "EW" and c.name == "Red")
				then Enum.Material.Neon
				else Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = model,
		})
		lens:SetAttribute("OnColor", c.onColor)
		lens:SetAttribute("OffColor", c.offColor)
	end

	CollectionService:AddTag(model, CityConfig.TrafficLightTag)
	return model
end

function CityUtils.buildTree(parent: Instance, basePos: Vector3, leafColor: Color3?, scale: number?)
	local s = scale or 1
	local model = Instance.new("Model")
	model.Name = "CityTree"
	model.Parent = parent

	-- Bồn cây bằng đá
	CityUtils.makePart({
		Name = "PlanterRim",
		Size = Vector3.new(5.2 * s, 1.1, 5.2 * s),
		Position = basePos + Vector3.new(0, 0.55, 0),
		Color = Color3.fromRGB(145, 148, 156),
		Material = Enum.Material.Concrete,
		Parent = model,
	})
	CityUtils.makePart({
		Name = "Soil",
		Size = Vector3.new(4.4 * s, 1.18, 4.4 * s),
		Position = basePos + Vector3.new(0, 0.58, 0),
		Color = Color3.fromRGB(86, 62, 44),
		Material = Enum.Material.Ground,
		Parent = model,
	})

	CityUtils.makePart({
		Name = "Trunk",
		Size = Vector3.new(1.5 * s, 7.5 * s, 1.5 * s),
		Position = basePos + Vector3.new(0, 4.2 * s, 0),
		Color = Color3.fromRGB(108, 76, 52),
		Material = Enum.Material.Wood,
		Parent = model,
	})

	local mainLeaf = leafColor or Color3.fromRGB(68, 152, 82)
	CityUtils.makePart({
		Name = "CanopyMain",
		Size = Vector3.new(8.2 * s, 5.4 * s, 8.2 * s),
		Position = basePos + Vector3.new(0, 9.2 * s, 0),
		Color = mainLeaf,
		Material = Enum.Material.Grass,
		Parent = model,
	})
	CityUtils.makePart({
		Name = "CanopyTop",
		Size = Vector3.new(5.6 * s, 3.8 * s, 5.6 * s),
		Position = basePos + Vector3.new(0.4 * s, 12.2 * s, -0.3 * s),
		Color = mainLeaf:Lerp(Color3.fromRGB(190, 245, 160), 0.16),
		Material = Enum.Material.Grass,
		Parent = model,
	})
	return model
end

function CityUtils.buildBench(parent: Instance, centerPos: Vector3, facingDir: Vector3)
	local model = Instance.new("Model")
	model.Name = "ParkBench"
	model.Parent = parent

	local cf = CFrame.lookAt(centerPos, centerPos + Vector3.new(facingDir.X, 0, facingDir.Z).Unit)

	CityUtils.makePart({
		Name = "SeatPlank",
		Size = Vector3.new(6.2, 0.4, 2.0),
		CFrame = cf * CFrame.new(0, 1.6, 0),
		Color = Color3.fromRGB(150, 102, 62),
		Material = Enum.Material.WoodPlanks,
		Parent = model,
	})
	CityUtils.makePart({
		Name = "Backrest",
		Size = Vector3.new(6.2, 1.8, 0.35),
		CFrame = cf * CFrame.new(0, 2.6, 0.85) * CFrame.Angles(math.rad(10), 0, 0),
		Color = Color3.fromRGB(140, 94, 56),
		Material = Enum.Material.WoodPlanks,
		Parent = model,
	})
	for _, xOff in ipairs({ -2.6, 2.6 }) do
		CityUtils.makePart({
			Name = "Leg",
			Size = Vector3.new(0.4, 1.6, 1.9),
			CFrame = cf * CFrame.new(xOff, 0.8, 0),
			Color = Color3.fromRGB(45, 48, 56),
			Material = Enum.Material.Metal,
			Parent = model,
		})
	end

	-- 2 chỗ ngồi thực tế
	for _, xSeat in ipairs({ -1.5, 1.5 }) do
		local seat = Instance.new("Seat")
		seat.Name = "BenchSeat"
		seat.Anchored = true
		seat.Size = Vector3.new(2.2, 0.4, 1.8)
		seat.Transparency = 1
		seat.CFrame = cf * CFrame.new(xSeat, 1.8, 0)
		seat.Parent = model
	end
	return model
end

function CityUtils.buildCitizenNpc(
	parent: Instance,
	feetPos: Vector3,
	facingDir: Vector3,
	npcId: string,
	displayName: string,
	shirtColor: Color3,
	pantsColor: Color3
): Model
	local npc = Instance.new("Model")
	npc.Name = "NPC_" .. npcId
	npc:SetAttribute("NpcId", npcId)
	npc.Parent = parent

	local cf = CFrame.lookAt(feetPos, feetPos + Vector3.new(facingDir.X, 0, facingDir.Z).Unit)

	local torso = CityUtils.makePart({
		Name = "Torso",
		Size = Vector3.new(2, 2, 1),
		CFrame = cf * CFrame.new(0, 3, 0),
		Color = shirtColor,
		Parent = npc,
	})
	npc.PrimaryPart = torso

	local head = CityUtils.makePart({
		Name = "Head",
		Size = Vector3.new(1.25, 1.25, 1.25),
		CFrame = cf * CFrame.new(0, 4.65, 0),
		Color = Color3.fromRGB(245, 205, 172),
		Parent = npc,
	})
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.2, 1.2, 1.2)
	headMesh.Parent = head

	-- Tóc / mũ cách điệu
	CityUtils.makePart({
		Name = "Hair",
		Size = Vector3.new(1.4, 0.55, 1.4),
		CFrame = cf * CFrame.new(0, 5.2, 0.05),
		Color = Color3.fromRGB(42, 34, 30),
		Parent = npc,
	})

	for _, xArm in ipairs({ -1.5, 1.5 }) do
		CityUtils.makePart({
			Name = "Arm",
			Size = Vector3.new(1, 2, 1),
			CFrame = cf * CFrame.new(xArm, 3, 0),
			Color = Color3.fromRGB(245, 205, 172),
			Parent = npc,
		})
	end
	for _, xLeg in ipairs({ -0.5, 0.5 }) do
		CityUtils.makePart({
			Name = "Leg",
			Size = Vector3.new(1, 2, 1),
			CFrame = cf * CFrame.new(xLeg, 1, 0),
			Color = pantsColor,
			Parent = npc,
		})
	end

	-- Bảng tên trên đầu NPC
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(190, 42)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 48
	bb.AlwaysOnTop = false
	bb.Parent = head

	local tagBg = Instance.new("Frame")
	tagBg.Size = UDim2.fromScale(1, 1)
	tagBg.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	tagBg.BackgroundTransparency = 0.2
	tagBg.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = tagBg

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(0.92, 0.85)
	lbl.Position = UDim2.fromScale(0.04, 0.07)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(255, 240, 175)
	lbl.Text = "💬 " .. displayName
	lbl.Parent = tagBg

	CityUtils.addPrompt(torso, "NpcTalk", "Trò chuyện", displayName, 11, {
		NpcId = npcId,
	})

	CollectionService:AddTag(npc, CityConfig.NpcTag)
	return npc
end

function CityUtils.buildVehicleModel(
	parent: Instance,
	spawnCf: CFrame,
	bodyColor: Color3,
	carName: string?
): Model
	local car = Instance.new("Model")
	car.Name = carName or "CitySportsCar"
	car.Parent = parent

	-- Khung gầm chính (Chassis) có độ hở gầm hợp lý để leo vỉa hè mượt mà
	local chassis = CityUtils.makePart({
		Name = "Chassis",
		Size = Vector3.new(6.8, 1.5, 13.6),
		CFrame = spawnCf * CFrame.new(0, 2.0, 0),
		Color = bodyColor,
		Material = Enum.Material.SmoothPlastic,
		Reflectance = 0.15,
		Parent = car,
	})
	car.PrimaryPart = chassis

	-- Mui xe thuôn khí động học
	CityUtils.makeWedge({
		Name = "FrontHoodSlope",
		Size = Vector3.new(6.6, 1.0, 3.6),
		CFrame = chassis.CFrame * CFrame.new(0, 1.1, -4.8),
		Color = bodyColor,
		CanCollide = false,
		Parent = car,
	})

	CityUtils.makePart({
		Name = "CabinGlass",
		Size = Vector3.new(5.8, 2.0, 6.2),
		CFrame = chassis.CFrame * CFrame.new(0, 1.65, 0.4),
		Color = Color3.fromRGB(35, 48, 68),
		Material = Enum.Material.Glass,
		Transparency = 0.35,
		CanCollide = false,
		Parent = car,
	})

	CityUtils.makePart({
		Name = "Roof",
		Size = Vector3.new(5.5, 0.3, 4.6),
		CFrame = chassis.CFrame * CFrame.new(0, 2.7, 0.6),
		Color = bodyColor,
		CanCollide = false,
		Parent = car,
	})

	-- Cánh gió thể thao phía sau
	CityUtils.makePart({
		Name = "SpoilerWing",
		Size = Vector3.new(6.4, 0.25, 1.2),
		CFrame = chassis.CFrame * CFrame.new(0, 1.55, 6.1),
		Color = Color3.fromRGB(28, 30, 38),
		Material = Enum.Material.Metal,
		CanCollide = false,
		Parent = car,
	})

	-- Đèn pha trước + SpotLight chiếu đường ban đêm
	for _, xSide in ipairs({ -2.2, 2.2 }) do
		local headlight = CityUtils.makePart({
			Name = "Headlight",
			Size = Vector3.new(1.4, 0.45, 0.25),
			CFrame = chassis.CFrame * CFrame.new(xSide, 0.15, -6.78),
			Color = Color3.fromRGB(255, 250, 220),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = car,
		})
		local beam = Instance.new("SpotLight")
		beam.Face = Enum.NormalId.Front
		beam.Angle = 75
		beam.Range = 48
		beam.Brightness = 2.2
		beam.Color = Color3.fromRGB(255, 248, 220)
		beam.Parent = headlight
	end

	-- Dải đèn hậu LED đỏ
	CityUtils.makePart({
		Name = "TaillightBar",
		Size = Vector3.new(6.0, 0.38, 0.22),
		CFrame = chassis.CFrame * CFrame.new(0, 0.25, 6.78),
		Color = Color3.fromRGB(255, 35, 50),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = car,
	})

	-- 4 bánh xe chi tiết
	local wheelOffsets = {
		Vector3.new(-3.35, -0.65, -4.2),
		Vector3.new(3.35, -0.65, -4.2),
		Vector3.new(-3.35, -0.65, 4.2),
		Vector3.new(3.35, -0.65, 4.2),
	}
	for idx, wOff in ipairs(wheelOffsets) do
		CityUtils.makePart({
			Name = "Wheel_" .. tostring(idx),
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.1, 2.5, 2.5),
			CFrame = chassis.CFrame * CFrame.new(wOff) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(24, 26, 30),
			Material = Enum.Material.Rubber,
			CanCollide = false,
			Parent = car,
		})
		CityUtils.makePart({
			Name = "Rim_" .. tostring(idx),
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.16, 1.4, 1.4),
			CFrame = chassis.CFrame * CFrame.new(wOff) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(210, 218, 230),
			Material = Enum.Material.Metal,
			CanCollide = false,
			Parent = car,
		})
	end

	-- Ghế lái chính (VehicleSeat) + ghế phụ (Seat)
	local driverSeat = Instance.new("VehicleSeat")
	driverSeat.Name = "DriverSeat"
	driverSeat.Anchored = true
	driverSeat.Size = Vector3.new(2.2, 0.6, 2.2)
	driverSeat.MaxSpeed = 68
	driverSeat.Torque = 25000
	driverSeat.TurnSpeed = 2.1
	driverSeat.HeadsUpDisplay = false
	driverSeat.Color = Color3.fromRGB(32, 34, 42)
	driverSeat.CFrame = chassis.CFrame * CFrame.new(-1.35, 0.55, 0.2)
	driverSeat.Parent = car

	local passengerSeat = Instance.new("Seat")
	passengerSeat.Name = "PassengerSeat"
	passengerSeat.Anchored = true
	passengerSeat.Size = Vector3.new(2.2, 0.6, 2.2)
	passengerSeat.Color = Color3.fromRGB(32, 34, 42)
	passengerSeat.CFrame = chassis.CFrame * CFrame.new(1.35, 0.55, 0.2)
	passengerSeat.Parent = car

	CollectionService:AddTag(car, CityConfig.VehicleTag)
	return car
end

return CityUtils
