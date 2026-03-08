-------------------------------------------------------------------------
-- data/levels/intermediate/level_015.lua
-- Get10 — Intermediate Level 15: The Squeeze
-- Goal: REACH  |  Target: 5  |  Par: 22 moves
-------------------------------------------------------------------------

return {
    name   = "The Squeeze",
    goal   = "reach",
    target = 5,
    moves  = nil,
    par    = 22,
    noBomb = false,
    hint   = "Four corner bricks tighten the board — squeeze out that tile 5!",
    grid   = {
        {1, 2, 1, 1, 2, 1},
        {2, 1, 2, 2, 1, 2},
        {1, 2, 1, 1, 2, 1},
        {2, 1, 2, 2, 1, 2},
        {1, 2, 1, 1, 2, 1},
        {2, 1, 2, 2, 1, 2},
    },
}
