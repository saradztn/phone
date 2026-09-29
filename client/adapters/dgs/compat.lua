--[[
    NovaUI - Legacy DGS Compatibility & Migration Layer
    Allows gradual migration from procedural DGS scripts to NovaUI components
    File: client/adapters/dgs/compat.lua
]]

NovaUI = NovaUI or {}
NovaUI.compat = {}

local compat = NovaUI.compat

-- Map legacy DGS type names to NovaUI component types
local _typeMap = {
    ["dgs-dxwindow"]       = "window",
    ["window"]             = "window",
    ["dgs-dxbutton"]       = "button",
    ["button"]             = "button",
    ["dgs-dxlabel"]        = "label",
    ["label"]              = "label",
    ["dgs-dxedit"]         = "edit",
    ["edit"]               = "edit",
    ["dgs-dxmemo"]         = "textarea",
    ["memo"]               = "textarea",
    ["dgs-dxcheckbox"]     = "checkbox",
    ["checkbox"]           = "checkbox",
    ["dgs-dxradiobutton"]  = "radio",
    ["radiobutton"]        = "radio",
    ["dgs-dxswitchbutton"] = "switch",
    ["switchbutton"]       = "switch",
    ["dgs-dxcombobox"]     = "combobox",
    ["combobox"]           = "combobox",
    ["dgs-dxgridlist"]     = "table",
    ["gridlist"]           = "table",
    ["dgs-dxprogressbar"]  = "progressbar",
    ["progressbar"]        = "progressbar",
    ["dgs-dxtabpanel"]     = "tabs",
    ["tabpanel"]           = "tabs",
    ["dgs-dxscrollpane"]   = "scrollpanel",
    ["scrollpane"]         = "scrollpanel",
    ["dgs-dxscrollbar"]    = "slider",
    ["scrollbar"]          = "slider",
    ["dgs-dximage"]        = "image",
    ["image"]              = "image",
}

local function _resolveCoords(x, y, w, h, relative, parent)
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    w = tonumber(w) or 100
    h = tonumber(h) or 36
    if relative then
        local pw, ph = NovaUI.getScreenSize()
        if parent and parent.width and parent.height then
            pw, ph = parent.width, parent.height
        end
        x = math.floor(x * pw)
        y = math.floor(y * ph)
        w = math.floor(w * pw)
        h = math.floor(h * ph)
    end
    return x, y, w, h
end

function compat.create(dgsType, props, parent)
    local mapped = _typeMap[tostring(dgsType or ""):lower()] or tostring(dgsType or "panel"):lower()
    return NovaUI.create(mapped, props or {}, parent)
end

function compat.destroy(element)
    if type(element) == "table" and type(element.destroy) == "function" then
        return element:destroy()
    end
    return NovaUI.warn("NovaUI.compat.destroy", "Invalid NovaUI component")
end

function compat.setVisible(element, visible)
    if type(element) == "table" and type(element.setVisible) == "function" then
        element:setVisible(visible)
        return true
    end
    return false
end

function compat.getVisible(element)
    if type(element) == "table" and type(element.isVisible) == "function" then
        return element:isVisible()
    end
    return false
end

function compat.setEnabled(element, enabled)
    if type(element) == "table" and type(element.setEnabled) == "function" then
        element:setEnabled(enabled)
        return true
    end
    return false
end

function compat.getEnabled(element)
    if type(element) == "table" then
        return not element.props.disabled
    end
    return false
end

function compat.setText(element, text)
    if type(element) == "table" and type(element.setText) == "function" then
        element:setText(text)
        return true
    end
    return false
end

function compat.getText(element)
    if type(element) == "table" and type(element.getText) == "function" then
        return element:getText()
    end
    return ""
end

function compat.setPosition(element, x, y, relative)
    if type(element) == "table" and type(element.setPosition) == "function" then
        local nx, ny = _resolveCoords(x, y, 0, 0, relative, element.parent)
        element:setPosition(nx, ny)
        return true
    end
    return false
end

function compat.getPosition(element)
    if type(element) == "table" then
        return element.x, element.y
    end
    return 0, 0
end

function compat.setSize(element, w, h, relative)
    if type(element) == "table" and type(element.setSize) == "function" then
        local _, _, nw, nh = _resolveCoords(0, 0, w, h, relative, element.parent)
        element:setSize(nw, nh)
        return true
    end
    return false
end

function compat.getSize(element)
    if type(element) == "table" then
        return element.width, element.height
    end
    return 0, 0
end

function compat.setAlpha(element, alpha)
    if type(element) == "table" and type(element.setAlpha) == "function" then
        local a = tonumber(alpha) or 1
        if a <= 1 then a = a * 255 end
        element:setAlpha(a)
        return true
    end
    return false
end

function compat.getAlpha(element)
    if type(element) == "table" then
        return (element.alpha or 255) / 255
    end
    return 1
end

function compat.createWindow(x, y, w, h, text, relative)
    local nx, ny, nw, nh = _resolveCoords(x, y, w, h, relative)
    return NovaUI.create("window", { x = nx, y = ny, width = nw, height = nh, title = text or "Window" })
end

function compat.createButton(x, y, w, h, text, relative, parent)
    local nx, ny, nw, nh = _resolveCoords(x, y, w, h, relative, parent)
    return NovaUI.create("button", { x = nx, y = ny, width = nw, height = nh, text = text or "Button" }, parent)
end

function compat.createLabel(x, y, w, h, text, relative, parent)
    local nx, ny, nw, nh = _resolveCoords(x, y, w, h, relative, parent)
    return NovaUI.create("label", { x = nx, y = ny, width = nw, height = nh, text = text or "" }, parent)
end

function compat.createEdit(x, y, w, h, text, relative, parent)
    local nx, ny, nw, nh = _resolveCoords(x, y, w, h, relative, parent)
    return NovaUI.create("edit", { x = nx, y = ny, width = nw, height = nh, value = text or "" }, parent)
end

function compat.createCheckBox(x, y, w, h, text, state, relative, parent)
    local nx, ny, nw, nh = _resolveCoords(x, y, w, h, relative, parent)
    return NovaUI.create("checkbox", { x = nx, y = ny, width = nw, height = nh, label = text or "", checked = state and true or false }, parent)
end

function compat.createComboBox(x, y, w, h, caption, relative, parent)
    local nx, ny, nw, nh = _resolveCoords(x, y, w, h, relative, parent)
    return NovaUI.create("combobox", { x = nx, y = ny, width = nw, height = nh, placeholder = caption or "Select..." }, parent)
end

function compat.createProgressBar(x, y, w, h, relative, parent)
    local nx, ny, nw, nh = _resolveCoords(x, y, w, h, relative, parent)
    return NovaUI.create("progressbar", { x = nx, y = ny, width = nw, height = nh, value = 0 }, parent)
end

function compat.createScrollPane(x, y, w, h, relative, parent)
    local nx, ny, nw, nh = _resolveCoords(x, y, w, h, relative, parent)
    return NovaUI.create("scrollpanel", { x = nx, y = ny, width = nw, height = nh }, parent)
end
