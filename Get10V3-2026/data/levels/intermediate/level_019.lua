-------------------------------------------------------------------------
-- data/levels/intermediate/level_019.lua
-- Get10 — Intermediate Level 19: No Mistakes
-- Goal: REACH  |  Target: 6  |  Par: 24 moves
-------------------------------------------------------------------------

return {
    name   = "No Mistakes",
    goal   = "reach",
    target = 6,
    moves  = nil,
    par    = 24,
    noBomb = true,
    hint   = "No bombs — pure merging skill required. Plan every move!",
    grid   = {
        {3, 2, 1, 2, 3, 2},
        {2, 1, 3, 1, 2, 3},
        {1, 3, 2, 3, 1, 2},
        {2, 1, 3, 2, 3, 1},
        {3, 2, 1, 3, 2, 1},
        {2, 3, 2, 1, 1, 3},
    },
}
