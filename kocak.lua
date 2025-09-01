--[[
  UNIVERSAL AIR WALK SCRIPT (DELTA MOBILE)
  Fitur:
  ✅ GUI ON/OFF muncul di semua game
  ✅ Bisa di-drag & resize
  ✅ Auto-off saat nabrak bangunan (pakai raycast, bukan touched)
  ✅ Kompatibel Delta Mobile
--]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local airwalk = false
local speed = 50

-- GUI Setup pakai CoreGui supaya tidak diblokir
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AirWalkGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = gethui and gethui() or game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 60)
frame.Position = UDim2.new(0.05, 0, 0.8, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -10, 0.6, 0)
toggleButton.Position = UDim2.new(0, 5, 0, 5)
toggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextScaled = true
toggleButton.Text = "Air Walk: OFF"
toggleButton.Parent = frame

local resizeButton = Instance.new("TextButton")
resizeButton.Size = UDim2.new(1, -10, 0.3, 0)
resizeButton.Position = UDim2.new(0, 5, 0.65, 0)
resizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
resizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resizeButton.Font = Enum.Font.Gotham
resizeButton.TextScaled = true
resizeButton.Text = "Resize GUI"
resizeButton.Parent = frame

-- Fungsi toggle Air Walk
local function toggleAirWalk(state)
    airwalk = state
    if airwalk then
        toggleButton.Text = "Air Walk: ON ✅"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        toggleButton.Text = "Air Walk: OFF ❌"
        toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        rootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

toggleButton.MouseButton1Click:Connect(function()
    toggleAirWalk(not airwalk)
end)

-- Resize GUI
resizeButton.MouseButton1Click:Connect(function()
    if frame.Size == UDim2.new(0, 180, 0, 60) then
        frame.Size = UDim2.new(0, 120, 0, 40)
    else
        frame.Size = UDim2.new(0, 180, 0, 60)
    end
end)

-- Air Walk Movement
RunService.Heartbeat:Connect(function()
    if airwalk and character and rootPart and humanoid then
        local moveDir = humanoid.MoveDirection
        rootPart.Velocity = Vector3.new(moveDir.X * speed, 2, moveDir.Z * speed)
    end
end)

-- Auto OFF saat nabrak bangunan (pakai raycast)
RunService.Stepped:Connect(function()
    if airwalk and rootPart then
        local rayOrigin = rootPart.Position
        local rayDirection = rootPart.CFrame.LookVector * 3
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

        local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
            toggleAirWalk(false)
        end
    end
end)

-- Respawn Support
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    toggleAirWalk(false)
end)
