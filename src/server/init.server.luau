local net = require("@Server/Networking/server")
local scheduler = require("@Shared/scheduler")
local replicator = require("@Shared/replicator").server
local jabby = require("@Packages/jabby")
local c = require("@Shared/components")
local players = require("@Shared/players")
local spawnCharacter = require("@Server/Prefabs/character")
local world = require("@Shared/world")

-- Replecs: start replication and answer full-state requests
replicator:init()

net.ReceiveFull.On(function(player)
	if replicator:is_player_ready(player) then
		return nil, nil
	end

	replicator:mark_player_ready(player)
	return replicator:get_full(player)
end)

-- Planck: schedule systems
local systemsOrder = {
	require("@Server/Systems/replecsServer"),
	require("@Shared/Systems/timers"), -- Starts the player unix timer
	require("@Server/Systems/healthSystem"),
}

scheduler:addSystems(systemsOrder)

-- Jabby: expose the server world to the debugger
jabby.register({
	name = "Server",
	applet = jabby.applets.world,
	configuration = { world = world :: any },
})

-- Initial character spawn on join (move to respawnSystem later)
local characterSetup = world:entity()
world:set(characterSetup, c.player_setup, function(player: Player, _entity)
	spawnCharacter(player)
end)

-- Bootstrap players (after everything else is ready)
players.start_current_players()
players.listen_for_players()
