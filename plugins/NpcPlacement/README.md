# NPC Placement Studio Plugin

Replaces translucent `npc` prefab models in the workspace with real character models from `ServerStorage.NpcModels`.

## Setup in your place

1. Save your translucent placement rig as `ServerStorage.NpcModels._default`.
2. Add character models under `ServerStorage.NpcModels` (for example `Jeff`, `Charlie`).
3. Make sure `npc_configs.luau` uses the same model name in each entry's `model` field.
4. Use **Insert Prefab** (or duplicate `_default` manually) to place markers in the world.

## Install the plugin

### Option A: Rojo (recommended for this repo)

```bash
rojo serve plugins/NpcPlacement --port 34873
```

In Roblox Studio: Plugins → Rojo → Connect to `localhost:34873`.

### Option A2: Argon

If you use the Argon plugin instead of Rojo, serve the same folder from the repo root:

```bash
argon serve plugins/NpcPlacement --port 34873
```

In Studio: connect Argon to `localhost:34873` (same flow as Rojo — Plugins → your sync plugin → connect to the served project).

### Option B: Local plugin script

Copy `src/init.luau` into a Script in your local Roblox Plugins folder and set `RunContext` to `Plugin`.

## Usage

1. Open **RPG Tools → NPC Placement**.
2. Click **Insert Prefab** to clone `_default` into the world (or duplicate `_default` yourself).
3. Select one or more placement prefab **Models** in the Explorer.
4. Enter the model name (must match a child of `ServerStorage.NpcModels`, not `_default`). Fuzzy matching fixes small typos (for example `Jefff` → `Jeff`, `Jeg` → `Jeff`).
5. Click **Set NPC**.

**Undo:** Press **Ctrl+Z** to restore the placement prefab you had before Set NPC. Each Set NPC action is wrapped in Studio change history waypoints.

Wrong name flow: Set NPC → Jeff → Ctrl+Z → prefab returns → enter Charlie → Set NPC again.

Or swap directly: select Jeff, enter Charlie, Set NPC (Ctrl+Z once restores Jeff, twice restores prefab).

The plugin will:

- Clone the model
- Move it to the prefab's exact pivot
- Set attribute `npc_id`
- Add CollectionService tag `npc`
- Delete the prefab
- Support undo via Studio change history (Ctrl+Z restores the destroyed prefab)

## Naming

Use the same string for:

- Model name in `ServerStorage.NpcModels`
- Text field input in the plugin
- `npc_id` attribute on the placed NPC
- `model` field in `npc_configs.luau`

Example: model `Blacksmith` → attribute `npc_id = "Blacksmith"` → config entry `model = "Blacksmith"`.
