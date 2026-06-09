--[[
    SyntraUI
    A modern single-file Roblox UI library for script hubs.

    Basic usage:

    local SyntraUI = loadstring(game:HttpGet(".../SyntraUI.lua"))()

    local Window = SyntraUI:CreateWindow({
        Name = "Syntra",
        Subtitle = "Dashboard",
        LoadingTitle = "Syntra",
        LoadingSubtitle = "Preparing interface",
        LoadingImage = "SyntraUi.png", -- optional custom asset path or rbxassetid
        Theme = "Midnight",
        ToggleKeybind = Enum.KeyCode.RightControl,
        SaveConfiguration = true,
        ConfigurationFolder = "Syntra",
        ConfigurationFile = "Main"
    })

    local Tab = Window:CreateTab("Main", "Home")
    local Section = Tab:CreateSection("Automation")

    Section:CreateButton({
        Name = "Run Task",
        Callback = function()
            Window:Notify({ Title = "Syntra", Content = "Task started." })
        end
    })
]]

local SyntraUI = {}
SyntraUI.Version = "2.0.0"
SyntraUI.Flags = {}
SyntraUI.Windows = {}
SyntraUI.ActiveThemeName = "Midnight"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")

local DEFAULT_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FAST_TWEEN = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SPRING_TWEEN = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SOFT_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local SYNTRA_LOGO_URL = "https://raw.githubusercontent.com/PixelGG/RobloxExecuter/main/SyntraUI.png"
local SYNTRA_LOGO_CACHE = "Syntra/SyntraUI.png"
local ActiveTweens = setmetatable({}, { __mode = "k" })

local Themes = {
    Midnight = {
        Background = Color3.fromRGB(12, 14, 22),
        Surface = Color3.fromRGB(18, 21, 31),
        SurfaceLight = Color3.fromRGB(26, 30, 43),
        SurfaceHover = Color3.fromRGB(33, 38, 55),
        Stroke = Color3.fromRGB(48, 55, 77),
        Text = Color3.fromRGB(239, 244, 255),
        MutedText = Color3.fromRGB(152, 164, 191),
        Accent = Color3.fromRGB(92, 164, 255),
        AccentSecondary = Color3.fromRGB(134, 94, 255),
        Success = Color3.fromRGB(72, 210, 149),
        Warning = Color3.fromRGB(245, 187, 83),
        Danger = Color3.fromRGB(255, 101, 116),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    Obsidian = {
        Background = Color3.fromRGB(8, 10, 12),
        Surface = Color3.fromRGB(15, 17, 20),
        SurfaceLight = Color3.fromRGB(23, 26, 31),
        SurfaceHover = Color3.fromRGB(31, 35, 42),
        Stroke = Color3.fromRGB(56, 62, 72),
        Text = Color3.fromRGB(245, 247, 250),
        MutedText = Color3.fromRGB(157, 165, 177),
        Accent = Color3.fromRGB(75, 221, 176),
        AccentSecondary = Color3.fromRGB(80, 148, 255),
        Success = Color3.fromRGB(85, 220, 150),
        Warning = Color3.fromRGB(255, 192, 90),
        Danger = Color3.fromRGB(255, 95, 120),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    Aurora = {
        Background = Color3.fromRGB(13, 16, 25),
        Surface = Color3.fromRGB(20, 24, 36),
        SurfaceLight = Color3.fromRGB(30, 35, 51),
        SurfaceHover = Color3.fromRGB(39, 45, 64),
        Stroke = Color3.fromRGB(61, 70, 96),
        Text = Color3.fromRGB(241, 246, 255),
        MutedText = Color3.fromRGB(161, 171, 198),
        Accent = Color3.fromRGB(103, 232, 249),
        AccentSecondary = Color3.fromRGB(167, 139, 250),
        Success = Color3.fromRGB(110, 231, 183),
        Warning = Color3.fromRGB(251, 191, 36),
        Danger = Color3.fromRGB(251, 113, 133),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    Crimson = {
        Background = Color3.fromRGB(16, 12, 15),
        Surface = Color3.fromRGB(25, 18, 23),
        SurfaceLight = Color3.fromRGB(37, 27, 34),
        SurfaceHover = Color3.fromRGB(48, 35, 44),
        Stroke = Color3.fromRGB(77, 55, 68),
        Text = Color3.fromRGB(255, 241, 246),
        MutedText = Color3.fromRGB(195, 158, 173),
        Accent = Color3.fromRGB(255, 92, 135),
        AccentSecondary = Color3.fromRGB(255, 154, 92),
        Success = Color3.fromRGB(77, 210, 145),
        Warning = Color3.fromRGB(245, 185, 79),
        Danger = Color3.fromRGB(255, 87, 87),
        Shadow = Color3.fromRGB(0, 0, 0)
    }
}

SyntraUI.Themes = Themes

local function currentTheme()
    return Themes[SyntraUI.ActiveThemeName] or Themes.Midnight
end

local function protect(callback, ...)
    if typeof(callback) ~= "function" then
        return nil
    end

    local packed = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(packed, 1, packed.n))
        end)

        if not ok then
            warn("[SyntraUI] Callback error: " .. tostring(err))
        end
    end)
end

local function merge(defaults, options)
    local result = {}
    for key, value in pairs(defaults or {}) do
        result[key] = value
    end
    for key, value in pairs(options or {}) do
        result[key] = value
    end
    return result
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function round(value, decimals)
    local power = 10 ^ (decimals or 0)
    return math.floor(value * power + 0.5) / power
end

local function colorToTable(color)
    if typeof(color) ~= "Color3" then
        return nil
    end

    return {
        R = math.floor(color.R * 255 + 0.5),
        G = math.floor(color.G * 255 + 0.5),
        B = math.floor(color.B * 255 + 0.5)
    }
end

local function tableToColor(value, fallback)
    if typeof(value) == "Color3" then
        return value
    end

    if typeof(value) == "table" and value.R and value.G and value.B then
        return Color3.fromRGB(
            clamp(tonumber(value.R) or 255, 0, 255),
            clamp(tonumber(value.G) or 255, 0, 255),
            clamp(tonumber(value.B) or 255, 0, 255)
        )
    end

    return fallback or Color3.fromRGB(255, 255, 255)
end

local function getParent()
    if gethui then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    return CoreGui or PlayerGui
end

local tryCustomAsset

local function requestBody(url)
    local req = request or http_request or (http and http.request) or (syn and syn.request) or (fluxus and fluxus.request)
    if req then
        local ok, response = pcall(function()
            return req({
                Url = url,
                Method = "GET",
                Headers = { ["User-Agent"] = "SyntraUI" }
            })
        end)

        if ok and response and (response.Success or response.StatusCode == 200) and response.Body then
            return response.Body
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)

    if ok and body and body ~= "" then
        return body
    end

    return nil
end

local function ensureFolderPath(path)
    if typeof(makefolder) ~= "function" or typeof(isfolder) ~= "function" then
        return false
    end

    local current = ""
    for part in tostring(path):gmatch("[^/]+") do
        current = current == "" and part or (current .. "/" .. part)
        if not isfolder(current) then
            local ok = pcall(makefolder, current)
            if not ok then
                return false
            end
        end
    end

    return true
end

local function resolveImageAsset(asset)
    asset = asset or SYNTRA_LOGO_URL

    if typeof(asset) ~= "string" or asset == "" then
        return ""
    end

    if asset:lower() == "syntraui.png" then
        asset = SYNTRA_LOGO_URL
    end

    if asset:find("http", 1, true) then
        if typeof(getcustomasset) == "function"
            and typeof(writefile) == "function"
            and typeof(isfile) == "function"
            and typeof(readfile) == "function" then

            local cachePath = SYNTRA_LOGO_CACHE
            if not isfile(cachePath) then
                ensureFolderPath("Syntra")
                local body = requestBody(asset)
                if body and #body > 0 then
                    pcall(writefile, cachePath, body)
                end
            end

            if isfile(cachePath) then
                local ok, result = pcall(getcustomasset, cachePath)
                if ok and result then
                    return result
                end
            end
        end

        return asset
    end

    return tryCustomAsset(asset)
end

tryCustomAsset = function(asset)
    if typeof(asset) ~= "string" or asset == "" then
        return ""
    end

    if asset:find("rbxasset", 1, true) or asset:find("http", 1, true) then
        return asset
    end

    if getcustomasset then
        local ok, result = pcall(getcustomasset, asset)
        if ok and result then
            return result
        end
    end

    return asset
end

local function new(className, properties, children)
    local instance = Instance.new(className)

    for property, value in pairs(properties or {}) do
        instance[property] = value
    end

    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end

    return instance
end

local function corner(radius)
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius or 10)
    })
end

local function stroke(color, transparency, thickness)
    return new("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or currentTheme().Stroke,
        Transparency = transparency or 0.35,
        Thickness = thickness or 1
    })
end

local function padding(left, top, right, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0)
    })
end

local function gradient(colorA, colorB, rotation, transparency)
    return new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colorA),
            ColorSequenceKeypoint.new(1, colorB)
        }),
        Rotation = rotation or 0,
        Transparency = transparency or NumberSequence.new(0)
    })
end

local function tween(instance, info, properties)
    if not instance or not instance.Parent then
        return nil
    end

    ActiveTweens[instance] = ActiveTweens[instance] or {}
    local activeForInstance = ActiveTweens[instance]

    for property in pairs(properties or {}) do
        if activeForInstance[property] then
            pcall(function()
                activeForInstance[property]:Cancel()
            end)
            activeForInstance[property] = nil
        end
    end

    local tweenObject = TweenService:Create(instance, info or DEFAULT_TWEEN, properties)
    for property in pairs(properties or {}) do
        activeForInstance[property] = tweenObject
    end

    tweenObject.Completed:Connect(function()
        if ActiveTweens[instance] == activeForInstance then
            for property in pairs(properties or {}) do
                if activeForInstance[property] == tweenObject then
                    activeForInstance[property] = nil
                end
            end
        end
    end)

    tweenObject:Play()
    return tweenObject
end

local function bindHover(button, normalProps, hoverProps)
    button.MouseEnter:Connect(function()
        tween(button, FAST_TWEEN, hoverProps)
    end)

    button.MouseLeave:Connect(function()
        tween(button, FAST_TWEEN, normalProps)
    end)
end

local function makeText(parent, text, size, weight, color, align)
    return new("TextLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Font = weight or Enum.Font.GothamMedium,
        Text = text or "",
        TextColor3 = color or currentTheme().Text,
        TextSize = size or 14,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
end

local function makeButton(parent, name)
    return new("TextButton", {
        Parent = parent,
        AutoButtonColor = false,
        BackgroundColor3 = currentTheme().SurfaceLight,
        BorderSizePixel = 0,
        Text = name or "",
        TextColor3 = currentTheme().Text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium
    })
end

local function layoutContent(scrollFrame, paddingTop)
    local layout = new("UIListLayout", {
        Parent = scrollFrame,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    padding(2, paddingTop or 2, 8, 12).Parent = scrollFrame

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 18)
    end)

    return layout
end

local function makeCard(parent, height)
    local theme = currentTheme()
    local card = new("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 48)
    }, {
        corner(9),
        stroke(theme.Stroke, 0.58, 1)
    })

    return card
end

local function createShadow(parent, radius)
    local shadow = new("ImageLabel", {
        Parent = parent,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = currentTheme().Shadow,
        ImageTransparency = 0.55,
        Position = UDim2.fromScale(0.5, 0.5),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, radius or 38, 1, radius or 38),
        ZIndex = 0
    })

    return shadow
end

local Config = {}

function Config:canUseFiles()
    return typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
        and typeof(isfolder) == "function"
        and typeof(makefolder) == "function"
end

function Config:path(folder, file)
    return tostring(folder or "Syntra") .. "/" .. tostring(file or "Config") .. ".json"
end

function Config:load(folder, file)
    if not self:canUseFiles() then
        return {}
    end

    local path = self:path(folder, file)
    if not isfile(path) then
        return {}
    end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if ok and typeof(decoded) == "table" then
        return decoded
    end

    return {}
end

function Config:save(folder, file, data)
    if not self:canUseFiles() then
        return false
    end

    local ok = pcall(function()
        if not isfolder(folder) then
            makefolder(folder)
        end

        writefile(self:path(folder, file), HttpService:JSONEncode(data or {}))
    end)

    return ok
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local BaseControl = {}
BaseControl.__index = BaseControl

local function registerThemeObject(window, instance, property, key, alpha)
    table.insert(window._themeObjects, {
        Instance = instance,
        Property = property,
        Key = key,
        Alpha = alpha
    })
end

local function themed(window, instance, property, key, alpha)
    registerThemeObject(window, instance, property, key, alpha)
    local value = currentTheme()[key]
    if value then
        instance[property] = value
    end
end

local function registerControl(window, control)
    table.insert(window._controls, control)

    if control.Section and control.Section.Controls then
        table.insert(control.Section.Controls, control)
    end

    if control.Flag then
        window.Flags[control.Flag] = control
        SyntraUI.Flags[control.Flag] = control.GetFlagValue and control:GetFlagValue() or control.Value
    end
end

local function setFlag(control, value, save)
    control.Value = value

    if control.Flag then
        SyntraUI.Flags[control.Flag] = value
        control.Window.Configuration.Values[control.Flag] = value
        if save ~= false then
            control.Window:SaveConfiguration()
        end
    end
end

function BaseControl:Get()
    return self.Value
end

function BaseControl:Set(value)
    if self.SetValue then
        self:SetValue(value)
    end
end

function BaseControl:SetVisible(visible)
    if self.Instance then
        self.Instance.Visible = visible and true or false
    end
end

function BaseControl:SetEnabled(enabled)
    self.Enabled = enabled and true or false

    if self.Instance then
        self.Instance.BackgroundTransparency = self.Enabled and 0.08 or 0.42
    end

    if self.Label then
        self.Label.TextTransparency = self.Enabled and 0 or 0.45
    end
end

function BaseControl:Destroy()
    if self.Instance then
        self.Instance:Destroy()
    end
end

function SyntraUI:AddTheme(name, theme)
    assert(typeof(name) == "string", "Theme name must be a string")
    assert(typeof(theme) == "table", "Theme must be a table")

    Themes[name] = merge(Themes.Midnight, theme)
    return Themes[name]
end

function SyntraUI:SetTheme(name)
    if not Themes[name] then
        warn("[SyntraUI] Unknown theme: " .. tostring(name))
        return false
    end

    SyntraUI.ActiveThemeName = name
    for _, window in ipairs(SyntraUI.Windows) do
        window:SetTheme(name)
    end

    return true
end

function SyntraUI:GetThemes()
    local names = {}
    for name in pairs(Themes) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function SyntraUI:GetFlag(flag)
    return SyntraUI.Flags[flag]
end

function SyntraUI:SetFlag(flag, value)
    for _, window in ipairs(SyntraUI.Windows) do
        local control = window.Flags[flag]
        if control and control.SetValue then
            control:SetValue(value)
            return true
        end
    end

    SyntraUI.Flags[flag] = value
    return false
end

function SyntraUI:Notify(options)
    local window = SyntraUI.Windows[#SyntraUI.Windows]
    if window then
        return window:Notify(options)
    end
end

local function createLoadingScreen(options)
    options = options or {}
    local theme = currentTheme()

    local gui = new("ScreenGui", {
        Name = "SyntraUILoading",
        DisplayOrder = 999999,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = getParent()
    })

    local overlay = new("Frame", {
        Parent = gui,
        BackgroundColor3 = Color3.fromRGB(5, 7, 12),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1)
    })

    local overlayGradient = gradient(Color3.fromRGB(7, 10, 18), Color3.fromRGB(24, 20, 38), 35)
    overlayGradient.Parent = overlay

    local holder = new("Frame", {
        Parent = overlay,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(360, 250),
        ClipsDescendants = true
    }, {
        corner(18),
        stroke(theme.Stroke, 0.42, 1)
    })

    local holderScale = new("UIScale", {
        Parent = holder,
        Scale = 0.94
    })

    local holderShadow = createShadow(holder, 60)
    holderShadow.ImageTransparency = 1
    padding(24, 24, 24, 24).Parent = holder

    local logoFrame = new("Frame", {
        Parent = holder,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0, 10),
        Size = UDim2.fromOffset(86, 86),
        ZIndex = 2
    }, {
        corner(22),
        stroke(theme.Accent, 0.55, 1)
    })

    local logoGradient = gradient(theme.Accent, theme.AccentSecondary, 35, NumberSequence.new(0.65))
    logoGradient.Parent = logoFrame

    local logoScale = new("UIScale", {
        Parent = logoFrame,
        Scale = 0.86
    })

    local image = resolveImageAsset(options.LoadingImage or options.Image or SYNTRA_LOGO_URL)
    local logoImage
    if image ~= "" then
        logoImage = new("ImageLabel", {
            Parent = logoFrame,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = image,
            ImageTransparency = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromOffset(58, 58),
            ZIndex = 3
        })
    else
        logoImage = makeText(logoFrame, "S", 36, Enum.Font.GothamBold, theme.Text, Enum.TextXAlignment.Center)
        logoImage.Size = UDim2.fromScale(1, 1)
        logoImage.TextTransparency = 1
    end

    local title = makeText(holder, options.LoadingTitle or options.Name or "Syntra", 22, Enum.Font.GothamBold, theme.Text, Enum.TextXAlignment.Center)
    title.Position = UDim2.fromOffset(0, 118)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.TextTransparency = 1
    title.ZIndex = 2

    local subtitle = makeText(holder, options.LoadingSubtitle or "Loading interface", 13, Enum.Font.GothamMedium, theme.MutedText, Enum.TextXAlignment.Center)
    subtitle.Position = UDim2.fromOffset(0, 150)
    subtitle.Size = UDim2.new(1, 0, 0, 20)
    subtitle.TextTransparency = 1
    subtitle.ZIndex = 2

    local track = new("Frame", {
        Parent = holder,
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = theme.SurfaceLight,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 1, -22),
        Size = UDim2.new(1, -54, 0, 6),
        ZIndex = 2
    }, {
        corner(99)
    })

    local fill = new("Frame", {
        Parent = track,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        ZIndex = 3
    }, {
        corner(99),
        gradient(theme.Accent, theme.AccentSecondary, 0)
    })

    local alive = true
    task.spawn(function()
        while alive and gui.Parent do
            tween(logoScale, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 1.03 })
            tween(logoGradient, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = 95 })
            task.wait(0.9)
            tween(logoScale, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 0.98 })
            tween(logoGradient, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = 35 })
            task.wait(0.9)
        end
    end)

    tween(overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.08 })
    tween(holder, SOFT_TWEEN, { BackgroundTransparency = 0.1 })
    tween(holderScale, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
    tween(holderShadow, SOFT_TWEEN, { ImageTransparency = 0.55 })
    tween(logoFrame, SOFT_TWEEN, { BackgroundTransparency = 0.18 })
    if logoImage:IsA("ImageLabel") then
        tween(logoImage, SOFT_TWEEN, { ImageTransparency = 0 })
    else
        tween(logoImage, SOFT_TWEEN, { TextTransparency = 0 })
    end
    tween(logoScale, TweenInfo.new(0.44, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
    task.delay(0.08, function()
        tween(title, SOFT_TWEEN, { TextTransparency = 0 })
    end)
    task.delay(0.14, function()
        tween(subtitle, SOFT_TWEEN, { TextTransparency = 0 })
        tween(track, SOFT_TWEEN, { BackgroundTransparency = 0.2 })
    end)
    tween(fill, TweenInfo.new(options.LoadingDuration or 0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(1, 1) })

    task.wait(options.LoadingDuration or 0.9)
    alive = false
    tween(holderScale, SOFT_TWEEN, { Scale = 0.97 })
    tween(holder, SOFT_TWEEN, { BackgroundTransparency = 1 })
    tween(holderShadow, SOFT_TWEEN, { ImageTransparency = 1 })
    tween(logoFrame, SOFT_TWEEN, { BackgroundTransparency = 1 })
    tween(title, SOFT_TWEEN, { TextTransparency = 1 })
    tween(subtitle, SOFT_TWEEN, { TextTransparency = 1 })
    tween(track, SOFT_TWEEN, { BackgroundTransparency = 1 })
    tween(fill, SOFT_TWEEN, { BackgroundTransparency = 1 })
    if logoImage:IsA("ImageLabel") then
        tween(logoImage, SOFT_TWEEN, { ImageTransparency = 1 })
    else
        tween(logoImage, SOFT_TWEEN, { TextTransparency = 1 })
    end
    tween(overlay, SOFT_TWEEN, { BackgroundTransparency = 1 })
    task.delay(0.32, function()
        gui:Destroy()
    end)
end

local function createNotificationArea(parent)
    local area = new("Frame", {
        Parent = parent,
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(340, 420),
        ZIndex = 50
    })

    new("UIListLayout", {
        Parent = area,
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom
    })

    return area
end

local function createDragging(frame, handle)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

function SyntraUI:CreateWindow(options)
    options = merge({
        Name = "Syntra",
        Subtitle = "Professional Roblox UI Library",
        Theme = "Midnight",
        Width = 760,
        Height = 520,
        MinWidth = 620,
        MinHeight = 420,
        Scale = 1,
        Loading = true,
        LoadingDuration = 1.05,
        LoadingImage = SYNTRA_LOGO_URL,
        ToggleKeybind = Enum.KeyCode.RightControl,
        SaveConfiguration = false,
        ConfigurationFolder = "Syntra",
        ConfigurationFile = "Interface"
    }, options or {})

    local loadedConfig = Config:load(options.ConfigurationFolder, options.ConfigurationFile)
    if options.SaveConfiguration and loadedConfig.__theme and Themes[loadedConfig.__theme] then
        options.Theme = loadedConfig.__theme
    end

    if options.SaveConfiguration and tonumber(loadedConfig.__scale) then
        options.Scale = clamp(tonumber(loadedConfig.__scale), 0.75, 1.2)
    end

    if Themes[options.Theme] then
        SyntraUI.ActiveThemeName = options.Theme
    end

    if options.Loading then
        createLoadingScreen(options)
    end

    local theme = currentTheme()
    local gui = new("ScreenGui", {
        Name = "SyntraUI",
        DisplayOrder = 999998,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = getParent()
    })

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local width = clamp(options.Width, options.MinWidth, math.max(options.MinWidth, viewport.X - 60))
    local height = clamp(options.Height, options.MinHeight, math.max(options.MinHeight, viewport.Y - 60))
    options.Width = width
    options.Height = height

    local root = new("Frame", {
        Parent = gui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width, height)
    })

    local uiScale = new("UIScale", {
        Parent = root,
        Scale = options.Scale
    })

    local shadow = createShadow(root, 72)

    local main = new("Frame", {
        Parent = root,
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2
    }, {
        corner(18),
        stroke(theme.Stroke, 0.35, 1),
        gradient(theme.Background, theme.Surface, 35, NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.08)
        }))
    })

    local sidebar = new("Frame", {
        Parent = main,
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 218, 1, 0),
        ZIndex = 3
    }, {
        corner(18)
    })

    local sidebarMask = new("Frame", {
        Parent = sidebar,
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -18, 0, 0),
        Size = UDim2.new(0, 18, 1, 0),
        ZIndex = 4
    })

    local topbar = new("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(218, 0),
        Size = UDim2.new(1, -218, 0, 72),
        ZIndex = 4
    })

    local contentHost = new("CanvasGroup", {
        Parent = main,
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        GroupTransparency = 0,
        Position = UDim2.fromOffset(218, 72),
        Size = UDim2.new(1, -218, 1, -72),
        ZIndex = 4
    })

    local titleBlock = new("Frame", {
        Parent = sidebar,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 18),
        Size = UDim2.new(1, -36, 0, 58),
        ZIndex = 5
    })

    local brand = makeText(titleBlock, options.Name, 22, Enum.Font.GothamBold, theme.Text)
    brand.Size = UDim2.new(1, 0, 0, 28)
    brand.ZIndex = 6

    local sub = makeText(titleBlock, options.Subtitle, 12, Enum.Font.GothamMedium, theme.MutedText)
    sub.Position = UDim2.fromOffset(0, 30)
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.ZIndex = 6

    local tabList = new("ScrollingFrame", {
        Parent = sidebar,
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(14, 96),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 2,
        Size = UDim2.new(1, -28, 1, -164),
        ZIndex = 6
    })

    local tabLayout = new("UIListLayout", {
        Parent = tabList,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabList.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 8)
    end)

    local footer = new("Frame", {
        Parent = sidebar,
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 1, -14),
        Size = UDim2.new(1, -28, 0, 48),
        ZIndex = 6
    })

    local settingsButton = makeButton(footer, "Settings")
    settingsButton.Size = UDim2.new(1, 0, 1, 0)
    settingsButton.ZIndex = 7
    corner(10).Parent = settingsButton
    stroke(theme.Stroke, 0.55, 1).Parent = settingsButton
    bindHover(settingsButton, { BackgroundColor3 = theme.SurfaceLight }, { BackgroundColor3 = theme.SurfaceHover })

    local pageTitle = makeText(topbar, "Dashboard", 21, Enum.Font.GothamBold, theme.Text)
    pageTitle.Position = UDim2.fromOffset(24, 15)
    pageTitle.Size = UDim2.new(1, -156, 0, 28)
    pageTitle.ZIndex = 6

    local pageSubtitle = makeText(topbar, "Ready", 12, Enum.Font.GothamMedium, theme.MutedText)
    pageSubtitle.Position = UDim2.fromOffset(24, 42)
    pageSubtitle.Size = UDim2.new(1, -156, 0, 18)
    pageSubtitle.ZIndex = 6

    local minButton = makeButton(topbar, "-")
    minButton.AnchorPoint = Vector2.new(1, 0)
    minButton.Position = UDim2.new(1, -64, 0, 18)
    minButton.Size = UDim2.fromOffset(34, 34)
    minButton.TextSize = 18
    minButton.ZIndex = 8
    corner(9).Parent = minButton

    local closeButton = makeButton(topbar, "x")
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.Position = UDim2.new(1, -24, 0, 18)
    closeButton.Size = UDim2.fromOffset(34, 34)
    closeButton.TextSize = 16
    closeButton.ZIndex = 8
    closeButton.BackgroundColor3 = theme.SurfaceLight
    corner(9).Parent = closeButton

    local notificationArea = createNotificationArea(gui)

    local window = setmetatable({
        Options = options,
        ScreenGui = gui,
        Root = root,
        UIScale = uiScale,
        Main = main,
        Shadow = shadow,
        Sidebar = sidebar,
        SidebarMask = sidebarMask,
        Topbar = topbar,
        TabList = tabList,
        ContentHost = contentHost,
        NotificationArea = notificationArea,
        PageTitle = pageTitle,
        PageSubtitle = pageSubtitle,
        SettingsButton = settingsButton,
        Tabs = {},
        ActiveTab = nil,
        Flags = {},
        Minimized = false,
        Closed = false,
        _themeObjects = {},
        _controls = {},
        _connections = {},
        Configuration = {
            Enabled = options.SaveConfiguration,
            Folder = options.ConfigurationFolder,
            File = options.ConfigurationFile,
            Values = loadedConfig
        }
    }, Window)

    table.insert(SyntraUI.Windows, window)

    themed(window, main, "BackgroundColor3", "Background")
    themed(window, sidebar, "BackgroundColor3", "Surface")
    themed(window, sidebarMask, "BackgroundColor3", "Surface")
    themed(window, brand, "TextColor3", "Text")
    themed(window, sub, "TextColor3", "MutedText")
    themed(window, tabList, "ScrollBarImageColor3", "Accent")
    themed(window, pageTitle, "TextColor3", "Text")
    themed(window, pageSubtitle, "TextColor3", "MutedText")
    themed(window, settingsButton, "BackgroundColor3", "SurfaceLight")
    themed(window, minButton, "BackgroundColor3", "SurfaceLight")
    themed(window, closeButton, "BackgroundColor3", "SurfaceLight")
    themed(window, settingsButton, "TextColor3", "Text")
    themed(window, minButton, "TextColor3", "Text")
    themed(window, closeButton, "TextColor3", "Text")

    createDragging(root, topbar)
    createDragging(root, titleBlock)

    minButton.MouseButton1Click:Connect(function()
        window:Toggle()
    end)

    closeButton.MouseButton1Click:Connect(function()
        window:Destroy()
    end)

    settingsButton.MouseButton1Click:Connect(function()
        window:OpenSettings()
    end)

    if options.ToggleKeybind then
        table.insert(window._connections, UserInputService.InputBegan:Connect(function(input, processed)
            if processed then
                return
            end

            if input.KeyCode == options.ToggleKeybind then
                window:Toggle()
            end
        end))
    end

    root.Size = UDim2.fromOffset(width - 28, height - 28)
    main.BackgroundTransparency = 1
    shadow.ImageTransparency = 1
    tween(root, SPRING_TWEEN, { Size = UDim2.fromOffset(width, height) })
    tween(main, DEFAULT_TWEEN, { BackgroundTransparency = 0.05 })
    tween(shadow, DEFAULT_TWEEN, { ImageTransparency = 0.55 })

    RunService.RenderStepped:Wait()

    return window
end

function Window:SaveConfiguration()
    if not self.Configuration.Enabled then
        return false
    end

    self.Configuration.Values.__theme = SyntraUI.ActiveThemeName
    return Config:save(self.Configuration.Folder, self.Configuration.File, self.Configuration.Values)
end

function Window:SetTheme(name)
    if not Themes[name] then
        warn("[SyntraUI] Unknown theme: " .. tostring(name))
        return false
    end

    SyntraUI.ActiveThemeName = name
    local theme = currentTheme()

    for _, item in ipairs(self._themeObjects) do
        if item.Instance and item.Instance.Parent then
            local value = theme[item.Key]
            if value then
                item.Instance[item.Property] = value
            end
        end
    end

    for _, control in ipairs(self._controls) do
        if control.RefreshTheme then
            control:RefreshTheme()
        end
    end

    if self.ScreenGui then
        for _, descendant in ipairs(self.ScreenGui:GetDescendants()) do
            if descendant:IsA("UIStroke") then
                descendant.Color = theme.Stroke
            elseif descendant:IsA("ImageLabel") and descendant.Image == "rbxassetid://5554236805" then
                descendant.ImageColor3 = theme.Shadow
            end
        end
    end

    self:SaveConfiguration()
    return true
end

function Window:SetScale(scale)
    scale = clamp(tonumber(scale) or 1, 0.75, 1.2)

    if self.UIScale then
        tween(self.UIScale, DEFAULT_TWEEN, { Scale = scale })
    end

    self.Options.Scale = scale
    self.Configuration.Values.__scale = scale
    self:SaveConfiguration()
    return scale
end

function Window:Toggle()
    if self.Closed then
        return
    end

    self.Minimized = not self.Minimized

    if self.Minimized then
        if self.ContentHost then
            tween(self.ContentHost, FAST_TWEEN, { GroupTransparency = 1 })
        end
        tween(self.Sidebar, SOFT_TWEEN, { BackgroundTransparency = 1 })
        tween(self.SidebarMask, SOFT_TWEEN, { BackgroundTransparency = 1 })
        tween(self.Topbar, SOFT_TWEEN, { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 72) })
        tween(self.Root, SOFT_TWEEN, { Size = UDim2.fromOffset(self.Options.Width, 72) })
        tween(self.Shadow, SOFT_TWEEN, { ImageTransparency = 0.68 })
        task.delay(0.22, function()
            if self.Minimized then
                if self.ContentHost then
                    self.ContentHost.Visible = false
                end
                if self.Sidebar then
                    self.Sidebar.Visible = false
                end
            end
        end)
    else
        if self.Sidebar then
            self.Sidebar.Visible = true
        end
        if self.ContentHost then
            self.ContentHost.Visible = true
        end

        tween(self.Root, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(self.Options.Width, self.Options.Height) })
        tween(self.Topbar, SOFT_TWEEN, { Position = UDim2.fromOffset(218, 0), Size = UDim2.new(1, -218, 0, 72) })
        tween(self.Sidebar, SOFT_TWEEN, { BackgroundTransparency = 0.1 })
        tween(self.SidebarMask, SOFT_TWEEN, { BackgroundTransparency = 0.1 })
        tween(self.Shadow, SOFT_TWEEN, { ImageTransparency = 0.55 })
        task.delay(0.08, function()
            if not self.Minimized and self.ContentHost then
                tween(self.ContentHost, SOFT_TWEEN, { GroupTransparency = 0 })
            end
        end)
    end
end

function Window:Destroy()
    if self.Closed then
        return
    end

    self.Closed = true

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end

    if self.ContentHost then
        tween(self.ContentHost, FAST_TWEEN, { GroupTransparency = 1 })
    end
    tween(self.Root, SOFT_TWEEN, { Size = UDim2.fromOffset(math.max(0, self.Root.AbsoluteSize.X - 28), math.max(0, self.Root.AbsoluteSize.Y - 28)) })
    tween(self.Main, SOFT_TWEEN, { BackgroundTransparency = 1 })
    tween(self.Shadow, SOFT_TWEEN, { ImageTransparency = 1 })

    task.delay(0.32, function()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
        end
    end)
end

function Window:Notify(options)
    options = merge({
        Title = "Notification",
        Content = "",
        Duration = 4,
        Type = "Info"
    }, options or {})

    local theme = currentTheme()
    local accent = theme.Accent

    if options.Type == "Success" then
        accent = theme.Success
    elseif options.Type == "Warning" then
        accent = theme.Warning
    elseif options.Type == "Error" or options.Type == "Danger" then
        accent = theme.Danger
    end

    local card = new("Frame", {
        Parent = self.NotificationArea,
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(320, 88),
        ZIndex = 60
    }, {
        corner(12),
        stroke(theme.Stroke, 0.5, 1)
    })

    createShadow(card, 38)
    padding(16, 14, 16, 12).Parent = card

    local bar = new("Frame", {
        Parent = card,
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 4, 1, 0),
        ZIndex = 62
    }, {
        corner(12)
    })

    local title = makeText(card, options.Title, 14, Enum.Font.GothamBold, theme.Text)
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.new(1, -32, 0, 22)
    title.ZIndex = 63

    local content = makeText(card, options.Content, 12, Enum.Font.GothamMedium, theme.MutedText)
    content.Position = UDim2.fromOffset(16, 38)
    content.Size = UDim2.new(1, -32, 0, 34)
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.ZIndex = 63

    card.Position = UDim2.fromOffset(28, 0)
    card.BackgroundTransparency = 1
    tween(card, SPRING_TWEEN, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.05 })

    task.delay(options.Duration, function()
        if card and card.Parent then
            tween(card, DEFAULT_TWEEN, { Position = UDim2.fromOffset(28, 0), BackgroundTransparency = 1 })
            tween(title, DEFAULT_TWEEN, { TextTransparency = 1 })
            tween(content, DEFAULT_TWEEN, { TextTransparency = 1 })
            tween(bar, DEFAULT_TWEEN, { BackgroundTransparency = 1 })
            task.delay(0.24, function()
                if card then
                    card:Destroy()
                end
            end)
        end
    end)

    return card
end

function Window:CreateTab(name, icon)
    local theme = currentTheme()

    local button = makeButton(self.TabList, tostring(name or "Tab"))
    button.BackgroundColor3 = theme.SurfaceLight
    button.BackgroundTransparency = 0.42
    button.Size = UDim2.new(1, 0, 0, 42)
    button.Text = ""
    button.ZIndex = 8
    corner(10).Parent = button

    local accent = new("Frame", {
        Parent = button,
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 9),
        Size = UDim2.fromOffset(3, 24),
        ZIndex = 9
    }, {
        corner(99)
    })

    local iconLabel = makeText(button, icon or "", 14, Enum.Font.GothamBold, theme.Accent, Enum.TextXAlignment.Center)
    iconLabel.Position = UDim2.fromOffset(12, 0)
    iconLabel.Size = UDim2.fromOffset(24, 42)
    iconLabel.ZIndex = 10

    local label = makeText(button, name, 13, Enum.Font.GothamMedium, theme.MutedText)
    label.Position = UDim2.fromOffset(42, 0)
    label.Size = UDim2.new(1, -52, 1, 0)
    label.ZIndex = 10

    local page = new("ScrollingFrame", {
        Parent = self.ContentHost,
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(0, 0),
        ScrollBarImageColor3 = theme.Accent,
        ScrollBarThickness = 3,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 5
    })

    layoutContent(page, 2)

    local tab = setmetatable({
        Window = self,
        Name = name,
        Icon = icon,
        Button = button,
        Accent = accent,
        IconLabel = iconLabel,
        Label = label,
        Page = page,
        Sections = {}
    }, Tab)

    table.insert(self.Tabs, tab)

    themed(self, button, "BackgroundColor3", "SurfaceLight")
    themed(self, accent, "BackgroundColor3", "Accent")
    themed(self, iconLabel, "TextColor3", "Accent")
    themed(self, label, "TextColor3", "MutedText")
    themed(self, page, "ScrollBarImageColor3", "Accent")

    button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, FAST_TWEEN, { BackgroundTransparency = 0.24 })
        end
    end)

    button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, FAST_TWEEN, { BackgroundTransparency = 0.42 })
        end
    end)

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    if not self.ActiveTab then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab)
    if self.ActiveTab == tab then
        return
    end

    local old = self.ActiveTab
    self.ActiveTab = tab

    if old then
        old.Page.Visible = false
        old.Page.Position = UDim2.fromOffset(0, 0)
        tween(old.Button, DEFAULT_TWEEN, { BackgroundTransparency = 0.42 })
        tween(old.Accent, DEFAULT_TWEEN, { BackgroundTransparency = 1 })
        tween(old.Label, DEFAULT_TWEEN, { TextColor3 = currentTheme().MutedText })
    end

    tab.Page.Position = UDim2.fromOffset(10, 0)
    tab.Page.Visible = true
    tab.Page.CanvasPosition = Vector2.new(0, 0)
    self.PageTitle.Text = tostring(tab.Name)
    self.PageSubtitle.Text = tostring(#tab.Sections) .. " section" .. (#tab.Sections == 1 and "" or "s")

    tween(tab.Button, DEFAULT_TWEEN, { BackgroundTransparency = 0.08 })
    tween(tab.Accent, DEFAULT_TWEEN, { BackgroundTransparency = 0 })
    tween(tab.Label, DEFAULT_TWEEN, { TextColor3 = currentTheme().Text })
    tween(tab.Page, SOFT_TWEEN, { Position = UDim2.fromOffset(0, 0) })
end

function Window:CreateSettingsTab()
    if self.SettingsTab then
        return self.SettingsTab
    end

    local tab = self:CreateTab("Settings", "S")
    self.SettingsTab = tab

    local appearance = tab:CreateSection("Appearance")
    appearance:CreateDropdown({
        Name = "Theme",
        Options = SyntraUI:GetThemes(),
        CurrentOption = SyntraUI.ActiveThemeName,
        Flag = "__theme",
        Callback = function(value)
            self:SetTheme(value)
            self:Notify({
                Title = "Theme changed",
                Content = "Active theme: " .. tostring(value),
                Type = "Success",
                Duration = 2.5
            })
        end
    })

    appearance:CreateSlider({
        Name = "UI Scale",
        Range = { 0.75, 1.2 },
        Increment = 0.05,
        CurrentValue = self.Options.Scale or 1,
        Suffix = "x",
        Flag = "__scale",
        Callback = function(value)
            self:SetScale(value)
        end
    })

    local behavior = tab:CreateSection("Behavior")
    behavior:CreateKeybind({
        Name = "Toggle UI",
        CurrentKeybind = self.Options.ToggleKeybind,
        HoldToInteract = false,
        Flag = "__toggleKeybind",
        Callback = function()
            self:Toggle()
        end
    })

    behavior:CreateButton({
        Name = "Save Settings",
        Callback = function()
            local ok = self:SaveConfiguration()
            self:Notify({
                Title = ok and "Settings saved" or "Settings unavailable",
                Content = ok and "Configuration was written successfully." or "This environment does not expose file APIs.",
                Type = ok and "Success" or "Warning"
            })
        end
    })

    return tab
end

function Window:OpenSettings()
    self:CreateSettingsTab()
    self:SelectTab(self.SettingsTab)
end

function Window:CreateSection(name)
    if not self.ActiveTab then
        return self:CreateTab("Main", "M"):CreateSection(name)
    end

    return self.ActiveTab:CreateSection(name)
end

function Tab:CreateSection(name)
    local theme = currentTheme()

    local container = new("Frame", {
        Parent = self.Page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 60),
        ZIndex = 6
    })

    local title = makeText(container, name or "Section", 14, Enum.Font.GothamBold, theme.Text)
    title.Position = UDim2.fromOffset(2, 0)
    title.Size = UDim2.new(1, -4, 0, 24)
    title.ZIndex = 7

    local body = new("Frame", {
        Parent = container,
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 20),
        ZIndex = 6
    }, {
        corner(12),
        stroke(theme.Stroke, 0.58, 1)
    })

    padding(12, 12, 12, 12).Parent = body

    local layout = new("UIListLayout", {
        Parent = body,
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        body.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 24)
        container.Size = UDim2.new(1, -8, 0, body.AbsoluteSize.Y + 34)
    end)

    local section = setmetatable({
        Window = self.Window,
        Tab = self,
        Name = name,
        Instance = container,
        Body = body,
        Title = title,
        Layout = layout,
        Controls = {}
    }, Section)

    table.insert(self.Sections, section)
    themed(self.Window, title, "TextColor3", "Text")
    themed(self.Window, body, "BackgroundColor3", "Surface")

    if self.Window.ActiveTab == self then
        self.Window.PageSubtitle.Text = tostring(#self.Sections) .. " section" .. (#self.Sections == 1 and "" or "s")
    end

    return section
end

function Section:Clear()
    for _, control in ipairs(self.Controls) do
        if control.Instance then
            control.Instance:Destroy()
        end
    end

    table.clear(self.Controls)
end

function Section:SetVisible(visible)
    if self.Instance then
        self.Instance.Visible = visible and true or false
    end
end

function Section:SetCollapsed(collapsed)
    self.Collapsed = collapsed and true or false

    if self.Instance then
        if self.Collapsed then
            tween(self.Instance, DEFAULT_TWEEN, { Size = UDim2.new(1, -8, 0, 28) })
            task.delay(0.2, function()
                if self.Collapsed and self.Body then
                    self.Body.Visible = false
                end
            end)
        else
            if self.Body then
                self.Body.Visible = true
            end
            local height = self.Body and (self.Body.AbsoluteSize.Y + 34) or 60
            tween(self.Instance, DEFAULT_TWEEN, { Size = UDim2.new(1, -8, 0, height) })
        end
    end
end

local function makeControl(section, options, height)
    options = options or {}
    local card = makeCard(section.Body, height or 48)
    padding(14, 0, 14, 0).Parent = card

    local label = makeText(card, options.Name or "Control", 13, Enum.Font.GothamMedium, currentTheme().Text)
    label.Position = UDim2.fromOffset(14, 0)
    label.Size = UDim2.new(1, -28, 1, 0)
    label.ZIndex = 10

    if section.Window then
        themed(section.Window, card, "BackgroundColor3", "SurfaceLight")
        themed(section.Window, label, "TextColor3", "Text")
    end

    return card, label
end

function Section:CreateLabel(options)
    if typeof(options) == "string" then
        options = { Name = options }
    end

    local card, label = makeControl(self, options, 40)
    label.TextColor3 = currentTheme().MutedText
    themed(self.Window, label, "TextColor3", "MutedText")

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Label = label,
        Value = options.Name,
        Enabled = true
    }, BaseControl)

    function control:SetValue(value)
        self.Value = value
        self.Label.Text = tostring(value)
    end

    registerControl(self.Window, control)
    return control
end

function Section:CreateParagraph(options)
    if typeof(options) == "string" then
        options = { Title = options, Content = "" }
    end

    options = merge({
        Title = "Information",
        Content = "",
        Type = "Info"
    }, options or {})

    local theme = currentTheme()
    local accent = theme.Accent

    if options.Type == "Success" then
        accent = theme.Success
    elseif options.Type == "Warning" then
        accent = theme.Warning
    elseif options.Type == "Error" or options.Type == "Danger" then
        accent = theme.Danger
    end

    local card = makeCard(self.Body, 82)
    padding(16, 12, 16, 12).Parent = card

    local bar = new("Frame", {
        Parent = card,
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 12),
        Size = UDim2.new(0, 3, 1, -24),
        ZIndex = 11
    }, {
        corner(99)
    })

    local title = makeText(card, options.Title, 14, Enum.Font.GothamBold, theme.Text)
    title.Position = UDim2.fromOffset(16, 8)
    title.Size = UDim2.new(1, -32, 0, 24)
    title.ZIndex = 12

    local content = makeText(card, options.Content, 12, Enum.Font.GothamMedium, theme.MutedText)
    content.Position = UDim2.fromOffset(16, 34)
    content.Size = UDim2.new(1, -32, 0, 38)
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.ZIndex = 12

    themed(self.Window, card, "BackgroundColor3", "SurfaceLight")
    themed(self.Window, title, "TextColor3", "Text")
    themed(self.Window, content, "TextColor3", "MutedText")

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Title = title,
        Content = content,
        Accent = bar,
        Value = options.Content,
        Enabled = true
    }, BaseControl)

    function control:SetValue(value)
        self.Value = tostring(value or "")
        self.Content.Text = self.Value
    end

    registerControl(self.Window, control)
    return control
end

function Section:CreateDivider(options)
    if typeof(options) == "string" then
        options = { Name = options }
    end

    options = options or {}
    local holder = new("Frame", {
        Parent = self.Body,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, options.Name and 28 or 16),
        ZIndex = 8
    })

    local line = new("Frame", {
        Parent = holder,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = currentTheme().Stroke,
        BackgroundTransparency = 0.34,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 9
    })

    themed(self.Window, line, "BackgroundColor3", "Stroke")

    local label
    if options.Name then
        label = makeText(holder, options.Name, 11, Enum.Font.GothamBold, currentTheme().MutedText, Enum.TextXAlignment.Center)
        label.AnchorPoint = Vector2.new(0.5, 0.5)
        label.BackgroundColor3 = currentTheme().Surface
        label.BackgroundTransparency = 0
        label.Position = UDim2.fromScale(0.5, 0.5)
        label.Size = UDim2.fromOffset(math.max(72, (#tostring(options.Name) * 7) + 22), 18)
        label.ZIndex = 10
        themed(self.Window, label, "TextColor3", "MutedText")
        themed(self.Window, label, "BackgroundColor3", "Surface")
    end

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = holder,
        Label = label,
        Line = line,
        Enabled = true
    }, BaseControl)

    registerControl(self.Window, control)
    return control
end

function Section:CreateProgress(options)
    options = merge({
        Name = "Progress",
        CurrentValue = 0,
        Range = { 0, 100 },
        Suffix = "%"
    }, options or {})

    local minValue = tonumber(options.Range[1]) or 0
    local maxValue = tonumber(options.Range[2]) or 100
    local card, label = makeControl(self, options, 62)
    label.Position = UDim2.fromOffset(14, 2)
    label.Size = UDim2.new(1, -112, 0, 28)

    local valueLabel = makeText(card, "", 12, Enum.Font.GothamBold, currentTheme().Accent, Enum.TextXAlignment.Right)
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -14, 0, 4)
    valueLabel.Size = UDim2.fromOffset(96, 24)
    valueLabel.ZIndex = 12

    local track = new("Frame", {
        Parent = card,
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = currentTheme().SurfaceHover,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 1, -14),
        Size = UDim2.new(1, -28, 0, 7),
        ZIndex = 12
    }, {
        corner(99)
    })

    local fill = new("Frame", {
        Parent = track,
        BackgroundColor3 = currentTheme().Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        ZIndex = 13
    }, {
        corner(99),
        gradient(currentTheme().Accent, currentTheme().AccentSecondary, 0)
    })

    themed(self.Window, valueLabel, "TextColor3", "Accent")
    themed(self.Window, track, "BackgroundColor3", "SurfaceHover")
    themed(self.Window, fill, "BackgroundColor3", "Accent")

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Label = label,
        ValueLabel = valueLabel,
        Fill = fill,
        Value = clamp(tonumber(options.CurrentValue) or minValue, minValue, maxValue),
        Suffix = options.Suffix,
        Enabled = true
    }, BaseControl)

    function control:Refresh()
        local percent = 0
        if maxValue ~= minValue then
            percent = clamp((self.Value - minValue) / (maxValue - minValue), 0, 1)
        end
        self.ValueLabel.Text = tostring(self.Value) .. tostring(self.Suffix or "")
        tween(self.Fill, DEFAULT_TWEEN, { Size = UDim2.fromScale(percent, 1) })
    end

    function control:SetValue(value)
        self.Value = clamp(tonumber(value) or minValue, minValue, maxValue)
        self:Refresh()
    end

    control:Refresh()
    registerControl(self.Window, control)
    return control
end

function Section:CreateButton(options)
    options = merge({
        Name = "Button",
        Callback = nil
    }, options or {})

    local card, label = makeControl(self, options, 46)
    label.Size = UDim2.new(1, -84, 1, 0)

    local action = makeButton(card, "Run")
    action.AnchorPoint = Vector2.new(1, 0.5)
    action.BackgroundColor3 = currentTheme().Accent
    action.Position = UDim2.new(1, -12, 0.5, 0)
    action.Size = UDim2.fromOffset(68, 30)
    action.ZIndex = 12
    corner(8).Parent = action
    gradient(currentTheme().Accent, currentTheme().AccentSecondary, 0).Parent = action

    themed(self.Window, action, "TextColor3", "Text")
    bindHover(card, { BackgroundTransparency = 0.08 }, { BackgroundTransparency = 0 })

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Label = label,
        Button = action,
        Value = nil,
        Callback = options.Callback,
        Enabled = true
    }, BaseControl)

    action.MouseButton1Click:Connect(function()
        if control.Enabled == false then
            return
        end

        tween(action, FAST_TWEEN, { Size = UDim2.fromOffset(62, 28) })
        task.delay(0.08, function()
            tween(action, FAST_TWEEN, { Size = UDim2.fromOffset(68, 30) })
        end)
        protect(control.Callback)
    end)

    registerControl(self.Window, control)
    return control
end

function Section:CreateToggle(options)
    options = merge({
        Name = "Toggle",
        CurrentValue = false,
        Flag = nil,
        Callback = nil
    }, options or {})

    if options.Flag and self.Window.Configuration.Values[options.Flag] ~= nil then
        options.CurrentValue = self.Window.Configuration.Values[options.Flag]
    end

    local card, label = makeControl(self, options, 48)
    label.Size = UDim2.new(1, -84, 1, 0)

    local track = new("Frame", {
        Parent = card,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = currentTheme().SurfaceHover,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(48, 26),
        ZIndex = 12
    }, {
        corner(99)
    })

    local knob = new("Frame", {
        Parent = track,
        BackgroundColor3 = currentTheme().Text,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 13
    }, {
        corner(99)
    })

    themed(self.Window, track, "BackgroundColor3", "SurfaceHover")
    themed(self.Window, knob, "BackgroundColor3", "Text")

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Label = label,
        Track = track,
        Knob = knob,
        Flag = options.Flag,
        Value = options.CurrentValue and true or false,
        Callback = options.Callback,
        Enabled = true
    }, BaseControl)

    function control:Refresh()
        local themeNow = currentTheme()
        if self.Value then
            tween(self.Track, DEFAULT_TWEEN, { BackgroundColor3 = themeNow.Accent })
            tween(self.Knob, DEFAULT_TWEEN, { Position = UDim2.fromOffset(25, 3) })
        else
            tween(self.Track, DEFAULT_TWEEN, { BackgroundColor3 = themeNow.SurfaceHover })
            tween(self.Knob, DEFAULT_TWEEN, { Position = UDim2.fromOffset(3, 3) })
        end
    end

    function control:SetValue(value, fireCallback)
        setFlag(self, value and true or false)
        self:Refresh()
        if fireCallback ~= false then
            protect(self.Callback, self.Value)
        end
    end

    function control:RefreshTheme()
        self:Refresh()
    end

    card.InputBegan:Connect(function(input)
        if control.Enabled == false then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            control:SetValue(not control.Value)
        end
    end)

    control:Refresh()
    setFlag(control, control.Value, false)
    registerControl(self.Window, control)
    return control
end

function Section:CreateSlider(options)
    options = merge({
        Name = "Slider",
        Range = { 0, 100 },
        Increment = 1,
        CurrentValue = 0,
        Suffix = "",
        Flag = nil,
        Callback = nil
    }, options or {})

    if options.Flag and self.Window.Configuration.Values[options.Flag] ~= nil then
        options.CurrentValue = self.Window.Configuration.Values[options.Flag]
    end

    local minValue = tonumber(options.Range[1]) or 0
    local maxValue = tonumber(options.Range[2]) or 100
    local increment = tonumber(options.Increment) or 1

    local card, label = makeControl(self, options, 68)
    label.Position = UDim2.fromOffset(14, 3)
    label.Size = UDim2.new(1, -104, 0, 30)

    local valueLabel = makeText(card, "", 12, Enum.Font.GothamBold, currentTheme().Accent, Enum.TextXAlignment.Right)
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -14, 0, 5)
    valueLabel.Size = UDim2.fromOffset(90, 26)
    valueLabel.ZIndex = 11

    local track = new("Frame", {
        Parent = card,
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = currentTheme().SurfaceHover,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 1, -15),
        Size = UDim2.new(1, -28, 0, 6),
        ZIndex = 12
    }, {
        corner(99)
    })

    local fill = new("Frame", {
        Parent = track,
        BackgroundColor3 = currentTheme().Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        ZIndex = 13
    }, {
        corner(99),
        gradient(currentTheme().Accent, currentTheme().AccentSecondary, 0)
    })

    local knob = new("Frame", {
        Parent = track,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = currentTheme().Text,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(14, 14),
        ZIndex = 14
    }, {
        corner(99)
    })

    themed(self.Window, valueLabel, "TextColor3", "Accent")
    themed(self.Window, track, "BackgroundColor3", "SurfaceHover")
    themed(self.Window, fill, "BackgroundColor3", "Accent")
    themed(self.Window, knob, "BackgroundColor3", "Text")

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Label = label,
        ValueLabel = valueLabel,
        Track = track,
        Fill = fill,
        Knob = knob,
        Flag = options.Flag,
        Value = clamp(tonumber(options.CurrentValue) or minValue, minValue, maxValue),
        Callback = options.Callback,
        Suffix = options.Suffix,
        Enabled = true
    }, BaseControl)

    local dragging = false

    local function snap(value)
        value = clamp(value, minValue, maxValue)
        if increment > 0 then
            value = round(value / increment, 0) * increment
        end
        return clamp(value, minValue, maxValue)
    end

    local function fromPosition(x)
        local relative = clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        return snap(minValue + ((maxValue - minValue) * relative))
    end

    function control:Refresh()
        local percent = 0
        if maxValue ~= minValue then
            percent = clamp((self.Value - minValue) / (maxValue - minValue), 0, 1)
        end

        self.ValueLabel.Text = tostring(self.Value) .. tostring(self.Suffix or "")
        tween(self.Fill, DEFAULT_TWEEN, { Size = UDim2.fromScale(percent, 1) })
        tween(self.Knob, DEFAULT_TWEEN, { Position = UDim2.fromScale(percent, 0.5) })
    end

    function control:SetValue(value, fireCallback)
        setFlag(self, snap(tonumber(value) or minValue), not dragging)
        self:Refresh()
        if fireCallback ~= false then
            protect(self.Callback, self.Value)
        end
    end

    track.InputBegan:Connect(function(input)
        if control.Enabled == false then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            control:SetValue(fromPosition(input.Position.X))
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and control.Enabled ~= false and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            control:SetValue(fromPosition(input.Position.X))
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and control.Flag then
                control.Window:SaveConfiguration()
            end
            dragging = false
        end
    end)

    control:Refresh()
    setFlag(control, control.Value, false)
    registerControl(self.Window, control)
    return control
end

function Section:CreateDropdown(options)
    options = merge({
        Name = "Dropdown",
        Options = {},
        CurrentOption = nil,
        MultipleOptions = false,
        Flag = nil,
        Callback = nil
    }, options or {})

    if options.Flag and self.Window.Configuration.Values[options.Flag] ~= nil then
        options.CurrentOption = self.Window.Configuration.Values[options.Flag]
    end

    local card, label = makeControl(self, options, 50)
    label.Size = UDim2.new(1, -154, 1, 0)

    local picker = makeButton(card, "")
    picker.AnchorPoint = Vector2.new(1, 0.5)
    picker.Position = UDim2.new(1, -12, 0.5, 0)
    picker.Size = UDim2.fromOffset(140, 32)
    picker.ZIndex = 12
    picker.TextXAlignment = Enum.TextXAlignment.Left
    picker.TextSize = 12
    corner(8).Parent = picker
    padding(10, 0, 10, 0).Parent = picker

    local menu = new("Frame", {
        Parent = card,
        BackgroundColor3 = currentTheme().Surface,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.new(1, -152, 1, 6),
        Size = UDim2.fromOffset(140, 0),
        Visible = false,
        ZIndex = 30
    }, {
        corner(8),
        stroke(currentTheme().Stroke, 0.45, 1)
    })

    local menuLayout = new("UIListLayout", {
        Parent = menu,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    themed(self.Window, picker, "BackgroundColor3", "SurfaceHover")
    themed(self.Window, picker, "TextColor3", "Text")
    themed(self.Window, menu, "BackgroundColor3", "Surface")

    local initialValue = options.CurrentOption
    if initialValue == nil then
        initialValue = options.MultipleOptions and {} or options.Options[1]
    end

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Label = label,
        Picker = picker,
        Menu = menu,
        Flag = options.Flag,
        Options = options.Options,
        Multiple = options.MultipleOptions,
        Value = initialValue,
        Callback = options.Callback,
        Open = false,
        Enabled = true
    }, BaseControl)

    local function valueText(value)
        if typeof(value) == "table" then
            if #value == 0 then
                return "None"
            end
            return table.concat(value, ", ")
        end

        return tostring(value or "Select")
    end

    local function isSelected(value)
        if control.Multiple and typeof(control.Value) == "table" then
            return table.find(control.Value, value) ~= nil
        end
        return control.Value == value
    end

    local function resizeMenu()
        local height = control.Open and math.min(#control.Options * 32, 192) or 0
        local targetCardHeight = control.Open and (58 + height) or 50
        if control.Open then
            menu.Visible = true
            menu.BackgroundTransparency = 0.02
        end

        tween(card, SOFT_TWEEN, { Size = UDim2.new(1, 0, 0, targetCardHeight) })
        tween(menu, SOFT_TWEEN, {
            Size = UDim2.fromOffset(140, height),
            BackgroundTransparency = control.Open and 0.02 or 1
        })

        if not control.Open then
            task.delay(0.26, function()
                if not control.Open and menu then
                    menu.Visible = false
                end
            end)
        end
    end

    local function rebuild()
        for _, child in ipairs(menu:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for _, option in ipairs(control.Options) do
            local row = makeButton(menu, tostring(option))
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, 32)
            row.TextSize = 12
            row.ZIndex = 31
            row.TextColor3 = isSelected(option) and currentTheme().Accent or currentTheme().Text
            bindHover(row, { BackgroundTransparency = 1 }, { BackgroundTransparency = 0.82 })

            row.MouseButton1Click:Connect(function()
                if control.Enabled == false then
                    return
                end

                if control.Multiple then
                    local nextValue = {}
                    if typeof(control.Value) == "table" then
                        for _, existing in ipairs(control.Value) do
                            table.insert(nextValue, existing)
                        end
                    end

                    local index = table.find(nextValue, option)
                    if index then
                        table.remove(nextValue, index)
                    else
                        table.insert(nextValue, option)
                    end
                    control:SetValue(nextValue)
                else
                    control:SetValue(option)
                    control.Open = false
                    resizeMenu()
                end
                rebuild()
            end)
        end

        picker.Text = valueText(control.Value)
    end

    function control:SetValue(value, fireCallback)
        setFlag(self, value)
        self.Picker.Text = valueText(value)
        if fireCallback ~= false then
            protect(self.Callback, value)
        end
    end

    function control:Refresh(optionsList)
        if typeof(optionsList) == "table" then
            self.Options = optionsList
        end
        rebuild()
        resizeMenu()
    end

    picker.MouseButton1Click:Connect(function()
        if control.Enabled == false then
            return
        end

        control.Open = not control.Open
        resizeMenu()
    end)

    setFlag(control, control.Value, false)
    rebuild()
    registerControl(self.Window, control)
    return control
end

function Section:CreateColorPicker(options)
    options = merge({
        Name = "Color",
        CurrentColor = currentTheme().Accent,
        Colors = {
            Color3.fromRGB(92, 164, 255),
            Color3.fromRGB(134, 94, 255),
            Color3.fromRGB(75, 221, 176),
            Color3.fromRGB(255, 92, 135),
            Color3.fromRGB(255, 184, 92),
            Color3.fromRGB(245, 247, 250)
        },
        Flag = nil,
        Callback = nil
    }, options or {})

    if options.Flag and self.Window.Configuration.Values[options.Flag] ~= nil then
        options.CurrentColor = tableToColor(self.Window.Configuration.Values[options.Flag], options.CurrentColor)
    end

    local card, label = makeControl(self, options, 62)
    label.Size = UDim2.new(1, -238, 1, 0)

    local preview = new("Frame", {
        Parent = card,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = tableToColor(options.CurrentColor, currentTheme().Accent),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        ZIndex = 14
    }, {
        corner(8),
        stroke(currentTheme().Stroke, 0.45, 1)
    })

    local swatchHolder = new("Frame", {
        Parent = card,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -52, 0.5, 0),
        Size = UDim2.fromOffset(190, 30),
        ZIndex = 12
    })

    new("UIListLayout", {
        Parent = swatchHolder,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Label = label,
        Preview = preview,
        Holder = swatchHolder,
        Flag = options.Flag,
        Value = tableToColor(options.CurrentColor, currentTheme().Accent),
        Callback = options.Callback,
        Enabled = true,
        Swatches = {}
    }, BaseControl)

    local function sameColor(a, b)
        return math.floor(a.R * 255 + 0.5) == math.floor(b.R * 255 + 0.5)
            and math.floor(a.G * 255 + 0.5) == math.floor(b.G * 255 + 0.5)
            and math.floor(a.B * 255 + 0.5) == math.floor(b.B * 255 + 0.5)
    end

    function control:Refresh()
        self.Preview.BackgroundColor3 = self.Value

        for _, swatch in ipairs(self.Swatches) do
            local selected = sameColor(swatch.Color, self.Value)
            tween(swatch.Button, FAST_TWEEN, {
                Size = selected and UDim2.fromOffset(28, 28) or UDim2.fromOffset(22, 22),
                BackgroundTransparency = selected and 0 or 0.08
            })
        end
    end

    function control:SetValue(value, fireCallback)
        local color = tableToColor(value, self.Value)
        self.Value = color

        if self.Flag then
            SyntraUI.Flags[self.Flag] = color
            self.Window.Configuration.Values[self.Flag] = colorToTable(color)
            self.Window:SaveConfiguration()
        end

        self:Refresh()
        if fireCallback ~= false then
            protect(self.Callback, color)
        end
    end

    for _, color in ipairs(options.Colors) do
        local swatchColor = tableToColor(color, currentTheme().Accent)
        local swatch = new("TextButton", {
            Parent = swatchHolder,
            AutoButtonColor = false,
            BackgroundColor3 = swatchColor,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(22, 22),
            Text = "",
            ZIndex = 13
        }, {
            corner(7),
            stroke(currentTheme().Stroke, 0.45, 1)
        })

        table.insert(control.Swatches, {
            Button = swatch,
            Color = swatchColor
        })

        swatch.MouseButton1Click:Connect(function()
            if control.Enabled == false then
                return
            end
            control:SetValue(swatchColor)
        end)
    end

    if control.Flag then
        SyntraUI.Flags[control.Flag] = control.Value
        control.Window.Configuration.Values[control.Flag] = colorToTable(control.Value)
    end

    control:Refresh()
    registerControl(self.Window, control)
    return control
end

function Section:CreateTextbox(options)
    options = merge({
        Name = "Textbox",
        PlaceholderText = "Enter text",
        CurrentValue = "",
        ClearTextOnFocus = false,
        Flag = nil,
        Callback = nil
    }, options or {})

    if options.Flag and self.Window.Configuration.Values[options.Flag] ~= nil then
        options.CurrentValue = self.Window.Configuration.Values[options.Flag]
    end

    local card, label = makeControl(self, options, 52)
    label.Size = UDim2.new(1, -194, 1, 0)

    local box = new("TextBox", {
        Parent = card,
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = currentTheme().SurfaceHover,
        BorderSizePixel = 0,
        ClearTextOnFocus = options.ClearTextOnFocus,
        Font = Enum.Font.GothamMedium,
        PlaceholderText = options.PlaceholderText,
        PlaceholderColor3 = currentTheme().MutedText,
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(180, 32),
        Text = tostring(options.CurrentValue or ""),
        TextColor3 = currentTheme().Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12
    }, {
        corner(8),
        padding(10, 0, 10, 0)
    })

    themed(self.Window, box, "BackgroundColor3", "SurfaceHover")
    themed(self.Window, box, "TextColor3", "Text")
    themed(self.Window, box, "PlaceholderColor3", "MutedText")

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Label = label,
        Box = box,
        Flag = options.Flag,
        Value = tostring(options.CurrentValue or ""),
        Callback = options.Callback,
        Enabled = true
    }, BaseControl)

    function control:SetValue(value, fireCallback)
        value = tostring(value or "")
        setFlag(self, value)
        self.Box.Text = value
        if fireCallback ~= false then
            protect(self.Callback, value)
        end
    end

    box.FocusLost:Connect(function()
        if control.Enabled == false then
            return
        end

        control:SetValue(box.Text)
    end)

    setFlag(control, control.Value, false)
    registerControl(self.Window, control)
    return control
end

function Section:CreateInput(options)
    return self:CreateTextbox(options)
end

function Section:CreateKeybind(options)
    options = merge({
        Name = "Keybind",
        CurrentKeybind = Enum.KeyCode.F,
        HoldToInteract = false,
        Flag = nil,
        Callback = nil
    }, options or {})

    if options.Flag and self.Window.Configuration.Values[options.Flag] ~= nil then
        local stored = self.Window.Configuration.Values[options.Flag]
        if typeof(stored) == "string" and Enum.KeyCode[stored] then
            options.CurrentKeybind = Enum.KeyCode[stored]
        end
    end

    local card, label = makeControl(self, options, 48)
    label.Size = UDim2.new(1, -124, 1, 0)

    local keyButton = makeButton(card, options.CurrentKeybind and options.CurrentKeybind.Name or "None")
    keyButton.AnchorPoint = Vector2.new(1, 0.5)
    keyButton.Position = UDim2.new(1, -12, 0.5, 0)
    keyButton.Size = UDim2.fromOffset(104, 30)
    keyButton.TextSize = 12
    keyButton.ZIndex = 12
    corner(8).Parent = keyButton

    themed(self.Window, keyButton, "BackgroundColor3", "SurfaceHover")
    themed(self.Window, keyButton, "TextColor3", "Text")

    local control = setmetatable({
        Window = self.Window,
        Section = self,
        Instance = card,
        Label = label,
        Button = keyButton,
        Flag = options.Flag,
        Value = options.CurrentKeybind,
        Callback = options.Callback,
        Hold = options.HoldToInteract,
        Listening = false,
        Enabled = true
    }, BaseControl)

    local function keyName(key)
        if typeof(key) == "EnumItem" then
            return key.Name
        end
        return "None"
    end

    function control:SetValue(value, fireCallback)
        if typeof(value) == "string" and Enum.KeyCode[value] then
            value = Enum.KeyCode[value]
        end

        self.Value = value
        self.Button.Text = keyName(value)

        if self.Flag then
            SyntraUI.Flags[self.Flag] = keyName(value)
            self.Window.Configuration.Values[self.Flag] = keyName(value)
            self.Window:SaveConfiguration()
        end

        if fireCallback ~= false then
            protect(self.Callback, value)
        end
    end

    function control:GetFlagValue()
        return keyName(self.Value)
    end

    keyButton.MouseButton1Click:Connect(function()
        if control.Enabled == false then
            return
        end

        control.Listening = true
        keyButton.Text = "Press key"
    end)

    table.insert(self.Window._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if control.Enabled == false then
            return
        end

        if control.Listening then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                control.Listening = false
                control:SetValue(input.KeyCode, false)
            end
            return
        end

        if input.KeyCode == control.Value then
            if control.Hold then
                protect(control.Callback, true)
            else
                protect(control.Callback)
            end
        end
    end))

    table.insert(self.Window._connections, UserInputService.InputEnded:Connect(function(input)
        if control.Enabled == false or not control.Hold then
            return
        end

        if input.KeyCode == control.Value then
            protect(control.Callback, false)
        end
    end))

    if control.Flag then
        SyntraUI.Flags[control.Flag] = keyName(control.Value)
        control.Window.Configuration.Values[control.Flag] = keyName(control.Value)
    end

    registerControl(self.Window, control)
    return control
end

function Section:AddButton(options)
    return self:CreateButton(options)
end

function Section:AddLabel(options)
    return self:CreateLabel(options)
end

function Section:AddParagraph(options)
    return self:CreateParagraph(options)
end

function Section:AddDivider(options)
    return self:CreateDivider(options)
end

function Section:AddProgress(options)
    return self:CreateProgress(options)
end

function Section:AddToggle(options)
    return self:CreateToggle(options)
end

function Section:AddSlider(options)
    return self:CreateSlider(options)
end

function Section:AddDropdown(options)
    return self:CreateDropdown(options)
end

function Section:AddColorPicker(options)
    return self:CreateColorPicker(options)
end

function Section:AddTextbox(options)
    return self:CreateTextbox(options)
end

function Section:AddInput(options)
    return self:CreateTextbox(options)
end

function Section:AddKeybind(options)
    return self:CreateKeybind(options)
end

function Tab:AddSection(name)
    return self:CreateSection(name)
end

function Window:AddTab(name, icon)
    return self:CreateTab(name, icon)
end

function Window:AddSection(name)
    return self:CreateSection(name)
end

function Window:AddButton(options)
    return self:CreateSection("Controls"):CreateButton(options)
end

function Window:AddLabel(options)
    return self:CreateSection("Controls"):CreateLabel(options)
end

function Window:AddParagraph(options)
    return self:CreateSection("Controls"):CreateParagraph(options)
end

function Window:AddDivider(options)
    return self:CreateSection("Controls"):CreateDivider(options)
end

function Window:AddProgress(options)
    return self:CreateSection("Controls"):CreateProgress(options)
end

function Window:AddToggle(options)
    return self:CreateSection("Controls"):CreateToggle(options)
end

function Window:AddSlider(options)
    return self:CreateSection("Controls"):CreateSlider(options)
end

function Window:AddDropdown(options)
    return self:CreateSection("Controls"):CreateDropdown(options)
end

function Window:AddColorPicker(options)
    return self:CreateSection("Controls"):CreateColorPicker(options)
end

function Window:AddTextbox(options)
    return self:CreateSection("Controls"):CreateTextbox(options)
end

function Window:AddInput(options)
    return self:CreateSection("Controls"):CreateTextbox(options)
end

function Window:AddKeybind(options)
    return self:CreateSection("Controls"):CreateKeybind(options)
end

return SyntraUI
