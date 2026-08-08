-- https://lua.expert/
-- Structure Dumper - read-only tool buat inspect hierarki Workspace/Instance
-- Gunanya: begitu game rilis, jalanin ini buat cepet nemuin nama-nama
-- Instance yang dibutuhin (NPC, checkpoint, ATM, consumable, dll) tanpa
-- klik manual satu-satu di Explorer bawaan executor.
--
-- Hasil dump otomatis: (1) disimpan ke file, (2) di-copy ke clipboard,
-- (3) di-print ke console. Tinggal Ctrl+V buat langsung paste ke mana aja.
--
-- Ganti URL di baris ini dulu sebelum pakai (sama kayak AzayaUI.lua):
local AzayaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/azayatao/azayaUI/main/AzayaUI.lua"))()

--------------------------------------------------
-- CORE DUMP LOGIC
--------------------------------------------------

local v1 = game:GetService("HttpService")
local lastDumpContent = ""

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

local yieldCounter = 0

local function p3(p4, p5, p6, p7) -- dumpRecursive(instance, path, lines, maxDepth)
	p7 = p7 or 3
	if #p6 > 2000 then return end -- safety cap biar gak kegedean & gak berat

	local v20 = p4:GetChildren()

	-- Folder dekorasi/gede biasanya gak relevan buat kita, dan bikin proses berat.
	-- Kalau anaknya kebanyakan, cuma dicatet jumlahnya doang, gak diselam lebih dalam.
	if #v20 > 300 then
		table.insert(p6, p5 .. "  [SKIPPED: " .. #v20 .. " children, kebanyakan buat di-dump detail]")
		return
	end

	for _, v4 in ipairs(v20) do
		local v5 = p5 .. "." .. v4.Name
		local v6 = p1(v4)
		table.insert(p6, v5 .. "  (" .. v4.ClassName .. ")  " .. v6)

		yieldCounter = yieldCounter + 1
		if yieldCounter >= 150 then
			yieldCounter = 0
			task.wait() -- kasih nafas ke engine, biar gak freeze/crash pas workspace gede
		end

		if #p6 > 2000 then
			table.insert(p6, "... [TRUNCATED, lebih dari 2000 baris]")
			return
		end

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

	p3(p9, p9.Name, v7, 3)

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
-- SAVE + CLIPBOARD + CONSOLE HELPER
--------------------------------------------------

local function p13(p14, p15) -- saveDump(filename, content)
	lastDumpContent = p15

	if not isfolder("AzayaUI/Dumps") then
		makefolder("AzayaUI/Dumps")
	end

	local v12, v13 = pcall(function()
		writefile("AzayaUI/Dumps/" .. p14 .. ".txt", p15)
	end)

	local v14 = pcall(function()
		setclipboard(p15)
	end)

	print(p15)

	return v12, v13, v14
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

QuickSection:AddLabel("Hasil: file + clipboard + console (tinggal Ctrl+V)")
QuickSection:AddLabel("Coba 'Dump Ringan' dulu kalau map-nya berat/gede")

QuickSection:AddButton("Dump Ringan (depth 1, paling aman)", function()
	local v14 = {}
	table.insert(v14, "=== DUMP RINGAN: workspace (depth 1) ===")
	table.insert(v14, "Generated: " .. os.date())
	table.insert(v14, "")
	p3(workspace, "workspace", v14, 1)
	local v15 = table.concat(v14, "\n")

	local v17, v18, v19 = p13("workspace_shallow", v15)

	if v17 then
		Window:Notify("Dumper", (v19 and "Saved + copied to clipboard!" or "Saved to file (clipboard gagal)"), 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v18), 4)
	end
end)

QuickSection:AddButton("Dump workspace (depth 3, lebih berat)", function()
	local v16 = p8(workspace)
	local v17, v18, v19 = p13("workspace_full", v16)

	if v17 then
		Window:Notify("Dumper", (v19 and "Saved + copied to clipboard!" or "Saved to file (clipboard gagal)"), 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v18), 4)
	end
end)

QuickSection:AddButton("Dump PlayerGui (buat cari GUI currency/stats)", function()
	local v20 = game:GetService("Players").LocalPlayer.PlayerGui
	local v21 = p8(v20)
	local v22, v23, v24 = p13("playergui_full", v21)

	if v22 then
		Window:Notify("Dumper", (v24 and "Saved + copied to clipboard!" or "Saved to file (clipboard gagal)"), 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v23), 4)
	end
end)

QuickSection:AddButton("Dump ReplicatedStorage (buat cari RemoteEvent)", function()
	local v25 = game:GetService("ReplicatedStorage")
	local v26 = p8(v25)
	local v27, v28, v29 = p13("replicatedstorage_full", v26)

	if v27 then
		Window:Notify("Dumper", (v29 and "Saved + copied to clipboard!" or "Saved to file (clipboard gagal)"), 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v28), 4)
	end
end)

QuickSection:AddButton("Copy Last Dump Lagi", function()
	if lastDumpContent == "" then
		Window:Notify("Dumper", "Belum ada dump yang dijalanin", 3)
		return
	end

	local v30 = pcall(function()
		setclipboard(lastDumpContent)
	end)

	Window:Notify("Dumper", (v30 and "Copied!" or "Gagal copy ke clipboard"), 3)
end)

local SearchSection = MainTab:CreateSection("Search by Name")
SearchSection:AddLabel("Contoh: ketik 'saitama', 'roadwork', 'atm', 'muscle' dll")

local v31 = ""
SearchSection:AddTextbox("Kata kunci", {
	Placeholder = "misal: saitama",
	Callback = function(p16)
		v31 = p16
	end,
})

SearchSection:AddButton("Cari & simpan hasil", function()
	if v31 == "" then
		Window:Notify("Dumper", "Isi kata kunci dulu", 3)
		return
	end

	local v32 = p10(v31)
	local v33 = "=== SEARCH: \"" .. v31 .. "\" ===\nHasil: " .. #v32 .. "\n\n" .. table.concat(v32, "\n")

	local v34, v35, v36 = p13("search_" .. v31:gsub("%s+", "_"), v33)

	if v34 then
		Window:Notify("Dumper", #v32 .. " hasil" .. (v36 and " (copied!)" or ""), 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v35), 4)
	end
end)

local ManualSection = MainTab:CreateSection("Manual Path Dump")

local v37 = "workspace"
ManualSection:AddLabel("Ketik path Lua, misal: workspace.Ignore.Interactables")
ManualSection:AddTextbox("Path", {
	Placeholder = "workspace.NamaFolder",
	Default = "workspace",
	Callback = function(p17)
		v37 = p17
	end,
})

ManualSection:AddButton("Dump path ini", function()
	local v38, v39 = pcall(function()
		return loadstring("return " .. v37)()
	end)

	if not v38 or not v39 or typeof(v39) ~= "Instance" then
		Window:Notify("Dumper", "Path gak valid atau bukan Instance", 4)
		return
	end

	local v40 = p8(v39)
	local v41, v42, v43 = p13("manual_" .. v39.Name, v40)

	if v41 then
		Window:Notify("Dumper", (v43 and "Saved + copied to clipboard!" or "Saved to file (clipboard gagal)"), 4)
	else
		Window:Notify("Dumper", "Gagal simpan: " .. tostring(v42), 4)
	end
end)

Window:Notify("Structure Dumper", "Siap. Buka menu buat mulai dump.", 4)
