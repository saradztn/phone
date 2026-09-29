--[[
    NovaUI - Panel, Container, Divider, and Spacer Components
    File: client/components/core/panel.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. Panel Component
-- ============================================================================
local Panel = NovaUI.Class("Panel", NovaUI.Component)

function Panel:onCreate(props)
    self.title = props.title and tostring(props.title) or nil
    self.subtitle = props.subtitle and tostring(props.subtitle) or nil
    self.variant = props.variant or "surface" -- "surface" | "elevated" | "glass" | "outlined" | "ghost"
    self.radius = props.radius or "md"
    self.shadow = props.shadow or (self.variant == "elevated" and "md" or "none")
    self.headerHeight = self.title and NovaUI.scale(tonumber(props.headerHeight) or 40) or 0
end

function Panel:getContentOrigin(absX, absY)
    return absX, absY + self.headerHeight
end

function Panel:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    if self.variant == "ghost" then return end

    local fill = self.props.backgroundColor
    if not fill then
        if self.variant == "elevated" then fill = theme.surfaceElevated
        elseif self.variant == "glass" then fill = theme.glass
        elseif self.variant == "outlined" then fill = { 0, 0, 0, 0 }
        else fill = theme.surface end
    end

    local borderCol = self.props.border ~= false and Utils.withAlpha(self.props.borderColor or theme.border, 190 * alphaRatio) or nil
    local bgCol = Utils.withAlpha(fill, (fill[4] or 255) * alphaRatio)

    if self.shadow and self.shadow ~= "none" then
        Primitives.drawShadow(absX, absY, w, h, self.radius, self.shadow, alphaRatio, false)
    end
    Primitives.drawRoundedRect(absX, absY, w, h, self.radius, bgCol, borderCol, 1, false)

    if self.title then
        local padX = NovaUI.scale(14)
        Primitives.drawText(self.title, absX + padX, absY, w - padX * 2, self.headerHeight, Utils.withAlpha(theme.text, 255 * alphaRatio), "md", "bold", "left", "center")
        Primitives.drawRoundedRect(absX + 1, absY + self.headerHeight - 1, w - 2, 1, 0, Utils.withAlpha(theme.border, 130 * alphaRatio), nil, 0, false)
    end
end

NovaUI.registerComponent("panel", Panel, { "Panel" })

-- ============================================================================
-- 2. Container Component (Supports vertical/horizontal auto-stacking layout)
-- ============================================================================
local Container = NovaUI.Class("Container", NovaUI.Component)

function Container:onCreate(props)
    self._passthrough = props.backgroundColor == nil
    self.layout = props.layout or "none" -- "none" | "column" | "row"
    self.gap = tonumber(props.gap) or 8
    self.padding = tonumber(props.padding) or 0
end

function Container:relayout()
    if self.layout == "none" or not self.children then return end
    local pad = NovaUI.scale(self.padding)
    local gap = NovaUI.scale(self.gap)
    local cursorX = pad
    local cursorY = pad

    for i = 1, #self.children do
        local c = self.children[i]
        if c and not c._destroyed and c.visible then
            if self.layout == "column" then
                c.x = pad
                c.y = cursorY
                if self.props.stretchChildren then
                    c.width = math.max(10, self.width - pad * 2)
                end
                cursorY = cursorY + c.height + gap
            elseif self.layout == "row" then
                c.x = cursorX
                c.y = pad
                cursorX = cursorX + c.width + gap
            end
        end
    end
end

function Container:onChildAdded()
    self:relayout()
end

function Container:onResize()
    self:relayout()
end

function Container:render(absX, absY, w, h, alphaRatio)
    if self.props.backgroundColor then
        Primitives.drawRoundedRect(absX, absY, w, h, self.props.radius or "sm", Utils.withAlpha(self.props.backgroundColor, 255 * alphaRatio), nil, 0, false)
    end
end

NovaUI.registerComponent("container", Container, { "Container" })

-- ============================================================================
-- 3. Divider Component
-- ============================================================================
local Divider = NovaUI.Class("Divider", NovaUI.Component)

function Divider:onCreate(props)
    self.orientation = props.orientation or "horizontal" -- "horizontal" | "vertical"
    if self.orientation == "horizontal" and not props.height and not props.h then
        self._rawH = props.text and 20 or 2
        self.height = NovaUI.scale(self._rawH)
    elseif self.orientation == "vertical" and not props.width and not props.w then
        self._rawW = 2
        self.width = NovaUI.scale(self._rawW)
    end
    self._passthrough = true
end

function Divider:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local col = Utils.withAlpha(self.props.color or theme.border, 190 * alphaRatio)
    if self.orientation == "vertical" then
        local cx = absX + math.floor(w * 0.5)
        Primitives.drawRoundedRect(cx, absY, 1, h, 0, col, nil, 0, false)
    else
        local cy = absY + math.floor(h * 0.5)
        local label = self.props.text or self.props.label
        if label and label ~= "" then
            local tw = NovaUI.Fonts.getTextWidth(label, "xs", "regular") + NovaUI.scale(16)
            local sideW = math.max(0, math.floor((w - tw) * 0.5))
            Primitives.drawRoundedRect(absX, cy, sideW, 1, 0, col, nil, 0, false)
            Primitives.drawRoundedRect(absX + w - sideW, cy, sideW, 1, 0, col, nil, 0, false)
            Primitives.drawText(label, absX + sideW, absY, tw, h, Utils.withAlpha(theme.textMuted, 230 * alphaRatio), "xs", "regular", "center", "center")
        else
            Primitives.drawRoundedRect(absX, cy, w, 1, 0, col, nil, 0, false)
        end
    end
end

NovaUI.registerComponent("divider", Divider, { "Divider" })

-- ============================================================================
-- 4. Spacer Component
-- ============================================================================
local Spacer = NovaUI.Class("Spacer", NovaUI.Component)

function Spacer:onCreate(props)
    self._rawW = tonumber(props.size or props.width or props.w) or 12
    self._rawH = tonumber(props.size or props.height or props.h) or 12
    self.width = NovaUI.scale(self._rawW)
    self.height = NovaUI.scale(self._rawH)
    self._passthrough = true
end

function Spacer:render() end

NovaUI.registerComponent("spacer", Spacer, { "Spacer" })
