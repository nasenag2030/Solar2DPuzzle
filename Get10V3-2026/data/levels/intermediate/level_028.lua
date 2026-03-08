-------------------------------------------------------------------------
-- data/levels/intermediate/level_028.lua
-- Get10 — Intermediate Level 28: Frame Game
-- Goal: SURVIVE  |  Target: 30 merges  |  Par: 45
-------------------------------------------------------------------------

return {
    name   = "Frame Game",
    goal   = "survive",
    target = 30,
    moves  = nil,
    par    = 45,
    noBomb = false,
    hint   = "Bricks frame the inner area — survive 30 merges in the tight space!",
    grid   = {
        {2, 3, 2, 3, 2, 3},
        {3, 2, 3, 2, 3, 2},
        {2, 3, 4, 3, 2, 3},
        {3, 2, 3, 4, 3, 2},
        {2, 3, 2, 3, 2, 3},
        {3, 2, 3, 2, 3, 2},
    },
}
