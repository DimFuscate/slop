local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Config
local ACCENT = Color3.fromRGB(160, 73, 255)
local BG = Color3.fromRGB(15, 15, 15)
local TPWalkEnabled = false
local TPWalkSpeed = 1
local ChamsEnabled = false

-- UI Root
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Zyphera_Final_Attempt"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- MAIN WINDOW (Created first so it's behind the button logic)
local Window = Instance.new("Frame")
Window.Name = "Main"
Window.Size = UDim2.new(0, 200, 0, 220)
Window.Position = UDim2.new(0.5, -100, 0.2, 0)
Window.BackgroundColor3 = BG
Window.Visible = false
Window.ClipsDescendants = true
Window.Parent = ScreenGui

Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 10)
local winStroke = Instance.new("UIStroke", Window)
winStroke.Color = ACCENT
winStroke.Thickness = 2

local Layout = Instance.new("UIListLayout", Window)
Layout.Padding = UDim.new(0, 10)
Layout.HorizontalAlignment = "Center"
Instance.new("UIPadding", Window).PaddingTop = UDim.new(0, 10)

-- FLOATING BUTTON (The Trigger)
local FloatingBtn = Instance.new("TextButton") -- Changed to TextButton for direct click detection
FloatingBtn.Name = "Trigger"
FloatingBtn.Size = UDim2.new(0, 150, 0, 45)
FloatingBtn.Position = UDim2.new(0.5, -75, 0.05, 0)
FloatingBtn.BackgroundColor3 = Color3.new(0, 0, 0)
FloatingBtn.BackgroundTransparency = 0.2
FloatingBtn.Text = "ZYPHERA HUB"
FloatingBtn.TextColor3 = ACCENT
FloatingBtn.Font = Enum.Font.TitilliumWeb
FloatingBtn.TextSize = 18
FloatingBtn.AutoButtonColor = false -- Prevents annoying gray flicker
FloatingBtn.Parent = ScreenGui

Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(0, 12)
local floatStroke = Instance.new("UIStroke", FloatingBtn)
floatStroke.Color = ACCENT
floatStroke.Thickness = 2

-- SIMPLE TOGGLE LOGIC (No complex raycasting, just a direct click)
FloatingBtn.MouseButton1Click:Connect(function()
    Window.Visible = not Window.Visible
    
    -- Fast Animation
    if Window.Visible then
        Window.Size = UDim2.new(0, 200, 0, 0)
        Window:TweenSize(UDim2.new(0, 200, 0, 220), "Out", "Back", 0.3, true)
    end
end)

-- MAKE IT DRAGGABLE
local dragging, dragInput, dragStart, startPos
FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = FloatingBtn.Position
    end
end)
FloatingBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        FloatingBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
FloatingBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-----------------------------------------------------------
-- BUTTONS & BOXES
-----------------------------------------------------------

local function CreateToggle(name, callback)
    local btn = Instance.new("TextButton", Window)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    btn.Font = Enum.Font.TitilliumWeb
    Instance.new("UICorner", btn)

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.Text = name .. (active and ": ON" or ": OFF")
        btn.TextColor3 = active and ACCENT or Color3.new(0.8, 0.8, 0.8)
        callback(active)
    end)
end

-- TP Adjuster (InputBox)
local SpeedInput = Instance.new("TextBox", Window)
SpeedInput.Size = UDim2.new(0.9, 0, 0, 35)
SpeedInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SpeedInput.Text = "1"
SpeedInput.PlaceholderText = "Speed (1-5)"
SpeedInput.TextColor3 = ACCENT
SpeedInput.Font = Enum.Font.TitilliumWeb
Instance.new("UICorner", SpeedInput)

SpeedInput.FocusLost:Connect(function()
    local val = tonumber(SpeedInput.Text)
    if val then 
        TPWalkSpeed = math.clamp(val, 0, 5) 
    end
    SpeedInput.Text = tostring(TPWalkSpeed)
end)

-----------------------------------------------------------
-- GAME LOGIC (LOCKED TO HEARTBEAT)
-----------------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
    -- TP Walk Logic
    if TPWalkEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then
            char:TranslateBy(hum.MoveDirection * TPWalkSpeed * dt * 10)
        end
    end

    -- Chams Logic (HumanoidRootPart Box)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local ch = hrp:FindFirstChild("ZyCham")
                if ChamsEnabled then
                    if not ch then
                        ch = Instance.new("BoxHandleAdornment", hrp)
                        ch.Name = "ZyCham"
                        ch.Size = hrp.Size + Vector3.new(0.1, 0.1, 0.1)
                        ch.AlwaysOnTop = true
                        ch.ZIndex = 10
                        ch.Color3 = ACCENT
                        ch.Transparency = 0.5
                        ch.Adornee = hrp
                    end
                else
                    if ch then ch:Destroy() end
                end
            end
        end
    end
end)

CreateToggle("TP-Walk", function(v) TPWalkEnabled = v end)
CreateToggle("Chams", function(v) ChamsEnabled = v end)
