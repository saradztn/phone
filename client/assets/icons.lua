--[[
    NovaUI - Unified Vector / SVG & Procedural Icon Engine
    Renders crisp scalable vector icons via cached SVG or DirectX vector geometry
    File: client/assets/icons.lua
]]

NovaUI = NovaUI or {}
NovaUI.Icons = {}

local Icons = NovaUI.Icons
local Utils = NovaUI.Utils
local mathFloor = math.floor
local mathCos = math.cos
local mathSin = math.sin
local mathPi = math.pi

-- SVG Path definitions for 48 standard UI icons (24x24 viewBox)
Icons.definitions = {
    ["search"]        = '<circle cx="11" cy="11" r="7" stroke="white" stroke-width="2.2" fill="none"/><line x1="16.5" y1="16.5" x2="21" y2="21" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["close"]         = '<line x1="6" y1="6" x2="18" y2="18" stroke="white" stroke-width="2.2" stroke-linecap="round"/><line x1="18" y1="6" x2="6" y2="18" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["check"]         = '<polyline points="5 12.5 10 17.5 19 6.5" stroke="white" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    ["plus"]          = '<line x1="12" y1="5" x2="12" y2="19" stroke="white" stroke-width="2.2" stroke-linecap="round"/><line x1="5" y1="12" x2="19" y2="12" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["minus"]         = '<line x1="5" y1="12" x2="19" y2="12" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["chevron-down"]  = '<polyline points="6 9 12 15 18 9" stroke="white" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    ["chevron-up"]    = '<polyline points="18 15 12 9 6 15" stroke="white" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    ["chevron-left"]  = '<polyline points="15 18 9 12 15 6" stroke="white" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    ["chevron-right"] = '<polyline points="9 18 15 12 9 6" stroke="white" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    ["home"]          = '<path d="M3 10.5L12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1v-9.5z" stroke="white" stroke-width="2" fill="none" stroke-linejoin="round"/>',
    ["dashboard"]     = '<rect x="3" y="3" width="8" height="8" rx="2" stroke="white" stroke-width="2" fill="none"/><rect x="13" y="3" width="8" height="5" rx="2" stroke="white" stroke-width="2" fill="none"/><rect x="13" y="10" width="8" height="11" rx="2" stroke="white" stroke-width="2" fill="none"/><rect x="3" y="13" width="8" height="8" rx="2" stroke="white" stroke-width="2" fill="none"/>',
    ["settings"]      = '<circle cx="12" cy="12" r="3.5" stroke="white" stroke-width="2" fill="none"/><path d="M12 2v3M12 19v3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1l2.1-2.1M17 7l2.1-2.1" stroke="white" stroke-width="2" stroke-linecap="round"/>',
    ["user"]          = '<circle cx="12" cy="8" r="4" stroke="white" stroke-width="2" fill="none"/><path d="M4 20c1.5-4 14.5-4 16 0" stroke="white" stroke-width="2" fill="none" stroke-linecap="round"/>',
    ["users"]         = '<circle cx="9" cy="8" r="3.5" stroke="white" stroke-width="2" fill="none"/><path d="M2.5 19.5c1.2-3.5 11.8-3.5 13 0" stroke="white" stroke-width="2" fill="none" stroke-linecap="round"/><circle cx="17" cy="9" r="2.5" stroke="white" stroke-width="1.8" fill="none"/><path d="M15.5 19.5c1-2.5 5-2.5 6 0" stroke="white" stroke-width="1.8" fill="none" stroke-linecap="round"/>',
    ["bell"]          = '<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" stroke="white" stroke-width="2" fill="none"/><path d="M13.73 21a2 2 0 0 1-3.46 0" stroke="white" stroke-width="2" stroke-linecap="round"/>',
    ["info"]          = '<circle cx="12" cy="12" r="9" stroke="white" stroke-width="2" fill="none"/><line x1="12" y1="11" x2="12" y2="16" stroke="white" stroke-width="2.2" stroke-linecap="round"/><circle cx="12" cy="7.5" r="1.2" fill="white"/>',
    ["warning"]       = '<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" stroke="white" stroke-width="2" fill="none"/><line x1="12" y1="9" x2="12" y2="13" stroke="white" stroke-width="2.2" stroke-linecap="round"/><circle cx="12" cy="17" r="1.2" fill="white"/>',
    ["error"]         = '<circle cx="12" cy="12" r="9" stroke="white" stroke-width="2" fill="none"/><line x1="15" y1="9" x2="9" y2="15" stroke="white" stroke-width="2.2" stroke-linecap="round"/><line x1="9" y1="9" x2="15" y2="15" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["success"]       = '<circle cx="12" cy="12" r="9" stroke="white" stroke-width="2" fill="none"/><polyline points="8 12.5 11 15.5 16 9.5" stroke="white" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    ["lock"]          = '<rect x="5" y="11" width="14" height="10" rx="2" stroke="white" stroke-width="2" fill="none"/><path d="M8 11V7a4 4 0 0 1 8 0v4" stroke="white" stroke-width="2" fill="none"/>',
    ["unlock"]        = '<rect x="5" y="11" width="14" height="10" rx="2" stroke="white" stroke-width="2" fill="none"/><path d="M8 11V7a4 4 0 0 1 7.5-1.5" stroke="white" stroke-width="2" fill="none" stroke-linecap="round"/>',
    ["eye"]           = '<path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6-10-6-10-6z" stroke="white" stroke-width="2" fill="none"/><circle cx="12" cy="12" r="3" stroke="white" stroke-width="2" fill="none"/>',
    ["eye-off"]       = '<path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6-10-6-10-6z" stroke="white" stroke-width="2" fill="none"/><line x1="4" y1="4" x2="20" y2="20" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["edit"]          = '<path d="M12 20h9" stroke="white" stroke-width="2" stroke-linecap="round"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z" stroke="white" stroke-width="2" fill="none" stroke-linejoin="round"/>',
    ["trash"]         = '<polyline points="3 6 5 6 21 6" stroke="white" stroke-width="2" stroke-linecap="round"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6m5 0V4a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v2" stroke="white" stroke-width="2" fill="none"/>',
    ["copy"]          = '<rect x="9" y="9" width="11" height="11" rx="2" stroke="white" stroke-width="2" fill="none"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" stroke="white" stroke-width="2" fill="none"/>',
    ["refresh"]       = '<path d="M21 12a9 9 0 1 1-2.64-6.36" stroke="white" stroke-width="2" fill="none" stroke-linecap="round"/><polyline points="21 3 21 9 15 9" stroke="white" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    ["filter"]        = '<polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" stroke="white" stroke-width="2" fill="none" stroke-linejoin="round"/>',
    ["sort"]          = '<line x1="4" y1="6" x2="13" y2="6" stroke="white" stroke-width="2" stroke-linecap="round"/><line x1="4" y1="12" x2="11" y2="12" stroke="white" stroke-width="2" stroke-linecap="round"/><line x1="4" y1="18" x2="9" y2="18" stroke="white" stroke-width="2" stroke-linecap="round"/><polyline points="15 15 18 18 21 15" stroke="white" stroke-width="2" fill="none" stroke-linecap="round"/><line x1="18" y1="6" x2="18" y2="18" stroke="white" stroke-width="2" stroke-linecap="round"/>',
    ["star"]          = '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" stroke="white" stroke-width="2" fill="none" stroke-linejoin="round"/>',
    ["heart"]         = '<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78L12 21.23l8.84-8.84a5.5 5.5 0 0 0 0-7.78z" stroke="white" stroke-width="2" fill="none"/>',
    ["shield"]        = '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" stroke="white" stroke-width="2" fill="none" stroke-linejoin="round"/>',
    ["terminal"]      = '<polyline points="4 17 10 11 4 5" stroke="white" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/><line x1="12" y1="19" x2="20" y2="19" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["chart"]         = '<line x1="18" y1="20" x2="18" y2="10" stroke="white" stroke-width="2.4" stroke-linecap="round"/><line x1="12" y1="20" x2="12" y2="4" stroke="white" stroke-width="2.4" stroke-linecap="round"/><line x1="6" y1="20" x2="6" y2="14" stroke="white" stroke-width="2.4" stroke-linecap="round"/>',
    ["folder"]        = '<path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z" stroke="white" stroke-width="2" fill="none" stroke-linejoin="round"/>',
    ["file"]          = '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" stroke="white" stroke-width="2" fill="none" stroke-linejoin="round"/><polyline points="14 2 14 8 20 8" stroke="white" stroke-width="2" fill="none"/>',
    ["key"]           = '<circle cx="7.5" cy="15.5" r="4.5" stroke="white" stroke-width="2" fill="none"/><path d="M10.7 12.3L21 2m-3 3l3 3m-6 1l2 2" stroke="white" stroke-width="2" stroke-linecap="round"/>',
    ["sliders"]       = '<line x1="4" y1="21" x2="4" y2="14" stroke="white" stroke-width="2" stroke-linecap="round"/><line x1="4" y1="10" x2="4" y2="3" stroke="white" stroke-width="2" stroke-linecap="round"/><line x1="12" y1="21" x2="12" y2="12" stroke="white" stroke-width="2" stroke-linecap="round"/><line x1="12" y1="8" x2="12" y2="3" stroke="white" stroke-width="2" stroke-linecap="round"/><line x1="20" y1="21" x2="20" y2="16" stroke="white" stroke-width="2" stroke-linecap="round"/><line x1="20" y1="12" x2="20" y2="3" stroke="white" stroke-width="2" stroke-linecap="round"/><circle cx="4" cy="12" r="2" stroke="white" stroke-width="2" fill="none"/><circle cx="12" cy="10" r="2" stroke="white" stroke-width="2" fill="none"/><circle cx="20" cy="14" r="2" stroke="white" stroke-width="2" fill="none"/>',
    ["power"]         = '<path d="M18.36 6.64a9 9 0 1 1-12.73 0" stroke="white" stroke-width="2.2" fill="none" stroke-linecap="round"/><line x1="12" y1="2" x2="12" y2="12" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["play"]          = '<polygon points="6 4 20 12 6 20 6 4" stroke="white" stroke-width="2" fill="white" stroke-linejoin="round"/>',
    ["pause"]         = '<rect x="6" y="4" width="4" height="16" rx="1" fill="white"/><rect x="14" y="4" width="4" height="16" rx="1" fill="white"/>',
    ["clock"]         = '<circle cx="12" cy="12" r="9" stroke="white" stroke-width="2" fill="none"/><polyline points="12 7 12 12 15.5 14" stroke="white" stroke-width="2" fill="none" stroke-linecap="round"/>',
    ["globe"]         = '<circle cx="12" cy="12" r="9" stroke="white" stroke-width="2" fill="none"/><line x1="3" y1="12" x2="21" y2="12" stroke="white" stroke-width="1.8"/><path d="M12 3a14 14 0 0 1 0 18a14 14 0 0 1 0-18" stroke="white" stroke-width="1.8" fill="none"/>',
    ["sparkle"]       = '<path d="M12 2L14.5 9.5L22 12L14.5 14.5L12 22L9.5 14.5L2 12L9.5 9.5L12 2Z" stroke="white" stroke-width="2" fill="none" stroke-linejoin="round"/>',
    ["menu"]          = '<line x1="4" y1="7" x2="20" y2="7" stroke="white" stroke-width="2.2" stroke-linecap="round"/><line x1="4" y1="12" x2="20" y2="12" stroke="white" stroke-width="2.2" stroke-linecap="round"/><line x1="4" y1="17" x2="20" y2="17" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["more"]          = '<circle cx="6" cy="12" r="1.8" fill="white"/><circle cx="12" cy="12" r="1.8" fill="white"/><circle cx="18" cy="12" r="1.8" fill="white"/>',
    ["minimize"]      = '<line x1="6" y1="12" x2="18" y2="12" stroke="white" stroke-width="2.2" stroke-linecap="round"/>',
    ["maximize"]      = '<rect x="5" y="5" width="14" height="14" rx="2" stroke="white" stroke-width="2" fill="none"/>',
}

function Icons.exists(name)
    return Icons.definitions[tostring(name or ""):lower()] ~= nil
end

function Icons.getList()
    local list = {}
    for k in pairs(Icons.definitions) do
        table.insert(list, k)
    end
    table.sort(list)
    return list
end

-- Draw an icon at (x, y, size, color) using cached SVG or procedural DX fallback
function Icons.draw(name, x, y, size, color, rotation, postGUI)
    name = tostring(name or "info"):lower()
    size = mathFloor(tonumber(size) or NovaUI.scale(18))
    local col = Utils.toColor(color or NovaUI.Theme.text)
    local def = Icons.definitions[name] or Icons.definitions["info"]

    -- 1. Try cached SVG texture if MTA's svgCreate is available
    local svgXml = string.format('<svg viewBox="0 0 24 24" width="%d" height="%d" xmlns="http://www.w3.org/2000/svg">%s</svg>', size, size, def)
    local svgTex = NovaUI.Assets.getSVG("icon_" .. name, size, size, svgXml)
    if svgTex and type(dxDrawImage) == "function" then
        dxDrawImage(x, y, size, size, svgTex, rotation or 0, 0, 0, col, postGUI or false)
        return true
    end

    -- 2. Procedural DX vector fallback so icons always render crisply even without SVG
    if type(dxDrawLine) ~= "function" then return false end
    local cx, cy = x + size * 0.5, y + size * 0.5
    local r = size * 0.35
    local stroke = math.max(1.5, size * 0.1)

    if name == "close" or name == "error" then
        dxDrawLine(cx - r * 0.7, cy - r * 0.7, cx + r * 0.7, cy + r * 0.7, col, stroke, postGUI)
        dxDrawLine(cx + r * 0.7, cy - r * 0.7, cx - r * 0.7, cy + r * 0.7, col, stroke, postGUI)
    elseif name == "check" or name == "success" then
        dxDrawLine(cx - r * 0.75, cy, cx - r * 0.15, cy + r * 0.6, col, stroke, postGUI)
        dxDrawLine(cx - r * 0.15, cy + r * 0.6, cx + r * 0.8, cy - r * 0.55, col, stroke, postGUI)
    elseif name == "plus" then
        dxDrawLine(cx - r * 0.75, cy, cx + r * 0.75, cy, col, stroke, postGUI)
        dxDrawLine(cx, cy - r * 0.75, cx, cy + r * 0.75, col, stroke, postGUI)
    elseif name == "minus" or name == "minimize" then
        dxDrawLine(cx - r * 0.75, cy, cx + r * 0.75, cy, col, stroke, postGUI)
    elseif name == "chevron-down" then
        dxDrawLine(cx - r * 0.65, cy - r * 0.25, cx, cy + r * 0.4, col, stroke, postGUI)
        dxDrawLine(cx, cy + r * 0.4, cx + r * 0.65, cy - r * 0.25, col, stroke, postGUI)
    elseif name == "chevron-up" then
        dxDrawLine(cx - r * 0.65, cy + r * 0.25, cx, cy - r * 0.4, col, stroke, postGUI)
        dxDrawLine(cx, cy - r * 0.4, cx + r * 0.65, cy + r * 0.25, col, stroke, postGUI)
    elseif name == "chevron-left" then
        dxDrawLine(cx + r * 0.25, cy - r * 0.65, cx - r * 0.4, cy, col, stroke, postGUI)
        dxDrawLine(cx - r * 0.4, cy, cx + r * 0.25, cy + r * 0.65, col, stroke, postGUI)
    elseif name == "chevron-right" then
        dxDrawLine(cx - r * 0.25, cy - r * 0.65, cx + r * 0.4, cy, col, stroke, postGUI)
        dxDrawLine(cx + r * 0.4, cy, cx - r * 0.25, cy + r * 0.65, col, stroke, postGUI)
    elseif name == "search" then
        local segs = 12
        local cr = r * 0.65
        local ox, oy = cx - r * 0.15, cy - r * 0.15
        for i = 1, segs do
            local a1 = ((i - 1) / segs) * mathPi * 2
            local a2 = (i / segs) * mathPi * 2
            dxDrawLine(ox + mathCos(a1) * cr, oy + mathSin(a1) * cr, ox + mathCos(a2) * cr, oy + mathSin(a2) * cr, col, stroke, postGUI)
        end
        dxDrawLine(ox + cr * 0.7, oy + cr * 0.7, cx + r * 0.85, cy + r * 0.85, col, stroke, postGUI)
    elseif name == "menu" then
        dxDrawLine(cx - r * 0.8, cy - r * 0.55, cx + r * 0.8, cy - r * 0.55, col, stroke, postGUI)
        dxDrawLine(cx - r * 0.8, cy, cx + r * 0.8, cy, col, stroke, postGUI)
        dxDrawLine(cx - r * 0.8, cy + r * 0.55, cx + r * 0.8, cy + r * 0.55, col, stroke, postGUI)
    else
        -- Default geometric diamond/circle emblem
        local segs = 8
        for i = 1, segs do
            local a1 = ((i - 1) / segs) * mathPi * 2
            local a2 = (i / segs) * mathPi * 2
            dxDrawLine(cx + mathCos(a1) * r, cy + mathSin(a1) * r, cx + mathCos(a2) * r, cy + mathSin(a2) * r, col, stroke, postGUI)
        end
    end
    return true
end
