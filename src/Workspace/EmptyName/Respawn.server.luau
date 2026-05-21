local Model = script.Parent
local Backup = Model:clone()

function onDied()
	local Parent = Model.Parent
	wait(0.5)
	script.Parent = game.Workspace
	Model:remove()
	wait(2)
	Backup.Parent = Parent
	Backup:makeJoints()
	script:remove()
end

script.Parent.Humanoid.Died:connect(onDied)