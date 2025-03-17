local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Config = {
    ToggleKey = Enum.KeyCode.Q,
    TeamCheck = true,
    DebugMode = false
}

local AutoClicker = {
    isEnabled = true,
    isHolding = false,
    lastCheckTime = 0
}

local ESPFolder = Instance.new("Folder", Camera)
ESPFolder.Name = "ESPFolder"
local espCache = {}

-- Enhanced ESP System --
local function addESP(character)
    if not character or not character:FindFirstChild("Humanoid") then return end
    if espCache[character] then return end
    
    -- Skip local player's character
    local player = Players:GetPlayerFromCharacter(character)
    if player and player == LocalPlayer then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.OutlineColor = Color3.new(1, 0, 0)
    highlight.FillTransparency = 1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ESPFolder
    highlight.Adornee = character

    espCache[character] = highlight

    -- Cleanup system
    local destroyConnection
    destroyConnection = character.Destroying:Connect(function()
        if espCache[character] then
            highlight:Destroy()
            espCache[character] = nil
            destroyConnection:Disconnect()
        end
    end)
end

local function initializeESP()
    -- Initial scan with filtering
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(child)
            if not player or player ~= LocalPlayer then
                addESP(child)
            end
        end
    end

    -- Smart child added listener
    local function onChildAdded(child)
        if child:IsA("Model") then
            -- Filter local player's character
            local player = Players:GetPlayerFromCharacter(child)
            if player and player == LocalPlayer then return end

            -- Immediate check
            if child:FindFirstChild("Humanoid") then
                addESP(child)
            end
            
            -- Delayed humanoid detection
            local humanoidConnection
            humanoidConnection = child.ChildAdded:Connect(function(descendant)
                if descendant:IsA("Humanoid") then
                    addESP(child)
                    humanoidConnection:Disconnect()
                end
            end)
        end
    end

    workspace.ChildAdded:Connect(onChildAdded)
end

local function clearESP()
    for character, highlight in pairs(espCache) do
        highlight:Destroy()
        espCache[character] = nil
    end
    ESPFolder:ClearAllChildren()
end

-- Player cleanup system
Players.PlayerRemoving:Connect(function(player)
    local character = player.Character
    if character and espCache[character] then
        espCache[character]:Destroy()
        espCache[character] = nil
    end
end)

-- Target validation system
local function isValidTarget(target)
    if not target then return false end
    
    local targetCharacter = target:FindFirstAncestorOfClass("Model")
    if not targetCharacter then return false end
    
    -- Ignore local player's character
    if targetCharacter == LocalPlayer.Character then return false end
    
    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
    if not targetPlayer then return false end
    
    -- Team check
    if Config.TeamCheck and LocalPlayer.Team and targetPlayer.Team then
        return targetPlayer.Team ~= LocalPlayer.Team
    end
    
    return true
end

-- Debug system
local function debugLog(message)
    if Config.DebugMode then
        print("[AutoClicker Debug] " .. message)
    end
end

-- Auto-hold core system
local function autoHoldLoop()
    RunService.Heartbeat:Connect(function()
        if not AutoClicker.isEnabled then 
            if AutoClicker.isHolding then
                AutoClicker.isHolding = false
                mouse1release()
            end
            return 
        end
        
        local target = Mouse.Target
        
        if target and isValidTarget(target) then
            if not AutoClicker.isHolding then
                AutoClicker.isHolding = true
                mouse1press()
                debugLog("Target acquired, started holding")
            end
        else
            if AutoClicker.isHolding then
                AutoClicker.isHolding = false
                mouse1release()
                debugLog("No valid target, released")
            end
        end
    end)
end

-- Cursor management
local function lockCursor()
    UserInputService.MouseBehavior = AutoClicker.isEnabled 
        and Enum.MouseBehavior.LockCenter 
        or Enum.MouseBehavior.Default
end

-- Toggle control system
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.ToggleKey then
        AutoClicker.isEnabled = not AutoClicker.isEnabled
        lockCursor()
        
        -- Notification system
        local notificationService = game:GetService("StarterGui")
        notificationService:SetCore("SendNotification", {
            Title = "Auto Clicker",
            Text = AutoClicker.isEnabled and "Enabled ✓" or "Disabled ✗",
            Duration = 2
        })
        
        -- ESP management
        if AutoClicker.isEnabled then
            initializeESP()
            debugLog("Systems activated")
        else
            clearESP()
            debugLog("Systems deactivated")
            if AutoClicker.isHolding then
                AutoClicker.isHolding = false
                mouse1release()
            end
        end
    end
end)

-- Initialization sequence
autoHoldLoop()
lockCursor()
initializeESP()
debugLog("Systems initialized")

-- Final cleanup
LocalPlayer.CharacterRemoving:Connect(function()
    clearESP()
    lockCursor()
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "System Ready",
    Text = "AutoClicker & ESP initialized",
    Duration = 3
})
