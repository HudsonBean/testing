local ServerScriptService = game:GetService("ServerScriptService")

local net = require("@Server/Networking/server")
local scheduler = require("@Shared/scheduler")
local replicator = require("@Shared/replicator").server
local bootstrapPrefabs = require("@Shared/utils/bootstrapPrefabs")
local c = require("@Shared/components")
local jabby = require("@Packages/jabby")
local players = require("@Shared/players")
local spawnPlayer = require("@Server/Prefabs/player")
local world = require("@Shared/world")

bootstrapPrefabs(ServerScriptService:WaitForChild("Server"))

replicator:init()

net.ReceiveFull.On(function(player)
	if replicator:is_player_ready(player) then
		return nil, nil
	end

	replicator:mark_player_ready(player)
	return replicator:get_full(player)
end)

-- Update:    timers → fire delays; damage → write c.damage on victims
-- PostUpdate: health → apply damage + regen; death → tag c.dead; respawn → revive c.dead; replecs → replicate
local systemsOrder = {
	require("@Shared/Systems/timers"),
	require("@Server/Systems/damageSystem"),
	require("@Server/Systems/healthSystem"),
	require("@Server/Systems/deathSystem"),
	require("@Server/Systems/respawnSystem"),
	require("@Server/Systems/replecsServer"),
}

scheduler:addSystems(systemsOrder)

jabby.register({
	name = "Server",
	applet = jabby.applets.world,
	configuration = { world = world :: any },
})

local playerSetup = world:entity()
world:set(playerSetup, c.player_setup, function(player: Player, _entity)
	spawnPlayer(player)
end)

players.start_current_players()
players.listen_for_players()
