-------------------------------------------------------------------------
-- data/levels/intermediate/level_035.lua
-- Get10 — Intermediate Level 35: Score Rush
-- Goal: SCORE  |  Target: 800  |  Par: 25 moves
-------------------------------------------------------------------------

return {
    name   = "Score Rush",
    goal   = "score",
    target = 800,
    moves  = 36,
    par    = 25,
    noBomb = false,
    hint   = "Score 800 in 36 moves — go for big chains and hot zone bonuses!",
    grid   = {
        {4, 3, 4, 3, 4, 3},
        {3, 5, 3, 5, 3, 4},
        {4, 3, 5, 3, 5, 3},
        {3, 5, 3, 5, 3, 4},
        {4, 3, 5, 3, 4, 3},
        {3, 4, 3, 4, 3, 5},
    },
}
