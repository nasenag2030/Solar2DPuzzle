-------------------------------------------------------------------------
-- data/levels/intermediate/level_031.lua
-- Get10 — Intermediate Level 31: Grid Lock
-- Goal: REACH  |  Target: 8  |  Par: 42 moves
-------------------------------------------------------------------------

return {
    name   = "Grid Lock",
    goal   = "reach",
    target = 8,
    moves  = nil,
    par    = 42,
    noBomb = false,
    hint   = "Eight bricks in a ring formation — the center is your battlefield!",
    grid   = {
        {3, 2, 4, 3, 2, 4},
        {4, 3, 2, 4, 3, 2},
        {2, 4, 3, 2, 4, 3},
        {3, 2, 4, 3, 2, 4},
        {4, 3, 2, 4, 3, 2},
        {2, 4, 3, 2, 4, 3},
    },
}
