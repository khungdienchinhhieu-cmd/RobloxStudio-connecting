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

GtaHud.mount(localPlayer, hudRemote)
VehiclePromptUI.mount(localPlayer)
LSCustomsUI.mount(localPlayer)
WeaponClient.mount(localPlayer, weaponRemote)
GtaWeaponWheel.mount(localPlayer, weaponSync, weaponReload)
