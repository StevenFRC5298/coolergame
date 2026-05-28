--This is the most advanced combat AI script made by WilsonFactions.
--It has wandering, speech, combat scripting and self preservation functions
--All in one. Put this inside a character to make it work.

--Assets, lots of them.

--Gets NPC model
local Figure = script.Parent

--Gets Customization values (most can be found parented under this script,
--and are easily editable)

--Determines if the NPC will attempt to flee after taking too much damage
local Fear = script.HasFear.Value
--Determines if the NPC can use the chat service
local CanTalk = script.Talks.Value
--Determines if the NPC can hurt people
local CanHarm = script.Hostile.Value
--How far the NPC can see
local MaxDist = script.MaxDetectionDistance.Value
--How close the NPC must be to a target to start attacking
local AttackDist = script.AttackDistance.Value
--How low the NPC's health must be for it to start running away (only applies
--if fear is enabled)
local Tolerance = script.MinimalHealth.Value
--The NPC's chat bubble color (only applies if speech is enabled)
local ChatColor = Enum.ChatColor.White
--Services
local PathService = game:GetService("PathfindingService")
local ChatService = game:GetService("Chat")
--This will determine how long the NPC must wait between pathfinding waypoints
--Before moving on to the next, as humanoid.movetofinished is unreliable.
--By using this calculation, we are keeping the NPC in sync with its path
--According to its walkspeed.
local Calc = Figure.Humanoid.WalkSpeed/3.675
local TimePerStep = 1/Calc
--Values used when tracking a target
local Target = nil
local TargetVisible = false
local Distance = nil
local TargetID = nil
--A table of threats and allies. Allies will be ignored, while threats will
--Always be targeted. You can only have up to 5 allies.
local Allies = {}
local Threats = {}
--"Last known" values.
local LastKnownHP = Figure.Humanoid.Health
local LastKnownPos = nil
--A set of speech line tables. Only used if the NPC is allowed to talk.
local Spotlines = {"Got you!","I see you!","Come here!"}
local SearchLines = {"Come out!","You can't hide!","I'm going to catch you."}
local Complaints = {"Ow!","Stop please!","That hurts."}
local DeathLines = {"I'M DEAD!","Ahh!","NO!"}
local Victorylines = {"Welp.","They gone.","Haha."}
local Insults1 = {"You stinky, ","Everyone hates you, ","Just go die, "}
local Insults2 = {", You stink!",", You're the worst player.",", You suck!"}
local HelpCalls = {"I'M BEING OVERRUN","HELP ME!","NOPE"}
local Chats = {"I like ROBLOX","I want to hurt people","This game is nice"}
--Random permission value for cooldowns.
local Perm = true

--What to do when attacking a target.
function Attack(Object)
	if CanHarm == true then
		
	end
end

--Chatting function. Default cooldown is 0.5 and shouldn't be lower than that.
function Chat(Message)
	if Message ~= nil then
		if CanTalk == true then
			if Perm == true then
				ChatService:Chat(Figure.Head, Message, ChatColor)
				Perm = false
				wait(0.5)
				Perm = true
			end
		end
	end
end

--Pathfinding function which uses the calculation in the local assets.
function PathTo(Goal)
	local Path = PathService:FindPathAsync(Figure.HumanoidRootPart.Position, Goal)
	if Path.Status == Enum.PathStatus.Success then
		local Waypoints = Path:GetWaypoints()
		for _, Point in ipairs(Waypoints) do
			Figure.Humanoid:MoveTo(Point.Position)
			if Point.Action == Enum.PathWaypointAction.Jump then
				Figure.Humanoid.Jump = true
			end
			wait(TimePerStep)
		end
	end
end

--Causes the NPC to pathfind to an area away from a part.
function FleeFrom(Object)
	local Tables = {HelpCalls}
	local Table = Tables[math.random(#Tables)]
	local Msg = Table[math.random(#Table)]
	Chat(Msg)
	local Max = 75
	local randomZ = math.random(-Max,Max)
	local randomX = math.random(-Max,Max)
	local Goal = Object.Position - Vector3.new(randomX, 0, randomZ)
	PathTo(Goal)
end

--Makes the NPC chat and wander at random.
function Wander()
	local Chance = math.random(1,30)
	if Chance == 1 then
		local Max = 50
		local randomZ = math.random(-Max,Max)
		local randomX = math.random(-Max,Max)
		local Goal = Figure.HumanoidRootPart.Position - Vector3.new(randomX, 0, randomZ)
		PathTo(Goal)
	end
	if Chance == 2 then
		local Tables = {Chats}
		local Table = Tables[math.random(#Tables)]
		local Msg = Table[math.random(#Table)]
		Chat(Msg)
	end
end

--Causes the NPC to start targeting a part. This takes care of most of the AI's
--functionality.
function Track(Object)
	if Figure.Humanoid.Health > Tolerance then
		if TargetVisible == true then
			Figure.Humanoid:MoveTo(Object.Position)
			if Distance < AttackDist then
				Attack(Object)
			end
		else
			local Chance = math.random(1,30)
			if Chance == 1 then
				local Tables = {SearchLines}
				local Table = Tables[math.random(#Tables)]
				local Msg = Table[math.random(#Table)]
				Chat(Msg)
			end
			PathTo(Object.Position)
		end
	else
		if Fear == true then
			FleeFrom(Object)
		else
			if TargetVisible == true then
				Figure.Humanoid:MoveTo(Object.Position)
				if Distance < AttackDist then
					Attack(Object)
				end
			else
				PathTo(Object.Position)
			end
		end
	end
	if Target == nil then
		local Tables = {Spotlines}
		local Table = Tables[math.random(#Tables)]
		local Msg = Table[math.random(#Table)]
		Chat(Msg)
	end
	TargetID = Object.Parent.Name
	local Chance = math.random(1,45)
	if Chance == 1 then
		local Tables = {Insults1, Insults2}
		local Table = Tables[math.random(#Tables)]
		local Msg = Table[math.random(#Table)]
		if Table == Insults1 then
			Chat(Msg .. TargetID)
		else
			if Table == Insults2 then
				Chat(TargetID .. Msg)
			else
				Chat(Msg)
			end
		end
	end
	Target = Object
end

--Causes the AI to stop targeting something.
function Stop()	
	local Tables = {Victorylines}
	local Table = Tables[math.random(#Tables)]
	local Msg = Table[math.random(#Table)]
	Chat(Msg)
	Target = nil
	TargetVisible = false
	TargetID = nil
	Distance = nil
end

--Checks an object to make sure that:
--The NPC wont target itself
--The object's parent's name matches that of a name in the "Threats" table.
--(the npc will target everything except allies if there are no threat names listed.)
--The Object's parent's name doesn't match that of an ally.
--If the target matches this criteria, the AI will use the tracking function on the object.
function Check(Object)
	if Object.Parent.Name ~= Figure.Name then
		if Object.Parent:IsA("Model") then
			if Threats[1] ~= nil then
				for _, Name in pairs(Threats) do
					if Object.Parent.Name == Name then
						Track(Object)
					end
				end
			else
				if Object.Parent.Name ~= Allies[1] and Object.Parent.Name ~= Allies[2] and Object.Parent.Name ~= Allies[3] and Object.Parent.Name ~= Allies[4] and Object.Parent.Name ~= Allies[5] then
					Track(Object)
				end
			end
		end
	end
end

--Makes the NPC complain when harmed.
--This only works when the NPC is allowed to talk.
--It also shuts the AI down if the health is reduced to zero.
--To make sure the NPC doesn't complain about healing, the function
--will check if the health is lower than before using one of the local
--"last known" assets.
function Harmed()
	if Figure.Humanoid.Health < LastKnownHP and Figure.Humanoid.Health > Tolerance then
		if Figure.Humanoid.Health ~= 0 then
			local Tables = {Complaints}
			local Table = Tables[math.random(#Tables)]
			local Msg = Table[math.random(#Table)]
			Chat(Msg)
		else
			local Tables = {DeathLines}
			local Table = Tables[math.random(#Tables)]
			local Msg = Table[math.random(#Table)]
			Chat(Msg)
			wait(0.5)
			script.Disabled = true
		end
	end
	LastKnownHP = Figure.Humanoid.Health
end

--Connects healthchanged event.
Figure.Humanoid.HealthChanged:Connect(Harmed)

--This makes the AI tick. It checks the workspace for models containing humanoids,
--Finds required parts for targeting, and Checks them to make sure they're
--valid targets according to the "Allies" and "Threats" tables.
--if no targets are currently being tracked, the AI will use the 
--"Wander" function. It also won't target dead humanoids.
while wait(0.25) do
	for _, Model in pairs(workspace:GetChildren()) do
		if Model:IsA("Model") then
			local Human = Model:FindFirstChildOfClass("Humanoid")
			if Human then
				if Human.Health > 0 then
					local Head = Model:FindFirstChild("Head")
					if Head then
						if Head:IsA("Part") then
							Distance = (Figure.Head.Position - Head.Position).Magnitude
							if Distance < MaxDist then
								local CheckRay = Ray.new(Figure.Head.CFrame.Position, (Head.CFrame.Position - Figure.Head.CFrame.Position).unit * 10000)
								local Part = workspace:FindPartOnRay(CheckRay, Figure, false, true)
								if Part ~= nil then
									if Part.Parent == Head.Parent or Part.Parent.Parent == Head.Parent or Part.Parent.Parent.Parent == Head.Parent then
										TargetVisible = true
										Check(Head)
									else
										TargetVisible = false
									end
								end
							end
						end
					else
						local Head = Model:FindFirstChild("HumanoidRootPart")
						if Head then
							if Head:IsA("Part") then
								Distance = (Figure.Head.Position - Head.Position).Magnitude
								if Distance < MaxDist then
									local CheckRay = Ray.new(Figure.Head.CFrame.Position, (Head.CFrame.Position - Figure.Head.CFrame.Position).unit * 10000)
									local Part = workspace:FindPartOnRay(CheckRay, Figure, false, true)
									if Part ~= nil then
										if Part.Parent == Head.Parent or Part.Parent.Parent == Head.Parent or Part.Parent.Parent.Parent == Head.Parent then
											Check(Head)
											TargetVisible = true
										else
											TargetVisible = false
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if Target ~= nil then
		if Distance > MaxDist or Target.Parent.Humanoid.Health == 0 or Target == nil then
			Stop()
		else
			Track(Target)
		end
	else
		Wander()
	end
end

--Made by WilsonFactions.