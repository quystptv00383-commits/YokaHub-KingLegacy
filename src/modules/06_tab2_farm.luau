    -- ========================================================
    -- TAB 2: TU DONG FARM (INTEGRATED FROM WUKONG ENGINE)
    -- ========================================================
    do
        local FarmTab = Window:CreateTab({
            Name = "Tự Động Farm",
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
                    safeNotify("YokaHub Farm", "Đã tắt Farm Level.", "info")
                end
            end,
        }, "AutoLevelToggle")

        LevelSection:CreateToggle({
            Name = "⚔️ Tự Xả Chiêu Đánh Quái (Tổng Hợp Auto Skills)",
            Description = "Công tắc tổng bật/tắt toàn bộ tính năng tự xả chiêu khi farm quái & boss",
            CurrentValue = hubState.autoSkills,
            Callback = function(Value: boolean)
                hubState.autoSkills = Value
                saveState(hubState)
                pcall(function()
                    genv.opeskill = Value
                    genv.autoskillsea = Value
                end)
                if Value then safeNotify("YokaHub Skills", "Đã bật tự động xả chiêu!", "flash_on") end
            end,
        }, "AutoSkillsToggle")

        LevelSection:CreateToggle({
            Name = "🍎 Xả Skill Trái Ác Quỷ (Fruit Skills)",
            Description = "Tự động kích hoạt các chiêu thức của Trái Ác Quỷ đang dùng",
            CurrentValue = hubState.skillFruit,
            Callback = function(Value: boolean)
                hubState.skillFruit = Value
                saveState(hubState)
                pcall(function()
                    if Value then
                        if hubState.skillFruitKeys == "Z + X" then genv.CombatSkillFruit = {"Z", "X"}
                        elseif hubState.skillFruitKeys == "Z + X + C" then genv.CombatSkillFruit = {"Z", "X", "C"}
                        elseif hubState.skillFruitKeys == "Z + X + C + V" then genv.CombatSkillFruit = {"Z", "X", "C", "V"}
                        else genv.CombatSkillFruit = {"Z", "X", "C", "V", "E"} end
                    else
                        genv.CombatSkillFruit = {}
                    end
                end)
            end,
        }, "SkillFruitToggle")

        LevelSection:CreateDropdown({
            Name = "Chọn Phím Skill Trái Muốn Xả",
            Options = { "Z + X", "Z + X + C", "Z + X + C + V", "Toàn Bộ (Z, X, C, V, E)" },
            CurrentOption = { hubState.skillFruitKeys or "Z + X" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.skillFruitKeys = val
                saveState(hubState)
                pcall(function()
                    if hubState.skillFruit then
                        if val == "Z + X" then genv.CombatSkillFruit = {"Z", "X"}
                        elseif val == "Z + X + C" then genv.CombatSkillFruit = {"Z", "X", "C"}
                        elseif val == "Z + X + C + V" then genv.CombatSkillFruit = {"Z", "X", "C", "V"}
                        else genv.CombatSkillFruit = {"Z", "X", "C", "V", "E"} end
                    end
                end)
            end,
        }, "SkillFruitKeysDropdown")

        LevelSection:CreateToggle({
            Name = "🗡️ Xả Skill Kiếm (Sword Skills)",
            Description = "Tự động chém các chiêu kiếm đang cầm trên tay",
            CurrentValue = hubState.skillSword,
            Callback = function(Value: boolean)
                hubState.skillSword = Value
                saveState(hubState)
                pcall(function()
                    if Value then
                        if hubState.skillSwordKeys == "Z + X" then genv.CombatSkillSword = {"Z", "X"}
                        elseif hubState.skillSwordKeys == "Chỉ Phím Z" then genv.CombatSkillSword = {"Z"}
                        elseif hubState.skillSwordKeys == "Chỉ Phím X" then genv.CombatSkillSword = {"X"}
                        else genv.CombatSkillSword = {"Z", "X"} end
                    else
                        genv.CombatSkillSword = {}
                    end
                end)
            end,
        }, "SkillSwordToggle")

        LevelSection:CreateDropdown({
            Name = "Chọn Phím Skill Kiếm Muốn Xả",
            Options = { "Z + X", "Chỉ Phím Z", "Chỉ Phím X" },
            CurrentOption = { hubState.skillSwordKeys or "Z + X" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.skillSwordKeys = val
                saveState(hubState)
                pcall(function()
                    if hubState.skillSword then
                        if val == "Z + X" then genv.CombatSkillSword = {"Z", "X"}
                        elseif val == "Chỉ Phím Z" then genv.CombatSkillSword = {"Z"}
                        elseif val == "Chỉ Phím X" then genv.CombatSkillSword = {"X"}
                        else genv.CombatSkillSword = {"Z", "X"} end
                    end
                end)
            end,
        }, "SkillSwordKeysDropdown")

        LevelSection:CreateToggle({
            Name = "👊 Xả Skill Võ / Melee (Melee Skills)",
            Description = "Tự động thi triển các chiêu đấm võ cận chiến",
            CurrentValue = hubState.skillMelee,
            Callback = function(Value: boolean)
                hubState.skillMelee = Value
                saveState(hubState)
                pcall(function()
                    if Value then
                        if hubState.skillMeleeKeys == "Toàn Bộ (Z, X, C, V, E)" then genv.CombatSkillMelee = {"Z", "X", "C", "V", "E"}
                        elseif hubState.skillMeleeKeys == "Z + X + C" then genv.CombatSkillMelee = {"Z", "X", "C"}
                        else genv.CombatSkillMelee = {"Z", "X"} end
                    else
                        genv.CombatSkillMelee = {}
                    end
                end)
            end,
        }, "SkillMeleeToggle")

        LevelSection:CreateDropdown({
            Name = "Chọn Phím Skill Võ Muốn Xả",
            Options = { "Toàn Bộ (Z, X, C, V, E)", "Z + X + C", "Z + X" },
            CurrentOption = { hubState.skillMeleeKeys or "Toàn Bộ (Z, X, C, V, E)" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.skillMeleeKeys = val
                saveState(hubState)
                pcall(function()
                    if hubState.skillMelee then
                        if val == "Toàn Bộ (Z, X, C, V, E)" then genv.CombatSkillMelee = {"Z", "X", "C", "V", "E"}
                        elseif val == "Z + X + C" then genv.CombatSkillMelee = {"Z", "X", "C"}
                        else genv.CombatSkillMelee = {"Z", "X"} end
                    end
                end)
            end,
        }, "SkillMeleeKeysDropdown")

        LevelSection:CreateToggle({
            Name = "🛡️ Tự Bật Haki Vũ Trang & Quan Sát",
            Description = "Tự động kích hoạt Haki để tăng sát thương và tránh né đòn",
            CurrentValue = hubState.autoHaki,
            Callback = function(Value: boolean)
                hubState.autoHaki = Value
                saveState(hubState)
                pcall(function()
                    genv.haki = Value
                    genv.hakivutrangv2 = Value
                    genv.hakiquansatv2 = Value
                end)
            end,
        }, "AutoHakiToggle")

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

        LevelSection:CreateToggle({
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

        LevelSection:CreateToggle({
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

        local MatSection = FarmTab:CreateSection("📦 Gom Nguyên Liệu Tự Động (Chọn Nguyên Liệu Cụ Thể)")
        MatSection:CreateToggle({
            Name = "🌊 Bật Gom Nguyên Liệu Sea 3",
            Description = "Tự động farm nguyên liệu đã chọn bên dưới tại Sea 3",
            CurrentValue = hubState.farmSea3Mat,
            Callback = function(Value: boolean)
                hubState.farmSea3Mat = Value
                if Value then
                    hubState.farmSea2Mat = false
                    hubState.farmSea1Mat = false
                    if currentMode ~= "off" then applyMode("off", false) end
                    if game.PlaceId ~= SEA3_PLACE then
                        safeNotify("Lệch Sea", "Đang chuyển sang Sea 3 để gom nguyên liệu...", "public")
                        ensureCorrectSea(SEA3_PLACE, "Nguyên Liệu Sea 3", "Lệch Sea", "coral")
                    end
                end
                saveState(hubState)
                pcall(function()
                    genv.farmMaterialsea3 = Value
                    if Value then
                        genv.farmMaterialsea2 = false
                        genv.farmMaterialsea1 = false
                    end
                end)
            end,
        }, "FarmSea3MatToggle")

        MatSection:CreateDropdown({
            Name = "Chọn Nguyên Liệu Sea 3 Muốn Farm",
            Options = { "Coral (San Hô)", "Shark's Fin (Vây Cá Mập)", "Dragon Scale (Vảy Rồng)", "Sea King's Blood (Máu Vua Biển)", "Phoenix Tear (Nước Mắt Phượng)", "Off (Tắt)" },
            CurrentOption = { hubState.nguyenlieuSea3 or "Coral (San Hô)" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.nguyenlieuSea3 = val
                saveState(hubState)
                pcall(function()
                    local clean = val:match("^([^(]+)") or val
                    genv.nguyenlieusea3 = clean:match("^%s*(.-)%s*$")
                end)
                safeNotify("Nguyên Liệu Sea 3", "Đã chọn: " .. val, "inventory_2")
            end,
        }, "NguyenLieuSea3Dropdown")

        MatSection:CreateToggle({
            Name = "🐋 Bật Gom Nguyên Liệu Sea 2",
            Description = "Tự động farm nguyên liệu đã chọn bên dưới tại Sea 2",
            CurrentValue = hubState.farmSea2Mat,
            Callback = function(Value: boolean)
                hubState.farmSea2Mat = Value
                if Value then
                    hubState.farmSea3Mat = false
                    hubState.farmSea1Mat = false
                    if currentMode ~= "off" then applyMode("off", false) end
                    if game.PlaceId ~= SEA2_PLACE then
                        safeNotify("Lệch Sea", "Đang chuyển sang Sea 2 để gom nguyên liệu...", "public")
                        ensureCorrectSea(SEA2_PLACE, "Nguyên Liệu Sea 2", "Lệch Sea", "iron")
                    end
                end
                saveState(hubState)
                pcall(function()
                    genv.farmMaterialsea2 = Value
                    if Value then
                        genv.farmMaterialsea3 = false
                        genv.farmMaterialsea1 = false
                    end
                end)
            end,
        }, "FarmSea2MatToggle")

        MatSection:CreateDropdown({
            Name = "Chọn Nguyên Liệu Sea 2 Muốn Farm",
            Options = { "Iron Ingot (Sắt Thỏi)", "Dark Powder (Bột Hắc Ám)", "Ghost Flesh (Thịt Ma)", "Magma Crystal (Pha Lê Dung Nham)", "Off (Tắt)" },
            CurrentOption = { hubState.nguyenlieuSea2 or "Iron Ingot (Sắt Thỏi)" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.nguyenlieuSea2 = val
                saveState(hubState)
                pcall(function()
                    local clean = val:match("^([^(]+)") or val
                    genv.nguyenlieusea2 = clean:match("^%s*(.-)%s*$")
                end)
                safeNotify("Nguyên Liệu Sea 2", "Đã chọn: " .. val, "inventory_2")
            end,
        }, "NguyenLieuSea2Dropdown")

        MatSection:CreateToggle({
            Name = "🏝️ Bật Gom Nguyên Liệu Sea 1",
            Description = "Tự động farm nguyên liệu đã chọn bên dưới tại Sea 1",
            CurrentValue = hubState.farmSea1Mat,
            Callback = function(Value: boolean)
                hubState.farmSea1Mat = Value
                if Value then
                    hubState.farmSea3Mat = false
                    hubState.farmSea2Mat = false
                    if currentMode ~= "off" then applyMode("off", false) end
                    if game.PlaceId ~= SEA1_PLACE then
                        safeNotify("Lệch Sea", "Đang chuyển sang Sea 1 để gom nguyên liệu...", "public")
                        ensureCorrectSea(SEA1_PLACE, "Nguyên Liệu Sea 1", "Lệch Sea", "leather")
                    end
                end
                saveState(hubState)
                pcall(function()
                    genv.farmMaterialsea1 = Value
                    if Value then
                        genv.farmMaterialsea3 = false
                        genv.farmMaterialsea2 = false
                    end
                end)
            end,
        }, "FarmSea1MatToggle")

        MatSection:CreateDropdown({
            Name = "Chọn Nguyên Liệu Sea 1 Muốn Farm",
            Options = { "Leather (Da Thuộc)", "Wood (Gỗ)", "Rope (Dây Thừng)", "Thief Rag (Vải Rách)", "Off (Tắt)" },
            CurrentOption = { hubState.nguyenlieuSea1 or "Leather (Da Thuộc)" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.nguyenlieuSea1 = val
                saveState(hubState)
                pcall(function()
                    local clean = val:match("^([^(]+)") or val
                    genv.nguyenlieusea1 = clean:match("^%s*(.-)%s*$")
                end)
                safeNotify("Nguyên Liệu Sea 1", "Đã chọn: " .. val, "inventory_2")
            end,
        }, "NguyenLieuSea1Dropdown")

        local DungSection = FarmTab:CreateSection("🏰 Tự Động Vượt Phó Bản (Auto Dungeon / Raid)")
        DungSection:CreateToggle({
            Name = "🏰 Bật Auto Dungeon / Raid",
            Description = "Tự động vào phòng, quét từng đợt quái và hồi máu an toàn",
            CurrentValue = hubState.autoDungeon,
            Callback = function(Value: boolean)
                hubState.autoDungeon = Value
                saveState(hubState)
                pcall(function() genv.autodungeon = Value end)
                if Value then safeNotify("Dungeon", "Đã bật Auto Dungeon!", "fort") end
            end,
        }, "AutoDungeonToggle")

        DungSection:CreateDropdown({
            Name = "Chọn Độ Khó Dungeon",
            Options = { "Easy", "Normal", "Hard" },
            CurrentOption = { hubState.dungeonMode or "Easy" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.dungeonMode = val
                saveState(hubState)
                pcall(function() genv.dungeonmode = val end)
            end,
        }, "DungeonModeDropdown")

        DungSection:CreateDropdown({
            Name = "Chọn Mode Chiến Thuật Dungeon",
            Options = {
                "🛡️ Safe Mode (Khoảng Cách An Toàn 260m + Hồi Máu)",
                "⚡ Fast Sweep (Càn Quét Tốc Độ Cao)",
                "⚖️ Balanced Mode (Cân Bằng Sinh Tồn & Tốc Độ)",
            },
            CurrentOption = { hubState.dungeonTactics or "🛡️ Safe Mode (Khoảng Cách An Toàn 260m + Hồi Máu)" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.dungeonTactics = val
                saveState(hubState)
                pcall(function()
                    if string.find(val, "Safe") then
                        genv.DungeonBossSafeHeight = 180
                        genv.DungeonBossSafeDistance = 260
                        genv.DungeonSweepPulses = 2
                    elseif string.find(val, "Fast") then
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
                end)
                safeNotify("Dungeon Tactics", "Đã chuyển sang: " .. val, "shield")
            end,
        }, "DungeonTacticsDropdown")

        DungSection:CreateToggle({
            Name = "🪄 Tự Động Cầm Gậy Hồi Máu (Auto Scepter Heal)",
            Description = "Tự chuyển sang quyền trượng để hồi máu khi lượng HP xuống thấp",
            CurrentValue = hubState.dungeonAutoHeal,
            Callback = function(Value: boolean)
                hubState.dungeonAutoHeal = Value
                saveState(hubState)
                pcall(function() genv.DungeonAutoScepterHeal = Value end)
            end,
        }, "DungeonAutoHealToggle")

        DungSection:CreateToggle({
            Name = "🎥 Khóa Camera Góc Nhìn Dungeon (Camera Lock)",
            Description = "Tự động khóa góc nhìn vào Boss hoặc quái để xả chiêu chính xác 100%",
            CurrentValue = hubState.dungeonCameraLock,
            Callback = function(Value: boolean)
                hubState.dungeonCameraLock = Value
                saveState(hubState)
                pcall(function() genv.DungeonCameraLock = Value end)
            end,
        }, "DungeonCameraLockToggle")

        -- ========================================================
        -- SECTION: AUTO FISHING (CÂU CÁ TỰ ĐỘNG)
        -- ========================================================
        local FishSection = FarmTab:CreateSection("🎣 Tự Động Câu Cá (Auto Fishing)")
        FishSection:CreateToggle({
            Name = "🎣 Bật Auto Câu Cá Tự Động (Auto Fish)",
            Description = "Tự động cầm cần/kiếm câu cá, ném mồi và giật cần thu hoạch khi cá cắn",
            CurrentValue = hubState.autoFish,
            Callback = function(Value: boolean)
                hubState.autoFish = Value
                saveState(hubState)
                pcall(function()
                    genv.AutoFish = Value
                    if hubState.fishWeapon then genv.kiemmacauca = hubState.fishWeapon end
                end)
                if Value then
                    safeNotify("YokaHub Fishing", "Đã bật Auto Câu Cá! Vui lòng đứng gần mép nước.", "phishing")
                else
                    safeNotify("YokaHub Fishing", "Đã dừng Auto Câu Cá.", "info")
                end
            end,
        }, "AutoFishToggle")

        FishSection:CreateDropdown({
            Name = "Chọn Kiếm / Cần Câu Cá (Fish Rod / Weapon)",
            Options = {
                "True Muramasa",
                "Muramasa",
                "Authentic Triple Katana",
                "Golden Staff",
                "Fishing Rod (Cần Câu Mặc Định)",
            },
            CurrentOption = { hubState.fishWeapon or "True Muramasa" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.fishWeapon = val
                saveState(hubState)
                pcall(function() genv.kiemmacauca = val end)
                safeNotify("Vũ Khí Câu Cá", "Đã chọn: " .. val, "handyman")
            end,
        }, "FishWeaponDropdown")

        FishSection:CreateToggle({
            Name = "🌊 Nổi / Đứng Trên Mặt Nước Khi Câu (Water Float)",
            Description = "Giữ nhân vật lơ lửng trên mặt nước không bị chìm hoặc mất máu khi ra khơi câu cá",
            CurrentValue = hubState.fishFloat,
            Callback = function(Value: boolean)
                hubState.fishFloat = Value
                saveState(hubState)
            end,
        }, "FishFloatToggle")
    end

