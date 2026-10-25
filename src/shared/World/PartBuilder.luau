--!strict

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
}

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
	w.Parent = spec.parent
	return w
end

function PartBuilder.groundPlaque(
	parent: Instance,
	pos: Vector3,
	codeText: string,
	subText: string,
	accentColor: Color3?
): Part
	local plate = PartBuilder.part({
		name = "PlotMarker_" .. codeText,
		parent = parent,
		pos = pos,
		size = Vector3.new(38, 0.08, 13),
		color = Color3.fromRGB(28, 34, 44),
		material = Enum.Material.Metal,
		canCollide = false,
		castShadow = false,
	})

	local sgui = Instance.new("SurfaceGui")
	sgui.Face = Enum.NormalId.Top
	sgui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sgui.PixelsPerStud = 28
	sgui.LightInfluence = 0.2
	sgui.Parent = plate

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.94, 0.52)
	title.Position = UDim2.fromScale(0.03, 0.08)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = accentColor or Color3.fromRGB(245, 202, 56)
	title.Text = codeText
	title.Parent = sgui

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.fromScale(0.94, 0.34)
	sub.Position = UDim2.fromScale(0.03, 0.58)
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(215, 224, 236)
	sub.Text = subText
	sub.Parent = sgui

	return plate
end

return PartBuilder
