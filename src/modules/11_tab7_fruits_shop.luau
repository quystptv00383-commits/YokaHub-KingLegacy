    -- ========================================================
    -- TAB 7: TRAI AC QUY & SHOP SNIPER (FRUITS & SHOP)
    -- ========================================================
    do
        local FruitTab = Window:CreateTab({
            Name = "🍎 Trái & Cửa Hàng",
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
            Description = "Tự động gửi vào kho ngay sau khi nhặt được để tránh bị người khác cướp hoặc mất",
            CurrentValue = hubState.storeFruits,
            Callback = function(Value: boolean)
                hubState.storeFruits = Value
                saveState(hubState)
                pcall(function() genv.AutoStoreFruit = Value end)
            end,
        }, "StoreFruitsToggle")

        local ShopSection = FruitTab:CreateSection("🛒 Bắn Tỉa Mua Trái Trong Shop (Shop Sniper)")
        ShopSection:CreateToggle({
            Name = "🛒 Bật Sniper Tự Mua Trái Khi Shop Mở Bán",
            Description = "Tự động kiểm tra Shop Trái mỗi vài giây và mua ngay lập tức các trái được chọn",
            CurrentValue = hubState.snipeShop,
            Callback = function(Value: boolean)
                hubState.snipeShop = Value
                saveState(hubState)
                pcall(function()
                    genv.shopSniperEnabled = Value
                    genv.shopSniperDelay = hubState.snipeDelay or 5
                end)
                if Value then safeNotify("Shop Sniper", "Đang theo dõi Shop: " .. tostring(hubState.snipeFruit), "shopping_cart") end
            end,
        }, "SnipeShopToggle")

        ShopSection:CreateDropdown({
            Name = "Chọn Trái Cụ Thể Muốn Sniper",
            Options = {
                "⭐ Toàn Bộ Trái Thần Thoại & Cực Hiếm (Mythic + Legendary)",
                "Dragon (Rồng Thần)",
                "Phoenix (Phượng Hoàng)",
                "Gate (Cổng Không Gian)",
                "Dough (Bánh Mochi)",
                "Erebus (Bóng Tối Tối Thượng)",
                "Spirit (Linh Hồn)",
                "Magnet (Từ Tính)",
                "Toy (Đồ Chơi)",
                "Melody (Âm Nhạc)",
                "Demon (Quỷ Vương)",
                "Snow (Tuyết Trắng)",
            },
            CurrentOption = { hubState.snipeFruit or "⭐ Toàn Bộ Trái Thần Thoại & Cực Hiếm (Mythic + Legendary)" },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.snipeFruit = val
                saveState(hubState)
                pcall(function()
                    local rawName = string.match(val, "^([%w%s%']+)") or "Dragon"
                    rawName = string.gsub(rawName, "%s+$", "")
                    if string.find(val, "Toàn Bộ") then
                        genv.shopSniperFruits = {"Dragon", "Phoenix", "Gate", "Dough", "Erebus", "Spirit", "Magnet", "Toy", "Melody", "Demon", "Snow"}
                    else
                        genv.shopSniperFruits = { rawName }
                    end
                end)
            end,
        }, "SnipeFruitDropdown")

        ShopSection:CreateButton({
            Name = "⚡ Chọn Nhanh Top 5 Trái Meta Hot Nhất",
            Description = "Thiết lập mua ngay: Dragon, Phoenix, Gate, Dough, Erebus",
            Callback = function()
                hubState.snipeFruit = "⭐ Toàn Bộ Trái Thần Thoại & Cực Hiếm (Mythic + Legendary)"
                saveState(hubState)
                pcall(function()
                    genv.shopSniperFruits = {"Dragon", "Phoenix", "Gate", "Dough", "Erebus"}
                    safeNotify("Shop Sniper", "Đã cấu hình mua Top 5 trái Meta: Dragon, Phoenix, Gate, Dough, Erebus!", "verified")
                end)
            end,
        })

        ShopSection:CreateSlider({
            Name = "⏱️ Tần Suất Quét Shop (Giây)",
            Range = { 1, 30 },
            Increment = 1,
            CurrentValue = hubState.snipeDelay or 5,
            Callback = function(Value: number)
                hubState.snipeDelay = Value
                saveState(hubState)
                pcall(function()
                    genv.shopSniperDelay = Value
                end)
            end,
        }, "SnipeDelaySlider")

        local InventoryActionsSection = FruitTab:CreateSection("📤 Thao Tác Trái Kho Đồ")
        InventoryActionsSection:CreateButton({
            Name = "📦 Lấy Toàn Bộ Trái Ra Khỏi Rương (Unstore All)",
            Description = "Rút tất cả trái ác quỷ trong rương đồ ra balo cá nhân qua DealFruit chính thức",
            Callback = function()
                task.spawn(function()
                    local unstored = 0
                    pcall(function()
                        local chest = game:GetService("ReplicatedStorage"):FindFirstChild("Chest")
                        local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                        local dealFruit = remFuncs and remFuncs:FindFirstChild("DealFruit")
                        local ps = player:FindFirstChild("PlayerStats")
                        local fsObj = ps and ps:FindFirstChild("FruitStore")
                        if dealFruit and fsObj and typeof(fsObj.Value) == "string" and #fsObj.Value > 2 then
                            local okDec, tbl = pcall(function() return httpService:JSONDecode(fsObj.Value) end)
                            if okDec and typeof(tbl) == "table" then
                                for fruitName, qty in pairs(tbl) do
                                    if (tonumber(qty) or 0) > 0 then
                                        pcall(function() dealFruit:InvokeServer(tostring(fruitName), "Unstore") end)
                                        unstored += 1
                                        task.wait(0.12)
                                    end
                                end
                            end
                        end
                    end)
                    if unstored > 0 then
                        safeNotify("YokaHub Kho Đồ", "Đã rút " .. tostring(unstored) .. " loại trái ác quỷ từ rương ra balo!", "inventory")
                    else
                        safeNotify("YokaHub Kho Đồ", "Không thấy trái nào trong rương (FruitStore trống).", "info")
                    end
                end)
            end,
        })

        InventoryActionsSection:CreateButton({
            Name = "⚠️ Thả Trái Rơi Ra Đất (Drop Fruit)",
            Description = "Thả trái vật lý trên tay hoặc trong balo ra đất (tự bảo vệ không thả nhầm Trái đang ăn)",
            Callback = function()
                pcall(function()
                    local char = player.Character
                    local held = char and char:FindFirstChildOfClass("Tool")
                    if held and (held.ToolTip == "Fruit Power" or not string.find(string.lower(held.Name), "fruit")) then
                        held = nil
                    end
                    if not held then
                        for _, t in ipairs(player.Backpack:GetChildren()) do
                            if t:IsA("Tool") and t.ToolTip ~= "Fruit Power" and string.find(string.lower(t.Name), "fruit") then
                                held = t
                                if char and char:FindFirstChildOfClass("Humanoid") then
                                    char.Humanoid:EquipTool(t)
                                    task.wait(0.2)
                                end
                                break
                            end
                        end
                    end
                    if held then
                        local chest = game:GetService("ReplicatedStorage"):FindFirstChild("Chest")
                        local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                        if remFuncs and remFuncs:FindFirstChild("DealFruit") then
                            pcall(function() remFuncs.DealFruit:InvokeServer(held.Name, "Drop") end)
                        end
                        safeNotify("YokaHub", "Đã thả trái [" .. held.Name .. "] ra đất!", "file_download")
                    else
                        safeNotify("YokaHub", "Không tìm thấy trái vật lý nào trong túi đồ để thả!", "warning")
                    end
                end)
            end,
        })
    end
