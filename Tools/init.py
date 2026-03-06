#!/usr/bin/env python3
"""
init.py — Solar2DPuzzle new game scaffolder
============================================

Creates a fully structured Solar2D game project inside the Solar2DPuzzle
platform folder, registers it in platform.json, and prints next steps.

Run from the Solar2DPuzzle/ root folder.

USAGE
-----
  python Tools/init.py <slug> "<Display Name>" "<description>"

  slug         — short lowercase identifier (used in platform.json and commands)
  Display Name — human-readable game name (used in CLAUDE.md, build settings)
  description  — one sentence describing the core mechanic

EXAMPLES
--------
  python Tools/init.py blockdrop "Block Drop" "Drop blocks to fill rows"
  python Tools/init.py lineconnect "Line Connect" "Draw lines to connect matching dots"

WHAT IT CREATES
---------------
  <DisplayName>-YYYY/           (e.g. LineConnect-2026/)
  ├── .gitignore
  ├── CLAUDE.md                 game-specific Claude instructions
  ├── HandOff2ClaudeCode.md     project context template
  ├── main.lua                  Solar2D boot file
  ├── config.lua                display/content settings
  ├── build.settings            iOS + Android build config
  ├── config/
  │   ├── settings.lua          ALL constants (fill this first)
  │   ├── activeGame.lua        set by build.py switch
  │   └── gameConfig.lua        ad IDs and feature flags (set by build.py prepare)
  ├── scenes/
  │   ├── menu.lua              main menu scene (template)
  │   └── game.lua              game scene stub
  ├── app/
  │   ├── helpers/
  │   │   ├── gameLogic.lua     pure game rules stub
  │   │   ├── scoreHelper.lua   scoring math stub
  │   │   ├── audioHelper.lua   audio pre-load/play stub
  │   │   └── saveState.lua     SQLite persistence stub
  │   ├── models/
  │   │   ├── dbModel.lua       raw SQLite wrapper (production-ready)
  │   │   └── settingsModel.lua user prefs stub
  │   ├── components/
  │   │   └── .gitkeep
  │   └── assets/
  │       └── audio/
  │           └── README.txt
  ├── data/
  │   └── levels/
  │       ├── intermediate/
  │       │   └── .gitkeep
  │       └── advanced/
  │           └── .gitkeep
  └── vibe/
      ├── bug/
      │   └── .gitkeep
      ├── improvement/
      │   └── .gitkeep
      └── others/
          └── .gitkeep
"""

import argparse
import json
import os
import sys
from datetime import datetime

# ── Helpers ───────────────────────────────────────────────────────────────────

def pascal_case(s):
    """Convert 'line connect' or 'Line Connect' to 'LineConnect'."""
    return "".join(w.capitalize() for w in s.replace("-", " ").replace("_", " ").split())

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    print(f"  created  {os.path.relpath(path)}")

def touch(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "a").close()
    print(f"  created  {os.path.relpath(path)}")

# ── Templates ─────────────────────────────────────────────────────────────────

def tpl_gitignore():
    return """.DS_Store
*.db
*.db-shm
*.db-wal
*.apk
*.ipa
build/
"""

def tpl_claude_md(display_name, slug, description, folder_name):
    return f"""# CLAUDE.md — {display_name}

**{display_name}** — {description}
Built with **Solar2D** (Corona SDK). Language: **Lua**.

Current version: **v1.0** — in development.

> Platform-wide rules (three-layer architecture, coding style, critical Solar2D rules)
> are in the parent `Solar2DPuzzle/CLAUDE.md`. This file covers game-specific rules only.

---

## Running the Game

Open the `{folder_name}/` folder in the **Solar2D Simulator** (https://solar2d.com).
No build step — the simulator runs Lua directly. Press `Cmd+R` to restart.

To switch active game: `python Tools/build.py switch {slug}`

---

## Core Mechanic

[TODO: describe the core mechanic in 2-3 sentences. What does the player do?
What is the win condition? What makes it fun?]

---

## Key Files

| File | Purpose |
|------|---------|
| `main.lua` | Boot: init DB, audio, go to menu |
| `config/settings.lua` | **ALL constants** — change values here only |
| `scenes/menu.lua` | Main menu |
| `scenes/game.lua` | Main game scene |
| `app/helpers/gameLogic.lua` | Pure game rules (no display) |
| `app/helpers/saveState.lua` | All SQLite persistence |
| `HandOff2ClaudeCode.md` | Full project context and roadmap |

---

## Game-Specific Rules

[TODO: add rules critical to this game's correctness. Examples:]
- [Rule about your grid / board structure]
- [Rule about your merge / interaction pipeline]
- [Rule about your data structure invariants]

---

## Scene Navigation

```
menu → game
game → gameover overlay → PLAY AGAIN or MAIN MENU
```

[TODO: expand as scenes are added]

---

## What Needs Work

- [ ] Define core mechanic fully in `config/settings.lua`
- [ ] Build game scene (`scenes/game.lua`)
- [ ] Add audio files (`app/assets/audio/`)
- [ ] Create Intermediate levels (`data/levels/intermediate/`)
- [ ] App icon, splash screen, `build.settings` bundle ID
- [ ] Fill ad IDs in `Tools/platform.json`
"""

def tpl_handoff(display_name, description):
    return f"""# HandOff2ClaudeCode.md — {display_name}

## 1. Project Overview

**{display_name}** — {description}

Platform: Solar2D (Corona SDK)
Language: Lua
Target: iOS + Android (portrait)

## 2. Current State

Version: v1.0 — scaffolded, not yet implemented.

## 3. Architecture

Follows the Solar2DPuzzle three-layer architecture:
- Layer 3: Scenes (display, input, animations)
- Layer 2: Helpers (pure logic, no display)
- Layer 1: Models (SQLite persistence)

See `solar2d_game_architecture_v2.md` in the platform root for full patterns.

## 4. Core Mechanic

[TODO: describe in detail how the game works]

## 5. Roadmap

- [ ] Core game loop
- [ ] Basic mode
- [ ] Intermediate levels
- [ ] Advanced stages
- [ ] Mania / endless mode
- [ ] Audio
- [ ] Ads

## 6. Known Issues

None yet.

## 7. Notes for Claude

[Add anything Claude should know when picking up this project mid-stream]
"""

def tpl_main_lua(display_name, slug):
    year = datetime.now().year
    return f"""-----------------------------------------------------------------------------------------
-- main.lua
-- Boot entry point for {display_name}.
-- Initialises DB, audio, and navigates to the main menu.
--
-- WHAT THIS FILE DOES:
--   Solar2D calls this first. Keep it minimal: init services, go to menu.
-- CHANGELOG:
--   v1.0  {year}-01-01  Initial scaffold
-----------------------------------------------------------------------------------------

local composer   = require("composer")
local dbModel    = require("app.models.dbModel")
local saveState  = require("app.helpers.saveState")
local audioHelper = require("app.helpers.audioHelper")

-- Initialise persistence
dbModel.init()
saveState.init()

-- Initialise audio (pre-loads all sounds)
audioHelper.init()

-- Go to main menu
composer.gotoScene("scenes.menu", {{ effect="fade", time=400 }})
"""

def tpl_config_lua():
    return """-----------------------------------------------------------------------------------------
-- config.lua
-- Solar2D display / content settings.
-- Do not put game constants here — use config/settings.lua.
-----------------------------------------------------------------------------------------

application = {
    content = {
        width  = 320,
        height = 568,
        scale  = "letterBox",
        fps    = 60,
        imageSuffix = {
            ["@2x"] = 1.5,
            ["@4x"] = 3.0,
        },
    },
}
"""

def tpl_build_settings(display_name):
    return f"""-- build.settings
-- iOS + Android build configuration.
-- Update bundle IDs and version before submitting.
settings = {{
    orientation = {{
        default   = "portrait",
        supported = {{ "portrait" }},
    }},
    iphone = {{
        plist = {{
            UIStatusBarHidden       = true,
            UIRequiresFullScreen    = true,
            CFBundleDisplayName     = "{display_name}",
            CFBundleVersion         = "1",
            CFBundleShortVersionString = "1.0",
            NSMotionUsageDescription   = "Used for haptic feedback.",
        }},
    }},
    android = {{
        versionCode   = 1,
        versionName   = "1.0",
        minSdkVersion = "21",
    }},
    plugins = {{
        -- ["plugin.admob"] = {{ publisherId="com.coronalabs" }},
    }},
}}
"""

def tpl_settings_lua(display_name):
    year = datetime.now().year
    return f"""-----------------------------------------------------------------------------------------
-- config/settings.lua
-- ALL game constants live here. Never hardcode numbers in scenes or helpers.
--
-- CHANGELOG:
--   v1.0  {year}-01-01  Initial scaffold
-----------------------------------------------------------------------------------------

local S = {{}}

-- Version
S.VERSION     = {{ major=1, minor=0, patch=0 }}
S.VERSION_STR = "v1.0"
S.GAME_NAME   = "{display_name}"

-- Grid (update for your game)
S.GAME = {{}}
S.GAME.GRID_ROWS = 5
S.GAME.GRID_COLS = 5

-- Visual
S.VISUAL = {{}}
S.VISUAL.TILE_SIZE      = 60
S.VISUAL.TILE_CORNER    = 8
S.VISUAL.MERGE_ANIM_MS  = 110
S.VISUAL.FALL_ANIM_MS   = 70
S.VISUAL.SPAWN_ANIM_MS  = 120

-- Fonts
S.FONT = {{}}
S.FONT.NORMAL = "OpenSans"
S.FONT.BOLD   = "OpenSans-Bold"

-- Colours (RGB 0-1 float)
S.COLOR = {{}}
S.COLOR.BACKGROUND       = {{ 0.13, 0.13, 0.17 }}
S.COLOR.BUTTON_PRIMARY   = {{ 1.00, 0.47, 0.27 }}
S.COLOR.BUTTON_SECONDARY = {{ 0.38, 0.38, 0.48 }}

return S
"""

def tpl_active_game_lua(slug, display_name):
    return f"""-- config/activeGame.lua
-- Written by build.py — do not edit manually.
-- Identifies which game is currently active in the simulator.

return {{
    slug        = "{slug}",
    displayName = "{display_name}",
}}
"""

def tpl_game_config_lua():
    return """-- config/gameConfig.lua
-- Written by build.py prepare — do not edit manually.
-- Contains ad IDs and feature flags for the active game.

return {
    ads = {
        enabled              = false,
        admobAppIdIos        = "PLACEHOLDER",
        admobAppIdAndroid    = "PLACEHOLDER",
        bannerId             = "PLACEHOLDER",
        interstitialId       = "PLACEHOLDER",
        rewardedId           = "PLACEHOLDER",
    },
    features = {
        adsEnabled        = false,
        iapEnabled        = false,
        analyticsEnabled  = false,
    },
}
"""

def tpl_menu_lua(display_name):
    year = datetime.now().year
    return f"""-----------------------------------------------------------------------------------------
-- scenes/menu.lua
-- Main menu scene. Presents game modes and navigates to game.
--
-- WHAT THIS FILE DOES:
--   Shows the title, mode buttons, and stats entry point.
-- SCENE FLOW:
--   menu → game (basic)
-- CHANGELOG:
--   v1.0  {year}-01-01  Initial scaffold
-----------------------------------------------------------------------------------------

local composer  = require("composer")
local settings  = require("config.settings")

local scene = composer.newScene()

local _sceneGroup

-- ── Private ───────────────────────────────────────────────────────────────────

local function goToGame()
    composer.gotoScene("scenes.game", {{ effect="slideLeft", time=300 }})
end

-- ── Scene lifecycle ───────────────────────────────────────────────────────────

function scene:create( event )
    _sceneGroup = self.view

    -- Background
    local bg = display.newRect(_sceneGroup, display.contentCenterX, display.contentCenterY,
        display.contentWidth, display.contentHeight)
    bg:setFillColor( table.unpack(settings.COLOR.BACKGROUND) )

    -- Title
    local title = display.newText({{
        parent   = _sceneGroup,
        text     = settings.GAME_NAME,
        x        = display.contentCenterX,
        y        = display.contentCenterY - 80,
        font     = settings.FONT.BOLD,
        fontSize = 36,
    }})
    title:setFillColor(1, 1, 1)

    -- Play button
    local btnBg = display.newRoundedRect(_sceneGroup,
        display.contentCenterX, display.contentCenterY + 40, 160, 50, 10)
    btnBg:setFillColor( table.unpack(settings.COLOR.BUTTON_PRIMARY) )

    local btnLabel = display.newText({{
        parent   = _sceneGroup,
        text     = "PLAY",
        x        = display.contentCenterX,
        y        = display.contentCenterY + 40,
        font     = settings.FONT.BOLD,
        fontSize = 20,
    }})
    btnLabel:setFillColor(1, 1, 1)

    btnBg:addEventListener("tap", goToGame)
end

function scene:show( event )
    if event.phase == "will" then
        -- reset state before visible
    elseif event.phase == "did" then
        -- start any menu animations here
    end
end

function scene:hide( event )
    if event.phase == "will" then
        -- pause anything running
    end
end

function scene:destroy( event )
    -- composer cleans up display groups automatically
end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
"""

def tpl_game_lua(display_name):
    year = datetime.now().year
    return f"""-----------------------------------------------------------------------------------------
-- scenes/game.lua
-- Main game scene for {display_name}.
--
-- WHAT THIS FILE DOES:
--   Renders the game grid, handles player input, runs the post-merge pipeline.
-- SCENE FLOW:
--   game → gameover overlay on win/lose
-- CHANGELOG:
--   v1.0  {year}-01-01  Initial scaffold (stub)
-----------------------------------------------------------------------------------------

local composer  = require("composer")
local settings  = require("config.settings")
-- local GL     = require("app.helpers.gameLogic")   -- uncomment when ready

local scene = composer.newScene()

local _sceneGroup
local _touchEnabled = true

-- Forward declarations for mutually-recursive functions
-- local _endSession

-- ── Private ───────────────────────────────────────────────────────────────────

-- TODO: implement game logic here following the three-layer architecture.
-- See solar2d_game_architecture_v2.md §6 for the post-merge pipeline pattern.

-- ── Scene lifecycle ───────────────────────────────────────────────────────────

function scene:create( event )
    _sceneGroup = self.view
    local params = event.params or {{}}

    local bg = display.newRect(_sceneGroup, display.contentCenterX, display.contentCenterY,
        display.contentWidth, display.contentHeight)
    bg:setFillColor( table.unpack(settings.COLOR.BACKGROUND) )

    local lbl = display.newText({{
        parent   = _sceneGroup,
        text     = "Game scene — implement me!",
        x        = display.contentCenterX,
        y        = display.contentCenterY,
        font     = settings.FONT.NORMAL,
        fontSize = 18,
        width    = display.contentWidth - 40,
        align    = "center",
    }})
    lbl:setFillColor(1, 1, 1)
end

function scene:show( event )
    if event.phase == "will" then
        _touchEnabled = true
    elseif event.phase == "did" then
        -- start timers here
    end
end

function scene:hide( event )
    if event.phase == "will" then
        _touchEnabled = false
    elseif event.phase == "did" then
        -- cancel transitions here
    end
end

function scene:destroy( event )
    -- cancel Runtime: listeners and timers here
end

scene:addEventListener("create",  scene)
scene:addEventListener("show",    scene)
scene:addEventListener("hide",    scene)
scene:addEventListener("destroy", scene)

return scene
"""

def tpl_game_logic_lua(display_name):
    year = datetime.now().year
    return f"""-----------------------------------------------------------------------------------------
-- app/helpers/gameLogic.lua
-- Pure game rules for {display_name}. NO display, NO transition, NO timer.
-- Can be tested without Solar2D running.
--
-- CHANGELOG:
--   v1.0  {year}-01-01  Initial scaffold (stub)
-----------------------------------------------------------------------------------------

local M = {{}}

--- Initialise a new empty grid.
--- @param rows number
--- @param cols number
--- @return table grid[i][j] = {{ num=nil, i=i, j=j }}
function M.newGrid(rows, cols)
    local grid = {{}}
    for i = 1, rows do
        grid[i] = {{}}
        for j = 1, cols do
            grid[i][j] = {{ num=nil, i=i, j=j }}
        end
    end
    return grid
end

--- TODO: add applyGravity(), findGroups(), checkWin(), etc.

return M
"""

def tpl_score_helper_lua(display_name):
    year = datetime.now().year
    return f"""-----------------------------------------------------------------------------------------
-- app/helpers/scoreHelper.lua
-- All scoring formulas for {display_name}. Pure math — no display.
--
-- CHANGELOG:
--   v1.0  {year}-01-01  Initial scaffold (stub)
-----------------------------------------------------------------------------------------

local settings = require("config.settings")
local M = {{}}

--- Format a score number for display (1200 → "1.2K", 1500000 → "1.5M").
--- @param n number
--- @return string
function M.scoreDisplay(n)
    if n >= 1000000 then return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then return string.format("%.1fK", n / 1000)
    else return tostring(math.floor(n)) end
end

--- TODO: add merge score formula, XP calculation, etc.

return M
"""

def tpl_audio_helper_lua():
    return """-----------------------------------------------------------------------------------------
-- app/helpers/audioHelper.lua
-- Pre-load and play all game sounds. Fails silently if files are missing.
--
-- CHANGELOG:
--   v1.0  Initial scaffold (stub)
-----------------------------------------------------------------------------------------

local M = {}
local _sounds  = {}
local _enabled = true
local PATH     = "app/assets/audio/"

local function load(key, file)
    local h = audio.loadSound(PATH .. file)
    if h then _sounds[key] = h end
end

local function play(key)
    if not _enabled then return end
    local h = _sounds[key]
    if h then audio.play(h) end
end

--- Initialise: pre-load all sounds. Call once at boot in main.lua.
function M.init()
    -- load("tap",  "button_tap.mp3")
    -- load("win",  "endgame_win.mp3")
    -- load("lose", "endgame_lose.mp3")
end

--- @param flag boolean
function M.setEnabled(flag) _enabled = flag end

function M.playTap()  play("tap")  end
function M.playWin()  play("win")  end
function M.playLose() play("lose") end

return M
"""

def tpl_save_state_lua(display_name):
    year = datetime.now().year
    return f"""-----------------------------------------------------------------------------------------
-- app/helpers/saveState.lua
-- All SQLite persistence for {display_name}: game state, stats, settings.
--
-- CHANGELOG:
--   v1.0  {year}-01-01  Initial scaffold (stub)
-----------------------------------------------------------------------------------------

local dbModel = require("app.models.dbModel")
local json    = require("json")
local M       = {{}}

local STATS_DEFAULT = {{
    gamesPlayed  = 0,
    bestScore    = 0,
    totalMerges  = 0,
    highestTile  = 0,
    totalXP      = 0,
}}

--- Create tables and seed defaults. Call once at boot.
function M.init()
    dbModel.createTable("settings", {{
        key   = "TEXT PRIMARY KEY",
        value = "TEXT",
    }})
    dbModel.createTable("statsState", {{
        key   = "TEXT PRIMARY KEY",
        value = "TEXT",
    }}, {{
        {{ key="stats", value=json.encode(STATS_DEFAULT) }},
    }})
end

--- @return table stats
function M.getStats()
    local row = dbModel.getRow("SELECT value FROM statsState WHERE key='stats';")
    return row and json.decode(row.value) or STATS_DEFAULT
end

--- @param stats table
function M.saveStats(stats)
    local encoded = json.encode(stats):gsub("'", "''")
    dbModel.exec("INSERT OR REPLACE INTO statsState (key, value) VALUES ('stats', '" .. encoded .. "');")
end

return M
"""

def tpl_db_model_lua():
    return """-----------------------------------------------------------------------------------------
-- app/models/dbModel.lua
-- Raw SQLite wrapper. All models use this. No game logic here.
--
-- CHANGELOG:
--   v1.0  Initial (production-ready pattern from Get10 v4.0)
-----------------------------------------------------------------------------------------

local sqlite3 = require("sqlite3")
local M = {}
local _db = nil

--- Open the database. Call once at boot in main.lua.
function M.init()
    if _db then return end
    _db = sqlite3.open(system.pathForFile("game.db", system.DocumentsDirectory))
end

--- Create a table if it does not exist, optionally seeding rows if empty.
--- @param name string
--- @param columns table  { colName = "TYPE CONSTRAINTS", ... }
--- @param seedRows table|nil  array of { colName=value, ... }
function M.createTable(name, columns, seedRows)
    local defs = {}
    for col, typedef in pairs(columns) do
        defs[#defs + 1] = col .. " " .. typedef
    end
    _db:exec("CREATE TABLE IF NOT EXISTS " .. name .. " (" .. table.concat(defs, ", ") .. ");")
    if seedRows then
        for row in _db:nrows("SELECT COUNT(*) as cnt FROM " .. name .. ";") do
            if row.cnt == 0 then
                for _, r in ipairs(seedRows) do
                    local cols, vals = {}, {}
                    for k, v in pairs(r) do
                        cols[#cols + 1] = k
                        vals[#vals + 1] = "'" .. tostring(v) .. "'"
                    end
                    _db:exec("INSERT INTO " .. name .. " (" .. table.concat(cols, ",") ..
                        ") VALUES (" .. table.concat(vals, ",") .. ");")
                end
            end
            break
        end
    end
end

--- Return the first row from a SELECT query, or nil.
--- @param sql string
--- @return table|nil
function M.getRow(sql)
    for row in _db:nrows(sql) do return row end
    return nil
end

--- Execute any SQL statement.
--- @param sql string
function M.exec(sql) return _db:exec(sql) end

return M
"""

def tpl_settings_model_lua():
    return """-----------------------------------------------------------------------------------------
-- app/models/settingsModel.lua
-- User preferences: sound on/off, high score, first-run flag.
--
-- CHANGELOG:
--   v1.0  Initial scaffold (stub)
-----------------------------------------------------------------------------------------

local dbModel = require("app.models.dbModel")
local M = {}

local DEFAULTS = {
    sound     = "1",
    highScore = "0",
    firstRun  = "1",
}

--- Ensure settings table exists with defaults.
function M.init()
    local seeds = {}
    for k, v in pairs(DEFAULTS) do
        seeds[#seeds + 1] = { key=k, value=v }
    end
    dbModel.createTable("settings", {
        key   = "TEXT PRIMARY KEY",
        value = "TEXT",
    }, seeds)
end

local function get(key)
    local row = dbModel.getRow("SELECT value FROM settings WHERE key='" .. key .. "';")
    return row and row.value or DEFAULTS[key]
end

local function set(key, value)
    dbModel.exec("INSERT OR REPLACE INTO settings (key, value) VALUES ('" .. key .. "', '" .. tostring(value) .. "');")
end

function M.getSound()    return get("sound") == "1" end
function M.setSound(v)   set("sound", v and "1" or "0") end
function M.getHighScore() return tonumber(get("highScore")) or 0 end
function M.setHighScore(n) set("highScore", tostring(math.floor(n))) end
function M.isFirstRun()   return get("firstRun") == "1" end
function M.clearFirstRun() set("firstRun", "0") end

return M
"""

def tpl_audio_readme():
    return """# Audio Files

Place all .mp3 files here before submitting to App Store / Play Store.

Recommended free sources:
  freesound.org
  zapsplat.com
  mixkit.co

Typical files needed:
  button_tap.mp3        — short UI click (< 0.2s)
  endgame_win.mp3       — win fanfare (1-2s)
  endgame_lose.mp3      — lose sound (1-2s)
  endgame_highscore.mp3 — triumphant new record (1-2s)

For tile games with numbered tiles, add:
  1.mp3 … N.mp3         — ascending musical tones, one per tile value

Load all sounds in audioHelper.init() at boot.
Do NOT use audio.loadStream() for short sounds — use audio.loadSound().
"""

# ── platform.json updater ─────────────────────────────────────────────────────

def register_in_platform_json(platform_json_path, slug, display_name, description, folder_name):
    with open(platform_json_path) as f:
        data = json.load(f)

    if slug in data["games"]:
        print(f"\n  WARNING: slug '{slug}' already exists in platform.json — skipping registration.")
        return

    data["games"][slug] = {
        "_status":           "IN DEVELOPMENT",
        "project_folder":    folder_name,
        "display_name":      display_name,
        "short_name":        pascal_case(display_name),
        "bundle_id_ios":     f"com.YOURCOMPANY.{slug}",
        "bundle_id_android": f"com.YOURCOMPANY.{slug}",
        "version":           "1.0.0",
        "build_number":      1,
        "entry_scene":       "scenes.menu",
        "description":       description,
        "ads": {
            "_comment":                "Replace PLACEHOLDER values before publishing",
            "admob_app_id_ios":        "PLACEHOLDER_ADMOB_APP_ID_IOS",
            "admob_app_id_android":    "PLACEHOLDER_ADMOB_APP_ID_ANDROID",
            "banner_id_ios":           "PLACEHOLDER_BANNER_IOS",
            "banner_id_android":       "PLACEHOLDER_BANNER_ANDROID",
            "interstitial_id_ios":     "PLACEHOLDER_INTERSTITIAL_IOS",
            "interstitial_id_android": "PLACEHOLDER_INTERSTITIAL_ANDROID",
            "rewarded_id_ios":         "PLACEHOLDER_REWARDED_IOS",
            "rewarded_id_android":     "PLACEHOLDER_REWARDED_ANDROID",
        },
        "urls": {
            "privacy": f"https://example.com/{slug}/privacy",
            "terms":   f"https://example.com/{slug}/terms",
            "support": f"https://example.com/{slug}/support",
        },
        "social":    { "twitter": "", "facebook": "", "website": "" },
        "app_store": {
            "apple_id":           "",
            "google_play_id":     "",
            "apple_team_id":      "",
            "apple_provisioning": "",
        },
        "features": {
            "ads_enabled":         False,
            "iap_enabled":         False,
            "analytics_enabled":   False,
            "leaderboard_enabled": False,
        },
    }

    with open(platform_json_path, "w") as f:
        json.dump(data, f, indent=2)
    print(f"  updated  {os.path.relpath(platform_json_path)}")

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Scaffold a new Solar2D game inside the Solar2DPuzzle platform."
    )
    parser.add_argument("slug",         help="Short lowercase identifier, e.g. blockdrop")
    parser.add_argument("display_name", help="Human-readable name, e.g. 'Block Drop'")
    parser.add_argument("description",  help="One sentence: core mechanic")
    args = parser.parse_args()

    slug         = args.slug.lower().replace(" ", "")
    display_name = args.display_name
    description  = args.description
    year         = datetime.now().year
    folder_name  = pascal_case(display_name) + f"-{year}"

    # Must be run from Solar2DPuzzle/ root
    platform_json = os.path.join("Tools", "platform.json")
    if not os.path.exists(platform_json):
        print("ERROR: Run this script from the Solar2DPuzzle/ root folder.")
        print("  cd path/to/Solar2DPuzzle")
        print("  python Tools/init.py ...")
        sys.exit(1)

    root = folder_name

    if os.path.exists(root):
        print(f"ERROR: Folder '{root}' already exists. Aborting.")
        sys.exit(1)

    print(f"\nScaffolding '{display_name}' → {root}/\n")

    # ── Files ──────────────────────────────────────────────────────────────────
    write_file(f"{root}/.gitignore",                          tpl_gitignore())
    write_file(f"{root}/CLAUDE.md",                           tpl_claude_md(display_name, slug, description, folder_name))
    write_file(f"{root}/HandOff2ClaudeCode.md",               tpl_handoff(display_name, description))
    write_file(f"{root}/main.lua",                            tpl_main_lua(display_name, slug))
    write_file(f"{root}/config.lua",                          tpl_config_lua())
    write_file(f"{root}/build.settings",                      tpl_build_settings(display_name))
    write_file(f"{root}/config/settings.lua",                 tpl_settings_lua(display_name))
    write_file(f"{root}/config/activeGame.lua",               tpl_active_game_lua(slug, display_name))
    write_file(f"{root}/config/gameConfig.lua",               tpl_game_config_lua())
    write_file(f"{root}/scenes/menu.lua",                     tpl_menu_lua(display_name))
    write_file(f"{root}/scenes/game.lua",                     tpl_game_lua(display_name))
    write_file(f"{root}/app/helpers/gameLogic.lua",           tpl_game_logic_lua(display_name))
    write_file(f"{root}/app/helpers/scoreHelper.lua",         tpl_score_helper_lua(display_name))
    write_file(f"{root}/app/helpers/audioHelper.lua",         tpl_audio_helper_lua())
    write_file(f"{root}/app/helpers/saveState.lua",           tpl_save_state_lua(display_name))
    write_file(f"{root}/app/models/dbModel.lua",              tpl_db_model_lua())
    write_file(f"{root}/app/models/settingsModel.lua",        tpl_settings_model_lua())
    write_file(f"{root}/app/assets/audio/README.txt",         tpl_audio_readme())
    touch(f"{root}/app/components/.gitkeep")
    touch(f"{root}/data/levels/intermediate/.gitkeep")
    touch(f"{root}/data/levels/advanced/.gitkeep")
    touch(f"{root}/vibe/bug/.gitkeep")
    touch(f"{root}/vibe/improvement/.gitkeep")
    touch(f"{root}/vibe/others/.gitkeep")

    # ── Register in platform.json ──────────────────────────────────────────────
    register_in_platform_json(platform_json, slug, display_name, description, folder_name)

    # ── Next steps ─────────────────────────────────────────────────────────────
    print(f"""
Done! '{display_name}' scaffolded at {root}/

Next steps:
  1. Open Solar2D Simulator → File → Open → {root}/
  2. Define your core mechanic in {root}/config/settings.lua
  3. Fill in the TODO sections in {root}/CLAUDE.md
  4. Build the game scene: {root}/scenes/game.lua
  5. Update platform.json with real bundle IDs when ready to publish:
       python Tools/build.py prepare {slug} mobile

Git:
  git add {root}/ Tools/platform.json
  git commit -m "feat: scaffold {display_name} game"
""")

if __name__ == "__main__":
    main()
