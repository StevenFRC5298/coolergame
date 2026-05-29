local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

-- CONFIGURATION
local CAMERA_HEIGHT = 15     -- How high above the player the camera sits
local CAMERA_RADIUS = 10     -- How far back from the player the camera pulls
local ROTATION_SPEED = 1.5   -- Speed multiplier for the camera rotation

local currentAngle = 0       -- The only angle allowed to change (in radians)

local function onFrame(deltaTime)
	if not root then return end

	-- Force camera type to Scriptable so Roblox default scripts don't override it
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- Check if Left or Right arrow keys are actively being held down
	if UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		currentAngle = currentAngle + (ROTATION_SPEED * deltaTime)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		currentAngle = currentAngle - (ROTATION_SPEED * deltaTime)
	end

	-- Calculate the X and Z offsets using our locked orbital math
	local offsetX = math.sin(currentAngle) * CAMERA_RADIUS
	local offsetZ = math.cos(currentAngle) * CAMERA_RADIUS

	-- Combine offsets relative to the player's position
	local cameraPosition = root.Position + Vector3.new(offsetX, CAMERA_HEIGHT, offsetZ)

	-- Positioned at cameraPosition, looking directly at the player's root
	camera.CFrame = CFrame.new(cameraPosition, root.Position)
end

-- RenderStep binding (priority 200 matches standard Roblox camera priorities)
RunService:BindToRenderStep("TopDownCamera", Enum.RenderPriority.Camera.Value, onFrame)