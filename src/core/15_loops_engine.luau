
    -- Cô lập phạm vi thanh ghi cục bộ cho Engine (tránh vượt giới hạn 200 local registers của Luau)
    ;(function()
    -- ========================================================
    -- [KIỂM TRA ĐỊNH KỲ 19 PHÚT & CHỐNG KICK AFK 20 PHÚT]
    -- ========================================================
    pcall(function()
        local vu = game:GetService("VirtualUser")
        trackConn(player.Idled:Connect(function()
            if hubState.antiAfk19m ~= false and genv._YokaHubToken == myToken then
                pcall(function()
                    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
                    task.wait(1)
                    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
                end)
            end
        end))
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
    -- [SHARED HELPERS: QUÉT QUÁI / BOSS, BAY HOVER LOCK, AUTO AIM & SMART SKILL HOLD]
    -- ========================================================
    local sharedVim = game:GetService("VirtualInputManager")
    local sharedRunService = game:GetService("RunService")
    local sharedRS = game:GetService("ReplicatedStorage")

    local currentCombatTarget: Model? = nil
    local currentCombatTargetAt = 0
    local dodgeUntilClock = 0
    local isHoldingSkill = false
    local lastPlayerSkillCastClock = 0
    local getActiveM1Categories: () -> { string }
    local getAvailableM1Categories: () -> { string }

    local activeFlightTarget = {
        pos = nil :: Vector3?,
        lookAt = nil :: Vector3?,
        instant = false,
        priority = 0,
        updatedAt = 0,
    }

    local function setFlightTarget(pos: Vector3, lookAt: Vector3?, instant: boolean?, priority: number?)
        local prio = priority or 40
        local baseSpeed = tonumber(hubState.flySpeed or genv.YokaFlySpeed) or 420
        local now = os.clock()
        if activeFlightTarget.pos ~= nil and prio < activeFlightTarget.priority and (now - activeFlightTarget.updatedAt) < 0.9 then
            return
        end
        if now < dodgeUntilClock and prio < 90 then
            return
        end
        activeFlightTarget.pos = pos
        activeFlightTarget.lookAt = lookAt
        activeFlightTarget.instant = (instant == true)
        activeFlightTarget.priority = prio
        activeFlightTarget.updatedAt = now
    end

    local function clearFlightTarget(minPriority: number?)
        if (minPriority or 999) >= activeFlightTarget.priority then
            activeFlightTarget.pos = nil
            activeFlightTarget.lookAt = nil
            activeFlightTarget.instant = false
            activeFlightTarget.priority = 0
            activeFlightTarget.updatedAt = 0
        end
    end

    local function getModelRoot(m: Model?): BasePart?
        if not m or not m.Parent then return nil end
        return (m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")) :: BasePart?
    end

    local function isModelAlive(m: Model?): boolean
        if not m or not m.Parent then return false end
        local h = m:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
            return getModelRoot(m) ~= nil
        end
        return false
    end

    local function setCurrentCombatTarget(m: Model?)
        if isModelAlive(m) then
            currentCombatTarget = m
            currentCombatTargetAt = os.clock()
        end
    end

    local function getAliveMobFolders(includeBosses: boolean, includeSeaMonsters: boolean?, includeDungeon: boolean?): { Instance }
        local list: { Instance } = {}
        local mon = workspace:FindFirstChild("Monster")
        if mon then
            table.insert(list, mon)
            local mSub = mon:FindFirstChild("Mon")
            if mSub then table.insert(list, mSub) end
            if includeBosses then
                local bSub = mon:FindFirstChild("Boss")
                if bSub then table.insert(list, bSub) end
            end
        end
        for _, fn in ipairs({ "Enemy", "Monsters" }) do
            local f = workspace:FindFirstChild(fn)
            if f then table.insert(list, f) end
        end
        if includeSeaMonsters then
            for _, fn in ipairs({ "SeaMonster", "GhostMonster" }) do
                local f = workspace:FindFirstChild(fn)
                if f then table.insert(list, f) end
            end
        end
        if includeDungeon then
            for _, fn in ipairs({ "Dungeon", "RaidMonster" }) do
                local f = workspace:FindFirstChild(fn)
                if f then table.insert(list, f) end
            end
        end
        return list
    end

    local function isIslandMobName(n: string): boolean
        return string.find(n, "%[lv%.") ~= nil
            or string.find(n, "soldier", 1, true) ~= nil
            or string.find(n, "guard", 1, true) ~= nil
            or string.find(n, "warrior", 1, true) ~= nil
            or string.find(n, "swordsman", 1, true) ~= nil
            or string.find(n, "cultist", 1, true) ~= nil
            or string.find(n, "sentry", 1, true) ~= nil
            or string.find(n, "diver", 1, true) ~= nil
            or string.find(n, "explorer", 1, true) ~= nil
            or string.find(n, "raider", 1, true) ~= nil
            or string.find(n, "wayfarer", 1, true) ~= nil
            or string.find(n, "tidebreaker", 1, true) ~= nil
            or string.find(n, "voyager", 1, true) ~= nil
            or string.find(n, "villager", 1, true) ~= nil
            or string.find(n, "combatant", 1, true) ~= nil
            or string.find(n, "bandit", 1, true) ~= nil
            or string.find(n, "pirate", 1, true) ~= nil
            or string.find(n, "tamer", 1, true) ~= nil
            or string.find(n, "seeker", 1, true) ~= nil
            or string.find(n, "buccaneer", 1, true) ~= nil
            or string.find(n, "gorilla", 1, true) ~= nil
            or string.find(n, "ape", 1, true) ~= nil
            or string.find(n, "minion", 1, true) ~= nil
            or string.find(n, "grunt", 1, true) ~= nil
            or string.find(n, "scout", 1, true) ~= nil
            or string.find(n, "fighter", 1, true) ~= nil
            or string.find(n, "assaulter", 1, true) ~= nil
            or string.find(n, "gunner", 1, true) ~= nil
            or string.find(n, "marksman", 1, true) ~= nil
            or string.find(n, "apprentice", 1, true) ~= nil
            or string.find(n, "crew", 1, true) ~= nil
    end

    local function isDepthKingBoss(n: string): boolean
        if isIslandMobName(n) then return false end
        if string.find(n, "abyssal", 1, true) ~= nil then return false end
        return string.find(n, "depth king", 1, true) ~= nil or n == "depthking" or (string.find(n, "depth", 1, true) ~= nil and string.find(n, "king", 1, true) ~= nil)
    end

    local function isDragonBoss(n: string): boolean
        if isIslandMobName(n) then return false end
        if string.find(n, "abyssal", 1, true) ~= nil or string.find(n, "depth", 1, true) ~= nil or string.find(n, "tyrant", 1, true) ~= nil then return false end
        return string.find(n, "drakenfyr", 1, true) ~= nil or string.find(n, "inferno king", 1, true) ~= nil or string.find(n, "sea dragon", 1, true) ~= nil or (string.find(n, "dragon", 1, true) ~= nil and string.find(n, "fruit", 1, true) == nil and string.find(n, "claw", 1, true) == nil and string.find(n, "orb", 1, true) == nil)
    end

    local function isAbyssalBoss(n: string): boolean
        if isIslandMobName(n) then return false end
        if string.find(n, "depth", 1, true) ~= nil then return false end
        return string.find(n, "abyssal tyrant", 1, true) ~= nil or n == "abyssaltyrant" or (string.find(n, "tyrant", 1, true) ~= nil and string.find(n, "abyssal", 1, true) ~= nil)
    end

    local function isKrakenBoss(n: string): boolean
        if isIslandMobName(n) then return false end
        return string.find(n, "kraken", 1, true) ~= nil or string.find(n, "tentacle", 1, true) ~= nil
    end

    local function isCrabBoss(n: string): boolean
        if isIslandMobName(n) then return false end
        return string.find(n, "giant crab", 1, true) ~= nil or (string.find(n, "crab", 1, true) ~= nil and string.find(n, "meat", 1, true) == nil)
    end

    local function isSerpentBoss(n: string): boolean
        if isIslandMobName(n) then return false end
        return string.find(n, "serpent", 1, true) ~= nil
    end

    local function isSeaEventMiscBoss(n: string): boolean
        if isIslandMobName(n) then return false end
        return string.find(n, "sea beast", 1, true) ~= nil or string.find(n, "seabeast", 1, true) ~= nil or string.find(n, "galleon", 1, true) ~= nil or string.find(n, "ghost ship", 1, true) ~= nil
    end

    local function isSea3BossEnabled(name: string): boolean
        local n = string.lower(name)
        if isIslandMobName(n) then return false end

        -- 1. Depth King (Top 1)
        if isDepthKingBoss(n) then
            return hubState.fightSea3DepthKing ~= false
        end
        -- 2. Drakenfyr / Dragon / Sea Dragon (Top 2)
        if isDragonBoss(n) then
            return hubState.fightSea3Dragon ~= false
        end
        -- 3. Abyssal Tyrant (Top 3)
        if isAbyssalBoss(n) then
            return hubState.fightSea3Abyssal ~= false
        end
        -- 4. Kraken & Xúc tu (Top 4)
        if isKrakenBoss(n) then
            return hubState.fightSea3Kraken ~= false
        end
        -- 5. Cua biển (Top 5)
        if isCrabBoss(n) then
            return hubState.fightSea3Crab ~= false
        end
        -- 6. Rắn biển Serpent
        if isSerpentBoss(n) then
            return hubState.fightSea2Serpent ~= false
        end
        -- 7. Các Sea Events thường khác (Galleon / Ghost / Sea Beast)
        if isSeaEventMiscBoss(n) then
            return hubState.fightSea3Events == true
        end
        return false
    end

    local function isSea2BossEnabled(name: string): boolean
        local n = string.lower(name)
        if string.find(n, "hydra", 1, true) ~= nil then return hubState.fightSea2Hydra ~= false end
        if string.find(n, "sea king", 1, true) ~= nil or string.find(n, "seaking", 1, true) ~= nil then return hubState.fightSea2SeaKing ~= false end
        if string.find(n, "ghost", 1, true) ~= nil then return hubState.fightSea2GhostShip ~= false end
        if string.find(n, "serpent", 1, true) ~= nil then return hubState.fightSea2Serpent ~= false end
        return false
    end

    local function getAimPoint(targetModel: Model, targetRoot: BasePart): Vector3
        local vel = Vector3.zero
        pcall(function()
            vel = targetRoot.AssemblyLinearVelocity
        end)
        local lead = Vector3.new(math.clamp(vel.X, -80, 80), math.clamp(vel.Y, -30, 30), math.clamp(vel.Z, -80, 80)) * 0.08
        return targetRoot.Position + lead
    end

    local function getBestCombatTarget(maxRange: number): (Model?, BasePart?)
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil, nil end
        local myPos = hrp.Position

        if currentCombatTarget and (os.clock() - currentCombatTargetAt) < 4.0 and isModelAlive(currentCombatTarget) then
            local cRoot = getModelRoot(currentCombatTarget)
            if cRoot and (cRoot.Position - myPos).Magnitude <= (maxRange + 220) then
                return currentCombatTarget, cRoot
            end
        end

        local bestModel: Model? = nil
        local bestRoot: BasePart? = nil
        local bestTier = -1
        local bestDist = maxRange

        local function scanFolder(fld: Instance?, tier: number)
            if not fld then return end
            for _, m in ipairs(fld:GetChildren()) do
                if m:IsA("Model") then
                    local mHum = m:FindFirstChildOfClass("Humanoid")
                    local mRoot = getModelRoot(m)
                    if mHum and mHum.Health > 0 and mRoot then
                        local d = (mRoot.Position - myPos).Magnitude
                        if d <= maxRange then
                            if tier > bestTier or (tier == bestTier and d < bestDist) then
                                bestTier = tier
                                bestDist = d
                                bestModel = m
                                bestRoot = mRoot
                            end
                        end
                    end
                end
            end
        end

        -- Ưu tiên Sea Event / Boss Biển -> Island Boss -> Quái thường / Dungeon
        scanFolder(workspace:FindFirstChild("SeaMonster"), 3)
        scanFolder(workspace:FindFirstChild("GhostMonster"), 3)
        local mon = workspace:FindFirstChild("Monster")
        if mon then
            scanFolder(mon:FindFirstChild("Boss"), 2)
            scanFolder(mon:FindFirstChild("Mon"), 1)
            scanFolder(mon, 1)
        end
        scanFolder(workspace:FindFirstChild("Dungeon"), 1)
        scanFolder(workspace:FindFirstChild("RaidMonster"), 1)
        scanFolder(workspace:FindFirstChild("Enemy"), 1)
        scanFolder(workspace:FindFirstChild("Monsters"), 1)

        return bestModel, bestRoot
    end

    -- ========================================================
    -- [UNIFIED FLIGHT + HOVER LOCK + NOCLIP + REALTIME AUTO AIM]
    -- ========================================================
    local function isAnyFlightConsumerActive(now: number): boolean
        if now < dodgeUntilClock then return true end
        if activeFlightTarget.priority >= 68 and (now - activeFlightTarget.updatedAt) <= 3.0 then return true end
        if hubState.autoLevel or hubState.autoKillSelectedMob then return true end
        if hubState.farmSea3Mat or hubState.farmSea2Mat or hubState.farmSea1Mat then return true end
        if hubState.autoDungeon then return true end
        if hubState.bringFruits then return true end
        if (currentMode ~= "off" or hubState.autoFightMaster or hubState.autoFightIslandBoss) and not hubState.autoFish then return true end
        return false
    end

    local noclipWasActive = false
    pcall(function()
        trackConn(sharedRunService.Heartbeat:Connect(function(dt: number)
            if genv._YokaHubToken ~= myToken then return end
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not (char and hrp and hum and hum.Health > 0) then return end

            local now = os.clock()
            local flightAlive = activeFlightTarget.pos ~= nil and (now - activeFlightTarget.updatedAt) <= 2.6
            if flightAlive and not isAnyFlightConsumerActive(now) then
                clearFlightTarget(999)
                flightAlive = false
            end

            -- 1. Realtime Auto Aim (_G.MouseHit cập nhật từng khung hình cho Quái, Boss & Sea Event)
            local aimPos: Vector3? = nil
            if hubState.skillAimbot ~= false and genv.PlayerAimbotEnabled ~= false then
                local aimRange = tonumber(genv.PlayerAimRange) or 450
                local tModel, tRoot = getBestCombatTarget(aimRange)
                if tModel and tRoot then
                    aimPos = getAimPoint(tModel, tRoot)
                    _G.MouseHit = CFrame.new(aimPos)
                    if not flightAlive and (aimPos - hrp.Position).Magnitude <= 140 and (isHoldingSkill or #getAvailableM1Categories() > 0) then
                        local flatLook = Vector3.new(aimPos.X, hrp.Position.Y, aimPos.Z)
                        if (flatLook - hrp.Position).Magnitude > 0.5 then
                            hrp.CFrame = CFrame.lookAt(hrp.Position, flatLook)
                        end
                    end
                end
            end

            -- 2. Flight + Hover Lock (Bay mượt trên không & khóa độ cao chống rơi rớt kể cả khi chiêu xóa BodyVelocity)
            if flightAlive and activeFlightTarget.pos then
                if hum.Sit then hum.Sit = false end
                local bv = hrp:FindFirstChild("YokaHoverBV")
                if not bv or not bv:IsA("BodyVelocity") then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = "YokaHoverBV"
                    bv.MaxForce = Vector3.new(1e7, 1e7, 1e7)
                    bv.P = 20000
                    bv.Velocity = Vector3.zero
                    bv.Parent = hrp
                else
                    bv.Velocity = Vector3.zero
                    bv.MaxForce = Vector3.new(1e7, 1e7, 1e7)
                end

                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)

                local targetPos = activeFlightTarget.pos
                local lookTarget = activeFlightTarget.lookAt or aimPos
                local function orientAt(p: Vector3): CFrame
                    if lookTarget and (lookTarget - p).Magnitude > 0.5 then
                        return CFrame.lookAt(p, lookTarget)
                    end
                    return CFrame.new(p)
                end

                local curPos = hrp.Position
                local delta = targetPos - curPos
                local dist = delta.Magnitude

                -- Tất cả di chuyển đều dùng teleport tức thì, không bay đường dài
                if dist > 20 or activeFlightTarget.instant then
                    hrp.CFrame = orientAt(targetPos)
                    activeFlightTarget.instant = false
                else
                    -- Tại khu vực đánh (farm mob hoặc săn boss): Bay tại chỗ (hover lock) giữ vững độ cao
                    hrp.CFrame = orientAt(targetPos)
                end

                if activeFlightTarget.priority == 70 and dist <= 20 then
                    clearFlightTarget(999)
                end
            else
                local bv = hrp:FindFirstChild("YokaHoverBV")
                if bv then
                    pcall(function() bv:Destroy() end)
                end
            end
        end))

        trackConn(sharedRunService.Stepped:Connect(function()
            if genv._YokaHubToken ~= myToken then return end
            local char = player.Character
            if not char then return end
            local now = os.clock()
            local isFlying = activeFlightTarget.pos ~= nil and (now - activeFlightTarget.updatedAt) <= 2.6 and isAnyFlightConsumerActive(now)
            if isFlying then
                noclipWasActive = true
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:IsA("BasePart") then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            elseif noclipWasActive then
                noclipWasActive = false
                for _, partName in ipairs({ "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head" }) do
                    local p = char:FindFirstChild(partName)
                    if p and p:IsA("BasePart") then
                        p.CanCollide = true
                    end
                end
            end
        end))

        -- Chống spam thông báo "Skill locked!" liên hoàn (chỉ cho phép hiện 1 lần duy nhất mỗi 60 giây, tự gắn lại khi hồi sinh)
        local seenLockedAlerts: { [string]: number } = {}
        local hookedHolders: { [Instance]: boolean } = {}
        local function hookNotifHolder(holder: Instance?)
            if not holder or hookedHolders[holder] then return end
            hookedHolders[holder] = true
            trackConn(holder.ChildAdded:Connect(function(child: Instance)
                if genv._YokaHubToken ~= myToken then return end
                task.defer(function()
                    if not child or not child.Parent then return end
                    local txt = ""
                    if child:IsA("TextLabel") then
                        txt = child.Text or ""
                    else
                        local lbl = child:FindFirstChildWhichIsA("TextLabel", true)
                        if lbl then txt = lbl.Text or "" end
                    end
                    local low = string.lower(txt)
                    if string.find(low, "skill locked", 1, true) or string.find(low, "required", 1, true) then
                        local now = os.clock()
                        local lastSeen = seenLockedAlerts[txt] or 0
                        if (now - lastSeen) < 60.0 then
                            pcall(function() child:Destroy() end)
                        else
                            seenLockedAlerts[txt] = now
                        end
                    end
                end)
            end))
        end

        local pgui = player:FindFirstChild("PlayerGui")
        if pgui then
            local ng = pgui:FindFirstChild("NotificationGui")
            if ng then hookNotifHolder(ng:FindFirstChild("NotificationHolder")) end
            trackConn(pgui.ChildAdded:Connect(function(g: Instance)
                if genv._YokaHubToken ~= myToken then return end
                if g.Name == "NotificationGui" then
                    task.defer(function()
                        hookNotifHolder(g:WaitForChild("NotificationHolder", 5))
                    end)
                end
            end))
        end
    end)

    local function classifyKingLegacyTool(t: Tool): string?
        if not t or not t:IsA("Tool") then return nil end
        local tip = t.ToolTip
        if tip == "Fruit Power" then return "fruit"
        elseif tip == "Sword" then return "sword"
        elseif tip == "Combat" then return "melee"
        end
        if t:GetAttribute("IsWeapon") == true then return "sword" end
        if t:GetAttribute("CustomAnim") == "CombatStyle" then return "melee" end

        local ps = player:FindFirstChild("PlayerStats")
        if ps then
            local dfObj = ps:FindFirstChild("DFName")
            if dfObj and tostring(dfObj.Value) == t.Name then return "fruit" end
            local swObj = ps:FindFirstChild("SwordName")
            if swObj and tostring(swObj.Value) == t.Name then return "sword" end
            local fsObj = ps:FindFirstChild("FightingStyle")
            if fsObj and tostring(fsObj.Value) == t.Name then return "melee" end
        end

        local pScripts = player:FindFirstChild("PlayerScripts")
        local svcs = pScripts and pScripts:FindFirstChild("Services")
        local csh = svcs and svcs:FindFirstChild("ClientSkillHandler")
        if csh then
            if csh:FindFirstChild("FruitSkills") and csh.FruitSkills:FindFirstChild(t.Name .. "_Client") then return "fruit" end
            if csh:FindFirstChild("SwordSkills") and csh.SwordSkills:FindFirstChild(t.Name .. "_Client") then return "sword" end
            if csh:FindFirstChild("FightingStyleSkills") and csh.FightingStyleSkills:FindFirstChild(t.Name .. "_Client") then return "melee" end
        end
        return nil
    end

    local function findToolByCategory(cat: string): Tool?
        local char = player.Character
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and classifyKingLegacyTool(t) == cat then
                    return t
                end
            end
        end
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and classifyKingLegacyTool(t) == cat then
                    return t
                end
            end
        end
        return nil
    end

    getActiveM1Categories = function(): { string }
        local hasSword = (hubState.autoM1Sword == true) or (genv.AutoM1Sword == true)
        local hasMelee = (hubState.autoM1Melee == true) or (genv.AutoM1Melee == true)
        local hasFruit = (hubState.autoM1Fruit == true) or (genv.AutoM1Fruit == true)

        if typeof(hubState.m1SpamList) == "table" then
            for _, opt in ipairs(hubState.m1SpamList) do
                if opt == "Sword M1" then hasSword = true end
                if opt == "Melee M1" then hasMelee = true end
                if opt == "Fruit M1" then hasFruit = true end
            end
        end

        local mode = hubState.toolMode or "Auto Mode"
        if mode == "Sword" then
            return (hasSword or not (hasMelee or hasFruit)) and { "sword" } or {}
        elseif mode == "Melee" then
            return (hasMelee or not (hasSword or hasFruit)) and { "melee" } or {}
        elseif mode == "Fruit" then
            return (hasFruit or not (hasSword or hasMelee)) and { "fruit" } or {}
        end

        -- Auto Mode: CHỈ dùng đúng các vũ khí đã được người dùng tích chọn
        -- Nếu không tích chọn vũ khí nào -> trả về danh sách rỗng {} (tuyệt đối không tự lấy từ kho/bộ nhớ!)
        local cats = {}
        if hasSword then table.insert(cats, "sword") end
        if hasMelee then table.insert(cats, "melee") end
        if hasFruit then table.insert(cats, "fruit") end
        return cats
    end

    getAvailableM1Categories = function(): { string }
        local userCats = getActiveM1Categories()
        local available = {}
        local seen = {}

        -- CHỈ tìm vũ khí người chơi đang có mà người dùng ĐÃ TÍCH CHỌN
        -- Không bao giờ fallback sang vũ khí không được tích chọn
        for _, cat in ipairs(userCats) do
            if findToolByCategory(cat) and not seen[cat] then
                seen[cat] = true
                table.insert(available, cat)
            end
        end

        return available
    end

    local clientModuleCache: { [string]: any } = {}
    local function getClientSkillModule(toolName: string, cat: string): any
        local folderName = (cat == "fruit" and "FruitSkills") or (cat == "sword" and "SwordSkills") or "FightingStyleSkills"
        local cacheKey = folderName .. ":" .. toolName
        if clientModuleCache[cacheKey] ~= nil then
            return clientModuleCache[cacheKey] ~= false and clientModuleCache[cacheKey] or nil
        end
        local pScripts = player:FindFirstChild("PlayerScripts")
        local svcs = pScripts and pScripts:FindFirstChild("Services")
        local csh = svcs and svcs:FindFirstChild("ClientSkillHandler")
        local skillFolder = csh and csh:FindFirstChild(folderName)
        local modInst = skillFolder and skillFolder:FindFirstChild(toolName .. "_Client")
        if modInst and modInst:IsA("ModuleScript") then
            local okReq, modTbl = pcall(require, modInst)
            if okReq and typeof(modTbl) == "table" then
                clientModuleCache[cacheKey] = modTbl
                return modTbl
            end
        end
        clientModuleCache[cacheKey] = false
        return nil
    end

    local cachedSkillAction: RemoteFunction? = nil
    local function getSkillActionRemote(): RemoteFunction?
        if cachedSkillAction and cachedSkillAction.Parent then
            return cachedSkillAction
        end
        local chest = sharedRS:FindFirstChild("Chest")
        local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
        local sa = remFuncs and remFuncs:FindFirstChild("SkillAction")
        if sa and sa:IsA("RemoteFunction") then
            cachedSkillAction = sa
            return sa
        end
        return nil
    end

    local cachedSwordM1: RemoteEvent? = nil
    local function getSwordM1Remote(): RemoteEvent?
        if cachedSwordM1 and cachedSwordM1.Parent then
            return cachedSwordM1
        end
        local chest = sharedRS:FindFirstChild("Chest")
        local remEvts = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Events")
        local sm1 = remEvts and remEvts:FindFirstChild("SwordM1")
        if sm1 and sm1:IsA("RemoteEvent") then
            cachedSwordM1 = sm1
            return sm1
        end
        return nil
    end

    local function triggerKingLegacyM1(tool: Tool, cat: string)
        if not tool or not tool.Parent then return end
        local tModel, tRoot = getBestCombatTarget(150)
        if not tModel or not tRoot then return end
        pcall(function()
            local aimPt = getAimPoint(tModel, tRoot)
            _G.MouseHit = CFrame.new(aimPt)

            local modTbl = getClientSkillModule(tool.Name, cat)
            local sa = getSkillActionRemote()
            local sm1 = (cat == "sword") and getSwordM1Remote() or nil
            local vu = game:GetService("VirtualUser")

            -- Fast Attack Multi-Vector (2 xung nhịp liên tiếp chuẩn siêu tốc)
            for _ = 1, 2 do
                if modTbl and typeof(modTbl.M1) == "function" then
                    task.spawn(function()
                        pcall(modTbl.M1)
                    end)
                end

                if sm1 then
                    pcall(function() sm1:FireServer() end)
                end

                if sa then
                    local prefix = (cat == "fruit" and "DF_") or (cat == "sword" and "SW_") or "FS_"
                    local actionName = prefix .. tool.Name .. "_M1"
                    task.spawn(function()
                        pcall(function() sa:InvokeServer(actionName) end)
                    end)
                end

                pcall(function() tool:Activate() end)
            end

            if vu then
                pcall(function()
                    vu:CaptureController()
                    vu:ClickButton1(Vector2.zero)
                end)
            end

            -- Tăng tốc Animation swing / attack (Animation Speedup Bypass)
            pcall(function()
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local animator = hum and hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        local nameLower = track.Animation and track.Animation.Name:lower() or ""
                        if nameLower:find("slash") or nameLower:find("attack") or nameLower:find("swing") 
                           or nameLower:find("punch") or nameLower:find("m1") or nameLower:find("hit") 
                           or nameLower:find("combo") then
                            track:AdjustSpeed(4.0)
                        end
                    end
                end
            end)
        end)
    end

    local m1CycleIndex = 1
    local lastM1CycleClock = 0
    local m1HitsOnCurrentTool = 0

    local function equipAndFireSelectedM1(char: Model, hum: Humanoid): Tool?
        -- CHỈ ĐÁNH KHI CÓ MỤC TIÊU SỐNG TRONG TẦM
        local tModel, tRoot = getBestCombatTarget(150)
        if not tModel or not tRoot then return nil end

        local cats = getAvailableM1Categories()
        if #cats == 0 then
            -- Người dùng không tích chọn vũ khí nào -> tuyệt đối dừng, không tự cầm vũ khí từ kho/balo!
            return nil
        end

        local now = os.clock()
        -- Tự động luân chuyển vũ khí mượt mà theo nhịp burst siêu tốc (~0.28s hoặc sau 4 nhát đánh)
        if #cats > 1 then
            if (now - lastM1CycleClock) >= 0.28 or m1HitsOnCurrentTool >= 4 then
                lastM1CycleClock = now
                m1HitsOnCurrentTool = 0
                m1CycleIndex = (m1CycleIndex % #cats) + 1
            elseif m1CycleIndex > #cats then
                m1CycleIndex = 1
            end
        else
            m1CycleIndex = 1
        end

        local chosenCat = cats[m1CycleIndex] or cats[1]
        local targetTool = findToolByCategory(chosenCat)
        if not targetTool then
            for _, fallbackCat in ipairs(cats) do
                targetTool = findToolByCategory(fallbackCat)
                if targetTool then
                    chosenCat = fallbackCat
                    break
                end
            end
        end

        if targetTool then
            if targetTool.Parent == player.Backpack then
                hum:EquipTool(targetTool)
            end
            triggerKingLegacyM1(targetTool, chosenCat)
            m1HitsOnCurrentTool += 1
            return targetTool
        end

        return nil
    end

    -- ========================================================
    -- [NATIVE AUTO M1 WORKER (FRUIT / SWORD / MELEE)]
    -- ========================================================
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(0.02)
            local cats = getAvailableM1Categories()
            if #cats == 0 then
                task.wait(0.15)
                continue
            end

            local hasAnyM1 = (hubState.autoM1Fruit == true) or (hubState.autoM1Sword == true) or (hubState.autoM1Melee == true) 
                or (genv.AutoM1Fruit == true) or (genv.AutoM1Sword == true) or (genv.AutoM1Melee == true)
            if typeof(hubState.m1SpamList) == "table" and #hubState.m1SpamList > 0 then
                hasAnyM1 = true
            end
            local inCombat = (currentMode ~= "off") or (hubState.autoLevel == true) or (hubState.autoKillSelectedMob == true) 
                or (hubState.autoFightMaster == true) or (hubState.autoFightIslandBoss == true) or (hubState.autoDungeon == true) 
                or (hubState.farmSea3Mat == true) or (hubState.farmSea2Mat == true) or (hubState.farmSea1Mat == true)

            if (hasAnyM1 or inCombat) and not hubState.autoFish and not isHoldingSkill and os.clock() >= dodgeUntilClock then
                local tModel, _ = getBestCombatTarget(150)
                if tModel then
                    pcall(function()
                        local char = player.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not (char and hum and hrp and hum.Health > 0) then return end
                        equipAndFireSelectedM1(char, hum)
                    end)
                end
            end
        end
    end)

    -- ========================================================
    -- [SMART SKILL HOLD ANALYZER & COOLDOWN CHECKER]
    -- ========================================================
    local skillDataCache: { [string]: any } = {}
    local function getSkillDataTable(toolName: string, cat: string): any
        local subFolder = (cat == "fruit" and "Fruits") or (cat == "sword" and "Swords") or "Styles"
        local cacheKey = subFolder .. ":" .. toolName
        if skillDataCache[cacheKey] ~= nil then
            return skillDataCache[cacheKey] ~= false and skillDataCache[cacheKey] or nil
        end
        local chest = sharedRS:FindFirstChild("Chest")
        local mods = chest and chest:FindFirstChild("Modules")
        local sdRoot = mods and mods:FindFirstChild("SkillData")
        local catFolder = sdRoot and sdRoot:FindFirstChild(subFolder)
        local dataMod = catFolder and (catFolder:FindFirstChild(toolName .. "_Data") or catFolder:FindFirstChild(toolName))
        if dataMod and dataMod:IsA("ModuleScript") then
            local okReq, tbl = pcall(require, dataMod)
            if okReq and typeof(tbl) == "table" then
                skillDataCache[cacheKey] = tbl
                return tbl
            end
        end
        skillDataCache[cacheKey] = false
        return nil
    end

    local function getSkillPrefix(cat: string): string
        if cat == "fruit" then return "DF"
        elseif cat == "sword" then return "SW"
        else return "FS" end
    end

    local function getPlayerStatForCategory(cat: string): number
        local ps = player:FindFirstChild("PlayerStats")
        if not ps then return 0 end
        if cat == "fruit" then
            local o = ps:FindFirstChild("DF") or ps:FindFirstChild("Fruit")
            return o and tonumber(o.Value) or 0
        elseif cat == "sword" then
            local o = ps:FindFirstChild("sword") or ps:FindFirstChild("Sword")
            return o and tonumber(o.Value) or 0
        else
            local o = ps:FindFirstChild("Melee") or ps:FindFirstChild("melee")
            return o and tonumber(o.Value) or 0
        end
    end

    local function isSkillReadyToCast(cat: string, key: string, tool: Tool?): boolean
        local prefix = getSkillPrefix(cat)
        local myStat = getPlayerStatForCategory(cat)

        -- 1. Kiểm tra thẳng chỉ số mở khóa từ SkillData (ZRequire, XRequire, CRequire, VRequire, ERequire)
        if tool then
            local sData = getSkillDataTable(tool.Name, cat)
            if typeof(sData) == "table" then
                local req = tonumber(sData[key .. "Require"])
                if req and myStat < req then
                    return false
                end
            end
        end

        -- 2. Kiểm tra hồi chiêu trong _G.Cooldowns
        if typeof(_G.Cooldowns) == "table" then
            local cdVal = _G.Cooldowns[prefix .. key]
            if cdVal == true or (typeof(cdVal) == "number" and cdVal > 0) then
                return false
            end
        end

        -- 3. Kiểm tra giao diện SkillCooldown (Locked & SkillsRequire [số])
        local pgui = player:FindFirstChild("PlayerGui")
        local scGui = pgui and pgui:FindFirstChild("SkillCooldown")
        local frame = scGui and scGui:FindFirstChild(prefix .. "Frame")
        local slot = frame and frame:FindFirstChild(key)
        if slot then
            local locked = slot:FindFirstChild("Locked", true)
            if locked and locked:IsA("GuiObject") and locked.Visible then
                return false
            end
            local reqLbl = slot:FindFirstChild("SkillsRequire", true)
            if reqLbl and reqLbl:IsA("TextLabel") then
                local reqNum = tonumber(string.match(reqLbl.Text or "", "%d+"))
                if reqNum and reqNum > 0 and myStat < reqNum then
                    return false
                end
            end
            local cdObj = slot:FindFirstChild("Cooldown") or slot:FindFirstChild("CD")
            if cdObj and cdObj:IsA("GuiObject") and cdObj.Visible then
                if cdObj:IsA("TextLabel") then
                    local num = tonumber(string.match(cdObj.Text, "%d+"))
                    if num and num > 0 then return false end
                elseif cdObj.Size.Y.Scale > 0.08 or cdObj.Size.X.Scale > 0.08 then
                    return false
                end
            end
        end
        return true
    end

    local INSTANT_TAP_KEYWORDS = {
        "fly", "flight", "dash", "teleport", "tele", "portal", "blink", "flash", "step",
        "buff", "heal", "shield", "barrier", "counter", "transform", "awaken", "gear",
        "mode", "form", "room", "domain", "summon", "clone", "mirror", "coat", "aura",
    }
    local HOLD_SKILL_KEYWORDS = {
        "beam", "laser", "ray", "barrage", "gatling", "flurry", "storm", "rain", "hail",
        "cannon", "breath", "roar", "blast", "meteor", "tsunami", "tempest", "vortex",
        "hurricane", "tornado", "charge", "hold", "eruption", "supernova", "nova",
        "comet", "black hole", "quake", "inferno", "flamethrower", "wave", "overload",
    }

    local function getOptimalSkillHoldTime(tool: Tool, cat: string, key: string): number
        if hubState.smartSkillHold == false or genv.SmartSkillHold == false then
            return 0.04
        end
        -- Phím E thường là chiêu di chuyển / bay / buff -> luôn nhấn nhả nhanh
        if key == "E" then
            return 0.04
        end

        local prefix = getSkillPrefix(cat)
        local skillDisplayName = ""
        pcall(function()
            local pgui = player:FindFirstChild("PlayerGui")
            local scGui = pgui and pgui:FindFirstChild("SkillCooldown")
            local frame = scGui and scGui:FindFirstChild(prefix .. "Frame")
            local slot = frame and frame:FindFirstChild(key)
            local nameLbl = slot and (slot:FindFirstChild("SkillsNames") or slot:FindFirstChild("SkillName"))
            if nameLbl and nameLbl:IsA("TextLabel") then
                skillDisplayName = string.lower(nameLbl.Text or "")
            end
        end)

        -- 1. Kiểm tra từ khóa nhấn nhanh (di chuyển, buff, biến hình)
        if skillDisplayName ~= "" then
            for _, kw in ipairs(INSTANT_TAP_KEYWORDS) do
                if string.find(skillDisplayName, kw, 1, true) then
                    return 0.04
                end
            end
            -- 2. Kiểm tra từ khóa chiêu đè / tụ lực / tia laser / xả đạn liên hoàn
            for _, kw in ipairs(HOLD_SKILL_KEYWORDS) do
                if string.find(skillDisplayName, kw, 1, true) then
                    return (key == "C" or key == "V") and 0.65 or 0.50
                end
            end
        end

        -- 3. Đọc trực tiếp bảng SkillData của King Legacy
        local sData = getSkillDataTable(tool.Name, cat)
        if typeof(sData) == "table" then
            local entry = sData[key] or sData[prefix .. key]
            if typeof(entry) == "table" then
                if entry.Instant == true or entry.Tap == true or entry.IsFlight == true then
                    return 0.04
                end
                local maxH = tonumber(entry.MaxHold or entry.HoldTime or entry.ChargeTime or entry.ChannelTime)
                if maxH and maxH > 0.15 then
                    return math.clamp(maxH * 0.65, 0.35, 0.68)
                end
                if entry.Hold == true or entry.CanHold == true or entry.Channel == true or entry.Charge == true then
                    return 0.55
                end
            end
        end

        -- 4. Kiểm tra hook Deactive() trong ClientSkillHandler (cơ chế đè chiêu chuẩn King Legacy)
        local modTbl = getClientSkillModule(tool.Name, cat)
        if modTbl and typeof(modTbl.Deactive) == "function" then
            if key == "C" or key == "V" then
                return 0.52
            elseif key == "Z" or key == "X" then
                return 0.38
            end
        end

        return 0.04
    end

    local function parseKeysFromOption(opt: any, fallbackList: { string }?): { string }
        local res = {}
        local function addUnique(k: string)
            for _, ek in ipairs(res) do
                if ek == k then return end
            end
            table.insert(res, k)
        end
        if typeof(opt) == "table" then
            for _, item in ipairs(opt) do
                if typeof(item) == "string" then
                    for _, k in ipairs({ "Z", "X", "C", "V", "E" }) do
                        if string.find(string.upper(item), k) then
                            addUnique(k)
                        end
                    end
                end
            end
        elseif typeof(opt) == "string" and opt ~= "" then
            if opt == "Chỉ Phím Z" then addUnique("Z")
            elseif opt == "Chỉ Phím X" then addUnique("X")
            else
                if string.find(opt, "Z") then addUnique("Z") end
                if string.find(opt, "X") then addUnique("X") end
                if string.find(opt, "C") then addUnique("C") end
                if string.find(opt, "V") then addUnique("V") end
                if string.find(opt, "E") then addUnique("E") end
            end
        end
        if #res == 0 and typeof(fallbackList) == "table" then
            for _, k in ipairs(fallbackList) do
                addUnique(k)
            end
        end
        return res
    end

    local lastHakiClock = 0
    local isCastingSkills = false

    local function castConfiguredSkills(char: Model, hum: Humanoid, targetModel: Model?)
        if os.clock() < dodgeUntilClock then return end
        if targetModel then
            setCurrentCombatTarget(targetModel)
        end

        -- 1. Tự bật Haki Vũ Trang (Armament) & Quan Sát (Ken) chuẩn King Legacy
        if hubState.autoHaki and (os.clock() - lastHakiClock) >= 6.0 then
            lastHakiClock = os.clock()
            pcall(function()
                genv.haki = true
                genv.hakivutrangv2 = true
                local chest = sharedRS:FindFirstChild("Chest")
                local rem = chest and chest:FindFirstChild("Remotes")
                local evts = rem and rem:FindFirstChild("Events")
                local funcs = rem and rem:FindFirstChild("Functions")
                if evts and evts:FindFirstChild("Armament") then
                    local hakiOn = (char:GetAttribute("Armament") == true) or (char:FindFirstChild("Haki") ~= nil) or (char:FindFirstChild("Armament") ~= nil)
                    if not hakiOn then
                        evts.Armament:FireServer()
                    end
                end
                if (hubState.autoKenHaki ~= false) and funcs and funcs:FindFirstChild("KenEvent") then
                    genv.hakiquansatv2 = true
                    local kenOn = (char:GetAttribute("Ken") == true) or (player:GetAttribute("Ken") == true)
                    if not kenOn then
                        pcall(function() funcs.KenEvent:InvokeServer(true) end)
                    end
                end
            end)
        end

        -- 2. Đánh M1 tốc độ cao chuẩn vũ khí đang dùng (Fruit / Sword / Melee)
        if not isHoldingSkill then
            equipAndFireSelectedM1(char, hum)
        end

        -- 3. Xả chiêu thông minh BẤT ĐỒNG BỘ (không làm khựng vòng bay Hover Lock, chỉ dùng đúng nút người dùng bật!)
        if not hubState.autoSkills or isCastingSkills then return end

        local m1Cats = getActiveM1Categories()
        local curHeldTool = char:FindFirstChildOfClass("Tool")
        local mode = hubState.toolMode or "Auto Mode"
        local primaryCat = (mode == "Sword" and "sword") or (mode == "Melee" and "melee") or (mode == "Fruit" and "fruit")
            or (#m1Cats == 1 and m1Cats[1]) or (curHeldTool and classifyKingLegacyTool(curHeldTool)) or "fruit"

        local catPlan: { { cat: string, keys: { string }, prio: number } } = {}
        local function addPlan(cat: string, opt: any, fb: { string }?, defKeys: { string })
            local kList = parseKeysFromOption(opt, fb)
            if #kList == 0 then kList = defKeys end
            table.insert(catPlan, { cat = cat, keys = kList, prio = (cat == primaryCat and 2 or 1) })
        end
        if hubState.skillFruit then
            local fOpt = (typeof(hubState.fruitSkillsList) == "table" and #hubState.fruitSkillsList > 0) and hubState.fruitSkillsList or hubState.skillFruitKeys
            addPlan("fruit", fOpt, genv.CombatSkillFruit, { "Z", "X", "C", "E" })
        end
        if hubState.skillSword then
            local sOpt = (typeof(hubState.swordSkillsList) == "table" and #hubState.swordSkillsList > 0) and hubState.swordSkillsList or hubState.skillSwordKeys
            addPlan("sword", sOpt, genv.CombatSkillSword, { "Z", "X" })
        end
        if hubState.skillMelee then
            local mOpt = (typeof(hubState.meleeSkillsList) == "table" and #hubState.meleeSkillsList > 0) and hubState.meleeSkillsList or hubState.skillMeleeKeys
            addPlan("melee", mOpt, genv.CombatSkillMelee, { "Z", "X", "C", "V" })
        end
        if #catPlan == 0 then return end
        table.sort(catPlan, function(a, b) return a.prio > b.prio end)

        isCastingSkills = true
        task.spawn(function()
            local okCast, _ = pcall(function()
                local castsDone = 0
                local maxCastsPerTick = 2
                local switchedAway = false

                for _, plan in ipairs(catPlan) do
                    if castsDone >= maxCastsPerTick or os.clock() < dodgeUntilClock then break end
                    if targetModel and not isModelAlive(targetModel) then break end
                    local tool = findToolByCategory(plan.cat)
                    if tool then
                        for _, k in ipairs(plan.keys) do
                            if castsDone >= maxCastsPerTick or os.clock() < dodgeUntilClock then break end
                            if targetModel and not isModelAlive(targetModel) then break end
                            if isSkillReadyToCast(plan.cat, k, tool) then
                                local keyEnum = (Enum.KeyCode :: any)[k]
                                if keyEnum and sharedVim then
                                    if tool.Parent == player.Backpack then
                                        hum:EquipTool(tool)
                                        if plan.cat ~= primaryCat then switchedAway = true end
                                        task.wait(0.04)
                                    end
                                    local tModel, tRoot = targetModel, getModelRoot(targetModel)
                                    if not (tModel and tRoot) then
                                        tModel, tRoot = getBestCombatTarget(450)
                                    end
                                    if tModel and tRoot then
                                        _G.MouseHit = CFrame.new(getAimPoint(tModel, tRoot))
                                    end

                                    local holdDur = getOptimalSkillHoldTime(tool, plan.cat, k)
                                    lastPlayerSkillCastClock = os.clock()
                                    pcall(function()
                                        sharedVim:SendKeyEvent(true, keyEnum, false, game)
                                        if holdDur > 0.12 then
                                            isHoldingSkill = true
                                            local held = 0
                                            while held < holdDur and genv._YokaHubToken == myToken and os.clock() >= dodgeUntilClock do
                                                if hum.Health <= 0 then break end
                                                if targetModel and not isModelAlive(targetModel) then break end
                                                if tModel and tRoot and tRoot.Parent then
                                                    _G.MouseHit = CFrame.new(getAimPoint(tModel, tRoot))
                                                end
                                                local slice = math.min(0.04, holdDur - held)
                                                task.wait(slice)
                                                held += slice
                                            end
                                            isHoldingSkill = false
                                        else
                                            task.wait(holdDur)
                                        end
                                        sharedVim:SendKeyEvent(false, keyEnum, false, game)
                                    end)
                                    castsDone += 1
                                    task.wait(0.04)
                                end
                            end
                        end
                    end
                end

                -- Trả lại ngay vũ khí chính để M1 đánh liên hoàn không gián đoạn
                if switchedAway and #m1Cats == 1 then
                    local mainTool = findToolByCategory(primaryCat)
                    if mainTool and mainTool.Parent == player.Backpack then
                        pcall(function() hum:EquipTool(mainTool) end)
                    end
                end
            end)
            isHoldingSkill = false
            isCastingSkills = false
        end)
    end

    -- ========================================================
    -- [AUTO FIGHT BOSS WORKER] - LUỒNG CHIẾN ĐẤU SEA EVENT, BOSS ĐẢO & NHẶT RƯƠNG BOSS
    -- ========================================================
    local function isIslandWanted(n: string, soloKey: string?, mode: string?): boolean
        if soloKey and soloKey ~= "" then
            if soloKey == "dragon" then
                return (string.find(n, "dragon", 1, true) ~= nil or string.find(n, "drakenfyr", 1, true) ~= nil or string.find(n, "inferno", 1, true) ~= nil)
                    and string.find(n, "abyssal", 1, true) == nil and string.find(n, "depth", 1, true) == nil
            elseif soloKey == "depth_king" then
                return (string.find(n, "depth", 1, true) ~= nil) and string.find(n, "abyssal", 1, true) == nil
            elseif soloKey == "abyssal_tyrant" then
                return string.find(n, "abyssal", 1, true) ~= nil
            elseif soloKey == "kraken" then
                return string.find(n, "kraken", 1, true) ~= nil or string.find(n, "tentacle", 1, true) ~= nil
            elseif soloKey == "crab" then
                return string.find(n, "crab", 1, true) ~= nil
            elseif soloKey == "sea3_events" then
                if string.find(n, "depth", 1, true) ~= nil or string.find(n, "abyssal", 1, true) ~= nil then return false end
                return string.find(n, "kraken", 1, true) ~= nil or string.find(n, "crab", 1, true) ~= nil or string.find(n, "sea", 1, true) ~= nil
            elseif soloKey == "hydra" then
                return string.find(n, "hydra", 1, true) ~= nil
            elseif soloKey == "sea_king" then
                return string.find(n, "legacy", 1, true) ~= nil or string.find(n, "sea island", 1, true) ~= nil or string.find(n, "sea king", 1, true) ~= nil
            elseif soloKey == "ghost_ship" then
                return string.find(n, "ghost", 1, true) ~= nil
            elseif soloKey == "serpent" then
                return string.find(n, "serpent", 1, true) ~= nil
            end
        end
        if mode == "sea3" then
            if hubState.fightSea3DepthKing ~= false and (string.find(n, "depth", 1, true) ~= nil and string.find(n, "abyssal", 1, true) == nil) then return true end
            if hubState.fightSea3Dragon ~= false and (string.find(n, "dragon", 1, true) ~= nil or string.find(n, "drakenfyr", 1, true) ~= nil) then return true end
            if hubState.fightSea3Abyssal ~= false and string.find(n, "abyssal", 1, true) ~= nil then return true end
            if hubState.fightSea3Kraken ~= false and string.find(n, "kraken", 1, true) ~= nil then return true end
            if hubState.fightSea3Crab ~= false and string.find(n, "crab", 1, true) ~= nil then return true end
            if hubState.fightSea3Events == true and (string.find(n, "sea", 1, true) ~= nil or string.find(n, "galleon", 1, true) ~= nil) then return true end
            return false
        elseif mode == "sea2" then
            if hubState.fightSea2Hydra ~= false and string.find(n, "hydra", 1, true) ~= nil then return true end
            if hubState.fightSea2SeaKing ~= false and (string.find(n, "legacy", 1, true) ~= nil or string.find(n, "sea island", 1, true) ~= nil or string.find(n, "sea king", 1, true) ~= nil) then return true end
            if hubState.fightSea2GhostShip ~= false and string.find(n, "ghost", 1, true) ~= nil then return true end
            return false
        end
        return false
    end

    local function findSeaEventIslandPos(soloKey: string?, mode: string?): (Vector3?, string?)
        -- 1. Kiểm tra trực tiếp tọa độ sự kiện biển từ Wukong SeaEvent API nếu có
        if typeof(genv.WK_SeaEvent) == "table" and typeof(genv.WK_SeaEvent.GetState) == "function" then
            local okS, st = pcall(genv.WK_SeaEvent.GetState)
            if okS and typeof(st) == "table" and st.phase and st.phase ~= "inactive" then
                local ek = string.lower(tostring(st.eventKey or ""))
                if isIslandWanted(ek, soloKey, mode) then
                    local rawPos = st.position or st.targetPos or (typeof(st.cframe) == "CFrame" and st.cframe.Position)
                    if typeof(rawPos) == "Vector3" then
                        return rawPos, tostring(st.eventKey or "SeaEvent")
                    end
                end
            end
        end
        -- 2. Quét các đảo sự kiện tương ứng với mục tiêu đang săn
        local isl = workspace:FindFirstChild("Island")
        if isl then
            for _, c in ipairs(isl:GetChildren()) do
                local n = string.lower(c.Name)
                if isIslandWanted(n, soloKey, mode) then
                    local okB, cf = pcall(function() return c:IsA("Model") and c:GetBoundingBox() or (c:IsA("BasePart") and c.CFrame or nil) end)
                    if okB and typeof(cf) == "CFrame" then
                        return cf.Position, c.Name
                    end
                end
            end
        end
        -- 3. Quét trực tiếp các vật thể GhostShip / SeaEvent trong workspace
        for _, obj in ipairs(workspace:GetChildren()) do
            local n = string.lower(obj.Name)
            if (obj:IsA("Model") or obj:IsA("Folder")) and isIslandWanted(n, soloKey, mode) then
                local okB, cf = pcall(function() return obj:IsA("Model") and obj:GetBoundingBox() or nil end)
                if okB and typeof(cf) == "CFrame" then
                    return cf.Position, obj.Name
                end
            end
        end
        return nil, nil
    end

    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(0.16)
            local busyOtherMode = hubState.autoFish
                or (currentMode == "off" and (hubState.autoLevel or hubState.autoKillSelectedMob or hubState.autoDungeon or hubState.farmSea3Mat or hubState.farmSea2Mat or hubState.farmSea1Mat))
            local bossFightActive = (currentMode ~= "off") or hubState.autoFightMaster or hubState.autoFightIslandBoss
            if bossFightActive and not busyOtherMode and genv._YokaHubToken == myToken then
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                    local hrp = char.HumanoidRootPart
                    local hum = char.Humanoid
                    if hum.Health <= 0 then return end
                    if os.clock() < dodgeUntilClock then return end

                    -- 1. Quét tìm rương báu Boss / Sea Event không giới hạn tầm (Streaming-safe, bay lơ lửng tới nhặt không rơi xuống biển)
                    if hubState.autoCollectChest ~= false then
                        local foundChestTarget: BasePart? = nil
                        local foundChestPrompt: ProximityPrompt? = nil

                        local function inspectChestModel(m: Instance): boolean
                            if m:IsA("Model") and string.find(string.lower(m.Name), "chest", 1, true) and not string.find(string.lower(m.Name), "spawner", 1, true) then
                                local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                                if pp then
                                    foundChestTarget = pp
                                    foundChestPrompt = m:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    return true
                                end
                            end
                            return false
                        end

                        -- Quét trong workspace.Island
                        local isl = workspace:FindFirstChild("Island")
                        if isl then
                            for _, c in ipairs(isl:GetChildren()) do
                                local cn = string.lower(c.Name)
                                local isEventIsl = string.find(cn, "hydra", 1, true) or string.find(cn, "legacy", 1, true) or string.find(cn, "sea", 1, true) or string.find(cn, "ghost", 1, true) or string.find(cn, "event", 1, true) or string.find(cn, "depth", 1, true)
                                if isEventIsl or currentMode == "off" then
                                    for _, d in ipairs(c:GetDescendants()) do
                                        if inspectChestModel(d) then break end
                                    end
                                    if foundChestTarget then break end
                                end
                            end
                        end

                        -- Quét bổ sung trực tiếp ngoài workspace và SeaMonster
                        if not foundChestTarget then
                            for _, obj in ipairs(workspace:GetChildren()) do
                                if inspectChestModel(obj) then break end
                            end
                        end
                        if not foundChestTarget then
                            local sm = workspace:FindFirstChild("SeaMonster")
                            if sm then
                                for _, obj in ipairs(sm:GetChildren()) do
                                    if inspectChestModel(obj) then break end
                                end
                            end
                        end

                        if foundChestTarget then
                            local chestPos = foundChestTarget.Position + Vector3.new(0, 4, 0)
                            setFlightTarget(chestPos, foundChestTarget.Position, (foundChestTarget.Position - hrp.Position).Magnitude > 1400, 60)
                            if foundChestPrompt and (foundChestTarget.Position - hrp.Position).Magnitude <= 20 and typeof(fireproximityprompt) == "function" then
                                pcall(fireproximityprompt, foundChestPrompt)
                            end
                            return
                        end
                    end

                    -- 2. Quét Boss Đảo nếu bật autoFightIslandBoss, hoặc Boss Biển / Sea Event nếu bật autoFightMaster hoặc đang ở chế độ Hop Boss
                    local islandKeyword = ""
                    local islandExact = ""
                    if hubState.autoFightIslandBoss and hubState.islandBossTarget then
                        islandExact = hubState.islandBossTarget
                        local rawIsl = string.match(hubState.islandBossTarget, "^([^(%[]+)") or hubState.islandBossTarget
                        rawIsl = string.gsub(rawIsl, "%s+[Bb]oss%s*$", "")
                        islandKeyword = string.lower(string.gsub(rawIsl, "%s+$", ""))
                        -- Tự nhận đúng Quest Boss Đảo chuẩn King Legacy nếu bật Auto Take Boss Quest
                        if hubState.autoTakeBossQuest and islandKeyword ~= "" then
                            local curQ = player:FindFirstChild("CurrentQuest")
                            local curQVal = curQ and tostring(curQ.Value) or ""
                            local hasMyQuest = curQVal ~= "" and curQVal ~= "None" and (string.find(string.lower(curQVal), islandKeyword, 1, true) ~= nil or (islandExact ~= "" and string.find(curQVal, islandExact, 1, true) ~= nil))
                            if not hasMyQuest then
                                pcall(function()
                                    local chest = sharedRS:FindFirstChild("Chest")
                                    local qmMod = chest and chest:FindFirstChild("Modules") and chest.Modules:FindFirstChild("QuestManager")
                                    local qRem = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions") and chest.Remotes.Functions:FindFirstChild("Quest")
                                    if qmMod and qRem then
                                        local okQ, qTbl = pcall(require, qmMod)
                                        if okQ and typeof(qTbl) == "table" then
                                            for qName, qInfo in pairs(qTbl) do
                                                if typeof(qName) == "string" and typeof(qInfo) == "table" and not qInfo.DailyQuest then
                                                    local mobLow = string.lower(tostring(qInfo.Mob or ""))
                                                    if tostring(qInfo.Mob or "") == islandExact or string.find(mobLow, islandKeyword, 1, true) or string.find(string.lower(qName), islandKeyword, 1, true) then
                                                        if curQVal ~= "" and curQVal ~= "None" then
                                                            pcall(function() qRem:InvokeServer("abandon") end)
                                                        end
                                                        qRem:InvokeServer("take", qName)
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end)
                            end
                        end
                    end

                    local soloKeyActive = (currentMode == "solo") and getSoloKey(currentSoloTarget) or ""
                    local function isBossWanted(rawName: string, folderName: string?): boolean
                        local n = string.lower(rawName)
                        if hubState.autoFightIslandBoss and (rawName == islandExact or (islandKeyword ~= "" and string.find(n, islandKeyword, 1, true) ~= nil)) then
                            return true
                        end
                        -- Nếu đang ở chế độ Săn Riêng / Sea 2 / Sea 3: luôn đánh đúng Boss của chế độ đó!
                        if currentMode == "solo" then
                            if soloKeyActive == "depth_king" then return isDepthKingBoss(n) end
                            if soloKeyActive == "abyssal_tyrant" then return isAbyssalBoss(n) end
                            if soloKeyActive == "dragon" then return isDragonBoss(n) end
                            if soloKeyActive == "kraken" then return isKrakenBoss(n) end
                            if soloKeyActive == "crab" then return isCrabBoss(n) end
                            if soloKeyActive == "hydra" then return string.find(n, "hydra", 1, true) ~= nil and not isIslandMobName(n) end
                            if soloKeyActive == "sea_king" then return (string.find(n, "sea king", 1, true) ~= nil or string.find(n, "seaking", 1, true) ~= nil) and not isIslandMobName(n) end
                            if soloKeyActive == "ghost_ship" then return string.find(n, "ghost", 1, true) ~= nil and not isIslandMobName(n) end
                            if soloKeyActive == "serpent" then return isSerpentBoss(n) end
                            if soloKeyActive == "sea3_events" then
                                if isDepthKingBoss(n) or isAbyssalBoss(n) or isIslandMobName(n) then return false end
                                return isKrakenBoss(n) or isCrabBoss(n) or isDragonBoss(n) or isSerpentBoss(n) or isSeaEventMiscBoss(n) or (folderName == "SeaMonster" and not isIslandMobName(n))
                            end
                        elseif currentMode == "sea2" then
                            return isSea2BossEnabled(rawName)
                        elseif currentMode == "sea3" then
                            return isSea3BossEnabled(rawName)
                        end
                        if not hubState.autoFightMaster then
                            return false
                        end
                        return isSea3BossEnabled(rawName) or isSea2BossEnabled(rawName)
                    end

                    -- Quét trong SeaMonster, GhostMonster, Monster & Monster.Boss
                    local targetBoss: Model? = nil
                    local bestBossDist = 1e9
                    local folders
                    if currentMode == "solo" or currentMode == "sea3" then
                        folders = {}
                        local sm = workspace:FindFirstChild("SeaMonster")
                        if sm then table.insert(folders, sm) end
                        local gm = workspace:FindFirstChild("GhostMonster")
                        if gm then table.insert(folders, gm) end
                        local mon = workspace:FindFirstChild("Monster")
                        local bossF = mon and mon:FindFirstChild("Boss")
                        if bossF then table.insert(folders, bossF) end
                        if hubState.autoFightIslandBoss and mon then
                            table.insert(folders, mon)
                        end
                    else
                        folders = getAliveMobFolders(true, true, false)
                    end
                    for _, fld in ipairs(folders) do
                        for _, m in ipairs(fld:GetChildren()) do
                            if m:IsA("Model") and isBossWanted(m.Name, fld.Name) then
                                local bHum = m:FindFirstChildOfClass("Humanoid")
                                local bRoot = getModelRoot(m)
                                if bHum and bHum.Health > 0 and bRoot then
                                    local d = (bRoot.Position - hrp.Position).Magnitude
                                    if d < bestBossDist then
                                        bestBossDist = d
                                        targetBoss = m
                                    end
                                end
                            end
                        end
                    end

                    -- Nếu tìm thấy Boss hợp lệ: Bay + Hover Lock trên đầu Boss, Auto Aim & Xả chiêu thông minh
                    if targetBoss then
                        local bRoot = getModelRoot(targetBoss)
                        if bRoot then
                            setCurrentCombatTarget(targetBoss)
                            local sHeight = math.clamp(tonumber(hubState.bossSafeHeight) or 18, 8, 50)
                            local aimPos = getAimPoint(targetBoss, bRoot)
                            local hoverPos = bRoot.Position + Vector3.new(0, sHeight, 0)
                            setFlightTarget(hoverPos, aimPos, (hoverPos - hrp.Position).Magnitude > 1600, 55)
                            if (hrp.Position - hoverPos).Magnitude <= 50 then
                                castConfiguredSkills(char, hum, targetBoss)
                            end
                            pcall(function()
                                genv.autoskillsea = true
                            end)
                        end
                    elseif hubState.autoFightIslandBoss and hubState.islandBossTarget then
                        -- StreamingEnabled fix cho Boss Đảo: Nếu Boss chưa load quanh nhân vật -> quét vị trí Spawner/Boss trong Monster.Boss hoặc AllNPC để bay tới
                        local bossPos: Vector3? = nil
                        local monB = workspace:FindFirstChild("Monster") and workspace.Monster:FindFirstChild("Boss")
                        if monB then
                            for _, b in ipairs(monB:GetChildren()) do
                                if b.Name == islandExact or (islandKeyword ~= "" and string.find(string.lower(b.Name), islandKeyword, 1, true) ~= nil) then
                                    local root = getModelRoot(b)
                                    if root then bossPos = root.Position; break end
                                end
                            end
                        end
                        if not bossPos then
                            local allNpc = workspace:FindFirstChild("AllNPC")
                            if allNpc then
                                for _, n in ipairs(allNpc:GetChildren()) do
                                    if islandKeyword ~= "" and string.find(string.lower(n.Name), islandKeyword, 1, true) ~= nil then
                                        local root = n:IsA("BasePart") and n or (n:FindFirstChild("HumanoidRootPart") or n:FindFirstChildWhichIsA("BasePart"))
                                        if root then bossPos = root.Position; break end
                                    end
                                end
                            end
                        end
                        if bossPos and (bossPos - hrp.Position).Magnitude > 60 then
                            local sHeight = math.clamp(tonumber(hubState.bossSafeHeight) or 18, 8, 50)
                            local flyPos = bossPos + Vector3.new(0, sHeight, 0)
                            setFlightTarget(flyPos, bossPos, (bossPos - hrp.Position).Magnitude > 1400, 52)
                        end
                    elseif currentMode ~= "off" or hubState.autoFightMaster then
                        -- StreamingEnabled fix: Nếu SeaMonster chưa load do ở quá xa -> bay tới thẳng Đảo Sự Kiện (Hydra / Sea Island / Legacy / Ghost Ship) để nạp Boss!
                        local evPos, _ = findSeaEventIslandPos(soloKeyActive, currentMode)
                        if evPos and (evPos - hrp.Position).Magnitude > 120 then
                            local flyPos = evPos + Vector3.new(0, 65, 0)
                            setFlightTarget(flyPos, evPos, (flyPos - hrp.Position).Magnitude > 1400, 54)
                        end
                    end
                end)
            end
        end
    end)

    -- ========================================================
    -- [AUTO CLICK PLAY] - TU DONG NHAN PLAY KHI LOAD XONG / HOP SERVER
    -- ========================================================
    task.spawn(function()
        triggerKingLegacyAutoPlay(function()
            return hubState.autoClickPlay ~= false and genv._YokaHubToken == myToken
        end)
        while genv._YokaHubToken == myToken do
            task.wait(1.5)
            if hubState.autoClickPlay ~= false then
                local pgui = player:FindFirstChild("PlayerGui")
                local loadingGui = pgui and pgui:FindFirstChild("LoadingGUI")
                if player:GetAttribute("Playing") ~= true or loadingGui then
                    triggerKingLegacyAutoPlay(function()
                        return hubState.autoClickPlay ~= false and genv._YokaHubToken == myToken
                    end)
                    task.wait(3.0)
                end
            end
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

    local function getSlotTier(e: any): number
        local pCur = typeof(e.players) == "table" and (tonumber(e.players.current) or 99) or 99
        local pMax = typeof(e.players) == "table" and (tonumber(e.players.max) or 12) or 12
        local free = pMax - pCur
        if pCur >= 4 and pCur <= 8 and free >= 3 then return 4 end
        if free >= 2 then return 3 end
        if free >= 1 then return 1 end
        return 0
    end

    local function getSea3Prio(e: any): number
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))

        -- Top 1: Depth King (Sea 3) - Ưu tiên cao nhất (10 điểm)
        if (src == "depth_king" or string.find(nm, "depth king", 1, true) ~= nil or nm == "depthking" or (string.find(nm, "depth", 1, true) ~= nil and string.find(nm, "king", 1, true) ~= nil)) and string.find(nm, "abyssal", 1, true) == nil then
            if hubState.fightSea3DepthKing == false then return 0 end
            return 10
        end

        -- Top 2: Drakenfyr the Inferno King / Dragon / Sea Dragon (Sea 3) - Ưu tiên số 2 (8 điểm)
        if (string.find(nm, "drakenfyr", 1, true) ~= nil or string.find(nm, "inferno king", 1, true) ~= nil or string.find(nm, "sea dragon", 1, true) ~= nil or (src == "sea_event" and string.find(nm, "dragon", 1, true) ~= nil)) and string.find(nm, "abyssal", 1, true) == nil and string.find(nm, "depth", 1, true) == nil and string.find(nm, "tyrant", 1, true) == nil then
            if hubState.fightSea3Dragon == false then return 0 end
            return 8
        end

        -- Top 3: Abyssal Tyrant (Sea 3) - Ưu tiên số 3 (6 điểm)
        if (string.find(nm, "abyssal tyrant", 1, true) ~= nil or nm == "abyssaltyrant" or (string.find(nm, "abyssal", 1, true) ~= nil and string.find(nm, "tyrant", 1, true) ~= nil)) and string.find(nm, "depth", 1, true) == nil then
            if hubState.fightSea3Abyssal == false then return 0 end
            return 6
        end

        -- Top 4: Kraken & Xúc Tu (Sea 3) - Ưu tiên số 4 (4 điểm)
        if src == "sea_event" and (string.find(nm, "kraken", 1, true) ~= nil or string.find(nm, "tentacle", 1, true) ~= nil) then
            if hubState.fightSea3Kraken == false then return 0 end
            return 4
        end

        -- Top 5: Cua Biển Khổng Lồ (Giant Crab Sea 3) - Ưu tiên số 5 (3 điểm)
        if string.find(nm, "crab", 1, true) ~= nil then
            if hubState.fightSea3Crab == false then return 0 end
            return 3
        end

        -- Top 6: Rắn Biển / Serpent (Sea 3 & 2) - Ưu tiên số 6 (2 điểm)
        if src == "serpent" or string.find(nm, "serpent", 1, true) ~= nil then
            if hubState.fightSea2Serpent == false then return 0 end
            return 2
        end

        -- Tuyệt đối không để Depth King, Dragon hoặc Abyssal bị người dùng tắt mà lại lọt qua Top 7
        local isDkRoom = (src == "depth_king" or string.find(nm, "depth", 1, true) ~= nil)
        local isAbRoom = (string.find(nm, "abyssal", 1, true) ~= nil or string.find(nm, "tyrant", 1, true) ~= nil)
        local isDgRoom = (string.find(nm, "drakenfyr", 1, true) ~= nil or string.find(nm, "inferno king", 1, true) ~= nil or string.find(nm, "sea dragon", 1, true) ~= nil or (src == "sea_event" and string.find(nm, "dragon", 1, true) ~= nil))
        if isDkRoom and hubState.fightSea3DepthKing == false then return 0 end
        if isAbRoom and hubState.fightSea3Abyssal == false then return 0 end
        if isDgRoom and hubState.fightSea3Dragon == false then return 0 end

        -- Top 7: Sea Events Thường & Tàu Galleon Boss (1 điểm - CHỈ khi người dùng bật toggle Sea Event Thường)
        if src == "sea_event" or src == "ship_ability" or string.find(nm, "sea beast", 1, true) ~= nil or string.find(nm, "galleon", 1, true) ~= nil then
            if hubState.fightSea3Events ~= true then return 0 end
            return 1
        end

        return 0
    end

    local function getSea2Prio(e: any): number
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))
        if (src == "sk_hd_chest" and string.find(nm, "hydra", 1, true) ~= nil) or src == "hydra" or string.find(nm, "hydra", 1, true) ~= nil then
            if hubState.fightSea2Hydra == false then return 0 end
            return src == "sk_hd_chest" and 7 or 6
        end
        if (src == "sk_hd_chest" and (string.find(nm, "sea king", 1, true) ~= nil or string.find(nm, "seaking", 1, true) ~= nil)) or src == "sea_king" or string.find(nm, "sea king", 1, true) ~= nil or string.find(nm, "seaking", 1, true) ~= nil then
            if hubState.fightSea2SeaKing == false then return 0 end
            return src == "sk_hd_chest" and 5 or 4
        end
        if src == "serpent" or string.find(nm, "serpent", 1, true) ~= nil then
            if hubState.fightSea2Serpent == false then return 0 end
            return 3
        end
        if string.find(src, "ghost", 1, true) ~= nil or string.find(nm, "ghost", 1, true) ~= nil then
            if hubState.fightSea2GhostShip == false then return 0 end
            return string.find(nm, "chest", 1, true) ~= nil and 2 or 1
        end
        return 0
    end

    -- Helper cham diem cho tung che do SAN RIENG API (F7)
    local function getSoloApiPrio(e: any, soloKey: string): number
        local pid = tonumber(e.placeId)
        local src = string.lower(tostring(e.source or ""))
        local nm = string.lower(tostring(e.eventName or ""))
        if soloKey == "dragon" then
            if pid == SEA3_PLACE and (string.find(nm, "drakenfyr", 1, true) ~= nil or string.find(nm, "inferno king", 1, true) ~= nil or string.find(nm, "sea dragon", 1, true) ~= nil or (string.find(nm, "dragon", 1, true) ~= nil and string.find(nm, "fruit", 1, true) == nil and string.find(nm, "claw", 1, true) == nil and string.find(nm, "orb", 1, true) == nil)) then
                -- Tuyệt đối loại bỏ nếu tên phòng có chữ abyssal hoặc depth hoặc tyrant
                if string.find(nm, "abyssal", 1, true) == nil and string.find(nm, "tyrant", 1, true) == nil and string.find(nm, "depth", 1, true) == nil then
                    return (string.find(nm, "drakenfyr", 1, true) ~= nil or string.find(nm, "sea dragon", 1, true) ~= nil) and 2 or 1
                end
            end
        elseif soloKey == "abyssal_tyrant" then
            if pid == SEA3_PLACE and (string.find(nm, "abyssal tyrant", 1, true) ~= nil or nm == "abyssaltyrant" or (string.find(nm, "abyssal", 1, true) ~= nil and string.find(nm, "tyrant", 1, true) ~= nil)) then
                if string.find(nm, "dragon", 1, true) == nil and string.find(nm, "depth", 1, true) == nil then
                    return 2
                end
            end
        elseif soloKey == "depth_king" then
            if pid == SEA3_PLACE and (src == "depth_king" or string.find(nm, "depth king", 1, true) ~= nil or nm == "depthking" or (string.find(nm, "depth", 1, true) ~= nil and string.find(nm, "king", 1, true) ~= nil)) then
                if string.find(nm, "abyssal", 1, true) == nil and string.find(nm, "tyrant", 1, true) == nil then
                    return 2
                end
            end
        elseif soloKey == "kraken" then
            if pid == SEA3_PLACE and src == "sea_event" and (string.find(nm, "kraken", 1, true) ~= nil or string.find(nm, "tentacle", 1, true) ~= nil) then return 2 end
        elseif soloKey == "crab" then
            if pid == SEA3_PLACE and src == "sea_event" and string.find(nm, "crab", 1, true) ~= nil then return 2 end
        elseif soloKey == "sea3_events" then
            if pid == SEA3_PLACE and src == "sea_event" then
                -- Tuyệt đối loại bỏ Depth King & Abyssal Tyrant
                if string.find(nm, "depth", 1, true) ~= nil or string.find(nm, "abyssal", 1, true) ~= nil or string.find(nm, "tyrant", 1, true) ~= nil then
                    return 0
                end
                if string.find(nm, "sea dragon", 1, true) ~= nil or string.find(nm, "drakenfyr", 1, true) ~= nil then return 4 end
                if string.find(nm, "dragon", 1, true) ~= nil then return 3 end
                if string.find(nm, "kraken", 1, true) ~= nil then return 2 end
                if string.find(nm, "crab", 1, true) ~= nil then return 2 end
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
                    local isAbyssal = isAbyssalBoss(ek)
                    local isDk = isDepthKingBoss(ek)
                    local isDg = isDragonBoss(ek)
                    if soloKey == "abyssal_tyrant" and isAbyssal then return "boss", tostring(st.eventKey or "Abyssal Tyrant")
                    elseif soloKey == "depth_king" and isDk then return "boss", tostring(st.eventKey or "Depth King")
                    elseif soloKey == "dragon" and isDg then return "boss", tostring(st.eventKey or "Drakenfyr")
                    elseif soloKey == "kraken" and isKrakenBoss(ek) then return "boss", tostring(st.eventKey)
                    elseif soloKey == "crab" and isCrabBoss(ek) then return "boss", tostring(st.eventKey)
                    elseif soloKey == "sea3_events" and not isDk and not isAbyssal then return "boss", tostring(st.eventKey or st.phase)
                    end
                end
            end
            local sm = workspace:FindFirstChild("SeaMonster")
            if sm then
                for _, m in ipairs(sm:GetChildren()) do
                    local n = string.lower(m.Name)
                    local match = false
                    if soloKey == "abyssal_tyrant" then match = isAbyssalBoss(n)
                    elseif soloKey == "depth_king" then match = isDepthKingBoss(n)
                    elseif soloKey == "dragon" then match = isDragonBoss(n)
                    elseif soloKey == "kraken" then match = isKrakenBoss(n)
                    elseif soloKey == "crab" then match = isCrabBoss(n)
                    elseif soloKey == "sea3_events" then match = not isDepthKingBoss(n) and not isAbyssalBoss(n) and (isKrakenBoss(n) or isCrabBoss(n) or isDragonBoss(n) or isSerpentBoss(n) or isSeaEventMiscBoss(n))
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
                    if soloKey == "abyssal_tyrant" then match = isAbyssalBoss(n)
                    elseif soloKey == "depth_king" then match = isDepthKingBoss(n)
                    elseif soloKey == "dragon" then match = isDragonBoss(n)
                    elseif soloKey == "kraken" then match = isKrakenBoss(n)
                    elseif soloKey == "crab" then match = isCrabBoss(n)
                    elseif soloKey == "sea3_events" then match = not isDepthKingBoss(n) and not isAbyssalBoss(n) and (isKrakenBoss(n) or isCrabBoss(n) or isDragonBoss(n))
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
                local evName = tostring(st.eventKey or st.phase or "")
                if isSea3BossEnabled(evName) then
                    return true, evName
                end
            end
        end
        -- 1. Quet trong Workspace.SeaMonster (noi spawn Depth King / SeaDragon / Kraken / Crab / Serpent)
        local sm = workspace:FindFirstChild("SeaMonster")
        if sm then
            for _, m in ipairs(sm:GetChildren()) do
                if isSea3BossEnabled(m.Name) then
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
                if isSea3BossEnabled(m.Name) then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then return true, m.Name end
                end
            end
        end
        if genv.DepthKingChestWaitStarted == true and genv.DepthKingChestReadyToHop == false and hubState.fightSea3DepthKing ~= false then
            return true, "Đang mở rương Depth King"
        end
        if genv.SeaKingChestWaitStarted == true and genv.SeaKingChestReadyToHop == false and hubState.fightSea3Events == true then
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
                        if hum and hum.Health > 0 and isSea2BossEnabled(m.Name) then
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
                    if hum and hum.Health > 0 and isSea2BossEnabled(m.Name) then
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
        if (genv.HydraChestWaitStarted == true and hubState.fightSea2Hydra ~= false) or (genv.SeaKingChestWaitStarted == true and hubState.fightSea2SeaKing ~= false) then return "chest", "Rương Sea 2" end
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
                local chestAllowed = false
                if string.find(n, "hydra") and hubState.fightSea2Hydra ~= false then chestAllowed = true
                elseif (string.find(n, "sea king") or string.find(n, "sea island") or string.find(n, "legacy island")) and hubState.fightSea2SeaKing ~= false then chestAllowed = true
                elseif string.find(n, "ghost") and hubState.fightSea2GhostShip ~= false then chestAllowed = true
                end
                if chestAllowed then
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
            armAutoReexec(false)
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

    task.spawn(function()
    local prevSoloKey = ""
    while genv._YokaHubToken == myToken do
        local mode: string = hubState.mode or currentMode
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
                elseif soloKey == "dragon" or soloKey == "kraken" or soloKey == "crab" or soloKey == "sea3_events" then
                    genv.AutoDepthKing = false
                    genv.SeaEvent = true
                    genv.utienSeaEvent = true
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
            local preferSea3Boss = (hubState.fightSea3DepthKing ~= false and "depth")
                or (hubState.fightSea3Dragon ~= false and "dragon")
                or (hubState.fightSea3Abyssal ~= false and "abyssal")
                or (hubState.fightSea3Kraken ~= false and "kraken")
                or (hubState.fightSea3Crab ~= false and "crab")
                or "depth"
            if game.PlaceId ~= SEA3_PLACE then
                ensureCorrectSea(SEA3_PLACE, "Boss Sea 3", "Lệch Sea", preferSea3Boss)
                smartWait(15.0, "sea3")
                continue
            end
            pcall(function()
                genv.AutoDepthKing = (hubState.fightSea3DepthKing ~= false)
                genv.SeaEvent = (hubState.fightSea3Dragon ~= false or hubState.fightSea3Kraken ~= false or hubState.fightSea3Crab ~= false or hubState.fightSea3Events == true)
                genv.Serpent = (hubState.fightSea2Serpent ~= false)
                genv.utienSeaEvent = true
                genv.autoskillsea = true
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
        while genv._YokaHubToken == myToken do
            task.wait(1.5)
            if hubState.autoFish and currentMode == "off" then
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end

                    -- Tự động cầm cần câu hoặc kiếm câu cá
                    local rawWeapon = hubState.fishWeapon or "True Muramasa"
                    local weaponName = string.match(rawWeapon, "^([%w%s%']+)") or "True Muramasa"
                    weaponName = string.gsub(weaponName, "%s+$", "")
                    local tool = char:FindFirstChild(weaponName) or player.Backpack:FindFirstChild(weaponName)
                    if not tool then
                        for _, t in ipairs(player.Backpack:GetChildren()) do
                            if t:IsA("Tool") and (string.find(string.lower(t.Name), "rod") or string.find(string.lower(t.Name), "fish") or string.find(string.lower(t.Name), string.lower(weaponName))) then
                                tool = t
                                break
                            end
                        end
                    end
                    if tool and tool.Parent == player.Backpack then
                        char.Humanoid:EquipTool(tool)
                        task.wait(0.4)
                    end

                    -- Đứng trên mặt nước nếu bật Water Float (giữ độ cao ổn định trên bệ nổi YokaWaterPlatform)
                    if hubState.fishFloat then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp.Position.Y < 1 and hrp.Position.Y > -25 then
                            hrp.Velocity = Vector3.new(0, 0, 0)
                            hrp.CFrame = CFrame.new(hrp.Position.X, 4, hrp.Position.Z)
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
    -- [HELPER GOM QUÁI CẢ ĐẢO VỀ VỊ TRÍ NHÂN VẬT (FAST MOB BRING)]
    -- ========================================================
    local function getBringRangeStuds(): number
        return math.clamp(tonumber(hubState.mobBringRange or genv.MobBringRange) or 800, 100, 1200)
    end

    local lastGlobalBringClock = 0
    local mobLastBrought: { [Model]: number } = {}

    local function bringMobsToPosition(anchorPos: Vector3, maxRange: number, maxCount: number, filterName: string?, includeDungeon: boolean?, excludeMob: Model?)
        local now = os.clock()
        if (now - lastGlobalBringClock) < 0.8 then
            return
        end
        lastGlobalBringClock = now

        local mobFolders = getAliveMobFolders(false, false, includeDungeon == true)
        local brought = 0
        for _, fld in ipairs(mobFolders) do
            for _, otherMob in ipairs(fld:GetChildren()) do
                if brought >= maxCount then break end
                -- Tuyệt đối không can thiệp quái mục tiêu chính đang bị player trực tiếp đánh
                if otherMob:IsA("Model") and otherMob ~= excludeMob and (not filterName or otherMob.Name == filterName) then
                    local oRoot = getModelRoot(otherMob)
                    local oHum = otherMob:FindFirstChildOfClass("Humanoid")
                    if oRoot and oHum and oHum.Health > 0 then
                        local dist = (oRoot.Position - anchorPos).Magnitude
                        -- CHỈ GOM KHI QUÁI Ở XA (> 22 studs) - Tránh giật CFrame liên tục làm mất hit/mất sát thương
                        if dist > 22 and dist <= maxRange then
                            local lastB = mobLastBrought[otherMob] or 0
                            if (now - lastB) >= 3.0 then
                                mobLastBrought[otherMob] = now
                                pcall(function()
                                    for _, p in ipairs(otherMob:GetChildren()) do
                                        if p:IsA("BasePart") then
                                            p.CanCollide = false
                                            p.AssemblyLinearVelocity = Vector3.zero
                                            p.AssemblyAngularVelocity = Vector3.zero
                                        end
                                    end
                                    local angle = math.random() * math.pi * 2
                                    local rad = math.random(4, 9)
                                    local targetPos = Vector3.new(anchorPos.X + math.cos(angle) * rad, anchorPos.Y, anchorPos.Z + math.sin(angle) * rad)
                                    oRoot.CFrame = CFrame.new(targetPos)
                                end)
                                brought += 1
                            end
                        end
                    end
                end
            end
            if brought >= maxCount then break end
        end
    end

    -- Luồng độc lập giữ quái gom chặt tại vị trí nhân vật (chỉ chạy khi đứng đánh tự do, không can thiệp vào vòng farm/boss)
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(1.0)
            if hubState.fastMobBring ~= false and not hubState.autoFish and os.clock() >= dodgeUntilClock then
                pcall(function()
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if not (char and hrp and hum and hum.Health > 0) then return end

                    local isBossMode = (currentMode ~= "off") or hubState.autoFightMaster or hubState.autoFightIslandBoss
                    local isFarmMode = hubState.autoLevel or hubState.autoKillSelectedMob
                        or hubState.farmSea3Mat or hubState.farmSea2Mat or hubState.farmSea1Mat
                        or hubState.autoDungeon

                    -- Khi đang ở chế độ Farm hoặc Boss, để vòng lặp của chế độ đó quản lý gom quái
                    if isBossMode or isFarmMode then
                        return
                    end

                    -- Đứng đánh tay tự do: CHỈ hút quái khi người dùng đang bật ít nhất 1 Auto M1
                    if #getActiveM1Categories() == 0 then return end
                    local look = hrp.CFrame.LookVector
                    local flatLook = Vector3.new(look.X, 0, look.Z)
                    if flatLook.Magnitude < 0.1 then flatLook = Vector3.new(0, 0, -1) else flatLook = flatLook.Unit end
                    local frontAnchor = hrp.Position + flatLook * 8
                    bringMobsToPosition(frontAnchor, getBringRangeStuds(), 25, nil, false, nil)
                end)
            end
        end
    end)

    -- ========================================================
    -- [QUEST MANAGER & AUTO REPEAT QUEST HELPERS (SEA 1 / 2 / 3)]
    -- ========================================================
    local cachedQuestManager: any = nil
    local function getQuestManagerTable(): any
        if cachedQuestManager ~= nil then
            return cachedQuestManager ~= false and cachedQuestManager or nil
        end
        local chest = sharedRS:FindFirstChild("Chest")
        local mods = chest and chest:FindFirstChild("Modules")
        local qmInst = mods and mods:FindFirstChild("QuestManager")
        if qmInst and qmInst:IsA("ModuleScript") then
            local okReq, tbl = pcall(require, qmInst)
            if okReq and typeof(tbl) == "table" then
                cachedQuestManager = tbl
                return tbl
            end
        end
        cachedQuestManager = false
        return nil
    end

    local function getSeaQuestNpcRanges(): { { name: string, minLv: number, maxLv: number, pos: Vector3 } }
        local list = {}
        local allNpc = workspace:FindFirstChild("AllNPC")
        if allNpc then
            for _, c in ipairs(allNpc:GetChildren()) do
                local lmin = tonumber(c:GetAttribute("LevelMin"))
                local lmax = tonumber(c:GetAttribute("LevelMax"))
                -- Bỏ qua NPC đặc biệt không có mốc cấp thực (như QuestKioru [0-0] ở Sea 2)
                if lmin ~= nil and lmax ~= nil and not (lmin == 0 and lmax == 0) then
                    local p = c:IsA("BasePart") and c or (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart"))
                    if p then
                        table.insert(list, { name = c.Name, minLv = lmin, maxLv = lmax, pos = p.Position })
                    end
                end
            end
        end
        return list
    end

    local function findQuestNpcPositionForLevel(qLv: number): Vector3?
        local ranges = getSeaQuestNpcRanges()
        local bestPos: Vector3? = nil
        local bestSpan = 1e9
        for _, r in ipairs(ranges) do
            if qLv >= r.minLv and qLv <= r.maxLv then
                local span = r.maxLv - r.minLv
                if span < bestSpan then
                    bestSpan = span
                    bestPos = r.pos
                end
            end
        end
        if not bestPos then
            local bestDiff = 1e9
            for _, r in ipairs(ranges) do
                local d = math.min(math.abs(qLv - r.minLv), math.abs(qLv - r.maxLv))
                if d < bestDiff then
                    bestDiff = d
                    bestPos = r.pos
                end
            end
        end
        return bestPos
    end

    local function getBestQuestForLevel(myLvl: number): (string?, any?)
        local qm = getQuestManagerTable()
        if not qm then return nil, nil end
        local ranges = getSeaQuestNpcRanges()
        local hasRanges = #ranges > 0
        local seaMinBound = (game.PlaceId == SEA3_PLACE and 4000) or (game.PlaceId == SEA2_PLACE and 2250) or 0
        local seaMaxBound = (game.PlaceId == SEA1_PLACE and 2200) or (game.PlaceId == SEA2_PLACE and 3999) or 999999
        local function inCurrentSea(qLv: number): boolean
            if qLv < seaMinBound or qLv > seaMaxBound then return false end
            if not hasRanges then return true end
            for _, r in ipairs(ranges) do
                if qLv >= r.minLv and qLv <= r.maxLv then
                    return true
                end
            end
            return false
        end

        local bestName: string? = nil
        local bestInfo: any = nil
        local bestLv = -1
        for qName, qInfo in pairs(qm) do
            if typeof(qName) == "string" and typeof(qInfo) == "table" then
                if not qInfo.DailyQuest and not qInfo.Interact and typeof(qInfo.Mob) == "string" and qInfo.Mob ~= "" then
                    local qLv = tonumber(qInfo.Level)
                    if qLv and qLv <= myLvl and inCurrentSea(qLv) then
                        if qLv > bestLv then
                            bestLv = qLv
                            bestName = qName
                            bestInfo = qInfo
                        end
                    end
                end
            end
        end
        return bestName, bestInfo
    end

    local function clickQuestRepeatButton(acceptRepeat: boolean)
        pcall(function()
            local pgui = player:FindFirstChild("PlayerGui")
            local mainGui = pgui and pgui:FindFirstChild("MainGui")
            local qFrame = mainGui and mainGui:FindFirstChild("QuestFrame")
            local rep = qFrame and qFrame:FindFirstChild("RepeatFrame")
            if rep and rep:IsA("GuiObject") and rep.Visible then
                local btn = rep:FindFirstChild(acceptRepeat and "Yes" or "No")
                if btn and btn:IsA("GuiButton") then
                    local getConns = (getconnections :: any)
                    if typeof(getConns) == "function" then
                        for _, conn in ipairs(getConns(btn.MouseButton1Click)) do
                            pcall(function() conn:Fire() end)
                        end
                    end
                    local fireSig = (firesignal :: any)
                    if typeof(fireSig) == "function" then
                        pcall(function() fireSig(btn.MouseButton1Click) end)
                    end
                end
            end
        end)
    end

    local function handleQuestRepeatPopup()
        if not hubState.autoTakeLevelQuest then return end
        local pgui = player:FindFirstChild("PlayerGui")
        local mainGui = pgui and pgui:FindFirstChild("MainGui")
        local qFrame = mainGui and mainGui:FindFirstChild("QuestFrame")
        local rep = qFrame and qFrame:FindFirstChild("RepeatFrame")
        if not (rep and rep:IsA("GuiObject") and rep.Visible) then return end

        local ps = player:FindFirstChild("PlayerStats")
        local lvlObj = ps and ps:FindFirstChild("lvl")
        local myLvl = lvlObj and tonumber(lvlObj.Value) or 1
        local bestName, bestInfo = getBestQuestForLevel(myLvl)
        local qm = getQuestManagerTable()
        local curQ = player:FindFirstChild("CurrentQuest")
        local curName = (curQ and typeof(curQ.Value) == "string") and curQ.Value or ""
        local curInfo = (qm and curName ~= "") and qm[curName] or nil

        -- Nếu đã lên cấp mở khóa nhiệm vụ cao hơn -> bấm No để tự chuyển sang nhiệm vụ mới
        if bestInfo and curInfo and (tonumber(bestInfo.Level) or 0) > (tonumber(curInfo.Level) or 0) then
            clickQuestRepeatButton(false)
        else
            clickQuestRepeatButton(true)
        end
    end

    -- Bắt sự kiện RepeatFrame hiện lên ngay tức thì (< 0.05s) giống trong video
    pcall(function()
        local pgui = player:FindFirstChild("PlayerGui")
        local mainGui = pgui and pgui:FindFirstChild("MainGui")
        local qFrame = mainGui and mainGui:FindFirstChild("QuestFrame")
        local rep = qFrame and qFrame:FindFirstChild("RepeatFrame")
        if rep and rep:IsA("GuiObject") then
            trackConn(rep:GetPropertyChangedSignal("Visible"):Connect(function()
                if genv._YokaHubToken ~= myToken then return end
                if rep.Visible then
                    task.defer(handleQuestRepeatPopup)
                end
            end))
        end
    end)

    -- ========================================================
    -- [NATIVE AUTO FARM LEVEL & SELECT MOB WORKER]
    -- ========================================================
    local function getActiveQuestMobExact(): (string?, number?)
        local exactMob: string? = nil
        local reqAmount: number? = nil
        pcall(function()
            local curQ = player:FindFirstChild("CurrentQuest")
            local curName = (curQ and typeof(curQ.Value) == "string") and curQ.Value or ""
            local qm = getQuestManagerTable()
            if qm and curName ~= "" and typeof(qm[curName]) == "table" then
                local entry = qm[curName]
                if typeof(entry.Mob) == "string" and entry.Mob ~= "" then
                    exactMob = entry.Mob
                    reqAmount = tonumber(entry.Ammount) or 1
                    return
                end
            end
            local pgui = player:FindFirstChild("PlayerGui")
            local mainGui = pgui and pgui:FindFirstChild("MainGui")
            local qFrame = mainGui and mainGui:FindFirstChild("QuestFrame")
            local qBoard = qFrame and qFrame:FindFirstChild("QuestBoard")
            if qBoard and qBoard:IsA("GuiObject") and qBoard.Visible then
                local tFrame = qBoard:FindFirstChild("TextFrame")
                local qLbl = (tFrame and (tFrame:FindFirstChild("QuestName") or tFrame:FindFirstChildWhichIsA("TextLabel")))
                    or qBoard:FindFirstChild("QuestName", true)
                if qLbl and qLbl:IsA("TextLabel") and qLbl.Text ~= "" then
                    exactMob = qLbl.Text
                end
            end
        end)
        return exactMob, reqAmount
    end

    local function parseMobLevel(mobName: string): number?
        local lv = string.match(mobName, "[Ll][Vv]%.?%s*(%d+)")
        return lv and tonumber(lv) or nil
    end

    local questMobLastPos: { [string]: Vector3 } = {}

    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(0.08)
            if (hubState.autoLevel or hubState.autoKillSelectedMob) and currentMode == "off" then
                pcall(function()
                    handleQuestRepeatPopup()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                    local hrp = char.HumanoidRootPart
                    local hum = char.Humanoid
                    if hum.Health <= 0 then return end
                    if os.clock() < dodgeUntilClock then return end

                    local ps = player:FindFirstChild("PlayerStats")
                    local lvlObj = ps and ps:FindFirstChild("lvl")
                    local myLvl = lvlObj and tonumber(lvlObj.Value) or 1

                    -- Quét ĐẦY ĐỦ cả Monster.Mon lẫn Monster.Boss (để đánh được cả Boss nhiệm vụ như Rumble Man [Lv. 950], Leader [Lv. 1100]...)
                    local mobFolders = getAliveMobFolders(true, false, false)
                    local isSelectMode = (hubState.autoKillSelectedMob == true)
                    local selectedMobName = hubState.selectedMob or genv.chonmod or ""
                    local rawSelLower = ""
                    if isSelectMode and selectedMobName ~= "" then
                        local rawSel = string.match(selectedMobName, "^([%w%s%']+)") or selectedMobName
                        rawSelLower = string.lower(string.gsub(rawSel, "%s+$", ""))
                    end

                    local questMobExact, questAmount = nil, nil
                    if not isSelectMode then
                        questMobExact, questAmount = getActiveQuestMobExact()
                        -- Nếu đang bật Tự Nhận Nhiệm Vụ mà chưa có quest (đang bay tới NPC Quest) -> nhường quyền bay cho Quest Worker, không giật lùi
                        if not questMobExact and hubState.autoTakeLevelQuest then
                            local bName = getBestQuestForLevel(myLvl)
                            if bName then
                                return
                            end
                        end
                    end
                    local questMobLower = questMobExact and string.lower(questMobExact) or nil

                    local targetMob: Model? = nil
                    local bestScore = -1e9

                    for _, fld in ipairs(mobFolders) do
                        for _, m in ipairs(fld:GetChildren()) do
                            if m:IsA("Model") then
                                local mHum = m:FindFirstChildOfClass("Humanoid")
                                local mRoot = getModelRoot(m)
                                if mHum and mHum.Health > 0 and mRoot then
                                    local mnLower = string.lower(m.Name)
                                    local dist = (mRoot.Position - hrp.Position).Magnitude
                                    if isSelectMode and rawSelLower ~= "" then
                                        if string.find(mnLower, rawSelLower, 1, true) then
                                            local score = 100000 - dist
                                            if score > bestScore then
                                                bestScore = score
                                                targetMob = m
                                            end
                                        end
                                    elseif questMobExact and questMobLower then
                                        -- Khóa chặt đúng quái / boss của nhiệm vụ đang nhận (như Rumble Man / High-class Soldier)
                                        if m.Name == questMobExact or string.find(mnLower, questMobLower, 1, true) then
                                            local score = 200000 - dist
                                            if m == currentCombatTarget then score += 500 end
                                            if score > bestScore then
                                                bestScore = score
                                                targetMob = m
                                            end
                                        end
                                    else
                                        local score = -dist * 0.25
                                        local mLv = parseMobLevel(m.Name)
                                        if mLv then
                                            if mLv <= myLvl + 25 then
                                                score += 10000 - math.abs(myLvl - mLv) * 4
                                            else
                                                score -= (mLv - myLvl) * 8
                                            end
                                        end
                                        if m == currentCombatTarget then
                                            score += 1200
                                        end
                                        if score > bestScore then
                                            bestScore = score
                                            targetMob = m
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if targetMob then
                        local mRoot = getModelRoot(targetMob)
                        local mHum = targetMob:FindFirstChildOfClass("Humanoid")
                        if mRoot and mHum and mHum.Health > 0 then
                            setCurrentCombatTarget(targetMob)
                            if questMobExact then
                                questMobLastPos[questMobExact] = mRoot.Position
                            end
                            -- Lơ lửng ngay trên đầu quái/boss nhìn thẳng xuống (8.5 studs an toàn, đánh M1 + Skill trúng 100%)
                            local sHeight = (hubState.safeDistance ~= false) and 8.5 or 7.0
                            local aimPos = getAimPoint(targetMob, mRoot)
                            local hoverPos = mRoot.Position + Vector3.new(0, sHeight, 0)
                            setFlightTarget(hoverPos, aimPos, (hoverPos - hrp.Position).Magnitude > 1600, 45)

                            -- Gom toàn bộ quái cùng loại trên cả đảo về ngay dưới chân nhân vật (tối đa 25 con, chừa quái mục tiêu chính)
                            if (hubState.fastMobBring ~= false or genv.autocat) and (questAmount == nil or questAmount > 1) then
                                local bringAnchor = ((hrp.Position - hoverPos).Magnitude <= 35)
                                    and Vector3.new(hrp.Position.X, mRoot.Position.Y, hrp.Position.Z)
                                    or mRoot.Position
                                bringMobsToPosition(bringAnchor, getBringRangeStuds(), 25, targetMob.Name, false, targetMob)
                            end

                            if (hrp.Position - hoverPos).Magnitude <= 28 then
                                castConfiguredSkills(char, hum, targetMob)
                            end
                        end
                    elseif questMobExact then
                        -- Quái / Boss nhiệm vụ vừa chết đang hồi sinh -> Bay lên cao (+36 studs) đứng chờ an toàn ngay bãi spawn như trong video
                        local waitAnchor = questMobLastPos[questMobExact]
                        if not waitAnchor then
                            local qLv = parseMobLevel(questMobExact) or myLvl
                            waitAnchor = findQuestNpcPositionForLevel(qLv)
                        end
                        if waitAnchor then
                            local safeWaitPos = waitAnchor + Vector3.new(0, 36, 0)
                            setFlightTarget(safeWaitPos, waitAnchor, (safeWaitPos - hrp.Position).Magnitude > 1600, 44)
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
            task.wait(0.22)
            if (hubState.farmSea3Mat or hubState.farmSea2Mat or hubState.farmSea1Mat or genv.farmMaterialsea3 or genv.farmMaterialsea2 or genv.farmMaterialsea1) and currentMode == "off" then
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                    local hrp = char.HumanoidRootPart
                    local hum = char.Humanoid
                    if hum.Health <= 0 then return end
                    if os.clock() < dodgeUntilClock then return end

                    -- Xác định nguyên liệu đang chọn
                    local targetMat = hubState.nguyenlieuSea3 or "Coral"
                    if hubState.farmSea2Mat or genv.farmMaterialsea2 then targetMat = hubState.nguyenlieuSea2 or "Iron Ingot"
                    elseif hubState.farmSea1Mat or genv.farmMaterialsea1 then targetMat = hubState.nguyenlieuSea1 or "Leather" end

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

                    -- Tìm quái rơi nguyên liệu gần nhất (Quét cả Monster.Mon và SeaMonster nếu săn máu Hải Vương)
                    local targetMob: Model? = nil
                    local bestDist = 1e9
                    local mobFolders = getAliveMobFolders(true, rawMat == "sea king's blood", false)
                    for _, fld in ipairs(mobFolders) do
                        for _, m in ipairs(fld:GetChildren()) do
                            if m:IsA("Model") then
                                local mHum = m:FindFirstChildOfClass("Humanoid")
                                local mRoot = getModelRoot(m)
                                if mHum and mHum.Health > 0 and mRoot then
                                    local mn = string.lower(m.Name)
                                    local matched = false
                                    for _, kw in ipairs(keywords) do
                                        if string.find(mn, kw, 1, true) or string.find(kw, mn, 1, true) then
                                            matched = true
                                            break
                                        end
                                    end
                                    if matched then
                                        local d = (mRoot.Position - hrp.Position).Magnitude
                                        if d < bestDist then
                                            bestDist = d
                                            targetMob = m
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if targetMob then
                        local mRoot = getModelRoot(targetMob)
                        if mRoot then
                            setCurrentCombatTarget(targetMob)
                            local sHeight = (hubState.safeDistance ~= false) and 11 or 8
                            local aimPos = getAimPoint(targetMob, mRoot)
                            local hoverPos = mRoot.Position + Vector3.new(0, sHeight, 0)
                            setFlightTarget(hoverPos, aimPos, (hoverPos - hrp.Position).Magnitude > 1600, 44)
                            if (hubState.fastMobBring ~= false or genv.autocat) and (hrp.Position - hoverPos).Magnitude <= 35 then
                                local bringAnchor = Vector3.new(hrp.Position.X, mRoot.Position.Y, hrp.Position.Z)
                                bringMobsToPosition(bringAnchor, getBringRangeStuds(), 25, targetMob.Name, false, targetMob)
                            end
                            if (hrp.Position - hoverPos).Magnitude <= 32 then
                                castConfiguredSkills(char, hum, targetMob)
                            end
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
            task.wait(0.22)
            if (hubState.autoDungeon or genv.autodungeon) and currentMode == "off" then
                pcall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
                    local hrp = char.HumanoidRootPart
                    local hum = char.Humanoid
                    if hum.Health <= 0 then return end
                    if os.clock() < dodgeUntilClock then return end
                    local dMode = hubState.dungeonMode or genv.dungeonmode or "Easy"

                    -- Tự hồi máu bằng gậy nếu bật và máu < 85%
                    if hubState.dungeonAutoHeal and hum.Health / math.max(1, hum.MaxHealth) < 0.85 then
                        local scepter = char:FindFirstChild("Scepter") or player.Backpack:FindFirstChild("Scepter") or char:FindFirstChild("Golden Staff") or player.Backpack:FindFirstChild("Golden Staff")
                        if scepter then
                            if scepter.Parent == player.Backpack then
                                hum:EquipTool(scepter)
                                task.wait(0.2)
                            end
                            scepter:Activate()
                        end
                    end

                    -- Quét quái Dungeon gần nhất (bao gồm cả Monster.Mon và Monster.Boss)
                    local dungeonFolders = getAliveMobFolders(true, false, true)
                    local targetMob: Model? = nil
                    local bestDist = 1e9
                    for _, fld in ipairs(dungeonFolders) do
                        for _, m in ipairs(fld:GetChildren()) do
                            if m:IsA("Model") then
                                local mHum = m:FindFirstChildOfClass("Humanoid")
                                local mRoot = getModelRoot(m)
                                if mHum and mHum.Health > 0 and mRoot then
                                    local d = (mRoot.Position - hrp.Position).Magnitude
                                    if d < bestDist then
                                        bestDist = d
                                        targetMob = m
                                    end
                                end
                            end
                        end
                    end

                    if targetMob then
                        local mRoot = getModelRoot(targetMob)
                        if mRoot then
                            setCurrentCombatTarget(targetMob)
                            local tactics = hubState.dungeonTactics or "Safe"
                            local sDist = string.find(tactics, "Fast") and 8 or (string.find(tactics, "Safe") and 18 or 12)
                            local aimPos = getAimPoint(targetMob, mRoot)
                            local hoverPos = mRoot.Position + Vector3.new(0, sDist, 0)
                            setFlightTarget(hoverPos, aimPos, (hoverPos - hrp.Position).Magnitude > 1600, 48)
                            if (hubState.fastMobBring ~= false or genv.autocat) and (hrp.Position - hoverPos).Magnitude <= 38 then
                                local bringAnchor = Vector3.new(hrp.Position.X, mRoot.Position.Y, hrp.Position.Z)
                                bringMobsToPosition(bringAnchor, getBringRangeStuds(), 25, nil, true, targetMob)
                            end
                            if hubState.dungeonCameraLock == true then
                                pcall(function()
                                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, aimPos)
                                end)
                            end
                            if (hrp.Position - hoverPos).Magnitude <= 35 then
                                castConfiguredSkills(char, hum, targetMob)
                            end
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

                -- 1. Tự Hút / Nhặt Trái Rơi Tự Do (Bay lơ lửng tới nhặt, không rơi xuống biển)
                if (hubState.bringFruits or genv.BringDroppedFruit) and hrp and os.clock() >= dodgeUntilClock then
                    for _, item in ipairs(workspace:GetChildren()) do
                        if item:IsA("Tool") or (item:IsA("Model") and string.find(string.lower(item.Name), "fruit")) then
                            local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                            if handle and (handle.Position - hrp.Position).Magnitude < 4000 then
                                local dest = handle.Position + Vector3.new(0, 2.5, 0)
                                setFlightTarget(dest, handle.Position, (dest - hrp.Position).Magnitude > 1400, 62)
                                task.wait(0.35)
                            end
                        end
                    end
                end

                -- 2. Tự Động Cất Trái Vào Kho Rương (Store Fruit — chỉ cất trái vật lý, không chạm Trái Power đang ăn!)
                if hubState.storeFruits or genv.AutoStoreFruit then
                    local function checkAndStore(tool: Tool)
                        if tool and tool.ToolTip ~= "Fruit Power" and string.find(string.lower(tool.Name), "fruit") then
                            local chest = sharedRS:FindFirstChild("Chest")
                            local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                            if remFuncs and remFuncs:FindFirstChild("DealFruit") then
                                pcall(function() remFuncs.DealFruit:InvokeServer(tool.Name, "Store") end)
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

                -- 3. Shop Sniper Tự Mua Trái Khi Mở Bán (dùng đúng Chest.Remotes.Functions.BuyFruitStock của King Legacy)
                if hubState.snipeShop or genv.shopSniperEnabled then
                    local now = os.clock()
                    local delay = hubState.snipeDelay or genv.shopSniperDelay or 5
                    if now - lastSnipe >= delay then
                        lastSnipe = now
                        local targetFruits = genv.shopSniperFruits or (hubState.snipeFruit and { hubState.snipeFruit }) or { "Dragon", "Phoenix", "Gate", "Dough", "Erebus" }
                        local chest = sharedRS:FindFirstChild("Chest")
                        local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                        local buyStock = remFuncs and remFuncs:FindFirstChild("BuyFruitStock")
                        local legacyNet = sharedRS:FindFirstChild("Remotes")
                        local legacyShop = legacyNet and legacyNet:FindFirstChild("Functions") and (legacyNet.Functions:FindFirstChild("FruitShop") or legacyNet.Functions:FindFirstChild("Merchant"))
                        for _, fruitName in ipairs(targetFruits) do
                            local baseName = string.gsub(fruitName, "Fruit$", "")
                            if buyStock then
                                pcall(function() buyStock:InvokeServer(baseName) end)
                                pcall(function() buyStock:InvokeServer(baseName .. "Fruit") end)
                            elseif legacyShop then
                                pcall(function() legacyShop:InvokeServer("Buy", baseName) end)
                                pcall(function() legacyShop:InvokeServer("Buy", baseName .. "Fruit") end)
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
                local isHovering = activeFlightTarget.pos ~= nil and (os.clock() - activeFlightTarget.updatedAt) <= 2.6
                if (hubState.walkOnWater or hubState.fishFloat or genv.Walkonwater) and hrp and not isHovering then
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
        trackConn(uis.JumpRequest:Connect(function()
            if genv._YokaHubToken ~= myToken then return end
            if (hubState.infiniteJump or genv.InfiniteJumpEnabled) and player and player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end))
    end)

    -- 3. Click Teleport (Giữ Ctrl + Click chuột trái để dịch chuyển, không bấm nhầm khi đánh hoặc bấm UI)
    pcall(function()
        local uis = game:GetService("UserInputService")
        local mouse = player:GetMouse()
        trackConn(mouse.Button1Down:Connect(function()
            if genv._YokaHubToken ~= myToken then return end
            if (hubState.clickTeleport or genv.clickTeleportEnabled) and uis:IsKeyDown(Enum.KeyCode.LeftControl) and player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hit = mouse.Hit
                if hit then
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
                end
            end
        end))
    end)

    -- 4. Tăng Tốc Độ Chạy (Speed Boost — tự trả về 16 khi tắt)
    task.spawn(function()
        local speedWasBoosted = false
        while genv._YokaHubToken == myToken do
            task.wait(0.4)
            pcall(function()
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                if hubState.speedBoost or genv.PlayerSpeedEnabled then
                    speedWasBoosted = true
                    local desired = genv.PlayerWalkSpeed or 65
                    if hum.WalkSpeed < desired - 2 then
                        hum.WalkSpeed = desired
                    end
                elseif speedWasBoosted then
                    speedWasBoosted = false
                    if hum.WalkSpeed > 25 then
                        hum.WalkSpeed = 16
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
                    local f = Instance.new("TextButton")
                    f.Size = UDim2.new(1, 0, 1, 0)
                    f.BackgroundColor3 = Color3.new(0, 0, 0)
                    f.BorderSizePixel = 0
                    f.AutoButtonColor = false
                    f.Text = ""
                    f.Parent = blackGui
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, 0, 0, 40)
                    lbl.Position = UDim2.new(0, 0, 0.5, -20)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = "YokaHub AFK Mode — Tiết Kiệm Điện (Bấm vào màn hình để tắt)"
                    lbl.TextColor3 = Color3.fromRGB(160, 160, 160)
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 16
                    lbl.Parent = f
                    f.MouseButton1Click:Connect(function()
                        hubState.blackScreen = false
                        genv.BlackScreen = false
                        saveState(hubState)
                        if blackGui then
                            blackGui:Destroy()
                            blackGui = nil
                        end
                        safeNotify("YokaHub AFK", "Đã tắt Màn hình đen.", "light_mode")
                    end)
                    blackGui.Parent = guiParent
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
                    local curQ = player:FindFirstChild("CurrentQuest")
                    if not curQ or curQ.Value == "" or curQ.Value == "None" then
                        local qm = getQuestManagerTable()
                        local chest = sharedRS:FindFirstChild("Chest")
                        local qRem = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions") and chest.Remotes.Functions:FindFirstChild("Quest")
                        local ps = player:FindFirstChild("PlayerStats")
                        local myLvl = ps and ps:FindFirstChild("lvl") and tonumber(ps.lvl.Value) or 1
                        if qm and qRem then
                            local bestDq: string? = nil
                            local bestLv = -1
                            for qName, qInfo in pairs(qm) do
                                if typeof(qName) == "string" and typeof(qInfo) == "table" and qInfo.DailyQuest == true then
                                    local ql = tonumber(qInfo.Level) or 0
                                    if ql <= myLvl and ql > bestLv then
                                        bestLv = ql
                                        bestDq = qName
                                    end
                                end
                            end
                            if bestDq then
                                pcall(function() qRem:InvokeServer("take", bestDq) end)
                            end
                        end
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
    -- [NATIVE AUTO STATS WORKER]
    -- ========================================================
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(1.0)
            pcall(function()
                local hasStatActive = hubState.statMelee or hubState.statDefense or hubState.statSword or hubState.statFruit
                if not hasStatActive then return end

                local ps = player:FindFirstChild("PlayerStats")
                local pointsObj = ps and ps:FindFirstChild("Points")
                local availPoints = pointsObj and tonumber(pointsObj.Value) or 0
                if availPoints <= 0 then return end

                local pointsPerTick = math.clamp(tonumber(hubState.statPointsPerTick) or 5, 1, 100)
                local toSpend = math.min(availPoints, pointsPerTick)

                local chestFuncs = game:GetService("ReplicatedStorage"):FindFirstChild("Chest")
                local remFuncs = chestFuncs and chestFuncs:FindFirstChild("Remotes") and chestFuncs.Remotes:FindFirstChild("Functions")
                local upRemote = remFuncs and remFuncs:FindFirstChild("Upgrade")

                local targets = {}
                if hubState.statMelee then table.insert(targets, "Melee") end
                if hubState.statDefense then table.insert(targets, "Defense") end
                if hubState.statSword then table.insert(targets, "Sword") end
                if hubState.statFruit then table.insert(targets, "DF") end

                if #targets > 0 then
                    local perTarget = math.max(1, math.floor(toSpend / #targets))
                    for _, statName in ipairs(targets) do
                        pcall(function()
                            if upRemote then
                                upRemote:InvokeServer(statName, perTarget)
                            end
                            if typeof(genv.UpStats) == "function" then
                                genv.UpStats(statName, perTarget)
                            end
                        end)
                        task.wait(0.08)
                    end
                end
            end)
        end
    end)

    -- ========================================================
    -- [NATIVE AUTO LEVEL QUEST WORKER]
    -- ========================================================
    task.spawn(function()
        while genv._YokaHubToken == myToken do
            task.wait(0.75)
            if hubState.autoTakeLevelQuest then
                pcall(handleQuestRepeatPopup)
            end
            if hubState.autoTakeLevelQuest and hubState.autoLevel and currentMode == "off" then
                pcall(function()
                    handleQuestRepeatPopup()
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if not (hrp and hum and hum.Health > 0) then return end
                    if os.clock() < dodgeUntilClock then return end

                    local ps = player:FindFirstChild("PlayerStats")
                    local lvlObj = ps and ps:FindFirstChild("lvl")
                    local myLvl = lvlObj and tonumber(lvlObj.Value) or 1

                    local bestName, bestInfo = getBestQuestForLevel(myLvl)
                    if not (bestName and bestInfo) then return end

                    local chest = sharedRS:FindFirstChild("Chest")
                    local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                    local qRemote = remFuncs and remFuncs:FindFirstChild("Quest")
                    local etcRemote = remFuncs and remFuncs:FindFirstChild("EtcFunction")
                    local curQuestObj = player:FindFirstChild("CurrentQuest")
                    local curName = (curQuestObj and typeof(curQuestObj.Value) == "string") and curQuestObj.Value or ""

                    -- Nếu đã lên cấp mở khóa nhiệm vụ cao hơn -> tự hủy quest cũ để nhận quest mới
                    if curName ~= "" and curName ~= "None" then
                        local qm = getQuestManagerTable()
                        local curInfo = qm and qm[curName] or nil
                        local curLv = curInfo and tonumber(curInfo.Level) or 0
                        local bestLv = tonumber(bestInfo.Level) or 0
                        if bestLv > curLv and etcRemote then
                            pcall(function() etcRemote:InvokeServer("CancelQuest", {}) end)
                            task.wait(0.25)
                            curName = (curQuestObj and typeof(curQuestObj.Value) == "string") and curQuestObj.Value or ""
                        else
                            return
                        end
                    end

                    -- Nhận nhiệm vụ mới chuẩn King Legacy: Quest:InvokeServer("take", bestName)
                    if (curName == "" or curName == "None") and qRemote then
                        pcall(function() qRemote:InvokeServer("take", bestName) end)
                        task.wait(0.22)
                        local afterName = (curQuestObj and typeof(curQuestObj.Value) == "string") and curQuestObj.Value or ""
                        if afterName == "" or afterName == "None" then
                            -- Nếu server yêu cầu đứng gần NPC Quest -> bay mượt tới đúng NPC Quest theo cấp
                            local npcPos = findQuestNpcPositionForLevel(tonumber(bestInfo.Level) or myLvl)
                            if npcPos then
                                local dest = npcPos + Vector3.new(0, 6, 0)
                                setFlightTarget(dest, npcPos, (dest - hrp.Position).Magnitude > 1600, 52)
                                if (hrp.Position - npcPos).Magnitude <= 30 then
                                    pcall(function() qRemote:InvokeServer("take", bestName) end)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ========================================================
    -- [NATIVE ISLAND TELEPORT HANDLER]
    -- ========================================================
    local ISLAND_COORDS: { [string]: Vector3 } = {
        ["🏝️ [Sea 1] Đảo Hải Tặc Đầu Tiên (Pirate Island)"] = Vector3.new(1450, 48, 1450),
        ["🏝️ [Sea 1] Trụ Sở Hải Quân (Marine Headquarters)"] = Vector3.new(-3100, 35, -2300),
        ["🏝️ [Sea 1] Đảo Hề Buggy (Clown Island)"] = Vector3.new(-1200, 35, 1200),
        ["🏝️ [Sea 1] Đảo Sa Mạc (Desert Island)"] = Vector3.new(850, 40, -1450),
        ["🏝️ [Sea 1] Đảo Tuyết (Snow Island)"] = Vector3.new(-2200, 75, 450),
        ["🏝️ [Sea 1] Đảo Trên Trời (Skypiea)"] = Vector3.new(100, 950, -4500),
        ["🏝️ [Sea 1] Đảo Bong Bóng (Bubble Island)"] = Vector3.new(-3800, 45, 2100),
        ["🏝️ [Sea 1] Đảo Người Cá (Fishman Island)"] = Vector3.new(500, -1800, 6500),
        ["🏝️ [Sea 1] Đảo Zombie (Thriller Island)"] = Vector3.new(-5400, 60, -800),
        ["🏝️ [Sea 1] Đảo Tổng Bộ Hải Quân (Marineford)"] = Vector3.new(4500, 75, -2800),
        ["🏝️ [Sea 2] Đảo Viridans (Viridans)"] = Vector3.new(-1700, 70, -2100),
        ["🏝️ [Sea 2] Đảo Florescence (Florescence)"] = Vector3.new(1200, 65, -3400),
        ["🏝️ [Sea 2] Đảo Đầu Lâu (Skull Island)"] = Vector3.new(-3500, 85, 1200),
        ["🏝️ [Sea 2] Đảo Tuyết Sea 2 (Dead Tundra)"] = Vector3.new(3400, 70, 2200),
        ["🏝️ [Sea 2] Đảo Bánh Mì (Loaf Island)"] = Vector3.new(-4200, 90, -4500),
        ["🏝️ [Sea 2] Đảo Shred (Shred Island)"] = Vector3.new(5200, 80, -1500),
        ["🏝️ [Sea 2] Đảo Hibernus (Hibernus)"] = Vector3.new(150, 60, 4800),
        ["🏝️ [Sea 3] Cảng Hải Tặc (Port Island)"] = Vector3.new(150, 45, 250),
        ["🏝️ [Sea 3] Đấu Trường La Mã (The Colosseum)"] = Vector3.new(-2200, 80, -1800),
        ["🏝️ [Sea 3] Đảo Fiore (Fiore Island)"] = Vector3.new(2800, 65, -3200),
        ["🏝️ [Sea 3] Ổ Rồng Lửa (Mount Inferno)"] = Vector3.new(-4500, 210, 3500),
        ["🏝️ [Sea 3] Thánh Địa Mặt Trời (Sanctuary of the Sun)"] = Vector3.new(4200, 150, 4100),
    }

    genv.TeleportToIsland = function(islandName: string?)
        pcall(function()
            local chosen = islandName or hubState.selectedIsland or "🏝️ [Sea 1] Đảo Hải Tặc Đầu Tiên (Pirate Island)"
            local targetPos: Vector3? = nil

            -- 1. Ưu tiên tìm tọa độ thực tế ngay trong workspace.AllNPC / workspace.Island theo tên tiếng Anh trong ngoặc
            local engHint = string.match(chosen, "%(([^%)]+)%)") or chosen
            engHint = string.lower(string.gsub(engHint, "%s+[Ii]sland%s*$", ""))
            engHint = string.gsub(engHint, "^the%s+", "")
            if #engHint >= 3 then
                local allNpc = workspace:FindFirstChild("AllNPC")
                if allNpc then
                    for _, c in ipairs(allNpc:GetChildren()) do
                        if string.find(string.lower(c.Name), engHint, 1, true) then
                            local p = c:IsA("BasePart") and c or (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart"))
                            if p then targetPos = p.Position; break end
                        end
                    end
                end
                if not targetPos then
                    local islF = workspace:FindFirstChild("Island")
                    if islF then
                        for _, c in ipairs(islF:GetChildren()) do
                            if string.find(string.lower(c.Name), engHint, 1, true) then
                                local okB, cf = pcall(function() return c:IsA("Model") and c:GetBoundingBox() or (c:IsA("BasePart") and c.CFrame or nil) end)
                                if okB and typeof(cf) == "CFrame" then targetPos = cf.Position; break end
                            end
                        end
                    end
                end
            end

            -- 2. Dự phòng dùng bảng tọa độ cứng ISLAND_COORDS
            if not targetPos then
                targetPos = ISLAND_COORDS[chosen]
                if not targetPos then
                    for k, pos in pairs(ISLAND_COORDS) do
                        if string.find(string.lower(k), string.lower(chosen), 1, true) then
                            targetPos = pos
                            break
                        end
                    end
                end
            end
            if not targetPos then
                safeNotify("Dịch Chuyển Đảo", "Không tìm thấy tọa độ đảo: " .. tostring(chosen), "error")
                return
            end

            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                safeNotify("Dịch Chuyển Đảo", "Đang bay / dịch chuyển đến " .. chosen .. "...", "near_me")
                local dest = targetPos + Vector3.new(0, 22, 0)
                setFlightTarget(dest, nil, (dest - hrp.Position).Magnitude > 1400, 70)
            end
        end)
    end

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
                    local chest = sharedRS:FindFirstChild("Chest")
                    local cFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                    local allyRem = cFuncs and cFuncs:FindFirstChild("Ally")
                    if not allyRem then
                        local legacy = sharedRS:FindFirstChild("Remotes")
                        allyRem = legacy and legacy:FindFirstChild("Functions") and legacy.Functions:FindFirstChild("Ally")
                    end
                    if allyRem then
                        for _, otherPlr in ipairs(players:GetPlayers()) do
                            if otherPlr ~= player then
                                pcall(function() allyRem:InvokeServer("Accept", otherPlr) end)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ========================================================
    -- [NATIVE COMBAT AIMBOT, PREDICTIVE TELEPORT DODGE & AUTO TRANSFORM WORKER]
    -- ========================================================
    local HAZARD_NAME_KEYWORDS = {
        "aoe", "beam", "laser", "meteor", "explosion", "explode", "slash", "tsunami",
        "thunder", "lightning", "tornado", "fireball", "dragon", "kraken", "tentacle",
        "acid", "poison", "quake", "blast", "wave", "breath", "shockwave", "slam",
        "warning", "indicator", "hitbox", "danger", "ring", "circle", "vortex", "nova",
        "flame", "magma", "ice", "spike", "roar", "stomp", "whirlpool", "typhoon",
    }

    local function isLikelyHazardName(nameLower: string): boolean
        for _, kw in ipairs(HAZARD_NAME_KEYWORDS) do
            if string.find(nameLower, kw, 1, true) then
                return true
            end
        end
        return false
    end

    local function isMegaSeaBossName(nameLower: string): boolean
        if isIslandMobName(nameLower) then return false end
        return string.find(nameLower, "depth king", 1, true) ~= nil
            or string.find(nameLower, "abyssal tyrant", 1, true) ~= nil
            or string.find(nameLower, "drakenfyr", 1, true) ~= nil
            or string.find(nameLower, "sea dragon", 1, true) ~= nil
            or string.find(nameLower, "hydra", 1, true) ~= nil
            or string.find(nameLower, "sea king", 1, true) ~= nil
            or string.find(nameLower, "seaking", 1, true) ~= nil
            or string.find(nameLower, "kraken", 1, true) ~= nil
            or string.find(nameLower, "serpent", 1, true) ~= nil
            or string.find(nameLower, "ghost ship", 1, true) ~= nil
            or string.find(nameLower, "crab", 1, true) ~= nil
            or string.find(nameLower, "sea beast", 1, true) ~= nil
    end

    local function isBossWindingUp(bossModel: Model, bossHum: Humanoid): boolean
        -- 1. Kiểm tra các Attribute trạng thái ra chiêu của King Legacy
        for _, attrName in ipairs({ "Doing", "TotalDoing", "Attacking", "Skill", "Casting", "Busy", "UsingSkill" }) do
            local v = bossModel:GetAttribute(attrName)
            if v == true or (typeof(v) == "number" and v > 0) or (typeof(v) == "string" and v ~= "" and v ~= "None") then
                return true
            end
        end
        -- 2. Kiểm tra Animation Track đang chạy (bỏ qua idle / walk / run / swim)
        local animator = bossHum:FindFirstChildOfClass("Animator")
        if animator then
            local okTracks, tracks = pcall(function()
                return animator:GetPlayingAnimationTracks()
            end)
            if okTracks and typeof(tracks) == "table" then
                for _, tr in ipairs(tracks) do
                    local tn = string.lower(tostring(tr.Name or ""))
                    local prio = tr.Priority
                    local isIdleMove = string.find(tn, "idle", 1, true) ~= nil
                        or string.find(tn, "walk", 1, true) ~= nil
                        or string.find(tn, "run", 1, true) ~= nil
                        or string.find(tn, "swim", 1, true) ~= nil
                        or string.find(tn, "fall", 1, true) ~= nil
                    if not isIdleMove and (prio == Enum.AnimationPriority.Action or prio == Enum.AnimationPriority.Action2 or prio == Enum.AnimationPriority.Action3 or prio == Enum.AnimationPriority.Action4 or tr.Speed > 0.1) then
                        return true
                    end
                end
            end
        end
        return false
    end

    task.spawn(function()
        local lastTransformTick = 0
        local lastDodgeTick = 0
        local lastHpSample = -1
        local lastHpClock = 0
        local vim = game:GetService("VirtualInputManager")

        while genv._YokaHubToken == myToken do
            task.wait(0.08)
            pcall(function()
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not (hrp and hum and hum.Health > 0) then
                    lastHpSample = -1
                    return
                end

                local now = os.clock()
                local myPos = hrp.Position

                -- 1. Auto Transform (Chỉ bấm phím V khi chiêu V của Trái đã MỞ KHÓA đủ chỉ số DF, tuyệt đối không spam Skill locked!)
                if hubState.autoTransform and (now - lastTransformTick) > 12.0 then
                    local isFighting = (currentMode ~= "off") or (hubState.autoLevel) or (hubState.autoKillSelectedMob) or (hubState.autoFightMaster) or (hubState.autoFightIslandBoss) or (hubState.autoDungeon)
                    if isFighting and now >= dodgeUntilClock and not isHoldingSkill then
                        local fruitTool = findToolByCategory("fruit")
                        if fruitTool and isSkillReadyToCast("fruit", "V", fruitTool) then
                            lastTransformTick = now
                            pcall(function()
                                if fruitTool.Parent == player.Backpack then
                                    hum:EquipTool(fruitTool)
                                    task.wait(0.05)
                                end
                                vim:SendKeyEvent(true, Enum.KeyCode.V, false, game)
                                task.wait(0.05)
                                vim:SendKeyEvent(false, Enum.KeyCode.V, false, game)
                            end)
                            pcall(function()
                                local chest = sharedRS:FindFirstChild("Chest")
                                local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                                if remFuncs and remFuncs:FindFirstChild("SkillAction") then
                                    remFuncs.SkillAction:InvokeServer("Transform")
                                end
                            end)
                        end
                    end
                end

                -- 2. Skill Direction Aimbot (Bổ sung đồng bộ trạng thái & hướng mục tiêu Boss/Quái/Sea Event)
                if hubState.skillAimbot ~= false and genv.PlayerAimbotEnabled ~= false then
                    local aimRange = tonumber(genv.PlayerAimRange) or 450
                    local tModel, tRoot = getBestCombatTarget(aimRange)
                    if tModel and tRoot then
                        local aimPos = getAimPoint(tModel, tRoot)
                        _G.MouseHit = CFrame.new(aimPos)
                    end
                end

                -- 3. Predictive Boss AOE Teleport Dodge (Né bằng Teleport + Hover Lock, dự đoán tầm chiêu Boss, KHÔNG dùng Q Dash)
                local maxHp = math.max(1, hum.MaxHealth)
                local curHp = hum.Health
                local suddenDrop = false
                if lastHpSample > 0 and (now - lastHpClock) <= 0.45 then
                    if (lastHpSample - curHp) >= (maxHp * 0.10) then
                        suddenDrop = true
                    end
                end
                if (now - lastHpClock) >= 0.35 or lastHpSample < 0 then
                    lastHpSample = curHp
                    lastHpClock = now
                end

                if hubState.autoDodge ~= false and genv.autoDodgeEnabled ~= false and (now - lastDodgeTick) >= 1.1 then
                    local safeRange = math.clamp(tonumber(hubState.dodgeSafeDistance or genv.DodgeSafeDistance) or 95, 40, 180)
                    local activeHazards: { { pos: Vector3, radius: number } } = {}
                    local triggerThreatPos: Vector3? = nil
                    local triggerThreatLook: Vector3? = nil
                    local triggerDangerRadius = 0
                    local triggerHoldSec = 1.15

                    -- Quét Boss / Sea Event sống gần người chơi trước (chỉ bật dự đoán né AOE khi thực sự ở gần Boss/Sea Event để tránh tự né chiêu của chính mình khi farm quái thường!)
                    local bossFolders: { Instance } = {}
                    for _, fn in ipairs({ "SeaMonster", "GhostMonster" }) do
                        local f = workspace:FindFirstChild(fn)
                        if f then table.insert(bossFolders, f) end
                    end
                    local monF = workspace:FindFirstChild("Monster")
                    if monF and monF:FindFirstChild("Boss") then
                        table.insert(bossFolders, monF.Boss)
                    end

                    local nearestBossPos: Vector3? = nil
                    local nearestBossLook: Vector3? = nil
                    local nearestBossDist = 1e9

                    -- Lớp 1: Dự đoán tầm chiêu của Boss / Sea Event khi Boss gồng chiêu hoặc nhắm thẳng vào người chơi
                    for _, bf in ipairs(bossFolders) do
                        for _, boss in ipairs(bf:GetChildren()) do
                            if boss:IsA("Model") then
                                local bHum = boss:FindFirstChildOfClass("Humanoid")
                                local bRoot = getModelRoot(boss)
                                if bHum and bHum.Health > 0 and bRoot then
                                    local toMe = myPos - bRoot.Position
                                    local dist = toMe.Magnitude
                                    if dist < nearestBossDist then
                                        nearestBossDist = dist
                                        nearestBossPos = bRoot.Position
                                        nearestBossLook = bRoot.CFrame.LookVector
                                    end
                                    if dist <= (safeRange + 65) then
                                        local isMega = (bf.Name == "SeaMonster" or bf.Name == "GhostMonster") or isMegaSeaBossName(string.lower(boss.Name))
                                        local predRadius = isMega and safeRange or math.max(52, safeRange * 0.68)
                                        local inFrontCone = false
                                        if dist > 2 then
                                            local flatToMe = Vector3.new(toMe.X, 0, toMe.Z)
                                            local flatLook = Vector3.new(bRoot.CFrame.LookVector.X, 0, bRoot.CFrame.LookVector.Z)
                                            if flatToMe.Magnitude > 0.5 and flatLook.Magnitude > 0.5 then
                                                inFrontCone = flatLook.Unit:Dot(flatToMe.Unit) > 0.70 and dist <= (predRadius * 1.35)
                                            end
                                        end
                                        local windingUp = isBossWindingUp(boss, bHum)
                                        if (windingUp and (dist <= predRadius or inFrontCone)) or (isMega and dist <= math.min(46, predRadius * 0.52)) then
                                            local neededRad = inFrontCone and (predRadius * 1.3) or predRadius
                                            if neededRad > triggerDangerRadius then
                                                triggerThreatPos = bRoot.Position
                                                triggerThreatLook = bRoot.CFrame.LookVector
                                                triggerDangerRadius = neededRad
                                                triggerHoldSec = isMega and 1.4 or 1.1
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- Lớp 2: Quét vùng chiêu AOE trong workspace.Effects CHỈ KHI có Boss/Sea Event trong tầm 240 studs (bỏ qua VFX chiêu của chính người chơi!)
                    if nearestBossPos and nearestBossDist <= 240 then
                        local ps = player:FindFirstChild("PlayerStats")
                        local myDfLow = ps and ps:FindFirstChild("DFName") and string.lower(tostring(ps.DFName.Value or "")) or ""
                        local myDfShort = (#myDfLow >= 6 and string.sub(myDfLow, 1, math.floor(#myDfLow / 2)) == string.sub(myDfLow, math.floor(#myDfLow / 2) + 1)) and string.sub(myDfLow, 1, math.floor(#myDfLow / 2)) or myDfLow
                        local mySwLow = ps and ps:FindFirstChild("SwordName") and string.lower(tostring(ps.SwordName.Value or "")) or ""

                        local fxFolder = workspace:FindFirstChild("Effects")
                        if fxFolder then
                            for _, fx in ipairs(fxFolder:GetChildren()) do
                                local ownerAttr = fx:GetAttribute("Owner") or fx:GetAttribute("User") or fx:GetAttribute("Player")
                                if ownerAttr ~= player.Name then
                                    local nameLow = string.lower(fx.Name)
                                    local isMyOwnSkillFx = (#myDfShort >= 3 and string.find(nameLow, myDfShort, 1, true) ~= nil)
                                        or (#mySwLow >= 3 and string.find(nameLow, mySwLow, 1, true) ~= nil)
                                    if not isMyOwnSkillFx then
                                        local fxPos: Vector3? = nil
                                        local fxRadius = 0
                                        if fx:IsA("BasePart") then
                                            fxPos = fx.Position
                                            fxRadius = math.max(fx.Size.X, fx.Size.Y, fx.Size.Z) * 0.5
                                        elseif fx:IsA("Model") then
                                            local okBb, cf, sz = pcall(function() return fx:GetBoundingBox() end)
                                            if okBb and cf and sz then
                                                fxPos = cf.Position
                                                fxRadius = math.max(sz.X, sz.Y, sz.Z) * 0.5
                                            end
                                        end
                                        if fxPos then
                                            local distToFx = (fxPos - myPos).Magnitude
                                            local distFxToBoss = (fxPos - nearestBossPos).Magnitude
                                            if distToFx <= 220 and distFxToBoss <= 260 then
                                                local isDangerFx = (fxRadius >= 14) or (fxRadius >= 7 and isLikelyHazardName(nameLow))
                                                if isDangerFx and not ((now - lastPlayerSkillCastClock) < 0.45 and distToFx < 16) then
                                                    local dangerRad = math.clamp(fxRadius + 24, 42, safeRange + 35)
                                                    table.insert(activeHazards, { pos = fxPos, radius = dangerRad })
                                                    if distToFx <= dangerRad and dangerRad > triggerDangerRadius then
                                                        triggerThreatPos = fxPos
                                                        triggerDangerRadius = dangerRad
                                                        triggerHoldSec = 1.15
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- Lớp 3: Phản xạ khẩn cấp khi tụt máu đột ngột (>12% trong 0.45s) hoặc HP < 30%
                    local isLowHp = (curHp / maxHp) < 0.30
                    if not triggerThreatPos and ((suddenDrop and nearestBossDist <= 180) or isLowHp) then
                        if nearestBossPos and nearestBossDist <= 180 then
                            triggerThreatPos = nearestBossPos
                            triggerThreatLook = nearestBossLook
                            triggerDangerRadius = safeRange
                            triggerHoldSec = 1.45
                        elseif isLowHp then
                            local tM, tR = getBestCombatTarget(55)
                            if tM and tR then
                                triggerThreatPos = tR.Position
                                triggerDangerRadius = math.max(60, safeRange * 0.75)
                                triggerHoldSec = 1.25
                            end
                        end
                    end

                    -- Thực thi Teleport né ra ngoài tầm chiêu dự đoán + Hover Lock trên không
                    if triggerThreatPos then
                        lastDodgeTick = now
                        isHoldingSkill = false
                        dodgeUntilClock = now + triggerHoldSec

                        local escapeDist = math.max(triggerDangerRadius + 28, safeRange + 16)
                        local baseDir: Vector3
                        if triggerThreatLook then
                            -- Ưu tiên nhảy lệch vuông góc / ra sau lưng Boss để tránh tia Beam thẳng mặt
                            local back = Vector3.new(-triggerThreatLook.X, 0, -triggerThreatLook.Z)
                            local side = Vector3.new(-triggerThreatLook.Z, 0, triggerThreatLook.X)
                            local mixed = back * 0.7 + side * 0.7
                            baseDir = mixed.Magnitude > 0.1 and mixed.Unit or Vector3.new(1, 0, 0)
                        else
                            local away = Vector3.new(myPos.X - triggerThreatPos.X, 0, myPos.Z - triggerThreatPos.Z)
                            baseDir = away.Magnitude > 0.5 and away.Unit or Vector3.new(1, 0, 0)
                        end

                        local safeY = math.max(triggerThreatPos.Y + 42, myPos.Y + 22, 58)
                        local chosenEscape = Vector3.new(
                            triggerThreatPos.X + baseDir.X * escapeDist,
                            safeY,
                            triggerThreatPos.Z + baseDir.Z * escapeDist
                        )

                        -- Kiểm tra 5 góc thoát (0°, +60°, -60°, +120°, -120°) để không tele trúng vùng AOE khác
                        local candidateAngles = { 0, 60, -60, 120, -120 }
                        for _, deg in ipairs(candidateAngles) do
                            local rad = math.rad(deg)
                            local c, s = math.cos(rad), math.sin(rad)
                            local dir = Vector3.new(baseDir.X * c - baseDir.Z * s, 0, baseDir.X * s + baseDir.Z * c)
                            local candPos = Vector3.new(
                                triggerThreatPos.X + dir.X * escapeDist,
                                safeY,
                                triggerThreatPos.Z + dir.Z * escapeDist
                            )
                            local insideOtherHazard = false
                            for _, hz in ipairs(activeHazards) do
                                if (candPos - hz.pos).Magnitude < (hz.radius + 14) then
                                    insideOtherHazard = true
                                    break
                                end
                            end
                            if not insideOtherHazard then
                                chosenEscape = candPos
                                break
                            end
                        end

                        setFlightTarget(chosenEscape, triggerThreatPos, true, 100)
                    end
                end
            end)
        end
    end)

    -- ========================================================
    -- [NATIVE MATERIAL QUANTITY TRACKER WORKER]
    -- ========================================================
    task.spawn(function()
        local lastCheckTick = 0
        local quotaTarget = 50

        while genv._YokaHubToken == myToken do
            task.wait(2.5)
            pcall(function()
                if not (hubState.materialQuantityTracker or genv.MaterialQuantityTracker) then return end
                if not (hubState.farmSea3Mat or hubState.farmSea2Mat or hubState.farmSea1Mat or genv.farmMaterialsea3 or genv.farmMaterialsea2 or genv.farmMaterialsea1) then return end
                if (os.clock() - lastCheckTick) < 5.0 then return end
                lastCheckTick = os.clock()

                local ps = player:FindFirstChild("PlayerStats")
                local matObj = ps and ps:FindFirstChild("Material")
                if not matObj or typeof(matObj.Value) ~= "string" or #matObj.Value < 3 then return end

                local okDecode, matTable = pcall(function()
                    return game:GetService("HttpService"):JSONDecode(matObj.Value)
                end)
                if not okDecode or typeof(matTable) ~= "table" then return end

                local curMat = hubState.nguyenlieuSea3 or "Coral"
                if hubState.farmSea2Mat or genv.farmMaterialsea2 then curMat = hubState.nguyenlieuSea2 or "Iron Ingot"
                elseif hubState.farmSea1Mat or genv.farmMaterialsea1 then curMat = hubState.nguyenlieuSea1 or "Leather" end

                curMat = string.match(curMat, "^([%w%s%']+)") or curMat
                curMat = string.gsub(curMat, "%s+$", "")

                local count = tonumber(matTable[curMat]) or 0
                if count >= quotaTarget then
                    hubState.farmSea3Mat = false
                    hubState.farmSea2Mat = false
                    hubState.farmSea1Mat = false
                    genv.farmMaterialsea3 = false
                    genv.farmMaterialsea2 = false
                    genv.farmMaterialsea1 = false
                    saveState(hubState)
                    safeNotify("Gom Nguyên Liệu", "Đã gom đủ " .. tostring(count) .. " " .. curMat .. " (Đạt mốc " .. quotaTarget .. "). Đã tự động dừng gom!", "verified")
                end
            end)
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
                -- Dọn dẹp các ESP của vật thể đã biến mất khỏi bản đồ
                for inst, bb in pairs(activeEspObjects) do
                    if not inst or not inst.Parent or not bb or not bb.Parent then
                        pcall(function() if bb then bb:Destroy() end end)
                        activeEspObjects[inst] = nil
                    end
                end

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
                    local function attachChestEsp(root: BasePart, labelPrefix: string?)
                        if not root:FindFirstChild("YokaChestESP") then
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "YokaChestESP"
                            bb.AlwaysOnTop = true
                            bb.Size = UDim2.new(0, 150, 0, 28)
                            bb.StudsOffset = Vector3.new(0, 2, 0)
                            local lbl = Instance.new("TextLabel")
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.TextColor3 = Color3.fromRGB(255, 170, 40)
                            lbl.TextStrokeTransparency = 0.2
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 12
                            local dist = math.floor((root.Position - myPos).Magnitude)
                            lbl.Text = "📦 " .. (labelPrefix or "Rương") .. " [" .. dist .. "m]"
                            lbl.Parent = bb
                            bb.Adornee = root
                            bb.Parent = root
                            activeEspObjects[root] = bb
                        else
                            local lbl = root.YokaChestESP:FindFirstChildOfClass("TextLabel")
                            if lbl then
                                local dist = math.floor((root.Position - myPos).Magnitude)
                                lbl.Text = "📦 " .. (labelPrefix or "Rương") .. " [" .. dist .. "m]"
                            end
                        end
                    end

                    local chestFolders = { workspace:FindFirstChild("Chests"), workspace:FindFirstChild("ChestFolder") }
                    for _, cf in ipairs(chestFolders) do
                        if cf then
                            for _, ch in ipairs(cf:GetChildren()) do
                                local root = ch:IsA("BasePart") and ch or ch:FindFirstChildWhichIsA("BasePart")
                                if root then attachChestEsp(root, "Rương") end
                            end
                        end
                    end
                    local isl = workspace:FindFirstChild("Island")
                    if isl then
                        for _, c in ipairs(isl:GetChildren()) do
                            for _, d in ipairs(c:GetDescendants()) do
                                if d:IsA("Model") and string.find(string.lower(d.Name), "chest") and not string.find(string.lower(d.Name), "spawner") then
                                    local root = d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")
                                    if root then attachChestEsp(root, d.Name) end
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
    end)()
end)
