local _, ns = ...
local CrossGambling = ns.CG

local ledgerFrames, ledgerButtons, ledgerFonts, ledgerInputs, ledgerPanels = {}, {}, {}, {}, {}
local LEDGER_BACKDROP = {
    bgFile = "Interface\\AddOns\\CrossGambling\\media\\CG.tga",
    edgeFile = "Interface\\AddOns\\CrossGambling\\media\\CG.tga",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function ledgerName(name)
    return "|cffffffff" .. name .. "|r"
end

local function selectedLedgerPlayer(frame, addon)
    local entry = addon:GetLedgerEntry(frame.selectedId)
    return entry and entry.loser or frame.historyPlayer or frame.playerFilter
end

local function styleDebtRow(row, selected, color, index)
    if selected then
        row.background:SetColorTexture(math.min(1, color.r + 0.08), math.min(1, color.g + 0.08), math.min(1, color.b + 0.08), 0.95)
    else
        row.background:SetColorTexture(color.r, color.g, color.b, index % 2 == 0 and 0.55 or 0.2)
    end
    row.selectionBorder:SetShown(selected)
end

local function register(theme, object, registry, method)
    if object._ledgerRegistry ~= theme[registry] then
        theme[method](theme, object)
        object._ledgerRegistry = theme[registry]
    end
end

local function chrome(control, slick)
    if not control._ledgerTextures then
        control._ledgerTextures = {}
        for _, region in ipairs({ control:GetRegions() }) do
            if region:GetObjectType() == "Texture" then
                table.insert(control._ledgerTextures, { region, region:IsShown() })
            end
        end
    end
    for _, texture in ipairs(control._ledgerTextures) do
        texture[1]:SetShown(not slick and texture[2])
    end
    if control.NineSlice then control.NineSlice:SetShown(not slick) end
    if control.Inset then control.Inset:SetShown(not slick) end
end

function CrossGambling:RestylePaymentLedger()
    local theme = CGTheme
    local slick = theme and theme:GetTheme() == "Slick"
    for _, frame in ipairs(ledgerFrames) do
        chrome(frame, slick)
        frame:SetBackdrop(slick and LEDGER_BACKDROP or nil)
        if slick then
            frame:SetBackdropBorderColor(0, 0, 0)
            frame:SetBackdropColor(theme._frameColor.r, theme._frameColor.g, theme._frameColor.b)
            register(theme, frame, "_frameFrames", "RegisterFrame")
        end
        if frame.TitleText then
            frame.TitleText:ClearAllPoints()
            frame.TitleText:SetPoint("TOPLEFT", frame, "TOPLEFT", slick and 16 or 32, slick and -11 or -5)
            frame.TitleText:SetPoint("RIGHT", frame, "RIGHT", -40, 0)
            frame.TitleText:SetJustifyH(slick and "LEFT" or "CENTER")
        end
    end
    for _, control in ipairs(ledgerButtons) do
        chrome(control, slick)
        if not control._ledgerSlickHighlight then
            control._ledgerClassicHighlight = control:GetHighlightTexture()
            local highlight = control:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
            highlight:SetBlendMode("ADD")
            highlight:SetAllPoints()
            control._ledgerSlickHighlight = highlight
        end
        control._ledgerSlickHighlight:SetShown(slick)
        control:SetHighlightTexture(slick and control._ledgerSlickHighlight or control._ledgerClassicHighlight)
        control:SetBackdrop(slick and LEDGER_BACKDROP or nil)
        if slick then
            control:SetBackdropBorderColor(0, 0, 0)
            control:SetBackdropColor(theme._buttonColor.r, theme._buttonColor.g, theme._buttonColor.b)
            register(theme, control, "_btnFrames", "RegisterBtn")
            control:GetFontString():SetFont(theme:GetFontPath(), math.min(14, theme:GetFontSize()), theme:GetFontFlags())
        else
            control:GetFontString():SetFontObject("GameFontNormal")
        end
        if control._ledgerFilter then
            local selected = self.paymentLedgerFrame and self.paymentLedgerFrame.filter == control._ledgerFilter
            control._ledgerFilterBorder:SetShown(selected)
            control:SetText((selected and "|cffffffff" or "|cffbbbbbb") .. control._ledgerFilter .. "|r")
            if slick and selected then
                control:SetBackdropColor(math.min(1, theme._buttonColor.r + 0.08), math.min(1, theme._buttonColor.g + 0.08), math.min(1, theme._buttonColor.b + 0.08), 0.95)
            end
        end
    end
    for _, input in ipairs(ledgerInputs) do
        chrome(input, slick)
        input:SetBackdrop(slick and LEDGER_BACKDROP or nil)
        if slick then
            input:SetBackdropBorderColor(0, 0, 0)
            input:SetBackdropColor(theme._sideColor.r, theme._sideColor.g, theme._sideColor.b)
            input:SetFont(theme:GetFontPath(), math.min(12, theme:GetFontSize()), theme:GetFontFlags())
            register(theme, input, "_sideFrames", "RegisterSide")
        else
            input:SetFontObject("ChatFontNormal")
        end
    end
    for _, field in ipairs(ledgerFonts) do
        if slick then
            register(theme, field, "_fontStrings", "RegisterFont")
            field:SetFont(theme:GetFontPath(), math.min(field._ledgerTitle and 14 or 12, theme:GetFontSize()), theme:GetFontFlags())
            field:SetTextColor(theme:GetFontColor())
        else
            field:SetFontObject(_G[field._ledgerFontObject or "GameFontHighlightSmall"])
        end
    end
    for _, panel in ipairs(ledgerPanels) do
        local color = slick and theme._sideColor or { r = 0.12, g = 0.12, b = 0.12 }
        panel:SetBackdropColor(color.r, color.g, color.b)
        if slick then register(theme, panel, "_sideFrames", "RegisterSide") end
    end
    local ledger = self.paymentLedgerFrame
    if ledger then
        local color = theme and theme._sideColor or { r = 0.2, g = 0.2, b = 0.2 }
        for index, row in ipairs(ledger.rows or {}) do
            styleDebtRow(row, row.entryId == ledger.selectedId, color, index)
        end
    end
end
local function label(parent, text, x, y, width, template)
    local field = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    field:SetPoint("TOPLEFT", x, y)
    field:SetWidth(width)
    field:SetJustifyH("LEFT")
    field:SetWordWrap(true)
    field:SetText(text)
    field._ledgerFontObject = template or "GameFontHighlightSmall"
    table.insert(ledgerFonts, field)
    return field
end

local function button(parent, text, width, x, y, callback)
    local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate,BackdropTemplate")
    control:SetSize(width, 25)
    control:SetPoint("TOPLEFT", x, y)
    control:SetText(text)
    control:SetScript("OnClick", callback)
    table.insert(ledgerButtons, control)
    return control
end

local function gold(addon, value)
    return addon:addCommas(value) .. "g"
end

local function confirm(text, callback)
    if not StaticPopupDialogs.CG_LEDGER_CONFIRM then
        StaticPopupDialogs.CG_LEDGER_CONFIRM = {
            text = "%s", button1 = "Confirm", button2 = "Cancel",
            OnAccept = function(_, data) data() end,
            timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        }
    end
    StaticPopup_Show("CG_LEDGER_CONFIRM", text, nil, callback)
end

function CrossGambling:ShowPaymentLedgerExport(text)
    local frame = self.paymentLedgerExportFrame
    if not frame then
        frame = CreateFrame("Frame", "CrossGamblingLedgerExport", UIParent, "BasicFrameTemplateWithInset,BackdropTemplate")
        self.paymentLedgerExportFrame = frame
        table.insert(ledgerFrames, frame)
        frame.TitleText._ledgerTitle = true
        frame.TitleText._ledgerFontObject = "GameFontNormal"
        table.insert(ledgerFonts, frame.TitleText)
        frame:SetSize(640, 410)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetClampedToScreen(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame.TitleText:SetText("Copy Payment Ledger")
        label(frame, "Click the text, press Ctrl+A, then Ctrl+C. Paste into a spreadsheet or save as text.", 18, -38, 598)
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -68)
        scroll:SetPoint("BOTTOMRIGHT", -38, 20)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject("ChatFontNormal")
        edit._ledgerFontObject = "ChatFontNormal"
        table.insert(ledgerFonts, edit)
        edit:SetWidth(580)
        edit:SetScript("OnEscapePressed", function() frame:Hide() end)
        scroll:SetScrollChild(edit)
        frame.edit = edit
        table.insert(UISpecialFrames, "CrossGamblingLedgerExport")
    end
    self:RestylePaymentLedger()
    frame.edit:SetText(text)
    frame:Show()
    frame.edit:SetFocus()
    frame.edit:HighlightText()
end

function CrossGambling:ShowPaymentLedger(playerName)
    local addon = self
    local frame = self.paymentLedgerFrame
    if frame then
        if playerName then
            frame.playerFilter = playerName
            frame.historyPlayer = playerName
            frame.filter = "Outstanding"
            frame.selectedId = nil
            frame.amount:SetText("")
            frame.feedback:SetText("")
            frame.search:SetText(playerName)
        end
        self:RestylePaymentLedger()
        frame:Show()
        frame:Raise()
        frame:Refresh()
        return
    end
    frame = CreateFrame("Frame", "CrossGamblingPaymentLedger", UIParent, "BasicFrameTemplateWithInset,BackdropTemplate")
    self.paymentLedgerFrame = frame
    table.insert(ledgerFrames, frame)
    frame.TitleText._ledgerTitle = true
    frame.TitleText._ledgerFontObject = "GameFontNormal"
    table.insert(ledgerFonts, frame.TitleText)
    frame:SetSize(680, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.TitleText:SetText("CrossGambling - Payment Ledger")
    table.insert(UISpecialFrames, "CrossGamblingPaymentLedger")
    frame.playerFilter = playerName
    frame.historyPlayer = playerName
    frame.filter = "Outstanding"
    frame.recipient = "winner"
    frame.rows = {}
    frame.summary = label(frame, "", 18, -40, 278, "GameFontNormal")
    frame.summary:SetHeight(36)
    frame.summary:SetJustifyV("TOP")
    label(frame, "Search player, guild, mode or debt #", 18, -84, 285)
    local search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate,BackdropTemplate")
    search:SetSize(196, 23)
    search:SetPoint("TOPLEFT", 22, -101)
    search:SetAutoFocus(false)
    search:SetMaxLetters(100)
    search:SetScript("OnEscapePressed", function(control) control:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(control) control:ClearFocus() end)
    frame.search = search
    table.insert(ledgerInputs, search)
    search:SetText(playerName or "")
    frame.filterButtons = {}
    for i, value in ipairs({ "Outstanding", "Paid", "All" }) do
        local filter = value
        frame.filterButtons[filter] = button(frame, filter, 92, 18 + (i - 1) * 99, -133, function()
            frame.filter = filter
            frame:Refresh()
        end)
        local control = frame.filterButtons[filter]
        control._ledgerFilter = filter
        control._ledgerFilterBorder = CreateFrame("Frame", nil, control, "BackdropTemplate")
        control._ledgerFilterBorder:SetAllPoints()
        control._ledgerFilterBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        control._ledgerFilterBorder:SetBackdropBorderColor(1, 0.82, 0, 1)
    end
    button(frame, "Copy list", 88, 18, -464, function()
        addon:ShowPaymentLedgerExport(addon:ExportPaymentLedger(search:GetText(), frame.filter, frame.playerFilter))
    end)
    button(frame, "Clear", 74, 224, -101, function()
        frame.playerFilter = nil
        frame.historyPlayer = nil
        search:SetText("")
        frame:Refresh()
    end)
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -165)
    scroll:SetSize(278, 291)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(278, 1)
    scroll:SetScrollChild(content)
    frame.empty = label(content, "", 8, -12, 262)
    frame.debtTitle = label(frame, "Payment details", 336, -40, 324, "GameFontNormal")
    frame.debtTitle:SetHeight(20)
    frame.detail = label(frame, "Select a debt to record a payment.", 336, -64, 324, "GameFontHighlight")
    frame.detail:SetHeight(36)
    frame.detail:SetJustifyV("TOP")
    frame.detailMeta = label(frame, "", 336, -102, 324)
    frame.detailMeta:SetHeight(28)
    frame.detailMeta:SetJustifyV("TOP")
    local detailTooltip = CreateFrame("Frame", nil, frame)
    detailTooltip:SetPoint("TOPLEFT", 336, -40)
    detailTooltip:SetSize(324, 88)
    detailTooltip:EnableMouse(true)
    detailTooltip:SetScript("OnEnter", function(control)
        local entry = addon:GetLedgerEntry(frame.selectedId)
        if not entry then return end
        GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
        GameTooltip:SetText("Debt #" .. entry.id .. " - " .. addon:GetLedgerStatus(entry))
        GameTooltip:AddLine(entry.loser .. " owes " .. gold(addon, entry.amount) .. " total", 1, 1, 1, true)
        GameTooltip:AddLine("Winner: " .. entry.winner .. " - " .. gold(addon, entry.winnerAmount), 1, 1, 1, true)
        if entry.guildAmount > 0 then
            GameTooltip:AddLine("Guild: " .. entry.guild .. " - " .. gold(addon, entry.guildAmount), 1, 1, 1, true)
        end
        GameTooltip:AddLine((entry.mode or "") .. " - " .. (entry.profile or ""), 1, 0.82, 0, true)
        GameTooltip:AddLine(addon:FormatAuditTimestamp(entry.timestamp), 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    detailTooltip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.winnerButton = button(frame, "Winner", 158, 336, -132, function()
        frame.recipient = "winner"
        frame.amount:SetText("")
        frame.feedback:SetText("")
        frame:RefreshDetails()
    end)
    frame.guildButton = button(frame, "Guild", 158, 502, -132, function()
        frame.recipient = "guild"
        frame.amount:SetText("")
        frame.feedback:SetText("")
        frame:RefreshDetails()
    end)
    frame.recipientName = label(frame, "", 336, -164, 324)
    frame.recipientName:SetHeight(28)
    frame.recipientName:SetJustifyV("TOP")
    local balancePanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    balancePanel:SetPoint("TOPLEFT", 336, -194)
    balancePanel:SetSize(324, 40)
    balancePanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    table.insert(ledgerPanels, balancePanel)
    frame.balance = label(balancePanel, "", 10, -6, 144)
    frame.balance:SetHeight(28)
    frame.balance:SetJustifyV("TOP")
    frame.remaining = label(balancePanel, "", 170, -6, 144)
    frame.remaining:SetHeight(28)
    frame.remaining:SetJustifyV("TOP")
    label(frame, "Payment amount (gold)", 336, -240, 324)
    local amount = CreateFrame("EditBox", nil, frame, "InputBoxTemplate,BackdropTemplate")
    amount:SetSize(112, 24)
    amount:SetPoint("TOPLEFT", 341, -258)
    amount:SetAutoFocus(false)
    amount:SetMaxLetters(10)
    amount:SetScript("OnEscapePressed", function(control) control:ClearFocus() end)
    frame.amount = amount
    table.insert(ledgerInputs, amount)
    frame.recordButton = button(frame, "Record payment", 194, 466, -258, function()
        local ok, message = addon:RecordLedgerPayment(frame.selectedId, frame.recipient, amount:GetText())
        if ok then amount:SetText("") amount:ClearFocus() end
        frame.feedback:SetText((ok and "|cff66dd99" or "|cffff7777") .. message .. "|r")
    end)
    amount:SetScript("OnEnterPressed", function() frame.recordButton:Click() end)
    frame.markButton = button(frame, "Mark paid", 158, 336, -290, function()
        local entry = addon:GetLedgerEntry(frame.selectedId)
        if not entry then return end
        local id, recipient = entry.id, frame.recipient
        local remaining = addon:GetLedgerBalance(entry, recipient)
        local name = recipient == "winner" and entry.winner or entry.guild
        confirm("Record " .. gold(addon, remaining) .. " paid by " .. entry.loser .. " to " .. name .. "?", function()
            local current = addon:GetLedgerEntry(id)
            if not current or addon:GetLedgerBalance(current, recipient) ~= remaining then
                frame.feedback:SetText("Balance changed. Review the debt and try again.")
                return
            end
            local ok, message = addon:RecordLedgerPayment(id, recipient, remaining)
            frame.feedback:SetText(message)
            if ok then amount:SetText("") end
        end)
    end)
    frame.undoButton = button(frame, "Undo payment", 158, 502, -290, function()
        local entry = addon:GetLedgerEntry(frame.selectedId)
        if not entry then return end
        local payment, index = addon:GetLastLedgerPayment(entry)
        if not payment then return end
        local id = entry.id
        local name = payment.recipient == "winner" and entry.winner or entry.guild
        confirm("Undo the last " .. gold(addon, payment.amount) .. " payment to " .. name .. "?", function()
            local _, message = addon:UndoLedgerPayment(id, index)
            frame.feedback:SetText(message)
        end)
    end)
    for _, control in ipairs({ frame.recordButton, frame.markButton, frame.undoButton }) do
        control:SetScript("OnEnter", function(button)
            local entry = addon:GetLedgerEntry(frame.selectedId)
            if not entry then return end
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText("Selected debt #" .. entry.id)
            GameTooltip:AddLine(entry.loser .. " -> " .. entry.winner, 1, 1, 1, true)
            GameTooltip:AddLine(button == frame.undoButton and "Undo only the latest recorded payment on this debt." or "Record a payment only against this debt's selected recipient.", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        control:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    frame.feedback = label(frame, "", 336, -321, 324)
    frame.feedback:SetHeight(28)
    frame.feedback:SetJustifyV("TOP")
    frame.historyTitle = label(frame, "Player payment history", 336, -355, 214, "GameFontNormal")
    frame.historyTitle:SetHeight(16)
    label(frame, "Scroll to review", 552, -355, 108)
    local historyPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    historyPanel:SetPoint("TOPLEFT", 336, -372)
    historyPanel:SetSize(324, 108)
    historyPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    table.insert(ledgerPanels, historyPanel)
    local history = CreateFrame("ScrollingMessageFrame", nil, historyPanel)
    history:SetPoint("TOPLEFT", 4, -4)
    history:SetSize(316, 100)
    history:SetFontObject(GameFontHighlightSmall)
    table.insert(ledgerFonts, history)
    history:SetJustifyH("LEFT")
    history:SetInsertMode("TOP")
    history:SetFading(false)
    history:EnableMouseWheel(true)
    history:SetScript("OnMouseWheel", function(control, delta)
        if delta > 0 then control:ScrollUp() else control:ScrollDown() end
    end)
    frame.reportButton = button(frame, "Report debts to chat", 184, 114, -464, function()
        local ok, message
        if addon.ledgerDebtReport then
            ok, message = addon:StopLedgerDebtReport()
        else
            ok, message = addon:ReportPlayerDebts(selectedLedgerPlayer(frame, addon))
        end
        frame.feedback:SetText((ok and "|cff66dd99" or "|cffff7777") .. message .. "|r")
    end)
    frame.reportButton:SetScript("OnEnter", function(control)
        local playerName = selectedLedgerPlayer(frame, addon)
        GameTooltip:SetOwner(control, "ANCHOR_RIGHT")
        if addon.ledgerDebtReport then
            GameTooltip:SetText("Stop Debt Report")
            GameTooltip:AddLine("Stop sending the remaining report lines.", 1, 1, 1, true)
            GameTooltip:Show()
            return
        end
        GameTooltip:SetText("Report Unpaid Debts")
        GameTooltip:AddLine("List everything " .. (playerName or "the selected player") .. " still owes, including guild payments, in the selected game chat channel.", 1, 1, 1, true)
        GameTooltip:AddLine("Includes all their debts, regardless of this window's filters.", 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    frame.reportButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.history = history

    function frame:RefreshPlayerHistory()
        history:Clear()
        local playerName = selectedLedgerPlayer(self, addon)
        self.reportButton:SetEnabled(playerName ~= nil or addon.ledgerDebtReport ~= nil)
        self.reportButton:SetText(addon.ledgerDebtReport and "Stop debt report" or "Report debts to chat")
        self.historyTitle:SetText(playerName and ("History: " .. ledgerName(playerName)) or "Player payment history")
        if not playerName then
            history:AddMessage("Select a player to see all their payments.", 0.6, 0.6, 0.6)
            return
        end
        local payments = addon:GetPlayerLedgerHistory(playerName)
        history:SetMaxLines(math.max(20, #payments * 3))
        for i = #payments, 1, -1 do
            local payment = payments[i]
            local selected = payment.ledgerId == self.selectedId
            local reference = (selected and "|cffffd100Selected debt #" or "|cffaaaaaaDebt #") .. payment.ledgerId .. "|r"
            local color = payment.reversedAt and "|cffaaaaaa" or "|cff66dd99"
            local text = reference .. "  " .. color .. addon:FormatAuditTimestamp(payment.timestamp, true)
                .. "\n" .. ledgerName(payment.payer) .. color .. " -> " .. ledgerName(payment.recipient) .. color .. ": " .. gold(addon, payment.amount)
            if payment.reversedAt then
                text = text .. "\nUndone " .. addon:FormatAuditTimestamp(payment.reversedAt, true)
            end
            history:AddMessage(text .. "|r")
        end
        if #payments == 0 then history:AddMessage("No payments recorded for " .. playerName .. " yet.", 0.6, 0.6, 0.6) end
        history:ScrollToTop()
    end

    function frame:RefreshDetails()
        local entry = addon:GetLedgerEntry(self.selectedId)
        if entry then self.historyPlayer = entry.loser end
        self:RefreshPlayerHistory()
        local controls = { self.winnerButton, self.guildButton, self.recordButton, self.markButton, self.undoButton }
        if not entry then
            self.debtTitle:SetText("Payment details")
            self.detail:SetText("Select a debt to view its payout split and record payments.")
            self.detailMeta:SetText("")
            self.recipientName:SetText("")
            self.balance:SetText("")
            self.remaining:SetText("")
            self.winnerButton:SetText("Winner")
            self.guildButton:SetText("Guild")
            self.winnerButton:SetWidth(158)
            self.guildButton:SetWidth(158)
            self.guildButton:ClearAllPoints()
            self.guildButton:SetPoint("TOPLEFT", 502, -132)
            self.winnerButton:Show()
            self.guildButton:Show()
            for _, control in ipairs(controls) do control:Disable() end
            self.amount:Disable()
            return
        end
        local winnerRemaining, winnerPaid = addon:GetLedgerBalance(entry, "winner")
        local guildRemaining, guildPaid = addon:GetLedgerBalance(entry, "guild")
        self.debtTitle:SetText(string.format("|cffffd100Debt #%d|r  -  %s", entry.id, addon:GetLedgerStatus(entry)))
        self.detail:SetText(ledgerName(entry.loser) .. " owes " .. gold(addon, entry.amount) .. " total\nWinner: " .. ledgerName(entry.winner))
        self.detailMeta:SetText((entry.mode or "") .. "  -  " .. (entry.profile or "") .. "\n" .. addon:FormatAuditTimestamp(entry.timestamp))
        if entry.winnerAmount == 0 then self.recipient = "guild" end
        if entry.guildAmount == 0 then self.recipient = "winner" end
        local isWinner = self.recipient == "winner"
        self.winnerButton:SetText((isWinner and "|cffffd100" or "") .. "Winner: " .. gold(addon, winnerRemaining) .. "|r")
        self.guildButton:SetText((not isWinner and "|cffffd100" or "") .. "Guild: " .. gold(addon, guildRemaining) .. "|r")
        self.winnerButton:SetEnabled(entry.winnerAmount > 0)
        self.guildButton:SetEnabled(entry.guildAmount > 0)
        self.winnerButton:SetShown(entry.winnerAmount > 0)
        self.guildButton:SetShown(entry.guildAmount > 0)
        self.winnerButton:SetWidth(entry.guildAmount == 0 and 324 or 158)
        self.guildButton:SetWidth(entry.winnerAmount == 0 and 324 or 158)
        self.guildButton:ClearAllPoints()
        self.guildButton:SetPoint("TOPLEFT", entry.winnerAmount == 0 and 336 or 502, -132)
        local remaining = isWinner and winnerRemaining or guildRemaining
        local paid = isWinner and winnerPaid or guildPaid
        self.recipientName:SetText("Paying " .. ledgerName(isWinner and entry.winner or entry.guild))
        self.balance:SetText("Recorded paid\n" .. gold(addon, paid))
        self.remaining:SetText("Remaining\n|cffffd100" .. gold(addon, remaining) .. "|r")
        self.recordButton:SetEnabled(remaining > 0)
        self.markButton:SetEnabled(remaining > 0)
        if remaining > 0 then self.amount:Enable() else self.amount:Disable() end
        self.undoButton:SetEnabled(addon:GetLastLedgerPayment(entry) ~= nil)
    end

    function frame:Refresh()
        local entries, summary = addon:GetFilteredLedgerEntries(search:GetText(), self.filter, self.playerFilter)
        self.summary:SetText(string.format("Outstanding: %s  |  %d debts\nWinner: %s  |  Guild: %s", gold(addon, summary.outstanding), summary.count, gold(addon, summary.winner), gold(addon, summary.guild)))
        for _, control in pairs(self.filterButtons) do control:Enable() end
        local selectedVisible = false
        for i, entry in ipairs(entries) do
            if entry.id == self.selectedId then selectedVisible = true end
            local row = self.rows[i]
            if not row then
                row = CreateFrame("Button", nil, content)
                row:SetSize(278, 94)
                row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                row.background = row:CreateTexture(nil, "BACKGROUND")
                row.background:SetAllPoints()
                row.selectionBorder = CreateFrame("Frame", nil, row, "BackdropTemplate")
                row.selectionBorder:SetAllPoints()
                row.selectionBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
                row.selectionBorder:SetBackdropBorderColor(1, 0.82, 0, 1)
                row.text = label(row, "", 8, -8, 262)
                row.text:SetHeight(78)
                row.text:SetJustifyV("TOP")
                row:SetScript("OnClick", function(control)
                    self.selectedId = control.entryId
                    local selectedEntry = addon:GetLedgerEntry(control.entryId)
                    self.historyPlayer = selectedEntry and selectedEntry.loser or nil
                    self.recipient = "winner"
                    amount:SetText("")
                    self.feedback:SetText("")
                    self:Refresh()
                end)
                self.rows[i] = row
            end
            row.entryId = entry.id
            row:SetPoint("TOPLEFT", 0, -(i - 1) * 97)
            local winnerRemaining = addon:GetLedgerBalance(entry, "winner")
            local guildRemaining = addon:GetLedgerBalance(entry, "guild")
            local status = addon:GetLedgerStatus(entry)
            local color = status == "Paid" and "|cff66dd99" or (status == "Partial" and "|cffffcc66" or "|cffff8888")
            row.text:SetText(string.format("|cffffd100#%d|r  %s  %s%s|r\nTo %s: %s\nGuild: %s  |  %s\n%s - %s", entry.id, ledgerName(entry.loser), color, status, ledgerName(entry.winner),
                gold(addon, winnerRemaining), gold(addon, guildRemaining), entry.mode or "", entry.profile or "", addon:FormatAuditTimestamp(entry.timestamp, true)))
            local color = CGTheme and CGTheme._sideColor or { r = 0.2, g = 0.2, b = 0.2 }
            styleDebtRow(row, entry.id == self.selectedId, color, i)
            row:Show()
        end
        for i = #entries + 1, #self.rows do self.rows[i]:Hide() end
        if not selectedVisible then self.selectedId = nil end
        self.empty:SetText(#entries == 0 and (search:GetText() ~= "" and "No debts match this search." or (self.filter == "Outstanding" and "No outstanding debts.\nNew hosted game results appear here automatically.\nOlder History entries are not treated as unpaid debts." or "No debts in this view.")) or "")
        content:SetHeight(math.max(1, #entries * 97))
        addon:RestylePaymentLedger()
        self:RefreshDetails()
    end
    search:SetScript("OnTextChanged", function(_, userInput)
        if userInput then
            frame.playerFilter = nil
            frame.historyPlayer = nil
        end
        scroll:SetVerticalScroll(0)
        frame:Refresh()
    end)
    frame:SetScript("OnShow", function() addon:RestylePaymentLedger() frame:Refresh() end)
    frame:Refresh()
    frame:Show()
end
