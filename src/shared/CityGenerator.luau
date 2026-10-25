--!strict

local Lighting = game:GetService("Lighting")
local CityConfig = require(script.Parent:WaitForChild("CityConfig"))
local CityUtils = require(script.Parent:WaitForChild("CityUtils"))
local RoadsAndPark = require(script.Parent:WaitForChild("Districts"):WaitForChild("RoadsAndPark"))
local Buildings = require(script.Parent:WaitForChild("Districts"):WaitForChild("Buildings"))

local CityGenerator = {}

function CityGenerator.configureLighting()
	Lighting.ClockTime = 17.8 -- Hoàng hôn rực rỡ chuẩn bị lên đèn neon
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(58, 64, 88)
	Lighting.OutdoorAmbient = Color3.fromRGB(95, 102, 132)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.85
	Lighting.EnvironmentSpecularScale = 0.9

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:GetAttribute("__ArenaCityEffect") == true then
			child:Destroy()
		end
	end

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "CityAtmosphere"
	atmo.Density = 0.28
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(255, 205, 175)
	atmo.Decay = Color3.fromRGB(110, 92, 145)
	atmo.Glare = 0.25
	atmo.Haze = 1.4
	atmo:SetAttribute("__ArenaCityEffect", true)
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "CityNeonBloom"
	bloom.Intensity = 0.65
	bloom.Size = 24
	bloom.Threshold = 1.15
	bloom:SetAttribute("__ArenaCityEffect", true)
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "CityColorGrade"
	cc.Contrast = 0.08
	cc.Saturation = 0.14
	cc.Brightness = 0.02
	cc:SetAttribute("__ArenaCityEffect", true)
	cc.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "CitySunRays"
	sunRays.Intensity = 0.12
	sunRays.Spread = 0.75
	sunRays:SetAttribute("__ArenaCityEffect", true)
	sunRays.Parent = Lighting
end

function CityGenerator.buildCity(forceRebuild: boolean?): Folder
	local existing = workspace:FindFirstChild(CityConfig.CityFolderName)
	if existing then
		if forceRebuild then
			existing:Destroy()
		elseif existing:IsA("Folder") then
			return existing
		end
	end

	-- Ẩn Baseplate mặc định của Studio để không đè mặt nước biển & mặt đường
	local defaultBaseplate = workspace:FindFirstChild("Baseplate")
	if defaultBaseplate and defaultBaseplate:IsA("BasePart") then
		defaultBaseplate.Transparency = 1
		defaultBaseplate.CanCollide = false
	end

	-- Tắt SpawnLocation mặc định ngoài thành phố nếu có
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("SpawnLocation") then
			child.Enabled = false
			child.Transparency = 1
			child.CanCollide = false
		end
	end

	local cityRoot = Instance.new("Folder")
	cityRoot.Name = CityConfig.CityFolderName
	cityRoot.Parent = workspace

	CityGenerator.configureLighting()
	RoadsAndPark.build(cityRoot)
	Buildings.build(cityRoot)

	-- ========================================================================
	-- ĐẶT CƯ DÂN NPC TƯƠNG TÁC TẠI CÁC ĐỊA ĐIỂM CHÍNH
	-- ========================================================================
	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "Citizens"
	npcFolder.Parent = cityRoot

	CityUtils.buildCitizenNpc(
		npcFolder,
		Vector3.new(-22, 1.4, 26),
		Vector3.new(-1, 0, 1),
		"LinhGuide",
		"Linh (Hướng dẫn viên)",
		Color3.fromRGB(56, 189, 248),
		Color3.fromRGB(30, 41, 59)
	)
	CityUtils.buildCitizenNpc(
		npcFolder,
		Vector3.new(46, 1.5, -46.5),
		Vector3.new(0, 0, 1),
		"MinhBarista",
		"Minh (Barista Cafe)",
		Color3.fromRGB(180, 83, 9),
		Color3.fromRGB(41, 37, 36)
	)
	CityUtils.buildCitizenNpc(
		npcFolder,
		Vector3.new(96, 1.5, -46.5),
		Vector3.new(0, 0, 1),
		"HungPizza",
		"Hùng (Quản lý Giao hàng)",
		Color3.fromRGB(220, 38, 38),
		Color3.fromRGB(31, 41, 55)
	)
	CityUtils.buildCitizenNpc(
		npcFolder,
		Vector3.new(-42, 1.5, -47.5),
		Vector3.new(0, 0, 1),
		"LanBanker",
		"Lan (Giao dịch viên)",
		Color3.fromRGB(16, 185, 129),
		Color3.fromRGB(30, 41, 59)
	)
	CityUtils.buildCitizenNpc(
		npcFolder,
		Vector3.new(102, 1.5, 74),
		Vector3.new(0, 0, -1),
		"KhoaMechanic",
		"Khoa (Kỹ sư Xe)",
		Color3.fromRGB(249, 115, 22),
		Color3.fromRGB(30, 41, 59)
	)

	-- ========================================================================
	-- ĐẶT SẴN XE HƠI LÁI ĐƯỢC NGAY TRÊN ĐẠI LỘ TRUNG TÂM & GARAGE
	-- ========================================================================
	local vehiclesFolder = Instance.new("Folder")
	vehiclesFolder.Name = "Vehicles"
	vehiclesFolder.Parent = cityRoot

	-- Xe thể thao đỏ đậu ngay gần Quảng Trường Spawn để lên xe lái liền!
	CityUtils.buildVehicleModel(
		vehiclesFolder,
		CFrame.lookAt(Vector3.new(-8, 0.5, 42), Vector3.new(-8, 0.5, -10)),
		Color3.fromRGB(225, 38, 52),
		"StarterSportsCar_Red"
	)

	-- Siêu xe xanh neon trước Auto Metro Garage
	CityUtils.buildVehicleModel(
		vehiclesFolder,
		CFrame.lookAt(Vector3.new(82, 0.5, 8), Vector3.new(120, 0.5, 8)),
		Color3.fromRGB(14, 165, 233),
		"GarageCyberCar_Cyan"
	)

	-- Xe vàng thể thao trước khu Tài Chính
	CityUtils.buildVehicleModel(
		vehiclesFolder,
		CFrame.lookAt(Vector3.new(-58, 0.5, -8), Vector3.new(10, 0.5, -8)),
		Color3.fromRGB(245, 180, 25),
		"FinanceCruiser_Gold"
	)

	return cityRoot
end

return CityGenerator
