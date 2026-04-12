-- LOAD RAYFIELD
local Rayfield=loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window=Rayfield:CreateWindow({
Name="SR13 FINAL STABLE",
LoadingTitle="Loading...",
LoadingSubtitle="Ordered Craft System",
ConfigurationSaving={Enabled=false}
})
local Tab=Window:CreateTab("Main",4483362458)

-- SERVICES
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local VirtualUser=game:GetService("VirtualUser")

local player=Players.LocalPlayer
local character=player.Character or player.CharacterAdded:Wait()
local root=character:WaitForChild("HumanoidRootPart")

local function refreshCharacter()
character=player.Character or player.CharacterAdded:Wait()
root=character:WaitForChild("HumanoidRootPart")
print("Character Refreshed")
end

player.CharacterAdded:Connect(function()
task.wait(1)
refreshCharacter()
end)

local remote=
ReplicatedStorage
:WaitForChild("Remotes")
:WaitForChild("Clicked")

-- ANTI AFK
player.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)

-- LOOP INPUT
local LOOP_COUNT=1
Tab:CreateInput({
Name="🔁 Loop Count",
PlaceholderText="1",
Callback=function(txt)
local num=tonumber(txt)
LOOP_COUNT=(num and num>0) and math.floor(num) or 1
print("🔁 Loop set:",LOOP_COUNT)
end
})

-- GLOBAL LOCK
local CRAFT_LOCK=false
local function lock(mode)
CRAFT_LOCK=true
print("🔒 LOCKED:",mode)
end

local function unlock()
CRAFT_LOCK=false
print("🔓 UNLOCKED")
end

-- TIMER
local timerLabel=
player.PlayerGui
:WaitForChild("ScreenGui")
:WaitForChild("Alchemy")
:WaitForChild("WaitFrame")
:WaitForChild("Time")

local function getTimerValue()
local num=tonumber(string.match(timerLabel.Text or "","%-?[%d%.]+"))
return(num and num>0)and num or 0
end

local function isTimerRunning()
return getTimerValue()>0
end

-- INGREDIENT CHECK
local function getHerbCount(name)

local mainFrame=
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

local function canCraft(recipeName,ingredients)

for herb,qty in pairs(ingredients) do

local have=getHerbCount(herb)

if have<qty then
return false
end

end

return true

end

--------------------------------------------------
-- RECIPES (ARRAY)
--------------------------------------------------

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

local RECIPE_COUNT=#recipes

--------------------------------------------------
-- COUNTER
--------------------------------------------------

local HAND_DONE=0
local NPC_DONE=0

local HAND_TARGET=0
local NPC_TARGET=0

--------------------------------------------------
-- AUTO FORAGE (ORIGINAL STABLE)
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
for _,v in ipairs(collectibles)do
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
and(root.Position-part.Position).Magnitude
or math.huge

end

local function getItems()

local items={}

for _,obj in ipairs(Workspace:GetDescendants())do

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

if not root or not root.Parent then
refreshCharacter()
return
end

local targetPart=getTargetPart(item)

local prompt=item:FindFirstChildWhichIsA(
"ProximityPrompt",
true
)

if not(targetPart and prompt)then return end

local old=root.CFrame

local offsets={

Vector3.new(0,3,0),
Vector3.new(2,2,0),
Vector3.new(-2,2,0),
Vector3.new(0,2,2),
Vector3.new(0,2,-2),

}

for _,offset in ipairs(offsets)do

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

if HAND_TARGET==0 then
HAND_TARGET=
RECIPE_COUNT*LOOP_COUNT
end

if HAND_DONE>=HAND_TARGET then

AUTO_HAND=false

Rayfield:Notify({
Title="Handcraft Done",
Content="Total Crafted: "..HAND_DONE,
Duration=6
})

continue

end

if CRAFT_LOCK then
task.wait(1)
continue
end

for i=1,RECIPE_COUNT do

if not AUTO_HAND then break end

local recipe=recipes[i]

local recipeName=recipe[1]
local ingredientTable=recipe[2]

while not canCraft(
recipeName,
ingredientTable
)do
task.wait(10)
end

while isTimerRunning()do
task.wait(2)
end

lock("HAND")

remote:FireServer(
"AlchemyController",
false,
"craft",
ingredientTable
)

task.wait(0.3)

for i=1,6 do
remote:FireServer(
"AlchemyController",
false,
"mixing",
math.random()
)
task.wait(0.02)
end

repeat
task.wait(1)
until not isTimerRunning()

remote:FireServer(
"AlchemyController",
false,
"finishPill"
)

HAND_DONE+=1

unlock()

task.wait(2)

end

else
task.wait(1)
end

end

end)

--------------------------------------------------
-- AUTO NPC
--------------------------------------------------

local AUTO_NPC=false

task.spawn(function()

while true do

if AUTO_NPC then

if NPC_TARGET==0 then
NPC_TARGET=
RECIPE_COUNT*LOOP_COUNT
end

if NPC_DONE>=NPC_TARGET then

AUTO_NPC=false

Rayfield:Notify({
Title="NPC Done",
Content="Total Crafted: "..NPC_DONE,
Duration=6
})

continue

end

if CRAFT_LOCK then
task.wait(1)
continue
end

for i=1,RECIPE_COUNT do

if not AUTO_NPC then break end

local recipe=recipes[i]

local recipeName=recipe[1]
local ingredientTable=recipe[2]

while not canCraft(
recipeName,
ingredientTable
)do
task.wait(10)
end

lock("NPC")

remote:FireServer(
"AlchemyController",
false,
"alchemist",
ingredientTable
)

task.wait(3)

NPC_DONE+=1

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
Callback=function(v)
AUTO_FORAGE=v
STATE="IDLE"
end
})

Tab:CreateToggle({
Name="🧪 Auto Alchemist",
Callback=function(v)
AUTO_NPC=v
if v then
NPC_DONE=0
NPC_TARGET=0
end
end
})

Tab:CreateToggle({
Name="🛠 Auto Handcraft",
Callback=function(v)
AUTO_HAND=v
if v then
HAND_DONE=0
HAND_TARGET=0
end
end
})
