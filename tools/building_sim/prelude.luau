-- =============================================================================
-- Mock Roblox API (đủ dùng) để CHẠY THẬT một module công trình ngoài Studio
--   • Vector3 / CFrame CÓ MA TRẬN XOAY THẬT (không xấp xỉ) -> đo AABB chính xác
--   • Instance có cây cha–con thật, GetDescendants() đệ quy
--   • Mọi BasePart được tạo ra đều ghi vào bảng PARTS để QA đếm / đo
-- =============================================================================

local W = {}
WARNS = W
function warn(...)
	local t = {}
	for i = 1, select("#", ...) do table.insert(t, tostring(select(i, ...))) end
	table.insert(W, table.concat(t, " "))
end

-- ── Vector3 ──────────────────────────────────────────────────────────────────
local VMT = {}
local function mk(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, VMT)
end
VMT.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
	elseif k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		if m == 0 then return mk(0, 0, 0) end
		return mk(t.X / m, t.Y / m, t.Z / m)
	elseif k == "Lerp" then
		return function(a, b, u)
			return mk(a.X + (b.X - a.X) * u, a.Y + (b.Y - a.Y) * u, a.Z + (b.Z - a.Z) * u)
		end
	elseif k == "Dot" then
		return function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
	elseif k == "Cross" then
		return function(a, b)
			return mk(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
		end
	end
	return nil
end
VMT.__add = function(a, b) return mk(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
VMT.__sub = function(a, b) return mk(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
VMT.__mul = function(a, b)
	if type(b) == "number" then return mk(a.X * b, a.Y * b, a.Z * b) end
	if type(a) == "number" then return mk(b.X * a, b.Y * a, b.Z * a) end
	return mk(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
VMT.__div = function(a, b)
	if type(b) == "number" then return mk(a.X / b, a.Y / b, a.Z / b) end
	return mk(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
VMT.__unm = function(a) return mk(-a.X, -a.Y, -a.Z) end
VMT.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
VMT.__tostring = function(a) return string.format("(%.2f, %.2f, %.2f)", a.X, a.Y, a.Z) end
Vector3 = { new = mk, zero = mk(0, 0, 0), one = mk(1, 1, 1), xAxis = mk(1, 0, 0), yAxis = mk(0, 1, 0), zAxis = mk(0, 0, 1) }

-- ── CFrame (vị trí + ma trận xoay 3×3 THẬT) ──────────────────────────────────
local CMT = {}
local function cfNew(P, R)
	return setmetatable({ P = P, R = R }, CMT)
end
local IDENT = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function mul3(a, b)
	local o = {}
	for i = 0, 2 do
		for j = 0, 2 do
			o[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return o
end
local function apply3(R, v)
	return mk(
		R[1] * v.X + R[2] * v.Y + R[3] * v.Z,
		R[4] * v.X + R[5] * v.Y + R[6] * v.Z,
		R[7] * v.X + R[8] * v.Y + R[9] * v.Z
	)
end
CMT.__index = function(t, k)
	if k == "Position" or k == "p" then return t.P end
	if k == "X" then return t.P.X end
	if k == "Y" then return t.P.Y end
	if k == "Z" then return t.P.Z end
	if k == "Rotation" then return t.R end
	if k == "LookVector" then return mk(-t.R[3], -t.R[6], -t.R[9]) end
	if k == "RightVector" then return mk(t.R[1], t.R[4], t.R[7]) end
	if k == "UpVector" then return mk(t.R[2], t.R[5], t.R[8]) end
	if k == "Inverse" then
		local Rt = { t.R[1], t.R[4], t.R[7], t.R[2], t.R[5], t.R[8], t.R[3], t.R[6], t.R[9] }
		local p = apply3(Rt, t.P)
		return cfNew(mk(-p.X, -p.Y, -p.Z), Rt)
	end
	if k == "PointToWorldSpace" then
		return function(self, v) return self.P + apply3(self.R, v) end
	elseif k == "PointToObjectSpace" then
		return function(self, v) return apply3(self.Inverse.R, v - self.P) end
	elseif k == "VectorToWorldSpace" then
		return function(self, v) return apply3(self.R, v) end
	elseif k == "VectorToObjectSpace" then
		return function(self, v) return apply3(self.Inverse.R, v) end
	elseif k == "ToWorldSpace" then
		return function(self, cf) return self * cf end
	elseif k == "Lerp" then
		return function(self, b, u)
			return cfNew(self.P + (b.P - self.P) * u, self.R)
		end
	elseif k == "ToObjectSpace" then
		return function(a, b)
			local inv = a.Inverse
			return cfNew(inv.P + apply3(inv.R, b.P), mul3(inv.R, b.R))
		end
	end
	return nil
end
CMT.__mul = function(a, b)
	if getmetatable(b) == CMT then
		return cfNew(a.P + apply3(a.R, b.P), mul3(a.R, b.R))
	end
	return a.P + apply3(a.R, b)
end
CMT.__add = function(a, b) return cfNew(a.P + b, a.R) end
CMT.__sub = function(a, b) return cfNew(a.P - b, a.R) end
CMT.__tostring = function(a) return "CFrame" .. tostring(a.P) end

CFrame = {}
CFrame.__index = CMT.__index
CFrame.new = function(x, y, z)
	if type(x) == "table" then return cfNew(mk(x.X, x.Y, x.Z), IDENT) end
	return cfNew(mk(x, y, z), IDENT)
end
CFrame.Angles = function(rx, ry, rz)
	local cx, sx = math.cos(rx), math.sin(rx)
	local cy, sy = math.cos(ry), math.sin(ry)
	local cz, sz = math.cos(rz), math.sin(rz)
	local Rx = { 1, 0, 0, 0, cx, -sx, 0, sx, cx }
	local Ry = { cy, 0, sy, 0, 1, 0, -sy, 0, cy }
	local Rz = { cz, -sz, 0, sz, cz, 0, 0, 0, 1 }
	return cfNew(mk(0, 0, 0), mul3(mul3(Rx, Ry), Rz))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
CFrame.fromEulerAnglesYXZ = CFrame.Angles
CFrame.identity = cfNew(mk(0, 0, 0), IDENT)
CFrame.lookAt = function(from, to)
	local dir = (to - from).Unit
	local yaw = math.atan2(-dir.X, -dir.Z)
	return cfNew(mk(from.X, from.Y, from.Z), CFrame.Angles(0, yaw, 0).R)
end

-- ── kiểu dữ liệu phụ ─────────────────────────────────────────────────────────
Color3 = {
	new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0 } end,
	fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end,
}
Color3.__index = Color3
UDim2 = { new = function() return {} end, fromOffset = function() return {} end, fromScale = function() return {} end, fromScaleOffset = function() return {} end }
UDim = { new = function() return {} end }
NumberSequence = { new = function() return {} end }
ColorSequence = { new = function() return {} end }
ColorSequenceKeypoint = { new = function() return {} end }
NumberSequenceKeypoint = { new = function() return {} end }
Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }
Rect = { new = function() return {} end }
Enum = setmetatable({}, {
	__index = function(_, k)
		return setmetatable({}, { __index = function(_, k2) return k .. "." .. k2 end })
	end,
})
RaycastParams = { new = function() return { FilterDescendantsInstances = {} } end }

-- ── Instance ─────────────────────────────────────────────────────────────────
PARTS = {}       -- mọi BasePart được tạo (thứ tự tạo)
NODES = {}       -- mọi Instance được tạo

-- cây kế thừa lớp tối thiểu (IsA("BasePart") phải đúng, nếu không mọi pass tối ưu sẽ bỏ qua part)
local ISA = {
	Part = { BasePart = true, PVInstance = true, Instance = true },
	WedgePart = { BasePart = true, PVInstance = true, Instance = true },
	MeshPart = { BasePart = true, PVInstance = true, Instance = true },
	TrussPart = { BasePart = true, PVInstance = true, Instance = true },
	Model = { PVInstance = true, Instance = true },
	Folder = { Instance = true },
	SurfaceGui = { LayerCollector = true, GuiBase2d = true, Instance = true },
	TextLabel = { GuiObject = true, GuiBase2d = true, Instance = true },
	Frame = { GuiObject = true, GuiBase2d = true, Instance = true },
	BillboardGui = { LayerCollector = true, GuiBase2d = true, Instance = true },
	PointLight = { Light = true, Instance = true },
	SpotLight = { Light = true, Instance = true },
	Highlight = { Instance = true },
}

local INST = {}
local function inst(class, name)
	local o = { ClassName = class, Name = name or class, Children = {}, Parent = nil, Attributes = {} }
	setmetatable(o, INST)
	table.insert(NODES, o)
	if class == "Part" or class == "WedgePart" or class == "MeshPart" or class == "TrussPart" then
		table.insert(PARTS, o)
	end
	return o
end

INST.__index = function(t, k)
	local v = rawget(t, k)
	if v ~= nil then return v end
	if k == "Position" then
		local cf = rawget(t, "CFrame")
		if cf then return cf.P end
		return rawget(t, "__pos") or mk(0, 0, 0)
	elseif k == "CFrame" then
		local p = rawget(t, "__pos")
		if p then return cfNew(p, IDENT) end
		return cfNew(mk(0, 0, 0), IDENT)
	elseif k == "GetDescendants" then
		return function(self)
			local out = {}
			local function rec(node)
				for _, c in ipairs(node.Children) do
					table.insert(out, c)
					rec(c)
				end
			end
			rec(self)
			return out
		end
	elseif k == "GetChildren" then
		return function(self) return self.Children end
	elseif k == "FindFirstChild" then
		return function(self, n, recursive)
			for _, c in ipairs(self.Children) do if c.Name == n then return c end end
			if recursive then
				for _, c in ipairs(self:GetDescendants()) do if c.Name == n then return c end end
			end
			return nil
		end
	elseif k == "WaitForChild" then
		return function(self, n) return self:FindFirstChild(n) end
	elseif k == "FindFirstChildOfClass" then
		return function(self, c)
			for _, o in ipairs(self.Children) do if o.ClassName == c then return o end end
			return nil
		end
	elseif k == "FindFirstChildWhichIsA" then
		return function(self, c)
			for _, o in ipairs(self.Children) do if o:IsA(c) then return o end end
			return nil
		end
	elseif k == "GetAttribute" then
		return function(self, n) return self.Attributes[n] end
	elseif k == "SetAttribute" then
		return function(self, n, v) self.Attributes[n] = v end
	elseif k == "GetPivot" then
		return function(self)
			local cf = rawget(self, "CFrame")
			return cf or cfNew(mk(0, 0, 0), IDENT)
		end
	elseif k == "PivotTo" then
		return function(self, cf)
			if self.SetCFrame then self:SetCFrame(cf) end
			for _, c in ipairs(self.Children) do
				if c.PivotTo then c:PivotTo(cf) end
			end
		end
	elseif k == "Destroy" then
		return function(self) self.Parent = nil end
	elseif k == "Clone" then
		return function(self) return inst(self.ClassName, self.Name) end
	elseif k == "IsA" then
		return function(self, c)
			if self.ClassName == c then return true end
			local chain = ISA[self.ClassName]
			return (chain and chain[c]) or false
		end
	elseif k == "SetCFrame" then
		return function(self, cf)
			rawset(self, "CFrame", cf)
			rawset(self, "__pos", cf.P)
		end
	end
	-- thuộc tính hay gặp với giá trị mặc định
	if k == "Size" then return mk(1, 1, 1) end
	if k == "Transparency" or k == "Reflectance" then return 0 end
	if k == "CanCollide" or k == "CanQuery" or k == "CanTouch" or k == "Anchored" then return true end
	if k == "CastShadow" then return true end
	if k == "Material" then return "SmoothPlastic" end
	if k == "Shape" then return "Block" end
	if k == "Color" then return { R = 0.64, G = 0.64, B = 0.64 } end
	if k == "PixelsPerStud" then return 50 end
	if k == "MaxDistance" then return 1000 end
	if k == "TextScaled" then return false end
	if k == "Value" then return 0 end
	return nil
end

INST.__newindex = function(t, k, v)
	if k == "Parent" then
		rawset(t, k, v)
		if v and rawget(v, "Children") then table.insert(v.Children, t) end
		return
	end
	if k == "Position" then
		rawset(t, "__pos", v)
		rawset(t, "CFrame", cfNew(v, IDENT))
		return
	end
	if k == "CFrame" then
		rawset(t, "CFrame", v)
		rawset(t, "__pos", v.P)
		return
	end
	rawset(t, k, v)
end

Instance = { new = function(class, parent)
	local o = inst(class)
	if parent then o.Parent = parent end
	return o
end }

-- ── service ──────────────────────────────────────────────────────────────────
local RS = inst("ReplicatedStorage", "ReplicatedStorage")
local Shared = inst("Folder", "Shared"); Shared.Parent = RS
local World = inst("Folder", "World"); World.Parent = Shared
script = inst("ModuleScript", "PlotModule")
local SERVICES = { ReplicatedStorage = RS, Workspace = inst("Workspace", "Workspace"), Players = inst("Players"), ServerStorage = inst("ServerStorage") }
game = {
	GetService = function(_, n) return SERVICES[n] or inst(n) end,
	Workspace = SERVICES.Workspace,
}
task = { wait = function() end, spawn = function(f) f() end, delay = function() end }
