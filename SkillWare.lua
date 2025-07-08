-- example script by https://github.com/mstudio45/LinoriaLib/blob/main/Example.lua and modified by deivid
-- You can suggest changes with a pull request or something

local repo = "https://raw.githubusercontent.com/SkillWareCheats/Obsidianv122/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false -- Forces AddToggle to AddCheckbox
Library.ShowToggleFrameInKeybinds = true -- Make toggle keybinds work inside the keybinds UI (aka adds a toggle to the UI). Good for mobile users (Default value = true)

local Window = Library:CreateWindow({
	-- Set Center to true if you want the menu to appear in the center
	-- Set AutoShow to true if you want the menu to appear when it is created
	-- Set Resizable to true if you want to have in-game resizable Window
	-- Set MobileButtonsSide to "Left" or "Right" if you want the ui toggle & lock buttons to be on the left or right side of the window
	-- Set ShowCustomCursor to false if you don't want to use the Linoria cursor
	-- NotifySide = Changes the side of the notifications (Left, Right) (Default value = Left)
	-- Position and Size are also valid options here
	-- but you do not need to define them unless you are changing them :)

	Title = "SkillWare",
	Footer = "Prison Life",
	Icon = "122751651591691",
	NotifySide = "Left",
	ShowCustomCursor = true,
})
local Tabs = {
	Main = Window:AddTab("Main", "user"),
	Weapon = Window:AddTab("Weapon", "axe"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Movement", "person-standing")
local WeaponBox = Tabs.Weapon:AddLeftGroupbox("Weapon Properties", "person-standing")
local DropdownGroupBox = Tabs.Main:AddRightGroupbox("Other", "info")
local userInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

local jumpConnection = nil -- to store the connection and disconnect later

LeftGroupBox:AddToggle("INFJump", {
	Text = "INF Jump",
	Tooltip = "INF", -- Shown when hovering over the toggle
	DisabledTooltip = "I am disabled!",

	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,

	Callback = function(enabled)
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")

		local canJump = true
		local jumpCooldown = 0.0

		if enabled then
			local function onJumpRequest()
				if canJump then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					canJump = false
					task.wait(jumpCooldown)
					canJump = true
				end
			end

			jumpConnection = userInputService.JumpRequest:Connect(onJumpRequest)
			print("[cb] INFJump enabled")
		else
			if jumpConnection then
				jumpConnection:Disconnect()
				jumpConnection = nil
			end
			print("[cb] INFJump disabled")
		end

		print("[cb] INFJump changed to:", enabled)
	end,
})

local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer

local noclipConnection = nil
local previouslyTouchedParts = {}

LeftGroupBox:AddToggle("NoclipToggle", {
	Text = "Noclip",
	Tooltip = "Walk through walls",
	Default = false,
	Callback = function(enabled)
		if enabled then
			noclipConnection = RunService.Stepped:Connect(function()
				local character = player.Character
				if character then
					for _, part in ipairs(character:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide == true then
							part.CanCollide = false
							-- Track parts we modified
							previouslyTouchedParts[part] = true
						end
					end
				end
			end)
			print("[cb] Noclip enabled")
		else
			if noclipConnection then
				noclipConnection:Disconnect()
				noclipConnection = nil
			end

			-- Restore only the parts we modified
			for part in pairs(previouslyTouchedParts) do
				if part and part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
			-- Clear the record
			previouslyTouchedParts = {}

			print("[cb] Noclip disabled")
		end
	end,
})


local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

local flying = false
local flyConnection = nil
local bodyGyro, bodyVelocity
local movementInput = Vector3.new(0, 0, 0)
local flySpeed = 50  -- Default fly speed, will be updated by slider

local humanoid

local keysDown = {}

local function updateMovement()
	local x, y, z = 0, 0, 0
	if keysDown.W then z = z + 1 end
	if keysDown.S then z = z - 1 end
	if keysDown.A then x = x - 1 end
	if keysDown.D then x = x + 1 end
	if keysDown.Space then y = y + 1 end
	if keysDown.LeftControl then y = y - 1 end
	movementInput = Vector3.new(x, y, z)
end

local function startFly()
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")

	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.P = 9e4
	bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bodyGyro.CFrame = root.CFrame
	bodyGyro.Parent = root

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = root

	flyConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then return end

		local camCF = camera.CFrame
		local moveDir = (camCF.RightVector * movementInput.X) + (camCF.UpVector * movementInput.Y) + (camCF.LookVector * movementInput.Z)

		if moveDir.Magnitude > 0 then
			bodyVelocity.Velocity = moveDir.Unit * flySpeed
		else
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		end
		bodyGyro.CFrame = camCF
	end)
end

local function stopFly()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if humanoid then
		humanoid.AutoRotate = true
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
		humanoid = nil
	end

	movementInput = Vector3.new(0, 0, 0)
	keysDown = {}
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local key = input.KeyCode
	if key == Enum.KeyCode.W then keysDown.W = true
	elseif key == Enum.KeyCode.S then keysDown.S = true
	elseif key == Enum.KeyCode.A then keysDown.A = true
	elseif key == Enum.KeyCode.D then keysDown.D = true
	elseif key == Enum.KeyCode.Space then keysDown.Space = true
	elseif key == Enum.KeyCode.LeftControl then keysDown.LeftControl = true
	end
	updateMovement()
end)

UserInputService.InputEnded:Connect(function(input)
	local key = input.KeyCode
	if key == Enum.KeyCode.W then keysDown.W = false
	elseif key == Enum.KeyCode.S then keysDown.S = false
	elseif key == Enum.KeyCode.A then keysDown.A = false
	elseif key == Enum.KeyCode.D then keysDown.D = false
	elseif key == Enum.KeyCode.Space then keysDown.Space = false
	elseif key == Enum.KeyCode.LeftControl then keysDown.LeftControl = false
	end
	updateMovement()
end)

-- UI: Toggle fly on/off
LeftGroupBox:AddToggle("FlyToggle", {
	Text = "Fly",
	Tooltip = "Toggle flying",
	Default = false,
	Callback = function(enabled)
		if enabled then
			startFly()
			print("[cb] Fly enabled")
		else
			stopFly()
			print("[cb] Fly disabled")
		end
	end,
})

-- UI: Slider to control fly speed dynamically
LeftGroupBox:AddSlider("FlySpeedSlider", {
	Text = "Fly Speed",
	Min = 10,
	Max = 200,
	Default = flySpeed,
	Rounding = 0,
	Compact = false,
	Callback = function(value)
		flySpeed = value
		print("[cb] Fly speed set to:", flySpeed)
	end,
})

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local function setCharacterTransparency(transparency)
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Transparency = transparency
			-- Also disable/enable decals so eyes etc disappear
			for _, decal in pairs(part:GetChildren()) do
				if decal:IsA("Decal") then
					decal.Transparency = transparency
				end
			end
		elseif part:IsA("ParticleEmitter") or part:IsA("BillboardGui") then
			-- Optionally disable visual effects if you want
			part.Enabled = (transparency == 0)
		end
	end
end

DropdownGroupBox:AddToggle("InvisibleMovementToggle", {
	Text = "Invisible",
	Tooltip = "Toggle invisible character",
	Default = false,
	Callback = function(enabled)
		character = player.Character or player.CharacterAdded:Wait()
		if enabled then
			setCharacterTransparency(1) -- fully invisible
			print("[cb] Invisible Movement enabled")
		else
			setCharacterTransparency(0) -- fully visible
			print("[cb] Invisible Movement disabled")
		end
	end,
})

-- Fetching a toggle object for later use:
-- Toggles.MyToggle.Value

-- Toggles is a table added to getgenv() by the library
-- You index Toggles with the specified index, in this case it is 'MyToggle'
-- To get the state of the toggle you do toggle.Value

-- Calls the passed function when the toggle is updated

-- 1/15/23
-- Deprecated old way of creating buttons in favor of using a table
-- Added DoubleClick button functionality

--[[
	Groupbox:AddButton
	Arguments: {
		Text = string,
		Func = function,
		DoubleClick = boolean
		Tooltip = string,
	}

	You can call :AddButton on a button to add a SubButton!
]]

--[[
	NOTE: You can chain the button methods!
	EXAMPLE:

	LeftGroupBox:AddButton({ Text = 'Kill all', Func = Functions.KillAll, Tooltip = 'This will kill everyone in the game!' })
		:AddButton({ Text = 'Kick all', Func = Functions.KickAll, Tooltip = 'This will kick everyone in the game!' })
]]

-- Options is a table added to getgenv() by the library
-- You index Options with the specified index, in this case it is 'SecondTestLabel' & 'TestLabel'
-- To set the text of the label you do label:SetText

-- Options.TestLabel:SetText("first changed!")
-- Options.SecondTestLabel:SetText("second changed!")

-- Groupbox:AddDivider
-- Arguments: None

--[[
	Groupbox:AddSlider
	Arguments: Idx, SliderOptions

	SliderOptions: {
		Text = string,
		Default = number,
		Min = number,
		Max = number,
		Suffix = string,
		Rounding = number,
		Compact = boolean,
		HideMax = boolean,
	}

	Text, Default, Min, Max, Rounding must be specified.
	Suffix is optional.
	Rounding is the number of decimal places for precision.

	Compact will hide the title label of the Slider

	HideMax will only display the value instead of the value & max value of the slider
	Compact will do the same thing
]]
LeftGroupBox:AddSlider("SpeedSlider", {
	Text = "Speed",
	Default = 16,
	Min = 16,
	Max = 200,
	Rounding = 1,
	Compact = false,

	Callback = function(Value)
		game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
		print("[cb] SpeedSlider was changed! New value:", Value)
	end,

	Tooltip = "Change", -- Information shown when you hover over the slider
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the slider while it's disabled

	Disabled = false, -- Will disable the slider (true / false)
	Visible = true, -- Will make the slider invisible (true / false)
})

LeftGroupBox:AddSlider("JumpSlider", {
	Text = "Jump",
	Default = 50,
	Min = 50,
	Max = 400,
	Rounding = 1,
	Compact = false,

	Callback = function(Value)
		game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
		print("[cb] JumpSlider was changed! New value:", Value)
	end,

	Tooltip = "Change", -- Information shown when you hover over the slider
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the slider while it's disabled

	Disabled = false, -- Will disable the slider (true / false)
	Visible = true, -- Will make the slider invisible (true / false)
})

local LeftGroupBox2 = Tabs.Main:AddLeftGroupbox("Visuals", "view")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Master toggle switches
local espEnabled = false
local showBoxes = false
local showTracers = false
local showNames = false
local showDistance = false
local showHealth = false

local ESPObjects = {}

local function createESP(player)
	if player == LocalPlayer or ESPObjects[player] then return end

	local objects = {
		Box = Drawing.new("Square"),
		Tracer = Drawing.new("Line"),
		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text"),
		Health = Drawing.new("Text"),
	}

	objects.Box.Color = Color3.fromRGB(0, 255, 0)
	objects.Box.Thickness = 2
	objects.Box.Filled = false
	objects.Box.Transparency = 1
	objects.Box.Visible = false

	objects.Tracer.Color = Color3.fromRGB(255, 255, 0)
	objects.Tracer.Thickness = 1
	objects.Tracer.Transparency = 1
	objects.Tracer.Visible = false

	for _, text in ipairs({objects.Name, objects.Distance, objects.Health}) do
		text.Size = 12
		text.Center = true
		text.Outline = true
		text.Visible = false
	end

	objects.Name.Color = Color3.fromRGB(255, 255, 255)
	objects.Distance.Color = Color3.fromRGB(200, 200, 200)
	objects.Health.Color = Color3.fromRGB(255, 0, 0)

	ESPObjects[player] = objects
end

local function removeESP(player)
	local obj = ESPObjects[player]
	if obj then
		for _, drawing in pairs(obj) do
			drawing:Remove()
		end
		ESPObjects[player] = nil
	end
end

RunService.RenderStepped:Connect(function()
	if not espEnabled then return end
	for player, drawings in pairs(ESPObjects) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and humanoid and humanoid.Health > 0 then
			local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
			if onScreen then
				local size = Vector2.new(2, 3) * (Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y - pos.Y)

				drawings.Box.Size = size
				drawings.Box.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
				drawings.Box.Visible = showBoxes

				drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
				drawings.Tracer.To = Vector2.new(pos.X, pos.Y)
				drawings.Tracer.Visible = showTracers

				drawings.Name.Text = player.Name
				drawings.Name.Position = Vector2.new(pos.X, pos.Y - size.Y / 2 - 15)
				drawings.Name.Visible = showNames

				local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
				drawings.Distance.Text = string.format("%.0f studs", dist)
				drawings.Distance.Position = Vector2.new(pos.X, pos.Y + size.Y / 2 + 2)
				drawings.Distance.Visible = showDistance

				drawings.Health.Text = "HP: " .. math.floor(humanoid.Health)
				drawings.Health.Position = Vector2.new(pos.X, pos.Y + size.Y / 2 + 15)
				drawings.Health.Visible = showHealth
			else
				for _, v in pairs(drawings) do
					v.Visible = false
				end
			end
		else
			for _, v in pairs(drawings) do
				v.Visible = false
			end
		end
	end
end)

task.spawn(function()
	while true do
		if espEnabled then
			for _, player in ipairs(Players:GetPlayers()) do
				createESP(player)
			end
			for player in pairs(ESPObjects) do
				if not Players:FindFirstChild(player.Name) then
					removeESP(player)
				end
			end
		end
		task.wait(1)
	end
end)

-- Create toggles and keep references
local ESPMasterToggle = LeftGroupBox2:AddToggle("ESPMaster", {
	Text = "ESP Master",
	Default = false,
	Tooltip = "Enable full ESP system",
	Callback = function(value)
		espEnabled = value
	end
})

local ESPBoxesToggle = LeftGroupBox2:AddToggle("ESPBoxes", {
	Text = "ESP Boxes",
	Default = false,
	Tooltip = "Draw boxes around players",
	Callback = function(value)
		showBoxes = value
	end
})

local ESPTracersToggle = LeftGroupBox2:AddToggle("ESPTracers", {
	Text = "ESP Tracers",
	Default = false,
	Tooltip = "Draw tracer lines to players",
	Callback = function(value)
		showTracers = value
	end
})

local ESPNamesToggle = LeftGroupBox2:AddToggle("ESPNames", {
	Text = "ESP Name Tags",
	Default = false,
	Tooltip = "Show player names",
	Callback = function(value)
		showNames = value
	end
})

local ESPDistanceToggle = LeftGroupBox2:AddToggle("ESPDistance", {
	Text = "ESP Distance",
	Default = false,
	Tooltip = "Show distance to player",
	Callback = function(value)
		showDistance = value
	end
})

local ESPHealthToggle = LeftGroupBox2:AddToggle("ESPHealth", {
	Text = "ESP Health",
	Default = false,
	Tooltip = "Show player HP",
	Callback = function(value)
		showHealth = value
	end
})

-- Add color pickers as children of toggles for proper UI nesting
local ESPBoxColorPicker = ESPBoxesToggle:AddColorPicker("ESPBoxColor", {
	Default = Color3.fromRGB(0, 255, 0),
	Title = "Box Color",
	Transparency = 0,
	Callback = function(color)
		for _, obj in pairs(ESPObjects) do
			obj.Box.Color = color
		end
	end
})

local ESPTracerColorPicker = ESPTracersToggle:AddColorPicker("ESPTracerColor", {
	Default = Color3.fromRGB(255, 255, 0),
	Title = "Tracer Color",
	Transparency = 0,
	Callback = function(color)
		for _, obj in pairs(ESPObjects) do
			obj.Tracer.Color = color
		end
	end
})

local ESPNameColorPicker = ESPNamesToggle:AddColorPicker("ESPNameColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Name Color",
	Transparency = 0,
	Callback = function(color)
		for _, obj in pairs(ESPObjects) do
			obj.Name.Color = color
		end
	end
})

local ESPHealthColorPicker = ESPHealthToggle:AddColorPicker("ESPHealthColor", {
	Default = Color3.fromRGB(255, 0, 0),
	Title = "Health Color",
	Transparency = 0,
	Callback = function(color)
		for _, obj in pairs(ESPObjects) do
			obj.Health.Color = color
		end
	end
})

local ESPDistanceColorPicker = ESPDistanceToggle:AddColorPicker("ESPDistanceColor", {
	Default = Color3.fromRGB(200, 200, 200),
	Title = "Distance Color",
	Transparency = 0,
	Callback = function(color)
		for _, obj in pairs(ESPObjects) do
			obj.Distance.Color = color
		end
	end
})

local TabBox = Tabs.Main:AddRightTabbox() -- Add Tabbox on right side

-- ===================================
-- Libraries & Services
-- ===================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ===================================
-- Global weapon vars
-- ===================================
BulletsPerShot = 1
MultiShotEnabled = false
RapidFireEnabled = false
RapidFireDelay = 1

-- ===================================
-- UI Setup (using your Tabs & Groupboxes)
-- ===================================
WeaponBox:AddButton({
    Text = "Infinite Ammo",
    Func = function()
        task.spawn(function()
            while true do
                for _,v in pairs(getgc(true)) do
                    if type(v) == "table" and rawget(v, "MaxAmmo") then
                        v.MaxAmmo = math.huge
                        v.CurrentAmmo = math.huge
                    end
                end
                task.wait(1)
            end
        end)
    end,
    DoubleClick = true,
    Tooltip = "Gives you infinite ammo"
})

WeaponBox:AddButton({
    Text = "Reset Ammo",
    Func = function()
        for _,v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "MaxAmmo") then
                v.MaxAmmo = 15
                v.CurrentAmmo = 15
            end
        end
    end,
    DoubleClick = true,
    Tooltip = "Resets ammo to normal"
})

WeaponBox:AddSlider("BulletsPerShot", {
    Text = "Bullets Per Shot",
    Default = 1,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Tooltip = "Number of bullets fired each shot",
    Callback = function(Value)
        BulletsPerShot = Value
    end
})

WeaponBox:AddToggle("MultiShotToggle", {
    Text = "Enable Multi Shot",
    Default = false,
    Tooltip = "Shoot multiple bullets per shot",
    Callback = function(Value)
        MultiShotEnabled = Value
    end
})

WeaponBox:AddToggle("RapidFireToggle", {
    Text = "Enable Rapid Fire",
    Default = false,
    Tooltip = "Remove firing delay for rapid shots",
    Callback = function(Value)
        RapidFireEnabled = Value
    end
})

WeaponBox:AddSlider("RapidFireSpeed", {
    Text = "Rapid Fire Speed",
    Default = 1,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Tooltip = "Lower is faster (delay in seconds)",
    Callback = function(Value)
        RapidFireDelay = Value
    end
})

-- ===================================
-- Backend weapon modifications
-- ===================================

-- Rapid Fire Hook
task.spawn(function()
    while task.wait() do
        if RapidFireEnabled then
            local delay = RapidFireDelay or 0.1
            for _,v in pairs(getgc(true)) do
                if type(v) == "table" and rawget(v, "FireRate") then
                    v.FireRate = delay
                end
            end
        end
    end
end)

-- Multi Shot Hook
task.spawn(function()
    while task.wait() do
        if MultiShotEnabled then
            for _,v in pairs(getgc(true)) do
                if type(v) == "table" and rawget(v, "Bullets") then
                    v.Bullets = BulletsPerShot
                end
            end
        end
    end
end)

DropdownGroupBox:AddButton("Reset FOV", function()
    game.Workspace.CurrentCamera.FieldOfView = 70
    Obsidian:Notify("✅ FOV Reset", "Camera FOV set back to 70.", 2)
end)

DropdownGroupBox:AddSlider("FOVSlider", {
    Text = "Field of View",
    Default = 70, -- typical Roblox FOV
    Min = 40,
    Max = 120,
    Rounding = 1,
    Tooltip = "Adjust your camera field of view.",
    Callback = function(Value)
        game.Workspace.CurrentCamera.FieldOfView = Value
    end
})

-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place") -- if the game has multiple places inside of it (for example: DOORS)
-- you can use this to save configs for those places separately
-- The path in this script would be: MyScriptHub/specific-game/settings/specific-place
-- [ This is optional ]

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs["UI Settings"])

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
