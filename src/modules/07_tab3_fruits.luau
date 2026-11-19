    -- ========================================================
    -- TAB 3: TRAI AC QUY (INTEGRATED FROM WUKONG ENGINE)
    -- ========================================================
    do
        local FruitTab = Window:CreateTab({
            Name = "Trái Ác Quỷ",
            Icon = "spa",
            ImageSource = "Material",
            ShowTitle = false,
        })

        local MagnetSection = FruitTab:CreateSection("🍎 Nhặt & Cất Kho Trái Ác Quỷ")
        MagnetSection:CreateToggle({
            Name = "🧲 Tự Hút / Nhặt Trái Rơi Tự Do (Bring Fruit)",
            Description = "Tự động bay đến nhặt ngay lập tức khi có bất kỳ trái nào rơi trên map",
            CurrentValue = hubState.bringFruits,
            Callback = function(Value: boolean)
                hubState.bringFruits = Value
                saveState(hubState)
                pcall(function() genv.BringDroppedFruit = Value end)
                if Value then safeNotify("YokaHub", "Đang tự động quét nhặt trái rơi trên map...", "spa") end
            end,
        }, "BringFruitsToggle")

        MagnetSection:CreateToggle({
            Name = "📦 Tự Động Cất Trái Vào Kho Rương (Store Fruit)",
            Description = "Tự cất ngay vào rương sau khi nhặt, tránh bị mất khi chết",
            CurrentValue = hubState.storeFruits,
            Callback = function(Value: boolean)
                hubState.storeFruits = Value
                saveState(hubState)
                pcall(function() genv.autocat = Value end)
            end,
        }, "StoreFruitsToggle")

        local ShopSection = FruitTab:CreateSection("🛒 Bắn Tỉa Mua Trái Trong Shop (Shop Sniper)")
        ShopSection:CreateToggle({
            Name = "🎯 Bật Tự Động Mua Trái Khi Shop Mở Bán",
            Description = "Tự động kiểm tra danh mục Shop và mua ngay các trái đã chọn bên dưới",
            CurrentValue = hubState.snipeShop,
            Callback = function(Value: boolean)
                hubState.snipeShop = Value
                saveState(hubState)
                pcall(function() genv.autobuy = Value end)
                if Value then safeNotify("Shop Sniper", "Đã bật tự động săn mua trái trong Shop!", "shopping_cart") end
            end,
        }, "SnipeShopToggle")

        ShopSection:CreateDropdown({
            Name = "Chọn Trái Muốn Bắn Tỉa Mua Tự Động",
            Options = {
                "⭐ Toàn Bộ Trái Thần Thoại & Cực Hiếm (Mythic + Legendary)",
                "DragonFruit (Rồng)",
                "PhoenixFruit (Phượng Hoàng)",
                "GateFruit (Cổng Không Gian)",
                "DoughFruit (Bánh Mochi)",
                "ErebusFruit (Bóng Tối Huyền Thoại)",
                "SpiritFruit (Linh Hồn)",
                "MagnetFruit (Từ Tính)",
                "ToyFruit (Đồ Chơi)",
                "MelodyFruit (Âm Nhạc)",
                "DemonFruit (Ác Ma)",
                "SnowFruit (Tuyết)",
            },
            CurrentOption = { hubState.snipeFruit or "⭐ Toàn Bộ Trái Thần Thoại & Cực Hiếm (Mythic + Legendary)" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.snipeFruit = val
                saveState(hubState)
                pcall(function()
                    if string.find(val, "Toàn Bộ") then
                        genv.shopSniperFruits = {"DragonFruit", "PhoenixFruit", "GateFruit", "DoughFruit", "ErebusFruit", "SpiritFruit", "MagnetFruit", "ToyFruit", "MelodyFruit", "DemonFruit"}
                    else
                        local fName = val:match("^([%w]+)") or val
                        genv.shopSniperFruits = { fName }
                    end
                end)
                safeNotify("Shop Sniper", "Mục tiêu mua: " .. val, "verified")
            end,
        }, "SnipeFruitDropdown")

        ShopSection:CreateSlider({
            Name = "⏱️ Tần Suất Quét Shop (Giây)",
            Range = { 1, 15 },
            Increment = 1,
            Suffix = "giây",
            CurrentValue = hubState.snipeDelay or 5,
            Callback = function(Value: number)
                hubState.snipeDelay = Value
                saveState(hubState)
                pcall(function() genv.shopSniperDelay = Value end)
            end,
        }, "SnipeDelaySlider")

        ShopSection:CreateButton({
            Name = "⚡ Chọn Nhanh: 5 Trái Top 1 Server (Dragon, Phoenix, Gate, Dough, Erebus)",
            Description = "Bấm để chọn tự động mua 5 trái ác quỷ đắt giá nhất King Legacy",
            Callback = function()
                hubState.snipeFruit = "Dragon, Phoenix, Gate, Dough, Erebus"
                saveState(hubState)
                pcall(function()
                    genv.shopSniperFruits = {"DragonFruit", "PhoenixFruit", "GateFruit", "DoughFruit", "ErebusFruit"}
                end)
                safeNotify("Shop Sniper", "Đã chọn nhanh 5 Trái Top 1 Server!", "star")
            end,
        }, "QuickSnipeButton")

        local EspSection = FruitTab:CreateSection("👁️ ESP Nhìn Xuyên Bản Đồ")
        EspSection:CreateToggle({
            Name = "👁️ ESP Hiện Vị Trí Trái Ác Quỷ",
            Description = "Hiển thị khung tên và khoảng cách đến các trái ác quỷ trên đảo",
            CurrentValue = hubState.fruitESP,
            Callback = function(Value: boolean)
                hubState.fruitESP = Value
                saveState(hubState)
                pcall(function() genv.FruitESPEnabled = Value end)
            end,
        }, "FruitESPToggle")
    end

