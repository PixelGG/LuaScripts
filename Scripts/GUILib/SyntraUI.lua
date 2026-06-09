-- ╔══════════════════════════════════════════════════════╗
-- ║   SyntraUI  v4.0  ·  Complete Rework                ║
-- ║   Potassium Edition  ·  by Lorthanyx                ║
-- ╚══════════════════════════════════════════════════════╝

local SyntraUI   = {}
SyntraUI.__index = SyntraUI

-- ══════════════════════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local SyntraLogoUrl = "https://raw.githubusercontent.com/PixelGG/LuaScripts/main/SyntraUI.png"
local SyntraBrandUrl = "https://raw.githubusercontent.com/PixelGG/LuaScripts/main/Syntra.png"
local SyntraFolder = "SyntraUI"

local Executor = {
    Name = "Unknown",
    Version = "",
}

do
    if identifyexecutor then
        local ok, name, version = pcall(identifyexecutor)
        if ok then
            Executor.Name = name or Executor.Name
            Executor.Version = version or ""
        end
    end
end

-- ══════════════════════════════════════════════════════
--  THEME  v5.0  Glassmorphism
-- ══════════════════════════════════════════════════════
local Theme = {
    -- Glass base backgrounds
    BgBase        = Color3.fromRGB(8,   10,  18),
    BgSurface     = Color3.fromRGB(16,  18,  30),
    BgCard        = Color3.fromRGB(22,  24,  40),
    BgElevated    = Color3.fromRGB(28,  30,  50),
    -- Legacy aliases (backwards-compat)
    Background    = Color3.fromRGB(8,   10,  18),
    Secondary     = Color3.fromRGB(16,  18,  30),
    Tertiary      = Color3.fromRGB(22,  24,  40),
    Elevated      = Color3.fromRGB(28,  30,  50),
    Surface       = Color3.fromRGB(20,  22,  36),
    -- Accent (indigo-violet)
    Accent        = Color3.fromRGB(118, 92,  255),
    AccentDark    = Color3.fromRGB(72,  52,  185),
    AccentGlow    = Color3.fromRGB(170, 148, 255),
    AccentSoft    = Color3.fromRGB(40,  32,  95),
    AccentLine    = Color3.fromRGB(118, 92,  255),
    -- Glass borders (white used at high transparency)
    GlassWhite    = Color3.fromRGB(255, 255, 255),
    Border        = Color3.fromRGB(255, 255, 255),   -- used at T=0.88 for glass look
    BorderLight   = Color3.fromRGB(255, 255, 255),
    Separator     = Color3.fromRGB(255, 255, 255),   -- used at T=0.92 for glass look
    Shadow        = Color3.fromRGB(0,   0,   0),
    -- Text
    TextPrimary   = Color3.fromRGB(235, 237, 252),
    TextSecondary = Color3.fromRGB(130, 138, 170),
    TextDisabled  = Color3.fromRGB(58,  66,  96),
    -- States
    Success       = Color3.fromRGB(52,  211, 153),
    Warning       = Color3.fromRGB(251, 191, 36),
    Error         = Color3.fromRGB(248, 113, 113),
    Info          = Color3.fromRGB(56,  189, 248),
}

-- ══════════════════════════════════════════════════════
--  HILFSFUNKTIONEN
-- ══════════════════════════════════════════════════════
local Util = {}

-- Tween-Wrapper
function Util.Tween(obj, props, duration, style, direction)
    duration  = duration  or 0.2
    style     = style     or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
    t:Play()
    return t
end

-- Instance-Fabrik
function Util.New(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function()
            obj[k] = v
        end)
    end
    return obj
end

-- Schnell-Ersteller mit optionalem Parent
function Util.Make(class, props, parent)
    local obj = Util.New(class, props)
    if parent then obj.Parent = parent end
    return obj
end

-- UICorner, UIStroke, UIPadding Shortcuts
function Util.Corner(radius, parent)
    return Util.Make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

function Util.Stroke(color, thickness, parent)
    return Util.Make("UIStroke", {Color = color or Theme.Border, Thickness = thickness or 1}, parent)
end

function Util.Padding(t, b, l, r, parent)
    return Util.Make("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
    }, parent)
end

-- Ripple-Effekt (Klick-Feedback)
function Util.Ripple(parent, x, y)
    local abs = parent.AbsolutePosition
    local sz  = parent.AbsoluteSize
    local rx  = x and (x - abs.X) or sz.X / 2
    local ry  = y and (y - abs.Y) or sz.Y / 2

    local ripple = Util.Make("Frame", {
        Size                   = UDim2.new(0, 0, 0, 0),
        Position               = UDim2.new(0, rx, 0, ry),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.82,
        ZIndex                 = parent.ZIndex + 2,
        ClipsDescendants       = false,
    }, parent)
    Util.Corner(9999, ripple)

    local maxDim = math.max(sz.X, sz.Y) * 2.2
    Util.Tween(ripple, {
        Size                   = UDim2.new(0, maxDim, 0, maxDim),
        BackgroundTransparency = 1,
    }, 0.5, Enum.EasingStyle.Quad)

    task.delay(0.5, function()
        if ripple and ripple.Parent then ripple:Destroy() end
    end)
end

-- Draggable mit Screen-Grenzen
function Util.MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging  = true
        dragStart = inp.Position
        -- Position in reine Pixel-Offsets konvertieren (Scale-Anteil auflösen)
        local vp = workspace.CurrentCamera.ViewportSize
        startPos = UDim2.new(
            0, frame.Position.X.Scale * vp.X + frame.Position.X.Offset,
            0, frame.Position.Y.Scale * vp.Y + frame.Position.Y.Offset
        )
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not (dragging and inp.UserInputType == Enum.UserInputType.MouseMovement) then return end
        local delta = inp.Position - dragStart
        local vpSize = workspace.CurrentCamera.ViewportSize

        local newX = math.clamp(
            startPos.X.Offset + delta.X,
            -frame.AbsoluteSize.X + 60,
            vpSize.X - 60
        )
        local newY = math.clamp(
            startPos.Y.Offset + delta.Y,
            0,
            vpSize.Y - 40
        )
        frame.Position = UDim2.new(0, newX, 0, newY)
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Hex → Color3
local function hexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

-- Color3 → Hex
local function colorToHex(c)
    return string.format("%02X%02X%02X",
        math.round(c.R * 255),
        math.round(c.G * 255),
        math.round(c.B * 255)
    )
end

-- ══════════════════════════════════════════════════════
--  NOTIFICATION-SYSTEM
-- ══════════════════════════════════════════════════════
local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return CoreGui
end

local function ensureFolder(path)
    if not isfolder then return false end
    local current = ""
    for _, part in ipairs(string.split(path, "/")) do
        current = current == "" and part or (current .. "/" .. part)
        if not isfolder(current) then
            makefolder(current)
        end
    end
    return true
end

local function requestUrl(url)
    local requester = request or http_request or (http and http.request) or (syn and syn.request) or (fluxus and fluxus.request)

    if requester then
        local ok, result = pcall(function()
            return requester({
                Url = url,
                Method = "GET",
            })
        end)

        if ok and result and (result.Success or result.StatusCode == 200 or result.StatusCode == nil) and result.Body then
            return result.Body
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and body and body ~= "" then return body end

    return nil
end

local function resolveImage(image, localName)
    if type(image) ~= "string" then return image end
    if not image:match("^https?://") then return image end
    if not (writefile and getcustomasset) then return image end

    local assetsFolder = SyntraFolder .. "/assets"
    local fileName = localName or "image.png"
    local path = assetsFolder .. "/" .. fileName

    if not (isfile and isfile(path)) then
        local body = requestUrl(image)
        if body then
            ensureFolder(assetsFolder)
            writefile(path, body)
        end
    end

    if isfile and isfile(path) then
        local ok, asset = pcall(getcustomasset, path)
        if ok then return asset end
    end

    return image
end

local NotifHolder

local NOTIF_ICONS = {
    Info    = "ℹ",
    Success = "✓",
    Warning = "⚠",
    Error   = "✕",
}

local function ensureNotifHolder()
    if NotifHolder and NotifHolder.Parent then return end

    local guiParent = getGuiParent()
    local existing = guiParent:FindFirstChild("SyntraUI_Notifs")
    if existing then existing:Destroy() end

    local sg = Util.Make("ScreenGui", {
        Name           = "SyntraUI_Notifs",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, guiParent)

    NotifHolder = Util.Make("Frame", {
        Name                   = "Holder",
        Size                   = UDim2.new(0, 310, 1, 0),
        Position               = UDim2.new(1, -320, 0, 0),
        BackgroundTransparency = 1,
    }, sg)

    Util.Make("UIListLayout", {
        SortOrder         = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding           = UDim.new(0, 8),
    }, NotifHolder)

    Util.Padding(0, 14, 0, 0, NotifHolder)
end

function SyntraUI:Notify(options)
    options = options or {}
    local title    = options.Title    or "Notification"
    local content  = options.Content  or ""
    local ntype    = options.Type     or "Info"
    local duration = options.Duration or 4

    ensureNotifHolder()

    local accentColor = Theme[ntype] or Theme.Info
    local icon        = NOTIF_ICONS[ntype] or "ℹ"

    -- Glass-Karte
    local card = Util.Make("Frame", {
        Name                   = "Notif",
        Size                   = UDim2.new(1, 0, 0, 76),
        BackgroundColor3       = Theme.BgCard,
        BackgroundTransparency = 0.12,
        ClipsDescendants       = true,
        Position               = UDim2.new(1, 20, 0, 0),
        BorderSizePixel        = 0,
    }, NotifHolder)
    Util.Corner(12, card)
    Util.Make("UIStroke", { Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.86 }, card)

    -- Linker Akzentstreifen (breiter + Glow-Effekt durch zwei Ebenen)
    Util.Make("Frame", {
        Size             = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        ZIndex           = 2,
    }, card)
    Util.Make("Frame", {
        Size                   = UDim2.new(0, 20, 1, 0),
        BackgroundColor3       = accentColor,
        BackgroundTransparency = 0.88,
        BorderSizePixel        = 0,
        ZIndex                 = 1,
    }, card)

    -- Icon-Kreis
    local iconCircle = Util.Make("Frame", {
        Size             = UDim2.new(0, 26, 0, 26),
        Position         = UDim2.new(0, 14, 0, 12),
        BackgroundColor3 = accentColor,
        ZIndex           = 3,
    }, card)
    Util.Corner(999, iconCircle)
    Util.Make("TextLabel", {
        Text                   = icon,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 13,
        TextColor3             = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 1, 0),
        TextXAlignment         = Enum.TextXAlignment.Center,
        ZIndex                 = 4,
    }, iconCircle)

    -- Titel
    Util.Make("TextLabel", {
        Text                   = title,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 13,
        TextColor3             = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -58, 0, 18),
        Position               = UDim2.new(0, 48, 0, 10),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 3,
    }, card)

    -- Inhalt
    Util.Make("TextLabel", {
        Text                   = content,
        Font                   = Enum.Font.Gotham,
        TextSize               = 11,
        TextColor3             = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -58, 0, 34),
        Position               = UDim2.new(0, 48, 0, 30),
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        ZIndex                 = 3,
    }, card)

    -- Fortschrittsbalken (unten)
    local bar = Util.Make("Frame", {
        Size             = UDim2.new(1, -4, 0, 3),
        Position         = UDim2.new(0, 4, 1, -3),
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, card)
    Util.Corner(2, bar)

    -- Einblenden
    Util.Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Fortschritt läuft ab
    Util.Tween(bar, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if not (card and card.Parent) then return end
        Util.Tween(card, {Position = UDim2.new(1, 20, 0, 0)}, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.3, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)
end

-- ══════════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════════
function SyntraUI:CreateWindow(options)
    options = options or {}
    local title    = options.Title    or "SyntraUI"
    local subtitle = options.Subtitle or ""
    local winSize  = options.Size     or UDim2.new(0, 840, 0, 580)
    local winPos   = options.Position or UDim2.new(0.5, -420, 0.5, -290)
    local logo     = options.Logo     or SyntraBrandUrl
    local sidebarWidth = options.SidebarWidth or 210
    local topbarHeight = options.TopbarHeight or 52
    local footerHeight = options.FooterHeight or 24
    local footerText = options.Footer or "SyntraUI v5.0  ·  by Lorthanyx"
    local searchPlaceholder = options.SearchPlaceholder or "Search..."

    -- Alte Instanz aufräumen
    local guiParent = getGuiParent()
    local old = guiParent:FindFirstChild("SyntraUI_Window")
    if old then old:Destroy() end

    -- ── ScreenGui ────────────────────────────────────────
    local ScreenGui = Util.Make("ScreenGui", {
        Name           = "SyntraUI_Window",
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder   = 50,
    }, guiParent)

    -- ── Haupt-Frame ──────────────────────────────────────
    local Main = Util.Make("Frame", {
        Name                   = "Main",
        Size                   = UDim2.new(winSize.X.Scale, winSize.X.Offset, 0, 0),
        Position               = winPos,
        BackgroundColor3       = Theme.BgBase,
        BackgroundTransparency = 0.06,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
    }, ScreenGui)
    Util.Corner(14, Main)
    Util.Make("UIStroke", {
        Color           = Theme.Accent,
        Thickness       = 1,
        Transparency    = 0.72,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, Main)
    -- White glass top highlight
    Util.Make("Frame", {
        Size                   = UDim2.new(1, 0, 0, 1),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.86,
        BorderSizePixel        = 0,
        ZIndex                 = 10,
    }, Main)

    -- ── SIDEBAR ──────────────────────────────────────────
    local Sidebar = Util.Make("Frame", {
        Name                   = "Sidebar",
        Size                   = UDim2.new(0, sidebarWidth, 1, 0),
        Position               = UDim2.new(0, 0, 0, 0),
        BackgroundColor3       = Theme.BgSurface,
        BackgroundTransparency = 0.18,
        BorderSizePixel        = 0,
        ZIndex                 = 3,
        ClipsDescendants       = true,
    }, Main)

    -- Sidebar rechte Glass-Trennlinie
    Util.Make("Frame", {
        Size                   = UDim2.new(0, 1, 1, 0),
        Position               = UDim2.new(1, -1, 0, 0),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.86,
        BorderSizePixel        = 0,
        ZIndex                 = 6,
    }, Sidebar)

    -- Sidebar Header (Logo + Titel)
    local SideHeader = Util.Make("Frame", {
        Size                   = UDim2.new(1, 0, 0, topbarHeight),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 4,
    }, Sidebar)

    -- Logo-Box (glass + Accent-Glow Rand)
    local logoBox = Util.Make("Frame", {
        Size                   = UDim2.new(0, 34, 0, 34),
        Position               = UDim2.new(0, 10, 0.5, -17),
        BackgroundColor3       = Theme.Accent,
        BackgroundTransparency = 0.45,
        BorderSizePixel        = 0,
        ZIndex                 = 5,
    }, SideHeader)
    Util.Corner(10, logoBox)
    Util.Make("UIStroke", {
        Color        = Theme.AccentGlow,
        Thickness    = 1.5,
        Transparency = 0.45,
    }, logoBox)
    -- Fallback-Buchstabe
    Util.Make("TextLabel", {
        Text                   = tostring(title):sub(1,1):upper(),
        Font                   = Enum.Font.GothamBlack,
        TextSize               = 16,
        TextColor3             = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1,0,1,0),
        ZIndex                 = 6,
    }, logoBox)
    -- Logo async laden (Fade-in)
    local logoImg = Util.Make("ImageLabel", {
        Size                   = UDim2.new(0.85, 0, 0.85, 0),
        Position               = UDim2.new(0.075, 0, 0.075, 0),
        BackgroundTransparency = 1,
        Image                  = "",
        ScaleType              = Enum.ScaleType.Fit,
        ImageTransparency      = 1,
        ZIndex                 = 7,
    }, logoBox)
    task.spawn(function()
        local img = resolveImage(logo, "Syntra.png")
        if logoImg and logoImg.Parent then
            logoImg.Image = img or ""
            if img and img ~= "" then
                Util.Tween(logoImg, { ImageTransparency = 0 }, 0.4)
            end
        end
    end)

    Util.Make("TextLabel", {
        Text                   = title,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 14,
        TextColor3             = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -54, 0, 17),
        Position               = UDim2.new(0, 50, 0.5, -14),
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 5,
    }, SideHeader)
    Util.Make("TextLabel", {
        Text                   = subtitle ~= "" and subtitle or "dashboard",
        Font                   = Enum.Font.Gotham,
        TextSize               = 10,
        TextColor3             = Theme.TextDisabled,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -54, 0, 13),
        Position               = UDim2.new(0, 50, 0.5, 3),
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 5,
    }, SideHeader)

    -- Separator unter Header (Glass)
    Util.Make("Frame", {
        Size                   = UDim2.new(1, -24, 0, 1),
        Position               = UDim2.new(0, 12, 0, topbarHeight - 1),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.88,
        BorderSizePixel        = 0,
        ZIndex                 = 5,
    }, Sidebar)

    -- Tab-Liste (scrollbar)
    local TabList = Util.Make("ScrollingFrame", {
        Name                 = "TabList",
        Size                 = UDim2.new(1, 0, 1, -(topbarHeight + footerHeight + 4)),
        Position             = UDim2.new(0, 0, 0, topbarHeight + 4),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        ScrollBarThickness   = 2,
        ScrollBarImageColor3 = Theme.AccentGlow,
        CanvasSize           = UDim2.new(0,0,0,0),
        AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        ScrollingDirection   = Enum.ScrollingDirection.Y,
        ZIndex               = 3,
    }, Sidebar)
    Util.Padding(6, 6, 8, 8, TabList)
    Util.Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 2),
    }, TabList)

    -- ── TOPBAR ───────────────────────────────────────────
    local Titlebar = Util.Make("Frame", {
        Name                   = "Titlebar",
        Size                   = UDim2.new(1, -sidebarWidth, 0, topbarHeight),
        Position               = UDim2.new(0, sidebarWidth, 0, 0),
        BackgroundColor3       = Theme.BgSurface,
        BackgroundTransparency = 0.10,
        BorderSizePixel        = 0,
        ZIndex                 = 3,
    }, Main)

    -- Topbar Glass-Separator
    Util.Make("Frame", {
        Size                   = UDim2.new(1, 0, 0, 1),
        Position               = UDim2.new(0, 0, 1, -1),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.88,
        BorderSizePixel        = 0,
        ZIndex                 = 4,
    }, Titlebar)

    -- Aktiver Tab Name (bread crumb)
    local topbarTabLabel = Util.Make("TextLabel", {
        Text                   = title,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 14,
        TextColor3             = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(0, 220, 1, 0),
        Position               = UDim2.new(0, 18, 0, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 5,
    }, Titlebar)

    -- Search Box — Glass Pill (zentriert)
    local searchBox = Util.Make("Frame", {
        Size                   = UDim2.new(0, 200, 0, 30),
        Position               = UDim2.new(0.5, -100, 0.5, -15),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.92,
        BorderSizePixel        = 0,
        ZIndex                 = 5,
    }, Titlebar)
    Util.Corner(999, searchBox)
    Util.Make("UIStroke", { Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.84 }, searchBox)

    Util.Make("TextLabel", {
        Text                   = "⌕",
        Font                   = Enum.Font.Gotham,
        TextSize               = 14,
        TextColor3             = Theme.TextDisabled,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(0, 26, 1, 0),
        Position               = UDim2.new(0, 4, 0, 0),
        ZIndex                 = 6,
    }, searchBox)

    local SearchInput = Util.Make("TextBox", {
        Text                   = "",
        PlaceholderText        = searchPlaceholder,
        PlaceholderColor3      = Theme.TextDisabled,
        Font                   = Enum.Font.Gotham,
        TextSize               = 12,
        TextColor3             = Theme.TextPrimary,
        BackgroundTransparency = 1,
        ClearTextOnFocus       = false,
        Size                   = UDim2.new(1, -30, 1, 0),
        Position               = UDim2.new(0, 28, 0, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 6,
    }, searchBox)

    -- Window Buttons (rechts oben, macOS-style)
    local function makeWinBtn(offsetX, symbol, color)
        local dot = Util.Make("Frame", {
            Size             = UDim2.new(0, 13, 0, 13),
            Position         = UDim2.new(1, offsetX, 0.5, -6),
            BackgroundColor3 = color,
            BorderSizePixel  = 0,
            ZIndex           = 6,
        }, Titlebar)
        Util.Corner(999, dot)
        local sym = Util.Make("TextLabel", {
            Text                   = symbol,
            Font                   = Enum.Font.GothamBold,
            TextSize               = 8,
            TextColor3             = Color3.fromRGB(30, 20, 10),
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            TextTransparency       = 1,
            ZIndex                 = 7,
        }, dot)
        local btn = Util.Make("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 8,
        }, dot)
        btn.MouseEnter:Connect(function()
            Util.Tween(dot,  {BackgroundColor3 = color},    0.08)
            Util.Tween(sym,  {TextTransparency = 0},        0.1)
        end)
        btn.MouseLeave:Connect(function()
            Util.Tween(dot,  {BackgroundColor3 = color},    0.08)
            Util.Tween(sym,  {TextTransparency = 1},        0.1)
        end)
        return btn, dot
    end

    local CloseBtn,    closeDot    = makeWinBtn(-18, "×", Theme.Error)
    local MinimizeBtn, minimizeDot = makeWinBtn(-38, "–", Theme.Warning)
    local MaximizeBtn, maximizeDot = makeWinBtn(-58, "+", Theme.Success)

    -- ── FOOTER ───────────────────────────────────────────
    local Footer = Util.Make("Frame", {
        Name                   = "Footer",
        Size                   = UDim2.new(1, 0, 0, footerHeight),
        Position               = UDim2.new(0, 0, 1, -footerHeight),
        BackgroundColor3       = Theme.BgSurface,
        BackgroundTransparency = 0.14,
        BorderSizePixel        = 0,
        ZIndex                 = 4,
    }, Main)
    Util.Make("Frame", {
        Size                   = UDim2.new(1, 0, 0, 1),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.88,
        BorderSizePixel        = 0,
        ZIndex                 = 5,
    }, Footer)
    -- Status-Dot links
    local statusDot = Util.Make("Frame", {
        Size             = UDim2.new(0, 6, 0, 6),
        Position         = UDim2.new(0, 10, 0.5, -3),
        BackgroundColor3 = Theme.Success,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, Footer)
    Util.Corner(999, statusDot)
    Util.Make("TextLabel", {
        Text                   = footerText,
        Font                   = Enum.Font.Code,
        TextSize               = 10,
        TextColor3             = Theme.TextDisabled,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(0.5, -20, 1, 0),
        Position               = UDim2.new(0, 22, 0, 0),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 5,
    }, Footer)
    -- Executor Badge rechts
    if Executor.Name ~= "Unknown" then
        local exBadge = Util.Make("Frame", {
            Size             = UDim2.new(0, 0, 0, 16),
            Position         = UDim2.new(1, -8, 0.5, -8),
            BackgroundColor3 = Theme.AccentSoft,
            BorderSizePixel  = 0,
            AutomaticSize    = Enum.AutomaticSize.X,
            ZIndex           = 5,
        }, Footer)
        Util.Corner(4, exBadge)
        local exLbl = Util.Make("TextLabel", {
            Text                   = Executor.Name,
            Font                   = Enum.Font.GothamBold,
            TextSize               = 10,
            TextColor3             = Theme.AccentGlow,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(0, 0, 1, 0),
            AutomaticSize          = Enum.AutomaticSize.X,
            ZIndex                 = 6,
        }, exBadge)
        Util.Padding(0, 0, 6, 6, exLbl)
        -- Badge nach rechts verschieben wenn Breite bekannt
        task.defer(function()
            if exBadge and exBadge.Parent then
                exBadge.Position = UDim2.new(1, -(exBadge.AbsoluteSize.X + 8), 0.5, -8)
            end
        end)
    end

    -- ── CONTENT ──────────────────────────────────────────
    local ContentFrame = Util.Make("Frame", {
        Name                   = "Content",
        Size                   = UDim2.new(1, -sidebarWidth, 1, -(topbarHeight + footerHeight)),
        Position               = UDim2.new(0, sidebarWidth, 0, topbarHeight),
        BackgroundTransparency = 1,
        ClipsDescendants       = true,
        ZIndex                 = 2,
    }, Main)

    local Pages = Util.Make("Frame", {
        Name                   = "Pages",
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants       = true,
    }, ContentFrame)

    -- Drag via Topbar
    Util.MakeDraggable(Main, Titlebar)

    -- ── STATE ─────────────────────────────────────────────
    local minimized     = false
    local maximized     = false
    local normalSize    = winSize
    local normalPos     = winPos
    local tabs          = {}
    local activePageGen = 0

    -- Pop-in Animation
    local popW = winSize.X.Offset
    local popH = winSize.Y.Offset
    Main.Size = UDim2.new(0, popW * 0.88, 0, popH * 0.88)
    Main.Position = UDim2.new(
        winPos.X.Scale, winPos.X.Offset + popW * 0.06,
        winPos.Y.Scale, winPos.Y.Offset + popH * 0.06
    )
    Main.BackgroundTransparency = 1
    task.spawn(function()
        task.wait(0.04)
        Util.Tween(Main, {
            Size                   = winSize,
            Position               = winPos,
            BackgroundTransparency = 0.06,
        }, 0.48, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Util.Ripple(closeDot)
        Util.Tween(Main, { Size = UDim2.new(winSize.X.Scale, winSize.X.Offset, 0, 0), BackgroundTransparency = 1 }, 0.24)
        task.delay(0.26, function()
            if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
        end)
    end)
    MinimizeBtn.MouseButton1Click:Connect(function()
        Util.Ripple(minimizeDot)
        minimized = not minimized
        Util.Tween(Main, { Size = minimized and UDim2.new(winSize.X.Scale, winSize.X.Offset, 0, topbarHeight) or (maximized and UDim2.new(1,0,1,0) or winSize) }, 0.26)
    end)
    MaximizeBtn.MouseButton1Click:Connect(function()
        Util.Ripple(maximizeDot)
        if minimized then return end
        maximized = not maximized
        if maximized then
            normalSize = Main.Size; normalPos = Main.Position
            Util.Tween(Main, { Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0) }, 0.28)
        else
            Util.Tween(Main, { Size = normalSize, Position = normalPos }, 0.28)
        end
    end)

    -- ── WINDOW OBJECT ─────────────────────────────────────
    local Window                      = {}
    Window._main                      = Main
    Window._tabList                   = TabList
    Window._pages                     = Pages
    Window._tabs                      = tabs
    Window._activeTab                 = nil
    Window._gui                       = SyntraUI
    Window._searchInput               = SearchInput
    Window._topbarTabLabel            = topbarTabLabel
    Window._activateNextUserTab       = false

    local function applyTabSearch()
        local q = string.lower(SearchInput.Text or "")
        for _, t in ipairs(tabs) do
            t._btn.Visible = q == "" or string.lower(t._name or ""):find(q, 1, true) ~= nil
        end
    end
    SearchInput:GetPropertyChangedSignal("Text"):Connect(applyTabSearch)

    function Window:SelectTab(name)
        local needle = string.lower(tostring(name or ""))
        for _, t in ipairs(tabs) do
            if string.lower(t._name or "") == needle and t._activate then
                t._activate(); return true
            end
        end
        return false
    end

    -- ╔══════════════════════════════════════════════════╗
    --  TAB ERSTELLEN
    -- ╚══════════════════════════════════════════════════╝
    function Window:CreateTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = tabOpts.Name or "Tab"
        local builtIn = tabOpts.BuiltIn == true

        -- Sidebar-Button
        local TabBtn = Util.Make("TextButton", {
            Name                   = tabName,
            Size                   = UDim2.new(1, 0, 0, 36),
            BackgroundColor3       = Theme.AccentSoft,
            BackgroundTransparency = 1,
            Text                   = tabName,
            Font                   = Enum.Font.GothamSemibold,
            TextSize               = 13,
            TextColor3             = Theme.TextSecondary,
            TextXAlignment         = Enum.TextXAlignment.Left,
            AutoButtonColor        = false,
            ZIndex                 = 4,
        }, TabList)
        Util.Corner(7, TabBtn)
        Util.Padding(0, 0, 14, 8, TabBtn)

        -- Aktiv-Indikator
        local Indicator = Util.Make("Frame", {
            Size                   = UDim2.new(0, 3, 0, 16),
            Position               = UDim2.new(0, 1, 0.5, -8),
            BackgroundColor3       = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ZIndex                 = 5,
        }, TabBtn)
        Util.Corner(999, Indicator)

        -- ── Seiten-ScrollFrame ──────────────────────────
        local Page = Util.Make("ScrollingFrame", {
            Name                 = tabName .. "_Page",
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel      = 0,
            Visible              = false,
            ScrollBarThickness   = 4,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize           = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize  = Enum.AutomaticSize.Y,
        }, Pages)
        Util.Padding(16, 16, 16, 16, Page)
        Util.Make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 8),
        }, Page)

        -- Tab-Eintrag
        local tab = { _name = tabName, _btn = TabBtn, _page = Page, _indicator = Indicator }
        table.insert(tabs, tab)
        applyTabSearch()

        -- Aktivierungslogik mit Page-Übergangsanimation
        local function activateTab()
            for _, t in ipairs(tabs) do
                if t._page.Visible then
                    -- Aktive Page schnell ausblenden
                    t._page.Position = UDim2.new(0, 0, 0, 0)
                    Util.Tween(t._page, { Position = UDim2.new(-0.06, 0, 0, 0) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    task.delay(0.12, function()
                        if t._page and t._page.Parent then t._page.Visible = false end
                        t._page.Position = UDim2.new(0, 0, 0, 0)
                    end)
                else
                    t._page.Visible = false
                end
                Util.Tween(t._btn, {BackgroundTransparency = 1, TextColor3 = Theme.TextSecondary}, 0.15)
                Util.Tween(t._indicator, {BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0, 14)}, 0.15)
            end
            -- Neue Page einblenden (generation-guarded, verhindert doppelte Pages)
            activePageGen = activePageGen + 1
            local myGen = activePageGen
            task.delay(0.1, function()
                if not (Page and Page.Parent) then return end
                if activePageGen ~= myGen then return end
                Page.Position = UDim2.new(0.04, 0, 0, 0)
                Page.Visible = true
                Util.Tween(Page, { Position = UDim2.new(0, 0, 0, 0) }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)
            -- Aktiver Tab: Accent glass pill
            Util.Tween(TabBtn, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.70, TextColor3 = Theme.AccentGlow}, 0.18)
            Util.Tween(Indicator, {BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0, 20)}, 0.18)
            Window._activeTab = tab
            if Window._topbarTabLabel and Window._topbarTabLabel.Parent then
                Window._topbarTabLabel.Text = tabName
            end
        end
        tab._activate = activateTab

        TabBtn.MouseButton1Click:Connect(function()
            Util.Ripple(TabBtn)
            activateTab()
        end)
        TabBtn.MouseEnter:Connect(function()
            if Window._activeTab ~= tab then
                Util.Tween(TabBtn, {BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0.91, TextColor3 = Theme.TextPrimary}, 0.12)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window._activeTab ~= tab then
                Util.Tween(TabBtn, {BackgroundTransparency = 1, TextColor3 = Theme.TextSecondary}, 0.12)
            end
        end)

        if #tabs == 1 or (Window._activateNextUserTab and not builtIn) then
            activateTab()
            if not builtIn then Window._activateNextUserTab = false end
        end

        -- ══════════════════════════════════════════════
        --  KOMPONENTEN
        -- ══════════════════════════════════════════════
        local Tab = {}

        -- Glass Container (Glassmorphism card)
        local function makeContainer(height, clipChildren)
            local c = Util.Make("Frame", {
                Size                   = UDim2.new(1, 0, 0, height),
                BackgroundColor3       = Theme.BgCard,
                BackgroundTransparency = 0.55,
                BorderSizePixel        = 0,
                ClipsDescendants       = clipChildren ~= false,
            }, Page)
            Util.Corner(10, c)
            Util.Make("UIStroke", { Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.88 }, c)
            -- Glass fade-in
            Util.Tween(c, { BackgroundTransparency = 0.42 }, 0.20)
            return c
        end

        -- ── SECTION ────────────────────────────────────
        function Tab:AddSection(name)
            local wrap = Util.Make("Frame", {
                Size                   = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
            }, Page)

            -- Linker Akzent-Punkt
            Util.Make("Frame", {
                Size             = UDim2.new(0, 3, 0, 14),
                Position         = UDim2.new(0, 0, 0.5, -7),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
            }, wrap)
            Util.Corner(999, wrap:FindFirstChildOfClass("Frame"))

            Util.Make("TextLabel", {
                Text                   = name:upper(),
                Font                   = Enum.Font.GothamBold,
                TextSize               = 10,
                TextColor3             = Theme.Accent,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -12, 1, 0),
                Position               = UDim2.new(0, 10, 0, 0),
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, wrap)

            -- Glass-Trennlinie rechts
            Util.Make("Frame", {
                Size                   = UDim2.new(1, -120, 0, 1),
                Position               = UDim2.new(0, 116, 0.5, 0),
                BackgroundColor3       = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.90,
                BorderSizePixel        = 0,
            }, wrap)
        end

        -- ── DIVIDER ────────────────────────────────────
        function Tab:AddDivider()
            Util.Make("Frame", {
                Size                   = UDim2.new(1, 0, 0, 1),
                BackgroundColor3       = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.90,
                BorderSizePixel        = 0,
            }, Page)
        end

        -- ── LABEL ──────────────────────────────────────
        function Tab:AddLabel(text)
            local lbl = Util.Make("TextLabel", {
                Text                   = text,
                Font                   = Enum.Font.Gotham,
                TextSize               = 13,
                TextColor3             = Theme.TextSecondary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 26),
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, Page)
            Util.Padding(0, 0, 4, 0, lbl)

            return {
                Set      = function(_, t) lbl.Text = t end,
                SetColor = function(_, c) lbl.TextColor3 = c end,
                Get      = function(_) return lbl.Text end,
            }
        end

        -- ── PARAGRAPH ──────────────────────────────────
        function Tab:AddParagraph(pOpts)
            pOpts = pOpts or {}
            local pTitle   = pOpts.Title   or ""
            local pContent = pOpts.Content or ""

            local lines = math.max(1, math.ceil(#pContent / 58))
            local h     = (pTitle ~= "" and 22 or 0) + lines * 16 + 18

            local c = makeContainer(h)

            if pTitle ~= "" then
                Util.Make("TextLabel", {
                    Text                   = pTitle,
                    Font                   = Enum.Font.GothamBold,
                    TextSize               = 12,
                    TextColor3             = Theme.AccentGlow,
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, -16, 0, 18),
                    Position               = UDim2.new(0, 10, 0, 6),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                }, c)
            end

            Util.Make("TextLabel", {
                Text                   = pContent,
                Font                   = Enum.Font.Gotham,
                TextSize               = 12,
                TextColor3             = Theme.TextSecondary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -16, 1, pTitle ~= "" and -26 or 0),
                Position               = UDim2.new(0, 10, 0, pTitle ~= "" and 24 or 6),
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextWrapped            = true,
            }, c)
        end

        -- ── BUTTON ─────────────────────────────────────
        function Tab:AddButton(bOpts)
            bOpts = bOpts or {}
            local bName     = bOpts.Name     or "Button"
            local bDesc     = bOpts.Desc     or nil
            local bCallback = bOpts.Callback or function() end

            local h = bDesc and 54 or 38
            local c = makeContainer(h)

            local nameLabel = Util.Make("TextLabel", {
                Text                   = bName,
                Font                   = Enum.Font.GothamSemibold,
                TextSize               = 13,
                TextColor3             = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -36, 0, 20),
                Position               = UDim2.new(0, 12, 0, bDesc and 7 or 9),
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 2,
            }, c)

            if bDesc then
                Util.Make("TextLabel", {
                    Text                   = bDesc,
                    Font                   = Enum.Font.Gotham,
                    TextSize               = 11,
                    TextColor3             = Theme.TextSecondary,
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, -36, 0, 18),
                    Position               = UDim2.new(0, 12, 0, 28),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 2,
                }, c)
            end

            -- Accent-Pill rechts
            local pill = Util.Make("Frame", {
                Size             = UDim2.new(0, 48, 0, 22),
                Position         = UDim2.new(1, -58, 0.5, -11),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.58,
                BorderSizePixel  = 0,
                ZIndex           = 2,
            }, c)
            Util.Corner(6, pill)
            Util.Make("TextLabel", {
                Text = "Run", Font = Enum.Font.GothamBold, TextSize = 10,
                TextColor3 = Theme.AccentGlow, BackgroundTransparency = 1,
                Size = UDim2.new(1,0,1,0), ZIndex = 3,
            }, pill)

            local btn = Util.Make("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                ZIndex                 = 4,
            }, c)

            btn.MouseButton1Click:Connect(function(x, y)
                Util.Ripple(c, x, y)
                Util.Tween(pill, {BackgroundTransparency = 0.20}, 0.08)
                task.delay(0.12, function() Util.Tween(pill, {BackgroundTransparency = 0.58}, 0.20) end)
                Util.Tween(c, {BackgroundTransparency = 0.28}, 0.08)
                task.delay(0.12, function() Util.Tween(c, {BackgroundTransparency = 0.42}, 0.18) end)
                bCallback()
            end)
            btn.MouseEnter:Connect(function()
                Util.Tween(c, {BackgroundTransparency = 0.28}, 0.12)
            end)
            btn.MouseLeave:Connect(function()
                Util.Tween(c, {BackgroundTransparency = 0.42}, 0.12)
            end)

            return {
                SetName = function(_, t) nameLabel.Text = t end,
                SetDesc = function(_, t)
                    local d = c:FindFirstChild("Desc")
                    if d then d.Text = t end
                end,
            }
        end

        -- ── TOGGLE ─────────────────────────────────────
        function Tab:AddToggle(tOpts)
            tOpts = tOpts or {}
            local tName     = tOpts.Name     or "Toggle"
            local tDesc     = tOpts.Desc     or nil
            local tDefault  = tOpts.Default  or false
            local tCallback = tOpts.Callback or function() end

            local state = tDefault
            local h     = tDesc and 54 or 38
            local c     = makeContainer(h)

            local nameLabel = Util.Make("TextLabel", {
                Text                   = tName,
                Font                   = Enum.Font.GothamSemibold,
                TextSize               = 13,
                TextColor3             = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -62, 0, 20),
                Position               = UDim2.new(0, 12, 0, tDesc and 7 or 9),
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, c)

            if tDesc then
                Util.Make("TextLabel", {
                    Text                   = tDesc,
                    Font                   = Enum.Font.Gotham,
                    TextSize               = 11,
                    TextColor3             = Theme.TextSecondary,
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, -62, 0, 18),
                    Position               = UDim2.new(0, 12, 0, 28),
                    TextXAlignment         = Enum.TextXAlignment.Left,
                }, c)
            end

            -- Switch-Track (glass)
            local track = Util.Make("Frame", {
                Size             = UDim2.new(0, 42, 0, 24),
                Position         = UDim2.new(1, -54, 0.5, -12),
                BackgroundColor3 = Theme.BgElevated,
            }, c)
            Util.Corner(999, track)
            Util.Make("UIStroke", { Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.88 }, track)

            -- Innerer Glow (nur sichtbar wenn aktiv)
            local glow = Util.Make("Frame", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundColor3       = Theme.Accent,
                BackgroundTransparency = 1,
            }, track)
            Util.Corner(999, glow)

            -- Knob
            local knob = Util.Make("Frame", {
                Size             = UDim2.new(0, 18, 0, 18),
                Position         = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex           = 2,
            }, track)
            Util.Corner(999, knob)

            -- Knob-Schatten
            Util.Make("UIStroke", {
                Color             = Color3.fromRGB(0, 0, 0),
                Thickness         = 1,
                Transparency      = 0.7,
                ApplyStrokeMode   = Enum.ApplyStrokeMode.Border,
            }, knob)

            local btn = Util.Make("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                ZIndex                 = 3,
            }, c)

            local function setToggle(val, silent)
                state = val
                if state then
                    Util.Tween(track, {BackgroundColor3 = Theme.Accent}, 0.2)
                    Util.Tween(glow,  {BackgroundTransparency = 0.85}, 0.2)
                    Util.Tween(knob,  {Position = UDim2.new(0, 21, 0.5, -9)}, 0.2)
                    Util.Tween(nameLabel, {TextColor3 = Theme.TextPrimary}, 0.15)
                else
                    Util.Tween(track, {BackgroundColor3 = Theme.BgElevated}, 0.2)
                    Util.Tween(glow,  {BackgroundTransparency = 1}, 0.2)
                    Util.Tween(knob,  {Position = UDim2.new(0, 3, 0.5, -9)}, 0.2)
                    Util.Tween(nameLabel, {TextColor3 = Theme.TextSecondary}, 0.15)
                end
                if not silent then tCallback(state) end
            end

            setToggle(tDefault, true)

            btn.MouseButton1Click:Connect(function()
                Util.Ripple(c)
                setToggle(not state)
            end)

            return {
                Set = function(_, v) setToggle(v, true) end,
                Get = function(_) return state end,
            }
        end

        -- ── SLIDER ─────────────────────────────────────
        function Tab:AddSlider(sOpts)
            sOpts = sOpts or {}
            local sName     = sOpts.Name     or "Slider"
            local sMin      = sOpts.Min      or 0
            local sMax      = sOpts.Max      or 100
            local sDefault  = sOpts.Default  or sMin
            local sSuffix   = sOpts.Suffix   or ""
            local sStep     = sOpts.Step     or 1
            local sCallback = sOpts.Callback or function() end

            local value = math.clamp(sDefault, sMin, sMax)

            local c = makeContainer(60)

            Util.Make("TextLabel", {
                Text                   = sName,
                Font                   = Enum.Font.GothamSemibold,
                TextSize               = 13,
                TextColor3             = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -80, 0, 20),
                Position               = UDim2.new(0, 12, 0, 6),
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, c)

            -- Wert-Anzeige (glass)
            local valBox = Util.Make("Frame", {
                Size                   = UDim2.new(0, 58, 0, 20),
                Position               = UDim2.new(1, -70, 0, 6),
                BackgroundColor3       = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.90,
            }, c)
            Util.Corner(5, valBox)
            Util.Make("UIStroke", { Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.84 }, valBox)

            local valLabel = Util.Make("TextLabel", {
                Text                   = tostring(value) .. sSuffix,
                Font                   = Enum.Font.GothamBold,
                TextSize               = 12,
                TextColor3             = Theme.AccentGlow,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                TextXAlignment         = Enum.TextXAlignment.Center,
            }, valBox)

            -- Track (glass)
            local track = Util.Make("Frame", {
                Size                   = UDim2.new(1, -24, 0, 6),
                Position               = UDim2.new(0, 12, 0, 40),
                BackgroundColor3       = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.88,
            }, c)
            Util.Corner(999, track)

            -- Fill
            local fill = Util.Make("Frame", {
                Size             = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
            }, track)
            Util.Corner(999, fill)

            -- Glow-Overlay auf Fill
            local fillGlow = Util.Make("Frame", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundColor3       = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.82,
            }, fill)
            Util.Corner(999, fillGlow)

            -- Knob
            local knob = Util.Make("Frame", {
                Size             = UDim2.new(0, 14, 0, 14),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = Theme.TextPrimary,
                ZIndex           = 3,
            }, track)
            Util.Corner(999, knob)
            Util.Stroke(Theme.Accent, 2, knob)

            -- Anfangsposition
            local pct0 = (value - sMin) / (sMax - sMin)
            fill.Size     = UDim2.new(pct0, 0, 1, 0)
            knob.Position = UDim2.new(pct0, 0, 0.5, 0)

            local dragging = false

            local function updateSlider(screenX)
                local abs   = track.AbsolutePosition.X
                local width = track.AbsoluteSize.X
                local pct   = math.clamp((screenX - abs) / width, 0, 1)
                local raw   = sMin + (sMax - sMin) * pct
                value       = math.round(raw / sStep) * sStep
                value       = math.clamp(value, sMin, sMax)

                local dispPct = (value - sMin) / (sMax - sMin)
                valLabel.Text = tostring(value) .. sSuffix
                Util.Tween(fill, {Size = UDim2.new(dispPct, 0, 1, 0)}, 0.06)
                Util.Tween(knob, {Position = UDim2.new(dispPct, 0, 0.5, 0)}, 0.06)
                sCallback(value)
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateSlider(i.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(i.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            return {
                Set = function(_, v)
                    v = math.clamp(math.round(v / sStep) * sStep, sMin, sMax)
                    local p = (v - sMin) / (sMax - sMin)
                    value = v
                    valLabel.Text = tostring(v) .. sSuffix
                    Util.Tween(fill, {Size = UDim2.new(p, 0, 1, 0)}, 0.14)
                    Util.Tween(knob, {Position = UDim2.new(p, 0, 0.5, 0)}, 0.14)
                end,
                Get = function(_) return value end,
            }
        end

        -- ── TEXTBOX ────────────────────────────────────
        function Tab:AddTextBox(tbOpts)
            tbOpts = tbOpts or {}
            local tbName        = tbOpts.Name           or "Input"
            local tbPlaceholder = tbOpts.Placeholder    or "Text eingeben..."
            local tbDefault     = tbOpts.Default        or ""
            local tbCallback    = tbOpts.Callback       or function() end
            local tbClear       = tbOpts.ClearOnFocus
            if tbClear == nil then tbClear = false end

            local c = makeContainer(60)

            Util.Make("TextLabel", {
                Text                   = tbName,
                Font                   = Enum.Font.GothamSemibold,
                TextSize               = 13,
                TextColor3             = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -16, 0, 20),
                Position               = UDim2.new(0, 12, 0, 5),
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, c)

            local inputBg = Util.Make("Frame", {
                Size                   = UDim2.new(1, -24, 0, 26),
                Position               = UDim2.new(0, 12, 0, 28),
                BackgroundColor3       = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.90,
            }, c)
            Util.Corner(6, inputBg)
            local stroke = Util.Make("UIStroke", { Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.84 }, inputBg)

            local tb = Util.Make("TextBox", {
                Size              = UDim2.new(1, -14, 1, 0),
                Position          = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Font              = Enum.Font.Gotham,
                TextSize          = 12,
                TextColor3        = Theme.TextPrimary,
                PlaceholderText   = tbPlaceholder,
                PlaceholderColor3 = Theme.TextDisabled,
                Text              = tbDefault,
                ClearTextOnFocus  = tbClear,
                TextXAlignment    = Enum.TextXAlignment.Left,
            }, inputBg)

            tb.Focused:Connect(function()
                Util.Tween(stroke, {Color = Theme.Accent, Transparency = 0.50}, 0.15)
                Util.Tween(inputBg, {BackgroundTransparency = 0.82}, 0.15)
            end)
            tb.FocusLost:Connect(function(enter)
                Util.Tween(stroke, {Color = Color3.new(1,1,1), Transparency = 0.84}, 0.15)
                Util.Tween(inputBg, {BackgroundTransparency = 0.90}, 0.15)
                tbCallback(tb.Text, enter)
            end)

            return {
                Set = function(_, t) tb.Text = t end,
                Get = function(_) return tb.Text end,
            }
        end

        -- ── DROPDOWN ───────────────────────────────────
        function Tab:AddDropdown(ddOpts)
            ddOpts = ddOpts or {}
            local ddName     = ddOpts.Name     or "Dropdown"
            local ddOptions  = ddOpts.Options  or {}
            local ddDefault  = ddOpts.Default  or ddOptions[1]
            local ddMulti    = ddOpts.Multi    or false
            local ddCallback = ddOpts.Callback or function() end

            local selected  = ddMulti and {} or ddDefault
            local ddOpen    = false
            local listH     = math.min(#ddOptions * 30, 150)

            -- Dropdown container (glass, kein clip)
            local c = Util.Make("Frame", {
                Size                   = UDim2.new(1, 0, 0, 38),
                BackgroundColor3       = Theme.BgCard,
                BackgroundTransparency = 0.42,
                BorderSizePixel        = 0,
                ClipsDescendants       = false,
                ZIndex                 = 5,
            }, Page)
            Util.Corner(10, c)
            Util.Make("UIStroke", { Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.88 }, c)

            Util.Make("TextLabel", {
                Text                   = ddName,
                Font                   = Enum.Font.GothamSemibold,
                TextSize               = 13,
                TextColor3             = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0.48, 0, 1, 0),
                Position               = UDim2.new(0, 12, 0, 0),
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 6,
            }, c)

            local selLabel = Util.Make("TextLabel", {
                Text                   = ddMulti and "— Nichts —" or (ddDefault or "Auswählen..."),
                Font                   = Enum.Font.Gotham,
                TextSize               = 12,
                TextColor3             = Theme.TextSecondary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0.44, -28, 1, 0),
                Position               = UDim2.new(0.5, 0, 0, 0),
                TextXAlignment         = Enum.TextXAlignment.Right,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                ZIndex                 = 6,
            }, c)

            local arrow = Util.Make("TextLabel", {
                Text                   = "⌄",
                Font                   = Enum.Font.GothamBold,
                TextSize               = 16,
                TextColor3             = Theme.Accent,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0, 22, 1, 0),
                Position               = UDim2.new(1, -24, 0, 0),
                ZIndex                 = 6,
            }, c)

            -- Dropdown-Menu (glass)
            local menu = Util.Make("Frame", {
                Size                   = UDim2.new(1, 0, 0, 0),
                Position               = UDim2.new(0, 0, 1, 5),
                BackgroundColor3       = Theme.BgElevated,
                BackgroundTransparency = 0.10,
                ClipsDescendants       = true,
                Visible                = false,
                ZIndex                 = 12,
            }, c)
            Util.Corner(10, menu)
            Util.Make("UIStroke", { Color = Color3.new(1,1,1), Thickness = 1, Transparency = 0.82 }, menu)
            Util.Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, menu)
            Util.Padding(4, 4, 0, 0, menu)

            local function refreshLabel()
                if ddMulti then
                    local keys = {}
                    for k in pairs(selected) do table.insert(keys, k) end
                    selLabel.Text = #keys > 0 and table.concat(keys, ", ") or "— Nichts —"
                else
                    selLabel.Text = selected or "Auswählen..."
                end
            end

            local function closeMenu()
                ddOpen = false
                Util.Tween(menu, {Size = UDim2.new(1, 0, 0, 0)}, 0.18)
                Util.Tween(arrow, {Rotation = 0}, 0.18)
                task.delay(0.19, function() if menu.Parent then menu.Visible = false end end)
            end

            -- Items bauen
            for _, opt in ipairs(ddOptions) do
                local item = Util.Make("TextButton", {
                    Size                   = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3       = Theme.Elevated,
                    BackgroundTransparency = 1,
                    Text                   = opt,
                    Font                   = Enum.Font.Gotham,
                    TextSize               = 12,
                    TextColor3             = Theme.TextSecondary,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    AutoButtonColor        = false,
                    ZIndex                 = 13,
                }, menu)
                Util.Padding(0, 0, 12, 0, item)

                local function isActive()
                    return ddMulti and selected[opt] or (selected == opt)
                end

                item.MouseEnter:Connect(function()
                    Util.Tween(item, {BackgroundTransparency = 0.7, TextColor3 = Theme.TextPrimary}, 0.1)
                end)
                item.MouseLeave:Connect(function()
                    Util.Tween(item, {
                        BackgroundTransparency = isActive() and 0.8 or 1,
                        TextColor3             = isActive() and Theme.AccentGlow or Theme.TextSecondary,
                    }, 0.1)
                end)
                item.MouseButton1Click:Connect(function()
                    if ddMulti then
                        selected[opt] = selected[opt] and nil or true
                    else
                        selected = opt
                    end
                    refreshLabel()
                    ddCallback(selected)
                    if not ddMulti then closeMenu() end
                end)
            end

            -- Auslöser
            local trigger = Util.Make("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                ZIndex                 = 7,
            }, c)

            trigger.MouseButton1Click:Connect(function()
                ddOpen = not ddOpen
                if ddOpen then
                    menu.Visible = true
                    menu.Size    = UDim2.new(1, 0, 0, 0)
                    Util.Tween(menu,  {Size = UDim2.new(1, 0, 0, listH + 8)}, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    Util.Tween(arrow, {Rotation = 180}, 0.22)
                else
                    closeMenu()
                end
            end)

            return {
                Set = function(_, v)
                    selected = ddMulti and (type(v) == "table" and v or {}) or v
                    refreshLabel()
                end,
                Get       = function(_) return selected end,
                AddOption = function(_, opt) table.insert(ddOptions, opt) end,
            }
        end

        -- ── KEYBIND ────────────────────────────────────
        function Tab:AddKeybind(kOpts)
            kOpts = kOpts or {}
            local kName     = kOpts.Name     or "Keybind"
            local kDefault  = kOpts.Default  or Enum.KeyCode.Unknown
            local kCallback = kOpts.Callback or function() end

            local bound    = kDefault
            local binding  = false

            local c = makeContainer(38)

            Util.Make("TextLabel", {
                Text                   = kName,
                Font                   = Enum.Font.GothamSemibold,
                TextSize               = 13,
                TextColor3             = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0.6, 0, 1, 0),
                Position               = UDim2.new(0, 12, 0, 0),
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, c)

            local keyBg = Util.Make("Frame", {
                Size             = UDim2.new(0, 82, 0, 24),
                Position         = UDim2.new(1, -94, 0.5, -12),
                BackgroundColor3 = Theme.Tertiary,
            }, c)
            Util.Corner(6, keyBg)
            Util.Stroke(Theme.Border, 1, keyBg)

            local keyLabel = Util.Make("TextLabel", {
                Text                   = bound.Name ~= "Unknown" and bound.Name or "None",
                Font                   = Enum.Font.GothamBold,
                TextSize               = 11,
                TextColor3             = Theme.AccentGlow,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                TextXAlignment         = Enum.TextXAlignment.Center,
                ZIndex                 = 2,
            }, keyBg)

            local keyBtn = Util.Make("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
                ZIndex                 = 3,
            }, keyBg)

            keyBtn.MouseButton1Click:Connect(function()
                if binding then return end
                binding = true
                keyLabel.Text      = "..."
                keyLabel.TextColor3 = Theme.Warning
                Util.Stroke(Theme.Warning, 1, keyBg)
            end)

            -- Einmaliger Listener für das Binden
            UserInputService.InputBegan:Connect(function(i, gp)
                if not binding or gp then return end
                if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                bound   = i.KeyCode
                binding = false
                keyLabel.Text       = bound.Name
                keyLabel.TextColor3 = Theme.AccentGlow
                keyBg:FindFirstChildOfClass("UIStroke").Color = Theme.Border
                kCallback(bound)
            end)

            -- Globaler Trigger (nur wenn nicht gerade gebunden wird)
            UserInputService.InputBegan:Connect(function(i, gp)
                if gp or binding then return end
                if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == bound then
                    kCallback(bound)
                end
            end)

            return {
                Set = function(_, k)
                    bound = k
                    keyLabel.Text = k.Name ~= "Unknown" and k.Name or "None"
                end,
                Get = function(_) return bound end,
            }
        end

        -- ── COLOR PICKER ───────────────────────────────
        function Tab:AddColorPicker(cpOpts)
            cpOpts = cpOpts or {}
            local cpName     = cpOpts.Name     or "Farbe"
            local cpDefault  = cpOpts.Default  or Color3.new(1, 1, 1)
            local cpCallback = cpOpts.Callback or function() end

            local color  = cpDefault
            local cpOpen = false
            local h, s, v = Color3.toHSV(color)

            -- Haupt-Zeile
            local c = Util.Make("Frame", {
                Size             = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = Theme.Secondary,
                BorderSizePixel  = 0,
                ClipsDescendants = false,
                ZIndex           = 4,
            }, Page)
            Util.Corner(8, c)
            Util.Stroke(Theme.Border, 1, c)

            Util.Make("TextLabel", {
                Text                   = cpName,
                Font                   = Enum.Font.GothamSemibold,
                TextSize               = 13,
                TextColor3             = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0.6, 0, 1, 0),
                Position               = UDim2.new(0, 12, 0, 0),
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 5,
            }, c)

            -- Hex-Label (rechts vom Swatch)
            local hexLabel = Util.Make("TextLabel", {
                Text                   = "#" .. colorToHex(color),
                Font                   = Enum.Font.GothamBold,
                TextSize               = 11,
                TextColor3             = Theme.TextSecondary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(0, 60, 1, 0),
                Position               = UDim2.new(1, -104, 0, 0),
                TextXAlignment         = Enum.TextXAlignment.Right,
                ZIndex                 = 5,
            }, c)

            -- Farbvorschau
            local swatch = Util.Make("TextButton", {
                Size             = UDim2.new(0, 34, 0, 22),
                Position         = UDim2.new(1, -46, 0.5, -11),
                BackgroundColor3 = color,
                Text             = "",
                ZIndex           = 5,
                AutoButtonColor  = false,
            }, c)
            Util.Corner(5, swatch)
            Util.Stroke(Theme.BorderLight, 1, swatch)

            -- Panel
            local panel = Util.Make("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 1, 5),
                BackgroundColor3 = Theme.Elevated,
                ClipsDescendants = true,
                Visible          = false,
                ZIndex           = 9,
            }, c)
            Util.Corner(8, panel)
            Util.Stroke(Theme.BorderLight, 1, panel)

            -- HSV-Slider-Generator
            local function makeHSVSlider(lbl, yPos, initVal)
                Util.Make("TextLabel", {
                    Text                   = lbl,
                    Font                   = Enum.Font.GothamBold,
                    TextSize               = 10,
                    TextColor3             = Theme.TextSecondary,
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(0, 16, 0, 16),
                    Position               = UDim2.new(0, 8, 0, yPos),
                    ZIndex                 = 10,
                }, panel)

                local tr = Util.Make("Frame", {
                    Size             = UDim2.new(1, -44, 0, 6),
                    Position         = UDim2.new(0, 28, 0, yPos + 4),
                    BackgroundColor3 = Theme.Border,
                    ZIndex           = 10,
                }, panel)
                Util.Corner(999, tr)

                local fl = Util.Make("Frame", {
                    Size             = UDim2.new(initVal, 0, 1, 0),
                    BackgroundColor3 = Theme.Accent,
                    ZIndex           = 10,
                }, tr)
                Util.Corner(999, fl)

                local kn = Util.Make("Frame", {
                    Size        = UDim2.new(0, 10, 0, 10),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position    = UDim2.new(initVal, 0, 0.5, 0),
                    BackgroundColor3 = Theme.TextPrimary,
                    ZIndex      = 11,
                }, tr)
                Util.Corner(999, kn)
                Util.Stroke(Theme.Accent, 2, kn)

                return tr, fl, kn
            end

            local hT, hF, hK = makeHSVSlider("H", 10, h)
            local sT, sF, sK = makeHSVSlider("S", 32, s)
            local vT, vF, vK = makeHSVSlider("V", 54, v)

            -- Hex-Eingabe
            local hexBg = Util.Make("Frame", {
                Size             = UDim2.new(1, -16, 0, 22),
                Position         = UDim2.new(0, 8, 0, 80),
                BackgroundColor3 = Theme.Secondary,
                ZIndex           = 10,
            }, panel)
            Util.Corner(5, hexBg)
            Util.Stroke(Theme.Separator, 1, hexBg)

            local hexInput = Util.Make("TextBox", {
                Text              = "#" .. colorToHex(color),
                Font              = Enum.Font.GothamBold,
                TextSize          = 11,
                TextColor3        = Theme.AccentGlow,
                BackgroundTransparency = 1,
                Size              = UDim2.new(1, -8, 1, 0),
                Position          = UDim2.new(0, 4, 0, 0),
                TextXAlignment    = Enum.TextXAlignment.Center,
                ZIndex            = 11,
                ClearTextOnFocus  = false,
            }, hexBg)

            local function updateColor(skipHex)
                color = Color3.fromHSV(h, s, v)
                swatch.BackgroundColor3 = color
                hexLabel.Text = "#" .. colorToHex(color)
                if not skipHex then
                    hexInput.Text = "#" .. colorToHex(color)
                end
                cpCallback(color)
            end

            local function bindDrag(track, fill, knob, setter)
                local drag = false
                track.InputBegan:Connect(function(i)
                    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    drag = true
                    local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    setter(pct)
                    Util.Tween(fill,  {Size = UDim2.new(pct, 0, 1, 0)}, 0.05)
                    Util.Tween(knob,  {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.05)
                    updateColor()
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if not (drag and i.UserInputType == Enum.UserInputType.MouseMovement) then return end
                    local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    setter(pct)
                    Util.Tween(fill,  {Size = UDim2.new(pct, 0, 1, 0)}, 0.05)
                    Util.Tween(knob,  {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.05)
                    updateColor()
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
                end)
            end

            bindDrag(hT, hF, hK, function(p) h = p end)
            bindDrag(sT, sF, sK, function(p) s = p end)
            bindDrag(vT, vF, vK, function(p) v = p end)

            -- Hex-Eingabe auswerten
            hexInput.FocusLost:Connect(function()
                local parsed = hexToColor(hexInput.Text)
                if parsed then
                    color = parsed
                    h, s, v = Color3.toHSV(color)
                    -- Slider synchronisieren
                    Util.Tween(hF, {Size = UDim2.new(h, 0, 1, 0)}, 0.1)
                    Util.Tween(hK, {Position = UDim2.new(h, 0, 0.5, 0)}, 0.1)
                    Util.Tween(sF, {Size = UDim2.new(s, 0, 1, 0)}, 0.1)
                    Util.Tween(sK, {Position = UDim2.new(s, 0, 0.5, 0)}, 0.1)
                    Util.Tween(vF, {Size = UDim2.new(v, 0, 1, 0)}, 0.1)
                    Util.Tween(vK, {Position = UDim2.new(v, 0, 0.5, 0)}, 0.1)
                    updateColor(true)
                else
                    hexInput.Text = "#" .. colorToHex(color)
                end
            end)

            -- Öffnen/Schließen
            swatch.MouseButton1Click:Connect(function()
                cpOpen = not cpOpen
                if cpOpen then
                    panel.Visible = true
                    panel.Size    = UDim2.new(1, 0, 0, 0)
                    Util.Tween(panel, {Size = UDim2.new(1, 0, 0, 110)}, 0.25)
                else
                    Util.Tween(panel, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    task.delay(0.21, function() if panel.Parent then panel.Visible = false end end)
                end
            end)

            return {
                Set = function(_, col)
                    color = col
                    swatch.BackgroundColor3 = col
                    hexLabel.Text = "#" .. colorToHex(col)
                    hexInput.Text = "#" .. colorToHex(col)
                    h, s, v = Color3.toHSV(col)
                end,
                Get = function(_) return color end,
            }
        end

        -- ── TOGGLE-GROUP (Radio-Buttons) ────────────────
        function Tab:AddToggleGroup(tgOpts)
            tgOpts = tgOpts or {}
            local tgName     = tgOpts.Name     or "Auswahl"
            local tgOptions  = tgOpts.Options  or {}
            local tgDefault  = tgOpts.Default  or tgOptions[1]
            local tgCallback = tgOpts.Callback or function() end

            local selected = tgDefault
            local h = 36 + math.ceil(#tgOptions / 2) * 32 + 8

            local c = makeContainer(h)
            Util.Make("TextLabel", {
                Text                   = tgName,
                Font                   = Enum.Font.GothamSemibold,
                TextSize               = 13,
                TextColor3             = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, -12, 0, 20),
                Position               = UDim2.new(0, 12, 0, 8),
                TextXAlignment         = Enum.TextXAlignment.Left,
            }, c)

            local grid = Util.Make("Frame", {
                Size             = UDim2.new(1, -24, 0, h - 44),
                Position         = UDim2.new(0, 12, 0, 36),
                BackgroundTransparency = 1,
            }, c)
            Util.Make("UIGridLayout", {
                CellSize    = UDim2.new(0.5, -4, 0, 26),
                CellPadding = UDim2.new(0, 4, 0, 4),
            }, grid)

            local btns = {}

            local function setSelected(opt)
                selected = opt
                for _, pair in ipairs(btns) do
                    local isActive = pair.opt == opt
                    Util.Tween(pair.frame, {
                        BackgroundColor3 = isActive and Theme.Accent or Theme.Tertiary,
                    }, 0.15)
                    Util.Tween(pair.lbl, {
                        TextColor3 = isActive and Theme.TextPrimary or Theme.TextSecondary,
                    }, 0.15)
                end
                tgCallback(selected)
            end

            for _, opt in ipairs(tgOptions) do
                local isActive = opt == tgDefault
                local btnF = Util.Make("Frame", {
                    BackgroundColor3 = isActive and Theme.Accent or Theme.Tertiary,
                }, grid)
                Util.Corner(6, btnF)

                local lbl = Util.Make("TextLabel", {
                    Text                   = opt,
                    Font                   = Enum.Font.GothamSemibold,
                    TextSize               = 12,
                    TextColor3             = isActive and Theme.TextPrimary or Theme.TextSecondary,
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 1, 0),
                    TextXAlignment         = Enum.TextXAlignment.Center,
                    ZIndex                 = 2,
                }, btnF)

                local btn = Util.Make("TextButton", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    ZIndex                 = 3,
                }, btnF)

                table.insert(btns, {opt = opt, frame = btnF, lbl = lbl})

                btn.MouseButton1Click:Connect(function()
                    Util.Ripple(btnF)
                    setSelected(opt)
                end)
            end

            return {
                Set = function(_, v) setSelected(v) end,
                Get = function(_) return selected end,
            }
        end

        return Tab
    end -- CreateTab

    -- ══════════════════════════════════════════════════════
    --  BUILT-IN SETTINGS TAB
    -- ══════════════════════════════════════════════════════
    do
        local st = Window:CreateTab({ Name = options.SettingsTabName or "Einstellungen", BuiltIn = true })

        st:AddSection("Appearance")

        st:AddToggle({
            Name     = "Compact Mode",
            Desc     = "Reduce element spacing",
            Default  = false,
            Callback = function(val)
                local pad = val and 4 or 6
                for _, p in ipairs(Pages:GetChildren()) do
                    if p:IsA("ScrollingFrame") then
                        local layout = p:FindFirstChildOfClass("UIListLayout")
                        if layout then layout.Padding = UDim.new(0, pad) end
                    end
                end
            end,
        })

        st:AddSlider({
            Name     = "UI Scale",
            Min      = 70,
            Max      = 130,
            Default  = 100,
            Suffix   = "%",
            Step     = 5,
            Callback = function(val)
                local sc = ScreenGui:FindFirstChildOfClass("UIScale")
                if not sc then sc = Util.Make("UIScale", {}, ScreenGui) end
                sc.Scale = val / 100
            end,
        })

        st:AddSection("Window")

        st:AddButton({
            Name     = "Reset Position",
            Desc     = "Move window back to center",
            Callback = function()
                Util.Tween(Main, { Position = winPos }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end,
        })

        st:AddButton({
            Name     = "Reset Size",
            Desc     = "Restore default window size",
            Callback = function()
                maximized = false
                Util.Tween(Main, { Size = winSize, Position = winPos }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end,
        })

        st:AddSection("Information")

        st:AddParagraph({
            Title   = "Executor",
            Content = Executor.Name .. (Executor.Version ~= "" and (" " .. Executor.Version) or ""),
        })

        st:AddParagraph({
            Title   = "SyntraUI",
            Content = "v5.0 – Glassmorphism Edition  |  by Lorthanyx",
        })

        st:AddParagraph({
            Title   = "Game",
            Content = "PlaceId: " .. tostring(game.PlaceId) .. "  |  GameId: " .. tostring(game.GameId),
        })

        st:AddSection("Actions")

        st:AddButton({
            Name     = "Close Dashboard",
            Desc     = "Destroy the entire UI",
            Callback = function()
                Util.Tween(Main, { Size = UDim2.new(winSize.X.Scale, winSize.X.Offset, 0, 0) }, 0.22)
                task.delay(0.23, function()
                    if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
                end)
            end,
        })
    end

    Window._activateNextUserTab = true

    return Window
end -- CreateWindow

-- ══════════════════════════════════════════════════════
--  LOADING SCREEN
-- ══════════════════════════════════════════════════════
function SyntraUI:ShowLoadingScreen(options)
    options = options or {}
    local title    = options.Title    or "SyntraUI"
    local subtitle = options.Subtitle or "Loading..."
    local duration = options.Duration
    local logoUrl  = options.Logo or SyntraLogoUrl

    local guiParent = getGuiParent()
    local old = guiParent:FindFirstChild("SyntraUI_LoadingGui")
    if old then old:Destroy() end

    -- ── Blur auf Camera ──────────────────────────────────
    local camera = workspace.CurrentCamera
    local blurEffect = nil
    if camera then
        pcall(function()
            local existing = camera:FindFirstChildOfClass("BlurEffect")
            if existing then existing:Destroy() end
            blurEffect = Instance.new("BlurEffect")
            blurEffect.Size = 0
            blurEffect.Parent = camera
            -- Blur einblenden
            local t = TweenService:Create(blurEffect, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 20})
            t:Play()
        end)
    end

    -- ── ScreenGui ────────────────────────────────────────
    local sg = Util.Make("ScreenGui", {
        Name           = "SyntraUI_LoadingGui",
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder   = 200,
    }, guiParent)

    -- Dunkles Semi-Transparent Overlay (kein Vollbild-Block, nur Dimmer)
    local overlay = Util.Make("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundColor3       = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 1,
    }, sg)
    Util.Tween(overlay, { BackgroundTransparency = 0.45 }, 0.4)

    -- Äußerer Glow-Blob
    local glowBlob = Util.Make("Frame", {
        Size                   = UDim2.new(0, 380, 0, 320),
        Position               = UDim2.new(0.5, -190, 0.5, -160),
        BackgroundColor3       = Theme.Accent,
        BackgroundTransparency = 0.88,
        BorderSizePixel        = 0,
        ZIndex                 = 2,
    }, sg)
    Util.Corner(999, glowBlob)

    -- ── Card ─────────────────────────────────────────────
    local cardW, cardH = 340, 290
    local card = Util.Make("Frame", {
        Size                   = UDim2.new(0, cardW, 0, cardH),
        Position               = UDim2.new(0.5, -cardW/2, 0.5, -cardH/2 + 20),
        BackgroundColor3       = Theme.BgCard,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 3,
        ClipsDescendants       = true,
    }, sg)
    Util.Corner(18, card)

    -- Glass white border
    local cardStroke = Util.Make("UIStroke", {
        Color        = Color3.new(1, 1, 1),
        Thickness    = 1,
        Transparency = 0.82,
    }, card)

    -- Accent-Balken oben
    local topBar = Util.Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, card)
    -- Runde untere Hälfte von topBar abschneiden
    Util.Make("Frame", {
        Size             = UDim2.new(1, 0, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, topBar)

    -- Logo-Box (hochwertiger Stil: runder Gradient-Hintergrund)
    local logoBox = Util.Make("Frame", {
        Size             = UDim2.new(0, 72, 0, 72),
        Position         = UDim2.new(0.5, -36, 0, 24),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.0,
        BorderSizePixel  = 0,
        ZIndex           = 4,
    }, card)
    Util.Corner(20, logoBox)
    -- Inner glow ring
    Util.Make("UIStroke", {
        Color        = Theme.AccentGlow,
        Thickness    = 1.5,
        Transparency = 0.4,
    }, logoBox)
    -- Fallback-Buchstabe
    local logoFallback = Util.Make("TextLabel", {
        Text                   = tostring(title):sub(1,1):upper(),
        Font                   = Enum.Font.GothamBlack,
        TextSize               = 32,
        TextColor3             = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 1, 0),
        TextXAlignment         = Enum.TextXAlignment.Center,
        ZIndex                 = 5,
    }, logoBox)
    -- Echtes Logo async
    local logoImg = Util.Make("ImageLabel", {
        Size                   = UDim2.new(0.85, 0, 0.85, 0),
        Position               = UDim2.new(0.075, 0, 0.075, 0),
        BackgroundTransparency = 1,
        Image                  = "",
        ScaleType              = Enum.ScaleType.Fit,
        ImageTransparency      = 1,
        ZIndex                 = 6,
    }, logoBox)
    task.spawn(function()
        local img = resolveImage(logoUrl, "SyntraUI.png")
        if logoImg and logoImg.Parent then
            logoImg.Image = img or ""
            if img and img ~= "" then
                Util.Tween(logoImg, { ImageTransparency = 0 }, 0.3)
            end
        end
    end)

    -- Puls-Animation auf Logo-Box
    task.spawn(function()
        while sg and sg.Parent do
            Util.Tween(logoBox, { BackgroundTransparency = 0.15 }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.0)
            if not (sg and sg.Parent) then break end
            Util.Tween(logoBox, { BackgroundTransparency = 0.0 }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.0)
        end
    end)

    -- Titel
    local titleLabel = Util.Make("TextLabel", {
        Text                   = title,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 22,
        TextColor3             = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -32, 0, 30),
        Position               = UDim2.new(0, 16, 0, 108),
        TextXAlignment         = Enum.TextXAlignment.Center,
        ZIndex                 = 4,
    }, card)

    -- Status
    local statusLabel = Util.Make("TextLabel", {
        Text                   = subtitle,
        Font                   = Enum.Font.Gotham,
        TextSize               = 12,
        TextColor3             = Theme.TextSecondary,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -32, 0, 18),
        Position               = UDim2.new(0, 16, 0, 143),
        TextXAlignment         = Enum.TextXAlignment.Center,
        ZIndex                 = 4,
    }, card)

    -- Fortschrittsbalken Hintergrund (glass)
    local barBack = Util.Make("Frame", {
        Size                   = UDim2.new(1, -48, 0, 6),
        Position               = UDim2.new(0, 24, 0, 182),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.88,
        BorderSizePixel        = 0,
        ZIndex                 = 4,
        ClipsDescendants       = true,
    }, card)
    Util.Corner(999, barBack)

    -- Fortschrittsbalken
    local bar = Util.Make("Frame", {
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, barBack)
    Util.Corner(999, bar)

    -- Glanz auf Bar
    local barShine = Util.Make("Frame", {
        Size                   = UDim2.new(0.4, 0, 1, 0),
        Position               = UDim2.new(0.6, 0, 0, 0),
        BackgroundColor3       = Color3.new(1,1,1),
        BackgroundTransparency = 0.75,
        BorderSizePixel        = 0,
        ZIndex                 = 6,
    }, bar)
    Util.Corner(999, barShine)

    -- Version-Label
    Util.Make("TextLabel", {
        Text                   = "v5.0  ·  Glassmorphism Edition",
        Font                   = Enum.Font.Code,
        TextSize               = 10,
        TextColor3             = Theme.TextDisabled,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -32, 0, 16),
        Position               = UDim2.new(0, 16, 0, 252),
        TextXAlignment         = Enum.TextXAlignment.Center,
        ZIndex                 = 4,
    }, card)

    -- ── Card Pop-in Animation ────────────────────────────
    task.spawn(function()
        task.wait(0.05)
        card.Size = UDim2.new(0, cardW * 0.88, 0, cardH * 0.88)
        Util.Tween(card, {
            BackgroundTransparency = 0.12,
            Size                   = UDim2.new(0, cardW, 0, cardH),
            Position               = UDim2.new(0.5, -cardW/2, 0.5, -cardH/2),
        }, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    -- ── Shimmer auf Bar ──────────────────────────────────
    task.spawn(function()
        while sg and sg.Parent do
            if bar.Size.X.Scale > 0.05 then
                Util.Tween(barShine, { BackgroundTransparency = 0.88 }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(0.65)
                if not (sg and sg.Parent) then break end
                Util.Tween(barShine, { BackgroundTransparency = 0.75 }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            end
            task.wait(0.65)
        end
    end)

    local manualProgress = false

    if duration then
        Util.Tween(bar, { Size = UDim2.new(1, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)
    else
        task.spawn(function()
            while sg and sg.Parent and not manualProgress do
                bar.Size     = UDim2.new(0.3, 0, 1, 0)
                bar.Position = UDim2.new(-0.32, 0, 0, 0)
                Util.Tween(bar, { Position = UDim2.new(1.02, 0, 0, 0) }, 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(1.15)
            end
        end)
    end

    -- ── Loader API ───────────────────────────────────────
    local loader = {}
    function loader:SetStatus(text)
        if statusLabel and statusLabel.Parent then
            statusLabel.Text = tostring(text or "")
        end
    end
    function loader:SetProgress(value)
        manualProgress = true
        value = math.clamp(tonumber(value) or 0, 0, 1)
        if bar and bar.Parent then
            Util.Tween(bar, { Position = UDim2.new(0,0,0,0), Size = UDim2.new(value, 0, 1, 0) }, 0.25, Enum.EasingStyle.Quart)
        end
    end
    function loader:Close(fadeTime)
        fadeTime = fadeTime or 0.45
        if not (sg and sg.Parent) then return end
        manualProgress = true

        -- Blur ausblenden
        if blurEffect and blurEffect.Parent then
            local t = TweenService:Create(blurEffect, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0})
            t:Play()
            task.delay(fadeTime + 0.1, function()
                if blurEffect and blurEffect.Parent then blurEffect:Destroy() end
            end)
        end

        -- Overlay abdunkeln ausblenden
        Util.Tween(overlay, { BackgroundTransparency = 1 }, fadeTime)
        Util.Tween(glowBlob, { BackgroundTransparency = 1 }, fadeTime * 0.8)

        -- Card: Scale down + fade (schöne Pop-out Animation)
        Util.Tween(card, {
            BackgroundTransparency = 1,
            Size     = UDim2.new(0, cardW * 0.9, 0, cardH * 0.9),
            Position = UDim2.new(0.5, -(cardW*0.9)/2, 0.5, -(cardH*0.9)/2),
        }, fadeTime * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

        -- Inhalte schneller ausblenden
        for _, obj in ipairs(card:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                Util.Tween(obj, { TextTransparency = 1 }, fadeTime * 0.5)
            elseif obj:IsA("ImageLabel") then
                Util.Tween(obj, { ImageTransparency = 1 }, fadeTime * 0.5)
            elseif obj:IsA("Frame") then
                Util.Tween(obj, { BackgroundTransparency = 1 }, fadeTime * 0.6)
            elseif obj:IsA("UIStroke") then
                Util.Tween(obj, { Transparency = 1 }, fadeTime * 0.5)
            end
        end
        Util.Tween(cardStroke, { Transparency = 1 }, fadeTime * 0.5)

        task.delay(fadeTime + 0.08, function()
            if sg and sg.Parent then sg:Destroy() end
        end)
    end

    if duration then
        task.delay(duration, function()
            if options.AutoClose ~= false then loader:Close() end
        end)
    end

    return loader
end

function SyntraUI:GetConfigPath(name)
    name = tostring(name or "default")
    return SyntraFolder .. "/configs/" .. name .. ".json"
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
    options = options or {}
    local cfg = {
        Name = options.Name or "default",
        Values = options.Defaults or {},
        Items = {},
    }

    function cfg:Register(key, control, defaultValue)
        self.Items[key] = control
        if self.Values[key] == nil then
            self.Values[key] = defaultValue
        end
        if defaultValue ~= nil and control and control.Set then
            control:Set(defaultValue)
        end
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
        if control and control.Set then
            control:Set(value)
        end
    end

    function cfg:Collect()
        local data = {}
        for key, value in pairs(self.Values) do
            data[key] = value
        end
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
            if control and control.Set then
                control:Set(value)
            end
        end
        return self.Values, err
    end

    return cfg
end

function SyntraUI:BuildScriptSource(source)
    if type(source) ~= "string" then return nil, "source must be a string" end
    if source:match("^https?://") then
        return string.format([[
local url = %q
local req = request or http_request or (http and http.request) or (syn and syn.request) or (fluxus and fluxus.request)
local body
if req then
    local response = req({Url = url, Method = "GET"})
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
    options = options or {}
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
    local lines = {"{"}
    for placeId, source in pairs(self._placeLoads or {}) do
        table.insert(lines, string.format("[%d] = %q,", placeId, source))
    end
    table.insert(lines, "}")
    local placeLoadsTable = table.concat(lines, "\n")
    return string.format(template, placeLoadsTable, template)
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

TeleportService.TeleportInitFailed:Connect(function()
    if SyntraUI._autoLoadSource then
        SyntraUI:QueueOnTeleport(SyntraUI:BuildAutoLoadSource(SyntraUI._autoLoadSource))
    end
end)

function SyntraUI:SetTheme(custom)
    for k, v in pairs(custom) do
        if Theme[k] ~= nil then Theme[k] = v end
    end
end

function SyntraUI:GetTheme()
    return Theme
end

-- ══════════════════════════════════════════════════════
--  RÜCKGABE
-- ══════════════════════════════════════════════════════
return SyntraUI
