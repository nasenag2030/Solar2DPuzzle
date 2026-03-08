-------------------------------------------------------------------------
-- data/levels/intermediate/level_011.lua
-- Get10 — Intermediate Level 11: Four Corners
-- Goal: REACH  |  Target: 5  |  Par: 18 moves
-------------------------------------------------------------------------

return {
    name   = "Four Corners",
    goal   = "reach",
    target = 5,
    moves  = nil,
    par    = 18,
    noBomb = false,
    hint   = "Four bricks guard the inner corners — work around them!",
    grid   = {
        {1, 2, 1, 2, 1, 2},
        {2, 1, 2, 1, 2, 1},
        {1, 2, 1, 2, 1, 2},
        {2, 1, 2, 1, 2, 1},
        {1, 2, 1, 2, 1, 2},
        {2, 1, 2, 1, 2, 1},
    },
}
