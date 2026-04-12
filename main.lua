-- LOAD
local Rayfield=loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window=Rayfield:CreateWindow({Name="SR13 FINAL STABLE",LoadingTitle="Loading...",LoadingSubtitle="Ordered Craft System",ConfigurationSaving={Enabled=false}})
local Tab=Window:CreateTab("Main",4483362458)

-- SERVICES
local Players,Workspace,ReplicatedStorage,VirtualUser=
game:GetService("Players"),
game:GetService("Workspace"),
game:GetService("ReplicatedStorage"),
game:GetService("VirtualUser")

local player=Players.LocalPlayer
local character=player.Character or player.CharacterAdded:Wait()
local root=character:WaitForChild("HumanoidRootPart")

-- STATES
local AUTO_FORAGE=false
local STATE="IDLE"
local lastCollectTime=tick()
local forestCreated=false

local AUTO_HAND=false
local AUTO_NPC=false

local HAND_DONE,NPC_DONE=0,0
local HAND_TARGET,NPC_TARGET=0,0
local HAND_INDEX,NPC_INDEX=1,1

local LOOP_COUNT=1
local CRAFT_LOCK=false

local function refreshCharacter()
character=player.Character or player.CharacterAdded:Wait()
root=character:WaitForChild("HumanoidRootPart")
end

player.CharacterAdded:Connect(function()
task.wait(1)
refreshCharacter()
if AUTO_FORAGE then
forestCreated=false
STATE="COOLDOWN"
lastCollectTime=tick()
end
end)

local remote=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Clicked")

-- ANTI AFK
player.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)

-- LOOP INPUT
Tab:CreateInput({
Name="🔁 Loop Count",
PlaceholderText="1",
Callback=function(txt)
local n=tonumber(txt)
LOOP_COUNT=(n and n>0) and math.floor(n) or 1
end})

-- LOCK
local function lock()CRAFT_LOCK=true end
local function unlock()CRAFT_LOCK=false end

-- RESULT UI
local resultLabel=
player.PlayerGui:WaitForChild("ScreenGui")
:WaitForChild("Alchemy")
:WaitForChild("SelectionFrame")
:WaitForChild("Success")

local timerLabel=
player.PlayerGui:WaitForChild("ScreenGui")
:WaitForChild("Alchemy")
:WaitForChild("WaitFrame")
:WaitForChild("Time")

local function getResultText()
local ok,t=pcall(function()return resultLabel.Text end)
return ok and t or ""
end

local function waitForResult(before,timeout)

local deadline=tick()+timeout
local lastSeen=before

while tick()<deadline do

if not AUTO_NPC then
return"CANCELLED"
end

task.wait(.2)

local ok,current=pcall(function()
return resultLabel.Text
end)

if ok and current~="" then
if current~=lastSeen then
local l=string.lower(current)
if string.find(l,"recipe") then
return"NO_RECIPE"
elseif string.find(l,"spirit") then
return"NO_STONE"
else
return"SUCCESS"
end
end
lastSeen=current
end
end
-- fallback SAFE VERSION
local ok,timer=pcall(function()
return getTimerValue()
end)
if ok and timer>0 then
return"SUCCESS"
end
return"TIMEOUT"
end
-- fallback: cek apakah timer jalan
if isTimerRunning() then
return"SUCCESS"
end
return"TIMEOUT"
end

local function getTimerValue()
local ok,r=pcall(function()
return tonumber(string.match(timerLabel.Text or "","%-?[%d%.]+"))
end)
return(ok and r and r>0)and r or 0
end

local function isTimerRunning()
return getTimerValue()>0
end

-- INGREDIENT CHECK
local function getHerbCount(name)
local frame=player.PlayerGui.ScreenGui.Alchemy.SelectionFrame.lister.MainFrame
for _,c in ipairs(frame:GetChildren())do
if c.Name:lower()==name:lower()then
for _,d in ipairs(c:GetDescendants())do
if d:IsA("TextLabel")then
local n=string.match(d.Text,"%d+")
if n then return tonumber(n)end
end end end end
return 0
end

local function canCraft(recipeName,ingredients)
local miss={}
for herb,qty in pairs(ingredients)do
local have=getHerbCount(herb)
if have<qty then
table.insert(miss,herb.." ("..have.."/"..qty..")")
end end
if #miss>0 then return false end
return true
end

-- RECIPES (PASTE YOUR RECIPES HERE)
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

-- COLLECT SYSTEM
local collectibles={
"Azure Serpent Grass","Basic Herb","Bitter Jade Grass","Black Iron Root",
"Blue Wave Coral Herb","Cloud Mist Herb","Common Spirit Grass",
"Crimson Flame Mushroom","Dandelion of Qi","Healing Sunflower",
"Heavenly Spirit Vine","Ironbone Grass","Moonlight Jade Leaf",
"Mountain Green Herb","Nine Suns Flame Grass","Purple Lightning Orchid",
"Red Ginseng","Seven Star Flower","Silverleaf Herb","Spirit Spring Herb",
"Starlight Dew Herb","Thousand Year Lotus","Wild Bitter Grass",
"Wild Spirit Grass","Chest"}

local collectSet={}
for _,v in ipairs(collectibles)do collectSet[v]=true end

local function getTargetPart(i)
return i:IsA("BasePart")and i or i.PrimaryPart or i:FindFirstChildWhichIsA("BasePart")
end

local function getDistance(o)
local p=getTargetPart(o)
return p and(root.Position-p.Position).Magnitude or math.huge
end

local function getItems()
local t={}
for _,o in ipairs(Workspace:GetDescendants())do
if collectSet[o.Name]and getTargetPart(o)then
table.insert(t,o)
end end
table.sort(t,function(a,b)return getDistance(a)<getDistance(b)end)
return t
end

local function collectItem(item)
local p=getTargetPart(item)
local pr=item:FindFirstChildWhichIsA("ProximityPrompt",true)
if not(p and pr)then return end
if not root or not root.Parent then refreshCharacter()return end
local old=root.CFrame

local offs={
Vector3.new(0,3,0),
Vector3.new(2,2,0),
Vector3.new(-2,2,0),
Vector3.new(0,2,2),
Vector3.new(0,2,-2)}

for _,o in ipairs(offs)do
root.CFrame=p.CFrame+o
task.wait(.03)
pr.RequiresLineOfSight=false
pr.HoldDuration=0
for i=1,4 do
pr:InputHoldBegin()
task.wait()
pr:InputHoldEnd()
end
if not item.Parent then
lastCollectTime=tick()
break
end end

root.CFrame=old
end

local function enterForest()
if not forestCreated then
remote:FireServer("Forest",false,"Create")
forestCreated=true
task.wait(3)
end end

local function destroyForest()
remote:FireServer("Forest",false,"Destroy")
forestCreated=false
end

local cooldownStart=0

-- AUTO FORAGE LOOP
task.spawn(function()
while true do
if AUTO_FORAGE then

if STATE=="IDLE"then
STATE="COOLDOWN"
cooldownStart=tick()

elseif STATE=="COOLDOWN"then

local waitTime=math.random(18,28)

if not forestCreated then
enterForest()
cooldownStart=tick()
end

local items=getItems()

if #items>0 then
lastCollectTime=tick()
STATE="FARM"

elseif tick()-cooldownStart>waitTime then
print("⚠️ Cooldown passed but no items — recreating forest")
destroyForest()
task.wait(2)
forestCreated=false

else
task.wait(2)
end

elseif STATE=="FARM"then
local items=getItems()

if #items>0 then
collectItem(items[1])
lastCollectTime=tick()
else
if tick()-lastCollectTime>3 then
destroyForest()
STATE="COOLDOWN"
cooldownStart=tick()
end end end

else
STATE="IDLE"
forestCreated=false
task.wait(1)
end

task.wait(.1)
end
end)

-- AUTO HAND
task.spawn(function()
while true do
if AUTO_HAND then

if HAND_TARGET==0 then
HAND_TARGET=RECIPE_COUNT*LOOP_COUNT
end

if HAND_DONE>=HAND_TARGET then
AUTO_HAND=false
HAND_INDEX=1
continue
end

if CRAFT_LOCK then task.wait(1)continue end

for i=HAND_INDEX,RECIPE_COUNT do
if not AUTO_HAND then
HAND_INDEX=i
break
end

local r=recipes[i]
local name,ing=r[1],r[2]

while not canCraft(name,ing)do
if not AUTO_HAND then break end
task.wait(10)
end

local ex=getTimerValue()
if ex>0 then task.wait(ex+.5)end

lock()

remote:FireServer("AlchemyController",false,"craft",ing)
task.wait(.2)

remote:FireServer("AlchemyController",false,"mixing",1)

repeat task.wait(1)
until not isTimerRunning()or not AUTO_HAND

remote:FireServer("AlchemyController",false,"finishPill")

HAND_DONE+=1

unlock()

if i==RECIPE_COUNT then
HAND_INDEX=1
end

task.wait(2)
end

else
task.wait(1)
end
end
end)

-- AUTO NPC
task.spawn(function()
while true do
if AUTO_NPC then

if NPC_TARGET==0 then
NPC_TARGET=RECIPE_COUNT*LOOP_COUNT
end

if NPC_DONE>=NPC_TARGET then
AUTO_NPC=false
NPC_INDEX=1
continue
end

if CRAFT_LOCK then task.wait(1)continue end

for i=NPC_INDEX,RECIPE_COUNT do

if not AUTO_NPC then
NPC_INDEX=i
break
end

local r=recipes[i]
local name,ing=r[1],r[2]

while not canCraft(name,ing)do
if not AUTO_NPC then break end
task.wait(10)
end

lock()

local before=getResultText()

remote:FireServer("AlchemyController",false,"alchemist",ing)

local res=waitForResult(before,5)

if res=="SUCCESS"or res=="TIMEOUT"then
NPC_DONE+=1
end

unlock()

if i==RECIPE_COUNT then
NPC_INDEX=1
end

task.wait(1)

end

else
task.wait(1)
end
end
end)

-- UI
Tab:CreateToggle({
Name="🌿 Auto Forage",
Callback=function(v)
AUTO_FORAGE=v
STATE="IDLE"
forestCreated=false
end})

Tab:CreateToggle({
Name="🧪 Auto Alchemist",
Callback=function(v)
AUTO_NPC=v
if v and NPC_TARGET==0 then
NPC_DONE=0
NPC_INDEX=1
end
end})

Tab:CreateToggle({
Name="🛠 Auto Handcraft",
Callback=function(v)
AUTO_HAND=v
if v and HAND_TARGET==0 then
HAND_DONE=0
HAND_INDEX=1
end
end})
