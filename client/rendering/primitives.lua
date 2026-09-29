--[[
    NovaUI - High-Performance Drawing Primitives
    Uses cached SVG/DGS Shaders with fast DirectX fallbacks (Zero per-frame allocations)
    File: client/rendering/primitives.lua
]]

NovaUI = NovaUI or {}
NovaUI.Primitives = {}

local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils
local mathFloor = math.floor
local mathMin = math.min
local mathMax = math.max
local mathCos = math.cos
local mathSin = math.sin
local mathRad = math.rad

local dxDrawRectangle = dxDrawRectangle or function() end
local dxDrawImage = dxDrawImage or function() end
local dxDrawText = dxDrawText or function() end
local dxDrawLine = dxDrawLine or function() end

-- Resolve radius token or number
function Primitives.resolveRadius(r, w, h)
    if type(r) == "string" then
        r = NovaUI.Tokens.radius[r] or 8
    end
    r = NovaUI.scale(tonumber(r) or 0)
    local maxR = mathFloor(mathMin(w, h) * 0.5)
    return Utils.clamp(r, 0, maxR)
end

-- Draw soft multi-step elevation shadow
function Primitives.drawShadow(x, y, w, h, radius, shadowToken, alphaMult, postGUI)
    if not NovaUI.Config.enableShadows then return end
    local preset = type(shadowToken) == "table" and shadowToken or (NovaUI.Tokens.shadows[shadowToken or "md"] or NovaUI.Tokens.shadows.md)
    if not preset or (preset.alpha or 0) <= 0 then return end

    alphaMult = tonumber(alphaMult) or 1.0
    local baseAlpha = preset.alpha * alphaMult
    if baseAlpha <= 2 then return end

    local oy = NovaUI.scale(preset.offsetY or 4)
    local layers = 3
    local spread = NovaUI.scale(preset.spread or 2)
    local sr, sg, sb = Utils.unpackColor(NovaUI.Theme.shadow or { 0, 0, 0, 150 })

    for i = 1, layers do
        local expand = mathFloor((spread * i) * 1.35)
        local layerAlpha = mathFloor((baseAlpha / layers) * (1.15 - (i / (layers + 1))))
        if layerAlpha > 1 then
            dxDrawRectangle(
                x - expand,
                y + oy - expand + i,
                w + expand * 2,
                h + expand * 2,
                Utils.toColor({ sr, sg, sb, layerAlpha }),
                postGUI or false
            )
        end
    end
end

-- Draw a rounded rectangle with optional border (cached SVG/DGS shader or fast 3-slice DX)
function Primitives.drawRoundedRect(x, y, w, h, radius, fillColor, borderColor, borderWidth, postGUI)
    if w <= 0 or h <= 0 then return end
    x, y, w, h = mathFloor(x), mathFloor(y), mathFloor(w), mathFloor(h)
    local rad = Primitives.resolveRadius(radius, w, h)
    borderWidth = borderWidth and mathMax(1, NovaUI.scale(borderWidth)) or 0

    -- Fast path for sharp rectangles
    if rad <= 1 then
        if fillColor then
            dxDrawRectangle(x, y, w, h, Utils.toColor(fillColor), postGUI or false)
        end
        if borderColor and borderWidth > 0 then
            Primitives.drawRectBorder(x, y, w, h, borderColor, borderWidth, postGUI)
        end
        return
    end

    -- 1. Try DGS RoundRect shader if DGS Adapter is active
    if NovaUI.DGSAdapter and NovaUI.DGSAdapter.isAvailable() then
        local shader = NovaUI.DGSAdapter.getRoundRectShader(rad, fillColor or { 0, 0, 0, 0 }, borderColor, borderWidth > 0 and (borderWidth / mathMin(w, h)) or nil)
        if shader then
            dxDrawImage(x, y, w, h, shader, 0, 0, 0, -1, postGUI or false)
            return
        end
    end

    -- 2. Fast composite DirectX rounded rectangle (zero per-frame texture allocation)
    if fillColor then
        local col = Utils.toColor(fillColor)
        local cr = mathMin(rad, mathFloor(mathMin(w, h) * 0.25))
        if cr <= 2 then
            dxDrawRectangle(x, y, w, h, col, postGUI or false)
        else
            -- Center body + left/right wings
            dxDrawRectangle(x + cr, y, w - cr * 2, h, col, postGUI or false)
            dxDrawRectangle(x, y + cr, cr, h - cr * 2, col, postGUI or false)
            dxDrawRectangle(x + w - cr, y + cr, cr, h - cr * 2, col, postGUI or false)
            -- Beveled smooth corner steps
            local halfCr = mathFloor(cr * 0.5)
            if halfCr >= 1 then
                dxDrawRectangle(x + halfCr, y + halfCr, cr - halfCr, halfCr, col, postGUI or false)
                dxDrawRectangle(x + w - cr, y + halfCr, cr - halfCr, halfCr, col, postGUI or false)
                dxDrawRectangle(x + halfCr, y + h - cr, cr - halfCr, halfCr, col, postGUI or false)
                dxDrawRectangle(x + w - cr, y + h - cr, cr - halfCr, halfCr, col, postGUI or false)
            end
        end
    end

    if borderColor and borderWidth > 0 then
        Primitives.drawRectBorder(x, y, w, h, borderColor, borderWidth, postGUI)
    end
end

function Primitives.drawRectBorder(x, y, w, h, color, thickness, postGUI)
    thickness = mathMax(1, mathFloor(thickness or 1))
    local col = Utils.toColor(color)
    dxDrawRectangle(x, y, w, thickness, col, postGUI or false)
    dxDrawRectangle(x, y + h - thickness, w, thickness, col, postGUI or false)
    dxDrawRectangle(x, y + thickness, thickness, mathMax(0, h - thickness * 2), col, postGUI or false)
    dxDrawRectangle(x + w - thickness, y + thickness, thickness, mathMax(0, h - thickness * 2), col, postGUI or false)
end

-- Draw glass/frosted panel with subtle top specular highlight
function Primitives.drawGlassPanel(x, y, w, h, radius, tintColor, borderColor, shadowToken, postGUI)
    if shadowToken and shadowToken ~= "none" then
        Primitives.drawShadow(x, y, w, h, radius, shadowToken, 1.0, postGUI)
    end
    Primitives.drawRoundedRect(x, y, w, h, radius, tintColor or NovaUI.Theme.glass, borderColor or NovaUI.Theme.border, 1, postGUI)
    -- Subtle top inner specular line for modern depth
    local inset = mathMax(2, Primitives.resolveRadius(radius, w, h))
    if w > inset * 2 then
        local highlightAlpha = NovaUI.Theme.isDark and 24 or 120
        dxDrawRectangle(x + inset, y + 1, w - inset * 2, 1, Utils.toColor({ 255, 255, 255, highlightAlpha }), postGUI or false)
    end
end

-- Draw circle (cached SVG or multi-segment DX)
function Primitives.drawCircle(cx, cy, radius, fillColor, borderColor, borderWidth, postGUI)
    radius = mathFloor(tonumber(radius) or 8)
    if radius <= 0 then return end
    local d = radius * 2
    local x, y = mathFloor(cx - radius), mathFloor(cy - radius)

    local svgXml = string.format(
        '<svg viewBox="0 0 %d %d" width="%d" height="%d" xmlns="http://www.w3.org/2000/svg"><circle cx="%d" cy="%d" r="%d" fill="white"/></svg>',
        d, d, d, d, radius, radius, radius - 1
    )
    local svgTex = NovaUI.Assets.getSVG("circle", d, d, svgXml)
    if svgTex then
        if borderColor and (borderWidth or 0) > 0 then
            local bw = mathFloor(borderWidth)
            dxDrawImage(x - bw, y - bw, d + bw * 2, d + bw * 2, svgTex, 0, 0, 0, Utils.toColor(borderColor), postGUI or false)
        end
        if fillColor then
            dxDrawImage(x, y, d, d, svgTex, 0, 0, 0, Utils.toColor(fillColor), postGUI or false)
        end
        return
    end

    Primitives.drawRoundedRect(x, y, d, d, radius, fillColor, borderColor, borderWidth, postGUI)
end

-- Draw circular arc (used for Spinner, Circular Progress, and Donut Charts)
function Primitives.drawArc(cx, cy, radius, thickness, startDeg, endDeg, color, postGUI)
    local col = Utils.toColor(color)
    local span = mathMax(0, endDeg - startDeg)
    if span <= 0.5 then return end
    local steps = mathMax(6, mathFloor(span / 8))
    local stepAngle = span / steps
    for i = 0, steps - 1 do
        local a1 = mathRad(startDeg + i * stepAngle - 90)
        local a2 = mathRad(startDeg + (i + 1) * stepAngle - 90)
        local x1, y1 = cx + mathCos(a1) * radius, cy + mathSin(a1) * radius
        local x2, y2 = cx + mathCos(a2) * radius, cy + mathSin(a2) * radius
        dxDrawLine(x1, y1, x2, y2, col, thickness or 2, postGUI or false)
    end
end

-- Draw text using cached fonts from NovaUI.Fonts
function Primitives.drawText(text, x, y, w, h, color, fontSize, fontWeight, alignX, alignY, clip, wordBreak, postGUI, colorCoded)
    text = tostring(text or "")
    if text == "" then return end
    local font, scale = NovaUI.Fonts.get(fontSize or "md", fontWeight or "regular")
    local col = Utils.toColor(color or NovaUI.Theme.text)
    dxDrawText(
        text,
        mathFloor(x),
        mathFloor(y),
        mathFloor(x + (w or 0)),
        mathFloor(y + (h or 0)),
        col,
        scale or 1.0,
        font or "default",
        alignX or "left",
        alignY or "center",
        clip ~= false,
        wordBreak or false,
        postGUI or false,
        colorCoded or false,
        true
    )
end

function Primitives.drawLine(x1, y1, x2, y2, color, width, postGUI)
    dxDrawLine(x1, y1, x2, y2, Utils.toColor(color or NovaUI.Theme.border), width or 1, postGUI or false)
end
