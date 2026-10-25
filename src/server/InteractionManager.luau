--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CityConfig = require(Shared:WaitForChild("CityConfig"))
local CityUtils = require(Shared:WaitForChild("CityUtils"))
local CitySimulation = require(script.Parent:WaitForChild("CitySimulation"))

local InteractionManager = {}

local atmCooldowns: { [number]: number } = {}
local fountainPaletteIdx = 1
local timePresetIdx = 1
local aptLightIdx = 1
local playerSpawnedCars: { [number]: Model } = {}

local FOUNTAIN_COLORS = {
	{ name = "Xanh Ngọc Biển", col = Color3.fromRGB(34, 211, 238) },
	{ name = "Hồng Anh Đào", col = Color3.fromRGB(244, 114, 182) },
	{ name = "Vàng Hoàng Kim", col = Color3.fromRGB(250, 204, 21) },
	{ name = "Tím Ngân Hà", col = Color3.fromRGB(168, 85, 247) },
}

local TIME_PRESETS = {
	{ name = "Đêm Thành Phố Neon (21:30)", clock = 21.5 },
	{ name = "Ban Ngày Nắng Đẹp (10:30)", clock = 10.5 },
	{ name = "Hoàng Hôn Rực Rỡ (17:45)", clock = 17.8 },
}

local APT_LIGHT_COLORS = {
	{ name = "Tím Chill Cyber", col = Color3.fromRGB(192, 132, 252) },
	{ name = "Xanh Ngọc Lục Bảo", col = Color3.fromRGB(52, 211, 153) },
	{ name = "Trắng Ấm Gia Đình", col = Color3.fromRGB(255, 240, 205) },
}

local function getCash(player: Player): number
	return tonumber(player:GetAttribute("Cash")) or 0
end

local function addCash(player: Player, delta: number)
	local nextVal = math.max(0, getCash(player) + delta)
	player:SetAttribute("Cash", nextVal)
	local ls = player:FindFirstChild("leaderstats")
	local cashObj = if ls then ls:FindFirstChild("Tiền ($)") else nil
	if cashObj and cashObj:IsA("IntValue") then
		cashObj.Value = nextVal
	end
end

local function notify(notifyRemote: RemoteEvent, player: Player, kind: string, title: string, body: string, extra: any?)
	notifyRemote:FireClient(player, {
		kind = kind,
		title = title,
		body = body,
		extra = extra,
	})
end

local function giveDrinkTool(player: Player, itemInfo: any, notifyRemote: RemoteEvent)
	local tool = Instance.new("Tool")
	tool.Name = itemInfo.name
	tool.ToolTip = itemInfo.desc
	tool.GripPos = Vector3.new(0, -0.35, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(1.35, 0.9, 0.9)
	handle.CFrame = CFrame.Angles(0, 0, math.rad(90))
	handle.Color = itemInfo.color
	handle.Material = Enum.Material.SmoothPlastic
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = tool

	local straw = Instance.new("Part")
	straw.Name = "Straw"
	straw.Size = Vector3.new(0.14, 0.9, 0.14)
	straw.Color = Color3.fromRGB(245, 245, 250)
	straw.CanCollide = false
	straw.Massless = true
	straw.CFrame = handle.CFrame * CFrame.new(0.65, 0.15, 0)
	straw.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = straw
	weld.Parent = handle

	local used = false
	tool.Activated:Connect(function()
		if used then
			return
		end
		local char = tool.Parent
		local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		if not hum then
			return
		end
		used = true
		hum.Health = hum.MaxHealth
		player:SetAttribute("SpeedBoostValue", itemInfo.speedBoost)
		player:SetAttribute("SpeedBoostUntil", os.clock() + itemInfo.duration)
		hum.WalkSpeed = itemInfo.speedBoost

		notify(
			notifyRemote,
			player,
			"success",
			"⚡ Đã thưởng thức " .. itemInfo.name,
			string.format("Tốc độ chạy tăng lên %d trong %d giây!", itemInfo.speedBoost, itemInfo.duration)
		)
		task.delay(itemInfo.duration, function()
			if player.Parent and (tonumber(player:GetAttribute("SpeedBoostUntil")) or 0) <= os.clock() + 0.1 then
				player:SetAttribute("SpeedBoostValue", 0)
				local c = player.Character
				local h = if c then c:FindFirstChildOfClass("Humanoid") else nil
				if h and h.WalkSpeed > 16 then
					h.WalkSpeed = 16
				end
			end
		end)
		tool:Destroy()
	end)

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		tool.Parent = backpack
	end
end

local function attachNeonTrail(player: Player)
	local char = player.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
	if not hrp or not hrp:IsA("BasePart") then
		return
	end
	local existing = hrp:FindFirstChild("CyberArcadeTrail")
	if existing then
		existing:Destroy()
	end

	local a0 = Instance.new("Attachment")
	a0.Name = "TrailTop"
	a0.Position = Vector3.new(0, 1.2, 0)
	a0.Parent = hrp

	local a1 = Instance.new("Attachment")
	a1.Name = "TrailBottom"
	a1.Position = Vector3.new(0, -1.2, 0)
	a1.Parent = hrp

	local trail = Instance.new("Trail")
	trail.Name = "CyberArcadeTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.65
	trail.LightEmission = 1
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 211, 238)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(232, 121, 249)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(250, 204, 21)),
	})
	trail.Transparency = NumberSequence.new(0.1, 1)
	trail.Parent = hrp
end

function InteractionManager.start(notifyRemote: RemoteEvent)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if not CollectionService:HasTag(prompt, CityConfig.PromptTag) then
			return
		end

		local actionType = tostring(prompt:GetAttribute("ActionType") or "")

		if actionType == "UseATM" then
			local now = os.clock()
			local nextAllowed = atmCooldowns[player.UserId] or 0
			if now < nextAllowed then
				local remain = math.ceil(nextAllowed - now)
				notify(
					notifyRemote,
					player,
					"warn",
					"🏦 ATM Neo Bank",
					string.format("Bạn vừa rút trợ cấp rồi! Vui lòng quay lại sau %d giây.", remain)
				)
				return
			end
			atmCooldowns[player.UserId] = now + 35
			addCash(player, 150)
			notify(
				notifyRemote,
				player,
				"cash",
				"💵 Rút Tiền Thành Công (+$150)",
				"Bạn đã nhận $150 trợ cấp công dân Thành Phố Ánh Sáng!"
			)

		elseif actionType == "BuyItem" then
			local itemId = tostring(prompt:GetAttribute("ItemId") or "")
			local itemInfo = (CityConfig.Items :: any)[itemId]
			if not itemInfo then
				return
			end
			if getCash(player) < itemInfo.price then
				notify(
					notifyRemote,
					player,
					"warn",
					"Không đủ tiền mặt",
					string.format("Món %s có giá $%d. Hãy ghé ATM hoặc đi giao Pizza nhé!", itemInfo.name, itemInfo.price)
				)
				return
			end
			addCash(player, -itemInfo.price)
			giveDrinkTool(player, itemInfo, notifyRemote)
			notify(
				notifyRemote,
				player,
				"success",
				"🥤 Đã mua " .. itemInfo.name,
				"Món đồ đã vào Balo (phím 1-9) — cầm lên và nhấp chuột để uống tăng tốc!"
			)

		elseif actionType == "StartDelivery" then
			local currentTarget = player:GetAttribute("DeliveryTargetId")
			if type(currentTarget) == "string" and currentTarget ~= "" then
				notify(
					notifyRemote,
					player,
					"info",
					"📦 Đang có đơn hàng!",
					"Hãy giao đơn hiện tại tới: " .. tostring(player:GetAttribute("DeliveryTargetName"))
				)
				return
			end
			local targets = CityConfig.DeliveryTargets
			local chosen = targets[math.random(1, #targets)]
			player:SetAttribute("DeliveryTargetId", chosen.id)
			player:SetAttribute("DeliveryTargetName", chosen.name)
			player:SetAttribute("DeliveryReward", chosen.reward)
			player:SetAttribute("DeliveryTargetPos", chosen.position)

			notify(
				notifyRemote,
				player,
				"quest",
				"🍕 Đơn Giao Hàng Mới!",
				string.format("Giao tới %s để nhận thưởng $%d! (Đã bật điểm chỉ đường trên màn hình)", chosen.name, chosen.reward)
			)

		elseif actionType == "DeliverOrder" then
			local pointId = tostring(prompt:GetAttribute("TargetId") or "")
			local activeId = tostring(player:GetAttribute("DeliveryTargetId") or "")
			if activeId == "" then
				notify(
					notifyRemote,
					player,
					"info",
					"Chưa nhận đơn hàng",
					"Hãy ghé tiệm Pizza Hot & 24/7 Mart ở Phố Thương Mại để nhận đơn giao hàng nhé!"
				)
				return
			end
			if activeId ~= pointId then
				notify(
					notifyRemote,
					player,
					"warn",
					"Nhầm địa chỉ giao hàng!",
					"Đơn hiện tại cần giao tới: " .. tostring(player:GetAttribute("DeliveryTargetName"))
				)
				return
			end
			local baseReward = tonumber(player:GetAttribute("DeliveryReward")) or 90
			local streak = (tonumber(player:GetAttribute("DeliveryStreak")) or 0) + 1
			local bonus = math.min((streak - 1) * 15, 60)
			local total = baseReward + bonus

			player:SetAttribute("DeliveryStreak", streak)
			player:SetAttribute("DeliveryTargetId", "")
			player:SetAttribute("DeliveryTargetName", "")
			addCash(player, total)

			notify(
				notifyRemote,
				player,
				"cash",
				string.format("🎉 Giao Hàng Xuất Sắc! (+$%d)", total),
				string.format("Chuỗi giao hàng liên tiếp x%d! Ghé Pizza Hot để nhận chuyến tiếp theo.", streak)
			)

		elseif actionType == "SpawnVehicle" then
			local cityRoot = workspace:FindFirstChild(CityConfig.CityFolderName)
			local vehiclesFolder = if cityRoot then cityRoot:FindFirstChild("Vehicles") else workspace
			local oldCar = playerSpawnedCars[player.UserId]
			if oldCar and oldCar.Parent then
				oldCar:Destroy()
			end

			local style = tostring(prompt:GetAttribute("CarStyle") or "RedSport")
			local carColor = if style == "CyanCyber"
				then Color3.fromRGB(14, 165, 233)
				else Color3.fromRGB(225, 38, 52)

			local spawnCf = CFrame.lookAt(Vector3.new(102, 0.6, 8), Vector3.new(40, 0.6, 8))
			local newCar = CityUtils.buildVehicleModel(
				vehiclesFolder or workspace,
				spawnCf,
				carColor,
				player.Name .. "_Car"
			)
			playerSpawnedCars[player.UserId] = newCar
			CitySimulation.setupVehicle(newCar)

			local char = player.Character
			local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
			local seat = newCar:FindFirstChild("DriverSeat")
			if hum and seat and seat:IsA("VehicleSeat") then
				seat:Sit(hum)
			end

			notify(
				notifyRemote,
				player,
				"success",
				"🏎️ Đã gọi xe thành công!",
				"Dùng phím W / A / S / D để lái xe dạo quanh đại lộ Thành Phố Ánh Sáng!"
			)

		elseif actionType == "UseElevator" then
			local char = player.Character
			local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
			if hrp and hrp:IsA("BasePart") then
				local dx = tonumber(prompt:GetAttribute("DestX")) or 0
				local dy = tonumber(prompt:GetAttribute("DestY")) or 5
				local dz = tonumber(prompt:GetAttribute("DestZ")) or 0
				local label = tostring(prompt:GetAttribute("Label") or "Tầng mới")
				hrp.CFrame = CFrame.new(dx, dy, dz)
				notify(notifyRemote, player, "info", "🛗 Thang Máy SkyTower", "Đã di chuyển tới: " .. label)
			end

		elseif actionType == "SkyLaunch" then
			local char = player.Character
			local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
			if hrp and hrp:IsA("BasePart") then
				local att = Instance.new("Attachment")
				att.Parent = hrp
				local lv = Instance.new("LinearVelocity")
				lv.Attachment0 = att
				lv.MaxForce = 95000
				lv.VectorVelocity = Vector3.new(46, 52, 46)
				lv.Parent = hrp

				task.delay(0.65, function()
					if lv.Parent then
						-- Chế độ lượn dù êm ái ngắm toàn thành phố
						lv.VectorVelocity = Vector3.new(26, -7.5, 26)
					end
				end)
				task.delay(7.5, function()
					if lv.Parent then
						lv:Destroy()
					end
					if att.Parent then
						att:Destroy()
					end
				end)
				notify(
					notifyRemote,
					player,
					"success",
					"🪂 Đang Bay Dù Lượn Ngắm Thành Phố!",
					"Tận hưởng góc nhìn toàn cảnh từ đỉnh SkyTower xuống Vịnh Biển!"
				)
			end

		elseif actionType == "CycleTime" then
			local preset = TIME_PRESETS[timePresetIdx]
			timePresetIdx = (timePresetIdx % #TIME_PRESETS) + 1
			Lighting.ClockTime = preset.clock
			CitySimulation.updateNightLights()
			notify(
				notifyRemote,
				player,
				"info",
				"🌤️ Đã chuyển bầu trời thành phố",
				"Thời gian hiện tại: " .. preset.name
			)

		elseif actionType == "FountainWish" then
			fountainPaletteIdx = (fountainPaletteIdx % #FOUNTAIN_COLORS) + 1
			local choice = FOUNTAIN_COLORS[fountainPaletteIdx]
			local fountainModel = if prompt.Parent then prompt.Parent.Parent else nil
			if fountainModel then
				local water = fountainModel:FindFirstChild("FountainWater")
				local crystal = fountainModel:FindFirstChild("FountainCrystal")
				if water and water:IsA("BasePart") then
					water.Color = choice.col
				end
				if crystal and crystal:IsA("BasePart") then
					crystal.Color = choice.col
					local pl = crystal:FindFirstChildOfClass("PointLight")
					if pl then
						pl.Color = choice.col
					end
				end
			end
			addCash(player, 20)
			notify(
				notifyRemote,
				player,
				"cash",
				"⛲ Ước Nguyện Đài Phun Nước (+$20)",
				"Đài phun nước đã chuyển sang sắc màu: " .. choice.name
			)

		elseif actionType == "ToggleDoor" then
			local door = prompt.Parent
			if door and door:IsA("BasePart") then
				local closedPos = door:GetAttribute("ClosedPos")
				if typeof(closedPos) ~= "Vector3" then
					closedPos = door.Position
					door:SetAttribute("ClosedPos", closedPos)
				end
				local isOpen = door:GetAttribute("IsOpen") == true
				local targetPos = if isOpen then closedPos else (closedPos + Vector3.new(8.2, 0, 0))
				door:SetAttribute("IsOpen", not isOpen)
				TweenService:Create(door, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = targetPos,
				}):Play()
			end

		elseif actionType == "ToggleAptLight" then
			local choice = APT_LIGHT_COLORS[aptLightIdx]
			aptLightIdx = (aptLightIdx % #APT_LIGHT_COLORS) + 1
			local aptModel = if prompt.Parent then prompt.Parent.Parent else nil
			if aptModel then
				local lamp = aptModel:FindFirstChild("CeilingLight")
				if lamp and lamp:IsA("BasePart") then
					lamp.Color = choice.col
					local pl = lamp:FindFirstChildOfClass("PointLight")
					if pl then
						pl.Color = choice.col
					end
				end
			end
			notify(notifyRemote, player, "info", "🏠 Nhà Thông Minh Lumina", "Đèn phòng khách: " .. choice.name)

		elseif actionType == "PlayArcade" then
			if getCash(player) < 20 then
				notify(notifyRemote, player, "warn", "Cần $20 xu Arcade", "Hãy ghé ATM rút trợ cấp để chơi nhé!")
				return
			end
			addCash(player, -20)
			local roll = math.random(1, 100)
			attachNeonTrail(player)
			if roll >= 65 then
				addCash(player, 90)
				notify(
					notifyRemote,
					player,
					"cash",
					"🎰 JACKPOT CYBER ARCADE! (+$90)",
					"Bạn vừa trúng giải lớn và nhận hiệu ứng Hào Quang Neon rực rỡ!"
				)
			else
				addCash(player, 25)
				notify(
					notifyRemote,
					player,
					"success",
					"🕹️ Thắng giải Arcade! (+$25)",
					"Đã kích hoạt hiệu ứng Hào Quang Neon đa sắc sau lưng nhân vật!"
				)
			end

		elseif actionType == "NitroBoost" then
			local foundCar: Model? = nil
			local char = player.Character
			local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
			if hum and hum.SeatPart and hum.SeatPart.Parent and hum.SeatPart.Parent:IsA("Model") then
				foundCar = hum.SeatPart.Parent
			else
				foundCar = playerSpawnedCars[player.UserId]
			end
			if foundCar and foundCar.Parent then
				foundCar:SetAttribute("NitroUntil", os.clock() + 45)
				notify(
					notifyRemote,
					player,
					"success",
					"🔥 Đã Nạp Nhiên Liệu NITRO!",
					"Tốc độ tối đa xe của bạn tăng lên 96 trong 45 giây!"
				)
			elseif hum then
				hum.WalkSpeed = 28
				task.delay(25, function()
					if hum.Parent and hum.WalkSpeed == 28 then
						hum.WalkSpeed = 16
					end
				end)
				notify(
					notifyRemote,
					player,
					"success",
					"⚡ Năng Lượng Petro Metro!",
					"Tăng tốc độ chạy bộ trong 25 giây! (Hãy lái xe vào trạm để nạp Nitro cho xe)"
				)
			end

		elseif actionType == "HealPlayer" then
			local char = player.Character
			local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
			if hum then
				hum.Health = hum.MaxHealth
				notify(
					notifyRemote,
					player,
					"success",
					"💚 Bệnh Viện Đa Khoa Metro",
					"Sức khoẻ & thể lực của bạn đã được hồi phục 100%!"
				)
			end

		elseif actionType == "NpcTalk" then
			local npcId = tostring(prompt:GetAttribute("NpcId") or "")
			local dlg = (CityConfig.NpcDialogues :: any)[npcId]
			if dlg then
				notify(
					notifyRemote,
					player,
					"dialogue",
					dlg.title,
					table.concat(dlg.lines, "\n")
				)
			end
		end
	end)
end

return InteractionManager
