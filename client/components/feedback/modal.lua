--[[
    NovaUI - Modal, Dialog, and ConfirmDialog System
    Supports: Backdrop overlay, Escape key handling, focus management, animations, and callbacks
    File: client/components/feedback/modal.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

NovaUI.ModalManager = {}
local ModalManager = NovaUI.ModalManager

local Modal = NovaUI.Class("Modal", NovaUI.Component)

function Modal:onCreate(props)
    -- Detach from regular rootElements so ModalManager renders it in the dedicated modal layer
    for i = #NovaUI._registry.rootElements, 1, -1 do
        if NovaUI._registry.rootElements[i] == self then
            table.remove(NovaUI._registry.rootElements, i)
            break
        end
    end

    self._rawW = tonumber(props.width or props.w) or 440
    self._rawH = tonumber(props.height or props.h) or 220
    self.width = NovaUI.scale(self._rawW)
    self.height = NovaUI.scale(self._rawH)

    local sw, sh = NovaUI.getScreenSize()
    self.x = math.floor((sw - self.width) * 0.5)
    self.y = math.floor((sh - self.height) * 0.5)
    self._rawX = NovaUI.unscale(self.x)
    self._rawY = NovaUI.unscale(self.y)

    self.zIndex = NovaUI.Tokens.zIndex.modal
    self.title = tostring(props.title or "Dialog")
    self.message = tostring(props.message or props.text or "")
    self.icon = props.icon or "info"
    self.closeOnEscape = props.closeOnEscape ~= false
    self.headerHeight = NovaUI.scale(48)
    self.footerHeight = NovaUI.scale(56)

    table.insert(NovaUI._registry.modals, self)

    -- Create footer buttons if specified
    local btns = props.buttons
    if type(btns) == "table" and #btns > 0 then
        local btnW = 104
        local gap = 10
        local rightCursor = self._rawW - 18
        for i = #btns, 1, -1 do
            local bSpec = btns[i]
            rightCursor = rightCursor - btnW
            local btn = NovaUI.create("button", {
                x = rightCursor,
                y = self._rawH - 44,
                width = btnW,
                height = 34,
                text = bSpec.text or bSpec.label or "OK",
                variant = bSpec.variant or (i == #btns and "primary" or "secondary"),
            }, self)
            btn:on("click", function()
                if type(bSpec.onClick) == "function" then
                    bSpec.onClick(self)
                end
                if bSpec.role == "confirm" and type(props.onConfirm) == "function" then
                    props.onConfirm(self)
                elseif bSpec.role == "cancel" and type(props.onCancel) == "function" then
                    props.onCancel(self)
                end
                if bSpec.autoClose ~= false then
                    self:close()
                end
            end)
            rightCursor = rightCursor - gap
        end
    end

    -- Entrance animation
    NovaUI.animate(self, {
        from = { alpha = 0, _animOffsetY = NovaUI.scale(16) },
        alpha = 255,
        _animOffsetY = 0,
        duration = NovaUI.Tokens.animation.normal,
        easing = "outBack",
    })
end

function Modal:getContentOrigin(absX, absY)
    return absX, absY
end

function Modal:close()
    if self._closing then return self end
    self._closing = true
    self:emit("close", self)

    NovaUI.animate(self, {
        alpha = 0,
        _animOffsetY = NovaUI.scale(12),
        duration = NovaUI.Tokens.animation.fast,
        easing = "inQuad",
        onComplete = function()
            self:destroy()
        end,
    })
    return self
end

function Modal:onDestroy()
    for i = #NovaUI._registry.modals, 1, -1 do
        if NovaUI._registry.modals[i] == self then
            table.remove(NovaUI._registry.modals, i)
            break
        end
    end
end

function Modal:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local sw, sh = NovaUI.getScreenSize()

    -- Fullscreen dimmed backdrop overlay
    Primitives.drawRoundedRect(0, 0, sw, sh, 0, Utils.withAlpha(theme.overlay, (theme.overlay[4] or 180) * alphaRatio), nil, 0, false)

    -- Modal card surface + shadow
    Primitives.drawGlassPanel(absX, absY, w, h, "lg", Utils.withAlpha(theme.surfaceElevated, 255 * alphaRatio), Utils.withAlpha(theme.borderLight, 220 * alphaRatio), "xl", false)

    -- Header
    local padX = NovaUI.scale(20)
    local icSz = NovaUI.scale(20)
    NovaUI.Icons.draw(self.icon, absX + padX, absY + math.floor((self.headerHeight - icSz) * 0.5), icSz, Utils.withAlpha(theme.primary, 255 * alphaRatio))
    Primitives.drawText(self.title, absX + padX + icSz + NovaUI.scale(10), absY, w - padX * 2 - icSz, self.headerHeight, Utils.withAlpha(theme.text, 255 * alphaRatio), "lg", "bold", "left", "center")
    Primitives.drawRoundedRect(absX + 1, absY + self.headerHeight, w - 2, 1, 0, Utils.withAlpha(theme.border, 150 * alphaRatio), nil, 0, false)

    -- Message body
    if self.message ~= "" then
        local bodyY = absY + self.headerHeight + NovaUI.scale(14)
        local bodyH = h - self.headerHeight - self.footerHeight - NovaUI.scale(20)
        Primitives.drawText(self.message, absX + padX, bodyY, w - padX * 2, bodyH, Utils.withAlpha(theme.textSecondary, 245 * alphaRatio), "md", "regular", "left", "top", true, true)
    end

    -- Footer separator
    Primitives.drawRoundedRect(absX + 1, absY + h - self.footerHeight, w - 2, 1, 0, Utils.withAlpha(theme.border, 140 * alphaRatio), nil, 0, false)
end

function ModalManager.renderAll()
    local modals = NovaUI._registry.modals
    if not modals or #modals == 0 then return end
    for i = 1, #modals do
        local m = modals[i]
        if m and not m._destroyed and m.visible then
            NovaUI.Renderer.renderComponent(m, 0, 0, 1.0)
        end
    end
end

function ModalManager.handleEscape()
    local modals = NovaUI._registry.modals
    if not modals or #modals == 0 then return false end
    local top = modals[#modals]
    if top and not top._destroyed and top.closeOnEscape then
        top:close()
        return true
    end
    return false
end

-- High-level NovaUI.confirm({...}) helper
function NovaUI.confirm(options)
    options = type(options) == "table" and options or { message = tostring(options or "Are you sure?") }
    options.title = options.title or "Confirm Action"
    options.icon = options.icon or "warning"
    if not options.buttons then
        options.buttons = {
            {
                text = options.cancelText or "Cancel",
                variant = "secondary",
                role = "cancel",
                onClick = options.onCancel,
            },
            {
                text = options.confirmText or "Confirm",
                variant = options.confirmVariant or "primary",
                role = "confirm",
                onClick = options.onConfirm,
            },
        }
    end
    return NovaUI.create("confirmdialog", options)
end

NovaUI.registerComponent("modal", Modal, { "Modal" })
NovaUI.registerComponent("dialog", Modal, { "Dialog" })
NovaUI.registerComponent("confirmdialog", Modal, { "ConfirmDialog" })
