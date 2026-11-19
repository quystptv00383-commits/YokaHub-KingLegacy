    -- ========================================================
    -- TAB 6: CAU CA TU DONG (AUTO FISHING)
    -- ========================================================
    do
        local FishTab = Window:CreateTab({
            Name = "🎣 Câu Cá Tự Động",
            Icon = "phishing",
            ImageSource = "Material",
            ShowTitle = false,
        })

        local MainFishSection = FishTab:CreateSection("🎣 Tự Động Câu Cá (Auto Fishing Master)")
        MainFishSection:CreateToggle({
            Name = "🎣 Bật Tự Động Câu Cá (Auto Fishing)",
            Description = "Tự cầm cần câu/kiếm câu cá, bay ra mặt biển đứng nổi, quăng mồi và kéo cá",
            CurrentValue = hubState.autoFish,
            Callback = function(Value: boolean)
                hubState.autoFish = Value
                if Value and currentMode ~= "off" then
                    applyMode("off", false)
                    setStatus("Đang câu cá — Tạm dừng Săn Boss.")
                end
                saveState(hubState)
                pcall(function()
                    genv.AutoFish = Value
                    genv.kiemmacauca = hubState.fishWeapon or "True Muramasa"
                    genv.Walkonwater = hubState.fishFloat ~= false
                end)
                if Value then safeNotify("YokaHub Câu Cá", "Đã bật Auto Fishing hoàn chỉnh!", "phishing") end
            end,
        }, "AutoFishToggle")

        MainFishSection:CreateParagraph({
            Title = "🐟 Cơ Chế Vận Hành Rảnh Tay",
            Text = "Nhân vật sẽ tự động trang bị cần câu hoặc kiếm câu cá đã chọn, bay ra biển đứng nổi trên mặt nước, quăng mồi câu và tự động giật cá vào kho đồ.",
        })

        local GearFishSection = FishTab:CreateSection("🗡️ Trang Bị Cần & Kiếm Câu Cá")
        GearFishSection:CreateDropdown({
            Name = "Chọn Cần / Kiếm Câu Cá",
            Options = {
                "True Muramasa (Khuyên Dùng - Tốc Độ Cao)",
                "Muramasa (Kiếm Câu Chuẩn)",
                "Triple Katana (Tam Kiếm Phái)",
                "Golden Staff (Gậy Vàng Thần Thoại)",
                "Fishing Rod (Cần Câu Mặc Định)",
            },
            CurrentOption = { hubState.fishWeapon or "True Muramasa (Khuyên Dùng - Tốc Độ Cao)" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                local rawWeapon = string.match(val, "^([%w%s%']+)") or "True Muramasa"
                rawWeapon = string.gsub(rawWeapon, "%s+$", "")
                hubState.fishWeapon = rawWeapon
                saveState(hubState)
                pcall(function()
                    genv.kiemmacauca = rawWeapon
                end)
            end,
        }, "FishWeaponDropdown")

        local SurfaceFishSection = FishTab:CreateSection("🌊 Đứng Nổi Trên Mặt Biển")
        SurfaceFishSection:CreateToggle({
            Name = "🌊 Tự Động Nổi Trên Mặt Nước (Water Float)",
            Description = "Tạo bệ nổi vô hình giúp nhân vật không bị chìm xuống nước khi đang câu cá",
            CurrentValue = hubState.fishFloat ~= false,
            Callback = function(Value: boolean)
                hubState.fishFloat = Value
                saveState(hubState)
                pcall(function()
                    genv.Walkonwater = Value
                end)
            end,
        }, "FishFloatToggle")
    end
