--!strict
--[[
	BuildKit.luau  (Sync v27 — bộ khung dựng công trình dùng chung)
	================================================================================
	Trước đây mỗi module công trình (1 200–3 000 dòng) đều tự chép lại ~120 dòng
	helper (box/rbox/tileField/wallRun/glass/perfPass). Sáu lần chép là sáu lần có
	thể lệch chuẩn (có lần quên tắt CanTouch, có lần để khối 0,3 stud còn va chạm).

	BuildKit gom đúng những helper đó về MỘT chỗ, đã khoá theo luật của dự án:
	  • Mọi khối đi qua PartBuilder.part → tự có máu ẩn (Destructible/PartHealth/...).
	  • Khối nhỏ hơn 1,6 stud KHÔNG BAO GIỜ va chạm (xe/người không bị kẹt trên gờ).
	  • Kính / Neon / khối nhỏ KHÔNG đổ bóng (CastShadow = false).
	  • SurfaceGui: MaxDistance 340, PixelsPerStud ≤ 32, không TextScaled.
	  • `perf()` quét lại toàn bộ cây sau khi dựng: CanTouch = false cho mọi part
	    (dự án không dùng sự kiện .Touched), CanQuery = true cho khối có máu.

	Công trình chỉ cần mô tả kiến trúc, không cần quan tâm mấy luật trên nữa.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local PartBuilder = require(Shared:WaitForChild("World"):WaitForChild("PartBuilder"))

local BuildKit = {}

BuildKit.STUDS_PER_METER = WorldGrid.STUDS_PER_METER
--- Cao độ mặt vỉa hè / nền ô đất (mọi công trình đều đứng trên mặt này).
BuildKit.GROUND = (WorldGrid :: any).SIDEWALK_TOP_Y or 1.15

--- Tuỳ chọn dùng lại: khối nhỏ & kính thì tắt va chạm + tắt đổ bóng.
BuildKit.SMALL = { canCollide = false, castShadow = false }
BuildKit.GLASS = { canCollide = false, castShadow = false }
BuildKit.NEON = { canCollide = false, castShadow = false }

local SMALL_MAX = 1.6

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end
BuildKit.folder = folder

local function merge(spec: { [string]: any }, opts: { [string]: any }?): { [string]: any }
	if opts then
		for k, v in pairs(opts) do
			spec[k] = v
		end
	end
	return spec
end

--- Khối hộp đặt theo TÂM.
function BuildKit.box(
	parent: Instance,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?,
	opts: { [string]: any }?
): Part
	local spec: { [string]: any } = {
		name = name,
		parent = parent,
		size = size,
		pos = pos,
		color = color,
		material = material or Enum.Material.SmoothPlastic,
		destructible = hp ~= nil,
		integrity = hp,
		fractureGroup = group or parent.Name,
		structuralRow = row or 1,
	}
	if math.max(size.X, size.Y, size.Z) < SMALL_MAX then
		spec.canCollide = false
		spec.castShadow = false
	end
	merge(spec, opts)
	return PartBuilder.part(spec :: any)
end

--- Khối hộp đặt theo CFrame (xoay được).
function BuildKit.rbox(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?,
	opts: { [string]: any }?
): Part
	local spec: { [string]: any } = {
		name = name,
		parent = parent,
		size = size,
		cframe = cf,
		color = color,
		material = material or Enum.Material.SmoothPlastic,
		destructible = hp ~= nil,
		integrity = hp,
		fractureGroup = group or parent.Name,
		structuralRow = row or 1,
	}
	if math.max(size.X, size.Y, size.Z) < SMALL_MAX then
		spec.canCollide = false
		spec.castShadow = false
	end
	merge(spec, opts)
	return PartBuilder.part(spec :: any)
end
BuildKit.merge = merge

--- Trụ tròn ĐỨNG (Part.Shape = Cylinder mặc định nằm ngang trục X → xoay 90°).
function BuildKit.cyl(
	parent: Instance,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	row: number?,
	opts: { [string]: any }?
): Part
	local o = merge({ shape = Enum.PartType.Cylinder }, opts)
	return BuildKit.rbox(parent, name, size, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		color, material, hp, group, row, o)
end

--- Bánh xe / ống nằm ngang trục X.
function BuildKit.wheel(parent: Instance, name: string, size: Vector3, pos: Vector3, color: Color3, hp: number?): Part
	return BuildKit.rbox(parent, name, size, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		color, Enum.Material.Rubber, hp, "Wheel", 1, { shape = Enum.PartType.Cylinder })
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SÀN LÁT Ô VUÔNG (sân, sảnh, vỉa hè riêng của công trình)
-- ══════════════════════════════════════════════════════════════════════════════
function BuildKit.tileField(
	parent: Instance,
	prefix: string,
	x0: number, x1: number, z0: number, z1: number,
	y: number, cell: number, hp: number,
	colA: Color3, colB: Color3, group: string, thickness: number?
): number
	local nx = math.max(1, math.floor((x1 - x0) / cell + 0.5))
	local nz = math.max(1, math.floor((z1 - z0) / cell + 0.5))
	local w = (x1 - x0) / nx
	local d = (z1 - z0) / nz
	local made = 0
	for i = 1, nx do
		for j = 1, nz do
			local cxi = x0 + (i - 0.5) * w
			local czi = z0 + (j - 0.5) * d
			local col = if (i + j) % 2 == 0 then colA else colB
			BuildKit.box(parent, string.format("%s_%02d_%02d", prefix, i, j),
				Vector3.new(w - 0.07, thickness or 0.12, d - 0.07),
				Vector3.new(cxi, y, czi), col, Enum.Material.Concrete, hp, group, 1, { canCollide = false })
			made += 1
		end
	end
	return made
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TƯỜNG CÓ KHOÉT CỬA
--   axis "X": tường chạy dọc X tại Z = fixed        (a0..a1 là toạ độ X)
--   axis "Z": tường chạy dọc Z tại X = fixed        (a0..a1 là toạ độ Z)
--   openings: { { a = số, b = số, y0 = số, y1 = số }, ... }
-- ══════════════════════════════════════════════════════════════════════════════
function BuildKit.wall(
	parent: Instance,
	name: string,
	axis: string,
	fixed: number,
	a0: number, a1: number,
	y0: number, y1: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?,
	hp: number?,
	group: string?,
	openings: { any }?
): number
	local list = {}
	if openings then
		for _, o in ipairs(openings) do
			table.insert(list, o)
		end
		table.sort(list, function(p, q) return p.a < q.b and p.a < q.a end)
	end

	local function emit(fromA: number, toA: number, lowY: number, highY: number, tag: string)
		if toA - fromA <= 0.05 or highY - lowY <= 0.05 then
			return 0
		end
		local midA = (fromA + toA) * 0.5
		local midY = (lowY + highY) * 0.5
		local size, pos
		if axis == "X" then
			size = Vector3.new(toA - fromA, highY - lowY, thickness)
			pos = Vector3.new(midA, midY, fixed)
		else
			size = Vector3.new(thickness, highY - lowY, toA - fromA)
			pos = Vector3.new(fixed, midY, midA)
		end
		BuildKit.box(parent, name .. "_" .. tag, size, pos, color, material, hp, group, 1)
		return 1
	end

	local made = 0
	local cursor = a0
	local idx = 0
	for _, o in ipairs(list) do
		local oa = math.max(a0, o.a)
		local ob = math.min(a1, o.b)
		if ob > oa then
			if oa - cursor > 0.05 then
				idx += 1
				made += emit(cursor, oa, y0, y1, string.format("P%02d", idx))
			end
			local oy0 = math.max(y0, o.y0 or y0)
			local oy1 = math.min(y1, o.y1 or y1)
			if oy0 > y0 then
				idx += 1
				made += emit(oa, ob, y0, oy0, string.format("L%02d", idx))
			end
			if oy1 < y1 then
				idx += 1
				made += emit(oa, ob, oy1, y1, string.format("H%02d", idx))
			end
			cursor = math.max(cursor, ob)
		end
	end
	if a1 - cursor > 0.05 then
		idx += 1
		made += emit(cursor, a1, y0, y1, string.format("P%02d", idx))
	end
	return made
end

-- ══════════════════════════════════════════════════════════════════════════════
-- VÁCH KÍNH CHIA Ô (storefront / curtain wall) + khung đứng
-- ══════════════════════════════════════════════════════════════════════════════
function BuildKit.curtain(
	parent: Instance,
	prefix: string,
	axis: string,
	fixed: number,
	a0: number, a1: number,
	y0: number, y1: number,
	cols: number, rows: number,
	glass: Color3,
	frame: Color3,
	hp: number,
	group: string?
): number
	local span = a1 - a0
	local cw = span / cols
	local ch = (y1 - y0) / rows
	local made = 0
	local g = group or "Curtain"

	for i = 1, cols do
		for j = 1, rows do
			local a = a0 + (i - 0.5) * cw
			local y = y0 + (j - 0.5) * ch
			local size, pos
			if axis == "X" then
				size = Vector3.new(cw - 0.34, ch - 0.34, 0.18)
				pos = Vector3.new(a, y, fixed)
			else
				size = Vector3.new(0.18, ch - 0.34, cw - 0.34)
				pos = Vector3.new(fixed, y, a)
			end
			BuildKit.box(parent, string.format("%s_G%02d_%d", prefix, i, j), size, pos, glass,
				Enum.Material.Glass, hp, g, 1, { canCollide = false, castShadow = false, transparency = 0.18 })
			made += 1
		end
	end

	-- khung đứng + khung ngang
	for i = 0, cols do
		local a = a0 + i * cw
		local size, pos
		if axis == "X" then
			size = Vector3.new(0.34, y1 - y0, 0.42)
			pos = Vector3.new(a, (y0 + y1) * 0.5, fixed)
		else
			size = Vector3.new(0.42, y1 - y0, 0.34)
			pos = Vector3.new(fixed, (y0 + y1) * 0.5, a)
		end
		BuildKit.box(parent, string.format("%s_MullionV_%02d", prefix, i), size, pos, frame,
			Enum.Material.Metal, math.max(30, hp), g, 2, { canCollide = false, castShadow = false })
		made += 1
	end
	for j = 0, rows do
		local y = y0 + j * ch
		local size, pos
		if axis == "X" then
			size = Vector3.new(span, 0.34, 0.42)
			pos = Vector3.new((a0 + a1) * 0.5, y, fixed)
		else
			size = Vector3.new(0.42, 0.34, span)
			pos = Vector3.new(fixed, y, (a0 + a1) * 0.5)
		end
		BuildKit.box(parent, string.format("%s_MullionH_%02d", prefix, j), size, pos, frame,
			Enum.Material.Metal, math.max(30, hp), g, 2, { canCollide = false, castShadow = false })
		made += 1
	end
	return made
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BIỂN HIỆU (bảng + SurfaceGui chữ nổi)
-- ══════════════════════════════════════════════════════════════════════════════
function BuildKit.sign(
	parent: Instance,
	name: string,
	pos: Vector3,
	size: Vector3,
	face: Enum.NormalId,
	text: string,
	bg: Color3,
	fg: Color3,
	hp: number?,
	pixels: number?
): Part
	local board = BuildKit.box(parent, name, size, pos, bg, Enum.Material.SmoothPlastic, hp, "SignBoard", 1)
	board:SetAttribute("IsSignBoard", true)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gui_" .. name
	gui.Face = face
	gui.MaxDistance = 340
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = math.min(pixels or 20, 32)
	gui.Adornee = board
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = fg
	label.TextScaled = false
	label.TextSize = 34
	label.Font = Enum.Font.GothamBlack
	label.TextWrapped = false
	label.Parent = gui
	return board
end

-- ══════════════════════════════════════════════════════════════════════════════
-- LAN CAN KÍNH (ban công, cầu thang, sân thượng)
-- ══════════════════════════════════════════════════════════════════════════════
function BuildKit.railing(
	parent: Instance,
	name: string,
	axis: string,
	fixed: number,
	a0: number, a1: number,
	y: number,
	height: number,
	color: Color3,
	glass: Color3?,
	hp: number?
): number
	local made = 0
	local span = a1 - a0
	local posts = math.max(2, math.floor(span / 5) + 1)
	for i = 0, posts - 1 do
		local a = a0 + (i / (posts - 1)) * span
		local size, pos
		if axis == "X" then
			size = Vector3.new(0.28, height, 0.28)
			pos = Vector3.new(a, y + height * 0.5, fixed)
		else
			size = Vector3.new(0.28, height, 0.28)
			pos = Vector3.new(fixed, y + height * 0.5, a)
		end
		BuildKit.box(parent, string.format("%s_Post%02d", name, i), size, pos, color,
			Enum.Material.Metal, math.max(25, hp or 40), name, 2, { canCollide = false, castShadow = false })
		made += 1
	end
	-- tay vịn trên
	local sizeTop, posTop
	if axis == "X" then
		sizeTop = Vector3.new(span, 0.24, 0.34)
		posTop = Vector3.new((a0 + a1) * 0.5, y + height, fixed)
	else
		sizeTop = Vector3.new(0.34, 0.24, span)
		posTop = Vector3.new(fixed, y + height, (a0 + a1) * 0.5)
	end
	BuildKit.box(parent, name .. "_Top", sizeTop, posTop, color, Enum.Material.Metal,
		math.max(25, hp or 40), name, 2, { canCollide = false, castShadow = false })
	made += 1
	-- tấm kính
	if glass then
		local sizeG, posG
		if axis == "X" then
			sizeG = Vector3.new(span, height - 0.5, 0.12)
			posG = Vector3.new((a0 + a1) * 0.5, y + height * 0.5, fixed)
		else
			sizeG = Vector3.new(0.12, height - 0.5, span)
			posG = Vector3.new(fixed, y + height * 0.5, (a0 + a1) * 0.5)
		end
		BuildKit.box(parent, name .. "_Glass", sizeG, posG, glass, Enum.Material.Glass,
			math.max(20, hp or 30), name, 2, { canCollide = false, castShadow = false, transparency = 0.55 })
		made += 1
	end
	return made
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CẦU THANG (dirX/dirZ ∈ {-1, 0, 1})
-- ══════════════════════════════════════════════════════════════════════════════
function BuildKit.stairs(
	parent: Instance,
	name: string,
	origin: Vector3,
	dirX: number, dirZ: number,
	steps: number,
	width: number,
	rise: number,
	run: number,
	color: Color3,
	hp: number?,
	group: string?
): number
	for i = 1, steps do
		local y = origin.Y + i * rise
		local off = (i - 0.5) * run
		local pos = Vector3.new(origin.X + dirX * off, y - rise * 0.5, origin.Z + dirZ * off)
		local size = if dirX ~= 0 then Vector3.new(run, rise, width) else Vector3.new(width, rise, run)
		BuildKit.box(parent, string.format("%s_%02d", name, i), size, pos, color,
			Enum.Material.Concrete, hp or 80, group or name, i)
	end
	return steps
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CÂY CỐI / ĐÈN / XE / BỒN HOA
-- ══════════════════════════════════════════════════════════════════════════════
function BuildKit.palm(parent: Instance, name: string, pos: Vector3, height: number, trunk: Color3, leaf: Color3, hp: number?): number
	local made = 0
	local seg = 5
	for i = 1, seg do
		local h = height / seg
		BuildKit.cyl(parent, string.format("%s_Trunk%d", name, i), Vector3.new(h, 0.9 - i * 0.06, 0.9 - i * 0.06),
			Vector3.new(pos.X, pos.Y + (i - 0.5) * h, pos.Z), trunk, Enum.Material.Wood, hp or 90, name, i,
			{ canCollide = false })
		made += 1
	end
	for k = 0, 5 do
		local ang = (k / 6) * math.pi * 2
		local cf = CFrame.new(pos.X + math.cos(ang) * 3.4, pos.Y + height + 0.6, pos.Z + math.sin(ang) * 3.4)
			* CFrame.Angles(0, -ang, math.rad(24))
		BuildKit.rbox(parent, string.format("%s_Leaf%d", name, k), Vector3.new(7.6, 0.22, 2.4), cf, leaf,
			Enum.Material.Grass, hp or 40, name, 3, { canCollide = false, castShadow = false })
		made += 1
	end
	return made
end

function BuildKit.planter(parent: Instance, name: string, pos: Vector3, w: number, d: number, h: number, stone: Color3, leaf: Color3, hp: number?): number
	local made = 0
	BuildKit.box(parent, name .. "_Box", Vector3.new(w, h, d), Vector3.new(pos.X, pos.Y + h * 0.5, pos.Z),
		stone, Enum.Material.Concrete, hp or 120, name, 1)
	made += 1
	BuildKit.box(parent, name .. "_Soil", Vector3.new(w - 0.7, 0.2, d - 0.7), Vector3.new(pos.X, pos.Y + h + 0.02, pos.Z),
		Color3.fromRGB(58, 42, 30), Enum.Material.Ground, hp or 60, name, 2, { canCollide = false })
	made += 1
	local n = math.max(2, math.floor(w / 2.6))
	for i = 1, n do
		local bx = pos.X - w * 0.5 + (i - 0.5) * (w / n)
		BuildKit.box(parent, string.format("%s_Bush%d", name, i), Vector3.new(1.9, 1.5, 1.5),
			Vector3.new(bx, pos.Y + h + 0.9, pos.Z), leaf, Enum.Material.Grass, hp or 30, name, 3,
			{ canCollide = false, castShadow = false, shape = Enum.PartType.Ball })
		made += 1
	end
	return made
end

function BuildKit.lampPost(parent: Instance, name: string, pos: Vector3, height: number, color: Color3, glow: Color3, hp: number?): number
	BuildKit.cyl(parent, name .. "_Base", Vector3.new(1.4, 1.9, 1.9), Vector3.new(pos.X, pos.Y + 0.7, pos.Z),
		color, Enum.Material.Metal, hp or 160, name, 1)
	BuildKit.cyl(parent, name .. "_Pole", Vector3.new(height, 0.55, 0.55), Vector3.new(pos.X, pos.Y + height * 0.5, pos.Z),
		color, Enum.Material.Metal, hp or 120, name, 2)
	BuildKit.box(parent, name .. "_Head", Vector3.new(2.4, 0.8, 2.4), Vector3.new(pos.X, pos.Y + height + 0.3, pos.Z),
		glow, Enum.Material.Neon, hp or 40, name, 3, { canCollide = false, castShadow = false })
	local light = Instance.new("PointLight")
	light.Brightness = 1.4
	light.Range = 34
	light.Color = glow
	light.Parent = parent:FindFirstChild(name .. "_Head") or parent
	return 3
end

--- Xe khối hộp (dùng cho bãi đỗ / trưng bày / xe cũ trong bãi phế liệu).
function BuildKit.car(parent: Instance, name: string, pos: Vector3, yaw: number, body: Color3, hp: number?, group: string?): number
	local g = group or name
	local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	local made = 0

	local function put(n: string, size: Vector3, off: Vector3, col: Color3, mat: Enum.Material, health: number, row: number)
		local world = cf * CFrame.new(off)
		BuildKit.rbox(parent, name .. "_" .. n, size, world, col, mat, health, g, row)
		made += 1
	end

	put("Body", Vector3.new(4.4, 2.0, 9.6), Vector3.new(0, 2.7, 0), body, Enum.Material.SmoothPlastic, hp or 220, 1)
	put("Hood", Vector3.new(4.2, 0.7, 3.0), Vector3.new(0, 3.9, -2.9), body, Enum.Material.SmoothPlastic, hp or 160, 2)
	put("Cabin", Vector3.new(4.0, 2.0, 4.4), Vector3.new(0, 4.5, 0.7), Color3.fromRGB(24, 28, 34), Enum.Material.Glass, hp or 120, 2)
	put("Roof", Vector3.new(4.1, 0.35, 4.2), Vector3.new(0, 5.6, 0.7), body, Enum.Material.SmoothPlastic, hp or 140, 3)
	local wheelIdx = 0
	for _, sx in ipairs({ -2.35, 2.35 }) do
		for _, sz in ipairs({ -2.9, 2.9 }) do
			wheelIdx += 1
			local wheelCf = cf * CFrame.new(Vector3.new(sx, 1.55, sz)) * CFrame.Angles(0, 0, math.rad(90))
			BuildKit.rbox(parent, string.format("%s_Wheel%d", name, wheelIdx), Vector3.new(1.1, 2.9, 2.9), wheelCf,
				Color3.fromRGB(22, 22, 24), Enum.Material.Rubber, hp or 90, g, 1,
				{ shape = Enum.PartType.Cylinder })
			made += 1
		end
	end
	put("LightL", Vector3.new(1.2, 0.55, 0.3), Vector3.new(-1.4, 3.0, -4.85), Color3.fromRGB(255, 246, 210), Enum.Material.Neon, 30, 2)
	put("LightR", Vector3.new(1.2, 0.55, 0.3), Vector3.new(1.4, 3.0, -4.85), Color3.fromRGB(255, 246, 210), Enum.Material.Neon, 30, 2)
	put("TailL", Vector3.new(1.1, 0.5, 0.3), Vector3.new(-1.5, 3.0, 4.85), Color3.fromRGB(230, 60, 50), Enum.Material.Neon, 30, 2)
	put("TailR", Vector3.new(1.1, 0.5, 0.3), Vector3.new(1.5, 3.0, 4.85), Color3.fromRGB(230, 60, 50), Enum.Material.Neon, 30, 2)
	return made
end

-- ══════════════════════════════════════════════════════════════════════════════
-- QUÉT HIỆU NĂNG SAU KHI DỰNG (bắt buộc)
-- ══════════════════════════════════════════════════════════════════════════════
function BuildKit.perf(root: Instance): { [string]: number }
	local stat = { parts = 0, smallCollide = 0, shadow = 0, gui = 0 }
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			stat.parts += 1
			local p = d :: BasePart
			p.CanTouch = false
			local md = math.max(p.Size.X, p.Size.Y, p.Size.Z)
			if md < SMALL_MAX and p.CanCollide then
				-- gờ nhỏ không được chặn xe/người, nhưng vẫn phải giữ va chạm cho khối
				-- kết cấu thật (tường mỏng 1,2–1,5 stud vẫn cho phép)
				if md < 1.2 then
					p.CanCollide = false
					stat.smallCollide += 1
				end
			end
			if p.Transparency > 0 or p.Material == Enum.Material.Neon or p.Material == Enum.Material.Glass or md < 2.6 then
				p.CastShadow = false
				stat.shadow += 1
			end
		elseif d:IsA("SurfaceGui") then
			local g = d :: SurfaceGui
			g.MaxDistance = 340
			if g.PixelsPerStud > 32 then
				g.PixelsPerStud = 32
			end
			for _, t in ipairs(g:GetDescendants()) do
				if t:IsA("TextLabel") then
					(t :: TextLabel).TextScaled = false
				end
			end
		end
	end
	return stat
end

return BuildKit
