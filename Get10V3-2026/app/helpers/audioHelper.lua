-----------------------------------------------------------------------------------------
--
-- app/helpers/audioHelper.lua
-- Get10 - Audio Manager
-- v3.1.0
--
-- Pre-loads ALL sounds at startup. Call init() once from main.lua.
-- Scenes should NEVER call audio.loadSound() directly.
--
-- Usage:
--   local AH = require("app.helpers.audioHelper")
--   AH.init()
--   AH.playTap()
--   AH.playMerge(num)    -- plays pitched sound for tile number
--   AH.playBomb()
--   AH.playClear()
--   AH.playWin()
--   AH.playLose()
--   AH.playHighScore()
--   AH.setEnabled(bool)
--   AH.isEnabled()
--
-- CHANGELOG:
--   v3.0.0  2026-03-03  Initial refactor (pre-load pattern)
--   v3.1.0  2026-03-03  Added playBomb()
--
-----------------------------------------------------------------------------------------

local settings      = require("config.settings")
local settingsModel = require("app.models.settingsModel")
local coronaAudio   = require("audio")

local M = {}

-- ── Private ───────────────────────────────────────────────────────────────────

local _sounds  = {}
local _enabled = true

local PATH = "app/assets/audio/"

local function load( key, file )
    local h = coronaAudio.loadSound(PATH .. file)
    if h then _sounds[key] = h end
end

-- ── Public API ────────────────────────────────────────────────────────────────

function M.init()
    _enabled = settingsModel.getSound()

    -- Numbered merge sounds (1-13 tones, ascending)
    for i = 1, 13 do
        load("num_"..i, i..".mp3")
    end

    load("tap",       "button_tap.mp3")
    load("clear",     "blocks_clear.mp3")
    load("win",       "endgame_win.mp3")
    load("lose",      "endgame_lose.mp3")
    load("highscore", "endgame_highscore.mp3")
    -- Bomb: re-use blocks_clear or a dedicated file if you have one
    load("bomb",      "blocks_clear.mp3")
end

function M.setEnabled( flag )
    _enabled = flag
    settingsModel.setSound(flag)
end

function M.isEnabled()
    return _enabled
end

local function play( key )
    if not _enabled then return end
    local h = _sounds[key]
    if h then coronaAudio.play(h) end
end

function M.playTap()        play("tap")        end
function M.playClear()      play("clear")      end
function M.playWin()        play("win")        end
function M.playLose()       play("lose")       end
function M.playHighScore()  play("highscore")  end
function M.playBomb()       play("bomb")       end

-- Haptics (I-01) - vibration scaled to tile value
function M.vibrateOnMerge( tileNum )
    if not _enabled then return end
    if not system.vibrate then return end
    local p = 1
    if (tileNum or 1) >= 7 then p = 3 elseif (tileNum or 1) >= 4 then p = 2 end
    for _ = 1, p do system.vibrate() end
end
function M.vibrateTap()
    if not _enabled then return end
    if system.vibrate then system.vibrate() end
end


--- Play the merge sound matching the resulting tile number.
function M.playMerge( num )
    play("num_" .. math.min(num, 13))
end

return M
