--[[
    Enhanced Mirror Movement Script (Auto-Correct & FPS Camera)
    ------------------------------
    Features:
    - Smoother movement with interpolation and tweening
    - Multiple mirror modes: Mirror, Follow, and Face
    - Improved natural physics integration for jumps
    - Enhanced UI with better layout and status indicators
    - Auto-correction for both rotation and position glitches
    - Optional FPS camera mode for Mirror rotation: your camera is forced into FPS mode
    - Better error handling and teleport detection
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Constants and configuration
local MODES = {
    MIRROR = "Mirror", -- Mirror movements with left/right flipped
    FOLLOW = "Follow", -- Copy movements exactly (no mirroring)
    FACE = "Face"      -- Mirror while always facing the target
}

local CONFIG = {
    Mode = MODES.MIRROR,
    Distance = 5,               -- Distance from target (studs)
    SmoothFactor = 0.2,         -- Smoothing for position (0.1-0.5 recommended)
    PositionP = 3000,           -- BodyPosition responsiveness
    PositionD = 200,            -- BodyPosition damping
    GyroP = 3000,               -- BodyGyro responsiveness
    MaxForce = 1e5,             -- Maximum force for BodyMovers
    RotationSmoothSpeed = 15,   -- Higher values yield faster (more instant) rotation smoothing
    RotationErrorThreshold = 0.3,  -- In radians; if difference is above, force correction
    PositionErrorThreshold = 2,    -- In studs; if position error is above, force correction
}

-- State variables
local localPlayer = Players.LocalPlayer
local mirroringActive = false
local targetPlayer = nil
local targetCF0, myCF0 = nil, nil  -- Initial reference CFrames for relative transform
local wasJumping = false         -- For jump edge detection
local previousPos = nil          -- For velocity calculation
local mirrorConnection = nil
local bp, bg = nil, nil          -- BodyPosition and BodyGyro references

-- New variable for mirror rotation offset (in radians)
local mirrorOffsetAngle = nil

-- GUI elements
local screenGui, mainFrame, playerInput, mirrorButton, statusLabel

-------------------------------------------------
-- Create modern GUI with improved layout
-------------------------------------------------
local function CreateGUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MirrorMovementGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 240)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -120)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local cornerFix = Instance.new("Frame")
    cornerFix.Size = UDim2.new(1, 0, 0, 10)
    cornerFix.Position = UDim2.new(0, 0, 1, -10)
    cornerFix.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    cornerFix.BorderSizePixel = 0
    cornerFix.ZIndex = 0
    cornerFix.Parent = titleBar
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 80))
    })
    gradient.Rotation = 90
    gradient.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Mirror Movement"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 26, 0, 26)
    closeButton.Position = UDim2.new(1, -30, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 14
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Status Indicator
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Size = UDim2.new(0, 10, 0, 10)
    statusIndicator.Position = UDim2.new(0, 10, 0, 46)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(200, 60, 60) -- Red when inactive
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Parent = mainFrame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(1, 0)
    statusCorner.Parent = statusIndicator
    
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 200, 0, 20)
    statusLabel.Position = UDim2.new(0, 26, 0, 41)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Not Mirroring"
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(0, 120, 0, 20)
    playerLabel.Position = UDim2.new(0, 10, 0, 70)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = "Player Name:"
    playerLabel.TextColor3 = Color3.new(1, 1, 1)
    playerLabel.Font = Enum.Font.Gotham
    playerLabel.TextSize = 14
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.Parent = mainFrame
    
    playerInput = Instance.new("TextBox")
    playerInput.Size = UDim2.new(0, 330, 0, 30)
    playerInput.Position = UDim2.new(0, 10, 0, 90)
    playerInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    playerInput.BorderSizePixel = 0
    playerInput.Text = ""
    playerInput.PlaceholderText = "Enter username/display name"
    playerInput.TextColor3 = Color3.new(1, 1, 1)
    playerInput.Font = Enum.Font.Gotham
    playerInput.TextSize = 14
    playerInput.ClearTextOnFocus = false
    playerInput.Parent = mainFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = playerInput
    
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(0, 120, 0, 20)
    modeLabel.Position = UDim2.new(0, 10, 0, 130)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = "Mirror Mode:"
    modeLabel.TextColor3 = Color3.new(1, 1, 1)
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.TextSize = 14
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeLabel.Parent = mainFrame
    
    -- Mode buttons (centered)
    local modes = {MODES.MIRROR, MODES.FOLLOW, MODES.FACE}
    local buttonWidth = 60
    local spacing = 10
    local totalWidth = (#modes * buttonWidth) + ((#modes - 1) * spacing)
    local startX = (350 - totalWidth) / 2
    
    for i, mode in ipairs(modes) do
        local button = Instance.new("TextButton")
        button.Name = "ModeButton_" .. mode
        button.Size = UDim2.new(0, buttonWidth, 0, 20)
        button.Position = UDim2.new(0, startX + (i - 1) * (buttonWidth + spacing), 0, 130)
        button.BackgroundColor3 = (mode == CONFIG.Mode) and Color3.fromRGB(80, 100, 200) or Color3.fromRGB(60, 60, 80)
        button.Text = mode
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.Gotham
        button.TextSize = 12
        button.Parent = mainFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            CONFIG.Mode = mode
            for j, m in ipairs(modes) do
                local btn = mainFrame:FindFirstChild("ModeButton_" .. m)
                if btn then
                    btn.BackgroundColor3 = (m == mode) and Color3.fromRGB(80, 100, 200) or Color3.fromRGB(60, 60, 80)
                end
            end
            
            if mirroringActive and targetPlayer then
                StopMirroring()
                task.wait(0.1)
                StartMirroring(targetPlayer)
            end
        end)
    end
    
    mirrorButton = Instance.new("TextButton")
    mirrorButton.Size = UDim2.new(0, 120, 0, 30)
    mirrorButton.Position = UDim2.new(0.5, -60, 1, -40)
    mirrorButton.BackgroundColor3 = Color3.fromRGB(80, 100, 200)
    mirrorButton.Text = "Start Mirror"
    mirrorButton.TextColor3 = Color3.new(1, 1, 1)
    mirrorButton.Font = Enum.Font.GothamBold
    mirrorButton.TextSize = 14
    mirrorButton.Parent = mainFrame
    
    local mirrorCorner = Instance.new("UICorner")
    mirrorCorner.CornerRadius = UDim.new(0, 6)
    mirrorCorner.Parent = mirrorButton
    
    closeButton.MouseButton1Click:Connect(function()
        StopMirroring()
        screenGui:Destroy()
    end)
    
    mirrorButton.MouseButton1Click:Connect(function()
        if mirroringActive then
            StopMirroring()
        else
            local targetName = playerInput.Text
            if targetName == "" then
                ShowNotification("Please enter a player name")
                return
            end
            
            local foundPlayer = FindPlayerByName(targetName)
            if not foundPlayer then
                ShowNotification("Player not found!")
                return
            end
            
            targetPlayer = foundPlayer
            StartMirroring(foundPlayer)
        end
    end)
end

-------------------------------------------------
-- Show temporary notification in status label
-------------------------------------------------
function ShowNotification(message)
    if not statusLabel then return end
    local originalText = statusLabel.Text
    statusLabel.Text = message
    task.delay(2, function()
        if statusLabel and statusLabel.Text == message then
            statusLabel.Text = mirroringActive and ("Mirroring: " .. (targetPlayer.DisplayName or targetPlayer.Name)) or "Not Mirroring"
        end
    end)
end

-------------------------------------------------
-- Find player by username/display name (case-insensitive)
-------------------------------------------------
function FindPlayerByName(name)
    name = name:lower()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower() == name or player.DisplayName:lower() == name then
            return player
        end
    end
    return nil
end

-------------------------------------------------
-- Update status indicators
-------------------------------------------------
function UpdateStatus(isActive, targetName)
    if not mainFrame then return end
    
    local indicator = mainFrame:FindFirstChild("Frame")
    if indicator then
        indicator.BackgroundColor3 = isActive and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(200, 60, 60)
    end
    
    if statusLabel then
        statusLabel.Text = isActive and ("Mirroring: " .. targetName) or "Not Mirroring"
    end
    
    if mirrorButton then
        mirrorButton.Text = isActive and "Stop Mirror" or "Start Mirror"
        mirrorButton.BackgroundColor3 = isActive and Color3.fromRGB(200, 80, 80) or Color3.fromRGB(80, 100, 200)
    end
end

-------------------------------------------------
-- Cleanup BodyMovers with smooth transition
-------------------------------------------------
function CleanupMovers(hrp)
    if not hrp then return end
    
    if hrp:FindFirstChild("MirrorBodyPosition") then
        local bodyPos = hrp:FindFirstChild("MirrorBodyPosition")
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(bodyPos, tweenInfo, {MaxForce = Vector3.new(0, 0, 0)})
        tween:Play()
        task.delay(0.5, function()
            if bodyPos and bodyPos.Parent then
                bodyPos:Destroy()
            end
        end)
    end
    
    if hrp:FindFirstChild("MirrorBodyGyro") then
        local bodyGyro = hrp:FindFirstChild("MirrorBodyGyro")
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(bodyGyro, tweenInfo, {MaxTorque = Vector3.new(0, 0, 0)})
        tween:Play()
        task.delay(0.5, function()
            if bodyGyro and bodyGyro.Parent then
                bodyGyro:Destroy()
            end
        end)
    end
end

-------------------------------------------------
-- Stop mirroring and cleanup
-------------------------------------------------
function StopMirroring()
    mirroringActive = false
    
    if mirrorConnection then
        mirrorConnection:Disconnect()
        mirrorConnection = nil
    end
    
    if localPlayer.Character then
        local myHRP = localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHumanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if myHumanoid then
            myHumanoid.AutoRotate = true
        end
        if myHRP then
            CleanupMovers(myHRP)
        end
    end
    
    bp = nil
    bg = nil
    mirrorOffsetAngle = nil
    
    -- Reset camera to default
    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    
    UpdateStatus(false)
end

-------------------------------------------------
-- Start mirroring the target player
-------------------------------------------------
function StartMirroring(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        ShowNotification("Target character not found!")
        return
    end
    
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        ShowNotification("Your character not found!")
        return
    end
    
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHumanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
    
    if myHumanoid then
        myHumanoid.AutoRotate = false
    end
    
    local distance = CONFIG.Distance
    local newPos
    if CONFIG.Mode == MODES.MIRROR or CONFIG.Mode == MODES.FACE then
        newPos = targetHRP.Position + (targetHRP.CFrame.LookVector * distance)
    elseif CONFIG.Mode == MODES.FOLLOW then
        newPos = targetHRP.Position - (targetHRP.CFrame.LookVector * distance)
    end
    
    local lookAt = (CONFIG.Mode == MODES.FOLLOW) and (targetHRP.Position + targetHRP.CFrame.LookVector * 10) or targetHRP.Position
    myHRP.CFrame = CFrame.new(newPos, lookAt)
    
    targetCF0 = targetHRP.CFrame
    myCF0 = myHRP.CFrame
    
    -- In Mirror mode, compute the rotation offset so that:
    -- newYaw = -targetYaw + mirrorOffsetAngle matches your starting orientation.
    if CONFIG.Mode == MODES.MIRROR then
        local _, initMyYaw, _ = myHRP.CFrame:ToEulerAnglesYXZ()
        local _, initTargetYaw, _ = targetHRP.CFrame:ToEulerAnglesYXZ()
        mirrorOffsetAngle = initMyYaw + initTargetYaw
    end
    
    CleanupMovers(myHRP)
    
    bp = Instance.new("BodyPosition")
    bp.Name = "MirrorBodyPosition"
    bp.P = CONFIG.PositionP
    bp.D = CONFIG.PositionD
    bp.MaxForce = Vector3.new(0, 0, 0)
    bp.Position = myHRP.Position
    bp.Parent = myHRP
    
    bg = Instance.new("BodyGyro")
    bg.Name = "MirrorBodyGyro"
    bg.MaxTorque = Vector3.new(CONFIG.MaxForce, CONFIG.MaxForce, CONFIG.MaxForce)
    bg.P = CONFIG.GyroP
    bg.CFrame = myHRP.CFrame
    bg.Parent = myHRP
    
    previousPos = myHRP.Position
    wasJumping = false
    
    mirroringActive = true
    UpdateStatus(true, target.DisplayName or target.Name)
    
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(bp, tweenInfo, {MaxForce = Vector3.new(CONFIG.MaxForce, CONFIG.MaxForce, CONFIG.MaxForce)})
    tween:Play()
    
    mirrorConnection = RunService.Heartbeat:Connect(function(dt)
        UpdateMirror(dt, target)
    end)
end

-------------------------------------------------
-- Update mirror movement (called each frame)
-------------------------------------------------
function UpdateMirror(dt, target)
    if not mirroringActive then return end
    
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        ShowNotification("Target character lost")
        StopMirroring()
        return
    end
    
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        ShowNotification("Your character lost")
        StopMirroring()
        return
    end
    
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHumanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
    local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
    
    -- Re-sync reference if target teleports
    if (targetHRP.Position - targetCF0.Position).Magnitude > 100 then
        targetCF0 = targetHRP.CFrame
        local distance = CONFIG.Distance
        local newPos
        if CONFIG.Mode == MODES.MIRROR or CONFIG.Mode == MODES.FACE then
            newPos = targetHRP.Position + (targetHRP.CFrame.LookVector * distance)
        elseif CONFIG.Mode == MODES.FOLLOW then
            newPos = targetHRP.Position - (targetHRP.CFrame.LookVector * distance)
        end
        local lookAt = (CONFIG.Mode == MODES.FOLLOW) and (targetHRP.Position + targetHRP.CFrame.LookVector * 10) or targetHRP.Position
        myCF0 = CFrame.new(newPos, lookAt)
    end
    
    -- Calculate the relative transformation based on initial references
    local targetRelCF = targetCF0:ToObjectSpace(targetHRP.CFrame)
    local newMyCF
    if CONFIG.Mode == MODES.MIRROR then
        local mirroredTrans = Vector3.new(-targetRelCF.Position.X, targetRelCF.Position.Y, targetRelCF.Position.Z)
        local origRight = targetRelCF.XVector
        local origUp = targetRelCF.YVector
        local origLook = targetRelCF.ZVector
        local mirroredRot = CFrame.fromMatrix(Vector3.new(), -origRight, origUp, origLook)
        local mirroredRelCF = CFrame.new(mirroredTrans) * mirroredRot
        newMyCF = myCF0 * mirroredRelCF
        
        -- Override rotation: calculate expected yaw based on target’s current rotation
        local pos = newMyCF.Position
        local _, currentTargetYaw, _ = targetHRP.CFrame:ToEulerAnglesYXZ()
        local expectedYaw = -currentTargetYaw + mirrorOffsetAngle
        newMyCF = CFrame.new(pos) * CFrame.Angles(0, expectedYaw, 0)
        
        -- Auto-correct rotation if error is too high
        local _, myYaw, _ = myHRP.CFrame:ToEulerAnglesYXZ()
        local angleDiff = math.abs(math.atan2(math.sin(myYaw - expectedYaw), math.cos(myYaw - expectedYaw)))
        if angleDiff > CONFIG.RotationErrorThreshold then
            bg.CFrame = CFrame.new(myHRP.Position) * CFrame.Angles(0, expectedYaw, 0)
        end
        
        -- Update camera for FPS view
        local cam = Workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = CFrame.new(myHRP.Position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, expectedYaw, 0)
        
    elseif CONFIG.Mode == MODES.FOLLOW then
        newMyCF = myCF0 * targetRelCF
    elseif CONFIG.Mode == MODES.FACE then
        local mirroredTrans = Vector3.new(-targetRelCF.Position.X, targetRelCF.Position.Y, targetRelCF.Position.Z)
        local mirroredPosCF = myCF0 * CFrame.new(mirroredTrans)
        newMyCF = CFrame.new(mirroredPosCF.Position, targetHRP.Position)
    end
    
    if bg then
        bg.CFrame = bg.CFrame:Lerp(newMyCF, math.clamp(dt * CONFIG.RotationSmoothSpeed, 0, 1))
    end
    
    local currentY = myHRP.Position.Y
    local myState = myHumanoid and myHumanoid:GetState() or nil
    local isJumpingOrFalling = myState == Enum.HumanoidStateType.Jumping or myState == Enum.HumanoidStateType.Freefall
    
    local targetPosition = isJumpingOrFalling and Vector3.new(newMyCF.Position.X, currentY, newMyCF.Position.Z) or newMyCF.Position
    
    if CONFIG.SmoothFactor < 1 and bp then
        local currentPosition = bp.Position
        targetPosition = currentPosition:Lerp(targetPosition, CONFIG.SmoothFactor)
    end
    
    if bp then
        bp.Position = targetPosition
        local posError = (myHRP.Position - targetPosition).Magnitude
        if posError > CONFIG.PositionErrorThreshold then
            bp.Position = targetPosition
        end
        if isJumpingOrFalling then
            bp.MaxForce = Vector3.new(CONFIG.MaxForce, 0, CONFIG.MaxForce)
        else
            bp.MaxForce = Vector3.new(CONFIG.MaxForce, CONFIG.MaxForce, CONFIG.MaxForce)
        end
    end
    
    if targetHumanoid and myHumanoid then
        local targetState = targetHumanoid:GetState()
        local targetJumping = (targetState == Enum.HumanoidStateType.Jumping or targetState == Enum.HumanoidStateType.Freefall)
        if targetJumping and not wasJumping and not isJumpingOrFalling then
            myHumanoid.Jump = true
        end
        wasJumping = targetJumping
    end
    
    local currentPos = myHRP.Position
    local velocity = Vector3.new(0, 0, 0)
    if dt > 0 and previousPos then
        velocity = (currentPos - previousPos) / dt
    end
    previousPos = currentPos
    
    if myHumanoid then
        local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
        if horizontalVelocity.Magnitude > 0.1 then
            myHumanoid:Move(horizontalVelocity, false)
        else
            myHumanoid:Move(Vector3.new(0, 0, 0), false)
        end
    end
end

-- Initialize the script
CreateGUI()
