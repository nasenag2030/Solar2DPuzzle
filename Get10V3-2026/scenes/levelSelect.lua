-----------------------------------------------------------------------------------------
--
-- scenes/levelSelect.lua
-- Get10 v4.0 — Intermediate Mode: Level Selection Screen
--
-- WHAT THIS SCENE DOES
-- ====================
-- Shows all 50 Intermediate levels as a paginated 3×4 grid (12 levels per page).
-- Each tile shows: level number, star rating (0–3), and lock state.
-- Levels unlock sequentially — level N+1 unlocks when N earns ≥ 1 star.
-- Level 1 is always unlocked.
--
-- PAGINATION
-- ==========
-- 12 levels per page (3 cols × 4 rows). 50 levels = 5 pages.
-- Prev / Next buttons sit at the bottom. Current page indicator shown between them.
--
-- STAR DISPLAY
-- ============
--   ★★★  grey   = locked
--   ★☆☆  white  = completed (1 star)
--   ★★☆  white  = completed with par moves (2 stars)
--   ★★★  gold   = perfect (3 stars — no bomb used)
--
-- USAGE
-- =====
-- Called from menu.lua via:
--   composer.gotoScene("scenes.levelSelect", { effect="slideLeft", time=300 })
--
-- CHANGELOG:
--   v4.0  2026-03-03  Initial (ScrollView 3-col)
--   v4.1  2026-03-07  Replaced ScrollView with 3×4 paginated grid (12/page)
--
-----------------------------------------------------------------------------------------

local composer      = require("composer")
local settings      = require("config.settings")
local saveState     = require("app.helpers.saveState")
local audioHelper   = require("app.helpers.audioHelper")
local levelLoader   = require("app.helpers.levelLoader")

local scene = composer.newScene()

-- ── Layout constants ───────────────────────────────────────────────────────────
local COLS            = 3
local ROWS            = 4
local LEVELS_PER_PAGE = COLS * ROWS   -- 12
local CELL_W          = 90
local CELL_H          = 82
local CELL_PAD        = 10
local TOTAL_LEVELS    = 50
local TOTAL_PAGES     = math.ceil(TOTAL_LEVELS / LEVELS_PER_PAGE)   -- 5
local HEADER_H        = 65    -- pixels reserved for title + back button
local FOOTER_H        = 58    -- pixels reserved for pagination bar

-- ── Module-level state (reset each create) ────────────────────────────────────
local _sv           = nil   -- scene view group
local _gridGroup    = nil   -- DisplayGroup holding current page tiles
local _pageLabel    = nil   -- "2 / 5" text
local _prevBtn      = nil
local _nextBtn      = nil
local _currentPage  = 1
local _allStars     = {}
local _unlocked     = {}

-- ── Helper: build unlock table ────────────────────────────────────────────────
--- @return nil  (writes into _unlocked)
local function computeUnlocked()
    _unlocked = {}
    local DEV_UNLOCK_ALL = true   -- TODO: set false before release
    for n = 1, TOTAL_LEVELS do
        _unlocked[n] = DEV_UNLOCK_ALL or (n == 1) or ((_allStars[n - 1] or 0) >= 1)
    end
end

-- ── Build one level tile ───────────────────────────────────────────────────────
--- @param parent  DisplayGroup  container to insert into
--- @param num     number        level number (1–50)
--- @param stars   number        0–3
--- @param locked  boolean
--- @param onTap   function(num)
--- @return        DisplayGroup
local function buildLevelTile( parent, num, stars, locked, onTap )
    local g  = display.newGroup()
    parent:insert(g)

    -- Background card
    local bg = display.newRoundedRect(g, 0, 0, CELL_W, CELL_H, 10)
    if locked then
        bg:setFillColor(0.20, 0.20, 0.26)
    else
        bg:setFillColor(unpack(settings.COLOR.GRID_BG))
    end

    -- Level number
    local numLbl = display.newText{
        parent   = g,
        text     = tostring(num),
        x        = 0, y = -12,
        font     = settings.FONT.BOLD,
        fontSize = 22,
    }
    if locked then
        numLbl:setFillColor(0.40)
    else
        numLbl:setFillColor(unpack(settings.COLOR.SCORE))
    end

    -- Star row
    local starStr = ""
    for s = 1, 3 do
        starStr = starStr .. (s <= stars and "★" or "☆")
    end
    local starLbl = display.newText{
        parent   = g,
        text     = starStr,
        x        = 0, y = 18,
        font     = settings.FONT.NORMAL,
        fontSize = 15,
    }
    if stars == 3 then
        starLbl:setFillColor(unpack(settings.COLOR.SCORE))
    elseif stars > 0 then
        starLbl:setFillColor(0.85, 0.85, 0.85)
    else
        starLbl:setFillColor(0.35, 0.35, 0.40)
    end

    -- Lock icon overlay
    if locked then
        local lockLbl = display.newText{
            parent = g, text = "🔒",
            x = 0, y = 2,
            font = settings.FONT.NORMAL, fontSize = 20,
        }
        lockLbl:setFillColor(0.45)
        numLbl.alpha  = 0.35
        starLbl.alpha = 0.25
    end

    -- Tap handler (unlocked tiles only)
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

-- ── Render a page of level tiles ──────────────────────────────────────────────
--- @param page  number  1-based page index
local function showPage( page )
    if _gridGroup then
        _gridGroup:removeSelf()
        _gridGroup = nil
    end
    _gridGroup = display.newGroup()
    _sv:insert(_gridGroup)

    local startLevel = (page - 1) * LEVELS_PER_PAGE + 1
    local endLevel   = math.min(page * LEVELS_PER_PAGE, TOTAL_LEVELS)

    local gridTotalW = COLS * CELL_W + (COLS - 1) * CELL_PAD
    local gridTotalH = ROWS * CELL_H + (ROWS - 1) * CELL_PAD
    local gridAreaTop = HEADER_H + 4
    local gridAreaBot = display.actualContentHeight - FOOTER_H - 4
    local originX = display.contentCenterX - gridTotalW * 0.5 + CELL_W * 0.5
    local originY = (gridAreaTop + gridAreaBot) * 0.5 - gridTotalH * 0.5 + CELL_H * 0.5

    local function onLevelTap( num )
        local levelData = levelLoader.loadIntermediate(num)
        composer.removeScene("scenes.game")
        composer.gotoScene("scenes.game", {
            effect = "fade", time = 300,
            params = {
                mode      = "intermediate",
                levelNum  = num,
                levelData = levelData,
                gridSize  = 6,
            },
        })
    end

    for n = startLevel, endLevel do
        local idx  = n - startLevel
        local col  = idx % COLS
        local row  = math.floor(idx / COLS)
        local cx   = originX + col * (CELL_W + CELL_PAD)
        local cy   = originY + row * (CELL_H + CELL_PAD)

        local tile = buildLevelTile(
            _gridGroup, n,
            _allStars[n] or 0,
            not _unlocked[n],
            onLevelTap
        )
        tile.x = cx
        tile.y = cy
    end

    _pageLabel.text = page .. " / " .. TOTAL_PAGES
    _prevBtn.alpha  = (page > 1)            and 1.0 or 0.30
    _nextBtn.alpha  = (page < TOTAL_PAGES)  and 1.0 or 0.30

    -- Re-insert footer so it stays on top of _gridGroup in z-order.
    -- _gridGroup is inserted into _sv each call, pushing footer behind it.
    if _prevBtn  then _sv:insert(_prevBtn)  end
    if _pageLabel then _sv:insert(_pageLabel) end
    if _nextBtn  then _sv:insert(_nextBtn)  end
end

-- ── Scene lifecycle ────────────────────────────────────────────────────────────

function scene:create( event )
    _sv           = self.view
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
        parent = _sv, text = "BRICK",
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

    _allStars = saveState.loadIntermediateStars() or {}
    computeUnlocked()
    showPage(_currentPage)
end

function scene:show( event )
    if event.phase == "did" then
        _allStars = saveState.loadIntermediateStars() or {}
        computeUnlocked()
        showPage(_currentPage)
    end
end

function scene:hide( event )   end

function scene:destroy( event )
    _sv          = nil
    _gridGroup   = nil
    _pageLabel   = nil
    _prevBtn     = nil
    _nextBtn     = nil
    _allStars    = {}
    _unlocked    = {}
    _currentPage = 1
end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
