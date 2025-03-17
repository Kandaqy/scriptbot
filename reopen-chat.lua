local TextChatService = game:GetService("TextChatService")

-- Function to ensure chat window is enabled
local function enableChatWindow()
    local ChatWindowConfiguration = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
    
    if ChatWindowConfiguration then
        ChatWindowConfiguration.Enabled = true
    end
end

-- Initial enable
enableChatWindow()

-- Monitor for changes
TextChatService.ChildAdded:Connect(function(child)
    if child:IsA("ChatWindowConfiguration") then
        enableChatWindow()
    end
end)

-- Monitor for property changes on existing ChatWindowConfiguration
local function setupPropertyWatch(config)
    config:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not config.Enabled then
            config.Enabled = true
        end
    end)
end

-- Set up watching for existing configuration
local currentConfig = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
if currentConfig then
    setupPropertyWatch(currentConfig)
end

-- Watch for new configurations
TextChatService.ChildAdded:Connect(function(child)
    if child:IsA("ChatWindowConfiguration") then
        setupPropertyWatch(child)
    end
end)