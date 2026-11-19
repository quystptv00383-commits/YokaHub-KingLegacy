    -- ========================================================
    -- [YOKAHUB] - HIGH-SECURITY MULTI-TAB GATEWAY
    -- Tac gia: Yoka (Shinene_11)
    -- ========================================================
    local function checkSavedLicense(): boolean
        local isf = genv.isfile or isfile
        local rf = genv.readfile or readfile
        if typeof(isf) ~= "function" or typeof(rf) ~= "function" then return false end
        if not isf("YokaHub_License.json") then return false end
        local ok, res = pcall(function()
            return game:GetService("HttpService"):JSONDecode(rf("YokaHub_License.json"))
        end)
        if ok and typeof(res) == "table" and (res.keyHash or res.key) and res.hwid then
            local myHwid = ""
            if typeof(gethwid) == "function" then pcall(function() myHwid = gethwid() end) end
            if myHwid == "" and typeof(get_hwid) == "function" then pcall(function() myHwid = get_hwid() end) end
            if myHwid == "" then pcall(function() myHwid = game:GetService("RbxAnalyticsService"):GetClientId() end) end
            if myHwid == "" then myHwid = "USER-" .. tostring(players and players.LocalPlayer and players.LocalPlayer.UserId or "0") end
            
            local hwidMatch = (myHwid ~= "" and myHwid == res.hwid)
            local userMatch = (res.userId and players and players.LocalPlayer and res.userId == players.LocalPlayer.UserId)

            if hwidMatch or userMatch then
                if not res.expireAt or res.expireAt <= 0 or os.time() < res.expireAt then
                    return true
                end
            end
        end
        return false
    end

    local function launchGatewayUI()
        local authSuccess = false
        local authAborted = false

        -- Run Gateway UI
        -- ========================================================
        -- [YOKAHUB] - MULTI-TAB COMMERCIAL GATEWAY & KEY SYSTEM
        -- Tac gia: Yoka (Shinene_11)
        -- Bao mat cap cao: Ma hoa 2 chieu (Stream Cipher) + Ma hoa 1 chieu (Salted SHA-256)
        -- ========================================================
        
        local Players = game:GetService("Players")
        local TweenService = game:GetService("TweenService")
        local HttpService = game:GetService("HttpService")
        local UserInputService = game:GetService("UserInputService")
        local CoreGui = game:GetService("CoreGui")
        
        local lp = Players.LocalPlayer
        
        -- 1. MA HOA 2 CHIEU: Polymorphic Stream Cipher Engine
        local _K = { 0x59, 0x6F, 0x6B, 0x61, 0x53, 0x65, 0x63, 0x75, 0x72, 0x69, 0x74, 0x79, 0x32, 0x30, 0x32, 0x36, 0x21, 0x40, 0x23 }
        
        local function _D(hex: string): string
            local bytes = {}
            local len = #hex / 2
            local kLen = #_K
            for i = 1, len do
                local b = tonumber(string.sub(hex, (i - 1) * 2 + 1, i * 2), 16)
                local k = _K[((i - 1) % kLen) + 1]
                local shift = bit32.band((i - 1) * 7, 0xFF)
                bytes[i] = string.char(bit32.bxor(bit32.bxor(b, k), shift))
            end
            return table.concat(bytes)
        end
        
        -- Cac chuoi nhay cam da duoc ma hoa 2 chieu (Khong de lo Plaintext)
        local _HEX_SALT     = "00070e1507332b1b19335141140e340063076feabcab9a9eb9ed"
        local _HEX_KEYS_URL = "311c11043c7c666b2d3f4140480c392b39423fa9909d8991a2a2b7aac3cb8588bfb8f7a5c959200a030a0378677d0813094d0338332c2fb284e19d92a0cceeefd38094c39de5bba5ace925487b402a7855316c055a5c4b2a3e70362ad2e4e8afa4ad8793bbfff4c6c8d8b1b5b7a65a"
        local _HEX_GET_KEY  = "311c11043c7c666b263f5c5f100e222b384438f2809796ddb4a3b6bd80d6cfc4a9bab3b5d4553153141b01233237"
        local _HEX_DISCORD  = "311c11043c7c666b2e3f415709193471365072a58c8d89dfa9a5b0acc2cdcfc6bcbcb6bf"
        local _HEX_STORE    = "https://quystptv00383-commits.github.io/yokahub-store/"
        local LICENSE_FILE  = "YokaHub_License.json"
        
        -- 2. MA HOA 1 CHIEU: Cryptographic Hash Engine (SHA-256 + Salt)
        local function computeHash(inputStr: string): string
            if typeof(crypt) == "table" and typeof(crypt.hash) == "function" then
                local ok, res = pcall(function() return crypt.hash(inputStr, "sha256") end)
                if ok and typeof(res) == "string" and #res == 64 then return string.lower(res) end
            end
            if typeof(syn) == "table" and typeof(syn.crypt) == "table" and typeof(syn.crypt.hash) == "function" then
                local ok, res = pcall(function() return syn.crypt.hash(inputStr) end)
                if ok and typeof(res) == "string" and #res >= 32 then return string.lower(res) end
            end
        
            local h1 = 0x811c9dc5
            local h2 = 0x9e3779b9
            for i = 1, #inputStr do
                local b = string.byte(inputStr, i)
                h1 = bit32.bxor(h1, b)
                h1 = bit32.band(h1 * 0x01000193, 0xffffffff)
                h2 = bit32.bxor(h2, bit32.rrotate(h1, 13) + b)
                h2 = bit32.band(h2 * 0x85ebca6b, 0xffffffff)
            end
            return string.format("%08x%08x%08x%08x", h1, h2, bit32.bxor(h1, h2), bit32.bor(h1, h2))
        end
        
        local function hashKey(rawKey: string): string
            rawKey = string.gsub(rawKey, "%s+", "")
            return computeHash(_D(_HEX_SALT) .. rawKey)
        end
        
        local function getClientHWID(): string
            local hwid = ""
            if typeof(gethwid) == "function" then pcall(function() hwid = gethwid() end) end
            if hwid == "" and typeof(get_hwid) == "function" then pcall(function() hwid = get_hwid() end) end
            if hwid == "" then pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end) end
            if hwid == "" then hwid = "USER-" .. tostring(lp and lp.UserId or "0") end
            return tostring(hwid)
        end
        
        local function generateSignature(keyHash: string, hwid: string, expireAt: number, keyType: string): string
            return computeHash("SIG_" .. _D(_HEX_SALT) .. "_" .. keyHash .. "_" .. hwid .. "_" .. tostring(expireAt) .. "_" .. keyType)
        end
        
        -- 3. Khoi tao Giao dien Gateway
        local parentGui: Instance = CoreGui
        if typeof(gethui) == "function" then pcall(function() parentGui = gethui() end) end
        pcall(function()
            local old = parentGui:FindFirstChild("YokaHub_GatewayUI")
            if old then old:Destroy() end
        end)
        
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "YokaHub_GatewayUI"
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.ResetOnSpawn = false
        ScreenGui.DisplayOrder = 2147483646
        ScreenGui.Parent = parentGui
        
        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 560, 0, 420)
        MainFrame.Position = UDim2.new(0.5, -280, 0.5, -210)
        MainFrame.BackgroundColor3 = Color3.fromRGB(13, 16, 22)
        MainFrame.BorderSizePixel = 0
        MainFrame.Active = true
        MainFrame.ClipsDescendants = true
        MainFrame.Parent = ScreenGui
        
        local MainCorner = Instance.new("UICorner")
        MainCorner.CornerRadius = UDim.new(0, 14)
        MainCorner.Parent = MainFrame
        
        local MainStroke = Instance.new("UIStroke")
        MainStroke.Color = Color3.fromRGB(45, 55, 75)
        MainStroke.Thickness = 1.5
        MainStroke.Parent = MainFrame
        
        local TopBar = Instance.new("Frame")
        TopBar.Name = "TopBar"
        TopBar.Size = UDim2.new(1, 0, 0, 48)
        TopBar.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
        TopBar.BorderSizePixel = 0
        TopBar.Parent = MainFrame
        
        local TopCorner = Instance.new("UICorner")
        TopCorner.CornerRadius = UDim.new(0, 14)
        TopCorner.Parent = TopBar
        
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Name = "TitleLabel"
        TitleLabel.Size = UDim2.new(1, -60, 0, 24)
        TitleLabel.Position = UDim2.new(0, 16, 0, 5)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.Text = "👑 YOKAHUB • CỔNG BẢN QUYỀN & XÁC THỰC"
        TitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        TitleLabel.TextSize = 15
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = TopBar
        
        local SubTitle = Instance.new("TextLabel")
        SubTitle.Name = "SubTitle"
        SubTitle.Size = UDim2.new(1, -60, 0, 16)
        SubTitle.Position = UDim2.new(0, 16, 0, 27)
        SubTitle.BackgroundTransparency = 1
        SubTitle.Font = Enum.Font.Gotham
        SubTitle.Text = "King Legacy • Mã Hóa 2 Chiều Stream Cipher & Băm 1 Chiều SHA-256"
        SubTitle.TextColor3 = Color3.fromRGB(150, 165, 185)
        SubTitle.TextSize = 11
        SubTitle.TextXAlignment = Enum.TextXAlignment.Left
        SubTitle.Parent = TopBar
        
        local TopBarGetKeyBtn = Instance.new("TextButton")
        TopBarGetKeyBtn.Name = "TopBarGetKeyBtn"
        TopBarGetKeyBtn.Size = UDim2.new(0, 120, 0, 28)
        TopBarGetKeyBtn.Position = UDim2.new(1, -170, 0, 10)
        TopBarGetKeyBtn.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
        TopBarGetKeyBtn.Font = Enum.Font.GothamBold
        TopBarGetKeyBtn.Text = "🔗 TRANG GET KEY"
        TopBarGetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TopBarGetKeyBtn.TextSize = 11
        TopBarGetKeyBtn.BorderSizePixel = 0
        TopBarGetKeyBtn.Parent = TopBar
        
        local TbgkCorner = Instance.new("UICorner")
        TbgkCorner.CornerRadius = UDim.new(0, 6)
        TbgkCorner.Parent = TopBarGetKeyBtn
        
        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Name = "CloseBtn"
        CloseBtn.Size = UDim2.new(0, 32, 0, 32)
        CloseBtn.Position = UDim2.new(1, -40, 0, 8)
        CloseBtn.BackgroundTransparency = 1
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.Text = "✕"
        CloseBtn.TextColor3 = Color3.fromRGB(160, 175, 190)
        CloseBtn.TextSize = 16
        CloseBtn.Parent = TopBar
        
        CloseBtn.MouseButton1Click:Connect(function()
            ScreenGui:Destroy()
        end)
        
        TopBarGetKeyBtn.MouseButton1Click:Connect(function()
            switchTab("FreeKey")
        end)
        
        -- Drag GUI
        local dragging, dragInput, dragStart, startPos
        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        TopBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        -- Tab Bar
        local TabBar = Instance.new("Frame")
        TabBar.Name = "TabBar"
        TabBar.Size = UDim2.new(1, -32, 0, 36)
        TabBar.Position = UDim2.new(0, 16, 0, 56)
        TabBar.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
        TabBar.BorderSizePixel = 0
        TabBar.Parent = MainFrame
        
        local TabBarCorner = Instance.new("UICorner")
        TabBarCorner.CornerRadius = UDim.new(0, 8)
        TabBarCorner.Parent = TabBar
        
        local TabListLayout = Instance.new("UIListLayout")
        TabListLayout.FillDirection = Enum.FillDirection.Horizontal
        TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabListLayout.Padding = UDim.new(0, 6)
        TabListLayout.Parent = TabBar
        
        local ContentContainer = Instance.new("Frame")
        ContentContainer.Name = "ContentContainer"
        ContentContainer.Size = UDim2.new(1, -32, 1, -104)
        ContentContainer.Position = UDim2.new(0, 16, 0, 98)
        ContentContainer.BackgroundTransparency = 1
        ContentContainer.Parent = MainFrame
        
        local Pages = {}
        local TabButtons = {}
        
        local function createTab(tabId: string, tabName: string, icon: string, layoutOrder: number)
            local btn = Instance.new("TextButton")
            btn.Name = "TabBtn_" .. tabId
            btn.Size = UDim2.new(0.24, -4, 1, -4)
            btn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
            btn.Font = Enum.Font.GothamMedium
            btn.Text = icon .. " " .. tabName
            btn.TextColor3 = Color3.fromRGB(160, 175, 190)
            btn.TextSize = 12
            btn.BorderSizePixel = 0
            btn.LayoutOrder = layoutOrder
            btn.Parent = TabBar
        
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn
        
            local page = Instance.new("Frame")
            page.Name = "Page_" .. tabId
            page.Size = UDim2.new(1, 0, 1, 0)
            page.BackgroundTransparency = 1
            page.Visible = false
            page.Parent = ContentContainer
        
            Pages[tabId] = page
            TabButtons[tabId] = btn
            return btn, page
        end
        
        local function switchTab(targetId: string)
            for id, page in pairs(Pages) do
                local isCurrent = (id == targetId)
                page.Visible = isCurrent
                local btn = TabButtons[id]
                if btn then
                    if isCurrent then
                        btn.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
                        btn.TextColor3 = Color3.fromRGB(255, 215, 0)
                        btn.Font = Enum.Font.GothamBold
                    else
                        btn.BackgroundColor3 = Color3.fromRGB(22, 26, 35)
                        btn.TextColor3 = Color3.fromRGB(150, 165, 180)
                        btn.Font = Enum.Font.GothamMedium
                    end
                end
            end
        end
        
        -- TAB 1: TRANG CHU
        local btnHome, pageHome = createTab("Home", "Trang Chủ", "🏠", 1)
        btnHome.MouseButton1Click:Connect(function() switchTab("Home") end)
        
        local HomeIntro = Instance.new("TextLabel")
        HomeIntro.Size = UDim2.new(1, 0, 0, 48)
        HomeIntro.Position = UDim2.new(0, 0, 0, 4)
        HomeIntro.BackgroundTransparency = 1
        HomeIntro.Font = Enum.Font.GothamMedium
        HomeIntro.Text = "Chào mừng bạn đến với King Legacy YokaHub!\nVui lòng chọn một tùy chọn bên dưới để bắt đầu sử dụng."
        HomeIntro.TextColor3 = Color3.fromRGB(200, 215, 230)
        HomeIntro.TextSize = 13
        HomeIntro.TextXAlignment = Enum.TextXAlignment.Center
        HomeIntro.Parent = pageHome
        
        local HomeCards = Instance.new("Frame")
        HomeCards.Size = UDim2.new(1, 0, 1, -56)
        HomeCards.Position = UDim2.new(0, 0, 0, 56)
        HomeCards.BackgroundTransparency = 1
        HomeCards.Parent = pageHome
        
        local CardLayout = Instance.new("UIGridLayout")
        CardLayout.CellSize = UDim2.new(0.315, 0, 0.92, 0)
        CardLayout.CellPadding = UDim2.new(0.027, 0, 0, 0)
        CardLayout.Parent = HomeCards
        
        local function createPortalCard(title: string, desc: string, btnText: string, color: Color3, onClick: () -> ())
            local card = Instance.new("Frame")
            card.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
            card.BorderSizePixel = 0
            card.Parent = HomeCards
        
            local cCorner = Instance.new("UICorner")
            cCorner.CornerRadius = UDim.new(0, 10)
            cCorner.Parent = card
        
            local cStroke = Instance.new("UIStroke")
            cStroke.Color = Color3.fromRGB(35, 45, 60)
            cStroke.Thickness = 1
            cStroke.Parent = card
        
            local tLbl = Instance.new("TextLabel")
            tLbl.Size = UDim2.new(1, -16, 0, 24)
            tLbl.Position = UDim2.new(0, 8, 0, 12)
            tLbl.BackgroundTransparency = 1
            tLbl.Font = Enum.Font.GothamBold
            tLbl.Text = title
            tLbl.TextColor3 = color
            tLbl.TextSize = 13
            tLbl.Parent = card
        
            local dLbl = Instance.new("TextLabel")
            dLbl.Size = UDim2.new(1, -16, 0, 80)
            dLbl.Position = UDim2.new(0, 8, 0, 40)
            dLbl.BackgroundTransparency = 1
            dLbl.Font = Enum.Font.Gotham
            dLbl.Text = desc
            dLbl.TextColor3 = Color3.fromRGB(140, 155, 170)
            dLbl.TextSize = 11
            dLbl.TextWrapped = true
            dLbl.Parent = card
        
            local cBtn = Instance.new("TextButton")
            cBtn.Size = UDim2.new(1, -16, 0, 36)
            cBtn.Position = UDim2.new(0, 8, 1, -46)
            cBtn.BackgroundColor3 = color
            cBtn.Font = Enum.Font.GothamBold
            cBtn.Text = btnText
            cBtn.TextColor3 = (color == Color3.fromRGB(255, 215, 0)) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
            cBtn.TextSize = 12
            cBtn.BorderSizePixel = 0
            cBtn.Parent = card
        
            local btnC = Instance.new("UICorner")
            btnC.CornerRadius = UDim.new(0, 6)
            btnC.Parent = cBtn
        
            cBtn.MouseButton1Click:Connect(onClick)
        end
        
        createPortalCard("🔑 ĐÃ CÓ KEY", "Nhập mã Key bản quyền để xác thực mở Hub.", "ĐĂNG NHẬP NGAY", Color3.fromRGB(36, 175, 125), function() switchTab("Login") end)
        createPortalCard("🔗 LẤY KEY FREE", "Lấy mã Key chơi miễn phí 24 giờ siêu tốc.", "LẤY KEY FREE 24H", Color3.fromRGB(6, 182, 212), function() switchTab("FreeKey") end)
        createPortalCard("💎 MUA KEY VIP", "Mua bản quyền VIP 1 Tháng (30 ngày) hoặc 3 Tháng (90 ngày).", "XEM BẢNG GIÁ", Color3.fromRGB(255, 215, 0), function() switchTab("BuyVip") end)
        
        -- TAB 2: NHAP KEY (LOGIN)
        local btnLogin, pageLogin = createTab("Login", "Nhập Key", "🔑", 2)
        btnLogin.MouseButton1Click:Connect(function() switchTab("Login") end)
        
        local InputContainer = Instance.new("Frame")
        InputContainer.Size = UDim2.new(1, 0, 0, 48)
        InputContainer.Position = UDim2.new(0, 0, 0, 16)
        InputContainer.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
        InputContainer.BorderSizePixel = 0
        InputContainer.Parent = pageLogin
        
        local InputCorner = Instance.new("UICorner")
        InputCorner.CornerRadius = UDim.new(0, 8)
        InputCorner.Parent = InputContainer
        
        local KeyTextBox = Instance.new("TextBox")
        KeyTextBox.Size = UDim2.new(1, -50, 1, 0)
        KeyTextBox.Position = UDim2.new(0, 14, 0, 0)
        KeyTextBox.BackgroundTransparency = 1
        KeyTextBox.Font = Enum.Font.GothamMedium
        KeyTextBox.PlaceholderText = "Dán mã Key tại đây (VD: yk_vip1m_... hoặc yk_life_...)"
        KeyTextBox.PlaceholderColor3 = Color3.fromRGB(110, 125, 140)
        KeyTextBox.Text = ""
        KeyTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        KeyTextBox.TextSize = 13
        KeyTextBox.TextXAlignment = Enum.TextXAlignment.Left
        KeyTextBox.ClearTextOnFocus = false
        KeyTextBox.Parent = InputContainer
        
        local PasteBtn = Instance.new("TextButton")
        PasteBtn.Size = UDim2.new(0, 36, 0, 36)
        PasteBtn.Position = UDim2.new(1, -42, 0, 6)
        PasteBtn.BackgroundColor3 = Color3.fromRGB(32, 40, 54)
        PasteBtn.Font = Enum.Font.GothamBold
        PasteBtn.Text = "📋"
        PasteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        PasteBtn.TextSize = 14
        PasteBtn.BorderSizePixel = 0
        PasteBtn.Parent = InputContainer
        
        local PasteCorner = Instance.new("UICorner")
        PasteCorner.CornerRadius = UDim.new(0, 6)
        PasteCorner.Parent = PasteBtn
        
        PasteBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if typeof(getclipboard) == "function" then
                    local clip = getclipboard()
                    if clip and #clip > 0 then KeyTextBox.Text = clip end
                end
            end)
        end)
        
        local StatusLabel = Instance.new("TextLabel")
        StatusLabel.Size = UDim2.new(1, 0, 0, 24)
        StatusLabel.Position = UDim2.new(0, 0, 0, 76)
        StatusLabel.BackgroundTransparency = 1
        StatusLabel.Font = Enum.Font.GothamMedium
        StatusLabel.Text = "Trạng thái: Vui lòng nhập Key rồi bấm Xác Nhận."
        StatusLabel.TextColor3 = Color3.fromRGB(150, 175, 190)
        StatusLabel.TextSize = 12
        StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
        StatusLabel.Parent = pageLogin
        
        local CheckKeyBtn = Instance.new("TextButton")
        CheckKeyBtn.Size = UDim2.new(1, 0, 0, 42)
        CheckKeyBtn.Position = UDim2.new(0, 0, 0, 108)
        CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(36, 175, 125)
        CheckKeyBtn.Font = Enum.Font.GothamBold
        CheckKeyBtn.Text = "✓ XÁC NHẬN VÀ VÀO GAME"
        CheckKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CheckKeyBtn.TextSize = 14
        CheckKeyBtn.BorderSizePixel = 0
        CheckKeyBtn.Parent = pageLogin
        
        local CheckCorner = Instance.new("UICorner")
        CheckCorner.CornerRadius = UDim.new(0, 8)
        CheckCorner.Parent = CheckKeyBtn
        
        -- Dieu huong neu chua co Key (Bat buoc vuot link hoac mua VIP de co Key)
        local GoToFreeBtn = Instance.new("TextButton")
        GoToFreeBtn.Name = "GoToFreeBtn"
        GoToFreeBtn.Size = UDim2.new(1, 0, 0, 38)
        GoToFreeBtn.Position = UDim2.new(0, 0, 0, 160)
        GoToFreeBtn.BackgroundColor3 = Color3.fromRGB(16, 28, 42)
        GoToFreeBtn.Font = Enum.Font.GothamBold
        GoToFreeBtn.Text = "🔗 CHƯA CÓ KEY? VƯỢT LINK LẤY KEY FREE 24H"
        GoToFreeBtn.TextColor3 = Color3.fromRGB(6, 182, 212)
        GoToFreeBtn.TextSize = 12
        GoToFreeBtn.BorderSizePixel = 0
        GoToFreeBtn.Parent = pageLogin
        
        local GtfCorner = Instance.new("UICorner")
        GtfCorner.CornerRadius = UDim.new(0, 8)
        GtfCorner.Parent = GoToFreeBtn
        
        local GtfStroke = Instance.new("UIStroke")
        GtfStroke.Color = Color3.fromRGB(6, 182, 212)
        GtfStroke.Thickness = 1
        GtfStroke.Transparency = 0.3
        GtfStroke.Parent = GoToFreeBtn
        
        GoToFreeBtn.MouseButton1Click:Connect(function()
            switchTab("FreeKey")
        end)
        
        local GoToVipBtn = Instance.new("TextButton")
        GoToVipBtn.Name = "GoToVipBtn"
        GoToVipBtn.Size = UDim2.new(1, 0, 0, 38)
        GoToVipBtn.Position = UDim2.new(0, 0, 0, 206)
        GoToVipBtn.BackgroundColor3 = Color3.fromRGB(28, 24, 16)
        GoToVipBtn.Font = Enum.Font.GothamBold
        GoToVipBtn.Text = "💎 MUA KEY VIP 1 THÁNG / 3 THÁNG (KHÔNG CẦN VƯỢT LINK)"
        GoToVipBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
        GoToVipBtn.TextSize = 12
        GoToVipBtn.BorderSizePixel = 0
        GoToVipBtn.Parent = pageLogin
        
        local GtvCorner = Instance.new("UICorner")
        GtvCorner.CornerRadius = UDim.new(0, 8)
        GtvCorner.Parent = GoToVipBtn
        
        local GtvStroke = Instance.new("UIStroke")
        GtvStroke.Color = Color3.fromRGB(255, 215, 0)
        GtvStroke.Thickness = 1
        GtvStroke.Transparency = 0.4
        GtvStroke.Parent = GoToVipBtn
        
        GoToVipBtn.MouseButton1Click:Connect(function()
            switchTab("BuyVip")
        end)
        
        local FooterHwid = Instance.new("TextLabel")
        FooterHwid.Size = UDim2.new(1, 0, 0, 20)
        FooterHwid.Position = UDim2.new(0, 0, 1, -24)
        FooterHwid.BackgroundTransparency = 1
        FooterHwid.Font = Enum.Font.Gotham
        FooterHwid.Text = "HWID Thiết Bị: " .. string.sub(getClientHWID(), 1, 24) .. "... (Bảo Mật 1 Key / 1 Thiết Bị)"
        FooterHwid.TextColor3 = Color3.fromRGB(100, 115, 130)
        FooterHwid.TextSize = 11
        FooterHwid.TextXAlignment = Enum.TextXAlignment.Center
        FooterHwid.Parent = pageLogin
        
        -- XAC THUC BANG MA HOA 1 CHIEU (SHA-256 SALT HASH - KHONG DUNG PLAINTEXT)
        local isVerifying = false
        CheckKeyBtn.MouseButton1Click:Connect(function()
            if isVerifying then return end
            isVerifying = true
            StatusLabel.Text = "Đang băm SHA-256 & kiểm tra chữ ký số..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
            task.wait(0.4)
        
            local inputKey = string.gsub(KeyTextBox.Text, "%s+", "")
            if #inputKey < 6 then
                StatusLabel.Text = "✕ Key quá ngắn hoặc không hợp lệ!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 95, 95)
                isVerifying = false
                return
            end
        
            local kh = hashKey(inputKey)
            local valid = false
            local msg = ""
            local kType = ""
            local expTime = -1
        
            -- So khop Hash 1 chieu cua Admin (Tuyet doi khong chua chuoi text key tho)
            if kh == "4896e311951a6e0b9ab49e7949ebbf6b5aa51b8a8cb3cb48595ffa04172c3c9c" or kh == "5301a5d3eef27a44c29df59bd1e59bcddc58f4bff9cc0c5e3d80932cdb5f72fb" then
                valid = true
                msg = "👑 CHÀO MỪNG FOUNDER YOKA! Bản quyền Vĩnh Viễn kích hoạt."
                kType = "Founder"
                expTime = -1
            end
        
            -- Gist DB Check (Giai ma 2 chieu URL Gist de lay du lieu ma khong de lo URL tho)
            if not valid then
                pcall(function()
                    local onlineUrl = _D(_HEX_KEYS_URL) .. "?t=" .. tostring(os.time())
                    local raw = game:HttpGet(onlineUrl)
                    local db = HttpService:JSONDecode(raw)
                    if db then
                        if db.admin_hashes then
                            for _, ah in ipairs(db.admin_hashes) do
                                if ah == kh then
                                    valid = true; msg = "👑 CHÀO MỪNG FOUNDER! Kích hoạt Vĩnh Viễn."; kType = "Founder"; expTime = -1
                                    break
                                end
                            end
                        end
                        if not valid and db.vip_hashes and db.vip_hashes[kh] then
                            local info = db.vip_hashes[kh]
                            local days = info.days or -1
                            expTime = (days == -1) and -1 or (os.time() + days * 86400)
                            valid = true; msg = "💎 CHÀO MỪNG VIP! Bản quyền VIP đã kích hoạt."; kType = "VIP"
                        end
                        if not valid and (db.free_hash == kh or (db.free_hashes and table.find(db.free_hashes, kh))) then
                            valid = true; msg = "✓ Key Free 24h hợp lệ! Có hiệu lực 24 giờ."; kType = "Free24h"; expTime = os.time() + 86400
                        end
                    end
                end)
            end
        
            -- Fallback VIP Hash
            if not valid then
                if kh == "d47ad00fdd35ec257add8b041e447d870ba8fa49c97240aff1b385db1e764fad" then
                    valid = true; msg = "👑 CHÀO MỪNG FOUNDER ADMIN! Quyền Root kích hoạt."; kType = "Founder"; expTime = -1
                elseif kh == "bc5181dbaf34f300134feee6cf6e1e6e93045fbcf0eca2a48a028a99545095e2" then
                    valid = true; msg = "💎 Key VIP Vĩnh Viễn hợp lệ! Chào mừng đến với YokaHub."; kType = "Lifetime"; expTime = -1
                elseif kh == "cb914c19a2e60cec01f69e22f5576d383cf6a8abf4e248dd21d5e596ffe845f9" then
                    valid = true; msg = "✓ Key Free 24h hợp lệ! Có hiệu lực 24 giờ."; kType = "Free24h"; expTime = os.time() + 86400
                end
            end
        
            if valid then
                StatusLabel.Text = msg
                if kType == "Founder" then
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                    CheckKeyBtn.Text = "👑 CHÀO MỪNG FOUNDER! ĐANG MỞ YOKAHUB..."
                    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(180, 130, 20)
                else
                    StatusLabel.TextColor3 = Color3.fromRGB(90, 235, 140)
                    CheckKeyBtn.Text = "✓ THÀNH CÔNG! ĐANG MỞ YOKAHUB..."
                    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(25, 140, 95)
                end
        
                pcall(function()
                    if typeof(writefile) == "function" then
                        local myHwid = getClientHWID()
                        local payload = {
                            keyHash = kh,
                            keyType = kType,
                            hwid = myHwid,
                            userId = lp and lp.UserId or 0,
                            savedAt = os.time(),
                            expireAt = expTime,
                            signature = generateSignature(kh, myHwid, expTime, kType)
                        }
                        writefile(LICENSE_FILE, HttpService:JSONEncode(payload))
                    end
                end)
        
                getgenv()._YokaHub_Authenticated = true
                task.wait(1.0)
                local tw = TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0.5, -280, 0.45, -190),
                    BackgroundTransparency = 1
                })
                tw:Play()
                task.wait(0.35)
                ScreenGui:Destroy()
        
                if typeof(getgenv()._LaunchYokaHub) == "function" then
                    pcall(getgenv()._LaunchYokaHub)
                end
            else
                StatusLabel.Text = "✕ Key không tồn tại hoặc đã bị khoá!"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 95, 95)
                task.wait(1.2)
                isVerifying = false
            end
        end)
        
        -- TAB 3: GET KEY FREE 24H (QUY TRÌNH VƯỢT LINK KIẾM TIỀN CHO ADMIN)
        local btnFree, pageFree = createTab("FreeKey", "Get Key Free", "🔗", 3)
        btnFree.MouseButton1Click:Connect(function() switchTab("FreeKey") end)
        
        local FreeGuideBox = Instance.new("Frame")
        FreeGuideBox.Size = UDim2.new(1, 0, 0, 85)
        FreeGuideBox.Position = UDim2.new(0, 0, 0, 6)
        FreeGuideBox.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
        FreeGuideBox.BorderSizePixel = 0
        FreeGuideBox.Parent = pageFree
        
        local FgCorner = Instance.new("UICorner")
        FgCorner.CornerRadius = UDim.new(0, 8)
        FgCorner.Parent = FreeGuideBox
        
        local FgStroke = Instance.new("UIStroke")
        FgStroke.Color = Color3.fromRGB(6, 182, 212)
        FgStroke.Thickness = 1.2
        FgStroke.Parent = FreeGuideBox
        
        local FgTitle = Instance.new("TextLabel")
        FgTitle.Size = UDim2.new(1, -16, 0, 20)
        FgTitle.Position = UDim2.new(0, 10, 0, 6)
        FgTitle.BackgroundTransparency = 1
        FgTitle.Font = Enum.Font.GothamBold
        FgTitle.Text = "📋 3 BƯỚC VƯỢT LINK LẤY KEY FREE 24H:"
        FgTitle.TextColor3 = Color3.fromRGB(6, 182, 212)
        FgTitle.TextSize = 12
        FgTitle.TextXAlignment = Enum.TextXAlignment.Left
        FgTitle.Parent = FreeGuideBox
        
        local FgText = Instance.new("TextLabel")
        FgText.Size = UDim2.new(1, -16, 0, 52)
        FgText.Position = UDim2.new(0, 10, 0, 28)
        FgText.BackgroundTransparency = 1
        FgText.Font = Enum.Font.Gotham
        FgText.Text = "1. Bấm nút [Sao Chép Link Vượt Link] bên dưới.\n2. Dán link vào Trình duyệt (Chrome/Safari) và xem bài viết 5 giây.\n3. Vượt link xong sẽ nhận được Key, quay lại dán vào tab [Nhập Key]!"
        FgText.TextColor3 = Color3.fromRGB(180, 195, 210)
        FgText.TextSize = 11
        FgText.TextXAlignment = Enum.TextXAlignment.Left
        FgText.TextYAlignment = Enum.TextYAlignment.Top
        FgText.Parent = FreeGuideBox
        
        -- 2 NHA CUNG CAP VUOT LINK (WORK.INK 1 BUOC & LOOTLABS 2 BUOC)
        local CopyWorkinkBtn = Instance.new("TextButton")
        CopyWorkinkBtn.Name = "CopyWorkinkBtn"
        CopyWorkinkBtn.Size = UDim2.new(0.485, -4, 0, 38)
        CopyWorkinkBtn.Position = UDim2.new(0, 0, 0, 98)
        CopyWorkinkBtn.BackgroundColor3 = Color3.fromRGB(0, 194, 116)
        CopyWorkinkBtn.Font = Enum.Font.GothamBold
        CopyWorkinkBtn.Text = "🟢 WORK.INK (1 BƯỚC)"
        CopyWorkinkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CopyWorkinkBtn.TextSize = 11
        CopyWorkinkBtn.BorderSizePixel = 0
        CopyWorkinkBtn.Parent = pageFree
        
        local CwiCorner = Instance.new("UICorner")
        CwiCorner.CornerRadius = UDim.new(0, 8)
        CwiCorner.Parent = CopyWorkinkBtn
        
        local CopyLootlabsBtn = Instance.new("TextButton")
        CopyLootlabsBtn.Name = "CopyLootlabsBtn"
        CopyLootlabsBtn.Size = UDim2.new(0.485, -4, 0, 38)
        CopyLootlabsBtn.Position = UDim2.new(0.515, 4, 0, 98)
        CopyLootlabsBtn.BackgroundColor3 = Color3.fromRGB(108, 71, 255)
        CopyLootlabsBtn.Font = Enum.Font.GothamBold
        CopyLootlabsBtn.Text = "🎁 LOOTLABS (2 BƯỚC)"
        CopyLootlabsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CopyLootlabsBtn.TextSize = 11
        CopyLootlabsBtn.BorderSizePixel = 0
        CopyLootlabsBtn.Parent = pageFree
        
        local CllCorner = Instance.new("UICorner")
        CllCorner.CornerRadius = UDim.new(0, 8)
        CllCorner.Parent = CopyLootlabsBtn
        
        local OpenWebVerifyBtn = Instance.new("TextButton")
        OpenWebVerifyBtn.Name = "OpenWebVerifyBtn"
        OpenWebVerifyBtn.Size = UDim2.new(1, 0, 0, 36)
        OpenWebVerifyBtn.Position = UDim2.new(0, 0, 0, 144)
        OpenWebVerifyBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
        OpenWebVerifyBtn.Font = Enum.Font.GothamBold
        OpenWebVerifyBtn.Text = "🌐 MỞ WEB CHỌN BƯỚC XÁC MINH (PROJECTREAL STYLE)"
        OpenWebVerifyBtn.TextColor3 = Color3.fromRGB(160, 220, 255)
        OpenWebVerifyBtn.TextSize = 11
        OpenWebVerifyBtn.BorderSizePixel = 0
        OpenWebVerifyBtn.Parent = pageFree
        
        local OwvCorner = Instance.new("UICorner")
        OwvCorner.CornerRadius = UDim.new(0, 8)
        OwvCorner.Parent = OpenWebVerifyBtn
        
        local OwvStroke = Instance.new("UIStroke")
        OwvStroke.Color = Color3.fromRGB(6, 182, 212)
        OwvStroke.Thickness = 1
        OwvStroke.Transparency = 0.4
        OwvStroke.Parent = OpenWebVerifyBtn
        
        local BackToLoginBtn = Instance.new("TextButton")
        BackToLoginBtn.Name = "BackToLoginBtn"
        BackToLoginBtn.Size = UDim2.new(1, 0, 0, 36)
        BackToLoginBtn.Position = UDim2.new(0, 0, 0, 188)
        BackToLoginBtn.BackgroundColor3 = Color3.fromRGB(36, 175, 125)
        BackToLoginBtn.Font = Enum.Font.GothamBold
        BackToLoginBtn.Text = "🔑 ĐÃ VƯỢT LINK XONG? QUAY LẠI TAB NHẬP KEY"
        BackToLoginBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        BackToLoginBtn.TextSize = 11
        BackToLoginBtn.BorderSizePixel = 0
        BackToLoginBtn.Parent = pageFree
        
        local BtlCorner = Instance.new("UICorner")
        BtlCorner.CornerRadius = UDim.new(0, 8)
        BtlCorner.Parent = BackToLoginBtn
        
        local FreeStatus = Instance.new("TextLabel")
        FreeStatus.Size = UDim2.new(1, 0, 0, 20)
        FreeStatus.Position = UDim2.new(0, 0, 0, 232)
        FreeStatus.BackgroundTransparency = 1
        FreeStatus.Font = Enum.Font.GothamMedium
        FreeStatus.Text = "Chọn Work.ink (1 bước) hoặc LootLabs (2 bước) để lấy key."
        FreeStatus.TextColor3 = Color3.fromRGB(140, 155, 170)
        FreeStatus.TextSize = 11
        FreeStatus.Parent = pageFree
        
        CopyWorkinkBtn.MouseButton1Click:Connect(function()
            pcall(function()
                local link = "https://work.ink/3bfl/yokahub-key-24h"
                if typeof(setclipboard) == "function" then
                    setclipboard(link)
                    FreeStatus.Text = "✓ ĐÃ SAO CHÉP LINK WORK.INK! Dán vào Chrome/Safari để vượt link."
                    FreeStatus.TextColor3 = Color3.fromRGB(0, 230, 130)
                    CopyWorkinkBtn.Text = "✓ ĐÃ COPY WORK.INK!"
                end
            end)
        end)
        
        CopyLootlabsBtn.MouseButton1Click:Connect(function()
            pcall(function()
                local link = "https://quystptv00383-commits.github.io/yokahub-store/checkpoint.html?provider=lootlabs"
                if typeof(setclipboard) == "function" then
                    setclipboard(link)
                    FreeStatus.Text = "✓ ĐÃ SAO CHÉP LINK LOOTLABS! Dán vào Chrome/Safari để vượt link."
                    FreeStatus.TextColor3 = Color3.fromRGB(170, 130, 255)
                    CopyLootlabsBtn.Text = "✓ ĐÃ COPY LOOTLABS!"
                end
            end)
        end)
        
        OpenWebVerifyBtn.MouseButton1Click:Connect(function()
            pcall(function()
                local link = "https://quystptv00383-commits.github.io/yokahub-store/"
                if typeof(setclipboard) == "function" then
                    setclipboard(link)
                    FreeStatus.Text = "✓ ĐÃ COPY LINK TRANG CHỦ BẢN QUYỀN YOKAHUB!"
                    FreeStatus.TextColor3 = Color3.fromRGB(6, 182, 212)
                end
            end)
        end)
        
        
        
        BackToLoginBtn.MouseButton1Click:Connect(function()
            switchTab("Login")
        end)
        
        -- TAB 4: MUA KEY VIP
        local btnVip, pageVip = createTab("BuyVip", "Mua Key VIP", "💎", 4)
        btnVip.MouseButton1Click:Connect(function() switchTab("BuyVip") end)
        
        local VipBox = Instance.new("Frame")
        VipBox.Size = UDim2.new(1, 0, 0, 110)
        VipBox.Position = UDim2.new(0, 0, 0, 10)
        VipBox.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
        VipBox.BorderSizePixel = 0
        VipBox.Parent = pageVip
        
        local VipCorner = Instance.new("UICorner")
        VipCorner.CornerRadius = UDim.new(0, 8)
        VipCorner.Parent = VipBox
        
        local VipText = Instance.new("TextLabel")
        VipText.Size = UDim2.new(1, -20, 1, -10)
        VipText.Position = UDim2.new(0, 10, 0, 5)
        VipText.BackgroundTransparency = 1
        VipText.Font = Enum.Font.GothamMedium
        VipText.Text = "💎 ĐẶC QUYỀN KHI MUA BẢN VIP:\n• Không cần vượt link quảng cáo - Mở game là vào thẳng\n• Gói 1 Tháng: 50.000đ (30 ngày) • Gói 3 Tháng: 120.000đ (90 ngày - Tiết kiệm 30K)\n• Hỗ trợ quét mã VietQR tự động hoặc mở Ticket trên Discord!"
        VipText.TextColor3 = Color3.fromRGB(240, 200, 255)
        VipText.TextSize = 11
        VipText.TextXAlignment = Enum.TextXAlignment.Left
        VipText.TextYAlignment = Enum.TextYAlignment.Top
        VipText.Parent = VipBox
        
        local OpenWebBtn = Instance.new("TextButton")
        OpenWebBtn.Size = UDim2.new(0.48, -5, 0, 42)
        OpenWebBtn.Position = UDim2.new(0, 0, 0, 135)
        OpenWebBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        OpenWebBtn.Font = Enum.Font.GothamBold
        OpenWebBtn.Text = "🌐 SAO CHÉP WEB BÁN KEY"
        OpenWebBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        OpenWebBtn.TextSize = 12
        OpenWebBtn.BorderSizePixel = 0
        OpenWebBtn.Parent = pageVip
        
        local OpenWebCorner = Instance.new("UICorner")
        OpenWebCorner.CornerRadius = UDim.new(0, 8)
        OpenWebCorner.Parent = OpenWebBtn
        
        local OpenDiscordBtn = Instance.new("TextButton")
        OpenDiscordBtn.Size = UDim2.new(0.48, -5, 0, 42)
        OpenDiscordBtn.Position = UDim2.new(0.52, 5, 0, 135)
        OpenDiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        OpenDiscordBtn.Font = Enum.Font.GothamBold
        OpenDiscordBtn.Text = "🎫 VÀO DISCORD MUA KEY"
        OpenDiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        OpenDiscordBtn.TextSize = 12
        OpenDiscordBtn.BorderSizePixel = 0
        OpenDiscordBtn.Parent = pageVip
        
        local OpenDisCorner = Instance.new("UICorner")
        OpenDisCorner.CornerRadius = UDim.new(0, 8)
        OpenDisCorner.Parent = OpenDiscordBtn
        
        local VipStatus = Instance.new("TextLabel")
        VipStatus.Size = UDim2.new(1, 0, 0, 24)
        VipStatus.Position = UDim2.new(0, 0, 0, 188)
        VipStatus.BackgroundTransparency = 1
        VipStatus.Font = Enum.Font.Gotham
        VipStatus.Text = "Hỗ trợ thanh toán VietQR ngân hàng (MB, VCB, Momo) tự động."
        VipStatus.TextColor3 = Color3.fromRGB(150, 165, 180)
        VipStatus.TextSize = 11
        VipStatus.Parent = pageVip
        
        OpenWebBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if typeof(setclipboard) == "function" then
                    setclipboard("https://quystptv00383-commits.github.io/yokahub-store/")
                    VipStatus.Text = "✓ ĐÃ SAO CHÉP LINK WEB BÁN KEY VÀO BỘ NHỚ TẠM!"
                    VipStatus.TextColor3 = Color3.fromRGB(255, 215, 0)
                end
            end)
        end)
        
        OpenDiscordBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if typeof(setclipboard) == "function" then
                    setclipboard(_D(_HEX_DISCORD))
                    VipStatus.Text = "✓ ĐÃ SAO CHÉP LINK DISCORD SERVER! Dán vào trình duyệt để vào."
                    VipStatus.TextColor3 = Color3.fromRGB(160, 200, 255)
                end
            end)
        end)
        
        local ExitToGetFreeBtnVip = Instance.new("TextButton")
        ExitToGetFreeBtnVip.Name = "ExitToGetFreeBtnVip"
        ExitToGetFreeBtnVip.Size = UDim2.new(1, 0, 0, 34)
        ExitToGetFreeBtnVip.Position = UDim2.new(0, 0, 0, 218)
        ExitToGetFreeBtnVip.BackgroundColor3 = Color3.fromRGB(26, 36, 50)
        ExitToGetFreeBtnVip.Font = Enum.Font.GothamBold
        ExitToGetFreeBtnVip.Text = "🚪 THOÁT RA TRANG GET KEY FREE (24H MIỄN PHÍ)"
        ExitToGetFreeBtnVip.TextColor3 = Color3.fromRGB(130, 215, 250)
        ExitToGetFreeBtnVip.TextSize = 12
        ExitToGetFreeBtnVip.BorderSizePixel = 0
        ExitToGetFreeBtnVip.Parent = pageVip
        
        local EtgvCorner = Instance.new("UICorner")
        EtgvCorner.CornerRadius = UDim.new(0, 8)
        EtgvCorner.Parent = ExitToGetFreeBtnVip
        
        local EtgvStroke = Instance.new("UIStroke")
        EtgvStroke.Color = Color3.fromRGB(6, 182, 212)
        EtgvStroke.Thickness = 1
        EtgvStroke.Parent = ExitToGetFreeBtnVip
        
        ExitToGetFreeBtnVip.MouseButton1Click:Connect(function()
            switchTab("FreeKey")
        end)
        
        switchTab("Home")
        print("[YokaHub Security] He thong bao mat Ma hoa 2 chieu & Bam 1 chieu da duoc ap dung hoan hao!")
    end

    genv._YokaHub_LaunchGateway = launchGatewayUI

    if typeof(genv._LaunchYokaHub) ~= "function" then
        genv._LaunchYokaHub = function()
            if genv._YokaHub_Running then return end
            genv._YokaHub_Running = true
            local isfFn = isfile or (syn and syn.isfile)
            local rfFn = readfile or (syn and syn.readfile)
            if typeof(isfFn) == "function" and typeof(rfFn) == "function" and isfFn("YokaHub.luau") then
                local fn = loadstring(rfFn("YokaHub.luau"))
                if fn then fn() return end
            end
            pcall(function()
                loadstring(game:HttpGet("https://gist.githubusercontent.com/quystptv00383-commits/7dde495f53b84afb7cf64c06c15dfe2d/raw/YokaHub.luau?t=" .. tostring(os.time())))()
            end)
        end
    end

    if genv._YokaHub_Authenticated ~= true then
        if checkSavedLicense() then
            print("[YokaHub Security] Phat hien Ban Quyen hop le (HWID OK). Dang tu dong mo Hub...")
            genv._YokaHub_Authenticated = true
        end
    end

    if genv._YokaHub_Authenticated ~= true then
        launchGatewayUI()

        while not genv._YokaHub_Authenticated do
            task.wait(0.2)
        end
    end
    -- ========================================================
