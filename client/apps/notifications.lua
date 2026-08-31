-- AURA Phone v2 - Notification Center
registerPhoneApp({
    id = "notifications",
    name = "Notifications",
    render = function()
        D.rrect(0, 0, 360, 740, 0, D.t().screen)
        D.header(L("notifications"))

        local list = Phone.notif
        if #list == 0 then
            D.empty(L("noNotif"), 0, 220, 360)
        else
            D.list("notifications.app", 14, 80, 332, 740 - 80 - 18, #list, 64, function(i, y)
                local n = list[i]
                D.rrect(16, y + 3, 328, 58, 14, D.t().card)
                local app = Phone.appRegistry[n.icon]
                D.icon(app and Phone.img[app.icon], n.title, 28, y + 13, 38)
                D.text(n.title, 78, y + 10, { size = 12.5, bold = true, w = 250, h = 20 })
                if n.body and n.body ~= "" then
                    D.text(n.body, 78, y + 31, { size = 10.5, color = D.t().sub, w = 196, h = 24, wrap = true })
                end
                D.text(Utils.timeAgo(n.t), 288, y + 12, { w = 52, size = 9.5, align = "right", color = D.t().faint, h = 16 })
            end)
        end
    end,
})
