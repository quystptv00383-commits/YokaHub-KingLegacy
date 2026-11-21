-- ========================================================
-- [YOKAHUB] - KING LEGACY (SACH SE · DE NHIN · CHUAN PRO)
-- 4 Tab: San Boss | Do Farm | Tien ich | Ung ho
-- 1 Tong mau thong nhat (Obsidian + Xanh Ngoc) · Khong blur · Full man hinh + Keo gian tu do
-- ========================================================

if game.GameId ~= 1451439645 then
    return
end

task.spawn(function()
    if not game:IsLoaded() then
        pcall(function() game.Loaded:Wait() end)
    end
    local players = game:GetService("Players")
    local initStart = os.clock()
    while not players.LocalPlayer and (os.clock() - initStart) < 15.0 do
        task.wait(0.2)
    end
    local player = players.LocalPlayer
    if not player then return end

    local genv: any = getgenv()
    genv._YokaHub_IsEmbedded = true
    local httpService = game:GetService("HttpService")
    local teleportService = game:GetService("TeleportService")
    local userInputService = game:GetService("UserInputService")
    local tweenService = game:GetService("TweenService")
    local guiService = game:GetService("GuiService")
    local runService = game:GetService("RunService")
    local lighting = game:GetService("Lighting")
    local coreGui = game:GetService("CoreGui")
    local sharedRS = game:GetService("ReplicatedStorage")

    -- ========================================================
    -- [INSTANT AUTO-PLAY ENGINE] - TU DONG VAO GAME NGAY KHI VAO SERVER / HOP SERVER
    -- ========================================================
    local function triggerKingLegacyAutoPlay(checkState: (() -> boolean)?)
        task.spawn(function()
            local maxWait = 45
            local startClock = os.clock()
            local enteredAt = 0
            while (os.clock() - startClock) < maxWait do
                task.wait(0.25)
                if checkState and not checkState() then
                    break
                end

                local pgui = player:FindFirstChild("PlayerGui")
                local loadingGui = pgui and pgui:FindFirstChild("LoadingGUI")
                local isPlaying = (player:GetAttribute("Playing") == true)

                if isPlaying and not loadingGui then
                    -- Đảm bảo nhân vật đã được gỡ neo và giao diện chính đã bật hoàn toàn
                    pcall(function()
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and hrp.Anchored then hrp.Anchored = false end
                        local cam = workspace.CurrentCamera
                        if cam and cam.CameraType == Enum.CameraType.Scriptable then
                            cam.CameraType = Enum.CameraType.Custom
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if hum then cam.CameraSubject = hum end
                        end
                        local tb = lighting:FindFirstChild("TeamBlur")
                        if tb then tb:Destroy() end
                        if pgui then
                            for _, gName in ipairs({ "MainGui", "Backpack", "SkillCooldown", "Popup" }) do
                                local sg = pgui:FindFirstChild(gName)
                                if sg and sg:IsA("ScreenGui") then sg.Enabled = true end
                            end
                        end
                    end)
                    break
                end

                -- Nếu đã bấm Play và Playing == true nhưng LoadingGUI vẫn còn đang đóng, chờ tối đa 2.5s rồi dọn sạch
                if isPlaying and loadingGui then
                    if enteredAt == 0 then enteredAt = os.clock() end
                    if (os.clock() - enteredAt) > 2.5 then
                        pcall(function()
                            loadingGui:Destroy()
                            local tb = lighting:FindFirstChild("TeamBlur")
                            if tb then tb:Destroy() end
                            if pgui then
                                for _, gName in ipairs({ "MainGui", "Backpack", "SkillCooldown", "Popup" }) do
                                    local sg = pgui:FindFirstChild(gName)
                                    if sg and sg:IsA("ScreenGui") then sg.Enabled = true end
                                end
                            end
                        end)
                        break
                    end
                    continue
                end

                -- Chờ DataLoaded tồn tại và StartLoadingScreen đã khởi tạo TeamBlur / LoadingGUI
                local dataLoadedObj = player:FindFirstChild("DataLoaded")
                local teamBlur = lighting:FindFirstChild("TeamBlur")
                local elapsed = os.clock() - startClock
                if not dataLoadedObj and elapsed < 12.0 then
                    continue
                end
                if loadingGui and not teamBlur and elapsed < 6.0 then
                    continue
                end

                pcall(function()
                    local clicked = false
                    if loadingGui then
                        local playBtn = loadingGui:FindFirstChild("Play") or loadingGui:FindFirstChild("Play", true)
                        if playBtn and playBtn:IsA("GuiButton") then
                            playBtn.Visible = true
                            playBtn.Active = true
                            if playBtn.Size.X.Scale < 0.05 and playBtn.Size.X.Offset < 10 then
                                playBtn.Size = UDim2.new(0.211, 0, 0.107, 0)
                            end

                            if typeof(getconnections) == "function" then
                                local okC, conns = pcall(getconnections, playBtn.MouseButton1Click)
                                if okC and typeof(conns) == "table" and #conns > 0 then
                                    for _, c in ipairs(conns) do
                                        pcall(function()
                                            if typeof(c.Fire) == "function" then c:Fire()
                                            elseif typeof(c.Function) == "function" then task.spawn(c.Function) end
                                        end)
                                    end
                                    clicked = true
                                end
                            end

                            if typeof(firesignal) == "function" then
                                pcall(function() firesignal(playBtn.MouseButton1Click) end)
                                pcall(function() firesignal(playBtn.Activated) end)
                                clicked = true
                            end

                            if not clicked and playBtn.AbsoluteSize.X > 10 and playBtn.AbsoluteSize.Y > 10 then
                                local vim = game:GetService("VirtualInputManager")
                                if vim then
                                    local cx = playBtn.AbsolutePosition.X + playBtn.AbsoluteSize.X / 2
                                    local cy = playBtn.AbsolutePosition.Y + playBtn.AbsoluteSize.Y / 2
                                    pcall(function()
                                        vim:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                                        task.wait(0.04)
                                        vim:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                                    end)
                                    clicked = true
                                end
                            end
                        end
                    end

                    -- Dự phòng gọi thẳng Remote EnterTheGame chính thức của King Legacy nếu nút chưa kích hoạt Playing
                    if player:GetAttribute("Playing") ~= true and (clicked or elapsed > 3.5) then
                        task.wait(0.2)
                        if player:GetAttribute("Playing") ~= true then
                            local rs = game:GetService("ReplicatedStorage")
                            local chest = rs:FindFirstChild("Chest")
                            local remFuncs = chest and chest:FindFirstChild("Remotes") and chest.Remotes:FindFirstChild("Functions")
                            local etcFunc = remFuncs and remFuncs:FindFirstChild("EtcFunction")
                            if etcFunc then
                                pcall(function() etcFunc:InvokeServer("EnterTheGame", {}) end)
                            end
                        end
                    end
                end)
                task.wait(0.6)
            end
        end)
    end

    -- Kích hoạt ngay lập tức khi vừa vào Server (nếu người dùng không tắt autoClickPlay trong file cấu hình)
    triggerKingLegacyAutoPlay(function()
        local rfFn = genv.readfile or readfile
        local isfFn = genv.isfile or isfile
        if typeof(isfFn) == "function" and typeof(rfFn) == "function" then
            local okE, ex = pcall(isfFn, "YokaHub_State.json")
            if okE and ex then
                local okR, raw = pcall(rfFn, "YokaHub_State.json")
                if okR and typeof(raw) == "string" and string.find(raw, '"autoClickPlay":false', 1, true) then
                    return false
                end
            end
        end
        return true
    end)

