local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG
local F = _G.Foundry_1_0

local commandOrder = {
    "show", "hide", "minimap", "allstats", "stats", "joinstats", "unjoinstats", "listalts",
    "updatestat", "deletestat", "resetstats", "exportstats", "importstats", "ban", "unban",
    "listbans", "audit", "ledger", "profiles", "profile", "testing", "testbots", "stoptest",
}

function CrossGambling:PrintCommandHelp()
    self:Print(L["Commands_Commands"] .. table.concat(commandOrder, ", "))
    self:Print(L["Commands_UsageCgCommandValue"])
end

function CrossGambling:InitCommands()
    local commands = F.Commands:New({
        name = "CrossGambling",
        slashes = { "/cg", "/crossgambling" },
        printer = function(line) CrossGambling:Print(line) end,
        defaultHandler = function() CrossGambling:PrintCommandHelp() end,
        unknownMessage = function(input)
            local token = input:match("^(%S+)") or input
            CrossGambling:Print((L["Commands_UnknownCommand"]):format(token:lower()))
            CrossGambling:PrintCommandHelp()
            return ""
        end,
    })
    self.commands = commands

    commands:Register({ name = "show", help = L["Commands_ShowGame"],
        handler = function() CrossGambling:ToggleGUI(nil, true) end })
    commands:Register({ name = "hide", help = L["Commands_HideGame"],
        handler = function() CrossGambling:ToggleGUI(nil, false) end })
    commands:Register({ name = "minimap", help = L["Commands_ShowHideMinimapIcon"],
        handler = function() CrossGambling:ToggleMinimap() end })
    commands:Register({ name = "allstats", help = L["Commands_ShowsAllStatsOutOfOrderIn"],
        handler = function() CrossGambling:reportStats(true) end })
    commands:Register({ name = "stats", help = L["Commands_ShowsTop3WinnersLosersOutOf"],
        handler = function() CrossGambling:reportStats() end })
    commands:Register({ name = "joinstats", args = L["Commands_MainAlt"],
        help = L["Commands_MainAltJoinTwoCharactersWinLoss"],
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print(L["Commands_UsageCgJoinstatsMainNameAltName"])
                return
            end
            CrossGambling:joinStats(nil, rest)
        end })
    commands:Register({ name = "unjoinstats", args = L["Commands_Alt"],
        help = L["Commands_AltUnjoinsTheAltFromWhomeverIt"],
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print(L["Commands_UsageCgUnjoinstatsAltUnjoinsTheAlt"])
                return
            end
            CrossGambling:unjoinStats(nil, rest)
        end })
    commands:Register({ name = "listalts", help = L["Commands_SeeEveryoneWhosUsedJoinstats"],
        handler = function() CrossGambling:listAlts() end })
    commands:Register({ name = "updatestat", args = L["Commands_PlayerAmount"],
        help = L["Commands_PlayerAmountAddAmountToPlayerS"],
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print(L["Commands_UsageCgUpdatestatPlayerAmountAddAmount"])
                return
            end
            CrossGambling:updateStat(nil, rest)
        end })
    commands:Register({ name = "deletestat", args = L["Commands_Player"],
        help = L["Commands_PlayerPermanentlyDeleteStats"],
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print(L["Commands_UsageCgDeletestatPlayerPermanentlyDeleteStats"])
                return
            end
            CrossGambling:deleteStat(nil, rest)
        end })
    commands:Register({ name = "resetstats", help = L["Commands_DeletesAllStats"],
        handler = function() CrossGambling:resetStats() end })
    commands:Register({ name = "exportstats", help = L["Commands_OpenTheStatsExportWindow"],
        handler = function() CrossGambling:ShowStatsTransferFrame("export") end })
    commands:Register({ name = "importstats", help = L["Commands_OpenTheStatsImportWindow"],
        handler = function() CrossGambling:ShowStatsTransferFrame("import") end })
    commands:Register({ name = "ban", args = L["Commands_Player"],
        help = L["Commands_PlayerBanPlayersFromJoining"],
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print(L["Commands_UsageCgBanPlayerBanPlayersFrom"])
                return
            end
            CrossGambling:banPlayer(nil, rest)
        end })
    commands:Register({ name = "unban", args = L["Commands_Player"],
        help = L["Commands_PlayerUnbansAPreviouslyBannedPlayer"],
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print(L["Commands_UsageCgUnbanPlayerUnbansAPreviously"])
                return
            end
            CrossGambling:unbanPlayer(nil, rest)
        end })
    commands:Register({ name = "listbans", help = L["Commands_SeeBannedPlayers"],
        handler = function() CrossGambling:listBans() end })
    commands:Register({ name = "audit", help = L["Commands_SeeAllMergedPlayersOrChanges"],
        handler = function() CrossGambling:auditMerges() end })
    commands:Register({ name = "ledger", help = L["Commands_OpenPaymentLedgerAndOutstandingBalances"],
        handler = function() CrossGambling:ShowPaymentLedger() end })
    commands:Register({ name = "profiles", help = L["Commands_OpenNamedHistoryProfiles"],
        handler = function() CrossGambling:ShowStatProfilesFrame() end })
    commands:Register({ name = "profile", args = L["Commands_Name"],
        help = L["Commands_NameSelectAnExistingHistoryProfile"],
        handler = function(rest)
            if rest == "" then
                local name = CrossGambling:GetActiveStatProfile()
                CrossGambling:Print(L["Commands_ActiveHistoryProfile"] .. tostring(name) .. ".")
                return
            end
            CrossGambling:SetActiveStatProfile(rest)
        end })
    commands:Register({ name = "testing", args = "[on|off]",
        help = L["Commands_OnOffEnableToUnlockCgTestbots"],
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print(L["Commands_UsageCgTestingOnOffEnableTo"])
                return
            end
            CrossGambling:SetTestingMode(nil, rest)
        end })
    commands:Register({ name = "testbots", args = L["Commands_Count"],
        help = L["Commands_CountStartALocalBotOnlyTest"],
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print(L["Commands_UsageCgTestbotsCountStartALocal"])
                return
            end
            CrossGambling:StartBotTest(nil, rest)
        end })
    commands:Register({ name = "stoptest", help = L["Commands_StopsResetsAnInProgressBotTest"],
        handler = function() CrossGambling:StopBotTest() end })

end
