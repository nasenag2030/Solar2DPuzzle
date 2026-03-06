-----------------------------------------------------------------------------------------
--
-- main.lua
-- Get10 - Main Entry Point
--
-- Description:
--   Bootstraps the application. Sets display properties, initialises
--   database / settings, and navigates to the first scene.
--
-----------------------------------------------------------------------------------------

-- Hide status bar on all platforms
display.setStatusBar( display.HiddenStatusBar )

-- Allow background audio from other apps to keep playing
local audio = require("audio")
if audio.supportsSessionProperty then
    audio.setSessionProperty( audio.MixMode, audio.AmbientMixMode )
end

-- Initialise storage (SQLite via dbModel + settingsModel)
local dbModel       = require("app.models.dbModel")
local settingsModel = require("app.models.settingsModel")
local saveState     = require("app.helpers.saveState")

dbModel.init()
settingsModel.init()
saveState.init()

-- Initialise audio helper (pre-loads sounds)
local audioHelper = require("app.helpers.audioHelper")
audioHelper.init()

-- Launch first scene — show T&C on first install, menu thereafter
local composer = require("composer")
composer.recycleOnSceneChange = false   -- keep game scene in memory

if saveState.hasAcceptedTerms() then
    composer.gotoScene("scenes.menu")
else
    composer.gotoScene("scenes.termsAndConditions")
end
