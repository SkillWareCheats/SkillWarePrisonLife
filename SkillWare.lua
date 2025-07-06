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

-- CALLBACK NOTE:
-- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
-- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
-- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.

-- You do not have to set your tabs & groups up this way, just a prefrence.
-- You can find more icons in https://lucide.dev/
local Tabs = {
	-- Creates a new tab titled Main
	Main = Window:AddTab("Main", "user"),
	Weapon = Window:AddTab("Weapon", "axe"),
	Key = Window:AddKeyTab("Key System"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}


--[[
Example of how to add a warning box to a tab; the title AND text support rich text formatting.

local WarningTab = Tabs["UI Settings"]:AddTab("Warning Box", "user")

WarningTab:UpdateWarningBox({
	Visible = true,
	Title = "Warning",
	Text = "This is a warning box!",
})

]]

-- Groupbox and Tabbox inherit the same functions
-- except Tabboxes you have to call the functions on a tab (Tabbox:AddTab(Name))
local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Movement", "person-standing")
-- We can also get our Main tab via the following code:
-- local LeftGroupBox = Window.Tabs.Main:AddLeftGroupbox("Groupbox", "boxes")

-- Tabboxes are a tiny bit different, but here's a basic example:
--[[

local TabBox = Tabs.Main:AddLeftTabbox() -- Add Tabbox on left side

local Tab1 = TabBox:AddTab("Tab 1")
local Tab2 = TabBox:AddTab("Tab 2")

-- You can now call AddToggle, etc on the tabs you added to the Tabbox
]]

-- Groupbox:AddToggle
-- Arguments: Index, Options
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- UI setup (replace with your actual Main tab/group variable)
local MainTab = Tabs.Main -- change this if your Main tab var is named differently
local MainGroup = MainTab:AddLeftGroupbox("Player Health & Godmode")

-- Variables
local godmodeEnabled = false
local customMaxHealth = 1000

-- Current character and humanoid refs
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Protect Humanoid from damage & death (advanced)
local function protectHumanoid(humanoid)
    if not humanoid then return end
    
    -- Override TakeDamage method
    if humanoid.TakeDamage then
        local oldTakeDamage = humanoid.TakeDamage
        humanoid.TakeDamage = function(self, damage)
            if godmodeEnabled then
                return
            else
                return oldTakeDamage(self, damage)
            end
        end
    end

    -- Hook Health setter to prevent health reduction
    local mt = getrawmetatable(game)
    if setreadonly then setreadonly(mt, false) else make_writeable(mt, true) end
    local oldNewIndex = mt.__newindex
    mt.__newindex = newcclosure(function(t, k, v)
        if t == humanoid and (k == "Health" or k == "health") and godmodeEnabled then
            if v < humanoid.Health then
                return -- block health lowering
            end
        end
        return oldNewIndex(t, k, v)
    end)
    if setreadonly then setreadonly(mt, true) else make_writeable(mt, false) end

    -- Prevent death state
    humanoid.StateChanged:Connect(function(_, newState)
        if godmodeEnabled and newState == Enum.HumanoidStateType.Dead then
            humanoid.Health = humanoid.MaxHealth
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)

    -- Set initial health values
    humanoid.MaxHealth = customMaxHealth
    humanoid.Health = customMaxHealth
end

-- Prevent character removal (hook Destroy and Parent changes)
local function protectCharacter(char)
    if not char then return end
    
    -- Hook Destroy method
    local oldDestroy = char.Destroy
    char.Destroy = function(self, ...)
        if godmodeEnabled then
            return -- block destruction
        else
            return oldDestroy(self, ...)
        end
    end
    
    -- Hook Parent changes (metamethod)
    local oldNewIndex
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
        if self == char and key == "Parent" and godmodeEnabled then
            if value == nil then
                return -- block removal from workspace
            end
        end
        return oldNewIndex(self, key, value)
    end)
end

-- Update function to run every frame
RunService.Heartbeat:Connect(function()
    if godmodeEnabled and Humanoid and Humanoid.Parent then
        if Humanoid.Health < Humanoid.MaxHealth then
            Humanoid.Health = Humanoid.MaxHealth
        end
        if Humanoid:GetState() == Enum.HumanoidStateType.Dead then
            Humanoid.Health = Humanoid.MaxHealth
            Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

-- On character spawn, refresh references & protections
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    protectHumanoid(Humanoid)
    protectCharacter(Character)
end)

-- UI: Toggle Godmode
MainGroup:AddToggle("GodmodeToggle", {
    Text = "Godmode",
    Default = false,
    Tooltip = "Enable or disable godmode (invincible health)",
    Callback = function(value)
        godmodeEnabled = value
        if godmodeEnabled then
            protectHumanoid(Humanoid)
            protectCharacter(Character)
            Humanoid.MaxHealth = customMaxHealth
            Humanoid.Health = customMaxHealth
        end
    end,
})

-- UI: Slider for custom max health
MainGroup:AddSlider("MaxHealthSlider", {
    Text = "Max Health",
    Min = 100,
    Max = 5000,
    Default = customMaxHealth,
    Rounding = 0,
    Tooltip = "Set custom max health while godmode is active",
    Callback = function(value)
        customMaxHealth = value
        if Humanoid then
            Humanoid.MaxHealth = customMaxHealth
            if godmodeEnabled then
                Humanoid.Health = customMaxHealth
            end
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

-- Options is a table added to getgenv() by the library
-- You index Options with the specified index, in this case it is 'MySlider'
-- To get the value of the slider you do slider.Value

-- Groupbox:AddInput
-- Arguments: Idx, Info
LeftGroupBox:AddInput("MyTextbox", {
	Default = "My textbox!",
	Numeric = false, -- true / false, only allows numbers
	Finished = false, -- true / false, only calls callback when you press enter
	ClearTextOnFocus = true, -- true / false, if false the text will not clear when textbox focused

	Text = "This is a textbox",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the textbox

	Placeholder = "Placeholder text", -- placeholder text when the box is empty
	-- MaxLength is also an option which is the max length of the text

	Callback = function(Value)
		print("[cb] Text updated. New text:", Value)
	end,
})

Options.MyTextbox:OnChanged(function()
	print("Text updated. New text:", Options.MyTextbox.Value)
end)

-- Groupbox:AddDropdown
-- Arguments: Idx, Info

local DropdownGroupBox = Tabs.Main:AddRightGroupbox("Dropdowns")

DropdownGroupBox:AddDropdown("MyDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Searchable = false, -- true / false, makes the dropdown searchable (great for a long list of values)

	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

Options.MyDropdown:OnChanged(function()
	print("Dropdown got changed. New value:", Options.MyDropdown.Value)
end)

Options.MyDropdown:SetValue("This")

DropdownGroupBox:AddDropdown("MySearchableDropdown", {
	Values = { "This", "is", "a", "searchable", "dropdown" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A searchable dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Searchable = true, -- true / false, makes the dropdown searchable (great for a long list of values)

	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

DropdownGroupBox:AddDropdown("MyDisplayFormattedDropdown", {
	Values = { "This", "is", "a", "formatted", "dropdown" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A display formatted dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	FormatDisplayValue = function(Value) -- You can change the display value for any values. The value will be still same, only the UI changes.
		if Value == "formatted" then
			return "display formatted" -- formatted -> display formatted but in Options.MyDisplayFormattedDropdown.Value it will still return formatted if its selected.
		end

		return Value
	end,

	Searchable = false, -- true / false, makes the dropdown searchable (great for a long list of values)

	Callback = function(Value)
		print("[cb] Display formatted dropdown got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

-- Multi dropdowns
DropdownGroupBox:AddDropdown("MyMultiDropdown", {
	-- Default is the numeric index (e.g. "This" would be 1 since it if first in the values list)
	-- Default also accepts a string as well

	-- Currently you can not set multiple values with a dropdown

	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Multi = true, -- true / false, allows multiple choices to be selected

	Text = "A multi dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown

	Callback = function(Value)
		print("[cb] Multi dropdown got changed:")
		for key, value in next, Options.MyMultiDropdown.Value do
			print(key, value) -- should print something like This, true
		end
	end,
})

Options.MyMultiDropdown:SetValue({
	This = true,
	is = true,
})

DropdownGroupBox:AddDropdown("MyDisabledDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A disabled dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Callback = function(Value)
		print("[cb] Disabled dropdown got changed. New value:", Value)
	end,

	Disabled = true, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

DropdownGroupBox:AddDropdown("MyDisabledValueDropdown", {
	Values = { "This", "is", "a", "dropdown", "with", "disabled", "value" },
	DisabledValues = { "disabled" }, -- Disabled Values that are unclickable
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A dropdown with disabled value",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Callback = function(Value)
		print("[cb] Dropdown with disabled value got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

DropdownGroupBox:AddDropdown("MyVeryLongDropdown", {
	Values = {
		"This",
		"is",
		"a",
		"very",
		"long",
		"dropdown",
		"with",
		"a",
		"lot",
		"of",
		"values",
		"but",
		"you",
		"can",
		"see",
		"more",
		"than",
		"8",
		"values",
	},
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	MaxVisibleDropdownItems = 12, -- Default: 8, allows you to change the size of the dropdown list

	Text = "A very long dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown
	DisabledTooltip = "I am disabled!", -- Information shown when you hover over the dropdown while it's disabled

	Searchable = false, -- true / false, makes the dropdown searchable (great for a long list of values)

	Callback = function(Value)
		print("[cb] Very long dropdown got changed. New value:", Value)
	end,

	Disabled = false, -- Will disable the dropdown (true / false)
	Visible = true, -- Will make the dropdown invisible (true / false)
})

DropdownGroupBox:AddDropdown("MyPlayerDropdown", {
	SpecialType = "Player",
	ExcludeLocalPlayer = true, -- true / false, excludes the localplayer from the Player type
	Text = "A player dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown

	Callback = function(Value)
		print("[cb] Player dropdown got changed:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyTeamDropdown", {
	SpecialType = "Team",
	Text = "A team dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown

	Callback = function(Value)
		print("[cb] Team dropdown got changed:", Value)
	end,
})

-- Label:AddColorPicker
-- Arguments: Idx, Info

-- You can also ColorPicker & KeyPicker to a Toggle as well

LeftGroupBox:AddLabel("Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0), -- Bright green
	Title = "Some color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker (leave as nil to disable)

	Callback = function(Value)
		print("[cb] Color changed!", Value)
	end,
})

Options.ColorPicker:OnChanged(function()
	print("Color changed!", Options.ColorPicker.Value)
	print("Transparency changed!", Options.ColorPicker.Transparency)
end)

Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

-- Label:AddKeyPicker
-- Arguments: Idx, Info

LeftGroupBox:AddLabel("Keybind"):AddKeyPicker("KeyPicker", {
	-- SyncToggleState only works with toggles.
	-- It allows you to make a keybind which has its state synced with its parent toggle

	-- Example: Keybind which you use to toggle flyhack, etc.
	-- Changing the toggle disables the keybind state and toggling the keybind switches the toggle state

	Default = "MB2", -- String as the name of the keybind (MB1, MB2 for mouse buttons)
	SyncToggleState = false,

	-- You can define custom Modes but I have never had a use for it.
	Mode = "Toggle", -- Modes: Always, Toggle, Hold

	Text = "Auto lockpick safes", -- Text to display in the keybind menu
	NoUI = false, -- Set to true if you want to hide from the Keybind menu,

	-- Occurs when the keybind is clicked, Value is `true`/`false`
	Callback = function(Value)
		print("[cb] Keybind clicked!", Value)
	end,

	-- Occurs when the keybind itself is changed, `New` is a KeyCode Enum OR a UserInputType Enum
	ChangedCallback = function(New)
		print("[cb] Keybind changed!", New)
	end,
})

-- OnClick is only fired when you press the keybind and the mode is Toggle
-- Otherwise, you will have to use Keybind:GetState()
Options.KeyPicker:OnClick(function()
	print("Keybind clicked!", Options.KeyPicker:GetState())
end)

Options.KeyPicker:OnChanged(function()
	print("Keybind changed!", Options.KeyPicker.Value)
end)

task.spawn(function()
	while true do
		wait(1)

		-- example for checking if a keybind is being pressed
		local state = Options.KeyPicker:GetState()
		if state then
			print("KeyPicker is being held down")
		end

		if Library.Unloaded then
			break
		end
	end
end)

Options.KeyPicker:SetValue({ "MB2", "Hold" }) -- Sets keybind to MB2, mode to Hold

-- Long text label to demonstrate UI scrolling behaviour.
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

-- Anything we can do in a Groupbox, we can do in a Tabbox tab (AddToggle, AddSlider, AddLabel, etc etc...)
local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })

local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })

Library:OnUnload(function()
	print("Unloaded!")
end)

local workspace = game:GetService("Workspace")
local Remote = workspace:WaitForChild("Remote")
local ItemHandler = Remote:WaitForChild("ItemHandler")

local weaponsFolder = workspace.Prison_ITEMS.giver

local weapons = {
    "M9",
    "Remington",
    "AK-47",
    "Desert Eagle",
    "RPG",
    "Flamethrower",
    "Fists",
    "Brass Knuckles",
    "Knife",
    "Taser",
    "Stun Gun",
    "Gun",
}

local selectedWeapon = weapons[1]

local WeaponGroupBox = Tabs.Weapon:AddLeftGroupbox("Weapon Selector")

WeaponGroupBox:AddDropdown("WeaponDropdown", {
    Text = "Select Weapon",
    Values = weapons,
    Default = 1,
    Tooltip = "Choose your weapon",
    Callback = function(value)
        selectedWeapon = value
        print("[Weapon] Selected:", selectedWeapon)
    end,
})

WeaponGroupBox:AddButton({
    Text = "Give Weapon",
    Tooltip = "Gives the selected weapon",
    Func = function()
        local weaponPickup = weaponsFolder:FindFirstChild(selectedWeapon)
        if weaponPickup and weaponPickup:FindFirstChild("ITEMPICKUP") then
            local itemPickup = weaponPickup.ITEMPICKUP
            local success, err = pcall(function()
                ItemHandler:InvokeServer(itemPickup)
            end)
            if success then
                print("[Weapon] Given:", selectedWeapon)
            else
                warn("[Weapon] Failed to give weapon:", err)
            end
        else
            warn("[Weapon] Weapon not found in workspace:", selectedWeapon)
        end
    end,
})


-- Anything we can do in a Groupbox, we can do in a Key tab (AddToggle, AddSlider, AddLabel, etc etc...)
Tabs.Key:AddLabel({
	Text = "Key: Banana",
	DoesWrap = true,
	Size = 16,
})

Tabs.Key:AddKeyBox("Banana", function(Success, ReceivedKey)
	print("Expected Key: Banana - Received Key:", ReceivedKey, "| Success:", Success)
	Library:Notify({
		Title = "Expected Key: Banana",
		Description = "Received Key: " .. ReceivedKey .. "\nSuccess: " .. tostring(Success),
		Time = 4,
	})
end)

Tabs.Key:AddLabel({
	Text = "No Key",
	DoesWrap = true,
	Size = 16,
})

Tabs.Key:AddKeyBox(function(Success, ReceivedKey)
	print("Expected Key: None | Success:", Success) -- true
	Library:Notify("Success: " .. tostring(Success), 4)
end)

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