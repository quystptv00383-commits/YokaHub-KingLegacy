    -- ========================================================
    -- TAB 4: GOM NGUYEN LIEU (MATERIAL COLLECTOR)
    -- ========================================================
    do
        local MatTab = Window:CreateTab({
            Name = "📦 Gom Nguyên Liệu",
            Icon = "all_inbox",
            ImageSource = "Material",
            ShowTitle = false,
        })

        local Sea3MatSection = MatTab:CreateSection("🌊 Nguyên Liệu Sea 3 (Cực Hiếm)")
        local FarmSea3MatToggle = Sea3MatSection:CreateToggle({
            Name = "📦 Bật Cày Nguyên Liệu Sea 3",
            Description = "Tự động di chuyển đến bãi farm nguyên liệu tương ứng ở Sea 3",
            CurrentValue = hubState.farmSea3Mat,
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.farmSea3Mat = Value
                if Value then
                    deactivateOtherLocalModes("farmSea3Mat")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang cày nguyên liệu Sea 3 — Tạm dừng Săn Boss.")
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
                if Value then safeNotify("YokaHub Nguyên Liệu", "Đang cày nguyên liệu Sea 3: " .. tostring(hubState.nguyenlieuSea3), "layers") end
            end,
        }, "FarmSea3MatToggle")
        registerLocalModeToggle("farmSea3Mat", FarmSea3MatToggle)

        local sea3Options = {
            "Coral (San Hô)",
            "Shark's Fin (Vây Cá Mập)",
            "Dragon Scale (Vảy Rồng)",
            "Sea King's Blood (Máu Hải Vương)",
            "Phoenix Tear (Nước Mắt Phượng Hoàng)",
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
            end,
        }, "Sea3MatDropdown")

        local Sea2MatSection = MatTab:CreateSection("🔱 Nguyên Liệu Sea 2")
        local FarmSea2MatToggle = Sea2MatSection:CreateToggle({
            Name = "📦 Bật Cày Nguyên Liệu Sea 2",
            Description = "Tự động di chuyển đến bãi farm nguyên liệu tương ứng ở Sea 2",
            CurrentValue = hubState.farmSea2Mat,
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.farmSea2Mat = Value
                if Value then
                    deactivateOtherLocalModes("farmSea2Mat")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang cày nguyên liệu Sea 2 — Tạm dừng Săn Boss.")
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
                if Value then safeNotify("YokaHub Nguyên Liệu", "Đang cày nguyên liệu Sea 2: " .. tostring(hubState.nguyenlieuSea2), "layers") end
            end,
        }, "FarmSea2MatToggle")
        registerLocalModeToggle("farmSea2Mat", FarmSea2MatToggle)

        local sea2Options = {
            "Iron Ingot (Sắt Thỏi)",
            "Dark Powder (Bột Bóng Đêm)",
            "Ghost Flesh (Thịt Ma)",
            "Magma Crystal (Tinh Thể Nham Thạch)",
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
            end,
        }, "Sea2MatDropdown")

        local Sea1MatSection = MatTab:CreateSection("⛵ Nguyên Liệu Sea 1")
        local FarmSea1MatToggle = Sea1MatSection:CreateToggle({
            Name = "📦 Bật Cày Nguyên Liệu Sea 1",
            Description = "Tự động di chuyển đến bãi farm nguyên liệu tương ứng ở Sea 1",
            CurrentValue = hubState.farmSea1Mat,
            Callback = function(Value: boolean)
                if syncingLocalToggles then return end
                hubState.farmSea1Mat = Value
                if Value then
                    deactivateOtherLocalModes("farmSea1Mat")
                    if currentMode ~= "off" then
                        applyMode("off", false)
                        setStatus("Đang cày nguyên liệu Sea 1 — Tạm dừng Săn Boss.")
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
                if Value then safeNotify("YokaHub Nguyên Liệu", "Đang cày nguyên liệu Sea 1: " .. tostring(hubState.nguyenlieuSea1), "layers") end
            end,
        }, "FarmSea1MatToggle")
        registerLocalModeToggle("farmSea1Mat", FarmSea1MatToggle)

        local sea1Options = {
            "Leather (Da Thuộc)",
            "Wood (Gỗ Cổ Thụ)",
            "Rope (Dây Thừng)",
            "Thief Rag (Vải Tặc)",
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
            end,
        }, "Sea1MatDropdown")

        local QueueSection = MatTab:CreateSection("🔢 Chế Độ Gom Theo Số Lượng (Quantity Tracker)")
        QueueSection:CreateToggle({
            Name = "🎯 Cày Đủ Số Lượng Tự Chuyển Món Tiếp Theo",
            Description = "Tự động ngưng khi gom đủ số lượng nguyên liệu đặt ra",
            CurrentValue = hubState.materialQuantityTracker == true,
            Callback = function(Value: boolean)
                hubState.materialQuantityTracker = Value
                saveState(hubState)
                pcall(function()
                    genv.MaterialQuantityTracker = Value
                end)
            end,
        }, "MaterialQuantityTrackerToggle")
    end
