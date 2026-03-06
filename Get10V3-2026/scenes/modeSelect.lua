-----------------------------------------------------------------------------------------
--
-- scenes/modeSelect.lua
-- Get10 v4.0 — Mode Select Sub-Menu
--
-- Reached from the main menu via NEW STYLE button.
-- Shows all modes beyond Classic:
--   DASH       — Bombs + Undo, 5×5 (current full feature set)
--   CHALLENGE  — Bombs + Undo + Chains, 5×5
--   FREEPLAY   — Classic rules, selectable grid size 3×3 to 10×10
--   LEVELS     — Intermediate, 50 curated levels
--   STAGES     — Advanced, 999 shaped stages
--   MANIA      — Survival chaos mode
--
-- CHANGELOG:
--   v4.0  2026-03-06  Initial
--
-----------------------------------------------------------------------------------------

local composer      = require("composer")
local settings      = require("config.settings")
local audioHelper   = require("app.helpers.audioHelper")

local scene = composer.newScene()

function scene:create( event )
    local g  = self.view
    local cx = display.contentCenterX
    local cy = display.contentCenterY

    -- Background
    local bg = display.newRect(g, cx, cy, display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(unpack(settings.COLOR.BACKGROUND))

    -- Title
    local title = display.newText{ parent=g, text="CHOOSE MODE",
        x=cx, y=cy-210, font=settings.FONT.BOLD, fontSize=22, align="center" }
    title:setFillColor(unpack(settings.COLOR.SCORE))

    -- Back button
    local backBtn = display.newText{ parent=g, text="< BACK",
        x=cx, y=cy-170, font=settings.FONT.NORMAL, fontSize=13, align="center" }
    backBtn:setFillColor(0.55)
    backBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.gotoScene("scenes.menu", { effect="slideRight", time=300 })
        return true
    end)

    -- Button factory (same style as menu.lua)
    local function makeBtn( label, subtitle, yPos, primary, onTap )
        local col = primary and settings.COLOR.BUTTON_PRIMARY or settings.COLOR.BUTTON_SECONDARY
        local btn = display.newRoundedRect(g, cx, yPos, 220, 50, 12)
        btn:setFillColor(unpack(col))
        btn:addEventListener("tap", onTap)

        local lbl = display.newText{ parent=g, text=label, x=cx, y=yPos-4,
            font=settings.FONT.BOLD, fontSize=18 }
        lbl:setFillColor(1)
        lbl:addEventListener("tap", onTap)

        if subtitle then
            local sub = display.newText{ parent=g, text=subtitle, x=cx, y=yPos+11,
                font=settings.FONT.NORMAL, fontSize=10 }
            sub:setFillColor(1, 1, 1, 0.65)
            sub:addEventListener("tap", onTap)
        end
    end

    local btnY = cy - 120

    -- DASH: bombs + undo, no chains
    makeBtn("DASH", "Bombs + Undo · 5x5", btnY, true, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.game", { effect="fade", time=300,
            params={ mode="dash", hasBombs=true, hasUndo=true, hasChains=false, gridSize=5 } })
        return true
    end)

    -- CHALLENGE: bombs + undo + chains
    makeBtn("CHALLENGE", "Bombs + Undo + Chains · 5x5", btnY+68, false, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.game", { effect="fade", time=300,
            params={ mode="challenge", hasBombs=true, hasUndo=true, hasChains=true, gridSize=5 } })
        return true
    end)

    -- FREEPLAY: classic rules, pick grid size
    makeBtn("FREEPLAY", "Classic rules · Choose grid size", btnY+136, false, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.gridSelect", { effect="slideLeft", time=300 })
        return true
    end)

    -- LEVELS
    makeBtn("LEVELS", "Intermediate · 50 levels", btnY+204, false, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.levelSelect", { effect="slideLeft", time=300 })
        return true
    end)

    -- STAGES
    makeBtn("STAGES", "Advanced · 999 stages", btnY+272, false, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.stageSelect", { effect="slideLeft", time=300 })
        return true
    end)

    -- MANIA
    makeBtn("MANIA", "Chaos · Survival", btnY+340, false, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.mania", { effect="fade", time=300 })
        return true
    end)
end

function scene:show(e)  end
function scene:hide(e)  end
function scene:destroy(e) end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
