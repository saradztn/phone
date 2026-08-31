Database = {
    connection = nil
}

function dbExecSafe(query, ...)
    if not Database.connection
        or type(query) ~= "string" then
        return false
    end

    return dbExec(
        Database.connection,
        query,
        ...
    )
end

function dbQuerySafe(query, ...)
    if not Database.connection
        or type(query) ~= "string" then
        return {}
    end

    local handle =
        dbQuery(
            Database.connection,
            query,
            ...
        )

    if not handle then
        return {}
    end

    local result =
        dbPoll(handle, -1)

    if type(result) ~= "table" then
        return {}
    end

    return result
end

function initDatabase()
    Database.connection =
        dbConnect(
            "sqlite",
            "aura_phone.db"
        )

    if not Database.connection then
        return false
    end

    local queries = {
        [[
        CREATE TABLE IF NOT EXISTS phones (
            serial TEXT PRIMARY KEY,
            number TEXT UNIQUE,
            bank_balance INTEGER DEFAULT 0
        )
        ]],

        [[
        CREATE TABLE IF NOT EXISTS contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_serial TEXT,
            name TEXT,
            number TEXT
        )
        ]],

        [[
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender TEXT,
            receiver TEXT,
            body TEXT,
            timestamp INTEGER
        )
        ]],

        [[
        CREATE TABLE IF NOT EXISTS calls (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            caller TEXT,
            receiver TEXT,
            status TEXT,
            timestamp INTEGER
        )
        ]],

        [[
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_serial TEXT,
            title TEXT,
            body TEXT
        )
        ]],

        [[
        CREATE TABLE IF NOT EXISTS settings (
            owner_serial TEXT PRIMARY KEY,
            dark INTEGER,
            sounds INTEGER,
            pin_enabled INTEGER,
            pin TEXT,
            wallpaper TEXT
        )
        ]]
    }

    for _, query in ipairs(queries) do
        if not dbExecSafe(query) then
            return false
        end
    end

    return true
end

function getPhoneNumber(player)
    local serial =
        getPlayerSerial(player)

    local rows =
        dbQuerySafe(
            "SELECT number FROM phones WHERE serial=?",
            serial
        )

    if rows[1] then
        return tostring(rows[1].number)
    end

    local number

    repeat
        number = tostring(
            math.random(
                1000000,
                9999999
            )
        )

        rows = dbQuerySafe(
            "SELECT number FROM phones WHERE number=?",
            number
        )
    until #rows == 0

    dbExecSafe(
        "INSERT INTO phones(serial,number,bank_balance) VALUES(?,?,0)",
        serial,
        number
    )

    return number
end

function findPlayerByPhone(number)
    for _, player in ipairs(
        getElementsByType("player")
    ) do
        if getPhoneNumber(player)
            == tostring(number) then
            return player
        end
    end

    return nil
end
