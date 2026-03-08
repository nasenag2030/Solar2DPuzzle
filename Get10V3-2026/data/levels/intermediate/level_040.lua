-------------------------------------------------------------------------
-- data/levels/intermediate/level_040.lua
-- Get10 — Intermediate Level 40: Fourth Boss
-- Goal: REACH  |  Target: 9  |  Par: 50 moves
-------------------------------------------------------------------------

return {
    name   = "Fourth Boss",
    goal   = "reach",
    target = 9,
    moves  = nil,
    par    = 50,
    noBomb = false,
    hint   = "Level 40 boss — nine bricks form a diamond. Reach tile 9 to pass!",
    grid   = {
        {3, 5, 4, 5, 3, 4},
        {5, 4, 3, 4, 5, 3},
        {4, 3, 5, 3, 4, 5},
        {5, 4, 3, 5, 3, 4},
        {3, 5, 4, 3, 5, 4},
        {4, 3, 5, 4, 3, 5},
    },
}
