-------------------------------------------------------------------------
-- data/levels/intermediate/level_022.lua
-- Get10 — Intermediate Level 22: Scatter Shot
-- Goal: SURVIVE  |  Target: 25 merges  |  Par: 38
-------------------------------------------------------------------------

return {
    name   = "Scatter Shot",
    goal   = "survive",
    target = 25,
    moves  = nil,
    par    = 38,
    noBomb = false,
    hint   = "Bricks scatter across every corner — just keep merging, 25 times!",
    grid   = {
        {1, 2, 1, 2, 1, 2},
        {2, 1, 2, 1, 2, 1},
        {1, 3, 1, 3, 1, 2},
        {2, 1, 3, 1, 3, 1},
        {1, 2, 1, 2, 1, 2},
        {2, 1, 2, 1, 2, 1},
    },
}
