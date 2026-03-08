-----------------------------------------------------------------------------------------
--
-- scenes/stageSelect.lua
-- Get10 v4.0 — Advanced Mode: Stage Selection Screen
--
-- WHAT THIS SCENE DOES
-- ====================
-- Shows all 50 Advanced stages as a paginated 3×4 grid (12 stages per page).
-- Stages unlock sequentially — stage N+1 unlocks when N is completed.
-- Stage 1 is always unlocked.
--
-- PAGINATION
-- ==========
-- 12 stages per page (3 cols × 4 rows). 50 stages = 5 pages.
-- Prev / Next buttons sit at the bottom. Current page indicator shown between them.
--
-- TILE STATES
-- ===========
--   Dark bg  = locked
--   Grid bg  = unlocked / current
--   Green bg = completed  (shows ✓)
--
-- USAGE
-- =====
-- Called from menu.lua via:
--   composer.gotoScene("scenes.stageSelect", { effect="slideLeft", time=300 })
--
-- CHANGELOG:
--   v4.0  2026-03-03  Initial (ScrollView 5-col, 52×52 tiles, 999 stages)
--   v4.1  2026-03-07  Replaced ScrollView with 3×4 paginated grid (12/page, 50 stages)
--
-----------------------------------------------------------------------------------------

local composer    = require("composer")
local settings    = require("config.settings")
local saveState   = require("app.helpers.saveState")
local audioHelper = require("app.helpers.audioHelper")
local levelLoader = require("app.helpers.levelLoader")

local scene = composer.newScene()

-- ── Layout constants ───────────────────────────────────────────────────────────
local COLS            = 3
local ROWS            = 4
local STAGES_PER_PAGE = COLS * ROWS   -- 12
local CELL_W          = 90
local CELL_H          = 82
local CELL_PAD        = 10
local TOTAL_STAGES    = 50
local TOTAL_PAGES     = math.ceil(TOTAL_STAGES / STAGES_PER_PAGE)   -- 5
local HEADER_H        = 65
local FOOTER_H        = 58

-- ── Module-level state ─────────────────────────────────────────────────────────
local _sv           = nil
local _gridGroup    = nil
local _pageLabel    = nil
local _prevBtn      = nil
local _nextBtn      = nil
local _currentPage  = 1
local _currentStage = 1   -- player's furthest unlocked stage

-- ── Build one stage tile ───────────────────────────────────────────────────────
--- @param parent     DisplayGroup
--- @param num        number        stage number (1–50)
--- @param completed  boolean       stage already beaten
--- @param locked     boolean       not yet reachable
--- @param onTap      function(num)
--- @return           DisplayGroup
local function buildStageTile( parent, num, completed, locked, onTap )
    local g = display.newGroup()
    parent:insert(g)

    -- Background
    local bg = display.newRoundedRect(g, 0, 0, CELL_W, CELL_H, 10)
    if locked then
        bg:setFillColor(0.20, 0.20, 0.26)
    elseif completed then
        bg:setFillColor(0.20, 0.50, 0.28)
    else
        bg:setFillColor(unpack(settings.COLOR.GRID_BG))
    end

    -- Stage number
    local numY = completed and 12 or 0
    local numLbl = display.newText{
        parent   = g,
        text     = tostring(num),
        x        = 0, y = numY,
        font     = settings.FONT.BOLD,
        fontSize = 22,
    }
    if locked then
        numLbl:setFillColor(0.40)
    elseif completed then
        numLbl:setFillColor(0.70, 1.00, 0.70)
    else
        numLbl:setFillColor(unpack(settings.COLOR.SCORE))
    end

    -- Completion check
    if completed then
        local ck = display.newText{
            parent = g, text = "✓",
            x = 0, y = -20,
            font = settings.FONT.BOLD, fontSize = 20,
        }
        ck:setFillColor(0.70, 1.00, 0.70)
    end

    -- Lock icon
    if locked then
        local lk = display.newText{
            parent = g, text = "🔒",
            x = 0, y = 0,
            font = settings.FONT.NORMAL, fontSize = 20,
        }
        lk:setFillColor(0.40)
        numLbl.alpha = 0.30
    end

    -- Tap (unlocked only)
    if not locked then
        local function doTap()
            audioHelper.playTap()
            onTap(num)
            return true
        end
        bg:addEventListener("tap", doTap)
        g:addEventListener("tap",  doTap)
    end

    return g
end

-- ── Render a page of stage tiles ──────────────────────────────────────────────
--- @param page  number  1-based
local function showPage( page )
    if _gridGroup then
        _gridGroup:removeSelf()
        _gridGroup = nil
    end
    _gridGroup = display.newGroup()
    _sv:insert(_gridGroup)

    local startStage = (page - 1) * STAGES_PER_PAGE + 1
    local endStage   = math.min(page * STAGES_PER_PAGE, TOTAL_STAGES)

    local gridTotalW = COLS * CELL_W + (COLS - 1) * CELL_PAD
    local gridTotalH = ROWS * CELL_H + (ROWS - 1) * CELL_PAD
    local gridAreaTop = HEADER_H + 4
    local gridAreaBot = display.actualContentHeight - FOOTER_H - 4
    local originX = display.contentCenterX - gridTotalW * 0.5 + CELL_W * 0.5
    local originY = (gridAreaTop + gridAreaBot) * 0.5 - gridTotalH * 0.5 + CELL_H * 0.5

    local function onStageTap( num )
        local data = levelLoader.loadAdvanced(num)
        composer.removeScene("scenes.game")
        composer.gotoScene("scenes.game", {
            effect = "fade", time = 300,
            params = { mode = "advanced", stageNum = num, levelData = data, gridSize = 6 },
        })
    end

    for n = startStage, endStage do
        local idx  = n - startStage
        local col  = idx % COLS
        local row  = math.floor(idx / COLS)
        local cx   = originX + col * (CELL_W + CELL_PAD)
        local cy   = originY + row * (CELL_H + CELL_PAD)

        local tile = buildStageTile(
            _gridGroup, n,
            n < _currentStage,
            n > _currentStage,
            onStageTap
        )
        tile.x = cx
        tile.y = cy
    end

    _pageLabel.text = page .. " / " .. TOTAL_PAGES
    _prevBtn.alpha  = (page > 1)            and 1.0 or 0.30
    _nextBtn.alpha  = (page < TOTAL_PAGES)  and 1.0 or 0.30

    -- Re-insert footer so it stays on top of _gridGroup in z-order.
    -- _gridGroup is inserted into _sv each call, pushing footer behind it.
    if _prevBtn   then _sv:insert(_prevBtn)   end
    if _pageLabel then _sv:insert(_pageLabel) end
    if _nextBtn   then _sv:insert(_nextBtn)   end
end

-- ── Scene lifecycle ────────────────────────────────────────────────────────────

function scene:create( event )
    local DEV_UNLOCK_ALL = true   -- TODO: set false before release
    _sv           = self.view
    _currentStage = DEV_UNLOCK_ALL and (TOTAL_STAGES + 1) or (saveState.loadAdvancedStage() or 1)
    _currentPage  = 1

    local bg = display.newRect(_sv,
        display.contentCenterX, display.contentCenterY,
        display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(unpack(settings.COLOR.BACKGROUND))

    local backBtn = display.newText{
        parent = _sv, text = "‹ Back",
        x = 40, y = 36,
        font = settings.FONT.BOLD, fontSize = 16,
    }
    backBtn:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    backBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.gotoScene("scenes.menu", { effect="slideRight", time=300 })
        return true
    end)

    local hdr = display.newText{
        parent = _sv, text = "STAGES",
        x = display.contentCenterX, y = 36,
        font = settings.FONT.BOLD, fontSize = 26,
    }
    hdr:setFillColor(unpack(settings.COLOR.SCORE))

    local footerY = display.actualContentHeight - FOOTER_H * 0.5

    _prevBtn = display.newText{
        parent = _sv, text = "‹",
        x = 36, y = footerY,
        font = settings.FONT.BOLD, fontSize = 32,
    }
    _prevBtn:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    _prevBtn:addEventListener("tap", function()
        if _currentPage > 1 then
            audioHelper.playTap()
            _currentPage = _currentPage - 1
            showPage(_currentPage)
        end
        return true
    end)

    _pageLabel = display.newText{
        parent = _sv, text = "1 / " .. TOTAL_PAGES,
        x = display.contentCenterX, y = footerY,
        font = settings.FONT.NORMAL, fontSize = 16,
    }
    _pageLabel:setFillColor(0.70, 0.70, 0.75)

    _nextBtn = display.newText{
        parent = _sv, text = "›",
        x = display.actualContentWidth - 36, y = footerY,
        font = settings.FONT.BOLD, fontSize = 32,
    }
    _nextBtn:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    _nextBtn:addEventListener("tap", function()
        if _currentPage < TOTAL_PAGES then
            audioHelper.playTap()
            _currentPage = _currentPage + 1
            showPage(_currentPage)
        end
        return true
    end)

    showPage(_currentPage)
end

function scene:show( event )
    if event.phase == "did" then
        local DEV_UNLOCK_ALL = true   -- TODO: set false before release
        _currentStage = DEV_UNLOCK_ALL and (TOTAL_STAGES + 1) or (saveState.loadAdvancedStage() or 1)
        showPage(_currentPage)
    end
end

function scene:hide( event )    end

function scene:destroy( event )
    _sv           = nil
    _gridGroup    = nil
    _pageLabel    = nil
    _prevBtn      = nil
    _nextBtn      = nil
    _currentPage  = 1
    _currentStage = 1
end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
