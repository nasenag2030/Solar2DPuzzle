-----------------------------------------------------------------------------------------
--
-- app/helpers/achievementHelper.lua
-- Get10 v4.0 — Achievement System (P-03)
--
-- Defines all 8 achievements and provides the check() function that
-- game.lua calls at the end of every game. Returns a list of newly
-- unlocked achievements so the UI can show a banner.
--
-- ACHIEVEMENT DESIGN RULE:
--   Each achievement fires exactly once per lifetime.
--   saveState.unlockAchievement() is idempotent — safe to call every game.
--
-- Usage:
--   local AH = require("app.helpers.achievementHelper")
--   local newUnlocks = AH.check(session, stats)
--   -- newUnlocks = array of { id, name, desc, icon }
--   local all = AH.all()    -- full list with .unlocked flag set
--
-- CHANGELOG:
--   v4.0  2026-03-03  Initial
--
-----------------------------------------------------------------------------------------

local saveState = require("app.helpers.saveState")

local M = {}

-- ── Achievement definitions ────────────────────────────────────────────────────
--
-- Each entry:
--   id      unique string key stored in the DB
--   name    short display name (shown in banner + stats screen)
--   desc    one-line description of how to earn it
--   icon    emoji used as the badge icon
--   check   function(session, stats) → bool
--             session: { score, maxTile, bestCombo, merges, chainDepth, usedBomb, usedUndo }
--             stats:   the UPDATED lifetime stats table (after this game)

local ACHIEVEMENTS = {
    {
        id   = "first_win",
        name = "First Victory",
        desc = "Reach tile 10 for the first time",
        icon = "🏆",
        check = function(session, _)
            return (session.maxTile or 0) >= 10
        end,
    },
    {
        id   = "combo_king",
        name = "Combo King",
        desc = "Reach a ×5 combo streak",
        icon = "🔥",
        check = function(session, _)
            return (session.maxCombo or 0) >= 5
        end,
    },
    {
        id   = "chain_master",
        name = "Chain Master",
        desc = "Trigger a chain reaction 3 levels deep",
        icon = "⛓️",
        check = function(session, _)
            return (session.maxChainDepth or 0) >= 3
        end,
    },
    {
        id   = "bomb_squad",
        name = "Bomb Squad",
        desc = "Use 10 bombs across all games",
        icon = "💣",
        check = function(_, stats)
            return (stats.totalBombsUsed or 0) >= 10
        end,
    },
    {
        id   = "minimalist",
        name = "Minimalist",
        desc = "Win without using any bomb",
        icon = "🎯",
        check = function(session, _)
            return (session.maxTile or 0) >= 10 and not session.usedBomb
        end,
    },
    {
        id   = "high_roller",
        name = "High Roller",
        desc = "Score over 5000 points in one game",
        icon = "💰",
        check = function(session, _)
            return (session.score or 0) >= 5000
        end,
    },
    {
        id   = "speed_demon",
        name = "Speed Demon",
        desc = "Win in under 2 minutes",
        icon = "⚡",
        check = function(session, _)
            return (session.maxTile or 0) >= 10
                and (session.elapsedSeconds or 9999) < 120
        end,
    },
    {
        id   = "grandmaster",
        name = "Grandmaster",
        desc = "Reach tile 12 in Endless mode",
        icon = "👑",
        check = function(session, _)
            return (session.maxTile or 0) >= 12
        end,
    },
}

-- ── Public API ─────────────────────────────────────────────────────────────────

---
-- Check all achievements against this session's results.
-- Unlocks any newly earned ones via saveState and returns them.
--
-- @param session  table — stats for the game just finished:
--                   score, maxTile, bestCombo, merges, maxCombo,
--                   maxChainDepth, usedBomb, elapsedSeconds
-- @param stats    table — updated lifetime stats (from saveState.updateStats)
-- @return array of newly unlocked achievement tables { id, name, desc, icon }
function M.check( session, stats )
    local newUnlocks = {}
    for _, ach in ipairs(ACHIEVEMENTS) do
        if ach.check(session, stats) then
            -- saveState returns true only on a NEW unlock
            local isNew = saveState.unlockAchievement(ach.id)
            if isNew then
                newUnlocks[#newUnlocks+1] = ach
            end
        end
    end
    return newUnlocks
end

---
-- Return the full achievement list with .unlocked flag set.
-- Used by the stats / achievements screen.
function M.all()
    local unlocked = saveState.loadAchievements()
    local result   = {}
    for _, ach in ipairs(ACHIEVEMENTS) do
        result[#result+1] = {
            id       = ach.id,
            name     = ach.name,
            desc     = ach.desc,
            icon     = ach.icon,
            unlocked = unlocked[ach.id] == true,
        }
    end
    return result
end

---
-- Return player's XP rank index (1 = Novice … 5 = Legend).
-- @param totalXP  number
-- @return  rank index (1–5), rank name string, XP to next rank
function M.rankFromXP( totalXP )
    local settings = require("config.settings")
    local thresholds = settings.XP.RANK_THRESHOLDS
    local names      = settings.XP.RANK_NAMES
    local rank = 1
    for i = #thresholds, 1, -1 do
        if totalXP >= thresholds[i] then
            rank = i
            break
        end
    end
    local toNext = (rank < #thresholds)
        and (thresholds[rank + 1] - totalXP) or 0
    return rank, names[rank], toNext
end

---
-- Return the XP threshold for the NEXT rank above rankIdx.
-- Used by stats.lua to draw the XP progress bar.
-- @param rankIdx  current rank index (from rankFromXP)
-- @return XP threshold for next rank, or nil if already at max rank
function M.nextRankXP( rankIdx )
    local settings = require("config.settings")
    local thresholds = settings.XP.RANK_THRESHOLDS
    if rankIdx < #thresholds then
        return thresholds[rankIdx + 1]
    end
    return nil
end

return M
