-------------------------------------------------------------------------
-- data/levels/intermediate/level_043.lua
-- Get10 — Intermediate Level 43: Corner Siege
-- Goal: REACH  |  Target: 9  |  Par: 54 moves
-------------------------------------------------------------------------

return {
    name   = "Corner Siege",
    goal   = "reach",
    target = 9,
    moves  = nil,
    par    = 54,
    noBomb = false,
    hint   = "Ten bricks besiege all four corners — fight your way to tile 9!",
    grid   = {
        {4, 5, 4, 3, 5, 4},
        {5, 3, 5, 4, 3, 5},
        {3, 5, 4, 5, 4, 3},
        {5, 4, 3, 4, 5, 4},
        {4, 3, 5, 3, 4, 5},
        {3, 5, 4, 5, 3, 4},
    },
}
