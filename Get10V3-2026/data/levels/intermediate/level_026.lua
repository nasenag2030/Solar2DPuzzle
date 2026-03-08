-------------------------------------------------------------------------
-- data/levels/intermediate/level_026.lua
-- Get10 — Intermediate Level 26: Seven Up
-- Goal: REACH  |  Target: 7  |  Par: 34 moves
-------------------------------------------------------------------------

return {
    name   = "Seven Up",
    goal   = "reach",
    target = 7,
    moves  = nil,
    par    = 34,
    noBomb = false,
    hint   = "Seven bricks form a cross shape — work the open quadrants!",
    grid   = {
        {2, 3, 2, 1, 3, 2},
        {3, 2, 1, 3, 2, 1},
        {1, 2, 3, 2, 1, 3},
        {3, 1, 2, 3, 2, 1},
        {2, 3, 1, 1, 3, 2},
        {1, 2, 3, 2, 1, 3},
    },
}
