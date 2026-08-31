function getContacts(player)
    return dbQuerySafe(
        "SELECT id,name,number FROM contacts WHERE owner_serial=? ORDER BY name",
        getPlayerSerial(player)
    )
end

addEvent(
    "auraPhone:saveContact",
    true
)

addEventHandler(
    "auraPhone:saveContact",
    resourceRoot,
    function(id, name, number)

        local player = client

        id = tonumber(id) or 0
        name = tostring(name or "")
        number = tostring(number or "")

        if not isElement(player)
            or #name < 1
            or #name > CONTACT_NAME_MAX_LENGTH
            or not validPhoneNumber(number) then
            return
        end

        local serial =
            getPlayerSerial(player)

        if id > 0 then
            dbExecSafe(
                "UPDATE contacts SET name=?,number=? WHERE id=? AND owner_serial=?",
                name,
                number,
                id,
                serial
            )
        else
            dbExecSafe(
                "INSERT INTO contacts(owner_serial,name,number) VALUES(?,?,?)",
                serial,
                name,
                number
            )
        end

        sendPhoneData(player)
    end
)
