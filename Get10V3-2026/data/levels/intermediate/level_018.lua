-------------------------------------------------------------------------
-- data/levels/intermediate/level_018.lua
-- Get10 — Intermediate Level 18: The Row
-- Goal: REACH  |  Target: 6  |  Par: 26 moves
-------------------------------------------------------------------------

return {
    name   = "The Row",
    goal   = "reach",
    target = 6,
    moves  = nil,
    par    = 26,
    noBomb = false,
    hint   = "Bricks form a staggered row — tiles above and below must work together.",
    grid   = {
        {2, 2, 1, 1, 2, 2},
        {1, 1, 2, 2, 1, 1},
        {2, 2, 1, 1, 2, 2},
        {1, 1, 2, 2, 1, 1},
        {3, 2, 1, 2, 3, 1},
        {2, 3, 2, 1, 2, 3},
    },
}
