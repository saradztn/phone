Apps.messages = {
    selected = nil,
    draft = "",
    newNumber = ""
}

function Apps.messages.render()
    Header("Messages")
    Back()

    if Apps.messages.selected then
        local number = Apps.messages.selected

        TXT(
            number,
            20,
            104,
            320,
            32,
            0.9,
            T.sub
        )

        local list =
            Phone.data.messages[number] or {}

        local y = 145

        for _, message in ipairs(list) do
            local mine =
                message.from == Phone.data.phoneNumber

            local x = mine and 120 or 20

            R(
                x,
                y,
                220,
                38,
                mine and T.primary or T.card
            )

            TXT(
                message.body,
                x + 8,
                y + 3,
                204,
                32,
                0.7,
                T.text
            )

            y = y + 45
        end

        Input(
            "draft",
            Apps.messages.draft,
            20,
            650,
            250,
            45,
            MESSAGE_MAX_LENGTH,
            function(value)
                Apps.messages.draft = value
            end
        )

        Button(
            "send",
            "Send",
            278,
            650,
            62,
            45,
            function()
                local body =
                    trim(Apps.messages.draft)

                if body ~= ""
                    and validPhoneNumber(number) then

                    triggerServerEvent(
                        "auraPhone:sendMessage",
                        resourceRoot,
                        number,
                        body
                    )

                    Apps.messages.draft = ""
                    clearPhoneInput()
                end
            end
        )
    else
        local y = 110

        for number, list in pairs(Phone.data.messages) do
            local last = list[#list]

            Row(
                "conversation_" .. number,
                number,
                last and last.body or "",
                20,
                y,
                function()
                    Apps.messages.selected = number
                end
            )

            y = y + 62
        end

        Input(
            "new_number",
            Apps.messages.newNumber,
            20,
            570,
            320,
            45,
            PHONE_NUMBER_MAX,
            function(value)
                Apps.messages.newNumber = value
            end,
            "%d"
        )

        Button(
            "open_conversation",
            "Open Conversation",
            20,
            630,
            320,
            45,
            function()
                if validPhoneNumber(
                    Apps.messages.newNumber
                ) then
                    Apps.messages.selected =
                        Apps.messages.newNumber

                    Phone.data.messages[
                        Apps.messages.selected
                    ] =
                        Phone.data.messages[
                            Apps.messages.selected
                        ] or {}
                else
                    notify(
                        "Messages",
                        "Enter a valid number."
                    )
                end
            end
        )
    end
end
