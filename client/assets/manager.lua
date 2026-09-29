--[[
    NovaUI - Texture & Asset Manager
    Handles texture loading, caching, reference counting, preloading, and safe fallbacks
    File: client/assets/manager.lua
]]

NovaUI = NovaUI or {}
NovaUI.Assets = {
    cache = {},       -- path -> { texture, refs, lastUsed, isFallback }
    svgCache = {},    -- key -> svgElement
    fallbackPath = "assets/images/fallback.png",
    fallbackTexture = nil,
}

local Assets = NovaUI.Assets

local function _fileExistsSafe(path)
    if type(path) ~= "string" or path == "" then return false end
    if type(fileExists) == "function" then
        return fileExists(path)
    end
    return true
end

local function _ensureFallbackTexture()
    if Assets.fallbackTexture and (type(isElement) ~= "function" or isElement(Assets.fallbackTexture)) then
        return Assets.fallbackTexture
    end
    if type(dxCreateTexture) == "function" then
        if _fileExistsSafe(Assets.fallbackPath) then
            local ok, tex = pcall(dxCreateTexture, Assets.fallbackPath, "argb", true, "clamp")
            if ok and tex then
                Assets.fallbackTexture = tex
                return tex
            end
        end
        -- Procedural 2x2 fallback pixel texture if file is unavailable
        local ok, tex = pcall(dxCreateTexture, 2, 2)
        if ok and tex then
            Assets.fallbackTexture = tex
            return tex
        end
    end
    return nil
end

function Assets.getTexture(path, mipmaps, edgeMode)
    if type(path) ~= "string" or path == "" then
        NovaUI.warn("NovaUI.Assets.getTexture", "Empty or invalid asset path '%s', using fallback", tostring(path))
        return _ensureFallbackTexture(), true
    end

    local entry = Assets.cache[path]
    if entry and entry.texture then
        if type(isElement) ~= "function" or isElement(entry.texture) then
            entry.refs = (entry.refs or 0) + 1
            entry.lastUsed = type(getTickCount) == "function" and getTickCount() or 0
            return entry.texture, entry.isFallback
        else
            Assets.cache[path] = nil
        end
    end

    if not _fileExistsSafe(path) then
        NovaUI.warn("NovaUI.Assets.getTexture", "Missing asset file '%s', using fallback", path)
        local fb = _ensureFallbackTexture()
        Assets.cache[path] = {
            texture = fb,
            refs = 1,
            lastUsed = type(getTickCount) == "function" and getTickCount() or 0,
            isFallback = true,
        }
        return fb, true
    end

    local tex = nil
    if type(dxCreateTexture) == "function" then
        local ok, created = pcall(dxCreateTexture, path, "argb", mipmaps ~= false, edgeMode or "clamp")
        if ok and created then
            tex = created
        end
    end

    if not tex then
        NovaUI.warn("NovaUI.Assets.getTexture", "Failed to load texture '%s', using fallback", path)
        local fb = _ensureFallbackTexture()
        Assets.cache[path] = {
            texture = fb,
            refs = 1,
            lastUsed = type(getTickCount) == "function" and getTickCount() or 0,
            isFallback = true,
        }
        return fb, true
    end

    Assets.cache[path] = {
        texture = tex,
        refs = 1,
        lastUsed = type(getTickCount) == "function" and getTickCount() or 0,
        isFallback = false,
    }
    return tex, false
end

function Assets.releaseTexture(path)
    if type(path) ~= "string" then return false end
    local entry = Assets.cache[path]
    if not entry then return false end
    entry.refs = math.max(0, (entry.refs or 1) - 1)
    if entry.refs == 0 and not entry.isFallback and not entry.pinned then
        if entry.texture and type(isElement) == "function" and isElement(entry.texture) then
            destroyElement(entry.texture)
        end
        Assets.cache[path] = nil
        return true
    end
    return false
end

function Assets.preload(paths)
    if type(paths) ~= "table" then
        return NovaUI.warn("NovaUI.Assets.preload", "paths must be a table of strings")
    end
    local loaded = 0
    for i = 1, #paths do
        local p = paths[i]
        if type(p) == "string" then
            local tex, isFallback = Assets.getTexture(p)
            if tex and not isFallback then
                Assets.cache[p].pinned = true
                loaded = loaded + 1
            end
        end
    end
    return loaded
end

function Assets.getSVG(key, width, height, xmlString)
    if type(key) ~= "string" then return nil end
    local cacheKey = string.format("%s_%d_%d", key, math.floor(width or 24), math.floor(height or 24))
    local existing = Assets.svgCache[cacheKey]
    if existing and (type(isElement) ~= "function" or isElement(existing)) then
        return existing
    end
    if type(svgCreate) == "function" and type(xmlString) == "string" then
        local ok, svg = pcall(svgCreate, math.max(4, math.floor(width)), math.max(4, math.floor(height)), xmlString)
        if ok and svg then
            Assets.svgCache[cacheKey] = svg
            return svg
        end
    end
    return nil
end

function Assets.unloadAll()
    for path, entry in pairs(Assets.cache) do
        if entry.texture and not entry.isFallback and type(isElement) == "function" and isElement(entry.texture) then
            destroyElement(entry.texture)
        end
        Assets.cache[path] = nil
    end
    for key, svg in pairs(Assets.svgCache) do
        if svg and type(isElement) == "function" and isElement(svg) then
            destroyElement(svg)
        end
        Assets.svgCache[key] = nil
    end
    if Assets.fallbackTexture and type(isElement) == "function" and isElement(Assets.fallbackTexture) then
        destroyElement(Assets.fallbackTexture)
        Assets.fallbackTexture = nil
    end
end
