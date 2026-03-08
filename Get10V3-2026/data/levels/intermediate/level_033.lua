-------------------------------------------------------------------------
-- data/levels/intermediate/level_033.lua
-- Get10 — Intermediate Level 33: Ring of Fire
-- Goal: REACH  |  Target: 8  |  Par: 44 moves
-------------------------------------------------------------------------

return {
    name   = "Ring of Fire",
    goal   = "reach",
    target = 8,
    moves  = nil,
    par    = 44,
    noBomb = false,
    hint   = "Bricks form a ring pattern — work the inside and outside simultaneously!",
    grid   = {
        {2, 3, 4, 3, 2, 4},
        {4, 2, 3, 4, 3, 2},
        {3, 4, 2, 3, 4, 3},
        {2, 3, 4, 2, 3, 4},
        {4, 2, 3, 4, 2, 3},
        {3, 4, 2, 3, 4, 2},
    },
}
