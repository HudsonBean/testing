--[[
	Server bootstrap: validate static game data, wire replication, register systems,
	and attach player entities to the ECS world.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local net = require("@Server/Networking/server")
local dialogue_configs = require("@Server/Configs/dialogue_configs")
local npc_configs = require("@Server/Configs/npc_configs")
local quest_configs = require("@Server/Configs/quest_configs")
local scheduler = require("@Shared/scheduler")
local replicator = require("@Shared/replicator").server
local c = require("@Shared/components")
local jabby = require("@Packages/jabby")
local jecs = require("@Packages/jecs")
local replecs = require("@Packages/replecs")
local world = require("@Shared/world")

local pair = jecs.pair
local ref = c.ref

-- ---------------------------------------------------------------------------
-- Config validation — cross-reference NPC, dialogue, and quest ids at boot
-- ---------------------------------------------------------------------------

local function validateGameData()
	local errors: { string } = {}

	local function fail(message: string)
		table.insert(errors, message)
	end

	for _, npcId in npc_configs.listIds() do
		local npc = npc_configs.get(npcId)
		if not npc then
			continue
		end

		if npc.dialogue and not dialogue_configs.get(npc.dialogue) then
			fail(`NPC "{npcId}": unknown dialogue tree "{npc.dialogue}"`)
		end

		if npc.quests then
			for _, questId in npc.quests do
				if not quest_configs.get(questId) then
					fail(`NPC "{npcId}": unknown quest "{questId}"`)
				end
			end
		end
	end

	for _, treeId in dialogue_configs.listTreeIds() do
		local tree = dialogue_configs.get(treeId)
		if not tree then
			continue
		end

		if not tree.nodes[tree.start] then
			fail(`Dialogue "{treeId}": start node "{tree.start}" is missing`)
		end

		for nodeId, node in tree.nodes do
			if node.requires_quest and not quest_configs.get(node.requires_quest) then
				fail(`Dialogue "{treeId}/{nodeId}": unknown requires_quest "{node.requires_quest}"`)
			end

			if not node.choices then
				continue
			end

			for _, choice in node.choices do
				if not tree.nodes[choice.next] then
					fail(`Dialogue "{treeId}/{nodeId}": choice next "{choice.next}" is missing`)
				end

				if choice.starts_quest and not quest_configs.get(choice.starts_quest) then
					fail(`Dialogue "{treeId}/{nodeId}": unknown starts_quest "{choice.starts_quest}"`)
				end

				if choice.completes_quest and not quest_configs.get(choice.completes_quest) then
					fail(`Dialogue "{treeId}/{nodeId}": unknown completes_quest "{choice.completes_quest}"`)
				end
			end
		end
	end

	for _, questId in quest_configs.listIds() do
		local quest = quest_configs.get(questId)
		if not quest then
			continue
		end

		for _, objective in quest.objectives do
			if objective.kind == "talk_to_npc" and objective.target and not npc_configs.get(objective.target) then
				fail(`Quest "{questId}": talk_to_npc target "{objective.target}" is unknown`)
			end
		end

		if quest.requires then
			for _, prerequisite in quest.requires do
				if not quest_configs.get(prerequisite.quest) then
					fail(`Quest "{questId}": unknown prerequisite quest "{prerequisite.quest}"`)
				end
			end
		end
	end

	if #errors == 0 then
		return
	end

	for _, message in errors do
		warn("[config validation]", message)
	end

	if RunService:IsStudio() then
		error(`[config validation] {#errors} error(s) — see Output`, 0)
	end
end

validateGameData()

-- ---------------------------------------------------------------------------
-- Replication & networking — replecs init and initial full-state handoff
-- ---------------------------------------------------------------------------

replicator:init()

net.ReceiveFull.On(function(player)
	if replicator:is_player_ready(player) then
		return nil, nil
	end

	replicator:mark_player_ready(player)
	return replicator:get_full(player)
end)

-- ---------------------------------------------------------------------------
-- Player ECS — join/leave hooks and replicated player entity setup
-- ---------------------------------------------------------------------------

local function setupPlayer(player: Player)
	local entity = ref(player)
	world:set(entity, c.player, player)

	world:add(entity, replecs.networked)
	replicator:set_custom(entity, c.player)
	replicator:set_reliable(entity, c.player)
	replicator:set_reliable(entity, c.unix)
	replicator:set_reliable(entity, c.quest_state)
	world:set(entity, c.unix, 0)
	world:set(entity, c.quest_state, { quests = {} })

	world:set(entity, c.timer, {
		start = os.clock(),
		wait = 1,
		repeats = true,
		callback = function()
			world:set(entity, c.unix, world:get(entity, c.unix) :: number + 1)
		end,
	})

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

local playerSetup = world:entity()
world:set(playerSetup, c.player_setup, function(_player: Player, entity)
	world:add(entity, pair(c.spawn_request, entity))
end)

-- ---------------------------------------------------------------------------
-- ECS systems — Planck scheduler registration
-- ---------------------------------------------------------------------------

-- Update:    timers → damage → quest intents
-- PostUpdate: health → death → respawn (queues spawn_request) → spawn → replicate
local systemsOrder = {
	require("@Shared/Systems/timers"),
	require("@Server/Systems/damageSystem"),
	require("@Server/Systems/questSystem"),
	require("@Server/Systems/healthSystem"),
	require("@Server/Systems/deathSystem"),
	require("@Server/Systems/respawnSystem"),
	require("@Server/Systems/spawnSystem"),
	require("@Server/Systems/interactionSystemServer"),
	require("@Server/Systems/replecsServer"),
}

scheduler:addSystems(systemsOrder)

-- ---------------------------------------------------------------------------
-- Debug tooling — Jabby world inspector
-- ---------------------------------------------------------------------------

jabby.register({
	name = "Server",
	applet = jabby.applets.world,
	configuration = { world = world :: any },
})

-- ---------------------------------------------------------------------------
-- Boot — connect existing players and listen for join/leave
-- ---------------------------------------------------------------------------

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)
