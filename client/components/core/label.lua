--[[
    NovaUI - Typography Label Component
    Supports variants, weights, semantic color tokens, alignment, and word-wrapping
    File: client/components/core/label.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

local Label = NovaUI.Class("Label", NovaUI.Component)

local VARIANT_MAP = {
    display  = { size = "display", weight = "bold" },
    h1       = { size = "h1",      weight = "bold" },
    h2       = { size = "h2",      weight = "bold" },
    h3       = { size = "h3",      weight = "bold" },
    title    = { size = "lg",      weight = "bold" },
    subtitle = { size = "md",      weight = "regular" },
    body     = { size = "md",      weight = "regular" },
    caption  = { size = "xs",      weight = "regular" },
    small    = { size = "sm",      weight = "regular" },
}

function Label:onCreate(props)
    self.props.text = tostring(props.text or props.label or "")
    self.variant = props.variant or "body"
    self.alignX = props.alignX or props.align or "left"
    self.alignY = props.alignY or props.verticalAlign or "center"
    self.wordBreak = props.wordBreak == true
    self.colorCoded = props.colorCoded == true
    self._passthrough = props.interactive ~= true
end

function Label:_resolveColor(alphaRatio)
    local theme = NovaUI.Theme
    local c = self.props.color
    if type(c) == "string" and theme[c] then
        return Utils.withAlpha(theme[c], 255 * alphaRatio)
    elseif c then
        return Utils.withAlpha(c, 255 * alphaRatio)
    end
    if self.variant == "caption" or self.props.muted then
        return Utils.withAlpha(theme.textMuted, 255 * alphaRatio)
    elseif self.variant == "subtitle" then
        return Utils.withAlpha(theme.textSecondary, 255 * alphaRatio)
    end
    return Utils.withAlpha(theme.text, 255 * alphaRatio)
end

function Label:render(absX, absY, w, h, alphaRatio)
    local v = VARIANT_MAP[self.variant] or VARIANT_MAP.body
    local fontSize = self.props.fontSize or v.size
    local fontWeight = self.props.fontWeight or v.weight
    local col = self:_resolveColor(alphaRatio)

    Primitives.drawText(
        self.props.text,
        absX,
        absY,
        w,
        h,
        col,
        fontSize,
        fontWeight,
        self.alignX,
        self.alignY,
        self.props.clip ~= false,
        self.wordBreak,
        false,
        self.colorCoded
    )
end

NovaUI.registerComponent("label", Label, { "Label" })
