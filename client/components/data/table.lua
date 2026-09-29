--[[
    NovaUI - Enterprise Data Table Component
    Features: Sortable columns, search filter, virtualized row rendering, badge/status cells, row selection
    File: client/components/data/table.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

local Table = NovaUI.Class("Table", NovaUI.Component)

function Table:onCreate(props)
    self.columns = type(props.columns) == "table" and props.columns or {
        { key = "col1", label = "Name", width = 160, sortable = true },
        { key = "col2", label = "Value", width = 120, sortable = true },
    }
    self.rawData = type(props.data or props.rows) == "table" and (props.data or props.rows) or {}
    self.rows = Utils.shallowCopy(self.rawData)
    self.headerHeight = NovaUI.scale(tonumber(props.headerHeight) or 38)
    self.rowHeight = NovaUI.scale(tonumber(props.rowHeight) or 36)
    self.striped = props.striped ~= false

    self.sortColumn = nil
    self.sortAsc = true
    self.filterQuery = ""
    self.scrollY = 0
    self.selectedIndex = nil
    self.hoveredIndex = nil
end

function Table:setData(rows)
    self.rawData = type(rows) == "table" and rows or {}
    self:_applyFilterAndSort()
    self.scrollY = 0
    self.selectedIndex = nil
    self._dirty = true
    return self
end

function Table:addRow(row)
    table.insert(self.rawData, row)
    self:_applyFilterAndSort()
    self._dirty = true
    return self
end

function Table:clear()
    return self:setData({})
end

function Table:setFilter(query)
    self.filterQuery = tostring(query or ""):lower()
    self:_applyFilterAndSort()
    self.scrollY = 0
    self._dirty = true
    return self
end

function Table:sortBy(colKey, ascending)
    if ascending ~= nil then
        self.sortAsc = ascending
    elseif self.sortColumn == colKey then
        self.sortAsc = not self.sortAsc
    else
        self.sortAsc = true
    end
    self.sortColumn = colKey
    self:_applyFilterAndSort()
    self._dirty = true
    self:emit("sort", colKey, self.sortAsc)
    return self
end

function Table:_applyFilterAndSort()
    local filtered = {}
    local q = self.filterQuery
    for i = 1, #self.rawData do
        local row = self.rawData[i]
        if q == "" then
            table.insert(filtered, row)
        else
            local matched = false
            for _, col in ipairs(self.columns) do
                local v = tostring(row[col.key] or ""):lower()
                if v:find(q, 1, true) then
                    matched = true
                    break
                end
            end
            if matched then
                table.insert(filtered, row)
            end
        end
    end

    if self.sortColumn then
        local key = self.sortColumn
        local asc = self.sortAsc
        table.sort(filtered, function(a, b)
            local va, vb = a[key], b[key]
            local na, nb = tonumber(va), tonumber(vb)
            if na and nb then
                return asc and (na < nb) or (na > nb)
            end
            local sa, sb = tostring(va or ""), tostring(vb or "")
            return asc and (sa < sb) or (sa > sb)
        end)
    end
    self.rows = filtered
end

function Table:getSelectedRow()
    return self.selectedIndex and self.rows[self.selectedIndex] or nil
end

function Table:onScroll(direction)
    local bodyH = self.height - self.headerHeight
    local totalH = #self.rows * self.rowHeight
    local maxScroll = math.max(0, totalH - bodyH)
    if maxScroll <= 0 then return false end
    self.scrollY = Utils.clamp(self.scrollY - direction * (self.rowHeight * 2), 0, maxScroll)
    self._dirty = true
    return true
end

function Table:onMouseMove(mx, my)
    local absX, absY = self:getScreenPosition()
    local bodyY = absY + self.headerHeight
    if my < bodyY or my > absY + self.height then
        self.hoveredIndex = nil
        return
    end
    local idx = math.floor(((my - bodyY) + self.scrollY) / self.rowHeight) + 1
    self.hoveredIndex = (idx >= 1 and idx <= #self.rows) and idx or nil
end

function Table:onMouseLeave()
    self.hoveredIndex = nil
end

function Table:onClick(mx, my)
    local absX, absY = self:getScreenPosition()
    -- 1. Check column header click for sorting
    if my >= absY and my <= absY + self.headerHeight then
        local cursorX = absX
        for i = 1, #self.columns do
            local col = self.columns[i]
            local cw = NovaUI.scale(tonumber(col.width) or 120)
            if mx >= cursorX and mx <= cursorX + cw then
                if col.sortable ~= false then
                    self:sortBy(col.key)
                end
                return
            end
            cursorX = cursorX + cw
        end
        return
    end

    -- 2. Check row selection
    self:onMouseMove(mx, my)
    if self.hoveredIndex and self.rows[self.hoveredIndex] then
        self.selectedIndex = self.hoveredIndex
        local row = self.rows[self.selectedIndex]
        self:setValue(row)
        self:emit("select", row, self.selectedIndex)
    end
end

function Table:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    Primitives.drawRoundedRect(absX, absY, w, h, "md", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(theme.border, 200 * alphaRatio), 1, false)

    -- 1. Table Header
    Primitives.drawRoundedRect(absX + 1, absY + 1, w - 2, self.headerHeight - 1, "md", Utils.withAlpha(theme.surfaceElevated, 255 * alphaRatio), nil, 0, false)
    Primitives.drawRoundedRect(absX + 1, absY + self.headerHeight - 1, w - 2, 1, 0, Utils.withAlpha(theme.border, 190 * alphaRatio), nil, 0, false)

    local colX = absX
    local padX = NovaUI.scale(12)
    for i = 1, #self.columns do
        local col = self.columns[i]
        local cw = NovaUI.scale(tonumber(col.width) or 120)
        local isSorted = (self.sortColumn == col.key)
        local hdrCol = isSorted and theme.primary or theme.textMuted

        Primitives.drawText(
            tostring(col.label or col.key):upper(),
            colX + padX,
            absY,
            cw - padX * 2,
            self.headerHeight,
            Utils.withAlpha(hdrCol, 245 * alphaRatio),
            "xs",
            "bold",
            col.align or "left",
            "center"
        )

        if isSorted then
            local icSz = NovaUI.scale(12)
            NovaUI.Icons.draw(
                self.sortAsc and "chevron-up" or "chevron-down",
                colX + cw - padX - icSz,
                absY + math.floor((self.headerHeight - icSz) * 0.5),
                icSz,
                Utils.withAlpha(theme.primary, 245 * alphaRatio)
            )
        end
        colX = colX + cw
    end

    -- 2. Virtualized Rows
    local bodyY = absY + self.headerHeight
    local bodyH = h - self.headerHeight
    local rowCount = #self.rows

    if rowCount == 0 then
        Primitives.drawText(self.props.emptyText or "No matching records found", absX, bodyY, w, bodyH, Utils.withAlpha(theme.textMuted, 180 * alphaRatio), "sm", "regular", "center", "center")
        return
    end

    local firstIdx = math.max(1, math.floor(self.scrollY / self.rowHeight) + 1)
    local visibleCount = math.ceil(bodyH / self.rowHeight) + 1
    local lastIdx = math.min(rowCount, firstIdx + visibleCount - 1)

    for rIdx = firstIdx, lastIdx do
        local row = self.rows[rIdx]
        local ry = bodyY + (rIdx - 1) * self.rowHeight - self.scrollY
        if ry + self.rowHeight > bodyY and ry < absY + h then
            local drawY = math.max(bodyY, ry)
            local drawH = math.min(ry + self.rowHeight, absY + h - 1) - drawY

            if drawH >= NovaUI.scale(14) then
                local isSel = (rIdx == self.selectedIndex)
                local isHov = (rIdx == self.hoveredIndex)

                if isSel then
                    Primitives.drawRoundedRect(absX + 2, drawY, w - 4, drawH, 0, Utils.withAlpha(theme.primarySoft, 220 * alphaRatio), nil, 0, false)
                elseif isHov then
                    Primitives.drawRoundedRect(absX + 2, drawY, w - 4, drawH, 0, Utils.withAlpha(theme.surfaceHover, 190 * alphaRatio), nil, 0, false)
                elseif self.striped and (rIdx % 2 == 0) then
                    Primitives.drawRoundedRect(absX + 2, drawY, w - 4, drawH, 0, Utils.withAlpha(theme.backgroundAlt, 110 * alphaRatio), nil, 0, false)
                end

                local cx = absX
                for cIdx = 1, #self.columns do
                    local col = self.columns[cIdx]
                    local cw = NovaUI.scale(tonumber(col.width) or 120)
                    local cellVal = tostring(row[col.key] or "")

                    if col.type == "badge" or col.type == "status" then
                        local vLower = cellVal:lower()
                        local badgeBg, badgeFg = theme.primarySoft, theme.primary
                        if vLower == "active" or vLower == "online" or vLower == "paid" or vLower == "ready" then
                            badgeBg, badgeFg = theme.successSoft, theme.success
                        elseif vLower == "pending" or vLower == "away" or vLower == "warning" or vLower == "idle" then
                            badgeBg, badgeFg = theme.warningSoft, theme.warning
                        elseif vLower == "banned" or vLower == "offline" or vLower == "error" or vLower == "danger" then
                            badgeBg, badgeFg = theme.dangerSoft, theme.danger
                        end
                        local bw = math.min(cw - padX * 2, NovaUI.Fonts.getTextWidth(cellVal, "xs", "bold") + NovaUI.scale(16))
                        local bh = NovaUI.scale(20)
                        local bx = cx + padX
                        local by = drawY + math.floor((drawH - bh) * 0.5)
                        Primitives.drawRoundedRect(bx, by, bw, bh, "pill", Utils.withAlpha(badgeBg, 220 * alphaRatio), nil, 0, false)
                        Primitives.drawText(cellVal, bx, by, bw, bh, Utils.withAlpha(badgeFg, 255 * alphaRatio), "xs", "bold", "center", "center")
                    else
                        local textCol = (cIdx == 1 or isSel) and theme.text or theme.textSecondary
                        Primitives.drawText(cellVal, cx + padX, drawY, cw - padX * 2, drawH, Utils.withAlpha(textCol, 255 * alphaRatio), "sm", cIdx == 1 and "bold" or "regular", col.align or "left", "center")
                    end
                    cx = cx + cw
                end
            end
        end
    end
end

NovaUI.registerComponent("table", Table, { "Table", "gridlist" })
