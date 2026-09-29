--[[
    NovaUI - Advanced Overlay Component: ContextMenu
    Supports icons, shortcut labels, dividers, danger actions, and viewport-clamped positioning
    File: client/components/advanced/overlay.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

local ContextMenu = NovaUI.Class("ContextMenu", NovaUI.Component)

function ContextMenu:onCreate(props)
    self.items = type(props.items) == "table" and props.items or {}
    self.itemHeight = NovaUI.scale(tonumber(props.itemHeight) or 34)
    self._rawW = tonumber(props.width or props.w) or 200
    self.width = NovaUI.scale(self._rawW)
    self.isOpen = false
    self.visible = false
    self._passthrough = true

    if props.target and type(props.target) == "table" and props.target._isComponent then
        props.target:on("contextMenu", function(_, mx, my)
            self:openAt(mx, my)
        end)
    end
end

function ContextMenu:_calcHeight()
    local h = NovaUI.scale(8)
    for i = 1, #self.items do
        if self.items[i].divider then
            h = h + NovaUI.scale(9)
        else
            h = h + self.itemHeight
        end
    end
    return h
end

function ContextMenu:openAt(x, y)
    self.height = self:_calcHeight()
    local bx, by, bw, bh = NovaUI.fitToViewport(x or NovaUI.Input.cursorX, y or NovaUI.Input.cursorY, self.width, self.height, NovaUI.scale(8))
    self.x, self.y, self.width, self.height = bx, by, bw, bh
    self.isOpen = true
    self.visible = true
    NovaUI.Input.activePopover = self
    self:emit("open", bx, by)
    return self
end

function ContextMenu:closePopover()
    self.isOpen = false
    self.visible = false
    if NovaUI.Input.activePopover == self then
        NovaUI.Input.activePopover = nil
    end
    self:emit("close")
    return self
end

function ContextMenu:hitTestPopover(mx, my)
    if not self.isOpen then return false end
    return Utils.pointInRect(mx, my, self.x, self.y, self.width, self.height)
end

function ContextMenu:onPopoverClick(button, state, mx, my)
    if button ~= "left" or state ~= "down" then return end
    if not self:hitTestPopover(mx, my) then
        self:closePopover()
        return
    end
    local cursorY = self.y + NovaUI.scale(4)
    for i = 1, #self.items do
        local it = self.items[i]
        local rowH = it.divider and NovaUI.scale(9) or self.itemHeight
        if not it.divider and not it.disabled and my >= cursorY and my <= cursorY + rowH then
            if type(it.onClick) == "function" then
                it.onClick(it, i)
            end
            self:emit("select", it, i)
            self:closePopover()
            return
        end
        cursorY = cursorY + rowH
    end
end

function ContextMenu:render()
    if not self.isOpen then return end
    NovaUI.Renderer.enqueueOverlay(NovaUI.Tokens.zIndex.contextMenu, function()
        local theme = NovaUI.Theme
        local rx, ry, rw, rh = self.x, self.y, self.width, self.height
        Primitives.drawGlassPanel(rx, ry, rw, rh, "sm", theme.surfaceElevated, theme.borderLight, "lg", true)

        local mx, my = NovaUI.Input.cursorX, NovaUI.Input.cursorY
        local pad = NovaUI.scale(4)
        local cursorY = ry + pad

        for i = 1, #self.items do
            local it = self.items[i]
            if it.divider then
                local dy = cursorY + NovaUI.scale(4)
                Primitives.drawRoundedRect(rx + NovaUI.scale(8), dy, rw - NovaUI.scale(16), 1, 0, theme.border, nil, 0, true)
                cursorY = cursorY + NovaUI.scale(9)
            else
                local isHov = not it.disabled and Utils.pointInRect(mx, my, rx + pad, cursorY, rw - pad * 2, self.itemHeight)
                if isHov then
                    local hovBg = it.danger and theme.dangerSoft or theme.surfaceHover
                    Primitives.drawRoundedRect(rx + pad, cursorY, rw - pad * 2, self.itemHeight, "xs", hovBg, nil, 0, true)
                end

                local fg = it.disabled and theme.textMuted or (it.danger and theme.danger or theme.text)
                local textX = rx + NovaUI.scale(12)
                if it.icon then
                    local icSz = NovaUI.scale(15)
                    NovaUI.Icons.draw(it.icon, textX, cursorY + math.floor((self.itemHeight - icSz) * 0.5), icSz, fg, 0, true)
                    textX = textX + icSz + NovaUI.scale(10)
                end
                Primitives.drawText(tostring(it.label or it.text or ""), textX, cursorY, rw - (textX - rx) - NovaUI.scale(12), self.itemHeight, fg, "sm", "regular", "left", "center", true, false, true)
                if it.shortcut then
                    Primitives.drawText(tostring(it.shortcut), rx, cursorY, rw - NovaUI.scale(12), self.itemHeight, theme.textMuted, "xs", "regular", "right", "center", true, false, true)
                end
                cursorY = cursorY + self.itemHeight
            end
        end
    end)
end

NovaUI.registerComponent("contextmenu", ContextMenu, { "ContextMenu" })
