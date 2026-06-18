local collect = require(game:GetService('ReplicatedStorage'):FindFirstChild('Shared'):FindFirstChild('utils'):FindFirstChild('collect'))
local replicator = require(game:GetService('ReplicatedStorage'):FindFirstChild('Shared'):FindFirstChild('replicator')).client
local net = require(script.Parent.Parent:FindFirstChild('Networking'):FindFirstChild('client'))
local planckRunService = require(game:GetService('ReplicatedStorage'):FindFirstChild('Packages'):FindFirstChild('planck-runservice'))

local reliable_updates = collect(function(listener)
	net.SendUpdates.On(listener)
end)
local unreliable_updates = collect(function(listener)
	net.SendUnreliables.On(listener)
end)

function replecsClient()
	for _, buf, variants in reliable_updates do
		replicator:apply_updates(buf, variants)
	end
	for _, buf, variants in unreliable_updates do
		replicator:apply_unreliable(buf, variants)
	end
end

return {
	name = "replecsClient",
	system = replecsClient,
	phase = planckRunService.Phases.PreUpdate,
	runConditions = {},
}
