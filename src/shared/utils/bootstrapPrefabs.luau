local function bootstrapPrefabs(root: Instance?)
	local prefabs = root and root:FindFirstChild("Prefabs")
	if not prefabs then
		return
	end

	for _, prefab in prefabs:GetChildren() do
		require(prefab)
	end
end

return bootstrapPrefabs
