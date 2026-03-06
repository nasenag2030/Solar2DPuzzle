-----------------------------------------------------------------------------------------
--
-- scenes/settings.lua
-- Get10 - Settings Overlay
-- v3.1.0
--
-- Modal overlay. Handles:
--   - Sound on/off toggle
--   - How to play instructions (includes bomb info)
--   - Lifetime stats display (best combo, total merges)
--
-- CHANGELOG:
--   v3.0.0  2026-03-03  Initial refactor
--   v3.1.0  2026-03-03  Dark theme, lifetime stats, bomb instructions
--
-----------------------------------------------------------------------------------------

local composer      = require("composer")
local settings      = require("config.settings")
local audioHelper   = require("app.helpers.audioHelper")
local saveState     = require("app.helpers.saveState")

local scene = composer.newScene()

function scene:create( event )
    local g = self.view

    -- Backdrop (tap to close)
    local backdrop = display.newRect(g,
        display.contentCenterX, display.contentCenterY,
        display.actualContentWidth, display.actualContentHeight)
    backdrop:setFillColor(0, 0, 0, 0.65)
    backdrop:addEventListener("tap", function()
        composer.hideOverlay()
        return true
    end)

    local cx = display.contentCenterX
    local cy = display.contentCenterY

    -- Card
    local card = display.newRoundedRect(g, cx, cy, 276, 420, 18)
    card:setFillColor(0.14, 0.14, 0.18)
    card.strokeWidth = 1
    card:setStrokeColor(0.30, 0.30, 0.38)

    -- Title
    local title = display.newText{
        parent=g, text="Settings",
        x=cx, y=cy - 190,
        font=settings.FONT.BOLD, fontSize=22,
    }
    title:setFillColor(0.90)

    -- ── Sound toggle ───────────────────────────────────────────────────────────
    local soundLbl = display.newText{
        parent=g, text="Sound",
        x=cx - 80, y=cy - 140,
        font=settings.FONT.NORMAL, fontSize=16,
    }
    soundLbl:setFillColor(0.70)

    local soundOn = audioHelper.isEnabled()

    local function soundColor( on )
        return on and settings.COLOR.SCORE or { 0.4, 0.4, 0.4 }
    end

    local soundToggle = display.newText{
        parent=g, text= soundOn and "ON" or "OFF",
        x=cx + 85, y=cy - 140,
        font=settings.FONT.BOLD, fontSize=16,
    }
    soundToggle:setFillColor(unpack(soundColor(soundOn)))

    soundToggle:addEventListener("tap", function()
        local newState = not audioHelper.isEnabled()
        audioHelper.setEnabled(newState)
        soundToggle.text = newState and "ON" or "OFF"
        soundToggle:setFillColor(unpack(soundColor(newState)))
        if newState then audioHelper.playTap() end
        return true
    end)

    -- Divider
    local div1 = display.newRect(g, cx, cy - 115, 238, 1)
    div1:setFillColor(0.25)

    -- ── How to play ────────────────────────────────────────────────────────────
    local howTitle = display.newText{
        parent=g, text="How to Play",
        x=cx, y=cy - 95,
        font=settings.FONT.BOLD, fontSize=14,
    }
    howTitle:setFillColor(0.70)

    local instructions = {
        "Tap a group of 2+ tiles with the same",
        "number — they merge into one higher tile.",
        "Chain merges quickly for a COMBO bonus!",
        "💣 Bomb tiles appear every 12 merges —",
        "   tap the bomb to clear a cross of 5 tiles.",
        "Reach tile 10 to win!",
    }

    for k, line in ipairs(instructions) do
        local t = display.newText{
            parent=g, text=line,
            x=cx, y=cy - 68 + (k-1)*22,
            font=settings.FONT.NORMAL, fontSize=11,
            width=244, align="center",
        }
        t:setFillColor(0.50)
    end

    -- Divider
    local div2 = display.newRect(g, cx, cy + 80, 238, 1)
    div2:setFillColor(0.25)

    -- ── Lifetime stats ─────────────────────────────────────────────────────────
    local statsTitle = display.newText{
        parent=g, text="Your Stats",
        x=cx, y=cy + 100,
        font=settings.FONT.BOLD, fontSize=14,
    }
    statsTitle:setFillColor(0.70)

    local stats = saveState.loadStats()

    local stat1 = display.newText{
        parent=g,
        text="Best combo: " .. (stats.bestCombo or 0) .. " tiles",
        x=cx, y=cy + 125,
        font=settings.FONT.NORMAL, fontSize=12,
    }
    stat1:setFillColor(unpack(settings.COLOR.COMBO_LABEL))

    local stat2 = display.newText{
        parent=g,
        text="Total merges: " .. (stats.totalMerges or 0),
        x=cx, y=cy + 148,
        font=settings.FONT.NORMAL, fontSize=12,
    }
    stat2:setFillColor(0.50)

    -- ── Close button ───────────────────────────────────────────────────────────
    local closeBtn = display.newRoundedRect(g, cx, cy + 185, 170, 44, 10)
    closeBtn:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    closeBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.hideOverlay()
        return true
    end)

    local closeLbl = display.newText{
        parent=g, text="CLOSE",
        x=cx, y=cy + 185,
        font=settings.FONT.BOLD, fontSize=16,
    }
    closeLbl:setFillColor(1)
    closeLbl:addEventListener("tap", function()
        audioHelper.playTap()
        composer.hideOverlay()
        return true
    end)
end

function scene:show( event )  end
function scene:hide( event )  end
function scene:destroy( event ) end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
