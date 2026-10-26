--!nonstrict
--[[
	MugClient.luau — CƯỚP VÍ (phím T)
	Client chỉ chọn NPC gần nhất rồi gửi lên server. Server tự kiểm tra
	khoảng cách, cooldown và loại NPC; client không quyết định gì về tiền.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local MugClient = {}

local NPC_FOLDER_NAME = "LosSantos_NPCs"
local RANGE = 7 -- phải khớp MUG_RANGE phía server (server là bên quyết định)
local KEY = Enum.KeyCode.T

function MugClient.mount(localPlayer: Player)
	local remotes = ReplicatedStorage:WaitForChild("GtaRemotes")
	local mugRemote = remotes:WaitForChild("MugRequest") :: RemoteEvent

	local function nearestNpc(): Model?
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local folder = Workspace:FindFirstChild(NPC_FOLDER_NAME)
		if not root or not folder then
			return nil
		end
		local best, bestD = nil, RANGE
		for _, m in ipairs(folder:GetChildren()) do
			if m:IsA("Model") then
				local hrp = m:FindFirstChild("HumanoidRootPart")
				local hum = m:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local d = (hrp.Position - root.Position).Magnitude
					if d <= bestD then
						best, bestD = m, d
					end
				end
			end
		end
		return best
	end

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or input.KeyCode ~= KEY then
			return
		end
		local target = nearestNpc()
		if target then
			mugRemote:FireServer(target)
		end
	end)
end

return MugClient
