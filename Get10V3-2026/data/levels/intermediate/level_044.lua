-------------------------------------------------------------------------
-- data/levels/intermediate/level_044.lua
-- Get10 — Intermediate Level 44: The Crown
-- Goal: REACH  |  Target: 9  |  Par: 56 moves
-------------------------------------------------------------------------

return {
    name   = "The Crown",
    goal   = "reach",
    target = 9,
    moves  = 80,
    par    = 56,
    noBomb = false,
    hint   = "Ten bricks form a crown pattern — claim tile 9 and wear it!",
    grid   = {
        {5, 4, 5, 4, 5, 4},
        {4, 5, 3, 5, 4, 5},
        {5, 3, 5, 3, 5, 4},
        {4, 5, 3, 5, 3, 5},
        {5, 4, 5, 4, 5, 4},
        {4, 5, 4, 5, 4, 5},
    },
}
