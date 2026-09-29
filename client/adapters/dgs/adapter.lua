--[[
    NovaUI - DGS Abstraction Adapter Layer
    Architecture: NovaUI -> NovaUI Core -> DGS Adapter -> DGS -> MTA:SA
    Verified against DGS v3.524 API specification
    File: client/adapters/dgs/adapter.lua
]]

NovaUI = NovaUI or {}
NovaUI.DGSAdapter = {
    available = false,
    resource = nil,
    roundRectCache = {},
    blurBoxCache = {},
}

local Adapter = NovaUI.DGSAdapter

-- Check whether DGS resource is currently running in MTA:SA
function Adapter.detect()
    if not NovaUI.Config.useDGSBackend then
        Adapter.available = false
        return false
    end
    if type(getResourceFromName) == "function" and type(getResourceState) == "function" then
        local res = getResourceFromName("dgs")
        if res and getResourceState(res) == "running" then
            Adapter.resource = res
            Adapter.available = true
            return true
        end
    end
    Adapter.available = false
    Adapter.resource = nil
    return false
end

-- Safe call to an exported DGS function
function Adapter.call(fnName, ...)
    if not Adapter.available then
        Adapter.detect()
    end
    if not Adapter.available or not Adapter.resource then
        return nil
    end
    if type(call) == "function" then
        local ok, r1, r2, r3, r4 = pcall(call, Adapter.resource, fnName, ...)
        if ok then
            return r1, r2, r3, r4
        end
    elseif type(exports) == "table" and exports.dgs and type(exports.dgs[fnName]) == "function" then
        local ok, r1, r2, r3, r4 = pcall(exports.dgs[fnName], exports.dgs, ...)
        if ok then
            return r1, r2, r3, r4
        end
    end
    return nil
end

function Adapter.isAvailable()
    return Adapter.available
end

-- Create a DGS RoundRect shader cached by (radius, colorHex, borderColorHex, thickness)
function Adapter.getRoundRectShader(radius, color, borderColor, borderThickness)
    if not Adapter.available then return nil end
    local r, g, b, a = NovaUI.Utils.unpackColor(color)
    local tc = NovaUI.Utils.toColor(color)
    local key = string.format("%d_%d_%d_%d_%d_%s_%s",
        tonumber(radius) or 0, r, g, b, a,
        tostring(borderColor or "none"),
        tostring(borderThickness or 0)
    )
    if Adapter.roundRectCache[key] and type(isElement) == "function" and isElement(Adapter.roundRectCache[key]) then
        return Adapter.roundRectCache[key]
    end
    local shader
    if borderColor and borderThickness then
        local bc = NovaUI.Utils.toColor(borderColor)
        shader = Adapter.call("dgsCreateRoundRect", radius, false, tc, nil, true, bc, borderThickness, borderThickness)
    else
        shader = Adapter.call("dgsCreateRoundRect", radius, false, tc)
    end
    if shader then
        Adapter.roundRectCache[key] = shader
    end
    return shader
end

-- Create a DGS BlurBox if supported and enabled
function Adapter.createBlurBox(w, h, level)
    if not Adapter.available or not NovaUI.Config.enableBlur then
        return nil
    end
    return Adapter.call("dgsCreateBlurBox", math.max(16, math.floor(w)), math.max(16, math.floor(h)), nil, level or 5)
end

-- Create a native DGS Edit proxy for clipboard/IME/caret support while keeping NovaUI visuals
function Adapter.createProxyEdit(component, x, y, w, h, text, isMasked)
    if not Adapter.available then return nil end
    local edit = Adapter.call("dgsCreateEdit", x, y, w, h, tostring(text or ""), false, nil, 0, 1, 1, nil, 0)
    if edit then
        Adapter.call("dgsSetProperty", edit, "alpha", 0)
        if isMasked then
            Adapter.call("dgsEditSetMasked", edit, true)
        end
        NovaUI._registry.dgsMap[edit] = component
        if type(addEventHandler) == "function" then
            addEventHandler("onDgsTextChange", edit, function()
                if component and not component._destroyed then
                    local newText = Adapter.call("dgsGetText", edit)
                    if type(newText) == "string" and newText ~= component.state.value then
                        component:setValue(newText, true)
                    end
                end
            end, false)
            addEventHandler("onDgsEditAccepted", edit, function()
                if component and not component._destroyed then
                    component:emit("submit", component.state.value)
                end
            end, false)
        end
    end
    return edit
end

function Adapter.syncElement(dgsEle, props)
    if not Adapter.available or not dgsEle then return false end
    if type(isElement) == "function" and not isElement(dgsEle) then return false end
    if props.x and props.y then
        Adapter.call("dgsSetPosition", dgsEle, props.x, props.y, false)
    end
    if props.w and props.h then
        Adapter.call("dgsSetSize", dgsEle, props.w, props.h, false)
    end
    if props.visible ~= nil then
        Adapter.call("dgsSetVisible", dgsEle, props.visible and true or false)
    end
    if props.enabled ~= nil then
        Adapter.call("dgsSetEnabled", dgsEle, props.enabled and true or false)
    end
    if props.alpha ~= nil then
        Adapter.call("dgsSetAlpha", dgsEle, math.max(0, math.min(1, props.alpha)))
    end
    if props.text ~= nil then
        Adapter.call("dgsSetText", dgsEle, tostring(props.text))
    end
    return true
end

function Adapter.destroyElement(dgsEle)
    if not dgsEle then return false end
    NovaUI._registry.dgsMap[dgsEle] = nil
    if type(isElement) == "function" and isElement(dgsEle) then
        if type(destroyElement) == "function" then
            destroyElement(dgsEle)
            return true
        end
    end
    return false
end

function Adapter.cleanup()
    for k, shader in pairs(Adapter.roundRectCache) do
        if type(isElement) == "function" and isElement(shader) then
            destroyElement(shader)
        end
        Adapter.roundRectCache[k] = nil
    end
    for k, bb in pairs(Adapter.blurBoxCache) do
        if type(isElement) == "function" and isElement(bb) then
            destroyElement(bb)
        end
        Adapter.blurBoxCache[k] = nil
    end
    NovaUI._registry.dgsMap = {}
end

-- Initial detection on load
Adapter.detect()
