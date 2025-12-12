local ReplicatedStorage = game:GetService("ReplicatedStorage")
local self = script

local license = ReplicatedStorage:WaitForChild("LicenseEnabled")

if license.Value == false then
	self:Destroy()
	return
end

license.Changed:Connect(function(new)
	if new == false then
		self:Destroy()
	end
end)


local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local character
local hrp
local humanoid

local lastPlatform = nil
local lastCFrame = nil

-- FOLDER WHERE YOUR MOVING PLATFORMS ARE
local PLATFORM_FOLDER = Workspace:WaitForChild("PlatformProps")

-- Build raycast filter to IGNORE all characters
local function getIgnoreList()
	local ignore = {character}

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			table.insert(ignore, plr.Character)
		end
	end

	return ignore
end

local function isValidPlatform(part)
	-- Only treat things inside PlatformProps as valid moving platforms
	return part and part:IsDescendantOf(PLATFORM_FOLDER)
end

local function setupCharacter(char)
	character = char
	hrp = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")

	lastPlatform = nil
	lastCFrame = nil
end

setupCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(setupCharacter)

RunService.Heartbeat:Connect(function(dt)
	if not character or not hrp or not humanoid then return end

	if humanoid.FloorMaterial == Enum.Material.Air then
		lastPlatform = nil
		lastCFrame = nil
		return
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = getIgnoreList()

	local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), params)

	if not result or not result.Instance then
		lastPlatform = nil
		lastCFrame = nil
		return
	end

	local part = result.Instance

	-- Only treat approved moving platforms
	if not isValidPlatform(part) or part.Anchored then
		lastPlatform = nil
		lastCFrame = nil
		return
	end

	if part ~= lastPlatform then
		lastPlatform = part
		lastCFrame = part.CFrame
		return
	end

	local newCF = part.CFrame
	local delta = newCF * lastCFrame:Inverse()

	-- Apply movement offset
	hrp.CFrame = delta * hrp.CFrame
	lastCFrame = newCF
end)
