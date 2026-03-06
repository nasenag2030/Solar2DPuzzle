-------------------------------------------------------------------------
-- data/levels/intermediate/level_005.lua
-- Get10 — Intermediate Level 5: Endurance
-- Goal: SURVIVE  |  Target: 15  |  Par: 20 moves
-------------------------------------------------------------------------

return {
    name   = "Endurance",
    goal   = "survive",
    target = 15,
    moves  = nil,   -- unlimited
    par    = 20,
    noBomb = false,
    hint   = "Keep merging as the board refills. Reach 15 total merges.",
    grid   = nil,  -- random fill
}
