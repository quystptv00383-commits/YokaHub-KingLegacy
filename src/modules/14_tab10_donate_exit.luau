    -- ========================================================
    -- TAB 4: UNG HO (DONATE)
    -- ========================================================
    do
        local DonateTab = Window:CreateTab({
            Name = "Ủng hộ",
            Icon = "volunteer_activism",
            ImageSource = "Material",
            ShowTitle = false,
        })

    local DonateSection = DonateTab:CreateSection("💖 Ủng hộ nhà phát triển YokaHub")

    DonateSection:CreateParagraph({
        Title = "Cảm ơn bạn đã đồng hành cùng YokaHub!",
        Text = "Mọi sự ủng hộ của bạn là nguồn động lực to lớn giúp Yoka duy trì hệ thống API săn Boss tốc độ cao, cập nhật tính năng mới liên tục và tối ưu trải nghiệm mượt mà nhất.",
    })

    local BankInfoParagraph = DonateSection:CreateParagraph({
        Title = "🏦 Thông tin chuyển khoản (MB Bank)",
        Text = table.concat({
            "• Ngân hàng: MB Bank (TMCP Quân Đội)",
            "• Số tài khoản: 36390914112009",
            "• Chủ tài khoản: SON TRAN PHU QUY",
            "• Lời nhắn: Ung ho YokaHub",
        }, "\n"),
    })

    local function copyToClipboard(text: string, successMsg: string)
        local sc = genv.setclipboard or setclipboard or genv.toclipboard or toclipboard
        if typeof(sc) == "function" then
            local ok = pcall(sc, text)
            if ok then
                safeNotify("Ủng hộ Yoka", successMsg, "check_circle")
                return true
            end
        end
        safeNotify("Ủng hộ Yoka", "Không thể ghi clipboard trên client này.", "info")
        return false
    end

    DonateSection:CreateButton({
        Name = "📋 Sao chép STK: 36390914112009",
        Description = "Nhấn để copy nhanh số tài khoản MB Bank",
        Callback = function()
            copyToClipboard("36390914112009", "Đã sao chép STK: 36390914112009")
        end,
    })

    DonateSection:CreateButton({
        Name = "📋 Sao chép toàn bộ thông tin CK",
        Description = "Copy Ngân hàng, STK, Tên chủ thẻ và lời nhắn",
        Callback = function()
            local fullInfo = "Ngân hàng: MB Bank (TMCP Quân Đội)\nSTK: 36390914112009\nChủ tài khoản: SON TRAN PHU QUY\nNội dung CK: Ung ho YokaHub"
            copyToClipboard(fullInfo, "Đã sao chép toàn bộ thông tin chuyển khoản!")
        end,
    })

    DonateSection:CreateButton({
        Name = "🔗 Sao chép link VietQR xem ảnh",
        Description = "Nhấn để copy link mã QR VietQR mở trên trình duyệt",
        Callback = function()
            local qrLink = "https://img.vietqr.io/image/MB-36390914112009-compact2.png?accountName=SON%20TRAN%20PHU%20QUY"
            copyToClipboard(qrLink, "Đã sao chép link ảnh VietQR vào bộ nhớ tạm!")
        end,
    })

    -- Khung ma QR VietQR (hien thi truc tiep trong tab)
    task.spawn(function()
        pcall(function()
            local qrAsset = ""
            local qrFileName = "YokaDonateQR.png"
            local qrUrl = "https://files.catbox.moe/rypryx.png"

            local gca = genv.getcustomasset or getcustomasset or genv.getsynasset or getsynasset
            local needDownload = false
            if typeof(isf) == "function" then
                if not isf(qrFileName) then
                    needDownload = true
                else
                    local okR, rawData = pcall(rf, qrFileName)
                    if not okR or typeof(rawData) ~= "string" or string.sub(rawData, 1, 4) ~= "\137PNG" then
                        needDownload = true
                    end
                end
            else
                needDownload = true
            end

            if needDownload and typeof(wf) == "function" then
                local okD, imgData = pcall(function() return game:HttpGet(qrUrl) end)
                if okD and typeof(imgData) == "string" and string.sub(imgData, 1, 4) == "\137PNG" then
                    wf(qrFileName, imgData)
                end
            end

            if typeof(gca) == "function" and typeof(isf) == "function" and isf(qrFileName) then
                qrAsset = gca(qrFileName)
            end

            local page = DonateTab.Page
            if page and page:IsA("ScrollingFrame") then
                local qrCard = Instance.new("Frame")
                qrCard.Name = "QRCard"
                qrCard.Size = UDim2.new(1, -6, 0, 275)
                qrCard.BackgroundColor3 = THEME.cardBg
                qrCard.BackgroundTransparency = 0.35
                qrCard.BorderSizePixel = 0
                setCorner(qrCard, 10)

                local qrStroke = Instance.new("UIStroke")
                qrStroke.Color = THEME.cardStroke
                qrStroke.Transparency = 0.5
                qrStroke.Thickness = 1
                qrStroke.Parent = qrCard

                local qrImg = Instance.new("ImageLabel")
                qrImg.Name = "QRImage"
                qrImg.Size = UDim2.fromOffset(195, 255)
                qrImg.Position = UDim2.fromScale(0.5, 0.5)
                qrImg.AnchorPoint = Vector2.new(0.5, 0.5)
                qrImg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                qrImg.BackgroundTransparency = 1
                qrImg.BorderSizePixel = 0
                qrImg.ScaleType = Enum.ScaleType.Fit
                setCorner(qrImg, 8)
                if qrAsset and qrAsset ~= "" then
                    qrImg.Image = qrAsset
                end
                qrImg.Parent = qrCard

                qrCard.Parent = page
            end
        end)
    end)

    -- 2. BANG VANG VINH DANH (DANH SACH NGUOI DA DONATE)
    local DonatorsSection = DonateTab:CreateSection("🏆 Bảng vàng người vừa donate vào tài khoản")

    local donatorsFile = "YokaHub_Donators.json"
    local donatorsOnlineUrl = "https://gist.githubusercontent.com/quystptv00383-commits/7dde495f53b84afb7cf64c06c15dfe2d/raw/YokaHub_Donators.json"
    local sepayTokenFile = "YokaHub_SePayToken.txt"

    local currentDonators: { { name: string, amount: string, note: string, date: string, source: string?, ref: string? } } = {}

    local function loadDonators(): { any }
        local list = {}
        local okH, rawH = pcall(function() return game:HttpGet(donatorsOnlineUrl .. "?t=" .. os.time()) end)
        if okH and typeof(rawH) == "string" and #rawH > 5 then
            local okD, parsed = pcall(function() return httpService:JSONDecode(rawH) end)
            if okD and typeof(parsed) == "table" and #parsed > 0 then
                list = parsed
                if typeof(wf) == "function" then
                    pcall(wf, donatorsFile, rawH)
                end
                return list
            end
        end

        if typeof(isf) == "function" and isf(donatorsFile) and typeof(rf) == "function" then
            local ok, raw = pcall(rf, donatorsFile)
            if ok and typeof(raw) == "string" and #raw > 5 then
                local okD, parsed = pcall(function() return httpService:JSONDecode(raw) end)
                if okD and typeof(parsed) == "table" then
                    list = parsed
                end
            end
        end
        return list
    end

    local function saveDonators(list: { any }): boolean
        if typeof(wf) == "function" then
            local okE, raw = pcall(function() return httpService:JSONEncode(list) end)
            if okE and typeof(raw) == "string" then
                return pcall(wf, donatorsFile, raw)
            end
        end
        return false
    end

    local function formatDonatorsText(list: { any }): string
        if not list or #list == 0 then
            return "Chưa có thông tin người ủng hộ nào trong danh sách.\nQuét mã QR MB Bank bên trên để xuất hiện trên Bảng vàng vinh danh!"
        end
        local lines = {}
        local latest = list[#list]
        if latest then
            local lName = tostring(latest.name or "Ẩn danh")
            local lAmt = tostring(latest.amount or "")
            local lDate = tostring(latest.date or "")
            local lNote = tostring(latest.note or "")
            table.insert(lines, "🔥 [VỪA DONATE GẦN NHẤT]: " .. lName .. (lAmt ~= "" and (" — " .. lAmt) or ""))
            if lDate ~= "" then
                table.insert(lines, "   ⏰ Thời gian: " .. lDate)
            end
            if lNote ~= "" and lNote ~= "Ủng hộ YokaHub" then
                table.insert(lines, "   💬 Lời nhắn: " .. lNote)
            end
            table.insert(lines, "────────────────────────────")
        end

        table.insert(lines, "🏆 BẢNG VÀNG VINH DANH (" .. #list .. " người ủng hộ):")
        for idx, d in ipairs(list) do
            local badge = (idx == 1 and "👑 [TOP 1] ") or (idx == 2 and "🥈 [TOP 2] ") or (idx == 3 and "🥉 [TOP 3] ") or ("⭐ #" .. idx .. " ")
            local tag = ""
            if d.source == "bank" then tag = " [🏦 MB Bank]" end
            local name = tostring(d.name or "Ẩn danh")
            local amount = tostring(d.amount or "Tùy tâm")
            local note = tostring(d.note or "")
            local date = tostring(d.date or "")
            local entryStr = badge .. name .. tag .. " — " .. amount
            if date ~= "" then
                entryStr = entryStr .. " (" .. date .. ")"
            end
            table.insert(lines, entryStr)
            if note ~= "" and note ~= "Ủng hộ YokaHub" then
                table.insert(lines, "   💬 Lời nhắn: " .. note)
            end
            if idx < #list then
                table.insert(lines, "")
            end
        end
        return table.concat(lines, "\n")
    end

    currentDonators = loadDonators()

    local DonatorsParagraph = DonatorsSection:CreateParagraph({
        Title = "🌟 Danh sách người vừa donate vào tài khoản",
        Text = formatDonatorsText(currentDonators),
    })

    local function refreshDonatorsUI()
        currentDonators = loadDonators()
        DonatorsParagraph:Set({
            Title = "🌟 Danh sách người vừa donate (" .. #currentDonators .. " người)",
            Text = formatDonatorsText(currentDonators),
        })
    end

    DonatorsSection:CreateButton({
        Name = "🔄 Tải lại danh sách người donate",
        Description = "Cập nhật danh sách mới nhất từ máy chủ",
        Callback = function()
            refreshDonatorsUI()
            safeNotify("Bảng Vinh Danh", "Đã cập nhật danh sách người ủng hộ!", "check_circle")
        end,
    })

    -- TIEN TRINH TU DONG DONG BO NGAM 100% (SEPAY BANK + GIST ONLINE)
    local function getReqFn()
        local g: any = genv
        return g.request or request or g.http_request or http_request
    end

    local function checkSePayBankAuto(token: string)
        if not token or #token < 5 then return end
        local reqFn = getReqFn()
        if typeof(reqFn) ~= "function" then return end

        task.spawn(function()
            local ok, resp = pcall(reqFn, {
                Url = "https://my.sepay.vn/userapi/transactions/list?limit=20",
                Method = "GET",
                Headers = {
                    ["Authorization"] = "Apikey " .. token,
                    ["Content-Type"] = "application/json",
                },
            })
            if not ok or typeof(resp) ~= "table" or not resp.Body then return end
            local okD, data = pcall(function() return httpService:JSONDecode(resp.Body) end)
            if not okD or typeof(data) ~= "table" or typeof(data.transactions) ~= "table" then return end

            local newCount = 0
            for _, tx in ipairs(data.transactions) do
                local amtIn = tonumber(tx.amount_in) or 0
                if amtIn > 0 then
                    local txRef = tostring(tx.reference_number or tx.id or "")
                    local alreadyExists = false
                    for _, ex in ipairs(currentDonators) do
                        if ex.ref == txRef and txRef ~= "" then
                            alreadyExists = true
                            break
                        end
                    end
                    if not alreadyExists then
                        local content = tostring(tx.transaction_content or "")
                        local donorName = "Nhà tài trợ MB"
                        if #content > 0 then
                            donorName = content
                        end
                        local amtStr = string.format("%sđ", tostring(amtIn))
                        local txDate = string.sub(tostring(tx.transaction_date or os.date("%d/%m/%Y")), 1, 10)
                        table.insert(currentDonators, {
                            name = donorName,
                            amount = amtStr,
                            note = content,
                            date = txDate,
                            source = "bank",
                            ref = txRef,
                        })
                        newCount += 1
                    end
                end
            end

            if newCount > 0 then
                saveDonators(currentDonators)
                refreshDonatorsUI()
                local lastDonor = currentDonators[#currentDonators]
                safeNotify("SePay MB Bank", "🎉 Người vừa donate mới: " .. tostring(lastDonor.name) .. " (" .. tostring(lastDonor.amount) .. ")!", "favorite")
            end
        end)
    end

    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(30)
            -- Kiem tra SePay MB Bank neu co file token
            if typeof(isf) == "function" and isf(sepayTokenFile) and typeof(rf) == "function" then
                local okR, tVal = pcall(rf, sepayTokenFile)
                if okR and typeof(tVal) == "string" and #tVal > 5 then
                    local cleanTok = string.gsub(tVal, "%s+", "")
                    checkSePayBankAuto(cleanTok)
                end
            end
            -- Tu dong dong bo danh sach online tu GitHub Gist
            pcall(function()
                local okH, rawH = pcall(function() return game:HttpGet(donatorsOnlineUrl .. "?t=" .. os.time()) end)
                if okH and typeof(rawH) == "string" and #rawH > 5 then
                    local okD, parsed = pcall(function() return httpService:JSONDecode(rawH) end)
                    if okD and typeof(parsed) == "table" and #parsed > 0 then
                        if #parsed ~= #currentDonators then
                            currentDonators = parsed
                            if typeof(wf) == "function" then pcall(wf, donatorsFile, rawH) end
                            DonatorsParagraph:Set({
                                Title = "🌟 Danh sách người vừa donate (" .. #currentDonators .. " người)",
                                Text = formatDonatorsText(currentDonators),
                            })
                            local latest = currentDonators[#currentDonators]
                            if latest then
                                safeNotify("Ủng hộ YokaHub", "🎉 " .. tostring(latest.name) .. " vừa ủng hộ " .. tostring(latest.amount) .. "!", "favorite")
                            end
                        end
                    end
                end
            end)
        end
    end)
    end

    -- Ap dung giao dien + mo rong Sidebar + nut Full + goc keo tu do (van giu an cho den khi nguoi dung bam mo)
    task.spawn(function()
        hideHubImmediate()
        task.wait(0.45)
        applyVisualTheme()
        attachCornerResizer()
        applyWindowSize(hubState.winW, hubState.winH, false, false)
        local winCam = workspace.CurrentCamera
        if winCam then
            trackConn(winCam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                local lunaGui = getLunaGui()
                if not lunaGui then return end
                local smartWin = lunaGui:FindFirstChild("SmartWindow")
                if not (smartWin and smartWin:IsA("GuiObject")) then return end
                local v = winCam.ViewportSize
                if smartWin.Size.X.Offset > (v.X - 16) or smartWin.Size.Y.Offset > (v.Y - 16) then
                    applyWindowSize(math.min(smartWin.Size.X.Offset, v.X - 16), math.min(smartWin.Size.Y.Offset, v.Y - 16), true, false)
                end
            end))
        end
        if not userOpenedHub then hideHubImmediate() end
        task.wait(0.6)
        applyVisualTheme()
        if not userOpenedHub then hideHubImmediate() end
    end)

    do
        local ExitTab = Window:CreateTab({
            Name = "🚪 Thoát Key",
            Icon = "logout",
            ImageSource = "Material",
            ShowTitle = false,
        })
        local ExitSec = ExitTab:CreateSection("🚪 Đăng Xuất & Quay Lại Cổng Key")
        ExitSec:CreateButton({
            Name = "🚪 BẤM ĐÂY ĐỂ THOÁT RA GIAO DIỆN CHƯA GET KEY",
            Description = "Xóa thông tin Key và quay lại màn hình Gateway (Nhập Key / Get Key Free / Mua VIP)",
            Callback = function()
                doExitToGateway()
            end,
        })
    end

    HopTab:Activate()

