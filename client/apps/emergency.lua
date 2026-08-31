Apps.emergency = Apps.emergency or {}

function Apps.emergency.render()
    Header("Emergency")
    Back()

    R(20, 120, 320, 430, T.card)

    TXT(
        "Emergency",
        20,
        150,
        320,
        40,
        1.2,
        T.text,
        "center"
    )

    TXT(
        "Functional Aura Phone application",
        35,
        220,
        290,
        60,
        0.75,
        T.sub,
        "center",
        "center"
    )

    TXT(
        "This application is connected to the phone UI and navigation system.",
        35,
        300,
        290,
        80,
        0.7,
        T.sub,
        "center",
        "center"
    )

    Button(
        "emergency_action",
        "Action",
        70,
        450,
        220,
        50,
        function()
            notify(
                "Emergency",
                "Action executed."
            )
        end
    )
end
