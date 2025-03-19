--------------------------------------------------------------------------------
--                           Mistral Hub by Zaky (Styled)                     --
--   Key Authentication -> Advanced UI -> Two Tabs -> Script Buttons, etc.    --
--------------------------------------------------------------------------------

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
--                              HELPER FUNCTIONS                              --
--------------------------------------------------------------------------------

-- Converts a string to an Enum.KeyCode (for toggle key changes).
local function convertToKeyCode(keyStr)
    keyStr = keyStr:lower()
    if keyStr == ";" then
        return Enum.KeyCode.Semicolon
    elseif #keyStr == 1 then
        local upperKey = keyStr:upper()
        return Enum.KeyCode[upperKey] or Enum.KeyCode.Unknown
    else
        -- If user tries something like "Space" or "LeftShift"
        local success, code = pcall(function() return Enum.KeyCode[keyStr] end)
        if success and code then
            return code
        end
    end
    return Enum.KeyCode.Unknown
end

--------------------------------------------------------------------------------
--                            CONFIGURATION VALUES                            --
--------------------------------------------------------------------------------

local validKey = "zakysigma"             -- Key for authentication
local defaultToggleKey = Enum.KeyCode.Semicolon  -- Default toggle key is ";"

--------------------------------------------------------------------------------
--                          1) AUTHENTICATION UI                              --
--------------------------------------------------------------------------------

local AuthUI = Instance.new("ScreenGui")
AuthUI.Name = "AuthUI"
AuthUI.ResetOnSpawn = false
AuthUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
AuthUI.Parent = PlayerGui

local AuthFrame = Instance.new("Frame")
AuthFrame.Name = "AuthFrame"
AuthFrame.Size = UDim2.new(0, 300, 0, 150)
AuthFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
AuthFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AuthFrame.BackgroundTransparency = 0.1
AuthFrame.BorderSizePixel = 0
AuthFrame.Parent = AuthUI

local AuthUICorner = Instance.new("UICorner")
AuthUICorner.CornerRadius = UDim.new(0, 5)
AuthUICorner.Parent = AuthFrame

-- (Optional) Outline stroke for the AuthFrame to mimic that "box" style
local AuthStroke = Instance.new("UIStroke")
AuthStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
AuthStroke.Color = Color3.fromRGB(80, 80, 80)
AuthStroke.Thickness = 1
AuthStroke.Parent = AuthFrame

local AuthTitle = Instance.new("TextLabel")
AuthTitle.Name = "AuthTitle"
AuthTitle.Size = UDim2.new(1, 0, 0, 40)
AuthTitle.BackgroundTransparency = 1
AuthTitle.Text = "Enter Access Key"
AuthTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
AuthTitle.Font = Enum.Font.SourceSansBold
AuthTitle.TextSize = 24
AuthTitle.Parent = AuthFrame

local KeyBox = Instance.new("TextBox")
KeyBox.Name = "KeyBox"
KeyBox.Size = UDim2.new(0.8, 0, 0, 30)
KeyBox.Position = UDim2.new(0.1, 0, 0, 50)
KeyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
KeyBox.BorderSizePixel = 0
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.PlaceholderText = "Enter key..."
KeyBox.Font = Enum.Font.SourceSans
KeyBox.TextSize = 18
KeyBox.ClearTextOnFocus = false
KeyBox.Parent = AuthFrame

local KeyBoxCorner = Instance.new("UICorner")
KeyBoxCorner.CornerRadius = UDim.new(0, 5)
KeyBoxCorner.Parent = KeyBox

local ConfirmButton = Instance.new("TextButton")
ConfirmButton.Name = "ConfirmButton"
ConfirmButton.Size = UDim2.new(0.8, 0, 0, 30)
ConfirmButton.Position = UDim2.new(0.1, 0, 0, 90)
ConfirmButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ConfirmButton.Text = "Confirm"
ConfirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmButton.Font = Enum.Font.SourceSansBold
ConfirmButton.TextSize = 18
ConfirmButton.Parent = AuthFrame

local ConfirmCorner = Instance.new("UICorner")
ConfirmCorner.CornerRadius = UDim.new(0, 5)
ConfirmCorner.Parent = ConfirmButton

local ErrorLabel = Instance.new("TextLabel")
ErrorLabel.Name = "ErrorLabel"
ErrorLabel.Size = UDim2.new(1, 0, 0, 20)
ErrorLabel.Position = UDim2.new(0, 0, 1, -20)
ErrorLabel.BackgroundTransparency = 1
ErrorLabel.Text = ""
ErrorLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
ErrorLabel.Font = Enum.Font.SourceSans
ErrorLabel.TextSize = 16
ErrorLabel.Parent = AuthFrame

--------------------------------------------------------------------------------
--                    2) CREATE MAIN UI (SIMILAR TO YOUR REFERENCE)           --
--------------------------------------------------------------------------------

local function createMainUI()
    local WindowUI = Instance.new("ScreenGui")
    WindowUI.Name = "WindowUI"
    WindowUI.ResetOnSpawn = false
    WindowUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
    WindowUI.Parent = PlayerGui

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -175)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.Active = true
    MainFrame.Parent = WindowUI

    local MainFrameCorner = Instance.new("UICorner")
    MainFrameCorner.CornerRadius = UDim.new(0, 4)
    MainFrameCorner.Parent = MainFrame

    -- Subtle Outline
    local MainFrameStroke = Instance.new("UIStroke")
    MainFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainFrameStroke.Color = Color3.fromRGB(80, 80, 80)
    MainFrameStroke.Thickness = 1
    MainFrameStroke.Parent = MainFrame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleBarStroke = Instance.new("UIStroke")
    TitleBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    TitleBarStroke.Color = Color3.fromRGB(80, 80, 80)
    TitleBarStroke.Thickness = 1
    TitleBarStroke.Parent = TitleBar

    -- Draggable logic
    local dragging = false
    local dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Title Text (Top Left)
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(0, 250, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.Text = "Mistral Hub by Zaky"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 18
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 50, 1, 0)
    CloseButton.Position = UDim2.new(1, -50, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.TextSize = 20
    CloseButton.Parent = TitleBar

    CloseButton.MouseButton1Click:Connect(function()
        WindowUI:Destroy()
    end)

    -- Minimize Button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Name = "MinimizeButton"
    MinimizeButton.Size = UDim2.new(0, 50, 1, 0)
    MinimizeButton.Position = UDim2.new(1, -100, 0, 0)
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.Text = "-"
    MinimizeButton.TextColor3 = Color3.fromRGB(100, 100, 255)
    MinimizeButton.Font = Enum.Font.SourceSansBold
    MinimizeButton.TextSize = 20
    MinimizeButton.Parent = TitleBar

    -- Resize Button
    local ResizeButton = Instance.new("TextButton")
    ResizeButton.Name = "ResizeButton"
    ResizeButton.Size = UDim2.new(0, 50, 1, 0)
    ResizeButton.Position = UDim2.new(1, -150, 0, 0)
    ResizeButton.BackgroundTransparency = 1
    ResizeButton.Text = "◩"
    ResizeButton.TextColor3 = Color3.fromRGB(100, 255, 100)
    ResizeButton.Font = Enum.Font.SourceSansBold
    ResizeButton.TextSize = 20
    ResizeButton.Parent = TitleBar

    -- Resizing logic
    local resizing = false
    local resizeStart, startSize

    ResizeButton.MouseButton1Down:Connect(function()
        resizing = true
        resizeStart = UserInputService:GetMouseLocation()
        startSize = MainFrame.Size
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = UserInputService:GetMouseLocation() - resizeStart
            local newWidth = math.clamp(startSize.X.Offset + delta.X, 400, 900)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 200, 600)
            MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)

    -- Content Frame (below the title bar)
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -30)
    ContentFrame.Position = UDim2.new(0, 0, 0, 30)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    -- Minimize toggling
    local minimized = false
    local storedSize = MainFrame.Size
    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            ContentFrame.Visible = false
            storedSize = MainFrame.Size
            MainFrame:TweenSize(UDim2.new(0, storedSize.X.Offset, 0, 30), "Out", "Quad", 0.3, true)
        else
            ContentFrame.Visible = true
            MainFrame:TweenSize(storedSize, "Out", "Quad", 0.3, true)
        end
    end)

    ----------------------------------------------------------------------------
    --                          NOTIFICATIONS CONTAINER                        --
    ----------------------------------------------------------------------------

    local NotificationContainer = Instance.new("Frame")
    NotificationContainer.Name = "NotificationContainer"
    NotificationContainer.Size = UDim2.new(0, 300, 0, 200)
    NotificationContainer.AnchorPoint = Vector2.new(0, 1)
    NotificationContainer.Position = UDim2.new(0, 10, 1, -10)
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.Parent = WindowUI

    local NotificationLayout = Instance.new("UIListLayout")
    NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotificationLayout.Padding = UDim.new(0, 5)
    NotificationLayout.Parent = NotificationContainer

    local function AddNotification(message, nType)
        local notifyFrame = Instance.new("Frame")
        notifyFrame.Size = UDim2.new(1, 0, 0, 40)
        notifyFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        notifyFrame.BackgroundTransparency = 0.2
        notifyFrame.BorderSizePixel = 0
        notifyFrame.Parent = NotificationContainer

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = notifyFrame

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.fromRGB(100, 100, 100)
        stroke.Thickness = 1
        stroke.Parent = notifyFrame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 1, 0)
        label.Position = UDim2.new(0, 5, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = message
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.SourceSans
        label.TextSize = 16
        label.TextWrapped = true
        label.Parent = notifyFrame

        if nType == "success" then
            label.TextColor3 = Color3.fromRGB(100, 255, 100)
        elseif nType == "warning" then
            label.TextColor3 = Color3.fromRGB(255, 255, 100)
        elseif nType == "error" then
            label.TextColor3 = Color3.fromRGB(255, 100, 100)
        end

        local showTween = TweenService:Create(notifyFrame, TweenInfo.new(0.4), {BackgroundTransparency = 0.2})
        showTween:Play()

        delay(3, function()
            local hideTween = TweenService:Create(notifyFrame, TweenInfo.new(0.4), {
                BackgroundTransparency = 1, 
                Position = notifyFrame.Position - UDim2.new(0, 0, 0, 10)
            })
            hideTween:Play()
            hideTween.Completed:Connect(function()
                notifyFrame:Destroy()
            end)
        end)
    end

    ----------------------------------------------------------------------------
    --                          TABS: Main & UI Settings                       --
    ----------------------------------------------------------------------------

    -- Top-level container for tabs
    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Size = UDim2.new(1, 0, 0, 30)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.Parent = ContentFrame

    local TabButtonsLayout = Instance.new("UIListLayout")
    TabButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
    TabButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabButtonsLayout.Padding = UDim.new(0, 10)
    TabButtonsLayout.Parent = TabsContainer

    -- We'll create two text buttons for the two tabs: Main & UI Settings
    local function createTabButton(name, text)
        local btn = Instance.new("TextButton")
        btn.Name = name .. "TabButton"
        btn.Size = UDim2.new(0, 120, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.BackgroundTransparency = 0.1
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 16

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.fromRGB(80, 80, 80)
        stroke.Thickness = 1
        stroke.Parent = btn

        return btn
    end

    local MainTabButton = createTabButton("Main", "Main")
    MainTabButton.Parent = TabsContainer

    local SettingsTabButton = createTabButton("Settings", "UI Settings")
    SettingsTabButton.Parent = TabsContainer

    -- Container that holds the actual content of each tab
    local TabsContentFrame = Instance.new("Frame")
    TabsContentFrame.Name = "TabsContentFrame"
    TabsContentFrame.Size = UDim2.new(1, 0, 1, -30)
    TabsContentFrame.Position = UDim2.new(0, 0, 0, 30)
    TabsContentFrame.BackgroundTransparency = 1
    TabsContentFrame.Parent = ContentFrame

    -- Main Tab
    local MainTab = Instance.new("Frame")
    MainTab.Name = "MainTab"
    MainTab.Size = UDim2.new(1, 0, 1, 0)
    MainTab.BackgroundTransparency = 1
    MainTab.Parent = TabsContentFrame

    -- We'll create a left "GroupBox" for scripts, right "GroupBox" for something else
    local MainTabLeft = Instance.new("Frame")
    MainTabLeft.Name = "MainTabLeft"
    MainTabLeft.Size = UDim2.new(0.5, -5, 1, 0)
    MainTabLeft.Position = UDim2.new(0, 0, 0, 0)
    MainTabLeft.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MainTabLeft.BackgroundTransparency = 0.05
    MainTabLeft.BorderSizePixel = 0
    MainTabLeft.Parent = MainTab

    local LeftCorner = Instance.new("UICorner")
    LeftCorner.CornerRadius = UDim.new(0, 4)
    LeftCorner.Parent = MainTabLeft

    local LeftStroke = Instance.new("UIStroke")
    LeftStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    LeftStroke.Color = Color3.fromRGB(80, 80, 80)
    LeftStroke.Thickness = 1
    LeftStroke.Parent = MainTabLeft

    local LeftLabel = Instance.new("TextLabel")
    LeftLabel.Name = "LeftLabel"
    LeftLabel.Size = UDim2.new(1, 0, 0, 25)
    LeftLabel.BackgroundTransparency = 1
    LeftLabel.Text = "Script Buttons"
    LeftLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    LeftLabel.Font = Enum.Font.SourceSansBold
    LeftLabel.TextSize = 16
    LeftLabel.Parent = MainTabLeft

    local ScrollingScripts = Instance.new("ScrollingFrame")
    ScrollingScripts.Name = "ScrollingScripts"
    ScrollingScripts.Size = UDim2.new(1, 0, 1, -25)
    ScrollingScripts.Position = UDim2.new(0, 0, 0, 25)
    ScrollingScripts.BackgroundTransparency = 1
    ScrollingScripts.ScrollBarThickness = 6
    ScrollingScripts.Parent = MainTabLeft

    local ScriptLayout = Instance.new("UIListLayout")
    ScriptLayout.Padding = UDim.new(0, 5)
    ScriptLayout.Parent = ScrollingScripts

    -- Right group box for demonstration (empty or add your own features)
    local MainTabRight = Instance.new("Frame")
    MainTabRight.Name = "MainTabRight"
    MainTabRight.Size = UDim2.new(0.5, -5, 1, 0)
    MainTabRight.Position = UDim2.new(0.5, 5, 0, 0)
    MainTabRight.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MainTabRight.BackgroundTransparency = 0.05
    MainTabRight.BorderSizePixel = 0
    MainTabRight.Parent = MainTab

    local RightCorner = Instance.new("UICorner")
    RightCorner.CornerRadius = UDim.new(0, 4)
    RightCorner.Parent = MainTabRight

    local RightStroke = Instance.new("UIStroke")
    RightStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    RightStroke.Color = Color3.fromRGB(80, 80, 80)
    RightStroke.Thickness = 1
    RightStroke.Parent = MainTabRight

    local RightLabel = Instance.new("TextLabel")
    RightLabel.Name = "RightLabel"
    RightLabel.Size = UDim2.new(1, 0, 0, 25)
    RightLabel.BackgroundTransparency = 1
    RightLabel.Text = "Other Features"
    RightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    RightLabel.Font = Enum.Font.SourceSansBold
    RightLabel.TextSize = 16
    RightLabel.Parent = MainTabRight

    -- Add your own placeholders or controls to the right group if needed
    -- e.g., "Full Bright", "Transparent Water", "Shark Chams" as in the example screenshot.

    -- Script Buttons (similar to your existing code)
    local scriptInfo = {
        { Name = "Auto-aim",      URL = "https://raw.githubusercontent.com/Kandaqy/scriptbot/refs/heads/main/autoaim.lua" },
        { Name = "Possessor",     URL = "https://raw.githubusercontent.com/Kandaqy/scriptbot/refs/heads/main/possessor.lua" },
        { Name = "Re-open Chat",  URL = "https://raw.githubusercontent.com/Kandaqy/scriptbot/refs/heads/main/reopen-chat.lua" },
        { Name = "Shader",  URL = "https://raw.githubusercontent.com/randomstring0/pshade-ultimate/refs/heads/main/src/cd.lua" },
        { Name = "Mirror",  URL = "https://raw.githubusercontent.com/Kandaqy/scriptbot/refs/heads/main/mirror.lua" },
        { Name = "Mirror",  URL = "https://raw.githubusercontent.com/Kandaqy/scriptbot/refs/heads/main/evaderespawn" },
        -- Add more here if desired
    }

    local function createScriptButton(name, url)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(1, -10, 0, 30)
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        button.BackgroundTransparency = 0.1
        button.BorderSizePixel = 0
        button.Text = name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.SourceSansBold
        button.TextSize = 16

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = button

        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.fromRGB(80, 80, 80)
        stroke.Thickness = 1
        stroke.Parent = button

        button.Parent = ScrollingScripts

        button.MouseButton1Click:Connect(function()
            local success, err = pcall(function()
                loadstring(game:HttpGet(url))()
            end)
            if success then
                AddNotification("Executed: "..name, "success")
            else
                AddNotification("Error running: "..name.."\n"..err, "error")
            end
        end)
    end

    for _, info in ipairs(scriptInfo) do
        createScriptButton(info.Name, info.URL)
    end

    -- Settings Tab
    local SettingsTab = Instance.new("Frame")
    SettingsTab.Name = "SettingsTab"
    SettingsTab.Size = UDim2.new(1, 0, 1, 0)
    SettingsTab.BackgroundTransparency = 1
    SettingsTab.Visible = false
    SettingsTab.Parent = TabsContentFrame

    -- We'll mimic a similar style: a single box or multiple boxes
    local SettingsGroup = Instance.new("Frame")
    SettingsGroup.Name = "SettingsGroup"
    SettingsGroup.Size = UDim2.new(1, 0, 1, 0)
    SettingsGroup.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    SettingsGroup.BackgroundTransparency = 0.05
    SettingsGroup.BorderSizePixel = 0
    SettingsGroup.Parent = SettingsTab

    local SettingsCorner = Instance.new("UICorner")
    SettingsCorner.CornerRadius = UDim.new(0, 4)
    SettingsCorner.Parent = SettingsGroup

    local SettingsStroke = Instance.new("UIStroke")
    SettingsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    SettingsStroke.Color = Color3.fromRGB(80, 80, 80)
    SettingsStroke.Thickness = 1
    SettingsStroke.Parent = SettingsGroup

    local SettingsLabel = Instance.new("TextLabel")
    SettingsLabel.Size = UDim2.new(1, 0, 0, 30)
    SettingsLabel.BackgroundTransparency = 1
    SettingsLabel.Text = "UI Settings"
    SettingsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SettingsLabel.Font = Enum.Font.SourceSansBold
    SettingsLabel.TextSize = 18
    SettingsLabel.Parent = SettingsGroup

    -- We'll place the settings in a scrolling frame
    local SettingsScroll = Instance.new("ScrollingFrame")
    SettingsScroll.Name = "SettingsScroll"
    SettingsScroll.Size = UDim2.new(1, 0, 1, -30)
    SettingsScroll.Position = UDim2.new(0, 0, 0, 30)
    SettingsScroll.BackgroundTransparency = 1
    SettingsScroll.ScrollBarThickness = 6
    SettingsScroll.Parent = SettingsGroup

    local SettingsLayout = Instance.new("UIListLayout")
    SettingsLayout.Padding = UDim.new(0, 5)
    SettingsLayout.Parent = SettingsScroll

    -- Toggle Key Setting
    local ToggleKeyLabel = Instance.new("TextLabel")
    ToggleKeyLabel.Size = UDim2.new(1, -20, 0, 30)
    ToggleKeyLabel.BackgroundTransparency = 1
    ToggleKeyLabel.Text = "Toggle Keybind:"
    ToggleKeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleKeyLabel.Font = Enum.Font.SourceSansBold
    ToggleKeyLabel.TextSize = 18
    ToggleKeyLabel.Parent = SettingsScroll

    local ToggleKeyBox = Instance.new("TextBox")
    ToggleKeyBox.Size = UDim2.new(1, -20, 0, 30)
    ToggleKeyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ToggleKeyBox.BackgroundTransparency = 0.1
    ToggleKeyBox.BorderSizePixel = 0
    ToggleKeyBox.Text = ""
    ToggleKeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleKeyBox.PlaceholderText = "Current: ;"
    ToggleKeyBox.Font = Enum.Font.SourceSans
    ToggleKeyBox.TextSize = 16
    ToggleKeyBox.ClearTextOnFocus = false
    ToggleKeyBox.Parent = SettingsScroll

    local ToggleKeyCorner = Instance.new("UICorner")
    ToggleKeyCorner.CornerRadius = UDim.new(0, 4)
    ToggleKeyCorner.Parent = ToggleKeyBox

    local ToggleKeyStroke = Instance.new("UIStroke")
    ToggleKeyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ToggleKeyStroke.Color = Color3.fromRGB(80, 80, 80)
    ToggleKeyStroke.Thickness = 1
    ToggleKeyStroke.Parent = ToggleKeyBox

    local currentToggleKey = defaultToggleKey

    ToggleKeyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local text = ToggleKeyBox.Text
            if #text > 0 then
                local newKey = convertToKeyCode(text)
                if newKey ~= Enum.KeyCode.Unknown then
                    currentToggleKey = newKey
                    AddNotification("Toggle key changed to '"..tostring(newKey).."'", "success")
                    ToggleKeyBox.PlaceholderText = "Current: "..tostring(newKey)
                else
                    AddNotification("Invalid key.", "error")
                end
                ToggleKeyBox.Text = ""
            end
        end
    end)

    -- Opacity Setting
    local OpacityLabel = Instance.new("TextLabel")
    OpacityLabel.Size = UDim2.new(1, -20, 0, 30)
    OpacityLabel.BackgroundTransparency = 1
    OpacityLabel.Text = "UI Opacity (0 to 1):"
    OpacityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpacityLabel.Font = Enum.Font.SourceSansBold
    OpacityLabel.TextSize = 18
    OpacityLabel.Parent = SettingsScroll

    local OpacityBox = Instance.new("TextBox")
    OpacityBox.Size = UDim2.new(1, -20, 0, 30)
    OpacityBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    OpacityBox.BackgroundTransparency = 0.1
    OpacityBox.BorderSizePixel = 0
    OpacityBox.Text = ""
    OpacityBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpacityBox.PlaceholderText = "e.g., 0.2"
    OpacityBox.Font = Enum.Font.SourceSans
    OpacityBox.TextSize = 16
    OpacityBox.ClearTextOnFocus = false
    OpacityBox.Parent = SettingsScroll

    local OpacityCorner = Instance.new("UICorner")
    OpacityCorner.CornerRadius = UDim.new(0, 4)
    OpacityCorner.Parent = OpacityBox

    local OpacityStroke = Instance.new("UIStroke")
    OpacityStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    OpacityStroke.Color = Color3.fromRGB(80, 80, 80)
    OpacityStroke.Thickness = 1
    OpacityStroke.Parent = OpacityBox

    local function setUIOpacity(value)
        value = math.clamp(value, 0, 1)
        MainFrame.BackgroundTransparency = value
        TitleBar.BackgroundTransparency = math.clamp(value + 0.1, 0, 1)
    end

    OpacityBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(OpacityBox.Text)
            if num then
                setUIOpacity(num)
                AddNotification("Opacity set to "..num, "success")
            else
                AddNotification("Invalid opacity value.", "error")
            end
            OpacityBox.Text = ""
        end
    end)

    -- Tab switching
    local function showMainTab()
        MainTab.Visible = true
        SettingsTab.Visible = false
    end

    local function showSettingsTab()
        MainTab.Visible = false
        SettingsTab.Visible = true
    end

    MainTabButton.MouseButton1Click:Connect(showMainTab)
    SettingsTabButton.MouseButton1Click:Connect(showSettingsTab)

    showMainTab() -- default

    ----------------------------------------------------------------------------
    --                        TOGGLE KEY FUNCTIONALITY                         --
    ----------------------------------------------------------------------------

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == currentToggleKey then
            WindowUI.Enabled = not WindowUI.Enabled
        end
    end)
end

--------------------------------------------------------------------------------
--          3) AUTHENTICATION LOGIC -> DESTROY AUTH UI -> CREATE MAIN UI       --
--------------------------------------------------------------------------------

ConfirmButton.MouseButton1Click:Connect(function()
    local userKey = KeyBox.Text
    if userKey == validKey then
        ErrorLabel.Text = "Success!"
        wait(0.5)
        AuthUI:Destroy()
        createMainUI()
    else
        ErrorLabel.Text = "Invalid key. Try again."
    end
end)
