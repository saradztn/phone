--[[
    NovaUI - Easing Functions Library
    Supports 24 built-in curves + custom easing registration
    File: client/animation/easing.lua
]]

NovaUI = NovaUI or {}
NovaUI.Easing = {}

local Easing = NovaUI.Easing
local mathSin = math.sin
local mathCos = math.cos
local mathPi = math.pi
local mathPow = math.pow or function(a, b) return a ^ b end

local c1 = 1.70158
local c2 = c1 * 1.525
local c3 = c1 + 1
local c4 = (2 * mathPi) / 3

Easing.functions = {
    linear = function(t) return t end,

    inQuad = function(t) return t * t end,
    outQuad = function(t) return 1 - (1 - t) * (1 - t) end,
    inOutQuad = function(t)
        return t < 0.5 and (2 * t * t) or (1 - mathPow(-2 * t + 2, 2) / 2)
    end,

    inCubic = function(t) return t * t * t end,
    outCubic = function(t) return 1 - mathPow(1 - t, 3) end,
    inOutCubic = function(t)
        return t < 0.5 and (4 * t * t * t) or (1 - mathPow(-2 * t + 2, 3) / 2)
    end,

    inQuart = function(t) return t * t * t * t end,
    outQuart = function(t) return 1 - mathPow(1 - t, 4) end,
    inOutQuart = function(t)
        return t < 0.5 and (8 * t * t * t * t) or (1 - mathPow(-2 * t + 2, 4) / 2)
    end,

    inQuint = function(t) return t * t * t * t * t end,
    outQuint = function(t) return 1 - mathPow(1 - t, 5) end,
    inOutQuint = function(t)
        return t < 0.5 and (16 * t * t * t * t * t) or (1 - mathPow(-2 * t + 2, 5) / 2)
    end,

    inSine = function(t) return 1 - mathCos((t * mathPi) / 2) end,
    outSine = function(t) return mathSin((t * mathPi) / 2) end,
    inOutSine = function(t) return -(mathCos(mathPi * t) - 1) / 2 end,

    inExpo = function(t) return t == 0 and 0 or mathPow(2, 10 * t - 10) end,
    outExpo = function(t) return t == 1 and 1 or (1 - mathPow(2, -10 * t)) end,

    inBack = function(t) return c3 * t * t * t - c1 * t * t end,
    outBack = function(t) return 1 + c3 * mathPow(t - 1, 3) + c1 * mathPow(t - 1, 2) end,
    inOutBack = function(t)
        if t < 0.5 then
            return (mathPow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
        end
        return (mathPow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
    end,

    outElastic = function(t)
        if t == 0 or t == 1 then return t end
        return mathPow(2, -10 * t) * mathSin((t * 10 - 0.75) * c4) + 1
    end,

    outBounce = function(t)
        local n1, d1 = 7.5625, 2.75
        if t < 1 / d1 then
            return n1 * t * t
        elseif t < 2 / d1 then
            t = t - 1.5 / d1
            return n1 * t * t + 0.75
        elseif t < 2.5 / d1 then
            t = t - 2.25 / d1
            return n1 * t * t + 0.9375
        else
            t = t - 2.625 / d1
            return n1 * t * t + 0.984375
        end
    end,

    spring = function(t)
        return 1 - (mathCos(t * 4.5 * mathPi) * mathPow(2, -6 * t))
    end,
}

-- Case-insensitive lookup map for MTA/DGS easing names (e.g., "OutQuad", "Linear")
local _aliasMap = {}
for k, fn in pairs(Easing.functions) do
    _aliasMap[k:lower()] = fn
end

function Easing.evaluate(nameOrFn, t)
    t = NovaUI.Utils.clamp(tonumber(t) or 0, 0, 1)
    if type(nameOrFn) == "function" then
        return nameOrFn(t)
    end
    local key = tostring(nameOrFn or "outCubic")
    local fn = Easing.functions[key] or _aliasMap[key:lower()]
    if fn then
        return fn(t)
    end
    if type(getEasingValue) == "function" then
        local ok, val = pcall(getEasingValue, t, key)
        if ok and type(val) == "number" then
            return val
        end
    end
    return Easing.functions.outCubic(t)
end

function Easing.register(name, fn)
    if type(name) == "string" and type(fn) == "function" then
        Easing.functions[name] = fn
        _aliasMap[name:lower()] = fn
        return true
    end
    return false
end
