-- https://lua.expert/
-- Contoh cara pakai AzayaUI di script manapun.
-- Ganti URL loadstring di bawah dengan link raw GitHub kamu sendiri
-- setelah AzayaUI.lua di-upload ke repo/gist kamu.

local AzayaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/azayatao/azayaUI/main/AzayaUI.lua"))()

local Window = AzayaUI.new({
	Title = "Contoh Script",
	ConfigFolder = "AzayaUI/ContohScript", -- folder tempat config disimpan
})

local MainTab = Window:CreateTab("Main")
local SettingsTab = Window:CreateTab("Settings")

--------------------------------------------------
-- TAB: Main
--------------------------------------------------

local FarmSection = MainTab:CreateSection("Farming")

FarmSection:AddToggle("Auto Farm Contoh", {
	Default = false,
	Flag = "auto_farm_contoh", -- dipakai buat config persistence
	Callback = function(state)
		print("Auto Farm:", state)
	end,
})

FarmSection:AddSlider("Kecepatan", {
	Min = 0,
	Max = 100,
	Default = 50,
	Flag = "kecepatan",
	Callback = function(value)
		print("Kecepatan diatur ke:", value)
	end,
})

FarmSection:AddDropdown("Mode", {
	Options = { "Aman", "Cepat", "Maksimal" },
	Default = "Aman",
	Flag = "mode",
	Callback = function(selected)
		print("Mode dipilih:", selected)
	end,
})

--------------------------------------------------
-- TAB: Settings
--------------------------------------------------

local ConfigSection = SettingsTab:CreateSection("Konfigurasi")

ConfigSection:AddButton("Save Config", function()
	Window:SaveConfig("default")
end)

ConfigSection:AddButton("Load Config", function()
	Window:LoadConfig("default")
end)

ConfigSection:AddKeybind("Toggle Menu", {
	Default = Enum.KeyCode.RightControl,
	Flag = "menu_keybind",
	Callback = function()
		print("Keybind ditekan")
	end,
})

--------------------------------------------------
-- NOTIFIKASI CONTOH
--------------------------------------------------

Window:Notify("AzayaUI", "Script berhasil dimuat!", 3)
