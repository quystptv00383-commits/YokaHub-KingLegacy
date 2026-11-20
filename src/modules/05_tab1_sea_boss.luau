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

    local function getSea3Prio(e: any): number
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))

        -- Top 1: Depth King (Sea 3) - Ưu tiên cao nhất (10 điểm)
        if (src == "depth_king" or string.find(nm, "depth king", 1, true) ~= nil or nm == "depthking" or (string.find(nm, "depth", 1, true) ~= nil and string.find(nm, "king", 1, true) ~= nil)) and string.find(nm, "abyssal", 1, true) == nil then
            if hubState.fightSea3DepthKing == false then return 0 end
            return 10
        end

        -- Top 2: Drakenfyr the Inferno King / Dragon / Sea Dragon (Sea 3) - Ưu tiên số 2 (8 điểm)
        local isDragonMatch = (src == "sea_event" and (string.find(nm, "dragon", 1, true) ~= nil or string.find(nm, "drakenfyr", 1, true) ~= nil))
            or string.find(nm, "drakenfyr", 1, true) ~= nil
            or string.find(nm, "inferno king", 1, true) ~= nil
            or string.find(nm, "sea dragon", 1, true) ~= nil
            or (string.find(nm, "dragon", 1, true) ~= nil and string.find(nm, "fruit", 1, true) == nil and string.find(nm, "claw", 1, true) == nil and string.find(nm, "orb", 1, true) == nil)
        local notDragonOther = string.find(nm, "abyssal", 1, true) == nil
            and string.find(nm, "tyrant", 1, true) == nil
            and string.find(nm, "depth", 1, true) == nil
            and string.find(src, "abyssal", 1, true) == nil
            and string.find(src, "depth", 1, true) == nil
        if isDragonMatch and notDragonOther then
            if hubState.fightSea3Dragon == false then return 0 end
            return 8
        end

        -- Top 3: Abyssal Tyrant (Sea 3) - Ưu tiên số 3 (6 điểm)
        local isAbyssalMatch = (src == "abyssal" or src == "tyrant" or string.find(src, "abyssal", 1, true) ~= nil or string.find(src, "tyrant", 1, true) ~= nil)
            or string.find(nm, "abyssal", 1, true) ~= nil
            or string.find(nm, "tyrant", 1, true) ~= nil
        local notAbyssalOther = string.find(nm, "depth", 1, true) == nil
            and string.find(nm, "swordsman", 1, true) == nil
            and string.find(nm, "dragon", 1, true) == nil
            and string.find(src, "depth", 1, true) == nil
        if isAbyssalMatch and notAbyssalOther then
            if hubState.fightSea3Abyssal == false then return 0 end
            return 6
        end

        -- Top 4: Kraken & Xúc Tu (Sea 3) - Ưu tiên số 4 (4 điểm)
        if src == "sea_event" and (string.find(nm, "kraken", 1, true) ~= nil or string.find(nm, "tentacle", 1, true) ~= nil) then
            if hubState.fightSea3Kraken == false then return 0 end
            return 4
        end

        -- Top 5: Cua Biển Khổng Lồ (Giant Crab Sea 3) - Ưu tiên số 5 (3 điểm)
        if string.find(nm, "crab", 1, true) ~= nil then
            if hubState.fightSea3Crab == false then return 0 end
            return 3
        end

        -- Top 6: Rắn Biển / Serpent (Sea 3 & 2) - Ưu tiên số 6 (2 điểm)
        if src == "serpent" or string.find(nm, "serpent", 1, true) ~= nil then
            if hubState.fightSea2Serpent == false then return 0 end
            return 2
        end

        -- Tuyệt đối không để Depth King, Dragon hoặc Abyssal bị người dùng tắt mà lại lọt qua Top 7
        local isDkRoom = (src == "depth_king" or string.find(nm, "depth", 1, true) ~= nil)
        local isAbRoom = (string.find(nm, "abyssal", 1, true) ~= nil or string.find(nm, "tyrant", 1, true) ~= nil)
        local isDgRoom = (string.find(nm, "drakenfyr", 1, true) ~= nil or string.find(nm, "inferno king", 1, true) ~= nil or string.find(nm, "sea dragon", 1, true) ~= nil or (src == "sea_event" and string.find(nm, "dragon", 1, true) ~= nil))
        if isDkRoom and hubState.fightSea3DepthKing == false then return 0 end
        if isAbRoom and hubState.fightSea3Abyssal == false then return 0 end
        if isDgRoom and hubState.fightSea3Dragon == false then return 0 end

        -- Top 7: Sea Events Thường & Tàu Galleon Boss (1 điểm - CHỈ khi người dùng bật toggle Sea Event Thường)
        if src == "sea_event" or src == "ship_ability" or string.find(nm, "sea beast", 1, true) ~= nil or string.find(nm, "galleon", 1, true) ~= nil then
            if hubState.fightSea3Events ~= true then return 0 end
            return 1
        end

        return 0
    end

    local function getSea2Prio(e: any): number
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))
        if (src == "sk_hd_chest" and string.find(nm, "hydra", 1, true) ~= nil) or src == "hydra" or string.find(nm, "hydra", 1, true) ~= nil then
            if hubState.fightSea2Hydra == false then return 0 end
            return src == "sk_hd_chest" and 7 or 6
        end
        if (src == "sk_hd_chest" and (string.find(nm, "sea king", 1, true) ~= nil or string.find(nm, "seaking", 1, true) ~= nil)) or src == "sea_king" or string.find(nm, "sea king", 1, true) ~= nil or string.find(nm, "seaking", 1, true) ~= nil then
            if hubState.fightSea2SeaKing == false then return 0 end
            return src == "sk_hd_chest" and 5 or 4
        end
        if src == "serpent" or string.find(nm, "serpent", 1, true) ~= nil then
            if hubState.fightSea2Serpent == false then return 0 end
            return 3
        end
        if string.find(src, "ghost", 1, true) ~= nil or string.find(nm, "ghost", 1, true) ~= nil then
            if hubState.fightSea2GhostShip == false then return 0 end
            return string.find(nm, "chest", 1, true) ~= nil and 2 or 1
        end
        return 0
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

    local function getActiveBossSummary(): (string, string)
        if currentMode == "sea3" then
            local names: { string } = {}
            if hubState.fightSea3DepthKing then table.insert(names, "Depth King") end
            if hubState.fightSea3Dragon then table.insert(names, "Drakenfyr") end
            if hubState.fightSea3Abyssal then table.insert(names, "Abyssal") end
            if hubState.fightSea3Kraken then table.insert(names, "Kraken") end
            if hubState.fightSea3Crab then table.insert(names, "Cua") end
            if hubState.fightSea3Events then table.insert(names, "Sea Events") end
            if #names == 6 then
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

    local function applyMode(newMode: string, notifyUser: boolean)
        -- Khử xung đột: Khi chuyển sang Săn Boss, tự động bật Master Auto Fight và tắt các chế độ cày cục bộ
        if newMode ~= "off" then
            hubState.autoFightMaster = true
            local hadConflict = hubState.autoLevel or hubState.autoKillSelectedMob or hubState.farmSea3Mat or hubState.farmSea2Mat or hubState.farmSea1Mat or hubState.autoDungeon or hubState.autoFish or hubState.autoFightIslandBoss
            deactivateOtherLocalModes("none")
            if hadConflict then
                safeNotify("YokaHub", "Đã ưu tiên Săn Boss Biển (Tạm dừng các chế độ cày quái/câu cá/dungeon).", "info")
            end
        end
        currentMode = newMode
        hubState.mode = newMode
        genv._KingAutoHopMode = newMode
        genv._AutoSeaEventApiHop = (newMode == "sea3")
        genv._AutoSea2PriorityApiHop = (newMode == "sea2")
        genv._AutoDepthKingOnlyApiHop = (newMode == "sea3" and hubState.fightSea3DepthKing == true and not hubState.fightSea3Dragon and not hubState.fightSea3Abyssal and not hubState.fightSea3Kraken and not hubState.fightSea3Crab and not hubState.fightSea3Events)
        saveState(hubState)
        updateDockDot()
        if newMode ~= "off" then
            armAutoReexec(false)
        end

        if MasterAutoFightToggle and typeof(MasterAutoFightToggle.Set) == "function" then
            pcall(function() MasterAutoFightToggle:Set({ CurrentValue = hubState.autoFightMaster }) end)
        end

        if newMode == "sea3" then
            local preferSea3Boss = (hubState.fightSea3DepthKing and "depth")
                or (hubState.fightSea3Dragon and "dragon")
                or (hubState.fightSea3Abyssal and "abyssal")
                or (hubState.fightSea3Kraken and "kraken")
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
            if not ensureCorrectSea(SEA2_PLACE, "Boss Sea 2", "Săn Boss", "hydra") then
                setStatus("Đang tự động chuyển sang Sea 2 để săn Boss & Rương...", true)
                return
            end
            local summary, _ = getActiveBossSummary()
            setStatus("Đang tìm phòng có Boss / Rương ở Sea 2 (" .. summary .. ")...", true)
            if notifyUser then
                safeNotify("YokaHub", "Đã bật Auto Hop: " .. summary, "public")
            end
        else
            -- Tat toan bo co tu dong hop cua Wukong de khong bi nhay phong ngam khi da tat YokaHub
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

    local function recalcHopMode(notifyUser: boolean)
        local anySea3 = (hubState.fightSea3DepthKing == true)
            or (hubState.fightSea3Dragon == true)
            or (hubState.fightSea3Abyssal == true)
            or (hubState.fightSea3Kraken == true)
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
            and (hubState.fightSea3Crab == true)
            and (hubState.fightSea3Events == true)

        local allSea2 = (hubState.fightSea2Hydra == true)
            and (hubState.fightSea2SeaKing == true)
            and (hubState.fightSea2GhostShip == true)
            and (hubState.fightSea2Serpent == true)

        local newMode = "off"
        if anySea3 and anySea2 then
            newMode = (game.PlaceId == SEA2_PLACE) and "sea2" or "sea3"
        elseif anySea3 then
            newMode = "sea3"
        elseif anySea2 then
            newMode = "sea2"
        else
            newMode = "off"
        end

        applyMode(newMode, notifyUser)

        syncingBossToggles = true
        if Sea3Toggle and typeof(Sea3Toggle.Set) == "function" then
            pcall(function() Sea3Toggle:Set({ CurrentValue = allSea3 }) end)
        end
        if Sea2Toggle and typeof(Sea2Toggle.Set) == "function" then
            pcall(function() Sea2Toggle:Set({ CurrentValue = allSea2 }) end)
        end
        syncingBossToggles = false
    end

    genv.SetKingAutoHopMode = function(m: string) applyMode(m, false) end
    genv.SetAutoDepthKingHopEnabled = function(on: boolean)
        syncingBossToggles = true
        hubState.fightSea3DepthKing = on
        if on then
            hubState.fightSea3Dragon = false
            hubState.fightSea3Abyssal = false
            hubState.fightSea3Kraken = false
            hubState.fightSea3Crab = false
            hubState.fightSea3Events = false
        end
        for k, tog in pairs(bossToggles) do
            if string.sub(k, 1, 4) == "Sea3" and tog and typeof(tog.Set) == "function" then
                pcall(function() tog:Set({ CurrentValue = (k == "Sea3DepthKing" and on or false) }) end)
            end
        end
        syncingBossToggles = false
        recalcHopMode(false)
    end
    genv.SetAutoHopEnabled = function(on: boolean)
        syncingBossToggles = true
        hubState.fightSea3DepthKing = on
        hubState.fightSea3Dragon = on
        hubState.fightSea3Abyssal = on
        hubState.fightSea3Kraken = on
        hubState.fightSea3Crab = on
        hubState.fightSea3Events = on
        for k, tog in pairs(bossToggles) do
            if string.sub(k, 1, 4) == "Sea3" and tog and typeof(tog.Set) == "function" then
                pcall(function() tog:Set({ CurrentValue = on }) end)
            end
        end
        syncingBossToggles = false
        recalcHopMode(false)
    end
    genv.SetAutoSea2HopEnabled = function(on: boolean)
        syncingBossToggles = true
        hubState.fightSea2Hydra = on
        hubState.fightSea2SeaKing = on
        hubState.fightSea2GhostShip = on
        hubState.fightSea2Serpent = on
        for k, tog in pairs(bossToggles) do
            if string.sub(k, 1, 4) == "Sea2" and tog and typeof(tog.Set) == "function" then
                pcall(function() tog:Set({ CurrentValue = on }) end)
            end
        end
        syncingBossToggles = false
        recalcHopMode(false)
    end

    Sea3Toggle = StatusSection:CreateToggle({
        Name = "🐉 Bật / Tắt toàn bộ Boss Sea 3 (Phím F8)",
        Description = "Ưu tiên: Depth King (Top 1) → Drakenfyr (Top 2) → Abyssal (Top 3) → Kraken → Cua → Events",
        CurrentValue = (hubState.mode == "sea3" and hubState.fightSea3DepthKing and hubState.fightSea3Dragon and hubState.fightSea3Abyssal and hubState.fightSea3Kraken and hubState.fightSea3Crab and hubState.fightSea3Events),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            syncingBossToggles = true
            hubState.fightSea3DepthKing = Value
            hubState.fightSea3Dragon = Value
            hubState.fightSea3Abyssal = Value
            hubState.fightSea3Kraken = Value
            hubState.fightSea3Crab = Value
            hubState.fightSea3Events = Value
            for k, tog in pairs(bossToggles) do
                if string.sub(k, 1, 4) == "Sea3" and tog and typeof(tog.Set) == "function" then
                    pcall(function() tog:Set({ CurrentValue = Value }) end)
                end
            end
            syncingBossToggles = false
            recalcHopMode(true)
        end,
    }, "AutoHopSea3")

    Sea2Toggle = StatusSection:CreateToggle({
        Name = "🐍 Bật / Tắt toàn bộ Boss Sea 2 (Phím F9)",
        Description = "Ưu tiên: Rương Hydra → Hydra → Sea King → Serpent → Tàu Ma",
        CurrentValue = (hubState.mode == "sea2" and hubState.fightSea2Hydra and hubState.fightSea2SeaKing and hubState.fightSea2GhostShip and hubState.fightSea2Serpent),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            syncingBossToggles = true
            hubState.fightSea2Hydra = Value
            hubState.fightSea2SeaKing = Value
            hubState.fightSea2GhostShip = Value
            hubState.fightSea2Serpent = Value
            for k, tog in pairs(bossToggles) do
                if string.sub(k, 1, 4) == "Sea2" and tog and typeof(tog.Set) == "function" then
                    pcall(function() tog:Set({ CurrentValue = Value }) end)
                end
            end
            syncingBossToggles = false
            recalcHopMode(true)
        end,
    }, "AutoHopSea2")

    StatusSection:CreateButton({
        Name = "⛔ Dừng toàn bộ Auto Hop (Đứng yên tại phòng)",
        Description = "Tắt tức thì mọi chế độ nhảy phòng và dừng săn Boss",
        Callback = function()
            syncingBossToggles = true
            hubState.fightSea3DepthKing = false
            hubState.fightSea3Dragon = false
            hubState.fightSea3Abyssal = false
            hubState.fightSea3Kraken = false
            hubState.fightSea3Crab = false
            hubState.fightSea3Events = false
            hubState.fightSea2Hydra = false
            hubState.fightSea2SeaKing = false
            hubState.fightSea2GhostShip = false
            hubState.fightSea2Serpent = false
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
            syncingBossToggles = false
            applyMode("off", true)
        end,
    })

    trackConn(userInputService.InputBegan:Connect(function(input: InputObject, gp: boolean)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F8 then
            local targetVal = (currentMode ~= "sea3")
            if Sea3Toggle and typeof(Sea3Toggle.Set) == "function" then
                Sea3Toggle:Set({ CurrentValue = targetVal })
            else
                applyMode(targetVal and "sea3" or "off", true)
            end
        elseif input.KeyCode == Enum.KeyCode.F9 then
            local targetVal = (currentMode ~= "sea2")
            if Sea2Toggle and typeof(Sea2Toggle.Set) == "function" then
                Sea2Toggle:Set({ CurrentValue = targetVal })
            else
                applyMode(targetVal and "sea2" or "off", true)
            end
        end
    end))

    -- ========================================================
    -- BẢNG 1: CÀI ĐẶT CHIẾN ĐẤU BOSS & NHẶT RƯƠNG
    -- ========================================================
    local MasterFightSection = HopTab:CreateSection("🌟 CÀI ĐẶT CHIẾN ĐẤU BOSS & NHẶT RƯƠNG")
    MasterAutoFightToggle = MasterFightSection:CreateToggle({
        Name = "⚔️ Tự Động Đánh Boss & Sea Event Khi Thấy (Master Auto Fight)",
        Description = "Tự động bay đến, né chiêu trên không và tiêu diệt bất kỳ Boss biển nào xuất hiện trong phòng",
        CurrentValue = hubState.autoFightMaster,
        Callback = function(Value: boolean)
            hubState.autoFightMaster = Value
            saveState(hubState)
            if Value then
                safeNotify("YokaHub Boss", "Đã bật Master Auto Fight Boss & Sea Event!", "flash_on")
            else
                safeNotify("YokaHub Boss", "Đã tắt Auto Fight Boss.", "info")
            end
        end,
    }, "MasterAutoFightToggle")

    MasterFightSection:CreateToggle({
        Name = "🎁 Tự Động Nhặt Rương Báu Sau Khi Diệt Boss (Auto Collect Chests)",
        Description = "Tự động bay đến vị trí rương rơi ra mở rương nhận thưởng (Rương Vua Biển, Hydra, Depth King...)",
        CurrentValue = hubState.autoCollectChest,
        Callback = function(Value: boolean)
            hubState.autoCollectChest = Value
            saveState(hubState)
        end,
    }, "AutoCollectChestToggle")

    MasterFightSection:CreateSlider({
        Name = "🕊️ Độ Cao Bay An Toàn Khi Đánh Boss",
        Range = { 10, 40 },
        Increment = 1,
        Suffix = "studs",
        CurrentValue = hubState.bossSafeHeight or 18,
        Callback = function(Value: number)
            hubState.bossSafeHeight = Value
            saveState(hubState)
        end,
    }, "BossSafeHeightSlider")

    -- ========================================================
    -- BẢNG 2: TỰ ĐỘNG HOP & SĂN BOSS SEA 3 (TỪNG CON RIÊNG BIỆT)
    -- ========================================================
    local Sea3FightSection = HopTab:CreateSection("👑 TỰ ĐỘNG HOP & SĂN BOSS SEA 3 (API TỪNG CON)")
    bossToggles.Sea3DepthKing = Sea3FightSection:CreateToggle({
        Name = "👑 Auto Hop & Săn Depth King (Sea 3)",
        Description = "Tự động tìm phòng có Vua Vực Thẳm Depth King qua API, bay tới diệt và mở rương (Top 1)",
        CurrentValue = (hubState.mode == "sea3" and hubState.fightSea3DepthKing == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea3DepthKing = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea3DepthKingToggle")

    bossToggles.Sea3Dragon = Sea3FightSection:CreateToggle({
        Name = "🐲 Auto Hop & Săn Drakenfyr / Dragon (Sea 3)",
        Description = "Tự động tìm phòng có Rồng Lửa Drakenfyr / Sea Dragon qua API và tiêu diệt (Top 2)",
        CurrentValue = (hubState.mode == "sea3" and hubState.fightSea3Dragon == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea3Dragon = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea3DragonToggle")

    bossToggles.Sea3Abyssal = Sea3FightSection:CreateToggle({
        Name = "👑 Auto Hop & Săn Abyssal Tyrant (Sea 3)",
        Description = "Tự động tìm phòng có Bạo Chúa Abyssal Tyrant qua API và tiêu diệt (Top 3)",
        CurrentValue = (hubState.mode == "sea3" and hubState.fightSea3Abyssal == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea3Abyssal = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea3AbyssalToggle")

    bossToggles.Sea3Kraken = Sea3FightSection:CreateToggle({
        Name = "🐙 Auto Hop & Săn Kraken & Xúc Tu (Sea 3)",
        Description = "Tự động tìm phòng có Kraken qua API, chặt xúc tu và diệt thân quái (Top 4)",
        CurrentValue = (hubState.mode == "sea3" and hubState.fightSea3Kraken == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea3Kraken = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea3KrakenToggle")

    bossToggles.Sea3Crab = Sea3FightSection:CreateToggle({
        Name = "🦀 Auto Hop & Săn Cua Biển Khổng Lồ (Sea 3)",
        Description = "Tự động tìm phòng có Cua Biển khổng lồ Sea 3 qua API và tiêu diệt (Top 5)",
        CurrentValue = (hubState.mode == "sea3" and hubState.fightSea3Crab == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea3Crab = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea3CrabToggle")

    bossToggles.Sea3Events = Sea3FightSection:CreateToggle({
        Name = "🌊 Auto Hop & Săn Sea Event Thường (Sea 3)",
        Description = "Tự động tìm phòng có sự kiện biển vừa và nhỏ (Galleon, Sea Beast...)",
        CurrentValue = (hubState.mode == "sea3" and hubState.fightSea3Events == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea3Events = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea3EventsToggle")

    -- ========================================================
    -- BẢNG 3: TỰ ĐỘNG HOP & SĂN BOSS SEA 2 (TỪNG CON RIÊNG BIỆT)
    -- ========================================================
    local Sea2FightSection = HopTab:CreateSection("🐋 TỰ ĐỘNG HOP & SĂN BOSS SEA 2 (API TỪNG CON)")
    bossToggles.Sea2Hydra = Sea2FightSection:CreateToggle({
        Name = "🐍 Auto Hop & Săn Hydra & Rương Hydra (Sea 2)",
        Description = "Tự động tìm phòng có Rắn 3 đầu Hydra / Rương Hydra qua API và mở rương (Top 1)",
        CurrentValue = (hubState.mode == "sea2" and hubState.fightSea2Hydra == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea2Hydra = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea2HydraToggle")

    bossToggles.Sea2SeaKing = Sea2FightSection:CreateToggle({
        Name = "🐋 Auto Hop & Săn Sea King & Rương Vua Biển (Sea 2)",
        Description = "Tự động tìm phòng có Vua Biển Sea King / Rương Vua Biển qua API và mở rương (Top 2)",
        CurrentValue = (hubState.mode == "sea2" and hubState.fightSea2SeaKing == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea2SeaKing = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea2SeaKingToggle")

    bossToggles.Sea2GhostShip = Sea2FightSection:CreateToggle({
        Name = "👻 Auto Hop & Săn Thuyền Ma & Rương Thuyền Ma (Sea 2)",
        Description = "Tự động tìm phòng có Tàu Ma Ghost Ship qua API, bắn phá và nhặt rương rơi",
        CurrentValue = (hubState.mode == "sea2" and hubState.fightSea2GhostShip == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea2GhostShip = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea2GhostShipToggle")

    bossToggles.Sea2Serpent = Sea2FightSection:CreateToggle({
        Name = "🐍 Auto Hop & Săn Rắn Biển / Sea Serpent (Sea 2 & 3)",
        Description = "Tự động tìm phòng có Rắn Biển Serpent qua API và tiêu diệt",
        CurrentValue = ((hubState.mode == "sea2" or hubState.mode == "sea3") and hubState.fightSea2Serpent == true),
        Callback = function(Value: boolean)
            if syncingBossToggles then return end
            hubState.fightSea2Serpent = Value
            saveState(hubState)
            recalcHopMode(true)
        end,
    }, "FightSea2SerpentToggle")
    -- BẢNG 4: BẢNG RIÊNG 3 - SĂN BOSS TRÊN ĐẢO (ISLAND BOSSES)
    -- ========================================================
    local IslandFightSection = HopTab:CreateSection("🏝️ BẢNG RIÊNG 3: SĂN BOSS TRÊN ĐẢO (WORLD BOSSES)")
    local AutoFightIslandBossToggle = IslandFightSection:CreateToggle({
        Name = "⚔️ Bật Tự Động Săn Boss Đảo (Auto Farm Island Bosses)",
        Description = "Tự động bay đến hòn đảo có Boss mục tiêu, nhận quest và tiêu diệt",
        CurrentValue = hubState.autoFightIslandBoss,
        Callback = function(Value: boolean)
            if syncingLocalToggles then return end
            hubState.autoFightIslandBoss = Value
            if Value then
                deactivateOtherLocalModes("autoFightIslandBoss")
                if currentMode ~= "off" then
                    applyMode("off", false)
                end
            end
            saveState(hubState)
            if Value then
                safeNotify("YokaHub Island Boss", "Đang tự động săn Boss đảo: " .. tostring(hubState.islandBossTarget or "Hephaestus"), "my_location")
            end
        end,
    }, "AutoFightIslandBossToggle")
    registerLocalModeToggle("autoFightIslandBoss", AutoFightIslandBossToggle)

    local function scanCurrentSeaBossOptions(): { string }
        local list: { string } = {}
        local seen: { [string]: boolean } = {}
        local mon = workspace:FindFirstChild("Monster")
        local bSub = mon and mon:FindFirstChild("Boss")
        if bSub then
            for _, b in ipairs(bSub:GetChildren()) do
                if b:IsA("Model") and not seen[b.Name] then
                    seen[b.Name] = true
                    table.insert(list, b.Name)
                end
            end
        end
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
    local IslandBossDropdownObj = IslandFightSection:CreateDropdown({
        Name = "Chọn Boss Đảo Muốn Tiêu Diệt (Tự quét đúng Sea hiện tại)",
        Options = islandBossList,
        CurrentOption = { defaultIslandBoss },
        MultipleOptions = false,
        Callback = function(opt: any)
            local val = pickDropdownValue(opt)
            hubState.islandBossTarget = val
            saveState(hubState)
            safeNotify("Mục Tiêu Boss Đảo", "Đã chọn: " .. val, "flag")
        end,
    }, "IslandBossDropdown")

    IslandFightSection:CreateButton({
        Name = "🔄 Tải Lại Danh Sách Boss Đảo Trong Sea Này",
        Description = "Quét lại toàn bộ Boss Đảo thực tế đang có mặt trong server hiện tại",
        Callback = function()
            local fresh = scanCurrentSeaBossOptions()
            pcall(function()
                if IslandBossDropdownObj and typeof(IslandBossDropdownObj.Set) == "function" then
                    IslandBossDropdownObj:Set({ Options = fresh, CurrentOption = { fresh[1] } })
                end
            end)
            hubState.islandBossTarget = fresh[1]
            saveState(hubState)
            safeNotify("Mục Tiêu Boss Đảo", "Đã cập nhật " .. tostring(#fresh) .. " Boss Đảo trong Sea hiện tại!", "refresh")
        end,
    })

    IslandFightSection:CreateToggle({
        Name = "📜 Tự Động Nhận Quest Boss Trước Khi Đánh",
        Description = "Tự bay qua NPC nhận nhiệm vụ trước khi đánh Boss để tối đa Beli và EXP",
        CurrentValue = hubState.autoTakeBossQuest,
        Callback = function(Value: boolean)
            hubState.autoTakeBossQuest = Value
            saveState(hubState)
        end,
    }, "AutoTakeBossQuestToggle")

    local QuickHopSection = HopTab:CreateSection("🎯 Nhảy nhanh sang phòng khác")
    local snipeTarget = "Depth King (Sea 3)"
    QuickHopSection:CreateDropdown({
        Name = "Chọn Boss / Rương muốn tìm",
        Options = {
            "Depth King (Sea 3)",
            "Drakenfyr the Inferno King / Dragon (Sea 3)",
            "Abyssal Tyrant (Sea 3)",
            "Kraken (Sea 3)",
            "Cua Biển / Crab (Sea 3)",
            "Rương Hydra (Sea 2)",
            "Hydra (Sea 2)",
            "Rương Vua Biển (Sea 2)",
            "Vua Biển / Sea King (Sea 2)",
            "Thuyền Ma / Ghost Ship (Sea 2)",
            "Rắn Biển / Serpent (Sea 2 & 3)",
        },
        CurrentOption = { "Depth King (Sea 3)" },
        MultipleOptions = false,
        Callback = function(opt: any) snipeTarget = pickDropdownValue(opt) end,
    }, "SnipeTarget")

    local function matchSnipe(e: any, target: string, ignorePlayers: boolean?): boolean
        if e.alive ~= true then return false end
        if not ignorePlayers then
            local pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 99) or 99
            local pMax = typeof(e.players) == "table" and (tonumber(e.players.max) or 12) or 12
            if pCur >= pMax then return false end
        end
        if typeof(e.health) == "table" and (tonumber(e.health.percent) or 0) < 15 then return false end
        local pid = tonumber(e.placeId)
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))
        if target == "Drakenfyr the Inferno King / Dragon (Sea 3)" or target == "Rồng Biển / Dragon (Sea 3)" then
            local isDragonMatch = (src == "sea_event" and (string.find(nm, "dragon", 1, true) ~= nil or string.find(nm, "drakenfyr", 1, true) ~= nil))
                or string.find(nm, "drakenfyr", 1, true) ~= nil
                or string.find(nm, "inferno king", 1, true) ~= nil
                or string.find(nm, "sea dragon", 1, true) ~= nil
                or (string.find(nm, "dragon", 1, true) ~= nil and string.find(nm, "fruit", 1, true) == nil and string.find(nm, "claw", 1, true) == nil and string.find(nm, "orb", 1, true) == nil)
            local notDragonOther = string.find(nm, "abyssal", 1, true) == nil
                and string.find(nm, "tyrant", 1, true) == nil
                and string.find(nm, "depth", 1, true) == nil
                and string.find(src, "abyssal", 1, true) == nil
                and string.find(src, "depth", 1, true) == nil
            return pid == SEA3_PLACE and isDragonMatch and notDragonOther
        elseif target == "Abyssal Tyrant (Sea 3)" then
            local isAbyssalMatch = (src == "abyssal" or src == "tyrant" or string.find(src, "abyssal", 1, true) ~= nil or string.find(src, "tyrant", 1, true) ~= nil)
                or string.find(nm, "abyssal", 1, true) ~= nil
                or string.find(nm, "tyrant", 1, true) ~= nil
            local notAbyssalOther = string.find(nm, "depth", 1, true) == nil
                and string.find(nm, "swordsman", 1, true) == nil
                and string.find(nm, "dragon", 1, true) == nil
                and string.find(src, "depth", 1, true) == nil
            return pid == SEA3_PLACE and isAbyssalMatch and notAbyssalOther
        elseif target == "Depth King (Sea 3)" then
            return pid == SEA3_PLACE and (src == "depth_king" or string.find(nm, "depth king", 1, true) ~= nil or nm == "depthking" or (string.find(nm, "depth", 1, true) ~= nil and string.find(nm, "king", 1, true) ~= nil)) and string.find(nm, "abyssal", 1, true) == nil and string.find(nm, "tyrant", 1, true) == nil
        elseif target == "Kraken (Sea 3)" then return pid == SEA3_PLACE and src == "sea_event" and (string.find(nm, "kraken", 1, true) ~= nil or string.find(nm, "tentacle", 1, true) ~= nil)
        elseif target == "Cua Biển / Crab (Sea 3)" then return pid == SEA3_PLACE and (string.find(nm, "crab", 1, true) ~= nil or (src == "sea_event" and string.find(nm, "crab", 1, true) ~= nil))
        elseif target == "Rương Hydra (Sea 2)" then return pid == SEA2_PLACE and src == "sk_hd_chest" and string.find(nm, "hydra", 1, true) ~= nil
        elseif target == "Hydra (Sea 2)" then return pid == SEA2_PLACE and (src == "hydra" or string.find(nm, "hydra", 1, true) ~= nil)
        elseif target == "Rương Vua Biển (Sea 2)" then return pid == SEA2_PLACE and src == "sk_hd_chest" and (string.find(nm, "sea king", 1, true) ~= nil or string.find(nm, "seaking", 1, true) ~= nil)
        elseif target == "Vua Biển / Sea King (Sea 2)" then return pid == SEA2_PLACE and (src == "sea_king" or string.find(nm, "sea king", 1, true) ~= nil or string.find(nm, "seaking", 1, true) ~= nil)
        elseif target == "Thuyền Ma / Ghost Ship (Sea 2)" then return pid == SEA2_PLACE and (src == "ghost_ship" or string.find(nm, "ghost", 1, true) ~= nil)
        elseif target == "Rắn Biển / Serpent (Sea 2 & 3)" then return (src == "serpent" or string.find(nm, "serpent", 1, true) ~= nil)
        end
        return false
    end

    local snipeBusy = false
    QuickHopSection:CreateButton({
        Name = "🚀 Bay ngay vào 1 phòng có Boss đã chọn",
        Description = "Tự chọn phòng còn chỗ trống và Boss còn nhiều máu",
        Callback = function()
            if snipeBusy then
                safeNotify("YokaHub", "Đang tìm phòng, vui lòng đợi vài giây...", "info")
                return
            end
            snipeBusy = true
            task.spawn(function()
                local function done() snipeBusy = false end
                if typeof(genv.WK_FetchLiveBossApiSnapshot) ~= "function" or typeof(genv.WK_JoinLiveBossApiEntry) ~= "function" then
                    setStatus("Cần mở Wukong HUD để tìm phòng có Boss.")
                    safeNotify("YokaHub", "Cần mở Wukong HUD để tìm phòng có Boss.", "info")
                    done(); return
                end
                local reqPlace = nil
                if string.find(snipeTarget, "Serpent", 1, true) ~= nil then
                    reqPlace = (game.PlaceId == SEA2_PLACE) and SEA2_PLACE or SEA3_PLACE
                elseif string.find(snipeTarget, "Sea 2", 1, true) ~= nil and string.find(snipeTarget, "Sea 3", 1, true) == nil then
                    reqPlace = SEA2_PLACE
                elseif string.find(snipeTarget, "Sea 3", 1, true) ~= nil and string.find(snipeTarget, "Sea 2", 1, true) == nil then
                    reqPlace = SEA3_PLACE
                end
                if reqPlace and game.PlaceId ~= reqPlace then
                    local targetSeaName = (reqPlace == SEA2_PLACE and "Sea 2" or "Sea 3")
                    setStatus("Đang tự động chuyển sang " .. targetSeaName .. " để săn " .. snipeTarget .. "...")
                    safeNotify("Khác Sea", "Đang chuyển sang " .. targetSeaName .. " trước khi săn " .. snipeTarget .. "!", "flight_takeoff")
                    ensureCorrectSea(reqPlace, snipeTarget, "Khác Sea", snipeTarget)
                    done()
                    return
                end

                setStatus("Đang quét API tìm " .. snipeTarget .. "...")
                local ok, snap = pcall(genv.WK_FetchLiveBossApiSnapshot)
                if not ok or typeof(snap) ~= "table" or typeof(snap.entries) ~= "table" then
                    setStatus("Không đọc được Live Boss API, thử bấm lại.")
                    safeNotify("YokaHub", "Không đọc được Live Boss API, thử bấm lại.", "info")
                    done(); return
                end
                local list = {}
                local fullCount = 0
                for _, e in ipairs(snap.entries) do
                    if matchSnipe(e, snipeTarget) then
                        e._tier = getSlotTier(e)
                        e._hp = typeof(e.health) == "table" and (tonumber(e.health.percent) or 100) or 100
                        e._pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 99) or 99
                        table.insert(list, e)
                    elseif e.alive == true then
                        local pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 0) or 0
                        local pMax = typeof(e.players) == "table" and (tonumber(e.players.max) or 12) or 12
                        if pCur >= pMax and matchSnipe(e, snipeTarget, true) then
                            fullCount += 1
                        end
                    end
                end
                if #list == 0 then
                    local msg = fullCount > 0
                        and string.format("%s đang có %d phòng nhưng đều đầy 12/12! Thử chọn Boss khác.", snipeTarget, fullCount)
                        or ("Hiện chưa có phòng nào trên API cho " .. snipeTarget)
                    setStatus(msg)
                    safeNotify("YokaHub", msg, "info")
                    done(); return
                end
                table.sort(list, function(a, b)
                    if a._tier ~= b._tier then return a._tier > b._tier end
                    local aCur = a._pCur or 99
                    local bCur = b._pCur or 99
                    if aCur ~= bCur then return aCur < bCur end
                    return a._hp > b._hp
                end)
                local tries = math.min(#list, 4)
                for idx = 1, tries do
                    if genv._YokaHubToken ~= myToken then break end
                    local chosen = list[idx]
                    local info = string.format("%s (%s/%s người)", tostring(chosen.eventName), tostring(chosen.players and chosen.players.current or "?"), tostring(chosen.players and chosen.players.max or "?"))
                    setStatus("Đang bay vào: " .. info)
                    if idx == 1 then recordHop() end
                    armAutoReexec(false)
                    local hopStart = os.clock()
                    pcall(genv.WK_JoinLiveBossApiEntry, chosen)
                    safeNotify("Đang bay tới", info, "public")
                    local failed = false
                    local w = 0
                    while w < 4.0 do
                        task.wait(0.25); w += 0.25
                        if (tonumber(genv._LastTeleportFailClock) or 0) >= hopStart and w >= 0.6 then
                            failed = true
                            if idx < tries then
                                setStatus("Phòng vừa đầy, bật sang phòng tiếp theo ngay...")
                            else
                                setStatus("Các phòng thử đều vừa đầy, thử bấm lại sau vài giây.")
                            end
                            break
                        end
                    end
                    if not failed then break end
                end
                done()
            end)
        end,
    })

    QuickHopSection:CreateButton({
        Name = "🔄 Sang phòng mới ít người (để Random Trái)",
        Description = "Chuyển nhanh sang phòng thoáng 3–8 người để random trái hoặc nghỉ farm",
        Callback = function()
            task.spawn(function()
                if currentMode ~= "off" then
                    applyMode("off", false)
                end
                setStatus("Đang tìm phòng ít người (3–8 người)...")
                local chosenId: string? = nil
                local chosenInfo = ""

                local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
                local ok, raw = pcall(function() return game:HttpGet(url) end)
                if ok and typeof(raw) == "string" then
                    local dok, decoded = pcall(function() return httpService:JSONDecode(raw) end)
                    if dok and typeof(decoded) == "table" and typeof(decoded.data) == "table" then
                        local pref, fb = {}, {}
                        for _, srv in ipairs(decoded.data) do
                            local id = tostring(srv.id or "")
                            local p, m = tonumber(srv.playing) or 99, tonumber(srv.maxPlayers) or 12
                            if id ~= "" and id ~= game.JobId and p < m then
                                table.insert(fb, srv)
                                if p >= 3 and p <= 8 then table.insert(pref, srv) end
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

                recordHop()
                armAutoReexec(false)
                if chosenId and chosenId ~= "" then
                    setStatus(chosenInfo)
                    safeNotify("Đang chuyển phòng", chosenInfo, "public")
                    pcall(function() teleportService:TeleportToPlaceInstance(game.PlaceId, chosenId :: string, players.LocalPlayer) end)
                else
                    setStatus("Đang chuyển sang phòng mới...")
                    safeNotify("Đang chuyển phòng", "Đang chuyển sang phòng công khai mới...", "public")
                    if teleportToSea then
                        teleportToSea(game.PlaceId)
                    else
                        pcall(function() teleportService:Teleport(game.PlaceId, players.LocalPlayer) end)
                    end
                end
            end)
        end,
    })

