--!strict
--[[
	PartBuilder.luau (Modular Destructible Voxel Engine)
	Bộ công cụ dựng hình chuẩn hóa cho toàn bộ thế giới GTA V Los Santos:
	- Mọi khối tường, dải phân cách, bồn đá, lan can, cọc chắn và công trình về sau đều tạo từ
	  các khối vật lý rời có gắn Attribute:
	    + Destructible (boolean)
	    + MaxIntegrity / Integrity (number)
	    + FractureGroup (string)
	    + StructuralRow (number: tầng kết cấu từ dưới lên để tính sập dây chuyền)
]]

local PartBuilder = {}

export type PartSpec = {
	name: string?,
	parent: Instance,
	size: Vector3,
	pos: Vector3?,
	cframe: CFrame?,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	reflectance: number?,
	canCollide: boolean?,
	castShadow: boolean?,
	shape: Enum.PartType?,
	destructible: boolean?,
	integrity: number?,
	fractureGroup: string?,
	structuralRow: number?,
}

export type MasonryWallSpec = {
	name: string,
	parent: Instance,
	axis: "X" | "Z", -- Tường chạy dọc trục X (từ min -> max tại fixedCoord Z) hoặc trục Z
	fixedCoord: number,
	minCoord: number,
	maxCoord: number,
	baseY: number,
	thickness: number,
	courses: number,
	courseHeight: number,
	blockLength: number,
	mortarGap: number?,
	baseColor: Color3,
	material: Enum.Material?,
	colorJitter: number?,
	integrity: number?,
	fractureGroup: string,
	addCoping: boolean?,
	copingColor: Color3?,
}

export type StaircaseSpec = {
	name: string,
	parent: Instance,
	origin: Vector3, -- Tâm chân bậc đầu tiên (ở cao độ thấp)
	dir: Vector3, -- Hướng bước lên: Vector3.new(0,0,-1), (0,0,1), (1,0,0), (-1,0,0)
	width: number,
	steps: number,
	totalRise: number,
	totalRun: number,
	color: Color3,
	cheekColor: Color3?,
	material: Enum.Material?,
	fractureGroup: string?,
}

local function applyDestructionTags(
	inst: BasePart,
	destructible: boolean?,
	integrity: number?,
	group: string?,
	row: number?
)
	local isDest = if destructible ~= nil then destructible else false
	inst:SetAttribute("Destructible", isDest)
	if isDest then
		local hp = integrity or 100
		inst:SetAttribute("MaxPartHealth", hp)
		inst:SetAttribute("PartHealth", hp)
		inst:SetAttribute("MaxIntegrity", hp)
		inst:SetAttribute("Integrity", hp)
		inst:SetAttribute("FractureGroup", group or "WorldProp")
		inst:SetAttribute("StructuralRow", row or 1)
	end
end

local function tintColor(base: Color3, seedA: number, seedB: number, jitter: number): Color3
	local h = ((seedA * 73856093 + seedB * 19349663) % 29) - 14
	local delta = (h / 14.0) * (jitter / 255.0)
	return Color3.new(
		math.clamp(base.R + delta, 0, 1),
		math.clamp(base.G + delta, 0, 1),
		math.clamp(base.B + delta * 0.85, 0, 1)
	)
end

function PartBuilder.part(spec: PartSpec): Part
	local p = Instance.new("Part")
	p.Name = spec.name or "Part"
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if spec.shape then
		p.Shape = spec.shape
	end
	p.Size = spec.size
	if spec.cframe then
		p.CFrame = spec.cframe
	elseif spec.pos then
		p.Position = spec.pos
	end
	p.Color = spec.color
	p.Material = spec.material or Enum.Material.SmoothPlastic
	p.Transparency = spec.transparency or 0
	p.Reflectance = spec.reflectance or 0
	if spec.canCollide ~= nil then
		p.CanCollide = spec.canCollide
	end
	if spec.castShadow ~= nil then
		p.CastShadow = spec.castShadow
	end
	applyDestructionTags(p, spec.destructible, spec.integrity, spec.fractureGroup, spec.structuralRow)
	p.Parent = spec.parent
	return p
end

function PartBuilder.wedge(spec: PartSpec): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = spec.name or "Wedge"
	w.Anchored = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Size = spec.size
	if spec.cframe then
		w.CFrame = spec.cframe
	elseif spec.pos then
		w.Position = spec.pos
	end
	w.Color = spec.color
	w.Material = spec.material or Enum.Material.SmoothPlastic
	w.Transparency = spec.transparency or 0
	if spec.canCollide ~= nil then
		w.CanCollide = spec.canCollide
	end
	if spec.castShadow ~= nil then
		w.CastShadow = spec.castShadow
	end
	applyDestructionTags(w, spec.destructible, spec.integrity, spec.fractureGroup, spec.structuralRow)
	w.Parent = spec.parent
	return w
end

-- Dựng mảng tường đá / gạch / bê tông ghép so le từng viên vật lý độc lập (Running-Bond Destructible Masonry)
function PartBuilder.masonryWall(spec: MasonryWallSpec): Folder
	local wallFolder = Instance.new("Folder")
	wallFolder.Name = spec.name
	wallFolder.Parent = spec.parent

	local gap = spec.mortarGap or 0.08
	local mat = spec.material or Enum.Material.Concrete
	local jitter = spec.colorJitter or 7
	local hp = spec.integrity or 130
	local totalLen = spec.maxCoord - spec.minCoord
	if totalLen <= 0.2 then
		return wallFolder
	end

	for row = 1, spec.courses do
		local cy = spec.baseY + (row - 0.5) * spec.courseHeight
		local actualH = math.max(0.15, spec.courseHeight - gap * 0.6)
		local stagger = if (row % 2 == 0) then (spec.blockLength * 0.5) else 0

		local cursor = spec.minCoord
		local colIdx = 1
		while cursor < spec.maxCoord - 0.05 do
			local targetLen = if colIdx == 1 and stagger > 0 then stagger else spec.blockLength
			local segEnd = math.min(spec.maxCoord, cursor + targetLen)
			local segLen = segEnd - cursor
			if segLen < 0.8 and cursor > spec.minCoord then
				break
			end
			local drawLen = math.max(0.4, segLen - gap)
			local mid = (cursor + segEnd) * 0.5

			local pos = if spec.axis == "X"
				then Vector3.new(mid, cy, spec.fixedCoord)
				else Vector3.new(spec.fixedCoord, cy, mid)
			local sz = if spec.axis == "X"
				then Vector3.new(drawLen, actualH, spec.thickness)
				else Vector3.new(spec.thickness, actualH, drawLen)

			PartBuilder.part({
				name = string.format("Block_R%d_C%d", row, colIdx),
				parent = wallFolder,
				pos = pos,
				size = sz,
				color = tintColor(spec.baseColor, row + math.floor(spec.fixedCoord), colIdx, jitter),
				material = mat,
				destructible = true,
				integrity = hp,
				fractureGroup = spec.fractureGroup,
				structuralRow = row,
			})

			cursor = segEnd
			colIdx += 1
		end
	end

	if spec.addCoping then
		local topY = spec.baseY + spec.courses * spec.courseHeight + 0.16
		local capW = spec.thickness + 0.36
		local capStep = spec.blockLength * 1.25
		local cur = spec.minCoord
		local idx = 1
		while cur < spec.maxCoord - 0.05 do
			local nxt = math.min(spec.maxCoord, cur + capStep)
			local ln = math.max(0.5, (nxt - cur) - gap)
			local mid = (cur + nxt) * 0.5
			local pos = if spec.axis == "X"
				then Vector3.new(mid, topY, spec.fixedCoord)
				else Vector3.new(spec.fixedCoord, topY, mid)
			local sz = if spec.axis == "X"
				then Vector3.new(ln, 0.32, capW)
				else Vector3.new(capW, 0.32, ln)

			PartBuilder.part({
				name = "CopingStone_" .. tostring(idx),
				parent = wallFolder,
				pos = pos,
				size = sz,
				color = spec.copingColor or Color3.fromRGB(204, 200, 192),
				material = Enum.Material.Sandstone,
				destructible = true,
				integrity = math.floor(hp * 0.85),
				fractureGroup = spec.fractureGroup,
				structuralRow = spec.courses + 1,
			})
			cur = nxt
			idx += 1
		end
	end

	return wallFolder
end

-- Dựng dải phân cách bê tông K-Rail (California Jersey Barrier) từng đốt rời có thể húc văng
function PartBuilder.jerseyBarrierRun(spec: {
	name: string,
	parent: Instance,
	axis: "X" | "Z",
	fixedCoord: number,
	minCoord: number,
	maxCoord: number,
	baseY: number,
	segmentLength: number?,
	fractureGroup: string,
}): Folder
	local folder = Instance.new("Folder")
	folder.Name = spec.name
	folder.Parent = spec.parent

	local segLen = spec.segmentLength or 13.5
	local gap = 0.45
	local cur = spec.minCoord
	local idx = 1

	while cur + 2.0 <= spec.maxCoord do
		local nxt = math.min(spec.maxCoord, cur + segLen)
		local drawL = (nxt - cur) - gap
		local mid = (cur + nxt) * 0.5
		local unitGroup = string.format("%s_Seg%d", spec.fractureGroup, idx)

		local basePos = if spec.axis == "X"
			then Vector3.new(mid, spec.baseY + 0.45, spec.fixedCoord)
			else Vector3.new(spec.fixedCoord, spec.baseY + 0.45, mid)
		local baseSz = if spec.axis == "X"
			then Vector3.new(drawL, 0.9, 2.2)
			else Vector3.new(2.2, 0.9, drawL)

		local topPos = if spec.axis == "X"
			then Vector3.new(mid, spec.baseY + 1.45, spec.fixedCoord)
			else Vector3.new(spec.fixedCoord, spec.baseY + 1.45, mid)
		local topSz = if spec.axis == "X"
			then Vector3.new(drawL, 1.15, 1.1)
			else Vector3.new(1.1, 1.15, drawL)

		local col = tintColor(Color3.fromRGB(168, 172, 178), idx, 7, 5)
		PartBuilder.part({
			name = "KRailBase_" .. tostring(idx),
			parent = folder,
			pos = basePos,
			size = baseSz,
			color = col,
			material = Enum.Material.Concrete,
			destructible = true,
			integrity = 240,
			fractureGroup = unitGroup,
			structuralRow = 1,
		})
		PartBuilder.part({
			name = "KRailSpine_" .. tostring(idx),
			parent = folder,
			pos = topPos,
			size = topSz,
			color = col,
			material = Enum.Material.Concrete,
			destructible = true,
			integrity = 210,
			fractureGroup = unitGroup,
			structuralRow = 2,
		})

		-- Miếng phản quang vàng trên đỉnh mỗi đốt dải phân cách cao tốc
		local reflPos = if spec.axis == "X"
			then Vector3.new(mid, spec.baseY + 2.08, spec.fixedCoord)
			else Vector3.new(spec.fixedCoord, spec.baseY + 2.08, mid)
		PartBuilder.part({
			name = "KRailReflector_" .. tostring(idx),
			parent = folder,
			pos = reflPos,
			size = Vector3.new(0.45, 0.14, 0.45),
			color = Color3.fromRGB(245, 192, 42),
			material = Enum.Material.Neon,
			canCollide = false,
			castShadow = false,
			destructible = true,
			integrity = 40,
			fractureGroup = unitGroup,
			structuralRow = 3,
		})

		cur = nxt
		idx += 1
	end

	return folder
end

-- Dựng hàng cọc thép chống đâm xe trên vỉa hè / quảng trường (húc bay từng cọc như GTA V!)
function PartBuilder.bollardLine(spec: {
	name: string,
	parent: Instance,
	startPos: Vector3,
	endPos: Vector3,
	count: number,
	fractureGroup: string,
}): Folder
	local folder = Instance.new("Folder")
	folder.Name = spec.name
	folder.Parent = spec.parent

	for i = 0, math.max(0, spec.count - 1) do
		local alpha = if spec.count <= 1 then 0.5 else (i / (spec.count - 1))
		local p = spec.startPos + (spec.endPos - spec.startPos) * alpha
		local grp = string.format("%s_Bollard%d", spec.fractureGroup, i + 1)

		PartBuilder.part({
			name = "BollardPost_" .. tostring(i + 1),
			parent = folder,
			pos = Vector3.new(p.X, p.Y + 1.35, p.Z),
			size = Vector3.new(0.75, 2.7, 0.75),
			color = Color3.fromRGB(42, 47, 56),
			material = Enum.Material.Metal,
			destructible = true,
			integrity = 75,
			fractureGroup = grp,
			structuralRow = 1,
		})
		PartBuilder.part({
			name = "BollardRing_" .. tostring(i + 1),
			parent = folder,
			pos = Vector3.new(p.X, p.Y + 2.35, p.Z),
			size = Vector3.new(0.82, 0.22, 0.82),
			color = Color3.fromRGB(245, 198, 46),
			material = Enum.Material.SmoothPlastic,
			canCollide = false,
			castShadow = false,
			destructible = true,
			integrity = 50,
			fractureGroup = grp,
			structuralRow = 2,
		})
	end

	return folder
end

-- Dựng bậc tam cấp / cầu thang đi bộ thật (mỗi bậc là 1 khối độc lập)
function PartBuilder.staircase(spec: StaircaseSpec): Folder
	local folder = Instance.new("Folder")
	folder.Name = spec.name
	folder.Parent = spec.parent

	local riser = spec.totalRise / spec.steps
	local tread = spec.totalRun / spec.steps
	local mat = spec.material or Enum.Material.Sandstone
	local isZ = math.abs(spec.dir.Z) > 0.5

	for s = 1, spec.steps do
		local stepH = s * riser
		local offset = (s - 0.5) * tread
		local pos = Vector3.new(
			spec.origin.X + spec.dir.X * offset,
			spec.origin.Y + stepH * 0.5,
			spec.origin.Z + spec.dir.Z * offset
		)
		local sz = if isZ
			then Vector3.new(spec.width, stepH, tread + 0.15)
			else Vector3.new(tread + 0.15, stepH, spec.width)

		PartBuilder.part({
			name = "Step_" .. tostring(s),
			parent = folder,
			pos = pos,
			size = sz,
			color = tintColor(spec.color, s, 3, 4),
			material = mat,
			destructible = false,
		})
	end

	-- 2 thành lan can đá thấp hai bên cầu thang (Destructible = true)
	local midOffset = spec.totalRun * 0.5
	for _, side in ipairs({ -1, 1 }) do
		local cheekPos = if isZ
			then Vector3.new(spec.origin.X + side * (spec.width * 0.5 + 0.65), spec.origin.Y + spec.totalRise * 0.55, spec.origin.Z + spec.dir.Z * midOffset)
			else Vector3.new(spec.origin.X + spec.dir.X * midOffset, spec.origin.Y + spec.totalRise * 0.55, spec.origin.Z + side * (spec.width * 0.5 + 0.65))
		local cheekSz = if isZ
			then Vector3.new(1.3, spec.totalRise + 1.1, spec.totalRun + 0.8)
			else Vector3.new(spec.totalRun + 0.8, spec.totalRise + 1.1, 1.3)

		PartBuilder.part({
			name = "StairCheekWall_" .. tostring(side),
			parent = folder,
			pos = cheekPos,
			size = cheekSz,
			color = spec.cheekColor or Color3.fromRGB(168, 164, 156),
			material = Enum.Material.Concrete,
			destructible = true,
			integrity = 160,
			fractureGroup = (spec.fractureGroup or spec.name) .. "_Cheek" .. tostring(side),
			structuralRow = 1,
		})
	end

	return folder
end

-- Bia mốc quy hoạch nhỏ gọn ở lối vào ô đất (thay cho tấm bảng đen to thô giữa đất)
function PartBuilder.surveyMonument(
	parent: Instance,
	pos: Vector3,
	codeText: string,
	subText: string,
	accentColor: Color3?
): Folder
	local f = Instance.new("Folder")
	f.Name = "SurveyMonument_" .. codeText
	f.Parent = parent

	PartBuilder.part({
		name = "MonumentBase",
		parent = f,
		pos = Vector3.new(pos.X, pos.Y + 0.45, pos.Z),
		size = Vector3.new(11.5, 0.9, 2.2),
		color = Color3.fromRGB(156, 160, 168),
		material = Enum.Material.Concrete,
		destructible = true,
		integrity = 140,
		fractureGroup = "Monument_" .. codeText,
		structuralRow = 1,
	})

	local signBoard = PartBuilder.part({
		name = "MonumentBoard",
		parent = f,
		pos = Vector3.new(pos.X, pos.Y + 2.1, pos.Z),
		size = Vector3.new(10.6, 2.5, 0.9),
		color = Color3.fromRGB(24, 30, 40),
		material = Enum.Material.Metal,
		destructible = true,
		integrity = 100,
		fractureGroup = "Monument_" .. codeText,
		structuralRow = 2,
	})

	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sgui = Instance.new("SurfaceGui")
		sgui.Face = face
		sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sgui.PixelsPerStud = 36
		sgui.LightInfluence = 0.15
		sgui.Parent = signBoard

		local topStripe = Instance.new("Frame")
		topStripe.Size = UDim2.new(1, 0, 0.1, 0)
		topStripe.BackgroundColor3 = accentColor or Color3.fromRGB(245, 198, 46)
		topStripe.BorderSizePixel = 0
		topStripe.Parent = sgui

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.fromScale(0.92, 0.44)
		title.Position = UDim2.fromScale(0.04, 0.14)
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true
		title.TextColor3 = accentColor or Color3.fromRGB(245, 198, 46)
		title.Text = codeText
		title.Parent = sgui

		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.Size = UDim2.fromScale(0.92, 0.3)
		sub.Position = UDim2.fromScale(0.04, 0.6)
		sub.Font = Enum.Font.GothamBold
		sub.TextScaled = true
		sub.TextColor3 = Color3.fromRGB(220, 228, 238)
		sub.Text = subText
		sub.Parent = sgui
	end

	return f
end

return PartBuilder
