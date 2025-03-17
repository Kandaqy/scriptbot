local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Constants
local FRAME_SIZE = UDim2.new(0.3, 0, 0.1, 0)
local FRAME_POSITION = UDim2.new(0.35, 0, 0.05, 0)
local UPDATE_INTERVAL = 0.1 -- Seconds between updates
local TWEEN_SPEED = 0.3 -- Animation duration

-- UI Elements
local screenGui = Instance.new("ScreenGui")
local frame = Instance.new("Frame")
local textLabel = Instance.new("TextLabel")
local highlight = Instance.new("Highlight")

-- Variables
local isUIVisible = true
local isEnabled = true  -- New variable to track if the script is enabled
local lastUpdateTime = 0
local currentTarget = nil
local isDragging = false
local dragStart = nil
local startPos = nil

-- UI Setup Function
local function setupUI()
    screenGui.Name = "PlayerNameDisplay"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    frame.Name = "NameDisplayFrame"
    frame.Size = FRAME_SIZE
    frame.Position = FRAME_POSITION
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Visible = true
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.7
    stroke.Thickness = 2
    stroke.Parent = frame

    textLabel.Name = "PlayerNameLabel"
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = "Hover over a player"
    textLabel.Parent = frame

    highlight.Enabled = false
    highlight.FillColor = Color3.new(0, 0.5, 1)
    highlight.FillTransparency = 0.8
    highlight.OutlineColor = Color3.new(0, 0.5, 1)
    highlight.OutlineTransparency = 0
    highlight.Parent = workspace
end

-- UI Animation Functions
local function fadeUI(visible)
    local targetTransparency = visible and 0.5 or 1
    local tween = TweenService:Create(frame, TweenInfo.new(TWEEN_SPEED), 
        {BackgroundTransparency = targetTransparency})
    tween:Play()
end

-- Dragging Functions
local function updateDrag(input)
    if not isDragging then return end
    
    local delta = input.Position - dragStart
    local targetPosition = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
    
    local tween = TweenService:Create(frame, TweenInfo.new(0.1), 
        {Position = targetPosition})
    tween:Play()
end

local function setupDragging()
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag(input)
        end
    end)
end

-- Player Detection Function
local function updatePlayerName()
    if not isEnabled then return end  -- Add check for enabled state
    
    local now = tick()
    if now - lastUpdateTime < UPDATE_INTERVAL then return end
    lastUpdateTime = now

    local target = mouse.Target
    if not target then
        if currentTarget then
            textLabel.Text = "Hover over a player"
            highlight.Enabled = false
            currentTarget = nil
        end
        return
    end

    local character = target:FindFirstAncestorOfClass("Model")
    if not character then return end

    local targetPlayer = Players:GetPlayerFromCharacter(character)
    if not targetPlayer then return end

    if currentTarget ~= targetPlayer then
        currentTarget = targetPlayer
        textLabel.Text = targetPlayer.DisplayName
        highlight.Adornee = character
        highlight.Enabled = true
        
        local tween = TweenService:Create(highlight, TweenInfo.new(TWEEN_SPEED), 
            {FillTransparency = 0.8})
        tween:Play()
    end
end

-- Function to toggle the script
local function toggleScript()
    isEnabled = not isEnabled
    frame.Visible = isEnabled
    highlight.Enabled = false
    if not isEnabled then
        textLabel.Text = "Hover over a player"
        currentTarget = nil
    end
end

-- Initialize
setupUI()
setupDragging()

-- Event Connections
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then  -- Changed from M to T
        toggleScript()
    end
end)

RunService.RenderStepped:Connect(updatePlayerName)