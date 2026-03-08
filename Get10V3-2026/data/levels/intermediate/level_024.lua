-------------------------------------------------------------------------
-- data/levels/intermediate/level_024.lua
-- Get10 — Intermediate Level 24: The Diagonal
-- Goal: SCORE  |  Target: 400  |  Par: 20 moves
-------------------------------------------------------------------------

return {
    name   = "The Diagonal",
    goal   = "score",
    target = 400,
    moves  = 30,
    par    = 20,
    noBomb = false,
    hint   = "Score 400 points — bricks on the diagonal, combos are your friend!",
    grid   = {
        {3, 2, 1, 2, 3, 2},
        {2, 3, 2, 3, 2, 1},
        {1, 2, 3, 1, 2, 3},
        {2, 3, 2, 3, 1, 2},
        {3, 1, 2, 2, 3, 1},
        {2, 2, 3, 1, 2, 3},
    },
}
