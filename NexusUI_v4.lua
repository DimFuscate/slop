
-- ================================================================
-- SERVICES
-- ================================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ================================================================
-- COLOURS
-- ================================================================
local SILVER     = Color3.fromRGB(160, 165, 180)
local SILVER_DIM = Color3.fromRGB(70,  74,  86)
local BLACK      = Color3.fromRGB(8,   8,   11)
local PANEL      = Color3.fromRGB(13,  13,  17)
local SURFACE    = Color3.fromRGB(19,  19,  25)
local BORDER     = Color3.fromRGB(45,  48,  58)
local WHITE_TEXT = Color3.fromRGB(210, 214, 228)
local DIM_TEXT   = Color3.fromRGB(100, 104, 118)
local SUCCESS_C  = Color3.fromRGB(60,  200, 100)
local ERROR_C    = Color3.fromRGB(200, 60,  60)
local WARN_C     = Color3.fromRGB(200, 160, 40)

local TITLE_FONT = Font.new(
    "rbxasset://fonts/families/TitilliumWeb.json",
    Enum.FontWeight.Bold,
    Enum.FontStyle.Normal
)
local BODY_FONT  = Font.new(
    "rbxasset://fonts/families/TitilliumWeb.json",
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)

-- ================================================================
-- INTERNAL HELPERS
-- ================================================================
local function tw(obj, t, props, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function corner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = p
    return c
end

local function stroke(th, col, p)
    local s = Instance.new("UIStroke")
    s.Thickness = th
    s.Color     = col
    s.Parent    = p
    return s
end

local function metalGrad(parent, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(35,  37,  47)),
        ColorSequenceKeypoint.new(0.2,  Color3.fromRGB(95,  99,  115)),
        ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(165, 170, 188)),
        ColorSequenceKeypoint.new(0.8,  Color3.fromRGB(95,  99,  115)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(35,  37,  47)),
    })
    g.Rotation = rotation or 45
    g.Parent   = parent
    return g
end

local function isAssetId(v)
    return type(v) == "string" and v:sub(1, 13) == "rbxassetid://"
end

-- Draggable helper
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ================================================================
-- NOTIFICATION SYSTEM  (standalone, no window required)
-- ================================================================
local _notifGui, _notifContainer, _notifCount = nil, nil, 0

local function _ensureNotifGui()
    if _notifGui and _notifGui.Parent then return end
    _notifGui = Instance.new("ScreenGui")
    _notifGui.Name           = "NexusUI_Notifs"
    _notifGui.ResetOnSpawn   = false
    _notifGui.DisplayOrder   = 999
    pcall(function() _notifGui.Parent = CoreGui end)
    if not _notifGui.Parent then _notifGui.Parent = LocalPlayer.PlayerGui end

    _notifContainer = Instance.new("Frame", _notifGui)
    _notifContainer.Size                   = UDim2.new(0, 320, 1, -20)
    _notifContainer.Position               = UDim2.new(1, -330, 0, 10)
    _notifContainer.BackgroundTransparency = 1

    local lay = Instance.new("UIListLayout", _notifContainer)
    lay.VerticalAlignment = Enum.VerticalAlignment.Top
    lay.Padding           = UDim.new(0, 8)
    lay.SortOrder         = Enum.SortOrder.LayoutOrder
end

local function _notify(config)
    config = config or {}
    _ensureNotifGui()
    _notifCount = _notifCount + 1

    local ntype   = config.Type    or "Info"
    local title   = config.Title   or "Notification"
    local content = config.Content or ""
    local dur     = config.Duration or 4

    local accentMap = {
        Success = SUCCESS_C,
        Error   = ERROR_C,
        Warning = WARN_C,
        Info    = SILVER,
    }
    local iconMap = {
        Success = "✓",
        Error   = "✕",
        Warning = "!",
        Info    = "i",
    }

    local accent = accentMap[ntype] or SILVER
    local icon   = iconMap[ntype]   or "i"

    local card = Instance.new("Frame", _notifContainer)
    card.Size                   = UDim2.new(1, 0, 0, 66)
    card.BackgroundColor3       = PANEL
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel        = 0
    card.LayoutOrder            = _notifCount
    card.Position               = UDim2.new(1.1, 0, 0, 0)
    corner(10, card)
    stroke(1.5, BORDER, card)

    -- Accent left bar
    local bar = Instance.new("Frame", card)
    bar.Size             = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel  = 0
    corner(4, bar)

    -- Icon circle
    local iconFrame = Instance.new("Frame", card)
    iconFrame.Size             = UDim2.new(0, 28, 0, 28)
    iconFrame.Position         = UDim2.new(0, 12, 0.5, -14)
    iconFrame.BackgroundColor3 = accent
    iconFrame.BackgroundTransparency = 0.75
    iconFrame.BorderSizePixel  = 0
    corner(14, iconFrame)

    local iconLbl = Instance.new("TextLabel", iconFrame)
    iconLbl.Size                   = UDim2.new(1, 0, 1, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text                   = icon
    iconLbl.TextColor3             = accent
    iconLbl.TextSize               = 14
    iconLbl.FontFace               = TITLE_FONT

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size                   = UDim2.new(1, -54, 0, 22)
    titleLbl.Position               = UDim2.new(0, 48, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text                   = title
    titleLbl.TextColor3             = WHITE_TEXT
    titleLbl.TextSize               = 13
    titleLbl.FontFace               = TITLE_FONT
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left

    local contentLbl = Instance.new("TextLabel", card)
    contentLbl.Size                   = UDim2.new(1, -54, 0, 28)
    contentLbl.Position               = UDim2.new(0, 48, 0, 28)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text                   = content
    contentLbl.TextColor3             = DIM_TEXT
    contentLbl.TextSize               = 11
    contentLbl.FontFace               = BODY_FONT
    contentLbl.TextXAlignment         = Enum.TextXAlignment.Left
    contentLbl.TextWrapped            = true

    -- Slide in
    tw(card, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    task.delay(dur, function()
        tw(card, 0.3, {Position = UDim2.new(1.1, 0, 0, 0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.32)
        card:Destroy()
    end)
end

-- ================================================================
-- KEY SYSTEM
-- ================================================================
local function _keySystem(config, onSuccess)
    config = config or {}

    local title     = config.Title      or "Key System"
    local validKeys = config.Valid_Keys or {}  -- array of string keys
    local keyURL    = config.KeyURL     -- optional link to get a key
    local keyAPI    = config.KeyAPI     -- optional validation endpoint
    local keySecret = config.KeySecret  or ""
    local maxTries  = config.Attempts   or 3
    local kickOnFail = config.KickOnFail ~= false

    -- Validate via API or local list
    local function validateKey(k)
        -- API validation
        if keyAPI and keyAPI ~= "" then
            local ok, res = pcall(function()
                return HttpService:RequestAsync({
                    Url     = keyAPI .. "?key=" .. HttpService:UrlEncode(k),
                    Method  = "GET",
                    Headers = { ["x-secret"] = keySecret },
                })
            end)
            return ok and res and res.Success
                and (res.Body or ""):find('"valid"%s*:%s*true') ~= nil
        end
        -- Local key list
        for _, v in ipairs(validKeys) do
            if v == k then return true end
        end
        return false
    end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "NexusKey"
    sg.ResetOnSpawn   = false
    sg.DisplayOrder   = 998
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = LocalPlayer.PlayerGui end

    local overlay = Instance.new("Frame", sg)
    overlay.Size             = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel  = 0

    local card = Instance.new("Frame", sg)
    card.Size             = UDim2.new(0, 420, 0, 240)
    card.Position         = UDim2.new(0.5, -210, 0.5, -120)
    card.BackgroundColor3 = PANEL
    card.BorderSizePixel  = 0
    corner(12, card)
    local cs = stroke(1.5, BORDER, card)
    metalGrad(cs, 45)

    -- Top accent line
    local accentLine = Instance.new("Frame", card)
    accentLine.Size             = UDim2.new(1, 0, 0, 2)
    accentLine.BackgroundColor3 = SILVER
    accentLine.BorderSizePixel  = 0
    corner(12, accentLine)

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size               = UDim2.new(1, -30, 0, 28)
    titleLbl.Position           = UDim2.new(0, 15, 0, 16)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text               = title
    titleLbl.TextColor3         = WHITE_TEXT
    titleLbl.TextSize           = 16
    titleLbl.FontFace           = TITLE_FONT
    titleLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local subLbl = Instance.new("TextLabel", card)
    subLbl.Size               = UDim2.new(1, -30, 0, 18)
    subLbl.Position           = UDim2.new(0, 15, 0, 44)
    subLbl.BackgroundTransparency = 1
    subLbl.Text               = "Enter your access key to continue."
    subLbl.TextColor3         = DIM_TEXT
    subLbl.TextSize           = 12
    subLbl.FontFace           = BODY_FONT
    subLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local inputBg = Instance.new("Frame", card)
    inputBg.Size             = UDim2.new(1, -30, 0, 38)
    inputBg.Position         = UDim2.new(0, 15, 0, 76)
    inputBg.BackgroundColor3 = SURFACE
    inputBg.BorderSizePixel  = 0
    corner(7, inputBg)
    local inputStroke = stroke(1, BORDER, inputBg)

    local inputBox = Instance.new("TextBox", inputBg)
    inputBox.Size               = UDim2.new(1, -20, 1, 0)
    inputBox.Position           = UDim2.new(0, 10, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Text               = ""
    inputBox.PlaceholderText    = "XXXX-XXXX-XXXX-XXXX"
    inputBox.PlaceholderColor3  = DIM_TEXT
    inputBox.TextColor3         = SILVER
    inputBox.TextSize           = 13
    inputBox.FontFace           = BODY_FONT
    inputBox.ClearTextOnFocus   = false

    inputBox.Focused:Connect(function()
        tw(inputStroke, 0.15, {Color = SILVER})
    end)
    inputBox.FocusLost:Connect(function()
        tw(inputStroke, 0.15, {Color = BORDER})
    end)

    local statusLbl = Instance.new("TextLabel", card)
    statusLbl.Size               = UDim2.new(1, -30, 0, 18)
    statusLbl.Position           = UDim2.new(0, 15, 0, 122)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text               = "Attempts: 0 / " .. maxTries
    statusLbl.TextColor3         = DIM_TEXT
    statusLbl.TextSize           = 11
    statusLbl.FontFace           = BODY_FONT
    statusLbl.TextXAlignment     = Enum.TextXAlignment.Left

    local submitBtn = Instance.new("TextButton", card)
    submitBtn.Size             = UDim2.new(1, -30, 0, 38)
    submitBtn.Position         = UDim2.new(0, 15, 0, 148)
    submitBtn.BackgroundColor3 = SURFACE
    submitBtn.BorderSizePixel  = 0
    submitBtn.Text             = "SUBMIT KEY"
    submitBtn.TextColor3       = WHITE_TEXT
    submitBtn.TextSize         = 14
    submitBtn.FontFace         = TITLE_FONT
    submitBtn.AutoButtonColor  = false
    corner(7, submitBtn)
    stroke(1, BORDER, submitBtn)

    if keyURL and keyURL ~= "" then
        local getKeyBtn = Instance.new("TextButton", card)
        getKeyBtn.Size             = UDim2.new(1, -30, 0, 24)
        getKeyBtn.Position         = UDim2.new(0, 15, 0, 200)
        getKeyBtn.BackgroundTransparency = 1
        getKeyBtn.Text             = "Get a key →  " .. keyURL
        getKeyBtn.TextColor3       = DIM_TEXT
        getKeyBtn.TextSize         = 11
        getKeyBtn.FontFace         = BODY_FONT
        getKeyBtn.AutoButtonColor  = false
        getKeyBtn.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(keyURL) end)
            getKeyBtn.Text = "Link copied to clipboard!"
            task.delay(2.5, function()
                if getKeyBtn.Parent then
                    getKeyBtn.Text = "Get a key →  " .. keyURL
                end
            end)
        end)
    end

    -- Animate card in
    card.Position = UDim2.new(0.5, -210, 0.62, -120)
    tw(card, 0.4, {Position = UDim2.new(0.5, -210, 0.5, -120)},
       Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local tries  = 0
    local done   = false
    local busy   = false

    local function shakeCard()
        local orig = card.Position
        for _, ox in ipairs({8, -8, 5, -5, 3, 0}) do
            card.Position = UDim2.new(
                orig.X.Scale, orig.X.Offset + ox,
                orig.Y.Scale, orig.Y.Offset
            )
            task.wait(0.04)
        end
        card.Position = orig
    end

    local function onSubmit()
        if done or busy then return end
        local k = inputBox.Text:match("^%s*(.-)%s*$")
        if k == "" then
            statusLbl.TextColor3 = WARN_C
            statusLbl.Text = "Please enter a key."
            return
        end
        busy = true
        submitBtn.Text      = "Validating..."
        submitBtn.BackgroundColor3 = SURFACE
        statusLbl.TextColor3 = DIM_TEXT
        statusLbl.Text = "Checking..."

        task.spawn(function()
            local ok = validateKey(k)
            busy = false

            if ok then
                done = true
                submitBtn.BackgroundColor3 = SUCCESS_C
                submitBtn.Text = "✓  Access Granted"
                statusLbl.TextColor3 = SUCCESS_C
                statusLbl.Text = "Key accepted."
                task.wait(0.7)
                tw(card, 0.35, {BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, -210, 0.4, -120)},
                    Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                tw(overlay, 0.35, {BackgroundTransparency = 1})
                task.wait(0.38)
                sg:Destroy()
                if onSuccess then onSuccess() end
            else
                tries = tries + 1
                statusLbl.Text = "Attempts: " .. tries .. " / " .. maxTries
                statusLbl.TextColor3 = tries >= maxTries and ERROR_C or WARN_C
                submitBtn.BackgroundColor3 = ERROR_C
                submitBtn.Text = "✕  Invalid Key  (" .. math.max(0, maxTries - tries) .. " left)"
                shakeCard()
                task.wait(1.6)
                if not done then
                    submitBtn.BackgroundColor3 = SURFACE
                    submitBtn.Text = "SUBMIT KEY"
                end
                if tries >= maxTries and kickOnFail then
                    done = true
                    submitBtn.Text = "Kicked."
                    task.wait(0.6)
                    LocalPlayer:Kick("Invalid key — too many failed attempts.")
                end
            end
        end)
    end

    submitBtn.MouseButton1Click:Connect(onSubmit)
    inputBox.FocusLost:Connect(function(enter)
        if enter then onSubmit() end
    end)
end

-- ================================================================
-- NEXUS LIBRARY
-- ================================================================
local Nexus = {}
Nexus.__index = Nexus

-- ── Nexus:KeySystem(config, onSuccess) ──────────────────────────
-- Call before CreateWindow if you want a key gate.
-- Pass an onSuccess callback or it will just block until accepted.
function Nexus:KeySystem(config, onSuccess)
    if onSuccess then
        _keySystem(config, onSuccess)
        return
    end
    -- Blocking version: yield until key is accepted
    local done = false
    _keySystem(config, function() done = true end)
    while not done do task.wait(0.1) end
end

-- ── Nexus:Notify(config) ────────────────────────────────────────
-- config = { Title, Content, Type, Duration }
-- Type   = "Success" | "Error" | "Warning" | "Info"
function Nexus:Notify(config)
    _notify(config)
end

-- ── Nexus:Create(kind, parent, config) ──────────────────────────
function Nexus:Create(kind, parent, config)
    config = config or {}

    if kind == "Window" then
        return self:_createWindow(config)

    elseif kind == "Tab" then
        assert(type(parent) == "table" and parent._addTab,
            "Nexus:Create('Tab') — parent must be a Window object")
        return parent:_addTab(config)

    elseif kind == "Button" then
        assert(type(parent) == "table" and parent._addButton,
            "Nexus:Create('Button') — parent must be a Tab object")
        return parent:_addButton(config)

    elseif kind == "Toggle" then
        assert(type(parent) == "table" and parent._addToggle,
            "Nexus:Create('Toggle') — parent must be a Tab object")
        return parent:_addToggle(config)

    elseif kind == "Slider" then
        assert(type(parent) == "table" and parent._addSlider,
            "Nexus:Create('Slider') — parent must be a Tab object")
        return parent:_addSlider(config)

    elseif kind == "Dropdown" then
        assert(type(parent) == "table" and parent._addDropdown,
            "Nexus:Create('Dropdown') — parent must be a Tab object")
        return parent:_addDropdown(config)

    elseif kind == "Paragraph" then
        assert(type(parent) == "table" and parent._addParagraph,
            "Nexus:Create('Paragraph') — parent must be a Tab object")
        return parent:_addParagraph(config)

    elseif kind == "Description" then
        -- Attaches a description label beneath a feature row
        assert(type(parent) == "table" and parent._frame,
            "Nexus:Create('Description') — parent must be a feature object")
        return self:_addDescription(parent, config)

    elseif kind == "Tag" then
        assert(type(parent) == "table" and parent._tagBar,
            "Nexus:Create('Tag') — parent must be a Window object")
        return parent:_addTag(config)

    else
        error("Nexus:Create — unknown kind '" .. tostring(kind) .. "'")
    end
end

-- ================================================================
-- DESCRIPTION  (attaches below any feature frame)
-- ================================================================
function Nexus:_addDescription(featureObj, config)
    local text = config.Content or config.Text or ""
    local frame = featureObj._frame
    if not frame then return end

    -- Expand the parent row height
    local origHeight = frame.Size.Y.Offset
    frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset,
                           0, origHeight + 22)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size               = UDim2.new(1, -20, 0, 18)
    lbl.Position           = UDim2.new(0, 10, 0, origHeight)
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel    = 0
    lbl.Text               = text
    lbl.TextColor3         = DIM_TEXT
    lbl.TextSize           = 11
    lbl.FontFace           = BODY_FONT
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    return lbl
end

-- ================================================================
-- WINDOW  (internal builder)
-- ================================================================
function Nexus:_createWindow(config)
    local title        = config.Title                or "Nexus Hub"
    local version      = config.Version              or "v1.0"
    local icon         = config.Icon                 or "ND"
    local draggable    = config.Draggable            ~= false
    local minBtn       = config.MinimizeButtonEnabled ~= false
    local loadEnabled  = config.LoadingEnabled       ~= false
    local loadTitle    = config.LoadingTitle         or title
    local loadText     = config.LoadingText          or ("Thanks for using " .. title .. "!")
    local hideCmd      = config.HideAllCommand
    local showCmd      = config.ShowAllCommand

    -- ── ScreenGui ────────────────────────────────────────────────
    local sg = Instance.new("ScreenGui")
    sg.Name           = "NexusUI_" .. title
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.ResetOnSpawn   = false
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = LocalPlayer.PlayerGui end

    -- ================================================================
    -- LOADING INTRO
    -- ================================================================
    if loadEnabled then
        local LF = Instance.new("Frame", sg)
        LF.Name               = "Loading_Intro"
        LF.Size               = UDim2.new(0, 420, 0, 68)
        LF.AnchorPoint        = Vector2.new(0.5, 0)
        LF.Position           = UDim2.new(0.5, 0, -0.15, 0)
        LF.BackgroundColor3   = PANEL
        LF.BorderSizePixel    = 0
        LF.ZIndex             = 10
        corner(14, LF)
        local lStroke = stroke(1.5, BORDER, LF)
        local lGrad   = Instance.new("UIGradient", lStroke)
        lGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(40,  42,  52)),
            ColorSequenceKeypoint.new(0.35, Color3.fromRGB(130, 134, 150)),
            ColorSequenceKeypoint.new(0.65, Color3.fromRGB(130, 134, 150)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(40,  42,  52)),
        })
        lGrad.Rotation = 45

        -- Logo mark
        local lm
        if isAssetId(icon) then
            lm = Instance.new("ImageLabel", LF)
            lm.Image     = icon
            lm.ScaleType = Enum.ScaleType.Fit
        else
            lm = Instance.new("TextLabel", LF)
            lm.Text      = icon
            lm.TextColor3 = SILVER
            lm.TextSize  = 14
            lm.FontFace  = TITLE_FONT
        end
        lm.Size             = UDim2.new(0, 38, 0, 38)
        lm.Position         = UDim2.new(0, 15, 0.5, -19)
        lm.BackgroundColor3 = SURFACE
        lm.BorderSizePixel  = 0
        lm.ZIndex           = 11
        corner(8, lm)
        stroke(1, BORDER, lm)

        local lt = Instance.new("TextLabel", LF)
        lt.Size               = UDim2.new(1, -70, 0, 22)
        lt.Position           = UDim2.new(0, 62, 0, 12)
        lt.BackgroundTransparency = 1
        lt.Text               = loadTitle
        lt.TextColor3         = WHITE_TEXT
        lt.TextSize           = 16
        lt.FontFace           = TITLE_FONT
        lt.TextXAlignment     = Enum.TextXAlignment.Left
        lt.ZIndex             = 11

        local ls = Instance.new("TextLabel", LF)
        ls.Size               = UDim2.new(1, -70, 0, 18)
        ls.Position           = UDim2.new(0, 62, 0, 34)
        ls.BackgroundTransparency = 1
        ls.Text               = loadText
        ls.TextColor3         = DIM_TEXT
        ls.TextSize           = 12
        ls.FontFace           = BODY_FONT
        ls.TextXAlignment     = Enum.TextXAlignment.Left
        ls.ZIndex             = 11

        local pbg = Instance.new("Frame", LF)
        pbg.Size             = UDim2.new(1, -24, 0, 3)
        pbg.Position         = UDim2.new(0, 12, 1, -8)
        pbg.BackgroundColor3 = SURFACE
        pbg.BorderSizePixel  = 0
        pbg.ZIndex           = 11
        corner(99, pbg)

        local pf = Instance.new("Frame", pbg)
        pf.Size             = UDim2.new(0, 0, 1, 0)
        pf.BackgroundColor3 = SILVER
        pf.BorderSizePixel  = 0
        pf.ZIndex           = 12
        corner(99, pf)

        task.spawn(function()
            tw(LF, 0.65, {Position = UDim2.new(0.5, 0, 0, 26)},
               Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            task.wait(0.1)
            tw(pf, 2.4, {Size = UDim2.new(1, 0, 1, 0)},
               Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            task.wait(2.6)
            local FADE = 0.45
            tw(LF, FADE, {BackgroundTransparency = 1})
            for _, obj in ipairs(LF:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    tw(obj, FADE, {TextTransparency = 1})
                end
                if obj:IsA("Frame") or obj:IsA("ImageLabel") then
                    tw(obj, FADE, {BackgroundTransparency = 1})
                end
                if obj:IsA("UIStroke") then tw(obj, FADE, {Transparency = 1}) end
            end
            task.wait(FADE + 0.05)
            LF.Visible = false
        end)
    end

    -- ================================================================
    -- LOGO TOGGLE BUTTON
    -- ================================================================
    local LogoToggle
    if isAssetId(icon) then
        LogoToggle = Instance.new("ImageButton", sg)
        LogoToggle.Image     = icon
        LogoToggle.ScaleType = Enum.ScaleType.Fit
    else
        LogoToggle = Instance.new("TextButton", sg)
        LogoToggle.Text      = icon
        LogoToggle.TextColor3 = SILVER
        LogoToggle.TextSize  = 15
        LogoToggle.FontFace  = TITLE_FONT
        LogoToggle.BackgroundTransparency = 0
    end
    LogoToggle.Name                  = "Logo_Toggle"
    LogoToggle.Size                  = UDim2.new(0, 48, 0, 46)
    LogoToggle.Position              = UDim2.new(0, 14, 0, 18)
    LogoToggle.BackgroundColor3      = PANEL
    LogoToggle.BorderSizePixel       = 0
    LogoToggle.AutoButtonColor       = false
    LogoToggle.Visible               = not loadEnabled
    LogoToggle.ZIndex                = 5
    corner(10, LogoToggle)
    local logoStroke = stroke(1.5, BORDER, LogoToggle)
    local logoGrad   = Instance.new("UIGradient", logoStroke)
    logoGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(40,  42,  52)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 114, 130)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(40,  42,  52)),
    })
    logoGrad.Rotation = 45

    -- Rotate logo border shimmer
    task.spawn(function()
        local r = 45
        while LogoToggle and LogoToggle.Parent do
            r = (r + 1.5) % 360
            logoGrad.Rotation = r
            task.wait(0.03)
        end
    end)

    if loadEnabled then
        task.spawn(function()
            task.wait(3.5)
            LogoToggle.Visible = true
            LogoToggle.Size    = UDim2.new(0, 0, 0, 0)
            tw(LogoToggle, 0.4, {Size = UDim2.new(0, 48, 0, 46)}, Enum.EasingStyle.Back)
        end)
    end

    LogoToggle.MouseEnter:Connect(function()
        tw(LogoToggle, 0.12, {BackgroundColor3 = SURFACE})
        tw(logoStroke, 0.12, {Color = SILVER})
    end)
    LogoToggle.MouseLeave:Connect(function()
        tw(LogoToggle, 0.12, {BackgroundColor3 = PANEL})
        tw(logoStroke, 0.12, {Color = BORDER})
    end)

    -- ================================================================
    -- MAIN WINDOW FRAME
    -- ================================================================
    local WinFrame = Instance.new("Frame", sg)
    WinFrame.Name                  = "Window_Frame"
    WinFrame.Size                  = UDim2.new(0, 534, 0, 272)
    WinFrame.Position              = UDim2.new(0, 70, 0, 18)
    WinFrame.BackgroundColor3      = BLACK
    WinFrame.BackgroundTransparency = 0.08
    WinFrame.BorderSizePixel       = 0
    WinFrame.Visible               = false
    WinFrame.ClipsDescendants      = false
    corner(12, WinFrame)

    local winStroke = stroke(1.5, BORDER, WinFrame)
    local winGrad   = metalGrad(winStroke, 45)

    task.spawn(function()
        local r = 45
        while WinFrame and WinFrame.Parent do
            r = (r + 0.4) % 360
            winGrad.Rotation = r
            task.wait(0.03)
        end
    end)

    local winBgGrad = Instance.new("UIGradient", WinFrame)
    winBgGrad.Color    = ColorSequence.new(Color3.fromRGB(12,12,16), Color3.fromRGB(7,7,10))
    winBgGrad.Rotation = 90

    -- ── Title bar ────────────────────────────────────────────────
    local TitleBar = Instance.new("Frame", WinFrame)
    TitleBar.Name                  = "TitleBar"
    TitleBar.Size                  = UDim2.new(1, 0, 0, 34)
    TitleBar.BackgroundColor3      = PANEL
    TitleBar.BackgroundTransparency = 0.1
    TitleBar.BorderSizePixel       = 0
    corner(12, TitleBar)

    local tbFill = Instance.new("Frame", TitleBar)
    tbFill.Size             = UDim2.new(1, 0, 0, 12)
    tbFill.Position         = UDim2.new(0, 0, 1, -12)
    tbFill.BackgroundColor3 = PANEL
    tbFill.BackgroundTransparency = 0.1
    tbFill.BorderSizePixel  = 0

    local accentLine = Instance.new("Frame", TitleBar)
    accentLine.Size             = UDim2.new(1, 0, 0, 1)
    accentLine.Position         = UDim2.new(0, 0, 1, -1)
    accentLine.BackgroundColor3 = BORDER
    accentLine.BorderSizePixel  = 0

    -- Title text + gradient
    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.Name               = "Title_Label"
    TitleLabel.Size               = UDim2.new(0, 180, 1, 0)
    TitleLabel.Position           = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text               = title
    TitleLabel.TextColor3         = WHITE_TEXT
    TitleLabel.TextSize           = 15
    TitleLabel.FontFace           = TITLE_FONT
    TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
    TitleLabel.ZIndex             = 2

    -- Version chip
    local VerChip = Instance.new("Frame", TitleBar)
    VerChip.Size             = UDim2.new(0, 44, 0, 16)
    VerChip.Position         = UDim2.new(0, 192, 0.5, -8)
    VerChip.BackgroundColor3 = SURFACE
    VerChip.BorderSizePixel  = 0
    VerChip.ZIndex           = 2
    corner(4, VerChip)

    local VerLabel = Instance.new("TextLabel", VerChip)
    VerLabel.Size               = UDim2.new(1, 0, 1, 0)
    VerLabel.BackgroundTransparency = 1
    VerLabel.Text               = version
    VerLabel.TextColor3         = SILVER_DIM
    VerLabel.TextSize           = 10
    VerLabel.FontFace           = BODY_FONT
    VerLabel.ZIndex             = 3

    -- Tag bar (right of title)
    local TagBar = Instance.new("Frame", TitleBar)
    TagBar.Name                  = "TagBar"
    TagBar.Size                  = UDim2.new(0.4, 0, 1, 0)
    TagBar.Position              = UDim2.new(0.58, 0, 0, 0)
    TagBar.BackgroundTransparency = 1
    TagBar.BorderSizePixel       = 0
    TagBar.ZIndex                = 2

    local tagLayout = Instance.new("UIListLayout", TagBar)
    tagLayout.FillDirection        = Enum.FillDirection.Horizontal
    tagLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Right
    tagLayout.VerticalAlignment    = Enum.VerticalAlignment.Center
    tagLayout.Padding              = UDim.new(0, 5)
    local tagPad = Instance.new("UIPadding", TagBar)
    tagPad.PaddingRight = UDim.new(0, 8)

    -- Minimize pill
    local MinimizeBtn = Instance.new("TextButton", TitleBar)
    MinimizeBtn.Name             = "Minimize_Btn"
    MinimizeBtn.Size             = UDim2.new(0, 160, 0, 5)
    MinimizeBtn.Position         = UDim2.new(0.5, -80, 0, 6)
    MinimizeBtn.BackgroundColor3 = SILVER_DIM
    MinimizeBtn.BackgroundTransparency = 0.4
    MinimizeBtn.BorderSizePixel  = 0
    MinimizeBtn.Text             = ""
    MinimizeBtn.AutoButtonColor  = false
    MinimizeBtn.ZIndex           = 3
    MinimizeBtn.Visible          = minBtn
    corner(99, MinimizeBtn)

    MinimizeBtn.MouseEnter:Connect(function()
        tw(MinimizeBtn, 0.15, {BackgroundColor3 = SILVER, BackgroundTransparency = 0.1})
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        tw(MinimizeBtn, 0.2, {BackgroundColor3 = SILVER_DIM, BackgroundTransparency = 0.4})
    end)

    -- ── Sidebar ──────────────────────────────────────────────────
    local Sidebar = Instance.new("Frame", WinFrame)
    Sidebar.Name             = "Tabs_Window"
    Sidebar.Size             = UDim2.new(0, 140, 1, -34)
    Sidebar.Position         = UDim2.new(0, 0, 0, 34)
    Sidebar.BackgroundColor3 = PANEL
    Sidebar.BackgroundTransparency = 0.05
    Sidebar.BorderSizePixel  = 0
    corner(12, Sidebar)

    local sbTopFill = Instance.new("Frame", Sidebar)
    sbTopFill.Size             = UDim2.new(1, 0, 0, 12)
    sbTopFill.BackgroundColor3 = PANEL
    sbTopFill.BackgroundTransparency = 0.05
    sbTopFill.BorderSizePixel  = 0

    local sbBorder = Instance.new("Frame", Sidebar)
    sbBorder.Size             = UDim2.new(0, 1, 1, 0)
    sbBorder.Position         = UDim2.new(1, -1, 0, 0)
    sbBorder.BackgroundColor3 = BORDER
    sbBorder.BorderSizePixel  = 0

    local TabList = Instance.new("UIListLayout", Sidebar)
    TabList.SortOrder           = Enum.SortOrder.LayoutOrder
    TabList.Padding             = UDim.new(0, 4)
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local sbPad = Instance.new("UIPadding", Sidebar)
    sbPad.PaddingTop    = UDim.new(0, 10)
    sbPad.PaddingLeft   = UDim.new(0, 6)
    sbPad.PaddingRight  = UDim.new(0, 6)
    sbPad.PaddingBottom = UDim.new(0, 6)

    -- ── Content area ─────────────────────────────────────────────
    local ContentArea = Instance.new("Frame", WinFrame)
    ContentArea.Name             = "Content_Window"
    ContentArea.Size             = UDim2.new(1, -140, 1, -34)
    ContentArea.Position         = UDim2.new(0, 140, 0, 34)
    ContentArea.BackgroundColor3 = BLACK
    ContentArea.BackgroundTransparency = 0.05
    ContentArea.BorderSizePixel  = 0
    ContentArea.ClipsDescendants = true
    corner(12, ContentArea)

    local caTopFill = Instance.new("Frame", ContentArea)
    caTopFill.Size             = UDim2.new(1, 0, 0, 12)
    caTopFill.BackgroundColor3 = BLACK
    caTopFill.BackgroundTransparency = 0.05
    caTopFill.BorderSizePixel  = 0

    -- Active tab name label (the "FAH" pill from the original — updates on each tab switch)
    local TabNameLabel = Instance.new("TextLabel", ContentArea)
    TabNameLabel.Name               = "ActiveTabName"
    TabNameLabel.Size               = UDim2.new(0, 324, 0, 14)
    TabNameLabel.Position           = UDim2.new(0, 30, 0, 8)
    TabNameLabel.BackgroundColor3   = Color3.new(1, 1, 1)
    TabNameLabel.BackgroundTransparency = 0
    TabNameLabel.BorderSizePixel    = 0
    TabNameLabel.Text               = ""
    TabNameLabel.TextColor3         = Color3.new(0, 0, 0)
    TabNameLabel.TextSize           = 12
    TabNameLabel.FontFace           = Font.new(
        "rbxasset://fonts/families/DenkOne.json",
        Enum.FontWeight.Regular,
        Enum.FontStyle.Normal
    )
    TabNameLabel.ZIndex             = 3
    corner(9999, TabNameLabel)

    local tabNameGrad = Instance.new("UIGradient", TabNameLabel)
    tabNameGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,   0,   0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,   0,   0)),
    })

    -- ── Dragging ─────────────────────────────────────────────────
    if draggable then
        MakeDraggable(WinFrame, TitleBar)
    end

    -- ── Open / Close ─────────────────────────────────────────────
    local OPEN_POS  = WinFrame.Position
    local OPEN_SIZE = WinFrame.Size

    local function openWindow()
        LogoToggle.Visible = false
        WinFrame.Visible   = true
        WinFrame.Size      = UDim2.new(0, 0, 0, 0)
        WinFrame.Position  = UDim2.new(
            OPEN_POS.X.Scale, OPEN_POS.X.Offset + OPEN_SIZE.X.Offset * 0.5,
            OPEN_POS.Y.Scale, OPEN_POS.Y.Offset + OPEN_SIZE.Y.Offset * 0.5
        )
        tw(WinFrame, 0.45, {Size = OPEN_SIZE, Position = OPEN_POS},
           Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    local function closeWindow()
        local closePos = UDim2.new(
            OPEN_POS.X.Scale, OPEN_POS.X.Offset + OPEN_SIZE.X.Offset * 0.5,
            OPEN_POS.Y.Scale, OPEN_POS.Y.Offset + OPEN_SIZE.Y.Offset * 0.5
        )
        tw(WinFrame, 0.35, {Size = UDim2.new(0,0,0,0), Position = closePos},
           Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.38)
        WinFrame.Visible   = false
        LogoToggle.Visible = true
        WinFrame.Position  = OPEN_POS
        WinFrame.Size      = OPEN_SIZE
    end

    LogoToggle.MouseButton1Click:Connect(function()
        tw(LogoToggle, 0.08, {Size = UDim2.new(0, 42, 0, 40)},
           Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.08)
        tw(LogoToggle, 0.14, {Size = UDim2.new(0, 48, 0, 46)}, Enum.EasingStyle.Back)
        openWindow()
    end)

    if minBtn then
        MinimizeBtn.MouseButton1Click:Connect(closeWindow)
    end

    -- RightShift toggle
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            if WinFrame.Visible then closeWindow() else openWindow() end
        end
    end)

    -- Chat commands
    if hideCmd or showCmd then
        LocalPlayer.Chatted:Connect(function(msg)
            if hideCmd and msg:lower() == hideCmd:lower() then
                if WinFrame.Visible then closeWindow() end
            elseif showCmd and msg:lower() == showCmd:lower() then
                if not WinFrame.Visible then openWindow() end
            end
        end)
    end

    -- ================================================================
    -- TAB SYSTEM
    -- ================================================================
    local activeBtn    = nil
    local activeStroke = nil
    local allPages     = {}
    local tabOrder     = 0
    local tabRegistry  = {}

    -- ================================================================
    -- WINDOW OBJECT
    -- ================================================================
    local WindowObj = {}
    WindowObj._tagBar = TagBar

    -- ── _addTag ──────────────────────────────────────────────────
    function WindowObj:_addTag(cfg)
        local tagType  = cfg.Type  or "Version"
        local tagValue = cfg.Value or ""

        local icons = {
            Version = "◈",
            Discord = "💬",
            Github  = "⌥",
        }
        local iconChar = icons[tagType] or "•"

        local chip = Instance.new("Frame", TagBar)
        chip.BackgroundColor3 = SURFACE
        chip.BackgroundTransparency = 0.1
        chip.BorderSizePixel  = 0
        chip.AutomaticSize    = Enum.AutomaticSize.X
        chip.Size             = UDim2.new(0, 0, 0, 18)
        chip.ZIndex           = 3
        corner(5, chip)
        stroke(1, BORDER, chip)

        local chipLayout = Instance.new("UIListLayout", chip)
        chipLayout.FillDirection        = Enum.FillDirection.Horizontal
        chipLayout.VerticalAlignment    = Enum.VerticalAlignment.Center
        chipLayout.Padding              = UDim.new(0, 3)
        local chipPad = Instance.new("UIPadding", chip)
        chipPad.PaddingLeft  = UDim.new(0, 5)
        chipPad.PaddingRight = UDim.new(0, 5)

        local iconLbl = Instance.new("TextLabel", chip)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text     = iconChar
        iconLbl.TextColor3 = SILVER_DIM
        iconLbl.TextSize = 10
        iconLbl.FontFace = BODY_FONT
        iconLbl.Size     = UDim2.new(0, 11, 1, 0)
        iconLbl.ZIndex   = 4
        iconLbl.AutomaticSize = Enum.AutomaticSize.X

        local valLbl = Instance.new("TextLabel", chip)
        valLbl.BackgroundTransparency = 1
        valLbl.Text     = tagValue
        valLbl.TextColor3 = SILVER_DIM
        valLbl.TextSize = 10
        valLbl.FontFace = BODY_FONT
        valLbl.Size     = UDim2.new(0, 0, 1, 0)
        valLbl.ZIndex   = 4
        valLbl.AutomaticSize = Enum.AutomaticSize.X

        -- Click to copy value
        local clickable = Instance.new("TextButton", chip)
        clickable.Size               = UDim2.new(1, 0, 1, 0)
        clickable.BackgroundTransparency = 1
        clickable.Text               = ""
        clickable.ZIndex             = 5
        clickable.AutomaticSize      = Enum.AutomaticSize.X
        clickable.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(tagValue) end)
            local orig = valLbl.Text
            valLbl.Text = "Copied!"
            task.delay(1.5, function()
                if valLbl.Parent then valLbl.Text = orig end
            end)
        end)

        return chip
    end

    -- ── _addTab ──────────────────────────────────────────────────
    function WindowObj:_addTab(cfg)
        tabOrder = tabOrder + 1
        local tabTitle = cfg.Title or ("Tab " .. tabOrder)

        local btn = Instance.new("TextButton", Sidebar)
        btn.Name             = tabTitle .. "_Tab"
        btn.Size             = UDim2.new(1, 0, 0, 44)
        btn.BackgroundColor3 = SURFACE
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel  = 0
        btn.Text             = tabTitle
        btn.TextColor3       = DIM_TEXT
        btn.TextSize         = 13
        btn.FontFace         = TITLE_FONT
        btn.AutoButtonColor  = false
        btn.LayoutOrder      = tabOrder
        corner(8, btn)
        local s = stroke(1, BORDER, btn)

        local page = Instance.new("ScrollingFrame", ContentArea)
        page.Name                 = tabTitle .. "_Page"
        page.Size                 = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel      = 0
        page.ScrollBarThickness   = 3
        page.ScrollBarImageColor3 = BORDER
        page.AutomaticCanvasSize  = Enum.AutomaticSize.Y
        page.CanvasSize           = UDim2.new(0, 0, 0, 0)
        page.Visible              = false

        local lay = Instance.new("UIListLayout", page)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding   = UDim.new(0, 6)

        local pad = Instance.new("UIPadding", page)
        pad.PaddingTop    = UDim.new(0, 10)
        pad.PaddingLeft   = UDim.new(0, 10)
        pad.PaddingRight  = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 10)

        table.insert(allPages, page)

        local function activate()
            if activeBtn then
                tw(activeBtn, 0.15, {BackgroundTransparency = 0.3, TextColor3 = DIM_TEXT})
                if activeStroke then tw(activeStroke, 0.15, {Color = BORDER}) end
            end
            for _, p in ipairs(allPages) do p.Visible = false end
            tw(btn, 0.15, {BackgroundTransparency = 0, TextColor3 = WHITE_TEXT})
            tw(s,   0.15, {Color = SILVER})
            page.Visible = true
            activeBtn    = btn
            activeStroke = s
            -- Update the active tab name pill
            TabNameLabel.Text = tabTitle
        end

        btn.MouseButton1Click:Connect(activate)
        btn.MouseEnter:Connect(function()
            if activeBtn ~= btn then
                tw(btn, 0.12, {BackgroundTransparency = 0.1, TextColor3 = SILVER})
            end
        end)
        btn.MouseLeave:Connect(function()
            if activeBtn ~= btn then
                tw(btn, 0.12, {BackgroundTransparency = 0.3, TextColor3 = DIM_TEXT})
            end
        end)

        tabRegistry[tabTitle] = { btn = btn, page = page, activate = activate }
        if activeBtn == nil then activate() end

        -- ── TAB OBJECT ──────────────────────────────────────────
        local TabObj  = {}
        TabObj._page  = page

        -- Internal component adders

        function TabObj:_addSection(cfg)
            local text = cfg.Title or cfg.Text or cfg[1] or ""
            local sep = Instance.new("Frame", page)
            sep.Size               = UDim2.new(1, 0, 0, 20)
            sep.BackgroundTransparency = 1
            sep.BorderSizePixel    = 0

            local line = Instance.new("Frame", sep)
            line.Size             = UDim2.new(1, 0, 0, 1)
            line.Position         = UDim2.new(0, 0, 0.5, 0)
            line.BackgroundColor3 = BORDER
            line.BorderSizePixel  = 0

            local hdr = Instance.new("TextLabel", sep)
            hdr.Size             = UDim2.new(0, 80, 1, 0)
            hdr.Position         = UDim2.new(0, 6, 0, 0)
            hdr.BackgroundColor3 = BLACK
            hdr.BorderSizePixel  = 0
            hdr.Text             = "  " .. text .. "  "
            hdr.TextColor3       = SILVER_DIM
            hdr.TextSize         = 11
            hdr.FontFace         = TITLE_FONT
            hdr.TextXAlignment   = Enum.TextXAlignment.Left
            hdr.AutomaticSize    = Enum.AutomaticSize.X
        end

        function TabObj:_addParagraph(cfg)
            local text = cfg.Content or cfg.Text or ""
            local f = Instance.new("Frame", page)
            f.Size             = UDim2.new(1, 0, 0, 0)
            f.AutomaticSize    = Enum.AutomaticSize.Y
            f.BackgroundColor3 = SURFACE
            f.BackgroundTransparency = 0.2
            f.BorderSizePixel  = 0
            corner(7, f)
            stroke(1, BORDER, f)

            local lbl = Instance.new("TextLabel", f)
            lbl.Size               = UDim2.new(1, -20, 0, 0)
            lbl.Position           = UDim2.new(0, 10, 0, 8)
            lbl.AutomaticSize      = Enum.AutomaticSize.Y
            lbl.BackgroundTransparency = 1
            lbl.Text               = text
            lbl.TextColor3         = DIM_TEXT
            lbl.TextSize           = 12
            lbl.FontFace           = BODY_FONT
            lbl.TextXAlignment     = Enum.TextXAlignment.Left
            lbl.TextWrapped        = true

            local pad = Instance.new("UIPadding", f)
            pad.PaddingBottom = UDim.new(0, 8)
            return f
        end

        function TabObj:_addButton(cfg)
            local text     = cfg.Title or cfg.Text or "Button"
            local callback = cfg.Logic or cfg.Callback or function() end

            local btn2 = Instance.new("TextButton", page)
            btn2.Size             = UDim2.new(1, 0, 0, 34)
            btn2.BackgroundColor3 = SURFACE
            btn2.BackgroundTransparency = 0
            btn2.BorderSizePixel  = 0
            btn2.Text             = text
            btn2.TextColor3       = WHITE_TEXT
            btn2.TextSize         = 13
            btn2.FontFace         = BODY_FONT
            btn2.AutoButtonColor  = false
            corner(7, btn2)
            stroke(1, BORDER, btn2)

            btn2.MouseEnter:Connect(function()
                tw(btn2, 0.1, {BackgroundColor3 = Color3.fromRGB(28, 28, 36), TextColor3 = SILVER})
            end)
            btn2.MouseLeave:Connect(function()
                tw(btn2, 0.1, {BackgroundColor3 = SURFACE, TextColor3 = WHITE_TEXT})
            end)
            btn2.MouseButton1Click:Connect(function()
                tw(btn2, 0.07, {BackgroundColor3 = Color3.fromRGB(40, 42, 52)})
                task.wait(0.07)
                tw(btn2, 0.1, {BackgroundColor3 = SURFACE})
                callback()
            end)

            local obj = { _frame = btn2 }
            return obj
        end

        function TabObj:_addToggle(cfg)
            local text     = cfg.Title   or cfg.Text or "Toggle"
            local default  = cfg.Default or false
            local callback = cfg.Logic   or cfg.Callback or function() end

            local row = Instance.new("Frame", page)
            row.Size             = UDim2.new(1, 0, 0, 34)
            row.BackgroundColor3 = SURFACE
            row.BackgroundTransparency = 0
            row.BorderSizePixel  = 0
            corner(7, row)
            stroke(1, BORDER, row)

            local lbl2 = Instance.new("TextLabel", row)
            lbl2.Size               = UDim2.new(0.65, 0, 1, 0)
            lbl2.Position           = UDim2.new(0, 10, 0, 0)
            lbl2.BackgroundTransparency = 1
            lbl2.BorderSizePixel    = 0
            lbl2.Text               = text
            lbl2.TextColor3         = WHITE_TEXT
            lbl2.TextSize           = 13
            lbl2.FontFace           = BODY_FONT
            lbl2.TextXAlignment     = Enum.TextXAlignment.Left

            local track = Instance.new("Frame", row)
            track.Size             = UDim2.new(0, 44, 0, 20)
            track.Position         = UDim2.new(1, -54, 0.5, -10)
            track.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
            track.BorderSizePixel  = 0
            corner(99, track)

            local thumb = Instance.new("Frame", track)
            thumb.Size             = UDim2.new(0, 14, 0, 14)
            thumb.BackgroundColor3 = SILVER_DIM
            thumb.BorderSizePixel  = 0
            corner(99, thumb)

            local state = default

            local function setVisual(s, skipCb)
                state = s
                if state then
                    tw(track, 0.2, {BackgroundColor3 = Color3.fromRGB(35, 40, 55)})
                    tw(thumb, 0.2, {Position = UDim2.new(1, -17, 0.5, -7), BackgroundColor3 = SILVER})
                else
                    tw(track, 0.2, {BackgroundColor3 = Color3.fromRGB(22, 22, 30)})
                    tw(thumb, 0.2, {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = SILVER_DIM})
                end
                if not skipCb then callback(state) end
            end

            -- Apply initial state
            if state then
                thumb.Position         = UDim2.new(1, -17, 0.5, -7)
                thumb.BackgroundColor3 = SILVER
                track.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            else
                thumb.Position = UDim2.new(0, 3, 0.5, -7)
            end

            local click = Instance.new("TextButton", row)
            click.Size               = UDim2.new(1, 0, 1, 0)
            click.BackgroundTransparency = 1
            click.Text               = ""
            click.BorderSizePixel    = 0
            click.MouseButton1Click:Connect(function()
                setVisual(not state)
            end)

            local obj = { _frame = row, SetState = setVisual }
            return obj
        end

        function TabObj:_addSlider(cfg)
            local text     = cfg.Title   or cfg.Text or "Slider"
            local minVal   = tonumber(cfg.Min)     or 0
            local maxVal   = tonumber(cfg.Max)     or 100
            local default  = tonumber(cfg.Default) or minVal
            local isFloat  = cfg.Float   or false
            local callback = cfg.Logic   or cfg.Callback or function() end
            default = math.clamp(default, minVal, maxVal)

            local row = Instance.new("Frame", page)
            row.Size             = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = SURFACE
            row.BackgroundTransparency = 0
            row.BorderSizePixel  = 0
            corner(7, row)
            stroke(1, BORDER, row)

            local lbl3 = Instance.new("TextLabel", row)
            lbl3.Size               = UDim2.new(0.65, 0, 0, 20)
            lbl3.Position           = UDim2.new(0, 10, 0, 6)
            lbl3.BackgroundTransparency = 1
            lbl3.Text               = text
            lbl3.TextColor3         = WHITE_TEXT
            lbl3.TextSize           = 13
            lbl3.FontFace           = BODY_FONT
            lbl3.TextXAlignment     = Enum.TextXAlignment.Left

            local valLbl = Instance.new("TextLabel", row)
            valLbl.Size               = UDim2.new(0.3, 0, 0, 20)
            valLbl.Position           = UDim2.new(0.68, 0, 0, 6)
            valLbl.BackgroundTransparency = 1
            valLbl.Text               = tostring(default)
            valLbl.TextColor3         = SILVER
            valLbl.TextSize           = 12
            valLbl.FontFace           = BODY_FONT
            valLbl.TextXAlignment     = Enum.TextXAlignment.Right

            local track = Instance.new("Frame", row)
            track.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            track.BorderSizePixel  = 0
            track.Size             = UDim2.new(1, -20, 0, 5)
            track.Position         = UDim2.new(0, 10, 0, 34)
            corner(99, track)

            local pct0 = (default - minVal) / math.max(maxVal - minVal, 0.001)

            local fill = Instance.new("Frame", track)
            fill.Size             = UDim2.new(pct0, 0, 1, 0)
            fill.BackgroundColor3 = SILVER
            fill.BorderSizePixel  = 0
            corner(99, fill)

            local thumb = Instance.new("Frame", track)
            thumb.Size             = UDim2.new(0, 13, 0, 13)
            thumb.Position         = UDim2.new(pct0, -6, 0.5, -6)
            thumb.BackgroundColor3 = WHITE_TEXT
            thumb.BorderSizePixel  = 0
            corner(99, thumb)

            local dragging2 = false
            local curVal    = default

            local function applyRel(rel)
                rel = math.clamp(rel, 0, 1)
                fill.Size      = UDim2.new(rel, 0, 1, 0)
                thumb.Position = UDim2.new(rel, -6, 0.5, -6)
                local v = minVal + (maxVal - minVal) * rel
                v = isFloat and (math.floor(v * 100) / 100) or math.floor(v)
                curVal        = v
                valLbl.Text   = tostring(v)
                callback(v)
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging2 = true
                    applyRel((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
                end
            end)
            thumb.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging2 = true
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if not dragging2 then return end
                if i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch then
                    applyRel((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging2 = false
                end
            end)

            local function setVal(v)
                v = math.clamp(v, minVal, maxVal)
                curVal = v
                valLbl.Text = tostring(v)
                local rel = (v - minVal) / math.max(maxVal - minVal, 0.001)
                fill.Size      = UDim2.new(rel, 0, 1, 0)
                thumb.Position = UDim2.new(rel, -6, 0.5, -6)
            end

            local obj = { _frame = row, SetValue = setVal }
            return obj
        end

        function TabObj:_addDropdown(cfg)
            local text     = cfg.Title   or cfg.Text or "Dropdown"
            local options  = cfg.Options or {}
            local callback = cfg.Logic   or cfg.Callback or function() end
            local selected = options[1]  or "Select..."
            local open     = false

            local container = Instance.new("Frame", page)
            container.Size               = UDim2.new(1, 0, 0, 34)
            container.BackgroundTransparency = 1
            container.BorderSizePixel    = 0
            container.ClipsDescendants   = false

            local header = Instance.new("TextButton", container)
            header.Size             = UDim2.new(1, 0, 0, 34)
            header.BackgroundColor3 = SURFACE
            header.BackgroundTransparency = 0
            header.BorderSizePixel  = 0
            header.Text             = text .. ":  " .. selected .. "  ▾"
            header.TextColor3       = WHITE_TEXT
            header.TextSize         = 13
            header.FontFace         = BODY_FONT
            header.AutoButtonColor  = false
            corner(7, header)
            stroke(1, BORDER, header)

            local panel = Instance.new("Frame", container)
            panel.BackgroundColor3 = PANEL
            panel.BorderSizePixel  = 0
            panel.Size             = UDim2.new(1, 0, 0, #options * 30)
            panel.Position         = UDim2.new(0, 0, 0, 37)
            panel.Visible          = false
            panel.ZIndex           = 20
            panel.ClipsDescendants = true
            corner(7, panel)
            stroke(1, BORDER, panel)

            local pLayout = Instance.new("UIListLayout", panel)
            pLayout.SortOrder = Enum.SortOrder.LayoutOrder

            for _, opt in ipairs(options) do
                local ob = Instance.new("TextButton", panel)
                ob.Size             = UDim2.new(1, 0, 0, 30)
                ob.BackgroundColor3 = PANEL
                ob.BackgroundTransparency = 0
                ob.BorderSizePixel  = 0
                ob.Text             = opt
                ob.TextColor3       = DIM_TEXT
                ob.TextSize         = 12
                ob.FontFace         = BODY_FONT
                ob.AutoButtonColor  = false
                ob.ZIndex           = 21
                ob.MouseEnter:Connect(function()
                    tw(ob, 0.1, {BackgroundColor3 = SURFACE, TextColor3 = WHITE_TEXT})
                end)
                ob.MouseLeave:Connect(function()
                    tw(ob, 0.1, {BackgroundColor3 = PANEL, TextColor3 = DIM_TEXT})
                end)
                ob.MouseButton1Click:Connect(function()
                    selected    = opt
                    header.Text = text .. ":  " .. opt .. "  ▾"
                    open        = false
                    panel.Visible = false
                    container.Size = UDim2.new(1, 0, 0, 34)
                    callback(opt)
                end)
            end

            header.MouseButton1Click:Connect(function()
                open = not open
                panel.Visible  = open
                container.Size = open
                    and UDim2.new(1, 0, 0, 34 + #options * 30 + 4)
                    or  UDim2.new(1, 0, 0, 34)
            end)

            local obj = { _frame = container }
            return obj
        end

        return TabObj
    end

    -- ── Window methods ───────────────────────────────────────────

    function WindowObj:SelectTab(name)
        local e = tabRegistry[name]
        if e then e.activate() end
    end

    function WindowObj:SetTitle(t)
        TitleLabel.Text = t
    end

    function WindowObj:SetVersion(v)
        VerLabel.Text = v
    end

    function WindowObj:Open()
        openWindow()
    end

    function WindowObj:Close()
        closeWindow()
    end

    function WindowObj:Destroy()
        sg:Destroy()
    end

    return WindowObj
end

    return WindowObj
end -- closes _createWindow body
end -- closes Nexus:_createWindow
end
end
end
end
end
end
end

return Nexus