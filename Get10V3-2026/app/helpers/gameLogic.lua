-----------------------------------------------------------------------------------------
--
-- app/helpers/gameLogic.lua
-- Get10 v4.0 — Pure Game Logic (NO display objects, NO Corona APIs)
--
-- All grid data operations live here. Display-free by design so every
-- function can be unit-tested without a running Corona instance.
--
-- THE GRID DATA STRUCTURE
-- =======================
--   grid[i][j] = {
--     num      = number|nil,   tile value (nil = empty cell)
--     i        = number,       row  1=top, GRID=bottom
--     j        = number,       col  1=left, GRID=right
--     isBomb   = boolean,      is this tile a bomb?
--     isHotZone = boolean,     is this cell currently a score hot zone?
--     isBrick    = boolean,    solid blocker — cannot be merged, moved, or destroyed
--     isInactive = boolean,    dead cell — outside the stage shape; never drawn or filled
--     obj      = DisplayGroup, live display object (managed by scenes/game.lua)
--     _visited = boolean,      internal flood-fill flag (always cleared after use)
--   }
--
-- GRAVITY RULE (critical — always follow this):
--   applyGravity() moves { num, isBomb, isHotZone, obj } together as a unit.
--   NEVER move only .num. If .obj is separated from its .num the display
--   sync will animate the wrong tile. See applyGravity() for full explanation.
--
-- HOT ZONE NOTES (M-07):
--   Hot zones are purely a scoring modifier — the cell's .isHotZone flag is
--   checked by game.lua when scoring a merge. Gravity moves the flag with
--   the tile so zones don't "stay behind" when tiles fall.
--   refreshHotZones() picks new random cells; old zones are cleared first.
--
-- Usage:
--   local GL = require("app.helpers.gameLogic")
--   local grid = GL.buildGrid()
--   GL.populateGrid(grid, 5, nil)
--   local group = GL.getConnected(grid, 3, 2)   → array of cells
--   GL.applyGravity(grid)
--   local chains = GL.findChains(grid)           → array of groups
--   local dest, num = GL.executeChain(grid, group)
--   GL.refreshHotZones(grid)                     → sets isHotZone on N cells
--   local near = GL.findNearMiss(grid, i, j)     → neighbour cell or nil
--   local ok = GL.hasMoves(grid)
--   local bomb = GL.plantBomb(grid)
--   local cells = GL.getBombBlast(grid, i, j)
--   local n = GL.randomTileNum(maxTile)
--
-- CHANGELOG:
--   v3.0  2026-03-03  Initial three-layer refactor
--   v3.1  2026-03-03  plantBomb, getBombBlast
--   v3.2  2026-03-03  BUG FIX: applyGravity moves .obj with data
--   v3.3  2026-03-03  findChains, executeChain; cross-shaped bomb blast
--   v4.0  2026-03-03  Hot zones (isHotZone flag), near-miss detection,
--                     Mania mode gravity direction support
--
-----------------------------------------------------------------------------------------

local settings = require("config.settings")

local M = {}

local GRID    = settings.GAME.GRID_SIZE
local WEIGHTS = settings.GAME.TILE_WEIGHTS

-- ── Random tile number ─────────────────────────────────────────────────────────
--
-- Returns a weighted-random tile value biased toward low numbers.
-- Only tiers 1..(maxTile-2) are active so the board doesn't immediately fill
-- with tiles the player can't merge.
--
-- Example: maxTile=5 → tiers 1,2,3 active; tier 3 is rare (weight 20 vs 50+40).
--
-- @param maxTile  current highest tile on the board
-- @return         integer tile value ≥ 1
function M.randomTileNum( maxTile )
    local maxTier = math.min( math.max(maxTile - 2, 1), #WEIGHTS )
    local total   = 0
    for i = 1, maxTier do total = total + WEIGHTS[i] end
    local rand  = math.random(1, total)
    local accum = 0
    for i = 1, maxTier do
        accum = accum + WEIGHTS[i]
        if rand <= accum then return i end
    end
    return 1
end

-- ── Seeded grid builder (Daily Challenge) ─────────────────────────────────────

---
-- Build a gridSize×gridSize tile-number grid deterministically from seed.
-- Uses an LCG so the same seed always yields the same layout.
-- Values are 1–5 (low-range), guaranteed at least one mergeable pair per row.
-- @param seed      number  (from saveState.loadDailyChallenge().seed)
-- @param gridSize  number
-- @return 2-D table [1..N][1..N] of integers 1–5
function M.buildGridFromSeed( seed, gridSize )
    local s = math.floor(seed) % 4294967296
    local function lcg()
        s = (s * 1664525 + 1013904223) % 4294967296
        return s
    end
    local g = {}
    for i = 1, gridSize do
        g[i] = {}
        for j = 1, gridSize do
            g[i][j] = (lcg() % 5) + 1
        end
    end
    -- Guarantee at least one mergeable pair: duplicate one tile in each row
    for i = 1, gridSize do
        local srcJ = (lcg() % gridSize) + 1
        local dstJ = (srcJ % gridSize) + 1   -- next col (wraps)
        g[i][dstJ] = g[i][srcJ]
    end
    return g
end

-- ── Grid construction ──────────────────────────────────────────────────────────

---
-- Allocate an empty GRID×GRID logical grid.
-- Every cell: num=nil, isBomb=false, isHotZone=false, obj=nil.
function M.buildGrid(size)
    local N = size or GRID
    local grid = {}
    for i = 1, N do
        grid[i] = {}
        for j = 1, N do
            grid[i][j] = {
                num=nil, i=i, j=j,
                isBomb=false, isHotZone=false, isBrick=false, isInactive=false, obj=nil,
            }
        end
    end
    return grid
end

---
-- Fill cells from savedData (resume) or random (new game).
--
-- savedData format: savedData[i][j] = { num=N, isBomb=bool }  (or plain number legacy)
--
-- Fresh game: random fill + one guaranteed "4" tile so there's always a first merge.
--
-- @param grid      logical grid (from buildGrid)
-- @param maxTile   highest tier for random generation
-- @param savedData optional 2-D save array
function M.populateGrid( grid, maxTile, savedData )
    maxTile = maxTile or settings.GAME.START_MAX_TILE
    local N = #grid

    if savedData then
        for i = 1, N do
            for j = 1, N do
                local v = savedData[i] and savedData[i][j]
                if type(v) == "table" then
                    grid[i][j].num      = (v.num  and v.num  > 0) and v.num  or nil
                    grid[i][j].isBomb   = v.isBomb   or false
                    grid[i][j].isHotZone = v.isHotZone or false
                else
                    grid[i][j].num      = (v and v > 0) and v or nil
                    grid[i][j].isBomb   = false
                    grid[i][j].isHotZone = false
                end
                grid[i][j].obj = nil
            end
        end
        return
    end

    -- Fresh board
    for i = 1, N do
        for j = 1, N do
            grid[i][j].num      = M.randomTileNum(maxTile)
            grid[i][j].isBomb   = false
            grid[i][j].isHotZone = false
            grid[i][j].obj      = nil
        end
    end
    -- Guarantee one 4-tile for an immediate merge opportunity
    local si = math.random(1, N)
    local sj = math.random(1, N)
    grid[si][sj].num = 4
end

-- ── Flood-fill (shared by getConnected and findChains) ─────────────────────────
--
-- Standard 4-directional flood-fill. Uses _visited to avoid revisiting cells.
-- clearVisited() MUST be called after every flood-fill use.

local function floodFill( grid, num, i, j, result )
    local N = #grid
    if i < 1 or i > N or j < 1 or j > N then return end
    local cell = grid[i][j]
    if cell._visited or cell.num ~= num then return end
    cell._visited     = true
    result[#result+1] = cell
    floodFill(grid, num, i-1, j,   result)   -- up
    floodFill(grid, num, i+1, j,   result)   -- down
    floodFill(grid, num, i,   j-1, result)   -- left
    floodFill(grid, num, i,   j+1, result)   -- right
end

local function clearVisited( grid )
    local N = #grid
    for i = 1, N do
        for j = 1, N do
            grid[i][j]._visited = nil
        end
    end
end

-- ── Connected group (player tap) ───────────────────────────────────────────────

---
-- Return all cells connected to (i,j) with the same tile number.
-- Bomb tiles are returned alone (size 1) — they don't flood-fill with normal tiles.
-- @return array of cell references (may be length 1 if the tile is isolated)
function M.getConnected( grid, i, j )
    local cell = grid[i][j]
    if not cell.num then return {} end
    if cell.isBomb  then return { cell } end
    local result = {}
    floodFill(grid, cell.num, i, j, result)
    clearVisited(grid)
    return result
end

-- ── Near-miss detection (M-08) ─────────────────────────────────────────────────
--
-- Called when the player taps an isolated tile (group size = 1).
-- Returns a neighbouring cell that has the same number if one exists.
-- game.lua uses this to flash both tiles and show "So close!".
--
-- @param grid  logical grid
-- @param i, j  position of the tapped isolated tile
-- @return      neighbour cell with the same num, or nil

function M.findNearMiss( grid, i, j )
    local num  = grid[i][j].num
    if not num then return nil end
    local dirs = { {-1,0}, {1,0}, {0,-1}, {0,1} }
    for _, d in ipairs(dirs) do
        local ni, nj = i+d[1], j+d[2]
        if ni >= 1 and ni <= #grid and nj >= 1 and nj <= #grid then
            local nb = grid[ni][nj]
            if nb.num == num and not nb.isBomb then
                return nb
            end
        end
    end
    return nil
end

-- ── Gravity ────────────────────────────────────────────────────────────────────
--
-- HOW GRAVITY WORKS
-- -----------------
-- After a merge some cells become empty (num=nil). Gravity fills the gaps
-- by dropping the remaining tiles to the bottom of each column.
--
-- Algorithm (per column):
--   1. Walk top-to-bottom, collect every occupied cell as a snapshot:
--        { num, isBomb, isHotZone, obj }
--      We capture .obj too — this is the KEY difference from naive gravity.
--   2. Clear the entire column (num=nil, obj=nil, isBomb=false, isHotZone=false).
--   3. Re-assign the snapshots from the BOTTOM of the column upward,
--      leaving empty rows at the top.
--   4. Update obj.i and obj.j on the display object so tileOnTap can look
--      up the correct logical cell after the tile moves.
--
-- WHY WE MOVE .obj:
--   syncDisplayAfterGravity() in game.lua animates cell.obj to gridToScreen(i,j).
--   If .obj stayed on the old (higher) cell, the sync would:
--     - New cell: has .num but no .obj → no animation
--     - Old cell: has .obj but no .num → removeOrphans() deletes it
--   Result: tile vanishes instead of sliding down.
--   Moving .obj with the data keeps them always in sync.
--
-- @param grid         logical grid (modified in-place)
-- @param gravityDir   "down"|"up"|"left"|"right"  (default "down"; Mania uses others)
-- @return array of changed column/row indices (for debugging)

function M.applyGravity( grid, gravityDir )
    gravityDir = gravityDir or "down"

    -- For "down" (standard) and "up": iterate columns; tiles move along rows.
    -- For "left" and "right":          iterate rows;    tiles move along cols.
    -- We unify by extracting "lanes" then re-inserting.

    local function processSegment( segment )
        -- segment: contiguous sub-lane with no bricks (array of {i,j})
        -- Tiles settle at the END (gravity direction end) of the segment.

        -- Step 1: collect occupied tiles
        local tiles = {}
        for _, pos in ipairs(segment) do
            local cell = grid[pos[1]][pos[2]]
            if cell.num then
                tiles[#tiles+1] = {
                    num       = cell.num,
                    isBomb    = cell.isBomb,
                    isHotZone = cell.isHotZone,
                    obj       = cell.obj,
                }
            end
        end

        -- Step 2: clear the segment
        for _, pos in ipairs(segment) do
            local cell     = grid[pos[1]][pos[2]]
            cell.num       = nil
            cell.isBomb    = false
            cell.isHotZone = false
            cell.obj       = nil
        end

        -- Step 3: re-fill from the gravity end of the segment
        local offset = #segment - #tiles
        for k, t in ipairs(tiles) do
            local pos  = segment[offset + k]
            local cell = grid[pos[1]][pos[2]]
            cell.num       = t.num
            cell.isBomb    = t.isBomb
            cell.isHotZone = t.isHotZone
            cell.obj       = t.obj
            if cell.obj then
                cell.obj.i = pos[1]
                cell.obj.j = pos[2]
            end
        end
    end

    local function processLane( positions )
        -- positions: array of { i, j } for cells in this lane, in gravity order.
        -- Brick cells split the lane — each brick-separated segment is processed
        -- independently so tiles can never pass through a brick.
        local segment = {}
        for _, pos in ipairs(positions) do
            local cell = grid[pos[1]][pos[2]]
            if cell.isBrick or cell.isInactive then
                if #segment > 0 then
                    processSegment(segment)
                    segment = {}
                end
                -- brick/inactive stays in place — skip it
            else
                segment[#segment+1] = pos
            end
        end
        if #segment > 0 then processSegment(segment) end
    end

    local N = #grid
    if gravityDir == "down" then
        -- Tiles fall toward row N (bottom). Process each column top→bottom.
        for j = 1, N do
            local lane = {}
            for i = 1, N do lane[#lane+1] = {i, j} end
            processLane(lane)
        end

    elseif gravityDir == "up" then
        -- Tiles fall toward row 1 (top). Reverse each column so row 1 is "end".
        for j = 1, N do
            local lane = {}
            for i = N, 1, -1 do lane[#lane+1] = {i, j} end
            processLane(lane)
        end

    elseif gravityDir == "left" then
        -- Tiles fall toward col 1 (left). Process each row right→left.
        for i = 1, N do
            local lane = {}
            for j = N, 1, -1 do lane[#lane+1] = {i, j} end
            processLane(lane)
        end

    elseif gravityDir == "right" then
        -- Tiles fall toward col N (right). Process each row left→right.
        for i = 1, N do
            local lane = {}
            for j = 1, N do lane[#lane+1] = {i, j} end
            processLane(lane)
        end
    end
end

-- ── Hot zones (M-07) ──────────────────────────────────────────────────────────
--
-- A "hot zone" is a randomly chosen non-empty, non-bomb cell that earns
-- HOT_ZONE.MULT × score when it is part of a merge group.
-- Zones move every HOT_ZONE.RESPAWN_MERGES merges.
--
-- The flag lives on the logical cell so gravity carries it when tiles fall.
-- game.lua checks isHotZone on any cell in the merge group.
-- When game.lua calls refreshHotZones() it passes shouldClear=true to remove
-- old zones before placing new ones.

---
-- Place HOT_ZONE.COUNT hot zones on random non-bomb, occupied cells.
-- @param grid         logical grid
-- @param shouldClear  boolean — if true, clear all existing zones first
function M.refreshHotZones( grid, shouldClear )
    local N = #grid
    -- Clear existing zones
    if shouldClear then
        for i = 1, N do
            for j = 1, N do
                grid[i][j].isHotZone = false
            end
        end
    end

    -- Collect eligible cells (occupied, not bomb, not already hot)
    local candidates = {}
    for i = 1, N do
        for j = 1, N do
            local cell = grid[i][j]
            if cell.num and not cell.isBomb and not cell.isHotZone then
                candidates[#candidates+1] = cell
            end
        end
    end

    -- Place zones up to COUNT
    local count = math.min(settings.HOT_ZONE.COUNT, #candidates)
    for k = 1, count do
        -- Fisher-Yates pick: swap k with a random later index
        local idx = math.random(k, #candidates)
        candidates[k], candidates[idx] = candidates[idx], candidates[k]
        candidates[k].isHotZone = true
    end
end

-- ── Chain reactions ────────────────────────────────────────────────────────────
--
-- After gravity, if any two orthogonal neighbours share the same number,
-- they automatically merge (chain reaction). findChains() locates all such
-- groups; executeChain() performs the data-side merge for one group.
--
-- findChains uses the same flood-fill as getConnected but only returns
-- groups of size ≥ 2. A group is visited only once even if multiple cells
-- in it could be entry points.

---
-- Scan the grid for all same-number connected groups of size ≥ 2.
-- Bombs never chain.
-- @return array of groups (each group = array of cell references)
function M.findChains( grid )
    local N = #grid
    local groups = {}
    for i = 1, N do
        for j = 1, N do
            local cell = grid[i][j]
            if cell.num and not cell.isBomb and not cell._visited then
                local group = {}
                floodFill(grid, cell.num, i, j, group)
                if #group >= 2 then
                    groups[#groups+1] = group
                end
            end
        end
    end
    clearVisited(grid)
    return groups
end

---
-- Execute the data-side merge for one chain group.
--
-- Destination = cell with the highest row index (lowest on screen).
-- This matches where gravity would settle the tile naturally.
--
-- Steps:
--   1. Find destination cell (max .i).
--   2. Clear all other cells (num=nil).
--      NOTE: .obj is NOT cleared here — game.lua still needs it for animation.
--   3. Increment destination.num.
--   4. Clear destination.isBomb (chains never produce bombs).
--
-- @param  grid   logical grid
-- @param  group  array of cells from findChains()
-- @return destCell   the merged destination cell
-- @return mergedNum  tile value BEFORE the upgrade (used by scoreHelper)
function M.executeChain( grid, group )
    local destCell = group[1]
    for _, cell in ipairs(group) do
        if cell.i > destCell.i then destCell = cell end
    end

    local mergedNum = destCell.num

    for _, cell in ipairs(group) do
        if cell ~= destCell then
            cell.num    = nil
            cell.isBomb = false
            cell.isHotZone = false
            -- NOTE: cell.obj intentionally NOT cleared here
        end
    end

    destCell.num    = mergedNum + 1
    destCell.isBomb = false

    return destCell, mergedNum
end

-- ── Has-moves check ────────────────────────────────────────────────────────────
--
-- Returns true if ANY valid action exists:
--   • A connected group of ≥ 2 equal tiles
--   • OR any bomb tile (always tappable)
-- Returns false only when the board is completely stuck → game over.

function M.hasMoves( grid )
    local N = #grid
    for i = 1, N do
        for j = 1, N do
            local cell = grid[i][j]
            if cell.num then
                if cell.isBomb then
                    clearVisited(grid)
                    return true
                end
                if not cell._visited then
                    local group = M.getConnected(grid, i, j)
                    if #group >= 2 then
                        clearVisited(grid)
                        return true
                    end
                end
            end
        end
    end
    clearVisited(grid)
    return false
end

-- ── Bomb tile ──────────────────────────────────────────────────────────────────
--
-- Bomb design (v3.3+):
--   • Cross-shaped blast (4 orthogonal neighbours) — surgical, player can aim it.
--   • Spawns only on low-value tiles (≤ SPAWN_MAX_NUM) — never destroys hard work.
--   • Score = per-tile-value (see scoreHelper.bombScore).

---
-- Mark a random low-value non-bomb occupied cell as a bomb.
-- Falls back to any non-bomb cell if no low-value ones exist.
-- @return  the chosen cell (for display update), or nil if board is empty
function M.plantBomb( grid )
    local N = #grid
    local lowPool = {}
    local anyPool = {}
    for i = 1, N do
        for j = 1, N do
            local cell = grid[i][j]
            if cell.num and not cell.isBomb then
                anyPool[#anyPool+1] = cell
                if cell.num <= settings.BOMB.SPAWN_MAX_NUM then
                    lowPool[#lowPool+1] = cell
                end
            end
        end
    end
    local pool = (#lowPool > 0) and lowPool or anyPool
    if #pool == 0 then return nil end
    local chosen  = pool[ math.random(1, #pool) ]
    chosen.isBomb = true
    return chosen
end

---
-- Return all cells hit by a bomb at (i,j).
-- Cross pattern — center + 4 orthogonal neighbours.
-- Index 1 is always the bomb cell itself.
-- Only includes cells that have a tile (num ~= nil).
--
-- Cross pattern (B=bomb, X=destroyed):
--        X
--      X B X
--        X
--
-- @param grid  logical grid
-- @param i, j  bomb position
-- @return array of cells (center first)
function M.getBombBlast( grid, i, j )
    local result = { grid[i][j] }
    local dirs   = { {-1,0}, {1,0}, {0,-1}, {0,1} }
    for _, d in ipairs(dirs) do
        local ni, nj = i+d[1], j+d[2]
        if ni >= 1 and ni <= #grid and nj >= 1 and nj <= #grid then
            if grid[ni][nj].num then
                result[#result+1] = grid[ni][nj]
            end
        end
    end
    return result
end

return M
