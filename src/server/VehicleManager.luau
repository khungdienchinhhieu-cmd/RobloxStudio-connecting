--!strict
--[[
	VehicleManager.luau
	Điều khiển vật lý lái xe GTA V mượt mà + Xử lý VA CHẠM TỐC ĐỘ CAO trừ máu ẩn (PartHealth):
	- Khi xe tông vào cọc tiêu, dải phân cách K-Rail, tường gạch, bờ kè hoặc xe khác:
	  + Khối bị tông mất máu ẩn theo động lượng -> hết máu tự vỡ tung thành mảnh rời!
	  + Chính cản trước / đèn pha / nắp capo / kính chắn gió của xe cũng mất máu ẩn -> hết máu bung rơi khỏi xe!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VehicleBuilder = require(Shared:WaitForChild("Vehicles"):WaitForChild("VehicleBuilder"))
local DestructionManager = require(script.Parent:WaitForChild("DestructionManager"))

local VehicleManager = {}

local trackedCars: { [Model]: boolean } = {}
local partHitCooldown: { [BasePart]: number } = {}
local carSelfHitCooldown: { [Model]: number } = {}

local PRESET_CYCLE = {
	VehicleBuilder.PRESETS.CrimsonBanshee,
	VehicleBuilder.PRESETS.ObsidianGauntlet,
	VehicleBuilder.PRESETS.MidnightBanshee,
	VehicleBuilder.PRESETS.SunsetComet,
}
local playerCarIndex = 0

local function pickVehicleZonePart(car: Model, zone: string): BasePart?
	local bodyFolder = car:FindFirstChild("DestructibleBodywork")
	if not bodyFolder then
		return nil
	end
	local candidates: { BasePart } = {}
	for _, ch in ipairs(bodyFolder:GetChildren()) do
		if ch:IsA("BasePart") and ch:GetAttribute("Destructible") == true then
			local z = tostring(ch:GetAttribute("DamageZone") or "")
			if z == zone or (zone == "Front" and z == "Glass") then
				table.insert(candidates, ch)
			end
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(1, #candidates)]
end

local function updateBrakeLights(car: Model, braking: boolean)
	local bodyFolder = car:FindFirstChild("DestructibleBodywork")
	if not bodyFolder then
		return
	end
	local col = if braking then Color3.fromRGB(255, 65, 65) else Color3.fromRGB(175, 22, 30)
	for _, nm in ipairs({ "LeftTaillight", "RightTaillight" }) do
		local tl = bodyFolder:FindFirstChild(nm)
		if tl and tl:IsA("BasePart") then
			tl.Color = col
		end
	end
end

local function setCabinLight(car: Model, active: boolean)
	local interior = car:FindFirstChild("InteriorDetails")
	local dome = if interior then interior:FindFirstChild("CabinDomeLight") else nil
	if dome and dome:IsA("BasePart") then
		dome.Material = if active then Enum.Material.Neon else Enum.Material.SmoothPlastic
		local pl = dome:FindFirstChildOfClass("PointLight")
		if pl then
			pl.Brightness = if active then 1.65 else 0
		end
	end
end

-- Diễn hoạt xoay mở / đóng cánh cửa quanh bản lề trước (LeftDoorHinge / RightDoorHinge)
function VehicleManager.animateDoor(
	car: Model,
	tag: "Left" | "Right",
	angleDeg: number,
	duration: number,
	easingStyle: Enum.EasingStyle?
)
	local bodyFolder = car:FindFirstChild("DestructibleBodywork")
	local doorPart = if bodyFolder then bodyFolder:FindFirstChild(tag .. "Door") else nil
	if not doorPart then
		return -- Cánh cửa đã bị đâm / bắn văng khỏi xe!
	end

	local hinge = car:FindFirstChild(tag .. "DoorHinge")
	local weld = if hinge then hinge:FindFirstChild("DoorHingeWeld") :: Weld? else nil
	if not hinge or not weld then
		return
	end

	local cx = tonumber(hinge:GetAttribute("ClosedX")) or 0
	local cy = tonumber(hinge:GetAttribute("ClosedY")) or 0
	local cz = tonumber(hinge:GetAttribute("ClosedZ")) or 0
	local sideSign = tonumber(hinge:GetAttribute("SideSign")) or -1

	local targetC0 = CFrame.new(cx, cy, cz) * CFrame.Angles(0, sideSign * math.rad(angleDeg), 0)
	setCabinLight(car, angleDeg > 4)

	TweenService:Create(
		weld,
		TweenInfo.new(duration, easingStyle or Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ C0 = targetC0 }
	):Play()
end

local function wireDoorAndSeat(car: Model, chassis: BasePart, tag: "Left" | "Right", seatObj: BasePart)
	local sideSign = if tag == "Left" then -1 else 1
	local bodyFolder = car:FindFirstChild("DestructibleBodywork")
	local handle = if bodyFolder then bodyFolder:FindFirstChild(tag .. "OuterDoorHandle") else nil
	local prompt = if handle then handle:FindFirstChild("EnterDoorPrompt") :: ProximityPrompt? else nil

	local animToken = 0
	local enteringViaPrompt = false
	local lastOccupant: Humanoid? = nil

	local function getOccupant(): Humanoid?
		if seatObj:IsA("VehicleSeat") then
			return seatObj.Occupant
		elseif seatObj:IsA("Seat") then
			return seatObj.Occupant
		end
		return nil
	end

	local function sitHumanoid(hum: Humanoid)
		if seatObj:IsA("VehicleSeat") then
			seatObj:Sit(hum)
		elseif seatObj:IsA("Seat") then
			seatObj:Sit(hum)
		end
	end

	-- 1) Khi bấm phím [F] cạnh tay nắm cửa -> Mở rộng cửa 64° -> Bước vào ngồi -> Kéo đóng cửa!
	if prompt then
		prompt.Triggered:Connect(function(player)
			if getOccupant() ~= nil or enteringViaPrompt then
				return
			end
			local char = player.Character
			local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
			local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
			if not hum or hum.Health <= 0 or hum.SeatPart ~= nil or not hrp or not hrp:IsA("BasePart") then
				return
			end

			enteringViaPrompt = true
			animToken += 1
			local myTok = animToken
			prompt.Enabled = false

			-- Bước 1: Tung cánh cửa mở rộng 64° + bật đèn trần ca-bin
			VehicleManager.animateDoor(car, tag, 64, 0.28, Enum.EasingStyle.Quart)

			-- Đưa nhân vật đứng ngay sát bậc cửa đang mở, quay mặt vào khoang lái
			local standPos = (chassis.CFrame * CFrame.new(sideSign * 5.05, 0.55, 0.25)).Position
			local seatWorld = seatObj.Position
			hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(seatWorld.X, standPos.Y, seatWorld.Z))

			-- Bước 2: Sau 0.22s khi cửa đã hé rộng, đặt nhân vật ngồi êm vào ghế đua
			task.delay(0.22, function()
				if animToken ~= myTok or not car.Parent then
					enteringViaPrompt = false
					return
				end
				if hum.Health > 0 and getOccupant() == nil then
					sitHumanoid(hum)
				end

				-- Bước 3: Ngồi yên trong ghế xong -> kéo cánh cửa sập đóng lại!
				task.delay(0.34, function()
					enteringViaPrompt = false
					if animToken == myTok and car.Parent then
						VehicleManager.animateDoor(car, tag, 0, 0.30, Enum.EasingStyle.Back)
					end
				end)
			end)
		end)
	end

	-- Hạ nhẹ tư thế ngồi SeatWeld xuống đệm ghế đua âm sàn (-0.34 stud) để tóc cao R15 tuyệt đối không lòi qua mui xe!
	seatObj.ChildAdded:Connect(function(ch)
		if ch.Name == "SeatWeld" and ch:IsA("Weld") then
			ch.C0 = CFrame.new(0, -0.34, 0.10) * ch.C0
		end
	end)

	-- 2) Theo dõi khi ngồi trực tiếp (chạm ghế) HOẶC khi nhảy ra khỏi xe (Space) -> Tự động mở & đóng cửa!
	seatObj:GetPropertyChangedSignal("Occupant"):Connect(function()
		pcall(function()
			chassis:SetNetworkOwner(nil)
		end)

		local occ = getOccupant()
		if occ ~= nil then
			lastOccupant = occ
			if prompt then
				prompt.Enabled = false
			end
			if not enteringViaPrompt then
				animToken += 1
				local myTok = animToken
				VehicleManager.animateDoor(car, tag, 56, 0.18, Enum.EasingStyle.Quad)
				task.delay(0.26, function()
					if animToken == myTok and car.Parent then
						VehicleManager.animateDoor(car, tag, 0, 0.28, Enum.EasingStyle.Back)
					end
				end)
			end
		else
			-- Người chơi vừa bước xuống xe -> Mở bung cửa 62°, đặt nhân vật ra cạnh cửa thoáng đãng rồi khép cửa lại!
			if prompt and prompt.Parent then
				prompt.Enabled = true
			end
			animToken += 1
			local myTok = animToken
			VehicleManager.animateDoor(car, tag, 62, 0.22, Enum.EasingStyle.Quart)

			local prevHum = lastOccupant
			lastOccupant = nil
			if prevHum and prevHum.Parent then
				local prevChar = prevHum.Parent
				local prevHrp = prevChar:FindFirstChild("HumanoidRootPart")
				if prevHrp and prevHrp:IsA("BasePart") then
					task.defer(function()
						if prevHrp.Parent and chassis.Parent then
							local exitCF = chassis.CFrame * CFrame.new(sideSign * 5.75, 0.65, 0.30)
							prevHrp.CFrame = CFrame.lookAt(
								exitCF.Position,
								exitCF.Position + chassis.CFrame.LookVector
							)
						end
					end)
				end
			end

			task.delay(0.55, function()
				if animToken == myTok and car.Parent then
					VehicleManager.animateDoor(car, tag, 0, 0.32, Enum.EasingStyle.Quad)
				end
			end)
		end
	end)
end

function VehicleManager.registerCar(car: Model)
	if trackedCars[car] then
		return
	end
	trackedCars[car] = true

	local chassis = car:FindFirstChild("Chassis") :: BasePart?
	local driverSeat = car:FindFirstChild("DriverSeat") :: VehicleSeat?
	local passSeat = car:FindFirstChild("PassengerSeat") :: Seat?
	if chassis then
		pcall(function()
			chassis:SetNetworkOwner(nil)
		end)
		if driverSeat then
			wireDoorAndSeat(car, chassis, "Left", driverSeat)
		end
		if passSeat then
			wireDoorAndSeat(car, chassis, "Right", passSeat)
		end
	end
end

function VehicleManager.spawnForPlayer(player: Player): Model?
	local char = player.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
	if not hrp or not hrp:IsA("BasePart") then
		return nil
	end

	local root = Workspace:FindFirstChild("LosSantos")
	local fleet = if root then root:FindFirstChild("Phase2_Vehicles") else nil
	local targetParent: Instance = fleet or Workspace

	-- Xoá xe cá nhân cũ của người chơi nếu còn để tránh rác map
	local oldTag = "PersonalCar_" .. tostring(player.UserId)
	for carModel in pairs(trackedCars) do
		if carModel.Parent and carModel:GetAttribute("OwnerTag") == oldTag then
			carModel:Destroy()
			trackedCars[carModel] = nil
		end
	end

	playerCarIndex = (playerCarIndex % #PRESET_CYCLE) + 1
	local preset = PRESET_CYCLE[playerCarIndex]

	local flatLook = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	if flatLook.Magnitude < 0.05 then
		flatLook = Vector3.new(0, 0, -1)
	else
		flatLook = flatLook.Unit
	end

	local spawnPos = hrp.Position + flatLook * 13 + Vector3.new(0, 0.5, 0)
	local spawnCF = CFrame.lookAt(spawnPos, spawnPos + flatLook)
	local car = VehicleBuilder.spawn(targetParent, spawnCF, preset)
	car:SetAttribute("OwnerTag", oldTag)
	VehicleManager.registerCar(car)
	return car
end

function VehicleManager.init()
	local root = Workspace:FindFirstChild("LosSantos")
	if root then
		local fleet = root:FindFirstChild("Phase2_Vehicles")
		if not fleet then
			fleet = VehicleBuilder.spawnDefaultFleet(root)
		end
		for _, child in ipairs(fleet:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("IsGtaVehicle") == true then
				VehicleManager.registerCar(child)
			end
		end
	end

	RunService.Heartbeat:Connect(function(_dt)
		local now = os.clock()

		-- Dọn bảng cooldown cũ định kỳ
		for p, expTime in pairs(partHitCooldown) do
			if not p.Parent or now > expTime then
				partHitCooldown[p] = nil
			end
		end

		for car in pairs(trackedCars) do
			if not car.Parent or car:GetAttribute("_Exploded") == true then
				trackedCars[car] = nil
				continue
			end

			local chassis = car:FindFirstChild("Chassis") :: BasePart?
			local seat = car:FindFirstChild("DriverSeat") :: VehicleSeat?
			local vf = if chassis then chassis:FindFirstChild("DriveVectorForce") :: VectorForce? else nil
			local av = if chassis then chassis:FindFirstChild("SteerAngularVelocity") :: AngularVelocity? else nil

			if not chassis or not seat or not vf or not av then
				continue
			end

			local vel = chassis.AssemblyLinearVelocity
			local speed = vel.Magnitude
			car:SetAttribute("CurrentMPH", math.floor(speed * 1.15))

			local cf = chassis.CFrame
			local flatFwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
			if flatFwd.Magnitude < 0.01 then
				flatFwd = Vector3.new(0, 0, -1)
			else
				flatFwd = flatFwd.Unit
			end
			local flatRight = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
			if flatRight.Magnitude < 0.01 then
				flatRight = Vector3.new(1, 0, 0)
			else
				flatRight = flatRight.Unit
			end

			local fwdSpeed = vel:Dot(flatFwd)
			local latSpeed = vel:Dot(flatRight)
			local mass = chassis.AssemblyMass
			local maxSpeed = tonumber(car:GetAttribute("MaxSpeed")) or 92

			if seat.Occupant then
				local throttle = seat.ThrottleFloat
				local steer = seat.SteerFloat

				-- Lực kéo động cơ + Phanh + Lực bám ngang chống trượt bánh lố
				local driveF = Vector3.zero
				if math.abs(throttle) > 0.04 then
					local targetSpd = if throttle > 0 then (throttle * maxSpeed) else (throttle * maxSpeed * 0.45)
					local gain = if (throttle * fwdSpeed < -2) then 7.2 else 4.4 -- Phanh gấp ăn hơn!
					driveF = flatFwd * ((targetSpd - fwdSpeed) * mass * gain)
				else
					driveF = -flatFwd * (fwdSpeed * mass * 0.95)
				end

				local gripF = -flatRight * (latSpeed * mass * 8.2)
				vf.Force = driveF + gripF

				-- Đánh lái mượt tỉ lệ theo tốc độ lăn bánh
				local moveRatio = math.clamp(math.abs(fwdSpeed) / 9.0, 0, 1)
				local revSign = if fwdSpeed < -1.5 then -1 else 1
				av.MaxTorque = mass * 520
				av.AngularVelocity = Vector3.new(0, -steer * 2.45 * moveRatio * revSign, 0)

				updateBrakeLights(car, throttle < -0.1)
			else
				-- Khi không có người lái: hãm trôi tự nhiên để xe đậu đằm trên dốc/lề đường
				vf.Force = -Vector3.new(vel.X, 0, vel.Z) * (mass * 2.4)
				av.MaxTorque = 0
				updateBrakeLights(car, false)
			end

			-- QUÉT VA CHẠM TỐC ĐỘ CAO: Xe đụng khối có máu ẩn -> Trừ PartHealth -> Hết máu tự vỡ!
			if speed >= 13.5 then
				local goingForward = fwdSpeed >= -1.0
				local zoneOffsetZ = if goingForward then -8.15 else 8.15
				local zoneName = if goingForward then "Front" else "Rear"
				local sweepCF = cf * CFrame.new(0, 0.55, zoneOffsetZ)

				local params = OverlapParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				local debFolder = Workspace:FindFirstChild("LosSantos_Debris")
				params.FilterDescendantsInstances = if debFolder then { car, debFolder } else { car }

				local hits = Workspace:GetPartBoundsInBox(sweepCF, Vector3.new(7.5, 2.5, 2.4), params)
				local hitSolidObstacle = false

				for _, hp in ipairs(hits) do
					if hp:IsA("BasePart") then
						if hp:GetAttribute("Destructible") == true then
							if not partHitCooldown[hp] then
								partHitCooldown[hp] = now + 0.16
								hitSolidObstacle = true
								local impactDmg = speed * 2.35
								local pushVec = vel * 1.15 + Vector3.new(0, 14, 0)
								DestructionManager.damagePart(hp, impactDmg, hp.Position, pushVec)
							end
						elseif hp.CanCollide and (hp.Position.Y + hp.Size.Y * 0.5) > (cf.Position.Y - 0.35) then
							-- Va vào vách núi / tường cứng cao hơn bậc vỉa hè
							hitSolidObstacle = true
						end
					end
				end

				-- Phản lực làm móp / vỡ đèn pha / cản xe / nắp capo của chính chiếc xe đang tông!
				if hitSolidObstacle and (now > (carSelfHitCooldown[car] or 0)) then
					carSelfHitCooldown[car] = now + 0.22
					local selfPanel = pickVehicleZonePart(car, zoneName)
					if selfPanel then
						DestructionManager.damagePart(
							selfPanel,
							speed * 0.58,
							selfPanel.Position,
							-flatFwd * (speed * 0.35) + Vector3.new(0, 12, 0)
						)
					else
						DestructionManager.damageVehicleEngine(car, speed * 0.65, vel)
					end
				end
			end
		end
	end)
end

return VehicleManager
