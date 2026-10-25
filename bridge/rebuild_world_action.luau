local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")

if not shared then
	warn("[Sync] KHÔNG tìm thấy ReplicatedStorage.Shared — chưa apply bundle? Hãy chạy lại lệnh Command Bar.")
	return
end

-- Nhân bản tạm thời Shared để phá bộ nhớ đệm require() của Roblox Studio Edit Mode
local freshShared = shared:Clone()
freshShared.Name = "_TempBuildSharedMultiAgent"
freshShared.Parent = ReplicatedStorage

local ok, err = pcall(function()
	local WorldRoot = freshShared:WaitForChild("World")
	local CityFoundation = require(WorldRoot:WaitForChild("CityFoundation"))
	local DistrictRegistry = require(WorldRoot:WaitForChild("DistrictRegistry"))
	local PerfOptimizer = require(WorldRoot:WaitForChild("PerfOptimizer"))
	local VehicleBuilder = require(freshShared:WaitForChild("Vehicles"):WaitForChild("VehicleBuilder"))

	-- 1) Dựng nền thành phố (đường, vỉa hè, ô móng)
	local root = CityFoundation.build(true)

	-- 2) Dựng toàn bộ công trình từ các module (bán kính tự động)
	local summary = DistrictRegistry.buildAll(root)

	-- 3) Xe mặc định
	VehicleBuilder.spawnDefaultFleet(root)

	-- 4) Tối ưu hiệu năng ngay trong Edit Mode
	local report = PerfOptimizer.optimize(root)

	-- 5) BÁO CÁO: liệt kê từng module đã dựng để xác nhận đã "gắn vào game"
	local modulesFolder = WorldRoot:FindFirstChild("Modules")
	local built = {}
	if modulesFolder then
		for _, child in ipairs(modulesFolder:GetChildren()) do
			if child:IsA("ModuleScript") then
				table.insert(built, child.Name)
			end
		end
	end
	table.sort(built)

	local container = root:FindFirstChild("DistrictModules")
	local districtCount = if container then #container:GetChildren() else 0

	print(string.format(
		"[Sync] DỰNG XONG — %d part | %d module OK | %d module lỗi | va chạm %d | đổ bóng %d | SurfaceGui %d | DistrictModules: %d",
		report.totalParts,
		summary.loadedCount,
		summary.failedCount,
		report.collidableAfter,
		report.shadowCastersAfter,
		report.surfaceGuis,
		districtCount
	))
	print("[Sync] Module đã nạp: " .. table.concat(built, ", "))

	if summary.loadedCount < #built then
		warn(string.format(
			"[Sync] CẢNH BÁO: %d/%d module KHÔNG dựng được — xem log 'Lỗi nạp module' / 'Lỗi dựng công trình' phía trên.",
			#built - summary.loadedCount,
			#built
		))
	end

	-- StreamingEnabled KHÔNG thể bật bằng script -> nhắc Chủ dự án bật tay 1 lần
	if not workspace.StreamingEnabled then
		warn("[Hiệu năng] HÃY BẬT: chọn Workspace > Properties > StreamingEnabled = true (StreamingTargetRadius = 1024). Giảm ~78% part phải nạp.")
	end
end)

freshShared:Destroy()

if not ok then
	warn("[Los Santos Multi-Agent Build Error]", err)
end
