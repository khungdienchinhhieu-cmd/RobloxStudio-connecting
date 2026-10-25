--!strict

local Hello = {}

Hello.ProjectName = "RobloxStudio-connecting"

function Hello.greet(scope: string): string
	return string.format("[%s] Kết nối Rojo thành công từ %s!", Hello.ProjectName, scope)
end

return Hello
