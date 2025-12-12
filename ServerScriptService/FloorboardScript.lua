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

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local FADE_TIME = 2 

local DEBOUNCE_TIME = 1 
local lastTransitionTime = 0
local isTransitioning = false

local panel = workspace:WaitForChild("Visual Panel 2")
local topSurfaceGui = panel:WaitForChild("SurfaceGui")
local main = topSurfaceGui:WaitForChild("Main")
local screenFolder = workspace:WaitForChild("FloorParts")

local function crossfadeImageLabel(visualImage, newImage)
	if not visualImage or not visualImage:IsA("ImageLabel") then return end
	local parent = visualImage.Parent
	if not parent then return end

	local tweenInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	if not newImage then
		local overlay = Instance.new("Frame")
		overlay.Name = "BlackOverlay"
		overlay.Size = visualImage.Size
		overlay.Position = visualImage.Position
		overlay.AnchorPoint = visualImage.AnchorPoint
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.ZIndex = (visualImage.ZIndex or 1) + 2
		overlay.Parent = parent

		visualImage.ImageTransparency = 0

		local fadeToBlack = TweenService:Create(overlay, tweenInfo, {BackgroundTransparency = 0})
		local fadeOut = TweenService:Create(visualImage, tweenInfo, {ImageTransparency = 1})

		fadeToBlack:Play()
		fadeOut:Play()

		local completed = false
		fadeToBlack.Completed:Connect(function() completed = true end)
		local start = tick()
		while not completed and tick() - start < (FADE_TIME + 1) do
			RunService.Heartbeat:Wait()
		end

		visualImage.Image = ""
		visualImage.BackgroundColor3 = Color3.new(0, 0, 0)
		visualImage.BackgroundTransparency = 0
		visualImage.ImageTransparency = 1

		if overlay.Parent then overlay:Destroy() end
		return
	end

	local overlay = Instance.new("ImageLabel")
	overlay.Name = "TransitionOverlay"
	overlay.Size = visualImage.Size
	overlay.Position = visualImage.Position
	overlay.AnchorPoint = visualImage.AnchorPoint
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Image = newImage
	overlay.ImageTransparency = 1
	overlay.ZIndex = (visualImage.ZIndex or 1) + 2
	overlay.Parent = parent

	visualImage.ImageTransparency = 0
	overlay.ImageTransparency = 1

	local fadeIn = TweenService:Create(overlay, tweenInfo, {ImageTransparency = 0})
	local fadeOut = TweenService:Create(visualImage, tweenInfo, {ImageTransparency = 1})

	fadeIn:Play()
	fadeOut:Play()

	local completed = false
	fadeIn.Completed:Connect(function() completed = true end)
	local start = tick()
	while not completed and tick() - start < (FADE_TIME + 1) do
		RunService.Heartbeat:Wait()
	end

	visualImage.Image = newImage
	visualImage.BackgroundTransparency = 1
	visualImage.ImageTransparency = 0
	if overlay.Parent then overlay:Destroy() end
end

local function transitionToImage(imageId)

	local currentTime = tick()
	if isTransitioning or (currentTime - lastTransitionTime < DEBOUNCE_TIME) then
		return
	end

	isTransitioning = true
	lastTransitionTime = currentTime

	local success, errorMessage = pcall(function()
		for _, part in ipairs(screenFolder:GetChildren()) do
			if part.Name == "ScreenPart" then
				local surfaceGui = part:FindFirstChild("SurfaceGui")
				if surfaceGui then
					local visualImage = surfaceGui:FindFirstChild("VisualImage")
					if visualImage and visualImage:IsA("ImageLabel") then

						coroutine.wrap(function()
							pcall(crossfadeImageLabel, visualImage, imageId)
						end)()
					else
						warn("No VisualImage found in SurfaceGui of", part:GetFullName())
					end
				else
					warn("No SurfaceGui found in", part:GetFullName())
				end
			end
		end
	end)

	delay(FADE_TIME + 0.5, function()
		isTransitioning = false
	end)

	if not success then
		warn("Transition failed:", errorMessage)
		isTransitioning = false
	end
end

local function hookButton(btn)
	if not btn then return end
	if not (btn:IsA("TextButton") or btn:IsA("ImageButton")) then return end

	local lowerName = btn.Name:lower()

	local function onClick()

		if isTransitioning then return end

		if lowerName:find("off") then
			print("Off button pressed -> fading to black")
			transitionToImage(nil)
			return
		end

		local preview = btn:FindFirstChild("Visual Preview")
		if preview and preview:IsA("ImageLabel") then
			local imageId = preview.Image
			if imageId and imageId ~= "" then
				print("Button clicked -> transition to", imageId)
				transitionToImage(imageId)
			else
				warn("Button preview has no image:", btn:GetFullName())
			end
		else
			warn("Button missing 'Visual Preview' ImageLabel:", btn:GetFullName())
		end
	end

	btn.MouseButton1Click:Connect(onClick)
	print("Hooked button:", btn:GetFullName())
end

local function hookButtonsIn(container)
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
			hookButton(descendant)
		end
	end
end

hookButtonsIn(main)
hookButtonsIn(topSurfaceGui)

print("[VisualPanel] All buttons hooked. Ready for concert visuals!")