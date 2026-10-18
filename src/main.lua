--[[
    r3xsense
    File: src/main.lua
    Version: 1.0.0

    Main application controller
    Loads project modules and initializes the GUI.
]]

local Players = game:GetService("Players")

local App = {
    Name = "r3xsense",
    Version = "1.0.0",
    Running = false,
    Destroyed = false,

    Modules = {},
    Tabs = {},
    Connections = {},

    UI = {},

    State = {
        CurrentTab = "Settings",
        Visible = true,
    },
}

local Player = Players.LocalPlayer

if not Player then
    error("[r3xsense] This application must run on the client")
end

local PlayerGui = Player:WaitForChild("PlayerGui")

--// Connection management

function App:Connect(Signal, Callback)
    local Connection = Signal:Connect(Callback)

    table.insert(self.Connections, Connection)

    return Connection
end

function App:DisconnectAll()
    for _, Connection in ipairs(self.Connections) do
        if Connection.Connected then
            Connection:Disconnect()
        end
    end

    table.clear(self.Connections)
end

--// Module loading

function App:LoadModule(Name, ModuleScript)
    if not ModuleScript then
        warn("[r3xsense] Missing module: " .. Name)
        return nil
    end

    if not ModuleScript:IsA("ModuleScript") then
        warn("[r3xsense] Expected ModuleScript: " .. Name)
        return nil
    end

    local Success, Result = pcall(require, ModuleScript)

    if not Success then
        warn(
            "[r3xsense] Failed to load "
            .. Name
            .. ": "
            .. tostring(Result)
        )

        return nil
    end

    self.Modules[Name] = Result

    return Result
end

function App:LoadModules()
    local Source = script.Parent

    local CoreFolder = Source:FindFirstChild("core")
    local UIFolder = Source:FindFirstChild("ui")
    local UtilsFolder = Source:FindFirstChild("utils")
    local TabsFolder = Source:FindFirstChild("tabs")

    self:LoadModule(
        "Config",
        Source:FindFirstChild("config")
    )

    self:LoadModule(
        "Theme",
        UIFolder and UIFolder:FindFirstChild("theme")
    )

    self:LoadModule(
        "Components",
        UIFolder and UIFolder:FindFirstChild("components")
    )

    self:LoadModule(
        "Animations",
        UtilsFolder and UtilsFolder:FindFirstChild("animations")
    )

    self:LoadModule(
        "Mobile",
        CoreFolder and CoreFolder:FindFirstChild("mobile")
    )

    self:LoadModule(
        "Settings",
        TabsFolder and TabsFolder:FindFirstChild("settings")
    )

    self:LoadModule(
        "Visuals",
        TabsFolder and TabsFolder:FindFirstChild("visuals")
    )
end

--// Configuration

function App:GetConfig()
    return self.Modules.Config or {}
end

--// GUI construction

function App:CreateUI()
    local Config = self:GetConfig()
    local UIConfig = Config.UI or {}
    local Theme = Config.Theme or {}

    local ScreenGui = Instance.new("ScreenGui")

    ScreenGui.Name = "r3xsenseUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 10

    local MainFrame = Instance.new("Frame")

    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)

    MainFrame.Size = UDim2.fromOffset(
        UIConfig.DefaultWidth or 620,
        UIConfig.DefaultHeight or 420
    )

    MainFrame.BackgroundColor3 =
        Theme.Background or Color3.fromRGB(17, 17, 22)

    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = true
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")

    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")

    MainStroke.Color = Theme.Border
        or Color3.fromRGB(55, 55, 68)

    MainStroke.Thickness = UIConfig.BorderThickness or 1
    MainStroke.Parent = MainFrame

    --// Topbar

    local Topbar = Instance.new("Frame")

    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 40)

    Topbar.BackgroundColor3 =
        Theme.SecondaryBackground
        or Color3.fromRGB(23, 23, 30)

    Topbar.BorderSizePixel = 0
    Topbar.Parent = MainFrame

    local Title = Instance.new("TextLabel")

    Title.Name = "Title"
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.fromOffset(12, 0)
    Title.Size = UDim2.new(1, -24, 1, 0)

    Title.Font = UIConfig.BoldFont or Enum.Font.GothamBold
    Title.Text = UIConfig.Title or "r3xsense"
    Title.TextColor3 = Theme.Text or Color3.new(1, 1, 1)
    Title.TextSize = UIConfig.TitleSize or 17
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Topbar

    --// Separator

    local Separator = Instance.new("Frame")

    Separator.Name = "Separator"
    Separator.Position = UDim2.fromOffset(0, 40)
    Separator.Size = UDim2.new(1, 0, 0, 1)

    Separator.BackgroundColor3 =
        Theme.Border or Color3.fromRGB(55, 55, 68)

    Separator.BorderSizePixel = 0
    Separator.Parent = MainFrame

    --// Sidebar

    local Sidebar = Instance.new("Frame")

    Sidebar.Name = "Sidebar"
    Sidebar.Position = UDim2.fromOffset(0, 41)

    Sidebar.Size = UDim2.new(
        0,
        Config.Sidebar and Config.Sidebar.Width or 120,
        1,
        -41
    )

    Sidebar.BackgroundColor3 =
        Theme.SidebarBackground
        or Color3.fromRGB(20, 20, 26)

    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarPadding = Instance.new("UIPadding")

    SidebarPadding.PaddingTop = UDim.new(0, 10)
    SidebarPadding.PaddingLeft = UDim.new(0, 7)
    SidebarPadding.PaddingRight = UDim.new(0, 7)
    SidebarPadding.Parent = Sidebar

    local SidebarLayout = Instance.new("UIListLayout")

    SidebarLayout.Padding = UDim.new(
        0,
        Config.Sidebar and Config.Sidebar.ButtonSpacing or 5
    )

    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Parent = Sidebar

    --// Content container

    local SidebarWidth =
        Config.Sidebar and Config.Sidebar.Width or 120

    local Content = Instance.new("Frame")

    Content.Name = "Content"
    Content.Position = UDim2.new(0, SidebarWidth, 0, 41)

    Content.Size = UDim2.new(
        1,
        -SidebarWidth,
        1,
        -41
    )

    Content.BackgroundColor3 =
        Theme.Background or Color3.fromRGB(17, 17, 22)

    Content.BorderSizePixel = 0
    Content.ClipsDescendants = true
    Content.Parent = MainFrame

    local ContentPadding = Instance.new("UIPadding")

    ContentPadding.PaddingTop = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 10)
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.Parent = Content

    local PageLayout = Instance.new("UIPageLayout")

    PageLayout.Name = "PageLayout"
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.EasingStyle = Enum.EasingStyle.Quart
    PageLayout.EasingDirection = Enum.EasingDirection.Out
    PageLayout.TweenTime = 0.18
    PageLayout.Circular = false
    PageLayout.Parent = Content

    ScreenGui.Parent = PlayerGui

    self.UI = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        Topbar = Topbar,
        Title = Title,
        Sidebar = Sidebar,
        SidebarLayout = SidebarLayout,
        Content = Content,
        PageLayout = PageLayout,
    }

    return self.UI
end

--// Theme integration

function App:ApplyTheme()
    local Theme = self.Modules.Theme

    if not Theme then
        return
    end

    local ApplyFunction =
        Theme.Apply or Theme.Init

    if type(ApplyFunction) ~= "function" then
        return
    end

    local Success, ErrorMessage = pcall(function()
        ApplyFunction(self.UI, self)
    end)

    if not Success then
        warn(
            "[r3xsense] Theme error: "
            .. tostring(ErrorMessage)
        )
    end
end

--// Animation integration

function App:PlayAnimation(Object, Properties, Duration)
    local Animations = self.Modules.Animations

    if not Animations then
        return nil
    end

    if type(Animations.Tween) ~= "function" then
        return nil
    end

    return Animations.Tween(
        Object,
        Properties,
        Duration
    )
end

--// Tab construction

function App:CreateTab(Name, Order)
    if self.Tabs[Name] then
        return self.Tabs[Name]
    end

    local Config = self:GetConfig()
    local Theme = Config.Theme or {}
    local SidebarConfig = Config.Sidebar or {}

    local Page = Instance.new("ScrollingFrame")

    Page.Name = Name .. "Page"
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollingDirection = Enum.ScrollingDirection.Y
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new()
    Page.LayoutOrder = Order or 0
    Page.Visible = true
    Page.Parent = self.UI.Content

    local PageLayout = Instance.new("UIListLayout")

    PageLayout.Name = "PageLayout"
    PageLayout.Padding = UDim.new(0, 8)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Parent = Page

    local PagePadding = Instance.new("UIPadding")

    PagePadding.PaddingRight = UDim.new(0, 4)
    PagePadding.PaddingBottom = UDim.new(0, 4)
    PagePadding.Parent = Page

    local Button = Instance.new("TextButton")

    Button.Name = Name .. "Button"

    Button.Size = UDim2.new(
        1,
        0,
        0,
        SidebarConfig.ButtonHeight or 36
    )

    Button.BackgroundColor3 =
        Theme.ElementBackground
        or Color3.fromRGB(29, 29, 37)

    Button.BackgroundTransparency = 1
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.GothamMedium
    Button.Text = Name
    Button.TextColor3 =
        Theme.SecondaryText or Color3.fromRGB(155, 155, 170)

    Button.TextSize = SidebarConfig.TextSize or 12
    Button.LayoutOrder = Order or 0
    Button.Parent = self.UI.Sidebar

    local ButtonCorner = Instance.new("UICorner")

    ButtonCorner.CornerRadius = UDim.new(
        0,
        SidebarConfig.CornerRadius or 6
    )

    ButtonCorner.Parent = Button

    local Tab = {
        Name = Name,
        Page = Page,
        Button = Button,
        Layout = PageLayout,
        Order = Order or 0,
    }

    self.Tabs[Name] = Tab

    self:Connect(Button.Activated, function()
        self:SelectTab(Name)
    end)

    local Animations = self.Modules.Animations

    if Animations and type(Animations.ButtonHover) == "function" then
        pcall(function()
            Animations.ButtonHover(
                Button,
                Button.BackgroundColor3,
                Theme.ElementHover
            )
        end)
    end

    return Tab
end

--// Tab selection

function App:SelectTab(Name)
    local Tab = self.Tabs[Name]

    if not Tab then
        warn("[r3xsense] Unknown tab: " .. tostring(Name))
        return false
    end

    self.State.CurrentTab = Name

    local Config = self:GetConfig()
    local Theme = Config.Theme or {}

    for TabName, Entry in pairs(self.Tabs) do
        local Selected = TabName == Name

        Entry.Button.BackgroundTransparency =
            Selected and 0 or 1

        Entry.Button.BackgroundColor3 =
            Selected
            and (
                Theme.ElementActive
                or Color3.fromRGB(45, 45, 58)
            )
            or (
                Theme.ElementBackground
                or Color3.fromRGB(29, 29, 37)
            )

        Entry.Button.TextColor3 =
            Selected
            and (
                Theme.Text
                or Color3.fromRGB(240, 240, 245)
            )
            or (
                Theme.SecondaryText
                or Color3.fromRGB(155, 155, 170)
            )
    end

    local Success, ErrorMessage = pcall(function()
        self.UI.PageLayout:JumpTo(Tab.Page)
    end)

    if not Success then
        warn(
            "[r3xsense] Tab transition failed: "
            .. tostring(ErrorMessage)
        )

        for TabName, Entry in pairs(self.Tabs) do
            Entry.Page.Visible = TabName == Name
        end
    end

    return true
end

--// Initialize settings and visuals modules

function App:InitializeTabModule(ModuleName, TabName)
    local Module = self.Modules[ModuleName]
    local Tab = self.Tabs[TabName]

    if not Module or not Tab then
        warn(
            "[r3xsense] Cannot initialize "
            .. ModuleName
            .. ": module or tab missing"
        )

        return false
    end

    if type(Module.Init) ~= "function" then
        warn(
            "[r3xsense] "
            .. ModuleName
            .. " must export an Init function"
        )

        return false
    end

    local Success, ErrorMessage = pcall(function()
        Module.Init({
            App = self,
            Page = Tab.Page,
            Tab = Tab,
            UI = self.UI,
            Config = self:GetConfig(),
            Theme = self.Modules.Theme,
            Components = self.Modules.Components,
            Animations = self.Modules.Animations,
            Mobile = self.Modules.Mobile,
        })
    end)

    if not Success then
        warn(
            "[r3xsense] "
            .. ModuleName
            .. " initialization failed: "
            .. tostring(ErrorMessage)
        )

        return false
    end

    return true
end

--// Mobile initialization

function App:InitializeMobile()
    local Mobile = self.Modules.Mobile

    if not Mobile or type(Mobile.Init) ~= "function" then
        warn("[r3xsense] Mobile module unavailable")
        return false
    end

    local Config = self:GetConfig()

    local Success, Result = pcall(function()
        return Mobile.Init({
            ScreenGui = self.UI.ScreenGui,
            MainFrame = self.UI.MainFrame,
            DragHandle = self.UI.Topbar,
            Configuration = Config.Mobile or {},
        })
    end)

    if not Success then
        warn(
            "[r3xsense] Mobile initialization failed: "
            .. tostring(Result)
        )

        return false
    end

    return Result ~= false
end

--// Window visibility

function App:SetVisible(Visible)
    if self.Destroyed then
        return
    end

    Visible = Visible == true

    self.State.Visible = Visible

    local MainFrame = self.UI.MainFrame

    if MainFrame then
        MainFrame.Visible = Visible
    end
end

function App:Toggle()
    self:SetVisible(not self.State.Visible)
end

--// Runtime cleanup

function App:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    self.Running = false

    self:DisconnectAll()

    local Mobile = self.Modules.Mobile

    if Mobile and type(Mobile.Destroy) == "function" then
        pcall(function()
            Mobile.Destroy()
        end)
    end

    local Animations = self.Modules.Animations

    if Animations and type(Animations.Cleanup) == "function" then
        pcall(function()
            Animations.Cleanup()
        end)
    end

    local ScreenGui = self.UI.ScreenGui

    if ScreenGui then
        ScreenGui:Destroy()
    end

    table.clear(self.Tabs)
    table.clear(self.Modules)
    table.clear(self.UI)
end

--// Startup

function App:Start()
    if self.Running or self.Destroyed then
        return false
    end

    self:LoadModules()

    self:CreateUI()
    self:ApplyTheme()

    self:CreateTab("Settings", 1)
    self:CreateTab("Visuals", 2)

    self:InitializeTabModule("Settings", "Settings")
    self:InitializeTabModule("Visuals", "Visuals")

    self:InitializeMobile()

    self:SelectTab("Settings")

    self.Running = true

    print(
        "[r3xsense] "
        .. self.Name
        .. " v"
        .. self.Version
        .. " initialized"
    )

    return true
end

--// Launch

App:Start()

return App
