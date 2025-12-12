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


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local self = script

local license = ReplicatedStorage:WaitForChild("LicenseEnabled")
if not license.Value then self:Destroy() return end
license.Changed:Connect(function(new) if not new then self:Destroy() end end)


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character, hrp, humanoid

---------------------------------------------------------------------
-- DRESS ROOT
---------------------------------------------------------------------
local DRESS_LIFT = Workspace:WaitForChild("Lifts")
    :WaitForChild("dress")
    :WaitForChild("Lift")

local LIFT_ROOT = DRESS_LIFT.PrimaryPart or DRESS_LIFT

-- record previous root CFrame
local lastRootCFrame = nil


---------------------------------------------------------------------
-- character setup
---------------------------------------------------------------------
local function onCharacter(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")

    lastRootCFrame = nil
end

onCharacter(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(onCharacter)


---------------------------------------------------------------------
-- Follower
---------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	if not character or not hrp or not humanoid then return end

	-- If airborne, reset and ignore
	if humanoid.FloorMaterial == Enum.Material.Air then
		lastRootCFrame = LIFT_ROOT.CFrame
		return
	end

	-- Do a downward ray to detect WHAT we're standing on
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -8, 0), params)
	if not result or not result.Instance then
		lastRootCFrame = LIFT_ROOT.CFrame
		return
	end

	local part = result.Instance

	-- only if the part is inside THIS specific dress lift
	if not part:IsDescendantOf(DRESS_LIFT) then
		lastRootCFrame = LIFT_ROOT.CFrame
		return
	end

	-- FIRST attach/remember
	if not lastRootCFrame then
		lastRootCFrame = LIFT_ROOT.CFrame
		return
	end

	-- compute delta of lift root
	local rootNow = LIFT_ROOT.CFrame
	local delta = rootNow * lastRootCFrame:Inverse()

	-- apply movement only to THIS player
	hrp.CFrame = delta * hrp.CFrame

	-- remember
	lastRootCFrame = rootNow
end)
