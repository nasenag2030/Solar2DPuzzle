-------------------------------------------------------------------------
-- data/levels/intermediate/level_037.lua
-- Get10 — Intermediate Level 37: The Gauntlet
-- Goal: REACH  |  Target: 9  |  Par: 48 moves
-------------------------------------------------------------------------

return {
    name   = "The Gauntlet",
    goal   = "reach",
    target = 9,
    moves  = nil,
    par    = 48,
    noBomb = false,
    hint   = "Nine bricks in a gauntlet formation — chain reactions will save you!",
    grid   = {
        {4, 3, 5, 4, 3, 5},
        {3, 5, 4, 3, 5, 4},
        {5, 4, 3, 5, 4, 3},
        {4, 3, 5, 4, 3, 5},
        {3, 5, 4, 3, 5, 4},
        {5, 4, 3, 5, 4, 3},
    },
}
