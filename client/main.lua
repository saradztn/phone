function openPhone()
    if Phone.visible then
        return
    end

    Phone.visible = true

    animatePhone(1)

    showCursor(true)

    triggerServerEvent(
        "auraPhone:requestData",
        resourceRoot
    )
end

function closePhone()
    if not Phone.visible then
        return
    end

    Phone.visible = false

    animatePhone(0)

    showCursor(false)

    clearPhoneInput()
end

function togglePhone()
    if Phone.visible then
        closePhone()
    else
        openPhone()
    end
end

bindKey("F2", "down", togglePhone)

addCommandHandler(
    "phone",
    togglePhone
)

bindKey(
    "escape",
    "down",
    function()
        if Phone.visible then
            closePhone()
            cancelEvent()
        end
    end
)

addEventHandler(
    "onClientResourceStart",
    resourceRoot,
    function()
        loadPhoneAssets()
        updatePhoneLayout()

        triggerServerEvent(
            "auraPhone:requestData",
            resourceRoot
        )
    end
)

addEventHandler(
    "onClientResourceStop",
    resourceRoot,
    destroyPhoneAssets
)

addEvent(
    "auraPhone:syncData",
    true
)

addEventHandler(
    "auraPhone:syncData",
    resourceRoot,
    function(data)
        if type(data) ~= "table" then
            return
        end

        Phone.data = data

        Phone.settings =
            data.settings
            or Phone.settings

        Phone.wallpaper =
            data.wallpaper
            or Phone.wallpaper

        Theme.apply(
            Phone.settings.dark
                and "dark"
                or "light"
        )
    end
)

addEvent(
    "auraPhone:receiveMessage",
    true
)

addEventHandler(
    "auraPhone:receiveMessage",
    resourceRoot,
    function(number, message)
        Phone.data.messages[number] =
            Phone.data.messages[number]
            or {}

        table.insert(
            Phone.data.messages[number],
            message
        )

        notify(
            "New Message",
            message.body
        )
    end
)

addEvent(
    "auraPhone:incomingCall",
    true
)

addEventHandler(
    "auraPhone:incomingCall",
    resourceRoot,
    function(number)
        Apps.calls.incoming = number
        Apps.calls.state = "incoming"

        Phone.app = "calls"
        Phone.locked = false

        openPhone()

        playPhoneSound("ringtone")
    end
)

addEvent(
    "auraPhone:callAccepted",
    true
)

addEventHandler(
    "auraPhone:callAccepted",
    resourceRoot,
    function(number)
        Apps.calls.number = number
        Apps.calls.state = "active"

        playPhoneSound("accept")
    end
)

addEvent(
    "auraPhone:callEnded",
    true
)

addEventHandler(
    "auraPhone:callEnded",
    resourceRoot,
    function()
        Apps.calls.state = "idle"
        Apps.calls.incoming = nil

        notify(
            "Phone",
            "Call ended."
        )
    end
)

addEvent(
    "auraPhone:operationResult",
    true
)

addEventHandler(
    "auraPhone:operationResult",
    resourceRoot,
    function(title, message)
        notify(title, message)
    end
)
