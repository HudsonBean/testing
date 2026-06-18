local c = require("@Shared/components")
local jecs = require("@Packages/jecs")
local planckRunService = require("@Packages/planck-runservice")
local world = require("@Shared/world")

local function getEntityName(entity: jecs.Entity<any>): string
	local player = world:get(entity, c.player)
	if player then
		return player.Name
	end

	local damageSource = world:get(entity, c.damage_source)
	if damageSource then
		return damageSource.instance.Name
	end

	return tostring(entity)
end

local function healthSystem()
	for entity, health: c.HealthInterface in world:query(c.health) do
		if world:has(entity, c.damage) then -- If the entity has damage, consume it
			local damage = world:get(entity, c.damage) :: c.DamageInterface
			health.health = health.health - damage.damage
			world:set(entity, c.health, health)
			world:remove(entity, c.damage)
			print(
				getEntityName(entity)
					.. " took "
					.. damage.damage
					.. " damage from "
					.. getEntityName(damage.source)
					.. " and has "
					.. health.health
					.. " health remaining"
			)
		end
		if health.health <= 0 then -- If health drops below 0, the entity is dead
			world:add(entity, c.dead)
			print(getEntityName(entity) .. " is dead")
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
