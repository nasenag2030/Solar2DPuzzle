# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**Get10** — A hyper-casual mobile tile-merging puzzle game for iOS and Android.
Built with **Solar2D** (Corona SDK). Language: **Lua**.

Core mechanic: tap connected groups of matching numbered tiles → they merge into one tile with value+1. Goal: reach tile 10.

Current version: **v4.0** — feature complete. Priority is bug fixes and content, not new features.

---

## Running the Game

Open the `Corona/` folder in the **Solar2D Simulator** (https://solar2d.com). There is no build step — the simulator runs Lua directly. Press `⌘R` to restart.

To test on device, use Solar2D's build menu (File → Build). Requires Xcode for iOS, Android SDK for Android.

---

## Three-Layer Architecture (never break this)

```
LAYER 3 — SCENES (scenes/*.lua)
  Owns all display objects, handles input, runs animations and timers
  Rule: NO game rules, NO SQL, NO score math

LAYER 2 — HELPERS (app/helpers/*.lua)
  Pure logic — display-free. Can be tested without Solar2D running.
  Rule: NO display.*, NO transition.*, NO timer.*

LAYER 1 — DATA (app/models/*.lua)
  All SQLite persistence
  Rule: NO display, NO game logic
```

**Dependency flow (one direction only):** Scenes → Helpers → Models → dbModel

`config/settings.lua` and `app/components/*.lua` may be used at any layer.

---

## Critical Rules

### Gravity must move `.obj` with `.num` — always
When `applyGravity()` moves a tile's logical data, it MUST move the `.obj` reference too. Moving `.num` without `.obj` causes tiles to vanish: `syncDisplayAfterGravity()` finds the num but skips animation; `removeOrphanedObjects()` then deletes the orphaned obj.

After moving, update the obj's coords so tap handlers resolve correctly:
```lua
cell.obj.i = newRow
cell.obj.j = newCol
```

### Touch guard — lock at the top of every tap handler
```lua
if not _touchEnabled then return true end
_touchEnabled = false  -- lock BEFORE any async work
```
Re-enable only at the very end of the post-merge pipeline.

### Forward declarations for mutually-recursive functions
```lua
local _endSession          -- forward declare
local function checkEnd()
    _endSession(true)      -- safe to reference
end
_endSession = function()   -- assign (no "local function" keyword)
    ...
end
```

### All constants in `config/settings.lua` — never inline numbers
```lua
-- ❌ timer.performWithDelay(110, ...)
-- ✅ timer.performWithDelay(settings.VISUAL.MERGE_ANIM_MS, ...)
```

### Nil-guard every display object before use
```lua
local obj = cell.obj
cell.obj = nil
if obj then display.remove(obj) end

-- Before transitions:
if obj and obj.parent then transition.to(obj, { ... }) end
```

### Timer safety
```lua
_myTimer = timer.performWithDelay(...)   -- always store handle
-- Cancel in scene:hide AND scene:destroy:
pcall(timer.cancel, _myTimer)
```

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

## Scene Navigation

```
menu → game (Basic/Intermediate/Advanced)
menu → mania
menu → levelSelect → game (mode="intermediate", levelNum=N)
menu → stageSelect → game (mode="advanced", stageNum=N)
game / mania → gameover overlay → PLAY AGAIN or MAIN MENU
```

Modal overlays (gameover, settings, stats) always receive `mode`, `levelNum`, and `stageNum` in params so PLAY AGAIN routes correctly.

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

**Advanced stages** (`data/levels/advanced/stage_NNNN.lua`): same format with `winTile` and `theme` fields. Missing stages auto-generate procedurally.

---

## What Needs Work (v4.0 state)

- Audio files missing — game runs silent (see `app/assets/audio/README.txt`)
- Intermediate levels 11–50 not created yet
- No app icons, splash screens, or `build.settings`
- Ads not implemented (plan in `HandOff2ClaudeCode.md` section 11)
- Known bugs from owner testing — fix before adding features

---

## Coding Style

- All state as module-level `local` — no globals ever
- File naming: `snake_case` for files, `camelCase` for helper modules, `UPPER_SNAKE` for constants
- Every file must have the standard header block (see `HandOff2ClaudeCode.md` section 12)
- Every function must have a `--- @param / @return` comment block
- Comment density must match existing files
