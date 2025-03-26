--[[
    Enhanced Mirror Movement Script v5 (Movement/Jump Fix)
    ------------------------------
    Based on v4, addressing issues where movement/jumping might not mirror:
    - Removed PositionErrorThreshold check, relying solely on Lerp for position smoothing.
    - Ensured BodyPosition.MaxForce.Y is zeroed immediately when jump is triggered.
    - Verified BodyPosition MaxForce update logic in the main loop.
    - Includes adaptive rotation, inverted Z-axis, smooth camera, respawn handling, distance slider.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Constants and configuration
local MODES = {
    MIRROR = "Mirror", -- Mirror X/Z pos, Mirror Y rot
    FOLLOW = "Follow", -- Copy movements and rotation exactly
    FACE = "Face"      -- Mirror X/Z pos, always face target
}

local CONFIG = {
    Mode = MODES.MIRROR,
    Distance = 5,               -- Initial distance from target (studs)
    MinDistance = 2,            -- Minimum distance for slider
    MaxDistance = 20,           -- Maximum distance for slider
    SmoothFactor = 0.2,         -- Smoothing for position (0.1-0.5 recommended)
    PositionP = 5000,           -- BodyPosition responsiveness
    PositionD = 250,            -- BodyPosition damping
    GyroP = 25000,              -- BodyGyro responsiveness
    GyroMaxTorque = 5e5,        -- Max torque for BodyGyro
    RotationSmoothSpeed = 20,   -- Base speed for rotation lerp
    RotationAdaptiveFactor = 0.6,-- How much angular error affects smoothing (0-1)
    MaxForce = 1e5,             -- Maximum force for BodyPosition
    -- PositionErrorThreshold = 2, -- REMOVED - Relying on Lerp smoothing now
    CameraTransitionTime = 0.3, -- Time for camera mode transition
}
local GYRO_MAX_TORQUE_VEC = Vector3.new(CONFIG.GyroMaxTorque, CONFIG.GyroMaxTorque, CONFIG.GyroMaxTorque)
local BP_MAX_FORCE_VEC_FULL = Vector3.new(CONFIG.MaxForce, CONFIG.MaxForce, CONFIG.MaxForce)
local BP_MAX_FORCE_VEC_NO_Y = Vector3.new(CONFIG.MaxForce, 0, CONFIG.MaxForce)


-- State variables (Same as v4)
local localPlayer = Players.LocalPlayer
local mirroringActive = false
local targetPlayer = nil
local targetCF0, myCF0 = nil, nil
local wasJumping = false
local mirrorConnection = nil
local bp, bg = nil, nil
local targetCharacterAddedConn = nil
local localCharacterAddedConn = nil
local mirrorOffsetAngle = nil
local isFpsModeActive = false
local previousCameraType = Enum.CameraType.Custom
local previousCameraCFrame = CFrame.new()
local screenGui, mainFrame, playerInput, mirrorButton, statusLabel, distanceSlider, distanceLabel

-------------------------------------------------
-- Create modern GUI (Identical to v4)
-------------------------------------------------
local function CreateGUI() if screenGui then screenGui:Destroy() end; screenGui = Instance.new("ScreenGui"); screenGui.Name = "MirrorMovementGUI"; screenGui.ResetOnSpawn = false; screenGui.IgnoreGuiInset = true; screenGui.Parent = localPlayer:WaitForChild("PlayerGui"); mainFrame = Instance.new("Frame"); mainFrame.Size = UDim2.new(0, 350, 0, 280); mainFrame.Position = UDim2.new(0.5, -175, 0.5, -140); mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40); mainFrame.BorderSizePixel = 0; mainFrame.Active = true; mainFrame.Draggable = true; mainFrame.Parent = screenGui; local uiCorner = Instance.new("UICorner"); uiCorner.CornerRadius = UDim.new(0, 8); uiCorner.Parent = mainFrame; local titleBar = Instance.new("Frame"); titleBar.Size = UDim2.new(1, 0, 0, 36); titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 80); titleBar.BorderSizePixel = 0; titleBar.Parent = mainFrame; local titleCorner = Instance.new("UICorner"); titleCorner.CornerRadius = UDim.new(0, 8); titleCorner.Parent = titleBar; local cornerFix = Instance.new("Frame"); cornerFix.Size = UDim2.new(1, 0, 0, 10); cornerFix.Position = UDim2.new(0, 0, 1, -10); cornerFix.BackgroundColor3 = Color3.fromRGB(60, 60, 80); cornerFix.BorderSizePixel = 0; cornerFix.ZIndex = 0; cornerFix.Parent = titleBar; local gradient = Instance.new("UIGradient"); gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 80))}); gradient.Rotation = 90; gradient.Parent = titleBar; local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -40, 1, 0); title.Position = UDim2.new(0, 10, 0, 0); title.BackgroundTransparency = 1; title.Text = "Mirror Movement v5"; title.TextColor3 = Color3.new(1, 1, 1); title.Font = Enum.Font.GothamBold; title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = titleBar; local closeButton = Instance.new("TextButton"); closeButton.Size = UDim2.new(0, 26, 0, 26); closeButton.Position = UDim2.new(1, -30, 0, 5); closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60); closeButton.Text = "X"; closeButton.TextColor3 = Color3.new(1, 1, 1); closeButton.Font = Enum.Font.GothamBold; closeButton.TextSize = 14; closeButton.Parent = titleBar; local closeCorner = Instance.new("UICorner"); closeCorner.CornerRadius = UDim.new(0, 6); closeCorner.Parent = closeButton; local statusIndicator = Instance.new("Frame"); statusIndicator.Name = "StatusIndicator"; statusIndicator.Size = UDim2.new(0, 10, 0, 10); statusIndicator.Position = UDim2.new(0, 10, 0, 46); statusIndicator.BackgroundColor3 = Color3.fromRGB(200, 60, 60); statusIndicator.BorderSizePixel = 0; statusIndicator.Parent = mainFrame; local statusCorner = Instance.new("UICorner"); statusCorner.CornerRadius = UDim.new(1, 0); statusCorner.Parent = statusIndicator; statusLabel = Instance.new("TextLabel"); statusLabel.Size = UDim2.new(0, 300, 0, 20); statusLabel.Position = UDim2.new(0, 26, 0, 41); statusLabel.BackgroundTransparency = 1; statusLabel.Text = "Not Mirroring"; statusLabel.TextColor3 = Color3.new(1, 1, 1); statusLabel.Font = Enum.Font.Gotham; statusLabel.TextSize = 14; statusLabel.TextXAlignment = Enum.TextXAlignment.Left; statusLabel.Parent = mainFrame; local playerLabel = Instance.new("TextLabel"); playerLabel.Size = UDim2.new(0, 120, 0, 20); playerLabel.Position = UDim2.new(0, 10, 0, 70); playerLabel.BackgroundTransparency = 1; playerLabel.Text = "Player Name:"; playerLabel.TextColor3 = Color3.new(1, 1, 1); playerLabel.Font = Enum.Font.Gotham; playerLabel.TextSize = 14; playerLabel.TextXAlignment = Enum.TextXAlignment.Left; playerLabel.Parent = mainFrame; playerInput = Instance.new("TextBox"); playerInput.Size = UDim2.new(0, 330, 0, 30); playerInput.Position = UDim2.new(0, 10, 0, 90); playerInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50); playerInput.BorderSizePixel = 0; playerInput.Text = ""; playerInput.PlaceholderText = "Enter username/display name"; playerInput.TextColor3 = Color3.new(1, 1, 1); playerInput.Font = Enum.Font.Gotham; playerInput.TextSize = 14; playerInput.ClearTextOnFocus = false; playerInput.Parent = mainFrame; local inputCorner = Instance.new("UICorner"); inputCorner.CornerRadius = UDim.new(0, 6); inputCorner.Parent = playerInput; local modeLabel = Instance.new("TextLabel"); modeLabel.Size = UDim2.new(0, 120, 0, 20); modeLabel.Position = UDim2.new(0, 10, 0, 130); modeLabel.BackgroundTransparency = 1; modeLabel.Text = "Mirror Mode:"; modeLabel.TextColor3 = Color3.new(1, 1, 1); modeLabel.Font = Enum.Font.Gotham; modeLabel.TextSize = 14; modeLabel.TextXAlignment = Enum.TextXAlignment.Left; modeLabel.Parent = mainFrame; local modes = {MODES.MIRROR, MODES.FOLLOW, MODES.FACE}; local buttonWidth = 60; local spacing = 10; local totalWidth = (#modes * buttonWidth) + ((#modes - 1) * spacing); local startX = (350 - totalWidth) / 2; for i, mode in ipairs(modes) do local button = Instance.new("TextButton"); button.Name = "ModeButton_" .. mode; button.Size = UDim2.new(0, buttonWidth, 0, 20); button.Position = UDim2.new(0, startX + (i - 1) * (buttonWidth + spacing), 0, 130); button.BackgroundColor3 = (mode == CONFIG.Mode) and Color3.fromRGB(80, 100, 200) or Color3.fromRGB(60, 60, 80); button.Text = mode; button.TextColor3 = Color3.new(1, 1, 1); button.Font = Enum.Font.Gotham; button.TextSize = 12; button.Parent = mainFrame; local buttonCorner = Instance.new("UICorner"); buttonCorner.CornerRadius = UDim.new(0, 4); buttonCorner.Parent = button; button.MouseButton1Click:Connect(function() if CONFIG.Mode == mode then return end; CONFIG.Mode = mode; for _, m in ipairs(modes) do local btn = mainFrame:FindFirstChild("ModeButton_" .. m); if btn then btn.BackgroundColor3 = (m == mode) and Color3.fromRGB(80, 100, 200) or Color3.fromRGB(60, 60, 80) end end; if mirroringActive and targetPlayer then local currentTarget = targetPlayer; StopMirroring(); task.wait(0.2); StartMirroring(currentTarget) end end) end; distanceLabel = Instance.new("TextLabel"); distanceLabel.Size = UDim2.new(1, -20, 0, 20); distanceLabel.Position = UDim2.new(0, 10, 0, 165); distanceLabel.BackgroundTransparency = 1; distanceLabel.Text = "Distance: " .. string.format("%.1f", CONFIG.Distance) .. " studs"; distanceLabel.TextColor3 = Color3.new(1, 1, 1); distanceLabel.Font = Enum.Font.Gotham; distanceLabel.TextSize = 14; distanceLabel.TextXAlignment = Enum.TextXAlignment.Left; distanceLabel.Parent = mainFrame; distanceSlider = Instance.new("Frame"); distanceSlider.Size = UDim2.new(0, 330, 0, 10); distanceSlider.Position = UDim2.new(0, 10, 0, 190); distanceSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50); distanceSlider.BorderSizePixel = 0; distanceSlider.Parent = mainFrame; local sliderTrackCorner = Instance.new("UICorner"); sliderTrackCorner.CornerRadius = UDim.new(0, 5); sliderTrackCorner.Parent = distanceSlider; local sliderHandle = Instance.new("Frame"); sliderHandle.Size = UDim2.new(0, 16, 0, 16); sliderHandle.Position = UDim2.new(0, 0, 0.5, -8); sliderHandle.BackgroundColor3 = Color3.fromRGB(80, 100, 200); sliderHandle.BorderSizePixel = 0; sliderHandle.ZIndex = 2; sliderHandle.Parent = distanceSlider; local sliderHandleCorner = Instance.new("UICorner"); sliderHandleCorner.CornerRadius = UDim.new(0, 4); sliderHandleCorner.Parent = sliderHandle; local function UpdateSliderHandlePosition() local percentage = (CONFIG.Distance - CONFIG.MinDistance) / (CONFIG.MaxDistance - CONFIG.MinDistance); local trackWidth = distanceSlider.AbsoluteSize.X; local handleWidth = sliderHandle.AbsoluteSize.X; local maxHandleX = trackWidth - handleWidth; sliderHandle.Position = UDim2.new(0, math.clamp(percentage * maxHandleX, 0, maxHandleX), 0.5, -8); distanceLabel.Text = "Distance: " .. string.format("%.1f", CONFIG.Distance) .. " studs" end; local isDragging = false; sliderHandle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = true end end); sliderHandle.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end end); UserInputService.InputChanged:Connect(function(input) if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local trackWidth = distanceSlider.AbsoluteSize.X; local handleWidth = sliderHandle.AbsoluteSize.X; local maxHandleX = trackWidth - handleWidth; local relativeMouseX = UserInputService:GetMouseLocation().X - distanceSlider.AbsolutePosition.X - (handleWidth / 2); local percentage = math.clamp(relativeMouseX / maxHandleX, 0, 1); local newDistance = CONFIG.MinDistance + percentage * (CONFIG.MaxDistance - CONFIG.MinDistance); CONFIG.Distance = newDistance; UpdateSliderHandlePosition(); if mirroringActive and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then local targetHRP = targetPlayer.Character.HumanoidRootPart; local myHRP = localPlayer.Character.HumanoidRootPart; targetCF0 = targetHRP.CFrame; local desiredOffset; if CONFIG.Mode == MODES.MIRROR or CONFIG.Mode == MODES.FACE then desiredOffset = targetHRP.CFrame.LookVector * CONFIG.Distance else desiredOffset = -targetHRP.CFrame.LookVector * CONFIG.Distance end; local desiredWorldPos = targetHRP.Position + desiredOffset; myCF0 = CFrame.new(desiredWorldPos) * myHRP.CFrame:ToObjectSpace(CFrame.new(myHRP.Position)); if CONFIG.Mode == MODES.MIRROR then local _, cMyY, _ = myHRP.CFrame:ToEulerAnglesYXZ(); local _, cTgtY, _ = targetHRP.CFrame:ToEulerAnglesYXZ(); mirrorOffsetAngle = cMyY + cTgtY; mirrorOffsetAngle = math.atan2(math.sin(mirrorOffsetAngle), math.cos(mirrorOffsetAngle)) end end end end); UpdateSliderHandlePosition(); mirrorButton = Instance.new("TextButton"); mirrorButton.Size = UDim2.new(0, 120, 0, 30); mirrorButton.Position = UDim2.new(0.5, -60, 1, -40); mirrorButton.BackgroundColor3 = Color3.fromRGB(80, 100, 200); mirrorButton.Text = "Start Mirror"; mirrorButton.TextColor3 = Color3.new(1, 1, 1); mirrorButton.Font = Enum.Font.GothamBold; mirrorButton.TextSize = 14; mirrorButton.Parent = mainFrame; local mirrorCorner = Instance.new("UICorner"); mirrorCorner.CornerRadius = UDim.new(0, 6); mirrorCorner.Parent = mirrorButton; closeButton.MouseButton1Click:Connect(function() StopMirroring(); if screenGui then screenGui:Destroy() end end); mirrorButton.MouseButton1Click:Connect(function() if mirroringActive then StopMirroring() else local targetName = playerInput.Text; if targetName == "" then ShowNotification("Please enter a player name", true); return end; local foundPlayer = FindPlayerByName(targetName); if not foundPlayer then ShowNotification("Player not found!", true); return end; if foundPlayer == localPlayer then ShowNotification("Cannot mirror yourself!", true); return end; targetPlayer = foundPlayer; StartMirroring(foundPlayer) end end) end

-------------------------------------------------
-- Utility Functions (Identical to v4)
-------------------------------------------------
function ShowNotification(message, isError) if not statusLabel then return end; local originalText = statusLabel.Text; statusLabel.Text = message; statusLabel.TextColor3 = isError and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(200, 200, 100); task.delay(3, function() if statusLabel and statusLabel.Parent and statusLabel.Text == message then statusLabel.TextColor3 = Color3.new(1, 1, 1); if mirroringActive and targetPlayer then statusLabel.Text = "Mirroring: " .. (targetPlayer.DisplayName or targetPlayer.Name) else statusLabel.Text = "Not Mirroring" end end end) end
function FindPlayerByName(name) name = name:lower(); for _, player in ipairs(Players:GetPlayers()) do if player.Name:lower() == name or player.DisplayName:lower() == name then return player end end; return nil end
function UpdateStatus(isActive, targetName) if not mainFrame then return end; local indicator = mainFrame:FindFirstChild("StatusIndicator"); if indicator then indicator.BackgroundColor3 = isActive and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(200, 60, 60) end; if statusLabel then statusLabel.Text = isActive and ("Mirroring: " .. targetName) or "Not Mirroring"; statusLabel.TextColor3 = Color3.new(1,1,1) end; if mirrorButton then mirrorButton.Text = isActive and "Stop Mirror" or "Start Mirror"; mirrorButton.BackgroundColor3 = isActive and Color3.fromRGB(200, 80, 80) or Color3.fromRGB(80, 100, 200) end end
local cameraTween = nil
function SetCameraMode(isFPS) local cam = Workspace.CurrentCamera; if isFPS and not isFpsModeActive then isFpsModeActive = true; previousCameraType = cam.CameraType; previousCameraCFrame = cam.CFrame; cam.CameraType = Enum.CameraType.Scriptable; local myHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart"); if myHRP then local targetCFrame = CFrame.new(myHRP.Position + Vector3.new(0,1.5,0)) * CFrame.Angles(0, math.rad(180), 0); if cameraTween then cameraTween:Cancel() end; cameraTween = TweenService:Create(cam, TweenInfo.new(CONFIG.CameraTransitionTime), {CFrame = targetCFrame}); cameraTween:Play() end elseif not isFPS and isFpsModeActive then isFpsModeActive = false; if cameraTween then cameraTween:Cancel() end; cameraTween = TweenService:Create(cam, TweenInfo.new(CONFIG.CameraTransitionTime), {CFrame = previousCameraCFrame}); cameraTween:Play(); task.delay(CONFIG.CameraTransitionTime, function() if not isFpsModeActive then cam.CameraType = previousCameraType end end) end end
function CleanupMovers(hrp) if not hrp then return end; for _, moverName in ipairs({"MirrorBodyPosition", "MirrorBodyGyro"}) do local mover = hrp:FindFirstChild(moverName); if mover then local props = {}; if mover:IsA("BodyPosition") then props.MaxForce = Vector3.zero; bp = nil elseif mover:IsA("BodyGyro") then props.MaxTorque = Vector3.zero; bg = nil end; if next(props) then local tween = TweenService:Create(mover, TweenInfo.new(0.3), props); tween:Play(); task.delay(0.3, function() pcall(function() mover:Destroy() end) end) else pcall(function() mover:Destroy() end) end end end; bp = nil; bg = nil end
local function getYawAngleDifference(cf1, cf2) local _, y1, _ = cf1:ToEulerAnglesYXZ(); local _, y2, _ = cf2:ToEulerAnglesYXZ(); local diff = y1 - y2; return math.atan2(math.sin(diff), math.cos(diff)) end

-------------------------------------------------
-- Stop mirroring (Identical to v4)
-------------------------------------------------
function StopMirroring() if not mirroringActive then return end; mirroringActive = false; if mirrorConnection then mirrorConnection:Disconnect(); mirrorConnection = nil end; if targetCharacterAddedConn then targetCharacterAddedConn:Disconnect(); targetCharacterAddedConn = nil end; if localCharacterAddedConn then localCharacterAddedConn:Disconnect(); localCharacterAddedConn = nil end; local char = localPlayer.Character; if char then local myHRP = char:FindFirstChild("HumanoidRootPart"); local myHumanoid = char:FindFirstChildOfClass("Humanoid"); if myHumanoid then myHumanoid.AutoRotate = true end; if myHRP then CleanupMovers(myHRP) end end; targetPlayer = nil; mirrorOffsetAngle = nil; SetCameraMode(false); UpdateStatus(false) end

-------------------------------------------------
-- Start mirroring (Identical to v4 - MaxForce tween is fine here)
-------------------------------------------------
function StartMirroring(target)
    if mirroringActive then StopMirroring() end
    local targetChar = target and target.Character; local localChar = localPlayer.Character
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then ShowNotification("Target character not found!", true); return end
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") or not localChar:FindFirstChildOfClass("Humanoid") then ShowNotification("Your character not found or incomplete!", true); return end

    local targetHRP = targetChar.HumanoidRootPart; local myHRP = localChar.HumanoidRootPart; local myHumanoid = localChar.Humanoid
    myHumanoid.AutoRotate = false

    local initialOffset = Vector3.zero; if CONFIG.Mode == MODES.MIRROR or CONFIG.Mode == MODES.FACE then initialOffset = targetHRP.CFrame.LookVector * CONFIG.Distance elseif CONFIG.Mode == MODES.FOLLOW then initialOffset = -targetHRP.CFrame.LookVector * CONFIG.Distance end
    local desiredStartPos = targetHRP.Position + initialOffset; myHRP.CFrame = CFrame.new(desiredStartPos, targetHRP.Position)
    targetCF0 = targetHRP.CFrame; myCF0 = myHRP.CFrame

    if CONFIG.Mode == MODES.MIRROR then local _, iMyY, _ = myCF0:ToEulerAnglesYXZ(); local _, iTgtY, _ = targetCF0:ToEulerAnglesYXZ(); mirrorOffsetAngle = iMyY + iTgtY; mirrorOffsetAngle = math.atan2(math.sin(mirrorOffsetAngle), math.cos(mirrorOffsetAngle)) end

    CleanupMovers(myHRP); task.wait(0.05)

    bp = Instance.new("BodyPosition"); bp.Name = "MirrorBodyPosition"; bp.P = CONFIG.PositionP; bp.D = CONFIG.PositionD; bp.MaxForce = Vector3.zero; bp.Position = myHRP.Position; bp.Parent = myHRP
    bg = Instance.new("BodyGyro"); bg.Name = "MirrorBodyGyro"; bg.MaxTorque = GYRO_MAX_TORQUE_VEC; bg.P = CONFIG.GyroP; bg.CFrame = myHRP.CFrame; bg.Parent = myHRP

    wasJumping = false; mirroringActive = true
    UpdateStatus(true, target.DisplayName or target.Name)
    -- Tween BodyPosition MaxForce up from zero
    local tween = TweenService:Create(bp, TweenInfo.new(0.5), {MaxForce = BP_MAX_FORCE_VEC_FULL}); tween:Play()
    if CONFIG.Mode == MODES.MIRROR then SetCameraMode(true) else SetCameraMode(false) end

    targetCharacterAddedConn = target.CharacterAdded:Connect(function(newChar) ShowNotification("Target respawned, stopping.", false); StopMirroring() end)
    localCharacterAddedConn = localPlayer.CharacterAdded:Connect(function(newChar) ShowNotification("You respawned, stopping.", false); StopMirroring() end)
    mirrorConnection = RunService.Heartbeat:Connect(function(dt) UpdateMirror(dt, target) end)
end


-------------------------------------------------
-- Update mirror movement (Heartbeat) - MODIFIED
-------------------------------------------------
function UpdateMirror(dt, currentTarget)
    if not mirroringActive or not currentTarget then return end

    local success, result = pcall(function()
        local targetChar = currentTarget.Character; local localChar = localPlayer.Character
        if not targetChar or not targetChar.Parent or not localChar or not localChar.Parent then return false, "Character lost parent" end
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart"); local myHRP = localChar:FindFirstChild("HumanoidRootPart")
        local myHumanoid = localChar:FindFirstChildOfClass("Humanoid"); local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
        if not targetHRP or not myHRP or not myHumanoid or not targetHumanoid then return false, "Essential part missing" end
        if not bp or not bp.Parent or not bg or not bg.Parent then return false, "BodyMovers missing" end

        -- Teleport Resync (Identical to v4)
        if (targetHRP.Position - targetCF0.Position).Magnitude > 100 then
            ShowNotification("Target teleported, re-syncing...", false); targetCF0 = targetHRP.CFrame
            local desiredOffset; if CONFIG.Mode == MODES.MIRROR or CONFIG.Mode == MODES.FACE then desiredOffset = targetHRP.CFrame.LookVector * CONFIG.Distance else desiredOffset = -targetHRP.CFrame.LookVector * CONFIG.Distance end
            local desiredWorldPos = targetHRP.Position + desiredOffset; myCF0 = CFrame.new(desiredWorldPos) * myHRP.CFrame:ToObjectSpace(CFrame.new(myHRP.Position))
            if CONFIG.Mode == MODES.MIRROR then local _, cMyY, _ = myHRP.CFrame:ToEulerAnglesYXZ(); local _, cTgtY, _ = targetHRP.CFrame:ToEulerAnglesYXZ(); mirrorOffsetAngle = cMyY + cTgtY; mirrorOffsetAngle = math.atan2(math.sin(mirrorOffsetAngle), math.cos(mirrorOffsetAngle)) end
        end

        local targetRelCF = targetCF0:ToObjectSpace(targetHRP.CFrame)
        local targetCurrentPos = targetHRP.Position
        local goalMyCF, goalMyPos, goalMyRot -- Rotation/Position Goal Calculation (Identical to v4)

        -- Calculate goal position and rotation based on mode (Identical logic to v4)
        if CONFIG.Mode == MODES.MIRROR then
            local invMirRelPos = Vector3.new(-targetRelCF.Position.X, targetRelCF.Position.Y, -targetRelCF.Position.Z)
            goalMyPos = myCF0.Position + (myCF0.RightVector * invMirRelPos.X) + (myCF0.UpVector * invMirRelPos.Y) + (myCF0.LookVector * invMirRelPos.Z)
            local _, curTgtY, _ = targetHRP.CFrame:ToEulerAnglesYXZ(); local desWorldY = -curTgtY + mirrorOffsetAngle
            goalMyRot = CFrame.Angles(0, desWorldY, 0); goalMyCF = CFrame.new(goalMyPos) * goalMyRot
        elseif CONFIG.Mode == MODES.FOLLOW then
            goalMyCF = myCF0 * targetRelCF; goalMyPos = goalMyCF.Position; goalMyRot = goalMyCF - goalMyPos
        elseif CONFIG.Mode == MODES.FACE then
            local invMirRelPos = Vector3.new(-targetRelCF.Position.X, targetRelCF.Position.Y, -targetRelCF.Position.Z)
            goalMyPos = myCF0.Position + (myCF0.RightVector * invMirRelPos.X) + (myCF0.UpVector * invMirRelPos.Y) + (myCF0.LookVector * invMirRelPos.Z)
            local lookAtPos = Vector3.new(targetCurrentPos.X, goalMyPos.Y, targetCurrentPos.Z)
            if (goalMyPos - lookAtPos).Magnitude < 0.1 then goalMyRot = myHRP.CFrame - myHRP.Position else goalMyRot = CFrame.lookAt(goalMyPos, lookAtPos) - goalMyPos end
            goalMyCF = CFrame.new(goalMyPos) * goalMyRot
        end

        -- Rotation Update (BodyGyro) - Using Adaptive Smoothing (Identical to v4)
        if bg then -- Check bg still exists
            local currentRotCF = bg.CFrame
            local angleDiff = math.abs(getYawAngleDifference(currentRotCF, goalMyCF))
            local adaptiveAlpha = math.clamp(dt * CONFIG.RotationSmoothSpeed + angleDiff * CONFIG.RotationAdaptiveFactor, 0, 1)
            bg.CFrame = currentRotCF:Lerp(goalMyCF, adaptiveAlpha)

            -- Update FPS Camera if applicable (Identical to v4)
            if isFpsModeActive and CONFIG.Mode == MODES.MIRROR then
                 local cam = Workspace.CurrentCamera; local _, desWorldY, _ = goalMyRot:ToEulerAnglesYXZ() -- Extract yaw from goal rotation
                 local camTargetCFrame = CFrame.new(myHRP.Position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, desWorldY, 0)
                 cam.CFrame = cam.CFrame:Lerp(camTargetCFrame, adaptiveAlpha)
            end
        end

        -- Position Update (BodyPosition) - MODIFIED
        if bp then -- Check bp still exists
            local finalTargetPos = goalMyPos -- Start with the raw goal position
            if CONFIG.SmoothFactor < 1 then
                finalTargetPos = bp.Position:Lerp(goalMyPos, CONFIG.SmoothFactor) -- Apply smoothing
            end

            -- Always update the position to the (potentially smoothed) target
            bp.Position = finalTargetPos

            -- NOTE: MaxForce is now handled primarily in the Jump Replication section below
            -- We set a default here, but the jump logic might override it.
            bp.MaxForce = BP_MAX_FORCE_VEC_FULL -- Default to full force
        end

        -- Jump Replication & BodyPosition MaxForce Handling - MODIFIED
        local myState = myHumanoid:GetState()
        local isJumpingOrFalling = myState == Enum.HumanoidStateType.Jumping or myState == Enum.HumanoidStateType.Freefall
        local targetState = targetHumanoid:GetState()
        local targetIsJumping = (targetState == Enum.HumanoidStateType.Jumping or targetState == Enum.HumanoidStateType.Freefall)

        -- Jump Trigger Logic
        if targetIsJumping and not wasJumping and not isJumpingOrFalling then
            myHumanoid.Jump = true
             -- Crucial: Force MaxForce.Y to 0 *immediately* when triggering the jump
            if bp then
                 bp.MaxForce = BP_MAX_FORCE_VEC_NO_Y
            end
            -- We set isJumpingOrFalling true here temporarily just for the MaxForce check below
            -- It will be correctly evaluated by the Humanoid state next frame anyway
            isJumpingOrFalling = true
        end
        wasJumping = targetIsJumping

        -- Apply correct MaxForce based on whether we are (or just started) jumping/falling
        if bp then
             if isJumpingOrFalling then
                 -- If we are already in the air OR we just triggered the jump above
                 if bp.MaxForce.Y ~= 0 then -- Only update if necessary
                     bp.MaxForce = BP_MAX_FORCE_VEC_NO_Y
                 end
             else
                 -- Only apply full force if not jumping/falling AND force isn't already full
                 if bp.MaxForce.Y == 0 then
                     bp.MaxForce = BP_MAX_FORCE_VEC_FULL
                 end
             end
        end

        return true -- Success
    end)

    -- Error Handling (Identical to v4)
    if not success then warn("Mirror Update Error:", result); ShowNotification("Error during update, stopping. ("..tostring(result)..")", true); StopMirroring()
    elseif success and not result then warn("Mirror Update Stopped:", result); ShowNotification("Stopping mirror: "..tostring(result), false); StopMirroring() end
end

-- Initialize & Cleanup Connections (Identical to v4)
CreateGUI()
Players.PlayerRemoving:Connect(function(player) if player == targetPlayer then ShowNotification("Target left, stopping.", false); StopMirroring() end end)
local errorConnection; errorConnection = game:GetService("ScriptContext").Error:Connect(function(message, stacktrace, scriptInstance) if scriptInstance == script then StopMirroring(); if screenGui then pcall(function() screenGui:Destroy() end) end; if errorConnection then errorConnection:Disconnect() end end end)
localPlayer.CharacterRemoving:Connect(function() StopMirroring() end)
