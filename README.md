# AzayaUI

Library GUI Roblox executor bergaya 8-bit/arcade — outline hitam tebal, aksen kuning-merah, sudut tajam (gak ada rounded corner, sengaja biar kerasa pixel-art). Dibikin biar semua script kamu ke depannya (Evade, Battlegrounds, atau apapun) tinggal pakai satu library yang sama, gak perlu load Rayfield atau library orang lain lagi.

## Fitur

- **Draggable** — window utama dan tombol toggle bisa digeser, support mouse **dan** touch (mobile-friendly)
- **Floating toggle icon** — tombol "AZ" kecil yang selalu ada di layar buat buka/tutup menu (penting buat mobile, karena keybind `M` cuma jalan di desktop)
- **Tab + Section system** — pengelompokan menu rapi
- **Elemen lengkap**: Button, Toggle, Slider, Dropdown, TextBox, Keybind, Label
- **Config persistence** — `SaveConfig()` / `LoadConfig()`, otomatis nyimpen semua value elemen yang dikasih `Flag`, tersimpan sebagai file JSON lewat `writefile`/`readfile`
- **Notifikasi** — popup kecil di pojok kanan atas, auto-hilang setelah durasi tertentu

## Cara Pakai

```lua
local AzayaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/azayatao/azayaUI/main/AzayaUI.lua"))()

local Window = AzayaUI.new({
    Title = "Nama Script Kamu",
    ConfigFolder = "AzayaUI/NamaScript", -- folder penyimpanan config
})

local Tab = Window:CreateTab("Main")
local Section = Tab:CreateSection("Farming")

Section:AddToggle("Auto Farm", {
    Default = false,
    Flag = "auto_farm", -- kalau diisi, otomatis ke-track buat save/load config
    Callback = function(state)
        -- logic kamu di sini
    end,
})
```

Lihat `example-usage.lua` buat contoh lengkap semua jenis elemen.

## Setup

1. Upload `AzayaUI.lua` ke GitHub repo (bisa public/private) atau GitHub Gist
2. Ambil **raw URL**-nya
3. Ganti URL placeholder di `example-usage.lua` (atau script kamu sendiri) dengan raw URL itu
4. `loadstring(game:HttpGet(...))()` di awal script kamu, langsung bisa dipakai

## Referensi API

### `AzayaUI.new(config)`
- `config.Title` — judul window
- `config.ConfigFolder` — folder tempat config disimpan (default: `"AzayaUI"`)

### `Window:CreateTab(name)` → Tab
### `Tab:CreateSection(name)` → Section

### Section methods:
| Method | Opsi |
|---|---|
| `AddLabel(text)` | teks info doang |
| `AddButton(text, callback)` | |
| `AddToggle(text, {Default, Flag, Callback})` | |
| `AddSlider(text, {Min, Max, Default, Flag, Callback})` | |
| `AddDropdown(text, {Options, Default, Flag, Callback})` | |
| `AddTextbox(text, {Placeholder, Default, Flag, Callback})` | |
| `AddKeybind(text, {Default, Flag, Callback})` | |

### `Window:SaveConfig(name)` / `Window:LoadConfig(name)`
Nyimpen/muat semua value elemen yang punya `Flag`. Nama file: `ConfigFolder/name.json`.

### `Window:Notify(title, text, duration)`
Popup notifikasi, `duration` dalam detik (default 3).

## Catatan Teknis

- Font pixel (`PressStart2P`) dipakai buat title bar & label section; kalau gak kesupport di executor kamu, otomatis fallback ke `Enum.Font.Code`
- Semua elemen interaktif udah di-`pcall` di callback-nya, jadi error di satu tombol gak bakal nge-crash seluruh script
- Belum pernah dites langsung di Roblox client (dibangun tanpa akses ke game) — sintaks udah divalidasi pakai Lua 5.4 parser, tapi tetap cek behavior asli pas pertama kali dipakai, siapa tau ada penyesuaian kecil yang perlu dilakuin
