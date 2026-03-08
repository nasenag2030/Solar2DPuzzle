-------------------------------------------------------------------------
-- data/levels/intermediate/level_021.lua
-- Get10 — Intermediate Level 21: Six Pack
-- Goal: REACH  |  Target: 6  |  Par: 28 moves
-------------------------------------------------------------------------

return {
    name   = "Six Pack",
    goal   = "reach",
    target = 6,
    moves  = nil,
    par    = 28,
    noBomb = false,
    hint   = "Six bricks scattered across the board — find the open lanes!",
    grid   = {
        {1, 2, 3, 1, 2, 3},
        {3, 1, 2, 3, 1, 2},
        {2, 3, 1, 2, 3, 1},
        {1, 2, 3, 1, 2, 3},
        {3, 1, 2, 3, 1, 2},
        {2, 3, 1, 2, 3, 1},
    },
}
