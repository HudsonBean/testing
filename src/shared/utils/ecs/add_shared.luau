local replecs = require("@Packages/replecs")
local world = require("@Shared/world")

function add_shared<T>(entities: T, skip: { [string]: boolean }?): T
	for name, entity in pairs(entities :: any) do
		if skip and skip[name] then
			continue
		end

		world:add(entity, replecs.shared)
	end

	return entities
end

return add_shared
