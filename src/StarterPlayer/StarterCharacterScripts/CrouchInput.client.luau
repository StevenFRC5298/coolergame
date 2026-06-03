local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local toggleCrouchRemote = ReplicatedStorage:WaitForChild("ToggleCrouchState")

local Crouching = false
local Debounce = false

print("⌨️ INPUT SCRIPT: Listening for 'C' key...")

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.C then
		if Debounce then return end
		Debounce = true

		Crouching = not Crouching

		-- Strictly update the state attribute and tell the server
		char:SetAttribute("IsCrouching", Crouching)
		toggleCrouchRemote:FireServer(Crouching)

		print("⌨️ INPUT SCRIPT: Toggled state to ->", Crouching)

		task.wait(0.3)
		Debounce = false
	end
end)