-- ============================================================================
-- AURA Phone v2 - client core
-- * Phone state, app registry (registerPhoneApp), open/close
-- * environment probe (reports what this client can/cannot do)
-- * safe wrappers for time/screen/image/font APIs
-- * single onClientRender entry point
-- ============================================================================

-- ---------------------------------------------------------------------------
-- environment probe + safe wrappers
-- ---------------------------------------------------------------------------
Env = {
    mouse  = type(dxGetMousePosition) == "function" or type(dxGetCursorPosition) == "function",
    dxf    = type(dxfCreateImage) == "function",
    tex    = type(dxCreateTexture) == "function",
    font   = type(dxCreateFont) == "function",
    tick   = type(getTickCount) == "function",
    delta  = type(getFrameDelta) == "function",
    scr    = type(getScreenSize) == "function",
    draw   = type(dxDrawText) == "function" and type(dxDrawRectangle) == "function",
}
Env.ok = Env.draw and (Env.dxf or Env.tex)

function Env.mousePos()
    if dxGetMousePosition then return dxGetMousePosition() end
    if dxGetCursorPosition then return dxGetCursorPosition() end
    return 0, 0
end

function Env.mouseState()
    if dxGetMouseState then return dxGetMouseState() end
    return 0
end

function Env.cursor(v)
    if type(showCursor) == "function" then showCursor(v) end
end

function Env.tick()
    if type(getTickCount) == "function" then return getTickCount() end
    return math.floor(os.clock() * 1000)
end

function Env.delta()
    if getFrameDelta then
        local d = getFrameDelta()
        if d and d > 0 then return d end
    end
    return 16
end

function Env.screenWH()
    if getScreenSize then
        local w, h = getScreenSize()
        if w and h and w > 0 and h > 0 then return w, h end
    end
    return 1024, 768
end

--- create a DX image; works on dxf (1.4+) or old dxCreateTexture
function Env.image(path)
    if Env.dxf then
        local ok, img = pcall(dxfCreateImage, path)
        if ok and img then return img end
        return nil
    elseif Env.tex then
        local ok, img = pcall(dxCreateTexture, path)
        if ok and img then return img end
        return nil
    end
    return nil
end

local function imgW(img)
    if type(dxfGetImageWidth) == "function" then
        local ok, w = pcall(dxfGetImageWidth, img)
        if ok and w and w > 0 then return w end
    end
    local ok, w, h = pcall(dxfGetImageSize, img)
    if ok and w and w > 0 then return w end
    return 0
end
Env.imgW = imgW

-- ---------------------------------------------------------------------------
-- global phone state
-- ---------------------------------------------------------------------------
Phone = {
    open = false,
    closing = false,
    openP = 0,               -- open/close progress 0..1
    app = "home",
    locked = true,
    pinInput = "",
    shade = false,
    shadeP = 0,
    call = nil,              -- {number, name, state, start, reason, duration, soundId}
    toast = nil,             -- current toast
    toastQueue = {},
    notif = {},              -- notification center list (newest first)
    battery = PhoneConfig.battery and PhoneConfig.battery.start or 100,
    number = "",
    playerName = "",
    pkey = "",
    lowBattWarned = false,
    keyboard = not Env.mouse,  -- fallback input mode

    settings = {
        theme = "dark",
        wallpaper = 1,
        uiScale = 1.0,
        ringVol = 70,
        notifyVol = 70,
        sfxVol = 100,
        phoneName = PhoneConfig.appName or "AURA Phone",
        pinEnabled = false,
        pin = "",
        language = PhoneConfig.language,
    },

    data = {
        contacts = {},
        chats = {},
        calllog = {},
        bank = { balance = 0, txns = {} },
        notes = {},
        vehicles = {},
        properties = {},
        jobs = nil,
        store = {},
        installed = {},
        serverInfo = nil,
        waypoint = nil,
        unreadMsgs = 0,
        unreadCalls = 0,
        pendingChat = nil,
    },

    img = {},       -- path -> image
    fonts = {},     -- "size|bold|script" -> font
}

-- geometry, recomputed every frame (screen px)
Phone.dX, Phone.dY, Phone.dW, Phone.dH = 0, 0, 0, 0   -- device image rect
Phone.sx, Phone.sy, Phone.sw, Phone.sh = 0, 0, 0, 0   -- screen rect inside device
Phone.S = 1                                              -- virtual->px scale

-- ---------------------------------------------------------------------------
-- app registry
-- ---------------------------------------------------------------------------
local AppRegistry = {}
function registerPhoneApp(def)
    if type(def) ~= "table" or not def.id or not def.render then
        error("registerPhoneApp: expected { id, render = function() ... }", 2)
        return
    end
    def.name = def.name or def.id
    def.icon = def.icon or ("assets/icons/" .. def.id .. ".png")
    AppRegistry[def.id] = def
end
Phone.appRegistry = AppRegistry

-- ---------------------------------------------------------------------------
-- fonts (Noto Sans Latin + Noto Sans Arabic, Regular + Bold)
-- ---------------------------------------------------------------------------
local FONT_SIZES = { 10, 11, 12, 13, 14, 16, 18, 22, 26, 34, 54 }
local function loadFonts()
    if not Env.font then return end
    for _, size in ipairs(FONT_SIZES) do
        for _, script in ipairs({ "en", "ar" }) do
            for _, bold in ipairs({ false, true }) do
                local key = size .. (bold and "b" or "") .. script
                local path = (script == "ar") and (bold and PhoneConfig.fonts.arBold or PhoneConfig.fonts.ar)
                    or (bold and PhoneConfig.fonts.enBold or PhoneConfig.fonts.en)
                local ok, f = pcall(dxCreateFont, path, size)
                if ok and f then Phone.fonts[key] = f end
            end
        end
    end
    if next(Phone.fonts) == nil then
        outputDebugString("[phone] WARNING: custom fonts failed to load - using default font")
    end
end
Phone.loadFonts = loadFonts

--- pick a font element for text; nil = MTA default font
function Phone.pickFont(size, bold, text)
    if not Env.font then return nil end
    local script = (text and isArabic(text)) and "ar" or "en"
    local f = Phone.fonts[size .. (bold and "b" or "") .. script]
    if f then return f end
    -- size not in the preset list: pick nearest
    local best = nil
    for _, s in ipairs(FONT_SIZES) do
        if not best or math.abs(s - size) < math.abs(best - size) then best = s end
    end
    return Phone.fonts[best .. (bold and "b" or "") .. script]
end

-- ---------------------------------------------------------------------------
-- image preload
-- ---------------------------------------------------------------------------
function Phone.preload()
    if not (Env.dxf or Env.tex) then return end
    local function load(path)
        Phone.img[path] = Env.image(path)
    end
    load(PhoneConfig.device.img)
    load("assets/ui/rounded.png")
    load("assets/ui/circle.png")
    for _, app in pairs(AppRegistry) do load(app.icon) end
    for i, wp in ipairs(PhoneConfig.wallpapers or {}) do load(wp) end
end

-- ---------------------------------------------------------------------------
-- sound
-- ---------------------------------------------------------------------------
Sound = { id = nil }
function Sound.play(name)
    local file = PhoneConfig.sounds and PhoneConfig.sounds[name]
    if not file then return nil end
    local vol
    if name == "ring" then vol = Phone.settings.ringVol
    elseif name == "notify" or name == "send" then vol = Phone.settings.notifyVol
    else vol = Phone.settings.sfxVol end
    if not vol or vol <= 0 then return nil end
    if type(playClientSound) ~= "function" then return nil end
    if Sound.id then pcall(stopClientSound, Sound.id) end
    local ok, id = pcall(playClientSound, resourceRoot, file, name == "ring")
    Sound.id = ok and id or nil
    return Sound.id
end
function Sound.stop()
    if Sound.id then pcall(stopClientSound, Sound.id) Sound.id = nil end
end

-- ---------------------------------------------------------------------------
-- open / close
-- ---------------------------------------------------------------------------
function Phone.toggle()
    if Phone.open then closePhone() else openPhone() end
end

function openPhone()
    if Phone.open or Phone.closing then return end
    Phone.open = true
    Phone.openP = 0
    Sound.play("click")
    guiSetInputEnabled(false)
    Env.cursor(true)
end

function closePhone()
    if not Phone.open or Phone.closing then return end
    Phone.closing = true
    Sound.stop()
    Sound.play("back")
end

local function finishClose()
    Phone.open = false
    Phone.closing = false
    Phone.openP = 0
    Phone.locked = true
    Phone.call = nil
    Input.reset()
    guiSetInputEnabled(true)
    Env.cursor(false)
end

local function bindPhoneKey(key, handler)
    if type(bindKey) ~= "function" then
        outputDebugString("[phone] WARNING: bindKey() is not available on this client")
        return false
    end
    -- MTA 1.6+: bindKey(key, keyState, handler)
    local ok1, res1 = pcall(bindKey, key, "down", handler)
    if ok1 and res1 == true then return true end
    -- legacy 1.5.x: bindKey(key, allowInVehicle, handler)
    local ok2, res2 = pcall(bindKey, key, false, handler)
    if ok2 and res2 == true then return true end
    outputDebugString("[phone] WARNING: could not bind " .. tostring(key) .. " - the key may be in use")
    return false
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    if type(PhoneConfig.openKey) == "string" and PhoneConfig.openKey ~= "" then
        bindPhoneKey(PhoneConfig.openKey, Phone.toggle)
    end
end)

addEventHandler("onClientWasted", localPlayer, function()
    closePhone()
end)

-- battery simulation (driven from the render loop - no setTimer needed)
local battAcc = 0

-- ---------------------------------------------------------------------------
-- server handshake
-- ---------------------------------------------------------------------------
addEvent("phone:settings:load", true)
addEventHandler("phone:settings:load", root, function(s)
    s = s or {}
    if s.phoneName then Phone.settings.phoneName = s.phoneName end
    if s.pin then Phone.settings.pin = tostring(s.pin) end
    if s.number then Phone.number = tostring(s.number) end
    if s.displayName and s.displayName ~= "" then Phone.playerName = s.displayName end
    if Phone.playerName == "" and localPlayer then
        local ok, nm = pcall(getPlayerName, localPlayer)
        Phone.playerName = ok and nm or ""
    end
    Phone.settings.pinEnabled = (s.pinEnabled == 1 or s.pinEnabled == true)
    Phone.locked = Phone.settings.pinEnabled and Phone.settings.pin ~= ""
end)

addEvent("phone:apps:load", true)
addEventHandler("phone:apps:load", root, function(map)
    Phone.data.installed = map or {}
end)

addEvent("phone:count", true)
addEventHandler("phone:count", root, function(field, value)
    if field == "msgs" then
        Phone.data.unreadMsgs = math.max(0, tonumber(value) or 0)
    elseif field == "calls" then
        Phone.data.unreadCalls = Phone.data.unreadCalls + math.max(0, tonumber(value) or 0)
    end
end)

addEvent("phone:toast", true)
addEventHandler("phone:toast", root, function(ok, text)
    pushLocalNotif(ok and "notifications" or "notifications", ok and L("ok") or L("error"), text or "", "messages")
end)

-- ---------------------------------------------------------------------------
-- local notification helper (toast + center)
-- ---------------------------------------------------------------------------
function pushLocalNotif(icon, title, body, cat)
    table.insert(Phone.notif, 1, { icon = icon or "notifications", title = title or "Notification", body = body or "", t = os.time() })
    if #Phone.notif > 30 then table.remove(Phone.notif) end
    table.insert(Phone.toastQueue, 1, { icon = icon or "notifications", title = title or "", body = body or "" })
    if #Phone.toastQueue > 8 then table.remove(Phone.toastQueue) end
    if Phone.open and not Phone.closing then
        Sound.play("notify")
    end
end

addEvent("phone:notify", true)
addEventHandler("phone:notify", root, function(icon, title, body, cat)
    pushLocalNotif(icon, title, body, cat or "messages")
end)

-- ---------------------------------------------------------------------------
-- the single render entry point
-- ---------------------------------------------------------------------------
addEventHandler("onClientRender", root, function()
    if not Phone.open and not Phone.closing then return end
    if not Phone.openP then Phone.openP = 0 end
    -- progress
    local delta = Env.delta()
    local speed = delta / 260
    if Phone.closing then
        Phone.openP = math.max(0, Phone.openP - speed)
        if Phone.openP <= 0 then finishClose() return end
    elseif Phone.open then
        Phone.openP = math.min(1, Phone.openP + speed)
        -- battery drain (1 tick per second of being open)
        battAcc = battAcc + delta
        if battAcc >= 1000 then
            battAcc = battAcc - 1000
            Phone.battery = math.max(1, (Phone.battery or 100) - 0.15)
            if Phone.battery <= 15 and not Phone.lowBattWarned then
                Phone.lowBattWarned = true
                pushLocalNotif("notifications", L("phone"), "Battery low (15%)", "messages")
            end
        end
    end
    Input.update()
    drawPhone()
end)

-- ---------------------------------------------------------------------------
-- resource start / stop
-- ---------------------------------------------------------------------------
addEventHandler("onClientResourceStart", resourceRoot, function()
    loadFonts()
    Phone.preload()
    -- one-time environment report
    local missing = {}
    if not Env.mouse then missing[#missing + 1] = "mouse" end
    if not (Env.dxf or Env.tex) then missing[#missing + 1] = "images" end
    if not Env.font then missing[#missing + 1] = "fonts" end
    if not Env.ok then
        outputDebugString("[phone] WARNING: this client is missing: " .. table.concat(missing, ", ") ..
            " - the phone UI cannot work on it (a standard PC MTA client is required).")
    else
        outputDebugString("[phone] environment ok" .. (#missing > 0 and (" (fallbacks for: " .. table.concat(missing, ", ") .. ")") or ""))
    end
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    Sound.stop()
    guiSetInputEnabled(true)
    Env.cursor(false)
    Phone.open, Phone.closing, Phone.openP = false, false, 0
end)
