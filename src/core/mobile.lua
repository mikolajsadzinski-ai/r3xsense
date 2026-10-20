--[[
    r3xsense
    File: src/core/mobile.lua
    Version: 1.1.0

    Mobile support module for Roblox Studio.

    Features:
    - Responsive UI scaling
    - Touch and mouse dragging
    - Mobile visibility toggle
    - Viewport change detection
    - Screen boundary handling
    - Runtime configuration updates
    - Connection cleanup
]]

local Mobile = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

Mobile.Version = "1.1.0"
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

local function RegisterConnection(Connection)
    if Connection then
        table.insert(Mobile.Connections, Connection)
    end

    return Connection
end

local function DisconnectAllConnections()
    for _, Connection in ipairs(Mobile.Connections) do
        pcall(function()
            Connection:Disconnect()
        end)
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

    if Camera then
        return Camera.ViewportSize
    end

    local Player = Players.LocalPlayer
    local PlayerGui = Player and Player:FindFirstChildOfClass("PlayerGui")

    if PlayerGui then
        local Size = PlayerGui.AbsoluteSize

        if Size.X > 0 and Size.Y > 0 then
            return Vector2.new(Size.X, Size.Y)
        end
    end

    return Vector2.new(800, 600)
end

local function GetSafeViewportSize()
    local Viewport = GetViewportSize()

    local Success, TopLeft, BottomRight = pcall(function()
        return GuiService:GetGuiInset()
    end)

    if Success and TopLeft and BottomRight then
        return Vector2.new(
            math.max(1, Viewport.X - TopLeft.X - BottomRight.X),
            math.max(1, Viewport.Y - TopLeft.Y - BottomRight.Y)
        )
    end

    return Viewport
end

local function DetectMobile()
    return UserInputService.TouchEnabled
        and not UserInputService.MouseEnabled
end

function Mobile.UpdateDeviceState()
    Mobile.State.IsMobile = DetectMobile()
    return Mobile.State.IsMobile
end

local function GetScaleForViewport(Viewport)
    local ReferenceWidth = math.max(
        1,
        tonumber(Mobile.Config.ReferenceWidth) or 620
    )

    local ReferenceHeight = math.max(
        1,
        tonumber(Mobile.Config.ReferenceHeight) or 420
    )

    local MinimumScale = math.clamp(
        tonumber(Mobile.Config.MinimumScale) or 0.55,
        0.25,
        1
    )

    local MaximumScale = math.clamp(
        tonumber(Mobile.Config.MaximumScale) or 1,
        MinimumScale,
        2
    )

    local WidthScale = Viewport.X / ReferenceWidth
    local HeightScale = Viewport.Y / ReferenceHeight

    return math.clamp(
        math.min(WidthScale, HeightScale, MaximumScale),
        MinimumScale,
        MaximumScale
    )
end

local function GetWindowSize()
    local Frame = Mobile.Objects.MainFrame

    if not IsValidGuiObject(Frame) then
        return Vector2.zero
    end

    -- AbsoluteSize represents the GUI's measured size.
    -- Do not multiply by UIScale a second time.
    return Frame.AbsoluteSize
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
    local WindowSize = GetWindowSize()

    local ScaleObject = Mobile.Objects.ScaleObject
    local Scale = 1

    if ScaleObject and ScaleObject.Parent then
        Scale = ScaleObject.Scale
    end

    local Width = WindowSize.X * Scale
    local Height = WindowSize.Y * Scale

    local Padding = math.max(
        0,
        tonumber(Mobile.Config.ScreenPadding) or 12
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
        Viewport.X - Width - Padding
    )

    local MaximumY = math.max(
        MinimumY,
        Viewport.Y - Height - Padding
    )

    Frame.Position = UDim2.fromOffset(
        math.clamp(CurrentX, MinimumX, MaximumX),
        math.clamp(CurrentY, MinimumY, MaximumY)
    )
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

    if not ScaleObject or not ScaleObject.Parent then
        ScaleObject = Instance.new("UIScale")
        ScaleObject.Name = "R3XMobileScale"
        ScaleObject.Scale = 1
        ScaleObject.Parent = Frame

        Mobile.Objects.ScaleObject = ScaleObject
    end

    Mobile.UpdateDeviceState()

    local Viewport = GetSafeViewportSize()
    local Scale = 1

    if Mobile.State.IsMobile or Mobile.Config.ScaleOnDesktop then
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
        ClampWindowPosition()
    end
end

function Mobile.SetTouchEnabled(Enabled)
    Mobile.Config.TouchEnabled = Enabled == true

    if not Mobile.Config.TouchEnabled then
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

    Mobile.Config.MinimumScale = math.clamp(Minimum, 0.25, 1)

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

    if not Width or not Height or Width <= 0 or Height <= 0 then
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
    Mobile.SetWindowVisible(not Mobile.State.WindowVisible)
end

local function CreateMobileToggle()
    local ScreenGui = Mobile.Objects.ScreenGui

    if not ScreenGui or not Mobile.Config.ShowMobileToggle then
        return nil
    end

    local Existing = ScreenGui:FindFirstChild("R3XMobileToggle")

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

    Button.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
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
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(75, 75, 90)
    Stroke.Thickness = 1
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
    elseif Toggle then
        Toggle.Visible = not Mobile.State.WindowVisible
    end
end

function Mobile.SetToggleText(Text)
    local Toggle = Mobile.Objects.MobileToggle

    if not Toggle or typeof(Text) ~= "string" then
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
    local Handle = Mobile.Objects.DragHandle

    if not IsValidGuiObject(Frame) then
        return false
    end

    if not IsValidGuiObject(Handle) then
        Handle = Frame
    end

    local Dragging = false
    local ActiveInput = nil
    local DragStart = nil
    local StartPosition = nil

    RegisterConnection(Handle.InputBegan:Connect(function(Input)
        if not Mobile.Config.Enabled
            or not Mobile.Config.DraggableWindow
            or not IsAllowedDragInput(Input) then
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
    end))

    RegisterConnection(UserInputService.InputChanged:Connect(function(Input)
        if not Dragging or not ActiveInput then
            return
        end

        local IsMouseMove =
            ActiveInput.UserInputType == Enum.UserInputType.MouseButton1
            and Input.UserInputType == Enum.UserInputType.MouseMovement

        local IsTouchMove =
            ActiveInput.UserInputType == Enum.UserInputType.Touch
            and Input == ActiveInput

        if not IsMouseMove and not IsTouchMove then
            return
        end

        local Delta = Input.Position - DragStart
        local Threshold = math.max(
            0,
            tonumber(Mobile.Config.DragThreshold) or 4
        )

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

    RegisterConnection(UserInputService.InputEnded:Connect(function(Input)
        if not Dragging or not ActiveInput then
            return
        end

        local SameInput = Input == ActiveInput

        local MouseReleased =
            ActiveInput.UserInputType == Enum.UserInputType.MouseButton1
            and Input.UserInputType == Enum.UserInputType.MouseButton1

        if SameInput or MouseReleased then
            Dragging = false
            ActiveInput = nil

            Mobile.State.IsDragging = false
            ClampWindowPosition()
        end
    end))

    return true
end

local function ConnectViewportChanges()
    local CameraConnection = nil

    local function ConnectCurrentCamera()
        if CameraConnection then
            CameraConnection:Disconnect()
            CameraConnection = nil
        end

        local Camera = GetCamera()

        if not Camera then
            return
        end

        CameraConnection = Camera:GetPropertyChangedSignal(
            "ViewportSize"
        ):Connect(function()
            Mobile.UpdateDeviceState()
            Mobile.UpdateScale()
        end)

        RegisterConnection(CameraConnection)

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
        local ExistingValue = Mobile.Config[Key]

        if ExistingValue ~= nil
            and typeof(Value) == typeof(ExistingValue) then
            Mobile.Config[Key] = Value
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

    if typeof(Options) ~= "table" then
        Options = {}
    end

    local ScreenGui = Options.ScreenGui
    local MainFrame = Options.MainFrame

    if not ScreenGui
        or not ScreenGui:IsA("ScreenGui") then
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

    if not Mobile.Config.Enabled then
        Mobile.Initialized = false
        return false
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
    local Toggle = Mobile.Objects.MobileToggle

    if ScaleObject then
        ScaleObject:Destroy()
    end

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
