    -- ========================================================
    -- TAB 3: XA CHIEU & HAKI (AUTO SKILLS & COMBAT)
    -- ========================================================
    do
        local SkillTab = Window:CreateTab({
            Name = "⚔️ Xả Chiêu & Haki",
            Icon = "flash_on",
            ImageSource = "Material",
            ShowTitle = false,
        })

        -- BIẾN ĐIỀU HƯỚNG ĐỒNG BỘ 2 CHIỀU GIỮA DROPDOWN VÀ TOGGLE
        local isSyncingM1 = false
        local AutoM1SwordToggleObj: any = nil
        local AutoM1MeleeToggleObj: any = nil
        local AutoM1FruitToggleObj: any = nil
        local M1SpamDropdownObj: any = nil

        -- ========================================================
        -- SECTION 1: 👊 CHIẾN ĐẤU & TRANG BỊ VŨ KHÍ (COMBAT ENGINE)
        -- ========================================================
        local CombatSection = SkillTab:CreateSection("👊 Combat")

        CombatSection:CreateDropdown({
            Name = "Tool Mode",
            Description = "Chế độ dùng vũ khí: Auto Mode (tự xoay vòng các vũ khí đã tích), hoặc cố định riêng Sword, Melee, Fruit",
            Options = { "Auto Mode", "Sword", "Melee", "Fruit" },
            CurrentOption = { hubState.toolMode or "Auto Mode" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.toolMode = val
                saveState(hubState)
                safeNotify("Tool Mode", "Đã chọn chế độ: " .. val, "build")
            end,
        }, "ToolModeDropdown")

        CombatSection:CreateToggle({
            Name = "🍎 Use Fruit Transformation",
            Description = "Tự động kích hoạt dạng biến hình của Trái Ác Quỷ khi giao chiến",
            CurrentValue = hubState.autoTransform ~= false,
            Callback = function(Value: boolean)
                hubState.autoTransform = Value
                saveState(hubState)
                pcall(function()
                    genv.bienhinh = Value
                end)
                if Value then
                    safeNotify("Transformation", "Đã bật tự động biến hình Trái Ác Quỷ!", "spa")
                end
            end,
        }, "UseFruitTransformToggle")

        CombatSection:CreateDropdown({
            Name = "🗡️ Skill Sword",
            Description = "Tích chọn các phím kỹ năng Kiếm muốn tự động xả khi chiến đấu",
            Options = { "Z", "X" },
            CurrentOption = (typeof(hubState.swordSkillsList) == "table" and #hubState.swordSkillsList > 0) and hubState.swordSkillsList or { "Z", "X" },
            MultipleOptions = true,
            Callback = function(opts: any)
                local keys = pickMultiDropdownValue(opts)
                hubState.swordSkillsList = keys
                hubState.skillSwordKeys = table.concat(keys, " + ")
                hubState.skillSword = (#keys > 0)
                saveState(hubState)
                pcall(function()
                    genv.CombatSkillSword = keys
                    genv.skillSword = (#keys > 0)
                end)
            end,
        }, "SkillSwordMultiDropdown")

        CombatSection:CreateDropdown({
            Name = "🥊 Skill Melee",
            Description = "Tích chọn các phím kỹ năng Cận chiến / Võ muốn tự động xả khi chiến đấu",
            Options = { "Z", "X", "C", "V" },
            CurrentOption = (typeof(hubState.meleeSkillsList) == "table" and #hubState.meleeSkillsList > 0) and hubState.meleeSkillsList or { "Z", "X", "C", "V" },
            MultipleOptions = true,
            Callback = function(opts: any)
                local keys = pickMultiDropdownValue(opts)
                hubState.meleeSkillsList = keys
                hubState.skillMeleeKeys = table.concat(keys, " + ")
                hubState.skillMelee = (#keys > 0)
                saveState(hubState)
                pcall(function()
                    genv.CombatSkillMelee = keys
                    genv.skillMelee = (#keys > 0)
                end)
            end,
        }, "SkillMeleeMultiDropdown")

        CombatSection:CreateDropdown({
            Name = "🍎 Skill Fruit",
            Description = "Tích chọn các phím kỹ năng Trái Ác Quỷ muốn tự động xả khi chiến đấu",
            Options = { "Z", "X", "C", "V", "E" },
            CurrentOption = (typeof(hubState.fruitSkillsList) == "table" and #hubState.fruitSkillsList > 0) and hubState.fruitSkillsList or { "Z", "X", "C", "E" },
            MultipleOptions = true,
            Callback = function(opts: any)
                local keys = pickMultiDropdownValue(opts)
                hubState.fruitSkillsList = keys
                hubState.skillFruitKeys = table.concat(keys, " + ")
                hubState.skillFruit = (#keys > 0)
                saveState(hubState)
                pcall(function()
                    genv.CombatSkillFruit = keys
                    genv.skillFruit = (#keys > 0)
                end)
            end,
        }, "SkillFruitMultiDropdown")

        -- TÍNH TOÁN LỰA CHỌN M1 HIỆN TẠI TỪ CONFIG (ĐỒNG BỘ 100% TRÁNH LỆCH TOGGLE)
        local initialM1Selections = {}
        if typeof(hubState.m1SpamList) == "table" and #hubState.m1SpamList > 0 then
            for _, item in ipairs(hubState.m1SpamList) do
                table.insert(initialM1Selections, item)
            end
        else
            initialM1Selections = { "Sword M1", "Melee M1", "Fruit M1" }
            hubState.m1SpamList = initialM1Selections
        end
        hubState.autoM1Sword = table.find(initialM1Selections, "Sword M1") ~= nil
        hubState.autoM1Melee = table.find(initialM1Selections, "Melee M1") ~= nil
        hubState.autoM1Fruit = table.find(initialM1Selections, "Fruit M1") ~= nil

        M1SpamDropdownObj = CombatSection:CreateDropdown({
            Name = "⚡ M1 Spam",
            Description = "Tích chọn vũ khí được phép spam M1 siêu tốc. Chỉ vũ khí được tích mới được dùng và xoay vòng!",
            Options = { "Sword M1", "Melee M1", "Fruit M1" },
            CurrentOption = initialM1Selections,
            MultipleOptions = true,
            Callback = function(opts: any)
                if isSyncingM1 then return end
                isSyncingM1 = true
                local selected = pickMultiDropdownValue(opts)
                hubState.m1SpamList = selected
                local hasSword = table.find(selected, "Sword M1") ~= nil
                local hasMelee = table.find(selected, "Melee M1") ~= nil
                local hasFruit = table.find(selected, "Fruit M1") ~= nil

                hubState.autoM1Sword = hasSword
                hubState.autoM1Melee = hasMelee
                hubState.autoM1Fruit = hasFruit

                pcall(function()
                    genv.AutoM1Sword = hasSword
                    genv.AutoM1Melee = hasMelee
                    genv.AutoM1Fruit = hasFruit
                end)
                saveState(hubState)

                if AutoM1SwordToggleObj and AutoM1SwordToggleObj.Set then pcall(function() AutoM1SwordToggleObj:Set({ CurrentValue = hasSword }) end) end
                if AutoM1MeleeToggleObj and AutoM1MeleeToggleObj.Set then pcall(function() AutoM1MeleeToggleObj:Set({ CurrentValue = hasMelee }) end) end
                if AutoM1FruitToggleObj and AutoM1FruitToggleObj.Set then pcall(function() AutoM1FruitToggleObj:Set({ CurrentValue = hasFruit }) end) end
                isSyncingM1 = false
            end,
        }, "M1SpamMultiDropdown")

        -- ========================================================
        -- SECTION 2: 🖱️ TÙY CHỌN M1 RIÊNG LẺ (QUICK TOGGLES)
        -- ========================================================
        local QuickM1Section = SkillTab:CreateSection("🖱️ Tùy Chọn M1 Riêng Lẻ (Bật / Tắt Trực Tiếp)")

        local function syncDropdownFromToggles()
            if isSyncingM1 then return end
            isSyncingM1 = true
            local list = {}
            if hubState.autoM1Sword then table.insert(list, "Sword M1") end
            if hubState.autoM1Melee then table.insert(list, "Melee M1") end
            if hubState.autoM1Fruit then table.insert(list, "Fruit M1") end
            hubState.m1SpamList = list
            saveState(hubState)
            if M1SpamDropdownObj and M1SpamDropdownObj.Set then
                pcall(function()
                    M1SpamDropdownObj:Set({ CurrentOption = list })
                end)
            end
            isSyncingM1 = false
        end

        AutoM1SwordToggleObj = QuickM1Section:CreateToggle({
            Name = "🗡️ Auto M1 Kiếm (Sword M1)",
            Description = "Tích chọn để tự cầm Kiếm và chém thường M1 siêu tốc",
            CurrentValue = hubState.autoM1Sword == true,
            Callback = function(Value: boolean)
                hubState.autoM1Sword = Value
                pcall(function() genv.AutoM1Sword = Value end)
                syncDropdownFromToggles()
                if Value then safeNotify("Auto M1", "Đã bật Auto M1 cho Kiếm (Sword)!", "flash_on") end
            end,
        }, "AutoM1SwordToggle")

        AutoM1MeleeToggleObj = QuickM1Section:CreateToggle({
            Name = "👊 Auto M1 Võ / Melee (Melee M1)",
            Description = "Tích chọn để tự cầm Võ / Melee và đấm thường M1 siêu tốc",
            CurrentValue = hubState.autoM1Melee == true,
            Callback = function(Value: boolean)
                hubState.autoM1Melee = Value
                pcall(function() genv.AutoM1Melee = Value end)
                syncDropdownFromToggles()
                if Value then safeNotify("Auto M1", "Đã bật Auto M1 cho Võ / Melee!", "fitness_center") end
            end,
        }, "AutoM1MeleeToggle")

        AutoM1FruitToggleObj = QuickM1Section:CreateToggle({
            Name = "🍎 Auto M1 Trái Ác Quỷ (Fruit M1)",
            Description = "Tích chọn để tự cầm Trái Ác Quỷ và đánh thường M1 siêu tốc",
            CurrentValue = hubState.autoM1Fruit == true,
            Callback = function(Value: boolean)
                hubState.autoM1Fruit = Value
                pcall(function() genv.AutoM1Fruit = Value end)
                syncDropdownFromToggles()
                if Value then safeNotify("Auto M1", "Đã bật Auto M1 cho Trái Ác Quỷ!", "spa") end
            end,
        }, "AutoM1FruitToggle")

        -- ========================================================
        -- SECTION 3: ⚔️ CÔNG TẮC TỔNG XẢ CHIÊU & SMART HOLD
        -- ========================================================
        local MasterSkillSection = SkillTab:CreateSection("⚔️ Công Tắc Tổng XẢ Chiêu & Thông Minh")
        MasterSkillSection:CreateToggle({
            Name = "⚔️ Tự Xả Chiêu Đánh Quái & Boss (Auto Skills Master)",
            Description = "Bật/Tắt toàn bộ luồng tự động tung chiêu khi đánh quái, đánh boss và đi dungeon",
            CurrentValue = hubState.autoSkills,
            Callback = function(Value: boolean)
                hubState.autoSkills = Value
                saveState(hubState)
                pcall(function()
                    genv.autoskillsea = Value
                end)
                if Value then safeNotify("YokaHub Skills", "Đã kích hoạt tự động xả chiêu!", "flash_on") end
            end,
        }, "AutoSkillsToggle")

        MasterSkillSection:CreateToggle({
            Name = "🧠 Tự Nhận Diện Đè Skill Tối Ưu (Smart Skill Hold)",
            Description = "Tự phân biệt chiêu cần giữ đè để tích sát thương và chiêu bấm nhanh không cần đè, tự bỏ qua chiêu đang hồi",
            CurrentValue = hubState.smartSkillHold ~= false,
            Callback = function(Value: boolean)
                hubState.smartSkillHold = Value
                saveState(hubState)
                pcall(function()
                    genv.SmartSkillHold = Value
                end)
                if Value then
                    safeNotify("Smart Skill Hold", "Đã bật tự động phân biệt chiêu đè & chiêu bấm nhanh!", "auto_awesome")
                end
            end,
        }, "SmartSkillHoldToggle")

        -- ========================================================
        -- SECTION 4: 🛡️ HAKI & VŨ KHÍ TÁC CHIẾN
        -- ========================================================
        local HakiSection = SkillTab:CreateSection("🛡️ Haki & Vũ Khí Tác Chiến")
        HakiSection:CreateToggle({
            Name = "🛡️ Tự Bật Haki Vũ Trang (Busoshoku Haki V1 / V2)",
            Description = "Tự động kích hoạt Haki vũ trang tăng sát thương vật lý",
            CurrentValue = hubState.autoHaki,
            Callback = function(Value: boolean)
                hubState.autoHaki = Value
                saveState(hubState)
                pcall(function()
                    genv.haki = Value
                    genv.hakivutrangv2 = Value
                end)
            end,
        }, "AutoHakiToggle")

        HakiSection:CreateToggle({
            Name = "👁️ Tự Bật Haki Quan Sát (Ken Haki / Kenbunshoku V2)",
            Description = "Tự động bật quan sát né đòn tự động",
            CurrentValue = hubState.autoKenHaki ~= false,
            Callback = function(Value: boolean)
                hubState.autoKenHaki = Value
                saveState(hubState)
                pcall(function()
                    genv.hakiquansatv2 = Value
                end)
            end,
        }, "AutoKenHakiToggle")

        -- ========================================================
        -- SECTION 5: 🎯 AUTO AIM & TỰ NÉ CHIÊU BOSS BẰNG TELEPORT
        -- ========================================================
        local AimSection = SkillTab:CreateSection("🎯 Auto Aim & Tự Né Chiêu Boss Bằng Teleport")
        AimSection:CreateToggle({
            Name = "🎯 Auto Aim Khóa Mục Tiêu (Quái / Boss / Sea Event)",
            Description = "Tự động khóa 100% tâm chiêu & hướng mặt vào Boss, Quái, Sea Event (Mặc định luôn tự aim khi chiến đấu)",
            CurrentValue = hubState.skillAimbot ~= false,
            Callback = function(Value: boolean)
                hubState.skillAimbot = Value
                saveState(hubState)
                pcall(function()
                    genv.PlayerAimbotEnabled = Value
                    genv.PlayerAimMode = "Skill Direction"
                    genv.PlayerAimRange = 650
                end)
            end,
        }, "SkillAimbotToggle")

        AimSection:CreateToggle({
            Name = "⚡ Tự Né Chiêu Boss Bằng Teleport (Dự Đoán Tầm AOE)",
            Description = "Dự đoán tầm chiêu & hiệu ứng AOE của Boss/Sea Event rồi tự Teleport né ra ngoài tầm an toàn thay vì dash",
            CurrentValue = hubState.autoDodge ~= false,
            Callback = function(Value: boolean)
                hubState.autoDodge = Value
                saveState(hubState)
                pcall(function()
                    genv.autoDodgeEnabled = Value
                end)
            end,
        }, "AutoDodgeToggle")

        AimSection:CreateSlider({
            Name = "📏 Tầm Tele Né Chiêu Boss An Toàn (Dodge Range)",
            Range = { 40, 180 },
            Increment = 5,
            Suffix = " studs",
            CurrentValue = hubState.dodgeSafeDistance or 95,
            Callback = function(Value: number)
                hubState.dodgeSafeDistance = math.clamp(math.floor(Value), 40, 180)
                saveState(hubState)
                pcall(function()
                    genv.DodgeSafeDistance = hubState.dodgeSafeDistance
                end)
            end,
        }, "DodgeSafeDistanceSlider")
    end
