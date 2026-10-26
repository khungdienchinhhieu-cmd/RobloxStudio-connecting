--!strict
--[[
	Plot_E2_LaMesaGarage.luau  (Sync v27 — vòng quét V6, Agent A)
	================================================================================
	LA MESA CUSTOMS — xưởng độ xe công nghiệp, 3 khoang cầu nâng
	Ô đất   : Plot_E2 (La Mesa)  X 358…536 · Z −204…−60 · nền Y = 1,15
	Mặt tiền: Nam (+Z, Z = −96) nhìn ra Olympic Fwy (Z = −36)

	Chức năng: quầy `E2_GARAGE` (REPAIR_CAR $150, sửa xe rẻ hơn LS Customs)
	tự dựng trước cửa xưởng khi module này được nạp.

	KIẾN TRÚC
	  • 3 khoang cửa cuốn 18 × 12 stud, mỗi khoang 1 cầu nâng 2 trụ + đèn soi gầm.
	  • Bên trong: vách dụng cụ (36 móc), 6 kệ lốp 4 tầng, máy chẩn đoán, dyno 2 trục,
	    buồng sơn kín, kho phụ tùng, phòng khách kính có sofa + quầy thu ngân.
	  • Mái: 4 ống xả khí thải, 3 HVAC, tháp nước, biển "LA MESA CUSTOMS" hai mặt.
	  • Sân: hàng rào lưới B40, 6 đèn pha, 3 xe phế, 8 thùng phuy, 4 pallet, cẩu tay.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local K = require(Shared:WaitForChild("World"):WaitForChild("BuildKit"))

local Module = {
	Id = "Plot_E2_LaMesaGarage",
	PlotId = "Plot_E2",
	Order = 63,
	Enabled = true,
}

local M = Enum.Material
local G = K.GROUND
local SPM = K.STUDS_PER_METER

local C = {
	WALL = Color3.fromRGB(198, 196, 188),
	WALL_D = Color3.fromRGB(158, 156, 148),
	STEEL = Color3.fromRGB(172, 176, 182),
	STEEL_D = Color3.fromRGB(118, 122, 128),
	DARK = Color3.fromRGB(40, 42, 46),
	FLOOR = Color3.fromRGB(118, 118, 114),
	FLOOR_D = Color3.fromRGB(96, 96, 92),
	YELLOW = Color3.fromRGB(226, 186, 52),
	ORANGE = Color3.fromRGB(214, 110, 40),
	RED = Color3.fromRGB(170, 46, 44),
	BLUE = Color3.fromRGB(52, 92, 150),
	GLASS = Color3.fromRGB(146, 186, 196),
	TIRE = Color3.fromRGB(26, 26, 28),
	RUST = Color3.fromRGB(136, 92, 62),
	CHAIN = Color3.fromRGB(150, 152, 156),
	LEAF = Color3.fromRGB(78, 118, 70),
}

local BX0, BX1 = 372, 512
local BZ0, BZ1 = -196, -96
local CX, CZ = (BX0 + BX1) * 0.5, (BZ0 + BZ1) * 0.5
local FLOOR = G + 0.15
local H1 = 18.0
local SLAB = 1.2
local Y_ROOF = FLOOR + H1 + SLAB
local WT = 1.4

-- 3 khoang cửa cuốn: rộng 18, cao 12, cách nhau 8 stud
local BAY_W, BAY_H = 18, 12
local BAY_X = { CX - 28, CX, CX + 28 }

local FRONT_OPEN = {}
for _, bx in ipairs(BAY_X) do
	table.insert(FRONT_OPEN, { a = bx - BAY_W * 0.5, b = bx + BAY_W * 0.5, y0 = FLOOR, y1 = FLOOR + BAY_H })
end

local function buildShell(f: Instance): number
	local grp = "GarageShell"
	local made = 0
	K.box(f, "BaseSlab", Vector3.new(BX1 - BX0 + 0.4, FLOOR - G, BZ1 - BZ0 + 0.4),
		Vector3.new(CX, (G + FLOOR) * 0.5, CZ), C.FLOOR_D, M.Concrete, nil, grp, 1, { canCollide = true })
	made += 1
	made += K.tileField(f, "ShopFloor", BX0 + 1, BX1 - 1, BZ0 + 1, BZ1 - 1, FLOOR, 4.6, 140,
		C.FLOOR, C.FLOOR_D, grp, 0.14)
	-- vạch kẻ vàng khoanh vùng khoang sửa
	for i, bx in ipairs(BAY_X) do
		K.box(f, "BayStripeL" .. i, Vector3.new(0.4, 0.06, 34), Vector3.new(bx - 11, FLOOR + 0.09, BZ1 - 20),
			C.YELLOW, M.SmoothPlastic, 30, grp, 1, { canCollide = false, castShadow = false })
		K.box(f, "BayStripeR" .. i, Vector3.new(0.4, 0.06, 34), Vector3.new(bx + 11, FLOOR + 0.09, BZ1 - 20),
			C.YELLOW, M.SmoothPlastic, 30, grp, 1, { canCollide = false, castShadow = false })
		made += 2
	end

	made += K.wall(f, "SouthWall", "X", BZ1 - WT * 0.5, BX0, BX1, FLOOR, Y_ROOF, WT,
		C.WALL, M.Concrete, 300, grp, FRONT_OPEN)
	made += K.wall(f, "NorthWall", "X", BZ0 + WT * 0.5, BX0, BX1, FLOOR, Y_ROOF, WT,
		C.WALL_D, M.Concrete, 320, grp, {
			{ a = BX1 - 40, b = BX1 - 22, y0 = FLOOR + 2, y1 = FLOOR + 10 }, -- cửa kho
		})
	made += K.wall(f, "WestWall", "Z", BX0 + WT * 0.5, BZ0, BZ1, FLOOR, Y_ROOF, WT,
		C.WALL_D, M.Concrete, 300, grp, {
			{ a = -170, b = -150, y0 = FLOOR + 4, y1 = FLOOR + 11 },
			{ a = -140, b = -120, y0 = FLOOR + 4, y1 = FLOOR + 11 },
		})
	made += K.wall(f, "EastWall", "Z", BX1 - WT * 0.5, BZ0, BZ1, FLOOR, Y_ROOF, WT,
		C.WALL_D, M.Concrete, 300, grp, nil)

	-- dầm thép + mái tole
	K.box(f, "RingBeam", Vector3.new(BX1 - BX0 + 1, 1.4, BZ1 - BZ0 + 1),
		Vector3.new(CX, Y_ROOF - 0.7, CZ), C.STEEL_D, M.Metal, 320, grp, 5, { canCollide = false })
	made += 1

	-- 10 nan cửa cuốn mỗi khoang (máu 90 — bắn/phá được)
	for i, bx in ipairs(BAY_X) do
		for s = 1, 10 do
			K.box(f, string.format("RollupSlat_%d_%d", i, s), Vector3.new(BAY_W - 0.6, 1.05, 0.5),
				Vector3.new(bx, FLOOR + 0.6 + (s - 1) * 1.12, BZ1 - 0.4), C.STEEL, M.Metal, 90, "RollupDoor", s)
			made += 1
		end
		K.box(f, "RollupLintel" .. i, Vector3.new(BAY_W + 2.4, 1.6, 1.4), Vector3.new(bx, FLOOR + BAY_H + 0.8, BZ1 - 0.5),
			C.YELLOW, M.Metal, 200, "RollupDoor", 11)
		K.box(f, "RollupHeader" .. i, Vector3.new(BAY_W + 4, 3.0, 2.0), Vector3.new(bx, FLOOR + BAY_H + 3.2, BZ1),
			C.WALL, M.Concrete, 220, "RollupDoor", 12)
		made += 2
	end
	return made
end

local function buildLift(f: Instance, idx: number, bx: number): number
	local made = 0
	local grp = "Lift" .. idx
	-- bệ nâng
	K.box(f, "LiftPlatform" .. idx, Vector3.new(20, 0.7, 30), Vector3.new(bx, FLOOR + 0.35, BZ1 - 20),
		C.STEEL, M.DiamondPlate, 240, grp, 1)
	for i, sx in ipairs({ -8.5, 8.5 }) do
		K.box(f, string.format("LiftPost_%d_%d", idx, i), Vector3.new(1.6, 11, 1.6),
			Vector3.new(bx + sx, FLOOR + 5.5, BZ1 - 32), C.STEEL_D, M.Metal, 220, grp, 2)
		K.box(f, string.format("LiftPostFoot_%d_%d", idx, i), Vector3.new(3.0, 1.0, 3.0),
			Vector3.new(bx + sx, FLOOR + 0.5, BZ1 - 32), C.DARK, M.Metal, 160, grp, 1)
		made += 2
	end
	K.box(f, "LiftCross" .. idx, Vector3.new(19, 1.2, 1.4), Vector3.new(bx, FLOOR + 10.4, BZ1 - 32),
		C.STEEL_D, M.Metal, 200, grp, 3)
	-- đèn soi gầm
	for i = -1, 1 do
		K.box(f, string.format("UnderLight_%d_%d", idx, i), Vector3.new(4, 0.4, 1.2),
			Vector3.new(bx + i * 6, FLOOR + 0.75, BZ1 - 12), Color3.fromRGB(255, 248, 224), M.Neon, 20, grp, 1,
			{ canCollide = false, castShadow = false })
		made += 1
	end
	-- vách dụng cụ sau khoang
	K.box(f, "ToolWall" .. idx, Vector3.new(16, 9, 0.6), Vector3.new(bx, FLOOR + 5.4, BZ0 + 8),
		C.STEEL_D, M.Metal, 200, grp, 2)
	for i = 1, 12 do
		K.box(f, string.format("ToolHook_%d_%d", idx, i), Vector3.new(0.3, 0.9, 0.5),
			Vector3.new(bx - 6.6 + (i - 1) * 1.2, FLOOR + 7.4, BZ0 + 8.6), C.STEEL, M.Metal, 20, grp, 2,
			{ canCollide = false, castShadow = false })
		made += 1
	end
	return made
end

local function buildEquipment(f: Instance): number
	local made = 0
	local grp = "Equipment"
	-- 6 kệ lốp (4 tầng), xếp 5 lốp mỗi tầng
	for r = 1, 6 do
		local x = BX0 + 10 + (r - 1) * 5.4
		for t = 1, 4 do
			K.box(f, string.format("TireRack_%d_%d", r, t), Vector3.new(5, 0.4, 18),
				Vector3.new(x, FLOOR + t * 3.4, BZ0 + 22), C.STEEL_D, M.Metal, 90, "TireRack", t)
			for k = 1, 4 do
				K.cyl(f, string.format("Tire_%d_%d_%d", r, t, k), Vector3.new(1.3, 3.4, 3.4),
					Vector3.new(x, FLOOR + t * 3.4 + 0.9, BZ0 + 15 + k * 4), C.TIRE, M.Rubber, 40, "TireRack", t,
					{ canCollide = false, castShadow = false })
				made += 1
			end
			made += 1
		end
	end

	-- máy chẩn đoán + tủ đồ nghề
	K.box(f, "DiagnosticCart", Vector3.new(4, 6, 3), Vector3.new(BX1 - 12, FLOOR + 3, BZ1 - 14), C.BLUE, M.Metal, 100,
		"Equipment", 1)
	K.box(f, "DiagnosticScreen", Vector3.new(3.4, 2.6, 0.3), Vector3.new(BX1 - 12, FLOOR + 6.4, BZ1 - 13.6),
		Color3.fromRGB(24, 40, 60), M.Neon, 30, "Equipment", 2, { canCollide = false, castShadow = false })
	K.box(f, "ToolChest", Vector3.new(9, 4.4, 5), Vector3.new(BX1 - 24, FLOOR + 2.2, BZ1 - 12), C.RED, M.Metal, 120,
		"Equipment", 1)
	for i = 1, 4 do
		K.box(f, "ToolDrawer" .. i, Vector3.new(8.6, 0.8, 4.6), Vector3.new(BX1 - 24, FLOOR + 0.9 * i + 0.4, BZ1 - 12),
			C.DARK, M.Metal, 30, "Equipment", 2, { canCollide = false })
		made += 1
	end
	made += 2

	-- dyno 2 trục sau xưởng
	for i, dz in ipairs({ 0, 12 }) do
		K.box(f, "DynoRoller" .. i, Vector3.new(9, 0.9, 4), Vector3.new(BX0 + 22, FLOOR + 1.6, BZ0 + 52 + dz),
			C.STEEL, M.DiamondPlate, 140, "Dyno", 1)
		K.cyl(f, "DynoAxle" .. i, Vector3.new(0.8, 4.0, 4.0), Vector3.new(BX0 + 22, FLOOR + 1.4, BZ0 + 52 + dz),
			C.DARK, M.Metal, 80, "Dyno", 1, { canCollide = false })
		made += 2
	end
	K.box(f, "DynoBase", Vector3.new(11, 1.0, 18), Vector3.new(BX0 + 22, FLOOR + 0.5, BZ0 + 58), C.DARK, M.Metal, 160,
		"Dyno", 1)
	made += 1

	-- buồng sơn kín (góc Đông-Bắc)
	K.box(f, "PaintBooth", Vector3.new(30, 16, 24), Vector3.new(BX1 - 18, FLOOR + 8, BZ0 + 18), C.WALL, M.Metal, 300,
		"PaintBooth", 2)
	K.box(f, "PaintBoothDoor", Vector3.new(0.5, 12, 16), Vector3.new(BX1 - 33.2, FLOOR + 6, BZ0 + 18), C.GLASS, M.Glass,
		40, "PaintBooth", 2, { canCollide = false, castShadow = false, transparency = 0.3 })
	K.box(f, "PaintBoothFilter", Vector3.new(6, 4, 0.6), Vector3.new(BX1 - 18, FLOOR + 14, BZ0 + 30), C.STEEL, M.Metal,
		60, "PaintBooth", 3)
	made += 3

	-- phòng khách kính + quầy thu ngân (góc Tây-Bắc)
	K.box(f, "OfficeSlab", Vector3.new(30, 0.6, 24), Vector3.new(BX0 + 20, FLOOR + 8.6, BZ0 + 18), C.WOOD_D, M.WoodPlanks,
		200, "Office", 2)
	for _, wall in ipairs({
		{ "OfficeGlassS", Vector3.new(30, 8, 0.3), Vector3.new(BX0 + 20, FLOOR + 4.3, BZ0 + 30) },
		{ "OfficeGlassE", Vector3.new(0.3, 8, 24), Vector3.new(BX0 + 35, FLOOR + 4.3, BZ0 + 18) },
	}) do
		K.box(f, wall[1], wall[2], wall[3], C.GLASS, M.Glass, 40, "Office", 1,
			{ canCollide = false, castShadow = false, transparency = 0.3 })
		made += 1
	end
	K.box(f, "OfficeDesk", Vector3.new(10, 3.2, 5), Vector3.new(BX0 + 18, FLOOR + 1.6, BZ0 + 18), C.WOOD, M.Wood, 100,
		"Office", 1)
	K.box(f, "OfficeSofa", Vector3.new(4, 3, 12), Vector3.new(BX0 + 10, FLOOR + 1.5, BZ0 + 18), C.RED, M.Fabric, 90,
		"Office", 1)
	K.box(f, "OfficeCounter", Vector3.new(6, 4.2, 10), Vector3.new(BX0 + 32, FLOOR + 2.1, BZ0 + 18), C.WOOD_D, M.Wood,
		120, "Office", 1)
	made += 4

	-- cầu trục nhỏ chạy dọc xưởng
	K.box(f, "CraneRailA", Vector3.new(BX1 - BX0 - 10, 0.8, 1.2), Vector3.new(CX, Y_ROOF - 2.4, BZ0 + 40),
		C.STEEL_D, M.Metal, 120, "Crane", 5, { canCollide = false })
	K.box(f, "CraneRailB", Vector3.new(BX1 - BX0 - 10, 0.8, 1.2), Vector3.new(CX, Y_ROOF - 2.4, BZ0 + 70),
		C.STEEL_D, M.Metal, 120, "Crane", 5, { canCollide = false })
	K.box(f, "CraneHoist", Vector3.new(4, 3, 4), Vector3.new(CX, Y_ROOF - 4.2, BZ0 + 55), C.YELLOW, M.Metal, 90,
		"Crane", 6, { canCollide = false })
	K.cyl(f, "CraneChain", Vector3.new(6, 0.3, 0.3), Vector3.new(CX, Y_ROOF - 7.6, BZ0 + 55), C.CHAIN, M.Metal, 30,
		"Crane", 6, { canCollide = false })
	made += 4
	return made
end

local function buildRoof(f: Instance): number
	local made = 0
	local grp = "GarageRoof"
	K.box(f, "RoofDeck", Vector3.new(BX1 - BX0 + 1.6, SLAB, BZ1 - BZ0 + 1.6),
		Vector3.new(CX, Y_ROOF - SLAB * 0.5, CZ), C.STEEL_D, M.CorrugatedMetal, 340, grp, 6, { canCollide = true })
	made += 1
	-- 4 ống xả khí thải cao
	for i = 1, 4 do
		local x = BX0 + 24 + (i - 1) * 30
		K.cyl(f, "ExhaustStack" .. i, Vector3.new(12, 3.0, 3.0), Vector3.new(x, Y_ROOF + 6, CZ + 10),
			C.STEEL, M.Metal, 140, grp, 7)
		K.cyl(f, "ExhaustCap" .. i, Vector3.new(1.2, 3.8, 3.8), Vector3.new(x, Y_ROOF + 12.4, CZ + 10),
			C.DARK, M.Metal, 60, grp, 8)
		made += 2
	end
	for i = 1, 3 do
		K.box(f, "RoofHVAC" .. i, Vector3.new(9, 4, 7), Vector3.new(BX0 + 30 + (i - 1) * 28, Y_ROOF + 2, BZ0 + 26),
			C.WALL_D, M.Metal, 110, grp, 6)
		made += 1
	end
	K.cyl(f, "RoofTank", Vector3.new(7, 8, 8), Vector3.new(BX1 - 20, Y_ROOF + 4, BZ0 + 22), C.STEEL, M.Metal, 130,
		grp, 6)
	K.box(f, "RoofBeacon", Vector3.new(1.4, 1.4, 1.4), Vector3.new(CX, Y_ROOF + 1.6, BZ1 - 6), C.ORANGE, M.Neon, 20,
		grp, 7, { canCollide = false, castShadow = false })
	made += 2
	return made
end

local function buildForecourt(f: Instance): number
	local made = 0
	local grp = "Yard"
	made += K.tileField(f, "YardConcrete", 362, 532, BZ1, -62, G + 0.07, 4.4, 80, C.FLOOR, C.FLOOR_D, grp, 0.14)

	-- hàng rào lưới B40 + cổng
	local function fence(name: string, axis: string, fixed: number, a0: number, a1: number)
		local span = a1 - a0
		local posts = math.max(2, math.floor(span / 10) + 1)
		for i = 0, posts - 1 do
			local a = a0 + (i / (posts - 1)) * span
			local pos = if axis == "X" then Vector3.new(a, G + 3.4, fixed) else Vector3.new(fixed, G + 3.4, a)
			K.cyl(f, string.format("%s_Post%d", name, i), Vector3.new(6.8, 0.35, 0.35), pos, C.STEEL, M.Metal, 80, name, 2,
				{ canCollide = false })
			made += 1
		end
		-- lưới: các thanh mảnh chạy dọc
		for i = 1, 3 do
			local pos = if axis == "X" then Vector3.new((a0 + a1) * 0.5, G + 1.2 + i * 1.6, fixed)
				else Vector3.new(fixed, G + 1.2 + i * 1.6, (a0 + a1) * 0.5)
			local size = if axis == "X" then Vector3.new(span, 0.16, 0.16) else Vector3.new(0.16, 0.16, span)
			K.box(f, string.format("%s_Mesh%d", name, i), size, pos, C.CHAIN, M.Metal, 30, name, 2,
				{ canCollide = false, castShadow = false })
			made += 1
		end
	end
	fence("FenceWest", "Z", 362, BZ1, -64)
	fence("FenceSouth", "X", -63, 362, 408)
	fence("FenceSouthE", "X", -63, 462, 532)
	fence("FenceEast", "Z", 532, BZ1, -64)

	-- cột đèn pha 6 cái
	for i = 1, 6 do
		local col = (i - 1) % 3
		local row = math.floor((i - 1) / 3)
		made += K.lampPost(f, "YardLamp" .. i,
			Vector3.new(372 + col * 56, G, -70 - row * 18), 14, C.STEEL_D, Color3.fromRGB(255, 246, 208), 110)
	end

	-- 3 xe phế + phụ tùng
	made += K.car(f, "JunkA", Vector3.new(392, G, -84), math.rad(24), C.RUST, 120, "JunkCar")
	made += K.car(f, "JunkB", Vector3.new(424, G, -78), math.rad(-15), Color3.fromRGB(96, 80, 66), 120, "JunkCar")
	made += K.car(f, "JunkC", Vector3.new(500, G, -86), math.rad(70), Color3.fromRGB(70, 78, 70), 120, "JunkCar")

	-- 8 thùng phuy + 4 pallet
	for i = 1, 8 do
		K.cyl(f, "Drum" .. i, Vector3.new(4.4, 3.0, 3.0),
			Vector3.new(470 + (i % 4) * 4.5, G + 2.2, -80 - math.floor((i - 1) / 4) * 6),
			if i % 2 == 0 then C.RED else C.BLUE, M.Metal, 70, "Drum", 1)
		made += 1
	end
	for i = 1, 4 do
		K.box(f, "Pallet" .. i, Vector3.new(6, 0.5, 7), Vector3.new(516, G + 0.4, -80 - i * 8), C.RUST, M.Wood, 50,
			"Pallet", 1)
		made += 1
	end

	-- biển pylons hai mặt
	K.box(f, "PylonBase", Vector3.new(7, 2.2, 7), Vector3.new(388, G + 1.1, -70), C.DARK, M.Metal, 160, "Pylon", 1)
	K.cyl(f, "PylonPole", Vector3.new(20, 1.8, 1.8), Vector3.new(388, G + 11, -70), C.STEEL_D, M.Metal, 140,
		"Pylon", 2)
	K.sign(f, "PylonSign", Vector3.new(388, G + 22, -70), Vector3.new(26, 8, 0.8), Enum.NormalId.Back,
		"LA MESA CUSTOMS", C.DARK, C.ORANGE, 120, 16)
	K.sign(f, "PylonSignRear", Vector3.new(388, G + 22, -70.9), Vector3.new(26, 8, 0.8), Enum.NormalId.Front,
		"SỬA XE · ĐỘ XE · ĐỒNG SƠN", C.DARK, C.YELLOW, 120, 16)
	made += 4

	-- biển hiệu trên mái
	K.sign(f, "RoofSign", Vector3.new(CX, Y_ROOF + 7, BZ1 - 1), Vector3.new(70, 9, 1.0), Enum.NormalId.Back,
		"LA MESA CUSTOMS", C.DARK, C.ORANGE, 150, 14)
	made += 1
	return made
end

function Module.build(modulesContainer: Instance): Instance
	local root = K.folder("Plot_E2_LaMesaGarage", modulesContainer)
	root:SetAttribute("PlotId", "Plot_E2")
	root:SetAttribute("ModuleId", Module.Id)
	root:SetAttribute("MainEntrance", "X=442, Z=-96 (3 cửa cuốn 18 × 12 stud), sân rào lưới Z -96…-62")
	root:SetAttribute("Bays", "3 khoang, mỗi khoang cầu nâng 2 trụ 11 stud")
	root:SetAttribute("StudsPerMeter", SPM)

	buildShell(K.folder("01_Shell", root))
	local lifts = K.folder("02_Lifts", root)
	for i, bx in ipairs(BAY_X) do
		buildLift(lifts, i, bx)
	end
	buildEquipment(K.folder("03_Equipment", root))
	buildRoof(K.folder("04_Roof", root))
	buildForecourt(K.folder("05_Yard", root))

	local stat = K.perf(root)
	root:SetAttribute("PartCount", stat.parts)
	return root
end

return Module
