--[[
    NovaUI - Event Emitter System
    File: client/events/emitter.lua
]]

NovaUI = NovaUI or {}

local EventEmitter = NovaUI.Class("EventEmitter")
NovaUI.EventEmitter = EventEmitter

function EventEmitter:init()
    self._listeners = {}
end

function EventEmitter:on(eventName, callback, priority)
    if type(eventName) ~= "string" or eventName == "" then
        NovaUI.warn("EventEmitter:on", "eventName must be a non-empty string")
        return self
    end
    if type(callback) ~= "function" then
        NovaUI.warn("EventEmitter:on('" .. eventName .. "')", "callback must be a function")
        return self
    end
    self._listeners = self._listeners or {}
    local list = self._listeners[eventName]
    if not list then
        list = {}
        self._listeners[eventName] = list
    end
    local entry = {
        fn = callback,
        once = false,
        priority = tonumber(priority) or 0,
    }
    table.insert(list, entry)
    if #list > 1 and entry.priority ~= 0 then
        table.sort(list, function(a, b) return a.priority > b.priority end)
    end
    return self, callback
end

function EventEmitter:once(eventName, callback, priority)
    if type(eventName) ~= "string" or type(callback) ~= "function" then
        NovaUI.warn("EventEmitter:once", "valid eventName and callback function required")
        return self
    end
    self._listeners = self._listeners or {}
    local list = self._listeners[eventName]
    if not list then
        list = {}
        self._listeners[eventName] = list
    end
    table.insert(list, {
        fn = callback,
        once = true,
        priority = tonumber(priority) or 0,
    })
    return self, callback
end

function EventEmitter:off(eventName, callback)
    if not self._listeners then return self end
    if not eventName then
        self._listeners = {}
        return self
    end
    local list = self._listeners[eventName]
    if not list then return self end
    if not callback then
        self._listeners[eventName] = nil
        return self
    end
    for i = #list, 1, -1 do
        if list[i].fn == callback then
            table.remove(list, i)
        end
    end
    if #list == 0 then
        self._listeners[eventName] = nil
    end
    return self
end

function EventEmitter:emit(eventName, ...)
    if not self._listeners then return false end
    local list = self._listeners[eventName]
    if not list or #list == 0 then return false end

    -- Snapshot to allow safe mutation during dispatch
    local snapshot = {}
    for i = 1, #list do
        snapshot[i] = list[i]
    end

    local handled = false
    for i = 1, #snapshot do
        local item = snapshot[i]
        if item.once then
            self:off(eventName, item.fn)
        end
        local ok, res = pcall(item.fn, ...)
        if not ok then
            NovaUI.error("Event '%s' handler error: %s", tostring(eventName), tostring(res))
        else
            handled = true
            if res == false then
                break
            end
        end
    end
    return handled
end

function EventEmitter:removeAllListeners(eventName)
    return self:off(eventName)
end
