-- Foundry.List
--
-- A thin bridge over Blizzard's modern ScrollBox system. One :New(config) builds
-- the five-object composition a scrolling list needs (the WowScrollBoxList frame,
-- the MinimalScrollBar EventFrame, a ScrollBoxListLinearView, a DataProvider, and
-- the ScrollUtil wiring) in the correct order, with the ordering traps handled,
-- and returns a small controller: SetData to replace the rows, ForEachFrame to
-- touch the realized rows in place, GetNativeHandles to drop to the raw Blizzard
-- objects, and Destroy to tear it down. List bridges the linear list view only
-- (grid, tree, and biaxal views are out of scope) and operates entirely in the
-- insecure domain. The raw objects stay reachable via :GetNativeHandles().

local F = _G.Foundry_1_0
if not F then
    error("Foundry-1.0: List.lua requires the Foundry-1.0 bootstrap (Foundry.lua) "
        .. "to have loaded first; _G.Foundry_1_0 is missing.", 0)
end
-- Guarded-embedding stand-down (§2.2b): if this module is already registered on the
-- winning copy, this is a redundant embedded copy — load nothing.
if F:HasModule("List") then return end

local List = {}
List.API_VERSION = 1

--------------------------------------------------------------------------------
-- ScrollBox-system capability gate (flavor support)
--------------------------------------------------------------------------------

-- The modern ScrollBox system shipped engine-wide in the 10.0 UI rewrite. List
-- presence-checks it at :New so a client that lacks it (a partial Classic export)
-- refuses loudly rather than erroring deep inside a missing global. There is no
-- FauxScrollFrame fallback: List bridges the modern system only.
local function hasScrollBoxSystem()
    return type(ScrollUtil) == "table"
        and type(ScrollUtil.InitScrollBoxListWithScrollBar) == "function"
        and type(CreateScrollBoxListLinearView) == "function"
        and type(CreateDataProvider) == "function"
end

--------------------------------------------------------------------------------
-- Controller
--------------------------------------------------------------------------------

local Controller = {}
Controller.__index = Controller

-- Shared destroyed-guard. The message form has no colon after the method name
-- ("List:SetData called on a destroyed controller"), matching the spec.
local function refuseIfDestroyed(self, method)
    if self._destroyed then
        F:RaiseDevError("List:" .. method .. " called on a destroyed controller")
        return true
    end
    return false
end

-- Replace the entire row set. Builds a fresh DataProvider and reassigns it, which
-- releases and re-acquires every visible row (not an in-place recycle) and scrolls
-- back to the top. Rows must be an array of tables; non-table rows disable
-- Blizzard's frame recycling, so List refuses them.
function Controller:SetData(rows)
    if refuseIfDestroyed(self, "SetData") then return end
    -- SetData reassigns the provider, which is unsafe to do from inside an
    -- initializer. Blizzard's Acquire reentrancy guard does not cover the
    -- post-layout initializer, so this is List's own contract.
    if self._inInitializer then
        F:RaiseDevError("List:SetData: cannot mutate data from inside an initializer")
        return
    end
    if type(rows) ~= "table" then
        F:RaiseDevError("List:SetData: data must be an array of tables (non-table rows disable recycling)")
        return
    end
    for i = 1, #rows do
        if type(rows[i]) ~= "table" then
            F:RaiseDevError("List:SetData: data must be an array of tables (non-table rows disable recycling)")
            return
        end
    end
    self._scrollBox:SetDataProvider(CreateDataProvider(rows))
end

-- Iterate the currently-realized row frames for an in-place visual update with no
-- provider rebuild (for example, repaint the selected row's highlight). fn is
-- called as fn(frame, elementData); returning a truthy value stops iteration.
function Controller:ForEachFrame(fn)
    if refuseIfDestroyed(self, "ForEachFrame") then return end
    if type(fn) ~= "function" then
        F:RaiseDevError("List:ForEachFrame: fn must be a function")
        return
    end
    return self._scrollBox:ForEachFrame(fn)
end

-- The escape hatch: the live Blizzard objects List composed. A fresh table each
-- call; the objects themselves are live, so mutating them affects the list. List
-- exposes no internal tables of its own through handles.
function Controller:GetNativeHandles()
    if refuseIfDestroyed(self, "GetNativeHandles") then return end
    return {
        scrollBox = self._scrollBox,
        scrollBar = self._scrollBar,
        view = self._view,
        dataProvider = self._view:GetDataProvider(),
    }
end

-- Tear down the native state List created: release the provider, hide and drop
-- the frames, drop the managed-visibility behavior, and mark the controller
-- destroyed. A second call refuses loudly rather than silently passing.
function Controller:Destroy()
    if refuseIfDestroyed(self, "Destroy") then return end
    self._scrollBox:RemoveDataProvider()
    self._scrollBox:Hide()
    self._scrollBar:Hide()
    self._scrollBox = nil
    self._scrollBar = nil
    self._view = nil
    self._managedVisBehavior = nil
    self._destroyed = true
end

--------------------------------------------------------------------------------
-- Factory
--------------------------------------------------------------------------------

-- Create a list controller scoped to one consumer surface. Validation is atomic:
-- every check passes before any frame, view, or provider is created, so a
-- rejected :New leaves the pre-call state byte-for-byte unchanged.
function List:New(config)
    if type(config) ~= "table" then
        F:RaiseDevError("List:New: config must be a table")
        return
    end
    if type(config.name) ~= "string" or config.name == "" then
        F:RaiseDevError("List:New: config.name must be a non-empty string")
        return
    end
    if type(config.parent) ~= "table" then
        F:RaiseDevError("List:New: config.parent must be a frame")
        return
    end

    -- Element identity: exactly one of template or elementType.
    local hasTemplate = config.template ~= nil
    local hasElementType = config.elementType ~= nil
    if not hasTemplate and not hasElementType then
        F:RaiseDevError("List:New: config requires exactly one of template or elementType")
        return
    end
    if hasTemplate and hasElementType then
        F:RaiseDevError("List:New: config.template and config.elementType are mutually exclusive")
        return
    end
    if hasTemplate and type(config.template) ~= "string" then
        F:RaiseDevError("List:New: config.template must be a string")
        return
    end
    if hasElementType and type(config.elementType) ~= "string" then
        F:RaiseDevError("List:New: config.elementType must be a string")
        return
    end

    if type(config.initializer) ~= "function" then
        F:RaiseDevError("List:New: config.initializer must be a function")
        return
    end
    if config.resetter ~= nil and type(config.resetter) ~= "function" then
        F:RaiseDevError("List:New: config.resetter must be a function")
        return
    end

    -- Extent contract. extent and extentCalculator are mutually exclusive (List's
    -- own strictness; Blizzard would tolerate both and prefer extent).
    local hasExtent = config.extent ~= nil
    local hasCalc = config.extentCalculator ~= nil
    if hasExtent and hasCalc then
        F:RaiseDevError("List:New: config.extent and config.extentCalculator are mutually exclusive")
        return
    end
    if hasExtent and (type(config.extent) ~= "number" or config.extent <= 0) then
        F:RaiseDevError("List:New: config.extent must be a number > 0")
        return
    end
    if hasCalc and type(config.extentCalculator) ~= "function" then
        F:RaiseDevError("List:New: config.extentCalculator must be a function")
        return
    end
    -- Frame-type (elementType) rows have no measurable template, so they REQUIRE
    -- an explicit extent or a calculator; an unset extent is silently clamped to
    -- 1px by Blizzard and then explodes as a runaway range error at display.
    -- Template rows can be measured from their XML, so the extent is optional.
    if hasElementType and not hasExtent and not hasCalc then
        F:RaiseDevError("List:New: elementType rows require config.extent (> 0) or config.extentCalculator")
        return
    end

    if config.spacing ~= nil and type(config.spacing) ~= "number" then
        F:RaiseDevError("List:New: config.spacing must be a number")
        return
    end

    -- Capability gate (§6). Checked after input validation so a bad config still
    -- surfaces its specific error first; a good config on a client without the
    -- ScrollBox system refuses here rather than erroring deep in Blizzard.
    if not hasScrollBoxSystem() then
        F:RaiseDevError("List:New: this client lacks the modern scrolling-list system "
            .. "(ScrollUtil/CreateScrollBoxListLinearView); Foundry.List is unavailable here")
        return
    end

    -- All valid. Build the five-object composition. `c` is a private local table
    -- (not observable) created here so the wrapped initializer can close over it.
    local c = setmetatable({}, Controller)
    c._destroyed = false
    c._name = config.name
    c._inInitializer = false

    local parent = config.parent
    local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    -- Default fill anchor: a starting point only. Consumers re-anchor through
    -- :GetNativeHandles() when their layout reserves a scrollbar gutter or a
    -- header inset (see the reference page).
    scrollBox:SetPoint("TOPLEFT")
    scrollBox:SetPoint("BOTTOMRIGHT")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    local view = CreateScrollBoxListLinearView(0, 0, 0, 0, config.spacing or 0)

    if hasExtent then
        view:SetElementExtent(config.extent)
    elseif hasCalc then
        -- Wrap the consumer calculator so its RETURN value is guarded at runtime:
        -- :New only proved it's a function. A nil return leaves Blizzard's
        -- calculatedElementExtents SHORT (ScrollBoxStride then hits a nil
        -- operand); a non-number return instead corrupts the extents arithmetic
        -- -- either way a cryptic crash far from the cause. Dev raises a clear
        -- List error; release prints and degrades to a safe positive fallback.
        local consumerCalc = config.extentCalculator
        view:SetElementExtentCalculator(function(index, elementData)
            local extent = consumerCalc(index, elementData)
            if type(extent) ~= "number" or extent <= 0 then
                F:RaiseDevError("List: extentCalculator must return a number > 0 (got "
                    .. tostring(extent) .. ")")
                return 1
            end
            return extent
        end)
    end

    -- Wrap the consumer initializer so SetData-from-inside-initializer can be
    -- refused. The flag is always cleared, even if the consumer initializer
    -- errors, so one bad initializer call cannot permanently brick SetData.
    local consumerInit = config.initializer
    local elementId = config.template or config.elementType
    view:SetElementInitializer(elementId, function(frame, elementData)
        c._inInitializer = true
        local ok, err = pcall(consumerInit, frame, elementData)
        c._inInitializer = false
        if not ok then
            error(err, 0)
        end
    end)

    if config.resetter then
        view:SetElementResetter(config.resetter)
    end

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    if config.managedScrollBarVisibility then
        c._managedVisBehavior = ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar)
    end

    -- Seed an empty provider so SetData is valid immediately. This must follow the
    -- initializer: SetDataProvider errors if no element factory has been set.
    scrollBox:SetDataProvider(CreateDataProvider())

    c._scrollBox = scrollBox
    c._scrollBar = scrollBar
    c._view = view

    return c
end

F:RegisterModule("List", List)
