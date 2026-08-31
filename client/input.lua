function clearClickAreas()
    UI.areas = {}
end

function addClickArea(id, x, y, w, h, callback)
    table.insert(UI.areas, {
        id = id,
        x = x,
        y = y,
        w = w,
        h = h,
        callback = callback
    })
end

function setPhoneInput(id, value, maxLength, onChange, filter)
    UI.input = {
        id = id,
        value = tostring(value or ""),
        maxLength = maxLength or 255,
        onChange = onChange,
        filter = filter
    }
end

function clearPhoneInput()
    UI.input = nil
end

addEventHandler("onClientCharacter", root, function(character)
    if not Phone.visible or not UI.input then
        return
    end

    if UI.input.filter and not character:match(UI.input.filter) then
        return
    end

    if #UI.input.value >= UI.input.maxLength then
        return
    end

    UI.input.value = UI.input.value .. character

    if UI.input.onChange then
        UI.input.onChange(UI.input.value)
    end
end)

bindKey("backspace", "down", function()
    if Phone.visible and UI.input then
        UI.input.value = UI.input.value:sub(1, -2)

        if UI.input.onChange then
            UI.input.onChange(UI.input.value)
        end
    end
end)

addEventHandler("onClientClick", root,
    function(button, state, absoluteX, absoluteY)

        if button ~= "left"
            or state ~= "down"
            or not Phone.visible then
            return
        end

        local x =
            (absoluteX - Phone.x) / Phone.S

        local y =
            (absoluteY - Phone.y) / Phone.S

        for i = #UI.areas, 1, -1 do
            local area = UI.areas[i]

            if pointInRect(
                x, y,
                area.x, area.y,
                area.w, area.h
            ) then
                playPhoneSound("click")

                area.callback()
                cancelEvent()

                return
            end
        end
    end
)
