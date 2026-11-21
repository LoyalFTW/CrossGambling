local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG


CrossGambling:RegisterMode(CrossGambling:NewHighLowMode(
    "BigTwo",
    L["BigTwoMode_EveryoneRolls12HighRollWins"],
    { fixedMax = 2, stakeIsWager = true }
))
