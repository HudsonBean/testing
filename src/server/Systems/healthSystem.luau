local c = require("@Shared/components")
local planckRunService = require("@Packages/planck-runservice")
local world = require("@Shared/world")

local function healthSystem()
	for entity, health: c.HealthInterface in world:query(c.health) do
		if world:has(entity, c.dead) then
			continue
		end

		if world:has(entity, c.damage) then
			local damage = world:get(entity, c.damage) :: c.DamageInterface
			health.health = math.max(0, health.health - damage.damage)
			world:set(entity, c.health, health)
			world:remove(entity, c.damage)
		end

		if health.health > health.max_health then -- TODO: Maybe add an overheal feature
			health.health = health.max_health
			world:set(entity, c.health, health)
		end
	end
end

return {
	name = "healthSystem",
	system = healthSystem,
	phase = planckRunService.Phases.PostUpdate,
	runConditions = {},
}
