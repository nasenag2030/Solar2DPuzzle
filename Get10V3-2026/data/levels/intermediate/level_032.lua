-------------------------------------------------------------------------
-- data/levels/intermediate/level_032.lua
-- Get10 — Intermediate Level 32: The Maze
-- Goal: SCORE  |  Target: 500  |  Par: 22 moves
-------------------------------------------------------------------------

return {
    name   = "The Maze",
    goal   = "score",
    target = 500,
    moves  = 32,
    par    = 22,
    noBomb = false,
    hint   = "Score 500 points navigating a brick maze — find the chain reactions!",
    grid   = {
        {3, 4, 3, 2, 4, 3},
        {2, 3, 4, 3, 2, 4},
        {4, 2, 3, 4, 3, 2},
        {3, 4, 2, 3, 4, 3},
        {2, 3, 4, 2, 3, 4},
        {4, 2, 3, 4, 2, 3},
    },
}
