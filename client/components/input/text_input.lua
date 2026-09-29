--[[
    NovaUI - Text Input Components: Edit, SearchBox, PasswordInput, NumberInput, TextArea
    File: client/components/input/text_input.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

-- ============================================================================
-- 1. Edit Component (Base Single-Line Input)
-- ============================================================================
local Edit = NovaUI.Class("Edit", NovaUI.Component)

function Edit:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 38
        self.height = NovaUI.scale(38)
    end
    self._acceptsTextInput = true
    self.state.value = tostring(props.value or props.text or "")
    self.placeholder = tostring(props.placeholder or "")
    self.maxLength = tonumber(props.maxLength) or 256
    self.readOnly = props.readOnly == true
    self.masked = props.masked == true or props.password == true
    self.icon = props.icon
    self.clearable = props.clearable == true
    self.caretPos = Utils.utf8Len(self.state.value)

    -- Create DGS proxy edit if DGS is available
    if NovaUI.DGSAdapter and NovaUI.DGSAdapter.isAvailable() then
        self._dgsElement = NovaUI.DGSAdapter.createProxyEdit(self, self.x, self.y, self.width, self.height, self.state.value, self.masked)
    end
end

function Edit:setValue(val, silent)
    local s = tostring(val or "")
    if self.maxLength and Utils.utf8Len(s) > self.maxLength then
        s = Utils.utf8Sub(s, 1, self.maxLength)
    end
    local old = self.state.value
    self.state.value = s
    self.props.value = s
    self.props.text = s
    self.caretPos = Utils.clamp(self.caretPos or Utils.utf8Len(s), 0, Utils.utf8Len(s))
    self._dirty = true
    if self._dgsElement then
        NovaUI.DGSAdapter.syncElement(self._dgsElement, { text = s })
    end
    if not silent and old ~= s then
        self:emit("change", s, old)
    end
    return self
end

function Edit:getText()
    return tostring(self.state.value or "")
end

function Edit:setText(text)
    return self:setValue(text)
end

function Edit:clear()
    return self:setValue("")
end

function Edit:onCharacter(ch)
    if self.readOnly or self.props.disabled then return false end
    if type(ch) ~= "string" or ch == "" then return false end
    local byte = string.byte(ch, 1)
    if byte and byte < 32 then return false end

    if self.props.numericOnly and not ch:match("^[0-9%.%-]$") then
        return false
    end

    local cur = tostring(self.state.value or "")
    local len = Utils.utf8Len(cur)
    if len >= self.maxLength then return false end

    local pos = Utils.clamp(self.caretPos or len, 0, len)
    local left = pos > 0 and Utils.utf8Sub(cur, 1, pos) or ""
    local right = pos < len and Utils.utf8Sub(cur, pos + 1, len) or ""
    local nextVal = left .. ch .. right
    self.caretPos = pos + 1
    self:setValue(nextVal)
    return true
end

function Edit:onKey(key, press)
    if not press or self.props.disabled then return false end
    local cur = tostring(self.state.value or "")
    local len = Utils.utf8Len(cur)
    local pos = Utils.clamp(self.caretPos or len, 0, len)

    if key == "backspace" and not self.readOnly then
        if pos > 0 and len > 0 then
            local left = pos > 1 and Utils.utf8Sub(cur, 1, pos - 1) or ""
            local right = pos < len and Utils.utf8Sub(cur, pos + 1, len) or ""
            self.caretPos = pos - 1
            self:setValue(left .. right)
        end
        return true
    elseif key == "delete" and not self.readOnly then
        if pos < len then
            local left = pos > 0 and Utils.utf8Sub(cur, 1, pos) or ""
            local right = (pos + 2 <= len) and Utils.utf8Sub(cur, pos + 2, len) or ""
            self:setValue(left .. right)
        end
        return true
    elseif key == "arrow_l" then
        self.caretPos = math.max(0, pos - 1)
        return true
    elseif key == "arrow_r" then
        self.caretPos = math.min(len, pos + 1)
        return true
    elseif key == "home" then
        self.caretPos = 0
        return true
    elseif key == "end" then
        self.caretPos = len
        return true
    elseif key == "enter" or key == "num_enter" then
        self:emit("submit", self.state.value)
        return true
    end
    return false
end

function Edit:onClick(mx, my)
    local absX, absY = self:getScreenPosition()
    -- Check right-side action button (clear button or password visibility toggle)
    if (self.clearable and self.state.value ~= "") or self._hasRightAction then
        local btnAreaX = absX + self.width - NovaUI.scale(34)
        if mx >= btnAreaX then
            if type(self.onRightActionClick) == "function" then
                self:onRightActionClick()
                return
            elseif self.clearable then
                self:clear()
                self:emit("clear")
                return
            end
        end
    end
    self.caretPos = Utils.utf8Len(self.state.value or "")
end

function Edit:_getDisplayString()
    local val = tostring(self.state.value or "")
    if self.masked and val ~= "" then
        return string.rep("•", Utils.utf8Len(val))
    end
    return val
end

function Edit:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local isFocused = self.state.focused
    local isHov = self.state.hovered

    local bg = isFocused and theme.backgroundAlt or (isHov and theme.surfaceElevated or theme.surface)
    local border = isFocused and theme.borderFocus or (isHov and theme.borderLight or theme.border)
    local bw = isFocused and 1.5 or 1

    Primitives.drawRoundedRect(absX, absY, w, h, self.props.radius or "sm", Utils.withAlpha(bg, 255 * alphaRatio), Utils.withAlpha(border, 235 * alphaRatio), bw, false)

    local padX = NovaUI.scale(12)
    local textX = absX + padX
    local rightPad = padX

    if self.icon then
        local icSz = NovaUI.scale(16)
        local icCol = isFocused and theme.primary or theme.textMuted
        NovaUI.Icons.draw(self.icon, textX, absY + math.floor((h - icSz) * 0.5), icSz, Utils.withAlpha(icCol, 240 * alphaRatio))
        textX = textX + icSz + NovaUI.scale(8)
    end

    if (self.clearable and self.state.value ~= "") or self._rightIcon then
        local rIcon = self._rightIcon or "close"
        local icSz = NovaUI.scale(15)
        NovaUI.Icons.draw(rIcon, absX + w - padX - icSz, absY + math.floor((h - icSz) * 0.5), icSz, Utils.withAlpha(theme.textMuted, 220 * alphaRatio))
        rightPad = padX + icSz + NovaUI.scale(8)
    end

    local availW = math.max(10, (absX + w - rightPad) - textX)
    local displayStr = self:_getDisplayString()

    if displayStr ~= "" then
        Primitives.drawText(displayStr, textX, absY, availW, h, Utils.withAlpha(theme.text, 255 * alphaRatio), "md", "regular", "left", "center", true, false)
    elseif self.placeholder ~= "" then
        Primitives.drawText(self.placeholder, textX, absY, availW, h, Utils.withAlpha(theme.textMuted, 180 * alphaRatio), "md", "regular", "left", "center", true, false)
    end

    -- Blinking caret when focused
    if isFocused and not self.readOnly then
        local now = type(getTickCount) == "function" and getTickCount() or 0
        if (math.floor(now / 500) % 2) == 0 then
            local subText = self.masked and string.rep("•", self.caretPos or 0) or Utils.utf8Sub(tostring(self.state.value or ""), 1, self.caretPos or 0)
            local tw = NovaUI.Fonts.getTextWidth(subText, "md", "regular")
            local cx = math.min(textX + availW - 2, textX + tw + 1)
            local ch = math.floor(h * 0.52)
            Primitives.drawRoundedRect(cx, absY + math.floor((h - ch) * 0.5), 1.5, ch, 0, Utils.withAlpha(theme.primary, 255 * alphaRatio), nil, 0, false)
        end
    end
end

NovaUI.registerComponent("edit", Edit, { "Edit", "input" })

-- ============================================================================
-- 2. SearchBox Component
-- ============================================================================
local SearchBox = NovaUI.Class("SearchBox", Edit)

function SearchBox:onCreate(props)
    props.icon = props.icon or "search"
    props.placeholder = props.placeholder or "Search..."
    props.clearable = props.clearable ~= false
    Edit.onCreate(self, props)
end

NovaUI.registerComponent("searchbox", SearchBox, { "SearchBox" })

-- ============================================================================
-- 3. PasswordInput Component
-- ============================================================================
local PasswordInput = NovaUI.Class("PasswordInput", Edit)

function PasswordInput:onCreate(props)
    props.masked = true
    props.icon = props.icon or "lock"
    props.placeholder = props.placeholder or "Enter password..."
    Edit.onCreate(self, props)
    self._hasRightAction = true
    self._rightIcon = "eye"
end

function PasswordInput:onRightActionClick()
    self.masked = not self.masked
    self._rightIcon = self.masked and "eye" or "eye-off"
    self._dirty = true
end

NovaUI.registerComponent("passwordinput", PasswordInput, { "PasswordInput", "password" })

-- ============================================================================
-- 4. NumberInput Component (With +/- Stepper Controls & Min/Max Clamping)
-- ============================================================================
local NumberInput = NovaUI.Class("NumberInput", Edit)

function NumberInput:onCreate(props)
    props.numericOnly = true
    self.min = tonumber(props.min)
    self.max = tonumber(props.max)
    self.step = tonumber(props.step) or 1
    local initNum = tonumber(props.value) or self.min or 0
    props.value = tostring(initNum)
    Edit.onCreate(self, props)
    self.state.value = initNum
end

function NumberInput:setValue(val, silent)
    local num = tonumber(val)
    if not num then num = tonumber(self.state.value) or 0 end
    if self.min and num < self.min then num = self.min end
    if self.max and num > self.max then num = self.max end
    local old = self.state.value
    self.state.value = num
    self.props.value = num
    self._dirty = true
    if not silent and old ~= num then
        self:emit("change", num, old)
    end
    return self
end

function NumberInput:increment()
    return self:setValue((tonumber(self.state.value) or 0) + self.step)
end

function NumberInput:decrement()
    return self:setValue((tonumber(self.state.value) or 0) - self.step)
end

function NumberInput:onClick(mx, my)
    local absX = self:getScreenPosition()
    local btnW = NovaUI.scale(28)
    if mx >= absX + self.width - btnW then
        self:increment()
    elseif mx >= absX + self.width - btnW * 2 then
        self:decrement()
    end
end

function NumberInput:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local btnW = NovaUI.scale(28)
    Primitives.drawRoundedRect(absX, absY, w, h, "sm", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(self.state.focused and theme.borderFocus or theme.border, 230 * alphaRatio), 1, false)

    -- Value text
    local padX = NovaUI.scale(12)
    Primitives.drawText(tostring(self.state.value or 0), absX + padX, absY, w - btnW * 2 - padX, h, Utils.withAlpha(theme.text, 255 * alphaRatio), "md", "bold", "left", "center")

    -- Minus & Plus buttons on right
    local minusX = absX + w - btnW * 2
    local plusX = absX + w - btnW
    Primitives.drawRoundedRect(minusX, absY + 2, 1, h - 4, 0, Utils.withAlpha(theme.border, 160 * alphaRatio), nil, 0, false)
    Primitives.drawRoundedRect(plusX, absY + 2, 1, h - 4, 0, Utils.withAlpha(theme.border, 160 * alphaRatio), nil, 0, false)

    local icSz = NovaUI.scale(12)
    NovaUI.Icons.draw("minus", minusX + math.floor((btnW - icSz) * 0.5), absY + math.floor((h - icSz) * 0.5), icSz, Utils.withAlpha(theme.textSecondary, 240 * alphaRatio))
    NovaUI.Icons.draw("plus", plusX + math.floor((btnW - icSz) * 0.5), absY + math.floor((h - icSz) * 0.5), icSz, Utils.withAlpha(theme.primary, 240 * alphaRatio))
end

NovaUI.registerComponent("numberinput", NumberInput, { "NumberInput", "number" })

-- ============================================================================
-- 5. TextArea Component (Multi-Line Text Input)
-- ============================================================================
local TextArea = NovaUI.Class("TextArea", Edit)

function TextArea:onCreate(props)
    if not props.height and not props.h then
        self._rawH = 100
        self.height = NovaUI.scale(100)
    end
    props.maxLength = tonumber(props.maxLength) or 2000
    Edit.onCreate(self, props)
end

function TextArea:onKey(key, press)
    if press and (key == "enter" or key == "num_enter") and not self.readOnly then
        self:onCharacter("\n")
        return true
    end
    return Edit.onKey(self, key, press)
end

function TextArea:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    local isFocused = self.state.focused
    local bg = isFocused and theme.backgroundAlt or theme.surface
    local border = isFocused and theme.borderFocus or theme.border

    Primitives.drawRoundedRect(absX, absY, w, h, "sm", Utils.withAlpha(bg, 255 * alphaRatio), Utils.withAlpha(border, 230 * alphaRatio), isFocused and 1.5 or 1, false)

    local pad = NovaUI.scale(10)
    local val = tostring(self.state.value or "")
    if val ~= "" then
        Primitives.drawText(val, absX + pad, absY + pad, w - pad * 2, h - pad * 2, Utils.withAlpha(theme.text, 255 * alphaRatio), "sm", "regular", "left", "top", true, true)
    elseif self.placeholder ~= "" then
        Primitives.drawText(self.placeholder, absX + pad, absY + pad, w - pad * 2, h - pad * 2, Utils.withAlpha(theme.textMuted, 180 * alphaRatio), "sm", "regular", "left", "top", true, true)
    end
end

NovaUI.registerComponent("textarea", TextArea, { "TextArea", "memo" })
