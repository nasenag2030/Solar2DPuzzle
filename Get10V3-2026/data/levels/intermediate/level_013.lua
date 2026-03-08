-------------------------------------------------------------------------
-- data/levels/intermediate/level_013.lua
-- Get10 — Intermediate Level 13: Center Block
-- Goal: REACH  |  Target: 5  |  Par: 20 moves
-------------------------------------------------------------------------

return {
    name   = "Center Block",
    goal   = "reach",
    target = 5,
    moves  = nil,
    par    = 20,
    noBomb = false,
    hint   = "A 2×2 brick wall blocks the center — use the sides!",
    grid   = {
        {2, 1, 2, 1, 2, 1},
        {1, 2, 1, 2, 1, 2},
        {2, 1, 2, 2, 1, 2},
        {1, 2, 2, 2, 2, 1},
        {2, 1, 1, 2, 1, 2},
        {1, 2, 1, 1, 2, 1},
    },
}
