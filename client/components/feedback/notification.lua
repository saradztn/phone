--[[
    NovaUI - Notification & Toast System
    Supports: info, success, warning, error, custom
    Features: Concurrent stacking, smooth enter/exit animations, countdown progress bar, click-to-dismiss
    File: client/components/feedback/notification.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

NovaUI.NotificationManager = {
    items = {},
    maxVisible = 6,
    position = "top-right", -- "top-right" | "bottom-right" | "top-left"
}

local Manager = NovaUI.NotificationManager

local TYPE_META = {
    info    = { colorKey = "info",    softKey = "infoSoft",    icon = "info" },
    success = { colorKey = "success", softKey = "successSoft", icon = "success" },
    warning = { colorKey = "warning", softKey = "warningSoft", icon = "warning" },
    error   = { colorKey = "danger",  softKey = "dangerSoft",  icon = "error" },
    danger  = { colorKey = "danger",  softKey = "dangerSoft",  icon = "error" },
    custom  = { colorKey = "primary", softKey = "primarySoft", icon = "sparkle" },
}

function NovaUI.notify(options)
    if type(options) == "string" then
        options = { message = options }
    end
    if type(options) ~= "table" then
        return NovaUI.warn("NovaUI.notify", "options must be a table or string")
    end

    local now = type(getTickCount) == "function" and getTickCount() or 0
    local nType = tostring(options.type or "info"):lower()
    local meta = TYPE_META[nType] or TYPE_META.info

    local sw = NovaUI.getScreenSize()
    local cardW = NovaUI.scale(tonumber(options.width) or 330)
    local cardH = NovaUI.scale(tonumber(options.height) or 74)
    local margin = NovaUI.scale(18)

    local targetX = sw - cardW - margin
    local targetY = margin + (#Manager.items) * (cardH + NovaUI.scale(10))

    local item = {
        id = NovaUI._registry.nextId,
        type = nType,
        title = tostring(options.title or nType:sub(1, 1):upper() .. nType:sub(2)),
        message = tostring(options.message or options.text or ""),
        icon = options.icon or meta.icon,
        customColor = options.color,
        duration = tonumber(options.duration) or 4000,
        createdAt = now,
        closing = false,
        _destroyed = false,
        x = targetX + NovaUI.scale(60),
        y = targetY,
        width = cardW,
        height = cardH,
        alpha = 0,
    }
    NovaUI._registry.nextId = NovaUI._registry.nextId + 1

    table.insert(Manager.items, item)
    NovaUI._registry.notifications = Manager.items

    -- Enforce maxVisible by dismissing oldest
    if #Manager.items > Manager.maxVisible then
        Manager.dismiss(Manager.items[1])
    end

    -- Entrance animation
    NovaUI.animate(item, {
        x = targetX,
        alpha = 255,
        duration = NovaUI.Tokens.animation.normal,
        easing = "outBack",
    })

    Manager.reflow()
    return item
end

function Manager.reflow()
    local sw = NovaUI.getScreenSize()
    local margin = NovaUI.scale(18)
    local gap = NovaUI.scale(10)
    local cursorY = margin

    for i = 1, #Manager.items do
        local it = Manager.items[i]
        if not it.closing then
            local targetX = sw - it.width - margin
            NovaUI.animate(it, {
                x = targetX,
                y = cursorY,
                duration = NovaUI.Tokens.animation.fast,
                easing = "outCubic",
            })
            cursorY = cursorY + it.height + gap
        end
    end
end

function Manager.dismiss(itemOrId)
    for i = 1, #Manager.items do
        local it = Manager.items[i]
        if it == itemOrId or it.id == itemOrId then
            if it.closing then return true end
            it.closing = true
            local sw = NovaUI.getScreenSize()
            NovaUI.animate(it, {
                x = sw + NovaUI.scale(20),
                alpha = 0,
                duration = NovaUI.Tokens.animation.fast,
                easing = "inQuad",
                onComplete = function()
                    it._destroyed = true
                    for j = #Manager.items, 1, -1 do
                        if Manager.items[j] == it then
                            table.remove(Manager.items, j)
                            break
                        end
                    end
                    Manager.reflow()
                end,
            })
            return true
        end
    end
    return false
end

function Manager.clearAll()
    for i = #Manager.items, 1, -1 do
        Manager.items[i]._destroyed = true
    end
    Manager.items = {}
    NovaUI._registry.notifications = Manager.items
end

function Manager.handleClick(mx, my)
    for i = #Manager.items, 1, -1 do
        local it = Manager.items[i]
        if not it.closing and Utils.pointInRect(mx, my, it.x, it.y, it.width, it.height) then
            Manager.dismiss(it)
            return true
        end
    end
    return false
end

function Manager.renderAll(now)
    if #Manager.items == 0 then return end
    now = now or (type(getTickCount) == "function" and getTickCount() or 0)
    local theme = NovaUI.Theme

    for i = 1, #Manager.items do
        local it = Manager.items[i]
        if it and not it._destroyed then
            local elapsed = now - it.createdAt
            if not it.closing and it.duration > 0 and elapsed >= it.duration then
                Manager.dismiss(it)
            end

            local alphaRatio = Utils.clamp((it.alpha or 255) / 255, 0, 1)
            if alphaRatio > 0.01 then
                local meta = TYPE_META[it.type] or TYPE_META.info
                local accent = it.customColor or theme[meta.colorKey] or theme.primary
                local soft = theme[meta.softKey] or theme.primarySoft

                Primitives.drawGlassPanel(it.x, it.y, it.width, it.height, "md", Utils.withAlpha(theme.surfaceElevated, 245 * alphaRatio), Utils.withAlpha(accent, 140 * alphaRatio), "lg", true)

                -- Left accent bar
                Primitives.drawRoundedRect(it.x + NovaUI.scale(4), it.y + NovaUI.scale(10), NovaUI.scale(4), it.height - NovaUI.scale(20), "pill", Utils.withAlpha(accent, 255 * alphaRatio), nil, 0, true)

                -- Icon badge
                local icBox = NovaUI.scale(34)
                local icX = it.x + NovaUI.scale(16)
                local icY = it.y + math.floor((it.height - icBox) * 0.5)
                Primitives.drawRoundedRect(icX, icY, icBox, icBox, "sm", Utils.withAlpha(soft, 230 * alphaRatio), nil, 0, true)
                local icSz = NovaUI.scale(18)
                NovaUI.Icons.draw(it.icon, icX + math.floor((icBox - icSz) * 0.5), icY + math.floor((icBox - icSz) * 0.5), icSz, Utils.withAlpha(accent, 255 * alphaRatio), 0, true)

                -- Title & Message
                local tx = icX + icBox + NovaUI.scale(12)
                local tw = it.width - (tx - it.x) - NovaUI.scale(28)
                Primitives.drawText(it.title, tx, it.y + NovaUI.scale(12), tw, NovaUI.scale(20), Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "bold", "left", "center", true, false, true)
                Primitives.drawText(it.message, tx, it.y + NovaUI.scale(33), tw, NovaUI.scale(28), Utils.withAlpha(theme.textSecondary, 235 * alphaRatio), "xs", "regular", "left", "top", true, true, true)

                -- Dismiss X icon
                local closeSz = NovaUI.scale(12)
                NovaUI.Icons.draw("close", it.x + it.width - NovaUI.scale(20), it.y + NovaUI.scale(12), closeSz, Utils.withAlpha(theme.textMuted, 190 * alphaRatio), 0, true)

                -- Countdown progress bar at bottom
                if it.duration > 0 then
                    local remRatio = Utils.clamp(1 - (elapsed / it.duration), 0, 1)
                    local pw = math.floor((it.width - NovaUI.scale(16)) * remRatio)
                    if pw > 0 then
                        Primitives.drawRoundedRect(it.x + NovaUI.scale(8), it.y + it.height - NovaUI.scale(3), pw, NovaUI.scale(2), 1, Utils.withAlpha(accent, 210 * alphaRatio), nil, 0, true)
                    end
                end
            end
        end
    end
end

-- Component wrapper for inline Notification / Toast elements
local NotificationComp = NovaUI.Class("Notification", NovaUI.Component)

function NotificationComp:onCreate(props)
    if not props.width and not props.w then self._rawW = 320; self.width = NovaUI.scale(320) end
    if not props.height and not props.h then self._rawH = 68; self.height = NovaUI.scale(68) end
    self.notifType = tostring(props.type or props.variant or "info"):lower()
    self.title = tostring(props.title or "Notification")
    self.message = tostring(props.message or props.text or "")
end

function NotificationComp:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local meta = TYPE_META[self.notifType] or TYPE_META.info
    local accent = theme[meta.colorKey] or theme.primary
    Primitives.drawRoundedRect(absX, absY, w, h, "md", Utils.withAlpha(theme.surfaceElevated, 255 * alphaRatio), Utils.withAlpha(accent, 160 * alphaRatio), 1, false)
    Primitives.drawRoundedRect(absX + NovaUI.scale(4), absY + NovaUI.scale(8), NovaUI.scale(4), h - NovaUI.scale(16), "pill", Utils.withAlpha(accent, 255 * alphaRatio), nil, 0, false)
    local tx = absX + NovaUI.scale(16)
    Primitives.drawText(self.title, tx, absY + NovaUI.scale(10), w - NovaUI.scale(24), NovaUI.scale(20), Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "bold", "left", "center")
    Primitives.drawText(self.message, tx, absY + NovaUI.scale(32), w - NovaUI.scale(24), NovaUI.scale(24), Utils.withAlpha(theme.textSecondary, 240 * alphaRatio), "xs", "regular", "left", "center")
end

NovaUI.registerComponent("notification", NotificationComp, { "Notification" })
NovaUI.registerComponent("toast", NotificationComp, { "Toast" })
