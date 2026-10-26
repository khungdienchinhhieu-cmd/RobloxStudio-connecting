--!strict
--[[
	CityCuller.luau  (Sync v31 — sửa lỗi "nhà mất tiêu rồi hiện lại")
	================================================================================
	Cách cũ (v23) có 2 lỗi gốc:
	  1. Mỗi ô đất là một Folder rộng ~184×144 stud nhưng chỉ có MỘT điểm đại diện, là
	     trung bình của 24 part đầu tiên (không phải tâm ô). Điểm đó ra khỏi khung hình hoặc
	     xa hơn 900 stud thì CẢ Ô bị cất → nhà biến mất, rồi hiện lại khi quay về.
	  2. Kiểm tra khung hình chỉ dùng một điểm, nên ô đang nằm ở rìa màn hình vẫn bị cất.

	Cách mới:
	  • Mỗi ô có HỘP BAO thật (tính một lần khi nạp). Khoảng cách tính tới CẠNH hộp.
	  • Khung hình: 8 góc + tâm hộp; chỉ cần 1 điểm nhìn thấy là coi như trong khung hình.
	  • Cất phải "ngoài tầm" liên tiếp 2 nhịp (0,5 s) mới cất. Hiện thì hiện ngay.
	  • Logic quyết định nằm trong CullMath.luau (đã kiểm thử bằng tools/cull_sim).

	Vẫn giữ:
	  • Đường đi, mặt đất, vỉa hè, biển KHÔNG bao giờ bị cất (chỉ cull DistrictModules).
	  • "Cất" = đổi Parent sang thư mục cache do client tạo (không replicate, không Destroy).
	  • Chạy 4 Hz.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CullMath = require(script.Parent:WaitForChild("CullMath"))

local CityCuller = {}

local NEAR_RADIUS = 380
local FAR_RADIUS = 900
local BEHIND_RADIUS = 460
local HYSTERESIS = 40
local HIDE_TICKS = 2 -- số nhịp "ngoài tầm" liên tiếp trước khi cất
local TICK = 0.25

type Chunk = {
	instance: Instance,
	minX: number,
	minY: number,
	minZ: number,
	maxX: number,
	maxY: number,
	maxZ: number,
	visible: boolean,
	offTicks: number,
	baseParent: Instance,
}

local chunks: { Chunk } = {}
local cacheFolder: Folder? = nil
local started = false
local stats = { culled = 0, kept = 0, total = 0 }

local function ensureCache(): Folder
	if cacheFolder and cacheFolder.Parent then
		return cacheFolder
	end
	-- Client tạo ⇒ chỉ tồn tại trên máy người chơi này, không replicate, không lộ ra server.
	local folder = Instance.new("Folder")
	folder.Name = "__CityCullCache"
	folder.Parent = ReplicatedStorage
	cacheFolder = folder
	return folder
end

--- Hộp bao thật của toàn bộ BasePart con (tính một lần).
local function boundsOf(inst: Instance): (number, number, number, number, number, number, number)
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	local n = 0
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("BasePart") then
			local part = d :: BasePart
			local cf = part.CFrame
			local h = part.Size * 0.5
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local p = cf * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
						minX = math.min(minX, p.X)
						minY = math.min(minY, p.Y)
						minZ = math.min(minZ, p.Z)
						maxX = math.max(maxX, p.X)
						maxY = math.max(maxY, p.Y)
						maxZ = math.max(maxZ, p.Z)
					end
				end
			end
			n += 1
		end
	end
	if n == 0 then
		return 0, 0, 0, 0, 0, 0, 0
	end
	return minX, minY, minZ, maxX, maxY, maxZ, n
end

local function collectChunks()
	chunks = {}
	local root = Workspace:FindFirstChild("LosSantos")
	if not root then
		return
	end
	local modules = root:FindFirstChild("DistrictModules")
	if not modules then
		return
	end

	for _, child in ipairs(modules:GetChildren()) do
		if child:IsA("Model") or child:IsA("Folder") then
			local minX, minY, minZ, maxX, maxY, maxZ, n = boundsOf(child)
			if n > 0 then
				table.insert(chunks, {
					instance = child,
					minX = minX,
					minY = minY,
					minZ = minZ,
					maxX = maxX,
					maxY = maxY,
					maxZ = maxZ,
					visible = child.Parent ~= nil and child.Parent.Name ~= "__CityCullCache",
					offTicks = 0,
					baseParent = modules,
				})
			end
		end
	end

	stats.total = #chunks
	print(string.format("[CityCuller] Theo dõi %d khối công trình (hộp bao thật, cất theo khung hình + khoảng cách)", #chunks))
end

local function show(chunk: Chunk)
	if chunk.visible then
		return
	end
	chunk.instance.Parent = chunk.baseParent
	chunk.visible = true
end

local function hide(chunk: Chunk)
	if not chunk.visible then
		return
	end
	chunk.instance.Parent = ensureCache()
	chunk.visible = false
end

--- Có góc/tâm nào của hộp bao nằm trong khung hình không.
local function anyPointOnScreen(camera: Camera, chunk: Chunk): boolean
	local cx = (chunk.minX + chunk.maxX) * 0.5
	local cy = (chunk.minY + chunk.maxY) * 0.5
	local cz = (chunk.minZ + chunk.maxZ) * 0.5
	local points = CullMath.corners(chunk.minX, chunk.minY, chunk.minZ, chunk.maxX, chunk.maxY, chunk.maxZ)
	table.insert(points, { cx, cy, cz })
	for _, p in ipairs(points) do
		local _, onScreen = camera:WorldToViewportPoint(Vector3.new(p[1], p[2], p[3]))
		if onScreen then
			return true
		end
	end
	return false
end

local function step()
	local camera = Workspace.CurrentCamera
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local subject: Vector3
	if camera then
		subject = camera.CFrame.Position
	elseif character then
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end
		subject = hrp.Position
	else
		return
	end

	local culled, kept = 0, 0
	for _, chunk in ipairs(chunks) do
		local dist = CullMath.distToBoxXZ(subject.X, subject.Z, chunk.minX, chunk.minZ, chunk.maxX, chunk.maxZ)

		local onScreen = false
		if camera and dist > BEHIND_RADIUS and dist < FAR_RADIUS + HYSTERESIS then
			onScreen = anyPointOnScreen(camera, chunk)
		end

		local keep = CullMath.decide(dist, onScreen, chunk.visible, NEAR_RADIUS, FAR_RADIUS, BEHIND_RADIUS, HYSTERESIS)
		local hideNow, off = CullMath.hideDebounce(keep, chunk.offTicks, HIDE_TICKS)
		chunk.offTicks = off

		if keep then
			show(chunk)
			kept += 1
		elseif hideNow then
			hide(chunk)
			culled += 1
		else
			kept += 1 -- đang chờ đủ nhịp, vẫn hiện
		end
	end

	stats.culled = culled
	stats.kept = kept
end

function CityCuller.getStats()
	return {
		total = stats.total,
		kept = stats.kept,
		culled = stats.culled,
		nearRadius = NEAR_RADIUS,
		farRadius = FAR_RADIUS,
	}
end

function CityCuller.mount()
	if started then
		return CityCuller
	end
	started = true

	task.spawn(function()
		for _ = 1, 40 do
			local root = Workspace:FindFirstChild("LosSantos")
			if root and root:FindFirstChild("DistrictModules") then
				local mods = root:FindFirstChild("DistrictModules") :: Instance
				if #mods:GetChildren() > 0 then
					break
				end
			end
			task.wait(0.25)
		end
		collectChunks()

		while true do
			step()
			if #chunks == 0 then
				collectChunks()
			end
			task.wait(TICK)
		end
	end)

	return CityCuller
end

return CityCuller
