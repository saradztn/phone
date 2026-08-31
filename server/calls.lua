ActiveCalls = {}

function callKey(player)
    return getPlayerSerial(player)
end

function clearCall(player)
    ActiveCalls[callKey(player)] = nil
end

function logCall(caller, receiver, status)
    dbExecSafe(
        "INSERT INTO calls(caller,receiver,status,timestamp) VALUES(?,?,?,?)",
        caller,
        receiver,
        status,
        getRealTime().timestamp
    )
end

addEvent(
    "auraPhone:startCall",
    true
)

addEventHandler(
    "auraPhone:startCall",
    resourceRoot,
    function(number)

        local player = client

        number =
            tostring(number or "")

        if not isElement(player)
            or not validPhoneNumber(number) then
            return
        end

        local target =
            findPlayerByPhone(number)

        local callerNumber =
            getPhoneNumber(player)

        if not target
            or target == player then

            triggerClientEvent(
                player,
                "auraPhone:callEnded",
                resourceRoot
            )

            return
        end

        ActiveCalls[callKey(player)] = {
            other = target,
            number = number
        }

        ActiveCalls[callKey(target)] = {
            other = player,
            number = callerNumber
        }

        logCall(
            callerNumber,
            number,
            "ringing"
        )

        triggerClientEvent(
            target,
            "auraPhone:incomingCall",
            resourceRoot,
            callerNumber
        )
    end
)

addEvent(
    "auraPhone:acceptCall",
    true
)

addEventHandler(
    "auraPhone:acceptCall",
    resourceRoot,
    function()

        local player = client
        local call =
            ActiveCalls[callKey(player)]

        if not call
            or not isElement(call.other) then
            return
        end

        triggerClientEvent(
            player,
            "auraPhone:callAccepted",
            resourceRoot,
            call.number
        )

        triggerClientEvent(
            call.other,
            "auraPhone:callAccepted",
            resourceRoot,
            getPhoneNumber(player)
        )
    end
)

addEvent(
    "auraPhone:declineCall",
    true
)

addEventHandler(
    "auraPhone:declineCall",
    resourceRoot,
    function()

        local player = client
        local call =
            ActiveCalls[callKey(player)]

        if not call then
            return
        end

        if isElement(call.other) then
            triggerClientEvent(
                call.other,
                "auraPhone:callEnded",
                resourceRoot
            )

            clearCall(call.other)
        end

        clearCall(player)
    end
)

addEvent(
    "auraPhone:endCall",
    true
)

addEventHandler(
    "auraPhone:endCall",
    resourceRoot,
    function()

        local player = client
        local call =
            ActiveCalls[callKey(player)]

        if not call then
            return
        end

        if isElement(call.other) then

            triggerClientEvent(
                call.other,
                "auraPhone:callEnded",
                resourceRoot
            )

            logCall(
                getPhoneNumber(player),
                getPhoneNumber(call.other),
                "ended"
            )

            clearCall(call.other)
        end

        clearCall(player)

        triggerClientEvent(
            player,
            "auraPhone:callEnded",
            resourceRoot
        )
    end
)

function getCallHistory(player)
    local number =
        getPhoneNumber(player)

    return dbQuerySafe(
        [[
        SELECT caller,receiver,status,timestamp
        FROM calls
        WHERE caller=? OR receiver=?
        ORDER BY id DESC
        LIMIT 50
        ]],
        number,
        number
    )
end
