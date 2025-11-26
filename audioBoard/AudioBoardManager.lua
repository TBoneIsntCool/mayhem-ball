-- server sided
-- AudioBoardManager.server.lua
-- Server-side audio board controller that:
--  * Broadcasts song selections to all clients
--  * Keeps a single authoritative start time using server clock
--  * Automatically syncs late-join players
--  * Updates "Now Playing" label on the board

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

---------------------------------------------------------------------
-- Remote events
---------------------------------------------------------------------

local playEvent = ReplicatedStorage:FindFirstChild("PlaySongEvent")
if not playEvent then
	playEvent = Instance.new("RemoteEvent")
	playEvent.Name = "PlaySongEvent"
	playEvent.Parent = ReplicatedStorage
end

local stopEvent = ReplicatedStorage:FindFirstChild("StopSongEvent")
if not stopEvent then
	stopEvent = Instance.new("RemoteEvent")
	stopEvent.Name = "StopSongEvent"
	stopEvent.Parent = ReplicatedStorage
end

---------------------------------------------------------------------
-- State + configuration
---------------------------------------------------------------------

local currentSong = nil
local overlap = 0.05

-- Optional silent server tracker (can be used if you want the server
-- itself to have a sound instance following the song).
local serverSound = SoundService:FindFirstChild("ServerAudioTracker")
if not serverSound then
	serverSound = Instance.new("Sound")
	serverSound.Name = "ServerAudioTracker"
	serverSound.Volume = 0
	serverSound.Looped = false
	serverSound.Parent = SoundService
end

local playingText
do
	local board = workspace:FindFirstChild("AudioBoard")
	if board and board:FindFirstChild("SurfaceGui") then
		local surfaceGui = board.SurfaceGui
		if surfaceGui:FindFirstChild("Main") then
			local main = surfaceGui.Main
			local frame = main:FindFirstChild("Frame")
			if frame and frame:FindFirstChild("Playing") then
				playingText = frame.Playing
			end
		end
	end
end

---------------------------------------------------------------------
-- Song library
---------------------------------------------------------------------

local SongLibrary = {
	Act1Tab = {
		["Manifesto of Mayhem Intro"] = {ids={80325581777615}, slowed=false, speed=2.5},
		["Abracadabra"] = {ids={128317515430940,109975876833429}, slowed=true, speed=2.5},
		["Judas"] = {ids={89356534251234}, slowed=true, speed=2.5},
		["Aura"] = {ids={139810770623872}, slowed=true, speed=2.5},
		["Scheiße"] = {ids={104027258826879,135443631600016}, slowed=true, speed=2.5},
		["Garden of Eden"] = {ids={109089477921556,83279851662710}, slowed=true, speed=2.5},
		["Poker Face"] = {ids={70677052573237,97868773683409}, slowed=true, speed=2.5},
		['"Off With Her Head" Exterlude'] = {ids={130089262705170,88348289165549,117818906564675}, slowed=true, speed=2.5},
	},

	Act2Tab = {
		["Perfect Celebrity"] = {ids={99446970061249,110670671860561}, slowed=true, speed=2.5},
		["Disease"] = {ids={128786224573472,111000154407006}, slowed=true, speed=2.5},
		["Paparazzi"] = {ids={122480798102859,77623822549853}, slowed=true, speed=2.5},
		["Love Game"] = {ids={113105022218449,130968797273119}, slowed=true, speed=2.5},
		["Alejandro"] = {ids={115652664559851}, slowed=true, speed=2.5},
		["The Beast"] = {ids={104969259293058,78543820052497}, slowed=true, speed=2.5},
		["Exterlude"] = {ids={106685461895966,87437994419947}, slowed=true, speed=2.5},
	},

	Act3Tab = {
		["Act 3 Intro"] = {ids={89210919625195}, slowed=true, speed=2.5},
		["Killah"] = {ids={90384703142960,126872965125505}, slowed=true, speed=2.5},
		["Zombieboy"] = {ids={107289161467420,110597118894548}, slowed=true, speed=2.5},
		["The Dead Dance"] = {ids={74946387716786,101372905098634}, slowed=true, speed=2.5},
		["LoveDrug"] = {ids={99459380850239,122585636671249}, slowed=true, speed=2.5},
		["Applause"] = {ids={85309226366978}, slowed=true, speed=2.5},
		["Just Dance"] = {ids={122122438975832}, slowed=true, speed=2.5},
		['"Wake Her Up!" Exterlude'] = {ids={114392146916351,77305764198907}, slowed=true, speed=2.5},
	},

	Act4Tab = {
		["Shadow of a Man"] = {ids={75791455538632,118789204460711}, slowed=true, speed=2.5},
		["Kill for Love"] = {ids={138263310113753}, slowed=true, speed=2.5},
		["Summerboy"] = {ids={76243253529608}, slowed=true, speed=2.5},
		["Born This Way"] = {ids={74963758537550,135850949779403}, slowed=true, speed=2.5},
		["Million Reasons"] = {ids={83911794973123,98237373785326}, slowed=true, speed=2.5},
		["Shallow"] = {ids={105193068068149,128485959174571}, slowed=true, speed=2.5},
		["Die With a Smile"] = {ids={103394497857317,128348852783614}, slowed=true, speed=2.5},
		["Vanish Into You"] = {ids={107112969920122}, slowed=true, speed=2.5},
	},

	FinaleTab = {
		["Finale Transition"] = {ids={84751156404151}, slowed=false, speed=2.5},
		["Finale Interlude"] = {ids={112907918512178}, slowed=false, speed=2.5},
		["Bad Romance"] = {ids={79733258511470,103570708381897,102534184775562}, slowed=true, speed=2.5},
		["Credits Interlude"] = {ids={119429580593511}, slowed=false, speed=2.5},
		["How Bad Do You Want Me"] = {ids={85956298346571,109070414624914}, slowed=true, speed=2.5},
	},

	OtherTab = {
		["Abracadabra / Dead Dance Intro"] = {ids={135687026376984,123399849387606,110269639369751,73922772246585,114877259721463}, slowed=true, speed=2.5},
		["Piano: Speechless"] = {ids={103275920661979,92885194956113}, slowed=true, speed=2.0},
		["Poker Face - Dead Dance"] = {ids={140611443595086,74787943364386}, slowed=true, speed=2.5},
	},
}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function updateNowPlaying(text)
	if playingText then
		playingText.Text = text or "..."
	end
end

local function broadcastStop()
	currentSong = nil
	serverSound:Stop()
	updateNowPlaying("...")

	for _, plr in ipairs(Players:GetPlayers()) do
		stopEvent:FireClient(plr)
	end
end

local function broadcastPlay(ids, slowed, speed, songName)
	-- Authoritative server start time. Using "now" keeps it instant.
	local startAt = Workspace:GetServerTimeNow()

	currentSong = {
		ids = ids,
		slowed = slowed,
		speed = speed or 1,
		startTime = startAt,
		overlap = overlap,
		songName = songName,
	}

	updateNowPlaying(songName)

	-- Server tracker is optional but kept for debugging / visual alignment
	serverSound:Stop()
	serverSound.SoundId = "rbxassetid://" .. ids[1]
	serverSound.PlaybackSpeed = (slowed and speed) or 1

	-- Start the tracker at (almost) the same time as the clients
	serverSound:Play()

	-- Tell ALL clients to start their local sequence.
	-- Clients will compute their own offset using Workspace:GetServerTimeNow()
	for _, plr in ipairs(Players:GetPlayers()) do
		playEvent:FireClient(plr, ids, slowed, startAt, overlap, speed or 1)
	end
end

-- Single Ended connection for the server tracker
serverSound.Ended:Connect(function()
	if currentSong then
		-- When the first ID finishes, consider the song "done" from the server perspective.
		currentSong = nil
		updateNowPlaying("...")
	end
end)

---------------------------------------------------------------------
-- Late join sync
---------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	if currentSong then
		-- New player joining late gets snapped into the correct
		-- position based on the original start time.
		playEvent:FireClient(
			player,
			currentSong.ids,
			currentSong.slowed,
			currentSong.startTime,
			currentSong.overlap,
			currentSong.speed
		)
	end
end)

---------------------------------------------------------------------
-- Hook UI buttons on the AudioBoard
---------------------------------------------------------------------

local function hookButtons()
	local board = workspace:FindFirstChild("AudioBoard")
	if not board then
		warn("AudioBoard not found in workspace.")
		return
	end

	local gui = board:FindFirstChild("SurfaceGui")
	if not gui then
		warn("SurfaceGui not found on AudioBoard.")
		return
	end

	if not gui:FindFirstChild("Main") then
		warn("Main frame not found on AudioBoard SurfaceGui.")
		return
	end

	local main = gui.Main
	local audioButtons = main:FindFirstChild("AudioButtons")
	if not audioButtons then
		warn("AudioButtons frame not found under Main.")
		return
	end

	-- Wire up tab buttons to the library
	for _, tab in pairs(audioButtons:GetChildren()) do
		if tab:IsA("Frame") and SongLibrary[tab.Name] then
			local list = tab:FindFirstChild("ButtonList")
			if list then
				for _, btn in pairs(list:GetChildren()) do
					if btn:IsA("TextButton") then
						btn.MouseButton1Click:Connect(function()
							local data = SongLibrary[tab.Name][btn.Text]
							if data then
								-- Stop any current song, then start the new one
								broadcastStop()
								broadcastPlay(data.ids, data.slowed, data.speed, btn.Text)
							else
								warn("No song data for button text:", btn.Text)
							end
						end)
					end
				end
			end
		end
	end

	-- Global stop button
	local stopBtn = audioButtons:FindFirstChild("StopButton")
	if stopBtn and stopBtn:IsA("TextButton") then
		stopBtn.MouseButton1Click:Connect(broadcastStop)
	end
end

hookButtons()

print("AudioBoardManager READY (Synced + Instant Start)")
