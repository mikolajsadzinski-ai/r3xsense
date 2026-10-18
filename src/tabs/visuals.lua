local Visuals = {}

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local defaults = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

Visuals.Settings = {
    Enabled = false,
    Brightness = defaults.Brightness,
    ClockTime = defaults.ClockTime,
    FogEnd = defaults.FogEnd,
    Ambient = defaults.Ambient,
    OutdoorAmbient = defaults.OutdoorAmbient,
    HighlightsEnabled = false,
    HighlightColor = Color3.fromRGB(255, 170, 50),
}

function Visuals.SetBrightness(value)
    value = tonumber(value)
    if not value then return end

    Lighting.Brightness = math.clamp(value, 0, 10)
    Visuals.Settings.Brightness = Lighting.Brightness
end

function Visuals.SetClockTime(value)
    value = tonumber(value)
    if not value then return end

    Lighting.ClockTime = math.clamp(value, 0, 24)
    Visuals.Settings.ClockTime = Lighting.ClockTime
end

function Visuals.SetFogEnd(value)
    value = tonumber(value)
    if not value then return end

    Lighting.FogEnd = math.clamp(value, 0, 100000)
    Visuals.Settings.FogEnd = Lighting.FogEnd
end

function Visuals.SetAmbient(color)
    if typeof(color) ~= "Color3" then return end

    Lighting.Ambient = color
    Visuals.Settings.Ambient = color
end

function Visuals.SetOutdoorAmbient(color)
    if typeof(color) ~= "Color3" then return end

    Lighting.OutdoorAmbient = color
    Visuals.Settings.OutdoorAmbient = color
end

function Visuals.SetHighlightsEnabled(enabled, folder)
    Visuals.Settings.HighlightsEnabled = enabled == true

    if not folder or not folder:IsA("Folder") then
        return false, "Provide a test-object Folder from your own Roblox Studio place"
    end

    for _, object in ipairs(folder:GetDescendants()) do
        if object:IsA("BasePart") then
            local highlight = object:FindFirstChild("R3XTestHighlight")

            if enabled then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "R3XTestHighlight"
                    highlight.Adornee = object
                    highlight.FillColor = Visuals.Settings.HighlightColor
                    highlight.OutlineColor = Color3.new(1, 1, 1)
                    highlight.Parent = object
                end

                highlight.Enabled = true
            elseif highlight then
                highlight:Destroy()
            end
        end
    end

    return true
end

function Visuals.SetHighlightColor(color)
    if typeof(color) ~= "Color3" then return end

    Visuals.Settings.HighlightColor = color
end

function Visuals.Reset()
    Lighting.Brightness = defaults.Brightness
    Lighting.ClockTime = defaults.ClockTime
    Lighting.FogEnd = defaults.FogEnd
    Lighting.Ambient = defaults.Ambient
    Lighting.OutdoorAmbient = defaults.OutdoorAmbient

    Visuals.Settings.Brightness = defaults.Brightness
    Visuals.Settings.ClockTime = defaults.ClockTime
    Visuals.Settings.FogEnd = defaults.FogEnd
    Visuals.Settings.Ambient = defaults.Ambient
    Visuals.Settings.OutdoorAmbient = defaults.OutdoorAmbient
end

return Visuals
