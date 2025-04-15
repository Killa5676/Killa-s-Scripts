--// Services --//

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local CoreGui = gethui and gethui() or game:GetService("CoreGui")
local MarketplaceService = game:GetService("MarketplaceService")

--// Variables --//

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local GuiInset = GuiService:GetGuiInset()

local DefaultGravity = workspace.Gravity
local DefaultJumpPower
local DefaultWalkSpeed

local Util = {}

local Animate = {
	Disabled = false,

	CurrentAnimation = "",
	CurrentAnimationInstance = nil,
	CurrentAnimationTrack = nil,
	CurrentAnimationSpeed = nil,
	CurrentAnimationKeyframeHandler = nil,
	AnimationTable = {},
	AnimationQueue = {},

	ToolAnim = "None",
	ToolAnimTime = 0,
	ToolAnimName = "",
	ToolAnimTrack = nil,
	ToolAnimInstance = nil,
	CurrentToolAnimKeyframeHandler = nil,

	JumpAnimTime = 0,
	JumpAnimDuration = 0.3,

	ToolTransitionTime = 0.1,
	FallTransitionTime = 0.3,
	JumpMaxLimbVelocity = 0.75,

	Pose = nil,

	LastTick = 0,
}

local Camera = {
	ZoomControllers = {},	
	CameraCFrame = CurrentCamera.CFrame
}

local Input = {
	Cursors = {},
	Cursor = nil,
	CursorIcon = nil,
	CursorSize = nil,
	Resolution = nil,
	CursorOffset = nil,
	ShiftLockEnabled = false,
}

local Replay = {
	Enabled = false,
	File = "FirstTAS",
	FileStart = "{\"Replay\":",
	FileEnd = "}",
	Writing = false,
	Reading = false,
	RecordingTable = {},
	ReplayTable = {},
	ReplayTableIndex = 0,
	Frozen = false,
	FreezeFrame = 1,
	SeekDirection = 0,
	SeekDirectionMultiplier = 1,
}

local Connections = {
	SteppedConnections = {},
	RenderSteppedConnections = {},
	InputEndedQueue = {},
	InputBeganQueue= {},
	HumanoidStateQueue = {},
}

--// Main --//

do 
	function Util:GetCharacter()
		return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	end

	function Util:GetHumanoid()
		return self:GetCharacter():WaitForChild("Humanoid")
	end

	function Util:GetBodyPart(bodyPart)
		local torso = self:GetCharacter():WaitForChild("Torso")

		for _, obj in torso:GetChildren() do 
			if obj.Name == bodyPart then 
				return obj
			end
		end
	end

	function Util:RoundNumber(number, digits)
		local Mult = 10 ^ math.max(tonumber(digits) or 0, 0)
		return math.floor(number * Mult + 0.5) / Mult
	end

	function Util:Vector3ToTable(vector3)
		return {vector3.X, vector3.Y, vector3.Z}
	end

	function Util:TableToVector3(tbl)
		return Vector3.new(table.unpack(tbl))
	end

	function Util:Vector2ToTable(vector2)
		return {vector2.X, vector2.Y}
	end

	function Util:TableToVector2(tbl)
		return Vector2.new(table.unpack(tbl))
	end

	function Util:CFrameToTable(cframe)
		return {cframe:GetComponents()}
	end

	function Util:TableToCFrame(tbl)
		return CFrame.new(table.unpack(tbl))
	end

	function Util:RoundTable(tbl, digits)
		local roundedTable = {}

		for i, number in tbl do
			roundedTable[i] = self:RoundNumber(number, digits)
		end

		return roundedTable
	end

	function Util:FindListIndex(tbl, search)
		for i, v in tbl do
			if v == search then
				return i
			end
		end
	end

	function Util:WaitForInput()
		local keyPressed = Instance.new("BindableEvent")
		local inputBeganConnection

		inputBeganConnection = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				RunService.RenderStepped:Wait()
				keyPressed:Fire()
			end
		end)

		keyPressed.Event:Wait()
		inputBeganConnection:Disconnect()
		keyPressed:Destroy()
	end
end

do 
	local Animations = { 
		idle = 	{	
			{ id = "http://www.roblox.com/asset/?id=180435571", weight = 8 },
			{ id = "http://www.roblox.com/asset/?id=180435792", weight = 1 }
		},
		walk = 	{ 	
			{ id = "http://www.roblox.com/asset/?id=180426354", weight = 10 } 
		}, 
		run = 	{
			{ id = "run.xml", weight = 10 } 
		}, 
		jump = 	{
			{ id = "http://www.roblox.com/asset/?id=125750702", weight = 12 } 
		}, 
		fall = 	{
			{ id = "http://www.roblox.com/asset/?id=180436148", weight = 9 } 
		}, 
		climb = {
			{ id = "http://www.roblox.com/asset/?id=180436334", weight = 10 } 
		}, 
		sit = 	{
			{ id = "http://www.roblox.com/asset/?id=178130996", weight = 10 } 
		},	
		toolnone = {
			{ id = "http://www.roblox.com/asset/?id=182393478", weight = 10 } 
		},
		toolslash = {
			{ id = "http://www.roblox.com/asset/?id=129967390", weight = 10 } 
		},
		toollunge = {
			{ id = "http://www.roblox.com/asset/?id=129967478", weight = 10 } 
		},
		wave = {
			{ id = "http://www.roblox.com/asset/?id=128777973", weight = 10 } 
		},
		point = {
			{ id = "http://www.roblox.com/asset/?id=128853357", weight = 10 } 
		},
		dance1 = {
			{ id = "http://www.roblox.com/asset/?id=182435998", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491037", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491065", weight = 10 } 
		},
		dance2 = {
			{ id = "http://www.roblox.com/asset/?id=182436842", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491248", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491277", weight = 10 } 
		},
		dance3 = {
			{ id = "http://www.roblox.com/asset/?id=182436935", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491368", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491423", weight = 10 } 
		},
		laugh = {
			{ id = "http://www.roblox.com/asset/?id=129423131", weight = 10 } 
		},
		cheer = {
			{ id = "http://www.roblox.com/asset/?id=129423030", weight = 10 } 
		},
	}

	local Dances = {"dance1", "dance2", "dance3"}

	local Emotes = { wave = false, point = false, dance1 = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

	function Animate:Destroy()
		for _, obj in Util:GetCharacter():GetDescendants() do 
			if obj:IsA("LocalScript") and obj.Name == "Animate" then 
				obj:Destroy()
			end
		end
	end

	function Animate:StopAllAnimations()
		for _, animation in Util:GetHumanoid():GetPlayingAnimationTracks() do 
			animation:Stop()
		end
	end

	function Animate:StopAllAnimationsAdvanced()
		local oldAnimation = self.CurrentAnimation

		if (Emotes[oldAnimation] ~= nil and Emotes[oldAnimation] == false) then
			oldAnimation = "idle"
		end

		self.CurrentAnimation = ""
		self.CurrentAnimationInstance = nil

		if (self.CurrentAnimationKeyframeHandler ~= nil) then
			self.CurrentAnimationKeyframeHandler:disconnect()
		end

		if (self.CurrentAnimationTrack ~= nil) then
			self.CurrentAnimationTrack:Stop()
			self.CurrentAnimationTrack:Destroy()
			self.CurrentAnimationTrack = nil
		end

		return oldAnimation
	end

	function Animate:GetAnimationFunctionFromId(id)
		return ({
			[1] = self.OnDied;
			[2] = self.OnRunning;
			[3] = self.OnJumping;
			[4] = self.OnClimbing;
			[5] = self.OnGettingUp;
			[6] = self.OnFreeFall;
			[7] = self.OnFallingDown;
			[8] = self.OnSeated;
			[9] = self.OnPlatformStanding;
			[10] = self.OnSwimming;
		})[id]
	end

	function Animate:ConfigureAnimationSet(name, fileList)
		if (self.AnimationTable[name] ~= nil) then
			for _, connection in self.AnimationTable[name].connections do
				connection:disconnect()
			end
		end
		self.AnimationTable[name] = {}
		self.AnimationTable[name].count = 0
		self.AnimationTable[name].totalWeight = 0	
		self.AnimationTable[name].connections = {}

		if (self.AnimationTable[name].count <= 0) then
			for idx, anim in pairs(fileList) do
				self.AnimationTable[name][idx] = {}
				self.AnimationTable[name][idx].anim = Instance.new("Animation")
				self.AnimationTable[name][idx].anim.Name = name
				self.AnimationTable[name][idx].anim.AnimationId = anim.id
				self.AnimationTable[name][idx].weight = anim.weight
				self.AnimationTable[name].count = self.AnimationTable[name].count + 1
				self.AnimationTable[name].totalWeight = self.AnimationTable[name].totalWeight + anim.weight
			end
		end
	end

	function Animate:SetAnimationSpeed(speed)
		if speed ~= self.CurrentAnimationSpeed then 
			self.CurrentAnimationSpeed = speed
			self.CurrentAnimationTrack:AdjustSpeed(self.CurrentAnimationSpeed)
		end
	end

	function Animate:KeyFrameReached(frameName)
		if (frameName == "End") then

			local repeatAnim = self.CurrentAnimation
			if (Emotes[repeatAnim] ~= nil and Emotes[repeatAnim] == false) then
				repeatAnim = "idle"
			end

			local animSpeed = self.CurrentAnimationSpeed
			self:PlayAnimation(repeatAnim, 0.0)
			self:SetAnimationSpeed(animSpeed)
		end
	end

	function Animate:PlayAnimation(animName, transitionTime, bypassAnimateDisabled)
		--pcall(function()
		if self.Disabled and not bypassAnimateDisabled then
			return
		end

		table.insert(self.AnimationQueue,{animName,transitionTime})

		local roll = math.random(1, self.AnimationTable[animName].totalWeight) 
		local origRoll = roll
		local idx = 1

		while (roll > self.AnimationTable[animName][idx].weight) do
			roll = roll - self.AnimationTable[animName][idx].weight
			idx = idx + 1
		end

		local anim = self.AnimationTable[animName][idx].anim

		if (anim ~= self.CurrentAnimationInstance) then

			if (self.CurrentAnimationTrack ~= nil) then
				self.CurrentAnimationTrack:Stop(transitionTime)
				self.CurrentAnimationTrack:Destroy()
			end

			self.CurrentAnimationSpeed = 1.0

			self.CurrentAnimationTrack = Util:GetHumanoid():LoadAnimation(anim)
			self.CurrentAnimationTrack.Priority = Enum.AnimationPriority.Core

			self.CurrentAnimationTrack:Play(transitionTime)
			self.CurrentAnimation = animName
			self.CurrentAnimationInstance = anim

			if (self.CurrentAnimationKeyframeHandler ~= nil) then
				self.CurrentAnimationKeyframeHandler:disconnect()
			end

			self.CurrentAnimationKeyframeHandler = self.CurrentAnimationTrack.KeyframeReached:Connect(function(...)
				self:KeyFrameReached(...)
			end)
		end
		--end)
	end

	function Animate:ToolKeyFrameReached(frameName)
		if (frameName == "End") then

			self:PlayToolAnimation(self.ToolAnimationName, 0.0)
		end
	end

	function Animate:PlayToolAnimation(animName, transitionTime, priority)
		local roll = math.random(1, self.AnimationTable[animName].totalWeight) 
		local origRoll = roll
		local idx = 1
		while (roll > self.AnimationTable[animName][idx].weight) do
			roll = roll - self.AnimationTable[animName][idx].weight
			idx = idx + 1
		end

		local anim = self.AnimationTable[animName][idx].anim

		if (self.ToolAnimInstance ~= anim) then

			if (self.ToolAnimTrack ~= nil) then
				self.ToolAnimTrack:Stop()
				self.ToolAnimTrack:Destroy()
				transitionTime = 0
			end

			self.ToolAnimTrack = Util:GetHumanoid():LoadAnimation(anim)
			if priority then
				self.ToolAnimTrack.Priority = priority
			end

			self.ToolAnimTrack:Play(transitionTime)
			self.ToolAnimName = animName
			self.ToolAnimInstance = anim

			self.CurrentToolAnimKeyframeHandler = self.ToolAnimationTrack.KeyframeReached:Connect(function(...)
				self:ToolKeyFrameReached(...)
			end)
		end
	end

	function Animate:StopToolAnimations()
		local oldAnim = self.ToolAnimName

		if (self.CurrentToolAnimKeyframeHandler ~= nil) then
			self.CurrentToolAnimKeyframeHandler:disconnect()
		end

		self.ToolAnimName = ""
		self.ToolAnimInstance = nil
		if (self.ToolAnimTrack ~= nil) then
			self.ToolAnimTrack:Stop()
			self.ToolAnimTrack:Destroy()
			self.ToolAnimTrack = nil
		end


		return oldAnim
	end

	function Animate:OnRunning(speed)
		if speed > 0.01 then
			self:PlayAnimation("walk", 0.1)
			if self.CurrentAnimationInstance and self.CurrentAnimationInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
				self:SetAnimationSpeed(speed / 14.5)
			end
			self.Pose = "Running"
		else
			if Emotes[self.CurrentAnimation] == nil then
				self:PlayAnimation("idle", 0.1)
				self.Pose = "Standing"
			end
		end
	end

	function Animate:OnDied()
		self.Pose = "Dead"
	end

	function Animate:OnJumping()
		self:PlayAnimation("jump", 0.1)
		self.JumpAnimTime = self.JumpAnimDuration
		self.Pose = "Jumping"
	end

	function Animate:OnClimbing(speed)
		self:PlayAnimation("climb", 0.1)
		self:SetAnimationSpeed(speed / 12.0)
		self.Pose = "Climbing"
	end

	function Animate:OnGettingUp()
		self.Pose = "GettingUp"
	end

	function Animate:OnFreeFall()
		if (self.JumpAnimTime <= 0) then
			self:PlayAnimation("fall", self.FallTransitionTime)
		end
		self.Pose = "FreeFall"
	end

	function Animate:OnFallingDown()
		self.Pose = "FallingDown"
	end

	function Animate:OnSeated()
		self.Pose = "Seated"
	end

	function Animate:OnPlatformStanding()
		self.Pose = "PlatformStanding"
	end

	function Animate:OnSwimming(speed)
		if speed > 0 then
			self.Pose = "Running"
		else
			self.Pose = "Standing"
		end
	end

	function Animate:GetTool()
		for _, obj in Util:GetCharacter():GetChildren() do 
			if obj.ClassName == "Tool" then 
				return obj
			end
		end
	end

	function Animate:GetToolAnimation(tool)
		for _, obj in tool:GetChildren() do
			if obj.Name == "toolanim" and obj.className == "StringValue" then
				return obj
			end
		end
	end

	function Animate:AnimateTool()
		if self.ToolAnim == "None" then
			self:PlayToolAnimation("toolnone", self.ToolTransitionTime, Enum.AnimationPriority.Idle)
		elseif self.ToolAnim == "Slash" then 
			self:PlayToolAnimation("toolslash", 0, Enum.AnimationPriority.Action)	
		elseif self.ToolAnim == "Lunge" then	
			self:PlayToolAnimation("toollunge", 0, Enum.AnimationPriority.Action)
		end	
	end

	function Animate:Move(time)
		if self.Disabled then
			return
		end

		local amplitude = 1
		local frequency = 1
		local deltaTime = time - self.LastTick
		self.LastTick = time

		local climbFudge = 0
		local setAngles = false

		if (self.JumpAnimTime > 0) then
			self.JumpAnimTime = self.JumpAnimTime - deltaTime
		end

		if (self.Pose == "FreeFall" and self.JumpAnimTime <= 0) then
			self:PlayAnimation("fall", self.FallTransitionTime)
		elseif (self.Pose == "Seated") then
			self:PlayAnimation("sit", 0.5)
			return
		elseif (self.Pose == "Running") then
			self:PlayAnimation("walk", 0.1)
		elseif (self.Pose == "Dead" or self.Pose == "GettingUp" or self.Pose == "FallingDown" or self.Pose == "Seated" or self.Pose == "PlatformStanding") then
			self:StopAllAnimationsAdvanced()
			amplitude = 0.1
			frequency = 1
			setAngles = true
		end

		if (setAngles) then
			local desiredAngle = amplitude * math.sin(time * frequency)

			Util:GetBodyPart("RightShoulder"):SetDesiredAngle(desiredAngle + climbFudge)
			Util:GetBodyPart("LeftShoulder"):SetDesiredAngle(desiredAngle - climbFudge)
			Util:GetBodyPart("RightHip"):SetDesiredAngle(-desiredAngle)
			Util:GetBodyPart("LeftHip"):SetDesiredAngle(-desiredAngle)
		end

		local tool = self:GetTool()
		if tool and tool:FindFirstChild("Handle") then

			local animStringValueObject = self:GetToolAnimation(tool)

			if animStringValueObject then
				self.ToolAnim = animStringValueObject.Value
				animStringValueObject.Parent = nil
				self.ToolAnim = time + .3
			end

			if time > self.ToolAnimTime then
				self.ToolAnimTime = 0
				self.ToolAnim = "None"
			end

			self:AnimateTool()		
		else
			self:StopToolAnimations()
			self.ToolAnim = "None"
			self.ToolAnimInstance = nil
			self.ToolAnimTime = 0
		end
	end

	function Animate:Reanimate()
		self:Destroy()

		local character = Util:GetCharacter()
		local humanoid = Util:GetHumanoid()

		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator") or nil
		if animator then
			local animationTracks = animator:GetPlayingAnimationTracks()
			for i,track in animationTracks do
				track:Stop(0)
				track:Destroy()
			end
		end

		self:StopAllAnimations()

		for name, fileList in Animations do 
			self:ConfigureAnimationSet(name, fileList)
		end	

		humanoid.Died:Connect(function(...)
			if self.Disabled then
				return
			end

			self:OnDied(...)
		end)

		humanoid.Running:Connect(function(...)
			if self.Disabled then
				return
			end

			self:OnRunning(...)
		end)

		humanoid.Jumping:Connect(function(...)
			self:OnJumping(...)
		end)

		humanoid.Climbing:Connect(function(...)
			if self.Disabled then
				return
			end

			self:OnClimbing(...)
		end)

		humanoid.GettingUp:connect(function(...)
			if self.Disabled then
				return
			end

			self:OnGettingUp(...)
		end)

		humanoid.FreeFalling:connect(function(...)
			if self.Disabled then
				return
			end

			self:OnFreeFall(...)
		end)

		humanoid.FallingDown:connect(function(...)
			if self.Disabled then
				return
			end

			self:OnFallingDown(...)
		end)

		humanoid.Seated:connect(function(...)
			if self.Disabled then
				return
			end

			self:OnSeated(...)
		end)

		humanoid.PlatformStanding:connect(function(...)
			if self.Disabled then
				return
			end

			self:OnPlatformStanding(...)
		end)

		humanoid.Swimming:connect(function(...)
			if self.Disabled then
				return
			end

			self:OnSwimming(...)
		end)

		LocalPlayer.Chatted:connect(function(msg)
			local emote = ""
			if msg == "/e dance" then
				emote = Dances[math.random(1, #Dances)]
			elseif (string.sub(msg, 1, 3) == "/e ") then
				emote = string.sub(msg, 4)
			elseif (string.sub(msg, 1, 7) == "/emote ") then
				emote = string.sub(msg, 8)
			end

			if (self.Pose == "Standing" and Emotes[emote] ~= nil) then
				self:PlayAnimation(emote, 0.1)
			end
		end)

		self:PlayAnimation("idle", 0.1)

		self.Pose = "Standing"

		task.spawn(function()
			while character.Parent ~= nil do
				local _, time = wait(0.1)

				self:Move(time)
			end
		end)
	end
end

do
	function Camera:SetZoom(zoom)
		for _,ZoomController in self.ZoomControllers do
			pcall(function()
				ZoomController:SetCameraToSubjectDistance(zoom)
			end)
		end
	end

	function Camera:GetZoom()
		for _,ZoomController in self.ZoomControllers do
			local Zoom = ZoomController:GetCameraToSubjectDistance()
			if Zoom and Zoom ~= 12.5 then
				return Zoom
			end
		end

		return 12.5
	end

	function Camera:SetCFrame(cframe)
		self.CameraCFrame = cframe
	--	CurrentCamera.CFrame = cframe
	end

	function Camera:Init()
		VirtualInputManager:SendKeyEvent(true, 304, false, workspace)
		task.wait()
		VirtualInputManager:SendKeyEvent(true, 304, false, workspace)
		task.wait()

		for _, obj in getgc(true) do
			if type(obj) == "table" and rawget(obj, "FIRST_PERSON_DISTANCE_THRESHOLD") then
				table.insert(self.ZoomControllers, obj)
			end
		end	
	end
end

do  
	local Cursors = {
		["ArrowFarCursor"] = {
			Icon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png";
			Size = UDim2.fromOffset(64,64);
			Offset = Vector2.new(-32,4);
		};
		["MouseLockedCursor"] = {
			Icon = "rbxasset://textures/MouseLockedCursor.png";
			Size = UDim2.fromOffset(32,32);
			Offset = Vector2.new(-16,20);
		};
	}

	function Input:GetShiftLockEnabled()
		return self.ShiftLockEnabled
	end

	function Input:SetShiftLockEnabled(bool)
		if self.ShiftLockEnabled ~= bool then
			self.ShiftLockEnabled = bool
			if bool then
				self:SetCursor("MouseLockedCursor")
			else
				self:SetCursor("ArrowFarCursor")
			end

			self.MouseLockController:DoMouseLockSwitch("MouseLockSwitchAction", Enum.UserInputState.Begin, game)
		end
	end

	function Input:BlockInputs()
		self.Controls:Disable()
	end

	function Input:UnblockInputs()
		self.Controls:Enable()
	end

	function Input:SetCursor(name)
		local CursorData = Cursors[name]
		self.CursorIcon = CursorData.Icon
		self.CursorSize = CursorData.Size
		self.CursorOffset = CursorData.Offset
	end

	function Input:Init()		
		self.CursorHolder = Instance.new("ScreenGui")
		self.Cursor = Instance.new("ImageLabel")
		self.Cursor.BackgroundTransparency = 1
		self.Cursor.ZIndex = math.huge
		self.Cursor.Parent = self.CursorHolder
		self.CursorHolder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		self.CursorHolder.Parent = CoreGui
		self.CursorHolder.DisplayOrder = 2147483647
		self.Resolution = self.CursorHolder.AbsoluteSize

		self.BlockGui = Instance.new("ScreenGui")
		self.BlockFrame = Instance.new("TextButton")
		self.BlockFrame.Text = ""
		self.BlockFrame.BackgroundTransparency = 1
		self.BlockFrame.Size = UDim2.fromScale(1,1)
		self.BlockFrame.Selectable = false
		self.BlockFrame.Selected = false
		self.BlockFrame.Parent = self.BlockGui 
		self.BlockGui.Enabled = false
		self.BlockGui.Parent = CoreGui

		for _, obj in getgc(true) do 
			if type(obj) == "table" and rawget(obj, "activeMouseLockController") then 
				self.MouseLockController = obj.activeMouseLockController
				break
			end
		end

		for _, obj in getgc(true) do 
			if type(obj) == "table" and rawget(obj, "controls") then 
				self.Controls = obj.controls
				break
			end
		end

		self:SetCursor("ArrowFarCursor")
		UserInputService.MouseIconEnabled = false
		LocalPlayer:FindFirstChild("BoundKeys", true).Value = ""

		task.spawn(function()
			while true do
				self.Cursor.Image = self.CursorIcon
				self.Cursor.Size = self.CursorSize

				local mouseLocation = UserInputService:GetMouseLocation()
				if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
					self.Cursor.Position = UDim2.fromOffset((self.Resolution.X / 2)+self.CursorOffset.X-GuiInset.X,(self.Resolution.Y/2)+self.CursorOffset.Y-GuiInset.Y-18)
				else
					self.Cursor.Position = UDim2.fromOffset(mouseLocation.X+self.CursorOffset.X-GuiInset.X,mouseLocation.Y+self.CursorOffset.Y-GuiInset.Y-36)
				end

				RunService.RenderStepped:Wait()
			end
		end)
	end
end

do 	
	function Replay:Encode(tbl)
		local encoded = HttpService:JSONEncode(tbl)

		return `{self.FileStart}{encoded}{self.FileEnd}`
	end

	function Replay:Decode(str)
		local decoded = HttpService:JSONDecode(str)

		return decoded.Replay
	end
	
	function Replay:NewFile(fileName)
		self.File = fileName
		self.RecordingTable = {}
		self.ReplayTable = {}
		self.ReplayTableIndex = 0
		self.FreezeFrame = 1
		self.SeekDirection = 0
		self.SeekDirectionMultiplier = 1
	end
	
	function Replay:GetReplayFile()
		if not isfolder("Universal TAS") then 
			makefolder("Universal TAS")
		end

		if not isfile(`Universal TAS/{self.File}.json`) then 
			writefile(`Universal TAS/{self.File}.json`, self.FileStart)
			return self.FileStart
		end

		return readfile(`Universal TAS/{self.File}.json`)
	end

	function Replay:SaveToFile()
		local encoded = self:Encode(self.ReplayTable)

		writefile(`Universal TAS/{self.File}.json`, encoded)
	end

	function Replay:RecordReplay()
		if self.Writing then 
			self:Stop()
			return
		end

		Util:WaitForInput()

		self:Start()
	end

	function Replay:StartRecording()
		if self.Reading then 
			return
		end

		self.Writing = true
	end

	function Replay:StopRecording()
		if self.Reading then 
			return
		end

		self.Writing = false
	end

	function Replay:SaveRecording()
		if #self.RecordingTable > 0 then 
			local old = #self.ReplayTable

			for _, frame in self.RecordingTable do 
				table.insert(self.ReplayTable, frame)
			end

			self.RecordingTable = {}
		end
	end

	function Replay:DiscardRecording()
		if #self.RecordingTable > 0 then
			self.RecordingTable = {}
		end
	end

	function Replay:StartReading(file, dly)
		if self.Reading then 
			return
		end

		dly = dly or 3

		task.wait(dly)
		
		self:SaveToFile()
				
		self.ReplayTable = file or self:Decode(self:GetReplayFile())
		if not self.ReplayTable then 
			self.ReplayTable = {}
		end

		self:Freeze(false, nil, true)
		Animate.Disabled = true
		workspace.Gravity = 0
		self.ReplayTableIndex = 1
		Input:BlockInputs()
		self.Reading = true
	end

	function Replay:StopReading()
		if not self.Reading then
			return 
		end

		local character = Util:GetCharacter()

		Input:UnblockInputs()
		character.Head.CanCollide = true 
		character.Torso.CanCollide = true
		character.HumanoidRootPart.CanCollide = true
		Animate.Disabled = false
		self.Reading = false
		character.Humanoid.JumpPower = DefaultJumpPower
		character.Humanoid.WalkSpeed = DefaultWalkSpeed

		workspace.Gravity = DefaultGravity
	end

	function Replay:Freeze(bool, dontRecord, nah)
		if self.Frozen == bool or self.Reading then 
			return
		end

		self.SeekDirection = 0

		if bool then 
			self.Frozen = true
			self:StopRecording()
			self:SaveRecording()
			self.FreezeFrame = #self.ReplayTable
		else 
			if dontRecord then 
				self.Frozen = false
			else 
				for i = #self.ReplayTable, self.FreezeFrame, -1 do
					self.ReplayTable[i] = nil
				end

				self.Frozen  = false
				
				if not nah then 

				self:StartRecording()
				end
			end
		end
	end

	function Replay:Init()
		task.spawn(function()
			while true do 
				if self.Reading then 
					local frame = self.ReplayTable[self.ReplayTableIndex]
					if frame == 0 then 
						Util:GetHumanoid():ChangeState(15)
						for _, obj in Util:GetCharacter():GetDescendants() do 
							if obj:IsA("BasePart") then 
								obj:Destroy()
							end
						end
						repeat 
							task.wait()
						until not Connections.Dead
						RunService.Heartbeat:Wait()
						self.ReplayTableIndex += 1
						continue
					elseif frame == 1 then 
						Util:GetHumanoid():ChangeState(15)
						workspace.Gravity = DefaultGravity

						continue
					end
					if not frame then 
						Replay:StopReading()
						continue
					end
					Animate.Disabled = true
					workspace.Gravity = 0
					Util:GetHumanoid().WalkSpeed = 0
					Util:GetHumanoid().JumpPower = 0
					if not Util:GetCharacter():FindFirstChild("HumanoidRootPart") then 
						RunService.Heartbeat:Wait()

						continue
					end
					local rootPartCFrame = Util:TableToCFrame(frame[1])
					local animations = frame[2]
					local animationSpeed = frame[3]
					local humanoidState = frame[4]
					local currentCameraCFrame = Util:TableToCFrame(frame[7]) 
					local zoom = frame[8]
					local animatePose = frame[9]
					local shiftLockEnabled = (frame[10] == 1 and true) or false
					local mouseLocation = Util:TableToVector2(frame[11])
					local CurrentState = Util:GetHumanoid():GetState().Value
					Camera:SetCFrame(currentCameraCFrame)
					Camera:SetZoom(zoom)
					Util:GetHumanoid():ChangeState(humanoidState)
					Animate.Pose = animatePose
					for _, args in animations do
						local animation = args[1]
						local transitionTime = args[2]
						if animation == "walk" then
							if Util:GetHumanoid().FloorMaterial ~= Enum.Material.Air and CurrentState ~= 3 then
								Animate:PlayAnimation("walk", transitionTime, true)
							end
						else
							Animate:PlayAnimation(animation, transitionTime, true)
						end
					end
					pcall(function()
						Animate:SetAnimationSpeed(animationSpeed)
					end)

					if shiftLockEnabled then
						Input:SetShiftLockEnabled(true)
					else
						Input:SetShiftLockEnabled(false)
					end	

					if not shiftLockEnabled and zoom > 0.52 then
						mousemoveabs(mouseLocation.X, mouseLocation.Y)
					else
						mousemoveabs((Input.Resolution.X / 2) + Input.CursorOffset.X - GuiInset.X, (Input.Resolution.Y / 2) + Input.CursorOffset.Y - GuiInset.Y - 36)
					end
					Util:GetCharacter().HumanoidRootPart.CFrame = rootPartCFrame
					self.ReplayTableIndex += 1
				end
				RunService.Heartbeat:Wait()
			end
		end)


		task.spawn(function()
			while true do 
				if self.Reading then
					if workspace.Gravity ~= DefaultGravity then
						for _,v in Util:GetCharacter():GetChildren() do
							if v:IsA("BasePart") then
								v.CanCollide = false
							end
						end
					end
					if not Util:GetCharacter():FindFirstChild("HumanoidRootPart") then
						RunService.Stepped:Wait()
						continue
					end
					local frame = self.ReplayTable[self.ReplayTableIndex]
					if frame and type(frame) == "table" then
						local humanoidRootPartCFrame = Util:TableToCFrame(frame[1])
						local currentCameraCFrame = Util:TableToCFrame(frame[7])
						local zoom = frame[8]

						Util:GetCharacter().HumanoidRootPart.CFrame = humanoidRootPartCFrame
					end
				else
					workspace.Gravity = DefaultGravity
				end
				RunService.Stepped:Wait()
			end
		end)

		task.spawn(function()
			while true do
				if self.Writing then 
					if (not Util:GetCharacter() or not Util:GetCharacter().Parent) or (not Util:GetCharacter():FindFirstChild("HumanoidRootPart")) then
						if type(self.RecordingTable[#self.RecordingTable]) == "table" then
							table.insert(self.RecordingTable, 0)
						end
						RunService.RenderStepped:Wait()
						continue
					end
					if (Util:GetHumanoid().Health == 0) then
						if type(self.RecordingTable[#self.RecordingTable]) == "table" then
							table.insert(self.RecordingTable, 1)
						end
						RunService.RenderStepped:Wait()
						continue
					end
					local frame = {}
					frame[1] = Util:RoundTable(Util:CFrameToTable(Util:GetCharacter().HumanoidRootPart.CFrame), 3)
					frame[2] = Animate.AnimationQueue
					frame[3] = Util:RoundNumber(Animate.CurrentAnimationSpeed, 3)
					frame[4] = Util:GetHumanoid():GetState().Value
					frame[5] = Util:RoundTable(Util:Vector3ToTable(Util:GetCharacter().HumanoidRootPart.Velocity), 3)
					frame[6] = Util:RoundTable(Util:Vector3ToTable(Util:GetCharacter().HumanoidRootPart.RotVelocity), 3)
					frame[7] = Util:RoundTable(Util:CFrameToTable(CurrentCamera.CFrame), 3)
					frame[8] = Util:RoundNumber(Camera:GetZoom(), 3)
					frame[9] = Animate.Pose
					frame[10] = (Input:GetShiftLockEnabled() and 1) or 0
					frame[11] = Util:RoundTable(Util:Vector2ToTable(UserInputService:GetMouseLocation()), 3)
					frame[12] = {Connections.InputBeganQueue, Connections.InputEndedQueue}
					table.insert(self.RecordingTable, frame)
				end
				Animate.AnimationQueue = {}
				Connections.HumanoidStateQueue = {}
				if setfpscap then
					setfpscap(60)
				end
				RunService.RenderStepped:Wait()
			end
		end)

		task.spawn(function()
			while true do
				if self.Frozen then
					Util:GetCharacter().HumanoidRootPart.Anchored = true
					if self.FreezeFrame > 0 and self.FreezeFrame <= #self.ReplayTable then
						local RoundedFreezeFrame = Util:RoundNumber(self.FreezeFrame, 0)
						local Frame = self.ReplayTable[RoundedFreezeFrame]
						if type(Frame) == "table" then
							local AnimatePose
							local Animation
							for i = RoundedFreezeFrame,1,-1 do
								if AnimatePose and Animation then
									break
								end
								local Frame = self.ReplayTable[i]
								if type(Frame) == "table" then
									AnimatePose = Frame[9]
									Animation = Frame[2][#Frame[2]]
								end
							end
							local CurrentPressedKeys = {}
							for Index = RoundedFreezeFrame-math.max(500,0),RoundedFreezeFrame do
								local Frame = self.ReplayTable[Index]
								if Frame and type(Frame) == "table" then
									local BeganInputs, EndedInputs = table.unpack(Frame[12])

									for _,Key in BeganInputs do
										if Key ~= "u" and Key ~= "d" then
											CurrentPressedKeys[Key] = true
										end
									end

									for _,Key in EndedInputs do
										CurrentPressedKeys[Key] = nil
									end
								end
							end
							local HumanoidRootPartCFrame = Util:TableToCFrame(Frame[1])
							local AnimationSpeed = Frame[3]
							local HumanoidState = Frame[4]
							local HumanoidRootPartVelocity = Util:TableToVector3(Frame[5]) 
							local HumanoidRootPartRotVelocity = Util:TableToVector3(Frame[6])
							local CameraCFrame = Util:TableToCFrame(Frame[7]) 
							local Zoom = Frame[8]
							local ShiftLockEnabled = (Frame[10] == 1 and true) or false
							local MouseLocation = Util:TableToVector2(Frame[11])
							local CurrentState = Util:GetHumanoid():GetState().Value
							if Animation then
								if Animation[1] == "walk" then
									if Util:GetHumanoid().FloorMaterial ~= Enum.Material.Air and CurrentState ~= 3 then
										Animate:PlayAnimation("walk",Animation[2],true)
									end
								else
									Animate:PlayAnimation(Animation[1],Animation[2],true)
								end
							end
							pcall(function()
								Animate:SetAnimationSpeed(AnimationSpeed)
							end)
							Animate.Pose = AnimatePose
							Util:GetHumanoid():ChangeState(HumanoidState)
							Util:GetCharacter().HumanoidRootPart.Velocity = HumanoidRootPartVelocity
							Util:GetCharacter().HumanoidRootPart.RotVelocity = HumanoidRootPartRotVelocity
							Util:GetCharacter().HumanoidRootPart.CFrame = HumanoidRootPartCFrame
							print("set")
							CurrentCamera.CFrame = CameraCFrame
							Camera:SetZoom(Zoom)
							if ShiftLockEnabled ~= Input:GetShiftLockEnabled() then
								Input:SetShiftLockEnabled(ShiftLockEnabled)
							end
							mousemoveabs(MouseLocation.X,MouseLocation.Y)
						else
							RunService.RenderStepped:Wait()
						end
					end
				else
					pcall(function()
						Util:GetCharacter().HumanoidRootPart.Anchored = false
					end)
				end
				RunService.RenderStepped:Wait()
			end
		end)
	end
end

do 
	local InputBlacklist = {
		["R"] = true;
		["T"] = true;
		["F"] = true;
		["G"] = true;
		["E"] = true;
	}

	function Connections:CharacterAdded()
		local humanoid = Util:GetHumanoid()

		humanoid.StateChanged:Connect(function(_, state)
			table.insert(self.HumanoidStateQueue, state.Value)
		end)

		DefaultJumpPower = humanoid.JumpPower
		DefaultWalkSpeed = humanoid.WalkSpeed
		Animate:Reanimate()

		humanoid.Died:Connect(function()
			self.Dead = true
		end)

		self.Dead = false
	end

	function Connections:Init()
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				gameProcessed = false
			end
			

			if input.KeyCode == Enum.KeyCode.LeftShift and not Replay.Reading and not gameProcessed then
				Input:SetShiftLockEnabled(not Input.ShiftLockEnabled)
			end

			if not Replay.Enabled then 
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				table.insert(self.InputBeganQueue,"b1")
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				table.insert(self.InputBeganQueue,"b2")
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
				local inputName = string.split(tostring(input.KeyCode),".")[3]

				if not InputBlacklist[inputName] then
					table.insert(self.InputBeganQueue, inputName)
				end
			end

			if input.KeyCode == Enum.KeyCode.E then
				Replay:Freeze(not Replay.Frozen)
			elseif input.KeyCode == Enum.KeyCode.T  then
				
				if not Replay.Reading then
					Replay:Freeze(true)
					if Replay.SeekDirection == 0 then
						Replay.SeekDirection = -1 * Replay.SeekDirectionMultiplier
					end
				end
			elseif input.KeyCode == Enum.KeyCode.Y then				
				if not Replay.Reading then
					Replay:Freeze(true)
					if Replay.SeekDirection == 0 then
						Replay.SeekDirection = 1 * Replay.SeekDirectionMultiplier
					end
				end
			elseif input.KeyCode == Enum.KeyCode.F and Replay.SeekDirection == 0 then 
				Replay:Freeze(true)

				local newFreezeFrame = Replay.FreezeFrame - 1
				if newFreezeFrame > 0 and newFreezeFrame <= #Replay.ReplayTable then
					Replay.FreezeFrame = newFreezeFrame
				end
			elseif input.KeyCode == Enum.KeyCode.G and Replay.SeekDirection == 0  then
				Replay:Freeze(true)

				local newFreezeFrame = Replay.FreezeFrame + 1
				if newFreezeFrame > 0 and newFreezeFrame <= #Replay.ReplayTable then
					Replay.FreezeFrame = newFreezeFrame
				end
			elseif input.KeyCode == Enum.KeyCode.Q then 
				Replay:StartReading()	
			elseif input.KeyCode == Enum.KeyCode.L then 
				Replay:StopReading()
			elseif input.KeyCode == Enum.KeyCode.P then 
				Replay:SaveToFile()	
			end
		end)

		UserInputService.InputChanged:Connect(function(input, gameProcessed)
			if not Replay.Enabled then 
				return
			end

			if Input.UserInputType == Enum.UserInputType.MouseWheel then
				if Input.Position.Z > 0 then
					table.insert(self.InputBeganQueue,"u")
				else
					table.insert(self.InputBeganQueue,"d")
				end
			end
		end)


		UserInputService.InputEnded:Connect(function(input, gameProcessed)
			if not Replay.Enabled then 
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				table.insert(self.InputEndedQueue,"b1")
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				table.insert(self.InputEndedQueue,"b2")
			elseif input.UserInputType == Enum.UserInputType.MouseWheel then
				if input.Position.Z > 0 then
					table.insert(self.InputEndedQueue,"u")
				else
					table.insert(self.InputEndedQueue,"d")
				end			
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
				local inputName = string.split(tostring(input.KeyCode),".")[3]
				table.insert(self.InputEndedQueue, inputName)
			end

			if input.KeyCode == Enum.KeyCode.T then
				if Replay.SeekDirection == -1*Replay.SeekDirectionMultiplier then
					Replay.SeekDirection = 0
				end
			elseif input.KeyCode == Enum.KeyCode.Y then
				if Replay.SeekDirection == 1*Replay.SeekDirectionMultiplier then
					Replay.SeekDirection = 0
				end
			end
		end)

		RunService.RenderStepped:Connect(function()
			if not Replay.Frozen then 
				return
			end
			
			local NewFreezeFrame = Replay.FreezeFrame + Replay.SeekDirection
			
			if NewFreezeFrame < 1 then
				Replay.FreezeFrame = 1
			elseif NewFreezeFrame > #Replay.ReplayTable then
				Replay.FreezeFrame = #Replay.ReplayTable
			else
				Replay.FreezeFrame = NewFreezeFrame
			end
		end)

		CurrentCamera.Changed:Connect(function()
			if Replay.Reading then
			CurrentCamera.CFrame = Camera.CameraCFrame
			end
		end)

		LocalPlayer.CharacterAdded:Connect(function(...)
			self:CharacterAdded(...)
		end)
	end
end

do 
	Input:Init()
	Camera:Init()
	Replay:Init()
	Connections:Init()

	Connections:CharacterAdded()

	RunService.Heartbeat:Connect(function()
		Connections.InputBeganQueue = {}
		Connections.InputEndedQueue = {}
	end)
end

return Replay
