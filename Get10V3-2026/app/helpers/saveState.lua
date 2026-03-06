-----------------------------------------------------------------------------------------
--
-- app/helpers/saveState.lua
-- Get10 v4.0 — Game State & Progression Persistence
--
-- Stores everything that must survive app restarts:
--   • Current game board (resume on relaunch)
--   • All-time stats: bestCombo, totalMerges, highestTile, gamesPlayed, totalXP
--   • Daily streak: lastPlayDate, currentStreak, longestStreak
--   • Achievements: which ones have been unlocked
--   • Daily challenge: seed used today, score achieved
--   • Player rank (derived from totalXP but cached here)
--   • Per-mode progress: advancedStage, intermediateStars[level]
--
-- All data is stored as JSON in SQLite via dbModel so it survives updates.
--
-- Usage:
--   local SS = require("app.helpers.saveState")
--   SS.init()
--   SS.save(score, grid, maxTile)
--   local data = SS.load()          -- { score, allTiles, maxTile } or nil
--   SS.clear()
--   local stats = SS.loadStats()
--   SS.updateStats(session)         -- session = { bestCombo, merges, highestTile, score }
--   local streak = SS.loadStreak()
--   SS.updateStreak()               -- call once per game completed
--   SS.unlockAchievement(id)
--   local ach = SS.loadAchievements()
--   SS.saveAdvancedStage(N)
--   local stage = SS.loadAdvancedStage()
--   SS.saveIntermediateStars(level, stars)
--   local stars = SS.loadIntermediateStars()
--
-- CHANGELOG:
--   v3.0  2026-03-03  Initial (board save/load, basic stats)
--   v3.1  2026-03-03  Added bomb flag, bestCombo, totalMerges
--   v4.0  2026-03-03  Full progression: streak, achievements, XP, rank,
--                     Advanced stage, Intermediate stars, daily challenge
--
-----------------------------------------------------------------------------------------

local json = require("json")
local db   = require("app.models.dbModel")

local M = {}

-- ── Table names ────────────────────────────────────────────────────────────────
local T_SAVE   = "saveState"
local T_STATS  = "statsState"
local T_STREAK = "streakState"
local T_ACH    = "achievements"
local T_ADV    = "advancedState"
local T_INTER  = "intermediateState"
local T_DAILY  = "dailyState"
local T_TERMS  = "termsState"

-- ── Helper ─────────────────────────────────────────────────────────────────────

-- Safely decode JSON; return fallback on error
local function decode( str, fallback )
    if not str or str == "" then return fallback end
    return json.decode(str) or fallback
end

-- Safely encode and escape single quotes for SQLite
local function encode( t )
    return json.encode(t):gsub("'", "''")
end

-- Get today's date as "YYYY-MM-DD" string
local function todayStr()
    return os.date("%Y-%m-%d")
end

-- ── Init (called once from main.lua) ──────────────────────────────────────────
--
-- Creates all tables if they don't exist and seeds one row per table.
-- Safe to call multiple times (IF NOT EXISTS guards).

function M.init()
    -- Board save
    db.createTable(T_SAVE,
        { id="INTEGER PRIMARY KEY", state="TEXT DEFAULT NULL" },
        { { id=1 } }
    )

    -- All-time stats
    db.createTable(T_STATS,
        { id="INTEGER PRIMARY KEY", stats="TEXT DEFAULT NULL" },
        { { id=1 } }
    )

    -- Daily streak
    db.createTable(T_STREAK,
        { id="INTEGER PRIMARY KEY", streak="TEXT DEFAULT NULL" },
        { { id=1 } }
    )

    -- Achievements (one row; JSON array of unlocked IDs)
    db.createTable(T_ACH,
        { id="INTEGER PRIMARY KEY", data="TEXT DEFAULT NULL" },
        { { id=1 } }
    )

    -- Advanced mode progress
    db.createTable(T_ADV,
        { id="INTEGER PRIMARY KEY", stage="INTEGER DEFAULT 1" },
        { { id=1, stage=1 } }
    )

    -- Intermediate mode star ratings (JSON map: { ["1"]=3, ["2"]=2, ... })
    db.createTable(T_INTER,
        { id="INTEGER PRIMARY KEY", stars="TEXT DEFAULT NULL" },
        { { id=1 } }
    )

    -- Daily challenge (seed + today's score)
    db.createTable(T_DAILY,
        { id="INTEGER PRIMARY KEY", data="TEXT DEFAULT NULL" },
        { { id=1 } }
    )

    -- Terms & Conditions acceptance (one-time on first install)
    db.createTable(T_TERMS,
        { id="INTEGER PRIMARY KEY", accepted="INTEGER DEFAULT 0" },
        { { id=1, accepted=0 } }
    )
end

-- ── Board save / load / clear (per-mode) ──────────────────────────────────────
--
-- The state column holds a JSON map keyed by mode string:
--   { classic={score,allTiles,maxTile}, dash={...}, challenge={...}, ... }
-- Each mode has its own independent save slot so resuming one mode never
-- interferes with another.

---
-- Save current board for the given mode.
-- @param mode     string — "classic" | "dash" | "challenge" | "freeplay" | ...
-- @param score    current score
-- @param grid     logical grid (cells have .num and .isBomb)
-- @param maxTile  highest tile currently on the board
function M.save( mode, score, grid, maxTile )
    local row      = db.getRow("SELECT state FROM "..T_SAVE.." WHERE id=1")
    local allSaves = decode(row and row.state or nil, {})

    local flat = {}
    for i = 1, #grid do
        flat[i] = {}
        for j = 1, #grid[i] do
            local c = grid[i][j]
            flat[i][j] = { num=c.num or 0, isBomb=c.isBomb or false }
        end
    end

    allSaves[mode] = { score=score, allTiles=flat, maxTile=maxTile or 5 }
    db.exec("UPDATE "..T_SAVE.." SET state='"..encode(allSaves).."' WHERE id=1")
end

---
-- Load saved board for the given mode. Returns { score, allTiles, maxTile } or nil.
-- @param mode  string — must match the mode used when saving
function M.load( mode )
    local row = db.getRow("SELECT state FROM "..T_SAVE.." WHERE id=1")
    if not (row and row.state and row.state ~= "") then return nil end
    local allSaves = decode(row.state, {})
    local data     = allSaves[mode]
    if not data then return nil end
    -- Normalise: 0 → nil for num
    for i = 1, #(data.allTiles or {}) do
        for j = 1, #(data.allTiles[i] or {}) do
            local v = data.allTiles[i][j]
            if type(v) == "table" then
                if v.num == 0 then v.num = nil end
            else
                data.allTiles[i][j] = { num=(v and v > 0) and v or nil, isBomb=false }
            end
        end
    end
    return data
end

---
-- Erase the saved board for the given mode only (other modes are unaffected).
-- @param mode  string
function M.clear( mode )
    local row      = db.getRow("SELECT state FROM "..T_SAVE.." WHERE id=1")
    local allSaves = decode(row and row.state or nil, {})
    allSaves[mode] = nil
    db.exec("UPDATE "..T_SAVE.." SET state='"..encode(allSaves).."' WHERE id=1")
end

-- ── All-time stats ─────────────────────────────────────────────────────────────
--
-- Stats table stores:
--   bestCombo     — largest single group ever merged
--   totalMerges   — lifetime merge count
--   highestTile   — highest tile value ever reached
--   gamesPlayed   — total completed games
--   totalXP       — cumulative XP (score ÷ XP_DIVISOR per game)
--   totalScore    — all-time score sum

local STATS_DEFAULT = {
    bestCombo      = 0,
    totalMerges    = 0,
    highestTile    = 0,
    gamesPlayed    = 0,
    totalXP        = 0,
    bestScore      = 0,   -- renamed from totalScore for clarity (stats screen shows best)
    totalBombsUsed = 0,   -- lifetime bomb uses (P-03 Bomb Squad achievement)
}

---
-- Load all-time stats. Always returns a table (never nil).
function M.loadStats()
    local row = db.getRow("SELECT stats FROM "..T_STATS.." WHERE id=1")
    if row and row.stats and row.stats ~= "" then
        local s = decode(row.stats, {})
        -- Fill in any missing keys from a fresh install / older version
        for k, v in pairs(STATS_DEFAULT) do
            if s[k] == nil then s[k] = v end
        end
        return s
    end
    -- Copy of default so caller can mutate safely
    local copy = {}
    for k, v in pairs(STATS_DEFAULT) do copy[k] = v end
    return copy
end

---
-- Merge one game session's results into lifetime stats and persist.
-- @param session  table with optional fields:
--                   bestCombo, merges, highestTile, score, xp
function M.updateStats( session )
    session = session or {}
    local s = M.loadStats()

    if (session.bestCombo  or 0) > s.bestCombo  then s.bestCombo  = session.bestCombo  end
    if (session.highestTile or 0) > s.highestTile then s.highestTile = session.highestTile end

    s.totalMerges    = s.totalMerges    + (session.merges or 0)
    s.gamesPlayed    = s.gamesPlayed    + 1
    s.totalBombsUsed = s.totalBombsUsed + (session.totalBombsUsed or 0)
    s.totalXP        = s.totalXP        + (session.xp     or 0)
    -- bestScore = highest single-game score (not a sum)
    if (session.score or 0) > (s.bestScore or 0) then
        s.bestScore = session.score
    end

    db.exec("UPDATE "..T_STATS.." SET stats='"..encode(s).."' WHERE id=1")
    return s
end

-- ── Daily streak (P-01) ────────────────────────────────────────────────────────
--
-- Streak data:
--   lastPlayDate    — "YYYY-MM-DD" of the last game completed
--   currentStreak   — consecutive days played
--   longestStreak   — all-time record

local STREAK_DEFAULT = { lastPlayDate="", currentStreak=0, longestStreak=0 }

--- Load daily streak data. Always returns a table.
-- Also computes recentDays[1..7] (true/false) for the last 7 days,
-- where index 1 = 6 days ago and index 7 = today.
-- stats.lua uses this to draw the calendar dot row.
function M.loadStreak()
    local row = db.getRow("SELECT streak FROM "..T_STREAK.." WHERE id=1")
    local s
    if row and row.streak and row.streak ~= "" then
        s = decode(row.streak, {})
        for k, v in pairs(STREAK_DEFAULT) do
            if s[k] == nil then s[k] = v end
        end
    else
        s = {}
        for k, v in pairs(STREAK_DEFAULT) do s[k] = v end
    end

    -- Build recentDays[1..7]: true if that day was played.
    -- We derive this from playDates (array of "YYYY-MM-DD" strings in streak).
    -- If playDates is absent (old save), fall back to approximation from streak length.
    local recentDays = {}
    local playSet = {}
    if type(s.playDates) == "table" then
        for _, d in ipairs(s.playDates) do playSet[d] = true end
    elseif (s.currentStreak or 0) > 0 then
        -- Approximate: assume the last N days were played
        for d = 0, math.min((s.currentStreak or 0)-1, 6) do
            local ds = os.date("%Y-%m-%d", os.time() - d*86400)
            playSet[ds] = true
        end
    end
    for d = 6, 0, -1 do
        local ds = os.date("%Y-%m-%d", os.time() - d*86400)
        recentDays[7-d] = (playSet[ds] == true)
    end
    s.recentDays = recentDays
    return s
end

---
-- Call once after every completed game to update the streak.
-- Returns the updated streak table.
function M.updateStreak()
    local s    = M.loadStreak()
    local today = todayStr()

    if s.lastPlayDate == today then
        -- Already played today — no change
        return s
    end

    -- Check if yesterday was played (continuing the streak)
    local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
    if s.lastPlayDate == yesterday then
        s.currentStreak = s.currentStreak + 1
    else
        -- Gap in streak — reset
        s.currentStreak = 1
    end

    s.lastPlayDate  = today
    if s.currentStreak > s.longestStreak then
        s.longestStreak = s.currentStreak
    end

    -- Track individual play dates for the calendar (keep last 30)
    if type(s.playDates) ~= "table" then s.playDates = {} end
    s.playDates[#s.playDates+1] = today
    if #s.playDates > 30 then table.remove(s.playDates, 1) end

    -- Don't persist derived recentDays field
    local toStore = {}
    for k, v in pairs(s) do
        if k ~= "recentDays" then toStore[k] = v end
    end
    db.exec("UPDATE "..T_STREAK.." SET streak='"..encode(toStore).."' WHERE id=1")
    return s
end

-- ── Achievements (P-03) ────────────────────────────────────────────────────────
--
-- Stored as a JSON object: { ["first_win"]=true, ["combo_king"]=true, ... }
-- IDs match the ACHIEVEMENT_IDS table in achievementHelper.

--- Load achievement unlock map. Returns {} if none unlocked.
function M.loadAchievements()
    local row = db.getRow("SELECT data FROM "..T_ACH.." WHERE id=1")
    if row and row.data and row.data ~= "" then
        return decode(row.data, {})
    end
    return {}
end

---
-- Unlock an achievement by ID string. No-op if already unlocked.
-- @param id  string e.g. "first_win", "combo_king" (see achievementHelper)
-- @return    true if this was a NEW unlock, false if already had it
function M.unlockAchievement( id )
    local ach = M.loadAchievements()
    if ach[id] then return false end   -- already unlocked
    ach[id] = true
    db.exec("UPDATE "..T_ACH.." SET data='"..encode(ach).."' WHERE id=1")
    return true
end

-- ── Advanced mode progress (P mode) ───────────────────────────────────────────

--- Save the furthest Advanced stage reached.
function M.saveAdvancedStage( stage )
    db.exec("UPDATE "..T_ADV.." SET stage="..math.floor(stage).." WHERE id=1")
end

--- Load the furthest Advanced stage reached (default 1).
function M.loadAdvancedStage()
    local row = db.getRow("SELECT stage FROM "..T_ADV.." WHERE id=1")
    return (row and row.stage) or 1
end

-- ── Intermediate mode star ratings ─────────────────────────────────────────────

---
-- Save star rating for a level. Only saves if new rating is better.
-- @param level  integer level number (1-50)
-- @param stars  integer 1-3
function M.saveIntermediateStars( level, stars )
    local row = db.getRow("SELECT stars FROM "..T_INTER.." WHERE id=1")
    local map = decode(row and row.stars or nil, {})
    local key = tostring(level)
    if (map[key] or 0) < stars then
        map[key] = stars
        db.exec("UPDATE "..T_INTER.." SET stars='"..encode(map).."' WHERE id=1")
    end
end

---
-- Load all intermediate star ratings.
-- @return  table { ["1"]=3, ["2"]=1, ... }  — unplayed levels are absent
function M.loadIntermediateStars()
    local row = db.getRow("SELECT stars FROM "..T_INTER.." WHERE id=1")
    return decode(row and row.stars or nil, {})
end

-- ── Daily challenge (M-04) ────────────────────────────────────────────────────
--
-- Stored: { date="YYYY-MM-DD", seed=N, score=N }
-- One challenge per calendar day, same seed for all players.

local settings = require("config.settings")

---
-- Get today's daily challenge data. Returns { date, seed, score }.
-- If it's a new day, resets score to 0 so the player can attempt it.
function M.loadDailyChallenge()
    local row = db.getRow("SELECT data FROM "..T_DAILY.." WHERE id=1")
    local d   = decode(row and row.data or nil, {})

    local today = todayStr()
    if d.date ~= today then
        -- New day: compute today's seed deterministically
        local t    = os.time()
        local ymd  = os.date("*t", t)
        local seed = settings.DAILY.SEED_OFFSET
                     + ymd.year * 10000
                     + ymd.month * 100
                     + ymd.day
        d = { date=today, seed=seed, score=0, completed=false }
        db.exec("UPDATE "..T_DAILY.." SET data='"..encode(d).."' WHERE id=1")
    end
    return d
end

---
-- Record the score for today's daily challenge.
-- Only updates if score is higher than previous attempt.
-- @param score  number
function M.saveDailyChallengeScore( score )
    local d = M.loadDailyChallenge()
    if score > (d.score or 0) then
        d.score     = score
        d.completed = true
        db.exec("UPDATE "..T_DAILY.." SET data='"..encode(d).."' WHERE id=1")
    end
end

-- ── Terms & Conditions (one-time on first install) ────────────────────────────

--- Returns true if the player has already accepted T&C.
function M.hasAcceptedTerms()
    local row = db.getRow("SELECT accepted FROM "..T_TERMS.." WHERE id=1")
    return row and (row.accepted == 1 or row.accepted == true)
end

--- Record that the player accepted T&C.
function M.acceptTerms()
    db.exec("UPDATE "..T_TERMS.." SET accepted=1 WHERE id=1")
end

return M
