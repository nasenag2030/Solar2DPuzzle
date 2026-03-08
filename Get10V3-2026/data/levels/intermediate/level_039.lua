-------------------------------------------------------------------------
-- data/levels/intermediate/level_039.lua
-- Get10 — Intermediate Level 39: Twin Peaks
-- Goal: SURVIVE  |  Target: 40 merges  |  Par: 60
-------------------------------------------------------------------------

return {
    name   = "Twin Peaks",
    goal   = "survive",
    target = 40,
    moves  = nil,
    par    = 60,
    noBomb = false,
    hint   = "Reach 40 total merges — the brick twin-peak pattern splits your options!",
    grid   = {
        {4, 5, 4, 5, 4, 5},
        {5, 4, 5, 4, 5, 4},
        {4, 5, 4, 5, 4, 5},
        {5, 4, 5, 4, 5, 4},
        {4, 5, 4, 5, 4, 5},
        {5, 4, 5, 4, 5, 4},
    },
}
