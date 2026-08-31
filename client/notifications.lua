function notify(title, body)
    table.insert(Notifications, 1, {
        title = title,
        body = body,
        created = safeTickCount()
    })

    playPhoneSound("notification")
end

function drawNotifications()
    local now = safeTickCount()

    for i = #Notifications, 1, -1 do
        if now - Notifications[i].created
            > Config.notificationDuration then

            table.remove(Notifications, i)
        end
    end

    for i, notification in ipairs(Notifications) do
        local y = 92 + (i - 1) * 65

        R(16, y, 328, 56, T.toast)

        TXT(
            notification.title,
            28,
            y + 5,
            290,
            22,
            0.82,
            T.text,
            "left",
            "center",
            "default-bold"
        )

        TXT(
            notification.body,
            28,
            y + 27,
            290,
            20,
            0.68,
            T.sub
        )
    end
end
