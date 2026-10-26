--!strict
--[[
	Plot_E1_PacificBluffs.luau  —  BIỆT THỰ VEN VỊNH PACIFIC BLUFFS
	================================================================================
	Ô đất : Plot_E1 (MỚI, Sync v21)  |  X −522..−342 , Z −208..−54 , groundY = 1.15
	Mặt tiền quay Nam (+Z, ra Vinewood Blvd) và Đông (+X, ra Pacific Coast Hwy).

	★ ĐÂY LÀ CÔNG TRÌNH MẪU CHO KỸ THUẬT "ÍT PART MÀ VẪN BỂ"
	  Toàn bộ phần thân nhà do `DestructibleShell.buildHouse` dựng:
	    TẦNG 1  kết cấu chịu lực  (móng, sàn, cột, cầu thang)   ~14 part
	    TẦNG 2  tấm vỏ tường      (mỗi ô cửa sổ = 1 tấm)        ~52 part
	    TẦNG 3  hoa văn bằng Texture (KHÔNG phải part)            0 part
	    TẦNG 4  trang trí         (ốp chân, gờ mái, đèn, lan can) ~9 part
	  Cộng thêm sân vườn / hồ bơi / cổng / cây bên dưới.
	  => So sánh: LS Customs dùng 3 462 part cho cùng diện tích.
	     Biệt thự này dùng chưa tới ~150 part nhưng BỀ MẶT VẪN BỂ 100 %.

	Khi tấm vỏ vỡ, `fractureWorldBlock` tự đập nó thành 8–14 mảnh theo lưới 3D
	-> nhìn y như 60 viên gạch nổ tung.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartBuilder = require(Shared:WaitForChild("World"):WaitForChild("PartBuilder"))
local DestructibleShell = require(Shared:WaitForChild("World"):WaitForChild("DestructibleShell"))

local V = Vector3.new
local RGB = Color3.fromRGB

-- ── Toạ độ ──────────────────────────────────────────────────────────────────
local GY = 1.15                      -- đỉnh vỉa hè
local CX, CZ = -432, -131            -- tâm ô đất Plot_E1
local HW, HD = 44, 28                -- khối nhà: 44 (X) × 28 (Z)
local FLOORS = 3
local FLOOR_H = 11

-- ── Bảng màu ────────────────────────────────────────────────────────────────
local C_WALL    = RGB(226, 214, 196)  -- tường vôi trắng ngà
local C_TRIM    = RGB(242, 240, 234)  -- gờ / cột trắng
local C_ROOF    = RGB(96, 74, 62)     -- ngói nâu đỏ
local C_DECK    = RGB(198, 186, 168)  -- sàn hiên đá
local C_WATER   = RGB(52, 158, 196)   -- nước hồ bơi
local C_POOL    = RGB(226, 232, 230)  -- thành hồ
local C_GRASS   = RGB(84, 138, 82)    -- thảm cỏ
local C_HEDGE   = RGB(52, 104, 62)    -- hàng rào cây
local C_ASPHALT = RGB(58, 60, 66)     -- đường xe vào
local C_IRON    = RGB(38, 42, 50)     -- cổng sắt
local C_TRUNK   = RGB(126, 96, 64)    -- thân cọ
local C_LEAF    = RGB(58, 128, 68)    -- tàu cọ
local C_NEON    = RGB(255, 208, 128)  -- đèn sân
local C_STONE   = RGB(176, 172, 164)  -- đá viền

local module = {
	Id = "Plot_E1_PacificBluffs",
	PlotId = "Plot_E1",
	Order = 40,
	Enabled = true,
}

-- ══════════════════════════════════════════════════════════════════════════════
-- Tiện ích cục bộ
-- ══════════════════════════════════════════════════════════════════════════════

local function ground(parent: Instance, name: string, pos: Vector3, size: Vector3, color: Color3, material: Enum.Material?, collide: boolean?)
	return PartBuilder.part({
		name = name,
		parent = parent,
		pos = pos,
		size = size,
		color = color,
		material = material or Enum.Material.Concrete,
		canCollide = if collide ~= nil then collide else true,
		destructible = false,
		castShadow = false,
	})
end

local function solid(parent: Instance, name: string, pos: Vector3, size: Vector3, color: Color3, material: Enum.Material?, hp: number, group: string, row: number?)
	return PartBuilder.part({
		name = name,
		parent = parent,
		pos = pos,
		size = size,
		color = color,
		material = material or Enum.Material.Concrete,
		destructible = true,
		integrity = hp,
		fractureGroup = group,
		structuralRow = row or 1,
	})
end

local function prop(parent: Instance, name: string, pos: Vector3, size: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?)
	local p = PartBuilder.part({
		name = name,
		parent = parent,
		pos = pos,
		size = size,
		color = color,
		material = material or Enum.Material.SmoothPlastic,
		shape = shape,
		canCollide = false,
		castShadow = false,
		destructible = false,
	})
	p.Massless = true
	p.CanQuery = false
	return p
end

-- Cây cọ: 1 thân + 5 tàu = 6 part (không phải 40 part lá rời)
local function palm(parent: Instance, name: string, x: number, z: number, height: number, seed: number)
	local trunk = solid(parent, name .. "_Trunk", V(x, GY + height * 0.5, z), V(1.5, height, 1.5), C_TRUNK, Enum.Material.Wood, 160, "PalmTrunk")
	trunk.Shape = Enum.PartType.Cylinder
	trunk.CFrame = CFrame.new(V(x, GY + height * 0.5, z)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Size = V(height, 1.5, 1.5)

	local top = GY + height
	for i = 1, 5 do
		local ang = (i / 5) * math.pi * 2 + seed
		local leaf = prop(
			parent,
			name .. "_Leaf" .. i,
			V(x + math.cos(ang) * 3.4, top + 0.2, z + math.sin(ang) * 3.4),
			V(8.2, 0.35, 2.6),
			C_LEAF,
			Enum.Material.Grass
		)
		leaf.CFrame = CFrame.new(V(x + math.cos(ang) * 3.6, top - 0.4, z + math.sin(ang) * 3.6))
			* CFrame.Angles(0, -ang, math.rad(-14))
	end
	prop(parent, name .. "_Crown", V(x, top + 0.3, z), V(1.6, 1.2, 1.6), C_LEAF, Enum.Material.Grass)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BUILD
-- ══════════════════════════════════════════════════════════════════════════════

function module.build(modulesContainer: Instance): Instance?
	local model = Instance.new("Model")
	model.Name = module.PlotId .. "_PacificBluffsVilla"
	model.Parent = modulesContainer
	model:SetAttribute("PlotId", module.PlotId)

	local site = Instance.new("Folder")
	site.Name = "Site"
	site.Parent = model

	-- ── 1. KHU ĐẤT ────────────────────────────────────────────────────────
	-- Thảm cỏ phủ toàn ô (1 part thay vì hàng trăm ô cỏ)
	ground(site, "Lawn", V(CX, GY + 0.04, CZ), V(178, 0.08, 152), C_GRASS, Enum.Material.Grass, true)

	-- Đường xe vào từ Vinewood Blvd (mép Nam Z = -54) chạy vào nhà
	ground(site, "Driveway", V(CX + 34, GY + 0.09, CZ + 46), V(26, 0.1, 62), C_ASPHALT, Enum.Material.Asphalt, true)
	-- Vạch chỉ dẫn mép đường
	ground(site, "DrivewayEdgeL", V(CX + 21.2, GY + 0.14, CZ + 46), V(0.5, 0.06, 62), C_STONE, Enum.Material.Concrete, false)
	ground(site, "DrivewayEdgeR", V(CX + 46.8, GY + 0.14, CZ + 46), V(0.5, 0.06, 62), C_STONE, Enum.Material.Concrete, false)

	-- Sân đỗ xe (3 chỗ) trước cổng
	ground(site, "MotorCourt", V(CX + 34, GY + 0.1, CZ + 6), V(30, 0.12, 22), C_STONE, Enum.Material.Concrete, true)
	for i = 0, 2 do
		ground(
			site,
			"ParkingStripe" .. i,
			V(CX + 24 + i * 10, GY + 0.17, CZ + 6),
			V(0.4, 0.05, 18),
			RGB(238, 236, 228),
			Enum.Material.SmoothPlastic,
			false
		)
	end

	-- ── 2. HỒ BƠI + HIÊN ──────────────────────────────────────────────────
	local poolX, poolZ = CX - 40, CZ + 26
	-- Thành hồ: 1 part đá bao quanh (rỗng ở giữa nhờ 4 dải)
	ground(site, "PoolCopingN", V(poolX, GY + 0.16, poolZ - 11), V(26, 0.32, 1.6), C_POOL, Enum.Material.Marble, true)
	ground(site, "PoolCopingS", V(poolX, GY + 0.16, poolZ + 11), V(26, 0.32, 1.6), C_POOL, Enum.Material.Marble, true)
	ground(site, "PoolCopingW", V(poolX - 12, GY + 0.16, poolZ), V(1.6, 0.32, 22), C_POOL, Enum.Material.Marble, true)
	ground(site, "PoolCopingE", V(poolX + 12, GY + 0.16, poolZ), V(1.6, 0.32, 22), C_POOL, Enum.Material.Marble, true)
	-- Nước (không va chạm, trong suốt)
	local water = PartBuilder.part({
		name = "PoolWater",
		parent = site,
		pos = V(poolX, GY - 0.1, poolZ),
		size = V(23, 2.2, 20),
		color = C_WATER,
		material = Enum.Material.Glass,
		transparency = 0.35,
		canCollide = false,
		castShadow = false,
		destructible = false,
	})
	water.CanQuery = false

	-- Sàn hiên đá dọc mặt Nam của nhà (2 part thay vì từng viên lát)
	ground(site, "Terrace", V(CX, GY + 0.18, CZ + 20.5), V(HW + 16, 0.36, 13), C_DECK, Enum.Material.Marble, true)
	-- Lan can hiên: 2 thanh dài
	for _, sx in ipairs({ -1, 1 }) do
		prop(site, "TerraceRail" .. sx, V(CX + sx * (HW * 0.5 + 7.6), GY + 1.55, CZ + 20.5), V(0.24, 0.24, 13), C_IRON, Enum.Material.Metal)
	end
	prop(site, "TerraceRailS", V(CX, GY + 1.55, CZ + 27), V(HW + 16, 0.24, 0.24), C_IRON, Enum.Material.Metal)
	-- Cột đèn sân
	for _, sx in ipairs({ -1, 1 }) do
		prop(site, "YardLampPost" .. sx, V(CX + sx * (HW * 0.5 + 8), GY + 4.5, CZ + 27), V(0.6, 9, 0.6), C_IRON, Enum.Material.Metal)
		local bulb = prop(site, "YardLampBulb" .. sx, V(CX + sx * (HW * 0.5 + 8), GY + 9.2, CZ + 27), V(1.6, 1.6, 1.6), C_NEON, Enum.Material.Neon)
		local l = Instance.new("PointLight")
		l.Brightness = 1.6
		l.Range = 34
		l.Color = RGB(255, 214, 150)
		l.Parent = bulb
	end

	-- ── 3. THÂN NHÀ — kỹ thuật ít part ────────────────────────────────────
	local house, stats = DestructibleShell.buildHouse({
		parent = model,
		name = module.Id,
		center = V(CX, GY + 0.2, CZ - 6),
		width = HW,
		depth = HD,
		floors = FLOORS,
		floorHeight = FLOOR_H,
		wallColor = C_WALL,
		trimColor = C_TRIM,
		roofColor = C_ROOF,
		pattern = "stucco",
		baysX = 4,
		baysZ = 3,
		seed = 7,
	})
	house.Name = "VillaBody"

	-- ── 4. CHI TIẾT KIẾN TRÚC (vẫn rất ít part) ───────────────────────────
	local detail = Instance.new("Folder")
	detail.Name = "ArchitecturalDetail"
	detail.Parent = model

	local houseBase = GY + 0.2 + 1.2

	-- Mái hiên rộng che sàn hiên tầng 1: 1 tấm + 2 thanh đỡ
	solid(detail, "PorticoCanopy", V(CX, houseBase + FLOOR_H - 1.2, CZ + 6), V(HW + 10, 0.7, 15), C_TRIM, Enum.Material.Concrete, 420, "Portico", 2)
	for _, sx in ipairs({ -1, 1 }) do
		solid(
			detail,
			"PorticoPillar" .. sx,
			V(CX + sx * (HW * 0.5 + 3), houseBase + (FLOOR_H - 1.2) * 0.5, CZ + 12),
			V(1.4, FLOOR_H - 1.2, 1.4),
			C_TRIM,
			Enum.Material.Concrete,
			380,
			"Portico",
			1
		)
	end

	-- Ban công tầng 2 (1 tấm sàn + lan can liền)
	solid(detail, "BalconySlab", V(CX, houseBase + FLOOR_H + 0.45, CZ + 11), V(HW - 6, 0.9, 10), C_TRIM, Enum.Material.Concrete, 460, "Balcony", 3)
	prop(detail, "BalconyRailF", V(CX, houseBase + FLOOR_H + 2.1, CZ + 15.8), V(HW - 6, 2.3, 0.22), C_IRON, Enum.Material.Metal)
	for _, sx in ipairs({ -1, 1 }) do
		prop(detail, "BalconyRailS" .. sx, V(CX + sx * (HW - 6) * 0.5, houseBase + FLOOR_H + 2.1, CZ + 11), V(0.22, 2.3, 10), C_IRON, Enum.Material.Metal)
	end

	-- Khung cửa chính: 1 vòm (WedgePart) + 2 trụ
	solid(detail, "EntryDoorFrame", V(CX, houseBase + 4.6, CZ + HD * 0.5 + 0.6), V(9, 9.2, 0.9), C_TRIM, Enum.Material.Concrete, 500, "Entry", 1)
	local door = PartBuilder.part({
		name = "EntryDoorGlass",
		parent = detail,
		pos = V(CX, houseBase + 2.6, CZ + HD * 0.5 + 1.15),
		size = V(7.4, 5.2, 0.3),
		color = RGB(150, 205, 226),
		material = Enum.Material.Glass,
		transparency = 0.45,
		canCollide = false,
		destructible = true,
		integrity = 70,
		fractureGroup = "EntryGlass",
		structuralRow = 1,
	})
	door.CastShadow = false

	-- Ống khói + 2 ống thông gió
	solid(detail, "Chimney", V(CX - 14, houseBase + FLOORS * FLOOR_H + 3.4, CZ - 6), V(4, 8, 4), RGB(150, 104, 88), Enum.Material.Brick, 300, "Chimney", 8)
	prop(detail, "ChimneyCap", V(CX - 14, houseBase + FLOORS * FLOOR_H + 7.6, CZ - 6), V(4.8, 0.6, 4.8), RGB(70, 66, 62), Enum.Material.Metal)

	-- Biển số nhà
	local numberPlate = prop(detail, "HouseNumberPlate", V(CX + 6.5, houseBase + 5.6, CZ + HD * 0.5 + 0.75), V(2.2, 1.1, 0.12), RGB(28, 30, 36), Enum.Material.SmoothPlastic)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(220, 110)
	sg.MaxDistance = 120
	sg.Parent = numberPlate
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = "1842"
	tl.TextColor3 = RGB(236, 226, 196)
	tl.TextScaled = true
	tl.Font = Enum.Font.GothamBold
	tl.Parent = sg

	-- ── 5. RANH GIỚI KHU ĐẤT ──────────────────────────────────────────────
	local fence = Instance.new("Folder")
	fence.Name = "Boundary"
	fence.Parent = model

	-- Hàng rào cây (hedge): 4 dải dài thay vì 60 bụi rời
	local halfX, halfZ = 88, 75
	local fenceY = GY + 1.5
	local hedgeT = 2.4
	prop(fence, "HedgeN", V(CX, fenceY, CZ - halfZ), V(halfX * 2, 3, hedgeT), C_HEDGE, Enum.Material.Grass)
	prop(fence, "HedgeS_L", V(CX - 30, fenceY, CZ + halfZ), V(halfX * 2 - 60, 3, hedgeT), C_HEDGE, Enum.Material.Grass)
	prop(fence, "HedgeS_R", V(CX + 30, fenceY, CZ + halfZ), V(halfX * 2 - 60, 3, hedgeT), C_HEDGE, Enum.Material.Grass)
	prop(fence, "HedgeW", V(CX - halfX, fenceY, CZ), V(hedgeT, 3, halfZ * 2), C_HEDGE, Enum.Material.Grass)
	prop(fence, "HedgeE_L", V(CX + halfX, fenceY, CZ - 20), V(hedgeT, 3, halfZ * 2 - 40), C_HEDGE, Enum.Material.Grass)
	prop(fence, "HedgeE_R", V(CX + halfX, fenceY, CZ + 46), V(hedgeT, 3, halfZ * 2 - 90), C_HEDGE, Enum.Material.Grass)

	-- Cổng sắt (bể được — xe tông bay cổng)
	for _, sx in ipairs({ -1, 1 }) do
		solid(
			fence,
			"GatePost" .. sx,
			V(CX + 34 + sx * 10, GY + 5, CZ + halfZ),
			V(2, 10, 2),
			C_STONE,
			Enum.Material.Concrete,
			600,
			"Gate",
			1
		)
	end
	solid(fence, "GateLeafL", V(CX + 28.5, GY + 4.2, CZ + halfZ), V(9, 8.4, 0.4), C_IRON, Enum.Material.Metal, 220, "GateLeaf", 1)
	solid(fence, "GateLeafR", V(CX + 39.5, GY + 4.2, CZ + halfZ), V(9, 8.4, 0.4), C_IRON, Enum.Material.Metal, 220, "GateLeaf", 1)
	for i = 1, 5 do
		prop(fence, "GateBar" .. i, V(CX + 24 + i * 3.4, GY + 4.2, CZ + halfZ + 0.3), V(0.28, 8, 0.28), C_IRON, Enum.Material.Metal)
	end

	-- ── 6. CÂY CỐI ────────────────────────────────────────────────────────
	local garden = Instance.new("Folder")
	garden.Name = "Garden"
	garden.Parent = model

	local palmSpots = {
		{ -74, 62 }, { -74, 10 }, { -74, -52 },
		{ 74, -52 }, { 74, 60 },
		{ -20, 66 }, { 14, 66 },
	}
	for i, s in ipairs(palmSpots) do
		palm(garden, "Palm" .. i, CX + s[1], CZ + s[2], 18 + (i % 3) * 2.5, i * 1.3)
	end

	-- Bụi cây trang trí quanh hồ bơi
	for i = 1, 4 do
		local ang = (i / 4) * math.pi * 2
		prop(
			garden,
			"PoolShrub" .. i,
			V(poolX + math.cos(ang) * 15, GY + 1.2, poolZ + math.sin(ang) * 13),
			V(3.4, 2.4, 3.4),
			C_HEDGE,
			Enum.Material.Grass
		)
	end

	-- ── Thống kê ──────────────────────────────────────────────────────────
	local total = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			total += 1
		end
	end
	model:SetAttribute("PartCount", total)
	model:SetAttribute("BuildTechnique", "DestructibleShell")
	model:SetAttribute("ShellPartStats", string.format(
		"Thân nhà: %d kết cấu + %d tấm vỏ + %d trang trí = %d part",
		stats.structural,
		stats.shell,
		stats.decor,
		stats.total
	))
	print(string.format(
		"[Plot_E1] Biệt thự Pacific Bluffs: %d part TỔNG (thân nhà %d = %d kết cấu + %d tấm vỏ + %d trang trí)",
		total,
		stats.total,
		stats.structural,
		stats.shell,
		stats.decor
	))

	return model
end

return module
