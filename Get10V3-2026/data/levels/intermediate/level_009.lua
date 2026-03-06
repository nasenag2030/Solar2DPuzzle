-------------------------------------------------------------------------
-- data/levels/intermediate/level_009.lua
-- Get10 — Intermediate Level 9: The Stairs
-- Goal: REACH  |  Target: 6  |  Par: 13 moves
-------------------------------------------------------------------------

return {
    name   = "The Stairs",
    goal   = "reach",
    target = 6,
    moves  = 18,
    par    = 13,
    noBomb = false,
    hint   = "The staircase shape means gravity helps you on the left side.",
    grid   = {
        {1, nil, nil, nil, nil},
        {1, 2, nil, nil, nil},
        {1, 2, 3, nil, nil},
        {1, 2, 3, 2, nil},
        {1, 2, 3, 2, 1}
    },
}
