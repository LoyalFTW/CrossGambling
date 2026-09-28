local _, ns = ...
local CrossGambling = ns.CG


CrossGambling:RegisterMode(CrossGambling:NewHighLowMode(
    "BigTwo",
    "Everyone rolls 1-2. High roll wins the full wager from the low roll. Ties at the top or bottom re-roll.",
    { fixedMax = 2, stakeIsWager = true }
))
