--!nonstrict
--[[
	FirstPersonCamera.luau — GÓC NHÌN THỨ NHẤT
	- Camera luôn ở góc nhìn thứ nhất (LockFirstPerson). Chuột bị khoá giữa màn hình để xoay nhìn.
	- Bấm ESC: mở chuột để bấm menu/bảng. Bấm lại ESC hoặc click vào màn hình để khoá chuột lại.
	  (ESC của Roblox vốn cũng mở menu và nhả chuột; script này giữ hành vi đó và thêm click để khoá lại.)
]]

local UserInputService = game:GetService("UserInputService")

local FirstPersonCamera = {}

function FirstPersonCamera.mount(localPlayer: Player)
	localPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	localPlayer.CameraMaxZoomDistance = 0.5
	localPlayer.CameraMinZoomDistance = 0.5

	local mouseFree = false

	local function setMouseFree(free: boolean)
		mouseFree = free
		if free then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if input.KeyCode == Enum.KeyCode.Escape then
			setMouseFree(not mouseFree)
			return
		end
		if mouseFree and input.UserInputType == Enum.UserInputType.MouseButton1 and not processed then
			setMouseFree(false)
		end
	end)

	setMouseFree(false)
end

return FirstPersonCamera
