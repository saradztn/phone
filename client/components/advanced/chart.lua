--[[
    NovaUI - Data Visualization Chart Component
    Supports: "line", "area", "bar", and "donut" charts inside MTA:SA
    File: client/components/advanced/chart.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

local Chart = NovaUI.Class("Chart", NovaUI.Component)

function Chart:onCreate(props)
    if not props.width and not props.w then self._rawW = 360; self.width = NovaUI.scale(360) end
    if not props.height and not props.h then self._rawH = 200; self.height = NovaUI.scale(200) end

    self.chartType = tostring(props.chartType or props.type or "line"):lower() -- "line" | "area" | "bar" | "donut"
    self.title = props.title and tostring(props.title) or nil
    self.labels = type(props.labels) == "table" and props.labels or { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }
    self.data = type(props.data) == "table" and props.data or { 42, 68, 55, 89, 74, 96, 84 }
    self.accent = props.variant or props.accent or "primary"
end

function Chart:setData(data, labels)
    if type(data) == "table" then self.data = data end
    if type(labels) == "table" then self.labels = labels end
    self._dirty = true
    return self
end

function Chart:setChartType(chartType)
    self.chartType = tostring(chartType or "line"):lower()
    self._dirty = true
    return self
end

function Chart:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local accentCol = theme[self.accent] or theme.primary

    Primitives.drawRoundedRect(absX, absY, w, h, "md", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(theme.border, 195 * alphaRatio), 1, false)

    local pad = NovaUI.scale(16)
    local topOffset = self.title and NovaUI.scale(38) or pad
    if self.title then
        Primitives.drawText(self.title, absX + pad, absY + NovaUI.scale(10), w - pad * 2, NovaUI.scale(22), Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "bold", "left", "center")
    end

    local count = #self.data
    if count == 0 then return end

    local maxVal = 1
    local sumVal = 0
    for i = 1, count do
        local v = tonumber(self.data[i]) or 0
        if v > maxVal then maxVal = v end
        sumVal = sumVal + v
    end

    -- 1. Donut Chart
    if self.chartType == "donut" then
        local radius = math.floor(math.min(w * 0.45, h - topOffset - pad) * 0.38)
        local cx = absX + math.floor(w * 0.34)
        local cy = absY + topOffset + math.floor((h - topOffset - pad) * 0.5)
        local palette = { theme.primary, theme.secondary, theme.success, theme.warning, theme.accent, theme.danger }
        local startDeg = 0

        for i = 1, count do
            local v = tonumber(self.data[i]) or 0
            local span = sumVal > 0 and ((v / sumVal) * 360) or 0
            local segCol = palette[((i - 1) % #palette) + 1]
            Primitives.drawArc(cx, cy, radius, NovaUI.scale(10), startDeg, startDeg + math.max(1, span - 2), Utils.withAlpha(segCol, 255 * alphaRatio), false)
            startDeg = startDeg + span

            -- Legend entry on right side
            local lx = absX + math.floor(w * 0.62)
            local ly = absY + topOffset + (i - 1) * NovaUI.scale(22)
            if ly + NovaUI.scale(16) <= absY + h then
                Primitives.drawRoundedRect(lx, ly + NovaUI.scale(4), NovaUI.scale(8), NovaUI.scale(8), 2, Utils.withAlpha(segCol, 255 * alphaRatio), nil, 0, false)
                local lbl = tostring(self.labels[i] or ("Item " .. i))
                Primitives.drawText(lbl, lx + NovaUI.scale(14), ly, w * 0.32, NovaUI.scale(18), Utils.withAlpha(theme.textSecondary, 240 * alphaRatio), "xs", "regular", "left", "center")
            end
        end

        Primitives.drawText(Utils.formatNumber(sumVal), cx - radius, cy - NovaUI.scale(10), radius * 2, NovaUI.scale(20), Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "bold", "center", "center")
        return
    end

    -- Cartesian Plot Area (Line, Area, Bar)
    local plotX = absX + pad + NovaUI.scale(26)
    local plotY = absY + topOffset + NovaUI.scale(6)
    local plotW = w - (plotX - absX) - pad
    local plotH = h - (plotY - absY) - NovaUI.scale(26)
    if plotW <= 10 or plotH <= 10 then return end

    -- Horizontal grid lines + Y-axis labels
    local gridSteps = 4
    for g = 0, gridSteps do
        local gy = plotY + math.floor((g / gridSteps) * plotH)
        Primitives.drawRoundedRect(plotX, gy, plotW, 1, 0, Utils.withAlpha(theme.border, 100 * alphaRatio), nil, 0, false)
        local yVal = math.floor(maxVal * (1 - g / gridSteps) + 0.5)
        Primitives.drawText(tostring(yVal), absX + pad, gy - NovaUI.scale(8), NovaUI.scale(22), NovaUI.scale(16), Utils.withAlpha(theme.textMuted, 190 * alphaRatio), "xxs", "regular", "right", "center")
    end

    if self.chartType == "bar" then
        local slotW = plotW / count
        local barW = math.max(NovaUI.scale(8), math.floor(slotW * 0.56))
        for i = 1, count do
            local v = tonumber(self.data[i]) or 0
            local ratio = Utils.clamp(v / maxVal, 0, 1)
            local bh = math.max(2, math.floor(plotH * ratio))
            local bx = plotX + math.floor((i - 0.5) * slotW - barW * 0.5)
            local by = plotY + plotH - bh

            Primitives.drawRoundedRect(bx, by, barW, bh, "xs", Utils.withAlpha(accentCol, 235 * alphaRatio), nil, 0, false)
            if self.labels[i] then
                Primitives.drawText(tostring(self.labels[i]), plotX + math.floor((i - 1) * slotW), plotY + plotH + NovaUI.scale(4), math.floor(slotW), NovaUI.scale(18), Utils.withAlpha(theme.textMuted, 220 * alphaRatio), "xxs", "regular", "center", "center")
            end
        end
    else
        -- "line" or "area" chart
        local stepX = count > 1 and (plotW / (count - 1)) or plotW
        local pts = {}
        for i = 1, count do
            local v = tonumber(self.data[i]) or 0
            local ratio = Utils.clamp(v / maxVal, 0, 1)
            local px = plotX + math.floor((i - 1) * stepX)
            local py = plotY + plotH - math.floor(plotH * ratio)
            pts[i] = { x = px, y = py }
        end

        if self.chartType == "area" then
            for i = 1, count do
                local colH = (plotY + plotH) - pts[i].y
                if colH > 0 then
                    Primitives.drawRoundedRect(pts[i].x - NovaUI.scale(2), pts[i].y, NovaUI.scale(4), colH, 0, Utils.withAlpha(accentCol, 45 * alphaRatio), nil, 0, false)
                end
            end
        end

        for i = 1, count - 1 do
            Primitives.drawLine(pts[i].x, pts[i].y, pts[i + 1].x, pts[i + 1].y, Utils.withAlpha(accentCol, 255 * alphaRatio), NovaUI.scale(2.2), false)
        end

        for i = 1, count do
            Primitives.drawCircle(pts[i].x, pts[i].y, NovaUI.scale(4), { 255, 255, 255, 255 * alphaRatio }, Utils.withAlpha(accentCol, 255 * alphaRatio), 2, false)
            if self.labels[i] then
                Primitives.drawText(tostring(self.labels[i]), pts[i].x - NovaUI.scale(20), plotY + plotH + NovaUI.scale(4), NovaUI.scale(40), NovaUI.scale(18), Utils.withAlpha(theme.textMuted, 220 * alphaRatio), "xxs", "regular", "center", "center")
            end
        end
    end
end

NovaUI.registerComponent("chart", Chart, { "Chart" })
