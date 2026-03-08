-------------------------------------------------------------------------
-- data/levels/intermediate/level_016.lua
-- Get10 — Intermediate Level 16: Rising Five
-- Goal: REACH  |  Target: 6  |  Par: 24 moves
-------------------------------------------------------------------------

return {
    name   = "Rising Five",
    goal   = "reach",
    target = 6,
    moves  = nil,
    par    = 24,
    noBomb = false,
    hint   = "Five bricks now — build bigger groups to reach tile 6!",
    grid   = {
        {1, 1, 2, 2, 1, 1},
        {1, 2, 3, 2, 2, 1},
        {2, 3, 2, 1, 3, 2},
        {2, 2, 1, 3, 2, 1},
        {1, 2, 3, 2, 1, 2},
        {1, 1, 2, 2, 1, 1},
    },
}
