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


local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SOUND_PARENT = workspace
local VOLUME = 1

local allAudioIds = {
	-- Act 1
	80325581777615, -- Manifesto of Mayhem Intro
	128317515430940, 109975876833429, -- Abracadabra
	89356534251234, -- Judas
	139810770623872, -- Aura
	104027258826879, 135443631600016, -- Scheiße
	109089477921556, 83279851662710, -- Garden of Eden
	70677052573237, 97868773683409, -- Poker Face
	130089262705170, 88348289165549, 117818906564675, -- "Off With Her Head" Exterlude

	-- Act 2
	99446970061249, 110670671860561, -- Perfect Celebrity
	128786224573472, 111000154407006, -- Disease
	122480798102859, 77623822549853, -- Paparazzi
	113105022218449, 130968797273119, -- LoveGame
	115652664559851, -- Alejandro
	104969259293058, 78543820052497, -- The Beast
	106685461895966, 87437994419947, -- Exterlude

	-- Act 3
	89210919625195, -- Act 3 Intro
	90384703142960, 126872965125505, -- Killah
	107289161467420, 110597118894548, -- Zombieboy
	74946387716786, 101372905098634, -- The Dead Dance
	99459380850239, 122585636671249, -- LoveDrug
	85309226366978, -- Applause
	122122438975832, -- Just Dance
	114392146916351, 77305764198907, -- "Wake Her Up!" Exterlude

	-- Act 4
	75791455538632, 118789204460711, -- Shadow of a Man
	138263310113753, -- Kill for Love
	76243253529608, -- Summerboy
	74963758537550, 135850949779403, -- Born This Way
	83911794973123, 98237373785326, -- Million Reasons
	105193068068149, 128485959174571, -- Shallow
	103394497857317, 128348852783614, -- Die With a Smile
	107112969920122, -- Vanish Into You

	-- Finale
	84751156404151, -- Finale Transition
	112907918512178, -- Finale Interlude
	79733258511470, 103570708381897, 102534184775562, -- Bad Romance
	119429580593511, -- credits interlude
	85956298346571,109070414624914, --hbduwm
	
	--extra stuff
	135687026376984, 123399849387606, 110269639369751, 73922772246585, 114877259721463, --alternate intro
	103275920661979, 92885194956113, --speechless
	140611443595086, 74787943364386, --poker face studio/dead dance
	93543880391006, 102752210354583, 120937976513479, 109825274123687 --symphony
}

local tempSounds = {}
for _, id in ipairs(allAudioIds) do
	if typeof(id) == "number" and id > 0 then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. id
		sound.Volume = VOLUME
		sound.PlaybackSpeed = 1
		sound.Parent = SOUND_PARENT
		table.insert(tempSounds, sound)
	end
end

local success, err = pcall(function()
	ContentProvider:PreloadAsync(tempSounds)
end)

if success then
	print("[AudioCache] Successfully preloaded all songs (Acts 1–4 + Finale)")
else
	warn("[AudioCache] Error while preloading audio: " .. tostring(err))
end

for _, sound in ipairs(tempSounds) do
	sound:Destroy()
end

print("[AudioCache] Cleanup complete, all sounds ready for playback")
