local ProximityPromptService = game:GetService("ProximityPromptService")
local planckRunService = require("@Packages/planck-runservice")

local function interactionSystemServer() end

return {
	name = "interactionSystemServer",
	system = interactionSystemServer,
	phase = planckRunService.Phases.Update,
	runConditions = {},
}
