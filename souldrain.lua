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
-- Q → E EDITABLE INPUT
--==================================================

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.55, -5, 0, 25)
DelayLabel.Position = UDim2.new(0, 5, 0, 136)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Q → E Delay:"
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.TextSize = 13
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = MainFrame

local DelayInput = Instance.new("TextBox")
DelayInput.Size = UDim2.new(0.45, -10, 0, 25)
DelayInput.Position = UDim2.new(0.55, 5, 0, 136)
DelayInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
DelayInput.BorderSizePixel = 0
DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayInput.TextSize = 13
DelayInput.Font = Enum.Font.SourceSans
DelayInput.Text = tostring(Q_E_Delay)
DelayInput.ClearTextOnFocus = false
DelayInput.TextXAlignment = Enum.TextXAlignment.Center
DelayInput.Parent = MainFrame

DelayInput.FocusLost:Connect(function()
	local value = tonumber(DelayInput.Text)

	if value and value >= 0 then
		Q_E_Delay = value
		DelayInput.Text = tostring(Q_E_Delay)
	else
		DelayInput.Text = tostring(Q_E_Delay)
	end
end)

--==================================================
-- DIVIDER
--==================================================

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -10, 0, 1)
Divider.Position = UDim2.new(0, 5, 0, 172)
Divider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

--==================================================
-- TELEPORT SECTION
--==================================================

local TeleportTitle = Instance.new("TextLabel")
TeleportTitle.Size = UDim2.new(1, 0, 0, 25)
TeleportTitle.Position = UDim2.new(0, 0, 0, 179)
TeleportTitle.BackgroundTransparency = 1
TeleportTitle.Text = "Teleport"
TeleportTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportTitle.TextSize = 14
TeleportTitle.Font = Enum.Font.SourceSansBold
TeleportTitle.Parent = MainFrame

-- Keybind
local KeybindLabel = Instance.new("TextLabel")
KeybindLabel.Size = UDim2.new(1, 0, 0, 22)
KeybindLabel.Position = UDim2.new(0, 0, 0, 203)
KeybindLabel.BackgroundTransparency = 1
KeybindLabel.Text = "Keybind: G"
KeybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
KeybindLabel.TextSize = 13
KeybindLabel.Font = Enum.Font.SourceSansBold
KeybindLabel.Parent = MainFrame

-- Teleport ON/OFF
local TeleportToggle = Instance.new("TextButton")
TeleportToggle.Size = UDim2.new(1, -10, 0, 32)
TeleportToggle.Position = UDim2.new(0, 5, 0, 227)
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
IntervalLabel.Position = UDim2.new(0, 0, 0, 264)
IntervalLabel.BackgroundTransparency = 1
IntervalLabel.Text = "Teleport Interval: " .. TeleportInterval .. "s"
IntervalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
IntervalLabel.TextSize = 13
IntervalLabel.Font = Enum.Font.SourceSans
IntervalLabel.Parent = MainFrame

-- Target
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, 0, 0, 20)
TargetLabel.Position = UDim2.new(0, 0, 0, 292)
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

local qPressed = false
local ePressed = false

local function isInsideGroundAura()
	local groundAura = workspace:FindFirstChild("groundAura", true)

	if not groundAura then
		return false
	end

	local MyCharacter = LocalPlayer.Character
	local MyRoot = MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart")

	if not MyRoot then
		return false
	end

	-- groundAura must be a BasePart
	if groundAura:IsA("BasePart") then
		local localPosition = groundAura.CFrame:PointToObjectSpace(MyRoot.Position)
		local halfSize = groundAura.Size / 2

		return
			math.abs(localPosition.X) <= halfSize.X
			and math.abs(localPosition.Y) <= halfSize.Y
			and math.abs(localPosition.Z) <= halfSize.Z
	end

	return false
end

task.spawn(function()
	while true do

		if Enabled then

			--==================================================
			-- AUTOMATIC
			--==================================================

			if TriggerMode == "Automatic" then

				if not running then
					running = true

					if Mode == "Both" then

						pressKey(Enum.KeyCode.Q)
						pressKey(Enum.KeyCode.E)

					elseif Mode == "Single" then

						pressKey(Enum.KeyCode.Q)

						task.wait(Q_E_Delay)

						if Enabled then
							pressKey(Enum.KeyCode.E)
						end
					end

					running = false
				end

			--==================================================
			-- MANUAL
			--==================================================

			elseif TriggerMode == "Manual" then

				local insideGroundAura = isInsideGroundAura()
				local soulDrainFound = workspace:FindFirstChild("Soul Drain", true) ~= nil

				-- Q when entering groundAura
				if insideGroundAura and not qPressed then
					pressKey(Enum.KeyCode.Q)
					qPressed = true
				end

				-- Reset Q trigger after leaving groundAura
				if not insideGroundAura then
					qPressed = false
				end

				-- E when Soul Drain appears
				if soulDrainFound and not ePressed then
					pressKey(Enum.KeyCode.E)
					ePressed = true
				end

				-- Reset E trigger after Soul Drain disappears
				if not soulDrainFound then
					ePressed = false
				end
			end
		else
			-- Reset manual trigger states when disabled
			qPressed = false
			ePressed = false
		end

		task.wait(0.05)
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
