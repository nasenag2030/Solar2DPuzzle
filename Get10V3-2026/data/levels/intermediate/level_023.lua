-------------------------------------------------------------------------
-- data/levels/intermediate/level_023.lua
-- Get10 — Intermediate Level 23: Bull's Eye
-- Goal: REACH  |  Target: 7  |  Par: 30 moves
-------------------------------------------------------------------------

return {
    name   = "Bull's Eye",
    goal   = "reach",
    target = 7,
    moves  = nil,
    par    = 30,
    noBomb = false,
    hint   = "A 2×2 brick block plugs the center — aim for the edges!",
    grid   = {
        {2, 1, 3, 2, 1, 3},
        {1, 3, 2, 1, 3, 2},
        {3, 2, 1, 3, 2, 1},
        {2, 1, 3, 2, 1, 3},
        {1, 3, 2, 1, 3, 2},
        {3, 2, 1, 3, 2, 1},
    },
}
