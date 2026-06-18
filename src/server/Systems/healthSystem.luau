local c = require("@Shared/components")
local planckRunService = require("@Packages/planck-runservice")
local world = require("@Shared/world")

local function healthSystem()
	for entity, health: c.HealthInterface in world:query(c.health) do
		if world:has(entity, c.damage) then -- If the entity has damage, consume it
			local damage = world:get(entity, c.damage) :: c.DamageInterface
			health.health = health.health - damage.damage
			world:set(entity, c.health, health)
			world:remove(entity, c.damage)
			print(
				entity.Name
					.. " took "
					.. damage.damage
					.. " damage from "
					.. damage.source.Name
					.. " and has "
					.. health.health
					.. " health remaining"
			)
		end
		if health.health <= 0 then -- If health drops below 0, the entity is dead
			world:add(entity, c.dead)
			print(entity.Name .. " is dead")
		end
		if health.health > health.max_health then -- If health exceeds max health, set it to max health
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
