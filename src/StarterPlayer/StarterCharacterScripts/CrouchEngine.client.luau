local RS = game:GetService("RunService")
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local rootPart = char:WaitForChild("HumanoidRootPart")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rigTemplate = ReplicatedStorage:WaitForChild("StealthRigTemplate")
local playStealthAnimRemote = ReplicatedStorage:WaitForChild("PlayStealthAnimation")

local activeClone = nil
local activeWeld = nil
local activeIdleTrack = nil
local activeMoveTrack = nil
local isExecutingKnockout = false -- 🟢 NEW: Prevents engine from rendering clone during takeout

local ORIGINAL_SPEED = 12
local CROUCH_SPEED = 6

local CROUCH_IDLE_ID = "rbxassetid://112157034461664"
local CROUCH_MOVE_ID = "rbxassetid://113728128195248"

print("⚙️ ENGINE SCRIPT: Standing by for attribute updates...")

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

local function setCloneVisibility(visible)
	if not activeClone then return end
	for _, part in ipairs(activeClone:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name ~= "HumanoidRootPart" then 
				part.Transparency = visible and 0 or 1 
			end
		elseif part:IsA("Decal") or part:IsA("Texture") then
			part.Transparency = visible and 0 or 1
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
	for _, npc in ipairs(workspace:GetChildren()) do
		if npc:IsA("Model") and npc.Name == "Noob" then
			local torso = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
			local prompt = torso and torso:FindFirstChild("StealthPrompt")
			if prompt then prompt.Enabled = false end
		end
	end

	if activeIdleTrack then pcall(function() activeIdleTrack:Stop() end) end
	if activeMoveTrack then pcall(function() activeMoveTrack:Stop() end) end

	if activeWeld then activeWeld:Destroy() end
	if activeClone then activeClone:Destroy() end

	activeIdleTrack = nil
	activeMoveTrack = nil
	activeWeld = nil
	activeClone = nil

	-- Only restore real visibility if we aren't mid-knockout cutscene
	if not isExecutingKnockout then
		hum.WalkSpeed = ORIGINAL_SPEED
		setRealCharacterVisibility(true)
	end
	print("⚙️ ENGINE SCRIPT: Cleaned up visuals.")
end

local function activateCrouch()
	if isExecutingKnockout then return end -- Guard block

	hum.WalkSpeed = CROUCH_SPEED

	activeClone = rigTemplate:Clone()
	activeClone.Name = player.Name .. "_Crouch"
	cloneAppearance(char, activeClone)

	local cloneHum = activeClone:FindFirstChildOfClass("Humanoid")
	if cloneHum then
		cloneHum.PlatformStand = true
		cloneHum.EvaluateStateMachine = false
		cloneHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local cloneAnimator = activeClone:FindFirstChildOfClass("Animator") or (cloneHum and cloneHum:FindFirstChildOfClass("Animator"))
	if not cloneAnimator and cloneHum then
		cloneAnimator = Instance.new("Animator", cloneHum)
	end

	for _, part in ipairs(activeClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			if part.Name ~= "HumanoidRootPart" then part.Transparency = 0 end
		elseif part:IsA("Decal") then
			part.Transparency = 0
		end
	end

	setRealCharacterVisibility(false)
	activeClone.Parent = workspace

	local cloneRoot = activeClone:FindFirstChild("HumanoidRootPart") or activeClone:FindFirstChild("Torso")
	if cloneRoot and rootPart then
		activeClone:PivotTo(rootPart.CFrame * CFrame.new(0, -1.35, 0))

		activeWeld = Instance.new("Weld")
		activeWeld.Name = "StealthCrouchWeld"
		activeWeld.Part0 = rootPart
		activeWeld.Part1 = cloneRoot
		activeWeld.Parent = rootPart
	end

	if cloneAnimator then
		local idleAnimObj = Instance.new("Animation")
		idleAnimObj.AnimationId = CROUCH_IDLE_ID
		local moveAnimObj = Instance.new("Animation")
		moveAnimObj.AnimationId = CROUCH_MOVE_ID

		pcall(function()
			activeIdleTrack = cloneAnimator:LoadAnimation(idleAnimObj)
			activeMoveTrack = cloneAnimator:LoadAnimation(moveAnimObj)
			activeIdleTrack.Priority = Enum.AnimationPriority.Action
			activeMoveTrack.Priority = Enum.AnimationPriority.Action
		end)
	end
end

-- Watcher for manual inputs
char:GetAttributeChangedSignal("IsCrouching"):Connect(function()
	if char:GetAttribute("IsCrouching") then
		activateCrouch()
	else
		cleanUpCrouch()
	end
end)

-- 🟢 REMOTE HANDLER: Listens to the server starting/ending the knockout take down
playStealthAnimRemote.OnClientEvent:Connect(function(state)
	if state == "Start" then
		isExecutingKnockout = true
		setCloneVisibility(false) -- Hide the crouch clone completely during cutscene
		if activeIdleTrack then activeIdleTrack:Stop() end
		if activeMoveTrack then activeMoveTrack:Stop() end
	elseif state == "End" then
		isExecutingKnockout = false

		-- Check if the player's underlying attribute intent is still set to crouching
		if char:GetAttribute("IsCrouching") then
			print("⚙️ ENGINE SCRIPT: Player is still crouching. Re-activating clone model.")
			-- Destroy old ghost references and spin up a fresh animated clone instantly
			if activeWeld then activeWeld:Destroy() end
			if activeClone then activeClone:Destroy() end
			activeWeld = nil
			activeClone = nil

			activateCrouch()
		else
			-- If they somehow uncrouched during it, safely restore standard appearance
			setRealCharacterVisibility(true)
			hum.WalkSpeed = ORIGINAL_SPEED
		end
	end
end)

-- Animation Blending Tree
RS.PreRender:Connect(function()
	if isExecutingKnockout or not char:GetAttribute("IsCrouching") then return end
	if not activeClone or not rootPart or not activeIdleTrack or not activeMoveTrack then return end

	if hum.MoveDirection.Magnitude > 0 then
		if not activeMoveTrack.IsPlaying then
			if activeIdleTrack.IsPlaying then activeIdleTrack:Stop(0.1) end
			activeMoveTrack:Play(0.1)
		end
	else
		if not activeIdleTrack.IsPlaying then
			if activeMoveTrack.IsPlaying then activeMoveTrack:Stop(0.1) end
			activeIdleTrack:Play(0.1)
		end
	end
end)

-- Prompt Async Handler Loop
task.spawn(function()
	while true do
		task.wait(0.1)
		if isExecutingKnockout or not char:GetAttribute("IsCrouching") or not rootPart then continue end

		for _, npc in ipairs(workspace:GetChildren()) do
			if npc:IsA("Model") and npc.Name == "Noob" then
				local torso = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
				if torso then
					local prompt = torso:FindFirstChild("StealthPrompt")
					if prompt and prompt:IsA("ProximityPrompt") then
						local distance = (rootPart.Position - torso.Position).Magnitude
						local npcLookVector = torso.CFrame.LookVector
						local playerToNpcVector = (torso.Position - rootPart.Position).Unit
						local positionDot = playerToNpcVector:Dot(npcLookVector)

						if distance <= 6.0 and positionDot > 0.6 then
							prompt.Enabled = true
						else
							prompt.Enabled = false
						end
					end
				end
			end
		end
	end
end)

hum.Died:Connect(function()
	char:SetAttribute("IsCrouching", false)
end)