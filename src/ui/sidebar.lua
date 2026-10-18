
local Theme = require(script.Parent.theme)

local Sidebar = {}

local TABS = {
    {
        Name = "Ragebot",
        Icon = "",
    },
    {
        Name = "Legit",
        Icon = "",
    },
    {
        Name = "Visuals",
        Icon = "",
    },
    {
        Name = "Settings",
        Icon = "",
    },
    {
        Name = "Misc",
        Icon = "",
    },
    {
        Name = "Configs",
        Icon = "",
    },
}

function Sidebar.Create(parent, onTabSelected)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 58, 1, 0)
    sidebar.Position = UDim2.new(0, 0, 0, 0)
    sidebar.BackgroundColor3 = Theme.Colors.Background
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Parent = parent

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.Name = "SidebarPadding"
    sidebarPadding.PaddingTop = UDim.new(0, 12)
    sidebarPadding.PaddingBottom = UDim.new(0, 12)
    sidebarPadding.PaddingLeft = UDim.new(0, 8)
    sidebarPadding.PaddingRight = UDim.new(0, 8)
    sidebarPadding.Parent = sidebar

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Name = "SidebarLayout"
    sidebarLayout.FillDirection = Enum.FillDirection.Vertical
    sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 8)
    sidebarLayout.Parent = sidebar

    local buttons = {}
    local selectedTab = nil

    local function updateButtonAppearance(tabName, button)
        local isSelected = tabName == selectedTab

        if isSelected then
            button.BackgroundColor3 = Theme.Colors.AccentDark
            button.ImageColor3 = Theme.Colors.Accent
        else
            button.BackgroundColor3 = Theme.Colors.Background
            button.ImageColor3 = Theme.Colors.Muted
        end
    end

    local function selectTab(tabName)
        local tabExists = false

        for _, tab in ipairs(TABS) do
            if tab.Name == tabName then
                tabExists = true
                break
            end
        end

        if not tabExists then
            return
        end

        selectedTab = tabName

        for name, button in pairs(buttons) do
            updateButtonAppearance(name, button)
        end

        if typeof(onTabSelected) == "function" then
            onTabSelected(tabName)
        end
    end

    for index, tab in ipairs(TABS) do
        local button = Instance.new("ImageButton")
        button.Name = tab.Name .. "Button"
        button.LayoutOrder = index
        button.Size = UDim2.new(0, 42, 0, 42)
        button.BackgroundColor3 = Theme.Colors.Background
        button.BackgroundTransparency = 0
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Image = tab.Icon
        button.ImageColor3 = Theme.Colors.Muted
        button.ImageTransparency = 0
        button.ScaleType = Enum.ScaleType.Fit
        button.Active = true
        button.Selectable = true
        button.Parent = sidebar

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.Name = "ButtonCorner"
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Name = "ButtonStroke"
        buttonStroke.Color = Theme.Colors.Border
        buttonStroke.Thickness = 1
        buttonStroke.Transparency = 1
        buttonStroke.Parent = button

        local iconPadding = Instance.new("UIPadding")
        iconPadding.Name = "IconPadding"
        iconPadding.PaddingTop = UDim.new(0, 10)
        iconPadding.PaddingBottom = UDim.new(0, 10)
        iconPadding.PaddingLeft = UDim.new(0, 10)
        iconPadding.PaddingRight = UDim.new(0, 10)
        iconPadding.Parent = button

        buttons[tab.Name] = button

        button.Activated:Connect(function()
            selectTab(tab.Name)
        end)

        button.MouseEnter:Connect(function()
            if selectedTab ~= tab.Name then
                button.BackgroundColor3 = Theme.Colors.Panel
                buttonStroke.Transparency = 0.5
            end
        end)

        button.MouseLeave:Connect(function()
            updateButtonAppearance(tab.Name, button)
            buttonStroke.Transparency = 1
        end)
    end

    selectTab("Ragebot")

    return sidebar, selectTab, buttons
end

function Sidebar.GetTabs()
    local tabNames = {}

    for index, tab in ipairs(TABS) do
        tabNames[index] = tab.Name
    end

    return tabNames
end

function Sidebar.GetSelectedTab()
    return selectedTab
end

return Sidebar
