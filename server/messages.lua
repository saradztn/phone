addEvent(
    "auraPhone:sendMessage",
    true
)

addEventHandler(
    "auraPhone:sendMessage",
    resourceRoot,
    function(receiver, body)

        local player = client

        receiver =
            tostring(receiver or "")

        body =
            tostring(body or "")

        if not isElement(player)
            or not validPhoneNumber(receiver)
            or #body < 1
            or #body > MESSAGE_MAX_LENGTH then

            return
        end

        local sender =
            getPhoneNumber(player)

        local timestamp =
            getRealTime().timestamp

        dbExecSafe(
            "INSERT INTO messages(sender,receiver,body,timestamp) VALUES(?,?,?,?)",
            sender,
            receiver,
            body,
            timestamp
        )

        local message = {
            from = sender,
            to = receiver,
            body = body,
            timestamp = timestamp
        }

        triggerClientEvent(
            player,
            "auraPhone:receiveMessage",
            resourceRoot,
            receiver,
            message
        )

        local target =
            findPlayerByPhone(receiver)

        if target then
            triggerClientEvent(
                target,
                "auraPhone:receiveMessage",
                resourceRoot,
                sender,
                message
            )
        end
    end
)
