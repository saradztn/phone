--[[
    NovaUI - Interactive SaaS & Game Server Control Center Demo Dashboard
    Toggle in MTA:SA with F2 or /novaui command
    Showcases: Sidebar, Navbar, Breadcrumb, Avatar, StatsCards, Charts, Tabs,
               Sortable Table, SearchBox, Dropdown, Sliders, RangeSlider, Switches,
               Checkboxes, Radios, ColorPicker, Keybind, Stepper, Timeline, Accordion,
               VirtualList (2,500 items), Tree, Notifications, and ConfirmDialog Modal.
    File: examples/demo_dashboard.lua
]]

NovaUI = NovaUI or {}
NovaUI.Demo = {
    window = nil,
    pages = {},
    activePage = "overview",
}

local Demo = NovaUI.Demo

function Demo.build()
    if Demo.window and not Demo.window._destroyed then
        return Demo.window
    end

    -- 1. Main Application Window
    local win = NovaUI.create("window", {
        title = "NovaUI Control Center",
        subtitle = "Next-Generation Retained-Mode UI Framework for MTA:SA",
        icon = "sparkle",
        width = 1100,
        height = 660,
        minWidth = 760,
        minHeight = 480,
        showFooter = true,
        footerText = "NovaUI v" .. tostring(NovaUI.VERSION) .. "  •  Press F2 or /novaui to toggle cursor & dashboard  •  Right-click rows for Context Menu",
    })
    Demo.window = win

    -- 2. Left Sidebar Navigation
    local sidebar = win:create("sidebar", {
        x = 0,
        y = 0,
        width = 220,
        height = 570,
        brandTitle = "NovaUI",
        brandSubtitle = "DESIGN SYSTEM v3.0",
        activeId = "overview",
        items = {
            { id = "overview",  label = "Overview & Charts",  icon = "dashboard", badge = "LIVE" },
            { id = "players",   label = "Player Directory",   icon = "users",     badge = "128" },
            { id = "controls",  label = "Inputs & Controls",  icon = "sliders" },
            { id = "workflows", label = "Virtual & Workflow", icon = "folder",    badge = "2.5K" },
            { id = "settings",  label = "Themes & System",    icon = "settings" },
        },
    })

    -- User Profile Card at bottom of Sidebar
    local profileCard = sidebar:create("panel", {
        x = 10,
        y = 492,
        width = 200,
        height = 66,
        variant = "elevated",
        radius = "sm",
    })
    profileCard:create("avatar", {
        x = 10,
        y = 12,
        size = 42,
        src = "assets/images/avatar_default.png",
        status = "online",
    })
    profileCard:create("label", {
        x = 62,
        y = 12,
        width = 128,
        height = 20,
        text = "Ghost_Operator",
        variant = "body",
        fontWeight = "bold",
    })
    profileCard:create("status", {
        x = 62,
        y = 34,
        width = 128,
        height = 20,
        status = "online",
        text = "ROOT ADMIN",
    })

    -- 3. Top Header Bar inside Content Area
    local headerBar = win:create("panel", {
        x = 220,
        y = 0,
        width = 880,
        height = 54,
        variant = "surface",
        radius = 0,
    })

    local breadcrumb = headerBar:create("breadcrumb", {
        x = 20,
        y = 13,
        width = 340,
        height = 28,
        items = { "NovaUI", "Dashboard", "Overview & Charts" },
    })

    -- Quick Theme Switcher Dropdown in Header
    local themeDropdown = headerBar:create("dropdown", {
        x = 500,
        y = 8,
        width = 150,
        height = 36,
        value = NovaUI.getThemeName(),
        options = {
            { label = "Midnight Theme", value = "midnight" },
            { label = "Dark Theme",     value = "dark" },
            { label = "Ocean Theme",    value = "ocean" },
            { label = "Emerald Theme",  value = "emerald" },
            { label = "Light Theme",    value = "light" },
        },
    })
    themeDropdown:setTooltip("Switch UI Theme in real time")
    themeDropdown:on("change", function(themeName)
        NovaUI.setTheme(themeName)
        NovaUI.notify({
            type = "info",
            title = "Theme Updated",
            message = "Switched active theme to '" .. tostring(themeName) .. "'.",
            duration = 2800,
        })
    end)

    -- Quick Toast Notification button
    local notifyBtn = headerBar:create("button", {
        x = 660,
        y = 8,
        width = 100,
        height = 36,
        text = "Notify",
        icon = "bell",
        variant = "secondary",
        size = "sm",
    })
    notifyBtn:setTooltip("Trigger a sample toast notification")
    notifyBtn:on("click", function()
        NovaUI.notify({
            type = "success",
            title = "Telemetry Synced",
            message = "All server metrics and player states are synchronized.",
            duration = 3500,
        })
    end)

    -- Quick Confirm Modal button
    local modalBtn = headerBar:create("button", {
        x = 768,
        y = 8,
        width = 96,
        height = 36,
        text = "Modal",
        icon = "shield",
        variant = "primary",
        size = "sm",
    })
    modalBtn:setTooltip("Open confirmation modal dialog")
    modalBtn:on("click", function()
        NovaUI.confirm({
            title = "Deploy Configuration",
            message = "Are you sure you want to apply the current security & performance profile to all active MTA:SA nodes?",
            confirmText = "Deploy Now",
            cancelText = "Cancel",
            onConfirm = function()
                NovaUI.notify({
                    type = "success",
                    title = "Configuration Deployed",
                    message = "Applied live settings across all nodes.",
                })
            end,
        })
    end)

    -- ========================================================================
    -- PAGE 1: Overview & Analytics (StatsCards + Charts + Timeline)
    -- ========================================================================
    local pageOverview = win:create("container", {
        x = 220,
        y = 54,
        width = 880,
        height = 516,
        visible = true,
    })
    Demo.pages.overview = pageOverview

    -- Row of 4 KPI StatsCards
    pageOverview:create("statscard", {
        x = 18, y = 16, width = 200, height = 104,
        title = "Active Players",
        value = "128 / 250",
        trend = "+18.4% vs yesterday",
        trendUp = true,
        icon = "users",
        variant = "primary",
        sparkline = { 0.40, 0.52, 0.61, 0.58, 0.76, 0.92 },
    })
    pageOverview:create("statscard", {
        x = 232, y = 16, width = 200, height = 104,
        title = "Client Frame Rate",
        value = "60.0 FPS",
        trend = "0.18ms UI Render",
        trendUp = true,
        icon = "chart",
        variant = "success",
        sparkline = { 0.92, 0.95, 0.94, 0.96, 0.95, 0.98 },
    })
    pageOverview:create("statscard", {
        x = 446, y = 16, width = 200, height = 104,
        title = "Economy Volume",
        value = "$4.82M",
        trend = "+6.2% this week",
        trendUp = true,
        icon = "globe",
        variant = "secondary",
        sparkline = { 0.30, 0.45, 0.50, 0.68, 0.72, 0.85 },
    })
    pageOverview:create("statscard", {
        x = 660, y = 16, width = 202, height = 104,
        title = "Security Alerts",
        value = "2 Blocked",
        trend = "-75% threats",
        trendUp = true,
        icon = "shield",
        variant = "warning",
        sparkline = { 0.80, 0.60, 0.45, 0.30, 0.22, 0.15 },
    })

    -- Charts row (Area Chart + Donut Chart)
    pageOverview:create("chart", {
        x = 18, y = 134, width = 530, height = 206,
        chartType = "area",
        title = "Server Player Concurrency (Last 7 Days)",
        labels = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" },
        data = { 94, 112, 108, 145, 168, 215, 198 },
        variant = "primary",
    })

    pageOverview:create("chart", {
        x = 562, y = 134, width = 300, height = 206,
        chartType = "donut",
        title = "Resource Budget Allocation",
        labels = { "NovaUI", "Gameplay", "Vehicles", "Audio" },
        data = { 12, 48, 26, 14 },
    })

    -- Bottom row: Bar Chart + Activity Timeline
    pageOverview:create("chart", {
        x = 18, y = 352, width = 420, height = 148,
        chartType = "bar",
        title = "Hourly Transactions (K)",
        labels = { "08h", "10h", "12h", "14h", "16h", "18h", "20h" },
        data = { 24, 38, 52, 46, 72, 88, 64 },
        variant = "success",
    })

    local timelineCard = pageOverview:create("card", {
        x = 452, y = 352, width = 410, height = 148,
        title = "Live System Timeline",
        icon = "clock",
        headerHeight = 38,
    })
    timelineCard:create("timeline", {
        x = 12, y = 6, width = 386, height = 104,
        itemHeight = 48,
        items = {
            { title = "Anti-Cheat Policy v4.2 Active", time = "Just now", description = "Zero false positives across 128 players", type = "success" },
            { title = "Database Snapshot Completed",   time = "14m ago",  description = "Incremental backup stored (14.2 MB)",     type = "primary" },
        },
    })

    -- ========================================================================
    -- PAGE 2: Player Directory (SearchBox, Dropdown, Sortable Table, ContextMenu, Pagination)
    -- ========================================================================
    local pagePlayers = win:create("container", {
        x = 220,
        y = 54,
        width = 880,
        height = 516,
        visible = false,
    })
    Demo.pages.players = pagePlayers

    local playerSearch = pagePlayers:create("searchbox", {
        x = 18, y = 16, width = 280, height = 36,
        placeholder = "Search players by name, role, or status...",
    })

    local statusFilter = pagePlayers:create("dropdown", {
        x = 310, y = 16, width = 170, height = 36,
        placeholder = "All Statuses",
        options = {
            { label = "All Players", value = "" },
            { label = "Online",      value = "Online" },
            { label = "Away",        value = "Away" },
            { label = "Offline",     value = "Offline" },
        },
    })

    local initialPlayers = {
        { id = "01", name = "Ghost_Operator", role = "Administrator", ping = 18,  wealth = "$1,450,000", status = "Online" },
        { id = "02", name = "Vortex_Racer",   role = "VIP Gold",      ping = 34,  wealth = "$640,200",   status = "Online" },
        { id = "03", name = "Cipher_Nine",    role = "Moderator",     ping = 27,  wealth = "$890,000",   status = "Online" },
        { id = "04", name = "Nova_Sentinel",  role = "Developer",     ping = 12,  wealth = "$2,100,000", status = "Online" },
        { id = "05", name = "Blaze_Drift",    role = "Member",        ping = 62,  wealth = "$125,400",   status = "Away" },
        { id = "06", name = "Kairo_Tactical", role = "Police Chief",  ping = 41,  wealth = "$530,000",   status = "Online" },
        { id = "07", name = "Elena_Vance",    role = "Medic Lead",    ping = 29,  wealth = "$410,800",   status = "Online" },
        { id = "08", name = "Shadow_Merc",    role = "Member",        ping = 88,  wealth = "$74,500",    status = "Offline" },
        { id = "09", name = "Apex_Striker",   role = "VIP Platinum",  ping = 22,  wealth = "$1,120,000", status = "Online" },
        { id = "10", name = "Zane_Valen",     role = "Member",        ping = 53,  wealth = "$98,000",    status = "Away" },
        { id = "11", name = "Lyra_Frost",     role = "Moderator",     ping = 19,  wealth = "$780,000",   status = "Online" },
        { id = "12", name = "Orion_Pulse",    role = "Member",        ping = 47,  wealth = "$215,000",   status = "Online" },
    }

    local playerTable = pagePlayers:create("table", {
        x = 18, y = 64, width = 844, height = 390,
        columns = {
            { key = "id",     label = "ID",     width = 70,  sortable = true },
            { key = "name",   label = "Player", width = 220, sortable = true },
            { key = "role",   label = "Role",   width = 180, sortable = true },
            { key = "ping",   label = "Ping",   width = 100, sortable = true },
            { key = "wealth", label = "Balance",width = 150, sortable = true },
            { key = "status", label = "Status", width = 120, sortable = true, type = "badge" },
        },
        data = initialPlayers,
    })

    playerSearch:on("change", function(query)
        playerTable:setFilter(query)
    end)

    statusFilter:on("change", function(val)
        playerTable:setFilter(val or "")
    end)

    -- Attach right-click ContextMenu to playerTable
    pagePlayers:create("contextmenu", {
        target = playerTable,
        items = {
            { label = "Inspect Player Profile", icon = "user", shortcut = "Enter", onClick = function()
                local row = playerTable:getSelectedRow()
                NovaUI.notify({ type = "info", title = "Player Profile", message = "Inspecting " .. (row and row.name or "selected player") })
            end },
            { label = "Spectate Camera", icon = "eye", onClick = function()
                NovaUI.notify({ type = "info", title = "Spectate Mode", message = "Switched camera feed." })
            end },
            { divider = true },
            { label = "Kick from Server", icon = "error", danger = true, onClick = function()
                local row = playerTable:getSelectedRow()
                NovaUI.confirm({
                    title = "Kick Player",
                    message = "Are you sure you want to kick " .. (row and row.name or "this player") .. "?",
                    confirmVariant = "danger",
                    confirmText = "Kick Player",
                })
            end },
        },
    })

    pagePlayers:create("pagination", {
        x = 18, y = 468, width = 300, height = 32,
        page = 1,
        totalPages = 5,
    })

    -- ========================================================================
    -- PAGE 3: Form & Input Controls Showcase
    -- ========================================================================
    local pageControls = win:create("container", {
        x = 220,
        y = 54,
        width = 880,
        height = 516,
        visible = false,
    })
    Demo.pages.controls = pageControls

    local leftCard = pageControls:create("card", {
        x = 18, y = 16, width = 412, height = 484,
        title = "Text, Numeric & Selection Inputs",
        subtitle = "Validated keyboard, caret, masking & stepper inputs",
        icon = "edit",
    })

    leftCard:create("label", { x = 16, y = 12, width = 200, height = 18, text = "Server Hostname", variant = "caption" })
    leftCard:create("edit", { x = 16, y = 32, width = 380, height = 36, value = "NovaUI Official Roleplay [EN/AR]", clearable = true, icon = "globe" })

    leftCard:create("label", { x = 16, y = 78, width = 200, height = 18, text = "RCON Security Token", variant = "caption" })
    leftCard:create("passwordinput", { x = 16, y = 98, width = 380, height = 36, value = "nova_secret_2026" })

    leftCard:create("label", { x = 16, y = 144, width = 180, height = 18, text = "Max Player Slots", variant = "caption" })
    leftCard:create("numberinput", { x = 16, y = 164, width = 180, height = 36, value = 250, min = 32, max = 1024, step = 16 })

    leftCard:create("label", { x = 212, y = 144, width = 180, height = 18, text = "Primary Region", variant = "caption" })
    leftCard:create("combobox", {
        x = 212, y = 164, width = 184, height = 36,
        value = "EU-Central",
        options = { "EU-Central", "US-East", "ME-Dubai", "Asia-Tokyo" },
    })

    leftCard:create("label", { x = 16, y = 212, width = 260, height = 18, text = "Server MOTD Announcement", variant = "caption" })
    leftCard:create("textarea", {
        x = 16, y = 232, width = 380, height = 82,
        value = "Welcome to NovaUI v3.0! Enjoy smooth 60 FPS retained-mode interfaces.",
    })

    leftCard:create("keybind", {
        x = 16, y = 328, width = 380, height = 36,
        label = "Dashboard Toggle Keybind",
        value = "F2",
    })

    local rightCard = pageControls:create("card", {
        x = 446, y = 16, width = 416, height = 484,
        title = "Sliders, Toggles & Color Engine",
        subtitle = "Smooth hardware-accelerated transitions",
        icon = "sliders",
    })

    rightCard:create("slider", {
        x = 16, y = 14, width = 384, height = 42,
        label = "Master Audio Volume",
        value = 80, min = 0, max = 100, suffix = "%",
    })

    rightCard:create("rangeslider", {
        x = 16, y = 66, width = 384, height = 42,
        label = "Matchmaking Level Bracket",
        value = { 15, 75 }, min = 1, max = 100,
    })

    rightCard:create("switch", { x = 16, y = 122, width = 185, height = 28, label = "Dynamic Blur Shaders", checked = true })
    rightCard:create("switch", { x = 212, y = 122, width = 185, height = 28, label = "60 FPS VSync Limiter", checked = true })
    rightCard:create("checkbox", { x = 16, y = 158, width = 185, height = 26, label = "Enable Anti-Cheat", checked = true })
    rightCard:create("checkbox", { x = 212, y = 158, width = 185, height = 26, label = "Auto-Save Telemetry", checked = false })

    rightCard:create("radio", { x = 16, y = 194, width = 120, height = 26, group = "perfMode", label = "Ultra Quality", checked = true })
    rightCard:create("radio", { x = 148, y = 194, width = 120, height = 26, group = "perfMode", label = "Balanced" })
    rightCard:create("radio", { x = 280, y = 194, width = 120, height = 26, group = "perfMode", label = "Low Latency" })

    rightCard:create("label", { x = 16, y = 232, width = 300, height = 18, text = "Custom HUD Primary Accent Color", variant = "caption" })
    local picker = rightCard:create("colorpicker", {
        x = 16, y = 254, width = 384, height = 114,
        value = NovaUI.Theme.primary,
    })
    picker:on("change", function(col)
        NovaUI.Theme.primary = col
    end)

    -- ========================================================================
    -- PAGE 4: Workflows, VirtualList (2,500 items), Tree & Accordion
    -- ========================================================================
    local pageWorkflows = win:create("container", {
        x = 220,
        y = 54,
        width = 880,
        height = 516,
        visible = false,
    })
    Demo.pages.workflows = pageWorkflows

    pageWorkflows:create("stepper", {
        x = 18, y = 14, width = 844, height = 54,
        steps = { "1. Initialize Core", "2. Mount DGS Adapter", "3. Apply Theme", "4. Render Scene" },
        currentStep = 3,
    })

    -- VirtualList with 2,500 items (demonstrating O(1) visible-row virtualization!)
    local massiveItems = {}
    for i = 1, 2500 do
        massiveItems[i] = {
            title = string.format("Virtualized Asset Node #%04d", i),
            subtitle = (i % 2 == 0) and "Cached in VRAM" or "Streamed on-demand",
            badge = string.format("%d KB", (i * 7) % 240 + 12),
        }
    end

    local vListCard = pageWorkflows:create("card", {
        x = 18, y = 78, width = 412, height = 270,
        title = "VirtualList (2,500 Items @ 60 FPS)",
        subtitle = "Only visible rows are drawn each frame",
        icon = "folder",
    })
    vListCard:create("virtuallist", {
        x = 12, y = 10, width = 388, height = 198,
        items = massiveItems,
        rowHeight = 34,
    })

    -- Hierarchical Tree + Accordion on right side
    local treeCard = pageWorkflows:create("card", {
        x = 446, y = 78, width = 416, height = 270,
        title = "Resource Hierarchy Tree",
        subtitle = "Click folders to expand or collapse nodes",
        icon = "terminal",
    })
    treeCard:create("tree", {
        x = 12, y = 10, width = 392, height = 198,
        nodes = {
            {
                label = "NovaUI/", expanded = true, icon = "folder",
                children = {
                    { label = "client/core/ (5 modules)", icon = "folder", expanded = true, children = {
                        { label = "namespace.lua", icon = "file" },
                        { label = "lifecycle.lua", icon = "file" },
                    }},
                    { label = "client/components/ (55 widgets)", icon = "folder" },
                    { label = "client/adapters/dgs/adapter.lua", icon = "file" },
                },
            },
        },
    })

    pageWorkflows:create("progressbar", {
        x = 18, y = 362, width = 412, height = 32,
        label = "VRAM Texture Cache Utilization",
        value = 68,
        variant = "primary",
    })
    pageWorkflows:create("alert", {
        x = 18, y = 404, width = 412, height = 56,
        variant = "success",
        title = "Off-Screen Culling Active",
        message = "2,494 off-screen rows skipped automatically this frame.",
    })

    pageWorkflows:create("accordion", {
        x = 446, y = 362, width = 416, height = 138,
        headerHeight = 34,
        contentHeight = 52,
        items = {
            { title = "How does DGS Integration work?", expanded = true, content = "NovaUI uses a clean DGSAdapter abstraction layer with native fallback." },
            { title = "Is multi-resolution scaling automatic?", expanded = false, content = "Yes! Tested from 800x600 up to 3840x2160 (4K)." },
        },
    })

    -- ========================================================================
    -- PAGE 5: Themes & System Preferences
    -- ========================================================================
    local pageSettings = win:create("container", {
        x = 220,
        y = 54,
        width = 880,
        height = 516,
        visible = false,
    })
    Demo.pages.settings = pageSettings

    local themeCard = pageSettings:create("card", {
        x = 18, y = 16, width = 844, height = 210,
        title = "Theme Engine & Custom Palettes",
        subtitle = "Switch between built-in palettes or register your own custom theme at runtime",
        icon = "sparkle",
    })

    local themes = {
        { id = "midnight", label = "Midnight Nebula", variant = "primary" },
        { id = "dark",     label = "Modern Dark",     variant = "secondary" },
        { id = "ocean",    label = "Oceanic Abyss",   variant = "outline" },
        { id = "emerald",  label = "Emerald Matrix",  variant = "success" },
        { id = "light",    label = "Daylight Crisp",  variant = "secondary" },
    }
    for i = 1, #themes do
        local t = themes[i]
        local btn = themeCard:create("button", {
            x = 16 + (i - 1) * 162,
            y = 20,
            width = 152,
            height = 42,
            text = t.label,
            variant = t.variant,
        })
        btn:on("click", function()
            NovaUI.setTheme(t.id)
            themeDropdown:setValue(t.id, true)
        end)
    end

    local customThemeBtn = themeCard:create("button", {
        x = 16, y = 82, width = 260, height = 40,
        text = "Create & Apply 'Crimson Cyber' Theme",
        icon = "plus",
        variant = "danger",
    })
    customThemeBtn:on("click", function()
        NovaUI.createTheme("crimson", {
            label           = "Crimson Cyber",
            background      = { 16, 10, 14, 248 },
            surface         = { 26, 15, 22, 255 },
            surfaceElevated = { 38, 22, 32, 255 },
            surfaceHover    = { 50, 28, 42, 255 },
            header          = { 20, 12, 17, 255 },
            sidebar         = { 18, 11, 15, 255 },
            primary         = { 244, 63, 94, 255 },
            primaryHover    = { 251, 113, 133, 255 },
            primarySoft     = { 244, 63, 94, 40 },
            borderFocus     = { 244, 63, 94, 255 },
        }, "dark")
        NovaUI.setTheme("crimson")
        NovaUI.notify({
            type = "custom",
            title = "Custom Theme Created",
            message = "Registered and activated 'crimson' via NovaUI.createTheme()!",
        })
    end)

    -- Sidebar page switching handler
    sidebar:on("change", function(pageId, item)
        Demo.activePage = pageId
        for k, container in pairs(Demo.pages) do
            container:setVisible(k == pageId)
        end
        breadcrumb:setItems({ "NovaUI", "Dashboard", item and item.label or pageId })
    end)

    return win
end

function Demo.open()
    local win = Demo.build()
    NovaUI.stopAnimations(win)
    win._closing = false
    win.alpha = 255
    win._animOffsetY = 0
    win:setVisible(true)
    win:bringToFront()
    if type(showCursor) == "function" then
        pcall(showCursor, true)
    end
    return win
end

function Demo.close()
    if Demo.window and not Demo.window._destroyed then
        Demo.window:close()
    end
    if type(showCursor) == "function" then
        pcall(showCursor, false)
    end
end

function Demo.toggle()
    if Demo.window and not Demo.window._destroyed and Demo.window:isVisible() then
        Demo.close()
    else
        Demo.open()
    end
end

-- Bind F2 and /novaui command when running in MTA:SA
NovaUI.bindKey("f2", function()
    Demo.toggle()
end)

if type(addCommandHandler) == "function" then
    addCommandHandler("novaui", function()
        Demo.toggle()
    end)
end

if type(addEventHandler) == "function" and type(resourceRoot) ~= "nil" then
    addEventHandler("onClientResourceStart", resourceRoot, function()
        Demo.open()
    end)
end
