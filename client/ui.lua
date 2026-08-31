-- ============================================================================
-- AURA Phone v2 - main UI (client)
-- * device image + screen geometry
-- * status bar, wallpaper, lock screen, home grid + dock
-- * call overlay, toasts, notification shade, home indicator
-- * openApp / goHome / Phone.setWaypoint
-- ============================================================================

-- ---------------------------------------------------------------------------
-- geometry: device image centered on screen, 88% of height
-- ---------------------------------------------------------------------------
local function updateGeometry()
    local sw, sh = Env.screenWH()
    local dH = math.min(sh * 0.92, sw * 1.7)
    local dW = dH * PhoneConfig.device.aspect
    dW = math.min(dW, sw * 0.8)
    dH = dW / PhoneConfig.device.aspect
    Phone.dX = (sw - dW) / 2
    Phone.dY = (sh - dH) / 2 - (1 - Phone.openP) * sh * 0.12
    Phone.dW, Phone.dH = dW, dH

    local sc = PhoneConfig.device.screen
    Phone.sx = Phone.dX + dW * sc.x0
    Phone.sy = Phone.dY + dH * sc.y0
    Phone.sw = dW * (sc.x1 - sc.x0)
    Phone.sh = dH * (sc.y1 - sc.y0)
    Phone.S = Phone.sw / 360
end

-- ---------------------------------------------------------------------------
-- app switching
-- ---------------------------------------------------------------------------
function openApp(id)
    local app = Phone.appRegistry[id]
    if not app then return end
    if Phone.app == id then return end
    Phone.app = id
    Sound.play("click")
    if app.onOpen then app.onOpen() end
end

function goHome()
    if Phone.app == "home" then return end
    local cur = Phone.appRegistry[Phone.app]
    if cur and cur.onClose then pcall(cur.onClose) end
    Phone.app = "home"
    Phone.shade = false
    Sound.play("back")
end

function Phone.startCall(number, name)
    if not Utils.isValidNumber(number) and number ~= "911" then
        pushLocalNotif("calls", L("invalidNumber"), number, "calls")
        return
    end
    Phone.call = { number = number, name = name or number, state = "CALLING", start = Env.tick() }
    Sound.play("send")
    triggerServerEvent("phone:call:start", number)
end

function Phone.setWaypoint(p)
    p = p or nil
    Phone.data.waypoint = p
    if p then
        local ok = pcall(function()
            if mapAddBlip then
                return mapAddBlip(p.x, p.y, p.z, 2, 0, 180, 70, 220, 255, 0)
            elseif createBlip then
                local b = createBlip(2, p.x, p.y, p.z, 26, 0, 180, 70, 255)
                if b then setBlipIcon(b, 2) end
                return b
            end
            return false
        end)
        if ok then
            Sound.play("click")
            pushLocalNotif("maps", L("setWp"), p.name, "messages")
        else
            pushLocalNotif("maps", L("gps"), p.name .. " (" .. math.floor(p.x) .. ", " .. math.floor(p.y) .. ")", "messages")
        end
    else
        pcall(function()
            if mapRemoveBlip then mapRemoveBlip() end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- status bar (top of screen)
-- ---------------------------------------------------------------------------
local function drawStatusBar()
    local t = D.t()
    local clock = Utils.formatClock(getRealTime())
    D.text(clock, 18, 8, { size = 11, bold = true, color = t.text })
    D.text(L("carrier"), 130, 8, { w = 100, size = 9, align = "center", color = t.faint })
    -- battery
    local bw = 22
    D.rrect(322, 10, bw, 11, 3, t.cardSoft)
    D.rrect(345, 13, 2.5, 5, 1, t.cardSoft)
    local pct = Phone.battery / 100
    local bcol = Phone.battery <= 15 and t.danger or t.success
    D.rrect(323.5, 11.5, math.max(2, (bw - 3) * pct), 8, 2, bcol)
    D.text(math.floor(Phone.battery) .. "%", 272, 9, { w = 46, size = 8.5, align = "right", color = t.sub })
    -- signal bars (by ping)
    local ping = getRealPing and getRealPing() or 50
    local bars = ping < 80 and 4 or ping < 160 and 3 or ping < 300 and 2 or 1
    for i = 1, 4 do
        local h = 3 + i * 2
        D.rrect(296 + i * 5, 20 - h, 3.4, h, 1, i <= bars and t.text or t.faint)
    end
    -- tap to toggle shade
    D.zone(0, 0, 360, 30, function()
        Phone.shade = not Phone.shade
        Sound.play("click")
    end)
end

-- ---------------------------------------------------------------------------
-- wallpaper
-- ---------------------------------------------------------------------------
local function drawWallpaper()
    local n = Phone.settings.wallpaper or 1
    if n == 0 then
        D.rrect(0, 0, 360, 740, 0, { 14, 22, 48, 255 })
        for i = 0, 10 do
            D.rrect(0, i * 74, 360, 74, 0, D.mix({ 14, 22, 48 }, { 30, 60, 110 }, i / 10), 90)
        end
        return
    end
    local img = Phone.img[PhoneConfig.wallpapers[n]]
    if img and Env.imgW(img) > 0 then
        local x, y = D.vx(0, 0, 360, 740)
        pcall(dxDrawImage, img, x, y, Phone.sw, Phone.sh)
        return
    end
    D.rrect(0, 0, 360, 740, 0, { 14, 22, 48, 255 })
end

-- ---------------------------------------------------------------------------
-- lock screen
-- ---------------------------------------------------------------------------
local PIN_KEYS = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#" }
local function drawLockScreen()
    local t = D.t()
    D.rrect(0, 0, 360, 740, 0, { 0, 0, 0, 120 })
    local rt = getRealTime()
    D.text(Utils.formatClock(rt), 0, 180, { w = 360, size = 64, bold = true, align = "center", color = { 255, 255, 255, 255 } })
    D.text(Utils.formatDateLong(rt), 0, 258, { w = 360, size = 13, align = "center", color = { 255, 255, 255, 200 } })
    D.text(L("carrier"), 0, 292, { w = 360, size = 10, align = "center", color = { 255, 255, 255, 140 } })

    local unread = Phone.data.unreadMsgs
    if unread > 0 then
        D.rrect(60, 350, 240, 44, 22, { 255, 255, 255, 28 })
        D.text(unread .. " " .. L("messages"):lower(), 60, 350, { w = 240, size = 12, align = "center", valign = "middle", color = { 255, 255, 255, 230 } })
    end

    if Phone.settings.pinEnabled and Phone.settings.pin ~= "" then
        D.text(L("pinPad"), 0, 440, { w = 360, size = 12, align = "center", color = { 255, 255, 255, 200 } })
        -- dots
        local dots = Input.pinInput or ""
        for i = 1, 4 do
            D.rrect(160 + (i - 1) * 24, 478, 10, 10, 5, i <= #dots and t.primary or { 255, 255, 255, 90 })
        end
        for i, k in ipairs(PIN_KEYS) do
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local kx = 120 + col * 52
            local ky = 516 + row * 52
            D.rrect(kx, ky, 44, 44, 22, { 255, 255, 255, 26 })
            D.text(k, kx, ky, { w = 44, h = 44, size = 17, align = "center", valign = "middle", color = { 255, 255, 255, 240 }, bold = true })
            D.zone(kx, ky, 44, 44, function()
                if k:match("%d") then
                    Input.pinInput = (Input.pinInput or "") .. k
                    Sound.play("click")
                    if #Input.pinInput == 4 then
                        local ok2 = Input.pinInput == Phone.settings.pin
                        Input.pinInput = ""
                        if ok2 then
                            Phone.locked = false
                        else
                            Sound.play("back")
                            pushLocalNotif("notifications", L("error"), L("pinWrong"), "messages")
                        end
                    end
                end
            end)
        end
    else
        D.text(L("unlock"), 0, 560, { w = 360, size = 11, align = "center", color = { 255, 255, 255, 150 } })
        D.zone(0, 520, 360, 120, function()
            Phone.locked = false
            Sound.play("click")
        end)
    end
end

-- ---------------------------------------------------------------------------
-- home screen: grid + dock
-- ---------------------------------------------------------------------------
local function isDock(id)
    for _, d in ipairs(PhoneConfig.dockApps or {}) do
        if d == id then return true end
    end
    return false
end

local function installed(id)
    return next(Phone.data.installed) == nil or Phone.data.installed[id]
end

local function drawAppIcon(app, cx, cy, size, showLabel)
    local img = Phone.img[app.icon]
    D.icon(img, app.name, cx, cy, size)
    if showLabel then
        D.text(app.name, cx - 14, cy + size + 4, { w = size + 28, size = 10, align = "center", color = { 255, 255, 255, 235 } })
    end
    if app.id == "messages" and Phone.data.unreadMsgs > 0 then
        D.badge(Phone.data.unreadMsgs, cx + size - 14, cy + 4)
    end
    D.zone(cx, cy, size, size, function()
        openApp(app.id)
    end)
end

local function drawHome()
    -- grid
    local apps = {}
    for _, app in ipairs(PhoneApps) do
        if installed(app.id) and not isDock(app.id) then
            table.insert(apps, app)
        end
    end
    table.sort(apps, function(a, b) return a.order < b.order end)

    local size = 58
    local left = 22
    local step = (360 - 44 - size) / 3
    local top = 78
    local rstep = 94
    for i, app in ipairs(apps) do
        local col = (i - 1) % 4
        local row = math.floor((i - 1) / 4)
        drawAppIcon(app, left + col * step, top + row * rstep, size, true)
    end

    -- dock
    local dockY = 740 - 96
    D.rrect(14, dockY, 332, 78, 26, D.t().dock)
    local dApps = {}
    for _, id in ipairs(PhoneConfig.dockApps or {}) do
        local app = PhoneAppMap[id]
        if app and installed(id) then table.insert(dApps, app) end
    end
    local dSize = 54
    local dStep = #dApps > 1 and (332 - 28 - dSize * #dApps) / (#dApps - 1) or 0
    for i, app in ipairs(dApps) do
        local cx = 28 + (i - 1) * dStep
        drawAppIcon(app, cx, dockY + 12, dSize, false)
    end
end

-- ---------------------------------------------------------------------------
-- call overlay
-- ---------------------------------------------------------------------------
local function drawCallOverlay()
    local c = Phone.call
    if not c then return end
    local t = D.t()
    D.rrect(0, 0, 360, 740, 0, { 8, 10, 16, 235 })

    D.avatar(c.name or c.number, 144, 120, 72)
    D.text(c.name or c.number, 0, 214, { w = 360, size = 17, bold = true, align = "center", color = { 255, 255, 255, 255 } })
    D.text(c.number, 0, 240, { w = 360, size = 11, align = "center", color = { 255, 255, 255, 160 } })

    if c.state == "CALLING" then
        D.text(L("calling"), 0, 300, { w = 360, size = 13, align = "center", color = { 255, 255, 255, 200 } })
        D.btn(138, 480, 84, 46, function()
            Phone.call = nil
            Sound.stop()
            triggerServerEvent("phone:call:end")
        end, { style = "danger", label = L("call"), size = 13 })
    elseif c.state == "RINGING" then
        D.text(L("ringing"), 0, 300, { w = 360, size = 13, align = "center", color = { 255, 255, 255, 200 } })
        D.btn(60, 480, 84, 46, function()
            Phone.call = nil
            Sound.stop()
            triggerServerEvent("phone:call:decline")
        end, { style = "danger", label = L("decline"), size = 12 })
        D.btn(216, 480, 84, 46, function()
            triggerServerEvent("phone:call:accept")
        end, { style = "success", label = L("accept"), size = 12 })
    elseif c.state == "ACTIVE" then
        local dur = math.floor((Env.tick() - c.start) / 1000)
        D.text(Utils.formatDuration(dur), 0, 300, { w = 360, size = 18, align = "center", color = { 255, 255, 255, 230 } })
        D.btn(138, 480, 84, 46, function()
            Phone.call = nil
            triggerServerEvent("phone:call:end")
        end, { style = "danger", label = L("call"), size = 13 })
    elseif c.state == "ENDED" then
        D.text(c.reason or L("ended"), 0, 300, { w = 360, size = 14, align = "center", color = { 255, 255, 255, 220 } })
        if c.duration and c.duration > 0 then
            D.text(Utils.formatDuration(c.duration), 0, 326, { w = 360, size = 11, align = "center", color = { 255, 255, 255, 140 } })
        end
    end
    -- auto-clear ENDED after 2.5s
    if c.state == "ENDED" then
        if not c.clearAt then c.clearAt = Env.tick() + 2500 end
        if Env.tick() > c.clearAt then Phone.call = nil end
    end
end

-- ---------------------------------------------------------------------------
-- toasts + notification shade
-- ---------------------------------------------------------------------------
local function updateToasts()
    if not Phone.toast then
        local next = table.remove(Phone.toastQueue, #Phone.toastQueue)
        if next then
            next.born = Env.tick()
            Phone.toast = next
        end
        return
    end
    if Env.tick() - Phone.toast.born > 3600 then
        Phone.toast = nil
    end
end

local function drawToasts()
    local toast = Phone.toast
    if not toast then return end
    local age = Env.tick() - toast.born
    local slide = math.min(1, age / 200)
    local y = -54 + slide * 54
    D.rrect(16, y, 328, 48, 14, D.t().toast)
    D.rrect(16, y, 3, 48, 1.5, D.t().primary)
    local app = Phone.appRegistry[toast.icon]
    D.icon(app and Phone.img[app.icon], toast.title, 28, y + 8, 32)
    D.text(toast.title, 70, y + 8, { size = 11.5, bold = true, h = 20, w = 260 })
    if toast.body then
        D.text(toast.body, 70, y + 27, { size = 10, color = D.t().sub, h = 16, w = 260 })
    end
    D.zone(16, y, 328, 48, function()
        Phone.toast = nil
    end)
end

local function drawShade()
    if not Phone.shade then return end
    local t = D.t()
    local h = 430
    D.rrect(0, 0, 360, h, 0, { 12, 14, 22, 240 })
    D.rrect(0, h - 1, 360, 1, 0, t.border)
    D.text(L("notifications"), 20, 44, { size = 15, bold = true })
    D.btn(282, 36, 58, 34, function()
        Phone.shade = false
        Sound.play("back")
    end, { style = "ghost", label = L("close"), size = 11 })

    local list = Phone.notif
    if #list == 0 then
        D.empty(L("noNotif"), 0, 120, 360)
    else
        local top = 84
        for i = 1, math.min(6, #list) do
            local n = list[i]
            local y = top + (i - 1) * 54
            D.rrect(16, y, 328, 48, 12, t.card)
            local app = Phone.appRegistry[n.icon]
            D.icon(app and Phone.img[app.icon], n.title, 28, y + 8, 32)
            D.text(n.title, 70, y + 7, { size = 11.5, bold = true, w = 240, h = 18 })
            D.text(n.body, 70, y + 25, { size = 10, color = t.sub, w = 240, h = 20 })
            D.text(Utils.timeAgo(n.t), 286, y + 8, { w = 52, size = 9, align = "right", color = t.faint, h = 16 })
        end
    end
    D.zone(0, h, 360, 740 - h, function()
        Phone.shade = false
    end)
end

-- ---------------------------------------------------------------------------
-- the main draw
-- ---------------------------------------------------------------------------
function drawPhone()
    D.zones = {}
    updateGeometry()
    local p = Phone.openP
    if p <= 0 then return end

    local img = Phone.img[PhoneConfig.device.img]
    -- device shadow
    D.rrectScreen(Phone.dX + 8, Phone.dY + 18, Phone.dW, Phone.dH, Phone.dH * 0.05, { 0, 0, 0, 255 }, 50 * p)
    if img and Env.imgW(img) > 0 then
        dxDrawImage(img, Phone.dX, Phone.dY, Phone.dW, Phone.dH)
    else
        -- fallback: drawn frame
        D.rrectScreen(Phone.dX, Phone.dY, Phone.dW, Phone.dH, Phone.dH * 0.05, { 24, 26, 34, 255 })
        D.rrectScreen(Phone.dX + 4, Phone.dY + 4, Phone.dW - 8, Phone.dH - 8, Phone.dH * 0.045, { 8, 9, 13, 255 })
    end

    -- clip: draw screen content (virtual space)
    drawWallpaper()

    if Phone.locked then
        drawStatusBar()
        drawLockScreen()
    else
        drawStatusBar()
        local app = Phone.appRegistry[Phone.app] or Phone.appRegistry["home"]
        if app then pcall(app.render) end
        if Phone.shade then drawShade() end
        drawToasts()
        drawCallOverlay()
    end

    updateToasts()

    -- keyboard cursor highlight
    if Input.kCursorVisible() then
        local z = Input.kCursor
        local vx, vy = (z.x - Phone.sx) / Phone.S, (z.y - Phone.sy) / Phone.S
        D.rrect(vx - 3, vy - 3, z.w / Phone.S + 6, z.h / Phone.S + 6, 10, { 0, 0, 0, 0 })
        local cr, cg, cb, ca = D.c(D.t().primary)
        local x, y, w, h = D.vx(vx - 3, vy - 3, z.w / Phone.S + 6, z.h / Phone.S + 6)
        dxDrawRectangle(x, y, w, 2, cr, cg, cb, ca)
        dxDrawRectangle(x, y + h - 2, w, 2, cr, cg, cb, ca)
        dxDrawRectangle(x, y, 2, h, cr, cg, cb, ca)
        dxDrawRectangle(x + w - 2, y, 2, h, cr, cg, cb, ca)
    end

    -- home indicator
    D.rrect(130, 726, 100, 4, 2, { 255, 255, 255, 120 })

    Input.consumeClick()
end

--- screen-space rounded rect helper (device frame fallback)
function D.rrectScreen(x, y, w, h, r, color, alpha)
    r = math.min(r, w / 2, h / 2)
    local cr, cg, cb, ca = D.c(color, alpha)
    if r > 0 then
        dxDrawRectangle(x, y + r, w, h - 2 * r, cr, cg, cb, ca)
        dxDrawRectangle(x, y, w, r, cr, cg, cb, ca)
        dxDrawRectangle(x, y + h - r, w, r, cr, cg, cb, ca)
        dxDrawRectangle(x, y, r, r, cr, cg, cb, ca)
        dxDrawRectangle(x + w - r, y, r, r, cr, cg, cb, ca)
        dxDrawRectangle(x, y + h - r, r, r, cr, cg, cb, ca)
        dxDrawRectangle(x + w - r, y + h - r, r, r, cr, cg, cb, ca)
    else
        dxDrawRectangle(x, y, w, h, cr, cg, cb, ca)
    end
end

-- ---------------------------------------------------------------------------
-- call state events (drive the overlay)
-- ---------------------------------------------------------------------------
addEvent("phone:call:incoming", true)
addEventHandler("phone:call:incoming", root, function(number, name)
    if Phone.call then
        triggerServerEvent("phone:call:decline")
        return
    end
    Phone.call = { number = number, name = name or number, state = "RINGING", start = Env.tick() }
    Sound.play("ring")
end)

addEvent("phone:call:state", true)
addEventHandler("phone:call:state", root, function(state, number, name, duration, reason)
    local c = Phone.call
    if state == "CALLING" then
        if not c then
            Phone.call = { number = number, name = name or number, state = "CALLING", start = Env.tick() }
        end
    elseif state == "ACTIVE" then
        if c then
            c.state = "ACTIVE"
            c.start = Env.tick()
            c.reason = nil
            Sound.stop()
        end
    elseif state == "ENDED" then
        if c then
            c.state = "ENDED"
            c.duration = duration
            c.reason = reason
            c.number = number or c.number
            c.name = name or c.name
            Sound.stop()
        else
            if reason == "Missed call" then Phone.data.unreadCalls = Phone.data.unreadCalls + 1 end
        end
    end
end)

addEvent("phone:calllog:data", true)
addEventHandler("phone:calllog:data", root, function(list)
    Phone.data.calllog = list or {}
end)
