--[[
    NovaUI - Tooltip Manager & Component
    Automatically displays viewport-clamped hover tooltips for any element with props.tooltip
    File: client/components/feedback/tooltip.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

NovaUI.TooltipManager = {
    target = nil,
    hoverStart = 0,
    delayMs = 260,
}

local TM = NovaUI.TooltipManager

function TM.onHoverChange(target)
    if target and not target._destroyed and target.props and target.props.tooltip and target.props.tooltip ~= "" then
        TM.target = target
        TM.hoverStart = type(getTickCount) == "function" and getTickCount() or 0
    else
        TM.target = nil
    end
end

function TM.render(now)
    local target = TM.target
    if not target or target._destroyed or not target:isVisible() then
        TM.target = nil
        return
    end
    local text = tostring(target.props.tooltip or "")
    if text == "" then return end

    now = now or (type(getTickCount) == "function" and getTickCount() or 0)
    local elapsed = now - TM.hoverStart
    if elapsed < TM.delayMs then return end

    local fadeProgress = Utils.clamp((elapsed - TM.delayMs) / 140, 0, 1)
    local theme = NovaUI.Theme
    local padX = NovaUI.scale(10)
    local padY = NovaUI.scale(6)
    local tw = NovaUI.Fonts.getTextWidth(text, "xs", "bold")
    local th = NovaUI.Fonts.getFontHeight("xs", "bold")
    local boxW = tw + padX * 2
    local boxH = th + padY * 2

    local mx, my = NovaUI.Input.cursorX, NovaUI.Input.cursorY
    local bx, by, bw, bh = NovaUI.fitToViewport(mx + NovaUI.scale(14), my + NovaUI.scale(18), boxW, boxH, NovaUI.scale(6))

    Primitives.drawGlassPanel(bx, by, bw, bh, "xs", Utils.withAlpha(theme.surfaceElevated, 248 * fadeProgress), Utils.withAlpha(theme.borderLight, 230 * fadeProgress), "md", true)
    Primitives.drawText(text, bx, by, bw, bh, Utils.withAlpha(theme.text, 255 * fadeProgress), "xs", "bold", "center", "center", true, false, true)
end

-- Standalone Tooltip Component wrapper
local Tooltip = NovaUI.Class("Tooltip", NovaUI.Component)

function Tooltip:onCreate(props)
    self.text = tostring(props.text or props.label or "")
    if props.target and type(props.target) == "table" and props.target._isComponent then
        props.target:setTooltip(self.text)
    end
    self._passthrough = true
end

function Tooltip:render() end

NovaUI.registerComponent("tooltip", Tooltip, { "Tooltip" })
