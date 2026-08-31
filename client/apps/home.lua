Apps.home = {}

function Apps.home.render()

    local wallpaper =
        Phone.wallpaper:gsub("%.png$", "")

    IMG(
        asset("wallpapers/" .. wallpaper),
        0, 0,
        360, 740
    )

    for i, app in ipairs(APP_GRID) do
        local column = (i - 1) % 4
        local row = math.floor((i - 1) / 4)

        local x = 24 + column * 82
        local y = 105 + row * 95

        IMG(icon(app.icon), x, y, 58, 58)

        TXT(
            app.name,
            x - 5,
            y + 60,
            68,
            22,
            0.56,
            T.text,
            "center"
        )

        addClickArea(
            "app_" .. app.id,
            x - 5,
            y - 5,
            68,
            84,
            function()
                Phone.app = app.id
                clearPhoneInput()
            end
        )
    end

    R(18, 660, 324, 64, T.dock)

    local dock = {
        {"phone", "calls"},
        {"messages", "messages"},
        {"contacts", "contacts"},
        {"settings", "settings"}
    }

    for i, item in ipairs(dock) do
        local x = 40 + (i - 1) * 72

        IMG(icon(item[1]), x, 668, 48, 48)

        addClickArea(
            "dock_" .. item[1],
            x,
            660,
            55,
            62,
            function()
                Phone.app = item[2]
            end
        )
    end
end
