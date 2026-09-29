--[[
    NovaUI - Retained-Mode Scene Graph Renderer
    Features: Z-index sorting, viewport & clip-rect culling, dirty tracking, and overlay passes
    File: client/rendering/renderer.lua
]]

NovaUI = NovaUI or {}
NovaUI.Renderer = {
    clipStack = {},
    overlayQueue = {},   -- transient top-layer popovers/dropdowns per frame
    frameCount = 0,
    renderedCount = 0,
    culledCount = 0,
    isDirty = true,
    isSorted = false,
}

local Renderer = NovaUI.Renderer
local Utils = NovaUI.Utils

function Renderer.markDirty()
    Renderer.isDirty = true
end

function Renderer.markZOrderDirty()
    Renderer.isSorted = false
    Renderer.isDirty = true
end

function Renderer.pushClip(x, y, w, h)
    local stack = Renderer.clipStack
    if #stack > 0 then
        local top = stack[#stack]
        x, y, w, h = Utils.intersectRect(top[1], top[2], top[3], top[4], x, y, w, h)
    end
    stack[#stack + 1] = { x, y, w, h }
    return x, y, w, h
end

function Renderer.popClip()
    local stack = Renderer.clipStack
    if #stack > 0 then
        stack[#stack] = nil
    end
end

function Renderer.getCurrentClip()
    local stack = Renderer.clipStack
    if #stack > 0 then
        local top = stack[#stack]
        return top[1], top[2], top[3], top[4]
    end
    local sw, sh = NovaUI.getScreenSize()
    return 0, 0, sw, sh
end

function Renderer.isRectVisible(x, y, w, h)
    if w <= 0 or h <= 0 then return false end
    local cx, cy, cw, ch = Renderer.getCurrentClip()
    local _, _, iw, ih = Utils.intersectRect(cx, cy, cw, ch, x, y, w, h)
    return iw > 0 and ih > 0
end

-- Queue a floating overlay callback (e.g. open dropdown menu or context menu) to render on top of windows
function Renderer.enqueueOverlay(zIndex, callback)
    if type(callback) == "function" then
        table.insert(Renderer.overlayQueue, {
            zIndex = tonumber(zIndex) or NovaUI.Tokens.zIndex.dropdown,
            fn = callback,
        })
    end
end

function Renderer.sortRoots()
    if Renderer.isSorted then return end
    table.sort(NovaUI._registry.rootElements, function(a, b)
        local za = (a and a.zIndex) or 100
        local zb = (b and b.zIndex) or 100
        if za == zb then
            return (a._focusOrder or a.id or 0) < (b._focusOrder or b.id or 0)
        end
        return za < zb
    end)
    Renderer.isSorted = true
end

-- Render a single component and its children with off-screen culling
function Renderer.renderComponent(comp, parentAbsX, parentAbsY, inheritedAlpha)
    if not comp or comp._destroyed or not comp.visible then
        return
    end
    local alphaRatio = ((comp.alpha or 255) / 255) * (inheritedAlpha or 1.0)
    if alphaRatio <= 0.005 then
        return
    end

    local absX = (parentAbsX or 0) + (comp.x or 0) + (comp._animOffsetX or 0)
    local absY = (parentAbsY or 0) + (comp.y or 0) + (comp._animOffsetY or 0)
    local w = comp.width or 0
    local h = comp.height or 0

    comp._absX = absX
    comp._absY = absY
    comp._effectiveAlpha = alphaRatio

    -- Off-screen / clip-rect culling (major FPS saver for large UIs)
    if not comp._alwaysRender and not Renderer.isRectVisible(absX, absY, w, h) then
        Renderer.culledCount = Renderer.culledCount + 1
        return
    end

    Renderer.renderedCount = Renderer.renderedCount + 1

    if type(comp.render) == "function" then
        comp:render(absX, absY, w, h, alphaRatio)
    end

    -- Render children if component does not handle child traversal internally (like ScrollPanel/Tabs/Window)
    if not comp._customChildRender and comp.children and #comp.children > 0 then
        local contentX, contentY = absX, absY
        if type(comp.getContentOrigin) == "function" then
            contentX, contentY = comp:getContentOrigin(absX, absY)
        end
        for i = 1, #comp.children do
            Renderer.renderComponent(comp.children[i], contentX, contentY, alphaRatio)
        end
    end
end

-- Master per-frame render pass
function Renderer.renderFrame()
    Renderer.frameCount = Renderer.frameCount + 1
    Renderer.renderedCount = 0
    Renderer.culledCount = 0
    Renderer.clipStack = {}
    Renderer.overlayQueue = {}

    local now = type(getTickCount) == "function" and getTickCount() or (Renderer.frameCount * 16)

    -- 1. Advance Animation Engine
    if NovaUI.Animation and NovaUI.Animation.tick then
        NovaUI.Animation.tick(now)
    end

    -- 2. Sort root elements by zIndex & focus order
    Renderer.sortRoots()

    -- 3. Render root elements
    local roots = NovaUI._registry.rootElements
    for i = 1, #roots do
        local rootComp = roots[i]
        if rootComp and not rootComp._destroyed then
            Renderer.renderComponent(rootComp, 0, 0, 1.0)
        end
    end

    -- 4. Render active Modal stack
    if NovaUI.ModalManager and NovaUI.ModalManager.renderAll then
        NovaUI.ModalManager.renderAll(now)
    end

    -- 5. Render queued floating overlays (dropdown lists, color popovers, context menus)
    if #Renderer.overlayQueue > 0 then
        table.sort(Renderer.overlayQueue, function(a, b) return a.zIndex < b.zIndex end)
        for i = 1, #Renderer.overlayQueue do
            pcall(Renderer.overlayQueue[i].fn)
        end
    end

    -- 6. Render Notification / Toast stack
    if NovaUI.NotificationManager and NovaUI.NotificationManager.renderAll then
        NovaUI.NotificationManager.renderAll(now)
    end

    -- 7. Render active Tooltip
    if NovaUI.TooltipManager and NovaUI.TooltipManager.render then
        NovaUI.TooltipManager.render(now)
    end

    Renderer.isDirty = false
end

-- Attach to MTA client render lifecycle
if type(addEventHandler) == "function" and type(root) ~= "nil" then
    addEventHandler("onClientRender", root, Renderer.renderFrame)
end
