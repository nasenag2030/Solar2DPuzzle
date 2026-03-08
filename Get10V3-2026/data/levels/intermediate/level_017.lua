-------------------------------------------------------------------------
-- data/levels/intermediate/level_017.lua
-- Get10 — Intermediate Level 17: Cross Fire
-- Goal: SCORE  |  Target: 300  |  Par: 18 moves
-------------------------------------------------------------------------

return {
    name   = "Cross Fire",
    goal   = "score",
    target = 300,
    moves  = 26,
    par    = 18,
    noBomb = false,
    hint   = "Score 300 points — chain reactions are worth big bonus points!",
    grid   = {
        {2, 1, 2, 1, 2, 1},
        {1, 3, 1, 3, 1, 3},
        {2, 1, 3, 1, 3, 2},
        {1, 3, 1, 3, 1, 1},
        {2, 1, 3, 1, 2, 3},
        {1, 2, 1, 2, 1, 2},
    },
}
