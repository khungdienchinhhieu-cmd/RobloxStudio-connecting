--!strict
--[[
	WeaponManager.luau
	Cấp vũ khí GTA V (Pistol 9mm & Carbine Rifle) cho người chơi để kiểm thử & chiến đấu:
	- Bắn trúng bất kỳ Part nào có máu ẩn (tường gạch, bờ kè, cọc tiêu, dải phân cách, kính/vỏ xe)
	  đều trừ PartHealth thông qua DestructionManager -> hết máu ẩn là TỰ VỠ!
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DestructionManager = require(script.Parent:WaitForChild("DestructionManager"))

local WeaponManager = {}

local WEAPON_SPECS = {
	["Pistol 9mm"] = {
		damage = 38,
		cooldown = 0.16,
		range = 300,
		impulse = 36,
		isRifle = false,
	},
	["Carbine Rifle"] = {
		damage = 30,
		cooldown = 0.095,
		range = 380,
		impulse = 44,
		isRifle = true,
	},
}

local lastShotAt: { [Player]: number } = {}

local function buildWeaponTool(toolName: string, isRifle: boolean): Tool
	local tool = Instance.new("Tool")
	tool.Name = toolName
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("IsGtaWeapon", true)
	tool:SetAttribute("AutoFire", isRifle)
	tool:SetAttribute("FireCooldown", if isRifle then 0.10 else 0.17)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = if isRifle then Vector3.new(0.32, 0.95, 0.45) else Vector3.new(0.28, 0.82, 0.38)
	handle.Color = Color3.fromRGB(26, 29, 36)
	handle.Material = Enum.Material.Metal
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.CanCollide = false
	handle.Parent = tool

	-- Thân súng & Nòng súng chi tiết hàn cố định vào Handle
	local body = Instance.new("Part")
	body.Name = "ReceiverSlide"
	body.Size = if isRifle then Vector3.new(0.34, 0.42, 2.55) else Vector3.new(0.30, 0.34, 1.25)
	body.CFrame = handle.CFrame * CFrame.new(0, 0.44, if isRifle then -0.85 else -0.36)
	body.Color = if isRifle then Color3.fromRGB(36, 40, 48) else Color3.fromRGB(52, 58, 68)
	body.Material = Enum.Material.Metal
	body.CanCollide = false
	body.Massless = true
	body.Parent = tool

	local wc1 = Instance.new("WeldConstraint")
	wc1.Part0 = handle
	wc1.Part1 = body
	wc1.Parent = body

	local muzzle = Instance.new("Part")
	muzzle.Name = "Muzzle"
	muzzle.Size = Vector3.new(0.18, 0.18, 0.35)
	muzzle.CFrame = handle.CFrame * CFrame.new(0, 0.46, if isRifle then -2.25 else -1.08)
	muzzle.Color = Color3.fromRGB(20, 22, 26)
	muzzle.Material = Enum.Material.Metal
	muzzle.CanCollide = false
	muzzle.Massless = true
	muzzle.Parent = tool

	local wc2 = Instance.new("WeldConstraint")
	wc2.Part0 = handle
	wc2.Part1 = muzzle
	wc2.Parent = muzzle

	if isRifle then
		local mag = Instance.new("Part")
		mag.Name = "Magazine"
		mag.Size = Vector3.new(0.24, 0.78, 0.36)
		mag.CFrame = handle.CFrame * CFrame.new(0, -0.05, -0.78) * CFrame.Angles(math.rad(14), 0, 0)
		mag.Color = Color3.fromRGB(22, 24, 30)
		mag.Material = Enum.Material.Metal
		mag.CanCollide = false
		mag.Massless = true
		mag.Parent = tool
		local wc3 = Instance.new("WeldConstraint")
		wc3.Part0 = handle
		wc3.Part1 = mag
		wc3.Parent = mag
	end

	return tool
end

local function giveLoadout(player: Player)
	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then
		return
	end
	for _, nm in ipairs({ "Pistol 9mm", "Carbine Rifle" }) do
		if not backpack:FindFirstChild(nm) then
			local t = buildWeaponTool(nm, nm == "Carbine Rifle")
			t.Parent = backpack
		end
	end
end

function WeaponManager.init(remotesFolder: Instance)
	local fireRemote = remotesFolder:FindFirstChild("WeaponFire") :: RemoteEvent?
	if not fireRemote then
		local created = Instance.new("RemoteEvent")
		created.Name = "WeaponFire"
		created.Parent = remotesFolder
		fireRemote = created
	end
	local activeFireRemote = fireRemote :: RemoteEvent

	local function hookPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait(0.15)
			giveLoadout(player)
		end)
		if player.Character then
			task.spawn(giveLoadout, player)
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		hookPlayer(p)
	end
	Players.PlayerAdded:Connect(hookPlayer)
	Players.PlayerRemoving:Connect(function(p)
		lastShotAt[p] = nil
	end)

	activeFireRemote.OnServerEvent:Connect(function(player, originPos, aimPos)
		if typeof(originPos) ~= "Vector3" or typeof(aimPos) ~= "Vector3" then
			return
		end

		local char = player.Character
		if not char then
			return
		end
		local tool = char:FindFirstChildOfClass("Tool")
		if not tool or tool:GetAttribute("IsGtaWeapon") ~= true then
			return
		end

		local spec = WEAPON_SPECS[tool.Name]
		if not spec then
			return
		end

		local now = os.clock()
		if now - (lastShotAt[player] or 0) < (spec.cooldown * 0.75) then
			return
		end
		lastShotAt[player] = now

		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp or (originPos - hrp.Position).Magnitude > 22 then
			return
		end

		local dirVec = aimPos - originPos
		if dirVec.Magnitude < 0.05 then
			return
		end
		local rayDir = dirVec.Unit * spec.range

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local deb = Workspace:FindFirstChild("LosSantos_Debris")
		params.FilterDescendantsInstances = if deb then { char, deb } else { char }

		local result = Workspace:Raycast(originPos, rayDir, params)
		if result and result.Instance and result.Instance:IsA("BasePart") then
			local hitPart = result.Instance
			local hitModel = hitPart:FindFirstAncestorOfClass("Model")
			local hitHum = if hitModel then hitModel:FindFirstChildOfClass("Humanoid") else nil

			if hitHum and hitModel ~= char then
				hitHum:TakeDamage(spec.damage * 0.7)
				activeFireRemote:FireClient(player, "hit", false)
			else
				local shattered = DestructionManager.damagePart(
					hitPart,
					spec.damage,
					result.Position,
					dirVec.Unit * spec.impulse + Vector3.new(0, 8, 0)
				)
				if hitPart:GetAttribute("Destructible") == true or shattered or (hitModel and hitModel:GetAttribute("IsGtaVehicle") == true) then
					activeFireRemote:FireClient(player, "hit", shattered)
				end
			end
		end
	end)
end

return WeaponManager
