--[[
    NovaUI - Unified Input Manager
    Handles mouse, hover, click, double-click, drag, wheel scroll, focus, keyboard, text input, and keybinds.
    Prevents input conflicts across modals, popovers, windows, and game binds.
    File: client/input/manager.lua
]]

NovaUI = NovaUI or {}
NovaUI.Input = {
    cursorX = 0,
    cursorY = 0,
    hovered = nil,
    pressed = nil,
    focused = nil,
    dragged = nil,
    dragStartX = 0,
    dragStartY = 0,
    lastClickTime = 0,
    lastClickTarget = nil,
    lastClickButton = nil,
    activePopover = nil,     -- currently open Dropdown / ComboBox / ContextMenu
    capturingKeybind = nil,  -- Keybind component waiting for key press
}

local Input = NovaUI.Input
local Utils = NovaUI.Utils

-- Deepest hit-test traversal in reverse render order (topmost z-index first)
local function _hitTestTree(comp, mx, my)
    if not comp or comp._destroyed or not comp.visible or comp.props.disabled then
        return nil
    end

    local absX = comp._absX or comp.x or 0
    local absY = comp._absY or comp.y or 0
    local w = comp.width or 0
    local h = comp.height or 0

    -- Check children first in reverse order (topmost child first)
    if comp.children and #comp.children > 0 and not comp._minimized then
        local canHitChildren = true
        if comp._clipsChildren then
            local cx, cy, cw, ch = absX, absY, w, h
            if type(comp.getViewportRect) == "function" then
                cx, cy, cw, ch = comp:getViewportRect(absX, absY, w, h)
            end
            canHitChildren = Utils.pointInRect(mx, my, cx, cy, cw, ch)
        end
        if canHitChildren then
            for i = #comp.children, 1, -1 do
                local hit = _hitTestTree(comp.children[i], mx, my)
                if hit then
                    return hit
                end
            end
        end
    end

    if not comp._passthrough and Utils.pointInRect(mx, my, absX, absY, w, h) then
        return comp
    end
    return nil
end

function Input.getElementAt(mx, my)
    -- 1. Active popover (Dropdown menu / ContextMenu) gets highest priority
    if Input.activePopover and not Input.activePopover._destroyed and Input.activePopover.visible then
        if type(Input.activePopover.hitTestPopover) == "function" then
            if Input.activePopover:hitTestPopover(mx, my) then
                return Input.activePopover
            end
        end
    end

    -- 2. If a Modal is active, restrict hit-testing to the topmost modal
    local modals = NovaUI._registry.modals
    if modals and #modals > 0 then
        local topModal = modals[#modals]
        if topModal and not topModal._destroyed and topModal.visible then
            local hit = _hitTestTree(topModal, mx, my)
            return hit or topModal
        end
    end

    -- 3. Traverse root elements in reverse z-order
    NovaUI.Renderer.sortRoots()
    local roots = NovaUI._registry.rootElements
    for i = #roots, 1, -1 do
        local hit = _hitTestTree(roots[i], mx, my)
        if hit then
            return hit
        end
    end
    return nil
end

function Input.setFocus(comp)
    if Input.focused == comp then return end
    local prev = Input.focused
    Input.focused = comp

    if prev and not prev._destroyed then
        prev.state.focused = false
        prev._dirty = true
        if type(prev.onBlur) == "function" then
            pcall(prev.onBlur, prev)
        end
        prev:emit("blur", prev)
    end

    local isTextInput = false
    if comp and not comp._destroyed then
        comp.state.focused = true
        comp._dirty = true
        isTextInput = comp._acceptsTextInput == true
        if type(comp.onFocus) == "function" then
            pcall(comp.onFocus, comp)
        end
        comp:emit("focus", comp)
    end

    if type(guiSetInputMode) == "function" then
        pcall(guiSetInputMode, isTextInput and "no_binds" or "allow_binds")
    end
end

function Input.clearComponentState(comp)
    if Input.hovered == comp then Input.hovered = nil end
    if Input.pressed == comp then Input.pressed = nil end
    if Input.focused == comp then Input.setFocus(nil) end
    if Input.dragged == comp then Input.dragged = nil end
    if Input.activePopover == comp then Input.activePopover = nil end
    if Input.capturingKeybind == comp then Input.capturingKeybind = nil end
end

function Input.handleMouseMove(mx, my)
    mx = tonumber(mx) or Input.cursorX
    my = tonumber(my) or Input.cursorY
    local dx = mx - Input.cursorX
    local dy = my - Input.cursorY
    Input.cursorX = mx
    Input.cursorY = my

    -- Handle active drag operation
    if Input.dragged and not Input.dragged._destroyed then
        if type(Input.dragged.onDragMove) == "function" then
            Input.dragged:onDragMove(mx, my, dx, dy)
        end
        Input.dragged:emit("drag", mx, my, dx, dy)
        return
    end

    local target = Input.getElementAt(mx, my)
    if target ~= Input.hovered then
        local prev = Input.hovered
        Input.hovered = target
        if prev and not prev._destroyed then
            prev.state.hovered = false
            prev._dirty = true
            if type(prev.onMouseLeave) == "function" then prev:onMouseLeave(mx, my) end
            prev:emit("mouseLeave", mx, my)
            prev:emit("hover", false, mx, my)
        end
        if target and not target._destroyed then
            target.state.hovered = true
            target._dirty = true
            if type(target.onMouseEnter) == "function" then target:onMouseEnter(mx, my) end
            target:emit("mouseEnter", mx, my)
            target:emit("hover", true, mx, my)
        end
        if NovaUI.TooltipManager and NovaUI.TooltipManager.onHoverChange then
            NovaUI.TooltipManager.onHoverChange(target, mx, my)
        end
    elseif target and not target._destroyed then
        if type(target.onMouseMove) == "function" then
            target:onMouseMove(mx, my)
        end
    end
end

function Input.handleMouseClick(button, state, mx, my)
    mx = tonumber(mx) or Input.cursorX
    my = tonumber(my) or Input.cursorY
    Input.cursorX = mx
    Input.cursorY = my

    -- Check Notifications click first when clicking top-right area
    if state == "down" and button == "left" and NovaUI.NotificationManager and NovaUI.NotificationManager.handleClick then
        if NovaUI.NotificationManager.handleClick(mx, my) then
            return true
        end
    end

    -- Check active popover (Dropdown / ComboBox / ContextMenu)
    if Input.activePopover and not Input.activePopover._destroyed then
        local pop = Input.activePopover
        if state == "down" then
            if type(pop.hitTestPopover) == "function" and pop:hitTestPopover(mx, my) then
                if type(pop.onPopoverClick) == "function" then
                    pop:onPopoverClick(button, state, mx, my)
                end
                return true
            else
                if type(pop.closePopover) == "function" then
                    pop:closePopover()
                end
                Input.activePopover = nil
                -- If the user clicked the dropdown trigger itself to close it, consume the click so it doesn't re-open on mouseUp
                local hit = Input.getElementAt(mx, my)
                if hit == pop then
                    Input.pressed = nil
                    return true
                end
            end
        end
    end

    local target = Input.getElementAt(mx, my)

    if state == "down" then
        Input.pressed = target
        Input.setFocus(target)

        if target and not target._destroyed then
            target:bringToFront()
            target.state.pressed = true
            target._dirty = true
            Input.dragStartX = mx
            Input.dragStartY = my

            if type(target.onMouseDown) == "function" then
                target:onMouseDown(button, mx, my)
            end
            target:emit("mouseDown", button, mx, my)
        end
    elseif state == "up" then
        if Input.dragged and not Input.dragged._destroyed then
            if type(Input.dragged.onDragEnd) == "function" then
                Input.dragged:onDragEnd(mx, my)
            end
            Input.dragged:emit("dragEnd", mx, my)
            Input.dragged = nil
        end

        local pressedComp = Input.pressed
        Input.pressed = nil

        if pressedComp and not pressedComp._destroyed then
            pressedComp.state.pressed = false
            pressedComp._dirty = true
            if type(pressedComp.onMouseUp) == "function" then
                pressedComp:onMouseUp(button, mx, my)
            end
            pressedComp:emit("mouseUp", button, mx, my)
        end

        if target and target == pressedComp and not target._destroyed and not target.props.disabled then
            local now = type(getTickCount) == "function" and getTickCount() or 0
            local isDouble = (Input.lastClickTarget == target)
                and (Input.lastClickButton == button)
                and ((now - Input.lastClickTime) <= 320)

            Input.lastClickTarget = target
            Input.lastClickButton = button
            Input.lastClickTime = now

            if button == "left" then
                if type(target.onClick) == "function" then
                    target:onClick(mx, my)
                end
                target:emit("click", target, mx, my)

                if isDouble then
                    if type(target.onDoubleClick) == "function" then
                        target:onDoubleClick(mx, my)
                    end
                    target:emit("doubleClick", target, mx, my)
                end
            elseif button == "right" then
                if type(target.onContextMenu) == "function" then
                    target:onContextMenu(mx, my)
                end
                target:emit("contextMenu", target, mx, my)
            end
        end
    end
    return target ~= nil
end

function Input.handleMouseWheel(direction)
    -- direction: 1 for scroll up, -1 for scroll down
    if Input.activePopover and not Input.activePopover._destroyed and type(Input.activePopover.onPopoverScroll) == "function" then
        if Input.activePopover:onPopoverScroll(direction) then
            return true
        end
    end

    local node = Input.hovered or Input.getElementAt(Input.cursorX, Input.cursorY)
    while node do
        if not node._destroyed and not node.props.disabled and type(node.onScroll) == "function" then
            if node:onScroll(direction) ~= false then
                node:emit("scroll", direction)
                return true
            end
        end
        node = node.parent
    end
    return false
end

function Input.handleKey(key, press)
    if key == "mouse_wheel_up" and press then
        return Input.handleMouseWheel(1)
    elseif key == "mouse_wheel_down" and press then
        return Input.handleMouseWheel(-1)
    end

    if not press then return false end

    -- 1. Active Keybind capture component
    if Input.capturingKeybind and not Input.capturingKeybind._destroyed then
        if type(Input.capturingKeybind.onCaptureKey) == "function" then
            Input.capturingKeybind:onCaptureKey(key)
            return true
        end
    end

    -- 2. Escape closes active popover or topmost Modal
    if key == "escape" then
        if Input.activePopover and not Input.activePopover._destroyed then
            if type(Input.activePopover.closePopover) == "function" then
                Input.activePopover:closePopover()
            end
            Input.activePopover = nil
            return true
        end
        if NovaUI.ModalManager and NovaUI.ModalManager.handleEscape then
            if NovaUI.ModalManager.handleEscape() then
                return true
            end
        end
    end

    -- 3. Route key to focused component
    if Input.focused and not Input.focused._destroyed and not Input.focused.props.disabled then
        if type(Input.focused.onKey) == "function" then
            if Input.focused:onKey(key, press) then
                return true
            end
        end
        Input.focused:emit("key", key, press)
    end

    -- 4. Global registered keybinds
    local kb = NovaUI._registry.keybinds[tostring(key):lower()]
    if kb and type(kb) == "function" then
        pcall(kb, key)
        return true
    end
    return false
end

function Input.handleCharacter(char)
    if Input.focused and not Input.focused._destroyed and not Input.focused.props.disabled then
        if type(Input.focused.onCharacter) == "function" then
            Input.focused:onCharacter(char)
            return true
        end
    end
    return false
end

function NovaUI.bindKey(key, callback)
    if type(key) ~= "string" or key == "" then return false end
    NovaUI._registry.keybinds[key:lower()] = callback
    return true
end

-- Attach MTA client input handlers
if type(addEventHandler) == "function" and type(root) ~= "nil" then
    addEventHandler("onClientCursorMove", root, function(_, _, absX, absY)
        Input.handleMouseMove(absX, absY)
    end)
    addEventHandler("onClientClick", root, function(button, state, absX, absY)
        Input.handleMouseClick(button, state, absX, absY)
    end)
    addEventHandler("onClientKey", root, function(button, press)
        Input.handleKey(button, press)
    end)
    addEventHandler("onClientCharacter", root, function(character)
        Input.handleCharacter(character)
    end)
end
