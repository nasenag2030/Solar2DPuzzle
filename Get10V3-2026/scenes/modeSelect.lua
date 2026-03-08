-----------------------------------------------------------------------------------------
--
-- scenes/modeSelect.lua
-- Get10 v4.0 — New Mode Sub-Menu
--
-- Reached from the main menu via NEW MODE button.
-- Shows modes beyond Classic:
--   FREEPLAY   — Classic rules, selectable grid size 3×3 to 10×10
--   BRICK      — Intermediate, 50 curated levels on a 6×6 grid
--   STAGES     — Advanced, 50 shaped stages
--   MANIA      — Survival chaos mode
--
-- Resume dot: small orange circle top-right of button when a saved game exists.
--
-- CHANGELOG:
--   v4.0  2026-03-06  Initial
--   v4.1  2026-03-07  Per-style save/HS; resume indicators; renamed NEW MODE
--   v4.2  2026-03-07  Removed DASH + CHALLENGE; renamed LEVELS→BRICK
--
-----------------------------------------------------------------------------------------

local composer      = require("composer")
local settings      = require("config.settings")
local audioHelper   = require("app.helpers.audioHelper")
local saveState     = require("app.helpers.saveState")

local scene = composer.newScene()

-- Resume indicator dots keyed by style key
local _dots = {}

-- Orange dot colour for resume indicators
local DOT_COLOR = { 1, 0.55, 0.1 }

local function hasFreeplayResume()
    for n = 3, 10 do
        if saveState.hasResume("freeplay_"..n) then return true end
    end
    return false
end

local function refreshDots()
    -- if _dots.dash      then _dots.dash.isVisible      = saveState.hasResume("dash")      end
    -- if _dots.challenge then _dots.challenge.isVisible  = saveState.hasResume("challenge") end
    if _dots.freeplay  then _dots.freeplay.isVisible   = hasFreeplayResume()              end
end

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

    -- Button factory; returns a resume dot object (hidden by default)
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

        -- Resume indicator dot: top-right corner of button
        local dot = display.newCircle(g, cx+100, yPos-17, 5)
        dot:setFillColor(unpack(DOT_COLOR))
        dot.isVisible = false
        return dot
    end

    local btnY = cy - 100

    -- FREEPLAY: classic rules, pick grid size
    _dots.freeplay = makeBtn("FREEPLAY", "Classic rules · Choose grid size", btnY, true, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.gridSelect", { effect="slideLeft", time=300 })
        return true
    end)

    -- BRICK: curated levels on a 6×6 grid
    makeBtn("BRICK", "50 levels · 6×6 grid", btnY+68, false, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.levelSelect", { effect="slideLeft", time=300 })
        return true
    end)

    -- STAGES
    makeBtn("STAGES", "Advanced · 50 stages", btnY+136, false, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.stageSelect", { effect="slideLeft", time=300 })
        return true
    end)

    -- MANIA (no resume — not resumable)
    makeBtn("MANIA", "Chaos · Survival", btnY+204, false, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.mania", { effect="fade", time=300 })
        return true
    end)

    -- HIDDEN (not ready for publish) ──────────────────────────────────────────
    -- DASH: bombs + undo, no chains
    -- _dots.dash = makeBtn("DASH", "Bombs + Undo · 5x5", btnY+272, false, function()
    --     audioHelper.playTap()
    --     composer.gotoScene("scenes.game", { effect="fade", time=300,
    --         params={ mode="dash", hasBombs=true, hasUndo=true, hasChains=false, gridSize=5 } })
    --     return true
    -- end)

    -- CHALLENGE: bombs + undo + chains
    -- _dots.challenge = makeBtn("CHALLENGE", "Bombs + Undo + Chains · 5x5", btnY+340, false, function()
    --     audioHelper.playTap()
    --     composer.gotoScene("scenes.game", { effect="fade", time=300,
    --         params={ mode="challenge", hasBombs=true, hasUndo=true, hasChains=true, gridSize=5 } })
    --     return true
    -- end)

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
