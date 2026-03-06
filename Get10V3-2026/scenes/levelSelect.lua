-----------------------------------------------------------------------------------------
--
-- scenes/levelSelect.lua
-- Get10 v4.0 — Intermediate Mode: Level Selection Screen
--
-- WHAT THIS SCENE DOES
-- ====================
-- Shows all 50 Intermediate levels as a scrollable grid of tiles.
-- Each tile shows: level number, star rating (0–3), and lock state.
-- Levels unlock sequentially — level N+1 unlocks when N earns ≥ 1 star.
-- Level 1 is always unlocked.
--
-- STAR DISPLAY
-- ============
--   ★★★  grey   = locked
--   ★☆☆  white  = completed (1 star)
--   ★★☆  white  = completed with par moves (2 stars)
--   ★★★  gold   = perfect (3 stars — no bomb used)
--
-- SCROLL
-- ======
-- Uses a simple ScrollView. Levels are laid out in a 3-column grid.
-- The ScrollView is 4 rows tall; remaining rows scroll below.
--
-- USAGE
-- =====
-- Called from menu.lua via:
--   composer.gotoScene("scenes.levelSelect", { effect="slideLeft", time=300 })
--
-- CHANGELOG:
--   v4.0  2026-03-03  Initial
--
-----------------------------------------------------------------------------------------

local composer      = require("composer")
local widget        = require("widget")
local settings      = require("config.settings")
local saveState     = require("app.helpers.saveState")
local audioHelper   = require("app.helpers.audioHelper")
local levelLoader   = require("app.helpers.levelLoader")

local scene = composer.newScene()

-- Layout constants
local COLS      = 3
local CELL_W    = 90
local CELL_H    = 90
local CELL_PAD  = 12
local TOTAL_LEVELS = 50
local SCROLL_H  = display.actualContentHeight - 100   -- leave room for header

-- ── Build one level tile ───────────────────────────────────────────────────────
-- Returns a DisplayGroup representing a single level button.
-- parent   : the group to insert into
-- num      : level number (1–50)
-- stars    : 0–3  (from saveState)
-- locked   : bool
-- onTap    : callback(num)

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
        x        = 0, y = -14,
        font     = settings.FONT.BOLD,
        fontSize = 24,
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
        x        = 0, y = 20,
        font     = settings.FONT.NORMAL,
        fontSize = 16,
    }
    if stars == 3 then
        starLbl:setFillColor(unpack(settings.COLOR.SCORE))     -- gold
    elseif stars > 0 then
        starLbl:setFillColor(0.85, 0.85, 0.85)                 -- white
    else
        starLbl:setFillColor(0.35, 0.35, 0.40)                 -- grey (locked)
    end

    -- Lock icon
    if locked then
        local lockLbl = display.newText{
            parent=g, text="🔒", x=0, y=0, font=settings.FONT.NORMAL, fontSize=22
        }
        lockLbl:setFillColor(0.45)
        numLbl.alpha  = 0.35
        starLbl.alpha = 0.25
    end

    -- Tap handler
    if not locked then
        bg:addEventListener("tap", function()
            audioHelper.playTap()
            onTap(num)
            return true
        end)
        g:addEventListener("tap", function()
            audioHelper.playTap()
            onTap(num)
            return true
        end)
    end

    return g
end

-- ── Scene create ──────────────────────────────────────────────────────────────

function scene:create( event )
    local sv = self.view

    -- Background
    local bg = display.newRect(sv,
        display.contentCenterX, display.contentCenterY,
        display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(unpack(settings.COLOR.BACKGROUND))

    -- Header
    local hdr = display.newText{
        parent = sv, text = "LEVELS",
        x = display.contentCenterX, y = 36,
        font = settings.FONT.BOLD, fontSize = 26,
    }
    hdr:setFillColor(unpack(settings.COLOR.SCORE))

    -- Back button
    local backBtn = display.newText{
        parent = sv, text = "‹ Back",
        x = 38, y = 36,
        font = settings.FONT.BOLD, fontSize = 16,
    }
    backBtn:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    backBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.gotoScene("scenes.menu", { effect="slideRight", time=300 })
        return true
    end)

    -- Load all star data
    local allStars = saveState.loadIntermediateStars() or {}

    -- Compute which levels are unlocked
    -- Level 1 always unlocked. Level N unlocked if (N-1) has ≥ 1 star.
    local unlocked = {}
    unlocked[1] = true
    for n = 2, TOTAL_LEVELS do
        unlocked[n] = (allStars[n-1] or 0) >= 1
    end

    -- Build scroll view
    local scrollView = widget.newScrollView{
        x          = display.contentCenterX,
        y          = display.contentCenterY + 30,
        width      = display.actualContentWidth - 20,
        height     = SCROLL_H,
        scrollWidth  = display.actualContentWidth - 20,
        scrollHeight = math.ceil(TOTAL_LEVELS / COLS) * (CELL_H + CELL_PAD) + CELL_PAD,
        horizontalScrollingEnabled = false,
        hideBackground = true,
        hideScrollBar  = false,
    }
    sv:insert(scrollView)

    -- Tap handler: go into a level
    local function onLevelTap( num )
        local levelData = levelLoader.loadIntermediate(num)
        composer.gotoScene("scenes.game", {
            effect = "fade", time = 300,
            params = {
                mode       = "intermediate",
                levelNum   = num,
                levelData  = levelData,
            },
        })
    end

    -- Lay out level tiles inside the scroll view
    local startX = CELL_W * 0.5 + CELL_PAD
    local startY = CELL_H * 0.5 + CELL_PAD

    for n = 1, TOTAL_LEVELS do
        local col  = ((n-1) % COLS)
        local row  = math.floor((n-1) / COLS)
        local cx   = startX + col * (CELL_W + CELL_PAD)
        local cy   = startY + row * (CELL_H + CELL_PAD)

        local tile = buildLevelTile(
            scrollView,
            n,
            allStars[n] or 0,
            not unlocked[n],
            onLevelTap
        )
        tile.x = cx
        tile.y = cy
    end
end

function scene:show(e)  end
function scene:hide(e)  end
function scene:destroy(e) end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
