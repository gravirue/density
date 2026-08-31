-- Roblox LocalScript Tester
-- Studio-only test harness for Orbit, Snake, and Wings modes.
--
-- Place this LocalScript in:
-- StarterPlayer > StarterPlayerScripts
--
-- This script only runs in Roblox Studio and scans unanchored BaseParts
-- in Workspace, excluding the local player's character.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if not RunService:IsStudio() then
	warn("Roblox LocalScript Tester only runs in Roblox Studio.")
	return
end

local player = Players.LocalPlayer

-- Orbit settings
local orbitRadius = 20
local orbitSpeed = 1.5

-- Snake settings
local snakeWidth = 12
local snakeLength = 80
local snakeWaves = 2
local snakeSpeed = 2.5

-- Wings settings
local wingSpan = 24
local wingFlapHeight = 7
local wingFlapSpeed = 3

local minimumRadius = 5
local maximumRadius = 150
local minimumSnakeWidth = 1
local maximumSnakeWidth = 60
local minimumSnakeLength = 10
local maximumSnakeLength = 300

-- Available values: "Orbit", "Snake", "Wings", or nil.
local activeMode = "Orbit"

local parts = {}
local lastScan = 0
local scanInterval = 0.25

local radiusLabel
local countLabel
local radiusInput
local modeStatusLabel
local modeFrame
local orbitButton
local snakeButton
local wingsButton
local stopButton
local snakeWidthInput
local snakeLengthInput

local function getCharacter()
	return player.Character
end

local function refreshParts()
	table.clear(parts)

	local character = getCharacter()

	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("BasePart")
			and not object.Anchored
			and (not character or not object:IsDescendantOf(character)) then

			table.insert(parts, object)
		end
	end

	if countLabel then
		countLabel.Text = "Unanchored parts: " .. #parts
	end
end

local function getRootPart()
	local character = getCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function setRadius(value)
	local number = tonumber(value)

	if not number then
		return
	end

	orbitRadius = math.clamp(math.floor(number), minimumRadius, maximumRadius)
	radiusInput.Text = tostring(orbitRadius)
	radiusLabel.Text = "Orbit radius: " .. orbitRadius
end

local function applySnakeSettings()
	local width = tonumber(snakeWidthInput.Text)
	local length = tonumber(snakeLengthInput.Text)

	if width then
		snakeWidth = math.clamp(math.floor(width), minimumSnakeWidth, maximumSnakeWidth)
	end

	if length then
		snakeLength = math.clamp(math.floor(length), minimumSnakeLength, maximumSnakeLength)
	end

	snakeWidthInput.Text = tostring(snakeWidth)
	snakeLengthInput.Text = tostring(snakeLength)
end

local function updateModeUi()
	if not modeStatusLabel then
		return
	end

	if activeMode == "Orbit" then
		modeStatusLabel.Text = "Active mode: Orbit"
	elseif activeMode == "Snake" then
		modeStatusLabel.Text = "Active mode: Snake"
	elseif activeMode == "Wings" then
		modeStatusLabel.Text = "Active mode: Wings"
	else
		modeStatusLabel.Text = "Active mode: None"
	end

	local buttons = {
		{button = orbitButton, mode = "Orbit", label = "Orbit"},
		{button = snakeButton, mode = "Snake", label = "Snake"},
		{button = wingsButton, mode = "Wings", label = "Wings"},
	}

	for _, item in ipairs(buttons) do
		if activeMode == item.mode then
			item.button.BackgroundColor3 = Color3.fromRGB(45, 135, 85)
			item.button.Text = item.label .. ": ON"
		else
			item.button.BackgroundColor3 = Color3.fromRGB(70, 70, 82)
			item.button.Text = item.label
		end
	end

	if activeMode == nil then
		stopButton.BackgroundColor3 = Color3.fromRGB(160, 55, 55)
	else
		stopButton.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
	end

	local snakeSettings = modeFrame:FindFirstChild("SnakeSettings")
	if snakeSettings then
		snakeSettings.Visible = activeMode == "Snake"
	end
end

local function selectMode(mode)
	if activeMode == mode then
		-- Clicking the selected mode again is an emergency stop.
		activeMode = nil
	else
		activeMode = mode
	end

	updateModeUi()
end

local function movePart(part, position)
	if not part
		or not part.Parent
		or not part:IsA("BasePart")
		or part.Anchored then

		return
	end

	part.CFrame = CFrame.new(position) * part.CFrame.Rotation
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
end

local function updateOrbit(rootPart)
	local count = #parts
	if count == 0 then
		return
	end

	local time = os.clock() * orbitSpeed

	for index, part in ipairs(parts) do
		local angle = ((index - 1) / count) * math.pi * 2 + time
		local offset = Vector3.new(
			math.cos(angle) * orbitRadius,
			3,
			math.sin(angle) * orbitRadius
		)

		movePart(part, rootPart.Position + offset)
	end
end

local function updateSnake(rootPart)
	local count = #parts
	if count == 0 then
		return
	end

	local phase = os.clock() * snakeSpeed
	local right = rootPart.CFrame.RightVector
	local forward = rootPart.CFrame.LookVector

	for index, part in ipairs(parts) do
		local progress = count == 1 and 0.5 or (index - 1) / (count - 1)
		local forwardDistance = (progress - 0.5) * snakeLength
		local waveOffset = math.sin(
			progress * math.pi * 2 * snakeWaves + phase
		) * snakeWidth

		local targetPosition =
			rootPart.Position
			+ right * forwardDistance
			+ forward * waveOffset
			+ Vector3.new(0, 3, 0)

		movePart(part, targetPosition)
	end
end

local function updateWings(rootPart)
	local count = #parts
	if count == 0 then
		return
	end

	local right = rootPart.CFrame.RightVector
	local forward = rootPart.CFrame.LookVector
	local time = os.clock() * wingFlapSpeed
	local partsPerWing = math.ceil(count / 2)

	for index, part in ipairs(parts) do
		local side
		local wingIndex

		if index % 2 == 0 then
			side = 1
			wingIndex = index / 2
		else
			side = -1
			wingIndex = (index + 1) / 2
		end

		local progress = partsPerWing <= 1
			and 0.5
			or (wingIndex - 1) / (partsPerWing - 1)

		local sideDistance = 3 + progress * wingSpan
		local backwardSweep = -math.sin(progress * math.pi) * 8
		local flapStrength = 0.25 + progress * 0.75
		local flapOffset = math.sin(time + progress * 2)
			* wingFlapHeight
			* flapStrength
		local naturalHeight = 4 + math.sin(progress * math.pi) * 6

		local targetPosition =
			rootPart.Position
			+ right * side * sideDistance
			+ forward * backwardSweep
			+ Vector3.new(0, naturalHeight + flapOffset, 0)

		movePart(part, targetPosition)
	end
end

-- UI helpers
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LocalScriptModeTester"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function makeButton(parent, name, text, position, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(70, 70, 82)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.Parent = parent

	addCorner(button, 6)
	return button
end

local function makeTextBox(parent, name, text, position, size, placeholder)
	local textBox = Instance.new("TextBox")
	textBox.Name = name
	textBox.Text = text
	textBox.PlaceholderText = placeholder
	textBox.ClearTextOnFocus = false
	textBox.Size = size
	textBox.Position = position
	textBox.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 170)
	textBox.TextSize = 14
	textBox.Font = Enum.Font.Gotham
	textBox.Parent = parent

	addCorner(textBox, 6)
	return textBox
end

-- Main menu
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainMenu"
mainFrame.Size = UDim2.fromOffset(340, 240)
mainFrame.Position = UDim2.fromOffset(20, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
addCorner(mainFrame, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Text = "LocalScript Mode Tester"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

modeStatusLabel = Instance.new("TextLabel")
modeStatusLabel.Size = UDim2.new(1, -20, 0, 22)
modeStatusLabel.Position = UDim2.fromOffset(10, 38)
modeStatusLabel.BackgroundTransparency = 1
modeStatusLabel.TextColor3 = Color3.fromRGB(120, 220, 150)
modeStatusLabel.TextSize = 14
modeStatusLabel.Font = Enum.Font.Gotham
modeStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
modeStatusLabel.Parent = mainFrame

countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -20, 0, 20)
countLabel.Position = UDim2.fromOffset(10, 60)
countLabel.BackgroundTransparency = 1
countLabel.TextColor3 = Color3.fromRGB(175, 175, 185)
countLabel.TextSize = 13
countLabel.Font = Enum.Font.Gotham
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = mainFrame

radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(1, -20, 0, 22)
radiusLabel.Position = UDim2.fromOffset(10, 82)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Orbit radius: " .. orbitRadius
radiusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
radiusLabel.TextSize = 14
radiusLabel.Font = Enum.Font.Gotham
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Parent = mainFrame

radiusInput = makeTextBox(
	mainFrame,
	"RadiusInput",
	tostring(orbitRadius),
	UDim2.fromOffset(10, 108),
	UDim2.fromOffset(105, 32),
	"Radius"
)

local applyRadiusButton = makeButton(
	mainFrame,
	"ApplyRadius",
	"Apply",
	UDim2.fromOffset(122, 108),
	UDim2.fromOffset(70, 32)
)

local resetRadiusButton = makeButton(
	mainFrame,
	"ResetRadius",
	"Reset",
	UDim2.fromOffset(200, 108),
	UDim2.fromOffset(70, 32)
)

local decreaseRadiusButton = makeButton(
	mainFrame,
	"DecreaseRadius",
	"-",
	UDim2.fromOffset(10, 150),
	UDim2.fromOffset(70, 32)
)

local increaseRadiusButton = makeButton(
	mainFrame,
	"IncreaseRadius",
	"+",
	UDim2.fromOffset(88, 150),
	UDim2.fromOffset(70, 32)
)

local rescanButton = makeButton(
	mainFrame,
	"Rescan",
	"Rescan Parts",
	UDim2.fromOffset(166, 150),
	UDim2.fromOffset(104, 32)
)

local modesToggleButton = makeButton(
	mainFrame,
	"ModesToggle",
	"Modes",
	UDim2.fromOffset(10, 192),
	UDim2.fromOffset(260, 32)
)

-- Modes menu
modeFrame = Instance.new("Frame")
modeFrame.Name = "ModesMenu"
modeFrame.Size = UDim2.fromOffset(280, 330)
modeFrame.Position = UDim2.fromOffset(375, 20)
modeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
modeFrame.BorderSizePixel = 0
modeFrame.Visible = false
modeFrame.Parent = screenGui
addCorner(modeFrame, 10)

local modesTitle = Instance.new("TextLabel")
modesTitle.Size = UDim2.new(1, -20, 0, 28)
modesTitle.Position = UDim2.fromOffset(10, 8)
modesTitle.BackgroundTransparency = 1
modesTitle.Text = "Select Mode"
modesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
modesTitle.TextSize = 18
modesTitle.Font = Enum.Font.GothamBold
modesTitle.TextXAlignment = Enum.TextXAlignment.Left
modesTitle.Parent = modeFrame

orbitButton = makeButton(
	modeFrame,
	"OrbitMode",
	"Orbit",
	UDim2.fromOffset(10, 45),
	UDim2.fromOffset(260, 34)
)

snakeButton = makeButton(
	modeFrame,
	"SnakeMode",
	"Snake",
	UDim2.fromOffset(10, 85),
	UDim2.fromOffset(260, 34)
)

wingsButton = makeButton(
	modeFrame,
	"WingsMode",
	"Wings",
	UDim2.fromOffset(10, 125),
	UDim2.fromOffset(260, 34)
)

stopButton = makeButton(
	modeFrame,
	"StopMode",
	"Emergency Stop",
	UDim2.fromOffset(10, 165),
	UDim2.fromOffset(260, 34)
)

local snakeSettings = Instance.new("Frame")
snakeSettings.Name = "SnakeSettings"
snakeSettings.Size = UDim2.fromOffset(260, 105)
snakeSettings.Position = UDim2.fromOffset(10, 210)
snakeSettings.BackgroundTransparency = 1
snakeSettings.Visible = false
snakeSettings.Parent = modeFrame

local snakeSettingsTitle = Instance.new("TextLabel")
snakeSettingsTitle.Size = UDim2.new(1, 0, 0, 22)
snakeSettingsTitle.BackgroundTransparency = 1
snakeSettingsTitle.Text = "Snake settings"
snakeSettingsTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
snakeSettingsTitle.TextSize = 14
snakeSettingsTitle.Font = Enum.Font.GothamBold
snakeSettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
snakeSettingsTitle.Parent = snakeSettings

snakeWidthInput = makeTextBox(
	snakeSettings,
	"SnakeWidthInput",
	tostring(snakeWidth),
	UDim2.fromOffset(0, 28),
	UDim2.fromOffset(110, 32),
	"Width"
)

snakeLengthInput = makeTextBox(
	snakeSettings,
	"SnakeLengthInput",
	tostring(snakeLength),
	UDim2.fromOffset(120, 28),
	UDim2.fromOffset(140, 32),
	"Size"
)

local applySnakeButton = makeButton(
	snakeSettings,
	"ApplySnakeSettings",
	"Apply Snake Settings",
	UDim2.fromOffset(0, 68),
	UDim2.fromOffset(260, 32)
)

-- UI events
applyRadiusButton.Activated:Connect(function()
	setRadius(radiusInput.Text)
end)

radiusInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		setRadius(radiusInput.Text)
	end
end)

resetRadiusButton.Activated:Connect(function()
	setRadius(20)
end)

decreaseRadiusButton.Activated:Connect(function()
	setRadius(orbitRadius - 5)
end)

increaseRadiusButton.Activated:Connect(function()
	setRadius(orbitRadius + 5)
end)

rescanButton.Activated:Connect(refreshParts)

modesToggleButton.Activated:Connect(function()
	modeFrame.Visible = not modeFrame.Visible
end)

orbitButton.Activated:Connect(function()
	selectMode("Orbit")
end)

snakeButton.Activated:Connect(function()
	selectMode("Snake")
end)

wingsButton.Activated:Connect(function()
	selectMode("Wings")
end)

stopButton.Activated:Connect(function()
	activeMode = nil
	updateModeUi()
end)

applySnakeButton.Activated:Connect(applySnakeSettings)

snakeWidthInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		applySnakeSettings()
	end
end)

snakeLengthInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		applySnakeSettings()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftBracket then
		setRadius(orbitRadius - 5)
	elseif input.KeyCode == Enum.KeyCode.RightBracket then
		setRadius(orbitRadius + 5)
	elseif input.KeyCode == Enum.KeyCode.M then
		modeFrame.Visible = not modeFrame.Visible
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	refreshParts()
end)

refreshParts()
updateModeUi()

RunService.RenderStepped:Connect(function()
	local currentTime = os.clock()

	if currentTime - lastScan >= scanInterval then
		lastScan = currentTime
		refreshParts()
	end

	local rootPart = getRootPart()

	if not rootPart or not activeMode then
		return
	end

	if activeMode == "Orbit" then
		updateOrbit(rootPart)
	elseif activeMode == "Snake" then
		updateSnake(rootPart)
	elseif activeMode == "Wings" then
		updateWings(rootPart)
	end
end)