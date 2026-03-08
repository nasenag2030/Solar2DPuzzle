-------------------------------------------------------------------------
-- data/levels/intermediate/level_042.lua
-- Get10 — Intermediate Level 42: Diamond Cut
-- Goal: SCORE  |  Target: 1200  |  Par: 28 moves
-------------------------------------------------------------------------

return {
    name   = "Diamond Cut",
    goal   = "score",
    target = 1200,
    moves  = 40,
    par    = 28,
    noBomb = false,
    hint   = "Score 1200 — the diamond brick pattern creates juicy combo opportunities!",
    grid   = {
        {5, 4, 5, 4, 5, 4},
        {4, 5, 4, 5, 4, 5},
        {5, 4, 5, 4, 5, 4},
        {4, 5, 4, 5, 4, 5},
        {5, 4, 5, 4, 5, 4},
        {4, 5, 4, 5, 4, 5},
    },
}
