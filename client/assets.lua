Assets = {
    textures = {}
}

function loadTexture(key)
    local path = "assets/" .. key .. ".png"

    Assets.textures[key] = dxCreateTexture(path)
end

function loadPhoneAssets()
    local textures = {
        "phone/phone_frame",
        "phone/screen_mask",
        "phone/dynamic_island",
        "phone/home_indicator",
        "phone/phone_shadow",

        "wallpapers/wallpaper_01",
        "wallpapers/wallpaper_02",

        "ui/circle",
        "ui/rounded_square",
        "ui/glass_panel",
        "ui/app_dock"
    }

    for _, app in ipairs(APP_GRID) do
        table.insert(textures, "icons/" .. app.icon)
    end

    for _, iconName in ipairs({
        "notifications",
        "search",
        "back",
        "close",
        "plus",
        "delete",
        "edit",
        "send",
        "call",
        "end_call",
        "mute",
        "speaker",
        "location",
        "lock",
        "unlock"
    }) do
        table.insert(textures, "icons/" .. iconName)
    end

    for _, key in ipairs(textures) do
        loadTexture(key)
    end
end

function asset(key)
    return Assets.textures[key]
end

function icon(key)
    return Assets.textures["icons/" .. key]
end

function destroyPhoneAssets()
    for _, texture in pairs(Assets.textures) do
        if isElement(texture) then
            destroyElement(texture)
        end
    end

    Assets.textures = {}
end
