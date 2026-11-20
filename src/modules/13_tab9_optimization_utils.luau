    -- ========================================================
    -- TAB 3: TIEN ICH
    -- ========================================================
    do
        local UtilTab = Window:CreateTab({
            Name = "Tiện ích",
            Icon = "bolt",
            ImageSource = "Material",
            ShowTitle = false,
        })

    local SysSection = UtilTab:CreateSection("🛡️ Cài đặt & Chuyển Sea nhanh")
    SysSection:CreateToggle({
        Name = "🛡️ Tự đóng bảng lỗi (773 / 772)",
        Description = "Tự tắt thông báo phòng đầy / VIP để game không bị đứng",
        CurrentValue = hubState.autoDismiss773,
        Callback = function(Value: boolean)
            hubState.autoDismiss773 = Value
            saveState(hubState)
        end,
    }, "AutoDismiss773")

    SysSection:CreateToggle({
        Name = "▶️ Tự Động Nhấn Play Khi Load Xong",
        Description = "Tự động bấm nút Play/Start trên giao diện Menu khi vào phòng để nhân vật xuất hiện ngay",
        CurrentValue = hubState.autoClickPlay,
        Callback = function(Value: boolean)
            hubState.autoClickPlay = Value
            saveState(hubState)
            if Value then
                armAutoReexec(false)
                triggerKingLegacyAutoPlay(function() return hubState.autoClickPlay ~= false end)
                safeNotify("YokaHub", "Đã bật tự động nhấn Play ngay khi vào server / hop server!", "play_circle")
            else
                safeNotify("YokaHub", "Đã tắt tự động nhấn Play.", "info")
            end
        end,
    }, "AutoClickPlayToggle")

    if hubState.autoReexec or hubState.autoClickPlay then
        task.defer(function() armAutoReexec(false) end)
    end

    SysSection:CreateToggle({
        Name = "⚡ Tự chạy lại khi vào SV (Delta)",
        Description = "Tự execute lại YokaHub khi chuyển phòng (Delta / Mobile)",
        CurrentValue = hubState.autoReexec,
        Callback = function(Value: boolean)
            hubState.autoReexec = Value
            saveState(hubState)
            if Value then
                armAutoReexec(true)
            else
                safeNotify("YokaHub", "Đã tắt tự động chạy lại khi chuyển server.", "notifications")
            end
        end,
    }, "AutoReexecOnHop")

    local defaultTravel = (game.PlaceId == SEA2_PLACE and "Sea 3") or (game.PlaceId == SEA3_PLACE and "Sea 2") or "Sea 3"
    local travelChoice = defaultTravel
    SysSection:CreateDropdown({
        Name = "Chọn điểm muốn đến",
        Options = { "Sea 3", "Sea 2", "Sea 1", "Tải lại phòng hiện tại" },
        CurrentOption = { defaultTravel },
        MultipleOptions = false,
        Callback = function(opt: any) travelChoice = pickDropdownValue(opt) end,
    }, "TravelChoice")

    SysSection:CreateButton({
        Name = "🧭 Di chuyển ngay",
        Callback = function()
            local targetPlace = nil
            if travelChoice == "Sea 3" then targetPlace = SEA3_PLACE
            elseif travelChoice == "Sea 2" then targetPlace = SEA2_PLACE
            elseif travelChoice == "Sea 1" then targetPlace = SEA1_PLACE
            end

            if targetPlace and targetPlace == game.PlaceId then
                safeNotify("YokaHub", "Bạn đang ở " .. travelChoice .. " rồi! Nếu muốn đổi server, hãy chọn 'Tải lại phòng hiện tại'.", "info")
                return
            end

            if currentMode ~= "off" then
                applyMode("off", false)
            end
            safeNotify("YokaHub", "Đang di chuyển tới " .. travelChoice .. "...", "public")
            task.spawn(function()
                pcall(function()
                    hubState.mode = "off"
                    saveState(hubState)
                    armAutoReexec(false)
                    if targetPlace then
                        if teleportToSea then
                            teleportToSea(targetPlace)
                        else
                            teleportService:Teleport(targetPlace, players.LocalPlayer)
                        end
                    else
                        teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, players.LocalPlayer)
                    end
                end)
            end)
        end,
    })

    local KeySection = UtilTab:CreateSection("🔑 Quản lý Bản Quyền & Key")
    KeySection:CreateButton({
        Name = "🚪 Thoát ra Trang Get Key (Đăng Xuất / Đổi Key)",
        Description = "Xoá mã Key lưu trên máy, đóng Hub và quay lại Cổng Get Key / Nhập Key",
        Callback = function()
            doExitToGateway()
        end,
    })

    local PerfSection = UtilTab:CreateSection("🌙 Chế Độ Treo Máy Đêm Siêu Nhẹ (AFK Overnight)")
    PerfSection:CreateToggle({
        Name = "🌑 Màn Hình Đen (Black Screen) - Giảm 80% CPU & GPU",
        Description = "Dừng dựng hình 3D, màn hình tối nhẹ giúp máy mát rượi khi treo đêm",
        CurrentValue = hubState.blackScreen,
        Callback = function(Value: boolean)
            hubState.blackScreen = Value
            saveState(hubState)
            pcall(function()
                if typeof(genv.WK_ApplyBlackScreen) == "function" then
                    genv.WK_ApplyBlackScreen(Value)
                else
                    genv.BlackScreen = Value
                end
            end)
            if Value then
                safeNotify("YokaHub AFK", "Đã bật Màn hình đen tiết kiệm pin!", "dark_mode")
            else
                safeNotify("YokaHub AFK", "Đã tắt Màn hình đen.", "light_mode")
            end
        end,
    }, "BlackScreenToggle")

    PerfSection:CreateToggle({
        Name = "⚡ Fast Mode (Xóa Hiệu Ứng Thừa & Giảm Tải GPU)",
        Description = "Hạ chất lượng đồ họa, tắt bóng đổ và hiệu ứng hạt thừa ngay lập tức để tăng FPS",
        CurrentValue = hubState.fastMode,
        Callback = function(Value: boolean)
            hubState.fastMode = Value
            saveState(hubState)
            applyFastModeSetting(Value)
            pcall(function()
                genv.fastMode = Value
                genv.lowTextureMap = Value
                genv.removeEffects = Value
            end)
            safeNotify("Fast Mode", Value and "Đã bật chế độ siêu mượt (tắt bóng & giảm tải GPU)!" or "Đã khôi phục đồ họa mặc định.", "speed")
        end,
    }, "FastModeToggle")

    PerfSection:CreateToggle({
        Name = "🛡️ Chống Văng Game 20 Phút & Kiểm Tra Định Kỳ 19 Phút",
        Description = "Tự động phát tín hiệu kiểm tra định kỳ 19 phút, dọn rác bộ nhớ và chặn 100% mã lỗi 268/277 của Roblox",
        CurrentValue = hubState.antiAfk19m ~= false,
        Callback = function(Value: boolean)
            hubState.antiAfk19m = Value
            saveState(hubState)
            if Value then
                safeNotify("YokaHub", "Đã bật kiểm tra định kỳ 19 phút & Chống văng game!", "verified_user")
            else
                safeNotify("YokaHub", "Đã tắt kiểm tra định kỳ 19 phút.", "info")
            end
        end,
    }, "AntiAfk19mToggle")

    local MoveSection = UtilTab:CreateSection("🏃 Hỗ Trợ Di Chuyển & Đồng Minh")
    MoveSection:CreateToggle({
        Name = "🌊 Đi Bộ Trên Mặt Nước (Walk On Water)",
        Description = "Không bị tụt máu do dính nước biển khi dùng Trái Ác Quỷ",
        CurrentValue = hubState.walkOnWater,
        Callback = function(Value: boolean)
            hubState.walkOnWater = Value
            saveState(hubState)
            pcall(function() genv.Walkonwater = Value end)
        end,
    }, "WalkOnWaterToggle")

    MoveSection:CreateToggle({
        Name = "🦘 Nhảy Vô Hạn Trên Không (Infinite Jump)",
        Description = "Nhảy liên tục trên không trung không giới hạn độ cao",
        CurrentValue = hubState.infiniteJump,
        Callback = function(Value: boolean)
            hubState.infiniteJump = Value
            saveState(hubState)
            pcall(function() genv.InfiniteJumpEnabled = Value end)
        end,
    }, "InfiniteJumpToggle")

    MoveSection:CreateToggle({
        Name = "🏃 Tăng Tốc Độ Chạy (Speed Boost)",
        Description = "Tăng tốc độ chạy lên 65 (tự động trả về 16 chuẩn khi tắt)",
        CurrentValue = hubState.speedBoost == true,
        Callback = function(Value: boolean)
            hubState.speedBoost = Value
            saveState(hubState)
            pcall(function() genv.PlayerSpeedEnabled = Value end)
        end,
    }, "SpeedBoostToggle")

    MoveSection:CreateToggle({
        Name = "🖱️ Dịch Chuyển Bằng Chuột (Giữ Ctrl + Click)",
        Description = "Giữ phím Ctrl rồi bấm chuột trái để dịch chuyển ngay tới vị trí con trỏ (không bấm nhầm khi đánh)",
        CurrentValue = hubState.clickTeleport == true,
        Callback = function(Value: boolean)
            hubState.clickTeleport = Value
            saveState(hubState)
            pcall(function() genv.clickTeleportEnabled = Value end)
        end,
    }, "ClickTeleportToggle")

    MoveSection:CreateToggle({
        Name = "🤝 Tự Động Gửi & Nhận Đồng Minh (Auto Ally)",
        Description = "Tự động kết minh để không đánh nhầm người chơi khác khi săn Boss",
        CurrentValue = hubState.autoAlly,
        Callback = function(Value: boolean)
            hubState.autoAlly = Value
            saveState(hubState)
            pcall(function()
                genv.AutoSendAlly = Value
                genv.AutoAcceptAlly = Value
            end)
        end,
    }, "AutoAllyToggle")

    local WebhookSection = UtilTab:CreateSection("🔔 Thông Báo Discord Webhook")
    local webhookInput = hubState.webhookUrl or ""
    WebhookSection:CreateInput({
        Name = "Link Discord Webhook URL",
        PlaceholderText = "https://discord.com/api/webhooks/...",
        RemoveTextAfterFocusLost = false,
        Callback = function(text: string)
            local clean = string.gsub(text, "%s+", "")
            webhookInput = clean
            hubState.webhookUrl = clean
            saveState(hubState)
            pcall(function() genv.Webhook_URL2 = clean end)
            if #clean > 10 then safeNotify("Discord Webhook", "Đã lưu Webhook URL thành công!", "notifications") end
        end,
    }, "WebhookUrlInput")

    WebhookSection:CreateToggle({
        Name = "🍎 Gửi thông báo khi Nhặt Trái Ác Quỷ",
        Description = "Tự động gửi ảnh và tên trái rơi về kênh Discord cá nhân",
        CurrentValue = hubState.whFruit,
        Callback = function(Value: boolean)
            hubState.whFruit = Value
            saveState(hubState)
            pcall(function() genv.whshowfruit = Value end)
        end,
    }, "WhFruitToggle")

    WebhookSection:CreateToggle({
        Name = "🎁 Gửi thông báo khi Rơi Đồ Hiếm / Đánh Boss",
        Description = "Gửi thông báo khi nhặt rương Vua Biển, vảy Rồng hoặc đồ thần thoại",
        CurrentValue = hubState.whDrop,
        Callback = function(Value: boolean)
            hubState.whDrop = Value
            saveState(hubState)
            pcall(function() genv.whitemdrop = Value end)
        end,
    }, "WhDropToggle")

    local WinSection = UtilTab:CreateSection("🖥️ Cửa sổ YokaHub")
    WinSection:CreateButton({
        Name = "🔄 Đưa cửa sổ & nút nổi về mặc định",
        Description = "Đặt lại kích thước chuẩn 720×450 và góc nút nổi",
        Callback = function()
            isFullscreen = false
            hubState.dockX = nil
            hubState.dockY = nil
            dockBtn.Position = UDim2.new(1, -76, 0, 148)
            local lunaGui = getLunaGui()
            if lunaGui then
                local sw = lunaGui:FindFirstChild("SmartWindow")
                local sh = lunaGui:FindFirstChild("ShadowHolder")
                local centerPos = UDim2.fromScale(0.5, 0.5)
                if sw and sw:IsA("GuiObject") then sw.Position = centerPos end
                if sh and sh:IsA("GuiObject") then sh.Position = centerPos end
            end
            applyWindowSize(720, 450, true, true)
            safeNotify("YokaHub", "Đã đưa cửa sổ & nút avatar về mặc định.", "check_circle")
        end,
    })
    WinSection:CreateButton({
        Name = "❌ Tắt hoàn toàn YokaHub",
        Callback = function()
            hubState.mode = "off"
            saveState(hubState)
            genv._DisableWatchdog = true
            genv._YokaHubToken = -1
            genv._KingAutoHopMode = "off"
            genv._AutoSeaEventApiHop = false
            genv._AutoSea2PriorityApiHop = false
            genv._AutoDepthKingOnlyApiHop = false
            pcall(function()
                genv.AutoHop = false
                genv.HopDepthKing = false
                genv.HopDepthKingApi = false
                genv.autoskhdhop = false
                genv.hopSerpent = false
                genv.hopSerpentApi = false
            end)
            dmgEnabled = false
            clearDmgWatchers()
            for _, c in ipairs(activeConns) do pcall(function() c:Disconnect() end) end
            purgeLunaBlur()
            pcall(function() dockGui:Destroy() end)
            pcall(function() Luna:Destroy() end)
            genv._YokaHubLuna = nil
        end,
    })
    end

