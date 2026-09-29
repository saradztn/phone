--[[
    NovaUI - Data Lists: VirtualList, List, and Grid
    Virtualization renders only the visible slice of items (handles 10,000+ rows at 60+ FPS)
    File: client/components/data/list.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. VirtualList Component (O(visibleRows) rendering for massive datasets)
-- ============================================================================
local VirtualList = NovaUI.Class("VirtualList", NovaUI.Component)

function VirtualList:onCreate(props)
    self.items = type(props.items) == "table" and props.items or {}
    self.rowHeight = NovaUI.scale(tonumber(props.rowHeight) or 38)
    self.scrollY = 0
    self.selectedIndex = tonumber(props.selectedIndex)
    self.hoveredIndex = nil
    self.renderItem = type(props.renderItem) == "function" and props.renderItem or nil
end

function VirtualList:setItems(items)
    self.items = type(items) == "table" and items or {}
    self.scrollY = 0
    self.selectedIndex = nil
    self._dirty = true
    return self
end

function VirtualList:addItem(item)
    table.insert(self.items, item)
    self._dirty = true
    return self
end

function VirtualList:clear()
    self.items = {}
    self.scrollY = 0
    self.selectedIndex = nil
    self._dirty = true
    return self
end

function VirtualList:getSelectedItem()
    return self.selectedIndex and self.items[self.selectedIndex] or nil
end

function VirtualList:onScroll(direction)
    local totalH = #self.items * self.rowHeight
    local maxScroll = math.max(0, totalH - self.height)
    if maxScroll <= 0 then return false end
    self.scrollY = Utils.clamp(self.scrollY - direction * (self.rowHeight * 2), 0, maxScroll)
    self._dirty = true
    return true
end

function VirtualList:onMouseMove(mx, my)
    local absX, absY = self:getScreenPosition()
    if not Utils.pointInRect(mx, my, absX, absY, self.width, self.height) then
        self.hoveredIndex = nil
        return
    end
    local relY = (my - absY) + self.scrollY
    local idx = math.floor(relY / self.rowHeight) + 1
    self.hoveredIndex = (idx >= 1 and idx <= #self.items) and idx or nil
end

function VirtualList:onMouseLeave()
    self.hoveredIndex = nil
end

function VirtualList:onClick(mx, my)
    self:onMouseMove(mx, my)
    if self.hoveredIndex and self.items[self.hoveredIndex] then
        self.selectedIndex = self.hoveredIndex
        local item = self.items[self.selectedIndex]
        self:setValue(item)
        self:emit("select", item, self.selectedIndex)
    end
end

function VirtualList:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    Primitives.drawRoundedRect(absX, absY, w, h, self.props.radius or "sm", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(theme.border, 190 * alphaRatio), 1, false)

    local totalCount = #self.items
    if totalCount == 0 then
        Primitives.drawText(self.props.emptyText or "No items to display", absX, absY, w, h, Utils.withAlpha(theme.textMuted, 190 * alphaRatio), "sm", "regular", "center", "center")
        return
    end

    -- Compute exact visible range [firstIdx .. lastIdx] (Virtualization core!)
    local firstIdx = math.max(1, math.floor(self.scrollY / self.rowHeight) + 1)
    local visibleRows = math.ceil(h / self.rowHeight) + 1
    local lastIdx = math.min(totalCount, firstIdx + visibleRows - 1)
    local padX = NovaUI.scale(12)

    for i = firstIdx, lastIdx do
        local item = self.items[i]
        local ry = absY + (i - 1) * self.rowHeight - self.scrollY
        -- Clamp row within list bounds
        if ry + self.rowHeight > absY and ry < absY + h then
            local drawY = math.max(absY + 1, ry)
            local drawH = math.min(ry + self.rowHeight, absY + h - 1) - drawY
            if drawH >= NovaUI.scale(14) then
                local isSel = (i == self.selectedIndex)
                local isHov = (i == self.hoveredIndex)

                if isSel or isHov then
                    local rowBg = isSel and theme.primarySoft or theme.surfaceHover
                    Primitives.drawRoundedRect(absX + 4, drawY, w - 12, drawH - 1, "xs", Utils.withAlpha(rowBg, (rowBg[4] or 200) * alphaRatio), nil, 0, false)
                end

                if self.renderItem then
                    self.renderItem(item, i, absX + 4, drawY, w - 12, drawH, isSel, isHov, alphaRatio)
                else
                    local label = type(item) == "table" and tostring(item.label or item.title or item.text or item[1] or "") or tostring(item)
                    local sub = type(item) == "table" and item.subtitle or nil
                    local badge = type(item) == "table" and item.badge or nil
                    local fg = isSel and theme.primary or theme.text

                    Primitives.drawText(label, absX + padX, drawY, w - padX * 2, drawH, Utils.withAlpha(fg, 255 * alphaRatio), "sm", isSel and "bold" or "regular", "left", "center")
                    if sub then
                        Primitives.drawText(tostring(sub), absX + padX, drawY, w - padX * 2 - (badge and NovaUI.scale(60) or 0), drawH, Utils.withAlpha(theme.textMuted, 220 * alphaRatio), "xs", "regular", "right", "center")
                    end
                    if badge then
                        Primitives.drawText(tostring(badge), absX + padX, drawY, w - padX * 2, drawH, Utils.withAlpha(theme.primary, 240 * alphaRatio), "xs", "bold", "right", "center")
                    end
                end
            end
        end
    end

    -- Virtual scrollbar indicator
    local totalH = totalCount * self.rowHeight
    if totalH > h then
        local barW = NovaUI.scale(4)
        local barX = absX + w - barW - 3
        local trackH = h - 8
        local thumbH = math.max(NovaUI.scale(18), math.floor(trackH * (h / totalH)))
        local maxScroll = math.max(1, totalH - h)
        local thumbY = absY + 4 + math.floor((trackH - thumbH) * (self.scrollY / maxScroll))
        Primitives.drawRoundedRect(barX, thumbY, barW, thumbH, "pill", Utils.withAlpha(theme.scrollbarThumb, 220 * alphaRatio), nil, 0, false)
    end
end

NovaUI.registerComponent("virtuallist", VirtualList, { "VirtualList" })
NovaUI.registerComponent("list", VirtualList, { "List" })

-- ============================================================================
-- 2. Grid Component (Virtualized Multi-Column Tile Grid)
-- ============================================================================
local Grid = NovaUI.Class("Grid", NovaUI.Component)

function Grid:onCreate(props)
    self.items = type(props.items) == "table" and props.items or {}
    self.columns = math.max(1, tonumber(props.columns) or 3)
    self.cellHeight = NovaUI.scale(tonumber(props.cellHeight) or 84)
    self.gap = NovaUI.scale(tonumber(props.gap) or 10)
    self.scrollY = 0
    self.selectedIndex = nil
    self.hoveredIndex = nil
end

function Grid:setItems(items)
    self.items = type(items) == "table" and items or {}
    self.scrollY = 0
    self._dirty = true
    return self
end

function Grid:onScroll(direction)
    local rows = math.ceil(#self.items / self.columns)
    local totalH = rows * (self.cellHeight + self.gap)
    local maxScroll = math.max(0, totalH - self.height)
    if maxScroll <= 0 then return false end
    self.scrollY = Utils.clamp(self.scrollY - direction * (self.cellHeight * 0.8), 0, maxScroll)
    return true
end

function Grid:onClick(mx, my)
    local absX, absY = self:getScreenPosition()
    local pad = self.gap
    local cellW = math.floor((self.width - pad * (self.columns + 1)) / self.columns)
    local col = math.floor((mx - absX - pad) / (cellW + pad))
    local row = math.floor((my - absY + self.scrollY - pad) / (self.cellHeight + pad))
    if col >= 0 and col < self.columns and row >= 0 then
        local idx = row * self.columns + col + 1
        if self.items[idx] then
            self.selectedIndex = idx
            self:emit("select", self.items[idx], idx)
        end
    end
end

function Grid:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    Primitives.drawRoundedRect(absX, absY, w, h, "sm", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(theme.border, 180 * alphaRatio), 1, false)

    local pad = self.gap
    local cellW = math.floor((w - pad * (self.columns + 1)) / self.columns)
    local rowStride = self.cellHeight + pad
    local firstRow = math.max(0, math.floor(self.scrollY / rowStride))
    local visibleRows = math.ceil(h / rowStride) + 1

    for r = firstRow, firstRow + visibleRows do
        for c = 0, self.columns - 1 do
            local idx = r * self.columns + c + 1
            local item = self.items[idx]
            if item then
                local cx = absX + pad + c * (cellW + pad)
                local cy = absY + pad + r * rowStride - self.scrollY
                if cy + self.cellHeight > absY and cy < absY + h then
                    local isSel = (idx == self.selectedIndex)
                    local bg = isSel and theme.primarySoft or theme.surfaceElevated
                    local border = isSel and theme.primary or theme.border
                    Primitives.drawRoundedRect(cx, cy, cellW, self.cellHeight, "sm", Utils.withAlpha(bg, 255 * alphaRatio), Utils.withAlpha(border, 210 * alphaRatio), 1, false)

                    local title = type(item) == "table" and (item.title or item.label or item[1]) or tostring(item)
                    local sub = type(item) == "table" and item.subtitle or nil
                    Primitives.drawText(tostring(title), cx + NovaUI.scale(10), cy + NovaUI.scale(12), cellW - NovaUI.scale(20), NovaUI.scale(22), Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "bold", "left", "center")
                    if sub then
                        Primitives.drawText(tostring(sub), cx + NovaUI.scale(10), cy + NovaUI.scale(38), cellW - NovaUI.scale(20), NovaUI.scale(20), Utils.withAlpha(theme.textMuted, 230 * alphaRatio), "xs", "regular", "left", "center")
                    end
                end
            end
        end
    end
end

NovaUI.registerComponent("grid", Grid, { "Grid" })
