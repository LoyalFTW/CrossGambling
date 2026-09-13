-- Foundry.Events
--
-- A thin registry over WoW's native frame-event system (CreateFrame("Frame"),
-- :RegisterEvent / :RegisterUnitEvent, and the OnEvent script). One controller
-- per consumer owns a single hidden frame and an event -> handler table, so
-- registration, dispatch, and teardown all live in one place. The native
-- primitive stays reachable underneath via :GetNativeHandles().
-- When C_EventUtils is available, invalid event names are refused before the
-- native call; clients without it retain native registration semantics.

local F = _G.Foundry_1_0
if not F then
    error("Foundry-1.0: Events.lua requires the Foundry-1.0 bootstrap (Foundry.lua) "
        .. "to have loaded first; _G.Foundry_1_0 is missing.", 0)
end
-- Guarded-embedding stand-down (§2.2b): if this module is already registered on the
-- winning copy, this is a redundant embedded copy — load nothing.
if F:HasModule("Events") then return end

local Events = {}
Events.API_VERSION = 2

--------------------------------------------------------------------------------
-- Controller
--------------------------------------------------------------------------------

local Controller = {}
Controller.__index = Controller

-- Modern clients can reject a retired event before the native registration
-- call. Keep the check at registration time so older clients without this API
-- retain the native throw-first behavior.
local function isEventValid(event)
    local eventUtils = _G.C_EventUtils
    return not eventUtils or not eventUtils.IsEventValid or eventUtils.IsEventValid(event)
end

-- Register a standard frame event. One handler per event: a duplicate is
-- rejected, leaving the existing registration unchanged. Validation is atomic
-- -- a rejected call mutates neither the handler table nor the native frame.
-- The native register runs BEFORE any bookkeeping: Midnight's RegisterEvent
-- throws on an unknown/removed event name, and that error must propagate with
-- the controller unchanged (no phantom IsRegistered, retry stays possible).
function Controller:Register(event, handler)
    if self._destroyed then
        F:RaiseDevError("Events:Register called on a destroyed controller")
        return
    end
    if type(event) ~= "string" or event == "" then
        F:RaiseDevError("Events:Register: event must be a non-empty string")
        return
    end
    if type(handler) ~= "function" then
        F:RaiseDevError("Events:Register: event '" .. event
            .. "' requires a handler function")
        return
    end
    if self._handlers[event] then
        F:RaiseDevError("Events:Register: event '" .. event
            .. "' is already registered; Unregister it first to replace the handler")
        return
    end
    if not isEventValid(event) then
        F:RaiseDevError("Events:Register: '" .. event .. "' is not a valid event on this client")
        return
    end

    self._frame:RegisterEvent(event)
    self._handlers[event] = handler
end

-- Register a unit-filtered frame event. Identical to :Register but subscribes
-- via frame:RegisterUnitEvent(event, unit1 [, unit2]). unit1 is required;
-- unit2 is optional. Validation is atomic.
function Controller:RegisterUnit(event, handler, unit1, unit2)
    if self._destroyed then
        F:RaiseDevError("Events:RegisterUnit called on a destroyed controller")
        return
    end
    if type(event) ~= "string" or event == "" then
        F:RaiseDevError("Events:RegisterUnit: event must be a non-empty string")
        return
    end
    if type(handler) ~= "function" then
        F:RaiseDevError("Events:RegisterUnit: event '" .. event
            .. "' requires a handler function")
        return
    end
    if type(unit1) ~= "string" or unit1 == "" then
        F:RaiseDevError("Events:RegisterUnit: event '" .. event
            .. "' requires unit1 to be a non-empty string")
        return
    end
    if unit2 ~= nil and (type(unit2) ~= "string" or unit2 == "") then
        F:RaiseDevError("Events:RegisterUnit: event '" .. event
            .. "' unit2, when supplied, must be a non-empty string")
        return
    end
    if self._handlers[event] then
        F:RaiseDevError("Events:RegisterUnit: event '" .. event
            .. "' is already registered; Unregister it first to replace the handler")
        return
    end
    if not isEventValid(event) then
        F:RaiseDevError("Events:RegisterUnit: '" .. event .. "' is not a valid event on this client")
        return
    end

    if unit2 ~= nil then
        self._frame:RegisterUnitEvent(event, unit1, unit2)
    else
        self._frame:RegisterUnitEvent(event, unit1)
    end
    self._handlers[event] = handler
end

-- Register a handler that auto-unregisters after its first fire, so it runs
-- exactly once. The auto-unregister happens BEFORE the consumer's handler is
-- invoked (ordering is fixed): the event slot is already free by the time the
-- handler runs, so a handler that re-registers the same event in its own body
-- behaves predictably.
function Controller:RegisterOnce(event, handler)
    if self._destroyed then
        F:RaiseDevError("Events:RegisterOnce called on a destroyed controller")
        return
    end
    if type(event) ~= "string" or event == "" then
        F:RaiseDevError("Events:RegisterOnce: event must be a non-empty string")
        return
    end
    if type(handler) ~= "function" then
        F:RaiseDevError("Events:RegisterOnce: event '" .. event
            .. "' requires a handler function")
        return
    end
    if self._handlers[event] then
        F:RaiseDevError("Events:RegisterOnce: event '" .. event
            .. "' is already registered; Unregister it first to replace the handler")
        return
    end
    if not isEventValid(event) then
        F:RaiseDevError("Events:RegisterOnce: '" .. event .. "' is not a valid event on this client")
        return
    end

    -- The wrapper unregisters before invoking, so the slot is free for any
    -- re-registration the handler performs in its own body.
    local function once(ev, ...)
        self:Unregister(ev)
        handler(ev, ...)
    end

    self._frame:RegisterEvent(event)
    self._handlers[event] = once
end

--------------------------------------------------------------------------------
-- Bucket (RegisterBucket)
--------------------------------------------------------------------------------

-- A bucket coalesces a burst of WoW events into a single delayed handler call,
-- the same settle-pattern Blizzard ships for some systems as a "_DELAYED"
-- event (e.g. BAG_UPDATE_DELAYED), for any event lacking a native twin.
--
-- SCOPE: a Blizzard-event-coalescing wrapper, NOT a general scheduler -- one
-- handler call per quiet-window, nothing more (no combat-gating,
-- debounce-by-key, or repeating ticker; those are C_Timer's).
--
-- HANDLE-based, not event-keyed: a multi-event bucket can't be keyed by a
-- single event name, so RegisterBucket returns a handle (:Cancel/:IsPending).
-- The bucket still occupies one handler slot per member event on the shared
-- frame, so the one-handler-per-event rule keeps holding: a later
-- Register/RegisterUnit/RegisterOnce (or another bucket) on an owned event is
-- refused by the existing self._handlers[event] duplicate check.
local Bucket = {}
Bucket.__index = Bucket

-- Whether a flush is currently scheduled. Pure read; safe after Cancel (always
-- false once cancelled). Intended for diagnostics and tests.
function Bucket:IsPending()
    return self._timer ~= nil
end

-- Cancel the bucket: unregister all its member events, cancel any pending flush,
-- and drop its controller bookkeeping. Idempotent -- a second Cancel (or a
-- Cancel after the controller already tore the bucket down via Destroy /
-- UnregisterAll) is a no-op. Cancel touches the controller's frame only while
-- the bucket is live, so it never reaches into a destroyed controller.
function Bucket:Cancel()
    if self._cancelled then return end
    local c = self._controller
    for _, event in ipairs(self._events) do
        c._handlers[event] = nil
        c._bucketEvents[event] = nil
        c._frame:UnregisterEvent(event)
    end
    -- Remove this handle from the controller's live bucket list.
    for i = #c._buckets, 1, -1 do
        if c._buckets[i] == self then
            table.remove(c._buckets, i)
            break
        end
    end
    self:_teardown()
end

-- Internal teardown shared by Cancel and by controller-level teardown
-- (Destroy / UnregisterAll). It cancels a pending flush timer and flips the
-- cancelled flag; it does NOT touch the native frame or the controller's bucket
-- list, because the two callers handle native unregistration differently
-- (Cancel per-event; Destroy/UnregisterAll via UnregisterAllEvents). Idempotent.
function Bucket:_teardown()
    if self._cancelled then return end
    self._cancelled = true
    self._deadline = nil
    if self._timer then
        self._timer:Cancel()
        self._timer = nil
    end
end

-- Register a bucket: coalesce a burst of one or more WoW events into a single
-- handler() call, fired once per quiet-window. spec fields:
--   events   -- a non-empty event-name string, OR an array of unique, non-empty
--               event-name strings.
--   interval -- the coalescing window in seconds (a number > 0).
--   edge     -- "leading" (DEFAULT) or "trailing"; nil means leading.
--   handler  -- the function called once per window, with NO arguments.
-- Returns a bucket HANDLE exposing :Cancel() and :IsPending().
--
-- Validation is atomic and mirrors Register/RegisterUnit: every check runs
-- and a rejected call mutates neither the handler table, the bucket
-- bookkeeping, nor the native frame. ALL member events are checked for a
-- prior registration BEFORE any event is registered, so a duplicate anywhere
-- in the list refuses the whole bucket cleanly.
function Controller:RegisterBucket(spec)
    if self._destroyed then
        F:RaiseDevError("Events:RegisterBucket called on a destroyed controller")
        return
    end
    if type(spec) ~= "table" then
        F:RaiseDevError("Events:RegisterBucket: spec must be a table")
        return
    end

    -- Normalize events to a list and validate shape: a non-empty string, or a
    -- non-empty array of non-empty, unique strings. Duplicates within the list
    -- are refused (they would map two slots to one event and corrupt teardown).
    local events = spec.events
    local list
    if type(events) == "string" then
        if events == "" then
            F:RaiseDevError("Events:RegisterBucket: events string must be non-empty")
            return
        end
        list = { events }
    elseif type(events) == "table" then
        if #events == 0 then
            F:RaiseDevError("Events:RegisterBucket: events array must be non-empty")
            return
        end
        local seen = {}
        list = {}
        for i = 1, #events do
            local ev = events[i]
            if type(ev) ~= "string" or ev == "" then
                F:RaiseDevError("Events:RegisterBucket: every event must be a non-empty string")
                return
            end
            if seen[ev] then
                F:RaiseDevError("Events:RegisterBucket: duplicate event '" .. ev
                    .. "' in the events array")
                return
            end
            seen[ev] = true
            list[#list + 1] = ev
        end
    else
        F:RaiseDevError("Events:RegisterBucket: events must be a string or an array of strings")
        return
    end

    -- A finite number > 0. The positive form also rejects NaN (NaN > 0 is false)
    -- and +inf (interval < math.huge is false): both would otherwise pass a "<= 0"
    -- check, then schedule a flush that never sensibly fires -- silently swallowing
    -- coalesced events while IsPending stays true, the opposite of failing loudly.
    if type(spec.interval) ~= "number"
        or not (spec.interval > 0 and spec.interval < math.huge) then
        F:RaiseDevError("Events:RegisterBucket: interval must be a finite number > 0")
        return
    end

    local edge = spec.edge
    if edge == nil then
        edge = "leading"
    elseif edge ~= "leading" and edge ~= "trailing" then
        F:RaiseDevError("Events:RegisterBucket: edge must be 'leading' or 'trailing' when supplied")
        return
    end

    if type(spec.handler) ~= "function" then
        F:RaiseDevError("Events:RegisterBucket: handler must be a function")
        return
    end

    -- Atomic duplicate check: refuse if ANY member event is already owned on this
    -- controller (by a plain handler, a once-wrapper, or another bucket) BEFORE
    -- registering any of them, so a rejected bucket leaves the frame untouched.
    for i = 1, #list do
        if self._handlers[list[i]] then
            F:RaiseDevError("Events:RegisterBucket: event '" .. list[i]
                .. "' is already registered; Unregister it (or Cancel its bucket) first")
            return
        end
    end

    -- Validate every member before the native loop, so a rejected bucket stays
    -- atomic even when an earlier member would otherwise be registered first.
    for i = 1, #list do
        if not isEventValid(list[i]) then
            F:RaiseDevError("Events:RegisterBucket: '" .. list[i]
                .. "' is not a valid event on this client")
            return
        end
    end

    local bucket = setmetatable({}, Bucket)
    bucket._controller = self
    bucket._events = list
    bucket._interval = spec.interval
    bucket._edge = edge
    bucket._handler = spec.handler
    bucket._timer = nil
    bucket._deadline = nil
    bucket._cancelled = false

    -- Hot-path locals, captured once per bucket (FND-033).
    local newTimer = C_Timer.NewTimer
    local getTime = GetTime

    -- Flush: clear the pending state BEFORE invoking handler (mirrors the
    -- RegisterOnce free-before-invoke order), so a handler that re-triggers a
    -- member event opens a fresh window safely and IsPending() reads false from
    -- inside the handler. Guarded against a stray post-teardown fire.
    --
    -- Trailing edge re-arms instead of delivering while the deadline is still
    -- ahead (FND-033): fires during the window only move bucket._deadline, so
    -- a storm allocates one timer per interval, not one per event, and no
    -- cancelled C-side timers pile up awaiting their expiry.
    local function flush()
        if bucket._cancelled then return end
        local deadline = bucket._deadline
        if deadline then
            local remaining = deadline - getTime()
            if remaining > 0 then
                bucket._timer = newTimer(remaining, flush)
                return
            end
        end
        bucket._timer = nil
        bucket._deadline = nil
        bucket._handler()
    end

    -- One shared OnFire closure across every member event. Leading: the first
    -- fire opens the window (creates the timer); fires while a flush is already
    -- pending are absorbed so the window is anchored to the FIRST fire.
    -- Trailing: every fire moves the deadline to now + interval, anchoring the
    -- window to the LAST fire -- the flush runs once the events go quiet for
    -- interval (delivery is the re-arming flush above, allocation-free per
    -- fire). handler receives NO arguments (no arg-aggregation).
    local function onFire()
        if bucket._cancelled then return end
        if edge == "leading" then
            if bucket._timer then return end
            bucket._timer = newTimer(bucket._interval, flush)
        else
            bucket._deadline = getTime() + bucket._interval
            if not bucket._timer then
                bucket._timer = newTimer(bucket._interval, flush)
            end
        end
    end

    -- Native-first with rollback (FND-027, pairing with FND-026's ordering
    -- rule): register every member event on the frame BEFORE any bookkeeping.
    -- If the client rejects a name mid-loop (Midnight throws on unknown or
    -- removed events), natively unregister the members that did register and
    -- rethrow -- the error propagates with the controller unchanged, never
    -- leaving live events wired to a bucket handle the caller never received.
    local registered = 0
    local ok, nativeErr = pcall(function()
        for i = 1, #list do
            self._frame:RegisterEvent(list[i])
            registered = i
        end
    end)
    if not ok then
        for i = 1, registered do
            self._frame:UnregisterEvent(list[i])
        end
        error(nativeErr, 0)
    end

    for i = 1, #list do
        self._handlers[list[i]] = onFire
        self._bucketEvents[list[i]] = bucket
    end
    self._buckets[#self._buckets + 1] = bucket

    return bucket
end

-- Remove the handler for one event and call the matching native unregister.
-- Idempotent: unregistering an event that is not registered is a no-op, not an
-- error.
function Controller:Unregister(event)
    if self._destroyed then
        F:RaiseDevError("Events:Unregister called on a destroyed controller")
        return
    end
    if type(event) ~= "string" or event == "" then
        F:RaiseDevError("Events:Unregister: event must be a non-empty string")
        return
    end
    if not self._handlers[event] then return end
    -- A bucket-owned event is not a plain handler: it shares an OnFire closure
    -- across the bucket's member events, so removing this one slot would leave a
    -- half-torn bucket. Refuse and point the caller at bucket:Cancel(), which
    -- tears the whole bucket down (events + pending flush) coherently.
    if self._bucketEvents[event] then
        F:RaiseDevError("Events:Unregister: event '" .. event
            .. "' is owned by a bucket; call bucket:Cancel() to remove it")
        return
    end
    self._handlers[event] = nil
    self._frame:UnregisterEvent(event)
end

-- Remove every handler this controller owns and call the native
-- UnregisterAllEvents. "Stop listening to everything I set up" in one call.
function Controller:UnregisterAll()
    if self._destroyed then
        F:RaiseDevError("Events:UnregisterAll called on a destroyed controller")
        return
    end
    -- Tear down every bucket first: cancel each pending flush timer and drop the
    -- bucket bookkeeping. We mark each bucket cancelled (rather than routing
    -- through bucket:Cancel(), which would re-issue per-event native unregisters
    -- that UnregisterAllEvents below makes redundant) so a later consumer
    -- bucket:Cancel() is an idempotent no-op.
    for i = #self._buckets, 1, -1 do
        self._buckets[i]:_teardown()
        self._buckets[i] = nil
    end
    for event in pairs(self._bucketEvents) do
        self._bucketEvents[event] = nil
    end
    for event in pairs(self._handlers) do
        self._handlers[event] = nil
    end
    self._frame:UnregisterAllEvents()
end

-- Whether this controller currently holds a handler for event. No side effects.
function Controller:IsRegistered(event)
    if self._destroyed then
        F:RaiseDevError("Events:IsRegistered called on a destroyed controller")
        return
    end
    return self._handlers[event] ~= nil
end

-- The progressive-disclosure escape hatch. Returns the live shared frame and a
-- shallow COPY (snapshot) of the event -> handler table. Mutating the snapshot
-- cannot affect live dispatch; the frame, by contrast, is the live object.
function Controller:GetNativeHandles()
    if self._destroyed then
        F:RaiseDevError("Events:GetNativeHandles called on a destroyed controller")
        return
    end
    local snapshot = {}
    for event, handler in pairs(self._handlers) do
        snapshot[event] = handler
    end
    return {
        frame = self._frame,
        handlers = snapshot,
    }
end

-- Tear down: unregister every event, clear the dispatch table, detach the
-- OnEvent script, hide and release the shared frame, mark destroyed. After
-- this, every controller method fails loudly (mirrors Commands).
function Controller:Destroy()
    if self._destroyed then
        F:RaiseDevError("Events:Destroy called on a destroyed controller")
        return
    end
    local frame = self._frame
    frame:UnregisterAllEvents()
    -- Cancel every bucket's pending flush so no timer survives teardown and
    -- leaks a callback into a destroyed controller. _teardown only cancels the
    -- timer + flips the bucket's cancelled flag; the native unregister is
    -- covered by UnregisterAllEvents above.
    for i = #self._buckets, 1, -1 do
        self._buckets[i]:_teardown()
        self._buckets[i] = nil
    end
    for event in pairs(self._bucketEvents) do
        self._bucketEvents[event] = nil
    end
    for event in pairs(self._handlers) do
        self._handlers[event] = nil
    end
    frame:SetScript("OnEvent", nil)
    frame:Hide()
    self._destroyed = true
end

--------------------------------------------------------------------------------
-- Factory
--------------------------------------------------------------------------------

-- Create a controller scoped to one consumer. owner is a stored identity label;
-- it is not read elsewhere (it does not name the frame, appear in diagnostics, or
-- scope :UnregisterAll, which is instance-scoped). Each call owns exactly one
-- hidden frame and one event -> handler table; no event is registered until the
-- first :Register.
function Events:New(owner)
    if type(owner) ~= "string" or owner == "" then
        F:RaiseDevError("Events:New: owner must be a non-empty string")
        return
    end

    local c = setmetatable({}, Controller)
    c._owner = owner
    c._handlers = {}
    -- Bucket bookkeeping (RegisterBucket). _bucketEvents maps an owned event ->
    -- its bucket handle, so Unregister can tell a bucket-owned event from a plain
    -- one; _buckets is the live list teardown iterates to cancel pending timers.
    c._bucketEvents = {}
    c._buckets = {}
    c._destroyed = false

    local frame = CreateFrame("Frame")
    frame:Hide()
    c._frame = frame

    -- One OnEvent script for all of this controller's events. It dispatches by
    -- event name to the stored handler and drops the native frame self, calling
    -- handler(event, ...). A fire for an event with no live handler is ignored
    -- (the handler table is the source of truth; the frame can momentarily
    -- carry an event that is mid-teardown).
    frame:SetScript("OnEvent", function(_, event, ...)
        local handler = c._handlers[event]
        if handler then
            handler(event, ...)
        end
    end)

    return c
end

F:RegisterModule("Events", Events)
