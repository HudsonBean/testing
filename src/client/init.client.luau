-- Client

local jecs = require(game.ReplicatedStorage.Shared.Packages.jecs)
local createScheduler = require(game.ReplicatedStorage.Shared.createScheduler)

local world = jecs.world()
local state = {}
local scheduler = createScheduler(world, state) -- Already has plugins injected

local systemsOrder = {
	require(game.ReplicatedStorage.Shared.Systems.HealthSystem),
}
scheduler:addSystems(systemsOrder)
