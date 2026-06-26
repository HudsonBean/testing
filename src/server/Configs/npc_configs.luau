export type NpcHealthConfig = {
	health: number,
	max_health: number?,
	regen: number?,
	regen_multiplier: number?,
	regen_delay: number?,
}

-- Static NPC definitions. Runtime NPC entities store c.npc (config id) and look up here.
export type NpcConfig = {
	model: string, -- Model name under ServerStorage.NpcModels
	health: NpcHealthConfig,
	dialogue: string?, -- Dialogue tree id; resolved by a future dialogue system
	quests: { string }?, -- Quest ids this NPC can offer or advance
	hostile: boolean?,
}

local configs: { [string]: NpcConfig } = {
	ZombieKicker7 = {
		model = "ZombieKicker7",
		health = {
			health = math.huge,
			max_health = math.huge,
		},
		dialogue = "developer_greeting",
		quests = { "do_the_do" },
	},

	John = {
		model = "John",
		health = {
			health = 100,
			max_health = 100,
		},
		dialogue = "john_greeting",
	},
}

local function get(npcName: string): NpcConfig?
	return configs[npcName]
end

return {
	get = get,
}
