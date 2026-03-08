# Get10 — Complete Handoff Document for Claude Code
# ═══════════════════════════════════════════════════════════════════
#
# HOW TO USE THIS FILE
# ────────────────────
# Tell Claude Code:
#   "Read HandOff2ClaudeCode.md first. It contains the full project
#    context, architecture, roadmap, bugs, and coding guidelines.
#    Start working from where we left off."
#
# This file is the single source of truth for everything decided
# in the planning conversations. Nothing important is missing.
#
# Last updated: 2026-03-04  |  Version: v4.0
# ═══════════════════════════════════════════════════════════════════

---

## 1. WHAT THIS PROJECT IS

**Get10** — A hyper-casual mobile tile-merging puzzle game for iOS and Android.
Built with **Solar2D** (Corona SDK). Language: **Lua**.

**Core mechanic:** Tap connected groups of matching numbered tiles. They merge
into one tile with value+1. Goal: reach tile 10. Simple to learn, hard to master.

**Business goal:** Ship to App Store / Play Store and generate revenue.
This is one of several games in a portfolio. Code must be maintainable so
the same architecture can be reused across future games.

**Engine:** Solar2D (free, open source Corona SDK fork)
- Download: https://solar2d.com
- Docs: https://docs.coronalabs.com
- The game compiles to native iOS and Android from Lua source

---

## 2. CURRENT STATUS (v4.0 — as of handoff)

### What is COMPLETE and working
- ✅ Basic mode — 5×5 grid, reach tile 10, endless mode after win
- ✅ Chain reactions — auto-merge after gravity, cascades up to depth 10
- ✅ Combo streak — ×2 to ×5 multiplier, 2-second window
- ✅ Bomb tiles — appear every 12 merges, cross-shaped blast
- ✅ Undo system — 1 free per game, blue flash rewind animation
- ✅ Hot zones — 2 glowing cells worth 2× score, refresh every 5 merges
- ✅ Near-miss detection — "So close!" flash when 1 neighbour away
- ✅ Dynamic background — tints gold/mint/red based on game state
- ✅ Score roll-up animation — counter rolls from old to new value
- ✅ Particle bursts on merge
- ✅ Haptic feedback scaled to tile value
- ✅ Musical notes per tile (13 ascending tones)
- ✅ Achievements — 8 total, checked at game end
- ✅ XP & player rank — Novice → Skilled → Expert → Master → Legend
- ✅ Daily streak calendar — 7-day dot display
- ✅ Lifetime stats screen — scrollable overlay
- ✅ Gameover/win overlay — score, rank, streak, achievement banners
- ✅ Mania mode — auto-drop tiles, rotating gravity, ratcheting multiplier
- ✅ Intermediate mode framework — levelSelect scene, 10 hand-crafted levels
- ✅ Advanced mode framework — stageSelect scene, 999 stages (procedural fallback)
- ✅ Settings overlay — sound toggle, how-to-play
- ✅ SQLite persistence — board resume, stats, achievements, streak
- ✅ All bugs from v3.2 fixed (gravity, nil crash, bomb position, forward decl)

### What is INCOMPLETE (needs work)
- ⚠️  Audio files missing — see `app/assets/audio/README.txt` for list needed
- ⚠️  Intermediate levels 11–50 missing (levels 1–10 done, rest fallback to procedural)
- ⚠️  No hand-crafted Advanced stages yet (all 999 use procedural generation)
- ✅  Splash screen wired — placeholder PNG at `app/assets/splash/splash.png`
      TODO (ART): Create real splash (1080×1920, dark navy #14141A, "GET 10" logo centred)
- ⚠️  No app icons (1024×1024 for iOS, adaptive for Android)
- ⚠️  No build.settings configured for App Store submission
- ⚠️  Ads not implemented yet (planned — see section 10)
- ⚠️  Known bugs reported by owner — screenshots coming (test and fix as found)

---

## 3. FOLDER STRUCTURE (every file explained)

```
Corona/                             ← Solar2D project root
│
├── HandOff2ClaudeCode.md           ← THIS FILE
├── main.lua                        ← App entry point. Init DB, audio, go to menu.
├── config.lua                      ← Display config: 320×568 canvas, 60fps, letterBox
│
├── config/
│   └── settings.lua                ← ALL constants. Change values here only.
│                                     Sections: VERSION, GAME, COMBO, CHAIN, UNDO,
│                                     BOMB, HOT_ZONE, NEAR_MISS, ENDLESS, MANIA,
│                                     DAILY, XP, ADVANCED, VISUAL, FONT, COLOR
│
├── scenes/
│   ├── menu.lua                    ← Main menu. Mode buttons, rank bar, streak badge.
│   ├── game.lua                    ← THE main game scene. Basic + Intermediate + Advanced.
│   │                                 1291 lines. See section 5 for internals.
│   ├── gameover.lua                ← Win/lose modal overlay. Confetti, achievements.
│   ├── settings.lua                ← Sound toggle modal overlay.
│   ├── stats.lua                   ← Lifetime stats + achievements modal overlay.
│   ├── levelSelect.lua             ← Intermediate: scrollable 50-level grid UI.
│   ├── stageSelect.lua             ← Advanced: 999-stage scrollable grid + progress bar.
│   └── mania.lua                   ← Mania survival mode. Separate scene, own timers.
│
├── app/
│   ├── components/
│   │   └── tile.lua                ← Tile display component. new(), upgrade(),
│   │                                 animateMerge(), animateFall(), spawnParticles(),
│   │                                 setBombPulse(), spawnBombBlast()
│   │
│   ├── helpers/
│   │   ├── gameLogic.lua           ← Pure game rules. NO display code. 548 lines.
│   │   │                             buildGrid(), populateGrid(), getConnected(),
│   │   │                             applyGravity(), findChains(), executeChain(),
│   │   │                             hasMoves(), plantBomb(), getBombBlast(),
│   │   │                             refreshHotZones(), findNearMiss()
│   │   ├── scoreHelper.lua         ← All scoring math. calculate(), chainScore(),
│   │   │                             bombScore(), toXP(), scoreDisplay()
│   │   ├── audioHelper.lua         ← Pre-load + play sounds. init(), playMerge(num),
│   │   │                             playTap(), playWin(), playLose(), playBomb(),
│   │   │                             vibrateOnMerge(tileNum), setEnabled()
│   │   ├── saveState.lua           ← All SQLite persistence. save/load/clear board,
│   │   │                             updateStats(), loadStats(), updateStreak(),
│   │   │                             loadStreak(), unlockAchievement(), loadAchievements(),
│   │   │                             saveAdvancedStage(), saveIntermediateStars()
│   │   ├── achievementHelper.lua   ← 8 achievement definitions + check(session, stats)
│   │   │                             rankFromXP(), nextRankXP(), all()
│   │   └── levelLoader.lua         ← loadIntermediate(num), loadAdvanced(num),
│   │                                 advancedWinTile(num), advancedChapter(num),
│   │                                 _generateStage(num) [procedural fallback]
│   │
│   ├── models/
│   │   ├── dbModel.lua             ← Raw SQLite wrapper. init(), createTable(),
│   │   │                             getRow(), exec()
│   │   └── settingsModel.lua       ← Sound on/off, high score, first-run flag.
│   │
│   └── assets/
│       └── audio/
│           └── README.txt          ← Lists all required .mp3 files
│
└── data/
    └── levels/
        ├── intermediate/
        │   ├── level_001.lua       ← "Getting Started" — reach tile 4
        │   ├── level_002.lua       ← "Rising Up" — reach tile 5 in 15 moves
        │   ├── level_003.lua       ← "Score Attack" — score 100 in 10 moves
        │   ├── level_004.lua       ← "Clean Sweep" — clear the board (cross shape)
        │   ├── level_005.lua       ← "Endurance" — survive 15 merges
        │   ├── level_006.lua       ← "The Cross" — reach tile 6, cross-shaped grid
        │   ├── level_007.lua       ← "Corner Pocket" — reach tile 5, no bombs
        │   ├── level_008.lua       ← "Speed Run" — reach tile 6 in only 8 moves
        │   ├── level_009.lua       ← "The Stairs" — staircase grid shape
        │   └── level_010.lua       ← "First Boss" — reach tile 7, checkerboard
        │   [levels 011–050 missing — use procedural fallback until created]
        │
        └── advanced/
            [all stages missing — 100% procedural generation until created]
```

---

## 4. ARCHITECTURE — THREE-LAYER RULE (NEVER BREAK THIS)

```
LAYER 3 — SCENES (scenes/*.lua)
  • Owns all display objects
  • Wires player input to helpers
  • Runs animations and timers
  • Rule: NO game rules, NO SQL, NO score math here

LAYER 2 — HELPERS (app/helpers/*.lua)
  • Pure logic — display-free
  • Rule: NO display.*, NO transition.*, NO timer.*
  • Can be tested without Solar2D running

LAYER 1 — DATA (app/models/*.lua)
  • All SQLite persistence
  • Rule: NO display, NO game logic
```

**Dependency flow (one direction only):**
Scenes → Helpers → Models → dbModel

---

## 5. game.lua INTERNALS (the most complex file)

### Module-level state variables
```lua
_grid          -- 5×5 logical grid (see section 6)
_tileGroup     -- DisplayGroup for all tile objects
_hotGroup      -- DisplayGroup for hot-zone glows (below tiles)
_sceneGroup    -- top-level scene view
_bgRect        -- background rect (tinted by dynamic bg system)
_totalScore, _highScore, _maxTile
_touchEnabled  -- CRITICAL: false while animations run, prevents nil crashes
_gameState     -- "running" | "gameover" | "win" | "endless"
_isEndless     -- true after first WIN_TILE reached in Basic mode
_streak, _comboMult, _lastMergeTime
_mergesUntilBomb, _mergesUntilHotRefresh
_undosLeft, _undoSnapshot
_session       -- accumulates stats during game, sent to achievements at end
_mode          -- "basic" | "intermediate" | "advanced"
_levelNum, _stageNum, _levelData
_gravityDir    -- "down" (always in Basic/Intermediate, rotates in Mania)
```

### The post-merge pipeline (critical sequence)
```
player tap
  └─ tileOnTap()
       ├─ isBomb? → doBombBlast() ──────────┐
       └─ group found? → doMerge() ──────────┤
                                             ↓
                                      runPostMerge()
                                        [MERGE_ANIM_MS + 20ms]
                                        applyGravity()
                                        syncDisplayAfterGravity()
                                        removeOrphanedObjects()
                                        refillEmptyCells()
                                        updateHotZoneDisplay()
                                        [FALL_ANIM_MS + 30ms]
                                        doChainStep(depth=1)
                                          └─ if chains found:
                                               animate + gravity + refill
                                               doChainStep(depth+1) [recursive]
                                          └─ if no chains:
                                               checkEndConditions()
                                                 ├─ shouldBomb? → plantBombNow()
                                                 ├─ win reached? → endless or gameover
                                                 └─ no moves? → gameover
                                                 └─ unlock input (_touchEnabled = true)
```

### Key functions in game.lua
| Function | Purpose |
|----------|---------|
| `gridToScreen(i,j)` | Convert grid coords to screen pixels |
| `setBgTint(col)` | Animate background colour toward target |
| `rollUpScore(lbl, old, new)` | Animated score counter |
| `updateStreak()` | Advance combo, update multiplier |
| `showChainLabel(depth)` | Show "CHAIN x2!" banner |
| `showNearMiss(obj, nb)` | Flash both tiles, show "So close!" |
| `takeUndoSnapshot()` | Snapshot grid before merge |
| `doUndo()` | Restore snapshot, flash blue |
| `plantBombNow()` | Place bomb AFTER gravity settled |
| `updateHotZoneDisplay()` | Draw/pulse gold glow on hot cells |
| `doChainStep(depth, onDone)` | Recursive chain processor |
| `runPostMerge(newTileNum, shouldBomb)` | Master animation pipeline |
| `doBombBlast(tappedCell)` | Cross-shaped explosion |
| `doMerge(tappedCell, group)` | Normal player merge |
| `tileOnTap(event)` | Single entry point for all input |
| `buildBoard(savedData)` | Reset and populate grid |
| `checkEndConditions(newTileNum, shouldBomb)` | Win/gameover/endless logic |
| `_endSession(isGameOver)` | Collect stats, trigger achievements, show overlay |

---

## 6. GRID DATA STRUCTURE

```lua
grid[i][j] = {
    num       = number|nil,   -- tile value. nil = empty cell
    i         = number,       -- row  (1=top, 5=bottom)
    j         = number,       -- col  (1=left, 5=right)
    isBomb    = boolean,
    isHotZone = boolean,      -- 2× score modifier
    obj       = DisplayGroup, -- live display object (managed by game.lua)
    _visited  = boolean,      -- internal flood-fill scratch flag
}
```

### THE MOST IMPORTANT RULE IN THE ENTIRE CODEBASE

**applyGravity() MUST move `.obj` with `.num`. Always.**

If you move `.num` without moving `.obj`:
- `syncDisplayAfterGravity()` finds `.num` but no `.obj` → skips animation
- `removeOrphanedObjects()` finds `.obj` with no `.num` → deletes it
- Tile vanishes instead of sliding down

After moving `.obj` to a new cell, update its coords:
```lua
cell.obj.i = newRow
cell.obj.j = newCol
```
So `tileOnTap` can look up the correct cell when the player taps.

---

## 7. LEVEL DATA FORMAT

### Intermediate levels (`data/levels/intermediate/level_NNN.lua`)
```lua
return {
    name   = "Level Name",
    goal   = "reach",     -- "reach" | "clear" | "score" | "survive"
    target = 6,           -- tile value (reach), 0 (clear), score, merge count
    moves  = 20,          -- nil = unlimited
    par    = 14,          -- moves for 3-star rating
    noBomb = false,
    hint   = "Short tip shown before level starts",
    grid   = {            -- nil = random fill
        {1,2,nil,2,1},    -- nil in grid = inactive cell (shaped board)
        {2,1,nil,1,2},
        {nil,nil,nil,nil,nil},
        {2,1,nil,1,2},
        {1,2,nil,2,1},
    },
}
```

### Advanced stages (`data/levels/advanced/stage_NNNN.lua`)
```lua
return {
    name    = "Stage 1",
    grid    = { ... },    -- nil cells = inactive
    goal    = "reach",
    target  = 10,
    winTile = 10,
    theme   = "Classic",
    hint    = "Chapter 1: Classic",
    noBomb  = false,
}
```

**Win tile by bracket:**
- Stages 1–100: reach tile 10
- Stages 101–300: reach tile 12
- Stages 301–600: reach tile 14
- Stages 601–999: reach tile 16

**Chapters:** every 10 stages = 1 chapter. Theme cycles:
Classic → Ocean → Fire → Forest → Space → Ice → Desert → Neon → Candy → Void

---

## 8. SAVE STATE — KEY NAMES (use exactly these)

```lua
-- Lifetime stats table (saved as JSON in SQLite)
{
    bestCombo      = 0,   -- largest single group merged
    totalMerges    = 0,   -- lifetime merge count
    highestTile    = 0,   -- highest tile ever reached
    gamesPlayed    = 0,
    totalXP        = 0,   -- cumulative XP across all games
    bestScore      = 0,   -- highest single-game score (NOT a sum)
    totalBombsUsed = 0,   -- lifetime bomb detonations (integer!)
}

-- Session table (accumulate during game, passed to achievements at end)
_session = {
    startTime      = system.getTimer(),
    merges         = 0,
    usedBomb       = false,      -- bool: was any bomb used this game?
    bombsUsedCount = 0,          -- int: how many bombs detonated (for achievements)
    maxTile        = 0,
    maxCombo       = 0,
    maxChainDepth  = 0,
    bestCombo      = 0,          -- largest group this game
    score          = 0,          -- set at end
    xp             = 0,          -- set at end
    elapsedSeconds = 0,          -- set at end
}
```

**Critical:** `totalBombsUsed` must be an **integer**, not a bool.
`usedBomb` (bool) is for the "Minimalist" achievement.
`bombsUsedCount` (int) feeds `totalBombsUsed` for the "Bomb Squad" achievement.

---

## 9. ACHIEVEMENTS (8 total)

| ID | Name | Condition |
|----|------|-----------|
| `first_win` | First Victory | reach tile 10 |
| `combo_king` | Combo King | combo ×5 in one game |
| `chain_master` | Chain Master | chain depth ≥ 3 |
| `bomb_squad` | Bomb Squad | totalBombsUsed ≥ 10 (lifetime) |
| `minimalist` | Minimalist | win without using any bomb |
| `high_roller` | High Roller | score > 5000 in one game |
| `speed_demon` | Speed Demon | win in under 2 minutes |
| `grandmaster` | Grandmaster | reach tile 12 (Endless mode) |

---

## 10. FULL DEVELOPMENT ROADMAP

### ✅ DONE (v4.0)
All items in section 2 "What is COMPLETE".

### 🔴 IMMEDIATE (fix before anything else)
1. **Test Basic mode end-to-end** — owner is finding bugs, screenshots incoming
2. **Fix all reported bugs** — priority 1, nothing else until stable
3. **Add audio files** — game runs silent without them (see `app/assets/audio/README.txt`)

### 🟡 NEXT — v3.3 Juice & Polish
4.  I-02 Animated score counter ← already implemented in v4.0
5.  M-08 Near-miss detection ← already implemented in v4.0
6.  M-07 Score multiplier zones ← already implemented in v4.0
7.  I-06 Dynamic background ← already implemented in v4.0
8.  P-01 Daily streak calendar ← already implemented in v4.0

### 🟡 AFTER — v3.4 Progression
9.  M-03 Endless mode ← already implemented in v4.0
10. P-02 Lifetime stats ← already implemented in v4.0
11. P-03 Achievements ← already implemented in v4.0
12. P-04 XP & player rank ← already implemented in v4.0
13. M-04 Daily challenge ← framework in saveState, UI not built yet

### 🟠 CONTENT — v3.5
14. Intermediate levels 11–50 (10 done, 40 remaining)
15. Advanced hand-crafted stages batch 1 (20 stages)
16. P-05 Tile skins / themes (2 unlockable colour palettes)
17. M-02 Hint system (sparkle after 10s idle)
18. I-05 Colour-blind mode (shape overlay on tiles)

### 🔵 FUTURE — v4.0 Mania + Advanced full
19. Advanced: build content pipeline for all 999 stages
20. P-06 Weekly leaderboard (local ghost scores, no server needed)
21. I-07 Merge trail animation (motion blur smear)
22. M-10 Locked tile obstacle (Advanced/Mania only)
23. M-05 Shuffle power-up (limited, earn via streak)
24. M-06 Freeze tile power-up

### 💰 MONETISATION (after gameplay is solid)
25. AdMob integration — interstitial after game over (max 1 per 3 games)
26. Rewarded video for extra undo
27. Rewarded video for shuffle power-up
28. Rewarded video to continue after game over (pay to not lose)
29. One-time IAP to remove ads ($1.99)
30. App Store / Play Store submission

---

## 11. AD INTEGRATION PLAN (implement last)

**Network:** AdMob (simplest Solar2D integration, start here)
**Plugin:** `plugin.admob` in build.settings

**Three placements (in order of player-friendliness):**

1. **Rewarded video** — player chooses to watch for reward
   - Extra undo (1 per game free, more via rewarded ad)
   - Shuffle power-up
   - Continue after game over (resurrection)

2. **Interstitial** — after game over only
   - Max once per 3 game-overs
   - 5-minute cooldown between shows
   - Never during gameplay

3. **Banner** — menu screen only, never during gameplay

**adHelper.lua** to create (fits the three-layer architecture):
```lua
-- app/helpers/adHelper.lua
-- M.init()
-- M.showInterstitial()   -- respects cooldown
-- M.showRewarded(rewardType, onComplete)
-- M.showBanner()
-- M.hideBanner()
-- M.setEnabled(bool)     -- disabled if player paid to remove
```

**Monetisation model:** Free with ads + one-time IAP to remove ($1.99)

---

## 12. CODING GUIDELINES (follow strictly)

### Lua style
```lua
-- ✅ Module-level locals only (no globals ever)
local _myVar = nil

-- ✅ Snake_case for files, camelCase for helpers, UPPER_SNAKE for constants
local GL = require("app.helpers.gameLogic")
local settings = require("config.settings")
local WIN = settings.GAME.WIN_TILE

-- ✅ Forward declare mutually-recursive functions
local myFn
local function otherFn() myFn() end
myFn = function() end   -- note: no "local function", assigns to existing local

-- ✅ Nil-guard every display object before use
local obj = cell.obj
cell.obj = nil
if obj then display.remove(obj) end

-- ✅ All constants in settings.lua, never inline
-- ❌ BAD:  timer.performWithDelay(110, ...)
-- ✅ GOOD: timer.performWithDelay(settings.VISUAL.MERGE_ANIM_MS, ...)
```

### File header (every file must have this)
```lua
-----------------------------------------------------------------------------------------
-- path/to/file.lua
-- Get10 vX.X — One-line description
--
-- WHAT THIS FILE DOES:
--   [2-5 sentences]
--
-- USAGE:
--   local X = require("path.to.file")
--   X.doThing()
--
-- CHANGELOG:
--   vX.X  YYYY-MM-DD  Description
-----------------------------------------------------------------------------------------
```

### The three-layer rule (repeat for emphasis)
- Helpers NEVER call `display.*`, `transition.*`, or `timer.*`
- Scenes NEVER contain game logic or SQL
- Models NEVER contain display or game logic

### Timer safety
- Always store timer handles: `_myTimer = timer.performWithDelay(...)`
- Always cancel in scene:hide AND scene:destroy
- Use `pcall(timer.cancel, handle)` when unsure if timer is valid

### Transition safety
```lua
-- Always check before animating:
if obj and obj.parent then
    transition.to(obj, { ... })
end

-- Always cancel before re-animating same object:
transition.cancel(obj)
transition.to(obj, { ... })
```

### Documentation standard
Every function must have a comment block:
```lua
---
-- Brief description of what the function does.
-- @param paramName  type  description
-- @return           type  description
function M.myFunction( paramName )
```

---

## 13. KNOWN BUGS (as of handoff)

### Fixed in v4.0 (do not re-introduce)
- ✅ Tiles vanishing after merge — gravity not moving `.obj` with `.num`
- ✅ nil crash on rapid double-tap — `_touchEnabled` not locked before timer
- ✅ Bomb appearing at wrong position — planted before gravity ran
- ✅ `_endSession` called before defined — needed forward declaration
- ✅ Stats screen showing 0 — `totalScore` key renamed to `bestScore`
- ✅ PLAY AGAIN routing wrong — gameover params missing `mode/levelNum/stageNum`
- ✅ Bomb Squad achievement never triggered — `usedBomb` was bool not int

### Reported but not yet fixed (screenshots incoming from owner)
- ⚠️  Unknown bugs from owner testing — awaiting screenshots
- ⚠️  Combo label may clip off-screen on very small phones
- ⚠️  Score box overflow for very large numbers (scoreDisplay() handles K/M but
       box may not resize — check on small screens)

### Suspected issues to investigate
- Mania mode gravity flip animation: tiles may not reposition correctly when
  gravity changes from "down" to "left" (syncGravity uses animateFall which
  only moves Y, not X — check animateFallH is called for horizontal gravity)
- Daily challenge seed: not tested — loadDailyChallenge() exists in saveState
  but the UI to launch a daily challenge does not exist yet
- levelLoader fallback: if `data/levels/intermediate/level_NNN.lua` is missing,
  it returns a random board with `goal="reach"` and `target=5+(num/10)`.
  Verify this doesn't cause issues at the win-check in checkEndConditions.

---

## 14. SOLAR2D CRITICAL PITFALLS

| # | Pitfall | Fix |
|---|---------|-----|
| 1 | Move `.num` in gravity without `.obj` | Move full `{num,isBomb,isHotZone,obj}` snapshot together |
| 2 | Read `obj.x/y` for bomb position after gravity | Use `gridToScreen(cell.i, cell.j)` — always correct |
| 3 | No `_touchEnabled` guard | Lock at TOP of tap handler before any async work |
| 4 | `_endSession` called before defined | `local _endSession` forward decl, then `_endSession = function()` |
| 5 | `usedBomb` bool not int | Use `bombsUsedCount` int for achievement counting |
| 6 | `audio.loadSound()` in scene:create | Pre-load in `audioHelper.init()` at boot |
| 7 | Gameover missing mode context | Always pass `mode`, `levelNum`, `stageNum` in params |
| 8 | Global variables | All state as `local` at module level |
| 9 | `display.remove()` without nil check in onComplete | `if obj and obj.parent then display.remove(obj) end` |
| 10 | Runtime:addEventListener without remove | Pair add/remove in scene:show/hide |
| 11 | `composer.recycleOnSceneChange = true` with game scene | Keep `false` — game state must survive overlay |
| 12 | Transition on already-removed object | `transition.cancel(obj)` before any new transition |
| 13 | `setBombPulse` on non-bomb tile | Guard: `if not tileObj._bombRing then return end` |

---

## 15. SCENE NAVIGATION MAP

```
menu.lua
  ├─ PLAY / CONTINUE → game.lua (mode="basic")
  ├─ LEVELS → levelSelect.lua
  │    └─ tap level → game.lua (mode="intermediate", levelNum=N, levelData=...)
  ├─ STAGES → stageSelect.lua
  │    └─ tap stage → game.lua (mode="advanced", stageNum=N, levelData=...)
  ├─ MANIA → mania.lua
  ├─ ⚙ → settings.lua (modal overlay)
  └─ 📊 → stats.lua (modal overlay)

game.lua
  └─ game over / win → gameover.lua (modal overlay)
       ├─ PLAY AGAIN → game.lua (same mode/level/stage)
       └─ MAIN MENU → menu.lua

mania.lua
  └─ game over → gameover.lua (modal overlay, params.isMania=true)
       ├─ PLAY AGAIN → mania.lua (fresh game)
       └─ MAIN MENU → menu.lua
```

---

## 16. VISUAL DESIGN SYSTEM

### Colour palette (all in settings.COLOR)
- **Background:** `#212229` (deep charcoal)
- **Grid panel:** `#2E2E38`
- **Empty cell:** `#383842`
- **Score gold:** `#FFBF4D`
- **Best green:** `#99DE99`
- **Button orange:** `#FF7845`
- **Combo yellow:** `#FFD733`
- **Chain mint:** `#66FF99`
- **Bomb red:** `#FF4019`

### Tile colours (index = tile value, wraps cyclically for endless mode)
1. Sky blue · 2. Mint green · 3. Yellow · 4. Salmon · 5. Lavender
6. Teal · 7. Coral · 8. Amber · 9. Cornflower · 10. Bright red (win)
11. Violet (endless) · 12. Dodger blue (endless)

### Typography
- Font NORMAL: `"OpenSans"` — labels, subtitles, hints
- Font BOLD: `"OpenSans-Bold"` — tile numbers, scores, buttons
- Tile number size: 23px (< 10) or 20px (≥ 10)
- Score display: 40px, gold
- Button label: 16-18px, white

### Grid layout
- Canvas: 320 × 568 (letterBox, works on all phones)
- Tile size: 60px with 4px gap (tile display = 56px)
- Corner radius: 8px
- Grid offset: `contentCenterY + 30` (shifts down to leave header room)
- Header height: 76px (score/best boxes at y=38, menu btn at y=38)

### Animation timings (all in settings.VISUAL)
- Merge slide: 110ms (inQuad)
- Tile fall: 70ms (outBounce) — the bounce makes it feel physical
- New tile spawn: 120ms (outQuad)
- Score pop: 140ms (outElastic) at ×1.4 scale
- Score roll-up: 400ms, 20 steps
- Intro stagger: 800ms delay + 25ms per tile + 400ms fade

---

## 17. MANIA MODE SPECIFICS

Mania is in `scenes/mania.lua` — a SEPARATE scene from `scenes/game.lua`.
Do NOT merge them. Mania has fundamentally different timer ownership.

### Mania-only timers (cancel ALL in scene:hide AND scene:destroy)
```lua
_autoDropTimer   -- fires every 8000ms: drops one tile into first empty cell
_gravityTimer    -- fires every 60000ms: rotates gravity direction
```

### Gravity cycle
`"down"` → `"left"` → `"up"` → `"right"` → `"down"` (repeating)

When gravity rotates:
1. `GL.applyGravity(_grid, newDir)` — move logical data
2. `syncGravity()` — animate display objects to new positions
3. Flash the gravity arrow indicator

### Ratcheting multiplier
```lua
_maniaMult = 1.0
-- every MULT_STEP_MERGES (10) merges:
_maniaMult = _maniaMult + MULT_STEP_SIZE (0.1)
-- no cap — can reach ×5, ×10, ×50 in a very long game
-- all scores = floor(base_score * _maniaMult)
```

### Auto-drop countdown bar
- Thin rect at top of grid, full width
- Animates from 100% to 0% over `FALL_INTERVAL_MS` (8000ms)
- Resets to 100% on every player merge (reward for staying active)
- Turns red when it hits 0

### Game over condition
Board is completely full AND `GL.hasMoves()` returns false.
(Not just no moves — next auto-drop might create new merge opportunities.)

---

## 18. HOW TO ADD MORE INTERMEDIATE LEVELS

Create `data/levels/intermediate/level_NNN.lua` (NNN = 011 to 050):

```lua
return {
    name   = "Level Name",
    goal   = "reach",      -- or "clear", "score", "survive"
    target = 7,
    moves  = 25,           -- nil = unlimited
    par    = 18,
    noBomb = false,
    hint   = "Short encouraging tip",
    grid   = {
        -- 5 rows × 5 cols
        -- number = starting tile value
        -- 0      = empty active cell (will be filled)
        -- nil    = inactive cell (shaped board)
        {1,2,3,2,1},
        {2,3,2,3,2},
        {3,2,3,2,3},
        {2,3,2,3,2},
        {1,2,3,2,1},
    },
}
```

Levels unlock sequentially (level N+1 unlocks when N earns ≥ 1 star).
Level 1 is always unlocked.

**Goal types:**
- `"reach"` — target = tile value to reach
- `"clear"` — target = 0, must remove ALL tiles
- `"score"` — target = score to reach within move limit
- `"survive"` — target = number of merges to perform

**Star rating:**
- ★ = completed goal
- ★★ = completed within `par` moves
- ★★★ = completed within `par` moves AND no bomb used

---

## 19. HOW TO ADD HAND-CRAFTED ADVANCED STAGES

Create `data/levels/advanced/stage_NNNN.lua` (NNNN = 0001 to 0999):

```lua
return {
    name    = "Stage 42: The Ring",
    chapter = 5,            -- floor((stageNum-1)/10) + 1
    theme   = "Space",      -- affects UI tint (handled by stageSelect)
    grid    = {
        {nil, 1, 1, 1, nil},
        {1,   1, nil,1, 1 },
        {1,  nil,nil,nil,1 },
        {1,   1, nil,1, 1 },
        {nil, 1, 1, 1, nil},
    },
    goal    = "reach",
    target  = 10,
    winTile = 10,
    hint    = "Clear the ring — the hole in the middle changes everything.",
    noBomb  = false,
}
```

If a stage file is missing, `levelLoader._generateStage(num)` creates one
procedurally (more holes as stage number increases).

**Chapter themes (10 stages each, cycling):**
Classic → Ocean → Fire → Forest → Space → Ice → Desert → Neon → Candy → Void

---

## 20. BUILD SETTINGS (create build.settings when ready to ship)

```lua
-- build.settings
settings = {
    orientation = {
        default   = "portrait",
        supported = { "portrait" },
    },
    iphone = {
        plist = {
            UIStatusBarHidden          = true,
            UIRequiresFullScreen       = true,
            CFBundleDisplayName        = "Get 10",
            CFBundleVersion            = "1.0.0",
            CFBundleShortVersionString = "1.0",
            NSMotionUsageDescription   = "Used for haptic feedback on tile merges.",
        },
    },
    android = {
        versionCode   = 1,
        versionName   = "1.0",
        minSdkVersion = "21",
    },
    plugins = {
        -- Uncomment when adding ads:
        -- ["plugin.admob"] = { publisherId = "com.coronalabs" },
    },
}
```

---

## 21. AUDIO FILES NEEDED

Place these .mp3 files in `app/assets/audio/`:

```
1.mp3 – 13.mp3      Musical tones, ascending (one per tile value)
button_tap.mp3      Short UI click
blocks_clear.mp3    Satisfying whoosh (used for bomb blast)
endgame_win.mp3     Win fanfare
endgame_lose.mp3    Game over sound
endgame_highscore.mp3  Triumphant new record sound
```

**Free sources:**
- https://freesound.org  (Creative Commons)
- https://mixkit.co/free-sound-effects/
- https://zapsplat.com

The game runs silently without these files — `audioHelper` loads with
`if h then _sounds[key] = h end` so missing files never crash the game.

---

## 22. QUICK REFERENCE — FUNCTION SIGNATURES

### gameLogic.lua (GL)
```lua
GL.buildGrid()                        → grid
GL.populateGrid(grid, maxTile, saved) → (modifies grid)
GL.randomTileNum(maxTile)             → number
GL.getConnected(grid, i, j)           → array of cells
GL.findNearMiss(grid, i, j)           → cell or nil
GL.applyGravity(grid, gravityDir)     → (modifies grid)
GL.findChains(grid)                   → array of groups
GL.executeChain(grid, group)          → destCell, mergedNum
GL.hasMoves(grid)                     → boolean
GL.plantBomb(grid)                    → cell or nil
GL.getBombBlast(grid, i, j)           → array of cells
GL.refreshHotZones(grid, shouldClear) → (modifies grid)
```

### scoreHelper.lua (SH)
```lua
SH.calculate(tileNum, count, comboMult, isHotZone) → integer
SH.chainScore(mergedNum, groupSize, chainDepth)    → integer
SH.bombScore(blastCells)                           → integer
SH.toXP(score)                                     → integer
SH.scoreDisplay(n)                                 → string ("1.2K", "954")
```

### saveState.lua (SS)
```lua
SS.init()
SS.save(score, grid, maxTile)
SS.load()                              → {score, allTiles, maxTile} or nil
SS.clear()
SS.loadStats()                         → stats table
SS.updateStats(session)                → updated stats table
SS.loadStreak()                        → streak table (with recentDays[1..7])
SS.updateStreak()                      → updated streak table
SS.unlockAchievement(id)               → true if NEW unlock, false if already had
SS.loadAchievements()                  → { [id]=true, ... }
SS.saveAdvancedStage(N)
SS.loadAdvancedStage()                 → integer
SS.saveIntermediateStars(level, stars)
SS.loadIntermediateStars()             → { ["1"]=3, ["2"]=1, ... }
SS.loadDailyChallenge()                → { date, seed, score, completed }
SS.saveDailyChallengeScore(score)
```

### achievementHelper.lua (AH)
```lua
AH.check(session, stats)    → array of newly unlocked { id, name, desc, icon }
AH.all()                    → full list with .unlocked flag
AH.rankFromXP(totalXP)      → rankIdx, rankName, xpToNext
AH.nextRankXP(rankIdx)      → XP threshold for next rank or nil
```

### tile.lua (Tile)
```lua
Tile.new(num, isBomb, isEndlessGlow)         → DisplayGroup
Tile.upgrade(tileData, parent, tapCB)        → (modifies tileData.obj)
Tile.animateMerge(obj, destX, destY)
Tile.animateFall(obj, newY)
Tile.animateFallH(obj, newX)                 -- horizontal (Mania)
Tile.spawnParticles(parent, x, y, color)
Tile.setBombPulse(obj, enabled)
Tile.spawnBombBlast(parent, x, y)
```

---

## 23. SESSION LOG (full history)

| Date       | Version | What changed |
|------------|---------|--------------|
| 2026-03-02 | v3.0.0  | Three-layer architecture refactor from original v2 code |
| 2026-03-03 | v3.1.0  | Combo streak, bomb tiles, particles, score pop, dark theme |
| 2026-03-03 | v3.2.0  | Gravity .obj bug fix, nil crash fix, bomb position fix |
| 2026-03-03 | v3.3.0  | Chain reactions, bomb redesign (cross not 8-way), hot zones |
| 2026-03-04 | v4.0.0  | Full feature complete: undo, near-miss, dynamic bg, endless, |
|            |         | score roll-up, full stats/achievements/XP/streak system,      |
|            |         | Mania mode, Intermediate framework + 10 levels,               |
|            |         | Advanced 999-stage framework, levelSelect + stageSelect UI,   |
|            |         | gameover PLAY AGAIN routing fixed, bomb count int fix          |

---

## 24. OWNER PREFERENCES & DECISIONS

- **Engine:** Solar2D only for now. Godot considered but deferred.
- **Strategy:** Ship Get10 first, then build other games on same architecture.
- **Monetisation:** Free with ads + IAP to remove. AdMob first.
- **Content:** Endless mode more important than 999 stages for initial ship.
- **Code quality:** Full documentation on every function. Claude Code must
  maintain the same comment density as the existing files.
- **No interaction during work:** Claude Code should work through tasks
  autonomously and only surface a build when it reaches a testable milestone.

---

---

## 25. BRICK MODE — UNLOCK RULES & OPEN DECISIONS

### Current unlock rule (scenes/levelSelect.lua → computeUnlocked)
```lua
_unlocked[n] = (_allStars[n - 1] or 0) >= 1
-- Level N unlocks when level N-1 has ≥ 1 star (goal completed, any condition).
```

### DEV unlock flag (remove before release)
```lua
-- scenes/levelSelect.lua line ~70:
local DEV_UNLOCK_ALL = true    -- testing: all 50 unlocked
local DEV_UNLOCK_ALL = false   -- release: sequential unlock restored
```

### Open decision — what should "unlock" require?
Options discussed but not decided:

| Option | Rule | Notes |
|--------|------|-------|
| A (current) | ≥ 1 star (goal met, any way) | Easiest — most players progress |
| B | ≥ 2 stars (goal met within par moves) | Medium gate — rewards efficiency |
| C | ≥ 3 stars (goal + par + no bomb) | Hard gate — may frustrate casuals |
| D | Reach tile 10 on previous level | Specific tile target regardless of goal type |

**Recommendation:** Keep Option A for retention. Gate progression generously —
the difficulty comes from brick patterns and goal types, not from replaying.

### Brick brick count formula
```
bricks = 2 + floor((levelNum - 1) / 5)
Level 1–5:  2 bricks    Level 26–30: 7 bricks
Level 6–10: 3 bricks    Level 31–35: 8 bricks
Level 11–15: 4 bricks   Level 36–40: 9 bricks
Level 16–20: 5 bricks   Level 41–45: 10 bricks
Level 21–25: 6 bricks   Level 46–50: 11 bricks  (11/36 cells = 30% blocked)
```

### Brick positions
Stored in `data/levels/bricks.json` — edit freely, no Lua needed.
Format: `{"1": [{"row": R, "col": C}, ...], "2": [...]}` (1-based coords).

---

## 26. PLAYER RETENTION & AD REVENUE STRATEGY

**Business model:** Free + ads (AdMob). Revenue = DAU × sessions/day × ad impressions/session.
Every decision below is aimed at maximising those three numbers.

---

### A. The Core Loop Must Feel Rewarding, Not Punishing

The number-one cause of uninstall in hyper-casual is **frustration without hope**.
Every loss must feel like the player's fault, not the game's.

- ✅ Already have: near-miss flash ("So close!"), dynamic background warning (red = low moves)
- ✅ Already have: undo system (reduces frustration on one bad tap)
- 🔲 TODO: After a loss, show "Your best tile was X" — pride, not shame
- 🔲 TODO: "You were 2 merges away!" message on game over screen

---

### B. Daily Return Hooks (DAU drivers)

| Feature | Impact | Effort |
|---------|--------|--------|
| **Daily Challenge level** — unique brick layout, resets midnight | Very high | Medium |
| **Daily streak calendar** (already built!) | High | Done ✅ |
| **"Come back in Xh for your next life"** energy system | Medium | Medium |
| **Daily reward** — watch ad to get a free hint/undo for the day | High | Low |
| **Push notification** — "Your daily challenge is waiting!" | High | Medium |

**Priority:** Daily Challenge is the single biggest DAU driver. One hand-crafted
6×6 brick layout per day. Can be server-driven or hard-coded for a year upfront.

---

### C. Session Length Drivers (impressions/session)

Longer sessions = more ad slots. These mechanics keep people in the app:

| Mechanic | How it works |
|----------|-------------|
| **"One more try"** | After loss, restart is instant. No friction. Already works ✅ |
| **Star re-run motivation** | 1-star levels show a banner: "Can you beat par?" |
| **Combo + chain feedback** | Big visual reward for skill = dopamine loop. Already works ✅ |
| **Level name + personality** | "The Cross", "Speed Run" make levels feel memorable |
| **Progress bar per page** | "You've earned 9/12 stars on page 1" — completion pull |
| **Endless mode** | After beating level 50, brick mode enters endless procedural. Infinite play. |

---

### D. Ad Placement Strategy (player-friendly order)

**Rule:** Ads shown after a win feel like a reward. Ads shown after a loss feel like punishment. Always prefer post-win.

```
1. Rewarded video (highest CPM, player-initiated — never irritating)
   - "Watch to get +3 moves"          ← show when out of moves (move-limit levels)
   - "Watch to get 1 free undo"       ← show after player runs out
   - "Watch to unlock a hint"         ← flash the best available merge
   - "Watch to see your next level preview"

2. Interstitial (automatic, must be controlled carefully)
   - Show ONLY after level WIN (never after loss)
   - Max once every 3 level completions
   - Never on the first 5 levels (let player get hooked first)
   - 5-minute cooldown between shows

3. Banner (passive, lowest CPM)
   - levelSelect screen only
   - Never during gameplay
   - Never on menu if it looks cheap — test both ways
```

---

### E. Psychological Hooks Already In the Game (leverage these)

| Hook | Mechanism | Status |
|------|-----------|--------|
| **Sunk cost** | Stars per level — beat with 1 star, feel pull to get 3 | ✅ built |
| **Collection** | Total star count across 50 levels | ✅ built, needs UI highlight |
| **Mastery** | XP → rank (Novice → Legend) | ✅ built |
| **Streak** | 7-day calendar | ✅ built |
| **Near-miss** | "So close!" flash | ✅ built |
| **Escalation** | 2→11 bricks over 50 levels | ✅ designed |
| **Named levels** | "The Fortress", "Speed Run" | ✅ first 10 named |

---

### F. Retention Anti-patterns to Avoid

- ❌ **Ads after every level** — kills DAU faster than anything else
- ❌ **Impossible levels early** — frustration at level 5 = uninstall
- ❌ **No feedback on fail** — player doesn't know why they lost
- ❌ **Slow restart** — any friction on "try again" loses the "one more" player
- ❌ **Energy/lives system** — works for mid-core, kills hyper-casual DAU
- ❌ **Too many popups on first launch** — rate us / notifications / ads = instant quit

---

### G. Priority Implementation Order (bang for buck)

1. **Daily Challenge** — biggest DAU driver, implement before launch
2. **Rewarded ad for +3 moves** — highest CPM, lowest frustration
3. **Post-win interstitial** (levels 6+, max 1 per 3 wins)
4. **"Star re-run" prompt** — after level end, show star gap and "beat your record"
5. **Progress bar on level select** — completion pull keeps players in the mode
6. **Endless procedural Brick mode** — infinite content after level 50
7. **Push notifications** — daily challenge reminder
8. **Banner on level select** — passive income while browsing levels

---

*End of HandOff2ClaudeCode.md*
*Get10 v4.0 — Solar2D / Lua — updated 2026-03-08*
