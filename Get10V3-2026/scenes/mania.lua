-----------------------------------------------------------------------------------------
--
-- scenes/mania.lua
-- Get10 v4.0 — Mania Mode: Chaos Survival Scene
--
-- WHAT THIS SCENE DOES
-- ====================
-- Mania is an endless survival mode with escalating chaos rules:
--   1. A new tile DROPS from the top every MANIA.FALL_INTERVAL_MS ms (time pressure)
--   2. Gravity direction ROTATES every MANIA.GRAVITY_FLIP_MS ms
--      (down → left → up → right → down → ...)
--   3. Score multiplier RATCHETS UP every MANIA.MULT_STEP_MERGES merges (no cap)
--   4. Bombs appear every MANIA.BOMB_INTERVAL merges (more frequent)
--   5. NO undo, NO hints
--   6. Game ends when the board is completely full AND no moves remain
--
-- LAYOUT
-- ======
-- Reuses the same 5×5 grid + tap system as the Basic game scene.
-- Additional UI elements:
--   • Gravity direction arrow indicator (top-left)
--   • Mania multiplier badge (top-right, grows as mult increases)
--   • Countdown timer bar showing time until next auto-drop
--   • "DANGER!" pulse when board is 80% full
--
-- WIRING
-- ======
-- This scene owns its own timers (autoDropTimer, gravityFlipTimer, multTimer).
-- All timers are cancelled in scene:hide and scene:destroy.
-- Reuses GL (gameLogic) and Tile unchanged — Mania is a display/rule layer only.
--
-- Usage (from menu.lua):
--   composer.gotoScene("scenes.mania", { effect="fade", time=300 })
--
-- CHANGELOG:
--   v4.0  2026-03-03  Initial
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

local scene = composer.newScene()

-- Gravity direction cycle
local GRAVITY_CYCLE = { "down", "left", "up", "right" }

-- ── State ─────────────────────────────────────────────────────────────────────
local _grid, _tileGroup, _sceneGroup, _bgRect
local _totalScore, _highScore
local _touchEnabled, _gameState
local _maxTile
local _gravityDir, _gravityIdx
local _maniaMult, _mergesUntilMultUp, _mergesUntilBomb
local _mergeCount

-- Timer handles
local _autoDropTimer, _gravityTimer, _multTimer, _dropBarTimer
local _comboTimer, _chainTimer

-- UI refs
local _scoreLabel, _highLabel
local _multLabel, _gravArrow
local _dropBar, _dropBarBg
local _chainLabel, _comboLabel

-- Layout
local GRID   = settings.GAME.GRID_SIZE
local TILE_S = settings.VISUAL.TILE_SIZE

local function gridToScreen(i,j)
    local ox = display.contentCenterX - GRID*TILE_S*0.5 + TILE_S*0.5
    local oy = display.contentCenterY - GRID*TILE_S*0.5 + TILE_S*0.5 + 30
    return ox+(j-1)*TILE_S, oy+(i-1)*TILE_S
end

-- Forward declaration
local tileOnTap

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function cancelTimers()
    for _, h in ipairs{_autoDropTimer,_gravityTimer,_comboTimer,_chainTimer} do
        if h then pcall(timer.cancel, h) end
    end
    _autoDropTimer=nil; _gravityTimer=nil; _comboTimer=nil; _chainTimer=nil
end

local function updateScoreUI()
    if _scoreLabel then _scoreLabel.text = scoreHelper.scoreDisplay(_totalScore) end
    if _highLabel  then _highLabel.text  = scoreHelper.scoreDisplay(_highScore)  end
end

local function updateMultLabel()
    if not _multLabel then return end
    _multLabel.text = "x" .. string.format("%.1f", _maniaMult)
    local g = math.min(_maniaMult / 5, 1)
    _multLabel:setFillColor(1, 1-g*0.6, 0.2)
end

local function updateGravArrow()
    if not _gravArrow then return end
    local arrows = { down="↓", left="←", up="↑", right="→" }
    _gravArrow.text = arrows[_gravityDir] or "↓"
end

-- ── Drawing ───────────────────────────────────────────────────────────────────

local function drawTile(cell)
    local obj = Tile.new(cell.num, cell.isBomb, false)
    local x,y = gridToScreen(cell.i, cell.j)
    obj.x=x; obj.y=y; obj.i=cell.i; obj.j=cell.j
    obj:addEventListener("tap", tileOnTap)
    _tileGroup:insert(obj)
    cell.obj = obj
    return obj
end

local function syncGravity()
    for i=1,GRID do for j=1,GRID do
        local cell = _grid[i][j]
        if cell.num and cell.obj then
            local tx,ty = gridToScreen(i,j)
            Tile.animateFall(cell.obj, ty)
        end
    end end
end

local function removeOrphans()
    for i=1,GRID do for j=1,GRID do
        local cell = _grid[i][j]
        if cell.obj and not cell.num then
            display.remove(cell.obj); cell.obj=nil
        end
    end end
end

local function refillEmpty()
    for i=1,GRID do for j=1,GRID do
        local cell = _grid[i][j]
        if not cell.num then
            cell.num  = GL.randomTileNum(_maxTile)
            cell.isBomb = false
            local obj  = drawTile(cell)
            local x,y  = gridToScreen(i,j)
            obj.alpha=0; obj.y = y - TILE_S*0.6
            transition.to(obj,{x=x,y=y,alpha=1,time=settings.VISUAL.SPAWN_ANIM_MS,transition=easing.outQuad})
        end
    end end
end

-- ── Auto-drop: add one tile to the top row ────────────────────────────────────
-- Drops a tile into the first empty cell in row 1 (left to right).
-- If row 1 is full → check if game is over, otherwise skip this drop.

local function autoDrop()
    if _gameState ~= "running" then return end

    -- Find an empty cell in the topmost available row
    local placed = false
    for i=1,GRID do
        for j=1,GRID do
            if not _grid[i][j].num then
                _grid[i][j].num    = GL.randomTileNum(_maxTile)
                _grid[i][j].isBomb = false
                local obj = drawTile(_grid[i][j])
                local x,y = gridToScreen(i,j)
                obj.y = y - TILE_S
                obj.alpha = 0.5
                transition.to(obj,{y=y,alpha=1,time=120,transition=easing.outBounce})
                placed = true
                break
            end
        end
        if placed then break end
    end

    -- If board is now completely full and no moves — game over
    if not placed and not GL.hasMoves(_grid) then
        _gameState = "gameover"
        _touchEnabled = false
        cancelTimers()
        timer.performWithDelay(400, function()
            composer.showOverlay("scenes.gameover",{
                isModal=true, effect="fromTop", time=300,
                params={
                    isGameOver=true, score=_totalScore, highScore=_highScore,
                    maxTile=_maxTile, isEndless=false, isMania=true,
                    merges=_mergeCount,
                },
            })
        end)
    end
end

-- ── Drop countdown bar ────────────────────────────────────────────────────────
-- Animates a thin bar across the top that resets each auto-drop cycle.

local function restartDropBar()
    if not _dropBar then return end
    transition.cancel(_dropBar)
    local maxW = display.actualContentWidth - 20
    _dropBar.width  = maxW
    _dropBar:setFillColor(1, 0.75, 0.2)
    transition.to(_dropBar,{
        width=0,
        time=settings.MANIA.FALL_INTERVAL_MS,
        transition=easing.linear,
        onComplete=function()
            _dropBar:setFillColor(1, 0.3, 0.2)   -- flash red at 0
        end,
    })
end

-- ── Gravity rotation ──────────────────────────────────────────────────────────

local function rotateGravity()
    if _gameState ~= "running" then return end
    _gravityIdx = (_gravityIdx % #GRAVITY_CYCLE) + 1
    _gravityDir = GRAVITY_CYCLE[_gravityIdx]
    updateGravArrow()

    -- Apply gravity in new direction immediately so tiles settle
    GL.applyGravity(_grid, _gravityDir)
    syncGravity()
    removeOrphans()
    -- Brief flash on arrow
    if _gravArrow then
        transition.from(_gravArrow,{xScale=2,yScale=2,time=300,transition=easing.outElastic})
    end
end

-- ── Chain reactions (same as Basic mode) ─────────────────────────────────────

local function doChainStep(depth, onDone)
    if depth > settings.CHAIN.MAX_DEPTH then onDone(); return end
    local chains = GL.findChains(_grid)
    if #chains == 0 then onDone(); return end

    if _chainLabel then
        _chainLabel.text=(depth>1) and ("CHAIN x"..depth.."!") or "CHAIN!"
        _chainLabel.alpha=1
        transition.from(_chainLabel,{xScale=1.5,yScale=1.5,time=160,transition=easing.outElastic})
        if _chainTimer then timer.cancel(_chainTimer) end
        _chainTimer=timer.performWithDelay(700,function()
            transition.to(_chainLabel,{alpha=0,time=200})
        end)
    end

    for _,group in ipairs(chains) do
        local dest=group[1]
        for _,c in ipairs(group) do if c.i>dest.i then dest=c end end
        local dx = dest.obj and dest.obj.x or 0
        local dy = dest.obj and dest.obj.y or 0
        for _,c in ipairs(group) do
            if c~=dest then
                local mo=c.obj; c.num=nil; c.obj=nil; c.isBomb=false
                if mo then Tile.animateMerge(mo,dx,dy) end
            end
        end
        local destRef, mNum = GL.executeChain(_grid,group)
        local pts = scoreHelper.chainScore(mNum,#group,depth) * _maniaMult
        _totalScore = _totalScore + math.floor(pts)
        if _totalScore > _highScore then
            _highScore = _totalScore
            settingsModel.setHighScore(_highScore)
        end
        updateScoreUI()
        Tile.upgrade(destRef, _tileGroup, tileOnTap)
    end

    timer.performWithDelay(settings.CHAIN.ANIM_MS+settings.CHAIN.DELAY_MS, function()
        GL.applyGravity(_grid,_gravityDir)
        syncGravity(); removeOrphans(); refillEmpty()
        timer.performWithDelay(settings.VISUAL.FALL_ANIM_MS+30, function()
            doChainStep(depth+1,onDone)
        end)
    end)
end

-- ── Post-merge pipeline ───────────────────────────────────────────────────────

local function runPostMerge()
    timer.performWithDelay(settings.VISUAL.MERGE_ANIM_MS+20, function()
        GL.applyGravity(_grid,_gravityDir)
        syncGravity(); removeOrphans(); refillEmpty()
        timer.performWithDelay(settings.VISUAL.FALL_ANIM_MS+30, function()
            doChainStep(1, function()
                if not GL.hasMoves(_grid) then
                    _gameState="gameover"; _touchEnabled=false; cancelTimers()
                    timer.performWithDelay(400, function()
                        composer.showOverlay("scenes.gameover",{
                            isModal=true,effect="fromTop",time=300,
                            params={isGameOver=true,score=_totalScore,highScore=_highScore,
                                maxTile=_maxTile,isMania=true,merges=_mergeCount},
                        })
                    end)
                else
                    _touchEnabled = true
                end
            end)
        end)
    end)
end

-- ── Bomb blast ────────────────────────────────────────────────────────────────

local function doBombBlast(tappedCell)
    local blastCells = GL.getBombBlast(_grid,tappedCell.i,tappedCell.j)
    Tile.spawnBombBlast(_tileGroup,tappedCell.obj.x,tappedCell.obj.y)
    audioHelper.playBomb()
    local pts=0
    for k,cell in ipairs(blastCells) do
        if cell.obj then
            Tile.setBombPulse(cell.obj,false)
            local obj=cell.obj; cell.obj=nil; cell.num=nil; cell.isBomb=false
            transition.to(obj,{delay=(k-1)*40,xScale=1.6,yScale=1.6,alpha=0,time=260,
                transition=easing.outQuad,onComplete=function() display.remove(obj) end})
        end
        pts=pts+(cell.num and cell.num*settings.BOMB.SCORE_PER_NUM or 0)
    end
    _totalScore=_totalScore+math.floor(pts*_maniaMult)
    if _totalScore>_highScore then _highScore=_totalScore; settingsModel.setHighScore(_highScore) end
    updateScoreUI()
    timer.performWithDelay(300+(#blastCells*40), function() runPostMerge() end)
end

-- ── Tile tap ──────────────────────────────────────────────────────────────────

tileOnTap = function(event)
    if not _touchEnabled then return true end
    _touchEnabled = false
    local obj  = event.target
    local cell = _grid[obj.i][obj.j]

    if cell.isBomb then doBombBlast(cell); return true end

    local group = GL.getConnected(_grid, obj.i, obj.j)
    if #group < 2 then
        transition.to(obj,{xScale=1.12,yScale=1.12,time=80,transition=easing.outQuad,
            onComplete=function() transition.to(obj,{xScale=1,yScale=1,time=80}) end})
        _touchEnabled=true; return true
    end

    local destX,destY = cell.obj.x, cell.obj.y
    local mergedNum   = cell.num
    _mergeCount = _mergeCount+1

    -- Multiplier ramp-up
    _mergesUntilMultUp = _mergesUntilMultUp-1
    if _mergesUntilMultUp <= 0 then
        _maniaMult = _maniaMult + settings.MANIA.MULT_STEP_SIZE
        _mergesUntilMultUp = settings.MANIA.MULT_STEP_MERGES
        updateMultLabel()
        transition.from(_multLabel,{xScale=1.5,yScale=1.5,time=200,transition=easing.outElastic})
    end

    -- Bomb counter
    _mergesUntilBomb = _mergesUntilBomb-1
    if _mergesUntilBomb <= 0 then
        _mergesUntilBomb = settings.MANIA.BOMB_INTERVAL
    end

    for _,c in ipairs(group) do
        if c~=cell then
            local mo=c.obj; c.num=nil; c.obj=nil; c.isBomb=false
            if mo then Tile.animateMerge(mo,destX,destY) end
        end
    end

    local pts = scoreHelper.calculate(mergedNum,#group,1,false) * _maniaMult
    _totalScore=_totalScore+math.floor(pts)
    if _totalScore>_highScore then _highScore=_totalScore; settingsModel.setHighScore(_highScore) end
    updateScoreUI()

    Tile.upgrade(cell,_tileGroup,tileOnTap)
    if cell.num > _maxTile then _maxTile=cell.num end
    audioHelper.playMerge(cell.num)

    -- Reset the auto-drop countdown bar on each merge (reward for activity)
    restartDropBar()
    runPostMerge()
    return true
end

-- ── Build board ───────────────────────────────────────────────────────────────

local function buildBoard()
    if _tileGroup then
        for i=_tileGroup.numChildren,1,-1 do display.remove(_tileGroup[i]) end
    end
    _totalScore=0; _highScore=settingsModel.getHighScore()
    _maxTile=settings.GAME.START_MAX_TILE
    _touchEnabled=true; _gameState="running"
    _gravityIdx=1; _gravityDir="down"
    _maniaMult=1.0
    _mergesUntilMultUp=settings.MANIA.MULT_STEP_MERGES
    _mergesUntilBomb=settings.MANIA.BOMB_INTERVAL
    _mergeCount=0

    _grid=GL.buildGrid(); GL.populateGrid(_grid,_maxTile,nil)
    for i=1,GRID do for j=1,GRID do
        if _grid[i][j].num then drawTile(_grid[i][j]) end
    end end
    updateScoreUI(); updateMultLabel(); updateGravArrow()
    restartDropBar()

    cancelTimers()

    -- Auto-drop timer
    _autoDropTimer = timer.performWithDelay(settings.MANIA.FALL_INTERVAL_MS, function()
        autoDrop(); restartDropBar()
    end, 0)

    -- Gravity rotation timer
    _gravityTimer = timer.performWithDelay(settings.MANIA.GRAVITY_FLIP_MS, function()
        rotateGravity()
    end, 0)
end

-- ── Scene lifecycle ───────────────────────────────────────────────────────────

function scene:create(event)
    _sceneGroup = self.view

    _bgRect = display.newRect(_sceneGroup,
        display.contentCenterX,display.contentCenterY,
        display.actualContentWidth,display.actualContentHeight)
    _bgRect:setFillColor(unpack(settings.COLOR.BACKGROUND))

    -- Grid panel
    local panelSize = GRID*TILE_S+12
    local panel = display.newRoundedRect(_sceneGroup,display.contentCenterX,display.contentCenterY+30,panelSize,panelSize,12)
    panel:setFillColor(unpack(settings.COLOR.GRID_BG))

    -- Cell backgrounds
    local cellBg = display.newGroup(); _sceneGroup:insert(cellBg)
    for i=1,GRID do for j=1,GRID do
        local x,y=gridToScreen(i,j)
        local c=display.newRoundedRect(cellBg,x,y,TILE_S-6,TILE_S-6,settings.VISUAL.TILE_CORNER)
        c:setFillColor(unpack(settings.COLOR.GRID_CELL))
    end end

    _tileGroup = display.newGroup(); _sceneGroup:insert(_tileGroup)

    -- Drop countdown bar (thin rect at top of grid)
    local gTop = display.contentCenterY - GRID*TILE_S*0.5 + 30
    local barW = display.actualContentWidth - 20
    _dropBarBg = display.newRect(_sceneGroup,display.contentCenterX,gTop-6,barW,5)
    _dropBarBg:setFillColor(0.22,0.22,0.28)
    _dropBar   = display.newRect(_sceneGroup,display.contentCenterX - barW/2,gTop-6,barW,5)
    _dropBar.anchorX = 0
    _dropBar:setFillColor(1,0.75,0.2)

    -- Header
    local hY = 38
    local function makeBox(cx,lbl)
        local bg2=display.newRoundedRect(_sceneGroup,cx,hY,90,44,8)
        bg2:setFillColor(unpack(settings.COLOR.GRID_BG))
        display.newText{parent=_sceneGroup,text=lbl,x=cx,y=hY-9,font=settings.FONT.NORMAL,fontSize=9}:setFillColor(0.55)
        local vl=display.newText{parent=_sceneGroup,text="0",x=cx,y=hY+8,font=settings.FONT.BOLD,fontSize=20}
        return vl
    end
    _scoreLabel = makeBox(display.contentCenterX-58,"SCORE")
    _scoreLabel:setFillColor(unpack(settings.COLOR.SCORE))
    _highLabel  = makeBox(display.contentCenterX+58,"BEST")
    _highLabel:setFillColor(unpack(settings.COLOR.HIGH_SCORE))

    -- Gravity arrow (top-left)
    _gravArrow = display.newText{parent=_sceneGroup,text="v",
        x=22,y=38,font=settings.FONT.BOLD,fontSize=26}
    _gravArrow:setFillColor(unpack(settings.COLOR.CHAIN_LABEL))

    -- Mania multiplier (top-right)
    _multLabel = display.newText{parent=_sceneGroup,text="x1.0",
        x=display.contentWidth-22,y=38,font=settings.FONT.BOLD,fontSize=18}
    _multLabel.anchorX=1
    _multLabel:setFillColor(1,0.75,0.2)

    -- Chain label
    local aboveY = display.contentCenterY - GRID*TILE_S*0.5 - 10
    _chainLabel = display.newText{parent=_sceneGroup,text="",
        x=display.contentCenterX,y=aboveY,font=settings.FONT.BOLD,fontSize=20}
    _chainLabel:setFillColor(unpack(settings.COLOR.CHAIN_LABEL))
    _chainLabel.alpha=0

    -- Back / menu button
    local menuBtn=display.newText{parent=_sceneGroup,text="=",x=display.contentCenterX,y=hY,
        font=settings.FONT.BOLD,fontSize=20}
    menuBtn:setFillColor(0.40)
    menuBtn:addEventListener("tap",function()
        audioHelper.playTap()
        cancelTimers()
        composer.gotoScene("scenes.menu",{effect="fade",time=300})
        return true
    end)

    -- Footer
    local foot=display.newText{parent=_sceneGroup,
        text="MANIA  Tiles fall every "..math.floor(settings.MANIA.FALL_INTERVAL_MS/1000).."s",
        x=display.contentCenterX,y=display.contentHeight-22,
        font=settings.FONT.NORMAL,fontSize=11,align="center"}
    foot:setFillColor(0.4)

    buildBoard()
end

function scene:show(event)
    if event.phase=="will" then _touchEnabled=(_gameState=="running") end
end

function scene:hide(event)
    if event.phase=="will" then
        _touchEnabled=false; cancelTimers()
    end
end

function scene:destroy(event)
    cancelTimers()
end

scene:addEventListener("create",scene)
scene:addEventListener("show",scene)
scene:addEventListener("hide",scene)
scene:addEventListener("destroy",scene)
return scene
