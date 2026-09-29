--[[
    NovaUI - Modern Retained-Mode UI Framework for MTA:SA
    Built on top of DGS & DirectX Primitives
    File: client/core/namespace.lua
]]

NovaUI = NovaUI or {}

NovaUI.VERSION = "3.0.0"
NovaUI.NAME = "NovaUI"
NovaUI.AUTHOR = "NovaUI Architecture Team"

-- Internal registries
NovaUI._registry = {
    components = {},      -- id -> component instance
    componentClasses = {},-- typeName -> class table
    rootElements = {},    -- ordered array of top-level components
    modals = {},          -- active modal stack
    notifications = {},   -- active notification stack
    animations = {},      -- active animations
    keybinds = {},        -- bound shortcut keys
    timers = {},          -- tracked MTA timers for safe cleanup
    dgsMap = {},          -- dgsElement -> NovaUI component
    nextId = 1,
}

-- Configuration
NovaUI.Config = {
    debug = false,
    warnThrottleMs = 5000,
    baseResolution = { width = 1920, height = 1080 },
    minScale = 0.62,
    maxScale = 1.75,
    useDGSBackend = true,
    enableBlur = true,
    enableShadows = true,
    enableAnimations = true,
    defaultTheme = "midnight",
    defaultFontFamily = "sans",
}

-- Rate-limited warning/error logger (prevents per-frame spam)
local _logHistory = {}

local function _shouldLog(key)
    local now = type(getTickCount) == "function" and getTickCount() or 0
    local last = _logHistory[key]
    if last and (now - last) < NovaUI.Config.warnThrottleMs then
        return false
    end
    _logHistory[key] = now
    return true
end

function NovaUI.log(message, ...)
    if not NovaUI.Config.debug then return end
    local formatted = select("#", ...) > 0 and string.format(tostring(message), ...) or tostring(message)
    local msg = string.format("[NovaUI] %s", formatted)
    if type(outputDebugString) == "function" then
        outputDebugString(msg, 3, 120, 180, 255)
    end
end

function NovaUI.warn(message, ...)
    local formatted = select("#", ...) > 0 and string.format(tostring(message), ...) or tostring(message)
    if not _shouldLog("W:" .. formatted) then return false end
    local msg = string.format("[NovaUI WARNING] %s", formatted)
    if type(outputDebugString) == "function" then
        outputDebugString(msg, 2, 255, 190, 60)
    end
    return false
end

function NovaUI.error(message, ...)
    local formatted = select("#", ...) > 0 and string.format(tostring(message), ...) or tostring(message)
    if not _shouldLog("E:" .. formatted) then return false end
    local msg = string.format("[NovaUI ERROR] %s", formatted)
    if type(outputDebugString) == "function" then
        outputDebugString(msg, 1, 255, 80, 80)
    end
    return false
end

function NovaUI.validate(condition, context, expectedMsg)
    if condition then
        return true
    end
    NovaUI.warn("%s: %s", tostring(context or "Validation"), tostring(expectedMsg or "Invalid argument"))
    return false
end

-- Safe timer wrapper that tracks timers for resource/component cleanup
function NovaUI.setTimer(callback, interval, timesToExecute, ...)
    if type(callback) ~= "function" then
        return NovaUI.warn("NovaUI.setTimer", "callback must be a function")
    end
    interval = math.max(50, tonumber(interval) or 50)
    timesToExecute = tonumber(timesToExecute) or 1
    if type(setTimer) == "function" then
        local args = { ... }
        local timer
        timer = setTimer(function()
            if timesToExecute == 1 and timer then
                NovaUI._registry.timers[timer] = nil
            end
            callback(unpack(args))
        end, interval, timesToExecute)
        if timer then
            NovaUI._registry.timers[timer] = true
        end
        return timer
    end
    return nil
end

function NovaUI.killTimer(timer)
    if timer then
        NovaUI._registry.timers[timer] = nil
        if type(isTimer) == "function" and isTimer(timer) then
            killTimer(timer)
            return true
        end
    end
    return false
end
