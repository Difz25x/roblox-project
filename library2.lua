local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Lonum = {}
Lonum.__index = Lonum

--=========================================
-- THEME & SETTINGS
--=========================================
Lonum.Theme = {
    MainBackground = Color3.fromRGB(20, 20, 25),
    SidebarBackground = Color3.fromRGB(15, 15, 20),
    ElementBackground = Color3.fromRGB(30, 30, 35),
    Accent = Color3.fromRGB(85, 120, 255),
    TextTitle = Color3.fromRGB(255, 255, 255),
    TextNormal = Color3.fromRGB(200, 200, 200),
    TextDim = Color3.fromRGB(150, 150, 150),
    CornerRadius = UDim.new(0, 6)
}

-- Config System Globals
local configData = {}
local currentConfigFolder = "Lonum_Data"
local currentConfigFile = "default_config.json"

--=========================================
-- UTILITIES
--=========================================
local function MakeDraggable(topBar, targetFrame)
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        targetFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Config Handling
function Lonum:SaveConfig()
    if writefile and HttpService then
        local success, encoded = pcall(function()
            return HttpService:JSONEncode(configData)
        end)
        if success then
            if not isfolder(currentConfigFolder) and makefolder then
                makefolder(currentConfigFolder)
            end
            pcall(function()
                writefile(currentConfigFolder .. "/" .. currentConfigFile, encoded)
            end)
        end
    end
end

function Lonum:LoadConfig()
    if readfile and isfile and isfile(currentConfigFolder .. "/" .. currentConfigFile) then
        local success, decoded = pcall(function()
            local content = readfile(currentConfigFolder .. "/" .. currentConfigFile)
            return HttpService:JSONDecode(content)
        end)
        if success and decoded then
            configData = decoded
        end
    end
end

--=========================================
-- WINDOW CREATION
--=========================================
function Lonum:CreateWindow(options)
    options = options or {}
    local Title = options.Name or "Lonum Library"
    local Subtitle = options.Subtitle or "Made for Exploits"

    if options.ConfigurationSaving then
        currentConfigFolder = options.ConfigurationSaving.FolderName or "Lonum_Data"
        currentConfigFile = (options.ConfigurationSaving.FileName or "config") .. ".json"
        self:LoadConfig()
    end

    -- Protect GUI
    local targetParent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
    -- Optional fallback to PlayerGui if CoreGui is restricted
    pcall(function()
        if not targetParent or not targetParent:FindFirstChild("RobloxGui") then
            targetParent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        end
    end)

    -- Destroy old instance if exists
    for _, gui in pairs(targetParent:GetChildren()) do
        if gui.Name == "LonumMainGui" then gui:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LonumMainGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = targetParent

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = self.Theme.MainBackground
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = self.Theme.CornerRadius
    MainCorner.Parent = MainFrame

    -- SIDEBAR
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = self.Theme.SidebarBackground
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = self.Theme.CornerRadius
    SidebarCorner.Parent = Sidebar

    -- Hide right corner of sidebar to blend with MainFrame
    local SidebarHideCorner = Instance.new("Frame")
    SidebarHideCorner.Size = UDim2.new(0, 10, 1, 0)
    SidebarHideCorner.Position = UDim2.new(1, -10, 0, 0)
    SidebarHideCorner.BackgroundColor3 = self.Theme.SidebarBackground
    SidebarHideCorner.BorderSizePixel = 0
    SidebarHideCorner.Parent = Sidebar

    MakeDraggable(Sidebar, MainFrame)

    -- TITLE
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 30)
    TitleLabel.Position = UDim2.new(0, 10, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = self.Theme.Accent
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Sidebar

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -20, 0, 15)
    SubLabel.Position = UDim2.new(0, 10, 0, 35)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = Subtitle
    SubLabel.TextColor3 = self.Theme.TextDim
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextSize = 11
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = Sidebar

    local SidebarLine = Instance.new("Frame")
    SidebarLine.Size = UDim2.new(1, -20, 0, 1)
    SidebarLine.Position = UDim2.new(0, 10, 0, 60)
    SidebarLine.BackgroundColor3 = self.Theme.ElementBackground
    SidebarLine.BorderSizePixel = 0
    SidebarLine.Parent = Sidebar

    -- TAB CONTAINER IN SIDEBAR
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 1, -70)
    TabContainer.Position = UDim2.new(0, 0, 0, 70)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.Parent = TabContainer

    -- CONTENT AREA (RIGHT SIDE)
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -170, 1, -20)
    ContentArea.Position = UDim2.new(0, 160, 0, 10)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    local WindowObj = {
        CurrentTab = nil,
        Tabs = {}
    }

    --=========================================
    -- TAB CREATION
    --=========================================
    function WindowObj:CreateTab(tabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName
        TabButton.Size = UDim2.new(1, -20, 0, 35)
        TabButton.BackgroundColor3 = Lonum.Theme.ElementBackground
        TabButton.BackgroundTransparency = 1
        TabButton.Text = tabName
        TabButton.TextColor3 = Lonum.Theme.TextDim
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 13
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabContainer

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = Lonum.Theme.CornerRadius
        TabBtnCorner.Parent = TabButton

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = tabName.."_Page"
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 2
        TabPage.ScrollBarImageColor3 = Lonum.Theme.ElementBackground
        TabPage.Visible = false
        TabPage.Parent = ContentArea

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = TabPage

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 5)
        PagePadding.PaddingBottom = UDim.new(0, 5)
        PagePadding.PaddingRight = UDim.new(0, 10)
        PagePadding.Parent = TabPage

        -- Auto resize canvas
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(self.Tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.3), {
                    TextColor3 = Lonum.Theme.TextDim,
                    BackgroundTransparency = 1
                }):Play()
            end

            TabPage.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.3), {
                TextColor3 = Lonum.Theme.TextTitle,
                BackgroundTransparency = 0.5
            }):Play()

            self.CurrentTab = tabName
        end)

        local TabObj = {
            Button = TabButton,
            Page = TabPage
        }
        table.insert(self.Tabs, TabObj)

        -- If first tab, make it active
        if #self.Tabs == 1 then
            TabPage.Visible = true
            TabButton.TextColor3 = Lonum.Theme.TextTitle
            TabButton.BackgroundTransparency = 0.5
            self.CurrentTab = tabName
        end

        -- ELEMENTS BUILDER
        function TabObj:CreateSection(name)
            local SecLabel = Instance.new("TextLabel")
            SecLabel.Size = UDim2.new(1, 0, 0, 20)
            SecLabel.BackgroundTransparency = 1
            SecLabel.Text = name
            SecLabel.TextColor3 = Lonum.Theme.Accent
            SecLabel.Font = Enum.Font.GothamBold
            SecLabel.TextSize = 14
            SecLabel.TextXAlignment = Enum.TextXAlignment.Left
            SecLabel.Parent = TabPage
        end

        function TabObj:CreateLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 25)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Lonum.Theme.TextNormal
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = TabPage

            local LabelObj = {}
            function LabelObj:Set(newText)
                lbl.Text = newText
            end
            return LabelObj
        end

        function TabObj:CreateParagraph(options)
            local pFrame = Instance.new("Frame")
            pFrame.Size = UDim2.new(1, 0, 0, 50)
            pFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            pFrame.Parent = TabPage

            local pCorner = Instance.new("UICorner")
            pCorner.CornerRadius = Lonum.Theme.CornerRadius
            pCorner.Parent = pFrame

            local pTitle = Instance.new("TextLabel")
            pTitle.Size = UDim2.new(1, -20, 0, 20)
            pTitle.Position = UDim2.new(0, 10, 0, 5)
            pTitle.BackgroundTransparency = 1
            pTitle.Text = options.Title or ""
            pTitle.TextColor3 = Lonum.Theme.TextTitle
            pTitle.Font = Enum.Font.GothamBold
            pTitle.TextSize = 13
            pTitle.TextXAlignment = Enum.TextXAlignment.Left
            pTitle.Parent = pFrame

            local pContent = Instance.new("TextLabel")
            pContent.Size = UDim2.new(1, -20, 0, 20)
            pContent.Position = UDim2.new(0, 10, 0, 25)
            pContent.BackgroundTransparency = 1
            pContent.Text = options.Content or ""
            pContent.TextColor3 = Lonum.Theme.TextDim
            pContent.Font = Enum.Font.Gotham
            pContent.TextSize = 12
            pContent.TextXAlignment = Enum.TextXAlignment.Left
            pContent.Parent = pFrame

            local PObj = {}
            function PObj:Set(newOpts)
                if newOpts.Title then pTitle.Text = newOpts.Title end
                if newOpts.Content then pContent.Text = newOpts.Content end
            end
            return PObj
        end

        function TabObj:CreateButton(options)
            local btnFrame = Instance.new("Frame")
            btnFrame.Size = UDim2.new(1, 0, 0, 35)
            btnFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            btnFrame.Parent = TabPage

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = Lonum.Theme.CornerRadius
            btnCorner.Parent = btnFrame

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = options.Name or "Button"
            btn.TextColor3 = Lonum.Theme.TextTitle
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 13
            btn.Parent = btnFrame

            btn.MouseEnter:Connect(function()
                TweenService:Create(btnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Lonum.Theme.Accent}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Lonum.Theme.ElementBackground}):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                -- Bounce animation
                TweenService:Create(btnFrame, TweenInfo.new(0.1), {Size = UDim2.new(0.98, 0, 0, 32)}):Play()
                task.wait(0.1)
                TweenService:Create(btnFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                if options.Callback then options.Callback() end
            end)
        end

        function TabObj:CreateToggle(options)
            local flag = options.Flag or options.Name
            local defaultVal = options.CurrentValue or false

            -- Check Config
            if configData[flag] ~= nil then
                defaultVal = configData[flag]
            end

            local tFrame = Instance.new("TextButton")
            tFrame.Size = UDim2.new(1, 0, 0, 35)
            tFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            tFrame.Text = ""
            tFrame.AutoButtonColor = false
            tFrame.Parent = TabPage

            local tCorner = Instance.new("UICorner")
            tCorner.CornerRadius = Lonum.Theme.CornerRadius
            tCorner.Parent = tFrame

            local tLabel = Instance.new("TextLabel")
            tLabel.Size = UDim2.new(1, -60, 1, 0)
            tLabel.Position = UDim2.new(0, 10, 0, 0)
            tLabel.BackgroundTransparency = 1
            tLabel.Text = options.Name or "Toggle"
            tLabel.TextColor3 = Lonum.Theme.TextNormal
            tLabel.Font = Enum.Font.Gotham
            tLabel.TextSize = 13
            tLabel.TextXAlignment = Enum.TextXAlignment.Left
            tLabel.Parent = tFrame

            local tBox = Instance.new("Frame")
            tBox.Size = UDim2.new(0, 40, 0, 20)
            tBox.Position = UDim2.new(1, -50, 0.5, -10)
            tBox.BackgroundColor3 = defaultVal and Lonum.Theme.Accent or Color3.fromRGB(50, 50, 55)
            tBox.Parent = tFrame

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(1, 0)
            boxCorner.Parent = tBox

            local tCircle = Instance.new("Frame")
            tCircle.Size = UDim2.new(0, 16, 0, 16)
            tCircle.Position = defaultVal and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            tCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            tCircle.Parent = tBox

            local circleCorner = Instance.new("UICorner")
            circleCorner.CornerRadius = UDim.new(1, 0)
            circleCorner.Parent = tCircle

            local State = defaultVal

            local function Fire()
                if options.Callback then options.Callback(State) end
                configData[flag] = State
                Lonum:SaveConfig()
            end

            -- Fire initial state securely without crashing if callback is slow
            task.spawn(Fire)

            tFrame.MouseButton1Click:Connect(function()
                State = not State
                TweenService:Create(tBox, TweenInfo.new(0.2), {
                    BackgroundColor3 = State and Lonum.Theme.Accent or Color3.fromRGB(50, 50, 55)
                }):Play()
                TweenService:Create(tCircle, TweenInfo.new(0.2), {
                    Position = State and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                }):Play()
                Fire()
            end)

            local TogObj = {}
            function TogObj:Set(newVal)
                if State == newVal then return end
                State = newVal
                TweenService:Create(tBox, TweenInfo.new(0.2), {
                    BackgroundColor3 = State and Lonum.Theme.Accent or Color3.fromRGB(50, 50, 55)
                }):Play()
                TweenService:Create(tCircle, TweenInfo.new(0.2), {
                    Position = State and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                }):Play()
                Fire()
            end
            return TogObj
        end

        function TabObj:CreateSlider(options)
            local flag = options.Flag or options.Name
            local min = options.Range and options.Range[1] or 0
            local max = options.Range and options.Range[2] or 100
            local inc = options.Increment or 1
            local defaultVal = options.CurrentValue or min

            if configData[flag] ~= nil then
                defaultVal = configData[flag]
            end
            defaultVal = math.clamp(defaultVal, min, max)

            local sFrame = Instance.new("Frame")
            sFrame.Size = UDim2.new(1, 0, 0, 50)
            sFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            sFrame.Parent = TabPage

            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = Lonum.Theme.CornerRadius
            sCorner.Parent = sFrame

            local sLabel = Instance.new("TextLabel")
            sLabel.Size = UDim2.new(1, -20, 0, 20)
            sLabel.Position = UDim2.new(0, 10, 0, 5)
            sLabel.BackgroundTransparency = 1
            sLabel.Text = options.Name or "Slider"
            sLabel.TextColor3 = Lonum.Theme.TextNormal
            sLabel.Font = Enum.Font.Gotham
            sLabel.TextSize = 13
            sLabel.TextXAlignment = Enum.TextXAlignment.Left
            sLabel.Parent = sFrame

            local sValLabel = Instance.new("TextLabel")
            sValLabel.Size = UDim2.new(0, 50, 0, 20)
            sValLabel.Position = UDim2.new(1, -60, 0, 5)
            sValLabel.BackgroundTransparency = 1
            sValLabel.Text = tostring(defaultVal)
            sValLabel.TextColor3 = Lonum.Theme.Accent
            sValLabel.Font = Enum.Font.GothamBold
            sValLabel.TextSize = 13
            sValLabel.TextXAlignment = Enum.TextXAlignment.Right
            sValLabel.Parent = sFrame

            local sBarArea = Instance.new("TextButton")
            sBarArea.Size = UDim2.new(1, -20, 0, 6)
            sBarArea.Position = UDim2.new(0, 10, 0, 32)
            sBarArea.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            sBarArea.AutoButtonColor = false
            sBarArea.Text = ""
            sBarArea.Parent = sFrame

            local barAreaCorner = Instance.new("UICorner")
            barAreaCorner.CornerRadius = UDim.new(1, 0)
            barAreaCorner.Parent = sBarArea

            local sFill = Instance.new("Frame")
            local startPct = (defaultVal - min) / (max - min)
            sFill.Size = UDim2.new(startPct, 0, 1, 0)
            sFill.BackgroundColor3 = Lonum.Theme.Accent
            sFill.Parent = sBarArea

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = sFill

            local Value = defaultVal

            local function Fire()
                sValLabel.Text = tostring(Value)
                if options.Callback then options.Callback(Value) end
                configData[flag] = Value
                Lonum:SaveConfig()
            end
            task.spawn(Fire)

            local dragging = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - sBarArea.AbsolutePosition.X) / sBarArea.AbsoluteSize.X, 0, 1)
                local rawValue = min + (pos * (max - min))
                Value = math.floor(rawValue / inc + 0.5) * inc
                Value = math.clamp(Value, min, max)

                local pct = (Value - min) / (max - min)
                TweenService:Create(sFill, TweenInfo.new(0.05), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                Fire()
            end

            sBarArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
        end

        function TabObj:CreateDropdown(options)
            -- Simplified Dropdown fallback (using multiple buttons for stability in lightweight lib)
            local dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(1, 0, 0, 35)
            dropFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            dropFrame.ClipsDescendants = true
            dropFrame.Parent = TabPage

            local dropCorner = Instance.new("UICorner")
            dropCorner.CornerRadius = Lonum.Theme.CornerRadius
            dropCorner.Parent = dropFrame

            local dropBtn = Instance.new("TextButton")
            dropBtn.Size = UDim2.new(1, 0, 0, 35)
            dropBtn.BackgroundTransparency = 1
            dropBtn.Text = "  " .. (options.Name or "Dropdown") .. " : " .. (options.CurrentOption[1] or "")
            dropBtn.TextColor3 = Lonum.Theme.TextNormal
            dropBtn.Font = Enum.Font.Gotham
            dropBtn.TextSize = 13
            dropBtn.TextXAlignment = Enum.TextXAlignment.Left
            dropBtn.Parent = dropFrame

            local isOpen = false
            local listOffset = 35

            local optionContainer = Instance.new("Frame")
            optionContainer.Size = UDim2.new(1, 0, 1, -35)
            optionContainer.Position = UDim2.new(0, 0, 0, 35)
            optionContainer.BackgroundTransparency = 1
            optionContainer.Parent = dropFrame

            local optLayout = Instance.new("UIListLayout")
            optLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optLayout.Parent = optionContainer

            local flag = options.Flag or options.Name
            local selected = options.CurrentOption[1] or ""

            if configData[flag] ~= nil then
                selected = configData[flag]
                dropBtn.Text = "  " .. (options.Name or "Dropdown") .. " : " .. selected
                if options.Callback then options.Callback({selected}) end
            end

            local function Fire(val)
                selected = val
                dropBtn.Text = "  " .. (options.Name or "Dropdown") .. " : " .. selected
                if options.Callback then options.Callback({selected}) end
                configData[flag] = selected
                Lonum:SaveConfig()
            end

            for _, opt in ipairs(options.Options or {}) do
                local oBtn = Instance.new("TextButton")
                oBtn.Size = UDim2.new(1, 0, 0, 30)
                oBtn.BackgroundColor3 = Lonum.Theme.ElementBackground
                oBtn.Text = "    " .. opt
                oBtn.TextColor3 = Lonum.Theme.TextDim
                oBtn.Font = Enum.Font.Gotham
                oBtn.TextSize = 12
                oBtn.TextXAlignment = Enum.TextXAlignment.Left
                oBtn.Parent = optionContainer

                oBtn.MouseEnter:Connect(function()
                    TweenService:Create(oBtn, TweenInfo.new(0.2), {BackgroundColor3 = Lonum.Theme.SidebarBackground}):Play()
                end)
                oBtn.MouseLeave:Connect(function()
                    TweenService:Create(oBtn, TweenInfo.new(0.2), {BackgroundColor3 = Lonum.Theme.ElementBackground}):Play()
                end)
                oBtn.MouseButton1Click:Connect(function()
                    Fire(opt)
                    -- Auto close
                    isOpen = false
                    TweenService:Create(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                end)
            end

            dropBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetHeight = isOpen and (35 + (#(options.Options or {}) * 30)) or 35
                TweenService:Create(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
            end)

            local DropObj = {}
            function DropObj:Refresh(newOpts)
                for _, child in ipairs(optionContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, opt in ipairs(newOpts or {}) do
                    local oBtn = Instance.new("TextButton")
                    oBtn.Size = UDim2.new(1, 0, 0, 30)
                    oBtn.BackgroundColor3 = Lonum.Theme.ElementBackground
                    oBtn.Text = "    " .. opt
                    oBtn.TextColor3 = Lonum.Theme.TextDim
                    oBtn.Font = Enum.Font.Gotham
                    oBtn.TextSize = 12
                    oBtn.TextXAlignment = Enum.TextXAlignment.Left
                    oBtn.Parent = optionContainer

                    oBtn.MouseButton1Click:Connect(function()
                        Fire(opt)
                        isOpen = false
                        TweenService:Create(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                    end)
                end
                options.Options = newOpts
                if isOpen then
                    local targetHeight = 35 + (#newOpts * 30)
                    TweenService:Create(dropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
                end
            end
            return DropObj
        end

        return TabObj
    end

    return WindowObj
end

--=========================================
-- FLOATING HUD (UI KEDUA / DEBUG MENU)
--=========================================
function Lonum:CreateFloatingHUD(options)
    options = options or {}
    local Title = options.Title or "Debug HUD"

    local targetParent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
    pcall(function()
        if not targetParent or not targetParent:FindFirstChild("RobloxGui") then
            targetParent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        end
    end)

    -- Destroy old instance
    for _, gui in pairs(targetParent:GetChildren()) do
        if gui.Name == "LonumFloatingGui" then gui:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LonumFloatingGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = targetParent

    local HUDFrame = Instance.new("Frame")
    HUDFrame.Name = "HUDFrame"
    HUDFrame.Size = UDim2.new(0, 250, 0, 80)
    HUDFrame.Position = UDim2.new(1, -270, 0, 20)
    HUDFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    HUDFrame.BackgroundTransparency = 0.2
    HUDFrame.BorderSizePixel = 0
    HUDFrame.Parent = ScreenGui

    local HUDCorner = Instance.new("UICorner")
    HUDCorner.CornerRadius = self.Theme.CornerRadius
    HUDCorner.Parent = HUDFrame

    -- HUD Header (Draggable)
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 25)
    Header.BackgroundTransparency = 1
    Header.Parent = HUDFrame

    MakeDraggable(Header, HUDFrame)

    local HeaderText = Instance.new("TextLabel")
    HeaderText.Size = UDim2.new(1, -20, 1, 0)
    HeaderText.Position = UDim2.new(0, 10, 0, 0)
    HeaderText.BackgroundTransparency = 1
    HeaderText.Text = Title
    HeaderText.TextColor3 = self.Theme.Accent
    HeaderText.Font = Enum.Font.GothamBold
    HeaderText.TextSize = 12
    HeaderText.TextXAlignment = Enum.TextXAlignment.Left
    HeaderText.Parent = Header

    local ContentText = Instance.new("TextLabel")
    ContentText.Size = UDim2.new(1, -20, 1, -25)
    ContentText.Position = UDim2.new(0, 10, 0, 25)
    ContentText.BackgroundTransparency = 1
    ContentText.Text = "Waiting for data..."
    ContentText.TextColor3 = self.Theme.TextTitle
    ContentText.Font = Enum.Font.Gotham
    ContentText.TextSize = 12
    ContentText.TextXAlignment = Enum.TextXAlignment.Left
    ContentText.TextYAlignment = Enum.TextYAlignment.Top
    ContentText.TextWrapped = true
    ContentText.Parent = HUDFrame

    local HUDObj = {}
    function HUDObj:UpdateText(newText)
        ContentText.Text = newText

        -- Auto resize based on text content lines
        local _, lineCount = string.gsub(newText, "\n", "")
        lineCount = lineCount + 1
        local neededHeight = 25 + (lineCount * 18) + 10
        if neededHeight < 80 then neededHeight = 80 end

        TweenService:Create(HUDFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 250, 0, neededHeight)}):Play()
    end

    function HUDObj:SetVisible(state)
        HUDFrame.Visible = state
    end

    function HUDObj:Destroy()
        ScreenGui:Destroy()
    end

    return HUDObj
end

--=========================================
-- NOTIFICATION SYSTEM
--=========================================
function Lonum:Notify(options)
    options = options or {}
    local Title = options.Title or "Notification"
    local Content = options.Content or "..."
    local Duration = options.Duration or 3

    local targetParent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
    pcall(function()
        if not targetParent or not targetParent:FindFirstChild("RobloxGui") then
            targetParent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        end
    end)

    local NotifGui = targetParent:FindFirstChild("LonumNotifGui")
    if not NotifGui then
        NotifGui = Instance.new("ScreenGui")
        NotifGui.Name = "LonumNotifGui"
        NotifGui.ResetOnSpawn = false
        NotifGui.Parent = targetParent
    end

    local NotifContainer = NotifGui:FindFirstChild("Container")
    if not NotifContainer then
        NotifContainer = Instance.new("Frame")
        NotifContainer.Name = "Container"
        NotifContainer.Size = UDim2.new(0, 250, 1, 0)
        NotifContainer.Position = UDim2.new(1, -270, 0, 0)
        NotifContainer.BackgroundTransparency = 1
        NotifContainer.Parent = NotifGui

        local NLayout = Instance.new("UIListLayout")
        NLayout.SortOrder = Enum.SortOrder.LayoutOrder
        NLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        NLayout.Padding = UDim.new(0, 10)
        NLayout.Parent = NotifContainer

        local NPad = Instance.new("UIPadding")
        NPad.PaddingBottom = UDim.new(0, 20)
        NPad.Parent = NotifContainer
    end

    local nFrame = Instance.new("Frame")
    nFrame.Size = UDim2.new(1, 0, 0, 60)
    nFrame.Position = UDim2.new(1, 300, 0, 0) -- Start hidden
    nFrame.BackgroundColor3 = self.Theme.ElementBackground
    nFrame.Parent = NotifContainer

    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = self.Theme.CornerRadius
    nCorner.Parent = nFrame

    local nLine = Instance.new("Frame")
    nLine.Size = UDim2.new(0, 3, 1, -10)
    nLine.Position = UDim2.new(0, 5, 0, 5)
    nLine.BackgroundColor3 = self.Theme.Accent
    nLine.BorderSizePixel = 0
    nLine.Parent = nFrame

    local nCornerLine = Instance.new("UICorner")
    nCornerLine.CornerRadius = UDim.new(1, 0)
    nCornerLine.Parent = nLine

    local nTitle = Instance.new("TextLabel")
    nTitle.Size = UDim2.new(1, -20, 0, 20)
    nTitle.Position = UDim2.new(0, 15, 0, 10)
    nTitle.BackgroundTransparency = 1
    nTitle.Text = Title
    nTitle.TextColor3 = self.Theme.TextTitle
    nTitle.Font = Enum.Font.GothamBold
    nTitle.TextSize = 13
    nTitle.TextXAlignment = Enum.TextXAlignment.Left
    nTitle.Parent = nFrame

    local nText = Instance.new("TextLabel")
    nText.Size = UDim2.new(1, -20, 0, 20)
    nText.Position = UDim2.new(0, 15, 0, 30)
    nText.BackgroundTransparency = 1
    nText.Text = Content
    nText.TextColor3 = self.Theme.TextDim
    nText.Font = Enum.Font.Gotham
    nText.TextSize = 11
    nText.TextXAlignment = Enum.TextXAlignment.Left
    nText.Parent = nFrame

    -- Animate In
    TweenService:Create(nFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

    -- Auto Destroy
    task.spawn(function()
        task.wait(Duration)
        local tweenOut = TweenService:Create(nFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, 0, 0)})
        tweenOut:Play()
        tweenOut.Completed:Wait()
        nFrame:Destroy()
    end)
end

return Lonum
