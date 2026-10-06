local SCRIPT_URL = "https://raw.githubusercontent.com/lingxingpubg-bit/souldrain/refs/heads/main/souldrain.lua"

--// Re-queue after teleport
if queue_on_teleport then
	queue_on_teleport([[
		loadstring(game:HttpGet("https://raw.githubusercontent.com/lingxingpubg-bit/souldrain/refs/heads/main/souldrain.lua"))()
	]])
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

-- Soul Drain
local Enabled = true
local Mode = "Both"
local TriggerMode = "Manual" -- "Automatic" or "Manual"
local Q_E_Delay = 1
local running = false

-- Teleport
local TargetName = "ANiceUser52"
local TeleportEnabled = false
local TeleportInterval = 0.02

--==================================================
-- KEY PRESS
--==================================================

local function pressKey(key)
	VirtualInputManager:SendKeyEvent(true, key, false, game)
	VirtualInputManager:SendKeyEvent(false, key, false, game)
end

--==================================================
-- MAIN GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SoulDrainAutomation"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 180, 0, 370)

-- Same general left-side location
MainFrame.Position = UDim2.new(0.02, 0, 0.02, 100)

MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

--==================================================
-- DRAGGING
--==================================================

local dragging = false
local dragStart
local startPos

local function updateDrag(input)
	local delta = input.Position - dragStart

	MainFrame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

MainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	) then
		updateDrag(input)
	end
end)

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 28)
Title.BackgroundTransparency = 1
Title.Text = "Soul Drain Q/E"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

--==================================================
-- SOUL DRAIN ENABLE
--==================================================

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1, -10, 0, 32)
Toggle.Position = UDim2.new(0, 5, 0, 30)
Toggle.TextSize = 14
Toggle.Font = Enum.Font.SourceSansBold
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.Parent = MainFrame

local function updateToggle()
	if Enabled then
		Toggle.Text = "ENABLED"
		Toggle.BackgroundColor3 = Color3.fromRGB(50, 170, 70)
	else
		Toggle.Text = "DISABLED"
		Toggle.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
	end
end

Toggle.MouseButton1Click:Connect(function()
	Enabled = not Enabled
	updateToggle()
end)

updateToggle()

--==================================================
-- BOTH / SINGLE
--==================================================

local ModeButton = Instance.new("TextButton")
ModeButton.Size = UDim2.new(1, -10, 0, 30)
ModeButton.Position = UDim2.new(0, 5, 0, 67)
ModeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeButton.TextSize = 14
ModeButton.Font = Enum.Font.SourceSansBold
ModeButton.Parent = MainFrame

local function updateMode()
	ModeButton.Text = Mode
end

ModeButton.MouseButton1Click:Connect(function()
	if Mode == "Both" then
		Mode = "Single"
	else
		Mode = "Both"
	end

	updateMode()
end)

updateMode()

--==================================================
-- AUTOMATIC / MANUAL
--==================================================

local TriggerButton = Instance.new("TextButton")
TriggerButton.Size = UDim2.new(1, -10, 0, 30)
TriggerButton.Position = UDim2.new(0, 5, 0, 101)
TriggerButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TriggerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TriggerButton.TextSize = 14
TriggerButton.Font = Enum.Font.SourceSansBold
TriggerButton.Parent = MainFrame

local function updateTriggerMode()
	TriggerButton.Text = TriggerMode
end

TriggerButton.MouseButton1Click:Connect(function()
	if TriggerMode == "Manual" then
		TriggerMode = "Automatic"
	else
		TriggerMode = "Manual"
	end

	updateTriggerMode()
end)

updateTriggerMode()

--==================================================
-- Q → E SLIDER
--==================================================

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1, -10, 0, 20)
SliderLabel.Position = UDim2.new(0, 5, 0, 136)
SliderLabel.BackgroundTransparency = 1
SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SliderLabel.TextSize = 13
SliderLabel.Font = Enum.Font.SourceSans
SliderLabel.Parent = MainFrame

local function updateSliderText()
	SliderLabel.Text = "Q → E: " .. Q_E_Delay .. "s"
end

updateSliderText()

local SliderBar = Instance.new("Frame")
SliderBar.Size = UDim2.new(1, -20, 0, 8)
SliderBar.Position = UDim2.new(0, 10, 0, 162)
SliderBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
SliderBar.BorderSizePixel = 0
SliderBar.Parent = MainFrame

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 14, 0, 20)
SliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
SliderButton.Position = UDim2.new(0, 0, 0.5, 0)
SliderButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
SliderButton.Text = ""
SliderButton.BorderSizePixel = 0
SliderButton.Parent = SliderBar

local sliderDragging = false

local function setSliderFromX(x)
	local relativeX = math.clamp(
		x - SliderBar.AbsolutePosition.X,
		0,
		SliderBar.AbsoluteSize.X
	)

	local percentage = relativeX / SliderBar.AbsoluteSize.X

	Q_E_Delay = math.clamp(
		math.floor(percentage * 7 + 1.5),
		1,
		8
	)

	SliderButton.Position = UDim2.new(
		(Q_E_Delay - 1) / 7,
		0,
		0.5,
		0
	)

	updateSliderText()
end

SliderButton.MouseButton1Down:Connect(function()
	sliderDragging = true
end)

SliderBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliderDragging = true
		setSliderFromX(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		setSliderFromX(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		sliderDragging = false
	end
end)

SliderButton.Position = UDim2.new(
	(Q_E_Delay - 1) / 7,
	0,
	0.5,
	0
)

--==================================================
-- DIVIDER
--==================================================

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -10, 0, 1)
Divider.Position = UDim2.new(0, 5, 0, 150)
Divider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

--==================================================
-- TELEPORT SECTION
--==================================================

local TeleportTitle = Instance.new("TextLabel")
TeleportTitle.Size = UDim2.new(1, 0, 0, 25)
TeleportTitle.Position = UDim2.new(0, 0, 0, 157)
TeleportTitle.BackgroundTransparency = 1
TeleportTitle.Text = "Teleport"
TeleportTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportTitle.TextSize = 14
TeleportTitle.Font = Enum.Font.SourceSansBold
TeleportTitle.Parent = MainFrame

-- Keybind
local KeybindLabel = Instance.new("TextLabel")
KeybindLabel.Size = UDim2.new(1, 0, 0, 22)
KeybindLabel.Position = UDim2.new(0, 0, 0, 181)
KeybindLabel.BackgroundTransparency = 1
KeybindLabel.Text = "Keybind: G"
KeybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
KeybindLabel.TextSize = 13
KeybindLabel.Font = Enum.Font.SourceSansBold
KeybindLabel.Parent = MainFrame

-- Teleport ON/OFF
local TeleportToggle = Instance.new("TextButton")
TeleportToggle.Size = UDim2.new(1, -10, 0, 32)
TeleportToggle.Position = UDim2.new(0, 5, 0, 205)
TeleportToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportToggle.TextSize = 14
TeleportToggle.Font = Enum.Font.SourceSansBold
TeleportToggle.Parent = MainFrame

local function UpdateTeleportToggle()
	if TeleportEnabled then
		TeleportToggle.Text = "ON"
		TeleportToggle.BackgroundColor3 = Color3.fromRGB(50, 170, 70)
	else
		TeleportToggle.Text = "OFF"
		TeleportToggle.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
	end
end

local function ToggleTeleport()
	TeleportEnabled = not TeleportEnabled
	UpdateTeleportToggle()
end

TeleportToggle.MouseButton1Click:Connect(ToggleTeleport)

UpdateTeleportToggle()

-- Interval
local IntervalLabel = Instance.new("TextLabel")
IntervalLabel.Size = UDim2.new(1, 0, 0, 25)
IntervalLabel.Position = UDim2.new(0, 0, 0, 242)
IntervalLabel.BackgroundTransparency = 1
IntervalLabel.Text = "Teleport Interval: " .. TeleportInterval .. "s"
IntervalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
IntervalLabel.TextSize = 13
IntervalLabel.Font = Enum.Font.SourceSans
IntervalLabel.Parent = MainFrame

-- Target
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, 0, 0, 20)
TargetLabel.Position = UDim2.new(0, 0, 0, 270)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Target: " .. TargetName
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.TextSize = 12
TargetLabel.Font = Enum.Font.SourceSans
TargetLabel.Parent = MainFrame

--==================================================
-- G KEYBIND
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.G then
		ToggleTeleport()
	end
end)

--==================================================
-- SOUL DRAIN LOOP
--==================================================

task.spawn(function()
	while task.wait(0.1) do

		if Enabled and not running then

			local shouldRun = false

			-- AUTOMATIC:
			-- Run without waiting for Soul Drain
			if TriggerMode == "Automatic" then
				shouldRun = true

			-- MANUAL:
			-- Only run when Soul Drain exists
			elseif TriggerMode == "Manual" then
				if workspace:FindFirstChild("Soul Drain", true) then
					shouldRun = true
				end
			end

			if shouldRun then
				running = true

				if Mode == "Both" then

					-- Q + E together
					pressKey(Enum.KeyCode.Q)
					pressKey(Enum.KeyCode.E)

				elseif Mode == "Single" then

					-- Q → delay → E
					pressKey(Enum.KeyCode.Q)

					task.wait(Q_E_Delay)

					if Enabled then
						pressKey(Enum.KeyCode.E)
					end
				end

				running = false
			end
		end
	end
end)

--==================================================
-- TELEPORT LOOP
--==================================================

task.spawn(function()
	while task.wait(TeleportInterval) do

		if TeleportEnabled then

			local Target = Players:FindFirstChild(TargetName)

			if Target and Target.Character then

				local TargetRoot =
					Target.Character:FindFirstChild("HumanoidRootPart")

				local MyCharacter = LocalPlayer.Character

				local MyRoot =
					MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart")

				if TargetRoot and MyRoot then
					MyRoot.CFrame = TargetRoot.CFrame
				end
			end
		end
	end
end)
