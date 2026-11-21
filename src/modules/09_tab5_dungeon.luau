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

        -- --------------------------------------------------------
        -- PHẦN 1: BẢNG ĐIỀU KHIỂN CHÍNH (MASTER AUTO DUNGEON)
        -- --------------------------------------------------------
        local MainDungSection = DungTab:CreateSection("🏰 BẢNG ĐIỀU KHIỂN CHÍNH (MASTER AUTO DUNGEON)")

        local DungStatusParagraph = MainDungSection:CreateParagraph({
            Title = "📊 TRẠNG THÁI PHÓ BẢN (LIVE DUNGEON STATUS)",
            Text = "🏰 Trạng Thái: Đang sẵn sàng\n⚔️ Tiến Độ: Chờ bắt đầu | Quái còn lại: 0\n⏱️ Thời Gian: 00:00:00 | Số trận đã vượt: 0",
        })

        -- Luồng ngầm cập nhật trực tiếp bảng trạng thái Live
        task.spawn(function()
            local startTime = os.clock()
            while task.wait(1.0) do
                pcall(function()
                    if DungStatusParagraph and DungStatusParagraph.Set then
                        local st = tostring(genv.DungeonStatus or "Đang chờ lệnh")
                        local wv = tostring(genv.DungeonCurrentWave or "Chờ Bắt Đầu")
                        local cnt = tonumber(genv.DungeonMobsCount) or 0
                        local clr = tonumber(genv.DungeonClearedCount) or 0
                        local elapsed = math.floor(os.clock() - startTime)
                        local timeStr = string.format("%02d:%02d:%02d", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60)
                        local newText = string.format("🏰 Trạng Thái: %s\n⚔️ Đợt Quái: %s | Quái còn lại: %d con\n⏱️ Thời Gian: %s | Đã hoàn thành: %d trận", st, wv, cnt, timeStr, clr)
                        DungStatusParagraph:Set({
                            Title = "📊 TRẠNG THÁI PHÓ BẢN (LIVE DUNGEON STATUS)",
                            Text = newText,
                        })
                    end
                end)
            end
        end)

        local AutoDungeonToggle = MainDungSection:CreateToggle({
            Name = "🏰 Bật Tự Động Vượt Phó Bản (Master Auto Dungeon)",
            Description = "Tự động vào sảnh/cổng, bay lơ lửng né đòn, gom quái đợt wave và xả trọn bộ skill diệt từ Wave 1 đến Wave 30",
            CurrentValue = hubState.autoDungeon,
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.autoDungeon = Value
                if Value then
                    deactivateOtherLocalModes("autoDungeon")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang vượt Dungeon — Tạm dừng Săn Boss.")
                    end
                end
                saveState(hubState)
                pcall(function()
                    if Value then
                        genv.DungeonCameraLock = (hubState.dungeonCameraLock == true)
                        genv.DungeonAutoScepterHeal = (hubState.dungeonAutoHeal ~= false)
                        genv.dungeonmode = string.match(hubState.dungeonMode or "Easy", "^(%a+)") or "Easy"
                    end
                end)
                if Value then
                    safeNotify("YokaHub Dungeon", "Đã bật tự động vượt Dungeon (Đã dừng các chế độ khác).", "castle")
                else
                    safeNotify("YokaHub Dungeon", "Đã dừng tự động vượt Dungeon.", "info")
                end
            end,
        }, "AutoDungeonToggle")
        registerLocalModeToggle("autoDungeon", AutoDungeonToggle)

        MainDungSection:CreateToggle({
            Name = "🚪 Tự Động Vào Vòng Tròn / Kích Hoạt Cổng (Auto Join Gate)",
            Description = "Tự động bay vào vòng tròn phó bản hoặc bấm phím tương tác NPC Dungeon khi đứng ở sảnh",
            CurrentValue = (hubState.dungeonAutoJoin ~= false),
            Callback = function(Value: boolean)
                hubState.dungeonAutoJoin = Value
                saveState(hubState)
            end,
        }, "DungeonAutoJoinToggle")

        MainDungSection:CreateToggle({
            Name = "🔁 Tự Động Đi Lại Vòng Mới Liên Tục (Auto Infinite Loop)",
            Description = "Khi kết thúc phó bản (Thắng hoặc Thua), tự động thu nhặt quà và xếp hàng vào trận mới để treo máy 24/7",
            CurrentValue = (hubState.dungeonAutoReplay ~= false),
            Callback = function(Value: boolean)
                hubState.dungeonAutoReplay = Value
                saveState(hubState)
                if Value then
                    safeNotify("YokaHub Dungeon", "Đã bật chế độ lặp vô tận (Auto Infinite Replay)!", "repeat")
                end
            end,
        }, "DungeonAutoReplayToggle")

        MainDungSection:CreateToggle({
            Name = "💎 Tự Động Thu Thập Rương Thưởng (Auto Collect Chests)",
            Description = "Tự động bay nhặt toàn bộ rương phần thưởng (Beli, Gem, Vật phẩm) sau mỗi mốc Wave và Boss cuối",
            CurrentValue = (hubState.dungeonAutoCollectChest ~= false),
            Callback = function(Value: boolean)
                hubState.dungeonAutoCollectChest = Value
                saveState(hubState)
            end,
        }, "DungeonAutoCollectChestToggle")

        -- --------------------------------------------------------
        -- PHẦN 2: THIẾT LẬP ĐỘ KHÓ & CHIẾN THUẬT BAY
        -- --------------------------------------------------------
        local ModeDungSection = DungTab:CreateSection("🎚️ LỰA CHỌN ĐỘ KHÓ & CHIẾN THUẬT BAY")

        local dungDiffOptions = {
            "Easy (Dễ - Cày Nhanh / Thích Hợp AFK)",
            "Normal (Thường - Cân Bằng)",
            "Hard (Khó - Thưởng Khủng)",
            "Nightmare (Cực Khó - Boss Đỉnh Cao)",
        }
        local defaultDungDiff = dungDiffOptions[1]
        for _, optStr in ipairs(dungDiffOptions) do
            if hubState.dungeonMode and (optStr == hubState.dungeonMode or string.find(optStr, "^" .. tostring(hubState.dungeonMode))) then
                defaultDungDiff = optStr
                break
            end
        end
        ModeDungSection:CreateDropdown({
            Name = "🎯 Chọn Độ Khó Dungeon",
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

        local dungWeaponOptions = {
            "Auto Mode (Tự Động Theo Tab Chiêu Thức)",
            "Fruit (Ưu Tiên Trái Ác Quỷ AOE)",
            "Sword (Ưu Tiên Kiếm Sát Thương Đơn/Đa)",
            "Melee (Ưu Tiên Võ Thuật Cận Chiến)",
        }
        ModeDungSection:CreateDropdown({
            Name = "🗡️ Chọn Vũ Khí Tấn Công Dungeon",
            Options = dungWeaponOptions,
            CurrentOption = { hubState.dungeonWeaponMode or dungWeaponOptions[1] },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.dungeonWeaponMode = val
                saveState(hubState)
            end,
        }, "DungeonWeaponModeDropdown")

        ModeDungSection:CreateSlider({
            Name = "🕊️ Độ Cao Bay An Toàn Khi Diệt Quái Dungeon",
            Description = "Khoảng cách bay lơ lửng trên đầu quái. 14-18 studs giúp xả chiêu trúng 100% mà quái đất không thể chạm tới",
            Range = { 6, 60 },
            Increment = 2,
            Suffix = "studs",
            CurrentValue = hubState.dungeonSafeHeight or 16,
            Callback = function(Value: number)
                hubState.dungeonSafeHeight = Value
                saveState(hubState)
            end,
        }, "DungeonSafeHeightSlider")

        ModeDungSection:CreateDropdown({
            Name = "⚡ Chọn Mode Chiến Thuật Tốc Độ",
            Options = {
                "⚡ Fast Sweep (Quét Siêu Tốc 8m / Gom Quái Tối Đa)",
                "🛡️ Safe Mode (Khoảng Cách An Toàn 22m + Hồi Máu)",
                "⚖️ Balanced Mode (Cân Bằng 14m / Tối Ưu DPS & HP)",
            },
            CurrentOption = { hubState.dungeonTactics or "⚡ Fast Sweep (Quét Siêu Tốc 8m / Gom Quái Tối Đa)" },
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

        -- --------------------------------------------------------
        -- PHẦN 3: TỤ QUÁI & TỐI ƯU HÓA DPS (WAVE CLEARING)
        -- --------------------------------------------------------
        local WaveClearSection = DungTab:CreateSection("🧲 TỤ QUÁI & TỐI ƯU HÓA DPS (WAVE CLEARING)")

        WaveClearSection:CreateToggle({
            Name = "🧲 Tự Động Gom Tụ Quái Dungeon (Auto Mob Bring)",
            Description = "Hút toàn bộ quái vật trong đợt wave về ngay dưới tâm ngắm để chiêu thức diện rộng dọn sạch tức thì",
            CurrentValue = (hubState.dungeonMobBring ~= false),
            Callback = function(Value: boolean)
                hubState.dungeonMobBring = Value
                saveState(hubState)
            end,
        }, "DungeonMobBringToggle")

        WaveClearSection:CreateSlider({
            Name = "📏 Bán Kính Quét Gom Quái Dungeon",
            Range = { 100, 1500 },
            Increment = 50,
            Suffix = "studs",
            CurrentValue = hubState.dungeonBringRange or 600,
            Callback = function(Value: number)
                hubState.dungeonBringRange = Value
                saveState(hubState)
            end,
        }, "DungeonBringRangeSlider")

        WaveClearSection:CreateToggle({
            Name = "🛡️ Tự Động Bật Haki Vũ Trang & Quan Sát Khi Vào Wave",
            Description = "Luôn duy trì Haki để tối đa hóa sát thương và né chiêu trong suốt phó bản",
            CurrentValue = (hubState.dungeonAutoHaki ~= false),
            Callback = function(Value: boolean)
                hubState.dungeonAutoHaki = Value
                saveState(hubState)
            end,
        }, "DungeonAutoHakiToggle")

        -- --------------------------------------------------------
        -- PHẦN 4: CỨU NGUY KHẨN CẤP & BẢO VỆ NHÂN VẬT
        -- --------------------------------------------------------
        local EmergencySection = DungTab:CreateSection("🩹 CỨU NGUY KHẨN CẤP & BẢO VỆ NHÂN VẬT")

        EmergencySection:CreateToggle({
            Name = "🪄 Tự Kích Hoạt Kỹ Năng Hồi Máu / Hút Máu Khi Dưới Ngưỡng",
            Description = "Tự động dùng Scepter, Golden Staff, chiêu Trái Phượng Hoàng (Flames of Restoration), hút máu Vampire/Blood khi máu tụt xuống mức nguy hiểm",
            CurrentValue = (hubState.dungeonAutoHeal ~= false),
            Callback = function(Value: boolean)
                hubState.dungeonAutoHeal = Value
                saveState(hubState)
                pcall(function()
                    genv.DungeonAutoScepterHeal = Value
                end)
            end,
        }, "DungeonAutoHealToggle")

        EmergencySection:CreateSlider({
            Name = "🩸 Ngưỡng Máu Kích Hoạt Hồi Máu (%)",
            Range = { 20, 95 },
            Increment = 5,
            Suffix = "%",
            CurrentValue = hubState.dungeonHealThreshold or 80,
            Callback = function(Value: number)
                hubState.dungeonHealThreshold = Value
                saveState(hubState)
            end,
        }, "DungeonHealThresholdSlider")

        EmergencySection:CreateToggle({
            Name = "🚀 Tự Động Bay Cao Thoát Hiểm Khi Máu Dưới 30% (Emergency Flight)",
            Description = "Tự bứt tốc bay vọt lên 75m né toàn bộ sát thương quái khi gặp nguy cấp, đợi hồi đầy máu mới hạ xuống tiếp tục đánh",
            CurrentValue = (hubState.dungeonEmergencyFlight ~= false),
            Callback = function(Value: boolean)
                hubState.dungeonEmergencyFlight = Value
                saveState(hubState)
            end,
        }, "DungeonEmergencyFlightToggle")

        EmergencySection:CreateToggle({
            Name = "🎥 Khóa Góc Nhìn Camera Vào Tâm Quái Dungeon",
            Description = "Cố định camera vào mục tiêu giúp skill định hướng luôn trúng 100% (mặc định tắt để tránh xoay góc nhìn)",
            CurrentValue = (hubState.dungeonCameraLock == true),
            Callback = function(Value: boolean)
                hubState.dungeonCameraLock = Value
                saveState(hubState)
                pcall(function()
                    genv.DungeonCameraLock = Value
                end)
            end,
        }, "DungeonCameraLockToggle")

        -- --------------------------------------------------------
        -- PHẦN 5: DỊCH CHUYỂN NHANH ĐẾN KHU VỰC PHÓ BẢN
        -- --------------------------------------------------------
        local NavigationSection = DungTab:CreateSection("📍 DỊCH CHUYỂN NHANH ĐẾN KHU VỰC PHÓ BẢN")

        NavigationSection:CreateButton({
            Name = "🏝️ Dịch Chuyển Đến Đảo Viridans (Cổng Dungeon)",
            Description = "Bay dịch chuyển nhanh đến tọa độ đảo Viridans nơi đặt cổng Phó bản",
            Callback = function()
                pcall(function()
                    if typeof(genv.TeleportToIsland) == "function" then
                        genv.TeleportToIsland("🏝️ [Sea 2] Đảo Viridans (Viridans)")
                        safeNotify("YokaHub Dungeon", "Đang bay đến Đảo Viridans (Cổng Phó bản)...", "flight_takeoff")
                    end
                end)
            end,
        }, "TeleportViridansButton")

        NavigationSection:CreateButton({
            Name = "🚪 Dịch Chuyển Đến Cổng / Vòng Tròn Phó Bản Gần Nhất",
            Description = "Tự động dò tìm vòng tròn / NPC Phó bản xung quanh và bay thẳng vào tâm",
            Callback = function()
                pcall(function()
                    if typeof(genv.DungeonTeleportGate) == "function" then
                        genv.DungeonTeleportGate()
                    else
                        safeNotify("YokaHub Dungeon", "Đang dò tìm cổng phó bản...", "explore")
                    end
                end)
            end,
        }, "TeleportDungeonGateButton")
    end
