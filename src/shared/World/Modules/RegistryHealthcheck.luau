--!strict
--[[
	RegistryHealthcheck.luau
	File mẫu chuẩn giao diện cho Hệ thống Đa-Agent (xem chi tiết tại `MULTI_AGENT_SYSTEM.md`).
	Mỗi Agent ở một phiên Arena.ai mới chỉ cần tạo 1 file `.luau` riêng trong thư mục `src/shared/World/Modules/`
	theo đúng cấu trúc dưới đây — `DistrictRegistry` sẽ tự động phát hiện và ghép vào thành phố Los Santos!
]]

local RegistryHealthcheck = {
	Id = "RegistryHealthcheck",
	PlotId = "NONE",
	Order = 1,
	Enabled = true,
}

function RegistryHealthcheck.build(modulesContainer: Instance): Instance?
	modulesContainer:SetAttribute("MultiAgentRegistryActive", true)
	return nil
end

return RegistryHealthcheck
