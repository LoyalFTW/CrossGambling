-- Foundry.Menu
--
-- A thin bridge over Blizzard's modern menu system (Blizzard_Menu / MenuUtil,
-- present on Retail 11.0+ and all Classic-family flavors). Encapsulates the
-- repeated MenuUtil.CreateContextMenu and dropdownButton:SetupMenu callsites
-- consumers carry by hand. Provides a named, lifecycle-tracked controller for
-- context menus and persistent dropdowns.
--
-- The consumer owns all menu content — the builder function receives the raw
-- Blizzard rootDescription and calls Create* methods directly. Foundry owns the
-- entry-point dispatch, the named-registration duplicate-refusal, and the
-- in-place destroy wrapper. MenuResponse is a Blizzard global; consumers access
-- it directly at runtime. Foundry.Menu does not alias or re-export it.
--
-- All flavors: MenuUtil is present on Retail 11.0+, Classic Era 1.15.x,
-- Pandaria Classic 5.5.x, and TBC Classic 2.5.x (confirmed via ui-toc-list.txt
-- manifests and active consumer callsites). No fallback path exists or is needed.

local F = _G.Foundry_1_0
if not F then
    error("Foundry-1.0: Menu.lua requires the Foundry-1.0 bootstrap (Foundry.lua) "
        .. "to have loaded first; _G.Foundry_1_0 is missing.", 0)
end
-- Guarded-embedding stand-down (§2.2b): if this module is already registered on the
-- winning copy, this is a redundant embedded copy — load nothing.
if F:HasModule("Menu") then return end

local Menu = {}
Menu.API_VERSION = 1

--------------------------------------------------------------------------------
-- Feature detection (checked at :New, never at file scope)
--------------------------------------------------------------------------------

local function hasMenuUtil()
    return type(_G.MenuUtil) == "table"
        and type(_G.MenuUtil.CreateContextMenu) == "function"
end

--------------------------------------------------------------------------------
-- Module-level live-key registry
-- Maps name string → true for every controller that has not been :Destroy()ed.
--------------------------------------------------------------------------------

local liveKeys = {}

--------------------------------------------------------------------------------
-- Anonymous-name counter
-- Incremented once per :New call that omits config.name. Never reused within a
-- session; named "F.Menu.anon.N" (1-based). Callers should not rely on the
-- counter value — the name is opaque and for duplicate-refusal only.
--------------------------------------------------------------------------------

local anonCounter = 0

--------------------------------------------------------------------------------
-- Controller
--------------------------------------------------------------------------------

local Controller = {}
Controller.__index = Controller

local function refuseIfDestroyed(self, method)
    if self._destroyed then
        F:RaiseDevError("Menu:" .. method .. " called on a destroyed controller")
        return true
    end
    return false
end

-- Opens a one-shot context menu anchored near owner. Extra args are forwarded
-- verbatim to the builder after rootDescription — matching Blizzard's convention
-- for MenuUtil.CreateContextMenu extra-args passthrough.
function Controller:CreateContextMenu(owner, ...)
    if refuseIfDestroyed(self, "CreateContextMenu") then return end
    _G.MenuUtil.CreateContextMenu(owner, self._generatorWrapper, ...)
end

-- Installs a persistent generator on a Blizzard DropdownButton frame. The same
-- generatorWrapper closure is reused; the _destroyed check fires on every open.
-- Calling :SetupDropdown on a destroyed controller raises via refuseIfDestroyed —
-- the loud path, distinct from the silent no-op when Blizzard fires an already-
-- installed wrapper on a destroyed controller.
function Controller:SetupDropdown(button)
    if refuseIfDestroyed(self, "SetupDropdown") then return end
    button:SetupMenu(self._generatorWrapper)
end

-- Marks the controller destroyed, frees the duplicate-refusal key, and disables
-- the registered wrapper in-place. Neither MenuUtil.CreateContextMenu nor
-- button:SetupMenu offers a public removal API; the _destroyed flag in the shared
-- closure is the designed teardown path — mirrors Tooltip exactly.
-- Idempotent: a second :Destroy() is a silent no-op.
-- Ordering: liveKeys clear MUST precede self._name = nil (ordering bug if reversed).
function Controller:Destroy()
    if self._destroyed then return end
    liveKeys[self._name] = nil
    self._destroyed = true
    self._builder          = nil
    self._name             = nil
    self._generatorWrapper = nil
end

-- Returns the raw Blizzard objects this controller was built against. A fresh
-- table is returned per call; mutating it does not corrupt controller state.
-- Keys: menuUtil (_G.MenuUtil), menu (_G.Menu — may be nil on clients where it
-- is absent; advisory). Consumers who need Menu.ModifyMenu or other raw APIs
-- access them here.
function Controller:GetNativeHandles()
    if refuseIfDestroyed(self, "GetNativeHandles") then return end
    return {
        menuUtil = _G.MenuUtil,
        menu     = _G.Menu,
    }
end

--------------------------------------------------------------------------------
-- Factory
--------------------------------------------------------------------------------

-- Create a menu controller. Validation is atomic: every field is checked before
-- any Blizzard API is called. A rejected :New leaves prior registrations untouched.
--
-- Config fields:
--   builder (required) — function(owner, rootDescription, ...) called every time
--                         the menu opens. Receives the owner and raw Blizzard
--                         rootDescription. Extra args forwarded from :CreateContextMenu.
--   name    (optional, non-empty string) — duplicate-refusal key; defaults to
--                         "F.Menu.anon.N" (N = module-level counter, never reused).
--                         Two live controllers with the same name are refused.
function Menu:New(config)
    if type(config) ~= "table" then
        F:RaiseDevError("Menu:New: config must be a table")
        return
    end

    local builder = config.builder
    if type(builder) ~= "function" then
        F:RaiseDevError("Menu:New: config.builder must be a function")
        return
    end

    local name = config.name
    if name ~= nil then
        if type(name) ~= "string" or name == "" then
            F:RaiseDevError("Menu:New: config.name must be a non-empty string when supplied")
            return
        end
    else
        anonCounter = anonCounter + 1
        name = "F.Menu.anon." .. anonCounter
    end

    if liveKeys[name] then
        F:RaiseDevError("Menu:New: a live controller already owns the name '"
            .. name .. "'; :Destroy() it before re-registering")
        return
    end

    -- Feature-detect MenuUtil last (house style): a consumer with a typo in
    -- builder sees the builder error, not a misleading "MenuUtil absent".
    if not hasMenuUtil() then
        F:RaiseDevError("Menu:New: MenuUtil is not available on this client; "
            .. "Foundry.Menu requires Blizzard_Menu (Retail 11.0+, Classic Era 1.15.x, "
            .. "TBC Classic 2.5.x, Pandaria Classic 5.5.x, or later)")
        return
    end

    -- generatorWrapper captures c by upvalue so :Destroy() (which sets
    -- c._destroyed) silences all future deliveries with no unregister call --
    -- identical to Tooltip's in-place disable pattern.
    local c = setmetatable({}, Controller)
    c._name      = name
    c._builder   = builder
    c._destroyed = false

    local function generatorWrapper(owner, rootDescription, ...)
        if c._destroyed then return end
        c._builder(owner, rootDescription, ...)
    end
    c._generatorWrapper = generatorWrapper

    liveKeys[name] = true

    return c
end

F:RegisterModule("Menu", Menu)
