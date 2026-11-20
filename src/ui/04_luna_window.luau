    local hubState = loadState()
    local session = loadSession()
    local currentMode: string = hubState.mode

    -- Tu dong dong bo cai dat Wukong Engine khi khoi dong
    pcall(function()
        if hubState.autoLevel then genv.Famlevel = true; genv.start = true end
        if hubState.autoSkills then genv.opeskill = true; genv.autoskillsea = true end
        if hubState.autoHaki then genv.haki = true; genv.hakivutrangv2 = true; genv.hakiquansatv2 = true end
        if hubState.safeDistance then genv.nequaikill = true; genv.tamxanekillquai = 250; genv.docaokillquai = 18 end
        if hubState.farmSea3Mat then genv.farmMaterialsea3 = true end
        if hubState.farmSea2Mat then genv.farmMaterialsea2 = true end
        if hubState.farmSea1Mat then genv.farmMaterialsea1 = true end
        if hubState.autoDungeon then genv.autodungeon = true end
        if hubState.dungeonMode then genv.dungeonmode = hubState.dungeonMode end
        if hubState.bringFruits then genv.BringDroppedFruit = true end
        if hubState.storeFruits then genv.autocat = true end
        if hubState.snipeShop then genv.autobuy = true end
        if hubState.fruitESP then genv.FruitESPEnabled = true end
        if hubState.blackScreen then
            if typeof(genv.WK_ApplyBlackScreen) == "function" then genv.WK_ApplyBlackScreen(true) else genv.BlackScreen = true end
        end
        if hubState.fastMode then genv.fastMode = true; genv.lowTextureMap = true; genv.removeEffects = true end
        if hubState.walkOnWater then genv.Walkonwater = true end
        if hubState.infiniteJump then genv.InfiniteJumpEnabled = true end
        if hubState.autoAlly then genv.AutoSendAlly = true; genv.AutoAcceptAlly = true end
        if hubState.autoDailyQuest then genv.autoalldailyquest = true; genv.nhiemvuhangngay = true end
        if hubState.autoRaceRoll then genv.AutoGetAutoRollRace = true; genv.toc = true end
        if hubState.webhookUrl and #hubState.webhookUrl > 10 then genv.Webhook_URL2 = hubState.webhookUrl end
        if hubState.whFruit then genv.whshowfruit = true end
        if hubState.whDrop then genv.whitemdrop = true end
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
                genv.shopSniperFruits = {"DragonFruit", "PhoenixFruit", "GateFruit", "DoughFruit", "ErebusFruit", "SpiritFruit", "MagnetFruit", "ToyFruit", "MelodyFruit", "DemonFruit"}
            else
                local fName = hubState.snipeFruit:match("^([%w]+)") or hubState.snipeFruit
                genv.shopSniperFruits = { fName }
            end
        end
        if hubState.snipeDelay then genv.shopSniperDelay = hubState.snipeDelay end

        -- Sync Auto Fishing
        if hubState.autoFish then genv.AutoFish = true end
        if hubState.fishWeapon then genv.kiemmacauca = hubState.fishWeapon end
    end)
    local currentSoloTarget: string = hubState.soloTarget
    local myToken = (tonumber(genv._YokaHubToken) or 0) + 1
    genv._YokaHubToken = myToken
    genv._KingAutoHopMode = currentMode
    genv._KingSoloTarget = currentSoloTarget
    genv._AutoSeaEventApiHop = (currentMode == "sea3")
    genv._AutoSea2PriorityApiHop = (currentMode == "sea2")
    genv._AutoDepthKingOnlyApiHop = (currentMode == "solo" and getSoloKey(currentSoloTarget) == "depth_king")

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
            local isServerFail = string.find(reason, "773") ~= nil or string.find(reason, "772") ~= nil or string.find(reason, "774") ~= nil or string.find(reason, "restricted") ~= nil or string.find(reason, "full") ~= nil
            if isDisconnect or isServerFail then
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
                        print("[YokaHub][Auto-Rescue] Fallback teleport to place:", targetPlace)
                        safeNotify("Tự động cứu hộ", "Đang tự kết nối lại phòng mới...", "refresh")
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

    -- 5. Tai Luna Interface Suite (vo hieu hoa BlurModule, sua loi Icon Notification & chuan hoa chieu cao Dropdown)
    genv.ConfirmLuna = true
    local okLuna, Luna: any = pcall(function()
        local rawSrc = game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/master/source.lua")
        local patchedSrc = string.gsub(rawSrc, "local function BlurModule%(Frame%)", "local function BlurModule(Frame) if true then return end", 1)
        patchedSrc = string.gsub(patchedSrc, "newNotification%.Icon%.Visible = false", "if newNotification and newNotification:FindFirstChild(\"Icon\") then newNotification.Icon.Visible = false end", 1)
        patchedSrc = string.gsub(patchedSrc, "closedsize = 38", "closedsize = 44", 1)
        local fn = loadstring(patchedSrc)
        return fn and fn() or nil
    end)
    if not okLuna or typeof(Luna) ~= "table" then
        warn("[YokaHub] Khong the tai Luna UI:", tostring(Luna))
        return
    end
    genv._YokaHubLuna = Luna

    local function safeNotify(title: string, content: string, icon: string?)
        task.spawn(function()
            pcall(function()
                Luna:Notification({
                    Title = title,
                    Content = content,
                    Icon = icon or "public",
                    ImageSource = "Material",
                    Duration = 3,
                })
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
        if not hubState.autoReexec then return false end
        local qFn = getRealQueueOnTeleport()
        if not qFn then
            if notifyUser then
                safeNotify("YokaHub", "Client hiện tại chưa hỗ trợ queue_on_teleport.", "info")
            end
            return false
        end
        if genv._YokaReexecQueued then
            if notifyUser then
                safeNotify("YokaHub", "Đã bật tự chạy lại khi chuyển server (Delta / Mobile).", "check_circle")
            end
            return true
        end
        local loaderUrl = getYokaLoaderUrl()
        local escapedUrl = string.gsub(loaderUrl, "\\", "\\\\")
        escapedUrl = string.gsub(escapedUrl, '"', '\\"')
        local payload = table.concat({
            'if game.GameId ~= 1451439645 then return end',
            'task.spawn(function()',
            '    if not game:IsLoaded() then game.Loaded:Wait() end',
            '    task.wait(1.0)',
            '    local g = getgenv()',
            '    if g._WukongMasterLoaded then return end',
            '    local rf, isf = g.readfile or readfile, g.isfile or isfile',
            '    if typeof(isf) == "function" and typeof(rf) == "function" and isf("YokaHub_State.json") then',
            '        local ok, raw = pcall(rf, "YokaHub_State.json")',
            '        if ok and typeof(raw) == "string" and string.find(raw, \'"autoReexec":false\', 1, true) then return end',
            '    end',
            '    local url = "' .. escapedUrl .. '"',
            '    if #url < 10 and typeof(isf) == "function" and typeof(rf) == "function" and isf("YokaHub_LoaderUrl.txt") then',
            '        local ok, u = pcall(rf, "YokaHub_LoaderUrl.txt")',
            '        if ok and typeof(u) == "string" then url = string.gsub(u, "%s+", "") end',
            '    end',
            '    local src = nil',
            '    if #url > 10 then',
            '        g._YokaHubLoaderUrl = url',
            '        local ok, res = pcall(function() return game:HttpGet(url) end)',
            '        if ok and typeof(res) == "string" and #res > 1000 then src = res end',
            '    end',
            '    if not src and typeof(isf) == "function" and typeof(rf) == "function" and isf("YokaHub_Full.luau") then',
            '        local ok, res = pcall(rf, "YokaHub_Full.luau")',
            '        if ok and typeof(res) == "string" and #res > 1000 then src = res end',
            '    end',
            '    if src then local fn = loadstring(src); if fn then fn() end end',
            'end)',
        }, "\n")
        local okQ = pcall(qFn, payload)
        if okQ then
            genv._YokaReexecQueued = true
            if notifyUser then
                safeNotify("YokaHub", "Đã bật tự động chạy lại khi vào SV mới (Delta / Mobile).", "check_circle")
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

    local function getOpenServerForPlace(placeId: number): string?
        local req = (genv.syn and genv.syn.request) or (genv.http and genv.http.request) or genv.request or genv.http_request
        local apiUrl = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/0?sortOrder=1&excludeFullGames=true&limit=100"
        local rawJson = nil
        if req then
            local okReq, res = pcall(req, { Url = apiUrl, Method = "GET" })
            if okReq and res and res.Body and #res.Body > 20 then
                rawJson = res.Body
            end
        end
        if not rawJson then
            pcall(function()
                rawJson = game:HttpGet(apiUrl)
            end)
        end
        if not rawJson then return nil end

        local okDec, data = pcall(function() return httpService:JSONDecode(rawJson) end)
        if not okDec or not data or typeof(data.data) ~= "table" or #data.data == 0 then
            return nil
        end

        local healthyServers = {}
        local backupServers = {}
        for _, s in ipairs(data.data) do
            local cur = tonumber(s.playing) or 0
            local maxP = tonumber(s.maxPlayers) or 12
            if s.id and s.id ~= game.JobId then
                if cur >= 2 and cur <= (maxP - 2) then
                    table.insert(healthyServers, s.id)
                elseif cur >= 1 and cur < maxP then
                    table.insert(backupServers, s.id)
                end
            end
        end

        if #healthyServers > 0 then
            return healthyServers[math.random(1, #healthyServers)]
        elseif #backupServers > 0 then
            return backupServers[math.random(1, #backupServers)]
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
                -- Nếu có yêu cầu Boss cụ thể (preferKey), thử dùng Wukong Live Boss API
                if preferKey and preferKey ~= "" then
                    if typeof(genv.WK_FetchLiveBossApiSnapshot) == "function" and typeof(genv.WK_JoinLiveBossApiEntry) == "function" then
                        local ok, snap = pcall(genv.WK_FetchLiveBossApiSnapshot)
                        if ok and typeof(snap) == "table" and typeof(snap.entries) == "table" then
                            local matched = nil
                            for _, entry in ipairs(snap.entries) do
                                if tonumber(entry.placeId) == targetPlace and entry.players and (entry.players.current or 0) < (entry.players.max or 12) then
                                    local en = string.lower(tostring(entry.eventName or ""))
                                    if en:find(string.lower(preferKey)) then
                                        matched = entry
                                        break
                                    end
                                end
                            end
                            if matched then
                                print("[YokaHub][Auto-Sea-Switch] Same-place hop via Wukong Live Boss API:", matched.eventName)
                                pcall(genv.WK_JoinLiveBossApiEntry, matched)
                                task.wait(12.0)
                                isSwitchingSea = false
                                return
                            end
                        end
                    end
                end

                -- Nếu không có Boss cụ thể, đổi server ngẫu nhiên cùng Sea
                local jobId = getOpenServerForPlace(targetPlace)
                if jobId and jobId ~= "" then
                    print("[YokaHub][Auto-Sea-Switch] Same-place hop via TeleportToPlaceInstance JobId:", jobId)
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

    local function ensureCorrectSea(targetPlace: number, bossName: string, reason: string?, preferKey: string?): boolean
        if game.PlaceId == targetPlace then
            return true
        end
        local seaName = (targetPlace == SEA3_PLACE and "Sea 3") or (targetPlace == SEA2_PLACE and "Sea 2") or (targetPlace == SEA1_PLACE and "Sea 1") or "Sea"
        local notifyMsg = "Đang tự động chuyển sang " .. seaName .. " để săn " .. bossName .. "!"
        if reason and reason ~= "" then
            notifyMsg = "[" .. reason .. "] " .. notifyMsg
        end
        print("[YokaHub][Auto-Sea-Switch]", notifyMsg)
        safeNotify("Tự chuyển Sea", notifyMsg, "flight_takeoff")

        saveState(hubState)
        teleportToSea(targetPlace, preferKey)
        return false
    end

    -- An ngay tu frame dau tien khi Luna tao GUI de khi hop server khong nhay cua so len man hinh
    local userOpenedHub = false
    local hubDesiredOpen = false
    local preHideConn: RBXScriptConnection? = nil
    preHideConn = guiParent.ChildAdded:Connect(function(ch: Instance)
        if ch.Name == "Luna UI" and ch:IsA("ScreenGui") then
            if preHideConn then preHideConn:Disconnect(); preHideConn = nil end
            for _, nm in ipairs({ "SmartWindow", "ShadowHolder", "Drag", "MobileSupport" }) do
                local o = ch:FindFirstChild(nm)
                if o and o:IsA("GuiObject") then o.Visible = false end
            end
        end
    end)

    
    task.spawn(function()
        task.wait(0.5)
        pcall(function()
            local lg = getLunaGui()
            if lg then
                for _, desc in ipairs(lg:GetDescendants()) do
                    if desc.Name == "Tabs" and desc:IsA("ScrollingFrame") then
                        desc.AutomaticCanvasSize = Enum.AutomaticSize.Y
                        desc.ScrollBarThickness = 3
                        desc.CanvasSize = UDim2.new(0, 0, 0, 0)
                    end
                end
            end
        end)
    end)

    local Window = Luna:CreateWindow({
        Name = "YokaHub",
        Subtitle = "King Legacy · " .. curSeaLabel,
        LogoID = "6031097225",
        LoadingEnabled = false,
        LoadingTitle = "YokaHub",
        LoadingSubtitle = "King Legacy",
        ConfigSettings = {
            RootFolder = "YokaHub",
            ConfigFolder = "Configs",
        },
        KeySystem = false,
    })
    if preHideConn then preHideConn:Disconnect(); preHideConn = nil end

    local function getLunaGui(): ScreenGui?
        local g = guiParent:FindFirstChild("Luna UI") or coreGui:FindFirstChild("Luna UI")
        if g and g:IsA("ScreenGui") then return g end
        return nil
    end

    local function hideHubImmediate()
        hubDesiredOpen = false
        local lg = getLunaGui()
        if not lg then return end
        for _, nm in ipairs({ "SmartWindow", "ShadowHolder", "Drag", "MobileSupport" }) do
            local o = lg:FindFirstChild(nm)
            if o and o:IsA("GuiObject") then o.Visible = false end
        end
    end
    hideHubImmediate()

    -- ========================================================
    -- NUT HINH NEN MO/TAT GIONG WUKONG (60x60 BO TRON · LUON NAM TREN CUNG MOI GIAO DIEN)
    -- ========================================================
    local DOCK_TOP_ORDER = 2147483646
    local HUB_ORDER = 1000010
    local doExitToGateway: () -> ()

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

    local dockBtn = Instance.new("ImageButton")
    dockBtn.Name = "DockButton"
    dockBtn.Size = UDim2.fromOffset(60, 60)
    -- Dat gon goc tren phai ngay duoi nut Wukong va gioi han an toan trong man hinh
    local function clampDockPos(x: number, y: number): (number, number)
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        return math.clamp(math.floor(x), 8, math.max(8, math.floor(vp.X - 68))),
            math.clamp(math.floor(y), 8, math.max(8, math.floor(vp.Y - 68)))
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
        doExitToGateway()
    end)

    -- Tu giu nut avatar trong man hinh neu cua so Roblox bi thu nho
    local initCam = workspace.CurrentCamera
    if initCam then
        trackConn(initCam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if hubState.dockX and hubState.dockY then
                local cx, cy = clampDockPos(hubState.dockX, hubState.dockY)
                dockBtn.Position = UDim2.fromOffset(cx, cy)
            end
        end))
    end

    local dockCorner = Instance.new("UICorner")
    dockCorner.CornerRadius = UDim.new(0, 12)
    dockCorner.Parent = dockBtn

    local dockStroke = Instance.new("UIStroke")
    dockStroke.Thickness = 2
    dockStroke.Color = Color3.fromRGB(214, 92, 118)
    dockStroke.Transparency = 0.08
    dockStroke.Parent = dockBtn

    local dockScale = Instance.new("UIScale")
    dockScale.Name = "HoverScale"
    dockScale.Scale = 1
    dockScale.Parent = dockBtn

    -- Cham den nho o goc duoi phai bao trang thai Auto Hop
    local dockDot = Instance.new("Frame")
    dockDot.Name = "StatusDot"
    dockDot.Size = UDim2.fromOffset(11, 11)
    dockDot.Position = UDim2.new(1, -13, 1, -13)
    dockDot.BackgroundColor3 = Color3.fromRGB(140, 145, 160)
    dockDot.BorderSizePixel = 0
    dockDot.ZIndex = 105
    dockDot.Parent = dockBtn

    local dockDotCorner = Instance.new("UICorner")
    dockDotCorner.CornerRadius = UDim.new(1, 0)
    dockDotCorner.Parent = dockDot

    local dockDotStroke = Instance.new("UIStroke")
    dockDotStroke.Thickness = 1.6
    dockDotStroke.Color = Color3.fromRGB(14, 15, 20)
    dockDotStroke.Parent = dockDot

    local function updateDockDot()
        if currentMode == "solo" then
            dockDot.BackgroundColor3 = Color3.fromRGB(178, 102, 255)
            dockStroke.Color = Color3.fromRGB(178, 102, 255)
        elseif currentMode == "sea3" then
            dockDot.BackgroundColor3 = THEME.c2
            dockStroke.Color = THEME.c2
        elseif currentMode == "sea2" then
            dockDot.BackgroundColor3 = Color3.fromRGB(82, 178, 240)
            dockStroke.Color = Color3.fromRGB(82, 178, 240)
        else
            dockDot.BackgroundColor3 = Color3.fromRGB(145, 150, 165)
            dockStroke.Color = Color3.fromRGB(214, 92, 118)
        end
    end
    updateDockDot()

    -- ========================================================
    -- TOI UU GIAO DIEN: MEM MAI · BO TRON MUOT · HOVER TINH TE
    -- ========================================================
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

    local function styleCard(card: GuiObject, bg: Color3, strokeCol: Color3, strokeT: number, titleCol: Color3, descCol: Color3, kind: string)
        card.BackgroundColor3 = bg
        card.BackgroundTransparency = 0.04
        setCorner(card, 10)
        local st = card:FindFirstChildOfClass("UIStroke")
        if st then
            st.Color = strokeCol
            st.Transparency = strokeT
            st.Thickness = 1
        end
        local ttl = card:FindFirstChild("Title")
        if ttl and ttl:IsA("TextLabel") then
            ttl.AnchorPoint = Vector2.new(0, 0)
            ttl.TextColor3 = titleCol
            ttl.Font = Enum.Font.GothamMedium
            ttl.TextSize = 15
            ttl.TextYAlignment = Enum.TextYAlignment.Top
            ttl.Active = false
        end
        local cardInteract = card:FindFirstChild("Interact")
        if cardInteract and cardInteract:IsA("GuiButton") then
            cardInteract.ZIndex = 152
        end

        -- Hieu ung hover mem mai cho cac the tuong tac
        if kind ~= "paragraph" and not card:GetAttribute("YokaHoverHooked") then
            card:SetAttribute("YokaHoverHooked", true)
            local hoverBg = Color3.new(
                math.min(1, bg.R + 0.032),
                math.min(1, bg.G + 0.035),
                math.min(1, bg.B + 0.042)
            )
            local hoverStroke = (kind == "danger") and THEME.dangerStroke or THEME.c2
            trackConn(card.MouseEnter:Connect(function()
                tweenService:Create(card, tweenHover, { BackgroundColor3 = hoverBg }):Play()
                if st then
                    tweenService:Create(st, tweenHover, { Color = hoverStroke, Transparency = 0.18 }):Play()
                end
            end))
            trackConn(card.MouseLeave:Connect(function()
                tweenService:Create(card, tweenHover, { BackgroundColor3 = bg }):Play()
                if st then
                    tweenService:Create(st, tweenHover, { Color = strokeCol, Transparency = strokeT }):Play()
                end
            end))
        end

        local desc = card:FindFirstChild("Desc")
        local bodyTxt = card:FindFirstChild("Text")
        local hasDesc = (desc ~= nil and desc:IsA("TextLabel") and string.gsub(desc.Text, "%s+", "") ~= "")

        if kind == "paragraph" then
            card.AutomaticSize = Enum.AutomaticSize.Y
            card.Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset, 0, 0)
            if not card:FindFirstChild("YokaCardPad") then
                local p = Instance.new("UIPadding")
                p.Name = "YokaCardPad"
                p.PaddingBottom = UDim.new(0, 12)
                p.Parent = card
            end
            if ttl and ttl:IsA("TextLabel") then
                ttl.Position = UDim2.new(0, 14, 0, 10)
                ttl.Size = UDim2.new(1, -28, 0, 20)
            end
            if bodyTxt and bodyTxt:IsA("TextLabel") then
                bodyTxt.AnchorPoint = Vector2.new(0, 0)
                bodyTxt.Font = Enum.Font.Gotham
                bodyTxt.TextColor3 = descCol
                bodyTxt.TextSize = 13
                bodyTxt.LineHeight = 1.35
                bodyTxt.TextWrapped = true
                bodyTxt.TextYAlignment = Enum.TextYAlignment.Top
                bodyTxt.AutomaticSize = Enum.AutomaticSize.Y
                bodyTxt.Position = UDim2.new(0, 14, 0, 35)
                bodyTxt.Size = UDim2.new(1, -28, 0, 0)
            end
        elseif (kind == "toggle" or kind == "button" or kind == "danger") and hasDesc and desc and desc:IsA("TextLabel") then
            card.Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset, 0, 62)
            if ttl and ttl:IsA("TextLabel") then
                ttl.Position = UDim2.new(0, 14, 0, 9)
                ttl.Size = UDim2.new(1, -92, 0, 20)
            end
            desc.AnchorPoint = Vector2.new(0, 0)
            desc.Visible = true
            desc.Active = false
            desc.Font = Enum.Font.Gotham
            desc.TextColor3 = descCol
            desc.TextSize = 13
            desc.TextYAlignment = Enum.TextYAlignment.Top
            desc.TextTruncate = Enum.TextTruncate.AtEnd
            desc.Position = UDim2.new(0, 14, 0, 34)
            desc.Size = UDim2.new(1, -92, 0, 20)
        elseif kind == "button" or kind == "danger" then
            card.Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset, 0, 44)
            if desc and desc:IsA("GuiObject") then desc.Visible = false end
            if ttl and ttl:IsA("TextLabel") then
                ttl.Position = UDim2.new(0, 14, 0, 0)
                ttl.Size = UDim2.new(1, -56, 1, 0)
                ttl.TextYAlignment = Enum.TextYAlignment.Center
            end
        elseif kind == "dropdown" then
            if card.Size.Y.Offset <= 55 then
                card.Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset, 0, 44)
            end
            if ttl and ttl:IsA("TextLabel") then
                ttl.Position = UDim2.new(0, 14, 0, 0)
                ttl.Size = UDim2.new(0.55, 0, 0, 44)
                ttl.TextYAlignment = Enum.TextYAlignment.Center
            end
            if desc and desc:IsA("TextLabel") then
                desc.Font = Enum.Font.Gotham
                desc.TextColor3 = descCol
                desc.TextSize = 13
                desc.Active = false
            end
            -- Khong de o TextBox Selected chan click mo Dropdown
            local sel = card:FindFirstChild("Selected")
            if sel and sel:IsA("TextBox") then
                sel.TextEditable = false
                sel.Active = false
                sel.Selectable = false
                sel.ZIndex = 151
                sel.TextColor3 = THEME.c1
                sel.PlaceholderColor3 = THEME.c1
                sel.Font = Enum.Font.GothamMedium
            end
            -- An List & OptionHolderBackground khi Dropdown dang dong de khong de nut ben duoi
            local ddList = card:FindFirstChild("List")
            local ddBg = card:FindFirstChild("OptionHolderBackground")
            if ddBg and ddBg:IsA("GuiObject") then
                ddBg.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
                ddBg.BackgroundTransparency = 0.04
            end
            if ddList and ddList:IsA("ScrollingFrame") then
                for _, opt in ipairs(ddList:GetChildren()) do
                    if opt:IsA("TextLabel") and opt.Name ~= "Template" then
                        opt.Font = Enum.Font.GothamMedium
                        opt.TextSize = 13
                        opt.TextColor3 = Color3.fromRGB(232, 238, 248)
                    end
                end
            end
            local function syncDropdownVis()
                local isOpen = (card.Size.Y.Offset > 55)
                if ddList and ddList:IsA("GuiObject") then ddList.Visible = isOpen end
                if ddBg and ddBg:IsA("GuiObject") then ddBg.Visible = isOpen end
            end
            syncDropdownVis()
            if not card:GetAttribute("YokaDdHooked") then
                card:SetAttribute("YokaDdHooked", true)
                trackConn(card:GetPropertyChangedSignal("Size"):Connect(syncDropdownVis))
            end
        end
    end

    local sidebarExpandedInit = false
    local tabStylersHooked = false

    local function styleTabButtons(nav: Instance, inter: Instance?)
        local tabsFolder = nav:FindFirstChild("Tabs")
        if not tabsFolder then return end

        local function refreshAllTabs(instant: boolean?)
            local activeName = tostring(Window.CurrentTab or "Săn Boss")
            for _, tb in ipairs(tabsFolder:GetChildren()) do
                if tb:IsA("Frame") and tb.Visible and tb.Name ~= "InActive Template" then
                    local isActive = (tb.Name == activeName)
                    setCorner(tb, 9)
                    local grad = tb:FindFirstChildOfClass("UIGradient")
                    if grad then grad.Enabled = false end

                    local lbl = tb:FindFirstChildOfClass("TextLabel")
                    local icon = tb:FindFirstChildOfClass("ImageLabel")
                    local st = tb:FindFirstChildOfClass("UIStroke")

                    local targetBg = isActive and THEME.activeTabBg or THEME.inactiveTabBg
                    local targetBgT = isActive and 0 or 0.45
                    local targetTxt = isActive and Color3.fromRGB(16, 22, 20) or Color3.fromRGB(220, 226, 238)
                    local targetIcon = isActive and Color3.fromRGB(16, 22, 20) or Color3.fromRGB(190, 198, 214)
                    local targetSt = isActive and THEME.c1 or THEME.cardStroke
                    local targetStT = isActive and 0.25 or 0.6

                    if lbl then
                        lbl.Font = isActive and Enum.Font.GothamBold or Enum.Font.GothamMedium
                        lbl.TextSize = 14
                        lbl.TextTransparency = 0
                    end
                    if icon then icon.ImageTransparency = 0 end

                    if instant then
                        tb.BackgroundColor3 = targetBg
                        tb.BackgroundTransparency = targetBgT
                        if lbl then lbl.TextColor3 = targetTxt end
                        if icon then icon.ImageColor3 = targetIcon end
                        if st then st.Color = targetSt; st.Transparency = targetStT end
                    else
                        tweenService:Create(tb, tweenSoft, { BackgroundColor3 = targetBg, BackgroundTransparency = targetBgT }):Play()
                        if lbl then tweenService:Create(lbl, tweenSoft, { TextColor3 = targetTxt }):Play() end
                        if icon then tweenService:Create(icon, tweenSoft, { ImageColor3 = targetIcon }):Play() end
                        if st then tweenService:Create(st, tweenSoft, { Color = targetSt, Transparency = targetStT }):Play() end
                    end
                end
            end

            -- Giu UIPageLayout sach se, khong de tab khac lo mep va khong lam hong JumpTo cua Luna
            if inter then
                local upl = inter:FindFirstChildOfClass("UIPageLayout")
                if upl then
                    upl.Circular = false
                    upl.TweenTime = 0
                    upl.Padding = UDim.new(0, 32)
                end
                local activePage: GuiObject? = nil
                for _, pg in ipairs(inter:GetChildren()) do
                    if pg:IsA("ScrollingFrame") and pg.Name ~= "Template" and pg.Name ~= "Settings" and pg.Name ~= "Home" then
                        pg.Visible = true
                        if pg.Name == activeName then
                            activePage = pg
                            pg.CanvasPosition = Vector2.new(0, 0)
                        end
                    end
                end
                if upl and activePage then
                    pcall(function() upl:JumpTo(activePage) end)
                end
            end
        end

        refreshAllTabs(true)
        if not tabStylersHooked then
            tabStylersHooked = true
            for _, tb in ipairs(tabsFolder:GetChildren()) do
                if tb:IsA("Frame") and tb.Visible and tb.Name ~= "InActive Template" then
                    local interact = tb:FindFirstChild("Interact")
                    if interact and interact:IsA("GuiButton") then
                        trackConn(interact.MouseEnter:Connect(function()
                            if tostring(Window.CurrentTab) ~= tb.Name then
                                tweenService:Create(tb, tweenHover, { BackgroundTransparency = 0.2 }):Play()
                            end
                        end))
                        trackConn(interact.MouseLeave:Connect(function()
                            if tostring(Window.CurrentTab) ~= tb.Name then
                                tweenService:Create(tb, tweenHover, { BackgroundTransparency = 0.45 }):Play()
                            end
                        end))
                        trackConn(interact.MouseButton1Click:Connect(function()
                            task.delay(0.05, function() refreshAllTabs(false) end)
                            task.delay(0.38, function() refreshAllTabs(true) end)
                        end))
                    end
                end
            end
        end
    end

    local themeRemoteFired = false
    local function applyVisualTheme()
        pcall(function()
            Luna.ThemeGradient = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, THEME.c1),
                ColorSequenceKeypoint.new(0.50, THEME.c2),
                ColorSequenceKeypoint.new(1.00, THEME.c3),
            })
            local lunaGui = getLunaGui()
            if not lunaGui then return end

            if not themeRemoteFired then
                themeRemoteFired = true
                local tr = lunaGui:FindFirstChild("ThemeRemote")
                if tr and tr:IsA("BoolValue") then tr.Value = not tr.Value end
            end

            local smartWin = lunaGui:FindFirstChild("SmartWindow")
            if not (smartWin and smartWin:IsA("GuiObject")) then return end

            smartWin.ClipsDescendants = true
            setCorner(smartWin, 12)
            smartWin.BackgroundColor3 = THEME.sidebarBg
            smartWin.BackgroundTransparency = 0.01
            local swStroke = smartWin:FindFirstChildOfClass("UIStroke")
            if swStroke then
                swStroke.Color = THEME.outerStroke
                swStroke.Transparency = 0.35
                swStroke.Thickness = 1.2
            end
            local line = smartWin:FindFirstChild("Line")
            if line and line:IsA("GuiObject") then
                line.BackgroundColor3 = THEME.outerStroke
                line.BackgroundTransparency = 0.25
            end

            local titleBox = smartWin:FindFirstChild("Title")
            if titleBox then
                local tbLL = titleBox:FindFirstChildOfClass("UIListLayout")
                if tbLL then tbLL.Padding = UDim.new(0, 10) end
                local t1 = titleBox:FindFirstChild("Title")
                if t1 and t1:IsA("TextLabel") then
                    t1.Font = Enum.Font.GothamBold
                    t1.TextColor3 = THEME.c1
                end
                local t2 = titleBox:FindFirstChild("subtitle")
                if t2 and t2:IsA("TextLabel") then
                    t2.Font = Enum.Font.Gotham
                    t2.TextColor3 = Color3.fromRGB(168, 178, 196)
                end
            end

            -- Dam bao YokaHub noi gon tren Wukong va nut avatar LUON o tang cao nhat man hinh
            lunaGui.DisplayOrder = HUB_ORDER
            dockGui.DisplayOrder = DOCK_TOP_ORDER
            dockBtn.Visible = true
            if not smartWin:GetAttribute("YokaVisHooked") then
                smartWin:SetAttribute("YokaVisHooked", true)
                trackConn(smartWin:GetPropertyChangedSignal("Visible"):Connect(function()
                    dockBtn.Visible = true
                    dockStroke.Thickness = smartWin.Visible and 2.4 or 2.0
                end))
            end

            local nav = smartWin:FindFirstChild("Navigation")
            local els = smartWin:FindFirstChild("Elements")
            local inter = els and els:FindFirstChild("Interactions")

            if nav and nav:IsA("GuiObject") and els and els:IsA("GuiObject") then
                els.ClipsDescendants = true
                if inter and inter:IsA("GuiObject") then
                    inter.ClipsDescendants = true
                end

                local function syncPaneLayout()
                    local w = math.max(55, math.floor(nav.Size.X.Offset))
                    els.AnchorPoint = Vector2.new(0, 0)
                    els.Position = UDim2.new(0, w, 0, 43)
                    els.Size = UDim2.new(1, -w, 1, -43)
                end

                if not sidebarExpandedInit then
                    sidebarExpandedInit = true
                    nav.Size = UDim2.new(0, 205, 1, -43)
                    syncPaneLayout()
                    trackConn(nav:GetPropertyChangedSignal("Size"):Connect(syncPaneLayout))
                else
                    syncPaneLayout()
                end
                styleTabButtons(nav, inter)
            end

            if els and els:IsA("GuiObject") then
                els.BackgroundColor3 = THEME.contentBg
                els.BackgroundTransparency = 0.01
                for _, hiderName in ipairs({ "Corner Hider 1", "Corner Hider 2", "Corner Hider 3" }) do
                    local h = els:FindFirstChild(hiderName)
                    if h and h:IsA("GuiObject") then
                        h.BackgroundColor3 = THEME.contentBg
                        h.BackgroundTransparency = 0.01
                    end
                end

                if inter then
                    for _, page in ipairs(inter:GetChildren()) do
                        if page:IsA("ScrollingFrame") then
                            local pPad = page:FindFirstChildOfClass("UIPadding")
                            if pPad then
                                pPad.PaddingTop = UDim.new(0, 14)
                                pPad.PaddingBottom = UDim.new(0, 18)
                                pPad.PaddingLeft = UDim.new(0, 12)
                                pPad.PaddingRight = UDim.new(0, 12)
                            end
                            local pageLL = page:FindFirstChildOfClass("UIListLayout")
                            if pageLL then pageLL.Padding = UDim.new(0, 18) end

                            for _, sec in ipairs(page:GetChildren()) do
                                if sec.Name == "Section" and sec:IsA("TextLabel") then
                                    sec.Font = Enum.Font.GothamBold
                                    sec.TextColor3 = THEME.secTitle
                                    sec.TextSize = 14
                                    sec.AutomaticSize = Enum.AutomaticSize.Y
                                    local holder = sec:FindFirstChild("Frame")
                                    if holder and holder:IsA("GuiObject") then
                                        holder.Position = UDim2.new(0, 0, 0, 30)
                                        holder.AutomaticSize = Enum.AutomaticSize.Y
                                        local hLL = holder:FindFirstChildOfClass("UIListLayout")
                                        if hLL then hLL.Padding = UDim.new(0, 10) end
                                        for _, item in ipairs(holder:GetChildren()) do
                                            if item:IsA("GuiObject") then
                                                local nm = item.Name
                                                local isToggle = string.find(nm, " - Toggle") ~= nil or item:FindFirstChild("toggle") ~= nil
                                                local isDropdown = item:FindFirstChild("List") ~= nil or item:FindFirstChild("Selected") ~= nil
                                                local isParagraph = item:FindFirstChild("Text") ~= nil and item:FindFirstChild("Title") ~= nil and not isToggle and not isDropdown
                                                if isParagraph then
                                                    styleCard(item, THEME.infoBg, THEME.infoStroke, 0.42, THEME.infoTitle, Color3.fromRGB(238, 244, 250), "paragraph")
                                                elseif isToggle then
                                                    styleCard(item, THEME.cardBg, THEME.cardStroke, 0.50, THEME.textMain, THEME.textDesc, "toggle")
                                                elseif isDropdown then
                                                    styleCard(item, THEME.cardBg, THEME.cardStroke, 0.50, THEME.textMain, THEME.textDesc, "dropdown")
                                                elseif string.find(nm, "Tắt hoàn toàn") then
                                                    styleCard(item, THEME.dangerBg, THEME.dangerStroke, 0.40, THEME.dangerTitle, THEME.textDesc, "danger")
                                                else
                                                    styleCard(item, THEME.cardBg, THEME.cardStroke, 0.50, THEME.textMain, THEME.textDesc, "button")
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local function ensurePopScale(obj: Instance): UIScale
        local ex = obj:FindFirstChild("YokaPopScale")
        if ex and ex:IsA("UIScale") then return ex end
        local s = Instance.new("UIScale")
        s.Name = "YokaPopScale"
        s.Scale = 1
        s.Parent = obj
        return s
    end

    local onHubOpenedHooks: { () -> () } = {}
    local function isHubOpen(): boolean
        local lg = getLunaGui()
        local sw = lg and lg:FindFirstChild("SmartWindow")
        return (sw ~= nil and sw:IsA("GuiObject") and sw.Visible)
    end

    local hubVisToken = 0
    local function setHubVisible(visible: boolean)
        local lunaGui = getLunaGui()
        if not lunaGui then return end
        local sw = lunaGui:FindFirstChild("SmartWindow")
        local sh = lunaGui:FindFirstChild("ShadowHolder")
        local dr = lunaGui:FindFirstChild("Drag")
        local mobile = lunaGui:FindFirstChild("MobileSupport")
        if mobile and mobile:IsA("GuiObject") then mobile.Visible = false end

        hubVisToken += 1
        local myVisToken = hubVisToken
        hubDesiredOpen = visible

        if visible then
            userOpenedHub = true
            dockGui.DisplayOrder = DOCK_TOP_ORDER
            dockBtn.Visible = true
            dockStroke.Thickness = 2.4
            if not themeRemoteFired then applyVisualTheme() end
            for _, fn in ipairs(onHubOpenedHooks) do pcall(fn) end
            if sw and sw:IsA("GuiObject") then
                local sc = ensurePopScale(sw)
                sc.Scale = 0.94
                sw.BackgroundTransparency = 0.01
                sw.Visible = true
                tweenService:Create(sc, tweenSoft, { Scale = 1 }):Play()
                -- Dam bao UIPageLayout nhay dung trang ngay lan mo dau tien sau khi hop
                local el = sw:FindFirstChild("Elements")
                local inter = el and el:FindFirstChild("Interactions")
                if inter then
                    local upl = inter:FindFirstChildOfClass("UIPageLayout")
                    local activeNm = tostring(Window.CurrentTab or "Săn Boss")
                    local pg = inter:FindFirstChild(activeNm) or inter:FindFirstChild("Săn Boss")
                    if upl and pg and pg:IsA("GuiObject") then
                        pcall(function() upl:JumpTo(pg) end)
                    end
                end
            end
            if sh and sh:IsA("GuiObject") then
                local sc = ensurePopScale(sh)
                sc.Scale = 0.94
                sh.Visible = true
                tweenService:Create(sc, tweenSoft, { Scale = 1 }):Play()
            end
            if dr and dr:IsA("GuiObject") then dr.Visible = true end
        else
            dockBtn.Visible = true
            dockStroke.Thickness = 2.0
            if dr and dr:IsA("GuiObject") then dr.Visible = false end
            if sw and sw:IsA("GuiObject") then
                local sc = ensurePopScale(sw)
                local tw = tweenService:Create(sc, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.94 })
                tw:Play()
                if sh and sh:IsA("GuiObject") then
                    tweenService:Create(ensurePopScale(sh), TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.94 }):Play()
                end
                tw.Completed:Once(function()
                    if myVisToken ~= hubVisToken then return end
                    if sw and sw:IsA("GuiObject") then sw.Visible = false end
                    if sh and sh:IsA("GuiObject") then sh.Visible = false end
                    sc.Scale = 1
                    if sh then ensurePopScale(sh).Scale = 1 end
                end)
            end
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

    -- ========================================================
    -- FULL MAN HINH (ICON CHUAN MATERIAL) + KEO GOC DUOI-PHAI
    -- ========================================================
    local isFullscreen = false
    local preFullW, preFullH = 720, 450
    local preFullPos: UDim2? = nil

    doExitToGateway = function()
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "YokaHub",
                Text = "Đang quay lại Cổng Get Key...",
                Duration = 2,
            })
        end)
        task.delay(0.2, function()
            -- 1. Xoa file License luu tren may
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

            -- 2. Don dep YokaHub dang chay
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
            pcall(function() Luna:Destroy() end)
            genv._YokaHubLuna = nil

            -- 3. Mo lai ngay Cổng Gateway (Giao dien chua Get Key)
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
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        
        -- Nguong an toan dong phu hop moi man hinh (Mobile / Tablet / PC nho / 4K)
        local minW = math.clamp(math.floor(vp.X * 0.45), 360, 540)
        local maxW = math.max(minW, math.floor(vp.X - 16))
        local minH = math.clamp(math.floor(vp.Y * 0.45), 260, 340)
        local maxH = math.max(minH, math.floor(vp.Y - 16))

        local finalW = math.clamp(math.floor(w + 0.5), minW, maxW)
        local finalH = math.clamp(math.floor(h + 0.5), minH, maxH)
        hubState.winW = finalW
        hubState.winH = finalH
        if saveIt then saveState(hubState) end

        local lunaGui = getLunaGui()
        if not lunaGui then return end
        local smartWin = lunaGui:FindFirstChild("SmartWindow")
        local shadow = lunaGui:FindFirstChild("ShadowHolder")
        if not (smartWin and smartWin:IsA("GuiObject")) then return end

        -- He so co gian ty le noi dung tu dong (Responsive UI Scale)
        local smartScale = smartWin:FindFirstChild("YokaResponsiveScale")
        if not smartScale then
            smartScale = Instance.new("UIScale")
            smartScale.Name = "YokaResponsiveScale"
            smartScale.Parent = smartWin
        end
        local scaleFactor = math.clamp(math.min(vp.X / 1050, vp.Y / 680), 0.72, 1.0)
        smartScale.Scale = scaleFactor

        local newSize = UDim2.fromOffset(finalW, finalH)
        local twInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        if smooth then
            tweenService:Create(smartWin, twInfo, { Size = newSize }):Play()
            if shadow and shadow:IsA("GuiObject") then tweenService:Create(shadow, twInfo, { Size = newSize }):Play() end
        else
            smartWin.Size = newSize
            if shadow and shadow:IsA("GuiObject") then shadow.Size = newSize end
        end
    end

    local function toggleFullscreen()
        local lunaGui = getLunaGui()
        if not lunaGui then return end
        local smartWin = lunaGui:FindFirstChild("SmartWindow")
        local shadow = lunaGui:FindFirstChild("ShadowHolder")
        if not (smartWin and smartWin:IsA("GuiObject")) then return end

        local twInfo = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        if not isFullscreen then
            isFullscreen = true
            local curW = smartWin.Size.X.Offset
            local curH = smartWin.Size.Y.Offset
            if curW >= (vp.X - 40) or curH >= (vp.Y - 40) then
                preFullW, preFullH, preFullPos = 720, 450, UDim2.fromScale(0.5, 0.5)
            else
                preFullW, preFullH, preFullPos = curW, curH, smartWin.Position
            end

            local fullW = math.max(360, math.floor(vp.X - 16))
            local fullH = math.max(260, math.floor(vp.Y - 16))
            local fullSz = UDim2.fromOffset(fullW, fullH)
            local centerPos = UDim2.fromScale(0.5, 0.5)

            tweenService:Create(smartWin, twInfo, { Size = fullSz, Position = centerPos }):Play()
            if shadow and shadow:IsA("GuiObject") then
                tweenService:Create(shadow, twInfo, { Size = fullSz, Position = centerPos }):Play()
            end
        else
            isFullscreen = false
            local backW = math.clamp(preFullW, 360, math.max(360, math.floor(vp.X - 16)))
            local backH = math.clamp(preFullH, 260, math.max(260, math.floor(vp.Y - 16)))
            local backSz = UDim2.fromOffset(backW, backH)
            local backPos = preFullPos or UDim2.fromScale(0.5, 0.5)
            tweenService:Create(smartWin, twInfo, { Size = backSz, Position = backPos }):Play()
            if shadow and shadow:IsA("GuiObject") then
                tweenService:Create(shadow, twInfo, { Size = backSz, Position = backPos }):Play()
            end
        end
    end

    local function attachCornerResizer()
        local lunaGui = getLunaGui()
        if not lunaGui then return end
        local smartWin = lunaGui:FindFirstChild("SmartWindow")
        local shadow = lunaGui:FindFirstChild("ShadowHolder")
        if not (smartWin and smartWin:IsA("GuiObject")) then return end

        -- An nut Close goc cua Luna va thay bang nut X muot thu gon ve hinh nen avatar
        local origCtrls = smartWin:FindFirstChild("Controls")
        local origClose = origCtrls and origCtrls:FindFirstChild("Close")
        if origClose and origClose:IsA("GuiObject") then origClose.Visible = false end
        local oldClose = smartWin:FindFirstChild("YokaCloseBtn")
        if oldClose then oldClose:Destroy() end

        -- [NUT THOAT RA CỔNG KEY TREN THANH TIEU DE TOPBAR]
        local oldExit = smartWin:FindFirstChild("YokaExitToGatewayBtn")
        if oldExit then oldExit:Destroy() end

        local exitBtn = Instance.new("TextButton")
        exitBtn.Name = "YokaExitToGatewayBtn"
        exitBtn.AnchorPoint = Vector2.new(1, 0)
        exitBtn.Size = UDim2.fromOffset(150, 30)
        exitBtn.Position = UDim2.new(1, -112, 0, 6)
        exitBtn.BackgroundColor3 = Color3.fromRGB(195, 38, 54)
        exitBtn.BackgroundTransparency = 0.15
        exitBtn.BorderSizePixel = 0
        exitBtn.AutoButtonColor = false
        exitBtn.Font = Enum.Font.GothamBold
        exitBtn.TextSize = 11
        exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        exitBtn.Text = "🚪 THOÁT RA CỔNG KEY"
        exitBtn.ZIndex = 1002
        exitBtn.Parent = smartWin

        local exitCorner = Instance.new("UICorner")
        exitCorner.CornerRadius = UDim.new(0, 7)
        exitCorner.Parent = exitBtn

        local exitStroke = Instance.new("UIStroke")
        exitStroke.Color = Color3.fromRGB(255, 90, 90)
        exitStroke.Thickness = 1.2
        exitStroke.Parent = exitBtn

        trackConn(exitBtn.MouseEnter:Connect(function()
            tweenService:Create(exitBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(230, 25, 45), BackgroundTransparency = 0 }):Play()
        end))
        trackConn(exitBtn.MouseLeave:Connect(function()
            tweenService:Create(exitBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(195, 38, 54), BackgroundTransparency = 0.15 }):Play()
        end))
        trackConn(exitBtn.MouseButton1Click:Connect(function()
            doExitToGateway()
        end))

        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "YokaCloseBtn"
        closeBtn.AnchorPoint = Vector2.new(1, 0)
        closeBtn.Size = UDim2.fromOffset(30, 30)
        closeBtn.Position = UDim2.new(1, -6, 0, 6)
        closeBtn.BackgroundColor3 = Color3.fromRGB(34, 38, 50)
        closeBtn.BackgroundTransparency = 0.55
        closeBtn.BorderSizePixel = 0
        closeBtn.AutoButtonColor = false
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 15
        closeBtn.TextColor3 = Color3.fromRGB(210, 216, 230)
        closeBtn.Text = "×"
        closeBtn.ZIndex = 1002
        closeBtn.Parent = smartWin

        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 7)
        closeCorner.Parent = closeBtn

        trackConn(closeBtn.MouseEnter:Connect(function()
            tweenService:Create(closeBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(185, 58, 68), BackgroundTransparency = 0.1, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
        end))
        trackConn(closeBtn.MouseLeave:Connect(function()
            tweenService:Create(closeBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(34, 38, 50), BackgroundTransparency = 0.55, TextColor3 = Color3.fromRGB(210, 216, 230) }):Play()
        end))
        trackConn(closeBtn.MouseButton1Click:Connect(function()
            setHubVisible(false)
        end))

        -- Nut Full Man Hinh dung icon Material chuan (open_in_full = 6026568245), khong bi loi font
        local oldFs = smartWin:FindFirstChild("YokaFullscreenBtn")
        if oldFs then oldFs:Destroy() end

        local fsBtn = Instance.new("ImageButton")
        fsBtn.Name = "YokaFullscreenBtn"
        fsBtn.AnchorPoint = Vector2.new(1, 0)
        fsBtn.Size = UDim2.fromOffset(30, 30)
        fsBtn.Position = UDim2.new(1, -74, 0, 6)
        fsBtn.BackgroundColor3 = Color3.fromRGB(34, 38, 50)
        fsBtn.BackgroundTransparency = 0.55
        fsBtn.BorderSizePixel = 0
        fsBtn.AutoButtonColor = false
        fsBtn.Image = ""
        fsBtn.ZIndex = 999
        fsBtn.Parent = smartWin

        local fsCorner = Instance.new("UICorner")
        fsCorner.CornerRadius = UDim.new(0, 7)
        fsCorner.Parent = fsBtn

        local fsIcon = Instance.new("ImageLabel")
        fsIcon.Name = "Icon"
        fsIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        fsIcon.Position = UDim2.fromScale(0.5, 0.5)
        fsIcon.Size = UDim2.fromOffset(17, 17)
        fsIcon.BackgroundTransparency = 1
        fsIcon.Image = "http://www.roblox.com/asset/?id=6026568245"
        fsIcon.ImageColor3 = Color3.fromRGB(205, 212, 226)
        fsIcon.ZIndex = 1000
        fsIcon.Parent = fsBtn

        trackConn(fsBtn.MouseEnter:Connect(function()
            tweenService:Create(fsBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.15 }):Play()
            tweenService:Create(fsIcon, TweenInfo.new(0.12), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
        end))
        trackConn(fsBtn.MouseLeave:Connect(function()
            tweenService:Create(fsBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.55 }):Play()
            tweenService:Create(fsIcon, TweenInfo.new(0.12), { ImageColor3 = Color3.fromRGB(205, 212, 226) }):Play()
        end))
        trackConn(fsBtn.MouseButton1Click:Connect(toggleFullscreen))

        local old = smartWin:FindFirstChild("YokaResizeHandle")
        if old then old:Destroy() end

        local handle = Instance.new("TextButton")
        handle.Name = "YokaResizeHandle"
        handle.Size = UDim2.fromOffset(24, 24)
        handle.Position = UDim2.new(1, -24, 1, -24)
        handle.BackgroundTransparency = 1
        handle.BorderSizePixel = 0
        handle.AutoButtonColor = false
        handle.Text = ""
        handle.ZIndex = 999
        handle.Active = true
        handle.Parent = smartWin

        local function makeBar(w: number, x: number, y: number): Frame
            local bar = Instance.new("Frame")
            bar.Size = UDim2.fromOffset(w, 2)
            bar.Position = UDim2.fromOffset(x, y)
            bar.Rotation = -45
            bar.BackgroundColor3 = THEME.c1
            bar.BackgroundTransparency = 0.4
            bar.BorderSizePixel = 0
            bar.ZIndex = 1000
            bar.Parent = handle
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(1, 0)
            c.Parent = bar
            return bar
        end

        local b1 = makeBar(12, 8, 15)
        local b2 = makeBar(7, 13, 18)

        trackConn(handle.MouseEnter:Connect(function()
            tweenService:Create(b1, TweenInfo.new(0.12), { BackgroundTransparency = 0.05 }):Play()
            tweenService:Create(b2, TweenInfo.new(0.12), { BackgroundTransparency = 0.05 }):Play()
        end))
        trackConn(handle.MouseLeave:Connect(function()
            tweenService:Create(b1, TweenInfo.new(0.12), { BackgroundTransparency = 0.4 }):Play()
            tweenService:Create(b2, TweenInfo.new(0.12), { BackgroundTransparency = 0.4 }):Play()
        end))
        trackConn(smartWin:GetPropertyChangedSignal("Size"):Connect(function()
            local expanded = (smartWin.Size.Y.Offset >= 120)
            handle.Visible = expanded
            fsBtn.Visible = expanded
        end))
        local initExpanded = (smartWin.Size.Y.Offset >= 120)
        handle.Visible = initExpanded
        fsBtn.Visible = initExpanded

        local resizing = false
        local rStartMouse = Vector2.new(0, 0)
        local rStartW, rStartH = 720, 450
        local rStartPos = smartWin.Position

        trackConn(handle.InputBegan:Connect(function(input: InputObject)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true; isFullscreen = false
                rStartMouse = Vector2.new(input.Position.X, input.Position.Y)
                rStartW = smartWin.Size.X.Offset
                rStartH = smartWin.Size.Y.Offset
                rStartPos = smartWin.Position
            end
        end))
        trackConn(userInputService.InputChanged:Connect(function(input: InputObject)
            if not resizing then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = Vector2.new(input.Position.X, input.Position.Y) - rStartMouse
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
            local dragMinW = math.clamp(math.floor(vp.X * 0.45), 360, 540)
            local dragMaxW = math.max(dragMinW, math.floor(vp.X - 16))
            local dragMinH = math.clamp(math.floor(vp.Y * 0.45), 260, 340)
            local dragMaxH = math.max(dragMinH, math.floor(vp.Y - 16))
            local newW = math.clamp(math.floor(rStartW + delta.X), dragMinW, dragMaxW)
            local newH = math.clamp(math.floor(rStartH + delta.Y), dragMinH, dragMaxH)
            local ddx = (newW - rStartW) * 0.5
            local ddy = (newH - rStartH) * 0.5

            smartWin.Size = UDim2.fromOffset(newW, newH)
            smartWin.Position = UDim2.new(rStartPos.X.Scale, rStartPos.X.Offset + ddx, rStartPos.Y.Scale, rStartPos.Y.Offset + ddy)
            if shadow and shadow:IsA("GuiObject") then
                shadow.Size = smartWin.Size
                shadow.Position = smartWin.Position
            end
            hubState.winW = newW
            hubState.winH = newH
        end))
        trackConn(userInputService.InputEnded:Connect(function(input: InputObject)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                resizing = false
                saveState(hubState)
            end
        end))
    end

