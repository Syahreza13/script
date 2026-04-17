-- LOAD RAYFIELD
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "SR13 FINAL STABLE",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Ordered Craft System",
    ConfigurationSaving = { Enabled = false }
})
local Tab = Window:CreateTab("Main", 4483362458)

-- SERVICES
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local player            = Players.LocalPlayer
local character         = player.Character or player.CharacterAdded:Wait()
local root              = character:WaitForChild("HumanoidRootPart")

-- STATE FLAGS
local AUTO_FORAGE = false
local AUTO_HAND   = false
local AUTO_NPC    = false

-- CHARACTER REFRESH
local function refreshCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    root = character:WaitForChild("HumanoidRootPart")
end
player.CharacterAdded:Connect(function()
    task.wait(1)
    refreshCharacter()
end)

-- REMOTES
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Clicked")

-- ANTI AFK
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- LOOP INPUT
local LOOP_COUNT = 1
Tab:CreateInput({
    Name = "🔁 Loop Count",
    PlaceholderText = "1",
    Callback = function(txt)
        local num = tonumber(txt)
        LOOP_COUNT = (num and num > 0) and math.floor(num) or 1
        print("🔁 Loop set:", LOOP_COUNT)
    end
})

-- GLOBAL LOCK
local CRAFT_LOCK = false
local function lock()   CRAFT_LOCK = true  end
local function unlock() CRAFT_LOCK = false end

-- ════════════════════════════════════════════════════════════
-- RESULT DETECTOR (NPC) — lazy getter
-- ════════════════════════════════════════════════════════════
local function getResultLabel()
    local ok, lbl = pcall(function()
        return player.PlayerGui.ScreenGui.Alchemy.SelectionFrame.Success
    end)
    return ok and lbl or nil
end

local function getResultText()
    local lbl = getResultLabel()
    if not lbl then return "" end
    local ok, text = pcall(function() return lbl.Text end)
    return ok and text or ""
end

local function waitForResult(textBefore, timeoutSec)
    local deadline    = tick() + timeoutSec
    local lastSeen    = textBefore
    local stableCount = 0
    while tick() < deadline do
        if not AUTO_NPC then return "CANCELLED" end
        task.wait(0.15)
        local lbl_ = getResultLabel()
        if not lbl_ then task.wait(0.5); continue end
        local ok, current = pcall(function() return lbl_.Text end)
        if not ok then continue end
        if current ~= "" then
            if current ~= lastSeen then
                lastSeen = current; stableCount = 1
            else
                stableCount += 1
            end
            if stableCount >= 2 and current ~= textBefore then
                local lower = string.lower(current)
                if string.find(lower, "recipe")  then return "NO_RECIPE"
                elseif string.find(lower, "spirit") then return "NO_STONE"
                else return "SUCCESS" end
            end
        end
    end
    return "TIMEOUT"
end

-- ════════════════════════════════════════════════════════════
-- TIMER DETECTOR (Hand) — lazy getter
-- ════════════════════════════════════════════════════════════
local function getTimerValue()
    local ok, result = pcall(function()
        local sg  = player.PlayerGui:FindFirstChild("ScreenGui")
        local alc = sg and sg:FindFirstChild("Alchemy")
        local wf  = alc and alc:FindFirstChild("WaitFrame")
        local lbl = wf and wf:FindFirstChild("Time")
        if not lbl then return 0 end
        return tonumber(string.match(lbl.Text or "", "%-?[%d%.]+")) or 0
    end)
    if ok and result and result > 0 then return result end
    return 0
end

local function isTimerRunning() return getTimerValue() > 0 end

-- ════════════════════════════════════════════════════════════
-- FOREST NAVIGATION
-- Anchor sebelum Destroy → tidak jatuh → unanchor setelah unload
-- ════════════════════════════════════════════════════════════
local function leaveForest()
    if root and root.Parent then root.Anchored = true end
    task.wait(0.2)
    remote:FireServer("Forest", false, "Destroy")
    task.wait(3)
    if root and root.Parent then root.Anchored = false end
    task.wait(0.5)
end

-- ════════════════════════════════════════════════════════════
-- INGREDIENT CHECK
-- ════════════════════════════════════════════════════════════
local function getHerbCount(name)
    local ok, mainFrame = pcall(function()
        return player.PlayerGui.ScreenGui.Alchemy.SelectionFrame.lister.MainFrame
    end)
    if not ok then return 0 end
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child.Name:lower() == name:lower() then
            for _, d in ipairs(child:GetDescendants()) do
                if d:IsA("TextLabel") then
                    local n = string.match(d.Text, "%d+")
                    if n then return tonumber(n) end
                end
            end
        end
    end
    return 0
end

local function canCraft(ingredients)
    for herb, qty in pairs(ingredients) do
        if getHerbCount(herb) < qty then return false end
    end
    return true
end

local function missingLog(recipeName, ingredients)
    local missing = {}
    for herb, qty in pairs(ingredients) do
        local have = getHerbCount(herb)
        if have < qty then
            table.insert(missing, herb.." ("..have.."/"..qty..")")
        end
    end
    if #missing > 0 then
        print("⏳", recipeName, "→", table.concat(missing, ", "))
    end
end

-- ════════════════════════════════════════════════════════════
-- FOREST ITEM DETECTION & COLLECTION
-- ════════════════════════════════════════════════════════════
local collectibles = {
    "Azure Serpent Grass","Basic Herb","Bitter Jade Grass","Black Iron Root",
    "Blue Wave Coral Herb","Cloud Mist Herb","Common Spirit Grass",
    "Crimson Flame Mushroom","Dandelion of Qi","Healing Sunflower",
    "Heavenly Spirit Vine","Ironbone Grass","Moonlight Jade Leaf",
    "Mountain Green Herb","Nine Suns Flame Grass","Purple Lightning Orchid",
    "Red Ginseng","Seven Star Flower","Silverleaf Herb","Spirit Spring Herb",
    "Starlight Dew Herb","Thousand Year Lotus","Wild Bitter Grass",
    "Wild Spirit Grass","Chest"
}
local collectSet = {}
for _, v in ipairs(collectibles) do collectSet[v] = true end

-- FIX: cek semua collectible, bukan hanya 3
local function forestHasItems()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if collectSet[obj.Name] then return true end
    end
    return false
end

local function getTargetPart(item)
    return item:IsA("BasePart") and item
        or item.PrimaryPart
        or item:FindFirstChildWhichIsA("BasePart")
end

local function getDistance(obj)
    local part = getTargetPart(obj)
    return part and (root.Position - part.Position).Magnitude or math.huge
end

local function getItems()
    local items = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if collectSet[obj.Name] and getTargetPart(obj) then
            table.insert(items, obj)
        end
    end
    table.sort(items, function(a, b) return getDistance(a) < getDistance(b) end)
    return items
end

--[[
  collectItem — FIX:
  - Coba hingga MAX_ATTEMPT kali per item
  - Verifikasi item.Parent == nil setelah tiap attempt (benar-benar tercollect)
  - Jeda lebih panjang tiap attempt agar server tidak throttle
  - Tidak ada savedCFrame restore → item baru diambil dari posisi terakhir
    (lebih efisien, tidak bolak-balik)
]]
local function collectItem(item)
    local OFFSETS = {
        Vector3.new(0, 3, 0),
        Vector3.new(2, 2, 0),
        Vector3.new(-2, 2, 0),
        Vector3.new(0, 2, 2),
        Vector3.new(0, 2, -2),
    }

    for attempt = 1, #OFFSETS do
        if not item or not item.Parent then return end

        local targetPart = getTargetPart(item)
        local prompt     = item:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not targetPart or not prompt then return end
        if not root or not root.Parent then refreshCharacter(); task.wait(1); return end

        root.CFrame = targetPart.CFrame + OFFSETS[attempt]
        task.wait(0.1) -- beri waktu physics settle

        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        pcall(function() fireproximityprompt(prompt) end)

        -- Tunggu konfirmasi server (max 0.8s) — jeda lebih lama agar server tidak throttle
        local deadline = tick() + 0.8
        repeat task.wait(0.1) until not item.Parent or tick() > deadline

        if not item.Parent then return end
        -- Gagal → jeda sebelum attempt berikutnya agar server tidak reject
        task.wait(0.3)
    end
end

-- ════════════════════════════════════════════════════════════
-- RECIPES
-- ════════════════════════════════════════════════════════════
local recipes = {
    -- Mistveil Focus Pill
    {"Mistveil Focus Pill A", {["Spirit Spring Herb"]=2,["Azure Serpent Grass"]=1,["Silverleaf Herb"]=2,["Thousand Year Lotus"]=1}},
    {"Mistveil Focus Pill B", {["Spirit Spring Herb"]=1,["Blue Wave Coral Herb"]=1,["Cloud Mist Herb"]=3,["Thousand Year Lotus"]=1}},
    {"Mistveil Focus Pill C", {["Spirit Spring Herb"]=2,["Silverleaf Herb"]=3,["Starlight Dew Herb"]=1}},
    {"Mistveil Focus Pill D", {["Blue Wave Coral Herb"]=1,["Spirit Spring Herb"]=2,["Azure Serpent Grass"]=1,["Silverleaf Herb"]=2}},
    {"Mistveil Focus Pill E", {["Blue Wave Coral Herb"]=1,["Cloud Mist Herb"]=1,["Spirit Spring Herb"]=1,["Azure Serpent Grass"]=1,["Silverleaf Herb"]=1,["Seven Star Flower"]=1}},
    {"Mistveil Focus Pill F", {["Heavenly Spirit Vine"]=2,["Cloud Mist Herb"]=1,["Spirit Spring Herb"]=3}},
    {"Mistveil Focus Pill G", {["Heavenly Spirit Vine"]=1,["Cloud Mist Herb"]=2,["Blue Wave Coral Herb"]=1,["Spirit Spring Herb"]=2}},
    {"Mistveil Focus Pill H", {["Blue Wave Coral Herb"]=1,["Cloud Mist Herb"]=2,["Spirit Spring Herb"]=1,["Azure Serpent Grass"]=1,["Seven Star Flower"]=1}},
    {"Mistveil Focus Pill I", {["Starlight Dew Herb"]=1,["Cloud Mist Herb"]=2,["Silverleaf Herb"]=1,["Spirit Spring Herb"]=2}},
    {"Mistveil Focus Pill J", {["Spirit Spring Herb"]=2,["Purple Lightning Orchid"]=1,["Seven Star Flower"]=1,["Silverleaf Herb"]=2}},
    {"Mistveil Focus Pill K", {["Cloud Mist Herb"]=1,["Spirit Spring Herb"]=1,["Azure Serpent Grass"]=1,["Silverleaf Herb"]=1,["Seven Star Flower"]=2}},
    {"Mistveil Focus Pill L", {["Spirit Spring Herb"]=3,["Azure Serpent Grass"]=2,["Cloud Mist Herb"]=1}},
    {"Mistveil Focus Pill M", {["Spirit Spring Herb"]=3,["Purple Lightning Orchid"]=1,["Silverleaf Herb"]=2}},
    {"Mistveil Focus Pill N", {["Spirit Spring Herb"]=2,["Seven Star Flower"]=1,["Silverleaf Herb"]=3}},
    {"Mistveil Focus Pill O", {["Spirit Spring Herb"]=2,["Seven Star Flower"]=1,["Silverleaf Herb"]=2,["Cloud Mist Herb"]=1}},
    {"Mistveil Focus Pill P", {["Silverleaf Herb"]=3,["Spirit Spring Herb"]=3}},
    {"Mistveil Focus Pill Q", {["Spirit Spring Herb"]=3,["Purple Lightning Orchid"]=1,["Cloud Mist Herb"]=2}},
    {"Mistveil Focus Pill R", {["Spirit Spring Herb"]=2,["Seven Star Flower"]=1,["Silverleaf Herb"]=1,["Cloud Mist Herb"]=2}},
    {"Mistveil Focus Pill S", {["Spirit Spring Herb"]=2,["Cloud Mist Herb"]=1,["Silverleaf Herb"]=1,["Wild Spirit Grass"]=1,["Purple Lightning Orchid"]=1}},
    {"Mistveil Focus Pill T", {["Cloud Mist Herb"]=3,["Spirit Spring Herb"]=3}},
    {"Mistveil Focus Pill U", {["Spirit Spring Herb"]=2,["Cloud Mist Herb"]=2,["Silverleaf Herb"]=1,["Wild Spirit Grass"]=1}},
    {"Mistveil Focus Pill V", {["Spirit Spring Herb"]=2,["Silverleaf Herb"]=2,["Dandelion of Qi"]=1,["Purple Lightning Orchid"]=1}},
    {"Mistveil Focus Pill W", {["Spirit Spring Herb"]=1,["Silverleaf Herb"]=1,["Dandelion of Qi"]=1,["Purple Lightning Orchid"]=1,["Cloud Mist Herb"]=1,["Seven Star Flower"]=1}},
    {"Mistveil Focus Pill X", {["Spirit Spring Herb"]=1,["Cloud Mist Herb"]=1,["Silverleaf Herb"]=2,["Dandelion of Qi"]=1,["Seven Star Flower"]=1}},
    {"Mistveil Focus Pill Y", {["Dandelion of Qi"]=2,["Purple Lightning Orchid"]=1,["Cloud Mist Herb"]=2,["Spirit Spring Herb"]=1}},
    -- Jade Tide Pill
    {"Jade Tide Pill A", {["Moonlight Jade Leaf"]=2,["Blue Wave Coral Herb"]=2,["Bitter Jade Grass"]=2}},
    {"Jade Tide Pill B", {["Black Iron Root"]=1,["Moonlight Jade Leaf"]=2,["Blue Wave Coral Herb"]=2,["Bitter Jade Grass"]=2}},
    {"Jade Tide Pill C", {["Black Iron Root"]=2,["Blue Wave Coral Herb"]=2,["Bitter Jade Grass"]=2}},
    {"Jade Tide Pill D", {["Blue Wave Coral Herb"]=2,["Moonlight Jade Leaf"]=2,["Red Ginseng"]=1,["Bitter Jade Grass"]=1}},
    {"Jade Tide Pill E", {["Ironbone Grass"]=2,["Blue Wave Coral Herb"]=2,["Bitter Jade Grass"]=2}},
    {"Jade Tide Pill F", {["Crimson Flame Mushroom"]=2,["Blue Wave Coral Herb"]=2,["Red Ginseng"]=2}},
    {"Jade Tide Pill G", {["Blue Wave Coral Herb"]=2,["Black Iron Root"]=1,["Crimson Flame Mushroom"]=1,["Bitter Jade Grass"]=2}},
    -- Celestial Harmony Pill
    {"Celestial Harmony Pill A", {["Thousand Year Lotus"]=1,["Seven Star Flower"]=2,["Moonlight Jade Leaf"]=1,["Silverleaf Herb"]=1,["Starlight Dew Herb"]=1}},
    {"Celestial Harmony Pill B", {["Seven Star Flower"]=2,["Moonlight Jade Leaf"]=1,["Silverleaf Herb"]=1,["Starlight Dew Herb"]=2}},
    {"Celestial Harmony Pill C", {["Seven Star Flower"]=2,["Black Iron Root"]=1,["Silverleaf Herb"]=1,["Starlight Dew Herb"]=2}},
    {"Celestial Harmony Pill D", {["Seven Star Flower"]=2,["Black Iron Root"]=1,["Blue Wave Coral Herb"]=2,["Silverleaf Herb"]=1}},
    {"Celestial Harmony Pill E", {["Seven Star Flower"]=2,["Spirit Spring Herb"]=1,["Silverleaf Herb"]=1,["Thousand Year Lotus"]=1,["Moonlight Jade Leaf"]=1}},
    {"Celestial Harmony Pill F", {["Cloud Mist Herb"]=1,["Seven Star Flower"]=3,["Moonlight Jade Leaf"]=1,["Starlight Dew Herb"]=1}},
    {"Celestial Harmony Pill G", {["Silverleaf Herb"]=1,["Seven Star Flower"]=1,["Mountain Green Herb"]=1,["Dandelion of Qi"]=1,["Wild Spirit Grass"]=2}},
    {"Celestial Harmony Pill H", {["Thousand Year Lotus"]=1,["Silverleaf Herb"]=1,["Seven Star Flower"]=3,["Moonlight Jade Leaf"]=1}},
    -- Concentration Pill
    {"Concentration Pill A", {["Azure Serpent Grass"]=2,["Starlight Dew Herb"]=2,["Heavenly Spirit Vine"]=1,["Thousand Year Lotus"]=1}},
    {"Concentration Pill B", {["Azure Serpent Grass"]=3,["Thousand Year Lotus"]=3}},
    {"Concentration Pill C", {["Azure Serpent Grass"]=3,["Starlight Dew Herb"]=3}},
    {"Concentration Pill D", {["Starlight Dew Herb"]=2,["Azure Serpent Grass"]=2,["Heavenly Spirit Vine"]=1,["Blue Wave Coral Herb"]=1}},
    {"Concentration Pill E", {["Azure Serpent Grass"]=2,["Starlight Dew Herb"]=2,["Purple Lightning Orchid"]=1,["Seven Star Flower"]=1}},
    {"Concentration Pill F", {["Cloud Mist Herb"]=3,["Starlight Dew Herb"]=3}},
    {"Concentration Pill G", {["Azure Serpent Grass"]=3,["Starlight Dew Herb"]=1,["Seven Star Flower"]=2}},
    {"Concentration Pill H", {["Seven Star Flower"]=3,["Azure Serpent Grass"]=3}},
    {"Concentration Pill I", {["Azure Serpent Grass"]=3,["Seven Star Flower"]=1,["Dandelion of Qi"]=2}},
    -- Stormheart Pill
    {"Stormheart Pill A", {["Azure Serpent Grass"]=2,["Cloud Mist Herb"]=2,["Spirit Spring Herb"]=2}},
    {"Stormheart Pill B", {["Heavenly Spirit Vine"]=2,["Spirit Spring Herb"]=2,["Cloud Mist Herb"]=2}},
    {"Stormheart Pill C", {["Cloud Mist Herb"]=4,["Spirit Spring Herb"]=2}},
    {"Stormheart Pill D", {["Cloud Mist Herb"]=4,["Spirit Spring Herb"]=1,["Dandelion of Qi"]=1}},
    {"Stormheart Pill E", {["Dandelion of Qi"]=1,["Seven Star Flower"]=1,["Purple Lightning Orchid"]=1,["Cloud Mist Herb"]=3}},
    -- Starborn Agility Pill
    {"Starborn Agility Pill A", {["Seven Star Flower"]=1,["Starlight Dew Herb"]=4,["Heavenly Spirit Vine"]=1}},
    {"Starborn Agility Pill B", {["Seven Star Flower"]=3,["Cloud Mist Herb"]=1,["Spirit Spring Herb"]=2}},
    {"Starborn Agility Pill C", {["Seven Star Flower"]=2,["Azure Serpent Grass"]=1,["Dandelion of Qi"]=3}},
    -- Seven Star Enlightenment Pill
    {"Seven Star Enlightenment Pill A", {["Thousand Year Lotus"]=1,["Blue Wave Coral Herb"]=2,["Starlight Dew Herb"]=2,["Heavenly Spirit Vine"]=1}},
    -- Void Clarity Pill
    {"Void Clarity Pill A", {["Starlight Dew Herb"]=2,["Cloud Mist Herb"]=2,["Heavenly Spirit Vine"]=1,["Bitter Jade Grass"]=1}},
    {"Void Clarity Pill B", {["Blue Wave Coral Herb"]=2,["Cloud Mist Herb"]=2,["Heavenly Spirit Vine"]=1,["Bitter Jade Grass"]=1}},
    {"Void Clarity Pill C", {["Blue Wave Coral Herb"]=2,["Cloud Mist Herb"]=2,["Azure Serpent Grass"]=1,["Bitter Jade Grass"]=1}},
    {"Void Clarity Pill D", {["Blue Wave Coral Herb"]=2,["Cloud Mist Herb"]=3,["Bitter Jade Grass"]=1}},
    {"Void Clarity Pill E", {["Silverleaf Herb"]=1,["Cloud Mist Herb"]=2,["Seven Star Flower"]=2,["Bitter Jade Grass"]=1}},
    {"Void Clarity Pill F", {["Basic Herb"]=1,["Cloud Mist Herb"]=2,["Thousand Year Lotus"]=2,["Heavenly Spirit Vine"]=1}},
    -- Dragon Pulse Pill
    {"Dragon Pulse Pill A", {["Blue Wave Coral Herb"]=2,["Azure Serpent Grass"]=1,["Spirit Spring Herb"]=1,["Moonlight Jade Leaf"]=2}},
    {"Dragon Pulse Pill B", {["Blue Wave Coral Herb"]=2,["Cloud Mist Herb"]=1,["Spirit Spring Herb"]=1,["Ironbone Grass"]=2}},
    -- Special
    {"Lotus Nirvana Pill",   {["Thousand Year Lotus"]=6}},
    {"Heavenly Spirit Pill", {["Heavenly Spirit Vine"]=2,["Starlight Dew Herb"]=3,["Moonlight Jade Leaf"]=1}},
}
local RECIPE_COUNT = #recipes

-- COUNTERS
local HAND_DONE = 0
local NPC_DONE  = 0

-- ════════════════════════════════════════════════════════════
-- CRAFT RUNNERS
-- ════════════════════════════════════════════════════════════

--[[
  AUTO HAND — Fire & Forget
  Skip: TIDAK ADA. Semua recipe dicoba.
  Tunggu stok: infinite wait di recipe yang bersangkutan.
  Timer: jika timer masih jalan dari craft sebelumnya, tunggu habis.
]]
local function runHandCraftPass()
    if not AUTO_HAND then return end

    for i = 1, RECIPE_COUNT do
        if not AUTO_HAND then break end
        local recipeName      = recipes[i][1]
        local ingredientTable = recipes[i][2]

        -- Tunggu stok — tidak ada skip, tidak ada timeout
        local _logH = 0
        while not canCraft(ingredientTable) do
            if not AUTO_HAND then break end
            _logH += 1
            if _logH % 4 == 1 then missingLog(recipeName, ingredientTable) end
            task.wait(5)
        end
        if not AUTO_HAND then break end

        -- Tunggu timer dari craft sebelumnya
        local existing = getTimerValue()
        if existing > 0 then
            task.wait(existing + 0.5)
        end
        if not AUTO_HAND then break end

        lock()
        remote:FireServer("AlchemyController", false, "craft", ingredientTable)
        task.wait(0.3)
        remote:FireServer("AlchemyController", false, "mixing", 1)
        task.wait(2)
        remote:FireServer("AlchemyController", false, "finishPill")
        HAND_DONE += 1
        unlock()
        task.wait(0.5)
    end
    print("🛠 Hand pass done:", HAND_DONE)
end

--[[
  AUTO NPC — Sequential, tunggu konfirmasi server
  Skip: HANYA jika server balas NO_RECIPE.
  NO_STONE: retry recipe yang sama setelah 10s.
  Stok kurang: infinite wait di recipe yang bersangkutan.
]]
local function runNPCCraftPass()
    if not AUTO_NPC then return end

    local i = 1
    while i <= RECIPE_COUNT do
        if not AUTO_NPC then break end
        local recipeName      = recipes[i][1]
        local ingredientTable = recipes[i][2]

        -- Tunggu stok — tidak ada skip, tidak ada timeout
        local _logN = 0
        while not canCraft(ingredientTable) do
            if not AUTO_NPC then break end
            _logN += 1
            if _logN % 4 == 1 then missingLog(recipeName, ingredientTable) end
            task.wait(5)
        end
        if not AUTO_NPC then break end

        lock()
        local textBefore = getResultText()
        remote:FireServer("AlchemyController", false, "alchemist", ingredientTable)
        task.wait(1.5)
        local result = waitForResult(textBefore, 15)

        if not AUTO_NPC then unlock(); break end

        if result == "SUCCESS" or result == "TIMEOUT" then
            NPC_DONE += 1
            print("✅", recipeName, "| NPC:", NPC_DONE)
            unlock(); i += 1

        elseif result == "NO_RECIPE" then
            -- Satu-satunya kondisi skip
            print("⏭ NO_RECIPE:", recipeName)
            unlock(); i += 1

        elseif result == "NO_STONE" then
            -- Jangan skip, retry
            unlock()
            task.wait(10)

        elseif result == "CANCELLED" then
            unlock(); break
        end

        task.wait(2)
    end
    print("🧪 NPC pass done:", NPC_DONE)
end

-- ════════════════════════════════════════════════════════════
-- LOOP FORAGE — independen, retry tiap 5s
-- ════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.5)
        if not AUTO_FORAGE then task.wait(1); continue end

        -- Pastikan root valid
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            refreshCharacter(); task.wait(2); continue
        end
        root = player.Character.HumanoidRootPart

        remote:FireServer("Forest", false, "Create")
        task.wait(3)

        local waitItems = tick() + 8
        repeat task.wait(1) until forestHasItems() or tick() > waitItems

        if forestHasItems() then
            -- Collect semua item
            while forestHasItems() and AUTO_FORAGE do
                local items = getItems()
                if #items == 0 then break end
                for _, item in ipairs(items) do
                    if not AUTO_FORAGE then break end
                    collectItem(item)
                    -- Jeda antar item — beri server waktu proses sebelum request berikutnya
                    task.wait(0.3)
                end
                task.wait(0.2)
            end
            print("✅ Forest collected")
            leaveForest()
            task.wait(5)
        else
            task.wait(5)
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- LOOP HAND CRAFT — independen
-- LOOP_COUNT = jumlah pengulangan semua recipe
-- ════════════════════════════════════════════════════════════
local HAND_RUNNING = false
task.spawn(function()
    while true do
        task.wait(0.5)
        if not AUTO_HAND or HAND_RUNNING then task.wait(1); continue end

        HAND_RUNNING = true
        HAND_DONE = 0
        local target = RECIPE_COUNT * LOOP_COUNT
        print("🛠 Hand START —", LOOP_COUNT, "pass ×", RECIPE_COUNT, "=", target, "pills")

        for pass = 1, LOOP_COUNT do
            if not AUTO_HAND then break end
            print("🛠 Pass", pass, "/", LOOP_COUNT)
            runHandCraftPass()
        end

        AUTO_HAND    = false
        HAND_RUNNING = false
        Rayfield:Notify({
            Title    = "✅ Handcraft Done",
            Content  = HAND_DONE .. " / " .. target .. " pills",
            Duration = 8
        })
        print("🛠 Hand DONE:", HAND_DONE, "/", target)
    end
end)

-- ════════════════════════════════════════════════════════════
-- LOOP NPC CRAFT — independen
-- LOOP_COUNT = jumlah pengulangan semua recipe
-- ════════════════════════════════════════════════════════════
local NPC_RUNNING = false
task.spawn(function()
    while true do
        task.wait(0.5)
        if not AUTO_NPC or NPC_RUNNING then task.wait(1); continue end

        NPC_RUNNING = true
        NPC_DONE = 0
        local target = RECIPE_COUNT * LOOP_COUNT
        print("🧪 NPC START —", LOOP_COUNT, "pass ×", RECIPE_COUNT, "=", target, "pills")

        for pass = 1, LOOP_COUNT do
            if not AUTO_NPC then break end
            print("🧪 Pass", pass, "/", LOOP_COUNT)
            runNPCCraftPass()
        end

        AUTO_NPC    = false
        NPC_RUNNING = false
        Rayfield:Notify({
            Title    = "✅ Alchemist Done",
            Content  = NPC_DONE .. " / " .. target .. " pills",
            Duration = 8
        })
        print("🧪 NPC DONE:", NPC_DONE, "/", target)
    end
end)

-- ════════════════════════════════════════════════════════════
-- UI TOGGLES
-- ════════════════════════════════════════════════════════════
Tab:CreateToggle({
    Name = "🌿 Auto Forage",
    Callback = function(v)
        AUTO_FORAGE = v
    end
})

Tab:CreateToggle({
    Name = "🛠 Auto Handcraft",
    Callback = function(v)
        AUTO_HAND = v
        if not v then HAND_RUNNING = false end
    end
})

Tab:CreateToggle({
    Name = "🧪 Auto Alchemist",
    Callback = function(v)
        AUTO_NPC = v
        if not v then NPC_RUNNING = false end
    end
})
