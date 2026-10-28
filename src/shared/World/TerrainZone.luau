--!nonstrict
--[[
	TerrainZone.luau — KHU ĐỊA HÌNH THỬ NGHIỆM (1:1, 1 stud = 1/3,33 m theo WorldGrid)
	Khu 1024×1024 stud (~307×307 m) đặt xa thành phố, tại ORIGIN.
	- Đồi nhấp nhô bằng noise nhiều tầng (fbm).
	- Sông uốn lượn theo trục Z, đáy cát, có nước (Water).
	- Đường nhựa chạy E–W qua tâm (z=0), cao ROAD_Y, có cầu bê tông bắc qua sông.
	- Rừng: cây thân + tán, mật độ theo noise, không mọc trên đường/sông.
	- Đá lộ ra ở dốc đứng và đỉnh cao.
	Công thức heightAt() là bản gốc. tools/terrain_sim/preview.py là bản Python để
	xuất ảnh bản đồ; khi sửa công thức phải sửa cả hai.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local TerrainZone = {}

TerrainZone.ORIGIN = Vector3.new(4000, 0, 0)
TerrainZone.HALF = 512 -- nửa cạnh khu (stud)
TerrainZone.VOXEL = 4 -- Roblox Terrain voxel = 4 stud
TerrainZone.WATER = 3 -- mực nước sông
TerrainZone.ROAD_Y = 12 -- cao độ mặt đường / cầu
TerrainZone.Y_MIN = -16
TerrainZone.Y_MAX = 160
TerrainZone.RIVER_BED = -2
TerrainZone.SPAWN_LOCAL = Vector3.new(-420, 0, 0)

local FOLDER_NAME = "TerrainZone"

local function clamp01(v: number): number
	if v < 0 then
		return 0
	elseif v > 1 then
		return 1
	end
	return v
end

local function smooth(t: number): number
	local u = clamp01(t)
	return u * u * (3 - 2 * u)
end

local function hash(ix: number, iz: number): number
	local v = math.sin(ix * 127.1 + iz * 311.7) * 43758.5453
	return v - math.floor(v)
end

local function vnoise(x: number, z: number): number
	local ix, iz = math.floor(x), math.floor(z)
	local fx, fz = x - ix, z - iz
	local ux = fx * fx * (3 - 2 * fx)
	local uz = fz * fz * (3 - 2 * fz)
	local a = hash(ix, iz)
	local b = hash(ix + 1, iz)
	local c = hash(ix, iz + 1)
	local d = hash(ix + 1, iz + 1)
	local ab = a + (b - a) * ux
	local cd = c + (d - c) * ux
	return ab + (cd - ab) * uz
end

local function fbm(x: number, z: number): number
	local s, amp, f, norm = 0, 0.5, 1, 0
	for _ = 1, 4 do
		s += amp * vnoise(x * f, z * f)
		norm += amp
		amp *= 0.5
		f *= 2
	end
	return s / norm
end

-- Toạ độ LOCAL (x,z trong [-HALF, HALF]); y là cao độ stud.
local function heightAt(x: number, z: number): number
	local base = 18 + 110 * fbm(x / 400, z / 400) + 6 * (vnoise(x / 60, z / 60) - 0.5)
	local rx = 80 * math.sin(z / 140)
	local d = math.abs(x - rx)
	-- độ ảnh hưởng của đường (1 trên đường, mờ dần ra hai bên)
	local ro = 1 - smooth((math.abs(z) - 7) / 9)
	local target = base + (TerrainZone.ROAD_Y - base) * ro
	if d < 18 then
		return TerrainZone.RIVER_BED
	elseif d < 32 then
		return TerrainZone.RIVER_BED + (target - TerrainZone.RIVER_BED) * smooth((d - 18) / 14)
	end
	return target
end

TerrainZone.heightAt = heightAt

local function isRoad(x: number, z: number): boolean
	local rx = 80 * math.sin(z / 140)
	return math.abs(z) < 7 and math.abs(x - rx) >= 32
end

local function isRiverZone(x: number, z: number): boolean
	local rx = 80 * math.sin(z / 140)
	return math.abs(x - rx) < 32
end

TerrainZone.isRoad = isRoad
TerrainZone.isRiverZone = isRiverZone

local function forestMask(x: number, z: number): number
	return fbm(x / 140, z / 140)
end

-- Chọn vật liệu cho một voxel, dựa trên cao độ mặt và độ dốc.
local function materialFor(x: number, z: number, y: number, top: number, slope: number): Enum.Material
	if y >= top then
		return Enum.Material.Water
	end
	local depth = top - y
	if isRoad(x, z) and depth < 4 then
		return Enum.Material.Asphalt
	end
	if top <= TerrainZone.WATER + 2 then
		return Enum.Material.Sand
	end
	if slope > 1.1 or top > 80 then
		return Enum.Material.Rock
	end
	if depth < 1.5 * 4 then
		return Enum.Material.Grass
	end
	if depth < 6 * 4 then
		return Enum.Material.Ground
	end
	return Enum.Material.Rock
end

local function buildVoxels(folder: Folder)
	local V = TerrainZone.VOXEL
	local half = TerrainZone.HALF
	local n = (half * 2) // V -- số cột voxel mỗi cạnh (256)
	local sy = (TerrainZone.Y_MAX - TerrainZone.Y_MIN) // V
	local origin = TerrainZone.ORIGIN

	-- cache cao độ tại tâm mỗi cột voxel
	local H = {}
	for i = 1, n do
		H[i] = {}
		local x = -half + (i - 0.5) * V
		for k = 1, n do
			local z = -half + (k - 0.5) * V
			H[i][k] = heightAt(x, z)
		end
	end

	local terrain = Workspace.Terrain
	local CHUNK = 64
	for i0 = 1, n, CHUNK do
		for k0 = 1, n, CHUNK do
			local cx = CHUNK
			local cz = CHUNK
			local minX = origin.X - half + (i0 - 1) * V
			local minZ = origin.Z - half + (k0 - 1) * V
			local region = Region3.new(
				Vector3.new(minX, TerrainZone.Y_MIN + origin.Y, minZ),
				Vector3.new(minX + cx * V, TerrainZone.Y_MAX + origin.Y, minZ + cz * V)
			)
			local mats = {}
			local occ = {}
			for xi = 1, cx do
				mats[xi] = {}
				occ[xi] = {}
				for yj = 1, sy do
					mats[xi][yj] = {}
					occ[xi][yj] = {}
				end
			end
			for xi = 1, cx do
				local gi = i0 + xi - 1
				local x = -half + (gi - 0.5) * V
				for zk = 1, cz do
					local gk = k0 + zk - 1
					local z = -half + (gk - 0.5) * V
					local top = H[gi][gk]
					local slope = math.abs(H[math.min(n, gi + 1)][gk] - H[math.max(1, gi - 1)][gk]) / (2 * V)
					for yj = 1, sy do
						local yc = TerrainZone.Y_MIN + (yj - 0.5) * V
						local m, o
						if yc < top then
							m = materialFor(x, z, yc, top, slope)
							o = 1
						elseif yc < TerrainZone.WATER then
							m = Enum.Material.Water
							o = 1
						else
							m = Enum.Material.Air
							o = 0
						end
						mats[xi][yj][zk] = m
						occ[xi][yj][zk] = o
					end
				end
			end
			terrain:WriteVoxels(region, V, mats, occ)
		end
	end
end

local function buildRoadAndBridge(folder: Folder)
	local origin = TerrainZone.ORIGIN
	local half = TerrainZone.HALF
	-- Vạch tim đường (trang trí, không va chạm)
	for x = -half + 40, half - 40, 24 do
		local dash = Instance.new("Part")
		dash.Name = "LaneDash"
		dash.Anchored = true
		dash.CanCollide = false
		dash.CanQuery = false
		dash.CanTouch = false
		dash.Material = Enum.Material.SmoothPlastic
		dash.Color = Color3.fromRGB(240, 190, 44)
		dash.Size = Vector3.new(10, 0.2, 0.6)
		local rx = 80 * math.sin(0 / 140)
		if math.abs(x - rx) >= 34 then
			dash.CFrame = CFrame.new(origin + Vector3.new(x, TerrainZone.ROAD_Y + 0.15, 0))
			dash.Parent = folder
		else
			dash:Destroy()
		end
	end

	-- Cầu bê tông bắc qua sông tại z=0 (rx(0)=0)
	local deck = Instance.new("Part")
	deck.Name = "BridgeDeck"
	deck.Anchored = true
	deck.Material = Enum.Material.Concrete
	deck.Color = Color3.fromRGB(150, 150, 150)
	deck.Size = Vector3.new(64, 2, 14)
	deck.CFrame = CFrame.new(origin + Vector3.new(0, TerrainZone.ROAD_Y - 1, 0))
	deck.Parent = folder
	for _, sx in ipairs({ -26, 26 }) do
		local pier = Instance.new("Part")
		pier.Name = "BridgePier"
		pier.Anchored = true
		pier.Material = Enum.Material.Concrete
		pier.Color = Color3.fromRGB(128, 128, 128)
		local h = TerrainZone.ROAD_Y - 1 - TerrainZone.RIVER_BED
		pier.Size = Vector3.new(4, h, 10)
		pier.CFrame = CFrame.new(origin + Vector3.new(sx, TerrainZone.RIVER_BED + h / 2, 0))
		pier.Parent = folder
	end
end

local function buildForest(folder: Folder)
	local origin = TerrainZone.ORIGIN
	local half = TerrainZone.HALF
	local forest = Instance.new("Folder")
	forest.Name = "Forest"
	forest.Parent = folder
	local SPACING = 20
	local count = 0
	for gx = -half + 10, half - 10, SPACING do
		for gz = -half + 10, half - 10, SPACING do
			local jx = (hash(gx, gz) - 0.5) * 12
			local jz = (hash(gz + 9.1, gx + 3.7) - 0.5) * 12
			local x, z = gx + jx, gz + jz
			local h = heightAt(x, z)
			if forestMask(x, z) > 0.56 and h > 8 and h < 90 and math.abs(z) > 16 and not isRiverZone(x, z) then
				if hash(x * 0.37, z * 0.91) > 0.35 then
					local trunkH = 14 + 6 * hash(x, z + 5)
					local trunk = Instance.new("Part")
					trunk.Name = "Trunk"
					trunk.Shape = Enum.PartType.Cylinder
					trunk.Anchored = true
					trunk.Material = Enum.Material.Wood
					trunk.Color = Color3.fromRGB(96, 68, 44)
					trunk.Size = Vector3.new(trunkH, 1.8, 1.8)
					trunk.CFrame = CFrame.new(origin + Vector3.new(x, h + trunkH / 2, z)) * CFrame.Angles(0, 0, math.pi / 2)
					trunk.Parent = forest
					local crown = Instance.new("Part")
					crown.Name = "Crown"
					crown.Shape = Enum.PartType.Ball
					crown.Anchored = true
					crown.Material = Enum.Material.Grass
					crown.Color = Color3.fromRGB(46, 110 + math.floor(40 * hash(z, x)), 52)
					local r = 5 + 2 * hash(z + 1, x + 1)
					crown.Size = Vector3.new(r * 2, r * 2, r * 2)
					crown.CFrame = CFrame.new(origin + Vector3.new(x, h + trunkH + r * 0.4, z))
					crown.Parent = forest
					count += 1
				end
			end
		end
	end
	forest:SetAttribute("TreeCount", count)
end

-- Xoá khu cũ rồi dựng lại (an toàn khi chạy lại).
function TerrainZone.build(): Folder
	local old = Workspace:FindFirstChild(FOLDER_NAME)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = Workspace

	buildVoxels(folder)
	buildRoadAndBridge(folder)
	buildForest(folder)

	-- Điểm đứng: trên đường, phía tây cầu
	local spawn = TerrainZone.ORIGIN + TerrainZone.SPAWN_LOCAL
	local top = heightAt(TerrainZone.SPAWN_LOCAL.X, TerrainZone.SPAWN_LOCAL.Z)
	folder:SetAttribute("SpawnX", spawn.X)
	folder:SetAttribute("SpawnY", top + 6)
	folder:SetAttribute("SpawnZ", spawn.Z)
	return folder
end

-- Người chơi vào game được đưa về điểm đứng của khu địa hình.
function TerrainZone.bindSpawn()
	local function place(char: Model)
		local folder = Workspace:FindFirstChild(FOLDER_NAME)
		if not folder then
			return
		end
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if not hrp then
			return
		end
		local x = folder:GetAttribute("SpawnX")
		local y = folder:GetAttribute("SpawnY")
		local z = folder:GetAttribute("SpawnZ")
		if typeof(x) == "number" and typeof(y) == "number" and typeof(z) == "number" then
			char:PivotTo(CFrame.new(x, y, z))
		end
	end
	local function hook(player: Player)
		player.CharacterAdded:Connect(place)
		if player.Character then
			place(player.Character)
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
end

return TerrainZone
