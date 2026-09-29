--[[
    NovaUI - Component Registration & Factory API
    Supports:
      NovaUI.create("window", props, parent)
      NovaUI.window(props, parent)
      parent:create("button", props)
    File: client/core/factory.lua
]]

NovaUI = NovaUI or {}

function NovaUI.registerComponent(typeName, componentClass, aliases)
    if type(typeName) ~= "string" or type(componentClass) ~= "table" then
        return NovaUI.warn("NovaUI.registerComponent", "Invalid component typeName or class")
    end
    local key = typeName:lower()
    NovaUI._registry.componentClasses[key] = componentClass

    -- Create shorthand constructor NovaUI[typeName](props, parent) if not colliding with core methods
    if NovaUI[typeName] == nil then
        NovaUI[typeName] = function(props, parent)
            return NovaUI.create(key, props, parent)
        end
    end
    if NovaUI[key] == nil then
        NovaUI[key] = function(props, parent)
            return NovaUI.create(key, props, parent)
        end
    end

    if type(aliases) == "table" then
        for i = 1, #aliases do
            local alias = tostring(aliases[i]):lower()
            NovaUI._registry.componentClasses[alias] = componentClass
            if NovaUI[aliases[i]] == nil then
                NovaUI[aliases[i]] = function(props, parent)
                    return NovaUI.create(key, props, parent)
                end
            end
        end
    end
    return componentClass
end

function NovaUI.create(typeName, props, parent)
    if type(typeName) ~= "string" or typeName == "" then
        return NovaUI.warn("NovaUI.create", "Component type must be a non-empty string")
    end
    local key = typeName:lower()
    local cls = NovaUI._registry.componentClasses[key]
    if not cls then
        return NovaUI.warn("NovaUI.create", "Unknown component type '%s'", tostring(typeName))
    end
    if props ~= nil and type(props) ~= "table" then
        NovaUI.warn("NovaUI.create('" .. key .. "')", "props should be a table, received %s", type(props))
        props = {}
    end
    return cls.new(key, props or {}, parent)
end

function NovaUI.getElementById(id)
    return NovaUI._registry.components[id]
end

function NovaUI.destroyAll()
    for id, comp in pairs(NovaUI._registry.components) do
        if comp and not comp._destroyed then
            comp:destroy()
        end
        NovaUI._registry.components[id] = nil
    end
    NovaUI._registry.rootElements = {}
    NovaUI._registry.modals = {}
    NovaUI._registry.notifications = {}
    NovaUI.Animation.active = {}
end
