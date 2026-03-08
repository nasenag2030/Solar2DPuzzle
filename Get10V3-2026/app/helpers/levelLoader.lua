-----------------------------------------------------------------------------------------
--
-- app/helpers/levelLoader.lua
-- Get10 v4.0 — Level Data Loader
--
-- Loads level definitions for Intermediate (50 curated levels) and
-- Advanced (999 shaped stages) modes.
--
-- LEVEL DATA FORMAT
-- =================
-- Each level file returns a table:
--   {
--     -- Required
--     grid    = { {1,2,nil,...}, ... },   -- GRID×GRID (nil = inactive/empty)
--                                          -- numbers = starting tile values
--                                          -- 0       = empty active cell
--     goal    = "reach"|"clear"|"score"|"survive",
--     target  = number,   -- tile value (reach), 0 (clear all), score (score), moves (survive)
--
--     -- Optional
--     moves   = number,   -- move limit (nil = unlimited)
--     par     = number,   -- moves for 3-star rating (Intermediate only)
--     noBomb  = boolean,  -- disable bombs for this level
--     hint    = string,   -- short tip shown before the level starts
--     name    = string,   -- display name
--     theme   = string,   -- "ocean"|"fire"|"space"|etc (Advanced chapters)
--   }
--
-- GOAL TYPES
-- ==========
--   "reach"   — merge until a tile reaches the target value
--   "clear"   — remove ALL tiles from the board
--   "score"   — reach the target score within the move limit
--   "survive" — perform the target number of merges before the board fills
--
-- STAR RATING (Intermediate)
--   ★    completed the goal
--   ★★   completed within par moves
--   ★★★  completed without using a bomb (or other perfection criteria)
--
-- Usage:
--   local LL = require("app.helpers.levelLoader")
--   local data = LL.loadIntermediate(levelNum)
--   local data = LL.loadAdvanced(stageNum)
--   local info = LL.advancedWinTile(stageNum)  -- win tile for this stage bracket
--
-- CHANGELOG:
--   v4.0  2026-03-03  Initial
--
-----------------------------------------------------------------------------------------

local settings = require("config.settings")

local M = {}

-- ── Brick data (loaded once from data/levels/bricks.json) ─────────────────────
--
-- Brick positions are kept in a separate JSON file so level designers can
-- edit coordinates without touching any Lua game code.
-- Format: { "1": [{row=R, col=C}, ...], "2": [...], ... }

local _bricksCache = nil   -- populated on first call to _getBricksData()
local _shapesCache = nil   -- populated on first call to _getShapesData()

local function _getBricksData()
    if _bricksCache then return _bricksCache end
    local ok, json = pcall(require, "json")
    if not ok then _bricksCache = {}; return _bricksCache end
    local path = system.pathForFile("data/levels/bricks.json", system.ResourceDirectory)
    if not path then _bricksCache = {}; return _bricksCache end
    local file = io.open(path, "r")
    if not file then _bricksCache = {}; return _bricksCache end
    local content = file:read("*a")
    file:close()
    _bricksCache = json.decode(content) or {}
    return _bricksCache
end

-- ── Stage shape data (loaded once from data/levels/shapes.json) ───────────────
--
-- Each Stages-mode stage has a unique grid shape. The shape is a 6×6 matrix
-- where 1 = active cell (can hold tiles) and 0 = inactive (dead space, never filled).
-- Format: { "1": [[1,1,0,...],[...]], "2": [...], ... }
-- Edit shapes.json freely — no Lua knowledge needed.

local function _getShapesData()
    if _shapesCache then return _shapesCache end
    local ok, json = pcall(require, "json")
    if not ok then _shapesCache = {}; return _shapesCache end
    local path = system.pathForFile("data/levels/shapes.json", system.ResourceDirectory)
    if not path then _shapesCache = {}; return _shapesCache end
    local file = io.open(path, "r")
    if not file then _shapesCache = {}; return _shapesCache end
    local content = file:read("*a")
    file:close()
    _shapesCache = json.decode(content) or {}
    return _shapesCache
end

-- ── Intermediate mode ──────────────────────────────────────────────────────────

---
-- Load an Intermediate level definition.
-- File path: data/levels/intermediate/level_NNN.lua
-- Falls back to a generated placeholder if the file doesn't exist yet.
-- Brick positions are merged in from data/levels/bricks.json.
--
-- @param  num  integer 1–50
-- @return level data table (with .bricks array if any bricks defined)
function M.loadIntermediate( num )
    local path  = string.format("data.levels.intermediate.level_%03d", num)
    local ok, data = pcall(require, path)
    if not (ok and type(data) == "table") then
        -- Placeholder: random fill, reach tile 5
        data = {
            name   = "Level " .. num,
            grid   = nil,
            goal   = "reach",
            target = 5 + math.floor(num / 10),
            moves  = 20 + num,
            par    = 15 + num,
            hint   = "Merge matching tiles to advance!",
            noBomb = false,
        }
    end
    -- Attach brick positions from the separate JSON file (nil if none defined)
    local bricksAll = _getBricksData()
    data.bricks = bricksAll[tostring(num)]
    return data
end

-- ── Advanced mode ──────────────────────────────────────────────────────────────

---
-- Return the win-tile requirement for an Advanced stage number.
-- Brackets from settings.ADVANCED.WIN_TILE_BY_BRACKET.
function M.advancedWinTile( stageNum )
    local brackets = settings.ADVANCED.WIN_TILE_BY_BRACKET
    local win      = 10    -- default
    -- Iterate sorted bracket starts
    local keys = { 1, 101, 301, 601 }
    for _, k in ipairs(keys) do
        if stageNum >= k then
            win = brackets[k]
        end
    end
    return win
end

---
-- Return the chapter number and theme name for an Advanced stage.
-- A chapter = every STAGES_PER_CHAPTER stages.
-- Themes cycle through a fixed list.
function M.advancedChapter( stageNum )
    local step    = settings.ADVANCED.STAGES_PER_CHAPTER
    local chapter = math.ceil(stageNum / step)
    local themes  = {
        "Classic", "Ocean", "Fire", "Forest", "Space",
        "Ice", "Desert", "Neon", "Candy", "Void",
    }
    local theme = themes[((chapter - 1) % #themes) + 1]
    return chapter, theme
end

---
-- Load an Advanced stage definition.
-- File path: data/levels/advanced/stage_NNNN.lua
-- Falls back to a procedurally generated stage if the file doesn't exist.
--
-- @param  num  integer 1–999
-- @return stage data table
function M.loadAdvanced( num )
    local path = string.format("data.levels.advanced.stage_%04d", num)
    local ok, data = pcall(require, path)
    if not (ok and type(data) == "table") then
        data = M._generateStage(num)
    end
    data.winTile = data.winTile or M.advancedWinTile(num)
    -- Attach stage shape from the separate shapes.json file (nil if not defined)
    local shapesAll = _getShapesData()
    data.shape = shapesAll[tostring(num)]
    return data
end

---
-- Generate a stage procedurally for stages without a hand-crafted file.
-- As stage number increases:
--   • The grid shape gets more irregular (holes / missing corners)
--   • The win tile requirement increases per bracket
--   • Locked tiles appear after stage 300
--
-- @param  num  stage number
-- @return stage data table
function M._generateStage( num )
    local GRID  = settings.GAME.GRID_SIZE
    local grid  = {}

    -- Determine how many cells to leave inactive (increases with stage)
    local maxHoles = math.min(math.floor(num / 50), 8)   -- 0 holes early, up to 8 later
    local holeCount = math.random(0, maxHoles)

    -- Build full grid first
    for i = 1, GRID do
        grid[i] = {}
        for j = 1, GRID do
            grid[i][j] = 0   -- 0 = empty active cell (will be filled by populateGrid)
        end
    end

    -- Punch random holes (nil = inactive)
    -- Avoid making the board disconnected by only removing corner/edge cells
    local edgeCells = {}
    for i = 1, GRID do
        for j = 1, GRID do
            local isEdge = (i == 1 or i == GRID or j == 1 or j == GRID)
            if isEdge then edgeCells[#edgeCells+1] = {i, j} end
        end
    end
    for k = 1, math.min(holeCount, #edgeCells) do
        local idx = math.random(k, #edgeCells)
        edgeCells[k], edgeCells[idx] = edgeCells[idx], edgeCells[k]
        local pos = edgeCells[k]
        grid[pos[1]][pos[2]] = nil   -- inactive
    end

    local chapter, theme = M.advancedChapter(num)
    return {
        name    = string.format("Stage %d", num),
        chapter = chapter,
        theme   = theme,
        grid    = grid,
        goal    = "reach",
        target  = M.advancedWinTile(num),
        winTile = M.advancedWinTile(num),
        hint    = string.format("Chapter %d: %s", chapter, theme),
        noBomb  = false,
    }
end

-- ── Sample level data: first 5 Intermediate levels ────────────────────────────
-- These are embedded here as a fallback so the game ships with playable content
-- even before the level files are hand-crafted.

M.SAMPLE_INTERMEDIATE = {
    -- Level 1: Tutorial — full board, reach tile 4
    [1] = {
        name="Getting Started", goal="reach", target=4, moves=nil, par=8,
        hint="Tap any connected group of the same number to merge!",
        grid = {
            {1,1,2,1,1},
            {2,1,1,2,1},
            {1,2,2,1,2},
            {2,1,1,2,1},
            {1,2,1,1,2},
        },
    },
    -- Level 2: Reach tile 5 in 15 moves
    [2] = {
        name="Rising Up", goal="reach", target=5, moves=15, par=10,
        hint="Plan ahead — merge large groups to earn bigger tiles faster.",
        grid=nil,
    },
    -- Level 3: Score 100 points in 10 moves
    [3] = {
        name="Score Attack", goal="score", target=100, moves=10, par=10,
        hint="Merging higher-value tiles earns more points. Look for 3s and 4s!",
        grid=nil,
    },
    -- Level 4: Clear the board (no tiles left)
    [4] = {
        name="Clean Sweep", goal="clear", target=0, moves=nil, par=18, noBomb=false,
        hint="Merge everything! No tile can remain on the board.",
        grid = {
            {2,2,nil,2,2},
            {2,2,nil,2,2},
            {nil,nil,nil,nil,nil},
            {2,2,nil,2,2},
            {2,2,nil,2,2},
        },
    },
    -- Level 5: Survive 15 merges
    [5] = {
        name="Endurance", goal="survive", target=15, moves=nil, par=20,
        hint="Keep merging — the board keeps refilling. Reach 15 total merges.",
        grid=nil,
    },
}

return M
