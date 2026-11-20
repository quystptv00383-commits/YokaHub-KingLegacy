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
            Name = "🕊️ Bay Lơ Lửng An Toàn Trên Không (Hover Lock + NoClip)",
            Description = "Bay mượt & giữ lơ lửng cố định trên đầu quái/boss không bị rơi xuống đất",
            CurrentValue = hubState.safeDistance,
            Callback = function(Value: boolean)
                hubState.safeDistance = Value
                saveState(hubState)
                pcall(function()
                    genv.nequaikill = Value
                    genv.tamxanekillquai = 250
                    genv.docaokillquai = 12
                end)
            end,
        }, "SafeDistanceToggle")

        LevelSection:CreateSlider({
            Name = "🚀 Tốc Độ Bay Khi Farm & Đánh Boss (Fly Speed)",
            Range = { 200, 650 },
            Increment = 10,
            Suffix = " studs/s",
            CurrentValue = hubState.flySpeed or 420,
            Callback = function(Value: number)
                hubState.flySpeed = math.clamp(math.floor(Value), 200, 650)
                saveState(hubState)
                pcall(function()
                    genv.YokaFlySpeed = hubState.flySpeed
                end)
            end,
        }, "FlySpeedSlider")

        LevelSection:CreateToggle({
            Name = "📜 Tự Nhận Nhiệm Vụ Theo Cấp (Auto Level Quest)",
            Description = "Tự động tìm NPC và nhận nhiệm vụ phù hợp với level hiện tại",
            CurrentValue = hubState.autoTakeLevelQuest,
            Callback = function(Value: boolean)
                hubState.autoTakeLevelQuest = Value
                saveState(hubState)
                if Value then safeNotify("YokaHub Farm", "Đã bật tự động nhận nhiệm vụ theo cấp!", "assignment") end
            end,
        }, "AutoTakeLevelQuestToggle")

        local StatsSection = FarmTab:CreateSection("💪 Tự Tăng Điểm Chỉ Số (Auto Stats)")
        StatsSection:CreateToggle({
            Name = "👊 Tự Tăng Cận Chiến (Auto Melee)",
            Description = "Tự động cộng điểm vào Melee khi lên cấp",
            CurrentValue = hubState.statMelee,
            Callback = function(Value: boolean)
                hubState.statMelee = Value
                saveState(hubState)
            end,
        }, "StatMeleeToggle")

        StatsSection:CreateToggle({
            Name = "🛡️ Tự Tăng Phòng Thủ (Auto Defense)",
            Description = "Tự động cộng điểm vào Defense khi lên cấp",
            CurrentValue = hubState.statDefense,
            Callback = function(Value: boolean)
                hubState.statDefense = Value
                saveState(hubState)
            end,
        }, "StatDefenseToggle")

        StatsSection:CreateToggle({
            Name = "🗡️ Tự Tăng Kiếm Thuật (Auto Sword)",
            Description = "Tự động cộng điểm vào Sword khi lên cấp",
            CurrentValue = hubState.statSword,
            Callback = function(Value: boolean)
                hubState.statSword = Value
                saveState(hubState)
            end,
        }, "StatSwordToggle")

        StatsSection:CreateToggle({
            Name = "🍎 Tự Tăng Trái Ác Quỷ (Auto Fruit)",
            Description = "Tự động cộng điểm vào Fruit khi lên cấp",
            CurrentValue = hubState.statFruit,
            Callback = function(Value: boolean)
                hubState.statFruit = Value
                saveState(hubState)
            end,
        }, "StatFruitToggle")

        StatsSection:CreateSlider({
            Name = "Số Điểm Nâng Mỗi Lần (Points Per Tick)",
            Range = { 1, 50 },
            Increment = 1,
            Suffix = " Điểm",
            CurrentValue = hubState.statPointsPerTick or 5,
            Callback = function(Value: number)
                hubState.statPointsPerTick = math.clamp(math.floor(Value), 1, 100)
                saveState(hubState)
            end,
        }, "StatPointsSlider")

        local MobSection = FarmTab:CreateSection("🎯 Farm Quái Chọn Lọc (Select Mob Farm)")
        local mobOptions = {
            "Elite Skeleton [Lv. 3100]",
            "Ocean Gladiator [Lv. 4500]",
            "Sea Soldier [Lv. 2250]",
            "Fishman Raider [Lv. 1500]",
            "Pirate Guard [Lv. 500]",
            "Desert Bandit [Lv. 100]",
        }
        local defaultSelectedMob = table.find(mobOptions, hubState.selectedMob) and hubState.selectedMob or mobOptions[1]
        MobSection:CreateDropdown({
            Name = "👾 Chọn Quái Muốn Cày",
            Options = mobOptions,
            CurrentOption = { defaultSelectedMob },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.selectedMob = val
                saveState(hubState)
                pcall(function()
                    genv.chonmod = val
                end)
            end,
        }, "SelectMobDropdown")

        MobSection:CreateToggle({
            Name = "⚔️ Bật Cày Quái Đã Chọn",
            Description = "Tập trung đánh loại quái được chọn ở dropdown trên",
            CurrentValue = hubState.autoKillSelectedMob == true,
            Callback = function(Value: boolean)
                hubState.autoKillSelectedMob = Value
                if Value and currentMode ~= "off" then
                    applyMode("off", false)
                    setStatus("Đang cày quái chọn lọc — Tạm dừng Săn Boss.")
                end
                saveState(hubState)
                pcall(function()
                    genv.Autokillmob = Value
                    genv.start = Value
                    if Value then
                        genv.chonmod = hubState.selectedMob or defaultSelectedMob
                        genv.autocat = hubState.fastMobBring ~= false
                        genv.haki = hubState.autoHaki ~= false
                    end
                end)
            end,
        }, "AutoKillSelectedMobToggle")

        MobSection:CreateToggle({
            Name = "⚡ Gom Quái Nhanh Về Vị Trí Mình (Fast Mob Bring)",
            Description = "Hút quái xung quanh tụ gọn ngay vị trí nhân vật (chạy cả khi Auto Farm, Nguyên Liệu, Dungeon & đánh tay)",
            CurrentValue = hubState.fastMobBring ~= false,
            Callback = function(Value: boolean)
                hubState.fastMobBring = Value
                saveState(hubState)
                pcall(function()
                    genv.autocat = Value
                end)
            end,
        }, "FastMobBringToggle")

        MobSection:CreateSlider({
            Name = "🧲 Phạm Vi Hút Quái Cả Đảo Về Vị Trí Mình (Bring Range)",
            Range = { 100, 1200 },
            Increment = 25,
            Suffix = " studs",
            CurrentValue = hubState.mobBringRange or 800,
            Callback = function(Value: number)
                hubState.mobBringRange = math.clamp(math.floor(Value), 100, 1200)
                saveState(hubState)
                pcall(function()
                    genv.MobBringRange = hubState.mobBringRange
                end)
            end,
        }, "MobBringRangeSlider")

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
