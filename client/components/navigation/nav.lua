--[[
    NovaUI - Navigation Components: Sidebar, Navbar, Breadcrumb, Pagination
    File: client/components/navigation/nav.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. Sidebar Component
-- ============================================================================
local Sidebar = NovaUI.Class("Sidebar", NovaUI.Component)

function Sidebar:onCreate(props)
    if not props.width and not props.w then
        self._rawW = 220
        self.width = NovaUI.scale(220)
    end
    self.brandTitle = props.brandTitle or props.title or "NovaUI"
    self.brandSubtitle = props.brandSubtitle or "FRAMEWORK v3.0"
    self.logo = props.logo or "assets/images/logo.png"
    self._logoTex = self:trackTexture(self.logo)

    self.items = {}
    self.activeId = props.activeId
    self._hoveredIdx = nil
    self.itemHeight = NovaUI.scale(tonumber(props.itemHeight) or 40)
    self.headerOffset = NovaUI.scale(72)

    if type(props.items) == "table" then
        for i = 1, #props.items do
            local it = props.items[i]
            table.insert(self.items, {
                id    = it.id or i,
                label = tostring(it.label or it.text or ("Item " .. i)),
                icon  = it.icon or "dashboard",
                badge = it.badge,
            })
        end
        if not self.activeId and self.items[1] then
            self.activeId = self.items[1].id
        end
    end
end

function Sidebar:addItem(item)
    if type(item) ~= "table" then return self end
    table.insert(self.items, {
        id    = item.id or (#self.items + 1),
        label = tostring(item.label or item.text or "Item"),
        icon  = item.icon or "dashboard",
        badge = item.badge,
    })
    if not self.activeId then self.activeId = self.items[1].id end
    self._dirty = true
    return self
end

function Sidebar:setActive(id, silent)
    local prev = self.activeId
    self.activeId = id
    self.state.value = id
    self._dirty = true
    if not silent and prev ~= id then
        self:emit("change", id)
    end
    return self
end

function Sidebar:onMouseMove(mx, my)
    local absX, absY = self:getScreenPosition()
    local startY = absY + self.headerOffset
    local gap = NovaUI.scale(4)
    self._hoveredIdx = nil
    for i = 1, #self.items do
        local iy = startY + (i - 1) * (self.itemHeight + gap)
        if Utils.pointInRect(mx, my, absX + NovaUI.scale(8), iy, self.width - NovaUI.scale(16), self.itemHeight) then
            self._hoveredIdx = i
            break
        end
    end
end

function Sidebar:onMouseLeave()
    self._hoveredIdx = nil
end

function Sidebar:onClick(mx, my)
    self:onMouseMove(mx, my)
    if self._hoveredIdx and self.items[self._hoveredIdx] then
        local it = self.items[self._hoveredIdx]
        self:setActive(it.id)
        self:emit("select", it.id, it)
    end
end

function Sidebar:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    Primitives.drawRoundedRect(absX, absY, w, h, self.props.radius or 0, Utils.withAlpha(theme.sidebar, 255 * alphaRatio), Utils.withAlpha(theme.border, 160 * alphaRatio), 1, false)

    -- Brand header
    local pad = NovaUI.scale(14)
    local logoSz = NovaUI.scale(34)
    if self._logoTex and type(dxDrawImage) == "function" then
        dxDrawImage(absX + pad, absY + NovaUI.scale(16), logoSz, logoSz, self._logoTex, 0, 0, 0, Utils.toColor({ 255, 255, 255, 255 }, alphaRatio), false)
    end
    local tx = absX + pad + logoSz + NovaUI.scale(10)
    Primitives.drawText(self.brandTitle, tx, absY + NovaUI.scale(14), w - (tx - absX) - pad, NovaUI.scale(20), Utils.withAlpha(theme.text, 255 * alphaRatio), "md", "bold", "left", "center")
    Primitives.drawText(self.brandSubtitle, tx, absY + NovaUI.scale(33), w - (tx - absX) - pad, NovaUI.scale(16), Utils.withAlpha(theme.primary, 230 * alphaRatio), "xxs", "bold", "left", "center")

    Primitives.drawRoundedRect(absX + pad, absY + self.headerOffset - NovaUI.scale(10), w - pad * 2, 1, 0, Utils.withAlpha(theme.border, 140 * alphaRatio), nil, 0, false)

    -- Navigation items
    local startY = absY + self.headerOffset
    local gap = NovaUI.scale(4)
    local itemPad = NovaUI.scale(10)

    for i = 1, #self.items do
        local it = self.items[i]
        local iy = startY + (i - 1) * (self.itemHeight + gap)
        local isAct = (it.id == self.activeId)
        local isHov = (i == self._hoveredIdx)

        if isAct or isHov then
            local bg = isAct and theme.primarySoft or theme.surfaceHover
            Primitives.drawRoundedRect(absX + itemPad, iy, w - itemPad * 2, self.itemHeight, "sm", Utils.withAlpha(bg, (bg[4] or 200) * alphaRatio), nil, 0, false)
        end

        if isAct then
            Primitives.drawRoundedRect(absX + itemPad, iy + NovaUI.scale(8), NovaUI.scale(3), self.itemHeight - NovaUI.scale(16), 1, Utils.withAlpha(theme.primary, 255 * alphaRatio), nil, 0, false)
        end

        local fg = isAct and theme.primary or (isHov and theme.text or theme.textSecondary)
        local icSz = NovaUI.scale(17)
        NovaUI.Icons.draw(it.icon, absX + itemPad + NovaUI.scale(12), iy + math.floor((self.itemHeight - icSz) * 0.5), icSz, Utils.withAlpha(fg, 255 * alphaRatio))

        local labelX = absX + itemPad + NovaUI.scale(38)
        Primitives.drawText(it.label, labelX, iy, w - (labelX - absX) - itemPad, self.itemHeight, Utils.withAlpha(fg, 255 * alphaRatio), "sm", isAct and "bold" or "regular", "left", "center")

        if it.badge then
            local badgeW = NovaUI.scale(26)
            local badgeH = NovaUI.scale(18)
            local bx = absX + w - itemPad - badgeW - NovaUI.scale(8)
            local by = iy + math.floor((self.itemHeight - badgeH) * 0.5)
            Primitives.drawRoundedRect(bx, by, badgeW, badgeH, "pill", Utils.withAlpha(theme.primarySoft, 220 * alphaRatio), nil, 0, false)
            Primitives.drawText(tostring(it.badge), bx, by, badgeW, badgeH, Utils.withAlpha(theme.primary, 255 * alphaRatio), "xxs", "bold", "center", "center")
        end
    end
end

NovaUI.registerComponent("sidebar", Sidebar, { "Sidebar" })

-- ============================================================================
-- 2. Navbar Component
-- ============================================================================
local Navbar = NovaUI.Class("Navbar", NovaUI.Component)

function Navbar:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 52
        self.height = NovaUI.scale(52)
    end
    self.title = tostring(props.title or "Dashboard")
    self.subtitle = props.subtitle and tostring(props.subtitle) or nil
end

function Navbar:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    Primitives.drawRoundedRect(absX, absY, w, h, 0, Utils.withAlpha(theme.header, 255 * alphaRatio), nil, 0, false)
    Primitives.drawRoundedRect(absX, absY + h - 1, w, 1, 0, Utils.withAlpha(theme.border, 160 * alphaRatio), nil, 0, false)

    local padX = NovaUI.scale(18)
    Primitives.drawText(self.title, absX + padX, absY, w * 0.5, h, Utils.withAlpha(theme.text, 255 * alphaRatio), "lg", "bold", "left", "center")
    if self.subtitle then
        local tw = NovaUI.Fonts.getTextWidth(self.title, "lg", "bold")
        Primitives.drawText(self.subtitle, absX + padX + tw + NovaUI.scale(12), absY, w * 0.4, h, Utils.withAlpha(theme.textMuted, 230 * alphaRatio), "xs", "regular", "left", "center")
    end
end

NovaUI.registerComponent("navbar", Navbar, { "Navbar" })

-- ============================================================================
-- 3. Breadcrumb Component
-- ============================================================================
local Breadcrumb = NovaUI.Class("Breadcrumb", NovaUI.Component)

function Breadcrumb:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 28
        self.height = NovaUI.scale(28)
    end
    self.items = type(props.items) == "table" and props.items or { "Home", "Dashboard" }
end

function Breadcrumb:setItems(items)
    if type(items) == "table" then
        self.items = items
        self._dirty = true
    end
    return self
end

function Breadcrumb:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local cursorX = absX
    local sepW = NovaUI.scale(18)

    for i = 1, #self.items do
        local label = tostring(type(self.items[i]) == "table" and self.items[i].label or self.items[i])
        local isLast = (i == #self.items)
        local tw = NovaUI.Fonts.getTextWidth(label, "xs", isLast and "bold" or "regular") + NovaUI.scale(4)
        local col = isLast and theme.primary or theme.textMuted

        Primitives.drawText(label, cursorX, absY, tw, h, Utils.withAlpha(col, 255 * alphaRatio), "xs", isLast and "bold" or "regular", "left", "center")
        cursorX = cursorX + tw

        if not isLast then
            Primitives.drawText("/", cursorX, absY, sepW, h, Utils.withAlpha(theme.textMuted, 160 * alphaRatio), "xs", "regular", "center", "center")
            cursorX = cursorX + sepW
        end
    end
end

NovaUI.registerComponent("breadcrumb", Breadcrumb, { "Breadcrumb" })

-- ============================================================================
-- 4. Pagination Component
-- ============================================================================
local Pagination = NovaUI.Class("Pagination", NovaUI.Component)

function Pagination:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 32
        self.height = NovaUI.scale(32)
    end
    self.page = math.max(1, tonumber(props.page or props.value) or 1)
    self.totalPages = math.max(1, tonumber(props.totalPages) or 5)
    self.state.value = self.page
end

function Pagination:setPage(page, silent)
    local p = Utils.clamp(math.floor(tonumber(page) or 1), 1, self.totalPages)
    self.page = p
    return self:setValue(p, silent)
end

function Pagination:onClick(mx)
    local absX = self:getScreenPosition()
    local btnW = NovaUI.scale(30)
    local gap = NovaUI.scale(4)
    local idx = math.floor((mx - absX) / (btnW + gap))
    if idx == 0 then
        self:setPage(self.page - 1)
    elseif idx == self.totalPages + 1 then
        self:setPage(self.page + 1)
    elseif idx >= 1 and idx <= self.totalPages then
        self:setPage(idx)
    end
end

function Pagination:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local btnW = NovaUI.scale(30)
    local gap = NovaUI.scale(4)

    -- Prev button
    Primitives.drawRoundedRect(absX, absY, btnW, h, "xs", Utils.withAlpha(theme.surfaceElevated, 255 * alphaRatio), Utils.withAlpha(theme.border, 180 * alphaRatio), 1, false)
    NovaUI.Icons.draw("chevron-left", absX + NovaUI.scale(8), absY + math.floor((h - NovaUI.scale(14)) * 0.5), NovaUI.scale(14), Utils.withAlpha(theme.text, 240 * alphaRatio))

    for i = 1, self.totalPages do
        local bx = absX + i * (btnW + gap)
        local isAct = (i == self.page)
        local bg = isAct and theme.primary or theme.surface
        local fg = isAct and theme.textInverse or theme.textSecondary
        Primitives.drawRoundedRect(bx, absY, btnW, h, "xs", Utils.withAlpha(bg, 255 * alphaRatio), Utils.withAlpha(isAct and theme.primary or theme.border, 190 * alphaRatio), 1, false)
        Primitives.drawText(tostring(i), bx, absY, btnW, h, Utils.withAlpha(fg, 255 * alphaRatio), "xs", "bold", "center", "center")
    end

    -- Next button
    local nx = absX + (self.totalPages + 1) * (btnW + gap)
    Primitives.drawRoundedRect(nx, absY, btnW, h, "xs", Utils.withAlpha(theme.surfaceElevated, 255 * alphaRatio), Utils.withAlpha(theme.border, 180 * alphaRatio), 1, false)
    NovaUI.Icons.draw("chevron-right", nx + NovaUI.scale(8), absY + math.floor((h - NovaUI.scale(14)) * 0.5), NovaUI.scale(14), Utils.withAlpha(theme.text, 240 * alphaRatio))
end

NovaUI.registerComponent("pagination", Pagination, { "Pagination" })
