local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
if shared then
	-- Nhân bản tạm thời Shared để phá bộ nhớ đệm require() của Roblox Studio Edit Mode
	local freshShared = shared:Clone()
	freshShared.Name = "_TempBuildSharedMultiAgent"
	freshShared.Parent = ReplicatedStorage

	local ok, err = pcall(function()
		local CityFoundation = require(freshShared:WaitForChild("World"):WaitForChild("CityFoundation"))
		local DistrictRegistry = require(freshShared:WaitForChild("World"):WaitForChild("DistrictRegistry"))
		local PerfOptimizer = require(freshShared:WaitForChild("World"):WaitForChild("PerfOptimizer"))
		local VehicleBuilder = require(freshShared:WaitForChild("Vehicles"):WaitForChild("VehicleBuilder"))
		local root = CityFoundation.build(true)
		DistrictRegistry.buildAll(root)
		VehicleBuilder.spawnDefaultFleet(root)
		-- Tối ưu hiệu năng ngay trong Edit Mode để bản lưu xuống Studio cũng nhẹ
		PerfOptimizer.optimize(root)
	end)

	freshShared:Destroy()
	if not ok then
		warn("[Los Santos Multi-Agent Build Error]", err)
	end
end
