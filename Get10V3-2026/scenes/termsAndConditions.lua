-----------------------------------------------------------------------------------------
--
-- scenes/termsAndConditions.lua
-- Get10 v4.0 — Terms & Conditions (one-time on first install)
--
-- Shown once after install. Player must tap Confirm to proceed.
-- Acceptance is persisted in SQLite; never shown again after that.
--
-- Links open in the device browser via system.openURL():
--   Privacy Policy  → PRIVACY_URL
--   Terms of Service → TERMS_URL
--
-- CHANGELOG:
--   v4.0  2026-03-06  Initial
--
-----------------------------------------------------------------------------------------

local composer    = require("composer")
local settings    = require("config.settings")
local saveState   = require("app.helpers.saveState")

-- ── Placeholder URLs — replace before App Store submission ─────────────────────
local PRIVACY_URL = "https://example.com/get10/privacy"
local TERMS_URL   = "https://example.com/get10/terms"

local scene = composer.newScene()

function scene:create( event )
    local g  = self.view
    local cx = display.contentCenterX
    local cy = display.contentCenterY
    local CW = display.actualContentWidth
    local CH = display.actualContentHeight

    -- Full-screen dark background
    local bg = display.newRect(g, cx, cy, CW, CH)
    bg:setFillColor(unpack(settings.COLOR.BACKGROUND))

    -- Card
    local cardW = math.min(CW - 32, 300)
    local cardH = 380
    local card  = display.newRoundedRect(g, cx, cy, cardW, cardH, 18)
    card:setFillColor(0.16, 0.16, 0.20)
    card.strokeWidth = 1
    card:setStrokeColor(0.30, 0.30, 0.38)

    local top = cy - cardH / 2

    -- ── "10" tile icon placeholder ────────────────────────────────────────────
    local iconSize = 64
    local iconBg = display.newRoundedRect(g, cx, top + 48, iconSize, iconSize, 14)
    iconBg:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    local iconLbl = display.newText{ parent=g, text="10",
        x=cx, y=top + 48, font=settings.FONT.BOLD, fontSize=28 }
    iconLbl:setFillColor(1)

    -- ── Heading ───────────────────────────────────────────────────────────────
    local heading = display.newText{
        parent=g, text="How we handle your data",
        x=cx, y=top + 106,
        font=settings.FONT.BOLD, fontSize=18,
        width=cardW - 40, align="center",
    }
    heading:setFillColor(unpack(settings.COLOR.SCORE))

    -- ── Body text ─────────────────────────────────────────────────────────────
    local body = display.newText{
        parent=g,
        text="This game may collect analytics data about how you play, which we use to improve your gaming experience. By continuing you confirm that you agree with our Terms of Service and that you have read our Privacy Policy.",
        x=cx, y=top + 196,
        font=settings.FONT.NORMAL, fontSize=12,
        width=cardW - 48, align="center",
    }
    body:setFillColor(0.72)

    -- ── Privacy Policy link ───────────────────────────────────────────────────
    local privacyLbl = display.newText{
        parent=g, text="Privacy Policy",
        x=cx, y=top + 278,
        font=settings.FONT.BOLD, fontSize=14, align="center",
    }
    privacyLbl:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    -- Underline simulation: thin rect below text
    local privLine = display.newRect(g, cx, top + 288, privacyLbl.width + 2, 1)
    privLine:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    privacyLbl:addEventListener("tap", function()
        system.openURL(PRIVACY_URL)
        return true
    end)
    privLine:addEventListener("tap", function()
        system.openURL(PRIVACY_URL)
        return true
    end)

    -- ── Terms of Service link ─────────────────────────────────────────────────
    local termsLbl = display.newText{
        parent=g, text="Terms of Service",
        x=cx, y=top + 312,
        font=settings.FONT.BOLD, fontSize=14, align="center",
    }
    termsLbl:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    local termsLine = display.newRect(g, cx, top + 322, termsLbl.width + 2, 1)
    termsLine:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    termsLbl:addEventListener("tap", function()
        system.openURL(TERMS_URL)
        return true
    end)
    termsLine:addEventListener("tap", function()
        system.openURL(TERMS_URL)
        return true
    end)

    -- ── Confirm button ────────────────────────────────────────────────────────
    local btnW  = cardW - 40
    local btnY  = cy + cardH / 2 - 38
    local btn   = display.newRoundedRect(g, cx, btnY, btnW, 48, 24)
    btn:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))

    local btnLbl = display.newText{
        parent=g, text="Confirm",
        x=cx, y=btnY, font=settings.FONT.BOLD, fontSize=18,
    }
    btnLbl:setFillColor(1)

    local function onConfirm()
        saveState.acceptTerms()
        composer.gotoScene("scenes.menu", { effect="fade", time=400 })
        return true
    end
    btn:addEventListener("tap",    onConfirm)
    btnLbl:addEventListener("tap", onConfirm)
end

function scene:show(e)  end
function scene:hide(e)  end
function scene:destroy(e) end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
