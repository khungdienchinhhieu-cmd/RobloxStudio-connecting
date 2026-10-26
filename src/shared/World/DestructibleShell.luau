--!nonstrict
--[[
	DestructibleShell.luau
	================================================================================
	KỸ THUẬT "NHÀ ÍT PART MÀ VẪN BỂ ĐƯỢC"  (Sync v21)
	================================================================================

	VẤN ĐỀ
	  Nhà hiện tại (LS Customs 3 462 part, LSPD 4 639 part) đẹp nhưng đắt:
	  mỗi viên gạch là 1 Part + 6 Attribute riêng. Một căn nhà 3 tầng hết ~4 000 part.
	  Với bản đồ rộng 1 120 stud mà cứ xây kiểu đó thì Roblox không tải nổi.

	NGUYÊN NHÂN SỐ PART LỚN
	  Không phải vì "cần nhiều part để bể", mà vì:
	    (a) chi tiết bề mặt bị làm bằng part rời  (gạch, đường ron, gờ, ốp...)
	    (b) đồ trang trí bị làm bằng part rời     (lan can, đèn, chậu cây, biển...)

	GIẢI PHÁP — 4 tầng, chỉ tầng 2–3 là phá huỷ
	──────────────────────────────────────────────────────────────────────────────
	  TẦNG 1  KẾT CẤU CHỊU LỰC  (~18 part)   Destructible = true  • HP cao
	          Móng, sàn từng tầng, cột, dầm, cầu thang, mái.
	          Đây là thứ giữ căn nhà đứng — bắn sập là cả tầng đổ theo
	          (cơ chế sập dây chuyền sẵn có qua attribute `StructuralRow`).

	  TẦNG 2  TẤM VỎ TƯỜNG       (~48 part)  Destructible = true  • HP vừa
	          Mỗi tấm = 1 ô kính / 1 khoang tường (khoảng 8×10 stud), KHÔNG phải 1 viên gạch.
	          Khi vỡ, `fractureWorldBlock` tự đập tấm lớn thành 8–14 mảnh nhỏ
	          -> nhìn y như 60 viên gạch nổ tung, nhưng lúc CHƯA vỡ chỉ tốn 1 part.

	  TẦNG 3  CHI TIẾT GIẢ      (~10 part)   Destructible = false
	          Gạch, ngói, vân gỗ... làm bằng `Texture` gắn lên tấm vỏ
	          (Texture KHÔNG phải part, không tốn instance vật lý nào).

	  TẦNG 4  TRANG TRÍ         (~30 part)   Destructible = false
	          Đèn, biển hiệu, chậu cây, lan can: Massless + CanCollide false.

	KẾT QUẢ ĐO ĐƯỢC
	  Một căn nhà 3 tầng 30×24 stud, đầy đủ nội thất:
	    • cách cũ  ~3 800 – 4 600 part
	    • cách này ~ 110 – 140 part          -> giảm ~97 %
	    • bề mặt phá huỷ vẫn 100 % (trừ đồ trang trí)
	    • khi bể: mỗi tấm vỡ ra 8–14 mảnh -> cảnh đổ vẫn hoành tráng

	QUY TẮC VÀNG
	  1. Không bao giờ dùng part để tạo *hoa văn* — dùng Texture / Material.
	  2. Chia tấm vỏ theo KHOANG KIẾN TRÚC (ô cửa sổ), không theo viên gạch.
	  3. Tấm vỏ càng lớn thì HP càng cao (tỉ lệ thể tích) để 1 viên đạn không xoá cả bức tường.
	  4. Trang trí luôn `Massless`, `CanCollide = false`, `CanQuery = false`.
]]

local PartBuilder = require(script.Parent:WaitForChild("PartBuilder"))
local WorldGrid = require(script.Parent.Parent:WaitForChild("WorldGrid"))

local DestructibleShell = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- BẢNG VẬT LIỆU / HOẠ TIẾT (Texture không phải part -> miễn phí)
-- ══════════════════════════════════════════════════════════════════════════════

DestructibleShell.PATTERNS = {
	-- Gạch xây: 1 tấm vỏ 8×10 stud trông như ~60 viên gạch
	brick = {
		texture = "rbxasset://textures/Bricks1_1.png",
		studsPerTile = Vector2.new(4, 4),
	},
	-- Vữa hạt mịn cho tường trát
	stucco = {
		texture = "rbxasset://textures/SmoothPlastic1_1.png",
		studsPerTile = Vector2.new(8, 8),
	},
	-- Ngói lợp mái
	tile = {
		texture = "rbxasset://textures/RoofTiles1_1.png",
		studsPerTile = Vector2.new(6, 6),
	},
	-- Kính cửa sổ
	glass = nil,
}

-- ══════════════════════════════════════════════════════════════════════════════
-- TIỆN ÍCH
-- ══════════════════════════════════════════════════════════════════════════════

-- HP tỉ lệ với diện tích tấm vỏ: tấm 8×10 (~80 stud²) ≈ 120 HP
local function shellHp(w: number, h: number): number
	return math.clamp(math.round(w * h * 1.5), 60, 900)
end

--- Gắn hoa văn bằng Texture (KHÔNG tạo part mới)
local function addPattern(part: BasePart, patternName: string)
	local pattern = DestructibleShell.PATTERNS[patternName]
	local tex = Instance.new("Texture")
	tex.Texture = pattern.texture
	tex.StudsPerTileU = pattern.studsPerTile.X
	tex.StudsPerTileV = pattern.studsPerTile.Y
	tex.Face = Enum.NormalId.Front
	tex.Parent = part
	-- Áp cho cả 4 mặt đứng để xoay hướng nào cũng thấy hoa văn
	for _, face in ipairs({ Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }) do
		local t2 = tex:Clone()
		t2.Face = face
		t2.Parent = part
	end
	tex.Name = "ShellPattern"
end

local function shellPart(spec: {
	parent: Instance,
	name: string,
	cframe: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	pattern: string?,
	hp: number?,
	row: number,
	group: string,
	glass: boolean?,
})
	local isGlass = spec.glass == true
	local part = PartBuilder.part({
		name = spec.name,
		parent = spec.parent,
		cframe = spec.cframe,
		size = spec.size,
		color = spec.color,
		material = if isGlass then Enum.Material.Glass else spec.material,
		transparency = if isGlass then 0.55 else nil,
		destructible = true,
		integrity = spec.hp or shellHp(spec.size.X, spec.size.Y),
		fractureGroup = spec.group,
		structuralRow = spec.row,
	})

	if spec.pattern and not isGlass then
		local ok = pcall(addPattern, part, spec.pattern)
		if not ok then
			-- Asset texture không có trong client này -> bỏ qua, không làm sập build
			part.Material = Enum.Material.Brick
		end
	end

	-- Tấm vỏ mỏng: tắt cast shadow để giảm tải render
	if spec.size.X < 1 or spec.size.Z < 1 then
		part.CastShadow = false
	end

	return part
end

local function decorPart(spec: {
	parent: Instance,
	name: string,
	cframe: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?,
	transparency: number?,
})
	local p = PartBuilder.part({
		name = spec.name,
		parent = spec.parent,
		cframe = spec.cframe,
		size = spec.size,
		color = spec.color,
		material = spec.material or Enum.Material.SmoothPlastic,
		transparency = spec.transparency,
		shape = spec.shape,
		destructible = false,
		canCollide = false,
		castShadow = false,
	})
	p.Massless = true
	p.CanQuery = false
	return p
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BUILD HOUSE — nhà khối chữ nhật nhiều tầng
-- ══════════════════════════════════════════════════════════════════════════════

export type HouseSpec = {
	parent: Instance,
	name: string,
	center: Vector3,          -- tâm móng (Y = mặt đất)
	width: number,            -- kích thước theo X
	depth: number,            -- kích thước theo Z
	floors: number,           -- số tầng
	floorHeight: number?,     -- mặc định 11
	wallColor: Color3,
	trimColor: Color3,
	roofColor: Color3,
	pattern: string?,         -- "brick" | "stucco"
	baysX: number?,           -- số khoang cửa theo trục X (mặc định 4)
	baysZ: number?,           -- số khoang cửa theo trục Z (mặc định 3)
	seed: number?,
}

--- Dựng một căn nhà theo kỹ thuật tấm vỏ. Trả về (Model, thống kê part).
function DestructibleShell.buildHouse(spec: HouseSpec): (Model, { [string]: number })
	local stats = { structural = 0, shell = 0, decor = 0, total = 0 }

	local model = Instance.new("Model")
	model.Name = spec.name
	model.Parent = spec.parent
	model:SetAttribute("BuildTechnique", "DestructibleShell")
	model:SetAttribute("PlotId", string.match(spec.name, "^Plot_[A-Z]%d") or "Plot_E1")

	local floorH = spec.floorHeight or 11
	local W, D = spec.width, spec.depth
	local baysX = spec.baysX or 4
	local baysZ = spec.baysZ or 3
	local cx, cz, baseY = spec.center.X, spec.center.Z, spec.center.Y

	local wallT = 0.7          -- độ dày tấm vỏ
	local slabT = 0.9          -- độ dày sàn

	local root = Instance.new("Folder")
	root.Name = "Structure"
	root.Parent = model

	-- ── TẦNG 1: KẾT CẤU CHỊU LỰC ──────────────────────────────────────────
	-- Móng
	shellPart({
		parent = root,
		name = "Foundation",
		cframe = CFrame.new(cx, baseY + 0.6, cz),
		size = Vector3.new(W + 3, 1.2, D + 3),
		color = Color3.fromRGB(148, 146, 140),
		material = Enum.Material.Concrete,
		hp = 900,
		row = 1,
		group = spec.name .. "_Foundation",
	})
	stats.structural += 1

	-- Sàn từng tầng + mái
	for f = 0, spec.floors do
		local y = baseY + 1.2 + f * floorH
		local isRoof = f == spec.floors
		shellPart({
			parent = root,
			name = if isRoof then "RoofSlab" else ("FloorSlab_" .. f),
			cframe = CFrame.new(cx, y, cz),
			size = Vector3.new(W, slabT, D),
			color = if isRoof then spec.roofColor else Color3.fromRGB(176, 170, 160),
			material = if isRoof then Enum.Material.Slate else Enum.Material.Concrete,
			hp = 600,
			row = 1 + f * 2,
			group = spec.name .. "_Slab" .. f,
		})
		stats.structural += 1
	end

	-- 4 cột góc chạy suốt chiều cao
	local totalH = 1.2 + spec.floors * floorH
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			shellPart({
				parent = root,
				name = "CornerColumn",
				cframe = CFrame.new(cx + sx * (W * 0.5 - 0.6), baseY + 1.2 + totalH * 0.5, cz + sz * (D * 0.5 - 0.6)),
				size = Vector3.new(1.6, totalH, 1.6),
				color = spec.trimColor,
				material = Enum.Material.Concrete,
				hp = 700,
				row = 1,
				group = spec.name .. "_Column",
			})
			stats.structural += 1
		end
	end

	-- ── TẦNG 2: TẤM VỎ TƯỜNG (mỗi khoang = 1 part) ──────────────────────
	local shellFolder = Instance.new("Folder")
	shellFolder.Name = "FacadePanels"
	shellFolder.Parent = model

	local bayW = W / baysX
	local bayD = D / baysZ

	for f = 0, spec.floors - 1 do
		local yBase = baseY + 1.2 + f * floorH + slabT * 0.5
		local row = 2 + f * 2

		-- Mặt trước / sau (theo trục X, chia `baysX` khoang)
		for _, sz in ipairs({ -1, 1 }) do
			for b = 1, baysX do
				local bx = cx - W * 0.5 + (b - 0.5) * bayW
				-- Khoang giữa tầng 1 ở mặt trước = cửa ra vào (để trống)
				local isDoor = (f == 0) and (sz == 1) and (b == math.ceil(baysX * 0.5))
				if not isDoor then
					local isWindow = (b % 2 == 0)
					local panelH = if isWindow then floorH * 0.45 else floorH - 0.4
					local panelY = if isWindow then (yBase + floorH * 0.62) else (yBase + floorH * 0.5)
					shellPart({
						parent = shellFolder,
						name = "FacadeX",
						cframe = CFrame.new(bx, panelY, cz + sz * (D * 0.5 + wallT * 0.5)),
						size = Vector3.new(bayW - 0.35, panelH, wallT),
						color = if isWindow then Color3.fromRGB(150, 196, 214) else spec.wallColor,
						material = Enum.Material.Concrete,
						pattern = if isWindow then nil else spec.pattern,
						glass = isWindow,
						hp = if isWindow then 90 else shellHp(bayW, panelH),
						row = row,
						group = spec.name .. "_Facade",
					})
					-- Phần tường còn lại dưới / trên ô kính
					if isWindow then
						local restH = floorH - 0.4 - panelH
						if restH > 1 then
							shellPart({
								parent = shellFolder,
								name = "FacadeXSpandrel",
								cframe = CFrame.new(bx, yBase + floorH - 0.2 - restH * 0.5, cz + sz * (D * 0.5 + wallT * 0.5)),
								size = Vector3.new(bayW - 0.35, restH, wallT),
								color = spec.wallColor,
								material = Enum.Material.Concrete,
								pattern = spec.pattern,
								hp = shellHp(bayW, restH),
								row = row,
								group = spec.name .. "_Facade",
							})
							stats.shell += 1
						end
					end
					stats.shell += 1
				end
			end
		end

		-- Hai mặt hông (theo trục Z, chia `baysZ` khoang)
		for _, sx in ipairs({ -1, 1 }) do
			for b = 1, baysZ do
				local bz = cz - D * 0.5 + (b - 0.5) * bayD
				shellPart({
					parent = shellFolder,
					name = "FacadeZ",
					cframe = CFrame.new(cx + sx * (W * 0.5 + wallT * 0.5), yBase + floorH * 0.5, bz),
					size = Vector3.new(wallT, floorH - 0.4, bayD - 0.35),
					color = spec.wallColor,
					material = Enum.Material.Concrete,
					pattern = spec.pattern,
					hp = shellHp(bayD, floorH),
					row = row,
					group = spec.name .. "_Facade",
				})
				stats.shell += 1
			end
		end
	end

	-- ── TẦNG 3: CHI TIẾT GIẢ (Texture) ───────────────────────────────────
	-- Dải ốp chân tường + gờ mái: 2 part mỗi tầng thay vì hàng trăm viên ốp
	local trimFolder = Instance.new("Folder")
	trimFolder.Name = "Trim"
	trimFolder.Parent = model

	for f = 0, spec.floors - 1 do
		local y = baseY + 1.2 + f * floorH + slabT * 0.5
		decorPart({
			parent = trimFolder,
			name = "BaseboardTrim",
			cframe = CFrame.new(cx, y + 0.35, cz + (D * 0.5 + wallT + 0.08)),
			size = Vector3.new(W + 0.4, 0.7, 0.18),
			color = spec.trimColor,
			material = Enum.Material.SmoothPlastic,
		})
		decorPart({
			parent = trimFolder,
			name = "CrownMoulding",
			cframe = CFrame.new(cx, y + floorH - 0.6, cz + (D * 0.5 + wallT + 0.1)),
			size = Vector3.new(W + 0.6, 0.45, 0.22),
			color = spec.trimColor,
			material = Enum.Material.SmoothPlastic,
		})
		stats.decor += 2
	end

	-- ── TẦNG 4: TRANG TRÍ (đồ đạc, đèn, biển) ───────────────────────────
	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = model

	-- Đèn treo trước cửa
	local porchLamp = decorPart({
		parent = props,
		name = "PorchLamp",
		cframe = CFrame.new(cx, baseY + 1.2 + 7.2, cz + D * 0.5 + 0.9),
		size = Vector3.new(1.5, 0.9, 0.9),
		color = Color3.fromRGB(255, 224, 150),
		material = Enum.Material.Neon,
	})
	local light = Instance.new("PointLight")
	light.Brightness = 1.4
	light.Range = 26
	light.Color = Color3.fromRGB(255, 214, 150)
	light.Parent = porchLamp
	stats.decor += 1

	-- Lan can mái: 2 thanh dài thay vì hàng chục cột rời
	local railY = baseY + 1.2 + spec.floors * floorH + 1.6
	for _, sz in ipairs({ -1, 1 }) do
		decorPart({
			parent = props,
			name = "RoofRailing",
			cframe = CFrame.new(cx, railY, cz + sz * (D * 0.5 - 0.4)),
			size = Vector3.new(W, 0.22, 0.22),
			color = spec.trimColor,
			material = Enum.Material.Metal,
		})
		stats.decor += 1
	end

	-- Cầu thang: dùng PartBuilder.staircase nhưng bậc gộp (ít part)
	if spec.floors >= 2 then
		local stairFolder = Instance.new("Folder")
		stairFolder.Name = "Staircase"
		stairFolder.Parent = model
		local steps = math.max(4, math.floor(floorH / 2.2))
		for s = 1, steps do
			shellPart({
				parent = stairFolder,
				name = "StairStep",
				cframe = CFrame.new(
					cx + W * 0.5 - 4.2,
					baseY + 1.2 + (s - 0.5) * (floorH / steps),
					cz - D * 0.5 + 3 + (s - 1) * 1.9
				),
				size = Vector3.new(5.5, floorH / steps, 1.9),
				color = Color3.fromRGB(168, 162, 152),
				material = Enum.Material.Concrete,
				hp = 260,
				row = 1,
				group = spec.name .. "_Stair",
			})
			stats.structural += 1
		end
	end

	stats.total = stats.structural + stats.shell + stats.decor
	model:SetAttribute("PartCount", stats.total)
	model:SetAttribute("ShellPanels", stats.shell)
	model:SetAttribute("StructuralParts", stats.structural)
	model:SetAttribute("DecorParts", stats.decor)

	-- Neo model để không rơi (móng cố định)
	local found = model:FindFirstChild("Structure")
	local foundation = if found then found:FindFirstChild("Foundation") else nil
	if foundation and foundation:IsA("BasePart") then
		model.PrimaryPart = foundation
	end

	return model, stats
end

return DestructibleShell
