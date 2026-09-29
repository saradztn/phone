--[[
    NovaUI - Lightweight OOP Class System
    File: client/core/class.lua
]]

NovaUI = NovaUI or {}

function NovaUI.Class(name, super)
    local cls = {}
    cls.__name = name or "NovaClass"
    cls.__index = cls
    cls.super = super

    if super then
        setmetatable(cls, {
            __index = super,
            __call = function(c, ...)
                return c.new(...)
            end
        })
    else
        setmetatable(cls, {
            __call = function(c, ...)
                return c.new(...)
            end
        })
    end

    function cls.new(...)
        local instance = setmetatable({}, cls)
        if instance.init then
            instance:init(...)
        end
        return instance
    end

    function cls:isInstanceOf(targetClass)
        local mt = getmetatable(self)
        while mt do
            if mt == targetClass then
                return true
            end
            mt = mt.super
        end
        return false
    end

    return cls
end
