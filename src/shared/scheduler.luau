local jecs = require("@Packages/jecs")
local planck = require("@Packages/planck")
local planckJabby = require("@Packages/planck-jabby")
local planckRunService = require("@Packages/planck-runservice")

local world = require("@Shared/world")
local state = {}

return planck.Scheduler
		.new(world, state)
		:addPlugin(planckJabby.new())
		:addPlugin(planckRunService.Plugin.new()) :: planck.Scheduler<jecs.World, { any }>
