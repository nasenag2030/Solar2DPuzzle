-------------------------------------------------------------------------
-- data/levels/intermediate/level_047.lua
-- Get10 — Intermediate Level 47: Endgame
-- Goal: REACH  |  Target: 10  |  Par: 60 moves
-------------------------------------------------------------------------

return {
    name   = "Endgame",
    goal   = "reach",
    target = 10,
    moves  = nil,
    par    = 60,
    noBomb = false,
    hint   = "So close! Eleven bricks stand between you and tile 10. You can do it!",
    grid   = {
        {5, 6, 4, 5, 6, 5},
        {6, 4, 6, 4, 5, 6},
        {4, 6, 5, 6, 4, 5},
        {6, 5, 4, 5, 6, 4},
        {5, 4, 6, 4, 5, 6},
        {4, 6, 5, 6, 4, 5},
    },
}
