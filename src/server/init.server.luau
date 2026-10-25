--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CityConfig = require(Shared:WaitForChild("CityConfig"))
local CityGenerator = require(Shared:WaitForChild("CityGenerator"))

local CitySimulation = require(script:WaitForChild("CitySimulation"))
local InteractionManager = require(script:WaitForChild("InteractionManager"))

-- Tạo thư mục RemoteEvents kết nối Server -> Client UI
local remotesFolder = ReplicatedStorage:FindFirstChild("CityRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "CityRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

local notifyRemote = remotesFolder:FindFirstChild("NotifyClient") :: RemoteEvent?
if not notifyRemote then
	local created = Instance.new("RemoteEvent")
	created.Name = "NotifyClient"
	created.Parent = remotesFolder
	notifyRemote = created
end

-- Bảo đảm Thành Phố Tương Tác đã được khởi tạo trong Workspace
CityGenerator.buildCity(false)

local function setupPlayer(player: Player)
	player:SetAttribute("Cash", CityConfig.StartingCash)
	player:SetAttribute("DeliveryTargetId", "")
	player:SetAttribute("DeliveryTargetName", "")
	player:SetAttribute("DeliveryStreak", 0)
	player:SetAttribute("SpeedBoostValue", 0)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashStat = Instance.new("IntValue")
	cashStat.Name = "Tiền ($)"
	cashStat.Value = CityConfig.StartingCash
	cashStat.Parent = leaderstats

	task.delay(1.5, function()
		if player.Parent and notifyRemote then
			notifyRemote:FireClient(player, {
				kind = "info",
				title = "🌆 Chào mừng đến Thành Phố Ánh Sáng!",
				body = "Nhấn [E] tại các cửa hàng, ATM, thang máy, NPC • Giữ [Shift] chạy nhanh • Lên xe ngay đại lộ để lái!",
			})
		end
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end
Players.PlayerAdded:Connect(setupPlayer)

CitySimulation.start()
InteractionManager.start(notifyRemote :: RemoteEvent)

print("[Thành Phố Ánh Sáng] Server đã khởi động hoàn tất!")
