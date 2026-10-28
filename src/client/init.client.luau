--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GtaRemotes")
local hudRemote = remotes:WaitForChild("HudAction") :: RemoteEvent
local weaponRemote = remotes:WaitForChild("WeaponFire") :: RemoteEvent
local weaponSync = remotes:WaitForChild("WeaponSync") :: RemoteEvent
local weaponReload = remotes:WaitForChild("WeaponReload") :: RemoteEvent

local GtaHud = require(script:WaitForChild("UI"):WaitForChild("GtaHud"))
local VehiclePromptUI = require(script:WaitForChild("UI"):WaitForChild("VehiclePromptUI"))
local LSCustomsUI = require(script:WaitForChild("UI"):WaitForChild("LSCustomsUI"))
local WeaponClient = require(script:WaitForChild("WeaponClient"))
local GtaWeaponWheel = require(script:WaitForChild("UI"):WaitForChild("GtaWeaponWheel"))
local NPCAnimator = require(script:WaitForChild("NPCAnimator"))
local CityCuller = require(script:WaitForChild("CityCuller"))
local CarryClient = require(script:WaitForChild("CarryClient"))
local MugClient = require(script:WaitForChild("MugClient"))
local FirstPersonCamera = require(script:WaitForChild("FirstPersonCamera"))

GtaHud.mount(localPlayer, hudRemote)
VehiclePromptUI.mount(localPlayer)
LSCustomsUI.mount(localPlayer)
WeaponClient.mount(localPlayer, weaponRemote)
GtaWeaponWheel.mount(localPlayer, weaponSync, weaponReload)

-- Dáng đi / đứng / ngồi lái / bắn của NPC: xoay Motor6D ngay trên máy người chơi
NPCAnimator.mount()

-- CHỈ RENDER THỨ CÓ TRONG MÀN HÌNH: cất công trình ở xa / sau lưng camera khỏi Workspace
-- (engine thôi render + thôi xử lý vật lý) -> hết khựng khi đi qua ranh giới ô đất.
CityCuller.mount()

-- CƠ CHẾ TAY (nhặt · tha · ném) + HUD "ĐANG VÁC"
CarryClient.mount()

-- CƯỚP VÍ (phím T) gần dân thường
MugClient.mount(localPlayer)

-- GÓC NHÌN THỨ NHẤT; ESC mở chuột
FirstPersonCamera.mount(localPlayer)

-- ⚠ VŨ KHÍ KHÔNG CÒN LÀ "ITEM" TRONG TÚI ĐỒ ROBLOX.
-- Tắt hẳn giao diện Backpack (thanh item + phím 1..9 mặc định) — người chơi chỉ
-- chọn súng bằng VÒNG CHỌN (giữ TAB) đúng chuẩn GTA V.
local StarterGui = game:GetService("StarterGui")
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

-- BỎ BẢNG XẾP HẠNG: tắt PlayerList (phím TAB mặc định của Roblox mở bảng này).
-- TAB giờ chỉ mở vòng chọn súng. leaderstats vẫn giữ dữ liệu tiền, chỉ không hiện.
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)
