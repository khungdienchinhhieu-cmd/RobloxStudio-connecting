--!strict
--[[
	VehiclePromptUI.luau
	Giao diện nút [F] lên xe thiết kế lại chuẩn GTA V (nhỏ gọn, tinh tế, KHÔNG BAO GIỜ chắn giữa màn hình):
	- Thay thế hoàn toàn bảng ProximityPrompt xám khổng lồ mặc định của Roblox (vì prompt.Style = Custom).
	- TỰ ĐỘNG ẨN 100% ngay lập tức khi nhân vật đã ngồi trên bất kỳ ghế nào (SeatPart ~= nil) -> không bao giờ
	  hiện nhầm nút "Vào ghế phụ" chắn ngang người khi đang ngồi lái!
	- Khi đi bộ lại gần tay nắm cửa xe:
	  1. Chấm ghim phím [F] siêu nhỏ (22x22 px) gắn gọn ngay trên tay nắm cửa 3D để biết đang đứng gần cửa nào.
	  2. Thanh chip mỏng 228x30 px nằm sát mép đáy màn hình (giữa Minimap & Tên Đường), bấm chuột/chạm tay cũng vào xe được!
]]

local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local VehiclePromptUI = {}

function VehiclePromptUI.mount(localPlayer: Player)
	local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local old = playerGui:FindFirstChild("GtaVehiclePromptGui")
	if old then
		old:Destroy()
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "GtaVehiclePromptGui"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 18
	screen.Parent = playerGui

	-- 1. Thanh Chip Gọn Nhẹ Sát Mép Đáy Màn Hình (Không bao giờ che nhân vật hay thân xe!)
	local bottomChip = Instance.new("TextButton")
	bottomChip.Name = "BottomActionChip"
	bottomChip.AnchorPoint = Vector2.new(0.5, 1)
	bottomChip.Position = UDim2.new(0.5, 0, 1, -18)
	bottomChip.Size = UDim2.fromOffset(234, 30)
	bottomChip.BackgroundColor3 = Color3.fromRGB(10, 13, 18)
	bottomChip.BackgroundTransparency = 0.14
	bottomChip.BorderSizePixel = 0
	bottomChip.AutoButtonColor = true
	bottomChip.Text = ""
	bottomChip.Visible = false
	bottomChip.Parent = screen

	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0, 6)
	chipCorner.Parent = bottomChip

	local chipStroke = Instance.new("UIStroke")
	chipStroke.Color = Color3.fromRGB(56, 189, 248)
	chipStroke.Transparency = 0.35
	chipStroke.Thickness = 1.2
	chipStroke.Parent = bottomChip

	local keyBadge = Instance.new("TextLabel")
	keyBadge.AnchorPoint = Vector2.new(0, 0.5)
	keyBadge.Position = UDim2.new(0, 7, 0.5, 0)
	keyBadge.Size = UDim2.fromOffset(20, 20)
	keyBadge.BackgroundColor3 = Color3.fromRGB(241, 245, 249)
	keyBadge.Font = Enum.Font.GothamBlack
	keyBadge.TextSize = 12
	keyBadge.TextColor3 = Color3.fromRGB(12, 16, 24)
	keyBadge.Text = "F"
	keyBadge.Parent = bottomChip

	local kbCorner = Instance.new("UICorner")
	kbCorner.CornerRadius = UDim.new(0, 4)
	kbCorner.Parent = keyBadge

	local actionLabel = Instance.new("TextLabel")
	actionLabel.AnchorPoint = Vector2.new(0, 0.5)
	actionLabel.Position = UDim2.new(0, 34, 0.5, 0)
	actionLabel.Size = UDim2.new(1, -42, 1, 0)
	actionLabel.BackgroundTransparency = 1
	actionLabel.Font = Enum.Font.GothamBold
	actionLabel.TextSize = 12
	actionLabel.TextXAlignment = Enum.TextXAlignment.Left
	actionLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
	actionLabel.TextTruncate = Enum.TextTruncate.AtEnd
	actionLabel.Text = "Vào ghế lái • Banshee GT"
	actionLabel.Parent = bottomChip

	-- 2. Chấm Ghim Nhỏ Gọn (22x22 px) Gắn Đúng Tay Nắm Cửa 3D (nhỏ gấp 15 lần bảng mặc định của Roblox!)
	local handlePin = Instance.new("BillboardGui")
	handlePin.Name = "DoorHandleMiniPin"
	handlePin.Size = UDim2.fromOffset(22, 22)
	handlePin.StudsOffset = Vector3.new(0, 0.35, 0)
	handlePin.AlwaysOnTop = true
	handlePin.Enabled = false
	handlePin.Parent = screen

	local pinBox = Instance.new("Frame")
	pinBox.Size = UDim2.fromScale(1, 1)
	pinBox.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
	pinBox.BackgroundTransparency = 0.12
	pinBox.BorderSizePixel = 0
	pinBox.Parent = handlePin

	local pinCorner = Instance.new("UICorner")
	pinCorner.CornerRadius = UDim.new(0, 5)
	pinCorner.Parent = pinBox

	local pinStroke = Instance.new("UIStroke")
	pinStroke.Color = Color3.fromRGB(56, 189, 248)
	pinStroke.Thickness = 1.4
	pinStroke.Parent = pinBox

	local pinTxt = Instance.new("TextLabel")
	pinTxt.Size = UDim2.fromScale(1, 1)
	pinTxt.BackgroundTransparency = 1
	pinTxt.Font = Enum.Font.GothamBlack
	pinTxt.TextSize = 11
	pinTxt.TextColor3 = Color3.fromRGB(248, 250, 252)
	pinTxt.Text = "F"
	pinTxt.Parent = pinBox

	local currentPrompt: ProximityPrompt? = nil

	local function isPlayerSeated(): boolean
		local char = localPlayer.Character
		local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		return hum ~= nil and hum.SeatPart ~= nil
	end

	local function refreshVisibility()
		local pr = currentPrompt
		if not pr or not pr.Parent or not pr.Enabled or isPlayerSeated() then
			bottomChip.Visible = false
			handlePin.Enabled = false
			handlePin.Adornee = nil
			return
		end

		local keyName = pr.KeyboardKeyCode.Name
		if keyName == "" or keyName == "Unknown" then
			keyName = "F"
		end
		keyBadge.Text = keyName
		pinTxt.Text = keyName

		local obj = pr.ObjectText
		local act = pr.ActionText
		actionLabel.Text = if obj ~= "" then (act .. " • " .. obj) else act

		local adornee = pr.Parent
		if adornee and adornee:IsA("BasePart") then
			handlePin.Adornee = adornee
			handlePin.Enabled = true
		else
			handlePin.Adornee = nil
			handlePin.Enabled = false
		end
		bottomChip.Visible = true
	end

	-- Cho phép bấm trực tiếp vào thanh Chip đáy màn hình (hỗ trợ cả Mobile / Chuột!)
	bottomChip.MouseButton1Click:Connect(function()
		local pr = currentPrompt
		if pr and pr.Parent and pr.Enabled and not isPlayerSeated() then
			pr:InputHoldBegin()
			pr:InputHoldEnd()
		end
	end)

	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return
		end
		currentPrompt = prompt
		refreshVisibility()
	end)

	ProximityPromptService.PromptHidden:Connect(function(prompt)
		if currentPrompt == prompt then
			currentPrompt = nil
			refreshVisibility()
		end
	end)

	-- Kiểm tra liên tục mỗi frame: vừa đặt mông lên ghế lái là ẩn sạch nút [F] trong 0.00s!
	RunService.RenderStepped:Connect(function()
		if currentPrompt ~= nil then
			refreshVisibility()
		elseif bottomChip.Visible or handlePin.Enabled then
			bottomChip.Visible = false
			handlePin.Enabled = false
		end
	end)
end

return VehiclePromptUI
