--[[
    NovaUI - Animation & Transition Engine
    Supports fade, slide, scale, move, resize, color interpolation, and custom properties.
    Zero timer overhead: driven by Renderer frame tick with automatic lifecycle cleanup.
    File: client/animation/engine.lua
]]

NovaUI = NovaUI or {}
NovaUI.Animation = {
    active = {},
    nextAnimId = 1,
}

local Animation = NovaUI.Animation
local Utils = NovaUI.Utils
local Easing = NovaUI.Easing

local RESERVED_KEYS = {
    duration   = true,
    delay      = true,
    easing     = true,
    onUpdate   = true,
    onComplete = true,
    from       = true,
}

local function _isColorTable(v)
    return type(v) == "table" and (#v == 3 or #v == 4) and type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number"
end

local function _readProp(target, key)
    if target[key] ~= nil then
        return target[key]
    elseif type(target.state) == "table" and target.state[key] ~= nil then
        return target.state[key]
    elseif type(target.props) == "table" and target.props[key] ~= nil then
        return target.props[key]
    end
    return 0
end

local function _writeProp(target, key, val)
    if target[key] ~= nil or key == "x" or key == "y" or key == "width" or key == "height" or key == "alpha" or key == "rotation" or key == "scale" or key == "_animOffsetX" or key == "_animOffsetY" then
        target[key] = val
    elseif type(target.state) == "table" and target.state[key] ~= nil then
        target.state[key] = val
    elseif type(target.props) == "table" then
        target.props[key] = val
    else
        target[key] = val
    end
    target._dirty = true
end

function NovaUI.animate(target, spec)
    if type(target) ~= "table" or target._destroyed then
        return NovaUI.warn("NovaUI.animate", "Invalid or destroyed target element")
    end
    if type(spec) ~= "table" then
        return NovaUI.warn("NovaUI.animate", "Animation specification table required")
    end

    local duration = math.max(0, tonumber(spec.duration) or NovaUI.Tokens.animation.normal or 240)
    local delay = math.max(0, tonumber(spec.delay) or 0)
    local easing = spec.easing or NovaUI.Tokens.animation.defaultEasing or "outCubic"
    local now = type(getTickCount) == "function" and getTickCount() or 0

    local tracks = {}
    local fromTable = type(spec.from) == "table" and spec.from or {}

    for k, targetVal in pairs(spec) do
        if not RESERVED_KEYS[k] then
            -- Cancel any existing track on the same (target, property)
            Animation.stopProperty(target, k)

            local startVal = fromTable[k]
            if startVal == nil then
                startVal = _readProp(target, k)
            end
            if fromTable[k] ~= nil then
                _writeProp(target, k, startVal)
            end

            if type(targetVal) == "number" and type(startVal) == "number" then
                tracks[k] = { kind = "number", from = startVal, to = targetVal }
            elseif _isColorTable(targetVal) then
                local r1, g1, b1, a1 = Utils.unpackColor(startVal)
                tracks[k] = { kind = "color", from = { r1, g1, b1, a1 }, to = targetVal }
            end
        end
    end

    if not NovaUI.Config.enableAnimations or duration == 0 then
        for k, tr in pairs(tracks) do
            _writeProp(target, k, tr.to)
        end
        if type(spec.onUpdate) == "function" then pcall(spec.onUpdate, target, 1.0) end
        if type(spec.onComplete) == "function" then pcall(spec.onComplete, target) end
        return nil
    end

    local animId = Animation.nextAnimId
    Animation.nextAnimId = animId + 1

    local animObj = {
        id = animId,
        target = target,
        tracks = tracks,
        startTime = now + delay,
        duration = duration,
        easing = easing,
        onUpdate = spec.onUpdate,
        onComplete = spec.onComplete,
        cancelled = false,
    }

    table.insert(Animation.active, animObj)
    return animObj
end

function Animation.stopProperty(target, propName)
    for i = #Animation.active, 1, -1 do
        local anim = Animation.active[i]
        if anim.target == target and anim.tracks[propName] then
            anim.tracks[propName] = nil
            if next(anim.tracks) == nil then
                table.remove(Animation.active, i)
            end
        end
    end
end

function NovaUI.stopAnimations(target, propName)
    if not target then return end
    if propName then
        Animation.stopProperty(target, propName)
        return
    end
    for i = #Animation.active, 1, -1 do
        if Animation.active[i].target == target then
            table.remove(Animation.active, i)
        end
    end
end

function Animation.tick(now)
    if #Animation.active == 0 then return end
    now = now or (type(getTickCount) == "function" and getTickCount() or 0)

    for i = #Animation.active, 1, -1 do
        local anim = Animation.active[i]
        local target = anim.target

        if anim.cancelled or not target or target._destroyed then
            table.remove(Animation.active, i)
        elseif now >= anim.startTime then
            local elapsed = now - anim.startTime
            local rawProgress = anim.duration > 0 and Utils.clamp(elapsed / anim.duration, 0, 1) or 1
            local eased = Easing.evaluate(anim.easing, rawProgress)

            for k, tr in pairs(anim.tracks) do
                if tr.kind == "number" then
                    local val = tr.from + (tr.to - tr.from) * eased
                    _writeProp(target, k, val)
                elseif tr.kind == "color" then
                    local col = Utils.lerpColor(tr.from, tr.to, eased)
                    _writeProp(target, k, col)
                end
            end

            if type(anim.onUpdate) == "function" then
                pcall(anim.onUpdate, target, rawProgress, eased)
            end

            if rawProgress >= 1 then
                table.remove(Animation.active, i)
                if type(anim.onComplete) == "function" then
                    pcall(anim.onComplete, target)
                end
            end
        end
    end
end

-- High-level animation helpers
function NovaUI.fadeIn(element, duration, easing, onComplete)
    if not element then return end
    element.visible = true
    return NovaUI.animate(element, {
        from = { alpha = 0 },
        alpha = 255,
        duration = duration or NovaUI.Tokens.animation.normal,
        easing = easing or "outCubic",
        onComplete = onComplete,
    })
end

function NovaUI.fadeOut(element, duration, easing, onComplete)
    if not element then return end
    return NovaUI.animate(element, {
        alpha = 0,
        duration = duration or NovaUI.Tokens.animation.fast,
        easing = easing or "inQuad",
        onComplete = function(el)
            el.visible = false
            if type(onComplete) == "function" then onComplete(el) end
        end,
    })
end

function NovaUI.slideTo(element, x, y, duration, easing, onComplete)
    if not element then return end
    return NovaUI.animate(element, {
        x = x or element.x,
        y = y or element.y,
        duration = duration or NovaUI.Tokens.animation.normal,
        easing = easing or "outQuart",
        onComplete = onComplete,
    })
end

function NovaUI.resizeTo(element, width, height, duration, easing, onComplete)
    if not element then return end
    return NovaUI.animate(element, {
        width = width or element.width,
        height = height or element.height,
        duration = duration or NovaUI.Tokens.animation.normal,
        easing = easing or "outQuart",
        onComplete = onComplete,
    })
end
