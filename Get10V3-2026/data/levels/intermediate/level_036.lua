-------------------------------------------------------------------------
-- data/levels/intermediate/level_036.lua
-- Get10 — Intermediate Level 36: Checker
-- Goal: REACH  |  Target: 8  |  Par: 46 moves
-------------------------------------------------------------------------

return {
    name   = "Checker",
    goal   = "reach",
    target = 8,
    moves  = nil,
    par    = 46,
    noBomb = false,
    hint   = "Nine bricks in a checkerboard — every other cell is blocked!",
    grid   = {
        {3, 4, 5, 3, 4, 5},
        {4, 5, 3, 4, 5, 3},
        {5, 3, 4, 5, 3, 4},
        {3, 4, 5, 3, 4, 5},
        {4, 5, 3, 4, 5, 3},
        {5, 3, 4, 5, 3, 4},
    },
}
