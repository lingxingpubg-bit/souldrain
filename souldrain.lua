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
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

-- Geyser
local Enabled = true
local Mode = "Both"
local TriggerMode = "Manual" -- "Automatic" or "Manual"
local Q_E_Delay = 1
local running = false

-- Teleport
local TargetName = "ANiceUser52"
local TeleportEnabled = true
local TeleportInterval = 0.02
local FollowDistance = 10
local wasTargetAlive = nil
local resettingCharacter = false

-- Auto Clicker Settings
local AutoClickEnabled = false
local AutoTriggerSafeZone = true -- Auto-triggers ON when entering thirdBossSafeZones OR dying
local AutoClickDelay = 0.05
local LockedPos = Vector2.new(605, 405) -- Default target: 605, 405

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
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = game:GetService("CoreGui")

-- Target Marker (Visual indicator for locked position)
local Marker = Instance.new("Frame")
Marker.Name = "AutoClickMarker"
Marker.Size = UDim2.fromOffset(12, 12)
Marker.AnchorPoint = Vector2.new(0.5, 0.5)
Marker.Position = UDim2.fromOffset(LockedPos.X, LockedPos.Y)
Marker.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
Marker.BackgroundTransparency = 0.2
Marker.Visible = true
Marker.Active = false
Marker.Parent = ScreenGui

local MarkerCorner = Instance.new("UICorner")
MarkerCorner.CornerRadius = UDim.new(1, 0)
MarkerCorner.Parent = Marker

local MarkerStroke = Instance.new("UIStroke")
MarkerStroke.Color = Color3.fromRGB(255, 255, 255)
MarkerStroke.Thickness = 1.5
MarkerStroke.Parent = Marker

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 180, 0, 500)
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
-- DIVIDER 1
--==================================================

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -10, 0, 1)
Divider.Position = UDim2.new(0, 5, 0, 168)
Divider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

--==================================================
-- TELEPORT SECTION
--==================================================

local TeleportTitle = Instance.new("TextLabel")
TeleportTitle.Size = UDim2.new(1, 0, 0, 22)
TeleportTitle.Position = UDim2.new(0, 0, 0, 172)
TeleportTitle.BackgroundTransparency = 1
TeleportTitle.Text = "Teleport [G]"
TeleportTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportTitle.TextSize = 13
TeleportTitle.Font = Enum.Font.SourceSansBold
TeleportTitle.Parent = MainFrame

local TeleportToggle = Instance.new("TextButton")
TeleportToggle.Size = UDim2.new(1, -10, 0, 28)
TeleportToggle.Position = UDim2.new(0, 5, 0, 196)
TeleportToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportToggle.TextSize = 13
TeleportToggle.Font = Enum.Font.SourceSansBold
TeleportToggle.Parent = MainFrame

local function UpdateTeleportToggle()
	if TeleportEnabled then
		TeleportToggle.Text = "Teleport: ON"
		TeleportToggle.BackgroundColor3 = Color3.fromRGB(50, 170, 70)
	else
		TeleportToggle.Text = "Teleport: OFF"
		TeleportToggle.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
	end
end

local function ToggleTeleport()
	TeleportEnabled = not TeleportEnabled
	UpdateTeleportToggle()
end

TeleportToggle.MouseButton1Click:Connect(ToggleTeleport)
UpdateTeleportToggle()

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, 0, 0, 18)
TargetLabel.Position = UDim2.new(0, 0, 0, 228)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Target: " .. TargetName
TargetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TargetLabel.TextSize = 12
TargetLabel.Font = Enum.Font.SourceSans
TargetLabel.Parent = MainFrame

--==================================================
-- DIVIDER 2
--==================================================

local Divider2 = Instance.new("Frame")
Divider2.Size = UDim2.new(1, -10, 0, 1)
Divider2.Position = UDim2.new(0, 5, 0, 252)
Divider2.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Divider2.BorderSizePixel = 0
Divider2.Parent = MainFrame

--==================================================
-- AUTO CLICKER SECTION
--==================================================

local AutoClickTitle = Instance.new("TextLabel")
AutoClickTitle.Size = UDim2.new(1, 0, 0, 22)
AutoClickTitle.Position = UDim2.new(0, 0, 0, 256)
AutoClickTitle.BackgroundTransparency = 1
AutoClickTitle.Text = "Auto Clicker [H]"
AutoClickTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoClickTitle.TextSize = 13
AutoClickTitle.Font = Enum.Font.SourceSansBold
AutoClickTitle.Parent = MainFrame

local AutoClickToggleBtn = Instance.new("TextButton")
AutoClickToggleBtn.Size = UDim2.new(0.5, -8, 0, 26)
AutoClickToggleBtn.Position = UDim2.new(0, 5, 0, 280)
AutoClickToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoClickToggleBtn.TextSize = 12
AutoClickToggleBtn.Font = Enum.Font.SourceSansBold
AutoClickToggleBtn.Parent = MainFrame

-- Auto Trigger Toggle Button (Safe Zone & Death Detection)
local AutoTriggerBtn = Instance.new("TextButton")
AutoTriggerBtn.Size = UDim2.new(0.5, -8, 0, 26)
AutoTriggerBtn.Position = UDim2.new(0.5, 3, 0, 280)
AutoTriggerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoTriggerBtn.TextSize = 11
AutoTriggerBtn.Font = Enum.Font.SourceSansBold
AutoTriggerBtn.Parent = MainFrame

local function UpdateAutoTriggerUI()
	if AutoTriggerSafeZone then
		AutoTriggerBtn.Text = "Zone Auto: ON"
		AutoTriggerBtn.BackgroundColor3 = Color3.fromRGB(45, 110, 180)
	else
		AutoTriggerBtn.Text = "Zone Auto: OFF"
		AutoTriggerBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
end

AutoTriggerBtn.MouseButton1Click:Connect(function()
	AutoTriggerSafeZone = not AutoTriggerSafeZone
	UpdateAutoTriggerUI()
end)
UpdateAutoTriggerUI()

local function UpdateAutoClickUI()
	if AutoClickEnabled then
		AutoClickToggleBtn.Text = "Click: ON"
		AutoClickToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 170, 70)
	else
		AutoClickToggleBtn.Text = "Click: OFF"
		AutoClickToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
	end
end

local function ToggleAutoClick()
	AutoClickEnabled = not AutoClickEnabled
	UpdateAutoClickUI()
end

AutoClickToggleBtn.MouseButton1Click:Connect(ToggleAutoClick)
UpdateAutoClickUI()

-- X and Y Input Row
local XBox = Instance.new("TextBox")
XBox.Size = UDim2.new(0.5, -8, 0, 22)
XBox.Position = UDim2.new(0, 5, 0, 310)
XBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
XBox.BorderSizePixel = 0
XBox.TextColor3 = Color3.fromRGB(255, 255, 255)
XBox.PlaceholderText = "Target X"
XBox.Text = tostring(LockedPos.X)
XBox.TextSize = 12
XBox.Font = Enum.Font.SourceSans
XBox.Parent = MainFrame

local YBox = Instance.new("TextBox")
YBox.Size = UDim2.new(0.5, -8, 0, 22)
YBox.Position = UDim2.new(0.5, 3, 0, 310)
YBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
YBox.BorderSizePixel = 0
YBox.TextColor3 = Color3.fromRGB(255, 255, 255)
YBox.PlaceholderText = "Target Y"
YBox.Text = tostring(LockedPos.Y)
YBox.TextSize = 12
YBox.Font = Enum.Font.SourceSans
YBox.Parent = MainFrame

-- Target Coordinates Status
local TargetStatus = Instance.new("TextLabel")
TargetStatus.Size = UDim2.new(1, 0, 0, 16)
TargetStatus.Position = UDim2.new(0, 0, 0, 336)
TargetStatus.BackgroundTransparency = 1
TargetStatus.Text = string.format("Locked: (%d, %d)", LockedPos.X, LockedPos.Y)
TargetStatus.TextColor3 = Color3.fromRGB(255, 120, 120)
TargetStatus.TextSize = 11
TargetStatus.Font = Enum.Font.SourceSans
TargetStatus.Parent = MainFrame

local function SetLockedPosition(vec2)
	LockedPos = vec2
	if vec2 then
		XBox.Text = tostring(math.floor(vec2.X))
		YBox.Text = tostring(math.floor(vec2.Y))
		TargetStatus.Text = string.format("Locked: (%d, %d)", vec2.X, vec2.Y)
		TargetStatus.TextColor3 = Color3.fromRGB(255, 120, 120)

		Marker.Position = UDim2.fromOffset(vec2.X, vec2.Y)
		Marker.Visible = true
	else
		XBox.Text = ""
		YBox.Text = ""
		TargetStatus.Text = "Mode: Following Mouse"
		TargetStatus.TextColor3 = Color3.fromRGB(120, 200, 120)
		Marker.Visible = false
	end
end

-- Lock Mouse / Follow Mouse Row
local LockMouseBtn = Instance.new("TextButton")
LockMouseBtn.Size = UDim2.new(0.5, -8, 0, 24)
LockMouseBtn.Position = UDim2.new(0, 5, 0, 356)
LockMouseBtn.BackgroundColor3 = Color3.fromRGB(45, 110, 180)
LockMouseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LockMouseBtn.Text = "Lock Mouse [J]"
LockMouseBtn.TextSize = 11
LockMouseBtn.Font = Enum.Font.SourceSansBold
LockMouseBtn.Parent = MainFrame

local FollowMouseBtn = Instance.new("TextButton")
FollowMouseBtn.Size = UDim2.new(0.5, -8, 0, 24)
FollowMouseBtn.Position = UDim2.new(0.5, 3, 0, 356)
FollowMouseBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
FollowMouseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
FollowMouseBtn.Text = "Follow Mouse"
FollowMouseBtn.TextSize = 11
FollowMouseBtn.Font = Enum.Font.SourceSans
FollowMouseBtn.Parent = MainFrame

LockMouseBtn.MouseButton1Click:Connect(function()
	SetLockedPosition(UserInputService:GetMouseLocation())
end)

FollowMouseBtn.MouseButton1Click:Connect(function()
	SetLockedPosition(nil)
end)

local function OnCoordInput()
	local x = tonumber(XBox.Text)
	local y = tonumber(YBox.Text)
	if x and y then
		SetLockedPosition(Vector2.new(x, y))
	end
end
XBox.FocusLost:Connect(OnCoordInput)
YBox.FocusLost:Connect(OnCoordInput)

-- Live Safe Zone Status Indicator
local ZoneStatusLabel = Instance.new("TextLabel")
ZoneStatusLabel.Size = UDim2.new(1, 0, 0, 15)
ZoneStatusLabel.Position = UDim2.new(0, 0, 0, 384)
ZoneStatusLabel.BackgroundTransparency = 1
ZoneStatusLabel.Text = "Zone: OUTSIDE"
ZoneStatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
ZoneStatusLabel.TextSize = 11
ZoneStatusLabel.Font = Enum.Font.SourceSansBold
ZoneStatusLabel.Parent = MainFrame

-- Safe Zone Distance Label
local ZoneDistLabel = Instance.new("TextLabel")
ZoneDistLabel.Size = UDim2.new(1, 0, 0, 15)
ZoneDistLabel.Position = UDim2.new(0, 0, 0, 400)
ZoneDistLabel.BackgroundTransparency = 1
ZoneDistLabel.Text = "Zone Dist: N/A"
ZoneDistLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
ZoneDistLabel.TextSize = 11
ZoneDistLabel.Font = Enum.Font.SourceSans
ZoneDistLabel.Parent = MainFrame

-- Live Cursor Position Label
local MouseLiveLabel = Instance.new("TextLabel")
MouseLiveLabel.Size = UDim2.new(1, 0, 0, 15)
MouseLiveLabel.Position = UDim2.new(0, 0, 0, 417)
MouseLiveLabel.BackgroundTransparency = 1
MouseLiveLabel.Text = "Mouse: (0, 0)"
MouseLiveLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
MouseLiveLabel.TextSize = 11
MouseLiveLabel.Font = Enum.Font.SourceSans
MouseLiveLabel.Parent = MainFrame

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local pos = UserInputService:GetMouseLocation()
		MouseLiveLabel.Text = string.format("Mouse: (%d, %d)", pos.X, pos.Y)
	end
end)

--==================================================
-- KEYBINDS (G, H, J)
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.G then
		ToggleTeleport()
	elseif input.KeyCode == Enum.KeyCode.H then
		ToggleAutoClick()
	elseif input.KeyCode == Enum.KeyCode.J then
		SetLockedPosition(UserInputService:GetMouseLocation())
	end
end)

--==================================================
-- THIRD BOSS SAFE ZONE DISTANCE & CHECK
--==================================================

local hitbox -- Reference to player's visual hitbox

local function getDistanceToSafeZone()
	local safeZones = workspace:FindFirstChild("thirdBossSafeZones", true)
	if not safeZones then
		return nil, false
	end

	-- Check hitbox position, fallback to HumanoidRootPart
	local checkPos
	if hitbox and hitbox.Parent then
		checkPos = hitbox.Position
	else
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			checkPos = root.Position
		else
			return nil, false
		end
	end

	local minDistance = math.huge
	local isInside = false

	local zoneParts = safeZones:IsA("BasePart") and {safeZones} or safeZones:GetDescendants()
	for _, part in ipairs(zoneParts) do
		if part:IsA("BasePart") then
			local localPos = part.CFrame:PointToObjectSpace(checkPos)
			local half = part.Size / 2

			-- Check if inside the bounding box
			if math.abs(localPos.X) <= (half.X + 2)
				and math.abs(localPos.Y) <= (half.Y + 2)
				and math.abs(localPos.Z) <= (half.Z + 2) then
				isInside = true
				minDistance = 0
				break
			end

			-- Calculate closest point on the part's surface
			local clamped = Vector3.new(
				math.clamp(localPos.X, -half.X, half.X),
				math.clamp(localPos.Y, -half.Y, half.Y),
				math.clamp(localPos.Z, -half.Z, half.Z)
			)
			local worldClosest = part.CFrame:PointToWorldSpace(clamped)
			local dist = (checkPos - worldClosest).Magnitude

			if dist < minDistance then
				minDistance = dist
			end
		end
	end

	if minDistance == math.huge then
		return nil, false
	end

	return minDistance, isInside
end

--==================================================
-- AUTO CLICK LOOP WITH LATCHING SAFE ZONE & DEATH TRIGGER
--==================================================

task.spawn(function()
	while ScreenGui.Parent do
		local dist, inside = getDistanceToSafeZone()

		-- Check player character health
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local isDead = hum ~= nil and hum.Health <= 0

		-- If player dies before reaching or outside the safe zone: latch auto-clicker ON
		if isDead and AutoTriggerSafeZone and not AutoClickEnabled then
			AutoClickEnabled = true
			UpdateAutoClickUI()
		end

		-- Update Distance and Status Labels
		if dist == nil then
			ZoneDistLabel.Text = "Safe Zone: Not Found"
			ZoneDistLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			ZoneStatusLabel.Text = isDead and "Status: DIED (Latched ON)" or "Zone: UNKNOWN"
			ZoneStatusLabel.TextColor3 = isDead and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(150, 150, 150)
		elseif isDead then
			ZoneDistLabel.Text = string.format("Zone Dist: %.1f studs (DEAD)", dist)
			ZoneDistLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			ZoneStatusLabel.Text = "Status: DIED (Latched ON)"
			ZoneStatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		elseif inside then
			ZoneDistLabel.Text = "Zone Dist: 0 studs (INSIDE)"
			ZoneDistLabel.TextColor3 = Color3.fromRGB(50, 220, 80)
			ZoneStatusLabel.Text = "Zone: INSIDE (Active)"
			ZoneStatusLabel.TextColor3 = Color3.fromRGB(50, 220, 80)

			-- Turn ON when entering the safe zone
			if AutoTriggerSafeZone and not AutoClickEnabled then
				AutoClickEnabled = true
				UpdateAutoClickUI()
			end
		else
			ZoneDistLabel.Text = string.format("Zone Dist: %.1f studs", dist)
			ZoneDistLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

			if AutoClickEnabled then
				ZoneStatusLabel.Text = "Zone: OUTSIDE (Latched ON)"
				ZoneStatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
			else
				ZoneStatusLabel.Text = "Zone: OUTSIDE (Click: OFF)"
				ZoneStatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
			end
			-- Note: It does NOT turn off when outside; it stays ON until manually toggled
		end

		-- Click Execution
		if AutoClickEnabled then
			local target = LockedPos or UserInputService:GetMouseLocation()
			VirtualInputManager:SendMouseButtonEvent(target.X, target.Y, 0, true, game, 0)
			task.wait(0.01)
			VirtualInputManager:SendMouseButtonEvent(target.X, target.Y, 0, false, game, 0)

			task.wait(AutoClickDelay)
		else
			task.wait(0.05)
		end
	end
end)

--==================================================
-- SOUL DRAIN LOOP
--==================================================

local function findGeyser()
	return workspace:FindFirstChild("Blade Barrage Sword", true)
end

local qPressed = false
local ePressed = false

local function isInsideGroundAura()
	local groundAura = workspace:FindFirstChild("groundAura", true)
	if not groundAura then return false end

	local MyCharacter = LocalPlayer.Character
	local MyRoot = MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart")
	if not MyRoot then return false end

	if groundAura:IsA("BasePart") then
		local localPosition = groundAura.CFrame:PointToObjectSpace(MyRoot.Position)
		local halfSize = groundAura.Size / 2

		return math.abs(localPosition.X) <= halfSize.X
			and math.abs(localPosition.Y) <= halfSize.Y
			and math.abs(localPosition.Z) <= halfSize.Z
	end

	return false
end

local TARGET_AURA_COLOR = Color3.fromRGB(211, 85, 85)

local function isTargetInsideGroundAura()
	local target = Players:FindFirstChild("ANiceUser52")
	if not target then return false end

	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	for _, aura in ipairs(workspace:GetChildren()) do
		if aura.Name == "groundAura"
			and aura:IsA("BasePart")
			and aura.Color == TARGET_AURA_COLOR then

			local localPos = aura.CFrame:PointToObjectSpace(root.Position)
			local halfSize = aura.Size / 2

			if math.abs(localPos.X) <= halfSize.X
				and math.abs(localPos.Y) <= halfSize.Y
				and math.abs(localPos.Z) <= halfSize.Z then
				return true
			end
		end
	end

	return false
end

task.spawn(function()
	while true do
		if Enabled then
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
			elseif TriggerMode == "Manual" then
				local insideGroundAura = isInsideGroundAura()
				local geyserObject = findGeyser()
				local geyserFound = geyserObject ~= nil

				local targetInsideAura = isTargetInsideGroundAura()

				if targetInsideAura and not qPressed then
					pressKey(Enum.KeyCode.Q)
					qPressed = true
				end

				if not targetInsideAura then
					qPressed = false
				end

				if geyserFound and not ePressed then
					pressKey(Enum.KeyCode.E)
					ePressed = true
				end

				if not geyserFound then
					ePressed = false
				end
			end
		else
			qPressed = false
			ePressed = false
		end

		task.wait(0.05)
	end
end)

--==================================================
-- AUTOMATIC TELEPORT / FOLLOW LOOP
--==================================================

task.spawn(function()
	while task.wait(TeleportInterval) do
		if not TeleportEnabled then
			wasTargetAlive = nil
			continue
		end

		local Target = Players:FindFirstChild(TargetName)
		if not Target then
			wasTargetAlive = nil
			continue
		end

		local TargetCharacter = Target.Character
		local TargetHumanoid = TargetCharacter and TargetCharacter:FindFirstChildOfClass("Humanoid")
		local TargetRoot = TargetCharacter and TargetCharacter:FindFirstChild("HumanoidRootPart")

		local targetAlive = TargetHumanoid ~= nil and TargetHumanoid.Health > 0

		if wasTargetAlive == true and not targetAlive then
			if not resettingCharacter then
				resettingCharacter = true

				local MyCharacter = LocalPlayer.Character
				local MyHumanoid = MyCharacter and MyCharacter:FindFirstChildOfClass("Humanoid")
				if MyHumanoid and MyHumanoid.Health > 0 then
					MyHumanoid.Health = 0
				end

				task.delay(3, function()
					resettingCharacter = false
				end)
			end
		end

		wasTargetAlive = targetAlive

		if targetAlive and TargetRoot then
			local MyCharacter = LocalPlayer.Character
			local MyRoot = MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart")
			local MyHumanoid = MyCharacter and MyCharacter:FindFirstChildOfClass("Humanoid")

			if MyRoot and MyHumanoid and MyHumanoid.Health > 0 then
				local distance = (MyRoot.Position - TargetRoot.Position).Magnitude

				if distance > FollowDistance then
					MyHumanoid:MoveTo(TargetRoot.Position)
				else
					MyRoot.CFrame = TargetRoot.CFrame
					MyHumanoid:MoveTo(MyRoot.Position)
				end
			end
		end
	end
end)

--==================================================
-- HITBOX AND REWARD RESETS
--==================================================

print("Hitbox script started")

local HITBOX_DIAMETER = 10
local HITBOX_HEIGHT = 6

local lastDetected = false
local targetPart = workspace:FindFirstChild("dailyRewardTouchPart", true)

if not targetPart then
	warn("dailyRewardTouchPart not found; hitbox GUI will still load.")
end

local function setupCharacter(character)
	local root = character:WaitForChild("HumanoidRootPart")

	local old = character:FindFirstChild("VisualHitbox")
	if old then
		old:Destroy()
	end

	local part = Instance.new("Part")
	part.Name = "VisualHitbox"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(HITBOX_HEIGHT, HITBOX_DIAMETER, HITBOX_DIAMETER)
	part.Color = Color3.fromRGB(255, 140, 0)
	part.Transparency = 0.65
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = false
	part.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
	part.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part

	return part
end

local isResetting = false

RunService.Heartbeat:Connect(function()
	if isResetting or not hitbox or not hitbox.Parent then
		return
	end

	if not targetPart or not targetPart:IsA("BasePart") then
		targetPart = workspace:FindFirstChild("dailyRewardTouchPart", true)
		return
	end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local localPos = targetPart.CFrame:PointToObjectSpace(hitbox.Position)
	local half = targetPart.Size / 2

	local closest = Vector3.new(
		math.clamp(localPos.X, -half.X, half.X),
		math.clamp(localPos.Y, -half.Y, half.Y),
		math.clamp(localPos.Z, -half.Z, half.Z)
	)

	closest = targetPart.CFrame:PointToWorldSpace(closest)

	local distance = (hitbox.Position - closest).Magnitude
	local range = hitbox.Size.Magnitude / 2

	if distance <= range then
		isResetting = true
		humanoid.Health = 0

		task.delay(2, function()
			isResetting = false
		end)
	end
end)

local function onCharacterAdded(character)
	hitbox = setupCharacter(character)
	lastDetected = false

	-- Listen for player death to automatically turn on and latch the auto-clicker
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function()
			if AutoTriggerSafeZone and not AutoClickEnabled then
				AutoClickEnabled = true
				UpdateAutoClickUI()
			end
		end)
	end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
