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
        local free = pMax - pCur
        if pCur >= 4 and pCur <= 8 and free >= 3 then return 4 end
        if free >= 2 then return 3 end
        if free >= 1 then return 1 end
        return 0
    end

    local function getSea3Prio(e: any): number
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))
        -- Top 1: Depth King (Sea 3) - Ưu tiên cao nhất (6 điểm)
        if (src == "depth_king" or string.find(nm, "depth") ~= nil) and string.find(nm, "abyssal") == nil then
            return 6
        end
        -- Top 2: Drakenfyr the Inferno King / Dragon (Sea 3) - Ưu tiên số 2 (5 điểm)
        if string.find(nm, "drakenfyr") ~= nil or string.find(nm, "inferno king") ~= nil or (src == "sea_event" and string.find(nm, "dragon") ~= nil) then
            return 5
        end
        -- Top 3: Abyssal Tyrant (Sea 3) - Ưu tiên số 3 (4 điểm)
        if string.find(nm, "abyssal tyrant") ~= nil or string.find(nm, "abyssal") ~= nil then
            return 4
        end
        -- Top 4: Kraken (Sea 3) - Ưu tiên số 4 (3 điểm)
        if src == "sea_event" and (string.find(nm, "kraken") ~= nil or string.find(nm, "tentacle") ~= nil) then
            return 3
        end
        -- Top 5: Các Sea Events khác (Cua Biển / Crab, Sea Beast...) (2 điểm)
        if src == "sea_event" then
            return 2
        end
        -- Top 6: Rắn Biển / Serpent (1 điểm)
        if src == "serpent" or string.find(nm, "serpent") ~= nil then
            return 1
        end
        return 0
    end

    local function getSea2Prio(e: any): number
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))
        if src == "sk_hd_chest" and string.find(nm, "hydra") then return 7 end
        if src == "hydra" then return 6 end
        if src == "sk_hd_chest" and (string.find(nm, "sea king") or string.find(nm, "seaking")) then return 5 end
        if src == "sea_king" then return 4 end
        if src == "serpent" or string.find(nm, "serpent") then return 3 end
        if (string.find(src, "ghost") or string.find(nm, "ghost")) and string.find(nm, "chest") then return 2 end
        if src == "ghost_ship" then return 1 end
        return 0
    end

    -- ========================================================
    -- TAB 1: SAN BOSS
    -- ========================================================
    local HopTab = Window:CreateTab({
        Name = "Săn Boss",
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

    local function applyMode(newMode: string, notifyUser: boolean)
        if newMode == "depth_king" then
            currentSoloTarget = SOLO_OPTIONS[1]
            hubState.soloTarget = currentSoloTarget
            newMode = "solo"
        end
        -- Khử xung đột: Khi chuyển sang Săn Boss, tự động tạm tắt cày quái thường
        if newMode ~= "off" then
            if hubState.autoLevel then
                hubState.autoLevel = false
                pcall(function() genv.Famlevel = false; genv.start = false end)
                safeNotify("YokaHub", "Đã ưu tiên Săn Boss (Tạm dừng cày quái thường).", "info")
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
            if not ensureCorrectSea(SEA3_PLACE, "Boss Sea 3", "Săn tổng hợp", "depth") then
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
            currentSoloTarget = SOLO_OPTIONS[1]
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

    StatusSection:CreateDropdown({
        Name = "🎯 Mục tiêu API",
        Options = SOLO_OPTIONS,
        CurrentOption = { currentSoloTarget },
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
        Description = "Ưu tiên: Depth King → Rồng → Kraken → Cua → Serpent",
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
    MasterFightSection:CreateToggle({
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
    IslandFightSection:CreateToggle({
        Name = "⚔️ Bật Tự Động Săn Boss Đảo (Auto Farm Island Bosses)",
        Description = "Tự động bay đến hòn đảo có Boss mục tiêu, nhận quest và tiêu diệt",
        CurrentValue = hubState.autoFightIslandBoss,
        Callback = function(Value: boolean)
            hubState.autoFightIslandBoss = Value
            saveState(hubState)
            if Value then
                safeNotify("YokaHub Island Boss", "Đang tự động săn Boss đảo: " .. tostring(hubState.islandBossTarget or "Hephaestus"), "my_location")
            end
        end,
    }, "AutoFightIslandBossToggle")

    IslandFightSection:CreateDropdown({
        Name = "Chọn Boss Đảo Muốn Tiêu Diệt",
        Options = {
            "Hephaestus (Thợ Rèn Thần - Sea 3)",
            "Dark Beard (Râu Đen - Sea 3)",
            "Gryphon Boss (Sea 3)",
            "Lucidus (Sea 2)",
            "Sunken Blade Boss (Sea 2)",
            "Snow Boss (Sea 2)",
            "Smoker (Sea 1)",
            "Tashigi (Sea 1)",
            "Buggy (Sea 1)",
            "Arlong (Sea 1)",
        },
        CurrentOption = { hubState.islandBossTarget or "Hephaestus (Thợ Rèn Thần - Sea 3)" },
        MultipleOptions = false,
        Callback = function(opt: any)
            local val = pickDropdownValue(opt)
            hubState.islandBossTarget = val
            saveState(hubState)
            safeNotify("Mục Tiêu Boss Đảo", "Đã chọn: " .. val, "flag")
        end,
    }, "IslandBossDropdown")

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
        if target == "Drakenfyr the Inferno King / Dragon (Sea 3)" or target == "Rồng Biển / Dragon (Sea 3)" then return pid == SEA3_PLACE and (src == "sea_event" and (string.find(nm, "dragon") ~= nil or string.find(nm, "drakenfyr") ~= nil) or string.find(nm, "drakenfyr") ~= nil or string.find(nm, "inferno king") ~= nil)
        elseif target == "Abyssal Tyrant (Sea 3)" then return pid == SEA3_PLACE and (string.find(nm, "abyssal tyrant") ~= nil or string.find(nm, "abyssal") ~= nil)
        elseif target == "Depth King (Sea 3)" then return pid == SEA3_PLACE and (src == "depth_king" or (string.find(nm, "depth") ~= nil and string.find(nm, "abyssal") == nil))
        elseif target == "Kraken (Sea 3)" then return pid == SEA3_PLACE and src == "sea_event" and string.find(nm, "kraken") ~= nil
        elseif target == "Rương Hydra (Sea 2)" then return pid == SEA2_PLACE and src == "sk_hd_chest" and string.find(nm, "hydra") ~= nil
        elseif target == "Hydra (Sea 2)" then return pid == SEA2_PLACE and src == "hydra"
        elseif target == "Rương Vua Biển (Sea 2)" then return pid == SEA2_PLACE and src == "sk_hd_chest" and (string.find(nm, "sea king") ~= nil or string.find(nm, "seaking") ~= nil)
        elseif target == "Vua Biển / Sea King (Sea 2)" then return pid == SEA2_PLACE and src == "sea_king"
        elseif target == "Thuyền Ma / Ghost Ship (Sea 2)" then return pid == SEA2_PLACE and (src == "ghost_ship" or string.find(nm, "ghost") ~= nil)
        elseif target == "Rắn Biển / Serpent (Sea 2 & 3)" then return src == "serpent"
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
                if string.find(snipeTarget, "Sea 2") ~= nil then
                    reqPlace = SEA2_PLACE
                elseif string.find(snipeTarget, "Sea 3") ~= nil then
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
                    local reqPlace = SEA3_PLACE
                    if string.find(snipeTarget, "Sea 2") ~= nil then reqPlace = SEA2_PLACE end
                    if game.PlaceId ~= reqPlace then
                        ensureCorrectSea(reqPlace, snipeTarget, "Chưa có phòng trên API", snipeTarget)
                        done(); return
                    end
                    local msg = fullCount > 0
                        and string.format("%s đang có %d phòng nhưng đều đầy 12/12! Thử chọn Boss khác.", snipeTarget, fullCount)
                        or ("Hiện chưa có phòng nào cho " .. snipeTarget)
                    setStatus(msg)
                    safeNotify("YokaHub", msg, "info")
                    done(); return
                end
                table.sort(list, function(a, b)
                    if a._tier ~= b._tier then return a._tier > b._tier end
                    return a._hp > b._hp
                end)
                local tries = math.min(#list, 4)
                for idx = 1, tries do
                    if genv._YokaHubToken ~= myToken then break end
                    local chosen = list[idx]
                    local info = string.format("%s (%s/%s người)", tostring(chosen.eventName), tostring(chosen.players and chosen.players.current or "?"), tostring(chosen.players and chosen.players.max or "?"))
                    setStatus("Đang bay vào: " .. info)
                    if idx == 1 then recordHop() end
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

