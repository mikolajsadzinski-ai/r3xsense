
--[[
    r3xsense
    File: src/config.lua
    Version: 1.0.0
]]

local Config = {}

--// General
Config.ProjectName = "r3xsense"
Config.Version = "1.0.0"
Config.Author = "r3xsense"
Config.Debug = false

--// Interface
Config.UI = {
    Title = "r3xsense",
    Subtitle = "Visual Interface",

    DefaultWidth = 620,
    DefaultHeight = 420,

    MinWidth = 300,
    MinHeight = 280,

    MaxWidth = 1000,
    MaxHeight = 800,

    Responsive = true,
    RoundedCorners = true,

    ShowTitlebar = true,
    ShowSidebar = true,

    AnimationEnabled = true,
    AnimationSpeed = 0.18,

    BackgroundTransparency = 0,
    BorderThickness = 1,

    Font = Enum.Font.Gotham,
    BoldFont = Enum.Font.GothamBold,

    TextSize = 13,
    TitleSize = 17,
}

--// Theme
Config.Theme = {
    Background = Color3.fromRGB(17, 17, 22),
    SecondaryBackground = Color3.fromRGB(23, 23, 30),
    SidebarBackground = Color3.fromRGB(20, 20, 26),

    ElementBackground = Color3.fromRGB(29, 29, 37),
    ElementHover = Color3.fromRGB(38, 38, 48),
    ElementActive = Color3.fromRGB(45, 45, 58),

    Accent = Color3.fromRGB(181, 116, 16),
    AccentLight = Color3.fromRGB(255, 156, 6),

    Text = Color3.fromRGB(240, 240, 245),
    SecondaryText = Color3.fromRGB(155, 155, 170),

    Border = Color3.fromRGB(55, 55, 68),

    Success = Color3.fromRGB(80, 200, 120),
    Warning = Color3.fromRGB(255, 190, 70),
    Error = Color3.fromRGB(235, 80, 80),
}

--// Sidebar
Config.Sidebar = {
    Width = 120,
    ButtonHeight = 36,
    ButtonSpacing = 5,

    IconSize = 18,
    TextSize = 12,

    ShowIcons = true,
    ShowLabels = true,

    PaddingTop = 10,
    PaddingLeft = 7,
    PaddingRight = 7,

    CornerRadius = 6,
}

--// Mobile support settings
-- Actual mobile logic belongs in core/mobile.lua.
-- These values are read by the Settings tab.

Config.Mobile = {
    Enabled = true,

    Responsive = true,
    TouchEnabled = true,

    DraggableWindow = true,
    ShowMobileToggle = true,

    ScaleOnDesktop = false,

    ReferenceWidth = 620,
    ReferenceHeight = 420,

    MinimumScale = 0.55,
    MaximumScale = 1.00,

    ScreenPadding = 12,
    DragThreshold = 4,

    ToggleWidth = 120,
    ToggleHeight = 44,

    KeepWindowOnScreen = true,

    AllowMouseDragging = true,
    AllowTouchDragging = true,

    ScrollableMenus = true,
    TouchFriendlyButtons = true,

    MobileButtonHeight = 42,
    MobileButtonSpacing = 8,

    MobileSidebarWidth = 95,
    MobileTextSize = 12,

    CloseButtonEnabled = true,
    ReopenButtonEnabled = true,
}

--// Window behavior
Config.Window = {
    Draggable = true,
    Resizable = false,

    CenterOnStart = true,
    RememberPosition = false,

    CloseOnOutsideClick = false,
    CloseOnEscape = false,

    MinimumVisiblePixels = 40,
}

--// Input
Config.Input = {
    MouseEnabled = true,
    TouchEnabled = true,

    KeyboardShortcutsEnabled = false,

    AllowTabSwitching = true,
    AllowButtonActivation = true,
}

--// Settings tab
Config.Settings = {
    Enabled = true,

    ShowInterfaceSettings = true,
    ShowThemeSettings = true,
    ShowMobileSettings = true,

    ShowAnimationSettings = true,
    ShowResetButton = true,

    SaveSettings = false,
    AutoSave = false,
}

--// Visual settings for an owned Roblox Studio experience
Config.Visuals = {
    Enabled = true,

    Brightness = {
        Enabled = false,
        Value = 2,
        Minimum = 0,
        Maximum = 10,
    },

    ClockTime = {
        Enabled = false,
        Value = 14,
        Minimum = 0,
        Maximum = 24,
    },

    Fog = {
        Enabled = false,
        EndDistance = 100000,
        Minimum = 100,
        Maximum = 100000,
    },

    ColorCorrection = {
        Enabled = false,

        Brightness = 0,
        Contrast = 0,
        Saturation = 0,

        MinimumBrightness = -1,
        MaximumBrightness = 1,

        MinimumContrast = -1,
        MaximumContrast = 1,

        MinimumSaturation = -1,
        MaximumSaturation = 1,
    },

    Highlight = {
        Enabled = false,

        FillColor = Color3.fromRGB(255, 156, 6),
        OutlineColor = Color3.fromRGB(255, 255, 255),

        FillTransparency = 0.75,
        OutlineTransparency = 0,
    },
}

--// Scroll behavior
Config.Scrolling = {
    Enabled = true,

    ScrollBarThickness = 3,

    AutomaticCanvasSize = true,

    ScrollbarColor = Color3.fromRGB(100, 100, 115),

    SmoothScrolling = true,
}

--// Notifications
Config.Notifications = {
    Enabled = true,

    Duration = 3,

    Position = "BottomRight",

    SuccessEnabled = true,
    WarningEnabled = true,
    ErrorEnabled = true,
}

--// Performance
Config.Performance = {
    UpdateInterval = 0.1,

    OptimizeMobile = true,

    ReduceAnimationsOnMobile = true,

    MaximumConnections = 100,
}

--// Development
Config.Development = {
    PrintStartupMessage = true,
    PrintModuleErrors = true,

    WarnOnMissingModules = true,
    StrictModuleLoading = false,
}

--// Utility functions

function Config.Get(section, key)
    local Section = Config[section]

    if type(Section) ~= "table" then
        return nil
    end

    if key == nil then
        return Section
    end

    return Section[key]
end

function Config.Set(section, key, value)
    local Section = Config[section]

    if type(Section) ~= "table" then
        return false
    end

    if Section[key] == nil then
        return false
    end

    if typeof(Section[key]) ~= typeof(value) then
        return false
    end

    Section[key] = value

    return true
end

function Config.ResetSection(section)
    warn(
        "[r3xsense] ResetSection requires default values "
        .. "to restore a section safely: "
        .. tostring(section)
    )

    return false
end

function Config.IsMobileSupportEnabled()
    return Config.Mobile.Enabled == true
end

function Config.IsResponsiveEnabled()
    return Config.Mobile.Responsive == true
end

function Config.IsTouchEnabled()
    return Config.Mobile.TouchEnabled == true
end

function Config.GetWindowSize()
    return {
        Width = Config.UI.DefaultWidth,
        Height = Config.UI.DefaultHeight,
    }
end

function Config.GetTheme()
    return Config.Theme
end

function Config.GetMobileSettings()
    return Config.Mobile
end

return Config
