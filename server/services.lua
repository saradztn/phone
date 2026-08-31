-- ============================================================================
-- AURA Phone - remaining services (server)
-- notes / app store / profile settings / server info / emergency quick calls
-- ============================================================================
local P = PhoneConfig.database.prefix

local function toast(player, ok, text)
    triggerClientEvent(player, "phone:toast", player, ok and 1 or 0, text)
end

-- ---------------------------------------------------------------------------
-- notes
-- ---------------------------------------------------------------------------
local function pushNotes(player)
    local pl = Players[player]
    if not pl then return end
    DB.select("SELECT id, title, body, created_at, updated_at FROM " .. P .. "notes "
        .. "WHERE owner_id = " .. DB.s(pl.pkey) .. " ORDER BY updated_at DESC LIMIT " .. PhoneConfig.maxNotes,
        function(ok, rows)
            local out = {}
            for _, r in ipairs(rows or {}) do
                table.insert(out, { id = r.id, title = r.title, body = r.body, created = r.created_at, updated = r.updated_at })
            end
            triggerClientEvent(player, "phone:notes:list", player, out)
        end)
end

addEvent("phone:notes:fetch", true)
addEventHandler("phone:notes:fetch", root, function()
    pushNotes(client)
end)

addEvent("phone:notes:save", true)
addEventHandler("phone:notes:save", root, function(id, title, body)
    local player = client
    local pl = Players[player]
    title = SEC.s(title, PhoneConfig.maxNoteTitle) or "Note"
    body = SEC.s(body, PhoneConfig.maxNoteLength) or ""
    if not pl then return end
    local now = os.time()
    if id and DB.i(id) then
        local iid = DB.i(id)
        DB.select("SELECT id FROM " .. P .. "notes WHERE id = " .. iid .. " AND owner_id = " .. DB.s(pl.pkey), function(ok, rows)
            if ok and rows and rows[1] then
                DB.run("UPDATE " .. P .. "notes SET title = " .. DB.s(title) .. ", body = " .. DB.s(body) .. ", updated_at = " .. now
                    .. " WHERE id = " .. iid)
                toast(player, true, "Note saved")
            end
        end)
    else
        DB.select("SELECT COUNT(*) AS c FROM " .. P .. "notes WHERE owner_id = " .. DB.s(pl.pkey), function(ok, rows)
            local count = ok and rows and tonumber(rows[1].c) or 0
            if count >= PhoneConfig.maxNotes then
                toast(player, false, "Notes are full.")
                return
            end
            DB.run(string.format(
                "INSERT INTO %snotes (owner_id, title, body, created_at, updated_at) VALUES (%s, %s, %s, %d, %d)",
                P, DB.s(pl.pkey), DB.s(title), DB.s(body), now, now))
                toast(player, true, "Note created")
        end)
    end
    pushNotes(player)
end)

addEvent("phone:notes:delete", true)
addEventHandler("phone:notes:delete", root, function(id)
    local player = client
    local pl = Players[player]
    id = DB.i(id)
    if not pl or not id then return end
    DB.run("DELETE FROM " .. P .. "notes WHERE id = " .. id .. " AND owner_id = " .. DB.s(pl.pkey), function(ok)
        if ok then
            toast(player, true, "Note deleted")
            pushNotes(player)
        end
    end)
end)

-- ---------------------------------------------------------------------------
-- app store
-- ---------------------------------------------------------------------------
addEvent("phone:store:fetch", true)
addEventHandler("phone:store:fetch", root, function()
    local player = client
    local pl = Players[player]
    if not pl then return end
    DB.select("SELECT app_id, installed FROM " .. P .. "apps WHERE owner_id = " .. DB.s(pl.pkey), function(ok, rows)
        local installed = {}
        for _, r in ipairs(rows or {}) do installed[r.app_id] = (r.installed == 1) end
        local out = {}
        for _, app in ipairs(PhoneApps) do
            table.insert(out, { id = app.id, name = app.name, desc = app.desc, installed = installed[app.id] ~= false })
        end
        for _, app in ipairs(PhoneConfig.storeComingSoon) do
            table.insert(out, { id = app.id, name = app.name, desc = app.desc, installed = false, soon = true })
        end
        triggerClientEvent(player, "phone:store:list", player, out)
    end)
end)

addEvent("phone:store:toggle", true)
addEventHandler("phone:store:toggle", root, function(appId)
    local player = client
    local pl = Players[player]
    appId = SEC.s(appId, 24)
    if not pl or not appId then return end
    -- only real apps can be toggled
    if not PhoneAppMap[appId] or appId == "store" then return end
    local now = os.time()
    DB.run("INSERT INTO " .. P .. "apps (owner_id, app_id, installed) VALUES (" .. DB.s(pl.pkey) .. ", " .. DB.s(appId) .. ", 0) "
        .. "ON DUPLICATE KEY UPDATE installed = 1 - installed", function()
        -- push the fresh state for that app only
        DB.select("SELECT installed FROM " .. P .. "apps WHERE owner_id = " .. DB.s(pl.pkey) .. " AND app_id = " .. DB.s(appId), function(ok, rows)
            local on = ok and rows and rows[1] and (rows[1].installed == 1)
            triggerClientEvent(player, "phone:store:state", player, appId, on and 1 or 0)
            toast(player, true, PhoneAppMap[appId].name .. (on and " installed" or " removed"))
        end)
    end)
end)

-- ---------------------------------------------------------------------------
-- profile settings (phone name, PIN) - cosmetic settings stay client-side
-- ---------------------------------------------------------------------------
local SETTING_VALIDATORS = {
    phoneName = function(v) return SEC.s(v, 16) end,
    pin = function(v) return (type(v) == "string" and v:match("^%d%d%d%d$") ~= nil) and v end,
    pinEnabled = function(v) return (v == 1 or v == "1" or v == true) and "1" or "0" end,
}

addEvent("phone:settings:set", true)
addEventHandler("phone:settings:set", root, function(key, value)
    local player = client
    local pl = Players[player]
    if not pl then return end
    local validator = SETTING_VALIDATORS[key]
    if not validator then
        SEC.reject(player, "unknown settings key " .. tostring(key), "settings:set")
        return
    end
    local clean = validator(value)
    if not clean then
        toast(player, false, "Invalid value.")
        return
    end
    local now = os.time()
    DB.run("INSERT INTO " .. P .. "settings (owner_id, skey, svalue) VALUES (" .. DB.s(pl.pkey) .. ", " .. DB.s(key) .. ", " .. DB.s(clean) .. ") "
        .. "ON DUPLICATE KEY UPDATE svalue = " .. DB.s(clean), function(ok)
        if ok then
            toast(player, true, "Saved")
            triggerClientEvent(player, "phone:settings:saved", player, key, clean)
        end
    end)
end)

-- ---------------------------------------------------------------------------
-- server info (Server app)
-- ---------------------------------------------------------------------------
local function serverName()
    local ok, motd = pcall(getMOTD)
    if ok and type(motd) == "table" and motd.text then
        return motd.text:match("[^\n]+") or "AURA RP"
    end
    return "AURA RP"
end

addEvent("phone:server:info", true)
addEventHandler("phone:server:info", root, function()
    local player = client
    local pl = Players[player]
    if not pl then return end
    triggerClientEvent(player, "phone:serverinfo", player, {
        name = serverName(),
        players = #getElementsByType("player"),
        version = getMTAVersion(),
        weather = PhoneConfig.weather,
        myName = getPlayerName(player),
        myNumber = pl.number,
    })
end)

-- ---------------------------------------------------------------------------
-- emergency quick dispatch (Police / Hospital buttons)
-- ---------------------------------------------------------------------------
addEvent("phone:emergency:call", true)
addEventHandler("phone:emergency:call", root, function(service)
    local player = client
    local pl = Players[player]
    if not pl then return end
    if service ~= "police" and service ~= "hospital" then return end
    if not SEC.rate(player, "emergency", 5, 120) then
        toast(player, false, "Dispatch is already on it.")
        return
    end
    local x, y, z = getElementPosition(player)
    local label = service == "police" and "police" or "medic"
    setTimer(function()
        if isElement(player) then
            phoneNotify(player, "Emergency", label:sub(1, 1):upper() .. label:sub(2) .. " unit is on its way to your location.", "emergency")
        end
    end, 3000, 1)
    SEC.audit("EMERGENCY_" .. service:upper(), player, string.format("pos %d,%d", math.floor(x), math.floor(y)))
end)
