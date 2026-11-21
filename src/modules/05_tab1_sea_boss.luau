    -- ========================================================
    -- HELPER API CHUNG
    -- ========================================================
    local function pickDropdownValue(v: any): string
        if typeof(v) == "table" then return tostring(v[1] or "") end
        return tostring(v or "")
    end

    local function getSlotTier(e: any): number
        local pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 99) or 99
        local pMax = typeof(e.players) == "table" and (tonumber(e.players.max) or 12) or 12
        if pCur >= pMax then return 0 end
        -- Phân hạng ưu tiên phòng ít người nhất: Càng ít người thì Tier càng cao
        if pCur <= 3 then return 5      -- Siêu ít người (1-3 người): Ưu tiên cao nhất
        elseif pCur <= 6 then return 4  -- Rất ít người (4-6 người): Ưu tiên rất cao
        elseif pCur <= 8 then return 3  -- Trung bình (7-8 người): Khá
        elseif pCur <= 10 then return 2 -- Khá đông (9-10 người): Thấp
        elseif pCur < pMax then return 1 -- Gần đầy (11 người): Dự phòng cuối
        end
        return 0
    end

    local function getEntryHpPercent(e: any): number
        if typeof(e) ~= "table" or typeof(e.health) ~= "table" then return 100 end
        local pct = tonumber(e.health.percent)
        if pct == nil then
            local cur = tonumber(e.health.current)
            local mx = tonumber(e.health.max)
            if cur ~= nil and mx ~= nil and mx > 0 then
                pct = (cur / mx) * 100
            end
        end
        if pct == nil or pct ~= pct then return 100 end
        return math.clamp(pct, 0, 100)
    end

    -- Lấy snapshot Live Boss API có TIMEOUT (API treo / mạng chậm không bao giờ làm kẹt luồng Hop)
    genv.YokaFetchBossSnapshot = function(timeoutSec: number?): (boolean, any)
        local fn = genv.WK_FetchLiveBossApiSnapshot
        if typeof(fn) ~= "function" then return false, nil end
        local limit = tonumber(timeoutSec) or 5.5
        local finished, okCall, result = false, false, nil
        task.spawn(function()
            local o, r = pcall(fn)
            okCall, result, finished = o, r, true
        end)
        local waited = 0
        while not finished and waited < limit do
            task.wait(0.05)
            waited += 0.05
        end
        if not finished then return false, nil end
        if okCall and typeof(result) == "table" and typeof(result.entries) == "table" then
            return true, result
        end
        return false, nil
    end

    local function isCurrentServerEntry(e: any): boolean
        if typeof(e) ~= "table" or game.JobId == "" then return false end
        local j1 = tostring(e.jobId or "")
        local j2 = tostring(e.serverId or "")
        local j3 = tostring(e.serverRef or "")
        local j4 = tostring(e.id or "")
        return j1 == game.JobId or j2 == game.JobId or j3 == game.JobId or j4 == game.JobId
    end

    -- ========================================================
    -- TAB 1: SAN BOSS
    -- ========================================================
    local HopTab = Window:CreateTab({
        Name = "🌊 Săn Boss Biển",
        Icon = "public",
        ImageSource = "Material",
        ShowTitle = false,
    })

    local StatusSection = HopTab:CreateSection("🌊 Trạng thái Săn Boss Biển")
    local StatusParagraph = StatusSection:CreateParagraph({
        Title = "Trạng thái · Đang tắt",
        Text = "Bật từng Boss bên dưới để tự động tìm phòng và săn.",
    })

    local lastStatusTitle = ""
    local lastStatusText = ""
    local statusDirty = false

    local syncingBossToggles = false
    local Sea3Toggle: any = nil
    local Sea2Toggle: any = nil
    local MasterAutoFightToggle: any = nil
    local bossToggles: { [string]: any } = {}

    -- Bộ điều khiển trung tâm Tab 1 (gom vào 1 bảng để không tốn thanh ghi local của Luau)
    local BossCtl: any = {
        sea3Keys = { "fightSea3DepthKing", "fightSea3Dragon", "fightSea3Abyssal", "fightSea3Kraken", "fightSea3Serpent", "fightSea3Crab", "fightSea3Events" },
        sea2Keys = { "fightSea2Hydra", "fightSea2SeaKing", "fightSea2GhostShip", "fightSea2Serpent" },
        islandReady = false,
        randomBusy = false,
        snipeBusy = false,
    }

    -- Chạy khối cập nhật UI đồng bộ: LUÔN trả cờ syncing về như cũ dù có lỗi (không bao giờ kẹt công tắc)
    function BossCtl.withSync(fn: () -> ())
        local prev = syncingBossToggles
        syncingBossToggles = true
        local ok, err = pcall(fn)
        syncingBossToggles = prev
        if not ok then warn("[YokaHub][Tab1] Lỗi đồng bộ công tắc:", tostring(err)) end
    end

    function BossCtl.setGroup(prefix: string, keys: { string }, value: boolean)
        BossCtl.withSync(function()
            for _, k in ipairs(keys) do
                (hubState :: any)[k] = value
            end
            for tk, tog in pairs(bossToggles) do
                if string.sub(tk, 1, 4) == prefix and tog and typeof(tog.Set) == "function" then
                    pcall(function() tog:Set({ CurrentValue = value }) end)
                end
            end
        end)
    end

    function BossCtl.stopAll(notifyUser: boolean)
        BossCtl.withSync(function()
            for _, k in ipairs(BossCtl.sea3Keys) do (hubState :: any)[k] = false end
            for _, k in ipairs(BossCtl.sea2Keys) do (hubState :: any)[k] = false end
            for _, tog in pairs(bossToggles) do
                if tog and typeof(tog.Set) == "function" then
                    pcall(function() tog:Set({ CurrentValue = false }) end)
                end
            end
            if Sea3Toggle and typeof(Sea3Toggle.Set) == "function" then
                pcall(function() Sea3Toggle:Set({ CurrentValue = false }) end)
            end
            if Sea2Toggle and typeof(Sea2Toggle.Set) == "function" then
                pcall(function() Sea2Toggle:Set({ CurrentValue = false }) end)
            end
        end)
        BossCtl.apply("off", notifyUser)
    end

    local function getActiveBossSummary(): (string, string)
        if currentMode == "sea3" then
            local names: { string } = {}
            if hubState.fightSea3DepthKing then table.insert(names, "Depth King") end
            if hubState.fightSea3Dragon then table.insert(names, "Dragon") end
            if hubState.fightSea3Abyssal then table.insert(names, "Sea Dragon / Abyssal") end
            if hubState.fightSea3Kraken then table.insert(names, "Kraken") end
            if hubState.fightSea3Serpent then table.insert(names, "Sea Serpent") end
            if hubState.fightSea3Crab then table.insert(names, "Crab") end
            if hubState.fightSea3Events then table.insert(names, "Sea Events") end
            if #names == 7 then
                return "Sea 3 (Tất cả)", "Đang tự động tìm phòng có bất kỳ Boss nào ở Sea 3..."
            elseif #names > 0 then
                local str = table.concat(names, ", ")
                return "Sea 3 · " .. str, "Đang tự động tìm phòng có: " .. str .. "..."
            else
                return "Sea 3", "Chưa bật Boss nào ở Sea 3."
            end
        elseif currentMode == "sea2" then
            local names: { string } = {}
            if hubState.fightSea2Hydra then table.insert(names, "Hydra") end
            if hubState.fightSea2SeaKing then table.insert(names, "Sea King") end
            if hubState.fightSea2GhostShip then table.insert(names, "Thuyền Ma") end
            if hubState.fightSea2Serpent then table.insert(names, "Serpent") end
            if #names == 4 then
                return "Sea 2 (Tất cả)", "Đang tự động tìm phòng có bất kỳ Boss / Rương nào ở Sea 2..."
            elseif #names > 0 then
                local str = table.concat(names, ", ")
                return "Sea 2 · " .. str, "Đang tự động tìm phòng có: " .. str .. "..."
            else
                return "Sea 2", "Chưa bật Boss nào ở Sea 2."
            end
        end
        return "Đang tắt", "Bật từng Boss bên dưới để bắt đầu tự động tìm phòng và săn."
    end

    local function setStatus(text: string, force: boolean?)
        local modeSummary, defaultText = getActiveBossSummary()
        local titleStr = "Trạng thái · " .. modeSummary
        local displayText = text
        if displayText == "" or displayText == nil then
            displayText = defaultText
        end
        if not force and titleStr == lastStatusTitle and displayText == lastStatusText then
            return
        end
        lastStatusTitle = titleStr
        lastStatusText = displayText
        if not force and not isHubOpen() then
            statusDirty = true
            return
        end
        statusDirty = false
        pcall(function()
            StatusParagraph:Set({ Title = titleStr, Text = displayText })
        end)
    end
    table.insert(onHubOpenedHooks, function()
        if statusDirty and lastStatusText ~= "" then
            setStatus(lastStatusText, true)
        end
    end)

    function BossCtl.applyInner(newMode: string, notifyUser: boolean)
        -- Khử xung đột: Khi chuyển sang Săn Boss, tự động bật Master Auto Fight và tắt các chế độ cày cục bộ
        if newMode ~= "off" then
            hubState.autoFightMaster = true
            hubState.autoCollectChest = true
            local hadConflict = hubState.autoLevel or hubState.autoKillSelectedMob or hubState.farmSea3Mat or hubState.farmSea2Mat or hubState.farmSea1Mat or hubState.autoDungeon or hubState.autoFish or hubState.autoFightIslandBoss
            deactivateOtherLocalModes("none")
            if hadConflict then
                safeNotify("YokaHub", "Đã ưu tiên Săn Boss Biển (Tạm dừng các chế độ cày quái/câu cá/dungeon).", "info")
            end
        end
        currentMode = newMode
        hubState.mode = newMode
        genv._KingAutoHopMode = newMode
        genv._AutoSeaEventApiHop = false
        genv._AutoSea2PriorityApiHop = false
        genv._AutoDepthKingOnlyApiHop = false
        saveState(hubState)
        updateDockDot()
        if newMode ~= "off" then
            armAutoReexec(false)
        end

        if MasterAutoFightToggle and typeof(MasterAutoFightToggle.UpdateState) == "function" then
            pcall(function() MasterAutoFightToggle:UpdateState(hubState.autoFightMaster == true) end)
        elseif MasterAutoFightToggle and typeof(MasterAutoFightToggle.Set) == "function" and MasterAutoFightToggle.CurrentValue ~= hubState.autoFightMaster then
            pcall(function() MasterAutoFightToggle:Set({ CurrentValue = hubState.autoFightMaster }) end)
        end

        if newMode == "sea3" then
            local preferSea3Boss = (hubState.fightSea3DepthKing and "depth")
                or (hubState.fightSea3Dragon and "dragon")
                or (hubState.fightSea3Abyssal and "abyssal")
                or (hubState.fightSea3Kraken and "kraken")
                or (hubState.fightSea3Serpent and "serpent")
                or (hubState.fightSea3Crab and "crab")
                or "depth"
            if not ensureCorrectSea(SEA3_PLACE, "Boss Sea 3", "Săn Boss", preferSea3Boss) then
                setStatus("Đang tự động chuyển sang Sea 3 để săn Boss...", true)
                return
            end
            local summary, _ = getActiveBossSummary()
            setStatus("Đang tìm phòng có Boss ở Sea 3 (" .. summary .. ")...", true)
            if notifyUser then
                safeNotify("YokaHub", "Đã bật Auto Hop: " .. summary, "public")
            end
        elseif newMode == "sea2" then
            local preferSea2Boss = (hubState.fightSea2Hydra == true and "hydra")
                or (hubState.fightSea2SeaKing == true and "sea king")
                or (hubState.fightSea2Serpent == true and "serpent")
                or (hubState.fightSea2GhostShip == true and "ghost")
                or "hydra"
            if not ensureCorrectSea(SEA2_PLACE, "Boss Sea 2", "Săn Boss", preferSea2Boss) then
                setStatus("Đang tự động chuyển sang Sea 2 để săn Boss & Rương...", true)
                return
            end
            local summary, _ = getActiveBossSummary()
            setStatus("Đang tìm phòng có Boss / Rương ở Sea 2 (" .. summary .. ")...", true)
            if notifyUser then
                safeNotify("YokaHub", "Đã bật Auto Hop: " .. summary, "public")
            end
        else
            -- Tắt toàn bộ cờ tự động nhảy phòng ngầm để bảo đảm đứng yên tại server hiện tại
            pcall(function()
                genv.AutoHop = false
                genv.HopDepthKing = false
                genv.HopDepthKingApi = false
                genv.autoskhdhop = false
                genv.hopSerpent = false
                genv.hopSerpentApi = false
                genv.HopSkullKing = false
                genv.HopSkullKingApi = false
                genv.HopJackOLantern = false
                genv.HopJackOLanternPremium = false
                genv.HalloweenHopBoss = false
                genv.PlayerAutoHop = false
                genv.AutoHopConquest = false
                genv.AutoDepthKing = false
                genv.SeaEvent = false
                genv.HydraSeaKing = false
                genv.GhostShip = false
                genv.seaking = false
                genv.Serpent = false
            end)
            setStatus("Đã tắt — Đứng yên tại phòng hiện tại (đã chặn mọi tự chuyển phòng).", true)
            if notifyUser then
                safeNotify("YokaHub", "Đã tắt hoàn toàn tự chuyển phòng.", "notifications")
            end
        end
    end

    -- Bản bọc an toàn: lỗi bất kỳ trong quá trình đổi chế độ không bao giờ làm chết luồng gọi (công tắc / phím tắt / Hop)
    local function applyMode(newMode: string, notifyUser: boolean)
        local ok, err = pcall(BossCtl.applyInner, newMode, notifyUser)
        if not ok then
            warn("[YokaHub][Tab1] Lỗi applyMode:", tostring(err))
            currentMode = newMode
            hubState.mode = newMode
        end
    end

    local function recalcHopMode(notifyUser: boolean, preferMode: string?)
        local anySea3 = (hubState.fightSea3DepthKing == true)
            or (hubState.fightSea3Dragon == true)
            or (hubState.fightSea3Abyssal == true)
            or (hubState.fightSea3Kraken == true)
            or (hubState.fightSea3Serpent == true)
            or (hubState.fightSea3Crab == true)
            or (hubState.fightSea3Events == true)

        local anySea2 = (hubState.fightSea2Hydra == true)
            or (hubState.fightSea2SeaKing == true)
            or (hubState.fightSea2GhostShip == true)
            or (hubState.fightSea2Serpent == true)

        local allSea3 = (hubState.fightSea3DepthKing == true)
            and (hubState.fightSea3Dragon == true)
            and (hubState.fightSea3Abyssal == true)
            and (hubState.fightSea3Kraken == true)
            and (hubState.fightSea3Serpent == true)
            and (hubState.fightSea3Crab == true)
            and (hubState.fightSea3Events == true)

        local allSea2 = (hubState.fightSea2Hydra == true)
            and (hubState.fightSea2SeaKing == true)
            and (hubState.fightSea2GhostShip == true)
            and (hubState.fightSea2Serpent == true)

        local newMode = "off"
        if anySea3 and anySea2 then
            if preferMode == "sea3" or preferMode == "sea2" then
                newMode = preferMode
            elseif currentMode == "sea3" or currentMode == "sea2" then
                newMode = currentMode
            else
                newMode = (game.PlaceId == SEA2_PLACE) and "sea2" or "sea3"
            end
        elseif anySea3 then
            newMode = "sea3"
        elseif anySea2 then
            newMode = "sea2"
        else
            newMode = "off"
        end

        applyMode(newMode, notifyUser)

        BossCtl.withSync(function()
            if Sea3Toggle and typeof(Sea3Toggle.Set) == "function" then
                pcall(function() Sea3Toggle:Set({ CurrentValue = allSea3 }) end)
            end
            if Sea2Toggle and typeof(Sea2Toggle.Set) == "function" then
                pcall(function() Sea2Toggle:Set({ CurrentValue = allSea2 }) end)
            end
        end)
    end

    BossCtl.apply = applyMode
    BossCtl.recalc = recalcHopMode

    genv.SetKingAutoHopMode = function(m: string) applyMode(m, false) end
    genv.YokaStopAllBossHop = function(notifyUser: boolean?) BossCtl.stopAll(notifyUser == true) end
    genv.SetAutoDepthKingHopEnabled = function(on: boolean)
        BossCtl.setGroup("Sea3", BossCtl.sea3Keys, false)
        if on then
            BossCtl.withSync(function()
                hubState.fightSea3DepthKing = true
                local t = bossToggles.Sea3DepthKing
                if t and typeof(t.Set) == "function" then
                    pcall(function() t:Set({ CurrentValue = true }) end)
                end
            end)
        end
        recalcHopMode(false)
    end
    genv.SetAutoHopEnabled = function(on: boolean)
        BossCtl.setGroup("Sea3", BossCtl.sea3Keys, on == true)
        recalcHopMode(false)
    end
    genv.SetAutoSea2HopEnabled = function(on: boolean)
        BossCtl.setGroup("Sea2", BossCtl.sea2Keys, on == true)
        recalcHopMode(false)
    end

    Sea3Toggle = StatusSection:CreateToggle({
        Name = "🐉 Bật / Tắt toàn bộ Boss Sea 3 (Phím F8)",
        Description = "Ưu tiên: Depth King (Top 1) → Dragon (Top 2) → Sea Dragon / Abyssal (Top 3) → Kraken → Sea Serpent → Crab → Sea Events",
        CurrentValue = (hubState.mode == "sea3" and hubState.fightSea3DepthKing == true and hubState.fightSea3Dragon == true and hubState.fightSea3Abyssal == true and hubState.fightSea3Kraken == true and hubState.fightSea3Serpent == true and hubState.fightSea3Crab == true and hubState.fightSea3Events == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea2", BossCtl.sea2Keys, false) end
            BossCtl.setGroup("Sea3", BossCtl.sea3Keys, on)
            saveState(hubState)
            recalcHopMode(true, on and "sea3" or nil)
        end,
    }, "AutoHopSea3")

    Sea2Toggle = StatusSection:CreateToggle({
        Name = "🐍 Bật / Tắt toàn bộ Boss Sea 2 (Phím F9)",
        Description = "Ưu tiên: Rương Hydra → Hydra → Sea King → Serpent → Tàu Ma",
        CurrentValue = (hubState.mode == "sea2" and hubState.fightSea2Hydra == true and hubState.fightSea2SeaKing == true and hubState.fightSea2GhostShip == true and hubState.fightSea2Serpent == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea3", BossCtl.sea3Keys, false) end
            BossCtl.setGroup("Sea2", BossCtl.sea2Keys, on)
            saveState(hubState)
            recalcHopMode(true, on and "sea2" or nil)
        end,
    }, "AutoHopSea2")

    StatusSection:CreateButton({
        Name = "⛔ Dừng toàn bộ Auto Hop (Đứng yên tại phòng)",
        Description = "Tắt tức thì mọi chế độ nhảy phòng và dừng săn Boss",
        Callback = function()
            BossCtl.stopAll(true)
        end,
    })

    trackConn(userInputService.InputBegan:Connect(function(input: InputObject, gp: boolean)
        if gp or genv._YokaHubToken ~= myToken then return end
        if input.KeyCode ~= Enum.KeyCode.F8 and input.KeyCode ~= Enum.KeyCode.F9 then return end
        local okKey, errKey = pcall(function()
            if input.KeyCode == Enum.KeyCode.F8 then
                local turnOn = (currentMode ~= "sea3")
                -- F8 và F9 loại trừ nhau: bật Sea 3 thì tạm tắt nhóm Sea 2 để chế độ không bị kẹt sai Sea
                if turnOn then BossCtl.setGroup("Sea2", BossCtl.sea2Keys, false) end
                BossCtl.setGroup("Sea3", BossCtl.sea3Keys, turnOn)
            else
                local turnOn = (currentMode ~= "sea2")
                if turnOn then BossCtl.setGroup("Sea3", BossCtl.sea3Keys, false) end
                BossCtl.setGroup("Sea2", BossCtl.sea2Keys, turnOn)
            end
            saveState(hubState)
            recalcHopMode(true)
        end)
        if not okKey then warn("[YokaHub][Tab1] Lỗi phím tắt F8/F9:", tostring(errKey)) end
    end))

    -- ========================================================
    -- BẢNG 1: CÀI ĐẶT CHIẾN ĐẤU BOSS & NHẶT RƯƠNG
    -- ========================================================
    local MasterFightSection = HopTab:CreateSection("🌟 CÀI ĐẶT CHIẾN ĐẤU BOSS & SEA EVENT")

    local AutoFightSeaEventToggle = MasterFightSection:CreateToggle({
        Name = "🌊 Tự Động Đánh Sea Event (Auto Fight Sea Event)",
        Description = "Tự động bay đến diệt mọi sự kiện biển (Kraken, Hydra, Vua Biển, Tàu Ma, Rắn Biển, Rồng Lửa...), tự xả chiêu và spam M1 theo Tab 3 chuẩn xác, bỏ động tác thừa",
        CurrentValue = (hubState.autoFightSeaEvent ~= false),
        Callback = function(Value: boolean)
            local on = (Value == true)
            hubState.autoFightSeaEvent = on
            saveState(hubState)
            pcall(function()
                genv.AutoFightSeaEvent = on
                genv.SeaEvent = on
            end)
            if on then
                safeNotify("YokaHub Sea Event", "Đã bật Tự Động Đánh Sea Event (Xả Skill & M1 theo Tab 3)!", "flash_on")
            else
                safeNotify("YokaHub Sea Event", "Đã tắt Tự Đánh Sea Event.", "info")
            end
        end,
    }, "AutoFightSeaEventToggle")

    MasterAutoFightToggle = MasterFightSection:CreateToggle({
        Name = "⚔️ Tự Động Đánh Boss & Săn Sea Event (Master Auto Fight)",
        Description = "Tự động bay đến diệt Boss biển, né chiêu trên không và tích hợp tự động nhặt rương sự kiện biển (Hydra, Vua Biển, Depth King...)",
        CurrentValue = (hubState.autoFightMaster == true),
        Callback = function(Value: boolean)
            local on = (Value == true)
            hubState.autoFightMaster = on
            saveState(hubState)
            if on then
                safeNotify("YokaHub Boss", "Đã bật Master Auto Fight & Săn Sea Event!", "flash_on")
            else
                safeNotify("YokaHub Boss", "Đã tắt Auto Fight Boss.", "info")
            end
        end,
    }, "MasterAutoFightToggle")

    MasterFightSection:CreateToggle({
        Name = "🧠 Tự Động Chỉnh Độ Cao Theo Từng Boss (Smart Height)",
        Description = "Tự động bay cao hay thấp chuẩn xác theo từng Boss (Hydra/Abyssal 80m, Depth King/Dragon 75m, Sea King 70m, Râu Đen/Râu Trắng/Hephaestus 36-38m, Lôi Thần/Ace 34-35m, Boss Đảo 28m) né trọn vẹn lốc xoáy & chiêu nộ",
        CurrentValue = (hubState.smartBossHeight ~= false),
        Callback = function(Value: boolean)
            local on = (Value == true)
            hubState.smartBossHeight = on
            saveState(hubState)
            if on then
                safeNotify("YokaHub Boss", "Đã bật Smart Safe Height (Tự chỉnh độ cao theo Boss)!", "brain")
            else
                safeNotify("YokaHub Boss", "Đã tắt Smart Height: Dùng độ cao thủ công cố định.", "info")
            end
        end,
    }, "SmartBossHeightToggle")

    MasterFightSection:CreateSlider({
        Name = "🕊️ Độ Cao Bay An Toàn Thủ Công (Manual Height)",
        Description = "Độ cao bay cố định khi tắt chế độ thông minh (hoặc dùng làm mốc dự phòng)",
        Range = { 10, 150 },
        Increment = 2,
        Suffix = "studs",
        CurrentValue = tonumber(hubState.bossSafeHeight) or 35,
        Callback = function(Value: number)
            hubState.bossSafeHeight = math.clamp(math.floor(tonumber(Value) or 35), 10, 150)
            saveState(hubState)
        end,
    }, "BossSafeHeightSlider")

    MasterFightSection:CreateSlider({
        Name = "⚡ Tốc Độ Quét & Hop Server API",
        Description = "Thời gian chờ quét lại API khi chưa có phòng trống (Mặc định 1.5s, siêu tốc 0.5s)",
        Range = { 0.5, 10 },
        Increment = 0.5,
        Suffix = "giây",
        CurrentValue = tonumber(hubState.apiHopInterval) or 1.5,
        Callback = function(Value: number)
            hubState.apiHopInterval = math.clamp(math.floor((tonumber(Value) or 1.5) * 2 + 0.5) / 2, 0.5, 10)
            genv.ApiHopInterval = hubState.apiHopInterval
            saveState(hubState)
        end,
    }, "ApiHopIntervalSlider")

    MasterFightSection:CreateToggle({
        Name = "🚫 Tắt Tự Động Đánh Kraken & Xúc Tu",
        Description = "Bỏ qua hoàn toàn Boss Quái Biển Kraken và xúc tu, không bay tới và không tấn công để tập trung săn các Boss lớn khác",
        CurrentValue = (hubState.ignoreKraken == true),
        Callback = function(Value: boolean)
            local on = (Value == true)
            hubState.ignoreKraken = on
            saveState(hubState)
            pcall(function()
                genv.IgnoreKraken = on
                if on and typeof(genv._YokaClearCombatTargetIfMatches) == "function" then
                    genv._YokaClearCombatTargetIfMatches("kraken", "tentacle", "galleon")
                end
            end)
            if on then
                safeNotify("YokaHub Boss", "Đã bật: Tắt đánh Boss Quái Biển Kraken & Xúc tu!", "block")
            else
                safeNotify("YokaHub Boss", "Đã tắt: Cho phép đánh lại Kraken.", "check")
            end
        end,
    }, "IgnoreKrakenToggle")

    MasterFightSection:CreateToggle({
        Name = "🚫 Tắt Tự Động Đánh Tàu Galleon",
        Description = "Bỏ qua hoàn toàn tất cả các loại Boss Thuyền Galleon (Ghost Galleon, Kraken Galleon...), không bắn phá tàu để tiết kiệm thời gian",
        CurrentValue = (hubState.ignoreGalleon == true),
        Callback = function(Value: boolean)
            local on = (Value == true)
            hubState.ignoreGalleon = on
            saveState(hubState)
            pcall(function()
                genv.IgnoreGalleon = on
                if on and typeof(genv._YokaClearCombatTargetIfMatches) == "function" then
                    genv._YokaClearCombatTargetIfMatches("galleon", nil, nil)
                end
            end)
            if on then
                safeNotify("YokaHub Boss", "Đã bật: Tắt đánh Boss Thuyền Galleon (bao gồm Kraken Galleon)!", "block")
            else
                safeNotify("YokaHub Boss", "Đã tắt: Cho phép đánh lại Galleon.", "check")
            end
        end,
    }, "IgnoreGalleonToggle")

    -- Đồng bộ cờ chiến đấu Tab 1 ra môi trường ngay khi khởi tạo
    pcall(function()
        genv.AutoFightSeaEvent = (hubState.autoFightSeaEvent ~= false)
        genv.IgnoreKraken = (hubState.ignoreKraken == true)
        genv.IgnoreGalleon = (hubState.ignoreGalleon == true)
        genv.ApiHopInterval = math.clamp(math.floor((tonumber(hubState.apiHopInterval) or 1.5) * 2 + 0.5) / 2, 0.5, 10)
    end)

    -- ========================================================
    -- BẢNG 2: TỰ ĐỘNG HOP & SĂN BOSS SEA 3 (TỪNG CON RIÊNG BIỆT)
    -- ========================================================
    local Sea3FightSection = HopTab:CreateSection("👑 TỰ ĐỘNG HOP & SĂN BOSS SEA 3 (API TỪNG CON)")
    bossToggles.Sea3DepthKing = Sea3FightSection:CreateToggle({
        Name = "👑 Auto Hop & Săn Depth King (Sea 3)",
        Description = "Tự động tìm phòng có Vua Vực Thẳm Depth King qua API, bay tới diệt và mở rương (Top 1)",
        CurrentValue = (hubState.fightSea3DepthKing == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea2", BossCtl.sea2Keys, false) end
            hubState.fightSea3DepthKing = on
            saveState(hubState)
            recalcHopMode(true, on and "sea3" or nil)
        end,
    }, "FightSea3DepthKingToggle")

    bossToggles.Sea3Dragon = Sea3FightSection:CreateToggle({
        Name = "🐲 Auto Hop & Săn Dragon (Sea 3)",
        Description = "Tự động tìm phòng có Dragon (Wukong API: Dragon) qua API và tiêu diệt (Top 2)",
        CurrentValue = (hubState.fightSea3Dragon == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea2", BossCtl.sea2Keys, false) end
            hubState.fightSea3Dragon = on
            saveState(hubState)
            recalcHopMode(true, on and "sea3" or nil)
        end,
    }, "FightSea3DragonToggle")

    bossToggles.Sea3Abyssal = Sea3FightSection:CreateToggle({
        Name = "🐉 Auto Hop & Săn Abyssal / Sea Dragon (Sea 3)",
        Description = "Tự động tìm phòng có Abyssal Tyrant (Wukong API: Sea Dragon) qua API và tiêu diệt (Top 3)",
        CurrentValue = (hubState.fightSea3Abyssal == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea2", BossCtl.sea2Keys, false) end
            hubState.fightSea3Abyssal = on
            saveState(hubState)
            recalcHopMode(true, on and "sea3" or nil)
        end,
    }, "FightSea3AbyssalToggle")

    bossToggles.Sea3Kraken = Sea3FightSection:CreateToggle({
        Name = "🐙 Auto Hop & Săn Kraken (Sea 3)",
        Description = "Tự động tìm phòng có Kraken qua API, chặt xúc tu và diệt thân quái (Top 4)",
        CurrentValue = (hubState.fightSea3Kraken == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea2", BossCtl.sea2Keys, false) end
            hubState.fightSea3Kraken = on
            saveState(hubState)
            recalcHopMode(true, on and "sea3" or nil)
        end,
    }, "FightSea3KrakenToggle")

    bossToggles.Sea3Serpent = Sea3FightSection:CreateToggle({
        Name = "🐍 Auto Hop & Săn Sea Serpent (Sea 3)",
        Description = "Tự động tìm phòng có Sea Serpent qua API và tiêu diệt (Ưu tiên cao hơn Crab & Tàu, Top 5)",
        CurrentValue = (hubState.fightSea3Serpent == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea2", BossCtl.sea2Keys, false) end
            hubState.fightSea3Serpent = on
            saveState(hubState)
            recalcHopMode(true, on and "sea3" or nil)
        end,
    }, "FightSea3SerpentToggle")

    bossToggles.Sea3Crab = Sea3FightSection:CreateToggle({
        Name = "🦀 Auto Hop & Săn Crab / Giant Crab (Sea 3)",
        Description = "Tự động tìm phòng có Crab / Giant Crab Sea 3 qua API và tiêu diệt (Top 6)",
        CurrentValue = (hubState.fightSea3Crab == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea2", BossCtl.sea2Keys, false) end
            hubState.fightSea3Crab = on
            saveState(hubState)
            recalcHopMode(true, on and "sea3" or nil)
        end,
    }, "FightSea3CrabToggle")

    bossToggles.Sea3Events = Sea3FightSection:CreateToggle({
        Name = "🌊 Auto Hop & Săn Sea Event Thường (Sea 3)",
        Description = "Tự động tìm phòng có sự kiện biển vừa và nhỏ (Galleon, Sea Beast...)",
        CurrentValue = (hubState.fightSea3Events == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea2", BossCtl.sea2Keys, false) end
            hubState.fightSea3Events = on
            saveState(hubState)
            recalcHopMode(true, on and "sea3" or nil)
        end,
    }, "FightSea3EventsToggle")

    -- ========================================================
    -- BẢNG 3: TỰ ĐỘNG HOP & SĂN BOSS SEA 2 (TỪNG CON RIÊNG BIỆT)
    -- ========================================================
    local Sea2FightSection = HopTab:CreateSection("🐋 TỰ ĐỘNG HOP & SĂN BOSS SEA 2 (API TỪNG CON)")
    bossToggles.Sea2Hydra = Sea2FightSection:CreateToggle({
        Name = "🐍 Auto Hop & Săn Hydra & Rương Hydra (Sea 2)",
        Description = "Tự động tìm phòng có Rắn 3 đầu Hydra / Rương Hydra qua API và mở rương (Top 1)",
        CurrentValue = (hubState.fightSea2Hydra == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea3", BossCtl.sea3Keys, false) end
            hubState.fightSea2Hydra = on
            saveState(hubState)
            recalcHopMode(true, on and "sea2" or nil)
        end,
    }, "FightSea2HydraToggle")

    bossToggles.Sea2SeaKing = Sea2FightSection:CreateToggle({
        Name = "🐋 Auto Hop & Săn Sea King & Rương Vua Biển (Sea 2)",
        Description = "Tự động tìm phòng có Vua Biển Sea King / Rương Vua Biển qua API và mở rương (Top 2)",
        CurrentValue = (hubState.fightSea2SeaKing == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea3", BossCtl.sea3Keys, false) end
            hubState.fightSea2SeaKing = on
            saveState(hubState)
            recalcHopMode(true, on and "sea2" or nil)
        end,
    }, "FightSea2SeaKingToggle")

    bossToggles.Sea2GhostShip = Sea2FightSection:CreateToggle({
        Name = "👻 Auto Hop & Săn Thuyền Ma & Rương Thuyền Ma (Sea 2)",
        Description = "Tự động tìm phòng có Tàu Ma Ghost Ship qua API, bắn phá và nhặt rương rơi",
        CurrentValue = (hubState.fightSea2GhostShip == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea3", BossCtl.sea3Keys, false) end
            hubState.fightSea2GhostShip = on
            saveState(hubState)
            recalcHopMode(true, on and "sea2" or nil)
        end,
    }, "FightSea2GhostShipToggle")

    bossToggles.Sea2Serpent = Sea2FightSection:CreateToggle({
        Name = "🐍 Auto Hop & Săn Rắn Biển / Sea Serpent (Sea 2 & 3)",
        Description = "Tự động tìm phòng có Rắn Biển Serpent qua API và tiêu diệt",
        CurrentValue = (hubState.fightSea2Serpent == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            local on = (Value == true)
            if on then BossCtl.setGroup("Sea3", BossCtl.sea3Keys, false) end
            hubState.fightSea2Serpent = on
            saveState(hubState)
            recalcHopMode(true, on and "sea2" or nil)
        end,
    }, "FightSea2SerpentToggle")

    -- Đồng bộ chính xác chế độ Hop theo các công tắc Boss đang bật ngay khi khởi tạo
    recalcHopMode(false, (hubState.mode == "sea3" or hubState.mode == "sea2") and hubState.mode or nil)

    -- BẢNG 4: BẢNG RIÊNG 3 - SĂN BOSS TRÊN ĐẢO (ISLAND BOSSES)
    -- ========================================================
    local IslandFightSection = HopTab:CreateSection("🏝️ BẢNG RIÊNG 3: SĂN BOSS TRÊN ĐẢO (WORLD BOSSES)")
    local AutoFightIslandBossToggle = IslandFightSection:CreateToggle({
        Name = "⚔️ Bật Tự Động Săn Boss Đảo (Auto Farm Island Bosses)",
        Description = "Tự động bay đến hòn đảo có Boss mục tiêu, nhận quest và tiêu diệt",
        CurrentValue = (hubState.autoFightIslandBoss == true),
        Callback = function(Value: boolean)
            if syncingLocalToggles then return end
            local on = (Value == true)
            hubState.autoFightIslandBoss = on
            if on then
                deactivateOtherLocalModes("autoFightIslandBoss")
                if currentMode ~= "off" then
                    applyMode("off", false)
                end
            end
            saveState(hubState)
            if on then
                safeNotify("YokaHub Island Boss", "Đang tự động săn Boss đảo: " .. tostring(hubState.islandBossTarget or "Hephaestus"), "my_location")
            end
        end,
    }, "AutoFightIslandBossToggle")
    registerLocalModeToggle("autoFightIslandBoss", AutoFightIslandBossToggle)

    local function scanCurrentSeaBossOptions(): { string }
        local list: { string } = {}
        local seen: { [string]: boolean } = {}
        pcall(function()
            local mon = workspace:FindFirstChild("Monster")
            local bSub = mon and mon:FindFirstChild("Boss")
            if bSub then
                for _, b in ipairs(bSub:GetChildren()) do
                    if b and b:IsA("Model") and typeof(b.Name) == "string" and b.Name ~= "" and not seen[b.Name] then
                        seen[b.Name] = true
                        table.insert(list, b.Name)
                    end
                end
            end
        end)
        table.sort(list, function(a, b)
            local la = tonumber(string.match(a, "[Ll][Vv]%.?%s*(%d+)")) or 999999
            local lb = tonumber(string.match(b, "[Ll][Vv]%.?%s*(%d+)")) or 999999
            if la ~= lb then return la < lb end
            return a < b
        end)
        if #list == 0 then
            if game.PlaceId == SEA3_PLACE then
                list = {
                    "Hephaestus [Lv. 4025]",
                    "Dark Beard [Lv. 4250]",
                    "Gryphon [Lv. 4500]",
                    "Lucidus [Lv. 4750]",
                    "Ghost Ship Captain [Lv. 5000]",
                }
            elseif game.PlaceId == SEA2_PLACE then
                list = {
                    "Gazelle Man [Lv. 2350]",
                    "Kitsune Samurai [Lv. 2650]",
                    "Flame User [Lv. 3200]",
                    "Sunken Vessel [Lv. 3225]",
                    "Ryu [Lv. 3975]",
                }
            else
                list = {
                    "Smoky [Lv. 20]",
                    "Tashi [Lv. 30]",
                    "Shark Man [Lv. 230]",
                    "King Snow [Lv. 450]",
                    "Rumble Man [Lv. 950]",
                    "Leader [Lv. 1100]",
                    "Quake Woman [Lv. 1925]",
                }
            end
        end
        return list
    end

    local islandBossList = scanCurrentSeaBossOptions()
    local defaultIslandBoss = table.find(islandBossList, hubState.islandBossTarget) and hubState.islandBossTarget or islandBossList[1]
    BossCtl.islandReady = false
    local IslandBossDropdownObj = IslandFightSection:CreateDropdown({
        Name = "Chọn Boss Đảo Muốn Tiêu Diệt (Tự quét đúng Sea hiện tại)",
        Options = islandBossList,
        CurrentOption = { defaultIslandBoss },
        MultipleOptions = false,
        Callback = function(opt: any)
            local val = pickDropdownValue(opt)
            if val == "" then return end
            local changed = (hubState.islandBossTarget ~= val)
            hubState.islandBossTarget = val
            saveState(hubState)
            if BossCtl.islandReady and changed then
                safeNotify("Mục Tiêu Boss Đảo", "Đã chọn: " .. val, "flag")
            end
        end,
    }, "IslandBossDropdown")
    if (typeof(hubState.islandBossTarget) ~= "string" or hubState.islandBossTarget == "") and defaultIslandBoss then
        hubState.islandBossTarget = defaultIslandBoss
    end
    BossCtl.islandReady = true

    IslandFightSection:CreateButton({
        Name = "🔄 Tải Lại Danh Sách Boss Đảo Trong Sea Này",
        Description = "Quét lại toàn bộ Boss Đảo thực tế đang có mặt trong server hiện tại",
        Callback = function()
            local fresh = scanCurrentSeaBossOptions()
            if #fresh == 0 then
                safeNotify("Mục Tiêu Boss Đảo", "Chưa tìm thấy Boss Đảo nào trong Sea này!", "info")
                return
            end
            local keepTarget = (typeof(hubState.islandBossTarget) == "string" and table.find(fresh, hubState.islandBossTarget)) and hubState.islandBossTarget or fresh[1]
            BossCtl.islandReady = false
            pcall(function()
                if IslandBossDropdownObj and typeof(IslandBossDropdownObj.Set) == "function" then
                    IslandBossDropdownObj:Set({ Options = fresh, CurrentOption = { keepTarget } })
                end
            end)
            BossCtl.islandReady = true
            hubState.islandBossTarget = keepTarget
            saveState(hubState)
            safeNotify("Mục Tiêu Boss Đảo", "Đã cập nhật " .. tostring(#fresh) .. " Boss Đảo trong Sea hiện tại!", "refresh")
        end,
    })

    IslandFightSection:CreateToggle({
        Name = "📜 Tự Động Nhận Quest Boss Trước Khi Đánh",
        Description = "Tự bay qua NPC nhận nhiệm vụ trước khi đánh Boss để tối đa Beli và EXP",
        CurrentValue = (hubState.autoTakeBossQuest == true),
        Callback = function(Value: boolean)
            hubState.autoTakeBossQuest = (Value == true)
            saveState(hubState)
        end,
    }, "AutoTakeBossQuestToggle")

    local QuickHopSection = HopTab:CreateSection("🎯 Nhảy nhanh sang phòng khác")
    local snipeTarget = "Depth King (Sea 3)"
    QuickHopSection:CreateDropdown({
        Name = "Chọn Boss / Rương muốn tìm",
        Options = {
            "Depth King (Sea 3)",
            "Dragon (Sea 3)",
            "Sea Dragon / Abyssal (Sea 3)",
            "Kraken (Sea 3)",
            "Crab (Sea 3)",
            "Sea Serpent (Sea 2 & 3)",
            "Hydra Chest (Sea 2)",
            "Hydra (Sea 2)",
            "Sea King Chest (Sea 2)",
            "Sea King (Sea 2)",
            "Ghost Ship (Sea 2)",
        },
        CurrentOption = { "Depth King (Sea 3)" },
        MultipleOptions = false,
        Callback = function(opt: any)
            local val = pickDropdownValue(opt)
            if val ~= "" then snipeTarget = val end
        end,
    }, "SnipeTarget")

    local function matchSnipe(e: any, target: string, ignorePlayers: boolean?): boolean
        if typeof(e) ~= "table" or e.alive ~= true then return false end
        if isCurrentServerEntry(e) then return false end
        if e.isPrivate == true or e.private == true or string.lower(tostring(e.serverType or "")) == "private" then return false end
        local phase = string.lower(tostring(e.phase or e.status or e.state or ""))
        if phase == "inactive" or phase == "dead" or phase == "cooldown" or phase == "waiting" or phase == "none" then
            return false
        end
        if not ignorePlayers then
            local pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 99) or 99
            local pMax = typeof(e.players) == "table" and (tonumber(e.players.max) or 12) or 12
            if pCur >= pMax then return false end
        end
        if getEntryHpPercent(e) < 15 then return false end
        local pid = tonumber(e.placeId)
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))

        local isSeaDragon = (string.find(nm, "sea dragon", 1, true) ~= nil
            or string.find(nm, "sea_dragon", 1, true) ~= nil
            or string.find(nm, "seadragon", 1, true) ~= nil
            or src == "sea_dragon" or src == "seadragon")
        local isAbyssalMatch = (isSeaDragon
            or string.find(nm, "abyssal", 1, true) ~= nil
            or string.find(nm, "tyrant", 1, true) ~= nil
            or src == "abyssal" or src == "tyrant")
            and string.find(nm, "swordsman", 1, true) == nil
        local isDragonMatch = (string.find(nm, "drakenfyr", 1, true) ~= nil
            or string.find(nm, "inferno king", 1, true) ~= nil
            or (string.find(nm, "dragon", 1, true) ~= nil and string.find(nm, "fruit", 1, true) == nil and string.find(nm, "claw", 1, true) == nil and string.find(nm, "orb", 1, true) == nil and string.find(nm, "scale", 1, true) == nil)
            or src == "dragon" or src == "drakenfyr")
            and not isAbyssalMatch
            and string.find(nm, "depth", 1, true) == nil

        if target == "Dragon (Sea 3)" or target == "Drakenfyr the Inferno King / Dragon (Sea 3)" or target == "Rồng Biển / Dragon (Sea 3)" then
            return pid == SEA3_PLACE and isDragonMatch
        elseif target == "Sea Dragon / Abyssal (Sea 3)" or target == "Abyssal Tyrant (Sea 3)" then
            return pid == SEA3_PLACE and isAbyssalMatch
        elseif target == "Depth King (Sea 3)" then
            return pid == SEA3_PLACE and not isDragonMatch and not isAbyssalMatch and (src == "depth_king" or string.find(nm, "depth king", 1, true) ~= nil or nm == "depthking" or (string.find(nm, "depth", 1, true) ~= nil and string.find(nm, "king", 1, true) ~= nil))
        elseif target == "Kraken (Sea 3)" then
            return pid == SEA3_PLACE and (string.find(nm, "kraken", 1, true) ~= nil or string.find(nm, "tentacle", 1, true) ~= nil or src == "kraken") and string.find(nm, "galleon", 1, true) == nil
        elseif target == "Crab (Sea 3)" or target == "Cua Biển / Crab (Sea 3)" then
            return pid == SEA3_PLACE and (string.find(nm, "crab", 1, true) ~= nil or src == "crab")
        elseif target == "Hydra Chest (Sea 2)" or target == "Rương Hydra (Sea 2)" then
            return pid == SEA2_PLACE and (src == "sk_hd_chest" or string.find(nm, "chest", 1, true) ~= nil) and string.find(nm, "hydra", 1, true) ~= nil
        elseif target == "Hydra (Sea 2)" then
            return pid == SEA2_PLACE and (src == "hydra" or string.find(nm, "hydra", 1, true) ~= nil)
        elseif target == "Sea King Chest (Sea 2)" or target == "Rương Vua Biển (Sea 2)" then
            return pid == SEA2_PLACE and (src == "sk_hd_chest" or string.find(nm, "chest", 1, true) ~= nil) and (string.find(nm, "sea king", 1, true) ~= nil or string.find(nm, "seaking", 1, true) ~= nil)
        elseif target == "Sea King (Sea 2)" or target == "Vua Biển / Sea King (Sea 2)" then
            return pid == SEA2_PLACE and (src == "sea_king" or string.find(nm, "sea king", 1, true) ~= nil or string.find(nm, "seaking", 1, true) ~= nil)
        elseif target == "Ghost Ship (Sea 2)" or target == "Thuyền Ma / Ghost Ship (Sea 2)" then
            return pid == SEA2_PLACE and (src == "ghost_ship" or string.find(src, "ghost", 1, true) ~= nil or string.find(nm, "ghost", 1, true) ~= nil)
        elseif target == "Sea Serpent (Sea 2 & 3)" or target == "Rắn Biển / Serpent (Sea 2 & 3)" then
            local reqPid = (game.PlaceId == SEA2_PLACE) and SEA2_PLACE or SEA3_PLACE
            return pid == reqPid and (src == "serpent" or string.find(nm, "serpent", 1, true) ~= nil)
        end
        return false
    end

    QuickHopSection:CreateButton({
        Name = "🚀 Bay ngay vào 1 phòng có Boss đã chọn",
        Description = "Tự chọn phòng còn chỗ trống và Boss còn nhiều máu",
        Callback = function()
            if BossCtl.snipeBusy or BossCtl.randomBusy then
                safeNotify("YokaHub", "Đang chuyển phòng, vui lòng đợi vài giây...", "info")
                return
            end
            BossCtl.snipeBusy = true
            local targetSnap = snipeTarget
            task.spawn(function()
                local okTask, errTask = pcall(function()
                    local reqPlace: number? = nil
                    if string.find(targetSnap, "Serpent", 1, true) ~= nil then
                        reqPlace = (game.PlaceId == SEA2_PLACE) and SEA2_PLACE or SEA3_PLACE
                    elseif string.find(targetSnap, "Sea 2", 1, true) ~= nil and string.find(targetSnap, "Sea 3", 1, true) == nil then
                        reqPlace = SEA2_PLACE
                    elseif string.find(targetSnap, "Sea 3", 1, true) ~= nil and string.find(targetSnap, "Sea 2", 1, true) == nil then
                        reqPlace = SEA3_PLACE
                    end
                    if reqPlace and game.PlaceId ~= reqPlace then
                        local targetSeaName = (reqPlace == SEA2_PLACE and "Sea 2" or "Sea 3")
                        setStatus("Đang tự động chuyển sang " .. targetSeaName .. " để săn " .. targetSnap .. "...")
                        safeNotify("Khác Sea", "Đang chuyển sang " .. targetSeaName .. " trước khi săn " .. targetSnap .. "!", "flight_takeoff")
                        ensureCorrectSea(reqPlace, targetSnap, "Khác Sea", targetSnap)
                        return
                    end

                    if typeof(genv.WK_FetchLiveBossApiSnapshot) ~= "function" then
                        setStatus("Wukong Live Boss API chưa sẵn sàng, vui lòng đợi vài giây...")
                        safeNotify("YokaHub", "Wukong API chưa sẵn sàng, thử lại sau vài giây!", "info")
                        return
                    end

                    setStatus("Đang quét API tìm " .. targetSnap .. "...")
                    local ok, snap = false, nil
                    if typeof(genv.YokaFetchBossSnapshot) == "function" then
                        ok, snap = genv.YokaFetchBossSnapshot(5.5)
                    else
                        ok, snap = pcall(genv.WK_FetchLiveBossApiSnapshot)
                    end
                    if genv._YokaHubToken ~= myToken then return end
                    if not ok or typeof(snap) ~= "table" or typeof(snap.entries) ~= "table" then
                        setStatus("API Live Boss phản hồi chậm hoặc đang lỗi, vui lòng bấm lại sau vài giây.")
                        safeNotify("YokaHub", "API đang bận/quá thời gian, thử bấm lại sau vài giây!", "info")
                        return
                    end

                    local list = {}
                    local fullCount = 0
                    for _, e in ipairs(snap.entries) do
                        if typeof(e) == "table" then
                            if matchSnipe(e, targetSnap) then
                                e._tier = getSlotTier(e)
                                e._hp = getEntryHpPercent(e)
                                e._pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 99) or 99
                                table.insert(list, e)
                            elseif e.alive == true then
                                local pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 0) or 0
                                local pMax = typeof(e.players) == "table" and (tonumber(e.players.max) or 12) or 12
                                if pCur >= pMax and matchSnipe(e, targetSnap, true) then
                                    fullCount += 1
                                end
                            end
                        end
                    end

                    if #list == 0 then
                        local msg = fullCount > 0
                            and string.format("Có %d phòng %s nhưng đều đầy 12/12.", fullCount, targetSnap)
                            or ("Không tìm thấy phòng trống có " .. targetSnap .. " trên API.")
                        setStatus(msg)
                        safeNotify("YokaHub", msg .. " Vui lòng thử lại sau vài giây!", "info")
                        return
                    end
                    table.sort(list, function(a, b)
                        if a._tier ~= b._tier then return a._tier > b._tier end
                        local aCur = a._pCur or 99
                        local bCur = b._pCur or 99
                        if aCur ~= bCur then return aCur < bCur end
                        return a._hp > b._hp
                    end)
                    local tries = math.min(#list, 3)
                    for idx = 1, tries do
                        if genv._YokaHubToken ~= myToken then break end
                        local chosen = list[idx]
                        local pCurStr = typeof(chosen.players) == "table" and tostring(chosen.players.current or "?") or "?"
                        local pMaxStr = typeof(chosen.players) == "table" and tostring(chosen.players.max or "?") or "?"
                        local info = string.format("%s (%s/%s người · %s%% HP)", tostring(chosen.eventName or targetSnap), pCurStr, pMaxStr, tostring(math.floor(tonumber(chosen._hp) or 0)))
                        setStatus("Đang bay vào: " .. info)
                        if idx == 1 then recordHop() end
                        armAutoReexec(false)
                        local hopStart = os.clock()
                        local dispatched = false
                        if typeof(genv.WK_JoinLiveBossApiEntry) == "function" then
                            local okJ, resJ = pcall(genv.WK_JoinLiveBossApiEntry, chosen)
                            dispatched = okJ and (resJ ~= false)
                        end
                        if not dispatched then
                            local srvId = chosen.jobId or chosen.serverId or chosen.serverRef or chosen.id
                            local pId = tonumber(chosen.placeId) or reqPlace or game.PlaceId
                            if typeof(srvId) == "string" and srvId ~= "" and srvId ~= game.JobId and string.find(srvId, "-", 1, true) ~= nil then
                                local okTp = pcall(function() teleportService:TeleportToPlaceInstance(pId, srvId, players.LocalPlayer) end)
                                dispatched = okTp
                            end
                        end
                        if not dispatched then
                            if idx < tries then
                                setStatus("Không thể vào phòng này, thử phòng tiếp theo...")
                                task.wait(0.3)
                            else
                                setStatus("Không thể điều hướng tới phòng đã chọn, vui lòng thử lại.")
                            end
                            continue
                        end
                        safeNotify("Đang bay tới", info, "public")
                        local failed = false
                        local w = 0
                        while w < 3.8 do
                            task.wait(0.15); w += 0.15
                            if genv._YokaHubToken ~= myToken then return end
                            if (tonumber(genv._LastTeleportFailClock) or 0) >= hopStart then
                                failed = true
                                if idx < tries then
                                    setStatus("Phòng vừa đầy, đổi ngay phòng tiếp theo...")
                                    task.wait(0.5)
                                else
                                    setStatus("Các phòng thử đều vừa đầy, thử bấm lại sau vài giây.")
                                end
                                break
                            end
                        end
                        if not failed then
                            task.wait(8.0)
                            break
                        end
                    end
                end)
                BossCtl.snipeBusy = false
                if not okTask then
                    warn("[YokaHub][Tab1] Lỗi Bay Ngay:", tostring(errTask))
                    setStatus("Có lỗi khi tìm phòng nhanh, vui lòng thử lại.", true)
                    safeNotify("YokaHub", "Lỗi tìm phòng nhanh, thử lại sau vài giây!", "info")
                end
            end)
        end,
    })

    QuickHopSection:CreateButton({
        Name = "🔄 Sang phòng mới ít người (để Random Trái)",
        Description = "Chuyển nhanh sang phòng thoáng 3–8 người để random trái hoặc nghỉ farm",
        Callback = function()
            if BossCtl.randomBusy or BossCtl.snipeBusy then
                safeNotify("YokaHub", "Đang chuyển phòng, vui lòng đợi vài giây...", "info")
                return
            end
            BossCtl.randomBusy = true
            task.spawn(function()
                local okRand, errRand = pcall(function()
                    if currentMode ~= "off" then
                        applyMode("off", false)
                    end
                    setStatus("Đang tìm phòng ít người (3–8 người)...")
                    local chosenId: string? = nil
                    local chosenInfo = ""

                    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
                    local raw: string? = nil
                    local reqFn = (genv.syn and genv.syn.request) or (genv.http and genv.http.request) or genv.http_request or genv.request
                    if typeof(reqFn) == "function" then
                        local okReq, resReq = pcall(reqFn, { Url = url, Method = "GET" })
                        if okReq and typeof(resReq) == "table" and tonumber(resReq.StatusCode) == 200 and typeof(resReq.Body) == "string" then
                            raw = resReq.Body
                        end
                    end
                    if not raw or raw == "" then
                        local okGet, bodyGet = pcall(function() return game:HttpGet(url) end)
                        if okGet and typeof(bodyGet) == "string" then
                            raw = bodyGet
                        end
                    end
                    if genv._YokaHubToken ~= myToken then return end

                    if typeof(raw) == "string" and raw ~= "" then
                        local dok, decoded = pcall(function() return httpService:JSONDecode(raw) end)
                        if dok and typeof(decoded) == "table" and typeof(decoded.data) == "table" then
                            local pref, fb = {}, {}
                            for _, srv in ipairs(decoded.data) do
                                if typeof(srv) == "table" then
                                    local id = tostring(srv.id or "")
                                    local p, m = tonumber(srv.playing) or 99, tonumber(srv.maxPlayers) or 12
                                    if id ~= "" and id ~= game.JobId and p < m then
                                        table.insert(fb, srv)
                                        if p >= 3 and p <= 8 then table.insert(pref, srv) end
                                    end
                                end
                            end
                            local pool = #pref > 0 and pref or fb
                            if #pool > 0 then
                                local chosen = pool[math.random(1, math.min(#pool, 10))]
                                chosenId = tostring(chosen.id)
                                chosenInfo = string.format("Sang phòng %d/%d người...", tonumber(chosen.playing) or 0, tonumber(chosen.maxPlayers) or 12)
                            end
                        end
                    end

                    if genv._YokaHubToken ~= myToken then return end
                    recordHop()
                    armAutoReexec(false)
                    if chosenId and chosenId ~= "" and chosenId ~= game.JobId then
                        setStatus(chosenInfo)
                        safeNotify("Đang chuyển phòng", chosenInfo, "public")
                        local okTp = pcall(function() teleportService:TeleportToPlaceInstance(game.PlaceId, chosenId :: string, players.LocalPlayer) end)
                        if okTp then
                            task.wait(8.0)
                            return
                        end
                    end
                    setStatus("Đang chuyển sang phòng mới...")
                    safeNotify("Đang chuyển phòng", "Đang chuyển sang phòng công khai mới...", "public")
                    if teleportToSea then
                        teleportToSea(game.PlaceId)
                    else
                        pcall(function() teleportService:Teleport(game.PlaceId, players.LocalPlayer) end)
                    end
                    task.wait(8.0)
                end)
                BossCtl.randomBusy = false
                if not okRand then
                    warn("[YokaHub][Tab1] Lỗi đổi phòng ít người:", tostring(errRand))
                    setStatus("Chuyển phòng chưa thành công, vui lòng thử lại.", true)
                end
            end)
        end,
    })

