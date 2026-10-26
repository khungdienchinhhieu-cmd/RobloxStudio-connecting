--!strict
--[[
	ServiceManager.luau  (Sync v25 — MỖI CÔNG TRÌNH ĐỀU CÓ CHỨC NĂNG)
	================================================================================
	Đọc bảng `BuildingServices` rồi dựng **quầy dịch vụ thật** trong thành phố:

	    ┌────────────┐
	    │  🔧  LOS SANTOS CUSTOMS   │   ← biển hiệu BillboardGui (luôn hướng camera)
	    │  Sửa xe  [$250]           │
	    └────────────┘
	         ║ cột sáng chỉ đường (neon, xuyên tường)
	      ▓▓▓▓▓▓▓  ← tấm đế phát sáng trên vỉa hè
	      [E] Sửa xe [$250]              ← ProximityPrompt

	• Ô đất CHƯA có công trình thì không dựng quầy (tránh quầy lơ lửng giữa bãi đất).
	• Khi agent dựng xong module của ô đó, gọi `ServiceManager.refresh()` là quầy tự bật.
	• Mỗi lượt dùng có cooldown 1,5 giây/người để không spam remote.

	Tiền: `player:GetAttribute("Cash")` (đồng bộ với leaderstats.Cash).
	Ngân hàng: `player:GetAttribute("Bank")`.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = Shared:WaitForChild("World")
local BuildingServices = require(World:WaitForChild("BuildingServices"))
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))

local ServiceManager = {}

local hudRemote: RemoteEvent? = nil
local counters: { [string]: Model } = {}
local lastUse: { [Player]: { [string]: number } } = {}
local COOLDOWN = 1.5

-- ══════════════════════════════════════════════════════════════════════════════
-- TIỆN ÍCH
-- ══════════════════════════════════════════════════════════════════════════════

local function cash(player: Player): number
	return tonumber(player:GetAttribute("Cash")) or 0
end

local function setCash(player: Player, value: number)
	local v = math.max(0, math.floor(value))
	player:SetAttribute("Cash", v)
	local ls = player:FindFirstChild("leaderstats")
	local cs = ls and ls:FindFirstChild("Cash")
	if cs and cs:IsA("IntValue") then
		cs.Value = v
	end
end

local function bank(player: Player): number
	return tonumber(player:GetAttribute("Bank")) or 0
end

local function setBank(player: Player, value: number)
	player:SetAttribute("Bank", math.max(0, math.floor(value)))
end

local function toast(player: Player, message: string, color: Color3?)
	if hudRemote then
		hudRemote:FireClient(player, {
			message = message,
			color = color or Color3.fromRGB(114, 204, 114),
		})
	end
end

local function humanoidOf(player: Player): Humanoid?
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChildOfClass("Humanoid")
end

local function header(player: Player): string
	return string.format("[Dịch vụ] %s · 💵 $%d · 🏦 $%d", player.Name, cash(player), bank(player))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- XE: TÌM XE GẦN NHẤT + SỬA
-- ══════════════════════════════════════════════════════════════════════════════

local function nearestCar(player: Player, maxDist: number): Model?
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return nil
	end
	-- Xe người chơi đang ngồi?
	local seat = char:FindFirstChildOfClass("Humanoid") and char.Humanoid.SeatPart
	if seat then
		local car = seat:FindFirstAncestorOfClass("Model")
		if car and car:GetAttribute("IsGtaVehicle") == true then
			return car
		end
	end
	-- Quét bán kính quanh người chơi
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local parts = Workspace:GetPartBoundsInRadius(hrp.Position, maxDist, params)
	local best: Model? = nil
	local bestD = maxDist
	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model:GetAttribute("IsGtaVehicle") == true then
			local chassis = model:FindFirstChild("Chassis")
			if chassis and chassis:IsA("BasePart") then
				local d = (chassis.Position - hrp.Position).Magnitude
				if d <= bestD then
					bestD = d
					best = model
				end
			end
		end
	end
	return best
end

local function repairCar(car: Model): number
	local fixed = 0
	for _, d in ipairs(car:GetDescendants()) do
		local maxH = d:GetAttribute("MaxPartHealth")
		if typeof(maxH) == "number" then
			d:SetAttribute("PartHealth", maxH)
			d:SetAttribute("Integrity", maxH)
			fixed += 1
		end
	end
	local maxEngine = car:GetAttribute("MaxEngineHealth")
	if typeof(maxEngine) == "number" then
		car:SetAttribute("EngineHealth", maxEngine)
	end
	car:SetAttribute("_Exploded", false)
	for _, d in ipairs(car:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("Scorched") == true then
			d:SetAttribute("Scorched", false)
		end
	end
	return fixed
end

-- ══════════════════════════════════════════════════════════════════════════════
-- VŨ KHÍ (do WeaponManager cung cấp, gắn sau khi init để tránh require vòng)
-- ══════════════════════════════════════════════════════════════════════════════

local weaponApi: any = nil
local vehicleApi: any = nil

function ServiceManager.bind(weapons: any, vehicles: any)
	weaponApi = weapons
	vehicleApi = vehicles
end

-- ══════════════════════════════════════════════════════════════════════════════
-- THỰC THI DỊCH VỤ
-- ══════════════════════════════════════════════════════════════════════════════

local function grantAmmo(player: Player)
	if weaponApi and weaponApi.refillAmmo then
		weaponApi.refillAmmo(player)
	end
end

--- Chạy một dịch vụ. Trả về true nếu đã trừ tiền & thực thi thành công.
local function runService(player: Player, service: any): boolean
	local kind = service.kind
	local hum = humanoidOf(player)

	if kind == "REPAIR_CAR" then
		local car = nearestCar(player, 34)
		if not car then
			toast(player, "Không có xe nào quanh đây để sửa.", Color3.fromRGB(239, 68, 68))
			return false
		end
		if cash(player) < service.price then
			toast(player, "Không đủ tiền! Cần $" .. tostring(service.price), Color3.fromRGB(239, 68, 68))
			return false
		end
		setCash(player, cash(player) - service.price)
		local n = repairCar(car)
		toast(player, string.format("🔧 Đã sửa %s (%d chi tiết) — trừ $%d", car.Name, n, service.price))
		return true
	end

	if kind == "SPAWN_CAR" then
		if cash(player) < service.price then
			toast(player, "Không đủ tiền! Cần $" .. tostring(service.price), Color3.fromRGB(239, 68, 68))
			return false
		end
		if vehicleApi and vehicleApi.spawnForPlayer then
			local car = vehicleApi.spawnForPlayer(player)
			if not car then
				toast(player, "Không đủ chỗ để giao xe — ra bãi trống nhé.", Color3.fromRGB(239, 68, 68))
				return false
			end
			setCash(player, cash(player) - service.price)
			toast(player, string.format("🚗 Đã giao %s — trừ $%d", car.Name, service.price))
			return true
		end
		return false
	end

	if kind == "HEAL" or kind == "HEAL_FULL" or kind == "CINEMA" then
		if cash(player) < service.price then
			toast(player, "Không đủ tiền! Cần $" .. tostring(service.price), Color3.fromRGB(239, 68, 68))
			return false
		end
		if not hum then
			return false
		end
		setCash(player, cash(player) - service.price)
		if kind == "HEAL" then
			local add = if service.id == "E3_FOOD" then 50 else 35
			hum.Health = math.min(hum.MaxHealth, hum.Health + add)
			toast(player, string.format("%s +%d máu", service.icon, add))
		else
			hum.Health = hum.MaxHealth
			player:SetAttribute("Armor", 100)
			toast(player, string.format("%s Hồi đầy máu + giáp", service.icon))
		end
		if kind == "CINEMA" then
			task.delay(3, function()
				if player.Parent then
					setCash(player, cash(player) + 150)
					toast(player, "🎬 Hết phim — cát-xê $150 đã vào ví.", Color3.fromRGB(250, 204, 21))
				end
			end)
		end
		return true
	end

	if kind == "ARMOR" then
		if cash(player) < service.price then
			toast(player, "Không đủ tiền! Cần $" .. tostring(service.price), Color3.fromRGB(239, 68, 68))
			return false
		end
		setCash(player, cash(player) - service.price)
		player:SetAttribute("Armor", 100)
		if service.id == "E4_MALL" then
			grantAmmo(player)
			toast(player, "🛍️ Combo: đầy giáp + đầy đạn dự phòng")
		else
			toast(player, "🛡️ Đã nạp đầy 100% giáp")
		end
		return true
	end

	if kind == "AMMO" then
		if cash(player) < service.price then
			toast(player, "Không đủ tiền! Cần $" .. tostring(service.price), Color3.fromRGB(239, 68, 68))
			return false
		end
		setCash(player, cash(player) - service.price)
		grantAmmo(player)
		toast(player, "📦 Đã nạp đầy đạn dự phòng cho mọi súng")
		return true
	end

	if kind == "CLEAR_WANTED" then
		local stars = tonumber(player:GetAttribute("WantedLevel")) or 0
		if stars <= 0 then
			toast(player, "Bạn không có án nào để nộp.", Color3.fromRGB(148, 163, 184))
			return false
		end
		local cost = service.price * stars
		if cash(player) < cost then
			toast(player, string.format("Cần $%d để xoá %d sao truy nã.", cost, stars), Color3.fromRGB(239, 68, 68))
			return false
		end
		setCash(player, cash(player) - cost)
		player:SetAttribute("WantedLevel", 0)
		toast(player, string.format("🚔 Đã nộp phạt $%d — xoá %d sao truy nã", cost, stars))
		return true
	end

	if kind == "UNLOCK_WEAPON" then
		local stars = tonumber(player:GetAttribute("WantedLevel")) or 0
		if stars > 0 then
			toast(player, "Kho vũ khí chỉ cấp cho người sạch án. Xoá sao trước!", Color3.fromRGB(239, 68, 68))
			return false
		end
		if weaponApi and weaponApi.grantWeapon then
			weaponApi.grantWeapon(player, "Carbine Rifle")
			toast(player, "🎖️ Đã cấp Carbine Rifle + đầy đạn", Color3.fromRGB(96, 165, 250))
			return true
		end
		return false
	end

	if kind == "BANK_DEPOSIT" then
		if cash(player) < service.price then
			toast(player, "Không đủ tiền mặt để gửi.", Color3.fromRGB(239, 68, 68))
			return false
		end
		setCash(player, cash(player) - service.price)
		setBank(player, bank(player) + service.price)
		toast(player, string.format("🏦 Đã gửi $%d — tài khoản: $%d", service.price, bank(player)))
		return true
	end

	if kind == "BANK_WITHDRAW" then
		if bank(player) < service.price then
			toast(player, "Tài khoản không đủ $500.", Color3.fromRGB(239, 68, 68))
			return false
		end
		setBank(player, bank(player) - service.price)
		setCash(player, cash(player) + service.price)
		toast(player, string.format("🏧 Đã rút $%d — tiền mặt: $%d", service.price, cash(player)))
		return true
	end

	return false
end

-- ══════════════════════════════════════════════════════════════════════════════
-- DỰNG QUẦY
-- ══════════════════════════════════════════════════════════════════════════════

local function makePart(name: string, size: Vector3, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

--- Cao độ mặt đỡ thật dưới một điểm (sàn công trình, sân trước, vỉa hè…).
--- v25 đo được: C1 = 1.28 · 24/7 = 1.30 · LSPD = 1.34 · Maze = 1.27 · D1 = 1.37 — KHÔNG phải 1.15.
--- Nếu đặt quầy ở 1.15 thì đế bị chôn dưới sàn công trình; nếu đặt ở 1.40 thì lơ lửng.
local function groundYAt(position: Vector3): number
	local fallback = (WorldGrid :: any).SIDEWALK_TOP_Y or 1.15
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local exclude = {}
	if containerFolder then
		table.insert(exclude, containerFolder)
	end
	params.FilterDescendantsInstances = exclude
	local ok, result = pcall(function()
		return Workspace:Raycast(position + Vector3.new(0, 45, 0), Vector3.new(0, -90, 0), params)
	end)
	if ok and result then
		-- chỉ tin mặt đỡ gần: chênh quá 3 stud so với vỉa hè thì bỏ (tránh ray trúng mái nhà)
		local y = result.Position.Y
		if y > fallback - 1.5 and y < fallback + 3 then
			return y
		end
	end
	return fallback
end

local function buildCounter(service: any, position: Vector3, parent: Instance): Model?
	local root = Instance.new("Model")
	root.Name = "Service_" .. service.id
	root:SetAttribute("ServiceId", service.id)
	root:SetAttribute("PlotId", service.plotId)

	-- Đế bê tông cắm xuống đất: nền ô đất có thể thấp hơn vỉa hè (0.5 vs 1.15)
	-- nên quầy luôn có đế, không bao giờ lơ lửng.
	local plinth = makePart("Plinth", Vector3.new(7.9, 2.6, 7.9), Color3.fromRGB(71, 85, 105), Enum.Material.Concrete)
	plinth.Shape = Enum.PartType.Cylinder
	plinth.CFrame = CFrame.new(position + Vector3.new(0, -1.24, 0)) * CFrame.Angles(0, 0, math.rad(90))
	plinth.CastShadow = false
	plinth.Parent = root

	-- Tấm đế phát sáng (vòng tròn dẹt) — nhìn từ xa biết chỗ tương tác
	local pad = makePart("Pad", Vector3.new(7.5, 0.16, 7.5), Color3.fromRGB(56, 189, 248), Enum.Material.Neon)
	pad.Shape = Enum.PartType.Cylinder
	pad.CFrame = CFrame.new(position + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pad.Transparency = 0.35
	pad.Parent = root

	-- Cột sáng chỉ đường
	local beam = makePart("Beam", Vector3.new(1.2, 58, 1.2), Color3.fromRGB(56, 189, 248), Enum.Material.Neon)
	beam.CFrame = CFrame.new(position + Vector3.new(0, 29, 0))
	beam.Transparency = 0.86
	beam.CastShadow = false
	beam.Parent = root

	-- Trụ biển hiệu
	local post = makePart("SignPost", Vector3.new(0.4, 9, 0.4), Color3.fromRGB(30, 41, 59), Enum.Material.Metal)
	post.CFrame = CFrame.new(position + Vector3.new(0, 4.5, 0))
	post.Parent = root

	local board = makePart("SignBoard", Vector3.new(12, 4.6, 0.35), Color3.fromRGB(15, 23, 42), Enum.Material.SmoothPlastic)
	board.CFrame = CFrame.new(position + Vector3.new(0, 8.4, 0))
	board.Transparency = 0.12
	board.Parent = root

	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(340, 120)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 11.6, 0)
	-- KHÔNG AlwaysOnTop: biển bị tường/mái che như vật thật, không đè lên màn hình khi đứng gần.
	-- MaxDistance 160 (trước 220 + AlwaysOnTop = thẻ che màn hình khi đi qua quầy).
	gui.AlwaysOnTop = false
	gui.MaxDistance = 160
	gui.LightInfluence = 0
	gui.Adornee = board
	gui.Parent = board

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
	frame.BackgroundTransparency = 0.18
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(56, 189, 248)
	stroke.Thickness = 2
	stroke.Transparency = 0.25
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0.5, 0)
	title.Position = UDim2.fromOffset(8, 6)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(226, 232, 240)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = service.icon .. "  " .. service.title
	title.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -16, 0.34, 0)
	sub.Position = UDim2.new(0, 8, 0.5, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 18
	sub.TextColor3 = Color3.fromRGB(148, 197, 255)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Text = service.subtitle
	sub.Parent = frame

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = service.prompt
	prompt.ObjectText = service.title
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad

	prompt.Triggered:Connect(function(player)
		local now = os.clock()
		local perPlayer = lastUse[player]
		if not perPlayer then
			perPlayer = {}
			lastUse[player] = perPlayer
		end
		local last = perPlayer[service.id] or 0
		if now - last < COOLDOWN then
			return
		end
		perPlayer[service.id] = now

		local ok, err = pcall(runService, player, service)
		if not ok then
			warn("[ServiceManager] lỗi dịch vụ", service.id, err)
			toast(player, "Dịch vụ đang gặp sự cố, thử lại sau.", Color3.fromRGB(239, 68, 68))
		end
	end)

	root.PrimaryPart = pad
	root.Parent = parent
	return root
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NHẬN BIẾT Ô ĐẤT ĐÃ CÓ CÔNG TRÌNH CHƯA
-- ══════════════════════════════════════════════════════════════════════════════

local function builtPlots(root: Instance): { [string]: boolean }
	local set: { [string]: boolean } = {}
	local container = root:FindFirstChild("DistrictModules")
	if container then
		for _, model in ipairs(container:GetChildren()) do
			local pid = model:GetAttribute("PlotId")
			if type(pid) == "string" then
				set[pid] = true
			end
		end
	end
	-- Quảng trường Legion (Plot_C2) do CityFoundation dựng sẵn — luôn có mặt
	set["Plot_C2"] = true
	return set
end

-- ══════════════════════════════════════════════════════════════════════════════
-- API
-- ══════════════════════════════════════════════════════════════════════════════

local containerFolder: Folder? = nil
local losSantosRoot: Instance? = nil

function ServiceManager.refresh(root: Instance?)
	if root then
		losSantosRoot = root
	end
	local host = losSantosRoot :: Instance?
	if not host then
		return 0
	end
	if not containerFolder or not containerFolder.Parent then
		local folder = Instance.new("Folder")
		folder.Name = "CityServices"
		folder.Parent = host
		containerFolder = folder
	end
	local folder = containerFolder :: Folder

	local built = builtPlots(host)
	local made = 0
	local skipped = 0

	for _, service in ipairs(BuildingServices.LIST) do
		if counters[service.id] then
			continue
		end
		if not built[service.plotId] then
			skipped += 1
			continue
		end
		local pos = BuildingServices.worldPosition(service)
		if not pos then
			continue
		end
		-- bám đúng mặt sàn thật (sân/nền công trình cao hơn vỉa hè)
		pos = Vector3.new(pos.X, groundYAt(pos), pos.Z)
		local counter = buildCounter(service, pos, folder)
		if counter then
			counters[service.id] = counter
			made += 1
		end
	end

	-- Dọn quầy của công trình vừa bị gỡ
	for id, counter in pairs(counters) do
		if not counter.Parent then
			counters[id] = nil
		end
	end

	print(string.format(
		"[ServiceManager] %d/%d quầy dịch vụ đang hoạt động (+%d mới · bỏ qua %d ô chưa có công trình)",
		ServiceManager.getCount(),
		#BuildingServices.LIST,
		made,
		skipped
	))
	return made
end

function ServiceManager.init(remotes: Instance, hud: RemoteEvent, root: Instance)
	hudRemote = hud
	losSantosRoot = root
	local made = ServiceManager.refresh(root)

	-- Quầy ở các ô đất chưa dựng sẽ tự bật khi agent dựng xong module.
	task.spawn(function()
		while true do
			task.wait(12)
			if losSantosRoot and losSantosRoot.Parent then
				ServiceManager.refresh(nil)
			else
				break
			end
		end
	end)

	return made
end

function ServiceManager.getCount(): number
	local n = 0
	for _ in pairs(counters) do
		n += 1
	end
	return n
end

return ServiceManager
