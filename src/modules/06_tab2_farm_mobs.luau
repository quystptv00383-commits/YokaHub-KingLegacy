    -- ========================================================
    -- TAB 2: CAY CAP & FARM QUAI (AUTO LEVEL & MOBS)
    -- ========================================================
    do
        local FarmTab = Window:CreateTab({
            Name = "🌾 Cày Cấp & Quái",
            Icon = "fitness_center",
            ImageSource = "Material",
            ShowTitle = false,
        })

        local LevelSection = FarmTab:CreateSection("🌾 Cày Cấp Độ Tự Động (Level 1 - Max)")
        LevelSection:CreateToggle({
            Name = "🌾 Bật Farm Level Tự Động",
            Description = "Tự bay đến NPC nhận quest theo cấp, gom quái và đánh dọn sạch",
            CurrentValue = hubState.autoLevel,
            Callback = function(Value: boolean)
                hubState.autoLevel = Value
                if Value and currentMode ~= "off" then
                    applyMode("off", false)
                    setStatus("Đang cày cấp độ trong phòng hiện tại — Tạm dừng Săn Boss.")
                end
                saveState(hubState)
                pcall(function()
                    genv.Famlevel = Value
                    genv.start = Value
                    if Value then
                        genv.autocat = true
                        genv.haki = true
                        genv.opeskill = true
                        genv.nequaikill = true
                    end
                end)
                if Value then
                    safeNotify("YokaHub Farm", "Đã bật Farm Level tự động (Đã dừng Hop Boss để tập trung cày cấp).", "agriculture")
                else
                    safeNotify("YokaHub Farm", "Đã tắt Farm Level.", "pause_circle")
                end
            end,
        }, "AutoLevelToggle")

        LevelSection:CreateToggle({
            Name = "🕊️ Giữ Khoảng Cách An Toàn Trên Không",
            Description = "Giữ vị trí lơ lửng trên đầu quái vật để không bị đánh trúng",
            CurrentValue = hubState.safeDistance,
            Callback = function(Value: boolean)
                hubState.safeDistance = Value
                saveState(hubState)
                pcall(function()
                    genv.nequaikill = Value
                    genv.tamxanekillquai = 250
                    genv.docaokillquai = 18
                end)
            end,
        }, "SafeDistanceToggle")

        local MobSection = FarmTab:CreateSection("🎯 Farm Quái Chọn Lọc (Select Mob Farm)")
        MobSection:CreateDropdown({
            Name = "👾 Chọn Quái Muốn Cày",
            Options = {
                "Elite Skeleton [Lv. 3100]",
                "Ocean Gladiator [Lv. 4500]",
                "Sea Soldier [Lv. 2250]",
                "Fishman Raider [Lv. 1500]",
                "Pirate Guard [Lv. 500]",
                "Desert Bandit [Lv. 100]",
            },
            CurrentOption = { "Elite Skeleton [Lv. 3100]" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                pcall(function()
                    genv.chonmod = val
                end)
            end,
        }, "SelectMobDropdown")

        MobSection:CreateToggle({
            Name = "⚔️ Bật Cày Quái Đã Chọn",
            Description = "Tập trung đánh loại quái được chọn ở dropdown trên",
            CurrentValue = false,
            Callback = function(Value: boolean)
                pcall(function()
                    genv.Autokillmob = Value
                    genv.start = Value
                    if Value then
                        genv.autocat = true
                        genv.haki = true
                    end
                end)
            end,
        }, "AutoKillSelectedMobToggle")

        MobSection:CreateToggle({
            Name = "⚡ Gom Quái Nhanh (Fast Mob Bring)",
            Description = "Hút quái vật xung quanh tụ lại 1 điểm để chém lan dọn nhanh",
            CurrentValue = true,
            Callback = function(Value: boolean)
                pcall(function()
                    genv.autocat = Value
                end)
            end,
        }, "FastMobBringToggle")

        local QuestSection = FarmTab:CreateSection("📋 Nhiệm Vụ Hàng Ngày & Tộc (Daily Quests & Race)")
        QuestSection:CreateToggle({
            Name = "📜 Tự Làm Nhiệm Vụ Hàng Ngày (Daily Quests)",
            Description = "Tự nhận và hoàn thành tất cả nhiệm vụ ngày để cày Gems và Beli",
            CurrentValue = hubState.autoDailyQuest,
            Callback = function(Value: boolean)
                hubState.autoDailyQuest = Value
                saveState(hubState)
                pcall(function()
                    genv.autoalldailyquest = Value
                    genv.nhiemvuhangngay = Value
                end)
                if Value then safeNotify("YokaHub", "Đã bật tự động làm Daily Quest!", "assignment") end
            end,
        }, "AutoDailyQuestToggle")

        QuestSection:CreateToggle({
            Name = "🧬 Tự Động Roll Tộc Mong Muốn (Auto Race Roll)",
            Description = "Tự động quay tộc bằng Gems cho đến khi ra tộc mong muốn",
            CurrentValue = hubState.autoRaceRoll,
            Callback = function(Value: boolean)
                hubState.autoRaceRoll = Value
                saveState(hubState)
                pcall(function()
                    genv.AutoGetAutoRollRace = Value
                    genv.toc = Value
                end)
            end,
        }, "AutoRaceRollToggle")
    end
