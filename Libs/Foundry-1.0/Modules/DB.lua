-- Foundry.DB
--
-- The AceDB-3.0 replacement: load a consumer's SavedVariables, apply the
-- consumer's defaults, run registered migrations, expose the live section tables
-- (profile / char / global / sv), and strip default-equal values back out at
-- logout -- for exactly the two storage shapes the committed consumers have on
-- disk. It changes the MACHINERY behind existing save files, never the SHAPE of
-- the data on disk. This is the highest-risk module in the library: save-file
-- bugs are silent until a user's data is already gone, so every guard here
-- prefers a refused operation over a half-completed one, in every build.
--
-- Clean-room: behavior-compatible with AceDB-3.0, no AceDB code reproduced.

local F = _G.Foundry_1_0
if not F then
    error("Foundry-1.0: DB.lua requires the Foundry-1.0 bootstrap (Foundry.lua) "
        .. "to have loaded first; _G.Foundry_1_0 is missing.", 0)
end
-- Guarded-embedding stand-down (§2.2b): if this module is already registered on the
-- winning copy, this is a redundant embedded copy — load nothing.
if F:HasModule("DB") then return end

-- Graft-guard (FND-007 #1). The bootstrap gate above protects against a
-- redundant copy of THE SAME core, but not this cross-version graft: TOC load
-- order is Foundry -> Commands -> Events -> Lifecycle -> DB -> List, so a
-- consumer embedding a NEWER Foundry when an OLDER standalone already won
-- _G.Foundry_1_0 runs this newer DB.lua against the OLD core, which has no DB
-- module and no post-logout seam. Grafting would defer the failure to a
-- cryptic "_RegisterPostLogout (a nil value)" deep in :New.
--
-- Feature-detect the exact seam DB needs (the function itself, not an
-- API_VERSION number, so the check can't drift and tolerates a core with no
-- Lifecycle at all) and stand down if absent: a clear load-time error plus an
-- absent F.DB beats a cryptic deep crash mid-session. Provably inert on the
-- normal load, since Lifecycle always loads before DB.
if type(F.Lifecycle) ~= "table"
    or type(F.Lifecycle._RegisterPostLogout) ~= "function" then
    F:RaiseDevError("DB requires Lifecycle's post-logout seam "
        .. "(F.Lifecycle._RegisterPostLogout), which the Foundry core serving this "
        .. "session does not provide. This embedded Foundry is " .. tostring(F.VERSION)
        .. " (API_VERSION " .. tostring(F.API_VERSION) .. "), but an older standalone "
        .. "Foundry addon won the runtime and is serving everyone. Update the standalone "
        .. "Foundry addon to at least this version. DB is unavailable this session.")
    return
end
if type(F.Events) ~= "table" or type(F.Events.New) ~= "function" then
    F:RaiseDevError("DB requires Foundry.Events, which the Foundry core serving this "
        .. "session does not provide. This embedded Foundry is " .. tostring(F.VERSION)
        .. " but an older standalone Foundry addon won the runtime. Update the "
        .. "standalone Foundry addon to at least this version. DB is unavailable this session.")
    return
end

local DB = {}
DB.API_VERSION = 2

--------------------------------------------------------------------------------
-- Shared private state (one set of upvalues per loaded library, lazy)
--------------------------------------------------------------------------------

-- live (un-Destroyed) controllers keyed by sv name -- backs the one-live-per-sv
-- rejection. A Destroyed controller releases its slot so a later :New may reuse it.
local liveControllers = {}

-- Live controllers by owning addon name, in DB construction order. One addon
-- may own more than one SavedVariables global, while the client warning names
-- only the addon; notify every live DB that belongs to that addon.
local liveControllersByAddon = {}

-- Controller -> store association, held OFF the controller in a file-local
-- side table (Defect 2). The store must NOT live at a present controller
-- field like `c._store`: Lua 5.1 __newindex fires only on ABSENT keys, so a
-- present `_store` lets `db._store = x` raw-overwrite the live store pointer
-- and the underscore write-guard never fires. Keyed off the side table, the
-- controller carries ZERO present fields, so __index/__newindex see EVERY
-- access and the guards stay enforceable for its whole life. GC is a
-- non-issue: every store is already retained for the session in `stores`
-- (it backs the logout strip), so a weak table would buy nothing here.
local controllerStore = {}

-- EVERY store constructed this session, in construction order. A "store" is a
-- plain record capturing the sv name, the resolved sv table, the defaults table,
-- and the per-section materialization flags -- everything the logout strip needs,
-- independent of whether a live controller still exists. Live, Destroyed, and
-- §8.2 step-6 refused stores all land here; at logout the newest store per sv
-- table strips (FND-030; see onLogout for the rule and its rationale).
local stores = {}

-- One-time guard: DB registers its single strip callback with Lifecycle's
-- post-logout seam exactly once, at the first :New.
local postLogoutRegistered = false

-- DB owns one library-scoped listener for the client warning. It is created on
-- the first DB so there is no frame at all for consumers that do not use DB.
local sizeWarningEvents = nil

-- The three managed section names and the SV sub-tables they live under. char
-- and profile are keyed maps; global is flat (no key layer).
local SECTION_GLOBAL = "global"
local SECTION_PROFILE = "profile"
local SECTION_CHAR = "char"

-- AceDB surface neither committed consumer uses (spec §5). Reads against these
-- names fail loudly through the controller __index; writes fail through
-- __newindex. Method stubs (below) cover the call surface. Stored in a set for
-- O(1) membership; the value is unused.
local DENY_LIST = {
    -- Section accessors (unsupported sections)
    realm = true, class = true, race = true, faction = true,
    factionrealm = true, factionrealmregion = true, locale = true,
    -- Object properties
    profiles = true, keys = true, defaults = true, parent = true, children = true,
    callbacks = true,
    -- Profile management
    SetProfile = true, GetProfiles = true, GetCurrentProfile = true,
    CopyProfile = true, DeleteProfile = true, ResetProfile = true, ResetDB = true,
    -- Defaults / namespaces / callbacks APIs
    RegisterDefaults = true, RegisterNamespace = true, GetNamespace = true,
    RegisterCallback = true, UnregisterCallback = true, UnregisterAllCallbacks = true,
}

-- Reserved controller field names (spec §2.2): the section properties, the
-- supported method names, and (handled separately) all underscore-prefixed
-- fields. Writes to any of these fail through __newindex.
local RESERVED = {
    profile = true, char = true, global = true, sv = true,
    OnReady = true, OnSavedVariablesTooLarge = true, GetNativeHandles = true, Destroy = true,
}

local REFERENCE_TAIL = "; see the DB Reference page"

-- Direct both-builds refusal (locked decision D3, Charter §3.4.1). For every
-- condition with NO checked-return refusal path -- :New validation, the §5
-- deny-list, destroyed-controller SECTION reads, and migrate-raised surfacing
-- -- the raise IS the release refusal: the same named error fires identically
-- in dev and release. F:RaiseDevError (dev raise / release print+nil) is
-- reserved for the one class whose release contract is print+return nil:
-- destroyed-controller METHOD calls (§7 row 6). Level 3 points at the
-- consumer's call site (1 = refuse itself, 2 = the calling :New/__index/
-- __newindex, 3 = the consumer line that triggered it).
local function refuse(msg)
    error("Foundry-1.0: " .. tostring(msg), 3)
end

local function onSavedVariablesTooLarge(_, addonName)
    local controllers = liveControllersByAddon[addonName]
    if not controllers then return end
    local svNames, callbackFailed, callbackErr = {}, false, nil
    -- Snapshot recipients and their handlers before invoking consumer code. A
    -- callback may Destroy() a DB or register another handler; the snapshot
    -- preserves the complete dispatch set at signal entry. Destroy affects a
    -- later client warning, not the callbacks already captured for this one.
    local snapshot = {}
    for i = 1, #controllers do
        local controller = controllers[i]
        local store = controllerStore[controller]
        local handlers = {}
        if store and not store.destroyed then
            for j = 1, #store.sizeWarningHandlers do
                handlers[j] = store.sizeWarningHandlers[j]
            end
            svNames[#svNames + 1] = store.svName
        end
        snapshot[i] = { controller = controller, store = store, handlers = handlers }
    end
    for i = 1, #snapshot do
        local recipient = snapshot[i]
        local controller, store = recipient.controller, recipient.store
        if store then
            for j = 1, #recipient.handlers do
                local handler = recipient.handlers[j]
                local ok, err = pcall(handler, controller, addonName, store.svName)
                if not ok then
                    if not callbackFailed then callbackErr = err end
                    callbackFailed = true
                end
            end
        end
    end
    if #svNames > 0 then
        local message = "DB: addon '" .. addonName .. "' SavedVariables globals '"
            .. table.concat(svNames, "', '") .. "' were too large for the client to save"
        if callbackFailed then
            message = message .. "; a size-warning callback errored: " .. tostring(callbackErr)
        end
        F:RaiseDevError(message)
    end
end

local function registerSizeWarning()
    if sizeWarningEvents then return end
    sizeWarningEvents = F.Events:New("Foundry.DB")
    sizeWarningEvents:Register("SAVED_VARIABLES_TOO_LARGE", onSavedVariablesTooLarge)
end

--------------------------------------------------------------------------------
-- Defaults application, stripping, and helpers
--------------------------------------------------------------------------------

-- Recursively reject any wildcard ('*' / '**') string key at any depth in a
-- defaults table. Both consumers declare only concrete keys; wildcard semantics
-- are unsupported (spec §4.5). Returns the offending key path, or nil if clean.
local function findWildcard(tbl, pathPrefix)
    for k, v in pairs(tbl) do
        if k == "*" or k == "**" then
            return pathPrefix .. tostring(k)
        end
        if type(v) == "table" then
            local found = findWildcard(v, pathPrefix .. tostring(k) .. ".")
            if found then return found end
        end
    end
    return nil
end

-- Apply concrete defaults into a stored section table (spec §4.1). Mutates
-- `stored` in place; never reads from or writes into `defaults` (held by
-- reference). Type-mismatch slots are preserved-and-skipped (D2) and reported
-- through onMismatch(path) so the caller can emit one loud dev diagnostic.
--
-- nil-vs-false is load-bearing: a scalar default lands ONLY into a raw-nil slot
-- (rawequal-to-nil), never via a truthiness test, so a stored `false` always
-- beats a default `true`.
local function applyDefaults(stored, defaults, onMismatch, path)
    for k, dv in pairs(defaults) do
        local sv = stored[k]
        if type(dv) == "table" then
            if sv == nil then
                local fresh = {}
                stored[k] = fresh
                applyDefaults(fresh, dv, onMismatch, path .. tostring(k) .. ".")
            elseif type(sv) == "table" then
                -- Additive backfill: recurse, applying missing keys only.
                applyDefaults(sv, dv, onMismatch, path .. tostring(k) .. ".")
            else
                -- Stored non-table, non-nil under a table default: preserve the
                -- stored value, skip the default subtree (D2), report once.
                if onMismatch then onMismatch(path .. tostring(k)) end
            end
        else
            -- Scalar default: fill a raw-nil slot only. A stored value of ANY
            -- type (including false) is left untouched.
            if sv == nil then
                stored[k] = dv
            end
        end
    end
end

-- Strip default-equal values out of a materialized section table (spec §4.3
-- step 1). Mutates `stored` in place. A stored scalar raw-equal to its default
-- is removed; a table default recurses; a stored table left empty after
-- recursion is removed. Type-mismatched slots (stored non-table under a table
-- default) are left untouched -- they were never defaulted.
local function stripDefaults(stored, defaults)
    for k, dv in pairs(defaults) do
        local sv = stored[k]
        if type(dv) == "table" then
            if type(sv) == "table" then
                stripDefaults(sv, dv)
                if next(sv) == nil then
                    stored[k] = nil
                end
            end
            -- stored nil or a non-table scalar (type mismatch): leave as-is.
        else
            if sv == dv then
                stored[k] = nil
            end
        end
    end
end

-- Parse a dot-path ("global.schemaVersion") into { "global", "schemaVersion" }.
local function splitPath(path)
    local parts = {}
    for piece in tostring(path):gmatch("[^.]+") do
        parts[#parts + 1] = piece
    end
    return parts
end

--------------------------------------------------------------------------------
-- The logout strip (rides Lifecycle's post-logout seam)
--------------------------------------------------------------------------------

-- Strip one store. Idempotent over concrete defaults, so a repeated
-- post-logout seam re-stripping the newest store is safe. Reads only the
-- captured refs, never a controller, so it runs for live, Destroyed, and
-- refused stores alike (newest-per-sv selection happens in onLogout).
local function stripStore(store)
    local sv = store.sv
    if type(sv) ~= "table" then return end
    local defaults = store.defaults

    -- Step 1: defaults walk -- MATERIALIZED sections only. An unmaterialized
    -- section had no defaults applied, so there is nothing to strip.
    if defaults then
        if store.materialized[SECTION_GLOBAL] and type(sv.global) == "table"
            and type(defaults.global) == "table" then
            stripDefaults(sv.global, defaults.global)
        end
        if store.materialized[SECTION_PROFILE] and defaults.profile
            and type(defaults.profile) == "table"
            and type(sv.profiles) == "table"
            and type(sv.profiles[store.profileKey]) == "table" then
            stripDefaults(sv.profiles[store.profileKey], defaults.profile)
        end
        if store.materialized[SECTION_CHAR] and defaults.char
            and type(defaults.char) == "table"
            and type(sv.char) == "table"
            and type(sv.char[store.charKey]) == "table" then
            stripDefaults(sv.char[store.charKey], defaults.char)
        end
    end

    -- Step 2: prune empties -- scope is SV-PRESENCE, not materialization. Every
    -- managed keyed section present in the SV is swept even if never read this
    -- session, so a stale empty bucket in the file is pruned exactly as AceDB
    -- pruned it. EXCEPTION: empty named profiles on the main DB survive as {}
    -- (AceDB's deliberate asymmetry), so `profiles` per-key buckets are NOT
    -- pruned. `global` (flat) has no per-key layer.
    if type(sv.char) == "table" then
        for key, bucket in pairs(sv.char) do
            if type(bucket) == "table" and next(bucket) == nil then
                sv.char[key] = nil
            end
        end
    end

    -- Empty section tables are removed, including an empty `global`. `profiles`
    -- is NOT removed when it still holds an empty named profile (the asymmetry):
    -- a non-empty `profiles` section is never removed, and step 1 never empties
    -- the profile bucket itself out of `profiles`.
    if type(sv.global) == "table" and next(sv.global) == nil then
        sv.global = nil
    end
    if type(sv.char) == "table" and next(sv.char) == nil then
        sv.char = nil
    end
    if type(sv.profiles) == "table" and next(sv.profiles) == nil then
        sv.profiles = nil
    end

    -- Step 3: profileKeys always survives with the character's mapping -- never
    -- pruned here. Step 4: anything DB does not manage (unknown top-level keys,
    -- unsupported leftover sections, dynamic keys) is untouched by construction:
    -- nothing above ever reaches outside global/char/profiles.
end

-- The single callback DB hands to Lifecycle's post-logout seam. Snapshot the
-- store list, then pcall-per-store so one store's strip error never starves
-- another's; surface once after the loop, gated on the RAISED flag (never the
-- error VALUE's truthiness -- the §3.4.1 falsy-error rule). A store registering
-- a new store mid-strip (via re-:New) is intentionally not in this snapshot.
--
-- Newest-store-per-sv rule (FND-030): only the LAST-constructed store for
-- each sv TABLE strips. A Destroyed store whose sv was re-:New'd with
-- CHANGED defaults must not strip: its stale defaults could delete a stored
-- value the user deliberately set that happens to equal an OLD default --
-- silent save-data deletion, the failure this module rules out. The newer
-- store's defaults are authoritative for that sv; the trade (spec §2.2
-- re-decided) is that a stale old-default value the user never touched now
-- freezes as ordinary data instead of being stripped -- wrong-but-safe, and
-- indistinguishable from a deliberate choice. The same exclusion applies with
-- IDENTICAL defaults when only materialization differs (the frozen section
-- strips on a later logout that materializes it there too). A Destroyed
-- store with NO successor still strips as before (skipping it would freeze
-- its own materialized defaults -- the phantom-deviation trap).
local function onLogout()
    local newest = {}
    for i = 1, #stores do newest[stores[i].sv] = stores[i] end
    local snapshot, n = {}, 0
    for i = 1, #stores do
        local s = stores[i]
        if newest[s.sv] == s then n = n + 1; snapshot[n] = s end
    end
    local raised, firstErr = false, nil
    for i = 1, n do
        local ok, err = pcall(stripStore, snapshot[i])
        if not ok and not raised then raised, firstErr = true, err end
    end
    if raised then
        F:RaiseDevError("DB: a store's logout strip errored: " .. tostring(firstErr))
    end
end

--------------------------------------------------------------------------------
-- Controller
--------------------------------------------------------------------------------

-- The controller is metatable-backed and NOT Mixin()-able (spec §2.2, D6). It is
-- held and accessed by reference. Sections are served through __index from an
-- internal per-controller cache (_sections) -- NEVER rawset onto the controller,
-- so __index keeps firing on absent keys and the deny-list / destroyed guards
-- stay enforceable for the controller's whole life. Section tables themselves
-- are the SV's own plain tables (no proxies, no metatables).

-- Materialize a section on first read: create the SV sub-table if missing, apply
-- that section's defaults, cache the result, and flag it materialized (so the
-- logout strip walks exactly the sections that were read). Returns the live
-- table (the SV's own), stable for the session.
local function materialize(store, section)
    local cache = store.sections
    local existing = cache[section]
    if existing ~= nil then return existing end

    local sv = store.sv
    local defaults = store.defaults
    local tbl, sectionDefaults

    if section == SECTION_GLOBAL then
        if type(sv.global) ~= "table" then sv.global = {} end
        tbl = sv.global
        sectionDefaults = defaults and defaults.global
    elseif section == SECTION_PROFILE then
        if type(sv.profiles) ~= "table" then sv.profiles = {} end
        if type(sv.profiles[store.profileKey]) ~= "table" then
            sv.profiles[store.profileKey] = {}
        end
        tbl = sv.profiles[store.profileKey]
        sectionDefaults = defaults and defaults.profile
    elseif section == SECTION_CHAR then
        if type(sv.char) ~= "table" then sv.char = {} end
        if type(sv.char[store.charKey]) ~= "table" then
            sv.char[store.charKey] = {}
        end
        tbl = sv.char[store.charKey]
        sectionDefaults = defaults and defaults.char
    end

    -- Flag and cache BEFORE applying defaults (FND-035): applyDefaults can
    -- raise mid-walk via onMismatch (dev builds), and an unflagged section
    -- whose defaults were already partially written would be skipped by the
    -- logout strip -- freezing fresh defaults onto disk as phantom user data,
    -- the exact trap the strip exists to prevent.
    cache[section] = tbl
    store.materialized[section] = true

    if type(sectionDefaults) == "table" then
        applyDefaults(tbl, sectionDefaults, store.onMismatch, section .. ".")
    end

    return tbl
end

-- Each controller's store lives in the file-local `controllerStore` side table
-- (declared up top), keyed by the controller and never as a controller field.

local Controller = {}

-- Methods are looked up by the metatable __index function (below), NOT via
-- Controller as a plain __index table, because we must intercept section names
-- and the deny-list first. Define the methods on Controller; __index dispatches
-- to them.

function Controller.OnReady(self, handler)
    local store = controllerStore[self]
    -- Non-controller value: a method extracted and invoked on a forged/foreign
    -- table (`local m = db.OnReady; m({})`) has no store mapping. Refuse with a
    -- NAMED message (raise both builds) rather than dying with the anonymous
    -- nil-index the named-message contract exists to eliminate. Distinct from the
    -- destroyed-controller path below (row 6): a destroyed controller still HAS a
    -- store, just flagged destroyed.
    if store == nil then
        refuse("DB:OnReady called on a non-controller value")
    end
    if store.destroyed then
        F:RaiseDevError("DB:OnReady called on a destroyed controller")
        return
    end
    if type(handler) ~= "function" then
        F:RaiseDevError("DB:OnReady: handler must be a function")
        return
    end
    -- The ready moment completed inside :New, so every registration is a
    -- synchronous catch-up. Multiple handlers are allowed; each runs once, now.
    handler(self)
end

-- Register a handler for the client's end-of-session SavedVariables size
-- warning. Unlike OnReady, this is event-driven: it runs only when the client
-- reports that this DB's owning addon could not be saved.
function Controller.OnSavedVariablesTooLarge(self, handler)
    local store = controllerStore[self]
    if store == nil then
        refuse("DB:OnSavedVariablesTooLarge called on a non-controller value")
    end
    if store.destroyed then
        F:RaiseDevError("DB:OnSavedVariablesTooLarge called on a destroyed controller")
        return
    end
    if type(handler) ~= "function" then
        F:RaiseDevError("DB:OnSavedVariablesTooLarge: handler must be a function")
        return
    end
    store.sizeWarningHandlers[#store.sizeWarningHandlers + 1] = handler
end

function Controller.GetNativeHandles(self)
    local store = controllerStore[self]
    -- Non-controller value: see Controller.OnReady.
    if store == nil then
        refuse("DB:GetNativeHandles called on a non-controller value")
    end
    if store.destroyed then
        F:RaiseDevError("DB:GetNativeHandles called on a destroyed controller")
        return
    end
    -- The live SV root is the consumer's own data (no Blizzard objects). charKey,
    -- profileKey, and the materialization state are SNAPSHOT copies; mutating
    -- them never affects live behavior. NO frame field: DB owns no event frame.
    local matSnapshot = {}
    for k, v in pairs(store.materialized) do matSnapshot[k] = v end
    return {
        sv = store.sv,
        charKey = store.charKey,
        profileKey = store.profileKey,
        materialized = matSnapshot,
    }
end

function Controller.Destroy(self)
    local store = controllerStore[self]
    -- Non-controller value: see Controller.OnReady.
    if store == nil then
        refuse("DB:Destroy called on a non-controller value")
    end
    if store.destroyed then
        F:RaiseDevError("DB:Destroy called on a destroyed controller")
        return
    end
    -- Release the controller surface and free the sv slot for a later :New.
    -- Never deletes or mutates saved data; the consumer's section references
    -- stay valid as fully-merged plain tables. The store's end-of-session
    -- strip duty SURVIVES this -- it stays in `stores` and still strips at
    -- logout -- UNLESS a later :New covers the same sv, in which case the
    -- newest store strips instead (FND-030; see onLogout).
    store.destroyed = true
    if liveControllers[store.svName] == self then
        liveControllers[store.svName] = nil
    end
    local byAddon = liveControllersByAddon[store.addonName]
    if byAddon then
        for i = #byAddon, 1, -1 do
            if byAddon[i] == self then
                table.remove(byAddon, i)
                break
            end
        end
        if #byAddon == 0 then
            liveControllersByAddon[store.addonName] = nil
        end
    end
    store.sizeWarningHandlers = {}
end

-- The controller metatable. __index: section names -> materialized section;
-- supported method names -> the method; deny-list names -> loud refusal (raise
-- in both builds, D3); destroyed section reads -> loud refusal; everything else
-- -> nil (plain Lua). __newindex: reserved + deny-list -> loud refusal; anything
-- else -> a plain raw set (exactly as on an AceDB db object).
local controllerMeta = {}

function controllerMeta.__index(self, key)
    local store = controllerStore[self]

    -- Section properties.
    if key == SECTION_GLOBAL or key == SECTION_PROFILE or key == SECTION_CHAR then
        if store.destroyed then
            -- A property read has no checkable nil-refusal path, so it raises in
            -- BOTH builds (spec §7 row 7, D3) -- never print+nil.
            refuse("DB: section '" .. key
                .. "' read on a destroyed controller")
        end
        return materialize(store, key)
    end

    -- db.sv: the live SavedVariables root (the unmerged store).
    if key == "sv" then
        if store.destroyed then
            refuse("DB: section 'sv' read on a destroyed controller")
        end
        return store.sv
    end

    -- Supported methods.
    local method = Controller[key]
    if method then return method end

    -- Unsupported AceDB surface read (spec §5): raise in both builds (D3) with a
    -- named message, never Lua's anonymous nil-index/nil-call.
    if DENY_LIST[key] then
        refuse("DB: AceDB feature '" .. key
            .. "' is not supported by Foundry.DB (Charter §3.4)" .. REFERENCE_TAIL)
    end

    -- Unknown name: plain Lua, nil read.
    return nil
end

function controllerMeta.__newindex(self, key, value)
    -- Reserved names (sections, supported methods) and the §5 deny-list both fail
    -- loudly in both builds (D3). The write guard is load-bearing: without it a
    -- stray `db.realm = {}` would rawset onto the controller, permanently shadow
    -- the deny-list for that key, and silently accept a session of writes against
    -- a table never connected to the SV -- the "build a broken table / drop data"
    -- class banned in every build.
    if RESERVED[key] or DENY_LIST[key]
        or (type(key) == "string" and key:sub(1, 1) == "_") then
        refuse("DB: '" .. tostring(key)
            .. "' is reserved or unsupported and cannot be assigned on the controller"
            .. REFERENCE_TAIL)
    end
    -- Unknown name: plain Lua, raw write (exactly as on an AceDB db object).
    rawset(self, key, value)
end

--------------------------------------------------------------------------------
-- Factory
--------------------------------------------------------------------------------

-- Validate a defaults table's top-level section names and reject wildcards.
-- Returns an error message string, or nil if valid.
local function validateDefaults(defaults)
    for k, v in pairs(defaults) do
        if k ~= SECTION_PROFILE and k ~= SECTION_CHAR and k ~= SECTION_GLOBAL then
            return "DB:New: defaults section '" .. tostring(k)
                .. "' is not supported; only 'profile', 'char', and 'global' are"
        end
        if type(v) ~= "table" then
            return "DB:New: defaults.'" .. tostring(k) .. "' must be a table"
        end
    end
    local wildcard = findWildcard(defaults, "")
    if wildcard then
        return "DB:New: wildcard default key '" .. wildcard
            .. "' is not supported by Foundry.DB (Charter §4.5)"
    end
    return nil
end

-- Resolve the running character's identity. Returns (charKey, errMessage): a nil
-- charKey with a message means the identity gate refused (computed lazily, never
-- at file load). nil / "" / "Unknown" all refuse before any mutation, so a junk
-- key ("nil - Realm", "Name - ", "Unknown - Realm") is never computed.
local function resolveCharKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if type(name) ~= "string" or name == "" or name == "Unknown" then
        return nil, "DB:New: player identity is not available yet (UnitName "
            .. "returned '" .. tostring(name) .. "'); construction refused"
    end
    if type(realm) ~= "string" or realm == "" or realm == "Unknown" then
        return nil, "DB:New: realm identity is not available yet (GetRealmName "
            .. "returned '" .. tostring(realm) .. "'); construction refused"
    end
    return name .. " - " .. realm, nil
end

-- Read the raw stored schema stamp (pre-defaults, the single read the seam ever
-- performs). The path is rooted at a supported section; we walk it without
-- materializing anything. Returns the raw value (may be nil or any type).
local function readRawStamp(sv, pathParts)
    local node = sv
    for i = 1, #pathParts do
        if type(node) ~= "table" then return nil end
        node = node[pathParts[i]]
    end
    return node
end

-- Write the schema stamp at schema.key, creating intermediate tables as needed.
-- Rooted at a supported section; the section is materialized through the
-- controller first by the caller so the write lands in the live section table.
local function writeStamp(sv, pathParts, value)
    local node = sv
    for i = 1, #pathParts - 1 do
        if type(node[pathParts[i]]) ~= "table" then
            node[pathParts[i]] = {}
        end
        node = node[pathParts[i]]
    end
    node[pathParts[#pathParts]] = value
end

function DB:New(config)
    -- 1. Config type checks (type errors surface before state errors).
    if type(config) ~= "table" then
        refuse("DB:New: config must be a table")
    end
    if type(config.name) ~= "string" or config.name == "" then
        refuse("DB:New: name must be a non-empty string")
    end
    if type(config.sv) ~= "string" or config.sv == "" then
        refuse("DB:New: sv must be a non-empty string")
    end
    if config.defaults ~= nil and type(config.defaults) ~= "table" then
        refuse("DB:New: defaults, when supplied, must be a table")
    end

    -- 2. defaultProfile must be the literal true (string / absent modes rejected).
    if config.defaultProfile ~= true then
        refuse("DB:New: defaultProfile must be the literal true; "
            .. "named-shared-profile and per-character-profile modes are not "
            .. "supported by Foundry.DB (Charter §2.1)")
    end

    -- 3. Defaults section names + wildcard scan.
    if config.defaults then
        local err = validateDefaults(config.defaults)
        if err then
            refuse(err)
        end
    end

    -- 4. schema validation (shape + key-vs-defaults collision, §8.2 step 0).
    local schema = config.schema
    local schemaPath
    if schema ~= nil then
        if type(schema) ~= "table" then
            refuse("DB:New: schema, when supplied, must be a table")
        end
        if type(schema.version) ~= "number" or schema.version <= 0
            or schema.version % 1 ~= 0 then
            refuse("DB:New: schema.version must be a positive integer")
        end
        if type(schema.key) ~= "string" or schema.key == "" then
            refuse("DB:New: schema.key must be a non-empty dot-path string")
        end
        if type(schema.migrate) ~= "function" then
            refuse("DB:New: schema.migrate must be a function")
        end
        schemaPath = splitPath(schema.key)
        local rootSection = schemaPath[1]
        -- Step 0 (root restriction): the stamp must be rooted EXACTLY at `global`.
        -- `char` and `profile` are keyed-MAP sections (sv.char maps charKeys to
        -- buckets), so a flat path like "char.schemaVersion" writes a scalar SIBLING
        -- of the per-character buckets inside the keyed map; the §8.4 structural
        -- check then rejects that scalar on every later load and construction
        -- refuses forever -- a permanent lockout from the user's own save. A
        -- keyed-section stamp has no coherent flat-path semantics, and both
        -- committed consumers stamp `global`, so the only legal root is `global`.
        if rootSection ~= SECTION_GLOBAL then
            refuse("DB:New: schema.key must be rooted at 'global' (got '"
                .. schema.key .. "'); char/profile are keyed sections")
        end
        -- The stamp needs a key BELOW the section root. A bare "global" passes
        -- the root check but makes writeStamp overwrite sv.global -- the section
        -- TABLE -- with the version NUMBER: this session's db.global writes
        -- orphan into the detached section cache and vanish at logout, and the
        -- §8.4 structural check then refuses the save on every later load --
        -- the same permanent-lockout class the root restriction above exists
        -- to prevent.
        if #schemaPath < 2 then
            refuse("DB:New: schema.key must name a key inside 'global' (got '"
                .. schema.key .. "'); a bare section root would overwrite the "
                .. "whole section with the version stamp")
        end
        -- Step 0: the stamp must NOT be covered by declared defaults. A
        -- defaults-covered stamp evaporates from disk whenever it equals its
        -- default (the strip deletes it), so migrate(db, nil) would run every
        -- session forever and downgrade protection would be permanently inert.
        if config.defaults then
            local node = config.defaults
            local covered = true
            for i = 1, #schemaPath do
                if type(node) ~= "table" then covered = false; break end
                node = node[schemaPath[i]]
                if node == nil then covered = false; break end
            end
            if covered then
                refuse("DB:New: schema.key '" .. schema.key
                    .. "' is covered by declared defaults; the logout strip would "
                    .. "delete the stamp whenever it equals its default. Remove the "
                    .. "stamp key from the defaults table before adopting the schema seam")
            end
        end
    end

    -- 5. One live controller per sv name.
    if liveControllers[config.sv] then
        refuse("DB:New: sv '" .. config.sv
            .. "' already has a live controller; Destroy it first to re-register")
    end

    -- 6. Timing guard: the addon must have FINISHED loading (SavedVariables
    -- restored). Gate on the SECOND return of IsAddOnLoaded. A too-early :New
    -- builds a fresh store that the real SV restoration then clobbers -- data loss.
    local loaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local _, finished = C_AddOns.IsAddOnLoaded(config.name)
        loaded = (finished == true)
    end
    if not loaded then
        refuse("DB:New: addon '" .. config.name
            .. "' has not finished loading; its SavedVariables are not yet "
            .. "available. Construct DB inside the addon-loaded window")
    end

    -- 7. Identity gate (nil / "" / "Unknown" all refuse before any mutation).
    local charKey, identityErr = resolveCharKey()
    if not charKey then
        refuse(identityErr)
    end

    -- 8. Read the existing SV global (RAW -- may be nil for a fresh save). The
    -- downgrade check below reads the stamp RAW, pre-defaults. Malformed
    -- structural checks run here, before any mutation.
    local existing = _G[config.sv]
    local freshSV = (existing == nil)
    if not freshSV then
        if type(existing) ~= "table" then
            refuse("DB:New: SavedVariables global '" .. config.sv
                .. "' is malformed (expected a table, got " .. type(existing)
                .. "); construction refused")
        end
        -- Structural malformation of managed sections / buckets / profileKeys.
        local malformed = nil
        if existing.profileKeys ~= nil and type(existing.profileKeys) ~= "table" then
            malformed = "profileKeys"
        elseif existing.profiles ~= nil and type(existing.profiles) ~= "table" then
            malformed = "profiles"
        elseif existing.char ~= nil and type(existing.char) ~= "table" then
            malformed = "char"
        elseif existing.global ~= nil and type(existing.global) ~= "table" then
            malformed = "global"
        end
        if not malformed and type(existing.profileKeys) == "table" then
            local pkv = existing.profileKeys[charKey]
            if pkv ~= nil and type(pkv) ~= "string" then
                malformed = "profileKeys['" .. charKey .. "']"
            end
        end
        if not malformed and type(existing.profiles) == "table" then
            for pk, pv in pairs(existing.profiles) do
                if type(pv) ~= "table" then
                    malformed = "profiles['" .. tostring(pk) .. "']"
                    break
                end
            end
        end
        if not malformed and type(existing.char) == "table" then
            for ck, cv in pairs(existing.char) do
                if type(cv) ~= "table" then
                    malformed = "char['" .. tostring(ck) .. "']"
                    break
                end
            end
        end
        if malformed then
            refuse("DB:New: SavedVariables '" .. config.sv
                .. "' is malformed at '" .. malformed
                .. "'; construction refused (the corrupt value is never overwritten)")
        end
    end

    -- 9. profileKey resolution (raw, pre-mutation): saved profileKeys[charKey]
    -- first, else "Default" (the normalized defaultProfile = true). Saved keys
    -- remain arbitrary strings and resolve exactly as AceDB resolved them.
    local profileKey = "Default"
    if not freshSV and type(existing.profileKeys) == "table" then
        local saved = existing.profileKeys[charKey]
        if type(saved) == "string" and saved ~= "" then
            profileKey = saved
        end
    end

    -- 10. Downgrade check -- part of validation, against the RAW pre-defaults
    -- stamp. Stored > declared ⇒ refuse construction, SV byte-untouched.
    local storedVersion
    if schema then
        storedVersion = readRawStamp(existing, schemaPath)  -- nil-safe (existing may be nil)
        if type(storedVersion) == "number" and storedVersion > schema.version then
            refuse("DB:New: stored schema version " .. storedVersion
                .. " is newer than this build's declared version " .. schema.version
                .. " (downgrade); construction refused, SavedVariables untouched")
        end
    end

    --==========================================================================
    -- VALIDATION COMPLETE. Every check above completed before this line. From
    -- here, and only here, do we mutate _G[config.sv] and library state. A
    -- rejected :New above left the SV byte-untouched (it did not even create a
    -- missing global).
    --==========================================================================

    if freshSV then
        _G[config.sv] = {}
    end
    local sv = _G[config.sv]

    -- profileKeys write-back: record the resolved mapping. Constructing a db is
    -- never read-only; both consumers' files carry profileKeys.
    if type(sv.profileKeys) ~= "table" then sv.profileKeys = {} end
    sv.profileKeys[charKey] = profileKey

    -- Build the store record (the strip's view of this db, controller-independent).
    local store = {
        addonName = config.name,
        svName = config.sv,
        sv = sv,
        defaults = config.defaults,
        charKey = charKey,
        profileKey = profileKey,
        sections = {},        -- section name -> live table (the cache)
        materialized = {},    -- section name -> true once a read begins (strip-owned; FND-035)
        sizeWarningHandlers = {},
        destroyed = false,
    }
    -- A loud dev diagnostic for each value-level type mismatch (D2 preserve-skip).
    store.onMismatch = function(slotPath)
        F:RaiseDevError("DB: stored value at '" .. slotPath
            .. "' has a type that conflicts with its table-typed default; the "
            .. "stored value is preserved and the default subtree is not applied")
    end

    stores[#stores + 1] = store

    -- Register DB's single logout-strip callback with Lifecycle's post-logout
    -- seam exactly once, at the first :New.
    if not postLogoutRegistered then
        F.Lifecycle._RegisterPostLogout(onLogout)
        postLogoutRegistered = true
    end

    -- Build the controller (metatable-backed; not Mixin()-able).
    local c = setmetatable({}, controllerMeta)
    controllerStore[c] = store
    liveControllers[config.sv] = c

    -- 11. Schema seam: run AFTER construction state exists but as part of :New, so
    -- the ready moment (defaults applied, migrations run) holds when :New returns.
    if schema then
        if freshSV then
            -- Fresh SV: stamp, migrate NOT called.
            local section = schemaPath[1]
            materialize(store, section)  -- ensure the rooted section is live
            writeStamp(sv, schemaPath, schema.version)
        elseif not (type(storedVersion) == "number" and storedVersion == schema.version) then
            -- Stored < declared, or nothing / a non-number: call migrate (stored
            -- == declared is a no-op, handled by skipping this branch). The
            -- consumer's nil path must be an idempotent repair: storedVersion is
            -- nil for a populated-but-unversioned save.
            --
            -- A PRESENT-but-non-number stamp bypasses §8.3's downgrade check (it
            -- only fires for a numeric stamp), so fire a loud dev diagnostic
            -- before proceeding: dev raises immediately; release prints and the
            -- nil-path migrate/repair proceeds unchanged (mv is nil either way;
            -- D2 onMismatch transport precedent).
            if storedVersion ~= nil and type(storedVersion) ~= "number" then
                F:RaiseDevError("DB:New: schema stamp at '" .. schema.key
                    .. "' is present but not a number (got a " .. type(storedVersion)
                    .. "); it bypasses the downgrade check by type and is treated as "
                    .. "unversioned -- migrate(db, nil) runs and the stamp is overwritten")
            end
            local mv = (type(storedVersion) == "number") and storedVersion or nil
            local ok, err = pcall(schema.migrate, c, mv)
            if not ok then
                -- A raised error (gated on the RAISED flag, never value
                -- truthiness) refuses construction -- a half-migrated store is
                -- never handed out. The store stays in `stores` so its
                -- (possibly partially-written) SV is still stripped at logout
                -- (by this store or a successor's, per the newest-per-sv rule).
                store.destroyed = true
                liveControllers[config.sv] = nil
                refuse("DB:New: schema.migrate raised; construction "
                    .. "refused (a half-migrated store is never handed out): "
                    .. tostring(err))
            end
            -- On normal return, stamp the declared version.
            local section = schemaPath[1]
            materialize(store, section)
            writeStamp(sv, schemaPath, schema.version)
        end
    end

    local byAddon = liveControllersByAddon[config.name]
    if not byAddon then
        byAddon = {}
        liveControllersByAddon[config.name] = byAddon
    end
    byAddon[#byAddon + 1] = c
    registerSizeWarning()

    return c
end

F:RegisterModule("DB", DB)
