local replecs = require(game:GetService('ReplicatedStorage'):FindFirstChild('Packages'):FindFirstChild('replecs'))
local world = require(script.Parent.Parent.Parent:FindFirstChild('world'))

function add_shared<T>(entities: T): T
	for name, entity in pairs(entities :: any) do
		world:add(entity, replecs.shared)
	end
	return entities
end

return add_shared
