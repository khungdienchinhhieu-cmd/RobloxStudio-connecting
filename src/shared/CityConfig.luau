--!strict

local CityConfig = {}

CityConfig.CityFolderName = "InteractiveCity"
CityConfig.PromptTag = "CityInteractivePrompt"
CityConfig.StreetLightTag = "CityStreetLight"
CityConfig.TrafficLightTag = "CityTrafficLight"
CityConfig.VehicleTag = "CityDrivableVehicle"
CityConfig.WindowGlowTag = "CityNightWindow"
CityConfig.NpcTag = "CityCitizenNpc"

CityConfig.StartingCash = 300

CityConfig.Items = {
	CaPheSuaDa = {
		id = "CaPheSuaDa",
		name = "Cà Phê Sữa Đá",
		price = 25,
		speedBoost = 24,
		duration = 30,
		color = Color3.fromRGB(130, 82, 45),
		desc = "Tăng tốc độ chạy lên 24 trong 30 giây!",
	},
	TraDaoCamSa = {
		id = "TraDaoCamSa",
		name = "Trà Đào Cam Sả",
		price = 30,
		speedBoost = 26,
		duration = 35,
		color = Color3.fromRGB(245, 145, 55),
		desc = "Hồi đầy máu & tăng tốc độ chạy lên 26!",
	},
	NuocTangLuc = {
		id = "NuocTangLuc",
		name = "Nước Tăng Lực Neon",
		price = 45,
		speedBoost = 30,
		duration = 40,
		color = Color3.fromRGB(0, 225, 255),
		desc = "Siêu tốc độ 30 trong 40 giây!",
	},
}

CityConfig.DeliveryTargets = {
	{
		id = "SkyTowerLobby",
		name = "Sảnh Tháp Tài Chính SkyTower",
		position = Vector3.new(-68, 4, -68),
		reward = 95,
	},
	{
		id = "NeoBank",
		name = "Ngân Hàng Neo Bank",
		position = Vector3.new(-42, 4, -30),
		reward = 80,
	},
	{
		id = "VipApartment",
		name = "Chung Cư Cao Cấp Lumina",
		position = Vector3.new(82, 4, -84),
		reward = 90,
	},
	{
		id = "CyberArcade",
		name = "Trung Tâm Giải Trí Cyber Arcade",
		position = Vector3.new(54, 4, 42),
		reward = 85,
	},
	{
		id = "AutoGarage",
		name = "Showroom Xe Auto Metro",
		position = Vector3.new(96, 4, 74),
		reward = 100,
	},
	{
		id = "HarborPier",
		name = "Bến Cảng Ngắm Biển Phía Nam",
		position = Vector3.new(0, 4, 195),
		reward = 120,
	},
}

CityConfig.Districts = {
	{
		name = "Quảng Trường & Công Viên Ánh Sáng",
		min = Vector3.new(-140, -20, 16),
		max = Vector3.new(-16, 200, 140),
	},
	{
		name = "Khu Tài Chính & Tháp SkyTower",
		min = Vector3.new(-140, -20, -140),
		max = Vector3.new(-16, 300, -16),
	},
	{
		name = "Phố Ẩm Thực & Thương Mại",
		min = Vector3.new(16, -20, -140),
		max = Vector3.new(140, 200, -16),
	},
	{
		name = "Khu Giải Trí Cyber & Auto Garage",
		min = Vector3.new(16, -20, 16),
		max = Vector3.new(140, 200, 140),
	},
	{
		name = "Bến Cảng & Phố Đi Bộ Ven Biển",
		min = Vector3.new(-240, -20, 164),
		max = Vector3.new(240, 200, 260),
	},
	{
		name = "Trạm Xăng & Bãi Đỗ Xe Phía Tây",
		min = Vector3.new(-240, -20, -164),
		max = Vector3.new(-164, 200, 164),
	},
	{
		name = "Bệnh Viện & Trung Tâm Hành Chính",
		min = Vector3.new(164, -20, -164),
		max = Vector3.new(240, 200, 164),
	},
}

CityConfig.NpcDialogues = {
	LinhGuide = {
		title = "Linh — Hướng Dẫn Viên Thành Phố",
		lines = {
			"Chào mừng bạn đến Thành Phố Ánh Sáng! Mọi tòa nhà quanh đây đều có thể tương tác đấy.",
			"Bạn có thể ghé Pizza Hot nhận việc giao hàng kiếm tiền, ra Auto Garage gọi xe hơi lái dạo phố, hoặc đi thang máy lên đỉnh SkyTower ngắm toàn cảnh!",
		},
	},
	MinhBarista = {
		title = "Minh — Pha Chế Saigon Chill",
		lines = {
			"Quán mình có Cà Phê Sữa Đá và Trà Đào Cam Sả pha nóng lạnh tại quầy!",
			"Mua một ly uống vào là chạy bộ quanh thành phố nhanh cực kỳ luôn nhé!",
		},
	},
	HungPizza = {
		title = "Hùng — Quản Lý Pizza Hot 24/7",
		lines = {
			"Đơn hàng trong thành phố đang nổ liên tục! Bấm nhận giao bánh ngay quầy để nhận thưởng $80 - $120 mỗi chuyến nhé!",
		},
	},
	LanBanker = {
		title = "Lan — Giao Dịch Viên Neo Bank",
		lines = {
			"Chào quý khách! Bạn có thể ghé cây ATM bên cạnh để nhận trợ cấp công dân $150 mỗi vài phút hoàn toàn miễn phí.",
		},
	},
	KhoaMechanic = {
		title = "Khoa — Kỹ Sư Auto Metro",
		lines = {
			"Muốn lướt phố nhanh? Bấm vào Bảng Gọi Xe ngay cửa Garage để nhận chiếc xe thể thao miễn phí, dùng phím W/A/S/D để lái nhé!",
		},
	},
}

return CityConfig
