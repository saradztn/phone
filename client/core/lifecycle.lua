--[[
    NovaUI - Base Component Lifecycle Class
    Implements: create -> mount -> update -> render -> destroy
    Guarantees zero memory leaks (cleans up events, animations, textures, timers, DGS proxies, and children)
    File: client/core/lifecycle.lua
]]

NovaUI = NovaUI or {}

local Component = NovaUI.Class("Component", NovaUI.EventEmitter)
NovaUI.Component = Component

local _focusCounter = 1

function Component:init(typeName, props, parent)
    NovaUI.EventEmitter.init(self)

    props = type(props) == "table" and props or {}
    self._isComponent = true
    self._destroyed = false
    self._mounted = false
    self._dirty = true

    local id = NovaUI._registry.nextId
    NovaUI._registry.nextId = id + 1
    self.id = props.id or id
    self.type = tostring(typeName or "component"):lower()

    -- Base unscaled design coordinates (stored so dynamic resolution changes can rescale cleanly)
    self._rawX = tonumber(props.x) or 0
    self._rawY = tonumber(props.y) or 0
    self._rawW = tonumber(props.width or props.w) or 120
    self._rawH = tonumber(props.height or props.h) or 36
    self._autoScale = props.autoScale ~= false

    if self._autoScale then
        self.x = NovaUI.scale(self._rawX)
        self.y = NovaUI.scale(self._rawY)
        self.width = NovaUI.scale(self._rawW)
        self.height = NovaUI.scale(self._rawH)
    else
        self.x = self._rawX
        self.y = self._rawY
        self.width = self._rawW
        self.height = self._rawH
    end

    self._absX = self.x
    self._absY = self.y
    self._animOffsetX = 0
    self._animOffsetY = 0

    self.visible = props.visible ~= false
    self.alpha = tonumber(props.alpha) or 255
    self.zIndex = tonumber(props.zIndex) or NovaUI.Tokens.zIndex.content
    self._focusOrder = _focusCounter
    _focusCounter = _focusCounter + 1

    self.props = NovaUI.Utils.shallowCopy(props)
    self.props.disabled = props.disabled == true or props.enabled == false

    self.state = {
        hovered = false,
        pressed = false,
        focused = false,
        value = props.value,
    }

    self.parent = nil
    self.children = {}
    self._ownedTextures = {}
    self._ownedTimers = {}
    self._dgsElement = nil

    -- Register in global component map
    NovaUI._registry.components[self.id] = self

    -- Attach to parent or root scene graph
    if parent and type(parent) == "table" and parent._isComponent and not parent._destroyed then
        parent:addChild(self)
    elseif not props._detached then
        table.insert(NovaUI._registry.rootElements, self)
        NovaUI.Renderer.markZOrderDirty()
    end

    -- Bind initial event callbacks if passed in props (onClick, onChange, onHover, etc.)
    if type(props.onClick) == "function" then self:on("click", props.onClick) end
    if type(props.onChange) == "function" then self:on("change", props.onChange) end
    if type(props.onHover) == "function" then self:on("hover", props.onHover) end
    if type(props.onFocus) == "function" then self:on("focus", props.onFocus) end
    if type(props.onBlur) == "function" then self:on("blur", props.onBlur) end
    if type(props.onClose) == "function" then self:on("close", props.onClose) end
    if type(props.onSubmit) == "function" then self:on("submit", props.onSubmit) end

    -- Lifecycle: onCreate -> mount
    if type(self.onCreate) == "function" then
        self:onCreate(self.props)
    end
    self:mount()
end

function Component:mount()
    if self._mounted or self._destroyed then return self end
    self._mounted = true
    if type(self.onMount) == "function" then
        self:onMount()
    end
    self:emit("mount", self)
    return self
end

function Component:update(newProps)
    if self._destroyed or type(newProps) ~= "table" then return self end
    for k, v in pairs(newProps) do
        self.props[k] = v
    end
    if newProps.x ~= nil or newProps.y ~= nil then
        self:setPosition(newProps.x or self._rawX, newProps.y or self._rawY)
    end
    if newProps.width ~= nil or newProps.height ~= nil or newProps.w ~= nil or newProps.h ~= nil then
        self:setSize(newProps.width or newProps.w or self._rawW, newProps.height or newProps.h or self._rawH)
    end
    if newProps.visible ~= nil then
        self:setVisible(newProps.visible)
    end
    if newProps.disabled ~= nil then
        self.props.disabled = newProps.disabled and true or false
    end
    if newProps.enabled ~= nil then
        self.props.disabled = not newProps.enabled
    end
    if newProps.alpha ~= nil then
        self:setAlpha(newProps.alpha)
    end
    if newProps.value ~= nil and type(self.setValue) == "function" then
        self:setValue(newProps.value)
    end
    if newProps.text ~= nil and type(self.setText) == "function" then
        self:setText(newProps.text)
    end
    self._dirty = true
    if type(self.onUpdate) == "function" then
        self:onUpdate(newProps)
    end
    self:emit("update", newProps)
    return self
end

-- Create a child component directly inside this component: parent:create("button", { ... })
function Component:create(childType, childProps)
    if self._destroyed then
        return NovaUI.warn("Component:create", "Cannot create child on a destroyed component")
    end
    return NovaUI.create(childType, childProps, self)
end

function Component:addChild(child)
    if self._destroyed or not child or child._destroyed or child == self then
        return self
    end
    -- Remove from previous parent or rootElements
    if child.parent and child.parent ~= self then
        child.parent:removeChild(child)
    else
        for i = #NovaUI._registry.rootElements, 1, -1 do
            if NovaUI._registry.rootElements[i] == child then
                table.remove(NovaUI._registry.rootElements, i)
                break
            end
        end
    end
    child.parent = self
    table.insert(self.children, child)
    self._dirty = true
    if type(self.onChildAdded) == "function" then
        self:onChildAdded(child)
    end
    return self
end

function Component:removeChild(child)
    if not child or not self.children then return self end
    for i = #self.children, 1, -1 do
        if self.children[i] == child then
            table.remove(self.children, i)
            child.parent = nil
            break
        end
    end
    self._dirty = true
    return self
end

function Component:clearChildren()
    if not self.children then return self end
    for i = #self.children, 1, -1 do
        local c = self.children[i]
        if c and not c._destroyed then
            c:destroy()
        end
    end
    self.children = {}
    self._dirty = true
    return self
end

function Component:setPosition(x, y, isScaled)
    self._rawX = tonumber(x) or 0
    self._rawY = tonumber(y) or 0
    if not isScaled and self._autoScale then
        self.x = NovaUI.scale(self._rawX)
        self.y = NovaUI.scale(self._rawY)
    else
        self.x = self._rawX
        self.y = self._rawY
    end
    if self.parent then
        local px, py = self.parent:getScreenPosition()
        if type(self.parent.getContentOrigin) == "function" then
            px, py = self.parent:getContentOrigin(px, py)
        end
        self._absX = px + self.x
        self._absY = py + self.y
    else
        self._absX = self.x
        self._absY = self.y
    end
    self._dirty = true
    if self._dgsElement then
        NovaUI.DGSAdapter.syncElement(self._dgsElement, { x = self.x, y = self.y })
    end
    self:emit("move", self.x, self.y)
    return self
end

function Component:getPosition()
    return self.x, self.y
end

function Component:getScreenPosition()
    return self._absX or self.x, self._absY or self.y
end

function Component:setSize(w, h, isScaled)
    self._rawW = math.max(0, tonumber(w) or 0)
    self._rawH = math.max(0, tonumber(h) or 0)
    if not isScaled and self._autoScale then
        self.width = NovaUI.scale(self._rawW)
        self.height = NovaUI.scale(self._rawH)
    else
        self.width = self._rawW
        self.height = self._rawH
    end
    self._dirty = true
    if self._dgsElement then
        NovaUI.DGSAdapter.syncElement(self._dgsElement, { w = self.width, h = self.height })
    end
    if type(self.onResize) == "function" then
        self:onResize(self.width, self.height)
    end
    self:emit("resize", self.width, self.height)
    return self
end

function Component:getSize()
    return self.width, self.height
end

function Component:onScaleChange()
    if self._autoScale then
        self.x = NovaUI.scale(self._rawX)
        self.y = NovaUI.scale(self._rawY)
        self.width = NovaUI.scale(self._rawW)
        self.height = NovaUI.scale(self._rawH)
        if type(self.onResize) == "function" then
            self:onResize(self.width, self.height)
        end
    end
end

function Component:setVisible(visible)
    local v = visible and true or false
    if self.visible == v then return self end
    self.visible = v
    self._dirty = true
    if self._dgsElement then
        NovaUI.DGSAdapter.syncElement(self._dgsElement, { visible = v })
    end
    if not v and NovaUI.Input and NovaUI.Input.clearComponentState then
        NovaUI.Input.clearComponentState(self)
    end
    self:emit("visibilityChange", v)
    return self
end

function Component:isVisible()
    if not self.visible or self._destroyed then return false end
    if self.parent then
        return self.parent:isVisible()
    end
    return true
end

function Component:show()
    return self:setVisible(true)
end

function Component:hide()
    return self:setVisible(false)
end

function Component:toggle()
    return self:setVisible(not self.visible)
end

function Component:setEnabled(enabled)
    self.props.disabled = not enabled
    self._dirty = true
    if self._dgsElement then
        NovaUI.DGSAdapter.syncElement(self._dgsElement, { enabled = enabled })
    end
    return self
end

function Component:isEnabled()
    return not self.props.disabled
end

function Component:setAlpha(alpha)
    self.alpha = NovaUI.Utils.clamp(tonumber(alpha) or 255, 0, 255)
    self._dirty = true
    if self._dgsElement then
        NovaUI.DGSAdapter.syncElement(self._dgsElement, { alpha = self.alpha / 255 })
    end
    return self
end

function Component:getAlpha()
    return self.alpha
end

function Component:setText(text)
    self.props.text = tostring(text or "")
    self._dirty = true
    if self._dgsElement then
        NovaUI.DGSAdapter.syncElement(self._dgsElement, { text = self.props.text })
    end
    return self
end

function Component:getText()
    return tostring(self.props.text or self.props.label or self.props.title or "")
end

function Component:setValue(val, silent)
    local old = self.state.value
    self.state.value = val
    self.props.value = val
    self._dirty = true
    if not silent and old ~= val then
        self:emit("change", val, old)
    end
    return self
end

function Component:getValue()
    return self.state.value
end

function Component:setTooltip(text, options)
    self.props.tooltip = text
    self.props.tooltipOptions = options
    return self
end

function Component:focus()
    if NovaUI.Input and NovaUI.Input.setFocus then
        NovaUI.Input.setFocus(self)
    end
    self:bringToFront()
    return self
end

function Component:blur()
    if NovaUI.Input and NovaUI.Input.focused == self then
        NovaUI.Input.setFocus(nil)
    end
    return self
end

function Component:bringToFront()
    _focusCounter = _focusCounter + 1
    self._focusOrder = _focusCounter
    if not self.parent then
        NovaUI.Renderer.markZOrderDirty()
    else
        self.parent:bringToFront()
    end
    return self
end

function Component:sendToBack()
    self._focusOrder = 0
    if not self.parent then
        NovaUI.Renderer.markZOrderDirty()
    end
    return self
end

function Component:animate(spec)
    return NovaUI.animate(self, spec)
end

function Component:trackTexture(path)
    if type(path) == "string" and path ~= "" then
        self._ownedTextures[path] = true
        return NovaUI.Assets.getTexture(path)
    end
    return nil
end

function Component:destroy()
    if self._destroyed then return false end
    self._destroyed = true
    self.visible = false

    -- 1. Destroy children first
    if self.children then
        for i = #self.children, 1, -1 do
            local child = self.children[i]
            if child and not child._destroyed then
                child:destroy()
            end
        end
        self.children = {}
    end

    -- 2. Detach from parent or root scene list
    if self.parent and self.parent.children then
        for i = #self.parent.children, 1, -1 do
            if self.parent.children[i] == self then
                table.remove(self.parent.children, i)
                break
            end
        end
    else
        for i = #NovaUI._registry.rootElements, 1, -1 do
            if NovaUI._registry.rootElements[i] == self then
                table.remove(NovaUI._registry.rootElements, i)
                break
            end
        end
    end
    self.parent = nil

    -- 3. Stop active animations targeting this component
    NovaUI.stopAnimations(self)

    -- 4. Clear Input focus/hover/drag references
    if NovaUI.Input and NovaUI.Input.clearComponentState then
        NovaUI.Input.clearComponentState(self)
    end

    -- 5. Release tracked textures
    if self._ownedTextures then
        for path in pairs(self._ownedTextures) do
            NovaUI.Assets.releaseTexture(path)
        end
        self._ownedTextures = nil
    end

    -- 6. Kill tracked component timers
    if self._ownedTimers then
        for timer in pairs(self._ownedTimers) do
            NovaUI.killTimer(timer)
        end
        self._ownedTimers = nil
    end

    -- 7. Destroy linked DGS proxy element if any
    if self._dgsElement then
        NovaUI.DGSAdapter.destroyElement(self._dgsElement)
        self._dgsElement = nil
    end

    -- 8. Run component-specific cleanup hook
    if type(self.onDestroy) == "function" then
        pcall(self.onDestroy, self)
    end

    -- 9. Emit destroy event & clear all event handlers
    self:emit("destroy", self)
    self:removeAllListeners()

    -- 10. Remove from global registry
    NovaUI._registry.components[self.id] = nil
    NovaUI.Renderer.markDirty()
    return true
end
