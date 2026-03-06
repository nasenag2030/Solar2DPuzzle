-------------------------------------------------------------------------
-- data/levels/intermediate/level_003.lua
-- Get10 — Intermediate Level 3: Score Attack
-- Goal: SCORE  |  Target: 100  |  Par: 10 moves
-------------------------------------------------------------------------

return {
    name   = "Score Attack",
    goal   = "score",
    target = 100,
    moves  = 10,
    par    = 10,
    noBomb = false,
    hint   = "Merging higher tiles earns more points. Target the 3s and 4s!",
    grid   = nil,  -- random fill
}
