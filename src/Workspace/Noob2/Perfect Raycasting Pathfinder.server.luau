-- 25/7/2019: Wanders when calm, chases when a player is spotted in front
hum = script.Parent:FindFirstChildWhichIsA('Humanoid')
root = script.Parent:FindFirstChild('HumanoidRootPart') or script.Parent:FindFirstChild('Torso')

chaseDist = 150
fovAngle = 60 -- Field of view angle (60 degrees left, 60 degrees right)

function getNearestTorso(list)
	local minDist = 150
	local minTor = nil
	for i,tor in pairs(list) do
		if (root.Position - tor.Position).Magnitude < minDist then
			minTor = tor
			minDist = (root.Position - tor.Position).Magnitude
		end
	end
	return minTor
end

function torsosInRange()
	local foundTorsos = {}
	for i,plr in pairs(game.Players:GetPlayers()) do
		if plr.Character then
			local tor = plr.Character:FindFirstChild("HumanoidRootPart")
			if tor then
				-- Check if the player is in front of the NPC using Dot Product
				local npcForward = root.CFrame.LookVector
				local directionToPlayer = (tor.Position - root.Position).Unit
				local angle = math.acos(npcForward:Dot(directionToPlayer))
				local angleDegrees = math.deg(angle)

				-- Only raycast if player is in the front vision cone
				if angleDegrees <= fovAngle then
					local ignorelist = {script.Parent}

					for na,ni in pairs(plr.Character:GetDescendants()) do
						if ni.Parent:IsA("Accoutrement") or ni.Parent:IsA("Tool") then
							table.insert(ignorelist, ni)
						end
					end

					local raycastParams = RaycastParams.new()
					raycastParams.FilterType = Enum.RaycastFilterType.Exclude
					raycastParams.FilterDescendantsInstances = ignorelist

					local rayDirection = directionToPlayer * chaseDist
					local raycastResult = workspace:Raycast(root.Position, rayDirection, raycastParams)

					local hit = raycastResult and raycastResult.Instance
					local pos = raycastResult and raycastResult.Position or (root.Position + rayDirection)

					if hit then
						if hit.Parent == plr.Character or hit:IsDescendantOf(plr.Character) then
							local hu = plr.Character:FindFirstChild('Humanoid')
							if hu and hu.Health > 0 then
								table.insert(foundTorsos, tor)
							end
						end
					end
				end
			end
		end
	end
	return foundTorsos
end

-- NEW: Main AI loop to control physical movement
while task.wait(0.1) do
	if hum and hum.Health > 0 and root then
		local targets = torsosInRange()
		local closestTarget = getNearestTorso(targets)

		if closestTarget then
			-- CHASE: Move directly toward the spotted player
			hum:MoveTo(closestTarget.Position)
		else
			-- WANDER: Move to a smart random spot nearby if no one is seen
			if hum.WalkToPoint == Vector3.new(0,0,0) or (root.Position - hum.WalkToPoint).Magnitude < 4 then
				local randomOffset = Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
				hum:MoveTo(root.Position + randomOffset)
			end
		end
	end
end
