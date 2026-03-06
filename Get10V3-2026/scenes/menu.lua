-----------------------------------------------------------------------------------------
--
-- scenes/menu.lua
-- Get10 v4.0 — Main Menu / Mode Select
--
-- Shows all available game modes:
--   PLAY    — Basic mode (5×5, reach 10, endless after)
--   LEVELS  — Intermediate (50 curated levels)
--   STAGES  — Advanced (999 shaped stages)
--   MANIA   — Mania survival mode
--
-- Also shows:
--   • Player rank and XP bar (P-04)
--   • Daily streak badge (P-01)
--   • CONTINUE button if a Basic mode save exists
--   • Best score
--   • Version watermark
--
-- CHANGELOG:
--   v3.0  2026-03-03  Initial
--   v3.1  2026-03-03  Dark theme, decorative tiles, title animation
--   v4.0  2026-03-03  Mode select, rank bar, streak badge, stats link
--
-----------------------------------------------------------------------------------------

local composer          = require("composer")
local settings          = require("config.settings")
local audioHelper       = require("app.helpers.audioHelper")
local saveState         = require("app.helpers.saveState")
local achievementHelper = require("app.helpers.achievementHelper")

local scene = composer.newScene()

function scene:create( event )
    local g  = self.view
    local cx = display.contentCenterX
    local cy = display.contentCenterY

    -- Dark background
    local bg = display.newRect(g, cx, cy, display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(unpack(settings.COLOR.BACKGROUND))

    -- Decorative tile strips (top + bottom rows, purely cosmetic)
    local function decorTile( num, x, y )
        local sz  = settings.VISUAL.TILE_SIZE - 10
        local col = settings.COLOR.TILE[((num-1) % #settings.COLOR.TILE)+1]
        local rt  = display.newRoundedRect(g, x, y, sz, sz, settings.VISUAL.TILE_CORNER)
        rt:setFillColor(col[1], col[2], col[3])
        rt.alpha = 0.15
        local lbl = display.newText{ parent=g, text=tostring(num), x=x, y=y,
            font=settings.FONT.BOLD, fontSize=16 }
        lbl:setFillColor(1, 1, 1, 0.20)
    end
    for j = 1, 5 do
        decorTile(j,         cx - 120 + (j-1)*60, 55)
        decorTile(10-j+1,    cx - 120 + (j-1)*60, display.contentHeight - 55)
    end

    -- ── Title ─────────────────────────────────────────────────────────────────
    local title = display.newText{ parent=g, text="GET  10",
        x=cx, y=cy-130, font=settings.FONT.BOLD, fontSize=54, align="center" }
    title:setFillColor(unpack(settings.COLOR.SCORE))
    title.alpha  = 0; title.yScale = 0.4
    transition.to(title, { alpha=1, yScale=1, time=500, transition=easing.outElastic })

    -- ── Player rank + XP bar (P-04) ────────────────────────────────────────────
    local stats     = saveState.loadStats()
    local rankIdx, rankName, toNext = achievementHelper.rankFromXP(stats.totalXP or 0)
    local rankColor = settings.COLOR.RANK[rankIdx]

    local rankLbl = display.newText{ parent=g, text=rankName,
        x=cx, y=cy-88, font=settings.FONT.BOLD, fontSize=14, align="center" }
    rankLbl:setFillColor(rankColor[1], rankColor[2], rankColor[3])

    -- XP progress bar (120px wide)
    local barW  = 120
    local barBg = display.newRoundedRect(g, cx, cy-70, barW, 8, 4)
    barBg:setFillColor(0.25, 0.25, 0.30)

    -- Compute fill fraction for current rank
    local thresholds = settings.XP.RANK_THRESHOLDS
    local rankStart  = thresholds[rankIdx] or 0
    local rankEnd    = thresholds[rankIdx+1] or (rankStart + 1000)
    local fraction   = math.min((stats.totalXP - rankStart) / (rankEnd - rankStart), 1)

    local barFill = display.newRoundedRect(g,
        cx - barW/2 + (barW * fraction)/2,
        cy-70,
        barW * fraction + 0.1, 8, 4)
    barFill:setFillColor(rankColor[1], rankColor[2], rankColor[3])
    barFill.anchorX = 0.5

    -- ── Daily streak badge (P-01) ──────────────────────────────────────────────
    local streak = saveState.loadStreak()
    if (streak.currentStreak or 0) > 0 then
        local streakBg = display.newRoundedRect(g, cx+70, cy-80, 62, 28, 6)
        streakBg:setFillColor(0.20, 0.20, 0.26)
        local streakLbl = display.newText{ parent=g,
            text="🔥 " .. streak.currentStreak .. " day" .. (streak.currentStreak > 1 and "s" or ""),
            x=cx+70, y=cy-80, font=settings.FONT.BOLD, fontSize=12, align="center" }
        streakLbl:setFillColor(unpack(settings.COLOR.COMBO_LABEL))
    end

    -- ── Best score ─────────────────────────────────────────────────────────────
    local hs = require("app.models.settingsModel").getHighScore()
    if hs > 0 then
        local bestLbl = display.newText{ parent=g,
            text="Best: " .. require("app.helpers.scoreHelper").scoreDisplay(hs),
            x=cx, y=cy-52, font=settings.FONT.NORMAL, fontSize=12, align="center" }
        bestLbl:setFillColor(unpack(settings.COLOR.HIGH_SCORE))
    end

    -- ── Mode buttons ───────────────────────────────────────────────────────────
    local function makeBtn( label, subtitle, yPos, primary, onTap )
        local col = primary and settings.COLOR.BUTTON_PRIMARY or settings.COLOR.BUTTON_SECONDARY
        local btn = display.newRoundedRect(g, cx, yPos, 220, 50, 12)
        btn:setFillColor(unpack(col))
        btn.alpha = 0
        transition.to(btn, { alpha=1, time=300, delay=500 })
        btn:addEventListener("tap", onTap)

        local lbl = display.newText{ parent=g, text=label, x=cx, y=yPos-4,
            font=settings.FONT.BOLD, fontSize=18 }
        lbl:setFillColor(1)
        lbl.alpha = 0
        transition.to(lbl, { alpha=1, time=300, delay=500 })
        lbl:addEventListener("tap", onTap)

        if subtitle then
            local sub = display.newText{ parent=g, text=subtitle, x=cx, y=yPos+11,
                font=settings.FONT.NORMAL, fontSize=10 }
            sub:setFillColor(1, 1, 1, 0.65)
            sub.alpha = 0
            transition.to(sub, { alpha=1, time=300, delay=500 })
            sub:addEventListener("tap", onTap)
        end
    end

    local btnY = cy - 10

    makeBtn("CLASSIC", "Reach tile 10 · No extras", btnY, true, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.game", { effect="fade", time=300,
            params={ mode="classic", hasBombs=false, hasUndo=false, hasChains=false, gridSize=5 } })
        return true
    end)

    makeBtn("NEW STYLE", "More modes & challenges", btnY+68, false, function()
        audioHelper.playTap()
        composer.gotoScene("scenes.modeSelect", { effect="slideLeft", time=300 })
        return true
    end)

    -- Settings icon (top-right)
    local settBtn = display.newText{ parent=g, text="⚙", x=display.contentWidth-22, y=22,
        font=settings.FONT.BOLD, fontSize=24 }
    settBtn:setFillColor(0.5)
    settBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.showOverlay("scenes.settings", { isModal=true, effect="fromTop", time=200 })
        return true
    end)

    -- Stats / achievements button
    local statsBtn = display.newText{ parent=g, text="STATS", x=22, y=22,
        font=settings.FONT.BOLD, fontSize=11 }
    statsBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.showOverlay("scenes.stats", { isModal=true, effect="fromTop", time=200 })
        return true
    end)

    -- Version watermark
    local ver = display.newText{ parent=g, text=settings.VERSION_STR,
        x=display.contentWidth-14, y=display.contentHeight-14,
        font=settings.FONT.NORMAL, fontSize=10 }
    ver:setFillColor(0.28); ver.anchorX = 1
end

function scene:show(e)  end
function scene:hide(e)  end
function scene:destroy(e) end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
