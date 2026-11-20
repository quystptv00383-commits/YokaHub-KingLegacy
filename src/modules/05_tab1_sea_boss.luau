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

    local StatusSection = HopTab:CreateSection("🌊 Tự động chuyển phòng săn Boss")
    local StatusParagraph = StatusSection:CreateParagraph({
        Title = "Trạng thái · Đang tắt",
        Text = currentMode == "off"
            and "Chọn Boss săn riêng (F7) hoặc bật săn tổng hợp Sea 3 (F8) / Sea 2 (F9)."
            or ("Đang khởi động chế độ " .. (currentMode == "solo" and ("Săn riêng: " .. currentSoloTarget) or (currentMode == "sea3" and "Sea 3" or "Sea 2")) .. "..."),
    })

    local lastStatusTitle = ""
    local lastStatusText = ""
    local statusDirty = false
    local function setStatus(text: string, force: boolean?)
        local titleStr = "Trạng thái · Đang tắt"
        if currentMode == "solo" then titleStr = "Săn riêng · " .. currentSoloTarget
        elseif currentMode == "sea3" then titleStr = "Trạng thái · Đang săn Sea 3"
        elseif currentMode == "sea2" then titleStr = "Trạng thái · Đang săn Sea 2"
        end
        if not force and titleStr == lastStatusTitle and text == lastStatusText then
            return
        end
        lastStatusTitle = titleStr
        lastStatusText = text
        if not force and not isHubOpen() then
            statusDirty = true
            return
        end
        statusDirty = false
        pcall(function()
            StatusParagraph:Set({ Title = titleStr, Text = text })
        end)
    end
    table.insert(onHubOpenedHooks, function()
        if statusDirty and lastStatusText ~= "" then
            setStatus(lastStatusText, true)
        end
    end)

    local syncingToggles = false
    local SoloToggle: any = nil
    local Sea3Toggle: any = nil
    local Sea2Toggle: any = nil
    local MasterAutoFightToggle: any = nil

    local function applyMode(newMode: string, notifyUser: boolean)
        if newMode == "depth_king" then
            currentSoloTarget = "👑 Depth King (Sea 3)"
            hubState.soloTarget = currentSoloTarget
            newMode = "solo"
        end
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
        genv._KingSoloTarget = currentSoloTarget
        genv._AutoSeaEventApiHop = (newMode == "sea3")
        genv._AutoSea2PriorityApiHop = (newMode == "sea2")
        genv._AutoDepthKingOnlyApiHop = (newMode == "solo" and getSoloKey(currentSoloTarget) == "depth_king")
        saveState(hubState)
        updateDockDot()
        if newMode ~= "off" then
            armAutoReexec(false)
        end

        syncingToggles = true
        if SoloToggle and typeof(SoloToggle.Set) == "function" then
            pcall(function() SoloToggle:Set({ CurrentValue = (newMode == "solo") }) end)
        end
        if Sea3Toggle and typeof(Sea3Toggle.Set) == "function" then
            pcall(function() Sea3Toggle:Set({ CurrentValue = (newMode == "sea3") }) end)
        end
        if Sea2Toggle and typeof(Sea2Toggle.Set) == "function" then
            pcall(function() Sea2Toggle:Set({ CurrentValue = (newMode == "sea2") }) end)
        end
        if MasterAutoFightToggle and typeof(MasterAutoFightToggle.Set) == "function" then
            pcall(function() MasterAutoFightToggle:Set({ CurrentValue = hubState.autoFightMaster }) end)
        end
        syncingToggles = false

        if newMode == "solo" then
            local soloKey = getSoloKey(currentSoloTarget)
            local targetPlace = getSoloPlaceId(soloKey)
            if not ensureCorrectSea(targetPlace, currentSoloTarget, "Săn riêng", soloKey) then
                local sName = (targetPlace == SEA3_PLACE and "Sea 3") or "Sea 2"
                setStatus("Đang tự động chuyển sang " .. sName .. " để săn " .. currentSoloTarget .. "...", true)
                return
            end
            setStatus("Đang dò riêng API: " .. currentSoloTarget .. "...", true)
            if notifyUser then
                safeNotify("YokaHub", "Đã bật săn riêng: " .. currentSoloTarget, "public")
            end
        elseif newMode == "sea3" then
            local preferSea3Boss = (hubState.fightSea3DepthKing ~= false and "depth")
                or (hubState.fightSea3Dragon ~= false and "dragon")
                or (hubState.fightSea3Abyssal ~= false and "abyssal")
                or (hubState.fightSea3Kraken ~= false and "kraken")
                or (hubState.fightSea3Crab ~= false and "crab")
                or "depth"
            if not ensureCorrectSea(SEA3_PLACE, "Boss Sea 3", "Săn tổng hợp", preferSea3Boss) then
                setStatus("Đang tự động chuyển sang Sea 3 để săn Boss tổng hợp...", true)
                return
            end
            setStatus("Đang tìm phòng có Boss ở Sea 3...", true)
            if notifyUser then
                safeNotify("YokaHub", "Đã bật tự động săn Boss Sea 3.", "public")
            end
        elseif newMode == "sea2" then
            if not ensureCorrectSea(SEA2_PLACE, "Boss Sea 2", "Săn tổng hợp", "hydra") then
                setStatus("Đang tự động chuyển sang Sea 2 để săn Boss & Rương...", true)
                return
            end
            setStatus("Đang tìm phòng có Boss / Rương ở Sea 2...", true)
            if notifyUser then
                safeNotify("YokaHub", "Đã bật tự động săn Boss & Rương Sea 2.", "public")
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

    genv.SetKingAutoHopMode = function(m: string) applyMode(m, false) end
    genv.SetAutoDepthKingHopEnabled = function(on: boolean)
        if on then
            currentSoloTarget = "👑 Depth King (Sea 3)"
            hubState.soloTarget = currentSoloTarget
        end
        applyMode(on and "solo" or "off", false)
    end
    genv.SetAutoSoloHopEnabled = function(on: boolean, targetOpt: string?)
        if typeof(targetOpt) == "string" and SOLO_KEY_MAP[targetOpt] ~= nil then
            currentSoloTarget = targetOpt
            hubState.soloTarget = targetOpt
        end
        applyMode(on and "solo" or "off", false)
    end
    genv.SetAutoHopEnabled = function(on: boolean) applyMode(on and "sea3" or "off", false) end
    genv.SetAutoSea2HopEnabled = function(on: boolean) applyMode(on and "sea2" or "off", false) end

    local defaultSoloTarget = table.find(SOLO_OPTIONS, currentSoloTarget) and currentSoloTarget or SOLO_OPTIONS[1]
    StatusSection:CreateDropdown({
        Name = "🎯 Mục tiêu API",
        Options = SOLO_OPTIONS,
        CurrentOption = { defaultSoloTarget },
        MultipleOptions = false,
        Callback = function(opt: any)
            local picked = pickDropdownValue(opt)
            if SOLO_KEY_MAP[picked] == nil then return end
            if picked == currentSoloTarget then return end
            currentSoloTarget = picked
            hubState.soloTarget = picked
            genv._KingSoloTarget = picked
            genv._AutoDepthKingOnlyApiHop = (currentMode == "solo" and getSoloKey(picked) == "depth_king")
            saveState(hubState)
            if currentMode == "solo" then
                local targetPlace = getSoloPlaceId(getSoloKey(picked))
                if not ensureCorrectSea(targetPlace, picked, "Đổi mục tiêu Boss", getSoloKey(picked)) then
                    local sName = (targetPlace == SEA3_PLACE and "Sea 3") or "Sea 2"
                    setStatus("Đang tự động chuyển sang " .. sName .. " để săn " .. picked .. "...", true)
                    return
                end
                setStatus("Đã đổi mục tiêu săn riêng sang: " .. picked, true)
                safeNotify("YokaHub", "Đang chuyển săn riêng: " .. picked, "public")
            end
        end,
    }, "SoloApiTarget")

    SoloToggle = StatusSection:CreateToggle({
        Name = "🎯 Săn riêng API đã chọn (Phím F7)",
        Description = "Chỉ nhảy đúng 1 mục tiêu ở trên · Không qua Boss khác",
        CurrentValue = (currentMode == "solo"),
        Callback = function(Value: boolean)
            if syncingToggles then return end
            if Value then applyMode("solo", true)
            elseif currentMode == "solo" then applyMode("off", true)
            end
        end,
    }, "AutoHopSoloApi")

    Sea3Toggle = StatusSection:CreateToggle({
        Name = "🐉 Săn tổng hợp Sea 3 (Phím F8)",
        Description = "Ưu tiên: Depth King (Top 1) → Rồng Drakenfyr (Top 2) → Abyssal (Top 3) → Kraken → Cua → Serpent",
        CurrentValue = (currentMode == "sea3"),
        Callback = function(Value: boolean)
            if syncingToggles then return end
            if Value then applyMode("sea3", true)
            elseif currentMode == "sea3" then applyMode("off", true)
            end
        end,
    }, "AutoHopSea3")

    Sea2Toggle = StatusSection:CreateToggle({
        Name = "🐍 Săn tổng hợp Sea 2 (Phím F9)",
        Description = "Ưu tiên: Rương Hydra → Hydra → Sea King → Serpent → Tàu",
        CurrentValue = (currentMode == "sea2"),
        Callback = function(Value: boolean)
            if syncingToggles then return end
            if Value then applyMode("sea2", true)
            elseif currentMode == "sea2" then applyMode("off", true)
            end
        end,
    }, "AutoHopSea2")

    trackConn(userInputService.InputBegan:Connect(function(input: InputObject, gp: boolean)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F7 then
            applyMode(currentMode == "solo" and "off" or "solo", true)
        elseif input.KeyCode == Enum.KeyCode.F8 then
            applyMode(currentMode == "sea3" and "off" or "sea3", true)
        elseif input.KeyCode == Enum.KeyCode.F9 then
            applyMode(currentMode == "sea2" and "off" or "sea2", true)
        end
    end))

    
    -- ========================================================
    -- BẢNG 1: BẢNG CHUNG - TỰ ĐỘNG ĐÁNH TỔNG HỢP SEA EVENT & BOSS
    -- ========================================================
    local MasterFightSection = HopTab:CreateSection("🌟 BẢNG CHUNG: TỰ ĐỘNG ĐÁNH TỔNG HỢP SEA EVENT & BOSS")
    MasterAutoFightToggle = MasterFightSection:CreateToggle({
        Name = "⚔️ Bật Tự Động Đánh Mọi Sea Event & Boss Khi Thấy (Master Auto Fight)",
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
    -- BẢNG 2: BẢNG RIÊNG 1 - CHUYÊN SĂN BOSS BIỂN SEA 3
    -- ========================================================
    local Sea3FightSection = HopTab:CreateSection("👑 BẢNG RIÊNG 1: SĂN BOSS BIỂN SEA 3 (CHỌN TỪNG CON)")
    Sea3FightSection:CreateToggle({
        Name = "👑 Săn Depth King (Sea 3)",
        Description = "Tự động săn và mở rương Vua Vực Thẳm Depth King (Top 1)",
        CurrentValue = hubState.fightSea3DepthKing,
        Callback = function(Value: boolean)
            hubState.fightSea3DepthKing = Value
            saveState(hubState)
        end,
    }, "FightSea3DepthKingToggle")

    Sea3FightSection:CreateToggle({
        Name = "🐲 Săn Drakenfyr the Inferno King / Dragon (Sea 3)",
        Description = "Tự động săn Rồng Lửa Drakenfyr the Inferno King (Top 2)",
        CurrentValue = hubState.fightSea3Dragon,
        Callback = function(Value: boolean)
            hubState.fightSea3Dragon = Value
            saveState(hubState)
        end,
    }, "FightSea3DragonToggle")

    Sea3FightSection:CreateToggle({
        Name = "👑 Săn Abyssal Tyrant (Sea 3)",
        Description = "Tự động săn bạo chúa Abyssal Tyrant (Top 3)",
        CurrentValue = hubState.fightSea3Abyssal,
        Callback = function(Value: boolean)
            hubState.fightSea3Abyssal = Value
            saveState(hubState)
        end,
    }, "FightSea3AbyssalToggle")

    Sea3FightSection:CreateToggle({
        Name = "🐙 Săn Kraken & Xúc Tu (Sea 3)",
        Description = "Tự động đánh Kraken và chặt xúc tu biển",
        CurrentValue = hubState.fightSea3Kraken,
        Callback = function(Value: boolean)
            hubState.fightSea3Kraken = Value
            saveState(hubState)
        end,
    }, "FightSea3KrakenToggle")

    Sea3FightSection:CreateToggle({
        Name = "🦀 Săn Cua Biển Khổng Lồ (Giant Crab Sea 3)",
        Description = "Tự động tiêu diệt Cua Biển khổng lồ Sea 3",
        CurrentValue = hubState.fightSea3Crab,
        Callback = function(Value: boolean)
            hubState.fightSea3Crab = Value
            saveState(hubState)
        end,
    }, "FightSea3CrabToggle")

    Sea3FightSection:CreateToggle({
        Name = "🌊 Săn Sea Event Thường (Bỏ qua Depth & Abyssal)",
        Description = "Tập trung săn các sự kiện biển vừa và nhỏ",
        CurrentValue = hubState.fightSea3Events,
        Callback = function(Value: boolean)
            hubState.fightSea3Events = Value
            saveState(hubState)
        end,
    }, "FightSea3EventsToggle")

    -- ========================================================
    -- BẢNG 3: BẢNG RIÊNG 2 - CHUYÊN SĂN BOSS BIỂN SEA 2
    -- ========================================================
    local Sea2FightSection = HopTab:CreateSection("🐋 BẢNG RIÊNG 2: SĂN BOSS BIỂN SEA 2 (CHỌN TỪNG CON)")
    Sea2FightSection:CreateToggle({
        Name = "🐍 Săn Hydra & Rương Hydra (Sea 2)",
        Description = "Tự động đánh Rắn 3 đầu Hydra và mở rương huyền thoại",
        CurrentValue = hubState.fightSea2Hydra,
        Callback = function(Value: boolean)
            hubState.fightSea2Hydra = Value
            saveState(hubState)
        end,
    }, "FightSea2HydraToggle")

    Sea2FightSection:CreateToggle({
        Name = "🐋 Săn Sea King (Vua Biển) & Rương Vua Biển (Sea 2)",
        Description = "Tự động đánh Sea King và mở rương Vua Biển",
        CurrentValue = hubState.fightSea2SeaKing,
        Callback = function(Value: boolean)
            hubState.fightSea2SeaKing = Value
            saveState(hubState)
        end,
    }, "FightSea2SeaKingToggle")

    Sea2FightSection:CreateToggle({
        Name = "👻 Săn Thuyền Ma & Rương Thuyền Ma (Sea 2)",
        Description = "Tự động bắn phá Tàu Ma Ghost Ship và nhặt rương rơi",
        CurrentValue = hubState.fightSea2GhostShip,
        Callback = function(Value: boolean)
            hubState.fightSea2GhostShip = Value
            saveState(hubState)
        end,
    }, "FightSea2GhostShipToggle")

    Sea2FightSection:CreateToggle({
        Name = "🐍 Săn Rắn Biển / Sea Serpent (Sea 2 & 3)",
        Description = "Tự động tiêu diệt Rắn Biển Serpent",
        CurrentValue = hubState.fightSea2Serpent,
        Callback = function(Value: boolean)
            hubState.fightSea2Serpent = Value
            saveState(hubState)
        end,
    }, "FightSea2SerpentToggle")

    -- ========================================================
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

