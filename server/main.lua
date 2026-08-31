function getSettings(player)
    local serial =
        getPlayerSerial(player)

    local row =
        dbQuerySafe(
            "SELECT * FROM settings WHERE owner_serial=?",
            serial
        )[1]

    if not row then
        dbExecSafe(
            [[
            INSERT INTO settings(
                owner_serial,
                dark,
                sounds,
                pin_enabled,
                pin,
                wallpaper
            )
            VALUES(?,1,1,0,'','wallpaper_01.png')
            ]],
            serial
        )

        return {
            dark = true,
            sounds = true,
            pinEnabled = false,
            pin = ""
        }, "wallpaper_01.png"
    end

    return {
        dark = tonumber(row.dark) == 1,
        sounds = tonumber(row.sounds) == 1,
        pinEnabled = tonumber(row.pin_enabled) == 1,
        pin = tostring(row.pin or "")
    }, tostring(
        row.wallpaper
        or "wallpaper_01.png"
    )
end

function getMessages(player)
    local number =
        getPhoneNumber(player)

    local rows =
        dbQuerySafe(
            [[
            SELECT sender,receiver,body,timestamp
            FROM messages
            WHERE sender=? OR receiver=?
            ORDER BY id ASC
            LIMIT 300
            ]],
            number,
            number
        )

    local output = {}

    for _, row in ipairs(rows) do
        local other

        if tostring(row.sender) == number then
            other = tostring(row.receiver)
        else
            other = tostring(row.sender)
        end

        output[other] =
            output[other] or {}

        table.insert(
            output[other],
            {
                from = tostring(row.sender),
                to = tostring(row.receiver),
                body = tostring(row.body),
                timestamp = tonumber(row.timestamp)
            }
        )
    end

    return output
end

function getNotes(player)
    return dbQuerySafe(
        [[
        SELECT id,title,body
        FROM notes
        WHERE owner_serial=?
        ORDER BY id DESC
        ]],
        getPlayerSerial(player)
    )
end

function sendPhoneData(player)
    local settings, wallpaper =
        getSettings(player)

    triggerClientEvent(
        player,
        "auraPhone:syncData",
        resourceRoot,
        {
            phoneNumber =
                getPhoneNumber(player),

            contacts =
                getContacts(player),

            messages =
                getMessages(player),

            calls =
                getCallHistory(player),

            notes =
                getNotes(player),

            settings = settings,
            wallpaper = wallpaper
        }
    )
end

addEvent(
    "auraPhone:requestData",
    true
)

addEventHandler(
    "auraPhone:requestData",
    resourceRoot,
    function()
        if isElement(client) then
            sendPhoneData(client)
        end
    end
)

addEvent(
    "auraPhone:saveSettings",
    true
)

addEventHandler(
    "auraPhone:saveSettings",
    resourceRoot,
    function(settings, wallpaper)

        local player = client

        if not isElement(player)
            or type(settings) ~= "table" then
            return
        end

        local pin =
            tostring(settings.pin or "")

        if #pin > 8
            or (pin ~= ""
                and not pin:match("^%d+$")) then
            pin = ""
        end

        if wallpaper ~= "wallpaper_02.png" then
            wallpaper = "wallpaper_01.png"
        end

        dbExecSafe(
            [[
            INSERT OR REPLACE INTO settings(
                owner_serial,
                dark,
                sounds,
                pin_enabled,
                pin,
                wallpaper
            )
            VALUES(?,?,?,?,?,?)
            ]],
            getPlayerSerial(player),
            settings.dark and 1 or 0,
            settings.sounds and 1 or 0,
            (
                settings.pinEnabled
                and pin ~= ""
            ) and 1 or 0,
            pin,
            wallpaper
        )
    end
)

addEventHandler(
    "onResourceStart",
    resourceRoot,
    function()

        if not initDatabase() then
            outputDebugString(
                "aura_phone: database initialization failed",
                1
            )
            return
        end

        for _, player in ipairs(
            getElementsByType("player")
        ) do
            getPhoneNumber(player)
        end
    end
)

addEventHandler(
    "onPlayerJoin",
    root,
    function()
        getPhoneNumber(source)
    end
)
