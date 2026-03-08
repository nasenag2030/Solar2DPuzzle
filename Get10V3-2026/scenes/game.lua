-----------------------------------------------------------------------------------------
--
-- scenes/game.lua
-- Get10 v4.0 — Main Game Scene
--
-- WHAT THIS FILE DOES
-- ===================
-- This scene is the DISPLAY + WIRING layer. It:
--   • Owns all display objects (tiles, labels, backgrounds, buttons)
--   • Listens for player taps and routes them to logic functions
--   • Runs the animation pipeline after every merge action
--   • Checks win/gameover conditions and triggers overlays
--   • Tracks session stats for achievements and progression
--
-- It does NOT contain any game rules — those live in gameLogic.lua.
-- It does NOT contain any scoring math — that lives in scoreHelper.lua.
--
-- SCENE FLOW
-- ==========
--   scene:create  → buildUI → buildBoard (loads/generates grid)
--   tileOnTap     → single entry point for all player input
--     ├─ undo tap      → doUndo()
--     ├─ bomb tap      → doBombBlast() → runPostMerge()
--     └─ normal tap    → near-miss? show hint : doMerge() → runPostMerge()
--   runPostMerge  (the master animation + logic pipeline):
--     [MERGE_ANIM_MS+20ms]
--       → applyGravity → syncDisplay → removeOrphans → refillEmpty
--     [FALL_ANIM_MS+30ms]
--       → doChainStep(1) ── auto-merges, recursive, each with own gravity+refill
--         → onDone: checkEndConditions → win | gameover | unlock input
--
-- HOT ZONES (M-07)
-- ================
-- Every HOT_ZONE.RESPAWN_MERGES merges, 2 random cells glow gold.
-- Any merge touching a hot-zone cell earns HOT_ZONE.MULT × points.
-- GL.refreshHotZones() updates logical flags; updateHotZoneDisplay() drives visuals.
--
-- NEAR-MISS (M-08)
-- ================
-- When the player taps an isolated tile that has exactly one same-number
-- neighbour, both tiles flash and "So close!" appears — encouraging not punishing.
--
-- UNDO (M-01)
-- ===========
-- Before every player merge, a snapshot { grid_flat, score, maxTile } is saved.
-- doUndo() restores the snapshot and redraws the board.
-- FREE_PER_GAME undos available; button shows remaining count.
--
-- DYNAMIC BACKGROUND (I-06)
-- ==========================
-- Background tints toward gold during combos, mint during chains, red when
-- the board is nearly stuck (< 2 valid moves remaining).
--
-- ENDLESS MODE (M-03)
-- ====================
-- After reaching WIN_TILE the game continues instead of ending.
-- Each new milestone (WIN_TILE+1, +2, ...) awards a bonus and banner.
-- Tiles 11+ show a gold glow ring on their display object.
-- The board's colour palette wraps cyclically for very high tiles.
--
-- SESSION TRACKING
-- ================
-- _session table accumulates stats during the game. At game-end it is
-- passed to saveState.updateStats() and achievementHelper.check().
--
-- CHANGELOG:
--   v3.0  2026-03-03  Initial three-layer refactor
--   v3.1  2026-03-03  Combo streak, bomb tiles, particles, score pop
--   v3.2  2026-03-03  Gravity bug, nil crash, bomb-position fixes
--   v3.3  2026-03-03  Chain reactions, bomb redesign, bomb counter UI
--   v4.0  2026-03-03  Undo, hot zones, near-miss, dynamic bg, endless mode,
--                     score roll-up, session stats, achievements trigger
--
-----------------------------------------------------------------------------------------

local composer        = require("composer")
local settings        = require("config.settings")
local GL              = require("app.helpers.gameLogic")
local Tile            = require("app.components.tile")
local scoreHelper     = require("app.helpers.scoreHelper")
local audioHelper     = require("app.helpers.audioHelper")
local saveState       = require("app.helpers.saveState")
local settingsModel   = require("app.models.settingsModel")
local achievementHelper = require("app.helpers.achievementHelper")

local scene = composer.newScene()

-- ── Module-level state ─────────────────────────────────────────────────────────
-- All reset in buildBoard() at the start of each game.

local _grid         = nil       -- 5×5 logical grid
local _tileGroup    = nil       -- DisplayGroup for all tile objects
local _hotGroup     = nil       -- DisplayGroup for hot-zone glows (below tiles)
local _sceneGroup   = nil       -- top-level scene view
local _bgRect       = nil       -- background rect (tinted by dynamic bg)

local _totalScore   = 0
local _highScore    = 0
local _maxTile      = settings.GAME.START_MAX_TILE
local _touchEnabled = true
local _gameState    = "running"    -- "running" | "gameover" | "win" | "endless"
local _isEndless    = false        -- true after the first WIN_TILE is reached
local _endlessMilestone = settings.GAME.WIN_TILE  -- next milestone to celebrate

-- Combo streak
local _streak        = 0
local _comboMult     = 1
local _lastMergeTime = 0

-- Bomb counter (counts down to 0, then a bomb is planted)
local _mergesUntilBomb = settings.BOMB.MERGE_INTERVAL

-- Hot zone counter
local _mergesUntilHotRefresh = settings.HOT_ZONE.RESPAWN_MERGES

-- Undo system
local _undoSnapshot  = nil       -- { flat, score, maxTile } or nil
local _undosLeft     = settings.UNDO.FREE_PER_GAME

-- Session accumulator (sent to achievements + stats at game-end)
-- All fields start at safe defaults so partial sessions don't crash anything.
local _session = {}

-- Timer handles (cancelled on scene destroy)
local _comboTimer  = nil
local _chainTimer  = nil
local _rollTimer   = nil    -- score roll-up timer

-- UI label references
local _scoreLabel    = nil
local _highLabel     = nil
local _comboLabel    = nil
local _chainLabel    = nil
local _bombCounter   = nil
local _undoBtn       = nil
local _undoCountLbl  = nil
local _nearMissLabel = nil
local _endlessBanner = nil  -- "TILE 11! +500 pts" milestone banner
local _movesLabel    = nil  -- "X left" move counter (daily / limited modes)

-- Group highlight (dim non-group tiles before merge)
local _highlightCells = nil

-- Hot zone display objects (gold glow rects behind tiles)
local _hotZoneObjs = {}     -- map: cell → glow display object

-- Gravity direction (Mania mode rotates this)
local _gravityDir = "down"

-- Mode params (classic | newstyle | challenge | freeplay | intermediate | advanced)
local _mode     = "classic"
-- Style key used for save/load/HS: same as _mode except freeplay → "freeplay_N"
local _styleKey = "classic"
local _levelNum = nil
local _stageNum = nil
local _levelData = nil
local _moveCount = 0
local _levelWinTile = nil
local _levelGoal = nil
local _levelTarget = nil

-- Feature flags — set from scene params in scene:create
local _hasBombs  = false   -- show bomb counter, plant bombs after merges
local _hasUndo   = false   -- show undo button
local _hasChains = false   -- run chain reactions after gravity

-- Grid layout — set in scene:create from params; all drawing functions use these
local GRID   = settings.GAME.GRID_SIZE
local TILE_S = settings.VISUAL.TILE_SIZE
local WIN    = settings.GAME.WIN_TILE

-- ── Layout helper ──────────────────────────────────────────────────────────────
-- Converts logical (i=row, j=col) to screen (x, y).
-- Row 1 = top; row GRID = bottom.
-- The +30 offset shifts the grid down to leave room for the header.

local function gridToScreen( i, j )
    local ox = display.contentCenterX - GRID * TILE_S * 0.5 + TILE_S * 0.5
    local oy = display.contentCenterY - GRID * TILE_S * 0.5 + TILE_S * 0.5 + 30
    return ox + (j-1)*TILE_S,  oy + (i-1)*TILE_S
end

-- ── Dynamic background (I-06) ──────────────────────────────────────────────────
-- Tints the background rect toward a target colour over BG_TINT_MS ms.
-- Called with a colour table from settings.VISUAL.BG_TINT_*.

local function setBgTint( col )
    if not _bgRect then return end
    transition.cancel(_bgRect)
    transition.to(_bgRect, {
        time       = settings.VISUAL.BG_TINT_MS,
        r          = col[1],
        g          = col[2],
        b          = col[3],
        transition = easing.inOutSine,
    })
end

-- ── Score labels ───────────────────────────────────────────────────────────────

-- Pop animation: transition.from() starts at enlarged scale and snaps to 1,1.
local function popScoreLabel( lbl )
    transition.cancel(lbl)
    transition.from(lbl, {
        xScale=settings.VISUAL.SCORE_POP_SCALE,
        yScale=settings.VISUAL.SCORE_POP_SCALE,
        time=settings.VISUAL.SCORE_POP_MS,
        transition=easing.outElastic,
    })
end

-- Animated score roll-up (I-02): count from oldVal to newVal over ROLLUP_MS.
-- Uses a timer that fires ROLLUP_STEPS times and increments the display.
local function rollUpScore( lbl, oldVal, newVal )
    if not lbl then return end
    if _rollTimer then timer.cancel(_rollTimer); _rollTimer = nil end

    local steps    = settings.VISUAL.SCORE_ROLLUP_STEPS
    local stepTime = math.floor(settings.VISUAL.SCORE_ROLLUP_MS / steps)
    local diff     = newVal - oldVal
    local current  = 0

    _rollTimer = timer.performWithDelay(stepTime, function()
        current = current + 1
        local val = oldVal + math.floor(diff * (current / steps))
        lbl.text  = scoreHelper.scoreDisplay(val)
        if current >= steps then
            lbl.text = scoreHelper.scoreDisplay(newVal)
            timer.cancel(_rollTimer)
            _rollTimer = nil
        end
    end, steps)
end

local function updateScoreLabels( oldScore )
    if _scoreLabel then
        if oldScore and oldScore ~= _totalScore then
            rollUpScore(_scoreLabel, oldScore, _totalScore)
        else
            _scoreLabel.text = scoreHelper.scoreDisplay(_totalScore)
        end
        popScoreLabel(_scoreLabel)
    end
    if _highLabel then
        _highLabel.text = scoreHelper.scoreDisplay(_highScore)
    end
end

local function updateBombCounter()
    if _bombCounter then
        _bombCounter.text = "💣 " .. tostring(_mergesUntilBomb)
    end
end

local function updateUndoButton()
    if _undoCountLbl then
        _undoCountLbl.text = tostring(_undosLeft)
        if _undoBtn then
            _undoBtn.alpha = (_undosLeft > 0) and 1.0 or 0.35
        end
    end
end

local function updateMovesLabel()
    if not _movesLabel then return end
    local limit = _levelData and _levelData.moves
    if not limit then return end
    local left = math.max(0, limit - _moveCount)
    _movesLabel.text = left .. " left"
    if left <= 5 then
        _movesLabel:setFillColor(unpack(settings.COLOR.BUTTON_SECONDARY))
    elseif left <= 10 then
        _movesLabel:setFillColor(1, 0.75, 0.2)
    else
        _movesLabel:setFillColor(unpack(settings.COLOR.SCORE))
    end
end

-- ── Combo streak ───────────────────────────────────────────────────────────────

local function showComboLabel( mult )
    if not _comboLabel then return end
    _comboLabel.text  = "COMBO  x" .. mult .. "!"
    _comboLabel.alpha = 1
    transition.cancel(_comboLabel)
    transition.from(_comboLabel, { xScale=1.5, yScale=1.5, time=180, transition=easing.outElastic })
    if _comboTimer then timer.cancel(_comboTimer) end
    _comboTimer = timer.performWithDelay(settings.COMBO.LABEL_TIME, function()
        transition.to(_comboLabel, { alpha=0, time=200 })
        setBgTint(settings.VISUAL.BG_TINT_NORMAL)
    end)
end

-- Called at the start of every player-initiated merge.
local function updateStreak()
    local now     = system.getTimer()
    local elapsed = now - _lastMergeTime
    if _lastMergeTime > 0 and elapsed <= settings.COMBO.WINDOW_MS then
        _streak = _streak + 1
    else
        _streak = 0
    end
    _lastMergeTime = now
    _comboMult = math.min(_streak + 1, settings.COMBO.MAX_MULT)
    -- Track max combo for achievements
    if _comboMult > (_session.maxCombo or 0) then
        _session.maxCombo = _comboMult
    end
    if _comboMult >= 2 then
        showComboLabel(_comboMult)
        setBgTint(settings.VISUAL.BG_TINT_COMBO)
    end
end

local function resetStreak()
    _streak        = 0
    _comboMult     = 1
    _lastMergeTime = 0
    if _comboLabel then _comboLabel.alpha = 0 end
end

-- ── Chain banner ───────────────────────────────────────────────────────────────

local function showChainLabel( depth )
    if not _chainLabel then return end
    _chainLabel.text  = (depth > 1) and ("CHAIN x"..depth.."!") or "CHAIN!"
    _chainLabel.alpha = 1
    transition.cancel(_chainLabel)
    transition.from(_chainLabel, { xScale=1.6, yScale=1.6, time=160, transition=easing.outElastic })
    if _chainTimer then timer.cancel(_chainTimer) end
    _chainTimer = timer.performWithDelay(700, function()
        transition.to(_chainLabel, { alpha=0, time=200 })
        setBgTint(settings.VISUAL.BG_TINT_NORMAL)
    end)
    -- Track max chain depth for achievements
    if depth > (_session.maxChainDepth or 0) then
        _session.maxChainDepth = depth
    end
    setBgTint(settings.VISUAL.BG_TINT_CHAIN)
end

-- ── Tile tap (forward-declared) ────────────────────────────────────────────────
local tileOnTap

-- ── Hot zone display ───────────────────────────────────────────────────────────
-- For each cell with isHotZone=true, draw a pulsing gold glow rect in _hotGroup.
-- updateHotZoneDisplay() is called after refreshHotZones() changes the flags.

local function updateHotZoneDisplay()
    -- Remove all existing glow objects
    for _, obj in pairs(_hotZoneObjs) do
        if obj and obj.removeSelf then
            transition.cancel(obj)
            display.remove(obj)
        end
    end
    _hotZoneObjs = {}

    -- Create new glow for each hot-zone cell
    for i = 1, GRID do
        for j = 1, GRID do
            local cell = _grid[i][j]
            if cell.isHotZone and cell.num then
                local x, y = gridToScreen(i, j)
                local sz   = TILE_S - 2
                local glow = display.newRoundedRect(_hotGroup, x, y, sz, sz, settings.VISUAL.TILE_CORNER)
                local c    = settings.COLOR.HOT_ZONE_OVERLAY
                glow:setFillColor(c[1], c[2], c[3], c[4] or 0.30)

                -- Pulse animation: fade in and out
                local function pulse()
                    transition.to(glow, {
                        alpha=0.55, time=settings.HOT_ZONE.PULSE_MS,
                        transition=easing.inOutSine,
                        onComplete = function()
                            if glow and glow.parent then
                                transition.to(glow, {
                                    alpha=0.15, time=settings.HOT_ZONE.PULSE_MS,
                                    transition=easing.inOutSine,
                                    onComplete=pulse
                                })
                            end
                        end
                    })
                end
                glow.alpha = 0.15
                pulse()
                _hotZoneObjs[cell] = glow
            end
        end
    end
end

-- ── Board drawing ──────────────────────────────────────────────────────────────

-- Create a brick display object (no tap listener — bricks are indestructible).
local function drawBrick( cell )
    local obj  = Tile.newBrick(TILE_S)
    local x, y = gridToScreen(cell.i, cell.j)
    obj.x = x;  obj.y = y
    obj.i = cell.i;  obj.j = cell.j
    local scl = TILE_S / settings.VISUAL.TILE_SIZE
    if math.abs(scl - 1) > 0.02 then obj.xScale = scl;  obj.yScale = scl end
    obj._cellScale = scl
    _tileGroup:insert(obj)
    cell.obj = obj
    return obj
end

-- Create one tile display object and register its tap listener.
-- Tiles with num > WIN get a gold endless-glow ring (if _isEndless).
local function drawTile( cell )
    local obj  = Tile.new(cell.num, cell.isBomb, _isEndless and cell.num > WIN)
    local x, y = gridToScreen(cell.i, cell.j)
    obj.x = x
    obj.y = y
    obj.i = cell.i
    obj.j = cell.j
    -- Scale tile if grid size differs from the default tile size
    local scl = TILE_S / settings.VISUAL.TILE_SIZE
    if math.abs(scl - 1) > 0.02 then
        obj.xScale = scl
        obj.yScale = scl
    end
    obj._cellScale = scl   -- stored so animateFall can restore correct scale
    obj:addEventListener("tap", tileOnTap)
    _tileGroup:insert(obj)
    cell.obj = obj
    return obj
end

local function drawAllTiles( animated )
    for i = 1, GRID do
        for j = 1, GRID do
            local cell = _grid[i][j]
            if cell.isBrick and not cell.obj then
                drawBrick(cell)
            elseif cell.num and not cell.obj then
                local obj = drawTile(cell)
                if animated then
                    obj.alpha = 0
                    transition.to(obj, {
                        alpha=1,
                        time=settings.VISUAL.INTRO_FADE_MS,
                        delay=settings.VISUAL.INTRO_DELAY_MS + settings.VISUAL.INTRO_STEP_MS*(i*j),
                        transition=easing.inExpo,
                    })
                end
            end
        end
    end
end

-- ── Gravity display sync ────────────────────────────────────────────────────────
-- After GL.applyGravity() moves .obj with the cell data, animate each object
-- to its cell's correct screen Y position (or X for left/right gravity).

local function syncDisplayAfterGravity()
    for i = 1, GRID do
        for j = 1, GRID do
            local cell = _grid[i][j]
            if cell.num and cell.obj then
                local tx, ty = gridToScreen(i, j)
                if _gravityDir == "down" or _gravityDir == "up" then
                    if math.abs(cell.obj.y - ty) > 1 then
                        Tile.animateFall(cell.obj, ty)
                    end
                else  -- left / right gravity (Mania)
                    if math.abs(cell.obj.x - tx) > 1 then
                        Tile.animateFallH(cell.obj, tx)  -- horizontal fall
                    end
                end
            end
        end
    end
end

local function removeOrphanedObjects()
    for i = 1, GRID do
        for j = 1, GRID do
            local cell = _grid[i][j]
            -- Bricks/inactive cells have obj=nil and no num — skip both
            if cell.obj and not cell.num and not cell.isBrick and not cell.isInactive then
                Tile.setBombPulse(cell.obj, false)
                display.remove(cell.obj)
                cell.obj = nil
            end
        end
    end
end

local function refillEmptyCells()
    for i = 1, GRID do
        for j = 1, GRID do
            local cell = _grid[i][j]
            if not cell.num and not cell.isBrick and not cell.isInactive then
                cell.num    = GL.randomTileNum(_maxTile)
                cell.isBomb = false
                local obj   = drawTile(cell)
                local x, y  = gridToScreen(i, j)
                obj.alpha   = 0
                -- New tiles drop from above (or the appropriate edge for other gravity)
                if _gravityDir == "down" then
                    obj.y = y - TILE_S * 0.6
                elseif _gravityDir == "up" then
                    obj.y = y + TILE_S * 0.6
                elseif _gravityDir == "right" then
                    obj.x = x - TILE_S * 0.6
                else  -- left
                    obj.x = x + TILE_S * 0.6
                end
                transition.to(obj, { x=x, y=y, alpha=1, time=settings.VISUAL.SPAWN_ANIM_MS, transition=easing.outQuad })
            end
        end
    end
end

-- ── Group highlight ─────────────────────────────────────────────────────────────
local function highlightGroup( groupCells )
    _highlightCells = {}
    local inGroup   = {}
    for _, c in ipairs(groupCells) do inGroup[c] = true end
    for i = 1, GRID do
        for j = 1, GRID do
            local cell = _grid[i][j]
            if cell.obj and not inGroup[cell] then
                transition.to(cell.obj, { alpha=settings.VISUAL.HIGHLIGHT_ALPHA, time=settings.VISUAL.HIGHLIGHT_MS })
                _highlightCells[#_highlightCells+1] = cell.obj
            end
        end
    end
end

local function clearHighlight()
    if not _highlightCells then return end
    for _, obj in ipairs(_highlightCells) do
        if obj and obj.parent then
            transition.to(obj, { alpha=1, time=settings.VISUAL.HIGHLIGHT_MS })
        end
    end
    _highlightCells = nil
end

-- ── Near-miss detection (M-08) ─────────────────────────────────────────────────
-- Flash the tapped tile and its lonely neighbour; show "So close!".

local function showNearMiss( tappedObj, neighbourCell )
    if not _nearMissLabel then return end

    -- Flash cycle: both tiles blink 3 times
    local function flashObj( obj )
        for k = 0, settings.NEAR_MISS.FLASH_COUNT - 1 do
            transition.to(obj, {
                delay  = k * settings.NEAR_MISS.FLASH_MS * 2,
                alpha  = 0.35,
                time   = settings.NEAR_MISS.FLASH_MS,
                transition = easing.inOutSine,
                onComplete = function()
                    transition.to(obj, { alpha=1, time=settings.NEAR_MISS.FLASH_MS })
                end,
            })
        end
    end

    flashObj(tappedObj)
    if neighbourCell.obj then flashObj(neighbourCell.obj) end

    _nearMissLabel.text  = "So close!"
    _nearMissLabel.alpha = 1
    transition.cancel(_nearMissLabel)
    transition.from(_nearMissLabel, { yScale=1.4, time=150, transition=easing.outElastic })
    timer.performWithDelay(settings.NEAR_MISS.LABEL_MS, function()
        transition.to(_nearMissLabel, { alpha=0, time=200 })
    end)
end

-- ── Undo system (M-01) ─────────────────────────────────────────────────────────

-- Take a snapshot of the board BEFORE a merge so we can rewind to it.
local function takeUndoSnapshot()
    if _undosLeft <= 0 then return end   -- no undos left; don't waste memory
    local flat = {}
    for i = 1, GRID do
        flat[i] = {}
        for j = 1, GRID do
            local c = _grid[i][j]
            flat[i][j] = { num=c.num, isBomb=c.isBomb, isHotZone=c.isHotZone }
        end
    end
    _undoSnapshot = { flat=flat, score=_totalScore, maxTile=_maxTile }
end

-- Restore the board to the last snapshot.
-- Clears all display objects, rebuilds from the saved flat data.
local function doUndo()
    if not _undoSnapshot or _undosLeft <= 0 then return end

    _touchEnabled = false
    _undosLeft    = _undosLeft - 1
    updateUndoButton()

    local snap = _undoSnapshot
    _undoSnapshot = nil     -- consume it

    _totalScore = snap.score
    _maxTile    = snap.maxTile

    -- Clear existing tile display objects
    for i = _tileGroup.numChildren, 1, -1 do
        display.remove(_tileGroup[i])
    end

    -- Rebuild grid from flat snapshot
    _grid = GL.buildGrid()
    GL.populateGrid(_grid, _maxTile, snap.flat)

    -- Flash a blue overlay to signal the rewind
    local cx, cy = display.contentCenterX, display.contentCenterY
    local flash  = display.newRect(_sceneGroup, cx, cy, display.actualContentWidth, display.actualContentHeight)
    local uc     = settings.VISUAL.UNDO_FLASH_COLOR
    flash:setFillColor(uc[1], uc[2], uc[3], uc[4] or 0.3)
    flash.alpha  = 0
    transition.to(flash, {
        alpha=0.6, time=settings.UNDO.ANIM_MS * 0.5,
        onComplete = function()
            transition.to(flash, {
                alpha=0, time=settings.UNDO.ANIM_MS * 0.5,
                onComplete = function()
                    display.remove(flash)
                    drawAllTiles(false)
                    updateHotZoneDisplay()
                    updateScoreLabels()
                    _touchEnabled = true
                end
            })
        end,
    })
end

-- ── Bomb plant ─────────────────────────────────────────────────────────────────
-- Called AFTER gravity + chains settle so tile positions are final.
-- Uses gridToScreen(cell.i, cell.j) — always correct regardless of animation state.

local function plantBombNow()
    local bombCell = GL.plantBomb(_grid)
    if not (bombCell and bombCell.obj) then return end

    local bx, by = gridToScreen(bombCell.i, bombCell.j)
    Tile.setBombPulse(bombCell.obj, false)
    display.remove(bombCell.obj)
    bombCell.obj = nil

    local newObj = Tile.new(bombCell.num, true, false)
    newObj.x = bx;  newObj.y = by
    newObj.i = bombCell.i;  newObj.j = bombCell.j
    local bScl = TILE_S / settings.VISUAL.TILE_SIZE
    if math.abs(bScl - 1) > 0.02 then newObj.xScale = bScl;  newObj.yScale = bScl end
    newObj._cellScale = bScl
    newObj:addEventListener("tap", tileOnTap)
    _tileGroup:insert(newObj)
    bombCell.obj = newObj
    transition.from(newObj, { xScale=1.5, yScale=1.5, time=200, transition=easing.outElastic })

    _mergesUntilBomb = settings.BOMB.MERGE_INTERVAL
    updateBombCounter()
    _session.usedBomb = true
    -- Note: plantBomb doesn't increment bombsUsedCount — that counts player detonations
end

-- ── Endless mode milestone ─────────────────────────────────────────────────────

local function checkEndlessMilestone( tileNum )
    if not _isEndless then return end
    if tileNum < _endlessMilestone then return end

    _endlessMilestone = _endlessMilestone + settings.ENDLESS.MILESTONE_STEP

    -- Award bonus points
    local bonus = settings.ENDLESS.EXTRA_WIN_BONUS
    _totalScore = _totalScore + bonus
    if _totalScore > _highScore then
        _highScore = _totalScore
        saveState.setStyleHS(_styleKey, _highScore)
    end
    updateScoreLabels()

    -- Show the milestone banner
    if _endlessBanner then
        _endlessBanner.text  = "TILE " .. tileNum .. "!  +" .. bonus .. " pts"
        _endlessBanner.alpha = 1
        transition.cancel(_endlessBanner)
        transition.from(_endlessBanner, { yScale=1.5, time=200, transition=easing.outElastic })
        timer.performWithDelay(1200, function()
            transition.to(_endlessBanner, { alpha=0, time=300 })
        end)
    end

    -- Track for achievements (Grandmaster = tile 12)
    if tileNum > (_session.maxTile or 0) then
        _session.maxTile = tileNum
    end
end

-- Forward declaration so checkEndConditions can call _endSession before its definition
local _endSession

-- ── No More Moves notice (non-blocking) ───────────────────────────────────────
--
-- Shows a small card below the grid so the player can admire their final board
-- before tapping OK to proceed to the game-over overlay.
-- Input remains locked (_touchEnabled = false) until the overlay appears.

local function showNoMovesNotice()
    local cx = display.contentCenterX

    -- Position the card just below the grid panel
    -- gridToScreen bottom edge: contentCenterY + 30 + GRID*TILE_S/2 + small pad
    local gridBottom = display.contentCenterY + 30 + GRID * TILE_S * 0.5
    local cardY = gridBottom + 44
    -- Clamp so the card never falls off-screen
    cardY = math.min(cardY, display.actualContentHeight - 42)

    local g = display.newGroup()
    _sceneGroup:insert(g)

    -- Dark semi-transparent card
    local card = display.newRoundedRect(g, cx, cardY, 264, 74, 12)
    card:setFillColor(0.10, 0.10, 0.14, 0.96)
    card.strokeWidth = 1.5
    card:setStrokeColor(unpack(settings.COLOR.BUTTON_PRIMARY))

    -- Title
    local title = display.newText{
        parent=g, text="No More Moves",
        x=cx, y=cardY-17,
        font=settings.FONT.BOLD, fontSize=17, align="center",
    }
    title:setFillColor(1)

    -- Sub-line: best tile reached
    local sub = display.newText{
        parent=g, text="Your best tile: " .. _maxTile,
        x=cx, y=cardY+3,
        font=settings.FONT.NORMAL, fontSize=12, align="center",
    }
    sub:setFillColor(0.65)

    -- OK button
    local okBg = display.newRoundedRect(g, cx, cardY+24, 90, 28, 8)
    okBg:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    local okLbl = display.newText{
        parent=g, text="OK",
        x=cx, y=cardY+24,
        font=settings.FONT.BOLD, fontSize=14,
    }
    okLbl:setFillColor(1)

    local function onOK()
        display.remove(g)
        _endSession(true)
        return true
    end
    okBg:addEventListener("tap", onOK)
    okLbl:addEventListener("tap", onOK)

    -- Slide up and fade in
    g.y      = 40
    g.alpha  = 0
    transition.to(g, { y=0, alpha=1, time=260, transition=easing.outQuad })
end

-- ── Win / game-over check ──────────────────────────────────────────────────────
--
-- Called after all chains resolve. Handles:
--   • Endless transition (first time WIN_TILE is reached)
--   • Ongoing endless milestones
--   • Standard gameover (no moves left)
--   • Bomb plant if flagged

local function checkEndConditions( newTileNum, shouldBomb )

    -- Plant bomb first (board is now in final state)
    if shouldBomb then plantBombNow() end

    -- ── Win tile reached ───────────────────────────────────────────────────────
    local effectiveWin = _levelWinTile or WIN
    if (not _isEndless) and newTileNum >= effectiveWin then
        if settings.ENDLESS.ENABLED and (_mode == "classic" or _mode == "basic") then
            -- Endless mode: only available in Basic, not in levels/stages
            _isEndless        = true
            _gameState        = "endless"
            _endlessMilestone = effectiveWin + settings.ENDLESS.MILESTONE_STEP
            -- Flash the banner
            if _endlessBanner then
                _endlessBanner.text  = "TILE 10!  Keep going! 🎉"
                _endlessBanner.alpha = 1
                transition.from(_endlessBanner, { yScale=1.5, time=200, transition=easing.outElastic })
                timer.performWithDelay(1400, function()
                    transition.to(_endlessBanner, { alpha=0, time=300 })
                end)
            end
            audioHelper.playWin()
            _touchEnabled = true
            return
        else
            -- Classic win — Intermediate, Advanced, or endless disabled
            _gameState = "win"
            _endSession(false)
            return
        end
    end

    -- ── Endless milestone ──────────────────────────────────────────────────────
    if _isEndless and newTileNum > 0 then
        checkEndlessMilestone(newTileNum)
    end

    -- ── Move limit reached (daily challenge / any moves-capped level) ─────────
    updateMovesLabel()
    local moveLimit = _levelData and _levelData.moves
    if moveLimit and _moveCount >= moveLimit then
        _gameState = "win"
        _endSession(false)
        return
    end

    -- ── Game over: no valid moves ──────────────────────────────────────────────
    -- Show a non-blocking notice so the player can see their final board.
    -- _touchEnabled stays false — only the OK button on the notice can proceed.
    if not GL.hasMoves(_grid) then
        _gameState = "gameover"
        showNoMovesNotice()
        return
    end

    -- ── Near-danger tint ──────────────────────────────────────────────────────
    -- Count how many groups exist; if very few, tint red to signal danger.
    local moveCount = 0
    for i = 1, GRID do
        for j = 1, GRID do
            local cell = _grid[i][j]
            if cell.num and not cell._visited then
                local g = GL.getConnected(_grid, i, j)
                if #g >= 2 then moveCount = moveCount + 1 end
            end
        end
    end
    for i=1,GRID do for j=1,GRID do _grid[i][j]._visited = nil end end

    if moveCount <= 2 then
        setBgTint(settings.VISUAL.BG_TINT_DANGER)
    end

    -- Auto-save after every settled merge so a phone call / app switch never loses progress.
    -- Only for modes that support resuming (classic, freeplay, dash, challenge).
    -- Level/Stage/Mania modes don't resume mid-game.
    if _mode ~= "intermediate" and _mode ~= "advanced" and _mode ~= "mania" then
        saveState.save(_styleKey, _totalScore, _grid, _maxTile)
    end

    -- All clear — unlock input
    _touchEnabled = true
end

-- ── Session end ────────────────────────────────────────────────────────────────
-- Collects stats, triggers achievements, shows the gameover overlay.

_endSession = function( isGameOver )
    -- Finish accumulating session stats
    _session.score        = _totalScore
    _session.merges       = _session.merges or 0
    _session.elapsedSeconds = math.floor(
        (system.getTimer() - (_session.startTime or 0)) / 1000
    )
    if _maxTile > (_session.maxTile or 0) then _session.maxTile = _maxTile end
    _session.xp = scoreHelper.toXP(_totalScore)

    -- Save daily challenge score (best score for today; only on actual end)
    if _mode == "daily" then
        saveState.saveDailyChallengeScore(_totalScore)
    end

    -- Save Intermediate / Advanced mode progress on win
    if not isGameOver then
        if _mode == "intermediate" and _levelNum then
            -- Stars: 1=done, 2=within par, 3=within par + no bomb
            local stars = 1
            local par   = _levelData and _levelData.par
            if par and _moveCount <= par then
                stars = (_session.usedBomb) and 2 or 3
            elseif not _session.usedBomb then
                stars = 2
            end
            saveState.saveIntermediateStars(_levelNum, stars)
        elseif _mode == "advanced" and _stageNum then
            saveState.saveAdvancedStage(_stageNum + 1)   -- unlock next stage
        end
    end

    -- Persist lifetime stats
    local updatedStats = saveState.updateStats({
        bestCombo      = _session.bestCombo or 0,
        merges         = _session.merges,
        highestTile    = _session.maxTile or 0,
        score          = _totalScore,
        xp             = _session.xp,
        totalBombsUsed = _session.bombsUsedCount or 0,  -- count, not bool
    })

    -- Update daily streak
    saveState.updateStreak()

    -- Check achievements
    local newAch = achievementHelper.check(_session, updatedStats)

    -- Clear board save for this mode only (game is over)
    saveState.clear(_styleKey)

    -- Spin tiles out
    local delay = 0
    if isGameOver then
        for i = 1, GRID do
            for j = 1, GRID do
                if _grid[i][j].obj then
                    delay = delay + 35
                    transition.to(_grid[i][j].obj, {
                        delay=delay, time=700, rotation=360, alpha=0,
                        transition=easing.inOutBack,
                    })
                end
            end
        end
    end

    -- XP rank
    local rankIdx, rankName = achievementHelper.rankFromXP(updatedStats.totalXP)
    local streak = saveState.loadStreak()

    timer.performWithDelay(delay + 300, function()
        composer.showOverlay("scenes.gameover", {
            effect="fromTop", time=300, isModal=true,
            params = {
                isGameOver      = isGameOver,
                mode            = _mode,
                levelNum        = _levelNum,
                stageNum        = _stageNum,
                score           = _totalScore,
                highScore       = _highScore,
                maxTile         = _maxTile,
                bestCombo       = _session.bestCombo or 0,
                totalXP         = updatedStats.totalXP,
                rankName        = rankName,
                streak          = streak.currentStreak,
                newAchievements = newAch,
                isEndless       = _isEndless,
            },
        })
    end)
end

-- ── Chain reaction processing ───────────────────────────────────────────────────
--
-- doChainStep() is recursive. It fires after every gravity+refill cycle and
-- processes ALL chain groups before handing back to onDone.
--
-- Depth 1 = first chain after player tap.
-- Depth N+1 = chain triggered by the result of depth N.
-- Safety cap: CHAIN.MAX_DEPTH prevents infinite loops.

local function doChainStep( depth, onDone )
    if depth > settings.CHAIN.MAX_DEPTH then onDone(); return end

    local chains = GL.findChains(_grid)
    if #chains == 0 then onDone(); return end

    showChainLabel(depth)
    audioHelper.playMerge(2)

    for _, group in ipairs(chains) do
        -- Destination = lowest on screen (highest row index)
        local destCell = group[1]
        for _, cell in ipairs(group) do
            if cell.i > destCell.i then destCell = cell end
        end

        local destX = destCell.obj and destCell.obj.x or 0
        local destY = destCell.obj and destCell.obj.y or 0

        for _, cell in ipairs(group) do
            if cell ~= destCell then
                local movingObj = cell.obj
                cell.num       = nil
                cell.obj       = nil
                cell.isBomb    = false
                cell.isHotZone = false
                if movingObj then
                    local col = settings.COLOR.TILE[((destCell.num-1) % #settings.COLOR.TILE)+1]
                    Tile.spawnParticles(_tileGroup, movingObj.x, movingObj.y, col)
                    Tile.animateMerge(movingObj, destX, destY)
                end
            end
        end

        local destCellRef, mergedNum = GL.executeChain(_grid, group)
        local pts = scoreHelper.chainScore(mergedNum, #group, depth)
        local old = _totalScore
        _totalScore = _totalScore + pts
        if _totalScore > _highScore then
            _highScore = _totalScore
            saveState.setStyleHS(_styleKey, _highScore)
        end
        updateScoreLabels(old)

        if destCellRef.num > _maxTile then _maxTile = destCellRef.num end
        Tile.upgrade(destCellRef, _tileGroup, tileOnTap, TILE_S / settings.VISUAL.TILE_SIZE)
    end

    timer.performWithDelay(settings.CHAIN.ANIM_MS + settings.CHAIN.DELAY_MS, function()
        GL.applyGravity(_grid, _gravityDir)
        syncDisplayAfterGravity()
        removeOrphanedObjects()
        refillEmptyCells()
        timer.performWithDelay(settings.VISUAL.FALL_ANIM_MS + 30, function()
            doChainStep(depth + 1, onDone)
        end)
    end)
end

-- ── Master post-merge pipeline ─────────────────────────────────────────────────
--
-- Runs after every merge (player tap or bomb blast):
--   Step 1 [MERGE_ANIM_MS]: gravity → sync → orphan cleanup → refill
--   Step 2 [FALL_ANIM_MS]:  chain reactions → win/gameover check

local function runPostMerge( newTileNum, shouldBomb )
    timer.performWithDelay(settings.VISUAL.MERGE_ANIM_MS + 20, function()
        GL.applyGravity(_grid, _gravityDir)
        syncDisplayAfterGravity()
        removeOrphanedObjects()
        refillEmptyCells()
        -- Refresh hot zones after gravity so the glows are in the right place
        updateHotZoneDisplay()

        timer.performWithDelay(settings.VISUAL.FALL_ANIM_MS + 30, function()
            if _hasChains then
                doChainStep(1, function()
                    checkEndConditions(newTileNum, shouldBomb)
                end)
            else
                checkEndConditions(newTileNum, shouldBomb)
            end
        end)
    end)
end

-- ── Bomb blast ──────────────────────────────────────────────────────────────────

local function doBombBlast( tappedCell )
    local blastCells = GL.getBombBlast(_grid, tappedCell.i, tappedCell.j)
    Tile.spawnBombBlast(_tileGroup, tappedCell.obj.x, tappedCell.obj.y)
    audioHelper.playBomb()
    audioHelper.vibrateTap()   -- I-01 haptics

    local old = _totalScore
    local pts = scoreHelper.bombScore(blastCells)
    _totalScore = _totalScore + pts
    if _totalScore > _highScore then
        _highScore = _totalScore
        saveState.setStyleHS(_styleKey, _highScore)
    end
    updateScoreLabels(old)
    _session.usedBomb = true
    _session.bombsUsedCount = (_session.bombsUsedCount or 0) + 1

    for k, cell in ipairs(blastCells) do
        if cell.obj then
            Tile.setBombPulse(cell.obj, false)
            local obj   = cell.obj
            cell.obj    = nil;  cell.num = nil;  cell.isBomb = false
            transition.to(obj, {
                delay=(k-1)*40, xScale=1.6, yScale=1.6, alpha=0, time=260,
                transition=easing.outQuad,
                onComplete=function() display.remove(obj) end,
            })
        end
    end

    resetStreak()
    timer.performWithDelay(300 + (#blastCells * 40), function()
        runPostMerge(-1, false)
    end)
end

-- ── Normal merge ────────────────────────────────────────────────────────────────

local function doMerge( tappedCell, group )
    local destX    = tappedCell.obj.x
    local destY    = tappedCell.obj.y
    local mergedNum = tappedCell.num
    local groupSize = #group

    -- Session stats
    _session.merges = (_session.merges or 0) + 1
    _moveCount = _moveCount + 1
    if groupSize > (_session.bestCombo or 0) then _session.bestCombo = groupSize end

    -- Check if any cell in the group is a hot zone
    local isHotZone = false
    for _, cell in ipairs(group) do
        if cell.isHotZone then isHotZone = true; break end
    end

    -- Bomb counter (only active when bombs are enabled)
    local shouldBomb = false
    if _hasBombs then
        _mergesUntilBomb = _mergesUntilBomb - 1
        shouldBomb = (_mergesUntilBomb <= 0)
        updateBombCounter()
    end

    -- Hot zone refresh counter
    _mergesUntilHotRefresh = _mergesUntilHotRefresh - 1
    if _mergesUntilHotRefresh <= 0 then
        _mergesUntilHotRefresh = settings.HOT_ZONE.RESPAWN_MERGES
        GL.refreshHotZones(_grid, true)
    end

    -- Advance combo (updates _comboMult + _session.maxCombo)
    updateStreak()

    -- Slide non-destination tiles toward destination
    for _, cell in ipairs(group) do
        if cell ~= tappedCell then
            local movingObj = cell.obj   -- guard: may be nil on rapid double-tap
            cell.num       = nil
            cell.obj       = nil
            cell.isBomb    = false
            cell.isHotZone = false
            if movingObj then
                local col = settings.COLOR.TILE[((mergedNum-1) % #settings.COLOR.TILE)+1]
                Tile.spawnParticles(_tileGroup, movingObj.x, movingObj.y, col)
                Tile.animateMerge(movingObj, destX, destY)
            end
        end
    end

    -- Score (with hot zone multiplier if applicable)
    local old = _totalScore
    local pts = scoreHelper.calculate(mergedNum, groupSize, _comboMult, isHotZone)
    _totalScore = _totalScore + pts
    if _totalScore > _highScore then
        _highScore = _totalScore
        saveState.setStyleHS(_styleKey, _highScore)
    end
    updateScoreLabels(old)

    -- Upgrade destination tile
    Tile.upgrade(tappedCell, _tileGroup, tileOnTap, TILE_S / settings.VISUAL.TILE_SIZE)

    if tappedCell.num > _maxTile then _maxTile = tappedCell.num end
    if tappedCell.num > (_session.maxTile or 0) then _session.maxTile = tappedCell.num end

    audioHelper.playMerge(tappedCell.num)
    audioHelper.vibrateOnMerge(tappedCell.num)   -- I-01 haptics
    runPostMerge(tappedCell.num, shouldBomb)
end

-- ── Tile tap ────────────────────────────────────────────────────────────────────

tileOnTap = function( event )
    if not _touchEnabled then return true end
    _touchEnabled = false   -- LOCK — re-enabled by checkEndConditions or early exit

    local obj      = event.target
    local tappedCell = _grid[obj.i][obj.j]

    -- Brick tap — indestructible, unlock input and ignore
    if tappedCell.isBrick then
        _touchEnabled = true
        return true
    end

    clearHighlight()

    -- Bomb tap
    if tappedCell.isBomb then
        doBombBlast(tappedCell)
        return true
    end

    -- Connected group
    local group = GL.getConnected(_grid, obj.i, obj.j)

    if #group < 2 then
        -- Near-miss check before giving up (M-08)
        local neighbour = GL.findNearMiss(_grid, obj.i, obj.j)
        if neighbour then
            showNearMiss(obj, neighbour)
        else
            -- Isolated tap: small bump animation
            transition.to(obj, {
                xScale=1.12, yScale=1.12, time=80, transition=easing.outQuad,
                onComplete=function()
                    transition.to(obj, { xScale=1, yScale=1, time=80 })
                end,
            })
        end
        resetStreak()
        _touchEnabled = true
        return true
    end

    -- Show highlight, then merge after 80ms pause
    highlightGroup(group)
    timer.performWithDelay(80, function()
        clearHighlight()
        -- Take undo snapshot BEFORE modifying the grid
        takeUndoSnapshot()
        doMerge(tappedCell, group)
    end)

    return true
end

-- ── Build / reset board ─────────────────────────────────────────────────────────

local function buildBoard( savedData )
    -- Remove existing tile objects
    if _tileGroup then
        for i = _tileGroup.numChildren, 1, -1 do display.remove(_tileGroup[i]) end
    end
    if _hotGroup then
        for i = _hotGroup.numChildren, 1, -1 do display.remove(_hotGroup[i]) end
    end
    _hotZoneObjs = {}

    -- Reset all state
    _totalScore            = savedData and savedData.score or 0
    _highScore             = saveState.getStyleHS(_styleKey)
    if _totalScore > _highScore then _highScore = _totalScore end
    _maxTile               = (savedData and savedData.maxTile) or settings.GAME.START_MAX_TILE
    _touchEnabled          = true
    _gameState             = "running"
    _isEndless             = false
    _endlessMilestone      = WIN + settings.ENDLESS.MILESTONE_STEP
    _streak                = 0
    _comboMult             = 1
    _lastMergeTime         = 0
    _mergesUntilBomb       = settings.BOMB.MERGE_INTERVAL
    _mergesUntilHotRefresh = settings.HOT_ZONE.RESPAWN_MERGES
    _undosLeft             = settings.UNDO.FREE_PER_GAME
    _undoSnapshot          = nil
    _gravityDir            = "down"
    _session               = { startTime=system.getTimer(), merges=0, usedBomb=false }

    if _comboLabel    then _comboLabel.alpha    = 0 end
    if _chainLabel    then _chainLabel.alpha    = 0 end
    if _nearMissLabel then _nearMissLabel.alpha = 0 end
    if _endlessBanner then _endlessBanner.alpha = 0 end
    setBgTint(settings.VISUAL.BG_TINT_NORMAL)

    local initGrid = savedData and savedData.allTiles
    if _levelData and not savedData then initGrid = _levelData.grid end
    _levelWinTile = (_levelData and _levelData.winTile) or WIN
    _levelGoal    = (_levelData and _levelData.goal) or "reach"
    _levelTarget  = (_levelData and _levelData.target) or WIN
    _moveCount    = 0
    _grid = GL.buildGrid(GRID)
    GL.populateGrid(_grid, _maxTile, initGrid)

    -- Mark cells inactive when the level's own grid data had nil at that position.
    -- nil in a level grid = "outside the shape" (never fill, never draw).
    -- 0 in a level grid  = "empty active cell" (fill randomly).
    -- This fixes shaped levels like The Cross (level 006) whose nil cells would
    -- otherwise get refilled by refillEmptyCells after every merge.
    -- Skip this block when a stage shape is present — the shape controls cell
    -- activity and the procedural grid may contain stray nil holes that would
    -- incorrectly mark active-shape cells as inactive before the shape is applied.
    local hasShape = _levelData and _levelData.shape
    if initGrid and not hasShape then
        for i = 1, GRID do
            for j = 1, GRID do
                if initGrid[i] ~= nil and initGrid[i][j] == nil then
                    _grid[i][j].isInactive = true
                end
            end
        end
    end

    -- Apply stage shape from levelData.shape (Stages mode).
    -- shape[i][j] = 0 → inactive cell (outside stage border).
    if _levelData and _levelData.shape then
        for i = 1, GRID do
            for j = 1, GRID do
                if (_levelData.shape[i] and _levelData.shape[i][j] == 0) then
                    local cell = _grid[i][j]
                    cell.num        = nil
                    cell.isInactive = true
                end
            end
        end
    end

    -- Apply brick positions from level data (after populateGrid so bricks override any tile)
    if _levelData and _levelData.bricks then
        for _, b in ipairs(_levelData.bricks) do
            local cell = _grid[b.row] and _grid[b.row][b.col]
            if cell then
                cell.num       = nil
                cell.isBomb    = false
                cell.isHotZone = false
                cell.isBrick   = true
            end
        end
    end

    GL.refreshHotZones(_grid, false)

    drawAllTiles(savedData == nil)
    updateHotZoneDisplay()
    updateScoreLabels()
    updateBombCounter()
    updateUndoButton()
    updateMovesLabel()
end

function scene.restart()
    saveState.clear(_styleKey)
    buildBoard(nil)
end

-- ── Resume dialog ───────────────────────────────────────────────────────────────
-- Shows "Continue / New Game" when save data is found at session start.
-- Appears on top of an already-built board (built from savedData so the
-- background grid is visible behind the card).

local function showResumeDialog( savedData )
    local cx  = display.contentCenterX
    local cy  = display.contentCenterY

    local dlg = display.newGroup()
    _sceneGroup:insert(dlg)

    -- Dim backdrop
    local dim = display.newRect(dlg, cx, cy, display.actualContentWidth, display.actualContentHeight)
    dim:setFillColor(0, 0, 0, 0.72)

    -- Card
    local card = display.newRoundedRect(dlg, cx, cy, 260, 190, 14)
    card:setFillColor(0.14, 0.14, 0.18)
    card.strokeWidth = 1
    card:setStrokeColor(unpack(settings.COLOR.SCORE))

    local heading = display.newText{ parent=dlg, text="Resume?",
        x=cx, y=cy-68, font=settings.FONT.BOLD, fontSize=22, align="center" }
    heading:setFillColor(unpack(settings.COLOR.SCORE))

    local info = display.newText{ parent=dlg,
        text="You have a game in progress",
        x=cx, y=cy-38, font=settings.FONT.NORMAL, fontSize=13, align="center" }
    info:setFillColor(0.65)

    local scoreInfo = display.newText{ parent=dlg,
        text="Score: " .. scoreHelper.scoreDisplay(savedData.score or 0),
        x=cx, y=cy-18, font=settings.FONT.NORMAL, fontSize=12, align="center" }
    scoreInfo:setFillColor(0.50)

    -- "Continue" button
    local contBtn = display.newRoundedRect(dlg, cx, cy+22, 210, 42, 10)
    contBtn:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    local contLbl = display.newText{ parent=dlg, text="CONTINUE",
        x=cx, y=cy+22, font=settings.FONT.BOLD, fontSize=16 }
    contLbl:setFillColor(1)

    -- "New Game" button
    local newBtn = display.newRoundedRect(dlg, cx, cy+74, 210, 42, 10)
    newBtn:setFillColor(unpack(settings.COLOR.BUTTON_SECONDARY))
    local newLbl = display.newText{ parent=dlg, text="NEW GAME",
        x=cx, y=cy+74, font=settings.FONT.BOLD, fontSize=16 }
    newLbl:setFillColor(1)

    local function onContinue()
        display.remove(dlg)
        _touchEnabled = true
        return true
    end

    local function onNewGame()
        display.remove(dlg)
        saveState.clear(_styleKey)
        buildBoard(nil)
        _touchEnabled = true
        return true
    end

    contBtn:addEventListener("tap", onContinue)
    contLbl:addEventListener("tap", onContinue)
    newBtn:addEventListener("tap",  onNewGame)
    newLbl:addEventListener("tap",  onNewGame)
end

-- ── Scene lifecycle ─────────────────────────────────────────────────────────────

function scene:create( event )
    _sceneGroup = self.view

    -- ── Read params FIRST so GRID/TILE_S are correct for all UI below ─────────
    local params   = event.params or {}
    _mode          = params.mode      or "classic"
    _levelNum      = params.levelNum  or nil
    _stageNum      = params.stageNum  or nil
    _levelData     = params.levelData or nil

    _hasBombs  = params.hasBombs  ~= false
    _hasUndo   = params.hasUndo   ~= false
    _hasChains = params.hasChains == true

    GRID      = params.gridSize or settings.GAME.GRID_SIZE
    TILE_S    = math.min(settings.VISUAL.TILE_SIZE,
                         math.floor(display.actualContentWidth * 0.88 / GRID))
    _styleKey = (_mode == "freeplay") and ("freeplay_"..GRID) or _mode

    -- Background (tinted by dynamic bg system)
    _bgRect = display.newRect(_sceneGroup,
        display.contentCenterX, display.contentCenterY,
        display.actualContentWidth, display.actualContentHeight)
    _bgRect:setFillColor(unpack(settings.COLOR.BACKGROUND))

    -- Grid panel
    local panelSize = GRID * TILE_S + 12
    local panelX    = display.contentCenterX
    local panelY    = display.contentCenterY + 30
    local panel     = display.newRoundedRect(_sceneGroup, panelX, panelY, panelSize, panelSize, 12)
    panel:setFillColor(unpack(settings.COLOR.GRID_BG))

    -- Cell backgrounds
    local gridBg = display.newGroup(); _sceneGroup:insert(gridBg)
    for i = 1, GRID do
        for j = 1, GRID do
            local x, y = gridToScreen(i, j)
            local c = display.newRoundedRect(gridBg, x, y, TILE_S-6, TILE_S-6, settings.VISUAL.TILE_CORNER)
            c:setFillColor(unpack(settings.COLOR.GRID_CELL))
        end
    end

    -- Hot zone glow group (between cell bg and tiles)
    _hotGroup = display.newGroup(); _sceneGroup:insert(_hotGroup)

    -- Tile group (on top of everything)
    _tileGroup = display.newGroup(); _sceneGroup:insert(_tileGroup)

    -- ── Header ────────────────────────────────────────────────────────────────
    local hY = 38

    local function makeBox( cx, label )
        local bg = display.newRoundedRect(_sceneGroup, cx, hY, 90, 44, 8)
        bg:setFillColor(unpack(settings.COLOR.GRID_BG))
        local tl = display.newText{ parent=_sceneGroup, text=label, x=cx, y=hY-9, font=settings.FONT.NORMAL, fontSize=9 }
        tl:setFillColor(0.55)
        local vl = display.newText{ parent=_sceneGroup, text="0", x=cx, y=hY+8, font=settings.FONT.BOLD, fontSize=20 }
        return vl
    end

    _scoreLabel = makeBox(display.contentCenterX - 58, "SCORE")
    _scoreLabel:setFillColor(unpack(settings.COLOR.SCORE))
    _highLabel  = makeBox(display.contentCenterX + 58, "BEST")
    _highLabel:setFillColor(unpack(settings.COLOR.HIGH_SCORE))
    _highLabel.text = scoreHelper.scoreDisplay(saveState.getStyleHS(_styleKey))

    -- Menu button
    local menuBtn = display.newText{ parent=_sceneGroup, text="☰", x=24, y=38, font=settings.FONT.BOLD, fontSize=26 }
    menuBtn:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    menuBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.showOverlay("scenes.settings", { isModal=true, effect="fromTop", time=200 })
        return true
    end)

    -- Bomb counter (top-right) — only shown when bombs are enabled
    if _hasBombs then
        _bombCounter = display.newText{ parent=_sceneGroup, text="💣 "..settings.BOMB.MERGE_INTERVAL,
            x=display.contentWidth-28, y=38, font=settings.FONT.BOLD, fontSize=14, align="right" }
        _bombCounter:setFillColor(unpack(settings.COLOR.BOMB_GLOW))
        _bombCounter.anchorX = 1
    end

    -- Move counter (top-right) — shown when level has a move limit (daily / limited)
    local moveLimit = params.levelData and params.levelData.moves
    if moveLimit then
        local mlBox = display.newRoundedRect(_sceneGroup, display.contentWidth-34, 68, 52, 28, 6)
        mlBox:setFillColor(unpack(settings.COLOR.GRID_BG))
        local mlCap = display.newText{ parent=_sceneGroup, text="MOVES",
            x=display.contentWidth-34, y=62, font=settings.FONT.NORMAL, fontSize=8 }
        mlCap:setFillColor(0.5)
        _movesLabel = display.newText{ parent=_sceneGroup, text=tostring(moveLimit).." left",
            x=display.contentWidth-34, y=74, font=settings.FONT.BOLD, fontSize=13 }
        _movesLabel:setFillColor(unpack(settings.COLOR.SCORE))
    end

    -- Undo button — only shown when undo is enabled
    if _hasUndo then
        local undoBg = display.newRoundedRect(_sceneGroup, display.contentWidth-34, 68, 52, 28, 6)
        undoBg:setFillColor(unpack(settings.COLOR.UNDO_BTN))
        undoBg.alpha = 0.85
        _undoBtn     = undoBg

        local undoLbl = display.newText{ parent=_sceneGroup, text="↩", x=display.contentWidth-42, y=68, font=settings.FONT.BOLD, fontSize=16 }
        undoLbl:setFillColor(1)
        _undoCountLbl = display.newText{ parent=_sceneGroup, text="1", x=display.contentWidth-22, y=68, font=settings.FONT.BOLD, fontSize=13 }
        _undoCountLbl:setFillColor(1)

        local function onUndoTap()
            if not _touchEnabled then return true end
            if _undosLeft <= 0 then return true end
            audioHelper.playTap()
            doUndo()
            return true
        end
        undoBg:addEventListener("tap", onUndoTap)
        undoLbl:addEventListener("tap", onUndoTap)
        _undoCountLbl:addEventListener("tap", onUndoTap)
    end

    -- Labels above the grid
    local aboveY = display.contentCenterY - GRID * TILE_S * 0.5 - 10
    _comboLabel = display.newText{ parent=_sceneGroup, text="",
        x=display.contentCenterX-50, y=aboveY, font=settings.FONT.BOLD, fontSize=20, align="center" }
    _comboLabel:setFillColor(unpack(settings.COLOR.COMBO_LABEL))
    _comboLabel.alpha = 0

    _chainLabel = display.newText{ parent=_sceneGroup, text="",
        x=display.contentCenterX+50, y=aboveY, font=settings.FONT.BOLD, fontSize=20, align="center" }
    _chainLabel:setFillColor(unpack(settings.COLOR.CHAIN_LABEL))
    _chainLabel.alpha = 0

    -- Near-miss label (centre, between combo and chain)
    _nearMissLabel = display.newText{ parent=_sceneGroup, text="So close!",
        x=display.contentCenterX, y=aboveY+26, font=settings.FONT.BOLD, fontSize=16, align="center" }
    _nearMissLabel:setFillColor(1, 0.8, 0.4)
    _nearMissLabel.alpha = 0

    -- Endless milestone banner (centre of grid)
    _endlessBanner = display.newText{ parent=_sceneGroup, text="",
        x=display.contentCenterX, y=display.contentCenterY+30,
        font=settings.FONT.BOLD, fontSize=22, align="center" }
    _endlessBanner:setFillColor(unpack(settings.COLOR.COMBO_LABEL))
    _endlessBanner.alpha = 0

    -- Footer hint
    local hintText = _hasBombs and "Tap connected tiles · Bomb clears cross"
                                 or "Tap connected tiles to merge · Reach 10!"
    local hint = display.newText{ parent=_sceneGroup,
        text=hintText,
        x=display.contentCenterX, y=display.contentHeight-22,
        font=settings.FONT.NORMAL, fontSize=11, align="center" }
    hint:setFillColor(0.4)

    -- Load saved board only for resumable modes; level/stage modes always start fresh
    local savedData = params.savedData
    local isResumable = (_mode == "classic" or _mode == "basic" or
                         _mode == "freeplay" or _mode == "dash" or _mode == "challenge")
    if not savedData and isResumable then
        savedData = saveState.load(_styleKey)
    end

    if savedData and isResumable then
        -- Build board from the saved state, then ask the player what they want
        _touchEnabled = false   -- locked until player chooses
        buildBoard(savedData)
        showResumeDialog(savedData)
    else
        buildBoard(nil)
    end
end

function scene:show( event )
    if event.phase == "will" then
        _touchEnabled = (_gameState == "running" or _gameState == "endless")
    end
end

function scene:hide( event )
    if event.phase == "will" then
        if _gameState == "running" or _gameState == "endless" then
            saveState.save(_styleKey, _totalScore, _grid, _maxTile)
        end
        _touchEnabled = false
        clearHighlight()
    end
end

function scene:destroy( event )
    if _comboTimer then timer.cancel(_comboTimer); _comboTimer = nil end
    if _chainTimer then timer.cancel(_chainTimer); _chainTimer = nil end
    if _rollTimer  then timer.cancel(_rollTimer);  _rollTimer  = nil end
    _scoreLabel = nil; _highLabel = nil; _bombCounter = nil
    _undoBtn    = nil; _undoCountLbl = nil; _movesLabel = nil
end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
