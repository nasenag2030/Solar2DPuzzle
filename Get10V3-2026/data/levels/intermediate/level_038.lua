-------------------------------------------------------------------------
-- data/levels/intermediate/level_038.lua
-- Get10 — Intermediate Level 38: Spiral Down
-- Goal: REACH  |  Target: 8  |  Par: 44 moves
-------------------------------------------------------------------------

return {
    name   = "Spiral Down",
    goal   = "reach",
    target = 8,
    moves  = 62,
    par    = 44,
    noBomb = false,
    hint   = "Nine bricks spiral across the board — follow the open path to tile 8!",
    grid   = {
        {5, 4, 3, 4, 5, 4},
        {4, 5, 4, 5, 4, 3},
        {3, 4, 5, 4, 3, 5},
        {5, 3, 4, 5, 4, 3},
        {4, 5, 3, 4, 5, 4},
        {3, 4, 5, 3, 4, 5},
    },
}
