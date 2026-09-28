local ADDON_NAME, ns = ...

local F = _G.Foundry_1_0
if not F then
    error("CrossGambling requires Foundry-1.0. Please install or enable it.")
end

F:RequireModule("Commands", 1)
F:RequireModule("Events", 1)
F:RequireModule("Lifecycle", 1)
F:RequireModule("DB", 1)

local CrossGambling = { name = ADDON_NAME }
ns.CG = CrossGambling
CrossGambling.ns = ns
_G.CrossGambling = CrossGambling

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

