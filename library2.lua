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
    MainBackground = Color3.fromRGB(20, 20, 25),    -- #141419
    SidebarBackground = Color3.fromRGB(15, 15, 20), -- #0f0f14
    ElementBackground = Color3.fromRGB(30, 30, 35), -- #1e1e23
    Accent = Color3.fromRGB(85, 120, 255),          -- #5578ff
    TextTitle = Color3.fromRGB(255, 255, 255),      -- #ffffff
    TextNormal = Color3.fromRGB(200, 200, 200),     -- #c8c8c8
    TextDim = Color3.fromRGB(150, 150, 150),        -- #969696
    CornerRadius = UDim.new(0, 10)                   -- Standard rounded
}

Lonum.ToggleKey = Enum.KeyCode.K

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
-- FLOATING HUD (DEBUG MENU)
--=========================================
function Lonum:CreateFloatingHUD(options)
    options = options or {}
    local Title = options.Title or "Server Live Status"

    local targetParent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
    pcall(function()
        if not targetParent or not targetParent:FindFirstChild("RobloxGui") then
            targetParent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        end
    end)

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
    HUDFrame.BackgroundTransparency = 0.15
    HUDFrame.BorderSizePixel = 0
    HUDFrame.Parent = ScreenGui

    local HUDCorner = Instance.new("UICorner")
    HUDCorner.CornerRadius = self.Theme.CornerRadius
    HUDCorner.Parent = HUDFrame

    local HUDStroke = Instance.new("UIStroke")
    HUDStroke.Color = Color3.fromRGB(255, 255, 255)
    HUDStroke.Transparency = 0.95
    HUDStroke.Parent = HUDFrame

    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundTransparency = 1
    Header.Parent = HUDFrame

    local HeaderBottomBorder = Instance.new("Frame")
    HeaderBottomBorder.Size = UDim2.new(1, -24, 0, 1)
    HeaderBottomBorder.Position = UDim2.new(0, 12, 1, 0)
    HeaderBottomBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HeaderBottomBorder.BackgroundTransparency = 0.95
    HeaderBottomBorder.BorderSizePixel = 0
    HeaderBottomBorder.Parent = Header

    MakeDraggable(Header, HUDFrame)

    local HeaderText = Instance.new("TextLabel")
    HeaderText.Size = UDim2.new(1, -40, 1, 0)
    HeaderText.Position = UDim2.new(0, 12, 0, 0)
    HeaderText.BackgroundTransparency = 1
    HeaderText.Text = string.upper(Title)
    HeaderText.TextColor3 = self.Theme.Accent
    HeaderText.Font = Enum.Font.GothamBold
    HeaderText.TextSize = 11
    HeaderText.TextXAlignment = Enum.TextXAlignment.Left
    HeaderText.Parent = Header

    local PulseDot = Instance.new("Frame")
    PulseDot.Size = UDim2.new(0, 6, 0, 6)
    PulseDot.Position = UDim2.new(1, -18, 0.5, -3)
    PulseDot.BackgroundColor3 = Color3.fromRGB(0, 230, 118)
    PulseDot.BorderSizePixel = 0
    PulseDot.Parent = Header

    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1, 0)
    DotCorner.Parent = PulseDot

    -- Pulse Animation
    task.spawn(function()
        while PulseDot.Parent do
            TweenService:Create(PulseDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.6}):Play()
            task.wait(1)
            TweenService:Create(PulseDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0}):Play()
            task.wait(1)
        end
    end)

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -24, 1, -40)
    ContentContainer.Position = UDim2.new(0, 12, 0, 38)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = HUDFrame

    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 6)
    ContentLayout.Parent = ContentContainer

    -- Auto Resize HUD
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local h = 38 + ContentLayout.AbsoluteContentSize.Y + 12
        TweenService:Create(HUDFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 250, 0, h)}):Play()
    end)

    local HUDObj = {}
    -- Rows Data
    local rowCache = {}

    -- UpdateText accepts string formatted with \n as lines, and splits it into Key : Value rows just like HTML
    function HUDObj:UpdateText(newText)
        local lines = string.split(newText, "\n")

        -- Hide unused rows
        for i = #lines + 1, #rowCache do
            rowCache[i].Frame.Visible = false
        end

        for i, line in ipairs(lines) do
            local parts = string.split(line, ":")
            local keyStr = parts[1] or ""
            local valStr = parts[2] or ""
            if valStr == "" then valStr = keyStr; keyStr = "" end -- fallback if no colon

            -- Cleanup string
            keyStr = keyStr:gsub("^%s+", ""):gsub("%s+$", "")
            valStr = valStr:gsub("^%s+", ""):gsub("%s+$", "")

            local row = rowCache[i]
            if not row then
                local rFrame = Instance.new("Frame")
                rFrame.Size = UDim2.new(1, 0, 0, 16)
                rFrame.BackgroundTransparency = 1
                rFrame.Parent = ContentContainer

                local lText = Instance.new("TextLabel")
                lText.Size = UDim2.new(0.5, 0, 1, 0)
                lText.BackgroundTransparency = 1
                lText.TextColor3 = Lonum.Theme.TextDim
                lText.Font = Enum.Font.Gotham
                lText.TextSize = 12
                lText.TextXAlignment = Enum.TextXAlignment.Left
                lText.Parent = rFrame

                local rText = Instance.new("TextLabel")
                rText.Size = UDim2.new(0.5, 0, 1, 0)
                rText.Position = UDim2.new(0.5, 0, 0, 0)
                rText.BackgroundTransparency = 1
                rText.TextColor3 = Lonum.Theme.TextTitle
                rText.Font = Enum.Font.Gotham
                rText.TextSize = 12
                rText.TextXAlignment = Enum.TextXAlignment.Right
                rText.Parent = rFrame

                row = {Frame = rFrame, Left = lText, Right = rText}
                rowCache[i] = row
            end

            row.Frame.Visible = true
            row.Left.Text = keyStr

            -- Color grading based on keywords (like HTML good/bad class)
            if string.find(string.lower(valStr), "✅") or string.find(string.lower(valStr), "spawned") then
                row.Right.TextColor3 = Color3.fromRGB(0, 230, 118)
            elseif string.find(string.lower(valStr), "❌") or string.find(string.lower(valStr), "inactive") then
                row.Right.TextColor3 = Color3.fromRGB(255, 59, 59)
            else
                row.Right.TextColor3 = Lonum.Theme.TextTitle
            end
            row.Right.Text = valStr
        end
    end

    function HUDObj:SetVisible(state)
        HUDFrame.Visible = state
    end

    return HUDObj
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

    local targetParent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
    pcall(function()
        if not targetParent or not targetParent:FindFirstChild("RobloxGui") then
            targetParent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        end
    end)

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
    MainFrame.Size = UDim2.new(0, 700, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -350, 0.5, -240)
    MainFrame.BackgroundColor3 = self.Theme.MainBackground
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 5)
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "http://www.roblox.com/asset/?id=5554236805"
    Shadow.ImageColor3 = Color3.new(0, 0, 0)
    Shadow.ImageTransparency = 0.4
    Shadow.ZIndex = 0
    Shadow.Parent = MainFrame

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = self.Theme.CornerRadius
    MainCorner.Parent = MainFrame

    -- SIDEBAR
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 190, 1, 0)
    Sidebar.BackgroundColor3 = self.Theme.SidebarBackground
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = self.Theme.CornerRadius
    SidebarCorner.Parent = Sidebar

    local SidebarHideCorner = Instance.new("Frame")
    SidebarHideCorner.Size = UDim2.new(0, 10, 1, 0)
    SidebarHideCorner.Position = UDim2.new(1, -10, 0, 0)
    SidebarHideCorner.BackgroundColor3 = self.Theme.SidebarBackground
    SidebarHideCorner.BorderSizePixel = 0
    SidebarHideCorner.Parent = Sidebar

    local SidebarBorder = Instance.new("Frame")
    SidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    SidebarBorder.Position = UDim2.new(1, -1, 0, 0)
    SidebarBorder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SidebarBorder.BackgroundTransparency = 0.95
    SidebarBorder.BorderSizePixel = 0
    SidebarBorder.Parent = Sidebar

    MakeDraggable(Sidebar, MainFrame)

    -- HEADER
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 65)
    Header.BackgroundTransparency = 1
    Header.Parent = Sidebar

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.Position = UDim2.new(0, 0, 1, -1)
    HeaderLine.BackgroundColor3 = self.Theme.ElementBackground
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Parent = Header

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -30, 0, 20)
    TitleLabel.Position = UDim2.new(0, 15, 0, 15)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = self.Theme.Accent
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -30, 0, 15)
    SubLabel.Position = UDim2.new(0, 15, 0, 38)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = Subtitle
    SubLabel.TextColor3 = self.Theme.TextDim
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextSize = 11
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = Header

    -- TAB CONTAINER IN SIDEBAR
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 1, -65)
    TabContainer.Position = UDim2.new(0, 0, 0, 65)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.Parent = TabContainer

    local TabPad = Instance.new("UIPadding")
    TabPad.PaddingTop = UDim.new(0, 15)
    TabPad.PaddingBottom = UDim.new(0, 15)
    TabPad.Parent = TabContainer

    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 30)
    end)

    -- CONTENT AREA
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -190, 1, 0)
    ContentArea.Position = UDim2.new(0, 190, 0, 0)
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
        TabButton.Text = "  " .. tabName
        TabButton.TextColor3 = Lonum.Theme.TextDim
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.TextSize = 13
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabContainer

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = Lonum.Theme.CornerRadius
        TabBtnCorner.Parent = TabButton

        local ActiveGlow = Instance.new("Frame")
        ActiveGlow.Size = UDim2.new(0, 3, 1, 0)
        ActiveGlow.BackgroundColor3 = Lonum.Theme.Accent
        ActiveGlow.BorderSizePixel = 0
        ActiveGlow.BackgroundTransparency = 1
        ActiveGlow.Parent = TabButton

        local GlowCorner = Instance.new("UICorner")
        GlowCorner.CornerRadius = UDim.new(0, 3)
        GlowCorner.Parent = ActiveGlow

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = tabName.."_Page"
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 4
        TabPage.ScrollBarImageColor3 = Lonum.Theme.ElementBackground
        TabPage.Visible = false
        TabPage.Parent = ContentArea

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = TabPage

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 25)
        PagePadding.PaddingBottom = UDim.new(0, 25)
        PagePadding.PaddingLeft = UDim.new(0, 25)
        PagePadding.PaddingRight = UDim.new(0, 25)
        PagePadding.Parent = TabPage

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 50)
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(self.Tabs) do
                t.Page.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.2), {TextColor3 = Lonum.Theme.TextDim, BackgroundTransparency = 1}):Play()
                TweenService:Create(t.Glow, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end

            TabPage.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.2), {TextColor3 = Lonum.Theme.TextTitle, BackgroundTransparency = 0}):Play()
            TweenService:Create(ActiveGlow, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            self.CurrentTab = tabName
        end)

        local TabObj = {
            Button = TabButton,
            Glow = ActiveGlow,
            Page = TabPage
        }
        table.insert(self.Tabs, TabObj)

        if #self.Tabs == 1 then
            TabPage.Visible = true
            TabButton.TextColor3 = Lonum.Theme.TextTitle
            TabButton.BackgroundTransparency = 0
            ActiveGlow.BackgroundTransparency = 0
            self.CurrentTab = tabName
        end

        -- ELEMENTS BUILDER
        function TabObj:CreateSection(name)
            local SecLabel = Instance.new("TextLabel")
            SecLabel.Size = UDim2.new(1, 0, 0, 30)
            SecLabel.BackgroundTransparency = 1
            SecLabel.Text = string.upper(name)
            SecLabel.TextColor3 = Lonum.Theme.Accent
            SecLabel.Font = Enum.Font.GothamBold
            SecLabel.TextSize = 13
            SecLabel.TextXAlignment = Enum.TextXAlignment.Left
            SecLabel.TextYAlignment = Enum.TextYAlignment.Bottom
            SecLabel.Parent = TabPage
        end

        function TabObj:CreateLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Lonum.Theme.TextDim
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = TabPage

            local LabelObj = {}
            function LabelObj:Set(newText) lbl.Text = newText end
            return LabelObj
        end

        function TabObj:CreateParagraph(options)
            return self:CreateLabel(options.Content or "")
        end

        function TabObj:CreateButton(options)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 42)
            btn.BackgroundColor3 = Lonum.Theme.ElementBackground
            btn.Text = options.Name or "Button"
            btn.TextColor3 = Lonum.Theme.TextTitle
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 13
            btn.AutoButtonColor = false
            btn.Parent = TabPage

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = Lonum.Theme.CornerRadius
            btnCorner.Parent = btn

            local btnStroke = Instance.new("UIStroke")
            btnStroke.Color = Color3.fromRGB(255,255,255)
            btnStroke.Transparency = 0.95
            btnStroke.Parent = btn

            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Lonum.Theme.Accent}):Play()
                TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Lonum.Theme.Accent, Transparency = 0}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Lonum.Theme.ElementBackground}):Play()
                TweenService:Create(btnStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255,255,255), Transparency = 0.95}):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0.98, 0, 0, 38)}):Play()
                task.wait(0.1)
                TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 42)}):Play()
                if options.Callback then options.Callback() end
            end)
        end

        function TabObj:CreateToggle(options)
            local flag = options.Flag or options.Name
            local defaultVal = options.CurrentValue or false

            if configData[flag] ~= nil then defaultVal = configData[flag] end

            local tFrame = Instance.new("TextButton")
            tFrame.Size = UDim2.new(1, 0, 0, 42)
            tFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            tFrame.Text = ""
            tFrame.AutoButtonColor = false
            tFrame.Parent = TabPage

            local tCorner = Instance.new("UICorner")
            tCorner.CornerRadius = Lonum.Theme.CornerRadius
            tCorner.Parent = tFrame

            local tStroke = Instance.new("UIStroke")
            tStroke.Color = Color3.fromRGB(255,255,255)
            tStroke.Transparency = 0.95
            tStroke.Parent = tFrame

            local tLabel = Instance.new("TextLabel")
            tLabel.Size = UDim2.new(1, -60, 1, 0)
            tLabel.Position = UDim2.new(0, 15, 0, 0)
            tLabel.BackgroundTransparency = 1
            tLabel.Text = options.Name or "Toggle"
            tLabel.TextColor3 = Lonum.Theme.TextNormal
            tLabel.Font = Enum.Font.Gotham
            tLabel.TextSize = 13
            tLabel.TextXAlignment = Enum.TextXAlignment.Left
            tLabel.Parent = tFrame

            local tBox = Instance.new("Frame")
            tBox.Size = UDim2.new(0, 36, 0, 18)
            tBox.Position = UDim2.new(1, -50, 0.5, -9)
            tBox.BackgroundColor3 = defaultVal and Lonum.Theme.Accent or Color3.fromRGB(50, 50, 55)
            tBox.Parent = tFrame

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(1, 0)
            boxCorner.Parent = tBox

            local tCircle = Instance.new("Frame")
            tCircle.Size = UDim2.new(0, 14, 0, 14)
            tCircle.Position = defaultVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            tCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            tCircle.Parent = tBox

            local circleCorner = Instance.new("UICorner")
            circleCorner.CornerRadius = UDim.new(1, 0)
            circleCorner.Parent = tCircle

            local State = defaultVal

            -- Sinkronisasikan state konfigurasi awal ke skrip utama secara langsung
            if options.Callback then options.Callback(State) end

            local function Fire()
                if options.Callback then options.Callback(State) end
                configData[flag] = State
                Lonum:SaveConfig()
            end

            tFrame.MouseButton1Click:Connect(function()
                State = not State
                TweenService:Create(tBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = State and Lonum.Theme.Accent or Color3.fromRGB(50, 50, 55)
                }):Play()
                TweenService:Create(tCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = State and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                }):Play()
                Fire()
            end)

            local TogObj = {}
            function TogObj:Set(newVal)
                if State == newVal then return end
                State = newVal
                TweenService:Create(tBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = State and Lonum.Theme.Accent or Color3.fromRGB(50, 50, 55)
                }):Play()
                TweenService:Create(tCircle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = State and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
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

            if configData[flag] ~= nil then defaultVal = configData[flag] end
            defaultVal = math.clamp(defaultVal, min, max)

            local sFrame = Instance.new("Frame")
            sFrame.Size = UDim2.new(1, 0, 0, 55)
            sFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            sFrame.Parent = TabPage

            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = Lonum.Theme.CornerRadius
            sCorner.Parent = sFrame

            local sStroke = Instance.new("UIStroke")
            sStroke.Color = Color3.fromRGB(255,255,255)
            sStroke.Transparency = 0.95
            sStroke.Parent = sFrame

            local sLabel = Instance.new("TextLabel")
            sLabel.Size = UDim2.new(1, -20, 0, 20)
            sLabel.Position = UDim2.new(0, 15, 0, 10)
            sLabel.BackgroundTransparency = 1
            sLabel.Text = options.Name or "Slider"
            sLabel.TextColor3 = Lonum.Theme.TextNormal
            sLabel.Font = Enum.Font.Gotham
            sLabel.TextSize = 13
            sLabel.TextXAlignment = Enum.TextXAlignment.Left
            sLabel.Parent = sFrame

            local sValLabel = Instance.new("TextLabel")
            sValLabel.Size = UDim2.new(0, 50, 0, 20)
            sValLabel.Position = UDim2.new(1, -65, 0, 10)
            sValLabel.BackgroundTransparency = 1
            sValLabel.Text = tostring(defaultVal)
            sValLabel.TextColor3 = Lonum.Theme.Accent
            sValLabel.Font = Enum.Font.GothamBold
            sValLabel.TextSize = 13
            sValLabel.TextXAlignment = Enum.TextXAlignment.Right
            sValLabel.Parent = sFrame

            local sBarArea = Instance.new("TextButton")
            sBarArea.Size = UDim2.new(1, -30, 0, 6)
            sBarArea.Position = UDim2.new(0, 15, 0, 38)
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

            local sKnob = Instance.new("Frame")
            sKnob.Size = UDim2.new(0, 12, 0, 12)
            sKnob.Position = UDim2.new(1, -6, 0.5, -6)
            sKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sKnob.Parent = sFill

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = sKnob

            local Value = defaultVal

            -- Sinkronisasikan state konfigurasi awal ke skrip utama secara langsung
            sValLabel.Text = tostring(Value)
            if options.Callback then options.Callback(Value) end

            local function Fire()
                sValLabel.Text = tostring(Value)
                if options.Callback then options.Callback(Value) end
                configData[flag] = Value
                Lonum:SaveConfig()
            end

            local dragging = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - sBarArea.AbsolutePosition.X) / sBarArea.AbsoluteSize.X, 0, 1)
                local rawValue = min + (pos * (max - min))
                Value = math.floor(rawValue / inc + 0.5) * inc
                Value = math.clamp(Value, min, max)

                local pct = (Value - min) / (max - min)
                TweenService:Create(sFill, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
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
            local dropFrame = Instance.new("Frame")
            dropFrame.Size = UDim2.new(1, 0, 0, 42)
            dropFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            dropFrame.ClipsDescendants = true
            dropFrame.Parent = TabPage

            local dropCorner = Instance.new("UICorner")
            dropCorner.CornerRadius = Lonum.Theme.CornerRadius
            dropCorner.Parent = dropFrame

            local dStroke = Instance.new("UIStroke")
            dStroke.Color = Color3.fromRGB(255,255,255)
            dStroke.Transparency = 0.95
            dStroke.Parent = dropFrame

            local dropBtn = Instance.new("TextButton")
            dropBtn.Size = UDim2.new(1, 0, 0, 42)
            dropBtn.BackgroundTransparency = 1
            dropBtn.Text = ""
            dropBtn.AutoButtonColor = false
            dropBtn.Parent = dropFrame

            local dTitle = Instance.new("TextLabel")
            dTitle.Size = UDim2.new(0.5, 0, 1, 0)
            dTitle.Position = UDim2.new(0, 15, 0, 0)
            dTitle.BackgroundTransparency = 1
            dTitle.Text = options.Name or "Dropdown"
            dTitle.TextColor3 = Lonum.Theme.TextNormal
            dTitle.Font = Enum.Font.Gotham
            dTitle.TextSize = 13
            dTitle.TextXAlignment = Enum.TextXAlignment.Left
            dTitle.Parent = dropBtn

            local dValue = Instance.new("TextLabel")
            dValue.Size = UDim2.new(0.5, -30, 1, 0)
            dValue.Position = UDim2.new(0.5, 10, 0, 0)
            dValue.BackgroundTransparency = 1
            dValue.Text = (options.CurrentOption[1] or "") .. " ▾"
            dValue.TextColor3 = Lonum.Theme.TextDim
            dValue.Font = Enum.Font.Gotham
            dValue.TextSize = 12
            dValue.TextXAlignment = Enum.TextXAlignment.Right
            dValue.Parent = dropBtn

            local isOpen = false
            local optionContainer = Instance.new("Frame")
            optionContainer.Size = UDim2.new(1, 0, 1, -42)
            optionContainer.Position = UDim2.new(0, 0, 0, 42)
            optionContainer.BackgroundTransparency = 1
            optionContainer.Parent = dropFrame

            local optLayout = Instance.new("UIListLayout")
            optLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optLayout.Parent = optionContainer

            local flag = options.Flag or options.Name
            local selected = options.CurrentOption[1] or ""

            if configData[flag] ~= nil then
                selected = configData[flag]
            end

            -- Initial state sync
            dValue.Text = selected .. " ▾"
            if options.Callback then options.Callback({selected}) end

            local function Fire(val)
                selected = val
                dValue.Text = selected .. " ▾"
                if options.Callback then options.Callback({selected}) end
                configData[flag] = selected
                Lonum:SaveConfig()
            end

            for _, opt in ipairs(options.Options or {}) do
                local oBtn = Instance.new("TextButton")
                oBtn.Size = UDim2.new(1, 0, 0, 35)
                oBtn.BackgroundColor3 = Lonum.Theme.ElementBackground
                oBtn.Text = "    " .. opt
                oBtn.TextColor3 = Lonum.Theme.TextDim
                oBtn.Font = Enum.Font.Gotham
                oBtn.TextSize = 12
                oBtn.TextXAlignment = Enum.TextXAlignment.Left
                oBtn.AutoButtonColor = false
                oBtn.Parent = optionContainer

                oBtn.MouseEnter:Connect(function()
                    TweenService:Create(oBtn, TweenInfo.new(0.2), {BackgroundColor3 = Lonum.Theme.SidebarBackground, TextColor3 = Lonum.Theme.TextNormal}):Play()
                end)
                oBtn.MouseLeave:Connect(function()
                    TweenService:Create(oBtn, TweenInfo.new(0.2), {BackgroundColor3 = Lonum.Theme.ElementBackground, TextColor3 = Lonum.Theme.TextDim}):Play()
                end)
                oBtn.MouseButton1Click:Connect(function()
                    Fire(opt)
                    isOpen = false
                    TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 42)}):Play()
                end)
            end

            dropBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetHeight = isOpen and (42 + (#(options.Options or {}) * 35)) or 42
                TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
            end)

            local DropObj = {}
            function DropObj:Refresh(newOpts)
                for _, child in ipairs(optionContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, opt in ipairs(newOpts or {}) do
                    local oBtn = Instance.new("TextButton")
                    oBtn.Size = UDim2.new(1, 0, 0, 35)
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
                        TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 42)}):Play()
                    end)
                end
                options.Options = newOpts
                if isOpen then
                    local targetHeight = 42 + (#newOpts * 35)
                    TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
                end
            end
            return DropObj
        end

        function TabObj:CreateKeybind(options)
            local flag = options.Flag or options.Name
            local defaultVal = options.CurrentValue or Enum.KeyCode.K

            if configData[flag] ~= nil then
                -- Parse from string (JSON save) to Enum
                local success, result = pcall(function() return Enum.KeyCode[configData[flag]] end)
                if success and result then defaultVal = result end
            end

            -- Update master key
            if flag == "ToggleUIKeybind" then Lonum.ToggleKey = defaultVal end

            -- Initial state sync
            if options.Callback then options.Callback(defaultVal) end

            local kFrame = Instance.new("Frame")
            kFrame.Size = UDim2.new(1, 0, 0, 42)
            kFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            kFrame.Parent = TabPage

            local kCorner = Instance.new("UICorner")
            kCorner.CornerRadius = Lonum.Theme.CornerRadius
            kCorner.Parent = kFrame

            local kStroke = Instance.new("UIStroke")
            kStroke.Color = Color3.fromRGB(255,255,255)
            kStroke.Transparency = 0.95
            kStroke.Parent = kFrame

            local kLabel = Instance.new("TextLabel")
            kLabel.Size = UDim2.new(1, -100, 1, 0)
            kLabel.Position = UDim2.new(0, 15, 0, 0)
            kLabel.BackgroundTransparency = 1
            kLabel.Text = options.Name or "Keybind"
            kLabel.TextColor3 = Lonum.Theme.TextNormal
            kLabel.Font = Enum.Font.Gotham
            kLabel.TextSize = 13
            kLabel.TextXAlignment = Enum.TextXAlignment.Left
            kLabel.Parent = kFrame

            local kBtn = Instance.new("TextButton")
            kBtn.Size = UDim2.new(0, 80, 0, 26)
            kBtn.Position = UDim2.new(1, -95, 0.5, -13)
            kBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            kBtn.Text = defaultVal.Name
            kBtn.TextColor3 = Lonum.Theme.Accent
            kBtn.Font = Enum.Font.GothamBold
            kBtn.TextSize = 12
            kBtn.AutoButtonColor = false
            kBtn.Parent = kFrame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = kBtn

            local isListening = false
            local connection

            local function Fire(val)
                kBtn.Text = val.Name
                if options.Callback then options.Callback(val) end
                if flag == "ToggleUIKeybind" then Lonum.ToggleKey = val end
                configData[flag] = val.Name
                Lonum:SaveConfig()
            end

            kBtn.MouseButton1Click:Connect(function()
                if isListening then return end
                isListening = true
                kBtn.Text = "..."
                TweenService:Create(kBtn, TweenInfo.new(0.2), {BackgroundColor3 = Lonum.Theme.SidebarBackground}):Play()

                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local key = input.KeyCode
                        isListening = false
                        connection:Disconnect()
                        TweenService:Create(kBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play()

                        -- Prevent binding to critical system keys
                        if key ~= Enum.KeyCode.Escape and key ~= Enum.KeyCode.Unknown then
                            Fire(key)
                        else
                            kBtn.Text = defaultVal.Name
                        end
                    end
                end)
            end)
        end

        return TabObj
    end

    -- Toggle UI Visibility Logic
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end -- Don't trigger if typing in chat
        if input.KeyCode == Lonum.ToggleKey then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    return WindowObj
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
    nFrame.Position = UDim2.new(1, 300, 0, 0)
    nFrame.BackgroundColor3 = self.Theme.ElementBackground
    nFrame.Parent = NotifContainer

    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = self.Theme.CornerRadius
    nCorner.Parent = nFrame

    local nStroke = Instance.new("UIStroke")
    nStroke.Color = Color3.fromRGB(255,255,255)
    nStroke.Transparency = 0.95
    nStroke.Parent = nFrame

    local nLine = Instance.new("Frame")
    nLine.Size = UDim2.new(0, 3, 1, -24)
    nLine.Position = UDim2.new(0, 8, 0, 12)
    nLine.BackgroundColor3 = self.Theme.Accent
    nLine.BorderSizePixel = 0
    nLine.Parent = nFrame

    local nCornerLine = Instance.new("UICorner")
    nCornerLine.CornerRadius = UDim.new(1, 0)
    nCornerLine.Parent = nLine

    local nTitle = Instance.new("TextLabel")
    nTitle.Size = UDim2.new(1, -20, 0, 20)
    nTitle.Position = UDim2.new(0, 18, 0, 10)
    nTitle.BackgroundTransparency = 1
    nTitle.Text = Title
    nTitle.TextColor3 = self.Theme.TextTitle
    nTitle.Font = Enum.Font.GothamBold
    nTitle.TextSize = 12
    nTitle.TextXAlignment = Enum.TextXAlignment.Left
    nTitle.Parent = nFrame

    local nText = Instance.new("TextLabel")
    nText.Size = UDim2.new(1, -20, 0, 20)
    nText.Position = UDim2.new(0, 18, 0, 28)
    nText.BackgroundTransparency = 1
    nText.Text = Content
    nText.TextColor3 = self.Theme.TextDim
    nText.Font = Enum.Font.Gotham
    nText.TextSize = 11
    nText.TextXAlignment = Enum.TextXAlignment.Left
    nText.Parent = nFrame

    -- Animate In
    TweenService:Create(nFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

    -- Auto Destroy
    task.spawn(function()
        task.wait(Duration)
        local tweenOut = TweenService:Create(nFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, 0, 0)})
        tweenOut:Play()
        tweenOut.Completed:Wait()
        nFrame:Destroy()
    end)
end

return Lonum
