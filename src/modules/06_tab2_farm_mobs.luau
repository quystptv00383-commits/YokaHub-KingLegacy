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
            Description = "Tự teleport tức thì đến NPC nhận quest theo cấp, gom quái và đánh dọn sạch (Teleport Farm)",
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
            Name = "🚀 Tốc Độ Bay Khi Khám Phá & Đánh Boss (Fly Speed)",
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

        local QuestSection = FarmTab:CreateSection("📋 Nhiệm Vụ Hàng Ngày (Daily Quests)")
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

        -- ========================================================
        -- PHÂN MỤC 1: 🎲 QUAY TỘC BẰNG GEMS (CHỈ TỘC ROLL ĐƯỢC)
        -- ========================================================
        local RaceRollSection = FarmTab:CreateSection("🎲 Quay Tộc Bằng Gems (Rollable Races - 35 Gems)")

        local ROLLABLE_RACES = {
            "Animal (Mink) - Siêu Tốc Độ (+10 Walkspeed & Lướt)",
            "Angel (Skypiean) - Nhảy Trên Không Sky Jump & Phòng Thủ",
            "Fish (Fishman) - Bơi Nhanh & Miễn Nhiễm Nước Biển",
            "Human - Tăng Cự Ly & Giảm Hồi Chiêu Flash Step",
        }

        local function getSelectedRollableTarget(): string
            local saved = hubState.targetRollableRace or hubState.targetRace or "Animal"
            for _, opt in ipairs(ROLLABLE_RACES) do
                if string.find(opt, saved, 1, true) ~= nil then
                    return opt
                end
            end
            return ROLLABLE_RACES[1]
        end

        local currentRaceLabel = "Đang kiểm tra..."
        pcall(function()
            local ps = player:FindFirstChild("PlayerStats")
            local r = ps and ps:FindFirstChild("Race") and tostring(ps.Race.Value)
            if not r or r == "" then
                local ro = player:FindFirstChild("Race")
                r = ro and tostring(ro.Value)
            end
            currentRaceLabel = (r and r ~= "") and r or "Chưa rõ"
        end)

        RaceRollSection:CreateParagraph({
            Title = "🧬 Thông Tin Tộc & Tài Nguyên Hiện Tại",
            Text = "• Tộc hiện tại của bạn: " .. currentRaceLabel .. "\n"
                .. "• Chi phí mỗi lượt quay: 35 Gems (tại NPC Hector)\n"
                .. "• ⚠️ Chú ý: Các tộc đặc biệt (Demon, Sea Beast, Cyborg) KHÔNG THỂ QUAY BẰNG GEMS, phải làm nhiệm vụ ở mục bên dưới!",
        })

        RaceRollSection:CreateDropdown({
            Name = "🎯 Chọn Tộc Mong Muốn (Target Rollable Race)",
            Description = "Chỉ bao gồm 4 tộc có thể quay ngẫu nhiên bằng Gems: Animal, Angel, Fish, Human",
            Options = ROLLABLE_RACES,
            CurrentOption = { getSelectedRollableTarget() },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                local rawRace = string.match(val, "^([%w%s]+)") or "Animal"
                rawRace = string.gsub(rawRace, "%s+$", "")
                hubState.targetRollableRace = val
                hubState.targetRace = rawRace
                saveState(hubState)
                safeNotify("YokaHub Tộc", "Đã đặt mục tiêu quay: " .. rawRace, "casino")
            end,
        }, "TargetRollableRaceDropdown")

        local AutoRaceRollToggle = RaceRollSection:CreateToggle({
            Name = "🎲 Tự Động Roll Tộc Bằng Gems (Auto Race Roll)",
            Description = "Tự động quay tộc tại NPC Hector (35 Gems/lần) cho đến khi ra CHÍNH XÁC tộc mong muốn thì tự động ngắt ngay",
            CurrentValue = hubState.autoRaceRoll == true,
            Callback = function(Value: boolean)
                hubState.autoRaceRoll = Value
                saveState(hubState)
                pcall(function()
                    genv.AutoGetAutoRollRace = Value
                    genv.toc = Value
                end)
                if Value then
                    safeNotify("Auto Roll Race", "Đã bật tự động quay tộc! Sẽ dừng ngay khi trúng hoặc hết Gems.", "casino")
                else
                    safeNotify("Auto Roll Race", "Đã dừng quay tộc.", "info")
                end
            end,
        }, "AutoRaceRollToggle")
        genv._YokaRaceRollToggle = AutoRaceRollToggle

        -- ========================================================
        -- PHÂN MỤC 2: ⚔️ TỘC NHIỆM VỤ ĐẶC BIỆT (NON-ROLLABLE RACES)
        -- ========================================================
        local QuestRaceSection = FarmTab:CreateSection("⚔️ Tộc Nhiệm Vụ Đặc Biệt (Non-Rollable: Demon, Sea Beast, Cyborg)")

        QuestRaceSection:CreateParagraph({
            Title = "📜 Hướng Dẫn Điều Kiện Tộc Nhiệm Vụ",
            Text = "• 😈 Demon (Ác Quỷ): Yêu cầu đang là tộc Human. Đến Sea 3 gặp NPC Dravhiel (Land of Detention), tiêu diệt 10 Imprisoned Angels + 100 Angelic Feathers + 5M Beli để lấy V1.\n"
                .. "• 🌊 Sea Beast: Đến Sea 3 gặp NPC Neptunian (Shallow Island), giải câu đố trượt 4x4 để mở khóa V1.\n"
                .. "• 🤖 Cyborg: Yêu cầu Level 3000+. Đến Sea 2 gặp NPC Ferrum (Đảo Fiore), nộp 4500 Iron Ingot, 1500 Rusted Scrap, 10 Lost Ruby, 3 Sea King Fin, 2 Hydra Tail, 1 Dragon Orb.",
        })

        local QUEST_RACES = {
            "😈 Demon (Ác Quỷ - Sea 3 Land of Detention / NPC Dravhiel)",
            "🌊 Sea Beast (Quái Biển - Sea 3 Shallow Island / NPC Neptunian)",
            "🤖 Cyborg (Cơ Giáp - Sea 2 Đảo Fiore / NPC Ferrum)",
        }

        local defaultQuestRace = hubState.questRaceTarget or QUEST_RACES[1]
        QuestRaceSection:CreateDropdown({
            Name = "Chọn Tộc Nhiệm Vụ Muốn Làm",
            Description = "Lựa chọn tộc nhiệm vụ để tự động định vị và bay đến NPC phụ trách",
            Options = QUEST_RACES,
            CurrentOption = { defaultQuestRace },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.questRaceTarget = val
                saveState(hubState)
                safeNotify("Tộc Nhiệm Vụ", "Đã chọn: " .. val, "assignment")
            end,
        }, "QuestRaceTargetDropdown")

        QuestRaceSection:CreateButton({
            Name = "🚀 Bay Ngay Tới NPC Nhận / Nộp Tộc Nhiệm Vụ",
            Description = "Tự động dịch chuyển nhân vật tới NPC nhận nhiệm vụ của tộc đã chọn",
            Callback = function()
                local chosen = hubState.questRaceTarget or QUEST_RACES[1]
                local targetPos: Vector3? = nil
                local targetDesc = ""

                if string.find(chosen, "Demon") then
                    targetPos = Vector3.new(-4800, 42, -5400) -- Land of Detention (NPC Dravhiel)
                    targetDesc = "NPC Dravhiel (Demon Race - Land of Detention)"
                elseif string.find(chosen, "Sea Beast") then
                    targetPos = Vector3.new(2400, 18, 6200) -- Shallow Island (NPC Neptunian)
                    targetDesc = "NPC Neptunian (Sea Beast Race - Shallow Island)"
                elseif string.find(chosen, "Cyborg") then
                    targetPos = Vector3.new(-1800, 45, 1200) -- Fiore Island (NPC Ferrum)
                    targetDesc = "NPC Ferrum (Cyborg Race - Fiore Island)"
                end

                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if targetPos and hrp then
                    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                    safeNotify("Dịch Chuyển", "Đã tới khu vực: " .. targetDesc, "flight_takeoff")
                else
                    safeNotify("Dịch Chuyển", "Không tìm thấy tọa độ NPC!", "warning")
                end
            end,
        }, "TeleportQuestNpcButton")

        -- ========================================================
        -- PHÂN MỤC 3: ⭐ TIẾN HÓA & NÂNG CẤP TỘC (RACE AWAKENING V1 -> V2 -> V3)
        -- ========================================================
        local AwakeningSection = FarmTab:CreateSection("⭐ Tiến Hóa & Nâng Cấp Tộc (Auto Awakening V1 -> V2 -> V3)")

        AwakeningSection:CreateToggle({
            Name = "⭐ Bật Tự Động Nâng Cấp Tộc V2 & V3 (Auto Race Awakening)",
            Description = "Tự động nhận diện tộc hiện tại, tự nộp nguyên liệu lên V2 và bay tới diệt Boss thử thách lên V3",
            CurrentValue = hubState.autoRaceAwakening == true,
            Callback = function(Value: boolean)
                hubState.autoRaceAwakening = Value
                saveState(hubState)
                pcall(function()
                    genv.AutoRaceAwakening = Value
                end)
                if Value then
                    safeNotify("Race Awakening", "Đã bật tự động tiến hóa tộc V2 & V3!", "auto_awesome")
                else
                    safeNotify("Race Awakening", "Đã dừng tự động tiến hóa tộc.", "info")
                end
            end,
        }, "AutoRaceAwakeningToggle")

        local UPGRADE_OPTIONS = {
            "Tự động theo Tộc hiện tại (Auto Detect)",
            "🐰 Animal (Mink) V2 (Bunny Girl) & V3 (Ruvo / Wildclaw)",
            "🐟 Fish (Fishman) V2 (Ata & Peri) & V3 (Abyrus / Morzareth)",
            "😈 Demon V1/V2 (Dravhiel) & V3 (Lilithar / Boss)",
            "🤖 Cyborg V2 (Ferrum) & V3 (Cyborg Architect)",
            "👤 Human V2 & V3",
            "👼 Angel (Skypiean) V2 & V3",
        }

        local defaultUpgradeOpt = hubState.raceAwakeningTarget or UPGRADE_OPTIONS[1]
        AwakeningSection:CreateDropdown({
            Name = "Chọn Lộ Trình Nâng Cấp Tộc",
            Description = "Chọn lộ trình nâng cấp cụ thể hoặc để hệ thống tự nhận diện tộc bạn đang sở hữu",
            Options = UPGRADE_OPTIONS,
            CurrentOption = { defaultUpgradeOpt },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.raceAwakeningTarget = val
                saveState(hubState)
                safeNotify("Nâng Cấp Tộc", "Đã chọn: " .. val, "upgrade")
            end,
        }, "RaceAwakeningTargetDropdown")

        AwakeningSection:CreateButton({
            Name = "🔍 Kiểm Tra Nguyên Liệu Còn Thiếu Cho V2 / V3",
            Description = "Quét kho đồ kiểm tra số lượng Cà rốt, Cá tươi, Máu Sea King, Beli, Feathers... và báo cáo chi tiết",
            Callback = function()
                safeNotify("YokaHub Tộc", "Đang quét túi đồ và nguyên liệu...", "search")
                task.spawn(function()
                    local ps = player:FindFirstChild("PlayerStats")
                    local curRace = ps and ps:FindFirstChild("Race") and tostring(ps.Race.Value) or "Human"
                    local beli = ps and ps:FindFirstChild("Beli") and tonumber(ps.Beli.Value) or 0
                    local gems = ps and ps:FindFirstChild("Gem") and tonumber(ps.Gem.Value) or (ps and ps:FindFirstChild("Gems") and tonumber(ps.Gems.Value) or 0)
                    local lvl = ps and ps:FindFirstChild("lvl") and tonumber(ps.lvl.Value) or 1

                    local report = string.format("Tộc: %s | Level: %d | Beli: %s | Gems: %d", curRace, lvl, tostring(beli), gems)
                    safeNotify("Kiểm Tra Tộc", report, "info")
                end)
            end,
        }, "CheckRaceReqsButton")

        AwakeningSection:CreateToggle({
            Name = "⚡ Tự Bật Kỹ Năng Tộc V3 Khi Đánh Nhau (Phím T)",
            Description = "Tự động kích hoạt chiêu thức buff bá đạo của Tộc V3 (phím T) khi đánh Boss hoặc khi máu tụt dưới 50%",
            CurrentValue = hubState.autoUseRaceSkill ~= false,
            Callback = function(Value: boolean)
                hubState.autoUseRaceSkill = Value
                saveState(hubState)
                pcall(function()
                    genv.AutoUseRaceSkill = Value
                end)
            end,
        }, "AutoUseRaceSkillToggle")
    end
