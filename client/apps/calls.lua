Apps.calls = {
    number = "",
    state = "idle",
    incoming = nil
}

function Apps.calls.render()
    Header("Phone")
    Back()

    if Apps.calls.state == "incoming" then

        TXT(
            Apps.calls.incoming,
            20,
            180,
            320,
            50,
            1.4,
            T.text,
            "center"
        )

        TXT(
            "Incoming call",
            20,
            230,
            320,
            35,
            0.9,
            T.sub,
            "center"
        )

        Button(
            "accept",
            "Accept",
            30,
            430,
            130,
            55,
            function()
                triggerServerEvent(
                    "auraPhone:acceptCall",
                    resourceRoot
                )

                Apps.calls.state = "active"
            end,
            T.success
        )

        Button(
            "decline",
            "Decline",
            200,
            430,
            130,
            55,
            function()
                triggerServerEvent(
                    "auraPhone:declineCall",
                    resourceRoot
                )

                Apps.calls.state = "idle"
                Apps.calls.incoming = nil
            end,
            T.danger
        )

    elseif Apps.calls.state == "active" then

        TXT(
            Apps.calls.number
                or Apps.calls.incoming
                or "",
            20,
            190,
            320,
            50,
            1.5,
            T.text,
            "center"
        )

        TXT(
            "Call active",
            20,
            245,
            320,
            35,
            0.9,
            T.success,
            "center"
        )

        Button(
            "hang",
            "End Call",
            70,
            480,
            220,
            55,
            function()
                triggerServerEvent(
                    "auraPhone:endCall",
                    resourceRoot
                )

                Apps.calls.state = "idle"
                Apps.calls.incoming = nil
            end,
            T.danger
        )

    else

        Input(
            "dial",
            Apps.calls.number,
            20,
            115,
            320,
            48,
            PHONE_NUMBER_MAX,
            function(value)
                Apps.calls.number = value
            end,
            "%d"
        )

        local keys = {
            "1", "2", "3",
            "4", "5", "6",
            "7", "8", "9",
            "*", "0", "#"
        }

        for i, key in ipairs(keys) do
            local column = (i - 1) % 3
            local row = math.floor(
                (i - 1) / 3
            )

            Button(
                "dial_key_" .. i,
                key,
                45 + column * 95,
                190 + row * 62,
                70,
                50,
                function()
                    if key:match("%d")
                        and #Apps.calls.number
                            < PHONE_NUMBER_MAX then

                        Apps.calls.number =
                            Apps.calls.number .. key
                    end
                end,
                T.cardSoft
            )
        end

        Button(
            "call",
            "Call",
            90,
            470,
            180,
            55,
            function()
                if validPhoneNumber(
                    Apps.calls.number
                ) then
                    triggerServerEvent(
                        "auraPhone:startCall",
                        resourceRoot,
                        Apps.calls.number
                    )

                    Apps.calls.state = "calling"
                else
                    notify(
                        "Phone",
                        "Invalid phone number."
                    )
                end
            end,
            T.success
        )
    end
end
