--!strict
--[[
	Plot_C2_LegionSquare.luau  (Sync v27 — vòng quét V6, Agent A)
	================================================================================
	LEGION SQUARE — quảng trường trung tâm + bãi thử xe
	Ô đất   : Plot_C2 (Legion Square)  X −92…92 · Z −14…130 · nền Y = 1,15
	Mặt tiền: Nam (+Z, Z = 126) nhìn ra Vespucci Blvd (Z = 148)

	Ô này trước đây TRỐNG (0 part) — bản đồ QA v27 lộ ra chỗ hụt 10/10 ô đất.
	Đây là ô duy nhất trong thành phố không phải "công trình" mà là KHÔNG GIAN CÔNG
	CỘNG: quảng trường có đài phun nước, tượng đài, bãi cỏ, đường dạo, sân khấu nhỏ.

	Chức năng: quầy `C2_TESTDRIVE` (SPAWN_CAR $0 — lấy xe thử miễn phí) đặt ở
	BÃI THỬ XE nửa Bắc: vạch kẻ đường, dải phân cách, kiosk điều hành có mái che.

	BỐ CỤC (Bắc → Nam)
	  Z −10…44  Bãi thử xe: sân nhựa + vạch kẻ, đảo cây giữa, kiosk 22×10, 3 xe thử,
	            cổng barie, 8 cột đèn pha.
	  Z 44…76   Quảng trường đá: ô vuông lớn, 4 cột cờ, 8 ghế đá, 6 bồn hoa.
	  Z 76…126  Công viên: đài phun nước bán kính 18 ba tầng, 4 bãi cỏ có hàng rào
	            cắt tỉa, 8 cọ, tượng đài 30 stud, khán đài nhỏ, cổng vòm phía Nam.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local K = require(Shared:WaitForChild("World"):WaitForChild("BuildKit"))

local Module = {
	Id = "Plot_C2_LegionSquare",
	PlotId = "Plot_C2",
	Order = 60,
	Enabled = true,
}

local M = Enum.Material
local G = K.GROUND
local SPM = K.STUDS_PER_METER

local C = {
	STONE = Color3.fromRGB(226, 222, 212),
	STONE_D = Color3.fromRGB(186, 182, 172),
	MARBLE = Color3.fromRGB(240, 238, 232),
	GRANITE = Color3.fromRGB(62, 64, 70),
	ASPHALT = Color3.fromRGB(62, 64, 68),
	ASPHALT_D = Color3.fromRGB(48, 50, 54),
	LINE = Color3.fromRGB(226, 220, 200),
	GRASS = Color3.fromRGB(74, 122, 66),
	GRASS_D = Color3.fromRGB(60, 102, 54),
	HEDGE = Color3.fromRGB(52, 92, 52),
	LEAF = Color3.fromRGB(84, 138, 80),
	LEAF2 = Color3.fromRGB(104, 154, 88),
	WATER = Color3.fromRGB(84, 168, 196),
	WATER_D = Color3.fromRGB(56, 124, 152),
	BRASS = Color3.fromRGB(202, 168, 92),
	STEEL = Color3.fromRGB(176, 180, 186),
	DARK = Color3.fromRGB(38, 40, 46),
	WOOD = Color3.fromRGB(150, 112, 72),
	WOOD_D = Color3.fromRGB(102, 74, 46),
	FLOWER_A = Color3.fromRGB(212, 96, 122),
	FLOWER_B = Color3.fromRGB(232, 176, 72),
	NEON = Color3.fromRGB(255, 232, 186),
	FABRIC = Color3.fromRGB(206, 198, 186),
	RED = Color3.fromRGB(156, 44, 52),
}

local BX0, BX1 = -88, 88
local BZ0, BZ1 = -10, 126
local CX = 0

local PAVE = G + 0.07
local PADDOCK_Z0, PADDOCK_Z1 = -8, 42
local PLAZA_Z0, PLAZA_Z1 = 42, 78
local PARK_Z0, PARK_Z1 = 78, 126
local FOUNTAIN_Z = 90
local TEST_Z = 52

local function buildPaving(f: Instance): number
	local made = 0
	-- sân nhựa bãi thử xe (Bắc)
	made += K.tileField(f, "PaddockAsphalt", BX0, BX1, PADDOCK_Z0, PADDOCK_Z1, G + 0.06, 6.4, 90,
		C.ASPHALT, C.ASPHALT_D, "Paddock", 0.12)
	-- quảng trường đá (giữa)
	made += K.tileField(f, "PlazaStone", BX0, BX1, PLAZA_Z0, PLAZA_Z1, PAVE, 5.6, 100,
		C.STONE, C.STONE_D, "Plaza", 0.14)
	-- công viên (Nam)
	made += K.tileField(f, "ParkStone", BX0, BX1, PARK_Z0, PARK_Z1, PAVE, 5.6, 100,
		C.MARBLE, C.STONE, "Park", 0.14)

	-- vạch kẻ bãi thử: 2 làn dọc + 4 vạch ngang
	for i = 1, 2 do
		K.box(f, "LaneLine" .. i, Vector3.new(0.5, 0.05, PADDOCK_Z1 - PADDOCK_Z0 - 6),
			Vector3.new(if i == 1 then -22 else 22, G + 0.14, (PADDOCK_Z0 + PADDOCK_Z1) * 0.5),
			C.LINE, M.SmoothPlastic, 20, "Paddock", 1, { canCollide = false, castShadow = false })
		made += 1
	end
	for i = 1, 4 do
		K.box(f, "CrossLine" .. i, Vector3.new(40, 0.05, 0.5),
			Vector3.new(0, G + 0.14, PADDOCK_Z0 + 8 + (i - 1) * 12), C.LINE, M.SmoothPlastic, 20, "Paddock", 1,
			{ canCollide = false, castShadow = false })
		made += 1
	end
	-- ô đỗ thử xe quanh cột quầy (0 · 52)
	for i = 1, 2 do
		K.box(f, "BayStripe" .. i, Vector3.new(0.4, 0.05, 12),
			Vector3.new(if i == 1 then -16 else 16, PAVE + 0.08, TEST_Z), C.LINE, M.SmoothPlastic, 20, "Plaza", 2,
			{ canCollide = false, castShadow = false })
		made += 1
	end
	return made
end

local function buildPaddock(f: Instance): number
	local made = 0
	local grp = "Paddock"
	-- đảo cây giữa bãi thử
	K.cyl(f, "IslandCurb", Vector3.new(0.5, 30, 30), Vector3.new(0, G + 0.3, 16), C.STONE_D, M.Concrete, 120, grp, 1)
	K.cyl(f, "IslandGrass", Vector3.new(0.4, 27, 27), Vector3.new(0, G + 0.6, 16), C.GRASS, M.Grass, 60, grp, 1,
		{ canCollide = false, castShadow = false })
	made += 2
	for i = 1, 4 do
		local ang = (i / 4) * math.pi * 2
		made += K.palm(f, "IslandPalm" .. i,
			Vector3.new(math.cos(ang) * 8, G + 0.6, 16 + math.sin(ang) * 8), 15, C.WOOD_D, C.LEAF, 70)
	end

	-- kiosk điều hành bãi thử (mặt Nam, quay ra quầy)
	K.box(f, "KioskBody", Vector3.new(22, 9, 10), Vector3.new(0, PAVE + 4.5, 32), C.WOOD_D, M.WoodPlanks, 240, grp, 2)
	K.box(f, "KioskGlass", Vector3.new(20, 5, 0.4), Vector3.new(0, PAVE + 5, 37.1), C.ASPHALT_D, M.Glass, 40, grp, 2,
		{ canCollide = false, castShadow = false, transparency = 0.35 })
	K.rbox(f, "KioskRoof", Vector3.new(26, 0.5, 14), CFrame.new(0, PAVE + 9.6, 32) * CFrame.Angles(math.rad(-3), 0, 0),
		Color3.fromRGB(168, 66, 58), M.Fabric, 90, grp, 3, { canCollide = false })
	K.box(f, "KioskCounter", Vector3.new(12, 3.6, 2.4), Vector3.new(0, PAVE + 1.8, 38.4), C.STEEL, M.DiamondPlate, 120,
		grp, 2)
	K.sign(f, "KioskSign", Vector3.new(0, PAVE + 8.2, 37.4), Vector3.new(20, 2.6, 0.5), Enum.NormalId.Back,
		"LEGION TEST DRIVE", C.DARK, C.NEON, 60, 14)
	made += 5

	-- 3 xe thử + barie cổng Bắc
	made += K.car(f, "TestCarA", Vector3.new(-26, G, 24), math.rad(180), Color3.fromRGB(178, 52, 48), 200, "TestCar")
	made += K.car(f, "TestCarB", Vector3.new(26, G, 24), math.rad(180), Color3.fromRGB(54, 96, 164), 200, "TestCar")
	made += K.car(f, "TestCarC", Vector3.new(0, G, 6), 0, Color3.fromRGB(212, 208, 198), 200, "TestCar")
	for i = 1, 4 do
		K.cyl(f, "BarrierPost" .. i, Vector3.new(3.4, 0.6, 0.6), Vector3.new(-30 + (i - 1) * 20, G + 1.7, -4), C.STEEL,
			M.Metal, 70, grp, 1)
		made += 1
	end
	for i = 1, 3 do
		K.box(f, "BarrierArm" .. i, Vector3.new(18, 0.5, 0.5), Vector3.new(-20 + (i - 1) * 20, G + 3.2, -4), C.RED,
			M.SmoothPlastic, 30, grp, 2, { canCollide = false, castShadow = false })
		made += 1
	end
	-- 4 cột đèn pha
	for i = 1, 4 do
		made += K.lampPost(f, "PaddockLamp" .. i,
			Vector3.new(if i <= 2 then -74 else 74, G, if i % 2 == 1 then 4 else 34), 15, C.STEEL,
			Color3.fromRGB(255, 246, 214), 110)
	end
	-- lốp + nón giao thông (bãi thử)
	for i = 1, 6 do
		K.cyl(f, "Pylon_" .. i, Vector3.new(1.8, 1.4, 1.4),
			Vector3.new(-40 + (i - 1) * 16, PAVE + 0.9, 38), Color3.fromRGB(226, 120, 40), M.SmoothPlastic, 20,
			"Pylon", 1, { canCollide = false, castShadow = false })
		made += 1
	end
	return made
end

local function buildPlaza(f: Instance): number
	local made = 0
	local grp = "Plaza"
	-- 4 cột cờ hai bên sân khấu
	for i = 1, 4 do
		local sx2 = if i % 2 == 1 then -20 else 20
		local sz2 = if i <= 2 then 46 else 74
		K.cyl(f, "FlagPole" .. i, Vector3.new(26, 0.5, 0.5), Vector3.new(sx2, PAVE + 13, sz2), C.STEEL, M.Metal, 90,
			"FlagPole", 1)
		K.box(f, "FlagCloth" .. i, Vector3.new(0.2, 6, 9), Vector3.new(sx2 + 0.2, PAVE + 23, sz2 + 4.5),
			if i % 2 == 0 then C.RED else Color3.fromRGB(52, 84, 148), M.Fabric, 30, "FlagPole", 2,
			{ canCollide = false, castShadow = false })
		made += 2
	end

	-- sân khấu nhỏ giữa quảng trường, hướng về đài phun nước
	K.box(f, "StageDeck", Vector3.new(26, 1.2, 14), Vector3.new(0, PAVE + 0.6, 64), C.WOOD_D, M.WoodPlanks, 160,
		"Stage", 1)
	for i = 1, 3 do
		K.box(f, "StageStep" .. i, Vector3.new(24, 0.4, 2), Vector3.new(0, PAVE + 0.2 + i * 0.3, 72 + i * 1.6),
			C.WOOD, M.Wood, 60, "Stage", 1, { canCollide = false })
		made += 1
	end
	K.box(f, "StageBackdrop", Vector3.new(26, 12, 0.8), Vector3.new(0, PAVE + 6.6, 56.6), C.DARK, M.Metal, 140,
		"Stage", 2)
	made += 2

	-- 10 ghế đá
	for i = 1, 10 do
		local col = (i - 1) % 5
		local sgn = if i <= 5 then -1 else 1
		local bx = if col < 3 then sgn * 34 else sgn * 52
		local bz = if col < 3 then 46 + col * 15 else 52 + (col - 3) * 16
		K.box(f, "PlazaBench" .. i, Vector3.new(8, 0.6, 2.6), Vector3.new(bx, PAVE + 1.5, bz), C.STONE_D, M.Marble,
			70, "Bench", 1, { canCollide = false })
		K.box(f, "PlazaBenchLeg" .. i, Vector3.new(6.6, 1.2, 2.0), Vector3.new(bx, PAVE + 0.6, bz), C.GRANITE,
			M.Marble, 70, "Bench", 1, { canCollide = false })
		made += 2
	end
	-- 6 bồn hoa sát biên
	for i = 1, 6 do
		local sx2 = if i <= 3 then -62 else 62
		local idx = (i - 1) % 3
		made += K.planter(f, "PlazaPlanter" .. i, Vector3.new(sx2, PAVE, 46 + idx * 12), 9, 9, 1.8, C.STONE_D,
			if i % 2 == 0 then C.FLOWER_A else C.FLOWER_B, 90)
	end
	-- 6 cột đèn
	for i = 1, 3 do
		made += K.lampPost(f, "PlazaLampW" .. i, Vector3.new(-70, PAVE, 46 + (i - 1) * 12), 10, C.GRANITE, C.NEON, 90)
		made += K.lampPost(f, "PlazaLampE" .. i, Vector3.new(70, PAVE, 46 + (i - 1) * 12), 10, C.GRANITE, C.NEON, 90)
	end
	-- 6 thùng rác + 4 giá để xe
	for i = 1, 6 do
		local bx = if i <= 2 then (if i == 1 then -30 else 30) else (i - 3) * 32 - 48
		local bz = if i <= 2 then 44 else 78
		K.cyl(f, "TrashBin" .. i, Vector3.new(3.2, 2.2, 2.2), Vector3.new(bx, PAVE + 1.6, bz), C.GRANITE, M.Metal, 50,
			"Bin", 1)
		made += 1
	end
	for i = 1, 4 do
		K.box(f, "BikeRack" .. i, Vector3.new(0.4, 3.0, 8), Vector3.new(-80 + (i - 1) * 4, PAVE + 1.5, 44),
			C.STEEL, M.Metal, 60, "BikeRack", 1, { canCollide = false })
		made += 1
	end
	return made
end

local function buildFountain(f: Instance): number
	local made = 0
	local grp = "Fountain"
	K.cyl(f, "FountainRimOuter", Vector3.new(1.5, 30, 30), Vector3.new(0, PAVE + 0.75, FOUNTAIN_Z), C.STONE_D,
		M.Marble, 200, grp, 1)
	K.cyl(f, "FountainWaterOuter", Vector3.new(0.9, 27, 27), Vector3.new(0, PAVE + 1.4, FOUNTAIN_Z), C.WATER,
		M.Glass, 40, grp, 2, { canCollide = false, castShadow = false, transparency = 0.22 })
	made += 2
	-- 8 trụ đá quanh vành
	for i = 1, 8 do
		local ang = (i / 8) * math.pi * 2
		K.cyl(f, "FountainPost" .. i, Vector3.new(3.2, 2.2, 2.2),
			Vector3.new(math.cos(ang) * 14, PAVE + 2.6, FOUNTAIN_Z + math.sin(ang) * 14), C.MARBLE, M.Marble, 90,
			grp, 2)
		made += 1
	end
	-- 3 tầng bát nước
	K.cyl(f, "Tier1Base", Vector3.new(6, 9, 9), Vector3.new(0, PAVE + 4, FOUNTAIN_Z), C.MARBLE, M.Marble, 130,
		grp, 3)
	K.cyl(f, "Tier1Bowl", Vector3.new(1.2, 15, 15), Vector3.new(0, PAVE + 7.4, FOUNTAIN_Z), C.MARBLE, M.Marble, 100,
		grp, 3, { canCollide = false })
	K.cyl(f, "Tier2Base", Vector3.new(5, 4.4, 4.4), Vector3.new(0, PAVE + 10, FOUNTAIN_Z), C.MARBLE, M.Marble, 90,
		grp, 4)
	K.cyl(f, "Tier2Bowl", Vector3.new(1.0, 10, 10), Vector3.new(0, PAVE + 13, FOUNTAIN_Z), C.MARBLE, M.Marble, 80,
		grp, 4, { canCollide = false })
	K.cyl(f, "Tier3Spire", Vector3.new(6, 2.4, 2.4), Vector3.new(0, PAVE + 17, FOUNTAIN_Z), C.MARBLE, M.Marble, 80,
		grp, 5)
	K.cyl(f, "Tier3Jet", Vector3.new(3.2, 1.2, 1.2), Vector3.new(0, PAVE + 21.4, FOUNTAIN_Z), C.WATER, M.Neon, 20,
		grp, 6, { canCollide = false, castShadow = false })
	made += 6
	-- 4 bồn hoa lớn 4 góc công viên
	for i = 1, 4 do
		local sx2 = if i % 2 == 1 then -70 else 70
		local sz2 = if i <= 2 then 84 else 118
		made += K.planter(f, "ParkBed" .. i, Vector3.new(sx2, PAVE, sz2), 14, 12, 1.6, C.STONE_D,
			if i % 2 == 0 then C.FLOWER_B else C.FLOWER_A, 100)
	end
	return made
end

local function buildPark(f: Instance): number
	local made = 0
	-- 4 bãi cỏ viền đá + hàng rào cắt tỉa
	local lawns = { { -46, 86 }, { 46, 86 }, { -46, 113 }, { 46, 113 } }
	for i, la in ipairs(lawns) do
		local lx, lz = la[1], la[2]
		K.box(f, "Lawn" .. i, Vector3.new(40, 0.35, 18), Vector3.new(lx, PAVE + 0.2, lz), C.GRASS, M.Grass, 70,
			"Lawn", 1, { canCollide = false, castShadow = false })
		for s2 = 1, 4 do
			local horiz = s2 <= 2
			local sgn = if s2 % 2 == 1 then -1 else 1
			K.box(f, string.format("LawnCurb_%d_%d", i, s2),
				if horiz then Vector3.new(41, 0.6, 0.8) else Vector3.new(0.8, 0.6, 19),
				if horiz then Vector3.new(lx, PAVE + 0.3, lz + sgn * 9.4) else Vector3.new(lx + sgn * 20.4, PAVE + 0.3, lz),
				C.STONE_D, M.Marble, 60, "Lawn", 1, { canCollide = false })
			made += 1
		end
		for h = 1, 6 do
			K.box(f, string.format("Hedge_%d_%d", i, h), Vector3.new(6.6, 3.2, 2.2),
				Vector3.new(lx - 18 + (h - 1) * 7.2, PAVE + 1.9, lz - 9.6), C.HEDGE, M.Grass, 60, "Hedge", 1,
				{ canCollide = false })
			made += 1
		end
	end
	-- 8 cọ
	for i = 1, 8 do
		local spots = { { -72, 80 }, { -72, 100 }, { -72, 120 }, { 72, 80 }, { 72, 100 }, { 72, 120 },
			{ -24, 108 }, { 24, 108 } }
		made += K.palm(f, "ParkPalm" .. i, Vector3.new(spots[i][1], PAVE, spots[i][2]), 17, C.WOOD_D,
			(if i % 2 == 0 then C.LEAF else C.LEAF2), 80)
	end
	-- 6 ghế dạo hai bên đài phun nước
	for i = 1, 6 do
		local sgn = if i % 2 == 1 then -1 else 1
		local idx = math.floor((i - 1) / 2)
		K.box(f, "ParkBench" .. i, Vector3.new(2.6, 0.6, 8), Vector3.new(sgn * 22, PAVE + 1.5, 84 + idx * 17),
			C.WOOD_D, M.Wood, 70, "Bench", 2, { canCollide = false })
		K.box(f, "ParkBenchLeg" .. i, Vector3.new(2.0, 1.2, 6.6), Vector3.new(sgn * 22, PAVE + 0.6, 84 + idx * 17),
			C.GRANITE, M.Marble, 70, "Bench", 2, { canCollide = false })
		made += 2
	end

	-- tượng đài 37 stud phía Nam
	for i = 1, 4 do
		K.box(f, "PlinthStep" .. i, Vector3.new(20, 0.5, 20), Vector3.new(0, PAVE + 0.25 + (if i <= 2 then 0 else 0.5), 119),
			C.STONE_D, M.Marble, 80, "Monument", 1, { canCollide = false })
		made += 1
	end
	K.box(f, "MonumentPlinth", Vector3.new(16, 3.0, 16), Vector3.new(0, PAVE + 2.5, 119), C.GRANITE, M.Marble, 250,
		"Monument", 3)
	K.box(f, "MonumentBase", Vector3.new(12, 4.0, 12), Vector3.new(0, PAVE + 6.0, 119), C.STONE, M.Marble, 220,
		"Monument", 4)
	K.box(f, "MonumentShaft", Vector3.new(6.4, 26, 6.4), Vector3.new(0, PAVE + 21, 119), C.MARBLE, M.Marble, 200,
		"Monument", 5)
	K.box(f, "MonumentCap", Vector3.new(5.0, 2.4, 5.0), Vector3.new(0, PAVE + 35.2, 119), C.BRASS, M.Metal, 120,
		"Monument", 6)
	K.cyl(f, "MonumentFinial", Vector3.new(3.2, 2.0, 2.0), Vector3.new(0, PAVE + 37.9, 119), C.BRASS, M.Metal, 90,
		"Monument", 6)
	made += 5

	-- 2 trụ cổng phía Nam (không vòm ngang để không cắt tượng đài)
	for i, sgn in ipairs({ -1, 1 }) do
		K.box(f, "GatePillar" .. i, Vector3.new(4.4, 18, 4.4), Vector3.new(sgn * 40, PAVE + 9, 127), C.MARBLE,
			M.Marble, 220, "Gate", 2)
		K.box(f, "GateCap" .. i, Vector3.new(5.6, 1.6, 5.6), Vector3.new(sgn * 40, PAVE + 18.6, 127), C.BRASS,
			M.Metal, 110, "Gate", 3)
		K.sign(f, "GateSign" .. i, Vector3.new(sgn * 40, PAVE + 15.4, 129.3), Vector3.new(4.2, 2.2, 0.3),
			Enum.NormalId.Back, "LEGION", C.GRANITE, Color3.fromRGB(240, 226, 190), 60, 12)
		made += 3
	end
	-- 6 cột đèn công viên
	for i = 1, 3 do
		made += K.lampPost(f, "ParkLampW" .. i, Vector3.new(-82, PAVE, 84 + (i - 1) * 18), 10, C.GRANITE, C.NEON, 90)
		made += K.lampPost(f, "ParkLampE" .. i, Vector3.new(82, PAVE, 84 + (i - 1) * 18), 10, C.GRANITE, C.NEON, 90)
	end
	return made
end

function Module.build(modulesContainer: Instance): Instance
	local root = K.folder("Plot_C2_LegionSquare", modulesContainer)
	root:SetAttribute("PlotId", "Plot_C2")
	root:SetAttribute("ModuleId", Module.Id)
	root:SetAttribute("MainEntrance", "X=0, Z=126 (cổng vòm 38 stud) — trục Bắc–Nam xuyên quảng trường")
	root:SetAttribute("TestDrive", "Bãi thử Z −8…42, quầy C2_TESTDRIVE ở (0 · 52)")
	root:SetAttribute("StudsPerMeter", SPM)

	buildPaving(K.folder("01_Paving", root))
	buildPaddock(K.folder("02_TestPaddock", root))
	buildPlaza(K.folder("03_Plaza", root))
	buildFountain(K.folder("04_Fountain", root))
	buildPark(K.folder("05_Park", root))

	local stat = K.perf(root)
	root:SetAttribute("PartCount", stat.parts)
	return root
end

return Module
