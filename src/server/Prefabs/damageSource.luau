local c = require("@Shared/components")
local jecs = require("@Packages/jecs")
local ref = require("@Shared/utils/ecs/ref")
local world = require("@Shared/world")
local CollectionService = game:GetService("CollectionService")
local tagService = game:GetService("CollectionService")

local function attachComponents(instance: BasePart, damage: number?, delay: number?)
	local resolvedDamage = tonumber(damage or instance:GetAttribute("damage"))
	local resolvedDelay = tonumber(delay or instance:GetAttribute("delay"))
	if resolvedDamage == nil or resolvedDelay == nil then
		warn("[damageSource prefab] damage or delay not set for instance:", instance.Name)
		return nil
	end
	instance.CanQuery = true

	return ref(instance, function(e)
		world:set(e, c.damage_source, {
			damage = resolvedDamage,
			delay = resolvedDelay,
			instance = instance,
		})
		world:set(e, c.cleanup, function()
			ref.unlist(instance)
		end)
		-- Touched or leave to hazardSystem
	end)
end

local function spawnDamageSource(position: Vector3, damage: number, delay: number): jecs.Entity<any>
	local damageSource = Instance.new("Part")
	damageSource:AddTag("damage_source")
	damageSource:SetAttribute("delay", delay)
	damageSource:SetAttribute("damage", damage)
	damageSource.Name = "damage_source"
	damageSource.Anchored = true
	damageSource.Size = Vector3.new(5, 1, 5)
	damageSource.TopSurface = Enum.SurfaceType.Smooth
	damageSource.BottomSurface = Enum.SurfaceType.Smooth
	damageSource.Color = Color3.fromRGB(196, 40, 28)
	damageSource.CFrame = CFrame.new(position)
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.LightInfluence = 1
	particleEmitter.Rate = 14
	particleEmitter.SpreadAngle = Vector2.one * 500
	particleEmitter.Size = NumberSequence.new(0.25)
	particleEmitter.Transparency = NumberSequence.new(0.1)
	particleEmitter.Speed = NumberRange.new(1)
	particleEmitter.Lifetime = NumberRange.new(2.5)
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 0, 0))
	particleEmitter.Parent = damageSource

	return attachComponents(damageSource, damage, delay)
end

-- Register parts that were preplaced and tagged
local tag = "damage_source"
for _, instance in pairs(tagService:GetTagged(tag)) do
	attachComponents(instance)
end
CollectionService:GetInstanceAddedSignal(tag):Connect(attachComponents)
CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: BasePart)
	local entity = ref.search(instance)
	if not entity then
		warn("[damageSource prefab] entity not found for instance:", instance.Name)
		return
	end
	world:remove(entity, c.damage_source)
	world:remove(entity, c.cleanup)
end)

return spawnDamageSource
