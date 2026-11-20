    -- ========================================================
    -- TAB 5: VUOT PHO BAN (AUTO DUNGEON & RAID)
    -- ========================================================
    do
        local DungTab = Window:CreateTab({
            Name = "🏰 Vượt Phó Bản",
            Icon = "explore",
            ImageSource = "Material",
            ShowTitle = false,
        })

        local MainDungSection = DungTab:CreateSection("🏰 Tự Động Vượt Phó Bản (Auto Dungeon / Raid)")
        MainDungSection:CreateToggle({
            Name = "🏰 Bật Tự Động Leo Dungeon (Auto Dungeon)",
            Description = "Tự vào vòng tròn Dungeon, bay lên không trung dọn dẹp các đợt quái (Waves)",
            CurrentValue = hubState.autoDungeon,
            Callback = function(Value: boolean)
                hubState.autoDungeon = Value
                if Value and currentMode ~= "off" then
                    applyMode("off", false)
                    setStatus("Đang vượt Dungeon — Tạm dừng Săn Boss.")
                end
                saveState(hubState)
                pcall(function()
                    genv.autodungeon = Value
                    genv.start = Value
                    if Value then
                        genv.DungeonCameraLock = hubState.dungeonCameraLock ~= false
                        genv.DungeonAutoScepterHeal = hubState.dungeonAutoHeal ~= false
                        genv.dungeonmode = string.match(hubState.dungeonMode or "Easy", "^(%a+)") or "Easy"
                    end
                end)
                if Value then safeNotify("YokaHub Dungeon", "Đã bật tự động vượt Dungeon (Đã dừng Hop Boss).", "castle") end
            end,
        }, "AutoDungeonToggle")

        MainDungSection:CreateParagraph({
            Title = "ℹ️ Cách Thức Vận Hành Dungeon",
            Text = "Nhân vật sẽ tự động mua hoặc kích hoạt lượt đi, bay lơ lửng trên không trung, xả chiêu diện rộng tiêu diệt từng đợt quái (Waves 1-30) và Boss cuối.",
        })

        local ModeDungSection = DungTab:CreateSection("🎚️ Lựa Chọn Độ Khó & Chiến Thuật")
        local dungDiffOptions = { "Easy (Dễ - Phù Hợp Cày Nhanh)", "Normal (Thường - Cân Bằng)", "Hard (Khó - Thưởng Lớn)" }
        local defaultDungDiff = dungDiffOptions[1]
        for _, optStr in ipairs(dungDiffOptions) do
            if hubState.dungeonMode and (optStr == hubState.dungeonMode or string.find(optStr, "^" .. tostring(hubState.dungeonMode))) then
                defaultDungDiff = optStr
                break
            end
        end
        ModeDungSection:CreateDropdown({
            Name = "Chọn Độ Khó Dungeon",
            Options = dungDiffOptions,
            CurrentOption = { defaultDungDiff },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.dungeonMode = val
                saveState(hubState)
                pcall(function()
                    genv.dungeonmode = string.match(val, "^(%a+)") or "Easy"
                end)
            end,
        }, "DungeonDifficultyDropdown")

        ModeDungSection:CreateDropdown({
            Name = "Chọn Mode Chiến Thuật Dungeon",
            Options = {
                "🛡️ Safe Mode (Khoảng Cách An Toàn 260m + Hồi Máu)",
                "⚡ Fast Sweep (Quét Xung Cực Nhanh 7m / 4 Pulses)",
                "⚖️ Balanced Mode (Cân Bằng Tốc Độ & An Toàn)",
            },
            CurrentOption = { hubState.dungeonTactics or "🛡️ Safe Mode (Khoảng Cách An Toàn 260m + Hồi Máu)" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.dungeonTactics = val
                saveState(hubState)
                pcall(function()
                    if string.find(val, "Safe") then
                        genv.DungeonBossSafeDistance = 260
                        genv.DungeonBossSafeHeight = 180
                        genv.DungeonSweepHeight = 12
                        genv.DungeonSweepPulses = 3
                        genv.sudungchedoantoan = true
                    elseif string.find(val, "Fast") then
                        genv.DungeonBossSafeDistance = 140
                        genv.DungeonBossSafeHeight = 110
                        genv.DungeonSweepHeight = 7
                        genv.DungeonSweepPulses = 4
                        genv.sudungchedoantoan = false
                    else
                        genv.DungeonBossSafeDistance = 200
                        genv.DungeonBossSafeHeight = 150
                        genv.DungeonSweepHeight = 9
                        genv.DungeonSweepPulses = 3
                        genv.sudungchedoantoan = true
                    end
                end)
            end,
        }, "DungeonTacticsDropdown")

        local ExtraDungSection = DungTab:CreateSection("🩹 Tiện Ích Độc Quyền Dungeon")
        ExtraDungSection:CreateToggle({
            Name = "🪄 Tự Dùng Gậy Scepter Hồi Máu Khi Máu Dưới Ngưỡng",
            Description = "Tự động đổi sang gậy hồi máu khi HP xuống dưới 85%",
            CurrentValue = hubState.dungeonAutoHeal ~= false,
            Callback = function(Value: boolean)
                hubState.dungeonAutoHeal = Value
                saveState(hubState)
                pcall(function()
                    genv.DungeonAutoScepterHeal = Value
                    genv.hpThreshold = 85
                end)
            end,
        }, "DungeonAutoHealToggle")

        ExtraDungSection:CreateToggle({
            Name = "🎥 Khóa Góc Nhìn Camera Vào Quái Dungeon",
            Description = "Cố định camera góc nhìn chuẩn giúp xả skill chính xác tuyệt đối",
            CurrentValue = hubState.dungeonCameraLock ~= false,
            Callback = function(Value: boolean)
                hubState.dungeonCameraLock = Value
                saveState(hubState)
                pcall(function()
                    genv.DungeonCameraLock = Value
                end)
            end,
        }, "DungeonCameraLockToggle")
    end
