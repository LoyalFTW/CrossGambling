local ADDON_NAME, ns = ...
local L = LibStub("AceLocale-3.0"):GetLocale("CrossGambling")
ns.L = L

local F = _G.Foundry_1_0
if not F then
    error(L["Theme_RequiresFoundry10PleaseInstallOr"])
end

F:RequireModule("Commands", 1)
F:RequireModule("Events", 1)
F:RequireModule("Lifecycle", 1)
F:RequireModule("DB", 1)

local CrossGambling = { name = ADDON_NAME }
ns.CG = CrossGambling
CrossGambling.ns = ns
_G.CrossGambling = CrossGambling

local channelNames = {
    PARTY = L["Channel_Party"],
    RAID = L["Channel_Raid"],
    GUILD = L["Channel_Guild"],
    INSTANCE_CHAT = L["Channel_Instance"],
}

function CrossGambling:GetChannelDisplayName(channel)
    return channelNames[channel] or channel
end

local PRINT_PREFIX = "|cff33ff99CrossGambling|r:"

function CrossGambling:Print(...)
    local parts = { PRINT_PREFIX }
    local n = 1
    for i = 1, select("#", ...) do
        n = n + 1
        parts[n] = tostring((select(i, ...)))
    end
    DEFAULT_CHAT_FRAME:AddMessage(table.concat(parts, " ", 1, n))
end

