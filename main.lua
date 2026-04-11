--// LOAD RAYFIELD
local Rayfield =
loadstring(
game:HttpGet('https://sirius.menu/rayfield')
)()

local Window = Rayfield:CreateWindow({

Name = "SR13 FINAL STABLE",
LoadingTitle = "Loading...",
LoadingSubtitle = "Smart Lock Stable",
ConfigurationSaving = {Enabled = false}

})

local Tab =
Window:CreateTab("Main",4483362458)

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local VirtualUser=game:GetService("VirtualUser")

local player=Players.LocalPlayer
local character=player.Character or player.CharacterAdded:Wait()
local root=character:WaitForChild("HumanoidRootPart")

local remote=
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

local resultLabel=

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
-- SMART TIMER DETECTOR
--------------------------------------------------

local timerLabel=

player.PlayerGui
:WaitForChild("ScreenGui")
:WaitForChild("Alchemy")
:WaitForChild("WaitFrame")
:WaitForChild("Time")

local lastTimerValue=0
local lastCheckTime=tick()

local function getTimerValue()

local txt=timerLabel.Text

if not txt then return 0 end

local num=

tonumber(
string.match(txt,"%-?[%d%.]+")
)

if num then
return num
end

return 0

end

local function isTimerRunning()

local current=getTimerValue()

if current<=0 then
lastTimerValue=current
return false
end

if current==lastTimerValue then

if tick()-lastCheckTime>3 then
return false
end

else

lastTimerValue=current
lastCheckTime=tick()
return true

end

return false

end

--------------------------------------------------
-- INGREDIENT DETECTOR
--------------------------------------------------

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

local n=
string.match(d.Text,"%d+")

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
-- SAFE canCraft
--------------------------------------------------

local function canCraft(recipeName,ingredientTable)

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
-- RECIPE LIST (URUT)
--------------------------------------------------

local recipeList={

{
"Mistveil Focus Pill A",
{["Spirit Spring Herb"]=2,
["Azure Serpent Grass"]=1,
["Silverleaf Herb"]=2,
["Thousand Year Lotus"]=1}
},

{
"Mistveil Focus Pill B",
{["Spirit Spring Herb"]=1,
["Blue Wave Coral Herb"]=1,
["Cloud Mist Herb"]=3,
["Thousand Year Lotus"]=1}
},

{
"Mistveil Focus Pill C",
{["Spirit Spring Herb"]=2,
["Silverleaf Herb"]=3,
["Starlight Dew Herb"]=1}
},

{
"Mistveil Focus Pill D",
{["Blue Wave Coral Herb"]=1,
["Spirit Spring Herb"]=2,
["Azure Serpent Grass"]=1,
["Silverleaf Herb"]=2}
},

{
"Mistveil Focus Pill E",
{["Blue Wave Coral Herb"]=1,
["Cloud Mist Herb"]=1,
["Spirit Spring Herb"]=1,
["Azure Serpent Grass"]=1,
["Silverleaf Herb"]=1,
["Seven Star Flower"]=1}
},

{
"Heavenly Spirit Pill",
{["Heavenly Spirit Vine"]=2,
["Starlight Dew Herb"]=3,
["Moonlight Jade Leaf"]=1}
}

}

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

for i,recipe in ipairs(recipeList) do

local recipeName=recipe[1]
local ingredientTable=recipe[2]

if not AUTO_HAND then break end

if isTimerRunning() then

local t=math.floor(getTimerValue())

print("⏱ Existing Pill Timer:",t,"S")

task.wait(2)
continue

end

if not canCraft(recipeName,ingredientTable) then

print("⏳ Hand Missing → Retry 10s")

task.wait(10)

continue

end

lock("HAND")

print("🛠 Handcraft →",recipeName)

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
-- AUTO NPC
--------------------------------------------------

local AUTO_NPC=false

task.spawn(function()

while true do

if AUTO_NPC then

if CRAFT_LOCK then
task.wait(1)
continue
end

for i,recipe in ipairs(recipeList) do

local recipeName=recipe[1]
local ingredientTable=recipe[2]

if not AUTO_NPC then break end

if not canCraft(recipeName,ingredientTable) then

print("⏳ NPC Missing → Retry 10s")

task.wait(10)

continue

end

lock("NPC")

print("🧪 NPC Craft →",recipeName)

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