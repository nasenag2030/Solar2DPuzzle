-------------------------------------------------------------------------
-- data/levels/intermediate/level_010.lua
-- Get10 — Intermediate Level 10: First Boss
-- Goal: REACH  |  Target: 7  |  Par: 22 moves
-------------------------------------------------------------------------

return {
    name   = "First Boss",
    goal   = "reach",
    target = 7,
    moves  = nil,   -- unlimited
    par    = 26,
    noBomb = false,
    hint   = "Reach tile 7! Chain reactions are your best friend here.",
    grid   = {
        {3, 2, 1, 1, 2, 3},
        {2, 3, 2, 2, 3, 2},
        {1, 2, 3, 3, 2, 1},
        {1, 2, 3, 3, 2, 1},
        {2, 3, 2, 2, 3, 2},
        {3, 2, 1, 1, 2, 3},
    },
}
