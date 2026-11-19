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
    if not players.LocalPlayer then return end

    local genv: any = getgenv()
    local httpService = game:GetService("HttpService")
    local teleportService = game:GetService("TeleportService")
    local userInputService = game:GetService("UserInputService")
    local tweenService = game:GetService("TweenService")
    local guiService = game:GetService("GuiService")
    local runService = game:GetService("RunService")
    local lighting = game:GetService("Lighting")
    local coreGui = game:GetService("CoreGui")

