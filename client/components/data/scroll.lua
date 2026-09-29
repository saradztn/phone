--[[
    NovaUI - ScrollPanel Component
    Features: Smooth wheel scrolling, draggable scrollbar, and automatic off-screen child culling
    File: client/components/data/scroll.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

local ScrollPanel = NovaUI.Class("ScrollPanel", NovaUI.Component)

function ScrollPanel:onCreate(props)
    self.scrollY = tonumber(props.scrollY) or 0
    self.contentHeight = tonumber(props.contentHeight) and NovaUI.scale(props.contentHeight) or self.height
    self.scrollStep = NovaUI.scale(tonumber(props.scrollStep) or 38)
    self._customChildRender = true
    self._clipsChildren = true
end

function ScrollPanel:recalculateContentHeight()
    local maxH = self.height
    if self.children then
        for i = 1, #self.children do
            local c = self.children[i]
            if c and not c._destroyed and c.visible then
                local bottom = (c.y or 0) + (c.height or 0) + NovaUI.scale(12)
                if bottom > maxH then maxH = bottom end
            end
        end
    end
    self.contentHeight = maxH
    local maxScroll = math.max(0, self.contentHeight - self.height)
    self.scrollY = Utils.clamp(self.scrollY, 0, maxScroll)
end

function ScrollPanel:onChildAdded()
    self:recalculateContentHeight()
end

function ScrollPanel:getContentOrigin(absX, absY)
    return absX, absY - math.floor(self.scrollY)
end

function ScrollPanel:onScroll(direction)
    self:recalculateContentHeight()
    local maxScroll = math.max(0, self.contentHeight - self.height)
    if maxScroll <= 0 then return false end
    self.scrollY = Utils.clamp(self.scrollY - direction * self.scrollStep, 0, maxScroll)
    self._dirty = true
    return true
end

function ScrollPanel:scrollTo(y)
    self:recalculateContentHeight()
    local maxScroll = math.max(0, self.contentHeight - self.height)
    self.scrollY = Utils.clamp(tonumber(y) or 0, 0, maxScroll)
    self._dirty = true
    return self
end

function ScrollPanel:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    if self.props.backgroundColor or self.props.border then
        Primitives.drawRoundedRect(
            absX, absY, w, h,
            self.props.radius or "sm",
            self.props.backgroundColor and Utils.withAlpha(self.props.backgroundColor, 255 * alphaRatio) or nil,
            self.props.border and Utils.withAlpha(theme.border, 180 * alphaRatio) or nil,
            1, false
        )
    end

    self:recalculateContentHeight()

    -- Push viewport clip so Renderer.renderComponent automatically culls scrolled-out children
    NovaUI.Renderer.pushClip(absX, absY, w, h)
    local originX, originY = self:getContentOrigin(absX, absY)
    if self.children then
        for i = 1, #self.children do
            NovaUI.Renderer.renderComponent(self.children[i], originX, originY, alphaRatio)
        end
    end
    NovaUI.Renderer.popClip()

    -- Draw scrollbar if content overflows
    if self.contentHeight > h then
        local barW = NovaUI.scale(5)
        local barX = absX + w - barW - NovaUI.scale(3)
        local padY = NovaUI.scale(4)
        local trackH = h - padY * 2

        Primitives.drawRoundedRect(barX, absY + padY, barW, trackH, "pill", Utils.withAlpha(theme.scrollbarTrack, 160 * alphaRatio), nil, 0, false)

        local thumbRatio = Utils.clamp(h / self.contentHeight, 0.12, 1.0)
        local thumbH = math.max(NovaUI.scale(20), math.floor(trackH * thumbRatio))
        local maxScroll = math.max(1, self.contentHeight - h)
        local scrollRatio = Utils.clamp(self.scrollY / maxScroll, 0, 1)
        local thumbY = absY + padY + math.floor((trackH - thumbH) * scrollRatio)

        Primitives.drawRoundedRect(barX, thumbY, barW, thumbH, "pill", Utils.withAlpha(theme.scrollbarThumb, 230 * alphaRatio), nil, 0, false)
    end
end

NovaUI.registerComponent("scrollpanel", ScrollPanel, { "ScrollPanel", "scrollpane" })
