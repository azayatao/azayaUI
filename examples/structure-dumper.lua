-- https://lua.expert/
-- Structure Dumper - read-only tool buat inspect hierarki Workspace/Instance
-- Gunanya: begitu game rilis, jalanin ini buat cepet nemuin nama-nama
-- Instance yang dibutuhin (NPC, checkpoint, ATM, consumable, dll) tanpa
-- klik manual satu-satu di Explorer bawaan executor.
--
-- Ganti URL di baris ini dulu sebelum pakai (sama kayak AzayaUI.lua):
local AzayaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/azayatao/azayaUI/main/AzayaUI.lua"))()

--------------------------------------------------
-- CORE DUMP LOGIC
--------------------------------------------------

local v1 = game:GetService("HttpService")

local function p1(p2) -- classifyInstance(instance) -> tag string kalau "menarik"
	if p2:IsA("BillboardGui") then return "[BEAM/CHECKPOINT?]" end
	if p2:IsA("ProximityPrompt") then return "[INTERACT: " .. p2.ActionText .. "]" end
	if p2:IsA("ClickDetector") then return "[CLICKABLE]" end
	if p2:IsA("RemoteEvent") then return "[REMOTE EVENT]" end
	if p2:IsA("RemoteFunction") then return "[REMOTE FUNCTION]" end
	if p2:IsA("Humanoid") then return "[NPC/CHARACTER]" end
	if p2:IsA("TextLabel") or p2:IsA("TextButton") then
		local v3 = pcall(function() return p2.Text end)
		if v3 and p2.Text and #p2.Text > 0 and #p2.Text < 40 then
			return "[TEXT: \"" .. p2.Text .. "\"]"
		end
	end
	return ""
end

local function p3(p4, p5, p6, p7) -- dumpRecursive(instance, path, lines, maxDepth)
	p7 = p7 or 6
	if #p6 > 8000 then return end -- safety cap biar file gak kegedean

	for _, v4 in ipairs(p4:GetChildren()) do
		local v5 = p5 .. "." .. v4.Name
		local v6 = p1(v4)
		table.insert(p6, v5 .. "  (" .. v4.ClassName .. ")  " .. v6)

		if p7 > 0 then
			p3(v4, v5, p6, p7 - 1)
		end
	end
end

local function p8(p9) -- dumpFrom(rootInstance) -> string hasil dump lengkap
	local v7 = {}
	table.insert(v7, "=== DUMP: " .. p9:GetFullName() .. " ===")
	table.insert(v7, "Generated: " .. os.date())
	table.insert(v7, "")

	p3(p9, p9.Name, v7, 6)

	return table.concat(v7, "\n")
end

local function p10(p11) -- searchByName(nameSubstring) -> list hasil
	local v8 = {}
	local v9 = p11:lower()

	local function v10(p12)
		for _, v11 in ipairs(p12:GetChildren()) do
			if v11.Name:lower():find(v9, 1, true) then
				table.insert(v8, v11:GetFullName() .. "  (" .. v11.ClassName .. ")")
			end
			v10(v11)
		end
	end

	v10(workspace)
	v10(game:GetService("Players").LocalPlayer.PlayerGui)

	return v8
end

--------------------------------------------------
-- SAVE HELPER
--------------------------------------------------

local function p13(p14, p15) -- saveDump(filename, content)
	if not isfolder("AzayaUI/Dumps") then
		makefolder("AzayaUI/Dumps")
	end

	local v12, v13 = pcall(function()
		writefile("AzayaUI/Dumps/" .. p14 .. ".txt", p15)
	end)

	return v12, v13
end

--------------------------------------------------
-- UI
--------------------------------------------------

local Window = AzayaUI.new({
	Title = "Structure Dumper",
	ConfigFolder = "AzayaUI/StructureDumper",
})

local MainTab = Window:CreateTab("Dumper")
local QuickSection = MainTab:CreateSection("Quick Dump")

QuickSection:AddLabel("Dump seluruh Workspace (bisa berat kalau map gede)")
QuickSection:AddButton("Dump workspace", function()
	local v14 = p8(workspace)
	local v15, v16 = p13("workspace_full", v14)

	if v15 then
		Window:Notify("Dumper", "Saved to AzayaUI/Dumps/workspace_full.txt", 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v16), 4)
	end
end)

QuickSection:AddButton("Dump PlayerGui (buat cari GUI currency/stats)", function()
	local v17 = game:GetService("Players").LocalPlayer.PlayerGui
	local v18 = p8(v17)
	local v19, v20 = p13("playergui_full", v18)

	if v19 then
		Window:Notify("Dumper", "Saved to AzayaUI/Dumps/playergui_full.txt", 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v20), 4)
	end
end)

QuickSection:AddButton("Dump ReplicatedStorage (buat cari RemoteEvent)", function()
	local v21 = game:GetService("ReplicatedStorage")
	local v22 = p8(v21)
	local v23, v24 = p13("replicatedstorage_full", v22)

	if v23 then
		Window:Notify("Dumper", "Saved to AzayaUI/Dumps/replicatedstorage_full.txt", 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v24), 4)
	end
end)

local SearchSection = MainTab:CreateSection("Search by Name")
SearchSection:AddLabel("Contoh: ketik 'saitama', 'roadwork', 'atm', 'muscle' dll")

local v25 = ""
SearchSection:AddTextbox("Kata kunci", {
	Placeholder = "misal: saitama",
	Callback = function(p16)
		v25 = p16
	end,
})

SearchSection:AddButton("Cari & simpan hasil", function()
	if v25 == "" then
		Window:Notify("Dumper", "Isi kata kunci dulu", 3)
		return
	end

	local v26 = p10(v25)
	local v27 = "=== SEARCH: \"" .. v25 .. "\" ===\nHasil: " .. #v26 .. "\n\n" .. table.concat(v26, "\n")

	local v28, v29 = p13("search_" .. v25:gsub("%s+", "_"), v27)

	if v28 then
		Window:Notify("Dumper", #v26 .. " hasil ditemukan, tersimpan ke file", 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v29), 4)
	end

	print(v27) -- juga print ke console biar bisa langsung diliat
end)

local ManualSection = MainTab:CreateSection("Manual Path Dump")

local v30 = "workspace"
ManualSection:AddLabel("Ketik path Lua, misal: workspace.Ignore.Interactables")
ManualSection:AddTextbox("Path", {
	Placeholder = "workspace.NamaFolder",
	Default = "workspace",
	Callback = function(p17)
		v30 = p17
	end,
})

ManualSection:AddButton("Dump path ini", function()
	local v31, v32 = pcall(function()
		return loadstring("return " .. v30)()
	end)

	if not v31 or not v32 or typeof(v32) ~= "Instance" then
		Window:Notify("Dumper", "Path gak valid atau bukan Instance", 4)
		return
	end

	local v33 = p8(v32)
	local v34, v35 = p13("manual_" .. v32.Name, v33)

	if v34 then
		Window:Notify("Dumper", "Saved to AzayaUI/Dumps/manual_" .. v32.Name .. ".txt", 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v35), 4)
	end
end)

Window:Notify("Structure Dumper", "Siap. Buka menu buat mulai dump.", 4)
