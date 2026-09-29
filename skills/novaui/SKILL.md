---
name: novaui
description: Build modern, responsive, high-performance MTA:SA (Multi Theft Auto: San Andreas) user interfaces, dashboards, HUDs, forms, tables, modals, and notifications using the NovaUI v3.0.0 Retained-Mode UI Framework.
version: 3.0.0
---

# NovaUI — AI Agent Skill & Interface Engineering Guide

Use this skill whenever you are asked to build, modify, or debug a user interface (GUI/DX/DGS) for **MTA:SA (Multi Theft Auto: San Andreas)** using **`NovaUI`**.

---

## 1. Core Mental Model & Golden Rules (MUST READ FIRST)

1. **Retained-Mode Architecture (Never Create in `onClientRender`)**:
   - `NovaUI` manages its own scene graph, `onClientRender` loop, off-screen culling, and z-index sorting automatically.
   - **NEVER** call `NovaUI.create(...)` inside `onClientRender`. Create components once, store references, and update them via `:setText()`, `:setValue()`, `:setVisible()`, `:setData()`, or `NovaUI.animate()`.
2. **Coordinate System & Automatic Scaling (`1920x1080` Base)**:
   - All `x`, `y`, `width`, `height` values passed to `NovaUI.create(type, props)` are authored in **1920x1080 design pixels** and are **scaled automatically** by `NovaUI` for every screen resolution (`800x600` to `3840x2160`).
   - **DO NOT** wrap `x`, `y`, `width`, `height` in `NovaUI.scale()` when passing them into `NovaUI.create(...)`, or they will be double-scaled. Only use `NovaUI.scale(px)` when doing custom manual math outside component creation.
   - If you omit `x` and `y` on a `"window"`, it automatically centers itself on screen.
3. **Parent-Relative Content Origin**:
   - When creating a child via `parent:create("button", { x = 16, y = 16, ... })`, `(x, y)` are relative to the parent's **content area**.
   - For `"window"`, `"card"`, and `"panel"` (when `title` is set), `y = 0` starts **immediately below the header bar**—you do NOT need to add `headerHeight` manually!
4. **Cursor Management in MTA:SA**:
   - Call `showCursor(true)` when opening an interactive window.
   - When a `NovaUI` window is closed via `window:close()` or the header `X` button, `NovaUI` automatically hides the cursor (`showCursor(false)`) if no other windows or modals remain visible.

---

## 2. Core API Cheat Sheet

### Creating Components
```lua
-- Top-level element (e.g., Window)
local win = NovaUI.create("window", {
    title = "Inventory & Loadout",
    subtitle = "Manage your equipped items",
    icon = "shield",
    width = 760,
    height = 500,
})

-- Child element inside any parent component
local btn = win:create("button", {
    x = 20,
    y = 20,
    width = 150,
    height = 38,
    text = "Equip Weapon",
    icon = "check",
    variant = "primary", -- "primary" | "secondary" | "outline" | "ghost" | "danger" | "success" | "warning"
})
```

### Universal Component Methods (Available on ALL 55 Components)
```lua
comp:create(childType, childProps)     -- Create & attach a child component
comp:setPosition(x, y)                 -- Move component (1080p design coords)
comp:getPosition()                     -- Returns scaled x, y
comp:getScreenPosition()               -- Returns absolute screen x, y
comp:setSize(width, height)            -- Resize component (1080p design coords)
comp:getSize()                         -- Returns scaled width, height
comp:setVisible(true | false)          -- Show or hide component
comp:isVisible()                       -- Returns true if component and ancestors are visible
comp:show() / comp:hide() / comp:toggle()
comp:setEnabled(true | false)          -- Enable or disable interaction
comp:isEnabled()                       -- Returns true if not disabled
comp:setAlpha(0..255)                  -- Set opacity (0 to 255)
comp:setText("New Text")               -- Update text/label
comp:getText()                         -- Read text/label
comp:setValue(newValue, silent)        -- Update state value (emits "change" unless silent=true)
comp:getValue()                        -- Read current state value
comp:setTooltip("Helpful hint text")   -- Attach automatic hover tooltip
comp:focus() / comp:blur()             -- Focus or blur component
comp:bringToFront() / comp:sendToBack()-- Adjust z-order
comp:animate(spec)                     -- Run animation on component
comp:update(newPropsTable)             -- Batch update properties
comp:destroy()                         -- Destroy component, children, animations, events & textures
```

### Event System (`:on`, `:once`, `:off`, `:emit`)
```lua
-- Bind listener
btn:on("click", function(self, mouseX, mouseY)
    NovaUI.notify({ type = "success", title = "Clicked", message = "Button pressed!" })
end)

-- Value change listener (Edit, Slider, Switch, Checkbox, Dropdown, Tabs, etc.)
slider:on("change", function(newValue, oldValue)
    outputChatBox("New value: " .. tostring(newValue))
end)

-- Cancel window close by returning false
win:on("close", function(self)
    if hasUnsavedChanges then
        NovaUI.notify({ type = "warning", title = "Unsaved", message = "Save changes first!" })
        return false -- Prevents window from closing
    end
end)
```

---

## 3. Complete 55-Component Reference Catalog

- **Core (9)**: `window`, `panel`, `container`, `label`, `button`, `image`, `icon`, `divider`, `spacer`
- **Input (14)**: `edit`, `searchbox`, `textarea`, `passwordinput`, `numberinput`, `slider`, `rangeslider`, `checkbox`, `switch`, `radio`, `dropdown`, `combobox`, `colorpicker`, `keybind`
- **Navigation (6)**: `tabs`, `tabbar`, `sidebar`, `navbar`, `breadcrumb`, `pagination`
- **Data (6)**: `list`, `virtuallist`, `grid`, `table`, `tree`, `scrollpanel`
- **Feedback (10)**: `notification`, `toast`, `tooltip`, `modal`, `dialog`, `confirmdialog`, `loading`, `progressbar`, `spinner`, `alert`
- **Advanced (10)**: `contextmenu`, `accordion`, `card`, `badge`, `avatar`, `status`, `stepper`, `timeline`, `statscard`, `chart`

### Built-in Vector Icons (48 Icons)
`"search"`, `"close"`, `"check"`, `"plus"`, `"minus"`, `"chevron-down"`, `"chevron-up"`, `"chevron-left"`, `"chevron-right"`, `"home"`, `"dashboard"`, `"settings"`, `"user"`, `"users"`, `"bell"`, `"info"`, `"warning"`, `"error"`, `"success"`, `"lock"`, `"unlock"`, `"eye"`, `"eye-off"`, `"edit"`, `"trash"`, `"copy"`, `"refresh"`, `"filter"`, `"sort"`, `"star"`, `"heart"`, `"shield"`, `"terminal"`, `"chart"`, `"folder"`, `"file"`, `"key"`, `"sliders"`, `"power"`, `"play"`, `"pause"`, `"clock"`, `"globe"`, `"sparkle"`, `"menu"`, `"more"`, `"minimize"`, `"maximize"`
