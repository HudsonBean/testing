local replecs
local scheduler = require("@Shared/scheduler")

local systemsOrder = {
	require("@Server/Systems/healthSystem"),
}

scheduler:addSystems(systemsOrder)
