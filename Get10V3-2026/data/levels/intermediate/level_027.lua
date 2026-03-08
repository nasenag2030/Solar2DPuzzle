-------------------------------------------------------------------------
-- data/levels/intermediate/level_027.lua
-- Get10 — Intermediate Level 27: The Fortress
-- Goal: REACH  |  Target: 7  |  Par: 36 moves
-------------------------------------------------------------------------

return {
    name   = "The Fortress",
    goal   = "reach",
    target = 7,
    moves  = nil,
    par    = 36,
    noBomb = false,
    hint   = "Seven bricks in a fortress pattern — break through to reach tile 7!",
    grid   = {
        {1, 2, 3, 4, 2, 1},
        {2, 3, 2, 1, 3, 2},
        {3, 1, 2, 3, 1, 4},
        {4, 2, 3, 2, 4, 1},
        {1, 4, 1, 4, 2, 3},
        {2, 1, 4, 1, 3, 2},
    },
}
