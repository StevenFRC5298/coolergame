local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- CONFIGURATION
local MAX_DISTANCE = 4
local STEALTH_ANGLE = 0.5
local PUSH_FORCE = 15
local ANIMATION_TIME = 0.8

local remote = ReplicatedStorage:WaitForChild("PlayStealthAnimation")
local rigTemplate = ReplicatedStorage:WaitForChild("StealthRigTemplate")
local fedoraTemplate = ReplicatedStorage:WaitForChild("Black Fedora") -- Place your hat model/accessory here!

local PLAYER_ANIM_ID = "rbxassetid://75622876246022"
local NPC_ANIM_ID = "rbxassetid://125821338722605"

local playerAnimObj = Instance.new("Animation")
playerAnimObj.AnimationId = PLAYER_ANIM_ID

local npcAnimObj = Instance.new("Animation")
npcAnimObj.AnimationId = NPC_ANIM_ID

local systemClones = {}

local function findTorso(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChild("Torso")
end

local function ragdollCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.RequiresNeck = false
	humanoid:ChangeState(Enum.HumanoidStateType.Dead)

	local torso = findTorso(character)
	if torso then
		torso.Anchored = false
		local attachment = Instance.new("Attachment", torso)

		local velocity = Instance.new("LinearVelocity")
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.VectorVelocity = torso.CFrame.LookVector * PUSH_FORCE
		velocity.MaxForce = math.huge
		velocity.Parent = torso

		Debris:AddItem(velocity, 0.2)
		Debris:AddItem(attachment, 0.2)
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			local socket = Instance.new("BallSocketConstraint")
			local a0 = Instance.new("Attachment", descendant.Part0)
			local a1 = Instance.new("Attachment", descendant.Part1)

			a0.CFrame = descendant.C0
			a1.CFrame = descendant.C1
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			socket.Parent = descendant.Parent

			descendant:Destroy()
		end
	end
end

local function stripCollisions(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
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
		if item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
			pcall(function() item:Clone().Parent = targetRig end)
		elseif item:IsA("Part") or item:IsA("MeshPart") then
			local targetPart = targetRig:FindFirstChild(item.Name)
			if targetPart and targetPart:IsA("BasePart") then
				targetPart.Color = item.Color
			end
		end
	end
end

local function attachFixedHat(targetRig)
	local targetHead = targetRig:FindFirstChild("Head")
	if not targetHead or not fedoraTemplate then return end

	local hatClone = fedoraTemplate:Clone()
	local handle = hatClone:FindFirstChild("Handle") or hatClone:FindFirstChildOfClass("BasePart")
	
	if handle then
		hatClone.Parent = targetRig
		handle.CanCollide = false
		handle.Anchored = false
		handle.CFrame = targetHead.CFrame * CFrame.new(0, 0.45, -0.05)

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = targetHead
		weld.Parent = handle
	end
end

local function setCharacterTransparency(character, transparency)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = transparency
		elseif part:IsA("Decal") then
			part.Transparency = opacity
		elseif part:IsA("Accessory") then
			local handle = part:FindFirstChild("Handle") or part:FindFirstChildOfClass("BasePart")
			if handle then handle.Transparency = transparency end
		end
	end
end

local function setupNPC(npc)
	if not npc:IsA("Model") or npc == rigTemplate or systemClones[npc] or npc.Name == "StealthClone" then return end
	
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local torso = findTorso(npc)
	if not torso then return end

	local prompt = torso:FindFirstChild("StealthPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StealthPrompt"
		prompt.ActionText = "Knock Out"
		prompt.ObjectText = npc.Name
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = MAX_DISTANCE
		prompt.Enabled = false
		prompt.Parent = torso
	end

	prompt.Triggered:Connect(function(player)
		if humanoid.Health <= 0 or npc:GetAttribute("BeingTakenDown") then return end
		
		npc:SetAttribute("BeingTakenDown", true)

		local character = player.Character
		if not character then return end

		local playerHumanoid = character:FindFirstChildOfClass("Humanoid")
		local playerRoot = findTorso(character)
		if not playerHumanoid or not playerRoot then return end

		prompt.Enabled = false

		-- 🔒 ANCHOR REAL NPC INSTANTLY
		local npcRoot = findTorso(npc)
		if npcRoot then npcRoot.Anchored = true end

		-- POSITION PLAYER BEHIND NPC
		local behindPosition = torso.Position - torso.CFrame.LookVector * 2
		local targetCFrame = CFrame.new(behindPosition, torso.Position)
		character:PivotTo(targetCFrame)

		-- FREEZE AND HIDE REAL PLAYER
		playerHumanoid.WalkSpeed = 0
		playerHumanoid.JumpPower = 0
		playerHumanoid.AutoRotate = false
		playerRoot.Anchored = true
		setCharacterTransparency(character, 1)

		-- CREATE CINEMATIC CLONE RIG
		local cloneRig = rigTemplate:Clone()
		cloneRig.Name = "StealthClone"
		systemClones[cloneRig] = true
		
		cloneAppearance(character, cloneRig)
		attachFixedHat(cloneRig) 
		stripCollisions(cloneRig)
		
		local cloneRoot = findTorso(cloneRig)
		if cloneRoot then
			cloneRoot.Anchored = true
		end

		cloneRig.Parent = workspace
		cloneRig.Name = "StealthClone"
		
		if cloneRoot then
			cloneRoot.CFrame = playerRoot.CFrame
		else
			cloneRig:PivotTo(playerRoot.CFrame)
		end
		stripCollisions(cloneRig)
		
		local cloneHumanoid = cloneRig:FindFirstChildOfClass("Humanoid")
		local cloneAnimator = cloneHumanoid and (cloneHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", cloneHumanoid))
		local npcAnimator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

		-- LOAD AND PLAY ANIMATIONS
		if cloneAnimator then
			local playerTrack = cloneAnimator:LoadAnimation(playerAnimObj)
			playerTrack.Priority = Enum.AnimationPriority.Action
			playerTrack:Play()
		end

		if npcAnimator then
			local npcTrack = npcAnimator:LoadAnimation(npcAnimObj)
			npcTrack.Priority = Enum.AnimationPriority.Action
			npcTrack:Play()
		end

		remote:FireClient(player)

		task.wait(ANIMATION_TIME)

		-- RESTORE REAL PLAYER
		if playerRoot and playerHumanoid then
			playerRoot.Anchored = false
			playerHumanoid.WalkSpeed = 16
			playerHumanoid.JumpPower = 50
			playerHumanoid.AutoRotate = true
			setCharacterTransparency(character, 0)
		end

		-- ✅ VAPORIZE ENTIRE MODEL TREE OUT OF WORKSPACE
		systemClones[cloneRig] = nil
		if cloneRig then
			pcall(function()
				cloneRig.Parent = nil
				cloneRig:Destroy()
			end)
		end

		-- KILL AND RAGDOLL TARGET NPC
		if humanoid and npc then
			humanoid.Health = 0
			ragdollCharacter(npc)
		end
		
		if prompt then pcall(function() prompt:Destroy() end) end
	end)
end

-- FALLBACK GARBAGE REMOVER FOR WORKSPACE STUCK CLONES
workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and (child.Name == "StealthClone" or systemClones[child]) then
		task.delay(ANIMATION_TIME + 0.05, function()
			if child then
				pcall(function()
					child.Parent = nil
					child:Destroy()
				end)
			end
		end)
	else
		buildPrompt(child)
	end
end)

for _, child in ipairs(workspace:GetChildren()) do
	setupNPC(child)
end

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end

		local playerRoot = findTorso(character)
		if not playerRoot then continue end

		for _, npc in ipairs(workspace:GetChildren()) do
			if npc == character or systemClones[npc] or npc.Name == "StealthClone" then continue end

			local humanoid = npc:FindFirstChildOfClass("Humanoid")
			local torso = findTorso(npc)
			
			if humanoid and torso and humanoid.Health > 0 and not npc:GetAttribute("BeingTakenDown") then
				local prompt = torso:FindFirstChild("StealthPrompt")
				if prompt and prompt:IsA("ProximityPrompt") then
					local distance = (playerRoot.Position - torso.Position).Magnitude

					if distance <= MAX_DISTANCE then
						local npcLook = torso.CFrame.LookVector
						local directionToPlayer = (playerRoot.Position - torso.Position).Unit
						local dot = npcLook:Dot(directionToPlayer)

						if dot < -STEALTH_ANGLE then
							prompt.Enabled = true
						else
							prompt.Enabled = false
						end
					else
						prompt.Enabled = false
					end
				end
			end
		end
	end
end)