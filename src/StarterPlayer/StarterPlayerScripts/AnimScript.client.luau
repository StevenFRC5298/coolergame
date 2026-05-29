-- 📁 PLACE THIS INSIDE YOUR LOCAL ANIMATION SCRIPT
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local remote = ReplicatedStorage:WaitForChild("PlayStealthAnimation")
local player = Players.LocalPlayer

-- Create a reusable sound instance
local snapSound = Instance.new("Sound")
snapSound.Name = "StealthSnapSound"
snapSound.Volume = 1.0
snapSound.Parent = SoundService

-- Preload the sound asset so it's ready instantly
task.spawn(function()
	snapSound.SoundId = "rbxassetid://100876071652717"
	pcall(function()
		ContentProvider:PreloadAsync({snapSound})
		print("🔊 Stealth audio preloaded successfully")
	end)
end)

remote.OnClientEvent:Connect(function(soundId)

	task.wait(0.1)
	
	-- Fallback check if the ID changes
	if soundId and snapSound.SoundId ~= soundId then
		snapSound.SoundId = soundId
	end
	
	-- Stop it if it's somehow already playing, then play it fresh
	snapSound:Stop()
	snapSound:Play()
	
	print("🎬 Stealth audio played")
end)