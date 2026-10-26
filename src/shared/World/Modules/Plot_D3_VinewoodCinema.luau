--!strict
--[[
	Plot_D3_VinewoodCinema.luau  (Sync v27 — vòng quét V6, Agent A)
	================================================================================
	VINEWOOD CINEMA — rạp chiếu phim Art Deco 2 tầng, 2 phòng chiếu
	Ô đất   : Plot_D3 (Downtown Vinewood)  X 134…318 · Z −204…−60 · nền Y = 1,15
	Mặt tiền: Nam (+Z, Z = −70) nhìn ra Olympic Fwy (Z = −36)

	Chức năng: quầy `D3_CINEMA` (CINEMA $50, +$150 vé VIP) của BuildingServices
	tự dựng trước sảnh vé khi module này được nạp.

	KIẾN TRÚC
	  • Mặt tiền Art Deco: 6 trụ dọc ốp đá trắng, 3 tầng ô cửa sổ hẹp, diềm ziggurat,
	    mái đua (marquee) 12 stud có 26 bóng đèn tròn + chữ neon "VINEWOOD".
	  • Sảnh vé thông tầng 16 stud: quầy vé gỗ, đèn chùm pha lê, sàn đá caro,
	    bảng lịch chiếu, 8 poster phim 2 bên.
	  • 2 phòng chiếu (mỗi phòng 50 × 66 stud): màn hình 40 × 18, 9 hàng ghế ×
	    12 ghế, dốc dần về phía màn hình, lối đi giữa có đèn sàn.
	  • Tầng 2: ban công phòng chiếu 1, phòng chiếu phim (projector) 2 cửa sổ, kho.
	  • Sân trước: thảm đỏ, 12 ngôi sao Walk of Fame, 2 dàn đèn rọi, quầy bắp nước,
	    bảng suất chiếu. Bãi đỗ 6 xe phía Đông.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local K = require(Shared:WaitForChild("World"):WaitForChild("BuildKit"))

local Module = {
	Id = "Plot_D3_VinewoodCinema",
	PlotId = "Plot_D3",
	Order = 62,
	Enabled = true,
}

local M = Enum.Material
local G = K.GROUND
local SPM = K.STUDS_PER_METER

local C = {
	CREAM = Color3.fromRGB(238, 230, 212),
	CREAM_D = Color3.fromRGB(206, 196, 176),
	GOLD = Color3.fromRGB(212, 172, 84),
	GOLD_D = Color3.fromRGB(158, 122, 52),
	MAROON = Color3.fromRGB(112, 30, 42),
	MAROON_D = Color3.fromRGB(78, 20, 30),
	CARPET = Color3.fromRGB(148, 28, 40),
	DARK = Color3.fromRGB(26, 26, 30),
	STEEL = Color3.fromRGB(168, 172, 178),
	GLASS = Color3.fromRGB(140, 190, 205),
	GLASS_D = Color3.fromRGB(90, 130, 145),
	NEON = Color3.fromRGB(255, 92, 126),
	BULB = Color3.fromRGB(255, 236, 176),
	SEAT = Color3.fromRGB(126, 32, 46),
	SCREEN = Color3.fromRGB(226, 230, 236),
	STONE = Color3.fromRGB(186, 180, 168),
	STONE_D = Color3.fromRGB(146, 140, 130),
	LEAF = Color3.fromRGB(70, 122, 74),
}

local BX0, BX1 = 150, 272
local BZ0, BZ1 = -196, -96
local CX, CZ = (BX0 + BX1) * 0.5, (BZ0 + BZ1) * 0.5
local FLOOR = G + 0.15
local H1 = 16.0
local SLAB = 1.2
local Y2 = FLOOR + H1 + SLAB
local H2 = 11.5
local Y_ROOF = Y2 + H2 + SLAB
local WT = 1.6

-- 2 phòng chiếu: [X0, X1]
local HALL_A = { 158, 208 }
local HALL_B = { 214, 264 }
local HALL_Z0, HALL_Z1 = BZ0 + 6, BZ0 + 72 -- −190 … −124

-- ── mặt tiền: 3 cửa chính giữa + 2 vịnh kính 2 bên ──────────────────────────
local DOOR_W = 16
local DOORS = { { CX - DOOR_W * 0.5, CX + DOOR_W * 0.5 } }
local FRONT_OPEN = {
	{ a = DOORS[1][1], b = DOORS[1][2], y0 = FLOOR, y1 = FLOOR + 9.6 },
	{ a = BX0 + 10, b = BX0 + 36, y0 = FLOOR + 2.2, y1 = FLOOR + 11.4 },
	{ a = BX1 - 36, b = BX1 - 10, y0 = FLOOR + 2.2, y1 = FLOOR + 11.4 },
}

local function buildShell(f: Instance): number
	local grp = "CinemaShell"
	local made = 0
	K.box(f, "BaseSlab", Vector3.new(BX1 - BX0 + 0.4, FLOOR - G, BZ1 - BZ0 + 0.4),
		Vector3.new(CX, (G + FLOOR) * 0.5, CZ), C.STONE_D, M.Concrete, nil, grp, 1, { canCollide = true })
	made += 1
	made += K.tileField(f, "LobbyTile", BX0 + 2, BX1 - 2, HALL_Z1, BZ1 - 2, FLOOR, 4.4, 120,
		C.CREAM, C.STONE, grp, 0.14)

	made += K.wall(f, "SouthWall", "X", BZ1 - WT * 0.5, BX0, BX1, FLOOR, FLOOR + H1 + H2 + SLAB, WT,
		C.CREAM, M.Concrete, 280, grp, (function()
			local out = {}
			for _, o in ipairs(FRONT_OPEN) do
				table.insert(out, o)
			end
			for i = 1, 6 do
				local a = BX0 + 8 + (i - 1) * 24
				table.insert(out, { a = a, b = a + 8, y0 = FLOOR + 13.2, y1 = FLOOR + 17.6 })
			end
			return out
		end)())
	made += K.wall(f, "NorthWall", "X", BZ0 + WT * 0.5, BX0, BX1, FLOOR, FLOOR + H1 + H2 + SLAB, WT,
		C.CREAM_D, M.Concrete, 300, grp, nil)
	made += K.wall(f, "WestWall", "Z", BX0 + WT * 0.5, BZ0, BZ1, FLOOR, FLOOR + H1 + H2 + SLAB, WT,
		C.CREAM_D, M.Concrete, 280, grp, { { a = -150, b = -134, y0 = FLOOR + 4, y1 = FLOOR + 10 } })
	made += K.wall(f, "EastWall", "Z", BX1 - WT * 0.5, BZ0, BZ1, FLOOR, FLOOR + H1 + H2 + SLAB, WT,
		C.CREAM_D, M.Concrete, 280, grp, { { a = -150, b = -134, y0 = FLOOR + 4, y1 = FLOOR + 10 } })

	-- vách kính 2 bên cửa chính + cửa đôi gỗ
	made += K.curtain(f, "FrontGlassW", "X", BZ1 - 0.45, BX0 + 10, BX0 + 36, FLOOR + 2.2, FLOOR + 11.4,
		4, 3, C.GLASS, C.GOLD_D, 40, "FrontGlass")
	made += K.curtain(f, "FrontGlassE", "X", BZ1 - 0.45, BX1 - 36, BX1 - 10, FLOOR + 2.2, FLOOR + 11.4,
		4, 3, C.GLASS, C.GOLD_D, 40, "FrontGlass")
	for i, sgn in ipairs({ -1, 1 }) do
		K.box(f, string.format("DoorLeaf_%d", i), Vector3.new(DOOR_W * 0.5 - 0.5, 9.4, 0.3),
			Vector3.new(CX + sgn * DOOR_W * 0.25, FLOOR + 4.7, BZ1 - 0.5), C.GLASS, M.Glass, 40, "MainDoor", 1,
			{ canCollide = false, castShadow = false, transparency = 0.2 })
		K.cyl(f, string.format("DoorHandle_%d", i), Vector3.new(1.0, 0.24, 0.24),
			Vector3.new(CX + sgn * 1.6, FLOOR + 4.4, BZ1 - 0.25), C.GOLD, M.Metal, 40, "MainDoor", 2)
		made += 2
	end
	K.box(f, "DoorHeader", Vector3.new(DOOR_W + 4, 1.6, 1.0), Vector3.new(CX, FLOOR + 10.4, BZ1 - 0.6),
		C.GOLD, M.Metal, 140, "MainDoor", 3)
	made += 1
	return made
end

local function buildLobby(f: Instance): number
	local made = 0
	local grp = "Lobby"
	-- trần thông tầng: dầm + đèn chùm
	K.box(f, "LobbyCeiling", Vector3.new(BX1 - BX0 - 6, 0.6, BZ1 - HALL_Z1 - 4),
		Vector3.new(CX, FLOOR + H1 + 6, (BZ1 + HALL_Z1) * 0.5), C.CREAM_D, M.Concrete, 200, grp, 5, { canCollide = false })
	K.cyl(f, "ChandelierStem", Vector3.new(4.0, 0.3, 0.3), Vector3.new(CX, FLOOR + H1 + 4, CZ + 18),
		C.GOLD_D, M.Metal, 40, grp, 5, { canCollide = false })
	for ring = 1, 3 do
		local rad = 3 + ring * 3.2
		for i = 1, 6 + ring * 2 do
			local ang = (i / (6 + ring * 2)) * math.pi * 2
			K.box(f, string.format("Crystal_%d_%d", ring, i), Vector3.new(0.7, 1.6, 0.7),
				Vector3.new(CX + math.cos(ang) * rad, FLOOR + H1 + 1.4 - ring * 1.1, CZ + 18 + math.sin(ang) * rad),
				C.BULB, M.Neon, 20, grp, 5, { canCollide = false, castShadow = false })
			made += 1
		end
	end

	-- quầy vé gỗ + rào xếp hàng
	K.box(f, "TicketCounter", Vector3.new(30, 5.2, 5), Vector3.new(BX0 + 26, FLOOR + 2.6, BZ1 - 16),
		C.MAROON, M.Wood, 200, grp, 2)
	K.box(f, "TicketTop", Vector3.new(31.5, 0.5, 6), Vector3.new(BX0 + 26, FLOOR + 5.4, BZ1 - 16),
		C.GOLD, M.Metal, 120, grp, 3)
	for i = 1, 3 do
		K.box(f, string.format("TicketGlass_%d", i), Vector3.new(8, 5.0, 0.25),
			Vector3.new(BX0 + 16 + (i - 1) * 9, FLOOR + 7.8, BZ1 - 18), C.GLASS, M.Glass, 40, "TicketGlass", 2,
			{ canCollide = false, castShadow = false, transparency = 0.35 })
		made += 1
	end
	K.sign(f, "TicketSign", Vector3.new(BX0 + 26, FLOOR + 10.6, BZ1 - 18), Vector3.new(26, 3.4, 0.4),
		Enum.NormalId.Back, "VÉ  ·  TICKETS", C.MAROON_D, C.GOLD, 40, 20)
	made += 1

	-- quầy bắp nước
	K.box(f, "Concession", Vector3.new(26, 5.6, 6), Vector3.new(BX1 - 26, FLOOR + 2.8, BZ1 - 16),
		C.CREAM, M.SmoothPlastic, 190, grp, 2)
	K.box(f, "ConcessionTop", Vector3.new(27, 0.45, 7), Vector3.new(BX1 - 26, FLOOR + 5.85, BZ1 - 16),
		C.GOLD, M.Metal, 110, grp, 3)
	for i = 1, 4 do
		K.cyl(f, "PopcornMachine" .. i, Vector3.new(3.4, 3.0, 3.0),
			Vector3.new(BX1 - 36 + (i - 1) * 6.5, FLOOR + 7.6, BZ1 - 16), C.MAROON, M.Metal, 60, grp, 3)
		K.box(f, "PopcornGlow" .. i, Vector3.new(2.2, 1.2, 2.2),
			Vector3.new(BX1 - 36 + (i - 1) * 6.5, FLOOR + 9.4, BZ1 - 16), C.BULB, M.Neon, 20, grp, 4,
			{ canCollide = false, castShadow = false })
		made += 2
	end

	-- 8 poster phim 2 bên tường
	for i = 1, 8 do
		local east = i > 4
		local x = if east then BX1 - WT - 0.6 else BX0 + WT + 0.6
		local z = BZ1 - 6 - ((i - 1) % 4) * 6
		local face = if east then Enum.NormalId.Left else Enum.NormalId.Right
		K.sign(f, "Poster_" .. i, Vector3.new(x, FLOOR + 8, z), Vector3.new(0.3, 8.4, 6.2), face,
			({ "NOW SHOWING", "COMING SOON", "I", "II", "III", "IV", "V", "VI" })[i], C.DARK, C.NEON, 40, 18)
		K.box(f, "PosterFrame_" .. i, Vector3.new(0.2, 9.2, 7.0), Vector3.new(x + (if east then 0.15 else -0.15), FLOOR + 8, z),
			C.GOLD, M.Metal, 40, "Poster", 2, { canCollide = false })
		made += 2
	end

	-- lối vào 2 phòng chiếu
	for i, hall in ipairs({ HALL_A, HALL_B }) do
		local hx = (hall[1] + hall[2]) * 0.5
		K.box(f, "HallDoor_" .. i, Vector3.new(18, 10, 1.0), Vector3.new(hx, FLOOR + 5, HALL_Z1),
			C.MAROON_D, M.Wood, 160, "HallDoor", 1)
		K.sign(f, "HallSign_" .. i, Vector3.new(hx, FLOOR + 11.6, HALL_Z1 - 0.8), Vector3.new(14, 3, 0.4),
			Enum.NormalId.Back, (i == 1 and "PHÒNG 1" or "PHÒNG 2"), C.MAROON_D, C.GOLD, 40, 20)
		made += 2
	end
	return made
end

local function buildHall(f: Instance, hall: { number }, idx: number): number
	local made = 0
	local grp = "Hall" .. idx
	local hx0, hx1 = hall[1], hall[2]
	local hcx = (hx0 + hx1) * 0.5
	local width = hx1 - hx0

	-- tường bao phòng chiếu
	made += K.wall(f, "HallWallW" .. idx, "Z", hx0, HALL_Z0, HALL_Z1, FLOOR, FLOOR + 15, 1.0,
		C.MAROON_D, M.Fabric, 220, grp, nil)
	made += K.wall(f, "HallWallE" .. idx, "Z", hx1, HALL_Z0, HALL_Z1, FLOOR, FLOOR + 15, 1.0,
		C.MAROON_D, M.Fabric, 220, grp, nil)

	-- sàn dốc: 10 hàng, mỗi hàng cao thêm 0.75 stud
	for row = 1, 9 do
		local z = HALL_Z1 - 6 - (row - 1) * 6.5
		local y = FLOOR + (row - 1) * 0.7
		K.box(f, string.format("RowStep_%d_%d", idx, row), Vector3.new(width - 2, 0.7, 6.5),
			Vector3.new(hcx, y + 0.35, z), C.MAROON, M.Fabric, 90, grp, row, { canCollide = true })
		made += 1
	end
	-- 12 ghế mỗi hàng (bỏ 2 ghế giữa làm lối đi)
	for row = 1, 9 do
		local z = HALL_Z1 - 6 - (row - 1) * 6.5
		local y = FLOOR + (row - 1) * 0.7
		for seat = 1, 12 do
			local x = hx0 + 6 + (seat - 1) * ((width - 12) / 11)
			if seat ~= 6 and seat ~= 7 then -- lối đi giữa
				K.box(f, string.format("Seat_%d_%d_%d", idx, row, seat), Vector3.new(2.9, 1.1, 3.2),
					Vector3.new(x, y + 1.35, z), C.SEAT, M.Fabric, 45, grp, row, { canCollide = false })
				K.box(f, string.format("SeatBack_%d_%d_%d", idx, row, seat), Vector3.new(2.9, 2.6, 0.5),
					Vector3.new(x, y + 2.5, z - 1.5), C.SEAT, M.Fabric, 40, grp, row, { canCollide = false })
				made += 2
			end
		end
	end

	-- màn hình + loa + bục
	K.box(f, "Screen_" .. idx, Vector3.new(40, 18, 0.8), Vector3.new(hcx, FLOOR + 11, HALL_Z0 + 2),
		C.SCREEN, M.SmoothPlastic, 120, "Screen", 1, { canCollide = false })
	K.box(f, "ScreenFrame_" .. idx, Vector3.new(43, 21, 0.5), Vector3.new(hcx, FLOOR + 11, HALL_Z0 + 1.4),
		C.DARK, M.Metal, 90, "Screen", 1, { canCollide = false })
	for i, sgn in ipairs({ -1, 1 }) do
		K.box(f, string.format("Speaker_%d_%d", idx, i), Vector3.new(4, 14, 4),
			Vector3.new(hcx + sgn * 22, FLOOR + 8, HALL_Z0 + 5), C.DARK, M.Fabric, 100, "Speaker", 1)
		made += 1
	end
	-- đèn sàn lối đi
	for i = 1, 9 do
		K.box(f, string.format("AisleLight_%d_%d", idx, i), Vector3.new(0.5, 0.4, 1.6),
			Vector3.new(hcx, FLOOR + (i - 1) * 0.7 + 0.9, HALL_Z1 - 6 - (i - 1) * 6.5), C.BULB, M.Neon, 15,
			"Screen", 2, { canCollide = false, castShadow = false })
		made += 1
	end
	return made
end

local function buildUpperFloor(f: Instance): number
	local made = 0
	local grp = "CinemaUpper"
	K.box(f, "L2Slab", Vector3.new(BX1 - BX0 + 0.6, SLAB, BZ1 - BZ0 + 0.6),
		Vector3.new(CX, Y2 - SLAB * 0.5, CZ), C.CREAM_D, M.Concrete, 320, grp, 5, { canCollide = true })
	made += 1
	-- ban công sảnh (hở giữa nhìn xuống)
	made += K.tileField(f, "L2Floor", BX0 + 2, BX0 + 40, HALL_Z1, BZ1 - 2, Y2 + 0.08, 4.0, 90,
		C.CREAM, C.STONE, grp, 0.14)
	made += K.tileField(f, "L2FloorE", BX1 - 40, BX1 - 2, HALL_Z1, BZ1 - 2, Y2 + 0.08, 4.0, 90,
		C.CREAM, C.STONE, grp, 0.14)
	made += K.railing(f, "BalconyRailW", "Z", BX0 + 40, HALL_Z1, BZ1 - 3, Y2, 4.4, C.GOLD_D, C.GLASS, 50)
	made += K.railing(f, "BalconyRailE", "Z", BX1 - 40, HALL_Z1, BZ1 - 3, Y2, 4.4, C.GOLD_D, C.GLASS, 50)
	made += K.railing(f, "BalconyRail", "X", HALL_Z1, BX0 + 40, BX1 - 40, Y2, 4.4, C.GOLD_D, C.GLASS, 50)

	-- phòng chiếu phim (projector) trên đầu mỗi phòng
	for i, hall in ipairs({ HALL_A, HALL_B }) do
		local hx = (hall[1] + hall[2]) * 0.5
		K.box(f, "ProjectorRoom" .. i, Vector3.new(18, 8, 12), Vector3.new(hx, Y2 + 4, HALL_Z1 - 10),
			C.CREAM, M.Concrete, 200, "Projector", 3)
		K.box(f, "ProjectorWindow" .. i, Vector3.new(10, 3.4, 0.3), Vector3.new(hx, Y2 + 6, HALL_Z1 - 16),
			C.GLASS_D, M.Glass, 40, "Projector", 4, { canCollide = false, castShadow = false, transparency = 0.3 })
		K.box(f, "ProjectorUnit" .. i, Vector3.new(4, 2.6, 5), Vector3.new(hx, Y2 + 9.3, HALL_Z1 - 10),
			C.DARK, M.Metal, 60, "Projector", 4)
		K.cyl(f, "ProjectorLens" .. i, Vector3.new(1.6, 1.4, 1.4), Vector3.new(hx, Y2 + 9.3, HALL_Z1 - 12.8),
			C.BULB, M.Neon, 20, "Projector", 5, { canCollide = false, castShadow = false })
		made += 4
	end

	-- hành lang kính tầng 2 phía sau
	made += K.curtain(f, "L2RearGlass", "X", BZ0 + 24, BX0 + 20, BX1 - 20, Y2 + 2.4, Y2 + 8.4,
		14, 2, C.GLASS, C.GOLD_D, 38, "L2Glass")
	return made
end

local function buildRoof(f: Instance): number
	local made = 0
	local grp = "CinemaRoof"
	K.box(f, "RoofSlab", Vector3.new(BX1 - BX0 + 2, SLAB, BZ1 - BZ0 + 2),
		Vector3.new(CX, Y_ROOF - SLAB * 0.5, CZ), C.STONE_D, M.Concrete, 340, grp, 6, { canCollide = true })
	made += 1
	-- diềm ziggurat Art Deco ở mặt tiền (3 bậc lùi dần)
	for step = 1, 3 do
		K.box(f, "Ziggurat" .. step, Vector3.new((BX1 - BX0) - step * 14, 1.4, 6 - step * 1.4),
			Vector3.new(CX, Y_ROOF + step * 1.4, BZ1 - 3 - step * 1.2), C.CREAM, M.Concrete, 140, grp, 6 + step)
		made += 1
	end
	-- 6 trụ dọc mặt tiền vượt mái
	for i = 0, 5 do
		local x = BX0 + 10 + i * ((BX1 - BX0 - 20) / 5)
		K.box(f, "Fin" .. i, Vector3.new(3.4, 3.0, 5.0), Vector3.new(x, Y_ROOF + 1.5, BZ1 - 4),
			C.CREAM, M.Concrete, 120, grp, 8)
		made += 1
	end
	-- HVAC + tháp nước + ăng ten
	for i = 1, 4 do
		K.box(f, "HVAC" .. i, Vector3.new(9, 4.6, 7), Vector3.new(BX0 + 26 + (i - 1) * 30, Y_ROOF + 2.3, CZ),
			C.STEEL, M.Metal, 120, grp, 6)
		K.cyl(f, "HVACFan" .. i, Vector3.new(0.6, 4.4, 4.4), Vector3.new(BX0 + 26 + (i - 1) * 30, Y_ROOF + 4.8, CZ),
			C.DARK, M.Metal, 40, grp, 7)
		made += 2
	end
	K.cyl(f, "WaterTower", Vector3.new(8, 9, 9), Vector3.new(BX1 - 24, Y_ROOF + 5, BZ0 + 22),
		C.WOOD_D, M.Wood, 160, grp, 6)
	K.box(f, "Antenna", Vector3.new(0.5, 14, 0.5), Vector3.new(CX, Y_ROOF + 8, BZ0 + 12), C.STEEL, M.Metal, 30, grp, 7)
	made += 2
	return made
end

local function buildFacade(f: Instance): number
	local made = 0
	local grp = "CinemaSign"
	-- 6 trụ dọc mặt tiền
	for i = 0, 5 do
		local x = BX0 + 10 + i * ((BX1 - BX0 - 20) / 5)
		K.box(f, "Pier" .. i, Vector3.new(4.2, H1 + H2 + SLAB, 2.2), Vector3.new(x, FLOOR + (H1 + H2 + SLAB) * 0.5, BZ1 + 0.2),
			C.CREAM, M.Concrete, 220, grp, 3)
		K.box(f, "PierCap" .. i, Vector3.new(5.2, 1.2, 3.0), Vector3.new(x, FLOOR + H1 + H2 + SLAB, BZ1 + 0.2),
			C.GOLD, M.Metal, 80, grp, 4, { canCollide = false })
		made += 2
	end

	-- mái đua (marquee) + 26 bóng đèn
	K.box(f, "MarqueeDeck", Vector3.new(64, 1.6, 12), Vector3.new(CX, FLOOR + 12.4, BZ1 + 6),
		C.MAROON_D, M.Metal, 220, grp, 5)
	K.box(f, "MarqueeUnder", Vector3.new(62, 0.4, 11), Vector3.new(CX, FLOOR + 11.5, BZ1 + 6),
		C.CREAM, M.SmoothPlastic, 60, grp, 5, { canCollide = false, castShadow = false })
	for i = 0, 12 do
		local x = CX - 30 + i * 5
		for _, dz in ipairs({ 1.5, 10.5 }) do
			K.cyl(f, string.format("Bulb_%d_%d", i, dz), Vector3.new(1.0, 1.1, 1.1),
				Vector3.new(x, FLOOR + 11.2, BZ1 + dz), C.BULB, M.Neon, 15, grp, 5,
				{ canCollide = false, castShadow = false })
			made += 1
		end
	end
	K.sign(f, "MarqueeSign", Vector3.new(CX, FLOOR + 14.2, BZ1 + 12.2), Vector3.new(60, 3.4, 0.5),
		Enum.NormalId.Back, "VINEWOOD CINEMA  ·  NOW SHOWING", C.MAROON_D, C.NEON, 60, 16)
	made += 1

	-- biển dọc chữ chạy dọc góc Đông
	K.box(f, "BladeSign", Vector3.new(4.0, 30, 1.0), Vector3.new(BX1 - 6, FLOOR + 18, BZ1 + 3.2),
		C.MAROON_D, M.SmoothPlastic, 160, grp, 6)
	local letters = { "V", "I", "N", "E", "W", "O", "O", "D" }
	for i, ch in ipairs(letters) do
		K.sign(f, "BladeChar" .. i, Vector3.new(BX1 - 6, FLOOR + 30 - (i - 1) * 3.4, BZ1 + 3.8),
			Vector3.new(3.6, 3.0, 0.4), Enum.NormalId.Back, ch, C.MAROON_D, C.BULB, 30, 26)
		made += 1
	end
	return made
end

local function buildForecourt(f: Instance): number
	local made = 0
	local grp = "Forecourt"
	made += K.tileField(f, "ForecourtTile", BX0 - 4, 272, BZ1, -64, G + 0.07, 4.2, 90,
		C.STONE, C.STONE_D, grp, 0.14)
	-- thảm đỏ dẫn vào cửa
	K.box(f, "RedCarpet", Vector3.new(16, 0.12, 26), Vector3.new(CX, G + 0.16, BZ1 + 13),
		C.CARPET, M.Fabric, 40, grp, 1, { canCollide = false, castShadow = false })
	made += 1
	-- 12 ngôi sao Walk of Fame (mỗi sao = đế + 6 cánh)
	for i = 1, 12 do
		local row = if i <= 6 then 1 else 2
		local k2 = ((i - 1) % 6)
		local x = CX - 52 + k2 * 18
		local z = BZ1 + 6 + row * 6
		K.cyl(f, "StarBase_" .. i, Vector3.new(0.16, 7.2, 7.2), Vector3.new(x, G + 0.1, z),
			Color3.fromRGB(196, 120, 140), M.SmoothPlastic, 30, grp, 1, { canCollide = false, castShadow = false })
		for arm = 0, 5 do
			local ang = (arm / 6) * math.pi * 2
			K.rbox(f, string.format("StarArm_%d_%d", i, arm), Vector3.new(2.8, 0.12, 0.9),
				CFrame.new(x + math.cos(ang) * 1.5, G + 0.2, z + math.sin(ang) * 1.5) * CFrame.Angles(0, -ang, 0),
				C.GOLD, M.Metal, 20, "Star", 1, { canCollide = false, castShadow = false })
			made += 1
		end
		made += 1
	end
	-- 2 dàn đèn rọi + cột đèn
	for i, sgn in ipairs({ -1, 1 }) do
		K.box(f, "SpotBase" .. i, Vector3.new(3.4, 1.4, 3.4), Vector3.new(CX + sgn * 26, G + 0.9, BZ1 + 22),
			C.DARK, M.Metal, 80, grp, 1)
		K.cyl(f, "SpotPole" .. i, Vector3.new(12, 1.0, 1.0), Vector3.new(CX + sgn * 26, G + 7, BZ1 + 22),
			C.DARK, M.Metal, 80, grp, 2)
		K.box(f, "SpotHead" .. i, Vector3.new(4, 3, 3), Vector3.new(CX + sgn * 26, G + 13, BZ1 + 22),
			C.BULB, M.Neon, 30, grp, 3, { canCollide = false, castShadow = false })
		made += 3
	end
	-- bảng suất chiếu
	K.sign(f, "ShowtimesBoard", Vector3.new(BX0 + 14, G + 7, BZ1 + 6), Vector3.new(16, 9, 0.5),
		Enum.NormalId.Back, "SHOWTIMES", C.DARK, C.NEON, 60, 18)
	K.box(f, "ShowtimesFrame", Vector3.new(17, 10, 0.3), Vector3.new(BX0 + 14, G + 7, BZ1 + 5.6),
		C.GOLD, M.Metal, 60, "SignBoard", 1, { canCollide = false })
	made += 2
	made += K.planter(f, "PlanterE", Vector3.new(BX1 - 12, G + 0.07, BZ1 + 8), 12, 5, 1.6, C.STONE_D, C.LEAF, 100)

	-- bãi đỗ 6 xe: dải Đông trong ô đất (X 278…314, Z −186…−104)
	for i = 0, 6 do
		K.box(f, "StallLine" .. i, Vector3.new(34, 0.06, 0.3), Vector3.new(296, G + 0.1, -186 + i * 13),
			Color3.fromRGB(230, 214, 120), M.SmoothPlastic, 30, grp, 1, { canCollide = false, castShadow = false })
		made += 1
	end
	made += K.car(f, "CarA", Vector3.new(296, G, -173), math.rad(90), Color3.fromRGB(150, 40, 60), 200, "ParkedCar")
	made += K.car(f, "CarB", Vector3.new(296, G, -147), math.rad(90), Color3.fromRGB(40, 56, 92), 200, "ParkedCar")
	made += K.car(f, "CarC", Vector3.new(296, G, -121), math.rad(90), Color3.fromRGB(210, 200, 178), 200, "ParkedCar")
	return made
end

function Module.build(modulesContainer: Instance): Instance
	local root = K.folder("Plot_D3_VinewoodCinema", modulesContainer)
	root:SetAttribute("PlotId", "Plot_D3")
	root:SetAttribute("ModuleId", Module.Id)
	root:SetAttribute("MainEntrance", "X=226, Z=-70 (cửa đôi kính 16 × 9,6 stud, mặt Nam ra Olympic Fwy)")
	root:SetAttribute("Marquee", "Z=-58, rộng 64 stud, cao 12,4 stud, 26 bóng đèn")
	root:SetAttribute("Halls", "2 phòng chiếu 64 × 96 stud, màn 44 × 20")
	root:SetAttribute("StudsPerMeter", SPM)

	buildShell(K.folder("01_Shell", root))
	buildLobby(K.folder("02_Lobby", root))
	buildHall(K.folder("03_HallA", root), HALL_A, 1)
	buildHall(K.folder("04_HallB", root), HALL_B, 2)
	buildUpperFloor(K.folder("05_UpperFloor", root))
	buildRoof(K.folder("06_Roof", root))
	buildFacade(K.folder("07_Facade", root))
	buildForecourt(K.folder("08_Forecourt", root))

	local stat = K.perf(root)
	root:SetAttribute("PartCount", stat.parts)
	return root
end

return Module
