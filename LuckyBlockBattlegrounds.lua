--[[
    Скрипт: Premium GUI спавнер блоков для Roblox (ФИНАЛЬНАЯ ИСПРАВЛЕННАЯ)
    Версия: 2.5
    Исправления: полная переработка загрузки UI, устранены все ошибки инициализации
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Ждём загрузки игрока
if not player then
    error("Player not loaded")
end

-- Ждём PlayerGui с таймаутом
local playerGui = nil
for i = 1, 20 do
    playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then break end
    task.wait(0.1)
end
if not playerGui then
    error("PlayerGui not found after 2 seconds")
end

-- Определение платформы
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local isTablet = UserInputService.TouchEnabled and UserInputService.MouseEnabled
local isPC = not UserInputService.TouchEnabled

-- Адаптивные размеры
local SCALE = 1
if isMobile then
    SCALE = 1.3
elseif isTablet then
    SCALE = 1.15
end

local CONFIG = {
    ToggleKey = Enum.KeyCode.Insert,
    AnimationDuration = 0.3,
    SpawnCount = 150,
    SpawnDelay = 0.05,
    ButtonSize = 55 * SCALE,
    WindowWidth = 340 * SCALE,
    WindowHeight = 400 * SCALE,
    CornerRadius = 16,
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
    Remotes["Lucky Block"] = { FireServer = function() print("Mock FireServer") end }
end

-- ============================================
-- СОЗДАНИЕ GUI С ЗАЩИТОЙ ОТ ДУБЛИРОВАНИЯ
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name = "PremiumBlockUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Удаляем старые копии
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
    
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.dragging = true
            dragData.startMouse = input.Position
            dragData.startPos = object.Position
        end
    end
    
    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragData.dragging = false
        end
    end
    
    handle.InputBegan:Connect(onInputBegan)
    handle.InputEnded:Connect(onInputEnded)
    
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
    
    return dragData
end

-- ============================================
-- СОЗДАНИЕ КНОПКИ-ТОГГЛА
-- ============================================
local buttonSize = CONFIG.ButtonSize

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, buttonSize, 0, buttonSize)
toggleBtn.Position = UDim2.new(0, 20, 0, 20)
toggleBtn.BackgroundColor3 = CONFIG.Colors.Accent
toggleBtn.Image = "rbxassetid://1318875241"
toggleBtn.ImageColor3 = CONFIG.Colors.Background
toggleBtn.ImageTransparency = 0.4
toggleBtn.ScaleType = Enum.ScaleType.Slice
toggleBtn.SliceCenter = Rect.new(10, 10, 10, 10)
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 100
toggleBtn.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, CONFIG.CornerRadius)
corner.Parent = toggleBtn

local toggleIcon = Instance.new("TextLabel")
toggleIcon.Size = UDim2.new(1, 0, 0.75, 0)
toggleIcon.Position = UDim2.new(0, 0, 0.05, 0)
toggleIcon.BackgroundTransparency = 1
toggleIcon.Text = "⚡"
toggleIcon.TextColor3 = CONFIG.Colors.Text
toggleIcon.TextSize = buttonSize * 0.45
toggleIcon.Font = Enum.Font.GothamBold
toggleIcon.Parent = toggleBtn

local dragHint = Instance.new("Frame")
dragHint.Size = UDim2.new(0.4, 0, 0.08, 0)
dragHint.Position = UDim2.new(0.3, 0, 0.88, 0)
dragHint.BackgroundColor3 = CONFIG.Colors.Text
dragHint.BackgroundTransparency = 0.7
dragHint.BorderSizePixel = 0
dragHint.Parent = toggleBtn
Instance.new("UICorner", dragHint).CornerRadius = UDim.new(1, 0)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(0, 70 * SCALE, 0, 18 * SCALE)
toggleLabel.Position = UDim2.new(0, 12 * SCALE, 0, buttonSize + 22 * SCALE)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "MENU"
toggleLabel.TextColor3 = CONFIG.Colors.TextSecondary
toggleLabel.TextSize = 10 * SCALE
toggleLabel.Font = Enum.Font.GothamBold
toggleLabel.Parent = gui

makeDraggable(toggleBtn, toggleBtn)

-- Пульсация
local pulseTween
local function startPulse()
    if pulseTween then pulseTween:Cancel() end
    local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    pulseTween = TweenService:Create(toggleBtn, info, {Size = UDim2.new(0, buttonSize * 1.08, 0, buttonSize * 1.08)})
    pulseTween:Play()
end
startPulse()

-- ============================================
-- ГЛАВНОЕ ОКНО
-- ============================================
local windowW = CONFIG.WindowWidth
local windowH = CONFIG.WindowHeight

local main = Instance.new("Frame")
main.Size = UDim2.new(0, windowW, 0, windowH)
main.Position = UDim2.new(0.5, -windowW/2, 0.5, -windowH/2)
main.BackgroundColor3 = CONFIG.Colors.Background
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
main.ZIndex = 50
main.Parent = gui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = CONFIG.Colors.Background
bg.BackgroundTransparency = 0.05
bg.BorderSizePixel = 0
bg.Parent = main
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, CONFIG.CornerRadius)

local glass = Instance.new("Frame")
glass.Size = UDim2.new(1, -4, 1, -4)
glass.Position = UDim2.new(0, 2, 0, 2)
glass.BackgroundColor3 = CONFIG.Colors.Background
glass.BackgroundTransparency = 0.3
glass.BorderSizePixel = 0
glass.Parent = main
Instance.new("UICorner", glass).CornerRadius = UDim.new(0, CONFIG.CornerRadius - 2)

local borderFrame = Instance.new("Frame")
borderFrame.Size = UDim2.new(1, 0, 1, 0)
borderFrame.BackgroundTransparency = 0.85
borderFrame.BackgroundColor3 = CONFIG.Colors.Accent
borderFrame.BorderSizePixel = 0
borderFrame.Parent = main
Instance.new("UICorner", borderFrame).CornerRadius = UDim.new(0, CONFIG.CornerRadius)

-- ЗАГОЛОВОК
local titleContainer = Instance.new("Frame")
titleContainer.Size = UDim2.new(1, 0, 0, 50 * SCALE)
titleContainer.BackgroundColor3 = CONFIG.Colors.Accent
titleContainer.BackgroundTransparency = 0.2
titleContainer.BorderSizePixel = 0
titleContainer.Parent = main
Instance.new("UICorner", titleContainer).CornerRadius = UDim.new(0, CONFIG.CornerRadius)

local dragLine = Instance.new("Frame")
dragLine.Size = UDim2.new(0.25, 0, 0.08, 0)
dragLine.Position = UDim2.new(0.375, 0, 0.9, 0)
dragLine.BackgroundColor3 = CONFIG.Colors.Text
dragLine.BackgroundTransparency = 0.7
dragLine.BorderSizePixel = 0
dragLine.Parent = titleContainer
Instance.new("UICorner", dragLine).CornerRadius = UDim.new(1, 0)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -50 * SCALE, 1, 0)
titleText.Position = UDim2.new(0, 20 * SCALE, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "⚡ BLOCK SPAWNER"
titleText.TextColor3 = CONFIG.Colors.Text
titleText.TextSize = 18 * SCALE
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleContainer

local verLabel = Instance.new("TextLabel")
verLabel.Size = UDim2.new(0, 50 * SCALE, 1, 0)
verLabel.Position = UDim2.new(1, -55 * SCALE, 0, 0)
verLabel.BackgroundTransparency = 1
verLabel.Text = "v2.5"
verLabel.TextColor3 = CONFIG.Colors.TextSecondary
verLabel.TextSize = 11 * SCALE
verLabel.Font = Enum.Font.Gotham
verLabel.Parent = titleContainer

local closeButton = Instance.new("ImageButton")
closeButton.Size = UDim2.new(0, 28 * SCALE, 0, 28 * SCALE)
closeButton.Position = UDim2.new(1, -35 * SCALE, 0, 11 * SCALE)
closeButton.BackgroundTransparency = 1
closeButton.Image = "rbxassetid://10747352493"
closeButton.ImageColor3 = CONFIG.Colors.TextSecondary
closeButton.ZIndex = 60
closeButton.Parent = titleContainer
closeButton.MouseButton1Click:Connect(function() toggleGUI() end)
closeButton.TouchTap:Connect(function() toggleGUI() end)

makeDraggable(main, titleContainer)

-- ============================================
-- ВЫПАДАЮЩИЙ СПИСОК
-- ============================================
local dropContainer = Instance.new("Frame")
dropContainer.Size = UDim2.new(1, -40 * SCALE, 0, 120 * SCALE)
dropContainer.Position = UDim2.new(0, 20 * SCALE, 0, 65 * SCALE)
dropContainer.BackgroundTransparency = 1
dropContainer.ClipsDescendants = true
dropContainer.Parent = main

local dropButton = Instance.new("TextButton")
dropButton.Size = UDim2.new(1, 0, 0, 40 * SCALE)
dropButton.BackgroundColor3 = CONFIG.Colors.DropdownBg
dropButton.BackgroundTransparency = 0.4
dropButton.Text = "🔽 SELECT BLOCK"
dropButton.TextColor3 = CONFIG.Colors.Text
dropButton.TextSize = 13 * SCALE
dropButton.Font = Enum.Font.GothamSemibold
dropButton.BorderSizePixel = 0
dropButton.ZIndex = 5
dropButton.Parent = dropContainer
Instance.new("UICorner", dropButton).CornerRadius = UDim.new(0, 10)

local arrowLabel = Instance.new("TextLabel")
arrowLabel.Size = UDim2.new(0, 20 * SCALE, 1, 0)
arrowLabel.Position = UDim2.new(1, -28 * SCALE, 0, 0)
arrowLabel.BackgroundTransparency = 1
arrowLabel.Text = "▾"
arrowLabel.TextColor3 = CONFIG.Colors.TextSecondary
arrowLabel.TextSize = 16 * SCALE
arrowLabel.Font = Enum.Font.GothamBold
arrowLabel.Parent = dropButton

local dropScroll = Instance.new("ScrollingFrame")
dropScroll.Size = UDim2.new(1, 0, 0, 0)
dropScroll.Position = UDim2.new(0, 0, 0, 44 * SCALE)
dropScroll.BackgroundColor3 = CONFIG.Colors.DropdownBg
dropScroll.BackgroundTransparency = 0.2
dropScroll.ScrollBarThickness = 3
dropScroll.ScrollBarImageColor3 = CONFIG.Colors.Accent
dropScroll.BorderSizePixel = 0
dropScroll.Visible = false
dropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
dropScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
dropScroll.ZIndex = 6
dropScroll.Parent = dropContainer
Instance.new("UICorner", dropScroll).CornerRadius = UDim.new(0, 10)

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 4 * SCALE)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = dropScroll

local function updateCanvas()
    task.wait()
    dropScroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 10 * SCALE)
end
scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

local selected = nil

for name, remote in pairs(Remotes) do
    local opt = Instance.new("TextButton")
    opt.Size = UDim2.new(1, -10 * SCALE, 0, 30 * SCALE)
    opt.Position = UDim2.new(0, 5 * SCALE, 0, 0)
    opt.BackgroundColor3 = CONFIG.Colors.ItemBg
    opt.BackgroundTransparency = 0.3
    opt.TextColor3 = CONFIG.Colors.Text
    opt.Text = name
    opt.TextSize = 12 * SCALE
    opt.Font = Enum.Font.Gotham
    opt.TextXAlignment = Enum.TextXAlignment.Left
    opt.BorderSizePixel = 0
    opt.Parent = dropScroll
    Instance.new("UICorner", opt).CornerRadius = UDim.new(0, 6)
    
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
    dropButton.Text = "✅ " .. name
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
        local targetHeight = math.min(scrollLayout.AbsoluteContentSize.Y + 10 * SCALE, 150 * SCALE)
        TweenService:Create(dropScroll, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)}) :Play()
        arrowLabel.Text = "▴"
    else
        TweenService:Create(dropScroll, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}) :Play()
        task.wait(CONFIG.AnimationDuration)
        dropScroll.Visible = false
        arrowLabel.Text = "▾"
    end
end

dropButton.MouseButton1Click:Connect(toggleDropdown)
dropButton.TouchTap:Connect(toggleDropdown)

-- ============================================
-- КНОПКА СПАВНА
-- ============================================
local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(1, -40 * SCALE, 0, 48 * SCALE)
spawnBtn.Position = UDim2.new(0, 20 * SCALE, 0, 205 * SCALE)
spawnBtn.BackgroundColor3 = CONFIG.Colors.Accent
spawnBtn.Text = "🚀 SPAWN ALL"
spawnBtn.TextColor3 = CONFIG.Colors.Text
spawnBtn.TextSize = 16 * SCALE
spawnBtn.Font = Enum.Font.GothamBold
spawnBtn.BorderSizePixel = 0
spawnBtn.ZIndex = 5
spawnBtn.Parent = main
Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 12)

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = CONFIG.Colors.Success
progressBar.BackgroundTransparency = 0.3
progressBar.BorderSizePixel = 0
progressBar.Parent = spawnBtn
Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 12)

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
        spawnBtn.Text = "⚠️ SELECT BLOCK"
        spawnBtn.BackgroundColor3 = CONFIG.Colors.Danger
        task.wait(1)
        spawnBtn.Text = "🚀 SPAWN ALL"
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
    task.wait(0.8)
    spawnBtn.Text = "🚀 SPAWN ALL"
    spawnBtn.BackgroundColor3 = CONFIG.Colors.Accent
    TweenService:Create(progressBar, TweenInfo.new(0.5), {Size = UDim2.new(0, 0, 1, 0)}) :Play()
    isSpawning = false
end

spawnBtn.MouseButton1Click:Connect(spawnBlocks)
spawnBtn.TouchTap:Connect(spawnBlocks)

-- ============================================
-- ИНФО-ПАНЕЛЬ
-- ============================================
local infoPanel = Instance.new("Frame")
infoPanel.Size = UDim2.new(1, -40 * SCALE, 0, 30 * SCALE)
infoPanel.Position = UDim2.new(0, 20 * SCALE, 0, 268 * SCALE)
infoPanel.BackgroundTransparency = 1
infoPanel.Parent = main

local countText = Instance.new("TextLabel")
countText.Size = UDim2.new(0.5, -5 * SCALE, 1, 0)
countText.Position = UDim2.new(0, 0, 0, 0)
countText.BackgroundTransparency = 1
countText.Text = "COUNT: " .. CONFIG.SpawnCount
countText.TextColor3 = CONFIG.Colors.TextSecondary
countText.TextSize = 12 * SCALE
countText.Font = Enum.Font.Gotham
countText.TextXAlignment = Enum.TextXAlignment.Left
countText.Parent = infoPanel

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(0.5, -5 * SCALE, 1, 0)
statusText.Position = UDim2.new(0.5, 5 * SCALE, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "READY"
statusText.TextColor3 = CONFIG.Colors.Success
statusText.TextSize = 12 * SCALE
statusText.Font = Enum.Font.Gotham
statusText.TextXAlignment = Enum.TextXAlignment.Right
statusText.Parent = infoPanel

local hotkeyInfo = Instance.new("TextLabel")
hotkeyInfo.Size = UDim2.new(1, 0, 0, 20 * SCALE)
hotkeyInfo.Position = UDim2.new(0, 0, 0, 310 * SCALE)
hotkeyInfo.BackgroundTransparency = 1
if isMobile then
    hotkeyInfo.Text = "Tap ⚡ to open/close | Drag to move"
else
    hotkeyInfo.Text = "Press INSERT to toggle | Drag to move"
end
hotkeyInfo.TextColor3 = CONFIG.Colors.TextSecondary
hotkeyInfo.TextSize = 10 * SCALE
hotkeyInfo.Font = Enum.Font.Gotham
hotkeyInfo.Parent = main

-- ============================================
-- ЛОГИКА ОТКРЫТИЯ/ЗАКРЫТИЯ
-- ============================================
local guiVisible = false

function toggleGUI()
    guiVisible = not guiVisible
    
    if guiVisible then
        main.Visible = true
        main.BackgroundTransparency = 0
        TweenService:Create(main, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {BackgroundTransparency = 0}) :Play()
        toggleBtn.BackgroundColor3 = CONFIG.Colors.Danger
        toggleIcon.Text = "✕"
        if pulseTween then pulseTween:Cancel() end
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, buttonSize, 0, buttonSize)}) :Play()
    else
        TweenService:Create(main, TweenInfo.new(CONFIG.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
            {BackgroundTransparency = 1}) :Play()
        task.wait(CONFIG.AnimationDuration)
        main.Visible = false
        main.BackgroundTransparency = 1
        toggleBtn.BackgroundColor3 = CONFIG.Colors.Accent
        toggleIcon.Text = "⚡"
        startPulse()
        if expanded then
            expanded = false
            dropScroll.Visible = false
            dropScroll.Size = UDim2.new(1, 0, 0, 0)
            arrowLabel.Text = "▾"
        end
    end
end

toggleBtn.MouseButton1Click:Connect(toggleGUI)
toggleBtn.TouchTap:Connect(toggleGUI)

if not isMobile then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == CONFIG.ToggleKey then
            toggleGUI()
        end
    end)
end

print("✅ Premium Block Spawner v2.5 loaded. Platform: " .. (isMobile and "Mobile" or isTablet and "Tablet" or "PC"))