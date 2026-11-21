    -- ========================================================
    -- TAB 4: GOM NGUYEN LIEU (MATERIAL COLLECTOR & TRACKER)
    -- ========================================================
    do
        local MatTab = Window:CreateTab({
            Name = "📦 Gom Nguyên Liệu",
            Icon = "all_inbox",
            ImageSource = "Material",
            ShowTitle = false,
        })

        -- ========================================================
        -- HELPER: PARSE & FORMAT LIVE MATERIAL INVENTORY
        -- ========================================================
        local function parseMaterialStats(): { [string]: number }
            local res: { [string]: number } = {}
            pcall(function()
                local ps = player:FindFirstChild("PlayerStats")
                local matObj = ps and ps:FindFirstChild("Material")
                if matObj and typeof(matObj.Value) == "string" and #matObj.Value > 2 then
                    local ok, tbl = pcall(function()
                        return game:GetService("HttpService"):JSONDecode(matObj.Value)
                    end)
                    if ok and typeof(tbl) == "table" then
                        for k, v in pairs(tbl) do
                            local num = tonumber(v)
                            if num and num > 0 then
                                res[tostring(k)] = num
                            end
                        end
                    end
                end
            end)
            return res
        end

        local function formatMaterialInventory(): (string, string)
            local mats = parseMaterialStats()
            local entries = {}
            for name, qty in pairs(mats) do
                table.insert(entries, { name = name, count = qty })
            end
            table.sort(entries, function(a, b)
                return a.count > b.count
            end)

            local content = ""
            if #entries == 0 then
                content = "📦 Túi đồ chưa có dữ liệu nguyên liệu (Hãy mở giao diện game hoặc tiêu diệt 1 quái để đồng bộ dữ liệu)."
            else
                local itemsList = {}
                for _, item in ipairs(entries) do
                    table.insert(itemsList, "• " .. item.name .. ": " .. tostring(item.count))
                end
                content = table.concat(itemsList, "  |  ")
            end

            -- Xác định nguyên liệu đang được nhắm tới
            local curMatRaw = "Coral"
            local activeSea = "Sea 3"
            if hubState.farmSea2Mat then
                curMatRaw = string.match(hubState.nguyenlieuSea2 or "", "^([%w%s%']+)") or "Iron Ingot"
                activeSea = "Sea 2"
            elseif hubState.farmSea1Mat then
                curMatRaw = string.match(hubState.nguyenlieuSea1 or "", "^([%w%s%']+)") or "Leather"
                activeSea = "Sea 1"
            else
                curMatRaw = string.match(hubState.nguyenlieuSea3 or "", "^([%w%s%']+)") or "Coral"
                activeSea = "Sea 3"
            end
            curMatRaw = string.gsub(curMatRaw, "%s+$", "")

            local owned = mats[curMatRaw] or 0
            local quota = tonumber(hubState.materialQuota) or 50
            local pct = math.clamp(math.floor((owned / math.max(1, quota)) * 100), 0, 100)
            local status = string.format("🎯 Mục Tiêu: [%s] (%s) | Sở hữu: %d / %d (%d%%)", curMatRaw, activeSea, owned, quota, pct)

            return content, status
        end

        -- ========================================================
        -- SECTION 1: 📊 THỐNG KÊ TÚI NGUYÊN LIỆU (LIVE INVENTORY)
        -- ========================================================
        local StatusSection = MatTab:CreateSection("📊 Thống Kê Túi Nguyên Liệu (Live Inventory)")

        local initContent, initStatus = formatMaterialInventory()

        local InvPara = StatusSection:CreateParagraph({
            Title = "📦 Túi Nguyên Liệu Trực Tiếp (Live Inventory)",
            Text = initContent,
        })

        local StatusPara = StatusSection:CreateParagraph({
            Title = "🎯 Tiến Độ Mục Tiêu Hiện Tại",
            Text = initStatus,
        })

        local function refreshInventoryUI()
            local c, s = formatMaterialInventory()
            pcall(function()
                InvPara:Set({ Text = c })
                StatusPara:Set({ Text = s })
            end)
        end

        StatusSection:CreateButton({
            Name = "🔄 Làm Mới Dữ Liệu Túi Đồ (Refresh Inventory)",
            Description = "Cập nhật tức thì số lượng nguyên liệu mới nhất từ PlayerStats",
            Callback = function()
                refreshInventoryUI()
                safeNotify("YokaHub Nguyên Liệu", "Đã cập nhật dữ liệu túi đồ nguyên liệu mới nhất!", "refresh")
            end,
        })

        -- Luồng ngầm định kỳ làm mới dữ liệu túi khi đang cày nguyên liệu
        task.spawn(function()
            while genv._YokaHubToken == myToken do
                task.wait(3.5)
                if hubState.farmSea3Mat or hubState.farmSea2Mat or hubState.farmSea1Mat or hubState.materialQuantityTracker then
                    pcall(refreshInventoryUI)
                end
            end
        end)

        -- ========================================================
        -- SECTION 2: 🌊 NGUYÊN LIỆU SEA 3 (CỰC HIẾM)
        -- ========================================================
        local Sea3MatSection = MatTab:CreateSection("🌊 Nguyên Liệu Sea 3 (Cực Hiếm)")

        local FarmSea3MatToggle = Sea3MatSection:CreateToggle({
            Name = "📦 Bật Cày Nguyên Liệu Sea 3",
            Description = "Tự động bay đến bãi farm nguyên liệu tương ứng ở Sea 3",
            CurrentValue = (hubState.farmSea3Mat == true),
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.farmSea3Mat = Value
                if Value then
                    deactivateOtherLocalModes("farmSea3Mat")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang cày nguyên liệu Sea 3 — Tạm dừng Săn Boss.")
                    end
                    if game.PlaceId ~= SEA3_PLACE then
                        safeNotify("Khác Vùng Biển", "Bạn đang không ở Sea 3! Nguyên liệu này chỉ rơi tại Sea 3. Hãy chuyển Sea tại Tab Tiện Ích.", "warning")
                    end
                end
                saveState(hubState)
                pcall(function()
                    if Value then
                        local rawMat = string.match(hubState.nguyenlieuSea3 or "", "^([%w%s%']+)") or "Coral"
                        rawMat = string.gsub(rawMat, "%s+$", "")
                        genv.nguyenlieusea3 = rawMat
                        genv.autocat = hubState.fastMobBring ~= false
                        genv.haki = hubState.autoHaki ~= false
                    end
                end)
                refreshInventoryUI()
                if Value then
                    safeNotify("YokaHub Nguyên Liệu", "Đang cày nguyên liệu Sea 3: " .. tostring(hubState.nguyenlieuSea3), "layers")
                end
            end,
        }, "FarmSea3MatToggle")
        registerLocalModeToggle("farmSea3Mat", FarmSea3MatToggle)

        local sea3Options = {
            "Coral (San Hô)",
            "Shark's Fin (Vây Cá Mập)",
            "Dragon Scale (Vảy Rồng)",
            "Sea King's Blood (Máu Hải Vương)",
            "Phoenix Tear (Nước Mắt Phượng Hoàng)",
            "Pure Feather (Lông Vũ Thuần Khiết)",
            "Lost Ruby (Hồng Ngọc Thất Lạc)",
            "Crab Meat (Thịt Cua Biển)",
            "Ghost Flesh (Thịt Ma Sea 3)",
        }
        local defaultSea3 = table.find(sea3Options, hubState.nguyenlieuSea3) and hubState.nguyenlieuSea3 or "Coral (San Hô)"
        Sea3MatSection:CreateDropdown({
            Name = "Chọn Nguyên Liệu Sea 3 Muốn Gom",
            Options = sea3Options,
            CurrentOption = { defaultSea3 },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.nguyenlieuSea3 = val
                saveState(hubState)
                pcall(function()
                    local rawMat = string.match(val, "^([%w%s%']+)") or "Coral"
                    rawMat = string.gsub(rawMat, "%s+$", "")
                    genv.nguyenlieusea3 = rawMat
                end)
                refreshInventoryUI()
            end,
        }, "Sea3MatDropdown")

        -- ========================================================
        -- SECTION 3: 🔱 NGUYÊN LIỆU SEA 2
        -- ========================================================
        local Sea2MatSection = MatTab:CreateSection("🔱 Nguyên Liệu Sea 2")

        local FarmSea2MatToggle = Sea2MatSection:CreateToggle({
            Name = "📦 Bật Cày Nguyên Liệu Sea 2",
            Description = "Tự động bay đến bãi farm nguyên liệu tương ứng ở Sea 2",
            CurrentValue = (hubState.farmSea2Mat == true),
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.farmSea2Mat = Value
                if Value then
                    deactivateOtherLocalModes("farmSea2Mat")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang cày nguyên liệu Sea 2 — Tạm dừng Săn Boss.")
                    end
                    if game.PlaceId ~= SEA2_PLACE then
                        safeNotify("Khác Vùng Biển", "Bạn đang không ở Sea 2! Nguyên liệu này chỉ rơi tại Sea 2. Hãy chuyển Sea tại Tab Tiện Ích.", "warning")
                    end
                end
                saveState(hubState)
                pcall(function()
                    if Value then
                        local rawMat = string.match(hubState.nguyenlieuSea2 or "", "^([%w%s%']+)") or "Iron Ingot"
                        rawMat = string.gsub(rawMat, "%s+$", "")
                        genv.nguyenlieusea2 = rawMat
                        genv.autocat = hubState.fastMobBring ~= false
                        genv.haki = hubState.autoHaki ~= false
                    end
                end)
                refreshInventoryUI()
                if Value then
                    safeNotify("YokaHub Nguyên Liệu", "Đang cày nguyên liệu Sea 2: " .. tostring(hubState.nguyenlieuSea2), "layers")
                end
            end,
        }, "FarmSea2MatToggle")
        registerLocalModeToggle("farmSea2Mat", FarmSea2MatToggle)

        local sea2Options = {
            "Iron Ingot (Sắt Thỏi)",
            "Dark Powder (Bột Bóng Đêm)",
            "Ghost Flesh (Thịt Ma Sea 2)",
            "Magma Crystal (Tinh Thể Nham Thạch)",
            "Fresh Fish (Cá Tươi)",
            "Hard Shell (Mai Rùa Cứng)",
            "Gunpowder (Thuốc Súng)",
        }
        local defaultSea2 = table.find(sea2Options, hubState.nguyenlieuSea2) and hubState.nguyenlieuSea2 or "Iron Ingot (Sắt Thỏi)"
        Sea2MatSection:CreateDropdown({
            Name = "Chọn Nguyên Liệu Sea 2 Muốn Gom",
            Options = sea2Options,
            CurrentOption = { defaultSea2 },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.nguyenlieuSea2 = val
                saveState(hubState)
                pcall(function()
                    local rawMat = string.match(val, "^([%w%s%']+)") or "Iron Ingot"
                    rawMat = string.gsub(rawMat, "%s+$", "")
                    genv.nguyenlieusea2 = rawMat
                end)
                refreshInventoryUI()
            end,
        }, "Sea2MatDropdown")

        -- ========================================================
        -- SECTION 4: ⛵ NGUYÊN LIỆU SEA 1
        -- ========================================================
        local Sea1MatSection = MatTab:CreateSection("⛵ Nguyên Liệu Sea 1")

        local FarmSea1MatToggle = Sea1MatSection:CreateToggle({
            Name = "📦 Bật Cày Nguyên Liệu Sea 1",
            Description = "Tự động bay đến bãi farm nguyên liệu tương ứng ở Sea 1",
            CurrentValue = (hubState.farmSea1Mat == true),
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.farmSea1Mat = Value
                if Value then
                    deactivateOtherLocalModes("farmSea1Mat")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang cày nguyên liệu Sea 1 — Tạm dừng Săn Boss.")
                    end
                    if game.PlaceId ~= SEA1_PLACE then
                        safeNotify("Khác Vùng Biển", "Bạn đang không ở Sea 1! Nguyên liệu này chỉ rơi tại Sea 1. Hãy chuyển Sea tại Tab Tiện Ích.", "warning")
                    end
                end
                saveState(hubState)
                pcall(function()
                    if Value then
                        local rawMat = string.match(hubState.nguyenlieuSea1 or "", "^([%w%s%']+)") or "Leather"
                        rawMat = string.gsub(rawMat, "%s+$", "")
                        genv.nguyenlieusea1 = rawMat
                        genv.autocat = hubState.fastMobBring ~= false
                        genv.haki = hubState.autoHaki ~= false
                    end
                end)
                refreshInventoryUI()
                if Value then
                    safeNotify("YokaHub Nguyên Liệu", "Đang cày nguyên liệu Sea 1: " .. tostring(hubState.nguyenlieuSea1), "layers")
                end
            end,
        }, "FarmSea1MatToggle")
        registerLocalModeToggle("farmSea1Mat", FarmSea1MatToggle)

        local sea1Options = {
            "Leather (Da Thuộc)",
            "Wood (Gỗ Cổ Thụ)",
            "Rope (Dây Thừng)",
            "Thief Rag (Vải Tặc)",
            "Fish Bone (Xương Cá)",
            "Carrot (Cà Rốt)",
        }
        local defaultSea1 = table.find(sea1Options, hubState.nguyenlieuSea1) and hubState.nguyenlieuSea1 or "Leather (Da Thuộc)"
        Sea1MatSection:CreateDropdown({
            Name = "Chọn Nguyên Liệu Sea 1 Muốn Gom",
            Options = sea1Options,
            CurrentOption = { defaultSea1 },
            MultipleOptions = false,
            Callback = function(opt: any)
                local val = pickDropdownValue(opt)
                hubState.nguyenlieuSea1 = val
                saveState(hubState)
                pcall(function()
                    local rawMat = string.match(val, "^([%w%s%']+)") or "Leather"
                    rawMat = string.gsub(rawMat, "%s+$", "")
                    genv.nguyenlieusea1 = rawMat
                end)
                refreshInventoryUI()
            end,
        }, "Sea1MatDropdown")

        -- ========================================================
        -- SECTION 5: 🎯 CÀI ĐẶT MỤC TIÊU & TỰ ĐỘNG DỪNG (QUOTA & SAFETY)
        -- ========================================================
        local QueueSection = MatTab:CreateSection("🎯 Cài Đặt Mục Tiêu & Tự Động Dừng (Quota & Safety)")

        QueueSection:CreateSlider({
            Name = "🎯 Mục Tiêu Số Lượng Cần Gom (Target Quota)",
            Description = "Đặt số lượng nguyên liệu cần farm trước khi bot tự động dừng (5 - 500)",
            Range = { 5, 500 },
            Increment = 5,
            CurrentValue = math.clamp(tonumber(hubState.materialQuota) or 50, 5, 500),
            Callback = function(Value: number)
                hubState.materialQuota = Value
                saveState(hubState)
                refreshInventoryUI()
            end,
        }, "MaterialQuotaSlider")

        QueueSection:CreateToggle({
            Name = "🛑 Tự Động Dừng Khi Đạt Đủ Mục Tiêu (Stop on Quota)",
            Description = "Tự động tắt toggle cày nguyên liệu ngay khi số lượng trong túi đạt chỉ tiêu",
            CurrentValue = (hubState.materialQuantityTracker == true),
            Callback = function(Value: boolean)
                hubState.materialQuantityTracker = Value
                saveState(hubState)
                pcall(function()
                    genv.MaterialQuantityTracker = Value
                end)
                if Value then
                    safeNotify("YokaHub Mục Tiêu", "Đã bật tự động dừng cày khi đủ số lượng nguyên liệu!", "verified")
                end
            end,
        }, "MaterialQuantityTrackerToggle")

        QueueSection:CreateToggle({
            Name = "🧲 Tự Động Gom Quái Xung Quanh (Mob Magnet Bring)",
            Description = "Kéo quái xung quanh lại một điểm để tiêu diệt đồng loạt, tăng tốc độ gom nguyên liệu",
            CurrentValue = (hubState.fastMobBring ~= false),
            Callback = function(Value: boolean)
                hubState.fastMobBring = Value
                saveState(hubState)
                pcall(function()
                    genv.autocat = Value
                end)
            end,
        }, "MobBringToggle")

        QueueSection:CreateSlider({
            Name = "📏 Bán Kính Gom Quái (Bring Studs)",
            Description = "Khoảng cách tối đa để quét và hút quái lại điểm gom (100 - 1200 studs)",
            Range = { 100, 1200 },
            Increment = 50,
            CurrentValue = math.clamp(tonumber(hubState.mobBringRange) or 800, 100, 1200),
            Callback = function(Value: number)
                hubState.mobBringRange = Value
                saveState(hubState)
                pcall(function()
                    genv.MobBringRange = Value
                end)
            end,
        }, "MobBringRangeSlider")

        -- Lưu lại tham chiếu các toggle nguyên liệu để tracker tự động tắt khi đủ số lượng
        genv._YokaMatToggles = {
            sea3 = FarmSea3MatToggle,
            sea2 = FarmSea2MatToggle,
            sea1 = FarmSea1MatToggle,
        }
    end