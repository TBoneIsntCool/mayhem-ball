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

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local GROUP_ID = 566368442
local MIN_RANK = 252

local function isWhitelisted(plr)
	if not plr or not plr:IsA("Player") then return false end
	return plr:GetRankInGroup(GROUP_ID) >= MIN_RANK
end

----------------------------------------------------------
-- MAKE AUDIO BOARD INVISIBLE (NOT DESTROYED)
----------------------------------------------------------
local function hideAudioBoard()
	local board = Workspace:FindFirstChild("AudioBoard")
	if not board then return end

	for _, obj in ipairs(board:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency = 1
			obj.CanCollide = false
			obj.CanQuery = false
			obj.CanTouch = false
		end
		if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
			obj.Enabled = false
		end
	end
end

----------------------------------------------------------
-- DESTROY ALL OTHER PANELS (unchanged)
----------------------------------------------------------
local function hidePanels()
local paths = {
	-- NEW
	Workspace:FindFirstChild("Crowd Lights")
		and Workspace["Crowd Lights"]:FindFirstChild("Panel")
		and Workspace["Crowd Lights"].Panel:FindFirstChild("Panel"),

	Workspace:FindFirstChild("MUSICPANELVER5"),

	-- EXISTING
	Workspace:FindFirstChild("StacyPilot"),
	Workspace:FindFirstChild("Panel"),
	Workspace:FindFirstChild("Visual Panel"),
	Workspace:FindFirstChild("Visual Panel 2"),
	Workspace:FindFirstChild("Lifts") and Workspace.Lifts:FindFirstChild("lifts panel"),
	Workspace:FindFirstChild("CLG Ambience Panel") and Workspace["CLG Ambience Panel"]:FindFirstChild("Ambience Panel"),
	Workspace:FindFirstChild("Pyros") and Workspace.Pyros:FindFirstChild("Stage Pyrotechnics Panel"),
	Workspace:FindFirstChild("House Lights Panel"),
	Workspace:FindFirstChild("Special Cue Panel"),
	Workspace:FindFirstChild("GLights1")
    	and Workspace.GLights1:FindFirstChild("Lights")
    	and Workspace.GLights1.Lights:FindFirstChild("House Lights")
    	and Workspace.GLights1.Lights["House Lights"]:FindFirstChild("Panel"),
}

	for _, panel in ipairs(paths) do
		if panel then panel:Destroy() end
	end

	local glights = Workspace:FindFirstChild("GLights")
	if glights then
		if glights.Lights then
			for _, folder in ipairs(glights.Lights:GetDescendants()) do
				if folder:FindFirstChild("Panel") then
					folder.Panel:Destroy()
				end
			end
		end

		if glights.ResetButtons then
			for _, obj in ipairs(glights.ResetButtons:GetDescendants()) do
				if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Folder") then
					obj:Destroy()
				end
			end
		end
	end

	-- AFTER DESTROYING PANELS, MAKE AUDIO BOARD INVISIBLE
	hideAudioBoard()
end

----------------------------------------------------------
-- REMOTE EVENT HANDLER
----------------------------------------------------------
local remote = ReplicatedStorage.AdminRemotes:WaitForChild("EventManagerToggleRE")

remote.OnClientEvent:Connect(function(eventType, value)
	if eventType == "enforceWhitelist" then
		if value and not isWhitelisted(player) then
			hidePanels()
		end
	end
end)
