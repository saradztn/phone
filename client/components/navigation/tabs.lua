--[[
    NovaUI - Navigation Tabs & TabBar Components
    File: client/components/navigation/tabs.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. TabBar Component (Standalone Tab Strip)
-- ============================================================================
local TabBar = NovaUI.Class("TabBar", NovaUI.Component)

function TabBar:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 40
        self.height = NovaUI.scale(40)
    end
    self.tabs = {}
    self.variant = props.variant or "pills" -- "pills" | "underline"
    self.activeIndex = tonumber(props.activeIndex) or 1
    self._hoveredTab = nil

    if type(props.tabs) == "table" then
        for i = 1, #props.tabs do
            local t = props.tabs[i]
            if type(t) == "table" then
                table.insert(self.tabs, {
                    id    = t.id or i,
                    label = tostring(t.label or t.title or t.text or ("Tab " .. i)),
                    icon  = t.icon,
                    badge = t.badge,
                })
            else
                table.insert(self.tabs, { id = i, label = tostring(t) })
            end
        end
    end
end

function TabBar:addTab(label, id, icon, badge)
    local idx = #self.tabs + 1
    table.insert(self.tabs, {
        id    = id or idx,
        label = tostring(label or ("Tab " .. idx)),
        icon  = icon,
        badge = badge,
    })
    self._dirty = true
    return idx
end

function TabBar:setActiveTab(indexOrId, silent)
    for i = 1, #self.tabs do
        if i == indexOrId or self.tabs[i].id == indexOrId or self.tabs[i].label == indexOrId then
            local prev = self.activeIndex
            self.activeIndex = i
            self.state.value = self.tabs[i].id
            self._dirty = true
            if not silent and prev ~= i then
                self:emit("change", self.tabs[i].id, i, self.tabs[i])
            end
            return true
        end
    end
    return false
end

function TabBar:onMouseMove(mx, my)
    local absX, absY = self:getScreenPosition()
    local count = #self.tabs
    if count == 0 then return end
    local tabW = self.width / count
    local idx = math.floor((mx - absX) / tabW) + 1
    self._hoveredTab = (idx >= 1 and idx <= count and Utils.pointInRect(mx, my, absX, absY, self.width, self.height)) and idx or nil
end

function TabBar:onMouseLeave()
    self._hoveredTab = nil
end

function TabBar:onClick(mx)
    local count = #self.tabs
    if count == 0 then return end
    local absX = self:getScreenPosition()
    local tabW = self.width / count
    local idx = Utils.clamp(math.floor((mx - absX) / tabW) + 1, 1, count)
    self:setActiveTab(idx)
end

function TabBar:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local count = #self.tabs
    if count == 0 then return end

    if self.variant == "pills" then
        Primitives.drawRoundedRect(absX, absY, w, h, "sm", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(theme.border, 190 * alphaRatio), 1, false)
    else
        Primitives.drawRoundedRect(absX, absY + h - 1, w, 1, 0, Utils.withAlpha(theme.border, 190 * alphaRatio), nil, 0, false)
    end

    local pad = NovaUI.scale(4)
    local tabW = (w - pad * 2) / count

    for i = 1, count do
        local tab = self.tabs[i]
        local tx = absX + pad + math.floor((i - 1) * tabW)
        local tw = math.floor(tabW)
        local isAct = (i == self.activeIndex)
        local isHov = (i == self._hoveredTab)

        if self.variant == "pills" then
            if isAct then
                Primitives.drawRoundedRect(tx, absY + pad, tw, h - pad * 2, "xs", Utils.withAlpha(theme.primary, 255 * alphaRatio), nil, 0, false)
            elseif isHov then
                Primitives.drawRoundedRect(tx, absY + pad, tw, h - pad * 2, "xs", Utils.withAlpha(theme.surfaceHover, 200 * alphaRatio), nil, 0, false)
            end
        else
            if isAct then
                Primitives.drawRoundedRect(tx + NovaUI.scale(8), absY + h - NovaUI.scale(3), tw - NovaUI.scale(16), NovaUI.scale(3), 1, Utils.withAlpha(theme.primary, 255 * alphaRatio), nil, 0, false)
            end
        end

        local textCol = isAct and (self.variant == "pills" and theme.textInverse or theme.primary) or (isHov and theme.text or theme.textSecondary)
        Primitives.drawText(tab.label, tx, absY, tw, h, Utils.withAlpha(textCol, 255 * alphaRatio), "sm", isAct and "bold" or "regular", "center", "center")
    end
end

NovaUI.registerComponent("tabbar", TabBar, { "TabBar" })

-- ============================================================================
-- 2. Tabs Component (Full Tabbed Container with Content Panels)
-- ============================================================================
local Tabs = NovaUI.Class("Tabs", NovaUI.Component)

function Tabs:onCreate(props)
    self.barHeight = NovaUI.scale(tonumber(props.barHeight) or 40)
    self.gap = NovaUI.scale(tonumber(props.gap) or 10)
    self.panels = {}

    self.tabBar = TabBar.new("tabbar", {
        x = 0,
        y = 0,
        width = self._rawW,
        height = NovaUI.unscale(self.barHeight),
        variant = props.variant or "pills",
    }, self)

    self.tabBar:on("change", function(tabId, idx)
        self:_syncPanels(idx)
        self:emit("change", tabId, idx)
    end)

    if type(props.tabs) == "table" then
        for i = 1, #props.tabs do
            local t = props.tabs[i]
            if type(t) == "table" then
                self:addTab(t.label or t.title or ("Tab " .. i), t.id or i, t.icon)
            else
                self:addTab(tostring(t), i)
            end
        end
    end
end

function Tabs:addTab(label, id, icon)
    local idx = self.tabBar:addTab(label, id, icon)
    local contentY = NovaUI.unscale(self.barHeight + self.gap)
    local contentH = math.max(20, self._rawH - contentY)
    local panel = NovaUI.create("container", {
        x = 0,
        y = contentY,
        width = self._rawW,
        height = contentH,
        visible = (idx == self.tabBar.activeIndex),
    }, self)
    self.panels[idx] = panel
    return panel, idx
end

function Tabs:getTabPanel(indexOrId)
    for i = 1, #self.tabBar.tabs do
        if i == indexOrId or self.tabBar.tabs[i].id == indexOrId or self.tabBar.tabs[i].label == indexOrId then
            return self.panels[i]
        end
    end
    return nil
end

function Tabs:setActiveTab(indexOrId)
    self.tabBar:setActiveTab(indexOrId)
    self:_syncPanels(self.tabBar.activeIndex)
    return self
end

function Tabs:_syncPanels(activeIdx)
    for i = 1, #self.panels do
        if self.panels[i] and not self.panels[i]._destroyed then
            self.panels[i]:setVisible(i == activeIdx)
        end
    end
end

function Tabs:render() end

NovaUI.registerComponent("tabs", Tabs, { "Tabs", "tabpanel" })
