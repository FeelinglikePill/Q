-- WindUI
local WindUI = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
Title = "Quality x",
Icon = "Star",
Author = "Qualitu-Team"
})

Window:EditOpenButton({
Title = "Open Quality",
Icon = "monitor",
CornerRadius = UDim.new(0, 16),
StrokeThickness = 2,
Color = ColorSequence.new(
Color3.fromRGB(255,15,123),
Color3.fromRGB(248,155,41)
),
OnlyMobile = false,
Enabled = true,
Draggable = true
})

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not LocalPlayer.Character then
LocalPlayer.CharacterAdded:Wait()
end

-- Tabs
local CombatTab = Window:Tab({Title = "Combat", Icon = "crosshair"})
local PlayerTab = Window:Tab({Title = "Player", Icon = "user"})
local TeleportTab = Window:Tab({Title = "Teleport", Icon = "map-pin"})
local ESPTab = Window:Tab({Title = "ESP", Icon = "eye"})


---

-- FOV

local FOVRadius = 150
local FOVEnabled = false
local sides = 32
local FOVLines = {}

for i = 1, sides do
local line = Drawing.new("Line")
line.Color = Color3.new(1,1,1)
line.Thickness = 2
line.Visible = false
FOVLines[i] = line
end

local AimLine = Drawing.new("Line")
AimLine.Color = Color3.new(1,0,0)
AimLine.Thickness = 2
AimLine.Visible = false

CombatTab:Toggle({
Title = "Show FOV",
Default = false,
Callback = function(state)
FOVEnabled = state
for _, l in pairs(FOVLines) do
l.Visible = state
end
AimLine.Visible = state
end
})

CombatTab:Slider({
Title = "FOV Size",
Step = 1,
Value = {Min = 50, Max = 1000, Default = FOVRadius},
Callback = function(v)
FOVRadius = v
end
})


---

-- Target

local function GetTarget()
local closest, bestDist = nil, math.huge
local center = Camera.ViewportSize / 2

for _, plr in ipairs(Players:GetPlayers()) do  
    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then  
        local head = plr.Character.Head  
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)  
        if onScreen then  
            local dist = (Vector2.new(pos.X,pos.Y) - center).Magnitude  
            if dist <= FOVRadius and dist < bestDist then  
                bestDist = dist  
                closest = head  
            end  
        end  
    end  
end  
return closest

end


---

-- ❗ SilentAim (ของเดิม ไม่แก้)

getgenv().SilentAimbot = true

local castRay
for _, fn in ipairs(getgc(true)) do
if typeof(fn) == "function" then
for _, uv in ipairs(debug.getupvalues(fn)) do
if typeof(uv) == "function"
and debug.getinfo(uv).name == "castRay" then
castRay = uv
break
end
end
end
if castRay then break end
end

if castRay then
local old
old = hookfunction(castRay, function(a, b, ...)
if getgenv().SilentAimbot then
local target = GetTarget()
if target then
return target, target.Position
end
end
return old(a, b, ...)
end)
end


---

-- Render (เส้นแดงจากกลาง FOV)

RunService.RenderStepped:Connect(function()
if not FOVEnabled then
AimLine.Visible = false
return
end

local center = Camera.ViewportSize / 2  
local points = {}  

-- วาดวง FOV  
for i = 0, sides - 1 do  
    local ang = math.rad(i * (360 / sides))  
    points[i+1] = Vector2.new(  
        center.X + FOVRadius * math.cos(ang),  
        center.Y + FOVRadius * math.sin(ang)  
    )  
end  

for i = 1, sides do  
    local n = (i % sides) + 1  
    FOVLines[i].From = points[i]  
    FOVLines[i].To = points[n]  
end  

-- เส้นแดงจากกลางจอ → เป้า  
local target = GetTarget()  
if target then  
    local tPos = Camera:WorldToViewportPoint(target.Position)  
    AimLine.From = Vector2.new(center.X, center.Y)  
    AimLine.To = Vector2.new(tPos.X, tPos.Y)  
    AimLine.Visible = true  
else  
    AimLine.Visible = false  
end

end)


---

-- Player

PlayerTab:Slider({
Title = "WalkSpeed",
Step = 1,
Value = {Min = 16, Max = 200, Default = 16},
Callback = function(v)
local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
if hum then hum.WalkSpeed = v end
end
})

PlayerTab:Slider({
Title = "JumpPower",
Step = 1,
Value = {Min = 50, Max = 300, Default = 50},
Callback = function(v)
local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
if hum then hum.JumpPower = v end
end
})


---

-- ESP

local ESPLabels = {}
local ESPEnabled = false

local function CreateESP(plr)
if ESPLabels[plr] then return end

local bb = Instance.new("BillboardGui")  
bb.Size = UDim2.new(0,100,0,20)  
bb.AlwaysOnTop = true  
bb.Enabled = ESPEnabled  

local txt = Instance.new("TextLabel")  
txt.Size = UDim2.fromScale(1,1)  
txt.BackgroundTransparency = 1  
txt.Text = plr.Name  
txt.Font = Enum.Font.SourceSansBold  
txt.TextSize = 14  
txt.Parent = bb  

bb.Parent = game:GetService("CoreGui")  
ESPLabels[plr] = bb

end

ESPTab:Toggle({
Title = "ESP Name",
Default = false,
Callback = function(state)
ESPEnabled = state
for _, bb in pairs(ESPLabels) do
bb.Enabled = state
end
end
})

RunService.RenderStepped:Connect(function()
for plr, bb in pairs(ESPLabels) do
if plr.Character and plr.Character:FindFirstChild("Head") then
bb.Adornee = plr.Character.Head
bb.Enabled = ESPEnabled
end
end
end)

for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then
if plr.Character then CreateESP(plr) end
plr.CharacterAdded:Connect(function()
CreateESP(plr)
end)
end
end

Players.PlayerAdded:Connect(function(plr)
plr.CharacterAdded:Connect(function()
CreateESP(plr)
end)
end)


---

-- WalkThrough / NoClip

local NoClip = false

PlayerTab:Toggle({
Title = "WalkThrough (NoClip)",
Default = false,
Callback = function(state)
NoClip = state
end
})

RunService.Stepped:Connect(function()
if NoClip and LocalPlayer.Character then
for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
end
end)

------------------------------------------------
-- Teleport
------------------------------------------------
TeleportTab:Button({
    Title = "TP to Tower",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if hrp then
            hrp.CFrame = CFrame.new(
                822.47509765625, 139.43064880371094, 2588.803466796875
            )
        end
    end
})

------------------------------------------------
-- Teleport
------------------------------------------------
TeleportTab:Button({
    Title = "tp to the thief's",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if hrp then
            hrp.CFrame = CFrame.new(
                -977.0906982421875,
                109.65302276611328,
                2056.8154296875
            )
        end
    end
})

------------------------------------------------
-- TP ไปจุดนี้ แล้วกลับที่เดิม
------------------------------------------------
TeleportTab:Button({
    Title = "TP to mp5",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- เก็บตำแหน่งเดิม
        local oldCFrame = hrp.CFrame

        -- TP ไปจุดเป้า
        hrp.CFrame = CFrame.new(
            813.44921875,
            99.18183135986328,
            2229.074462890625
        )

        -- หน่วงเวลา (วินาที) แล้ววาปกลับ
        task.wait(1) -- ปรับเวลาได้ เช่น 0.5 / 2 / 3

        -- วาปกลับตำแหน่งเดิม
        hrp.CFrame = oldCFrame
    end
})

------------------------------------------------
-- TP ไปจุดนี้ แล้วกลับที่เดิม (821)
------------------------------------------------
TeleportTab:Button({
    Title = "TP to remington",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- เก็บตำแหน่งเดิม
        local oldCFrame = hrp.CFrame

        -- TP ไปจุดเป้า
        hrp.CFrame = CFrame.new(
            821.404541015625,
            98.10057830810547,
            2228.724853515625
        )

        -- เวลาที่อยู่จุดนั้น (วินาที)
        task.wait(1)

        -- วาปกลับ
        hrp.CFrame = oldCFrame
    end
})
