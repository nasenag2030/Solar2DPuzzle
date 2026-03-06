-----------------------------------------------------------------------------------------
--
-- scenes/stageSelect.lua
-- Get10 v4.0 — Advanced Mode: Stage Selection Screen
--
-- Shows 999 stages in a 5-column scrollable grid.
-- Stages unlock sequentially. Completed stages show a green check.
-- A progress bar + bracket milestone dots show overall completion.
-- Auto-scrolls to the player's current position.
--
-- Usage (from menu.lua):
--   composer.gotoScene("scenes.stageSelect", { effect="slideLeft", time=300 })
--
-- CHANGELOG:
--   v4.0  2026-03-03  Initial
--
-----------------------------------------------------------------------------------------

local composer    = require("composer")
local widget      = require("widget")
local settings    = require("config.settings")
local saveState   = require("app.helpers.saveState")
local audioHelper = require("app.helpers.audioHelper")
local levelLoader = require("app.helpers.levelLoader")

local scene = composer.newScene()

local COLS     = 5
local CELL_W   = 52
local CELL_H   = 52
local CELL_PAD = 8
local TOTAL    = settings.ADVANCED.TOTAL_STAGES
local SCROLL_H = display.actualContentHeight - 130

local THEME_COLORS = {
    Classic={0.60,0.60,0.70}, Ocean={0.20,0.65,0.85}, Fire={1.00,0.40,0.15},
    Forest={0.30,0.75,0.30},  Space={0.35,0.25,0.70}, Ice={0.55,0.85,1.00},
    Desert={0.90,0.70,0.30},  Neon={0.95,0.15,0.85},  Candy={1.00,0.55,0.70},
    Void={0.20,0.10,0.25},
}
local function themeColor(t) return THEME_COLORS[t] or {0.50,0.50,0.55} end

local function buildStageTile(parent, num, completed, locked, theme, onTap)
    local g  = display.newGroup()
    parent:insert(g)
    local col = locked and {0.18,0.18,0.22}
             or completed and {0.20,0.55,0.30}
             or themeColor(theme)
    local bg = display.newRoundedRect(g, 0, 0, CELL_W, CELL_H, 7)
    bg:setFillColor(unpack(col))
    if locked then bg.alpha = 0.5 end
    if completed then
        local ck = display.newText{parent=g,text="✓",x=0,y=-1,font=settings.FONT.BOLD,fontSize=20}
        ck:setFillColor(1,1,1)
    end
    local lbl = display.newText{parent=g,text=tostring(num),x=0,y=completed and 16 or 0,
        font=settings.FONT.BOLD,fontSize=10}
    lbl:setFillColor(locked and 0.35 or 1)
    if not locked then
        bg:addEventListener("tap",function() audioHelper.playTap(); onTap(num); return true end)
    end
    return g
end

function scene:create(event)
    local sv = self.view
    local bg = display.newRect(sv,display.contentCenterX,display.contentCenterY,
        display.actualContentWidth,display.actualContentHeight)
    bg:setFillColor(unpack(settings.COLOR.BACKGROUND))

    local hdr = display.newText{parent=sv,text="STAGES",
        x=display.contentCenterX,y=30,font=settings.FONT.BOLD,fontSize=24}
    hdr:setFillColor(unpack(settings.COLOR.SCORE))

    local back = display.newText{parent=sv,text="< Back",
        x=38,y=30,font=settings.FONT.BOLD,fontSize=16}
    back:setFillColor(unpack(settings.COLOR.BUTTON_PRIMARY))
    back:addEventListener("tap",function()
        audioHelper.playTap()
        composer.gotoScene("scenes.menu",{effect="slideRight",time=300})
        return true
    end)

    local currentStage = saveState.loadAdvancedStage() or 1

    -- Progress bar
    local barW = display.actualContentWidth - 40
    local barBg = display.newRoundedRect(sv,display.contentCenterX,55,barW,10,5)
    barBg:setFillColor(0.22,0.22,0.28)
    local prog = math.min((currentStage-1)/TOTAL,1)
    if prog > 0 then
        local fill = display.newRoundedRect(sv,
            display.contentCenterX - barW/2 + (barW*prog)/2, 55, barW*prog, 10, 5)
        fill:setFillColor(unpack(settings.COLOR.SCORE))
    end
    local progLbl = display.newText{parent=sv,text=currentStage.." / "..TOTAL,
        x=display.contentCenterX,y=70,font=settings.FONT.NORMAL,fontSize=11}
    progLbl:setFillColor(0.55)
    for _,ms in ipairs({101,301,601}) do
        local xp = display.contentCenterX - barW/2 + barW*((ms-1)/TOTAL)
        local dot = display.newCircle(sv,xp,55,4)
        dot:setFillColor(ms<=currentStage and unpack(settings.COLOR.SCORE) or 0.40)
    end

    local function onStageTap(num)
        local data = levelLoader.loadAdvanced(num)
        composer.gotoScene("scenes.game",{effect="fade",time=300,
            params={mode="advanced",stageNum=num,levelData=data}})
    end

    local rows  = math.ceil(TOTAL/COLS)
    local totalH = rows*(CELL_H+CELL_PAD)+CELL_PAD
    local sv2 = widget.newScrollView{
        x=display.contentCenterX, y=display.contentCenterY+45,
        width=display.actualContentWidth-20, height=SCROLL_H,
        scrollWidth=display.actualContentWidth-20, scrollHeight=totalH,
        horizontalScrollingEnabled=false, hideBackground=true,
    }
    sv:insert(sv2)

    local startRow = math.max(0, math.floor((currentStage-1)/COLS)-1)
    local scrollY  = startRow*(CELL_H+CELL_PAD)
    if scrollY > 0 then sv2:scrollToPosition{y=-scrollY,time=400} end

    for n = 1, TOTAL do
        local c = ((n-1)%COLS)
        local r = math.floor((n-1)/COLS)
        local cx = CELL_W*0.5+CELL_PAD + c*(CELL_W+CELL_PAD)
        local cy = CELL_H*0.5+CELL_PAD + r*(CELL_H+CELL_PAD)
        local _,theme = levelLoader.advancedChapter(n)
        local tile = buildStageTile(sv2, n, n<currentStage, n>currentStage, theme, onStageTap)
        tile.x = cx; tile.y = cy
    end
end

function scene:show(e)  end
function scene:hide(e)  end
function scene:destroy(e) end
scene:addEventListener("create",scene)
scene:addEventListener("show",scene)
scene:addEventListener("hide",scene)
scene:addEventListener("destroy",scene)
return scene
