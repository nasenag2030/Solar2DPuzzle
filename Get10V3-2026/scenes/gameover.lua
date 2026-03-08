-----------------------------------------------------------------------------------------
--
-- scenes/gameover.lua
-- Get10 v4.0 — Game Over / Win Overlay
--
-- Shown as a modal overlay. Params from scenes/game.lua:
--   {
--     isGameOver      bool     true=lost, false=win/endless
--     score           number
--     highScore       number
--     maxTile         number
--     bestCombo       number   largest group this session
--     totalXP         number   lifetime XP after this game
--     rankName        string   e.g. "Expert"
--     streak          number   current daily streak
--     newAchievements array    { id, name, desc, icon } newly unlocked
--     isEndless       bool     true if player was in endless mode
--   }
--
-- CHANGELOG:
--   v3.0  2026-03-03  Initial
--   v3.1  2026-03-03  bestCombo badge, confetti, dark theme
--   v4.0  2026-03-03  Rank display, streak, achievement unlocks banner
--
-----------------------------------------------------------------------------------------

local composer      = require("composer")
local settings      = require("config.settings")
local audioHelper   = require("app.helpers.audioHelper")
local scoreHelper   = require("app.helpers.scoreHelper")
local achievementHelper = require("app.helpers.achievementHelper")

local scene = composer.newScene()

-- ── Confetti ───────────────────────────────────────────────────────────────────
local function spawnConfetti( parent )
    local colors = settings.COLOR.TILE
    local cx, cy = display.contentCenterX, display.contentCenterY
    for _ = 1, 55 do
        local col = colors[math.random(1, #colors)]
        local sz  = math.random(5, 11)
        local dot = display.newRoundedRect(parent, cx, cy-80, sz, sz*1.6, 2)
        dot:setFillColor(col[1], col[2], col[3])
        dot.rotation = math.random(0, 360); dot.alpha = 0
        local tx = math.random(cx-130, cx+130)
        local ty = math.random(cy-220, cy-20)
        transition.to(dot, { x=tx, y=ty, alpha=1, time=math.random(300,700), transition=easing.outQuad,
            onComplete=function()
                transition.to(dot, { y=ty+math.random(200,400), alpha=0, time=math.random(600,1200),
                    transition=easing.inQuad, onComplete=function() display.remove(dot) end })
            end })
    end
end

-- ── Achievement banner (shows each new unlock in sequence) ────────────────────
local function showAchievementBanners( parent, newAch, startY )
    for k, ach in ipairs(newAch) do
        local delay = (k-1) * 900
        local bY    = startY + (k-1) * 34
        local bg = display.newRoundedRect(parent, display.contentCenterX, bY, 230, 28, 6)
        bg:setFillColor(0.12, 0.12, 0.16)
        bg.strokeWidth = 1; bg:setStrokeColor(unpack(settings.COLOR.SCORE))
        bg.alpha = 0
        local lbl = display.newText{ parent=parent,
            text=ach.icon .. "  " .. ach.name .. " unlocked!",
            x=display.contentCenterX, y=bY, font=settings.FONT.BOLD, fontSize=12 }
        lbl:setFillColor(unpack(settings.COLOR.SCORE)); lbl.alpha = 0

        transition.to(bg,  { delay=delay, alpha=1, time=300 })
        transition.to(lbl, { delay=delay, alpha=1, time=300 })
    end
end

-- ── Scene ──────────────────────────────────────────────────────────────────────
function scene:create( event )
    local g      = self.view
    local params = event.params or {}
    local cx     = display.contentCenterX
    local cy     = display.contentCenterY

    local isGameOver   = params.isGameOver
    local mode         = params.mode      or "basic"
    local score        = params.score      or 0
    local highScore    = params.highScore  or 0
    local bestCombo    = params.bestCombo  or 0
    local totalXP      = params.totalXP   or 0
    local rankName     = params.rankName  or "Novice"
    local streak       = params.streak    or 0
    local newAch       = params.newAchievements or {}
    local isEndless    = params.isEndless or false
    local isNewBest    = (score > 0 and score >= highScore)

    -- Backdrop
    local backdrop = display.newRect(g, cx, cy, display.actualContentWidth, display.actualContentHeight)
    backdrop:setFillColor(0, 0, 0, 0.72)

    -- Extra height if there are achievement banners
    local achExtraH = #newAch * 34
    local cardH = 330 + achExtraH
    local card  = display.newRoundedRect(g, cx, cy, 270, cardH, 18)
    card:setFillColor(0.14, 0.14, 0.18)
    card.strokeWidth = 2
    card:setStrokeColor(unpack(isGameOver and settings.COLOR.BUTTON_SECONDARY or settings.COLOR.SCORE))

    local top = cy - cardH/2

    -- ── Heading ────────────────────────────────────────────────────────────────
    local headText = isGameOver and "No More Moves"
        or (mode == "daily" and "Daily Done! 🌟")
        or (isEndless and ("Tile "..params.maxTile.."! 🌟") or "You Got 10! 🎉")
    local head = display.newText{ parent=g, text=headText, x=cx, y=top+38,
        font=settings.FONT.BOLD, fontSize=22, align="center", width=240 }
    head:setFillColor(isGameOver and 0.65 or unpack(settings.COLOR.SCORE))

    if not isGameOver then spawnConfetti(g) end

    -- ── Score ──────────────────────────────────────────────────────────────────
    local sY = top + 90
    local scoreCap = display.newText{ parent=g, text="SCORE", x=cx, y=sY,
        font=settings.FONT.NORMAL, fontSize=10 }
    scoreCap:setFillColor(0.5)

    local scoreVal = display.newText{ parent=g, text=scoreHelper.scoreDisplay(score),
        x=cx, y=sY+26, font=settings.FONT.BOLD, fontSize=40 }
    scoreVal:setFillColor(unpack(settings.COLOR.SCORE))
    transition.from(scoreVal, { xScale=1.5, yScale=1.5, time=300, transition=easing.outElastic })

    -- New best badge or best score
    local badgeY = sY + 62
    if isNewBest then
        local badge = display.newText{ parent=g, text="🏆  NEW BEST!",
            x=cx, y=badgeY, font=settings.FONT.BOLD, fontSize=14 }
        badge:setFillColor(unpack(settings.COLOR.SCORE))
        transition.from(badge, { alpha=0, xScale=0.5, yScale=0.5, time=400, delay=200 })
    else
        local bl = display.newText{ parent=g, text="Best: "..scoreHelper.scoreDisplay(highScore),
            x=cx, y=badgeY, font=settings.FONT.NORMAL, fontSize=12 }
        bl:setFillColor(0.45)
    end

    -- ── Stats row: combo · rank · streak ──────────────────────────────────────
    local statsY = badgeY + 34
    local function statPill( text, col, xPos )
        local pill = display.newRoundedRect(g, xPos, statsY, 74, 24, 6)
        pill:setFillColor(0.20, 0.20, 0.26)
        local lbl = display.newText{ parent=g, text=text,
            x=xPos, y=statsY, font=settings.FONT.BOLD, fontSize=11 }
        lbl:setFillColor(col[1], col[2], col[3])
    end

    -- Combo pill
    if bestCombo > 0 then
        statPill("🔗 "..bestCombo.." tiles", settings.COLOR.CHAIN_LABEL, cx-78)
    end
    -- Rank pill
    local rankIdx = 1
    for i, n in ipairs(settings.XP.RANK_NAMES) do
        if n == rankName then rankIdx = i; break end
    end
    statPill(rankName, settings.COLOR.RANK[rankIdx] or {0.7,0.7,0.7}, cx)
    -- Streak pill
    if streak > 0 then
        statPill("🔥 "..streak.."d", settings.COLOR.COMBO_LABEL, cx+78)
    end

    -- ── Achievement banners ────────────────────────────────────────────────────
    if #newAch > 0 then
        local achStartY = statsY + 26
        local achTitle = display.newText{ parent=g, text="🏅 NEW ACHIEVEMENTS",
            x=cx, y=achStartY, font=settings.FONT.BOLD, fontSize=11 }
        achTitle:setFillColor(unpack(settings.COLOR.SCORE))
        showAchievementBanners(g, newAch, achStartY + 22)
    end

    -- ── Buttons ────────────────────────────────────────────────────────────────
    local btnBase = cy + cardH/2 - 110

    local function makeBtn( label, yPos, col, onTap )
        local btn = display.newRoundedRect(g, cx, yPos, 210, 46, 10)
        btn:setFillColor(unpack(col)); btn:addEventListener("tap", onTap)
        local lbl = display.newText{ parent=g, text=label, x=cx, y=yPos,
            font=settings.FONT.BOLD, fontSize=16 }
        lbl:setFillColor(1); lbl:addEventListener("tap", onTap)
    end

    makeBtn("PLAY AGAIN", btnBase, settings.COLOR.BUTTON_PRIMARY, function()
        audioHelper.playTap()
        composer.hideOverlay()
        local levelNum = params.levelNum or nil
        local stageNum = params.stageNum or nil
        if mode == "daily" then
            composer.removeScene("scenes.game")
            composer.gotoScene("scenes.dailyChallenge", { effect="fade", time=300 })
        elseif mode == "intermediate" and levelNum then
            -- Retry the same level
            local LL   = require("app.helpers.levelLoader")
            local data = LL.loadIntermediate(levelNum)
            composer.removeScene("scenes.game")
            composer.gotoScene("scenes.game", { effect="fade", time=300,
                params={mode="intermediate", levelNum=levelNum, levelData=data} })
        elseif mode == "advanced" and stageNum then
            local LL   = require("app.helpers.levelLoader")
            local data = LL.loadAdvanced(stageNum)
            composer.removeScene("scenes.game")
            composer.gotoScene("scenes.game", { effect="fade", time=300,
                params={mode="advanced", stageNum=stageNum, levelData=data} })
        else
            -- Basic mode: restart in-place
            local gs = composer.getScene("scenes.game")
            if gs and gs.restart then gs.restart() end
        end
        return true
    end)

    makeBtn("MAIN MENU", btnBase+58, settings.COLOR.BUTTON_SECONDARY, function()
        audioHelper.playTap()
        composer.hideOverlay()
        composer.gotoScene("scenes.menu", { effect="fade", time=300 })
        return true
    end)

    -- Audio
    if isNewBest then audioHelper.playHighScore()
    elseif isGameOver then audioHelper.playLose()
    else audioHelper.playWin() end
end

function scene:show(e)  end
function scene:hide(e)  end
function scene:destroy(e) end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
