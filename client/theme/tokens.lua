--[[
    NovaUI - Centralized Design System Tokens
    File: client/theme/tokens.lua
]]

NovaUI = NovaUI or {}

NovaUI.Tokens = {
    -- Spacing system (base pixels at 1080p)
    spacing = {
        xxs  = 2,
        xs   = 4,
        sm   = 8,
        md   = 12,
        lg   = 16,
        xl   = 24,
        xxl  = 32,
        xxxl = 48,
    },

    -- Border radius tokens
    radius = {
        none   = 0,
        xs     = 4,
        sm     = 6,
        md     = 10,
        lg     = 14,
        xl     = 20,
        pill   = 999,
        circle = 9999,
    },

    -- Typography scale (base pt sizes at 1080p)
    fontSize = {
        xxs     = 9,
        xs      = 10,
        sm      = 11,
        md      = 13,
        lg      = 15,
        xl      = 18,
        h3      = 20,
        h2      = 24,
        h1      = 30,
        display = 38,
    },

    -- Font weights
    fontWeight = {
        regular  = "regular",
        medium   = "regular",
        semibold = "bold",
        bold     = "bold",
    },

    -- Line heights
    lineHeight = {
        tight   = 1.2,
        normal  = 1.45,
        relaxed = 1.65,
    },

    -- Border widths
    border = {
        none      = 0,
        thin      = 1,
        medium    = 1.5,
        thick     = 2,
        focusRing = 2,
    },

    -- Shadow elevation presets
    shadows = {
        none = { offsetY = 0, blur = 0, spread = 0, alpha = 0 },
        sm   = { offsetY = 2, blur = 6, spread = 1, alpha = 70 },
        md   = { offsetY = 4, blur = 14, spread = 2, alpha = 105 },
        lg   = { offsetY = 8, blur = 24, spread = 4, alpha = 140 },
        xl   = { offsetY = 14, blur = 36, spread = 6, alpha = 180 },
        glow = { offsetY = 0, blur = 16, spread = 3, alpha = 110 },
    },

    -- Opacity states (0.0 - 1.0)
    opacity = {
        disabled      = 0.42,
        muted         = 0.68,
        subtle        = 0.85,
        solid         = 1.00,
        backdrop      = 0.65,
        glass         = 0.88,
        hoverOverlay  = 0.08,
        activeOverlay = 0.15,
    },

    -- Component interaction state multipliers
    states = {
        default  = { scale = 1.00, elevation = "sm" },
        hover    = { scale = 1.01, elevation = "md" },
        active   = { scale = 0.98, elevation = "none" },
        focused  = { scale = 1.00, elevation = "glow" },
        disabled = { scale = 1.00, elevation = "none" },
    },

    -- Animation durations (ms) & default easings
    animation = {
        instant = 75,
        fast    = 150,
        normal  = 240,
        slow    = 380,
        slower  = 550,
        defaultEasing = "outCubic",
        enterEasing   = "outQuart",
        exitEasing    = "inQuad",
        springEasing  = "outBack",
    },

    -- Z-Index layering hierarchy
    zIndex = {
        background   = 1,
        content      = 10,
        sticky       = 50,
        window       = 100,
        dropdown     = 400,
        contextMenu  = 500,
        modalOverlay = 700,
        modal        = 800,
        notification = 900,
        tooltip      = 1000,
    },
}
