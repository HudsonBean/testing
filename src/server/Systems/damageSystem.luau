local Players = game:GetService("Players")

local c = require("@Shared/components")
local jecs = require("@Packages/jecs")
local planckRunService = require("@Packages/planck-runservice")
local ref = require("@Shared/utils/ecs/ref")
local world = require("@Shared/world")

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local lastHit: { [jecs.Entity<any>]: { [jecs.Entity<any>]: number } } = {}

local function getPlayerEntityFromPart(part: BasePart): jecs.Entity<any>?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end

	if not model:FindFirstChildOfClass("Humanoid") then
		return nil
	end

	local player = Players:GetPlayerFromCharacter(model)
	if not player then
		return nil
	end

	return ref.search(player)
end

local function damageSystem()
	local now = os.clock()

	for sourceEntity, source: c.DamageSourceInterface in world:query(c.damage_source) do
		local hitbox = source.instance
		if not hitbox or not hitbox.Parent then
			continue
		end

		overlapParams.FilterDescendantsInstances = { hitbox }

		for _, part in workspace:GetPartsInPart(hitbox, overlapParams) do
			local victimEntity = getPlayerEntityFromPart(part)
			if not victimEntity then
				continue
			end
			if not world:has(victimEntity, c.health) then
				continue
			end
			if world:has(victimEntity, c.dead) then
				continue
			end

			local sourceHits = lastHit[sourceEntity]
			local last = sourceHits and sourceHits[victimEntity]
			if last and now - last < source.delay then
				continue
			end

			if not sourceHits then
				sourceHits = {}
				lastHit[sourceEntity] = sourceHits
			end
			sourceHits[victimEntity] = now

			world:set(victimEntity, c.damage, {
				damage = source.damage,
				source = sourceEntity,
			})
		end
	end
end

return {
	name = "damageSystem",
	system = damageSystem,
	phase = planckRunService.Phases.Update,
	runConditions = {},
}
