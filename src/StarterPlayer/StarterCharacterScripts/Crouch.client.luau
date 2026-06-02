local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local UIS = game:GetService("UserInputService")
local Debounce = false
local Crouching = false
local Idle = hum:WaitForChild("Animator"):LoadAnimation(script:WaitForChild("Idle"))
local Move = hum:WaitForChild("Animator"):LoadAnimation(script:WaitForChild("Move"))

UIS.InputBegan:Connect(function(I,S)
	if not S then
		if not Debounce then
			if I.KeyCode == Enum.KeyCode.C then
				Debounce = true
				Crouching = not Crouching
				wait()
				if Crouching then
					hum.WalkSpeed /= 2 --CROUCHSPEED, REGULAR WALKSPEED IS 16. THIS DIVIDES IT BY 2
				else
					hum.WalkSpeed *= 2--WALKSPEED, REGULAR WALKSPEED IS 16. THIS MULTIPLIES THE CROUCHSPEED BY 2
				end
				wait(0.5)
				Debounce = false
			end
		end
	end
end)

while true do --DONT CHANGE THIS
	wait()
	if Crouching then
		if hum.MoveDirection ~= Vector3.new(0,0,0) then
			print("Moving")
			Idle:Stop()
			Move:Play()
			repeat
				wait()
			until
			hum.MoveDirection == Vector3.new(0,0,0) or not Crouching
		else
			print("Idle")
			Idle:Play()
			Move:Play()
		end
	else
		Idle:Stop()
		Move:Stop()
	end
end