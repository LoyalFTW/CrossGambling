local CG = CrossGambling

local _btnFrames  = {}  
local _sideFrames = {}  
local _mainFrame  = nil  
local _textField  = nil 

local DEFAULTS = {
    frameColor  = { r = 0.27, g = 0.27, b = 0.27 },
    buttonColor = { r = 0.30, g = 0.30, b = 0.30 },
    sideColor   = { r = 0.20, g = 0.20, b = 0.20 },
    fontColor   = { r = 1.00, g = 1.00, b = 1.00 },
}

function CG:ColorsSetMainFrame(frame)
    _mainFrame = frame
end

function CG:ColorsSetTextField(frame)
    _textField = frame
end

function CG:ColorsRegisterButton(frame)
    table.insert(_btnFrames, frame)
end

function CG:ColorsRegisterSide(frame)
    table.insert(_sideFrames, frame)
end

local function GetColors()
    if CG.db and CG.db.global and CG.db.global.colors then
        return CG.db.global.colors
    end
    return DEFAULTS
end

local function SetBackdropSafe(frame, r, g, b)
    if frame and frame.SetBackdropColor then
        frame:SetBackdropColor(r, g, b)
    end
end

function CG:ColorsApplyAll()
    local c = GetColors()

    SetBackdropSafe(_mainFrame, c.frameColor.r, c.frameColor.g, c.frameColor.b)

    for _, f in ipairs(_btnFrames) do
        SetBackdropSafe(f, c.buttonColor.r, c.buttonColor.g, c.buttonColor.b)
    end

    for _, f in ipairs(_sideFrames) do
        SetBackdropSafe(f, c.sideColor.r, c.sideColor.g, c.sideColor.b)
    end

    if _textField and _textField.SetTextColor then
        local fc = c.fontColor
        _textField:SetTextColor(fc.r, fc.g, fc.b)
    end
end

function CG:ColorsSave(key, r, g, b)
    if not (CG.db and CG.db.global and CG.db.global.colors) then return end
    local entry = CG.db.global.colors[key]
    if not entry then
        CG.db.global.colors[key] = { r = r, g = g, b = b }
    else
        entry.r, entry.g, entry.b = r, g, b
    end
    CG:ColorsApplyAll()
end

function CG:ColorsReset()
    if not (CG.db and CG.db.global and CG.db.global.colors) then return end
    local c = CG.db.global.colors
    for key, def in pairs(DEFAULTS) do
        c[key] = { r = def.r, g = def.g, b = def.b }
    end
    CG:ColorsApplyAll()
end

function CG:ColorsOpenPicker(key, onRefresh)
    if not (CG.db and CG.db.global and CG.db.global.colors) then return end
    local c = CG.db.global.colors[key]
    if not c then return end

    local prevR, prevG, prevB = c.r, c.g, c.b

    local function apply(r, g, b)
        CG:ColorsSave(key, r, g, b)
        if onRefresh then onRefresh(r, g, b) end
    end

    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = c.r, g = c.g, b = c.b,
            hasOpacity  = false,
            swatchFunc  = function()
                apply(ColorPickerFrame:GetColorRGB())
            end,
            cancelFunc  = function(prev)
                apply(prev.r, prev.g, prev.b)
            end,
            previousValues = { r = prevR, g = prevG, b = prevB },
        })
    else
        -- Legacy API
        ColorPickerFrame.hasOpacity     = false
        ColorPickerFrame.previousValues = { r = prevR, g = prevG, b = prevB }
        ColorPickerFrame.func = function()
            apply(ColorPickerFrame:GetColorRGB())
        end
        ColorPickerFrame.cancelFunc = function(prev)
            apply(prev.r, prev.g, prev.b)
        end
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

function CG:ColorsLoad()
    CG:ColorsApplyAll()
end
