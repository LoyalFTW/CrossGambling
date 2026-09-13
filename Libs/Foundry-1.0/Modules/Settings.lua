-- Foundry.Settings
--
-- A thin bridge over Blizzard's options-panel registration surface. One :New(config)
-- selects the correct registration path (modern Settings.* API or legacy
-- InterfaceOptions_AddCategory fallback) and returns a controller that owns the
-- registered Blizzard category object. Foundry owns only the registration and the
-- resulting category; the consumer owns the panel frame and all of its controls.

local F = _G.Foundry_1_0
if not F then
    error("Foundry-1.0: Settings.lua requires the Foundry-1.0 bootstrap (Foundry.lua) "
        .. "to have loaded first; _G.Foundry_1_0 is missing.", 0)
end
-- Guarded-embedding stand-down (§2.2b): if this module is already registered on the
-- winning copy, this is a redundant embedded copy — load nothing.
if F:HasModule("Settings") then return end

local Settings = {}
Settings.API_VERSION = 1

--------------------------------------------------------------------------------
-- Module-level live-key registry
-- Maps name string → true for every controller that has not been :Destroy()ed.
-- A second :New() with an already-owned key is refused. The key is freed only
-- when :Destroy() is called on the controller that owns it. Persists for the
-- module's lifetime (not cleared per-event or per-session).
--------------------------------------------------------------------------------

local liveKeys = {}

-- Registered-category cache (FND-032). Blizzard provides no way to unregister
-- an options category, so a name's first successful registration is permanent
-- for the session. A later :New for the same name re-binds the cached Blizzard
-- objects when the registration inputs match (same frame, title, mode, parent
-- category) -- the player keeps exactly one panel entry across
-- New/Destroy/New cycles -- and is refused when they differ, since the stuck
-- category can neither be reused for different inputs nor removed.
-- name -> { category, layout, frame, title, mode, parentCategory }
local registeredCategories = {}

--------------------------------------------------------------------------------
-- Path selection (feature detection, not version checks or pcall)
--------------------------------------------------------------------------------

-- Checked inside :New() and :Open() at runtime, never at file scope.
local function hasModernSettings()
    return type(_G.Settings) == "table"
        and type(_G.Settings.RegisterCanvasLayoutCategory) == "function"
        and type(_G.Settings.RegisterAddOnCategory) == "function"
end

local function hasLegacyOptions()
    return type(_G.InterfaceOptions_AddCategory) == "function"
end

--------------------------------------------------------------------------------
-- Controller
--------------------------------------------------------------------------------

local Controller = {}
Controller.__index = Controller

-- Shared destroyed-guard. Message form: "Settings:<Method> called on a destroyed
-- controller", matching the List/Events house style.
local function refuseIfDestroyed(self, method)
    if self._destroyed then
        F:RaiseDevError("Settings:" .. method .. " called on a destroyed controller")
        return true
    end
    return false
end

-- Opens the Blizzard settings panel to this controller's category.
-- Modern: Settings.OpenToCategory(categoryID) where categoryID is a number from
--   category:GetID(). Taint-safe from an insecure OnClick; no C_Timer defer needed.
-- Legacy: InterfaceOptionsFrame:OpenToCategory(self._frame), called TWICE to absorb
--   the first-call quirk where InterfaceAddOnsList_Update has not run yet.
-- Neither present: return false, "unsupported-open" (defensive dead code — :New
--   refuses construction when neither API is present, so a live controller always
--   has a valid mode and this branch cannot fire in practice).
function Controller:Open()
    if refuseIfDestroyed(self, "Open") then return end
    if self._mode == "settings" then
        _G.Settings.OpenToCategory(self._category:GetID())
    elseif self._mode == "interface-options" then
        _G.InterfaceOptionsFrame:OpenToCategory(self._frame)
        _G.InterfaceOptionsFrame:OpenToCategory(self._frame)
    else
        return false, "unsupported-open"
    end
end

-- Returns the numeric category ID usable with Settings.OpenToCategory.
-- Modern (root or child): self._category:GetID() → number.
-- Legacy: nil (no equivalent numeric ID exists on the legacy surface).
function Controller:GetCategoryID()
    if refuseIfDestroyed(self, "GetCategoryID") then return end
    if self._mode == "settings" then
        return self._category:GetID()
    end
    return nil
end

-- Returns a fresh table containing the live Blizzard objects this controller owns.
-- A fresh table is returned on every call; mutating the returned table does not
-- corrupt controller state. The objects inside are live references.
-- Keys: frame (panel frame), category (modern category object; nil legacy),
--       categoryID (number on modern; nil legacy), mode ("settings" or "interface-options").
function Controller:GetNativeHandles()
    if refuseIfDestroyed(self, "GetNativeHandles") then return end
    local categoryID = nil
    if self._mode == "settings" and self._category then
        categoryID = self._category:GetID()
    end
    return {
        frame      = self._frame,
        category   = self._category,
        categoryID = categoryID,
        mode       = self._mode,
        layout     = self._layout,
    }
end

-- Marks the controller destroyed, frees the duplicate-refusal key from the
-- module-level live registry, and releases internal references.
-- Idempotent: a second :Destroy() is a no-op (not an error).
-- Does NOT promise to unregister the Blizzard category — Blizzard provides no
-- reliable unregister API for addon categories.
function Controller:Destroy()
    if self._destroyed then return end
    liveKeys[self._name] = nil
    self._destroyed = true
    self._category  = nil
    self._frame     = nil
    self._name      = nil
end

--------------------------------------------------------------------------------
-- Factory
--------------------------------------------------------------------------------

-- Create a settings controller. Validation is atomic: every field is checked
-- before any Blizzard API is called. A rejected :New leaves prior registrations
-- untouched.
--
-- Config fields:
--   title  (required, non-empty string) — player-facing category title.
--   frame  (required, frame)            — the consumer-built panel to register.
--   parent (optional)                   — a live Foundry.Settings controller for
--                                         subcategory registration, or nil.
--   name   (optional, non-empty string) — duplicate-refusal key; defaults to title.
function Settings:New(config)
    if type(config) ~= "table" then
        F:RaiseDevError("Settings:New: config must be a table")
        return
    end

    local title = config.title
    if type(title) ~= "string" or title == "" then
        F:RaiseDevError("Settings:New: config.title must be a non-empty string")
        return
    end

    local frame = config.frame
    if type(frame) ~= "table" or type(frame.GetObjectType) ~= "function" then
        F:RaiseDevError("Settings:New: config.frame must be a WoW frame (table with GetObjectType)")
        return
    end

    local parent = config.parent
    if parent ~= nil then
        if type(parent) ~= "table"
            or not parent._isSettingsController
            or parent._destroyed
        then
            F:RaiseDevError("Settings:New: config.parent must be a live Foundry.Settings controller or nil")
            return
        end
    end

    local name = config.name
    if name ~= nil then
        if type(name) ~= "string" or name == "" then
            F:RaiseDevError("Settings:New: config.name must be a non-empty string when supplied")
            return
        end
    else
        name = title
    end

    if liveKeys[name] then
        F:RaiseDevError("Settings:New: a live controller already owns the name '"
            .. name .. "'; :Destroy() it before re-registering")
        return
    end

    local category
    local layout
    local mode

    -- Re-bind path (FND-032): this name already registered a Blizzard category
    -- this session. Reuse it when the inputs match; refuse when they differ.
    local cached = registeredCategories[name]
    if cached then
        local parentCategory = parent and parent._category or nil
        local mismatch = (cached.frame ~= frame and "frame")
            or (cached.title ~= title and "title")
            or (cached.parentCategory ~= parentCategory and "parent")
        if mismatch then
            F:RaiseDevError("Settings:New: name '" .. name .. "' already registered a "
                .. "Blizzard category this session with a different " .. mismatch
                .. "; categories cannot be unregistered, so a re-:New must reuse "
                .. "the same registration inputs")
            return
        end
        category, layout, mode = cached.category, cached.layout, cached.mode
    elseif hasModernSettings() then
        -- Modern path: feature-detected, no pcall (fail-loud per house style).
        if parent then
            -- On the modern path, the parent must also have been registered via the
            -- modern path so that parent._category is a valid Blizzard category
            -- object for RegisterCanvasLayoutSubcategory.
            if parent._mode ~= "settings" then
                F:RaiseDevError("Settings:New: config.parent was registered on the legacy path; "
                    .. "subcategory registration requires a modern-path parent")
                return
            end
            -- Guard against a structurally invalid parent (no category object).
            if type(parent._category) ~= "table" then
                F:RaiseDevError("Settings:New: config.parent has no valid category object")
                return
            end
            -- Child: RegisterCanvasLayoutSubcategory; do NOT call RegisterAddOnCategory.
            category, layout = _G.Settings.RegisterCanvasLayoutSubcategory(
                parent._category, frame, title)
        else
            -- Root: RegisterCanvasLayoutCategory + RegisterAddOnCategory (once only).
            category, layout = _G.Settings.RegisterCanvasLayoutCategory(frame, title)
            _G.Settings.RegisterAddOnCategory(category)
        end
        mode = "settings"
    elseif hasLegacyOptions() then
        -- Legacy path: InterfaceOptions_AddCategory reads frame.name for the sidebar
        -- label. The same call for both root and child (legacy does not support visual
        -- parent-child nesting; a child registers as a sibling). This branch is
        -- forward-compat insurance only — nil on all currently-runnable supported
        -- flavors (Classic Era 1.15.x, Pandaria Classic 5.5.x, Retail all expose
        -- modern Settings). Covered by headless test stub; no in-game verification path.
        _G.InterfaceOptions_AddCategory(frame)
        mode = "interface-options"
    else
        F:RaiseDevError("Settings:New: no supported options-registration API on this client")
        return
    end

    -- Record the permanent registration so a later same-name :New re-binds it
    -- instead of registering a duplicate (FND-032). A cached re-bind rewrites
    -- the identical record.
    registeredCategories[name] = {
        category       = category,
        layout         = layout,
        frame          = frame,
        title          = title,
        mode           = mode,
        parentCategory = parent and parent._category or nil,
    }

    local c = setmetatable({}, Controller)
    c._category            = category
    c._layout              = layout
    c._frame               = frame
    c._mode                = mode
    c._name                = name
    c._destroyed           = false
    c._isSettingsController = true

    liveKeys[name] = true

    return c
end

F:RegisterModule("Settings", Settings)
