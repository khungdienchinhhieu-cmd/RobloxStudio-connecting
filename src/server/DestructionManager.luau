--!strict
--[[
	DestructionManager.luau
	Hệ thống Máu Ẩn (PartHealth) & Tự Động Vỡ Vật Lý (Auto-Shatter Engine):
	- Mọi khối vật lý có Destructible = true (tường gạch, dải phân cách K-Rail, cọc tiêu, bờ kè đá,
	  tượng đài, và toàn bộ vỏ/kính/đèn xe hơi) đều mang máu ẩn PartHealth.
	- Khi bị XE ĐỤNG hoặc BỊ SÚNG BẮN đều trừ PartHealth, sẫm màu / nứt kính dần.
	- Ngay khi PartHealth <= 0: TỰ ĐỘNG VỠ TUNG thành các mảnh vật lý 3D văng theo hướng lực tác động,
	  đồng thời kích hoạt sập dây chuyền cho các hàng gạch nằm chồng phía trên (StructuralRow).
]]

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local DestructionManager = {}

local MAX_ACTIVE_DEBRIS = 180
local activeDebrisCount = 0

local function getDebrisFolder(): Folder
	local f = Workspace:FindFirstChild("LosSantos_Debris") :: Folder?
	if not f then
		local created = Instance.new("Folder")
		created.Name = "LosSantos_Debris"
		created.Parent = Workspace
		f = created
	end
	return f :: Folder
end

local function spawnTrackedDebris(part: BasePart, lifetime: number)
	if activeDebrisCount >= MAX_ACTIVE_DEBRIS then
		local folder = getDebrisFolder()
		local children = folder:GetChildren()
		if #children > 0 then
			children[1]:Destroy()
			activeDebrisCount = math.max(0, activeDebrisCount - 1)
		end
	end
	activeDebrisCount += 1
	part.Parent = getDebrisFolder()
	task.delay(lifetime, function()
		if part.Parent then
			part:Destroy()
		end
		activeDebrisCount = math.max(0, activeDebrisCount - 1)
	end)
end

local function ensureBaseColorSaved(part: BasePart)
	if part:GetAttribute("_OrigR") == nil then
		part:SetAttribute("_OrigR", part.Color.R)
		part:SetAttribute("_OrigG", part.Color.G)
		part:SetAttribute("_OrigB", part.Color.B)
	end
end

local function getSavedBaseColor(part: BasePart): Color3
	local r = tonumber(part:GetAttribute("_OrigR")) or part.Color.R
	local g = tonumber(part:GetAttribute("_OrigG")) or part.Color.G
	local b = tonumber(part:GetAttribute("_OrigB")) or part.Color.B
	return Color3.new(r, g, b)
end

-- Tia mảnh vụn nhỏ văng ra mỗi khi đạn găm hoặc xe quệt trúng nhưng chưa vỡ hẳn
local function emitHitChip(hitPos: Vector3, basePart: BasePart, impulse: Vector3)
	if activeDebrisCount >= MAX_ACTIVE_DEBRIS then
		return
	end
	local chip = Instance.new("Part")
	chip.Name = "ImpactChip"
	chip.Size = Vector3.new(0.32, 0.24, 0.32)
	chip.CFrame = CFrame.new(hitPos)
	chip.Color = basePart.Color
	chip.Material = basePart.Material
	chip.Anchored = false
	chip.CanCollide = false
	chip.CanQuery = false
	chip.AssemblyLinearVelocity = impulse * 0.35 + Vector3.new(math.random(-10, 10), math.random(8, 18), math.random(-10, 10))
	chip.AssemblyAngularVelocity = Vector3.new(math.random(-12, 12), math.random(-12, 12), math.random(-12, 12))
	spawnTrackedDebris(chip, 1.8)
end

-- Vỡ kính / đèn thành hàng loạt mảnh kính trong suốt văng tứ phía
local function shatterGlassOrLight(part: BasePart, impulse: Vector3)
	local cf = part.CFrame
	local sz = part.Size
	local col = part.Color
	local mat = part.Material
	local transp = math.clamp(part.Transparency, 0.15, 0.55)

	part:Destroy()

	for i = 1, 6 do
		local ox = (math.random() - 0.5) * sz.X * 0.75
		local oy = (math.random() - 0.5) * sz.Y * 0.75
		local oz = (math.random() - 0.5) * sz.Z * 0.75

		local shard = Instance.new("WedgePart")
		shard.Name = "GlassShard_" .. tostring(i)
		shard.Size = Vector3.new(
			math.clamp(sz.X * 0.28, 0.22, 1.3),
			math.clamp(sz.Y * 0.32, 0.22, 1.3),
			math.clamp(sz.Z * 0.28, 0.15, 1.1)
		)
		shard.CFrame = cf * CFrame.new(ox, oy, oz) * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3)
		shard.Color = col
		shard.Material = mat
		shard.Transparency = transp
		shard.Anchored = false
		shard.CanCollide = true
		shard.CanQuery = false
		shard.AssemblyLinearVelocity = impulse * 0.65 + Vector3.new(math.random(-16, 16), math.random(6, 20), math.random(-16, 16))
		shard.AssemblyAngularVelocity = Vector3.new(math.random(-18, 18), math.random(-18, 18), math.random(-18, 18))
		spawnTrackedDebris(shard, 4.5)
	end
end

-- Tách khối gạch / bê tông / đá thành 4 mảnh vỡ vật lý 3D văng tung toé
local function fractureWorldBlock(part: BasePart, impulse: Vector3)
	local cf = part.CFrame
	local sz = part.Size
	local col = getSavedBaseColor(part)
	local mat = part.Material
	local parentFolder = part.Parent
	local row = tonumber(part:GetAttribute("StructuralRow")) or 1
	local pos = part.Position

	part:Destroy()

	-- ═══════════════════════════════════════════════════════════════════════════
	-- SỐ MẢNH VỠ TỈ LỆ VỚI KÍCH THƯỚC KHỐI  (kỹ thuật "ít part mà vẫn bể")
	-- ---------------------------------------------------------------------------
	-- Khối gạch nhỏ  (2×0.8×1 stud)   -> vỡ 2 mảnh  (như cũ)
	-- Khối tường lớn (8×10×0.6 stud)  -> vỡ 12 mảnh (nhìn như mảng tường nổ tung)
	-- Nhờ vậy 1 part lớn vẫn cho cảm giác "vỡ vụn" y như 60 viên gạch rời,
	-- nhưng lúc CHƯA vỡ thì chỉ tốn 1 part -> tiết kiệm 60 lần.
	-- ═══════════════════════════════════════════════════════════════════════════
	local volume = sz.X * sz.Y * sz.Z
	local longest = math.max(sz.X, sz.Y, sz.Z)
	local shortest = math.max(0.3, math.min(sz.X, sz.Y, sz.Z))

	-- 2 mảnh cho khối nhỏ, tối đa 14 mảnh cho mảng tường lớn
	local subCount = math.clamp(math.floor(volume / 6) + 2, 2, 14)
	-- Mảnh vỡ không nhỏ hơn 1 stud mỗi cạnh (tránh 60 mảnh bụi rác)
	local maxBySize = math.floor((longest / math.max(1.0, shortest)) * 3)
	if maxBySize >= 2 and subCount > maxBySize then
		subCount = maxBySize
	end

	-- Chia theo LƯỚI 3D (nx × ny × nz) thay vì luôn 2×2 -> mảng tường phẳng
	-- sẽ vỡ thành lưới ô đều nhau, rất giống tường gạch thật bị đục thủng.
	local nx = math.max(1, math.min(3, math.floor(subCount ^ 0.5 + 0.5)))
	local ny = math.max(1, math.min(3, math.ceil(subCount / (nx * 2))))
	local nz = math.max(1, math.floor(subCount / (nx * ny)))
	-- bù cho trường hợp chia hết chưa đủ số mảnh
	while nx * ny * nz < subCount and nx < 4 do
		nx += 1
	end

	local cellX = sz.X / nx
	local cellY = math.max(0.42, (sz.Y / ny) * 0.86)
	local cellZ = sz.Z / nz

	local limit = math.min(subCount, nx * ny * nz)
	for i = 1, limit do
		local ix = (i - 1) % nx
		local iy = math.floor((i - 1) / nx) % ny
		local iz = math.floor((i - 1) / (nx * ny)) % nz

		local localOff = Vector3.new(
			(ix + 0.5) * cellX - sz.X * 0.5,
			(iy + 0.5) * (sz.Y / ny) - sz.Y * 0.5,
			(iz + 0.5) * cellZ - sz.Z * 0.5
		)

		local chunk = Instance.new("Part")
		chunk.Name = "RubbleChunk"
		chunk.Size = Vector3.new(
			math.max(0.42, cellX * 0.9),
			cellY,
			math.max(0.42, cellZ * 0.9)
		)
		chunk.CFrame = cf * CFrame.new(localOff)
			* CFrame.Angles(math.rad(math.random(-11, 11)), math.rad(math.random(-16, 16)), 0)
		chunk.Color = col:Lerp(Color3.new(0.18, 0.18, 0.18), 0.14)
		chunk.Material = mat
		chunk.TopSurface = Enum.SurfaceType.Smooth
		chunk.BottomSurface = Enum.SurfaceType.Smooth
		chunk.Anchored = false
		chunk.CanCollide = true
		chunk.CanQuery = false
		-- Mảnh ở ngoài rìa văng mạnh hơn mảnh ở giữa
		local radial = if math.abs(localOff.X) > 0.01 then (if localOff.X > 0 then 1 else -1) else 0
		local radialZ = if math.abs(localOff.Z) > 0.01 then (if localOff.Z > 0 then 1 else -1) else 0
		chunk.AssemblyLinearVelocity = impulse * 0.55
			+ Vector3.new(
				radial * math.random(5, 14) + math.random(-3, 3),
				math.random(8, 22),
				radialZ * math.random(5, 14) + math.random(-3, 3)
			)
		chunk.AssemblyAngularVelocity = Vector3.new(
			math.random(-10, 10), math.random(-14, 14), math.random(-10, 10)
		)
		spawnTrackedDebris(chunk, 7.5)
	end

	-- Hiệu ứng sập dây chuyền cho các viên gạch nằm ngay bên trên (StructuralRow + 1)
	if parentFolder then
		local reachX = sz.X * 0.65 + 1.2
		local reachZ = sz.Z * 0.65 + 1.2
		for _, sib in ipairs(parentFolder:GetChildren()) do
			if sib:IsA("BasePart") and sib:GetAttribute("Destructible") == true then
				local sibRow = tonumber(sib:GetAttribute("StructuralRow")) or 1
				if sibRow == row + 1 then
					if math.abs(sib.Position.X - pos.X) <= reachX and math.abs(sib.Position.Z - pos.Z) <= reachZ then
						task.delay(0.08, function()
							if sib.Parent then
								local maxHp = tonumber(sib:GetAttribute("MaxPartHealth")) or 100
								DestructionManager.damagePart(sib, maxHp * 1.05, sib.Position, Vector3.new(0, -8, 0))
							end
						end)
					end
				end
			end
		end
	end
end

-- Bung rời cánh cửa / nắp capo / cản xe khi hết máu ẩn
local function detachVehiclePanel(part: BasePart, impulse: Vector3)
	if part.Material == Enum.Material.Glass or part.Material == Enum.Material.Neon then
		shatterGlassOrLight(part, impulse)
		return
	end

	local parentFolder = part.Parent
	local weld = part:FindFirstChildOfClass("WeldConstraint")
	if weld then
		weld:Destroy()
	end

	-- Nếu là Cánh Cửa Xe (LeftDoor / RightDoor): tắt ProximityPrompt & cho các chi tiết gắn trên cửa bay theo cùng cánh cửa!
	if parentFolder then
		for _, sib in ipairs(parentFolder:GetChildren()) do
			if sib ~= part and sib:IsA("BasePart") then
				local sw = sib:FindFirstChildOfClass("WeldConstraint")
				if sw and sw.Part0 == part then
					local pr = sib:FindFirstChildOfClass("ProximityPrompt")
					if pr then
						pr.Enabled = false
						pr:Destroy()
					end
					sib:SetAttribute("Destructible", false)
					sib.CanQuery = false
					spawnTrackedDebris(sib, 8.0)
				end
			end
		end
	end

	part:SetAttribute("Destructible", false)
	part.CanQuery = false
	part.CanCollide = true
	part.Massless = false
	part.Color = getSavedBaseColor(part):Lerp(Color3.fromRGB(28, 28, 32), 0.35)
	part.AssemblyLinearVelocity = impulse * 0.5 + Vector3.new(math.random(-12, 12), math.random(12, 24), math.random(-12, 12))
	part.AssemblyAngularVelocity = Vector3.new(math.random(-9, 9), math.random(-12, 12), math.random(-9, 9))
	spawnTrackedDebris(part, 8.0)
end

-- Xử lý khói đen, lửa cháy & NỔ TUNG XE khi EngineHealth <= 0
function DestructionManager.damageVehicleEngine(car: Model, amount: number, originImpulse: Vector3?)
	if not car.Parent or car:GetAttribute("_Exploded") == true then
		return
	end
	local chassis = car:FindFirstChild("Chassis") :: BasePart?
	if not chassis then
		return
	end

	local maxE = tonumber(car:GetAttribute("MaxEngineHealth")) or 700
	local curE = tonumber(car:GetAttribute("EngineHealth")) or maxE
	local nextE = math.max(0, curE - amount)
	car:SetAttribute("EngineHealth", nextE)

	local ratio = nextE / maxE

	-- Dưới 55% máu động cơ: bốc khói xám dưới nắp capo
	local smoke = chassis:FindFirstChild("EngineSmoke") :: Smoke?
	if ratio <= 0.55 and not smoke then
		local s = Instance.new("Smoke")
		s.Name = "EngineSmoke"
		s.Color = Color3.fromRGB(115, 118, 124)
		s.Opacity = 0.45
		s.RiseVelocity = 7
		s.Size = 3.5
		s.Parent = chassis
		smoke = s
	end

	-- Dưới 25% máu động cơ: khói đen đặc + bốc lửa cam chuẩn GTA V!
	if ratio <= 0.25 then
		if smoke then
			smoke.Color = Color3.fromRGB(28, 28, 30)
			smoke.Opacity = 0.78
		end
		if not chassis:FindFirstChild("EngineFire") then
			local fire = Instance.new("Fire")
			fire.Name = "EngineFire"
			fire.Heat = 12
			fire.Size = 7
			fire.Parent = chassis
		end
	end

	-- Hết sạch máu động cơ => NỔ TUNG XE & PHÁ VỠ GẠCH ĐÁ XUNG QUANH!
	if nextE <= 0 then
		car:SetAttribute("_Exploded", true)
		local blastCenter = chassis.Position

		local exp = Instance.new("Explosion")
		exp.Position = blastCenter
		exp.BlastRadius = 22
		exp.BlastPressure = 0 -- Tự tính lực văng mượt bằng DestructionManager
		exp.DestroyJointRadiusPercent = 0
		exp.Parent = Workspace

		-- Hất tung người ngồi nếu còn trên ghế
		local seat = car:FindFirstChild("DriverSeat") :: VehicleSeat?
		if seat and seat.Occupant then
			seat.Occupant.Sit = false
			seat.Occupant:TakeDamage(65)
		end

		-- Bung toàn bộ các mảnh vỏ xe còn lại và nhuộm cháy đen khung sườn
		for _, desc in ipairs(car:GetDescendants()) do
			if desc:IsA("BasePart") then
				if desc:GetAttribute("VehiclePart") == true then
					local outDir = (desc.Position - blastCenter)
					local unit = if outDir.Magnitude > 0.1 then outDir.Unit else Vector3.new(0, 1, 0)
					detachVehiclePanel(desc, unit * 48 + Vector3.new(0, 22, 0))
				else
					desc.Color = Color3.fromRGB(26, 25, 25)
					desc.Material = Enum.Material.CorrodedMetal
				end
			end
		end

		chassis.AssemblyLinearVelocity = (originImpulse or Vector3.zero) * 0.2 + Vector3.new(0, 32, 0)
		chassis.AssemblyAngularVelocity = Vector3.new(math.random(-4, 4), math.random(-5, 5), math.random(-4, 4))

		-- Sóng xung kích vụ nổ thổi vỡ gạch / cọc tiêu / dải phân cách xung quanh xe!
		DestructionManager.damageRadius(blastCenter, 20, 220, 58, car)

		Debris:AddItem(car, 10)
	end
end

-- Hàm trung tâm: Trừ máu ẩn (PartHealth) của bất kỳ Part nào khi bị ĐỤNG XE hoặc BỊ BẮN
function DestructionManager.damagePart(
	part: BasePart,
	amount: number,
	hitPos: Vector3?,
	impulseVec: Vector3?
): boolean
	if not part or not part.Parent or amount <= 0 then
		return false
	end

	-- Nếu bắn trực tiếp vào khung gầm/động cơ xe không phải vỏ rời => trừ thẳng EngineHealth!
	local parentCar = part:FindFirstAncestorOfClass("Model")
	if parentCar and parentCar:GetAttribute("IsGtaVehicle") == true and part:GetAttribute("Destructible") ~= true then
		DestructionManager.damageVehicleEngine(parentCar, amount * 0.85, impulseVec)
		emitHitChip(hitPos or part.Position, part, impulseVec or Vector3.new(0, 12, 0))
		return false
	end

	if part:GetAttribute("Destructible") ~= true then
		return false
	end
	if part:GetAttribute("_Shattered") == true then
		return false
	end

	ensureBaseColorSaved(part)

	local maxHp = tonumber(part:GetAttribute("MaxPartHealth"))
		or tonumber(part:GetAttribute("MaxIntegrity"))
		or 100
	local curHp = tonumber(part:GetAttribute("PartHealth"))
		or tonumber(part:GetAttribute("Integrity"))
		or maxHp

	local nextHp = math.max(0, curHp - amount)
	part:SetAttribute("PartHealth", nextHp)
	part:SetAttribute("Integrity", nextHp)

	local impulse = impulseVec or Vector3.new(0, 14, 0)
	local impactPt = hitPos or part.Position

	-- Nếu thuộc xe hơi, truyền một phần chấn động vào động cơ xe
	if part:GetAttribute("VehiclePart") == true and parentCar and parentCar:GetAttribute("IsGtaVehicle") == true then
		DestructionManager.damageVehicleEngine(parentCar, amount * 0.32, impulse)
	end

	if nextHp > 0 then
		-- Chưa hết máu ẩn: hiện vết sẫm màu / rạn kính & tia mảnh vụn nhỏ (KHÔNG hiện thanh máu thô!)
		emitHitChip(impactPt, part, impulse)
		local ratio = nextHp / math.max(1, maxHp)
		local origCol = getSavedBaseColor(part)

		if part.Material == Enum.Material.Glass then
			part.Color = origCol:Lerp(Color3.fromRGB(210, 230, 245), (1 - ratio) * 0.55)
			part.Transparency = math.clamp(0.18 + ratio * 0.25, 0.15, 0.5)
		elseif ratio <= 0.35 then
			part.Color = origCol:Lerp(Color3.fromRGB(24, 24, 28), 0.36)
		elseif ratio <= 0.70 then
			part.Color = origCol:Lerp(Color3.fromRGB(32, 32, 36), 0.18)
		end
		return false
	end

	-- ĐÃ HẾT SẠCH MÁU ẨN (nextHp <= 0) => TỰ ĐỘNG VỠ TUNG!
	part:SetAttribute("_Shattered", true)

	if part:GetAttribute("VehiclePart") == true then
		detachVehiclePanel(part, impulse)
	elseif part.Material == Enum.Material.Glass or part.Material == Enum.Material.Neon then
		shatterGlassOrLight(part, impulse)
	else
		fractureWorldBlock(part, impulse)
	end

	return true
end

-- Phá huỷ vùng (dùng cho cả Va chạm Mũi Xe Tốc Độ Cao lẫn Vụ Nổ!)
function DestructionManager.damageRadius(
	center: Vector3,
	radius: number,
	maxDamage: number,
	forceMag: number,
	ignoreInstance: Instance?
): number
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excludeList: { Instance } = { getDebrisFolder() }
	if ignoreInstance then
		table.insert(excludeList, ignoreInstance)
	end
	params.FilterDescendantsInstances = excludeList

	local hitParts = Workspace:GetPartBoundsInRadius(center, radius, params)
	local brokenCount = 0

	for _, hp in ipairs(hitParts) do
		if hp:IsA("BasePart") then
			local delta = hp.Position - center
			local dist = delta.Magnitude
			local falloff = math.clamp(1 - (dist / (radius + 2.5)), 0.25, 1)
			local dir = if dist > 0.05 then (delta / dist) else Vector3.new(0, 1, 0)
			local dmg = maxDamage * falloff
			if DestructionManager.damagePart(hp, dmg, center + dir * math.min(dist, 1.5), dir * (forceMag * falloff)) then
				brokenCount += 1
			end
		end
	end

	return brokenCount
end

return DestructionManager
