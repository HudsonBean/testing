local replecs
local scheduler = require(game:GetService('ReplicatedStorage'):FindFirstChild('Shared'):FindFirstChild('scheduler'))

local systemsOrder = {
	require(script:FindFirstChild('Systems'):FindFirstChild('healthSystem')),
}

scheduler:addSystems(systemsOrder)
