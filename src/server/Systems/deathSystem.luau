local c = require("@Shared/components")
local planckRunService = require("@Packages/planck-runservice")
local world = require("@Shared/world")

local function deathSystem()
	for entity, health: c.HealthInterface in world:query(c.health) do
		if health.health <= 0 and not world:has(entity, c.dead) then -- Marks entity dead if health is 0 or less
			world:add(entity, c.dead)
		end
		-- Remove the entity's character model if it is dead
		if world:has(entity, c.dead) and world:has(entity, c.character) then
			local character = world:get(entity, c.character)
			character:Destroy()
			world:remove(entity, c.character)
		end
	end
end

return {
	name = "deathSystem",
	system = deathSystem,
	phase = planckRunService.Phases.PostUpdate,
	runConditions = {},
}
