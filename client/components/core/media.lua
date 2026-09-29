--[[
    NovaUI - Media & Micro-Components: Image, Icon, Avatar, Badge, Status
    File: client/components/core/media.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. Image Component
-- ============================================================================
local Image = NovaUI.Class("Image", NovaUI.Component)

function Image:onCreate(props)
    self.src = props.src or props.image or props.path or "assets/images/logo.png"
    self.radius = props.radius or 0
    self._texture = self:trackTexture(self.src)
    self._passthrough = props.interactive ~= true
end

function Image:setSource(src)
    if self.src == src then return self end
    self.src = src
    self._texture = self:trackTexture(src)
    self._dirty = true
    return self
end

function Image:render(absX, absY, w, h, alphaRatio)
    local col = Utils.toColor(self.props.color or { 255, 255, 255, 255 }, alphaRatio)
    if self.props.backgroundColor then
        Primitives.drawRoundedRect(absX, absY, w, h, self.radius, Utils.withAlpha(self.props.backgroundColor, 255 * alphaRatio), nil, 0, false)
    end
    if self._texture and type(dxDrawImage) == "function" then
        dxDrawImage(absX, absY, w, h, self._texture, self.props.rotation or 0, 0, 0, col, false)
    else
        Primitives.drawRoundedRect(absX, absY, w, h, self.radius, Utils.withAlpha(NovaUI.Theme.surfaceElevated, 255 * alphaRatio), Utils.withAlpha(NovaUI.Theme.border, 180 * alphaRatio), 1, false)
    end
end

NovaUI.registerComponent("image", Image, { "Image" })

-- ============================================================================
-- 2. Icon Component
-- ============================================================================
local Icon = NovaUI.Class("Icon", NovaUI.Component)

function Icon:onCreate(props)
    local sz = tonumber(props.size or props.width or props.w) or 20
    self._rawW = sz
    self._rawH = sz
    self.width = NovaUI.scale(sz)
    self.height = NovaUI.scale(sz)
    self.name = props.name or props.icon or "info"
    self._passthrough = props.interactive ~= true
end

function Icon:setIcon(name)
    self.name = tostring(name or "info")
    self._dirty = true
    return self
end

function Icon:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    if self.props.backgroundColor then
        Primitives.drawRoundedRect(absX, absY, w, h, self.props.radius or "sm", Utils.withAlpha(self.props.backgroundColor, 255 * alphaRatio), nil, 0, false)
    end
    local iconSize = self.props.backgroundColor and math.floor(math.min(w, h) * 0.56) or math.min(w, h)
    local ix = absX + math.floor((w - iconSize) * 0.5)
    local iy = absY + math.floor((h - iconSize) * 0.5)
    local col = Utils.withAlpha(self.props.color or theme.text, 255 * alphaRatio)
    NovaUI.Icons.draw(self.name, ix, iy, iconSize, col, self.props.rotation or 0, false)
end

NovaUI.registerComponent("icon", Icon, { "Icon" })

-- ============================================================================
-- 3. Avatar Component
-- ============================================================================
local Avatar = NovaUI.Class("Avatar", NovaUI.Component)

local STATUS_COLORS = {
    online  = "success",
    away    = "warning",
    idle    = "warning",
    busy    = "danger",
    dnd     = "danger",
    offline = "textMuted",
}

function Avatar:onCreate(props)
    local sz = tonumber(props.size or props.width or props.w) or 42
    self._rawW = sz
    self._rawH = sz
    self.width = NovaUI.scale(sz)
    self.height = NovaUI.scale(sz)
    self.src = props.src or props.image or "assets/images/avatar_default.png"
    self.name = props.name or "Player"
    self.status = props.status -- "online" | "away" | "busy" | "offline"
    if self.src then
        self._texture = self:trackTexture(self.src)
    end
end

function Avatar:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local r = math.floor(math.min(w, h) * 0.5)
    local cx, cy = absX + r, absY + r

    Primitives.drawCircle(cx, cy, r, Utils.withAlpha(theme.surfaceElevated, 255 * alphaRatio), Utils.withAlpha(theme.primary, 180 * alphaRatio), 1.5, false)

    if self._texture and type(dxDrawImage) == "function" then
        local pad = NovaUI.scale(2)
        dxDrawImage(absX + pad, absY + pad, w - pad * 2, h - pad * 2, self._texture, 0, 0, 0, Utils.toColor({ 255, 255, 255, 255 }, alphaRatio), false)
    else
        local initials = tostring(self.name):sub(1, 2):upper()
        Primitives.drawText(initials, absX, absY, w, h, Utils.withAlpha(theme.primary, 255 * alphaRatio), "sm", "bold", "center", "center")
    end

    if self.status then
        local dotR = math.max(4, math.floor(r * 0.28))
        local tokenKey = STATUS_COLORS[tostring(self.status):lower()] or "success"
        local dotCol = Utils.withAlpha(theme[tokenKey] or theme.success, 255 * alphaRatio)
        Primitives.drawCircle(absX + w - dotR, absY + h - dotR, dotR, dotCol, Utils.withAlpha(theme.background, 255 * alphaRatio), 2, false)
    end
end

NovaUI.registerComponent("avatar", Avatar, { "Avatar" })

-- ============================================================================
-- 4. Badge Component
-- ============================================================================
local Badge = NovaUI.Class("Badge", NovaUI.Component)

function Badge:onCreate(props)
    self.props.text = tostring(props.text or props.label or "Badge")
    self.variant = props.variant or "primary" -- "primary" | "success" | "warning" | "danger" | "info" | "neutral"
    if not props.height and not props.h then
        self._rawH = 22
        self.height = NovaUI.scale(22)
    end
    if not props.width and not props.w then
        local tw = NovaUI.Fonts.getTextWidth(self.props.text, "xs", "bold")
        self.width = math.max(NovaUI.scale(44), tw + NovaUI.scale(18))
        self._rawW = NovaUI.unscale(self.width)
    end
    self._passthrough = true
end

function Badge:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local v = self.variant
    local bg, fg
    if v == "success" then bg, fg = theme.successSoft, theme.success
    elseif v == "warning" then bg, fg = theme.warningSoft, theme.warning
    elseif v == "danger" then bg, fg = theme.dangerSoft, theme.danger
    elseif v == "info" then bg, fg = theme.infoSoft, theme.info
    elseif v == "neutral" then bg, fg = theme.surfaceElevated, theme.textSecondary
    else bg, fg = theme.primarySoft, theme.primary end

    Primitives.drawRoundedRect(absX, absY, w, h, "pill", Utils.withAlpha(bg, (bg[4] or 40) * alphaRatio), Utils.withAlpha(fg, 95 * alphaRatio), 1, false)
    Primitives.drawText(self.props.text, absX, absY, w, h, Utils.withAlpha(fg, 255 * alphaRatio), "xs", "bold", "center", "center")
end

NovaUI.registerComponent("badge", Badge, { "Badge" })

-- ============================================================================
-- 5. Status Component
-- ============================================================================
local Status = NovaUI.Class("Status", NovaUI.Component)

function Status:onCreate(props)
    self.status = props.status or "online"
    self.props.text = tostring(props.text or props.label or self.status:upper())
    if not props.height and not props.h then
        self._rawH = 24
        self.height = NovaUI.scale(24)
    end
    self._passthrough = true
end

function Status:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local tokenKey = STATUS_COLORS[tostring(self.status):lower()] or "success"
    local col = theme[tokenKey] or theme.success
    local dotR = NovaUI.scale(4)
    local cy = absY + math.floor(h * 0.5)

    -- Subtle outer pulse ring
    Primitives.drawCircle(absX + dotR + 2, cy, dotR + NovaUI.scale(3), Utils.withAlpha(col, 45 * alphaRatio), nil, 0, false)
    Primitives.drawCircle(absX + dotR + 2, cy, dotR, Utils.withAlpha(col, 255 * alphaRatio), nil, 0, false)

    local tx = absX + dotR * 2 + NovaUI.scale(10)
    Primitives.drawText(self.props.text, tx, absY, w - (tx - absX), h, Utils.withAlpha(theme.textSecondary, 255 * alphaRatio), "xs", "bold", "left", "center")
end

NovaUI.registerComponent("status", Status, { "Status" })
