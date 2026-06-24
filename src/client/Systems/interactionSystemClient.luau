local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local c = require("@Shared/components")
local jecs = require("@Packages/jecs")
local planckRunService = require("@Packages/planck-runservice")
local clearRelation = require("@Shared/utils/ecs/clearRelation")
local ref = require("@Shared/utils/ecs/ref")
local world = require("@Shared/world")

local pair = jecs.pair

local TAG = "interactable"

local inRangeQueue: { Instance } = {}
local outOfRangeQueue: { Instance } = {}
local interactRequestQueue: { Instance } = {}

local function resolveInteractableRoot(from: Instance): Instance?
	local current: Instance? = from

	while current do
		if CollectionService:HasTag(current, TAG) then
			return current
		end

		current = current.Parent
	end

	return nil
end

local function resolveInteractableEntity(from: Instance): jecs.Entity<any>?
	local root = resolveInteractableRoot(from)
	if not root then
		return nil
	end

	return ref.search(root)
end

local function attachComponents(instance: Instance)
	ref(instance, function(entity)
		world:add(entity, c.interactable)

		world:set(entity, c.cleanup, function()
			ref.unlist(instance)
		end)
	end)
end

local function ensureProximityPrompt(instance: Instance)
	if instance:FindFirstChildOfClass("ProximityPrompt") then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent = instance
end

local function enqueueUnique(queue: { Instance }, instance: Instance)
	if table.find(queue, instance) then
		return
	end

	table.insert(queue, instance)
end

local function interactionSystemClient()
	for _, instance in inRangeQueue do
		local entity = resolveInteractableEntity(instance)
		if not entity then
			continue
		end

		if not world:has(entity, c.interactable) then
			world:delete(entity)
			continue
		end

		world:add(entity, c.interactable_in_range)
	end

	for _, instance in outOfRangeQueue do
		local entity = resolveInteractableEntity(instance)
		if not entity then
			continue
		end

		if not world:has(entity, c.interactable) then
			world:delete(entity)
			continue
		end

		if world:has(entity, c.interactable_in_range) then
			world:remove(entity, c.interactable_in_range)
		end
	end

	local player = Players.LocalPlayer
	local playerEntity = ref.search(player)
	if playerEntity then
		for _, instance in interactRequestQueue do
			local targetEntity = resolveInteractableEntity(instance)
			if not targetEntity then
				continue
			end

			if not world:has(targetEntity, c.interactable_in_range) then
				continue
			end

			clearRelation(playerEntity, c.interact_request)
			world:add(playerEntity, pair(c.interact_request, targetEntity))
		end
	end

	table.clear(inRangeQueue)
	table.clear(outOfRangeQueue)
	table.clear(interactRequestQueue)
end

for _, instance in CollectionService:GetTagged(TAG) do
	ensureProximityPrompt(instance)
	attachComponents(instance)
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance: Instance)
	ensureProximityPrompt(instance)
	attachComponents(instance)
end)

CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance: Instance)
	local entity = ref.search(instance)
	if not entity then
		return
	end

	world:delete(entity)
end)

ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
	local root = if prompt.Parent then resolveInteractableRoot(prompt.Parent) else nil
	if root then
		enqueueUnique(inRangeQueue, root)
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
	local root = if prompt.Parent then resolveInteractableRoot(prompt.Parent) else nil
	if not root then
		return
	end

	local index = table.find(inRangeQueue, root)
	if index then
		table.remove(inRangeQueue, index)
	end

	enqueueUnique(outOfRangeQueue, root)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	if player ~= Players.LocalPlayer then
		return
	end

	local root = if prompt.Parent then resolveInteractableRoot(prompt.Parent) else nil
	if root then
		enqueueUnique(interactRequestQueue, root)
	end
end)

return {
	name = "interactionSystemClient",
	system = interactionSystemClient,
	phase = planckRunService.Phases.PostUpdate,
	runConditions = {},
}
