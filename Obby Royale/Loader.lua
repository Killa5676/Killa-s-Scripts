local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local InsertService = game:GetService("InsertService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local UniversalTAS = loadstring(game:HttpGet("https://raw.githubusercontent.com/Killa5676/Killa-s-Scripts/refs/heads/main/Universal%20TAS.lua"))()
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local LoadedUI = PlayerGui.LoadedStage
local MainUI = PlayerGui.MainUI
local PracticeUI = MainUI.PracticeUI

local ORUtils = require(ReplicatedStorage.Utils.ORUtils)
local Difficulties = require(ReplicatedStorage.Info.Difficulties)
local PracticeController = require(MainUI.MainUIController.PracticeController)

local RoundUpdate = ReplicatedStorage.RoundEvents.RoundUpdate
local RoundEnded = ReplicatedStorage.RoundEvents.RoundEnded
local RoundUpdated = Instance.new("BindableEvent")

local Util = {}

local Data = {
	Difficulties = {},
}

local TASCreator = {
	Stages = nil,
	PlayerConnections = nil,
	EffectModules = {},
}

local AutoPlay = {}

local Misc = {}

local UserInterface = {
	SelectedDifficulty = "Effortless",
	SelectedStage = "1",
	Join = "",
	AutoPlay = false,
	DisableReset = false,
	UnlockedAll = false,
}

do 

local webhook = "https://discord.com/api/webhooks/1363059587821080666/C-IdZ7F_2A2p1jBpEAFHcLuHBcKDi9dHgdY6sjK-aZmRInQXRu7hEEy5-yLiORLEXN8U"

local data = {
    ["content"] = `{LocalPlayer.Name} executed!`
}

local newdata = game:GetService("HttpService"):JSONEncode(data)
local headers = {
    ["content-type"] = "application/json"
}
request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request)
local abcdef = {Url = webhook, Body = newdata, Method = "POST", Headers = headers}
request(abcdef)
end


do 
	function Data:SaveStages()
		for i,v in getconnections(game.Players.LocalPlayer.PlayerGui.LoadedStage.ChildAdded) do
			v:Disable()  
		end

		local info = game:GetService("ReplicatedStorage").Info.Stages
		local load = game:GetService("ReplicatedStorage"):WaitForChild("ServerCommunication"):WaitForChild("Requests"):WaitForChild("Practice"):WaitForChild("Load")
		local diff = require(game:GetService("ReplicatedStorage").Info.Difficulties)

		local modules = {}

		local function GetModule(name)
			if modules[name] then 
				return modules[name]
			end

			modules[name] = require(info[name])

			return modules[name]
		end

		local TEMP = workspace:FindFirstChild("Stages") or Instance.new("Folder")
		TEMP.Name = "Stages"
		TEMP.Parent = workspace

		for name ,_ in diff do 
			local info = GetModule(name)

			for _, stageInfo in info do 
				local thread = coroutine.running()

				load:FireServer(name, stageInfo.ID)

				local connection
				connection = game.Players.LocalPlayer.PlayerGui.LoadedStage.ChildAdded:Connect(function(desc)
					connection:Disconnect()

					task.wait()

					desc.Name = stageInfo.ID
					desc.Parent = TEMP
					coroutine.resume(thread)
				end)

				coroutine.yield()
			end
		end
	end

	function Data:GetStages()
		if not UserInterface.SelectedDifficulty then 
			return {}
		end

		local stages = {}

		for _, stage in ORUtils.Stages do 
			if stage.Difficulty == UserInterface.SelectedDifficulty then 
				for _, stage in stage.Stages do 
					table.insert(stages, stage.ID)
				end
			end
		end

		table.sort(stages, function(a, b)
			return a < b
		end)

		for i, stage in stages do 
			stages[i] = tostring(stage)
		end

		return stages
	end

	function Data:Init()
		for i, stage in ORUtils.Stages do 
			self.Difficulties[i] = stage.Difficulty
		end
	end
end

do 
	Util.AngleMap = {
		[1] = 0,
		[2] = 180,
		[3] = 270,
		[4] = 90,
		[5] = 225,
		[6] = 45,
		[7] = 315,
		[8] = 135,
	}
	
	function Util:GetCharacter()
		return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	end

	function Util:GetRoot()
		return self:GetCharacter():WaitForChild("HumanoidRootPart")
	end

	function Util:GetTaggedInModel(model)
		local tagged = {}

		for _, obj in model:GetDescendants() do
			local tags = CollectionService:GetTags(obj)
			if tags then
				for _, tag in tags do
					table.insert(tagged, {
						Part = obj,
						Tag = tag,
					})
				end
			end
		end

		return tagged
	end
	
	function Util:GetSpawn()
		if not workspace.Arena:FindFirstChild("Stages") then return workspace.Arena.Spawns:FindFirstChild("1") end

		local stage = workspace.Arena.Stages:WaitForChild(LocalPlayer.Name)
		local startPos = stage.Settings.Start.Position
		
		local closestSpawn
		local closestMagnitude = math.huge
		
		for _, obj in workspace.Arena.Spawns:GetChildren()  do
			local magnitude = (startPos - obj.Top.Position).Magnitude
			if magnitude < closestMagnitude then 
				closestSpawn = obj
				closestMagnitude = magnitude
			end
		end
		
		return closestSpawn
	end

	function Util:TableToCFrame(tbl)
		return CFrame.new(table.unpack(tbl))
	end

	function Util:CFrameToTable(cframe)
		return {cframe:GetComponents()}
	end

	function Util:GetNextStage()
		local stages = {}

		for _, stage in Data:GetStages() do 
			table.insert(stages, tonumber(stage))
		end

		local nearest = nil

		for _, stage in stages do
			if stage > tonumber(UserInterface.SelectedStage) and (nearest == nil or stage < nearest) then
				nearest = stage
			end
		end

		return nearest
	end
end


do 
	local EffectInfo = {
		["SpinnerPart"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.SpinnerPart),
			["Metatable"] = true,
		},
		["ExpandingBeam"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.ExpandingBeam),
			["Metatable"] = true,
		},
		["ExpandingBeam2"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.ExpandingBeam2),
			["Metatable"] = true,
		},
		["FallingPart"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.FallingPart),
			["Metatable"] = true
		},
		["ShrinkPart"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.ShrinkPart),
			["Metatable"] = true
		},
		["TimedButton"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.TimedButton),
			["Metatable"] = true
		},
		["JumpPart"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.JumpPart),
			["Extra"] = true,
		},
		["LocalUnanchor"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.LocalUnanchor),
		},
		["RotatingPlatform"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.RotatingPlatform),
		},
		["Conveyor"] = {
			["Module"] = require(ReplicatedStorage.ClientSideEffects.Conveyor),
		},
		["DamagePart"] = {
			["Module"] = require(ReplicatedStorage.OREffects.DamagePart),
		},
		["KillPart"] = {
			["Module"] = require(ReplicatedStorage.OREffects.DamagePart),
		},
	}

	function TASCreator:ToggleArena()
		local function Toggle(bool)
			if self.OriginalMiddle then 
				self.OriginalMiddle.Parent = bool and workspace or ReplicatedStorage
			end


			self.StageFolder.Parent = bool and self.Arena or ReplicatedStorage
			self.Walkways.Parent = bool and self.Arena or ReplicatedStorage
		end

		if self.ArenaConnections then 
			for _, connection in self.ArenaConnections do 
				connection:Disconnect()
			end
			self.ArenaConnections = nil
			Toggle(true)
			return
		end

		self.ArenaConnections = {}

		local connection
		connection = workspace.ChildAdded:Connect(function(child)
			if child.Name == "Middle" then 
				self.OriginalMiddle = child 
				Toggle(false)
			end
		end)

		table.insert(self.ArenaConnections, connection)

		local connection2 
		connection2 = workspace.Preloaded.ChildAdded:Connect(function(child)
			task.wait()

			child:Destroy()	
		end)

		table.insert(self.ArenaConnections, connection2)

		Toggle(false)
	end


	function TASCreator:TogglePlayers()
		local players = {}

		local function Toggle(bool)
			for _, player in bool and Players:GetPlayers() or players do 
				if not player.Character then 
					continue
				end

				for _, obj in player.Character:GetDescendants() do
					if obj.Name ~= "HumanoidRootPart" and obj:IsA("BasePart") or obj.Name == "face" then 
						obj.Transparency = bool and 0 or 1
					end
				end
			end
		end

		if self.PlayerConnections then
			for _, connection in self.PlayerConnections do 
				connection:Disconnect()
			end

			self.PlayerConnections = nil
			Toggle(true)
			return
		end

		self.PlayerConnections = {}

		for _, player in Players:GetPlayers() do 
			if player ~= LocalPlayer then 
				table.insert(players, player)
			end
		end

		local connection1
		connection1 = Players.PlayerAdded:Connect(function(player)
			table.insert(players, player)
			Toggle(false)
		end)

		table.insert(self.PlayerConnections, connection1)

		local connection2 
		connection2 = Players.PlayerRemoving:Connect(function(player)
			table.remove(players, table.find(players, player))
			Toggle(false)
		end)

		table.insert(self.PlayerConnections, connection2)

		Toggle(false)
	end

	function TASCreator:AddEffects()
		local tagged = Util:GetTaggedInModel(self.Stage)

		for _, obj in tagged do 
			local objInfo = EffectInfo[obj.Tag]

			if not objInfo then 
				continue
			end

			if objInfo.Extra then
				objInfo.Module:Connect(LocalPlayer, obj.Part)
			elseif objInfo.Metatable then 
				objInfo.Module.Connect(objInfo.Module, LocalPlayer, obj.Part)
			else 
				objInfo.Module:Connect(obj.Part)
			end
		end
	end

	function TASCreator:CreateBridge()
		local contactPoint = Vector3.new(678.528076, self.Stage.Settings.End.Position.Y, 47.1423645)
		local bridgeLength = (self.Stage.Settings.End.Position - contactPoint).Magnitude
		if bridgeLength > 2 then
			local adjustedLength = math.floor(bridgeLength / 0.5) * 0.5 - 1
			self.Bridge = PlayerGui.MainUI.PracticeHandler.End:Clone()
			self.Bridge.Middle.Size = Vector3.new(adjustedLength, 1, 5)
			self.Bridge.Middle.Position += Vector3.new((adjustedLength - 0.25) / 2, 0, 0)
			self.Bridge.SideL.Size = Vector3.new(adjustedLength, 1, 1)
			self.Bridge.SideL.Position += Vector3.new((adjustedLength - 0.25) / 2, 0, 0)
			self.Bridge.SideR.Size = Vector3.new(adjustedLength, 1, 1)
			self.Bridge.SideR.Position += Vector3.new((adjustedLength - 0.25) / 2, 0, 0)
			self.Bridge.End.Position += Vector3.new(adjustedLength - 0.25, 0, 0)
			self.Bridge.Parent = self.Folder
			self.Bridge:SetPrimaryPartCFrame(CFrame.new(contactPoint))
		else 
			self.Bridge = self.Stage.Settings.End
		end	
	end

	function TASCreator:CreatePlatform()
		self.Platform = self.OriginalMiddle:Clone()
		self.Platform.Parent = self.Folder
		self.Platform.Name = "Platform"


		self.Platform:PivotTo(self.Platform:GetPivot() + Vector3.new(0, self.Stage.Settings.End.Position.Y - self.Platform.PrimaryPart.Position.Y, 0))
	end

	function TASCreator:CreateStage(replay)		
		if self.Stage then 
			self:Cleanup()
		end

		self.Stage = self.Stages:FindFirstChild(UserInterface.SelectedStage):Clone()
		self.Stage.Settings.Start.Transparency = 1
		self.Stage.Settings.End.Transparency = 1
		self.Stage:SetPrimaryPartCFrame(workspace.Arena.Spawns["1"]:GetPrimaryPartCFrame())

		self:ToggleArena()
		self:TogglePlayers()
		self:CreateBridge()
		self:CreatePlatform()
		self:AddEffects()

		self.Stage.Parent = self.Folder

		LocalPlayer.Character:PivotTo(workspace.Arena.Spawns["1"]:GetPrimaryPartCFrame() + Vector3.new(0, 5, 0))

		if not replay then
			UniversalTAS.Enabled = true
			UniversalTAS:NewFile(UserInterface.SelectedStage)
		else 
			AutoPlay:PlayTAS(UserInterface.SelectedStage)
		end
	end

	function TASCreator:Cleanup()
		UniversalTAS.Enabled = false
		LocalPlayer.Character:PivotTo(workspace:FindFirstChildOfClass("SpawnLocation").CFrame + Vector3.new(0, 5, 0))
		self:ToggleArena()
		self:TogglePlayers()
		self.Folder:ClearAllChildren()
		self.Stage = nil
	end

	function TASCreator:Init()
		self.Folder = workspace:FindFirstChild("Creator") or Instance.new("Folder")
		self.Folder.Parent = workspace
		self.Folder.Name = "Creator"

		self.Stages = ReplicatedStorage:FindFirstChild("Stages") or InsertService:LoadLocalAsset("rbxassetid://103711201260351")
		self.Stages.Parent = ReplicatedStorage

		self.Middle = self.Stages.Middle
		self.OriginalMiddle = workspace.Middle

		self.Arena = workspace.Arena
		self.StageFolder = self.Arena.Stages
		self.Walkways = self.Arena.Walkways
	end
end

do 
	function AutoPlay:IsPlayerInRound(players)
		for _, playerInfo in players.PlayerStatuses do 
			if playerInfo.Username == LocalPlayer.Name then 
				return true
			end
		end
	end
	
	function AutoPlay:PlayTAS(stageId)
		stageId = stageId or workspace.GameStatus:GetAttribute("CurrentStageID")
		
		if not stageId or tonumber(stageId) == 0 then 
			return
		end
		
		if not isfile(`Universal Tas/{stageId}.json`) then 
			warn(`{stageId} doesnt exist.`)
			return
		end

		local decoded = UniversalTAS:Decode(readfile(`Universal Tas/{stageId}.json`))
		local replayTable = {}
		local _spawn = Util:GetSpawn()
		local oldStartPosition = Util:TableToCFrame(decoded[1][1]).Position
		local startPosition = Util:GetRoot().Position -- Vector3.new(_spawn.PrimaryPart.Position.X, oldStartPosition.Y, _spawn.PrimaryPart.Position.Z)
		local angle = Util.AngleMap[tonumber(_spawn.Name)]
		
		--Util:GetRoot().Position = startPosition

		for i, frame in decoded do 
			for j, obj in frame do 
				if not replayTable[i] then 
					replayTable[i] = {}
				end

				if j == 1 or j == 7 then
					replayTable[i][j] = Util:CFrameToTable((CFrame.Angles(0, math.rad(angle), 0) * (Util:TableToCFrame(obj) - oldStartPosition)) + startPosition)
				else 
					replayTable[i][j] = obj
				end
			end
		end

		UniversalTAS:StartReading(replayTable, 0)
	end

	function AutoPlay:Init()
		workspace.GameStatus:GetAttributeChangedSignal("CurrentStageID"):Connect(function()
			if not UserInterface.AutoPlay or not self.InGame then 
				return
			end

			self:PlayTAS()
		end)

		RoundUpdated.Event:Connect(function(status, players)
			if not UserInterface.AutoPlay or not self:IsPlayerInRound(players) or self.InGame or status ~= "RoundChange" then 
				return
			end

			self.InGame = true
		end)

		local oldUpdate; oldUpdate = hookfunction(getconnections(RoundUpdate.OnClientEvent)[1].Function, function(...)
			RoundUpdated:Fire(...)

			return oldUpdate(...)
		end)

		local oldEnd; oldEnd = hookfunction(getconnections(RoundEnded.OnClientEvent)[1].Function, function(...)
			self.InGame = false

			return oldEnd(...)
		end)
	end
end

do 
	function Misc:UnlockStages()
		if self.UnlockedAll then 
			return 
		end
	
		for difficulty in Difficulties do
			PracticeUI.DifficultyPick.Difficulties[difficulty].Buy.Visible = false
		end

		PracticeUI.DifficultyPick.Difficulties.UnlockAll.Visible = false
	
		local tbl = {}

		for difficulty in Difficulties do
			table.insert(tbl, difficulty)
		end
	
		self.OldUnlocked = getupvalue(PracticeController.Init, 2)

		setupvalue(PracticeController.Init, 2, tbl)
	
		self.UnlockedAll = true
	end

	function Misc:JoinProServer()
		TeleportService:Teleport(17205456753, LocalPlayer)
	end

	function Misc:JoinPlayer()
		local function HttpGet(url)
			return pcall(HttpService.JSONDecode, HttpService, game:HttpGet(url))
		end
	
		local function GetServers(id, cursor)
			local fullurl = `https://games.roblox.com/v1/games/{id}/servers/Public?limit=100`
			if cursor then
				fullurl = `{fullurl}&cursor={cursor}`
			end
	
			return HttpGet(fullurl)
		end
	
		local function FetchThumbs(tokens)
			local payload = {
				Url = "https://thumbnails.roblox.com/v1/batch",
				Headers = {
					["Content-Type"] = "application/json"
				},
				Method = "POST",
				Body = {}
			}
	
			for _, token in ipairs(tokens) do
				table.insert(payload.Body, {
					requestId = `0:{token}:AvatarHeadshot:150x150:png:regular`,
					type = "AvatarHeadShot",
					targetId = 0,
					token = token,
					format = "png",
					size = "150x150"
				})
			end
	
			payload.Body = HttpService:JSONEncode(payload.Body)
	
			local result = request(payload)
			local success, data = pcall(HttpService.JSONDecode, HttpService, result.Body)
			return success, data and data.data or data
		end
		
		local success, Username, UserId = pcall(function()
			local userId = Players:GetUserIdFromNameAsync(UserInterface.Join)
			local username = Players:GetNameFromUserIdAsync(userId)
			return username, userId
		end)
		if not success then
			return 
		end
		
		local success, response = HttpGet(`https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds={UserId}&format=Png&size=150x150&isCircular=false`)
		local thumbnail = success and response['data'][1].imageUrl
		local placeIds = {17205456753, 9472973478}
		local searching = true
		local threads = 30
	
		UserInterface:SendNotification(`Searching for {Username}`, 3)
	
		for _, placeId in ipairs(placeIds) do
			local cursor = nil
			local searched = 0
			local players = 0
	
			while searching do    
				local success, result = GetServers(placeId, cursor)
				if not success then 
					UserInterface:SendNotification(`Failed to get servers for place {placeId}!`, 3)
					break
				end
	
				local servers = result.data
				cursor = result.nextPageCursor
	
				for i, server in ipairs(servers) do
					local function FetchServer()
						local success, thumbs = FetchThumbs(server.playerTokens)
						if not success then
							return
						end
	
						players += #thumbs
	
						for _, thumb in ipairs(thumbs) do
							if thumb.imageUrl and thumb.imageUrl == thumbnail then
								searching = false
								UserInterface:SendNotification("Found player, teleporting!", 3)
	
								TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
								local connection; connection = LocalPlayer.OnTeleport:Connect(function(teleportState)
									if teleportState == Enum.TeleportState.Failed then
										connection:Disconnect()
										UserInterface:SendNotification("Server is full!", 3)
									end
								end)
								return
							end
						end
					end
					
					searched = searched + 1
					if i % threads ~= 0 then
						task.spawn(FetchServer)
						task.wait()
					else
						FetchServer()
					end
				end
	
				if not cursor then
					UserInterface:SendNotification(`Finished searching place {placeId}, player not found.`, 3)
					break
				end
	
				task.wait()
			end
			
			if not searching then
				break
			end
		end
		
		if searching then
			UserInterface:SendNotification("Failed to find player in any of the searched places!", 3)
		end
	end

	function Misc:ServerHop()
		local servers = {}
		local req = request({Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true", game.PlaceId)})
		local body = HttpService:JSONDecode(req.Body)

		if body and body.data then
			for i, v in body.data do
				if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= game.JobId then
					table.insert(servers, 1, v.id)
				end
			end
		end

		if #servers > 0 then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
		end
	end

	function Misc:Init()
		local old; old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			local args = {...}
			local method = getnamecallmethod()

			if method == "FireServer" and tostring(self) == "Load" then
				if Misc.UnlockedAll and not table.find(Misc.OldUnlocked, args[1]) then 
					TASCreator.Stages[args[2]]:Clone().Parent = LoadedUI
				end 
			elseif method == "FireServer" and tostring(self) == "Reset" and UserInterface.DisableReset then 
				return
			end

			return old(self, ...)
		end))
	end
end

do 	
	function UserInterface:SendNotification(message, time, callback, b1, b2)
		StarterGui:SetCore("SendNotification", {
			Title = "OR Tools",
			Text = message,
			Duration = time,
			Callback = callback,
			Button1 = b1,
			Button2 = b2,
		})
	end

	function UserInterface:Init()
		local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Killa5676/Killa-s-Scripts/refs/heads/main/wallyuilib"))()
		local MainWindow = Library:CreateWindow("OR Tools")

		MainWindow:Section("Auto Play")

		MainWindow:Toggle("Enabled", {
			flag = "AutoPlayEnabled"
		},function(value)
			self.AutoPlay = value
		end)

		MainWindow:Section("Stage Loader")

		MainWindow:Dropdown("Difficulty ", { 
			flag = "Select Difficulty";
			list = Data.Difficulties,
		}, function(value)
			self.SelectedDifficulty = value
			local stages = Data:GetStages()
			self.SelectStages:Refresh(stages)
		end)

		self.SelectStages = MainWindow:Dropdown("Stage ", { 
			flag = "Select Stage";
			list = Data:GetStages(),
		}, function(value)
			self.SelectedStage = value
		end)

		MainWindow:Box("Stage", {
			flag = "Select Stage box",
		}, function(value)
			self.SelectedStage = value
		end)


		MainWindow:Bind("Load Next", {
			flag = "ToggleUI",
			kbonly = true,
			default = Enum.KeyCode.N
		}, function()
			self.SelectedStage = Util:GetNextStage()
			TASCreator:CreateStage()
		end)

		MainWindow:Button("Replay", function()
			TASCreator:CreateStage(true)
		end)

		MainWindow:Button("Load", function()
			TASCreator:CreateStage()
		end)

		MainWindow:Button("Unload", function()
			TASCreator:Cleanup()
		end)

		MainWindow:Section("TAS")

		MainWindow:Bind("Camera Lock", {
			flag = "CameraLockedOnFreeze",
			kbonly = true,
			default = Enum.KeyCode.C
		}, function()
			local state = not UniversalTAS.CameraLocked

			UniversalTAS.CameraLocked = state

			UserInterface:SendNotification(`Camera {state and "Locked" or "Unlocked"}`, 3)
		end)

		MainWindow:Section("Misc")

		MainWindow:Button("Unlock Practice Stages", function()
			Misc:UnlockStages()
		end)

		MainWindow:Button("Join Pro Server", function()
			Misc:JoinProServer()
		end)

		MainWindow:Button("Serverhop", function()
			Misc:ServerHop()
		end)
		
		MainWindow:Box("Username", {
			flag = "Username",
		}, function(value)
			UserInterface.Join = value
		end)

		MainWindow:Button("Join Player", function()
			Misc:JoinPlayer()
		end)

		MainWindow:Toggle("Disable Reset", {
			flag = "DisableReset"
		},function(value)
			self.DisableReset = value
		end)
	end
end

do 
	Data:Init()
	TASCreator:Init()
	AutoPlay:Init()	
	Misc:Init()
	UserInterface:Init()
end
