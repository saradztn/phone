--[[
    NovaUI - Toggle Controls: Checkbox, Switch, and Radio
    File: client/components/input/toggle.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. Checkbox Component
-- ============================================================================
local Checkbox = NovaUI.Class("Checkbox", NovaUI.Component)

function Checkbox:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 26
        self.height = NovaUI.scale(26)
    end
    self.label = tostring(props.label or props.text or "")
    self.state.value = (props.checked == true or props.value == true)
    self.checked = self.state.value
end

function Checkbox:setChecked(checked, silent)
    local val = checked and true or false
    self.checked = val
    return self:setValue(val, silent)
end

function Checkbox:isChecked()
    return self.state.value == true
end

function Checkbox:onClick()
    if self.props.disabled then return end
    self:setChecked(not self.state.value)
end

function Checkbox:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local boxSize = NovaUI.scale(18)
    local boxY = absY + math.floor((h - boxSize) * 0.5)
    local isChecked = self.state.value == true
    local isHov = self.state.hovered and not self.props.disabled

    local bg = isChecked and theme.primary or (isHov and theme.surfaceHover or theme.surface)
    local border = isChecked and theme.primary or (isHov and theme.borderFocus or theme.borderLight)

    Primitives.drawRoundedRect(absX, boxY, boxSize, boxSize, "xs", Utils.withAlpha(bg, 255 * alphaRatio), Utils.withAlpha(border, 230 * alphaRatio), 1.5, false)

    if isChecked then
        local icSz = NovaUI.scale(13)
        NovaUI.Icons.draw("check", absX + math.floor((boxSize - icSz) * 0.5), boxY + math.floor((boxSize - icSz) * 0.5), icSz, Utils.withAlpha(theme.textInverse, 255 * alphaRatio))
    end

    if self.label ~= "" then
        local tx = absX + boxSize + NovaUI.scale(10)
        Primitives.drawText(self.label, tx, absY, w - (tx - absX), h, Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "regular", "left", "center")
    end
end

NovaUI.registerComponent("checkbox", Checkbox, { "Checkbox" })

-- ============================================================================
-- 2. Switch Component (Smooth Animated Pill Toggle)
-- ============================================================================
local Switch = NovaUI.Class("Switch", NovaUI.Component)

function Switch:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 28
        self.height = NovaUI.scale(28)
    end
    self.label = tostring(props.label or props.text or "")
    local initChecked = (props.checked == true or props.value == true)
    self.state.value = initChecked
    self._knobProgress = initChecked and 1.0 or 0.0
end

function Switch:setChecked(checked, silent)
    local val = checked and true or false
    self:setValue(val, silent)
    NovaUI.animate(self, {
        _knobProgress = val and 1.0 or 0.0,
        duration = NovaUI.Tokens.animation.fast,
        easing = "outCubic",
    })
    return self
end

function Switch:isChecked()
    return self.state.value == true
end

function Switch:onClick()
    if self.props.disabled then return end
    self:setChecked(not self.state.value)
end

function Switch:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local trackW = NovaUI.scale(42)
    local trackH = NovaUI.scale(22)
    local trackY = absY + math.floor((h - trackH) * 0.5)
    local prog = Utils.clamp(self._knobProgress or (self.state.value and 1 or 0), 0, 1)

    local trackCol = Utils.lerpColor(theme.surfaceElevated, theme.primary, prog)
    local borderCol = Utils.lerpColor(theme.borderLight, theme.primary, prog)

    Primitives.drawRoundedRect(absX, trackY, trackW, trackH, "pill", Utils.withAlpha(trackCol, 255 * alphaRatio), Utils.withAlpha(borderCol, 220 * alphaRatio), 1, false)

    local knobR = NovaUI.scale(8)
    local pad = NovaUI.scale(3)
    local minX = absX + pad + knobR
    local maxX = absX + trackW - pad - knobR
    local knobX = minX + (maxX - minX) * prog
    local knobY = trackY + math.floor(trackH * 0.5)

    Primitives.drawCircle(knobX, knobY, knobR, { 255, 255, 255, 255 * alphaRatio }, nil, 0, false)

    if self.label ~= "" then
        local tx = absX + trackW + NovaUI.scale(10)
        Primitives.drawText(self.label, tx, absY, w - (tx - absX), h, Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "regular", "left", "center")
    end
end

NovaUI.registerComponent("switch", Switch, { "Switch" })

-- ============================================================================
-- 3. Radio Component (Grouped Exclusive Selection)
-- ============================================================================
local Radio = NovaUI.Class("Radio", NovaUI.Component)
local _radioGroups = {}

function Radio:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 26
        self.height = NovaUI.scale(26)
    end
    self.label = tostring(props.label or props.text or "")
    self.group = tostring(props.group or "default")
    self.radioValue = props.radioValue or props.value or self.label
    self.state.value = (props.checked == true or props.selected == true)

    _radioGroups[self.group] = _radioGroups[self.group] or {}
    table.insert(_radioGroups[self.group], self)
end

function Radio:select()
    local grp = _radioGroups[self.group] or {}
    for i = 1, #grp do
        local r = grp[i]
        if r and not r._destroyed then
            local isSelf = (r == self)
            if r.state.value ~= isSelf then
                r.state.value = isSelf
                r._dirty = true
                if isSelf then
                    r:emit("change", r.radioValue, true)
                end
            end
        end
    end
    return self
end

function Radio:onClick()
    if self.props.disabled then return end
    self:select()
end

function Radio:onDestroy()
    local grp = _radioGroups[self.group]
    if grp then
        for i = #grp, 1, -1 do
            if grp[i] == self then
                table.remove(grp, i)
                break
            end
        end
    end
end

function Radio:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local r = NovaUI.scale(9)
    local cx = absX + r
    local cy = absY + math.floor(h * 0.5)
    local isSelected = self.state.value == true

    local borderCol = isSelected and theme.primary or (self.state.hovered and theme.borderFocus or theme.borderLight)
    Primitives.drawCircle(cx, cy, r, Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(borderCol, 240 * alphaRatio), 1.5, false)

    if isSelected then
        Primitives.drawCircle(cx, cy, NovaUI.scale(4.5), Utils.withAlpha(theme.primary, 255 * alphaRatio), nil, 0, false)
    end

    if self.label ~= "" then
        local tx = absX + r * 2 + NovaUI.scale(10)
        Primitives.drawText(self.label, tx, absY, w - (tx - absX), h, Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "regular", "left", "center")
    end
end

NovaUI.registerComponent("radio", Radio, { "Radio", "radiobutton" })
