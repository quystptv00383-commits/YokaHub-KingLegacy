
    -- ========================================================
    -- [KIỂM TRA ĐỊNH KỲ 19 PHÚT & CHỐNG KICK AFK 20 PHÚT]
    -- ========================================================
    pcall(function()
        local vu = game:GetService("VirtualUser")
        player.Idled:Connect(function()
            if hubState.antiAfk19m ~= false then
                pcall(function()
                    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
                    task.wait(1)
                    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
                end)
            end
        end)
    end)

    task.spawn(function()
        local elapsed = 0
        local checkInterval = 19 * 60
        while genv._YokaHubToken == myToken do
            task.wait(10)
            elapsed += 10
            if elapsed >= checkInterval then
                elapsed = 0
                if hubState.antiAfk19m ~= false then
                    pcall(function()
                        local vu = game:GetService("VirtualUser")
                        if vu then
                            vu:CaptureController()
                            vu:ClickButton2(Vector2.new(0, 0))
                        end
                        safeNotify("YokaHub Định Kỳ", "Đã hoàn thành kiểm tra 19 phút: Kết nối ổn định, đã đặt lại bộ đếm Idle an toàn!", "health_and_safety")
                    end)
                end
            end
        end
    end)


    -- ========================================================
    -- [AUTO FIGHT BOSS WORKER] - LUỒNG CHIẾN ĐẤU VÀ NHẶT RƯƠNG BOSS
    -- ========================================================
    task.spawn(function()
        while true do
            task.wait(1.2)
            if (hubState.autoFightMaster or hubState.autoFightIslandBoss) and genv._YokaHubToken == myToken then
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                    local hrp = char.HumanoidRootPart
                    local hum = char.Humanoid
                    if hum.Health <= 0 then return end
                    local dMode = hubState.dungeonMode or genv.dungeonmode or "Easy"

                    -- 1. Quét tìm rương báu Boss trước nếu có
                    if hubState.autoCollectChest then
                        local isl = workspace:FindFirstChild("Island")
                        if isl then
                            for _, c in ipairs(isl:GetChildren()) do
                                for _, d in ipairs(c:GetDescendants()) do
                                    if d:IsA("Model") and string.find(string.lower(d.Name), "chest") and not string.find(string.lower(d.Name), "spawner") then
                                        local pp = d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")
                                        if pp and (pp.Position - hrp.Position).Magnitude < 1500 then
                                            hrp.Velocity = Vector3.new(0, 0, 0)
                                            hrp.CFrame = CFrame.new(pp.Position + Vector3.new(0, 3, 0))
                                            task.wait(0.5)
                                            return
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- 2. Quét Boss biển theo các bảng riêng biệt đã chọn
                    local function isBossWanted(rawName: string): boolean
                        local n = string.lower(rawName)
                        if string.find(n, "depth") and string.find(n, "abyssal") == nil then return hubState.fightSea3DepthKing ~= false end
                        if string.find(n, "drakenfyr") or string.find(n, "inferno king") or (string.find(n, "dragon") and not string.find(n, "fruit")) then return hubState.fightSea3Dragon ~= false end
                        if string.find(n, "abyssal") or string.find(n, "tyrant") then return hubState.fightSea3Abyssal ~= false end
                        if string.find(n, "kraken") or string.find(n, "tentacle") then return hubState.fightSea3Kraken ~= false end
                        if string.find(n, "crab") then return hubState.fightSea3Crab ~= false end
                        if string.find(n, "hydra") then return hubState.fightSea2Hydra ~= false end
                        if string.find(n, "sea king") or string.find(n, "seaking") then return hubState.fightSea2SeaKing ~= false end
                        if string.find(n, "ghost") then return hubState.fightSea2GhostShip ~= false end
                        if string.find(n, "serpent") then return hubState.fightSea2Serpent ~= false end
                        return hubState.fightSea3Events ~= false
                    end

                    -- Quét trong SeaMonster & Monster
                    local targetBoss: Model? = nil
                    local folders = { workspace:FindFirstChild("SeaMonster"), workspace:FindFirstChild("Monster"), workspace:FindFirstChild("GhostMonster") }
                    for _, fld in ipairs(folders) do
                        if fld then
                            for _, m in ipairs(fld:GetChildren()) do
                                if m:IsA("Model") and isBossWanted(m.Name) then
                                    local bHum = m:FindFirstChildOfClass("Humanoid")
                                    if bHum and bHum.Health > 0 then
                                        targetBoss = m
                                        break
                                    end
                                end
                            end
                            if targetBoss then break end
                        end
                    end

                    -- Nếu tìm thấy Boss hợp lệ: Bay đến trên đầu và xả chiêu
                    if targetBoss then
                        local bRoot = targetBoss:FindFirstChild("HumanoidRootPart") or targetBoss:FindFirstChild("Torso") or targetBoss.PrimaryPart or targetBoss:FindFirstChildWhichIsA("BasePart")
                        if bRoot then
                            local sHeight = hubState.bossSafeHeight or 18
                            hrp.Velocity = Vector3.new(0, 0, 0)
                            hrp.CFrame = CFrame.new(bRoot.Position + Vector3.new(0, sHeight, 0), bRoot.Position)

                            -- Bật Haki
                            if hubState.autoHaki then
                                pcall(function() genv.haki = true; genv.hakivutrangv2 = true end)
                            end

                            -- Tự trang bị vũ khí nếu chưa cầm
                            local curTool = char:FindFirstChildOfClass("Tool")
                            if not curTool then
                                local bpTool = player.Backpack:FindFirstChildOfClass("Tool")
                                if bpTool then char.Humanoid:EquipTool(bpTool) end
                            else
                                curTool:Activate()
                            end

                            -- Kích hoạt xả chiêu
                            pcall(function()
                                genv.opeskill = true
                                genv.autoskillsea = true
                            end)
                        end
                    end
                end)
            end
        end
    end)

    -- ========================================================
    -- [AUTO CLICK PLAY] - TU DONG NHAN PLAY KHI LOAD XONG
    -- ========================================================
    task.spawn(function()
        local maxWait = 30
        local startClock = os.clock()
        while (os.clock() - startClock) < maxWait and genv._YokaHubToken == myToken do
            task.wait(0.5)
            if hubState.autoClickPlay == false then break end

            local char = player.Character
            local hasHrp = char and char:FindFirstChild("HumanoidRootPart")
            local hasHum = char and char:FindFirstChild("Humanoid")
            if hasHrp and hasHum and hasHum.Health > 0 then
                break
            end

            pcall(function()
                local pgui = player:FindFirstChild("PlayerGui")
                if not pgui then return end

                local clicked = false
                for _, btn in ipairs(pgui:GetDescendants()) do
                    if btn:IsA("GuiButton") and btn.Visible and btn.Active ~= false then
                        local bName = string.lower(btn.Name)
                        local bText = ""
                        if btn:IsA("TextButton") then
                            bText = string.lower(btn.Text)
                        else
                            local lbl = btn:FindFirstChildOfClass("TextLabel")
                            if lbl then bText = string.lower(lbl.Text) end
                        end

                        local isPlayBtn = (bName == "play" or bName == "playbutton" or bName == "start" or bName == "btnplay" or bName == "play_btn" or string.find(bName, "play") ~= nil)
                        local isPlayText = (bText == "play" or bText == "start" or bText == "chơi" or string.find(bText, "play") ~= nil)

                        if isPlayBtn or isPlayText then
                            if typeof(firesignal) == "function" then
                                pcall(function() firesignal(btn.MouseButton1Click) end)
                                pcall(function() firesignal(btn.Activated) end)
                                pcall(function() firesignal(btn.MouseButton1Down) end)
                                pcall(function() firesignal(btn.MouseButton1Up) end)
                            end

                            local vim = game:GetService("VirtualInputManager")
                            if vim and btn.AbsoluteSize.X > 0 and btn.AbsoluteSize.Y > 0 then
                                local cx = btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2
                                local cy = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2
                                pcall(function()
                                    vim:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                                    task.wait(0.03)
                                    vim:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                                end)
                            end

                            clicked = true
                            break
                        end
                    end
                end

                if clicked then
                    task.wait(1.5)
                end
            end)
        end
    end)

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
    local prevMode: string = hubState.mode or currentMode
    local didInitialRoomSettle = false

    -- Fast Mode rendering optimization
    if hubState.fastMode or genv.fastMode then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    end

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
        local mode: string = hubState.mode or currentMode
        if hubState.autoTakeBossQuest and (hubState.islandBossTarget or genv.bossTarget) then
            pcall(function()
                local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                if rem and rem:FindFirstChild("Functions") and rem.Functions:FindFirstChild("Quest") then
                    rem.Functions.Quest:InvokeServer("Take", hubState.islandBossTarget or genv.bossTarget)
                end
            end)
        end
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

                    -- Kích hoạt quăng mồi / giật cần (Activate tool + Fishing Remote)
                    local equipped = char:FindFirstChildOfClass("Tool")
                    if equipped then
                        equipped:Activate()
                    end
                    local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    if rem and rem:FindFirstChild("Functions") and rem.Functions:FindFirstChild("Fishing") then
                        pcall(function()
                            rem.Functions.Fishing:InvokeServer("Cast")
                            task.wait(0.5)
                            rem.Functions.Fishing:InvokeServer("Reel")
                        end)
                    end
                end)
            end
        end
    end)


    -- ========================================================
    -- [NATIVE AUTO FARM LEVEL & SELECT MOB WORKER]
    -- ========================================================
    task.spawn(function()
        local vim = game:GetService("VirtualInputManager")
        while genv._YokaHubToken == myToken do
            task.wait(0.3)
            if (hubState.autoLevel or genv.Autokillmob or genv.Famlevel) and currentMode == "off" then
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                    local hrp = char.HumanoidRootPart
                    local hum = char.Humanoid
                    if hum.Health <= 0 then return end
                    local dMode = hubState.dungeonMode or genv.dungeonmode or "Easy"

                    -- 1. Tìm quái mục tiêu
                    local targetMob: Model? = nil
                    local mobFolders = { workspace:FindFirstChild("Monster"), workspace:FindFirstChild("Enemy"), workspace:FindFirstChild("Monsters") }
                    local selectedMobName = genv.chonmod or ""

                    for _, fld in ipairs(mobFolders) do
                        if fld then
                            for _, m in ipairs(fld:GetChildren()) do
                                if m:IsA("Model") then
                                    local mHum = m:FindFirstChildOfClass("Humanoid")
                                    local mRoot = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                                    if mHum and mHum.Health > 0 and mRoot then
                                        if genv.Autokillmob and selectedMobName ~= "" then
                                            local rawSel = string.match(selectedMobName, "^([%w%s%']+)") or selectedMobName
                                            rawSel = string.gsub(rawSel, "%s+$", "")
                                            if string.find(string.lower(m.Name), string.lower(rawSel)) then
                                                targetMob = m
                                                break
                                            end
                                        else
                                            -- Auto level: chọn quái gần nhất
                                            local targetDist = targetMob and ((targetMob.PrimaryPart or targetMob:FindFirstChildWhichIsA("BasePart")).Position - hrp.Position).Magnitude or 99999
                                            if not targetMob or (mRoot.Position - hrp.Position).Magnitude < targetDist then
                                                targetMob = m
                                            end
                                        end
                                    end
                                end
                            end
                            if targetMob and genv.Autokillmob then break end
                        end
                    end

                    if targetMob then
                        local mRoot = targetMob:FindFirstChild("HumanoidRootPart") or targetMob.PrimaryPart or targetMob:FindFirstChildWhichIsA("BasePart")
                        local mHum = targetMob:FindFirstChildOfClass("Humanoid")
                        if mRoot and mHum and mHum.Health > 0 then
                            local sHeight = hubState.safeDistance and 18 or 10
                            hrp.Velocity = Vector3.new(0, 0, 0)
                            hrp.CFrame = CFrame.new(mRoot.Position + Vector3.new(0, sHeight, 0), mRoot.Position)

                            -- Gom quái xung quanh nếu bật autocat
                            if genv.autocat then
                                for _, fld in ipairs(mobFolders) do
                                    if fld then
                                        for _, otherMob in ipairs(fld:GetChildren()) do
                                            if otherMob:IsA("Model") and otherMob.Name == targetMob.Name and otherMob ~= targetMob then
                                                local oRoot = otherMob:FindFirstChild("HumanoidRootPart") or otherMob.PrimaryPart or otherMob:FindFirstChildWhichIsA("BasePart")
                                                local oHum = otherMob:FindFirstChildOfClass("Humanoid")
                                                if oRoot and oHum and oHum.Health > 0 and (oRoot.Position - mRoot.Position).Magnitude < 160 then
                                                    oRoot.CFrame = mRoot.CFrame
                                                    oRoot.Velocity = Vector3.new(0, 0, 0)
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            -- Tự bật Haki
                            if hubState.autoHaki or genv.haki then
                                pcall(function()
                                    local net = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                                    if net and net:FindFirstChild("Functions") and net.Functions:FindFirstChild("Skill") then
                                        net.Functions.Skill:InvokeServer("Buso")
                                    end
                                end)
                            end

                            -- Trang bị vũ khí đánh
                            local tool = char:FindFirstChildOfClass("Tool")
                            if not tool then
                                local bpTool = player.Backpack:FindFirstChildOfClass("Tool")
                                if bpTool then hum:EquipTool(bpTool) end
                            else
                                tool:Activate()
                            end

                            -- Xả chiêu thông minh (Z, X, C, V, E)
                            if hubState.autoSkills or genv.opeskill then
                                local activeSkillKeys = {}
                                local function pushKey(k)
                                    for _, ek in ipairs(activeSkillKeys) do
                                        if ek == k then return end
                                    end
                                    table.insert(activeSkillKeys, k)
                                end

                                if hubState.skillSword and hubState.skillSwordKeys then
                                    if hubState.skillSwordKeys == "Chỉ Phím Z" then pushKey("Z")
                                    elseif hubState.skillSwordKeys == "Chỉ Phím X" then pushKey("X")
                                    else pushKey("Z"); pushKey("X") end
                                end
                                if hubState.skillFruit and hubState.skillFruitKeys then
                                    if string.find(hubState.skillFruitKeys, "Z") then pushKey("Z") end
                                    if string.find(hubState.skillFruitKeys, "X") then pushKey("X") end
                                    if string.find(hubState.skillFruitKeys, "C") then pushKey("C") end
                                    if string.find(hubState.skillFruitKeys, "V") then pushKey("V") end
                                end

                                if type(genv.CombatSkillFruit) == "table" and #genv.CombatSkillFruit > 0 then
                                    for _, k in ipairs(genv.CombatSkillFruit) do pushKey(k) end
                                end
                                if type(genv.CombatSkillSword) == "table" and #genv.CombatSkillSword > 0 then
                                    for _, k in ipairs(genv.CombatSkillSword) do pushKey(k) end
                                end
                                if type(genv.CombatSkillMelee) == "table" and #genv.CombatSkillMelee > 0 then
                                    for _, k in ipairs(genv.CombatSkillMelee) do pushKey(k) end
                                end

                                if #activeSkillKeys == 0 then
                                    activeSkillKeys = { "Z", "X" }
                                    if hubState.skillMelee and hubState.skillMeleeKeys == "Toàn Bộ (Z, X, C, V, E)" then
                                        activeSkillKeys = { "Z", "X", "C", "V", "E" }
                                    elseif hubState.skillFruit then
                                        activeSkillKeys = { "Z", "X", "C", "V" }
                                    end
                                end

                                for _, k in ipairs(activeSkillKeys) do
                                    pcall(function()
                                        if vim then
                                            local keyEnum = Enum.KeyCode[k]
                                            if keyEnum then
                                                vim:SendKeyEvent(true, keyEnum, false, game)
                                                task.wait(0.03)
                                                vim:SendKeyEvent(false, keyEnum, false, game)
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ========================================================
    -- [NATIVE AUTO MATERIAL FARM WORKER]
    -- ========================================================
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(0.5)
            if (hubState.farmSea3Mat or hubState.farmSea2Mat or hubState.farmSea1Mat or genv.farmMaterialsea3 or genv.farmMaterialsea2 or genv.farmMaterialsea1) and currentMode == "off" then
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                    local hrp = char.HumanoidRootPart
                    local hum = char.Humanoid
                    if hum.Health <= 0 then return end

                    -- Xác định nguyên liệu đang chọn
                    local targetMat = hubState.nguyenlieuSea3 or "Coral"
                    if hubState.farmSea2Mat then targetMat = hubState.nguyenlieuSea2 or "Iron Ingot"
                    elseif hubState.farmSea1Mat then targetMat = hubState.nguyenlieuSea1 or "Leather" end

                    local rawMat = string.match(targetMat, "^([%w%s%']+)") or targetMat
                    rawMat = string.lower(string.gsub(rawMat, "%s+$", ""))

                    local MAT_MOB_MAP = {
                        ["coral"] = { "coral", "fishman", "ocean", "deep" },
                        ["shark's fin"] = { "shark", "megalodon", "gladiator" },
                        ["dragon scale"] = { "dragon", "drake", "volcano" },
                        ["sea king's blood"] = { "sea king", "hydra", "serpent" },
                        ["phoenix tear"] = { "phoenix", "fire bird", "blaze" },
                        ["iron ingot"] = { "samurai", "soldier", "knight" },
                        ["dark powder"] = { "shadow", "dark", "skeleton" },
                        ["ghost flesh"] = { "ghost", "zombie", "spirit" },
                        ["magma crystal"] = { "magma", "lava", "volcano" },
                        ["leather"] = { "bandit", "pirate", "thief" },
                        ["wood"] = { "monkey", "gorilla", "jungle" },
                        ["rope"] = { "sailor", "marine", "guard" },
                        ["thief rag"] = { "thief", "bandit", "clown" },
                    }
                    local keywords = MAT_MOB_MAP[rawMat] or { rawMat }

                    -- Tìm quái rơi nguyên liệu
                    local targetMob: Model? = nil
                    local mobFolders = { workspace:FindFirstChild("Monster"), workspace:FindFirstChild("Enemy") }
                    for _, fld in ipairs(mobFolders) do
                        if fld then
                            for _, m in ipairs(fld:GetChildren()) do
                                if m:IsA("Model") then
                                    local mHum = m:FindFirstChildOfClass("Humanoid")
                                    local mRoot = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                                    if mHum and mHum.Health > 0 and mRoot then
                                        local mn = string.lower(m.Name)
                                        local matched = false
                                        for _, kw in ipairs(keywords) do
                                            if string.find(mn, kw) or string.find(kw, mn) then
                                                matched = true
                                                break
                                            end
                                        end
                                        if matched then
                                            targetMob = m
                                            break
                                        end
                                    end
                                end
                            end
                            if targetMob then break end
                        end
                    end

                    if targetMob then
                        local mRoot = targetMob:FindFirstChild("HumanoidRootPart") or targetMob.PrimaryPart or targetMob:FindFirstChildWhichIsA("BasePart")
                        if mRoot then
                            hrp.Velocity = Vector3.new(0, 0, 0)
                            hrp.CFrame = CFrame.new(mRoot.Position + Vector3.new(0, 18, 0), mRoot.Position)
                            local tool = char:FindFirstChildOfClass("Tool") or player.Backpack:FindFirstChildOfClass("Tool")
                            if tool and tool.Parent == player.Backpack then hum:EquipTool(tool) end
                            if tool and tool.Parent == char then tool:Activate() end
                        end
                    end
                end)
            end
        end
    end)

    -- ========================================================
    -- [NATIVE AUTO DUNGEON WORKER]
    -- ========================================================
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(0.5)
            if (hubState.autoDungeon or genv.autodungeon) and currentMode == "off" then
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                    local hrp = char.HumanoidRootPart
                    local hum = char.Humanoid
                    if hum.Health <= 0 then return end
                    local dMode = hubState.dungeonMode or genv.dungeonmode or "Easy"

                    -- Tự hồi máu bằng gậy nếu bật và máu < 85%
                    if hubState.dungeonAutoHeal and hum.Health / hum.MaxHealth < 0.85 then
                        local scepter = char:FindFirstChild("Scepter") or player.Backpack:FindFirstChild("Scepter") or char:FindFirstChild("Golden Staff") or player.Backpack:FindFirstChild("Golden Staff")
                        if scepter and scepter.Parent == player.Backpack then
                            hum:EquipTool(scepter)
                            task.wait(0.2)
                            scepter:Activate()
                        end
                    end

                    -- Quét quái Dungeon
                    local dungeonFolders = { workspace:FindFirstChild("Dungeon"), workspace:FindFirstChild("Monster"), workspace:FindFirstChild("RaidMonster") }
                    local targetMob: Model? = nil
                    for _, fld in ipairs(dungeonFolders) do
                        if fld then
                            for _, m in ipairs(fld:GetChildren()) do
                                if m:IsA("Model") then
                                    local mHum = m:FindFirstChildOfClass("Humanoid")
                                    local mRoot = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                                    if mHum and mHum.Health > 0 and mRoot then
                                        targetMob = m
                                        break
                                    end
                                end
                            end
                            if targetMob then break end
                        end
                    end

                    if targetMob then
                        local mRoot = targetMob:FindFirstChild("HumanoidRootPart") or targetMob.PrimaryPart or targetMob:FindFirstChildWhichIsA("BasePart")
                        if mRoot then
                            local tactics = hubState.dungeonTactics or "Safe"
                            local sDist = string.find(tactics, "Fast") and 7 or (string.find(tactics, "Safe") and 22 or 15)
                            hrp.Velocity = Vector3.new(0, 0, 0)
                            hrp.CFrame = CFrame.new(mRoot.Position + Vector3.new(0, sDist, 0), mRoot.Position)
                            if hubState.dungeonCameraLock ~= false then
                                pcall(function()
                                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, mRoot.Position)
                                end)
                            end
                            local tool = char:FindFirstChildOfClass("Tool") or player.Backpack:FindFirstChildOfClass("Tool")
                            if tool and tool.Parent == player.Backpack then hum:EquipTool(tool) end
                            if tool and tool.Parent == char then tool:Activate() end
                        end
                    end
                end)
            end
        end
    end)

    -- ========================================================
    -- [NATIVE FRUIT AUTO & SHOP SNIPER WORKER]
    -- ========================================================
    task.spawn(function()
        local lastSnipe = 0
        while genv._YokaHubToken == myToken do
            task.wait(0.4)
            pcall(function()
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                -- 1. Tự Hút / Nhặt Trái Rơi Tự Do
                if (hubState.bringFruits or genv.BringDroppedFruit) and hrp then
                    for _, item in ipairs(workspace:GetChildren()) do
                        if item:IsA("Tool") or (item:IsA("Model") and string.find(string.lower(item.Name), "fruit")) then
                            local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                            if handle and (handle.Position - hrp.Position).Magnitude < 4000 then
                                hrp.Velocity = Vector3.new(0, 0, 0)
                                hrp.CFrame = handle.CFrame + Vector3.new(0, 2, 0)
                                task.wait(0.3)
                            end
                        end
                    end
                end

                -- 2. Tự Động Cất Trái Vào Kho Rương (Store Fruit)
                if hubState.storeFruits or genv.autobuy then
                    local function checkAndStore(tool: Tool)
                        if tool and string.find(string.lower(tool.Name), "fruit") then
                            local net = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                            if net and net:FindFirstChild("Functions") and net.Functions:FindFirstChild("StoreFruit") then
                                net.Functions.StoreFruit:InvokeServer(tool.Name)
                            end
                        end
                    end
                    for _, t in ipairs(player.Backpack:GetChildren()) do
                        if t:IsA("Tool") then checkAndStore(t) end
                    end
                    if char then
                        local held = char:FindFirstChildOfClass("Tool")
                        if held then checkAndStore(held) end
                    end
                end

                -- 3. Shop Sniper Tự Mua Trái Khi Mở Bán
                if hubState.snipeShop or genv.shopSniperEnabled then
                    local now = os.clock()
                    local delay = hubState.snipeDelay or genv.shopSniperDelay or 5
                    if now - lastSnipe >= delay then
                        lastSnipe = now
                        local targetFruits = genv.shopSniperFruits or (hubState.snipeFruit and { hubState.snipeFruit }) or { "Dragon", "Phoenix", "Gate", "Dough", "Erebus" }
                        local net = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        if net and net:FindFirstChild("Functions") then
                            local shopFunc = net.Functions:FindFirstChild("FruitShop") or net.Functions:FindFirstChild("Merchant")
                            if shopFunc then
                                for _, fruitName in ipairs(targetFruits) do
                                    pcall(function()
                                        shopFunc:InvokeServer("Buy", fruitName)
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- ========================================================
    -- [NATIVE MOVEMENT & UTILITIES WORKER]
    -- ========================================================
    -- 1. Đi Trên Mặt Nước (Walk On Water)
    task.spawn(function()
        local waterPlatform: Part? = nil
        while genv._YokaHubToken == myToken do
            task.wait(0.1)
            pcall(function()
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if (hubState.walkOnWater or hubState.fishFloat or genv.Walkonwater) and hrp then
                    if not waterPlatform or not waterPlatform.Parent then
                        waterPlatform = Instance.new("Part")
                        waterPlatform.Name = "YokaWaterPlatform"
                        waterPlatform.Size = Vector3.new(20, 1, 20)
                        waterPlatform.Transparency = 1
                        waterPlatform.Anchored = true
                        waterPlatform.CanCollide = true
                        waterPlatform.Parent = workspace
                    end
                    if hrp.Position.Y < 20 and hrp.Position.Y > -30 then
                        waterPlatform.Position = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
                    else
                        waterPlatform.Position = Vector3.new(0, -999, 0)
                    end
                else
                    if waterPlatform then
                        waterPlatform:Destroy()
                        waterPlatform = nil
                    end
                end
            end)
        end
        if waterPlatform then waterPlatform:Destroy() end
    end)

    -- 2. Nhảy Vô Hạn (Infinite Jump)
    pcall(function()
        local uis = game:GetService("UserInputService")
        uis.JumpRequest:Connect(function()
            if (hubState.infiniteJump or genv.InfiniteJumpEnabled) and player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end)

    -- 3. Click Teleport (Bấm chuột dịch chuyển)
    pcall(function()
        local mouse = player:GetMouse()
        mouse.Button1Down:Connect(function()
            if (hubState.clickTeleport or genv.clickTeleportEnabled) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hit = mouse.Hit
                if hit then
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
                end
            end
        end)
    end)

    -- 4. Tăng Tốc Độ Chạy (Speed Boost)
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(0.5)
            pcall(function()
                if (hubState.speedBoost or genv.PlayerSpeedEnabled) and player.Character then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.WalkSpeed < 60 then
                        hum.WalkSpeed = genv.PlayerWalkSpeed or 65
                    end
                end
            end)
        end
    end)

    -- 5. Màn Hình Đen (Black Screen AFK)
    task.spawn(function()
        local blackGui: ScreenGui? = nil
        while genv._YokaHubToken == myToken do
            task.wait(0.5)
            pcall(function()
                if (hubState.blackScreen or genv.BlackScreen) and not blackGui then
                    blackGui = Instance.new("ScreenGui")
                    blackGui.Name = "YokaBlackScreen"
                    blackGui.IgnoreGuiInset = true
                    blackGui.DisplayOrder = 999999
                    local f = Instance.new("Frame")
                    f.Size = UDim2.new(1, 0, 1, 0)
                    f.BackgroundColor3 = Color3.new(0, 0, 0)
                    f.BorderSizePixel = 0
                    f.Parent = blackGui
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, 0, 0, 40)
                    lbl.Position = UDim2.new(0, 0, 0.5, -20)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = "YokaHub AFK Mode — Tiết Kiệm Điện (Bấm lại để tắt)"
                    lbl.TextColor3 = Color3.fromRGB(160, 160, 160)
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 16
                    lbl.Parent = f
                    blackGui.Parent = coreGui
                elseif not (hubState.blackScreen or genv.BlackScreen) and blackGui then
                    blackGui:Destroy()
                    blackGui = nil
                end
            end)
        end
        if blackGui then blackGui:Destroy() end
    end)

    -- ========================================================
    -- [NATIVE DAILY QUEST & RACE ROLL WORKER]
    -- ========================================================
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(1.5)
            if hubState.autoDailyQuest or genv.autoalldailyquest then
                pcall(function()
                    local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    if rem and rem:FindFirstChild("Functions") and rem.Functions:FindFirstChild("DailyQuest") then
                        rem.Functions.DailyQuest:InvokeServer("ClaimAll")
                        task.wait(0.5)
                        rem.Functions.DailyQuest:InvokeServer("AcceptAll")
                    end
                end)
            end
            if hubState.autoRaceRoll or genv.AutoGetAutoRollRace then
                pcall(function()
                    local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    if rem and rem:FindFirstChild("Functions") and rem.Functions:FindFirstChild("Race") then
                        rem.Functions.Race:InvokeServer("Roll")
                    end
                end)
            end
        end
    end)

    -- ========================================================
    -- [NATIVE AUTO DISMISS & AUTO ALLY WORKER]
    -- ========================================================
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(2.0)
            if hubState.autoDismiss773 then
                pcall(function()
                    local promptGui = coreGui:FindFirstChild("RobloxPromptGui")
                    if promptGui and promptGui:FindFirstChild("promptOverlay") then
                        local btn = promptGui.promptOverlay:FindFirstChild("ErrorDismissButton", true)
                        if btn and btn:IsA("GuiButton") and btn.Visible then
                            btn.Visible = false
                        end
                    end
                end)
            end
            if hubState.autoAlly then
                pcall(function()
                    local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    if rem and rem:FindFirstChild("Functions") and rem.Functions:FindFirstChild("Ally") then
                        for _, otherPlr in ipairs(players:GetPlayers()) do
                            if otherPlr ~= player then
                                rem.Functions.Ally:InvokeServer("Accept", otherPlr)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ========================================================
    -- [NATIVE ESP RENDER WORKER (FRUITS, PLAYERS & CHESTS)]
    -- ========================================================
    task.spawn(function()
        local activeEspObjects: { [Instance]: BillboardGui } = {}

        local function cleanupEsp(tag: string)
            for inst, bb in pairs(activeEspObjects) do
                if bb.Name == tag then
                    pcall(function() bb:Destroy() end)
                    activeEspObjects[inst] = nil
                end
            end
        end

        while genv._YokaHubToken == myToken do
            task.wait(0.4)
            pcall(function()
                local char = player.Character
                local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                local myPos = myRoot and myRoot.Position or Vector3.new(0, 0, 0)

                -- 1. Fruit ESP
                if hubState.fruitESP or genv.FruitESPEnabled then
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if obj:IsA("Tool") and string.find(string.lower(obj.Name), "fruit") then
                            local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
                            if handle and not handle:FindFirstChild("YokaFruitESP") then
                                local bb = Instance.new("BillboardGui")
                                bb.Name = "YokaFruitESP"
                                bb.AlwaysOnTop = true
                                bb.Size = UDim2.new(0, 160, 0, 30)
                                bb.StudsOffset = Vector3.new(0, 2.5, 0)
                                local lbl = Instance.new("TextLabel")
                                lbl.Size = UDim2.new(1, 0, 1, 0)
                                lbl.BackgroundTransparency = 1
                                lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                                lbl.TextStrokeTransparency = 0.2
                                lbl.Font = Enum.Font.GothamBold
                                lbl.TextSize = 13
                                local dist = math.floor((handle.Position - myPos).Magnitude)
                                lbl.Text = "🍎 " .. obj.Name .. " [" .. dist .. "m]"
                                lbl.Parent = bb
                                bb.Adornee = handle
                                bb.Parent = handle
                                activeEspObjects[handle] = bb
                            elseif handle and handle:FindFirstChild("YokaFruitESP") then
                                local lbl = handle.YokaFruitESP:FindFirstChildOfClass("TextLabel")
                                if lbl then
                                    local dist = math.floor((handle.Position - myPos).Magnitude)
                                    lbl.Text = "🍎 " .. obj.Name .. " [" .. dist .. "m]"
                                end
                            end
                        end
                    end
                else
                    cleanupEsp("YokaFruitESP")
                end

                -- 2. Player ESP
                if hubState.playerESP or genv.PlayerESPEnabled then
                    for _, p in ipairs(players:GetPlayers()) do
                        if p ~= player and p.Character then
                            local pHead = p.Character:FindFirstChild("Head")
                            local pHum = p.Character:FindFirstChildOfClass("Humanoid")
                            if pHead and pHum and pHum.Health > 0 and not pHead:FindFirstChild("YokaPlayerESP") then
                                local bb = Instance.new("BillboardGui")
                                bb.Name = "YokaPlayerESP"
                                bb.AlwaysOnTop = true
                                bb.Size = UDim2.new(0, 160, 0, 32)
                                bb.StudsOffset = Vector3.new(0, 3, 0)
                                local lbl = Instance.new("TextLabel")
                                lbl.Size = UDim2.new(1, 0, 1, 0)
                                lbl.BackgroundTransparency = 1
                                lbl.TextColor3 = Color3.fromRGB(80, 255, 180)
                                lbl.TextStrokeTransparency = 0.2
                                lbl.Font = Enum.Font.GothamBold
                                lbl.TextSize = 13
                                local dist = math.floor((pHead.Position - myPos).Magnitude)
                                local hpPct = math.floor((pHum.Health / math.max(1, pHum.MaxHealth)) * 100)
                                lbl.Text = "👤 " .. p.DisplayName .. " (" .. hpPct .. "% | " .. dist .. "m)"
                                lbl.Parent = bb
                                bb.Adornee = pHead
                                bb.Parent = pHead
                                activeEspObjects[pHead] = bb
                            elseif pHead and pHead:FindFirstChild("YokaPlayerESP") and pHum then
                                local lbl = pHead.YokaPlayerESP:FindFirstChildOfClass("TextLabel")
                                if lbl then
                                    local dist = math.floor((pHead.Position - myPos).Magnitude)
                                    local hpPct = math.floor((pHum.Health / math.max(1, pHum.MaxHealth)) * 100)
                                    lbl.Text = "👤 " .. p.DisplayName .. " (" .. hpPct .. "% | " .. dist .. "m)"
                                end
                            end
                        end
                    end
                else
                    cleanupEsp("YokaPlayerESP")
                end

                -- 3. Chest ESP
                if hubState.chestESP or genv.ChestESPEnabled then
                    local chestFolders = { workspace:FindFirstChild("Chests"), workspace:FindFirstChild("ChestFolder") }
                    for _, cf in ipairs(chestFolders) do
                        if cf then
                            for _, ch in ipairs(cf:GetChildren()) do
                                local root = ch:IsA("BasePart") and ch or ch:FindFirstChildWhichIsA("BasePart")
                                if root and not root:FindFirstChild("YokaChestESP") then
                                    local bb = Instance.new("BillboardGui")
                                    bb.Name = "YokaChestESP"
                                    bb.AlwaysOnTop = true
                                    bb.Size = UDim2.new(0, 140, 0, 28)
                                    bb.StudsOffset = Vector3.new(0, 2, 0)
                                    local lbl = Instance.new("TextLabel")
                                    lbl.Size = UDim2.new(1, 0, 1, 0)
                                    lbl.BackgroundTransparency = 1
                                    lbl.TextColor3 = Color3.fromRGB(255, 170, 40)
                                    lbl.TextStrokeTransparency = 0.2
                                    lbl.Font = Enum.Font.GothamBold
                                    lbl.TextSize = 12
                                    local dist = math.floor((root.Position - myPos).Magnitude)
                                    lbl.Text = "📦 Rương [" .. dist .. "m]"
                                    lbl.Parent = bb
                                    bb.Adornee = root
                                    bb.Parent = root
                                    activeEspObjects[root] = bb
                                elseif root and root:FindFirstChild("YokaChestESP") then
                                    local lbl = root.YokaChestESP:FindFirstChildOfClass("TextLabel")
                                    if lbl then
                                        local dist = math.floor((root.Position - myPos).Magnitude)
                                        lbl.Text = "📦 Rương [" .. dist .. "m]"
                                    end
                                end
                            end
                        end
                    end
                else
                    cleanupEsp("YokaChestESP")
                end
            end)
        end

        for _, bb in pairs(activeEspObjects) do
            pcall(function() bb:Destroy() end)
        end
    end)
