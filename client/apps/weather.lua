-- AURA Phone v2 - Server info (weather + stats)
addEvent("phone:serverinfo", true)
addEventHandler("phone:serverinfo", root, function(info)
    Phone.data.serverInfo = info
end)

registerPhoneApp({
    id = "weather",
    name = "Server",
    onOpen = function()
        triggerServerEvent("phone:server:info")
    end,
    render = function()
        D.rrect(0, 0, 360, 740, 0, D.t().screen)
        D.header(L("server"))

        local info = Phone.data.serverInfo or {}
        local t = getRealTime()

        D.rrect(16, 74, 328, 110, 18, D.mix(D.t().info, { 18, 24, 40, 255 }, 0.25))
        D.icon(Phone.img["assets/icons/weather.png"], "Server", 32, 92, 48)
        D.text(info.weather or PhoneConfig.weather, 94, 92, { size = 17, bold = true })
        D.text(Utils.formatDateLong(t), 94, 122, { size = 11, color = D.t().sub })
        D.text(Utils.formatClock(t), 250, 92, { size = 22, bold = true, color = { 255, 255, 255, 235 } })

        local rows = {
            { L("server"), info.name or "—" },
            { L("players"), tostring(info.players or "…") },
            { L("mtaVersion"), info.version or "…" },
            { L("ping"), (getRealPing and getRealPing() or 0) .. " ms" },
        }
        local y = 206
        for _, r in ipairs(rows) do
            D.rrect(16, y, 328, 46, 12, D.t().card)
            D.text(r[1], 32, y + 8, { size = 11, color = D.t().sub, h = 18 })
            D.text(r[2], 32, y + 24, { size = 12.5, bold = true, h = 18 })
            y = y + 54
        end

        D.rrect(16, y + 8, 328, 96, 16, D.t().card)
        D.avatar(Phone.playerName ~= "" and Phone.playerName or "You", 32, y + 26, 60)
        D.text(Phone.playerName ~= "" and Phone.playerName or "Player", 106, y + 26, { size = 14, bold = true, h = 24 })
        D.text(L("yourPhone") .. ": " .. (Phone.number or "…"), 106, y + 54, { size = 11.5, color = D.t().sub, h = 20 })
        D.text(L("carrier"), 106, y + 76, { size = 10, color = D.t().faint, h = 16 })

        D.text(PhoneConfig.appName .. " v2.0", 0, 706, { w = 360, size = 9, align = "center", color = D.t().faint })
    end,
})
