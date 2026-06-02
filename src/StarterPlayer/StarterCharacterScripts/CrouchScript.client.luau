local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local rootPart = char:WaitForChild("HumanoidRootPart")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local PGS = game:GetService("PhysicsService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rigTemplate = ReplicatedStorage:WaitForChild("StealthRigTemplate")

local Crouching = false
local Debounce = false
local activeClone = nil
local activeIdle = nil
local activeMove = nil

local DEFAULT_HIP_HEIGHT = 1.745
local CROUCH_HIP_HEIGHT = 0.6     

local CROUCH_IDLE_ID = "rbxassetid://112157034461664"
local CROUCH_MOVE_ID = "rbxassetid://113728128195248"

pcall(function()
	PGS:RegisterCollisionGroup("CrouchVisuals")
	PGS:CollisionGroupSetCollidable("CrouchVisuals", "Default", false)
	PGS:CollisionGroupSetCollidable("CrouchVisuals", "Players", false)
end)

local function setRealCharacterVisibility(visible)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			part.Transparency = visible and 0 or 1
			if part.Name == "HumanoidRootPart" then part.Transparency = 1 end
		elseif part:IsA("Accessory") then
			local handle = part:FindFirstChild("Handle")
			if handle then handle.Transparency = visible and 0 or 1 end
		end
	end
end

local function cloneAppearance(sourceCharacter, targetRig)
	for _, item in ipairs(targetRig:GetChildren()) do
		if item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("Accessory") then
			item:Destroy()
		end
	end
	for _, item in ipairs(sourceCharacter:GetChildren()) do
		if item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("Accessory") then
			pcall(function() item:Clone().Parent = targetRig end)
		elseif item:IsA("Part") or item:IsA("MeshPart") then
			local targetPart = targetRig:FindFirstChild(item.Name)
			if targetPart and targetPart:IsA("BasePart") then
				targetPart.Color = item.Color
			end
		end
	end
end

local function cleanUpCrouch()
	Crouching = false
	char:SetAttribute("IsCrouching", false)

	if activeIdle then pcall(function() activeIdle:Stop() end) end
	if activeMove then pcall(function() activeMove:Stop() end) end
	if activeClone then activeClone:Destroy() end

	activeClone = nil
	activeIdle = nil
	activeMove = nil

	hum.WalkSpeed = 12
	hum.HipHeight = DEFAULT_HIP_HEIGHT 
	setRealCharacterVisibility(true)
end

local function activateCrouch()
	Crouching = true
	char:SetAttribute("IsCrouching", true)

	hum.WalkSpeed = 6
	hum.HipHeight = CROUCH_HIP_HEIGHT 

	activeClone = rigTemplate:Clone()
	activeClone.Name = player.Name .. "_Crouch"

	local cloneHum = activeClone:FindFirstChildOfClass("Humanoid")
	if cloneHum then
		-- 🛑 BOUNCE FIX: Completely freeze the state engine of the clone humanoid
		cloneHum.PlatformStand = true
		cloneHum.EvaluateStateMachine = false
		cloneHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		cloneHum.HipHeight = 0 -- Flatten out its math
	end

	local cloneAnimator = activeClone:FindFirstChildOfClass("Animator") or (cloneHum and cloneHum:FindFirstChildOfClass("Animator"))
	if not cloneAnimator then
		cloneAnimator = Instance.new("Animator", cloneHum or activeClone)
	end

	cloneAppearance(char, activeClone)

	for _, part in ipairs(activeClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			part.Anchored = false
			part.CollisionGroup = "CrouchVisuals"
		end
	end

	activeClone.Parent = workspace

	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = CROUCH_IDLE_ID
	local moveAnim = Instance.new("Animation")
	moveAnim.AnimationId = CROUCH_MOVE_ID

	activeIdle = cloneAnimator:LoadAnimation(idleAnim)
	activeMove = cloneAnimator:LoadAnimation(moveAnim)
	activeIdle.Priority = Enum.AnimationPriority.Action
	activeMove.Priority = Enum.AnimationPriority.Action

	setRealCharacterVisibility(false)
end

UIS.InputBegan:Connect(function(I, S)
	if S then return end
	if I.KeyCode == Enum.KeyCode.C then
		if Debounce then return end
		Debounce = true
		if not Crouching then activateCrouch() else cleanUpCrouch() end
		task.wait(0.3)
		Debounce = false
	end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, playerInstance)
	if playerInstance == player and prompt.Name == "StealthPrompt" then
		if Crouching then cleanUpCrouch() end
	end
end)

-- POSITION AND ANIMATION RENDERING
RS.PreRender:Connect(function()
	if not Crouching then return end
	if not activeClone or not rootPart then 
		cleanUpCrouch()
		return 
	end

	-- 🟢 VISUAL HEIGHT ALIGNMENT: 
	-- If your character still does a micro-bounce, change -1.35 to -1.25 to lift it slightly.
	activeClone:PivotTo(rootPart.CFrame * CFrame.new(0, -1.35, 0))

	if activeMove and activeIdle then
		if hum.MoveDirection.Magnitude > 0 then
			if not activeMove.IsPlaying then
				if activeIdle.IsPlaying then activeIdle:Stop() end
				activeMove:Play(0.1)
			end
		else
			if not activeIdle.IsPlaying then
				if activeMove.IsPlaying then activeMove:Stop() end
				activeIdle:Play(0.1)
			end
		end
	end
end)

hum.Died:Connect(function() cleanUpCrouch() end)