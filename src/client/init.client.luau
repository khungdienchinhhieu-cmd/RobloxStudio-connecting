--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CityConfig = require(Shared:WaitForChild("CityConfig"))

local remotesFolder = ReplicatedStorage:WaitForChild("CityRemotes")
local notifyRemote = remotesFolder:WaitForChild("NotifyClient") :: RemoteEvent

-- ============================================================================
-- 1. KHỞI TẠO GIAO DIỆN HUD HIỆN ĐẠI
-- ============================================================================
local existingHud = playerGui:FindFirstChild("CityInteractiveHud")
if existingHud then
	existingHud:Destroy()
end

local hud = Instance.new("ScreenGui")
hud.Name = "CityInteractiveHud"
hud.ResetOnSpawn = false
hud.IgnoreGuiInset = false
hud.Parent = playerGui

-- Thanh hiển thị Khu Vực Hiện Tại (Góc trên giữa)
local zoneBanner = Instance.new("Frame")
zoneBanner.Name = "ZoneBanner"
zoneBanner.AnchorPoint = Vector2.new(0.5, 0)
zoneBanner.Position = UDim2.new(0.5, 0, 0, 10)
zoneBanner.Size = UDim2.fromOffset(340, 34)
zoneBanner.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
zoneBanner.BackgroundTransparency = 0.2
zoneBanner.Parent = hud

local zbCorner = Instance.new("UICorner")
zbCorner.CornerRadius = UDim.new(0, 17)
zbCorner.Parent = zoneBanner

local zbStroke = Instance.new("UIStroke")
zbStroke.Color = Color3.fromRGB(56, 189, 248)
zbStroke.Thickness = 1.2
zbStroke.Transparency = 0.35
zbStroke.Parent = zoneBanner

local zoneLabel = Instance.new("TextLabel")
zoneLabel.Size = UDim2.fromScale(0.94, 1)
zoneLabel.Position = UDim2.fromScale(0.03, 0)
zoneLabel.BackgroundTransparency = 1
zoneLabel.Font = Enum.Font.GothamBold
zoneLabel.TextSize = 13
zoneLabel.TextColor3 = Color3.fromRGB(224, 242, 254)
zoneLabel.Text = "📍 Đại Lộ Trung Tâm"
zoneLabel.Parent = zoneBanner

-- Bảng thông tin Tiền mặt + Chạy Nhanh + Tốc độ Xe (Góc dưới bên trái)
local statsCard = Instance.new("Frame")
statsCard.Name = "StatsCard"
statsCard.AnchorPoint = Vector2.new(0, 1)
statsCard.Position = UDim2.new(0, 16, 1, -16)
statsCard.Size = UDim2.fromOffset(250, 108)
statsCard.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
statsCard.BackgroundTransparency = 0.15
statsCard.Parent = hud

local scCorner = Instance.new("UICorner")
scCorner.CornerRadius = UDim.new(0, 12)
scCorner.Parent = statsCard

local scStroke = Instance.new("UIStroke")
scStroke.Color = Color3.fromRGB(51, 65, 85)
scStroke.Thickness = 1.2
scStroke.Parent = statsCard

local cashLabel = Instance.new("TextLabel")
cashLabel.Position = UDim2.fromOffset(14, 10)
cashLabel.Size = UDim2.new(1, -28, 0, 28)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBlack
cashLabel.TextSize = 20
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.TextColor3 = Color3.fromRGB(110, 231, 183)
cashLabel.Text = "💵 $300"
cashLabel.Parent = statsCard

local questLabel = Instance.new("TextLabel")
questLabel.Position = UDim2.fromOffset(14, 38)
questLabel.Size = UDim2.new(1, -28, 0, 26)
questLabel.BackgroundTransparency = 1
questLabel.Font = Enum.Font.GothamMedium
questLabel.TextSize = 11
questLabel.TextWrapped = true
questLabel.TextXAlignment = Enum.TextXAlignment.Left
questLabel.TextColor3 = Color3.fromRGB(253, 224, 71)
questLabel.Text = "🍕 Ghé Pizza Hot để nhận việc giao hàng!"
questLabel.Parent = statsCard

local sprintBtn = Instance.new("TextButton")
sprintBtn.Position = UDim2.fromOffset(14, 68)
sprintBtn.Size = UDim2.fromOffset(128, 30)
sprintBtn.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
sprintBtn.Font = Enum.Font.GothamBold
sprintBtn.TextSize = 12
sprintBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sprintBtn.Text = "🏃 Chạy nhanh [Shift]"
sprintBtn.Parent = statsCard
local spCorner = Instance.new("UICorner")
spCorner.CornerRadius = UDim.new(0, 8)
spCorner.Parent = sprintBtn

local speedoLabel = Instance.new("TextLabel")
speedoLabel.Position = UDim2.fromOffset(148, 68)
speedoLabel.Size = UDim2.fromOffset(90, 30)
speedoLabel.BackgroundTransparency = 1
speedoLabel.Font = Enum.Font.GothamBold
speedoLabel.TextSize = 12
speedoLabel.TextXAlignment = Enum.TextXAlignment.Right
speedoLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
speedoLabel.Text = ""
speedoLabel.Parent = statsCard

-- Hộp thông báo & Hội thoại NPC (Góc trên bên phải / giữa dưới)
local toastFrame = Instance.new("Frame")
toastFrame.Name = "ToastNotification"
toastFrame.AnchorPoint = Vector2.new(0.5, 0)
toastFrame.Position = UDim2.new(0.5, 0, 0, -120)
toastFrame.Size = UDim2.fromOffset(420, 82)
toastFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
toastFrame.BackgroundTransparency = 0.08
toastFrame.Visible = false
toastFrame.Parent = hud

local tfCorner = Instance.new("UICorner")
tfCorner.CornerRadius = UDim.new(0, 12)
tfCorner.Parent = toastFrame

local tfStroke = Instance.new("UIStroke")
tfStroke.Color = Color3.fromRGB(56, 189, 248)
tfStroke.Thickness = 1.6
tfStroke.Parent = toastFrame

local toastTitle = Instance.new("TextLabel")
toastTitle.Position = UDim2.fromOffset(16, 10)
toastTitle.Size = UDim2.new(1, -32, 0, 22)
toastTitle.BackgroundTransparency = 1
toastTitle.Font = Enum.Font.GothamBold
toastTitle.TextSize = 14
toastTitle.TextXAlignment = Enum.TextXAlignment.Left
toastTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
toastTitle.Parent = toastFrame

local toastBody = Instance.new("TextLabel")
toastBody.Position = UDim2.fromOffset(16, 33)
toastBody.Size = UDim2.new(1, -32, 0, 40)
toastBody.BackgroundTransparency = 1
toastBody.Font = Enum.Font.GothamMedium
toastBody.TextSize = 12
toastBody.TextWrapped = true
toastBody.TextXAlignment = Enum.TextXAlignment.Left
toastBody.TextYAlignment = Enum.TextYAlignment.Top
toastBody.TextColor3 = Color3.fromRGB(203, 213, 225)
toastBody.Parent = toastFrame

local toastToken = 0
local function showNotification(kind: string, title: string, body: string)
	toastToken += 1
	local myToken = toastToken

	local accent = Color3.fromRGB(56, 189, 248)
	if kind == "cash" or kind == "success" then
		accent = Color3.fromRGB(52, 211, 153)
	elseif kind == "warn" then
		accent = Color3.fromRGB(251, 191, 36)
	elseif kind == "dialogue" or kind == "quest" then
		accent = Color3.fromRGB(232, 121, 249)
	end

	tfStroke.Color = accent
	toastTitle.TextColor3 = accent
	toastTitle.Text = title
	toastBody.Text = body
	toastFrame.Visible = true
	toastFrame.Position = UDim2.new(0.5, 0, 0, -100)

	TweenService:Create(toastFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 52),
	}):Play()

	task.delay(if kind == "dialogue" then 6.5 else 4.5, function()
		if toastToken ~= myToken then
			return
		end
		local hideTween = TweenService:Create(
			toastFrame,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -110) }
		)
		hideTween:Play()
		hideTween.Completed:Wait()
		if toastToken == myToken then
			toastFrame.Visible = false
		end
	end)
end

notifyRemote.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		showNotification(
			tostring(payload.kind or "info"),
			tostring(payload.title or "Thông báo"),
			tostring(payload.body or "")
		)
	end
end)

-- ============================================================================
-- 2. HỆ THỐNG CHẠY NHANH (SPRINT) & CỘT CHỈ ĐƯỜNG GIAO HÀNG 3D (GPS BEACON)
-- ============================================================================
local isSprinting = false

local function applySprintSpeed()
	local char = localPlayer.Character
	local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
	if not hum then
		return
	end
	local drinkBoost = tonumber(localPlayer:GetAttribute("SpeedBoostValue")) or 0
	if drinkBoost > 0 then
		hum.WalkSpeed = drinkBoost
	else
		hum.WalkSpeed = if isSprinting then 23 else 16
	end
	sprintBtn.BackgroundColor3 = if isSprinting
		then Color3.fromRGB(16, 185, 129)
		else Color3.fromRGB(37, 99, 235)
	sprintBtn.Text = if isSprinting then "⚡ Đang chạy nhanh" else "🏃 Chạy nhanh [Shift]"
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		isSprinting = true
		applySprintSpeed()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		isSprinting = false
		applySprintSpeed()
	end
end)

sprintBtn.MouseButton1Click:Connect(function()
	isSprinting = not isSprinting
	applySprintSpeed()
end)

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.3)
	applySprintSpeed()
end)

-- Cột sáng GPS hướng dẫn điểm giao hàng
local waypointPart: Part? = nil
local waypointLabel: TextLabel? = nil

local function updateDeliveryBeacon()
	local targetId = tostring(localPlayer:GetAttribute("DeliveryTargetId") or "")
	local targetName = tostring(localPlayer:GetAttribute("DeliveryTargetName") or "")
	local targetPos = localPlayer:GetAttribute("DeliveryTargetPos")

	if targetId == "" or typeof(targetPos) ~= "Vector3" then
		questLabel.Text = "🍕 Ghé Pizza Hot để nhận việc giao hàng!"
		if waypointPart then
			waypointPart:Destroy()
			waypointPart = nil
			waypointLabel = nil
		end
		return
	end

	local reward = tonumber(localPlayer:GetAttribute("DeliveryReward")) or 90
	questLabel.Text = string.format("📦 Giao tới: %s (+$%d)", targetName, reward)

	if not waypointPart then
		local p = Instance.new("Part")
		p.Name = "ClientDeliveryBeacon"
		p.Anchored = true
		p.CanCollide = false
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(65, 3.2, 3.2)
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(250, 204, 21)
		p.Transparency = 0.55

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(220, 50)
		bb.StudsOffset = Vector3.new(0, 12, 0)
		bb.AlwaysOnTop = true
		bb.Parent = p

		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(24, 20, 10)
		bg.BackgroundTransparency = 0.15
		bg.Parent = bb
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 10)
		c.Parent = bg

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(0.92, 0.86)
		lbl.Position = UDim2.fromScale(0.04, 0.07)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.TextColor3 = Color3.fromRGB(253, 224, 71)
		lbl.Parent = bg

		p.Parent = workspace
		waypointPart = p
		waypointLabel = lbl
	end

	if waypointPart then
		waypointPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 32, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end
end

local function updateCashUi()
	local cash = tonumber(localPlayer:GetAttribute("Cash")) or CityConfig.StartingCash
	cashLabel.Text = string.format("💵 $%d", cash)
end

localPlayer:GetAttributeChangedSignal("Cash"):Connect(updateCashUi)
localPlayer:GetAttributeChangedSignal("DeliveryTargetId"):Connect(updateDeliveryBeacon)
localPlayer:GetAttributeChangedSignal("DeliveryTargetPos"):Connect(updateDeliveryBeacon)
updateCashUi()
updateDeliveryBeacon()

-- ============================================================================
-- 3. CẬP NHẬT KHU VỰC ĐỊA LÝ, KHOẢNG CÁCH GPS & ĐỒNG HỒ TỐC ĐỘ XE
-- ============================================================================
local function detectDistrictName(pos: Vector3): string
	for _, d in ipairs(CityConfig.Districts) do
		if
			pos.X >= d.min.X
			and pos.X <= d.max.X
			and pos.Z >= d.min.Z
			and pos.Z <= d.max.Z
		then
			return d.name
		end
	end
	return "Đại Lộ Trung Tâm Thành Phố"
end

RunService.RenderStepped:Connect(function()
	local char = localPlayer.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
	local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
	if not hrp or not hrp:IsA("BasePart") then
		return
	end

	local pos = hrp.Position
	zoneLabel.Text = "📍 " .. detectDistrictName(pos)

	if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
		local kmh = math.round(hrp.AssemblyLinearVelocity.Magnitude * 1.1)
		speedoLabel.Text = string.format("🏎️ %d km/h", kmh)
	else
		speedoLabel.Text = ""
	end

	if waypointPart and waypointLabel then
		local targetPos = localPlayer:GetAttribute("DeliveryTargetPos")
		local targetName = tostring(localPlayer:GetAttribute("DeliveryTargetName") or "Điểm giao")
		if typeof(targetPos) == "Vector3" then
			local dist = math.round((pos - targetPos).Magnitude)
			waypointLabel.Text = string.format("📦 %s\nCách %d m", targetName, dist)
		end
	end
end)
