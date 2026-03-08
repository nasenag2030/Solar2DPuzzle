# Solar2D Game Architecture — Master Knowledge File v2.0
# ═══════════════════════════════════════════════════════════════════
# PURPOSE:
#   Drop this file into any new conversation with Claude.
#   It captures every pattern, pitfall, and solution learned from
#   building Get10 v4.0 — a fully-shipped hyper-casual mobile game
#   with Basic / Intermediate / Advanced / Mania modes.
#
# HOW TO USE:
#   Start your message with:
#   "Solar2D project. Here is my architecture file. [paste this file]
#    Now here is my code: [your files]"
#
# VERSION: 2.0  |  DATE: 2026-03-04
# Built from: Get10 v4.0 (30 Lua files, 4 game modes, full progression)
# ═══════════════════════════════════════════════════════════════════

---

## 1. THE THREE-LAYER ARCHITECTURE (non-negotiable)

Every Solar2D game should use this structure. No exceptions.

```
┌──────────────────────────────────────────────────────────────┐
│  LAYER 3 — SCENES  (scenes/*.lua)                            │
│  • Owns all display objects                                   │
│  • Listens for player input, routes to helpers               │
│  • Runs animations and timers                                 │
│  • NEVER contains game rules or SQL                          │
├──────────────────────────────────────────────────────────────┤
│  LAYER 2 — HELPERS  (app/helpers/*.lua)                      │
│  • Pure logic — no display, no transition, no Corona APIs    │
│  • gameLogic, scoreHelper, audioHelper, saveState            │
│  • achievementHelper, levelLoader                            │
│  • Can be unit-tested without a running Corona instance      │
├──────────────────────────────────────────────────────────────┤
│  LAYER 1 — DATA  (app/models/*.lua)                          │
│  • All persistence: SQLite via dbModel, user prefs           │
│  • settingsModel (sound on/off, high score, first-run)       │
│  • NEVER contains display or game logic                      │
└──────────────────────────────────────────────────────────────┘

SHARED EVERYWHERE (no layer restriction):
  config/settings.lua     ← ALL constants. One file, one truth.
  app/components/*.lua    ← Reusable display objects (Tile, Button…)
```

### Dependency rules (STRICT)
- Scenes may require helpers and models. ✅
- Helpers may require models and settings. ✅
- Models may only require dbModel and settings. ✅
- NO helper may require a scene. ❌
- NO helper may call display.*, transition.*, or timer.*. ❌
- NO model may contain game logic. ❌

---

## 2. CANONICAL FOLDER STRUCTURE

```
Corona/
├── main.lua                        ← boot only: init DB, audio, go to menu
├── config.lua                      ← display/content settings (320×568 base)
├── config/
│   └── settings.lua                ← ALL constants (see section 4)
├── scenes/
│   ├── menu.lua                    ← mode select, rank bar, streak badge
│   ├── game.lua                    ← main game scene (Basic + level/stage mode)
│   ├── gameover.lua                ← win/lose overlay (modal)
│   ├── settings.lua                ← sound toggle, how-to-play (modal overlay)
│   ├── stats.lua                   ← lifetime stats + achievements (modal overlay)
│   ├── levelSelect.lua             ← Intermediate: scrollable 50-level grid
│   ├── stageSelect.lua             ← Advanced: 999-stage scrollable grid
│   └── mania.lua                   ← Mania: separate scene (has own timers)
├── app/
│   ├── components/
│   │   └── tile.lua                ← tile display component (no logic)
│   ├── helpers/
│   │   ├── gameLogic.lua           ← pure game rules (grid, gravity, chains)
│   │   ├── scoreHelper.lua         ← all scoring math
│   │   ├── audioHelper.lua         ← pre-load + play sounds
│   │   ├── saveState.lua           ← game resume, stats, streak, achievements
│   │   ├── achievementHelper.lua   ← achievement definitions + check()
│   │   └── levelLoader.lua         ← load level/stage data files
│   ├── models/
│   │   ├── dbModel.lua             ← raw SQLite wrapper
│   │   └── settingsModel.lua       ← sound on/off, high score, first-run
│   └── assets/
│       └── audio/                  ← all .mp3 files (see section 9)
└── data/
    └── levels/
        ├── intermediate/           ← level_001.lua … level_050.lua
        └── advanced/               ← stage_0001.lua … stage_0999.lua
```

---

## 3. STANDARD SCENE TEMPLATE

Copy this for every new scene. Fill in the blanks.

```lua
-----------------------------------------------------------------------------------------
-- scenes/myScene.lua
-- [One sentence: what this scene does and what it owns]
--
-- WHAT THIS FILE DOES:
-- SCENE FLOW:
-- CHANGELOG:
--   v1.0  YYYY-MM-DD  Initial
-----------------------------------------------------------------------------------------

local composer = require("composer")
local settings = require("config.settings")
-- local GL     = require("app.helpers.gameLogic")   -- add as needed

local scene = composer.newScene()

-- ── Module-level state ─────────────────────────────────────────────────────────
-- Declare ALL local variables here. Reset them in scene:create or a buildX() fn.
local _sceneGroup   -- top-level view
local _touchEnabled = true

-- Forward-declare any functions that call each other before definition
local myForwardFn

-- ── Private functions ─────────────────────────────────────────────────────────

local function doSomething()
end

myForwardFn = function()
    doSomething()
end

-- ── Scene lifecycle ───────────────────────────────────────────────────────────

function scene:create( event )
    _sceneGroup = self.view
    local params = event.params or {}

    -- Build all display objects here.
    -- Do NOT start animations or timers here.
    -- Use params to receive data from the calling scene.
end

function scene:show( event )
    if event.phase == "will" then
        -- Scene is about to appear. Reset state, prepare labels.
        _touchEnabled = true
    elseif event.phase == "did" then
        -- Scene is fully visible. Start timers, play music.
    end
end

function scene:hide( event )
    if event.phase == "will" then
        -- About to leave. Save state, stop gameplay timers.
        _touchEnabled = false
    elseif event.phase == "did" then
        -- Fully hidden. Cancel any remaining transitions.
    end
end

function scene:destroy( event )
    -- Composer cleans up display groups automatically.
    -- Manually cancel only Runtime: listeners and timers here.
end

scene:addEventListener( "create",  scene )
scene:addEventListener( "show",    scene )
scene:addEventListener( "hide",    scene )
scene:addEventListener( "destroy", scene )

return scene
```

---

## 4. SETTINGS.LUA — COMPLETE TEMPLATE

Every constant lives here. Never hardcode numbers in scenes or helpers.

```lua
-- config/settings.lua

local S = {}

-- ── Version ────────────────────────────────────────────────────────────────────
S.VERSION     = { major=1, minor=0, patch=0 }
S.VERSION_STR = "v1.0"

-- ── Game rules ─────────────────────────────────────────────────────────────────
S.GAME = {}
S.GAME.GRID_SIZE      = 5
S.GAME.WIN_TILE       = 10
S.GAME.START_MAX_TILE = 5
S.GAME.TILE_WEIGHTS   = { 50, 40, 20, 10, 5, 3, 2 }  -- weighted random spawn

-- ── Combo streak ───────────────────────────────────────────────────────────────
S.COMBO = {}
S.COMBO.WINDOW_MS  = 2000   -- ms between merges to keep streak
S.COMBO.MAX_MULT   = 5      -- max multiplier
S.COMBO.LABEL_TIME = 900    -- how long banner stays visible

-- ── Chain reaction ─────────────────────────────────────────────────────────────
S.CHAIN = {}
S.CHAIN.MAX_DEPTH        = 10    -- safety cap
S.CHAIN.BONUS_MULTIPLIER = 1.5
S.CHAIN.ANIM_MS          = 120
S.CHAIN.DELAY_MS         = 180

-- ── Undo system ────────────────────────────────────────────────────────────────
S.UNDO = {}
S.UNDO.FREE_PER_GAME = 1
S.UNDO.ANIM_MS       = 250

-- ── Bomb tile ──────────────────────────────────────────────────────────────────
S.BOMB = {}
S.BOMB.MERGE_INTERVAL = 12
S.BOMB.SPAWN_MAX_NUM  = 3
S.BOMB.PULSE_TIME     = 700
S.BOMB.SCORE_PER_NUM  = 8

-- ── Hot zones ──────────────────────────────────────────────────────────────────
S.HOT_ZONE = {}
S.HOT_ZONE.COUNT          = 2
S.HOT_ZONE.MULT           = 2
S.HOT_ZONE.RESPAWN_MERGES = 5
S.HOT_ZONE.PULSE_MS       = 800

-- ── Near-miss ──────────────────────────────────────────────────────────────────
S.NEAR_MISS = {}
S.NEAR_MISS.FLASH_MS    = 120
S.NEAR_MISS.FLASH_COUNT = 3
S.NEAR_MISS.LABEL_MS    = 800

-- ── Endless mode ───────────────────────────────────────────────────────────────
S.ENDLESS = {}
S.ENDLESS.ENABLED         = true
S.ENDLESS.EXTRA_WIN_BONUS = 500
S.ENDLESS.MILESTONE_STEP  = 1

-- ── Mania mode ─────────────────────────────────────────────────────────────────
S.MANIA = {}
S.MANIA.FALL_INTERVAL_MS  = 8000
S.MANIA.GRAVITY_FLIP_MS   = 60000
S.MANIA.MULT_STEP_MERGES  = 10
S.MANIA.MULT_STEP_SIZE    = 0.1
S.MANIA.BOMB_INTERVAL     = 8

-- ── XP & Rank ──────────────────────────────────────────────────────────────────
S.XP = {}
S.XP.DIVISOR         = 10
S.XP.RANK_NAMES      = { "Novice", "Skilled", "Expert", "Master", "Legend" }
S.XP.RANK_THRESHOLDS = { 0, 500, 2000, 6000, 15000 }

-- ── Daily challenge ────────────────────────────────────────────────────────────
S.DAILY = {}
S.DAILY.SEED_OFFSET = 20260303

-- ── Advanced mode ──────────────────────────────────────────────────────────────
S.ADVANCED = {}
S.ADVANCED.TOTAL_STAGES = 999
S.ADVANCED.WIN_TILE_BY_BRACKET = {
    [1]=10, [101]=12, [301]=14, [601]=16
}
S.ADVANCED.STAGES_PER_CHAPTER = 10

-- ── Visual ─────────────────────────────────────────────────────────────────────
S.VISUAL = {}
S.VISUAL.TILE_SIZE      = 60
S.VISUAL.TILE_CORNER    = 8
S.VISUAL.MERGE_ANIM_MS  = 110
S.VISUAL.FALL_ANIM_MS   = 70
S.VISUAL.SPAWN_ANIM_MS  = 120
S.VISUAL.INTRO_DELAY_MS = 800
S.VISUAL.INTRO_STEP_MS  = 25
S.VISUAL.INTRO_FADE_MS  = 400
S.VISUAL.SCORE_POP_SCALE    = 1.40
S.VISUAL.SCORE_POP_MS       = 140
S.VISUAL.SCORE_ROLLUP_MS    = 400
S.VISUAL.SCORE_ROLLUP_STEPS = 20
S.VISUAL.PARTICLE_COUNT  = 8
S.VISUAL.PARTICLE_RADIUS = 28
S.VISUAL.PARTICLE_MS     = 380
S.VISUAL.HIGHLIGHT_ALPHA = 0.55
S.VISUAL.HIGHLIGHT_MS    = 120
S.VISUAL.BG_TINT_MS      = 800
S.VISUAL.BG_TINT_COMBO   = { 0.22, 0.18, 0.08 }
S.VISUAL.BG_TINT_CHAIN   = { 0.08, 0.22, 0.15 }
S.VISUAL.BG_TINT_DANGER  = { 0.22, 0.08, 0.08 }
S.VISUAL.BG_TINT_NORMAL  = { 0.13, 0.13, 0.17 }
S.VISUAL.UNDO_FLASH_COLOR = { 0.6, 0.8, 1.0, 0.3 }

-- ── Fonts ──────────────────────────────────────────────────────────────────────
S.FONT = {}
S.FONT.NORMAL = "OpenSans"
S.FONT.BOLD   = "OpenSans-Bold"

-- ── Colours (RGB 0-1 float) ────────────────────────────────────────────────────
S.COLOR = {}
S.COLOR.BACKGROUND       = { 0.13, 0.13, 0.17 }
S.COLOR.GRID_BG          = { 0.18, 0.18, 0.22 }
S.COLOR.GRID_CELL        = { 0.22, 0.22, 0.28 }
S.COLOR.SCORE            = { 1.00, 0.75, 0.30 }
S.COLOR.HIGH_SCORE       = { 0.60, 0.87, 0.60 }
S.COLOR.BUTTON_PRIMARY   = { 1.00, 0.47, 0.27 }
S.COLOR.BUTTON_SECONDARY = { 0.38, 0.38, 0.48 }
S.COLOR.COMBO_LABEL      = { 1.00, 0.84, 0.20 }
S.COLOR.CHAIN_LABEL      = { 0.40, 1.00, 0.70 }
S.COLOR.BOMB_GLOW        = { 1.00, 0.25, 0.10 }
S.COLOR.HOT_ZONE         = { 1.00, 0.90, 0.20 }
S.COLOR.UNDO_BTN         = { 0.35, 0.65, 1.00 }
S.COLOR.TILE_TEXT_DARK   = { 0.15, 0.15, 0.15 }
S.COLOR.TILE_TEXT_LIGHT  = { 1.00, 1.00, 1.00 }
S.COLOR.ENDLESS_GLOW     = { 1.00, 0.90, 0.30 }
S.COLOR.HOT_ZONE_OVERLAY = { 1.00, 0.90, 0.10, 0.30 }
S.COLOR.RANK = {
    { 0.70, 0.70, 0.75 },   -- Novice
    { 0.30, 0.75, 0.95 },   -- Skilled
    { 0.30, 0.90, 0.50 },   -- Expert
    { 1.00, 0.75, 0.20 },   -- Master
    { 1.00, 0.35, 0.90 },   -- Legend
}
S.COLOR.TILE = {
    {  25/255, 181/255, 254/255 },   --  1  sky blue
    { 106/255, 217/255, 126/255 },   --  2  mint green
    { 255/255, 213/255,  79/255 },   --  3  yellow
    { 255/255, 143/255, 107/255 },   --  4  salmon
    { 190/255, 144/255, 212/255 },   --  5  lavender
    {  54/255, 215/255, 183/255 },   --  6  teal
    { 255/255, 107/255, 107/255 },   --  7  coral
    { 249/255, 168/255,  38/255 },   --  8  amber
    { 117/255, 176/255, 244/255 },   --  9  cornflower
    { 255/255,  75/255,  75/255 },   -- 10  bright red (WIN)
    {  91/255,  50/255,  86/255 },   -- 11  violet (endless)
    {  52/255, 152/255, 219/255 },   -- 12  dodger blue (endless)
}

return S
```

---

## 5. GRID DATA STRUCTURE (for tile-based games)

The grid is the most important structure. Get it right or you'll fight bugs forever.

```lua
-- Each cell in the grid is a table:
grid[i][j] = {
    num       = number|nil,   -- tile value (nil = empty)
    i         = number,       -- row  (1=top, GRID=bottom)
    j         = number,       -- col  (1=left, GRID=right)
    isBomb    = boolean,
    isHotZone = boolean,      -- scoring modifier flag
    obj       = DisplayGroup, -- the live display object
    _visited  = boolean,      -- internal flood-fill flag
}
```

### THE MOST IMPORTANT RULE: gravity must move .obj with .num

```lua
-- WRONG — causes tiles to vanish after merge:
function applyGravity(grid)
    -- ... moves cell.num down but leaves cell.obj on original row
    -- syncDisplay() finds num but no obj → skips animation
    -- removeOrphans() finds obj with no num → deletes it
    -- Tile disappears instead of sliding
end

-- CORRECT — snapshot the full triplet and move everything together:
function applyGravity(grid)
    for j = 1, GRID do
        -- Step 1: collect occupied cells as snapshots
        local tiles = {}
        for i = 1, GRID do
            if grid[i][j].num then
                tiles[#tiles+1] = {
                    num       = grid[i][j].num,
                    isBomb    = grid[i][j].isBomb,
                    isHotZone = grid[i][j].isHotZone,
                    obj       = grid[i][j].obj,   -- ← CRITICAL
                }
            end
        end
        -- Step 2: clear column
        for i = 1, GRID do
            grid[i][j].num = nil; grid[i][j].obj = nil
            grid[i][j].isBomb = false; grid[i][j].isHotZone = false
        end
        -- Step 3: re-fill from bottom
        local offset = GRID - #tiles
        for k, t in ipairs(tiles) do
            local row = offset + k
            grid[row][j].num       = t.num
            grid[row][j].isBomb    = t.isBomb
            grid[row][j].isHotZone = t.isHotZone
            grid[row][j].obj       = t.obj
            if t.obj then
                t.obj.i = row   -- ← keep tap handler coords accurate
                t.obj.j = j
            end
        end
    end
end
```

---

## 6. TIMER CHAIN PATTERN (post-merge pipeline)

The canonical way to sequence gravity → chains → win-check after any merge.
All tile games need a pipeline like this.

```lua
-- runPostMerge() — call after every merge or bomb blast
local function runPostMerge( newTileNum, shouldBomb )
    -- Step 1: wait for merge animation, then apply gravity
    timer.performWithDelay(settings.VISUAL.MERGE_ANIM_MS + 20, function()
        GL.applyGravity(_grid, _gravityDir)
        syncDisplayAfterGravity()   -- animate display objects to new positions
        removeOrphanedObjects()     -- clean up objs with no num
        refillEmptyCells()          -- spawn new tiles in empty cells

        -- Step 2: wait for fall animation, then check for chains
        timer.performWithDelay(settings.VISUAL.FALL_ANIM_MS + 30, function()
            doChainStep(1, function()   -- recursive chain processor
                checkEndConditions(newTileNum, shouldBomb)
            end)
        end)
    end)
end

-- doChainStep() — recursive, finds all auto-merge groups
local function doChainStep( depth, onDone )
    if depth > settings.CHAIN.MAX_DEPTH then onDone(); return end

    local chains = GL.findChains(_grid)
    if #chains == 0 then onDone(); return end

    -- process chains visually...
    -- then recurse:
    timer.performWithDelay(settings.CHAIN.ANIM_MS + settings.CHAIN.DELAY_MS, function()
        GL.applyGravity(_grid, _gravityDir)
        syncDisplayAfterGravity()
        removeOrphanedObjects()
        refillEmptyCells()
        timer.performWithDelay(settings.VISUAL.FALL_ANIM_MS + 30, function()
            doChainStep(depth + 1, onDone)   -- ← tail recursion via timer
        end)
    end)
end
```

**Why timers instead of coroutines?** Solar2D's animation system is callback-based.
Coroutines can work but timers are simpler to debug and cancel reliably.

---

## 7. TOUCH / TAP GUARD PATTERN

Rapid tapping causes nil crashes. Always guard with a single boolean.

```lua
local _touchEnabled = true

tileOnTap = function( event )
    if not _touchEnabled then return true end
    _touchEnabled = false   -- LOCK immediately — before any async work

    -- do your work...
    -- at the very end of the pipeline, re-enable:
    -- _touchEnabled = true   (set in checkEndConditions after all timers settle)
    return true
end
```

**Common crash:** accessing `cell.obj` after it was set to nil by a previous tap.
Always nil-guard every display object access:

```lua
local movingObj = cell.obj   -- copy reference first
cell.num = nil               -- clear logical state
cell.obj = nil
if movingObj then            -- ← nil guard
    Tile.animateMerge(movingObj, destX, destY)
end
```

---

## 8. FORWARD DECLARATION PATTERN

Lua requires functions to be defined before they are called — EXCEPT when using
forward declaration. Use this for mutual recursion and event callbacks.

```lua
-- WRONG — crash: tileOnTap used in drawTile before it's defined
local function drawTile(cell)
    obj:addEventListener("tap", tileOnTap)   -- tileOnTap is nil here!
end
local function tileOnTap(event) ... end

-- CORRECT — forward declare, then assign
local tileOnTap   -- forward declaration (value is nil until assigned below)

local function drawTile(cell)
    obj:addEventListener("tap", tileOnTap)   -- ok: reference captured, value assigned later
end

tileOnTap = function( event )   -- note: no "local function" — assigns to existing local
    ...
end

-- Same pattern for _endSession (called from checkEndConditions defined above it):
local _endSession   -- forward declare

local function checkEndConditions(...)
    if gameOver then _endSession(true) end   -- safe
end

_endSession = function( isGameOver )   -- assigned after checkEndConditions
    ...
end
```

---

## 9. AUDIO HELPER — PRODUCTION PATTERN

```lua
-- app/helpers/audioHelper.lua
-- Pre-load ALL sounds at init(). Play anywhere. Fail silently if files missing.

local M = {}
local _sounds  = {}
local _enabled = true
local PATH     = "app/assets/audio/"

local function load(key, file)
    local h = audio.loadSound(PATH .. file)
    if h then _sounds[key] = h end   -- silent fail if file missing
end

function M.init()
    _enabled = settingsModel.getSound()   -- restore from DB

    -- Numbered tones for tile merges (I-09: musical scale per tile)
    for i = 1, 13 do load("num_"..i, i..".mp3") end

    load("tap",       "button_tap.mp3")
    load("win",       "endgame_win.mp3")
    load("lose",      "endgame_lose.mp3")
    load("highscore", "endgame_highscore.mp3")
    load("bomb",      "blocks_clear.mp3")
end

function M.setEnabled(flag)
    _enabled = flag
    settingsModel.setSound(flag)   -- persist immediately
end

local function play(key)
    if not _enabled then return end
    local h = _sounds[key]
    if h then audio.play(h) end
end

-- Haptics (I-01): vibration scaled to tile value
function M.vibrateOnMerge(tileNum)
    if not _enabled then return end
    if not system.vibrate then return end
    local pulses = (tileNum >= 7) and 3 or (tileNum >= 4) and 2 or 1
    for _ = 1, pulses do system.vibrate() end
end

function M.playMerge(num) play("num_"..math.min(num, 13)) end
function M.playTap()      play("tap")        end
function M.playWin()      play("win")        end
function M.playLose()     play("lose")       end
function M.playBomb()     play("bomb")       end
function M.playHighScore() play("highscore") end

return M
```

**Required audio files** (place in `app/assets/audio/`):
```
1.mp3 … 13.mp3       — ascending musical tones (one per tile value)
button_tap.mp3        — short UI click
blocks_clear.mp3      — satisfying whoosh (bomb/clear)
endgame_win.mp3       — win fanfare
endgame_lose.mp3      — lose sound
endgame_highscore.mp3 — triumphant new record
```
Free sources: freesound.org · zapsplat.com · mixkit.co

---

## 10. DATABASE PATTERN (SQLite)

```lua
-- app/models/dbModel.lua — raw wrapper, used by ALL models

local sqlite3 = require("sqlite3")
local M = {}
local _db = nil

function M.init()
    if _db then return end
    _db = sqlite3.open(system.pathForFile("game.db", system.DocumentsDirectory))
end

function M.createTable(name, columns, seedRows)
    local defs = {}
    for col, typedef in pairs(columns) do
        defs[#defs+1] = col.." "..typedef
    end
    _db:exec("CREATE TABLE IF NOT EXISTS "..name.." ("..table.concat(defs,", ")..");")
    if seedRows then
        for row in _db:nrows("SELECT COUNT(*) as cnt FROM "..name..";") do
            if row.cnt == 0 then
                for _, r in ipairs(seedRows) do
                    local cols, vals = {}, {}
                    for k, v in pairs(r) do cols[#cols+1]=k; vals[#vals+1]=tostring(v) end
                    _db:exec("INSERT INTO "..name.." ("..table.concat(cols,",")..") VALUES ("..table.concat(vals,",")..");")
                end
            end
        end
    end
end

function M.getRow(sql)
    for row in _db:nrows(sql) do return row end
    return nil
end

function M.exec(sql) return _db:exec(sql) end

return M
```

**saveState tables** (create all in saveState.init()):

| Table | Key | Value | Purpose |
|-------|-----|-------|---------|
| saveState | state | JSON | current board for resume |
| statsState | stats | JSON | lifetime stats |
| streakState | streak | JSON | daily streak + playDates |
| achievements | data | JSON | unlocked achievement IDs |
| advancedState | stage | INT | furthest advanced stage |
| intermediateState | stars | JSON | star ratings per level |
| dailyState | data | JSON | today's seed + score |
| settings | multiple | INT | sound, highScore, firstRun |

---

## 11. SAVE STATE — COMPLETE PATTERN

```lua
-- Key lifetime stat fields (use EXACTLY these key names):
local STATS_DEFAULT = {
    bestCombo      = 0,   -- largest group merged in one tap
    totalMerges    = 0,   -- lifetime merge count
    highestTile    = 0,   -- highest tile ever reached
    gamesPlayed    = 0,
    totalXP        = 0,   -- cumulative XP (score / XP_DIVISOR)
    bestScore      = 0,   -- highest single-game score (NOT a sum)
    totalBombsUsed = 0,   -- lifetime bomb detonations (int, not bool)
}
```

**Common bug:** tracking usedBomb as `bool` instead of `int`.
The achievement "Bomb Squad — use 10 bombs" needs an int counter.

```lua
-- WRONG:
_session.usedBomb = true

-- CORRECT:
_session.usedBomb = true
_session.bombsUsedCount = (_session.bombsUsedCount or 0) + 1

-- Then in updateStats:
s.totalBombsUsed = s.totalBombsUsed + (session.bombsUsedCount or 0)
```

---

## 12. SCORE HELPER — FORMULAS

```lua
-- Player merge:   floor( num² × (count-1) × comboMult × hotZoneMult )
-- Chain merge:    floor( num² × (count-1) × BONUS_MULT^depth )
-- Bomb blast:     sum( cell.num × SCORE_PER_NUM ) for all destroyed cells
-- XP:             floor( score / XP_DIVISOR )

-- Score display (prevents overflow on small screens):
function M.scoreDisplay(n)
    if n >= 1000000 then return string.format("%.1fM", n/1000000)
    elseif n >= 1000 then return string.format("%.1fK", n/1000)
    else return tostring(math.floor(n)) end
end
```

---

## 13. BOMB PLACEMENT BUG — SOLVED

**The bug:** bomb placed at wrong position after gravity.

**Root cause:** bomb was planted inside `timer.performWithDelay(MERGE_MS + 60)`
while gravity ran at `MERGE_MS + 20`. Gravity moved the tile; bomb read
`cell.obj.x/y` which was the pre-gravity position.

**Fix:** plant the bomb AFTER gravity + refill settle, inside the step-2 timer,
using `gridToScreen(cell.i, cell.j)` (always correct) not `obj.x/y`.

```lua
-- WRONG — planted before gravity:
timer.performWithDelay(MERGE_ANIM_MS + 60, function()
    local bombCell = GL.plantBomb(_grid)
    local x, y = bombCell.obj.x, bombCell.obj.y   -- WRONG: pre-gravity coords
    -- ...
end)
afterMergeSequence()   -- gravity runs here at MERGE_ANIM_MS + 20 ← too late

-- CORRECT — planted after gravity in the step-2 timer:
local function runPostMerge(newTileNum, shouldBomb)
    timer.performWithDelay(MERGE_ANIM_MS + 20, function()
        GL.applyGravity(_grid)   -- gravity first
        -- ...refill...
        timer.performWithDelay(FALL_ANIM_MS + 30, function()
            if shouldBomb then
                local bombCell = GL.plantBomb(_grid)
                local bx, by = gridToScreen(bombCell.i, bombCell.j)  -- ← logical coords
                -- now bx,by are always correct
            end
            checkEndConditions(newTileNum)
        end)
    end)
end
```

---

## 14. MODAL OVERLAY PATTERN

```lua
-- Show overlay from any scene:
composer.showOverlay("scenes.gameover", {
    effect="fromTop", time=300, isModal=true,
    params = {
        score    = _totalScore,
        -- ALWAYS pass mode/levelNum/stageNum so PLAY AGAIN works:
        mode     = _mode,       -- "basic"|"intermediate"|"advanced"
        levelNum = _levelNum,
        stageNum = _stageNum,
    },
})

-- In gameover.lua PLAY AGAIN button, route back correctly:
-- IMPORTANT: always removeScene first so scene:create runs fresh with the correct params.
-- Exception: basic/classic in-place restart reuses the live scene intentionally.
if mode == "intermediate" and levelNum then
    composer.removeScene("scenes.game")
    composer.gotoScene("scenes.game", { params={mode="intermediate", levelNum=levelNum, levelData=data} })
elseif mode == "advanced" and stageNum then
    composer.removeScene("scenes.game")
    composer.gotoScene("scenes.game", { params={mode="advanced", stageNum=stageNum, levelData=data} })
else
    local gs = composer.getScene("scenes.game")
    if gs and gs.restart then gs.restart() end   -- Basic: restart in-place
end
```

---

## 15. LEVEL DATA FORMAT

For Intermediate (50 curated) and Advanced (999 shaped) levels:

```lua
-- data/levels/intermediate/level_001.lua
return {
    name   = "Getting Started",
    goal   = "reach",          -- "reach"|"clear"|"score"|"survive"
    target = 4,                -- tile value (reach), score (score), merges (survive)
    moves  = nil,              -- nil = unlimited
    par    = 8,                -- moves for 3-star rating
    noBomb = false,
    hint   = "Tap matching groups to merge!",
    grid   = {                 -- nil = random fill
        {1,1,2,1,1},
        {2,1,1,2,1},
        {1,2,2,1,2},
        {2,1,1,2,1},
        {1,2,1,1,2},
    },
}

-- data/levels/advanced/stage_0001.lua
return {
    name    = "Stage 1",
    grid    = { ... },   -- nil cells = inactive (shaped board)
    goal    = "reach",
    target  = 10,
    winTile = 10,
    theme   = "Classic",
    hint    = "Chapter 1: Classic",
    noBomb  = false,
}
```

**Advanced stage win-tile brackets:**
- Stages 1–100: reach tile 10
- Stages 101–300: reach tile 12
- Stages 301–600: reach tile 14
- Stages 601–999: reach tile 16

---

## 16. MANIA MODE — KEY DIFFERENCES FROM BASIC

Mania is a separate scene (`scenes/mania.lua`) because it owns its own timers
that Basic doesn't have. Do NOT try to merge them into one scene.

```lua
-- Mania-specific timers (cancel ALL in scene:hide and scene:destroy):
_autoDropTimer  -- fires every MANIA.FALL_INTERVAL_MS: drops one tile
_gravityTimer   -- fires every MANIA.GRAVITY_FLIP_MS: rotates gravity direction
-- Gravity cycle: "down" → "left" → "up" → "right" → "down"

-- Score uses a ratcheting multiplier (no cap):
_maniaMult = 1.0
-- every MULT_STEP_MERGES merges: _maniaMult = _maniaMult + MULT_STEP_SIZE
-- all score = floor(base_score * _maniaMult)

-- Auto-drop countdown bar (visual feedback):
-- Thin rect at top of grid animates from full-width to 0 over FALL_INTERVAL_MS
-- Resets on every player merge (reward for staying active)

-- Game over condition: board completely full AND no moves remain
-- (not just no moves — player can still clear with the next auto-drop)
```

---

## 17. DYNAMIC BACKGROUND TINT SYSTEM

Simple but very effective — makes the game feel alive.

```lua
local _bgRect = nil   -- the background display.newRect

local function setBgTint(col)
    if not _bgRect then return end
    transition.cancel(_bgRect)
    transition.to(_bgRect, {
        time=settings.VISUAL.BG_TINT_MS,
        r=col[1], g=col[2], b=col[3],
        transition=easing.inOutSine,
    })
end

-- Usage:
setBgTint(settings.VISUAL.BG_TINT_COMBO)   -- warm gold during combo streak
setBgTint(settings.VISUAL.BG_TINT_CHAIN)   -- mint during chain reaction
setBgTint(settings.VISUAL.BG_TINT_DANGER)  -- red when < 2 valid moves left
setBgTint(settings.VISUAL.BG_TINT_NORMAL)  -- restore after effect ends
```

---

## 18. ACHIEVEMENT SYSTEM PATTERN

```lua
-- app/helpers/achievementHelper.lua

local ACHIEVEMENTS = {
    {
        id    = "first_win",
        name  = "First Victory",
        desc  = "Reach tile 10",
        icon  = "🏆",
        check = function(session, stats)
            return (session.maxTile or 0) >= 10
        end,
    },
    -- ... more achievements
}

-- check() called at game end. Returns array of NEWLY unlocked achievements.
-- saveState.unlockAchievement() is idempotent — safe to call every game.
function M.check(session, stats)
    local newUnlocks = {}
    for _, ach in ipairs(ACHIEVEMENTS) do
        if ach.check(session, stats) then
            local isNew = saveState.unlockAchievement(ach.id)
            if isNew then newUnlocks[#newUnlocks+1] = ach end
        end
    end
    return newUnlocks
end
```

**Session table fields** (accumulate during game, passed to check() at end):
```lua
_session = {
    startTime      = system.getTimer(),
    merges         = 0,
    usedBomb       = false,
    bombsUsedCount = 0,     -- int, not bool
    maxTile        = 0,
    maxCombo       = 0,
    maxChainDepth  = 0,
    bestCombo      = 0,
    score          = 0,     -- set at end
    xp             = 0,     -- set at end
    elapsedSeconds = 0,     -- set at end
}
```

---

## 19. COMMON SOLAR2D PITFALLS — DEFINITIVE LIST

| # | Pitfall | Symptom | Fix |
|---|---------|---------|-----|
| 1 | Move `.num` in gravity without moving `.obj` | Tiles vanish after merge | Move full `{num,isBomb,isHotZone,obj}` snapshot |
| 2 | Read `obj.x/y` after gravity for bomb position | Bomb appears at wrong location | Use `gridToScreen(cell.i, cell.j)` instead |
| 3 | No `_touchEnabled` guard | nil crash on rapid double-tap | Lock at top of tap handler, unlock at end of pipeline |
| 4 | `_endSession` called before defined | attempt to call nil | Forward-declare with `local _endSession` then `_endSession = function()` |
| 5 | `usedBomb` tracked as bool not int | "Bomb Squad" achievement never triggers | Use `bombsUsedCount` int counter |
| 6 | Stats key `totalScore` vs `bestScore` | Stats screen shows 0 | Standardise: `bestScore` = max single game, `totalScore` = lifetime sum |
| 7 | Gameover missing `mode/levelNum/stageNum` | "Play Again" goes to wrong scene | Always pass mode context in gameover params |
| 8 | `audio.loadStream()` in `scene:create` | Crackling / delay on repeat visits | Pre-load in `audioHelper.init()` at boot |
| 9 | Global variables | Invisible state, ghost bugs | All state as `local` at module level |
| 10 | `display.remove()` without nil check in transition | Crash mid-animation | `if obj and obj.parent then display.remove(obj) end` |
| 11 | Runtime:addEventListener without remove | Ghost listeners after scene change | Always pair in scene:show / scene:hide |
| 12 | `io.open` for save state | Slow, unreliable on iOS | Use `sqlite3` (built into Solar2D) |
| 13 | `setBombPulse` called on obj without `_bombRing` | Silent crash | Guard: `if not tileObj._bombRing then return end` |
| 14 | ScrollView inside a modal overlay without fixed height | Scroll bleeds through backdrop | Always set explicit `scrollHeight` in newScrollView |
| 15 | `composer.recycleOnSceneChange = true` with game scene | Game state lost on overlay | Set `recycleOnSceneChange = false` for game scenes |
| 16 | Navigate to the same scene with different params (e.g. different gridSize) | Old layout / stale module-level state shown | Call `composer.removeScene("scenes.game")` immediately before `gotoScene` — forces a fresh `scene:create` with the new params |

---

## 20. BUILD SETTINGS TEMPLATE

```lua
-- build.settings
settings = {
    orientation = {
        default   = "portrait",
        supported = { "portrait" },
    },
    iphone = {
        plist = {
            UIStatusBarHidden = true,
            UIRequiresFullScreen = true,
            CFBundleDisplayName = "Get 10",
            CFBundleVersion = "1.0.0",
            CFBundleShortVersionString = "1.0",
            NSMotionUsageDescription = "Used for haptic feedback on merges.",
        },
    },
    android = {
        versionCode    = 1,
        versionName    = "1.0",
        minSdkVersion  = "21",
    },
    plugins = {
        -- AdMob (add when ready for ads):
        -- ["plugin.admob"] = { publisherId="com.coronalabs" },
    },
}
```

---

## 21. HOW TO START A NEW PROJECT WITH CLAUDE

Give me this file + your project description. Then say:

**"New Solar2D project: [game name]. Genre: [hyper-casual / puzzle / arcade].
 Core mechanic: [one sentence]. Here is the architecture file."**

I will:
1. Create `config/settings.lua` with all constants first
2. Set up the three-layer folder structure
3. Build `main.lua`, `dbModel.lua`, `settingsModel.lua`, `audioHelper.lua`
4. Build `scenes/menu.lua` and `scenes/game.lua`
5. Add features from your roadmap in priority order

**For existing games:**
Upload the old code + this file. Say:
**"Refactor this Solar2D game using the architecture in the knowledge file."**

I will map existing code to the three-layer structure, extract magic numbers
to settings.lua, and identify dead code — without touching your assets.

---

## 22. GAME MODES FRAMEWORK (for hyper-casual games)

The four-mode structure that works for any tile/puzzle game:

| Mode | Description | Key config |
|------|-------------|------------|
| Basic | Infinite play, one rule set | `GAME.WIN_TILE`, endless after win |
| Intermediate | 50 curated levels, 3-star rating | `data/levels/intermediate/` |
| Advanced | 999 shaped stages, escalating difficulty | `data/levels/advanced/` + procedural fallback |
| Mania | Chaos rules, score-attack survival | Separate scene with own timers |

**Intermediate level goals:**
- `"reach"` — merge until tile reaches target value
- `"clear"` — remove all tiles from the board
- `"score"` — reach target score within move limit
- `"survive"` — perform N merges before board fills

**Advanced procedural generation fallback** (for stages without hand-crafted files):
Generate at runtime using stage number as seed — more holes/complexity as number increases.
This means 999 stages ship with zero content files; hand-crafted files replace them as you
create them.

---

## 23. AD INTEGRATION PLAN (implement after gameplay is solid)

Three placement types in order of player-friendliness:

1. **Rewarded video** — player CHOOSES to watch for a reward (extra undo, shuffle)
   - Best UX, highest eCPM, recommended first
2. **Interstitial** — full-screen between natural breaks (after game over)
   - Show max once per 3 game-overs; respect cooldown timer
3. **Banner** — small strip on menu screen only, never during gameplay

**adHelper.lua pattern:**
```lua
-- app/helpers/adHelper.lua (template)
local M = {}
local _lastInterstitialTime = 0
local COOLDOWN_SEC = settings.SYSTEM.SUSPEND_AD_COOLDOWN

function M.init()
    -- admob.init({ appId="...", testMode=true })
end

function M.showInterstitial()
    local now = system.getTimer() / 1000
    if now - _lastInterstitialTime < COOLDOWN_SEC then return end
    _lastInterstitialTime = now
    -- admob.show("interstitial")
end

function M.showRewarded(onComplete)
    -- admob.show("rewardedVideo")
    -- onComplete called with reward amount
end

return M
```

**Networks (Solar2D):**
- AdMob — industry standard, easiest setup, start here
- Appodeal — mediation (connects 70+ networks), better long-term eCPM

---

*End of Solar2D Game Architecture v2.0*
*Built from Get10 v4.0 — 4 game modes, 30 Lua files, full progression system*
