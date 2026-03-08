-------------------------------------------------------------------------
-- data/levels/intermediate/level_029.lua
-- Get10 — Intermediate Level 29: Split Board
-- Goal: REACH  |  Target: 8  |  Par: 38 moves
-------------------------------------------------------------------------

return {
    name   = "Split Board",
    goal   = "reach",
    target = 8,
    moves  = nil,
    par    = 38,
    noBomb = false,
    hint   = "The board is split by bricks — merge across the gap!",
    grid   = {
        {3, 2, 1, 2, 3, 4},
        {2, 4, 3, 4, 2, 1},
        {1, 3, 2, 1, 4, 3},
        {4, 2, 4, 3, 1, 2},
        {3, 1, 2, 4, 3, 4},
        {2, 4, 3, 2, 4, 1},
    },
}
