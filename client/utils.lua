function C(color, alpha)
    color = color or {255, 255, 255, 255}

    return tocolor(
        color[1] or 255,
        color[2] or 255,
        color[3] or 255,
        alpha or color[4] or 255
    )
end

function safeTickCount()
    if type(getTickCount) == "function" then
        return getTickCount()
    end

    return os.time() * 1000
end

function safeFrameDelta()
    return 16
end

function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function trim(value)
    value = tostring(value or "")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

function pointInRect(px, py, x, y, w, h)
    return px >= x
        and py >= y
        and px <= x + w
        and py <= y + h
end

function Phone.vp(vx, vy, vw, vh)
    return
        Phone.x + vx * Phone.S,
        Phone.y + vy * Phone.S,
        vw * Phone.S,
        vh * Phone.S
end

function formatTime()
    local time = getRealTime()

    return string.format(
        "%02d:%02d",
        time.hour,
        time.minute
    )
end

function formatDate()
    local time = getRealTime()

    return string.format(
        "%02d/%02d/%04d",
        time.monthday,
        time.month + 1,
        time.year + 1900
    )
end
