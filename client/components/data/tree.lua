--[[
    NovaUI - Hierarchical Tree View Component
    Supports expandable/collapsible nested nodes, icons, and selection
    File: client/components/data/tree.lua
]]

NovaUI = NovaUI or {}
local Primitives = NovaUI.Primitives
local Utils = NovaUI.Utils

local Tree = NovaUI.Class("Tree", NovaUI.Component)

function Tree:onCreate(props)
    self.nodes = type(props.nodes or props.data) == "table" and (props.nodes or props.data) or {}
    self.rowHeight = NovaUI.scale(tonumber(props.rowHeight) or 30)
    self.indentSize = NovaUI.scale(tonumber(props.indentSize) or 18)
    self.scrollY = 0
    self.selectedNode = nil
    self.flatVisible = {}
    self:_flatten()
end

function Tree:setNodes(nodes)
    self.nodes = type(nodes) == "table" and nodes or {}
    self:_flatten()
    self._dirty = true
    return self
end

function Tree:_flatten()
    self.flatVisible = {}
    local function walk(list, depth)
        for i = 1, #list do
            local n = list[i]
            table.insert(self.flatVisible, { node = n, depth = depth })
            if n.expanded and type(n.children) == "table" and #n.children > 0 then
                walk(n.children, depth + 1)
            end
        end
    end
    walk(self.nodes, 0)
end

function Tree:onClick(mx, my)
    local absX, absY = self:getScreenPosition()
    local idx = math.floor(((my - absY) + self.scrollY) / self.rowHeight) + 1
    local entry = self.flatVisible[idx]
    if entry and entry.node then
        local n = entry.node
        if type(n.children) == "table" and #n.children > 0 then
            n.expanded = not n.expanded
            self:_flatten()
            self:emit("toggle", n, n.expanded)
        end
        self.selectedNode = n
        self:setValue(n)
        self:emit("select", n)
    end
end

function Tree:render(absX, absY, w, h, alphaRatio)
    local theme = NovaUI.Theme
    Primitives.drawRoundedRect(absX, absY, w, h, "sm", Utils.withAlpha(theme.surface, 255 * alphaRatio), Utils.withAlpha(theme.border, 190 * alphaRatio), 1, false)

    local padX = NovaUI.scale(10)
    local maxRows = math.floor(h / self.rowHeight)

    for i = 1, math.min(#self.flatVisible, maxRows) do
        local entry = self.flatVisible[i]
        local n = entry.node
        local ry = absY + (i - 1) * self.rowHeight
        local isSel = (n == self.selectedNode)

        if isSel then
            Primitives.drawRoundedRect(absX + 4, ry + 2, w - 8, self.rowHeight - 4, "xs", Utils.withAlpha(theme.primarySoft, 220 * alphaRatio), nil, 0, false)
        end

        local indentX = absX + padX + entry.depth * self.indentSize
        local hasChildren = type(n.children) == "table" and #n.children > 0
        local icSz = NovaUI.scale(13)

        if hasChildren then
            NovaUI.Icons.draw(
                n.expanded and "chevron-down" or "chevron-right",
                indentX,
                ry + math.floor((self.rowHeight - icSz) * 0.5),
                icSz,
                Utils.withAlpha(theme.textMuted, 240 * alphaRatio)
            )
        end

        local iconName = n.icon or (hasChildren and "folder" or "file")
        local iconX = indentX + NovaUI.scale(18)
        NovaUI.Icons.draw(iconName, iconX, ry + math.floor((self.rowHeight - icSz) * 0.5), icSz, Utils.withAlpha(isSel and theme.primary or theme.secondary, 245 * alphaRatio))

        local labelX = iconX + icSz + NovaUI.scale(8)
        Primitives.drawText(
            tostring(n.label or n.title or "Node"),
            labelX,
            ry,
            w - (labelX - absX) - padX,
            self.rowHeight,
            Utils.withAlpha(isSel and theme.primary or theme.text, 255 * alphaRatio),
            "sm",
            isSel and "bold" or "regular",
            "left",
            "center"
        )
    end
end

NovaUI.registerComponent("tree", Tree, { "Tree" })
