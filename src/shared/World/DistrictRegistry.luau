--!strict
--[[
	DistrictRegistry.luau
	BỘ TỰ ĐỘNG NẠP MODULE ĐA-AGENT (MULTI-AGENT PLUG-AND-PLAY REGISTRY):
	- Tự động quét toàn bộ các ModuleScript nằm trong `ReplicatedStorage.Shared.World.Modules`
	  và gọi `mod.build(modulesRoot)` theo thứ tự `Order` tăng dần.
	- Nhờ cơ chế này, N phiên Arena.ai chạy song song chỉ cần mỗi Agent tạo 1 file riêng biệt trong
	  `src/shared/World/Modules/<Plot_X_TenCongTrinh>.luau` mà KHÔNG CẦN SỬA CHUNG bất kỳ file hệ thống nào
	  -> Gộp nhánh (Merge PR) về `main` mượt 100%, KHÔNG BAO GIỜ XUNG ĐỘT CODE (0% Git Conflict)!
]]

export type WorldModuleSpec = {
	Id: string,
	PlotId: string?,
	Order: number?,
	Enabled: boolean?,
	build: (modulesContainer: Instance) -> Instance?,
}

local DistrictRegistry = {}

function DistrictRegistry.buildAll(losSantosRoot: Instance): Folder
	local existing = losSantosRoot:FindFirstChild("DistrictModules")
	if existing then
		existing:Destroy()
	end

	local container = Instance.new("Folder")
	container.Name = "DistrictModules"
	container.Parent = losSantosRoot

	local modulesFolder = script.Parent:FindFirstChild("Modules")
	if not modulesFolder then
		return container
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
		local okBuild, err = pcall(function()
			item.spec.build(container)
		end)
		if not okBuild then
			warn("[DistrictRegistry] Lỗi dựng công trình", item.name, err)
		end
	end

	return container
end

return DistrictRegistry
