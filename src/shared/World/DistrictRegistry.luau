--!strict
--[[
	DistrictRegistry.luau
	BỘ TỰ ĐỘNG NẠP MODULE ĐA-AGENT (MULTI-AGENT PLUG-AND-PLAY REGISTRY):
	- Tự động quét toàn bộ các ModuleScript nằm trong `ReplicatedStorage.Shared.World.Modules`
	  và gọi `mod.build(modulesRoot)` theo thứ tự `Order` tăng dần.
	- Tự động dọn tường rào tạm (`PerimeterWall_*` / `SurveyMonument*`) của ô móng trống tương ứng
	  trong `02_SidewalksAndLots` để cổng ra vào công trình thông thoáng 100%.
]]

export type WorldModuleSpec = {
	Id: string,
	PlotId: string?,
	Order: number?,
	Enabled: boolean?,
	build: (modulesContainer: Instance) -> Instance?,
}

export type BuildSummary = {
	container: Folder,
	loadedCount: number,
	failedCount: number,
}

local DistrictRegistry = {}

local function clearPlotPlaceholders(losSantosRoot: Instance, rawPlotId: string?)
	if not rawPlotId or rawPlotId == "" or rawPlotId == "StreetProps" then
		return
	end

	local lotsFolder = losSantosRoot:FindFirstChild("02_SidewalksAndLots")
	if not lotsFolder then
		return
	end

	-- Hỗ trợ cả Plot_C3_West / Plot_C3_East ánh xạ về thư mục Plot_C3_*
	local basePlotId = rawPlotId
	local halfMode: string? = nil
	if rawPlotId == "Plot_C3_West" then
		basePlotId = "Plot_C3"
		halfMode = "WEST"
	elseif rawPlotId == "Plot_C3_East" then
		basePlotId = "Plot_C3"
		halfMode = "EAST"
	end

	for _, lotChild in ipairs(lotsFolder:GetChildren()) do
		if string.sub(lotChild.Name, 1, #basePlotId + 1) == (basePlotId .. "_") then
			for _, item in ipairs(lotChild:GetChildren()) do
				local isPlaceholder = string.sub(item.Name, 1, 14) == "PerimeterWall_"
					or string.sub(item.Name, 1, 14) == "SurveyMonument"
				if isPlaceholder then
					if halfMode == nil then
						item:Destroy()
					else
						-- Với ô đôi Plot_C3 (tâm X = 218), chỉ xoá các khối nằm bên nửa Tây (<218) hoặc Đông (>=218)
						if item:IsA("BasePart") then
							if (halfMode == "WEST" and item.Position.X <= 218.5) or (halfMode == "EAST" and item.Position.X >= 217.5) then
								item:Destroy()
							end
						else
							for _, sub in ipairs(item:GetDescendants()) do
								if sub:IsA("BasePart") then
									if (halfMode == "WEST" and sub.Position.X <= 218.5) or (halfMode == "EAST" and sub.Position.X >= 217.5) then
										sub:Destroy()
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function DistrictRegistry.buildAll(losSantosRoot: Instance): BuildSummary
	local existing = losSantosRoot:FindFirstChild("DistrictModules")
	if existing then
		existing:Destroy()
	end

	local container = Instance.new("Folder")
	container.Name = "DistrictModules"
	container.Parent = losSantosRoot
	container:SetAttribute("MultiAgentRegistryActive", true)

	local summary: BuildSummary = {
		container = container,
		loadedCount = 0,
		failedCount = 0,
	}

	local modulesFolder = script.Parent:FindFirstChild("Modules")
	if not modulesFolder then
		return summary
	end

	type LoadedEntry = {
		name: string,
		order: number,
		spec: WorldModuleSpec,
	}

	local entries: { LoadedEntry } = {}
	for _, child in ipairs(modulesFolder:GetChildren()) do
		if child:IsA("ModuleScript") then
			local okReq, result = pcall(require, child)
			if okReq and type(result) == "table" and type(result.build) == "function" then
				local spec = result :: WorldModuleSpec
				if spec.Enabled ~= false then
					table.insert(entries, {
						name = child.Name,
						order = tonumber(spec.Order) or 50,
						spec = spec,
					})
				end
			else
				summary.failedCount += 1
				warn("[DistrictRegistry] Lỗi nạp module", child.Name, result)
			end
		end
	end

	table.sort(entries, function(a, b)
		if a.order ~= b.order then
			return a.order < b.order
		end
		return a.name < b.name
	end)

	for _, item in ipairs(entries) do
		clearPlotPlaceholders(losSantosRoot, item.spec.PlotId)
		local okBuild, err = pcall(function()
			item.spec.build(container)
		end)
		if okBuild then
			summary.loadedCount += 1
		else
			summary.failedCount += 1
			warn("[DistrictRegistry] Lỗi dựng công trình", item.name, err)
		end
	end

	container:SetAttribute("LoadedModuleCount", summary.loadedCount)
	return summary
end

--[[
	Dựng lại ĐÚNG MỘT module (dùng cho đồng bộ tăng dần: chỉ module nào đổi mã mới dựng lại).
	Trả về (thành công, lỗi).
]]
function DistrictRegistry.buildOne(losSantosRoot: Instance, moduleName: string): (boolean, string?)
	local container = losSantosRoot:FindFirstChild("DistrictModules")
	if not container then
		return false, "chưa có DistrictModules"
	end
	local modulesFolder = script.Parent:FindFirstChild("Modules")
	local mod = modulesFolder and modulesFolder:FindFirstChild(moduleName)
	if not mod or not mod:IsA("ModuleScript") then
		return false, "không thấy ModuleScript " .. moduleName
	end

	local okReq, spec = pcall(require, mod)
	if not okReq or type(spec) ~= "table" or type((spec :: any).build) ~= "function" then
		return false, "module không hợp lệ: " .. tostring(spec)
	end
	local s = spec :: WorldModuleSpec
	if s.Enabled == false then
		return false, "module đang tắt"
	end

	-- Xoá bản dựng cũ của riêng module này (tên = Id, có fallback theo tên file)
	local old = container:FindFirstChild(s.Id) or container:FindFirstChild(moduleName)
	if old then
		old:Destroy()
	end

	clearPlotPlaceholders(losSantosRoot, s.PlotId)

	local okBuild, err = pcall(function()
		s.build(container)
	end)
	if not okBuild then
		return false, tostring(err)
	end
	return true, nil
end

return DistrictRegistry
