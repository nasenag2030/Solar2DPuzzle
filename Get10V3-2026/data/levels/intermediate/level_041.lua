-------------------------------------------------------------------------
-- data/levels/intermediate/level_041.lua
-- Get10 — Intermediate Level 41: The Fortress II
-- Goal: REACH  |  Target: 9  |  Par: 52 moves
-------------------------------------------------------------------------

return {
    name   = "The Fortress II",
    goal   = "reach",
    target = 9,
    moves  = nil,
    par    = 52,
    noBomb = false,
    hint   = "Ten bricks form a fortress — breach the walls to reach tile 9!",
    grid   = {
        {4, 5, 3, 4, 5, 3},
        {5, 3, 5, 3, 4, 5},
        {3, 5, 4, 5, 3, 4},
        {5, 4, 3, 4, 5, 3},
        {4, 3, 5, 3, 4, 5},
        {3, 5, 4, 5, 3, 4},
    },
}
