function updatePhoneLayout()
    Phone.sw, Phone.sh =
        guiGetScreenSize()

    Phone.S = math.min(
        Phone.sw / PHONE_W,
        Phone.sh / PHONE_H
    ) * Config.phoneScale

    Phone.x =
        (Phone.sw - PHONE_W * Phone.S) / 2

    Phone.y =
        (Phone.sh - PHONE_H * Phone.S) / 2
end

function drawLockScreen()
    local wallpaper =
        Phone.wallpaper:gsub("%.png$", "")

    IMG(
        asset("wallpapers/" .. wallpaper),
        0,
        0,
        360,
        740
    )

    TXT(
        formatTime(),
        20,
        145,
        320,
        80,
        2.4,
        T.text,
        "center"
    )

    TXT(
        formatDate(),
        20,
        220,
        320,
        35,
        0.9,
        T.text,
        "center"
    )

    if Phone.settings.pinEnabled then

        Input(
            "unlock_pin",
            Phone.pinInput,
            70,
            460,
            220,
            48,
            8,
            function(value)
                Phone.pinInput = value
            end,
            "%d",
            true
        )

        Button(
            "unlock",
            "Unlock",
            70,
            525,
            220,
            50,
            function()
                if Phone.pinInput
                    == Phone.settings.pin
                    and Phone.settings.pin ~= "" then

                    Phone.locked = false
                    Phone.pinInput = ""

                    clearPhoneInput()
                    playPhoneSound("unlock")
                else
                    notify(
                        "Phone",
                        "Incorrect PIN."
                    )
                end
            end
        )
    else
        Button(
            "unlock",
            "Unlock",
            70,
            500,
            220,
            52,
            function()
                Phone.locked = false
                playPhoneSound("unlock")
            end
        )
    end
end

function renderPhone()
    updatePhoneLayout()
    updateAnimations()

    if not Phone.visible
        and Animations.phone.value <= 0.001 then
        return
    end

    clearClickAreas()

    IMG(
        asset("phone/phone_shadow"),
        -12,
        -10,
        384,
        770,
        Animations.phone.value * 255
    )

    IMG(
        asset("phone/phone_frame"),
        0,
        0,
        360,
        740
    )

    R(
        12,
        12,
        336,
        716,
        T.screen
    )

    if Phone.locked then
        drawLockScreen()
    else
        TXT(
            formatTime(),
            22,
            15,
            90,
            28,
            0.7,
            T.text
        )

        TXT(
            Phone.battery .. "%",
            292,
            15,
            48,
            28,
            0.65,
            T.text,
            "right"
        )

        IMG(
            asset("phone/dynamic_island"),
            122,
            18,
            116,
            30
        )

        local app =
            Apps[Phone.app]
            or Apps.home

        app.render()

        drawNotifications()

        IMG(
            asset("phone/home_indicator"),
            115,
            710,
            130,
            12
        )

        addClickArea(
            "home_indicator",
            95,
            695,
            170,
            40,
            function()
                Phone.app = "home"
                clearPhoneInput()
            end
        )
    end
end

addEventHandler(
    "onClientRender",
    root,
    renderPhone
)
