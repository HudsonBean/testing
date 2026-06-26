--[[
	Client bootstrap: request replicated state, register systems, attach local player
	entities, and apply the initial world snapshot from the server.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local net = require("@Client/Networking/client")
local scheduler = require("@Shared/scheduler")
local replicator = require("@Shared/replicator").client
local c = require("@Shared/components")
local jabby = require("@Packages/jabby")
local world = require("@Shared/world")

local ref = c.ref

-- ---------------------------------------------------------------------------
-- Replication bootstrap — connect to server and receive initial full state
-- ---------------------------------------------------------------------------

replicator:init()
local buf, variants = net.ReceiveFull.Invoke(nil)

-- ---------------------------------------------------------------------------
-- Player ECS — join/leave hooks and local player entity setup
-- ---------------------------------------------------------------------------

local function setupPlayer(player: Player)
	local entity = ref(player)
	world:set(entity, c.player, player)

	for _, callback in world:query(c.player_setup):iter() do
		callback(player, entity)
	end
end

local function cleanupPlayer(player: Player)
	local entity = ref.search(player)
	if not entity then
		return
	end

	world:delete(entity)
	ref.unlist(player)
end

-- ---------------------------------------------------------------------------
-- ECS systems — Planck scheduler registration
-- ---------------------------------------------------------------------------

local systemsOrder = {
	require("@Client/Systems/interactionSystemClient"),
	require("@Client/Systems/replecsClient"),
}

scheduler:addSystems(systemsOrder)

-- ---------------------------------------------------------------------------
-- Debug tooling — Jabby world inspector (F4)
-- ---------------------------------------------------------------------------

local client = jabby.obtain_client()

jabby.register({
	name = "Client",
	applet = jabby.applets.world,
	configuration = { world = world :: any },
})

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F4 then
		client.spawn_app(client.apps.home)
	end
end)

-- ---------------------------------------------------------------------------
-- Boot — connect existing players, listen for join/leave, apply snapshot
-- ---------------------------------------------------------------------------

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

if buf then
	replicator:apply_full(buf, variants)
end
