--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CityFoundation = require(Shared:WaitForChild("World"):WaitForChild("CityFoundation"))
local DistrictRegistry = require(Shared:WaitForChild("World"):WaitForChild("DistrictRegistry"))
local VehicleManager = require(script:WaitForChild("VehicleManager"))
local WeaponManager = require(script:WaitForChild("WeaponManager"))

-- Tạo thư mục RemoteEvents phục vụ HUD, Xe & Vũ khí GTA V
local remotesFolder = ReplicatedStorage:FindFirstChild("GtaRemotes")
if not remotesFolder then
	local createdFolder = Instance.new("Folder")
	createdFolder.Name = "GtaRemotes"
	createdFolder.Parent = ReplicatedStorage
	remotesFolder = createdFolder
end
local activeRemotes = remotesFolder :: Instance

local hudRemote = activeRemotes:FindFirstChild("HudAction") :: RemoteEvent?
if not hudRemote then
	local created = Instance.new("RemoteEvent")
	created.Name = "HudAction"
	created.Parent = activeRemotes
	hudRemote = created
end
local activeHudRemote = hudRemote :: RemoteEvent

if not activeRemotes:FindFirstChild("WeaponFire") then
	local wf = Instance.new("RemoteEvent")
	wf.Name = "WeaponFire"
	wf.Parent = activeRemotes
end

-- 1. Dựng Nền Thành Phố ghép khối có máu ẩn + Tự động nạp mọi Công Trình Đa-Agent trong World/Modules
local losSantosRoot = CityFoundation.build(false)
DistrictRegistry.buildAll(losSantosRoot)

-- 2. Khởi chạy Đội Xe Hơi GTA V (vật lý lái + đụng xe trừ máu ẩn PartHealth) & Vũ Khí bắn vỡ khối
VehicleManager.init()
WeaponManager.init(activeRemotes)

local STARTING_CASH = 5000

local function setupPlayer(player: Player)
	player:SetAttribute("Cash", STARTING_CASH)
	player:SetAttribute("Armor", 65)
	player:SetAttribute("WantedLevel", 0)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashStat = Instance.new("IntValue")
	cashStat.Name = "Cash"
	cashStat.Value = STARTING_CASH
	cashStat.Parent = leaderstats
end

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end
Players.PlayerAdded:Connect(setupPlayer)

-- Xử lý lệnh từ Menu Kiểm Thử [H]
activeHudRemote.OnServerEvent:Connect(function(player, cmd)
	if cmd == "spawn_car" then
		local car = VehicleManager.spawnForPlayer(player)
		if car then
			activeHudRemote:FireClient(player, {
				message = string.format("Legendary Motorsport: Đã giao siêu xe %s ngay trước mặt bạn!", car.Name),
				color = Color3.fromRGB(56, 189, 248),
			})
		end
	elseif cmd == "add_star" then
		local cur = tonumber(player:GetAttribute("WantedLevel")) or 0
		local nxt = math.min(5, cur + 1)
		player:SetAttribute("WantedLevel", nxt)
		activeHudRemote:FireClient(player, {
			message = string.format("LSPD ALERT: Mức truy nã hiện tại là %d Sao!", nxt),
			color = Color3.fromRGB(239, 68, 68),
		})
	elseif cmd == "clear_stars" then
		player:SetAttribute("WantedLevel", 0)
		activeHudRemote:FireClient(player, {
			message = "LSPD đã ngừng truy đuổi. Bạn đã thoát truy nã!",
			color = Color3.fromRGB(86, 186, 86),
		})
	elseif cmd == "add_cash" then
		local nextCash = (tonumber(player:GetAttribute("Cash")) or 0) + 500
		player:SetAttribute("Cash", nextCash)
		local ls = player:FindFirstChild("leaderstats")
		local cs = if ls then ls:FindFirstChild("Cash") else nil
		if cs and cs:IsA("IntValue") then
			cs.Value = nextCash
		end
		activeHudRemote:FireClient(player, {
			message = "Maze Bank: Đã nhận +$500 vào tài khoản tiền mặt.",
			color = Color3.fromRGB(114, 204, 114),
		})
	elseif cmd == "add_armor" then
		local curA = tonumber(player:GetAttribute("Armor")) or 0
		local nxtA = if curA >= 100 then 0 else math.min(100, curA + 50)
		player:SetAttribute("Armor", nxtA)
		activeHudRemote:FireClient(player, {
			message = string.format("Ammu-Nation: Áo giáp chống đạn hiện tại %d%%.", nxtA),
			color = Color3.fromRGB(59, 155, 232),
		})
	elseif cmd == "test_hp" then
		local char = player.Character
		local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		if hum then
			if hum.Health <= 30 then
				hum.Health = hum.MaxHealth
				activeHudRemote:FireClient(player, {
					message = "Los Santos Medical: Đã hồi phục 100% máu!",
					color = Color3.fromRGB(86, 186, 86),
				})
			else
				hum.Health = math.max(20, hum.Health - 30)
				activeHudRemote:FireClient(player, {
					message = "Cảnh báo sát thương! Nhấn lần nữa khi <30% để hồi đầy máu.",
					color = Color3.fromRGB(239, 68, 68),
				})
			end
		end
	end
end)
