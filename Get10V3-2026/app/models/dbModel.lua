-----------------------------------------------------------------------------------------
--
-- app/models/dbModel.lua
-- Get10 - SQLite Persistence Layer
--
-- Wraps corona's sqlite3 so all other modules stay DB-agnostic.
-- Usage:
--   local db = require("app.models.dbModel")
--   db.init()
--   db.createTable("myTable", { id="INTEGER PRIMARY KEY", val="TEXT" })
--   local row = db.getRow("SELECT val FROM myTable WHERE id=1")
--
-----------------------------------------------------------------------------------------

local sqlite3 = require("sqlite3")

local M = {}

-- ── Private ─────────────────────────────────────────────────────────────────

local _db = nil  -- single shared connection

local function dbPath()
    return system.pathForFile("get10.db", system.DocumentsDirectory)
end

-- ── Public API ───────────────────────────────────────────────────────────────

--- Open (or create) the database file.
function M.init()
    if _db then return end
    _db = sqlite3.open( dbPath() )
    assert( _db, "get10: could not open database" )
end

--- Expose the raw handle (needed by models that run custom exec).
function M.handle()
    return _db
end

---
-- createTable(name, columns [, rows])
--   columns : { colName = "SQL_TYPE_DEF", … }
--   rows    : optional array of seed row tables
function M.createTable( name, columns, rows )
    -- Build CREATE TABLE IF NOT EXISTS …
    local defs = {}
    for col, typedef in pairs( columns ) do
        defs[#defs+1] = col .. " " .. typedef
    end
    local sql = "CREATE TABLE IF NOT EXISTS " .. name ..
                " (" .. table.concat(defs, ", ") .. ");"
    _db:exec( sql )

    -- Seed rows only when the table was just created (no rows yet)
    if rows then
        local checkSql = "SELECT COUNT(*) as cnt FROM " .. name .. ";"
        local count = 0
        for row in _db:nrows( checkSql ) do
            count = row.cnt
        end
        if count == 0 then
            for _, rowData in ipairs( rows ) do
                local cols, vals = {}, {}
                for k, v in pairs( rowData ) do
                    cols[#cols+1] = k
                    vals[#vals+1] = tostring(v)
                end
                local insertSql = "INSERT INTO " .. name ..
                    " (" .. table.concat(cols, ",") .. ") VALUES (" ..
                    table.concat(vals, ",") .. ");"
                _db:exec( insertSql )
            end
        end
    end
end

---
-- getRow(sql) → table or nil
-- Returns the first row as a key/value table, or nil if no rows.
function M.getRow( sql )
    if not _db then return nil end
    for row in _db:nrows( sql ) do
        return row
    end
    return nil
end

---
-- exec(sql) – fire-and-forget, returns the sqlite3 result code.
function M.exec( sql )
    if not _db then return end
    return _db:exec( sql )
end

return M
