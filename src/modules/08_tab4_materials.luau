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
        Sea3MatSection:CreateToggle({
            Name = "📦 Bật Cày Nguyên Liệu Sea 3",
            Description = "Tự động di chuyển đến bãi farm nguyên liệu tương ứng ở Sea 3",
            CurrentValue = hubState.farmSea3Mat,
            Callback = function(Value: boolean)
                hubState.farmSea3Mat = Value
                if Value and currentMode ~= "off" then
                    applyMode("off", false)
                    setStatus("Đang cày nguyên liệu Sea 3 — Tạm dừng Săn Boss.")
                end
                saveState(hubState)
                pcall(function()
                    genv.farmMaterialsea3 = Value
                    genv.start = Value
                    if Value then
                        local rawMat = string.match(hubState.nguyenlieuSea3 or "", "^([%w%s%']+)") or "Coral"
                        rawMat = string.gsub(rawMat, "%s+$", "")
                        genv.nguyenlieusea3 = rawMat
                        genv.autocat = true
                        genv.haki = true
                    end
                end)
                if Value then safeNotify("YokaHub Nguyên Liệu", "Đang cày nguyên liệu Sea 3: " .. tostring(hubState.nguyenlieuSea3), "layers") end
            end,
        }, "FarmSea3MatToggle")

        Sea3MatSection:CreateDropdown({
            Name = "Chọn Nguyên Liệu Sea 3 Muốn Gom",
            Options = {
                "Coral (San Hô)",
                "Shark's Fin (Vây Cá Mập)",
                "Dragon Scale (Vảy Rồng)",
                "Sea King's Blood (Máu Hải Vương)",
                "Phoenix Tear (Nước Mắt Phượng Hoàng)",
            },
            CurrentOption = { hubState.nguyenlieuSea3 or "Coral (San Hô)" },
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
        Sea2MatSection:CreateToggle({
            Name = "📦 Bật Cày Nguyên Liệu Sea 2",
            Description = "Tự động di chuyển đến bãi farm nguyên liệu tương ứng ở Sea 2",
            CurrentValue = hubState.farmSea2Mat,
            Callback = function(Value: boolean)
                hubState.farmSea2Mat = Value
                if Value and currentMode ~= "off" then
                    applyMode("off", false)
                    setStatus("Đang cày nguyên liệu Sea 2 — Tạm dừng Săn Boss.")
                end
                saveState(hubState)
                pcall(function()
                    genv.farmMaterialsea2 = Value
                    genv.start = Value
                    if Value then
                        local rawMat = string.match(hubState.nguyenlieuSea2 or "", "^([%w%s%']+)") or "Iron Ingot"
                        rawMat = string.gsub(rawMat, "%s+$", "")
                        genv.nguyenlieusea2 = rawMat
                        genv.autocat = true
                        genv.haki = true
                    end
                end)
                if Value then safeNotify("YokaHub Nguyên Liệu", "Đang cày nguyên liệu Sea 2: " .. tostring(hubState.nguyenlieuSea2), "layers") end
            end,
        }, "FarmSea2MatToggle")

        Sea2MatSection:CreateDropdown({
            Name = "Chọn Nguyên Liệu Sea 2 Muốn Gom",
            Options = {
                "Iron Ingot (Sắt Thỏi)",
                "Dark Powder (Bột Bóng Đêm)",
                "Ghost Flesh (Thịt Ma)",
                "Magma Crystal (Tinh Thể Nham Thạch)",
            },
            CurrentOption = { hubState.nguyenlieuSea2 or "Iron Ingot (Sắt Thỏi)" },
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
        Sea1MatSection:CreateToggle({
            Name = "📦 Bật Cày Nguyên Liệu Sea 1",
            Description = "Tự động di chuyển đến bãi farm nguyên liệu tương ứng ở Sea 1",
            CurrentValue = hubState.farmSea1Mat,
            Callback = function(Value: boolean)
                hubState.farmSea1Mat = Value
                if Value and currentMode ~= "off" then
                    applyMode("off", false)
                    setStatus("Đang cày nguyên liệu Sea 1 — Tạm dừng Săn Boss.")
                end
                saveState(hubState)
                pcall(function()
                    genv.farmMaterialsea1 = Value
                    genv.start = Value
                    if Value then
                        local rawMat = string.match(hubState.nguyenlieuSea1 or "", "^([%w%s%']+)") or "Leather"
                        rawMat = string.gsub(rawMat, "%s+$", "")
                        genv.nguyenlieusea1 = rawMat
                        genv.autocat = true
                        genv.haki = true
                    end
                end)
                if Value then safeNotify("YokaHub Nguyên Liệu", "Đang cày nguyên liệu Sea 1: " .. tostring(hubState.nguyenlieuSea1), "layers") end
            end,
        }, "FarmSea1MatToggle")

        Sea1MatSection:CreateDropdown({
            Name = "Chọn Nguyên Liệu Sea 1 Muốn Gom",
            Options = {
                "Leather (Da Thuộc)",
                "Wood (Gỗ Cổ Thụ)",
                "Rope (Dây Thừng)",
                "Thief Rag (Vải Tặc)",
            },
            CurrentOption = { hubState.nguyenlieuSea1 or "Leather (Da Thuộc)" },
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
            CurrentValue = false,
            Callback = function(Value: boolean)
                pcall(function()
                    genv.MaterialQuantityTracker = Value
                end)
            end,
        }, "MaterialQuantityTrackerToggle")
    end
