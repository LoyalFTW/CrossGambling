-- Foundry-1.0 bootstrap.
--
-- The single entry point that establishes the Foundry namespace. It creates
-- _G.Foundry_1_0, derives IS_DEV_BUILD and VERSION from the v1.0.105
-- packaging token, sets API_VERSION, provides the shared fail-loud helper, and
-- establishes module registration and access. It registers no events, touches
-- no SavedVariables, and depends on none of the modules.

local ADDON_NAME = ...

-- Built by concatenation so the literal token never appears in this file: the
-- BigWigs/CurseForge packager substitutes it across ALL packaged files, not
-- just the TOC, so a contiguous sentinel here would itself get rewritten at
-- package time -- a packaged release would then read as a dev build.
local VERSION_TOKEN = "@" .. "project-version" .. "@"
local DEV_VERSION = "dev"

-- 1. Read the version the packager wrote into the TOC (C_AddOns.GetAddOnMetadata;
--    the bare GetAddOnMetadata global routes to it). Unpackaged source still
--    returns the literal token, since the packager never ran.
local tocVersion = C_AddOns and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

-- 2. Dev-build detection: an unsubstituted token or missing version means a dev
--    copy. _G.FOUNDRY_DEV_BUILD_OVERRIDE (set in consumer code before this file
--    loads) forces dev on for local testing without risking a shipped release
--    reading as dev-on. The release-pipeline sanity check guards the inverse
--    case: a pipeline that ships the literal token.
local override = _G.FOUNDRY_DEV_BUILD_OVERRIDE
local isDevBuild = (tocVersion == nil)
    or (tocVersion == VERSION_TOKEN)
    or (override ~= nil and override ~= false)

local F = {}
F.IS_DEV_BUILD = isDevBuild
F.VERSION = isDevBuild and DEV_VERSION or tocVersion
F.SOURCE = ADDON_NAME
F.API_VERSION = 6
F._LOAD_TOKEN = {}   -- per-load identity token (guarded-embed §2.2c)

-- 3. Shared fail-loud helper: dev build raises so the author sees it
--    immediately; release build prints and returns, leaving the caller to
--    refuse rather than raise into a player's session. Neither path swallows
--    the condition.
function F:RaiseDevError(message)
    message = "Foundry-1.0: " .. tostring(message)
    if self.IS_DEV_BUILD then
        error(message, 2)
    else
        print(message)
    end
end

-- 4. Module registry and access. Modules register themselves as they load
--    (this bootstrap loads first per the TOC). Consumers reach a module
--    directly (F.Commands), or defensively via :HasModule / :RequireModule.
local modules = {}

function F:RegisterModule(name, module)
    if type(name) ~= "string" or name == "" then
        self:RaiseDevError("RegisterModule: name must be a non-empty string")
        return
    end
    if modules[name] then
        self:RaiseDevError("RegisterModule: module '" .. name .. "' is already registered")
        return
    end
    modules[name] = module
    self[name] = module
    return module
end

function F:HasModule(name)
    return modules[name] ~= nil
end

function F:RequireModule(name, minApiVersion)
    local module = modules[name]
    if not module then
        error("Foundry-1.0: required module '" .. tostring(name)
            .. "' is not present in this build.", 2)
    end
    if minApiVersion ~= nil then
        local level = module.API_VERSION or 0
        if level < minApiVersion then
            error(("Foundry-1.0: module '%s' is API version %d, but the caller requires at least %d.")
                :format(name, level, minApiVersion), 2)
        end
    end
    return module
end

-- 5. Bootstrap gate: if a copy of this major version already claimed the runtime
--    symbol, this copy must NOT overwrite it -- first-loaded wins, later copies
--    load nothing. Overwriting would create a second live instance (split-brain
--    dispatcher; double DB logout strip = save corruption). §2.2a + §2.3.
local existing = _G.Foundry_1_0
if existing then
    -- Dev-build diagnostics (noise tuning, not graft protection -- DB.lua's
    -- own graft-guard covers that). An enabled DevBuild reports if a release
    -- winner suppresses it; dev-winner diagnostics remain gated on API_VERSION
    -- skew so identical multi-embed dev setups stay silent. The
    -- _LOAD_TOKEN inequality is constant-true -- a fresh token is minted per
    -- chunk execution, so two loads never share one -- and the field is kept
    -- only as the §2.2c per-load identity marker (FND-036). Suppression rests
    -- entirely on the API_VERSION check; do not relax it expecting the token
    -- comparison to filter anything.
    if F.IS_DEV_BUILD and not existing.IS_DEV_BUILD then
        existing:RaiseDevError("an enabled Foundry-1.0 DevBuild was suppressed; "
            .. "the first-loaded release copy (version " .. tostring(existing.VERSION)
            .. ") is serving and this DevBuild loaded nothing")
    elseif existing.IS_DEV_BUILD and existing._LOAD_TOKEN ~= F._LOAD_TOKEN
        and existing.API_VERSION ~= F.API_VERSION then
        existing:RaiseDevError("a redundant embedded Foundry-1.0 copy was suppressed; "
            .. "the first-loaded copy (API_VERSION " .. tostring(existing.API_VERSION)
            .. ") is serving and this copy (API_VERSION " .. tostring(F.API_VERSION)
            .. ") loaded nothing")
    end
    return
end

-- 6. Publish under the major-version-qualified global. There
--    is no plain _G.Foundry; consumers bind _G.Foundry_1_0 explicitly.
_G.Foundry_1_0 = F
