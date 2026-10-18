
local Theme = {}

Theme.Colors = {
    Background = Color3.fromRGB(12, 13, 15),
    Window = Color3.fromRGB(17, 18, 20),
    Panel = Color3.fromRGB(22, 23, 25),
    Border = Color3.fromRGB(42, 44, 46),

    Text = Color3.fromRGB(225, 225, 225),
    Muted = Color3.fromRGB(125, 128, 132),

    Accent = Color3.fromRGB(151, 190, 68),
    AccentDark = Color3.fromRGB(49, 64, 31),

    ToggleOff = Color3.fromRGB(55, 57, 60),
    Danger = Color3.fromRGB(200, 65, 65),
}

Theme.Sizes = {
    WindowWidth = 610,
    WindowHeight = 390,

    MinWidth = 300,
    MinHeight = 280,

    SidebarWidth = 52,
    HeaderHeight = 42,

    MobileBreakpoint = 700,
    MobilePadding = 12,
    TouchButtonSize = 42,
}

Theme.Fonts = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold,
}

Theme.Corners = {
    Window = 4,
    Panel = 3,
    Button = 3,
}

Theme.Animations = {
    Fast = 0.12,
    Normal = 0.18,
    Slow = 0.25,
}

function Theme.IsMobile(viewportWidth)
    return viewportWidth < Theme.Sizes.MobileBreakpoint
end

function Theme.GetScale(viewportWidth, viewportHeight)
    local widthScale = (viewportWidth - 24) / Theme.Sizes.WindowWidth
    local heightScale = (viewportHeight - 80) / Theme.Sizes.WindowHeight

    return math.clamp(
        math.min(widthScale, heightScale, 1),
        0.5,
        1
    )
end

return Theme
