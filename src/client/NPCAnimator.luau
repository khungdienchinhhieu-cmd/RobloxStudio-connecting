--!nonstrict
--[[
	NPCAnimator.luau  —  ANIMATION CHO NPC (chạy ở CLIENT)
	================================================================================
	Vì sao làm ở client?
	  • Server chỉ đổi 1 attribute `AnimState` (IDLE/WALK/RUN/SHOOT/PUNCH/PHONE/DRIVE/DEAD).
	  • Client tự xoay Motor6D của rig -> 60 FPS mượt, KHÔNG tốn băng thông
	    (nếu server xoay Motor6D.C0 thì mỗi khung hình đều phải replicate cho mọi người chơi).

	Rig NPC do NPCManager dựng là R6 thật (Motor6D: RootJoint / Neck /
	Right Shoulder / Left Shoulder / Right Hip / Left Hip) nên xoay C0 là ra dáng đi.

	Các tư thế
	  IDLE   — thở nhẹ, tay đung đưa, đầu liếc nhìn
	  WALK   — sải chân vừa, tay vung ngược chiều
	  RUN    — sải chân lớn, người chúi tới (dùng cho CHẠY TRỐN)
	  SHOOT  — hai tay nâng súng, giật lùi theo nhịp bắn
	  PUNCH  — đấm liên hoàn (dùng cho ĐÁNH TAY KHÔNG)
	  PHONE  — một tay giơ điện thoại lên ngang đầu (QUAY VIDEO)
	  DRIVE  — ngồi trong xe: đùi gập, tay đặt vô lăng
	  DEAD   — ngã gục, tay chân duỗi
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local NPCAnimator = {}

local localPlayer = Players.LocalPlayer

local UPDATE_HZ = 24 -- 24 lần/giây là đủ mượt cho NPC nền
local CULL_DISTANCE = 260 -- bỏ qua NPC ở xa để không tốn CPU

type Rig = {
	model: Model,
	root: Motor6D?,
	neck: Motor6D?,
	rShoulder: Motor6D?,
	lShoulder: Motor6D?,
	rHip: Motor6D?,
	lHip: Motor6D?,
	phase: number,
	lastState: string,
}

local rigs: { [Model]: Rig } = {}

local function findMotor(model: Model, name: string): Motor6D?
	local inst = model:FindFirstChild(name, true)
	if inst and inst:IsA("Motor6D") then
		return inst
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

	local root = findMotor(model, "RootJoint")
	local neck = findMotor(model, "Neck")
	local rs = findMotor(model, "Right Shoulder")
	local ls = findMotor(model, "Left Shoulder")
	local rh = findMotor(model, "Right Hip")
	local lh = findMotor(model, "Left Hip")

	if not (rs and ls and rh and lh) then
		return
	end

	rigs[model] = {
		model = model,
		root = root,
		neck = neck,
		rShoulder = rs,
		lShoulder = ls,
		rHip = rh,
		lHip = lh,
		phase = math.random() * math.pi * 2,
		lastState = "IDLE",
	}
end

local function unregister(model: Instance)
	rigs[model] = nil
end

-- Áp tư thế
local function applyPose(rig: Rig, state: string, dt: number)
	-- mặc định: trả hết về tư thế gốc
	local rootOff = Vector3.zero
	local rootRot = Vector3.zero
	local neckRot = Vector3.zero
	local rsX, rsY, rsZ = 0, 0, 0
	local lsX, lsY, lsZ = 0, 0, 0
	local rhX, lhX = 0, 0

	if state == "WALK" then
		rig.phase += dt * 7.5
		local s = math.sin(rig.phase)
		local amp = 0.55
		rhX = s * amp
		lhX = -s * amp
		rsX = -s * amp * 0.85
		lsX = s * amp * 0.85
		rootOff = Vector3.new(0, math.abs(math.cos(rig.phase)) * 0.09, 0)
		neckRot = Vector3.new(0, math.sin(rig.phase * 0.5) * 0.16, 0)
	elseif state == "RUN" then
		rig.phase += dt * 11.5
		local s = math.sin(rig.phase)
		local amp = 0.95
		rhX = s * amp
		lhX = -s * amp
		rsX = -s * amp * 0.95
		lsX = s * amp * 0.95
		rootOff = Vector3.new(0, math.abs(math.cos(rig.phase)) * 0.16, 0)
		rootRot = Vector3.new(0.14, 0, 0) -- chúi người về trước
		neckRot = Vector3.new(-0.1, 0, 0)
	elseif state == "SHOOT" then
		-- hai tay nâng súng ngang ngực, giật theo nhịp bắn
		local recoil = math.abs(math.sin(os.clock() * 6)) * 0.08
		rsX = -1.45 - recoil
		rsY = -0.18
		lsX = -1.25
		lsY = 0.55
		neckRot = Vector3.new(-0.06, 0, 0)
	elseif state == "PUNCH" then
		-- đấm liên hoàn: tay phải ra vào nhanh
		local punch = (math.sin(os.clock() * 9) + 1) * 0.5 -- 0..1
		rsX = -0.55 - punch * 1.35
		rsY = -0.1 * punch
		lsX = -0.35
		lsY = 0.3
		rootRot = Vector3.new(0.06, -0.12 + punch * 0.24, 0)
	elseif state == "PHONE" then
		-- tay phải giơ điện thoại lên ngang đầu (quay video)
		rsX = -2.05
		rsZ = 0.55
		lsX = -0.15
		neckRot = Vector3.new(-0.08, -0.22, 0)
		rootOff = Vector3.new(0, math.sin(os.clock() * 1.6) * 0.02, 0)
	elseif state == "DRIVE" then
		-- ngồi: đùi gập về trước, tay đặt lên vô lăng, người nhún nhẹ
		rhX = -1.35
		lhX = -1.35
		rsX = -1.15
		lsX = -1.15
		rsY = -0.12
		lsY = 0.12
		rootOff = Vector3.new(0, math.sin(os.clock() * 5.5) * 0.02, 0)
		neckRot = Vector3.new(0, math.sin(os.clock() * 0.6) * 0.12, 0)
	elseif state == "DEAD" then
		rsX = 2.1
		lsX = 1.9
		rsZ = 0.5
		lsZ = -0.5
		rhX = -0.9
		lhX = 0.5
		rootRot = Vector3.new(0, 0, 1.45)
		neckRot = Vector3.new(0, 0, 0.45)
	else -- IDLE
		rig.phase += dt * 1.6
		local breathe = math.sin(rig.phase) * 0.045
		rsX = breathe
		lsX = -breathe
		rootOff = Vector3.new(0, breathe * 0.6, 0)
		neckRot = Vector3.new(0, math.sin(rig.phase * 0.45) * 0.3, 0)
	end

	-- Ghi vào Transform (KHÔNG replicate, không giành C0 với server)
	if rig.root then
		rig.root.Transform = CFrame.new(rootOff) * CFrame.Angles(rootRot.X, rootRot.Y, rootRot.Z)
	end
	if rig.neck then
		rig.neck.Transform = CFrame.Angles(neckRot.X, neckRot.Y, neckRot.Z)
	end
	rig.rShoulder.Transform = CFrame.Angles(rsX, rsY, rsZ)
	rig.lShoulder.Transform = CFrame.Angles(lsX, lsY, lsZ)
	rig.rHip.Transform = CFrame.Angles(rhX, 0, 0)
	rig.lHip.Transform = CFrame.Angles(lhX, 0, 0)
end

-- Theo dõi 1 thư mục: NPC đi bộ nằm phẳng trong LosSantos_NPCs,
-- còn TÀI XẾ nằm SÂU trong xe (LosSantos_Traffic/Xe/Driver) -> cần quét đệ quy.
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
		local trafficFolder = Workspace:WaitForChild("LosSantos_Traffic", 120)
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

		for model, rig in pairs(rigs) do
			if not model.Parent then
				rigs[model] = nil
				continue
			end

			-- cull theo khoảng cách
			local pivot = model:GetPivot().Position
			if (pivot - camPos).Magnitude > CULL_DISTANCE then
				continue
			end

			local state = model:GetAttribute("AnimState")
			if type(state) ~= "string" then
				state = "IDLE"
			end
			rig.lastState = state
			applyPose(rig, state, frameDt)
		end
	end)
end

return NPCAnimator
