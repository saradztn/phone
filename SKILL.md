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

### A. Core Components (9)

| Type | Key Props | Specific Methods / Notes |
| :--- | :--- | :--- |
| `"window"` | `title`, `subtitle`, `icon`, `width`, `height`, `x`, `y`, `draggable` (`true`), `resizable` (`true`), `minimizable` (`true`), `maximizable` (`true`), `closable` (`true`), `showHeader` (`true`), `showFooter` (`false`), `footerText`, `destroyOnClose` (`false`) | `:close()`, `:minimize()`, `:maximize()`, `:setTitle(title, subtitle)`. Content `(0,0)` starts below header. |
| `"panel"` | `title`, `variant` (`"surface"`, `"elevated"`, `"glass"`, `"outlined"`, `"ghost"`), `radius` (`"sm"`, `"md"`, `"lg"`), `shadow` (`"none"`, `"sm"`, `"md"`, `"lg"`) | Styled surface container. |
| `"container"` | `layout` (`"none"`, `"column"`, `"row"`), `gap` (`8`), `padding` (`0`), `stretchChildren` (`false`), `backgroundColor` | Lightweight layout group. Automatically stacks children when `layout = "column"` or `"row"`. |
| `"label"` | `text`, `variant` (`"display"`, `"h1"`, `"h2"`, `"h3"`, `"title"`, `"subtitle"`, `"body"`, `"small"`, `"caption"`), `color` (token name like `"primary"`, `"success"`, `"danger"` or `{r,g,b,a}`), `alignX` (`"left"`, `"center"`, `"right"`), `alignY` (`"top"`, `"center"`, `"bottom"`), `wordBreak` (`false`) | Typography text element. |
| `"button"` | `text`, `variant` (`"primary"`, `"secondary"`, `"outline"`, `"ghost"`, `"danger"`, `"success"`, `"warning"`), `size` (`"xs"`, `"sm"`, `"md"`, `"lg"`), `icon`, `iconPosition` (`"left"`, `"right"`), `loading` (`false`), `radius` | `:setLoading(bool)`. Emits `"click"`. |
| `"image"` | `src` (file path), `radius`, `color` (tint), `rotation` | `:setSource(path)`. Uses cached textures + automatic fallback. |
| `"icon"` | `name` (icon name), `size` (`20`), `color`, `backgroundColor`, `radius` | `:setIcon(name)`. Renders scalable vector icon. |
| `"divider"` | `orientation` (`"horizontal"`, `"vertical"`), `text` (optional centered label), `color` | Hairline separator line. |
| `"spacer"` | `size` (`12`), `width`, `height` | Empty layout spacing block. |

### B. Input Components (14)

| Type | Key Props | Specific Methods & Events |
| :--- | :--- | :--- |
| `"edit"` | `value`, `placeholder`, `icon`, `clearable` (`false`), `maxLength` (`256`), `readOnly` (`false`), `numericOnly` (`false`) | `:setValue(str)`, `:getValue()`, `:clear()`. Emits `"change" (val, old)`, `"submit" (val)`. |
| `"searchbox"` | `value`, `placeholder` (`"Search..."`), `clearable` (`true`) | Inherits `"edit"` with built-in `"search"` icon & clear button. |
| `"passwordinput"`| `value`, `placeholder` (`"Enter password..."`) | Inherits `"edit"` with `"lock"` icon and clickable `"eye"` / `"eye-off"` reveal toggle. |
| `"numberinput"` | `value` (`0`), `min`, `max`, `step` (`1`) | `:increment()`, `:decrement()`, `:setValue(num)`. Built-in `-` / `+` buttons. |
| `"textarea"` | `value`, `placeholder`, `maxLength` (`2000`) | Multi-line text input supporting `Enter` newlines and word-wrapping. |
| `"slider"` | `label`, `value`, `min` (`0`), `max` (`100`), `step` (`1`), `showValue` (`true`), `suffix` (`""`) | `:setValue(num)`. Emits `"change" (num)`. Supports click & drag. |
| `"rangeslider"` | `label`, `value` (`{ minVal, maxVal }`), `min` (`0`), `max` (`100`), `step` (`1`) | Dual-thumb range selector. `:setValue({v1, v2})`. Emits `"change" ({v1, v2})`. |
| `"checkbox"` | `label`, `checked` (`false`) | `:setChecked(bool)`, `:isChecked()`. Emits `"change" (bool)`. |
| `"switch"` | `label`, `checked` (`false`) | Smooth animated toggle pill. `:setChecked(bool)`, `:isChecked()`. Emits `"change" (bool)`. |
| `"radio"` | `label`, `group` (`"default"`), `radioValue`, `checked` (`false`) | Exclusive group selection. `:select()`. Emits `"change" (radioValue, true)`. |
| `"dropdown"` | `options` (`{ "A", "B" }` or `{ { label = "A", value = 1 } }`), `value`, `placeholder`, `maxVisibleItems` (`6`) | `:setOptions(list)`, `:addItem(label, val)`, `:getSelectedItem()`. Emits `"change" (val)`, `"select" (item, idx)`. |
| `"combobox"` | Same as `"dropdown"` + keyboard type-to-filter | Filterable dropdown selector. |
| `"colorpicker"` | `value` (`{r,g,b,a}` or `"#HEX"`), `swatches` | `:setColor(col)`, `:getHex()`. Interactive hue bar + preset swatches. Emits `"change" ({r,g,b,a})`. |
| `"keybind"` | `label`, `value` (`"F2"`) | Click to capture next key press (`Escape` cancels). Emits `"change" (keyName)`. |

### C. Navigation Components (6)

| Type | Key Props | Specific Methods & Events |
| :--- | :--- | :--- |
| `"tabbar"` | `tabs` (`{ "Tab 1", "Tab 2" }` or `{ { id = "t1", label = "Tab 1" } }`), `variant` (`"pills"`, `"underline"`), `activeIndex` (`1`) | `:addTab(label, id)`, `:setActiveTab(idOrIdx)`. Emits `"change" (tabId, idx, tabObj)`. |
| `"tabs"` | `tabs`, `variant` (`"pills"`, `"underline"`), `barHeight` (`40`), `gap` (`10`) | `:addTab(label, id)` returns `(panelContainer, idx)`, `:getTabPanel(idOrIdx)`, `:setActiveTab(idOrIdx)`. |
| `"sidebar"` | `brandTitle`, `brandSubtitle`, `logo`, `items` (`{ { id = "home", label = "Home", icon = "home", badge = "3" } }`), `activeId` | `:addItem(item)`, `:setActive(id)`. Emits `"change" (id)`, `"select" (id, item)`. |
| `"navbar"` | `title`, `subtitle`, `height` (`52`) | Top application header bar. |
| `"breadcrumb"` | `items` (`{ "Home", "Category", "Page" }`) | `:setItems(list)`. Renders path trail. |
| `"pagination"` | `page` (`1`), `totalPages` (`5`) | `:setPage(n)`. Emits `"change" (pageNumber)`. |

### D. Data & Virtualization Components (6)

| Type | Key Props | Specific Methods & Events |
| :--- | :--- | :--- |
| `"scrollpanel"` | `contentHeight`, `scrollStep` (`38`), `backgroundColor`, `border` | Scrollable container that clips & culls off-screen children. `:scrollTo(y)`. |
| `"virtuallist"` | `items` (`{ { title = "...", subtitle = "...", badge = "..." } }`), `rowHeight` (`38`), `renderItem` (optional custom draw fn) | Renders **only visible rows** (handles 10,000+ items at 60 FPS). `:setItems(list)`, `:addItem(it)`, `:clear()`, `:getSelectedItem()`. Emits `"select" (item, idx)`. |
| `"list"` | Same as `"virtuallist"` | Alias for `"virtuallist"`. |
| `"grid"` | `items`, `columns` (`3`), `cellHeight` (`84`), `gap` (`10`) | Virtualized multi-column tile grid. `:setItems(list)`. Emits `"select" (item, idx)`. |
| `"table"` | `columns` (`{ { key = "name", label = "Player", width = 180, sortable = true, type = "badge" } }`), `data` (array of row tables), `striped` (`true`) | `:setData(rows)`, `:addRow(row)`, `:clear()`, `:setFilter(query)`, `:sortBy(colKey, asc)`, `:getSelectedRow()`. Emits `"select" (row, idx)`, `"sort" (colKey, asc)`. |
| `"tree"` | `nodes` (`{ { label = "Folder", expanded = true, icon = "folder", children = { ... } } }`) | `:setNodes(nodes)`. Click folders to expand/collapse. Emits `"select" (node)`, `"toggle" (node, expanded)`. |

### E. Feedback Components (10)

| Type | Key Props / Global Helper | Specific Methods & Notes |
| :--- | :--- | :--- |
| `"notification"`| `NovaUI.notify({ type = "info"\|"success"\|"warning"\|"error"\|"custom", title = "...", message = "...", duration = 4000 })` | Stacked animated toast notifications with progress bar & click-to-dismiss. Also usable as inline component `"notification"` / `"toast"`. |
| `"toast"` | Alias for `"notification"` | Same as `"notification"`. |
| `"tooltip"` | `element:setTooltip("Text")` or `NovaUI.create("tooltip", { target = el, text = "..." })` | Viewport-clamped hover tooltip with fade-in delay. |
| `"modal"` | `title`, `message`, `icon`, `width` (`440`), `height` (`220`), `closeOnEscape` (`true`), `buttons` | Renders over fullscreen dimmed backdrop. `:close()`. |
| `"dialog"` | Alias for `"modal"` | Same as `"modal"`. |
| `"confirmdialog"`| `NovaUI.confirm({ title = "...", message = "...", confirmText = "OK", cancelText = "Cancel", confirmVariant = "primary"\|"danger", onConfirm = fn, onCancel = fn })` | High-level confirmation modal with callbacks. |
| `"progressbar"` | `label`, `value` (`0..100`), `max` (`100`), `variant` (`"primary"`, `"success"`, `"warning"`, `"danger"`), `showPercent` (`true`), `indeterminate` (`false`) | `:setProgress(val, animate)`. |
| `"spinner"` | `size` (`32`), `thickness` (`3`), `variant` (`"primary"`) | Smooth rotating arc indicator. |
| `"loading"` | `text` (`"Loading..."`), `width`, `height` | Frosted card with spinner + label. |
| `"alert"` | `variant` (`"info"`, `"success"`, `"warning"`, `"danger"`), `title`, `message`, `closable` (`false`) | Inline callout banner. |

### F. Advanced Components (10)

| Type | Key Props | Specific Methods & Events |
| :--- | :--- | :--- |
| `"contextmenu"` | `target` (optional component to bind right-click), `items` (`{ { label = "Action", icon = "edit", shortcut = "Ctrl+E", danger = false, onClick = fn }, { divider = true } }`) | `:openAt(x, y)`, `:closePopover()`. Emits `"select" (item, idx)`. |
| `"accordion"` | `items` (`{ { title = "Section 1", content = "Details...", expanded = true } }`), `allowMultiple` (`false`) | `:toggleSection(idx)`. Emits `"change" (idx, expanded, item)`. |
| `"card"` | `title`, `subtitle`, `icon`, `headerHeight` (`52`), `shadow` (`"sm"`) | Elevated content card. Children `(0,0)` start below card header. |
| `"statscard"` | `title`, `value`, `trend` (`"+12.4%"`), `trendUp` (`true`), `icon`, `variant` (`"primary"`, `"success"`, `"warning"`, `"danger"`, `"secondary"`), `sparkline` (`{0.3, 0.6, 0.9}`) | `:setMetric(value, trend, trendUp)`. Dashboard KPI card. |
| `"badge"` | `text`, `variant` (`"primary"`, `"success"`, `"warning"`, `"danger"`, `"info"`, `"neutral"`) | Pill tag component. |
| `"avatar"` | `src` (`"assets/images/avatar_default.png"`), `name`, `size` (`42`), `status` (`"online"`, `"away"`, `"busy"`, `"offline"`) | Circular avatar with status dot indicator. |
| `"status"` | `status` (`"online"`, `"idle"`, `"dnd"`, `"offline"`), `text` | Pulsing status dot + label. |
| `"stepper"` | `steps` (`{ "Step 1", "Step 2", "Step 3" }`), `currentStep` (`1`) | `:setStep(n)`, `:nextStep()`, `:prevStep()`. Emits `"change" (step)`. |
| `"timeline"` | `items` (`{ { title = "...", time = "2m ago", description = "...", type = "success" } }`) | `:addItem(item)`. Vertical chronological activity feed. |
| `"chart"` | `chartType` (`"line"`, `"area"`, `"bar"`, `"donut"`), `title`, `labels` (`{"Mon", "Tue"}`), `data` (`{40, 80}`), `variant` (`"primary"`, `"success"`) | `:setData(data, labels)`, `:setChartType(type)`. |

---

## 4. Built-in Vector Icons (48 Icons)

Always choose icon names from this verified list:
- **Navigation & Actions**: `"search"`, `"close"`, `"check"`, `"plus"`, `"minus"`, `"chevron-down"`, `"chevron-up"`, `"chevron-left"`, `"chevron-right"`, `"menu"`, `"more"`, `"minimize"`, `"maximize"`, `"refresh"`, `"filter"`, `"sort"`, `"edit"`, `"trash"`, `"copy"`, `"power"`, `"play"`, `"pause"`
- **Interface & Objects**: `"home"`, `"dashboard"`, `"settings"`, `"user"`, `"users"`, `"bell"`, `"lock"`, `"unlock"`, `"eye"`, `"eye-off"`, `"star"`, `"heart"`, `"shield"`, `"terminal"`, `"chart"`, `"folder"`, `"file"`, `"key"`, `"sliders"`, `"clock"`, `"globe"`, `"sparkle"`
- **Status & Semantic**: `"info"`, `"warning"`, `"error"`, `"success"`

---

## 5. Theme Engine & Animation Patterns

### Switching or Creating Themes
```lua
-- Switch to one of the 5 built-in themes: "midnight", "dark", "ocean", "emerald", "light"
NovaUI.setTheme("midnight")

-- Or register a custom theme at runtime
NovaUI.createTheme("gold_luxury", {
    label      = "Gold Luxury",
    background = { 14, 13, 10, 248 },
    surface    = { 24, 22, 17, 255 },
    primary    = "#F59E0B",
    secondary  = "#FBBF24",
    borderFocus= "#F59E0B",
}, "dark")
NovaUI.setTheme("gold_luxury")
```

### Animating Any Component
```lua
NovaUI.animate(panel, {
    x = 300,
    alpha = 255,
    duration = 280,
    easing = "outBack", -- "linear" | "outQuad" | "outCubic" | "outQuart" | "outBack" | "outElastic" | "outBounce" | "spring"
    onComplete = function(el)
        -- Optional callback
    end,
})
```

---

## 6. Complete Copy-Paste Blueprints for AI Agents

### Blueprint A: Vehicle Dealership / Shop Window with Table, Search & Purchase Modal
```lua
local shopWin = nil

function openVehicleShop(vehiclesList)
    if shopWin and not shopWin._destroyed then
        shopWin:setVisible(true)
        shopWin:bringToFront()
        showCursor(true)
        return
    end

    shopWin = NovaUI.create("window", {
        title = "Luxury Motorsport Dealership",
        subtitle = "Browse and purchase vehicles",
        icon = "sparkle",
        width = 820,
        height = 520,
    })

    local search = shopWin:create("searchbox", {
        x = 20, y = 18, width = 320, height = 38,
        placeholder = "Search vehicle model or category...",
    })

    local vehTable = shopWin:create("table", {
        x = 20, y = 68, width = 780, height = 330,
        columns = {
            { key = "id",       label = "ID",       width = 80,  sortable = true },
            { key = "name",     label = "Model",    width = 240, sortable = true },
            { key = "topSpeed", label = "Top Speed",width = 150, sortable = true },
            { key = "price",    label = "Price",    width = 160, sortable = true },
            { key = "stock",    label = "Stock",    width = 140, sortable = true, type = "badge" },
        },
        data = vehiclesList or {
            { id = 411, name = "Infernus GT", topSpeed = "245 km/h", price = "$450,000", stock = "Active" },
            { id = 560, name = "Sultan RS",   topSpeed = "215 km/h", price = "$185,000", stock = "Active" },
            { id = 451, name = "Turismo R",   topSpeed = "238 km/h", price = "$390,000", stock = "Pending" },
        },
    })

    search:on("change", function(q)
        vehTable:setFilter(q)
    end)

    local buyBtn = shopWin:create("button", {
        x = 620, y = 412, width = 180, height = 42,
        text = "Purchase Vehicle",
        icon = "check",
        variant = "primary",
    })

    buyBtn:on("click", function()
        local selected = vehTable:getSelectedRow()
        if not selected then
            NovaUI.notify({
                type = "warning",
                title = "No Vehicle Selected",
                message = "Please select a vehicle from the table first.",
            })
            return
        end

        NovaUI.confirm({
            title = "Confirm Vehicle Purchase",
            message = string.format("Do you want to buy %s for %s?", selected.name, selected.price),
            confirmText = "Buy Now",
            onConfirm = function()
                if type(triggerServerEvent) == "function" then
                    triggerServerEvent("dealership:buyVehicle", localPlayer, selected.id)
                end
                NovaUI.notify({
                    type = "success",
                    title = "Purchase Complete",
                    message = "You purchased " .. selected.name .. "!",
                })
            end,
        })
    end)

    showCursor(true)
end
```

### Blueprint B: Using NovaUI from Another Resource (`meta.xml` Include or Exports)
- **Option 1 (Inside the `NovaUI` resource)**: Add your client script at the bottom of `meta.xml` after `client/core/bootstrap.lua` and use the `NovaUI` table directly.
- **Option 2 (Cross-Resource via MTA Exports)**:
  ```lua
  local winId = exports.NovaUI:novaCreate("window", { title = "External Window", width = 500, height = 320 })
  local btnId = exports.NovaUI:novaCreate("button", { x = 20, y = 20, width = 140, height = 38, text = "Hello" }, winId)
  exports.NovaUI:novaNotify({ type = "info", title = "Ready", message = "Loaded via exports!" })
  ```
