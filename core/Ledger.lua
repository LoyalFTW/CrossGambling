local function goldAmount(value)
    local amount = tonumber(value)
    if not amount or amount ~= amount or amount == math.huge or amount == -math.huge or amount < 0 or amount ~= math.floor(amount) or amount > 2000000000 then
        return nil
    end
    return amount
end

function CrossGambling:EnsurePaymentLedger()
    local global = self.db.global
    if type(global.paymentLedger) ~= "table" then
        global.paymentLedger = { version = 1, nextId = 1, entries = {} }
    end
    local ledger = global.paymentLedger
    ledger.entries = ledger.entries or {}
    ledger.nextId = math.max(1, tonumber(ledger.nextId) or 1)
    return ledger
end

function CrossGambling:GetLedgerEntry(id)
    for _, entry in ipairs(self:EnsurePaymentLedger().entries) do
        if entry.id == id then
            return entry
        end
    end
end

function CrossGambling:GetLedgerBalance(entry, recipient)
    if recipient ~= "winner" and recipient ~= "guild" then
        return 0, 0, 0
    end
    local due = recipient == "winner" and entry.winnerAmount or entry.guildAmount
    local paid = 0
    for _, payment in ipairs(entry.payments) do
        if payment.recipient == recipient and not payment.reversedAt then
            paid = paid + payment.amount
        end
    end
    return math.max(0, due - paid), paid, due
end

function CrossGambling:GetLedgerStatus(entry)
    local winnerRemaining, winnerPaid = self:GetLedgerBalance(entry, "winner")
    local guildRemaining, guildPaid = self:GetLedgerBalance(entry, "guild")
    if winnerRemaining + guildRemaining == 0 then
        return "Paid"
    end
    return winnerPaid + guildPaid > 0 and "Partial" or "Unpaid"
end

function CrossGambling:RecordLedgerDebt(loser, winner, amount, winnerAmount, mode)
    local game = self.game
    amount, winnerAmount = goldAmount(amount), goldAmount(winnerAmount)
    if not game or not game.host or game.botTest or not amount or not winnerAmount or amount == 0 or winnerAmount > amount then
        return nil
    end
    local ledger = self:EnsurePaymentLedger()
    local entry = {
        id = ledger.nextId,
        timestamp = time(),
        sessionId = game.sessionId,
        host = game.hostName or game.PlayerName,
        realm = GetRealmName(),
        guild = GetGuildInfo("player") or "Guild",
        profile = self:GetActiveStatProfile(),
        mode = mode or game.mode,
        loser = loser,
        winner = winner,
        amount = amount,
        winnerAmount = winnerAmount,
        guildAmount = amount - winnerAmount,
        payments = {},
    }
    ledger.nextId = ledger.nextId + 1
    ledger.entries[#ledger.entries + 1] = entry
    self:RefreshPaymentLedger()
    return entry.id
end

function CrossGambling:RecordLedgerPayment(id, recipient, value)
    local entry = self:GetLedgerEntry(id)
    local amount = goldAmount(value)
    if not entry or (recipient ~= "winner" and recipient ~= "guild") then
        return false, "Select a debt and a recipient first."
    end
    if not amount or amount == 0 then
        return false, "Enter a positive whole-gold amount."
    end
    local remaining = self:GetLedgerBalance(entry, recipient)
    if amount > remaining then
        return false, "Payment exceeds the remaining " .. self:addCommas(remaining) .. "g balance."
    end
    entry.payments[#entry.payments + 1] = {
        recipient = recipient,
        amount = amount,
        timestamp = time(),
        recordedBy = self.game.PlayerName,
    }
    self:AddAuditEntry({ action = "payment", ledgerId = id, player = entry.loser,
        recipient = recipient == "winner" and entry.winner or entry.guild,
        amount = amount, profile = entry.profile })
    self:RefreshPaymentLedger()
    return true, "Recorded " .. self:addCommas(amount) .. "g paid."
end

function CrossGambling:GetLastLedgerPayment(entry)
    for i = #entry.payments, 1, -1 do
        if not entry.payments[i].reversedAt then
            return entry.payments[i], i
        end
    end
end

function CrossGambling:UndoLedgerPayment(id, expectedIndex)
    local entry = self:GetLedgerEntry(id)
    if not entry then
        return false, "Debt no longer exists."
    end
    local payment, index = self:GetLastLedgerPayment(entry)
    if not payment or (expectedIndex and index ~= expectedIndex) then
        return false, "Payment changed. Select the debt again."
    end
    payment.reversedAt = time()
    payment.reversedBy = self.game.PlayerName
    self:AddAuditEntry({ action = "paymentUndo", ledgerId = id, player = entry.loser,
        recipient = payment.recipient == "winner" and entry.winner or entry.guild,
        amount = payment.amount, profile = entry.profile })
    self:RefreshPaymentLedger()
    return true, "Payment undone; the balance has been restored."
end

function CrossGambling:GetFilteredLedgerEntries(search, filter, playerName)
    local entries, summary = {}, { outstanding = 0, winner = 0, guild = 0, count = 0 }
    local ledger = self:EnsurePaymentLedger()
    local playerKey = self:NormalizePlayerName(playerName, true)
    for i = #ledger.entries, 1, -1 do
        local entry = ledger.entries[i]
        local status = self:GetLedgerStatus(entry)
        local searchable = table.concat({ tostring(entry.id), entry.loser, entry.winner, entry.guild,
            entry.mode or "", entry.profile or "", entry.host or "", entry.realm or "", status }, " ")
        local involved = not playerKey or self:NormalizePlayerName(entry.loser, true) == playerKey or self:NormalizePlayerName(entry.winner, true) == playerKey
        if involved and self:AuditEntryMatches(entry, searchable, search) then
            local winner = self:GetLedgerBalance(entry, "winner")
            local guild = self:GetLedgerBalance(entry, "guild")
            summary.winner = summary.winner + winner
            summary.guild = summary.guild + guild
            summary.outstanding = summary.outstanding + winner + guild
            if winner + guild > 0 then summary.count = summary.count + 1 end
            if filter == "All" or (filter == "Paid" and status == "Paid") or ((not filter or filter == "Outstanding") and status ~= "Paid") then
                entries[#entries + 1] = entry
            end
        end
    end
    return entries, summary
end

function CrossGambling:GetPlayerLedgerHistory(playerName)
    local history = {}
    local playerKey = self:NormalizePlayerName(playerName, true)
    if not playerKey then return history end
    for _, entry in ipairs(self:EnsurePaymentLedger().entries) do
        local isPayer = self:NormalizePlayerName(entry.loser, true) == playerKey
        local isWinner = self:NormalizePlayerName(entry.winner, true) == playerKey
        if isPayer or isWinner then
            for index, payment in ipairs(entry.payments) do
                if isPayer or payment.recipient == "winner" then
                    history[#history + 1] = {
                        ledgerId = entry.id,
                        paymentIndex = index,
                        payer = entry.loser,
                        recipient = payment.recipient == "winner" and entry.winner or entry.guild,
                        amount = payment.amount,
                        timestamp = payment.timestamp,
                        reversedAt = payment.reversedAt,
                        eventTime = tonumber(payment.reversedAt or payment.timestamp) or 0,
                        mode = entry.mode,
                        profile = entry.profile,
                    }
                end
            end
        end
    end
    table.sort(history, function(a, b)
        if a.eventTime ~= b.eventTime then return a.eventTime > b.eventTime end
        if a.ledgerId ~= b.ledgerId then return a.ledgerId > b.ledgerId end
        return a.paymentIndex > b.paymentIndex
    end)
    return history
end

function CrossGambling:BuildPlayerDebtReport(playerName)
    local playerKey = self:NormalizePlayerName(playerName, true)
    if not playerKey then return nil end
    local lines, total, count = {}, 0, 0
    local displayName = self:TrimInput(playerName)
    for _, entry in ipairs(self:EnsurePaymentLedger().entries) do
        if self:NormalizePlayerName(entry.loser, true) == playerKey then
            displayName = entry.loser
            local winnerRemaining = self:GetLedgerBalance(entry, "winner")
            local guildRemaining = self:GetLedgerBalance(entry, "guild")
            if winnerRemaining + guildRemaining > 0 then
                count = count + 1
                total = total + winnerRemaining + guildRemaining
                local reference = "[Debt #" .. entry.id .. " - " .. (entry.mode or "Game") .. "] " .. entry.loser .. " owes "
                if winnerRemaining > 0 then
                    lines[#lines + 1] = reference .. entry.winner .. " " .. self:addCommas(winnerRemaining) .. "g."
                end
                if guildRemaining > 0 then
                    lines[#lines + 1] = reference .. entry.guild .. " (guild) " .. self:addCommas(guildRemaining) .. "g."
                end
            end
        end
    end
    table.insert(lines, 1, count == 0 and ("CrossGambling: " .. displayName .. " has no unpaid debts.")
        or string.format("CrossGambling: %s owes %sg across %d unpaid %s.", displayName, self:addCommas(total), count, count == 1 and "debt" or "debts"))
    return lines, total, count
end

function CrossGambling:ReportPlayerDebts(playerName)
    if self.ledgerDebtReport then
        return false, "A debt report is already being sent."
    end
    local lines = self:BuildPlayerDebtReport(playerName)
    if not lines then return false, "Select a player first." end
    local method = self.game.chatMethod
    if not self:CanSendToChannel(method) then
        return false, self:GetUnavailableChannelMessage(method)
    end
    local channel = self:ResolveChatChannel(method)
    local messages = {}
    for _, line in ipairs(lines) do
        while #line > 240 do
            local cut = 240
            local nextByte = string.byte(line, cut + 1)
            while nextByte and nextByte >= 128 and nextByte < 192 do
                cut = cut - 1
                nextByte = string.byte(line, cut + 1)
            end
            local space = line:sub(1, cut):match("^.*()%s")
            if space and space > 120 then cut = space - 1 end
            messages[#messages + 1] = line:sub(1, cut)
            line = self:TrimInput(line:sub(cut + 1))
        end
        messages[#messages + 1] = line
    end
    local report = { lines = messages, index = 1 }
    self.ledgerDebtReport = report
    local function sendNext()
        if self.ledgerDebtReport ~= report then return end
        if self.game.chatMethod ~= method or self:ResolveChatChannel(method) ~= channel or not self:CanSendToChannel(method) then
            self.ledgerDebtReport = nil
            self:RefreshPaymentLedger()
            self:Print("Debt report stopped because the chat channel changed or became unavailable.")
            return
        end
        self:SendChat(report.lines[report.index], method)
        report.index = report.index + 1
        if report.index > #report.lines then
            self.ledgerDebtReport = nil
            self:RefreshPaymentLedger()
        else
            C_Timer.After(0.8, sendNext)
        end
    end
    sendNext()
    self:RefreshPaymentLedger()
    return true, "Sending debt report to " .. channel .. "."
end

function CrossGambling:StopLedgerDebtReport()
    if not self.ledgerDebtReport then return false, "No debt report is being sent." end
    self.ledgerDebtReport = nil
    self:RefreshPaymentLedger()
    return true, "Debt report stopped."
end

function CrossGambling:ExportPaymentLedger(search, filter, playerName)
    local lines = { "ID\tDate\tProfile\tMode\tHost\tRealm\tPayer\tWinner\tGuild\tTotal gold\tWinner due\tWinner paid\tGuild due\tGuild paid\tStatus" }
    for _, entry in ipairs(self:GetFilteredLedgerEntries(search, filter, playerName)) do
        local _, winnerPaid = self:GetLedgerBalance(entry, "winner")
        local _, guildPaid = self:GetLedgerBalance(entry, "guild")
        local fields = { entry.id, self:FormatAuditTimestamp(entry.timestamp), entry.profile or "", entry.mode or "",
            entry.host or "", entry.realm or "", entry.loser, entry.winner, entry.guild, entry.amount,
            entry.winnerAmount, winnerPaid, entry.guildAmount, guildPaid, self:GetLedgerStatus(entry) }
        for i, value in ipairs(fields) do fields[i] = tostring(value):gsub("[\t\r\n]", " ") end
        lines[#lines + 1] = table.concat(fields, "\t")
    end
    return table.concat(lines, "\n")
end

function CrossGambling:RefreshPaymentLedger()
    if self.paymentLedgerFrame and self.paymentLedgerFrame:IsShown() then
        self.paymentLedgerFrame:Refresh()
    end
end
