--[[
    NovaUI - Professional Window Component
    Supports: Drag, Resize, Minimize, Maximize, Close, Move, Focus, Z-index,
              Modal state, Header, Footer, Custom Title, Icon, and Animations.
    File: client/components/core/window.lua
]]

NovaUI = NovaUI or {}

local Window = NovaUI.Class("Window", NovaUI.Component)
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

function Window:onCreate(props)
    self._rawW = tonumber(props.width or props.w) or 640
    self._rawH = tonumber(props.height or props.h) or 440
    self.width = self._autoScale and NovaUI.scale(self._rawW) or self._rawW
    self.height = self._autoScale and NovaUI.scale(self._rawH) or self._rawH

    -- Center window by default if x/y not explicitly provided
    local sw, sh = NovaUI.getScreenSize()
    if props.x == nil then
        self.x = math.floor((sw - self.width) * 0.5)
        self._rawX = NovaUI.unscale(self.x)
    end
    if props.y == nil then
        self.y = math.floor((sh - self.height) * 0.5)
        self._rawY = NovaUI.unscale(self.y)
    end

    self.zIndex = tonumber(props.zIndex) or NovaUI.Tokens.zIndex.window
    self.title = tostring(props.title or "Window")
    self.subtitle = props.subtitle and tostring(props.subtitle) or nil
    self.icon = props.icon or nil

    self.draggable = props.draggable ~= false
    self.resizable = props.resizable ~= false
    self.minimizable = props.minimizable ~= false
    self.maximizable = props.maximizable ~= false
    self.closable = props.closable ~= false
    self.showHeader = props.showHeader ~= false
    self.showFooter = props.showFooter == true

    self.headerHeight = NovaUI.scale(tonumber(props.headerHeight) or 46)
    self.footerHeight = self.showFooter and NovaUI.scale(tonumber(props.footerHeight) or 44) or 0
    self.minWidth = NovaUI.scale(tonumber(props.minWidth) or 260)
    self.minHeight = NovaUI.scale(tonumber(props.minHeight) or 160)
    self.radius = props.radius or "lg"

    self._minimized = false
    self._maximized = false
    self._restoreRect = nil
    self._dragMode = nil -- "move" | "resize"
    self._dragOffsetX = 0
    self._dragOffsetY = 0
    self._hoveredControl = nil -- "close" | "maximize" | "minimize"
    self._clipsChildren = true

    if props.animateOpen ~= false then
        NovaUI.animate(self, {
            from = { alpha = 0, _animOffsetY = NovaUI.scale(14) },
            alpha = tonumber(props.alpha) or 255,
            _animOffsetY = 0,
            duration = NovaUI.Tokens.animation.normal,
            easing = "outQuart",
        })
    end
end

function Window:getContentOrigin(absX, absY)
    local hh = self.showHeader and self.headerHeight or 0
    return absX, absY + hh
end

function Window:getViewportRect(absX, absY, w, h)
    local hh = self.showHeader and self.headerHeight or 0
    local fh = self.showFooter and self.footerHeight or 0
    return absX, absY + hh, w, math.max(0, h - hh - fh)
end

function Window:setTitle(title, subtitle)
    self.title = tostring(title or "")
    if subtitle ~= nil then
        self.subtitle = subtitle and tostring(subtitle) or nil
    end
    self._dirty = true
    return self
end

function Window:minimize()
    if not self.minimizable then return self end
    self._minimized = not self._minimized
    self._dirty = true
    self:emit("minimize", self._minimized)
    return self
end

function Window:maximize()
    if not self.maximizable then return self end
    local sw, sh = NovaUI.getScreenSize()
    if not self._maximized then
        self._restoreRect = { x = self.x, y = self.y, w = self.width, h = self.height }
        self._maximized = true
        self._minimized = false
        local pad = NovaUI.scale(16)
        self:setPosition(pad, pad, true)
        self:setSize(sw - pad * 2, sh - pad * 2, true)
    else
        self._maximized = false
        if self._restoreRect then
            self:setPosition(self._restoreRect.x, self._restoreRect.y, true)
            self:setSize(self._restoreRect.w, self._restoreRect.h, true)
        end
    end
    self:emit("maximize", self._maximized)
    return self
end

function Window:close()
    local shouldClose = true
    local res = self:emit("close", self)
    if res == false then shouldClose = false end
    if not shouldClose then return self end

    if NovaUI.Config.enableAnimations then
        NovaUI.animate(self, {
            alpha = 0,
            _animOffsetY = NovaUI.scale(10),
            duration = NovaUI.Tokens.animation.fast,
            easing = "inQuad",
            onComplete = function()
                if self.props.destroyOnClose then
                    self:destroy()
                else
                    self:setVisible(false)
                    self.alpha = 255
                    self._animOffsetY = 0
                end
            end,
        })
    else
        if self.props.destroyOnClose then
            self:destroy()
        else
            self:setVisible(false)
        end
    end
    return self
end

function Window:_getControlRects(absX, absY, w)
    local btnSize = NovaUI.scale(26)
    local gap = NovaUI.scale(6)
    local rightX = absX + w - NovaUI.scale(12) - btnSize
    local topY = absY + math.floor((self.headerHeight - btnSize) * 0.5)
    local rects = {}
    if self.closable then
        rects.close = { x = rightX, y = topY, w = btnSize, h = btnSize }
        rightX = rightX - btnSize - gap
    end
    if self.maximizable then
        rects.maximize = { x = rightX, y = topY, w = btnSize, h = btnSize }
        rightX = rightX - btnSize - gap
    end
    if self.minimizable then
        rects.minimize = { x = rightX, y = topY, w = btnSize, h = btnSize }
    end
    return rects
end

function Window:onMouseMove(mx, my)
    if not self.showHeader then return end
    local absX, absY = self:getScreenPosition()
    local rects = self:_getControlRects(absX, absY, self.width)
    self._hoveredControl = nil
    for name, r in pairs(rects) do
        if Utils.pointInRect(mx, my, r.x, r.y, r.w, r.h) then
            self._hoveredControl = name
            break
        end
    end
end

function Window:onMouseLeave()
    self._hoveredControl = nil
end

function Window:onMouseDown(button, mx, my)
    if button ~= "left" then return end
    local absX, absY = self:getScreenPosition()
    local effectiveH = self._minimized and self.headerHeight or self.height

    -- 1. Check window header controls
    if self.showHeader then
        local rects = self:_getControlRects(absX, absY, self.width)
        if rects.close and Utils.pointInRect(mx, my, rects.close.x, rects.close.y, rects.close.w, rects.close.h) then
            self:close()
            return
        elseif rects.maximize and Utils.pointInRect(mx, my, rects.maximize.x, rects.maximize.y, rects.maximize.w, rects.maximize.h) then
            self:maximize()
            return
        elseif rects.minimize and Utils.pointInRect(mx, my, rects.minimize.x, rects.minimize.y, rects.minimize.w, rects.minimize.h) then
            self:minimize()
            return
        end
    end

    -- 2. Check bottom-right resize grip
    local gripSize = NovaUI.scale(18)
    if self.resizable and not self._minimized and not self._maximized then
        if Utils.pointInRect(mx, my, absX + self.width - gripSize, absY + effectiveH - gripSize, gripSize, gripSize) then
            self._dragMode = "resize"
            self._dragStartW = self.width
            self._dragStartH = self.height
            self._dragOriginX = mx
            self._dragOriginY = my
            NovaUI.Input.dragged = self
            return
        end
    end

    -- 3. Check header drag area
    local dragAreaH = self.showHeader and self.headerHeight or NovaUI.scale(32)
    if self.draggable and not self._maximized and Utils.pointInRect(mx, my, absX, absY, self.width, dragAreaH) then
        self._dragMode = "move"
        self._dragOffsetX = mx - self.x
        self._dragOffsetY = my - self.y
        NovaUI.Input.dragged = self
    end
end

function Window:onDragMove(mx, my)
    if self._dragMode == "move" then
        local sw, sh = NovaUI.getScreenSize()
        local nx = Utils.clamp(mx - self._dragOffsetX, 0, math.max(0, sw - self.width))
        local ny = Utils.clamp(my - self._dragOffsetY, 0, math.max(0, sh - self.headerHeight))
        self:setPosition(nx, ny, true)
        self._rawX = NovaUI.unscale(nx)
        self._rawY = NovaUI.unscale(ny)
    elseif self._dragMode == "resize" then
        local nw = math.max(self.minWidth, self._dragStartW + (mx - self._dragOriginX))
        local nh = math.max(self.minHeight, self._dragStartH + (my - self._dragOriginY))
        self:setSize(nw, nh, true)
        self._rawW = NovaUI.unscale(nw)
        self._rawH = NovaUI.unscale(nh)
    end
end

function Window:onDragEnd()
    self._dragMode = nil
end

function Window:onScaleChange()
    NovaUI.Component.onScaleChange(self)
    self.headerHeight = NovaUI.scale(tonumber(self.props.headerHeight) or 46)
    self.footerHeight = self.showFooter and NovaUI.scale(tonumber(self.props.footerHeight) or 44) or 0
    self.x, self.y, self.width, self.height = NovaUI.fitToViewport(self.x, self.y, self.width, self.height, NovaUI.scale(8))
end

function Window:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local effectiveH = self._minimized and self.headerHeight or h
    local bgCol = Utils.withAlpha(self.props.backgroundColor or theme.background, (theme.background[4] or 248) * alphaRatio)
    local borderCol = Utils.withAlpha(
        self.state.focused and theme.borderFocus or theme.border,
        (self.state.focused and 210 or 180) * alphaRatio
    )

    -- 1. Window body + elevation shadow
    Primitives.drawGlassPanel(absX, absY, w, effectiveH, self.radius, bgCol, borderCol, "xl", false)

    -- 2. Window Header
    if self.showHeader then
        local headerCol = Utils.withAlpha(theme.header, 255 * alphaRatio)
        Primitives.drawRoundedRect(absX + 1, absY + 1, w - 2, self.headerHeight - 1, self.radius, headerCol, nil, 0, false)
        -- Header bottom divider line
        Primitives.drawRoundedRect(absX + 1, absY + self.headerHeight - 1, w - 2, 1, 0, Utils.withAlpha(theme.border, 160 * alphaRatio), nil, 0, false)
        -- Subtle primary accent bar at top-left
        local accentW = NovaUI.scale(36)
        Primitives.drawRoundedRect(absX + NovaUI.scale(16), absY + 1, accentW, NovaUI.scale(2), 1, Utils.withAlpha(theme.primary, 230 * alphaRatio), nil, 0, false)

        local titleX = absX + NovaUI.scale(16)
        if self.icon then
            local iconSize = NovaUI.scale(18)
            NovaUI.Icons.draw(self.icon, titleX, absY + math.floor((self.headerHeight - iconSize) * 0.5), iconSize, Utils.withAlpha(theme.primary, 255 * alphaRatio))
            titleX = titleX + iconSize + NovaUI.scale(10)
        end

        if self.subtitle then
            Primitives.drawText(self.title, titleX, absY + NovaUI.scale(6), w * 0.65, NovaUI.scale(20), Utils.withAlpha(theme.text, 255 * alphaRatio), "md", "bold", "left", "center")
            Primitives.drawText(self.subtitle, titleX, absY + NovaUI.scale(24), w * 0.65, NovaUI.scale(16), Utils.withAlpha(theme.textMuted, 240 * alphaRatio), "xs", "regular", "left", "center")
        else
            Primitives.drawText(self.title, titleX, absY, w * 0.7, self.headerHeight, Utils.withAlpha(theme.text, 255 * alphaRatio), "md", "bold", "left", "center")
        end

        -- Header control buttons (Minimize, Maximize, Close)
        local rects = self:_getControlRects(absX, absY, w)
        local iconSz = NovaUI.scale(13)
        for name, r in pairs(rects) do
            local isHov = (self._hoveredControl == name)
            if isHov then
                local hovBg = name == "close" and Utils.withAlpha(theme.danger, 220 * alphaRatio) or Utils.withAlpha(theme.surfaceHover, 240 * alphaRatio)
                Primitives.drawRoundedRect(r.x, r.y, r.w, r.h, "sm", hovBg, nil, 0, false)
            end
            local icCol = (isHov and name == "close") and { 255, 255, 255, 255 * alphaRatio } or Utils.withAlpha(isHov and theme.text or theme.textMuted, 245 * alphaRatio)
            local icName = name == "close" and "close" or (name == "maximize" and "maximize" or "minimize")
            NovaUI.Icons.draw(icName, r.x + math.floor((r.w - iconSz) * 0.5), r.y + math.floor((r.h - iconSz) * 0.5), iconSz, icCol)
        end
    end

    if self._minimized then
        return
    end

    -- 3. Window Footer (optional)
    if self.showFooter and self.footerHeight > 0 then
        local fy = absY + h - self.footerHeight
        Primitives.drawRoundedRect(absX + 1, fy, w - 2, self.footerHeight - 1, self.radius, Utils.withAlpha(theme.header, 230 * alphaRatio), nil, 0, false)
        Primitives.drawRoundedRect(absX + 1, fy, w - 2, 1, 0, Utils.withAlpha(theme.border, 160 * alphaRatio), nil, 0, false)
        if self.props.footerText then
            Primitives.drawText(self.props.footerText, absX + NovaUI.scale(16), fy, w - NovaUI.scale(32), self.footerHeight, Utils.withAlpha(theme.textMuted, 230 * alphaRatio), "xs", "regular", "left", "center")
        end
    end

    -- 4. Resize grip indicator in bottom-right corner
    if self.resizable and not self._maximized then
        local gx = absX + w - NovaUI.scale(12)
        local gy = absY + h - NovaUI.scale(12)
        local gCol = Utils.withAlpha(theme.textMuted, 120 * alphaRatio)
        Primitives.drawLine(gx, gy + NovaUI.scale(6), gx + NovaUI.scale(6), gy, gCol, 1.5, false)
        Primitives.drawLine(gx + NovaUI.scale(3), gy + NovaUI.scale(6), gx + NovaUI.scale(6), gy + NovaUI.scale(3), gCol, 1.5, false)
    end
end

NovaUI.registerComponent("window", Window, { "Window" })
