local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local LDB_NAME = "CrossGambling"
local MINIMAP_ICON = "Interface\\AddOns\\CrossGambling\\Media\\Icon"

local uiThemes = { "Classic", "Slick" }

local function ToggleMainWindow(addon)
    addon:BuildUI()
    if addon.db.global.theme == uiThemes[1] then
        addon:toggleUi2()
    elseif addon.db.global.theme == uiThemes[2] then
        addon:toggleUi()
    end
end

local function OpenSettings(addon)
    addon:BuildUI()
    if CGOptions and CGOptions.Open then
        CGOptions:Open()
    end
end

local function Click(addon, mouseButton)
    if mouseButton == "LeftButton" then
        ToggleMainWindow(addon)
    elseif mouseButton == "RightButton" then
        OpenSettings(addon)
    end
end

local function PopulateTooltip(tooltip)
    local getAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version = getAddOnMetadata and getAddOnMetadata(LDB_NAME, "Version") or nil
    version = version or "Dev"
    if version:find("project-version", 1, true) then
        version = "Dev"
    end

    tooltip:AddDoubleLine("Cross Gambling", "|cFFAAAAAA" .. version .. "|r", 1, 0.82, 0, 1, 1, 1)
    tooltip:AddLine("Left Click: Show or hide", 0.8, 0.8, 0.8)
    tooltip:AddLine("Right Click: AddOn settings", 0.8, 0.8, 0.8)
    tooltip:AddLine("Use /cg minimap to hide this button", 0.5, 0.5, 0.5)
end

function CrossGambling:InitMinimap()
    self.db.global.minimap = self.db.global.minimap or { hide = false }
    self.db.global.minimap.showInCompartment = true

    local addon = self
    local minimapObject = LDB:NewDataObject(LDB_NAME, {
        type = "launcher",
        text = LDB_NAME,
        icon = MINIMAP_ICON,
        OnClick = function(_, mouseButton)
            Click(addon, mouseButton)
        end,
        OnTooltipShow = PopulateTooltip,
    })

    if not LDBIcon.IsRegistered or not LDBIcon:IsRegistered(LDB_NAME) then
        LDBIcon:Register(LDB_NAME, minimapObject, self.db.global.minimap)
    end
    if LDBIcon.IsButtonCompartmentAvailable and LDBIcon:IsButtonCompartmentAvailable() then
        LDBIcon:AddButtonToCompartment(LDB_NAME, MINIMAP_ICON)
    end
    self.minimapIcon = LDBIcon
    self.minimapObject = minimapObject
end

function CrossGambling:SetMinimapHidden(hide)
    if not self.db or not self.db.global then return end

    self.db.global.minimap = self.db.global.minimap or { hide = false }
    self.db.global.minimap.hide = hide and true or false
    if hide then
        LDBIcon:Hide(LDB_NAME)
    else
        LDBIcon:Show(LDB_NAME)
    end
end

function CrossGambling:ToggleMinimap()
    local minimap = self.db and self.db.global and self.db.global.minimap
    self:SetMinimapHidden(not (minimap and minimap.hide))
end
