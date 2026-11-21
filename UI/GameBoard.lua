local _, ns = ...
local L = ns.L
local CrossGambling = ns.CG

local GameBoard = {
    adapters = {},
    serial = 0,
    refreshQueued = false,
}

local Controller = {}
Controller.__index = Controller

local COLUMN_TEXT = L["GameBoard_PLAYERSTATUS"]

local ROW_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local ROLE_COLORS = {
    normal = { 0.08, 0.08, 0.10, 0.82 },
    waiting = { 0.16, 0.16, 0.18, 0.72 },
    high = { 0.36, 0.27, 0.04, 0.92 },
    low = { 0.34, 0.06, 0.06, 0.92 },
    tie = { 0.34, 0.18, 0.04, 0.92 },
    active = { 0.05, 0.22, 0.38, 0.92 },
    holder = { 0.46, 0.16, 0.02, 0.94 },
    winner = { 0.08, 0.34, 0.12, 0.94 },
    out = { 0.08, 0.08, 0.08, 0.52 },
    over = { 0.06, 0.24, 0.38, 0.90 },
    under = { 0.30, 0.09, 0.24, 0.90 },
}

local function countSet(values)
    local count = 0
    for _ in pairs(values or {}) do
        count = count + 1
    end
    return count
end

local function classColorName(name)
    local _, class = UnitClass(name)
    local color = class and RAID_CLASS_COLORS[class]
    if color and color.colorStr then
        return "|c" .. color.colorStr .. name .. "|r"
    end
    return "|cffffffff" .. name .. "|r"
end

local function alphabetical(a, b)
    return strlower(a.name) < strlower(b.name)
end

local function ranked(a, b)
    if a.group ~= b.group then
        return a.group < b.group
    end
    local aRoll = tonumber(a.roll)
    local bRoll = tonumber(b.roll)
    if aRoll and bRoll and aRoll ~= bRoll then
        return aRoll > bRoll
    end
    if aRoll and not bRoll then
        return true
    end
    if bRoll and not aRoll then
        return false
    end
    return alphabetical(a, b)
end

local function baseView(addon)
    local game = addon.game or {}
    local rows = {}
    local rolled = 0
    for i, player in ipairs(game.players or {}) do
        rows[i] = {
            name = player.name,
            roll = player.roll,
            index = i,
            group = player.roll == nil and 2 or 1,
            role = player.roll == nil and "waiting" or "normal",
            badge = player.roll == nil and L["GameBoard_BadgeWaiting"] or tostring(player.roll),
            rank = "",
        }
        if player.roll ~= nil then
            rolled = rolled + 1
        end
    end

    local state = game.state or "START"
    local status
    if state == "REGISTER" then
        status = string.format(L["GameBoard_RegistrationJoined"], #rows)
        table.sort(rows, alphabetical)
    elseif state == "ROLL" then
        status = string.format(L["GameBoard_RollingReady"], rolled, #rows)
        table.sort(rows, ranked)
    elseif state == "DOUBLE_OR_NOTHING_OFFER" then
        status = L["GameBoard_DoubleOrNothingAwaitingAcceptance"]
    elseif state == "DOUBLE_OR_NOTHING_ROLL" then
        local duel = game.doubleOrNothing
        status = duel and string.format(L["GameBoard_DoubleOrNothingSTurn1"], duel.turn or "?", duel.max or "?") or L["Options_DoubleOrNothing2"]
    else
        status = #rows > 0 and string.format(L["GameBoard_GameCompletePlayers"], #rows) or L["GameBoard_ReadyForANewGame"]
    end

    return {
        title = addon:GetModeDisplayName(game.mode) or L["Common_Game"],
        status = status,
        rows = rows,
        rolled = rolled,
        total = #rows,
    }
end

local function markNumericExtremes(view, eligible)
    local low
    local high
    local lowCount = 0
    local highCount = 0
    local numericCount = 0
    for _, row in ipairs(view.rows) do
        local value = tonumber(row.roll)
        if value and (not eligible or eligible[row.name]) then
            numericCount = numericCount + 1
            if low == nil or value < low then
                low = value
                lowCount = 1
            elseif value == low then
                lowCount = lowCount + 1
            end
            if high == nil or value > high then
                high = value
                highCount = 1
            elseif value == high then
                highCount = highCount + 1
            end
        end
    end
    if numericCount < 2 or low == high then
        return
    end
    for _, row in ipairs(view.rows) do
        local value = tonumber(row.roll)
        if value and (not eligible or eligible[row.name]) then
            if value == high then
                row.role = highCount > 1 and "tie" or "high"
                row.badge = (highCount > 1 and L["GameBoard_HIGHTIE"] or L["GameBoard_HIGH"]) .. tostring(value)
            elseif value == low then
                row.role = lowCount > 1 and "tie" or "low"
                row.badge = (lowCount > 1 and L["GameBoard_LOWTIE"] or L["GameBoard_LOW"]) .. tostring(value)
            end
        end
    end
end

function GameBoard:RegisterModeAdapter(name, adapter)
    self.adapters[name] = adapter
end

function GameBoard:SetPlayerClickHandler(handler)
    self.playerClickHandler = handler
end

GameBoard:RegisterModeAdapter("Classic", function(addon, view)
    local game = addon.game
    local highlow = game.highlow
    local eligible = highlow and highlow.pending or nil
    if game.state == "ROLL" and not highlow then
        markNumericExtremes(view)
        return
    end
    if game.state == "ROLL" and highlow then
        local needed = countSet(eligible)
        local ready = 0
        for _, row in ipairs(view.rows) do
            if eligible[row.name] then
                row.group = row.roll == nil and 2 or 1
                if row.roll ~= nil then ready = ready + 1 end
            else
                row.group = 3
                row.role = "out"
                row.badge = L["GameBoard_BadgeLocked"]
            end
        end
        local phase = highlow.stage == "high" and L["GameBoard_HighTieBreak"] or highlow.stage == "low" and L["GameBoard_LowTieBreak"] or L["GameBoard_Rolling"]
        view.status = string.format(L["GameBoard_Ready"], phase, ready, needed)
        table.sort(view.rows, ranked)
        markNumericExtremes(view, eligible)
        for _, row in ipairs(view.rows) do
            if highlow.winners and #highlow.winners == 1 and row.name == highlow.winners[1] then
                row.role = "winner"
                row.badge = L["GameBoard_WINNER"] .. tostring(row.roll or "")
            elseif highlow.losers and #highlow.losers == 1 and row.name == highlow.losers[1] then
                row.role = "low"
                row.badge = L["GameBoard_LOSER"] .. tostring(row.roll or "")
            end
        end
        if highlow.winners and #highlow.winners == 1 and highlow.losers and #highlow.losers == 1 then
            view.completedStatus = highlow.winners[1] .. L["GameBoard_Wins"] .. highlow.losers[1] .. L["GameBoard_Loses"]
        end
    end
end)

GameBoard:RegisterModeAdapter("BigTwo", GameBoard.adapters.Classic)

GameBoard:RegisterModeAdapter("1v1DeathRoll", function(addon, view)
    local game = addon.game
    local deathroll = game.deathroll
    local current = deathroll and game.players[deathroll.turn]
    if game.state == "ROLL" and deathroll then
        view.status = deathroll.winner and L["GameBoard_DeathRollComplete"] or string.format(L["GameBoard_DeathRollSTurnRoll1"], current and current.name or "?", deathroll.max or "?")
        for _, row in ipairs(view.rows) do
            if row.name == deathroll.winner then
                row.group = 1
                row.role = "winner"
                row.badge = L["GameBoard_BadgeWinner"]
            elseif row.name == deathroll.loser then
                row.group = 2
                row.role = "low"
                row.badge = L["GameBoard_LOSER1"]
            else
                row.group = current and row.name == current.name and 1 or 2
                row.role = current and row.name == current.name and "active" or "normal"
                row.badge = current and row.name == current.name and L["GameBoard_BadgeTurn"] or (row.roll and L["GameBoard_LAST"] .. tostring(row.roll) or L["GameBoard_BadgeReady"])
            end
        end
        table.sort(view.rows, ranked)
        if deathroll.winner then
            view.completedStatus = deathroll.winner .. L["GameBoard_Wins"] .. deathroll.loser .. L["GameBoard_Loses"]
        end
    end
end)

GameBoard:RegisterModeAdapter("Elimination", function(addon, view)
    local game = addon.game
    local elimination = game.elimination
    if game.state ~= "ROLL" then return end
    if not elimination then
        for _, row in ipairs(view.rows) do
            if row.roll == "Loser" then
                row.group = 4
                row.role = "out"
                row.badge = L["GameBoard_BadgeOut"]
            end
        end
        table.sort(view.rows, ranked)
        markNumericExtremes(view)
        return
    end
    local alive = countSet(elimination.alive)
    if elimination.finale then
        local current = elimination.finaleOrder[elimination.finaleTurnIndex]
        view.status = string.format(L["GameBoard_FinalDuelSTurnRoll1"], current or "?", elimination.finaleMax or "?")
    else
        local ready = 0
        local needed = countSet(elimination.pending)
        for _, row in ipairs(view.rows) do
            if elimination.pending and elimination.pending[row.name] and row.roll ~= nil then ready = ready + 1 end
        end
        view.status = string.format(L["GameBoard_RoundAliveReady"], elimination.round or 1, alive, ready, needed)
    end
    local outByName = {}
    for i, entry in ipairs(elimination.eliminationOrder or {}) do
        outByName[entry.name] = { order = i, round = entry.round }
    end
    local current = elimination.finale and elimination.finaleOrder[elimination.finaleTurnIndex]
    for _, row in ipairs(view.rows) do
        local out = outByName[row.name]
        if row.name == elimination.winner then
            row.group = 1
            row.role = "winner"
            row.badge = L["GameBoard_BadgeWinner"]
        elseif out then
            row.group = 4
            row.outOrder = out.order
            row.role = "out"
            row.badge = L["GameBoard_OUTR"] .. tostring(out.round)
        elseif current == row.name then
            row.group = 1
            row.role = "active"
            row.badge = L["GameBoard_BadgeTurn"]
        elseif elimination.pending and elimination.pending[row.name] then
            row.group = row.roll == nil and 3 or 2
            row.role = row.roll == nil and "waiting" or "normal"
            row.badge = row.roll == nil and L["GameBoard_BadgeWaiting"] or tostring(row.roll)
        else
            row.group = 2
            row.badge = row.roll and tostring(row.roll) or L["GameBoard_BadgeAlive"]
        end
    end
    table.sort(view.rows, function(a, b)
        if a.group ~= b.group then return a.group < b.group end
        if a.group == 4 and a.outOrder ~= b.outOrder then return a.outOrder > b.outOrder end
        return ranked(a, b)
    end)
    if not elimination.finale then markNumericExtremes(view, elimination.pending) end
    if elimination.winner then view.completedStatus = elimination.winner .. L["GameBoard_WinsElimination"] end
end)

GameBoard:RegisterModeAdapter("HotPotato", function(addon, view)
    local game = addon.game
    local hotpotato = game.hotpotato
    if game.state ~= "ROLL" then return end
    if not hotpotato then
        markNumericExtremes(view)
        return
    end
    local ready = 0
    local needed = countSet(hotpotato.pending)
    for _, row in ipairs(view.rows) do
        if hotpotato.pending and hotpotato.pending[row.name] and row.roll ~= nil then ready = ready + 1 end
        if row.name == hotpotato.holder then
            row.role = "holder"
            row.badge = L["GameBoard_BadgePotato"]
        end
    end
    view.status = hotpotato.exploded and L["GameBoard_BOOMRoundComplete"] or string.format(L["GameBoard_RoundFuseBurningReady"], hotpotato.round or 1, ready, needed)
    table.sort(view.rows, ranked)
    markNumericExtremes(view, hotpotato.pending)
    for _, row in ipairs(view.rows) do
        if row.name == hotpotato.holder then
            row.role = hotpotato.exploded and "low" or "holder"
            row.badge = hotpotato.exploded and L["GameBoard_BOOM"] or L["GameBoard_BadgePotato"]
        end
    end
    if hotpotato.exploded then view.completedStatus = L["GameBoard_BOOM2"] .. tostring(hotpotato.holder) .. L["GameBoard_Loses"] end
end)

GameBoard:RegisterModeAdapter("OverUnder", function(addon, view)
    local game = addon.game
    local overunder = game.overunder
    local picks = overunder and overunder.picks or {}
    local picked = 0
    local eligible = 0
    for _, row in ipairs(view.rows) do
        if row.name ~= game.hostName then
            eligible = eligible + 1
            local stored = picks[row.name]
            local recorded = row.roll and strlower(tostring(row.roll)) or nil
            if stored == "over" or stored == "under" or recorded == "over" or recorded == "under" then
                picked = picked + 1
            end
        end
    end
    if overunder and overunder.resolved then
        view.status = string.format(L["GameBoard_ResultRoundComplete"], overunder.result or "?")
        view.completedStatus = L["GameBoard_Result"] .. tostring(overunder.result or "?")
    elseif game.state == "ROLL" then
        view.status = string.format(L["GameBoard_PickOverOrUnder50Picked"], picked, eligible)
    end
    for _, row in ipairs(view.rows) do
        local pick = picks[row.name] or (row.roll and strlower(tostring(row.roll)))
        if row.name == game.hostName then
            row.group = 1
            row.role = "active"
            row.badge = L["GameBoard_BadgeHouse"]
        elseif pick == "over" then
            row.group = 2
            row.role = "over"
            row.badge = L["GameBoard_BadgeOver"]
        elseif pick == "under" then
            row.group = 3
            row.role = "under"
            row.badge = L["GameBoard_BadgeUnder"]
        else
            row.group = 4
            row.role = "waiting"
            row.badge = L["GameBoard_BadgeWaiting"]
        end
        if overunder and overunder.outcomes and overunder.outcomes[row.name] ~= nil then
            row.role = overunder.outcomes[row.name] and "winner" or "low"
            row.badge = overunder.outcomes[row.name] and L["GameBoard_BadgeWon"] or L["GameBoard_BadgeLost"]
        end
    end
    table.sort(view.rows, ranked)
end)

GameBoard:RegisterModeAdapter("Raffle", function(addon, view)
    local game = addon.game
    if game.state == "ROLL" then
        view.status = string.format(L["GameBoard_RaffleDrawRolls1"], game.hostName or L["GameBoard_Host"], #view.rows)
    end
    for _, row in ipairs(view.rows) do
        row.group = row.index
        row.rank = "#" .. row.index
        if row.roll == "Winner" then
            row.role = "winner"
            row.badge = L["GameBoard_BadgeWinner"]
            view.completedStatus = row.name .. L["GameBoard_WinsTicket"] .. row.index
        else
            row.role = "normal"
            row.badge = L["GameBoard_TICKET"] .. row.index
        end
    end
    table.sort(view.rows, function(a, b) return a.index < b.index end)
end)

local function applyDoubleOrNothing(addon, view)
    local game = addon.game
    local duel = game.doubleOrNothing
    if not duel then return end
    local accepted = duel.accepted or {}
    local acceptedCount = 0
    for _, name in ipairs({ duel.loser, duel.winner }) do
        local key = name and addon:NormalizePlayerName(name)
        if key and accepted[key] then acceptedCount = acceptedCount + 1 end
    end
    if game.state == "DOUBLE_OR_NOTHING_OFFER" then
        view.status = string.format(L["GameBoard_DoubleOrNothing2Accepted"], acceptedCount)
    end
    for _, row in ipairs(view.rows) do
        if row.name == duel.turn then
            row.group = 1
            row.role = "active"
            row.badge = L["GameBoard_BadgeTurn"]
        elseif row.name == duel.loser or row.name == duel.winner then
            row.group = 2
            row.role = "normal"
            local key = addon:NormalizePlayerName(row.name)
            row.badge = game.state == "DOUBLE_OR_NOTHING_OFFER" and (accepted[key] and L["GameBoard_BadgeAccepted"] or L["GameBoard_BadgeDeciding"]) or (row.roll and L["GameBoard_LAST"] .. tostring(row.roll) or L["GameBoard_BadgeReady"])
        else
            row.group = 3
            row.role = "out"
            row.badge = L["GameBoard_BadgeSpectating"]
        end
    end
    table.sort(view.rows, ranked)
end

local function applyCompletedDoubleOrNothing(addon, view)
    local duel = addon.game and addon.game.completedDoubleOrNothing
    if not duel then return end
    local finalAmount = tonumber(duel.finalAmount) or 0
    view.completedStatus = finalAmount == 0 and L["GameBoard_DoubleOrNothingDebtCleared"] or L["GameBoard_DoubleOrNothingFinalDebt"] .. addon:addCommas(finalAmount) .. L["Common_GoldSuffix"]
    for _, row in ipairs(view.rows) do
        if row.name == duel.winner then
            row.group = 1
            row.role = finalAmount > 0 and "winner" or "normal"
            row.badge = finalAmount > 0 and L["GameBoard_BadgeWinner"] or L["GameBoard_BadgeCleared"]
        elseif row.name == duel.loser then
            row.group = 2
            row.role = finalAmount > 0 and "low" or "normal"
            row.badge = finalAmount > 0 and L["GameBoard_BadgeOwes"] or L["GameBoard_BadgeCleared"]
        else
            row.group = 3
            row.role = "out"
            row.badge = L["GameBoard_BadgeSpectating"]
        end
    end
    table.sort(view.rows, ranked)
end

function GameBoard:BuildView(addon)
    local view = baseView(addon)
    local game = addon.game or {}
    local adapter = self.adapters[game.mode]
    if adapter then
        adapter(addon, view)
    elseif game.state == "ROLL" then
        markNumericExtremes(view)
    end
    if game.state == "DOUBLE_OR_NOTHING_OFFER" or game.state == "DOUBLE_OR_NOTHING_ROLL" then
        applyDoubleOrNothing(addon, view)
    elseif game.completedDoubleOrNothing then
        applyCompletedDoubleOrNothing(addon, view)
    end
    local visibleRank = 0
    local lastRankedValue
    local lastRank
    for _, row in ipairs(view.rows) do
        if row.rank == "" and row.group < 3 and tonumber(row.roll) then
            visibleRank = visibleRank + 1
            local value = tonumber(row.roll)
            if value == lastRankedValue then
                row.rank = tostring(lastRank)
            else
                lastRank = visibleRank
                lastRankedValue = value
                row.rank = tostring(lastRank)
            end
        end
    end
    return view
end

function Controller:AcquireRow(index)
    local row = self.rows[index]
    if row then return row end
    row = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    row:SetSize(self.width - 30, self.rowHeight)
    row:EnableMouse(true)
    row:SetBackdrop(ROW_BACKDROP)
    row:SetBackdropBorderColor(0, 0, 0, 0.85)
    if self.options.styleRow then self.options.styleRow(row) end

    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.rank:SetPoint("LEFT", row, "LEFT", 7, 0)
    row.rank:SetWidth(24)
    row.rank:SetJustifyH("CENTER")

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("LEFT", row.rank, "RIGHT", 6, 0)
    row.name:SetWidth(self.width - 142)
    row.name:SetJustifyH("LEFT")

    row.badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.badge:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    row.badge:SetWidth(92)
    row.badge:SetJustifyH("RIGHT")

    row.flash = row:CreateTexture(nil, "OVERLAY")
    row.flash:SetAllPoints()
    row.flash:SetColorTexture(1, 0.82, 0.20, 0.28)
    row.flash:Hide()
    row.hover = row:CreateTexture(nil, "HIGHLIGHT")
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(1, 1, 1, 0.10)
    row.hover:Hide()
    row:SetScript("OnEnter", function(frame)
        frame.hover:Show()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(frame.playerName or L["GameBoard_Player"], 1, 1, 1)
        GameTooltip:AddLine(L["GameBoard_ClickToOpenPlayerCard"], 0.65, 0.85, 1)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(frame)
        frame.hover:Hide()
        GameTooltip:Hide()
    end)
    row:SetScript("OnMouseUp", function(frame, button)
        if button == "LeftButton" and GameBoard.playerClickHandler and frame.playerName then
            GameBoard.playerClickHandler(self.addon, frame.playerName, frame)
        end
    end)
    row:SetScript("OnUpdate", function(frame, elapsed)
        if not frame.flashRemaining then return end
        frame.flashRemaining = frame.flashRemaining - elapsed
        if frame.flashRemaining <= 0 then
            frame.flashRemaining = nil
            frame.flash:Hide()
        else
            frame.flash:SetAlpha(frame.flashRemaining / 0.65)
        end
    end)

    self.rows[index] = row
    return row
end

function Controller:AcquirePayoutRow(index)
    local row = self.payoutRows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    row:SetWidth(self.width - 38)
    row:SetBackdrop(ROW_BACKDROP)
    row:SetBackdropColor(0.13, 0.11, 0.06, 0.92)
    row:SetBackdropBorderColor(0, 0, 0, 0.85)

    row.names = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.names:SetPoint("TOPLEFT", 7, -5)
    row.names:SetPoint("TOPRIGHT", -7, -5)
    row.names:SetJustifyH("LEFT")
    row.names:SetWordWrap(true)

    row.amounts = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.amounts:SetPoint("TOPLEFT", row.names, "BOTTOMLEFT", 0, -4)
    row.amounts:SetJustifyH("LEFT")

    row.ledgerButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.ledgerButton:SetSize(84, 20)
    row.ledgerButton:SetPoint("BOTTOMRIGHT", -5, 4)
    row.ledgerButton:SetText(L["GameBoard_ViewDebt"])
    row.ledgerButton:SetScript("OnClick", function()
        if row.ledgerId then self.addon:ShowPaymentLedger(nil, row.ledgerId) end
    end)

    self.payoutRows[index] = row
    return row
end

function Controller:Refresh()
    local game = self.addon.game or {}
    local view
    if game.state == "START" and #(game.players or {}) == 0 and GameBoard.completedView then
        view = GameBoard.completedView
    else
        view = GameBoard:BuildView(self.addon)
    end
    self.header:SetText(L["GameBoard_GameBoard"] .. view.title)
    self.status:SetText(view.status)
    local payouts = view.payouts or {}
    local hasPayouts = #payouts > 0
    self.columns:SetText(hasPayouts and L["GameBoard_BadgePayouts"] or COLUMN_TEXT)
    self.empty:SetShown(#view.rows == 0 and not hasPayouts and not view.completed)
    self.rollColumns:SetShown(hasPayouts and #view.rows > 0)
    for _, row in ipairs(self.payoutRows) do row:Hide() end
    for _, frame in ipairs(self.rows) do frame:Hide() end

    local offset = 0
    for i, payout in ipairs(payouts) do
        local row = self:AcquirePayoutRow(i)
        row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -offset)
        local recipient = payout.winnerAmount > 0 and payout.winner or L["GameBoard_TheGuild"]
        row.names:SetText(payout.loser .. L["Common_Owes"] .. recipient)
        local amounts = L["GameBoard_Winner"] .. self.addon:addCommas(payout.winnerAmount) .. L["Common_GoldSuffix"]
        if payout.guildAmount > 0 then
            amounts = amounts .. L["GameBoard_Guild"] .. self.addon:addCommas(payout.guildAmount) .. L["Common_GoldSuffix"]
        end
        row.amounts:SetText(amounts)
        row.ledgerId = payout.ledgerId
        row.ledgerButton:SetShown(row.ledgerId ~= nil)
        local height = math.max(16, row.names:GetStringHeight()) + (row.ledgerId and 45 or 25)
        row:SetHeight(height)
        row:Show()
        offset = offset + height + 2
    end
    if self.rollColumns:IsShown() then
        self.rollColumns:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -offset - 5)
        offset = offset + 24
    end

    for i, data in ipairs(view.rows) do
        local frame = self:AcquireRow(i)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -offset - (i - 1) * self.rowHeight)
        local color = ROLE_COLORS[data.role] or ROLE_COLORS.normal
        frame:SetBackdropColor(color[1], color[2], color[3], color[4])
        frame.rank:SetText(data.rank)
        frame.name:SetText(classColorName(data.name))
        frame.playerName = data.name
        frame.badge:SetText(data.badge or "")
        frame:SetAlpha(data.role == "out" and 0.62 or 1)
        frame:Show()

        local prior = self.previousRolls[data.name]
        if data.roll ~= nil and self.knownPlayers[data.name] and tostring(prior) ~= tostring(data.roll) then
            frame.flashRemaining = 0.65
            frame.flash:SetAlpha(1)
            frame.flash:Show()
        end
        self.knownPlayers[data.name] = true
        self.previousRolls[data.name] = data.roll
    end

    local present = {}
    for _, data in ipairs(view.rows) do present[data.name] = true end
    for name in pairs(self.previousRolls) do
        if not present[name] then self.previousRolls[name] = nil end
    end
    for name in pairs(self.knownPlayers) do
        if not present[name] then self.knownPlayers[name] = nil end
    end
    self.content:SetHeight(math.max(1, offset + #view.rows * self.rowHeight))
    if self.completedView ~= (view.completed and view or nil) then
        self.completedView = view.completed and view or nil
        self.scroll:SetVerticalScroll(0)
    end
end

function GameBoard:Create(addon, parent, options)
    self.serial = self.serial + 1
    options = options or {}
    local controller = setmetatable({
        addon = addon,
        parent = parent,
        options = options,
        width = options.width or 300,
        height = options.height or 210,
        rowHeight = options.rowHeight or 27,
        rows = {},
        payoutRows = {},
        previousRolls = {},
        knownPlayers = {},
    }, Controller)

    parent:SetSize(controller.width, controller.height)
    controller.header = options.header
    controller.header:SetText(L["GameBoard_GameBoard2"])

    controller.status = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    controller.status:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -8)
    controller.status:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -8)
    controller.status:SetJustifyH("LEFT")

    controller.columns = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    controller.columns:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -28)
    controller.columns:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -25, -28)
    controller.columns:SetJustifyH("LEFT")
    controller.columns:SetText(COLUMN_TEXT)

    controller.scroll = CreateFrame("ScrollFrame", "CrossGamblingGameBoardScroll" .. self.serial, parent, "UIPanelScrollFrameTemplate")
    controller.scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -45)
    controller.scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -27, 9)
    if options.styleScrollBar then options.styleScrollBar(controller.scroll) end
    controller.scroll:EnableMouseWheel(true)

    controller.content = CreateFrame("Frame", nil, controller.scroll)
    controller.content:SetSize(controller.width - 30, 1)
    controller.scroll:SetScrollChild(controller.content)
    controller.rollColumns = controller.content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    controller.rollColumns:SetText(COLUMN_TEXT)
    controller.scroll:SetScript("OnMouseWheel", function(frame, delta)
        local maximum = math.max(0, controller.content:GetHeight() - frame:GetHeight())
        frame:SetVerticalScroll(math.max(0, math.min(frame:GetVerticalScroll() - delta * controller.rowHeight, maximum)))
    end)

    controller.empty = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    controller.empty:SetPoint("CENTER", controller.scroll, "CENTER", 0, 0)
    controller.empty:SetText(L["GameBoard_PlayersWillAppearHereWhenTheyJoin"])

    self.active = controller
    addon.gameBoard = controller
    controller:Refresh()
    return controller
end

function GameBoard:QueueRefresh()
    if self.refreshQueued then return end
    self.refreshQueued = true
    C_Timer.After(0, function()
        GameBoard.refreshQueued = false
        if GameBoard.active then GameBoard.active:Refresh() end
    end)
end

function GameBoard:CaptureCompleted(addon)
    local view = self:BuildView(addon)
    view.title = view.title .. L["GameBoard_Final"]
    view.completed = true
    view.payouts = addon.game.result
    view.status = view.completedStatus or (view.payouts and #view.payouts == 0 and L["GameBoard_NoGoldOwed"]) or L["GameBoard_RoundComplete"]
    self.completedView = view
end

function GameBoard:ClearCompleted()
    self.completedView = nil
end

CrossGamblingGameBoard = GameBoard

function CrossGambling:QueueGameBoardRefresh()
    GameBoard:QueueRefresh()
end

function CrossGambling:QueuePlayerListRefresh()
    GameBoard:QueueRefresh()
end

function CrossGambling:UpdatePlayerList()
    if GameBoard.active then GameBoard.active:Refresh() end
end

function CrossGambling:AddPlayer()
    GameBoard:QueueRefresh()
end

function CrossGambling:RemovePlayer()
    GameBoard:QueueRefresh()
end

function CrossGambling:CaptureCompletedGameBoard()
    GameBoard:CaptureCompleted(self)
end

function CrossGambling:ClearCompletedGameBoard()
    GameBoard:ClearCompleted()
end
