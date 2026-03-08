-------------------------------------------------------------------------
-- data/levels/intermediate/level_006.lua
-- Get10 — Intermediate Level 6: The Cross
-- Goal: REACH  |  Target: 6  |  Par: 14 moves
-------------------------------------------------------------------------

return {
    name   = "The Cross",
    goal   = "reach",
    target = 6,
    moves  = 20,
    par    = 16,
    noBomb = false,
    hint   = "Tiles only exist in the cross shape. Use the centre wisely!",
    grid   = {
        {nil, nil, 2, nil, nil, nil},
        {nil, nil, 2, nil, nil, nil},
        {nil, nil, 2, nil, nil, nil},
        {2,   2,   3, 2,   2,   2  },
        {nil, nil, 2, nil, nil, nil},
        {nil, nil, 2, nil, nil, nil},
    },
}
