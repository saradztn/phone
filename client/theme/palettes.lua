--[[
    NovaUI - Built-in Theme Palettes
    Supports: dark, light, midnight, ocean, emerald
    File: client/theme/palettes.lua
]]

NovaUI = NovaUI or {}

NovaUI.Palettes = {
    -- 1. Dark: Sleek modern zinc/slate SaaS dark theme
    dark = {
        name            = "dark",
        label           = "Modern Dark",
        isDark          = true,
        background      = { 12, 14, 18, 248 },
        backgroundAlt   = { 17, 20, 26, 255 },
        surface         = { 22, 26, 34, 255 },
        surfaceElevated = { 29, 34, 44, 255 },
        surfaceHover    = { 36, 42, 54, 255 },
        surfaceActive   = { 44, 51, 66, 255 },
        glass           = { 18, 22, 30, 225 },
        header          = { 16, 19, 25, 255 },
        sidebar         = { 14, 17, 22, 255 },

        primary         = { 99, 102, 241, 255 },   -- Indigo 500
        primaryHover    = { 129, 140, 248, 255 },  -- Indigo 400
        primaryActive   = { 79, 70, 229, 255 },    -- Indigo 600
        primarySoft     = { 99, 102, 241, 36 },

        secondary       = { 56, 189, 248, 255 },   -- Sky 400
        secondaryHover  = { 125, 211, 252, 255 },
        secondarySoft   = { 56, 189, 248, 34 },

        accent          = { 168, 85, 247, 255 },   -- Purple 500

        text            = { 241, 245, 249, 255 },  -- Slate 100
        textSecondary   = { 186, 196, 210, 255 },
        textMuted       = { 125, 138, 158, 255 },  -- Slate 400
        textInverse     = { 15, 23, 42, 255 },

        border          = { 45, 53, 68, 210 },
        borderLight     = { 62, 72, 92, 160 },
        borderFocus     = { 99, 102, 241, 255 },

        success         = { 16, 185, 129, 255 },   -- Emerald 500
        successSoft     = { 16, 185, 129, 36 },
        warning         = { 245, 158, 11, 255 },   -- Amber 500
        warningSoft     = { 245, 158, 11, 36 },
        danger          = { 239, 68, 68, 255 },    -- Rose/Red 500
        dangerSoft      = { 239, 68, 68, 36 },
        info            = { 59, 130, 246, 255 },   -- Blue 500
        infoSoft        = { 59, 130, 246, 36 },

        scrollbarTrack  = { 18, 21, 28, 180 },
        scrollbarThumb  = { 68, 78, 98, 220 },
        overlay         = { 4, 6, 10, 175 },
        shadow          = { 0, 0, 0, 150 },
    },

    -- 2. Midnight: Deep cyber-indigo & electric cyan/violet (Default flagship theme)
    midnight = {
        name            = "midnight",
        label           = "Midnight Nebula",
        isDark          = true,
        background      = { 9, 12, 22, 248 },
        backgroundAlt   = { 13, 17, 31, 255 },
        surface         = { 17, 23, 41, 255 },
        surfaceElevated = { 24, 32, 56, 255 },
        surfaceHover    = { 31, 41, 70, 255 },
        surfaceActive   = { 39, 52, 86, 255 },
        glass           = { 14, 19, 35, 228 },
        header          = { 11, 15, 28, 255 },
        sidebar         = { 10, 14, 25, 255 },

        primary         = { 56, 189, 248, 255 },   -- Electric Cyan
        primaryHover    = { 103, 214, 255, 255 },
        primaryActive   = { 14, 165, 233, 255 },
        primarySoft     = { 56, 189, 248, 38 },

        secondary       = { 129, 140, 248, 255 },  -- Soft Indigo
        secondaryHover  = { 165, 180, 252, 255 },
        secondarySoft   = { 129, 140, 248, 36 },

        accent          = { 192, 132, 252, 255 },  -- Neon Violet

        text            = { 240, 246, 255, 255 },
        textSecondary   = { 182, 198, 226, 255 },
        textMuted       = { 116, 134, 168, 255 },
        textInverse     = { 9, 13, 24, 255 },

        border          = { 38, 52, 84, 220 },
        borderLight     = { 58, 78, 122, 165 },
        borderFocus     = { 56, 189, 248, 255 },

        success         = { 34, 211, 153, 255 },
        successSoft     = { 34, 211, 153, 38 },
        warning         = { 251, 191, 36, 255 },
        warningSoft     = { 251, 191, 36, 38 },
        danger          = { 244, 63, 94, 255 },
        dangerSoft      = { 244, 63, 94, 38 },
        info            = { 56, 189, 248, 255 },
        infoSoft        = { 56, 189, 248, 38 },

        scrollbarTrack  = { 13, 18, 32, 180 },
        scrollbarThumb  = { 54, 72, 112, 225 },
        overlay         = { 3, 5, 12, 185 },
        shadow          = { 0, 2, 10, 165 },
    },

    -- 3. Ocean: Deep abyssal teal & aqua marine
    ocean = {
        name            = "ocean",
        label           = "Oceanic Abyss",
        isDark          = true,
        background      = { 7, 18, 24, 248 },
        backgroundAlt   = { 10, 25, 33, 255 },
        surface         = { 14, 33, 44, 255 },
        surfaceElevated = { 19, 43, 57, 255 },
        surfaceHover    = { 25, 55, 72, 255 },
        surfaceActive   = { 32, 68, 88, 255 },
        glass           = { 11, 27, 36, 228 },
        header          = { 9, 22, 30, 255 },
        sidebar         = { 8, 20, 27, 255 },

        primary         = { 20, 184, 166, 255 },   -- Teal 500
        primaryHover    = { 45, 212, 191, 255 },   -- Teal 400
        primaryActive   = { 13, 148, 136, 255 },   -- Teal 600
        primarySoft     = { 20, 184, 166, 40 },

        secondary       = { 56, 189, 248, 255 },
        secondaryHover  = { 125, 211, 252, 255 },
        secondarySoft   = { 56, 189, 248, 36 },

        accent          = { 34, 211, 238, 255 },   -- Cyan 400

        text            = { 236, 253, 245, 255 },
        textSecondary   = { 174, 214, 220, 255 },
        textMuted       = { 108, 152, 164, 255 },
        textInverse     = { 7, 18, 24, 255 },

        border          = { 29, 64, 82, 220 },
        borderLight     = { 44, 90, 112, 165 },
        borderFocus     = { 45, 212, 191, 255 },

        success         = { 16, 185, 129, 255 },
        successSoft     = { 16, 185, 129, 38 },
        warning         = { 245, 158, 11, 255 },
        warningSoft     = { 245, 158, 11, 38 },
        danger          = { 244, 63, 94, 255 },
        dangerSoft      = { 244, 63, 94, 38 },
        info            = { 6, 182, 212, 255 },
        infoSoft        = { 6, 182, 212, 38 },

        scrollbarTrack  = { 10, 24, 32, 180 },
        scrollbarThumb  = { 40, 84, 104, 225 },
        overlay         = { 2, 9, 14, 185 },
        shadow          = { 0, 5, 8, 160 },
    },

    -- 4. Emerald: Obsidian forest & vibrant emerald/mint
    emerald = {
        name            = "emerald",
        label           = "Emerald Matrix",
        isDark          = true,
        background      = { 9, 17, 14, 248 },
        backgroundAlt   = { 13, 24, 20, 255 },
        surface         = { 17, 32, 26, 255 },
        surfaceElevated = { 23, 42, 35, 255 },
        surfaceHover    = { 30, 54, 45, 255 },
        surfaceActive   = { 38, 67, 56, 255 },
        glass           = { 14, 26, 21, 228 },
        header          = { 11, 21, 17, 255 },
        sidebar         = { 10, 19, 15, 255 },

        primary         = { 16, 185, 129, 255 },   -- Emerald 500
        primaryHover    = { 52, 211, 153, 255 },   -- Emerald 400
        primaryActive   = { 5, 150, 105, 255 },    -- Emerald 600
        primarySoft     = { 16, 185, 129, 40 },

        secondary       = { 132, 204, 22, 255 },   -- Lime 500
        secondaryHover  = { 163, 230, 53, 255 },
        secondarySoft   = { 132, 204, 22, 36 },

        accent          = { 45, 212, 191, 255 },

        text            = { 236, 253, 245, 255 },
        textSecondary   = { 176, 212, 196, 255 },
        textMuted       = { 112, 150, 134, 255 },
        textInverse     = { 9, 17, 14, 255 },

        border          = { 32, 62, 50, 220 },
        borderLight     = { 48, 88, 72, 165 },
        borderFocus     = { 52, 211, 153, 255 },

        success         = { 34, 197, 94, 255 },
        successSoft     = { 34, 197, 94, 38 },
        warning         = { 234, 179, 8, 255 },
        warningSoft     = { 234, 179, 8, 38 },
        danger          = { 239, 68, 68, 255 },
        dangerSoft      = { 239, 68, 68, 38 },
        info            = { 20, 184, 166, 255 },
        infoSoft        = { 20, 184, 166, 38 },

        scrollbarTrack  = { 12, 23, 18, 180 },
        scrollbarThumb  = { 44, 82, 66, 225 },
        overlay         = { 3, 9, 6, 185 },
        shadow          = { 0, 6, 4, 160 },
    },

    -- 5. Light: Clean modern daylight SaaS interface
    light = {
        name            = "light",
        label           = "Daylight Crisp",
        isDark          = false,
        background      = { 241, 245, 249, 250 },  -- Slate 100
        backgroundAlt   = { 248, 250, 252, 255 },  -- Slate 50
        surface         = { 255, 255, 255, 255 },  -- Pure White
        surfaceElevated = { 248, 250, 252, 255 },
        surfaceHover    = { 241, 245, 249, 255 },
        surfaceActive   = { 226, 232, 240, 255 },
        glass           = { 255, 255, 255, 232 },
        header          = { 255, 255, 255, 255 },
        sidebar         = { 248, 250, 252, 255 },

        primary         = { 79, 70, 229, 255 },    -- Indigo 600
        primaryHover    = { 99, 102, 241, 255 },   -- Indigo 500
        primaryActive   = { 67, 56, 202, 255 },    -- Indigo 700
        primarySoft     = { 79, 70, 229, 28 },

        secondary       = { 14, 165, 233, 255 },   -- Sky 500
        secondaryHover  = { 2, 132, 199, 255 },
        secondarySoft   = { 14, 165, 233, 28 },

        accent          = { 147, 51, 234, 255 },

        text            = { 15, 23, 42, 255 },     -- Slate 900
        textSecondary   = { 51, 65, 85, 255 },     -- Slate 700
        textMuted       = { 100, 116, 139, 255 },  -- Slate 500
        textInverse     = { 255, 255, 255, 255 },

        border          = { 203, 213, 225, 230 },  -- Slate 300
        borderLight     = { 226, 232, 240, 200 },  -- Slate 200
        borderFocus     = { 79, 70, 229, 255 },

        success         = { 5, 150, 105, 255 },
        successSoft     = { 5, 150, 105, 28 },
        warning         = { 217, 119, 6, 255 },
        warningSoft     = { 217, 119, 6, 28 },
        danger          = { 220, 38, 38, 255 },
        dangerSoft      = { 220, 38, 38, 28 },
        info            = { 37, 99, 235, 255 },
        infoSoft        = { 37, 99, 235, 28 },

        scrollbarTrack  = { 226, 232, 240, 180 },
        scrollbarThumb  = { 148, 163, 184, 225 },
        overlay         = { 15, 23, 42, 120 },
        shadow          = { 15, 23, 42, 45 },
    },
}
