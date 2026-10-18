--[[
    r3xsense
    File: src/core/mobile.lua

    Mobile support module

    Features:
    - Responsive interface scaling
    - Touch input support
    - Mouse input support
    - Draggable main window
    - Mobile toggle button
    - Viewport change detection
    - Screen boundary handling
    - Enable and disable individual features
    - Cleanup connections
    - Runtime configuration updates

    Designed for a Roblox Studio project.
]]

local Mobile = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

Mobile.Version = "1.0.0"
Mobile.Initialized = false

Mobile.Config = {
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

    TogglePosition = UDim2.new(1, -12, 0.5, 0),

    KeepWindowOnScreen = true,
    AllowMouseDragging = true,
    AllowTouchDragging = true,
}

Mobile.State = {
    IsMobile = false,
    IsDragging = false,
    WindowVisible = true,
    CurrentScale = 1,
}

Mobile.Objects = {
    ScreenGui = nil,
    MainFrame = nil,
    ScaleObject = nil,
    MobileToggle = nil,
    DragHandle = nil,
}

Mobile.Connections = {}
Mobile.OriginalProperties = {}

local function DisconnectConnection(Connection)
    if Connection then
        pcall(function()
            Connection:Disconnect()
        end)
    end
end

local function RegisterConnection(Connection)
    if Connection then
        table.insert(Mobile.Connections, Connection)
    end

    return Connection
end

local function DisconnectAllConnections()
    for _, Connection in ipairs(Mobile.Connections) do
        DisconnectConnection(Connection)
    end

    table.clear(Mobile.Connections)
end

local function IsValidGuiObject(Object)
    return typeof(Object) == "Instance"
        and Object:IsA("GuiObject")
        and Object.Parent ~= nil
end

local function GetCamera()
    return Workspace.CurrentCamera
end

local function GetViewportSize()
    local Camera = GetCamera()

    if not Camera then
        return Vector2.new(800, 600)
    end

    return Camera.ViewportSize
end

local function DetectMobile()
    local TouchAvailable = UserInputService.TouchEnabled
    local KeyboardAvailable = UserInputService.KeyboardEnabled
    local MouseAvailable = UserInputService.MouseEnabled

    if TouchAvailable and not KeyboardAvailable then
        return true
    end

    if TouchAvailable and not MouseAvailable then
        return true
    end

    return false
end

local function GetSafeViewportSize()
    local Viewport = GetViewportSize()

    local Success, Insets = pcall(function()
        return GuiService:GetGuiInset()
    end)

    if Success and Insets then
        return Vector2.new(
            Viewport.X,
            math.max(0, Viewport.Y - Insets.Y)
        )
    end

    return Viewport
end

local function GetScaleForViewport(Viewport)
    local ReferenceWidth = math.max(
        1,
        Mobile.Config.ReferenceWidth
    )

    local ReferenceHeight = math.max(
        1,
        Mobile.Config.ReferenceHeight
    )

    local WidthScale = Viewport.X / ReferenceWidth
    local HeightScale = Viewport.Y / ReferenceHeight

    local Result = math.min(
        WidthScale,
        HeightScale,
        Mobile.Config.MaximumScale
    )

    return math.clamp(
        Result,
        Mobile.Config.MinimumScale,
        Mobile.Config.MaximumScale
    )
end

local function GetScaledWindowSize()
    local Frame = Mobile.Objects.MainFrame

    if not IsValidGuiObject(Frame) then
        return Vector2.new(0, 0)
    end

    local AbsoluteSize = Frame.AbsoluteSize

    local ScaleObject = Mobile.Objects.ScaleObject
    local Scale = 1

    if ScaleObject and ScaleObject:IsA("UIScale") then
        Scale = ScaleObject.Scale
    end

    return Vector2.new(
        AbsoluteSize.X * Scale,
        AbsoluteSize.Y * Scale
    )
end

local function ClampWindowPosition()
    local Frame = Mobile.Objects.MainFrame

    if not IsValidGuiObject(Frame) then
        return
    end

    if not Mobile.Config.KeepWindowOnScreen then
        return
    end

    local Viewport = GetSafeViewportSize()
    local WindowSize = GetScaledWindowSize()

    local Padding = math.max(
        0,
        Mobile.Config.ScreenPadding
    )

    local Position = Frame.Position

    local CurrentX =
        Viewport.X * Position.X.Scale + Position.X.Offset

    local CurrentY =
        Viewport.Y * Position.Y.Scale + Position.Y.Offset

    local MinimumX = Padding
    local MinimumY = Padding

    local MaximumX = math.max(
        MinimumX,
        Viewport.X - WindowSize.X - Padding
    )

    local MaximumY = math.max(
        MinimumY,
        Viewport.Y - WindowSize.Y - Padding
    )

    local ClampedX = math.clamp(
        CurrentX,
        MinimumX,
        MaximumX
    )

    local ClampedY = math.clamp(
        CurrentY,
        MinimumY,
        MaximumY
    )

    Frame.Position = UDim2.fromOffset(
        ClampedX,
        ClampedY
    )
end

function Mobile.UpdateDeviceState()
    Mobile.State.IsMobile = DetectMobile()

    return Mobile.State.IsMobile
end

function Mobile.UpdateScale()
    if not Mobile.Config.Enabled then
        return
    end

    if not Mobile.Config.Responsive then
        return
    end

    local Frame = Mobile.Objects.MainFrame

    if not IsValidGuiObject(Frame) then
        return
    end

    local ScaleObject = Mobile.Objects.ScaleObject

    if not ScaleObject then
        ScaleObject = Instance.new("UIScale")
        ScaleObject.Name = "R3XMobileScale"
        ScaleObject.Parent = Frame

        Mobile.Objects.ScaleObject = ScaleObject
    end

    if not ScaleObject:IsA("UIScale") then
        warn("[r3xsense] ScaleObject must be a UIScale")
        return
    end

    local Viewport = GetSafeViewportSize()
    local IsMobile = Mobile.UpdateDeviceState()

    local Scale = 1

    if IsMobile or Mobile.Config.ScaleOnDesktop then
        Scale = GetScaleForViewport(Viewport)
    end

    ScaleObject.Scale = Scale
    Mobile.State.CurrentScale = Scale

    task.defer(function()
        if Mobile.Initialized then
            ClampWindowPosition()
        end
    end)
end

function Mobile.SetResponsive(Enabled)
    Mobile.Config.Responsive = Enabled == true

    if Mobile.Config.Responsive then
        Mobile.UpdateScale()
    else
        local ScaleObject = Mobile.Objects.ScaleObject

        if ScaleObject and ScaleObject.Parent then
            ScaleObject.Scale = 1
        end

        Mobile.State.CurrentScale = 1
    end
end

function Mobile.SetTouchEnabled(Enabled)
    Mobile.Config.TouchEnabled = Enabled == true

    if not Mobile.Config.TouchEnabled
        and Mobile.State.IsDragging then

        Mobile.State.IsDragging = false
    end
end

function Mobile.SetDraggable(Enabled)
    Mobile.Config.DraggableWindow = Enabled == true

    if not Mobile.Config.DraggableWindow then
        Mobile.State.IsDragging = false
    end
end

function Mobile.SetKeepWindowOnScreen(Enabled)
    Mobile.Config.KeepWindowOnScreen = Enabled == true

    if Mobile.Config.KeepWindowOnScreen then
        ClampWindowPosition()
    end
end

function Mobile.SetScaleLimits(Minimum, Maximum)
    Minimum = tonumber(Minimum)
    Maximum = tonumber(Maximum)

    if not Minimum or not Maximum then
        return false
    end

    if Minimum <= 0 or Maximum < Minimum then
        return false
    end

    Mobile.Config.MinimumScale = math.clamp(
        Minimum,
        0.25,
        1
    )

    Mobile.Config.MaximumScale = math.clamp(
        Maximum,
        Mobile.Config.MinimumScale,
        2
    )

    Mobile.UpdateScale()

    return true
end

function Mobile.SetReferenceSize(Width, Height)
    Width = tonumber(Width)
    Height = tonumber(Height)

    if not Width or not Height then
        return false
    end

    if Width <= 0 or Height <= 0 then
        return false
    end

    Mobile.Config.ReferenceWidth = Width
    Mobile.Config.ReferenceHeight = Height

    Mobile.UpdateScale()

    return true
end

function Mobile.SetWindowVisible(Visible)
    Visible = Visible == true

    Mobile.State.WindowVisible = Visible

    local Frame = Mobile.Objects.MainFrame
    local Toggle = Mobile.Objects.MobileToggle

    if IsValidGuiObject(Frame) then
        Frame.Visible = Visible
    end

    if Toggle and Toggle.Parent then
        Toggle.Visible =
            Mobile.Config.ShowMobileToggle and not Visible
    end
end

function Mobile.ToggleWindow()
    Mobile.SetWindowVisible(
        not Mobile.State.WindowVisible
    )
end

local function CreateMobileToggle()
    local ScreenGui = Mobile.Objects.ScreenGui

    if not ScreenGui then
        return nil
    end

    if not Mobile.Config.ShowMobileToggle then
        return nil
    end

    local Existing = ScreenGui:FindFirstChild(
        "R3XMobileToggle"
    )

    if Existing then
        Existing:Destroy()
    end

    local Button = Instance.new("TextButton")

    Button.Name = "R3XMobileToggle"
    Button.AnchorPoint = Vector2.new(1, 0.5)
    Button.Position = Mobile.Config.TogglePosition

    Button.Size = UDim2.fromOffset(
        Mobile.Config.ToggleWidth,
        Mobile.Config.ToggleHeight
    )

    Button.BackgroundColor3 =
        Color3.fromRGB(30, 30, 38)

    Button.BackgroundTransparency = 0.05
    Button.BorderSizePixel = 0

    Button.Text = "Open r3xsense"
    Button.TextColor3 = Color3.fromRGB(245, 245, 250)

    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold

    Button.AutoButtonColor = true
    Button.Active = true
    Button.Selectable = true

    Button.ZIndex = 100
    Button.Visible = not Mobile.State.WindowVisible
    Button.Parent = ScreenGui

    local Corner = Instance.new("UICorner")

    Corner.Name = "Corner"
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    local Stroke = Instance.new("UIStroke")

    Stroke.Name = "Stroke"
    Stroke.Color = Color3.fromRGB(75, 75, 90)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.15
    Stroke.Parent = Button

    RegisterConnection(Button.Activated:Connect(function()
        Mobile.SetWindowVisible(true)
    end))

    Mobile.Objects.MobileToggle = Button

    return Button
end

function Mobile.SetMobileToggleEnabled(Enabled)
    Mobile.Config.ShowMobileToggle = Enabled == true

    local Toggle = Mobile.Objects.MobileToggle

    if not Mobile.Config.ShowMobileToggle then
        if Toggle then
            Toggle:Destroy()
        end

        Mobile.Objects.MobileToggle = nil
        return
    end

    if not Toggle or not Toggle.Parent then
        CreateMobileToggle()
    end

    if Mobile.Objects.MobileToggle then
        Mobile.Objects.MobileToggle.Visible =
            not Mobile.State.WindowVisible
    end
end

function Mobile.SetToggleText(Text)
    local Toggle = Mobile.Objects.MobileToggle

    if not Toggle then
        return false
    end

    if typeof(Text) ~= "string" then
        return false
    end

    Toggle.Text = Text

    return true
end

function Mobile.SetTogglePosition(Position)
    if typeof(Position) ~= "UDim2" then
        return false
    end

    Mobile.Config.TogglePosition = Position

    local Toggle = Mobile.Objects.MobileToggle

    if Toggle then
        Toggle.Position = Position
    end

    return true
end

local function IsAllowedDragInput(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        return Mobile.Config.AllowMouseDragging
    end

    if Input.UserInputType == Enum.UserInputType.Touch then
        return Mobile.Config.AllowTouchDragging
            and Mobile.Config.TouchEnabled
    end

    return false
end

local function ConnectDragging()
    local Frame = Mobile.Objects.MainFrame

    if not IsValidGuiObject(Frame) then
        return false
    end

    local Handle = Mobile.Objects.DragHandle

    if not IsValidGuiObject(Handle) then
        Handle = Frame
    end

    local Dragging = false
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil
    local ActiveInput = nil

    RegisterConnection(Handle.InputBegan:Connect(function(Input)
        if not Mobile.Config.Enabled then
            return
        end

        if not Mobile.Config.DraggableWindow then
            return
        end

        if not IsAllowedDragInput(Input) then
            return
        end

        if Dragging then
            return
        end

        Dragging = true
        ActiveInput = Input
        DragStart = Input.Position
        StartPosition = Frame.Position

        Mobile.State.IsDragging = true

        RegisterConnection(Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                if ActiveInput == Input then
                    Dragging = false
                    ActiveInput = nil

                    Mobile.State.IsDragging = false

                    ClampWindowPosition()
                end
            end
        end))
    end))

    RegisterConnection(Handle.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement
            or Input.UserInputType == Enum.UserInputType.Touch then

            DragInput = Input
        end
    end))

    RegisterConnection(UserInputService.InputChanged:Connect(function(Input)
        if not Dragging then
            return
        end

        if Input ~= DragInput
            and Input ~= ActiveInput then
            return
        end

        if not StartPosition or not DragStart then
            return
        end

        local Delta = Input.Position - DragStart

        local Threshold = Mobile.Config.DragThreshold

        if Delta.Magnitude < Threshold then
            return
        end

        Frame.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end))

    return true
end

local function ConnectViewportChanges()
    local function ConnectCurrentCamera()
        local Camera = GetCamera()

        if not Camera then
            return
        end

        RegisterConnection(
            Camera:GetPropertyChangedSignal("ViewportSize"):Connect(
                function()
                    Mobile.UpdateDeviceState()
                    Mobile.UpdateScale()
                end
            )
        )

        Mobile.UpdateScale()
    end

    RegisterConnection(
        Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(
            ConnectCurrentCamera
        )
    )

    ConnectCurrentCamera()
end

function Mobile.ApplyConfiguration(Configuration)
    if typeof(Configuration) ~= "table" then
        return false
    end

    for Key, Value in pairs(Configuration) do
        if Mobile.Config[Key] ~= nil then
            local ExistingValue = Mobile.Config[Key]

            if typeof(Value) == typeof(ExistingValue) then
                Mobile.Config[Key] = Value
            end
        end
    end

    Mobile.UpdateDeviceState()
    Mobile.UpdateScale()

    Mobile.SetMobileToggleEnabled(
        Mobile.Config.ShowMobileToggle
    )

    return true
end

function Mobile.GetConfiguration()
    local Result = {}

    for Key, Value in pairs(Mobile.Config) do
        Result[Key] = Value
    end

    return Result
end

function Mobile.GetState()
    local Result = {}

    for Key, Value in pairs(Mobile.State) do
        Result[Key] = Value
    end

    return Result
end

function Mobile.Init(Options)
    if Mobile.Initialized then
        warn("[r3xsense] Mobile support is already initialized")
        return false
    end

    Options = Options or {}

    if typeof(Options) ~= "table" then
        warn("[r3xsense] Init expects a configuration table")
        return false
    end

    local ScreenGui = Options.ScreenGui
    local MainFrame = Options.MainFrame

    if not ScreenGui or not ScreenGui:IsA("ScreenGui") then
        warn("[r3xsense] Init requires a ScreenGui")
        return false
    end

    if not IsValidGuiObject(MainFrame) then
        warn("[r3xsense] Init requires a valid MainFrame")
        return false
    end

    Mobile.Objects.ScreenGui = ScreenGui
    Mobile.Objects.MainFrame = MainFrame

    Mobile.Objects.DragHandle =
        Options.DragHandle or MainFrame

    if Options.Configuration then
        Mobile.ApplyConfiguration(Options.Configuration)
    end

    Mobile.UpdateDeviceState()

    Mobile.State.WindowVisible = MainFrame.Visible

    Mobile.Initialized = true

    if Mobile.Config.ShowMobileToggle then
        CreateMobileToggle()
    end

    if Mobile.Config.Responsive then
        Mobile.UpdateScale()
    end

    if Mobile.Config.DraggableWindow then
        ConnectDragging()
    end

    ConnectViewportChanges()

    RegisterConnection(ScreenGui.Destroying:Connect(function()
        Mobile.Destroy()
    end))

    print(
        "[r3xsense] Mobile module initialized",
        "Mobile:",
        Mobile.State.IsMobile
    )

    return true
end

function Mobile.Destroy()
    DisconnectAllConnections()

    local ScaleObject = Mobile.Objects.ScaleObject

    if ScaleObject then
        ScaleObject:Destroy()
    end

    local Toggle = Mobile.Objects.MobileToggle

    if Toggle then
        Toggle:Destroy()
    end

    Mobile.Objects.ScreenGui = nil
    Mobile.Objects.MainFrame = nil
    Mobile.Objects.ScaleObject = nil
    Mobile.Objects.MobileToggle = nil
    Mobile.Objects.DragHandle = nil

    Mobile.State.IsDragging = false
    Mobile.State.WindowVisible = false
    Mobile.State.CurrentScale = 1

    Mobile.Initialized = false
end

return Mobile
