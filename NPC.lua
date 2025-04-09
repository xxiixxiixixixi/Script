local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- GUI setup
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "NPCScannerUI"

local npcLabel = Instance.new("TextLabel", screenGui)
npcLabel.Size = UDim2.new(1, 0, 0, 100)
npcLabel.Position = UDim2.new(0, 0, 1, -100)
npcLabel.BackgroundTransparency = 1
npcLabel.TextColor3 = Color3.new(1, 1, 1)
npcLabel.TextStrokeTransparency = 0.5
npcLabel.TextScaled = true
npcLabel.Font = Enum.Font.SourceSansBold
npcLabel.Text = "NPCs in view:"

-- Проверка, является ли объект NPC
local function isNPC(obj)
	return obj:IsA("Model")
		and obj:FindFirstChild("Humanoid")
		and obj:FindFirstChild("Head")
		and not Players:GetPlayerFromCharacter(obj)
end

-- Обновление списка NPC в поле зрения
local function updateNPCList()
	local npcNames = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if isNPC(obj) then
			local head = obj:FindFirstChild("Head")
			if head then
				local screenPos, onScreen = Cam:WorldToViewportPoint(head.Position)
				if onScreen and screenPos.Z > 0 then
					table.insert(npcNames, obj.Name)
				end
			end
		end
	end
	npcLabel.Text = #npcNames > 0 and "NPCs in view:\n" .. table.concat(npcNames, "\n") or "No NPCs in view"
end

-- Подключаем к RenderStepped
RunService.RenderStepped:Connect(updateNPCList)
