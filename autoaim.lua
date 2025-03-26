--[[
    Script: Enhanced AutoClicker & ESP v1.2
    Features:
        - AutoShoot: Automatically holds LMB when aiming *specifically* at an enemy player's hitbox part.
        - ESP: Highlights other players through walls (handles joins, resets, deaths).
        - Cursor Lock: Locks the cursor to the center when enabled.
    Toggle Key: Configurable (Default: Q)
]]

--// Services //--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

--// Local Player & Mouse //--
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players.PlayerAdded:Wait() -- Wait for local player if script runs too early
    LocalPlayer = Players.LocalPlayer
end
local Mouse = LocalPlayer:GetMouse() -- Using legacy mouse for Mouse.Target

--// Configuration //--
local Config = {
    ToggleKey = Enum.KeyCode.Q,
    TeamCheck = true,           -- Only target/color differently players on different teams
    EnemyColor = Color3.fromRGB(255, 60, 60),   -- Red for enemies
    TeamColor = Color3.fromRGB(60, 255, 60),    -- Green for teammates
    HighlightFillTransparency = 0.8, -- How much the highlight fills the character (0=solid, 1=invisible)
    HighlightOutlineTransparency = 0, -- Outline visibility (0=visible, 1=invisible)
    DebugMode = false           -- Print debug messages to console
}

--// State Variables //--
local State = {
    isEnabled = true,      -- Is the main script functionality active?
    isHoldingMouse = false -- Is the left mouse button currently held down by the script?
}

--// Globals / External Dependencies (IMPORTANT!) //--
-- These functions MUST be provided by the script's execution environment.
local function performMousePress()
    if typeof(mouse1press) == "function" then
        mouse1press()
    elseif Config.DebugMode then warn("[AutoClicker] 'mouse1press' function not found!") end
end

local function performMouseRelease()
    if typeof(mouse1release) == "function" then
        mouse1release()
    elseif Config.DebugMode then warn("[AutoClicker] 'mouse1release' function not found!") end
end

--// Debug Logging //--
local function debugLog(message)
    if Config.DebugMode then
        print("[AutoClicker Debug] " .. tostring(message))
    end
end

--// ESP System //--
local espCache = {} -- [Character] = { Highlight = HighlightInstance, Connections = {Connection} }
local ESPFolder = Workspace.CurrentCamera:FindFirstChild("ESPFolder")
if not ESPFolder or not ESPFolder:IsA("Folder") then
    if ESPFolder then ESPFolder:Destroy() end -- Remove if wrong type
    ESPFolder = Instance.new("Folder", Workspace.CurrentCamera)
    ESPFolder.Name = "ESPFolder"
end

local function cleanupEspConnections(character)
    if espCache[character] and espCache[character].Connections then
        for _, conn in ipairs(espCache[character].Connections) do
            conn:Disconnect()
        end
        espCache[character].Connections = nil
    end
end

local function getHighlightColor(targetPlayer)
    if not targetPlayer then return Config.EnemyColor end
    if Config.TeamCheck and LocalPlayer.Team and targetPlayer.Team then
        return (targetPlayer.Team == LocalPlayer.Team) and Config.TeamColor or Config.EnemyColor
    else
        return Config.EnemyColor
    end
end

local function removeESP(character)
    if character and espCache[character] then
        --debugLog("Removing ESP for: " .. character.Name) -- Can be spammy, uncomment if needed
        cleanupEspConnections(character)
        if espCache[character].Highlight and espCache[character].Highlight.Parent then
            espCache[character].Highlight:Destroy()
        end
        espCache[character] = nil
    end
end

local function addESP(character)
    if not character or not character.Parent then return end
    if character == LocalPlayer.Character then return end
    if espCache[character] then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if humanoid.Health <= 0 then return end

    --debugLog("Adding ESP for: " .. character.Name) -- Can be spammy

    local player = Players:GetPlayerFromCharacter(character)
    local highlight = Instance.new("Highlight")
    highlight.Name = character.Name .. "_ESPHighlight"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = Config.HighlightFillTransparency
    highlight.OutlineTransparency = Config.HighlightOutlineTransparency
    highlight.OutlineColor = getHighlightColor(player)
    highlight.FillColor = highlight.OutlineColor

    espCache[character] = {
        Highlight = highlight,
        Connections = {}
    }

    table.insert(espCache[character].Connections, humanoid.HealthChanged:Connect(function(health)
        if health <= 0 and espCache[character] then
            removeESP(character)
        end
    end))

    table.insert(espCache[character].Connections, character.Destroying:Connect(function()
        removeESP(character)
    end))

    highlight.Parent = ESPFolder
end

local function updateESPColor(character)
     if character and espCache[character] and espCache[character].Highlight then
        local player = Players:GetPlayerFromCharacter(character)
        local color = getHighlightColor(player)
        espCache[character].Highlight.OutlineColor = color
        espCache[character].Highlight.FillColor = color
    end
end

local function setupPlayerESP(player)
    if player == LocalPlayer then return end
    --debugLog("Setting up ESP listeners for player: " .. player.Name) -- Spammy

    local charAddedConn = player.CharacterAdded:Connect(addESP)
    local charRemovingConn = player.CharacterRemoving:Connect(removeESP)
    local teamChangedConn = player:GetPropertyChangedSignal("Team"):Connect(function()
        if player.Character then updateESPColor(player.Character) end
    end)

    if player.Character then addESP(player.Character) end
end

local function initializeESP()
    debugLog("Initializing ESP...")
    espCache = {}
    ESPFolder:ClearAllChildren()

    task.spawn(function()
        for _, player in ipairs(Players:GetPlayers()) do
            setupPlayerESP(player)
        end
    end)
end

local function clearESP()
    debugLog("Clearing ESP...")
    for character, data in pairs(espCache) do
        cleanupEspConnections(character)
        if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
    end
    espCache = {}
end

--// Target Validation (Enhanced for Hitbox Specificity) //--
local function isValidTarget(hitPart)
    -- 1. Basic Part Check
    if not hitPart or not hitPart:IsA("BasePart") or not hitPart.Parent then
        return false -- Target isn't a valid part
    end

    -- 2. Accessory Check: Ignore parts that belong to an Accessory item
    if hitPart:FindFirstAncestorWhichIsA("Accessory") then
        -- Optionally log if debugging accessories: debugLog("Target is part of an Accessory: " .. hitPart.Name)
        return false
    end

    -- 3. Find Character Model
    local targetCharacter = hitPart:FindFirstAncestorWhichIsA("Model")
    if not targetCharacter or targetCharacter == LocalPlayer.Character then
        return false -- Not a model, or is the local player
    end

    -- 4. Character Validity Checks (Humanoid, Health)
    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false -- No humanoid or character is dead
    end

    -- 5. Player & Team Checks
    local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
    if not targetPlayer then
        return false -- It's a model, but not a player character (e.g., NPC)
    end

    if Config.TeamCheck then
        if LocalPlayer.Team and targetPlayer.Team and targetPlayer.Team == LocalPlayer.Team then
            return false -- On the same team
        end
    end

    -- 6. Hitbox Structure Check (Heuristic)
    -- Core body parts are typically direct children of the Model (R6)
    -- OR children of *another* BasePart that IS a child of the Model (R15 nested limbs).
    -- This helps filter out some layered clothing MeshParts that might be direct children of the Model
    -- but aren't part of the fundamental rig structure.
    local parent = hitPart.Parent
    local isLikelyHitbox = (parent == targetCharacter) -- Direct child (R6 body part, or potentially layered clothing)
                          or (parent:IsA("BasePart") and parent.Parent == targetCharacter) -- Nested child (R15 body part)

    if not isLikelyHitbox then
        --debugLog("Target part structure mismatch (likely clothing/attachment): " .. hitPart.Name)
        return false
    end

    -- If all checks pass, it's considered a valid hitbox target
    --debugLog("Valid hitbox target: " .. hitPart.Name .. " on " .. targetCharacter.Name) -- Spammy but useful for testing
    return true
end


--// Auto-Hold Logic //--
local function updateAutoHold()
    if not State.isEnabled then
        if State.isHoldingMouse then
            performMouseRelease()
            State.isHoldingMouse = false
            --debugLog("Auto-hold disabled, released mouse.")
        end
        return
    end

    local targetPart = Mouse.Target -- Get the specific part the mouse is over

    if isValidTarget(targetPart) then -- Use the enhanced validation
        if not State.isHoldingMouse then
            performMousePress()
            State.isHoldingMouse = true
            debugLog("Valid hitbox target (" .. targetPart.Name .. "), pressing mouse.")
        end
    else
        if State.isHoldingMouse then
            performMouseRelease()
            State.isHoldingMouse = false
            debugLog("Target lost/invalid hitbox, released mouse.")
        end
    end
end

--// Cursor Management //--
local function updateCursorLock()
    UserInputService.MouseBehavior = State.isEnabled and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
    --debugLog("Cursor lock state updated: " .. tostring(State.isEnabled))
end

--// Notification Helper //--
local function sendNotification(title, text, duration)
    local success, err = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = duration or 3
        })
    end)
    if not success then warn("[AutoClicker] Notification failed: " .. err) end
end

--// Toggle Control //--
local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Config.ToggleKey then
        State.isEnabled = not State.isEnabled

        sendNotification("Auto Clicker", State.isEnabled and "Enabled ✓" or "Disabled ✗", 2)
        updateCursorLock()

        if State.isEnabled then
            initializeESP()
            debugLog("Systems Activated")
        else
            clearESP()
            if State.isHoldingMouse then
                performMouseRelease()
                State.isHoldingMouse = false
            end
            debugLog("Systems Deactivated")
        end
    end
end

--// Cleanup Function //--
local function cleanup()
    debugLog("Cleaning up script...")
    clearESP()
    if ESPFolder and ESPFolder.Parent then ESPFolder:Destroy() end
    if State.isHoldingMouse then performMouseRelease() end
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
         UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
    -- Consider disconnecting top-level connections if stored in variables
end

--// Initialization Sequence //--
debugLog("Script initializing...")

updateCursorLock()
if State.isEnabled then initializeESP() else clearESP() end

local heartbeatConnection = RunService.Heartbeat:Connect(updateAutoHold)
local inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
local playerAddedConnection = Players.PlayerAdded:Connect(setupPlayerESP)
local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
    if player.Character then removeESP(player.Character) end
end)
local characterRemovingConnection = LocalPlayer.CharacterRemoving:Connect(function(character)
    if State.isHoldingMouse then
        performMouseRelease()
        State.isHoldingMouse = false
    end
end)
local teamChangedConnection = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    if not State.isEnabled then return end
    for character, data in pairs(espCache) do
       if data.Highlight then updateESPColor(character) end
    end
end)

sendNotification("System Ready", "AutoClicker & ESP initialized. Press " .. Config.ToggleKey.Name .. " to toggle.", 3)
debugLog("Systems initialized and running.")

-- game:BindToClose(cleanup)
