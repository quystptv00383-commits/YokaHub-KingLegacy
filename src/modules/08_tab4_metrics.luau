    -- ========================================================
    -- TAB 4: DO FARM
    -- ========================================================
    local updateSessionUI: ((boolean?) -> ())?
    local dmgEnabled = hubState.damageMeter
    local clearDmgWatchers: (() -> ())?
    local refreshNearbyMobs: (() -> ())?
    do
        local MetricsTab = Window:CreateTab({
            Name = "Đo Farm",
            Icon = "speed",
            ImageSource = "Material",
            ShowTitle = false,
        })

        local SessionSection = MetricsTab:CreateSection("💎 Thống kê Gems & Beli kiếm được")
        local SessionParagraph = SessionSection:CreateParagraph({
            Title = "Đang tính...",
            Text = "Đang đọc Gems & Beli...",
        })

        updateSessionUI = function(force: boolean?)
        local cur = getPlayerStats()
        if session.startGems == 0 and session.startBeli == 0 and (cur.gems > 0 or cur.beli > 0) then
            session.startGems = cur.gems
            session.startBeli = cur.beli
            writeJson(sessionFile, session)
        end
        if not force and not isHubOpen() then return end
        local elapsed = math.max(1, os.time() - session.startTime)
        local dGems = cur.gems - session.startGems
        local dBeli = cur.beli - session.startBeli
        local hrs = math.max(elapsed / 3600, 1 / 60)
        pcall(function()
            SessionParagraph:Set({
                Title = string.format("Thời gian treo: %s  ·  Đã đổi %d phòng", fmtDuration(elapsed), session.hops),
                Text = string.format(
                    "Gems: %s  (%s | %s/giờ)\nBeli: %s  (%s | %s/giờ)",
                    fmtNum(cur.gems), fmtSigned(dGems), fmtSigned(math.floor(dGems / hrs)),
                    fmtNum(cur.beli), fmtSigned(dBeli), fmtSigned(math.floor(dBeli / hrs))
                ),
            })
        end)
    end
    updateSessionUI(true)
    table.insert(onHubOpenedHooks, function() updateSessionUI(true) end)

    local resetDropsFn: (() -> ())? = nil
    SessionSection:CreateButton({
        Name = "🔄 Bắt đầu đếm lại từ đầu",
        Description = "Đặt lại mốc Gems, Beli, thời gian và danh sách Drop về 0",
        Callback = function()
            local cur = getPlayerStats()
            session = { startTime = os.time(), startGems = cur.gems, startBeli = cur.beli, hops = 0 }
            writeJson(sessionFile, session)
            updateSessionUI(true)
            if resetDropsFn then resetDropsFn() end
            safeNotify("YokaHub", "Đã bắt đầu đếm phiên Farm mới.", "check_circle")
        end,
    })

    -- ========================================================
    -- THEO DOI VAT PHAM DA DROP (NGAY DUOI THONG KE GEMS & BELI)
    -- ========================================================
    local DropSection = MetricsTab:CreateSection("🎁 Vật phẩm đã Drop trong phiên")
    local DropParagraph = DropSection:CreateParagraph({
        Title = "Đã nhặt: 0 vật phẩm",
        Text = "Chưa có vật phẩm nào drop trong phiên này — đánh Boss hoặc mở rương để tự động ghi lại.",
    })

    type DropEntry = { name: string, cat: string, count: number, lastAt: number }
    type DropStore = {
        startTime: number,
        baseline: { [string]: number },
        drops: { [string]: DropEntry },
        lastDrop: string,
    }

    local function captureInventorySnapshot(): ({ [string]: number }, boolean, { [string]: boolean })
        local snap: { [string]: number } = {}
        local loadedCats: { [string]: boolean } = { mat = false, fruit = false, item = false, sword = false, acc = false }
        local lp = players.LocalPlayer
        if not lp then return snap, false, loadedCats end

        -- Cho DataLoaded = true de khong bao gio doc tui do rong luc moi vao phong
        local dl = lp:FindFirstChild("DataLoaded")
        if dl and dl:IsA("BoolValue") and not dl.Value then
            return snap, false, loadedCats
        end

        local ps = lp:FindFirstChild("PlayerStats")
        if ps then
            local function readJsonMap(valName: string, prefix: string, catKey: string)
                local o = ps:FindFirstChild(valName)
                if o and o:IsA("StringValue") and o.Value ~= "" then
                    local ok, dec = pcall(function() return httpService:JSONDecode(o.Value) end)
                    if ok and typeof(dec) == "table" then
                        local countKeys = 0
                        for k, v in pairs(dec) do
                            local n = tonumber(v)
                            if n and n > 0 then
                                snap[prefix .. tostring(k)] = n
                                countKeys += 1
                            end
                        end
                        if countKeys > 0 then loadedCats[catKey] = true end
                    end
                end
            end
            readJsonMap("Material", "mat:", "mat")
            readJsonMap("FruitStore", "fruit:", "fruit")
            readJsonMap("Collectible", "item:", "item")
        end

        local inv = lp:FindFirstChild("Inventory")
        if inv then
            local ch = inv:GetChildren()
            if #ch > 0 then loadedCats.sword = true end
            for _, c in ipairs(ch) do
                snap["sword:" .. c.Name] = 1
            end
        end

        local acc = lp:FindFirstChild("Accessories")
        if acc then
            local ch = acc:GetChildren()
            if #ch > 0 then loadedCats.acc = true end
            for _, c in ipairs(ch) do
                snap["acc:" .. c.Name] = 1
            end
        end

        -- Chi coi du lieu da san sang khi it nhat Material da tai xong (tranh quet lech luc moi hop)
        local ready = loadedCats.mat == true
        return snap, ready, loadedCats
    end

    -- Tai bang ten chuan tu ReplicatedStorage cua King Legacy (CustomNames, MaterialList, CollectibleList)
    local klCustomNames: { [string]: string } = {}
    local klMaterialList: { [string]: any } = {}
    local klCollectibleList: { [string]: any } = {}
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local chest = rs:FindFirstChild("Chest")
        local mods = chest and chest:FindFirstChild("Modules")
        if not mods then return end
        local function tryReq(modName: string): any
            local m = mods:FindFirstChild(modName)
            if m and m:IsA("ModuleScript") then
                local ok, t = pcall(require, m)
                if ok and typeof(t) == "table" then return t end
            end
            return nil
        end
        local cn = tryReq("CustomNames")
        if cn then klCustomNames = cn end
        local ml = tryReq("MaterialList")
        if ml then klMaterialList = ml end
        local cl = tryReq("CollectibleList")
        if cl then klCollectibleList = cl end
    end)

    local function resolveOfficialItem(cat: string, rawName: string): (string, string)
        local finalCat = cat
        local mapped = klCustomNames[rawName] or rawName

        if cat == "mat" then
            local info = klMaterialList[rawName]
            if rawName == "Fresh Fish" then
                finalCat = "fish"
            elseif typeof(info) == "table" then
                if info.FishSize ~= nil then finalCat = "fish" end
                if typeof(info.DisplayName) == "string" and info.DisplayName ~= "" then
                    mapped = info.DisplayName
                elseif typeof(info.Name) == "string" and info.Name ~= "" then
                    mapped = info.Name
                end
            end
        elseif cat == "fruit" then
            -- Vi du: OpFruit -> ControlFruit -> Control Fruit; DoughFruit -> Dough Fruit
            if string.sub(mapped, -5) == "Fruit" and string.sub(mapped, -6) ~= " Fruit" then
                mapped = string.sub(mapped, 1, #mapped - 5) .. " Fruit"
            end
            mapped = klCustomNames[mapped] or mapped
        elseif cat == "item" then
            local info = klCollectibleList[rawName]
            if typeof(info) == "table" and typeof(info.Name) == "string" and info.Name ~= "" then
                if string.sub(rawName, 1, 6) ~= "x2 EXP" then
                    mapped = info.Name
                end
            end
            mapped = klCustomNames[mapped] or mapped
        elseif cat == "sword" or cat == "acc" then
            mapped = klCustomNames[rawName] or rawName
        end

        return finalCat, mapped
    end

    local function parseDropKey(key: string): (string, string)
        local colon = string.find(key, ":", 1, true)
        if not colon then return resolveOfficialItem("mat", key) end
        local cat = string.sub(key, 1, colon - 1)
        local rawName = string.sub(key, colon + 1)
        return resolveOfficialItem(cat, rawName)
    end

    local function dropCatIcon(cat: string): string
        if cat == "sword" then return "⚔️"
        elseif cat == "acc" then return "🛡️"
        elseif cat == "fruit" then return "🍎"
        elseif cat == "fish" then return "🐟"
        elseif cat == "item" then return "🎟️"
        end
        return "📦"
    end

    local function loadDropStore(): DropStore
        local now = os.time()
        local d = readJson(dropsFile)
        if typeof(d) == "table" and typeof(d.startTime) == "number" and (now - d.startTime) < 86400 and typeof(d.baseline) == "table" and typeof(d.drops) == "table" then
            -- Chuan hoa lai ten in-game va loai bo toan bo Ca (khong thong ke ca)
            local purged = false
            for key, entry in pairs(d.drops) do
                if typeof(entry) == "table" then
                    local cat, dispName = parseDropKey(tostring(key))
                    if cat == "fish" then
                        d.drops[key] = nil
                        purged = true
                    else
                        entry.cat = cat
                        entry.name = dispName
                    end
                end
            end
            local loaded: DropStore = {
                startTime = d.startTime,
                baseline = d.baseline,
                drops = d.drops,
                lastDrop = typeof(d.lastDrop) == "string" and d.lastDrop or "",
            }
            if purged then writeJson(dropsFile, loaded) end
            return loaded
        end
        local snap, _ = captureInventorySnapshot()
        local fresh: DropStore = {
            startTime = session.startTime,
            baseline = snap,
            drops = {},
            lastDrop = "",
        }
        if next(snap) ~= nil then writeJson(dropsFile, fresh) end
        return fresh
    end

    local dropStore = loadDropStore()

    local DROP_GROUPS = {
        { cat = "sword", label = "⚔️ Vũ khí" },
        { cat = "acc", label = "🛡️ Phụ kiện" },
        { cat = "fruit", label = "🍎 Trái ác quỷ" },
        { cat = "mat", label = "📦 Nguyên liệu" },
        { cat = "item", label = "🎟️ Vật phẩm khác" },
    }

    local function updateDropUI(force: boolean?)
        if not force and not isHubOpen() then return end
        local byCat: { [string]: { DropEntry } } = {}
        local totalCount = 0
        local totalTypes = 0
        for _, entry in pairs(dropStore.drops) do
            if typeof(entry) == "table" and entry.cat ~= "fish" and (tonumber(entry.count) or 0) > 0 then
                totalCount += math.floor(entry.count)
                totalTypes += 1
                local c = tostring(entry.cat or "mat")
                if not byCat[c] then byCat[c] = {} end
                table.insert(byCat[c], entry)
            end
        end

        local titleStr = "Đã nhặt: 0 vật phẩm"
        local bodyStr = "Chưa có vật phẩm nào drop trong phiên này (không tính cá) — đánh Boss hoặc mở rương để tự động ghi lại."
        if totalTypes > 0 then
            titleStr = string.format("Đã nhặt: %s vật phẩm (%d loại)", fmtNum(totalCount), totalTypes)
            if dropStore.lastDrop ~= "" then
                titleStr ..= "  ·  Mới nhất: " .. dropStore.lastDrop
            end
            local lines: { string } = {}
            for _, grp in ipairs(DROP_GROUPS) do
                local arr = byCat[grp.cat]
                if arr and #arr > 0 then
                    table.sort(arr, function(a, b)
                        if a.lastAt ~= b.lastAt then return a.lastAt > b.lastAt end
                        return a.count > b.count
                    end)
                    local parts: { string } = {}
                    local cap = math.min(#arr, 8)
                    for i = 1, cap do
                        table.insert(parts, string.format("%s +%s", arr[i].name, fmtNum(arr[i].count)))
                    end
                    if #arr > cap then
                        table.insert(parts, string.format("… (+%d loại)", #arr - cap))
                    end
                    table.insert(lines, grp.label .. ": " .. table.concat(parts, " · "))
                end
            end
            bodyStr = table.concat(lines, "\n")
        end

        pcall(function()
            DropParagraph:Set({ Title = titleStr, Text = bodyStr })
        end)
    end

    local function syncDrops(notifyRare: boolean)
        local curSnap, hasData, loadedCats = captureInventorySnapshot()
        if not hasData then return end

        -- Neu chua co moc ban dau (do luc moi load PlayerStats chua kip dong bo), chot moc luon khong bao drop ao
        if next(dropStore.baseline) == nil then
            dropStore.baseline = curSnap
            writeJson(dropsFile, dropStore)
            updateDropUI(false)
            return
        end

        local now = os.time()
        local changed = false
        local rareNotifies: { string } = {}

        for key, curVal in pairs(curSnap) do
            local prevVal = tonumber(dropStore.baseline[key]) or 0
            if curVal > prevVal then
                local delta = curVal - prevVal
                local cat, dispName = parseDropKey(key)
                dropStore.baseline[key] = curVal
                changed = true
                -- Chong bao nham toan bo kho do (neu truoc do = 0 ma dot ngot >= 25 thi chi dong bo lai moc)
                local isBogusBulk = (prevVal == 0 and delta >= 25)
                -- Bo qua Ca (khong thong ke ca drop)
                if cat ~= "fish" and not isBogusBulk then
                    local existing = dropStore.drops[key]
                    if existing then
                        existing.count += delta
                        existing.lastAt = now
                        existing.cat = cat
                        existing.name = dispName
                    else
                        dropStore.drops[key] = { name = dispName, cat = cat, count = delta, lastAt = now }
                    end
                    dropStore.lastDrop = "+" .. fmtNum(delta) .. " " .. dispName
                    if notifyRare and (cat == "sword" or cat == "acc" or cat == "fruit") then
                        table.insert(rareNotifies, dropCatIcon(cat) .. " +" .. fmtNum(delta) .. " " .. dispName)
                    end
                end
            elseif curVal < prevVal then
                dropStore.baseline[key] = curVal
                changed = true
            end
        end

        -- Chi dua moc ve 0 neu nhom vat pham do THUC SU da tai day du (khong bao gio xoa moc khi dang load)
        for key, prevVal in pairs(dropStore.baseline) do
            if curSnap[key] == nil and (tonumber(prevVal) or 0) > 0 then
                local colon = string.find(key, ":", 1, true)
                local rawCat = colon and string.sub(key, 1, colon - 1) or "mat"
                if loadedCats[rawCat] == true then
                    dropStore.baseline[key] = 0
                    changed = true
                end
            end
        end

        if changed then
            writeJson(dropsFile, dropStore)
            updateDropUI(false)
            if #rareNotifies > 0 then
                safeNotify("🎁 Vừa Drop Hiếm!", table.concat(rareNotifies, ", "), "check_circle")
            end
        end
    end

    resetDropsFn = function()
        local snap, _ = captureInventorySnapshot()
        dropStore = {
            startTime = os.time(),
            baseline = snap,
            drops = {},
            lastDrop = "",
        }
        writeJson(dropsFile, dropStore)
        updateDropUI(true)
    end

    updateDropUI(true)
    table.insert(onHubOpenedHooks, function()
        syncDrops(false)
        updateDropUI(true)
    end)

    -- Gan su kien theo doi drop thoi gian thuc (debounce 0.3s, khong ton FPS)
    local dropSyncPending = false
    local function scheduleDropSync()
        if dropSyncPending then return end
        dropSyncPending = true
        task.delay(0.3, function()
            dropSyncPending = false
            if genv._YokaHubToken == myToken then
                syncDrops(true)
            end
        end)
    end

    task.spawn(function()
        local lp = players.LocalPlayer
        if not lp then return end
        local ps = lp:WaitForChild("PlayerStats", 15)
        if genv._YokaHubToken ~= myToken then return end
        syncDrops(false)
        if ps then
            for _, nm in ipairs({ "Material", "FruitStore", "Collectible" }) do
                local v = ps:FindFirstChild(nm)
                if v and v:IsA("StringValue") then
                    trackConn(v.Changed:Connect(scheduleDropSync))
                end
            end
        end
        for _, fn in ipairs({ "Inventory", "Accessories" }) do
            local f = lp:FindFirstChild(fn)
            if f then
                trackConn(f.ChildAdded:Connect(scheduleDropSync))
            end
        end
    end)

    DropSection:CreateButton({
        Name = "🧹 Xóa danh sách Drop",
        Description = "Đặt lại danh sách vật phẩm đã nhặt về 0 (giữ nguyên mốc Gems / Beli)",
        Callback = function()
            if resetDropsFn then resetDropsFn() end
            safeNotify("YokaHub", "Đã xóa danh sách vật phẩm Drop.", "check_circle")
        end,
    })

    local DmgSection = MetricsTab:CreateSection("⚔️ Đo sát thương thực tế (Test Trái / Kiếm)")
    local DmgParagraph = DmgSection:CreateParagraph({
        Title = "Đo sát thương · Đang tắt",
        Text = "Gạt công tắc bên dưới rồi đánh quái hoặc Boss để xem tổng dame 1 đòn & 1 combo.",
    })

    dmgEnabled = hubState.damageMeter
    local dmgLastTarget = "Chưa đánh mục tiêu"
    local dmgLastHit, dmgComboTotal, dmgComboHits, dmgComboClock, dmgMaxHit, dmgMaxCombo = 0, 0, 0, 0, 0, 0
    local dmgLastUiClock = 0
    local dmgWatched: { [Humanoid]: { conn: RBXScriptConnection, lastHp: number, name: string } } = {}

    clearDmgWatchers = function()
        for hum, rec in pairs(dmgWatched) do
            pcall(function() rec.conn:Disconnect() end)
            dmgWatched[hum] = nil
        end
    end

    local function updateDmgUI(force: boolean?)
        if not force then
            if not isHubOpen() then return end
            local now = os.clock()
            if (now - dmgLastUiClock) < 0.15 then return end
            dmgLastUiClock = now
        else
            dmgLastUiClock = os.clock()
        end
        pcall(function()
            DmgParagraph:Set({
                Title = dmgEnabled and ("Đang đo · " .. dmgLastTarget) or "Đo sát thương · Đang tắt",
                Text = string.format(
                    "Đòn vừa đánh: %s  |  Tổng 1 Combo: %s (%d hit)\nĐòn mạnh nhất: %s  |  Combo mạnh nhất: %s",
                    fmtNum(dmgLastHit), fmtNum(dmgComboTotal), dmgComboHits, fmtNum(dmgMaxHit), fmtNum(dmgMaxCombo)
                ),
            })
        end)
    end
    updateDmgUI(true)
    table.insert(onHubOpenedHooks, function() updateDmgUI(true) end)

    local function watchMob(model: Instance, hum: Humanoid)
        if dmgWatched[hum] then return end
        dmgWatched[hum] = {
            lastHp = hum.Health,
            name = model.Name,
            conn = hum.HealthChanged:Connect(function(newHp: number)
                if not dmgEnabled then return end
                local entry = dmgWatched[hum]
                if not entry then return end
                local delta = entry.lastHp - newHp
                entry.lastHp = newHp
                if delta >= 1 then
                    local now = os.clock()
                    if (now - dmgComboClock) > 3.5 then
                        dmgComboTotal = 0
                        dmgComboHits = 0
                    end
                    dmgComboClock = now
                    dmgLastTarget = entry.name
                    dmgLastHit = delta
                    dmgComboTotal += delta
                    dmgComboHits += 1
                    if delta > dmgMaxHit then dmgMaxHit = delta end
                    if dmgComboTotal > dmgMaxCombo then dmgMaxCombo = dmgComboTotal end
                    updateDmgUI(false)
                end
                if newHp <= 0 then
                    pcall(function() entry.conn:Disconnect() end)
                    dmgWatched[hum] = nil
                end
            end),
        }
    end

    refreshNearbyMobs = function()
        if not dmgEnabled then return end
        local lp = players.LocalPlayer
        local hrp = lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not (hrp and hrp:IsA("BasePart")) then return end
        local origin = hrp.Position

        for hum, rec in pairs(dmgWatched) do
            local root = hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")
            if hum.Parent == nil or hum.Health <= 0 or not (root and root:IsA("BasePart")) or (root.Position - origin).Magnitude > 300 then
                pcall(function() rec.conn:Disconnect() end)
                dmgWatched[hum] = nil
            end
        end

        local folders: { Instance } = {}
        local mon = workspace:FindFirstChild("Monster")
        if mon then
            table.insert(folders, mon)
            local b = mon:FindFirstChild("Boss")
            if b then table.insert(folders, b) end
            local m = mon:FindFirstChild("Mon")
            if m then table.insert(folders, m) end
        end
        for _, fn in ipairs({ "SeaMonster", "GhostMonster" }) do
            local f = workspace:FindFirstChild(fn)
            if f then table.insert(folders, f) end
        end
        for _, folder in ipairs(folders) do
            for _, mob in ipairs(folder:GetChildren()) do
                local hum = mob:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local root = mob:FindFirstChild("HumanoidRootPart")
                    if root and root:IsA("BasePart") and (root.Position - origin).Magnitude <= 260 then
                        watchMob(mob, hum)
                    end
                end
            end
        end
    end

    DmgSection:CreateToggle({
        Name = "⚔️ Bật đo sát thương khi đánh",
        Description = "Tự cộng dồn dame chiêu nhiều hit để dễ so sánh trái / kiếm",
        CurrentValue = dmgEnabled,
        Callback = function(Value: boolean)
            dmgEnabled = Value
            hubState.damageMeter = Value
            saveState(hubState)
            if not Value then clearDmgWatchers() else refreshNearbyMobs() end
            updateDmgUI(true)
        end,
    }, "EnableDamageMeter")

    DmgSection:CreateButton({
        Name = "🧹 Xóa số đo cũ",
        Callback = function()
            dmgLastHit, dmgComboTotal, dmgComboHits, dmgMaxHit, dmgMaxCombo = 0, 0, 0, 0, 0
            dmgLastTarget = "Đã xóa"
            updateDmgUI(true)
        end,
    })
    end

