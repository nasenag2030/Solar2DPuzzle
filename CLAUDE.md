# CLAUDE.md — Solar2DPuzzle Platform

Platform for building, maintaining, and publishing hyper-casual mobile puzzle games
built with **Solar2D** (Corona SDK). Language: **Lua**.

---

## Platform Structure

```
Solar2DPuzzle/                         ← git root — START CLAUDE HERE
├── CLAUDE.md                          ← this file (platform-wide rules)
├── solar2d_game_architecture_v2.md    ← deep reference: patterns, pitfalls, templates
├── Tools/
│   ├── init.py                        ← scaffold a new game (full Solar2D structure)
│   ├── build.py                       ← prepare/publish games for App Store / Play Store
│   ├── platform.json                  ← game registry: bundle IDs, ad IDs, feature flags
│   └── templates/                     ← build.settings templates
├── Get10V3-2026/                      ← Get10 (v4.0 — bug fix phase)
│   └── CLAUDE.md                      ← Get10-specific rules
└── LineConnect-2026/                  ← Next game (planned)
    └── CLAUDE.md                      ← created when init.py is run
```

---

## Game Registry

| Slug | Folder | Display Name | Status |
|------|--------|--------------|--------|
| get10 | Get10V3-2026/ | Get 10 | v4.0 — bug fix phase |
| connectline | LineConnect-2026/ | Connect Line | Planned |

---

## Starting Claude for Each Workflow

| Task | Where to open Claude Code |
|------|--------------------------|
| Bug fixes or features in Get10 | `Solar2DPuzzle/` — reads both CLAUDE.md files |
| Architecture, Tools, cross-game | `Solar2DPuzzle/` (here) |
| Starting a new game | Run `init.py` first, then open from `Solar2DPuzzle/` |

Claude Code cascades CLAUDE.md up the directory tree to the git root, so opening
from `Solar2DPuzzle/` loads platform rules + the active game's rules automatically.

---

## Three-Layer Architecture (every game must follow this)

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

## Coding Style (all games)

- All state as module-level `local` — no globals ever
- All constants in `config/settings.lua` — never inline magic numbers
- File naming: `snake_case` files, `camelCase` modules, `UPPER_SNAKE` constants
- Every file: standard header block (see `solar2d_game_architecture_v2.md` §3)
- Every function: `--- @param / @return` comment block
- Comment density must match existing files

---

## Critical Solar2D Rules

### Gravity must move `.obj` with `.num` — always
Moving `.num` without `.obj` causes tiles to vanish after merge.
Always snapshot the full `{num, isBomb, isHotZone, obj}` and move everything together.
After moving, update `obj.i` and `obj.j` so tap handlers resolve correctly.

### Touch guard — lock at the top of every tap handler
```lua
if not _touchEnabled then return true end
_touchEnabled = false  -- lock BEFORE any async work
-- re-enable only at the very end of the post-merge pipeline
```

### Nil-guard every display object before use
```lua
local obj = cell.obj
cell.obj = nil
if obj then display.remove(obj) end
if obj and obj.parent then transition.to(obj, { ... }) end
```

### Forward declarations for mutually-recursive functions
```lua
local _endSession                      -- forward declare
local function checkEnd() _endSession(true) end
_endSession = function() ... end       -- assign (no "local function" keyword)
```

### Timer safety
```lua
_myTimer = timer.performWithDelay(...)
-- cancel in BOTH scene:hide AND scene:destroy:
pcall(timer.cancel, _myTimer)
```

---

## Tools

```bash
# List all games and their readiness
python Tools/build.py list

# Quick switch for simulator testing
python Tools/build.py switch get10

# Full preparation for App Store / Play Store
python Tools/build.py prepare get10 mobile

# Scaffold a brand new game
python Tools/init.py <slug> "<Display Name>" "<one-line description>"
# Example:
python Tools/init.py blockdrop "Block Drop" "Drop blocks to fill rows"
```

`init.py` creates the full Solar2D folder structure, CLAUDE.md, vibe/, all boilerplate
files, and registers the game in `platform.json`. Ready to open in the Simulator immediately.

---

## Deep Reference

`solar2d_game_architecture_v2.md` — 23 sections covering every pattern, template,
and pitfall learned from building Get10 v4.0. Includes:
- Complete `settings.lua` template (§4)
- Standard scene template (§3)
- Grid data structure (§5)
- Timer chain / post-merge pipeline (§6)
- Audio, database, save state patterns (§9–11)
- All 15 common Solar2D pitfalls (§19)
- Ad integration plan (§23)

Drop this file into any new conversation to give Claude full platform context.
