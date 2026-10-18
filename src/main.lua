
--[[
    lettium - Main
    File: src/main.lua

    Connects:
      - config.lua
      - core/mobile.lua
      - ui/theme.lua
      - ui/components.lua
      - tabs/settings.lua
      - tabs/visuals.lua

    Intended for your own Roblox Studio experience.
]]

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// Local player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Main application
local App = {
    Name = "lettium",
    Version = "1.0.0",

    Running = false,
    Destroyed = false,

    Connections = {},
    Modules = {},
    Tabs = {},

    UI = {},
    State = {
        CurrentTab = "Settings",
        Visible = true,
    },
}

--// Safe module loader
local function LoadModule(name, moduleScript)
    if not moduleScript then
        warn("[lettium] Missing module:", name)
        return nil
    end

    local success, result = pcall(require, moduleScript)

    if not success then
        warn("[lettium] Failed to load " .. name .. ": " .. tostring(result))
        return nil
    end

    App.Modules[name] = result
    return result
end

--// Find a ModuleScript by path
local function FindModule(parent, name)
    if not parent then
        return nil
    end

    local result = parent:FindFirstChild(name)

    if not result then
        warn("[lettium] ModuleScript not found:", name)
    end

    return result
end

--// Register connections for cleanup
function App:Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.Connections, connection)
    return connection
end

--// Load project modules
function App:LoadModules()
    local source = script.Parent
    local coreFolder = source:FindFirstChild("core")
    local uiFolder = source:FindFirstChild("ui")
    local tabsFolder = source:FindFirstChild("tabs")

    self.Modules.Config = LoadModule(
        "Config",
        FindModule(source, "config")
    )

    self.Modules.Theme = LoadModule(
        "Theme",
        FindModule(uiFolder, "theme")
    )

    self.Modules.Components = LoadModule(
        "Components",
        FindModule(uiFolder, "components")
    )

    self.Modules.Mobile = LoadModule(
        "Mobile",
        FindModule(coreFolder, "mobile")
    )

    self.Modules.Settings = LoadModule(
        "Settings",
        FindModule(tabsFolder, "settings")
    )

    self.Modules.Visuals = LoadModule(
        "Visuals",
        FindModule(tabsFolder, "visuals")
    )
end

--// Read configuration safely
function App:GetConfig()
    return self.Modules.Config or {}
end

--// Create base GUI
function App:CreateUI()
    local config = self:GetConfig()
    local uiConfig = config.UI or {}

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "lettiumUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.Size = UDim2.fromOffset(
        uiConfig.DefaultWidth or 340,
        uiConfig.DefaultHeight or 400
    )
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = 0.25
    stroke.Parent = mainFrame

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 38)
    topbar.BorderSizePixel = 0
    topbar.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(12, 0)
    title.Size = UDim2.new(1, -24, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = tostring(uiConfig.Title or self.Name)
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topbar

    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Position = UDim2.new(0, 0, 0, 38)
    separator.Size = UDim2.new(1, 0, 0, 1)
    separator.BorderSizePixel = 0
    separator.Parent = mainFrame

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Position = UDim2.fromOffset(0, 39)
    sidebar.Size = UDim2.new(0, 105, 1, -39)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 5)
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Parent = sidebar

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 8)
    sidebarPadding.PaddingLeft = UDim.new(0, 6)
    sidebarPadding.PaddingRight = UDim.new(0, 6)
    sidebarPadding.Parent = sidebar

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.new(0, 105, 0, 39)
    content.Size = UDim2.new(1, -105, 1, -39)
    content.BorderSizePixel = 0
    content.Parent = mainFrame

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 10)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.PaddingLeft = UDim.new(0, 10)
    contentPadding.PaddingRight = UDim.new(0, 10)
    contentPadding.Parent = content

    local pageLayout = Instance.new("UIPageLayout")
    pageLayout.Name = "PageLayout"
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.EasingStyle = Enum.EasingStyle.Quad
    pageLayout.EasingDirection = Enum.EasingDirection.Out
    pageLayout.TweenTime = 0.18
    pageLayout.Parent = content

    screenGui.Parent = PlayerGui

    self.UI.ScreenGui = screenGui
    self.UI.MainFrame = mainFrame
    self.UI.Topbar = topbar
    self.UI.Title = title
    self.UI.Sidebar = sidebar
    self.UI.Content = content
    self.UI.PageLayout = pageLayout

    return self.UI
end

--// Apply theme when the theme module supports it
function App:ApplyTheme()
    local theme = self.Modules.Theme

    if not theme then
        return
    end

    local success, err = pcall(function()
        if type(theme.Apply) == "function" then
            theme.Apply(self.UI, self)
        elseif type(theme.Init) == "function" then
            theme.Init(self.UI, self)
        end
    end)

    if not success then
        warn("[lettium] Theme error:", err)
    end
end

--// Create a tab page
function App:CreateTab(name, order)
    if self.Tabs[name] then
        return self.Tabs[name]
    end

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new()
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.LayoutOrder = order or 0
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.Parent = self.UI.Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingRight = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.Parent = page

    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(1, 0, 0, 32)
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamMedium
    button.Text = name
    button.TextSize = 12
    button.LayoutOrder = order or 0
    button.Parent = self.UI.Sidebar

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 5)
    tabCorner.Parent = button

    local tab = {
        Name = name,
        Page = page,
        Button = button,
        Layout = layout,
    }

    self.Tabs[name] = tab

    self:Connect(button.Activated, function()
        self:SelectTab(name)
    end)

    return tab
end

--// Select tab
function App:SelectTab(name)
    local tab = self.Tabs[name]

    if not tab then
        warn("[lettium] Unknown tab:", name)
        return false
    end

    self.State.CurrentTab = name

    for tabName, entry in pairs(self.Tabs) do
        entry.Button:SetAttribute("Selected", tabName == name)
    end

    self.UI.PageLayout:JumpTo(tab.Page)

    local theme = self.Modules.Theme
    if theme and type(theme.SelectTab) == "function" then
        pcall(theme.SelectTab, name, self)
    end

    return true
end

--// Initialize tab modules that expose Init
function App:InitializeTabModule(moduleName, tabName)
    local module = self.Modules[moduleName]
    local tab = self.Tabs[tabName]

    if not module or not tab then
        return false
    end

    local success, err = pcall(function()
        if type(module.Init) == "function" then
            module.Init({
                App = self,
                Page = tab.Page,
                Tab = tab,
                UI = self.UI,
                Config = self:GetConfig(),
                Theme = self.Modules.Theme,
                Components = self.Modules.Components,
            })
        end
    end)

    if not success then
        warn("[lettium] " .. moduleName .. " initialization failed:", err)
        return false
    end

    return true
end

--// Connect mobile module
function App:InitializeMobile()
    local mobile = self.Modules.Mobile

    if not mobile then
        warn("[lettium] Mobile module unavailable.")
        return
    end

    local success, err = pcall(function()
        if type(mobile.Init) == "function" then
            mobile.Init({
                ScreenGui = self.UI.ScreenGui,
                MainFrame = self.UI.MainFrame,
                DragHandle = self.UI.Topbar,
                App = self,
                Config = self:GetConfig(),
            })
        end
    end)

    if not success then
        warn("[lettium] Mobile initialization failed:", err)
    end
end

--// Toggle visibility
function App:SetVisible(visible)
    if self.Destroyed or not self.UI.MainFrame then
        return
    end

    self.State.Visible = visible == true
    self.UI.MainFrame.Visible = self.State.Visible
end

function App:Toggle()
    self:SetVisible(not self.State.Visible)
end

--// Cleanup
function App:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    self.Running = false

    for _, connection in ipairs(self.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end

    table.clear(self.Connections)

    local mobile = self.Modules.Mobile
    if mobile and type(mobile.Destroy) == "function" then
        pcall(mobile.Destroy)
    end

    if self.UI.ScreenGui then
        self.UI.ScreenGui:Destroy()
    end

    table.clear(self.Tabs)
end

--// Start application
function App:Start()
    if self.Running or self.Destroyed then
        return
    end

    self:LoadModules()
    self:CreateUI()
    self:ApplyTheme()

    -- Create the pages before initializing their modules.
    self:CreateTab("Settings", 1)
    self:CreateTab("Visuals", 2)

    self:InitializeTabModule("Settings", "Settings")
    self:InitializeTabModule("Visuals", "Visuals")
    self:InitializeMobile()

    self:SelectTab("Settings")

    self.Running = true
    print("[lettium] " .. self.Name .. " v" .. self.Version .. " started.")
end

--// Start
App:Start()

--// Return app object for other ModuleScripts
return App
