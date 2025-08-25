local addonName, HoA = ...

-- main frame setup (same as before)
local f = CreateFrame("Frame", "HoAMainFrame", UIParent)
f:SetSize(1000, 600)
f:SetPoint("CENTER")
f:Hide()
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)

-- container for right panel (page content)
f.rightPanel = CreateFrame("Frame", nil, f)
f.rightPanel:SetPoint("TOPLEFT", 300, -60)
f.rightPanel:SetPoint("BOTTOMRIGHT", -12, 12)

-- function to swap pages
HoA.Pages = {}
function HoA:ShowPage(name)
    if f.currentPage and f.currentPage.HidePage then
        f.currentPage:HidePage()
    elseif f.currentPage then
        f.currentPage:Hide()
    end

    local page = HoA.Pages[name]
    if not page then
        local ok, loaded = pcall(function()
            page = HoA:LoadPage(name)
        end)
        if not ok then
            print("HoA: Error loading page "..name..":", loaded)
            return
        end
    end

    f.currentPage = page
    if page.ShowPage then
        page:ShowPage()
    else
        page:Show()
    end
end

-- helper to load from Pages/*.lua
function HoA:LoadPage(name)
    local module = HoA.Pages[name]
    if module then return module end
    local file = "Interface\\AddOns\\HoA\\Pages\\"..name..".lua"
    -- WoW auto-loads Lua files if listed in TOC, so just reference it
    return HoA.Pages[name]
end

-- buttons on the left side
local buttons = {
    {text = "Main", page = "Main"},
    {text = "Community", page = "Community"},
    {text = "Guild", page = "Guild"},
    {text = "Settings", page = "Settings"},
}

local prev
for i, info in ipairs(buttons) do
    local btn = CreateFrame("Button", nil, f)
    btn:SetSize(200, 30)
    if not prev then
        btn:SetPoint("TOPLEFT", 20, -80)
    else
        btn:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -5)
    end
    prev = btn

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(info.text)

    btn:SetScript("OnClick", function()
        HoA:ShowPage(info.page)
    end)
end

-- slash command
SLASH_HOA1 = "/hoa"
SlashCmdList["HOA"] = function()
    if f:IsShown() then f:Hide() else f:Show() HoA:ShowPage("Main") end
end
