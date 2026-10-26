--!strict
--[[
	Plot_E1_PacificBluffsVilla.luau  (Sync v27 — vòng quét V6, Agent A)
	================================================================================
	PACIFIC BLUFFS VILLA — biệt thự ven vịnh 2 tầng + hồ bơi vô cực (bản chi tiết)
	Ô đất   : Plot_E1 (Pacific Bluffs)  X −536…−358 · Z −204…−60 · nền Y = 1,15
	Mặt tiền: Nam (+Z, Z = −116) nhìn ra Olympic Fwy (Z = −36)

	Bản "ít part" của ô này đã bị gỡ ở Sync v23 vì quá sơ sài; đây là bản dựng lại
	đầy đủ theo đúng chuẩn 1 công trình / 1 lượt.

	Chức năng: quầy `E1_SPA` (HEAL_FULL $400, hồi đầy máu + giáp) tự dựng trước
	sảnh khi module này được nạp.

	KIẾN TRÚC
	  • Trệt 15 stud: phòng khách thông tầng có lò sưởi + tường TV, bếp đảo, bàn ăn 10 chỗ,
	    hành lang tranh, WC khách, cầu thang cong 18 bậc.
	  • Tầng 2 (Y 16,45): phòng ngủ chính có ban công nhìn hồ bơi, 2 phòng ngủ phụ,
	    2 phòng tắm, tủ quần áo, góc làm việc.
	  • Sân thượng (Y 29,15): pergola gỗ, 2 ghế dài, bồn cây, giàn pin mặt trời.
	  • Ngoài trời: hồ bơi vô cực 40 × 26 stud có bậc xuống, sàn đá quanh hồ, 4 ghế
	    tắm nắng + dù, bếp ngoài + quầy bar, pergola, 8 cọ, vườn hoa, gara 2 xe,
	    cổng sắt + đường lái xe, đèn sân.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local K = require(Shared:WaitForChild("World"):WaitForChild("BuildKit"))

local Module = {
	Id = "Plot_E1_PacificBluffsVilla",
	PlotId = "Plot_E1",
	Order = 61,
	Enabled = true,
}

local M = Enum.Material
local G = K.GROUND
local SPM = K.STUDS_PER_METER

local C = {
	WALL = Color3.fromRGB(246, 240, 230),
	WALL_D = Color3.fromRGB(222, 214, 202),
	STONE = Color3.fromRGB(206, 198, 186),
	STONE_D = Color3.fromRGB(168, 160, 148),
	WOOD = Color3.fromRGB(160, 118, 74),
	WOOD_D = Color3.fromRGB(104, 74, 46),
	GLASS = Color3.fromRGB(170, 208, 216),
	GLASS_D = Color3.fromRGB(104, 140, 152),
	FRAME = Color3.fromRGB(58, 60, 66),
	WATER = Color3.fromRGB(78, 164, 198),
	WATER_D = Color3.fromRGB(52, 122, 156),
	TILE = Color3.fromRGB(238, 236, 232),
	MARBLE = Color3.fromRGB(240, 238, 234),
	STEEL = Color3.fromRGB(178, 182, 188),
	DARK = Color3.fromRGB(40, 42, 46),
	LEAF = Color3.fromRGB(74, 130, 78),
	LEAF2 = Color3.fromRGB(96, 148, 88),
	FLOWER = Color3.fromRGB(206, 96, 128),
	NEON = Color3.fromRGB(255, 226, 176),
	FABRIC = Color3.fromRGB(214, 206, 194),
	SEA = Color3.fromRGB(64, 138, 176),
}

local BX0, BX1 = -516, -396 -- thân biệt thự 120 stud
local BZ0, BZ1 = -192, -116 -- sâu 76 stud, mặt tiền Z = −116
local CX, CZ = (BX0 + BX1) * 0.5, (BZ0 + BZ1) * 0.5
local FLOOR = G + 0.15
local H1, SLAB = 15.0, 1.2
local Y2 = FLOOR + H1 + SLAB
local H2 = 11.5
local Y_ROOF = Y2 + H2 + SLAB
local WT = 1.4

-- hồ bơi + sân đá phía trước
local POOL_X0, POOL_X1 = -508, -468
local POOL_Z0, POOL_Z1 = -108, -82
local DECK_Z0, DECK_Z1 = BZ1, -70

local FRONT_OPEN = {
	{ a = CX - 24, b = CX + 24, y0 = FLOOR, y1 = FLOOR + 11.6 }, -- vách kính phòng khách
	{ a = BX0 + 10, b = BX0 + 30, y0 = FLOOR + 3, y1 = FLOOR + 9.6 }, -- cửa sổ bếp
	{ a = BX1 - 30, b = BX1 - 10, y0 = FLOOR + 3, y1 = FLOOR + 9.6 }, -- cửa sổ phòng ăn
	{ a = -476, b = -456, y0 = Y2, y1 = Y2 + 9 },                 -- cửa ra ban công tầng 2
	{ a = -440, b = -424, y0 = Y2 + 3, y1 = Y2 + 9 },             -- cửa sổ phòng trẻ
}

local function buildShell(f: Instance): number
	local grp = "VillaShell"
	local made = 0
	K.box(f, "BaseSlab", Vector3.new(BX1 - BX0 + 0.4, FLOOR - G, BZ1 - BZ0 + 0.4),
		Vector3.new(CX, (G + FLOOR) * 0.5, CZ), C.STONE_D, M.Concrete, nil, grp, 1, { canCollide = true })
	made += 1
	made += K.tileField(f, "GroundTile", BX0 + 1, BX1 - 1, BZ0 + 1, BZ1 - 1, FLOOR, 4.2, 130,
		C.MARBLE, C.TILE, grp, 0.14)

	made += K.wall(f, "SouthWall", "X", BZ1 - WT * 0.5, BX0, BX1, FLOOR, Y_ROOF, WT,
		C.WALL, M.Concrete, 300, grp, FRONT_OPEN)
	made += K.wall(f, "NorthWall", "X", BZ0 + WT * 0.5, BX0, BX1, FLOOR, Y_ROOF, WT,
		C.WALL_D, M.Concrete, 300, grp, {
			{ a = BX1 - 40, b = BX1 - 22, y0 = FLOOR, y1 = FLOOR + 8.8 }, -- cửa hậu ra vườn sau
		})
	made += K.wall(f, "WestWall", "Z", BX0 + WT * 0.5, BZ0, BZ1, FLOOR, Y_ROOF, WT,
		C.WALL, M.Concrete, 300, grp, {
			{ a = -170, b = -150, y0 = FLOOR + 3, y1 = FLOOR + 9.4 },
			{ a = -170, b = -150, y0 = Y2 + 3, y1 = Y2 + 9.0 },
		})
	made += K.wall(f, "EastWall", "Z", BX1 - WT * 0.5, BZ0, BZ1, FLOOR, Y_ROOF, WT,
		C.WALL, M.Concrete, 300, grp, {
			{ a = -150, b = -130, y0 = FLOOR + 3, y1 = FLOOR + 9.4 },
			{ a = -150, b = -130, y0 = Y2 + 3, y1 = Y2 + 9.0 },
		})

	-- vách kính phòng khách thông tầng (2 lớp, xe/người đâm xuyên được)
	made += K.curtain(f, "LivingGlass", "X", BZ1 - 0.45, CX - 24, CX + 24, FLOOR + 0.2, FLOOR + 11.6,
		8, 4, C.GLASS, C.FRAME, 40, "LivingGlass")
	-- cửa trượt ra hồ bơi
	K.box(f, "SlidingDoor", Vector3.new(18, 10.4, 0.35), Vector3.new(CX, FLOOR + 5.2, BZ1 - 0.3),
		C.GLASS, M.Glass, 40, "MainDoor", 1, { canCollide = false, castShadow = false, transparency = 0.24 })
	K.cyl(f, "SlidingHandle", Vector3.new(2.4, 0.24, 0.24), Vector3.new(CX + 7, FLOOR + 4.6, BZ1 - 0.1),
		C.STEEL, M.Metal, 30, "MainDoor", 2)
	made += 2
	return made
end

local function buildLiving(f: Instance): number
	local made = 0
	local grp = "Living"
	-- Tường tính năng phía Bắc: lò sưởi (Tây) + TV 16 stud (Đông)
	K.box(f, "TVWall", Vector3.new(38, 16, 2.0), Vector3.new(-462, FLOOR + 8, -189), C.STONE, M.Marble, 240, grp, 2)
	K.box(f, "TVScreen", Vector3.new(16, 9, 0.4), Vector3.new(-455, FLOOR + 9, -187.8), C.DARK, M.SmoothPlastic, 60,
		grp, 3, { canCollide = false, castShadow = false })
	K.box(f, "Fireplace", Vector3.new(12, 6, 3.0), Vector3.new(-475, FLOOR + 3, -187.4), C.STONE, M.Marble, 180, grp, 2)
	K.box(f, "Firebox", Vector3.new(8, 3.2, 1.4), Vector3.new(-475, FLOOR + 2.6, -186.2), Color3.fromRGB(70, 44, 32),
		M.Slate, 60, grp, 3)
	K.box(f, "FireGlow", Vector3.new(6.6, 2.2, 1.0), Vector3.new(-475, FLOOR + 2.2, -185.4),
		Color3.fromRGB(255, 140, 60), M.Neon, 20, grp, 4, { canCollide = false, castShadow = false })
	made += 5

	-- Phòng khách: thảm + sofa quay về tường TV + bàn cà phê + 2 ghế đơn
	K.box(f, "Rug", Vector3.new(44, 0.12, 36), Vector3.new(-460, FLOOR + 0.12, -170), C.FABRIC, M.Fabric, 30, grp, 1,
		{ canCollide = false, castShadow = false })
	K.box(f, "SofaBase", Vector3.new(40, 2.6, 12), Vector3.new(-460, FLOOR + 1.6, -160), C.FABRIC, M.Fabric, 120, grp, 1)
	K.box(f, "SofaBack", Vector3.new(40, 4.0, 3.0), Vector3.new(-460, FLOOR + 3.4, -154.5), C.FABRIC, M.Fabric, 110,
		grp, 2)
	for i = 1, 3 do
		K.box(f, "SofaCushion" .. i, Vector3.new(11, 1.0, 10), Vector3.new(-471 + (i - 1) * 11, FLOOR + 3.2, -161),
			C.WALL_D, M.Fabric, 40, grp, 2, { canCollide = false })
		made += 1
	end
	K.box(f, "CoffeeTable", Vector3.new(20, 0.7, 10), Vector3.new(-460, FLOOR + 2.1, -172), C.WOOD, M.Wood, 90,
		grp, 1)
	for i, sx in ipairs({ -8, 8 }) do
		K.box(f, "CoffeeLeg" .. i, Vector3.new(1.2, 1.8, 1.2), Vector3.new(-460 + sx, FLOOR + 1.1, -172),
			C.WOOD_D, M.Wood, 40, grp, 1, { canCollide = false })
		made += 1
	end
	for i, sz in ipairs({ -166, -178 }) do
		K.box(f, "Armchair" .. i, Vector3.new(8, 2.6, 9), Vector3.new(-436, FLOOR + 1.6, sz), C.FABRIC, M.Fabric,
			80, grp, 1)
		K.box(f, "ArmchairBack" .. i, Vector3.new(2.4, 3.4, 9), Vector3.new(-432.5, FLOOR + 3.4, sz), C.FABRIC,
			M.Fabric, 70, grp, 2)
		made += 2
	end

	-- Bàn ăn 10 chỗ (góc Tây-Nam, dưới cửa sổ bếp)
	K.box(f, "DiningTable", Vector3.new(32, 0.6, 10), Vector3.new(-492, FLOOR + 3.2, -132), C.WOOD, M.Wood, 110,
		grp, 1)
	for i = 1, 10 do
		local side = if i <= 5 then -1 else 1
		local idx = (i - 1) % 5
		local cx = -504 + idx * 6
		local cz = -132 + side * 8.5
		K.box(f, "DiningChair" .. i, Vector3.new(3.4, 0.5, 3.4), Vector3.new(cx, FLOOR + 2.0, cz), C.WOOD_D, M.Wood,
			40, grp, 1, { canCollide = false })
		K.box(f, "DiningChairBack" .. i, Vector3.new(3.4, 3.2, 0.5), Vector3.new(cx, FLOOR + 3.4, cz + side * 1.9),
			C.WOOD_D, M.Wood, 40, grp, 2, { canCollide = false })
		made += 2
	end

	-- Bếp (góc Tây-Bắc): đảo 26 stud, quầy 36 stud, 4 bếp, tủ lạnh
	K.box(f, "KitchenIsland", Vector3.new(26, 0.7, 10), Vector3.new(-496, FLOOR + 3.4, -176), C.MARBLE, M.Marble,
		120, "Kitchen", 1)
	K.box(f, "IslandBody", Vector3.new(25, 3.0, 9), Vector3.new(-496, FLOOR + 1.5, -176), C.WOOD_D, M.Wood, 110,
		"Kitchen", 1)
	K.box(f, "KitchenCounter", Vector3.new(34, 0.7, 4), Vector3.new(-497, FLOOR + 3.4, -188.5), C.MARBLE, M.Marble,
		110, "Kitchen", 1)
	K.box(f, "KitchenBack", Vector3.new(34, 6, 1.2), Vector3.new(-497, FLOOR + 4, -190), C.WOOD_D, M.Wood, 100,
		"Kitchen", 1)
	for i = 1, 4 do
		K.box(f, "Stove" .. i, Vector3.new(5, 0.25, 5), Vector3.new(-510 + (i - 1) * 8, FLOOR + 3.85, -189),
			C.DARK, M.Metal, 30, "Kitchen", 2, { canCollide = false })
		made += 1
	end
	K.box(f, "Fridge", Vector3.new(8, 12, 6), Vector3.new(-510, FLOOR + 6, -184), C.STEEL, M.Metal, 140,
		"Kitchen", 1)
	made += 5

	-- Cầu thang 16 bậc ở dải Đông, leo về phía Nam; giếng thang X −418…−396 · Z −192…−142
	K.stairs(f, "MainStairs", Vector3.new(-407, FLOOR, -182), 0, 1, 16, 12, (Y2 - FLOOR) / 16, 2.4,
		C.MARBLE, 120, "Stairs")
	made += 16
	for i, sx in ipairs({ -6.4, 6.4 }) do
		K.rbox(f, "StairRail" .. i, Vector3.new(0.4, 0.4, 41.7),
			CFrame.new(-407 + sx, (FLOOR + Y2) * 0.5 + 3, -162.8) * CFrame.Angles(-0.399, 0, 0),
			C.STEEL, M.Metal, 40, "Stairs", 9, { canCollide = false, castShadow = false })
		made += 1
	end

	-- Hành lang tranh dọc tường Đông
	for i = 1, 4 do
		K.sign(f, "ArtFrame" .. i, Vector3.new(-397.9, FLOOR + 7, -160 - (i - 1) * 8), Vector3.new(0.3, 4, 3.4),
			Enum.NormalId.Left, "ART", C.STONE, C.FLOWER, 30, 16)
		made += 1
	end
	-- WC khách (góc Đông-Nam)
	K.box(f, "GuestBath", Vector3.new(14, 10, 14), Vector3.new(-406, FLOOR + 5, -128), C.WALL_D, M.Marble,
		180, "Bath", 1)
	K.box(f, "GuestBathDoor", Vector3.new(6, 8.4, 0.3), Vector3.new(-406, FLOOR + 4.2, -135.2), C.WOOD, M.Wood,
		60, "Bath", 2)
	made += 2
	return made
end

local function buildUpper(f: Instance): number
	local made = 0
	local grp = "VillaUpper"
	-- Sàn tầng 2 chừa giếng thang X −418…−396 · Z −192…−142
	K.box(f, "L2SlabW", Vector3.new(98, SLAB, 76), Vector3.new(-467, Y2 - SLAB * 0.5, -154), C.STONE, M.Concrete,
		320, grp, 5, { canCollide = true })
	K.box(f, "L2SlabLanding", Vector3.new(22, SLAB, 26), Vector3.new(-407, Y2 - SLAB * 0.5, -129), C.STONE,
		M.Concrete, 200, grp, 5, { canCollide = true })
	made += 2
	made += K.tileField(f, "L2FloorW", BX0 + 1, -419, BZ0 + 1, BZ1 - 1, Y2, 4.2, 110, C.WOOD, C.WOOD_D, grp, 0.14)
	made += K.tileField(f, "L2FloorLanding", -417, BX1 - 1, -141, BZ1 - 1, Y2, 4.0, 60, C.WOOD, C.WOOD_D, grp, 0.14)
	made += K.railing(f, "StairVoidRail", "Z", -418, -192, -142, Y2, 4.2, C.STEEL, C.GLASS, 50)
	made += K.railing(f, "StairVoidRailS", "X", -142, -418, -396, Y2, 4.2, C.STEEL, C.GLASS, 50)

	-- Phòng ngủ chính (Tây): giường king + tủ đầu giường + tủ áo + ban công
	K.box(f, "MasterBed", Vector3.new(18, 2.0, 22), Vector3.new(-484, Y2 + 2.0, -176), C.FABRIC, M.Fabric, 100, grp, 6)
	K.box(f, "MasterHeadboard", Vector3.new(18, 6, 1.2), Vector3.new(-484, Y2 + 3.6, -187.5), C.WOOD, M.Wood, 90,
		grp, 6)
	for i, sx in ipairs({ -10.5, 10.5 }) do
		K.box(f, "Nightstand" .. i, Vector3.new(4, 3, 4), Vector3.new(-484 + sx, Y2 + 1.5, -186), C.WOOD_D, M.Wood,
			60, grp, 6)
		K.cyl(f, "BedLamp" .. i, Vector3.new(2.2, 1.2, 1.2), Vector3.new(-484 + sx, Y2 + 3.8, -186), C.NEON, M.Neon,
			20, grp, 7, { canCollide = false, castShadow = false })
		made += 2
	end
	K.box(f, "Wardrobe", Vector3.new(3.4, 11, 24), Vector3.new(-510, Y2 + 5.5, -153), C.WOOD_D, M.Wood, 150, grp, 6)
	for i = 1, 4 do
		K.box(f, "WardrobeDoor" .. i, Vector3.new(0.3, 10.4, 5.6), Vector3.new(-508.2, Y2 + 5.5, -162 + (i - 1) * 6),
			C.WOOD, M.Wood, 40, grp, 7, { canCollide = false })
		made += 1
	end
	made += 4

	-- Phòng tắm chính (khoang kính nhìn ra biển)
	K.box(f, "MasterBath", Vector3.new(30, 10, 20), Vector3.new(-492, Y2 + 5, -128), C.WALL_D, M.Marble, 160, grp, 6)
	K.box(f, "MasterBathGlass", Vector3.new(24, 8, 0.3), Vector3.new(-492, Y2 + 4, -137.8), C.GLASS, M.Glass, 40,
		grp, 6, { canCollide = false, castShadow = false, transparency = 0.35 })
	K.box(f, "Bathtub", Vector3.new(9, 3.4, 6), Vector3.new(-500, Y2 + 1.7, -124), C.TILE, M.Marble, 80, grp, 6)
	made += 3

	-- Vách ngăn phòng + 2 phòng trẻ (dải giữa)
	K.box(f, "DividerMain", Vector3.new(1.0, 10.6, 72), Vector3.new(-452, Y2 + 5.3, -154), C.WALL_D, M.Concrete,
		180, grp, 6)
	K.box(f, "DividerKids", Vector3.new(34, 10.6, 1.0), Vector3.new(-435, Y2 + 5.3, -156), C.WALL_D, M.Concrete,
		180, grp, 6)
	made += 2
	for i, sz in ipairs({ -176, -134 }) do
		K.box(f, "Bed" .. i, Vector3.new(14, 1.8, 18), Vector3.new(-434, Y2 + 1.9, sz), C.FABRIC, M.Fabric, 90, grp, 6)
		K.box(f, "BedHead" .. i, Vector3.new(14, 5, 1.0), Vector3.new(-434, Y2 + 3.2, sz - (if sz < -154 then 9 else 9)),
			C.WOOD, M.Wood, 80, grp, 6)
		K.box(f, "Desk" .. i, Vector3.new(6, 0.6, 8), Vector3.new(-446, Y2 + 3.2, sz + 6), C.WOOD_D, M.Wood, 60, grp, 6)
		made += 3
	end

	-- Ban công nhìn hồ bơi
	K.box(f, "BalconySlab", Vector3.new(60, 0.9, 10), Vector3.new(CX, Y2 - 0.5, BZ1 + 5), C.STONE, M.Concrete, 200,
		grp, 5, { canCollide = true })
	made += K.railing(f, "BalconyRail", "X", BZ1 + 9.6, CX - 30, CX + 30, Y2 - 0.05, 4.2, C.STEEL, C.GLASS, 50)
	made += K.railing(f, "BalconyRailW", "Z", CX - 29.6, BZ1 + 0.4, BZ1 + 9.6, Y2 - 0.05, 4.2, C.STEEL, C.GLASS, 50)
	made += K.railing(f, "BalconyRailE", "Z", CX + 29.6, BZ1 + 0.4, BZ1 + 9.6, Y2 - 0.05, 4.2, C.STEEL, C.GLASS, 50)
	for i = 1, 2 do
		K.box(f, "BalconyChair" .. i, Vector3.new(4, 1.6, 5), Vector3.new(CX - 12 + (i - 1) * 24, Y2 + 1.3, BZ1 + 5),
			C.WOOD, M.Wood, 50, grp, 6, { canCollide = false })
		made += 1
	end
	return made
end

local function buildRoof(f: Instance): number
	local made = 0
	local grp = "VillaRoof"
	K.box(f, "RoofSlab", Vector3.new(BX1 - BX0 + 1.6, SLAB, BZ1 - BZ0 + 1.6),
		Vector3.new(CX, Y_ROOF - SLAB * 0.5, CZ), C.STONE, M.Concrete, 320, grp, 10, { canCollide = true })
	made += 1
	made += K.tileField(f, "RoofDeck", BX0 + 2, BX1 - 2, BZ0 + 2, BZ1 - 2, Y_ROOF, 4.6, 80, C.STONE, C.STONE_D, grp, 0.18)
	-- pergola gỗ + lounge
	for i = 0, 5 do
		local x = BX0 + 10 + i * 20
		K.box(f, "PergolaPost" .. i, Vector3.new(1.4, 12, 1.4), Vector3.new(x, Y_ROOF + 6, BZ1 - 12), C.WOOD_D, M.Wood,
			100, grp, 11)
		K.box(f, "PergolaPostN" .. i, Vector3.new(1.4, 12, 1.4), Vector3.new(x, Y_ROOF + 6, BZ0 + 20), C.WOOD_D, M.Wood,
			100, grp, 11)
		made += 2
	end
	for i = 0, 12 do
		K.box(f, "PergolaSlat" .. i, Vector3.new(BX1 - BX0, 0.5, 1.2),
			Vector3.new(CX, Y_ROOF + 12.2, BZ0 + 20 + i * ((BZ1 - 12 - BZ0 - 20) / 12)), C.WOOD, M.Wood, 60, grp, 12,
			{ canCollide = false })
		made += 1
	end
	for i = 1, 2 do
		K.box(f, "RoofLounger" .. i, Vector3.new(4, 1.2, 8), Vector3.new(CX - 10 + (i - 1) * 20, Y_ROOF + 1.2, BZ1 - 16),
			C.FABRIC, M.Fabric, 50, grp, 11, { canCollide = false })
		made += 1
	end
	-- 8 tấm pin mặt trời
	for i = 1, 8 do
		K.rbox(f, "SolarPanel" .. i, Vector3.new(11, 0.3, 6),
			CFrame.new(BX0 + 14 + ((i - 1) % 4) * 14, Y_ROOF + 2.2, BZ0 + 44 + math.floor((i - 1) / 4) * 10)
				* CFrame.Angles(math.rad(-20), 0, 0),
			Color3.fromRGB(30, 46, 80), M.Glass, 40, grp, 12, { canCollide = false, castShadow = false })
		made += 1
	end
	K.box(f, "RoofHVAC", Vector3.new(9, 4, 7), Vector3.new(BX1 - 18, Y_ROOF + 2, BZ0 + 16), C.STEEL, M.Metal, 110,
		grp, 11)
	made += 1
	return made
end

local function buildOutdoor(f: Instance): number
	local made = 0
	local grp = "Outdoor"
	-- sàn đá quanh hồ bơi
	made += K.tileField(f, "PoolDeck", BX0 - 8, BX1 + 8, BZ1, DECK_Z1, G + 0.08, 3.6, 90, C.TILE, C.STONE, grp, 0.16)
	-- hồ bơi vô cực: thành hồ + mặt nước + đáy + bậc xuống
	K.box(f, "PoolFloor", Vector3.new(POOL_X1 - POOL_X0, 0.4, POOL_Z1 - POOL_Z0),
		Vector3.new((POOL_X0 + POOL_X1) * 0.5, G + 0.2, (POOL_Z0 + POOL_Z1) * 0.5), C.WATER_D, M.Sandstone, 120,
		"Pool", 1)
	K.box(f, "PoolWater", Vector3.new(POOL_X1 - POOL_X0 - 1.6, 0.5, POOL_Z1 - POOL_Z0 - 1.6),
		Vector3.new((POOL_X0 + POOL_X1) * 0.5, G + 1.5, (POOL_Z0 + POOL_Z1) * 0.5), C.WATER, M.Glass, 40, "Pool", 2,
		{ canCollide = false, castShadow = false, transparency = 0.25 })
	for _, w in ipairs({
		{ "PoolWallS", Vector3.new(POOL_X1 - POOL_X0 + 1.2, 1.5, 1.0), Vector3.new((POOL_X0 + POOL_X1) * 0.5, G + 0.75, POOL_Z0) },
		{ "PoolWallW", Vector3.new(1.0, 1.5, POOL_Z1 - POOL_Z0), Vector3.new(POOL_X0, G + 0.75, (POOL_Z0 + POOL_Z1) * 0.5) },
		{ "PoolWallE", Vector3.new(1.0, 1.5, POOL_Z1 - POOL_Z0), Vector3.new(POOL_X1, G + 0.75, (POOL_Z0 + POOL_Z1) * 0.5) },
	}) do
		K.box(f, w[1], w[2], w[3], C.TILE, M.Marble, 90, "Pool", 2)
		made += 1
	end
	for i = 1, 3 do
		K.box(f, "PoolStep" .. i, Vector3.new(POOL_X1 - POOL_X0 - 2, 0.4, 3),
			Vector3.new((POOL_X0 + POOL_X1) * 0.5, G + 0.2 + i * 0.45, POOL_Z0 + 2 + i * 2), C.TILE, M.Marble, 60,
			"Pool", 2, { canCollide = false })
		made += 1
	end

	-- 4 ghế tắm nắng + 2 dù
	for i = 1, 4 do
		local x = POOL_X0 + 4 + (i - 1) * 10
		K.box(f, "Lounger" .. i, Vector3.new(6, 1.0, 7), Vector3.new(x, G + 1.7, POOL_Z0 - 4), C.FABRIC, M.Fabric, 50,
			grp, 1)
		K.box(f, "LoungerLeg" .. i, Vector3.new(5, 1.2, 6), Vector3.new(x, G + 0.7, POOL_Z0 - 4), C.STEEL, M.Metal, 50,
			grp, 1, { canCollide = false })
		made += 2
	end
	for i = 1, 2 do
		local x = POOL_X0 + 12 + (i - 1) * 26
		K.cyl(f, "UmbrellaPole" .. i, Vector3.new(10, 0.4, 0.4), Vector3.new(x, G + 5, POOL_Z0 - 4), C.STEEL, M.Metal,
			40, "Umbrella", 1)
		K.cyl(f, "UmbrellaTop" .. i, Vector3.new(0.5, 16, 16), Vector3.new(x, G + 10.4, POOL_Z0 - 4),
			Color3.fromRGB(226, 218, 200), M.Fabric, 30, "Umbrella", 2, { canCollide = false, castShadow = false })
		made += 2
	end

	-- bếp ngoài + quầy bar + pergola sân vườn (phía Đông)
	K.box(f, "OutdoorKitchen", Vector3.new(28, 4.4, 8), Vector3.new(BX1 - 10, G + 2.2, BZ1 + 10), C.STONE,
		M.Marble, 150, "OutdoorKitchen", 1)
	K.box(f, "OutdoorBarTop", Vector3.new(29, 0.6, 9), Vector3.new(BX1 - 10, G + 4.7, BZ1 + 10), C.MARBLE,
		M.Marble, 90, "OutdoorKitchen", 2)
	K.box(f, "GrillUnit", Vector3.new(8, 3.0, 6), Vector3.new(BX1 - 22, G + 5.6, BZ1 + 10), C.DARK, M.Metal, 80,
		"OutdoorKitchen", 3)
	for i = 1, 4 do
		K.cyl(f, "BarStool" .. i, Vector3.new(2.6, 1.2, 1.2), Vector3.new(BX1 - 20 + (i - 1) * 5, G + 2.6, BZ1 + 16),
			C.WOOD_D, M.Wood, 40, "OutdoorKitchen", 1, { canCollide = false })
		made += 1
	end
	made += 3

	-- 8 cọ + vườn hoa
	for i = 1, 8 do
		local col = (i - 1) % 4
		local row = math.floor((i - 1) / 4)
		made += K.palm(f, "Palm" .. i,
			Vector3.new(BX0 + 10 + col * 34, G, BZ1 + 22 + row * 16), 17, C.WOOD_D, (if i % 2 == 0 then C.LEAF else C.LEAF2), 80)
	end
	for i = 1, 5 do
		made += K.planter(f, "GardenBed" .. i, Vector3.new(BX0 - 4, G, BZ1 + 6 + (i - 1) * 10), 10, 6, 1.4, C.STONE_D, C.FLOWER, 90)
	end

	-- gara 2 xe: DÃY ĐÔNG, ngoài thân nhà (X −392…−364) + đường lái xe lên cổng
	local GX = -378
	K.box(f, "GarageBody", Vector3.new(28, 13, 34), Vector3.new(GX, G + 6.5, -152), C.WALL, M.Concrete, 300,
		"Garage", 1)
	K.box(f, "GarageDoor", Vector3.new(20, 11, 0.6), Vector3.new(GX, G + 5.5, -134.6), C.STEEL_D, M.Metal,
		140, "Garage", 2)
	for i = 1, 8 do
		K.box(f, "GarageSlat" .. i, Vector3.new(19.4, 1.2, 0.3), Vector3.new(GX, G + 0.9 + (i - 1) * 1.35, -134.3),
			C.STEEL, M.Metal, 50, "Garage", 2, { canCollide = false })
		made += 1
	end
	K.box(f, "Driveway", Vector3.new(24, 0.2, 66), Vector3.new(GX, G + 0.1, -103), C.STONE_D, M.Concrete, 60,
		grp, 1, { canCollide = false })
	made += 4
	made += K.car(f, "GarageCarA", Vector3.new(GX - 6, G, -152), math.rad(90), Color3.fromRGB(150, 152, 158), 200,
		"GarageCar")
	made += K.car(f, "GarageCarB", Vector3.new(GX + 6, G, -152), math.rad(90), Color3.fromRGB(60, 84, 130), 200,
		"GarageCar")

	-- cổng sắt + trụ cổng + đèn
	for i, sx in ipairs({ -26, 26 }) do
		K.box(f, "GatePier" .. i, Vector3.new(5, 9, 5), Vector3.new(CX + sx, G + 4.5, -66), C.STONE, M.Concrete, 200,
			"Gate", 1)
		K.box(f, "GateLamp" .. i, Vector3.new(2, 1.6, 2), Vector3.new(CX + sx, G + 9.8, -66), C.NEON, M.Neon, 30,
			"Gate", 2, { canCollide = false, castShadow = false })
		made += 2
	end
	for i = 1, 8 do
		K.box(f, "GateBar" .. i, Vector3.new(0.5, 7, 0.5), Vector3.new(CX - 21 + (i - 1) * 6, G + 3.6, -66), C.DARK,
			M.Metal, 60, "Gate", 2, { canCollide = false })
		made += 1
	end
	K.box(f, "GateRail", Vector3.new(46, 0.6, 0.6), Vector3.new(CX, G + 7.2, -66), C.DARK, M.Metal, 60, "Gate", 2,
		{ canCollide = false })
	made += 1

	for i = 1, 4 do
		made += K.lampPost(f, "YardLamp" .. i, Vector3.new(BX0 + 6 + (i - 1) * 34, G, -72), 9, C.DARK, C.NEON, 100)
	end
	return made
end

function Module.build(modulesContainer: Instance): Instance
	local root = K.folder("Plot_E1_PacificBluffsVilla", modulesContainer)
	root:SetAttribute("PlotId", "Plot_E1")
	root:SetAttribute("ModuleId", Module.Id)
	root:SetAttribute("MainEntrance", "X=-456, Z=-116 (cửa trượt kính 18 × 10,4 stud, mặt Nam ra hồ bơi)")
	root:SetAttribute("Pool", "X -508…-468, Z -108…-82 (40 × 26 stud), sâu 1,5 stud")
	root:SetAttribute("Garage", "X -410…-382, Z -172…-138 (2 xe)")
	root:SetAttribute("StudsPerMeter", SPM)

	buildShell(K.folder("01_Shell", root))
	buildLiving(K.folder("02_Living", root))
	buildUpper(K.folder("03_UpperFloor", root))
	buildRoof(K.folder("04_RoofTerrace", root))
	buildOutdoor(K.folder("05_Outdoor", root))

	local stat = K.perf(root)
	root:SetAttribute("PartCount", stat.parts)
	return root
end

return Module
