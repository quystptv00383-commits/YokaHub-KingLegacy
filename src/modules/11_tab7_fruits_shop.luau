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

        -- ========================================================
        -- SECTION 1: 🍎 THU THẬP & CẤT GIỮ TRÁI (COLLECTION & STORAGE)
        -- ========================================================
        local MagnetSection = FruitTab:CreateSection("🍎 Thu Thập & Cất Giữ Trái (Collection & Storage)")

        MagnetSection:CreateToggle({
            Name = "🧲 Tự Teleport Nhặt Trái Rơi (Instant Bring Fruit)",
            Description = "Teleport tức thì đến vị trí trái rơi trên map và nhặt ngay lập tức trước khi người khác cướp",
            CurrentValue = (hubState.bringFruits == true),
            Callback = function(Value: boolean)
                hubState.bringFruits = Value
                saveState(hubState)
                pcall(function() genv.BringDroppedFruit = Value end)
                if Value then
                    safeNotify("YokaHub Trái", "Đã bật tự động teleport nhặt toàn bộ trái rơi trên map!", "spa")
                else
                    safeNotify("YokaHub Trái", "Đã tắt tự nhặt trái.", "info")
                end
            end,
        }, "BringFruitsToggle")

        MagnetSection:CreateToggle({
            Name = "📦 Tự Động Cất Trái Vào Rương (Auto Store Fruit)",
            Description = "Tự động gửi trái vật lý vào rương kho đồ (FruitStore) ngay khi nhặt được để tránh bị cướp hoặc mất",
            CurrentValue = (hubState.storeFruits ~= false),
            Callback = function(Value: boolean)
                hubState.storeFruits = Value
                saveState(hubState)
                pcall(function() genv.AutoStoreFruit = Value end)
                if Value then
                    safeNotify("YokaHub Kho", "Đã bật tự động cất trái vào rương!", "inventory_2")
                end
            end,
        }, "StoreFruitsToggle")

        MagnetSection:CreateToggle({
            Name = "👁️ Bật ESP Hiện Vị Trí Trái (Fruit ESP)",
            Description = "Hiện tên, khoảng cách và vòng sáng định vị tất cả trái ác quỷ đang rơi trên toàn map",
            CurrentValue = (hubState.fruitESP == true),
            Callback = function(Value: boolean)
                hubState.fruitESP = Value
                saveState(hubState)
                pcall(function() genv.FruitESPEnabled = Value end)
                if Value then
                    safeNotify("YokaHub ESP", "Đã bật Fruit ESP định vị trái rơi!", "visibility")
                else
                    safeNotify("YokaHub ESP", "Đã tắt Fruit ESP.", "visibility_off")
                end
            end,
        }, "FruitESPToggle")

        MagnetSection:CreateButton({
            Name = "🔍 Quét Số Lượng Trái Đang Rơi Trên Map",
            Description = "Kiểm tra toàn bộ workspace xem hiện tại đang có những trái ác quỷ nào rơi tự do",
            Callback = function()
                local fruitsFound = {}
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                pcall(function()
                    for _, item in ipairs(workspace:GetChildren()) do
                        if item:IsA("Tool") or (item:IsA("Model") and string.find(string.lower(item.Name), "fruit")) then
                            local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                            if handle then
                                local distStr = hrp and string.format(" (%d studs)", math.floor((handle.Position - hrp.Position).Magnitude)) or ""
                                table.insert(fruitsFound, item.Name .. distStr)
                            end
                        end
                    end
                end)
                if #fruitsFound > 0 then
                    safeNotify("YokaHub Quét Trái", string.format("Phát hiện %d trái rơi: %s", #fruitsFound, table.concat(fruitsFound, ", ")), "travel_explore")
                else
                    safeNotify("YokaHub Quét Trái", "Hiện tại không có trái ác quỷ nào đang rơi trên map.", "info")
                end
            end,
        })

        -- ========================================================
        -- SECTION 2: 🛒 BẮN TỈA MUA TRÁI SHOP (SHOP SNIPER)
        -- ========================================================
        local ShopSection = FruitTab:CreateSection("🛒 Bắn Tỉa Mua Trái Shop (Shop Sniper)")

        ShopSection:CreateToggle({
            Name = "🛒 Bật Sniper Tự Mua Trái Khi Mở Bán",
            Description = "Tự động kiểm tra Fruit Shop mỗi vài giây và mua ngay lập tức các trái được tích chọn",
            CurrentValue = (hubState.snipeShop == true),
            Callback = function(Value: boolean)
                hubState.snipeShop = Value
                saveState(hubState)
                pcall(function()
                    genv.shopSniperEnabled = Value
                    genv.shopSniperDelay = hubState.snipeDelay or 5
                end)
                if Value then
                    local count = typeof(hubState.snipeFruitList) == "table" and #hubState.snipeFruitList or 1
                    safeNotify("Shop Sniper", string.format("Đang theo dõi Shop để mua %d loại trái đã tích chọn!", count), "shopping_cart")
                else
                    safeNotify("Shop Sniper", "Đã tắt Sniper mua trái Shop.", "pause_circle")
                end
            end,
        }, "SnipeShopToggle")

        local ALL_SNIPE_FRUITS = {
            "Dragon",
            "Phoenix",
            "Gate",
            "Dough",
            "Erebus",
            "Spirit",
            "Magnet",
            "Toy",
            "Melody",
            "Demon",
            "Snow",
            "Quake",
            "Light",
            "Dark",
            "Rumble",
            "Flame",
            "Magma",
            "Leopard",
        }

        local defaultSnipeList = (typeof(hubState.snipeFruitList) == "table" and #hubState.snipeFruitList > 0)
            and hubState.snipeFruitList
            or { "Dragon", "Phoenix", "Gate", "Dough", "Erebus" }
        hubState.snipeFruitList = defaultSnipeList

        local SnipeFruitDropdownObj: any = nil
        SnipeFruitDropdownObj = ShopSection:CreateDropdown({
            Name = "🎯 Tích Chọn Các Trái Cần Mua (Multi-Select)",
            Description = "Tích chọn cùng lúc nhiều loại trái mong muốn; hệ thống sẽ mua tất cả các trái này khi shop restock",
            Options = ALL_SNIPE_FRUITS,
            CurrentOption = defaultSnipeList,
            MultipleOptions = true,
            Callback = function(opts: any)
                local selected = pickMultiDropdownValue(opts)
                if #selected == 0 then selected = { "Dragon" } end
                hubState.snipeFruitList = selected
                saveState(hubState)
                pcall(function()
                    genv.shopSniperFruits = selected
                end)
                safeNotify("Shop Sniper", "Đã cập nhật " .. tostring(#selected) .. " trái vào danh sách săn mua!", "checklist")
            end,
        }, "SnipeFruitMultiDropdown")

        ShopSection:CreateButton({
            Name = "⭐ Chọn Nhanh Top Trái Thần Thoại Meta",
            Description = "Tự động tích chọn Top 7 trái mạnh nhất: Dragon, Phoenix, Gate, Dough, Erebus, Spirit, Magnet",
            Callback = function()
                local topMeta = { "Dragon", "Phoenix", "Gate", "Dough", "Erebus", "Spirit", "Magnet" }
                hubState.snipeFruitList = topMeta
                saveState(hubState)
                pcall(function()
                    genv.shopSniperFruits = topMeta
                    if SnipeFruitDropdownObj and typeof(SnipeFruitDropdownObj.Set) == "function" then
                        SnipeFruitDropdownObj:Set({ CurrentOption = topMeta })
                    end
                end)
                safeNotify("Shop Sniper", "Đã kích hoạt săn Top 7 Trái Thần Thoại Meta!", "verified")
            end,
        })

        ShopSection:CreateSlider({
            Name = "⏱️ Tần Suất Quét Shop (Giây)",
            Range = { 1, 30 },
            Increment = 1,
            Suffix = " giây",
            CurrentValue = hubState.snipeDelay or 5,
            Callback = function(Value: number)
                hubState.snipeDelay = math.clamp(math.floor(Value), 1, 30)
                saveState(hubState)
                pcall(function()
                    genv.shopSniperDelay = hubState.snipeDelay
                end)
            end,
        }, "SnipeDelaySlider")

        ShopSection:CreateButton({
            Name = "📋 Xem Kho Hàng Shop Hiện Tại (View Shop Stock)",
            Description = "Tra cứu danh sách các trái hiện đang có sẵn trong Fruit Shop của server hiện tại",
            Callback = function()
                task.spawn(function()
                    local currentStock = {}
                    local seen = {}
                    local function addStockName(rawKey: string)
                        local clean = string.gsub(rawKey, "Fruit$", "")
                        local half = math.floor(#clean / 2)
                        if half >= 2 and (#clean % 2 == 0) and string.sub(clean, 1, half) == string.sub(clean, half + 1) then
                            clean = string.sub(clean, 1, half)
                        end
                        if clean ~= "" and not seen[clean] then
                            seen[clean] = true
                            table.insert(currentStock, clean)
                        end
                    end
                    pcall(function()
                        local chest = sharedRS:FindFirstChild("Chest")
                        local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                        local getStockRem = remFuncs and (remFuncs:FindFirstChild("GetDFShop") or remFuncs:FindFirstChild("GetFruitStock") or remFuncs:FindFirstChild("FruitStock") or remFuncs:FindFirstChild("FruitShop"))
                        if getStockRem then
                            local ok, res = pcall(function() return getStockRem:InvokeServer() end)
                            if ok and typeof(res) == "table" then
                                for fName, info in pairs(res) do
                                    if typeof(info) == "table" and (info.InStock == true or info.Stock == true or (tonumber(info.Amount) or 0) > 0) then
                                        addStockName(tostring(fName))
                                    elseif typeof(fName) == "string" and info == true then
                                        addStockName(fName)
                                    end
                                end
                            end
                        end
                        if #currentStock == 0 then
                            local ps = player:FindFirstChild("PlayerStats")
                            local mfs = ps and ps:FindFirstChild("MarketFruitStocks")
                            if mfs and typeof(mfs.Value) == "string" and #mfs.Value > 2 then
                                local dec = httpService:JSONDecode(mfs.Value)
                                if typeof(dec) == "table" then
                                    for k, v in pairs(dec) do
                                        if typeof(v) == "string" then
                                            addStockName(v)
                                        elseif v == true and typeof(k) == "string" then
                                            addStockName(k)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    table.sort(currentStock)
                    if #currentStock > 0 then
                        safeNotify("Fruit Shop (" .. tostring(#currentStock) .. " trái)", "Đang mở bán: " .. table.concat(currentStock, ", "), "store")
                    else
                        safeNotify("Fruit Shop", "Shop đang trong chu kỳ làm mới hoặc không có trái mở bán lúc này.", "info")
                    end
                end)
            end,
        })

        -- ========================================================
        -- SECTION 3: 🎰 QUAY TRÁI ÁC QUỶ TỰ ĐỘNG (AUTO GACHA / ROLL FRUIT)
        -- ========================================================
        local GachaSection = FruitTab:CreateSection("🎰 Quay Trái Ác Quỷ Tự Động (Auto Gacha / Roll Fruit)")

        GachaSection:CreateToggle({
            Name = "🎰 Tự Động Gacha Trái Bằng Beli (2.5M Beli)",
            Description = "Tự động mua lượt quay Random Fruit tại NPC bằng 2,500,000 Beli mỗi khi tích đủ tiền (tự cất rương ngay nếu bật Auto Store)",
            CurrentValue = (hubState.autoGachaFruitBeli == true),
            Callback = function(Value: boolean)
                hubState.autoGachaFruitBeli = Value
                saveState(hubState)
                pcall(function() genv.AutoGachaFruitBeli = Value end)
                if Value then
                    safeNotify("YokaHub Gacha", "Đã bật tự động Gacha Trái bằng Beli!", "casino")
                else
                    safeNotify("YokaHub Gacha", "Đã tắt Gacha Trái bằng Beli.", "info")
                end
            end,
        }, "AutoGachaBeliToggle")

        GachaSection:CreateToggle({
            Name = "💎 Tự Động Gacha Trái Bằng Gems (1 Gem)",
            Description = "Tự động mua lượt quay Random Fruit tại NPC bằng Gems (tự cất rương ngay nếu bật Auto Store)",
            CurrentValue = (hubState.autoGachaFruitGem == true),
            Callback = function(Value: boolean)
                hubState.autoGachaFruitGem = Value
                saveState(hubState)
                pcall(function() genv.AutoGachaFruitGem = Value end)
                if Value then
                    safeNotify("YokaHub Gacha", "Đã bật tự động Gacha Trái bằng Gems!", "diamond")
                else
                    safeNotify("YokaHub Gacha", "Đã tắt Gacha Trái bằng Gems.", "info")
                end
            end,
        }, "AutoGachaGemToggle")

        GachaSection:CreateButton({
            Name = "🎲 Quay Thử 1 Trái Bằng Beli Ngay Lập Tức",
            Description = "Thực hiện ngay 1 lượt quay Random Fruit bằng 2.5M Beli qua Remote NPC",
            Callback = function()
                task.spawn(function()
                    pcall(function()
                        local chest = sharedRS:FindFirstChild("Chest")
                        local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                        local dfBeliRem = remFuncs and remFuncs:FindFirstChild("dfbeli")
                        local etcRem = remFuncs and remFuncs:FindFirstChild("EtcFunction")
                        local gachaRem = remFuncs and (remFuncs:FindFirstChild("RandomFruit") or remFuncs:FindFirstChild("SpinFruit") or remFuncs:FindFirstChild("FruitGacha"))
                        if dfBeliRem or etcRem or gachaRem then
                            if dfBeliRem then
                                pcall(function() dfBeliRem:InvokeServer("Beli") end)
                                pcall(function() dfBeliRem:InvokeServer(1) end)
                                pcall(function() dfBeliRem:InvokeServer() end)
                            end
                            if etcRem then
                                pcall(function() etcRem:InvokeServer("RandomFruit", { Type = "Beli" }) end)
                            end
                            if gachaRem then
                                pcall(function() gachaRem:InvokeServer("Beli") end)
                            end
                            safeNotify("YokaHub Gacha", "Đã gửi yêu cầu quay Random Fruit bằng Beli!", "casino")
                        else
                            safeNotify("YokaHub Gacha", "Không tìm thấy Remote Gacha của game.", "warning")
                        end
                    end)
                end)
            end,
        })

        GachaSection:CreateButton({
            Name = "💎 Quay Thử 1 Trái Bằng Gem Ngay Lập Tức",
            Description = "Thực hiện ngay 1 lượt quay Random Fruit bằng Gems qua Remote NPC",
            Callback = function()
                task.spawn(function()
                    pcall(function()
                        local chest = sharedRS:FindFirstChild("Chest")
                        local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                        local dfBeliRem = remFuncs and remFuncs:FindFirstChild("dfbeli")
                        local dfGemRem = remFuncs and remFuncs:FindFirstChild("dfrobux")
                        local etcRem = remFuncs and remFuncs:FindFirstChild("EtcFunction")
                        local gachaRem = remFuncs and (remFuncs:FindFirstChild("RandomFruit") or remFuncs:FindFirstChild("SpinFruit") or remFuncs:FindFirstChild("FruitGacha"))
                        if dfBeliRem or dfGemRem or etcRem or gachaRem then
                            if dfBeliRem then
                                pcall(function() dfBeliRem:InvokeServer("Gem") end)
                                pcall(function() dfBeliRem:InvokeServer(2) end)
                            end
                            if etcRem then
                                pcall(function() etcRem:InvokeServer("RandomFruit", { Type = "Gem" }) end)
                            end
                            if gachaRem then
                                pcall(function() gachaRem:InvokeServer("Gem") end)
                            end
                            safeNotify("YokaHub Gacha", "Đã gửi yêu cầu quay Random Fruit bằng Gem!", "diamond")
                        else
                            safeNotify("YokaHub Gacha", "Không tìm thấy Remote Gacha của game.", "warning")
                        end
                    end)
                end)
            end,
        })

        -- ========================================================
        -- SECTION 4: 📤 QUẢN LÝ & THAO TÁC KHO RƯƠNG (STORAGE & INVENTORY)
        -- ========================================================
        local InventoryActionsSection = FruitTab:CreateSection("📤 Quản Lý & Thao Tác Kho Rương (Storage & Inventory)")

        local UNSTORE_OPTIONS = {
            "Dragon",
            "Phoenix",
            "Gate",
            "Dough",
            "Erebus",
            "Spirit",
            "Magnet",
            "Toy",
            "Melody",
            "Demon",
            "Snow",
            "Quake",
            "Light",
            "Dark",
            "Rumble",
            "Flame",
            "Magma",
            "Leopard",
        }
        local defaultUnstore = table.find(UNSTORE_OPTIONS, hubState.selectedUnstoreFruit) and hubState.selectedUnstoreFruit or UNSTORE_OPTIONS[1]

        InventoryActionsSection:CreateDropdown({
            Name = "Chọn Trái Cụ Thể Trong Rương Muốn Rút",
            Description = "Chọn chính xác loại trái ác quỷ bạn muốn rút ra từ FruitStore",
            Options = UNSTORE_OPTIONS,
            CurrentOption = { defaultUnstore },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.selectedUnstoreFruit = val
                saveState(hubState)
            end,
        }, "SelectUnstoreFruitDropdown")

        InventoryActionsSection:CreateButton({
            Name = "📥 Rút Trái Đã Chọn Ra Balo (Unstore Selected Fruit)",
            Description = "Rút đúng loại trái ác quỷ đã chọn ở trên từ rương ra túi đồ",
            Callback = function()
                task.spawn(function()
                    local target = hubState.selectedUnstoreFruit or "Dragon"
                    pcall(function()
                        local chest = sharedRS:FindFirstChild("Chest")
                        local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                        local dealFruit = remFuncs and remFuncs:FindFirstChild("DealFruit")
                        if dealFruit then
                            dealFruit:InvokeServer(target, "Unstore")
                            dealFruit:InvokeServer(target .. "Fruit", "Unstore")
                            safeNotify("YokaHub Kho Đồ", "Đã rút trái [" .. target .. "] từ rương ra balo!", "inventory")
                        end
                    end)
                end)
            end,
        })

        InventoryActionsSection:CreateButton({
            Name = "📦 Lấy Toàn Bộ Trái Ra Khỏi Rương (Unstore All)",
            Description = "Rút tất cả trái ác quỷ trong rương đồ ra balo cá nhân qua DealFruit chính thức",
            Callback = function()
                task.spawn(function()
                    local unstored = 0
                    pcall(function()
                        local chest = sharedRS:FindFirstChild("Chest")
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
            Name = "⚠️ Thả Trái Đang Cầm Ra Đất (Drop Held Fruit)",
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
                        local chest = sharedRS:FindFirstChild("Chest")
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

        InventoryActionsSection:CreateButton({
            Name = "🍽️ Ăn Trái Đang Cầm Trên Tay (Eat Held Fruit)",
            Description = "Ăn trái ác quỷ vật lý đang cầm trên tay để nhận sức mạnh trái ác quỷ mới",
            Callback = function()
                pcall(function()
                    local char = player.Character
                    local held = char and char:FindFirstChildOfClass("Tool")
                    if held and held.ToolTip ~= "Fruit Power" and string.find(string.lower(held.Name), "fruit") then
                        local chest = sharedRS:FindFirstChild("Chest")
                        local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                        if remFuncs and remFuncs:FindFirstChild("DealFruit") then
                            pcall(function() remFuncs.DealFruit:InvokeServer(held.Name, "Eat") end)
                            safeNotify("YokaHub", "Đã kích hoạt ăn trái [" .. held.Name .. "]!", "restaurant")
                        end
                    else
                        safeNotify("YokaHub", "Hãy cầm trái ác quỷ vật lý trên tay trước khi bấm Ăn!", "warning")
                    end
                end)
            end,
        })
    end
