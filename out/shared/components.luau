local add_names = require(script.Parent:FindFirstChild('utils'):FindFirstChild('ecs'):FindFirstChild('add_names'))
local add_shared = require(script.Parent:FindFirstChild('utils'):FindFirstChild('ecs'):FindFirstChild('add_shared'))
local jecs = require(script.Parent.Parent:FindFirstChild('Packages'):FindFirstChild('jecs'))
local ref = require(script.Parent:FindFirstChild('utils'):FindFirstChild('ecs'):FindFirstChild('ref'))
local replecs = require(script.Parent.Parent:FindFirstChild('Packages'):FindFirstChild('replecs'))
local world = require(script.Parent:FindFirstChild('world'))

local components = {
	player = world:component() :: jecs.Entity<Player>,
	client = world:entity(),
	cleanup = world:component() :: jecs.Entity<(jecs.Entity<any>) -> ()>,

	health = world:component() :: jecs.Entity<number>,
}

-- Consistent player mapping
world:set(components.player, replecs.custom_handler, function(player: Player)
	local entity = ref(player)
	return entity
end)

-- Setup cleanup callback
world:removed(components.cleanup, function(entity: jecs.Entity<any>)
	local callback = world:get(entity, components.cleanup)

	if callback then
		callback(entity)
	end
end)

add_names(components)
add_shared(components)

return components
