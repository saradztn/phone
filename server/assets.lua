-- ============================================================================
-- AURA Phone - vehicles / properties / jobs (server)
-- Vehicles: link the vehicle you're sitting in, then lock / engine / GPS.
--   Live vehicle elements are tracked in a session registry (VRefs).
--   After a server restart, an action re-activates automatically when the
--   owner (or anyone) enters the linked vehicle (onVehicleOccupant hook).
-- Properties: registered via export by your houses resource.
-- Jobs: static catalog from config + player's current job (phoneSetJob).
-- ============================================================================
local P = PhoneConfig.database.prefix
VRefs = {}      -- [vehicleId] = vehicle element (live session registry)
local VLastPos = {}  -- [vehicleId] = {x, y, z} last persisted position

local function toast(player, ok, text)
    triggerClientEvent(player, "phone:toast", player, ok and 1 or 0, text)
end

-- ---------------------------------------------------------------------------
-- vehicles
-- ---------------------------------------------------------------------------
addEvent("phone:vehicles:fetch", true)
addEventHandler("phone:vehicles:fetch", root, function()
    local player = client
    local pl = Players[player]
    if not pl then return end
    DB.select("SELECT id, name, model, locked, engine, last_x, last_y, last_z FROM " .. P .. "vehicles "
        .. "WHERE owner_id = " .. DB.s(pl.pkey) .. " ORDER BY updated_at DESC LIMIT " .. PhoneConfig.maxVehicles,
        function(ok, rows)
            local out = {}
            for _, r in ipairs(rows or {}) do
                table.insert(out, {
                    id = r.id,
                    name = r.name,
                    model = r.model,
                    locked = (r.locked == 1),
                    engine = (r.engine == 1),
                    x = r.last_x, y = r.last_y, z = r.last_z,
                })
            end
            triggerClientEvent(player, "phone:vehicles:list", player, out)
        end)
end)

addEvent("phone:vehicles:link", true)
addEventHandler("phone:vehicles:link", root, function()
    local player = client
    local pl = Players[player]
    if not pl then return end
    local v = getPedOccupiedVehicle(player, 0)
    if not v or not isElement(v) then
        toast(player, false, "You are not in a vehicle.")
        return
    end
    local vname = (getVehicleName and getVehicleName(v)) or "Vehicle"
    local vid = getElementId(v)
    local x, y, z = getElementPosition(v)
    DB.select("SELECT COUNT(*) AS c FROM " .. P .. "vehicles WHERE owner_id = " .. DB.s(pl.pkey), function(ok, rows)
        local count = ok and rows and tonumber(rows[1].c) or 0
        if count >= PhoneConfig.maxVehicles then
            toast(player, false, "Garage is full.")
            return
        end
        DB.run(string.format(
            "INSERT INTO %svehicles (owner_id, name, model, vehicle, last_x, last_y, last_z, locked, engine, updated_at) "
            .. "VALUES (%s, %s, %s, %d, %f, %f, %f, 0, 1, %d)",
            P, DB.s(pl.pkey), DB.s(vname), DB.s("Vehicle"), vid, x, y, z, os.time()), function(ok2)
            if ok2 then
                VRefs[vid] = v
                VLastPos[vid] = { x, y, z }
                toast(player, true, vname .. " added to your garage")
            else
                toast(player, false, "Could not save the vehicle.")
            end
        end)
    end)
end)

addEvent("phone:vehicles:action", true)
addEventHandler("phone:vehicles:action", root, function(id, action)
    local player = client
    local pl = Players[player]
    id = DB.i(id)
    if not pl or not id then return end
    if action ~= "lock" and action ~= "unlock" and action ~= "engine" then return end

    DB.select("SELECT * FROM " .. P .. "vehicles WHERE id = " .. id .. " AND owner_id = " .. DB.s(pl.pkey), function(ok, rows)
        local r = ok and rows and rows[1]
        if not r then
            toast(player, false, "This vehicle does not belong to you.")
            SEC.reject(player, "vehicle action on foreign vehicle id=" .. id, "vehicles:action")
            return
        end
        local v = tonumber(r.vehicle)
        local el = v and VRefs[v]
        local live = el and isElement(el)

        if action == "lock" and live then
            setEngineOn(el, false)
            setVehicleDormant(el, true)
            DB.run("UPDATE " .. P .. "vehicles SET locked = 1, engine = 0 WHERE id = " .. id)
            toast(player, true, r.name .. " locked")
            SEC.audit("VEHICLE_LOCK", player, r.name .. " (id=" .. id .. ")")
        elseif action == "unlock" and live then
            setVehicleDormant(el, false)
            DB.run("UPDATE " .. P .. "vehicles SET locked = 0 WHERE id = " .. id)
            toast(player, true, r.name .. " unlocked")
            SEC.audit("VEHICLE_UNLOCK", player, r.name .. " (id=" .. id .. ")")
        elseif action == "engine" and live then
            if getPedOccupiedVehicle(player, 0) ~= el then
                toast(player, false, "You must be in the vehicle.")
                return
            end
            local on = not isEngineOn(el)
            setEngineOn(el, on)
            DB.run("UPDATE " .. P .. "vehicles SET engine = " .. (on and 1 or 0) .. " WHERE id = " .. id)
            toast(player, true, "Engine " .. (on and "started" or "stopped"))
        else
            toast(player, false, "Vehicle is offline right now. Get in it once to re-link.")
        end
    end)
end)

-- re-adopt live vehicle elements when anyone enters them
addEventHandler("onVehicleOccupant", root, function(vehicle, seat, player, status)
    if status and seat == 0 then
        local vid = getElementId(vehicle)
        DB.select("SELECT owner_id FROM " .. P .. "vehicles WHERE vehicle = " .. vid, function(ok, rows)
            local r = ok and rows and rows[1]
            if r then VRefs[vid] = vehicle end
        end)
    end
end)

-- persist last position of moving linked vehicles (throttled)
setTimer(function()
    for vid, v in pairs(VRefs) do
        if isElement(v) and getVehicleController(v) then
            local x, y, z = getElementPosition(v)
            local last = VLastPos[vid]
            if not last or math.abs(x - last[1]) + math.abs(y - last[2]) > 8 then
                VLastPos[vid] = { x, y, z }
                DB.run(string.format(
                    "UPDATE %svehicles SET last_x = %f, last_y = %f, last_z = %f, updated_at = %d WHERE vehicle = %d",
                    P, x, y, z, os.time(), vid))
            end
        end
    end
end, 10000, 0)

-- ---------------------------------------------------------------------------
-- properties
-- ---------------------------------------------------------------------------
addEvent("phone:properties:fetch", true)
addEventHandler("phone:properties:fetch", root, function()
    local player = client
    local pl = Players[player]
    if not pl then return end
    DB.select("SELECT id, name, ptype, x, y, z FROM " .. P .. "properties WHERE owner_id = " .. DB.s(pl.pkey), function(ok, rows)
        local out = {}
        for _, r in ipairs(rows or {}) do
            table.insert(out, { id = r.id, name = r.name, type = r.ptype, x = r.x, y = r.y, z = r.z })
        end
        triggerClientEvent(player, "phone:properties:list", player, out)
    end)
end)

function phoneAddProperty(player, name, ptype, x, y, z)
    if not isElement(player) or not Players[player] then return false end
    name = SEC.s(name, 64)
    ptype = SEC.s(ptype, 32) or "House"
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not name or not x or not y or not z then return false end
    DB.run(string.format(
        "INSERT INTO %sproperties (owner_id, name, ptype, x, y, z) VALUES (%s, %s, %s, %f, %f, %f)",
        P, DB.s(Players[player].pkey), DB.s(name), DB.s(ptype), x, y, z))
    triggerClientEvent(player, "phone:toast", player, true, name .. " added to your homes")
    return true
end
SEC.export("phoneAddProperty", phoneAddProperty)

-- ---------------------------------------------------------------------------
-- jobs
-- ---------------------------------------------------------------------------
local function jobById(id)
    for _, j in ipairs(PhoneConfig.jobs) do
        if j.id == id then return j end
    end
    return nil
end

local function pushJobs(player)
    local pl = Players[player]
    if not pl then return end
    DB.select("SELECT svalue FROM " .. P .. "settings WHERE owner_id = " .. DB.s(pl.pkey) .. " AND skey = 'job'", function(ok, rows)
        local currentId = ok and rows and rows[1] and rows[1].svalue or "unemployed"
        local current = jobById(currentId) or PhoneConfig.jobs[1]
        triggerClientEvent(player, "phone:jobs:data", player, { current = current, list = PhoneConfig.jobs })
    end)
end

addEvent("phone:jobs:fetch", true)
addEventHandler("phone:jobs:fetch", root, function()
    if Players[client] then pushJobs(client) end
end)

function phoneSetJob(player, jobId)
    if not isElement(player) or not Players[player] then return false end
    local j = jobById(jobId)
    if not j then return false end
    local pl = Players[player]
    DB.run("INSERT INTO " .. P .. "settings (owner_id, skey, svalue) VALUES (" .. DB.s(pl.pkey) .. ", 'job', " .. DB.s(j.id) .. ") "
        .. "ON DUPLICATE KEY UPDATE svalue = " .. DB.s(j.id))
    phoneNotify(player, "Jobs", "Your job is now: " .. j.name, "jobs")
    pushJobs(player)
    return true
end
SEC.export("phoneSetJob", phoneSetJob)
