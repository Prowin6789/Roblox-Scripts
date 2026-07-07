--[[
    Скрипт: Premium GUI спавнер блоков для Roblox (ФИКС АВТОЗАКРЫТИЯ)
    Версия: 2.7
    Исправления: устранена проблема автоматического закрытия UI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

if not player then
    error("Player not loaded")
end

local playerGui = nil
for i = 1, 20 do
    playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then break end
    task.wait(0.1)
end
if not playerGui then
    error("PlayerGui not found")
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local isTablet = UserInputService.TouchEnabled and UserInputService.MouseEnabled
local isPC = not UserInputService.TouchEnabled

local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
local screenWidth = viewportSize.X

local SCALE = 1
if isMobile then
    if screenWidth < 600 then
        SCALE = 0.65
    else
        SCALE = 0.75
    end
elseif isTablet then
    SCALE = 0.85
else
    SCALE = 1.0
end

local CONFIG = {
    ToggleKey = Enum.KeyCode.Insert,
    AnimationDuration = 0.25,
    SpawnCount = 150,
    SpawnDelay = 0.05,
    ButtonSize = 40 * SCALE,
    WindowWidth = 280 * SCALE,
    WindowHeight = 340 * SCALE,
    CornerRadius = 12,
    Colors = {
        Background = Color3.fromRGB(18, 18, 22),
        Accent = Color3.fromRGB(70, 130, 255),
        AccentHover = Color3.fromRGB(100, 170, 255),
        Danger = Color3.fromRGB(255, 60, 60),
        Success = Color3.fromRGB(60, 220, 120),
        Text = Color3.new(1, 1, 1),
        TextSecondary = Color3.fromRGB(180, 180, 190),
        DropdownBg = Color3.fromRGB(28, 28, 34),
        ItemBg = Color3.fromRGB(38, 38, 46),
    }
}

-- Поиск удалённых событий
local Remotes = {}
local remoteNames = {"Lucky Block", "Super Block", "Rainbow Block", "Galaxy Block", "Diamond Block"}
for _, name in ipairs(remoteNames) do
    local remotePath = "Spawn" .. name:gsub(" ", "")
    local remote = ReplicatedStorage:FindFirstChild(remotePath)
    if remote then
        Remotes[name] = remote
    end
end

local fallbackRemotes = {
    ["Lucky Block"] = "SpawnLuckyBlock",
    ["Super Block"] = "SpawnSuperBlock",
    ["Rainbow Block"] = "SpawnRainbowBlock",
    ["Galaxy Block"] = "SpawnGalaxyBlock",
    ["Diamond Block"] = "SpawnDiamondBlock",
}
for name, remoteName in pairs(fallbackRemotes) do
    if not Remotes[name] then
        local remote = ReplicatedStorage:FindFirstChild(remoteName)
        if remote then
            Remotes[name] = remote
        end
    end
end

if not next(Remotes) then
    Remotes["Lucky Block"] = { FireServer = function() end }
end

-- ============================================
-- СОЗДАНИЕ GUI
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name = "PremiumBlockUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

for _, child in ipairs(playerGui:GetChildren()) do
    if child.Name == "PremiumBlockUI" and child ~= gui then
        child:Destroy()
    end
end

-- ============================================
-- ФУНКЦИЯ ПЕРЕТАСКИВАНИЯ
-- ============================================
local function makeDraggable(object, dragHandle)
    local dragData = {dragging = false, startPos = nil, startMouse = nil}
    local handle = dragHandle or object
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.dragging = true
            dragData.startMouse = input.Position
            dragData.startPos = object.Position
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragData.dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragData.startMouse
                object.Position = UDim2.new(
                    dragData.startPos.X.Scale,
                    dragData.startPos.X.Offset + delta.X,
                    dragData.startPos.Y.Scale,
                    dragData.startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- ============================================
-- КНОПКА-ТОГГЛ
-- ============================================
local btnSize = CONFIG.ButtonSize

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
toggleBtn.Position = UDim2.new(0, 10 * SCALE, 0, 10 * SCALE)
toggleBtn.BackgroundColor3 = CONFIG.Colors.Accent
toggleBtn.Image = "rbxassetid://1318875241"
toggleBtn.ImageColor3 = CONFIG.Colors.Background
toggleBtn.ImageTransparency = 0.4
toggleBtn.ScaleType = Enum.ScaleType.Slice
toggleBtn.SliceCenter = Rect.new(10, 10, 10, 10)
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 100
toggleBtn.Parent = gui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, CONFIG.CornerRadius)

local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(1, 0, 0.7, 0)
icon.Position = UDim2.new(0, 0, 0.05, 0)
icon.BackgroundTransparency = 1
icon.Text = "⚡"
icon.TextColor3 = CONFIG.Colors.Text
icon.TextSize = btnSize * 0.4
icon.Font = Enum.Font.GothamBold
icon.Parent = toggleBtn

local hint = Instance.new("Frame")
hint.Size = UDim2.new(0.3, 0, 0.06, 0)
hint.Position = UDim2.new(0.35, 0, 0.9, 0)
hint.BackgroundColor3 = CONFIG.Colors.Text
hint.BackgroundTransparency = 0.7
hint.BorderSizePixel = 0
hint.Parent = toggleBtn
Instance.new("UICorner", hint).CornerRadius = UDim.new(1, 0)

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 50 * SCALE, 0, 14 * SCALE)
label.Position = UDim2.new(0, 8 * SCALE, 0, btnSize + 16 * SCALE)
label.BackgroundTransparency = 1
label.Text = "MENU"
label.TextColor3 = CONFIG.Colors.TextSecondary
label.TextSize = 8 * SCALE
label.Font = Enum.Font.GothamBold
label.Parent = gui

makeDraggable(toggleBtn, toggleBtn)

local pulseTween
local function startPulse()
    if pulseTween then pulseTween:Cancel() end
    local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    pulseTween = TweenService:Create(toggleBtn, info, {Size = UDim2.new(0, btnSize * 1.06, 0, btnSize * 1.06)})
    pulseTween:Play()
end
startPulse()

-- ============================================
-- ГЛАВНОЕ ОКНО
-- ============================================
local winW = CONFIG.WindowWidth
local winH = CONFIG.WindowHeight

local main = Instance.new("Frame")
main.Size = UDim2.new(0, winW, 0, winH)
main.Position = UDim2.new(0.5, -winW/2, 0.5, -winH/2)
main.BackgroundColor3 = CONFIG.Colors.Background
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
main.ZIndex = 50
main.Parent = gui

local bgFrame = Instance.new("Frame")
bgFrame.Size = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = CONFIG.Colors.Background
bgFrame.BackgroundTransparency = 0.05
bgFrame.BorderSizePixel = 0
bgFrame.Parent = main
Instance.new("UICorner", bgFrame).CornerRadius = UDim.new(0, CONFIG.CornerRadius)

local glassFrame = Instance.new("Frame")
glassFrame.Size = UDim2.new(1, -4, 1, -4)
glassFrame.Position = UDim2.new(0, 2, 0, 2)
glassFrame.BackgroundColor3 = CONFIG.Colors.Background
glassFrame.BackgroundTransparency = 0.3
glassFrame.BorderSizePixel = 0
glassFrame.Parent = main
Instance.new("UICorner", glassFrame).CornerRadius = UDim.new(0, CONFIG.CornerRadius - 2)

local borderFrame = Instance.new("Frame")
borderFrame.Size = UDim2.new(1, 0, 1, 0)
borderFrame.BackgroundTransparency = 0.85
borderFrame.BackgroundColor3 = CONFIG.Colors.Accent
borderFrame.BorderSizePixel = 0
borderFrame.Parent = main
Instance.new("UICorner", borderFrame).CornerRadius = UDim.new(0, CONFIG.CornerRadius)

-- ЗАГОЛОВОК
local titleContainer = Instance.new("Frame")
titleContainer.Size = UDim2.new(1, 0, 0, 38 * SCALE)
titleContainer.BackgroundColor3 = CONFIG.Colors.Accent
titleContainer.BackgroundTransparency = 0.2
titleContainer.BorderSizePixel = 0
titleContainer.Parent = main
Instance.new("UICorner", titleContainer).CornerRadius = UDim.new(0, CONFIG.CornerRadius)

local dragLine = Instance.new("Frame")
dragLine.Size = UDim2.new(0.2, 0, 0.06, 0)
dragLine.Position = UDim2.new(0.4, 0, 0.9, 0)
dragLine.BackgroundColor3 = CONFIG.Colors.Text
dragLine.BackgroundTransparency = 0.7
dragLine.BorderSizePixel = 0
dragLine.Parent = titleContainer
Instance.new("UICorner", dragLine).CornerRadius = UDim.new(1, 0)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -45 * SCALE, 1, 0)
titleText.Position = UDim2.new(0, 15 * SCALE, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "⚡ SPAWNER"
titleText.TextColor3 = CONFIG.Colors.Text
titleText.TextSize = 14 * SCALE
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleContainer

local verLabel = Instance.new("TextLabel")
verLabel.Size = UDim2.new(0, 40 * SCALE, 1, 0)
verLabel.Position = UDim2.new(1, -45 * SCALE, 0, 0)
verLabel.BackgroundTransparency = 1
verLabel.Text = "v2.7"
verLabel.TextColor3 = CONFIG.Colors.TextSecondary
verLabel.TextSize = 9 * SCALE
verLabel.Font = Enum.Font.Gotham
verLabel.Parent = titleContainer

local closeBtn = Instance.new("ImageButton")
closeBtn.Size = UDim2.new(0, 22 * SCALE, 0, 22 * SCALE)
closeBtn.Position = UDim2.new(1, -30 * SCALE, 0, 8 * SCALE)
closeBtn.BackgroundTransparency = 1
closeBtn.Image = "rbxassetid://10747352493"
closeBtn.ImageColor3 = CONFIG.Colors.TextSecondary
closeBtn.ZIndex = 60
closeBtn.Parent = titleContainer
closeBtn.MouseButton1Click:Connect(function() toggleGUI() end)
closeBtn.TouchTap:Connect(function() toggleGUI() end)

makeDraggable(main, titleContainer)

-- ============================================
-- ВЫПАДАЮЩИЙ СПИСОК
-- ============================================
local dropContainer = Instance.new("Frame")
dropContainer.Size = UDim2.new(1, -30 * SCALE, 0, 90 * SCALE)
dropContainer.Position = UDim2.new(0, 15 * SCALE, 0, 50 * SCALE)
dropContainer.BackgroundTransparency = 1
dropContainer.ClipsDescendants = true
dropContainer.Parent = main

local dropBtn = Instance.new("TextButton")
dropBtn.Size = UDim2.new(1, 0, 0, 32 * SCALE)
dropBtn.BackgroundColor3 = CONFIG.Colors.DropdownBg
dropBtn.BackgroundTransparency = 0.4
dropBtn.Text = "🔽 SELECT"
dropBtn.TextColor3 = CONFIG.Colors.Text
dropBtn.TextSize = 11 * SCALE
dropBtn.Font = Enum.Font.GothamSemibold
dropBtn.BorderSizePixel = 0
dropBtn.ZIndex = 5
dropBtn.Parent = dropContainer
Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 8)

local arrowLabel = Instance.new("TextLabel")
arrowLabel.Size = UDim2.new(0, 16 * SCALE, 1, 0)
arrowLabel.Position = UDim2.new(1, -22 * SCALE, 0, 0)
arrowLabel.BackgroundTransparency = 1
arrowLabel.Text = "▾"
arrowLabel.TextColor3 = CONFIG.Colors.TextSecondary
arrowLabel.TextSize = 12 * SCALE
arrowLabel.Font = Enum.Font.GothamBold
arrowLabel.Parent = dropBtn

local dropScroll = Instance.new("ScrollingFrame")
dropScroll.Size = UDim2.new(1, 0, 0, 0)
dropScroll.Position = UDim2.new(0, 0, 0, 36 * SCALE)
dropScroll.BackgroundColor3 = CONFIG.Colors.DropdownBg
dropScroll.BackgroundTransparency = 0.2
dropScroll.ScrollBarThickness = 2
dropScroll.ScrollBarImageColor3 = CONFIG.Colors.Accent
dropScroll.BorderSizePixel = 0
dropScroll.Visible = false
dropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
dropScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
dropScroll.ZIndex = 6
dropScroll.Parent = dropContainer
Instance.new("UICorner", dropScroll).CornerRadius = UDim.new(0, 8)

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 3 * SCALE)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = dropScroll

local function updateCanvas()
    task.wait()
    dropScroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 8 * SCALE)
end
scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

local selected = nil

for name, remote in pairs(Remotes) do
    local opt = Instance.new("TextButton")
    opt.Size = UDim2.new(1, -8 * SCALE, 0, 24 * SCALE)
    opt.Position = UDim2.new(0, 4 * SCALE, 0, 0)
    opt.BackgroundColor3 = CONFIG.Colors.ItemBg
    opt.BackgroundTransparency = 0.3
    opt.TextColor3 = CONFIG.Colors.Text
    opt.Text = name
    opt.TextSize = 10 * SCALE
    opt.Font = Enum.Font.Gotham
    opt.TextXAlignment = Enum.TextXAlignment.Left
    opt.BorderSizePixel = 0
    opt.Parent = dropScroll
    Instance.new("UICorner", opt).CornerRadius = UDim.new(0, 5)
    
    opt.MouseEnter:Connect(function()
        TweenService:Create(opt, TweenInfo.new(0.15), {BackgroundTransparency = 0}) :Play()
    end)
    opt.MouseLeave:Connect(function()
        TweenService:Create(opt, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}) :Play()
    end)
    
    opt.MouseButton1Click:Connect(function()
        selectBlock(name)
    end)
    opt.TouchTap:Connect(function()
        selectBlock(name)
    end)
end

local function selectBlock(name)
    selected = name
    dropBtn.Text = "✅ " .. name
    arrowLabel.Text = "▴"
    TweenService:Create(dropScroll, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}) :Play()
    task.wait(CONFIG.AnimationDuration)
    dropScroll.Visible = false
    arrowLabel.Text = "▾"
    expanded = false
end

local expanded = false

local function toggleDropdown()
    expanded = not expanded
    if expanded then
        dropScroll.Visible = true
        local targetHeight = math.min(scrollLayout.AbsoluteContentSize.Y + 8 * SCALE, 100 * SCALE)
        TweenService:Create(dropScroll, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)}) :Play()
        arrowLabel.Text = "▴"
    else
        TweenService:Create(dropScroll, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}) :Play()
        task.wait(CONFIG.AnimationDuration)
        dropScroll.Visible = false
        arrowLabel.Text = "▾"
    end
end

dropBtn.MouseButton1Click:Connect(toggleDropdown)
dropBtn.TouchTap:Connect(toggleDropdown)

-- ============================================
-- КНОПКА СПАВНА
-- ============================================
local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(1, -30 * SCALE, 0, 38 * SCALE)
spawnBtn.Position = UDim2.new(0, 15 * SCALE, 0, 155 * SCALE)
spawnBtn.BackgroundColor3 = CONFIG.Colors.Accent
spawnBtn.Text = "🚀 SPAWN"
spawnBtn.TextColor3 = CONFIG.Colors.Text
spawnBtn.TextSize = 13 * SCALE
spawnBtn.Font = Enum.Font.GothamBold
spawnBtn.BorderSizePixel = 0
spawnBtn.ZIndex = 5
spawnBtn.Parent = main
Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 10)

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = CONFIG.Colors.Success
progressBar.BackgroundTransparency = 0.3
progressBar.BorderSizePixel = 0
progressBar.Parent = spawnBtn
Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 10)

spawnBtn.MouseEnter:Connect(function()
    TweenService:Create(spawnBtn, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.Colors.AccentHover}) :Play()
end)
spawnBtn.MouseLeave:Connect(function()
    TweenService:Create(spawnBtn, TweenInfo.new(0.2), {BackgroundColor3 = CONFIG.Colors.Accent}) :Play()
end)

local isSpawning = false

local function spawnBlocks()
    if isSpawning then return end
    if not selected or not Remotes[selected] then
        spawnBtn.Text = "⚠️ SELECT"
        spawnBtn.BackgroundColor3 = CONFIG.Colors.Danger
        task.wait(0.8)
        spawnBtn.Text = "🚀 SPAWN"
        spawnBtn.BackgroundColor3 = CONFIG.Colors.Accent
        return
    end
    
    isSpawning = true
    spawnBtn.Text = "⏳ 0%"
    spawnBtn.BackgroundColor3 = CONFIG.Colors.AccentHover
    local total = CONFIG.SpawnCount
    
    for i = 1, total do
        pcall(function()
            if Remotes[selected] and Remotes[selected].FireServer then
                Remotes[selected]:FireServer()
            end
        end)
        local progress = i / total
        progressBar.Size = UDim2.new(progress, 0, 1, 0)
        spawnBtn.Text = "⏳ " .. math.floor(progress * 100) .. "%"
        task.wait(CONFIG.SpawnDelay)
    end
    
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    spawnBtn.Text = "✅ DONE!"
    spawnBtn.BackgroundColor3 = CONFIG.Colors.Success
    task.wait(0.6)
    spawnBtn.Text = "🚀 SPAWN"
    spawnBtn.BackgroundColor3 = CONFIG.Colors.Accent
    TweenService:Create(progressBar, TweenInfo.new(0.4), {Size = UDim2.new(0, 0, 1, 0)}) :Play()
    isSpawning = false
end

spawnBtn.MouseButton1Click:Connect(spawnBlocks)
spawnBtn.TouchTap:Connect(spawnBlocks)

-- ============================================
-- ИНФО-ПАНЕЛЬ
-- ============================================
local infoPanel = Instance.new("Frame")
infoPanel.Size = UDim2.new(1, -30 * SCALE, 0, 24 * SCALE)
infoPanel.Position = UDim2.new(0, 15 * SCALE, 0, 203 * SCALE)
infoPanel.BackgroundTransparency = 1
infoPanel.Parent = main

local countText = Instance.new("TextLabel")
countText.Size = UDim2.new(0.5, -5 * SCALE, 1, 0)
countText.Position = UDim2.new(0, 0, 0, 0)
countText.BackgroundTransparency = 1
countText.Text = "COUNT: " .. CONFIG.SpawnCount
countText.TextColor3 = CONFIG.Colors.TextSecondary
countText.TextSize = 10 * SCALE
countText.Font = Enum.Font.Gotham
countText.TextXAlignment = Enum.TextXAlignment.Left
countText.Parent = infoPanel

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(0.5, -5 * SCALE, 1, 0)
statusText.Position = UDim2.new(0.5, 5 * SCALE, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "READY"
statusText.TextColor3 = CONFIG.Colors.Success
statusText.TextSize = 10 * SCALE
statusText.Font = Enum.Font.Gotham
statusText.TextXAlignment = Enum.TextXAlignment.Right
statusText.Parent = infoPanel

local hotkeyInfo = Instance.new("TextLabel")
hotkeyInfo.Size = UDim2.new(1, 0, 0, 16 * SCALE)
hotkeyInfo.Position = UDim2.new(0, 0, 0, 236 * SCALE)
hotkeyInfo.BackgroundTransparency = 1
if isMobile then
    hotkeyInfo.Text = "Tap ⚡ to toggle"
else
    hotkeyInfo.Text = "INSERT to toggle"
end
hotkeyInfo.TextColor3 = CONFIG.Colors.TextSecondary
hotkeyInfo.TextSize = 8 * SCALE
hotkeyInfo.Font = Enum.Font.Gotham
hotkeyInfo.Parent = main

-- ============================================
-- ЛОГИКА ОТКРЫТИЯ/ЗАКРЫТИЯ (ФИКС АВТОЗАКРЫТИЯ)
-- ============================================
local guiVisible = false
local isAnimating = false

function toggleGUI()
    if isAnimating then return end
    isAnimating = true
    
    guiVisible = not guiVisible
    
    if guiVisible then
        main.Visible = true
        main.BackgroundTransparency = 0
        main.Size = UDim2.new(0, winW, 0, winH)
        TweenService:Create(main, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {BackgroundTransparency = 0}) :Play()
        toggleBtn.BackgroundColor3 = CONFIG.Colors.Danger
        icon.Text = "✕"
        if pulseTween then pulseTween:Cancel() end
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, btnSize, 0, btnSize)}) :Play()
    else
        TweenService:Create(main, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
            {BackgroundTransparency = 1}) :Play()
        task.wait(CONFIG.AnimationDuration)
        main.Visible = false
        main.BackgroundTransparency = 1
        toggleBtn.BackgroundColor3 = CONFIG.Colors.Accent
        icon.Text = "⚡"
        startPulse()
        if expanded then
            expanded = false
            dropScroll.Visible = false
            dropScroll.Size = UDim2.new(1, 0, 0, 0)
            arrowLabel.Text = "▾"
        end
    end
    
    isAnimating = false
end

-- ОСНОВНЫЕ КНОПКИ
toggleBtn.MouseButton1Click:Connect(toggleGUI)
toggleBtn.TouchTap:Connect(toggleGUI)

-- ГОРЯЧАЯ КЛАВИША (ПК)
if not isMobile then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == CONFIG.ToggleKey then
            toggleGUI()
        end
    end)
end

-- ЗАЩИТА ОТ СЛУЧАЙНОГО ЗАКРЫТИЯ ПРИ КАСАНИИ ВНЕ ОКНА
-- НЕ ДОБАВЛЯЕМ НИКАКИХ ОБРАБОТЧИКОВ, КОТОРЫЕ ЗАКРЫВАЮТ GUI

print("✅ Premium Block Spawner v2.7 loaded. UI will NOT auto-close.")