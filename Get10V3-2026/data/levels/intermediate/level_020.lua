-------------------------------------------------------------------------
-- data/levels/intermediate/level_020.lua
-- Get10 — Intermediate Level 20: Halfway Boss
-- Goal: REACH  |  Target: 7  |  Par: 32 moves
-------------------------------------------------------------------------

return {
    name   = "Halfway Boss",
    goal   = "reach",
    target = 7,
    moves  = nil,
    par    = 32,
    noBomb = false,
    hint   = "Level 20 milestone — reach tile 7 with 5 bricks blocking your path!",
    grid   = {
        {2, 3, 2, 1, 2, 3},
        {3, 1, 2, 3, 1, 2},
        {2, 2, 1, 2, 3, 1},
        {1, 3, 2, 1, 2, 3},
        {2, 1, 3, 2, 1, 2},
        {3, 2, 1, 3, 2, 1},
    },
}
