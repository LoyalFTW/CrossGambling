local _, ns = ...
local CrossGambling = ns.CG
local F = _G.Foundry_1_0

local events = F.Events:New("CrossGambling")

function CrossGambling:RegisterEvent(event, methodName)
    if events:IsRegistered(event) then
        return
    end
    events:Register(event, function(firedEvent, ...)
        local method = CrossGambling[methodName]
        if method then
            method(CrossGambling, firedEvent, ...)
        end
    end)
end

function CrossGambling:UnregisterEvent(event)
    events:Unregister(event)
end

function CrossGambling:IsEventRegistered(event)
    return events:IsRegistered(event)
end

