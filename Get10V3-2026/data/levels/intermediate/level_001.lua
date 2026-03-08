-------------------------------------------------------------------------
-- data/levels/intermediate/level_001.lua
-- Get10 — Intermediate Level 1: Getting Started
-- Goal: REACH  |  Target: 4  |  Par: 8 moves
-------------------------------------------------------------------------

return {
    name   = "Getting Started",
    goal   = "reach",
    target = 4,
    moves  = nil,   -- unlimited
    par    = 8,
    noBomb = false,
    hint   = "Tap any connected group of matching numbers to merge!",
    grid   = {
        {1, 1, 2, 1, 1, 2},
        {2, 1, 1, 2, 1, 1},
        {1, 2, 2, 1, 2, 1},
        {2, 1, 1, 2, 1, 2},
        {1, 2, 1, 1, 2, 1},
        {2, 1, 2, 1, 1, 2},
    },
}
