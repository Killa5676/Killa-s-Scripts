local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local _Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Player = Players.LocalPlayer
local Frames = {}
Frames.__index = Frames
_G.AutoPlay = true


local function DestroyKillBricks()
	for _, v in pairs(CollectionService:GetTagged("KillPart")) do
		v:Destroy()
	end
	for _, v in pairs(CollectionService:GetTagged("DamagePart")) do
		v:Destroy()
	end
end

local function getChar()
	local Character = Player.Character
	if Character then
		return Character
	else
		Player.CharacterAdded:Wait()
		return getChar()
	end
end

local function isNear(vec1, target, threshold)
	return math.abs(vec1.x - target.x) <= threshold
		and math.abs(vec1.y - target.y) <= threshold
		and math.abs(vec1.z - target.z) <= threshold
end
local function TableToCFrame(t)
	return CFrame.new(unpack(t))
end

local function DesipherAngle(vec1)
	local threshold = 10
	if isNear(vec1, { x = 776, y = 223, z = 47 }, threshold) then
		return 0
	elseif isNear(vec1, { x = 743, y = 223, z = -33 }, threshold) then
		return 45
	elseif isNear(vec1, { x = 664, y = 223, z = -62 }, threshold) then
		return 90
	elseif isNear(vec1, { x = 584, y = 223, z = -33 }, threshold) then
		return 135
	elseif isNear(vec1, { x = 552, y = 223, z = 46 }, threshold) then
		return 180
	elseif isNear(vec1, { x = 585, y = 223, z = 126 }, threshold) then
		return 225
	elseif isNear(vec1, { x = 663, y = 223, z = 159 }, threshold) then
		return 270
	elseif isNear(vec1, { x = 743, y = 223, z = 126 }, threshold) then
		return 315
	else
		return 0
	end
end

local function fetchTas(name)
	local success, content = pcall(
		game.HttpGet,
		game,
		"https://raw.githubusercontent.com/Killa5676/Killa-s-Scripts/main/Obby%20Royale/TAS%20Files/" .. name .. ".json"
	)
	if success then
		return content
	else
		return nil
	end
end
local function LoadAutoPlayTas(name)
	local content = fetchTas(name)
	if not content then
		return
	end
	local success, loadedFrames = pcall(HttpService.JSONDecode, HttpService, content)
	if not success then
		warn("Failed to decode JSON: " .. loadedFrames)
		return
	end
	Frames = table.create(#loadedFrames)
	for i, frame in ipairs(loadedFrames) do
		table.insert(Frames, {
			TableToCFrame(frame[1]),
			frame[2],
			frame[3],
		})
	end
end

local function PlayLoadedTas()
	local Character = getChar()
	local TimePlay = tick()
	local FrameCount = #Frames
	local OldFrame = 1
	local firstFrame = Frames[1]
	local originalStartPosition = firstFrame[1].Position
	local newStartPosition = Character.HumanoidRootPart.Position
	local rotationAngle = DesipherAngle(newStartPosition)
	local rotationCFrame = CFrame.Angles(0, math.rad(rotationAngle), 0)

	local finished = false
	TASLoop = game:GetService("RunService").Heartbeat:Connect(function()
		local CurrentTime = tick()
		if (CurrentTime - TimePlay) >= Frames[FrameCount][3] then
			TASLoop:Disconnect()
			finished = true
			return
		end
		for i = OldFrame, FrameCount do
			local Frame = Frames[i]
			if Frame[3] <= CurrentTime - TimePlay then
				OldFrame = i
				local relativeCFrame = Frame[1] - originalStartPosition
				local rotatedCFrame = rotationCFrame * relativeCFrame
				local adjustedCFrame = rotatedCFrame + newStartPosition
				Character.HumanoidRootPart.CFrame = adjustedCFrame
				Character.Humanoid:ChangeState(Frame[2])
			end
		end
	end)
	return function()
		return finished
	end
end

local function GetNextStage()
	local Preloaded = _Workspace.Preloaded
	for _, v in pairs(Preloaded:GetChildren()) do
		if v:IsA("Model") then
			for _, v2 in pairs(v:GetChildren()) do
				if v2:IsA("Model") and v2:GetAttribute("ID") then
					return v2:GetAttribute("ID")
				end
			end
		end
	end
	return nil
end

task.spawn(function()
	while task.wait() and _G.AutoPlay do
		repeat
			task.wait()
		until Player.PlayerGui.MainUI.RoundUI.PlayerCards:FindFirstChild(Player.Name) or not _G.AutoPlay
		if not _G.AutoPlay then
			return
		end
		if
			(GetNextStage() ~= nil)
			or not Player.PlayerGui.MainUI.RoundUI.PlayerCards[Player.Name].PlayerIcon.Status.Visible
		then
			local stage = GetNextStage()
			if stage and _G.AutoPlay then
				if fetchTas(stage) ~= "404: Not Found" then
					DestroyKillBricks()
					print("loading tas...")
					LoadAutoPlayTas(stage)
					print("loaded tas")
					repeat
						task.wait()
					until tonumber(Player.PlayerGui.MainUI.RoundStatus.Title.Text) == 0 or not _G.AutoPlay
					task.wait(1)
					local isFinished = PlayLoadedTas()
					print("playing")
					repeat
						task.wait()
					until isFinished() or not _G.AutoPlay

					if isFinished() then
						print("tas finished")
						task.wait(1)
						repeat
							task.wait()
						until (GetNextStage() ~= nil) or not _G.AutoPlay
					end
				else
					repeat
						task.wait()
					until tonumber(Player.PlayerGui.MainUI.RoundStatus.Title.Text) <= 0
					repeat
						task.wait()
					until (GetNextStage() ~= nil) or not _G.AutoPlay_
				end
			end
		end
	end
end)

print("started tas")
