--!nocheck
--[[
	rebuild_world_action.luau
	TÁC VỤ DỰNG THÀNH PHỐ THÔNG MINH (INCREMENTAL) — chạy sau mỗi lần Sync.

	VẤN ĐỀ CŨ: mỗi lần publish (dù chỉ sửa 1 dòng UI) đều XOÁ SẠCH rồi dựng lại
	toàn bộ ~14.000 part của thành phố -> Studio đơ 20–40 giây mỗi lần.

	CÁCH LÀM MỚI:
	  • Băm mã nguồn từng file trong ReplicatedStorage.Shared (lấy mẫu mỗi 3 byte).
	  • So với dấu vân tay đã lưu trong StringValue "SyncHashes" trên model LosSantos.
	  • Không đổi gì            -> BỎ QUA toàn bộ (≈0,1 giây).
	  • Chỉ 1 module công trình -> chỉ dựng lại module đó (DistrictRegistry.buildOne).
	  • Nền thành phố đổi      -> dựng lại nền + toàn bộ công trình (như cũ).
	  • Xe đổi                 -> chỉ dựng lại dàn xe.
	  • Nếu dựng tăng dần lỗi   -> TỰ ĐỘNG lùi về dựng lại toàn bộ (an toàn tuyệt đối).

	Ép dựng lại toàn bộ thủ công: chạy trong Command Bar
		local sv = workspace.LosSantos:FindFirstChild("SyncHashes")
		if sv then sv:Destroy() end
	rồi chạy lại lệnh Sync.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t0 = os.clock()

local shared = ReplicatedStorage:FindFirstChild("Shared")
if not shared then
	warn("[Sync] KHÔNG tìm thấy ReplicatedStorage.Shared — chưa apply bundle? Hãy chạy lại lệnh Command Bar.")
	return
end

-- ══════════════════════════════════════════════════════════════════════════
-- 1. BĂM MÃ NGUỒN (deterministic, lấy mẫu mỗi 3 byte cho nhanh)
-- ══════════════════════════════════════════════════════════════════════════
-- Băm TOÀN BỘ byte (KHÔNG lấy mẫu): lấy mẫu từng bỏ sót thay đổi nhỏ trong file ngắn.
-- 500 KB mã nguồn băm hết chỉ tốn ~0,05 giây — rẻ hơn rất nhiều so với dựng lại 30 giây.
local function hashSource(s: string): number
	local h = 2166136261
	h = (h * 31 + #s) % 2147483647
	for i = 1, #s do
		h = (h * 31 + string.byte(s, i)) % 2147483647
	end
	return h
end

local function collectHashes(container: Instance): { [string]: number }
	local map: { [string]: number } = {}
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("ModuleScript") then
			local full = d:GetFullName()
			local key = string.gsub(full, "^ReplicatedStorage%.Shared%.", "")
			local src = d.Source
			if type(src) == "string" then
				map[key] = hashSource(src)
			end
		end
	end
	return map
end

local hashes = collectHashes(shared)

-- Danh sách file tạo nên NỀN thành phố (đổi 1 trong số này -> phải dựng lại nền)
local FOUNDATION_KEYS = { "World.CityFoundation", "World.WorldGrid", "World.PartBuilder" }

local moduleNames: { string } = {}
for key in pairs(hashes) do
	if string.sub(key, 1, 14) == "World.Modules." then
		table.insert(moduleNames, string.sub(key, 15))
	end
end
table.sort(moduleNames)

-- ══════════════════════════════════════════════════════════════════════════
-- 2. ĐỌC / GHI DẤU VÂN TAY
-- ══════════════════════════════════════════════════════════════════════════
local function readHashes(container: Instance?): { [string]: number }
	if not container then
		return {}
	end
	local sv = container:FindFirstChild("SyncHashes")
	if not sv or not sv:IsA("StringValue") or sv.Value == "" then
		return {}
	end
	local okDec, decoded = pcall(function()
		return HttpService:JSONDecode(sv.Value)
	end)
	if okDec and type(decoded) == "table" then
		return decoded
	end
	return {}
end

local function writeHashes(container: Instance, map: { [string]: number })
	local sv = container:FindFirstChild("SyncHashes")
	if not sv or not sv:IsA("StringValue") then
		sv = Instance.new("StringValue")
		sv.Name = "SyncHashes"
		sv.Parent = container
	end
	sv.Value = HttpService:JSONEncode(map)
end

-- ══════════════════════════════════════════════════════════════════════════
-- 3. SO SÁNH
-- ══════════════════════════════════════════════════════════════════════════
local root = workspace:FindFirstChild("LosSantos")
local prev = readHashes(root)

local foundationChanged = (root == nil) or (root:FindFirstChild("Phase1_CityFoundation") == nil)
for _, key in ipairs(FOUNDATION_KEYS) do
	if prev[key] ~= hashes[key] then
		foundationChanged = true
	end
end

local container = if root then root:FindFirstChild("DistrictModules") else nil
local changedModules: { string } = {}
for _, name in ipairs(moduleNames) do
	local built = container and container:FindFirstChild(name)
	if prev["World.Modules." .. name] ~= hashes["World.Modules." .. name] or not built then
		table.insert(changedModules, name)
	end
end

local vehiclesChanged = prev["Vehicles.VehicleBuilder"] ~= hashes["Vehicles.VehicleBuilder"]

-- ══════════════════════════════════════════════════════════════════════════
-- 4. KHÔNG CÓ GÌ ĐỔI -> THOÁT NGAY (nhanh nhất)
-- ══════════════════════════════════════════════════════════════════════════
if root and not foundationChanged and #changedModules == 0 and not vehiclesChanged then
	writeHashes(root, hashes)
	print(string.format(
		"[Sync] ⏩ Không có thay đổi hình học — BỎ QUA dựng lại (%.2f giây). Ép dựng lại: xoá StringValue 'SyncHashes' trong workspace.LosSantos",
		os.clock() - t0
	))
	return
end

-- ══════════════════════════════════════════════════════════════════════════
-- 5. DỰNG (nhân bản Shared để phá cache require() của chế độ Edit)
-- ══════════════════════════════════════════════════════════════════════════
local freshShared = shared:Clone()
freshShared.Name = "_TempBuildSharedMultiAgent"
freshShared.Parent = ReplicatedStorage

local ok, err = pcall(function()
	local WorldRoot = freshShared:WaitForChild("World")
	local CityFoundation = require(WorldRoot:WaitForChild("CityFoundation"))
	local DistrictRegistry = require(WorldRoot:WaitForChild("DistrictRegistry"))
	local PerfOptimizer = require(WorldRoot:WaitForChild("PerfOptimizer"))
	local VehicleBuilder = require(freshShared:WaitForChild("Vehicles"):WaitForChild("VehicleBuilder"))

	local tBuild = os.clock()

	-- 5.1. NỀN THÀNH PHỐ
	if foundationChanged then
		root = CityFoundation.build(true)
	else
		root = CityFoundation.build(false) -- đã có nền -> trả về ngay
	end
	local tFoundation = os.clock()

	-- 5.2. CÔNG TRÌNH
	local rebuilt = 0
	local failed: { string } = {}
	local didFull = foundationChanged

	if foundationChanged then
		local summary = DistrictRegistry.buildAll(root)
		rebuilt = summary.loadedCount
		local dcNew = root:FindFirstChild("DistrictModules")
		for _, name in ipairs(moduleNames) do
			if not (dcNew and dcNew:FindFirstChild(name)) then
				table.insert(failed, name)
			end
		end
	else
		local incrementalOk = true
		for _, name in ipairs(changedModules) do
			local okOne, errOne = DistrictRegistry.buildOne(root, name)
			if not okOne then
				incrementalOk = false
				warn("[Sync] Dựng tăng dần lỗi ở module " .. name .. ": " .. tostring(errOne))
				break
			end
			rebuilt += 1
			local dcNow = root:FindFirstChild("DistrictModules")
			local built = dcNow and dcNow:FindFirstChild(name)
			if built then
				PerfOptimizer.optimize(built)
			end
		end

		-- VAN AN TOÀN: dựng tăng dần lỗi -> lùi về dựng lại toàn bộ
		if not incrementalOk then
			warn("[Sync] ⚠ Lùi về DỰNG LẠI TOÀN BỘ để không bị thiếu công trình.")
			local summary = DistrictRegistry.buildAll(root)
			rebuilt = summary.loadedCount
			didFull = true
		end
	end
	local tModules = os.clock()

	-- 5.3. XE
	if foundationChanged or vehiclesChanged or didFull then
		pcall(function()
			VehicleBuilder.spawnDefaultFleet(root)
		end)
	end

	-- 5.4. TỐI ƯU HIỆU NĂNG (quét cả cây khi phải dựng lại nền)
	local report = nil
	if didFull then
		report = PerfOptimizer.optimize(root)
	end
	local tOptimize = os.clock()

	-- 5.5. LƯU DẤU VÂN TAY
	writeHashes(root, hashes)
	pcall(function()
		root:SetAttribute("LastSyncAt", os.date("%H:%M:%S %d/%m/%Y"))
	end)

	-- 5.6. BÁO CÁO
	local districtCount = 0
	local dc = root:FindFirstChild("DistrictModules")
	if dc then
		districtCount = #dc:GetChildren()
	end

	if didFull then
		print(string.format(
			"[Sync] 🏗 DỰNG LẠI TOÀN BỘ — %d part | %d module OK | %d lỗi | va chạm %d | đổ bóng %d | SurfaceGui %d | DistrictModules: %d",
			report and report.totalParts or 0,
			rebuilt,
			#failed,
			report and report.collidableAfter or 0,
			report and report.shadowCastersAfter or 0,
			report and report.surfaceGuis or 0,
			districtCount
		))
	else
		print(string.format(
			"[Sync] 🧱 DỰNG TĂNG DẦN — %d/%d module đổi: %s | lỗi: %d | DistrictModules: %d",
			rebuilt,
			#moduleNames,
			#changedModules > 0 and table.concat(changedModules, ", ") or "(không có)",
			#failed,
			districtCount
		))
	end

	print(string.format(
		"[Sync] ⏱ Nền %.2fs · Công trình %.2fs · Tối ưu %.2fs · TỔNG %.2fs",
		tFoundation - tBuild,
		tModules - tFoundation,
		tOptimize - tModules,
		os.clock() - t0
	))

	if #failed > 0 then
		warn("[Sync] CẢNH BÁO: " .. #failed .. " module KHÔNG dựng được: " .. table.concat(failed, ", "))
	end

	print("[Sync] Module đã nạp: " .. table.concat(moduleNames, ", "))

	if not workspace.StreamingEnabled then
		warn("[Hiệu năng] HÃY BẬT: chọn Workspace > Properties > StreamingEnabled = true (StreamingTargetRadius = 1024). Giảm ~78% part phải nạp.")
	end
end)

freshShared:Destroy()

if not ok then
	warn("[Los Santos Multi-Agent Build Error]", err)
end
