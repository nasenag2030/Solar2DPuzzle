-------------------------------------------------------------------------
-- data/levels/intermediate/level_004.lua
-- Get10 — Intermediate Level 4: Clean Sweep
-- Goal: CLEAR  |  Target: 0  |  Par: 18 moves
-------------------------------------------------------------------------

return {
    name   = "Clean Sweep",
    goal   = "clear",
    target = 0,
    moves  = nil,   -- unlimited
    par    = 18,
    noBomb = false,
    hint   = "Merge everything — no tile can remain on the board.",
    grid   = {
        {2, 2, nil, 2, 2},
        {2, 2, nil, 2, 2},
        {nil, nil, nil, nil, nil},
        {2, 2, nil, 2, 2},
        {2, 2, nil, 2, 2}
    },
}
