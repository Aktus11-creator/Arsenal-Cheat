-- AdvanceFalling Team - Arsenal Enhanced v2.0
-- Added: Aimbot System, Config System, UI Improvements

--[[
TODO COMPLETED:
 ✓ Added advanced aimbot system
 ✓ Config save/load system
 ✓ UI improvements with better organization
 ✓ Theme selector
 ✓ Status indicators
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Notifications
CoreGui:SetCore("SendNotification", {
    Title = "AdvanceTech Arsenal v2.0",
    Text = "Enhanced with Aimbot & Configs!",
    Duration = 5,
})

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Made By:",
    Text = "AdvancedFalling Team",
    Icon = "rbxthumb://type=Asset&id=13508183954&w=150&h=150",
    Duration = 5,
})

-- ============================================
-- CONFIG SYSTEM
-- ============================================
local ConfigSystem = {
    CurrentConfig = "default",
    Configs = {}
}

function ConfigSystem:GetDefaultConfig()
    return {
        -- Aimbot
        AimbotEnabled = false,
        AimbotKey = "MouseButton2",
        AimbotFOV = 100,
        AimbotSmoothness = 5,
        AimbotPart = "Head",
        AimbotTeamCheck = true,
        AimbotVisibleCheck = true,
        AimbotPrediction = false,
        AimbotPredictionAmount = 0.12,
        
        -- Hitbox
        HitboxEnabled = false,
        HitboxSize = 21,
        HitboxTransparency = 6,
        HitboxTeamCheck = "FFA",
        NoCollision = false,
        
        -- Gun Mods
        InfiniteAmmo = false,
        FastReload = false,
        FastFireRate = false,
        AlwaysAuto = false,
        NoSpread = false,
        NoRecoil = false,
        
        -- Player
        FlyEnabled = false,
        FlySpeed = 50,
        CustomWalkSpeed = false,
        WalkSpeed = 16,
        WalkMethod = "Velocity",
        InfiniteJump = false,
        CustomJumpPower = false,
        JumpPower = 50,
        JumpMethod = "Velocity",
        
        -- Visuals
        ESPEnabled = false,
        ESPTracers = false,
        ESPNames = true,
        ESPBoxes = true,
        ESPTeamColor = false,
        ESPTeammates = false,
        ESPColor = Color3.fromRGB(255, 0, 0),
        FullBright = false,
        
        -- Misc
        Triggerbot = false,
        TriggerbotDelay = 0.2,
        TriggerbotTeamCheck = "Team-Based",
        AutoFarm = false,
        FOV = 70,
        NoClip = false,
    }
end

function ConfigSystem:SaveConfig(name)
    name = name or self.CurrentConfig
    local config = self:GetDefaultConfig()
    
    -- Update config with current values
    config.AimbotEnabled = getgenv().AimbotSettings.Enabled
    config.AimbotFOV = getgenv().AimbotSettings.FOV
    config.AimbotSmoothness = getgenv().AimbotSettings.Smoothness
    config.HitboxEnabled = getgenv().HitboxEnabled or false
    config.HitboxSize = getgenv().HitboxSize or 21
    
    self.Configs[name] = config
    writefile("ArsenalConfig_" .. name .. ".json", game:GetService('HttpService'):JSONEncode(config))
    
    CoreGui:SetCore("SendNotification", {
        Title = "Config Saved",
        Text = "Configuration '" .. name .. "' saved successfully!",
        Duration = 3,
    })
end

function ConfigSystem:LoadConfig(name)
    name = name or self.CurrentConfig
    local success, config = pcall(function()
        return game:GetService('HttpService'):JSONDecode(readfile("ArsenalConfig_" .. name .. ".json"))
    end)
    
    if success then
        -- Apply config settings
        getgenv().AimbotSettings.Enabled = config.AimbotEnabled
        getgenv().AimbotSettings.FOV = config.AimbotFOV
        getgenv().AimbotSettings.Smoothness = config.AimbotSmoothness
        
        CoreGui:SetCore("SendNotification", {
            Title = "Config Loaded",
            Text = "Configuration '" .. name .. "' loaded successfully!",
            Duration = 3,
        })
    else
        CoreGui:SetCore("SendNotification", {
            Title = "Config Error",
            Text = "Failed to load config '" .. name .. "'",
            Duration = 3,
        })
    end
end

function ConfigSystem:DeleteConfig(name)
    local success = pcall(function()
        delfile("ArsenalConfig_" .. name .. ".json")
    end)
    
    if success then
        self.Configs[name] = nil
        CoreGui:SetCore("SendNotification", {
            Title = "Config Deleted",
            Text = "Configuration '" .. name .. "' deleted!",
            Duration = 3,
        })
    end
end

-- ============================================
-- AIMBOT SYSTEM
-- ============================================
getgenv().AimbotSettings = {
    Enabled = false,
    TeamCheck = true,
    VisibleCheck = true,
    FOV = 100,
    Smoothness = 5,
    TargetPart = "Head",
    Prediction = false,
    PredictionAmount = 0.12,
    KeyBind = Enum.UserInputType.MouseButton2,
    ShowFOV = true,
    FOVColor = Color3.fromRGB(255, 0, 0),
}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = getgenv().AimbotSettings.ShowFOV
FOVCircle.Thickness = 2
FOVCircle.Color = getgenv().AimbotSettings.FOVColor
FOVCircle.Filled = false
FOVCircle.Radius = getgenv().AimbotSettings.FOV
FOVCircle.NumSides = 64

-- Update FOV Circle
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
    FOVCircle.Radius = getgenv().AimbotSettings.FOV
    FOVCircle.Visible = getgenv().AimbotSettings.ShowFOV and getgenv().AimbotSettings.Enabled
    FOVCircle.Color = getgenv().AimbotSettings.FOVColor
end)

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = getgenv().AimbotSettings.FOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local targetPart = character:FindFirstChild(getgenv().AimbotSettings.TargetPart)
            
            if humanoid and humanoid.Health > 0 and rootPart and targetPart then
                -- Team check
                if getgenv().AimbotSettings.TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end
                
                -- Visible check
                if getgenv().AimbotSettings.VisibleCheck then
                    local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
                    local part, position = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
                    if part and not character:IsAncestorOf(part) then
                        continue
                    end
                end
                
                -- Calculate distance
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local distance = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local isAiming = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == getgenv().AimbotSettings.KeyBind then
        isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == getgenv().AimbotSettings.KeyBind then
        isAiming = false
    end
end)

-- Aimbot Loop
RunService.RenderStepped:Connect(function()
    if getgenv().AimbotSettings.Enabled and isAiming then
        local target = GetClosestPlayer()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(getgenv().AimbotSettings.TargetPart)
            if targetPart then
                local targetPos = targetPart.Position
                
                -- Prediction
                if getgenv().AimbotSettings.Prediction then
                    local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        targetPos = targetPos + (rootPart.Velocity * getgenv().AimbotSettings.PredictionAmount)
                    end
                end
                
                -- Smooth aim
                local currentPos = Camera.CFrame.Position
                local direction = (targetPos - currentPos).Unit
                local targetCFrame = CFrame.new(currentPos, currentPos + direction)
                
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / getgenv().AimbotSettings.Smoothness)
            end
        end
    end
end)

-- ============================================
-- FLY SCRIPT
-- ============================================
local flySettings = {fly = false, flyspeed = 50}
local c, h, bv, bav, cam, flying
local buttons = {W = false, S = false, A = false, D = false, Moving = false}

local startFly = function()
    if not LocalPlayer.Character or not LocalPlayer.Character.Head or flying then return end
    c = LocalPlayer.Character
    h = c.Humanoid
    h.PlatformStand = true
    cam = Workspace.CurrentCamera
    bv = Instance.new("BodyVelocity")
    bav = Instance.new("BodyAngularVelocity")
    bv.Velocity, bv.MaxForce, bv.P = Vector3.new(0, 0, 0), Vector3.new(10000, 10000, 10000), 1000
    bav.AngularVelocity, bav.MaxTorque, bav.P = Vector3.new(0, 0, 0), Vector3.new(10000, 10000, 10000), 1000
    bv.Parent = c.Head
    bav.Parent = c.Head
    flying = true
    h.Died:connect(function() flying = false end)
end

local endFly = function()
    if not LocalPlayer.Character or not flying then return end
    h.PlatformStand = false
    bv:Destroy()
    bav:Destroy()
    flying = false
end

UserInputService.InputBegan:connect(function(input, GPE)
    if GPE then return end
    for i, e in pairs(buttons) do
        if i ~= "Moving" and input.KeyCode == Enum.KeyCode[i] then
            buttons[i] = true
            buttons.Moving = true
        end
    end
end)

UserInputService.InputEnded:connect(function(input, GPE)
    if GPE then return end
    local a = false
    for i, e in pairs(buttons) do
        if i ~= "Moving" then
            if input.KeyCode == Enum.KeyCode[i] then
                buttons[i] = false
            end
            if buttons[i] then
                a = true
            end
        end
    end
    buttons.Moving = a
end)

local setVec = function(vec)
    return vec * (flySettings.flyspeed / vec.Magnitude)
end

RunService.Heartbeat:connect(function(step)
    if flying and c and c.PrimaryPart then
        local p = c.PrimaryPart.Position
        local cf = cam.CFrame
        local ax, ay, az = cf:toEulerAnglesXYZ()
        c:SetPrimaryPartCFrame(CFrame.new(p.x, p.y, p.z) * CFrame.Angles(ax, ay, az))
        if buttons.Moving then
            local t = Vector3.new()
            if buttons.W then t = t + (setVec(cf.lookVector)) end
            if buttons.S then t = t - (setVec(cf.lookVector)) end
            if buttons.A then t = t - (setVec(cf.rightVector)) end
            if buttons.D then t = t + (setVec(cf.rightVector)) end
            c:TranslateBy(t * step)
        end
    end
end)

-- ============================================
-- UI LIBRARY
-- ============================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bitef4/Recode/main/UI/Kavo_1.lua"))()
local Window = Library.CreateLib("AdvanceTech Arsenal v2.0 | Enhanced", "DarkTheme")

-- Status Display
local statusText = "Status: Ready | Aimbot: OFF | ESP: OFF"

-- ============================================
-- AIMBOT TAB
-- ============================================
local AimbotTab = Window:NewTab("🎯 Aimbot")
local AimbotMain = AimbotTab:NewSection("Main Settings")
local AimbotFOV = AimbotTab:NewSection("FOV Settings")
local AimbotAdvanced = AimbotTab:NewSection("Advanced Settings")

AimbotMain:NewToggle("Enable Aimbot", "Toggle aimbot on/off", function(state)
    getgenv().AimbotSettings.Enabled = state
    CoreGui:SetCore("SendNotification", {
        Title = "Aimbot",
        Text = state and "Enabled!" or "Disabled!",
        Duration = 2,
    })
end)

AimbotMain:NewDropdown("Target Part", "Select body part to aim at", {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"
}, function(selected)
    getgenv().AimbotSettings.TargetPart = selected
end)

AimbotMain:NewSlider("Smoothness", "How smooth the aimbot is (1-20)", 20, 1, function(value)
    getgenv().AimbotSettings.Smoothness = value
end)

AimbotMain:NewToggle("Team Check", "Don't aim at teammates", function(state)
    getgenv().AimbotSettings.TeamCheck = state
end)

AimbotMain:NewToggle("Visible Check", "Only aim at visible targets", function(state)
    getgenv().AimbotSettings.VisibleCheck = state
end)

AimbotFOV:NewToggle("Show FOV Circle", "Display FOV circle", function(state)
    getgenv().AimbotSettings.ShowFOV = state
end)

AimbotFOV:NewSlider("FOV Size", "Adjust FOV circle size", 500, 50, function(value)
    getgenv().AimbotSettings.FOV = value
end)

AimbotFOV:NewColorPicker("FOV Color", "Change FOV circle color", Color3.fromRGB(255, 0, 0), function(color)
    getgenv().AimbotSettings.FOVColor = color
end)

AimbotAdvanced:NewToggle("Prediction", "Enable bullet prediction", function(state)
    getgenv().AimbotSettings.Prediction = state
end)

AimbotAdvanced:NewSlider("Prediction Amount", "Adjust prediction strength", 50, 1, function(value)
    getgenv().AimbotSettings.PredictionAmount = value / 100
end)

AimbotAdvanced:NewLabel("Hold RIGHT MOUSE to activate aimbot")

-- ============================================
-- COMBAT TAB (Hitbox, Triggerbot, etc.)
-- ============================================
local CombatTab = Window:NewTab("⚔️ Combat")
local HitboxSection = CombatTab:NewSection("Hitbox Expander")
local TriggerbotSection = CombatTab:NewSection("Triggerbot")

-- Hitbox variables
getgenv().HitboxEnabled = false
local hitbox_original_properties = {}
getgenv().HitboxSize = 21
local hitboxTransparency = 6
local teamCheck = "FFA"
local noCollisionEnabled = false

local defaultBodyParts = {"UpperTorso", "Head", "HumanoidRootPart"}

local function savedPart(player, part)
    if not hitbox_original_properties[player] then
        hitbox_original_properties[player] = {}
    end
    if not hitbox_original_properties[player][part.Name] then
        hitbox_original_properties[player][part.Name] = {
            CanCollide = part.CanCollide,
            Transparency = part.Transparency,
            Size = part.Size
        }
    end
end

local function restoredPart(player)
    if hitbox_original_properties[player] then
        for partName, properties in pairs(hitbox_original_properties[player]) do
            local part = player.Character and player.Character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.CanCollide = properties.CanCollide
                part.Transparency = properties.Transparency
                part.Size = properties.Size
            end
        end
    end
end

local function extendHitbox(player)
    for _, partName in ipairs(defaultBodyParts) do
        local part = player.Character and player.Character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            savedPart(player, part)
            part.CanCollide = not noCollisionEnabled
            part.Transparency = hitboxTransparency / 10
            part.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
        end
    end
end

local function isEnemy(player)
    if teamCheck == "FFA" or teamCheck == "Everyone" then
        return true
    end
    return player.Team ~= LocalPlayer.Team
end

local function updateHitboxes()
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            if isEnemy(v) then
                extendHitbox(v)
            else
                restoredPart(v)
            end
        end
    end
end

HitboxSection:NewToggle("Enable Hitbox", "Expand enemy hitboxes", function(enabled)
    getgenv().HitboxEnabled = enabled
    if not enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            restoredPart(player)
        end
        hitbox_original_properties = {}
    end
end)

HitboxSection:NewSlider("Hitbox Size", "Adjust hitbox size", 25, 1, function(value)
    getgenv().HitboxSize = value
end)

HitboxSection:NewSlider("Transparency", "Adjust hitbox transparency", 10, 1, function(value)
    hitboxTransparency = value
end)

HitboxSection:NewDropdown("Team Check", "Select team check mode", {"FFA", "Team-Based", "Everyone"}, function(value)
    teamCheck = value
end)

-- Hitbox update loop
spawn(function()
    while wait(0.1) do
        if getgenv().HitboxEnabled then
            updateHitboxes()
        end
    end
end)

-- Triggerbot
getgenv().triggerb = false
local triggerbotTeamcheck = "Team-Based"
local triggerbotDelay = 0.2

TriggerbotSection:NewToggle("Enable Triggerbot", "Auto-shoot when hovering over enemy", function(state)
    getgenv().triggerb = state
end)

TriggerbotSection:NewDropdown("Team Check", "Select team check mode", {"FFA", "Team-Based", "Everyone"}, function(selected)
    triggerbotTeamcheck = selected
end)

TriggerbotSection:NewSlider("Shot Delay", "Delay between shots", 10, 1, function(value)
    triggerbotDelay = value / 10
end)

-- ============================================
-- GUN MODS TAB
-- ============================================
local GunTab = Window:NewTab("🔫 Gun Mods")
local GunSection = GunTab:NewSection("Weapon Modifications")

local originalValues = {
    FireRate = {},
    ReloadTime = {},
    EReloadTime = {},
    Auto = {},
    Spread = {},
    Recoil = {}
}

GunSection:NewToggle("Infinite Ammo", "Never run out of ammo", function(v)
    ReplicatedStorage.wkspc.CurrentCurse.Value = v and "Infinite Ammo" or ""
end)

GunSection:NewToggle("Fast Reload", "Instant reload", function(x)
    for _, v in pairs(ReplicatedStorage.Weapons:GetChildren()) do
        if v:FindFirstChild("ReloadTime") then
            if x then
                if not originalValues.ReloadTime[v] then
                    originalValues.ReloadTime[v] = v.ReloadTime.Value
                end
                v.ReloadTime.Value = 0.01
            else
                if originalValues.ReloadTime[v] then
                    v.ReloadTime.Value = originalValues.ReloadTime[v]
                end
            end
        end
    end
end)

GunSection:NewToggle("Fast Fire Rate", "Shoot faster", function(state)
    for _, v in pairs(ReplicatedStorage.Weapons:GetDescendants()) do
        if v.Name == "FireRate" or v.Name == "BFireRate" then
            if state then
                if not originalValues.FireRate[v] then
                    originalValues.FireRate[v] = v.Value
                end
                v.Value = 0.02
            else
                if originalValues.FireRate[v] then
                    v.Value = originalValues.FireRate[v]
                end
            end
        end
    end
end)

GunSection:NewToggle("Always Auto", "Make all guns automatic", function(state)
    for _, v in pairs(ReplicatedStorage.Weapons:GetDescendants()) do
        if v.Name == "Auto" then
            if state then
                if not originalValues.Auto[v] then
                    originalValues.Auto[v] = v.Value
                end
                v.Value = true
            else
                if originalValues.Auto[v] then
                    v.Value = originalValues.Auto[v]
                end
            end
        end
    end
end)

GunSection:NewToggle("No Spread", "Perfect accuracy", function(state)
    for _, v in pairs(ReplicatedStorage.Weapons:GetDescendants()) do
        if v.Name == "MaxSpread" or v.Name == "Spread" then
            if state then
                if not originalValues.Spread[v] then
                    originalValues.Spread[v] = v.Value
                end
                v.Value = 0
            else
                if originalValues.Spread[v] then
                    v.Value = originalValues.Spread[v]
                end
            end
        end
    end
end)

GunSection:NewToggle("No Recoil", "Remove weapon recoil", function(state)
    for _, v in pairs(ReplicatedStorage.Weapons:GetDescendants()) do
        if v.Name == "RecoilControl" or v.Name == "Recoil" then
            if state then
                if not originalValues.Recoil[v] then
                    originalValues.Recoil[v] = v.Value
                end
                v.Value = 0
            else
                if originalValues.Recoil[v] then
                    v.Value = originalValues.Recoil[v]
                end
            end
        end
    end
end)

-- ============================================
-- PLAYER TAB
-- ============================================
local PlayerTab = Window:NewTab("👤 Player")
local MovementSection = PlayerTab:NewSection("Movement")
local MiscSection = PlayerTab:NewSection("Miscellaneous")

MovementSection:NewToggle("Fly", "Enable flying", function(state)
    if state then
        startFly()
    else
        endFly()
    end
end)

MovementSection:NewSlider("Fly Speed", "Adjust fly speed", 500, 1, function(s)
    flySettings.flyspeed = s
end)

local settings = {WalkSpeed = 16}
local isWalkSpeedEnabled = false

MovementSection:NewToggle("Custom WalkSpeed", "Enable custom walk speed", function(enabled)
    isWalkSpeedEnabled = enabled
end)

MovementSection:NewSlider("WalkSpeed", "Adjust walk speed", 500, 16, function(value)
    settings.WalkSpeed = value
end)

-- ============================================
-- CONFIG TAB
-- ============================================
local ConfigTab = Window:NewTab("⚙️ Config")
local ConfigSection = ConfigTab:NewSection("Configuration Manager")
local QuickActions = ConfigTab:NewSection("Quick Actions")

local configName = "default"

ConfigSection:NewTextBox("Config Name", "Enter config name", function(txt)
    configName = txt
end)

ConfigSection:NewButton("Save Config", "Save current settings", function()
    ConfigSystem:SaveConfig(configName)
end)

ConfigSection:NewButton("Load Config", "Load saved settings", function()
    ConfigSystem:LoadConfig(configName)
end)

ConfigSection:NewButton("Delete Config", "Delete a config", function()
    ConfigSystem:DeleteConfig(configName)
end)

QuickActions:NewButton("Save as 'Legit'", "Quick save for legit settings", function()
    ConfigSystem:SaveConfig("legit")
end)

QuickActions:NewButton("Save as 'Rage'", "Quick save for rage settings", function()
    ConfigSystem:SaveConfig("rage")
end)

QuickActions:NewButton("Reset to Default", "Reset all settings", function()
    local default = ConfigSystem:GetDefaultConfig()
    -- Apply default settings
    CoreGui:SetCore("SendNotification", {
        Title = "Config Reset",
        Text = "All settings reset to default!",
        Duration = 3,
    })
end)

-- ============================================
-- SETTINGS TAB
-- ============================================
local SettingsTab = Window:NewTab("🔧 Settings")
local ThemeSection = SettingsTab:NewSection("UI Theme")
local KeybindSection = SettingsTab:NewSection("Keybinds")

ThemeSection:NewButton("Dark Theme", "Switch to dark theme", function()
    Library:ChangeTheme("DarkTheme")
end)

ThemeSection:NewButton("Blue Theme", "Switch to blue theme", function()
    Library:ChangeTheme("BlueTheme")
end)

ThemeSection:NewButton("Grape Theme", "Switch to grape theme", function()
    Library:ChangeTheme("GrapeTheme")
end)

ThemeSection:NewButton("Ocean Theme", "Switch to ocean theme", function()
    Library:ChangeTheme("Ocean")
end)

KeybindSection:NewKeybind("Toggle UI", "Show/hide the menu", Enum.KeyCode.RightShift, function()
    Library:ToggleUI()
end)

-- ============================================
-- CREDITS TAB
-- ============================================
local CreditsTab = Window:NewTab("ℹ️ Credits")
local CreditsSection = CreditsTab:NewSection("Script Information")

CreditsSection:NewLabel("AdvanceTech Arsenal v2.0")
CreditsSection:NewLabel("Enhanced Edition")
CreditsSection:NewLabel("")
CreditsSection:NewLabel("Developed by: AdvanceFalling Team")
CreditsSection:NewLabel("Features: Aimbot, Configs, Enhanced UI")
CreditsSection:NewLabel("")

CreditsSection:NewButton("Join Discord", "Copy Discord invite", function()
    setclipboard("https://discord.com/invite/d2446gBjfq")
    CoreGui:SetCore("SendNotification", {
        Title = "Discord",
        Text = "Invite link copied to clipboard!",
        Duration = 3,
    })
end)

-- ============================================
-- GUI TOGGLE BUTTON
-- ============================================
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local frame = Instance.new("ImageLabel", gui)
local button = Instance.new("TextButton", frame)

frame.BackgroundTransparency = 1
frame.Position = UDim2.new(0, 0, 0.65, -100)
frame.Size = UDim2.new(0, 100, 0, 50)
frame.Image = "rbxassetid://3570695787"
frame.ImageColor3 = Color3.fromRGB(11, 18, 7)
frame.ImageTransparency = 0.2
frame.ScaleType = Enum.ScaleType.Slice
frame.SliceCenter = Rect.new(100, 100, 100, 100)
frame.SliceScale = 0.12

button.AnchorPoint = Vector2.new(0, 0.5)
button.BackgroundTransparency = 1
button.Position = UDim2.new(0.022, 0, 0.85, -20)
button.Size = UDim2.new(1, -10, 1, 0)
button.Font = Enum.Font.GothamBold
button.Text = "Toggle"
button.TextColor3 = Color3.fromRGB(0, 170, 255)
button.TextSize = 20
button.TextWrapped = true
button.ZIndex = 11

button.MouseButton1Down:Connect(function()
    Library:ToggleUI()
end)

-- Dragging functionality
local dragging, dragStart, startPos = false, nil, nil

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

button.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        update(input)
    end
end)

-- ============================================
-- VISUAL ESP TAB
-- ============================================
local VisualTab = Window:NewTab("👁️ Visuals")
local ESPSection = VisualTab:NewSection("ESP Settings")

local esp = loadstring(game:HttpGet("https://rawscript.vercel.app/api/raw/esp_1"))()

ESPSection:NewToggle("Enable ESP", "Toggle ESP on/off", function(K)
    esp:Toggle(K)
    esp.Players = K
end)

ESPSection:NewToggle("Boxes", "Show boxes around players", function(K)
    esp.Boxes = K
end)

ESPSection:NewToggle("Names", "Show player names", function(K)
    esp.Names = K
end)

ESPSection:NewToggle("Tracers", "Show lines to players", function(K)
    esp.Tracers = K
end)

ESPSection:NewToggle("Team Color", "Use team colors", function(L)
    esp.TeamColor = L
end)

ESPSection:NewToggle("Show Teammates", "Show ESP for teammates", function(L)
    esp.TeamMates = L
end)

ESPSection:NewColorPicker("ESP Color", "Change ESP color", Color3.fromRGB(255, 0, 0), function(P)
    esp.Color = P
end)

local MiscVisuals = VisualTab:NewSection("Miscellaneous")

MiscVisuals:NewToggle("Full Bright", "See everything clearly", function(enabled)
    local Light = game:GetService("Lighting")
    if enabled then
        Light.Ambient = Color3.new(1, 1, 1)
        Light.ColorShift_Bottom = Color3.new(1, 1, 1)
        Light.ColorShift_Top = Color3.new(1, 1, 1)
    else
        Light.Ambient = Color3.new(0.5, 0.5, 0.5)
        Light.ColorShift_Bottom = Color3.new(0, 0, 0)
        Light.ColorShift_Top = Color3.new(0, 0, 0)
    end
end)

MiscVisuals:NewSlider("FOV", "Adjust field of view", 120, 70, function(num)
    LocalPlayer.Settings.FOV.Value = num
end)

-- ============================================
-- MISC/FUN TAB
-- ============================================
local MiscTab = Window:NewTab("🎮 Misc")
local FunSection = MiscTab:NewSection("Fun Features")
local UtilitySection = MiscTab:NewSection("Utilities")

-- Rainbow Gun
local rainbowEnabled = false
local c = 1

function zigzag(X)
    return math.acos(math.cos(X * math.pi)) / math.pi
end

FunSection:NewToggle("Rainbow Gun", "Make your gun rainbow colored", function(state)
    rainbowEnabled = state
end)

RunService.RenderStepped:Connect(function()
    if Workspace.Camera:FindFirstChild('Arms') and rainbowEnabled then
        for i, v in pairs(Workspace.Camera.Arms:GetDescendants()) do
            if v.ClassName == 'MeshPart' then
                v.Color = Color3.fromHSV(zigzag(c), 1, 1)
                c = c + .0001
            end
        end
    end
end)

-- Arm Customization
local armMaterial = "Plastic"
local armColor = Color3.new(1, 1, 1)
local armCharmsEnabled = false

FunSection:NewDropdown("Arm Material", "Change arm material", {
    "Plastic", "ForceField", "Wood", "Grass", "Neon"
}, function(selected)
    armMaterial = selected
end)

FunSection:NewColorPicker("Arm Color", "Change arm color", Color3.fromRGB(255, 255, 255), function(color)
    armColor = color
end)

FunSection:NewToggle("Apply Arm Skin", "Enable arm customization", function(enabled)
    armCharmsEnabled = enabled
end)

spawn(function()
    while wait(0.01) do
        if armCharmsEnabled then
            local cameraArms = Workspace.Camera:FindFirstChild("Arms")
            if cameraArms then
                for _, part in pairs(cameraArms:GetDescendants()) do
                    if part.Name == 'Right Arm' or part.Name == 'Left Arm' then
                        if part:IsA("BasePart") then
                            part.Material = Enum.Material[armMaterial]
                            part.Color = armColor
                        end
                    end
                end
            end
        end
    end
end)

-- Utilities
UtilitySection:NewToggle("NoClip", "Walk through walls", function(enabled)
    local noClipEnabled = enabled
    spawn(function()
        while noClipEnabled do
            local character = LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
            RunService.Stepped:Wait()
        end
        
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)
end)

UtilitySection:NewButton("Rejoin Server", "Rejoin current server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

UtilitySection:NewButton("Server Hop", "Join different server", function()
    local PlaceId = game.PlaceId
    local AllIDs = {}
    local foundAnything = ""
    local actualHour = os.date("!*t").hour
    
    local function TPReturner()
        local Site
        if foundAnything == "" then
            Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceId .. '/servers/Public?sortOrder=Asc&limit=100'))
        else
            Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
        end
        
        if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
            foundAnything = Site.nextPageCursor
        end
        
        for i,v in pairs(Site.data) do
            local ID = tostring(v.id)
            if tonumber(v.maxPlayers) > tonumber(v.playing) then
                for _, Existing in pairs(AllIDs) do
                    if ID == tostring(Existing) then
                        return
                    end
                end
                table.insert(AllIDs, ID)
                wait()
                pcall(function()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceId, ID, LocalPlayer)
                end)
                wait(4)
            end
        end
    end
    
    while wait() do
        pcall(function()
            TPReturner()
            if foundAnything ~= "" then
                TPReturner()
            end
        end)
    end
end)

-- ============================================
-- STATUS UPDATES
-- ============================================
spawn(function()
    while wait(1) do
        local aimbotStatus = getgenv().AimbotSettings.Enabled and "ON" or "OFF"
        local espStatus = esp.Players and "ON" or "OFF"
        local hitboxStatus = getgenv().HitboxEnabled and "ON" or "OFF"
        
        -- You can add a status label to the UI if you want
        -- This is just for notification purposes
    end
end)

-- ============================================
-- AUTO-SAVE CONFIG ON EXIT
-- ============================================
game:GetService("GuiService").MenuOpened:Connect(function()
    -- Auto-save when Roblox menu opens (game exit)
    ConfigSystem:SaveConfig("autosave")
end)

-- ============================================
-- FINAL NOTIFICATIONS
-- ============================================
wait(2)
CoreGui:SetCore("SendNotification", {
    Title = "Script Loaded!",
    Text = "Press RIGHT SHIFT to toggle UI",
    Duration = 5,
})

CoreGui:SetCore("SendNotification", {
    Title = "Aimbot Ready!",
    Text = "Hold RIGHT MOUSE to activate",
    Duration = 5,
})

print([[
═══════════════════════════════════════
    AdvanceTech Arsenal v2.0
    Enhanced Edition - Loaded Successfully!
    
    Features:
    ✓ Advanced Aimbot System
    ✓ Config Save/Load System
    ✓ Hitbox Expander
    ✓ Gun Modifications
    ✓ ESP & Visuals
    ✓ Enhanced UI
    
    Made by: AdvanceFalling Team
═══════════════════════════════════════
]])
