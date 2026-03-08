-------------------------------------------------------------------------
-- data/levels/intermediate/level_030.lua
-- Get10 — Intermediate Level 30: Third Boss
-- Goal: REACH  |  Target: 8  |  Par: 40 moves
-------------------------------------------------------------------------

return {
    name   = "Third Boss",
    goal   = "reach",
    target = 8,
    moves  = nil,
    par    = 40,
    noBomb = true,
    hint   = "Level 30 boss — no bombs allowed! Pure strategy to reach tile 8.",
    grid   = {
        {4, 3, 2, 3, 4, 3},
        {3, 4, 3, 4, 3, 2},
        {2, 3, 4, 3, 2, 4},
        {4, 2, 3, 4, 3, 2},
        {3, 4, 2, 3, 4, 3},
        {2, 3, 4, 2, 3, 4},
    },
}
