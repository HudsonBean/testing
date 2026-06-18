local replicator = require(game:GetService('ReplicatedStorage'):FindFirstChild('Shared'):FindFirstChild('replicator')).server
local interval = require(game:GetService('ReplicatedStorage'):FindFirstChild('Shared'):FindFirstChild('utils'):FindFirstChild('interval'))
local net = require(script.Parent.Parent:FindFirstChild('Networking'):FindFirstChild('server'))
local planckRunService = require(game:GetService('ReplicatedStorage'):FindFirstChild('Packages'):FindFirstChild('planck-runservice'))

local updates_interval = interval(1 / 20)
local unreliable_interval = interval(1 / 30)

function replecsServer()
	if updates_interval() then
		for player, buf, variants in replicator:collect_updates() do
			net.SendUpdates.Fire(player, buf, variants)
		end
	end
	if unreliable_interval() then
		for player, buf, variants in replicator:collect_unreliable() do
			net.SendUnreliables.Fire(player, buf, variants)
		end
	end
end

return {
	name = "replecsServer",
	system = replecsServer,
	phase = planckRunService.Phases.PostUpdate,
	runConditions = {},
}
