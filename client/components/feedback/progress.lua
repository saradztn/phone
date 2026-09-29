--[[
    NovaUI - Progress & Feedback Components: ProgressBar, Spinner, Loading, Alert
    File: client/components/feedback/progress.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. ProgressBar Component
-- ============================================================================
local ProgressBar = NovaUI.Class("ProgressBar", NovaUI.Component)

function ProgressBar:onCreate(props)
    if not props.height and not props.h then
        self._rawH = props.label and 32 or 12
        self.height = NovaUI.scale(self._rawH)
    end
    self.max = tonumber(props.max) or 100
    self.state.value = Utils.clamp(tonumber(props.value) or 0, 0, self.max)
    self.variant = props.variant or "primary" -- "primary" | "success" | "warning" | "danger" | "info"
    self.label = props.label
    self.showPercent = props.showPercent ~= false
    self.indeterminate = props.indeterminate == true
end

function ProgressBar:setProgress(val, animate)
    local target = Utils.clamp(tonumber(val) or 0, 0, self.max)
    if animate and NovaUI.Config.enableAnimations then
        NovaUI.animate(self, {
            value = target,
            duration = NovaUI.Tokens.animation.normal,
            easing = "outCubic",
        })
    else
        self:setValue(target)
    end
    return self
end

function ProgressBar:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local barH = self.label and NovaUI.scale(8) or h
    local barY = self.label and (absY + h - barH) or absY
    local fillCol = theme[self.variant] or theme.primary

    if self.label then
        Primitives.drawText(tostring(self.label), absX, absY, w * 0.7, NovaUI.scale(18), Utils.withAlpha(theme.textSecondary, 255 * alphaRatio), "xs", "regular", "left", "center")
        if self.showPercent and not self.indeterminate then
            local pct = math.floor((self.state.value / math.max(1, self.max)) * 100 + 0.5)
            Primitives.drawText(pct .. "%", absX, absY, w, NovaUI.scale(18), Utils.withAlpha(fillCol, 255 * alphaRatio), "xs", "bold", "right", "center")
        end
    end

    Primitives.drawRoundedRect(absX, barY, w, barH, "pill", Utils.withAlpha(theme.surfaceElevated, 255 * alphaRatio), nil, 0, false)

    if self.indeterminate then
        local now = type(getTickCount) == "function" and getTickCount() or 0
        local segW = math.floor(w * 0.35)
        local pos = math.floor(((now % 1200) / 1200) * (w + segW)) - segW
        local sx = math.max(absX, absX + pos)
        local ex = math.min(absX + w, absX + pos + segW)
        if ex > sx then
            Primitives.drawRoundedRect(sx, barY, ex - sx, barH, "pill", Utils.withAlpha(fillCol, 255 * alphaRatio), nil, 0, false)
        end
    else
        local ratio = Utils.clamp((tonumber(self.state.value) or 0) / math.max(1, self.max), 0, 1)
        local fw = math.floor(w * ratio)
        if fw > 0 then
            Primitives.drawRoundedRect(absX, barY, fw, barH, "pill", Utils.withAlpha(fillCol, 255 * alphaRatio), nil, 0, false)
        end
    end
end

NovaUI.registerComponent("progressbar", ProgressBar, { "ProgressBar" })

-- ============================================================================
-- 2. Spinner Component
-- ============================================================================
local Spinner = NovaUI.Class("Spinner", NovaUI.Component)

function Spinner:onCreate(props)
    local sz = tonumber(props.size or props.width or props.w) or 32
    self._rawW = sz
    self._rawH = sz
    self.width = NovaUI.scale(sz)
    self.height = NovaUI.scale(sz)
    self.thickness = tonumber(props.thickness) or 3
    self.variant = props.variant or "primary"
    self._passthrough = true
end

function Spinner:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local cx = absX + math.floor(w * 0.5)
    local cy = absY + math.floor(h * 0.5)
    local r = math.floor(math.min(w, h) * 0.44)
    local col = theme[self.variant] or theme.primary
    local now = type(getTickCount) == "function" and getTickCount() or 0
    local angle = (now * 0.32) % 360

    Primitives.drawArc(cx, cy, r, self.thickness, 0, 360, Utils.withAlpha(theme.surfaceHover, 140 * alphaRatio), false)
    Primitives.drawArc(cx, cy, r, self.thickness, angle, angle + 240, Utils.withAlpha(col, 255 * alphaRatio), false)
end

NovaUI.registerComponent("spinner", Spinner, { "Spinner" })

-- ============================================================================
-- 3. Loading Component (Overlay / Block Loader with Spinner + Label)
-- ============================================================================
local Loading = NovaUI.Class("Loading", NovaUI.Component)

function Loading:onCreate(props)
    self.text = tostring(props.text or props.label or "Loading...")
end

function Loading:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    Primitives.drawRoundedRect(absX, absY, w, h, "md", Utils.withAlpha(theme.glass, 215 * alphaRatio), Utils.withAlpha(theme.border, 180 * alphaRatio), 1, false)

    local cx = absX + math.floor(w * 0.5)
    local cy = absY + math.floor(h * 0.5) - NovaUI.scale(12)
    local r = NovaUI.scale(14)
    local now = type(getTickCount) == "function" and getTickCount() or 0
    local angle = (now * 0.32) % 360

    Primitives.drawArc(cx, cy, r, 3, 0, 360, Utils.withAlpha(theme.surfaceHover, 140 * alphaRatio), false)
    Primitives.drawArc(cx, cy, r, 3, angle, angle + 240, Utils.withAlpha(theme.primary, 255 * alphaRatio), false)
    Primitives.drawText(self.text, absX, cy + r + NovaUI.scale(8), w, NovaUI.scale(22), Utils.withAlpha(theme.textSecondary, 255 * alphaRatio), "sm", "bold", "center", "center")
end

NovaUI.registerComponent("loading", Loading, { "Loading" })

-- ============================================================================
-- 4. Alert Component (Inline Callout Banner)
-- ============================================================================
local Alert = NovaUI.Class("Alert", NovaUI.Component)

local ALERT_TYPES = {
    info    = { fg = "info",    bg = "infoSoft",    icon = "info" },
    success = { fg = "success", bg = "successSoft", icon = "success" },
    warning = { fg = "warning", bg = "warningSoft", icon = "warning" },
    danger  = { fg = "danger",  bg = "dangerSoft",  icon = "error" },
    error   = { fg = "danger",  bg = "dangerSoft",  icon = "error" },
}

function Alert:onCreate(props)
    if not props.height and not props.h then
        self._rawH = props.title and 64 or 44
        self.height = NovaUI.scale(self._rawH)
    end
    self.variant = tostring(props.variant or props.type or "info"):lower()
    self.title = props.title and tostring(props.title) or nil
    self.message = tostring(props.message or props.text or "")
    self.closable = props.closable == true
end

function Alert:onClick(mx)
    if self.closable then
        local absX = self:getScreenPosition()
        if mx >= absX + self.width - NovaUI.scale(32) then
            self:setVisible(false)
            self:emit("close")
        end
    end
end

function Alert:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local spec = ALERT_TYPES[self.variant] or ALERT_TYPES.info
    local fg = theme[spec.fg] or theme.info
    local bg = theme[spec.bg] or theme.infoSoft

    Primitives.drawRoundedRect(absX, absY, w, h, "sm", Utils.withAlpha(bg, 220 * alphaRatio), Utils.withAlpha(fg, 130 * alphaRatio), 1, false)

    local padX = NovaUI.scale(14)
    local icSz = NovaUI.scale(18)
    NovaUI.Icons.draw(self.props.icon or spec.icon, absX + padX, absY + math.floor((h - icSz) * 0.5), icSz, Utils.withAlpha(fg, 255 * alphaRatio))

    local tx = absX + padX + icSz + NovaUI.scale(12)
    local tw = w - (tx - absX) - (self.closable and NovaUI.scale(32) or padX)
    if self.title then
        Primitives.drawText(self.title, tx, absY + NovaUI.scale(8), tw, NovaUI.scale(20), Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "bold", "left", "center")
        Primitives.drawText(self.message, tx, absY + NovaUI.scale(28), tw, h - NovaUI.scale(32), Utils.withAlpha(theme.textSecondary, 240 * alphaRatio), "xs", "regular", "left", "top", true, true)
    else
        Primitives.drawText(self.message, tx, absY, tw, h, Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "regular", "left", "center")
    end

    if self.closable then
        NovaUI.Icons.draw("close", absX + w - NovaUI.scale(24), absY + math.floor((h - NovaUI.scale(12)) * 0.5), NovaUI.scale(12), Utils.withAlpha(theme.textMuted, 220 * alphaRatio))
    end
end

NovaUI.registerComponent("alert", Alert, { "Alert" })
