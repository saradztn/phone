--[[
    NovaUI - Slider & RangeSlider Components
    File: client/components/input/slider.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. Slider Component
-- ============================================================================
local Slider = NovaUI.Class("Slider", NovaUI.Component)

function Slider:onCreate(props)
    if not props.height and not props.h then
        self._rawH = props.label and 44 or 26
        self.height = NovaUI.scale(self._rawH)
    end
    self.min = tonumber(props.min) or 0
    self.max = tonumber(props.max) or 100
    if self.max <= self.min then self.max = self.min + 100 end
    self.step = tonumber(props.step) or 1
    self.label = props.label and tostring(props.label) or nil
    self.showValue = props.showValue ~= false
    self.suffix = tostring(props.suffix or "")
    self.state.value = Utils.clamp(tonumber(props.value) or self.min, self.min, self.max)
end

function Slider:_snapValue(rawVal)
    local clamped = Utils.clamp(rawVal, self.min, self.max)
    if self.step and self.step > 0 then
        clamped = self.min + math.floor(((clamped - self.min) / self.step) + 0.5) * self.step
    end
    return Utils.clamp(clamped, self.min, self.max)
end

function Slider:setValue(val, silent)
    local snapped = self:_snapValue(tonumber(val) or self.min)
    return NovaUI.Component.setValue(self, snapped, silent)
end

function Slider:_updateFromMouse(mx)
    local absX = self:getScreenPosition()
    local pad = NovaUI.scale(8)
    local trackW = math.max(10, self.width - pad * 2)
    local ratio = Utils.clamp((mx - (absX + pad)) / trackW, 0, 1)
    local newVal = self.min + ratio * (self.max - self.min)
    self:setValue(newVal)
end

function Slider:onMouseDown(button, mx)
    if button ~= "left" or self.props.disabled then return end
    self:_updateFromMouse(mx)
    NovaUI.Input.dragged = self
end

function Slider:onDragMove(mx)
    if self.props.disabled then return end
    self:_updateFromMouse(mx)
end

function Slider:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local pad = NovaUI.scale(8)
    local trackH = NovaUI.scale(6)
    local trackY = self.label and (absY + h - NovaUI.scale(14)) or (absY + math.floor((h - trackH) * 0.5))
    local trackW = math.max(10, w - pad * 2)
    local trackX = absX + pad

    if self.label or self.showValue then
        if self.label then
            Primitives.drawText(self.label, absX, absY, w * 0.7, NovaUI.scale(20), Utils.withAlpha(theme.textSecondary, 255 * alphaRatio), "sm", "regular", "left", "center")
        end
        if self.showValue then
            local valStr = tostring(self.state.value) .. self.suffix
            Primitives.drawText(valStr, absX, absY, w, NovaUI.scale(20), Utils.withAlpha(theme.primary, 255 * alphaRatio), "sm", "bold", "right", "center")
        end
    end

    -- Track background
    Primitives.drawRoundedRect(trackX, trackY, trackW, trackH, "pill", Utils.withAlpha(theme.surfaceElevated, 255 * alphaRatio), Utils.withAlpha(theme.border, 150 * alphaRatio), 1, false)

    -- Active fill
    local ratio = Utils.clamp((self.state.value - self.min) / (self.max - self.min), 0, 1)
    local fillW = math.floor(trackW * ratio)
    if fillW > 0 then
        Primitives.drawRoundedRect(trackX, trackY, fillW, trackH, "pill", Utils.withAlpha(theme.primary, 255 * alphaRatio), nil, 0, false)
    end

    -- Thumb knob
    local thumbR = NovaUI.scale((self.state.hovered or NovaUI.Input.dragged == self) and 8 or 7)
    local thumbX = trackX + fillW
    local thumbY = trackY + math.floor(trackH * 0.5)
    Primitives.drawCircle(thumbX, thumbY, thumbR, { 255, 255, 255, 255 * alphaRatio }, Utils.withAlpha(theme.primary, 255 * alphaRatio), 2, false)
end

NovaUI.registerComponent("slider", Slider, { "Slider" })

-- ============================================================================
-- 2. RangeSlider Component (Dual-Thumb Min/Max Range Selector)
-- ============================================================================
local RangeSlider = NovaUI.Class("RangeSlider", NovaUI.Component)

function RangeSlider:onCreate(props)
    if not props.height and not props.h then
        self._rawH = props.label and 44 or 28
        self.height = NovaUI.scale(self._rawH)
    end
    self.min = tonumber(props.min) or 0
    self.max = tonumber(props.max) or 100
    self.step = tonumber(props.step) or 1
    self.label = props.label
    local initVal = type(props.value) == "table" and props.value or { self.min + (self.max - self.min) * 0.2, self.min + (self.max - self.min) * 0.8 }
    self.state.value = {
        Utils.clamp(tonumber(initVal[1]) or self.min, self.min, self.max),
        Utils.clamp(tonumber(initVal[2]) or self.max, self.min, self.max),
    }
    self._activeThumb = 1
end

function RangeSlider:setValue(rangeTbl, silent)
    if type(rangeTbl) ~= "table" then return self end
    local v1 = Utils.clamp(tonumber(rangeTbl[1]) or self.min, self.min, self.max)
    local v2 = Utils.clamp(tonumber(rangeTbl[2]) or self.max, v1, self.max)
    self.state.value = { v1, v2 }
    self.props.value = self.state.value
    self._dirty = true
    if not silent then
        self:emit("change", self.state.value)
    end
    return self
end

function RangeSlider:_updateThumbFromMouse(mx, chooseNearest)
    local absX = self:getScreenPosition()
    local pad = NovaUI.scale(8)
    local trackW = math.max(10, self.width - pad * 2)
    local ratio = Utils.clamp((mx - (absX + pad)) / trackW, 0, 1)
    local rawVal = self.min + ratio * (self.max - self.min)
    if self.step and self.step > 0 then
        rawVal = self.min + math.floor(((rawVal - self.min) / self.step) + 0.5) * self.step
    end

    local v1, v2 = self.state.value[1], self.state.value[2]
    if chooseNearest then
        self._activeThumb = (math.abs(rawVal - v1) <= math.abs(rawVal - v2)) and 1 or 2
    end
    if self._activeThumb == 1 then
        v1 = math.min(rawVal, v2)
    else
        v2 = math.max(rawVal, v1)
    end
    self:setValue({ v1, v2 })
end

function RangeSlider:onMouseDown(button, mx)
    if button ~= "left" or self.props.disabled then return end
    self:_updateThumbFromMouse(mx, true)
    NovaUI.Input.dragged = self
end

function RangeSlider:onDragMove(mx)
    if self.props.disabled then return end
    self:_updateThumbFromMouse(mx, false)
end

function RangeSlider:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local pad = NovaUI.scale(8)
    local trackH = NovaUI.scale(6)
    local trackY = self.label and (absY + h - NovaUI.scale(14)) or (absY + math.floor((h - trackH) * 0.5))
    local trackW = math.max(10, w - pad * 2)
    local trackX = absX + pad

    local v1, v2 = self.state.value[1], self.state.value[2]
    if self.label then
        Primitives.drawText(self.label, absX, absY, w * 0.6, NovaUI.scale(20), Utils.withAlpha(theme.textSecondary, 255 * alphaRatio), "sm", "regular", "left", "center")
        Primitives.drawText(string.format("%s - %s", tostring(v1), tostring(v2)), absX, absY, w, NovaUI.scale(20), Utils.withAlpha(theme.primary, 255 * alphaRatio), "sm", "bold", "right", "center")
    end

    Primitives.drawRoundedRect(trackX, trackY, trackW, trackH, "pill", Utils.withAlpha(theme.surfaceElevated, 255 * alphaRatio), nil, 0, false)

    local r1 = Utils.clamp((v1 - self.min) / (self.max - self.min), 0, 1)
    local r2 = Utils.clamp((v2 - self.min) / (self.max - self.min), 0, 1)
    local x1 = trackX + math.floor(trackW * r1)
    local x2 = trackX + math.floor(trackW * r2)

    Primitives.drawRoundedRect(x1, trackY, math.max(2, x2 - x1), trackH, "pill", Utils.withAlpha(theme.primary, 255 * alphaRatio), nil, 0, false)

    local thumbY = trackY + math.floor(trackH * 0.5)
    local thumbR = NovaUI.scale(7)
    Primitives.drawCircle(x1, thumbY, thumbR, { 255, 255, 255, 255 * alphaRatio }, Utils.withAlpha(theme.primary, 255 * alphaRatio), 2, false)
    Primitives.drawCircle(x2, thumbY, thumbR, { 255, 255, 255, 255 * alphaRatio }, Utils.withAlpha(theme.primary, 255 * alphaRatio), 2, false)
end

NovaUI.registerComponent("rangeslider", RangeSlider, { "RangeSlider" })
