-------------------------------------------------------------------------
-- data/levels/intermediate/level_012.lua
-- Get10 — Intermediate Level 12: Zigzag Lane
-- Goal: SURVIVE  |  Target: 20 merges  |  Par: 30
-------------------------------------------------------------------------

return {
    name   = "Zigzag Lane",
    goal   = "survive",
    target = 20,
    moves  = nil,
    par    = 30,
    noBomb = false,
    hint   = "Keep merging — reach 20 total merges to win!",
    grid   = {
        {1, 1, 2, 2, 1, 1},
        {2, 2, 1, 1, 2, 2},
        {1, 1, 2, 2, 1, 1},
        {2, 2, 1, 1, 2, 2},
        {1, 1, 2, 2, 1, 1},
        {2, 2, 1, 1, 2, 2},
    },
}
