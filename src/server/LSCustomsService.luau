--!strict
--[[
	LSCustomsService.luau
	================================================================================
	DỊCH VỤ ĐỘ XE LOS SANTOS CUSTOMS (Plot_C1) — CHỨC NĂNG THẬT 100%
	================================================================================
	• Quét liên tục 2 khoang cửa cuốn (`BayZone1` / `BayZone2` do module Plot_C1 dựng).
	• Xe GTA V chạy vào khoang -> đèn neon mặt sàn + đèn cầu ĐỎ chuyển XANH,
	  người chơi nhận gợi ý "[E] ĐỘ XE" (HUD riêng, không dùng ProximityPrompt mặc định).
	• Bảng độ xe cho phép:
	    1) SỬA CHỮA  ($250)  : hồi 100% máu ẩn mọi part + sơn lại màu gốc + đầy EngineHealth.
	    2) SƠN LẠI   ($500)  : đổi màu sơn thân xe theo bảng màu GTA V (lưu lại màu gốc mới).
	    3) TURBO     ($1500) : +8 MaxSpeed mỗi cấp (tối đa 3 cấp) — xe chạy nhanh hơn thật.
	• Trừ tiền qua `Cash` attribute + leaderstats, chống spam bằng cooldown 0.5s.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LSCustomsService = {}

local PRICE_REPAIR = 250
local PRICE_PAINT = 500
local PRICE_TURBO = 1500
local MAX_TURBO_LEVEL = 3
local ACTION_COOLDOWN = 0.5

local PAINT_PALETTE: { Color3 } = {
	Color3.fromRGB(206, 28, 36), -- Rosso Corsa
	Color3.fromRGB(249, 168, 24), -- Sunset Orange
	Color3.fromRGB(247, 214, 58), -- Race Yellow
	Color3.fromRGB(46, 176, 96), -- Emerald Green
	Color3.fromRGB(38, 124, 214), -- Electric Blue
	Color3.fromRGB(140, 78, 210), -- Midnight Purple
	Color3.fromRGB(232, 236, 242), -- Frost White
	Color3.fromRGB(26, 28, 34), -- Matte Black
}

local BODY_ZONES: { [string]: boolean } = {
	Front = true,
	Rear = true,
	Top = true,
	Left = true,
	Right = true,
	Body = true,
}

type BayState = {
	zone: BasePart,
	center: Vector3,
	car: Model?,
	strip: BasePart?,
	lamp: BasePart?,
}

local remotesFolder: Instance? = nil
local hudRemote: RemoteEvent? = nil
local customsRemote: RemoteEvent? = nil
local bays: { BayState } = {}
local lastActionAt: { [Player]: number } = {}
local announced: { [Model]: boolean } = {}

local function findFirst(parent: Instance, name: string): Instance?
	local found = parent:FindFirstChild(name, true)
	return found
end

local function cashOf(player: Player): number
	local ls = player:FindFirstChild("leaderstats")
	local cs = if ls then ls:FindFirstChild("Cash") else nil
	if cs and cs:IsA("IntValue") then
		return cs.Value
	end
	return tonumber(player:GetAttribute("Cash")) or 0
end

local function setCash(player: Player, value: number)
	local clamped = math.max(0, math.floor(value))
	player:SetAttribute("Cash", clamped)
	local ls = player:FindFirstChild("leaderstats")
	local cs = if ls then ls:FindFirstChild("Cash") else nil
	if cs and cs:IsA("IntValue") then
		cs.Value = clamped
	end
end

local function toast(player: Player, message: string, color: Color3)
	local remote = hudRemote
	if remote then
		remote:FireClient(player, { message = message, color = color })
	end
end

local function setBayLights(state: BayState, occupied: boolean)
	local color = if occupied then Color3.fromRGB(46, 224, 128) else Color3.fromRGB(220, 42, 42)
	local strip = state.strip
	if strip then
		strip.Color = color
	end
	local lamp = state.lamp
	if lamp then
		lamp.Color = color
		lamp.Material = if occupied then Enum.Material.Neon else Enum.Material.Neon
	end
end

local function vehicleOfPlayer(player: Player): Model?
	local char = player.Character
	if not char then
		return nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local seat = if hum then hum.SeatPart else nil
	if not seat then
		return nil
	end
	local model = seat:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("IsGtaVehicle") == true then
		return model
	end
	return nil
end

local function insideBay(state: BayState, car: Model): boolean
	local chassis = car:FindFirstChild("Chassis")
	local prim = if chassis and chassis:IsA("BasePart") then chassis else car.PrimaryPart
	if not prim then
		return false
	end
	local p = prim.Position
	local z = state.zone.Position
	local sx = state.zone.Size.X * 0.5
	local sz = state.zone.Size.Z * 0.5
	return math.abs(p.X - z.X) <= sx + 1.5 and math.abs(p.Z - z.Z) <= sz + 1.5
end

local function collectVehicles(): { Model }
	local list: { Model } = {}
	local roots = { workspace:FindFirstChild("LosSantos"), workspace }
	for _, root in ipairs(roots) do
		if root then
			local fleet = root:FindFirstChild("Phase2_Vehicles", true)
			if fleet then
				for _, child in ipairs(fleet:GetChildren()) do
					if child:IsA("Model") and child:GetAttribute("IsGtaVehicle") == true then
						table.insert(list, child)
					end
				end
			end
		end
	end
	return list
end

local function nearbyPlayers(center: Vector3, radius: number): { Player }
	local out: { Player } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
		if hrp and hrp:IsA("BasePart") then
			if (hrp.Position - center).Magnitude <= radius then
				table.insert(out, player)
			end
		end
	end
	return out
end

local function pushPrompt(state: BayState, bayIndex: number)
	local remote = customsRemote
	if not remote then
		return
	end
	for _, player in ipairs(nearbyPlayers(state.center, 46)) do
		local inCar = vehicleOfPlayer(player) ~= nil
		remote:FireClient(player, {
			kind = "prompt",
			bay = bayIndex,
			visible = state.car ~= nil,
			vehicle = if state.car then tostring(state.car:GetAttribute("VehicleDisplayName") or state.car.Name) else "",
			inCar = inCar,
		})
	end
end

local function describeCar(car: Model): { [string]: any }
	local totalHp, maxHp = 0, 0
	local bodyFolder = car:FindFirstChild("DestructibleBodywork")
	if bodyFolder then
		for _, ch in ipairs(bodyFolder:GetDescendants()) do
			if ch:IsA("BasePart") and ch:GetAttribute("Destructible") == true then
				totalHp += tonumber(ch:GetAttribute("PartHealth")) or 0
				maxHp += tonumber(ch:GetAttribute("MaxPartHealth")) or 0
			end
		end
	end
	return {
		name = tostring(car:GetAttribute("VehicleDisplayName") or car.Name),
		turbo = tonumber(car:GetAttribute("TurboLevel")) or 0,
		maxSpeed = tonumber(car:GetAttribute("MaxSpeed")) or 0,
		damagePct = if maxHp > 0 then math.floor((1 - totalHp / maxHp) * 100) else 0,
		engine = tonumber(car:GetAttribute("EngineHealth")) or 0,
		prices = { repair = PRICE_REPAIR, paint = PRICE_PAINT, turbo = PRICE_TURBO },
	}
end

local function repairCar(car: Model): number
	local repaired = 0
	for _, ch in ipairs(car:GetDescendants()) do
		if ch:IsA("BasePart") and ch:GetAttribute("Destructible") == true then
			local maxHp = tonumber(ch:GetAttribute("MaxPartHealth")) or tonumber(ch:GetAttribute("MaxIntegrity")) or 0
			if maxHp > 0 then
				ch:SetAttribute("PartHealth", maxHp)
				ch:SetAttribute("Integrity", maxHp)
				repaired += 1
			end
			local r = tonumber(ch:GetAttribute("_OrigR"))
			local g = tonumber(ch:GetAttribute("_OrigG"))
			local b = tonumber(ch:GetAttribute("_OrigB"))
			if r and g and b then
				ch.Color = Color3.new(r, g, b)
			end
		end
	end
	local maxEngine = tonumber(car:GetAttribute("MaxEngineHealth")) or 700
	car:SetAttribute("EngineHealth", maxEngine)
	car:SetAttribute("_Exploded", false)
	return repaired
end

local function paintCar(car: Model, color: Color3): number
	local painted = 0
	for _, ch in ipairs(car:GetDescendants()) do
		if ch:IsA("BasePart") and ch:GetAttribute("VehiclePart") == true then
			local zone = tostring(ch:GetAttribute("DamageZone") or "Body")
			if BODY_ZONES[zone] == true and ch.Material ~= Enum.Material.Neon then
				ch.Color = color
				ch:SetAttribute("_OrigR", color.R)
				ch:SetAttribute("_OrigG", color.G)
				ch:SetAttribute("_OrigB", color.B)
				painted += 1
			end
		end
	end
	local nextIndex = (tonumber(car:GetAttribute("PaintIndex")) or 0) % #PAINT_PALETTE + 1
	car:SetAttribute("PaintIndex", nextIndex)
	car:SetAttribute("PaintName", string.format("Màu #%d", nextIndex))
	return painted
end

local function turboCar(car: Model): boolean
	local level = tonumber(car:GetAttribute("TurboLevel")) or 0
	if level >= MAX_TURBO_LEVEL then
		return false
	end
	local maxSpeed = tonumber(car:GetAttribute("MaxSpeed")) or 92
	car:SetAttribute("TurboLevel", level + 1)
	car:SetAttribute("MaxSpeed", math.min(140, maxSpeed + 8))
	return true
end

local function bayIndexOfCar(car: Model): number
	for i, state in ipairs(bays) do
		if state.car == car then
			return i
		end
	end
	return 0
end

local function handleAction(player: Player, payload: any)
	if type(payload) ~= "table" then
		return
	end
	local action = tostring(payload.action or "")
	local bayIndex = tonumber(payload.bay) or 0
	local state = bays[bayIndex]
	if not state then
		return
	end

	local now = os.clock()
	local lastAt = lastActionAt[player] or 0
	if now - lastAt < ACTION_COOLDOWN then
		return
	end
	lastActionAt[player] = now

	local car = state.car
	local remote = customsRemote
	if not remote then
		return
	end

	if action == "open" then
		if not car then
			remote:FireClient(player, { kind = "result", ok = false, message = "Khoang này đang trống — hãy lái xe vào!" })
			return
		end
		local char = player.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
		local driver = vehicleOfPlayer(player)
		local closeEnough = hrp and hrp:IsA("BasePart") and (hrp.Position - state.center).Magnitude <= 40
		if driver ~= car and not closeEnough then
			remote:FireClient(player, { kind = "result", ok = false, message = "Bạn phải đứng gần khoang độ xe này!" })
			return
		end
		remote:FireClient(player, {
			kind = "menu",
			bay = bayIndex,
			car = describeCar(car),
			cash = cashOf(player),
		})
		return
	end

	if action == "close" then
		remote:FireClient(player, { kind = "closed" })
		return
	end

	if not car then
		remote:FireClient(player, { kind = "result", ok = false, message = "Không có xe trong khoang!" })
		return
	end

	local price = if action == "repair" then PRICE_REPAIR elseif action == "paint" then PRICE_PAINT elseif action == "turbo" then PRICE_TURBO else -1
	if price < 0 then
		return
	end

	local cash = cashOf(player)
	if cash < price then
		remote:FireClient(player, { kind = "result", ok = false, message = string.format("Không đủ tiền! Cần $%d (bạn có $%d)", price, cash) })
		return
	end

	local okMessage = ""
	if action == "repair" then
		local count = repairCar(car)
		okMessage = string.format("Đã sửa chữa %d chi tiết — xe như mới!", count)
	elseif action == "paint" then
		local target = PAINT_PALETTE[(tonumber(car:GetAttribute("PaintIndex")) or 0) % #PAINT_PALETTE + 1]
		local count = paintCar(car, target)
		okMessage = string.format("Đã sơn lại %d tấm vỏ xe — lớp sơn tan chảy!", count)
	else
		if turboCar(car) then
			okMessage = string.format("Nâng cấp Turbo cấp %d — tốc độ tối đa %d!", tonumber(car:GetAttribute("TurboLevel")) or 1, math.floor(tonumber(car:GetAttribute("MaxSpeed")) or 0))
		else
			remote:FireClient(player, { kind = "result", ok = false, message = "Xe đã đạt Turbo cấp 3 tối đa!" })
			return
		end
	end

	setCash(player, cash - price)
	remote:FireClient(player, {
		kind = "result",
		ok = true,
		action = action,
		message = okMessage,
		cash = cashOf(player),
		car = describeCar(car),
	})
	toast(player, "Los Santos Customs: " .. okMessage .. string.format(" (-$%d)", price), Color3.fromRGB(56, 189, 248))
end

function LSCustomsService.init(remotesFolderRef: Instance, hudRemoteRef: RemoteEvent, losSantosRoot: Instance)
	remotesFolder = remotesFolderRef
	hudRemote = hudRemoteRef

	local existing = remotesFolderRef:FindFirstChild("LSCustoms")
	if existing and existing:IsA("RemoteEvent") then
		customsRemote = existing
	else
		local created = Instance.new("RemoteEvent")
		created.Name = "LSCustoms"
		created.Parent = remotesFolderRef
		customsRemote = created
	end

	bays = {}
	for i = 1, 2 do
		local zoneInstance = findFirst(losSantosRoot, "BayZone" .. i)
		if zoneInstance and zoneInstance:IsA("BasePart") then
			local centerAttr = zoneInstance:GetAttribute("BayCenter")
			local center = if typeof(centerAttr) == "Vector3" then centerAttr else zoneInstance.Position - Vector3.new(0, 6, 0)
			local strip = findFirst(losSantosRoot, "BayStatusStrip" .. i)
			local lamp = findFirst(losSantosRoot, "BayStatusLamp" .. i)
			bays[i] = {
				zone = zoneInstance,
				center = center :: Vector3,
				car = nil,
				strip = if strip and strip:IsA("BasePart") then strip else nil,
				lamp = if lamp and lamp:IsA("BasePart") then lamp else nil,
			}
			setBayLights(bays[i], false)
		end
	end

	local remote = customsRemote
	remote.OnServerEvent:Connect(handleAction)

	-- Vòng quét trạng thái khoang (0.35s) — ổn định hơn Touched và không bỏ sót xe đứng yên
	task.spawn(function()
		while true do
			task.wait(0.35)
			local vehicles = collectVehicles()
			for i, state in ipairs(bays) do
				local newCar: Model? = nil
				for _, car in ipairs(vehicles) do
					if insideBay(state, car) then
						newCar = car
						break
					end
				end
				if newCar ~= state.car then
					state.car = newCar
					setBayLights(state, newCar ~= nil)
					if newCar then
						pushPrompt(state, i)
					end
				end
				pushPrompt(state, i)
			end
			-- Chào mừng tài xế vừa lái xe vào khoang
			for _, state in ipairs(bays) do
				local car = state.car
				if car and not announced[car] then
					announced[car] = true
					local idx = bayIndexOfCar(car)
					local seat = car:FindFirstChild("DriverSeat")
					local occupant = if seat and seat:IsA("VehicleSeat") then seat.Occupant else nil
					local driverPlayer = if occupant then Players:GetPlayerFromCharacter(occupant.Parent) else nil
					if driverPlayer then
						toast(driverPlayer, string.format("LS CUSTOMS: Xe đã vào Khoang %d — bấm [E] để độ xe!", idx), Color3.fromRGB(46, 224, 128))
					end
				end
			end
			for car in pairs(announced) do
				if not car.Parent then
					announced[car] = nil
				end
			end
		end
	end)

	print(string.format("[LSCustomsService] Đã kích hoạt %d khoang độ xe (Bay 1 & Bay 2).", #bays))
end

return LSCustomsService
