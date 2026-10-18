
--[[
    r3xsense
    File: src/ui/animations.lua
    Version: 1.0.0

    UI animation module
    Features:
    - Fade in and fade out
    - Smooth transitions
    - Button hover effects
    - Button press effects
    - Window opening and closing
    - Tab transitions
    - Position and size animations
    - Color transitions
    - Animation cancellation
    - Global animation toggle
    - Cleanup
]]

local TweenService = game:GetService("TweenService")

local Animations = {}

Animations.Version = "1.0.0"
Animations.Enabled = true
Animations.DefaultDuration = 0.2

Animations.EasingStyle = Enum.EasingStyle.Quart
Animations.EasingDirection = Enum.EasingDirection.Out

Animations.ActiveTweens = {}
Animations.OriginalProperties = {}

local function IsValidInstance(Object)
    return typeof(Object) == "Instance"
        and Object.Parent ~= nil
end

local function GetTweenInfo(Duration, Style, Direction)
    return TweenInfo.new(
        Duration or Animations.DefaultDuration,
        Style or Animations.EasingStyle,
        Direction or Animations.EasingDirection
    )
end

function Animations.SetEnabled(Enabled)
    Animations.Enabled = Enabled == true

    if not Animations.Enabled then
        Animations.CancelAll()
    end
end

function Animations.SetDefaultDuration(Duration)
    Duration = tonumber(Duration)

    if not Duration or Duration < 0 then
        return false
    end

    Animations.DefaultDuration = math.clamp(Duration, 0, 5)

    return true
end

function Animations.Cancel(Object)
    local Tween = Animations.ActiveTweens[Object]

    if Tween then
        Tween:Cancel()
        Animations.ActiveTweens[Object] = nil
    end
end

function Animations.CancelAll()
    for Object, Tween in pairs(Animations.ActiveTweens) do
        pcall(function()
            Tween:Cancel()
        end)

        Animations.ActiveTweens[Object] = nil
    end
end

function Animations.Tween(Object, Properties, Duration, Style, Direction)
    if not IsValidInstance(Object) then
        return nil
    end

    if typeof(Properties) ~= "table" then
        return nil
    end

    Animations.Cancel(Object)

    if not Animations.Enabled or Duration == 0 then
        for Property, Value in pairs(Properties) do
            pcall(function()
                Object[Property] = Value
            end)
        end

        return nil
    end

    local Info = GetTweenInfo(Duration, Style, Direction)

    local Success, Tween = pcall(function()
        return TweenService:Create(Object, Info, Properties)
    end)

    if not Success or not Tween then
        return nil
    end

    Animations.ActiveTweens[Object] = Tween

    Tween.Completed:Connect(function()
        if Animations.ActiveTweens[Object] == Tween then
            Animations.ActiveTweens[Object] = nil
        end
    end)

    Tween:Play()

    return Tween
end

function Animations.FadeIn(Object, Duration)
    if not IsValidInstance(Object) then
        return
    end

    local Properties = {}

    if Object:IsA("GuiObject") then
        Object.Visible = true

        Properties.BackgroundTransparency = 0

        if Object:IsA("TextLabel")
            or Object:IsA("TextButton")
            or Object:IsA("TextBox") then

            Properties.TextTransparency = 0
        end

        if Object:IsA("ImageLabel")
            or Object:IsA("ImageButton") then

            Properties.ImageTransparency = 0
        end

        local Stroke = Object:FindFirstChildWhichIsA("UIStroke")

        if Stroke then
            Animations.Tween(Stroke, {
                Transparency = 0,
            }, Duration)
        end
    end

    if next(Properties) then
        return Animations.Tween(Object, Properties, Duration)
    end
end

function Animations.FadeOut(Object, Duration)
    if not IsValidInstance(Object) then
        return
    end

    local Properties = {}

    if Object:IsA("GuiObject") then
        Properties.BackgroundTransparency = 1

        if Object:IsA("TextLabel")
            or Object:IsA("TextButton")
            or Object:IsA("TextBox") then

            Properties.TextTransparency = 1
        end

        if Object:IsA("ImageLabel")
            or Object:IsA("ImageButton") then

            Properties.ImageTransparency = 1
        end
    end

    if next(Properties) then
        local Tween = Animations.Tween(Object, Properties, Duration)

        if Tween then
            Tween.Completed:Connect(function(State)
                if State == Enum.PlaybackState.Completed
                    and Object.Parent then

                    Object.Visible = false
                end
            end)
        else
            Object.Visible = false
        end

        return Tween
    end
end

function Animations.Scale(Object, TargetScale, Duration)
    if not IsValidInstance(Object) then
        return nil
    end

    TargetScale = tonumber(TargetScale)

    if not TargetScale then
        return nil
    end

    local ScaleObject = Object:FindFirstChild("AnimationScale")

    if not ScaleObject then
        ScaleObject = Instance.new("UIScale")
        ScaleObject.Name = "AnimationScale"
        ScaleObject.Scale = 1
        ScaleObject.Parent = Object
    end

    return Animations.Tween(ScaleObject, {
        Scale = math.clamp(TargetScale, 0.1, 3),
    }, Duration)
end

function Animations.Move(Object, Position, Duration)
    if not IsValidInstance(Object)
        or typeof(Position) ~= "UDim2" then

        return nil
    end

    return Animations.Tween(Object, {
        Position = Position,
    }, Duration)
end

function Animations.Resize(Object, Size, Duration)
    if not IsValidInstance(Object)
        or typeof(Size) ~= "UDim2" then

        return nil
    end

    return Animations.Tween(Object, {
        Size = Size,
    }, Duration)
end

function Animations.ChangeColor(Object, Color, Duration, Property)
    if not IsValidInstance(Object)
        or typeof(Color) ~= "Color3" then

        return nil
    end

    Property = Property or "BackgroundColor3"

    local Success = pcall(function()
        return Object[Property]
    end)

    if not Success then
        return nil
    end

    return Animations.Tween(Object, {
        [Property] = Color,
    }, Duration)
end

function Animations.ButtonHover(Button, NormalColor, HoverColor)
    if not IsValidInstance(Button)
        or not Button:IsA("GuiButton") then

        return false
    end

    NormalColor = NormalColor or Button.BackgroundColor3
    HoverColor = HoverColor or NormalColor:Lerp(Color3.new(1, 1, 1), 0.08)

    Button.MouseEnter:Connect(function()
        Animations.ChangeColor(Button, HoverColor, 0.12)
    end)

    Button.MouseLeave:Connect(function()
        Animations.ChangeColor(Button, NormalColor, 0.12)
    end)

    return true
end

function Animations.ButtonPress(Button)
    if not IsValidInstance(Button)
        or not Button:IsA("GuiButton") then

        return false
    end

    Button.Activated:Connect(function()
        Animations.Scale(Button, 0.96, 0.06)

        task.delay(0.07, function()
            if Button.Parent then
                Animations.Scale(Button, 1, 0.12)
            end
        end)
    end)

    return true
end

function Animations.OpenWindow(Window, Duration)
    if not IsValidInstance(Window) then
        return
    end

    Window.Visible = true

    local ScaleObject = Window:FindFirstChild("AnimationScale")

    if not ScaleObject then
        ScaleObject = Instance.new("UIScale")
        ScaleObject.Name = "AnimationScale"
        ScaleObject.Parent = Window
    end

    ScaleObject.Scale = 0.92
    Window.BackgroundTransparency = 1

    Animations.Tween(Window, {
        BackgroundTransparency = 0,
    }, Duration)

    Animations.Tween(ScaleObject, {
        Scale = 1,
    }, Duration or 0.22)
end

function Animations.CloseWindow(Window, Duration)
    if not IsValidInstance(Window) then
        return
    end

    local ScaleObject = Window:FindFirstChild("AnimationScale")

    if not ScaleObject then
        ScaleObject = Instance.new("UIScale")
        ScaleObject.Name = "AnimationScale"
        ScaleObject.Parent = Window
    end

    local Tween = Animations.Tween(ScaleObject, {
        Scale = 0.92,
    }, Duration or 0.16)

    Animations.Tween(Window, {
        BackgroundTransparency = 1,
    }, Duration or 0.16)

    if Tween then
        Tween.Completed:Connect(function(State)
            if State == Enum.PlaybackState.Completed
                and Window.Parent then

                Window.Visible = false
                ScaleObject.Scale = 1
                Window.BackgroundTransparency = 0
            end
        end)
    else
        Window.Visible = false
        ScaleObject.Scale = 1
        Window.BackgroundTransparency = 0
    end
end

function Animations.Cleanup()
    Animations.CancelAll()

    table.clear(Animations.OriginalProperties)
end

return Animations
