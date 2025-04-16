local fov = 136
local RunService = game:GetService(RunService)
local UserInputService = game:GetService(UserInputService)
local Cam = workspace.CurrentCamera
local Players = game:GetService(Players)
local LocalPlayer = Players.LocalPlayer

local FOVring = Drawing.new(Circle)
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 128)
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2

local isAiming = false
local validPlayers = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local ScreenGui = Instance.new(ScreenGui)
ScreenGui.Parent = game.CoreGui

local ToggleButton = Instance.new(TextButton)
ToggleButton.Size = UDim2.new(0, 120, 0, 40)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.Text = AIMBOT: OFF
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.TextColor3 = Color3.fromRGB(255, 50, 50)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.Parent = ScreenGui

local function isValidPlayerCharacter(character)
    if not character or not character:IsA(Model) then return false end
    if character == LocalPlayer.Character then return false end
    local player = Players:GetPlayerFromCharacter(character)
    return player and character:FindFirstChild(Humanoid) and character.Humanoid.Health > 0 and character:FindFirstChild(Head) and character:FindFirstChild(HumanoidRootPart)
end

local function updatePlayers()
    validPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isValidPlayerCharacter(player.Character) then
            table.insert(validPlayers, player.Character)
        end
    end
end

local function updateDrawings()
    FOVring.Position = Cam.ViewportSize / 2
    FOVring.Radius = fov * (Cam.ViewportSize.Y / 1080)
end

local function predictPos(target)
    local rootPart = target:FindFirstChild(HumanoidRootPart)
    local head = target:FindFirstChild(Head)
    if not rootPart or not head then return end
    local velocity = rootPart.Velocity
    local predictionTime = 0.02
    local basePosition = rootPart.Position + velocity * predictionTime
    local headOffset = head.Position - rootPart.Position
    return basePosition + headOffset
end

local function getTarget()
    local nearest = nil
    local minDistance = math.huge
    local viewportCenter = Cam.ViewportSize / 2
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

    for _, character in ipairs(validPlayers) do
        local predictedPos = predictPos(character)
        if predictedPos then
            local screenPos, visible = Cam:WorldToViewportPoint(predictedPos)
            if visible and screenPos.Z > 0 then
                local ray = workspace:Raycast(Cam.CFrame.Position, (predictedPos - Cam.CFrame.Position).Unit * 1000, raycastParams)
                if ray and ray.Instance:IsDescendantOf(character) then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                    if distance < minDistance and distance < fov then
                        minDistance = distance
                        nearest = character
                    end
                end
            end
        end
    end
    return nearest
end

local function aim(targetPosition)
    local currentCF = Cam.CFrame
    local targetDirection = (targetPosition - currentCF.Position).Unit
    local smoothFactor = 0.581
    local newLookVector = currentCF.LookVector:Lerp(targetDirection, smoothFactor)
    Cam.CFrame = CFrame.new(currentCF.Position, currentCF.Position + newLookVector)
end

local lastUpdate = 0
local UPDATE_INTERVAL = 0.4

RunService.Heartbeat:Connect(function(dt)
    updateDrawings()
    lastUpdate += dt
    if lastUpdate >= UPDATE_INTERVAL then
        updatePlayers()
        lastUpdate = 0
    end
    if isAiming then
        local target = getTarget()
        if target then
            local predictedPosition = predictPos(target)
            aim(predictedPosition)
        end
    end
end)

local function toggleAimbot()
    isAiming = not isAiming
    FOVring.Visible = isAiming
    ToggleButton.Text = AIMBOT:  .. (isAiming and ON or OFF)
    ToggleButton.TextColor3 = isAiming and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
end

ToggleButton.MouseButton1Click:Connect(toggleAimbot)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.T then
        toggleAimbot()
    end
end)

-- Dragging UI
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Character and table.find(validPlayers, player.Character) then
        for i = #validPlayers, 1, -1 do
            if validPlayers[i] == player.Character then
                table.remove(validPlayers, i)
                break
            end
        end
    end
end)

game:BindToClose(function()
    FOVring:Remove()
    ScreenGui:Destroy()
end)
