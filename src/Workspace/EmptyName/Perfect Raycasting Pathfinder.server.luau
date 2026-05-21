-- 25/7/2019: this makes the npc wanders around when no one's around and will chase if somebody is in it's range (using smart randomness, i mean AI) --
-- 27/7/2019: optimized so that the npc won't get stuck and get a script timeout --
hum = script.Parent:FindFirstChildWhichIsA('Humanoid')
root = script.Parent:FindFirstChild('HumanoidRootPart') or script.Parent:FindFirstChild('Torso')

chaseDist = 150

function getNearestTorso(list)
	local minDist = 150 -- doesn't matter, as long as it's a big number
	local minTor = nil
	for i,tor in pairs(list) do
		if (root.Position - tor.Position).Magnitude < minDist then
			minTor = tor
			minDist = (root.Position - tor.Position).Magnitude
		end
	end
	return minTor, minTor.Parent:FindFirstChild('Humanoid')
end

function torsosInRange()
	local foundTorsos = {}
	for i,plr in pairs(game.Players:GetPlayers()) do
		if plr.Character then
			local tor = plr.Character:FindFirstChild("HumanoidRootPart")
			if tor then
				local ignorelist = {script.Parent}
				
				for na,ni in pairs(plr.Character:GetDescendants()) do
					if ni.Parent:IsA("Accoutrement") or ni.Parent:IsA("Tool") then
						table.insert(ignorelist, ni)
					end
				end
				
				local searchray = Ray.new(root.Position, CFrame.new(root.Position, tor.Position).LookVector * chaseDist)
				local hit,pos = workspace:FindPartOnRayWithIgnoreList(searchray, ignorelist)
				
			local pp = Instance.new('Part')
			pp.BrickColor = BrickColor.Red()
				pp.Anchored = true
				pp.CanCollide = false				pp.Size = Vector3.new(.2,.2, (root.Position - pos).Magnitude)
			pp.CFrame = CFrame.new((root.Position + pos) / 2, pos)
				pp.Parent = script.Parent
			game.Debris:AddItem(pp,.5)
				
				if hit then
					if hit.Parent == plr.Character then
						local hu = plr.Character:FindFirstChild('Humanoid')
						if hu then
							if hu.Health > 0 then
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

while hum.Health > 0 do
	local foundTorsos = torsosInRange()
	
	if #foundTorsos > 0 then
		-- IF MONSTER SPOTS PLAYERS NEARBY (can be 1 or many) --
		local dator, dahum = getNearestTorso(foundTorsos)
		
		while dator.Parent ~= nil and dahum.Parent ~= nil do -- checking the parent is better than checking the object only
			--== So 3 situations can happen ==--
			-- 1. If the ray can reach the player (in which newtor ~= nil) then chase them like normally
			-- 2. If the ray cannot reach the player then wait until the the distance between the 2 gets over [25 STUDS] then stops chasing (aka lost track)
			-- 3. If the ray reached DIFFERENT player (intervening) then stop following the current player (and possible follow the new one too)
				
			foundTorsos = torsosInRange()
			
			if #foundTorsos > 0 then
				local newtor, newhum = getNearestTorso(foundTorsos)
					
				if newtor and newhum then -- SITUATION 1
					if newtor == dator then
						if dahum.Health > 0 then
							print'chasing straight'
							hum:MoveTo(dator.Position + CFrame.new(root.Position, dator.Position).LookVector * 6)
						else
							break -- if player dies then break
						end
					else -- SITUATION 3
						break
					end
				else
					-- happens when the torso found is not a real torso, which is IMPOSSIBLE
				end
			else -- SITUATION 2
				if (root.Position - dator.Position).Magnitude >= 25 or dahum.Health <= 0 then
					break
				end	
				hum:MoveTo(dator.Position)
				print'chasing bend'	
			end
			wait(.1)
		end
	else
		-- IF NO ONE IS NEARBY --
		while #torsosInRange() == 0 do -- keep searching for a reasonable distance to travel
			local wanderAngle, wanderRay, hit, pos
			local failAngles = Instance.new("Model") -- lmao using model and findfirstchild() is much faster!
			
			-- get the wanderangle, and cast ray from that angle, if the path is reasonable then stop
			-- if tried all 361 wanderangles and none of them work, then cast the last ray and break
			while hum.Health > 0 do
				repeat -- 2 loops is the key!
					wanderAngle = Instance.new('NumberValue', failAngles)
					wanderAngle.Name = math.random(-180,180)
					if failAngles:FindFirstChild(wanderAngle.Name) then
						wanderAngle:Destroy()
					end
				until not failAngles:FindFirstChild(wanderAngle.Name) -- make sure to not repeat that fail angle
				
				
				wanderRay = Ray.new(root.Position, (root.CFrame * CFrame.Angles(0, math.rad(wanderAngle.Name), 0)).LookVector * chaseDist )
				hit,pos = workspace:FindPartOnRay(wanderRay, script.Parent)

				if pos then
					if (root.Position - pos).Magnitude >= 20 then
						break
					else
						wanderAngle:Clone().Parent = failAngles
					end
				end
				
				if #failAngles:GetChildren() >= 361 then
					break
				end
			end
				
--			local pp = Instance.new('Part')
--			pp.Anchored = true
--			pp.CanCollide = false
--			pp.BrickColor = BrickColor.Blue()
--			pp.Size = Vector3.new(.2,.2, (root.Position - pos).Magnitude)
--			pp.CFrame = CFrame.new((root.Position + pos) / 2, pos)
--			pp.Parent = script.Parent
--			game.Debris:AddItem(pp,.5)
			
			if (root.Position - pos).Magnitude >= 20 then
				print'found reasonable path'
			elseif #failAngles:GetChildren() >= 361 then
				print'no reasonable path'
			end
			
			
			-- if doesnt matter if the path is reasonable or not, the code below will just move the monster to that position
			hum:MoveTo(pos)
			local wtime = 0
			repeat
				wtime = wtime + wait(.1)
			until (root.Position - pos).Magnitude <= 8 or #torsosInRange() > 0 or wtime >= 4
			
			
		end 
				
	end
	
	wait(.1)
end