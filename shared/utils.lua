-- ============================================================================
-- AURA Phone - shared utilities
-- ============================================================================
Utils = {}

function Utils.clamp(v, a, b)
    return v < a and a or (v > b and b or v)
end

--- "1234567" -> "1,234,567"
function Utils.formatMoney(n)
    n = math.floor(tonumber(n) or 0)
    local s = tostring(n)
    local out = {}
    while #s > 3 do
        table.insert(out, 1, s:sub(-3))
        s = s:sub(1, -4)
    end
    table.insert(out, 1, s)
    return table.concat(out, ",")
end

--- seconds -> "mm:ss" (or "h:mm:ss")
function Utils.formatDuration(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    end
    return string.format("%02d:%02d", m, s)
end

--- real-time table -> "9:41"
function Utils.formatClock(dt)
    dt = dt or getRealTime and getRealTime()
    local h = dt.hour % 12
    if h == 0 then h = 12 end
    return string.format("%d:%02d", h, dt.min)
end

local WEEKDAYS = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

--- real-time table -> "Tue, 31 Aug"
function Utils.formatDate(dt)
    dt = dt or getRealTime and getRealTime()
    local wd = WEEKDAYS[dt.wday] or "Day"
    return string.format("%s, %d %s", wd:sub(1, 3), dt.day, MONTHS[dt.month] or "")
end

local FULL_MONTHS = { "January", "February", "March", "April", "May", "June", "July",
                      "August", "September", "October", "November", "December" }

--- real-time table -> "Tuesday, August 31"
function Utils.formatDateLong(dt)
    dt = dt or getRealTime and getRealTime()
    return string.format("%s, %s %d", WEEKDAYS[dt.wday] or "", FULL_MONTHS[dt.month] or "", dt.day)
end

--- timestamp (os.time) -> "Now" / "4m" / "3h" / "5d"
function Utils.timeAgo(t)
    if not t then return "" end
    local d = os.time() - t
    if d < 45 then return "Now" end
    if d < 3600 then return string.format("%dm", math.max(1, math.floor(d / 60))) end
    if d < 86400 then return string.format("%dh", math.floor(d / 3600)) end
    return string.format("%dd", math.floor(d / 86400))
end

--- true when v looks like a phone number (digits only, 8..12 chars)
function Utils.isValidNumber(v)
    return type(v) == "string" and #v >= 8 and #v <= 12 and v:match("^%d+$") ~= nil
end

--- "Nadia Karim" -> "NK"
function Utils.initials(name)
    name = tostring(name or "")
    local parts = {}
    for w in name:gmatch("%S+") do table.insert(parts, w:sub(1, 1):upper()) end
    local s = table.concat(parts)
    if #s == 0 then return "?" end
    return s:sub(1, 2)
end

--- stable hash -> palette index 1..n
function Utils.hash(name, n)
    local h = 0
    for c in tostring(name or "?"):gmatch(".") do
        h = (h * 31 + string.byte(c)) % 1000003
    end
    return (h % n) + 1
end
