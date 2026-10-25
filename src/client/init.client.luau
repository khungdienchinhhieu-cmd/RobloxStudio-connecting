--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hello = require(Shared:WaitForChild("Hello"))

local localPlayer = Players.LocalPlayer
print(Hello.greet(string.format("Client (%s)", localPlayer.Name)))
