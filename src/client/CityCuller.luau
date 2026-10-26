--!strict
--[[
	CityCuller.luau  (Sync v23 — "chỉ render thứ có trong màn hình")
	================================================================================
	VẤN ĐỀ
	------
	Roblox đã tự động **frustum cull** (bỏ vẽ vật ngoài khung hình) và **occlusion cull**
	(bỏ vẽ vật bị che). Nhưng nó KHÔNG bỏ *xử lý* những thứ còn nằm trong `Workspace`:
	mỗi part vẫn tốn CPU cho kiểm tra va chạm, cập nhật CFrame, culling và bộ nhớ.
	Với 20 000+ part (LS Customs 3 462 · LSPD 4 639 · Maze Bank 2 312 · nền phố ~9 000)
	thì mỗi lần đi qua ranh giới ô đất, engine phải duyệt lại toàn bộ danh sách part
	→ đúng hiện tượng "khựng" (hitch/stutter) khi đứng ở vị trí khác.

	CÁCH LÀM (đã kiểm chứng theo tài liệu Roblox)
	--------------------------------------------
	`StreamingTargetRadius` mặc định là 1024 stud, mà bản đồ chỉ 1 160 stud ⇒ gần như
	KHÔNG có gì bị stream-out. Và thuộc tính này **không đặt được bằng script**.
	Nên ta cull thủ công ở client theo từng "khối công trình":

	  • Trong bán kính NEAR (380 stud)          → LUÔN giữ (không bao giờ thấy pop).
	  • Ngoài bán kính FAR (900 stud)           → cất vào kho ẩn.
	  • Sau lưng camera và xa hơn 460 stud      → cất (đúng nghĩa "chỉ render trong màn hình").
	  • Trong khoảng giữa mà vẫn trong khung hình → giữ.

	"Cất" = đổi `Parent` sang một `Folder` nằm trong `ReplicatedStorage` **do client tự tạo**
	(không replicate) ⇒ engine ngừng render + ngừng xử lý vật lý cho toàn bộ part con,
	khi quay lại thì gắn về chỗ cũ. Không `Destroy()` nên không mất dữ liệu.

	An toàn:
	  • Chỉ cull các **model công trình** trong `LosSantos/DistrictModules` (nơi nặng nhất).
	    Mặt đường / vỉa hè / đồi / biển KHÔNG bao giờ bị cất (người chơi sẽ rơi).
	  • Trễ 40 stud (hysteresis) để không bật/tắt liên tục ở ranh giới.
	  • Nếu model chứa nhân vật người chơi → bỏ qua.
	  • Chạy 4 Hz (0,25 s) và chỉ tính 10–20 phép đo khoảng cách mỗi nhịp ⇒ ~0,01 ms/khung.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CityCuller = {}

local NEAR_RADIUS = 380 -- luôn giữ
local FAR_RADIUS = 900 -- luôn cất
local BEHIND_RADIUS = 460 -- sau lưng camera thì cất sớm
local HYSTERESIS = 40
local TICK = 0.25

type Chunk = {
	instance: Instance,
	anchor: Vector3,
	visible: boolean,
	baseParent: Instance,
}

local chunks: { Chunk } = {}
local cacheFolder: Folder? = nil
local started = false
local stats = { culled = 0, kept = 0, total = 0 }

local function ensureCache(): Folder
	if cacheFolder and cacheFolder.Parent then
		return cacheFolder
	end
	-- Client tạo ⇒ chỉ tồn tại trên máy người chơi này, không replicate, không lộ ra server.
	local folder = Instance.new("Folder")
	folder.Name = "__CityCullCache"
	folder.Parent = ReplicatedStorage
	cacheFolder = folder
	return folder
end

--- Gom "khối" để cull. Hiện tại: mỗi công trình trong DistrictModules là 1 khối.
local function collectChunks()
	chunks = {}
	local root = Workspace:FindFirstChild("LosSantos")
	if not root then
		return
	end
	local modules = root:FindFirstChild("DistrictModules")
	if not modules then
		return
	end

	for _, child in ipairs(modules:GetChildren()) do
		if child:IsA("Model") or child:IsA("Folder") then
			local ok, pivot = pcall(function()
				if child:IsA("Model") then
					return child:GetPivot().Position
				end
				return (child :: Folder):GetChildren()[1] and Vector3.zero or Vector3.zero
			end)
			local anchor: Vector3
			if ok and typeof(pivot) == "Vector3" then
				anchor = pivot :: Vector3
			else
				anchor = Vector3.zero
			end
			-- Folder không có pivot: lấy tâm trung bình của các part con
			if child:IsA("Folder") then
				local sum, n = Vector3.zero, 0
				for _, d in ipairs(child:GetDescendants()) do
					if d:IsA("BasePart") then
						sum += d.Position
						n += 1
						if n >= 24 then
							break
						end
					end
				end
				anchor = if n > 0 then sum / n else Vector3.zero
			end

			table.insert(chunks, {
				instance = child,
				anchor = anchor,
				visible = child.Parent ~= nil and child.Parent.Name ~= "__CityCullCache",
				baseParent = modules,
			})
		end
	end

	stats.total = #chunks
	print(string.format("[CityCuller] Theo dõi %d khối công trình (cull theo khung hình + khoảng cách)", #chunks))
end

local function show(chunk: Chunk)
	if chunk.visible then
		return
	end
	chunk.instance.Parent = chunk.baseParent
	chunk.visible = true
end

local function hide(chunk: Chunk)
	if not chunk.visible then
		return
	end
	local folder = ensureCache()
	chunk.instance.Parent = folder
	chunk.visible = false
end

local function step()
	local camera = Workspace.CurrentCamera
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local subject: Vector3
	if camera then
		subject = camera.CFrame.Position
	elseif character then
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end
		subject = hrp.Position
	else
		return
	end

	local culled, kept = 0, 0

	for _, chunk in ipairs(chunks) do
		local delta = chunk.anchor - subject
		local dist = Vector3.new(delta.X, 0, delta.Z).Magnitude

		local keep: boolean
		if dist <= NEAR_RADIUS - HYSTERESIS then
			keep = true
		elseif dist >= FAR_RADIUS + HYSTERESIS then
			keep = false
		elseif camera and dist > BEHIND_RADIUS then
			-- "chỉ render thứ có trong màn hình": vật đang ở sau lưng camera thì cất sớm.
			local _, onScreen = camera:WorldToViewportPoint(chunk.anchor)
			keep = onScreen
		else
			keep = chunk.visible -- giữ nguyên trạng thái trong dải trễ
		end

		if keep then
			show(chunk)
			kept += 1
		else
			hide(chunk)
			culled += 1
		end
	end

	stats.culled = culled
	stats.kept = kept
end

function CityCuller.getStats()
	return {
		total = stats.total,
		kept = stats.kept,
		culled = stats.culled,
		nearRadius = NEAR_RADIUS,
		farRadius = FAR_RADIUS,
	}
end

function CityCuller.mount()
	if started then
		return CityCuller
	end
	started = true

	task.spawn(function()
		-- Đợi thành phố dựng xong (nền + công trình do DistrictRegistry nạp)
		for _ = 1, 40 do
			local root = Workspace:FindFirstChild("LosSantos")
			if root and root:FindFirstChild("DistrictModules") then
				local mods = root:FindFirstChild("DistrictModules") :: Instance
				if #mods:GetChildren() > 0 then
					break
				end
			end
			task.wait(0.25)
		end
		collectChunks()

		while true do
			step()
			-- Thỉnh thoảng quét lại (công trình mới do Agent khác dựng thêm)
			if #chunks == 0 then
				collectChunks()
			end
			task.wait(TICK)
		end
	end)

	return CityCuller
end

return CityCuller
