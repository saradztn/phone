--[[
    NovaUI - Font Manager
    Handles loading, caching, multi-size scaling, Arabic/Latin families, and fallback fonts
    Never allocates fonts inside per-frame render loops.
    File: client/fonts/manager.lua
]]

NovaUI = NovaUI or {}
NovaUI.Fonts = {
    cache = {},
    paths = {
        sans = {
            regular = "assets/fonts/NotoSans-Regular.ttf",
            bold    = "assets/fonts/NotoSans-Bold.ttf",
        },
        arabic = {
            regular = "assets/fonts/NotoSansArabic-Regular.ttf",
            bold    = "assets/fonts/NotoSansArabic-Bold.ttf",
        },
    },
    fallbackRegular = "default",
    fallbackBold    = "default-bold",
}

local Fonts = NovaUI.Fonts

local function _resolveSizeToken(sizeOrToken)
    if type(sizeOrToken) == "number" then
        return NovaUI.scaleFont(sizeOrToken)
    elseif type(sizeOrToken) == "string" then
        local tokenPt = NovaUI.Tokens.fontSize[sizeOrToken] or NovaUI.Tokens.fontSize.md
        return NovaUI.scaleFont(tokenPt)
    end
    return NovaUI.scaleFont(NovaUI.Tokens.fontSize.md or 13)
end

function Fonts.get(sizeOrToken, weight, family)
    weight = (weight == "bold" or weight == "semibold") and "bold" or "regular"
    family = family or NovaUI.Config.defaultFontFamily or "sans"
    local scaledPt = _resolveSizeToken(sizeOrToken)

    local cacheKey = string.format("%s_%s_%d", tostring(family), tostring(weight), scaledPt)
    local cached = Fonts.cache[cacheKey]
    if cached then
        if type(cached) == "string" or (type(isElement) == "function" and isElement(cached)) then
            return cached, 1.0
        else
            Fonts.cache[cacheKey] = nil
        end
    end

    local familyPaths = Fonts.paths[family] or Fonts.paths.sans
    local fontPath = familyPaths and familyPaths[weight] or Fonts.paths.sans.regular
    local createdFont = nil

    if type(fileExists) ~= "function" or fileExists(fontPath) then
        if NovaUI.DGSAdapter and NovaUI.DGSAdapter.isAvailable() then
            createdFont = NovaUI.DGSAdapter.call("dgsCreateFont", fontPath, scaledPt, weight == "bold", "proof")
        end
        if not createdFont and type(dxCreateFont) == "function" then
            local ok, f = pcall(dxCreateFont, fontPath, scaledPt, weight == "bold", "proof")
            if ok and f then
                createdFont = f
            end
        end
    end

    if not createdFont then
        local fallback = weight == "bold" and Fonts.fallbackBold or Fonts.fallbackRegular
        Fonts.cache[cacheKey] = fallback
        return fallback, scaledPt / 12.0
    end

    Fonts.cache[cacheKey] = createdFont
    return createdFont, 1.0
end

function Fonts.getTextWidth(text, sizeOrToken, weight, family, colorCoded)
    text = tostring(text or "")
    if text == "" then return 0 end
    local font, scale = Fonts.get(sizeOrToken, weight, family)
    if type(dxGetTextWidth) == "function" then
        local ok, w = pcall(dxGetTextWidth, text, scale or 1.0, font, colorCoded or false)
        if ok and type(w) == "number" then
            return w
        end
    end
    local pt = _resolveSizeToken(sizeOrToken)
    return NovaUI.Utils.utf8Len(text) * (pt * 0.56)
end

function Fonts.getFontHeight(sizeOrToken, weight, family)
    local font, scale = Fonts.get(sizeOrToken, weight, family)
    if type(dxGetFontHeight) == "function" then
        local ok, h = pcall(dxGetFontHeight, scale or 1.0, font)
        if ok and type(h) == "number" then
            return h
        end
    end
    local pt = _resolveSizeToken(sizeOrToken)
    return math.floor(pt * 1.35)
end

function Fonts.unloadAll()
    for k, font in pairs(Fonts.cache) do
        if type(font) ~= "string" and type(isElement) == "function" and isElement(font) then
            destroyElement(font)
        end
        Fonts.cache[k] = nil
    end
end
