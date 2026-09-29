--[[
    NovaUI - Disclosure & Card Components: Accordion, Card, StatsCard
    File: client/components/advanced/disclosure.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. Accordion Component
-- ============================================================================
local Accordion = NovaUI.Class("Accordion", NovaUI.Component)

function Accordion:onCreate(props)
    self.items = type(props.items) == "table" and props.items or {}
    self.headerHeight = NovaUI.scale(tonumber(props.headerHeight) or 40)
    self.contentHeight = NovaUI.scale(tonumber(props.contentHeight) or 68)
    self.allowMultiple = props.allowMultiple == true
end

function Accordion:toggleSection(index)
    local item = self.items[index]
    if not item then return self end
    local nextState = not item.expanded
    if not self.allowMultiple and nextState then
        for i = 1, #self.items do
            self.items[i].expanded = false
        end
    end
    item.expanded = nextState
    self._dirty = true
    self:emit("change", index, nextState, item)
    return self
end

function Accordion:onClick(_, my)
    local absX, absY = self:getScreenPosition()
    local cursorY = absY
    local gap = NovaUI.scale(6)
    for i = 1, #self.items do
        local it = self.items[i]
        local secH = self.headerHeight + (it.expanded and self.contentHeight or 0)
        if my >= cursorY and my <= cursorY + self.headerHeight then
            self:toggleSection(i)
            return
        end
        cursorY = cursorY + secH + gap
    end
end

function Accordion:render(absX, absY, w, _, alphaRatio)
    local theme = NovaUI.Theme
    local cursorY = absY
    local gap = NovaUI.scale(6)
    local padX = NovaUI.scale(14)

    for i = 1, #self.items do
        local it = self.items[i]
        local isExp = it.expanded == true
        local secH = self.headerHeight + (isExp and self.contentHeight or 0)

        Primitives.drawRoundedRect(absX, cursorY, w, secH, "sm", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(isExp and theme.borderFocus or theme.border, 200 * alphaRatio), 1, false)
        Primitives.drawText(tostring(it.title or ("Section " .. i)), absX + padX, cursorY, w - padX * 2 - NovaUI.scale(20), self.headerHeight, Utils.withAlpha(isExp and theme.primary or theme.text, 255 * alphaRatio), "sm", "bold", "left", "center")

        local icSz = NovaUI.scale(14)
        NovaUI.Icons.draw(isExp and "chevron-up" or "chevron-down", absX + w - padX - icSz, cursorY + math.floor((self.headerHeight - icSz) * 0.5), icSz, Utils.withAlpha(theme.textMuted, 240 * alphaRatio))

        if isExp then
            Primitives.drawRoundedRect(absX + padX, cursorY + self.headerHeight, w - padX * 2, 1, 0, Utils.withAlpha(theme.border, 130 * alphaRatio), nil, 0, false)
            Primitives.drawText(
                tostring(it.content or it.description or ""),
                absX + padX,
                cursorY + self.headerHeight + NovaUI.scale(8),
                w - padX * 2,
                self.contentHeight - NovaUI.scale(16),
                Utils.withAlpha(theme.textSecondary, 240 * alphaRatio),
                "xs",
                "regular",
                "left",
                "top",
                true,
                true
            )
        end

        cursorY = cursorY + secH + gap
    end
end

NovaUI.registerComponent("accordion", Accordion, { "Accordion" })

-- ============================================================================
-- 2. Card Component
-- ============================================================================
local Card = NovaUI.Class("Card", NovaUI.Component)

function Card:onCreate(props)
    self.title = props.title and tostring(props.title) or nil
    self.subtitle = props.subtitle and tostring(props.subtitle) or nil
    self.icon = props.icon
    self.badge = props.badge
    self.headerHeight = (self.title or self.subtitle) and NovaUI.scale(tonumber(props.headerHeight) or 52) or 0
end

function Card:getContentOrigin(absX, absY)
    return absX, absY + self.headerHeight
end

function Card:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local isHov = self.state.hovered and self.props.interactive
    local borderCol = isHov and theme.borderFocus or theme.border

    Primitives.drawGlassPanel(absX, absY, w, h, self.props.radius or "md", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(borderCol, 200 * alphaRatio), self.props.shadow or "sm", false)

    if self.headerHeight > 0 then
        local padX = NovaUI.scale(16)
        local tx = absX + padX
        if self.icon then
            local icSz = NovaUI.scale(18)
            NovaUI.Icons.draw(self.icon, tx, absY + NovaUI.scale(16), icSz, Utils.withAlpha(theme.primary, 255 * alphaRatio))
            tx = tx + icSz + NovaUI.scale(10)
        end
        if self.title then
            Primitives.drawText(self.title, tx, absY + NovaUI.scale(10), w - (tx - absX) - padX, NovaUI.scale(20), Utils.withAlpha(theme.text, 255 * alphaRatio), "md", "bold", "left", "center")
        end
        if self.subtitle then
            Primitives.drawText(self.subtitle, tx, absY + NovaUI.scale(29), w - (tx - absX) - padX, NovaUI.scale(16), Utils.withAlpha(theme.textMuted, 230 * alphaRatio), "xs", "regular", "left", "center")
        end
        Primitives.drawRoundedRect(absX + 1, absY + self.headerHeight - 1, w - 2, 1, 0, Utils.withAlpha(theme.border, 130 * alphaRatio), nil, 0, false)
    end
end

NovaUI.registerComponent("card", Card, { "Card" })

-- ============================================================================
-- 3. StatsCard Component (Dashboard KPI Metric Card with Trend & Sparkbars)
-- ============================================================================
local StatsCard = NovaUI.Class("StatsCard", NovaUI.Component)

function StatsCard:onCreate(props)
    if not props.width and not props.w then self._rawW = 220; self.width = NovaUI.scale(220) end
    if not props.height and not props.h then self._rawH = 106; self.height = NovaUI.scale(106) end
    self.title = tostring(props.title or "Metric")
    self.value = tostring(props.value or "0")
    self.trend = props.trend and tostring(props.trend) or nil
    self.trendUp = props.trendUp ~= false
    self.icon = props.icon or "chart"
    self.accent = props.variant or props.accent or "primary"
    self.sparkline = type(props.sparkline) == "table" and props.sparkline or { 0.35, 0.55, 0.45, 0.75, 0.62, 0.90 }
end

function StatsCard:setMetric(value, trend, trendUp)
    self.value = tostring(value)
    if trend ~= nil then self.trend = tostring(trend) end
    if trendUp ~= nil then self.trendUp = trendUp end
    self._dirty = true
    return self
end

function StatsCard:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local accentCol = theme[self.accent] or theme.primary
    local softCol = theme[self.accent .. "Soft"] or theme.primarySoft

    Primitives.drawGlassPanel(absX, absY, w, h, "md", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(theme.border, 200 * alphaRatio), "sm", false)

    -- Top accent strip
    Primitives.drawRoundedRect(absX + NovaUI.scale(14), absY + 1, NovaUI.scale(32), NovaUI.scale(2), 1, Utils.withAlpha(accentCol, 240 * alphaRatio), nil, 0, false)

    local pad = NovaUI.scale(14)
    -- Icon container on top-right
    local icBox = NovaUI.scale(36)
    local icX = absX + w - pad - icBox
    local icY = absY + pad
    Primitives.drawRoundedRect(icX, icY, icBox, icBox, "sm", Utils.withAlpha(softCol, 220 * alphaRatio), nil, 0, false)
    local icSz = NovaUI.scale(18)
    NovaUI.Icons.draw(self.icon, icX + math.floor((icBox - icSz) * 0.5), icY + math.floor((icBox - icSz) * 0.5), icSz, Utils.withAlpha(accentCol, 255 * alphaRatio))

    -- Title & main value
    Primitives.drawText(self.title:upper(), absX + pad, absY + pad, w - icBox - pad * 2, NovaUI.scale(16), Utils.withAlpha(theme.textMuted, 240 * alphaRatio), "xxs", "bold", "left", "center")
    Primitives.drawText(self.value, absX + pad, absY + NovaUI.scale(34), w - icBox - pad * 2, NovaUI.scale(32), Utils.withAlpha(theme.text, 255 * alphaRatio), "h3", "bold", "left", "center")

    -- Trend badge at bottom-left
    if self.trend then
        local tCol = self.trendUp and theme.success or theme.danger
        Primitives.drawText(self.trend, absX + pad, absY + h - NovaUI.scale(26), w * 0.6, NovaUI.scale(18), Utils.withAlpha(tCol, 255 * alphaRatio), "xs", "bold", "left", "center")
    end

    -- Mini sparkline bars at bottom-right
    if self.sparkline and #self.sparkline > 0 then
        local count = #self.sparkline
        local barW = NovaUI.scale(4)
        local gap = NovaUI.scale(3)
        local maxBarH = NovaUI.scale(22)
        local startX = absX + w - pad - (count * (barW + gap))
        local baseY = absY + h - NovaUI.scale(10)
        for i = 1, count do
            local v = Utils.clamp(tonumber(self.sparkline[i]) or 0.5, 0.15, 1.0)
            local bh = math.floor(maxBarH * v)
            local bx = startX + (i - 1) * (barW + gap)
            Primitives.drawRoundedRect(bx, baseY - bh, barW, bh, 1, Utils.withAlpha(accentCol, (i == count and 245 or 130) * alphaRatio), nil, 0, false)
        end
    end
end

NovaUI.registerComponent("statscard", StatsCard, { "StatsCard" })
