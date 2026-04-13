--[[
    SR13 FINAL STABLE - Ordered Craft System
    Type: .lua
    Description: Optimized & Structured Script
]]

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ==========================================
-- SERVICES
-- ==========================================
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")

-- ==========================================
-- CONFIGURATION & STATE
-- ==========================================
local player            = Players.LocalPlayer
local character         = player.Character or player.CharacterAdded:Wait()
local root              = character:WaitForChild("HumanoidRootPart")
local remote            = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Clicked")

local AUTO_FORAGE       = false
local AUTO_HAND         = false
local AUTO_NPC          = false
local CRAFT_LOCK        = false
local LOOP_COUNT        = 1
local STATE             = "IDLE"
local lastCollectTime   = tick()
local forestCreated     = false

local HAND_DONE, NPC_DONE     = 0, 0
local HAND_TARGET, NPC_TARGET = 0, 0
local HAND_INDEX, NPC_INDEX   = 1, 1

-- ==========================================
-- DATA: COLLECTIBLES & RECIPES
-- ==========================================
local collectibles = { 
    "Azure Serpent Grass", "Basic Herb", "Bitter Jade Grass", "Black Iron Root", 
    "Blue Wave Coral Herb", "Cloud Mist Herb", "Common Spirit Grass", 
    "Crimson Flame Mushroom", "Dandelion of Qi", "Healing Sunflower", 
    "Heavenly Spirit Vine", "Ironbone Grass", "Moonlight Jade Leaf", 
    "Mountain Green Herb", "Nine Suns Flame Grass", "Purple Lightning Orchid", 
    "Red Ginseng", "Seven Star Flower", "Silverleaf Herb", "Spirit Spring Herb", 
    "Starlight Dew Herb", "Thousand Year Lotus", "Wild Bitter Grass", 
    "Wild Spirit Grass", "Chest" 
}

local collectSet = {}
for _, v in ipairs(collectibles) do collectSet[v] = true end

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

    -- Special Pills
    {"Lotus Nirvana Pill", {["Thousand Year Lotus"]=6}},
    {"Heavenly Spirit Pill", {["Heavenly Spirit Vine"]=2,["Starlight Dew Herb"]=3,["Moonlight Jade Leaf"]=1}},
}

local RECIPE_COUNT = #recipes

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================
local function refreshCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    root = character:WaitForChild("HumanoidRootPart")
    print("✅ Character Refreshed")
end

local function printMode()
    print(string.format("Status: Forage=%s | Handcraft=%s | Alchemist=%s", tostring(AUTO_FORAGE), tostring(AUTO_HAND), tostring(AUTO_NPC)))
end

local function lock(mode) CRAFT_LOCK = true print("🔒 LOCKED:", mode) end
local function unlock() CRAFT_LOCK = false print("🔓 UNLOCKED") end

-- DETECTORS
local resultLabel
task.spawn(function()
    local ok, gui = pcall(function()
        return player.PlayerGui:WaitForChild("ScreenGui", 10):WaitForChild("Alchemy", 10):WaitForChild("SelectionFrame", 10):WaitForChild("Success", 10)
    end)
    if ok then resultLabel = gui else warn("ResultLabel Not Found") end
end)

local function getResultText()
    local ok, text = pcall(function() return resultLabel.Text end)
    return ok and text or ""
end

local function getTimerValue()
    local timerLabel = player.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Alchemy"):WaitForChild("WaitFrame"):WaitForChild("Time")
    local ok, result = pcall(function() return tonumber(string.match(timerLabel.Text or "", "%-?[%d%.]+")) end)
    return (ok and result and result > 0) and result or 0
end

local function isTimerRunning() return getTimerValue() > 0 end

local function getHerbCount(name)
    local mainFrame = player.PlayerGui.ScreenGui.Alchemy.SelectionFrame.lister.MainFrame
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

local function canCraft(recipeName, ingredients)
    local missing = {}
    for herb, qty in pairs(ingredients) do
        local have = getHerbCount(herb)
        if have < qty then table.insert(missing, string.format("%s (%d/%d)", herb, have, qty)) end
    end
    if #missing > 0 then
        print("❌ Missing:", recipeName, "->", table.concat(missing, ", "))
        return false
    end
    return true
end

-- ==========================================
-- FORAGE LOGIC
-- ==========================================
local function forestHasItems()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Azure Serpent Grass" or obj.Name == "Cloud Mist Herb" or obj.Name == "Chest" then return true end
    end
    return false
end

local function getTargetPart(item)
    return item:IsA("BasePart") and item or item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
end

local function collectItem(item)
    local targetPart = getTargetPart(item)
    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not (targetPart and prompt) then return end
    
    local old = root.CFrame
    local offsets = { Vector3.new(0,3,0), Vector3.new(2,2,0), Vector3.new(-2,2,0) }
    
    for _, offset in ipairs(offsets) do
        root.CFrame = targetPart.CFrame + offset
        task.wait(0.03)
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        for i = 1, 4 do prompt:InputHoldBegin() task.wait() prompt:InputHoldEnd() end
        if not item.Parent then lastCollectTime = tick() break end
    end
    root.CFrame = old
end

-- ==========================================
-- MAIN LOOPS (CO-ROUTINES)
-- ==========================================

-- 1. Anti-AFK
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- 2. Handcraft Loop
task.spawn(function()
    while true do
        if AUTO_HAND then
            if HAND_TARGET == 0 then HAND_TARGET = RECIPE_COUNT * LOOP_COUNT end
            if HAND_DONE >= HAND_TARGET then 
                AUTO_HAND = false 
                HAND_INDEX = 1
                Rayfield:Notify({Title="Handcraft Done", Content="Total: "..HAND_DONE, Duration=6})
            elseif not CRAFT_LOCK then
                for i = HAND_INDEX, RECIPE_COUNT do
                    if not AUTO_HAND then HAND_INDEX = i break end
                    local recipe = recipes[i]
                    while not canCraft(recipe[1], recipe[2]) do
                        if not AUTO_HAND then break end
                        task.wait(10)
                    end
                    if not AUTO_HAND then HAND_INDEX = i break end
                    
                    local existing = getTimerValue()
                    if existing > 0 then task.wait(existing + 0.5) end
                    
                    lock("HAND")
                    remote:FireServer("AlchemyController", false, "craft", recipe[2])
                    task.wait(0.2)
                    remote:FireServer("AlchemyController", false, "mixing", 1)
                    repeat task.wait(1) until not isTimerRunning() or not AUTO_HAND
                    remote:FireServer("AlchemyController", false, "finishPill")
                    HAND_DONE += 1
                    unlock()
                    if i == RECIPE_COUNT then HAND_INDEX = 1 end
                    task.wait(2)
                end
            end
        end
        task.wait(1)
    end
end)

-- 3. NPC Loop
local function waitForResult(textBefore, timeoutSec)
    local deadline = tick() + timeoutSec
    local lastSeen, stableCount = textBefore, 0
    while tick() < deadline do
        if not AUTO_NPC then return "CANCELLED" end
        task.wait(0.15)
        local current = getResultText()
        if current ~= "" then
            if current ~= lastSeen then lastSeen = current stableCount = 1 else stableCount += 1 end
            if stableCount >= 2 and current ~= textBefore then
                local lower = string.lower(current)
                if string.find(lower, "recipe") then return "NO_RECIPE"
                elseif string.find(lower, "spirit") then return "NO_STONE"
                else return "SUCCESS" end
            end
        end
    end
    return "SUCCESS"
end

task.spawn(function()
    while true do
        if AUTO_NPC then
            if NPC_TARGET == 0 then NPC_TARGET = RECIPE_COUNT * LOOP_COUNT end
            if NPC_DONE >= NPC_TARGET then
                AUTO_NPC = false NPC_INDEX = 1
                Rayfield:Notify({Title="NPC Done", Content="Total: "..NPC_DONE, Duration=6})
            elseif not CRAFT_LOCK then
                for i = NPC_INDEX, RECIPE_COUNT do
                    if not AUTO_NPC then NPC_INDEX = i break end
                    local recipe = recipes[i]
                    while not canCraft(recipe[1], recipe[2]) do
                        if not AUTO_NPC then break end
                        task.wait(10)
                    end
                    if not AUTO_NPC then NPC_INDEX = i break end
                    
                    lock("NPC")
                    local textBefore = getResultText()
                    remote:FireServer("AlchemyController", false, "alchemist", recipe[2])
                    local result = waitForResult(textBefore, 10)
                    if result == "SUCCESS" then NPC_DONE += 1 end
                    unlock()
                    if i == RECIPE_COUNT then NPC_INDEX = 1 end
                    task.wait(1)
                end
            end
        end
        task.wait(1)
    end
end)

-- ==========================================
-- UI WINDOW & TABS
-- ==========================================
local Window = Rayfield:CreateWindow({
    Name = "SR13 FINAL STABLE",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Ordered Craft System",
    ConfigurationSaving = { Enabled = false }
})

local Tab = Window:CreateTab("Main", 4483362458)

Tab:CreateInput({
    Name = "🔁 Loop Count",
    PlaceholderText = "1",
    Callback = function(txt)
        local num = tonumber(txt)
        LOOP_COUNT = (num and num > 0) and math.floor(num) or 1
        print("🔁 Loop set:", LOOP_COUNT)
    end
})

Tab:CreateToggle({
    Name = "🌿 Auto Forage",
    Callback = function(v)
        AUTO_FORAGE = v
        if v then AUTO_HAND = false AUTO_NPC = false end
    end
})

Tab:CreateToggle({
    Name = "🛠 Auto Handcraft",
    Callback = function(v)
        AUTO_HAND = v
        if v then AUTO_FORAGE = false HAND_DONE = 0 HAND_INDEX = 1 end
    end
})

Tab:CreateToggle({
    Name = "🧪 Auto Alchemist",
    Callback = function(v)
        AUTO_NPC = v
        if v then AUTO_FORAGE = false NPC_DONE = 0 NPC_INDEX = 1 end
    end
})

-- Handle Respawn
player.CharacterAdded:Connect(function()
    task.wait(1)
    refreshCharacter()
    if AUTO_FORAGE then forestCreated = false end
end)
