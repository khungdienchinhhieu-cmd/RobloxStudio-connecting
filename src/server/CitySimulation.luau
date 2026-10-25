--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CityConfig = require(Shared:WaitForChild("CityConfig"))

local CitySimulation = {}

local configuredVehicles: { [Model]: boolean } = {}

type VehicleRuntime = {
	model: Model,
	chassis: BasePart,
	seat: VehicleSeat,
	linVel: LinearVelocity,
	alignOri: AlignOrientation,
	yaw: number,
	speed: number,
}

local activeVehicles: { VehicleRuntime } = {}

function CitySimulation.setupVehicle(car: Model)
	if configuredVehicles[car] then
		return
	end
	local chassis = car.PrimaryPart or car:FindFirstChild("Chassis")
	local seat = car:FindFirstChild("DriverSeat")
	if not chassis or not chassis:IsA("BasePart") or not seat or not seat:IsA("VehicleSeat") then
		return
	end

	configuredVehicles[car] = true

	-- Hàn gắn toàn bộ chi tiết thân xe vào Chassis trước khi bỏ neo vật lý
	for _, desc in ipairs(car:GetDescendants()) do
		if desc:IsA("BasePart") and desc ~= chassis then
			desc.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = desc
			weld.Parent = chassis
		end
	end

	for _, desc in ipairs(car:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = false
		end
	end

	local att = Instance.new("Attachment")
	att.Name = "DriveAttachment"
	att.Parent = chassis

	local linVel = Instance.new("LinearVelocity")
	linVel.Name = "ArcadeDriveVelocity"
	linVel.Attachment0 = att
	linVel.RelativeTo = Enum.ActuatorRelativeTo.World
	linVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	linVel.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	linVel.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	linVel.MaxForce = 120000
	linVel.PlaneVelocity = Vector2.zero
	linVel.Parent = chassis

	local _, startYaw, _ = chassis.CFrame:ToOrientation()

	local alignOri = Instance.new("AlignOrientation")
	alignOri.Name = "ArcadeUprightSteering"
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Attachment0 = att
	alignOri.MaxTorque = 180000
	alignOri.Responsiveness = 22
	alignOri.CFrame = CFrame.Angles(0, startYaw, 0)
	alignOri.Parent = chassis

	table.insert(activeVehicles, {
		model = car,
		chassis = chassis,
		seat = seat,
		linVel = linVel,
		alignOri = alignOri,
		yaw = startYaw,
		speed = 0,
	})
end

function CitySimulation.updateNightLights()
	local clock = Lighting.ClockTime
	local isNight = (clock >= 17.6 or clock <= 6.3)

	for _, bulb in ipairs(CollectionService:GetTagged(CityConfig.StreetLightTag)) do
		if bulb:IsA("BasePart") then
			bulb.Material = if isNight then Enum.Material.Neon else Enum.Material.SmoothPlastic
			bulb.Color = if isNight then Color3.fromRGB(255, 232, 185) else Color3.fromRGB(190, 195, 205)
			local spot = bulb:FindFirstChildOfClass("SpotLight")
			if spot then
				spot.Enabled = isNight
			end
		end
	end

	for _, win in ipairs(CollectionService:GetTagged(CityConfig.WindowGlowTag)) do
		if win:IsA("BasePart") then
			win.Material = if isNight then Enum.Material.Neon else Enum.Material.Glass
			win.Reflectance = if isNight then 0 else 0.22
		end
	end
end

local function setTrafficAxisState(axisName: string, activeLamp: string)
	for _, tl in ipairs(CollectionService:GetTagged(CityConfig.TrafficLightTag)) do
		if tl:GetAttribute("Axis") == axisName then
			local box = tl:FindFirstChild("SignalBox")
			if box then
				for _, colorName in ipairs({ "Red", "Yellow", "Green" }) do
					local lens = tl:FindFirstChild(colorName)
					if lens and lens:IsA("BasePart") then
						local isOn = (colorName == activeLamp)
						local onCol = lens:GetAttribute("OnColor")
						local offCol = lens:GetAttribute("OffColor")
						if typeof(onCol) == "Color3" and typeof(offCol) == "Color3" then
							lens.Color = if isOn then onCol else offCol
						end
						lens.Material = if isOn then Enum.Material.Neon else Enum.Material.SmoothPlastic
					end
				end
			end
		end
	end
end

function CitySimulation.start()
	for _, car in ipairs(CollectionService:GetTagged(CityConfig.VehicleTag)) do
		if car:IsA("Model") then
			CitySimulation.setupVehicle(car)
		end
	end
	CollectionService:GetInstanceAddedSignal(CityConfig.VehicleTag):Connect(function(inst)
		if inst:IsA("Model") then
			task.defer(function()
				CitySimulation.setupVehicle(inst)
			end)
		end
	end)

	CitySimulation.updateNightLights()

	-- Vòng lặp vật lý lái xe mượt mà 60fps
	RunService.Heartbeat:Connect(function(dt)
		for i = #activeVehicles, 1, -1 do
			local v = activeVehicles[i]
			if not v.model.Parent or not v.chassis.Parent then
				table.remove(activeVehicles, i)
				continue
			end

			local throttle = v.seat.ThrottleFloat
			local steer = v.seat.SteerFloat
			local hasDriver = v.seat.Occupant ~= nil

			local nitroUntil = tonumber(v.model:GetAttribute("NitroUntil")) or 0
			local maxSpeed = if os.clock() < nitroUntil then 96 else 66

			if hasDriver and math.abs(throttle) > 0.02 then
				local targetSpeed = throttle * maxSpeed
				local accel = if throttle > 0 then 52 else 44
				v.speed += math.clamp(targetSpeed - v.speed, -accel * dt, accel * dt)
			else
				local drag = if hasDriver then 36 else 55
				if math.abs(v.speed) <= drag * dt then
					v.speed = 0
				else
					v.speed -= math.sign(v.speed) * drag * dt
				end
			end

			if hasDriver and math.abs(v.speed) > 1.2 and math.abs(steer) > 0.02 then
				local reverseFactor = if v.speed >= 0 then 1 else -1
				local turnRate = 1.95 * math.clamp(math.abs(v.speed) / 28, 0.35, 1.1)
				v.yaw -= steer * turnRate * reverseFactor * dt
				v.alignOri.CFrame = CFrame.Angles(0, v.yaw, 0)
			end

			local forward = CFrame.Angles(0, v.yaw, 0).LookVector
			v.linVel.PlaneVelocity = Vector2.new(forward.X * v.speed, forward.Z * v.speed)
		end
	end)

	-- Chu kỳ Đèn Giao Thông Ngã Tư + Thời gian Ngày/Đêm nhẹ nhàng
	task.spawn(function()
		local phases = {
			{ ns = "Green", ew = "Red", waitSec = 10 },
			{ ns = "Yellow", ew = "Red", waitSec = 2.5 },
			{ ns = "Red", ew = "Green", waitSec = 10 },
			{ ns = "Red", ew = "Yellow", waitSec = 2.5 },
		}
		local idx = 1
		while true do
			local p = phases[idx]
			setTrafficAxisState("NS", p.ns)
			setTrafficAxisState("EW", p.ew)
			CitySimulation.updateNightLights()
			task.wait(p.waitSec)
			Lighting.ClockTime = (Lighting.ClockTime + 0.06) % 24
			idx = (idx % #phases) + 1
		end
	end)
end

return CitySimulation
