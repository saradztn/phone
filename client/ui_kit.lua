function R(x, y, w, h, color, alpha)
    local X, Y, W, H = Phone.vp(x, y, w, h)

    dxDrawRectangle(
        X,
        Y,
        W,
        H,
        C(color, alpha)
    )
end

function TXT(text, x, y, w, h, scale, color, alignX, alignY, font)
    local X, Y, W, H = Phone.vp(x, y, w, h)

    dxDrawText(
        tostring(text or ""),
        X,
        Y,
        X + W,
        Y + H,
        C(color),
        scale * Phone.S,
        font or "default",
        alignX or "left",
        alignY or "center",
        false,
        false,
        false,
        false
    )
end

function IMG(texture, x, y, w, h, alpha)
    if not texture then
        return
    end

    local X, Y, W, H = Phone.vp(x, y, w, h)

    dxDrawImage(
        X,
        Y,
        W,
        H,
        texture,
        0,
        0,
        0,
        C({255, 255, 255, 255}, alpha or 255)
    )
end

function Header(title)
    TXT(
        title,
        20,
        48,
        320,
        38,
        1.4,
        T.text,
        "left",
        "center",
        "default-bold"
    )
end

function Back()
    IMG(icon("back"), 16, 96, 25, 25)

    addClickArea(
        "back",
        10, 90, 45, 42,
        function()
            Phone.app = "home"
            clearPhoneInput()
            playPhoneSound("back")
        end
    )
end

function Button(id, text, x, y, w, h, callback, color)
    R(x, y, w, h, color or T.primary)

    TXT(
        text,
        x,
        y,
        w,
        h,
        0.9,
        T.text,
        "center"
    )

    addClickArea(id, x, y, w, h, callback)
end

function Input(id, value, x, y, w, h, maxLength, callback, filter, masked)
    R(x, y, w, h, T.input)

    local display = tostring(value or "")

    if masked then
        display = string.rep("•", #display)
    end

    TXT(
        display,
        x + 10,
        y,
        w - 20,
        h,
        0.85,
        T.text
    )

    addClickArea(
        id,
        x,
        y,
        w,
        h,
        function()
            setPhoneInput(
                id,
                value,
                maxLength,
                callback,
                filter
            )
        end
    )
end

function Row(id, title, subtitle, x, y, callback)
    R(x, y, 320, 54, T.card)

    TXT(title, x + 14, y + 4, 290, 25, 0.9, T.text)

    TXT(
        subtitle or "",
        x + 14,
        y + 27,
        290,
        20,
        0.7,
        T.sub
    )

    if callback then
        addClickArea(
            id,
            x,
            y,
            320,
            54,
            callback
        )
    end
end
