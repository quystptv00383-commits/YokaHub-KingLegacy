    -- ========================================================
    -- VONG LAP NHE (SESSION + DAMAGE WATCHER)
    -- ========================================================
    task.spawn(function()
        local t = 0
        while genv._YokaHubToken == myToken do
            t += 1
            if t >= 1000000 then t = 0 end
            if t % 2 == 0 and updateSessionUI then updateSessionUI() end
            if dmgEnabled and refreshNearbyMobs then refreshNearbyMobs() end
            task.wait(1.5)
        end
        if clearDmgWatchers then clearDmgWatchers() end
    end)

    -- ========================================================
    -- VONG LAP AUTO HOP CHINH (SEA 3 & SEA 2)
    -- ========================================================
    local function smartWait(seconds: number, expectedMode: string)
        local w = 0
        while w < seconds and currentMode == expectedMode and genv._YokaHubToken == myToken do
            local step = math.min(0.25, seconds - w)
            task.wait(step)
            w += step
        end
    end

    -- Helper cham diem cho tung che do SAN RIENG API (F7)
    local function getSoloApiPrio(e: any, soloKey: string): number
        local pid = tonumber(e.placeId)
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))
        if soloKey == "dragon" then
            if pid == SEA3_PLACE and (string.find(nm, "drakenfyr") ~= nil or string.find(nm, "inferno king") ~= nil or (src == "sea_event" and string.find(nm, "dragon") ~= nil)) then
                return (string.find(nm, "drakenfyr") ~= nil or string.find(nm, "sea dragon") ~= nil) and 2 or 1
            end
        elseif soloKey == "abyssal_tyrant" then
            if pid == SEA3_PLACE and (string.find(nm, "abyssal tyrant") ~= nil or string.find(nm, "abyssal") ~= nil) then return 2 end
        elseif soloKey == "depth_king" then
            if pid == SEA3_PLACE and (src == "depth_king" or (string.find(nm, "depth") ~= nil and string.find(nm, "abyssal") == nil)) then return 2 end
        elseif soloKey == "kraken" then
            if pid == SEA3_PLACE and src == "sea_event" and (string.find(nm, "kraken") ~= nil or string.find(nm, "tentacle") ~= nil) then return 2 end
        elseif soloKey == "crab" then
            if pid == SEA3_PLACE and src == "sea_event" and string.find(nm, "crab") ~= nil then return 2 end
        elseif soloKey == "sea3_events" then
            if pid == SEA3_PLACE and src == "sea_event" then
                if string.find(nm, "sea dragon") ~= nil or string.find(nm, "drakenfyr") ~= nil then return 4 end
                if string.find(nm, "dragon") ~= nil then return 3 end
                if string.find(nm, "kraken") ~= nil then return 2 end
                return 1
            end
        elseif soloKey == "hydra" then
            if pid == SEA2_PLACE then
                if src == "sk_hd_chest" and string.find(nm, "hydra") ~= nil then return 2 end
                if src == "hydra" then return 1 end
            end
        elseif soloKey == "sea_king" then
            if pid == SEA2_PLACE then
                if src == "sk_hd_chest" and (string.find(nm, "sea king") ~= nil or string.find(nm, "seaking") ~= nil) then return 2 end
                if src == "sea_king" then return 1 end
            end
        elseif soloKey == "ghost_ship" then
            if pid == SEA2_PLACE then
                if (string.find(src, "ghost") ~= nil or string.find(nm, "ghost") ~= nil) and string.find(nm, "chest") ~= nil then return 2 end
                if src == "ghost_ship" or string.find(nm, "ghost ship") ~= nil then return 1 end
            end
        elseif soloKey == "serpent" then
            local reqPlace = (game.PlaceId == SEA2_PLACE) and SEA2_PLACE or SEA3_PLACE
            if pid == reqPlace and (src == "serpent" or string.find(nm, "serpent") ~= nil) then
                return 2
            end
        end
        return 0
    end

    local lastSoloIslandScan = 0
    local lastSoloChestResult: string? = nil
    local lastSoloChestKey = ""
    local function checkSoloServer(soloKey: string): (string, string)
        if soloKey ~= lastSoloChestKey then
            lastSoloChestKey = soloKey
            lastSoloIslandScan = 0
            lastSoloChestResult = nil
        end

        if soloKey == "depth_king" or soloKey == "abyssal_tyrant" or soloKey == "dragon" or soloKey == "kraken" or soloKey == "crab" or soloKey == "sea3_events" then
            if game.PlaceId ~= SEA3_PLACE then return "none", "wrong_sea" end
            if typeof(genv.WK_SeaEvent) == "table" and typeof(genv.WK_SeaEvent.GetState) == "function" then
                local ok, st = pcall(genv.WK_SeaEvent.GetState)
                if ok and typeof(st) == "table" and st.phase and st.phase ~= "inactive" then
                    local ek = string.lower(tostring(st.eventKey or ""))
                    local isAbyssal = string.find(ek, "abyssal") ~= nil or string.find(ek, "tyrant") ~= nil
                    local isDk = (string.find(ek, "depth") ~= nil and not isAbyssal)
                    if soloKey == "abyssal_tyrant" and isAbyssal then return "boss", tostring(st.eventKey or "Abyssal Tyrant")
                    elseif soloKey == "depth_king" and isDk then return "boss", tostring(st.eventKey or "Depth King")
                    elseif soloKey == "dragon" and (string.find(ek, "dragon") ~= nil or string.find(ek, "drakenfyr") ~= nil) then return "boss", tostring(st.eventKey or "Drakenfyr")
                    elseif soloKey == "kraken" and string.find(ek, "kraken") ~= nil then return "boss", tostring(st.eventKey)
                    elseif soloKey == "crab" and string.find(ek, "crab") ~= nil then return "boss", tostring(st.eventKey)
                    elseif soloKey == "sea3_events" and not isDk and not isAbyssal then return "boss", tostring(st.eventKey or st.phase)
                    end
                end
            end
            local sm = workspace:FindFirstChild("SeaMonster")
            if sm then
                for _, m in ipairs(sm:GetChildren()) do
                    local n = string.lower(m.Name)
                    local match = false
                    if soloKey == "abyssal_tyrant" then match = string.find(n, "abyssal") ~= nil or string.find(n, "tyrant") ~= nil
                    elseif soloKey == "depth_king" then match = (string.find(n, "depth") ~= nil and string.find(n, "abyssal") == nil)
                    elseif soloKey == "dragon" then match = string.find(n, "dragon") ~= nil or string.find(n, "drakenfyr") ~= nil
                    elseif soloKey == "kraken" then match = string.find(n, "kraken") ~= nil or string.find(n, "tentacle") ~= nil
                    elseif soloKey == "crab" then match = string.find(n, "crab") ~= nil
                    elseif soloKey == "sea3_events" then match = string.find(n, "dragon") ~= nil or string.find(n, "drakenfyr") ~= nil or string.find(n, "kraken") ~= nil or string.find(n, "tentacle") ~= nil or string.find(n, "crab") ~= nil or string.find(n, "sea beast") ~= nil or string.find(n, "seabeast") ~= nil
                    end
                    if match then
                        local hum = m:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then return "boss", m.Name end
                    end
                end
            end
            local mon = workspace:FindFirstChild("Monster")
            local bossF = mon and mon:FindFirstChild("Boss")
            if bossF then
                for _, m in ipairs(bossF:GetChildren()) do
                    local n = string.lower(m.Name)
                    local match = false
                    if soloKey == "abyssal_tyrant" then match = string.find(n, "abyssal") ~= nil or string.find(n, "tyrant") ~= nil
                    elseif soloKey == "depth_king" then match = (string.find(n, "depth king") ~= nil and string.find(n, "abyssal") == nil)
                    elseif soloKey == "dragon" then match = string.find(n, "drakenfyr") ~= nil or string.find(n, "sea dragon") ~= nil or string.find(n, "dragon") ~= nil
                    elseif soloKey == "kraken" then match = string.find(n, "kraken") ~= nil
                    elseif soloKey == "sea3_events" then match = string.find(n, "drakenfyr") ~= nil or string.find(n, "sea dragon") ~= nil or string.find(n, "kraken") ~= nil
                    end
                    if match then
                        local hum = m:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then return "boss", m.Name end
                    end
                end
            end
            if (soloKey == "depth_king" or soloKey == "abyssal_tyrant") and genv.DepthKingChestWaitStarted == true and genv.DepthKingChestReadyToHop == false then
                return "chest", "Rương Depth / Abyssal"
            end
            return "none", "empty"

        elseif soloKey == "hydra" or soloKey == "sea_king" or soloKey == "ghost_ship" then
            if game.PlaceId ~= SEA2_PLACE then return "none", "wrong_sea" end
            local folders = soloKey == "ghost_ship" and { "GhostMonster", "SeaMonster" } or { "SeaMonster" }
            for _, fn in ipairs(folders) do
                local folder = workspace:FindFirstChild(fn)
                if folder then
                    for _, m in ipairs(folder:GetChildren()) do
                        local n = string.lower(m.Name)
                        local match = (soloKey == "hydra" and string.find(n, "hydra") ~= nil)
                            or (soloKey == "sea_king" and (string.find(n, "seaking") ~= nil or string.find(n, "sea king") ~= nil))
                            or (soloKey == "ghost_ship" and string.find(n, "ghost") ~= nil)
                        if match then
                            local hum = m:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                lastSoloChestResult = nil
                                return "boss", m.Name
                            end
                        end
                    end
                end
            end
            if soloKey == "hydra" then
                if genv.HydraChestReadyToHop == true then lastSoloChestResult = nil; return "none", "claimed" end
                if genv.HydraChestWaitStarted == true then return "chest", "Rương Hydra" end
            elseif soloKey == "sea_king" then
                if genv.SeaKingChestReadyToHop == true then lastSoloChestResult = nil; return "none", "claimed" end
                if genv.SeaKingChestWaitStarted == true then return "chest", "Rương Sea King" end
            end
            local now = os.clock()
            if (now - lastSoloIslandScan) < 4 then
                if lastSoloChestResult then return "chest", lastSoloChestResult end
                return "none", "empty"
            end
            lastSoloIslandScan = now
            lastSoloChestResult = nil
            local isl = workspace:FindFirstChild("Island")
            if isl then
                for _, c in ipairs(isl:GetChildren()) do
                    local n = string.lower(c.Name)
                    local islMatch = (soloKey == "hydra" and string.find(n, "hydra") ~= nil)
                        or (soloKey == "sea_king" and (string.find(n, "sea island") ~= nil or string.find(n, "legacy island") ~= nil or string.find(n, "sea king") ~= nil))
                        or (soloKey == "ghost_ship" and string.find(n, "ghost") ~= nil)
                    if islMatch then
                        for _, d in ipairs(c:GetDescendants()) do
                            if d:IsA("Model") then
                                local dn = string.lower(d.Name)
                                if string.find(dn, "chest") and not string.find(dn, "spawner") then
                                    lastSoloChestResult = c.Name
                                    return "chest", c.Name .. " (" .. d.Name .. ")"
                                end
                            end
                        end
                    end
                end
            end
            return "none", "empty"

        elseif soloKey == "serpent" then
            local sm = workspace:FindFirstChild("SeaMonster")
            if sm then
                for _, m in ipairs(sm:GetChildren()) do
                    if string.find(string.lower(m.Name), "serpent") then
                        local hum = m:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then return "boss", m.Name end
                    end
                end
            end
            local mon = workspace:FindFirstChild("Monster")
            local bossF = mon and mon:FindFirstChild("Boss")
            if bossF then
                for _, m in ipairs(bossF:GetChildren()) do
                    if string.find(string.lower(m.Name), "serpent") then
                        local hum = m:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then return "boss", m.Name end
                    end
                end
            end
            return "none", "empty"
        end
        return "none", "empty"
    end

    local function checkSea3Server(): (boolean, string)
        if game.PlaceId ~= SEA3_PLACE then return false, "wrong_sea" end
        if typeof(genv.WK_SeaEvent) == "table" and typeof(genv.WK_SeaEvent.GetState) == "function" then
            local ok, st = pcall(genv.WK_SeaEvent.GetState)
            if ok and typeof(st) == "table" and st.phase and st.phase ~= "inactive" then
                return true, tostring(st.eventKey or st.phase)
            end
        end
        -- 1. Quet trong Workspace.SeaMonster (noi spawn Depth King / SeaDragon / Kraken / Crab / Serpent)
        local sm = workspace:FindFirstChild("SeaMonster")
        if sm then
            for _, m in ipairs(sm:GetChildren()) do
                local n = string.lower(m.Name)
                if string.find(n, "depth") or string.find(n, "abyssal tyrant") or string.find(n, "dragon") or string.find(n, "drakenfyr") or string.find(n, "crab") or string.find(n, "kraken") or string.find(n, "tentacle") or string.find(n, "sea beast") or string.find(n, "seabeast") or string.find(n, "serpent") then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then return true, m.Name end
                end
            end
        end
        -- 2. Quet trong Workspace.Monster.Boss CHI KHOP TEN CHINH XAC (tranh nham Inferno Diver / Abyssal Swordsman)
        local mon = workspace:FindFirstChild("Monster")
        local bossF = mon and mon:FindFirstChild("Boss")
        if bossF then
            for _, m in ipairs(bossF:GetChildren()) do
                local n = string.lower(m.Name)
                if string.find(n, "depth king") or string.find(n, "abyssal tyrant") or string.find(n, "drakenfyr") or string.find(n, "sea dragon") or string.find(n, "kraken") or string.find(n, "serpent") then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then return true, m.Name end
                end
            end
        end
        if genv.DepthKingChestWaitStarted == true and genv.DepthKingChestReadyToHop == false then
            return true, "Đang mở rương Depth King"
        end
        if genv.SeaKingChestWaitStarted == true and genv.SeaKingChestReadyToHop == false then
            return true, "Đang mở rương"
        end
        return false, "none"
    end

    local lastSea2IslandScan = 0
    local lastSea2ChestResult: string? = nil
    local function checkSea2Server(): (string, string)
        if game.PlaceId ~= SEA2_PLACE then return "none", "wrong_sea" end
        for _, fn in ipairs({ "SeaMonster", "GhostMonster" }) do
            local folder = workspace:FindFirstChild(fn)
            if folder then
                for _, m in ipairs(folder:GetChildren()) do
                    local n = string.lower(m.Name)
                    if string.find(n, "hydra") or string.find(n, "seaking") or string.find(n, "sea king") or string.find(n, "serpent") or string.find(n, "ghost") then
                        local hum = m:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            lastSea2ChestResult = nil
                            return "boss", m.Name
                        end
                    end
                end
            end
        end
        local mon2 = workspace:FindFirstChild("Monster")
        local bossF2 = mon2 and mon2:FindFirstChild("Boss")
        if bossF2 then
            for _, m in ipairs(bossF2:GetChildren()) do
                if string.find(string.lower(m.Name), "serpent") then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        lastSea2ChestResult = nil
                        return "boss", m.Name
                    end
                end
            end
        end
        if genv.HydraChestReadyToHop == true or genv.SeaKingChestReadyToHop == true then
            lastSea2ChestResult = nil
            return "none", "claimed"
        end
        if genv.HydraChestWaitStarted == true or genv.SeaKingChestWaitStarted == true then return "chest", "Rương Sea 2" end
        local now = os.clock()
        if (now - lastSea2IslandScan) < 4 then
            if lastSea2ChestResult then return "chest", lastSea2ChestResult end
            return "none", "empty"
        end
        lastSea2IslandScan = now
        lastSea2ChestResult = nil
        local isl = workspace:FindFirstChild("Island")
        if isl then
            for _, c in ipairs(isl:GetChildren()) do
                local n = string.lower(c.Name)
                if string.find(n, "hydra") or string.find(n, "sea island") or string.find(n, "legacy island") or string.find(n, "sea king") or string.find(n, "ghost") then
                    for _, d in ipairs(c:GetDescendants()) do
                        if d:IsA("Model") then
                            local dn = string.lower(d.Name)
                            if string.find(dn, "chest") and not string.find(dn, "spawner") then
                                lastSea2ChestResult = c.Name
                                return "chest", c.Name .. " (" .. d.Name .. ")"
                            end
                        end
                    end
                end
            end
        end
        return "none", "empty"
    end

    local wasInEvent, lastActiveClock, chestFirstSeenClock = false, 0, 0
    local lastSea3Target = ""
    local prevMode: string = currentMode
    local didInitialRoomSettle = false

    -- Helper doc thoi gian dao chim (sinkIn = "00:03:12") ra giay de tranh nhay vao ruong sap chim
    local function parseSinkSeconds(e: any): number?
        if typeof(e.details) ~= "table" or typeof(e.details.sinkIn) ~= "string" then return nil end
        local parts = string.split(e.details.sinkIn, ":")
        if #parts == 3 then
            return (tonumber(parts[1]) or 0) * 3600 + (tonumber(parts[2]) or 0) * 60 + (tonumber(parts[3]) or 0)
        elseif #parts == 2 then
            return (tonumber(parts[1]) or 0) * 60 + (tonumber(parts[2]) or 0)
        end
        return nil
    end

    -- Helper thu nhay nhanh lien tiep toi da 3 phong (gian cach 1.4s an toan chong loi 279)
    -- Neu la phong Hydra / Depth King ma bi day, chi khoa 20s (thay vi 150s) de quay lai ngay khi ho cho
    local function burstHopCandidates(candidates: { any }, visited: { [string]: number }, visitedFile: string, expectedMode: string, shortFailCooldownSec: number?, visitedPrefix: string?)
        local prefix = visitedPrefix or ""
        local tries = math.min(#candidates, 3)
        for idx = 1, tries do
            if currentMode ~= expectedMode or genv._YokaHubToken ~= myToken then break end
            local chosen = candidates[idx]
            local ref = tostring(chosen.serverRef or "")
            local vKey = prefix .. ref
            if ref ~= "" then visited[vKey] = os.time(); saveVisited(visitedFile, visited) end
            local hopStart = os.clock()
            local infoStr = string.format("%s (%s/%s người)", tostring(chosen.eventName), tostring(chosen.players and chosen.players.current or "?"), tostring(chosen.players and chosen.players.max or "?"))
            setStatus("Đang sang phòng: " .. infoStr)
            if idx == 1 then recordHop() end
            pcall(genv.WK_JoinLiveBossApiEntry, chosen)
            local waited = 0
            local failed = false
            while waited < 5.0 and currentMode == expectedMode and genv._YokaHubToken == myToken do
                task.wait(0.25); waited += 0.25
                if (tonumber(genv._LastTeleportFailClock) or 0) >= hopStart and waited >= 1.4 then
                    failed = true
                    if ref ~= "" and shortFailCooldownSec and shortFailCooldownSec > 0 then
                        visited[vKey] = os.time() - visitedTTL + shortFailCooldownSec
                        saveVisited(visitedFile, visited)
                    end
                    if idx < tries then
                        setStatus("Phòng vừa đầy/lỗi, chuyển phòng kế tiếp...")
                    end
                    break
                end
            end
            if not failed then break end
        end
    end

    local prevSoloKey = ""
    while genv._YokaHubToken == myToken do
        local mode: string = currentMode
        if mode ~= prevMode then
            wasInEvent, lastActiveClock, chestFirstSeenClock, lastSea3Target = false, 0, 0, ""
            prevMode = mode
        end
        if mode == "off" then
            task.wait(0.35)
            continue
        end
        if typeof(genv.WK_FetchLiveBossApiSnapshot) ~= "function" or typeof(genv.WK_JoinLiveBossApiEntry) ~= "function" then
            setStatus("Đang chờ Wukong HUD khởi động...")
            smartWait(1.2, mode)
            continue
        end
        if not didInitialRoomSettle then
            didInitialRoomSettle = true
            setStatus("Kiểm tra nhanh phòng hiện tại...")
            smartWait(1.8, mode)
            continue
        end

        if mode == "solo" then
            local soloOpt = currentSoloTarget
            local soloKey = getSoloKey(soloOpt)
            local targetPlace = getSoloPlaceId(soloKey)
            if game.PlaceId ~= targetPlace then
                ensureCorrectSea(targetPlace, soloOpt, "Lệch Sea", soloKey)
                smartWait(15.0, "solo")
                continue
            end
            if soloKey ~= prevSoloKey then
                wasInEvent, lastActiveClock, chestFirstSeenClock = false, 0, 0
                prevSoloKey = soloKey
            end

            -- Bat dung co danh cua Wukong cho tung Boss rieng & tat toan bo hopper xung dot
            pcall(function()
                genv.autoskhdhop = false
                genv.HopDepthKing = false
                genv.HopDepthKingApi = false
                genv.hopSerpent = false
                genv.hopSerpentApi = false
                genv.AutoHop = false
                genv.autoskillsea = true
                if soloKey == "depth_king" or soloKey == "abyssal_tyrant" then
                    genv.AutoDepthKing = true
                    genv.utienSeaEvent = true
                    genv.opeskill = true
                elseif soloKey == "dragon" or soloKey == "kraken" or soloKey == "crab" or soloKey == "sea3_events" then
                    genv.AutoDepthKing = false
                    genv.SeaEvent = true
                    genv.utienSeaEvent = true
                    genv.opeskill = true
                elseif soloKey == "hydra" then
                    genv.HydraSeaKing = true
                    genv.autoskhd = true
                    genv.seaking = false
                    genv.GhostShip = false
                elseif soloKey == "sea_king" then
                    genv.HydraSeaKing = true
                    genv.seaking = true
                    genv.autoskhd = true
                    genv.GhostShip = false
                elseif soloKey == "ghost_ship" then
                    genv.GhostShip = true
                    genv.HydraSeaKing = false
                    genv.seaking = false
                elseif soloKey == "serpent" then
                    genv.Serpent = true
                    genv.AutoSerpent = true
                    genv.serpent = true
                    genv.opeskill = true
                end
            end)

            local state, detail = checkSoloServer(soloKey)
            if state == "boss" then
                wasInEvent = true; lastActiveClock = os.clock(); chestFirstSeenClock = 0
                setStatus("Đang đánh: " .. detail)
                smartWait(1.5, "solo")
                continue
            elseif state == "chest" then
                if chestFirstSeenClock == 0 then chestFirstSeenClock = os.clock() end
                local maxChestHold = ((soloKey == "depth_king" or soloKey == "abyssal_tyrant") and 10) or (soloKey == "ghost_ship" and 12) or 14
                if (os.clock() - chestFirstSeenClock) < maxChestHold then
                    setStatus("Đang mở rương: " .. detail)
                    smartWait(0.9, "solo")
                    continue
                end
            end

            if wasInEvent then
                local waitLimit = ((soloKey == "depth_king" or soloKey == "abyssal_tyrant") and 9.5) or ((soloKey == "hydra" or soloKey == "sea_king") and 8.0) or 4.5
                local doneEarly = ((soloKey == "depth_king" or soloKey == "abyssal_tyrant") and genv.DepthKingChestWaitStarted == true and genv.DepthKingChestReadyToHop == true)
                    or (soloKey == "hydra" and genv.HydraChestReadyToHop == true)
                    or (soloKey == "sea_king" and genv.SeaKingChestReadyToHop == true)
                if not doneEarly and (os.clock() - lastActiveClock) < waitLimit then
                    setStatus("Đang chờ rương / phần thưởng...")
                    smartWait(0.75, "solo")
                    continue
                end
                wasInEvent = false
                if hubState.bringFruits then pcall(function() genv.BringDroppedFruit = true end) end
            end

            setStatus("Đang quét riêng API: " .. soloOpt .. "...")
            local ok, snap = pcall(genv.WK_FetchLiveBossApiSnapshot)
            if currentMode ~= "solo" or genv._YokaHubToken ~= myToken then continue end
            if ok and typeof(snap) == "table" and typeof(snap.entries) == "table" then
                local visited = loadVisited(visitedSoloFile)
                local vPrefix = soloKey .. ":"
                local candidates = {}
                local fullRooms, visitedRooms = 0, 0
                local minHp = (soloKey == "hydra" and 5) or ((soloKey == "depth_king" or soloKey == "abyssal_tyrant") and 10) or 15
                local minSink = (soloKey == "hydra" and 20) or 30
                local shortCd: number? = (soloKey == "depth_king" or soloKey == "abyssal_tyrant" or soloKey == "hydra") and 20 or nil

                for _, e in ipairs(snap.entries) do
                    local prio = getSoloApiPrio(e, soloKey)
                    if e.alive == true and prio > 0 then
                        local ref = tostring(e.serverRef or "")
                        local vKey = vPrefix .. ref
                        local pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 99) or 99
                        local pMax = typeof(e.players) == "table" and (tonumber(e.players.max) or 12) or 12
                        local hpOk = (typeof(e.health) ~= "table") or ((tonumber(e.health.percent) or 0) >= minHp)
                        local sinkSec = parseSinkSeconds(e)
                        local sinkOk = (sinkSec == nil) or (sinkSec >= minSink)
                        if pCur >= pMax then
                            fullRooms += 1
                        elseif ref ~= "" and visited[vKey] ~= nil then
                            visitedRooms += 1
                        elseif hpOk and sinkOk then
                            e._prio = prio
                            e._tier = getSlotTier(e)
                            e._sinkSec = sinkSec or 999
                            e._hp = typeof(e.health) == "table" and (tonumber(e.health.percent) or 100) or 100
                            table.insert(candidates, e)
                        end
                    end
                end
                table.sort(candidates, function(a, b)
                    if a._prio ~= b._prio then return a._prio > b._prio end
                    if a._tier ~= b._tier then return a._tier > b._tier end
                    if (soloKey == "hydra" or soloKey == "sea_king") and a._prio == 2 and a._sinkSec ~= b._sinkSec then
                        return a._sinkSec > b._sinkSec
                    end
                    return a._hp > b._hp
                end)

                if #candidates > 0 then
                    burstHopCandidates(candidates, visited, visitedSoloFile, "solo", shortCd, vPrefix)
                else
                    if fullRooms > 0 then
                        setStatus(string.format("Có %d phòng %s đều đầy 12/12 — dò lại sau 2s...", fullRooms, soloOpt))
                        smartWait(2.0, "solo")
                    elseif visitedRooms > 0 then
                        setStatus(string.format("Có %d phòng %s vừa ghé — chờ phòng mới sau 2s...", visitedRooms, soloOpt))
                        smartWait(2.0, "solo")
                    else
                        setStatus("Chưa có phòng trống cho " .. soloOpt .. " — dò lại sau 2.2s...")
                        smartWait(2.2, "solo")
                    end
                end
            else
                setStatus("Đang chờ API, thử lại sau 2.2s...")
                smartWait(2.2, "solo")
            end

        elseif mode == "sea3" then
            if game.PlaceId ~= SEA3_PLACE then
                ensureCorrectSea(SEA3_PLACE, "Boss Sea 3", "Lệch Sea", "depth")
                smartWait(15.0, "sea3")
                continue
            end
            pcall(function()
                genv.AutoDepthKing = true
                genv.SeaEvent = true
                genv.Serpent = true
                genv.utienSeaEvent = true
                genv.autoskillsea = true
                genv.opeskill = true
                genv.autoskhdhop = false
                genv.HopDepthKing = false
                genv.HopDepthKingApi = false
                genv.hopSerpent = false
                genv.hopSerpentApi = false
            end)
            local active, targetName = checkSea3Server()
            if active then
                wasInEvent = true; lastActiveClock = os.clock(); lastSea3Target = string.lower(targetName)
                -- Khử xung đột: Khi đang đánh Boss lớn, tạm dừng bay đi nhặt trái rơi để không bị bỏ sàn đấu
                pcall(function() genv.BringDroppedFruit = false end)
                setStatus("Đang đánh Boss: " .. targetName)
                smartWait(1.5, "sea3")
                continue
            elseif wasInEvent then
                local isDepthKing = (string.find(lastSea3Target, "depth") ~= nil or string.find(lastSea3Target, "abyssal") ~= nil or string.find(lastSea3Target, "tyrant") ~= nil)
                local waitLimit = isDepthKing and 9.0 or 4.5
                local dkDone = isDepthKing and (genv.DepthKingChestWaitStarted == true and genv.DepthKingChestReadyToHop == true)
                if not dkDone and (os.clock() - lastActiveClock) < waitLimit then
                    setStatus("Đang nhận rương / phần thưởng...")
                    smartWait(0.75, "sea3")
                    continue
                end
                wasInEvent = false
            end

            setStatus("Đang quét nhanh phòng Boss Sea 3...")
            local ok, snap = pcall(genv.WK_FetchLiveBossApiSnapshot)
            if currentMode ~= "sea3" or genv._YokaHubToken ~= myToken then continue end
            if ok and typeof(snap) == "table" and typeof(snap.entries) == "table" then
                local visited = loadVisited(visitedSea3File)
                local candidates = {}
                for _, e in ipairs(snap.entries) do
                    local prio = getSea3Prio(e)
                    local ref = tostring(e.serverRef or "")
                    local pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 99) or 99
                    local pMax = typeof(e.players) == "table" and (tonumber(e.players.max) or 12) or 12
                    local hpOk = (typeof(e.health) ~= "table") or ((tonumber(e.health.percent) or 0) >= 15)
                    if e.alive == true and tonumber(e.placeId) == SEA3_PLACE and prio > 0 and pCur < pMax and hpOk and (ref == "" or visited[ref] == nil) then
                        e._prio = prio
                        e._tier = getSlotTier(e)
                        e._hp = typeof(e.health) == "table" and (tonumber(e.health.percent) or 0) or 0
                        table.insert(candidates, e)
                    end
                end
                table.sort(candidates, function(a, b)
                    if a._prio ~= b._prio then return a._prio > b._prio end
                    if a._tier ~= b._tier then return a._tier > b._tier end
                    return a._hp > b._hp
                end)
                if #candidates > 0 then
                    burstHopCandidates(candidates, visited, visitedSea3File, "sea3")
                else
                    setStatus("Chưa có phòng phù hợp, quét lại sau 2.5s...")
                    smartWait(2.5, "sea3")
                end
            else
                setStatus("Đang chờ API, thử lại sau 2.5s...")
                smartWait(2.5, "sea3")
            end

        elseif mode == "sea2" then
            if game.PlaceId ~= SEA2_PLACE then
                ensureCorrectSea(SEA2_PLACE, "Boss Sea 2", "Lệch Sea", "hydra")
                smartWait(15.0, "sea2")
                continue
            end
            pcall(function()
                genv.HydraSeaKing = true
                genv.seaking = true
                genv.Serpent = true
                genv.GhostShip = true
                genv.autoskhd = true
                genv.autoskillsea = true
                genv.autoskhdhop = false
                genv.HopDepthKing = false
                genv.HopDepthKingApi = false
                genv.hopSerpent = false
                genv.hopSerpentApi = false
            end)
            local state, detail = checkSea2Server()
            if state == "boss" then
                wasInEvent = true; lastActiveClock = os.clock(); chestFirstSeenClock = 0
                setStatus("Đang đánh Boss: " .. detail)
                smartWait(1.5, "sea2")
                continue
            elseif state == "chest" then
                if chestFirstSeenClock == 0 then chestFirstSeenClock = os.clock() end
                if (os.clock() - chestFirstSeenClock) < 14 then
                    setStatus("Đang nhặt rương: " .. detail)
                    smartWait(1.0, "sea2")
                    continue
                else
                    state = "none"
                end
            end
            if wasInEvent and (os.clock() - lastActiveClock) < 8 and genv.HydraChestReadyToHop ~= true and genv.SeaKingChestReadyToHop ~= true then
                setStatus("Đang chờ rương xuất hiện...")
                smartWait(1.0, "sea2")
                continue
            end
            wasInEvent = false

            setStatus("Đang ưu tiên dò phòng Hydra & Rương Hydra...")
            local function scanSea2Pools(): ({ any }, { any }, { [string]: number }?, boolean)
                local ok, snap = pcall(genv.WK_FetchLiveBossApiSnapshot)
                if not ok or typeof(snap) ~= "table" or typeof(snap.entries) ~= "table" then
                    return {}, {}, nil, false
                end
                local visited = loadVisited(visitedSea2File)
                local hydraPool, otherPool = {}, {}
                for _, e in ipairs(snap.entries) do
                    local prio = getSea2Prio(e)
                    local ref = tostring(e.serverRef or "")
                    local pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 99) or 99
                    local pMax = typeof(e.players) == "table" and (tonumber(e.players.max) or 12) or 12
                    -- Hydra (prio >= 6) cho phep tu 5% HP tro len (kip danh 1 don + an ngay Ruong Hydra)
                    local minHp = (prio >= 6) and 5 or 15
                    local hpOk = (typeof(e.health) ~= "table") or ((tonumber(e.health.percent) or 0) >= minHp)
                    local sinkSec = parseSinkSeconds(e)
                    local sinkOk = (sinkSec == nil) or (sinkSec >= (prio >= 6 and 20 or 35))
                    if e.alive == true and tonumber(e.placeId) == SEA2_PLACE and prio > 0 and pCur < pMax and hpOk and sinkOk and (ref == "" or visited[ref] == nil) then
                        e._prio = prio
                        e._tier = getSlotTier(e)
                        e._sinkSec = sinkSec or 999
                        e._hp = typeof(e.health) == "table" and (tonumber(e.health.percent) or 100) or 100
                        if prio >= 6 then
                            table.insert(hydraPool, e)
                        else
                            table.insert(otherPool, e)
                        end
                    end
                end
                local function sortSea2(arr: { any })
                    table.sort(arr, function(a, b)
                        if a._prio ~= b._prio then return a._prio > b._prio end
                        if a._tier ~= b._tier then return a._tier > b._tier end
                        if (a._prio == 7 or a._prio == 5) and a._sinkSec ~= b._sinkSec then
                            return a._sinkSec > b._sinkSec
                        end
                        return a._hp > b._hp
                    end)
                end
                sortSea2(hydraPool)
                sortSea2(otherPool)
                return hydraPool, otherPool, visited, true
            end

            local hydraCands, otherCands, visited, apiOk = scanSea2Pools()
            if currentMode ~= "sea2" or genv._YokaHubToken ~= myToken then continue end
            if apiOk and visited then
                if #hydraCands > 0 then
                    -- Uu tien TUYET DOI Hydra / Ruong Hydra (chi khoa 20s neu phong day de san lai ngay)
                    burstHopCandidates(hydraCands, visited, visitedSea2File, "sea2", 20)
                else
                    -- Quet lai them 1 nhip nhanh 2.2s san Hydra truoc khi chap nhan qua Sea King Chest
                    setStatus("Chưa có Hydra trống, dò nhanh lại sau 2.2s trước khi qua Sea King...")
                    smartWait(2.2, "sea2")
                    if currentMode ~= "sea2" or genv._YokaHubToken ~= myToken then continue end
                    local hydraRetry, otherRetry, visitedRetry, okRetry = scanSea2Pools()
                    if okRetry and visitedRetry and #hydraRetry > 0 then
                        burstHopCandidates(hydraRetry, visitedRetry, visitedSea2File, "sea2", 20)
                    else
                        local fallback = (okRetry and #otherRetry > 0) and otherRetry or otherCands
                        local visUse = (okRetry and visitedRetry) or visited
                        if #fallback > 0 then
                            burstHopCandidates(fallback, visUse, visitedSea2File, "sea2")
                        else
                            setStatus("Chưa có phòng phù hợp, quét lại sau 2.5s...")
                            smartWait(2.5, "sea2")
                        end
                    end
                end
            else
                setStatus("Đang chờ API, thử lại sau 2.5s...")
                smartWait(2.5, "sea2")
            end
        end
    end
end)

    -- 🎣 LUỒNG CÂU CÁ TỰ ĐỘNG (AUTO FISHING WORKER)
    task.spawn(function()
        while true do
            task.wait(1.5)
            if hubState.autoFish and currentMode == "off" then
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end

                    -- Tự động cầm cần câu hoặc kiếm câu cá
                    local weaponName = hubState.fishWeapon or "True Muramasa"
                    local tool = char:FindFirstChild(weaponName) or player.Backpack:FindFirstChild(weaponName)
                    if not tool then
                        for _, t in ipairs(player.Backpack:GetChildren()) do
                            if t:IsA("Tool") and (string.find(string.lower(t.Name), "rod") or string.find(string.lower(t.Name), "fish")) then
                                tool = t
                                break
                            end
                        end
                    end
                    if tool and tool.Parent == player.Backpack then
                        char.Humanoid:EquipTool(tool)
                        task.wait(0.4)
                    end

                    -- Đứng trên mặt nước nếu bật Water Float
                    if hubState.fishFloat then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp.Position.Y < 15 and hrp.Position.Y > -25 then
                            hrp.Velocity = Vector3.new(0, 0, 0)
                            hrp.CFrame = CFrame.new(hrp.Position.X, 18, hrp.Position.Z)
                        end
                    end

                    -- Kích hoạt quăng mồi / giật cần (Activate tool)
                    local equipped = char:FindFirstChildOfClass("Tool")
                    if equipped then
                        equipped:Activate()
                    end
                end)
            end
        end
    end)
