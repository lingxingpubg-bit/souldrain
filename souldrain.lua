local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

--// SETTINGS
local Enabled = true
local Mode = "Both" -- "Both" or "Single"
local Q_E_Delay = 1 -- 1-8 seconds
local running = false

--// KEY PRESS
local function pressKey(key)
	VirtualInputManager:SendKeyEvent(true, key, false, game)
	VirtualInputManager:SendKeyEvent(false, key, false, game)
end

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SoulDrainAutomation"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 115, 0, 205)

-- Same general position as the old GUI
MainFrame.Position = UDim2.new(0.020, 0, 0.020, 100)

MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

--// DRAGGING
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

--// TITLE
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = "Soul Drain Q/E"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.SourceSansBold
Title.Parent = MainFrame

--// ENABLE / DISABLE
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

--// BOTH / SINGLE
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

--// SLIDER LABEL
local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1, -10, 0, 20)
SliderLabel.Position = UDim2.new(0, 5, 0, 102)
SliderLabel.BackgroundTransparency = 1
SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SliderLabel.TextSize = 13
SliderLabel.Font = Enum.Font.SourceSans
SliderLabel.Parent = MainFrame

local function updateSliderText()
	SliderLabel.Text = "Q → E: " .. Q_E_Delay .. "s"
end

updateSliderText()

--// SLIDER BAR
local SliderBar = Instance.new("Frame")
SliderBar.Size = UDim2.new(1, -20, 0, 8)
SliderBar.Position = UDim2.new(0, 10, 0, 128)
SliderBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
SliderBar.BorderSizePixel = 0
SliderBar.Parent = MainFrame

--// SLIDER BUTTON
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

	-- 1-8 seconds
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

-- Initial slider position
SliderButton.Position = UDim2.new(
	(Q_E_Delay - 1) / 7,
	0,
	0.5,
	0
)

--// DETECTION
task.spawn(function()
	while task.wait(0.1) do

		if Enabled and not running then

			local soulDrain = workspace:FindFirstChild("Soul Drain", true)

			if soulDrain then
				running = true

				if Mode == "Both" then
					-- Q and E together
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