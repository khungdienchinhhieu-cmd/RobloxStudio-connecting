-- ===== Mock Roblox API tối thiểu để CHẠY THẬT NPCManager.luau ngoài Studio =====
local REAL_WARN = {}
WARNS = REAL_WARN

local function pushWarn(msg)
	table.insert(REAL_WARN, tostring(msg))
end
function note(s)
	table.insert(REAL_WARN, "NOTE " .. tostring(s))
end

function warn(...)
	local parts = {}
	for i = 1, select("#", ...) do
		table.insert(parts, tostring(select(i, ...)))
	end
	pushWarn(table.concat(parts, " "))
end

-- Vector3 (một metatable duy nhất, đủ toán tử)
local vmt = {}
local function mk(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vmt)
end
vmt.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X ^ 2 + t.Y ^ 2 + t.Z ^ 2)
	elseif k == "Unit" then
		local m = math.sqrt(t.X ^ 2 + t.Y ^ 2 + t.Z ^ 2)
		if m == 0 then return mk(0, 0, 0) end
		return mk(t.X / m, t.Y / m, t.Z / m)
	elseif k == "Lerp" then
		return function(a, b, alpha)
			return mk(a.X + (b.X - a.X) * alpha, a.Y + (b.Y - a.Y) * alpha, a.Z + (b.Z - a.Z) * alpha)
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
vmt.__add = function(a, b) return mk(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vmt.__sub = function(a, b) return mk(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vmt.__mul = function(a, b)
	if type(b) == "number" then return mk(a.X * b, a.Y * b, a.Z * b) end
	if type(a) == "number" then return mk(b.X * a, b.Y * a, b.Z * a) end
	return mk(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
vmt.__div = function(a, b)
	if type(b) == "number" then return mk(a.X / b, a.Y / b, a.Z / b) end
	return mk(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
vmt.__unm = function(a) return mk(-a.X, -a.Y, -a.Z) end
vmt.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
vmt.__tostring = function(a) return string.format("(%.1f, %.1f, %.1f)", a.X, a.Y, a.Z) end
Vector3 = { new = mk, zero = mk(0, 0, 0) }

-- CFrame
local CF = {}
CF.__index = CF
CF.__mul = function(a, b)
	if getmetatable(b) == CF then
		return setmetatable({ P = a.P + b.P, L = b.L }, CF)
	end
	return setmetatable({ P = a.P + b, L = a.L }, CF)
end
CFrame = {}
CFrame.new = function(x, y, z)
	local p = (type(x) == "table" and x) or mk(x, y, z)
	return setmetatable({ P = p, L = mk(0, 0, -1) }, CF)
end
CFrame.lookAt = function(a, b) return CFrame.new(a) end
CFrame.Angles = function() return setmetatable({ P = mk(0,0,0), L = mk(0,0,-1) }, CF) end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
CF.__index = function(t, k)
	if k == "Position" or k == "p" then return t.P end
	if k == "LookVector" then return t.L end
	if k == "X" then return t.P.X end
	if k == "Y" then return t.P.Y end
	if k == "Z" then return t.P.Z end
	return nil
end
-- CFrame * Vector3 / CFrame * CFrame đã có ở CF.__mul phía trên.

Color3 = { new = function(r, g, b) return { R = r, G = g, B = b } end, fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end }
UDim2 = { new = function() return {} end, fromOffset = function() return {} end, fromScale = function() return {} end }
UDim = { new = function() return {} end }
Enum = setmetatable({}, { __index = function(_, k)
	return setmetatable({}, { __index = function(_, k2) return k .. "." .. k2 end })
end })
RaycastParams = { new = function() return { FilterDescendantsInstances = {} } end }

-- Instance
local INST = {}
INST.__index = INST
local function inst(class, name)
	return setmetatable({
		ClassName = class, Name = name or class, Children = {}, Parent = nil,
		Attributes = {}, Value = 0,
		Position = mk(0, 0, 0), Size = mk(1, 1, 1),
		AssemblyLinearVelocity = mk(0, 0, 0), AssemblyAngularVelocity = mk(0, 0, 0),
	}, INST)
end
local ISA = {
	Part = { BasePart = true, Instance = true },
	MeshPart = { BasePart = true, Instance = true },
	WedgePart = { BasePart = true, Instance = true },
	Model = { PVInstance = true, Instance = true },
	Humanoid = { Instance = true },
	Folder = { Instance = true },
	ModuleScript = { LuaSourceContainer = true, Instance = true },
	BillboardGui = { LayerCollector = true, Instance = true },
	TextLabel = { Instance = true },
	WeldConstraint = { Instance = true },
	RemoteEvent = { Instance = true },
}
function INST:IsA(c)
	if self.ClassName == c then return true end
	local m = ISA[self.ClassName]
	return (m and m[c]) or false
end
INST.__newindex = function(t, k, v)
	if k == "Parent" then
		rawset(t, k, v)
		if v and v.Children then
			table.insert(v.Children, t)
		end
		return
	end
	rawset(t, k, v)
end
function INST:FindFirstChild(n) for _, c in ipairs(self.Children) do if c.Name == n then return c end end return nil end
function INST:WaitForChild(n) return self:FindFirstChild(n) end
function INST:FindFirstChildOfClass(c)
	for _, child in ipairs(self.Children) do
		if child.ClassName == c then return child end
	end
	return nil
end
function INST:FindFirstChildWhichIsA(c)
	for _, child in ipairs(self.Children) do
		if child:IsA(c) then return child end
	end
	return nil
end
function INST:GetChildren() return self.Children end
function INST:GetDescendants() return {} end
function INST:SetAttribute(k, v) self.Attributes[k] = v end
function INST:GetAttribute(k) return self.Attributes[k] end
function INST:GetPivot() return CFrame.new(0, 0, 0) end
function INST:PivotTo() end
function INST:Destroy() self.Parent = nil end
function INST:Clone() return inst(self.ClassName, self.Name) end
function INST:GetPlayers() return PLAYER_LIST end
Instance = { new = function(class, parent)
	local i = inst(class)
	i.Parent = parent
	return i
end }

PLAYER_LIST = {}
local Players = inst("Players")
Players.GetPlayers = function() return PLAYER_LIST end
Players.PlayerAdded = inst("Event")
Players.PlayerAdded.Connect = function() return { Disconnect = function() end } end

local RS = inst("ReplicatedStorage")
local WS = inst("Workspace")
WS.CurrentCamera = nil
WS.Raycast = function() return nil end   -- cố tình trả nil -> kiểm tra nhánh cao độ hình học
local Debris = inst("Debris")
Debris.AddItem = function() end

local SERVICES = { Players = Players, ReplicatedStorage = RS, Workspace = WS, Debris = Debris }
game = { GetService = function(_, n) return SERVICES[n] or inst(n) end }

-- Cây Shared/WorldGrid
local Shared = Instance.new("Folder", RS); Shared.Name = "Shared"
local World = Instance.new("Folder", Shared); World.Name = "World"
local Vehicles = Instance.new("Folder", Shared); Vehicles.Name = "Vehicles"

-- ===== task: coroutine thật + đồng hồ mô phỏng =====
SIM = { t = 0 }
local realClock = os.clock
os.clock = function() return SIM.t end

local threads = {}     -- { co = coroutine, wakeAt = number }
local scheduled = {}   -- { at = number, f = function }

function __countThreads()
	local alive = 0
	for _, th in ipairs(threads) do
		if coroutine.status(th.co) ~= "dead" then alive += 1 end
	end
	return alive
end

task = {
	spawn = function(f, ...)
		local co = coroutine.create(f)
		table.insert(threads, { co = co, wakeAt = SIM.t })
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			table.insert(REAL_WARN, "TASK ERROR: " .. tostring(err))
		end
	end,
	wait = function(t)
		coroutine.yield(t or 0)
		return t or 0
	end,
	delay = function(t, f)
		table.insert(scheduled, { at = SIM.t + (t or 0), f = f })
	end,
	defer = function(f)
		table.insert(scheduled, { at = SIM.t, f = f })
	end,
	cancel = function() end,
}

--- Chạy đồng hồ mô phỏng thêm `seconds` giây, bước `step`.
function pump(seconds, step)
	step = step or 0.2
	local target = SIM.t + (seconds or 1)
	local guard = 0
	while SIM.t < target and guard < 200000 do
		guard += 1
		SIM.t += step
		-- việc hẹn giờ
		local due = {}
		for i = #scheduled, 1, -1 do
			if scheduled[i].at <= SIM.t then
				table.insert(due, scheduled[i].f)
				table.remove(scheduled, i)
			end
		end
		if __physicsStep then __physicsStep(step) end
		for _, f in ipairs(due) do
			local ok, err = pcall(f)
			if not ok then table.insert(REAL_WARN, "DELAY ERROR: " .. tostring(err)) end
		end
		-- coroutine
		for i = #threads, 1, -1 do
			local th = threads[i]
			if coroutine.status(th.co) == "dead" then
				table.remove(threads, i)
			elseif th.wakeAt <= SIM.t then
				local ok, waitFor = coroutine.resume(th.co)
				if not ok then
					table.insert(REAL_WARN, "TASK ERROR: " .. tostring(waitFor))
					table.remove(threads, i)
				else
					th.wakeAt = SIM.t + (tonumber(waitFor) or 0)
				end
			end
		end
	end
	return SIM.t
end

