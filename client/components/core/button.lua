--[[
    NovaUI - Modern Button Component
    Variants: primary, secondary, outline, ghost, danger, success, warning
    Supports: leading/trailing icons, loading spinner state, sizes (xs, sm, md, lg), ripple/press states
    File: client/components/core/button.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

local Button = NovaUI.Class("Button", NovaUI.Component)

local SIZE_PRESETS = {
    xs = { h = 26, fontSize = "xs", padX = 10, iconSize = 13 },
    sm = { h = 32, fontSize = "sm", padX = 12, iconSize = 15 },
    md = { h = 38, fontSize = "md", padX = 16, iconSize = 17 },
    lg = { h = 46, fontSize = "lg", padX = 22, iconSize = 20 },
}

function Button:onCreate(props)
    local sz = SIZE_PRESETS[props.size or "md"] or SIZE_PRESETS.md
    if not props.height and not props.h then
        self._rawH = sz.h
        self.height = NovaUI.scale(self._rawH)
    end
    self.props.text = tostring(props.text or props.label or "Button")
    self.variant = props.variant or "primary"
    self.size = props.size or "md"
    self.radius = props.radius or "sm"
    self.icon = props.icon
    self.iconPosition = props.iconPosition or "left"
    self.loading = props.loading == true
end

function Button:setLoading(isLoading)
    self.loading = isLoading and true or false
    self._dirty = true
    return self
end

function Button:_getColors(alphaRatio)
    local theme = NovaUI.Theme
    local v = self.variant
    local isHov = self.state.hovered and not self.props.disabled and not self.loading
    local isPress = self.state.pressed and not self.props.disabled and not self.loading

    local bg, border, textCol
    if v == "primary" then
        bg = isPress and theme.primaryActive or (isHov and theme.primaryHover or theme.primary)
        textCol = theme.textInverse
        border = isHov and theme.primaryHover or nil
    elseif v == "secondary" then
        bg = isPress and theme.surfaceActive or (isHov and theme.surfaceHover or theme.surfaceElevated)
        textCol = theme.text
        border = theme.borderLight
    elseif v == "outline" then
        bg = isHov and theme.primarySoft or { 0, 0, 0, 0 }
        textCol = isHov and theme.primaryHover or theme.text
        border = isHov and theme.primary or theme.borderLight
    elseif v == "ghost" then
        bg = isPress and theme.surfaceActive or (isHov and theme.surfaceHover or { 0, 0, 0, 0 })
        textCol = isHov and theme.text or theme.textSecondary
        border = nil
    elseif v == "danger" then
        bg = isHov and Utils.lerpColor(theme.danger, { 255, 255, 255, 255 }, 0.14) or theme.danger
        textCol = { 255, 255, 255, 255 }
        border = nil
    elseif v == "success" then
        bg = isHov and Utils.lerpColor(theme.success, { 255, 255, 255, 255 }, 0.14) or theme.success
        textCol = theme.textInverse
        border = nil
    elseif v == "warning" then
        bg = isHov and Utils.lerpColor(theme.warning, { 255, 255, 255, 255 }, 0.14) or theme.warning
        textCol = theme.textInverse
        border = nil
    else
        bg = isHov and theme.surfaceHover or theme.surfaceElevated
        textCol = theme.text
        border = theme.border
    end

    if self.props.backgroundColor then bg = self.props.backgroundColor end
    if self.props.textColor then textCol = self.props.textColor end

    local effAlpha = alphaRatio * (self.props.disabled and NovaUI.Tokens.opacity.disabled or 1.0)
    return Utils.withAlpha(bg, (bg[4] or 255) * effAlpha),
           border and Utils.withAlpha(border, (border[4] or 220) * effAlpha) or nil,
           Utils.withAlpha(textCol, 255 * effAlpha)
end

function Button:render(absX, absY, w, h, alphaRatio)
    local sz = SIZE_PRESETS[self.size] or SIZE_PRESETS.md
    local bgCol, borderCol, textCol = self:_getColors(alphaRatio)

    -- Subtle vertical press displacement
    local pressOffset = (self.state.pressed and not self.props.disabled) and NovaUI.scale(1) or 0
    local drawY = absY + pressOffset

    if self.variant == "primary" and self.state.hovered and not self.props.disabled then
        Primitives.drawShadow(absX, drawY, w, h, self.radius, "sm", alphaRatio * 0.7, false)
    end

    Primitives.drawRoundedRect(absX, drawY, w, h, self.radius, bgCol, borderCol, 1, false)

    local iconSize = NovaUI.scale(sz.iconSize)
    local label = self.props.text or ""
    local gap = label ~= "" and NovaUI.scale(8) or 0

    if self.loading then
        local now = type(getTickCount) == "function" and getTickCount() or 0
        local angle = (now * 0.36) % 360
        local cx = absX + math.floor(w * 0.5)
        local cy = drawY + math.floor(h * 0.5)
        Primitives.drawArc(cx, cy, math.floor(iconSize * 0.48), 2, angle, angle + 250, textCol, false)
        return
    end

    if self.icon then
        local tw = label ~= "" and NovaUI.Fonts.getTextWidth(label, sz.fontSize, "bold") or 0
        local totalW = iconSize + gap + tw
        local startX = absX + math.floor((w - totalW) * 0.5)
        local iconY = drawY + math.floor((h - iconSize) * 0.5)

        if self.iconPosition == "right" then
            if label ~= "" then
                Primitives.drawText(label, startX, drawY, tw + 4, h, textCol, sz.fontSize, "bold", "left", "center")
            end
            NovaUI.Icons.draw(self.icon, startX + tw + gap, iconY, iconSize, textCol)
        else
            NovaUI.Icons.draw(self.icon, startX, iconY, iconSize, textCol)
            if label ~= "" then
                Primitives.drawText(label, startX + iconSize + gap, drawY, tw + 4, h, textCol, sz.fontSize, "bold", "left", "center")
            end
        end
    else
        Primitives.drawText(label, absX, drawY, w, h, textCol, sz.fontSize, "bold", "center", "center")
    end
end

NovaUI.registerComponent("button", Button, { "Button" })
