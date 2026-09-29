--[[
    NovaUI - Reactive Theme Engine
    File: client/theme/manager.lua
]]

NovaUI = NovaUI or {}
NovaUI.ThemeManager = {
    currentName = NovaUI.Config.defaultTheme or "midnight",
    themes = {},
    listeners = {},
}

-- Active theme table exposed as NovaUI.Theme
NovaUI.Theme = {}

local Utils = NovaUI.Utils
local ThemeManager = NovaUI.ThemeManager

-- Normalize color values inside a theme definition to {r, g, b, a}
local function _normalizeThemeTable(raw, fallback)
    local result = Utils.deepCopy(fallback or NovaUI.Palettes.dark)
    if type(raw) == "table" then
        for k, v in pairs(raw) do
            if type(v) == "string" and v:sub(1, 1) == "#" then
                local r, g, b, a = Utils.unpackColor(v)
                result[k] = { r, g, b, a }
            elseif type(v) == "table" and (#v == 3 or #v == 4) and type(v[1]) == "number" then
                result[k] = { v[1], v[2], v[3], v[4] or 255 }
            else
                result[k] = Utils.deepCopy(v)
            end
        end
    end
    -- Attach centralized tokens directly onto NovaUI.Theme for convenience
    result.tokens = NovaUI.Tokens
    result.spacing = NovaUI.Tokens.spacing
    result.radius = NovaUI.Tokens.radius
    result.fontSize = NovaUI.Tokens.fontSize
    result.fontWeight = NovaUI.Tokens.fontWeight
    result.shadows = NovaUI.Tokens.shadows
    result.borderTokens = NovaUI.Tokens.border
    result.opacity = NovaUI.Tokens.opacity
    result.animation = NovaUI.Tokens.animation
    result.zIndex = NovaUI.Tokens.zIndex
    return result
end

-- Initialize built-in palettes
for name, palette in pairs(NovaUI.Palettes) do
    ThemeManager.themes[name] = _normalizeThemeTable(palette, NovaUI.Palettes.dark)
end

local function _applyThemeToGlobal(themeObj)
    for k in pairs(NovaUI.Theme) do
        NovaUI.Theme[k] = nil
    end
    for k, v in pairs(themeObj) do
        NovaUI.Theme[k] = v
    end
end

-- Apply default theme immediately
_applyThemeToGlobal(ThemeManager.themes[ThemeManager.currentName] or ThemeManager.themes.midnight)

function NovaUI.createTheme(name, definition, baseThemeName)
    if type(name) ~= "string" or name == "" then
        return NovaUI.warn("NovaUI.createTheme", "Theme name must be a non-empty string")
    end
    if type(definition) ~= "table" then
        return NovaUI.warn("NovaUI.createTheme('" .. name .. "')", "Theme definition must be a table")
    end
    local base = ThemeManager.themes[baseThemeName or "dark"] or NovaUI.Palettes.dark
    local normalized = _normalizeThemeTable(definition, base)
    normalized.name = name
    normalized.label = definition.label or name
    ThemeManager.themes[name] = normalized

    if ThemeManager.currentName == name then
        NovaUI.setTheme(name)
    end
    return normalized
end

function NovaUI.setTheme(name)
    if type(name) ~= "string" or not ThemeManager.themes[name] then
        return NovaUI.warn("NovaUI.setTheme", "Unknown theme '%s'", tostring(name))
    end
    local themeObj = ThemeManager.themes[name]
    ThemeManager.currentName = name
    _applyThemeToGlobal(themeObj)

    -- Notify all active components so they update colors/styles dynamically
    for _, comp in pairs(NovaUI._registry.components) do
        if comp and not comp._destroyed then
            comp._dirty = true
            if type(comp.onThemeChange) == "function" then
                pcall(comp.onThemeChange, comp, themeObj)
            end
            comp:emit("themeChange", themeObj)
        end
    end

    -- Notify global theme listeners
    for i = 1, #ThemeManager.listeners do
        pcall(ThemeManager.listeners[i], name, themeObj)
    end

    if NovaUI.Renderer and NovaUI.Renderer.markDirty then
        NovaUI.Renderer.markDirty()
    end
    return true
end

function NovaUI.getTheme(name)
    if name then
        return ThemeManager.themes[name]
    end
    return NovaUI.Theme
end

function NovaUI.getThemeName()
    return ThemeManager.currentName
end

function NovaUI.getThemes()
    local names = {}
    for k in pairs(ThemeManager.themes) do
        table.insert(names, k)
    end
    table.sort(names)
    return names
end

function NovaUI.onThemeChange(callback)
    if type(callback) == "function" then
        table.insert(ThemeManager.listeners, callback)
        return true
    end
    return false
end
