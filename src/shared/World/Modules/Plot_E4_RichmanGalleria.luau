--!strict
--[[
	Plot_E4_RichmanGalleria.luau  (Sync v27 — vòng quét V6, Agent A)
	================================================================================
	RICHMAN GALLERIA — trung tâm thương mại hạng sang 3 tầng + giếng trời kính
	Ô đất   : Plot_E4 (Richman Glen)  X 358…536 · Z −12…128 · nền Y = 1,15
	Mặt tiền: Nam (+Z, Z = 110) nhìn ra Vespucci Blvd (Z = 148)

	Chức năng: quầy `E4_MALL` (ARMOR $350, mua giáp chống đạn) tự dựng trước
	sảnh chính khi module này được nạp.

	KIẾN TRÚC
	  • Tầng trệt 16 stud: sảnh giếng trời, đài phun nước đá hoa cương, 8 gian hàng
	    (trang sức, đồng hồ, túi xách, nước hoa, kính mát, giày, vest, điện thoại),
	    quầy lễ tân, 2 thang cuốn lên tầng 2.
	  • Tầng 2 (Y 18,50): 10 gian hàng vách kính, hành lang bao quanh giếng trời,
	    lan can kính, 2 thang cuốn lên tầng 3.
	  • Tầng 3 (Y 32,70): khu ăn uống 12 bàn + sân thượng ngắm thành phố,
	    giếng trời kính hình vòm (3 vòng), 4 quạt trần lớn.
	  • Mặt tiền: 3 tầng kính cong, cột đá trắng, biển "RICHMAN GALLERIA" neon,
	    mái đua kính, 6 cột cờ.
	  • Sân trước: thảm đỏ + bồn nước + 6 cọ + 4 ghế đá + trạm valet.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local K = require(Shared:WaitForChild("World"):WaitForChild("BuildKit"))

local Module = {
	Id = "Plot_E4_RichmanGalleria",
	PlotId = "Plot_E4",
	Order = 64,
	Enabled = true,
}

local M = Enum.Material
local G = K.GROUND
local SPM = K.STUDS_PER_METER

local C = {
	STONE = Color3.fromRGB(232, 228, 220),
	STONE_D = Color3.fromRGB(190, 186, 176),
	MARBLE = Color3.fromRGB(244, 242, 238),
	GRANITE = Color3.fromRGB(58, 60, 66),
	BRASS = Color3.fromRGB(206, 172, 96),
	BRASS_D = Color3.fromRGB(150, 122, 60),
	GLASS = Color3.fromRGB(158, 200, 212),
	GLASS_D = Color3.fromRGB(96, 132, 148),
	FRAME = Color3.fromRGB(70, 74, 82),
	NEON = Color3.fromRGB(120, 220, 255),
	NEON2 = Color3.fromRGB(255, 214, 132),
	WATER = Color3.fromRGB(96, 168, 200),
	WOOD = Color3.fromRGB(146, 108, 70),
	WOOD_D = Color3.fromRGB(96, 68, 44),
	DARK = Color3.fromRGB(38, 40, 46),
	LEAF = Color3.fromRGB(76, 132, 82),
	SEAT = Color3.fromRGB(180, 168, 150),
	RED = Color3.fromRGB(146, 40, 52),
}

local BX0, BX1 = 372, 520
local BZ0, BZ1 = 8, 96 -- chừa 32 stud sân trước (96…128)
local CX, CZ = (BX0 + BX1) * 0.5, (BZ0 + BZ1) * 0.5
local FLOOR = G + 0.15
local H1, SLAB = 16.0, 1.2
local Y2 = FLOOR + H1 + SLAB
local H2 = 13.0
local Y3 = Y2 + H2 + SLAB
local H3 = 12.0
local Y_ROOF = Y3 + H3 + SLAB
local WT = 1.6

local ATRIUM_X0, ATRIUM_X1 = CX - 26, CX + 26
local ATRIUM_Z0, ATRIUM_Z1 = CZ - 22, CZ + 22

local function buildShell(f: Instance): number
	local grp = "MallShell"
	local made = 0
	K.box(f, "BaseSlab", Vector3.new(BX1 - BX0 + 0.4, FLOOR - G, BZ1 - BZ0 + 0.4),
		Vector3.new(CX, (G + FLOOR) * 0.5, CZ), C.GRANITE, M.Concrete, nil, grp, 1, { canCollide = true })
	made += 1
	made += K.tileField(f, "MarbleFloor", BX0 + 1, BX1 - 1, BZ0 + 1, BZ1 - 1, FLOOR, 4.4, 130,
		C.MARBLE, C.STONE, grp, 0.14)

	-- tường 3 tầng, mặt Nam mở 5 vịnh kính lớn
	local southOpen = {}
	for i = 1, 5 do
		local a = BX0 + 6 + (i - 1) * ((BX1 - BX0 - 12) / 5)
		table.insert(southOpen, { a = a + 1.2, b = a + (BX1 - BX0 - 12) / 5 - 1.2, y0 = FLOOR + 1.2, y1 = FLOOR + 14.2 })
	end
	made += K.wall(f, "SouthWall", "X", BZ1 - WT * 0.5, BX0, BX1, FLOOR, Y_ROOF, WT,
		C.STONE, M.Concrete, 320, grp, southOpen)
	made += K.wall(f, "NorthWall", "X", BZ0 + WT * 0.5, BX0, BX1, FLOOR, Y_ROOF, WT,
		C.STONE_D, M.Concrete, 320, grp, nil)
	made += K.wall(f, "WestWall", "Z", BX0 + WT * 0.5, BZ0, BZ1, FLOOR, Y_ROOF, WT,
		C.STONE_D, M.Concrete, 320, grp, {
			{ a = 30, b = 46, y0 = FLOOR + 2, y1 = FLOOR + 12 },
			{ a = 30, b = 46, y0 = Y2 + 2, y1 = Y2 + 10 },
		})
	made += K.wall(f, "EastWall", "Z", BX1 - WT * 0.5, BZ0, BZ1, FLOOR, Y_ROOF, WT,
		C.STONE_D, M.Concrete, 320, grp, {
			{ a = 76, b = 92, y0 = FLOOR + 2, y1 = FLOOR + 12 },
			{ a = 76, b = 92, y0 = Y2 + 2, y1 = Y2 + 10 },
		})

	made += K.curtain(f, "FrontGlassW", "X", BZ1 - 0.5, BX0 + 6, CX - 12, FLOOR + 1.2, FLOOR + 14.2,
		10, 3, C.GLASS, C.FRAME, 42, "FrontGlass")
	made += K.curtain(f, "FrontGlassE", "X", BZ1 - 0.5, CX + 12, BX1 - 6, FLOOR + 1.2, FLOOR + 14.2,
		10, 3, C.GLASS, C.FRAME, 42, "FrontGlass")

	-- cửa xoay chính (3 lá, không va chạm)
	for i = 1, 3 do
		local ang = math.rad(i * 60)
		K.rbox(f, "RevolvingDoor_" .. i, Vector3.new(0.3, 9.6, 8.4),
			CFrame.new(CX, FLOOR + 4.8, BZ1 - 0.6) * CFrame.Angles(0, ang, 0), C.GLASS, M.Glass, 40, "MainDoor", 1,
			{ canCollide = false, castShadow = false, transparency = 0.25 })
		made += 1
	end
	K.cyl(f, "RevolvingPost", Vector3.new(9.8, 0.5, 0.5), Vector3.new(CX, FLOOR + 4.9, BZ1 - 0.6),
		C.BRASS, M.Metal, 90, "MainDoor", 2)
	made += 1
	return made
end

local function buildLevel1(f: Instance): number
	local made = 0
	local grp = "MallL1"
	-- đài phun nước đá hoa cương giữa sảnh
	K.cyl(f, "FountainBase", Vector3.new(1.4, 26, 26), Vector3.new(CX, FLOOR + 0.7, CZ),
		C.GRANITE, M.Marble, 200, "Fountain", 1)
	K.cyl(f, "FountainWater", Vector3.new(0.6, 23, 23), Vector3.new(CX, FLOOR + 1.45, CZ),
		C.WATER, M.Glass, 40, "Fountain", 2, { canCollide = false, castShadow = false, transparency = 0.25 })
	K.cyl(f, "FountainPillar", Vector3.new(9, 3.4, 3.4), Vector3.new(CX, FLOOR + 5.5, CZ),
		C.MARBLE, M.Marble, 120, "Fountain", 2)
	K.cyl(f, "FountainBowl", Vector3.new(1.0, 11, 11), Vector3.new(CX, FLOOR + 10.2, CZ),
		C.MARBLE, M.Marble, 90, "Fountain", 3, { canCollide = false })
	K.cyl(f, "FountainJet", Vector3.new(5.5, 1.2, 1.2), Vector3.new(CX, FLOOR + 13.4, CZ),
		C.WATER, M.Neon, 25, "Fountain", 4, { canCollide = false, castShadow = false })
	made += 5

	-- 8 gian hàng quanh sảnh (vách kính + bảng hiệu + quầy)
	local shops = {
		{ "TRANG SỨC", 0 }, { "ĐỒNG HỒ", 1 }, { "TÚI XÁCH", 2 }, { "NƯỚC HOA", 3 },
		{ "KÍNH MÁT", 4 }, { "GIÀY", 5 }, { "VEST", 6 }, { "ĐIỆN THOẠI", 7 },
	}
	for i, shop in ipairs(shops) do
		local side = if i <= 4 then -1 else 1
		local idx = (i - 1) % 4
		local x = if side < 0 then BX0 + 16 else BX1 - 16
		local z = BZ0 + 18 + idx * 16
		K.box(f, string.format("ShopBack_%d", i), Vector3.new(2.0, 13, 20),
			Vector3.new(x + side * 8, FLOOR + 6.5, z), C.STONE, M.Concrete, 220, "Shop", 2)
		K.box(f, string.format("ShopGlass_%d", i), Vector3.new(0.5, 12, 18),
			Vector3.new(x - side * 4, FLOOR + 6.2, z), C.GLASS, M.Glass, 42, "Shop", 2,
			{ canCollide = false, castShadow = false, transparency = 0.2 })
		K.box(f, string.format("ShopCounter_%d", i), Vector3.new(4.0, 3.2, 9),
			Vector3.new(x + side * 2.5, FLOOR + 1.6, z), C.WOOD_D, M.Wood, 120, "Shop", 1)
		K.sign(f, string.format("ShopSign_%d", i), Vector3.new(x - side * 4.4, FLOOR + 14, z),
			Vector3.new(0.4, 3.6, 16), if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left,
			shop[1], C.GRANITE, C.NEON2, 50, 18)
		made += 4
	end

	-- 2 thang cuốn lên tầng 2 (mỗi bên 14 bậc)
	for side, sgn in ipairs({ -1, 1 }) do
		local x0 = CX + sgn * 30
		for i = 1, 14 do
			K.box(f, string.format("Escalator1_%d_%d", side, i), Vector3.new(8, 0.7, 3.0),
				Vector3.new(x0, FLOOR + i * ((H1) / 14) - 0.35, CZ + 30 - i * 1.7), C.GRANITE, M.Metal, 90,
				"Escalator", i)
			made += 1
		end
		-- tay vịn
		K.rbox(f, "EscalatorRail" .. side, Vector3.new(0.5, 0.4, 26),
			CFrame.new(x0, FLOOR + H1 * 0.55, CZ + 18) * CFrame.Angles(math.rad(-40), 0, 0),
			C.DARK, M.Rubber, 40, "Escalator", 8, { canCollide = false, castShadow = false })
		made += 1
	end

	-- quầy lễ tân + bản đồ trung tâm
	K.box(f, "InfoDesk", Vector3.new(20, 4.2, 6), Vector3.new(CX, FLOOR + 2.1, BZ1 - 16),
		C.MARBLE, M.Marble, 180, "InfoDesk", 1)
	K.box(f, "InfoDeskTop", Vector3.new(21, 0.4, 7), Vector3.new(CX, FLOOR + 4.4, BZ1 - 16),
		C.BRASS, M.Metal, 90, "InfoDesk", 2)
	K.sign(f, "DirectoryBoard", Vector3.new(BX0 + 8, FLOOR + 9, BZ1 - 24), Vector3.new(0.4, 10, 14),
		Enum.NormalId.Right, "DIRECTORY", C.DARK, C.NEON, 50, 18)
	made += 3

	-- 6 bồn cây + 8 ghế đá trong sảnh
	for i = 1, 6 do
		local ang = (i / 6) * math.pi * 2
		made += K.planter(f, "AtriumPlanter" .. i,
			Vector3.new(CX + math.cos(ang) * 40, FLOOR, CZ + math.sin(ang) * 34), 9, 9, 1.8, C.GRANITE, C.LEAF, 110)
	end
	for i = 1, 8 do
		local ang = (i / 8) * math.pi * 2
		local bx = CX + math.cos(ang) * 34
		local bz = CZ + math.sin(ang) * 28
		K.box(f, "BenchSeat" .. i, Vector3.new(6, 0.6, 2.4), Vector3.new(bx, FLOOR + 1.5, bz), C.SEAT, M.Marble, 60,
			"Bench", 1, { canCollide = false })
		K.box(f, "BenchLeg" .. i, Vector3.new(5, 1.2, 2.0), Vector3.new(bx, FLOOR + 0.6, bz), C.GRANITE, M.Marble, 60,
			"Bench", 1, { canCollide = false })
		made += 2
	end
	return made
end

local function buildLevel2(f: Instance): number
	local made = 0
	local grp = "MallL2"
	-- sàn vành khăn quanh giếng trời
	local function ringSlab(name: string, x0: number, x1: number, z0: number, z1: number)
		K.box(f, name, Vector3.new(x1 - x0, SLAB, z1 - z0), Vector3.new((x0 + x1) * 0.5, Y2 - SLAB * 0.5, (z0 + z1) * 0.5),
			C.STONE, M.Concrete, 300, grp, 5, { canCollide = true })
		made += 1
	end
	ringSlab("L2SlabW", BX0, ATRIUM_X0, BZ0, BZ1)
	ringSlab("L2SlabE", ATRIUM_X1, BX1, BZ0, BZ1)
	ringSlab("L2SlabN", ATRIUM_X0, ATRIUM_X1, BZ0, ATRIUM_Z0)
	ringSlab("L2SlabS", ATRIUM_X0, ATRIUM_X1, ATRIUM_Z1, BZ1)

	made += K.tileField(f, "L2FloorW", BX0 + 1, ATRIUM_X0 - 1, BZ0 + 1, BZ1 - 1, Y2 + 0.07, 4.2, 100,
		C.MARBLE, C.STONE, grp, 0.14)
	made += K.tileField(f, "L2FloorE", ATRIUM_X1 + 1, BX1 - 1, BZ0 + 1, BZ1 - 1, Y2 + 0.07, 4.2, 100,
		C.MARBLE, C.STONE, grp, 0.14)

	-- lan can kính quanh giếng trời
	made += K.railing(f, "AtriumRailN", "X", ATRIUM_Z0, ATRIUM_X0, ATRIUM_X1, Y2, 4.2, C.BRASS_D, C.GLASS, 50)
	made += K.railing(f, "AtriumRailS", "X", ATRIUM_Z1, ATRIUM_X0, ATRIUM_X1, Y2, 4.2, C.BRASS_D, C.GLASS, 50)
	made += K.railing(f, "AtriumRailW", "Z", ATRIUM_X0, ATRIUM_Z0, ATRIUM_Z1, Y2, 4.2, C.BRASS_D, C.GLASS, 50)
	made += K.railing(f, "AtriumRailE", "Z", ATRIUM_X1, ATRIUM_Z0, ATRIUM_Z1, Y2, 4.2, C.BRASS_D, C.GLASS, 50)

	-- 10 gian hàng tầng 2
	local labels = { "THỜI TRANG", "MỸ PHẨM", "SÁCH", "ĐỒ CHƠI", "THỂ THAO",
		"ĐIỆN TỬ", "NỘI THẤT", "BÁNH NGỌT", "CÀ PHÊ", "Spa" }
	for i = 1, 10 do
		local side = if i <= 5 then -1 else 1
		local idx = (i - 1) % 5
		local x = if side < 0 then BX0 + 14 else BX1 - 14
		local z = BZ0 + 18 + idx * 14
		K.box(f, string.format("L2ShopBack_%d", i), Vector3.new(1.8, 10, 16),
			Vector3.new(x + side * 7, Y2 + 5, z), C.STONE, M.Concrete, 200, "L2Shop", 6)
		K.box(f, string.format("L2ShopGlass_%d", i), Vector3.new(0.4, 9.4, 15),
			Vector3.new(x - side * 3.5, Y2 + 4.8, z), C.GLASS, M.Glass, 40, "L2Shop", 6,
			{ canCollide = false, castShadow = false, transparency = 0.22 })
		K.sign(f, string.format("L2ShopSign_%d", i), Vector3.new(x - side * 3.9, Y2 + 10.6, z),
			Vector3.new(0.4, 2.6, 13), if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left,
			labels[i], C.GRANITE, C.NEON, 40, 18)
		made += 3
	end

	-- thang cuốn tầng 2 → 3
	for side, sgn in ipairs({ -1, 1 }) do
		local x0 = CX + sgn * 30
		for i = 1, 12 do
			K.box(f, string.format("Escalator2_%d_%d", side, i), Vector3.new(8, 0.7, 3.0),
				Vector3.new(x0, Y2 + i * (H2 / 12) - 0.35, CZ - 34 + i * 1.7), C.GRANITE, M.Metal, 90,
				"Escalator2", i)
			made += 1
		end
	end
	-- 6 ghế chờ + 4 bồn cây hành lang
	for i = 1, 6 do
		K.box(f, "L2Bench" .. i, Vector3.new(2.4, 0.5, 6), Vector3.new(ATRIUM_X0 - 8, Y2 + 1.6, CZ - 30 + i * 11),
			C.SEAT, M.Marble, 50, "Bench", 6, { canCollide = false })
		made += 1
	end
	for i = 1, 4 do
		made += K.planter(f, "L2Planter" .. i, Vector3.new(ATRIUM_X1 + 8, Y2, CZ - 30 + i * 20), 7, 7, 1.6,
			C.GRANITE, C.LEAF, 90)
	end
	return made
end

local function buildLevel3(f: Instance): number
	local made = 0
	local grp = "MallL3"
	local function ringSlab3(name: string, x0: number, x1: number, z0: number, z1: number)
		K.box(f, name, Vector3.new(x1 - x0, SLAB, z1 - z0), Vector3.new((x0 + x1) * 0.5, Y3 - SLAB * 0.5, (z0 + z1) * 0.5),
			C.STONE, M.Concrete, 280, grp, 9, { canCollide = true })
		made += 1
	end
	ringSlab3("L3SlabW", BX0, ATRIUM_X0, BZ0, BZ1)
	ringSlab3("L3SlabE", ATRIUM_X1, BX1, BZ0, BZ1)
	ringSlab3("L3SlabN", ATRIUM_X0, ATRIUM_X1, BZ0, ATRIUM_Z0)
	ringSlab3("L3SlabS", ATRIUM_X0, ATRIUM_X1, ATRIUM_Z1, BZ1)
	made += K.tileField(f, "L3Floor", BX0 + 1, BX1 - 1, BZ0 + 1, BZ1 - 1, Y3 + 0.07, 4.6, 90,
		C.WOOD, C.WOOD_D, grp, 0.14)

	-- khu ăn uống: 12 bàn tròn + ghế
	for i = 1, 12 do
		local col = (i - 1) % 4
		local row = math.floor((i - 1) / 4)
		local x = BX0 + 22 + col * 24
		local z = BZ0 + 20 + row * 22
		K.cyl(f, "FoodTable" .. i, Vector3.new(0.5, 7, 7), Vector3.new(x, Y3 + 2.2, z), C.WOOD_D, M.Wood, 60,
			"FoodCourt", 10)
		K.cyl(f, "FoodTableLeg" .. i, Vector3.new(2.0, 1.2, 1.2), Vector3.new(x, Y3 + 1.1, z), C.DARK, M.Metal, 60,
			"FoodCourt", 10)
		for c = 1, 4 do
			local ang = (c / 4) * math.pi * 2
			K.box(f, string.format("FoodChair_%d_%d", i, c), Vector3.new(2.0, 0.4, 2.0),
				Vector3.new(x + math.cos(ang) * 5, Y3 + 1.4, z + math.sin(ang) * 5), C.SEAT, M.Wood, 40,
				"FoodCourt", 10, { canCollide = false })
			made += 1
		end
		made += 2
	end

	-- 4 quạt trần lớn dưới vòm kính
	for i = 1, 4 do
		local x = CX + ((i <= 2) and -26 or 26)
		local z = CZ + ((i % 2 == 1) and -22 or 22)
		K.cyl(f, "FanHub" .. i, Vector3.new(1.0, 1.4, 1.4), Vector3.new(x, Y_ROOF - 6, z), C.BRASS_D, M.Metal, 40,
			"Fan", 11, { canCollide = false })
		for b = 1, 4 do
			local ang = (b / 4) * math.pi * 2
			K.rbox(f, string.format("FanBlade_%d_%d", i, b), Vector3.new(11, 0.3, 1.8),
				CFrame.new(x + math.cos(ang) * 5.5, Y_ROOF - 6, z + math.sin(ang) * 5.5) * CFrame.Angles(0, -ang, 0),
				C.WOOD_D, M.Wood, 30, "Fan", 11, { canCollide = false, castShadow = false })
			made += 1
		end
	end

	-- sân thượng ngắm cảnh phía Nam
	made += K.tileField(f, "L3Terrace", BX0 + 4, BX1 - 4, BZ1 - 18, BZ1 - 1, Y3 + 0.07, 3.6, 80,
		C.WOOD, C.WOOD_D, "Terrace", 0.2)
	made += K.railing(f, "L3TerraceRail", "X", BZ1 - 1.2, BX0 + 4, BX1 - 4, Y3 + 0.1, 4.4, C.BRASS_D, C.GLASS, 50)
	made += K.railing(f, "L3TerraceRailW", "Z", BX0 + 4, BZ1 - 18, BZ1 - 1.2, Y3 + 0.1, 4.4, C.BRASS_D, C.GLASS, 50)
	made += K.railing(f, "L3TerraceRailE", "Z", BX1 - 4, BZ1 - 18, BZ1 - 1.2, Y3 + 0.1, 4.4, C.BRASS_D, C.GLASS, 50)
	return made
end

local function buildRoof(f: Instance): number
	local made = 0
	local grp = "MallRoof"
	-- sàn mái vành khăn (chừa lỗ giếng trời ở giữa)
	local function roofRing(name: string, x0: number, x1: number, z0: number, z1: number)
		K.box(f, name, Vector3.new(x1 - x0, SLAB, z1 - z0), Vector3.new((x0 + x1) * 0.5, Y_ROOF - SLAB * 0.5, (z0 + z1) * 0.5),
			C.STONE_D, M.Concrete, 320, grp, 12, { canCollide = true })
		made += 1
	end
	roofRing("RoofW", BX0, ATRIUM_X0, BZ0, BZ1)
	roofRing("RoofE", ATRIUM_X1, BX1, BZ0, BZ1)
	roofRing("RoofN", ATRIUM_X0, ATRIUM_X1, BZ0, ATRIUM_Z0)
	roofRing("RoofS", ATRIUM_X0, ATRIUM_X1, ATRIUM_Z1, BZ1)

	-- vòm kính giếng trời: 3 vòng bán nguyệt
	for ring = 1, 3 do
		local r = 12 + ring * 6
		local segs = 12 + ring * 4
		for i = 1, segs do
			local ang = (i / segs) * math.pi
			local px = CX + math.cos(ang) * r
			local pz = CZ
			local py = Y_ROOF + math.sin(ang) * (4 + ring * 2.6)
			K.rbox(f, string.format("DomeGlass_%d_%d", ring, i), Vector3.new(4.6, 0.3, 5.4),
				CFrame.new(px, py, pz) * CFrame.Angles(0, 0, -ang + math.pi * 0.5),
				C.GLASS, M.Glass, 30, "Dome", 13, { canCollide = false, castShadow = false, transparency = 0.3 })
			made += 1
		end
	end
	K.box(f, "DomeRib", Vector3.new(70, 0.8, 0.8), Vector3.new(CX, Y_ROOF + 5, CZ), C.BRASS, M.Metal, 60,
		"Dome", 14, { canCollide = false })

	-- HVAC + tháp nước + cột ăng ten + biển mái
	for i = 1, 5 do
		local x = BX0 + 22 + (i - 1) * 24
		K.box(f, "RoofHVAC" .. i, Vector3.new(9, 4.2, 7), Vector3.new(x, Y_ROOF + 2.1, BZ0 + 16),
			C.STONE_D, M.Metal, 110, grp, 12)
		K.cyl(f, "RoofHVACFan" .. i, Vector3.new(0.6, 4.0, 4.0), Vector3.new(x, Y_ROOF + 4.4, BZ0 + 16),
			C.DARK, M.Metal, 40, grp, 13)
		made += 2
	end
	K.cyl(f, "RoofTank", Vector3.new(7, 9, 9), Vector3.new(BX1 - 22, Y_ROOF + 4.5, BZ0 + 18),
		C.STONE_D, M.Metal, 130, grp, 12)
	K.box(f, "RoofMast", Vector3.new(0.6, 16, 0.6), Vector3.new(CX, Y_ROOF + 8, BZ0 + 10), C.BRASS, M.Metal, 40, grp, 13)
	made += 2
	return made
end

local function buildFacade(f: Instance): number
	local made = 0
	local grp = "MallSign"
	-- cột đá trắng 3 tầng + mái đua kính
	-- 8 cột, chừa đúng tim cửa xoay (CX) để lối vào không bị chặn
	local pierX = { BX0 + 2, BX0 + 24, CX - 44, CX - 22, CX + 22, CX + 44, BX1 - 24, BX1 - 2 }
	for i, x in ipairs(pierX) do
		K.box(f, "FacadePier" .. i, Vector3.new(3.6, Y_ROOF - FLOOR, 2.4),
			Vector3.new(x, FLOOR + (Y_ROOF - FLOOR) * 0.5, BZ1 + 0.2), C.MARBLE, M.Marble, 260, grp, 3)
		K.box(f, "PierCapital" .. i, Vector3.new(4.6, 1.4, 3.2), Vector3.new(x, Y_ROOF - 1.2, BZ1 + 0.2),
			C.BRASS, M.Metal, 90, grp, 4, { canCollide = false })
		made += 2
	end
	K.rbox(f, "CanopyGlass", Vector3.new(BX1 - BX0 - 6, 0.3, 10),
		CFrame.new(CX, FLOOR + 15.6, BZ1 + 5) * CFrame.Angles(math.rad(-8), 0, 0),
		C.GLASS, M.Glass, 60, grp, 5, { canCollide = false, castShadow = false, transparency = 0.35 })
	K.box(f, "CanopyBeam", Vector3.new(BX1 - BX0 - 6, 0.8, 1.2), Vector3.new(CX, FLOOR + 15.2, BZ1 + 9.6),
		C.BRASS, M.Metal, 90, grp, 5, { canCollide = false })
	made += 2

	K.sign(f, "MainSign", Vector3.new(CX, FLOOR + 20.4, BZ1 + 1.2), Vector3.new(76, 7.4, 1.0),
		Enum.NormalId.Back, "RICHMAN GALLERIA", C.GRANITE, C.NEON, 150, 16)
	made += 1
	K.box(f, "SignGlow", Vector3.new(76, 0.6, 0.4), Vector3.new(CX, FLOOR + 16.4, BZ1 + 1.6),
		C.NEON2, M.Neon, 40, grp, 6, { canCollide = false, castShadow = false })
	made += 1

	-- 6 cột cờ sân trước
	for i = 1, 6 do
		local x = CX - 50 + (i - 1) * 20
		K.cyl(f, "FlagPole" .. i, Vector3.new(24, 0.5, 0.5), Vector3.new(x, G + 13, BZ1 + 18), C.STONE_D, M.Metal, 60,
			"Flag", 1)
		K.box(f, "Flag" .. i, Vector3.new(0.2, 5, 8), Vector3.new(x + 0.2, G + 22, BZ1 + 22), C.RED, M.Fabric, 30,
			"Flag", 2, { canCollide = false, castShadow = false })
		made += 2
	end
	return made
end

local function buildForecourt(f: Instance): number
	local made = 0
	local grp = "Forecourt"
	made += K.tileField(f, "PlazaTile", BX0 - 6, BX1 + 6, BZ1, 124, G + 0.07, 4.2, 90, C.STONE, C.STONE_D, grp, 0.14)
	-- thảm đỏ + bồn nước
	K.box(f, "RedCarpet", Vector3.new(20, 0.1, 16), Vector3.new(CX, G + 0.16, BZ1 + 8), C.RED, M.Fabric, 40, grp, 1,
		{ canCollide = false, castShadow = false })
	made += 1
	K.cyl(f, "PlazaFountain", Vector3.new(1.2, 20, 20), Vector3.new(CX, G + 0.6, BZ1 + 13), C.GRANITE, M.Marble, 160,
		grp, 1)
	K.cyl(f, "PlazaWater", Vector3.new(0.5, 17, 17), Vector3.new(CX, G + 1.25, BZ1 + 13), C.WATER, M.Glass, 40,
		grp, 2, { canCollide = false, castShadow = false, transparency = 0.2 })
	made += 2
	-- 4 cọ + 4 ghế đá + 2 cột đèn
	for i = 1, 4 do
		local sgn = if i <= 2 then -1 else 1
		local idx = (i - 1) % 2
		made += K.palm(f, "Palm" .. i, Vector3.new(CX + sgn * (50 + idx * 10), G, BZ1 + 14), 15, C.WOOD, C.LEAF, 80)
	end
	for i = 1, 4 do
		local sgn = if i <= 2 then -1 else 1
		K.box(f, "PlazaBench" .. i, Vector3.new(8, 0.6, 2.6),
			Vector3.new(CX + sgn * 38, G + 1.5, BZ1 + 6 + ((i - 1) % 2) * 10), C.SEAT, M.Marble, 60, grp, 1,
			{ canCollide = false })
		made += 1
	end
	for i = 1, 2 do
		made += K.lampPost(f, "PlazaLamp" .. i, Vector3.new(CX + (i == 1 and -58 or 58), G, BZ1 + 6), 11, C.GRANITE, C.NEON2, 110)
	end
	-- trạm valet + bảng giờ mở cửa
	K.box(f, "ValetStand", Vector3.new(9, 5, 7), Vector3.new(BX0 + 12, G + 2.5, BZ1 + 6), C.WOOD_D, M.Wood, 120, grp, 1)
	K.sign(f, "ValetSign", Vector3.new(BX0 + 12, G + 7.6, BZ1 + 6), Vector3.new(9, 2.6, 0.4),
		Enum.NormalId.Back, "VALET", C.DARK, C.NEON2, 40, 20)
	made += 2
	-- 2 xe đỗ chờ trước sảnh (kiểu drop-off của trung tâm thương mại)
	made += K.car(f, "CarA", Vector3.new(BX0 + 22, G, BZ1 + 16), 0, Color3.fromRGB(60, 64, 96), 200, "ParkedCar")
	made += K.car(f, "CarB", Vector3.new(BX1 - 22, G, BZ1 + 16), 0, Color3.fromRGB(190, 186, 178), 200, "ParkedCar")
	return made
end

function Module.build(modulesContainer: Instance): Instance
	local root = K.folder("Plot_E4_RichmanGalleria", modulesContainer)
	root:SetAttribute("PlotId", "Plot_E4")
	root:SetAttribute("ModuleId", Module.Id)
	root:SetAttribute("MainEntrance", "X=446, Z=110 (cửa xoay 3 lá, mặt Nam ra Vespucci Blvd)")
	root:SetAttribute("Levels", "3 tầng thương mại + sân thượng, giếng trời vòm kính")
	root:SetAttribute("StudsPerMeter", SPM)

	buildShell(K.folder("01_Shell", root))
	buildLevel1(K.folder("02_Level1", root))
	buildLevel2(K.folder("03_Level2", root))
	buildLevel3(K.folder("04_Level3", root))
	buildRoof(K.folder("05_Roof", root))
	buildFacade(K.folder("06_Facade", root))
	buildForecourt(K.folder("07_Forecourt", root))

	local stat = K.perf(root)
	root:SetAttribute("PartCount", stat.parts)
	return root
end

return Module
