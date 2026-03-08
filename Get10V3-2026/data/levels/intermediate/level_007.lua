-------------------------------------------------------------------------
-- data/levels/intermediate/level_007.lua
-- Get10 — Intermediate Level 7: Corner Pocket
-- Goal: REACH  |  Target: 5  |  Par: 9 moves
-------------------------------------------------------------------------

return {
    name   = "Corner Pocket",
    goal   = "reach",
    target = 5,
    moves  = 12,
    par    = 9,
    noBomb = true,
    hint   = "No bombs this time! Merge the corners to build chains.",
    grid   = {
        {3, 1, nil, nil, 1, 3},
        {1, 2, nil, nil, 2, 1},
        {nil, nil, nil, nil, nil, nil},
        {nil, nil, nil, nil, nil, nil},
        {1, 2, nil, nil, 2, 1},
        {3, 1, nil, nil, 1, 3},
    },
}
