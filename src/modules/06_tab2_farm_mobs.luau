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
        local AutoLevelToggle = LevelSection:CreateToggle({
            Name = "🌾 Bật Farm Level Tự Động",
            Description = "Tự bay đến NPC nhận quest theo cấp, gom quái và đánh dọn sạch",
            CurrentValue = hubState.autoLevel,
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.autoLevel = Value
                if Value then
                    deactivateOtherLocalModes("autoLevel")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang cày cấp độ trong phòng hiện tại — Tạm dừng Săn Boss.")
                    end
                end
                saveState(hubState)
                pcall(function()
                    if Value then
                        genv.autocat = hubState.fastMobBring ~= false
                        genv.haki = hubState.autoHaki ~= false
                    end
                end)
                if Value then
                    safeNotify("YokaHub Farm", "Đã bật Farm Level tự động (Đã tự tắt các chế độ cày trùng lặp).", "agriculture")
                else
                    safeNotify("YokaHub Farm", "Đã tắt Farm Level.", "pause_circle")
                end
            end,
        }, "AutoLevelToggle")
        registerLocalModeToggle("autoLevel", AutoLevelToggle)

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

        LevelSection:CreateToggle({
            Name = "🐍 Tự Về Sea 2 Săn & Nhặt Rương Hydra Khi Max Level",
            Description = "Tự động phát hiện khi đạt cấp tối đa (Lv 5450), tắt cày level, dịch chuyển về Sea 2 và treo Hop API nhặt rương Hydra",
            CurrentValue = (hubState.autoMaxLevelHydra ~= false),
            Callback = function(Value: boolean)
                hubState.autoMaxLevelHydra = Value
                saveState(hubState)
                if Value then safeNotify("YokaHub Farm", "Đã bật: Đạt Max Level (5450) sẽ tự động về Sea 2 nhặt rương Hydra!", "military_tech") end
            end,
        }, "AutoMaxLevelHydraToggle")

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
        local function scanCurrentSeaMobOptions(): { string }
            local list: { string } = {}
            local seen: { [string]: boolean } = {}
            local mon = workspace:FindFirstChild("Monster")
            if mon then
                for _, subName in ipairs({ "Mon", "Boss" }) do
                    local sub = mon:FindFirstChild(subName)
                    if sub then
                        for _, m in ipairs(sub:GetChildren()) do
                            if m:IsA("Model") and not seen[m.Name] then
                                seen[m.Name] = true
                                table.insert(list, m.Name)
                            end
                        end
                    end
                end
                for _, m in ipairs(mon:GetChildren()) do
                    if m:IsA("Model") and not seen[m.Name] and m.Name ~= "Mon" and m.Name ~= "Boss" then
                        seen[m.Name] = true
                        table.insert(list, m.Name)
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
                        "Elite Skeleton [Lv. 3100]",
                        "High-class Soldier [Lv. 4000]",
                        "Sea King Warrior [Lv. 4200]",
                        "Ocean Gladiator [Lv. 4500]",
                    }
                elseif game.PlaceId == SEA2_PLACE then
                    list = {
                        "Fishman Raider [Lv. 1500]",
                        "Quake Woman [Lv. 1925]",
                        "Sea Soldier [Lv. 2250]",
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
                        "Desert Bandit [Lv. 100]",
                        "Shark Man [Lv. 230]",
                        "Pirate Guard [Lv. 500]",
                        "Rumble Man [Lv. 950]",
                        "Leader [Lv. 1100]",
                    }
                end
            end
            return list
        end

        local mobOptions = scanCurrentSeaMobOptions()
        local defaultSelectedMob = table.find(mobOptions, hubState.selectedMob) and hubState.selectedMob or mobOptions[1]
        local SelectMobDropdownObj = MobSection:CreateDropdown({
            Name = "👾 Chọn Quái Muốn Cày (Tự quét đúng Sea hiện tại)",
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

        MobSection:CreateButton({
            Name = "🔄 Tải Lại Danh Sách Quái Trong Sea Này",
            Description = "Quét lại toàn bộ quái & boss đảo đang có mặt trong server hiện tại",
            Callback = function()
                local fresh = scanCurrentSeaMobOptions()
                pcall(function()
                    if SelectMobDropdownObj and typeof(SelectMobDropdownObj.Set) == "function" then
                        SelectMobDropdownObj:Set({ Options = fresh, CurrentOption = { fresh[1] } })
                    end
                end)
                hubState.selectedMob = fresh[1]
                saveState(hubState)
                safeNotify("YokaHub Farm", "Đã cập nhật " .. tostring(#fresh) .. " loại quái trong Sea hiện tại!", "refresh")
            end,
        })

        local AutoKillSelectedMobToggle = MobSection:CreateToggle({
            Name = "⚔️ Bật Cày Quái Đã Chọn",
            Description = "Tập trung đánh loại quái được chọn ở dropdown trên",
            CurrentValue = hubState.autoKillSelectedMob == true,
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.autoKillSelectedMob = Value
                if Value then
                    deactivateOtherLocalModes("autoKillSelectedMob")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang cày quái chọn lọc — Tạm dừng Săn Boss.")
                    end
                end
                saveState(hubState)
                pcall(function()
                    if Value then
                        genv.chonmod = hubState.selectedMob or defaultSelectedMob
                        genv.autocat = hubState.fastMobBring ~= false
                        genv.haki = hubState.autoHaki ~= false
                    end
                end)
            end,
        }, "AutoKillSelectedMobToggle")
        registerLocalModeToggle("autoKillSelectedMob", AutoKillSelectedMobToggle)

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

        local RACE_OPTIONS = { "Cyborg", "Fishman", "Mink", "Skypiean", "Human" }
        local defaultRace = table.find(RACE_OPTIONS, hubState.targetRace) and hubState.targetRace or RACE_OPTIONS[1]
        QuestSection:CreateDropdown({
            Name = "🧬 Chọn Tộc Muốn Quay (Target Race)",
            Options = RACE_OPTIONS,
            CurrentOption = { defaultRace },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.targetRace = val
                saveState(hubState)
                safeNotify("YokaHub Tộc", "Đã chọn tộc mục tiêu: " .. val, "dna")
            end,
        }, "TargetRaceDropdown")

        local AutoRaceRollToggle = QuestSection:CreateToggle({
            Name = "🧬 Tự Động Roll Tộc Mong Muốn (Auto Race Roll)",
            Description = "Tự động quay tộc bằng Gems cho đến khi ra tộc mong muốn đã chọn",
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
        genv._YokaRaceRollToggle = AutoRaceRollToggle
    end
