local c = require("@Shared/components")
local jecs = require("@Packages/jecs")
local planckRunService = require("@Packages/planck-runservice")
local scheduleDelay = require("@Shared/utils/scheduleDelay")
local world = require("@Shared/world")

local q_health = world:query(c.health):cached()
local regenTimers: { [jecs.Entity<any>]: jecs.Entity<any> } = {}

local function cancelRegenTimer(entity: jecs.Entity<any>)
	local existing = regenTimers[entity]
	if existing and world:contains(existing) then
		world:delete(existing)
	end
	regenTimers[entity] = nil
end

local function cleanupStaleRegenTimers()
	for entity in regenTimers do
		if not world:contains(entity) or world:has(entity, c.dead) or not world:has(entity, c.health) then
			cancelRegenTimer(entity)
		end
	end
end

local function healthSystem()
	cleanupStaleRegenTimers()

	for entity, health: c.HealthInterface in q_health:iter() do
		if world:has(entity, c.dead) then
			continue
		end

		local health_changed = false

		if world:has(entity, c.damage) then
			local damage = world:get(entity, c.damage) :: c.DamageInterface
			health.health = math.max(0, health.health - damage.damage)
			world:remove(entity, c.damage)
			health_changed = true

			cancelRegenTimer(entity)
			regenTimers[entity] = scheduleDelay(health.regen_delay, function()
				regenTimers[entity] = nil

				if not world:contains(entity) or not world:has(entity, c.health) then
					return
				end

				local current = world:get(entity, c.health) :: c.HealthInterface
				current.health = math.min(
					current.health + current.regen * current.regen_multiplier,
					current.max_health
				)
				world:set(entity, c.health, current)
			end)
		end

		if health.health > health.max_health then -- TODO: Maybe add an overheal feature
			health.health = health.max_health
			health_changed = true
		end

		if health_changed then
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
