-----------------------------------------------------------------------------------------
--
-- config/settings.lua
-- Get10 — Global Application Settings
--
-- ALL tuneable values live here. Never scatter magic numbers in game code.
-- One file to rule all constants. Change here → applies everywhere.
--
-- SECTIONS:
--   VERSION, GAME, COMBO, CHAIN, BOMB, UNDO, HOT_ZONE,
--   ENDLESS, MANIA, VISUAL, FONT, COLOR
--
-- CHANGELOG:
--   v3.0  2026-03-03  Initial three-layer refactor
--   v3.1  2026-03-03  Combo, bomb, particle, highlight constants
--   v3.2  2026-03-03  Bug-fix release (no new constants)
--   v3.3  2026-03-03  Chain reaction + bomb redesign constants
--   v3.4  2026-03-03  Undo, hot zones, near-miss, dynamic bg, daily streak
--   v3.5  2026-03-03  Endless mode, achievements, XP/rank, daily challenge
--   v4.0  2026-03-03  Intermediate / Advanced / Mania mode constants
--
-----------------------------------------------------------------------------------------

local S = {}

-- ── Version ────────────────────────────────────────────────────────────────────
S.VERSION     = { major=4, minor=0, patch=0 }
S.VERSION_STR = "v4.0"

-- ── Game rules (Basic mode) ────────────────────────────────────────────────────
S.GAME = {}
S.GAME.GRID_SIZE      = 5      -- n × n grid
S.GAME.WIN_TILE       = 10     -- tile value that triggers a win in Basic mode
S.GAME.START_MAX_TILE = 5      -- max tile when seeding a fresh board

-- Tile spawn probability weights. Index = tile value, value = relative weight.
-- Only tiers 1..(maxTile-2) are active; higher tiers stay rare.
-- Increase weight[1] to make the board easier; decrease for harder starts.
S.GAME.TILE_WEIGHTS = { 50, 40, 20, 10, 5, 3, 2 }

-- ── Combo streak ───────────────────────────────────────────────────────────────
-- A streak builds when the player merges within WINDOW_MS of the previous merge.
-- The multiplier is capped at MAX_MULT to keep scoring fair.
S.COMBO = {}
S.COMBO.WINDOW_MS  = 2000   -- max gap between merges to keep streak alive (ms)
S.COMBO.MAX_MULT   = 5      -- maximum score multiplier (×5)
S.COMBO.LABEL_TIME = 900    -- how long the "COMBO x3!" banner stays visible (ms)

-- ── Chain reaction ─────────────────────────────────────────────────────────────
-- After gravity, if a tile lands next to a matching tile they auto-merge (chain).
-- Chains can cascade up to MAX_DEPTH times. Each deeper level earns more bonus.
S.CHAIN = {}
S.CHAIN.MAX_DEPTH        = 10    -- safety cap: max consecutive auto-merge passes
S.CHAIN.BONUS_MULTIPLIER = 1.5   -- score multiplier per chain depth (depth 1 = ×1.5)
S.CHAIN.ANIM_MS          = 120   -- duration of the chain flash animation
S.CHAIN.DELAY_MS         = 180   -- pause between chain steps (so player can see them)

-- ── Undo system (M-01) ─────────────────────────────────────────────────────────
-- One free undo per game. Extra undos can be earned (ads or daily login bonus).
-- Undo snapshots the full grid + score before each merge.
S.UNDO = {}
S.UNDO.FREE_PER_GAME = 1         -- undos the player starts each game with
S.UNDO.ANIM_MS       = 250       -- duration of the board "rewind" animation

-- ── Hot zones (M-07) ──────────────────────────────────────────────────────────
-- 2-3 random cells glow; merging them earns ZONE_MULT × normal score.
-- Zones reappear every RESPAWN_MERGES merges.
S.HOT_ZONE = {}
S.HOT_ZONE.COUNT           = 2   -- how many zones are active at once
S.HOT_ZONE.MULT            = 2   -- score multiplier for a hot-zone merge
S.HOT_ZONE.RESPAWN_MERGES  = 5   -- how many merges until zones move
S.HOT_ZONE.PULSE_MS        = 800 -- glow pulse duration

-- ── Near-miss detection (M-08) ────────────────────────────────────────────────
-- When the player taps an isolated tile that has exactly one same-number
-- neighbour, flash both tiles and show "So close!" for encouragement.
S.NEAR_MISS = {}
S.NEAR_MISS.FLASH_MS    = 120   -- each flash cycle duration
S.NEAR_MISS.FLASH_COUNT = 3     -- how many times to flash
S.NEAR_MISS.LABEL_MS    = 800   -- how long "So close!" stays visible

-- ── Bomb tile ──────────────────────────────────────────────────────────────────
-- Bomb only spawns on low-value tiles (≤ SPAWN_MAX_NUM).
-- Cross-shaped blast (4 orthogonal neighbours). Score = per-tile value × SCORE_PER_NUM.
S.BOMB = {}
S.BOMB.MERGE_INTERVAL = 12      -- one bomb planted every N merges
S.BOMB.SPAWN_MAX_NUM  = 3       -- bomb only appears on tiles ≤ this value
S.BOMB.PULSE_TIME     = 700     -- ms per glow-pulse animation cycle
S.BOMB.SCORE_PER_NUM  = 8       -- destroyed tile num × this = points

-- ── Endless mode (M-03) ────────────────────────────────────────────────────────
-- After reaching WIN_TILE, the game continues. Tiles go 11, 12, 13...
-- New colour palette activates; high-score board tracks "highest tile ever".
S.ENDLESS = {}
S.ENDLESS.ENABLED         = true    -- allow endless play after win
S.ENDLESS.EXTRA_WIN_BONUS = 500     -- bonus points awarded when passing each new milestone
S.ENDLESS.MILESTONE_STEP  = 1       -- show milestone banner every N tiles past WIN_TILE

-- ── Mania mode constants ────────────────────────────────────────────────────────
-- Tiles fall from the top on a timer. Gravity direction rotates every 60s.
-- Score multiplier ratchets up every 10 merges (no cap).
S.MANIA = {}
S.MANIA.FALL_INTERVAL_MS   = 8000   -- ms between automatic tile drops
S.MANIA.GRAVITY_FLIP_MS    = 60000  -- ms between gravity direction rotations
S.MANIA.MULT_STEP_MERGES   = 10     -- merges between automatic multiplier increases
S.MANIA.MULT_STEP_SIZE     = 0.1    -- how much multiplier grows each step
S.MANIA.BOMB_INTERVAL      = 8      -- bombs every N merges in Mania (more aggressive)

-- ── Daily challenge (M-04) ─────────────────────────────────────────────────────
S.DAILY = {}
S.DAILY.SEED_OFFSET = 20260303  -- base seed for daily board generation

-- ── XP & Player rank (P-04) ────────────────────────────────────────────────────
-- XP earned = score / XP_DIVISOR per game.
-- Each rank threshold is cumulative total XP needed.
S.XP = {}
S.XP.DIVISOR     = 10   -- score ÷ 10 = XP earned that game
S.XP.RANK_NAMES  = { "Novice", "Skilled", "Expert", "Master", "Legend" }
S.XP.RANK_THRESHOLDS = { 0, 500, 2000, 6000, 15000 }  -- cumulative XP per rank

-- ── Advanced mode ──────────────────────────────────────────────────────────────
-- 999 stages. Win tile requirement increases every 100 stages.
S.ADVANCED = {}
S.ADVANCED.TOTAL_STAGES = 999
S.ADVANCED.WIN_TILE_BY_BRACKET = {
    [1]   = 10,   -- stages   1-100
    [101] = 12,   -- stages 101-300
    [301] = 14,   -- stages 301-600
    [601] = 16,   -- stages 601-999
}
-- Chapter = every 10 stages. Theme affects bg + ambient sound.
S.ADVANCED.STAGES_PER_CHAPTER = 10

-- ── Visual ─────────────────────────────────────────────────────────────────────
S.VISUAL = {}
S.VISUAL.TILE_SIZE       = 60    -- grid cell size in pixels
S.VISUAL.TILE_CORNER     = 8     -- rounded corner radius
S.VISUAL.MERGE_ANIM_MS   = 110   -- tile slide-to-merge duration
S.VISUAL.FALL_ANIM_MS    = 70    -- tile fall-down duration
S.VISUAL.SPAWN_ANIM_MS   = 120   -- new tile drop-in duration
S.VISUAL.INTRO_DELAY_MS  = 800   -- delay before board appears on new game
S.VISUAL.INTRO_STEP_MS   = 25    -- stagger between each tile's intro fade
S.VISUAL.INTRO_FADE_MS   = 400   -- each tile's fade-in duration

-- Score label pop
S.VISUAL.SCORE_POP_SCALE = 1.40
S.VISUAL.SCORE_POP_MS    = 140

-- Score roll-up animation (I-02)
-- Label counts from old value to new over ROLLUP_MS milliseconds
S.VISUAL.SCORE_ROLLUP_MS = 400   -- total roll-up animation time
S.VISUAL.SCORE_ROLLUP_STEPS = 20 -- number of intermediate values shown

-- Particle burst on merge
S.VISUAL.PARTICLE_COUNT  = 8
S.VISUAL.PARTICLE_RADIUS = 28
S.VISUAL.PARTICLE_MS     = 380

-- Group highlight before tap executes
S.VISUAL.HIGHLIGHT_ALPHA = 0.55
S.VISUAL.HIGHLIGHT_MS    = 120

-- Dynamic background tint (I-06)
-- Background shifts toward TINT colour based on game state.
S.VISUAL.BG_TINT_MS        = 800   -- transition time for bg colour shift
S.VISUAL.BG_TINT_COMBO     = { 0.22, 0.18, 0.08 }  -- warm gold tint during streak
S.VISUAL.BG_TINT_CHAIN     = { 0.08, 0.22, 0.15 }  -- mint tint during chain reaction
S.VISUAL.BG_TINT_DANGER    = { 0.22, 0.08, 0.08 }  -- red tint when board is nearly stuck
S.VISUAL.BG_TINT_NORMAL    = { 0.13, 0.13, 0.17 }  -- default (matches BACKGROUND)

-- Undo board rewind visual
S.VISUAL.UNDO_FLASH_COLOR  = { 0.6, 0.8, 1.0, 0.3 }  -- blue flash over board

-- ── Fonts ──────────────────────────────────────────────────────────────────────
S.FONT = {}
S.FONT.NORMAL = "OpenSans"
S.FONT.BOLD   = "OpenSans-Bold"

-- ── Colours (RGB 0-1 float) ────────────────────────────────────────────────────
S.COLOR = {}
S.COLOR.BACKGROUND       = { 0.13, 0.13, 0.17 }   -- deep charcoal
S.COLOR.GRID_BG          = { 0.18, 0.18, 0.22 }   -- panel behind grid
S.COLOR.GRID_CELL        = { 0.22, 0.22, 0.28 }   -- empty cell bg
S.COLOR.SCORE            = { 1.00, 0.75, 0.30 }   -- warm gold
S.COLOR.HIGH_SCORE       = { 0.60, 0.87, 0.60 }   -- soft green
S.COLOR.BUTTON_PRIMARY   = { 1.00, 0.47, 0.27 }   -- orange-red
S.COLOR.BUTTON_SECONDARY = { 0.38, 0.38, 0.48 }   -- muted slate
S.COLOR.COMBO_LABEL      = { 1.00, 0.84, 0.20 }   -- vivid yellow
S.COLOR.CHAIN_LABEL      = { 0.40, 1.00, 0.70 }   -- bright mint
S.COLOR.BOMB_GLOW        = { 1.00, 0.25, 0.10 }   -- hot red
S.COLOR.HOT_ZONE         = { 1.00, 0.90, 0.20 }   -- bright yellow for hot zones
S.COLOR.UNDO_BTN         = { 0.35, 0.65, 1.00 }   -- blue for undo button
S.COLOR.TILE_TEXT_DARK   = { 0.15, 0.15, 0.15 }   -- number on light tiles
S.COLOR.TILE_TEXT_LIGHT  = { 1.00, 1.00, 1.00 }   -- number on dark tiles

-- Rank colours (P-04) — one per rank in XP.RANK_NAMES
S.COLOR.RANK = {
    { 0.70, 0.70, 0.75 },   -- Novice  (silver-grey)
    { 0.30, 0.75, 0.95 },   -- Skilled (sky blue)
    { 0.30, 0.90, 0.50 },   -- Expert  (mint)
    { 1.00, 0.75, 0.20 },   -- Master  (gold)
    { 1.00, 0.35, 0.90 },   -- Legend  (purple-pink)
}

-- Tile fill colours — index 1 = tile "1", wraps beyond 12.
-- Tiles 11+ (Endless mode) reuse this palette cyclically.
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
    { 255/255,  75/255,  75/255 },   -- 10  bright red  (Basic WIN tile)
    {  91/255,  50/255,  86/255 },   -- 11  violet      (Endless)
    {  52/255, 152/255, 219/255 },   -- 12  dodger blue (Endless)
}

-- Endless mode: border glow on tiles > WIN_TILE to highlight their rarity
S.COLOR.ENDLESS_GLOW = { 1.00, 0.90, 0.30 }   -- gold ring on high tiles

-- Hot zone overlay colour (semi-transparent yellow glow behind tile)
S.COLOR.HOT_ZONE_OVERLAY = { 1.00, 0.90, 0.10, 0.30 }

-- ── System ─────────────────────────────────────────────────────────────────────
S.SYSTEM = {}
S.SYSTEM.SUSPEND_AD_COOLDOWN = 60 * 5   -- seconds idle before ad on resume

return S
