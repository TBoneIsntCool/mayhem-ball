local HttpService = game:GetService("HttpService")
local self = script
local url = "https://raw.githubusercontent.com/TBoneIsntCool/mayhem-ball/refs/heads/main/license.txt"

local ok, license = pcall(function()
	return HttpService:GetAsync(url)
end)

if not ok then
	pcall(function() self:Destroy() end)
	return
end

license = tostring(license):lower():gsub("%s+", "")

if license ~= "enabled" then
	pcall(function() self:Destroy() end)
	return
end

local liftSystem = script.Parent
local lift = liftSystem:WaitForChild("Lift")
local panel = workspace.Lifts["lifts panel"].SurfaceGui.main["other lifts 2"]["Truss lift"]
local buttonsFolder = panel.Frame

local TweenService = game:GetService("TweenService")

local EASING_STYLE = Enum.EasingStyle.Sine
local EASING_DIRECTION = Enum.EasingDirection.InOut
local MOVING_COLOR = Color3.fromRGB(0, 85, 255)

-- Define positions (mapped to button names)
local POSITIONS = {
	["Point1"] = Vector3.new(73.658, 11.306, 17.125),  -- Floor (shadow of a man)
	["Point2"] = Vector3.new(73.658, 20.806, 17.125),  -- Middle (summerboy)
	["Reset"] = Vector3.new(73.658, 68.018, 17.125)    -- Reset (resting)
}

-- Define durations between positions
local DURATIONS = {
	["Reset_to_Point1"] = 47,   -- reset > shadow of a man (40 seconds)
	["Point1_to_Point2"] = 12,  -- shadow of a man > summerboy (12 seconds)
	["Point2_to_Reset"] = 30,   -- summerboy > reset (30 seconds)
	-- Reverse directions (assuming same time)
	["Point1_to_Reset"] = 40,
	["Point2_to_Point1"] = 12,
	["Reset_to_Point2"] = 30
}

if not lift.PrimaryPart then
	error("Lift model does not have a PrimaryPart set!")
end

local currentPosition = "Reset"

local function getTravelDuration(fromPos: string, toPos: string): number
	local key = fromPos .. "_to_" .. toPos
	return DURATIONS[key] or 30 -- Default to 30 if no specific duration found
end

local function moveLiftTo(positionName: string, button: ImageButton)
	if currentPosition == positionName then
		return -- Already at this position
	end

	local textLabel = button:FindFirstChild("textbutton")
	if not textLabel then
		warn("No 'textbutton' TextLabel found inside button:", button.Name)
		return
	end

	local targetPosition = POSITIONS[positionName]
	if not targetPosition then
		warn("No position found for:", positionName)
		return
	end

	local originalColor = button.ImageColor3
	local originalText = textLabel.Text
	local originalFont = textLabel.Font
	local originalTextSize = textLabel.TextSize

	button.AutoButtonColor = false
	button.ImageColor3 = MOVING_COLOR
	textLabel.Text = "<b>Moving Lift</b>"
	textLabel.TextScaled = false
	textLabel.RichText = true
	textLabel.TextSize = 40
	textLabel.TextTransparency = 0.4

	local travelTime = getTravelDuration(currentPosition, positionName)
	local targetCFrame = CFrame.new(targetPosition) * (lift.PrimaryPart.CFrame - lift.PrimaryPart.Position)
	local tweenInfo = TweenInfo.new(travelTime, EASING_STYLE, EASING_DIRECTION)
	local tween = TweenService:Create(lift.PrimaryPart, tweenInfo, {CFrame = targetCFrame})
	tween:Play()

	tween.Completed:Wait()

	currentPosition = positionName

	button.AutoButtonColor = true
	button.ImageColor3 = originalColor
	textLabel.Text = originalText
	textLabel.Font = originalFont
	textLabel.TextTransparency = 0
	textLabel.TextSize = originalTextSize
end

for _, button in pairs(buttonsFolder:GetChildren()) do
	if button:IsA("ImageButton") then
		local positionName = button.Name
		if POSITIONS[positionName] then
			button.MouseButton1Click:Connect(function()
				moveLiftTo(positionName, button)
			end)
		else
			warn("No position defined for button:", button.Name)
		end
	end
end