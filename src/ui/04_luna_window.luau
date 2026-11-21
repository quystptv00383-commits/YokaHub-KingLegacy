    local hubState = loadState()
    local session = loadSession()
    local currentMode: string = hubState.mode

    -- Helper khử xung đột & đồng bộ UI: chỉ cho phép 1 chế độ cày cục bộ chạy tại 1 thời điểm (không bao giờ kéo giật nhân vật giữa 2 luồng!)
    local localModeToggles: { [string]: any } = {}
    local syncingLocalToggles = false
    local function registerLocalModeToggle(key: string, toggleObj: any)
        localModeToggles[key] = toggleObj
    end

    local function deactivateOtherLocalModes(keepKey: string)
        local keys = { "autoLevel", "autoKillSelectedMob", "farmSea3Mat", "farmSea2Mat", "farmSea1Mat", "autoDungeon", "autoFish", "autoFightIslandBoss" }
        syncingLocalToggles = true
        for _, k in ipairs(keys) do
            if k ~= keepKey then
                (hubState :: any)[k] = false
                local tObj = localModeToggles[k]
                if tObj and typeof(tObj.Set) == "function" then
                    pcall(function() tObj:Set({ CurrentValue = false }) end)
                end
            end
        end
        syncingLocalToggles = false
        pcall(function()
            genv.Famlevel = false
            genv.Autokillmob = false
            genv.farmMaterialsea3 = false
            genv.farmMaterialsea2 = false
            genv.farmMaterialsea1 = false
            genv.autodungeon = false
            genv.AutoFish = (keepKey == "autoFish")
            genv.start = false
        end)
    end

    -- Helper bật/tắt Fast Mode trực tiếp trên Roblox Rendering & Lighting
    local function applyFastModeSetting(enabled: boolean)
        pcall(function()
            if enabled then
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                lighting.GlobalShadows = false
                lighting.FogEnd = 9e9
                for _, d in ipairs(workspace:GetDescendants()) do
                    if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
                        d.Enabled = false
                    elseif d:IsA("Explosion") then
                        d.BlastPressure = 1
                        d.BlastRadius = 1
                    end
                end
            else
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                lighting.GlobalShadows = true
            end
        end)
    end

    -- Tự động đồng bộ cài đặt YokaHub khi khởi động hệ thống
    pcall(function()
        if hubState.fastMode then applyFastModeSetting(true) end
        genv.PlayerSpeedEnabled = (hubState.speedBoost == true)
        genv.clickTeleportEnabled = (hubState.clickTeleport == true)
        genv.chonmod = hubState.selectedMob or "Elite Skeleton [Lv. 3100]"
        genv.autocat = (hubState.fastMobBring ~= false)
        genv.MobBringRange = hubState.mobBringRange or 800
        if hubState.autoSkills then genv.autoskillsea = true end
        if hubState.autoHaki then genv.haki = true; genv.hakivutrangv2 = true end
        genv.hakiquansatv2 = (hubState.autoKenHaki ~= false)
        genv.bienhinh = (hubState.autoTransform ~= false)
        genv.PlayerAimbotEnabled = (hubState.skillAimbot ~= false)
        genv.PlayerAimMode = "Skill Direction"
        genv.PlayerAimRange = 450
        genv.autoDodgeEnabled = (hubState.autoDodge ~= false)
        if hubState.safeDistance then genv.nequaikill = true; genv.tamxanekillquai = 250; genv.docaokillquai = 18 end
        genv.MaterialQuantityTracker = (hubState.materialQuantityTracker == true)
        if hubState.dungeonMode then genv.dungeonmode = string.match(hubState.dungeonMode, "^(%a+)") or "Easy" end
        if hubState.bringFruits then genv.BringDroppedFruit = true end
        if hubState.storeFruits then genv.AutoStoreFruit = true end
        if hubState.snipeShop then genv.shopSniperEnabled = true end
        if hubState.fruitESP then genv.FruitESPEnabled = true end
        if hubState.playerESP then genv.PlayerESPEnabled = true end
        if hubState.chestESP then genv.ChestESPEnabled = true end
        if hubState.blackScreen then genv.BlackScreen = true end
        if hubState.fastMode then genv.fastMode = true; genv.lowTextureMap = true; genv.removeEffects = true end
        if hubState.walkOnWater then genv.Walkonwater = true end
        if hubState.infiniteJump then genv.InfiniteJumpEnabled = true end
        if hubState.autoAlly then genv.AutoSendAlly = true; genv.AutoAcceptAlly = true end
        if hubState.autoDailyQuest then genv.autoalldailyquest = true; genv.nhiemvuhangngay = true end
        if hubState.autoRaceRoll then genv.AutoGetAutoRollRace = true; genv.toc = true end
        if hubState.webhookUrl and #hubState.webhookUrl > 10 then genv.Webhook_URL2 = hubState.webhookUrl end
        if hubState.whFruit then genv.whshowfruit = true end
        if hubState.whDrop then genv.whitemdrop = true end
        -- Sync Auto M1 & Smart Combat
        genv.AutoM1Fruit = (hubState.autoM1Fruit == true)
        genv.AutoM1Sword = (hubState.autoM1Sword == true)
        genv.AutoM1Melee = (hubState.autoM1Melee == true)
        genv.SmartSkillHold = (hubState.smartSkillHold ~= false)
        genv.DodgeSafeDistance = hubState.dodgeSafeDistance or 95
        genv.YokaFlySpeed = hubState.flySpeed or 420
        -- Sync Auto Skills & Keys
        if hubState.skillFruit then
            if hubState.skillFruitKeys == "Z + X" then genv.CombatSkillFruit = {"Z", "X"}
            elseif hubState.skillFruitKeys == "Z + X + C" then genv.CombatSkillFruit = {"Z", "X", "C"}
            elseif hubState.skillFruitKeys == "Z + X + C + V" then genv.CombatSkillFruit = {"Z", "X", "C", "V"}
            else genv.CombatSkillFruit = {"Z", "X", "C", "V", "E"} end
        else genv.CombatSkillFruit = {} end

        if hubState.skillSword then
            if hubState.skillSwordKeys == "Z + X" then genv.CombatSkillSword = {"Z", "X"}
            elseif hubState.skillSwordKeys == "Chỉ Phím Z" then genv.CombatSkillSword = {"Z"}
            elseif hubState.skillSwordKeys == "Chỉ Phím X" then genv.CombatSkillSword = {"X"}
            else genv.CombatSkillSword = {"Z", "X"} end
        else genv.CombatSkillSword = {} end

        if hubState.skillMelee then
            if hubState.skillMeleeKeys == "Toàn Bộ (Z, X, C, V, E)" then genv.CombatSkillMelee = {"Z", "X", "C", "V", "E"}
            elseif hubState.skillMeleeKeys == "Z + X + C" then genv.CombatSkillMelee = {"Z", "X", "C"}
            else genv.CombatSkillMelee = {"Z", "X"} end
        else genv.CombatSkillMelee = {} end

        -- Sync Materials
        if hubState.nguyenlieuSea3 then
            local clean3 = hubState.nguyenlieuSea3:match("^([^(]+)") or hubState.nguyenlieuSea3
            genv.nguyenlieusea3 = clean3:match("^%s*(.-)%s*$")
        end
        if hubState.nguyenlieuSea2 then
            local clean2 = hubState.nguyenlieuSea2:match("^([^(]+)") or hubState.nguyenlieuSea2
            genv.nguyenlieusea2 = clean2:match("^%s*(.-)%s*$")
        end
        if hubState.nguyenlieuSea1 then
            local clean1 = hubState.nguyenlieuSea1:match("^([^(]+)") or hubState.nguyenlieuSea1
            genv.nguyenlieusea1 = clean1:match("^%s*(.-)%s*$")
        end

        -- Sync Dungeon Tactics
        if hubState.dungeonTactics then
            if string.find(hubState.dungeonTactics, "Safe") then
                genv.DungeonBossSafeHeight = 180
                genv.DungeonBossSafeDistance = 260
                genv.DungeonSweepPulses = 2
            elseif string.find(hubState.dungeonTactics, "Fast") then
                genv.DungeonBossSafeHeight = 7
                genv.DungeonBossSafeDistance = 150
                genv.DungeonSweepHeight = 7
                genv.DungeonSweepPulses = 4
                genv.DungeonSweepMaxTargets = 6
                genv.DungeonSweepStepWait = 0.03
            else
                genv.DungeonBossSafeHeight = 120
                genv.DungeonBossSafeDistance = 200
                genv.DungeonSweepHeight = 12
                genv.DungeonSweepPulses = 3
            end
        end
        if hubState.dungeonAutoHeal ~= nil then genv.DungeonAutoScepterHeal = hubState.dungeonAutoHeal end
        if hubState.dungeonCameraLock ~= nil then genv.DungeonCameraLock = hubState.dungeonCameraLock end

        -- Sync Shop Sniper
        if hubState.snipeFruit then
            if string.find(hubState.snipeFruit, "Toàn Bộ") then
                genv.shopSniperFruits = {"Dragon", "Phoenix", "Gate", "Dough", "Erebus", "Spirit", "Magnet", "Toy", "Melody", "Demon", "Snow"}
            else
                local rawName = string.match(hubState.snipeFruit, "^([%w%s%']+)") or "Dragon"
                rawName = string.gsub(rawName, "%s+$", "")
                genv.shopSniperFruits = { rawName }
            end
        end
        if hubState.snipeDelay then genv.shopSniperDelay = hubState.snipeDelay end

        -- Sync Auto Fishing
        if hubState.autoFish then genv.AutoFish = true end
        if hubState.fishWeapon then
            local rawWeapon = string.match(hubState.fishWeapon, "^([%w%s%']+)") or "True Muramasa"
            rawWeapon = string.gsub(rawWeapon, "%s+$", "")
            genv.kiemmacauca = rawWeapon
        end
    end)
    local currentSoloTarget: string = hubState.soloTarget
    local myToken = (tonumber(genv._YokaHubToken) or 0) + 1
    genv._YokaHubToken = myToken
    genv._KingAutoHopMode = currentMode
    genv._KingSoloTarget = currentSoloTarget
    genv._AutoSeaEventApiHop = false
    genv._AutoSea2PriorityApiHop = false
    genv._AutoDepthKingOnlyApiHop = false

    local function recordHop()
        session.hops += 1
        writeJson(sessionFile, session)
    end

    local teleportToSea: ((targetPlace: number, preferKey: string?) -> boolean)? = nil

    -- 4. Tu go loi Teleport 773/772/279/277/266/529 sieu nhanh & tu cuu ket neu mat ket noi
    genv._LastTeleportFailClock = tonumber(genv._LastTeleportFailClock) or 0
    local clearErrPending = false
    local function dismissRobloxPromptGui()
        pcall(function() guiService:ClearError() end)
        pcall(function()
            local rpg = coreGui:FindFirstChild("RobloxPromptGui")
            if not rpg then return end
            local po = rpg:FindFirstChild("promptOverlay")
            local ep = po and po:FindFirstChild("ErrorPrompt")
            if ep and ep.Visible then
                for _, d in ipairs(ep:GetDescendants()) do
                    if d:IsA("GuiButton") and d.Visible then
                        local btnName = string.lower(d.Name)
                        if string.find(btnName, "retry") or string.find(btnName, "reconnect") or string.find(btnName, "button") then
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                local pos = d.AbsolutePosition + d.AbsoluteSize / 2
                                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                                task.wait(0.04)
                                vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                            end)
                            break
                        end
                    end
                end
            end
        end)
    end

    local lastAttemptedPlace: number? = nil
    local lastFailRescueClock = 0
    local function handleTeleportFail(reason: string, isDisconnect: boolean?)
        genv._LastTeleportFailClock = os.clock()
        if not hubState.autoDismiss773 or clearErrPending then return end
        if (os.clock() - lastFailRescueClock) < 12.0 then
            print("[YokaHub][Auto-Dismiss] Debounced fail rescue:", reason)
            dismissRobloxPromptGui()
            return
        end
        clearErrPending = true
        lastFailRescueClock = os.clock()
        task.spawn(function()
            task.wait(0.5)
            clearErrPending = false
            dismissRobloxPromptGui()
            print("[YokaHub][Auto-Dismiss]", reason)
            -- Khi đang chạy Auto Hop (sea3 / sea2 / solo), burstHopCandidates sẽ tự chuyển sang phòng Boss kế tiếp trên API,
            -- tuyệt đối KHÔNG gọi teleportToSea ngẫu nhiên vào phòng công khai không có Boss!
            if isDisconnect then
                task.wait(2.5)
                pcall(function()
                    local targetPlace = lastAttemptedPlace
                    if not targetPlace or targetPlace == 0 then
                        if currentMode == "solo" then targetPlace = getSoloPlaceId(getSoloKey(currentSoloTarget))
                        elseif currentMode == "sea3" then targetPlace = SEA3_PLACE
                        elseif currentMode == "sea2" then targetPlace = SEA2_PLACE
                        else targetPlace = game.PlaceId
                        end
                    end
                    if targetPlace and targetPlace ~= 0 then
                        print("[YokaHub][Auto-Rescue] Reconnecting after disconnect to place:", targetPlace)
                        safeNotify("Tự động cứu hộ", "Mất kết nối — Đang tự kết nối lại phòng mới...", "refresh")
                        if teleportToSea then
                            teleportToSea(targetPlace)
                        else
                            teleportService:Teleport(targetPlace, players.LocalPlayer)
                        end
                    end
                end)
            end
        end)
    end

    trackConn(teleportService.TeleportInitFailed:Connect(function(_plr, _res, msg)
        local s = tostring(msg)
        local is279 = string.find(s, "279") ~= nil or string.find(s, "Connection") ~= nil or string.find(s, "No response") ~= nil
        handleTeleportFail("TeleportInitFailed: " .. s, is279)
    end))
    trackConn(guiService.ErrorMessageChanged:Connect(function()
        local msg = guiService:GetErrorMessage()
        if not msg or msg == "" then return end
        local isDisc = string.find(msg, "279") ~= nil or string.find(msg, "277") ~= nil or string.find(msg, "266") ~= nil or string.find(msg, "529") ~= nil or string.find(msg, "Connection Failed") ~= nil or string.find(msg, "No response") ~= nil or string.find(msg, "Disconnected") ~= nil
        if isDisc or string.find(msg, "773") or string.find(msg, "772") or string.find(msg, "774") or string.find(msg, "restricted") or string.find(msg, "Teleport") or string.find(msg, "full") or string.find(msg, "Unable to join") then
            handleTeleportFail("ErrorMessage: " .. tostring(msg), isDisc)
        end
    end))

    -- Watchdog kiem tra dinh ky bang loi RobloxPromptGui (neu su kien bi bo sot)
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(2.5)
            pcall(function()
                if not hubState.autoDismiss773 then return end
                local rpg = coreGui:FindFirstChild("RobloxPromptGui")
                if not rpg then return end
                local po = rpg:FindFirstChild("promptOverlay")
                local ep = po and po:FindFirstChild("ErrorPrompt")
                if ep and ep.Visible then
                    local errMsg = ""
                    for _, t in ipairs(ep:GetDescendants()) do
                        if t:IsA("TextLabel") and #t.Text > 5 then
                            errMsg = errMsg .. " " .. t.Text
                        end
                    end
                    local isDisc = string.find(errMsg, "279") ~= nil or string.find(errMsg, "277") ~= nil or string.find(errMsg, "266") ~= nil or string.find(errMsg, "529") ~= nil or string.find(errMsg, "Connection") ~= nil or string.find(errMsg, "No response") ~= nil or string.find(errMsg, "Disconnected") ~= nil
                    handleTeleportFail("PromptWatchdog: " .. errMsg, isDisc)
                end
            end)
        end
    end)


    -- ========================================================
    -- YOKAUI v3 · THƯ VIỆN GIAO DIỆN RIÊNG CỦA YOKAHUB (thay thế Luna)
    -- API tương thích Luna: CreateTab / CreateSection / CreateToggle / CreateButton /
    -- CreateSlider / CreateDropdown / CreateParagraph / CreateInput / Notification
    -- Tính năng: sidebar nhóm tab · tìm kiếm tính năng (không dấu) · đếm tính năng đang bật ·
    -- section thu gọn · dropdown popup có ô tìm · toast thông báo · kéo/resize/phóng to · PC + mobile
    -- ========================================================
    local YokaUI: any = (function()
        local TweenService = game:GetService("TweenService")
        local UserInputService = game:GetService("UserInputService")
        local PlayersService = game:GetService("Players")

        local Lib: any = {}
        Lib.__index = Lib

        local RGB = Color3.fromRGB
        local P = {
            bg = RGB(13, 15, 21),
            panel = RGB(19, 22, 30),
            card = RGB(26, 30, 41),
            card2 = RGB(33, 38, 51),
            hover = RGB(38, 44, 59),
            stroke = RGB(42, 48, 64),
            strokeSoft = RGB(34, 39, 53),
            text = RGB(238, 242, 248),
            sub = RGB(148, 158, 178),
            mute = RGB(96, 106, 126),
            accent = RGB(52, 211, 153),
            accent2 = RGB(45, 190, 222),
            accentDark = RGB(8, 24, 20),
            danger = RGB(244, 86, 100),
            warn = RGB(251, 191, 36),
            info = RGB(96, 165, 250),
            off = RGB(52, 59, 77),
            knobOff = RGB(176, 186, 206),
        }
        Lib.Palette = P

        local FONT = Enum.Font.Gotham
        local FONT_M = Enum.Font.GothamMedium
        local FONT_B = Enum.Font.GothamBold
        local EASE = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local EASE_SLOW = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local XL, XR, XC = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right, Enum.TextXAlignment.Center
        local AUTO_Y, AUTO_X = Enum.AutomaticSize.Y, Enum.AutomaticSize.X

        local DEFAULT_W, DEFAULT_H = 760, 480
        local MIN_W, MIN_H = 520, 340

        local orderCounter = 0
        local function nextOrder(): number
            orderCounter += 10
            return orderCounter
        end

        local function tw(obj: any, props: any, info: TweenInfo?)
            if not obj then return nil end
            local t = TweenService:Create(obj, info or EASE, props)
            t:Play()
            return t
        end

        local function mk(class: string, defaults: any, props: any?, parent: Instance?): any
            local o = Instance.new(class)
            for k, v in pairs(defaults) do o[k] = v end
            if props then for k, v in pairs(props) do o[k] = v end end
            if parent then o.Parent = parent end
            return o
        end

        local function Frame(props: any?, parent: Instance?): any
            return mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = P.card }, props, parent)
        end
        local function Label(props: any?, parent: Instance?): any
            return mk("TextLabel", {
                BorderSizePixel = 0, BackgroundTransparency = 1, Font = FONT, TextSize = 13, TextColor3 = P.text,
                TextXAlignment = XL, TextYAlignment = Enum.TextYAlignment.Center, Text = "", RichText = false,
            }, props, parent)
        end
        local function Button(props: any?, parent: Instance?): any
            return mk("TextButton", {
                BorderSizePixel = 0, BackgroundTransparency = 1, AutoButtonColor = false, Text = "",
                Font = FONT, TextSize = 13, TextColor3 = P.text,
            }, props, parent)
        end
        local function Box(props: any?, parent: Instance?): any
            return mk("TextBox", {
                BorderSizePixel = 0, BackgroundTransparency = 1, Font = FONT_M, TextSize = 12.5, TextColor3 = P.text,
                PlaceholderColor3 = P.mute, ClearTextOnFocus = false, Text = "", TextXAlignment = XL,
            }, props, parent)
        end
        local function Image(props: any?, parent: Instance?): any
            return mk("ImageLabel", { BorderSizePixel = 0, BackgroundTransparency = 1 }, props, parent)
        end
        local function Round(o: Instance, r: any): any
            return mk("UICorner", { CornerRadius = (r == "full") and UDim.new(1, 0) or UDim.new(0, r) }, nil, o)
        end
        local function Stroke(o: Instance, color: Color3, thick: number?, trans: number?): any
            return mk("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color,
                Thickness = thick or 1, Transparency = trans or 0,
            }, nil, o)
        end
        local function Pad(o: Instance, t: number, r: number, b: number, l: number): any
            return mk("UIPadding", {
                PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r),
                PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l),
            }, nil, o)
        end
        local function List(o: Instance, gap: number, horizontal: boolean?): any
            return mk("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, gap),
                FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
            }, nil, o)
        end
        local function Grad(o: Instance, c0: Color3, c1: Color3, rot: number?): any
            return mk("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = rot or 0 }, nil, o)
        end

        -- ------------------------------------------------------------
        -- Chuẩn hoá chuỗi tìm kiếm: bỏ dấu tiếng Việt + chữ thường
        -- ------------------------------------------------------------
        local FOLD: { [number]: string } = {}
        local function addFold(base: string, chars: string)
            for _, cp in utf8.codes(chars) do FOLD[cp] = base end
        end
        addFold("a", "àáạảãâầấậẩẫăằắặẳẵÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ")
        addFold("e", "èéẹẻẽêềếệểễÈÉẸẺẼÊỀẾỆỂỄ")
        addFold("i", "ìíịỉĩÌÍỊỈĨ")
        addFold("o", "òóọỏõôồốộổỗơờớợởỡÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ")
        addFold("u", "ùúụủũưừứựửữÙÚỤỦŨƯỪỨỰỬỮ")
        addFold("y", "ỳýỵỷỹỲÝỴỶỸ")
        addFold("d", "đĐ")
        local function fold(s: string): string
            local ok, res = pcall(function()
                local out = {}
                for _, cp in utf8.codes(s) do
                    out[#out + 1] = FOLD[cp] or utf8.char(cp)
                end
                return table.concat(out)
            end)
            return string.lower(ok and res or s)
        end

        local function splitEmoji(name: string): (string?, string)
            local first, rest = string.match(name, "^(%S+)%s+(.+)$")
            if first and not string.find(first, "%a") and string.byte(first, 1) >= 128 then
                return first, rest
            end
            return nil, name
        end

        local ICONMAP = {
            public = "🌊", fitness_center = "🌾", flash_on = "⚔️", all_inbox = "📦", explore = "🏰",
            waves = "🎣", spa = "🍎", speed = "👁️", bolt = "⚡", volunteer_activism = "💖", logout = "🚪",
        }

        local TAB_META: { [string]: { group: string, label: string?, emoji: string? } } = {
            ["🌊 Săn Boss Biển"] = { group = "Chiến Đấu & Cày", label = "Săn Boss Biển", emoji = "🌊" },
            ["🌾 Cày Cấp & Quái"] = { group = "Chiến Đấu & Cày", label = "Cày Cấp & Quái", emoji = "🌾" },
            ["⚔️ Xả Chiêu & Haki"] = { group = "Chiến Đấu & Cày", label = "Xả Chiêu & Haki", emoji = "⚔️" },
            ["📦 Gom Nguyên Liệu"] = { group = "Phó Bản & Vật Phẩm", label = "Gom Nguyên Liệu", emoji = "📦" },
            ["🏰 Vượt Phó Bản"] = { group = "Phó Bản & Vật Phẩm", label = "Vượt Phó Bản", emoji = "🏰" },
            ["🎣 Câu Cá Tự Động"] = { group = "Phó Bản & Vật Phẩm", label = "Câu Cá Tự Động", emoji = "🎣" },
            ["🍎 Trái & Cửa Hàng"] = { group = "Phó Bản & Vật Phẩm", label = "Trái & Cửa Hàng", emoji = "🍎" },
            ["👁️ ESP & Thống Kê"] = { group = "Hệ Thống & Tiện Ích", label = "ESP & Thống Kê", emoji = "👁️" },
            ["Tiện ích"] = { group = "Hệ Thống & Tiện Ích", label = "Tối Ưu & Tiện Ích", emoji = "⚡" },
            ["Ủng hộ"] = { group = "Hệ Thống & Tiện Ích", label = "Ủng Hộ Yoka", emoji = "💖" },
            ["🚪 Thoát Key"] = { group = "Hệ Thống & Tiện Ích", label = "Thoát / Đổi Key", emoji = "🚪" },
        }

        local KIND_COLOR = { ok = P.accent, warn = P.warn, err = P.danger, info = P.info }
        local KIND_OF = {
            check_circle = "ok", favorite = "ok", done = "ok", agriculture = "ok", task_alt = "ok",
            warning = "warn", report = "warn", priority_high = "warn", flight_takeoff = "warn",
            error = "err", cancel = "err", block = "err",
        }

        local function isPress(input: InputObject): boolean
            return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
        end
        local function isMove(input: InputObject): boolean
            return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
        end

        -- ============================================================
        -- WINDOW
        -- ============================================================
        local TabMT: any = {}
        local SectionMT: any = {}

        function Lib.new(o: any): any
            o = o or {}
            local self: any = setmetatable({}, Lib)
            self.conns = {}
            self.tabs = {}
            self.tabList = {}
            self.CurrentTab = nil
            self.compact = false
            self.scale = 1
            self.W, self.H = o.Width or DEFAULT_W, o.Height or DEFAULT_H
            self.fullscreen = false
            self.query = ""
            self.destroyed = false
            self.statusText = "Sẵn sàng"
            self.statusColor = P.mute
            self.lastGroup = nil
            self.exitArmed = false
            self.OnClose = o.OnClose
            self.OnExit = o.OnExit
            self.OnResize = o.OnResize
            self.toastRecent = {}

            local gui = mk("ScreenGui", {
                Name = "Luna UI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder = o.DisplayOrder or 1000010, IgnoreGuiInset = true,
            }, nil, o.Parent)
            self.Gui = gui

            -- Root (SmartWindow): giữ kích thước + vị trí + UIScale responsive. Window + ShadowHolder nằm trong Root.
            local root = Frame({
                Name = "SmartWindow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(self.W, self.H), BackgroundTransparency = 1, Visible = false,
            }, gui)
            self.Root = root
            self.Scaler = mk("UIScale", { Name = "Scaler" }, nil, root)

            local shadow = Frame({
                Name = "ShadowHolder", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, 8, 1, 8), BackgroundColor3 = RGB(0, 0, 0), BackgroundTransparency = 0.55,
                ZIndex = 0,
            }, root)
            Round(shadow, 17)
            Stroke(shadow, P.accent, 1, 0.78)
            self.Shadow = shadow

            local win = Frame({
                Name = "Window", Size = UDim2.fromScale(1, 1), BackgroundColor3 = P.bg, Active = true, ZIndex = 1,
            }, root)
            Round(win, 14)
            Stroke(win, P.stroke, 1, 0.1)
            self.Window = win
            self.Pop = mk("UIScale", { Name = "Pop", Scale = 1 }, nil, win)

            -- ---------------- TOPBAR ----------------
            local top = Frame({ Name = "Topbar", Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1 }, win)
            self.Topbar = top
            Frame({
                Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.strokeSoft,
            }, top)

            local logo = Frame({
                Name = "Logo", Position = UDim2.fromOffset(16, 11), Size = UDim2.fromOffset(32, 32),
                BackgroundColor3 = Color3.new(1, 1, 1),
            }, top)
            Round(logo, 9)
            Grad(logo, P.accent, P.accent2, 45)
            self.LogoText = Label({
                Name = "Y", Size = UDim2.fromScale(1, 1), Text = "Y", Font = FONT_B, TextSize = 19,
                TextColor3 = P.accentDark, TextXAlignment = XC,
            }, logo)
            self.LogoImage = Image({
                Name = "Img", Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop, Visible = false,
            }, logo)
            Round(self.LogoImage, 9)

            local titleHolder = Frame({
                Name = "TitleHolder", Position = UDim2.fromOffset(58, 8), Size = UDim2.fromOffset(0, 18),
                AutomaticSize = AUTO_X, BackgroundTransparency = 1,
            }, top)
            mk("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center,
            }, nil, titleHolder)
            Label({
                Name = "Title", LayoutOrder = 1, Text = o.Name or "YokaHub", Font = FONT_B, TextSize = 16,
                Size = UDim2.fromOffset(0, 18), AutomaticSize = AUTO_X,
            }, titleHolder)
            local pro = Frame({
                Name = "Pro", LayoutOrder = 2, Size = UDim2.fromOffset(0, 15), AutomaticSize = AUTO_X,
                BackgroundColor3 = P.accent, BackgroundTransparency = 0.82,
            }, titleHolder)
            Round(pro, 5)
            Pad(pro, 0, 6, 0, 6)
            Label({
                Name = "T", Text = "PRO", Font = FONT_B, TextSize = 9, TextColor3 = P.accent,
                Size = UDim2.fromOffset(0, 15), AutomaticSize = AUTO_X,
            }, pro)
            self.Subtitle = Label({
                Name = "Subtitle", Position = UDim2.fromOffset(58, 28), Size = UDim2.new(0, 220, 0, 14),
                Text = o.Subtitle or "", Font = FONT, TextSize = 11, TextColor3 = P.sub, TextTruncate = Enum.TextTruncate.AtEnd,
            }, top)

            local right = Frame({
                Name = "Right", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(0, 32), AutomaticSize = AUTO_X, BackgroundTransparency = 1,
            }, top)
            mk("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
            }, nil, right)

            -- Status pill
            local pill = Frame({
                Name = "Status", LayoutOrder = 1, Size = UDim2.fromOffset(0, 28), AutomaticSize = AUTO_X,
                BackgroundColor3 = P.card,
            }, right)
            Round(pill, "full")
            Stroke(pill, P.strokeSoft, 1, 0)
            Pad(pill, 0, 12, 0, 10)
            mk("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 7), VerticalAlignment = Enum.VerticalAlignment.Center,
            }, nil, pill)
            self.StatusDot = Frame({ Name = "Dot", LayoutOrder = 1, Size = UDim2.fromOffset(8, 8), BackgroundColor3 = P.mute }, pill)
            Round(self.StatusDot, "full")
            self.StatusLabel = Label({
                Name = "Text", LayoutOrder = 2, Text = "Sẵn sàng", Font = FONT_M, TextSize = 11.5, TextColor3 = P.sub,
                Size = UDim2.fromOffset(0, 28), AutomaticSize = AUTO_X,
            }, pill)
            self.StatusPill = pill

            -- Search
            local search = Frame({
                Name = "Search", LayoutOrder = 2, Size = UDim2.fromOffset(200, 32), BackgroundColor3 = P.card,
            }, right)
            Round(search, 9)
            self.SearchStroke = Stroke(search, P.strokeSoft, 1, 0)
            local mg = Frame({
                Name = "Glass", Position = UDim2.fromOffset(11, 10), Size = UDim2.fromOffset(10, 10),
                BackgroundTransparency = 1,
            }, search)
            Round(mg, "full")
            Stroke(mg, P.sub, 1.6, 0)
            Frame({
                Name = "Handle", Position = UDim2.fromOffset(19, 19), Size = UDim2.fromOffset(5, 1.6),
                BackgroundColor3 = P.sub, Rotation = 45,
            }, search)
            local sbox = Box({
                Name = "Input", Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -58, 1, 0),
                PlaceholderText = "Tìm tính năng…", TextSize = 12.5, TextTruncate = Enum.TextTruncate.AtEnd,
            }, search)
            self.SearchBox = sbox
            local sclear = Button({
                Name = "Clear", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(20, 20), Text = "×", Font = FONT_B, TextSize = 16, TextColor3 = P.sub,
                Visible = false,
            }, search)
            self.SearchFrame = search

            -- Window buttons
            local function iconButton(name: string, order: number, red: boolean?): any
                local b = Button({
                    Name = name, LayoutOrder = order, Size = UDim2.fromOffset(32, 32),
                    BackgroundColor3 = red and P.danger or P.card2, BackgroundTransparency = 1,
                }, right)
                Round(b, 9)
                b.MouseEnter:Connect(function()
                    tw(b, { BackgroundTransparency = red and 0.1 or 0.2 })
                end)
                b.MouseLeave:Connect(function()
                    tw(b, { BackgroundTransparency = 1 })
                end)
                return b
            end
            local fsBtn = iconButton("Fullscreen", 3)
            local fsBox = Frame({
                Name = "Box", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
            }, fsBtn)
            Round(fsBox, 3)
            self.FsStroke = Stroke(fsBox, P.sub, 1.6, 0)
            self.FsBox = fsBox
            local closeBtn = iconButton("Close", 4, true)
            for _, rot in ipairs({ 45, -45 }) do
                Frame({
                    Name = "X", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(14, 1.8), Rotation = rot, BackgroundColor3 = P.sub,
                }, closeBtn)
            end

            -- ---------------- SIDEBAR ----------------
            local side = Frame({
                Name = "Sidebar", Position = UDim2.fromOffset(0, 54), Size = UDim2.new(0, 200, 1, -54),
                BackgroundTransparency = 1, ClipsDescendants = true,
            }, win)
            self.Sidebar = side
            local tabScroll = mk("ScrollingFrame", {
                Name = "Tabs", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -84),
                CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, ScrollBarThickness = 3,
                ScrollBarImageColor3 = P.stroke, ScrollBarImageTransparency = 0.25,
                ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
            }, nil, side)
            Pad(tabScroll, 6, 8, 6, 8)
            List(tabScroll, 2)
            self.TabScroll = tabScroll

            -- Footer sidebar (người dùng + đăng xuất)
            local foot = Frame({
                Name = "Footer", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 84), BackgroundTransparency = 1,
            }, side)
            self.SideFooter = foot
            Frame({ Name = "Line", Size = UDim2.new(1, -20, 0, 1), Position = UDim2.fromOffset(10, 0), BackgroundColor3 = P.strokeSoft }, foot)
            local avatar = Frame({
                Name = "Avatar", Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = P.card2,
            }, foot)
            Round(avatar, "full")
            Stroke(avatar, P.accent, 1.5, 0.35)
            self.AvatarBox = avatar
            self.AvatarImg = Image({ Name = "Img", Size = UDim2.fromScale(1, 1) }, avatar)
            Round(self.AvatarImg, "full")
            local lp = PlayersService.LocalPlayer
            self.UserName = Label({
                Name = "UserName", Position = UDim2.fromOffset(54, 11), Size = UDim2.new(1, -66, 0, 18),
                Text = o.UserName or (lp and lp.DisplayName) or "Player", Font = FONT_B, TextSize = 12.5,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, foot)
            self.UserSub = Label({
                Name = "UserSub", Position = UDim2.fromOffset(54, 29), Size = UDim2.new(1, -66, 0, 16),
                Text = o.UserSub or "", Font = FONT, TextSize = 11, TextColor3 = P.accent,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, foot)
            if lp then
                task.spawn(function()
                    local ok, img = pcall(function()
                        return PlayersService:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                    end)
                    if ok and not self.destroyed then self.AvatarImg.Image = img end
                end)
            end
            local exitBtn = Button({
                Name = "Exit", Position = UDim2.new(0, 10, 0, 52), Size = UDim2.new(1, -20, 0, 26),
                BackgroundColor3 = P.danger, BackgroundTransparency = 0.88, Text = "🚪  Đăng xuất / Đổi Key",
                Font = FONT_M, TextSize = 11.5, TextColor3 = RGB(255, 150, 160),
            }, foot)
            Round(exitBtn, 8)
            self.ExitStroke = Stroke(exitBtn, P.danger, 1, 0.65)
            self.ExitBtn = exitBtn

            -- ---------------- PANEL NỘI DUNG ----------------
            local panel = Frame({
                Name = "Panel", Position = UDim2.fromOffset(200, 54), Size = UDim2.new(1, -210, 1, -64),
                BackgroundColor3 = P.panel,
            }, win)
            Round(panel, 12)
            Stroke(panel, P.strokeSoft, 1, 0)
            self.Panel = panel

            local head = Frame({ Name = "Header", Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1 }, panel)
            self.HeadTitle = Label({
                Name = "Title", Position = UDim2.fromOffset(18, 11), Size = UDim2.new(1, -150, 0, 24),
                Text = "", Font = FONT_B, TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd,
            }, head)
            self.HeadSub = Label({
                Name = "Sub", Position = UDim2.fromOffset(18, 35), Size = UDim2.new(1, -150, 0, 16),
                Text = "", Font = FONT, TextSize = 12, TextColor3 = P.sub, TextTruncate = Enum.TextTruncate.AtEnd,
            }, head)
            local collapseBtn = Button({
                Name = "CollapseAll", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 17),
                Size = UDim2.fromOffset(104, 28), BackgroundColor3 = P.card, BackgroundTransparency = 0,
                Text = "Thu gọn tất cả", Font = FONT_M, TextSize = 11.5, TextColor3 = P.sub,
            }, head)
            Round(collapseBtn, 8)
            Stroke(collapseBtn, P.strokeSoft, 1, 0)
            self.CollapseBtn = collapseBtn
            Frame({
                Name = "Line", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.strokeSoft,
            }, head)

            local pages = Frame({
                Name = "Pages", Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 1, -62 - 28),
                BackgroundTransparency = 1, ClipsDescendants = true,
            }, panel)
            self.Pages = pages

            local pfoot = Frame({
                Name = "Footer", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
            }, panel)
            Frame({ Name = "Line", Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.strokeSoft }, pfoot)
            self.Hint = Label({
                Name = "Hint", Position = UDim2.fromOffset(16, 1), Size = UDim2.new(1, -60, 1, -1),
                Text = o.Hint or "", Font = FONT, TextSize = 10.5, TextColor3 = P.mute, TextTruncate = Enum.TextTruncate.AtEnd,
            }, pfoot)

            local grip = Button({
                Name = "ResizeGrip", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
                Size = UDim2.fromOffset(28, 28), ZIndex = 5,
            }, panel)
            for i, w in ipairs({ 12, 7 }) do
                Frame({
                    Name = "Bar", Size = UDim2.fromOffset(w, 1.6), Position = UDim2.fromOffset(i == 1 and 9 or 14, i == 1 and 15 or 18),
                    Rotation = -45, BackgroundColor3 = P.mute,
                }, grip)
            end

            -- Overlay toast
            local toasts = Frame({
                Name = "Toasts", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
                Size = UDim2.new(0, 310, 1, -32), BackgroundTransparency = 1, ZIndex = 1,
            }, gui)
            mk("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right,
            }, nil, toasts)
            self.ToastScale = mk("UIScale", {}, nil, toasts)
            self.Toasts = toasts

            -- ======== Sự kiện ========
            local function conn(sig: RBXScriptSignal, fn: (...any) -> ()): RBXScriptConnection
                local c = sig:Connect(fn)
                table.insert(self.conns, c)
                return c
            end
            self._conn = conn

            -- Tìm kiếm
            conn(sbox:GetPropertyChangedSignal("Text"), function()
                sclear.Visible = sbox.Text ~= ""
                self.searchToken = (self.searchToken or 0) + 1
                local my = self.searchToken
                task.delay(0.12, function()
                    if my == self.searchToken and not self.destroyed then self:_applySearch(sbox.Text) end
                end)
            end)
            conn(sbox.Focused, function() tw(self.SearchStroke, { Color = P.accent }) end)
            conn(sbox.FocusLost, function() tw(self.SearchStroke, { Color = P.strokeSoft }) end)
            conn(sclear.MouseButton1Click, function() sbox.Text = "" end)

            -- Nút cửa sổ
            conn(closeBtn.MouseButton1Click, function()
                if self.OnClose then pcall(self.OnClose) else self:SetVisible(false) end
            end)
            conn(fsBtn.MouseButton1Click, function() self:ToggleFullscreen() end)
            conn(collapseBtn.MouseButton1Click, function() self:_toggleCollapseAll() end)

            -- Đăng xuất (bấm 2 lần để xác nhận)
            conn(exitBtn.MouseButton1Click, function()
                if not self.exitArmed then
                    self.exitArmed = true
                    exitBtn.Text = self.compact and "?" or "Bấm lần nữa để xác nhận"
                    tw(exitBtn, { BackgroundTransparency = 0.45 })
                    tw(exitBtn, { TextColor3 = RGB(255, 255, 255) })
                    task.delay(2.6, function()
                        if self.destroyed or not self.exitArmed then return end
                        self.exitArmed = false
                        exitBtn.Text = self.compact and "🚪" or "🚪  Đăng xuất / Đổi Key"
                        tw(exitBtn, { BackgroundTransparency = 0.88, TextColor3 = RGB(255, 150, 160) })
                    end)
                else
                    self.exitArmed = false
                    if self.OnExit then pcall(self.OnExit) end
                end
            end)

            -- Kéo cửa sổ
            local dragging, dragStart, dragPos = false, Vector3.zero, root.Position
            conn(top.InputBegan, function(input: InputObject)
                if isPress(input) then
                    dragging = true
                    dragStart = input.Position
                    dragPos = root.Position
                end
            end)
            conn(UserInputService.InputChanged, function(input: InputObject)
                if dragging and isMove(input) and not self.fullscreen then
                    local d = input.Position - dragStart
                    root.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + d.X, dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
                end
            end)
            conn(UserInputService.InputEnded, function(input: InputObject)
                if dragging and isPress(input) then
                    dragging = false
                    self:_clampPosition()
                end
            end)

            -- Kéo góc để đổi kích thước
            local resizing, rStart, rW, rH, rPos = false, Vector3.zero, 0, 0, root.Position
            conn(grip.InputBegan, function(input: InputObject)
                if isPress(input) then
                    resizing = true
                    self.fullscreen = false
                    self:_syncFsIcon()
                    rStart = input.Position
                    rW, rH = self.W, self.H
                    rPos = root.Position
                end
            end)
            conn(UserInputService.InputChanged, function(input: InputObject)
                if resizing and isMove(input) then
                    local d = (input.Position - rStart) / self.scale
                    local nw, nh = self:_clampSize(rW + d.X, rH + d.Y)
                    self.W, self.H = nw, nh
                    root.Size = UDim2.fromOffset(nw, nh)
                    root.Position = UDim2.new(
                        rPos.X.Scale, rPos.X.Offset + (nw - rW) * 0.5 * self.scale,
                        rPos.Y.Scale, rPos.Y.Offset + (nh - rH) * 0.5 * self.scale
                    )
                    self:_layout()
                end
            end)
            conn(UserInputService.InputEnded, function(input: InputObject)
                if resizing and isPress(input) then
                    resizing = false
                    if self.OnResize then pcall(self.OnResize, self.W, self.H) end
                end
            end)

            -- Responsive theo màn hình
            local cam = workspace.CurrentCamera
            if cam then
                conn(cam:GetPropertyChangedSignal("ViewportSize"), function() self:_refreshScale(true) end)
            end
            self:_refreshScale(false)
            self:_layout()
            return self
        end

        -- ------------------------------------------------------------
        -- Layout / kích thước / responsive
        -- ------------------------------------------------------------
        function Lib:_viewport(): Vector2
            local cam = workspace.CurrentCamera
            return cam and cam.ViewportSize or Vector2.new(1280, 720)
        end

        function Lib:_calcScale(): number
            local vp = self:_viewport()
            return math.clamp(math.min(vp.X / (DEFAULT_W + 60), vp.Y / (DEFAULT_H + 70)), 0.55, 1.2)
        end

        function Lib:_clampSize(w: number, h: number): (number, number)
            local vp = self:_viewport()
            local availW = math.max(MIN_W, math.floor((vp.X - 16) / self.scale))
            local availH = math.max(MIN_H, math.floor((vp.Y - 16) / self.scale))
            return math.clamp(math.floor(w + 0.5), math.min(MIN_W, availW), availW),
                math.clamp(math.floor(h + 0.5), math.min(MIN_H, availH), availH)
        end

        function Lib:_refreshScale(animate: boolean)
            self.scale = self:_calcScale()
            self.Scaler.Scale = self.scale
            self.ToastScale.Scale = math.clamp(self:_viewport().X / 700, 0.7, 1)
            if self.fullscreen then
                self:_applyFullscreen(false)
            else
                local nw, nh = self:_clampSize(self.W, self.H)
                self.W, self.H = nw, nh
                self.Root.Size = UDim2.fromOffset(nw, nh)
                self:_layout()
                self:_clampPosition()
            end
        end

        function Lib:_clampPosition()
            local root = self.Root
            local vp = self:_viewport()
            local half = Vector2.new(self.W, self.H) * self.scale * 0.5
            local cx = vp.X * root.Position.X.Scale + root.Position.X.Offset
            local cy = vp.Y * root.Position.Y.Scale + root.Position.Y.Offset
            local minX, maxX = math.min(half.X, vp.X / 2) , math.max(vp.X - half.X, vp.X / 2)
            local minY, maxY = math.min(half.Y, vp.Y / 2), math.max(vp.Y - half.Y, vp.Y / 2)
            -- cho phép kéo lệch ra ngoài nhưng luôn chừa thanh tiêu đề trong màn hình
            minX = math.min(minX, 80 + 0) - (half.X - 140)
            maxX = maxX + (half.X - 140)
            minY = math.min(minY, 0) + half.Y - 0
            local nx = math.clamp(cx, math.min(minX, vp.X / 2), math.max(maxX, vp.X / 2))
            local ny = math.clamp(cy, math.min(minY, vp.Y / 2), math.max(maxY, vp.Y / 2))
            if nx ~= cx or ny ~= cy then
                tw(root, { Position = UDim2.fromOffset(nx, ny) }, EASE_SLOW)
            end
        end

        function Lib:_layout()
            if self.destroyed or not self.Root or not self.Root.Parent or not self.Sidebar or not self.Panel then
                return
            end
            local compact = self.W < 640
            self.compact = compact
            local sw = compact and 64 or 200
            self.Sidebar.Size = UDim2.new(0, sw, 1, -54)
            self.Panel.Position = UDim2.fromOffset(sw, 54)
            self.Panel.Size = UDim2.new(1, -(sw + 10), 1, -64)
            self.StatusPill.Visible = self.W >= 700
            self.SearchFrame.Size = UDim2.fromOffset(self.W >= 700 and 210 or (self.W >= 600 and 170 or 140), 32)
            self.Subtitle.Visible = self.W >= 560
            self.CollapseBtn.Size = UDim2.fromOffset(compact and 84 or 104, 28)
            self.CollapseBtn.Text = self:_allCollapsed() and "Mở rộng tất cả" or "Thu gọn tất cả"
            self.SideFooter.Size = UDim2.new(1, 0, 0, compact and 62 or 84)
            self.TabScroll.Size = UDim2.new(1, 0, 1, compact and -62 or -84)
            self.UserName.Visible = not compact
            self.UserSub.Visible = not compact
            local avBox = self.AvatarBox or (self.AvatarImg and self.AvatarImg.Parent)
            if avBox and avBox:IsA("GuiObject") then
                avBox.Position = compact and UDim2.new(0.5, -17, 0, 10) or UDim2.fromOffset(12, 12)
            end
            self.ExitBtn.Position = compact and UDim2.new(0.5, -17, 0, 48) or UDim2.new(0, 10, 0, 52)
            self.ExitBtn.Size = compact and UDim2.fromOffset(34, 0) or UDim2.new(1, -20, 0, 26)
            if compact then
                self.ExitBtn.Size = UDim2.fromOffset(34, 0)
                self.ExitBtn.Visible = false
            else
                self.ExitBtn.Visible = true
            end
            self.ExitBtn.Text = self.exitArmed and "Bấm lần nữa để xác nhận" or "🚪  Đăng xuất / Đổi Key"
            for _, tab in ipairs(self.tabList) do tab:_applyCompact(compact) end
        end

        function Lib:SetSize(w: number, h: number, smooth: boolean?, silent: boolean?)
            if self.destroyed or not self.Root or not self.Root.Parent then return end
            self.fullscreen = false
            self:_syncFsIcon()
            local nw, nh = self:_clampSize(w, h)
            self.W, self.H = nw, nh
            if smooth then
                tw(self.Root, { Size = UDim2.fromOffset(nw, nh) }, EASE_SLOW)
            else
                self.Root.Size = UDim2.fromOffset(nw, nh)
            end
            self:_layout()
            if not silent and self.OnResize then pcall(self.OnResize, nw, nh) end
        end

        function Lib:_syncFsIcon()
            if not self.FsBox then return end
            self.FsBox.Size = self.fullscreen and UDim2.fromOffset(9, 9) or UDim2.fromOffset(12, 12)
        end

        function Lib:_applyFullscreen(animate: boolean)
            local vp = self:_viewport()
            local w = math.max(MIN_W, math.floor((vp.X - 16) / self.scale))
            local h = math.max(MIN_H, math.floor((vp.Y - 16) / self.scale))
            self.W, self.H = w, h
            if animate then
                tw(self.Root, { Size = UDim2.fromOffset(w, h), Position = UDim2.fromScale(0.5, 0.5) }, EASE_SLOW)
            else
                self.Root.Size = UDim2.fromOffset(w, h)
                self.Root.Position = UDim2.fromScale(0.5, 0.5)
            end
            self:_layout()
        end

        function Lib:ToggleFullscreen()
            if not self.fullscreen then
                self.preFull = { w = self.W, h = self.H, pos = self.Root.Position }
                self.fullscreen = true
                self:_applyFullscreen(true)
            else
                self.fullscreen = false
                local pre = self.preFull or { w = DEFAULT_W, h = DEFAULT_H, pos = UDim2.fromScale(0.5, 0.5) }
                local nw, nh = self:_clampSize(pre.w, pre.h)
                self.W, self.H = nw, nh
                tw(self.Root, { Size = UDim2.fromOffset(nw, nh), Position = pre.pos }, EASE_SLOW)
                self:_layout()
            end
            self:_syncFsIcon()
        end

        function Lib:ResetWindow()
            self.fullscreen = false
            self:_syncFsIcon()
            self.Root.Position = UDim2.fromScale(0.5, 0.5)
            self:SetSize(DEFAULT_W, DEFAULT_H, true, false)
        end

        function Lib:IsVisible(): boolean
            return self.Root.Visible
        end

        function Lib:SetVisible(visible: boolean)
            self:_closeDropdown()
            self.visToken = (self.visToken or 0) + 1
            local my = self.visToken
            if visible then
                self.Root.Visible = true
                self.Pop.Scale = 0.95
                self.Shadow.BackgroundTransparency = 1
                tw(self.Pop, { Scale = 1 }, EASE_SLOW)
                tw(self.Shadow, { BackgroundTransparency = 0.55 }, EASE_SLOW)
            else
                tw(self.Shadow, { BackgroundTransparency = 1 }, EASE)
                local t = tw(self.Pop, { Scale = 0.95 }, EASE)
                if t then
                    t.Completed:Once(function()
                        if my == self.visToken and not self.destroyed then
                            self.Root.Visible = false
                            self.Pop.Scale = 1
                        end
                    end)
                end
            end
        end

        function Lib:SetSubtitle(text: string)
            self.Subtitle.Text = text
        end

        function Lib:SetUserInfo(name: string?, sub: string?)
            if name then self.UserName.Text = name end
            if sub then self.UserSub.Text = sub end
        end

        function Lib:SetLogo(image: string)
            if typeof(image) == "string" and image ~= "" then
                self.LogoImage.Image = image
                self.LogoImage.Visible = true
                self.LogoText.Visible = false
            end
        end

        function Lib:SetHint(text: string)
            self.Hint.Text = text
        end

        function Lib:SetStatus(text: string, color: Color3?)
            self.statusText = text
            self.statusColor = color or P.mute
            self:_refreshStatus()
        end

        function Lib:_refreshStatus()
            local total = 0
            for _, tab in ipairs(self.tabList) do total += tab.onCount or 0 end
            self.StatusLabel.Text = total > 0 and (self.statusText .. "  ·  " .. total .. " bật") or self.statusText
            tw(self.StatusDot, { BackgroundColor3 = self.statusColor })
            tw(self.StatusLabel, { TextColor3 = (self.statusColor == P.mute) and P.sub or P.text })
        end

        function Lib:Destroy()
            if self.destroyed then return end
            self.destroyed = true
            for _, c in ipairs(self.conns) do pcall(function() c:Disconnect() end) end
            pcall(function() self.Gui:Destroy() end)
        end

        -- ------------------------------------------------------------
        -- Tìm kiếm toàn bộ tính năng
        -- ------------------------------------------------------------
        function Lib:_applySearch(raw: string)
            local q = fold(raw or "")
            q = string.gsub(q, "^%s+", "")
            q = string.gsub(q, "%s+$", "")
            self.query = q
            local firstHit: any = nil
            local currentHits = 0
            for _, tab in ipairs(self.tabList) do
                local hits = 0
                for _, sec in ipairs(tab.sections) do
                    local secMatch = (q ~= "") and (string.find(sec.FoldTitle, q, 1, true) ~= nil)
                    local any = false
                    for _, e in ipairs(sec.elems) do
                        local m = (q == "") or secMatch or (string.find(e.key, q, 1, true) ~= nil)
                        if e.row.Visible ~= m then e.row.Visible = m end
                        if m then any = true; hits += 1 end
                    end
                    sec.Frame.Visible = (q == "") or any or secMatch
                    sec.Body.Visible = (not sec.collapsed) or (q ~= "")
                end
                tab.hits = hits
                tab.Empty.Visible = (q ~= "") and hits == 0
                if q ~= "" then
                    tab.Empty.Text = "Không tìm thấy “" .. raw .. "” trong mục này."
                end
                if q ~= "" and hits > 0 and not firstHit then firstHit = tab end
                if tab == self.CurrentTab then currentHits = hits end
                tab:_refreshBadge()
            end
            if q ~= "" and currentHits == 0 and firstHit then
                firstHit:Activate()
            end
            self:_updateHeader()
        end

        function Lib:_allCollapsed(): boolean
            local tab = self.CurrentTab
            if not tab or #tab.sections == 0 then return false end
            for _, sec in ipairs(tab.sections) do
                if not sec.collapsed then return false end
            end
            return true
        end

        function Lib:_toggleCollapseAll()
            local tab = self.CurrentTab
            if not tab then return end
            local target = not self:_allCollapsed()
            for _, sec in ipairs(tab.sections) do sec:SetCollapsed(target) end
            self.CollapseBtn.Text = target and "Mở rộng tất cả" or "Thu gọn tất cả"
        end

        function Lib:_updateHeader()
            local tab = self.CurrentTab
            if not tab then return end
            self.HeadTitle.Text = (tab.Emoji and (tab.Emoji .. "  ") or "") .. tab.Label
            local total, on = 0, 0
            for _, sec in ipairs(tab.sections) do
                total += #sec.toggles
                for _, t in ipairs(sec.toggles) do
                    if t.CurrentValue then on += 1 end
                end
            end
            if self.query ~= "" then
                self.HeadSub.Text = tab.hits .. " kết quả cho “" .. self.SearchBox.Text .. "” trong mục này"
            elseif total > 0 then
                self.HeadSub.Text = on .. " / " .. total .. " tính năng đang bật  ·  " .. #tab.sections .. " nhóm"
            else
                self.HeadSub.Text = #tab.sections .. " nhóm chức năng"
            end
            self.CollapseBtn.Text = self:_allCollapsed() and "Mở rộng tất cả" or "Thu gọn tất cả"
        end

        -- ------------------------------------------------------------
        -- TAB
        -- ------------------------------------------------------------
        function Lib:CreateTab(o: any): any
            o = o or {}
            local name = tostring(o.Name or "Tab")
            local meta = TAB_META[name]
            local emoji, label = splitEmoji(name)
            if meta then
                label = meta.label or label
                emoji = meta.emoji or emoji
            end
            emoji = emoji or ICONMAP[o.Icon or ""] or "•"
            local groupName = o.Group or (meta and meta.group) or nil
            local tab: any = setmetatable({
                Window = self, Name = name, Label = label, Emoji = emoji, Group = groupName,
                sections = {}, onCount = 0, hits = 0, headless = nil,
            }, TabMT)

            -- Tiêu đề nhóm trong sidebar
            if groupName and groupName ~= self.lastGroup then
                self.lastGroup = groupName
                local gl = Label({
                    Name = "Group", Size = UDim2.new(1, 0, 0, 19), Text = string.upper(groupName), Font = FONT_B,
                    TextSize = 9.5, TextColor3 = P.mute, LayoutOrder = nextOrder(),
                }, self.TabScroll)
                Pad(gl, 5, 0, 0, 8)
                tab.GroupLabel = gl
                tab.GroupText = string.upper(groupName)
            end

            -- Nút tab
            local btn = Button({
                Name = "Tab", Size = UDim2.new(1, 0, 0, 33), BackgroundColor3 = P.card, BackgroundTransparency = 1,
                LayoutOrder = nextOrder(),
            }, self.TabScroll)
            Round(btn, 8)
            tab.Btn = btn
            tab.Indicator = Frame({
                Name = "Indicator", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(3, 0), BackgroundColor3 = P.accent,
            }, btn)
            Round(tab.Indicator, "full")
            tab.Chip = Frame({
                Name = "Chip", Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(25, 25), BackgroundColor3 = P.card2,
            }, btn)
            Round(tab.Chip, 7)
            tab.ChipText = Label({
                Name = "Emoji", Size = UDim2.fromScale(1, 1), Text = emoji, TextSize = 13.5, TextXAlignment = XC,
            }, tab.Chip)
            tab.TabLabel = Label({
                Name = "Label", Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -40 - 36, 1, 0), Text = label,
                Font = FONT_M, TextSize = 12.5, TextColor3 = P.sub, TextTruncate = Enum.TextTruncate.AtEnd,
            }, btn)
            tab.Badge = Frame({
                Name = "Badge", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(0, 18), AutomaticSize = AUTO_X, BackgroundColor3 = P.accent,
                BackgroundTransparency = 0.84, Visible = false,
            }, btn)
            Round(tab.Badge, "full")
            Pad(tab.Badge, 0, 7, 0, 7)
            tab.BadgeText = Label({
                Name = "N", Text = "0", Font = FONT_B, TextSize = 10.5, TextColor3 = P.accent,
                Size = UDim2.fromOffset(0, 18), AutomaticSize = AUTO_X, TextXAlignment = XC,
            }, tab.Badge)

            -- Trang nội dung
            local page = mk("ScrollingFrame", {
                Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
                CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, ScrollBarThickness = 4,
                ScrollBarImageColor3 = P.stroke, ScrollBarImageTransparency = 0.2,
                ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
                Visible = false, TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
                MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            }, nil, self.Pages)
            Pad(page, 14, 16, 18, 14)
            List(page, 10)
            tab.Page = page
            tab.Empty = Label({
                Name = "Empty", Size = UDim2.new(1, 0, 0, 80), Text = "", Font = FONT, TextSize = 13, TextColor3 = P.mute,
                TextXAlignment = XC, Visible = false, LayoutOrder = 1000000,
            }, page)
            self._conn(page.ChildAdded, function(ch: Instance)
                if ch:IsA("GuiObject") and ch.Name == "QRCard" then
                    local firstSec = tab.sections[1]
                    ch.LayoutOrder = (firstSec and firstSec.Frame and firstSec.Frame.LayoutOrder or 10) + 5
                end
            end)

            btn.MouseEnter:Connect(function()
                if self.CurrentTab ~= tab then tw(btn, { BackgroundTransparency = 0.55 }) end
            end)
            btn.MouseLeave:Connect(function()
                if self.CurrentTab ~= tab then tw(btn, { BackgroundTransparency = 1 }) end
            end)
            btn.MouseButton1Click:Connect(function() tab:Activate() end)

            table.insert(self.tabList, tab)
            self.tabs[name] = tab
            tab:_applyCompact(self.compact)
            if not self.CurrentTab then tab:Activate(true) end
            return tab
        end

        TabMT.__index = function(t: any, k: any)
            local m = rawget(TabMT, k)
            if m ~= nil then return m end
            if type(k) == "string" and string.sub(k, 1, 6) == "Create" then
                return function(self: any, ...)
                    if not self.headless then self.headless = self:CreateSection("") end
                    return self.headless[k](self.headless, ...)
                end
            end
            return nil
        end

        function TabMT:_applyCompact(compact: boolean)
            self.TabLabel.Visible = not compact
            self.Chip.Position = compact and UDim2.new(0.5, -12, 0, 4) or UDim2.fromOffset(8, 4)
            if self.GroupLabel then
                self.GroupLabel.Text = compact and "" or self.GroupText
                self.GroupLabel.Size = UDim2.new(1, 0, 0, compact and 8 or 19)
            end
            self:_refreshBadge()
        end

        function TabMT:_style(active: boolean, instant: boolean?)
            local info = instant and TweenInfo.new(0) or EASE
            tw(self.Btn, { BackgroundTransparency = active and 0 or 1 }, info)
            tw(self.Indicator, { Size = UDim2.fromOffset(3, active and 18 or 0) }, info)
            tw(self.TabLabel, { TextColor3 = active and P.text or P.sub }, info)
            tw(self.Chip, { BackgroundColor3 = active and P.accent or P.card2, BackgroundTransparency = active and 0.8 or 0 }, info)
        end

        function TabMT:_refreshBadge()
            local win = self.Window
            local n = self.onCount or 0
            local searching = win.query ~= ""
            local val = searching and (self.hits or 0) or n
            self.BadgeText.Text = tostring(val)
            self.Badge.Visible = (not win.compact) and val > 0
            if searching then
                tw(self.Badge, { BackgroundColor3 = P.info })
                tw(self.BadgeText, { TextColor3 = P.info })
                tw(self.TabLabel, { TextTransparency = (self.hits or 0) == 0 and 0.6 or 0 })
            else
                tw(self.Badge, { BackgroundColor3 = P.accent })
                tw(self.BadgeText, { TextColor3 = P.accent })
                tw(self.TabLabel, { TextTransparency = 0 })
            end
        end

        function TabMT:_recount()
            local on = 0
            for _, sec in ipairs(self.sections) do
                for _, t in ipairs(sec.toggles) do
                    if t.CurrentValue then on += 1 end
                end
            end
            self.onCount = on
            self:_refreshBadge()
            local win = self.Window
            win:_refreshStatus()
            if win.CurrentTab == self then win:_updateHeader() end
        end

        function TabMT:Activate(instant: boolean?)
            local win = self.Window
            win:_closeDropdown()
            if win.CurrentTab == self and self.Page.Visible then return end
            local prev = win.CurrentTab
            win.CurrentTab = self
            for _, t in ipairs(win.tabList) do
                local active = (t == self)
                t:_style(active, instant or t ~= self and t ~= prev)
                if not active then t.Page.Visible = false end
            end
            self.Page.Visible = true
            if not instant then
                self.Page.Position = UDim2.fromOffset(0, 10)
                tw(self.Page, { Position = UDim2.fromOffset(0, 0) }, EASE_SLOW)
            end
            win.CurrentTab = self
            win:_updateHeader()
        end

        function TabMT:CreateSection(arg: any): any
            local title = type(arg) == "table" and tostring(arg.Name or "") or tostring(arg or "")
            local tab = self
            local sec: any = setmetatable({
                Tab = self, Window = self.Window, Title = title, FoldTitle = fold(title),
                elems = {}, toggles = {}, collapsed = false,
            }, SectionMT)

            local frame = Frame({
                Name = "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = P.card,
                LayoutOrder = nextOrder(),
            }, self.Page)
            Round(frame, 12)
            Stroke(frame, P.strokeSoft, 1, 0)
            List(frame, 0)
            sec.Frame = frame

            if title ~= "" then
                local head = Button({
                    Name = "Header", Size = UDim2.new(1, 0, 0, 42), LayoutOrder = 1,
                }, frame)
                local bar = Frame({
                    Name = "Bar", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
                    Size = UDim2.fromOffset(3, 15), BackgroundColor3 = Color3.new(1, 1, 1),
                }, head)
                Round(bar, "full")
                Grad(bar, P.accent, P.accent2, 90)
                Label({
                    Name = "Title", Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -110, 1, 0), Text = title,
                    Font = FONT_B, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
                }, head)
                sec.Count = Frame({
                    Name = "Count", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -38, 0.5, 0),
                    Size = UDim2.fromOffset(0, 20), AutomaticSize = AUTO_X, BackgroundColor3 = P.accent,
                    BackgroundTransparency = 0.86, Visible = false,
                }, head)
                Round(sec.Count, "full")
                Pad(sec.Count, 0, 8, 0, 8)
                sec.CountText = Label({
                    Name = "N", Text = "0/0", Font = FONT_B, TextSize = 10.5, TextColor3 = P.accent,
                    Size = UDim2.fromOffset(0, 20), AutomaticSize = AUTO_X, TextXAlignment = XC,
                }, sec.Count)
                sec.Chevron = Label({
                    Name = "Chevron", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -20, 0.5, 0),
                    Size = UDim2.fromOffset(18, 18), Text = ">", Font = FONT_B, TextSize = 14, TextColor3 = P.sub,
                    TextXAlignment = XC, Rotation = 90,
                }, head)
                head.MouseButton1Click:Connect(function() sec:SetCollapsed(not sec.collapsed) end)
                head.MouseEnter:Connect(function() tw(sec.Chevron, { TextColor3 = P.text }) end)
                head.MouseLeave:Connect(function() tw(sec.Chevron, { TextColor3 = P.sub }) end)
                sec.Head = head
            end

            local body = Frame({
                Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1,
                LayoutOrder = 2,
            }, frame)
            Pad(body, title ~= "" and 0 or 6, 8, 8, 8)
            List(body, 2)
            sec.Body = body

            table.insert(self.sections, sec)
            return sec
        end

        -- ------------------------------------------------------------
        -- SECTION
        -- ------------------------------------------------------------
        function SectionMT:SetCollapsed(c: boolean)
            self.collapsed = c
            self.Body.Visible = (not c) or (self.Window.query ~= "")
            if self.Chevron then
                tw(self.Chevron, { Rotation = c and 0 or 90 })
            end
        end

        function SectionMT:_recount()
            local total, on = #self.toggles, 0
            for _, t in ipairs(self.toggles) do
                if t.CurrentValue then on += 1 end
            end
            if self.Count then
                self.Count.Visible = total > 0
                self.CountText.Text = on .. "/" .. total
                tw(self.Count, { BackgroundTransparency = on > 0 and 0.78 or 0.92 })
                tw(self.CountText, { TextColor3 = on > 0 and P.accent or P.sub })
            end
            self.Tab:_recount()
        end

        function SectionMT:_register(row: any, name: string, desc: string?)
            table.insert(self.elems, { row = row, key = fold(name .. " " .. (desc or "")) })
        end

        function SectionMT:_row(clickable: boolean, minH: number?): any
            local row
            local props = {
                Name = "Row", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundColor3 = P.hover,
                BackgroundTransparency = 1, LayoutOrder = nextOrder(),
            }
            if clickable then
                row = Button(props, self.Body)
                row.MouseEnter:Connect(function() tw(row, { BackgroundTransparency = 0.45 }) end)
                row.MouseLeave:Connect(function() tw(row, { BackgroundTransparency = 1 }) end)
            else
                row = Frame(props, self.Body)
            end
            Round(row, 9)
            Pad(row, 9, 12, 9, 12)
            mk("UISizeConstraint", { MinSize = Vector2.new(0, minH or 44) }, nil, row)
            return row
        end

        local function buildInfo(parent: Instance, name: string, desc: string?, wScale: number, wOff: number): (any, any, any)
            local info = Frame({
                Name = "Info", BackgroundTransparency = 1, Size = UDim2.new(wScale, wOff, 0, 0), AutomaticSize = AUTO_Y,
                AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(0, 0),
            }, parent)
            mk("UISizeConstraint", { MinSize = Vector2.new(0, 26) }, nil, info)
            mk("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2),
                FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center,
            }, nil, info)
            local title = Label({
                Name = "Title", Text = name, Font = FONT_M, TextSize = 13, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = AUTO_Y, TextWrapped = true, LayoutOrder = 1,
            }, info)
            local d: any = nil
            if desc and desc ~= "" then
                d = Label({
                    Name = "Desc", Text = desc, Font = FONT, TextSize = 11.5, TextColor3 = P.sub,
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true,
                    TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2,
                }, info)
            end
            return info, title, d
        end

        local function safeCall(win: any, row: any, name: string, cb: any, ...: any)
            local ok, err = pcall(cb, ...)
            if not ok then
                warn("[YokaHub UI] Callback lỗi · " .. name .. " · " .. tostring(err))
                if row and row.Parent then
                    row.BackgroundColor3 = P.danger
                    tw(row, { BackgroundTransparency = 0.7 })
                    task.delay(0.7, function()
                        if row and row.Parent then
                            row.BackgroundColor3 = P.hover
                            tw(row, { BackgroundTransparency = 1 })
                        end
                    end)
                end
            end
        end

        -- ============ TOGGLE ============
        function SectionMT:CreateToggle(opts: any, flag: any?): any
            opts = type(opts) == "table" and opts or {}
            local name = tostring(opts.Name or "Toggle")
            local cb = opts.Callback or function() end
            local win = self.Window
            local row = self:_row(true)
            local info, title, descLbl = buildInfo(row, name, opts.Description, 1, -56)
            local sw = Frame({
                Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.fromOffset(40, 22), BackgroundColor3 = P.off,
            }, row)
            Round(sw, "full")
            local fill = Frame({
                Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 1,
            }, sw)
            Round(fill, "full")
            Grad(fill, P.accent, P.accent2, 0)
            local knob = Frame({
                Name = "Knob", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.fromOffset(16, 16), BackgroundColor3 = P.knobOff, ZIndex = 2,
            }, sw)
            Round(knob, "full")

            local obj: any = { Class = "Toggle", Name = name, CurrentValue = opts.CurrentValue == true, Row = row }
            local sec = self

            local function render(instant: boolean?)
                local on = obj.CurrentValue
                local pos = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                local kc = on and Color3.new(1, 1, 1) or P.knobOff
                if instant then
                    fill.BackgroundTransparency = on and 0 or 1
                    knob.Position = pos
                    knob.BackgroundColor3 = kc
                else
                    tw(fill, { BackgroundTransparency = on and 0 or 1 })
                    tw(knob, { Position = pos, BackgroundColor3 = kc })
                end
            end

            local function fire()
                safeCall(win, row, name, cb, obj.CurrentValue)
            end

            row.MouseButton1Click:Connect(function()
                obj.CurrentValue = not obj.CurrentValue
                render()
                sec:_recount()
                fire()
            end)

            function obj:Set(v: any)
                local val = v
                if type(v) == "table" then
                    val = v.CurrentValue
                    if v.Name then title.Text = tostring(v.Name) end
                    if v.Description and descLbl then descLbl.Text = tostring(v.Description) end
                    if v.Callback then cb = v.Callback end
                end
                if val == nil then val = obj.CurrentValue end
                obj.CurrentValue = val and true or false
                render()
                sec:_recount()
                fire()
            end
            function obj:UpdateState(v: boolean)
                obj.CurrentValue = v and true or false
                render()
                sec:_recount()
            end
            function obj:Destroy()
                row:Destroy()
                local i = table.find(sec.toggles, obj)
                if i then table.remove(sec.toggles, i) end
                for j, e in ipairs(sec.elems) do
                    if e.row == row then table.remove(sec.elems, j) break end
                end
                sec:_recount()
            end

            render(true)
            table.insert(self.toggles, obj)
            self:_register(row, name, opts.Description)
            self:_recount()
            return obj
        end

        -- ============ BUTTON ============
        function SectionMT:CreateButton(opts: any): any
            opts = type(opts) == "table" and opts or {}
            local name = tostring(opts.Name or "Button")
            local cb = opts.Callback or function() end
            local danger = opts.Style == "danger" or string.find(name, "Tắt hoàn toàn", 1, true) ~= nil
                or string.find(name, "THOÁT", 1, true) ~= nil or string.find(name, "Dừng toàn bộ", 1, true) ~= nil
                or string.find(name, "⛔", 1, true) ~= nil
            local accent = danger and P.danger or P.accent
            local win = self.Window
            local row = self:_row(true)
            local info, title, descLbl = buildInfo(row, name, opts.Description, 1, -44)
            if danger then title.TextColor3 = RGB(255, 190, 196) end
            local chip = Frame({
                Name = "Chip", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.fromOffset(30, 26), BackgroundColor3 = accent, BackgroundTransparency = 0.86,
            }, row)
            Round(chip, 8)
            local chipStroke = Stroke(chip, accent, 1, 0.7)
            local arrow = Label({
                Name = "Arrow", Size = UDim2.fromScale(1, 1), Text = ">", Font = FONT_B, TextSize = 14,
                TextColor3 = accent, TextXAlignment = XC,
            }, chip)
            row.MouseEnter:Connect(function()
                tw(chip, { BackgroundTransparency = 0.65 })
                tw(chipStroke, { Transparency = 0.3 })
            end)
            row.MouseLeave:Connect(function()
                tw(chip, { BackgroundTransparency = 0.86 })
                tw(chipStroke, { Transparency = 0.7 })
            end)
            local obj: any = { Class = "Button", Name = name, Row = row }
            row.MouseButton1Click:Connect(function()
                chip.BackgroundTransparency = 0.2
                tw(chip, { BackgroundTransparency = 0.86 }, EASE_SLOW)
                safeCall(win, row, name, cb)
            end)
            function obj:Set(v: any)
                if type(v) == "table" then
                    if v.Name then title.Text = tostring(v.Name) end
                    if v.Description and descLbl then descLbl.Text = tostring(v.Description) end
                    if type(v.Callback) == "function" then cb = v.Callback end
                end
            end
            function obj:Destroy() row:Destroy() end
            self:_register(row, name, opts.Description)
            return obj
        end

        -- ============ PARAGRAPH ============
        function SectionMT:CreateParagraph(opts: any): any
            opts = type(opts) == "table" and opts or {}
            local titleText = tostring(opts.Title or "")
            local bodyText = tostring(opts.Text or opts.Content or "")
            local win = self.Window
            local isStatusPara = string.find(titleText, "Trạng thái", 1, true) ~= nil
            local card = Frame({
                Name = "Paragraph", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
                BackgroundColor3 = RGB(20, 34, 38), LayoutOrder = nextOrder(),
            }, self.Body)
            Round(card, 9)
            Stroke(card, P.accent, 1, 0.72)
            Pad(card, 10, 14, 11, 14)
            mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, nil, card)
            local t = Label({
                Name = "Title", Text = titleText, Font = FONT_B, TextSize = 13, TextColor3 = P.accent,
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true, LayoutOrder = 1,
                Visible = titleText ~= "",
            }, card)
            local b = Label({
                Name = "Text", Text = bodyText, Font = FONT, TextSize = 12.5, TextColor3 = RGB(212, 222, 234),
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true, LineHeight = 1.25,
                TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2,
            }, card)
            if isStatusPara and bodyText ~= "" then
                win:SetHint(bodyText)
            end
            local obj: any = { Class = "Paragraph", Row = card, Settings = { Title = titleText, Text = bodyText } }
            function obj:Set(v: any)
                if type(v) ~= "table" then return end
                if v.Title ~= nil and tostring(v.Title) ~= t.Text then
                    t.Text = tostring(v.Title)
                    t.Visible = t.Text ~= ""
                end
                local nt = v.Text ~= nil and v.Text or v.Content
                if nt ~= nil and tostring(nt) ~= b.Text then
                    b.Text = tostring(nt)
                    if isStatusPara then
                        win:SetHint(b.Text)
                    end
                end
            end
            function obj:Update() end
            function obj:Destroy() card:Destroy() end
            self:_register(card, titleText, bodyText)
            return obj
        end

        -- ============ LABEL ============
        function SectionMT:CreateLabel(opts: any): any
            opts = type(opts) == "table" and opts or { Text = tostring(opts) }
            local row = self:_row(false, 32)
            local l = Label({
                Name = "Text", Text = tostring(opts.Text or ""), Font = FONT, TextSize = 12.5, TextColor3 = P.sub,
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true,
            }, row)
            local obj: any = { Row = row }
            function obj:Set(v: any)
                if type(v) == "table" then v = v.Text end
                l.Text = tostring(v or "")
            end
            function obj:Destroy() row:Destroy() end
            self:_register(row, l.Text, "")
            return obj
        end

        function SectionMT:CreateDivider()
            local f = Frame({
                Name = "Divider", Size = UDim2.new(1, -8, 0, 1), BackgroundColor3 = P.strokeSoft, LayoutOrder = nextOrder(),
            }, self.Body)
            return { Destroy = function() f:Destroy() end }
        end

        function SectionMT:CreateCustom(height: number): any
            local f = Frame({
                Name = "Custom", Size = UDim2.new(1, 0, 0, height or 100), BackgroundTransparency = 1, LayoutOrder = nextOrder(),
            }, self.Body)
            self:_register(f, "", "")
            return f
        end

        -- ============ SLIDER ============
        function SectionMT:CreateSlider(opts: any, flag: any?): any
            opts = type(opts) == "table" and opts or {}
            local name = tostring(opts.Name or "Slider")
            local range = opts.Range or { 0, 100 }
            local lo, hi = range[1], range[2]
            local inc = opts.Increment or 1
            local suffix = tostring(opts.Suffix or "")
            local cb = opts.Callback or function() end
            local win = self.Window
            local hasDesc = opts.Description ~= nil and opts.Description ~= ""

            local row = self:_row(false)
            row.AutomaticSize = Enum.AutomaticSize.None
            row.Size = UDim2.new(1, 0, 0, hasDesc and 78 or 62)
            local title = Label({
                Name = "Title", Size = UDim2.new(1, -112, 0, 18), Text = name, Font = FONT_M, TextSize = 13,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)
            if hasDesc then
                Label({
                    Name = "Desc", Position = UDim2.fromOffset(0, 19), Size = UDim2.new(1, -112, 0, 16), Text = opts.Description,
                    Font = FONT, TextSize = 11.5, TextColor3 = P.sub, TextTruncate = Enum.TextTruncate.AtEnd,
                }, row)
            end
            local valBox = Box({
                Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromOffset(98, 24), BackgroundTransparency = 0, BackgroundColor3 = P.card2,
                Font = FONT_B, TextSize = 12, TextColor3 = P.accent, TextXAlignment = XC, ClearTextOnFocus = false,
            }, row)
            Round(valBox, 7)
            local valStroke = Stroke(valBox, P.strokeSoft, 1, 0)

            local trackY = hasDesc and 52 or 38
            local hit = Button({
                Name = "Hit", Position = UDim2.fromOffset(0, trackY - 8), Size = UDim2.new(1, 0, 0, 22),
            }, row)
            local track = Frame({
                Name = "Track", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = P.off,
            }, hit)
            Round(track, "full")
            local fillBar = Frame({
                Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1),
            }, track)
            Round(fillBar, "full")
            Grad(fillBar, P.accent, P.accent2, 0)
            local knob = Frame({
                Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2,
            }, track)
            Round(knob, "full")
            Stroke(knob, P.accent, 2, 0)

            local function snap(v: number): number
                v = math.clamp(v, lo, hi)
                if inc and inc > 0 then
                    v = lo + math.floor((v - lo) / inc + 0.5) * inc
                    v = math.clamp(v, lo, hi)
                end
                return tonumber(string.format("%.4f", v)) or v
            end
            local obj: any = { Class = "Slider", Name = name, Row = row, CurrentValue = snap(opts.CurrentValue or lo) }

            local function fmt(v: number): string
                if v == math.floor(v) then return tostring(math.floor(v)) .. suffix end
                return tostring(v) .. suffix
            end
            local function render(v: number, animate: boolean?)
                local frac = (hi > lo) and (v - lo) / (hi - lo) or 0
                if animate then
                    tw(fillBar, { Size = UDim2.fromScale(frac, 1) }, TweenInfo.new(0.08))
                    tw(knob, { Position = UDim2.fromScale(frac, 0.5) }, TweenInfo.new(0.08))
                else
                    fillBar.Size = UDim2.fromScale(frac, 1)
                    knob.Position = UDim2.fromScale(frac, 0.5)
                end
                if not valBox:IsFocused() then valBox.Text = fmt(v) end
            end
            local function commit(v: number, fireCb: boolean)
                v = snap(v)
                local changed = v ~= obj.CurrentValue
                obj.CurrentValue = v
                render(v, true)
                if fireCb and changed then safeCall(win, row, name, cb, v) end
            end

            local dragging = false
            local function fromInput(input: InputObject)
                local w = track.AbsoluteSize.X
                if w <= 0 then return end
                local frac = math.clamp((input.Position.X - track.AbsolutePosition.X) / w, 0, 1)
                commit(lo + frac * (hi - lo), true)
            end
            win._conn(hit.InputBegan, function(input: InputObject)
                if isPress(input) then
                    dragging = true
                    tw(knob, { Size = UDim2.fromOffset(18, 18) })
                    fromInput(input)
                end
            end)
            win._conn(UserInputService.InputChanged, function(input: InputObject)
                if dragging and isMove(input) then fromInput(input) end
            end)
            win._conn(UserInputService.InputEnded, function(input: InputObject)
                if dragging and isPress(input) then
                    dragging = false
                    tw(knob, { Size = UDim2.fromOffset(14, 14) })
                end
            end)
            win._conn(valBox.Focused, function()
                valBox.Text = tostring(obj.CurrentValue)
                tw(valStroke, { Color = P.accent })
            end)
            win._conn(valBox.FocusLost, function()
                tw(valStroke, { Color = P.strokeSoft })
                local n = tonumber(string.match(valBox.Text, "-?%d+%.?%d*"))
                if n then commit(n, true) end
                valBox.Text = fmt(obj.CurrentValue)
            end)

            function obj:Set(v: any)
                local val = v
                if type(v) == "table" then
                    val = v.CurrentValue
                    if v.Name then title.Text = tostring(v.Name) end
                    if v.Callback then cb = v.Callback end
                end
                val = snap(tonumber(val) or obj.CurrentValue)
                obj.CurrentValue = val
                render(val, true)
                safeCall(win, row, name, cb, val)
            end
            function obj:UpdateValue(v: any) obj:Set(tonumber(v)) end
            function obj:Destroy() row:Destroy() end

            render(obj.CurrentValue)
            self:_register(row, name, opts.Description)
            safeCall(win, row, name, cb, obj.CurrentValue)
            return obj
        end

        -- ============ INPUT ============
        function SectionMT:CreateInput(opts: any, flag: any?): any
            opts = type(opts) == "table" and opts or {}
            local name = tostring(opts.Name or "Input")
            local cb = opts.Callback or function() end
            local win = self.Window
            local row = self:_row(false)
            local info, title, descLbl = buildInfo(row, name, opts.Description, 0.5, -8)
            local holder = Frame({
                Name = "Field", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.new(0.44, 0, 0, 30), BackgroundColor3 = P.card2,
            }, row)
            Round(holder, 8)
            local st = Stroke(holder, P.strokeSoft, 1, 0)
            mk("UISizeConstraint", { MinSize = Vector2.new(110, 30), MaxSize = Vector2.new(240, 30) }, nil, holder)
            local box = Box({
                Name = "Input", Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
                PlaceholderText = tostring(opts.PlaceholderText or ""), Text = tostring(opts.CurrentValue or ""),
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, holder)
            local obj: any = { Class = "Input", Name = name, Row = row, CurrentValue = box.Text }
            win._conn(box.Focused, function() tw(st, { Color = P.accent }) end)
            win._conn(box.FocusLost, function(enter: boolean)
                tw(st, { Color = P.strokeSoft })
                local txt = box.Text
                if opts.Numeric then txt = string.gsub(txt, "[^%d%.%-]", "") box.Text = txt end
                obj.CurrentValue = txt
                safeCall(win, row, name, cb, txt)
                if opts.RemoveTextAfterFocusLost then box.Text = "" end
            end)
            function obj:Set(v: any)
                if type(v) == "table" then
                    if v.CurrentValue ~= nil then box.Text = tostring(v.CurrentValue) end
                    if v.Name then title.Text = tostring(v.Name) end
                else
                    box.Text = tostring(v or "")
                end
                obj.CurrentValue = box.Text
            end
            function obj:Destroy() row:Destroy() end
            self:_register(row, name, opts.Description)
            return obj
        end

        -- ============ DROPDOWN ============
        local function normalizeSel(cur: any, multi: boolean): { string }
            local out = {}
            if type(cur) == "string" then
                out = { cur }
            elseif type(cur) == "table" then
                for _, v in ipairs(cur) do
                    if v ~= nil then table.insert(out, tostring(v)) end
                end
            end
            if not multi and #out > 1 then out = { out[1] } end
            return out
        end

        function Lib:_closeDropdown()
            if self.ddClose then
                local f = self.ddClose
                self.ddClose = nil
                pcall(f)
            end
        end

        function Lib:_openDropdown(anchor: any, cfg: any)
            self:_closeDropdown()
            local root = self.Root
            local s = self.scale
            local options = cfg.options
            local multi = cfg.multi
            local hasSearch = #options > 8

            local blocker = Button({ Name = "DropdownBlocker", Size = UDim2.fromScale(1, 1), ZIndex = 60 }, root)
            local popW = math.max(anchor.AbsoluteSize.X / s, 210)
            local rowH = 32
            local bodyH = math.max(42, math.min(#options * (rowH + 2) + 10, 250))
            local popH = bodyH + (hasSearch and 44 or 0)
            local bx = (anchor.AbsolutePosition.X - root.AbsolutePosition.X) / s
            local by = (anchor.AbsolutePosition.Y - root.AbsolutePosition.Y) / s
            local bw = anchor.AbsoluteSize.X / s
            local bh = anchor.AbsoluteSize.Y / s
            local x = math.clamp(bx + bw - popW, 8, math.max(8, self.W - popW - 8))
            local y = by + bh + 6
            if y + popH > self.H - 8 then y = by - popH - 6 end
            y = math.clamp(y, 8, math.max(8, self.H - popH - 8))

            local pop = Frame({
                Name = "Dropdown", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(popW, popH),
                BackgroundColor3 = RGB(24, 28, 39), ZIndex = 61,
            }, root)
            Round(pop, 11)
            Stroke(pop, P.accent, 1, 0.55)
            local sc = mk("UIScale", { Scale = 0.94 }, nil, pop)
            tw(sc, { Scale = 1 }, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out))

            local filterText = ""
            local listFrame = mk("ScrollingFrame", {
                Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0,
                Position = UDim2.fromOffset(0, hasSearch and 44 or 0), Size = UDim2.new(1, 0, 0, bodyH),
                CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO_Y, ScrollBarThickness = 3,
                ScrollBarImageColor3 = P.stroke, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 62,
            }, nil, pop)
            Pad(listFrame, 5, 5, 5, 5)
            List(listFrame, 2)

            local buttons: { [string]: any } = {}
            local selected: { [string]: boolean } = {}
            for _, v in ipairs(cfg.current()) do selected[v] = true end

            local function paint(btn: any, opt: string, instant: boolean?)
                local on = selected[opt] == true
                local lbl = btn:FindFirstChild("L")
                local dot = btn:FindFirstChild("Dot")
                local props = { BackgroundTransparency = on and 0.8 or 1 }
                if instant then
                    btn.BackgroundTransparency = props.BackgroundTransparency
                    lbl.TextColor3 = on and P.accent or P.text
                    lbl.Font = on and FONT_B or FONT_M
                    dot.BackgroundTransparency = on and 0 or 1
                else
                    tw(btn, props)
                    tw(lbl, { TextColor3 = on and P.accent or P.text })
                    lbl.Font = on and FONT_B or FONT_M
                    tw(dot, { BackgroundTransparency = on and 0 or 1 })
                end
            end

            for i, opt in ipairs(options) do
                local b = Button({
                    Name = "Opt", Size = UDim2.new(1, 0, 0, rowH), BackgroundColor3 = P.accent, BackgroundTransparency = 1,
                    LayoutOrder = i, ZIndex = 63,
                }, listFrame)
                Round(b, 8)
                Label({
                    Name = "L", Position = UDim2.fromOffset(11, 0), Size = UDim2.new(1, -34, 1, 0), Text = opt,
                    Font = FONT_M, TextSize = 12.5, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 64,
                }, b)
                local dot = Frame({
                    Name = "Dot", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -11, 0.5, 0),
                    Size = UDim2.fromOffset(8, 8), BackgroundColor3 = P.accent, BackgroundTransparency = 1, ZIndex = 64,
                }, b)
                Round(dot, "full")
                buttons[opt] = b
                paint(b, opt, true)
                b.MouseEnter:Connect(function()
                    if not selected[opt] then tw(b, { BackgroundColor3 = P.hover, BackgroundTransparency = 0.3 }) end
                end)
                b.MouseLeave:Connect(function()
                    if not selected[opt] then tw(b, { BackgroundTransparency = 1 }) end
                end)
                b.MouseButton1Click:Connect(function()
                    if multi then
                        selected[opt] = not selected[opt] or nil
                        b.BackgroundColor3 = P.accent
                        paint(b, opt)
                        local list = {}
                        for _, o2 in ipairs(options) do
                            if selected[o2] then table.insert(list, o2) end
                        end
                        cfg.pick(list)
                    else
                        cfg.pick({ opt })
                        self:_closeDropdown()
                    end
                end)
            end

            if hasSearch then
                local sf = Frame({
                    Name = "Search", Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 30),
                    BackgroundColor3 = P.card2, ZIndex = 62,
                }, pop)
                Round(sf, 8)
                Stroke(sf, P.strokeSoft, 1, 0)
                local sb = Box({
                    Name = "In", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0),
                    PlaceholderText = "Lọc danh sách…", ZIndex = 63,
                }, sf)
                sb:GetPropertyChangedSignal("Text"):Connect(function()
                    filterText = fold(sb.Text)
                    for _, opt in ipairs(options) do
                        buttons[opt].Visible = filterText == "" or string.find(fold(opt), filterText, 1, true) ~= nil
                    end
                end)
            end

            self.ddClose = function()
                pcall(function() blocker:Destroy() end)
                local t = tw(sc, { Scale = 0.94 }, TweenInfo.new(0.1))
                pcall(function() pop:Destroy() end)
            end
            blocker.MouseButton1Click:Connect(function() self:_closeDropdown() end)
        end

        function SectionMT:CreateDropdown(opts: any, flag: any?): any
            opts = type(opts) == "table" and opts or {}
            local name = tostring(opts.Name or "Dropdown")
            local cb = opts.Callback or function() end
            local multi = opts.MultipleOptions == true
            local win = self.Window
            local options: { string } = {}
            for _, v in ipairs(opts.Options or {}) do table.insert(options, tostring(v)) end

            local row = self:_row(false, 48)
            local info, title, descLbl = buildInfo(row, name, opts.Description, 0.54, -8)
            local sel = Button({
                Name = "Select", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.new(0.44, 0, 0, 32), BackgroundColor3 = P.card2, BackgroundTransparency = 0,
            }, row)
            Round(sel, 8)
            local selStroke = Stroke(sel, P.strokeSoft, 1, 0)
            mk("UISizeConstraint", { MinSize = Vector2.new(120, 32), MaxSize = Vector2.new(250, 32) }, nil, sel)
            local selLabel = Label({
                Name = "Value", Position = UDim2.fromOffset(11, 0), Size = UDim2.new(1, -34, 1, 0), Text = "",
                Font = FONT_M, TextSize = 12.5, TextColor3 = P.accent, TextTruncate = Enum.TextTruncate.AtEnd,
            }, sel)
            local caret = Label({
                Name = "Caret", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0),
                Size = UDim2.fromOffset(16, 16), Text = ">", Font = FONT_B, TextSize = 13, TextColor3 = P.sub,
                TextXAlignment = XC, Rotation = 90,
            }, sel)

            local obj: any = { Class = "Dropdown", Name = name, Row = row }
            local current = normalizeSel(opts.CurrentOption, multi)
            obj.CurrentOption = current

            local function label()
                if #current == 0 then
                    selLabel.Text = "Chưa chọn"
                    selLabel.TextColor3 = P.mute
                elseif #current == 1 then
                    selLabel.Text = current[1]
                    selLabel.TextColor3 = P.accent
                else
                    selLabel.Text = table.concat(current, ", ")
                    selLabel.TextColor3 = P.accent
                end
            end
            local function emit()
                local arg: any = (#current == 1) and current[1] or current
                safeCall(win, row, name, cb, arg)
            end

            row.MouseEnter:Connect(function() tw(selStroke, { Color = P.stroke }) end)
            row.MouseLeave:Connect(function() tw(selStroke, { Color = P.strokeSoft }) end)
            sel.MouseButton1Click:Connect(function()
                tw(caret, { Rotation = 270 })
                win:_openDropdown(sel, {
                    options = options, multi = multi,
                    current = function() return current end,
                    pick = function(list: { string })
                        current = list
                        obj.CurrentOption = current
                        label()
                        emit()
                    end,
                })
                task.defer(function()
                    local f = win.ddClose
                    if f then
                        win.ddClose = function()
                            tw(caret, { Rotation = 90 })
                            f()
                        end
                    end
                end)
            end)

            function obj:Set(v: any)
                if type(v) == "table" then
                    if v.Options ~= nil then
                        options = {}
                        for _, o2 in ipairs(v.Options) do table.insert(options, tostring(o2)) end
                    end
                    if v.CurrentOption ~= nil then
                        current = normalizeSel(v.CurrentOption, multi)
                    elseif v.Options ~= nil then
                        local keep = {}
                        for _, c in ipairs(current) do
                            if table.find(options, c) then table.insert(keep, c) end
                        end
                        current = keep
                    end
                    if v.Name then title.Text = tostring(v.Name) end
                    if v.Callback then cb = v.Callback end
                else
                    current = normalizeSel(v, multi)
                end
                obj.CurrentOption = current
                label()
                emit()
            end
            function obj:Refresh(list: { any }) obj:Set({ Options = list }) end
            function obj:Destroy() row:Destroy() end

            label()
            self:_register(row, name, opts.Description)
            emit()
            return obj
        end

        SectionMT.__index = SectionMT

        -- ============================================================
        -- NOTIFICATION (toast)
        -- ============================================================
        function Lib:Notification(o: any)
            if self.destroyed then return end
            o = type(o) == "table" and o or {}
            local title = tostring(o.Title or "YokaHub")
            local content = tostring(o.Content or o.Text or "")
            local key = title .. "|" .. content
            local now = os.clock()
            if self.toastRecent[key] and now - self.toastRecent[key] < 1.5 then return end
            self.toastRecent[key] = now
            local dur = tonumber(o.Duration) or 3.2
            local kind = KIND_OF[tostring(o.Icon or "")] or "info"
            local col = KIND_COLOR[kind]

            -- tối đa 4 toast cùng lúc
            local alive = {}
            for _, c in ipairs(self.Toasts:GetChildren()) do
                if c:IsA("Frame") then table.insert(alive, c) end
            end
            if #alive >= 4 then table.sort(alive, function(a, b) return a.LayoutOrder < b.LayoutOrder end) alive[1]:Destroy() end

            local wrap = Frame({
                Name = "ToastWrap", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1,
                LayoutOrder = nextOrder(),
            }, self.Toasts)
            local card = Button({
                Name = "Toast", Position = UDim2.fromOffset(340, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
                BackgroundColor3 = RGB(22, 26, 36), BackgroundTransparency = 0,
            }, wrap)
            Round(card, 11)
            Stroke(card, col, 1, 0.55)
            Pad(card, 11, 14, 11, 14)
            mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, nil, card)
            Label({
                Name = "T", Text = title, Font = FONT_B, TextSize = 12.5, TextColor3 = col,
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true, LayoutOrder = 1,
            }, card)
            if content ~= "" then
                Label({
                    Name = "C", Text = content, Font = FONT, TextSize = 12, TextColor3 = RGB(204, 214, 228),
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true,
                    TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2,
                }, card)
            end
            local progTrack = Frame({
                Name = "ProgTrack", Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = P.card2, LayoutOrder = 3,
            }, card)
            Round(progTrack, "full")
            local prog = Frame({
                Name = "Prog", Size = UDim2.fromScale(1, 1), BackgroundColor3 = col,
            }, progTrack)
            Round(prog, "full")

            local closed = false
            local function close()
                if closed then return end
                closed = true
                local t = tw(card, { Position = UDim2.fromOffset(340, 0) }, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
                if t then
                    t.Completed:Once(function() pcall(function() wrap:Destroy() end) end)
                else
                    pcall(function() wrap:Destroy() end)
                end
            end
            card.MouseButton1Click:Connect(close)
            tw(card, { Position = UDim2.fromOffset(0, 0) }, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            tw(prog, { Size = UDim2.fromScale(0, 1) }, TweenInfo.new(dur, Enum.EasingStyle.Linear))
            task.delay(dur, close)
        end

        return Lib
    end)()


    -- 5. Khoi tao YokaUI v3 Native Suite (khong phu thuoc thu vien ngoai, fallback icon an toan: http://www.roblox.com/asset/?id=6026568195)
    local Window: any = nil
    local Luna: any = nil
    local uiBootstrapping = true
    task.defer(function()
        uiBootstrapping = false
    end)

    local function safeNotify(title: string, content: string, icon: string?)
        if uiBootstrapping and title ~= "Tự chuyển Sea" then
            return
        end
        task.spawn(function()
            pcall(function()
                if Window and typeof(Window.Notification) == "function" then
                    Window:Notification({
                        Title = title,
                        Content = content,
                        Icon = icon or "public",
                        ImageSource = "Material",
                        Duration = 3,
                    })
                end
            end)
        end)
    end

    local curSeaLabel = "Sea ?"
    if game.PlaceId == SEA3_PLACE then curSeaLabel = "Sea 3"
    elseif game.PlaceId == SEA2_PLACE then curSeaLabel = "Sea 2"
    elseif game.PlaceId == SEA1_PLACE then curSeaLabel = "Sea 1"
    end

    local function getRealQueueOnTeleport(): ((string) -> ())?
        if typeof(genv._YokaRealQueueOnTeleport) == "function" and genv._YokaRealQueueOnTeleport ~= genv._YokaNoopQ then
            return genv._YokaRealQueueOnTeleport
        end
        local candidates: { any } = {
            genv.queue_on_teleport,
            genv.queue_on_tp,
            genv.queueonteleport,
            genv.queueontp,
            typeof(genv.syn) == "table" and genv.syn.queue_on_teleport or nil,
            typeof(genv.fluxus) == "table" and genv.fluxus.queue_on_teleport or nil,
        }
        local envOk, fenv = pcall(function() return getfenv(0) end)
        if envOk and typeof(fenv) == "table" then
            local f: any = fenv
            table.insert(candidates, f.queue_on_teleport)
            table.insert(candidates, f.queue_on_tp)
            table.insert(candidates, f.queueonteleport)
            table.insert(candidates, f.queueontp)
        end
        for _, fn in ipairs(candidates) do
            if typeof(fn) == "function" and fn ~= genv._YokaNoopQ then
                genv._YokaRealQueueOnTeleport = fn
                return fn
            end
        end
        return nil
    end

    local function getYokaLoaderUrl(): string
        if typeof(genv._YokaHubLoaderUrl) == "string" and #genv._YokaHubLoaderUrl > 10 then
            return genv._YokaHubLoaderUrl
        end
        if typeof(isf) == "function" and typeof(rf) == "function" then
            local okEx, ex = pcall(isf, "YokaHub_LoaderUrl.txt")
            if okEx and ex then
                local okR, u = pcall(rf, "YokaHub_LoaderUrl.txt")
                if okR and typeof(u) == "string" then
                    u = string.gsub(u, "%s+", "")
                    if #u > 10 then
                        genv._YokaHubLoaderUrl = u
                        return u
                    end
                end
            end
        end
        return "https://gist.githubusercontent.com/quystptv00383-commits/7dde495f53b84afb7cf64c06c15dfe2d/raw/YokaHub.luau"
    end

    local function armAutoReexec(notifyUser: boolean): boolean
        if not hubState.autoReexec and not hubState.autoClickPlay and currentMode == "off" then return false end
        local qFn = getRealQueueOnTeleport()
        if not qFn then
            if notifyUser then
                safeNotify("YokaHub", "Client hiện tại chưa hỗ trợ queue_on_teleport.", "info")
            end
            return false
        end
        if genv._YokaReexecQueued then
            if notifyUser then
                safeNotify("YokaHub", "Đã bật tự chạy lại & tự nhấn Play khi chuyển server.", "check_circle")
            end
            return true
        end
        local loaderUrl = getYokaLoaderUrl()
        local escapedUrl = string.gsub(loaderUrl, "\\", "\\\\")
        escapedUrl = string.gsub(escapedUrl, '"', '\\"')
        local payload = table.concat({
            'if game.GameId ~= 1451439645 then return end',
            'task.spawn(function()',
            '    if not game:IsLoaded() then pcall(function() game.Loaded:Wait() end) end',
            '    local g = getgenv()',
            '    local rf, isf = g.readfile or readfile, g.isfile or isfile',
            '    local allowPlay, allowReexec = true, true',
            '    if typeof(isf) == "function" and typeof(rf) == "function" and isf("YokaHub_State.json") then',
            '        local ok, raw = pcall(rf, "YokaHub_State.json")',
            '        if ok and typeof(raw) == "string" then',
            '            if string.find(raw, \'"autoClickPlay":false\', 1, true) then allowPlay = false end',
            '            if string.find(raw, \'"autoReexec":false\', 1, true) and string.find(raw, \'"mode":"off"\', 1, true) then allowReexec = false end',
            '        end',
            '    end',
            '    if allowPlay then',
            '        task.spawn(function()',
            '            local lp = game:GetService("Players").LocalPlayer or game:GetService("Players").PlayerAdded:Wait()',
            '            local lgt = game:GetService("Lighting")',
            '            local t0 = os.clock()',
            '            while (os.clock() - t0) < 40 do',
            '                task.wait(0.25)',
            '                local pgui = lp:FindFirstChild("PlayerGui")',
            '                local lg = pgui and pgui:FindFirstChild("LoadingGUI")',
            '                if lp:GetAttribute("Playing") == true and not lg then break end',
            '                if not lp:FindFirstChild("DataLoaded") and (os.clock() - t0) < 10 then continue end',
            '                if lg and not lgt:FindFirstChild("TeamBlur") and (os.clock() - t0) < 5 then continue end',
            '                pcall(function()',
            '                    local playBtn = lg and (lg:FindFirstChild("Play") or lg:FindFirstChild("Play", true))',
            '                    if playBtn and playBtn:IsA("GuiButton") then',
            '                        playBtn.Visible = true; playBtn.Active = true',
            '                        if playBtn.Size.X.Scale < 0.05 then playBtn.Size = UDim2.new(0.211, 0, 0.107, 0) end',
            '                        if typeof(getconnections) == "function" then',
            '                            for _, c in ipairs(getconnections(playBtn.MouseButton1Click)) do',
            '                                pcall(function() if typeof(c.Fire) == "function" then c:Fire() end end)',
            '                            end',
            '                        end',
            '                        if typeof(firesignal) == "function" then',
            '                            pcall(function() firesignal(playBtn.MouseButton1Click) end)',
            '                        end',
            '                    end',
            '                    if lp:GetAttribute("Playing") ~= true then',
            '                        local etc = game:GetService("ReplicatedStorage"):FindFirstChild("Chest")',
            '                        etc = etc and etc:FindFirstChild("Remotes") and etc.Remotes:FindFirstChild("Functions") and etc.Remotes.Functions:FindFirstChild("EtcFunction")',
            '                        if etc then pcall(function() etc:InvokeServer("EnterTheGame", {}) end) end',
            '                    end',
            '                end)',
            '                task.wait(0.5)',
            '            end',
            '        end)',
            '    end',
            '    if not allowReexec then return end',
            '    task.wait(0.4)',
            '    if g._YokaHubScriptKingLoaded then return end',
            '    g._YokaHubScriptKingLoaded = true',
            '    local url = "' .. escapedUrl .. '"',
            '    local src = nil',
            '    if #url > 10 then',
            '        g._YokaHubLoaderUrl = url',
            '        local ok, res = pcall(function() return game:HttpGet(url .. "?t=" .. tostring(os.time())) end)',
            '        if ok and typeof(res) == "string" and #res > 1000 then src = res end',
            '    end',
            '    if not src and typeof(isf) == "function" and typeof(rf) == "function" and isf("YokaHub.luau") then',
            '        local ok, res = pcall(rf, "YokaHub.luau")',
            '        if ok and typeof(res) == "string" and #res > 1000 then src = res end',
            '    end',
            '    if src then local fn = loadstring(src); if fn then task.spawn(fn) end end',
            'end)',
        }, "\n")
        local okQ = pcall(qFn, payload)
        if okQ then
            genv._YokaReexecQueued = true
            if notifyUser then
                safeNotify("YokaHub", "Đã bật tự động chạy lại & tự nhấn Play khi vào SV mới.", "check_circle")
            end
            return true
        else
            if notifyUser then
                safeNotify("YokaHub", "Không thể đăng ký tự chạy lại trên client này.", "info")
            end
            return false
        end
    end

    local isSwitchingSea = false
    local lastSeaSwitchClock = 0

    local YokaNet = (function()
        local net = {}
        local pubCache: { [number]: { data: { any }, cursor: string?, fetchedAt: number } } = {}
        local privCache = { url = "", snap = nil :: any, fetchedAt = 0 }
        local reportCooldowns: { [string]: number } = {}
        local discordCooldowns: { [string]: number } = {}
        local cachedLocalDiscordUrl = ""
        local cachedLocalDiscordAt = 0
        local mvcHealth = { url = "", checkedAt = 0, alive = false }
        local lastConfigSyncAt = 0
        local lastSessionSyncAt = 0

        function net.getReachableSqlMvcUrl(): string
            if hubState.syncToLocalSql == false then return "" end
            local sqlUrl = net.normalizeBaseUrl(hubState.mvcSqlServerUrl or "http://127.0.0.1:8787")
            if sqlUrl == "" then return "" end
            local now = os.clock()
            if mvcHealth.url == sqlUrl and (now - mvcHealth.checkedAt) < 15.0 then
                return mvcHealth.alive and sqlUrl or ""
            end
            mvcHealth.url = sqlUrl
            mvcHealth.checkedAt = now
            local okH, codeH, rawH = net.httpRequest("GET", sqlUrl .. "/api/health")
            mvcHealth.alive = (okH and codeH == 200 and typeof(rawH) == "string" and string.find(rawH, "YokaHubDB", 1, true) ~= nil)
            return mvcHealth.alive and sqlUrl or ""
        end

        function net.normalizeDiscordWebhook(raw: any): string
            local s = string.gsub(tostring(raw or ""), "%s+", "")
            if string.match(s, "^https://discord%.com/api/webhooks/%d+/[%w%-%_]+$") or string.match(s, "^https://discordapp%.com/api/webhooks/%d+/[%w%-%_]+$") then
                return s
            end
            return ""
        end

        function net.getBossDiscordWebhook(): string
            local fromState = net.normalizeDiscordWebhook(hubState.bossDiscordWebhook)
            if fromState ~= "" then return fromState end
            local now = os.clock()
            if (now - cachedLocalDiscordAt) < 10.0 then
                return cachedLocalDiscordUrl
            end
            cachedLocalDiscordAt = now
            cachedLocalDiscordUrl = ""
            if typeof(isf) == "function" and typeof(rf) == "function" then
                local okEx, exists = pcall(isf, "YokaHub_BossWebhook.txt")
                if okEx and exists then
                    local okR, raw = pcall(rf, "YokaHub_BossWebhook.txt")
                    if okR and typeof(raw) == "string" then
                        cachedLocalDiscordUrl = net.normalizeDiscordWebhook(raw)
                    end
                end
            end
            return cachedLocalDiscordUrl
        end

        local function getReqFn(): any
            return (genv.syn and genv.syn.request) or (genv.http and genv.http.request) or genv.request or genv.http_request
        end

        function net.normalizeBaseUrl(raw: any): string
            local s = string.gsub(tostring(raw or ""), "%s+", "")
            s = string.gsub(s, "/+$", "")
            if string.match(s, "^https?://[%w%.%-_]+") then
                return s
            end
            return ""
        end

        function net.httpRequest(method: string, url: string, bodyTbl: any?, extraHeaders: { [string]: string }?): (boolean, number, string?)
            local req = getReqFn()
            local headers: { [string]: string } = { ["Accept"] = "application/json" }
            if extraHeaders then
                for k, v in pairs(extraHeaders) do headers[k] = v end
            end
            local bodyStr: string? = nil
            if bodyTbl ~= nil then
                headers["Content-Type"] = "application/json"
                local okEnc, enc = pcall(function() return httpService:JSONEncode(bodyTbl) end)
                if okEnc and typeof(enc) == "string" then bodyStr = enc end
            end
            if req then
                local okReq, res = pcall(req, {
                    Url = url,
                    Method = method,
                    Headers = headers,
                    Body = bodyStr,
                })
                if okReq and typeof(res) == "table" then
                    local code = tonumber(res.StatusCode or res.status or 200) or 0
                    local b = res.Body or res.body
                    return (code >= 200 and code < 300), code, (typeof(b) == "string" and b or nil)
                end
            end
            if method == "GET" then
                local okGet, raw = pcall(function() return game:HttpGet(url) end)
                if okGet and typeof(raw) == "string" and #raw > 0 then
                    return true, 200, raw
                end
            end
            return false, 0, nil
        end

        local function getPrivateHeaders(): { [string]: string }?
            local key = string.gsub(tostring(hubState.privateBossApiKey or ""), "%s+", "")
            if key ~= "" then
                return { ["x-yoka-key"] = key }
            end
            return nil
        end

        function net.findPublicServers(placeId: number, visitedTbl: { [string]: number }?, prefMinPlayers: number?, prefMaxMargin: number?, visitedPrefix: string?): { any }
            local minP = prefMinPlayers or 2
            local margin = prefMaxMargin or 2
            local prefix = visitedPrefix or ""
            local cache = pubCache[placeId]
            local now = os.clock()

            local function filterFromRawList(rawList: { any }): { any }
                local out = {}
                for _, srv in ipairs(rawList) do
                    local id = tostring(srv.id or "")
                    local cur = tonumber(srv.playing) or 99
                    local maxP = tonumber(srv.maxPlayers) or 12
                    local ping = tonumber(srv.ping) or 999
                    local vKey = prefix .. id
                    local alreadyVisited = (visitedTbl ~= nil and visitedTbl[vKey] ~= nil)
                    if id ~= "" and id ~= game.JobId and cur >= 1 and cur < maxP and not alreadyVisited then
                        local tier = 1
                        if cur >= minP and cur <= (maxP - margin) and ping <= 220 then
                            tier = 3
                        elseif cur <= (maxP - margin) or ping <= 260 then
                            tier = 2
                        end
                        table.insert(out, {
                            jobId = id,
                            serverRef = id,
                            placeId = placeId,
                            eventName = string.format("Public %d/%d · %dms", cur, maxP, ping),
                            source = "yoka_public",
                            alive = true,
                            players = { current = cur, max = maxP },
                            health = { percent = 100 },
                            ping = ping,
                            _prio = tier,
                            _tier = tier,
                            _pCur = cur,
                            _hp = 100,
                            _isPublicHop = true,
                        })
                    end
                end
                table.sort(out, function(a, b)
                    if a._tier ~= b._tier then return a._tier > b._tier end
                    if a.ping ~= b.ping then return a.ping < b.ping end
                    return a._pCur < b._pCur
                end)
                return out
            end

            local list = (cache and (now - cache.fetchedAt) < 25.0) and filterFromRawList(cache.data) or {}
            if #list == 0 then
                local cursorPart = (cache and cache.cursor and cache.cursor ~= "") and ("&cursor=" .. cache.cursor) or ""
                local apiUrl = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/0?sortOrder=1&excludeFullGames=true&limit=100" .. cursorPart
                local okHttp, _, rawJson = net.httpRequest("GET", apiUrl)
                if not okHttp and cursorPart ~= "" then
                    apiUrl = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/0?sortOrder=1&excludeFullGames=true&limit=100"
                    okHttp, _, rawJson = net.httpRequest("GET", apiUrl)
                end
                if okHttp and typeof(rawJson) == "string" then
                    local okDec, decoded = pcall(function() return httpService:JSONDecode(rawJson) end)
                    if okDec and typeof(decoded) == "table" and typeof(decoded.data) == "table" then
                        pubCache[placeId] = {
                            data = decoded.data,
                            cursor = (typeof(decoded.nextPageCursor) == "string" and decoded.nextPageCursor ~= "") and decoded.nextPageCursor or nil,
                            fetchedAt = now,
                        }
                        list = filterFromRawList(decoded.data)
                    end
                elseif cache and #cache.data > 0 then
                    list = filterFromRawList(cache.data)
                end
            end
            return list
        end

        function net.fetchLiveBossSnapshot(): (boolean, any)
            local merged = {}
            local seen: { [string]: boolean } = {}
            local hasPrivate = false
            local hasWukong = false
            local apiUrls: { string } = {}
            local customPriv = net.normalizeBaseUrl(hubState.privateBossApiUrl)
            local localSql = net.getReachableSqlMvcUrl()
            if customPriv ~= "" then table.insert(apiUrls, customPriv) end
            if localSql ~= "" and localSql ~= customPriv then table.insert(apiUrls, localSql) end

            for _, baseUrl in ipairs(apiUrls) do
                local now = os.clock()
                local privEntries: { any }? = nil
                if privCache.url == baseUrl and (now - privCache.fetchedAt) < 2.0 and typeof(privCache.snap) == "table" then
                    privEntries = privCache.snap
                    hasPrivate = true
                else
                    local okReq, _, raw = net.httpRequest("GET", baseUrl .. "/api/bosses", nil, getPrivateHeaders())
                    if okReq and typeof(raw) == "string" then
                        local okDec, dec = pcall(function() return httpService:JSONDecode(raw) end)
                        if okDec and typeof(dec) == "table" then
                            local arr = (typeof(dec.entries) == "table") and dec.entries or dec
                            if typeof(arr) == "table" then
                                privEntries = arr
                                privCache = { url = baseUrl, snap = arr, fetchedAt = now }
                                hasPrivate = true
                            end
                        end
                    end
                end
                if privEntries then
                    for _, e in ipairs(privEntries) do
                        if typeof(e) == "table" then
                            local ref = tostring(e.jobId or e.serverRef or e.serverId or "")
                            local pid = tonumber(e.placeId) or 0
                            local nm = string.lower(tostring(e.eventName or ""))
                            local dk = tostring(pid) .. "|" .. ref .. "|" .. nm
                            if ref ~= "" and not seen[dk] then
                                seen[dk] = true
                                e.serverRef = e.serverRef or ref
                                e.jobId = e.jobId or (string.find(ref, "-", 1, true) and ref or nil)
                                e.alive = (e.alive ~= false)
                                e._sourceKind = "private"
                                table.insert(merged, e)
                            end
                        end
                    end
                end
            end

            if typeof(genv.WK_FetchLiveBossApiSnapshot) == "function" then
                local okWk, wkSnap = pcall(genv.WK_FetchLiveBossApiSnapshot)
                if okWk and typeof(wkSnap) == "table" and typeof(wkSnap.entries) == "table" then
                    hasWukong = true
                    for _, e in ipairs(wkSnap.entries) do
                        if typeof(e) == "table" then
                            local ref = tostring(e.serverRef or e.jobId or "")
                            local pid = tonumber(e.placeId) or 0
                            local nm = string.lower(tostring(e.eventName or ""))
                            local dk = tostring(pid) .. "|" .. ref .. "|" .. nm
                            if not seen[dk] then
                                seen[dk] = true
                                e._sourceKind = "wukong"
                                table.insert(merged, e)
                            end
                        end
                    end
                end
            end

            return (hasPrivate or hasWukong), {
                entries = merged,
                hasPrivate = hasPrivate,
                hasWukong = hasWukong,
            }
        end

        function net.joinApiEntry(chosen: any, fallbackPlaceId: number?): (boolean, string)
            if typeof(chosen) ~= "table" then return false, "invalid" end
            local pId = tonumber(chosen.placeId) or fallbackPlaceId or game.PlaceId
            local srvId = chosen.jobId or chosen.serverId or chosen.id
            if (typeof(srvId) ~= "string" or srvId == "") and typeof(chosen.serverRef) == "string" and string.find(chosen.serverRef, "-", 1, true) ~= nil then
                srvId = chosen.serverRef
            end
            if typeof(srvId) == "string" and string.find(srvId, "-", 1, true) ~= nil then
                local okTp = pcall(function() teleportService:TeleportToPlaceInstance(pId, srvId, players.LocalPlayer) end)
                return okTp, "jobId"
            elseif typeof(genv.WK_JoinLiveBossApiEntry) == "function" then
                local okWk = pcall(genv.WK_JoinLiveBossApiEntry, chosen)
                return okWk, "wukong"
            end
            return false, "no_route"
        end

        local function sendDiscordBossFallback(bossName: string, curH: number, maxH: number, pct: number, pCount: number, pMax: number, execName: string)
            local dcUrl = net.getBossDiscordWebhook()
            if dcUrl == "" or game.JobId == "" then return end
            local jobId = game.JobId
            local seaLabel = (game.PlaceId == SEA3_PLACE and "Sea 3") or (game.PlaceId == SEA2_PLACE and "Sea 2") or "Sea 1"
            local quickJoin = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)', game.PlaceId, jobId)
            local hpText = (maxH > 0) and string.format("%d/%d (%d%%)", curH, maxH, pct) or string.format("%d%%", pct)
            local dcDesc = table.concat({
                "```",
                string.format("🎮 %s: Alive | ❤️ %s", bossName, hpText),
                "```",
                "**🌐 SERVER**",
                string.format("**Game:** King Legacy (%s)", seaLabel),
                string.format("**Players:** %d/%d", pCount, pMax),
                "",
                "**📌 JobId PC**",
                "```",
                jobId,
                "```",
                "**📌 JobId Join Script**",
                "```lua",
                quickJoin,
                "```",
                "**💻 Executor**",
                execName,
            }, "\n")
            net.httpRequest("POST", dcUrl, {
                content = jobId,
                username = "YokaHub Boss Notifier",
                embeds = {
                    {
                        author = { name = "YokaHub Boss Notifier" },
                        title = "🔥 BOSS DETECTED",
                        description = dcDesc,
                        color = 16724787,
                        footer = { text = "YokaHub | Auto Detection System" },
                    },
                },
            })
        end

        function net.reportAliveBoss(bossName: string, bossSource: string, hpCur: number?, hpMax: number?)
            if game.JobId == "" then return end
            local now = os.clock()
            local jobId = game.JobId
            local cdKey = jobId .. "|" .. string.lower(bossName)
            local pCount = #players:GetPlayers()
            local pMax = players.MaxPlayers or 12
            local curH = math.floor(tonumber(hpCur) or 0)
            local maxH = math.floor(tonumber(hpMax) or 0)
            local pct = (maxH > 0) and math.clamp(math.floor((curH / maxH) * 100 + 0.5), 1, 100) or 100
            local execName = "YokaHub Client"
            pcall(function()
                if typeof(identifyexecutor) == "function" then
                    local ex = identifyexecutor()
                    if typeof(ex) == "string" and ex ~= "" then execName = ex end
                end
            end)

            local reportTargets: { string } = {}
            local baseUrl = net.normalizeBaseUrl(hubState.privateBossApiUrl)
            local sqlUrl = net.getReachableSqlMvcUrl()
            if hubState.privateBossApiReport ~= false and baseUrl ~= "" then table.insert(reportTargets, baseUrl) end
            if sqlUrl ~= "" and sqlUrl ~= baseUrl then table.insert(reportTargets, sqlUrl) end

            local wantClientDc = (hubState.bossDiscordNotify ~= false) and (net.getBossDiscordWebhook() ~= "") and ((now - (discordCooldowns[cdKey] or 0)) >= 60.0)
            if #reportTargets > 0 and (now - (reportCooldowns[cdKey] or 0)) >= 15.0 then
                reportCooldowns[cdKey] = now
                if wantClientDc then discordCooldowns[cdKey] = now end
                local payload = {
                    placeId = game.PlaceId,
                    jobId = jobId,
                    serverRef = jobId,
                    eventName = bossName,
                    source = bossSource,
                    alive = true,
                    executor = execName,
                    reportedBy = players.LocalPlayer and players.LocalPlayer.Name or "",
                    health = { current = curH, max = maxH, percent = pct },
                    players = { current = pCount, max = pMax },
                    reportedAt = os.time(),
                }
                task.spawn(function()
                    local handledByMvc = false
                    for _, targetUrl in ipairs(reportTargets) do
                        local okR, _, rawR = net.httpRequest("POST", targetUrl .. "/api/report", payload, getPrivateHeaders())
                        if okR and typeof(rawR) == "string" and string.find(rawR, '"discordHandledByServer":true', 1, true) ~= nil then
                            handledByMvc = true
                        end
                    end
                    if not handledByMvc and wantClientDc then
                        sendDiscordBossFallback(bossName, curH, maxH, pct, pCount, pMax, execName)
                    end
                end)
            elseif wantClientDc then
                discordCooldowns[cdKey] = now
                task.spawn(function()
                    sendDiscordBossFallback(bossName, curH, maxH, pct, pCount, pMax, execName)
                end)
            end
        end

        function net.syncDropToSql(dropTbl: { [string]: any })
            local sqlUrl = net.getReachableSqlMvcUrl()
            if sqlUrl == "" then return end
            task.spawn(function()
                net.httpRequest("POST", sqlUrl .. "/api/drops", dropTbl, getPrivateHeaders())
            end)
        end

        function net.syncSessionToSql(modeStr: string)
            local now = os.clock()
            if (now - lastSessionSyncAt) < 8.0 then return end
            local sqlUrl = net.getReachableSqlMvcUrl()
            if sqlUrl == "" then return end
            lastSessionSyncAt = now
            local cur = getPlayerStats()
            local payload = {
                playerName = players.LocalPlayer and players.LocalPlayer.Name or "Unknown",
                jobId = game.JobId,
                placeId = game.PlaceId,
                mode = modeStr or currentMode or "off",
                hopsCount = session.hops or 0,
                startBeli = session.startBeli or cur.beli,
                currentBeli = cur.beli,
                startGems = session.startGems or cur.gems,
                currentGems = cur.gems,
            }
            task.spawn(function()
                net.httpRequest("POST", sqlUrl .. "/api/session", payload, getPrivateHeaders())
            end)
        end

        function net.syncConfigToSql(cfgTbl: any)
            local now = os.clock()
            if (now - lastConfigSyncAt) < 1.5 then return end
            local sqlUrl = net.getReachableSqlMvcUrl()
            if sqlUrl == "" then return end
            lastConfigSyncAt = now
            task.spawn(function()
                net.httpRequest("POST", sqlUrl .. "/api/config", { configKey = "default", config = cfgTbl }, getPrivateHeaders())
            end)
        end

        genv._YokaSyncConfigToSql = function(stTbl: any)
            net.syncConfigToSql(stTbl)
        end

        return net
    end)()

    local function getOpenServerForPlace(placeId: number): string?
        local list = YokaNet.findPublicServers(placeId, nil, 2, 2, "")
        if #list > 0 then
            local poolMax = math.min(#list, 8)
            return tostring(list[math.random(1, poolMax)].jobId)
        end
        return nil
    end

    teleportToSea = function(targetPlace: number, preferKey: string?): boolean
        if isSwitchingSea and (os.clock() - lastSeaSwitchClock) < 12.0 then
            return false
        end
        isSwitchingSea = true
        lastSeaSwitchClock = os.clock()
        lastAttemptedPlace = targetPlace
        armAutoReexec(false)

        task.spawn(function()
            local lp = players.LocalPlayer

            -- TH1: NẾU CÙNG PLACEID (ĐỔI SERVER TRONG CÙNG SEA)
            if targetPlace == game.PlaceId then
                -- Nếu có yêu cầu Boss cụ thể (preferKey), thử dùng Private Boss API / Wukong API nếu có
                if preferKey and preferKey ~= "" then
                    local ok, snap = YokaNet.fetchLiveBossSnapshot()
                    if ok and typeof(snap) == "table" and typeof(snap.entries) == "table" then
                        local matched = nil
                        local pkLow = string.lower(preferKey)
                        for _, entry in ipairs(snap.entries) do
                            if entry.alive == true and tonumber(entry.placeId) == targetPlace and entry.players and (entry.players.current or 0) < (entry.players.max or 12) then
                                local en = string.lower(tostring(entry.eventName or ""))
                                local hit = false
                                if pkLow == "dragon" or string.find(pkLow, "dragon", 1, true) ~= nil or string.find(pkLow, "drakenfyr", 1, true) ~= nil then
                                    hit = (string.find(en, "drakenfyr", 1, true) ~= nil or string.find(en, "inferno king", 1, true) ~= nil or string.find(en, "sea dragon", 1, true) ~= nil or string.find(en, "dragon", 1, true) ~= nil)
                                        and string.find(en, "abyssal", 1, true) == nil and string.find(en, "tyrant", 1, true) == nil and string.find(en, "depth", 1, true) == nil
                                elseif pkLow == "abyssal" or string.find(pkLow, "abyssal", 1, true) ~= nil then
                                    hit = (string.find(en, "abyssal", 1, true) ~= nil or string.find(en, "tyrant", 1, true) ~= nil)
                                        and string.find(en, "drakenfyr", 1, true) == nil and string.find(en, "dragon", 1, true) == nil
                                elseif pkLow == "depth" or string.find(pkLow, "depth", 1, true) ~= nil then
                                    hit = string.find(en, "depth", 1, true) ~= nil
                                        and string.find(en, "abyssal", 1, true) == nil and string.find(en, "drakenfyr", 1, true) == nil and string.find(en, "dragon", 1, true) == nil
                                else
                                    hit = string.find(en, pkLow, 1, true) ~= nil
                                end
                                if hit then
                                    matched = entry
                                    break
                                end
                            end
                        end
                        if matched then
                            print("[YokaHub][Auto-Sea-Switch] Same-place hop to Boss server:", matched.eventName)
                            local okJoin = YokaNet.joinApiEntry(matched, targetPlace)
                            if okJoin then
                                task.wait(12.0)
                                isSwitchingSea = false
                                return
                            end
                        end
                    end
                end

                -- Nếu không có Boss API hoặc API trống, đổi sang phòng công khai thông minh của YokaHub
                local jobId = getOpenServerForPlace(targetPlace)
                if jobId and jobId ~= "" then
                    print("[YokaHub][Auto-Sea-Switch] Same-place hop via Public Server JobId:", jobId)
                    local okTp = pcall(function()
                        teleportService:TeleportToPlaceInstance(targetPlace, jobId, lp)
                    end)
                    if okTp then
                        task.wait(12.0)
                        isSwitchingSea = false
                        return
                    end
                end
                pcall(function() teleportService:Teleport(targetPlace, lp) end)
                task.wait(12.0)
                isSwitchingSea = false
                return
            end

            -- TH2: NẾU KHÁC PLACEID (CHUYỂN SANG SEA KHÁC)
            -- 1. Ưu tiên hàng đầu: Kích hoạt nút chuyển Sea chính thức trong ServerBrowserFrame của King Legacy
            -- Cơ chế này gọi trực tiếp backend King Legacy (EtcFunction/TeleportWithLoading) nên 100% không bị Error 772, 773 hay Server is Full!
            local btnName = (targetPlace == SEA3_PLACE and "Sea3") or (targetPlace == SEA2_PLACE and "Sea2") or (targetPlace == SEA1_PLACE and "Sea1") or nil
            local firedOfficial = false
            if btnName then
                pcall(function()
                    local sbf = lp.PlayerGui:FindFirstChild("MainGui")
                    if sbf then sbf = sbf:FindFirstChild("StarterFrame") end
                    if sbf then sbf = sbf:FindFirstChild("ServerBrowserFrame") end
                    local sf = sbf and sbf:FindFirstChild("SeaFrame")
                    local btn = sf and sf:FindFirstChild(btnName)
                    if btn and btn:IsA("TextButton") then
                        print("[YokaHub][Auto-Sea-Switch] Firing King Legacy official sea button:", btnName)
                        if typeof(firesignal) == "function" then
                            firesignal(btn.MouseButton1Click)
                            firedOfficial = true
                        elseif typeof(getconnections) == "function" then
                            local conns = getconnections(btn.MouseButton1Click)
                            if #conns > 0 then
                                for _, c in ipairs(conns) do
                                    if typeof(c.Fire) == "function" then c:Fire() end
                                end
                                firedOfficial = true
                            end
                        end
                    end
                end)
            end

            if not firedOfficial then
                print("[YokaHub][Auto-Sea-Switch] Teleporting cross-sea via TeleportService to place:", targetPlace)
                local okTp = pcall(function()
                    teleportService:Teleport(targetPlace, lp)
                end)
                if not okTp then
                    pcall(function()
                        local jobId = getOpenServerForPlace(targetPlace)
                        if jobId and jobId ~= "" then
                            teleportService:TeleportToPlaceInstance(targetPlace, jobId, lp)
                        end
                    end)
                end
            end
            task.wait(15.0)
            isSwitchingSea = false
        end)
        return true
    end

    local function ensureCorrectSea(targetPlace: number, bossName: string, reason: string?, preferKey: string?, forceHop: boolean?): boolean
        if game.PlaceId == targetPlace and not forceHop then
            return true
        end
        local seaName = (targetPlace == SEA3_PLACE and "Sea 3") or (targetPlace == SEA2_PLACE and "Sea 2") or (targetPlace == SEA1_PLACE and "Sea 1") or "Sea"
        local notifyMsg = (game.PlaceId == targetPlace) and ("Đang đổi server " .. seaName .. " để săn " .. bossName .. "!") or ("Đang tự động chuyển sang " .. seaName .. " để săn " .. bossName .. "!")
        if reason and reason ~= "" then
            notifyMsg = "[" .. reason .. "] " .. notifyMsg
        end
        print("[YokaHub][Auto-Sea-Switch]", notifyMsg)
        safeNotify("Tự chuyển Sea", notifyMsg, "flight_takeoff")

        saveState(hubState)
        if teleportToSea then
            teleportToSea(targetPlace, preferKey)
        end
        return false
    end

    -- ========================================================
    -- KHOI TAO CUA SO CHINH YOKAUI v3 & NUT NOI DOCK PRO
    -- ========================================================
    local userOpenedHub = false
    local hubDesiredOpen = false
    local isFullscreen = false
    local DOCK_TOP_ORDER = 2147483646
    local HUB_ORDER = 1000010
    local doExitToGateway: () -> ()
    local setHubVisible: (boolean) -> ()
    local onHubOpenedHooks: { () -> () } = {}

    local customAssetFn = getcustomasset or genv.getcustomasset or getsynasset or genv.getsynasset
    local dockImageId = "rbxassetid://6031097225"
    if typeof(customAssetFn) == "function" and typeof(isf) == "function" then
        local okEx, ex = pcall(isf, "YokaHub_Icon.png")
        if okEx and ex then
            local okId, assetUrl = pcall(customAssetFn, "YokaHub_Icon.png")
            if okId and typeof(assetUrl) == "string" and assetUrl ~= "" then
                dockImageId = assetUrl
            end
        end
    end

    local licenseTierLabel = "VIP PRO · " .. curSeaLabel
    pcall(function()
        local lic = readJson("YokaHub_License.json")
        if typeof(lic) == "table" and typeof(lic.tier) == "string" and lic.tier ~= "" then
            licenseTierLabel = tostring(lic.tier) .. " · " .. curSeaLabel
        end
    end)

    Window = YokaUI.new({
        Name = "YokaHub",
        Subtitle = "King Legacy · " .. curSeaLabel,
        UserName = player.DisplayName or player.Name,
        UserSub = licenseTierLabel,
        Hint = "Mẹo: Gõ từ khóa vào ô tìm kiếm phía trên để lọc nhanh bất kỳ tính năng nào (hỗ trợ không dấu)  ·  Phím tắt: RightCtrl / F8 / F9",
        Width = hubState.winW or 760,
        Height = hubState.winH or 480,
        DisplayOrder = HUB_ORDER,
        Parent = guiParent,
        OnClose = function()
            if setHubVisible then setHubVisible(false) end
        end,
        OnExit = function()
            if doExitToGateway then doExitToGateway() end
        end,
        OnResize = function(newW: number, newH: number)
            hubState.winW = newW
            hubState.winH = newH
            saveState(hubState)
        end,
    })
    if dockImageId ~= "rbxassetid://6031097225" then
        pcall(function() Window:SetLogo(dockImageId) end)
    end

    Luna = Window
    genv._YokaHubLuna = Window

    local function getLunaGui(): ScreenGui?
        if Window and Window.Gui and Window.Gui.Parent then
            return Window.Gui
        end
        local g = guiParent:FindFirstChild("Luna UI") or coreGui:FindFirstChild("Luna UI")
        if g and g:IsA("ScreenGui") then return g end
        return nil
    end

    local function hideHubImmediate()
        hubDesiredOpen = false
        if Window and Window.Root then
            Window.Root.Visible = false
        end
    end
    hideHubImmediate()

    -- ========================================================
    -- NÚT AVATAR MỞ/TẮT YOKAHUB (60x60 BO TRÒN · LUÔN NẰM TRÊN CÙNG MỌI GIAO DIỆN)
    -- ========================================================
    local dockGui = Instance.new("ScreenGui")
    dockGui.Name = "YokaHubDockGui"
    dockGui.ResetOnSpawn = false
    dockGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    dockGui.DisplayOrder = DOCK_TOP_ORDER
    dockGui.Parent = guiParent
    trackConn(dockGui:GetPropertyChangedSignal("DisplayOrder"):Connect(function()
        if dockGui.DisplayOrder ~= DOCK_TOP_ORDER then
            dockGui.DisplayOrder = DOCK_TOP_ORDER
        end
    end))

    local dockBtn = Instance.new("ImageButton")
    dockBtn.Name = "DockButton"
    dockBtn.Size = UDim2.fromOffset(60, 60)
    local function clampDockPos(x: number, y: number): (number, number)
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        return math.clamp(math.floor(x), 8, math.max(8, math.floor(vp.X - 68))),
            math.clamp(math.floor(y), 8, math.max(8, math.floor(vp.Y - 92)))
    end
    if hubState.dockX and hubState.dockY then
        local cx, cy = clampDockPos(hubState.dockX, hubState.dockY)
        dockBtn.Position = UDim2.fromOffset(cx, cy)
    else
        dockBtn.Position = UDim2.new(1, -76, 0, 148)
    end
    dockBtn.BackgroundColor3 = THEME.dockBg
    dockBtn.BackgroundTransparency = 0
    dockBtn.BorderSizePixel = 0
    dockBtn.AutoButtonColor = false
    dockBtn.Image = dockImageId
    dockBtn.ScaleType = Enum.ScaleType.Crop
    dockBtn.Active = true
    dockBtn.Visible = true
    dockBtn.ZIndex = 100
    dockBtn.Parent = dockGui

    local dockExitBtn = Instance.new("TextButton")
    dockExitBtn.Name = "DockExitToGatewayBtn"
    dockExitBtn.Size = UDim2.fromOffset(60, 20)
    dockExitBtn.Position = UDim2.new(dockBtn.Position.X.Scale, dockBtn.Position.X.Offset, dockBtn.Position.Y.Scale, dockBtn.Position.Y.Offset + 64)
    dockExitBtn.BackgroundColor3 = Color3.fromRGB(185, 35, 50)
    dockExitBtn.BorderSizePixel = 0
    dockExitBtn.Font = Enum.Font.GothamBold
    dockExitBtn.TextSize = 9
    dockExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dockExitBtn.Text = "🚪 THOÁT KEY"
    dockExitBtn.ZIndex = 101
    dockExitBtn.Parent = dockGui

    local debCorner = Instance.new("UICorner")
    debCorner.CornerRadius = UDim.new(0, 6)
    debCorner.Parent = dockExitBtn

    local function updateDockExitPos()
        dockExitBtn.Position = UDim2.new(dockBtn.Position.X.Scale, dockBtn.Position.X.Offset, dockBtn.Position.Y.Scale, dockBtn.Position.Y.Offset + 64)
    end
    trackConn(dockBtn:GetPropertyChangedSignal("Position"):Connect(updateDockExitPos))

    dockExitBtn.MouseButton1Click:Connect(function()
        if doExitToGateway then doExitToGateway() end
    end)

    local initCam = workspace.CurrentCamera
    if initCam then
        trackConn(initCam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            local rawX = hubState.dockX or dockBtn.AbsolutePosition.X
            local rawY = hubState.dockY or dockBtn.AbsolutePosition.Y
            local cx, cy = clampDockPos(rawX, rawY)
            if hubState.dockX and hubState.dockY then
                dockBtn.Position = UDim2.fromOffset(cx, cy)
            elseif dockBtn.AbsolutePosition.Y > (initCam.ViewportSize.Y - 92) or dockBtn.AbsolutePosition.X > (initCam.ViewportSize.X - 68) then
                dockBtn.Position = UDim2.fromOffset(cx, cy)
            end
        end))
    end

    local dockCorner = Instance.new("UICorner")
    dockCorner.CornerRadius = UDim.new(0, 14)
    dockCorner.Parent = dockBtn

    local dockStroke = Instance.new("UIStroke")
    dockStroke.Thickness = 2
    dockStroke.Color = THEME.c1
    dockStroke.Transparency = 0.08
    dockStroke.Parent = dockBtn

    local dockScale = Instance.new("UIScale")
    dockScale.Name = "HoverScale"
    dockScale.Scale = 1
    dockScale.Parent = dockBtn

    local dockDot = Instance.new("Frame")
    dockDot.Name = "StatusDot"
    dockDot.Size = UDim2.fromOffset(12, 12)
    dockDot.Position = UDim2.new(1, -13, 1, -13)
    dockDot.BackgroundColor3 = Color3.fromRGB(140, 145, 160)
    dockDot.BorderSizePixel = 0
    dockDot.ZIndex = 105
    dockDot.Parent = dockBtn

    local dockDotCorner = Instance.new("UICorner")
    dockDotCorner.CornerRadius = UDim.new(1, 0)
    dockDotCorner.Parent = dockDot

    local dockDotStroke = Instance.new("UIStroke")
    dockDotStroke.Thickness = 1.8
    dockDotStroke.Color = Color3.fromRGB(14, 15, 20)
    dockDotStroke.Parent = dockDot

    local function updateDockDot()
        if currentMode == "solo" then
            local col = Color3.fromRGB(178, 102, 255)
            dockDot.BackgroundColor3 = col
            dockStroke.Color = col
            if Window then Window:SetStatus("Auto Hop · Solo", col) end
        elseif currentMode == "sea3" then
            dockDot.BackgroundColor3 = THEME.c1
            dockStroke.Color = THEME.c1
            if Window then Window:SetStatus("Auto Hop · Sea 3", THEME.c1) end
        elseif currentMode == "sea2" then
            local col = Color3.fromRGB(82, 178, 240)
            dockDot.BackgroundColor3 = col
            dockStroke.Color = col
            if Window then Window:SetStatus("Auto Hop · Sea 2", col) end
        else
            dockDot.BackgroundColor3 = Color3.fromRGB(145, 150, 165)
            dockStroke.Color = THEME.c2
            if Window then Window:SetStatus("Đứng tại phòng", YokaUI.Palette.mute) end
        end
    end
    updateDockDot()

    local tweenSoft = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tweenHover = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function setCorner(obj: Instance, radius: number)
        local c = obj:FindFirstChildOfClass("UICorner")
        if not c then
            c = Instance.new("UICorner")
            c.Parent = obj
        end
        (c :: UICorner).CornerRadius = UDim.new(0, radius)
    end

    local function applyVisualTheme()
        updateDockDot()
    end

    local function attachCornerResizer()
        -- Tích hợp sẵn trong YokaUI v3
    end

    local function isHubOpen(): boolean
        return Window ~= nil and Window:IsVisible()
    end

    setHubVisible = function(visible: boolean)
        if not Window then return end
        hubDesiredOpen = visible
        if visible then
            userOpenedHub = true
            dockGui.DisplayOrder = DOCK_TOP_ORDER
            dockBtn.Visible = true
            dockStroke.Thickness = 2.4
            for _, fn in ipairs(onHubOpenedHooks) do pcall(fn) end
            Window:SetVisible(true)
        else
            dockBtn.Visible = true
            dockStroke.Thickness = 2.0
            Window:SetVisible(false)
        end
    end

    trackConn(dockBtn.MouseEnter:Connect(function()
        tweenService:Create(dockScale, tweenHover, { Scale = 1.07 }):Play()
        tweenService:Create(dockStroke, tweenHover, { Transparency = 0 }):Play()
    end))
    trackConn(dockBtn.MouseLeave:Connect(function()
        tweenService:Create(dockScale, tweenHover, { Scale = 1 }):Play()
        tweenService:Create(dockStroke, tweenHover, { Transparency = 0.08 }):Play()
    end))

    local dockDragging, dockDragged = false, false
    local dockDragStart = Vector2.new(0, 0)
    local dockStartPos = dockBtn.Position

    trackConn(dockBtn.InputBegan:Connect(function(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dockDragging = true; dockDragged = false
            dockDragStart = Vector2.new(input.Position.X, input.Position.Y)
            dockStartPos = dockBtn.Position
        end
    end))
    trackConn(userInputService.InputChanged:Connect(function(input: InputObject)
        if not dockDragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dockDragStart
        if delta.Magnitude > 5 then dockDragged = true end
        if dockDragged then
            dockBtn.Position = UDim2.new(dockStartPos.X.Scale, dockStartPos.X.Offset + delta.X, dockStartPos.Y.Scale, dockStartPos.Y.Offset + delta.Y)
        end
    end))
    trackConn(userInputService.InputEnded:Connect(function(input: InputObject)
        if dockDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dockDragging = false
            if dockDragged then
                local cx, cy = clampDockPos(dockBtn.AbsolutePosition.X, dockBtn.AbsolutePosition.Y)
                dockBtn.Position = UDim2.fromOffset(cx, cy)
                hubState.dockX = cx
                hubState.dockY = cy
                saveState(hubState)
            end
        end
    end))
    trackConn(dockBtn.MouseButton1Click:Connect(function()
        if dockDragged then return end
        dockScale.Scale = 0.90
        tweenService:Create(dockScale, tweenSoft, { Scale = 1 }):Play()
        setHubVisible(not hubDesiredOpen)
    end))

    -- Phim tat RightControl de dong/mo nhanh cua so YokaHub tren PC
    trackConn(userInputService.InputBegan:Connect(function(input: InputObject, gp: boolean)
        if gp or userInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            setHubVisible(not hubDesiredOpen)
        end
    end))

    doExitToGateway = function()
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "YokaHub",
                Text = "Đang quay lại Cổng Get Key...",
                Duration = 2,
            })
        end)
        task.delay(0.2, function()
            pcall(function()
                local delFn = delfile or (syn and syn.delfile)
                local isfFn = isfile or (syn and syn.isfile)
                if typeof(delFn) == "function" and typeof(isfFn) == "function" then
                    if isfFn("YokaHub_License.json") then
                        delFn("YokaHub_License.json")
                    end
                end
            end)
            genv._YokaHub_Authenticated = false
            genv._YokaHub_Running = nil

            hubState.mode = "off"
            saveState(hubState)
            genv._DisableWatchdog = true
            genv._YokaHubToken = -1
            genv._KingAutoHopMode = "off"
            genv._AutoSeaEventApiHop = false
            genv._AutoSea2PriorityApiHop = false
            genv._AutoDepthKingOnlyApiHop = false
            pcall(function()
                genv.AutoHop = false
                genv.HopDepthKing = false
                genv.HopDepthKingApi = false
                genv.autoskhdhop = false
                genv.hopSerpent = false
                genv.hopSerpentApi = false
            end)
            dmgEnabled = false
            if clearDmgWatchers then clearDmgWatchers() end
            for _, c in ipairs(activeConns) do pcall(function() c:Disconnect() end) end
            purgeLunaBlur()
            pcall(function() dockGui:Destroy() end)
            pcall(function() Window:Destroy() end)
            genv._YokaHubLuna = nil

            task.spawn(function()
                task.wait(0.3)
                if typeof(genv._YokaHub_LaunchGateway) == "function" then
                    genv._YokaHub_LaunchGateway()
                    return
                end
                local isfFn = isfile or (syn and syn.isfile)
                local rfFn = readfile or (syn and syn.readfile)
                if typeof(isfFn) == "function" and typeof(rfFn) == "function" and isfFn("YokaHub_KeySystem.luau") then
                    local fn = loadstring(rfFn("YokaHub_KeySystem.luau"))
                    if fn then fn() return end
                end
                pcall(function()
                    loadstring(game:HttpGet("https://gist.githubusercontent.com/quystptv00383-commits/7dde495f53b84afb7cf64c06c15dfe2d/raw/YokaHub_KeySystem.luau?t=" .. tostring(os.time())))()
                end)
            end)
        end)
    end

    local function applyWindowSize(w: number, h: number, smooth: boolean, saveIt: boolean)
        if not Window then return end
        isFullscreen = false
        Window:SetSize(w, h, smooth, true)
        hubState.winW = Window.W
        hubState.winH = Window.H
        if saveIt then saveState(hubState) end
    end

    local function toggleFullscreen()
        if not Window then return end
        Window:ToggleFullscreen()
        isFullscreen = Window.fullscreen
    end

