-- ============================================================================
-- AURA Phone v2 - drawing primitives (client)
-- All coordinates are in the virtual 360x740 screen space.
-- ============================================================================
D = {}

-- ---------------------------------------------------------------------------
-- color system
-- ---------------------------------------------------------------------------
local PALETTES = {
    dark = {
        screen   = { 10, 12, 18, 255 },
        card     = { 24, 28, 40, 245 },
        cardSoft = { 34, 39, 54, 235 },
        input    = { 18, 21, 30, 255 },
        primary  = { 52, 211, 153, 255 },
        primaryDeep = { 16, 185, 129, 255 },
        text     = { 244, 246, 250, 255 },
        sub      = { 150, 159, 178, 255 },
        faint    = { 96, 104, 124, 255 },
        danger   = { 248, 113, 113, 255 },
        dangerDeep = { 225, 29, 72, 255 },
        warn     = { 251, 191, 36, 255 },
        success  = { 52, 211, 153, 255 },
        info     = { 96, 165, 250, 255 },
        border   = { 255, 255, 255, 16 },
        dock     = { 255, 255, 255, 26 },
        toast    = { 22, 25, 34, 248 },
        bubbleMe = { 34, 197, 94, 255 },
        bubbleThem = { 33, 40, 56, 255 },
        dim      = { 4, 6, 12, 185 },
        avatar   = { 96, 165, 250, 255 },
    },
    light = {
        screen   = { 244, 245, 248, 255 },
        card     = { 255, 255, 255, 250 },
        cardSoft = { 236, 238, 244, 255 },
        input    = { 255, 255, 255, 255 },
        primary  = { 5, 150, 105, 255 },
        primaryDeep = { 4, 120, 85, 255 },
        text     = { 24, 28, 38, 255 },
        sub      = { 96, 104, 122, 255 },
        faint    = { 148, 156, 172, 255 },
        danger   = { 220, 60, 60, 255 },
        dangerDeep = { 190, 30, 50, 255 },
        warn     = { 214, 150, 20, 255 },
        success  = { 5, 150, 105, 255 },
        info     = { 50, 110, 200, 255 },
        border   = { 0, 0, 0, 22 },
        dock     = { 255, 255, 255, 170 },
        toast    = { 255, 255, 255, 248 },
        bubbleMe = { 34, 197, 94, 255 },
        bubbleThem = { 232, 234, 240, 255 },
        dim      = { 20, 22, 30, 150 },
        avatar   = { 50, 110, 200, 255 },
    },
}

function D.theme()
    return PALETTES[Phone.settings.theme] or PALETTES.dark
end

local T
function D.t()
    T = D.theme()
    return T
end

--- color -> 4 numbers with optional alpha override
function D.c(color, alpha)
    local r, g, b = color[1], color[2], color[3]
    return r, g, b, (alpha or color[4] or 255)
end

function D.mix(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        (a[4] or 255) + ((b[4] or 255) - (a[4] or 255)) * t,
    }
end

-- ---------------------------------------------------------------------------
-- virtual -> screen mapping
-- ---------------------------------------------------------------------------
function D.vx(vx, vy, vw, vh)
    return Phone.sx + vx * Phone.S, Phone.sy + vy * Phone.S, (vw or 0) * Phone.S, (vh or 0) * Phone.S
end

-- ---------------------------------------------------------------------------
-- zones (click targets) — rebuilt every frame
-- ---------------------------------------------------------------------------
D.zones = {}
function D.zone(vx, vy, vw, vh, cb)
    local x, y, w, h = D.vx(vx, vy, vw, vh)
    table.insert(D.zones, { x = x, y = y, w = w, h = h, cb = cb, key = false })
end

function D.pick(mx, my)
    for i = #D.zones, 1, -1 do
        local z = D.zones[i]
        if mx >= z.x and mx <= z.x + z.w and my >= z.y and my <= z.y + z.h then
            return z
        end
    end
    return nil
end

-- keyboard cursor
D.cursorId = nil
D.cursorTarget = nil  -- zone currently highlighted

local AVA_COLORS = {
    { 96, 165, 250 }, { 248, 113, 113 }, { 251, 191, 36 }, { 167, 139, 250 },
    { 52, 211, 153 }, { 251, 146, 60 }, { 56, 189, 248 }, { 244, 114, 182 },
}
local function avatarColor(name)
    local h = 0
    for i = 1, math.min(#tostring(name), 12) do
        h = (h * 31 + name:byte(i)) % 997
    end
    return AVA_COLORS[(h % #AVA_COLORS) + 1]
end

-- ---------------------------------------------------------------------------
-- text
-- ---------------------------------------------------------------------------
--- o: {size, bold, color, align(left/center/right), valign, font, w, h, wrap}
function D.text(s, vx, vy, o)
    s = tostring(s == nil and "" or s)
    o = o or {}
    local size = o.size or 12
    local col = o.color or D.t().text
    local cr, cg, cb, ca = D.c(col)
    local x, y, w, h = D.vx(vx, vy, o.w or 0, o.h or size * 1.4)
    local font = o.font or Phone.pickFont(size, o.bold, s)
    local scale = font and 1 or (size / 13)
    local alignX = (o.align == "center") and "center" or ((o.align == "right") and "right" or "left")
    local alignY = (o.valign == "middle") and "center" or ((o.valign == "bottom") and "bottom" or "top")
    if w <= 0 then
        w = nil
    end
    local ok, ex, ey = pcall(dxDrawText, s, x, y, w, h, cr, cg, cb, ca,
        scale, font or "default", alignX, alignY, false, o.wrap and true or false, false)
    return ok
end

-- ---------------------------------------------------------------------------
-- rounded rect (image corners, square fallback)
-- ---------------------------------------------------------------------------
function D.rrect(vx, vy, vw, vh, r, color, alpha)
    local x, y, w, h = D.vx(vx, vy, vw, vh)
    r = math.min(r, w / 2, h / 2) * Phone.S
    if r < 1 then r = 0 end
    local cr, cg, cb, ca = D.c(color, alpha)
    if r > 0 then
        dxDrawRectangle(x, y + r, w, h - 2 * r, cr, cg, cb, ca)
        if h > 2 * r then
            dxDrawRectangle(x, y, w, r, cr, cg, cb, ca)
            dxDrawRectangle(x, y + h - r, w, r, cr, cg, cb, ca)
        end
        local img = Phone.img["assets/ui/circle.png"]
        if img and Env.imgW(img) > 0 then
            dxDrawImage(img, x, y, r, r, cr, cg, cb, ca)
            dxDrawImage(img, x + w - r, y, r, r, cr, cg, cb, ca)
            dxDrawImage(img, x, y + h - r, r, r, cr, cg, cb, ca)
            dxDrawImage(img, x + w - r, y + h - r, r, r, cr, cg, cb, ca)
        else
            dxDrawRectangle(x, y, r, r, cr, cg, cb, ca)
            dxDrawRectangle(x + w - r, y, r, r, cr, cg, cb, ca)
            dxDrawRectangle(x, y + h - r, r, r, cr, cg, cb, ca)
            dxDrawRectangle(x + w - r, y + h - r, r, r, cr, cg, cb, ca)
        end
    else
        dxDrawRectangle(x, y, w, h, cr, cg, cb, ca)
    end
end

-- ---------------------------------------------------------------------------
-- icon: image, or colored letter tile fallback (no dxf available)
-- ---------------------------------------------------------------------------
local TILE_COLORS = {
    { 52, 211, 153 }, { 96, 165, 250 }, { 251, 191, 36 }, { 248, 113, 113 },
    { 167, 139, 250 }, { 251, 146, 60 }, { 56, 189, 248 }, { 244, 114, 182 },
    { 148, 163, 184 },
}
local function tileColor(name)
    local h = 0
    for i = 1, math.min(#tostring(name), 12) do
        h = (h * 31 + tostring(name):byte(i)) % 899
    end
    return TILE_COLORS[(h % #TILE_COLORS) + 1]
end

function D.icon(img, name, vx, vy, size, alpha)
    if img and Env.imgW(img) > 0 then
        local x, y = D.vx(vx, vy, size)
        local ok = pcall(dxDrawImage, img, x, y, size * Phone.S, size * Phone.S, D.c({ 255, 255, 255, alpha or 255 }))
        if ok then return end
    end
    -- letter tile fallback
    local tc = tileColor(name or "?")
    D.rrect(vx, vy, size, size, size * 0.24, tc, alpha)
    D.text(tostring(name or "?"):sub(1, 1):upper(), vx, vy, {
        w = size, h = size, size = size * 0.44, bold = true, align = "center", valign = "middle",
        color = { 255, 255, 255, 235 },
    })
end

-- ---------------------------------------------------------------------------
-- avatar (initials circle)
-- ---------------------------------------------------------------------------
function D.avatar(name, vx, vy, size)
    local col = avatarColor(name or "?")
    D.rrect(vx, vy, size, size, size / 2, col)
    D.text(Utils.initials(name or "?"), vx, vy, {
        w = size, h = size, size = size * 0.34, bold = true, align = "center", valign = "middle",
        color = { 255, 255, 255, 240 },
    })
end

-- ---------------------------------------------------------------------------
-- badge (count bubble)
-- ---------------------------------------------------------------------------
function D.badge(n, vx, vy)
    local label = n > 99 and "99+" or tostring(n)
    local w = 16 + #label * 6
    D.rrect(vx - w, vy - 9, w + 6, 18, 9, D.t().danger)
    D.text(label, vx - w, vy - 9, { w = w + 6, h = 18, size = 10, bold = true, align = "center", valign = "middle", color = { 255, 255, 255, 255 } })
end

-- ---------------------------------------------------------------------------
-- button
-- ---------------------------------------------------------------------------
--- style: primary | danger | success | info | ghost | card
function D.btn(vx, vy, vw, vh, cb, o)
    o = o or {}
    local t = D.t()
    local styles = {
        primary = t.primary, danger = t.danger, success = t.success, info = t.info,
        ghost = { 255, 255, 255, 22 }, card = t.cardSoft,
    }
    local base = o.color or styles[o.style or "card"]
    local hovered = false
    local x, y, w, h = D.vx(vx, vy, vw, vh)
    if Input.mx and Input.inside then
        hovered = Input.mx >= x and Input.mx <= x + w and Input.my >= y and Input.my <= y + h
    end
    local col = hovered and D.mix(base, { 255, 255, 255 }, 0.12) or base
    D.rrect(vx, vy, vw, vh, o.radius or math.min(vh / 2, 13), col)
    if o.label then
        local tc = (o.style == "card" or o.style == "ghost") and t.text or { 10, 22, 16, 255 }
        D.text(o.label, vx, vy, {
            w = vw, h = vh, size = o.size or 13, bold = true, align = "center", valign = "middle", color = tc,
        })
    end
    D.zone(vx, vy, vw, vh, function()
        Sound.play("click")
        cb()
    end)
end

-- ---------------------------------------------------------------------------
-- list row card
-- ---------------------------------------------------------------------------
function D.row(vx, vy, vw, vh, cb)
    D.rrect(vx, vy, vw, vh, 13, D.t().card)
    D.zone(vx, vy, vw, vh, cb)
end

-- ---------------------------------------------------------------------------
-- field (text input)
-- ---------------------------------------------------------------------------
--- o: {placeholder, max, digits, alnum, onSubmit, onEdit}
function D.field(id, vx, vy, vw, vh, o)
    o = o or {}
    local focused = Input.focus == id
    if focused then
        D.rrect(vx - 1.5, vy - 1.5, vw + 3, vh + 3, vh / 2, D.t().primary, 90)
    end
    D.rrect(vx, vy, vw, vh, vh / 2, D.t().input)
    local val = focused and Input.buf or ""
    if val == "" then
        D.text(o.placeholder or "Type…", vx + 14, vy, { h = vh, size = 12.5, valign = "middle", color = D.t().faint })
    else
        D.text(val, vx + 14, vy, { h = vh, size = 12.5, valign = "middle", color = D.t().text })
    end
    if focused and math.floor(Env.tick() / 450) % 2 == 0 then
        local cx = vx + 16 + #val * 7
        D.rrect(cx, vy + vh * 0.3, 1.6, vh * 0.4, 0.8, D.t().primary)
    end
    D.zone(vx, vy, vw, vh, function()
        Input._wasFieldClick = true
        Input.focus = id
        Input.buf = ""
        Input.fieldSpec[id] = {
            max = o.max or 64, digits = o.digits, alnum = o.alnum,
            onSubmit = o.onSubmit, onEdit = o.onEdit,
        }
    end)
    return focused
end

-- ---------------------------------------------------------------------------
-- virtualized list
-- ---------------------------------------------------------------------------
D.sc = {}
D.listRects = {}
function D.list(id, vx, vy, vw, vh, count, rowH, drawRow)
    local sc = D.sc[id] or { off = 0 }
    D.sc[id] = sc
    local contentH = count * rowH
    local maxOff = math.max(0, contentH - vh)
    sc.off = Utils.clamp(sc.off, 0, maxOff)

    local x, y, w, h = D.vx(vx, vy, vw, vh)
    D.listRects[id] = { x = x, y = y, w = w, h = h }

    -- scrollbar
    if maxOff > 4 then
        local barH = math.max(28, h * h / contentH)
        local barY = y + (sc.off / maxOff) * (h - barH)
        D.rrect(vx + vw - 3, vy + (barY - y) / Phone.S, 2, barH / Phone.S, 1, { 255, 255, 255, 60 })
    end

    local i0 = math.max(0, math.floor(sc.off / rowH))
    local i1 = math.min(count, i0 + math.ceil(vh / rowH) + 1)
    for i = i0, i1 - 1 do
        drawRow(i + 1, vy + (i * rowH - sc.off))
    end
end

function D.scrollToBottom(id, vh, count, rowH)
    local sc = D.sc[id] or { off = 0 }
    D.sc[id] = sc
    sc.off = math.max(0, count * rowH - vh)
end

function D.listTargetAt(mx, my)
    for id, r in pairs(D.listRects) do
        if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
            return id
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- toggle
-- ---------------------------------------------------------------------------
function D.toggle(vx, vy, vw, vh, on, cb)
    D.rrect(vx, vy, vw, vh, vh / 2, on and D.t().primary or { 90, 98, 118, 255 })
    local kx = on and vx + vw - vh + 2 or vx + vh - 2
    D.rrect(kx, vy + 2, vh - 4, vh - 4, (vh - 4) / 2, { 255, 255, 255, 255 })
    D.zone(vx, vy, vw, vh, function()
        cb(not on)
    end)
end

-- ---------------------------------------------------------------------------
-- slider
-- ---------------------------------------------------------------------------
function D.slider(id, vx, vy, vw, value, o, cb)
    o = o or {}
    local min, max = o.min or 0, o.max or 100
    local p = Utils.clamp((value - min) / (max - min), 0, 1)
    D.rrect(vx, vy + 7, vw, 6, 3, { 255, 255, 255, 30 })
    D.rrect(vx, vy + 7, math.max(6, vw * p), 6, 3, D.t().primary)
    D.rrect(vx + vw * p - 10, vy, 20, 20, 10, { 255, 255, 255, 240 })
    D.zone(vx - 10, vy - 8, vw + 20, 36, function()
        -- jump to click position
        local mx = Input.downAt and Input.downAt.x or Input.mx
        local x, _, w = D.vx(vx, vy, vw)
        local np = Utils.clamp((mx - x) / w, 0, 1)
        cb(min + np * (max - min))
    end)
end

-- ---------------------------------------------------------------------------
-- modal
-- ---------------------------------------------------------------------------
function D.modal(title, drawFn, mh)
    D.rrect(0, 0, 360, 740, 0, D.t().dim)
    local mw, mh = 316, (mh or 280)
    local vx, vy = (360 - mw) / 2, 180
    D.rrect(vx, vy, mw, mh, 18, D.t().card)
    D.text(title, vx + 20, vy + 16, { size = 15, bold = true })
    D.zone(vx, vy, mw, mh, nil) -- swallow clicks behind the card
    if drawFn then drawFn(vx, vy, mw, mh) end
end

-- ---------------------------------------------------------------------------
-- empty state + spinner + header
-- ---------------------------------------------------------------------------
function D.empty(msg, vx, vy, vw)
    D.text(msg or D.t().none, vx, vy, { w = vw, size = 12, align = "center", color = D.t().faint, h = 40 })
end

function D.spinner(vx, vy, size)
    local a = math.floor(Env.tick() / 60) % 12
    for i = 0, 11 do
        local ang = math.rad((i * 30) + a * 30)
        local alpha = (i == 0) and 255 or 60
        D.rrect(vx + size / 2 + math.cos(ang) * size * 0.38, vy + size / 2 + math.sin(ang) * size * 0.38, 3, 3, 1.5, D.t().primary, alpha)
    end
end

function D.header(title, rightFn)
    D.rrect(0, 0, 360, 60, 0, D.t().screen)
    D.text(title, 20, 18, { size = 16, bold = true })
    -- back button
    D.zone(4, 8, 44, 44, function()
        Sound.play("back")
        goHome()
    end)
    D.text("<", 4, 8, { w = 44, size = 20, align = "center", valign = "middle", color = D.t().sub, bold = true })
    if rightFn then rightFn() end
    D.rrect(0, 60, 360, 1, 0, D.t().border)
end
