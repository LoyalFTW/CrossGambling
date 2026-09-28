local _, ns = ...
local CrossGambling = ns.CG

function CrossGambling:OnInitialize()
    self:InitDB()
    self:InitMinimap()
    self:RegisterEvent("CHAT_MSG_ADDON", "OnAddonMessage")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStart")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnd")
    self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")
    self:RegisterEvent("ENCOUNTER_END", "OnEncounterEnd")
    C_Timer.After(2, function()
        if CrossGambling and CrossGambling.RequestStateSync then
            CrossGambling:RequestStateSync()
        end
    end)

    self:InitCommands()
    self.uiBuilt = false
end
