-- Roblox Map Explorer - Development Tool
-- Execute this script to explore and teleport to all parts in your map

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Main GUI variables
local mainGui = nil
local isOpen = false
local currentFilter = "All"

-- Create notification function
local function createNotification(message, color)
    local gui = Instance.new("ScreenGui")
    gui.Name = "DevNotification"
    gui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 50)
    frame.Position = UDim2.new(1, -320, 0, 20)
    frame.BackgroundColor3 = color or Color3.fromRGB(46, 46, 46)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 1, 0)
    text.Position = UDim2.new(0, 10, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = message
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextScaled = true
    text.Font = Enum.Font.Gotham
    text.Parent = frame
    
    -- Slide in animation
    frame:TweenPosition(UDim2.new(1, -320, 0, 20), "Out", "Quart", 0.3, true)
    
    -- Auto remove after 2 seconds
    game:GetService("Debris"):AddItem(gui, 2)
end

-- Get all parts in workspace with detailed info
local function getAllParts()
    local parts = {}
    
    local function scanObject(obj, depth)
        depth = depth or 0
        if depth > 50 then return end -- Prevent infinite recursion
        
        -- Add current object if it's relevant
        if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Folder") then
            local partInfo = {
                object = obj,
                name = obj.Name,
                className = obj.ClassName,
                parent = obj.Parent and obj.Parent.Name or "Workspace",
                position = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position) or Vector3.new(0, 0, 0),
                size = obj:IsA("BasePart") and obj.Size or Vector3.new(0, 0, 0),
                material = obj:IsA("BasePart") and obj.Material.Name or "N/A",
                color = obj:IsA("BasePart") and obj.Color or Color3.new(1, 1, 1),
                children = #obj:GetChildren(),
                path = obj:GetFullName(),
                depth = depth
            }
            
            -- Skip certain objects
            if not (obj.Name == "Camera" or obj.Name == "Terrain" or obj:IsA("Player") or obj:IsDescendantOf(playerGui)) then
                table.insert(parts, partInfo)
            end
        end
        
        -- Recursively scan children
        for _, child in pairs(obj:GetChildren()) do
            scanObject(child, depth + 1)
        end
    end
    
    scanObject(workspace)
    return parts
end

-- Teleport function
local function teleportToPart(partInfo)
    local character = player.Character
    if not character or not character.PrimaryPart then
        createNotification("❌ Character not found!", Color3.fromRGB(255, 100, 100))
        return
    end
    
    local targetPosition
    if partInfo.object:IsA("BasePart") then
        targetPosition = partInfo.object.Position + Vector3.new(0, partInfo.object.Size.Y/2 + 5, 0)
    elseif partInfo.object:IsA("Model") and partInfo.object.PrimaryPart then
        targetPosition = partInfo.object.PrimaryPart.Position + Vector3.new(0, 10, 0)
    else
        -- Try to find a BasePart in the object
        local basePart = partInfo.object:FindFirstChildOfClass("BasePart", true)
        if basePart then
            targetPosition = basePart.Position + Vector3.new(0, basePart.Size.Y/2 + 5, 0)
        else
            targetPosition = partInfo.position + Vector3.new(0, 10, 0)
        end
    end
    
    character:SetPrimaryPartCFrame(CFrame.new(targetPosition))
    createNotification("🚀 Teleported to: " .. partInfo.name, Color3.fromRGB(100, 255, 100))
end

-- Create part list item
local function createPartListItem(partInfo, parent)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -5, 0, 60)
    container.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container
    
    -- Indent based on depth
    local indentSize = math.min(partInfo.depth * 10, 50)
    
    -- Icon based on type
    local icon = "📦"
    if partInfo.object:IsA("BasePart") then
        if partInfo.object.Name:lower():find("floor") or partInfo.object.Name:lower():find("ground") then
            icon = "🟫"
        elseif partInfo.object.Name:lower():find("wall") then
            icon = "🧱"
        elseif partInfo.object.Name:lower():find("door") then
            icon = "🚪"
        else
            icon = "⬜"
        end
    elseif partInfo.object:IsA("Model") then
        icon = "🏗️"
    elseif partInfo.object:IsA("Folder") then
        icon = "📁"
    end
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.4, -indentSize, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 5 + indentSize, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = icon .. " " .. partInfo.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = container
    
    -- Type label
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
    typeLabel.Position = UDim2.new(0.4, 0, 0, 0)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = partInfo.className
    typeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    typeLabel.TextScaled = true
    typeLabel.Font = Enum.Font.Gotham
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.Parent = container
    
    -- Position info
    local positionLabel = Instance.new("TextLabel")
    positionLabel.Size = UDim2.new(1, -10, 0.5, 0)
    positionLabel.Position = UDim2.new(0, 5 + indentSize, 0.5, 0)
    positionLabel.BackgroundTransparency = 1
    if partInfo.object:IsA("BasePart") then
        positionLabel.Text = string.format("Pos: %.1f, %.1f, %.1f | Size: %.1f, %.1f, %.1f", 
            partInfo.position.X, partInfo.position.Y, partInfo.position.Z,
            partInfo.size.X, partInfo.size.Y, partInfo.size.Z)
    else
        positionLabel.Text = string.format("Children: %d | Path: %s", 
            partInfo.children, partInfo.parent)
    end
    positionLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    positionLabel.TextScaled = true
    positionLabel.Font = Enum.Font.Gotham
    positionLabel.TextXAlignment = Enum.TextXAlignment.Left
    positionLabel.Parent = container
    
    -- Teleport button
    local teleportBtn = Instance.new("TextButton")
    teleportBtn.Size = UDim2.new(0, 80, 0, 25)
    teleportBtn.Position = UDim2.new(1, -85, 0, 5)
    teleportBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    teleportBtn.BorderSizePixel = 0
    teleportBtn.Text = "🚀 Go"
    teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportBtn.TextScaled = true
    teleportBtn.Font = Enum.Font.GothamBold
    teleportBtn.Parent = container
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = teleportBtn
    
    -- Info button
    local infoBtn = Instance.new("TextButton")
    infoBtn.Size = UDim2.new(0, 80, 0, 25)
    infoBtn.Position = UDim2.new(1, -85, 0.5, 5)
    infoBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    infoBtn.BorderSizePixel = 0
    infoBtn.Text = "ℹ️ Info"
    infoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoBtn.TextScaled = true
    infoBtn.Font = Enum.Font.GothamBold
    infoBtn.Parent = container
    
    local infoBtnCorner = Instance.new("UICorner")
    infoBtnCorner.CornerRadius = UDim.new(0, 4)
    infoBtnCorner.Parent = infoBtn
    
    -- Button events
    teleportBtn.MouseButton1Click:Connect(function()
        teleportToPart(partInfo)
    end)
    
    infoBtn.MouseButton1Click:Connect(function()
        local infoText = string.format("Name: %s\nType: %s\nParent: %s\nChildren: %d\nPath: %s", 
            partInfo.name, partInfo.className, partInfo.parent, partInfo.children, partInfo.path)
        createNotification(infoText, Color3.fromRGB(100, 150, 255))
    end)
    
    -- Hover effects
    local function onHover()
        container.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end
    
    local function onLeave()
        container.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end
    
    container.MouseEnter:Connect(onHover)
    container.MouseLeave:Connect(onLeave)
    
    return container
end

-- Create main GUI
local function createMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MapExplorerGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Fix title bar bottom corners
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 25)
    titleFix.Position = UDim2.new(0, 0, 1, -25)
    titleFix.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -200, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🗺️ Map Explorer - Development Tool"
    title.TextColor3 = Color3.fromRGB(100, 200, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Refresh button
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 80, 0, 35)
    refreshBtn.Position = UDim2.new(1, -170, 0, 7.5)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Text = "🔄 Refresh"
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.TextScaled = true
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.Parent = titleBar
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 6)
    refreshCorner.Parent = refreshBtn
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -45, 0, 7.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    -- Filter bar
    local filterFrame = Instance.new("Frame")
    filterFrame.Size = UDim2.new(1, 0, 0, 40)
    filterFrame.Position = UDim2.new(0, 0, 0, 50)
    filterFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    filterFrame.BorderSizePixel = 0
    filterFrame.Parent = mainFrame
    
    -- Search box
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(0, 300, 0, 30)
    searchBox.Position = UDim2.new(0, 10, 0, 5)
    searchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    searchBox.BorderSizePixel = 0
    searchBox.PlaceholderText = "🔍 Search parts..."
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextScaled = true
    searchBox.Font = Enum.Font.Gotham
    searchBox.Parent = filterFrame
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchBox
    
    -- Filter buttons
    local filters = {"All", "Parts", "Models", "Folders"}
    local filterButtons = {}
    
    for i, filterName in ipairs(filters) do
        local filterBtn = Instance.new("TextButton")
        filterBtn.Size = UDim2.new(0, 80, 0, 30)
        filterBtn.Position = UDim2.new(0, 320 + (i-1) * 85, 0, 5)
        filterBtn.BackgroundColor3 = filterName == "All" and Color3.fromRGB(70, 130, 180) or Color3.fromRGB(60, 60, 60)
        filterBtn.BorderSizePixel = 0
        filterBtn.Text = filterName
        filterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        filterBtn.TextScaled = true
        filterBtn.Font = Enum.Font.Gotham
        filterBtn.Parent = filterFrame
        
        local filterCorner = Instance.new("UICorner")
        filterCorner.CornerRadius = UDim.new(0, 6)
        filterCorner.Parent = filterBtn
        
        filterButtons[filterName] = filterBtn
    end
    
    -- Parts list
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(1, -10, 1, -100)
    listFrame.Position = UDim2.new(0, 5, 0, 90)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 8
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    listFrame.Parent = mainFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 3)
    listLayout.Parent = listFrame
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 1, -25)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Loading parts..."
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = mainFrame
    
    -- Populate list function
    local function populateList(searchTerm)
        -- Clear existing items
        for _, child in pairs(listFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        local parts = getAllParts()
        local filteredParts = {}
        
        -- Apply filters
        for _, partInfo in ipairs(parts) do
            local passesFilter = true
            
            -- Type filter
            if currentFilter == "Parts" and not partInfo.object:IsA("BasePart") then
                passesFilter = false
            elseif currentFilter == "Models" and not partInfo.object:IsA("Model") then
                passesFilter = false
            elseif currentFilter == "Folders" and not partInfo.object:IsA("Folder") then
                passesFilter = false
            end
            
            -- Search filter
            if searchTerm and searchTerm ~= "" then
                local searchLower = searchTerm:lower()
                if not (partInfo.name:lower():find(searchLower) or 
                       partInfo.className:lower():find(searchLower) or
                       partInfo.path:lower():find(searchLower)) then
                    passesFilter = false
                end
            end
            
            if passesFilter then
                table.insert(filteredParts, partInfo)
            end
        end
        
        -- Create list items
        for _, partInfo in ipairs(filteredParts) do
            createPartListItem(partInfo, listFrame)
        end
        
        -- Update canvas size
        listFrame.CanvasSize = UDim2.new(0, 0, 0, #filteredParts * 63)
        statusLabel.Text = string.format("Found %d items (Total: %d)", #filteredParts, #parts)
    end
    
    -- Event connections
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        isOpen = false
    end)
    
    refreshBtn.MouseButton1Click:Connect(function()
        populateList(searchBox.Text)
    end)
    
    searchBox.Changed:Connect(function(property)
        if property == "Text" then
            populateList(searchBox.Text)
        end
    end)
    
    -- Filter button events
    for filterName, filterBtn in pairs(filterButtons) do
        filterBtn.MouseButton1Click:Connect(function()
            -- Reset all buttons
            for _, btn in pairs(filterButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
            -- Highlight selected
            filterBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
            currentFilter = filterName
            populateList(searchBox.Text)
        end)
    end
    
    -- Initial population
    populateList()
    
    mainGui = screenGui
    isOpen = true
    
    return screenGui
end

-- Toggle function
local function toggleExplorer()
    if isOpen and mainGui then
        mainGui:Destroy()
        mainGui = nil
        isOpen = false
    else
        createMainGUI()
    end
end

-- Keybind (F1 to toggle)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        toggleExplorer()
    end
end)

-- Auto-open on execution
createMainGUI()
createNotification("🗺️ Map Explorer loaded! Press F1 to toggle.", Color3.fromRGB(100, 255, 100))
createNotification("🚀 Click 'Go' to teleport to any part in your map!", Color3.fromRGB(100, 200, 255))

print("🗺️ Map Explorer Development Tool loaded!")
print("📝 Press F1 to toggle the explorer window")
print("🔍 Use search and filters to find specific parts")
print("🚀 Click 'Go' button to teleport to any part")
