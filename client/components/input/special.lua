--[[
    NovaUI - Specialized Input Components: ColorPicker & Keybind
    File: client/components/input/special.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. ColorPicker Component (Interactive HSV Palette + Swatches + Hex Preview)
-- ============================================================================
local ColorPicker = NovaUI.Class("ColorPicker", NovaUI.Component)

local DEFAULT_SWATCHES = {
    { 56, 189, 248, 255 },  -- Cyan
    { 99, 102, 241, 255 },  -- Indigo
    { 168, 85, 247, 255 },  -- Purple
    { 236, 72, 153, 255 },  -- Pink
    { 244, 63, 94, 255 },   -- Rose
    { 245, 158, 11, 255 },  -- Amber
    { 16, 185, 129, 255 },  -- Emerald
    { 20, 184, 166, 255 },  -- Teal
}

function ColorPicker:onCreate(props)
    if not props.width and not props.w then self._rawW = 240; self.width = NovaUI.scale(240) end
    if not props.height and not props.h then self._rawH = 120; self.height = NovaUI.scale(120) end

    local initCol = props.value or props.color or NovaUI.Theme.primary
    local r, g, b, a = Utils.unpackColor(initCol)
    self.hue, self.sat, self.val = Utils.rgbToHSV(r, g, b)
    self.state.value = { r, g, b, a }
    self.swatches = props.swatches or DEFAULT_SWATCHES
end

function ColorPicker:setColor(color, silent)
    local r, g, b, a = Utils.unpackColor(color)
    self.hue, self.sat, self.val = Utils.rgbToHSV(r, g, b)
    self:setValue({ r, g, b, a }, silent)
    return self
end

function ColorPicker:getHex()
    return Utils.rgbToHex(self.state.value)
end

function ColorPicker:_updateHueFromMouse(mx)
    local absX = self:getScreenPosition()
    local pad = NovaUI.scale(10)
    local barW = math.max(10, self.width - pad * 2)
    local ratio = Utils.clamp((mx - (absX + pad)) / barW, 0, 1)
    self.hue = ratio * 359
    local r, g, b = Utils.hsvToRGB(self.hue, math.max(0.65, self.sat), math.max(0.85, self.val))
    self:setValue({ r, g, b, 255 })
end

function ColorPicker:onMouseDown(button, mx, my)
    if button ~= "left" or self.props.disabled then return end
    local absX, absY = self:getScreenPosition()
    local pad = NovaUI.scale(10)
    local hueY = absY + NovaUI.scale(44)
    local hueH = NovaUI.scale(16)

    if my >= hueY and my <= hueY + hueH + NovaUI.scale(6) then
        self:_updateHueFromMouse(mx)
        NovaUI.Input.dragged = self
        return
    end

    -- Check preset swatches
    local swY = absY + NovaUI.scale(74)
    local swSize = NovaUI.scale(22)
    local gap = NovaUI.scale(6)
    for i = 1, #self.swatches do
        local sx = absX + pad + (i - 1) * (swSize + gap)
        if Utils.pointInRect(mx, my, sx, swY, swSize, swSize) then
            self:setColor(self.swatches[i])
            return
        end
    end
end

function ColorPicker:onDragMove(mx)
    self:_updateHueFromMouse(mx)
end

function ColorPicker:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local pad = NovaUI.scale(10)
    Primitives.drawRoundedRect(absX, absY, w, h, "md", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(theme.border, 220 * alphaRatio), 1, false)

    -- Current color preview box + Hex string
    local prevSize = NovaUI.scale(24)
    Primitives.drawRoundedRect(absX + pad, absY + pad, prevSize, prevSize, "xs", Utils.withAlpha(self.state.value, 255 * alphaRatio), Utils.withAlpha(theme.borderLight, 220 * alphaRatio), 1, false)
    Primitives.drawText(self:getHex(), absX + pad + prevSize + NovaUI.scale(10), absY + pad, w * 0.6, prevSize, Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "bold", "left", "center")

    -- Hue spectrum bar (segmented smooth spectrum)
    local hueY = absY + NovaUI.scale(44)
    local hueH = NovaUI.scale(14)
    local barW = w - pad * 2
    local segs = 18
    local segW = barW / segs
    for i = 0, segs - 1 do
        local hr, hg, hb = Utils.hsvToRGB((i / segs) * 360, 0.85, 0.95)
        Primitives.drawRoundedRect(absX + pad + math.floor(i * segW), hueY, math.ceil(segW), hueH, 0, { hr, hg, hb, 255 * alphaRatio }, nil, 0, false)
    end
    local knobX = absX + pad + math.floor((self.hue / 360) * barW)
    Primitives.drawCircle(knobX, hueY + math.floor(hueH * 0.5), NovaUI.scale(7), { 255, 255, 255, 255 * alphaRatio }, Utils.withAlpha(theme.background, 255 * alphaRatio), 2, false)

    -- Swatches row
    local swY = absY + NovaUI.scale(72)
    local swSize = NovaUI.scale(22)
    local gap = NovaUI.scale(6)
    for i = 1, #self.swatches do
        local sx = absX + pad + (i - 1) * (swSize + gap)
        if sx + swSize <= absX + w - pad then
            Primitives.drawRoundedRect(sx, swY, swSize, swSize, "xs", Utils.withAlpha(self.swatches[i], 255 * alphaRatio), Utils.withAlpha(theme.borderLight, 180 * alphaRatio), 1, false)
        end
    end
end

NovaUI.registerComponent("colorpicker", ColorPicker, { "ColorPicker" })

-- ============================================================================
-- 2. Keybind Component (Interactive Key Shortcut Binder)
-- ============================================================================
local Keybind = NovaUI.Class("Keybind", NovaUI.Component)

function Keybind:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 36
        self.height = NovaUI.scale(36)
    end
    self.label = tostring(props.label or "Shortcut")
    self.state.value = tostring(props.value or props.key or "F2"):upper()
    self.listening = false
end

function Keybind:onClick()
    if self.props.disabled then return end
    self.listening = not self.listening
    if self.listening then
        NovaUI.Input.capturingKeybind = self
    elseif NovaUI.Input.capturingKeybind == self then
        NovaUI.Input.capturingKeybind = nil
    end
    self._dirty = true
end

function Keybind:onCaptureKey(key)
    self.listening = false
    if NovaUI.Input.capturingKeybind == self then
        NovaUI.Input.capturingKeybind = nil
    end
    if key ~= "escape" then
        self:setValue(tostring(key):upper())
    end
    self._dirty = true
end

function Keybind:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local keyW = NovaUI.scale(96)
    local keyX = absX + w - keyW

    Primitives.drawText(self.label, absX, absY, w - keyW - NovaUI.scale(8), h, Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "regular", "left", "center")

    local bg = self.listening and theme.primarySoft or theme.surfaceElevated
    local border = self.listening and theme.primary or theme.borderLight
    local text = self.listening and "Press Key..." or tostring(self.state.value)
    local textCol = self.listening and theme.primary or theme.text

    Primitives.drawRoundedRect(keyX, absY + NovaUI.scale(3), keyW, h - NovaUI.scale(6), "xs", Utils.withAlpha(bg, 255 * alphaRatio), Utils.withAlpha(border, 230 * alphaRatio), 1, false)
    Primitives.drawText(text, keyX, absY, keyW, h, Utils.withAlpha(textCol, 255 * alphaRatio), "xs", "bold", "center", "center")
end

NovaUI.registerComponent("keybind", Keybind, { "Keybind" })
