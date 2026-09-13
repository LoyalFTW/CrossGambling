-- Foundry.Tooltip
--
-- A thin bridge over Blizzard's modern tooltip-hook system (TooltipDataProcessor).
-- :New(config) registers a typed post-call handler, applies an optional
-- tooltip-frame whitelist, and returns a controller with :Destroy() and
-- :GetNativeHandles(). Two line-emitter helpers are provided as module-level
-- functions. TooltipDataProcessor has no public unregister API; :Destroy() disables
-- the registered callback in-place rather than removing it from the dispatch list.
--
-- Cross-flavor (FND-031): TooltipDataProcessor ships on Retail 10.0.2+, Classic
-- Era 1.15.x, and Pandaria Classic 5.5.x (verified in Blizzard source), so the
-- module works on every supported flavor. Availability is feature-detected at
-- :New and fails loud when genuinely absent; there is no OnTooltipSetItem
-- fallback (global tooltip hijacks are out of scope per Charter §3.3).

local F = _G.Foundry_1_0
if not F then
    error("Foundry-1.0: Tooltip.lua requires the Foundry-1.0 bootstrap (Foundry.lua) "
        .. "to have loaded first; _G.Foundry_1_0 is missing.", 0)
end
-- Guarded-embedding stand-down (§2.2b): if this module is already registered on the
-- winning copy, this is a redundant embedded copy — load nothing.
if F:HasModule("Tooltip") then return end

local Tooltip = {}
Tooltip.API_VERSION = 1

--------------------------------------------------------------------------------
-- Feature detection (checked at :New, never at file scope)
--------------------------------------------------------------------------------

local function hasTooltipDataProcessor()
    return type(_G.TooltipDataProcessor) == "table"
        and type(_G.TooltipDataProcessor.AddTooltipPostCall) == "function"
end

--------------------------------------------------------------------------------
-- Module-level live-key registry
-- Maps name string → true for every controller that has not been :Destroy()ed.
--------------------------------------------------------------------------------

local liveKeys = {}

--------------------------------------------------------------------------------
-- Per-type dispatchers (FND-029)
--
-- AddTooltipPostCall has no removal API: every registered callback runs
-- (through a taint-barrier securecallfunction) on every matching render for
-- the rest of the session, so one callback per controller would accumulate
-- permanent cost across New→Destroy→New cycles. Instead exactly ONE post-call
-- is registered per tooltip type for the module lifetime, dispatching into a
-- mutable list of live controllers -- Destroy actually stops the cost.
--
-- The dispatch loop is allocation-free and re-entrancy-safe: destroyed
-- controllers are swept lazily at their own loop position, so Destroy stays
-- O(1) and a handler destroying any controller mid-dispatch (itself included)
-- cannot corrupt the iteration.
--------------------------------------------------------------------------------

local dispatchers = {}   -- tooltipType → array of live controllers

local function ensureDispatcher(tooltipType)
    local list = dispatchers[tooltipType]
    if list then return list end
    list = {}
    -- Native call first, bookkeeping after (the FND-026 atomicity rule): if
    -- AddTooltipPostCall rejects, no dispatcher entry is recorded.
    _G.TooltipDataProcessor.AddTooltipPostCall(tooltipType, function(tooltip, data)
        local i = 1
        while i <= #list do
            local c = list[i]
            if c._destroyed then
                table.remove(list, i)
            else
                if not c._filter or c._filter[tooltip] then
                    c._handler(tooltip, data)
                end
                i = i + 1
            end
        end
    end)
    dispatchers[tooltipType] = list
    return list
end

--------------------------------------------------------------------------------
-- Line emitters (module-level helpers)
--
-- Thin convenience wrappers for the two patterns consumers repeat most often.
-- Both operate directly on the tooltip argument passed by TooltipDataProcessor.
--------------------------------------------------------------------------------

-- Add a line to the tooltip. r, g, b default to 1, 1, 1 (white) when omitted.
function Tooltip.AddLine(tooltip, text, r, g, b)
    tooltip:AddLine(text, r or 1, g or 1, b or 1)
end

-- Add a blank separator line. Standard inter-section visual gap.
function Tooltip.AddSeparator(tooltip)
    tooltip:AddLine(" ")
end

--------------------------------------------------------------------------------
-- Controller
--------------------------------------------------------------------------------

local Controller = {}
Controller.__index = Controller

local function refuseIfDestroyed(self, method)
    if self._destroyed then
        F:RaiseDevError("Tooltip:" .. method .. " called on a destroyed controller")
        return true
    end
    return false
end

-- Returns the raw Blizzard objects this controller was built against. A fresh
-- table is returned per call; mutating it does not corrupt controller state.
-- Keys: tooltipDataProcessor (the _G global at :New time), type (the registered
-- TooltipDataType number).
function Controller:GetNativeHandles()
    if refuseIfDestroyed(self, "GetNativeHandles") then return end
    return {
        tooltipDataProcessor = _G.TooltipDataProcessor,
        type                 = self._type,
    }
end

-- Marks the controller destroyed and frees the duplicate-refusal key. The
-- shared per-type dispatcher skips destroyed controllers and sweeps them from
-- its list on the next render of that type. Idempotent: a second :Destroy()
-- is a silent no-op.
function Controller:Destroy()
    if self._destroyed then return end
    liveKeys[self._name] = nil
    self._destroyed = true
    self._handler   = nil
    self._name      = nil
    self._filter    = nil
end

--------------------------------------------------------------------------------
-- Factory
--------------------------------------------------------------------------------

-- Create a tooltip post-call controller. Validation is atomic: every field is
-- checked before TooltipDataProcessor.AddTooltipPostCall is called. A rejected
-- :New leaves prior registrations untouched.
--
-- Config fields:
--   type     (required) — Enum.TooltipDataType value (a number).
--   handler  (required) — function(tooltip, data) called per matching tooltip.
--   tooltips (optional) — array of tooltip frame objects; the handler fires only
--                         when the incoming tooltip is one of them. nil fires for
--                         all tooltips of the registered type.
--   name     (optional, non-empty string) — duplicate-refusal key; defaults to
--                         tostring(type) when not supplied.
function Tooltip:New(config)
    if type(config) ~= "table" then
        F:RaiseDevError("Tooltip:New: config must be a table")
        return
    end

    local tooltipType = config.type
    if type(tooltipType) ~= "number" then
        F:RaiseDevError("Tooltip:New: config.type must be a number (Enum.TooltipDataType value)")
        return
    end

    local handler = config.handler
    if type(handler) ~= "function" then
        F:RaiseDevError("Tooltip:New: config.handler must be a function")
        return
    end

    local tooltips = config.tooltips
    local filter = nil
    if tooltips ~= nil then
        if type(tooltips) ~= "table" then
            F:RaiseDevError("Tooltip:New: config.tooltips must be an array of tooltip frames or nil")
            return
        end
        filter = {}
        for i = 1, #tooltips do
            local t = tooltips[i]
            if type(t) ~= "table" then
                F:RaiseDevError("Tooltip:New: config.tooltips[" .. i
                    .. "] must be a tooltip frame (table)")
                return
            end
            filter[t] = true
        end
    end

    local name = config.name
    if name ~= nil then
        if type(name) ~= "string" or name == "" then
            F:RaiseDevError("Tooltip:New: config.name must be a non-empty string when supplied")
            return
        end
    else
        name = tostring(tooltipType)
    end

    if liveKeys[name] then
        F:RaiseDevError("Tooltip:New: a live controller already owns the name '"
            .. name .. "'; :Destroy() it before re-registering")
        return
    end

    if not hasTooltipDataProcessor() then
        F:RaiseDevError("Tooltip:New: TooltipDataProcessor is not available on this client "
            .. "(it ships on Retail 10.0.2+, Classic Era 1.15.x, and Pandaria Classic "
            .. "5.5.x); Foundry.Tooltip is unavailable here")
        return
    end

    -- Construct before registering so the upvalue the callback closure
    -- captures is the fully-initialised controller.
    local c = setmetatable({}, Controller)
    c._type               = tooltipType
    c._handler            = handler
    c._filter             = filter
    c._name               = name
    c._destroyed          = false
    c._isTooltipController = true

    -- Join the per-type dispatcher (see FND-029 above): Destroy silences
    -- future deliveries without an unregister call. Sweep destroyed husks
    -- here too -- the dispatcher only sweeps on render, so New/Destroy
    -- cycles on a never-rendering type would otherwise grow unbounded.
    local list = ensureDispatcher(tooltipType)
    local i = 1
    while i <= #list do
        if list[i]._destroyed then table.remove(list, i) else i = i + 1 end
    end
    list[#list + 1] = c

    liveKeys[name] = true

    return c
end

F:RegisterModule("Tooltip", Tooltip)
