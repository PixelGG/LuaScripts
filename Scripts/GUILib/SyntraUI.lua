--[[
    SyntraUI.lua
    Professional single-file Roblox UILib

    Design thesis:
    Dark fantasy / retro terminal materials, restrained brass-violet accent,
    strong spacing, readable controls, and quiet motion.
]]

local SyntraUI = {}
SyntraUI.__index = SyntraUI
SyntraUI.Version = "6.0.0"

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local SyntraFolder = "SyntraUI"

--// Executor
local Executor = { Name = "Unknown", Version = "" }
do
    if identifyexecutor then
        local ok, name, version = pcall(identifyexecutor)
        if ok then
            Executor.Name = name or Executor.Name
            Executor.Version = version or ""
        end
    end
end

--// Theme tokens
local Theme = {
    Background = Color3.fromRGB(9, 10, 14),
    Surface = Color3.fromRGB(18, 18, 24),
    SurfaceAlt = Color3.fromRGB(24, 23, 31),
    Elevated = Color3.fromRGB(31, 29, 40),
    Field = Color3.fromRGB(13, 14, 20),

    Accent = Color3.fromRGB(177, 137, 68),
    AccentAlt = Color3.fromRGB(132, 94, 194),
    AccentSoft = Color3.fromRGB(54, 41, 28),
    AccentGlow = Color3.fromRGB(238, 195, 112),

    Border = Color3.fromRGB(72, 66, 80),
    BorderSoft = Color3.fromRGB(42, 40, 50),
    Shadow = Color3.fromRGB(0, 0, 0),

    Text = Color3.fromRGB(237, 232, 218),
    TextMuted = Color3.fromRGB(165, 158, 145),
    TextDim = Color3.fromRGB(103, 97, 91),

    Success = Color3.fromRGB(77, 190, 140),
    Warning = Color3.fromRGB(232, 177, 74),
    Error = Color3.fromRGB(224, 91, 91),
    Info = Color3.fromRGB(126, 172, 232),

    Font = Enum.Font.Gotham,
    FontMedium = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontMono = Enum.Font.Code,
}

local Metrics = {
    Radius = 8,
    RadiusSmall = 6,
    Padding = 12,
    Gap = 8,
    ControlHeight = 42,
    ControlTall = 58,
    Sidebar = 190,
    Topbar = 52,
    Footer = 24,
}

--// Utilities
local Util = {}

function Util.Safe(fn, ...)
    if type(fn) ~= "function" then return true end
    local ok, result = pcall(fn, ...)
    if not ok then
        warn("[SyntraUI] Callback error: " .. tostring(result))
    end
    return ok, result
end

function Util.Tween(obj, props, duration, style, direction)
    if not obj then return nil end
    local ok, tween = pcall(function()
        return TweenService:Create(
            obj,
            TweenInfo.new(duration or 0.16, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
            props
        )
    end)
    if ok and tween then
        tween:Play()
        return tween
    end
    return nil
end

function Util.New(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        pcall(function()
            obj[key] = value
        end)
    end
    if parent then obj.Parent = parent end
    return obj
end

function Util.Corner(parent, radius)
    return Util.New("UICorner", { CornerRadius = UDim.new(0, radius or Metrics.Radius) }, parent)
end

function Util.Stroke(parent, color, transparency, thickness)
    return Util.New("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0.35,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

function Util.Padding(parent, allOrTop, right, bottom, left)
    if right == nil then
        right, bottom, left = allOrTop, allOrTop, allOrTop
    end
    return Util.New("UIPadding", {
        PaddingTop = UDim.new(0, allOrTop or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
    }, parent)
end

function Util.List(parent, padding, horizontal)
    return Util.New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or Metrics.Gap),
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, parent)
end

function Util.Scale(parent, minSize, maxSize)
    return Util.New("UISizeConstraint", {
        MinSize = minSize or Vector2.new(340, 280),
        MaxSize = maxSize or Vector2.new(980, 720),
    }, parent)
end

function Util.Text(parent, props)
    props = props or {}
    return Util.New("TextLabel", {
        BackgroundTransparency = 1,
        Font = props.Font or Theme.Font,
        Text = tostring(props.Text or ""),
        TextColor3 = props.Color or Theme.Text,
        TextSize = props.Size or 13,
        TextTransparency = props.Transparency or 0,
        TextXAlignment = props.X or Enum.TextXAlignment.Left,
        TextYAlignment = props.Y or Enum.TextYAlignment.Center,
        TextWrapped = props.Wrapped or false,
        TextTruncate = props.Truncate or Enum.TextTruncate.AtEnd,
        RichText = props.RichText or false,
        Size = props.BoxSize or UDim2.new(1, 0, 0, 18),
        Position = props.Position or UDim2.fromOffset(0, 0),
        ZIndex = props.ZIndex or 1,
    }, parent)
end

function Util.Button(parent, props)
    props = props or {}
    return Util.New("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = props.BackgroundColor3 or Theme.Elevated,
        BackgroundTransparency = props.BackgroundTransparency or 0,
        BorderSizePixel = 0,
        Font = props.Font or Theme.FontMedium,
        Text = props.Text or "",
        TextColor3 = props.TextColor3 or Theme.Text,
        TextSize = props.TextSize or 13,
        TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
        Size = props.Size or UDim2.new(1, 0, 0, Metrics.ControlHeight),
        Position = props.Position or UDim2.fromOffset(0, 0),
        ZIndex = props.ZIndex or 1,
    }, parent)
end

function Util.Highlight(button, surface, stroke)
    button.MouseEnter:Connect(function()
        Util.Tween(surface, { BackgroundColor3 = Theme.SurfaceAlt }, 0.12)
        if stroke then Util.Tween(stroke, { Transparency = 0.12, Color = Theme.Accent }, 0.12) end
    end)
    button.MouseLeave:Connect(function()
        Util.Tween(surface, { BackgroundColor3 = Theme.Surface }, 0.14)
        if stroke then Util.Tween(stroke, { Transparency = 0.42, Color = Theme.Border }, 0.14) end
    end)
end

function Util.Ripple(parent, x, y)
    if not parent then return end
    local size = parent.AbsoluteSize
    local pos = parent.AbsolutePosition
    local rx = x and (x - pos.X) or size.X * 0.5
    local ry = y and (y - pos.Y) or size.Y * 0.5
    local ripple = Util.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(rx, ry),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Theme.AccentGlow,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        ZIndex = (parent.ZIndex or 1) + 4,
    }, parent)
    Util.Corner(ripple, 999)
    local target = math.max(size.X, size.Y) * 2
    Util.Tween(ripple, {
        Size = UDim2.fromOffset(target, target),
        BackgroundTransparency = 1,
    }, 0.42, Enum.EasingStyle.Quad)
    task.delay(0.45, function()
        if ripple and ripple.Parent then ripple:Destroy() end
    end)
end

function Util.MakeDraggable(frame, handle)
    local dragging = false
    local dragStart, startOffset
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        dragStart = input.Position
        startOffset = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local delta = input.Position - dragStart
        local x = math.clamp(startOffset.X + delta.X, 8, math.max(8, viewport.X - frame.AbsoluteSize.X - 8))
        local y = math.clamp(startOffset.Y + delta.Y, 8, math.max(8, viewport.Y - 48))
        frame.Position = UDim2.fromOffset(x, y)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return CoreGui
end

local function ensureFolder(path)
    if not isfolder or not makefolder then return false end
    local current = ""
    for _, part in ipairs(string.split(path, "/")) do
        current = current == "" and part or (current .. "/" .. part)
        if not isfolder(current) then
            makefolder(current)
        end
    end
    return true
end

local function normalizeOptions(value)
    if type(value) ~= "table" then return {} end
    return value
end

local function keyName(value)
    if typeof(value) == "EnumItem" then return value.Name end
    return tostring(value or "None")
end

local function resolveKey(value)
    if typeof(value) == "EnumItem" then return value end
    if type(value) == "string" and Enum.KeyCode[value] then return Enum.KeyCode[value] end
    return Enum.KeyCode.RightControl
end

local function formatValue(value)
    if type(value) == "number" then
        return tostring(math.floor(value * 100 + 0.5) / 100)
    end
    return tostring(value)
end

--// Notifications
local NotificationGui
local NotificationList
local NotificationIcons = {
    Info = "i",
    Success = "OK",
    Warning = "!",
    Error = "X",
}

local function ensureNotifications()
    if NotificationList and NotificationList.Parent then return end
    local parent = getGuiParent()
    local old = parent:FindFirstChild("SyntraUI_Notifications")
    if old then old:Destroy() end

    NotificationGui = Util.New("ScreenGui", {
        Name = "SyntraUI_Notifications",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 90,
    }, parent)

    NotificationList = Util.New("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(330, 520),
        BackgroundTransparency = 1,
    }, NotificationGui)
    Util.List(NotificationList, 8)
    local layout = NotificationList:FindFirstChildOfClass("UIListLayout")
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
end

function SyntraUI:Notify(options)
    options = normalizeOptions(options)
    ensureNotifications()

    local title = options.Title or "SyntraUI"
    local content = options.Content or options.Text or ""
    local kind = options.Type or "Info"
    local duration = tonumber(options.Duration) or 4
    local accent = Theme[kind] or Theme.Info

    local card = Util.New("Frame", {
        Size = UDim2.new(1, 0, 0, content ~= "" and 78 or 58),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(36, 0),
    }, NotificationList)
    Util.Corner(card, 8)
    Util.Stroke(card, Theme.Border, 0.22)

    Util.New("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
    }, card)

    local icon = Util.New("Frame", {
        Position = UDim2.fromOffset(15, 13),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
    }, card)
    Util.Corner(icon, 6)
    Util.Text(icon, {
        Text = NotificationIcons[kind] or "i",
        Font = Theme.FontBold,
        Size = 11,
        BoxSize = UDim2.new(1, 0, 1, 0),
        X = Enum.TextXAlignment.Center,
        Color = Color3.fromRGB(18, 15, 12),
    })

    Util.Text(card, {
        Text = title,
        Font = Theme.FontBold,
        Size = 13,
        Position = UDim2.fromOffset(50, 10),
        BoxSize = UDim2.new(1, -64, 0, 20),
    })
    if content ~= "" then
        Util.Text(card, {
            Text = content,
            Size = 12,
            Color = Theme.TextMuted,
            Wrapped = true,
            Position = UDim2.fromOffset(50, 32),
            BoxSize = UDim2.new(1, -64, 0, 34),
        })
    end

    local progress = Util.New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 3, 1, 0),
        Size = UDim2.new(1, -3, 0, 2),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
    }, card)

    Util.Tween(card, { Position = UDim2.fromOffset(0, 0) }, 0.28, Enum.EasingStyle.Back)
    Util.Tween(progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if not (card and card.Parent) then return end
        Util.Tween(card, { Position = UDim2.fromOffset(42, 0), BackgroundTransparency = 1 }, 0.22)
        task.delay(0.24, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)
end

--// Window
function SyntraUI:CreateWindow(options)
    options = normalizeOptions(options)
    local title = options.Title or options.Name or "SyntraUI"
    local subtitle = options.Subtitle or "Professional Roblox UI"
    local keybind = resolveKey(options.ToggleKey or options.Keybind or Enum.KeyCode.RightControl)
    local closeExisting = options.CloseExisting ~= false
    local size = options.Size or UDim2.fromOffset(860, 560)
    local minSize = options.MinSize or Vector2.new(420, 320)
    local maxSize = options.MaxSize or Vector2.new(1040, 720)

    local parent = getGuiParent()
    if closeExisting then
        local old = parent:FindFirstChild("SyntraUI_Window")
        if old then old:Destroy() end
    end

    local screenGui = Util.New("ScreenGui", {
        Name = options.GuiName or "SyntraUI_Window",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = options.DisplayOrder or 50,
    }, parent)

    local main = Util.New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = options.Position or UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, screenGui)
    Util.Corner(main, 10)
    local mainStroke = Util.Stroke(main, Theme.Border, 0.12)
    Util.Scale(main, minSize, maxSize)

    local shadow = Util.New("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = main.Position,
        Size = UDim2.fromOffset(42, 42),
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = Theme.Shadow,
        ImageTransparency = 0.45,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        ZIndex = 0,
    }, screenGui)

    local function syncShadow()
        if not (shadow and shadow.Parent) then return end
        shadow.Position = main.Position
        shadow.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset + 42, main.Size.Y.Scale, main.Size.Y.Offset + 42)
    end

    local runeLine = Util.New("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, main)

    local sidebar = Util.New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, Metrics.Sidebar, 1, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, main)
    Util.New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.BorderSoft,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, sidebar)

    local brand = Util.New("Frame", {
        Name = "Brand",
        Size = UDim2.new(1, 0, 0, Metrics.Topbar),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, sidebar)

    local sigil = Util.New("Frame", {
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = Theme.AccentSoft,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, brand)
    Util.Corner(sigil, 7)
    Util.Stroke(sigil, Theme.Accent, 0.2)
    Util.Text(sigil, {
        Text = tostring(title):sub(1, 1):upper(),
        Font = Theme.FontBold,
        Size = 15,
        Color = Theme.AccentGlow,
        X = Enum.TextXAlignment.Center,
        BoxSize = UDim2.new(1, 0, 1, 0),
        ZIndex = 6,
    })

    Util.Text(brand, {
        Text = title,
        Font = Theme.FontBold,
        Size = 15,
        Position = UDim2.fromOffset(52, 10),
        BoxSize = UDim2.new(1, -62, 0, 18),
        ZIndex = 5,
    })
    Util.Text(brand, {
        Text = subtitle,
        Size = 11,
        Color = Theme.TextDim,
        Position = UDim2.fromOffset(52, 29),
        BoxSize = UDim2.new(1, -62, 0, 16),
        ZIndex = 5,
    })

    local tabsList = Util.New("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(10, Metrics.Topbar + 8),
        Size = UDim2.new(1, -20, 1, -(Metrics.Topbar + Metrics.Footer + 18)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 4,
    }, sidebar)
    Util.List(tabsList, 6)

    Util.Text(sidebar, {
        Text = "v" .. SyntraUI.Version .. "  |  " .. keyName(keybind),
        Font = Theme.FontMono,
        Size = 10,
        Color = Theme.TextDim,
        Position = UDim2.new(0, 12, 1, -Metrics.Footer),
        BoxSize = UDim2.new(1, -24, 0, Metrics.Footer),
        ZIndex = 5,
    })

    local topbar = Util.New("Frame", {
        Name = "Topbar",
        Position = UDim2.fromOffset(Metrics.Sidebar, 0),
        Size = UDim2.new(1, -Metrics.Sidebar, 0, Metrics.Topbar),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, main)

    local pageTitle = Util.Text(topbar, {
        Text = "Dashboard",
        Font = Theme.FontBold,
        Size = 16,
        Position = UDim2.fromOffset(18, 9),
        BoxSize = UDim2.new(1, -120, 0, 21),
        ZIndex = 4,
    })
    local pageSubtitle = Util.Text(topbar, {
        Text = "Choose a tab to begin.",
        Size = 11,
        Color = Theme.TextMuted,
        Position = UDim2.fromOffset(18, 29),
        BoxSize = UDim2.new(1, -120, 0, 16),
        ZIndex = 4,
    })

    local function titleButton(text, xOffset)
        local btn = Util.Button(topbar, {
            Text = text,
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(1, xOffset, 0, 12),
            BackgroundColor3 = Theme.SurfaceAlt,
            TextSize = 14,
            ZIndex = 6,
        })
        Util.Corner(btn, 7)
        Util.Stroke(btn, Theme.Border, 0.35)
        btn.MouseEnter:Connect(function() Util.Tween(btn, { BackgroundColor3 = Theme.Elevated }, 0.1) end)
        btn.MouseLeave:Connect(function() Util.Tween(btn, { BackgroundColor3 = Theme.SurfaceAlt }, 0.12) end)
        return btn
    end

    local minimizeButton = titleButton("-", -70)
    local closeButton = titleButton("x", -36)

    local content = Util.New("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(Metrics.Sidebar, Metrics.Topbar),
        Size = UDim2.new(1, -Metrics.Sidebar, 1, -Metrics.Topbar),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
    }, main)

    local window = {
        ScreenGui = screenGui,
        Main = main,
        Tabs = {},
        CurrentTab = nil,
        Closed = false,
        Minimized = false,
        ToggleKey = keybind,
    }

    local function updateResponsive()
        local width = main.AbsoluteSize.X
        local side = width < 620 and 150 or Metrics.Sidebar
        sidebar.Size = UDim2.new(0, side, 1, 0)
        topbar.Position = UDim2.fromOffset(side, 0)
        topbar.Size = UDim2.new(1, -side, 0, Metrics.Topbar)
        content.Position = UDim2.fromOffset(side, Metrics.Topbar)
        content.Size = UDim2.new(1, -side, 1, -Metrics.Topbar)
    end

    local function setVisible(visible)
        if window.Closed then return end
        screenGui.Enabled = visible
        window.Visible = visible
    end

    function window:SetVisible(visible)
        setVisible(visible)
    end

    function window:Toggle()
        setVisible(not screenGui.Enabled)
    end

    function window:Minimize()
        if self.Minimized then
            self.Minimized = false
            content.Visible = true
            sidebar.Visible = true
            topbar.Position = UDim2.fromOffset(Metrics.Sidebar, 0)
            topbar.Size = UDim2.new(1, -Metrics.Sidebar, 0, Metrics.Topbar)
            Util.Tween(main, { Size = size }, 0.24, Enum.EasingStyle.Quart)
            task.delay(0.24, updateResponsive)
        else
            self.Minimized = true
            content.Visible = false
            sidebar.Visible = false
            topbar.Position = UDim2.fromOffset(0, 0)
            topbar.Size = UDim2.new(1, 0, 0, Metrics.Topbar)
            local minimizedWidth = main.AbsoluteSize.X > 0 and math.min(420, main.AbsoluteSize.X) or 420
            Util.Tween(main, { Size = UDim2.fromOffset(minimizedWidth, Metrics.Topbar) }, 0.22)
        end
    end

    function window:Close()
        self.Closed = true
        Util.Tween(main, { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.24, function()
            if screenGui and screenGui.Parent then screenGui:Destroy() end
        end)
    end

    function window:SetToggleKey(newKey)
        self.ToggleKey = resolveKey(newKey)
    end

    function window:Notify(notifyOptions)
        return SyntraUI:Notify(notifyOptions)
    end

    minimizeButton.MouseButton1Click:Connect(function()
        window:Minimize()
    end)
    closeButton.MouseButton1Click:Connect(function()
        window:Close()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or window.Closed then return end
        if input.KeyCode == window.ToggleKey then
            window:Toggle()
        end
    end)

    Util.MakeDraggable(main, topbar)
    main:GetPropertyChangedSignal("Position"):Connect(syncShadow)
    main:GetPropertyChangedSignal("Size"):Connect(syncShadow)
    task.defer(syncShadow)

    local function makePage()
        local page = Util.New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(16, 12),
            Size = UDim2.new(1, -32, 1, -24),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ClipsDescendants = false,
            ZIndex = 3,
        }, content)
        Util.List(page, 9)
        return page
    end

    local function controlFrame(parent, height)
        local frame = Util.New("Frame", {
            Size = UDim2.new(1, 0, 0, height or Metrics.ControlHeight),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 4,
        }, parent)
        Util.Corner(frame, Metrics.Radius)
        local stroke = Util.Stroke(frame, Theme.Border, 0.42)
        return frame, stroke
    end

    local function controlTitle(frame, name, desc, rightSpace)
        local tall = desc and desc ~= ""
        local titlePosition = tall and UDim2.fromOffset(12, 8) or UDim2.fromOffset(12, 0)
        local titleSize = tall and UDim2.new(1, -(rightSpace or 100), 0, 18) or UDim2.new(1, -(rightSpace or 100), 1, 0)
        Util.Text(frame, {
            Text = name,
            Font = Theme.FontMedium,
            Size = 13,
            Position = titlePosition,
            BoxSize = titleSize,
            ZIndex = 6,
        })
        if tall then
            Util.Text(frame, {
                Text = desc,
                Size = 11,
                Color = Theme.TextMuted,
                Position = UDim2.fromOffset(12, 29),
                BoxSize = UDim2.new(1, -(rightSpace or 100), 0, 17),
                ZIndex = 6,
            })
        end
    end

    local function buildInputRow(parent, opts)
        opts = opts or {}
        local height = opts.Desc and Metrics.ControlTall or Metrics.ControlHeight
        local frame, stroke = controlFrame(parent, height)
        controlTitle(frame, opts.Name or "Control", opts.Desc, opts.RightSpace or 130)
        return frame, stroke
    end

    function window:SelectTab(tab)
        if self.CurrentTab == tab then return end
        for _, item in ipairs(self.Tabs) do
            item.Page.Visible = item == tab
            Util.Tween(item.Button, {
                BackgroundColor3 = item == tab and Theme.AccentSoft or Theme.Surface,
                TextColor3 = item == tab and Theme.AccentGlow or Theme.TextMuted,
            }, 0.14)
            if item.Marker then
                Util.Tween(item.Marker, { BackgroundTransparency = item == tab and 0 or 1 }, 0.14)
            end
        end
        self.CurrentTab = tab
        pageTitle.Text = tab.Name
        pageSubtitle.Text = tab.Desc or "Ready."
    end

    function window:CreateTab(tabOpts)
        tabOpts = type(tabOpts) == "table" and tabOpts or { Name = tostring(tabOpts or "Tab") }
        local tab = {
            Name = tabOpts.Name or tabOpts.Title or "Tab",
            Desc = tabOpts.Desc or tabOpts.Subtitle or "",
            Page = makePage(),
            Window = window,
        }

        tab.Button = Util.Button(tabsList, {
            Text = "  " .. tab.Name,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.Surface,
            TextColor3 = Theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        })
        Util.Corner(tab.Button, 7)
        Util.Stroke(tab.Button, Theme.BorderSoft, 0.55)
        tab.Marker = Util.New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 18),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 7,
        }, tab.Button)
        Util.Corner(tab.Marker, 3)

        tab.Button.MouseButton1Click:Connect(function()
            window:SelectTab(tab)
        end)
        tab.Button.MouseEnter:Connect(function()
            if window.CurrentTab ~= tab then
                Util.Tween(tab.Button, { BackgroundColor3 = Theme.SurfaceAlt }, 0.1)
            end
        end)
        tab.Button.MouseLeave:Connect(function()
            if window.CurrentTab ~= tab then
                Util.Tween(tab.Button, { BackgroundColor3 = Theme.Surface }, 0.12)
            end
        end)

        function tab:AddSection(name)
            local section = Util.New("Frame", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                ZIndex = 4,
            }, self.Page)
            Util.Text(section, {
                Text = tostring(name or "Section"),
                Font = Theme.FontBold,
                Size = 12,
                Color = Theme.AccentGlow,
                Position = UDim2.fromOffset(2, 6),
                BoxSize = UDim2.new(1, -12, 0, 18),
                ZIndex = 5,
            })
            Util.New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 2),
                Size = UDim2.new(1, -140, 0, 1),
                BackgroundColor3 = Theme.BorderSoft,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, section)
            return section
        end

        tab.CreateSection = tab.AddSection

        function tab:AddDivider()
            return Util.New("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.BorderSoft,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, self.Page)
        end

        function tab:AddLabel(text)
            local label = Util.Text(self.Page, {
                Text = tostring(text or "Label"),
                Size = 13,
                Color = Theme.TextMuted,
                BoxSize = UDim2.new(1, 0, 0, 24),
                ZIndex = 4,
            })
            return {
                Instance = label,
                Set = function(_, value) label.Text = tostring(value or "") end,
                SetText = function(_, value) label.Text = tostring(value or "") end,
                Get = function() return label.Text end,
            }
        end

        function tab:AddParagraph(pOpts)
            pOpts = type(pOpts) == "table" and pOpts or { Text = tostring(pOpts or "") }
            local frame, stroke = controlFrame(self.Page, pOpts.Height or 74)
            Util.Text(frame, {
                Text = pOpts.Title or pOpts.Name or "Paragraph",
                Font = Theme.FontBold,
                Size = 13,
                Position = UDim2.fromOffset(12, 9),
                BoxSize = UDim2.new(1, -24, 0, 18),
                ZIndex = 5,
            })
            local body = Util.Text(frame, {
                Text = pOpts.Content or pOpts.Text or "",
                Size = 12,
                Color = Theme.TextMuted,
                Wrapped = true,
                Position = UDim2.fromOffset(12, 31),
                BoxSize = UDim2.new(1, -24, 1, -38),
                ZIndex = 5,
            })
            return {
                Instance = frame,
                Set = function(_, value) body.Text = tostring(value or "") end,
                SetText = function(_, value) body.Text = tostring(value or "") end,
            }
        end

        function tab:AddButton(bOpts)
            bOpts = normalizeOptions(bOpts)
            local frame, stroke = buildInputRow(self.Page, {
                Name = bOpts.Name or "Button",
                Desc = bOpts.Desc or bOpts.Description,
                RightSpace = 112,
            })
            local button = Util.Button(frame, {
                Text = bOpts.ButtonText or "Run",
                Size = UDim2.fromOffset(86, 28),
                Position = UDim2.new(1, -98, 0.5, -14),
                BackgroundColor3 = Theme.AccentSoft,
                TextColor3 = Theme.AccentGlow,
                ZIndex = 7,
            })
            Util.Corner(button, 7)
            Util.Stroke(button, Theme.Accent, 0.35)
            Util.Highlight(button, frame, stroke)
            button.MouseButton1Click:Connect(function(x, y)
                Util.Ripple(frame, x, y)
                Util.Safe(bOpts.Callback)
            end)
            return {
                Instance = frame,
                Button = button,
                SetName = function(_, value) bOpts.Name = tostring(value or "") end,
            }
        end

        function tab:AddToggle(tOpts)
            tOpts = normalizeOptions(tOpts)
            local value = tOpts.Default == true
            local frame, stroke = buildInputRow(self.Page, {
                Name = tOpts.Name or "Toggle",
                Desc = tOpts.Desc or tOpts.Description,
                RightSpace = 92,
            })
            local track = Util.New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.fromOffset(50, 24),
                BackgroundColor3 = Theme.Field,
                BorderSizePixel = 0,
                ZIndex = 7,
            }, frame)
            Util.Corner(track, 999)
            Util.Stroke(track, Theme.Border, 0.32)
            local knob = Util.New("Frame", {
                Position = UDim2.fromOffset(3, 3),
                Size = UDim2.fromOffset(18, 18),
                BackgroundColor3 = Theme.TextDim,
                BorderSizePixel = 0,
                ZIndex = 8,
            }, track)
            Util.Corner(knob, 999)

            local hit = Util.Button(frame, { Text = "", BackgroundTransparency = 1, ZIndex = 10 })
            local api = {}

            local function render(skipCallback)
                Util.Tween(track, {
                    BackgroundColor3 = value and Theme.AccentSoft or Theme.Field,
                }, 0.16)
                Util.Tween(knob, {
                    Position = value and UDim2.fromOffset(29, 3) or UDim2.fromOffset(3, 3),
                    BackgroundColor3 = value and Theme.AccentGlow or Theme.TextDim,
                }, 0.16)
                if not skipCallback then Util.Safe(tOpts.Callback, value) end
            end

            hit.MouseButton1Click:Connect(function()
                value = not value
                render(false)
            end)
            hit.MouseEnter:Connect(function() Util.Tween(frame, { BackgroundColor3 = Theme.SurfaceAlt }, 0.12) end)
            hit.MouseLeave:Connect(function() Util.Tween(frame, { BackgroundColor3 = Theme.Surface }, 0.12) end)

            function api:Set(newValue, silent)
                value = newValue == true
                render(silent)
            end
            function api:Get()
                return value
            end
            api.Instance = frame
            render(true)
            return api
        end

        function tab:AddSlider(sOpts)
            sOpts = normalizeOptions(sOpts)
            local min = tonumber(sOpts.Min or sOpts.Minimum) or 0
            local max = tonumber(sOpts.Max or sOpts.Maximum) or 100
            local step = tonumber(sOpts.Step or sOpts.Increment) or 1
            local value = math.clamp(tonumber(sOpts.Default) or min, min, max)
            local frame, stroke = buildInputRow(self.Page, {
                Name = sOpts.Name or "Slider",
                Desc = sOpts.Desc or sOpts.Description,
                RightSpace = 102,
            })
            frame.Size = UDim2.new(1, 0, 0, (sOpts.Desc or sOpts.Description) and 70 or 56)

            local valueLabel = Util.Text(frame, {
                Text = formatValue(value),
                Font = Theme.FontMono,
                Size = 12,
                Color = Theme.AccentGlow,
                X = Enum.TextXAlignment.Right,
                Position = UDim2.new(1, -92, 0, 9),
                BoxSize = UDim2.fromOffset(78, 18),
                ZIndex = 6,
            })
            local bar = Util.New("Frame", {
                Position = UDim2.new(0, 12, 1, -19),
                Size = UDim2.new(1, -24, 0, 6),
                BackgroundColor3 = Theme.Field,
                BorderSizePixel = 0,
                ZIndex = 6,
            }, frame)
            Util.Corner(bar, 999)
            local fill = Util.New("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 7,
            }, bar)
            Util.Corner(fill, 999)

            local dragging = false
            local api = {}

            local function roundToStep(v)
                if step <= 0 then return v end
                return math.floor((v - min) / step + 0.5) * step + min
            end

            local function setFromAlpha(alpha, silent)
                value = math.clamp(roundToStep(min + (max - min) * math.clamp(alpha, 0, 1)), min, max)
                local pct = (value - min) / math.max(max - min, 0.0001)
                valueLabel.Text = formatValue(value)
                Util.Tween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.08)
                if not silent then Util.Safe(sOpts.Callback, value) end
            end

            local function setFromInput(input)
                local alpha = (input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
                setFromAlpha(alpha, false)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromInput(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromInput(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            function api:Set(newValue, silent)
                local alpha = ((tonumber(newValue) or min) - min) / math.max(max - min, 0.0001)
                setFromAlpha(alpha, silent)
            end
            function api:Get()
                return value
            end
            api.Instance = frame
            setFromAlpha((value - min) / math.max(max - min, 0.0001), true)
            return api
        end

        function tab:AddTextBox(tbOpts)
            tbOpts = normalizeOptions(tbOpts)
            local frame, stroke = buildInputRow(self.Page, {
                Name = tbOpts.Name or "Input",
                Desc = tbOpts.Desc or tbOpts.Description,
                RightSpace = 190,
            })
            local box = Util.New("TextBox", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(170, 28),
                BackgroundColor3 = Theme.Field,
                BorderSizePixel = 0,
                ClearTextOnFocus = tbOpts.ClearTextOnFocus == true,
                Font = Theme.Font,
                PlaceholderText = tbOpts.Placeholder or "Type...",
                PlaceholderColor3 = Theme.TextDim,
                Text = tostring(tbOpts.Default or ""),
                TextColor3 = Theme.Text,
                TextSize = 12,
                ZIndex = 7,
            }, frame)
            Util.Corner(box, 7)
            Util.Stroke(box, Theme.Border, 0.4)

            box.Focused:Connect(function()
                Util.Tween(box, { BackgroundColor3 = Theme.Elevated }, 0.12)
            end)
            box.FocusLost:Connect(function(enterPressed)
                Util.Tween(box, { BackgroundColor3 = Theme.Field }, 0.12)
                if tbOpts.Callback and (enterPressed or tbOpts.CallbackOnChange ~= true) then
                    Util.Safe(tbOpts.Callback, box.Text, enterPressed)
                end
            end)
            if tbOpts.CallbackOnChange then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    Util.Safe(tbOpts.Callback, box.Text, false)
                end)
            end

            return {
                Instance = frame,
                Box = box,
                Set = function(_, value) box.Text = tostring(value or "") end,
                Get = function() return box.Text end,
            }
        end

        tab.AddInput = tab.AddTextBox
        tab.AddTextbox = tab.AddTextBox

        function tab:AddDropdown(ddOpts)
            ddOpts = normalizeOptions(ddOpts)
            local optionsList = ddOpts.Options or ddOpts.Values or {}
            local multi = ddOpts.Multi == true
            local selected = multi and {} or (ddOpts.Default or optionsList[1])
            local open = false
            local baseHeight = ddOpts.Desc and Metrics.ControlTall or Metrics.ControlHeight
            local frame, stroke = buildInputRow(self.Page, {
                Name = ddOpts.Name or "Dropdown",
                Desc = ddOpts.Desc or ddOpts.Description,
                RightSpace = 210,
            })
            frame.ClipsDescendants = false

            local display = Util.Button(frame, {
                Text = "",
                Size = UDim2.fromOffset(190, 28),
                Position = UDim2.new(1, -202, 0.5, -14),
                BackgroundColor3 = Theme.Field,
                ZIndex = 8,
            })
            Util.Corner(display, 7)
            Util.Stroke(display, Theme.Border, 0.38)
            local displayText = Util.Text(display, {
                Text = "",
                Size = 12,
                Color = Theme.TextMuted,
                Position = UDim2.fromOffset(9, 0),
                BoxSize = UDim2.new(1, -28, 1, 0),
                ZIndex = 9,
            })
            Util.Text(display, {
                Text = "v",
                Font = Theme.FontBold,
                Size = 12,
                Color = Theme.AccentGlow,
                X = Enum.TextXAlignment.Center,
                Position = UDim2.new(1, -24, 0, 0),
                BoxSize = UDim2.fromOffset(22, 28),
                ZIndex = 9,
            })

            local menu = Util.New("Frame", {
                Position = UDim2.new(1, -202, 0.5, 18),
                Size = UDim2.fromOffset(190, 0),
                BackgroundColor3 = Theme.Elevated,
                BorderSizePixel = 0,
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 20,
            }, frame)
            Util.Corner(menu, 7)
            Util.Stroke(menu, Theme.Border, 0.18)
            Util.List(menu, 2)
            Util.Padding(menu, 4)

            local api = {}

            local function refreshText()
                if multi then
                    local names = {}
                    for name, isSelected in pairs(selected) do
                        if isSelected then table.insert(names, name) end
                    end
                    table.sort(names)
                    displayText.Text = #names > 0 and table.concat(names, ", ") or "None"
                else
                    displayText.Text = selected and tostring(selected) or "Select..."
                end
            end

            local function setOpen(state)
                open = state
                menu.Visible = true
                local targetHeight = open and math.min(#optionsList * 30 + 8, 188) or 0
                Util.Tween(menu, { Size = UDim2.fromOffset(190, targetHeight) }, 0.16)
                task.delay(0.18, function()
                    if menu and menu.Parent then menu.Visible = open end
                end)
            end

            local function rebuild()
                for _, child in ipairs(menu:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, option in ipairs(optionsList) do
                    local text = tostring(option)
                    local item = Util.Button(menu, {
                        Text = "  " .. text,
                        Size = UDim2.new(1, -8, 0, 28),
                        BackgroundTransparency = 1,
                        TextColor3 = Theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 21,
                    })
                    Util.Corner(item, 6)
                    item.MouseEnter:Connect(function()
                        Util.Tween(item, { BackgroundTransparency = 0, BackgroundColor3 = Theme.SurfaceAlt, TextColor3 = Theme.Text }, 0.1)
                    end)
                    item.MouseLeave:Connect(function()
                        Util.Tween(item, { BackgroundTransparency = 1, TextColor3 = Theme.TextMuted }, 0.12)
                    end)
                    item.MouseButton1Click:Connect(function()
                        if multi then
                            selected[text] = not selected[text]
                            Util.Safe(ddOpts.Callback, api:Get(), text)
                        else
                            selected = text
                            setOpen(false)
                            Util.Safe(ddOpts.Callback, selected)
                        end
                        refreshText()
                    end)
                end
                refreshText()
            end

            display.MouseButton1Click:Connect(function()
                setOpen(not open)
            end)

            function api:Set(newValue, silent)
                if multi then
                    selected = {}
                    if type(newValue) == "table" then
                        for _, item in ipairs(newValue) do selected[tostring(item)] = true end
                        for key, val in pairs(newValue) do
                            if type(key) == "string" and val then selected[key] = true end
                        end
                    elseif newValue ~= nil then
                        selected[tostring(newValue)] = true
                    end
                else
                    selected = newValue
                end
                refreshText()
                if not silent then Util.Safe(ddOpts.Callback, api:Get()) end
            end
            function api:Get()
                if not multi then return selected end
                local values = {}
                for name, isSelected in pairs(selected) do
                    if isSelected then table.insert(values, name) end
                end
                table.sort(values)
                return values
            end
            function api:Refresh(newOptions, keepSelection)
                optionsList = newOptions or {}
                if not keepSelection then
                    selected = multi and {} or optionsList[1]
                end
                rebuild()
            end
            api.Instance = frame
            rebuild()
            return api
        end

        function tab:AddKeybind(kOpts)
            kOpts = normalizeOptions(kOpts)
            local value = resolveKey(kOpts.Default or kOpts.Key or Enum.KeyCode.RightControl)
            local listening = false
            local frame, stroke = buildInputRow(self.Page, {
                Name = kOpts.Name or "Keybind",
                Desc = kOpts.Desc or kOpts.Description,
                RightSpace = 126,
            })
            local button = Util.Button(frame, {
                Text = keyName(value),
                Size = UDim2.fromOffset(106, 28),
                Position = UDim2.new(1, -118, 0.5, -14),
                BackgroundColor3 = Theme.Field,
                TextColor3 = Theme.AccentGlow,
                ZIndex = 8,
            })
            Util.Corner(button, 7)
            Util.Stroke(button, Theme.Border, 0.38)

            button.MouseButton1Click:Connect(function()
                listening = true
                button.Text = "Press key"
            end)
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if listening then
                    if input.KeyCode ~= Enum.KeyCode.Unknown then
                        value = input.KeyCode
                        button.Text = keyName(value)
                        listening = false
                        Util.Safe(kOpts.Callback, value)
                    end
                    return
                end
                if not gameProcessed and input.KeyCode == value then
                    Util.Safe(kOpts.Pressed or kOpts.OnPressed)
                end
            end)

            return {
                Instance = frame,
                Set = function(_, newKey)
                    value = resolveKey(newKey)
                    button.Text = keyName(value)
                end,
                Get = function() return value end,
            }
        end

        function tab:AddColorPicker(cpOpts)
            cpOpts = normalizeOptions(cpOpts)
            local value = cpOpts.Default or Theme.Accent
            local frame, stroke = buildInputRow(self.Page, {
                Name = cpOpts.Name or "Color",
                Desc = cpOpts.Desc or cpOpts.Description,
                RightSpace = 80,
            })
            local swatch = Util.Button(frame, {
                Text = "",
                Size = UDim2.fromOffset(44, 28),
                Position = UDim2.new(1, -56, 0.5, -14),
                BackgroundColor3 = value,
                ZIndex = 8,
            })
            Util.Corner(swatch, 7)
            Util.Stroke(swatch, Theme.Border, 0.25)

            local palette = {
                Theme.Accent,
                Theme.AccentAlt,
                Theme.Success,
                Theme.Warning,
                Theme.Error,
                Theme.Info,
                Color3.fromRGB(235, 235, 220),
                Color3.fromRGB(32, 32, 38),
            }
            local index = 1
            swatch.MouseButton1Click:Connect(function()
                index = index % #palette + 1
                value = palette[index]
                swatch.BackgroundColor3 = value
                Util.Safe(cpOpts.Callback, value)
            end)

            return {
                Instance = frame,
                Set = function(_, newColor, silent)
                    if typeof(newColor) == "Color3" then
                        value = newColor
                        swatch.BackgroundColor3 = value
                        if not silent then Util.Safe(cpOpts.Callback, value) end
                    end
                end,
                Get = function() return value end,
            }
        end

        function tab:AddToggleGroup(tgOpts)
            tgOpts = normalizeOptions(tgOpts)
            local choices = tgOpts.Options or tgOpts.Values or {}
            local selected = tgOpts.Default or choices[1]
            local frame, stroke = controlFrame(self.Page, math.max(54, 32 + math.ceil(#choices / 3) * 34))
            Util.Text(frame, {
                Text = tgOpts.Name or "Options",
                Font = Theme.FontMedium,
                Size = 13,
                Position = UDim2.fromOffset(12, 8),
                BoxSize = UDim2.new(1, -24, 0, 18),
                ZIndex = 6,
            })
            local holder = Util.New("Frame", {
                Position = UDim2.fromOffset(12, 32),
                Size = UDim2.new(1, -24, 1, -40),
                BackgroundTransparency = 1,
                ZIndex = 6,
            }, frame)
            local grid = Util.New("UIGridLayout", {
                CellSize = UDim2.new(0.333, -6, 0, 28),
                CellPadding = UDim2.fromOffset(6, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, holder)

            local buttons = {}
            local api = {}
            local function render(silent)
                for name, button in pairs(buttons) do
                    local active = name == selected
                    Util.Tween(button, {
                        BackgroundColor3 = active and Theme.AccentSoft or Theme.Field,
                        TextColor3 = active and Theme.AccentGlow or Theme.TextMuted,
                    }, 0.12)
                end
                if not silent then Util.Safe(tgOpts.Callback, selected) end
            end
            for _, option in ipairs(choices) do
                local text = tostring(option)
                local button = Util.Button(holder, {
                    Text = text,
                    BackgroundColor3 = Theme.Field,
                    TextColor3 = Theme.TextMuted,
                    ZIndex = 8,
                })
                Util.Corner(button, 7)
                buttons[text] = button
                button.MouseButton1Click:Connect(function()
                    selected = text
                    render(false)
                end)
            end
            function api:Set(value, silent)
                selected = tostring(value)
                render(silent)
            end
            function api:Get()
                return selected
            end
            api.Instance = frame
            render(true)
            return api
        end

        table.insert(window.Tabs, tab)
        if not window.CurrentTab then
            window:SelectTab(tab)
        end
        return tab
    end

    window.AddTab = window.CreateTab

    Util.Tween(main, { Size = size }, 0.34, Enum.EasingStyle.Back)
    main:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsive)
    task.defer(updateResponsive)

    if options.Settings ~= false and options.AutoSettings == true then
        local settings = window:CreateTab({ Name = options.SettingsTabName or "Settings", Desc = "Window controls." })
        settings:AddKeybind({
            Name = "Toggle UI",
            Desc = "Press the selected key to show or hide the window.",
            Default = keybind,
            Callback = function(newKey)
                window:SetToggleKey(newKey)
            end,
        })
        settings:AddButton({
            Name = "Close UI",
            Desc = "Destroy this SyntraUI instance.",
            ButtonText = "Close",
            Callback = function()
                window:Close()
            end,
        })
    end

    return window
end

--// Loading screen
function SyntraUI:ShowLoadingScreen(options)
    options = normalizeOptions(options)
    local parent = getGuiParent()
    local gui = Util.New("ScreenGui", {
        Name = "SyntraUI_Loading",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 200,
    }, parent)

    local overlay = Util.New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, gui)
    Util.Tween(overlay, { BackgroundTransparency = 0.34 }, 0.24)

    local panel = Util.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    Util.Corner(panel, 10)
    Util.Stroke(panel, Theme.Border, 0.18)
    Util.New("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, panel)
    Util.Text(panel, {
        Text = options.Title or "SyntraUI",
        Font = Theme.FontBold,
        Size = 18,
        X = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(20, 34),
        BoxSize = UDim2.new(1, -40, 0, 26),
    })
    local status = Util.Text(panel, {
        Text = options.Subtitle or options.Status or "Loading...",
        Size = 12,
        Color = Theme.TextMuted,
        X = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(20, 64),
        BoxSize = UDim2.new(1, -40, 0, 20),
    })
    local barBack = Util.New("Frame", {
        Position = UDim2.fromOffset(28, 112),
        Size = UDim2.new(1, -56, 0, 7),
        BackgroundColor3 = Theme.Field,
        BorderSizePixel = 0,
    }, panel)
    Util.Corner(barBack, 999)
    local bar = Util.New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, barBack)
    Util.Corner(bar, 999)

    Util.Tween(panel, { Size = UDim2.fromOffset(330, 160) }, 0.32, Enum.EasingStyle.Back)

    local loader = {}
    function loader:SetStatus(text)
        status.Text = tostring(text or "")
    end
    function loader:SetProgress(value)
        value = math.clamp(tonumber(value) or 0, 0, 1)
        Util.Tween(bar, { Size = UDim2.new(value, 0, 1, 0) }, 0.18)
    end
    function loader:Close(fadeTime)
        fadeTime = fadeTime or 0.24
        Util.Tween(overlay, { BackgroundTransparency = 1 }, fadeTime)
        Util.Tween(panel, { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 }, fadeTime)
        task.delay(fadeTime + 0.04, function()
            if gui and gui.Parent then gui:Destroy() end
        end)
    end

    if options.Duration then
        Util.Tween(bar, { Size = UDim2.new(1, 0, 1, 0) }, options.Duration, Enum.EasingStyle.Linear)
        task.delay(options.Duration, function()
            if options.AutoClose ~= false then loader:Close() end
        end)
    end

    return loader
end

--// Config helpers
function SyntraUI:GetConfigPath(name)
    return SyntraFolder .. "/configs/" .. tostring(name or "default") .. ".json"
end

function SyntraUI:SaveConfig(name, data)
    if not writefile then return false, "writefile is not available" end
    ensureFolder(SyntraFolder .. "/configs")
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data or {})
    end)
    if not ok then return false, encoded end
    writefile(self:GetConfigPath(name), encoded)
    return true
end

function SyntraUI:LoadConfig(name, defaultData)
    if not (isfile and readfile) then return defaultData or {}, "readfile is not available" end
    local path = self:GetConfigPath(name)
    if not isfile(path) then return defaultData or {}, "config not found" end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok then return defaultData or {}, decoded end
    return decoded
end

function SyntraUI:CreateConfig(options)
    options = normalizeOptions(options)
    local cfg = {
        Name = options.Name or "default",
        Values = options.Defaults or {},
        Items = {},
    }

    function cfg:Register(key, control, defaultValue)
        self.Items[key] = control
        if self.Values[key] == nil then self.Values[key] = defaultValue end
        if control and control.Set and self.Values[key] ~= nil then control:Set(self.Values[key], true) end
        return control
    end

    function cfg:Get(key, defaultValue)
        local control = self.Items[key]
        if control and control.Get then
            local ok, value = pcall(function() return control:Get() end)
            if ok then return value end
        end
        if self.Values[key] ~= nil then return self.Values[key] end
        return defaultValue
    end

    function cfg:Set(key, value)
        self.Values[key] = value
        local control = self.Items[key]
        if control and control.Set then control:Set(value, true) end
    end

    function cfg:Collect()
        local data = {}
        for key, value in pairs(self.Values) do data[key] = value end
        for key, control in pairs(self.Items) do
            if control and control.Get then
                local ok, value = pcall(function() return control:Get() end)
                if ok then data[key] = value end
            end
        end
        return data
    end

    function cfg:Save()
        return SyntraUI:SaveConfig(self.Name, self:Collect())
    end

    function cfg:Load()
        local data, err = SyntraUI:LoadConfig(self.Name, self.Values)
        self.Values = data or self.Values
        for key, value in pairs(self.Values) do
            local control = self.Items[key]
            if control and control.Set then control:Set(value, true) end
        end
        return self.Values, err
    end

    return cfg
end

--// Script loading / teleport helpers
function SyntraUI:BuildScriptSource(source)
    if type(source) ~= "string" then return nil, "source must be a string" end
    if source:match("^https?://") then
        return string.format([[
local url = %q
local req = request or http_request or (http and http.request) or (syn and syn.request) or (fluxus and fluxus.request)
local body
if req then
    local response = req({ Url = url, Method = "GET" })
    body = response and response.Body
else
    body = game:HttpGet(url)
end
assert(body and #body > 0, "SyntraUI failed to download script")
loadstring(body)()
]], source)
    end
    return source
end

function SyntraUI:LoadScript(source, options)
    options = normalizeOptions(options)
    local scriptSource, err = self:BuildScriptSource(source)
    if not scriptSource then return false, err end
    if options.QueueOnTeleport then
        self._autoLoadSource = scriptSource
        return self:QueueOnTeleport(self:BuildAutoLoadSource(scriptSource))
    end
    if not loadstring then return false, "loadstring is not available" end
    local fn, loadErr = loadstring(scriptSource)
    if not fn then return false, loadErr end
    return pcall(fn)
end

function SyntraUI:BuildAutoLoadSource(scriptSource)
    local template = [[
local source = %q
local template = %q
local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queue then queue(string.format(template, source, template)) end
local fn, err = loadstring(source)
if not fn then error(err) end
fn()
]]
    return string.format(template, scriptSource, template)
end

function SyntraUI:GetQueueOnTeleport()
    return queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
end

function SyntraUI:QueueOnTeleport(scriptSource)
    local queue = self:GetQueueOnTeleport()
    if not queue then return false, "queue_on_teleport is not available" end
    if type(scriptSource) ~= "string" then return false, "scriptSource must be a string" end
    queue(scriptSource)
    return true
end

function SyntraUI:SetAutoLoad(scriptSource)
    local source, err = self:BuildScriptSource(scriptSource)
    if not source then return false, err end
    self._autoLoadSource = source
    return self:QueueOnTeleport(self:BuildAutoLoadSource(source))
end

function SyntraUI:OnPlaceLoad(placeId, scriptSource)
    local numericPlaceId = tonumber(placeId)
    if not numericPlaceId then return false, "placeId must be a number" end
    local source, err = self:BuildScriptSource(scriptSource)
    if not source then return false, err end
    self._placeLoads = self._placeLoads or {}
    self._placeLoads[numericPlaceId] = source
    return self:QueuePlaceLoads()
end

function SyntraUI:RunPlaceLoad(placeId)
    local source = self._placeLoads and self._placeLoads[tonumber(placeId or game.PlaceId)]
    if source and loadstring then
        return loadstring(source)()
    end
end

function SyntraUI:BuildPlaceLoadSource()
    local template = [[
local placeLoadsSource = %q
local template = %q
local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queue then queue(string.format(template, placeLoadsSource, template)) end
local placeLoads = loadstring("return " .. placeLoadsSource)()
local source = placeLoads[game.PlaceId]
if source then loadstring(source)() end
]]
    local lines = { "{" }
    for placeId, source in pairs(self._placeLoads or {}) do
        table.insert(lines, string.format("[%d] = %q,", placeId, source))
    end
    table.insert(lines, "}")
    return string.format(template, table.concat(lines, "\n"), template)
end

function SyntraUI:QueuePlaceLoads()
    if not self._placeLoads then return false, "no place loads registered" end
    return self:QueueOnTeleport(self:BuildPlaceLoadSource())
end

function SyntraUI:GetExecutor()
    return Executor.Name, Executor.Version
end

function SyntraUI:IsPotassium()
    return string.lower(tostring(Executor.Name)):find("potassium", 1, true) ~= nil
end

function SyntraUI:CheckPotassium()
    if self:IsPotassium() then return true end
    return false, "SyntraUI is optimized for Potassium, current executor: " .. tostring(Executor.Name)
end

pcall(function()
    TeleportService.TeleportInitFailed:Connect(function()
        if SyntraUI._autoLoadSource then
            SyntraUI:QueueOnTeleport(SyntraUI:BuildAutoLoadSource(SyntraUI._autoLoadSource))
        end
    end)
end)

function SyntraUI:SetTheme(custom)
    if type(custom) ~= "table" then return end
    for key, value in pairs(custom) do
        if Theme[key] ~= nil then Theme[key] = value end
    end
end

function SyntraUI:GetTheme()
    return Theme
end

function SyntraUI:GetUtil()
    return Util
end

return SyntraUI
