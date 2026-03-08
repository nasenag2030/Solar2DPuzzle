-------------------------------------------------------------------------
-- data/levels/intermediate/level_046.lua
-- Get10 — Intermediate Level 46: The Labyrinth
-- Goal: REACH  |  Target: 9  |  Par: 58 moves
-------------------------------------------------------------------------

return {
    name   = "The Labyrinth",
    goal   = "reach",
    target = 9,
    moves  = nil,
    par    = 58,
    noBomb = false,
    hint   = "Eleven bricks form a labyrinth — find the path through to tile 9!",
    grid   = {
        {5, 6, 5, 4, 5, 6},
        {6, 4, 6, 5, 6, 4},
        {4, 6, 5, 6, 4, 5},
        {6, 5, 4, 5, 6, 4},
        {5, 4, 6, 4, 5, 6},
        {4, 6, 5, 6, 4, 5},
    },
}
