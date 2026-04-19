-- LOAD RAYFIELD
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "PLEASEEEEE",
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
local AUTO_USE    = false

-- CHARACTER REFRESH
local function refreshCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    root = character:WaitForChild("HumanoidRootPart")
    print("✅ Character Refreshed")
end
player.CharacterAdded:Connect(function()
    task.wait(1)
    refreshCharacter()
    print("💀 Respawn detected")
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

-- ════════════════════════════════════════════════════════════
-- RESULT DETECTOR (NPC)
-- ════════════════════════════════════════════════════════════
local function getResultLabel()
    local ok, lbl = pcall(function()
        return player.PlayerGui.ScreenGui
            .Alchemy.SelectionFrame.Success
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
                if string.find(lower, "recipe") then return "NO_RECIPE"
                elseif string.find(lower, "spirit") then return "NO_STONE"
                else return "SUCCESS" end
            end
        end
    end
    print("⚠ TIMEOUT → fallback SUCCESS")
    return "SUCCESS"
end

-- ════════════════════════════════════════════════════════════
-- TIMER DETECTOR (Hand)
-- ════════════════════════════════════════════════════════════
local function getTimerValue()
    local ok, result = pcall(function()
        local lbl = player.PlayerGui
            :FindFirstChild("ScreenGui")
            and player.PlayerGui.ScreenGui:FindFirstChild("Alchemy")
            and player.PlayerGui.ScreenGui.Alchemy:FindFirstChild("WaitFrame")
            and player.PlayerGui.ScreenGui.Alchemy.WaitFrame:FindFirstChild("Time")
        if not lbl then return 0 end
        return tonumber(string.match(lbl.Text or "", "%-?[%d%.]+")) or 0
    end)
    if ok and result and result > 0 then return result end
    return 0
end

local function isTimerRunning()
    return getTimerValue() > 0
end

-- ════════════════════════════════════════════════════════════
-- FOREST NAVIGATION
-- ════════════════════════════════════════════════════════════
local function leaveForest()
    print("🚪 Anchoring player before Destroy...")
    if root and root.Parent then
        root.Anchored = true
    end
    task.wait(0.2)
    print("🌲 Destroying Forest...")
    remote:FireServer("Forest", false, "Destroy")
    task.wait(3)
    if root and root.Parent then
        root.Anchored = false
    end
    print("✅ Forest destroyed, player released")
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
            table.insert(missing, herb .. " (" .. have .. "/" .. qty .. ")")
        end
    end
    if #missing > 0 then
        print("⏳ Waiting stock:", recipeName, "→", table.concat(missing, ", "))
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

local function forestHasItems()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Azure Serpent Grass"
        or obj.Name == "Cloud Mist Herb"
        or obj.Name == "Chest" then return true end
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

local function collectItem(item)
    local targetPart = getTargetPart(item)
    local prompt     = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not (targetPart and prompt) then return end
    if not root or not root.Parent then refreshCharacter(); return end
    local old     = root.CFrame
    local offsets = {
        Vector3.new(0,3,0),  Vector3.new(2,2,0),  Vector3.new(-2,2,0),
        Vector3.new(0,2,2),  Vector3.new(0,2,-2)
    }
    for _, offset in ipairs(offsets) do
        root.CFrame = targetPart.CFrame + offset
        task.wait(0.03)
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        for _ = 1, 4 do prompt:InputHoldBegin(); task.wait(); prompt:InputHoldEnd() end
        if not item.Parent then break end
    end
    root.CFrame = old
end

-- ════════════════════════════════════════════════════════════
-- AUTO USE PILL
-- Inventory : ScreenGui.MainFrame.Inventory.ItemList
--             .InsideFrame.MainFrame.[TypeId/Pill.InstanceId]
-- Active    : ScreenGui.SecondaryStats.ActivePills
--             .ScrollingFrame.[TypeId/Pill.InstanceId]
-- Remote    : Clicked:FireServer("Inventory",false,"Equip","TypeId/Pill.InstanceId")
-- ════════════════════════════════════════════════════════════
local function getActivePillIds()
    local active = {}
    pcall(function()
        local sf = player.PlayerGui.ScreenGui
            .SecondaryStats.ActivePills.ScrollingFrame
        for _, child in ipairs(sf:GetChildren()) do
            if child.Name:match("%d+/Pill%.%d+") then
                active[child.Name] = true
            end
        end
    end)
    return active
end

local function getInventoryPills()
    local pills = {}
    pcall(function()
        local mainFrame = player.PlayerGui.ScreenGui.MainFrame
            .Inventory.ItemList.InsideFrame.MainFrame
        for _, frame in ipairs(mainFrame:GetChildren()) do
            if frame.Name:match("%d+/Pill%.%d+") then
                local nameLabel   = frame:FindFirstChild("TextLabel", true)
                local amountLabel = frame:FindFirstChild("TextAmount")
                local amountText  = amountLabel and amountLabel.Text or "0"
                local amountNum   = tonumber(string.match(amountText, "%d+")) or 0
                if amountNum > 0 then
                    table.insert(pills, {
                        id   = frame.Name,
                        name = nameLabel and nameLabel.Text or "Unknown",
                    })
                end
            end
        end
    end)
    return pills
end

local function doAutoUsePills()
    local active = getActivePillIds()
    local pills  = getInventoryPills()
    local used   = 0
    for _, pill in ipairs(pills) do
        if not active[pill.id] then
            remote:FireServer("Inventory", false, "Equip", pill.id)
            print("💊 Equip:", pill.name, "(", pill.id, ")")
            used += 1
            task.wait(0.5)
        end
    end
    if used > 0 then
        print("💊 Auto Use: equipped", used, "pills")
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        if AUTO_USE then doAutoUsePills() end
    end
end)

-- ════════════════════════════════════════════════════════════
-- RECIPES
-- ════════════════════════════════════════════════════════════
local recipes =
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Syahreza13/script/refs/heads/main/Recipes"))()

local RECIPE_COUNT = #recipes
print("Loaded Recipes:", RECIPE_COUNT)

-- COUNTERS
local HAND_DONE, NPC_DONE     = 0, 0
local HAND_TARGET, NPC_TARGET = 0, 0

-- ════════════════════════════════════════════════════════════
-- CRAFT RUNNERS
-- ════════════════════════════════════════════════════════════
local function runHandCraftPass()
    if not AUTO_HAND then return end
    print("🛠 [Hand] Starting pass...")

    for i = 1, RECIPE_COUNT do
        if not AUTO_HAND then break end
        local recipeName      = recipes[i][1]
        local ingredientTable = recipes[i][2]

        while not canCraft(ingredientTable) do
            if not AUTO_HAND then break end
            missingLog(recipeName, ingredientTable)
            task.wait(5)
        end
        if not AUTO_HAND then break end

        local existing = getTimerValue()
        if existing > 0 then
            print("⏱ Previous timer:", existing, "s — waiting...")
            task.wait(existing + 0.5)
        end
        if not AUTO_HAND then break end

        print("🛠 Handcraft:", recipeName)
        remote:FireServer("AlchemyController", false, "craft", ingredientTable)
        task.wait(0.3)
        remote:FireServer("AlchemyController", false, "mixing", 1)
        task.wait(2)
        remote:FireServer("AlchemyController", false, "finishPill")
        HAND_DONE += 1
        print("📊 Hand:", HAND_DONE, "/", HAND_TARGET > 0 and tostring(HAND_TARGET) or "∞")
        task.wait(0.5)
    end
    print("🛠 [Hand] Pass done. Total:", HAND_DONE)
end

local function runNPCCraftPass()
    if not AUTO_NPC then return end
    print("🧪 [NPC] Starting pass...")

    local i = 1
    while i <= RECIPE_COUNT do
        if not AUTO_NPC then break end
        local recipeName      = recipes[i][1]
        local ingredientTable = recipes[i][2]

        while not canCraft(ingredientTable) do
            if not AUTO_NPC then break end
            missingLog(recipeName, ingredientTable)
            task.wait(5)
        end
        if not AUTO_NPC then break end

        print("🧪 NPC:", recipeName)
        local textBefore = getResultText()
        remote:FireServer("AlchemyController", false, "alchemist", ingredientTable)
        task.wait(1.5)
        local result = waitForResult(textBefore, 15)

        if not AUTO_NPC then break end

        if result == "SUCCESS" or result == "TIMEOUT" then
            NPC_DONE += 1
            print("✅ NPC OK:", recipeName, "| Total:", NPC_DONE, "/", NPC_TARGET > 0 and tostring(NPC_TARGET) or "∞")
            i += 1
        elseif result == "NO_RECIPE" then
            print("⏭ NO_RECIPE → Skip:", recipeName)
            i += 1
        elseif result == "NO_STONE" then
            print("⚠️ No Spirit Stone — retry in 10s:", recipeName)
            task.wait(10)
        elseif result == "CANCELLED" then
            print("🛑 NPC Cancelled")
            break
        end

        task.wait(2)
    end
    print("🧪 [NPC] Pass done. Total:", NPC_DONE)
end

-- ════════════════════════════════════════════════════════════
-- LOOP FORAGE
-- ════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.5)
        if not AUTO_FORAGE then task.wait(1); continue end

        print("🌿 Trying to enter forest...")
        remote:FireServer("Forest", false, "Create")
        task.wait(3)

        local waitItems = tick() + 8
        repeat task.wait(1) until forestHasItems() or tick() > waitItems

        if forestHasItems() then
            print("📦 Collecting...")
            while forestHasItems() and AUTO_FORAGE do
                local items = getItems()
                if #items == 0 then break end
                for _, item in ipairs(items) do
                    if not AUTO_FORAGE then break end
                    collectItem(item)
                    task.wait(0.1)
                end
                task.wait(0.3)
            end
            print("✅ Collect done — leaving forest")
            leaveForest()
            task.wait(5)
        else
            print("⏳ Forest not ready — retry in 5s")
            task.wait(5)
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- LOOP HAND CRAFT
-- ════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.5)
        if not AUTO_HAND then task.wait(1); continue end

        if HAND_TARGET == 0 then
            HAND_TARGET = RECIPE_COUNT * LOOP_COUNT
            print("🎯 Hand Target:", HAND_TARGET)
        end

        if HAND_DONE < HAND_TARGET then
            runHandCraftPass()
        else
            AUTO_HAND = false
            Rayfield:Notify({Title="Handcraft Done", Content="Total: "..HAND_DONE, Duration=6})
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- LOOP NPC CRAFT
-- ════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.5)
        if not AUTO_NPC then task.wait(1); continue end

        if NPC_TARGET == 0 then
            NPC_TARGET = RECIPE_COUNT * LOOP_COUNT
            print("🎯 NPC Target:", NPC_TARGET)
        end

        if NPC_DONE < NPC_TARGET then
            runNPCCraftPass()
        else
            AUTO_NPC = false
            Rayfield:Notify({Title="NPC Done", Content="Total: "..NPC_DONE, Duration=6})
        end
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
        if v then
            HAND_DONE   = 0
            HAND_TARGET = RECIPE_COUNT * LOOP_COUNT
            print("🎯 Hand Target:", HAND_TARGET)
        end
    end
})

Tab:CreateToggle({
    Name = "🧪 Auto Alchemist",
    Callback = function(v)
        AUTO_NPC = v
        if v then
            NPC_DONE   = 0
            NPC_TARGET = RECIPE_COUNT * LOOP_COUNT
            print("🎯 NPC Target:", NPC_TARGET)
        end
    end
})

Tab:CreateToggle({
    Name = "💊 Auto Use Pill",
    Callback = function(v)
        AUTO_USE = v
        if v then doAutoUsePills() end
    end
})
