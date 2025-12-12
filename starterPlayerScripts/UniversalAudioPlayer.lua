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
local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local playEvent = ReplicatedStorage:WaitForChild("PlaySongEvent")
local stopEvent = ReplicatedStorage:WaitForChild("StopSongEvent")

local SOUND_TAG = "AudioBoardSound"
local VOLUME = 3

local currentSequence = nil

local function clearSequence()
	if currentSequence then
		for _, s in ipairs(currentSequence.sounds or {}) do
			if s and s.Parent then
				s:Stop()
				s:Destroy()
			end
		end
		currentSequence.active = false
	end

	currentSequence = nil

	for _, s in ipairs(SoundService:GetChildren()) do
		if s:IsA("Sound") and s.Name == SOUND_TAG then
			s:Stop()
			s:Destroy()
		end
	end
end

local function preloadSounds(ids, slowed, speed)
	local sounds = {}

	for _, id in ipairs(ids) do
		local s = Instance.new("Sound")
		s.Name = SOUND_TAG
		s.SoundId = "rbxassetid://" .. id
		s.Volume = VOLUME
		s.Looped = false
		s.PlaybackSpeed = (slowed and speed) or 1
		s.Parent = SoundService

		table.insert(sounds, s)
	end

	if #sounds > 0 then
		local ok, err = pcall(function()
			ContentProvider:PreloadAsync(sounds)
		end)
		if not ok then
			warn("PreloadAsync failed:", err)
		end
	end

	return sounds
end

local function getSequenceOffsetSound(sounds, offset)
	local total = 0

	for index, sound in ipairs(sounds) do
		local dur = sound.TimeLength / sound.PlaybackSpeed
		if offset < total + dur then
			return index, offset - total
		end
		total += dur
	end

	return nil, nil
end

local function playSequence(ids, slowed, startAt, overlap, speed)
	clearSequence()

	local sounds = preloadSounds(ids, slowed, speed)

	if #sounds == 0 then
		warn("No sounds to play for sequence.")
		return
	end

	local sequence = {
		sounds = sounds,
		active = true,
	}
	currentSequence = sequence

	local now = Workspace:GetServerTimeNow()
	local offset = math.max(0, now - startAt)

	if now < startAt then
		offset = 0
	end

	local index, localOffset = getSequenceOffsetSound(sounds, offset)
	if not index then
		return
	end

	local current = sounds[index]
	local totalDurCurrent = current.TimeLength / current.PlaybackSpeed
	localOffset = math.clamp(localOffset, 0, math.max(totalDurCurrent - 0.001, 0))

	current.TimePosition = localOffset
	current:Play()

	local function scheduleRemainder(startIndex, timeLeftInCurrent)
		if not sequence.active then
			return
		end

		local remaining = timeLeftInCurrent

		for i = startIndex, #sounds do
			local sound = sounds[i]

			if i == startIndex then
				local delay = math.max(remaining - overlap, 0)
				task.delay(delay, function()
					if sequence.active then
						sound.TimePosition = 0
						sound:Play()
					end
				end)
				remaining = sound.TimeLength / sound.PlaybackSpeed
			else
				local dur = sound.TimeLength / sound.PlaybackSpeed
				local delay = math.max(remaining - overlap, 0)

				task.delay(delay, function()
					if sequence.active then
						sound.TimePosition = 0
						sound:Play()
					end
				end)

				remaining = dur
			end
		end
	end

	local timeLeftInCurrent = totalDurCurrent - localOffset
	scheduleRemainder(index + 1, timeLeftInCurrent)
end

playEvent.OnClientEvent:Connect(function(ids, slowed, startAt, overlap, speed)
	playSequence(ids, slowed, startAt, overlap, speed or 1)
end)

stopEvent.OnClientEvent:Connect(function()
	clearSequence()
end)

print("UniversalAudioPlayer CLIENT ready (synced + instant start)")
