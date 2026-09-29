--[[
    NovaUI - Developer API Quickstart & Component Showcase Snippets
    Provides reusable helper examples for every core NovaUI API.
    File: examples/api_showcase.lua
]]

NovaUI = NovaUI or {}
NovaUI.Examples = {}

-- Example 1: Minimal Window + Button + Event Listener (Section 19 specification)
function NovaUI.Examples.createSettingsDialog()
    local window = NovaUI.create("window", {
        title = "Player Settings",
        width = 520,
        height = 340,
    })

    local nameInput = window:create("edit", {
        x = 24,
        y = 24,
        width = 472,
        height = 38,
        placeholder = "Enter display nickname...",
        icon = "user",
        clearable = true,
    })

    local volumeSlider = window:create("slider", {
        x = 24,
        y = 82,
        width = 472,
        height = 44,
        label = "Voice Chat Volume",
        value = 75,
        min = 0,
        max = 100,
        suffix = "%",
    })

    local hudSwitch = window:create("switch", {
        x = 24,
        y = 142,
        width = 240,
        height = 28,
        label = "Enable Radar HUD",
        checked = true,
    })

    local saveBtn = window:create("button", {
        x = 356,
        y = 220,
        width = 140,
        height = 40,
        text = "Save Changes",
        icon = "check",
        variant = "primary",
    })

    saveBtn:on("click", function()
        NovaUI.notify({
            type = "success",
            title = "Settings Saved",
            message = string.format("Saved profile '%s' (Vol: %d%%, HUD: %s)",
                nameInput:getValue(),
                volumeSlider:getValue(),
                tostring(hudSwitch:isChecked())
            ),
            duration = 4000,
        })
    end)

    return window
end
