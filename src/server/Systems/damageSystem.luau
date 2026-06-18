local c = require("@Shared/components")
local planckRunService = require("@Packages/planck-runservice")
local world = require("@Shared/world")

local function damageSystem()
	for entity, damage: number in world:query(c.damage) do
		if world:has(entity, c.health) then
			local health = world:get(entity, c.health) :: c.HealthInterface
			health.health = health.health - damage
			world:set(entity, c.health, health)
		end
	end
end

return {
	name = "damageSystem",
	system = damageSystem,
	phase = planckRunService.Phases.Update,
	runConditions = {},
}
