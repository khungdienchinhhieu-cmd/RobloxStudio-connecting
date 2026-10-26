--!strict
--[[
	CarryClient.luau  (Sync v25 — CƠ CHẾ TAY, phần hiển thị)
	================================================================================
	• HUD nhỏ ở giữa dưới màn hình: món đồ đang vác + phím tắt (G thả · F/chuột trái ném)
	• Tư thế HAI TAY NÂNG: xoay Motor6D.Transform của vai trái/phải mỗi khung hình
	  (chỉ trên máy người chơi nên không tốn băng thông)
	• Gửi lệnh thả / ném lên server qua remote `CarryAction`
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local CarryClient = {}

local localPlayer = Players.LocalPlayer

-- Góc nâng tay khi vác đồ (độ). Chỉnh ở đây nếu muốn tay cao/thấp hơn.
local ARM_PITCH = 72
local ARM_SPREAD = 12

local function findMotor(char: Model, name: string): Motor6D?
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") and d.Name == name then
			return d
		end
	end
	return nil
end

function CarryClient.mount()
	local remotes = ReplicatedStorage:WaitForChild("GtaRemotes")
	local stateRemote = remotes:WaitForChild("CarryState") :: RemoteEvent
	local actionRemote = remotes:WaitForChild("CarryAction") :: RemoteEvent

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("GtaCarryGui")
	if old then
		old:Destroy()
	end

	-- ── HUD ────────────────────────────────────────────────────────────────
	local screen = Instance.new("ScreenGui")
	screen.Name = "GtaCarryGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 30
	screen.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -132)
	panel.Size = UDim2.fromOffset(360, 76)
	panel.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	panel.BackgroundTransparency = 0.18
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(250, 204, 21)
	stroke.Thickness = 2
	stroke.Transparency = 0.25
	stroke.Parent = panel

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(64, 64)
	icon.Position = UDim2.fromOffset(8, 6)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 34
	icon.Text = "📦"
	icon.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -84, 0, 30)
	title.Position = UDim2.fromOffset(76, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = Color3.fromRGB(250, 204, 21)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "ĐANG VÁC"
	title.Parent = panel

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(1, -84, 0, 30)
	hint.Position = UDim2.fromOffset(76, 36)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 15
	hint.TextColor3 = Color3.fromRGB(203, 213, 225)
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Text = "[G] Thả   ·   [F / Chuột trái] Ném"
	hint.Parent = panel

	-- ── Trạng thái ─────────────────────────────────────────────────────────
	local carrying = false
	local carryKind = ""
	local armConn: RBXScriptConnection? = nil

	local function stopPose()
		if armConn then
			armConn:Disconnect()
			armConn = nil
		end
	end

	local function startPose()
		stopPose()
		local char = localPlayer.Character
		if not char then
			return
		end
		local right = findMotor(char, "RightShoulder")
		local left = findMotor(char, "LeftShoulder")
		if not right and not left then
			return -- R6 hoặc rig lạ: bỏ qua, chỉ cần món đồ nằm trước ngực
		end
		armConn = RunService.RenderStepped:Connect(function()
			if not carrying then
				return
			end
			if right then
				right.Transform = CFrame.Angles(math.rad(-ARM_PITCH), 0, math.rad(ARM_SPREAD))
			end
			if left then
				left.Transform = CFrame.Angles(math.rad(-ARM_PITCH), 0, math.rad(-ARM_SPREAD))
			end
		end)
	end

	local function onGrab(kind: string, display: string, iconText: string)
		carrying = true
		carryKind = kind
		icon.Text = if iconText ~= "" then iconText else "📦"
		title.Text = "ĐANG VÁC: " .. string.upper(display)
		panel.Visible = true
		panel.Position = UDim2.new(0.5, 0, 1, -90)
		TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			Position = UDim2.new(0.5, 0, 1, -132),
		}):Play()
		startPose()
	end

	local function onRelease()
		carrying = false
		carryKind = ""
		panel.Visible = false
		stopPose()
	end

	stateRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if payload.action == "grab" then
			onGrab(tostring(payload.kind or ""), tostring(payload.display or "đồ"), tostring(payload.icon or ""))
		else
			onRelease()
		end
	end)

	-- ── Điều khiển ─────────────────────────────────────────────────────────
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not carrying then
			return
		end
		if input.KeyCode == Enum.KeyCode.G then
			actionRemote:FireServer("drop")
		elseif input.KeyCode == Enum.KeyCode.F then
			actionRemote:FireServer("throw", 1)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			actionRemote:FireServer("throw", 1.15)
		end
	end)

	-- Hồi sinh / vào game: đồng bộ lại trạng thái thật từ server
	local function syncWithServer()
		task.wait(0.5)
		actionRemote:FireServer("sync")
	end
	localPlayer.CharacterAdded:Connect(syncWithServer)
	if localPlayer.Character then
		task.spawn(syncWithServer)
	end
end

return CarryClient
