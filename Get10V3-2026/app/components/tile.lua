-----------------------------------------------------------------------------------------
--
-- app/components/tile.lua
-- Get10 v4.0 — Tile Display Component
--
-- Responsible ONLY for the visual representation of a single tile.
-- No game logic, no score, no state beyond the display object itself.
--
-- Each tile is a DisplayGroup containing:
--   • Rounded rect background (tileColor for this number)
--   • Subtle top-edge shine highlight
--   • Number label (dark or light text depending on tile brightness)
--   • Bomb ring + emoji (if isBomb)
--   • Endless glow ring (gold, if isEndless and num > WIN_TILE)
--
-- Usage:
--   local Tile = require("app.components.tile")
--   local obj = Tile.new(num, isBomb, isEndlessGlow)
--   Tile.upgrade(tileData, parent, tapCB)
--   Tile.animateMerge(obj, destX, destY)
--   Tile.animateFall(obj, newY)
--   Tile.animateFallH(obj, newX)        -- horizontal fall (Mania left/right gravity)
--   Tile.spawnParticles(parent, x, y, color)
--   Tile.setBombPulse(obj, enabled)
--   Tile.spawnBombBlast(parent, x, y)
--
-- CHANGELOG:
--   v3.0  2026-03-03  Initial refactor
--   v3.1  2026-03-03  Bomb visuals, particles, dark bg, shine
--   v4.0  2026-03-03  Endless glow ring, animateFallH (horizontal gravity)
--
-----------------------------------------------------------------------------------------

local settings = require("config.settings")

local M = {}

local COLORS     = settings.COLOR.TILE
local SIZE       = settings.VISUAL.TILE_SIZE
local CORNER     = settings.VISUAL.TILE_CORNER
local MERGE_TIME = settings.VISUAL.MERGE_ANIM_MS
local FALL_TIME  = settings.VISUAL.FALL_ANIM_MS

-- ── Colour helpers ─────────────────────────────────────────────────────────────

-- Returns the tile fill colour for a given number (wraps cyclically).
local function tileColor( num )
    local idx = ((num - 1) % #COLORS) + 1
    return COLORS[idx]
end

-- Dark text on yellow/amber tiles; white text on all others.
local function textColor( num )
    local idx = ((num - 1) % #COLORS) + 1
    -- Tiles at positions 3 (yellow) and 8 (amber) in the palette are light
    if idx == 3 or idx == 8 then
        return settings.COLOR.TILE_TEXT_DARK
    end
    return settings.COLOR.TILE_TEXT_LIGHT
end

-- ── Public API ─────────────────────────────────────────────────────────────────

---
-- Create a brick (immovable blocker) DisplayGroup.
-- Bricks have no number, cannot be merged or destroyed.
-- Visual: dark charcoal rounded rect with mortar-line grooves.
--
-- @param tileSize  pixel size of the cell (defaults to settings TILE_SIZE)
-- @return DisplayGroup  (isBrickObj=true flag set for identification)
function M.newBrick( tileSize )
    local sz    = tileSize or SIZE
    local group = display.newGroup()

    -- Dark background
    local bg = display.newRoundedRect(group, 0, 0, sz-4, sz-4, CORNER)
    bg:setFillColor(0.22, 0.20, 0.18)

    -- Mortar grooves (lighter horizontal lines to suggest a brick wall)
    local grooveAlpha = 0.18
    local grooveW     = sz - 12
    for _, dy in ipairs({ -(sz * 0.18), (sz * 0.18) }) do
        local groove = display.newRect(group, 0, dy, grooveW, 2)
        groove:setFillColor(1, 1, 1, grooveAlpha)
    end
    -- Vertical break on upper half (offset from lower half for classic brick pattern)
    local vUpper = display.newRect(group, -(sz * 0.16), -(sz * 0.09), 2, sz * 0.28)
    vUpper:setFillColor(1, 1, 1, grooveAlpha)
    local vLower = display.newRect(group, (sz * 0.16), (sz * 0.09), 2, sz * 0.28)
    vLower:setFillColor(1, 1, 1, grooveAlpha)

    -- Small lock icon to reinforce "indestructible"
    local icon = display.newText{
        parent=group, text="🔒",
        x=0, y=1, fontSize=sz * 0.38,
    }
    icon.alpha = 0.55

    group.isBrickObj = true
    return group
end

---
-- Create a new tile DisplayGroup.
--
-- @param num           integer ≥ 1    tile value
-- @param isBomb        boolean         add bomb ring + emoji
-- @param isEndlessGlow boolean         add gold endless-mode glow ring (tiles > WIN)
-- @return DisplayGroup
function M.new( num, isBomb, isEndlessGlow )
    local group = display.newGroup()

    -- Background rounded rect
    local col = tileColor(num)
    local bg  = display.newRoundedRect(group, 0, 0, SIZE-4, SIZE-4, CORNER)
    bg:setFillColor(col[1], col[2], col[3])

    -- Top-edge shine (subtle white strip for depth)
    local shine = display.newRoundedRect(group, 0, -(SIZE*0.28), SIZE-8, SIZE*0.18, 4)
    shine:setFillColor(1, 1, 1, 0.12)

    -- Number label
    local tc    = textColor(num)
    local label = display.newText{
        parent=group, text=tostring(num),
        x=0, y=1, font=settings.FONT.BOLD,
        fontSize=(num >= 10) and 20 or 23, align="center",
    }
    label:setFillColor(tc[1], tc[2], tc[3])

    -- Endless glow ring (gold border for tiles beyond WIN_TILE)
    if isEndlessGlow then
        local glow = display.newRoundedRect(group, 0, 0, SIZE-2, SIZE-2, CORNER+2)
        glow:setFillColor(0, 0, 0, 0)
        glow.strokeWidth = 3
        local gc = settings.COLOR.ENDLESS_GLOW
        glow:setStrokeColor(gc[1], gc[2], gc[3])
        -- Gentle pulse
        local function glowPulse()
            transition.to(glow, {
                alpha=0.4, time=900, transition=easing.inOutSine,
                onComplete=function()
                    if glow and glow.parent then
                        transition.to(glow, { alpha=1, time=900, transition=easing.inOutSine, onComplete=glowPulse })
                    end
                end
            })
        end
        glowPulse()
        group._endlessGlow = glow
    end

    -- Bomb visuals
    if isBomb then
        local ring = display.newCircle(group, 0, 0, (SIZE*0.5)-2)
        ring:setFillColor(0, 0, 0, 0)
        ring.strokeWidth = 3
        ring:setStrokeColor(unpack(settings.COLOR.BOMB_GLOW))

        local bombLbl = display.newText{
            parent=group, text="💣",
            x=SIZE*0.28, y=-(SIZE*0.26), fontSize=14,
        }
        group._bombRing  = ring
        group._bombLabel = bombLbl

        M.setBombPulse(group, true)
    end

    group.tileNum = num
    group.isBomb  = isBomb  or false

    return group
end

---
-- Start or stop the bomb ring pulse animation.
-- @param tileObj  DisplayGroup from M.new()
-- @param enabled  boolean
function M.setBombPulse( tileObj, enabled )
    if not tileObj._bombRing then return end
    transition.cancel(tileObj._bombRing)
    if enabled then
        local ring = tileObj._bombRing
        local function pulse()
            transition.to(ring, {
                time=settings.BOMB.PULSE_TIME, alpha=0.2, transition=easing.inOutSine,
                onComplete=function()
                    if ring and ring.parent then
                        transition.to(ring, { time=settings.BOMB.PULSE_TIME, alpha=1.0,
                            transition=easing.inOutSine, onComplete=pulse })
                    end
                end
            })
        end
        pulse()
    else
        tileObj._bombRing.alpha = 1
    end
end

---
-- Slide tileObj to (destX, destY), shrinking and fading it, then remove it.
-- Used for all non-destination tiles in a merge group.
function M.animateMerge( tileObj, destX, destY )
    transition.cancel(tileObj)
    transition.to(tileObj, {
        x=destX, y=destY, xScale=0.6, yScale=0.6, alpha=0,
        time=MERGE_TIME, transition=easing.inQuad,
        onComplete=function()
            if tileObj and tileObj.removeSelf then display.remove(tileObj) end
        end,
    })
end

---
-- Animate tileObj falling to a new Y position (standard downward gravity).
-- Uses outBounce so tiles feel physical and satisfying.
-- Restores _cellScale so a cancelled spring-pop doesn't leave tiles oversized.
function M.animateFall( tileObj, newY )
    local scl = tileObj._cellScale or 1
    transition.cancel(tileObj)
    transition.to(tileObj, { y=newY, xScale=scl, yScale=scl, time=FALL_TIME, transition=easing.outBounce })
end

---
-- Animate tileObj sliding to a new X position (horizontal gravity in Mania mode).
-- Restores _cellScale so a cancelled spring-pop doesn't leave tiles oversized.
function M.animateFallH( tileObj, newX )
    local scl = tileObj._cellScale or 1
    transition.cancel(tileObj)
    transition.to(tileObj, { x=newX, xScale=scl, yScale=scl, time=FALL_TIME, transition=easing.outBounce })
end

---
-- Replace a cell's display object with an upgraded one (num+1).
-- Removes the old obj, creates a new one at the same screen position.
-- Plays a spring pop animation on the new tile.
--
-- @param tileData  logical cell { num, i, j, obj, isBomb }
-- @param parent    DisplayGroup to insert new obj into
-- @param tapCB     "tap" event listener to register on new obj
function M.upgrade( tileData, parent, tapCB, scale )
    local oldObj = tileData.obj
    local newNum = tileData.num + 1
    local posX   = oldObj.x
    local posY   = oldObj.y

    M.setBombPulse(oldObj, false)
    transition.cancel(oldObj)
    display.remove(oldObj)
    tileData.obj    = nil
    tileData.isBomb = false

    -- Check if new tile qualifies for endless glow
    local settings2  = require("config.settings")
    local isEndless  = (newNum > settings2.GAME.WIN_TILE)

    local newObj = M.new(newNum, false, isEndless)
    newObj.x = posX;  newObj.y = posY
    newObj.i = tileData.i;  newObj.j = tileData.j
    local scl = scale or 1
    if math.abs(scl - 1) > 0.02 then
        newObj.xScale = scl;  newObj.yScale = scl
    end
    newObj._cellScale = scl   -- stored so animateFall can restore correct scale
    newObj:addEventListener("tap", tapCB)
    parent:insert(newObj)

    tileData.num = newNum
    tileData.obj = newObj

    -- Spring pop: transition.from records current xScale/yScale as target,
    -- so the pop correctly overshoots then settles at the scaled size.
    transition.from(newObj, { xScale=1.45, yScale=1.45, time=160, transition=easing.outElastic })
end

---
-- Spawn a small particle burst at (x, y) in the given colour.
-- Particles scatter outward and fade. All cleaned up automatically.
--
-- @param parent  DisplayGroup to add particles to
-- @param x, y   centre of burst
-- @param color  { r, g, b } tile colour
function M.spawnParticles( parent, x, y, color )
    local count  = settings.VISUAL.PARTICLE_COUNT
    local radius = settings.VISUAL.PARTICLE_RADIUS
    local ms     = settings.VISUAL.PARTICLE_MS

    for _ = 1, count do
        local angle = math.random(0, 360)
        local dist  = math.random(math.floor(radius * 0.5), radius)
        local tx    = x + dist * math.cos(math.rad(angle))
        local ty    = y + dist * math.sin(math.rad(angle))
        local sz    = math.random(4, 8)

        local dot = display.newCircle(parent, x, y, sz)
        dot:setFillColor(color[1], color[2], color[3], 0.9)
        transition.to(dot, {
            x=tx, y=ty, alpha=0, xScale=0.3, yScale=0.3,
            time=math.random(math.floor(ms*0.6), ms),
            transition=easing.outQuad,
            onComplete=function() display.remove(dot) end,
        })
    end
end

---
-- Create expanding shockwave rings at (x, y) for bomb detonation.
-- 3 rings staggered by 80ms each.
function M.spawnBombBlast( parent, x, y )
    for i = 1, 3 do
        local ring = display.newCircle(parent, x, y, 5)
        ring:setFillColor(0, 0, 0, 0)
        ring.strokeWidth = 3
        ring:setStrokeColor(unpack(settings.COLOR.BOMB_GLOW))
        transition.to(ring, {
            delay=(i-1)*80, xScale=8, yScale=8, alpha=0, time=420,
            transition=easing.outQuad,
            onComplete=function() display.remove(ring) end,
        })
    end
end

return M
