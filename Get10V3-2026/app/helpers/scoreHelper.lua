-----------------------------------------------------------------------------------------
--
-- app/helpers/scoreHelper.lua
-- Get10 v4.0 — Score Calculator
--
-- All scoring math lives here. No display code, no state, no side effects.
-- Every function is a pure computation: same inputs → same output.
--
-- SCORING PHILOSOPHY:
--   • Merging higher tiles earns exponentially more (num² formula).
--   • Merging more tiles at once earns a group bonus (count-1 multiplier).
--   • Combo streak stacks on top (player-controlled, up to ×5).
--   • Chain reactions earn a smaller bonus (automatic, so less credit).
--   • Hot zones double the score for that specific merge.
--   • Bombs reward destroying high-value tiles (per-tile-value formula).
--
-- Usage:
--   local SH = require("app.helpers.scoreHelper")
--   local pts = SH.calculate(tileNum, count, comboMult, isHotZone)
--   local pts = SH.chainScore(mergedNum, groupSize, chainDepth)
--   local pts = SH.bombScore(blastCells)
--   local xp  = SH.toXP(score)
--
-- CHANGELOG:
--   v3.0  2026-03-03  Initial
--   v3.1  2026-03-03  comboMult, bombBonus (flat)
--   v3.3  2026-03-03  chainScore(), bombScore() per-tile-value
--   v4.0  2026-03-03  isHotZone flag; toXP(); scoreDisplay() helper
--
-----------------------------------------------------------------------------------------

local settings = require("config.settings")

local M = {}

-- ── Player-initiated merge ─────────────────────────────────────────────────────
--
-- Formula:  floor( num² × (count-1) × comboMult × hotMult )
--
--   num²          — exponential reward for high tiles
--                   tile 1 merge → 1 pt base; tile 9 → 81 pt base
--   (count-1)     — bonus for merging more tiles at once
--                   a 2-tile merge gets ×1; a 5-tile merge gets ×4
--   comboMult     — streak multiplier set by the player (1–5)
--   hotMult       — HOT_ZONE.MULT (default ×2) if merge touches a hot zone
--
-- @param tileNum    value of the tapped tile BEFORE the merge upgrades it
-- @param count      number of tiles in the merged group (≥ 2)
-- @param comboMult  current combo multiplier (default 1)
-- @param isHotZone  boolean — true if any cell in the group was a hot zone
-- @return integer points ≥ 0
function M.calculate( tileNum, count, comboMult, isHotZone )
    comboMult  = comboMult or 1
    local hot  = (isHotZone) and settings.HOT_ZONE.MULT or 1
    return math.floor( tileNum * tileNum * (count - 1) * comboMult * hot )
end

-- ── Chain reaction merge ───────────────────────────────────────────────────────
--
-- Chain reactions are AUTOMATIC (player did not directly tap them) so they
-- earn a base bonus smaller than a player merge, but the bonus GROWS with
-- each consecutive chain level to reward deep cascades.
--
-- Formula:  floor( num² × (count-1) × BONUS_MULTIPLIER^depth )
--   BONUS_MULTIPLIER defaults to 1.5
--   depth 1 → ×1.5
--   depth 2 → ×2.25
--   depth 3 → ×3.375
--
-- @param mergedNum   tile value BEFORE the chain upgrade
-- @param groupSize   number of tiles that auto-merged (≥ 2)
-- @param chainDepth  1 = first chain after player tap; 2 = chain of chain; etc.
-- @return integer points
function M.chainScore( mergedNum, groupSize, chainDepth )
    chainDepth = chainDepth or 1
    local bonus = settings.CHAIN.BONUS_MULTIPLIER ^ chainDepth
    return math.floor( mergedNum * mergedNum * (groupSize - 1) * bonus )
end

-- ── Bomb blast ─────────────────────────────────────────────────────────────────
--
-- Score = sum over all destroyed cells of ( cell.num × SCORE_PER_NUM ).
-- Higher-value tiles are worth more when destroyed, making the bomb feel
-- like a precision instrument rather than a random clear.
--
-- Example: blasting a "3" tile = 3 × 8 = 24 points (with SCORE_PER_NUM=8)
--
-- @param blastCells  array of cell tables from GL.getBombBlast()
--                    each with .num (may be nil if cell was already empty)
-- @return integer total points
function M.bombScore( blastCells )
    local total = 0
    for _, cell in ipairs(blastCells) do
        if cell.num then
            total = total + (cell.num * settings.BOMB.SCORE_PER_NUM)
        end
    end
    return total
end

-- ── XP conversion (P-04) ──────────────────────────────────────────────────────
--
-- XP = floor( score / XP_DIVISOR )
-- Accumulated across all games into lifetime totalXP.
-- Player rank is derived from totalXP via achievementHelper.rankFromXP().
--
-- @param score  game score
-- @return integer XP earned this game
function M.toXP( score )
    return math.floor( (score or 0) / settings.XP.DIVISOR )
end

-- ── Display helper ─────────────────────────────────────────────────────────────
--
-- Formats a number for display:
--   < 1000    → "954"
--   ≥ 1000    → "1.2K"
--   ≥ 1000000 → "1.4M"
-- Keeps score boxes from overflowing on small screens.
--
-- @param n  number
-- @return   string
function M.scoreDisplay( n )
    n = n or 0
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(math.floor(n))
    end
end

return M
