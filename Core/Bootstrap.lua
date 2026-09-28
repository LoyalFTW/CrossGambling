local addonName, ns = ...
local CrossGambling = ns.CG
local Foundry = _G.Foundry_1_0

local lifecycle = Foundry.Lifecycle:New(CrossGambling, addonName)
CrossGambling._lifecycle = lifecycle

lifecycle:OnAddonLoaded(function()
    lifecycle:OnLogin(function(addon)
        addon:OnInitialize()
    end)
end)
