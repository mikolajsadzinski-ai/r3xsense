local Lighting = game:GetService("Lighting")
local Components = require(script.Parent.Parent.ui.components)

local Visuals = {}

local originalSettings = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    ExposureCompensation = Lighting.ExposureCompensation,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
}

local effects = {}

local function getEffect(className, effectName)
    if effects[effectName] and effects[effectName].Parent then
        return effects[effectName]
    end

    local effect = Lighting:FindFirstChild(effectName)

    if not effect or not effect:IsA(className) then
        effect = Instance.new(className)
        effect.Name = effectName
        effect.Parent = Lighting
    end

    effects[effectName] = effect

    return effect
end

local function createSlider(parent, title, minimum, maximum, defaultValue, callback)
    local row = Instance.new("Frame")
    row.Name = title:gsub("%s+", "") .. "Slider"
    row.Size = UDim2.new(1, 0, 0, 58)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -55, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Position = UDim2.new(1, -55, 0, 0)
    valueLabel.Size = UDim2.new(0, 55, 0, 24)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Color3.fromRGB(151, 190, 68)
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row

    local track = Instance.new("TextButton")
    track.Name = "Track"
    track.Position = UDim2.new(0, 0, 0, 32)
    track.Size = UDim2.new(1, 0, 0, 8)
    track.BackgroundColor3 = Color3.fromRGB(42, 44, 46)
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(151, 190, 68)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(14, 14)
    knob.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    knob.BorderSizePixel = 0
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local currentValue = math.clamp(defaultValue, minimum, maximum)
    local dragging = false

    local function updateValue(value, invokeCallback)
        currentValue = math.clamp(value, minimum, maximum)

        local alpha = (currentValue - minimum) / (maximum - minimum)

        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = string.format("%.2f", currentValue)

        if invokeCallback and callback then
            callback(currentValue)
        end
    end

    local function updateFromInput(input)
        local trackWidth = track.AbsoluteSize.X

        if trackWidth <= 0 then
            return
        end

        local alpha = math.clamp(
            (input.Position.X - track.AbsolutePosition.X) / trackWidth,
            0,
            1
        )

        local value = minimum + (maximum - minimum) * alpha

        updateValue(value, true)
    end

    track.Activated:Connect(function()
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()

        local alpha = math.clamp(
            (mouse.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1),
            0,
            1
        )

        updateValue(minimum + (maximum - minimum) * alpha, true)
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            updateFromInput(input)
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            updateFromInput(input)
        end
    end)

    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = false
        end
    end)

    updateValue(currentValue, false)

    return row
end

function Visuals.Create(parent)
    local section = Components.CreateSection(parent, "World & Lighting")

    section.Size = UDim2.new(1, 0, 0, 680)

    local list = section:FindFirstChildOfClass("UIListLayout")

    if list then
        list.Padding = UDim.new(0, 4)
    end

    Components.CreateToggle(section, "Night Mode", false, function(enabled)
        if enabled then
            Lighting.ClockTime = 0
            Lighting.Brightness = 1
            Lighting.ExposureCompensation = -0.5
        else
            Lighting.ClockTime = originalSettings.ClockTime
            Lighting.Brightness = originalSettings.Brightness
            Lighting.ExposureCompensation = originalSettings.ExposureCompensation
        end
    end)

    Components.CreateToggle(section, "Global Shadows", originalSettings.GlobalShadows, function(enabled)
        Lighting.GlobalShadows = enabled
    end)

    Components.CreateToggle(section, "Atmosphere", false, function(enabled)
        local atmosphere = Lighting:FindFirstChild("r3xsense_Atmosphere")

        if enabled then
            if not atmosphere then
                atmosphere = Instance.new("Atmosphere")
                atmosphere.Name = "r3xsense_Atmosphere"
                atmosphere.Density = 0.3
                atmosphere.Offset = 0.1
                atmosphere.Color = Color3.fromRGB(199, 210, 220)
                atmosphere.Decay = Color3.fromRGB(106, 112, 125)
                atmosphere.Glare = 0
                atmosphere.Haze = 1
                atmosphere.Parent = Lighting
            end
        elseif atmosphere then
            atmosphere:Destroy()
        end
    end)

    createSlider(section, "Brightness", 0, 5, Lighting.Brightness, function(value)
        Lighting.Brightness = value
    end)

    createSlider(section, "Clock Time", 0, 24, Lighting.ClockTime, function(value)
        Lighting.ClockTime = value
    end)

    createSlider(section, "Exposure", -3, 3, Lighting.ExposureCompensation, function(value)
        Lighting.ExposureCompensation = value
    end)

    createSlider(section, "Saturation", -1, 1, 0, function(value)
        local effect = getEffect("ColorCorrectionEffect", "r3xsense_ColorCorrection")
        effect.Saturation = value
    end)

    createSlider(section, "Contrast", -1, 1, 0, function(value)
        local effect = getEffect("ColorCorrectionEffect", "r3xsense_ColorCorrection")
        effect.Contrast = value
    end)

    createSlider(section, "Tint Strength", 0, 1, 0, function(value)
        local effect = getEffect("ColorCorrectionEffect", "r3xsense_ColorCorrection")
        effect.TintColor = Color3.new(1, 1 - value * 0.3, 1 - value * 0.5)
    end)

    createSlider(section, "Fog End", 100, 100000, Lighting.FogEnd, function(value)
        Lighting.FogEnd = value
    end)

    createSlider(section, "Ambient Intensity", 0, 1, 0.5, function(value)
        local channel = math.floor(value * 255)

        Lighting.Ambient = Color3.fromRGB(channel, channel, channel)
        Lighting.OutdoorAmbient = Color3.fromRGB(channel, channel, channel)
    end)

    return section
end

return Visuals
