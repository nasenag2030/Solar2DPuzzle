-----------------------------------------------------------------------------------------
--
-- scenes/gridSelect.lua
-- Get10 v4.0 — Freeplay Grid Size Selector
--
-- Let the player pick a grid size before launching Freeplay mode.
-- Classic rules apply: no bombs, no undo, no chains.
-- Grid size options: 3×3 through 10×10.
--
-- Each grid size is its own Game Style (save key "freeplay_N"), so resume
-- data and high scores are tracked independently per size.
-- A small orange dot appears top-right on any button that has a saved game.
--
-- CHANGELOG:
--   v4.0  2026-03-06  Initial
--   v4.1  2026-03-07  Per-style save/HS; resume indicator dots
--
-----------------------------------------------------------------------------------------

local composer    = require("composer")
local settings    = require("config.settings")
local audioHelper = require("app.helpers.audioHelper")
local saveState   = require("app.helpers.saveState")

local scene = composer.newScene()

-- Resume dots keyed by grid size integer
local _dots = {}

local DOT_COLOR = { 1, 0.55, 0.1 }

local function refreshDots()
    for n, dot in pairs(_dots) do
        dot.isVisible = saveState.hasResume("freeplay_"..n)
    end
end

function scene:create( event )
    local g  = self.view
    local cx = display.contentCenterX
    local cy = display.contentCenterY

    -- Background
    local bg = display.newRect(g, cx, cy, display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(unpack(settings.COLOR.BACKGROUND))

    -- Title
    local title = display.newText{ parent=g, text="FREEPLAY",
        x=cx, y=cy-220, font=settings.FONT.BOLD, fontSize=28, align="center" }
    title:setFillColor(unpack(settings.COLOR.SCORE))

    local sub = display.newText{ parent=g, text="Choose your grid size",
        x=cx, y=cy-188, font=settings.FONT.NORMAL, fontSize=13, align="center" }
    sub:setFillColor(0.55)

    -- Back button
    local backBtn = display.newText{ parent=g, text="< BACK",
        x=cx, y=cy-160, font=settings.FONT.NORMAL, fontSize=13, align="center" }
    backBtn:setFillColor(0.55)
    backBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.gotoScene("scenes.modeSelect", { effect="slideRight", time=300 })
        return true
    end)

    -- Grid size buttons: 3x3 through 10x10 in a 2-column grid
    local sizes  = {3, 4, 5, 6, 7, 8, 9, 10}
    local btnW   = 96
    local btnH   = 52
    local colGap = 110
    local rowGap = 64
    local startX = cx - colGap / 2
    local startY = cy - 90

    for k, n in ipairs(sizes) do
        local col  = (k - 1) % 2
        local row  = math.floor((k-1) / 2)
        local bx   = startX + col * colGap
        local by   = startY + row * rowGap

        local col1 = (n == 5) and settings.COLOR.BUTTON_PRIMARY or settings.COLOR.BUTTON_SECONDARY
        local btn  = display.newRoundedRect(g, bx, by, btnW, btnH, 10)
        btn:setFillColor(unpack(col1))

        local lbl = display.newText{ parent=g,
            text=n.."x"..n,
            x=bx, y=by-5, font=settings.FONT.BOLD, fontSize=18 }
        lbl:setFillColor(1)

        local sub2 = display.newText{ parent=g,
            text=n*n.." tiles",
            x=bx, y=by+11, font=settings.FONT.NORMAL, fontSize=9 }
        sub2:setFillColor(1, 1, 1, 0.65)

        -- Resume indicator dot: top-right corner of button
        local dot = display.newCircle(g, bx+40, by-20, 5)
        dot:setFillColor(unpack(DOT_COLOR))
        dot.isVisible = false
        _dots[n] = dot

        local function onTap( gridN )
            return function()
                audioHelper.playTap()
                composer.gotoScene("scenes.game", { effect="fade", time=300,
                    params={ mode="freeplay", hasBombs=false, hasUndo=false,
                             hasChains=false, gridSize=gridN } })
                return true
            end
        end

        btn:addEventListener("tap",  onTap(n))
        lbl:addEventListener("tap",  onTap(n))
        sub2:addEventListener("tap", onTap(n))
    end

    refreshDots()
end

function scene:show( event )
    if event.phase == "did" then refreshDots() end
end

function scene:hide(e)  end
function scene:destroy(e) _dots = {} end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
