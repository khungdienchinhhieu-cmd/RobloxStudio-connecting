--!strict
--[[
	PerfOptimizer.luau
	================================================================================
	LỚP TỐI ƯU HIỆU NĂNG TỰ ĐỘNG (chạy 1 lần sau khi dựng xong thành phố)
	================================================================================
	Dựa trên tài liệu chính thức của Roblox:
	  • create.roblox.com/docs/performance-optimization/improve
	  • create.roblox.com/docs/workspace/streaming/techniques
	  • devforum.roblox.com/t/all-about-text-best-practices/1515743
	  • devforum.roblox.com/t/new-surfaceguimaxdistance-property/2574715

	5 QUY TẮC (an toàn tuyệt đối với cơ chế phá huỷ):
	  1. `CanTouch = false` cho TOÀN BỘ part tĩnh — dự án không dùng sự kiện .Touched
	     (xe tông dùng OverlapParams, súng dùng Raycast) → bỏ hẳn TouchTransmitter.
	  2. Part trang trí NHỎ & KHÔNG phá huỷ (viền kính, nan cửa, chữ nổi, ốc vít…):
	     `CanCollide = false` + `CanTouch = false` + `CanQuery = false`
	     → engine loại khỏi broadphase va chạm hoàn toàn (theo docs: cả 3 false thì
	     part "will never need to compute any kind of part to part collisions").
	  3. Part CÓ MÁU ẨN (Destructible): giữ `CanQuery = true` (đạn bắn + quét va chạm xe
	     cần CanQuery); chỉ tắt `CanCollide` với khối mỏng < 1.2 stud để xe không bị
	     "vấp" vào viền kính / chữ nổi trong khi vẫn phá huỷ được.
	  4. `CastShadow = false` cho mọi part nhỏ (< 2.6 stud), part trong suốt và Neon
	     → giảm hẳn chi phí shadow map (đây là khoản tốn GPU lớn nhất của map 8.000 part).
	  5. `EnableFluidForces = false` toàn bộ + SurfaceGui: đặt `MaxDistance`
	     và hạ `PixelsPerStud` của biển lớn (canvas 1840px → 1104px).
  6. XE HƠI (`IsGtaVehicle`) được BỎ QUA hoàn toàn — bánh/cản/kính nhỏ nhưng cần va chạm thật.
]]

local PerfOptimizer = {}

export type PerfReport = {
	totalParts: number,
	collidableBefore: number,
	collidableAfter: number,
	touchableBefore: number,
	touchableAfter: number,
	queryableBefore: number,
	queryableAfter: number,
	shadowCastersBefore: number,
	shadowCastersAfter: number,
	surfaceGuis: number,
	fluidForcesDisabled: number,
	attributesRemoved: number,
	elapsedMs: number,
}

-- Part nhỏ hơn ngưỡng này + KHÔNG phá huỷ => tắt sạch va chạm/raycast/touch
local DECOR_MAX_DIM = 3.0
-- Part chi tiết rất nhỏ (chữ nổi, viền kính, ốc vít, hộp hàng trên kệ…) => không chặn vật lý
local TINY_MAX_DIM = 1.6
-- Vật phẩm phá huỷ nhỏ nằm trên cao (hàng hoá trên kệ, đồ treo tường) => không chặn vật lý
local PROP_MAX_DIM = 2.6
local PROP_MIN_BOTTOM = 3.2
-- Part nằm cao hơn tầm với của người chơi => chỉ giữ va chạm cho sàn đi được / khối lớn
local HIGH_BOTTOM = 8.0
local STRUCTURAL_MAX_DIM = 6.0
-- Mặt sàn/mái đi được: mỏng + rộng => LUÔN giữ va chạm ở mọi độ cao
local PLATFORM_MAX_THICK = 1.3
local PLATFORM_MIN_SPAN = 4.0
-- Part nhỏ hơn ngưỡng này => tắt đổ bóng
local SHADOW_MAX_DIM = 2.6
-- Canvas SurfaceGui tối đa (px) để tránh cấp phát texture quá lớn
local MAX_SURFACE_PIXELS = 1100
local SURFACE_MAX_DISTANCE = 340

local function maxDim(size: Vector3): number
	return math.max(size.X, math.max(size.Y, size.Z))
end

local function isDestructible(part: BasePart): boolean
	return part:GetAttribute("Destructible") == true
end

-- Xe hơi là NGOẠI LỆ: bánh xe / cản / kính lái rất nhỏ nhưng BẮT BUỘC giữ va chạm,
-- CanQuery (đạn bắn trúng) và CanTouch. Bỏ qua toàn bộ part thuộc xe.
local function isVehiclePart(part: BasePart): boolean
	if part:GetAttribute("VehiclePart") == true then
		return true
	end
	local node: Instance? = part.Parent
	local depth = 0
	while node and depth < 4 do
		if node:GetAttribute("IsGtaVehicle") == true then
			return true
		end
		node = node.Parent
		depth += 1
	end
	return false
end

function PerfOptimizer.optimize(root: Instance): PerfReport
	local started = os.clock()

	local report: PerfReport = {
		totalParts = 0,
		collidableBefore = 0,
		collidableAfter = 0,
		touchableBefore = 0,
		touchableAfter = 0,
		queryableBefore = 0,
		queryableAfter = 0,
		shadowCastersBefore = 0,
		shadowCastersAfter = 0,
		surfaceGuis = 0,
		fluidForcesDisabled = 0,
		attributesRemoved = 0,
		elapsedMs = 0,
	}

	local surfaceGuis: { SurfaceGui } = {}
	local destructibleTotal = 0

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("SurfaceGui") then
			table.insert(surfaceGuis, descendant)
			continue
		end
		if not descendant:IsA("BasePart") then
			continue
		end

		local part = descendant
		if isVehiclePart(part) then
			continue -- xe tự quản lý va chạm / máu riêng, không tối ưu ở đây
		end
		report.totalParts += 1

		if part.CanCollide then
			report.collidableBefore += 1
		end
		if part.CanTouch then
			report.touchableBefore += 1
		end
		if part.CanQuery then
			report.queryableBefore += 1
		end
		if part.CastShadow then
			report.shadowCastersBefore += 1
		end

		local size = part.Size
		local dim = maxDim(size)
		local destructible = isDestructible(part)
		if destructible then
			destructibleTotal += 1
		end

		-- (1) Không dùng .Touched ở bất kỳ đâu -> tắt cho tất cả
		part.CanTouch = false

		-- (2)+(3) Lọc va chạm theo 3 tầng ưu tiên (an toàn cho cơ chế phá huỷ)
		local bottomY = part.Position.Y - size.Y * 0.5
		local isPlatform = size.Y <= PLATFORM_MAX_THICK and size.X >= PLATFORM_MIN_SPAN and size.Z >= PLATFORM_MIN_SPAN

		if isPlatform then
			-- Sàn / mái / gác lửng đi được: luôn giữ va chạm để nhân vật không rơi xuyên
			part.CanCollide = true
		elseif not destructible then
			if dim < DECOR_MAX_DIM then
				part.CanCollide = false
				part.CanQuery = false
			end
		else
			local killCollision = dim < TINY_MAX_DIM
			if not killCollision and dim < PROP_MAX_DIM and bottomY > PROP_MIN_BOTTOM then
				killCollision = true -- hàng hoá trên kệ: bắn vỡ được nhưng không chặn đường đi
			end
			if not killCollision and bottomY > HIGH_BOTTOM and dim < STRUCTURAL_MAX_DIM then
				killCollision = true -- biển hiệu / đồ treo cao: chỉ cần CanQuery cho đạn & xe
			end
			if killCollision then
				part.CanCollide = false
			end
			-- CanQuery LUÔN = true cho part phá huỷ (đạn bắn + quét va chạm xe cần)
			part.CanQuery = true
		end

		-- (4) Đổ bóng: chỉ giữ cho khối lớn / đục
		local material = part.Material
		local isGlow = material == Enum.Material.Neon
		if dim < SHADOW_MAX_DIM or part.Transparency > 0.05 or isGlow then
			part.CastShadow = false
		end

		-- (5) Fluid forces (chỉ tốn với part không neo, nhưng tắt luôn cho chắc)
		local okFluid = pcall(function()
			part.EnableFluidForces = false
		end)
		if okFluid then
			report.fluidForcesDisabled += 1
		end

		-- (6) Gộp thuộc tính trùng lặp: MaxIntegrity/Integrity luôn == MaxPartHealth/PartHealth
		if destructible then
			local hasMaxIntegrity = part:GetAttribute("MaxIntegrity") ~= nil
			local hasIntegrity = part:GetAttribute("Integrity") ~= nil
			if hasMaxIntegrity then
				part:SetAttribute("MaxIntegrity", nil)
				report.attributesRemoved += 1
			end
			if hasIntegrity then
				part:SetAttribute("Integrity", nil)
				report.attributesRemoved += 1
			end
		end

		if part.CanCollide then
			report.collidableAfter += 1
		end
		if part.CanTouch then
			report.touchableAfter += 1
		end
		if part.CanQuery then
			report.queryableAfter += 1
		end
		if part.CastShadow then
			report.shadowCastersAfter += 1
		end
	end

	-- SurfaceGui: giới hạn khoảng cách vẽ + hạ mật độ điểm ảnh cho biển lớn
	for _, gui in ipairs(surfaceGuis) do
		report.surfaceGuis += 1
		if gui.MaxDistance <= 0 then
			gui.MaxDistance = SURFACE_MAX_DISTANCE
		else
			gui.MaxDistance = math.min(gui.MaxDistance, SURFACE_MAX_DISTANCE)
		end
		-- Adornee mặc định = part mà SurfaceGui gắn vào (nếu không set tường minh)
		local adornee = gui.Adornee or gui.Parent
		if adornee and adornee:IsA("BasePart") and gui.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud then
			local adorneeSize = (adornee :: BasePart).Size
			local longest = math.max(adorneeSize.X, math.max(adorneeSize.Y, adorneeSize.Z))
			local pps = gui.PixelsPerStud or 50
			if longest * pps > MAX_SURFACE_PIXELS then
				gui.PixelsPerStud = math.max(12, math.floor((MAX_SURFACE_PIXELS / longest) * 10) / 10)
			end
		end
	end

	report.elapsedMs = math.floor((os.clock() - started) * 10000) / 10

	-- Ghi số liệu lên root để QA Radar / HUD đọc được
	local data = root:FindFirstChild("LosSantos") or root
	data:SetAttribute("PerfTotalParts", report.totalParts)
	data:SetAttribute("PerfCollidable", report.collidableAfter)
	data:SetAttribute("PerfShadowCasters", report.shadowCastersAfter)
	data:SetAttribute("PerfDestructible", destructibleTotal)

	print(string.format(
		"[PerfOptimizer] %d parts | CanCollide %d → %d | CanTouch %d → %d | CanQuery %d → %d | CastShadow %d → %d | SurfaceGui %d | -%d attributes | %.1f ms",
		report.totalParts,
		report.collidableBefore,
		report.collidableAfter,
		report.touchableBefore,
		report.touchableAfter,
		report.queryableBefore,
		report.queryableAfter,
		report.shadowCastersBefore,
		report.shadowCastersAfter,
		report.surfaceGuis,
		report.attributesRemoved,
		report.elapsedMs
	))

	return report
end

return PerfOptimizer
