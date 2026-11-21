    -- ========================================================
    -- TAB 6: CAU CA TU DONG (AUTO FISHING MASTER V3)
    -- ========================================================
    do
        local FishTab = Window:CreateTab({
            Name = "🎣 Câu Cá Tự Động",
            Icon = "waves",
            ImageSource = "Material",
            ShowTitle = false,
        })

        -- ========================================================
        -- BIẾN NỘI BỘ & HELPER DỮ LIỆU
        -- ========================================================
        local defaultPresets = {
            "True Muramasa (Khuyên Dùng - Tốc Độ Cao)",
            "Muramasa (Kiếm Câu Chuẩn)",
            "Triple Katana (Tam Kiếm Phái)",
            "Golden Staff (Gậy Vàng Thần Thoại)",
            "Golden Rod (Cần Câu Vàng Thần Thoại)",
            "Carbon Rod (Cần Câu Carbon)",
            "Basic Rod (Cần Câu Cơ Bản)",
            "Fishing Rod (Cần Câu Mặc Định)",
        }

        local function getAvailableFishingGear(): { string }
            local list: { string } = {}
            local seen: { [string]: boolean } = {}

            -- Quét túi đồ (Backpack) & nhân vật (Character) tìm cần câu / kiếm
            pcall(function()
                local char = player.Character
                if char then
                    for _, item in ipairs(char:GetChildren()) do
                        if item:IsA("Tool") then
                            local nm = item.Name
                            if not seen[nm] then
                                seen[nm] = true
                                table.insert(list, nm .. " (Đang Cầm)")
                            end
                        end
                    end
                end
                local bp = player:FindFirstChild("Backpack")
                if bp then
                    for _, item in ipairs(bp:GetChildren()) do
                        if item:IsA("Tool") then
                            local nm = item.Name
                            if not seen[nm] then
                                seen[nm] = true
                                local low = string.lower(nm)
                                if string.find(low, "rod") or string.find(low, "fish") or string.find(low, "muramasa") or string.find(low, "staff") or string.find(low, "katana") then
                                    table.insert(list, nm .. " (Trong Túi)")
                                else
                                    table.insert(list, nm)
                                end
                            end
                        end
                    end
                end
            end)

            -- Bổ sung các preset chuẩn nếu chưa có
            for _, preset in ipairs(defaultPresets) do
                local raw = string.match(preset, "^([%w%s%']+)") or preset
                raw = string.gsub(raw, "%s+$", "")
                if not seen[preset] and not seen[raw] then
                    table.insert(list, preset)
                end
            end

            return #list > 0 and list or defaultPresets
        end

        local fishingHotspots = {
            ["Tự do (Vị trí hiện tại)"] = nil,
            ["🏝️ [Sea 1] Bờ Biển Đảo Khởi Đầu (Starter Beach)"] = Vector3.new(-105, 14, 520),
            ["🏴‍☠️ [Sea 1] Cầu Tàu Đảo Hải Tặc (Pirate Pier)"] = Vector3.new(1540, 16, 1280),
            ["🌸 [Sea 1] Cảng Thị Trấn Floresco (Floresco Town)"] = Vector3.new(-1250, 16, -180),
            ["🌿 [Sea 2] Vịnh Câu Cá Viridans (Viridans Bay)"] = Vector3.new(-4800, 16, 2100),
            ["💀 [Sea 2] Vùng Biển Đảo Đầu Lâu (Skull Waters)"] = Vector3.new(2800, 16, -3400),
            ["🌌 [Sea 3] Cầu Cảng Cõi Hư Vô (The Unearthly Pier)"] = Vector3.new(-6500, 18, 1200),
            ["🌊 [Sea 3] Vùng Nước Sâu Depth Waters (Sea 3)"] = Vector3.new(3200, 16, 4500),
        }

        local hotspotOptions = {
            "Tự do (Vị trí hiện tại)",
            "🏝️ [Sea 1] Bờ Biển Đảo Khởi Đầu (Starter Beach)",
            "🏴‍☠️ [Sea 1] Cầu Tàu Đảo Hải Tặc (Pirate Pier)",
            "🌸 [Sea 1] Cảng Thị Trấn Floresco (Floresco Town)",
            "🌿 [Sea 2] Vịnh Câu Cá Viridans (Viridans Bay)",
            "💀 [Sea 2] Vùng Biển Đảo Đầu Lâu (Skull Waters)",
            "🌌 [Sea 3] Cầu Cảng Cõi Hư Vô (The Unearthly Pier)",
            "🌊 [Sea 3] Vùng Nước Sâu Depth Waters (Sea 3)",
        }

        -- ========================================================
        -- SECTION 1: 🎣 TỰ ĐỘNG CÂU CÁ (MASTER FISHING)
        -- ========================================================
        local MainFishSection = FishTab:CreateSection("🎣 Tự Động Câu Cá (Auto Fishing Master)")

        local AutoFishToggle = MainFishSection:CreateToggle({
            Name = "🎣 Bật Tự Động Câu Cá (Auto Fishing Master)",
            Description = "Tự cầm cần/kiếm, di chuyển tới bãi câu, nổi an toàn trên biển, quăng mồi và giật cá hoàn toàn rảnh tay",
            CurrentValue = hubState.autoFish == true,
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.autoFish = Value
                if Value then
                    deactivateOtherLocalModes("autoFish")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang câu cá — Tạm dừng Săn Boss.")
                    end
                end
                saveState(hubState)
                pcall(function()
                    genv.AutoFish = Value
                    genv.kiemmacauca = hubState.fishWeapon or "True Muramasa"
                    genv.Walkonwater = hubState.fishFloat ~= false
                end)
                if Value then
                    safeNotify("YokaHub Câu Cá", "Đã bật Auto Fishing Master hoàn chỉnh!", "phishing")
                else
                    safeNotify("YokaHub Câu Cá", "Đã tắt Auto Fishing.", "info")
                end
            end,
        }, "AutoFishToggle")
        registerLocalModeToggle("autoFish", AutoFishToggle)

        MainFishSection:CreateParagraph({
            Title = "🐟 Cơ Chế Tác Chiến Rảnh Tay & Kiếm Beli Siêu Tốc",
            Text = "Hệ thống tự động trang bị cần câu hoặc vũ khí tốc độ cao, đứng nổi an toàn trên mặt nước (chống chết đuối do Trái Ác Quỷ), tự động quăng cần, bypass giải minigame hoàn hảo 100% không đứt dây và tự bán cá cho Fisher Frank.",
        })

        -- ========================================================
        -- SECTION 2: 🗡️ TRANG BỊ CẦN CÂU & VŨ KHÍ TÁC CHIẾN
        -- ========================================================
        local GearFishSection = FishTab:CreateSection("🗡️ Trang Bị Cần & Kiếm Câu Cá Tốc Độ Cao")

        local currentGearOptions = getAvailableFishingGear()
        local defaultFishWeapon = currentGearOptions[1]
        if hubState.fishWeapon then
            for _, opt in ipairs(currentGearOptions) do
                if opt == hubState.fishWeapon or string.find(opt, hubState.fishWeapon, 1, true) ~= nil then
                    defaultFishWeapon = opt
                    break
                end
            end
        end

        local FishWeaponDropdownObj: any = nil
        FishWeaponDropdownObj = GearFishSection:CreateDropdown({
            Name = "Chọn Cần / Kiếm Câu Cá",
            Description = "Tự động cầm vũ khí này khi câu cá (Khuyên dùng True Muramasa / Muramasa hoặc Cần Câu)",
            Options = currentGearOptions,
            CurrentOption = { defaultFishWeapon },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                local rawWeapon = string.match(val, "^([%w%s%']+)") or "True Muramasa"
                rawWeapon = string.gsub(rawWeapon, "%s+$", "")
                hubState.fishWeapon = val
                saveState(hubState)
                pcall(function()
                    genv.kiemmacauca = rawWeapon
                end)
                safeNotify("Cần Câu Cá", "Đã chọn: " .. val, "build")
            end,
        }, "FishWeaponDropdown")

        GearFishSection:CreateButton({
            Name = "🔄 Quét Lại Kho Đồ Tìm Cần Câu & Kiếm Mới",
            Description = "Làm mới danh sách vũ khí từ túi đồ (Backpack) và trang bị trên người",
            Callback = function()
                local newGears = getAvailableFishingGear()
                if FishWeaponDropdownObj and FishWeaponDropdownObj.Set then
                    pcall(function()
                        FishWeaponDropdownObj:Set({
                            Options = newGears,
                            CurrentOption = { newGears[1] },
                        })
                    end)
                end
                safeNotify("YokaHub", "Đã quét lại túi đồ: Tìm thấy " .. #newGears .. " trang bị câu cá!", "refresh")
            end,
        }, "RefreshGearButton")

        -- ========================================================
        -- SECTION 3: ⚡ TỰ ĐỘNG GIẬT CẦN & TỐI ƯU MINIGAME
        -- ========================================================
        local ReelSection = FishTab:CreateSection("⚡ Tự Động Giật Cần & Tối Ưu Minigame")

        ReelSection:CreateToggle({
            Name = "⚡ Tự Động Giật Cần Khi Cá Cắn (Auto Reel)",
            Description = "Tự động phát hiện cá cắn mồi và kéo cần ngay lập tức",
            CurrentValue = hubState.autoReel ~= false,
            Callback = function(Value: boolean)
                hubState.autoReel = Value
                saveState(hubState)
                pcall(function() genv.AutoReel = Value end)
            end,
        }, "AutoReelToggle")

        ReelSection:CreateToggle({
            Name = "🎯 Tự Động Giải Minigame Hoàn Hảo (Instant Perfect Catch)",
            Description = "Bypass thanh trượt minigame câu cá của game, kéo cá lên bờ trong 1 nốt nhạc mà không bao giờ bị đứt dây",
            CurrentValue = hubState.perfectCatch ~= false,
            Callback = function(Value: boolean)
                hubState.perfectCatch = Value
                saveState(hubState)
                pcall(function() genv.PerfectCatch = Value end)
            end,
        }, "PerfectCatchToggle")

        ReelSection:CreateSlider({
            Name = "⏱️ Độ Trễ Quăng Mồi (Cast Delay)",
            Description = "Khoảng thời gian chuẩn bị giữa mỗi lần quăng cần câu (khuyên dùng 1.5s - 2.5s)",
            Range = { 1.0, 5.0 },
            Increment = 0.1,
            Suffix = "s",
            CurrentValue = hubState.fishCastDelay or 1.8,
            Callback = function(Value: number)
                hubState.fishCastDelay = tonumber(string.format("%.1f", Value)) or 1.8
                saveState(hubState)
                pcall(function() genv.FishCastDelay = hubState.fishCastDelay end)
            end,
        }, "FishCastDelaySlider")

        ReelSection:CreateSlider({
            Name = "⏱️ Thời Gian Kéo Cần (Reel Delay)",
            Description = "Tốc độ kéo cá sau khi cá đã cắn mồi (khuyên dùng 0.3s - 0.6s)",
            Range = { 0.2, 2.0 },
            Increment = 0.05,
            Suffix = "s",
            CurrentValue = hubState.fishReelDelay or 0.45,
            Callback = function(Value: number)
                hubState.fishReelDelay = tonumber(string.format("%.2f", Value)) or 0.45
                saveState(hubState)
                pcall(function() genv.FishReelDelay = hubState.fishReelDelay end)
            end,
        }, "FishReelDelaySlider")

        -- ========================================================
        -- SECTION 4: 💰 TỰ ĐỘNG BÁN CÁ CHO FISHER FRANK
        -- ========================================================
        local SellSection = FishTab:CreateSection("💰 Tự Động Bán Cá Cho Fisher Frank")

        SellSection:CreateToggle({
            Name = "💰 Bật Tự Động Bán Cá (Auto Sell Fish)",
            Description = "Tự động bay tới NPC Fisher Frank bán cá định kỳ để kiếm hàng triệu Beli",
            CurrentValue = hubState.autoSellFish == true,
            Callback = function(Value: boolean)
                hubState.autoSellFish = Value
                saveState(hubState)
                pcall(function() genv.AutoSellFish = Value end)
                if Value then
                    safeNotify("Bán Cá", "Đã bật tự động bán cá cho Fisher Frank!", "monetization_on")
                end
            end,
        }, "AutoSellFishToggle")

        SellSection:CreateToggle({
            Name = "🐟 Bán Cá Thường (Common & Uncommon)",
            Description = "Tự động bán cá thông thường: Pebblefish, Celestafin, Lunafin, Moonbite, Embergill...",
            CurrentValue = hubState.sellCommonFish ~= false,
            Callback = function(Value: boolean)
                hubState.sellCommonFish = Value
                saveState(hubState)
            end,
        }, "SellCommonFishToggle")

        SellSection:CreateToggle({
            Name = "🐡 Bán Cá Hiếm (Rare Fish)",
            Description = "Tự động bán cá hiếm: Stormcatfish, Longtooth, Redbelly...",
            CurrentValue = hubState.sellRareFish ~= false,
            Callback = function(Value: boolean)
                hubState.sellRareFish = Value
                saveState(hubState)
            end,
        }, "SellRareFishToggle")

        SellSection:CreateToggle({
            Name = "🦈 Bán Cá Cực Phẩm (Epic Fish)",
            Description = "Tự động bán cá Epic: Mistjaw, Frost Shark, Inferno Shark...",
            CurrentValue = hubState.sellEpicFish == true,
            Callback = function(Value: boolean)
                hubState.sellEpicFish = Value
                saveState(hubState)
            end,
        }, "SellEpicFishToggle")

        SellSection:CreateToggle({
            Name = "🔒 Khóa & Giữ Lại Cá Thần Thoại (Lock Legendary & Mythical)",
            Description = "Tuyệt đối KHÔNG BÁN cá siêu hiếm (Abyss Mosa, Obsidian Whale, Volt Fang, Dread Lantern, Tidal Terror) để buff chỉ số Luck",
            CurrentValue = hubState.lockLegendaryFish ~= false,
            Callback = function(Value: boolean)
                hubState.lockLegendaryFish = Value
                saveState(hubState)
            end,
        }, "LockLegendaryFishToggle")

        SellSection:CreateButton({
            Name = "💸 Bay Ngay Tới Fisher Frank Để Bán Cá",
            Description = "Tìm NPC Fisher Frank gần nhất trên bản đồ, bay tới và bán toàn bộ cá đang có trong kho",
            Callback = function()
                safeNotify("YokaHub Bán Cá", "Đang quét vị trí NPC Fisher Frank...", "info")
                task.spawn(function()
                    local frankNpc: Model? = nil
                    local frankPos: Vector3? = nil
                    pcall(function()
                        local allNpc = workspace:FindFirstChild("AllNPC") or workspace:FindFirstChild("NPC") or workspace
                        for _, n in ipairs(allNpc:GetDescendants()) do
                            if n:IsA("Model") and (string.find(string.lower(n.Name), "fisher") or string.find(string.lower(n.Name), "frank")) then
                                local r = n:FindFirstChild("HumanoidRootPart") or n:FindFirstChildWhichIsA("BasePart")
                                if r then
                                    frankNpc = n
                                    frankPos = r.Position
                                    break
                                end
                            end
                        end
                    end)

                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if frankPos and hrp then
                        local oldPos = hrp.CFrame
                        hrp.CFrame = CFrame.new(frankPos + Vector3.new(0, 3, 3))
                        task.wait(0.6)
                        pcall(function()
                            local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                            if rem and rem:FindFirstChild("Functions") and rem.Functions:FindFirstChild("FisherFrank") then
                                rem.Functions.FisherFrank:InvokeServer("SellAll")
                            elseif rem and rem:FindFirstChild("Functions") and rem.Functions:FindFirstChild("Fishing") then
                                rem.Functions.Fishing:InvokeServer("SellAll")
                            end
                        end)
                        task.wait(0.8)
                        safeNotify("YokaHub Bán Cá", "Đã bán toàn bộ cá cho Fisher Frank thành công!", "check_circle")
                    else
                        -- Thử invoke remote trực tiếp nếu không cần lại gần
                        pcall(function()
                            local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                            if rem and rem:FindFirstChild("Functions") and rem.Functions:FindFirstChild("FisherFrank") then
                                rem.Functions.FisherFrank:InvokeServer("SellAll")
                                safeNotify("YokaHub Bán Cá", "Đã gọi bán cá qua Remote máy chủ!", "check_circle")
                            else
                                safeNotify("YokaHub Bán Cá", "Chưa tìm thấy NPC Fisher Frank trên Sea hiện tại!", "warning")
                            end
                        end)
                    end
                end)
            end,
        }, "SellNowButton")

        -- ========================================================
        -- SECTION 5: 📍 ĐIỂM CÂU ĐẮC ĐỊA & BỆ NỔI MẶT NƯỚC
        -- ========================================================
        local SpotSection = FishTab:CreateSection("📍 Điểm Câu Đắc Địa & Bệ Nổi Mặt Nước")

        SpotSection:CreateToggle({
            Name = "🌊 Bệ Nổi Vô Hình Trên Mặt Nước (Water Float Shield)",
            Description = "Tạo bệ nổi YokaWaterPlatform cố định dưới chân giúp nhân vật đứng vững trên mặt biển, tuyệt đối không bị tụt máu hoặc chết đuối do Trái Ác Quỷ",
            CurrentValue = hubState.fishFloat ~= false,
            Callback = function(Value: boolean)
                hubState.fishFloat = Value
                saveState(hubState)
                pcall(function()
                    genv.Walkonwater = Value
                end)
                if Value then
                    safeNotify("Water Float", "Đã kích hoạt khiên bệ nổi trên mặt nước!", "waves")
                end
            end,
        }, "FishFloatToggle")

        local selectedSpotName = hubState.fishLocation or hotspotOptions[1]
        SpotSection:CreateDropdown({
            Name = "📍 Chọn Điểm Câu Cá Đắc Địa (Fishing Hotspots)",
            Description = "Lựa chọn các bãi câu cá dồi dào cá hiếm trải dài khắp Sea 1, Sea 2 và Sea 3",
            Options = hotspotOptions,
            CurrentOption = { selectedSpotName },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.fishLocation = val
                saveState(hubState)
                safeNotify("Điểm Câu Cá", "Đã chọn: " .. val, "place")
            end,
        }, "FishLocationDropdown")

        SpotSection:CreateButton({
            Name = "🚀 Bay Ngay Tới Điểm Câu Đã Chọn",
            Description = "Dịch chuyển nhân vật tức thì tới tọa độ bãi câu đắc địa và tạo bệ nổi",
            Callback = function()
                local chosen = hubState.fishLocation or hotspotOptions[1]
                local targetCoords = fishingHotspots[chosen]
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if targetCoords and hrp then
                    hrp.CFrame = CFrame.new(targetCoords + Vector3.new(0, 3, 0))
                    safeNotify("Dịch Chuyển", "Đã tới: " .. chosen, "flight_takeoff")
                elseif hrp then
                    safeNotify("Dịch Chuyển", "Đang câu tự do tại vị trí hiện tại!", "info")
                end
            end,
        }, "TeleportSpotButton")

        -- ========================================================
        -- SECTION 6: 📊 BẢNG THỐNG KÊ SẢN LƯỢNG CÂU CÁ
        -- ========================================================
        local StatsSection = FishTab:CreateSection("📊 Bảng Thống Kê Sản Lượng Câu Cá")

        StatsSection:CreateParagraph({
            Title = "📈 Trạng Thái Câu Cá Phiên Này",
            Text = "• Trạng thái: " .. (hubState.autoFish and "🟢 Đang tự động câu cá" or "⚪ Đang tắt") .. "\n"
                .. "• Cần / Vũ khí: " .. tostring(hubState.fishWeapon or "True Muramasa") .. "\n"
                .. "• Tự giải Minigame: " .. (hubState.perfectCatch ~= false and "✅ Bật (Instant Catch)" or "❌ Tắt") .. "\n"
                .. "• Tự bán cá Fisher Frank: " .. (hubState.autoSellFish and "✅ Bật" or "❌ Tắt") .. "\n"
                .. "• Bệ nổi mặt nước: " .. (hubState.fishFloat ~= false and "🛡️ Bảo vệ 100%" or "❌ Tắt"),
        })

        StatsSection:CreateButton({
            Name = "🔄 Đặt Lại Trạng Thái Câu Cá",
            Description = "Reset dữ liệu thống kê câu cá phiên làm việc hiện tại",
            Callback = function()
                pcall(function()
                    genv.YokaFishCaught = 0
                    genv.YokaFishBeliEarned = 0
                end)
                safeNotify("Thống Kê", "Đã đặt lại dữ liệu câu cá phiên này!", "check")
            end,
        }, "ResetFishStatsButton")
    end
