-----------------------------------------------------------------------------------------
--
-- app/models/settingsModel.lua
-- Get10 - User Preferences Model
--
-- Persists: sound on/off, high score, first-run flag.
-- Usage:
--   local sm = require("app.models.settingsModel")
--   sm.init()                     -- called once from main.lua
--   sm.setSound(true/false)
--   local on = sm.getSound()      -- boolean
--   sm.setHighScore(1234)
--   local hs = sm.getHighScore()  -- number
--   sm.markStarted()
--   local started = sm.hasStarted() -- boolean
--
-----------------------------------------------------------------------------------------

local db = require("app.models.dbModel")

local M = {}

local TABLE = "settings"

-- ── Public API ───────────────────────────────────────────────────────────────

function M.init()
    db.createTable( TABLE,
        {
            id        = "INTEGER PRIMARY KEY",
            isSoundOn = "INT DEFAULT 1",
            isStarted = "INT DEFAULT 0",
            highScore = "INT DEFAULT 0",
        },
        { { id=1, isSoundOn=1, isStarted=0, highScore=0 } }
    )
end

-- Sound -----------------------------------------------------------------------

function M.setSound( flag )
    local v = flag and 1 or 0
    db.exec( "UPDATE "..TABLE.." SET isSoundOn="..v )
end

function M.getSound()
    local row = db.getRow( "SELECT isSoundOn FROM "..TABLE )
    return row and (row.isSoundOn == 1)
end

-- High score ------------------------------------------------------------------

--- Only updates if new score exceeds stored value.
function M.setHighScore( score )
    db.exec( "UPDATE "..TABLE.." SET highScore="..score.." WHERE highScore < "..score )
end

function M.getHighScore()
    local row = db.getRow( "SELECT highScore FROM "..TABLE )
    return row and row.highScore or 0
end

-- First-run flag --------------------------------------------------------------

function M.markStarted()
    db.exec( "UPDATE "..TABLE.." SET isStarted=1" )
end

function M.hasStarted()
    local row = db.getRow( "SELECT isStarted FROM "..TABLE )
    return row and (row.isStarted == 1)
end

return M
