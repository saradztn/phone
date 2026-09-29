--[[
    NovaUI - Resource Bootstrap, Exports & Memory Cleanup Lifecycle
    File: client/core/bootstrap.lua
]]

NovaUI = NovaUI or {}

function NovaUI.shutdown()
    -- 1. Destroy all components
    NovaUI.destroyAll()

    -- 2. Kill all tracked timers
    if NovaUI._registry and NovaUI._registry.timers then
        for timer in pairs(NovaUI._registry.timers) do
            NovaUI.killTimer(timer)
        end
        NovaUI._registry.timers = {}
    end

    -- 3. Unload cached textures & SVGs
    if NovaUI.Assets and NovaUI.Assets.unloadAll then
        NovaUI.Assets.unloadAll()
    end

    -- 4. Unload cached fonts
    if NovaUI.Fonts and NovaUI.Fonts.unloadAll then
        NovaUI.Fonts.unloadAll()
    end

    -- 5. Clean up DGS Adapter caches
    if NovaUI.DGSAdapter and NovaUI.DGSAdapter.cleanup then
        NovaUI.DGSAdapter.cleanup()
    end

    -- 6. Restore input mode
    if type(guiSetInputMode) == "function" then
        pcall(guiSetInputMode, "allow_binds")
    end
end

-- Exported global functions for cross-resource MTA:SA usage
function novaCreate(typeName, props, parentId)
    local parent = parentId and NovaUI.getElementById(parentId) or nil
    local comp = NovaUI.create(typeName, props, parent)
    return comp and comp.id or false
end

function novaDestroy(elementOrId)
    local comp = type(elementOrId) == "table" and elementOrId or NovaUI.getElementById(elementOrId)
    if comp and type(comp.destroy) == "function" then
        return comp:destroy()
    end
    return false
end

function novaSetTheme(themeName)
    return NovaUI.setTheme(themeName)
end

function novaCreateTheme(name, definition, baseTheme)
    return NovaUI.createTheme(name, definition, baseTheme) ~= nil
end

function novaScale(val)
    return NovaUI.scale(val)
end

function novaNotify(options)
    local n = NovaUI.notify(options)
    return n and n.id or false
end

function novaConfirm(options)
    local m = NovaUI.confirm(options)
    return m and m.id or false
end

function novaSetVisible(elementId, visible)
    local comp = NovaUI.getElementById(elementId)
    if comp then
        comp:setVisible(visible)
        return true
    end
    return false
end

if type(addEventHandler) == "function" and type(resourceRoot) ~= "nil" then
    addEventHandler("onClientResourceStop", resourceRoot, function()
        NovaUI.shutdown()
    end)
end
