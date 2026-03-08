-------------------------------------------------------------------------
-- data/levels/intermediate/level_014.lua
-- Get10 — Intermediate Level 14: Corner Chase
-- Goal: SCORE  |  Target: 200  |  Par: 15 moves
-------------------------------------------------------------------------

return {
    name   = "Corner Chase",
    goal   = "score",
    target = 200,
    moves  = 22,
    par    = 15,
    noBomb = false,
    hint   = "Score 200 points in time — hit hot zones for bonus points!",
    grid   = {
        {1, 2, 1, 2, 1, 2},
        {2, 3, 2, 1, 3, 1},
        {1, 2, 3, 2, 1, 2},
        {2, 1, 2, 3, 2, 1},
        {1, 3, 1, 2, 3, 2},
        {2, 1, 2, 1, 2, 1},
    },
}
