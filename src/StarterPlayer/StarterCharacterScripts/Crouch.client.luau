--READ ME ! ! ! !
--Made by skibidibopbopbop6/Danny. Hope the script helps as it was made by me and my friend.
--Comments will be left in the code so that it will be simpler to understand. Thanks for downloading!

local UserInputService = game:GetService("UserInputService")

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.C then
		-- Get the player's character and humanoid
		local player = game.Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			-- Change the humanoid's properties to make the character crouch
			humanoid.HipHeight = 0.5
			humanoid.WalkSpeed = 6 -- Slows down the player.

			-- Add more properties and actions as needed for crouching
		end
	end
end

local function onInputEnded(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.C then
		-- Get the player's character and humanoid
		local player = game.Players.LocalPlayer
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			-- Reset the humanoid's properties to stand up
			humanoid.HipHeight = 2
			humanoid.WalkSpeed = 12 -- Changes the speed back to normal (the walkspeed in my game is 12 so you can change it to your game's walkspeed).
			
			-- Reset other properties and actions as needed
		end
	end
end

-- Connect the input events
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

-- If you want to add some, you can add animations to add some life to your crouching.