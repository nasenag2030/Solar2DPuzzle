# CLAUDE.md — Get10

**Get10** — A hyper-casual mobile tile-merging puzzle game for iOS and Android.
Built with **Solar2D** (Corona SDK). Language: **Lua**.

Core mechanic: tap connected groups of matching numbered tiles → they merge into
one tile with value+1. Goal: reach tile 10.

Current version: **v4.0** — feature complete. Priority is **bug fixes**, not new features.

> Platform-wide rules (three-layer architecture, coding style, critical Solar2D rules)
> are in the parent `Solar2DPuzzle/CLAUDE.md`. This file covers Get10-specific rules only.

---

## Running the Game

Open the `Get10V3-2026/` folder in the **Solar2D Simulator** (https://solar2d.com).
No build step — the simulator runs Lua directly. Press `Cmd+R` to restart.

To switch: `python PublishTools/build.py switch get10`

---

## Key Files

| File | Purpose |
|------|---------|
| `main.lua` | Boot: init DB, audio, go to menu |
| `config/settings.lua` | **ALL constants** — change values here only |
| `scenes/game.lua` | Main game scene (~1300 lines). Basic + Intermediate + Advanced modes |
| `app/helpers/gameLogic.lua` | Pure game rules: grid, gravity, chains, bombs, hot zones |
| `app/helpers/saveState.lua` | All SQLite persistence |
| `app/components/tile.lua` | Tile display component |
| `HandOff2ClaudeCode.md` | Full project context, roadmap, and detailed internals |
| `vibe/bug/` | Bug reports and screenshots |

---

## Grid Data Structure

```lua
grid[i][j] = {
    num       = number|nil,   -- tile value; nil = empty
    i         = number,       -- row (1=top)
    j         = number,       -- col (1=left)
    isBomb    = boolean,
    isHotZone = boolean,
    obj       = DisplayGroup, -- live display object (owned by game.lua)
    _visited  = boolean,      -- flood-fill scratch flag
}
```

---

## Post-Merge Pipeline (core sequence in game.lua)

```
player tap → tileOnTap()
  └─ doMerge() / doBombBlast()
       └─ runPostMerge()
            [MERGE_ANIM_MS + 20ms]
            applyGravity() + syncDisplay() + refillEmptyCells()
            [FALL_ANIM_MS + 30ms]
            doChainStep(depth=1)  ← recursive until no more chains
              └─ checkEndConditions()
                   └─ _touchEnabled = true  ← re-enable input HERE
```

---

## Get10-Specific Critical Rules

### Gravity must move `.obj` with `.num` — always
`applyGravity()` MUST move the `.obj` reference alongside `.num`. Moving `.num`
without `.obj` causes tiles to vanish: `syncDisplayAfterGravity()` finds the num
but skips animation; `removeOrphanedObjects()` then deletes the orphaned obj.

After moving, update the obj's coords so tap handlers resolve correctly:
```lua
cell.obj.i = newRow
cell.obj.j = newCol
```

### Bomb position — always use grid coords, never obj.x/y
Plant the bomb AFTER gravity settles (inside the step-2 timer). Use
`gridToScreen(cell.i, cell.j)` — not `cell.obj.x/y` which is pre-gravity.

---

## Scene Navigation

```
menu → game (Basic/Intermediate/Advanced)
menu → mania
menu → levelSelect → game (mode="intermediate", levelNum=N)
menu → stageSelect → game (mode="advanced", stageNum=N)
game / mania → gameover overlay → PLAY AGAIN or MAIN MENU
```

Modal overlays (gameover, settings, stats) always receive `mode`, `levelNum`,
and `stageNum` in params so PLAY AGAIN routes correctly.

---

## Adding Content

**Intermediate levels** (`data/levels/intermediate/level_NNN.lua`, levels 11–50 missing):
```lua
return {
    name="Level Name", goal="reach", target=6,
    moves=20, par=14, noBomb=false,
    hint="Short tip",
    grid={ {1,2,3,2,1}, ... },  -- nil = inactive cell
}
```
Goals: `"reach"` (tile value) | `"clear"` (all tiles) | `"score"` (points) | `"survive"` (merge count)

**Advanced stages** (`data/levels/advanced/stage_NNNN.lua`): same format with `winTile`
and `theme` fields. Missing stages auto-generate procedurally.

---

## What Needs Work (v4.0 state)

- Audio files missing — game runs silent (see `app/assets/audio/README.txt`)
- Intermediate levels 11–50 not created yet
- No app icons, splash screens
- Ads not implemented (plan in `HandOff2ClaudeCode.md` section 11)
- Known bugs from owner testing — fix before adding features
