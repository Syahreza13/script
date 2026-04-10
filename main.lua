--// LOAD RAYFIELD
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "SR13 FIXED",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Smart Lock Stable",
    ConfigurationSaving = {Enabled = false}
})

local Tab = Window:CreateTab("Main", 4483362458)

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

local remote =
ReplicatedStorage
:WaitForChild("Remotes")
:WaitForChild("Clicked")

--------------------------------------------------
-- ANTI AFK
--------------------------------------------------

player.Idled:Connect(function()

VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())

end)

--------------------------------------------------
-- GLOBAL LOCK
--------------------------------------------------

local CRAFT_LOCK=false

local function lock(mode)

CRAFT_LOCK=true
print("🔒 LOCKED:",mode)

end

local function unlock()

CRAFT_LOCK=false
print("🔓 UNLOCKED")

end

--------------------------------------------------
-- RESULT DETECTOR
--------------------------------------------------

LAST_RESULT="UNKNOWN"

local resultLabel =
player.PlayerGui
:WaitForChild("ScreenGui")
:WaitForChild("Alchemy")
:WaitForChild("SelectionFrame")
:WaitForChild("Success")

resultLabel:GetPropertyChangedSignal("Text"):Connect(function()

local text=resultLabel.Text

if not text or text=="" then return end

local lower=string.lower(text)

print("📩 RESULT:",text)

if string.find(lower,"recipe") then

LAST_RESULT="NO_RECIPE"

elseif string.find(lower,"spirit") then

LAST_RESULT="NO_STONE"

else

LAST_RESULT="SUCCESS"

end

end)

--------------------------------------------------
-- TIMER DETECTOR
--------------------------------------------------

local timerLabel =
player.PlayerGui
:WaitForChild("ScreenGui")
:WaitForChild("Alchemy")
:WaitForChild("WaitFrame")
:WaitForChild("Time")

local function isTimerRunning()

local txt=timerLabel.Text

local num=tonumber(string.match(txt,"%-?[%d%.]+"))

if num and num>0 then
return true
end

return false

end

--------------------------------------------------
-- INGREDIENT DETECTOR
--------------------------------------------------

local function getHerbCount(name)

local mainFrame =
player.PlayerGui
.ScreenGui
.Alchemy
.SelectionFrame
.lister
.MainFrame

for _,child in ipairs(mainFrame:GetChildren()) do

if child.Name:lower()==name:lower() then

for _,d in ipairs(child:GetDescendants()) do

if d:IsA("TextLabel") then

local n=string.match(d.Text,"%d+")

if n then
return tonumber(n)
end

end

end

end

end

return 0

end

--------------------------------------------------
-- SAFE canCraft()
--------------------------------------------------

local function canCraft(recipeName, ingredientTable)

if not recipeName or not ingredientTable then
warn("❌ Invalid recipe format")
return false
end

local missing={}

for herb,qty in pairs(ingredientTable) do

local have=getHerbCount(herb)

if have<qty then

table.insert(
missing,
herb.." ("..have.."/"..qty..")"
)

end

end

if #missing>0 then

print("❌ Missing:",recipeName)
print(table.concat(missing,", "))

return false

end

return true

end

--------------------------------------------------
-- RECIPES (FORMAT DICTIONARY)
--------------------------------------------------

local recipes = {

["Mistveil Focus Pill A"] = {
["Spirit Spring Herb"]=2,
["Azure Serpent Grass"]=1,
["Silverleaf Herb"]=2,
["Thousand Year Lotus"]=1
},

["Mistveil Focus Pill B"] = {
["Spirit Spring Herb"]=1,
["Blue Wave Coral Herb"]=1,
["Cloud Mist Herb"]=3,
["Thousand Year Lotus"]=1
},

}

--------------------------------------------------
-- AUTO FORAGE (ASLI — TIDAK DIUBAH)
--------------------------------------------------

local AUTO_FORAGE=false
local STATE="IDLE"
local lastCollectTime=tick()

local collectibles={

"Azure Serpent Grass","Basic Herb","Bitter Jade Grass","Black Iron Root",
"Blue Wave Coral Herb","Cloud Mist Herb","Common Spirit Grass",
"Crimson Flame Mushroom","Dandelion of Qi","Healing Sunflower",
"Heavenly Spirit Vine","Ironbone Grass","Moonlight Jade Leaf",
"Mountain Green Herb","Nine Suns Flame Grass","Purple Lightning Orchid",
"Red Ginseng","Seven Star Flower","Silverleaf Herb","Spirit Spring Herb",
"Starlight Dew Herb","Thousand Year Lotus","Wild Bitter Grass",
"Wild Spirit Grass","Chest"

}

local collectSet={}

for _,v in ipairs(collectibles) do
collectSet[v]=true
end

local function getTargetPart(item)

return item:IsA("BasePart")
and item
or item.PrimaryPart
or item:FindFirstChildWhichIsA("BasePart")

end

local function getDistance(obj)

local part=getTargetPart(obj)

return part
and (root.Position-part.Position).Magnitude
or math.huge

end

local function getItems()

local items={}

for _,obj in ipairs(Workspace:GetDescendants()) do

if collectSet[obj.Name]
and getTargetPart(obj)
then

table.insert(items,obj)

end

end

table.sort(items,function(a,b)

return getDistance(a)<getDistance(b)

end)

return items

end

local function collectItem(item)

local targetPart=getTargetPart(item)

local prompt=item:FindFirstChildWhichIsA(
"ProximityPrompt",
true
)

if not(targetPart and prompt) then return end

local old=root.CFrame

local offsets={

Vector3.new(0,3,0),
Vector3.new(2,2,0),
Vector3.new(-2,2,0),
Vector3.new(0,2,2),
Vector3.new(0,2,-2),

}

for _,offset in ipairs(offsets) do

root.CFrame=targetPart.CFrame+offset

task.wait(0.03)

prompt.RequiresLineOfSight=false
prompt.HoldDuration=0

for i=1,4 do

prompt:InputHoldBegin()
task.wait()
prompt:InputHoldEnd()

end

if not item.Parent then

lastCollectTime=tick()
break

end

end

root.CFrame=old

end

local function tryEnterForest()

remote:FireServer(
"Forest",
false,
"Create"
)

task.wait(1)

return #getItems()>0

end

task.spawn(function()

while true do

if AUTO_FORAGE then

if STATE=="FARM" then

local items=getItems()

if #items>0 then
collectItem(items[1])
end

if tick()-lastCollectTime>10 then

remote:FireServer(
"Forest",
false,
"Destroy"
)

STATE="COOLDOWN"
task.wait(2)

end

end

if STATE=="COOLDOWN" then

if tryEnterForest() then
STATE="FARM"
lastCollectTime=tick()
else
task.wait(2)
end

end

if STATE=="IDLE" then
STATE="COOLDOWN"
end

else
task.wait(1)
end

task.wait(0.1)

end

end)

--------------------------------------------------
-- AUTO HANDCRAFT
--------------------------------------------------

local AUTO_HAND=false

task.spawn(function()

while true do

if AUTO_HAND then

if CRAFT_LOCK then
task.wait(1)
continue
end

for recipeName,ingredientTable in pairs(recipes) do

if not AUTO_HAND then break end

if not canCraft(recipeName,ingredientTable) then

print("⏳ Hand Missing → Retry 10s")
task.wait(10)
continue

end

if isTimerRunning() then

print("⏱ Existing timer detected")
task.wait(2)
continue

end

lock("HAND")

print("🛠 Handcraft:",recipeName)

remote:FireServer(
"AlchemyController",
false,
"craft",
ingredientTable
)

task.wait(1)

remote:FireServer(
"AlchemyController",
false,
"mixing",
1
)

print("⏱ Waiting timer...")

repeat
task.wait(1)
until not isTimerRunning()

print("🎉 Claim Pill")

remote:FireServer(
"AlchemyController",
false,
"finishPill"
)

unlock()

task.wait(2)

end

else
task.wait(1)
end

end

end)

--------------------------------------------------
-- AUTO ALCHEMIST
--------------------------------------------------

local AUTO_NPC=false

task.spawn(function()

while true do

if AUTO_NPC then

if CRAFT_LOCK then
task.wait(1)
continue
end

for recipeName,ingredientTable in pairs(recipes) do

if not AUTO_NPC then break end

if not canCraft(recipeName,ingredientTable) then

print("⏳ NPC Missing → Retry 10s")
task.wait(10)
continue

end

lock("NPC")

print("🧪 NPC Craft:",recipeName)

LAST_RESULT="UNKNOWN"

remote:FireServer(
"AlchemyController",
false,
"alchemist",
ingredientTable
)

task.wait(3)

unlock()

task.wait(2)

end

else
task.wait(1)
end

end

end)

--------------------------------------------------
-- UI
--------------------------------------------------

Tab:CreateToggle({

Name="🌿 Auto Forage",
CurrentValue=false,
Callback=function(v)

AUTO_FORAGE=v
STATE="IDLE"

end

})

Tab:CreateToggle({

Name="🧪 Auto Alchemist",
CurrentValue=false,
Callback=function(v)

AUTO_NPC=v

end

})

Tab:CreateToggle({

Name="🛠 Auto Handcraft",
CurrentValue=false,
Callback=function(v)

AUTO_HAND=v

end

})
