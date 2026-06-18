local Jecs = require("@Packages/jecs")
local world = require("@Shared/world")

function add_names<T>(entities: T): T
	for name, entity in pairs(entities :: any) do
		world:set(entity, Jecs.Name, name)
	end
	return entities
end

return add_names
