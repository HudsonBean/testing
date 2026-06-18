local jecs = require(script.Parent.Parent:FindFirstChild('Packages'):FindFirstChild('jecs'))
local planck = require(script.Parent.Parent:FindFirstChild('Packages'):FindFirstChild('planck'))
local planckJabby = require(script.Parent.Parent:FindFirstChild('Packages'):FindFirstChild('planck-jabby'))
local planckRunService = require(script.Parent.Parent:FindFirstChild('Packages'):FindFirstChild('planck-runservice'))

local world = require(script.Parent:FindFirstChild('world'))
local state = {}

return planck.Scheduler
		.new(world, state)
		:addPlugin(planckJabby.new())
		:addPlugin(planckRunService.Plugin.new()) :: planck.Scheduler<jecs.World, { any }>
