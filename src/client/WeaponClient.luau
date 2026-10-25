--!strict
--[[
	WeaponClient.luau
	Tâm ngắm chấm trắng chuẩn GTA V + Bắn tia đạn Tracer + Hiệu ứng nháy tâm khi bắn trúng / bắn vỡ khối!
	(Giữ nguyên quy tắc MÁU ẨN: tuyệt đối không hiện thanh máu thô trên gạch đá/xe).
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local WeaponClient = {}

local function drawLocalTracer(startPos: Vector3, endPos: Vector3, color: Color3?, thick: number?)
	local dist = (endPos - startPos).Magnitude
	if dist < 0.5 then
		return
	end
	local beam = Instance.new("Part")
	beam.Name = "BulletTracer"
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = color or Color3.fromRGB(255, 214, 102)
	beam.Transparency = 0.25
	local t = thick or 0.09
	beam.Size = Vector3.new(t, t, dist)
	beam.CFrame = CFrame.lookAt((startPos + endPos) * 0.5, endPos)
	beam.Parent = Workspace
	Debris:AddItem(beam, 0.055)
end

function WeaponClient.mount(localPlayer: Player, fireRemote: RemoteEvent)
	local mouse = localPlayer:GetMouse()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local reticleGui = Instance.new("ScreenGui")
	reticleGui.Name = "GtaWeaponReticle"
	reticleGui.ResetOnSpawn = false
	reticleGui.IgnoreGuiInset = true
	reticleGui.Parent = playerGui

	-- Tâm ngắm chấm trắng nhỏ gọn chuẩn GTA V (bám theo vị trí trỏ chuột khi cầm súng)
	local dot = Instance.new("Frame")
	dot.Name = "AimDot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.fromOffset(6, 6)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.Visible = false
	dot.Parent = reticleGui
	local dCorner = Instance.new("UICorner")
	dCorner.CornerRadius = UDim.new(1, 0)
	dCorner.Parent = dot
	local dStroke = Instance.new("UIStroke")
	dStroke.Color = Color3.fromRGB(0, 0, 0)
	dStroke.Thickness = 1.5
	dStroke.Parent = dot

	-- Nháy dấu '×' mảnh khi đạn trúng Part có máu ẩn (Đỏ rực khi viên đạn đó làm VỠ TUNG khối!)
	local hitTick = Instance.new("TextLabel")
	hitTick.AnchorPoint = Vector2.new(0.5, 0.5)
	hitTick.Position = UDim2.fromScale(0.5, 0.5)
	hitTick.Size = UDim2.fromOffset(22, 22)
	hitTick.BackgroundTransparency = 1
	hitTick.Font = Enum.Font.GothamBlack
	hitTick.TextSize = 16
	hitTick.Text = "×"
	hitTick.TextTransparency = 1
	hitTick.TextStrokeTransparency = 1
	hitTick.Parent = dot

	local tickToken = 0
	fireRemote.OnClientEvent:Connect(function(evt, shattered)
		if evt == "hit" then
			tickToken += 1
			local myT = tickToken
			hitTick.TextColor3 = if shattered
				then Color3.fromRGB(248, 62, 62)
				else Color3.fromRGB(248, 250, 252)
			hitTick.TextSize = if shattered then 21 else 15
			hitTick.TextTransparency = 0
			hitTick.TextStrokeTransparency = 0.25
			task.delay(0.14, function()
				if tickToken == myT then
					hitTick.TextTransparency = 1
					hitTick.TextStrokeTransparency = 1
				end
			end)
		end
	end)

	local holdingTrigger = false
	local lastLocalShot = 0

	local function getEquippedGtaWeapon(): Tool?
		local char = localPlayer.Character
		if not char then
			return nil
		end
		local tool = char:FindFirstChildOfClass("Tool")
		if tool and tool:GetAttribute("IsGtaWeapon") == true then
			return tool
		end
		return nil
	end

	local function uiBlocksCombat(): boolean
		if localPlayer:GetAttribute("WeaponWheelOpen") == true then
			return true
		end
		if localPlayer:GetAttribute("UIMenuOpen") == true then
			return true
		end
		local char = localPlayer.Character
		local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		if hum and hum.SeatPart then
			return true -- đang lái xe thì không bắn
		end
		return false
	end

	local function tryFireOnce(tool: Tool)
		if uiBlocksCombat() then
			return
		end
		local cd = tonumber(tool:GetAttribute("FireCooldown")) or 0.16
		local now = os.clock()
		if now - lastLocalShot < cd then
			return
		end
		lastLocalShot = now

		local muzzle = tool:FindFirstChild("Muzzle") :: BasePart?
		local handle = tool:FindFirstChild("Handle") :: BasePart?
		local origin = if muzzle then muzzle.Position elseif handle then handle.Position else nil
		if not origin then
			return
		end

		local targetPos = mouse.Hit.Position
		local dir = targetPos - origin
		if dir.Magnitude < 0.1 then
			return
		end

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local char = localPlayer.Character
		params.FilterDescendantsInstances = if char then { char } else {}
		local isMelee = tool:GetAttribute("IsMelee") == true
		local pellets = math.max(1, tonumber(tool:GetAttribute("Pellets")) or 1)

		-- RPG: KHÔNG vẽ tia hitscan (rocket bay 145 stud/s, server tự dựng part bay + vệt lửa)
		if tool:GetAttribute("IsExplosive") == true then
			local flash = Instance.new("Part")
			flash.Name = "RpgMuzzleFlash"
			flash.Shape = Enum.PartType.Ball
			flash.Size = Vector3.new(2.4, 2.4, 2.4)
			flash.Color = Color3.fromRGB(255, 214, 140)
			flash.Material = Enum.Material.Neon
			flash.CanCollide = false
			flash.CanTouch = false
			flash.CanQuery = false
			flash.Transparency = 0.35
			flash.CFrame = CFrame.new(origin + dir.Unit * 2.2)
			flash.Parent = Workspace
			Debris:AddItem(flash, 0.1)
			fireRemote:FireServer(origin, targetPos)
			return
		end

		if isMelee then
			-- Cận chiến: vệt chớp ngắn màu trắng thay cho tia đạn
			local res = Workspace:Raycast(origin, dir.Unit * 7, params)
			local endPt = if res then res.Position else (origin + dir.Unit * 5)
			drawLocalTracer(origin, endPt, Color3.fromRGB(226, 232, 240), 0.16)
			fireRemote:FireServer(origin, targetPos)
			return
		end

		local res = Workspace:Raycast(origin, dir.Unit * 350, params)
		local endPt = if res then res.Position else (origin + dir.Unit * 180)

		if pellets > 1 then
			-- SHOTGUN: vẽ 3 tia loe nhẹ cho cảm giác tản đạn (server vẫn bắn đủ 8 viên)
			for i = -1, 1 do
				local spreadDir = (dir.Unit + Vector3.new(0.035 * i, 0.02 * math.abs(i), 0) + Vector3.new(
					math.random() - 0.5,
					math.random() - 0.5,
					math.random() - 0.5
				) * 0.03).Unit
				local r = Workspace:Raycast(origin, spreadDir * 150, params)
				local e = if r then r.Position else (origin + spreadDir * 120)
				drawLocalTracer(origin, e, Color3.fromRGB(255, 196, 120), 0.12)
			end
		else
			drawLocalTracer(origin, endPt)
		end
		fireRemote:FireServer(origin, targetPos)
	end

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local tool = getEquippedGtaWeapon()
			if tool then
				holdingTrigger = true
				tryFireOnce(tool)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingTrigger = false
		end
	end)

	-- TỐI ƯU: cache vũ khí đang trang bị (trước đây dò Character mỗi frame)
	local cachedWeapon: Tool? = nil
	local weaponDirty = true

	local function refreshWeaponCache()
		weaponDirty = false
		local char = localPlayer.Character
		cachedWeapon = if char then getEquippedGtaWeapon() else nil
	end

	localPlayer.CharacterAdded:Connect(function(char)
		weaponDirty = true
		char.ChildAdded:Connect(function(ch)
			if ch:IsA("Tool") then
				weaponDirty = true
			end
		end)
		char.ChildRemoved:Connect(function(ch)
			if ch:IsA("Tool") then
				weaponDirty = true
			end
		end)
	end)

	RunService.RenderStepped:Connect(function()
		if weaponDirty or (cachedWeapon ~= nil and cachedWeapon.Parent == nil) then
			refreshWeaponCache()
		end
		local tool = cachedWeapon
		if tool then
			local loc = UserInputService:GetMouseLocation()
			dot.Position = UDim2.fromOffset(loc.X, loc.Y)
			dot.Visible = true
			if holdingTrigger and tool:GetAttribute("AutoFire") == true then
				tryFireOnce(tool)
			end
		else
			dot.Visible = false
			holdingTrigger = false
		end
	end)
end

return WeaponClient
