    -- ========================================================
    -- GLOBAL DROPDOWN HELPER (AVAILABLE TO ALL MODULES)
    -- ========================================================
    local function pickDropdownValue(v: any): string
        if typeof(v) == "table" then return tostring(v[1] or "") end
        return tostring(v or "")
    end

    local function pickMultiDropdownValue(v: any): { string }
        local res = {}
        if typeof(v) == "table" then
            for _, item in ipairs(v) do
                if typeof(item) == "string" and item ~= "" then
                    table.insert(res, item)
                end
            end
        elseif typeof(v) == "string" and v ~= "" then
            table.insert(res, v)
        end
        return res
    end
    -- [END GATEWAY] - BAT DAU KHOI DONG YOKAHUB
    -- ========================================================


    local SEA1_PLACE = 4520749081
    local SEA2_PLACE = 6381829480
    local SEA3_PLACE = 15759515082

    local stateFile = "YokaHub_State.json"
    local sessionFile = "YokaHub_Session.json"
    local dropsFile = "YokaHub_Drops.json"
    local visitedSea3File = "AutoSeaEventApiVisited.json"
    local visitedSea2File = "AutoSea2PriorityApiVisited.json"
    local visitedSoloFile = "AutoSoloApiVisited.json"
    local visitedTTL = 85 -- Thoi gian ghi nho phong da ghe (85s giup hop nhanh & xoay tua phong lien tuc)

    local rf = genv.readfile or readfile
    local wf = genv.writefile or writefile
    local isf = genv.isfile or isfile

    -- 1. Don sach phien ban cu, ket noi cu va toan bo LunaBlur
    genv._AutoHopLoopToken = -1
    genv._AutoSea2LoopToken = -1
    genv._KingAutoHopToken = -1
    genv._AutoSeaEventApiHop = false
    genv._AutoSea2PriorityApiHop = false
    genv._AutoDepthKingOnlyApiHop = false

    local oldConns = genv._YokaHubConns
    if typeof(oldConns) == "table" then
        for _, c in ipairs(oldConns) do
            pcall(function() c:Disconnect() end)
        end
    end
    local activeConns: { RBXScriptConnection } = {}
    genv._YokaHubConns = activeConns

    local function trackConn(conn: RBXScriptConnection): RBXScriptConnection
        table.insert(activeConns, conn)
        return conn
    end

    if genv._YokaHubLuna and typeof(genv._YokaHubLuna.Destroy) == "function" then
        pcall(function() genv._YokaHubLuna:Destroy() end)
        genv._YokaHubLuna = nil
    end

    local gethuiFn = genv.gethui
    local guiParent: Instance = coreGui
    if typeof(gethuiFn) == "function" then
        local ok, hui = pcall(gethuiFn)
        if ok and typeof(hui) == "Instance" then
            guiParent = hui
        end
    end
    for _, oldName in ipairs({ "AutoHopSea3ToggleGui", "AutoHopSea2ToggleGui", "KingAutoHopHubGui", "YokaHubDockGui", "Luna UI" }) do
        local g1 = guiParent:FindFirstChild(oldName)
        if g1 then g1:Destroy() end
        local g2 = coreGui:FindFirstChild(oldName)
        if g2 then g2:Destroy() end
    end

    local function purgeLunaBlur()
        for _, c in ipairs(lighting:GetChildren()) do
            if string.sub(c.Name, 1, 4) == "DPT_" then
                pcall(function() c:Destroy() end)
            end
        end
        local cam = workspace.CurrentCamera
        if cam then
            for _, c in ipairs(cam:GetChildren()) do
                if c.Name == "LunaBlur" then
                    pcall(function() c:Destroy() end)
                end
            end
        end
        for i = 1, 100 do
            pcall(function() runService:UnbindFromRenderStep("neon::" .. tostring(i)) end)
        end
    end
    purgeLunaBlur()

    -- 2. Tien ich JSON & dinh dang so
    local function readJson(path: string): any
        if typeof(isf) == "function" and typeof(rf) == "function" then
            local ok, exists = pcall(isf, path)
            if ok and exists then
                local rok, raw = pcall(rf, path)
                if rok and typeof(raw) == "string" then
                    local dok, decoded = pcall(function() return httpService:JSONDecode(raw) end)
                    if dok and typeof(decoded) == "table" then return decoded end
                end
            end
        end
        return nil
    end

    local function writeJson(path: string, tbl: any)
        if typeof(wf) == "function" then
            pcall(function() wf(path, httpService:JSONEncode(tbl)) end)
        end
    end

    local function fmtNum(n: number): string
        local sign = n < 0 and "-" or ""
        local a = math.abs(math.floor(n + 0.5))
        if a >= 1000000000 then
            return string.format("%s%.2fB", sign, a / 1000000000)
        elseif a >= 1000000 then
            return string.format("%s%.2fM", sign, a / 1000000)
        end
        local rev = string.reverse(tostring(a))
        local grouped = string.gsub(rev, "(%d%d%d)", "%1,")
        local out = string.reverse(grouped)
        if string.sub(out, 1, 1) == "," then out = string.sub(out, 2) end
        return sign .. out
    end

    local function fmtSigned(n: number): string
        return n > 0 and ("+" .. fmtNum(n)) or fmtNum(n)
    end

    local function fmtDuration(sec: number): string
        local s = math.max(0, math.floor(sec))
        return string.format("%02d:%02d:%02d", math.floor(s / 3600), math.floor((s % 3600) / 60), s % 60)
    end

    local function getPlayerStats()
        local lp = players.LocalPlayer
        local ps = lp and lp:FindFirstChild("PlayerStats")
        local function val(name: string): any
            local o = ps and ps:FindFirstChild(name)
            return o and (o :: any).Value or nil
        end
        return {
            beli = tonumber(val("beli")) or 0,
            gems = tonumber(val("Gem")) or 0,
        }
    end

    -- 1 TÔNG MÀU THỐNG NHẤT SẠCH ĐẸP (OBSIDIAN + XANH NGỌC YOKAHUB CHUẨN HIỆN ĐẠI)
    local THEME = {
        c1 = Color3.fromRGB(110, 231, 183),
        c2 = Color3.fromRGB(64, 198, 148),
        c3 = Color3.fromRGB(28, 168, 118),
        sidebarBg = Color3.fromRGB(17, 18, 24),
        contentBg = Color3.fromRGB(23, 25, 33),
        outerStroke = Color3.fromRGB(54, 60, 76),
        dockBg = Color3.fromRGB(20, 22, 29),
        activeTabBg = Color3.fromRGB(58, 182, 136),
        inactiveTabBg = Color3.fromRGB(30, 33, 44),
        secTitle = Color3.fromRGB(82, 214, 164),
        -- The thong nhat gon mat
        cardBg = Color3.fromRGB(31, 34, 44),
        cardStroke = Color3.fromRGB(56, 62, 80),
        infoBg = Color3.fromRGB(25, 36, 44),
        infoStroke = Color3.fromRGB(62, 174, 134),
        infoTitle = Color3.fromRGB(116, 234, 188),
        dangerBg = Color3.fromRGB(48, 24, 28),
        dangerStroke = Color3.fromRGB(196, 76, 86),
        dangerTitle = Color3.fromRGB(255, 214, 218),
        textMain = Color3.fromRGB(246, 248, 252),
        textDesc = Color3.fromRGB(182, 190, 206),
    }

    -- 3. Doc / Luu trang thai & phien Farm
    local SOLO_OPTIONS = {
        "👑 Depth King (Sea 3)",
        "🐲 Drakenfyr the Inferno King / Dragon (Sea 3)",
        "👑 Abyssal Tyrant (Sea 3)",
        "🐙 Kraken (Sea 3)",
        "🦀 Cua Biển / Crab (Sea 3)",
        "🌊 Sea Event Sea 3 (bỏ Depth & Abyssal)",
        "🐍 Hydra & Rương Hydra (Sea 2)",
        "🐋 Sea King & Rương SK (Sea 2)",
        "👻 Thuyền Ma / Ghost Ship (Sea 2)",
        "🐍 Rắn Biển / Serpent (Sea 2 & 3)",
    }

    local SOLO_KEY_MAP: { [string]: string } = {
        ["👑 Depth King (Sea 3)"] = "depth_king",
        ["🐲 Drakenfyr the Inferno King / Dragon (Sea 3)"] = "dragon",
        ["👑 Abyssal Tyrant (Sea 3)"] = "abyssal_tyrant",
        ["🐙 Kraken (Sea 3)"] = "kraken",
        ["🦀 Cua Biển / Crab (Sea 3)"] = "crab",
        ["🌊 Sea Event Sea 3 (bỏ Depth & Abyssal)"] = "sea3_events",
        ["🐍 Hydra & Rương Hydra (Sea 2)"] = "hydra",
        ["🐋 Sea King & Rương SK (Sea 2)"] = "sea_king",
        ["👻 Thuyền Ma / Ghost Ship (Sea 2)"] = "ghost_ship",
        ["🐍 Rắn Biển / Serpent (Sea 2 & 3)"] = "serpent",
    }

    local function getSoloKey(opt: string): string
        return SOLO_KEY_MAP[opt] or "depth_king"
    end

    local function getSoloPlaceId(soloKey: string): number
        if soloKey == "hydra" or soloKey == "sea_king" or soloKey == "ghost_ship" then
            return SEA2_PLACE
        elseif soloKey == "serpent" then
            if game.PlaceId == SEA2_PLACE then return SEA2_PLACE end
            return SEA3_PLACE
        end
        return SEA3_PLACE
    end

    type HubState = {
        mode: string,
        soloTarget: string,
        winW: number,
        winH: number,
        autoDismiss773: boolean,
        autoReexec: boolean,
        damageMeter: boolean,
        dockX: number?,
        dockY: number?,
        -- YokaHub Native Farm Features
        autoLevel: boolean?,
        autoTakeLevelQuest: boolean?,
        selectedMob: string?,
        autoKillSelectedMob: boolean?,
        fastMobBring: boolean?,
        mobBringRange: number?,
        statMelee: boolean?,
        statDefense: boolean?,
        statSword: boolean?,
        statFruit: boolean?,
        statPointsPerTick: number?,
        selectedIsland: string?,
        autoSkills: boolean?,
        autoHaki: boolean?,
        autoKenHaki: boolean?,
        autoTransform: boolean?,
        skillAimbot: boolean?,
        autoDodge: boolean?,
        safeDistance: boolean?,
        farmSea3Mat: boolean?,
        farmSea2Mat: boolean?,
        farmSea1Mat: boolean?,
        materialQuantityTracker: boolean?,
        materialQuota: number?,
        autoDungeon: boolean?,
        dungeonMode: string?,
        -- YokaHub Fruit & Storage Features
        bringFruits: boolean?,
        storeFruits: boolean?,
        snipeShop: boolean?,
        fruitESP: boolean?,
        playerESP: boolean?,
        chestESP: boolean?,
        -- YokaHub Utility & Performance Engine
        blackScreen: boolean?,
        fastMode: boolean?,
        walkOnWater: boolean?,
        infiniteJump: boolean?,
        speedBoost: boolean?,
        clickTeleport: boolean?,
        autoAlly: boolean?,
        autoDailyQuest: boolean?,
        autoRaceRoll: boolean?,
        targetRace: string?,
        webhookUrl: string?,
        whFruit: boolean?,
        whDrop: boolean?,
        -- Advanced Auto Skills & Auto M1
        toolMode: string?,
        m1SpamList: { string }?,
        autoM1Fruit: boolean?,
        autoM1Sword: boolean?,
        autoM1Melee: boolean?,
        fastAttackNoAnim: boolean?,
        smartSkillHold: boolean?,
        dodgeSafeDistance: number?,
        flySpeed: number?,
        skillFruit: boolean?,
        skillFruitKeys: string?,
        fruitSkillsList: { string }?,
        skillSword: boolean?,
        skillSwordKeys: string?,
        swordSkillsList: { string }?,
        skillMelee: boolean?,
        skillMeleeKeys: string?,
        meleeSkillsList: { string }?,
        -- Advanced Materials
        nguyenlieuSea3: string?,
        nguyenlieuSea2: string?,
        nguyenlieuSea1: string?,
        -- Advanced Dungeon & Raid
        dungeonTactics: string?,
        dungeonAutoHeal: boolean?,
        dungeonHealThreshold: number?,
        dungeonCameraLock: boolean?,
        dungeonSafeHeight: number?,
        dungeonMobBring: boolean?,
        dungeonBringRange: number?,
        dungeonAutoCollectChest: boolean?,
        dungeonAutoReplay: boolean?,
        dungeonEmergencyFlight: boolean?,
        dungeonAutoHaki: boolean?,
        dungeonAutoJoin: boolean?,
        dungeonWeaponMode: string?,
        -- Advanced Shop Sniper & Gacha
        snipeFruit: string?,
        snipeFruitList: { string }?,
        snipeDelay: number?,
        autoGachaFruitBeli: boolean?,
        autoGachaFruitGem: boolean?,
        selectedUnstoreFruit: string?,
        -- Auto Fishing
        autoClickPlay: boolean?,
        autoFish: boolean?,
        fishWeapon: string?,
        fishFloat: boolean?,
        autoReel: boolean?,
        perfectCatch: boolean?,
        fishCastDelay: number?,
        fishReelDelay: number?,
        autoSellFish: boolean?,
        sellCommonFish: boolean?,
        sellRareFish: boolean?,
        sellEpicFish: boolean?,
        lockLegendaryFish: boolean?,
        autoBuyBait: boolean?,
        fishLocation: string?,
        -- Boss & Sea Events Boards
        autoFightMaster: boolean?,
        autoFightSeaEvent: boolean?,
        autoCollectChest: boolean?,
        bossSafeHeight: number?,
        smartBossHeight: boolean?,
        ignoreKraken: boolean?,
        ignoreGalleon: boolean?,
        fightSea3DepthKing: boolean?,
        fightSea3Dragon: boolean?,
        fightSea3Abyssal: boolean?,
        fightSea3Kraken: boolean?,
        fightSea3Crab: boolean?,
        fightSea3Events: boolean?,
        fightSea2Hydra: boolean?,
        fightSea2SeaKing: boolean?,
        fightSea2GhostShip: boolean?,
        fightSea2Serpent: boolean?,
        autoFightIslandBoss: boolean?,
        islandBossTarget: string?,
        autoTakeBossQuest: boolean?,
        antiAfk19m: boolean?,
    }

    local function loadState(): HubState
        local st: HubState = {
            mode = "off",
            soloTarget = SOLO_OPTIONS[1],
            winW = 720,
            winH = 450,
            autoDismiss773 = true,
            autoReexec = true,
            damageMeter = false,
            dockX = nil,
            dockY = nil,
            autoLevel = false,
            autoTakeLevelQuest = true,
            selectedMob = "Elite Skeleton [Lv. 3100]",
            autoKillSelectedMob = false,
            fastMobBring = true,
            mobBringRange = 800,
            statMelee = false,
            statDefense = false,
            statSword = false,
            statFruit = false,
            statPointsPerTick = 5,
            selectedIsland = "🏝️ [Sea 1] Đảo Hải Tặc Đầu Tiên (Pirate Island)",
            autoSkills = true,
            autoHaki = true,
            autoKenHaki = true,
            autoTransform = true,
            skillAimbot = true,
            autoDodge = true,
            safeDistance = true,
            farmSea3Mat = false,
            farmSea2Mat = false,
            farmSea1Mat = false,
            materialQuantityTracker = false,
            materialQuota = 50,
            autoDungeon = false,
            dungeonMode = "Easy (Dễ - Phù Hợp Cày Nhanh)",
            bringFruits = false,
            storeFruits = true,
            snipeShop = false,
            fruitESP = false,
            playerESP = false,
            chestESP = false,
            blackScreen = false,
            fastMode = false,
            walkOnWater = true,
            infiniteJump = false,
            speedBoost = false,
            clickTeleport = false,
            autoAlly = true,
            autoDailyQuest = false,
            autoRaceRoll = false,
            targetRace = "Cyborg",
            webhookUrl = "",
            whFruit = false,
            whDrop = false,
            toolMode = "Auto Mode",
            m1SpamList = { "Sword M1", "Melee M1", "Fruit M1" },
            autoM1Fruit = true,
            autoM1Sword = true,
            autoM1Melee = true,
            fastAttackNoAnim = true,
            smartSkillHold = true,
            dodgeSafeDistance = 95,
            flySpeed = 420,
            skillFruit = true,
            skillFruitKeys = "Z + X",
            fruitSkillsList = { "Z", "X", "C", "E" },
            skillSword = true,
            skillSwordKeys = "Z + X",
            swordSkillsList = { "Z", "X" },
            skillMelee = true,
            skillMeleeKeys = "Toàn Bộ (Z, X, C, V, E)",
            meleeSkillsList = { "Z", "X", "C", "V" },
            nguyenlieuSea3 = "Coral (San Hô)",
            nguyenlieuSea2 = "Iron Ingot (Sắt Thỏi)",
            nguyenlieuSea1 = "Leather (Da Thuộc)",
            dungeonTactics = "⚡ Fast Sweep (Quét Siêu Tốc 8m / Gom Quái Tối Đa)",
            dungeonAutoHeal = true,
            dungeonHealThreshold = 80,
            dungeonCameraLock = false,
            dungeonSafeHeight = 16,
            dungeonMobBring = true,
            dungeonBringRange = 600,
            dungeonAutoCollectChest = true,
            dungeonAutoReplay = true,
            dungeonEmergencyFlight = true,
            dungeonAutoHaki = true,
            dungeonAutoJoin = true,
            dungeonWeaponMode = "Auto Mode (Tự Động Theo Tab Chiêu Thức)",
            snipeFruit = "⭐ Toàn Bộ Trái Thần Thoại & Cực Hiếm (Mythic + Legendary)",
            snipeFruitList = { "Dragon", "Phoenix", "Gate", "Dough", "Erebus" },
            snipeDelay = 5,
            autoGachaFruitBeli = false,
            autoGachaFruitGem = false,
            selectedUnstoreFruit = "Dragon",
            autoClickPlay = true,
            autoFish = false,
            fishWeapon = "True Muramasa (Khuyên Dùng - Tốc Độ Cao)",
            fishFloat = true,
            autoReel = true,
            perfectCatch = true,
            fishCastDelay = 1.8,
            fishReelDelay = 0.45,
            autoSellFish = false,
            sellCommonFish = true,
            sellRareFish = true,
            sellEpicFish = false,
            lockLegendaryFish = true,
            autoBuyBait = false,
            fishLocation = "Tự do (Vị trí hiện tại)",
            autoFightMaster = true,
            autoFightSeaEvent = true,
            autoCollectChest = true,
            bossSafeHeight = 35,
            smartBossHeight = true,
            ignoreKraken = false,
            ignoreGalleon = false,
            fightSea3DepthKing = false,
            fightSea3Dragon = false,
            fightSea3Abyssal = false,
            fightSea3Kraken = false,
            fightSea3Crab = false,
            fightSea3Events = false,
            fightSea2Hydra = false,
            fightSea2SeaKing = false,
            fightSea2GhostShip = false,
            fightSea2Serpent = false,
            autoFightIslandBoss = false,
            islandBossTarget = "Hephaestus (Thợ Rèn Thần - Sea 3)",
            autoTakeBossQuest = true,
            antiAfk19m = true,
        }
        local d = readJson(stateFile)
        if typeof(d) == "table" then
            if d.mode == "sea3" or d.mode == "sea2" or d.mode == "solo" or d.mode == "off" then
                st.mode = d.mode
            elseif d.mode == "depth_king" then
                st.mode = "solo"
                st.soloTarget = SOLO_OPTIONS[1]
            end
            if typeof(d.soloTarget) == "string" and SOLO_KEY_MAP[d.soloTarget] ~= nil then
                st.soloTarget = d.soloTarget
            end
            if typeof(d.winW) == "number" and d.winW >= 360 and d.winW <= 3840 then st.winW = math.floor(d.winW) end
            if typeof(d.winH) == "number" and d.winH >= 240 and d.winH <= 2160 then st.winH = math.floor(d.winH) end
            if typeof(d.autoDismiss773) == "boolean" then st.autoDismiss773 = d.autoDismiss773 end
            if typeof(d.autoReexec) == "boolean" then st.autoReexec = d.autoReexec end
            if typeof(d.damageMeter) == "boolean" then st.damageMeter = d.damageMeter end
            if typeof(d.dockX) == "number" and typeof(d.dockY) == "number" then
                st.dockX = d.dockX
                st.dockY = d.dockY
            end
            if typeof(d.autoLevel) == "boolean" then st.autoLevel = d.autoLevel end
            if typeof(d.autoTakeLevelQuest) == "boolean" then st.autoTakeLevelQuest = d.autoTakeLevelQuest end
            if typeof(d.selectedMob) == "string" then st.selectedMob = d.selectedMob end
            if typeof(d.autoKillSelectedMob) == "boolean" then st.autoKillSelectedMob = d.autoKillSelectedMob end
            if typeof(d.fastMobBring) == "boolean" then st.fastMobBring = d.fastMobBring end
            if typeof(d.mobBringRange) == "number" then st.mobBringRange = math.clamp(math.floor(d.mobBringRange), 100, 1200) end
            if typeof(d.statMelee) == "boolean" then st.statMelee = d.statMelee end
            if typeof(d.statDefense) == "boolean" then st.statDefense = d.statDefense end
            if typeof(d.statSword) == "boolean" then st.statSword = d.statSword end
            if typeof(d.statFruit) == "boolean" then st.statFruit = d.statFruit end
            if typeof(d.statPointsPerTick) == "number" then st.statPointsPerTick = d.statPointsPerTick end
            if typeof(d.selectedIsland) == "string" then st.selectedIsland = d.selectedIsland end
            if typeof(d.autoSkills) == "boolean" then st.autoSkills = d.autoSkills end
            if typeof(d.autoHaki) == "boolean" then st.autoHaki = d.autoHaki end
            if typeof(d.autoKenHaki) == "boolean" then st.autoKenHaki = d.autoKenHaki end
            if typeof(d.autoTransform) == "boolean" then st.autoTransform = d.autoTransform end
            if typeof(d.skillAimbot) == "boolean" then st.skillAimbot = d.skillAimbot end
            if typeof(d.autoDodge) == "boolean" then st.autoDodge = d.autoDodge end
            if typeof(d.safeDistance) == "boolean" then st.safeDistance = d.safeDistance end
            if typeof(d.farmSea3Mat) == "boolean" then st.farmSea3Mat = d.farmSea3Mat end
            if typeof(d.farmSea2Mat) == "boolean" then st.farmSea2Mat = d.farmSea2Mat end
            if typeof(d.farmSea1Mat) == "boolean" then st.farmSea1Mat = d.farmSea1Mat end
            if typeof(d.materialQuantityTracker) == "boolean" then st.materialQuantityTracker = d.materialQuantityTracker end
            if typeof(d.materialQuota) == "number" then st.materialQuota = math.clamp(math.floor(d.materialQuota), 5, 1000) end
            if typeof(d.autoDungeon) == "boolean" then st.autoDungeon = d.autoDungeon end
            if typeof(d.dungeonMode) == "string" then st.dungeonMode = d.dungeonMode end
            if typeof(d.bringFruits) == "boolean" then st.bringFruits = d.bringFruits end
            if typeof(d.storeFruits) == "boolean" then st.storeFruits = d.storeFruits end
            if typeof(d.snipeShop) == "boolean" then st.snipeShop = d.snipeShop end
            if typeof(d.fruitESP) == "boolean" then st.fruitESP = d.fruitESP end
            if typeof(d.playerESP) == "boolean" then st.playerESP = d.playerESP end
            if typeof(d.chestESP) == "boolean" then st.chestESP = d.chestESP end
            if typeof(d.blackScreen) == "boolean" then st.blackScreen = d.blackScreen end
            if typeof(d.fastMode) == "boolean" then st.fastMode = d.fastMode end
            if typeof(d.walkOnWater) == "boolean" then st.walkOnWater = d.walkOnWater end
            if typeof(d.infiniteJump) == "boolean" then st.infiniteJump = d.infiniteJump end
            if typeof(d.speedBoost) == "boolean" then st.speedBoost = d.speedBoost end
            if typeof(d.clickTeleport) == "boolean" then st.clickTeleport = d.clickTeleport end
            if typeof(d.autoAlly) == "boolean" then st.autoAlly = d.autoAlly end
            if typeof(d.autoDailyQuest) == "boolean" then st.autoDailyQuest = d.autoDailyQuest end
            if typeof(d.autoRaceRoll) == "boolean" then st.autoRaceRoll = d.autoRaceRoll end
            if typeof(d.targetRace) == "string" and d.targetRace ~= "" then st.targetRace = d.targetRace end
            if typeof(d.webhookUrl) == "string" then st.webhookUrl = d.webhookUrl end
            if typeof(d.whFruit) == "boolean" then st.whFruit = d.whFruit end
            if typeof(d.whDrop) == "boolean" then st.whDrop = d.whDrop end
            if typeof(d.autoM1Fruit) == "boolean" then st.autoM1Fruit = d.autoM1Fruit end
            if typeof(d.autoM1Sword) == "boolean" then st.autoM1Sword = d.autoM1Sword end
            if typeof(d.autoM1Melee) == "boolean" then st.autoM1Melee = d.autoM1Melee end
            if typeof(d.fastAttackNoAnim) == "boolean" then st.fastAttackNoAnim = d.fastAttackNoAnim end
            if typeof(d.smartSkillHold) == "boolean" then st.smartSkillHold = d.smartSkillHold end
            if typeof(d.dodgeSafeDistance) == "number" then st.dodgeSafeDistance = math.clamp(math.floor(d.dodgeSafeDistance), 40, 180) end
            if typeof(d.flySpeed) == "number" then st.flySpeed = math.clamp(math.floor(d.flySpeed), 200, 650) end
            if typeof(d.skillFruit) == "boolean" then st.skillFruit = d.skillFruit end
            if typeof(d.skillFruitKeys) == "string" then st.skillFruitKeys = d.skillFruitKeys end
            if typeof(d.skillSword) == "boolean" then st.skillSword = d.skillSword end
            if typeof(d.skillSwordKeys) == "string" then st.skillSwordKeys = d.skillSwordKeys end
            if typeof(d.skillMelee) == "boolean" then st.skillMelee = d.skillMelee end
            if typeof(d.skillMeleeKeys) == "string" then st.skillMeleeKeys = d.skillMeleeKeys end
            if typeof(d.nguyenlieuSea3) == "string" then st.nguyenlieuSea3 = d.nguyenlieuSea3 end
            if typeof(d.nguyenlieuSea2) == "string" then st.nguyenlieuSea2 = d.nguyenlieuSea2 end
            if typeof(d.nguyenlieuSea1) == "string" then st.nguyenlieuSea1 = d.nguyenlieuSea1 end
            if typeof(d.dungeonTactics) == "string" then st.dungeonTactics = d.dungeonTactics end
            if typeof(d.dungeonAutoHeal) == "boolean" then st.dungeonAutoHeal = d.dungeonAutoHeal end
            if typeof(d.dungeonHealThreshold) == "number" then st.dungeonHealThreshold = d.dungeonHealThreshold end
            if typeof(d.dungeonCameraLock) == "boolean" then st.dungeonCameraLock = d.dungeonCameraLock end
            if typeof(d.dungeonSafeHeight) == "number" then st.dungeonSafeHeight = d.dungeonSafeHeight end
            if typeof(d.dungeonMobBring) == "boolean" then st.dungeonMobBring = d.dungeonMobBring end
            if typeof(d.dungeonBringRange) == "number" then st.dungeonBringRange = d.dungeonBringRange end
            if typeof(d.dungeonAutoCollectChest) == "boolean" then st.dungeonAutoCollectChest = d.dungeonAutoCollectChest end
            if typeof(d.dungeonAutoReplay) == "boolean" then st.dungeonAutoReplay = d.dungeonAutoReplay end
            if typeof(d.dungeonEmergencyFlight) == "boolean" then st.dungeonEmergencyFlight = d.dungeonEmergencyFlight end
            if typeof(d.dungeonAutoHaki) == "boolean" then st.dungeonAutoHaki = d.dungeonAutoHaki end
            if typeof(d.dungeonAutoJoin) == "boolean" then st.dungeonAutoJoin = d.dungeonAutoJoin end
            if typeof(d.dungeonWeaponMode) == "string" then st.dungeonWeaponMode = d.dungeonWeaponMode end
            if typeof(d.snipeFruit) == "string" then st.snipeFruit = d.snipeFruit end
            if typeof(d.snipeFruitList) == "table" then st.snipeFruitList = d.snipeFruitList end
            if typeof(d.snipeDelay) == "number" then st.snipeDelay = d.snipeDelay end
            if typeof(d.autoGachaFruitBeli) == "boolean" then st.autoGachaFruitBeli = d.autoGachaFruitBeli end
            if typeof(d.autoGachaFruitGem) == "boolean" then st.autoGachaFruitGem = d.autoGachaFruitGem end
            if typeof(d.selectedUnstoreFruit) == "string" then st.selectedUnstoreFruit = d.selectedUnstoreFruit end
            if typeof(d.autoClickPlay) == "boolean" then st.autoClickPlay = d.autoClickPlay end
            if typeof(d.autoFish) == "boolean" then st.autoFish = d.autoFish end
            if typeof(d.fishWeapon) == "string" then st.fishWeapon = d.fishWeapon end
            if typeof(d.fishFloat) == "boolean" then st.fishFloat = d.fishFloat end
            if typeof(d.autoReel) == "boolean" then st.autoReel = d.autoReel end
            if typeof(d.perfectCatch) == "boolean" then st.perfectCatch = d.perfectCatch end
            if typeof(d.fishCastDelay) == "number" then st.fishCastDelay = d.fishCastDelay end
            if typeof(d.fishReelDelay) == "number" then st.fishReelDelay = d.fishReelDelay end
            if typeof(d.autoSellFish) == "boolean" then st.autoSellFish = d.autoSellFish end
            if typeof(d.sellCommonFish) == "boolean" then st.sellCommonFish = d.sellCommonFish end
            if typeof(d.sellRareFish) == "boolean" then st.sellRareFish = d.sellRareFish end
            if typeof(d.sellEpicFish) == "boolean" then st.sellEpicFish = d.sellEpicFish end
            if typeof(d.lockLegendaryFish) == "boolean" then st.lockLegendaryFish = d.lockLegendaryFish end
            if typeof(d.autoBuyBait) == "boolean" then st.autoBuyBait = d.autoBuyBait end
            if typeof(d.fishLocation) == "string" then st.fishLocation = d.fishLocation end
            if typeof(d.autoFightMaster) == "boolean" then st.autoFightMaster = d.autoFightMaster end
            if typeof(d.autoFightSeaEvent) == "boolean" then st.autoFightSeaEvent = d.autoFightSeaEvent end
            if typeof(d.autoCollectChest) == "boolean" then st.autoCollectChest = d.autoCollectChest end
            if typeof(d.bossSafeHeight) == "number" then st.bossSafeHeight = math.clamp(math.floor(d.bossSafeHeight), 10, 150) end
            if typeof(d.smartBossHeight) == "boolean" then st.smartBossHeight = d.smartBossHeight end
            if typeof(d.ignoreKraken) == "boolean" then st.ignoreKraken = d.ignoreKraken end
            if typeof(d.ignoreGalleon) == "boolean" then st.ignoreGalleon = d.ignoreGalleon end
            if typeof(d.fightSea3DepthKing) == "boolean" then st.fightSea3DepthKing = d.fightSea3DepthKing end
            if typeof(d.fightSea3Dragon) == "boolean" then st.fightSea3Dragon = d.fightSea3Dragon end
            if typeof(d.fightSea3Abyssal) == "boolean" then st.fightSea3Abyssal = d.fightSea3Abyssal end
            if typeof(d.fightSea3Kraken) == "boolean" then st.fightSea3Kraken = d.fightSea3Kraken end
            if typeof(d.fightSea3Crab) == "boolean" then st.fightSea3Crab = d.fightSea3Crab end
            if typeof(d.fightSea3Events) == "boolean" then st.fightSea3Events = d.fightSea3Events end
            if typeof(d.fightSea2Hydra) == "boolean" then st.fightSea2Hydra = d.fightSea2Hydra end
            if typeof(d.fightSea2SeaKing) == "boolean" then st.fightSea2SeaKing = d.fightSea2SeaKing end
            if typeof(d.fightSea2GhostShip) == "boolean" then st.fightSea2GhostShip = d.fightSea2GhostShip end
            if typeof(d.fightSea2Serpent) == "boolean" then st.fightSea2Serpent = d.fightSea2Serpent end
            if typeof(d.autoFightIslandBoss) == "boolean" then st.autoFightIslandBoss = d.autoFightIslandBoss end
            if typeof(d.islandBossTarget) == "string" then st.islandBossTarget = d.islandBossTarget end
            if typeof(d.autoTakeBossQuest) == "boolean" then st.autoTakeBossQuest = d.autoTakeBossQuest end
            if typeof(d.antiAfk19m) == "boolean" then st.antiAfk19m = d.antiAfk19m end
            if typeof(d.toolMode) == "string" then st.toolMode = d.toolMode end
            if typeof(d.m1SpamList) == "table" then
                st.m1SpamList = d.m1SpamList
                st.autoM1Sword = table.find(d.m1SpamList, "Sword M1") ~= nil
                st.autoM1Melee = table.find(d.m1SpamList, "Melee M1") ~= nil
                st.autoM1Fruit = table.find(d.m1SpamList, "Fruit M1") ~= nil
            else
                local mList = {}
                if st.autoM1Sword then table.insert(mList, "Sword M1") end
                if st.autoM1Melee then table.insert(mList, "Melee M1") end
                if st.autoM1Fruit then table.insert(mList, "Fruit M1") end
                st.m1SpamList = mList
            end
            if typeof(d.swordSkillsList) == "table" then st.swordSkillsList = d.swordSkillsList end
            if typeof(d.meleeSkillsList) == "table" then st.meleeSkillsList = d.meleeSkillsList end
            if typeof(d.fruitSkillsList) == "table" then st.fruitSkillsList = d.fruitSkillsList end
        end
        return st
    end

    local function saveState(st: HubState)
        writeJson(stateFile, st)
    end

    type SessionData = {
        startTime: number,
        startGems: number,
        startBeli: number,
        hops: number,
    }

    local function loadSession(): SessionData
        local cur = getPlayerStats()
        local now = os.time()
        local d = readJson(sessionFile)
        if typeof(d) == "table" and typeof(d.startTime) == "number" and (now - d.startTime) < 86400 then
            return {
                startTime = d.startTime,
                startGems = tonumber(d.startGems) or cur.gems,
                startBeli = tonumber(d.startBeli) or cur.beli,
                hops = tonumber(d.hops) or 0,
            }
        end
        local fresh: SessionData = { startTime = now, startGems = cur.gems, startBeli = cur.beli, hops = 0 }
        writeJson(sessionFile, fresh)
        return fresh
    end

    local visitedCache: { [string]: { [string]: number } } = {}
    local function loadVisited(filePath: string): { [string]: number }
        local now = os.time()
        local cached = visitedCache[filePath]
        if cached then
            for k, ts in pairs(cached) do
                if (now - ts) >= visitedTTL then cached[k] = nil end
            end
            return cached
        end
        local res: { [string]: number } = {}
        local decoded = readJson(filePath)
        if typeof(decoded) == "table" then
            for k, ts in pairs(decoded) do
                if typeof(ts) == "number" and (now - ts) < visitedTTL then
                    res[tostring(k)] = ts
                end
            end
        end
        visitedCache[filePath] = res
        return res
    end

    local function saveVisited(filePath: string, tbl: { [string]: number })
        visitedCache[filePath] = tbl
        writeJson(filePath, tbl)
    end

