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

        local MasterSkillSection = SkillTab:CreateSection("⚔️ Công Tắc Tổng Xả Chiêu")
        MasterSkillSection:CreateToggle({
            Name = "⚔️ Tự Xả Chiêu Đánh Quái & Boss (Auto Skills Master)",
            Description = "Bật/Tắt toàn bộ luồng tự động tung chiêu khi đánh quái, đánh boss và đi dungeon",
            CurrentValue = hubState.autoSkills,
            Callback = function(Value: boolean)
                hubState.autoSkills = Value
                saveState(hubState)
                pcall(function()
                    genv.opeskill = Value
                    genv.autoskillsea = Value
                end)
                if Value then safeNotify("YokaHub Skills", "Đã kích hoạt tự động xả chiêu!", "flash_on") end
            end,
        }, "AutoSkillsToggle")

        local FruitSkillSection = SkillTab:CreateSection("🍎 Kỹ Năng Trái Ác Quỷ (Fruit Skills)")
        FruitSkillSection:CreateToggle({
            Name = "🍎 Xả Skill Trái Ác Quỷ",
            Description = "Tự động thi triển các chiêu thức của Trái Ác Quỷ đang dùng",
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

        FruitSkillSection:CreateDropdown({
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

        local SwordSkillSection = SkillTab:CreateSection("🗡️ Kỹ Năng Kiếm (Sword Skills)")
        SwordSkillSection:CreateToggle({
            Name = "🗡️ Xả Skill Kiếm",
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

        SwordSkillSection:CreateDropdown({
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

        local MeleeSkillSection = SkillTab:CreateSection("👊 Kỹ Năng Võ / Melee (Melee Skills)")
        MeleeSkillSection:CreateToggle({
            Name = "👊 Xả Skill Võ / Melee",
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

        MeleeSkillSection:CreateDropdown({
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
            CurrentValue = true,
            Callback = function(Value: boolean)
                pcall(function()
                    genv.hakiquansatv2 = Value
                end)
            end,
        }, "AutoKenHakiToggle")

        HakiSection:CreateToggle({
            Name = "⚡ Tự Động Biến Hình (Auto Transform)",
            Description = "Tự động kích hoạt dạng biến hình của Trái Ác Quỷ khi giao chiến",
            CurrentValue = true,
            Callback = function(Value: boolean)
                pcall(function()
                    genv.bienhinh = Value
                end)
            end,
        }, "AutoTransformToggle")

        local AimSection = SkillTab:CreateSection("🎯 Hỗ Trợ Tác Chiến & Né Đòn (Aimbot & Dodge)")
        AimSection:CreateToggle({
            Name = "🎯 Khóa Chiêu Vào Mục Tiêu (Skill Direction Aimbot)",
            Description = "Tự động xoay người và hướng chiêu thẳng vào tim boss hoặc quái",
            CurrentValue = true,
            Callback = function(Value: boolean)
                pcall(function()
                    genv.PlayerAimbotEnabled = Value
                    genv.PlayerAimMode = "Skill Direction"
                    genv.PlayerAimRange = 350
                end)
            end,
        }, "SkillAimbotToggle")

        AimSection:CreateToggle({
            Name = "💨 Tự Động Lướt Né Chiêu (Auto Dodge)",
            Description = "Tự động lướt né khi quái vật hoặc boss vận chiêu diện rộng",
            CurrentValue = true,
            Callback = function(Value: boolean)
                pcall(function()
                    genv.autoDodgeEnabled = Value
                end)
            end,
        }, "AutoDodgeToggle")
    end
