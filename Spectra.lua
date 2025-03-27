local UserInputService = game:GetService("UserInputService")

if getgenv().SA_LOADED and not getgenv().SA_DEBUG then
    print("Spectra is already loaded. Exiting script...")
    return
end

pcall(function() 
    getgenv().SA_LOADED = true 
    print("Spectra loaded successfully.")
end)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local settings = {
	ESPHealth = false,
    ESPEnabled = false,
    ESPBox = false,
    ESPName = false,
    ESPTracer = false,
    BoxColor = Color3.fromRGB(255, 0, 0),
    NameColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(0, 255, 0),
    AimbotEnabled = false,
    AimKey = Enum.KeyCode.X,
    FOV = 100,
    LockStrength = 1,
    PredictionFactor = 0.03,
    Smoothing = 5,
    TargetPart = "Head",
    SilentAim = false,
    SilentAimStrength = 0,
    SilentAimEnabled = false,
    FlyEnabled = false,
    FlySpeed = 50,
    FlyKeybind = Enum.KeyCode.F
}

local ESPObjects = {} 

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            if obj then
                obj:Remove()
            end
        end
        ESPObjects[player] = nil
    end
end

local function CreateESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end 

    ESPObjects[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        HealthBar = Drawing.new("Line")  
    }

    
    ESPObjects[player].Box.Color = settings.BoxColor
    ESPObjects[player].Box.Thickness = 2
    ESPObjects[player].Box.Filled = false
    ESPObjects[player].Box.Visible = false

    
    ESPObjects[player].Name.Color = settings.NameColor
    ESPObjects[player].Name.Size = 18
    ESPObjects[player].Name.Center = true
    ESPObjects[player].Name.Outline = true
    ESPObjects[player].Name.Visible = false

    
    ESPObjects[player].Tracer.Color = settings.TracerColor
    ESPObjects[player].Tracer.Thickness = 1.5
    ESPObjects[player].Tracer.Visible = false

    
    ESPObjects[player].HealthBar.Color = Color3.fromRGB(0, 255, 0) 
    ESPObjects[player].HealthBar.Thickness = 2
    ESPObjects[player].HealthBar.Visible = false
end


local function RemoveAllESP()
    for player, esp in pairs(ESPObjects) do
        for _, obj in pairs(esp) do
            if obj then
                obj:Remove()
            end
        end
        ESPObjects[player] = nil
    end
end


RunService.RenderStepped:Connect(function()
    if not settings or not settings.ESPEnabled then
        RemoveAllESP() 
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            if humanoid.Health > 0 then
                if not ESPObjects[player] then
                    CreateESP(player)
                end

                local esp = ESPObjects[player]
                local rootPart = player.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

                if onScreen then
                    local size = math.clamp(3000 / (Camera.CFrame.Position - rootPart.Position).Magnitude, 40, 120)

                    
                    esp.Box.Visible = settings.ESPBox
                    if settings.ESPBox then
                        esp.Box.Size = Vector2.new(size, size * 2)
                        esp.Box.Position = Vector2.new(screenPos.X - size / 2, screenPos.Y - size / 2)
                    end

                    
                    esp.Name.Visible = settings.ESPName
                    if settings.ESPName then
                        esp.Name.Text = player.Name
                        esp.Name.Position = Vector2.new(screenPos.X, screenPos.Y - size / 2 - 15)
                    end

                    
                    esp.Tracer.Visible = settings.ESPTracer
                    if settings.ESPTracer then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    end

                    
                    esp.HealthBar.Visible = settings.ESPHealth
                    if settings.ESPHealth then
                        local healthPercentage = humanoid.Health / humanoid.MaxHealth
                        local healthBarHeight = size * 2
                        esp.HealthBar.From = Vector2.new(screenPos.X - size / 2 - 5, screenPos.Y - size / 2 + healthBarHeight)
                        esp.HealthBar.To = Vector2.new(screenPos.X - size / 2 - 5, screenPos.Y - size / 2 + healthBarHeight - (healthPercentage * healthBarHeight))
                    end
                else
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.Tracer.Visible = false
                    esp.HealthBar.Visible = false
                end
            else
                RemoveESP(player)
            end
        else
            RemoveESP(player)
        end
    end
end)


Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)


local flying = false
local flyVelocity
local flyGyro
local movementDirection = Vector3.new(0, 0, 0)
local HumanoidRootPart


local function UpdateCharacter()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") 
end


LocalPlayer.CharacterAdded:Connect(function()
    UpdateCharacter()
    if settings.FlyEnabled then
        ToggleFly(true) 
    end
end)


local function UpdateFlySpeed(speed)
    settings.FlySpeed = speed
end


local function ToggleFly(state)
    if not HumanoidRootPart then
        UpdateCharacter() 
    end

    if state == nil then
        flying = not flying
    else
        flying = state
    end

    if flying then
        if not HumanoidRootPart then return end

        
        flyVelocity = Instance.new("BodyVelocity")
        flyVelocity.Velocity = Vector3.zero
        flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyVelocity.Parent = HumanoidRootPart

        
        flyGyro = Instance.new("BodyGyro")
        flyGyro.CFrame = HumanoidRootPart.CFrame
        flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyGyro.Parent = HumanoidRootPart

    else
        if flyVelocity then
            flyVelocity:Destroy()
            flyVelocity = nil
        end

        if flyGyro then
            flyGyro:Destroy()
            flyGyro = nil
        end

        movementDirection = Vector3.new(0, 0, 0)
    end
end


UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == settings.FlyKeybind then
        if settings.FlyEnabled then
            ToggleFly()
        end
    end
end)


local function UpdateMovement()
    movementDirection = Vector3.new(0, 0, 0)

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        movementDirection = movementDirection + Vector3.new(0, 0, -1) 
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        movementDirection = movementDirection + Vector3.new(0, 0, 1) 
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        movementDirection = movementDirection + Vector3.new(-1, 0, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        movementDirection = movementDirection + Vector3.new(1, 0, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        movementDirection = movementDirection + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        movementDirection = movementDirection + Vector3.new(0, -1, 0)
    end

    
    if movementDirection.Magnitude > 0 then
        movementDirection = movementDirection.Unit
    end
end


RunService.RenderStepped:Connect(function()
    
    if not settings.FlyEnabled and flying then
        ToggleFly(false) 
    end

    
    if flying and flyVelocity and HumanoidRootPart then
        UpdateMovement()
        local camDirection = workspace.CurrentCamera.CFrame.LookVector
        local rightVector = workspace.CurrentCamera.CFrame.RightVector
        local moveVector = (camDirection * -movementDirection.Z) + (rightVector * movementDirection.X) + (Vector3.new(0, 1, 0) * movementDirection.Y)

        flyVelocity.Velocity = moveVector * settings.FlySpeed
        flyGyro.CFrame = workspace.CurrentCamera.CFrame
    end
end)


UpdateCharacter()


settings = settings or {} 
settings.AimbotEnabled = settings.AimbotEnabled or false
settings.Smoothing = settings.Smoothing or 5
settings.LockStrength = settings.LockStrength or 1.0
settings.PredictionFactor = settings.PredictionFactor or 1.0
settings.AimKey = settings.AimKey or Enum.KeyCode.X 

local targetPlayer
local targetDistance
local lastMousePos = UserInputService:GetMouseLocation()
local aiming = false 


local function GetClosestTarget()
    local closestPlayer = nil
    local closestDist = math.huge
    local closestDistance3D = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local targetPart = player.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)

            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                local dist3D = (LocalPlayer.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude

                if dist2D < closestDist then
                    closestDist = dist2D
                    closestDistance3D = dist3D
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer, closestDistance3D
end


local function AdjustAimSettings(distance)
    local smoothing = settings.Smoothing
    local predictionFactor = settings.PredictionFactor
    local lockStrength = settings.LockStrength

    if distance <= 3 then
        lockStrength = 1.3 
    elseif distance > 100 then
        smoothing = math.max(smoothing * 0.75, 0.1) 
        predictionFactor = math.max(predictionFactor * 0.75, 0.1)
    end

    return smoothing, predictionFactor, lockStrength
end


local function AimAt(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local targetPart = target.Character.Head
        local distance = (LocalPlayer.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude
        local smoothing, predictionFactor, lockStrength = AdjustAimSettings(distance)

        local predictedPos = targetPart.Position + (targetPart.Velocity * predictionFactor)
        local targetScreenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)

        if onScreen then
            local currentMousePos = UserInputService:GetMouseLocation()
            local deltaX = (targetScreenPos.X - currentMousePos.X) / smoothing
            local deltaY = (targetScreenPos.Y - currentMousePos.Y) / smoothing

            mousemoverel(deltaX, deltaY)
        end
    end
end

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == settings.AimKey or input.UserInputType == settings.AimKey then
        aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == settings.AimKey or input.UserInputType == settings.AimKey then
        aiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    if settings.AimbotEnabled and aiming then
        local target, distance = GetClosestTarget()
        if target then
            AimAt(target)
        end
    end
end)


local previousSettings = {
    Smoothing = settings.Smoothing,
    PredictionFactor = settings.PredictionFactor,
    LockStrength = settings.LockStrength
}

local function MonitorSettings()
    RunService.RenderStepped:Connect(function()
        if settings.Smoothing ~= previousSettings.Smoothing or
           settings.PredictionFactor ~= previousSettings.PredictionFactor or
           settings.LockStrength ~= previousSettings.LockStrength then
            

            
            previousSettings.Smoothing = settings.Smoothing
            previousSettings.PredictionFactor = settings.PredictionFactor
            previousSettings.LockStrength = settings.LockStrength
        end
    end)
end


MonitorSettings()

local ca = game:GetService("ContextActionService")
local players = game:GetService("Players")
local zeezy = players.LocalPlayer
local h = 0.0174533
local character = zeezy.Character or zeezy.CharacterAdded:Wait() 
local settings = settings or {}


zeezy.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
end)

function zeezyFrontflip(act, inp, obj)
    if inp == Enum.UserInputState.Begin and settings.Frontflip then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end 

        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState("Jumping")
            wait()
            humanoid.Sit = true
            for i = 1, 360 do
                delay(i / 720, function()
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        humanoid.Sit = true
                        character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(-h, 0, 0)
                    end
                end)
            end
            wait(0.55)
            if humanoid then
                humanoid.Sit = false
            end
        end
    end
end

function zeezyBackflip(act, inp, obj)
    if inp == Enum.UserInputState.Begin and settings.Backflip then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end 

        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState("Jumping")
            wait()
            humanoid.Sit = true
            for i = 1, 360 do
                delay(i / 720, function()
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        humanoid.Sit = true
                        character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(h, 0, 0)
                    end
                end)
            end
            wait(0.55)
            if humanoid then
                humanoid.Sit = false
            end
        end
    end
end

local FrontflipKey = Enum.KeyCode.Z
local BackflipKey = Enum.KeyCode.X
ca:BindAction("zeezyFrontflip", zeezyFrontflip, false, FrontflipKey)
ca:BindAction("zeezyBackflip", zeezyBackflip, false, BackflipKey)

local NoClipEnabled = false

local function EnableNoclip()
    NoClipEnabled = true
    RunService.Stepped:Connect(function()
        if NoClipEnabled and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function DisableNoclip()
    NoClipEnabled = false
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end





-- [[ MENU ]]


local successUI, UILib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/rustbuilderz/SpectraRoblox/refs/heads/main/library.lua"))()
end)
if not successUI then warn("❌ Failed to load UI Library!") end

local Main = UILib:Main("Script Menu")

local AimbotTab = Main:NewTab("Aimbot")

AimbotTab:NewToggle("Aimbot", function(state)
    settings.AimbotEnabled = state
end, settings.AimbotEnabled)

AimbotTab:NewSlider("Smoothing", 1, 20, 1, function(value)
    settings.Smoothing = value
end, settings.Smoothing or 5)

AimbotTab:NewSlider("Lock Strength", 1, 100, 1, function(value)
    settings.LockStrength = value / 100
end, (settings.LockStrength or 1) * 100)

AimbotTab:NewSlider("Prediction Factor", 0, 100, 1, function(value)
    settings.PredictionFactor = value / 100
end, (settings.PredictionFactor or 0.3) * 100)

AimbotTab:NewDropdown("Target Part", {"Head", "Torso"}, function(selected)
    settings.TargetPart = selected
end, settings.TargetPart or "Head")

AimbotTab:NewDropdown("Aim Key", {"X", "Left Mouse Button", "Right Mouse Button", "C"}, function(selected)
    local keyMap = {
        ["Right Mouse Button"] = Enum.UserInputType.MouseButton2,
        ["Left Mouse Button"] = Enum.UserInputType.MouseButton1,
        ["X"] = Enum.KeyCode.X,
        ["C"] = Enum.KeyCode.C
    }
    settings.AimKey = keyMap[selected] or Enum.KeyCode.X
end, "X")

local ESPTab = Main:NewTab("ESP")

ESPTab:NewToggle("ESP", function(state)
    settings.ESPEnabled = state
end, settings.ESPEnabled)

ESPTab:NewToggle("ESP Health", function(state)
    settings.ESPHealth = state
end, settings.ESPHealth)

ESPTab:NewToggle("ESP Box", function(state)
    settings.ESPBox = state
end, settings.ESPBox)

ESPTab:NewToggle("ESP Name", function(state)
    settings.ESPName = state
end, settings.ESPName)

ESPTab:NewToggle("ESP Tracer", function(state)
    settings.ESPTracer = state
end, settings.ESPTracer)

local MovementTab = Main:NewTab("Movement")

local InfiniteJumpEnabled = false

MovementTab:NewToggle("Infinite Jump", function(state)
    InfiniteJumpEnabled = state
    settings.InfiniteJump = state
end, settings.InfiniteJump)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local humanoid = game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState("Jumping")
        end
    end
end)

MovementTab:NewToggle("Fly", function(state)
    settings.FlyEnabled = state
end, settings.FlyEnabled)


MovementTab:NewToggle("NoClip", function(state)
    if state then
        EnableNoclip()
    else
        DisableNoclip()
    end
end, NoClipEnabled) 

MovementTab:NewToggle("Frontflip", function(state)
    settings.Frontflip = state  
end, settings.Frontflip)

MovementTab:NewToggle("Backflip", function(state)
    settings.Backflip = state  
end, settings.Backflip)


MovementTab:NewSlider("Fly Speed", 10, 100, 5, function(value)
    settings.FlySpeed = value
end, settings.FlySpeed)

MovementTab:NewDropdown("Fly Keybind", {"F", "B", "E", "C"}, function(selected)
    local keyMap = {
        ["F"] = Enum.KeyCode.F,
        ["B"] = Enum.KeyCode.B,
        ["E"] = Enum.KeyCode.E,
        ["C"] = Enum.KeyCode.C
    }
    settings.FlyKeybind = keyMap[selected]
end, settings.FlyKeybind)

MovementTab:NewButton("Refresh Fly", function()
end)



local MiscTab = Main:NewTab("Misc")

MiscTab:NewButton("Rejoin Lobby", function()
    print("🔄 Rejoining...")
    TeleportService:Teleport(PlaceId, LocalPlayer)
end)

MiscTab:NewButton("Bullet Tracer WARNING THIS IS EXPERIMENTAL", function()
    print("⚠️ Loading Bullet Tracer Script...")
	print("⚠️ Lasy ass developer alert, bitch has not made shit work")
end)
