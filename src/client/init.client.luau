--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GtaRemotes")
local hudRemote = remotes:WaitForChild("HudAction") :: RemoteEvent
local weaponRemote = remotes:WaitForChild("WeaponFire") :: RemoteEvent

local GtaHud = require(script:WaitForChild("UI"):WaitForChild("GtaHud"))
local WeaponClient = require(script:WaitForChild("WeaponClient"))

GtaHud.mount(localPlayer, hudRemote)
WeaponClient.mount(localPlayer, weaponRemote)
