Apps.contacts = {
    mode = nil,
    name = "",
    number = "",
    editing = 0
}

function Apps.contacts.render()
    Header("Contacts")
    Back()

    if Apps.contacts.mode then

        TXT(
            Apps.contacts.mode == "edit"
                and "Edit Contact"
                or "New Contact",
            20,
            115,
            320,
            30,
            1,
            T.text
        )

        Input(
            "contact_name",
            Apps.contacts.name,
            20,
            165,
            320,
            48,
            CONTACT_NAME_MAX_LENGTH,
            function(value)
                Apps.contacts.name = value
            end
        )

        Input(
            "contact_number",
            Apps.contacts.number,
            20,
            225,
            320,
            48,
            PHONE_NUMBER_MAX,
            function(value)
                Apps.contacts.number = value
            end,
            "%d"
        )

        Button(
            "save_contact",
            "Save",
            20,
            295,
            320,
            48,
            function()
                triggerServerEvent(
                    "auraPhone:saveContact",
                    resourceRoot,
                    Apps.contacts.editing,
                    Apps.contacts.name,
                    Apps.contacts.number
                )

                Apps.contacts.mode = nil
                clearPhoneInput()
            end
        )
    else

        local y = 115

        for _, contact in ipairs(
            Phone.data.contacts
        ) do
            Row(
                "contact_" .. contact.id,
                contact.name,
                contact.number,
                20,
                y,
                function()
                    Apps.contacts.mode = "edit"
                    Apps.contacts.editing = contact.id
                    Apps.contacts.name = contact.name
                    Apps.contacts.number = contact.number
                end
            )

            y = y + 62
        end

        Button(
            "add_contact",
            "+ Add Contact",
            20,
            650,
            320,
            46,
            function()
                Apps.contacts.mode = "new"
                Apps.contacts.editing = 0
                Apps.contacts.name = ""
                Apps.contacts.number = ""
            end
        )
    end
end
