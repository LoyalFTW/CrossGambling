local CG = CrossGambling

CG.Chat = {}
local Chat = CG.Chat

local function RegisterPrefix()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix("CrossGambling")
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix("CrossGambling")
    end
end
RegisterPrefix()

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    RegisterPrefix()
end)

function Chat:SendAddon(method, msg)
    RegisterPrefix()
    local result
    if ChatThrottleLib then
        result = ChatThrottleLib:SendAddonMessage("BULK", "CrossGambling", msg, method)
    elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
        result = C_ChatInfo.SendAddonMessage("CrossGambling", msg, method)
    end
    return result
end

function Chat:Send(message)
    local cg = CrossGambling
    if cg.game.chatframeOption == false and cg.game.host == true then
        local playerName = UnitName("player")
        local playerClass = select(2, UnitClass("player"))
        local msg = format("CHAT_MSG:%s:%s:%s", playerName, playerClass, message)

                local tf = cg.ChatTextField
        if tf then
            local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass]
            local nameStr = color and ("|c" .. color.colorStr .. playerName .. "|r") or playerName
            cg.recentChatMsgs = cg.recentChatMsgs or {}
            cg.recentChatMsgs[playerName .. ":" .. message] = GetTime()
            tf:AddMessage(nameStr .. ": " .. message)
            if tf.ScrollToBottom then tf:ScrollToBottom() end
        end

        cg:SendAddonMsg(msg)
    else
        SendChatMessage(message, cg.game.chatMethod)
    end
end

function CG:Announce(message)
    Chat:Send(message)
end

function CG:SendAddonMsg(msg)
    local method = self.game.chatMethod or "PARTY"
            Chat:SendAddon(method, msg)
end

function CG:SendMsg(event, arg1)
    local msg = event
    if arg1 then msg = msg .. ":" .. tostring(arg1) end
    self:SendAddonMsg(msg)
end

function CG:RegisterChatEvents()
    local method = self.game.chatMethod
    if method == "PARTY" then
        self:RegisterEvent("CHAT_MSG_PARTY", "handleChatMsg")
        self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "handleChatMsg")
    elseif method == "RAID" then
        self:RegisterEvent("CHAT_MSG_RAID", "handleChatMsg")
        self:RegisterEvent("CHAT_MSG_RAID_LEADER", "handleChatMsg")
        self:RegisterEvent("CHAT_MSG_INSTANCE_CHAT", "handleChatMsg")
    else
        self:RegisterEvent("CHAT_MSG_GUILD", "handleChatMsg")
    end
end

function CG:UnRegisterChatEvents()
    self:UnregisterEvent("CHAT_MSG_PARTY")
    self:UnregisterEvent("CHAT_MSG_PARTY_LEADER")
    self:UnregisterEvent("CHAT_MSG_RAID")
    self:UnregisterEvent("CHAT_MSG_RAID_LEADER")
    self:UnregisterEvent("CHAT_MSG_INSTANCE_CHAT")
    self:UnregisterEvent("CHAT_MSG_GUILD")
end

local CGCallFrame = CreateFrame("Frame")
CGCallFrame:RegisterEvent("CHAT_MSG_ADDON")
CGCallFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= "CrossGambling" then return end
    local event_type, rest = strsplit(":", msg, 2)
    if event_type == "CHAT_MSG" then
        local name, class, message = strmatch(rest or "", "^([^:]+):([^:]+):(.+)$")
        if name and class and message then
                        local dedupKey = name .. ":" .. message
            local now = GetTime()
            local recent = CrossGambling and CrossGambling.recentChatMsgs
            if recent and recent[dedupKey] and (now - recent[dedupKey]) < 2.0 then
                return             end

            local tf = CrossGambling and CrossGambling.ChatTextField
            if tf then
                local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
                local nameStr = color and ("|c" .. color.colorStr .. name .. "|r") or name
                tf:AddMessage(nameStr .. ": " .. message)
                if tf.ScrollToBottom then tf:ScrollToBottom() end
            end
        end
    elseif CGCall and CGCall[event_type] then
        local arg1, arg2 = strsplit(":", rest or "", 2)
        CGCall[event_type](arg1, arg2)
    end
end)
