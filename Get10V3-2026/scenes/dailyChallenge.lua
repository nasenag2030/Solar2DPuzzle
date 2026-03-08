-----------------------------------------------------------------------------------------
--
-- scenes/dailyChallenge.lua
-- Get10 v4.1 — Daily Challenge Lobby
--
-- Reached from the main menu (DAILY button).
-- Shows today's challenge info; launches game in "daily" mode.
--
-- Daily mode rules:
--   • 6×6 seeded grid — same layout for every player every day
--   • No bombs, no undo, no chains
--   • 40 moves to score as many points as possible
--   • Score saved as today's best (saveDailyChallengeScore)
--   • Only one attempt resets per day (replays allowed)
--
-- CHANGELOG:
--   v4.1  2026-03-08  Initial
--
-----------------------------------------------------------------------------------------

local composer    = require("composer")
local settings    = require("config.settings")
local audioHelper = require("app.helpers.audioHelper")
local saveState   = require("app.helpers.saveState")
local GL          = require("app.helpers.gameLogic")
local scoreHelper = require("app.helpers.scoreHelper")

local scene = composer.newScene()

local DAILY_MOVES = 40   -- move budget for every daily challenge

-- Format today's date as a readable string, e.g. "March 8, 2026"
local function todayLabel()
    local t = os.date("*t")
    local months = {
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    }
    return (months[t.month] or "?") .. " " .. t.day .. ", " .. t.year
end

function scene:create( event )
    local g  = self.view
    local cx = display.contentCenterX
    local cy = display.contentCenterY

    -- Background
    local bg = display.newRect(g, cx, cy, display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(unpack(settings.COLOR.BACKGROUND))

    -- Decorative top strip
    for j = 1, 6 do
        local sz  = 40
        local col = settings.COLOR.TILE[((j-1) % #settings.COLOR.TILE)+1]
        local rt  = display.newRoundedRect(g, cx - 125 + (j-1)*50, 55, sz, sz, settings.VISUAL.TILE_CORNER)
        rt:setFillColor(col[1], col[2], col[3]); rt.alpha = 0.18
        local nl = display.newText{ parent=g, text=tostring(j),
            x=cx - 125 + (j-1)*50, y=55, font=settings.FONT.BOLD, fontSize=14 }
        nl:setFillColor(1, 1, 1, 0.22)
    end

    -- Title
    local title = display.newText{ parent=g, text="DAILY",
        x=cx, y=cy - 160, font=settings.FONT.BOLD, fontSize=42, align="center" }
    title:setFillColor(unpack(settings.COLOR.SCORE))
    transition.from(title, { alpha=0, yScale=0.5, time=400, transition=easing.outElastic })

    local sub = display.newText{ parent=g, text="CHALLENGE",
        x=cx, y=cy - 118, font=settings.FONT.BOLD, fontSize=20, align="center" }
    sub:setFillColor(1, 1, 1, 0.70)

    -- Date label
    local dateLbl = display.newText{ parent=g, text=todayLabel(),
        x=cx, y=cy - 86, font=settings.FONT.NORMAL, fontSize=13, align="center" }
    dateLbl:setFillColor(0.50)

    -- Card
    local card = display.newRoundedRect(g, cx, cy + 10, 270, 190, 14)
    card:setFillColor(0.13, 0.13, 0.17)
    card.strokeWidth = 1.5
    card:setStrokeColor(unpack(settings.COLOR.SCORE))

    -- Rules text inside card
    local ruleY = cy - 60
    local function ruleRow(icon, txt, y)
        local lbl = display.newText{ parent=g,
            text=icon .. "  " .. txt,
            x=cx, y=y, font=settings.FONT.NORMAL, fontSize=13, align="center" }
        lbl:setFillColor(0.78)
    end
    ruleRow("🎲", "Same grid for everyone", cy - 38)
    ruleRow("🔢", "40 moves to score big",  cy - 12)
    ruleRow("🚫", "No bombs · No undo",     cy + 14)
    ruleRow("🏆", "Best score saved daily", cy + 40)

    -- Best score section
    local daily = saveState.loadDailyChallenge()
    local todayScore = daily and daily.score or 0
    local completed  = daily and daily.completed or false

    if todayScore > 0 then
        local bestBg = display.newRoundedRect(g, cx, cy + 76, 190, 34, 8)
        bestBg:setFillColor(0.20, 0.20, 0.26)
        local bestLbl = display.newText{ parent=g,
            text="Today's best: " .. scoreHelper.scoreDisplay(todayScore),
            x=cx, y=cy + 76, font=settings.FONT.BOLD, fontSize=14, align="center" }
        bestLbl:setFillColor(unpack(settings.COLOR.SCORE))
    else
        local notYetLbl = display.newText{ parent=g,
            text="Not attempted yet today",
            x=cx, y=cy + 76, font=settings.FONT.NORMAL, fontSize=13, align="center" }
        notYetLbl:setFillColor(0.45)
    end

    -- Play / Replay button
    local btnLabel = completed and "REPLAY" or "PLAY"
    local btnY = cy + 140
    local btn = display.newRoundedRect(g, cx, btnY, 220, 52, 12)
    btn:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    btn.alpha = 0
    transition.to(btn, { alpha=1, time=300, delay=200 })

    local btnLbl = display.newText{ parent=g, text=btnLabel,
        x=cx, y=btnY, font=settings.FONT.BOLD, fontSize=22 }
    btnLbl:setFillColor(1)
    btnLbl.alpha = 0
    transition.to(btnLbl, { alpha=1, time=300, delay=200 })

    local function onPlay()
        audioHelper.playTap()
        -- Generate today's seeded grid
        local d    = saveState.loadDailyChallenge()
        local grid = GL.buildGridFromSeed(d.seed, 6)
        local ld   = {
            name   = "Daily " .. todayLabel(),
            goal   = "score",
            target = 0,
            moves  = DAILY_MOVES,
            par    = math.floor(DAILY_MOVES * 0.60),
            noBomb = true,
            hint   = "40 moves — score as high as you can!",
            grid   = grid,
        }
        composer.removeScene("scenes.game")
        composer.gotoScene("scenes.game", {
            effect = "fade", time = 300,
            params = {
                mode      = "daily",
                levelData = ld,
                gridSize  = 6,
                hasBombs  = false,
                hasUndo   = false,
                hasChains = false,
            }
        })
        return true
    end
    btn:addEventListener("tap", onPlay)
    btnLbl:addEventListener("tap", onPlay)

    -- Streak badge
    local streak = saveState.loadStreak()
    if (streak.currentStreak or 0) > 0 then
        local sBg = display.newRoundedRect(g, cx, btnY + 52, 150, 26, 6)
        sBg:setFillColor(0.18, 0.18, 0.22)
        local sLbl = display.newText{ parent=g,
            text="🔥 " .. streak.currentStreak .. " day streak",
            x=cx, y=btnY + 52, font=settings.FONT.BOLD, fontSize=12, align="center" }
        sLbl:setFillColor(unpack(settings.COLOR.COMBO_LABEL))
    end

    -- Back button
    local backBtn = display.newText{ parent=g, text="< BACK",
        x=cx, y=display.contentHeight - 30, font=settings.FONT.NORMAL, fontSize=13 }
    backBtn:setFillColor(0.45)
    backBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.gotoScene("scenes.menu", { effect="slideRight", time=300 })
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
