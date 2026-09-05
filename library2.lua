local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local function GetSafeParent()
    if gethui and type(gethui) == "function" then
        local success, result = pcall(gethui)
        if success and result then return result end
    end

    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui then
        local robloxGui = coreGui:FindFirstChild("RobloxGui")
        if robloxGui then return robloxGui end
        return coreGui
    end

    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

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
    CornerRadius = UDim.new(0, 10),                  -- Standard rounded
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold
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
local function GenerateRandomName()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    local name = ""
    for i = 1, 15 do
        local r = math.random(1, #chars)
        name = name .. string.sub(chars, r, r)
    end
    return name
end

function Lonum:CreateFloatingHUD(options)
    options = options or {}
    local Title = options.Title or "Server Live Status"

    local targetParent = GetSafeParent()

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = GenerateRandomName()
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
    HUDCorner.CornerRadius = Lonum.Theme.CornerRadius
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
    HeaderText.TextColor3 = Lonum.Theme.Accent
    HeaderText.Font = Lonum.Theme.FontBold
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

    -- UpdateText accepts one key/value row per line.
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
                lText.Font = Lonum.Theme.Font
                lText.TextSize = 12
                lText.TextXAlignment = Enum.TextXAlignment.Left
                lText.Parent = rFrame

                local rText = Instance.new("TextLabel")
                rText.Size = UDim2.new(0.5, 0, 1, 0)
                rText.Position = UDim2.new(0.5, 0, 0, 0)
                rText.BackgroundTransparency = 1
                rText.TextColor3 = Lonum.Theme.TextTitle
                rText.Font = Lonum.Theme.Font
                rText.TextSize = 12
                rText.TextXAlignment = Enum.TextXAlignment.Right
                rText.Parent = rFrame

                row = {Frame = rFrame, Left = lText, Right = rText}
                rowCache[i] = row
            end

            row.Frame.Visible = true
            row.Left.Text = keyStr

            -- Color values based on common status keywords.
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
-- SUNC CHECKER & ENVIRONMENT VALIDATION
--=========================================
function Lonum.UNC(callback)
    local targetParent = GetSafeParent()
    for _, gui in pairs(targetParent:GetChildren()) do
        if gui.Name == "LonumUNC_Test" then gui:Destroy() end
    end

    local UNCGui = Instance.new("ScreenGui")
    UNCGui.Name = "LonumUNC_Test"
    UNCGui.ResetOnSpawn = false
    UNCGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UNCGui.Parent = targetParent

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 400, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    MainFrame.BackgroundColor3 = Lonum.Theme.SidebarBackground
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = UNCGui
    Instance.new("UICorner", MainFrame).CornerRadius = Lonum.Theme.CornerRadius

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Lonum.Theme.ElementBackground
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    Instance.new("UICorner", TopBar).CornerRadius = Lonum.Theme.CornerRadius

    -- Fix bottom rounded corners of topbar
    local Fix = Instance.new("Frame")
    Fix.Size = UDim2.new(1, 0, 0, 10)
    Fix.Position = UDim2.new(0, 0, 1, -10)
    Fix.BackgroundColor3 = Lonum.Theme.ElementBackground
    Fix.BorderSizePixel = 0
    Fix.Parent = TopBar

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -20, 1, 0)
    TitleLbl.Position = UDim2.new(0, 10, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = "Wait, Load Script... (Make sure you see UNC Test!)"
    TitleLbl.TextColor3 = Lonum.Theme.TextTitle
    TitleLbl.Font = Lonum.Theme.FontBold
    TitleLbl.TextSize = 14
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Parent = TopBar

    local ProgBG = Instance.new("Frame")
    ProgBG.Size = UDim2.new(1, -20, 0, 10)
    ProgBG.Position = UDim2.new(0, 10, 0, 50)
    ProgBG.BackgroundColor3 = Lonum.Theme.MainBackground
    ProgBG.Parent = MainFrame
    Instance.new("UICorner", ProgBG).CornerRadius = UDim.new(1, 0)

    local ProgFill = Instance.new("Frame")
    ProgFill.Size = UDim2.new(0, 0, 1, 0)
    ProgFill.BackgroundColor3 = Lonum.Theme.Accent
    ProgFill.Parent = ProgBG
    Instance.new("UICorner", ProgFill).CornerRadius = UDim.new(1, 0)

    local InfoLbl = Instance.new("TextLabel")
    InfoLbl.Size = UDim2.new(1, -20, 0, 20)
    InfoLbl.Position = UDim2.new(0, 10, 0, 65)
    InfoLbl.BackgroundTransparency = 1
    InfoLbl.Text = "Starting tests..."
    InfoLbl.TextColor3 = Lonum.Theme.TextDim
    InfoLbl.Font = Lonum.Theme.Font
    InfoLbl.TextSize = 13
    InfoLbl.Parent = MainFrame

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -140)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 90)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollFrame.Parent = MainFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.Parent = ScrollFrame

    -- Buttons (hidden initially)
    local ButtonsFrame = Instance.new("Frame")
    ButtonsFrame.Size = UDim2.new(1, -20, 0, 35)
    ButtonsFrame.Position = UDim2.new(0, 10, 1, -45)
    ButtonsFrame.BackgroundTransparency = 1
    ButtonsFrame.Visible = false
    ButtonsFrame.Parent = MainFrame

    local BtnCopy = Instance.new("TextButton")
    BtnCopy.Size = UDim2.new(1, 0, 0, 35)
    BtnCopy.BackgroundColor3 = Lonum.Theme.ElementBackground
    BtnCopy.Text = "Copy Output to Clipboard"
    BtnCopy.TextColor3 = Lonum.Theme.TextTitle
    BtnCopy.Font = Lonum.Theme.Font
    BtnCopy.TextSize = 14
    BtnCopy.Parent = ButtonsFrame
    Instance.new("UICorner", BtnCopy).CornerRadius = Lonum.Theme.CornerRadius

    local function addLog(text, isSuccess)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = isSuccess and Color3.fromRGB(0, 230, 118) or Color3.fromRGB(255, 59, 59)
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = ScrollFrame
    end

    task.spawn(function()
        local tests = {
            "checkcaller", "getnamecallmethod", "hookmetamethod",
            "getgenv", "getinstances", "getnilinstances",
            "sethiddenproperty", "getconnections", "firetouchinterest",
            "fireproximityprompt", "gethui", "queue_on_teleport",
            "debug.getupvalues", "debug.setupvalue", "require",
            "hookfunction"
        }

        local passed = 0
        local fails = 0
        local logBuffer = ""

        local function logAndPrint(txt, state)
            local icon = state and "✅" or "❌"
            local fTxt = icon .. " " .. txt
            addLog(fTxt, state)
            logBuffer = logBuffer .. fTxt .. "\n"
            print(fTxt)
        end

        for i, funcName in ipairs(tests) do
            ProgFill.Size = UDim2.new(i / #tests, 0, 1, 0)
            InfoLbl.Text = "Testing: " .. funcName .. " (" .. i .. "/" .. #tests .. ")"

            local path = string.split(funcName, ".")
            local envObj = getgenv()
            local found = true

            -- Quick check if function exists in executor environment
            for _, k in ipairs(path) do
                if type(envObj) == "table" and envObj[k] ~= nil then
                    envObj = envObj[k]
                else
                    found = false
                    break
                end
            end

            -- Certain built-ins validation
            if not found then
                -- if not in getgenv, maybe normal lua environment check
                local ok, res = pcall(function()
                    return loadstring("return " .. funcName)()
                end)
                if ok and res ~= nil then found = true end
            end

            if found then
                passed = passed + 1
                logAndPrint(funcName, true)
            else
                fails = fails + 1
                logAndPrint(funcName, false)
            end

            if i % 5 == 0 then task.wait() end
        end

        local Rate = math.floor((passed / #tests) * 100)
        local summary = "🟢 Passed: " .. passed .. " | 🔴 Failed: " .. fails .. "\nThe Result of the UNC is : " .. Rate .. "%"

        InfoLbl.Text = "Test Complete! Rate: " .. Rate .. "%"
        InfoLbl.TextColor3 = Lonum.Theme.TextTitle
        logBuffer = logBuffer .. "\n" .. summary
        print(summary)

        ButtonsFrame.Visible = true

        BtnCopy.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(logBuffer) end
        end)

        if Rate >= 80 then
            task.wait(1.5)
            UNCGui:Destroy()
            if type(callback) == "function" then callback() end
        else
            TitleLbl.Text = "Failed: Executor must support >= 80% UNC"
            TitleLbl.TextColor3 = Color3.fromRGB(255, 59, 59)

            -- Change UI to show Kick/Bypass
            BtnCopy.Size = UDim2.new(0.3, -5, 0, 35)

            local BtnKick = Instance.new("TextButton")
            BtnKick.Size = UDim2.new(0.3, -5, 0, 35)
            BtnKick.Position = UDim2.new(0.3, 5, 0, 0)
            BtnKick.BackgroundColor3 = Color3.fromRGB(255, 59, 59)
            BtnKick.Text = "Kick"
            BtnKick.TextColor3 = Color3.fromRGB(255, 255, 255)
            BtnKick.Font = Lonum.Theme.FontBold
            BtnKick.TextSize = 14
            BtnKick.Parent = ButtonsFrame
            Instance.new("UICorner", BtnKick).CornerRadius = Lonum.Theme.CornerRadius

            local BtnBypass = Instance.new("TextButton")
            BtnBypass.Size = UDim2.new(0.4, -5, 0, 35)
            BtnBypass.Position = UDim2.new(0.6, 5, 0, 0)
            BtnBypass.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
            BtnBypass.Text = "Bypass (Bugs Expected)"
            BtnBypass.TextColor3 = Color3.fromRGB(255, 255, 255)
            BtnBypass.Font = Lonum.Theme.FontBold
            BtnBypass.TextSize = 12
            BtnBypass.Parent = ButtonsFrame
            Instance.new("UICorner", BtnBypass).CornerRadius = Lonum.Theme.CornerRadius

            BtnKick.MouseButton1Click:Connect(function()
                game.Players.LocalPlayer:Kick("Executor does not meet the 80% UNC requirements.")
            end)

            BtnBypass.MouseButton1Click:Connect(function()
                UNCGui:Destroy()
                if type(callback) == "function" then callback() end
            end)
        end
    end)
end

--=========================================
-- WINDOW CREATION
--=========================================
function Lonum:CreateWindow(options)
    options = options or {}
    local Title = options.Name or "Lonum Library"
    local Subtitle = options.Subtitle or "Made by Difzz"

    if options.ConfigurationSaving then
        currentConfigFolder = options.ConfigurationSaving.FolderName or "Lonum_Data"
        currentConfigFile = (options.ConfigurationSaving.FileName or "config") .. ".json"
        self:LoadConfig()
    end

    local targetParent = GetSafeParent()

    for _, gui in pairs(targetParent:GetChildren()) do
        if gui.Name == "LonumMainGui" then gui:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LonumMainGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = targetParent

    -- MOBILE TOGGLE BUTTON (Cross-Platform Fallback)
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local MobileBtn = Instance.new("TextButton")
    MobileBtn.Name = "MobileToggle"
    MobileBtn.Size = UDim2.new(0, 45, 0, 45)
    MobileBtn.Position = UDim2.new(0, 20, 0, 20)
    MobileBtn.BackgroundColor3 = Lonum.Theme.SidebarBackground
    MobileBtn.Text = "L"
    MobileBtn.TextColor3 = Lonum.Theme.Accent
    MobileBtn.Font = Lonum.Theme.FontBold
    MobileBtn.TextSize = 20
    MobileBtn.ZIndex = 50
    MobileBtn.AutoButtonColor = false
    MobileBtn.Parent = ScreenGui

    -- Always show mobile button if requested or if on touch device
    if not isMobile then
        MobileBtn.Visible = true -- You can set this to false if you only want it on Mobile
    end

    local MobileCorner = Instance.new("UICorner")
    MobileCorner.CornerRadius = UDim.new(1, 0)
    MobileCorner.Parent = MobileBtn

    local MobileStroke = Instance.new("UIStroke")
    MobileStroke.Color = Lonum.Theme.Accent
    MobileStroke.Thickness = 2
    MobileStroke.Transparency = 0.2
    MobileStroke.Parent = MobileBtn

    MakeDraggable(MobileBtn, MobileBtn)

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0.65, 0, 0.7, 0) -- Responsive Scale Size
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Lonum.Theme.MainBackground
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainSizeConstraint = Instance.new("UISizeConstraint")
    MainSizeConstraint.MaxSize = Vector2.new(700, 480)
    MainSizeConstraint.MinSize = Vector2.new(450, 300)
    MainSizeConstraint.Parent = MainFrame

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
    MainCorner.CornerRadius = Lonum.Theme.CornerRadius
    MainCorner.Parent = MainFrame

    -- SIDEBAR
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0.3, 0, 1, 0) -- Responsive Width
    Sidebar.BackgroundColor3 = Lonum.Theme.SidebarBackground
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarConstraint = Instance.new("UISizeConstraint")
    SidebarConstraint.MaxSize = Vector2.new(190, math.huge)
    SidebarConstraint.MinSize = Vector2.new(140, 0)
    SidebarConstraint.Parent = Sidebar

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = Lonum.Theme.CornerRadius
    SidebarCorner.Parent = Sidebar

    local SidebarHideCorner = Instance.new("Frame")
    SidebarHideCorner.Size = UDim2.new(0, 10, 1, 0)
    SidebarHideCorner.Position = UDim2.new(1, -10, 0, 0)
    SidebarHideCorner.BackgroundColor3 = Lonum.Theme.SidebarBackground
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
    HeaderLine.BackgroundColor3 = Lonum.Theme.ElementBackground
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Parent = Header

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -30, 0, 20)
    TitleLabel.Position = UDim2.new(0, 15, 0, 15)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = Lonum.Theme.Accent
    TitleLabel.Font = Lonum.Theme.FontBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -30, 0, 15)
    SubLabel.Position = UDim2.new(0, 15, 0, 38)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = Subtitle
    SubLabel.TextColor3 = Lonum.Theme.TextDim
    SubLabel.Font = Lonum.Theme.Font
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
    ContentArea.Size = UDim2.new(0.7, 0, 1, 0)
    ContentArea.Position = UDim2.new(0.3, 0, 0, 0)
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
        TabButton.Font = Enum.Font.GothamMedium
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
        TabPage.ScrollBarImageTransparency = 0.15
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

        TabButton.Activated:Connect(function()
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
            SecLabel.Font = Lonum.Theme.FontBold
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
            lbl.Font = Lonum.Theme.Font
            lbl.TextSize = 12
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextWrapped = true
            lbl.AutomaticSize = Enum.AutomaticSize.Y
            lbl.Parent = TabPage

            local LabelObj = {}
            function LabelObj:Set(newText) lbl.Text = newText end
            return LabelObj
        end

        function TabObj:CreateParagraph(options)
            return self:CreateLabel(options.Content or "")
        end

        function TabObj:CreateSplitView(options)
            local columns = math.clamp(options.Columns or 2, 1, 4)
            local spacing = options.Spacing or 8

            local SplitContainer = Instance.new("Frame")
            SplitContainer.Size = UDim2.new(1, 0, 0, 0)
            SplitContainer.BackgroundTransparency = 1
            SplitContainer.AutomaticSize = Enum.AutomaticSize.Y
            SplitContainer.Parent = TabPage

            local SplitLayout = Instance.new("UIListLayout")
            SplitLayout.FillDirection = Enum.FillDirection.Horizontal
            SplitLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SplitLayout.Padding = UDim.new(0, spacing)
            SplitLayout.Parent = SplitContainer

            local Cols = {}
            for i = 1, columns do
                local ColFrame = Instance.new("Frame")
                local colWidth = (1 / columns)
                local offsetDeduction = (spacing * (columns - 1)) / columns
                ColFrame.Size = UDim2.new(colWidth, -offsetDeduction, 0, 0)
                ColFrame.BackgroundTransparency = 1
                ColFrame.AutomaticSize = Enum.AutomaticSize.Y
                ColFrame.Parent = SplitContainer

                local ColLayout = Instance.new("UIListLayout")
                ColLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ColLayout.Padding = UDim.new(0, 8)
                ColLayout.Parent = ColFrame

                -- Dummy builder functions inside each column
                local ColObj = { Frame = ColFrame }

                function ColObj:CreateSection(name)
                    local SecLabel = Instance.new("TextLabel")
                    SecLabel.Size = UDim2.new(1, 0, 0, 30)
                    SecLabel.BackgroundTransparency = 1
                    SecLabel.Text = string.upper(name)
                    SecLabel.TextColor3 = Lonum.Theme.Accent
                    SecLabel.Font = Lonum.Theme.FontBold
                    SecLabel.TextSize = 13
                    SecLabel.TextXAlignment = Enum.TextXAlignment.Left
                    SecLabel.TextYAlignment = Enum.TextYAlignment.Bottom
                    SecLabel.Parent = ColFrame
                end

                function ColObj:CreateLabel(text)
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, 0, 0, 20)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = text
                    lbl.TextColor3 = Lonum.Theme.TextDim
                    lbl.Font = Lonum.Theme.Font
                    lbl.TextSize = 12
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.TextWrapped = true
                    lbl.AutomaticSize = Enum.AutomaticSize.Y
                    lbl.Parent = ColFrame

                    local LabelObj = {}
                    function LabelObj:Set(newText) lbl.Text = newText end
                    return LabelObj
                end

                function ColObj:CreateCard(options)
                    local CardFrame = Instance.new("Frame")
                    CardFrame.Size = UDim2.new(1, 0, 0, 0)
                    CardFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
                    CardFrame.AutomaticSize = Enum.AutomaticSize.Y
                    CardFrame.Parent = ColFrame

                    local CardCorner = Instance.new("UICorner")
                    CardCorner.CornerRadius = Lonum.Theme.CornerRadius
                    CardCorner.Parent = CardFrame

                    local CardStroke = Instance.new("UIStroke")
                    CardStroke.Color = Color3.fromRGB(255, 255, 255)
                    CardStroke.Transparency = 0.95
                    CardStroke.Parent = CardFrame

                    local CPad = Instance.new("UIPadding")
                    CPad.PaddingTop = UDim.new(0, 10)
                    CPad.PaddingBottom = UDim.new(0, 10)
                    CPad.PaddingLeft = UDim.new(0, 10)
                    CPad.PaddingRight = UDim.new(0, 10)
                    CPad.Parent = CardFrame

                    local CLayout = Instance.new("UIListLayout")
                    CLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    CLayout.Padding = UDim.new(0, 4)
                    CLayout.Parent = CardFrame

                    local titleLbl = Instance.new("TextLabel")
                    titleLbl.Size = UDim2.new(1, 0, 0, 16)
                    titleLbl.BackgroundTransparency = 1
                    titleLbl.Text = options.Title or ""
                    titleLbl.TextColor3 = Lonum.Theme.TextTitle
                    titleLbl.Font = Lonum.Theme.FontBold
                    titleLbl.TextSize = 13
                    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                    titleLbl.TextWrapped = true
                    titleLbl.AutomaticSize = Enum.AutomaticSize.Y
                    titleLbl.Parent = CardFrame

                    local contentLbl = Instance.new("TextLabel")
                    contentLbl.Size = UDim2.new(1, 0, 0, 14)
                    contentLbl.BackgroundTransparency = 1
                    contentLbl.Text = options.Content or ""
                    contentLbl.TextColor3 = Lonum.Theme.TextDim
                    contentLbl.Font = Lonum.Theme.Font
                    contentLbl.TextSize = 11
                    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
                    contentLbl.TextWrapped = true
                    contentLbl.AutomaticSize = Enum.AutomaticSize.Y
                    contentLbl.Parent = CardFrame

                    local CardObj = { Frame = CardFrame }
                    function CardObj:SetContent(newText) contentLbl.Text = newText end
                    function CardObj:SetTitle(newText) titleLbl.Text = newText end
                    function CardObj:Destroy() CardFrame:Destroy() end
                    return CardObj
                end

                table.insert(Cols, ColObj)
            end

            local SplitObj = {
                Columns = Cols,
                Container = SplitContainer
            }
            return SplitObj
        end

        function TabObj:CreateButton(options)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 42)
            btn.BackgroundColor3 = Lonum.Theme.ElementBackground
            btn.Text = options.Name or "Button"
            btn.TextColor3 = Lonum.Theme.TextTitle
            btn.Font = Enum.Font.GothamMedium
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
            btn.Activated:Connect(function()
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
            tFrame.AutomaticSize = Enum.AutomaticSize.Y
            tFrame.Parent = TabPage

            local tCorner = Instance.new("UICorner")
            tCorner.CornerRadius = Lonum.Theme.CornerRadius
            tCorner.Parent = tFrame

            local tStroke = Instance.new("UIStroke")
            tStroke.Color = Color3.fromRGB(255,255,255)
            tStroke.Transparency = 0.95
            tStroke.Parent = tFrame

            local tLabel = Instance.new("TextLabel")
            tLabel.Size = UDim2.new(1, -60, 0, 42)
            tLabel.Position = UDim2.new(0, 15, 0, 0)
            tLabel.BackgroundTransparency = 1
            tLabel.Text = options.Name or "Toggle"
            tLabel.TextColor3 = Lonum.Theme.TextNormal
            tLabel.Font = Lonum.Theme.Font
            tLabel.TextSize = 13
            tLabel.TextXAlignment = Enum.TextXAlignment.Left
            tLabel.TextWrapped = true
            tLabel.AutomaticSize = Enum.AutomaticSize.Y
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

            -- Sinkronisasikan state konfigurasi awal secara aman HANYA JIKA aktif
            -- Mencegah "false" callbacks merusak workerGeneration skrip saat loading
            if options.Callback and State == true then
                pcall(function() options.Callback(State) end)
            end

            local function Fire()
                if options.Callback then pcall(function() options.Callback(State) end) end
                configData[flag] = State
                Lonum:SaveConfig()
            end

            tFrame.Activated:Connect(function()
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
            sFrame.AutomaticSize = Enum.AutomaticSize.Y
            sFrame.Parent = TabPage

            local sCorner = Instance.new("UICorner")
            sCorner.CornerRadius = Lonum.Theme.CornerRadius
            sCorner.Parent = sFrame

            local sStroke = Instance.new("UIStroke")
            sStroke.Color = Color3.fromRGB(255,255,255)
            sStroke.Transparency = 0.95
            sStroke.Parent = sFrame

            local sLabel = Instance.new("TextLabel")
            sLabel.Size = UDim2.new(1, -60, 0, 20)
            sLabel.Position = UDim2.new(0, 15, 0, 10)
            sLabel.BackgroundTransparency = 1
            sLabel.Text = options.Name or "Slider"
            sLabel.TextColor3 = Lonum.Theme.TextNormal
            sLabel.Font = Lonum.Theme.Font
            sLabel.TextSize = 13
            sLabel.TextXAlignment = Enum.TextXAlignment.Left
            sLabel.TextWrapped = true
            sLabel.AutomaticSize = Enum.AutomaticSize.Y
            sLabel.Parent = sFrame

            local sValLabel = Instance.new("TextLabel")
            sValLabel.Size = UDim2.new(0, 50, 0, 20)
            sValLabel.Position = UDim2.new(1, -65, 0, 10)
            sValLabel.BackgroundTransparency = 1
            sValLabel.Text = tostring(defaultVal)
            sValLabel.TextColor3 = Lonum.Theme.Accent
            sValLabel.Font = Lonum.Theme.FontBold
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

            -- Sinkronisasikan state konfigurasi awal secara aman
            sValLabel.Text = tostring(Value)
            if options.Callback then
                pcall(function() options.Callback(Value) end)
            end

            local function Fire()
                sValLabel.Text = tostring(Value)
                if options.Callback then pcall(function() options.Callback(Value) end) end
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
            dTitle.Size = UDim2.new(0.5, -5, 0, 42)
            dTitle.Position = UDim2.new(0, 15, 0, 0)
            dTitle.BackgroundTransparency = 1
            dTitle.Text = options.Name or "Dropdown"
            dTitle.TextColor3 = Lonum.Theme.TextNormal
            dTitle.Font = Lonum.Theme.Font
            dTitle.TextSize = 13
            dTitle.TextXAlignment = Enum.TextXAlignment.Left
            dTitle.TextWrapped = true
            dTitle.Parent = dropBtn

            local dValue = Instance.new("TextLabel")
            dValue.Size = UDim2.new(0.5, -20, 0, 42)
            dValue.Position = UDim2.new(0.5, 0, 0, 0)
            dValue.BackgroundTransparency = 1
            dValue.Text = (options.CurrentOption and options.CurrentOption[1] or "") .. " ▾"
            dValue.TextColor3 = Lonum.Theme.TextDim
            dValue.Font = Lonum.Theme.Font
            dValue.TextSize = 12
            dValue.TextXAlignment = Enum.TextXAlignment.Right
            dValue.TextWrapped = true
            dValue.Parent = dropBtn

            local isOpen = false
            local optionContainer = Instance.new("ScrollingFrame")
            optionContainer.Size = UDim2.new(1, 0, 1, -42)
            optionContainer.Position = UDim2.new(0, 0, 0, 42)
            optionContainer.BackgroundTransparency = 1
            optionContainer.ScrollBarThickness = 3
            optionContainer.ScrollBarImageColor3 = Lonum.Theme.TextDim
            optionContainer.BorderSizePixel = 0
            optionContainer.Visible = false
            optionContainer.Parent = dropFrame

            local optLayout = Instance.new("UIListLayout")
            optLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optLayout.Parent = optionContainer

            optLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                optionContainer.CanvasSize = UDim2.new(0, 0, 0, optLayout.AbsoluteContentSize.Y)
            end)

            local flag = options.Flag or options.Name
            local selected = options.CurrentOption and options.CurrentOption[1] or ""

            if configData[flag] ~= nil then
                selected = configData[flag]
            end

            -- Initial state sync
            dValue.Text = selected .. " ▾"
            if options.Callback then
                pcall(function() options.Callback({selected}) end)
            end

            local function Fire(val)
                selected = val
                dValue.Text = selected .. " ▾"
                if options.Callback then pcall(function() options.Callback({selected}) end) end
                configData[flag] = selected
                Lonum:SaveConfig()
            end

            local function GetTargetHeight()
                local optCount = #(options.Options or {})
                if optCount == 0 then return 42 end
                local visibleOpts = math.min(optCount, 4) -- Limit to showing max 4 items at once
                return 42 + (visibleOpts * 35)
            end

            local function PopulateOptions(newOpts)
                for _, child in ipairs(optionContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, opt in ipairs(newOpts or {}) do
                    local oBtn = Instance.new("TextButton")
                    oBtn.Size = UDim2.new(1, -8, 0, 35) -- Leave space for scrollbar
                    oBtn.BackgroundColor3 = Lonum.Theme.ElementBackground
                    oBtn.Text = "    " .. opt
                    oBtn.TextColor3 = Lonum.Theme.TextDim
                    oBtn.Font = Lonum.Theme.Font
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
                    oBtn.Activated:Connect(function()
                        Fire(opt)
                        isOpen = false
                        TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 42)}):Play()
                        task.delay(0.3, function() if not isOpen then optionContainer.Visible = false end end)
                    end)
                end
                options.Options = newOpts
            end

            PopulateOptions(options.Options)

            dropBtn.Activated:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    optionContainer.Visible = true
                    local targetHeight = GetTargetHeight()
                    TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
                else
                    TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 42)}):Play()
                    task.delay(0.3, function() if not isOpen then optionContainer.Visible = false end end)
                end
            end)

            local DropObj = {}
            function DropObj:Refresh(newOpts)
                PopulateOptions(newOpts)
                if isOpen then
                    local targetHeight = GetTargetHeight()
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
            if options.Callback then
                pcall(function() options.Callback(defaultVal) end)
            end

            local kFrame = Instance.new("Frame")
            kFrame.Size = UDim2.new(1, 0, 0, 42)
            kFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
            kFrame.AutomaticSize = Enum.AutomaticSize.Y
            kFrame.Parent = TabPage

            local kCorner = Instance.new("UICorner")
            kCorner.CornerRadius = Lonum.Theme.CornerRadius
            kCorner.Parent = kFrame

            local kStroke = Instance.new("UIStroke")
            kStroke.Color = Color3.fromRGB(255,255,255)
            kStroke.Transparency = 0.95
            kStroke.Parent = kFrame

            local kLabel = Instance.new("TextLabel")
            kLabel.Size = UDim2.new(1, -100, 0, 42)
            kLabel.Position = UDim2.new(0, 15, 0, 0)
            kLabel.BackgroundTransparency = 1
            kLabel.Text = options.Name or "Keybind"
            kLabel.TextColor3 = Lonum.Theme.TextNormal
            kLabel.Font = Lonum.Theme.Font
            kLabel.TextSize = 13
            kLabel.TextXAlignment = Enum.TextXAlignment.Left
            kLabel.TextWrapped = true
            kLabel.AutomaticSize = Enum.AutomaticSize.Y
            kLabel.Parent = kFrame

            local kBtn = Instance.new("TextButton")
            kBtn.Size = UDim2.new(0, 80, 0, 26)
            kBtn.Position = UDim2.new(1, -95, 0.5, -13)
            kBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            kBtn.Text = defaultVal.Name
            kBtn.TextColor3 = Lonum.Theme.Accent
            kBtn.Font = Lonum.Theme.FontBold
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

            kBtn.Activated:Connect(function()
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

    -- Mobile Button Click Toggle
    MobileBtn.Activated:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    -- Toggle UI Visibility Logic (Keyboard)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end -- Don't trigger if typing in chat
        if input.KeyCode == Lonum.ToggleKey then
            MainFrame.Visible = not MainFrame.Visible
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

    local targetParent = GetSafeParent()

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
    nFrame.BackgroundColor3 = Lonum.Theme.ElementBackground
    nFrame.AutomaticSize = Enum.AutomaticSize.Y
    nFrame.Parent = NotifContainer

    local nPadFrame = Instance.new("UIPadding")
    nPadFrame.PaddingBottom = UDim.new(0, 12)
    nPadFrame.Parent = nFrame

    local nCorner = Instance.new("UICorner")
    nCorner.CornerRadius = Lonum.Theme.CornerRadius
    nCorner.Parent = nFrame

    local nStroke = Instance.new("UIStroke")
    nStroke.Color = Color3.fromRGB(255,255,255)
    nStroke.Transparency = 0.95
    nStroke.Parent = nFrame

    local nLine = Instance.new("Frame")
    nLine.Size = UDim2.new(0, 3, 1, -24)
    nLine.Position = UDim2.new(0, 8, 0, 12)
    nLine.BackgroundColor3 = Lonum.Theme.Accent
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
    nTitle.TextColor3 = Lonum.Theme.TextTitle
    nTitle.Font = Lonum.Theme.FontBold
    nTitle.TextSize = 12
    nTitle.TextXAlignment = Enum.TextXAlignment.Left
    nTitle.Parent = nFrame

    local nText = Instance.new("TextLabel")
    nText.Size = UDim2.new(1, -26, 0, 20)
    nText.Position = UDim2.new(0, 18, 0, 28)
    nText.BackgroundTransparency = 1
    nText.Text = Content
    nText.TextColor3 = Lonum.Theme.TextDim
    nText.Font = Lonum.Theme.Font
    nText.TextSize = 11
    nText.TextXAlignment = Enum.TextXAlignment.Left
    nText.TextYAlignment = Enum.TextYAlignment.Top
    nText.TextWrapped = true
    nText.AutomaticSize = Enum.AutomaticSize.Y
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
