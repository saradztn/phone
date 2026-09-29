--[[
    NovaUI - Responsive Multi-Resolution Scaling Engine
    Supports 800x600 through 3840x2160 (4K) with perceptual curves & viewport clamping
    File: client/rendering/scaling.lua
]]

NovaUI = NovaUI or {}
NovaUI.Scaling = {}

local Scaling = NovaUI.Scaling
local Utils = NovaUI.Utils
local mathFloor = math.floor
local mathMin = math.min
local mathMax = math.max

local BASE_W = NovaUI.Config.baseResolution.width or 1920
local BASE_H = NovaUI.Config.baseResolution.height or 1080

-- Query initial screen size from MTA guiGetScreenSize (with fallback to 1920x1080)
local function _queryScreenSize()
    if type(guiGetScreenSize) == "function" then
        local sw, sh = guiGetScreenSize()
        if sw and sh and sw > 0 and sh > 0 then
            return sw, sh
        end
    end
    return BASE_W, BASE_H
end

Scaling.screenW, Scaling.screenH = _queryScreenSize()
Scaling.factorX = 1.0
Scaling.factorY = 1.0
Scaling.factor  = 1.0
Scaling.fontFactor = 1.0
Scaling.breakpoint = "xl"

local function _recalculate(sw, sh)
    sw = mathMax(640, tonumber(sw) or BASE_W)
    sh = mathMax(480, tonumber(sh) or BASE_H)
    Scaling.screenW = sw
    Scaling.screenH = sh

    Scaling.factorX = sw / BASE_W
    Scaling.factorY = sh / BASE_H

    -- Uniform UI scale uses min(factorX, factorY) blended slightly with geometric mean
    -- so 4:3 resolutions (800x600, 1024x768) and 16:9 resolutions scale harmoniously
    local rawMin = mathMin(Scaling.factorX, Scaling.factorY)
    local damped = rawMin
    if rawMin < 1.0 then
        -- Dampen downscaling slightly so UI remains readable on 800x600 / 1024x768
        damped = 1.0 - (1.0 - rawMin) * 0.85
    elseif rawMin > 1.0 then
        -- Smooth upscaling for 1440p and 4K
        damped = 1.0 + (rawMin - 1.0) * 0.90
    end

    Scaling.factor = Utils.clamp(damped, NovaUI.Config.minScale or 0.62, NovaUI.Config.maxScale or 1.75)
    Scaling.fontFactor = Utils.clamp(1.0 + (Scaling.factor - 1.0) * 0.88, 0.72, 1.65)

    if sw < 1024 then
        Scaling.breakpoint = "xs"
    elseif sw < 1280 then
        Scaling.breakpoint = "sm"
    elseif sw < 1600 then
        Scaling.breakpoint = "md"
    elseif sw < 1920 then
        Scaling.breakpoint = "lg"
    elseif sw < 2560 then
        Scaling.breakpoint = "xl"
    else
        Scaling.breakpoint = "xxl"
    end
end

_recalculate(Scaling.screenW, Scaling.screenH)

function NovaUI.scale(value)
    if type(value) ~= "number" then return 0 end
    if value == 0 then return 0 end
    local scaled = mathFloor(value * Scaling.factor + 0.5)
    if value > 0 and scaled < 1 then return 1 end
    if value < 0 and scaled > -1 then return -1 end
    return scaled
end

function NovaUI.scaleX(value)
    if type(value) ~= "number" then return 0 end
    return mathFloor(value * Scaling.factorX + 0.5)
end

function NovaUI.scaleY(value)
    if type(value) ~= "number" then return 0 end
    return mathFloor(value * Scaling.factorY + 0.5)
end

function NovaUI.scaleFont(ptSize)
    if type(ptSize) ~= "number" then return 10 end
    return mathMax(8, mathFloor(ptSize * Scaling.fontFactor + 0.5))
end

function NovaUI.unscale(pixels)
    if type(pixels) ~= "number" or Scaling.factor == 0 then return 0 end
    return mathFloor((pixels / Scaling.factor) + 0.5)
end

function NovaUI.getScreenSize()
    return Scaling.screenW, Scaling.screenH
end

function NovaUI.getScaleFactor()
    return Scaling.factor, Scaling.factorX, Scaling.factorY
end

function NovaUI.getBreakpoint()
    return Scaling.breakpoint
end

function NovaUI.setScreenSize(width, height)
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then
        return NovaUI.warn("NovaUI.setScreenSize", "width and height must be positive numbers")
    end
    _recalculate(width, height)

    -- Notify all components of resolution/scale change so layouts adapt cleanly
    for _, comp in pairs(NovaUI._registry.components) do
        if comp and not comp._destroyed then
            comp._dirty = true
            if type(comp.onScaleChange) == "function" then
                pcall(comp.onScaleChange, comp, Scaling.factor, width, height)
            end
        end
    end
    if NovaUI.Renderer and NovaUI.Renderer.markDirty then
        NovaUI.Renderer.markDirty()
    end
    return Scaling.factor
end

-- Fit a rectangle (in scaled or unscaled screen coordinates) safely within the viewport
function NovaUI.fitToViewport(x, y, w, h, margin)
    margin = tonumber(margin) or NovaUI.scale(12)
    local sw, sh = Scaling.screenW, Scaling.screenH
    local maxW = mathMax(120, sw - margin * 2)
    local maxH = mathMax(90, sh - margin * 2)
    local nw = mathMin(w, maxW)
    local nh = mathMin(h, maxH)
    local nx = Utils.clamp(x, margin, sw - nw - margin)
    local ny = Utils.clamp(y, margin, sh - nh - margin)
    return mathFloor(nx), mathFloor(ny), mathFloor(nw), mathFloor(nh)
end
