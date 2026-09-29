# NovaUI — Next-Generation Retained-Mode UI Framework for MTA:SA

<p align="center">
  <img src="assets/images/logo.png" width="96" height="96" alt="NovaUI Logo" />
</p>

**NovaUI (`v3.0.0`)** is a modern, modular, high-performance retained-mode UI framework for **Multi Theft Auto: San Andreas (MTA:SA)**. It is architected on top of **DGS (Dx-GUI System)** via a clean abstraction adapter (`NovaUI.DGSAdapter`) combined with a custom DirectX + SVG + Shader rendering pipeline so interfaces look like modern SaaS dashboards and AAA game UIs rather than legacy MTA windows.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Installation & Setup](#2-installation--setup)
3. [Quickstart & Initialization](#3-quickstart--initialization)
4. [Design System & Theme Engine](#4-design-system--theme-engine)
5. [Responsive Multi-Resolution Scaling](#5-responsive-multi-resolution-scaling)
6. [Complete Component Library (55 Components)](#6-complete-component-library-55-components)
7. [Practical Component Examples](#7-practical-component-examples)
8. [Event System](#8-event-system)
9. [Animation & Transition Engine](#9-animation--transition-engine)
10. [Notifications & Toast System](#10-notifications--toast-system)
11. [Modal & Confirm Dialog System](#11-modal--confirm-dialog-system)
12. [Asset, Vector Icon & Font Managers](#12-asset-vector-icon--font-managers)
13. [DGS Integration & Legacy Migration (`NovaUI.compat`)](#13-dgs-integration--legacy-migration-novauicompat)
14. [Running the Interactive Demo Dashboard](#14-running-the-interactive-demo-dashboard)
15. [Performance Tips & Virtualization](#15-performance-tips--virtualization)
16. [Troubleshooting](#16-troubleshooting)

---

## 1. Architecture Overview

```text
NovaUI Developer API (NovaUI.create / window:create / NovaUI.notify / NovaUI.animate)
   │
   ▼
NovaUI Core (Component Lifecycle, EventEmitter, Reactive Theme Engine, Responsive Scaling)
   │
   ├──► Retained-Mode Scene Graph Renderer (Z-Index Sorting, Viewport Culling, Overlay Queue)
   │
   ▼
DGS Abstraction Adapter (NovaUI.DGSAdapter & NovaUI.compat)
   │
   ├──► DGS Resource (RoundRect Shaders, BlurBox, Proxy Edit/Clipboard when DGS is active)
   └──► Native MTA:SA DirectX / SVG Pipeline (100% standalone fallback if DGS is not running)
```

### Project Directory Structure

```text
NovaUI/
├── meta.xml
├── README.md
├── assets/
│   ├── fonts/
│   │   ├── NotoSans-Regular.ttf
│   │   ├── NotoSans-Bold.ttf
│   │   ├── NotoSansArabic-Regular.ttf
│   │   └── NotoSansArabic-Bold.ttf
│   └── images/
│       ├── logo.png
│       ├── avatar_default.png
│       ├── fallback.png
│       └── pattern_grid.png
├── client/
│   ├── core/
│   │   ├── namespace.lua
│   │   ├── utils.lua
│   │   ├── class.lua
│   │   ├── lifecycle.lua
│   │   ├── factory.lua
│   │   └── bootstrap.lua
│   ├── theme/
│   │   ├── tokens.lua
│   │   ├── palettes.lua
│   │   └── manager.lua
│   ├── rendering/
│   │   ├── scaling.lua
│   │   ├── primitives.lua
│   │   └── renderer.lua
│   ├── animation/
│   │   ├── easing.lua
│   │   └── engine.lua
│   ├── events/
│   │   └── emitter.lua
│   ├── input/
│   │   └── manager.lua
│   ├── assets/
│   │   ├── manager.lua
│   │   └── icons.lua
│   ├── fonts/
│   │   └── manager.lua
│   ├── adapters/
│   │   └── dgs/
│   │       ├── adapter.lua
│   │       └── compat.lua
│   └── components/
│       ├── core/         (window, panel, container, label, button, image, icon, divider, spacer, avatar, badge, status)
│       ├── input/        (edit, searchbox, textarea, passwordinput, numberinput, slider, rangeslider, checkbox, switch, radio, dropdown, combobox, colorpicker, keybind)
│       ├── navigation/   (tabs, tabbar, sidebar, navbar, breadcrumb, pagination)
│       ├── data/         (scrollpanel, list, virtuallist, grid, table, tree)
│       ├── feedback/     (notification, toast, tooltip, modal, dialog, confirmdialog, loading, progressbar, spinner, alert)
│       └── advanced/     (contextmenu, accordion, card, stepper, timeline, statscard, chart)
└── examples/
    ├── api_showcase.lua
    └── demo_dashboard.lua
```

---

## 2. Installation & Setup

1. Copy the repository folder into your MTA:SA server's `mods/deathmatch/resources/NovaUI/` directory.
2. *(Optional)* Start `dgs` before `NovaUI` if you wish to use DGS hardware shader acceleration (`dgsCreateRoundRect`, `dgsCreateBlurBox`, native edit proxy). `NovaUI` also runs 100% standalone if `dgs` is not installed.
3. In your server console or `mtaserver.conf`:
   ```text
   start NovaUI
   ```
4. Press **`F2`** or type **`/novaui`** in-game to open the interactive **NovaUI Control Center Demo Dashboard**.

---

## 3. Quickstart & Initialization

```lua
-- Create a modern draggable/resizable window
local window = NovaUI.create("window", {
    title = "Player Settings",
    subtitle = "Configure gameplay & audio preferences",
    icon = "settings",
    width = 600,
    height = 400,
})

-- Add child components directly using parent:create(...)
local saveButton = window:create("button", {
    x = 24,
    y = 280,
    width = 160,
    height = 40,
    text = "Save Settings",
    icon = "check",
    variant = "primary",
})

-- Attach clean event listeners
saveButton:on("click", function()
    NovaUI.notify({
        type = "success",
        title = "Saved",
        message = "Your preferences have been saved successfully!",
        duration = 4000,
    })
end)
```

---

## 4. Design System & Theme Engine

All colors, typography sizes, border radii, spacing tokens, shadows, and animation timings are centralized in `NovaUI.Tokens` and `NovaUI.Theme`.

### Built-in Themes
- `"midnight"` *(Default flagship cyber-indigo & electric cyan)*
- `"dark"` *(Modern zinc/slate dark)*
- `"ocean"` *(Abyssal navy & teal)*
- `"emerald"` *(Obsidian forest & vibrant mint)*
- `"light"` *(Clean daylight SaaS interface)*

### Switching & Creating Custom Themes

```lua
-- Switch active theme at runtime (all mounted components update automatically)
NovaUI.setTheme("ocean")

-- Register a custom theme (inherits unspecified keys from base theme "dark")
NovaUI.createTheme("crimson", {
    label           = "Crimson Pro",
    background      = { 16, 10, 14, 248 },
    surface         = { 26, 15, 22, 255 },
    surfaceElevated = { 38, 22, 32, 255 },
    primary         = "#F43F5E",
    primaryHover    = "#FB7185",
    text            = "#F8FAFC",
    textMuted       = "#94A3B8",
    border          = { 68, 32, 46, 210 },
}, "dark")

NovaUI.setTheme("crimson")
```

---

## 5. Responsive Multi-Resolution Scaling

NovaUI automatically scales coordinates, dimensions, and typography across all 4:3, 16:9, and 4K resolutions:
- `800x600`, `1024x768`, `1280x720`, `1366x768`, `1600x900`, `1920x1080`, `2560x1440`, `3840x2160`.

```lua
local padding = NovaUI.scale(20)            -- Uniform perceptual scale
local fontPt  = NovaUI.scaleFont(14)        -- Perceptual font scale (never illegible on 800x600)
local sw, sh  = NovaUI.getScreenSize()      -- Current viewport resolution
local bp      = NovaUI.getBreakpoint()      -- "xs" | "sm" | "md" | "lg" | "xl" | "xxl"

-- Clamp any rectangle safely inside the screen boundaries
local safeX, safeY, safeW, safeH = NovaUI.fitToViewport(x, y, width, height, NovaUI.scale(12))
```

---

## 6. Complete Component Library (55 Components)

| Category | Components |
| :--- | :--- |
| **Core (9)** | `window`, `panel`, `container`, `label`, `button`, `image`, `icon`, `divider`, `spacer` |
| **Input (14)** | `edit`, `searchbox`, `textarea`, `passwordinput`, `numberinput`, `slider`, `rangeslider`, `checkbox`, `switch`, `radio`, `dropdown`, `combobox`, `colorpicker`, `keybind` |
| **Navigation (6)** | `tabs`, `tabbar`, `sidebar`, `navbar`, `breadcrumb`, `pagination` |
| **Data (6)** | `list`, `virtuallist`, `grid`, `table`, `tree`, `scrollpanel` |
| **Feedback (10)** | `notification`, `toast`, `tooltip`, `modal`, `dialog`, `confirmdialog`, `loading`, `progressbar`, `spinner`, `alert` |
| **Advanced (10)** | `contextmenu`, `accordion`, `card`, `badge`, `avatar`, `status`, `stepper`, `timeline`, `statscard`, `chart` |

---

## 7. Practical Component Examples

### Inputs (`Edit`, `SearchBox`, `PasswordInput`, `NumberInput`, `Slider`, `RangeSlider`, `Switch`, `Dropdown`, `ColorPicker`, `Keybind`)

```lua
local search = window:create("searchbox", {
    x = 20, y = 20, width = 280, height = 38,
    placeholder = "Search inventory...",
})
search:on("change", function(query)
    -- Filter data live
end)

local qty = window:create("numberinput", {
    x = 20, y = 70, width = 180, height = 38,
    value = 10, min = 1, max = 100, step = 1,
})

local range = window:create("rangeslider", {
    x = 20, y = 120, width = 280, height = 42,
    label = "Level Range",
    value = { 10, 50 }, min = 1, max = 100,
})

local roleSelect = window:create("dropdown", {
    x = 20, y = 175, width = 280, height = 38,
    placeholder = "Choose Role...",
    options = {
        { label = "Administrator", value = "admin" },
        { label = "Moderator",     value = "mod" },
        { label = "Member",        value = "member" },
    },
})
```

### Data & Virtualization (`Table`, `VirtualList`, `Tree`, `ScrollPanel`)

```lua
-- Sortable, filterable, virtualized Data Table
local tbl = window:create("table", {
    x = 20, y = 20, width = 600, height = 320,
    columns = {
        { key = "id",     label = "ID",     width = 70,  sortable = true },
        { key = "name",   label = "Player", width = 220, sortable = true },
        { key = "ping",   label = "Ping",   width = 100, sortable = true },
        { key = "status", label = "Status", width = 130, sortable = true, type = "badge" },
    },
    data = {
        { id = 1, name = "Ghost_Operator", ping = 18, status = "Online" },
        { id = 2, name = "Cipher_Nine",    ping = 31, status = "Away" },
    },
})

tbl:on("select", function(row, index)
    outputChatBox("Selected player: " .. tostring(row.name))
end)
```

### Charts (`line`, `area`, `bar`, `donut`) & `StatsCard`

```lua
window:create("statscard", {
    x = 20, y = 20, width = 220, height = 106,
    title = "Online Players",
    value = "128 / 250",
    trend = "+14.2% today",
    trendUp = true,
    icon = "users",
    variant = "primary",
})

window:create("chart", {
    x = 260, y = 20, width = 420, height = 200,
    chartType = "area", -- "line" | "area" | "bar" | "donut"
    title = "Server FPS History",
    labels = { "10m", "8m", "6m", "4m", "2m", "Now" },
    data = { 58, 60, 59, 60, 60, 60 },
    variant = "success",
})
```

---

## 8. Event System

Every component inherits from `NovaUI.EventEmitter`:

```lua
-- Subscribe to an event
local _, handler = button:on("click", function(self, mouseX, mouseY)
    -- Handle click
end)

-- Subscribe once
button:once("hover", function(isHovered)
    -- Fires only on first hover transition
end)

-- Remove a specific listener or all listeners for an event
button:off("click", handler)
button:removeAllListeners()
```

Supported standard events: `"click"`, `"doubleClick"`, `"contextMenu"`, `"mouseDown"`, `"mouseUp"`, `"hover"`, `"mouseEnter"`, `"mouseLeave"`, `"change"`, `"select"`, `"submit"`, `"focus"`, `"blur"`, `"scroll"`, `"move"`, `"resize"`, `"close"`, `"destroy"`.

---

## 9. Animation & Transition Engine

Driven by the main render tick with zero `setTimer` overhead and automatic cleanup when an element is destroyed:

```lua
NovaUI.animate(element, {
    x = 240,
    alpha = 255,
    backgroundColor = { 56, 189, 248, 255 },
    duration = 300,
    easing = "outBack", -- 24 curves: linear, outQuad, outCubic, outQuart, outBack, outElastic, outBounce, spring...
    onComplete = function(el)
        -- Finished
    end,
})

-- Shorthand helpers
NovaUI.fadeIn(element, 240)
NovaUI.fadeOut(element, 180)
NovaUI.slideTo(element, 100, 150, 260, "outQuart")
NovaUI.resizeTo(element, 500, 360, 260, "outQuart")
```

---

## 10. Notifications & Toast System

```lua
NovaUI.notify({
    type = "success", -- "info" | "success" | "warning" | "error" | "custom"
    title = "Success",
    message = "Saved successfully",
    duration = 4000,
})
```

---

## 11. Modal & Confirm Dialog System

```lua
NovaUI.confirm({
    title = "Confirm Reset",
    message = "Are you sure you want to reset your keybinds to default?",
    confirmText = "Reset",
    cancelText = "Cancel",
    confirmVariant = "danger",
    onConfirm = function()
        NovaUI.notify({ type = "info", title = "Reset", message = "Keybinds restored." })
    end,
})
```

---

## 12. Asset, Vector Icon & Font Managers

- **Textures (`NovaUI.Assets`)**: Reference-counted texture cache (`NovaUI.Assets.getTexture(path)`, `NovaUI.Assets.preload({...})`, `NovaUI.Assets.releaseTexture(path)`). Missing or corrupt files automatically fall back to `assets/images/fallback.png` without crashing the UI.
- **Icons (`NovaUI.Icons`)**: 48 built-in scalable SVG/Vector icons (`"search"`, `"close"`, `"check"`, `"plus"`, `"minus"`, `"settings"`, `"user"`, `"users"`, `"bell"`, `"shield"`, `"chart"`, `"sliders"`, etc.).
- **Fonts (`NovaUI.Fonts`)**: Cached by `(family, weight, scaledPtSize)`. Never allocates fonts inside render loops. Includes `NotoSans` and `NotoSansArabic`.

---

## 13. DGS Integration & Legacy Migration (`NovaUI.compat`)

Legacy resources written for DGS can migrate incrementally using `NovaUI.compat`:

```lua
local win = NovaUI.compat.createWindow(0.2, 0.2, 0.4, 0.4, "Legacy Window", true)
local btn = NovaUI.compat.createButton(20, 40, 140, 38, "Legacy Button", false, win)
NovaUI.compat.setVisible(win, true)
```

---

## 14. Running the Interactive Demo Dashboard

When `NovaUI` starts in MTA:SA, the Demo Dashboard opens automatically (or can be toggled anytime via **`F2`** or **`/novaui`**). It includes 5 full interactive views:
1. **Overview & Charts**: 4 KPI `StatsCard` widgets, Area/Donut/Bar `Chart` widgets, and `Timeline`.
2. **Player Directory**: Live `SearchBox`, status `Dropdown`, sortable `Table` with status badges, right-click `ContextMenu`, and `Pagination`.
3. **Inputs & Controls**: `Edit`, `PasswordInput`, `NumberInput`, `ComboBox`, `TextArea`, `Keybind`, `Slider`, `RangeSlider`, `Switch`, `Checkbox`, `Radio`, and `ColorPicker`.
4. **Virtual & Workflow**: `Stepper`, `VirtualList` (2,500 items @ 60 FPS), `Tree`, `ProgressBar`, `Alert`, and `Accordion`.
5. **Themes & System**: Live theme switcher (`midnight`, `dark`, `ocean`, `emerald`, `light`) + runtime custom theme generator.

---

## 15. Performance Tips & Virtualization

1. **Use `VirtualList` or `Table` for large datasets**: They compute `firstVisibleIndex .. lastVisibleIndex` and draw only the ~8–15 rows currently visible on screen, easily handling 10,000+ rows at 60 FPS.
2. **Off-screen Culling**: `NovaUI.Renderer` automatically skips components outside the current viewport or `ScrollPanel` clip rectangle.
3. **Never create elements inside `onClientRender`**: NovaUI is a retained-mode system—create components once (`NovaUI.create`) and mutate state via `:setText()`, `:setValue()`, `:setVisible()`, or `NovaUI.animate()`.

---

## 16. Troubleshooting

- **Keys like `T` or `F` trigger game actions while typing**: NovaUI automatically sets `guiSetInputMode("no_binds")` when an `Edit`/`TextArea` is focused. Ensure you click the input field to focus it.
- **Custom asset warning in debug console**: Verify the asset path is listed in `<file src="..." />` inside `meta.xml`. NovaUI will safely render the fallback texture until the file path is corrected.
