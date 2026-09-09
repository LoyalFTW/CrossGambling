
local uiThemes = { "Classic", "Slick" }

function CrossGambling:InitMinimap()
    local addon = self
    local minimapIcon = LibStub("LibDBIcon-1.0")
    local minimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("CrossGamblingIcon", {
        type = "data source",
        text = "CrossGambling",
        icon = "Interface\\AddOns\\CrossGambling\\media\\icon",
        OnClick = function()
            addon:BuildUI()
            if (addon.db.global.theme == uiThemes[1]) then
                addon:toggleUi2()
            elseif (addon.db.global.theme == uiThemes[2]) then
                addon:toggleUi()
            end
        end,
        OnTooltipShow = function(tooltip)
            local getAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
            local version = getAddOnMetadata and getAddOnMetadata("CrossGambling", "Version") or nil
            version = version or "Dev"
            if version:find("project-version", 1, true) then
                version = "Dev"
            end
            tooltip:AddDoubleLine("Cross Gambling", "|cFFAAAAAA" .. version .. "|r", 1, 0.82, 0, 1, 1, 1)
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine("|cFF00BBFFLeft-Click|r", "|cFFFFFFFFShow/Hide|r")
        end,
    })

    minimapIcon:Register("CrossGamblingIcon", minimapLDB, self.db.global.minimap)
    self.minimapIcon = minimapIcon
end

function CrossGambling:ToggleMinimap()
    if not self.minimapIcon then
        return
    end

    if (self.db.global.minimap.hide == false) then
        self.minimapIcon:Hide("CrossGamblingIcon")
        self.db.global.minimap.hide = true
    else
        self.minimapIcon:Show("CrossGamblingIcon")
        self.db.global.minimap.hide = false
    end
end
