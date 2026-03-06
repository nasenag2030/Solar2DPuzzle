-----------------------------------------------------------------------------------------
--
-- scenes/stats.lua
-- Get10 v4.0 — Lifetime Stats and Achievements Overlay
--
-- Modal overlay from menu.lua:
--   composer.showOverlay("scenes.stats", { isModal=true, effect="fromTop", time=200 })
--
-- Shows: player rank badge, XP bar, lifetime stats, daily streak dots,
-- and all 8 achievement badges (grey=locked, gold=unlocked).
--
-- CHANGELOG:
--   v4.0  2026-03-03  Initial
--
-----------------------------------------------------------------------------------------

local composer          = require("composer")
local widget            = require("widget")
local settings          = require("config.settings")
local saveState         = require("app.helpers.saveState")
local achievementHelper = require("app.helpers.achievementHelper")
local scoreHelper       = require("app.helpers.scoreHelper")
local audioHelper       = require("app.helpers.audioHelper")

local scene = composer.newScene()

local function sectionHeader(parent, label, y, cx)
    local lbl = display.newText{
        parent=parent, text=label,
        x=cx, y=y,
        font=settings.FONT.BOLD, fontSize=14,
    }
    lbl:setFillColor(unpack(settings.COLOR.SCORE))
    local line = display.newRect(parent, cx, y+14, 200, 1)
    line:setFillColor(0.30, 0.30, 0.38)
    return y + 26
end

local function statRow(parent, label, value, y, cx)
    local lbl = display.newText{
        parent=parent, text=label,
        x=cx - 5, y=y,
        font=settings.FONT.NORMAL, fontSize=13, align="right",
    }
    lbl:setFillColor(0.55)
    lbl.anchorX = 1
    local val = display.newText{
        parent=parent, text=tostring(value),
        x=cx + 5, y=y,
        font=settings.FONT.BOLD, fontSize=13, align="left",
    }
    val:setFillColor(1)
    val.anchorX = 0
end

function scene:create(event)
    local sv = self.view
    local CW = display.actualContentWidth
    local CH = display.actualContentHeight

    local dim = display.newRect(sv, display.contentCenterX, display.contentCenterY, CW, CH)
    dim:setFillColor(0, 0, 0, 0.55)
    dim:addEventListener("tap", function() end)

    local cardH = CH * 0.88
    local card  = display.newRoundedRect(sv, display.contentCenterX, display.contentCenterY, CW-24, cardH, 14)
    card:setFillColor(unpack(settings.COLOR.GRID_BG))

    local closeBtn = display.newText{
        parent=sv, text="X",
        x=display.contentCenterX + (CW-24)/2 - 22,
        y=display.contentCenterY - cardH/2 + 22,
        font=settings.FONT.BOLD, fontSize=20,
    }
    closeBtn:setFillColor(0.55)
    closeBtn:addEventListener("tap", function()
        audioHelper.playTap()
        composer.hideOverlay({effect="fromTop", time=200})
        return true
    end)

    local sv2 = widget.newScrollView{
        x=display.contentCenterX, y=display.contentCenterY + 10,
        width=CW-30, height=cardH-50,
        scrollWidth=CW-30, scrollHeight=820,
        horizontalScrollingEnabled=false, hideBackground=true,
    }
    sv:insert(sv2)

    -- Local center X for scroll view content (scroll view uses its own coordinate space)
    local scx = (CW-30) / 2

    local stats  = saveState.loadStats()  or {}
    local streak = saveState.loadStreak() or {}
    local allAch = achievementHelper.all() or {}
    local rankIdx, rankName = achievementHelper.rankFromXP(stats.totalXP or 0)
    local rankColor = settings.COLOR.RANK[rankIdx] or {1,1,1}

    local y = 30

    -- Rank badge
    local rankBg = display.newRoundedRect(sv2, scx, y, 160, 38, 10)
    rankBg:setFillColor(unpack(rankColor))
    local rankLbl = display.newText{parent=sv2, text=rankName,
        x=scx, y=y, font=settings.FONT.BOLD, fontSize=20}
    rankLbl:setFillColor(0.1, 0.1, 0.1)
    y = y + 32

    -- XP bar
    local xpTotal = stats.totalXP or 0
    local nextXP  = achievementHelper.nextRankXP(rankIdx) or (xpTotal + 100)
    local prevXP  = settings.XP.RANK_THRESHOLDS[rankIdx] or 0
    local xpRange = math.max(nextXP - prevXP, 1)
    local xpProg  = math.min((xpTotal - prevXP) / xpRange, 1)
    local barW    = 200
    local xpBgRect = display.newRoundedRect(sv2, scx, y, barW, 10, 5)
    xpBgRect:setFillColor(0.22, 0.22, 0.28)
    if xpProg > 0 then
        local fw = barW * xpProg
        local xpFill = display.newRoundedRect(sv2,
            scx - barW/2 + fw/2, y, fw, 10, 5)
        xpFill:setFillColor(unpack(rankColor))
    end
    local xpLbl = display.newText{parent=sv2, text=xpTotal.." XP",
        x=scx, y=y+14, font=settings.FONT.NORMAL, fontSize=10}
    xpLbl:setFillColor(0.50)
    y = y + 34

    -- Lifetime stats
    y = sectionHeader(sv2, "LIFETIME STATS", y, scx)
    local rows = {
        {"Games played",  stats.gamesPlayed or 0},
        {"Total merges",  stats.totalMerges or 0},
        {"Highest tile",  stats.highestTile or 0},
        {"Best score",    scoreHelper.scoreDisplay(stats.bestScore or 0)},
        {"Best combo",    stats.bestCombo or 0},
        {"Bombs used",    stats.totalBombsUsed or 0},
    }
    for _, row in ipairs(rows) do
        statRow(sv2, row[1], row[2], y, scx)
        y = y + 22
    end
    y = y + 10

    -- Daily streak
    y = sectionHeader(sv2, "DAILY STREAK", y, scx)
    statRow(sv2, "Current", (streak.currentStreak or 0).." days", y, scx); y=y+22
    statRow(sv2, "Best",    (streak.longestStreak or 0).." days", y, scx); y=y+18

    local today     = os.date("*t")
    local dotSpace  = 28
    local dotStartX = scx - 3*dotSpace
    for d = 6, 0, -1 do
        local dx = dotStartX + (6-d)*dotSpace
        local played = streak.recentDays and streak.recentDays[d+1]
        local dot = display.newCircle(sv2, dx, y, 9)
        if played then
            dot:setFillColor(unpack(settings.COLOR.HIGH_SCORE))
        else
            dot:setFillColor(0.28, 0.28, 0.35)
        end
        local ts = os.time{year=today.year, month=today.month, day=today.day-d}
        local dl = display.newText{parent=sv2, text=os.date("%a",ts),
            x=dx, y=y+18, font=settings.FONT.NORMAL, fontSize=8}
        dl:setFillColor(0.45)
    end
    y = y + 42

    -- Achievements
    y = sectionHeader(sv2, "ACHIEVEMENTS", y, scx)
    local achCols = 4
    local achSize = 52
    local achPad  = 8
    local achRowH = achSize + 20
    local achStartX = scx - (achCols*0.5 - 0.5)*(achSize+achPad)
    for k, ach in ipairs(allAch) do
        local col = (k-1) % achCols
        local row = math.floor((k-1) / achCols)
        local ax  = achStartX + col*(achSize+achPad)
        local ay  = y + row*achRowH + achSize/2
        local unlocked = ach.unlocked
        local achBg = display.newRoundedRect(sv2, ax, ay, achSize, achSize, 8)
        if unlocked then
            achBg:setFillColor(unpack(settings.COLOR.SCORE))
        else
            achBg:setFillColor(0.22, 0.22, 0.28)
        end
        local icon = display.newText{parent=sv2, text=ach.icon,
            x=ax, y=ay-3, font=settings.FONT.NORMAL, fontSize=22}
        if not unlocked then icon:setFillColor(0.3) end
        local nm = display.newText{parent=sv2, text=ach.name,
            x=ax, y=ay+achSize/2+5,
            font=settings.FONT.NORMAL, fontSize=8, align="center", width=achSize+achPad}
        nm:setFillColor(unlocked and 1 or 0.35)
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
