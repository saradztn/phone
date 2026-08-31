-- ============================================================================
-- AURA Phone - security layer (server)
-- * strict validators for every external value
-- * sliding-window rate limiting (messages / calls / transfers)
-- * audit trail for sensitive operations (console + log file)
-- ============================================================================
SEC = { rl = {} }

--- clean string: no control chars, trimmed, length checked
function SEC.s(v, maxLen)
    if type(v) ~= "string" then return nil end
    v = v:gsub("%c", "")
    v = v:match("^%s*(.-)%s*$") or ""
    if #v == 0 or #v > (maxLen or 128) then return nil end
    return v
end

--- valid phone number (digits only, 8..12)
function SEC.number(v)
    if type(v) ~= "string" or #v < 8 or #v > 12 or v:match("^%d+$") == nil then return nil end
    return v
end

--- valid transfer amount (positive integer within config cap)
function SEC.amount(v)
    v = tonumber(v)
    if not v or v ~= math.floor(v) or v <= 0 or v > PhoneConfig.maxTransfer then return nil end
    return v
end

--- sliding window rate limit. Returns false when the player is over limit.
function SEC.rate(player, key, max, windowSec)
    if not isElement(player) then return false end
    local now = getTickCount()
    local t = SEC.rl[player]
    if not t then t = {} SEC.rl[player] = t end
    local r = t[key]
    if not r or now - r.t0 > windowSec * 1000 then
        r = { t0 = now, n = 0 }
        t[key] = r
    end
    r.n = r.n + 1
    return r.n <= max
end

setTimer(function()
    local now = getTickCount()
    for p, t in pairs(SEC.rl) do
        for k, r in pairs(t) do
            if now - r.t0 > 150000 then t[k] = nil end
        end
        if next(t) == nil then SEC.rl[p] = nil end
    end
end, 60000, 0)

--- write an audit line (console + monthly log file inside the resource)
function SEC.audit(action, player, data)
    local line = string.format("[%s] %s | %s | %s",
        os.date("%Y-%m-%d %H:%M:%S"),
        action,
        player and isElement(player) and getPlayerName(player) or "-",
        tostring(data or ""))
    outputConsole("[phone:audit] " .. line)
    pcall(writeFile, "logs/audit_" .. os.date("%Y%m") .. ".txt", line .. "\n", true)
end

--- reject + log helper used by every handler
function SEC.reject(player, reason, auditTag)
    outputConsole("[phone] REJECTED " .. (auditTag or "event") .. " from " .. (player and isElement(player) and getPlayerName(player) or "?") .. ": " .. tostring(reason))
    SEC.audit("REJECT:" .. tostring(auditTag or "event"), player, reason)
end

-- ---------------------------------------------------------------------------
-- cross-version exports
--   MTA 1.5.9 and earlier: a function in the resource's global scope IS the
--   export (so the exported function must be declared globally).
--   MTA 1.6+ : explicit registration via export().
function SEC.export(name, fn)
    if type(export) ~= "function" then return end   -- pre-1.6: global = export
    local ok = pcall(export, fn, name)              -- export(fn, name)
    if not ok then pcall(export, name) end          -- fallback: export(name)
end
