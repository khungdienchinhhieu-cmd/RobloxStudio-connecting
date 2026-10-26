--!nonstrict
--[[
	NPCAnimator.luau  —  LỚP ANIMATION DỰ PHÒNG CHẠY Ở CLIENT
	================================================================================
	Kiến trúc 2 lớp (từ Sync v21):

	  LỚP 1 — ANIMATION THẬT CỦA ROBLOX  (ưu tiên)
	    Server gọi `Animator:LoadAnimation` với animation gốc của Roblox
	    (idle / walk / run) và tự Play/Stop theo tốc độ đi. Không cần file này.
	    Khi đó NPC có thuộc tính `UsesRealAnims = true`.

	  LỚP 2 — VẼ BẰNG MOTOR6D  (dự phòng, chính là file này)
	    Nếu Roblox không nạp được animation (mất mạng / asset bị chặn / rig tự ghép),
	    `UsesRealAnims = false` và client tự xoay khớp ở 24 Hz.
	    → NPC **luôn** có dáng đi, không bao giờ "trượt băng" như tượng.

	Hỗ trợ CẢ HAI loại rig:
	  • R15 (model Roblox thật): Waist / Neck / *Shoulder / *Elbow / *Hip / *Knee
	  • R6  (rig tự ghép dự phòng): RootJoint / Neck / "Right Shoulder" / "Right Hip"

	Ghi vào `Motor6D.Transform` (thuộc tính CỤC BỘ, không replicate) nên không tốn
	băng thông và không giành `C0` với server.

	Tư thế: IDLE · WALK · RUN · SHOOT · PUNCH · PHONE · DRIVE · DEAD
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local NPCAnimator = {}

local UPDATE_HZ = 24
local CULL_DISTANCE = 300

type Joints = {
	rigType: string,
	root: Motor6D?,
	waist: Motor6D?,
	neck: Motor6D?,
	shoulderR: Motor6D?,
	shoulderL: Motor6D?,
	elbowR: Motor6D?,
	elbowL: Motor6D?,
	hipR: Motor6D?,
	hipL: Motor6D?,
	kneeR: Motor6D?,
	kneeL: Motor6D?,
}

type Rig = {
	model: Model,
	j: Joints,
	phase: number,
	lastState: string,
}

local rigs: { [Model]: Rig } = {}

local function motor(model: Model, ...: string): Motor6D?
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		local inst = model:FindFirstChild(name, true)
		if inst and inst:IsA("Motor6D") then
			return inst
		end
	end
	return nil
end

local function collectJoints(model: Model): Joints?
	local r15ShoulderR = motor(model, "RightShoulder")
	local r15HipR = motor(model, "RightHip")

	if r15ShoulderR and r15HipR then
		return {
			rigType = "R15",
			root = motor(model, "Root"),
			waist = motor(model, "Waist"),
			neck = motor(model, "Neck"),
			shoulderR = r15ShoulderR,
			shoulderL = motor(model, "LeftShoulder"),
			elbowR = motor(model, "RightElbow"),
			elbowL = motor(model, "LeftElbow"),
			hipR = r15HipR,
			hipL = motor(model, "LeftHip"),
			kneeR = motor(model, "RightKnee"),
			kneeL = motor(model, "LeftKnee"),
		}
	end

	local r6ShoulderR = motor(model, "Right Shoulder")
	local r6HipR = motor(model, "Right Hip")
	if r6ShoulderR and r6HipR then
		return {
			rigType = "R6",
			root = motor(model, "RootJoint"),
			waist = nil,
			neck = motor(model, "Neck"),
			shoulderR = r6ShoulderR,
			shoulderL = motor(model, "Left Shoulder"),
			elbowR = nil,
			elbowL = nil,
			hipR = r6HipR,
			hipL = motor(model, "Left Hip"),
			kneeR = nil,
			kneeL = nil,
		}
	end

	return nil
end

local function register(model: Instance)
	if not model:IsA("Model") then
		return
	end
	if rigs[model] then
		return
	end
	if model:GetAttribute("IsGTA_NPC") ~= true then
		return
	end

	local joints = collectJoints(model)
	if not joints then
		return
	end

	rigs[model] = {
		model = model,
		j = joints,
		phase = math.random() * math.pi * 2,
		lastState = "IDLE",
	}
end

local function unregister(model: Instance)
	rigs[model] = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Áp tư thế
-- ─────────────────────────────────────────────────────────────────────────────

local function applyPose(rig: Rig, state: string, dt: number, clock: number)
	local j = rig.j

	-- Giá trị mặc định = đứng yên
	local rootOff = Vector3.zero
	local waistRot = Vector3.zero
	local neckRot = Vector3.zero
	local sR = Vector3.zero
	local sL = Vector3.zero
	local eR = Vector3.zero
	local eL = Vector3.zero
	local hR = 0
	local hL = 0
	local kR = 0
	local kL = 0

	if state == "WALK" then
		rig.phase += dt * 7.5
		local s = math.sin(rig.phase)
		local amp = 0.55
		hR = s * amp
		hL = -s * amp
		sR = Vector3.new(-s * amp * 0.85, 0, 0)
		sL = Vector3.new(s * amp * 0.85, 0, 0)
		kR = math.max(0, -s) * 0.75
		kL = math.max(0, s) * 0.75
		rootOff = Vector3.new(0, math.abs(math.cos(rig.phase)) * 0.09, 0)
		neckRot = Vector3.new(0, math.sin(rig.phase * 0.5) * 0.16, 0)
	elseif state == "RUN" then
		rig.phase += dt * 11.5
		local s = math.sin(rig.phase)
		local amp = 0.95
		hR = s * amp
		hL = -s * amp
		sR = Vector3.new(-s * amp * 0.95, 0, 0)
		sL = Vector3.new(s * amp * 0.95, 0, 0)
		kR = math.max(0, -s) * 1.15
		kL = math.max(0, s) * 1.15
		rootOff = Vector3.new(0, math.abs(math.cos(rig.phase)) * 0.16, 0)
		waistRot = Vector3.new(0.14, 0, 0)
		neckRot = Vector3.new(-0.1, 0, 0)
	elseif state == "SHOOT" then
		local recoil = math.abs(math.sin(clock * 6)) * 0.08
		sR = Vector3.new(-1.45 - recoil, -0.18, 0)
		sL = Vector3.new(-1.25, 0.55, 0)
		eR = Vector3.new(0, 0, -0.5)
		neckRot = Vector3.new(-0.06, 0, 0)
	elseif state == "PUNCH" then
		local punch = (math.sin(clock * 9) + 1) * 0.5
		sR = Vector3.new(-0.55 - punch * 1.35, -0.1 * punch, 0)
		sL = Vector3.new(-0.35, 0.3, 0)
		waistRot = Vector3.new(0.06, -0.12 + punch * 0.24, 0)
	elseif state == "PHONE" then
		sR = Vector3.new(-2.05, 0, 0.55)
		sL = Vector3.new(-0.15, 0, 0)
		neckRot = Vector3.new(-0.08, -0.22, 0)
		rootOff = Vector3.new(0, math.sin(clock * 1.6) * 0.02, 0)
	elseif state == "DRIVE" then
		hR = -1.35
		hL = -1.35
		kR = 1.3
		kL = 1.3
		sR = Vector3.new(-1.15, -0.12, 0)
		sL = Vector3.new(-1.15, 0.12, 0)
		eR = Vector3.new(0, 0, -0.35)
		eL = Vector3.new(0, 0, 0.35)
		rootOff = Vector3.new(0, math.sin(clock * 5.5) * 0.02, 0)
		neckRot = Vector3.new(0, math.sin(clock * 0.6) * 0.12, 0)
	elseif state == "DEAD" then
		sR = Vector3.new(2.1, 0, 0.5)
		sL = Vector3.new(1.9, 0, -0.5)
		hR = -0.9
		hL = 0.5
		kR = 0.6
		kL = 0.3
		waistRot = Vector3.new(0, 0, 1.45)
		neckRot = Vector3.new(0, 0, 0.45)
	else -- IDLE
		rig.phase += dt * 1.6
		local breathe = math.sin(rig.phase) * 0.045
		sR = Vector3.new(breathe, 0, 0.04)
		sL = Vector3.new(-breathe, 0, -0.04)
		rootOff = Vector3.new(0, breathe * 0.6, 0)
		neckRot = Vector3.new(0, math.sin(rig.phase * 0.45) * 0.3, 0)
	end

	if j.root then
		j.root.Transform = CFrame.new(rootOff)
	end
	if j.waist then
		j.waist.Transform = CFrame.Angles(waistRot.X, waistRot.Y, waistRot.Z)
	end
	if j.neck then
		j.neck.Transform = CFrame.Angles(neckRot.X, neckRot.Y, neckRot.Z)
	end
	if j.shoulderR then
		j.shoulderR.Transform = CFrame.Angles(sR.X, sR.Y, sR.Z)
	end
	if j.shoulderL then
		j.shoulderL.Transform = CFrame.Angles(sL.X, sL.Y, sL.Z)
	end
	if j.elbowR then
		j.elbowR.Transform = CFrame.Angles(eR.X, eR.Y, eR.Z)
	end
	if j.elbowL then
		j.elbowL.Transform = CFrame.Angles(eL.X, eL.Y, eL.Z)
	end
	if j.hipR then
		j.hipR.Transform = CFrame.Angles(hR, 0, 0)
	end
	if j.hipL then
		j.hipL.Transform = CFrame.Angles(hL, 0, 0)
	end
	if j.kneeR then
		j.kneeR.Transform = CFrame.Angles(kR, 0, 0)
	end
	if j.kneeL then
		j.kneeL.Transform = CFrame.Angles(kL, 0, 0)
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Theo dõi thư mục (NPC đi bộ nằm phẳng, tài xế nằm sâu trong xe)
-- ─────────────────────────────────────────────────────────────────────────────

local function watchFolder(folder: Instance, recursive: boolean)
	local function tryAdd(inst: Instance)
		if inst:IsA("Model") and inst:GetAttribute("IsGTA_NPC") == true then
			task.defer(register, inst)
		end
	end

	if recursive then
		for _, d in ipairs(folder:GetDescendants()) do
			tryAdd(d)
		end
		folder.DescendantAdded:Connect(tryAdd)
	else
		for _, child in ipairs(folder:GetChildren()) do
			register(child)
		end
		folder.ChildAdded:Connect(function(child)
			task.defer(register, child)
		end)
	end

	folder.DescendantRemoving:Connect(function(inst)
		if inst:IsA("Model") then
			unregister(inst)
		end
	end)
end

function NPCAnimator.mount()
	local folder = Workspace:WaitForChild("LosSantos_NPCs", 60)
	if folder then
		watchFolder(folder, false)
	end

	task.spawn(function()
		local trafficFolder = Workspace:WaitForChild("LosSantos_Traffic", 200)
		if trafficFolder then
			watchFolder(trafficFolder, true)
		end
	end)

	local accum = 0
	local step = 1 / UPDATE_HZ

	RunService.Heartbeat:Connect(function(dt)
		accum += dt
		if accum < step then
			return
		end
		local frameDt = accum
		accum = 0

		local cam = Workspace.CurrentCamera
		local camPos = if cam then cam.CFrame.Position else Vector3.zero
		local clock = os.clock()

		for model, rig in pairs(rigs) do
			if not model.Parent then
				rigs[model] = nil
				continue
			end

			local pivot = model:GetPivot().Position
			if (pivot - camPos).Magnitude > CULL_DISTANCE then
				continue
			end

			local state = model:GetAttribute("AnimState")
			if type(state) ~= "string" then
				state = "IDLE"
			end
			rig.lastState = state

			-- LỚP 1: Roblox đang tự phát animation thật -> không vẽ đè.
			-- Ngoại lệ DUY NHẤT là DRIVE: server đã dừng animation thật để
			-- nhân vật ngồi gọn trong ghế, nên client phải vẽ tư thế ngồi.
			local real = model:GetAttribute("UsesRealAnims") == true
			if real and state ~= "DRIVE" then
				continue
			end

			applyPose(rig, state, frameDt, clock)
		end
	end)
end

return NPCAnimator
