--[[
    NovaUI - Utility Functions
    File: client/core/utils.lua
]]

NovaUI = NovaUI or {}
NovaUI.Utils = {}

local Utils = NovaUI.Utils
local mathFloor = math.floor
local mathMin = math.min
local mathMax = math.max
local mathAbs = math.abs
local bitExtract = bitExtract
local tocolor = tocolor or function(r, g, b, a)
    a = a or 255
    return ((a % 256) * 16777216) + ((r % 256) * 65536) + ((g % 256) * 256) + (b % 256)
end

function Utils.clamp(val, minVal, maxVal)
    if val < minVal then return minVal end
    if val > maxVal then return maxVal end
    return val
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.round(val)
    return mathFloor(val + 0.5)
end

function Utils.pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= (rx + rw) and py >= ry and py <= (ry + rh)
end

function Utils.intersectRect(x1, y1, w1, h1, x2, y2, w2, h2)
    local nx = mathMax(x1, x2)
    local ny = mathMax(y1, y2)
    local nw = mathMin(x1 + w1, x2 + w2) - nx
    local nh = mathMin(y1 + h1, y2 + h2) - ny
    if nw <= 0 or nh <= 0 then
        return 0, 0, 0, 0
    end
    return nx, ny, nw, nh
end

-- Parse color input (table {r,g,b,a}, hex string "#RRGGBB" / "#RRGGBBAA", or packed ARGB number) into r, g, b, a
function Utils.unpackColor(color, defaultAlpha)
    defaultAlpha = defaultAlpha or 255
    if type(color) == "table" then
        return color[1] or color.r or 255,
               color[2] or color.g or 255,
               color[3] or color.b or 255,
               color[4] or color.a or defaultAlpha
    elseif type(color) == "string" then
        local hex = color:gsub("#", "")
        if #hex == 3 then
            local r = tonumber(hex:sub(1, 1) .. hex:sub(1, 1), 16) or 255
            local g = tonumber(hex:sub(2, 2) .. hex:sub(2, 2), 16) or 255
            local b = tonumber(hex:sub(3, 3) .. hex:sub(3, 3), 16) or 255
            return r, g, b, defaultAlpha
        elseif #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16) or 255
            local g = tonumber(hex:sub(3, 4), 16) or 255
            local b = tonumber(hex:sub(5, 6), 16) or 255
            return r, g, b, defaultAlpha
        elseif #hex == 8 then
            local r = tonumber(hex:sub(1, 2), 16) or 255
            local g = tonumber(hex:sub(3, 4), 16) or 255
            local b = tonumber(hex:sub(5, 6), 16) or 255
            local a = tonumber(hex:sub(7, 8), 16) or defaultAlpha
            return r, g, b, a
        end
    elseif type(color) == "number" then
        if type(bitExtract) == "function" then
            local b = bitExtract(color, 0, 8)
            local g = bitExtract(color, 8, 8)
            local r = bitExtract(color, 16, 8)
            local a = bitExtract(color, 24, 8)
            return r, g, b, a
        else
            local u = color
            if u < 0 then u = u + 4294967296 end
            local a = mathFloor(u / 16777216) % 256
            local r = mathFloor(u / 65536) % 256
            local g = mathFloor(u / 256) % 256
            local b = mathFloor(u) % 256
            return r, g, b, a
        end
    end
    return 255, 255, 255, defaultAlpha
end

function Utils.toColor(color, alphaMultiplier)
    local r, g, b, a = Utils.unpackColor(color)
    if alphaMultiplier then
        a = Utils.clamp(mathFloor(a * alphaMultiplier + 0.5), 0, 255)
    end
    return tocolor(r, g, b, a)
end

function Utils.withAlpha(color, newAlpha)
    local r, g, b = Utils.unpackColor(color)
    return { r, g, b, Utils.clamp(mathFloor(newAlpha + 0.5), 0, 255) }
end

function Utils.lerpColor(c1, c2, t)
    t = Utils.clamp(t, 0, 1)
    local r1, g1, b1, a1 = Utils.unpackColor(c1)
    local r2, g2, b2, a2 = Utils.unpackColor(c2)
    return {
        mathFloor(r1 + (r2 - r1) * t + 0.5),
        mathFloor(g1 + (g2 - g1) * t + 0.5),
        mathFloor(b1 + (b2 - b1) * t + 0.5),
        mathFloor(a1 + (a2 - a1) * t + 0.5),
    }
end

function Utils.rgbToHex(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = r[1] or 255, r[2] or 255, r[3] or 255, r[4]
    end
    r = Utils.clamp(mathFloor(r or 255), 0, 255)
    g = Utils.clamp(mathFloor(g or 255), 0, 255)
    b = Utils.clamp(mathFloor(b or 255), 0, 255)
    if a then
        a = Utils.clamp(mathFloor(a), 0, 255)
        return string.format("#%02X%02X%02X%02X", r, g, b, a)
    end
    return string.format("#%02X%02X%02X", r, g, b)
end

function Utils.hsvToRGB(h, s, v)
    h = (h or 0) % 360
    s = Utils.clamp(s or 0, 0, 1)
    v = Utils.clamp(v or 0, 0, 1)
    local c = v * s
    local x = c * (1 - mathAbs(((h / 60) % 2) - 1))
    local m = v - c
    local r1, g1, b1 = 0, 0, 0
    if h < 60 then r1, g1, b1 = c, x, 0
    elseif h < 120 then r1, g1, b1 = x, c, 0
    elseif h < 180 then r1, g1, b1 = 0, c, x
    elseif h < 240 then r1, g1, b1 = 0, x, c
    elseif h < 300 then r1, g1, b1 = x, 0, c
    else r1, g1, b1 = c, 0, x end
    return mathFloor((r1 + m) * 255 + 0.5), mathFloor((g1 + m) * 255 + 0.5), mathFloor((b1 + m) * 255 + 0.5)
end

function Utils.rgbToHSV(r, g, b)
    r, g, b = (r or 0) / 255, (g or 0) / 255, (b or 0) / 255
    local maxC = mathMax(r, g, b)
    local minC = mathMin(r, g, b)
    local delta = maxC - minC
    local h = 0
    if delta > 0 then
        if maxC == r then
            h = 60 * (((g - b) / delta) % 6)
        elseif maxC == g then
            h = 60 * (((b - r) / delta) + 2)
        else
            h = 60 * (((r - g) / delta) + 4)
        end
    end
    local s = maxC == 0 and 0 or (delta / maxC)
    return h, s, maxC
end

function Utils.shallowCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

function Utils.deepCopy(tbl, seen)
    if type(tbl) ~= "table" then return tbl end
    if seen and seen[tbl] then return seen[tbl] end
    local s = seen or {}
    local copy = {}
    s[tbl] = copy
    for k, v in pairs(tbl) do
        copy[Utils.deepCopy(k, s)] = Utils.deepCopy(v, s)
    end
    return copy
end

function Utils.merge(base, overrides)
    local out = Utils.deepCopy(base or {})
    if type(overrides) == "table" then
        for k, v in pairs(overrides) do
            if type(v) == "table" and type(out[k]) == "table" and not v._isComponent then
                out[k] = Utils.merge(out[k], v)
            else
                out[k] = v
            end
        end
    end
    return out
end

function Utils.utf8Len(str)
    str = tostring(str or "")
    if type(utf8) == "table" and type(utf8.len) == "function" then
        return utf8.len(str) or #str
    end
    local _, count = str:gsub("[^\128-\193]", "")
    return count
end

function Utils.utf8Sub(str, startChar, endChar)
    str = tostring(str or "")
    if type(utf8) == "table" and type(utf8.sub) == "function" then
        return utf8.sub(str, startChar, endChar)
    end
    return string.sub(str, startChar, endChar)
end

function Utils.formatNumber(n)
    local num = tonumber(n)
    if not num then return tostring(n) end
    local formatted = tostring(mathFloor(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end
