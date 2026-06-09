-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SyntraUI  v3.0  ·  Potassium Edition  ·  by Lorthanyx      ║
-- ║  Modern Roblox Dashboard Library – rebuilt from scratch      ║
-- ╚══════════════════════════════════════════════════════════════╝

local SyntraUI   = {}
SyntraUI.__index = SyntraUI

-- ── Services ──────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local RunService       = game:GetService("RunService")

local LocalPlayer    = Players.LocalPlayer
local BRAND_URL      = "https://raw.githubusercontent.com/PixelGG/LuaScripts/main/Syntra.png"
local LOGO_URL       = "https://raw.githubusercontent.com/PixelGG/LuaScripts/main/SyntraUI.png"
local FOLDER         = "SyntraUI"

-- ── Executor detection ─────────────────────────────────────────────────────
local Executor = { Name = "Unknown", Version = "" }
do
    if identifyexecutor then
        local ok, n, v = pcall(identifyexecutor)
        if ok then Executor.Name = tostring(n or "Unknown"); Executor.Version = tostring(v or "") end
    end
end

-- ── Theme ─────────────────────────────────────────────────────────────────
local T = {
    Bg          = Color3.fromRGB(11,  13,  20),
    Bg2         = Color3.fromRGB(16,  19,  30),
    Bg3         = Color3.fromRGB(21,  25,  39),
    Bg4         = Color3.fromRGB(27,  32,  50),
    Surface     = Color3.fromRGB(18,  22,  34),

    Accent      = Color3.fromRGB(99,  102, 241),
    AccentHover = Color3.fromRGB(129, 132, 255),
    AccentDim   = Color3.fromRGB(40,  42,  100),

    Text        = Color3.fromRGB(238, 242, 255),
    TextSub     = Color3.fromRGB(148, 156, 187),
    TextMuted   = Color3.fromRGB(72,  80,  110),

    Green       = Color3.fromRGB(52,  211, 153),
    Yellow      = Color3.fromRGB(251, 191, 36),
    Red         = Color3.fromRGB(248, 113, 113),
    Blue        = Color3.fromRGB(56,  189, 248),

    Border      = Color3.fromRGB(35,  40,  62),
    BorderBright= Color3.fromRGB(55,  63,  95),
    Sep         = Color3.fromRGB(26,  31,  48),
}

-- ── Util ──────────────────────────────────────────────────────────────────
local U = {}

function U.tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    local tw = TweenService:Create(obj, TweenInfo.new(t or 0.2, style, dir), props)
    tw:Play(); return tw
end

function U.make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    if parent then obj.Parent = parent end
    return obj
end

function U.corner(r, p)  return U.make("UICorner",  { CornerRadius = UDim.new(0, r or 8) }, p) end
function U.stroke(c, th, p) return U.make("UIStroke", { Color = c or T.Border, Thickness = th or 1 }, p) end
function U.pad(t, b, l, r, p)
    return U.make("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0), PaddingRight  = UDim.new(0, r or 0),
    }, p)
end

function U.list(so, pad, p)
    return U.make("UIListLayout", {
        SortOrder         = so or Enum.SortOrder.LayoutOrder,
        Padding           = UDim.new(0, pad or 0),
        FillDirection     = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    }, p)
end

function U.ripple(parent, mx, my)
    local abs = parent.AbsolutePosition
    local sz  = parent.AbsoluteSize
    local rx  = mx and (mx - abs.X) or sz.X / 2
    local ry  = my and (my - abs.Y) or sz.Y / 2
    local r   = U.make("Frame", {
        Size = UDim2.new(0,0,0,0), Position = UDim2.new(0, rx, 0, ry),
        AnchorPoint = Vector2.new(.5,.5), BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 0.8, ZIndex = (parent.ZIndex or 1) + 5,
    }, parent)
    U.corner(9999, r)
    local d = math.max(sz.X, sz.Y) * 2.4
    U.tween(r, { Size = UDim2.new(0,d,0,d), BackgroundTransparency = 1 }, 0.45, Enum.EasingStyle.Quad)
    task.delay(0.5, function() if r.Parent then r:Destroy() end end)
end

function U.drag(frame, handle)
    handle = handle or frame
    local dragging, dStart, fStart = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging = true; dStart = i.Position; fStart = frame.Position
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d   = i.Position - dStart
        local vp  = workspace.CurrentCamera.ViewportSize
        local nx  = math.clamp(fStart.X.Offset + d.X, -frame.AbsoluteSize.X + 80, vp.X - 80)
        local ny  = math.clamp(fStart.Y.Offset + d.Y, 0, vp.Y - 40)
        frame.Position = UDim2.new(0, nx, 0, ny)
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- ── GuiParent ──────────────────────────────────────────────────────────────
local function guiRoot()
    if gethui then local ok, h = pcall(gethui); if ok and h then return h end end
    return CoreGui
end

-- ── ensureFolder / HTTP ───────────────────────────────────────────────────
local function ensureFolder(path)
    if not (isfolder and makefolder) then return false end
    local cur = ""
    for p in tostring(path):gmatch("[^/]+") do
        cur = cur == "" and p or (cur.."/"..p)
        if not isfolder(cur) then makefolder(cur) end
    end
    return true
end

local function httpGet(url)
    local req = request or http_request or (http and http.request) or (syn and syn.request) or (fluxus and fluxus.request)
    if req then
        local ok, r = pcall(function() return req({ Url = url, Method = "GET" }) end)
        if ok and r and r.Body and r.Body ~= "" then return r.Body end
    end
    local ok, b = pcall(function() return game:HttpGet(url) end)
    if ok and b and b ~= "" then return b end
    return nil
end

local function resolveImage(url, localName)
    if type(url) ~= "string" or not url:match("^https?://") then return url end
    if not (writefile and getcustomasset) then return url end
    local path = FOLDER.."/assets/"..(localName or "img.png")
    if not (isfile and isfile(path)) then
        local body = httpGet(url)
        if body then ensureFolder(FOLDER.."/assets"); writefile(path, body) end
    end
    if isfile and isfile(path) then
        local ok, asset = pcall(getcustomasset, path)
        if ok then return asset end
    end
    return url
end

-- ══════════════════════════════════════════════════════════════════════════
--  NOTIFICATION
-- ══════════════════════════════════════════════════════════════════════════
local notifHolder

local NTYPE_COLOR = { Info = "Blue", Success = "Green", Warning = "Yellow", Error = "Red" }
local NTYPE_ICON  = { Info = "i", Success = "✓", Warning = "!", Error = "✕" }

local function ensureNotifHolder()
    if notifHolder and notifHolder.Parent then return end
    local root = guiRoot()
    local old = root:FindFirstChild("SyntraUI_Notifs")
    if old then old:Destroy() end
    local sg = U.make("ScreenGui", {
        Name = "SyntraUI_Notifs", ResetOnSpawn = false, DisplayOrder = 998,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, root)
    notifHolder = U.make("Frame", {
        Size = UDim2.new(0, 320, 1, 0),
        Position = UDim2.new(1, -330, 0, 0),
        BackgroundTransparency = 1,
    }, sg)
    U.list(Enum.SortOrder.LayoutOrder, 8, notifHolder)
    U.make("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom }, notifHolder)
    U.pad(0, 16, 0, 0, notifHolder)
end

function SyntraUI:Notify(opts)
    opts = opts or {}
    local title    = opts.Title    or "Notification"
    local content  = opts.Content  or ""
    local ntype    = opts.Type     or "Info"
    local duration = opts.Duration or 5

    ensureNotifHolder()
    local accentKey = NTYPE_COLOR[ntype] or "Blue"
    local accent    = T[accentKey] or T.Blue
    local icon      = NTYPE_ICON[ntype] or "i"

    -- card
    local card = U.make("Frame", {
        Name = "Notif", Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = T.Bg2, ClipsDescendants = true,
        Position = UDim2.new(1, 20, 0, 0), BorderSizePixel = 0,
    }, notifHolder)
    U.corner(12, card)
    U.stroke(T.Border, 1, card)

    -- left accent bar
    U.make("Frame", {
        Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 3,
    }, card)
    U.make("Frame", {
        Size = UDim2.new(0, 28, 1, 0), BorderSizePixel = 0, ZIndex = 2,
        BackgroundColor3 = accent, BackgroundTransparency = 0.87,
    }, card)

    -- icon
    local ic = U.make("Frame", {
        Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(0, 16, 0, 14),
        BackgroundColor3 = accent, ZIndex = 4,
    }, card)
    U.corner(999, ic)
    U.make("TextLabel", {
        Text = icon, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Color3.new(1,1,1), BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0), ZIndex = 5,
    }, ic)

    -- title
    U.make("TextLabel", {
        Text = title, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = T.Text, BackgroundTransparency = 1,
        Size = UDim2.new(1,-60, 0, 18), Position = UDim2.new(0, 52, 0, 10), ZIndex = 4,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)
    -- body
    U.make("TextLabel", {
        Text = content, Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = T.TextSub, BackgroundTransparency = 1,
        Size = UDim2.new(1,-60, 0, 36), Position = UDim2.new(0, 52, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 4,
    }, card)
    -- timer bar
    local tb = U.make("Frame", {
        Size = UDim2.new(1,-4, 0, 2), Position = UDim2.new(0, 2, 1, -2),
        BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 5,
    }, card)
    U.corner(999, tb)

    U.tween(card, { Position = UDim2.new(0,0,0,0) }, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    U.tween(tb, { Size = UDim2.new(0,0,0,2) }, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        if not (card and card.Parent) then return end
        U.tween(card, { Position = UDim2.new(1, 20, 0, 0) }, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.3, function() if card.Parent then card:Destroy() end end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════
--  LOADING SCREEN
-- ══════════════════════════════════════════════════════════════════════════
function SyntraUI:ShowLoadingScreen(opts)
    opts = opts or {}
    local title    = opts.Title    or "SyntraUI"
    local subtitle = opts.Subtitle or "Loading..."
    local duration = opts.Duration

    local root = guiRoot()
    local old  = root:FindFirstChild("SyntraUI_Loading")
    if old then old:Destroy() end

    local sg = U.make("ScreenGui", {
        Name = "SyntraUI_Loading", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999,
    }, root)

    -- full-screen dark overlay
    local overlay = U.make("Frame", {
        Size = UDim2.new(1,0,1,0), BackgroundColor3 = T.Bg,
        BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 1,
    }, sg)

    -- subtle radial glow behind card
    local glow = U.make("Frame", {
        Size = UDim2.new(0, 360, 0, 360),
        Position = UDim2.new(0.5, -180, 0.5, -180),
        BackgroundColor3 = T.Accent, BackgroundTransparency = 0.88,
        BorderSizePixel = 0, ZIndex = 2,
    }, overlay)
    U.corner(999, glow)

    -- card
    local card = U.make("Frame", {
        Size = UDim2.new(0, 300, 0, 228),
        Position = UDim2.new(0.5, -150, 0.5, -114),
        BackgroundColor3 = T.Bg2, BackgroundTransparency = 0,
        BorderSizePixel = 0, ZIndex = 3,
    }, overlay)
    U.corner(16, card)
    U.stroke(T.Border, 1, card)

    -- top accent strip
    local strip = U.make("Frame", {
        Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = T.Accent,
        BorderSizePixel = 0, ZIndex = 4,
    }, card)
    U.corner(999, strip)
    U.make("Frame", {
        Size = UDim2.new(1,0, 0.55,0), Position = UDim2.new(0,0, 0.45,0),
        BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 4,
    }, strip)

    -- logo box
    local logoBox = U.make("Frame", {
        Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0.5, -30, 0, 18),
        BackgroundColor3 = T.Bg3, BorderSizePixel = 0, ZIndex = 5,
    }, card)
    U.corner(14, logoBox)
    U.stroke(T.Border, 1, logoBox)

    -- letter fallback  (always shown; image will draw on top if loaded)
    U.make("TextLabel", {
        Text = tostring(title):sub(1,1):upper(), Font = Enum.Font.GothamBlack,
        TextSize = 26, TextColor3 = T.Accent, BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0), ZIndex = 6,
    }, logoBox)
    U.make("ImageLabel", {
        Size = UDim2.new(0,46,0,46), Position = UDim2.new(0.5,-23,0.5,-23),
        BackgroundTransparency = 1, Image = resolveImage(LOGO_URL, "SyntraUI.png"),
        ScaleType = Enum.ScaleType.Fit, ZIndex = 7,
    }, logoBox)

    -- title label
    U.make("TextLabel", {
        Text = title, Font = Enum.Font.GothamBold, TextSize = 18,
        TextColor3 = T.Text, BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 92),
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
    }, card)

    -- status label
    local statusLbl = U.make("TextLabel", {
        Text = subtitle, Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = T.TextSub, BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 10, 0, 122),
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
    }, card)

    -- progress track
    local track = U.make("Frame", {
        Size = UDim2.new(1, -40, 0, 5), Position = UDim2.new(0, 20, 0, 158),
        BackgroundColor3 = T.Bg3, BorderSizePixel = 0, ZIndex = 5,
        ClipsDescendants = true,
    }, card)
    U.corner(999, track)

    -- progress fill
    local fill = U.make("Frame", {
        Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(0,0,0,0),
        BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 6,
    }, track)
    U.corner(999, fill)

    -- shimmer on fill
    local shimmer = U.make("Frame", {
        Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 7,
    }, fill)
    U.corner(999, shimmer)

    -- version tag
    U.make("TextLabel", {
        Text = "v3.0  ·  Potassium Edition", Font = Enum.Font.Code, TextSize = 10,
        TextColor3 = T.TextMuted, BackgroundTransparency = 1,
        Size = UDim2.new(1,-20, 0, 16), Position = UDim2.new(0, 10, 0, 196),
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
    }, card)

    -- shimmer pulse
    local pulseAlive = true
    task.spawn(function()
        while pulseAlive and sg.Parent do
            U.tween(shimmer, { BackgroundTransparency = 0.92 }, 0.7, Enum.EasingStyle.Sine)
            task.wait(0.75)
            if not pulseAlive then break end
            U.tween(shimmer, { BackgroundTransparency = 0.6 }, 0.7, Enum.EasingStyle.Sine)
            task.wait(0.75)
        end
    end)

    -- indeterminate bounce (if no manual SetProgress called)
    local manualProg = false
    task.spawn(function()
        while not manualProg and sg.Parent do
            fill.Size     = UDim2.new(0.3, 0, 1, 0)
            fill.Position = UDim2.new(-0.35, 0, 0, 0)
            U.tween(fill, { Position = UDim2.new(1.05,0,0,0) }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.05)
        end
    end)

    -- auto-duration
    if duration then
        U.tween(fill, { Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0) }, duration, Enum.EasingStyle.Linear)
    end

    -- ── loader API ────────────────────────────────────────────────────────
    local loader = {}

    function loader:SetStatus(text)
        if statusLbl.Parent then statusLbl.Text = tostring(text or "") end
    end

    function loader:SetProgress(v)
        manualProg = true
        v = math.clamp(tonumber(v) or 0, 0, 1)
        fill.Position = UDim2.new(0,0,0,0)
        U.tween(fill, { Size = UDim2.new(v,0,1,0) }, 0.18, Enum.EasingStyle.Quad)
    end

    function loader:Close(ft)
        ft = ft or 0.38
        if not sg.Parent then return end
        pulseAlive = false
        manualProg = true
        -- fade everything
        U.tween(overlay, { BackgroundTransparency = 1 }, ft)
        U.tween(card,    { BackgroundTransparency = 1 }, ft)
        U.tween(glow,    { BackgroundTransparency = 1 }, ft)
        for _, d in ipairs(sg:GetDescendants()) do
            if d:IsA("Frame") or d:IsA("ImageLabel") or d:IsA("TextLabel") then
                pcall(function()
                    if d:IsA("TextLabel") then
                        U.tween(d, { TextTransparency = 1, BackgroundTransparency = 1 }, ft)
                    elseif d:IsA("ImageLabel") then
                        U.tween(d, { ImageTransparency = 1, BackgroundTransparency = 1 }, ft)
                    else
                        U.tween(d, { BackgroundTransparency = 1 }, ft)
                    end
                end)
            elseif d:IsA("UIStroke") then
                pcall(function() U.tween(d, { Transparency = 1 }, ft) end)
            end
        end
        task.delay(ft + 0.08, function()
            if sg.Parent then sg:Destroy() end
        end)
    end

    if duration then
        task.delay(duration, function()
            if opts.AutoClose ~= false then loader:Close() end
        end)
    end

    return loader
end

-- ══════════════════════════════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════════════════════════════
function SyntraUI:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title    or "SyntraUI"
    local subtitle = opts.Subtitle or ""
    local footer   = opts.Footer   or "SyntraUI v3.0  ·  by Lorthanyx"
    local logo     = opts.Logo     or BRAND_URL
    local W        = opts.Width    or 800
    local H        = opts.Height   or 560
    local SIDE     = opts.SidebarW or 220
    local TOP      = 52
    local BOT      = 28
    local searchPH = opts.SearchPlaceholder or "Search..."

    local winSize = UDim2.new(0, W, 0, H)
    local winPos  = UDim2.new(0.5, -W/2, 0.5, -H/2)

    -- cleanup
    local gp  = guiRoot()
    local old = gp:FindFirstChild("SyntraUI_Window")
    if old then old:Destroy() end

    -- ScreenGui
    local sg = U.make("ScreenGui", {
        Name = "SyntraUI_Window", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100,
    }, gp)

    -- ── Main frame ──────────────────────────────────────────────────────
    local main = U.make("Frame", {
        Name = "Main", Size = UDim2.new(winSize.X.Scale, winSize.X.Offset, 0, 0),
        Position = winPos, BackgroundColor3 = T.Bg, BorderSizePixel = 0,
        ClipsDescendants = true,
    }, sg)
    U.corner(12, main)
    U.stroke(T.Border, 1, main)

    -- drop shadow
    U.make("ImageLabel", {
        Size = UDim2.new(1,60,1,60), Position = UDim2.new(0,-30,0,-30),
        BackgroundTransparency = 1, Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.new(0,0,0), ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(23,23,277,277), ZIndex = 0,
    }, main)

    -- open animation
    U.tween(main, { Size = winSize }, 0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- ── Sidebar ──────────────────────────────────────────────────────────
    local sidebar = U.make("Frame", {
        Name = "Sidebar", Size = UDim2.new(0, SIDE, 1, -BOT),
        BackgroundColor3 = T.Bg2, BorderSizePixel = 0, ZIndex = 3,
    }, main)

    -- sidebar header area
    local sbHead = U.make("Frame", {
        Size = UDim2.new(1, 0, 0, TOP), BackgroundTransparency = 1, ZIndex = 4,
    }, sidebar)

    -- logo image
    U.make("ImageLabel", {
        Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 14, 0.5, -15),
        BackgroundTransparency = 1, Image = resolveImage(logo, "Syntra.png"),
        ScaleType = Enum.ScaleType.Fit, ZIndex = 5,
    }, sbHead)

    -- title
    U.make("TextLabel", {
        Text = title, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = T.Text, BackgroundTransparency = 1,
        Size = UDim2.new(1,-56, 0, 17), Position = UDim2.new(0, 52, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    }, sbHead)

    -- subtitle
    U.make("TextLabel", {
        Text = subtitle ~= "" and subtitle or "dashboard",
        Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = T.TextMuted, BackgroundTransparency = 1,
        Size = UDim2.new(1,-56, 0, 14), Position = UDim2.new(0, 52, 0, 29),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    }, sbHead)

    -- header bottom separator
    U.make("Frame", {
        Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,0,TOP-1),
        BackgroundColor3 = T.Sep, BorderSizePixel = 0, ZIndex = 4,
    }, sidebar)

    -- tab list (scrollable)
    local tabList = U.make("ScrollingFrame", {
        Size = UDim2.new(1,0, 1, -(TOP + 4)),
        Position = UDim2.new(0,0,0, TOP),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3,
    }, sidebar)
    U.pad(8, 8, 8, 8, tabList)
    U.list(Enum.SortOrder.LayoutOrder, 3, tabList)

    -- sidebar right border
    U.make("Frame", {
        Size = UDim2.new(0,1,1,0), Position = UDim2.new(1,-1,0,0),
        BackgroundColor3 = T.Sep, BorderSizePixel = 0, ZIndex = 4,
    }, sidebar)

    -- ── Topbar ───────────────────────────────────────────────────────────
    local topbar = U.make("Frame", {
        Name = "Topbar", Size = UDim2.new(1,-SIDE, 0, TOP),
        Position = UDim2.new(0, SIDE, 0, 0),
        BackgroundColor3 = T.Bg, BorderSizePixel = 0, ZIndex = 3,
    }, main)

    -- topbar bottom line
    U.make("Frame", {
        Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = T.Sep, BorderSizePixel = 0, ZIndex = 4,
    }, topbar)

    -- title label in topbar
    U.make("TextLabel", {
        Text = title, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = T.Text, BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 18), Position = UDim2.new(0, 16, 0.5, -9),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    }, topbar)

    -- breadcrumb subtitle
    if subtitle ~= "" then
        U.make("TextLabel", {
            Text = "/ "..subtitle, Font = Enum.Font.Gotham, TextSize = 12,
            TextColor3 = T.TextMuted, BackgroundTransparency = 1,
            Size = UDim2.new(0, 120, 0, 18), Position = UDim2.new(0, 188, 0.5, -9),
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
        }, topbar)
    end

    -- search box
    local searchBox = U.make("Frame", {
        Size = UDim2.new(0, 196, 0, 30), Position = UDim2.new(1,-316, 0.5,-15),
        BackgroundColor3 = T.Bg3, BorderSizePixel = 0, ZIndex = 5,
    }, topbar)
    U.corner(8, searchBox)
    U.stroke(T.Border, 1, searchBox)

    -- search icon text
    U.make("TextLabel", {
        Text = "⌕", Font = Enum.Font.Gotham, TextSize = 15,
        TextColor3 = T.TextMuted, BackgroundTransparency = 1,
        Size = UDim2.new(0,24, 1, 0), Position = UDim2.new(0, 6, 0, 0),
        ZIndex = 6,
    }, searchBox)

    local searchInput = U.make("TextBox", {
        Text = "", PlaceholderText = searchPH, Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = T.Text, PlaceholderColor3 = T.TextMuted,
        BackgroundTransparency = 1, ClearTextOnFocus = false,
        Size = UDim2.new(1,-34, 1, 0), Position = UDim2.new(0, 28, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
    }, searchBox)

    -- window control buttons
    local function makeWinBtn(symbol, rx, color, hoverColor, callback)
        local btn = U.make("TextButton", {
            Size = UDim2.new(0,24,0,24), Position = UDim2.new(1, rx, 0.5, -12),
            BackgroundColor3 = T.Bg3, Text = "", ZIndex = 6, AutoButtonColor = false,
        }, topbar)
        U.corner(999, btn)
        local lbl = U.make("TextLabel", {
            Text = symbol, Font = Enum.Font.GothamBold, TextSize = 11,
            TextColor3 = T.TextMuted, BackgroundTransparency = 1,
            Size = UDim2.new(1,0,1,0), ZIndex = 7,
        }, btn)
        btn.MouseEnter:Connect(function()
            U.tween(btn, { BackgroundColor3 = hoverColor or color }, 0.12)
            lbl.TextColor3 = Color3.new(1,1,1)
        end)
        btn.MouseLeave:Connect(function()
            U.tween(btn, { BackgroundColor3 = T.Bg3 }, 0.12)
            lbl.TextColor3 = T.TextMuted
        end)
        btn.MouseButton1Click:Connect(function() U.ripple(btn); callback() end)
        return btn
    end

    local minimized = false
    local maximized = false

    makeWinBtn("✕", -28, T.Red, T.Red, function()
        U.tween(main, { Size = UDim2.new(0, W, 0, 0) }, 0.22)
        task.delay(0.24, function() if sg.Parent then sg:Destroy() end end)
    end)
    makeWinBtn("–", -60, T.Yellow, T.Yellow, function()
        minimized = not minimized
        U.tween(main, { Size = minimized and UDim2.new(0,W,0,46) or winSize }, 0.26)
    end)
    makeWinBtn("⤢", -92, T.Green, T.Green, function()
        if minimized then return end
        maximized = not maximized
        if maximized then
            U.tween(main, { Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0) }, 0.28)
        else
            U.tween(main, { Size = winSize, Position = winPos }, 0.28)
        end
    end)

    U.drag(main, topbar)

    -- ── Content / Pages ───────────────────────────────────────────────────
    local content = U.make("Frame", {
        Name = "Content", Size = UDim2.new(1,-SIDE, 1,-(TOP+BOT)),
        Position = UDim2.new(0, SIDE, 0, TOP),
        BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 2,
    }, main)

    local pages = U.make("Frame", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ClipsDescendants = true,
    }, content)

    -- ── Footer ────────────────────────────────────────────────────────────
    local footerFrame = U.make("Frame", {
        Size = UDim2.new(1,0,0,BOT), Position = UDim2.new(0,0,1,-BOT),
        BackgroundColor3 = T.Bg2, BorderSizePixel = 0, ZIndex = 4,
    }, main)
    U.make("Frame", {
        Size = UDim2.new(1,0,0,1), BackgroundColor3 = T.Sep, BorderSizePixel = 0, ZIndex = 5,
    }, footerFrame)
    U.make("TextLabel", {
        Text = footer, Font = Enum.Font.Code, TextSize = 11,
        TextColor3 = T.TextMuted, BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0), ZIndex = 5,
    }, footerFrame)

    -- ── Window object ─────────────────────────────────────────────────────
    local Window = {}
    local tabs   = {}

    local function doSearch()
        local q = string.lower(searchInput.Text or "")
        for _, t in ipairs(tabs) do
            t._btn.Visible = (q == "") or string.lower(t._name or ""):find(q, 1, true) ~= nil
        end
    end
    searchInput:GetPropertyChangedSignal("Text"):Connect(doSearch)

    function Window:SelectTab(name)
        local n = string.lower(name or "")
        for _, t in ipairs(tabs) do
            if string.lower(t._name) == n then t._activate(); return true end
        end
        return false
    end

    -- ╔══════════════════════════════════════════════════════╗
    --  CreateTab
    -- ╚══════════════════════════════════════════════════════╝
    function Window:CreateTab(tOpts)
        tOpts = tOpts or {}
        local tName    = tOpts.Name    or "Tab"
        local isSystem = tOpts.System  == true

        -- sidebar button
        local btn = U.make("TextButton", {
            Name = tName, Size = UDim2.new(1,0,0,36),
            BackgroundColor3 = T.Bg3, BackgroundTransparency = 1,
            Text = tName, Font = Enum.Font.GothamSemibold, TextSize = 13,
            TextColor3 = T.TextSub, TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false, ZIndex = 4,
        }, tabList)
        U.corner(8, btn)
        U.pad(0,0,14,8, btn)

        -- active indicator bar
        local indicator = U.make("Frame", {
            Size = UDim2.new(0,3,0,20), Position = UDim2.new(0,0,0.5,-10),
            BackgroundColor3 = T.Accent, BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 5,
        }, btn)
        U.corner(999, indicator)

        -- page
        local page = U.make("ScrollingFrame", {
            Name = tName.."_Page", Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
            ScrollBarThickness = 4, ScrollBarImageColor3 = T.Accent,
            CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 2,
        }, pages)
        U.pad(16,16,16,16, page)
        U.list(Enum.SortOrder.LayoutOrder, 8, page)

        local tab = { _name = tName, _btn = btn, _page = page, _indicator = indicator }
        table.insert(tabs, tab)
        doSearch()

        local function activate()
            for _, t in ipairs(tabs) do
                t._page.Visible = false
                U.tween(t._btn, { BackgroundTransparency = 1, TextColor3 = T.TextSub }, 0.15)
                U.tween(t._indicator, { BackgroundTransparency = 1 }, 0.15)
            end
            page.Visible = true
            U.tween(btn, { BackgroundTransparency = 0.0, TextColor3 = T.Text }, 0.15)
            U.tween(indicator, { BackgroundTransparency = 0 }, 0.15)
            Window._activeTab = tab
        end
        tab._activate = activate

        btn.MouseButton1Click:Connect(function() U.ripple(btn); activate() end)
        btn.MouseEnter:Connect(function()
            if Window._activeTab ~= tab then U.tween(btn, { BackgroundTransparency = 0.6 }, 0.1) end
        end)
        btn.MouseLeave:Connect(function()
            if Window._activeTab ~= tab then U.tween(btn, { BackgroundTransparency = 1 }, 0.1) end
        end)

        -- auto-activate first user tab
        if #tabs == 1 or (Window._nextUserTab and not isSystem) then
            activate()
            if not isSystem then Window._nextUserTab = false end
        end

        -- ── components ───────────────────────────────────────────────────
        local Tab = {}

        local function container(h, clip)
            local c = U.make("Frame", {
                Size = UDim2.new(1,0,0,h), BackgroundColor3 = T.Surface,
                BorderSizePixel = 0, ClipsDescendants = clip ~= false,
            }, page)
            U.corner(8, c)
            U.stroke(T.Border, 1, c)
            return c
        end

        -- SECTION
        function Tab:AddSection(name)
            local w = U.make("Frame", {
                Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1,
            }, page)
            U.make("Frame", {
                Size = UDim2.new(0,3,0,13), Position = UDim2.new(0,0,0.5,-6.5),
                BackgroundColor3 = T.Accent, BorderSizePixel = 0,
            }, w):FindFirstChildOfClass("UICorner") or U.corner(999, w:FindFirstChildOfClass("Frame"))
            U.corner(999, w:FindFirstChildOfClass("Frame"))
            U.make("TextLabel", {
                Text = name:upper(), Font = Enum.Font.GothamBold, TextSize = 10,
                TextColor3 = T.Accent, BackgroundTransparency = 1,
                Size = UDim2.new(1,-10, 1, 0), Position = UDim2.new(0,10,0,0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, w)
            U.make("Frame", {
                Size = UDim2.new(1,-108, 0, 1), Position = UDim2.new(0, 104, 0.5, 0),
                BackgroundColor3 = T.Sep, BorderSizePixel = 0,
            }, w)
        end

        -- LABEL
        function Tab:AddLabel(text)
            local lbl = U.make("TextLabel", {
                Text = text, Font = Enum.Font.Gotham, TextSize = 13,
                TextColor3 = T.TextSub, BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,24), TextXAlignment = Enum.TextXAlignment.Left,
            }, page)
            U.pad(0,0,4,0, lbl)
            return { Set = function(_, t) lbl.Text = tostring(t) end, Get = function(_) return lbl.Text end }
        end

        -- PARAGRAPH
        function Tab:AddParagraph(pOpts)
            pOpts = pOpts or {}
            local pt = pOpts.Title or ""; local pc = pOpts.Content or ""
            local h  = (pt ~= "" and 22 or 0) + math.max(1, math.ceil(#pc/56))*16 + 18
            local c  = container(h)
            if pt ~= "" then
                U.make("TextLabel", {
                    Text = pt, Font = Enum.Font.GothamBold, TextSize = 12,
                    TextColor3 = T.AccentHover, BackgroundTransparency = 1,
                    Size = UDim2.new(1,-16,0,18), Position = UDim2.new(0,10,0,6),
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, c)
            end
            U.make("TextLabel", {
                Text = pc, Font = Enum.Font.Gotham, TextSize = 12,
                TextColor3 = T.TextSub, BackgroundTransparency = 1,
                Size = UDim2.new(1,-16, 1, pt ~= "" and -26 or 0),
                Position = UDim2.new(0,10, 0, pt ~= "" and 24 or 6),
                TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
            }, c)
        end

        -- BUTTON
        function Tab:AddButton(bOpts)
            bOpts = bOpts or {}
            local bn = bOpts.Name or "Button"; local bd = bOpts.Desc; local cb = bOpts.Callback or function() end
            local h  = bd and 54 or 38
            local c  = container(h)

            local nl = U.make("TextLabel", {
                Text = bn, Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextColor3 = T.Text, BackgroundTransparency = 1,
                Size = UDim2.new(1,-38,0,20), Position = UDim2.new(0,12,0, bd and 7 or 9),
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
            }, c)
            if bd then
                U.make("TextLabel", {
                    Text = bd, Font = Enum.Font.Gotham, TextSize = 11,
                    TextColor3 = T.TextSub, BackgroundTransparency = 1,
                    Size = UDim2.new(1,-38,0,18), Position = UDim2.new(0,12,0,28),
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
                }, c)
            end
            U.make("TextLabel", {
                Text = "›", Font = Enum.Font.GothamBold, TextSize = 22,
                TextColor3 = T.Accent, BackgroundTransparency = 1,
                Size = UDim2.new(0,24,1,0), Position = UDim2.new(1,-28,0,0), ZIndex = 2,
            }, c)
            local over = U.make("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 3,
            }, c)
            over.MouseButton1Click:Connect(function(mx, my)
                U.ripple(c, mx, my)
                U.tween(c, { BackgroundColor3 = T.Bg4 }, 0.07)
                task.delay(0.07, function() U.tween(c, { BackgroundColor3 = T.Surface }, 0.18) end)
                cb()
            end)
            over.MouseEnter:Connect(function() U.tween(c, { BackgroundColor3 = T.Bg3 }, 0.12) end)
            over.MouseLeave:Connect(function() U.tween(c, { BackgroundColor3 = T.Surface }, 0.12) end)
            return { SetName = function(_, t) nl.Text = t end }
        end

        -- TOGGLE
        function Tab:AddToggle(tOpts)
            tOpts = tOpts or {}
            local tn = tOpts.Name or "Toggle"; local td = tOpts.Desc
            local st = tOpts.Default or false; local cb = tOpts.Callback or function() end
            local h  = td and 54 or 38
            local c  = container(h)

            U.make("TextLabel", {
                Text = tn, Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextColor3 = T.Text, BackgroundTransparency = 1,
                Size = UDim2.new(1,-64,0,20), Position = UDim2.new(0,12,0, td and 7 or 9),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, c)
            if td then
                U.make("TextLabel", {
                    Text = td, Font = Enum.Font.Gotham, TextSize = 11,
                    TextColor3 = T.TextSub, BackgroundTransparency = 1,
                    Size = UDim2.new(1,-64,0,18), Position = UDim2.new(0,12,0,28),
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, c)
            end

            local track = U.make("Frame", {
                Size = UDim2.new(0,42,0,24), Position = UDim2.new(1,-54,0.5,-12),
                BackgroundColor3 = T.Border,
            }, c)
            U.corner(999, track)
            local glw = U.make("Frame", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = T.Accent, BackgroundTransparency = 1 }, track)
            U.corner(999, glw)
            local knob = U.make("Frame", {
                Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,3,0.5,-9),
                BackgroundColor3 = Color3.new(1,1,1), ZIndex = 2,
            }, track)
            U.corner(999, knob)

            local state = st
            local function set(v, silent)
                state = v
                if v then
                    U.tween(track, { BackgroundColor3 = T.Accent }, 0.18)
                    U.tween(glw,   { BackgroundTransparency = 0.82 }, 0.18)
                    U.tween(knob,  { Position = UDim2.new(0,21,0.5,-9) }, 0.18)
                else
                    U.tween(track, { BackgroundColor3 = T.Border }, 0.18)
                    U.tween(glw,   { BackgroundTransparency = 1 }, 0.18)
                    U.tween(knob,  { Position = UDim2.new(0,3,0.5,-9) }, 0.18)
                end
                if not silent then cb(v) end
            end
            set(st, true)

            local over = U.make("TextButton", {
                Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 3,
            }, c)
            over.MouseButton1Click:Connect(function() U.ripple(c); set(not state) end)
            return { Set = function(_, v) set(v, true) end, Get = function(_) return state end }
        end

        -- SLIDER
        function Tab:AddSlider(sOpts)
            sOpts = sOpts or {}
            local sn = sOpts.Name or "Slider"; local sMin = sOpts.Min or 0; local sMax = sOpts.Max or 100
            local sv = sOpts.Default or sMin; local sx = sOpts.Suffix or ""; local ss = sOpts.Step or 1
            local cb = sOpts.Callback or function() end
            local val = math.clamp(sv, sMin, sMax)
            local c   = container(62)

            U.make("TextLabel", {
                Text = sn, Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextColor3 = T.Text, BackgroundTransparency = 1,
                Size = UDim2.new(1,-80,0,20), Position = UDim2.new(0,12,0,7),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, c)

            local valBox = U.make("Frame", {
                Size = UDim2.new(0,58,0,22), Position = UDim2.new(1,-70,0,6),
                BackgroundColor3 = T.Bg3,
            }, c)
            U.corner(6, valBox)
            local valLbl = U.make("TextLabel", {
                Text = tostring(val)..sx, Font = Enum.Font.GothamBold, TextSize = 12,
                TextColor3 = T.AccentHover, BackgroundTransparency = 1,
                Size = UDim2.new(1,0,1,0),
            }, valBox)

            local trackF = U.make("Frame", {
                Size = UDim2.new(1,-24,0,5), Position = UDim2.new(0,12,0,40),
                BackgroundColor3 = T.Border,
            }, c)
            U.corner(999, trackF)
            local fillF = U.make("Frame", { Size = UDim2.new(0,0,1,0), BackgroundColor3 = T.Accent }, trackF)
            U.corner(999, fillF)
            local knob = U.make("Frame", {
                Size = UDim2.new(0,14,0,14), AnchorPoint = Vector2.new(.5,.5),
                Position = UDim2.new(0,0,0.5,0), BackgroundColor3 = T.Text, ZIndex = 3,
            }, trackF)
            U.corner(999, knob)
            U.stroke(T.Accent, 2, knob)

            local p0 = (val-sMin)/(sMax-sMin)
            fillF.Size = UDim2.new(p0,0,1,0); knob.Position = UDim2.new(p0,0,.5,0)

            local drag = false
            local function upd(sx2)
                local p = math.clamp((sx2 - trackF.AbsolutePosition.X)/trackF.AbsoluteSize.X, 0, 1)
                val = math.clamp(math.round((sMin+(sMax-sMin)*p)/ss)*ss, sMin, sMax)
                local dp = (val-sMin)/(sMax-sMin)
                valLbl.Text = tostring(val)..sx
                U.tween(fillF, { Size = UDim2.new(dp,0,1,0) }, 0.06)
                U.tween(knob,  { Position = UDim2.new(dp,0,.5,0) }, 0.06)
                cb(val)
            end
            trackF.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; upd(i.Position.X) end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if drag and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
            end)
            return { Set = function(_, v)
                val = math.clamp(math.round(v/ss)*ss, sMin, sMax)
                local dp = (val-sMin)/(sMax-sMin)
                valLbl.Text = tostring(val)..sx
                U.tween(fillF, { Size = UDim2.new(dp,0,1,0) }, 0.14)
                U.tween(knob,  { Position = UDim2.new(dp,0,.5,0) }, 0.14)
            end, Get = function(_) return val end }
        end

        -- TEXTBOX
        function Tab:AddTextBox(tbOpts)
            tbOpts = tbOpts or {}
            local tn = tbOpts.Name or "Input"; local tp = tbOpts.Placeholder or "Type here..."
            local td2 = tbOpts.Default or ""; local cb = tbOpts.Callback or function() end
            local c = container(62)
            U.make("TextLabel", {
                Text = tn, Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextColor3 = T.Text, BackgroundTransparency = 1,
                Size = UDim2.new(1,-16,0,20), Position = UDim2.new(0,12,0,6),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, c)
            local bg = U.make("Frame", {
                Size = UDim2.new(1,-24,0,27), Position = UDim2.new(0,12,0,30),
                BackgroundColor3 = T.Bg3,
            }, c)
            U.corner(7, bg)
            local st2 = U.stroke(T.Sep, 1, bg)
            local tb = U.make("TextBox", {
                Size = UDim2.new(1,-14,1,0), Position = UDim2.new(0,8,0,0),
                BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12,
                TextColor3 = T.Text, PlaceholderText = tp, PlaceholderColor3 = T.TextMuted,
                Text = td2, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
            }, bg)
            tb.Focused:Connect(function() U.tween(st2, { Color = T.Accent }, 0.15); U.tween(bg, { BackgroundColor3 = T.Bg4 }, 0.15) end)
            tb.FocusLost:Connect(function(e) U.tween(st2, { Color = T.Sep }, 0.15); U.tween(bg, { BackgroundColor3 = T.Bg3 }, 0.15); cb(tb.Text, e) end)
            return { Set = function(_, t) tb.Text = t end, Get = function(_) return tb.Text end }
        end

        -- DROPDOWN
        function Tab:AddDropdown(ddOpts)
            ddOpts = ddOpts or {}
            local dn = ddOpts.Name or "Dropdown"; local dopts = ddOpts.Options or {}
            local ddef = ddOpts.Default or dopts[1]; local cb = ddOpts.Callback or function() end
            local sel = ddef; local open = false

            local c = U.make("Frame", {
                Size = UDim2.new(1,0,0,38), BackgroundColor3 = T.Surface,
                BorderSizePixel = 0, ClipsDescendants = false, ZIndex = 5,
            }, page)
            U.corner(8, c); U.stroke(T.Border,1,c)

            U.make("TextLabel", {
                Text = dn, Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextColor3 = T.Text, BackgroundTransparency = 1,
                Size = UDim2.new(0.48,0,1,0), Position = UDim2.new(0,12,0,0),
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
            }, c)
            local selLbl = U.make("TextLabel", {
                Text = sel or "Select...", Font = Enum.Font.Gotham, TextSize = 12,
                TextColor3 = T.TextSub, BackgroundTransparency = 1,
                Size = UDim2.new(0.44,-28,1,0), Position = UDim2.new(0.5,0,0,0),
                TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
            }, c)
            local arrow = U.make("TextLabel", {
                Text = "⌄", Font = Enum.Font.GothamBold, TextSize = 14,
                TextColor3 = T.Accent, BackgroundTransparency = 1,
                Size = UDim2.new(0,22,1,0), Position = UDim2.new(1,-24,0,0), ZIndex = 6,
            }, c)

            local menu = U.make("Frame", {
                Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,1,4),
                BackgroundColor3 = T.Bg4, ClipsDescendants = true, Visible = false, ZIndex = 14,
            }, c)
            U.corner(8, menu); U.stroke(T.BorderBright, 1, menu)
            U.list(Enum.SortOrder.LayoutOrder, 0, menu)
            U.pad(4,4,0,0, menu)

            for _, opt in ipairs(dopts) do
                local oBg = U.make("TextButton", {
                    Size = UDim2.new(1,0,0,30), BackgroundColor3 = T.Bg4,
                    BackgroundTransparency = 1, Text = opt, Font = Enum.Font.Gotham, TextSize = 12,
                    TextColor3 = opt == sel and T.Text or T.TextSub,
                    TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 15,
                }, menu)
                U.pad(0,0,10,0,oBg)
                oBg.MouseEnter:Connect(function() U.tween(oBg, { BackgroundTransparency = 0.5 }, 0.1) end)
                oBg.MouseLeave:Connect(function() U.tween(oBg, { BackgroundTransparency = 1 }, 0.1) end)
                oBg.MouseButton1Click:Connect(function()
                    sel = opt; selLbl.Text = opt; cb(sel)
                    open = false
                    U.tween(menu, { Size = UDim2.new(1,0,0,0) }, 0.18); menu.Visible = false
                    U.tween(arrow, { Rotation = 0 }, 0.18)
                end)
            end

            local hMenu = math.min(#dopts * 30 + 8, 160)
            local over = U.make("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=7 }, c)
            over.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    menu.Visible = true
                    U.tween(menu, { Size = UDim2.new(1,0,0,hMenu) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    U.tween(arrow, { Rotation = 180 }, 0.18)
                else
                    U.tween(menu, { Size = UDim2.new(1,0,0,0) }, 0.18)
                    task.delay(0.19, function() menu.Visible = false end)
                    U.tween(arrow, { Rotation = 0 }, 0.18)
                end
            end)
            return { Set = function(_,v) sel=v; selLbl.Text=v end, Get = function(_) return sel end }
        end

        -- KEYBIND
        function Tab:AddKeybind(kOpts)
            kOpts = kOpts or {}
            local kn = kOpts.Name or "Keybind"; local kd = kOpts.Default or Enum.KeyCode.F
            local cb = kOpts.Callback or function() end
            local key = kd; local listening = false
            local c = container(38)
            U.make("TextLabel", {
                Text = kn, Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextColor3 = T.Text, BackgroundTransparency = 1,
                Size = UDim2.new(1,-90,0,38), Position = UDim2.new(0,12,0,0),
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
            }, c)
            local kBox = U.make("Frame", {
                Size = UDim2.new(0,72,0,26), Position = UDim2.new(1,-80,0.5,-13),
                BackgroundColor3 = T.Bg3, ZIndex = 2,
            }, c)
            U.corner(7, kBox)
            U.stroke(T.Border,1,kBox)
            local kLbl = U.make("TextLabel", {
                Text = tostring(key.Name), Font = Enum.Font.GothamBold, TextSize = 11,
                TextColor3 = T.Accent, BackgroundTransparency = 1,
                Size = UDim2.new(1,0,1,0), ZIndex = 3,
            }, kBox)
            local over = U.make("TextButton", { Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=3 }, c)
            over.MouseButton1Click:Connect(function()
                listening = true; kLbl.Text = "..."; kLbl.TextColor3 = T.Yellow
            end)
            UserInputService.InputBegan:Connect(function(inp, gp2)
                if not listening or gp2 then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    key = inp.KeyCode; listening = false
                    kLbl.Text = key.Name; kLbl.TextColor3 = T.Accent
                end
            end)
            UserInputService.InputBegan:Connect(function(inp)
                if not listening and inp.KeyCode == key then cb(key) end
            end)
            return { Get = function(_) return key end }
        end

        return Tab
    end -- CreateTab

    -- ── Built-in Settings Tab ────────────────────────────────────────────
    do
        local st = Window:CreateTab({ Name = "Settings", System = true })

        st:AddSection("Appearance")
        st:AddToggle({
            Name = "Compact Mode", Desc = "Reduce element spacing",
            Default = false, Callback = function(v)
                local pad = v and 4 or 8
                for _, p in ipairs(pages:GetChildren()) do
                    if p:IsA("ScrollingFrame") then
                        local l = p:FindFirstChildOfClass("UIListLayout")
                        if l then l.Padding = UDim.new(0, pad) end
                    end
                end
            end,
        })
        st:AddSlider({
            Name = "UI Scale", Min = 70, Max = 130, Default = 100, Suffix = "%", Step = 5,
            Callback = function(v)
                local sc = sg:FindFirstChildOfClass("UIScale")
                if not sc then sc = U.make("UIScale", {}, sg) end
                sc.Scale = v / 100
            end,
        })

        st:AddSection("Window")
        st:AddButton({ Name = "Reset Position", Desc = "Move window back to center",
            Callback = function() U.tween(main, { Position = winPos }, 0.3, Enum.EasingStyle.Back) end })
        st:AddButton({ Name = "Reset Size", Desc = "Restore default window size",
            Callback = function()
                maximized = false
                U.tween(main, { Size = winSize, Position = winPos }, 0.3, Enum.EasingStyle.Back)
            end })

        st:AddSection("Information")
        st:AddParagraph({ Title = "Executor", Content = Executor.Name..(Executor.Version ~= "" and " "..Executor.Version or "") })
        st:AddParagraph({ Title = "SyntraUI", Content = "v3.0 – Potassium Edition  |  by Lorthanyx" })
        st:AddParagraph({ Title = "Game", Content = "PlaceId: "..tostring(game.PlaceId).."  |  GameId: "..tostring(game.GameId) })

        st:AddSection("Actions")
        st:AddButton({ Name = "Close Dashboard", Desc = "Destroy the entire UI",
            Callback = function()
                U.tween(main, { Size = UDim2.new(0,W,0,0) }, 0.2)
                task.delay(0.22, function() if sg.Parent then sg:Destroy() end end)
            end })
    end

    Window._nextUserTab = true
    return Window
end -- CreateWindow

-- ══════════════════════════════════════════════════════════════════════════
--  CONFIG API
-- ══════════════════════════════════════════════════════════════════════════
function SyntraUI:GetConfigPath(name)
    return FOLDER.."/configs/"..tostring(name or "default")..".json"
end

function SyntraUI:SaveConfig(name, data)
    if not writefile then return false, "writefile not available" end
    ensureFolder(FOLDER.."/configs")
    local ok, enc = pcall(function() return HttpService:JSONEncode(data or {}) end)
    if not ok then return false, enc end
    writefile(self:GetConfigPath(name), enc); return true
end

function SyntraUI:LoadConfig(name, def)
    if not (isfile and readfile) then return def or {} end
    local p = self:GetConfigPath(name)
    if not isfile(p) then return def or {} end
    local ok, dec = pcall(function() return HttpService:JSONDecode(readfile(p)) end)
    return ok and dec or (def or {})
end

-- ══════════════════════════════════════════════════════════════════════════
--  THEME / EXECUTOR API
-- ══════════════════════════════════════════════════════════════════════════
function SyntraUI:SetTheme(custom)
    for k, v in pairs(custom) do if T[k] ~= nil then T[k] = v end end
end

function SyntraUI:GetTheme() return T end

function SyntraUI:GetExecutor() return Executor.Name, Executor.Version end

function SyntraUI:IsPotassium()
    return string.lower(tostring(Executor.Name)):find("potassium", 1, true) ~= nil
end

-- ══════════════════════════════════════════════════════════════════════════
return SyntraUI
