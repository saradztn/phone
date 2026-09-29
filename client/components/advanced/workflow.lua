--[[
    NovaUI - Workflow & Activity Components: Stepper & Timeline
    File: client/components/advanced/workflow.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. Stepper Component (Multi-Step Horizontal Workflow Indicator)
-- ============================================================================
local Stepper = NovaUI.Class("Stepper", NovaUI.Component)

function Stepper:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 54
        self.height = NovaUI.scale(54)
    end
    self.steps = type(props.steps) == "table" and props.steps or { "Step 1", "Step 2", "Step 3" }
    self.currentStep = Utils.clamp(tonumber(props.currentStep or props.value) or 1, 1, #self.steps)
    self.state.value = self.currentStep
end

function Stepper:setStep(step, silent)
    self.currentStep = Utils.clamp(tonumber(step) or 1, 1, #self.steps)
    return self:setValue(self.currentStep, silent)
end

function Stepper:nextStep()
    return self:setStep(self.currentStep + 1)
end

function Stepper:prevStep()
    return self:setStep(self.currentStep - 1)
end

function Stepper:onClick(mx)
    if self.props.clickable == false then return end
    local absX = self:getScreenPosition()
    local count = #self.steps
    if count == 0 then return end
    local segW = self.width / count
    local idx = Utils.clamp(math.floor((mx - absX) / segW) + 1, 1, count)
    self:setStep(idx)
end

function Stepper:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local count = #self.steps
    if count == 0 then return end

    local r = NovaUI.scale(13)
    local cy = absY + r + NovaUI.scale(4)
    local segW = w / count

    -- Connecting lines first
    for i = 1, count - 1 do
        local x1 = absX + (i - 0.5) * segW + r
        local x2 = absX + (i + 0.5) * segW - r
        local done = (i < self.currentStep)
        local lineCol = done and theme.primary or theme.border
        Primitives.drawRoundedRect(x1, cy - 1, math.max(2, x2 - x1), 2, 0, Utils.withAlpha(lineCol, 230 * alphaRatio), nil, 0, false)
    end

    -- Step circles + labels
    for i = 1, count do
        local cx = absX + math.floor((i - 0.5) * segW)
        local isDone = (i < self.currentStep)
        local isCurrent = (i == self.currentStep)
        local label = type(self.steps[i]) == "table" and self.steps[i].label or tostring(self.steps[i])

        local fill = isDone and theme.success or (isCurrent and theme.primary or theme.surfaceElevated)
        local border = isDone and theme.success or (isCurrent and theme.primary or theme.borderLight)

        Primitives.drawCircle(cx, cy, r, Utils.withAlpha(fill, 255 * alphaRatio), Utils.withAlpha(border, 240 * alphaRatio), 1.5, false)

        if isDone then
            local icSz = NovaUI.scale(13)
            NovaUI.Icons.draw("check", cx - math.floor(icSz * 0.5), cy - math.floor(icSz * 0.5), icSz, Utils.withAlpha(theme.textInverse, 255 * alphaRatio))
        else
            local numCol = isCurrent and theme.textInverse or theme.textMuted
            Primitives.drawText(tostring(i), cx - r, cy - r, r * 2, r * 2, Utils.withAlpha(numCol, 255 * alphaRatio), "xs", "bold", "center", "center")
        end

        local textCol = isCurrent and theme.text or (isDone and theme.textSecondary or theme.textMuted)
        Primitives.drawText(label, absX + math.floor((i - 1) * segW), cy + r + NovaUI.scale(4), math.floor(segW), NovaUI.scale(18), Utils.withAlpha(textCol, 255 * alphaRatio), "xs", isCurrent and "bold" or "regular", "center", "center")
    end
end

NovaUI.registerComponent("stepper", Stepper, { "Stepper" })

-- ============================================================================
-- 2. Timeline Component (Vertical Chronological Feed)
-- ============================================================================
local Timeline = NovaUI.Class("Timeline", NovaUI.Component)

function Timeline:onCreate(props)
    self.items = type(props.items) == "table" and props.items or {}
    self.itemHeight = NovaUI.scale(tonumber(props.itemHeight) or 54)
end

function Timeline:addItem(item)
    table.insert(self.items, item)
    self._dirty = true
    return self
end

function Timeline:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local count = #self.items
    if count == 0 then return end

    local lineX = absX + NovaUI.scale(14)
    local dotR = NovaUI.scale(5)

    for i = 1, count do
        local it = self.items[i]
        local ry = absY + (i - 1) * self.itemHeight
        if ry + self.itemHeight <= absY + h + NovaUI.scale(10) then
            local cy = ry + NovaUI.scale(12)
            local col = theme[it.type or it.variant or "primary"] or theme.primary

            if i < count then
                Primitives.drawRoundedRect(lineX - 1, cy + dotR, 2, self.itemHeight - dotR, 0, Utils.withAlpha(theme.border, 170 * alphaRatio), nil, 0, false)
            end

            Primitives.drawCircle(lineX, cy, dotR, Utils.withAlpha(col, 255 * alphaRatio), Utils.withAlpha(theme.background, 255 * alphaRatio), 1.5, false)

            local tx = lineX + NovaUI.scale(16)
            local tw = w - (tx - absX) - NovaUI.scale(8)
            Primitives.drawText(tostring(it.title or "Event"), tx, ry + NovaUI.scale(2), tw * 0.75, NovaUI.scale(20), Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "bold", "left", "center")

            if it.time then
                Primitives.drawText(tostring(it.time), tx, ry + NovaUI.scale(2), tw, NovaUI.scale(20), Utils.withAlpha(theme.textMuted, 220 * alphaRatio), "xxs", "regular", "right", "center")
            end
            if it.description or it.subtitle then
                Primitives.drawText(tostring(it.description or it.subtitle), tx, ry + NovaUI.scale(22), tw, NovaUI.scale(24), Utils.withAlpha(theme.textSecondary, 235 * alphaRatio), "xs", "regular", "left", "top")
            end
        end
    end
end

NovaUI.registerComponent("timeline", Timeline, { "Timeline" })
