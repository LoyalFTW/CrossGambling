local _, ns = ...
local CrossGambling = ns.CG
local F = _G.Foundry_1_0

local commandOrder = {
    "show", "hide", "minimap", "allstats", "stats", "joinstats", "unjoinstats", "listalts",
    "updatestat", "deletestat", "resetstats", "exportstats", "importstats", "ban", "unban",
    "listbans", "audit", "ledger", "profiles", "profile", "testing", "testbots", "stoptest",
}

function CrossGambling:PrintCommandHelp()
    self:Print("Commands: " .. table.concat(commandOrder, ", "))
    self:Print("Usage: /cg <command> [value]")
end

function CrossGambling:InitCommands()
    local commands = F.Commands:New({
        name = "CrossGambling",
        slashes = { "/cg", "/crossgambling" },
        printer = function(line) CrossGambling:Print(line) end,
        defaultHandler = function() CrossGambling:PrintCommandHelp() end,
        unknownMessage = function(input)
            local token = input:match("^(%S+)") or input
            CrossGambling:Print(("Unknown command: %s"):format(token:lower()))
            CrossGambling:PrintCommandHelp()
            return ""
        end,
    })
    self.commands = commands

    commands:Register({ name = "show", help = "Show Game",
        handler = function() CrossGambling:ToggleGUI(nil, true) end })
    commands:Register({ name = "hide", help = "Hide Game",
        handler = function() CrossGambling:ToggleGUI(nil, false) end })
    commands:Register({ name = "minimap", help = "Show/Hide Minimap Icon",
        handler = function() CrossGambling:ToggleMinimap() end })
    commands:Register({ name = "allstats", help = "Shows all Stats(Out of Order in Guild)",
        handler = function() CrossGambling:reportStats(true) end })
    commands:Register({ name = "stats", help = "Shows Top 3 Winners/Losers(Out of Order in Guild)",
        handler = function() CrossGambling:reportStats() end })
    commands:Register({ name = "joinstats", args = '"[main]" "[alt]"',
        help = '"[main]" "[alt]" - Join two characters\' win/loss amounts; quote names containing spaces',
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print('Usage: /cg joinstats "Main Name" "Alt Name"')
                return
            end
            CrossGambling:joinStats(nil, rest)
        end })
    commands:Register({ name = "unjoinstats", args = "[alt]",
        help = "[alt] - Unjoins the Alt from whomever it's attached to",
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print("Usage: /cg unjoinstats [alt] - Unjoins the Alt from whomever it's attached to")
                return
            end
            CrossGambling:unjoinStats(nil, rest)
        end })
    commands:Register({ name = "listalts", help = "See everyone whos used joinstats",
        handler = function() CrossGambling:listAlts() end })
    commands:Register({ name = "updatestat", args = "[player] [amount]",
        help = "[player] [amount] - Add [amount] to [player]'s stats (use negative numbers to subtract)",
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print("Usage: /cg updatestat [player] [amount] - Add [amount] to [player]'s stats (use negative numbers to subtract)")
                return
            end
            CrossGambling:updateStat(nil, rest)
        end })
    commands:Register({ name = "deletestat", args = "[player]",
        help = "[player] - Permanently delete stats",
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print("Usage: /cg deletestat [player] - Permanently delete stats")
                return
            end
            CrossGambling:deleteStat(nil, rest)
        end })
    commands:Register({ name = "resetstats", help = "Deletes All Stats",
        handler = function() CrossGambling:resetStats() end })
    commands:Register({ name = "exportstats", help = "Open the stats export window",
        handler = function() CrossGambling:ShowStatsTransferFrame("export") end })
    commands:Register({ name = "importstats", help = "Open the stats import window",
        handler = function() CrossGambling:ShowStatsTransferFrame("import") end })
    commands:Register({ name = "ban", args = "[player]",
        help = "[player] -  Ban players from joining",
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print("Usage: /cg ban [player] -  Ban players from joining")
                return
            end
            CrossGambling:banPlayer(nil, rest)
        end })
    commands:Register({ name = "unban", args = "[player]",
        help = "[player] - Unbans a previously banned player",
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print("Usage: /cg unban [player] - Unbans a previously banned player")
                return
            end
            CrossGambling:unbanPlayer(nil, rest)
        end })
    commands:Register({ name = "listbans", help = "See banned players",
        handler = function() CrossGambling:listBans() end })
    commands:Register({ name = "audit", help = "See all merged players or changes",
        handler = function() CrossGambling:auditMerges() end })
    commands:Register({ name = "ledger", help = "Open payment ledger and outstanding balances",
        handler = function() CrossGambling:ShowPaymentLedger() end })
    commands:Register({ name = "profiles", help = "Open named history profiles",
        handler = function() CrossGambling:ShowStatProfilesFrame() end })
    commands:Register({ name = "profile", args = "[name]",
        help = "[name] - Select an existing history profile",
        handler = function(rest)
            if rest == "" then
                local name = CrossGambling:GetActiveStatProfile()
                CrossGambling:Print("Active history profile: " .. tostring(name) .. ".")
                return
            end
            CrossGambling:SetActiveStatProfile(rest)
        end })
    commands:Register({ name = "testing", args = "[on|off]",
        help = "[on|off] - Enable to unlock /cg testbots and debug chat echoes. Off by default.",
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print("Usage: /cg testing [on|off] - Enable to unlock /cg testbots and debug chat echoes. Off by default.")
                return
            end
            CrossGambling:SetTestingMode(nil, rest)
        end })
    commands:Register({ name = "testbots", args = "[count]",
        help = "[count] - Start a local bot-only test game in the current mode. Requires /cg testing on first.",
        handler = function(rest)
            if rest == "" then
                CrossGambling:Print("Usage: /cg testbots [count] - Start a local bot-only test game in the current mode. Requires /cg testing on first.")
                return
            end
            CrossGambling:StartBotTest(nil, rest)
        end })
    commands:Register({ name = "stoptest", help = "Stops/resets an in-progress bot test game",
        handler = function() CrossGambling:StopBotTest() end })

end
