--[[
	Mirror Movement Script – Natural Jump & Improved Walking
	----------------------------------------------------------
	This script creates a draggable GUI with:
	  • A title ("Mirror Movement")
	  • A TextBox to enter a username/display name.
	  • A "Mirror" button to start/stop mirroring.
	  • A close ("X") button to terminate the script.
	
	When you click "Mirror":
	  1. It finds the target player.
	  2. Teleports your character in front of the target.
	  3. Records the initial HRP CFrames.
	  4. Creates BodyPosition and BodyGyro on your HRP to drive movement.
	     - The BodyPosition is set to control full position when on the ground,
	       but only horizontal (X,Z) when your humanoid is jumping/freefalling,
	       letting natural vertical physics (and jump impulse) take over.
	     - The BodyGyro rotates your character to mirror the target’s rotation.
	  5. Every Heartbeat, it computes the target’s relative transformation,
	     mirrors the left/right (X) components, and applies that to your initial HRP CFrame.
	  6. It triggers a natural jump: if the target is jumping/freefalling and you aren’t,
	     it sets your humanoid’s Jump flag (only once per jump).
	  7. It also computes your HRP velocity to call Humanoid:Move() so the walking animation plays.
	
	Click the "X" button to immediately disable the mirror and remove the GUI.
	
	Feel free to tweak the BodyMover properties (P, D, MaxForce) as needed.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local mirroringActive = false
local targetPlayer = nil
local targetCF0, myCF0  -- initial CFrames for target and local HRP
local previousPos     -- for calculating velocity
local mirrorConnection = nil

-- BodyMover references (will be created on the HRP)
local bp  -- BodyPosition
local bg  -- BodyGyro

-------------------------------------------------
-- Create the GUI
-------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MirrorMovementGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 150)
frame.Position = UDim2.new(0.5, -150, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true          -- allows dragging
frame.Draggable = true       -- make the UI draggable
frame.Parent = screenGui

-- Title Label
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Mirror Movement"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Parent = frame

-- Close Button ("X")
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Parent = frame

-- Input TextBox for username/display name
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0.8, 0, 0, 30)
inputBox.Position = UDim2.new(0.1, 0, 0.4, 0)
inputBox.PlaceholderText = "Enter username/display name"
inputBox.ClearTextOnFocus = false
inputBox.Parent = frame

-- Mirror Button
local mirrorButton = Instance.new("TextButton")
mirrorButton.Size = UDim2.new(0.5, 0, 0, 30)
mirrorButton.Position = UDim2.new(0.25, 0, 0.7, 0)
mirrorButton.Text = "Mirror"
mirrorButton.TextScaled = true
mirrorButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
mirrorButton.Parent = frame

-------------------------------------------------
-- Utility: Find player by username/display name (case-insensitive)
-------------------------------------------------
local function findPlayerByName(name)
	name = name:lower()
	for _, player in pairs(Players:GetPlayers()) do
		if player.Name:lower() == name or player.DisplayName:lower() == name then
			return player
		end
	end
	return nil
end

-------------------------------------------------
-- Cleanup BodyMovers from HRP
-------------------------------------------------
local function cleanupMovers(hrp)
	if hrp:FindFirstChild("MirrorBodyPosition") then
		hrp.MirrorBodyPosition:Destroy()
	end
	if hrp:FindFirstChild("MirrorBodyGyro") then
		hrp.MirrorBodyGyro:Destroy()
	end
end

-------------------------------------------------
-- Stop mirroring and cleanup everything
-------------------------------------------------
local function stopMirroring()
	mirroringActive = false
	if mirrorConnection then
		mirrorConnection:Disconnect()
		mirrorConnection = nil
	end
	-- Re-enable auto-rotate and cleanup movers
	if localPlayer.Character then
		local myHRP = localPlayer.Character:FindFirstChild("HumanoidRootPart")
		local myHumanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if myHumanoid then
			myHumanoid.AutoRotate = true
		end
		if myHRP then
			cleanupMovers(myHRP)
		end
	end
	-- Update button text if GUI is still visible
	if mirrorButton then
		mirrorButton.Text = "Mirror"
	end
end

-------------------------------------------------
-- Start mirroring: set up BodyMovers and update each frame.
-------------------------------------------------
local function startMirroring(target)
	-- Check target's character and HRP.
	if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
		warn("Target's character not found!")
		return
	end
	local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
	local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
	
	-- Check local player's character and HRP.
	local myChar = localPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
		warn("Your character not found!")
		return
	end
	local myHRP = myChar:FindFirstChild("HumanoidRootPart")
	local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
	
	-- Disable auto-rotate (we control rotation via BodyGyro)
	if myHumanoid then
		myHumanoid.AutoRotate = false
	end
	
	-- Teleport your character in front of the target (offset by 5 studs)
	local offset = 5
	local newPos = targetHRP.Position + (targetHRP.CFrame.LookVector * offset)
	myHRP.CFrame = CFrame.new(newPos, targetHRP.Position)
	
	-- Record the initial CFrames.
	targetCF0 = targetHRP.CFrame
	myCF0 = myHRP.CFrame
	
	-- Cleanup any previous movers.
	cleanupMovers(myHRP)
	
	-- Create BodyPosition and BodyGyro on your HRP.
	bp = Instance.new("BodyPosition")
	bp.Name = "MirrorBodyPosition"
	-- We'll update MaxForce each frame based on whether we're jumping.
	bp.P = 3000
	bp.D = 200
	bp.Parent = myHRP
	
	bg = Instance.new("BodyGyro")
	bg.Name = "MirrorBodyGyro"
	bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bg.P = 3000
	bg.CFrame = myHRP.CFrame
	bg.Parent = myHRP
	
	-- Initialize previous position for velocity calculation.
	previousPos = myHRP.Position
	
	mirroringActive = true
	
	-- Begin the mirror loop.
	mirrorConnection = RunService.Heartbeat:Connect(function(dt)
		if not mirroringActive then
			return
		end
		
		-- Verify both characters still exist.
		if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
			warn("Target character lost. Stopping mirror.")
			stopMirroring()
			return
		end
		if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
			warn("Your character lost. Stopping mirror.")
			stopMirroring()
			return
		end
		
		-- Update references.
		targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
		myHRP = localPlayer.Character:FindFirstChild("HumanoidRootPart")
		myHumanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
		
		-- Compute target's relative transformation from its initial state.
		local targetRelCF = targetCF0:ToObjectSpace(targetHRP.CFrame)
		-- Mirror the translation: invert the X (left/right) component.
		local mirroredTrans = Vector3.new(-targetRelCF.Position.X, targetRelCF.Position.Y, targetRelCF.Position.Z)
		-- Mirror rotation by inverting the local right vector.
		local origRight = targetRelCF.XVector
		local origUp = targetRelCF.YVector
		local origLook = targetRelCF.ZVector
		local mirroredRot = CFrame.fromMatrix(Vector3.new(), -origRight, origUp, origLook)
		-- Combined mirrored relative CFrame.
		local mirroredRelCF = CFrame.new(mirroredTrans) * mirroredRot
		-- Compute the new desired CFrame for your HRP.
		local newMyCF = myCF0 * mirroredRelCF
		
		-- Update BodyGyro to match desired rotation.
		if bg then
			bg.CFrame = newMyCF
		end
		
		-- Decide how to update BodyPosition:
		-- If our humanoid is jumping/freefalling, let natural physics control vertical movement.
		local currentY = myHRP.Position.Y
		if myHumanoid and (myHumanoid:GetState() == Enum.HumanoidStateType.Jumping or myHumanoid:GetState() == Enum.HumanoidStateType.Freefall) then
			-- Only control horizontal (X,Z); set Y to current value.
			bp.Position = Vector3.new(newMyCF.Position.X, currentY, newMyCF.Position.Z)
			-- Remove vertical force so natural jump physics take over.
			bp.MaxForce = Vector3.new(1e5, 0, 1e5)
		else
			-- Control full position.
			bp.Position = newMyCF.Position
			bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		end
		
		-- Trigger natural jump:
		-- If target is in a jump/freefall state and we're not already jumping, then trigger jump.
		if targetHumanoid and myHumanoid then
			local targetState = targetHumanoid:GetState()
			local myState = myHumanoid:GetState()
			if (targetState == Enum.HumanoidStateType.Jumping or targetState == Enum.HumanoidStateType.Freefall)
			   and (myState ~= Enum.HumanoidStateType.Jumping and myState ~= Enum.HumanoidStateType.Freefall) then
				myHumanoid.Jump = true
			end
		end
		
		-- Calculate velocity for walking animation.
		local currentPos = myHRP.Position
		local velocity = Vector3.new(0, 0, 0)
		if dt > 0 then
			velocity = (currentPos - previousPos) / dt
		end
		previousPos = currentPos
		
		-- Use horizontal velocity to trigger proper walking animations.
		if myHumanoid then
			local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
			if horizontalVelocity.Magnitude > 0.1 then
				myHumanoid:Move(horizontalVelocity, false)
			else
				myHumanoid:Move(Vector3.new(0,0,0), false)
			end
		end
	end)
end

-------------------------------------------------
-- Mirror Button Click: Start/Stop mirroring.
-------------------------------------------------
mirrorButton.MouseButton1Click:Connect(function()
	if mirroringActive then
		stopMirroring()
		mirrorButton.Text = "Mirror"
		return
	end
	
	local targetName = inputBox.Text
	if targetName == "" then
		warn("Please enter a username or display name!")
		return
	end
	local foundPlayer = findPlayerByName(targetName)
	if not foundPlayer then
		warn("Player not found!")
		return
	end
	targetPlayer = foundPlayer
	mirrorButton.Text = "Stop Mirror"
	startMirroring(targetPlayer)
end)

-------------------------------------------------
-- Close Button Click: Terminate mirroring and remove GUI.
-------------------------------------------------
closeButton.MouseButton1Click:Connect(function()
	stopMirroring()
	screenGui:Destroy()
end)
