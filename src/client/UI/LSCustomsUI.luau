--!strict
--[[
	LSCustomsUI.luau
	================================================================================
	GIAO DIỆN ĐỘ XE LOS SANTOS CUSTOMS (chuẩn GTA V — gọn, không che màn hình)
	================================================================================
	• Chip "[E] ĐỘ XE" nhỏ nằm sát đáy màn hình chỉ hiện khi xe đang nằm trong khoang.
	• Bấm [E] (hoặc chạm chip) mở bảng độ xe: SỬA CHỮA / SƠN LẠI / TURBO kèm giá tiền,
	  phím tắt [1] [2] [3], đóng bằng [ESC] hoặc nút X.
	• Mọi thao tác đều do server xác thực (tiền, khoang trống, cấp Turbo) rồi trả kết quả về.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LSCustomsUI = {}

local ACCENT = Color3.fromRGB(247, 214, 58)
local PANEL_BG = Color3.fromRGB(12, 16, 23)
local ROW_BG = Color3.fromRGB(24, 31, 42)

local function formatDollars(n: number): string
	local s = tostring(math.floor(n))
	local out = s
	while true do
		local formatted, k = string.gsub(out, "^(%d+)(%d%d%d)", "%1,%2")
		out = formatted
		if k == 0 then
			break
		end
	end
	return "$" .. out
end

function LSCustomsUI.mount(localPlayer: Player)
	local remotes = ReplicatedStorage:WaitForChild("GtaRemotes")
	local remote = remotes:WaitForChild("LSCustoms") :: RemoteEvent
	local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

	local old = playerGui:FindFirstChild("GtaLSCustomsGui")
	if old then
		old:Destroy()
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "GtaLSCustomsGui"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 21
	screen.Parent = playerGui

	-- ===========================================================
	-- 1. CHIP GỢI Ý [E] (sát đáy, nằm trên chip lên xe)
	-- ===========================================================
	local chip = Instance.new("TextButton")
	chip.Name = "LSCustomsChip"
	chip.AnchorPoint = Vector2.new(0.5, 1)
	chip.Position = UDim2.new(0.5, 0, 1, -56)
	chip.Size = UDim2.fromOffset(268, 32)
	chip.BackgroundColor3 = PANEL_BG
	chip.BackgroundTransparency = 0.12
	chip.BorderSizePixel = 0
	chip.AutoButtonColor = true
	chip.Text = ""
	chip.Visible = false
	chip.Parent = screen

	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0, 6)
	chipCorner.Parent = chip

	local chipStroke = Instance.new("UIStroke")
	chipStroke.Color = ACCENT
	chipStroke.Transparency = 0.25
	chipStroke.Thickness = 1.4
	chipStroke.Parent = chip

	local keyBadge = Instance.new("TextLabel")
	keyBadge.AnchorPoint = Vector2.new(0, 0.5)
	keyBadge.Position = UDim2.new(0, 8, 0.5, 0)
	keyBadge.Size = UDim2.fromOffset(22, 22)
	keyBadge.BackgroundColor3 = ACCENT
	keyBadge.BackgroundTransparency = 0.05
	keyBadge.BorderSizePixel = 0
	keyBadge.Text = "E"
	keyBadge.Font = Enum.Font.GothamBlack
	keyBadge.TextSize = 14
	keyBadge.TextColor3 = Color3.fromRGB(16, 20, 26)
	keyBadge.Parent = chip

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 5)
	badgeCorner.Parent = keyBadge

	local chipLabel = Instance.new("TextLabel")
	chipLabel.Position = UDim2.new(0, 38, 0, 0)
	chipLabel.Size = UDim2.new(1, -46, 1, 0)
	chipLabel.BackgroundTransparency = 1
	chipLabel.Font = Enum.Font.GothamBold
	chipLabel.TextSize = 13
	chipLabel.TextXAlignment = Enum.TextXAlignment.Left
	chipLabel.TextColor3 = Color3.fromRGB(236, 240, 246)
	chipLabel.Text = "ĐỘ XE — LOS SANTOS CUSTOMS"
	chipLabel.Parent = chip

	-- ===========================================================
	-- 2. BẢNG ĐỘ XE
	-- ===========================================================
	local panel = Instance.new("Frame")
	panel.Name = "LSCustomsPanel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -22, 0.5, 0)
	panel.Size = UDim2.fromOffset(372, 268)
	panel.BackgroundColor3 = PANEL_BG
	panel.BackgroundTransparency = 0.06
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screen

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = ACCENT
	panelStroke.Transparency = 0.55
	panelStroke.Thickness = 1.6
	panelStroke.Parent = panel

	local panelPad = Instance.new("UIPadding")
	panelPad.PaddingTop = UDim.new(0, 12)
	panelPad.PaddingBottom = UDim.new(0, 12)
	panelPad.PaddingLeft = UDim.new(0, 14)
	panelPad.PaddingRight = UDim.new(0, 14)
	panelPad.Parent = panel

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 20)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.TextSize = 16
	header.TextColor3 = ACCENT
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "LOS SANTOS CUSTOMS"
	header.Parent = panel

	local subHeader = Instance.new("TextLabel")
	subHeader.Position = UDim2.new(0, 0, 0, 22)
	subHeader.Size = UDim2.new(1, -30, 0, 16)
	subHeader.BackgroundTransparency = 1
	subHeader.Font = Enum.Font.GothamMedium
	subHeader.TextSize = 12
	subHeader.TextColor3 = Color3.fromRGB(168, 178, 192)
	subHeader.TextXAlignment = Enum.TextXAlignment.Left
	subHeader.Text = "Đang chờ xe trong khoang..."
	subHeader.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, 0, 0, 0)
	closeButton.Size = UDim2.fromOffset(24, 24)
	closeButton.BackgroundColor3 = ROW_BG
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 12
	closeButton.TextColor3 = Color3.fromRGB(226, 232, 240)
	closeButton.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 5)
	closeCorner.Parent = closeButton

	local list = Instance.new("Frame")
	list.Position = UDim2.new(0, 0, 0, 50)
	list.Size = UDim2.new(1, 0, 0, 152)
	list.BackgroundTransparency = 1
	list.Parent = panel

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	local footer = Instance.new("TextLabel")
	footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.new(0, 0, 1, 0)
	footer.Size = UDim2.new(1, 0, 0, 40)
	footer.BackgroundTransparency = 1
	footer.Font = Enum.Font.GothamMedium
	footer.TextSize = 11
	footer.TextWrapped = true
	footer.TextXAlignment = Enum.TextXAlignment.Left
	footer.TextYAlignment = Enum.TextYAlignment.Bottom
	footer.TextColor3 = Color3.fromRGB(150, 160, 175)
	footer.Text = "[1] [2] [3] chọn dịch vụ   •   [ESC] đóng bảng"
	footer.Parent = panel

	type Row = {
		button: TextButton,
		title: TextLabel,
		price: TextLabel,
		action: string,
	}

	local rows: { Row } = {}

	local specs = {
		{ action = "repair", index = "1", title = "SỬA CHỮA TOÀN XE", hint = "Hồi 100% máu ẩn mọi chi tiết" },
		{ action = "paint", index = "2", title = "SƠN LẠI VỎ XE", hint = "Đổi màu sơn theo bảng màu GTA V" },
		{ action = "turbo", index = "3", title = "NÂNG CẤP TURBO", hint = "Tăng tốc độ tối đa (tối đa 3 cấp)" },
	}

	for i, spec in ipairs(specs) do
		local row = Instance.new("TextButton")
		row.Name = "Row_" .. spec.action
		row.Size = UDim2.new(1, 0, 0, 44)
		row.BackgroundColor3 = ROW_BG
		row.BackgroundTransparency = 0.04
		row.BorderSizePixel = 0
		row.AutoButtonColor = true
		row.Text = ""
		row.LayoutOrder = i
		row.Parent = list

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 7)
		rowCorner.Parent = row

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Color3.fromRGB(56, 66, 82)
		rowStroke.Transparency = 0.35
		rowStroke.Thickness = 1
		rowStroke.Parent = row

		local keyTag = Instance.new("TextLabel")
		keyTag.AnchorPoint = Vector2.new(0, 0.5)
		keyTag.Position = UDim2.new(0, 10, 0.5, 0)
		keyTag.Size = UDim2.fromOffset(20, 20)
		keyTag.BackgroundColor3 = Color3.fromRGB(38, 48, 62)
		keyTag.BorderSizePixel = 0
		keyTag.Text = spec.index
		keyTag.Font = Enum.Font.GothamBold
		keyTag.TextSize = 12
		keyTag.TextColor3 = ACCENT
		keyTag.Parent = row

		local keyCorner = Instance.new("UICorner")
		keyCorner.CornerRadius = UDim.new(0, 4)
		keyCorner.Parent = keyTag

		local title = Instance.new("TextLabel")
		title.Position = UDim2.new(0, 38, 0, 6)
		title.Size = UDim2.new(1, -110, 0, 16)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 12
		title.TextColor3 = Color3.fromRGB(236, 242, 250)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = spec.title
		title.Parent = row

		local hint = Instance.new("TextLabel")
		hint.Position = UDim2.new(0, 38, 0, 22)
		hint.Size = UDim2.new(1, -110, 0, 14)
		hint.BackgroundTransparency = 1
		hint.Font = Enum.Font.GothamMedium
		hint.TextSize = 10
		hint.TextColor3 = Color3.fromRGB(142, 152, 168)
		hint.TextXAlignment = Enum.TextXAlignment.Left
		hint.Text = spec.hint
		hint.Parent = row

		local price = Instance.new("TextLabel")
		price.AnchorPoint = Vector2.new(1, 0.5)
		price.Position = UDim2.new(1, -12, 0.5, 0)
		price.Size = UDim2.fromOffset(66, 18)
		price.BackgroundTransparency = 1
		price.Font = Enum.Font.GothamBlack
		price.TextSize = 13
		price.TextColor3 = ACCENT
		price.TextXAlignment = Enum.TextXAlignment.Right
		price.Text = "--"
		price.Parent = row

		table.insert(rows, { button = row, title = title, price = price, action = spec.action })
	end

	-- ===========================================================
	-- 3. TRẠNG THÁI + ĐIỀU KHIỂN
	-- ===========================================================
	local promptVisible = false
	local currentBay = 0
	local menuOpen = false

	local function setPanelOpen(open: boolean)
		menuOpen = open
		panel.Visible = open
		if open then
			panel.Size = UDim2.fromOffset(356, 268)
			TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(372, 268),
			}):Play()
		end
	end

	local function refreshPrices(car: any)
		if type(car) ~= "table" then
			return
		end
		local prices = car.prices
		local turboLevel = tonumber(car.turbo) or 0
		subHeader.Text = string.format("%s   •   Hư hỏng %d%%   •   Turbo cấp %d", tostring(car.name), tonumber(car.damagePct) or 0, turboLevel)
		for _, row in ipairs(rows) do
			local price = if type(prices) == "table" then tonumber(prices[row.action]) else nil
			if price then
				row.price.Text = formatDollars(price)
				row.price.TextColor3 = ACCENT
			end
			if row.action == "turbo" then
				row.title.Text = if turboLevel >= 3 then "NÂNG CẤP TURBO (TỐI ĐA)" else "NÂNG CẤP TURBO"
				row.title.TextColor3 = if turboLevel >= 3 then Color3.fromRGB(140, 150, 165) else Color3.fromRGB(236, 242, 250)
			end
		end
	end

	chip.MouseButton1Click:Connect(function()
		if promptVisible then
			remote:FireServer({ action = "open", bay = currentBay })
		end
	end)

	closeButton.MouseButton1Click:Connect(function()
		setPanelOpen(false)
		remote:FireServer({ action = "close", bay = currentBay })
	end)

	local function fireRow(action: string)
		if not menuOpen then
			return
		end
		remote:FireServer({ action = action, bay = currentBay })
	end

	for _, row in ipairs(rows) do
		row.button.MouseButton1Click:Connect(function()
			fireRow(row.action)
		end)
	end

	remote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		local kind = payload.kind
		if kind == "prompt" then
			promptVisible = payload.visible == true
			currentBay = tonumber(payload.bay) or 0
			chip.Visible = promptVisible and not menuOpen
			if promptVisible then
				local vehicle = tostring(payload.vehicle or "")
				chipLabel.Text = if vehicle ~= "" then string.format("ĐỘ XE — %s", string.upper(vehicle)) else "ĐỘ XE — LOS SANTOS CUSTOMS"
			end
			if not promptVisible then
				setPanelOpen(false)
			end
		elseif kind == "menu" then
			currentBay = tonumber(payload.bay) or currentBay
			refreshPrices(payload.car)
			footer.Text = "[1] [2] [3] chọn dịch vụ   •   [ESC] đóng bảng"
			footer.TextColor3 = Color3.fromRGB(150, 160, 175)
			setPanelOpen(true)
			chip.Visible = false
		elseif kind == "closed" then
			setPanelOpen(false)
			chip.Visible = promptVisible
		elseif kind == "result" then
			local ok = payload.ok == true
			footer.Text = tostring(payload.message or "")
			footer.TextColor3 = if ok then Color3.fromRGB(86, 226, 140) else Color3.fromRGB(255, 118, 108)
			if payload.car then
				refreshPrices(payload.car)
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == Enum.KeyCode.E then
			if promptVisible and not menuOpen then
				remote:FireServer({ action = "open", bay = currentBay })
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			if menuOpen then
				setPanelOpen(false)
				remote:FireServer({ action = "close", bay = currentBay })
			end
		elseif input.KeyCode == Enum.KeyCode.One then
			fireRow("repair")
		elseif input.KeyCode == Enum.KeyCode.Two then
			fireRow("paint")
		elseif input.KeyCode == Enum.KeyCode.Three then
			fireRow("turbo")
		end
	end)

	local function hideOnSeatChange()
		if menuOpen then
			setPanelOpen(false)
		end
	end
	localPlayer.CharacterAdded:Connect(function()
		chip.Visible = false
		setPanelOpen(false)
		hideOnSeatChange()
	end)
end

return LSCustomsUI
