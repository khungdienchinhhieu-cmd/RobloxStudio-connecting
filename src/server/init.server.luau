--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Hello = require(Shared:WaitForChild("Hello"))

print(Hello.greet("Server"))
