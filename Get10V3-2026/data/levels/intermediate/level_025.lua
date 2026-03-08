-------------------------------------------------------------------------
-- data/levels/intermediate/level_025.lua
-- Get10 — Intermediate Level 25: Triple Threat
-- Goal: REACH  |  Target: 7  |  Par: 32 moves
-------------------------------------------------------------------------

return {
    name   = "Triple Threat",
    goal   = "reach",
    target = 7,
    moves  = nil,
    par    = 32,
    noBomb = false,
    hint   = "Six bricks in two diagonal lines — thread through the gaps!",
    grid   = {
        {2, 1, 2, 3, 1, 2},
        {1, 3, 1, 2, 3, 1},
        {3, 2, 3, 1, 2, 3},
        {2, 1, 2, 3, 1, 2},
        {1, 3, 1, 2, 3, 1},
        {3, 2, 3, 1, 2, 3},
    },
}
