--[[
    NovaUI - Select Components: Dropdown & Searchable ComboBox
    Renders floating menu in Renderer's top overlay pass so it is never clipped by parent containers.
    File: client/components/input/select.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- Normalize items into { label = ..., value = ..., icon = ... }
local function _normalizeOptions(items)
    local out = {}
    if type(items) ~= "table" then return out end
    for i = 1, #items do
        local it = items[i]
        if type(it) == "table" then
            table.insert(out, {
                label = tostring(it.label or it.text or it.value or it[1] or ""),
                value = it.value ~= nil and it.value or (it.label or it.text or it[1]),
                icon  = it.icon,
            })
        else
            table.insert(out, { label = tostring(it), value = it })
        end
    end
    return out
end

-- ============================================================================
-- 1. Dropdown Component
-- ============================================================================
local Dropdown = NovaUI.Class("Dropdown", NovaUI.Component)

function Dropdown:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 38
        self.height = NovaUI.scale(38)
    end
    self.options = _normalizeOptions(props.options or props.items or {})
    self.placeholder = tostring(props.placeholder or "Select option...")
    self.maxVisibleItems = tonumber(props.maxVisibleItems) or 6
    self.itemHeight = NovaUI.scale(tonumber(props.itemHeight) or 34)
    self.isOpen = false
    self.scrollOffset = 0
    self.hoveredIndex = nil
    self.selectedIndex = nil

    if props.selectedIndex and self.options[props.selectedIndex] then
        self.selectedIndex = props.selectedIndex
        self.state.value = self.options[props.selectedIndex].value
    elseif props.value ~= nil then
        self:setValue(props.value, true)
    end
end

function Dropdown:setOptions(options)
    self.options = _normalizeOptions(options)
    self.selectedIndex = nil
    self.scrollOffset = 0
    self._dirty = true
    return self
end

function Dropdown:addItem(label, value, icon)
    table.insert(self.options, {
        label = tostring(label),
        value = value ~= nil and value or label,
        icon  = icon,
    })
    self._dirty = true
    return self
end

function Dropdown:setValue(val, silent)
    self.selectedIndex = nil
    for i = 1, #self.options do
        if self.options[i].value == val or self.options[i].label == val then
            self.selectedIndex = i
            val = self.options[i].value
            break
        end
    end
    return NovaUI.Component.setValue(self, val, silent)
end

function Dropdown:getSelectedItem()
    return self.selectedIndex and self.options[self.selectedIndex] or nil
end

function Dropdown:_getMenuRect()
    local absX, absY = self:getScreenPosition()
    local count = math.min(#self.options, self.maxVisibleItems)
    local menuH = count * self.itemHeight + NovaUI.scale(8)
    local _, sh = NovaUI.getScreenSize()
    local menuY = absY + self.height + NovaUI.scale(4)
    if menuY + menuH > sh - NovaUI.scale(8) and (absY - menuH - NovaUI.scale(4)) > 0 then
        menuY = absY - menuH - NovaUI.scale(4)
    end
    return absX, menuY, self.width, menuH
end

function Dropdown:openPopover()
    if self.props.disabled or #self.options == 0 then return end
    if NovaUI.Input.activePopover and NovaUI.Input.activePopover ~= self then
        if type(NovaUI.Input.activePopover.closePopover) == "function" then
            NovaUI.Input.activePopover:closePopover()
        end
    end
    self.isOpen = true
    NovaUI.Input.activePopover = self
    self:emit("open")
end

function Dropdown:closePopover()
    if not self.isOpen then return end
    self.isOpen = false
    self.hoveredIndex = nil
    if NovaUI.Input.activePopover == self then
        NovaUI.Input.activePopover = nil
    end
    self:emit("close")
end

function Dropdown:onClick()
    if self.isOpen then
        self:closePopover()
    else
        self:openPopover()
    end
end

function Dropdown:hitTestPopover(mx, my)
    if not self.isOpen then return false end
    local rx, ry, rw, rh = self:_getMenuRect()
    return Utils.pointInRect(mx, my, rx, ry, rw, rh)
end

function Dropdown:onPopoverScroll(direction)
    if not self.isOpen then return false end
    local maxScroll = math.max(0, #self.options - self.maxVisibleItems)
    self.scrollOffset = Utils.clamp(self.scrollOffset - direction, 0, maxScroll)
    return true
end

function Dropdown:onPopoverClick(button, state, mx, my)
    if button ~= "left" or state ~= "down" then return end
    local rx, ry, rw, rh = self:_getMenuRect()
    if not Utils.pointInRect(mx, my, rx, ry, rw, rh) then
        self:closePopover()
        return
    end
    local relY = my - (ry + NovaUI.scale(4))
    local idx = math.floor(relY / self.itemHeight) + 1 + self.scrollOffset
    if self.options[idx] then
        self.selectedIndex = idx
        self:setValue(self.options[idx].value)
        self:emit("select", self.options[idx], idx)
        self:closePopover()
    end
end

function Dropdown:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local isFocused = self.isOpen or self.state.focused
    local bg = isFocused and theme.surfaceElevated or (self.state.hovered and theme.surfaceHover or theme.surface)
    local border = isFocused and theme.borderFocus or theme.border

    Primitives.drawRoundedRect(absX, absY, w, h, "sm", Utils.withAlpha(bg, 255 * alphaRatio), Utils.withAlpha(border, 235 * alphaRatio), isFocused and 1.5 or 1, false)

    local padX = NovaUI.scale(12)
    local selected = self:getSelectedItem()
    local labelText = selected and selected.label or self.placeholder
    local textCol = selected and theme.text or theme.textMuted

    Primitives.drawText(labelText, absX + padX, absY, w - padX * 2 - NovaUI.scale(20), h, Utils.withAlpha(textCol, 255 * alphaRatio), "sm", "regular", "left", "center")

    local icSz = NovaUI.scale(14)
    NovaUI.Icons.draw(self.isOpen and "chevron-up" or "chevron-down", absX + w - padX - icSz, absY + math.floor((h - icSz) * 0.5), icSz, Utils.withAlpha(theme.textMuted, 240 * alphaRatio))

    -- Enqueue floating menu in top overlay pass
    if self.isOpen and #self.options > 0 then
        NovaUI.Renderer.enqueueOverlay(NovaUI.Tokens.zIndex.dropdown, function()
            local rx, ry, rw, rh = self:_getMenuRect()
            Primitives.drawGlassPanel(rx, ry, rw, rh, "sm", theme.surfaceElevated, theme.borderLight, "lg", true)

            local mx, my = NovaUI.Input.cursorX, NovaUI.Input.cursorY
            local visibleCount = math.min(#self.options, self.maxVisibleItems)
            local pad = NovaUI.scale(4)

            for i = 1, visibleCount do
                local optIdx = i + self.scrollOffset
                local opt = self.options[optIdx]
                if opt then
                    local iy = ry + pad + (i - 1) * self.itemHeight
                    local isHov = Utils.pointInRect(mx, my, rx + pad, iy, rw - pad * 2, self.itemHeight)
                    local isSel = (optIdx == self.selectedIndex)

                    if isSel or isHov then
                        local itemBg = isSel and theme.primarySoft or theme.surfaceHover
                        Primitives.drawRoundedRect(rx + pad, iy, rw - pad * 2, self.itemHeight, "xs", itemBg, nil, 0, true)
                    end

                    local itemCol = isSel and theme.primary or theme.text
                    Primitives.drawText(opt.label, rx + padX, iy, rw - padX * 2, self.itemHeight, itemCol, "sm", isSel and "bold" or "regular", "left", "center", true, false, true)
                end
            end
        end)
    end
end

NovaUI.registerComponent("dropdown", Dropdown, { "Dropdown" })

-- ============================================================================
-- 2. ComboBox Component (Editable / Filterable Dropdown)
-- ============================================================================
local ComboBox = NovaUI.Class("ComboBox", Dropdown)

function ComboBox:onCreate(props)
    Dropdown.onCreate(self, props)
    self._acceptsTextInput = true
    self.filterText = ""
end

function ComboBox:onCharacter(ch)
    if not self.isOpen then self:openPopover() end
    self.filterText = (self.filterText or "") .. tostring(ch or "")
    for i = 1, #self.options do
        if self.options[i].label:lower():find(self.filterText:lower(), 1, true) then
            self.selectedIndex = i
            self.scrollOffset = math.max(0, math.min(i - 1, #self.options - self.maxVisibleItems))
            break
        end
    end
    return true
end

function ComboBox:onKey(key, press)
    if press and key == "backspace" then
        self.filterText = ""
        return true
    end
    return false
end

NovaUI.registerComponent("combobox", ComboBox, { "ComboBox" })
