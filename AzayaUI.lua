-- https://lua.expert/
-- AzayaUI - lightweight 8-bit/arcade style UI library for Roblox executors
-- Features: draggable window (mouse + touch), tabs, sections, standard elements,
-- config persistence (writefile/readfile), notification popups.

local AzayaUI = {}
AzayaUI.__index = AzayaUI

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local v1 = game:GetService("Players")
local v2 = game:GetService("UserInputService")
local v3 = game:GetService("TweenService")
local v4 = game:GetService("HttpService")
local v5 = game:GetService("RunService")

local v6 = v1.LocalPlayer
local v7 = v6:WaitForChild("PlayerGui")

--------------------------------------------------
-- THEME (8-bit arcade: black outline, yellow fill, red shadow)
--------------------------------------------------

local COLOR_BG = Color3.fromRGB(18, 15, 18)
local COLOR_PANEL = Color3.fromRGB(28, 24, 28)
local COLOR_BORDER = Color3.fromRGB(8, 6, 8)
local COLOR_YELLOW = Color3.fromRGB(255, 205, 60)
local COLOR_RED = Color3.fromRGB(214, 60, 45)
local COLOR_TEXT = Color3.fromRGB(240, 240, 240)
local COLOR_DIM = Color3.fromRGB(150, 145, 150)
local COLOR_GREEN = Color3.fromRGB(90, 200, 110)

local PIXEL_FONT
do
	local v8, v9 = pcall(function()
		return Enum.Font.PressStart2P
	end)
	PIXEL_FONT = (v8 and v9) or Enum.Font.Code
end

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function p1(p2, p3, p4, p5, p6) -- makeInstance(className, props, parent, size, position)
	local v10 = Instance.new(p2)
	for v11, v12 in pairs(p3 or {}) do
		v10[v11] = v12
	end
	if p5 then v10.Size = p5 end
	if p6 then v10.Position = p6 end
	v10.Parent = p4
	return v10
end

local function p7(p8) -- addPixelBorder(frame) - thick black outline, no rounding (sharp 8-bit look)
	local v13 = Instance.new("UIStroke")
	v13.Thickness = 2
	v13.Color = COLOR_BORDER
	v13.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	v13.Parent = p8
	return v13
end

local function p9(p10) -- makeDraggable(frame) - works with mouse AND touch
	local v14 = false
	local v15, v16, v17

	p10.InputBegan:Connect(function(p11)
		if p11.UserInputType == Enum.UserInputType.MouseButton1 or p11.UserInputType == Enum.UserInputType.Touch then
			v14 = true
			v16 = p11.Position
			v17 = p10.Position

			p11.Changed:Connect(function()
				if p11.UserInputState == Enum.UserInputState.End then
					v14 = false
				end
			end)
		end
	end)

	p10.InputChanged:Connect(function(p12)
		if p12.UserInputType == Enum.UserInputType.MouseMovement or p12.UserInputType == Enum.UserInputType.Touch then
			v15 = p12
		end
	end)

	v2.InputChanged:Connect(function(p13)
		if p13 == v15 and v14 then
			local v18 = p13.Position - v16
			p10.Position = UDim2.new(v17.X.Scale, v17.X.Offset + v18.X, v17.Y.Scale, v17.Y.Offset + v18.Y)
		end
	end)
end

--------------------------------------------------
-- CONFIG PERSISTENCE
--------------------------------------------------

function AzayaUI:_configPath(p14)
	return self.ConfigFolder .. "/" .. p14 .. ".json"
end

function AzayaUI:SaveConfig(p15)
	p15 = p15 or "default"
	if not isfolder(self.ConfigFolder) then
		makefolder(self.ConfigFolder)
	end

	local v19, v20 = pcall(function()
		writefile(self:_configPath(p15), v4:JSONEncode(self.Flags))
	end)

	if v19 then
		self:Notify("Config", "Saved: " .. p15, 2)
	else
		self:Notify("Config", "Failed to save: " .. tostring(v20), 3)
	end

	return v19
end

function AzayaUI:LoadConfig(p16)
	p16 = p16 or "default"
	local v21 = self:_configPath(p16)

	if not isfile(v21) then
		self:Notify("Config", "No saved config: " .. p16, 2)
		return false
	end

	local v22, v23 = pcall(function()
		return v4:JSONDecode(readfile(v21))
	end)

	if not v22 or type(v23) ~= "table" then
		self:Notify("Config", "Failed to load config", 3)
		return false
	end

	for v24, v25 in pairs(v23) do
		self.Flags[v24] = v25
		local v26 = self._elements[v24]
		if v26 and v26.Update then
			v26.Update(v25)
		end
	end

	self:Notify("Config", "Loaded: " .. p16, 2)
	return true
end

--------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------

function AzayaUI:Notify(p17, p18, p19)
	p19 = p19 or 3

	local v27 = p1("Frame", {
		BackgroundColor3 = COLOR_PANEL,
		BorderSizePixel = 0,
	}, self.NotifyHolder, UDim2.new(1, 0, 0, 54))

	p7(v27)

	p1("Frame", {
		BackgroundColor3 = COLOR_YELLOW,
		BorderSizePixel = 0,
	}, v27, UDim2.new(0, 4, 1, 0), UDim2.new(0, 0, 0, 0))

	p1("TextLabel", {
		Text = p17,
		Font = PIXEL_FONT,
		TextSize = 12,
		TextColor3 = COLOR_YELLOW,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
	}, v27, UDim2.new(1, -16, 0, 18), UDim2.new(0, 12, 0, 6))

	p1("TextLabel", {
		Text = p18,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
	}, v27, UDim2.new(1, -16, 0, 26), UDim2.new(0, 12, 0, 24))

	v27.Position = UDim2.new(1.2, 0, 0, 0)
	v3:Create(v27, TweenInfo.new(0.25), { Position = UDim2.new(0, 0, 0, 0) }):Play()

	task.delay(p19, function()
		local v28 = v3:Create(v27, TweenInfo.new(0.25), { Position = UDim2.new(1.2, 0, 0, 0) })
		v28:Play()
		v28.Completed:Wait()
		v27:Destroy()
	end)
end

--------------------------------------------------
-- WINDOW
--------------------------------------------------

function AzayaUI.new(p20)
	p20 = p20 or {}

	local v29 = setmetatable({}, AzayaUI)
	v29.Title = p20.Title or "AzayaUI"
	v29.ConfigFolder = p20.ConfigFolder or "AzayaUI"
	v29.Flags = {}
	v29._elements = {}
	v29._tabs = {}
	v29._activeTab = nil

	local v30 = p1("ScreenGui", {
		Name = "AzayaUI_" .. v29.Title,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, v7)
	v29.ScreenGui = v30

	-- Floating toggle icon (works well on mobile where a keybind isn't practical)
	local v31 = p1("TextButton", {
		Text = "AZ",
		Font = PIXEL_FONT,
		TextScaled = true,
		TextColor3 = COLOR_YELLOW,
		BackgroundColor3 = COLOR_BORDER,
		AutoButtonColor = false,
	}, v30, UDim2.new(0, 46, 0, 46), UDim2.new(0, 16, 0.4, 0))
	p7(v31)
	p9(v31)
	v29.ToggleIcon = v31

	-- Main window frame
	local v32 = p1("Frame", {
		BackgroundColor3 = COLOR_BG,
		BorderSizePixel = 0,
		Visible = false,
	}, v30, UDim2.new(0, 480, 0, 340), UDim2.new(0, 80, 0.5, -170))
	p7(v32)
	v29.MainFrame = v32

	-- Title bar
	local v33 = p1("Frame", {
		BackgroundColor3 = COLOR_YELLOW,
		BorderSizePixel = 0,
	}, v32, UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 0, 0))
	p7(v33)
	p9(v33)

	p1("TextLabel", {
		Text = v29.Title,
		Font = PIXEL_FONT,
		TextSize = 12,
		TextColor3 = COLOR_BORDER,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, v33, UDim2.new(1, -80, 1, 0), UDim2.new(0, 10, 0, 0))

	local v34 = p1("TextButton", {
		Text = "X",
		Font = PIXEL_FONT,
		TextSize = 12,
		TextColor3 = COLOR_RED,
		BackgroundColor3 = COLOR_BORDER,
		AutoButtonColor = false,
	}, v33, UDim2.new(0, 26, 0, 26), UDim2.new(1, -32, 0, 4))
	p7(v34)
	v34.MouseButton1Click:Connect(function()
		v32.Visible = false
	end)

	v31.MouseButton1Click:Connect(function()
		v32.Visible = not v32.Visible
	end)

	-- Tab bar (left column)
	local v35 = p1("Frame", {
		BackgroundColor3 = COLOR_PANEL,
		BorderSizePixel = 0,
	}, v32, UDim2.new(0, 110, 1, -34), UDim2.new(0, 0, 0, 34))
	p7(v35)

	local v36 = p1("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, v35)

	p1("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, v35)

	v29.TabBar = v35

	-- Content area (right side)
	local v37 = p1("Frame", {
		BackgroundTransparency = 1,
	}, v32, UDim2.new(1, -110, 1, -34), UDim2.new(0, 110, 0, 34))
	v29.ContentArea = v37

	-- Notification holder (top-right stack)
	local v38 = p1("Frame", {
		BackgroundTransparency = 1,
	}, v30, UDim2.new(0, 260, 1, -20), UDim2.new(1, -276, 0, 10))
	local v39 = p1("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, v38)
	v29.NotifyHolder = v38

	-- Desktop keybind toggle (M key) - mobile users rely on the floating icon instead
	v2.InputBegan:Connect(function(p21, p22)
		if p22 then return end
		if p21.KeyCode == Enum.KeyCode.M then
			v32.Visible = not v32.Visible
		end
	end)

	return v29
end

--------------------------------------------------
-- TABS
--------------------------------------------------

function AzayaUI:CreateTab(p23)
	local v40 = p1("TextButton", {
		Text = p23,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_DIM,
		BackgroundColor3 = COLOR_BORDER,
		AutoButtonColor = false,
	}, self.TabBar, UDim2.new(1, 0, 0, 30))
	p7(v40)

	local v41 = p1("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, self.ContentArea, UDim2.new(1, -12, 1, -12), UDim2.new(0, 6, 0, 6))

	local v42 = p1("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, v41)

	local v43 = { Page = v41, Button = v40, Window = self }
	setmetatable(v43, { __index = AzayaUI.TabMethods })

	table.insert(self._tabs, v43)

	v40.MouseButton1Click:Connect(function()
		for _, v44 in ipairs(self._tabs) do
			v44.Page.Visible = false
			v44.Button.TextColor3 = COLOR_DIM
			v44.Button.BackgroundColor3 = COLOR_BORDER
		end
		v41.Visible = true
		v40.TextColor3 = COLOR_YELLOW
		v40.BackgroundColor3 = COLOR_PANEL
	end)

	if #self._tabs == 1 then
		v41.Visible = true
		v40.TextColor3 = COLOR_YELLOW
		v40.BackgroundColor3 = COLOR_PANEL
	end

	return v43
end

--------------------------------------------------
-- TAB METHODS (sections)
--------------------------------------------------

AzayaUI.TabMethods = {}

function AzayaUI.TabMethods:CreateSection(p24)
	local v45 = p1("Frame", {
		BackgroundColor3 = COLOR_PANEL,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, self.Page, UDim2.new(1, 0, 0, 0))
	p7(v45)

	p1("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}, v45)

	p1("TextLabel", {
		Text = p24,
		Font = PIXEL_FONT,
		TextSize = 10,
		TextColor3 = COLOR_YELLOW,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, v45, UDim2.new(1, 0, 0, 16))

	local v46 = p1("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, v45, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 22))

	p1("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, v46)

	local v47 = { Holder = v46, Window = self.Window }
	setmetatable(v47, { __index = AzayaUI.SectionMethods })
	return v47
end

--------------------------------------------------
-- SECTION METHODS (elements)
--------------------------------------------------

AzayaUI.SectionMethods = {}

function AzayaUI.SectionMethods:AddLabel(p25)
	p1("TextLabel", {
		Text = p25,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_DIM,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, self.Holder, UDim2.new(1, 0, 0, 16))
end

function AzayaUI.SectionMethods:AddButton(p26, p27)
	local v48 = p1("TextButton", {
		Text = p26,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_TEXT,
		BackgroundColor3 = COLOR_BORDER,
		AutoButtonColor = false,
	}, self.Holder, UDim2.new(1, 0, 0, 30))
	p7(v48)

	v48.MouseButton1Click:Connect(function()
		local v49, v50 = pcall(p27)
		if not v49 then
			warn("[AzayaUI] Button callback error: " .. tostring(v50))
		end
	end)

	return v48
end

function AzayaUI.SectionMethods:AddToggle(p28, p29)
	p29 = p29 or {}
	local v51 = p29.Default or false
	local v52 = p29.Flag
	local v53 = p29.Callback or function() end

	local v54 = p1("Frame", {
		BackgroundTransparency = 1,
	}, self.Holder, UDim2.new(1, 0, 0, 26))

	p1("TextLabel", {
		Text = p28,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_TEXT,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, v54, UDim2.new(1, -50, 1, 0))

	local v55 = p1("TextButton", {
		Text = "",
		BackgroundColor3 = v51 and COLOR_GREEN or COLOR_BORDER,
		AutoButtonColor = false,
	}, v54, UDim2.new(0, 40, 0, 20), UDim2.new(1, -40, 0.5, -10))
	p7(v55)

	local function v56(p30)
		v55.BackgroundColor3 = p30 and COLOR_GREEN or COLOR_BORDER
	end

	v55.MouseButton1Click:Connect(function()
		v51 = not v51
		v56(v51)
		if v52 then self.Window.Flags[v52] = v51 end
		local v57, v58 = pcall(v53, v51)
		if not v57 then warn("[AzayaUI] Toggle callback error: " .. tostring(v58)) end
	end)

	if v52 then
		self.Window.Flags[v52] = v51
		self.Window._elements[v52] = {
			Update = function(p31)
				v51 = p31
				v56(v51)
			end,
		}
	end

	return v54
end

function AzayaUI.SectionMethods:AddSlider(p32, p33)
	p33 = p33 or {}
	local v59 = p33.Min or 0
	local v60 = p33.Max or 100
	local v61 = p33.Default or v59
	local v62 = p33.Flag
	local v63 = p33.Callback or function() end

	local v64 = p1("Frame", {
		BackgroundTransparency = 1,
	}, self.Holder, UDim2.new(1, 0, 0, 40))

	local v65 = p1("TextLabel", {
		Text = p32 .. ": " .. tostring(v61),
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_TEXT,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, v64, UDim2.new(1, 0, 0, 16))

	local v66 = p1("Frame", {
		BackgroundColor3 = COLOR_BORDER,
	}, v64, UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 20))
	p7(v66)

	local v67 = p1("Frame", {
		BackgroundColor3 = COLOR_YELLOW,
		BorderSizePixel = 0,
	}, v66, UDim2.new((v61 - v59) / (v60 - v59), 0, 1, 0))

	local function v68(p34)
		p34 = math.clamp(p34, v59, v60)
		v67.Size = UDim2.new((p34 - v59) / (v60 - v59), 0, 1, 0)
		v65.Text = p32 .. ": " .. tostring(math.floor(p34))
	end

	local v69 = false
	v66.InputBegan:Connect(function(p35)
		if p35.UserInputType == Enum.UserInputType.MouseButton1 or p35.UserInputType == Enum.UserInputType.Touch then
			v69 = true
		end
	end)
	v2.InputEnded:Connect(function(p36)
		if p36.UserInputType == Enum.UserInputType.MouseButton1 or p36.UserInputType == Enum.UserInputType.Touch then
			v69 = false
		end
	end)
	v2.InputChanged:Connect(function(p37)
		if not v69 then return end
		if p37.UserInputType ~= Enum.UserInputType.MouseMovement and p37.UserInputType ~= Enum.UserInputType.Touch then return end

		local v70 = math.clamp((p37.Position.X - v66.AbsolutePosition.X) / v66.AbsoluteSize.X, 0, 1)
		local v71 = v59 + (v60 - v59) * v70
		v68(v71)

		if v62 then self.Window.Flags[v62] = v71 end
		local v72, v73 = pcall(v63, v71)
		if not v72 then warn("[AzayaUI] Slider callback error: " .. tostring(v73)) end
	end)

	if v62 then
		self.Window.Flags[v62] = v61
		self.Window._elements[v62] = {
			Update = function(p38)
				v68(p38)
			end,
		}
	end

	return v64
end

function AzayaUI.SectionMethods:AddDropdown(p39, p40)
	p40 = p40 or {}
	local v74 = p40.Options or {}
	local v75 = p40.Default or v74[1]
	local v76 = p40.Flag
	local v77 = p40.Callback or function() end

	local v78 = p1("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, self.Holder, UDim2.new(1, 0, 0, 0))

	local v79 = p1("TextButton", {
		Text = p39 .. ": " .. tostring(v75),
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_TEXT,
		BackgroundColor3 = COLOR_BORDER,
		AutoButtonColor = false,
	}, v78, UDim2.new(1, 0, 0, 30))
	p7(v79)

	local v80 = p1("Frame", {
		BackgroundColor3 = COLOR_PANEL,
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.Y,
	}, v78, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 32))
	p7(v80)

	p1("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, v80)

	local function v81(p41)
		v75 = p41
		v79.Text = p39 .. ": " .. tostring(v75)
		if v76 then self.Window.Flags[v76] = v75 end
	end

	for _, v82 in ipairs(v74) do
		local v83 = p1("TextButton", {
			Text = v82,
			Font = Enum.Font.Code,
			TextSize = 12,
			TextColor3 = COLOR_TEXT,
			BackgroundColor3 = COLOR_BORDER,
			AutoButtonColor = false,
		}, v80, UDim2.new(1, 0, 0, 24))

		v83.MouseButton1Click:Connect(function()
			v81(v82)
			v80.Visible = false
			local v84, v85 = pcall(v77, v82)
			if not v84 then warn("[AzayaUI] Dropdown callback error: " .. tostring(v85)) end
		end)
	end

	v79.MouseButton1Click:Connect(function()
		v80.Visible = not v80.Visible
	end)

	if v76 then
		self.Window.Flags[v76] = v75
		self.Window._elements[v76] = { Update = v81 }
	end

	return v78
end

function AzayaUI.SectionMethods:AddTextbox(p42, p43)
	p43 = p43 or {}
	local v86 = p43.Placeholder or ""
	local v87 = p43.Default or ""
	local v88 = p43.Flag
	local v89 = p43.Callback or function() end

	local v90 = p1("Frame", {
		BackgroundTransparency = 1,
	}, self.Holder, UDim2.new(1, 0, 0, 46))

	p1("TextLabel", {
		Text = p42,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_TEXT,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, v90, UDim2.new(1, 0, 0, 16))

	local v91 = p1("TextBox", {
		Text = v87,
		PlaceholderText = v86,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_TEXT,
		PlaceholderColor3 = COLOR_DIM,
		BackgroundColor3 = COLOR_BORDER,
		ClearTextOnFocus = false,
	}, v90, UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 20))
	p7(v91)

	v91.FocusLost:Connect(function(p44)
		if v88 then self.Window.Flags[v88] = v91.Text end
		if p44 then
			local v92, v93 = pcall(v89, v91.Text)
			if not v92 then warn("[AzayaUI] Textbox callback error: " .. tostring(v93)) end
		end
	end)

	if v88 then
		self.Window.Flags[v88] = v87
		self.Window._elements[v88] = {
			Update = function(p45)
				v91.Text = p45
			end,
		}
	end

	return v90
end

function AzayaUI.SectionMethods:AddKeybind(p46, p47)
	p47 = p47 or {}
	local v94 = p47.Default or Enum.KeyCode.Unknown
	local v95 = p47.Flag
	local v96 = p47.Callback or function() end
	local v97 = false

	local v98 = p1("Frame", {
		BackgroundTransparency = 1,
	}, self.Holder, UDim2.new(1, 0, 0, 26))

	p1("TextLabel", {
		Text = p46,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = COLOR_TEXT,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, v98, UDim2.new(1, -90, 1, 0))

	local v99 = p1("TextButton", {
		Text = v94.Name,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = COLOR_YELLOW,
		BackgroundColor3 = COLOR_BORDER,
		AutoButtonColor = false,
	}, v98, UDim2.new(0, 80, 0, 24), UDim2.new(1, -80, 0.5, -12))
	p7(v99)

	v99.MouseButton1Click:Connect(function()
		v97 = true
		v99.Text = "..."
	end)

	v2.InputBegan:Connect(function(p48)
		if v97 and p48.UserInputType == Enum.UserInputType.Keyboard then
			v94 = p48.KeyCode
			v99.Text = v94.Name
			v97 = false
			if v95 then self.Window.Flags[v95] = v94.Name end
		elseif not v97 and p48.KeyCode == v94 then
			local v100, v101 = pcall(v96)
			if not v100 then warn("[AzayaUI] Keybind callback error: " .. tostring(v101)) end
		end
	end)

	if v95 then
		self.Window.Flags[v95] = v94.Name
		self.Window._elements[v95] = {
			Update = function(p49)
				local v102 = Enum.KeyCode[p49]
				if v102 then
					v94 = v102
					v99.Text = v94.Name
				end
			end,
		}
	end

	return v98
end

return AzayaUI
