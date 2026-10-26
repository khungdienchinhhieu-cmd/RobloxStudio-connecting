--!strict
--[[
	Plot_E3_LittleSeoulDiner.luau  (Sync v27 — vòng quét V6, Agent A)
	================================================================================
	SEOUL GARDEN — nhà hàng thịt nướng Hàn Quốc, 2 tầng + sân thượng
	Ô đất   : Plot_E3 (Little Seoul)  X −536…−358 · Z −12…128 · nền Y = 1,15
	Mặt tiền: Nam (+Z, Z = 106) nhìn ra Vespucci Blvd (Z = 148)

	Vì sao "mỗi nhà phải có chức năng": quầy `E3_FOOD` (HEAL $20, hồi 50 máu) của
	BuildingServices sẽ tự dựng trước hiên nhà này khi module được nạp.

	KIẾN TRÚC
	  • Tầng trệt 15 stud (≈4,5 m): sảnh nướng 12 bàn (mỗi bàn có bếp than hồng +
	    chụp hút), quầy bar gỗ dài, bếp mở sau quầy chuyển thức ăn, 2 WC.
	  • Tầng 2 (Y 16,15): 4 phòng riêng có vách gỗ + chiếu (ondol), hành lang kính,
	    sân thượng trước có lan can kính nhìn ra đại lộ.
	  • Mái (Y 27,15): diềm mái ngói cong kiểu hanok, 4 ống khói hút mùi, 3 cục HVAC,
	    bồn nước inox, giàn pin mặt trời nhỏ.
	  • Hiên trước: sàn gỗ 16 stud, 8 đèn lồng giấy, vách tre, bảng menu đèn neon,
	    biển chính "SEOUL GARDEN" + biển dọc chữ Hàn.
	  • Bãi đỗ 4 xe phía Tây + 2 xe đang đỗ.
	Chuẩn dự án: mọi khối qua PartBuilder (có máu ẩn), khối < 1,2 stud không va chạm,
	kính/neon không đổ bóng, SurfaceGui MaxDistance 340 / PixelsPerStud ≤ 32.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local K = require(Shared:WaitForChild("World"):WaitForChild("BuildKit"))

local Module = {
	Id = "Plot_E3_LittleSeoulDiner",
	PlotId = "Plot_E3",
	Order = 60,
	Enabled = true,
}

local M = Enum.Material
local G = K.GROUND -- 1,15 (mặt vỉa hè)
local SPM = K.STUDS_PER_METER

-- ── màu ──────────────────────────────────────────────────────────────────────
local C = {
	STONE = Color3.fromRGB(196, 188, 176),
	STONE_D = Color3.fromRGB(150, 142, 132),
	WOOD = Color3.fromRGB(126, 86, 52),
	WOOD_D = Color3.fromRGB(86, 58, 36),
	WOOD_L = Color3.fromRGB(168, 124, 82),
	WALL = Color3.fromRGB(232, 226, 214),
	WALL_D = Color3.fromRGB(206, 198, 184),
	ROOF = Color3.fromRGB(58, 62, 70),
	TILE = Color3.fromRGB(74, 52, 44),
	GLASS = Color3.fromRGB(150, 196, 206),
	GLASS_D = Color3.fromRGB(96, 132, 142),
	FRAME = Color3.fromRGB(52, 56, 62),
	NEON = Color3.fromRGB(255, 78, 92),
	NEON2 = Color3.fromRGB(255, 196, 84),
	PAPER = Color3.fromRGB(255, 226, 176),
	STEEL = Color3.fromRGB(176, 182, 190),
	DARK = Color3.fromRGB(34, 36, 40),
	CHAR = Color3.fromRGB(48, 46, 46),
	EMBER = Color3.fromRGB(255, 120, 40),
	LEAF = Color3.fromRGB(72, 128, 78),
	LEAF2 = Color3.fromRGB(96, 152, 88),
	BAMBOO = Color3.fromRGB(150, 170, 96),
	RED = Color3.fromRGB(158, 44, 44),
}

-- ── kích thước ───────────────────────────────────────────────────────────────
local BX0, BX1 = -500, -380 -- thân nhà 120 stud (chừa dải 30 stud phía Tây cho bãi đỗ)
local BZ0, BZ1 = 16, 106 -- sâu 90 stud, mặt tiền Z = 106
local FLOOR = G + 0.15 -- mặt sàn trệt
local H1 = 15.0 -- thông thuỷ tầng trệt (≈4,5 m)
local SLAB = 1.2
local Y2 = FLOOR + H1 + SLAB -- 16,15 → mặt sàn tầng 2
local H2 = 11.0
local Y_ROOF = Y2 + H2 + SLAB -- ~28,35
local WT = 1.4 -- dày tường ngoài

local CX = (BX0 + BX1) * 0.5
local CZ = (BZ0 + BZ1) * 0.5

-- ── mặt tiền: 5 vịnh kính, cửa đôi giữa ─────────────────────────────────────
local BAY = (BX1 - BX0 - 8) / 5
local DOOR_W = 14
local DOOR_X0 = CX - DOOR_W * 0.5
local DOOR_X1 = CX + DOOR_W * 0.5

local FRONT_OPENINGS = {} :: { any }
for i = 1, 5 do
	local a = BX0 + 4 + (i - 1) * BAY
	local b = a + BAY
	if i == 3 then
		-- vịnh giữa: cửa đôi đi bộ
		table.insert(FRONT_OPENINGS, { a = DOOR_X0, b = DOOR_X1, y0 = FLOOR, y1 = FLOOR + 9.0 })
	else
		table.insert(FRONT_OPENINGS, { a = a + 0.8, b = b - 0.8, y0 = FLOOR + 2.4, y1 = FLOOR + 10.6 })
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CÁC PHẦN
-- ══════════════════════════════════════════════════════════════════════════════

local function buildGround(f: Instance): number
	local grp = "SeoulGround"
	local made = 0

	-- sàn bê tông + gạch caro
	-- sàn nằm TRỌN trong khoảng G…FLOOR: không thò xuống dưới mặt vỉa hè
	K.box(f, "GroundSlab", Vector3.new(BX1 - BX0 + 0.4, FLOOR - G, BZ1 - BZ0 + 0.4),
		Vector3.new(CX, (G + FLOOR) * 0.5, CZ), C.STONE_D, M.Concrete, nil, grp, 1, { canCollide = true })
	made += 1
	made += K.tileField(f, "HallTile", BX0 + 1, BX1 - 1, BZ0 + 1, BZ1 - 1, FLOOR, 4.6, 120,
		C.STONE, C.STONE_D, grp, 0.14)

	-- tường bao quanh (mặt Nam có 5 vịnh kính)
	made += K.wall(f, "SouthWall", "X", BZ1 - WT * 0.5, BX0, BX1, FLOOR, FLOOR + H1, WT,
		C.WALL, M.Concrete, 240, grp, FRONT_OPENINGS)
	made += K.wall(f, "NorthWall", "X", BZ0 + WT * 0.5, BX0, BX1, FLOOR, FLOOR + H1, WT,
		C.WALL_D, M.Concrete, 260, grp, {
			{ a = BX0 + 10, b = BX0 + 22, y0 = FLOOR, y1 = FLOOR + 8.5 }, -- cửa hậu
			{ a = BX1 - 34, b = BX1 - 22, y0 = FLOOR + 4, y1 = FLOOR + 9 }, -- cửa sổ bếp
		})
	made += K.wall(f, "WestWall", "Z", BX0 + WT * 0.5, BZ0, BZ1, FLOOR, FLOOR + H1, WT,
		C.WALL, M.Concrete, 240, grp, {
			{ a = 30, b = 40, y0 = FLOOR + 3.2, y1 = FLOOR + 9.4 },
			{ a = 62, b = 72, y0 = FLOOR + 3.2, y1 = FLOOR + 9.4 },
		})
	made += K.wall(f, "EastWall", "Z", BX1 - WT * 0.5, BZ0, BZ1, FLOOR, FLOOR + H1, WT,
		C.WALL, M.Concrete, 240, grp, {
			{ a = 34, b = 44, y0 = FLOOR + 3.2, y1 = FLOOR + 9.4 },
			{ a = 64, b = 74, y0 = FLOOR + 3.2, y1 = FLOOR + 9.4 },
		})

	-- vách kính mặt tiền (2 lớp mảnh: kính + khung gỗ)
	made += K.curtain(f, "FrontGlass", "X", BZ1 - 0.35, BX0 + 4, BX1 - 4, FLOOR + 2.5, FLOOR + 10.5,
		10, 3, C.GLASS, C.WOOD_D, 38, "FrontGlass")
	-- cửa đôi gỗ + kính
	for i, sgn in ipairs({ -1, 1 }) do
		local dx = CX + sgn * DOOR_W * 0.25
		K.box(f, string.format("DoorLeaf_%d", i), Vector3.new(DOOR_W * 0.5 - 0.4, 8.8, 0.26),
			Vector3.new(dx, FLOOR + 4.4, BZ1 - 0.4), C.GLASS, M.Glass, 40, "MainDoor", 1,
			{ canCollide = false, castShadow = false, transparency = 0.25 })
		K.box(f, string.format("DoorFrameL_%d", i), Vector3.new(0.34, 9.2, 0.5),
			Vector3.new(dx - DOOR_W * 0.25, FLOOR + 4.6, BZ1 - 0.4), C.WOOD_D, M.Wood, 120, "MainDoor", 2)
		K.box(f, string.format("DoorFrameR_%d", i), Vector3.new(0.34, 9.2, 0.5),
			Vector3.new(dx + DOOR_W * 0.25, FLOOR + 4.6, BZ1 - 0.4), C.WOOD_D, M.Wood, 120, "MainDoor", 2)
		K.cyl(f, string.format("DoorHandle_%d", i), Vector3.new(0.7, 0.22, 0.22),
			Vector3.new(dx + sgn * -1.4, FLOOR + 4.2, BZ1 - 0.2), C.STEEL, M.Metal, 40, "MainDoor", 3)
		made += 5
	end

	-- dầm bo quanh đỉnh tường
	K.box(f, "RingBeam", Vector3.new(BX1 - BX0 + 1.0, 1.1, BZ1 - BZ0 + 1.0),
		Vector3.new(CX, FLOOR + H1 + 0.55, CZ), C.WOOD_D, M.Wood, 300, grp, 4, { canCollide = false })
	made += 1

	-- trần gỗ + đèn thả
	made += K.tileField(f, "CeilingPanel", BX0 + 2, BX1 - 2, BZ0 + 2, BZ1 - 2, FLOOR + H1 - 0.15, 6.0, 90,
		C.WOOD_L, C.WOOD, grp, 0.2)
	for i = 1, 6 do
		local x = BX0 + 14 + (i - 1) * 22
		K.box(f, string.format("PendantRod_%d", i), Vector3.new(0.18, 2.4, 0.18),
			Vector3.new(x, FLOOR + H1 - 1.5, CZ), C.DARK, M.Metal, 30, grp, 4, { canCollide = false })
		K.box(f, string.format("PendantShade_%d", i), Vector3.new(3.0, 1.3, 3.0),
			Vector3.new(x, FLOOR + H1 - 3.2, CZ), C.NEON2, M.Neon, 30, grp, 4, { canCollide = false, castShadow = false })
		made += 2
	end
	return made
end

local function diningTable(f: Instance, idx: number, x: number, z: number): number
	local made = 0
	local g = "DiningTable"
	-- bàn inox
	K.box(f, string.format("TableTop_%d", idx), Vector3.new(7.0, 0.35, 6.0),
		Vector3.new(x, FLOOR + 3.05, z), C.STEEL, M.DiamondPlate, 70, g, 1)
	K.cyl(f, string.format("TableLeg_%d", idx), Vector3.new(2.9, 0.9, 0.9),
		Vector3.new(x, FLOOR + 1.55, z), C.DARK, M.Metal, 90, g, 1)
	made += 2
	-- bếp than giữa bàn
	K.cyl(f, string.format("GrillRing_%d", idx), Vector3.new(0.5, 4.2, 4.2),
		Vector3.new(x, FLOOR + 3.25, z), C.CHAR, M.Metal, 60, g, 2, { canCollide = false })
	K.cyl(f, string.format("GrillEmber_%d", idx), Vector3.new(0.2, 3.2, 3.2),
		Vector3.new(x, FLOOR + 3.35, z), C.EMBER, M.Neon, 30, g, 3, { canCollide = false, castShadow = false })
	made += 2
	-- chụp hút trên cao
	K.box(f, string.format("HoodCanopy_%d", idx), Vector3.new(5.4, 1.0, 4.6),
		Vector3.new(x, FLOOR + 9.2, z), C.STEEL, M.Metal, 80, g, 4, { canCollide = false })
	K.box(f, string.format("HoodDuct_%d", idx), Vector3.new(1.3, 5.2, 1.3),
		Vector3.new(x, FLOOR + 12.3, z), C.STEEL, M.Metal, 60, g, 5, { canCollide = false })
	made += 2
	-- 4 ghế
	for c, off in ipairs({ { -5.2, 0 }, { 5.2, 0 }, { 0, -4.6 }, { 0, 4.6 } }) do
		local gx, gz = x + off[1] * 0.86, z + off[2] * 0.86
		K.box(f, string.format("ChairSeat_%d_%d", idx, c), Vector3.new(2.2, 0.34, 2.2),
			Vector3.new(gx, FLOOR + 1.75, gz), C.WOOD, M.Wood, 40, g, 1, { canCollide = false })
		K.box(f, string.format("ChairBack_%d_%d", idx, c), Vector3.new(2.2, 2.2, 0.3),
			Vector3.new(gx, FLOOR + 2.9, gz + (if off[2] ~= 0 then (if off[2] > 0 then 1.0 else -1.0) else 0)),
			C.WOOD, M.Wood, 40, g, 2, { canCollide = false })
		made += 2
	end
	return made
end

local function buildDining(f: Instance): number
	local made = 0
	-- 12 bàn: 3 dãy × 4
	local idx = 0
	for row = 1, 4 do
		for col = 1, 3 do
			idx += 1
			local x = BX0 + 26 + (col - 1) * 32
			local z = BZ0 + 30 + (row - 1) * 16
			made += diningTable(f, idx, x, z)
		end
	end

	-- quầy bar gỗ ven tường Đông
	local bar = K.folder("Bar", f)
	K.box(bar, "BarFront", Vector3.new(4.2, 5.6, 44),
		Vector3.new(BX1 - 6.5, FLOOR + 2.8, 66), C.WOOD_D, M.Wood, 220, "Bar", 1)
	K.box(bar, "BarTop", Vector3.new(6.4, 0.5, 45),
		Vector3.new(BX1 - 7.2, FLOOR + 5.85, 66), C.WOOD_L, M.WoodPlanks, 160, "Bar", 2)
	for i = 1, 7 do
		K.cyl(bar, string.format("BarStool_%d", i), Vector3.new(2.4, 1.2, 1.2),
			Vector3.new(BX1 - 12.0, FLOOR + 2.6, 48 + i * 6), C.DARK, M.Metal, 40, "Bar", 1, { canCollide = false })
		K.box(bar, string.format("BarStoolSeat_%d", i), Vector3.new(2.6, 0.4, 2.6),
			Vector3.new(BX1 - 12.0, FLOOR + 3.9, 48 + i * 6), C.WOOD, M.Wood, 40, "Bar", 2, { canCollide = false })
	end
	-- kệ rượu + đèn
	K.box(bar, "BackBar", Vector3.new(1.0, 8.0, 44), Vector3.new(BX1 - 2.2, FLOOR + 6.0, 66),
		C.WOOD_D, M.Wood, 150, "Bar", 2)
	for i = 1, 4 do
		K.box(bar, string.format("BottleShelf_%d", i), Vector3.new(1.8, 0.25, 40),
			Vector3.new(BX1 - 3.4, FLOOR + 3.0 + i * 1.8, 66), C.WOOD_L, M.Wood, 40, "Bar", 3, { canCollide = false })
		for b = 1, 9 do
			K.cyl(bar, string.format("Bottle_%d_%d", i, b), Vector3.new(1.5, 0.7, 0.7),
				Vector3.new(BX1 - 3.4, FLOOR + 3.9 + i * 1.8, 48 + b * 4), C.RED, M.Glass, 20, "Bar", 3,
				{ canCollide = false, castShadow = false })
		end
	end

	-- bếp mở phía Bắc + quầy chuyển thức ăn
	local kitchen = K.folder("Kitchen", f)
	K.box(kitchen, "PassCounter", Vector3.new(BX1 - BX0 - 40, 3.6, 3.0),
		Vector3.new(CX + 4, FLOOR + 1.8, BZ0 + 24), C.STEEL, M.DiamondPlate, 200, "Kitchen", 1)
	for i = 1, 5 do
		K.box(kitchen, string.format("CookRange_%d", i), Vector3.new(6, 3.2, 5),
			Vector3.new(BX0 + 16 + (i - 1) * 18, FLOOR + 1.6, BZ0 + 10), C.DARK, M.Metal, 150, "Kitchen", 1)
		K.cyl(kitchen, string.format("Burner_%d", i), Vector3.new(0.3, 3.0, 3.0),
			Vector3.new(BX0 + 16 + (i - 1) * 18, FLOOR + 3.3, BZ0 + 10), C.EMBER, M.Neon, 20, "Kitchen", 2,
			{ canCollide = false, castShadow = false })
		K.box(kitchen, string.format("PrepTable_%d", i), Vector3.new(7, 0.3, 4),
			Vector3.new(BX0 + 16 + (i - 1) * 18, FLOOR + 3.2, BZ0 + 18), C.STEEL, M.DiamondPlate, 60, "Kitchen", 2)
	end
	K.box(kitchen, "FridgeBank", Vector3.new(26, 9, 4), Vector3.new(BX0 + 30, FLOOR + 4.5, BZ0 + 4.5),
		C.STEEL, M.Metal, 220, "Kitchen", 1)

	-- 2 WC nhỏ góc Tây-Nam
	for i = 1, 2 do
		K.box(f, string.format("ToiletBooth_%d", i), Vector3.new(9, 9.5, 10),
			Vector3.new(BX0 + 8 + (i - 1) * 10.5, FLOOR + 4.75, BZ1 - 12), C.WOOD_L, M.Wood, 180, "Toilet", 1)
		K.box(f, string.format("ToiletDoor_%d", i), Vector3.new(0.25, 8.4, 6),
			Vector3.new(BX0 + 8 + (i - 1) * 10.5 + 4.6, FLOOR + 4.3, BZ1 - 12), C.WOOD_D, M.Wood, 60, "Toilet", 2)
	end
	return made
end

local function buildUpper(f: Instance): number
	local made = 0
	local grp = "SeoulUpper"
	-- sàn tầng 2
	K.box(f, "Level2Slab", Vector3.new(BX1 - BX0 + 1.2, SLAB, BZ1 - BZ0 + 1.2),
		Vector3.new(CX, Y2 - SLAB * 0.5, CZ), C.WOOD_D, M.WoodPlanks, 320, grp, 5, { canCollide = true })
	made += 1
	made += K.tileField(f, "L2Floor", BX0 + 1, BX1 - 1, BZ0 + 1, BZ0 + 74, Y2 + 0.08, 4.6, 100,
		C.WOOD_L, C.WOOD, grp, 0.14)

	-- tường tầng 2 (mặt tiền mở ra sân thượng bằng 4 vịnh kính lớn)
	made += K.wall(f, "L2SouthWall", "X", BZ1 - 22 - WT * 0.5, BX0, BX1, Y2, Y2 + H2, WT,
		C.WALL, M.Concrete, 230, grp, {
			{ a = BX0 + 12, b = BX1 - 12, y0 = Y2 + 2.6, y1 = Y2 + 9.6 },
		})
	made += K.wall(f, "L2NorthWall", "X", BZ0 + WT * 0.5, BX0, BX1, Y2, Y2 + H2, WT,
		C.WALL_D, M.Concrete, 230, grp, nil)
	made += K.wall(f, "L2WestWall", "Z", BX0 + WT * 0.5, BZ0, BZ1 - 22, Y2, Y2 + H2, WT,
		C.WALL, M.Concrete, 230, grp, { { a = 26, b = 38, y0 = Y2 + 3, y1 = Y2 + 9 } })
	made += K.wall(f, "L2EastWall", "Z", BX1 - WT * 0.5, BZ0, BZ1 - 22, Y2, Y2 + H2, WT,
		C.WALL, M.Concrete, 230, grp, { { a = 60, b = 72, y0 = Y2 + 3, y1 = Y2 + 9 } })
	made += K.curtain(f, "L2FrontGlass", "X", BZ1 - 22 - 0.35, BX0 + 12, BX1 - 12, Y2 + 2.6, Y2 + 9.6,
		12, 3, C.GLASS, C.WOOD_D, 36, "L2FrontGlass")

	-- hành lang + 4 phòng riêng (vách gỗ)
	for i = 0, 3 do
		local x0 = BX0 + 4 + i * 33
		K.box(f, string.format("RoomDivider_%d", i), Vector3.new(0.9, H2 - 1, 46),
			Vector3.new(x0, Y2 + (H2 - 1) * 0.5, BZ0 + 30), C.WOOD, M.Wood, 180, grp, 3)
		K.box(f, string.format("RoomShoji_%d", i), Vector3.new(0.4, 8.2, 9),
			Vector3.new(x0 + 2.6, Y2 + 4.1, BZ0 + 56), Color3.fromRGB(244, 236, 216), M.Fabric, 40, grp, 3,
			{ canCollide = false, castShadow = false })
	end
	-- 4 bàn phòng riêng + chiếu
	for i = 1, 4 do
		local x = BX0 + 20 + (i - 1) * 33
		K.box(f, string.format("Tatami_%d", i), Vector3.new(24, 0.3, 20), Vector3.new(x, Y2 + 0.2, BZ0 + 40),
			Color3.fromRGB(206, 196, 158), M.Fabric, 40, grp, 2, { canCollide = false })
		K.box(f, string.format("RoomTable_%d", i), Vector3.new(9, 1.4, 6), Vector3.new(x, Y2 + 1.2, BZ0 + 40),
			C.WOOD_D, M.Wood, 60, grp, 2)
		K.cyl(f, string.format("RoomGrill_%d", i), Vector3.new(0.25, 3.0, 3.0), Vector3.new(x, Y2 + 2.0, BZ0 + 40),
			C.EMBER, M.Neon, 20, grp, 3, { canCollide = false, castShadow = false })
	end

	-- sân thượng trước (Z 84..106)
	made += K.tileField(f, "TerraceDeck", BX0 + 2, BX1 - 2, BZ1 - 22, BZ1 - 1, Y2 + 0.06, 3.4, 90,
		C.WOOD_L, C.WOOD, "Terrace", 0.22)
	made += K.railing(f, "TerraceRail", "X", BZ1 - 1.4, BX0 + 2, BX1 - 2, Y2 + 0.1, 4.6,
		C.DARK, C.GLASS, 60)
	made += K.railing(f, "TerraceRailW", "Z", BX0 + 1.4, BZ1 - 22, BZ1 - 1.4, Y2 + 0.1, 4.6, C.DARK, C.GLASS, 60)
	made += K.railing(f, "TerraceRailE", "Z", BX1 - 1.4, BZ1 - 22, BZ1 - 1.4, Y2 + 0.1, 4.6, C.DARK, C.GLASS, 60)
	for i = 1, 4 do
		local x = BX0 + 18 + (i - 1) * 28
		K.box(f, string.format("TerraceTable_%d", i), Vector3.new(6, 0.3, 5), Vector3.new(x, Y2 + 3.0, BZ1 - 11),
			C.WOOD_D, M.Wood, 50, "Terrace", 3)
		K.cyl(f, string.format("TerraceTableLeg_%d", i), Vector3.new(2.9, 0.7, 0.7),
			Vector3.new(x, Y2 + 1.6, BZ1 - 11), C.DARK, M.Metal, 40, "Terrace", 2)
	end
	return made
end

local function buildRoof(f: Instance): number
	local made = 0
	local grp = "SeoulRoof"
	K.box(f, "RoofSlab", Vector3.new(BX1 - BX0 + 2.4, SLAB, BZ1 - BZ0 + 2.4),
		Vector3.new(CX, Y_ROOF - SLAB * 0.5, CZ), C.ROOF, M.Concrete, 340, grp, 6, { canCollide = true })
	made += 1
	made += K.tileField(f, "RoofDeck", BX0, BX1, BZ0, BZ1 - 20, Y_ROOF + 0.05, 6.0, 80,
		Color3.fromRGB(96, 100, 108), Color3.fromRGB(84, 88, 96), grp, 0.16)

	-- diềm mái ngói cong kiểu hanok (2 lớp so le)
	local eaveZ = BZ1 - 20
	for i = 0, 22 do
		local x = BX0 + i * ((BX1 - BX0) / 22)
		K.rbox(f, string.format("EaveTile_%d", i), Vector3.new(6.2, 0.7, 5.2),
			CFrame.new(x, Y_ROOF + 0.7, eaveZ + 1.6) * CFrame.Angles(math.rad(-13), 0, 0),
			C.TILE, M.Slate, 60, grp, 6, { canCollide = false })
		K.rbox(f, string.format("EaveTileTop_%d", i), Vector3.new(6.0, 0.45, 4.4),
			CFrame.new(x, Y_ROOF + 1.5, eaveZ + 0.5) * CFrame.Angles(math.rad(-24), 0, 0),
			Color3.fromRGB(66, 48, 42), M.Slate, 50, grp, 7, { canCollide = false })
		made += 2
	end
	K.box(f, "EaveGutter", Vector3.new(BX1 - BX0 + 6, 0.5, 0.9),
		Vector3.new(CX, Y_ROOF + 0.15, eaveZ + 4.2), C.DARK, M.Metal, 40, grp, 6, { canCollide = false })
	made += 1

	-- 4 ống khói hút mùi + 3 HVAC + bồn nước + pin mặt trời
	for i = 1, 4 do
		local x = BX0 + 22 + (i - 1) * 28
		K.cyl(f, string.format("Chimney_%d", i), Vector3.new(9, 2.4, 2.4),
			Vector3.new(x, Y_ROOF + 4.5, CZ + 8), C.STEEL, M.Metal, 120, grp, 7)
		K.cyl(f, string.format("ChimneyCap_%d", i), Vector3.new(1.0, 3.5, 3.5),
			Vector3.new(x, Y_ROOF + 9.2, CZ + 8), C.DARK, M.Metal, 60, grp, 8)
		made += 2
	end
	for i = 1, 3 do
		local x = BX0 + 30 + (i - 1) * 30
		K.box(f, string.format("HVAC_%d", i), Vector3.new(8, 4.4, 6), Vector3.new(x, Y_ROOF + 2.2, BZ0 + 18),
			C.STEEL, M.Metal, 120, grp, 6)
		K.cyl(f, string.format("HVACFan_%d", i), Vector3.new(0.6, 4.4, 4.4), Vector3.new(x, Y_ROOF + 4.5, BZ0 + 18),
			C.DARK, M.Metal, 40, grp, 7)
		made += 2
	end
	K.cyl(f, "WaterTank", Vector3.new(7, 8, 8), Vector3.new(BX1 - 16, Y_ROOF + 4.5, BZ0 + 14),
		C.STEEL, M.Metal, 140, grp, 6)
	for i = 1, 3 do
		K.rbox(f, string.format("SolarPanel_%d", i), Vector3.new(12, 0.3, 7),
			CFrame.new(BX0 + 26 + (i - 1) * 15, Y_ROOF + 2.4, BZ0 + 46) * CFrame.Angles(math.rad(-22), 0, 0),
			Color3.fromRGB(28, 44, 78), M.Glass, 40, grp, 7, { canCollide = false, castShadow = false })
	end
	return made
end

local function buildFacade(f: Instance): number
	local made = 0
	local grp = "SeoulSign"

	-- ban công/ô văng che cửa chính
	K.box(f, "EntryCanopy", Vector3.new(26, 0.9, 9), Vector3.new(CX, FLOOR + 11.4, BZ1 + 3.5),
		C.WOOD_D, M.Wood, 160, grp, 5)
	for i = 1, 2 do
		K.cyl(f, string.format("CanopyPost_%d", i), Vector3.new(11.4, 0.8, 0.8),
			Vector3.new(CX + (i == 1 and -11 or 11), FLOOR + 5.7, BZ1 + 7), C.WOOD_D, M.Wood, 90, grp, 1)
		made += 1
	end

	-- biển chính
	K.sign(f, "MainSign", Vector3.new(CX, FLOOR + 13.6, BZ1 + 0.5), Vector3.new(54, 6.4, 0.9),
		Enum.NormalId.Back, "SEOUL GARDEN  ·  한식 바베큐", C.DARK, C.NEON, 120, 16)
	made += 1
	K.box(f, "SignGlowStrip", Vector3.new(54, 0.5, 0.25), Vector3.new(CX, FLOOR + 10.2, BZ1 + 1.0),
		C.NEON, M.Neon, 30, grp, 6, { canCollide = false, castShadow = false })
	made += 1

	-- biển dọc chữ Hàn ở góc Đông
	K.box(f, "BladeSign", Vector3.new(1.0, 20, 4.6), Vector3.new(BX1 - 2.0, FLOOR + 10, BZ1 + 3.0),
		C.RED, M.SmoothPlastic, 110, grp, 5)
	for i = 1, 4 do
		local ch = ({"서", "울", "가", "든"})[i]
		K.sign(f, "BladeChar_" .. i, Vector3.new(BX1 - 2.7, FLOOR + 17.5 - (i - 1) * 4.4, BZ1 + 3.0),
			Vector3.new(0.4, 3.6, 3.6), Enum.NormalId.Left, ch, C.RED, Color3.fromRGB(255, 240, 210), 40, 24)
		made += 1
	end

	-- bảng menu đèn + lối vào
	K.sign(f, "MenuBoard", Vector3.new(BX0 + 16, FLOOR + 6.6, BZ1 + 2.6), Vector3.new(14, 9, 0.5),
		Enum.NormalId.Back, "MENU", C.DARK, C.NEON2, 60, 18)
	made += 1
	K.box(f, "MenuBoardFrame", Vector3.new(14.8, 9.8, 0.3), Vector3.new(BX0 + 16, FLOOR + 6.6, BZ1 + 2.3),
		C.WOOD_D, M.Wood, 80, grp, 1, { canCollide = false })
	K.box(f, "WheelChairRamp", Vector3.new(18, 0.7, 8), Vector3.new(CX, G + 0.35, BZ1 + 5),
		C.STONE, M.Concrete, 90, grp, 1, { canCollide = true })
	made += 2

	-- 8 đèn lồng giấy dọc hiên
	for i = 1, 8 do
		local x = BX0 + 12 + (i - 1) * 17
		K.cyl(f, string.format("LanternCord_%d", i), Vector3.new(2.0, 0.12, 0.12),
			Vector3.new(x, FLOOR + 11.0, BZ1 + 3.0), C.DARK, M.Metal, 20, grp, 6, { canCollide = false })
		K.cyl(f, string.format("Lantern_%d", i), Vector3.new(3.4, 2.6, 2.6),
			Vector3.new(x, FLOOR + 9.2, BZ1 + 3.0), C.PAPER, M.Neon, 25, grp, 7,
			{ canCollide = false, castShadow = false })
		made += 2
	end
	return made
end

local function buildForecourt(f: Instance): number
	local made = 0
	local grp = "Forecourt"
	-- sàn gỗ hiên + sàn đá ra vỉa hè
	made += K.tileField(f, "PorchDeck", BX0, BX1, BZ1, BZ1 + 16, FLOOR - 0.02, 3.4, 90, C.WOOD_L, C.WOOD, grp, 0.26)
	made += K.tileField(f, "Apron", BX0 - 6, BX1 + 6, BZ1 + 16, BZ1 + 22, G + 0.09, 5.0, 70,
		C.STONE, C.STONE_D, grp, 0.16)

	-- vách tre hai bên hiên
	for side, x in ipairs({ BX0 + 2, BX1 - 2 }) do
		for i = 1, 10 do
			K.cyl(f, string.format("Bamboo_%d_%d", side, i), Vector3.new(9.5, 0.42, 0.42),
				Vector3.new(x, FLOOR + 4.75, BZ1 + 2 + i * 1.3), C.BAMBOO, M.Wood, 40, grp, 2,
				{ canCollide = false, castShadow = false })
			made += 1
		end
	end

	-- bồn cây + cọ cảnh
	made += K.planter(f, "PlanterL", Vector3.new(BX0 + 12, G + 0.06, BZ1 + 12), 12, 5, 1.6, C.STONE_D, C.LEAF, 100)
	made += K.planter(f, "PlanterR", Vector3.new(BX1 - 12, G + 0.06, BZ1 + 12), 12, 5, 1.6, C.STONE_D, C.LEAF2, 100)
	made += K.palm(f, "PalmL", Vector3.new(BX0 - 24, G, BZ1 + 8), 16, C.WOOD, C.LEAF, 90)
	made += K.palm(f, "PalmR", Vector3.new(BX1 + 2, G, BZ1 + 8), 16, C.WOOD, C.LEAF2, 90)

	-- đèn sân
	made += K.lampPost(f, "LampL", Vector3.new(BX0 - 4, G, BZ1 + 8), 10, C.DARK, C.NEON2, 120)
	made += K.lampPost(f, "LampR", Vector3.new(BX1 + 4, G, BZ1 + 8), 10, C.DARK, C.NEON2, 120)

	-- bãi đỗ 4 xe: dải đất phía Tây thân nhà (X −536…−500, Z 32…92), xe quay đầu +X
	local stallX = BX0 - 10
	for i = 0, 4 do
		K.box(f, string.format("StallLine_%d", i), Vector3.new(16, 0.06, 0.34),
			Vector3.new(stallX, G + 0.1, 32 + i * 12), Color3.fromRGB(230, 214, 120), M.SmoothPlastic, 30, grp, 1,
			{ canCollide = false, castShadow = false })
		made += 1
	end
	made += K.car(f, "CarA", Vector3.new(stallX, G, 44), math.rad(90), Color3.fromRGB(168, 52, 52), 200, "ParkedCar")
	made += K.car(f, "CarB", Vector3.new(stallX, G, 68), math.rad(90), Color3.fromRGB(56, 62, 80), 200, "ParkedCar")
	made += K.car(f, "CarC", Vector3.new(stallX, G, 80), math.rad(90), Color3.fromRGB(210, 198, 176), 200, "ParkedCar")

	-- thùng rác + bảng hiệu nhỏ
	K.cyl(f, "TrashBin", Vector3.new(3.4, 2.2, 2.2), Vector3.new(BX1 + 5, G + 1.7, BZ1 + 2), C.DARK, M.Metal, 60, grp, 1)
	K.sign(f, "NoticeBoard", Vector3.new(BX0 - 18, G + 6, BZ1 + 21), Vector3.new(10, 5, 0.4),
		Enum.NormalId.Back, "SEOUL GARDEN · OPEN 11:00 – 23:00", C.DARK, C.NEON2, 40, 18)
	made += 3
	return made
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BUILD
-- ══════════════════════════════════════════════════════════════════════════════
function Module.build(modulesContainer: Instance): Instance
	local root = K.folder("Plot_E3_LittleSeoulDiner", modulesContainer)
	root:SetAttribute("PlotId", "Plot_E3")
	root:SetAttribute("ModuleId", Module.Id)
	root:SetAttribute("MainEntrance", "X=-447, Z=106 (cửa đôi gỗ-kính 14 × 9 stud, mặt Nam ra Vespucci Blvd)")
	root:SetAttribute("Parking", "X -552…-516, Z 104…124 (4 ô)")
	root:SetAttribute("ServiceCounter", "quầy E3_FOOD do ServiceManager tự dựng trước hiên")
	root:SetAttribute("GroundFloorClear_Studs", H1)
	root:SetAttribute("StudsPerMeter", SPM)

	local f = K.folder("01_GroundFloor", root)
	buildGround(f)
	buildDining(f)
	local u = K.folder("02_UpperFloor", root)
	buildUpper(u)
	local r = K.folder("03_Roof", root)
	buildRoof(r)
	local fa = K.folder("04_Facade", root)
	buildFacade(fa)
	local fc = K.folder("05_Forecourt", root)
	buildForecourt(fc)

	local stat = K.perf(root)
	root:SetAttribute("PartCount", stat.parts)
	return root
end

return Module
