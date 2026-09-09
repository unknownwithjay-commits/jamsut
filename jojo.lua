local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

-- Safe GUI Parent untuk Delta Android
local function GetSafeGuiParent()
    local ok, res = pcall(function()
        if gethui then return gethui() end
        return game:GetService("CoreGui")
    end)
    if ok and res then return res end
    return player:WaitForChild("PlayerGui")
end

local CoreGui = GetSafeGuiParent()

pcall(function()
    if CoreGui:FindFirstChild("ERDEVA_HUB") then CoreGui:FindFirstChild("ERDEVA_HUB"):Destroy() end
    if CoreGui:FindFirstChild("ERDEVA_KEY") then CoreGui:FindFirstChild("ERDEVA_KEY"):Destroy() end
end)

local API_URL = "http://78.154.103.42:9458"
local LOGO_URL = "https://raw.githubusercontent.com/voxynoxy/ErdevaHub/main/icon.png"
local LOGO_FILE = "icon.png"
local KEY_FILE = "erdeva_saved_key.txt"

local LogoAssetId = nil
pcall(function()
    if not isfile or not writefile or not getcustomasset then return end
    if not isfile(LOGO_FILE) then
        local imgData = game:HttpGet(LOGO_URL)
        if imgData and #imgData > 100 then
            writefile(LOGO_FILE, imgData)
        end
    end
    if isfile(LOGO_FILE) then
        LogoAssetId = getcustomasset(LOGO_FILE)
    end
end)

local C = {
    Bg        = Color3.fromRGB(13, 14, 18),
    Top       = Color3.fromRGB(18, 20, 26),
    TabBg     = Color3.fromRGB(16, 18, 24),
    Card      = Color3.fromRGB(20, 23, 31),
    CardHover = Color3.fromRGB(26, 30, 42),
    Red       = Color3.fromRGB(235, 45, 65),
    RedGlow   = Color3.fromRGB(255, 60, 80),
    Txt       = Color3.fromRGB(245, 245, 250),
    Sub       = Color3.fromRGB(135, 142, 160),
    Border    = Color3.fromRGB(32, 36, 48),
    Off       = Color3.fromRGB(36, 40, 54),
    Green     = Color3.fromRGB(46, 204, 113),
}

local function tw(o, p, t)
    TweenService:Create(o, TweenInfo.new(t or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local function Notify(title, desc, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = desc, Duration = duration or 4 })
    end)
end

RunService.Stepped:Connect(function()
    pcall(function()
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end)

local function SafeCall(remoteName, ...)
    local r = rs:FindFirstChild(remoteName, true)
    if not r then return false end
    local args = {...}
    local ok = pcall(function()
        if r:IsA("RemoteFunction") then
            return r:InvokeServer(table.unpack(args))
        elseif r:IsA("RemoteEvent") then
            r:FireServer(table.unpack(args))
            return true
        end
    end)
    return ok
end

local function ClickGuiButton(btn)
    if not btn or not btn.Parent then return false end
    pcall(function()
        if getconnections then
            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
                if type(c) == "table" and type(c.Fire) == "function" then c:Fire() end
            end
            for _, c in ipairs(getconnections(btn.Activated)) do
                if type(c) == "table" and type(c.Fire) == "function" then c:Fire() end
            end
        end
        if firesignal then
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
        end
    end)
    return true
end

local function ButtonText(btn)
    if not btn then return "" end
    local full = ((btn:IsA("TextButton") and btn.Text) or "") .. " " .. btn.Name
    for _, child in ipairs(btn:GetDescendants()) do
        if child:IsA("TextLabel") then
            full = full .. " " .. child.Text
        end
    end
    return full:lower()
end

local function IsVisibleGui(obj)
    if not obj:IsA("GuiObject") or not obj.Visible then return false end
    local cur = obj.Parent
    while cur and cur:IsA("GuiObject") do
        if not cur.Visible then return false end
        cur = cur.Parent
    end
    return true
end

local GuiCooldowns = {}
local function TryClickGuiAction(actionName, patterns, cooldown)
    local now = tick()
    if GuiCooldowns[actionName] and now - GuiCooldowns[actionName] < (cooldown or 1.0) then return false end
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, b in ipairs(pg:GetDescendants()) do
        if (b:IsA("TextButton") or b:IsA("ImageButton")) and IsVisibleGui(b) then
            local text = ButtonText(b)
            for _, pat in ipairs(patterns) do
                if text:find(pat) then
                    GuiCooldowns[actionName] = now
                    return ClickGuiButton(b)
                end
            end
        end
    end
    return false
end

local function DismissPopups()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    local clicked = false
    for _, gui in ipairs(pg:GetDescendants()) do
        if gui:IsA("GuiObject") and IsVisibleGui(gui) then
            local text = (gui:IsA("TextLabel") and gui.Text:lower()) or ""
            local name = gui.Name:lower()
            if text:find("not enough") or name:find("notenoughcash") or text:find("insufficient") then
                local container = gui.Parent
                while container and container ~= pg do
                    for _, b in ipairs(container:GetDescendants()) do
                        if (b:IsA("TextButton") or b:IsA("ImageButton")) and IsVisibleGui(b) then
                            local bt = ButtonText(b)
                            if bt:find("x") or bt:find("close") or b.Name:lower() == "x" or b.Name:lower() == "close" then
                                clicked = ClickGuiButton(b) or clicked
                            end
                        end
                    end
                    container = container.Parent
                end
            end
        end
    end
    return clicked
end

local function DismissArenaResults()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") and IsVisibleGui(obj) then
            local t = obj.Text:lower()
            if t:find("defeated") or t:find("victory") or t:find("trophies") then
                local cur = obj.Parent
                while cur and cur ~= pg do
                    for _, b in ipairs(cur:GetDescendants()) do
                        if (b:IsA("TextButton") or b:IsA("ImageButton")) and IsVisibleGui(b) then
                            ClickGuiButton(b)
                            return true
                        end
                    end
                    if cur:IsA("GuiButton") and IsVisibleGui(cur) then
                        ClickGuiButton(cur)
                        return true
                    end
                    cur = cur.Parent
                end
            end
        end
    end
    return false
end

-- [[ LOAD DATABASE AYAM DARI REPLICATEDSTORAGE ]] --
local ChickenDatabase = {}
pcall(function()
    local cTypesMod = rs:FindFirstChild("Content") and rs.Content:FindFirstChild("Catalog") and rs.Content.Catalog:FindFirstChild("ChickenTypes")
    if not cTypesMod then cTypesMod = rs:FindFirstChild("ChickenTypes", true) end
    if cTypesMod then
        local raw = require(cTypesMod)
        if type(raw) == "table" then
            for id, info in pairs(raw) do
                if type(info) == "table" then
                    local r = tostring(info.Rarity or info.rarity or "common"):lower()
                    local dName = tostring(info.Name or info.DisplayName or info.name or id):lower()
                    ChickenDatabase[dName] = r
                    ChickenDatabase[tostring(id):lower()] = r
                end
            end
        end
    end
end)

local StartMainScript
local LaunchKeyUI

local function RequestValidation(keyText)
    local u = player.Name
    local reqUrl = API_URL .. "/validate?key=" .. keyText .. "&username=" .. u
    local ok, res = pcall(function() return game:HttpGet(reqUrl) end)
    if not ok or not res then return false, "Connection to server failed!" end
    local parseOk, data = pcall(function() return HttpService:JSONDecode(res) end)
    if parseOk and data then
        return data.valid, data.reason or data.message, data.expires
    end
    return false, "Invalid server response!"
end

local function RequestServerTrial()
    local reqUrl = API_URL .. "/check_trial?username=" .. player.Name .. "&userid=" .. tostring(player.UserId)
    local ok, res = pcall(function() return game:HttpGet(reqUrl) end)
    if not ok or not res then return false, 0, "Failed to connect to trial server!" end
    local parseOk, data = pcall(function() return HttpService:JSONDecode(res) end)
    if parseOk and data then
        return data.trial, tonumber(data.remaining) or 0, data.reason or data.message
    end
    return false, 0, "Invalid server response!"
end

LaunchKeyUI = function(isExpiredTrial)
    if CoreGui:FindFirstChild("ERDEVA_KEY") then return end

    local KeyGui = Instance.new("ScreenGui", CoreGui)
    KeyGui.Name = "ERDEVA_KEY"
    KeyGui.ResetOnSpawn = false
    KeyGui.DisplayOrder = 99999

    local Overlay = Instance.new("Frame", KeyGui)
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
    Overlay.BackgroundTransparency = 0.35
    Overlay.BorderSizePixel = 0

    local Panel = Instance.new("Frame", KeyGui)
    Panel.Size = UDim2.fromOffset(360, 240)
    Panel.AnchorPoint = Vector2.new(0.5, 0.5)
    Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    Panel.BackgroundColor3 = C.Bg
    Panel.BorderSizePixel = 0
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)
    local PanelStroke = Instance.new("UIStroke", Panel)
    PanelStroke.Color = C.Red
    PanelStroke.Thickness = 1.4

    local Header = Instance.new("Frame", Panel)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = C.Top
    Header.BorderSizePixel = 0
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

    local TitleLabel = Instance.new("TextLabel", Header)
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = isExpiredTrial and "TRIAL EXPIRED" or "ERDEVA HUB v2.7"
    TitleLabel.TextColor3 = C.Txt
    TitleLabel.TextSize = 13
    TitleLabel.Font = Enum.Font.GothamBold

    local SubTitle = Instance.new("TextLabel", Panel)
    SubTitle.Size = UDim2.new(1, -20, 0, 26)
    SubTitle.Position = UDim2.fromOffset(10, 44)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = isExpiredTrial and "Free trial has ended. Enter your license key:" or "Enter license key from ERDEVA HUB Discord:"
    SubTitle.TextColor3 = isExpiredTrial and Color3.fromRGB(241, 196, 15) or C.Sub
    SubTitle.TextSize = 10
    SubTitle.Font = Enum.Font.Gotham

    local InputBox = Instance.new("Frame", Panel)
    InputBox.Size = UDim2.new(1, -20, 0, 36)
    InputBox.Position = UDim2.fromOffset(10, 76)
    InputBox.BackgroundColor3 = C.Card
    InputBox.BorderSizePixel = 0
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 6)
    local InputStroke = Instance.new("UIStroke", InputBox)
    InputStroke.Color = C.Border

    local TextInput = Instance.new("TextBox", InputBox)
    TextInput.Size = UDim2.new(1, -12, 1, 0)
    TextInput.Position = UDim2.fromOffset(6, 0)
    TextInput.BackgroundTransparency = 1
    TextInput.Text = ""
    TextInput.PlaceholderText = "XXXXXX-XXXXXX-XXXXXX-XXXXXX"
    TextInput.PlaceholderColor3 = Color3.fromRGB(80, 85, 100)
    TextInput.TextColor3 = C.Txt
    TextInput.TextSize = 11
    TextInput.Font = Enum.Font.GothamMedium
    TextInput.ClearTextOnFocus = false

    local StatusLabel = Instance.new("TextLabel", Panel)
    StatusLabel.Size = UDim2.new(1, -20, 0, 18)
    StatusLabel.Position = UDim2.fromOffset(10, 118)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = C.Sub
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.GothamMedium

    local SubmitBtn = Instance.new("TextButton", Panel)
    SubmitBtn.Size = UDim2.new(1, -20, 0, 36)
    SubmitBtn.Position = UDim2.fromOffset(10, 142)
    SubmitBtn.BackgroundColor3 = C.Red
    SubmitBtn.Text = "ACTIVATE LICENSE"
    SubmitBtn.TextColor3 = C.Txt
    SubmitBtn.TextSize = 12
    SubmitBtn.Font = Enum.Font.GothamBold
    SubmitBtn.BorderSizePixel = 0
    Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 6)

    local function SubmitKey(keyVal)
        keyVal = keyVal:gsub("%s+", ""):upper()
        if keyVal == "" then
            StatusLabel.Text = "Key cannot be empty!"
            StatusLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
            return
        end

        SubmitBtn.Active = false
        SubmitBtn.Text = "Validating..."
        StatusLabel.Text = "Contacting server..."
        StatusLabel.TextColor3 = C.Sub

        local valid, msg = RequestValidation(keyVal)
        if valid then
            StatusLabel.Text = "License Valid!"
            StatusLabel.TextColor3 = C.Green
            SubmitBtn.Text = "SUCCESS"
            tw(SubmitBtn, {BackgroundColor3 = C.Green}, 0.2)

            pcall(function()
                if writefile then writefile(KEY_FILE, keyVal) end
            end)

            task.delay(0.8, function()
                pcall(function() KeyGui:Destroy() end)
                StartMainScript(false)
            end)
        else
            StatusLabel.Text = msg or "Invalid Key!"
            StatusLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
            SubmitBtn.Active = true
            SubmitBtn.Text = "ACTIVATE LICENSE"
        end
    end

    SubmitBtn.MouseButton1Click:Connect(function()
        if SubmitBtn.Active ~= false then SubmitKey(TextInput.Text) end
    end)
    TextInput.FocusLost:Connect(function(enter)
        if enter and SubmitBtn.Active ~= false then SubmitKey(TextInput.Text) end
    end)
end

StartMainScript = function(isTrialMode, trialTimeLeft)
    local IsRunning = true
    local W, H = 450, 300

    if isTrialMode then
        local hoursLeft = math.floor(trialTimeLeft / 3600)
        local minsLeft = math.floor((trialTimeLeft % 3600) / 60)
        Notify("ERDEVA HUB", "Active Trial: " .. hoursLeft .. "h " .. minsLeft .. "m", 4)
    else
        Notify("ERDEVA HUB", "Script Loaded v2.7", 4)
    end

    local Flags = {
        AutoTakeEggs        = false,
        AutoOpenEggs        = false,
        AutoGrabScraps      = false,
        AutoRecycleScrap    = false,
        AutoUpgradeRecycler = false,
        ScrapCapacity       = 20,
        AutoRebirth         = false,
        AutoUpgradeCoop     = false,
        AutoUpgradeFeeder   = false,
        AutoBuyFeeders      = false,
        AutoStartTower      = false,
        AutoArena           = false,
        AutoNoThanks        = false,
        AutoBypassPopups    = false,
        AutoStartChaos      = false,
        AutoUFO             = false,

        -- [[ FITUR AUTO SELL & FILTER RARITY ]] --
        AutoSellChickens    = false,
        SellCommon          = true,
        SellUncommon        = true,
        SellRare            = true,
        SellEpic            = false,
        SellLegendary       = false,
        SellMythic          = false,
        SellCosmic          = false,
        SellSecret          = false,
    }

    local LOCKED_RECYCLER_POS = nil
    local ToggleUpdaters = {}
    local CurrentBatchScraps = 0
    local ChickenInTower = false
    local ChickenInArena = false
    local TowerSentTime = 0
    local ArenaSentTime = 0
    local LastTowerFinishedAt = tick()
    local ChickenInPitUntil = 0

    local function GetChar() return player.Character end
    local function GetRoot()
        local c = GetChar()
        return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
    end
    local function GetHumanoid()
        local c = GetChar()
        return c and c:FindFirstChildOfClass("Humanoid")
    end

    local ActionCooldowns = {}
    local function CanRunAction(action, cooldown)
        local now = tick()
        if ActionCooldowns[action] and now - ActionCooldowns[action] < cooldown then return false end
        ActionCooldowns[action] = now
        return true
    end

    local function FlatDist(a, b)
        return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
    end

    local function FastTouch(part)
        local root = GetRoot()
        if not root or not part or not part:IsA("BasePart") then return end
        if firetouchinterest then
            firetouchinterest(root, part, 0)
            task.wait(0.02)
            firetouchinterest(root, part, 1)
        end
    end

    local function TriggerPrompt(prompt)
        if not prompt or not prompt.Parent then return false end
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                task.wait((prompt.HoldDuration or 0) + 0.02)
                prompt:InputHoldEnd()
            end
        end)
        return true
    end

    local function TriggerNearbyPrompt(keyword, radius)
        local root = GetRoot()
        if not root then return false end
        keyword = keyword and keyword:lower() or nil
        radius = radius or 16
        local best, bestDist = nil, radius
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local part = obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or obj:FindFirstAncestorWhichIsA("BasePart")
                if part then
                    local text = (obj.ActionText .. " " .. obj.ObjectText .. " " .. obj.Name .. " " .. part.Name):lower()
                    local d = (root.Position - part.Position).Magnitude
                    if d <= bestDist and (not keyword or text:find(keyword)) then best = obj bestDist = d end
                end
            end
        end
        if best then return TriggerPrompt(best) end
        return false
    end

    local function WalkTo(targetPos, timeout, stopDist)
        if not IsRunning then return false end
        local hum = GetHumanoid()
        local root = GetRoot()
        if not hum or not root then return false end
        stopDist = stopDist or 4.5
        timeout = timeout or 3.5
        local t0 = tick()
        local char = GetChar()
        local lastPos = root.Position
        local stuckCounter = 0

        while IsRunning and tick() - t0 < timeout do
            if GetChar() ~= char then return false end
            hum = GetHumanoid()
            root = GetRoot()
            if not hum or not root or hum.Health <= 0 then return false end
            if FlatDist(root.Position, targetPos) <= stopDist then return true end

            hum:MoveTo(targetPos)
            task.wait(0.05)

            if FlatDist(root.Position, lastPos) < 0.25 then
                stuckCounter = stuckCounter + 1
                if stuckCounter >= 4 then
                    hum.Jump = true
                    stuckCounter = 0
                end
            else
                stuckCounter = 0
                lastPos = root.Position
            end
        end
        root = GetRoot()
        return root and FlatDist(root.Position, targetPos) <= (stopDist + 2.5)
    end

    -- [[ LOGIKA PENILAIAN RARITY AYAM ]] --
    local function ShouldSellRarity(rStr)
        if not rStr then return false end
        rStr = rStr:lower()
        if rStr:find("common") and not rStr:find("uncommon") then return Flags.SellCommon end
        if rStr:find("uncommon") then return Flags.SellUncommon end
        if rStr:find("rare") then return Flags.SellRare end
        if rStr:find("epic") then return Flags.SellEpic end
        if rStr:find("legendary") then return Flags.SellLegendary end
        if rStr:find("mythic") or rStr:find("celestial") or rStr:find("divine") then return Flags.SellMythic end
        if rStr:find("cosmic") then return Flags.SellCosmic end
        if rStr:find("secret") then return Flags.SellSecret end
        return false
    end

    local function GetChickenRarity(chickenBtn)
        if not chickenBtn then return "unknown" end
        -- 1. Cek dari nama label di dalam kartu
        local nameLbl = chickenBtn:FindFirstChild("ChickenName", true)
        local rawName = nameLbl and nameLbl.Text:lower() or ""
        
        -- Cek di database
        if ChickenDatabase[rawName] then
            return ChickenDatabase[rawName]
        end

        -- Cek nama tombol (misal c10446)
        if ChickenDatabase[chickenBtn.Name:lower()] then
            return ChickenDatabase[chickenBtn.Name:lower()]
        end

        -- 2. Fallback cek teks di kartu
        for _, t in ipairs(chickenBtn:GetDescendants()) do
            if t:IsA("TextLabel") then
                local txt = t.Text:lower()
                if txt:find("cosmic") then return "cosmic" end
                if txt:find("secret") then return "secret" end
                if txt:find("mythic") or txt:find("divine") or txt:find("celestial") then return "mythic" end
                if txt:find("legendary") then return "legendary" end
                if txt:find("epic") then return "epic" end
                if txt:find("rare") and not txt:find("uncommon") then return "rare" end
                if txt:find("uncommon") then return "uncommon" end
                if txt:find("common") then return "common" end
            end
        end
        return "common"
    end

    -- [[ EKSEKUTOR AUTO SELL CHICKENS ]] --
    local isSellingNow = false
    local function ExecuteAutoSell()
        if isSellingNow or not CanRunAction("AutoSellChickensAction", 4.0) then return end
        isSellingNow = true

        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            local flock = pg and pg:FindFirstChild("Collection") and pg.Collection:FindFirstChild("Flock", true)
            if not flock then isSellingNow = false return end

            local scroll = flock:FindFirstChild("ScrollingFrame", true)
            local sellModeBtn = flock:FindFirstChild("TopButtons") and flock.TopButtons:FindFirstChild("Sell")
            local sellInfo = flock:FindFirstChild("SellInfoHolder", true)
            local confirmSellBtn = sellInfo and sellInfo:FindFirstChild("Sell")

            if not scroll or not sellModeBtn or not confirmSellBtn then
                isSellingNow = false
                return
            end

            -- 1. Masuk ke Sell Mode jika belum aktif
            if not sellInfo.Visible then
                ClickGuiButton(sellModeBtn)
                task.wait(0.3)
            end

            -- 2. Scan ayam dan klik yang sesuai filter
            local selectedCount = 0
            for _, btn in ipairs(scroll:GetChildren()) do
                -- Pastikan ini kartu ayam (dimulai dengan 'c' lalu angka)
                if btn:IsA("GuiButton") and btn.Name:sub(1,1) == "c" and tonumber(btn.Name:sub(2)) then
                    -- CEK FAVORITE: Jangan pernah jual ayam favorit!
                    local fav = btn:FindFirstChild("FavoriteIcon", true)
                    local isFav = fav and fav.Visible
                    
                    if not isFav then
                        local r = GetChickenRarity(btn)
                        if ShouldSellRarity(r) then
                            ClickGuiButton(btn)
                            selectedCount = selectedCount + 1
                            if selectedCount % 15 == 0 then task.wait(0.05) end
                        end
                    end
                end
            end

            task.wait(0.2)

            -- 3. Eksekusi Jual jika ada ayam yang terpilih
            local toSellLbl = sellInfo:FindFirstChild("ToSellCount", true) or sellInfo:FindFirstChild("Value", true)
            local toSellText = toSellLbl and toSellLbl.Text or ""
            local count = tonumber(toSellText:match("(%d+)")) or selectedCount

            if count > 0 then
                ClickGuiButton(confirmSellBtn)
                Notify("ERDEVA HUB", "Auto Sold " .. tostring(count) .. " Chickens!", 3)
                task.wait(0.3)
            end

            -- 4. Keluar dari Sell Mode
            local cancelBtn = sellInfo:FindFirstChild("Cancel")
            if cancelBtn and sellInfo.Visible then
                ClickGuiButton(cancelBtn)
            elseif sellModeBtn and sellInfo.Visible then
                ClickGuiButton(sellModeBtn)
            end
        end)

        isSellingNow = false
    end

    -- Cek kapasitas tas ayam (misal 130/130)
    local function CheckBackpackFull()
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then return false end
        for _, lbl in ipairs(pg:GetDescendants()) do
            if lbl:IsA("TextLabel") and IsVisibleGui(lbl) then
                local cur, max = lbl.Text:match("(%d+)%s*/%s*(%d+)")
                if cur and max then
                    local c = tonumber(cur)
                    local m = tonumber(max)
                    if m and m >= 50 and c >= (m - 10) then
                        return true
                    end
                end
            end
        end
        return false
    end

    -- Buka Telur & Trigger Auto Sell
    local function DoUpgradesAndEggs()
        if Flags.AutoBuyFeeders then
            for slot = 1, 2 do SafeCall("BuyGenerator", slot); task.wait(0.1) end
        end
        if Flags.AutoUpgradeFeeder then
            for slot = 1, 2 do SafeCall("UpgradeGenerator", slot) end
        end
        if Flags.AutoUpgradeRecycler then
            SafeCall("UpgradeRecycler")
        end
        if Flags.AutoUpgradeCoop then
            SafeCall("ExpandCoop")
        end
        if Flags.AutoOpenEggs then
            SafeCall("HatchEggs", "common", 10)
            TryClickGuiAction("OpenEggs", { "hatch", "open egg", "open" }, 2.0)
            
            -- Jika auto sell aktif, jual ayam sampah secara berkala
            if Flags.AutoSellChickens then
                task.delay(1.0, function() ExecuteAutoSell() end)
            end
        end
    end

    -- Loop utama untuk cek auto sell & buka telur
    task.spawn(function()
        while IsRunning do
            pcall(function()
                if Flags.AutoSellChickens and CheckBackpackFull() then
                    ExecuteAutoSell()
                end
                DoUpgradesAndEggs()
            end)
            task.wait(2.0)
        end
    end)

    -- [[ UI SYSTEM ]] --
    local Gui = Instance.new("ScreenGui", CoreGui)
    Gui.Name = "ERDEVA_HUB"
    Gui.ResetOnSpawn = false
    Gui.DisplayOrder = 9999

    local function Shutdown()
        IsRunning = false
        for k in pairs(Flags) do Flags[k] = false end
        pcall(function() Gui:Destroy() end)
    end

    local Main = Instance.new("Frame", Gui)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Size = UDim2.fromOffset(W, H)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.BackgroundColor3 = C.Bg
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = C.Red
    MainStroke.Thickness = 1.2

    local Top = Instance.new("Frame", Main)
    Top.Size = UDim2.new(1, 0, 0, 36)
    Top.BackgroundColor3 = C.Top
    Top.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", Top)
    Title.Size = UDim2.new(1, -75, 1, 0)
    Title.Position = UDim2.fromOffset(12, 0)
    Title.BackgroundTransparency = 1
    Title.Text = isTrialMode and "ERDEVA HUB [TRIAL]" or "ERDEVA HUB v2.7"
    Title.TextColor3 = C.Txt
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", Top)
    CloseBtn.Size = UDim2.fromOffset(24, 24)
    CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = C.Sub
    CloseBtn.TextSize = 11
    CloseBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
    CloseBtn.MouseButton1Click:Connect(Shutdown)

    local MinBtn = Instance.new("TextButton", Top)
    MinBtn.Size = UDim2.fromOffset(24, 24)
    MinBtn.Position = UDim2.new(1, -58, 0.5, -12)
    MinBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
    MinBtn.Text = "-"
    MinBtn.TextColor3 = C.Sub
    MinBtn.TextSize = 13
    MinBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 5)

    local MiniIcon = Instance.new("TextButton", Gui)
    MiniIcon.Size = UDim2.fromOffset(50, 50)
    MiniIcon.Position = UDim2.new(0, 20, 0.5, -25)
    MiniIcon.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
    MiniIcon.Text = "ERDEVA"
    MiniIcon.TextColor3 = C.Red
    MiniIcon.TextSize = 10
    MiniIcon.Font = Enum.Font.GothamBold
    MiniIcon.Visible = false
    Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 10)
    local MiniStroke = Instance.new("UIStroke", MiniIcon)
    MiniStroke.Color = C.Red

    MinBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        MiniIcon.Visible = true
    end)
    MiniIcon.MouseButton1Click:Connect(function()
        MiniIcon.Visible = false
        Main.Visible = true
    end)

    -- Draggable
    local mainDrag, dragStart, startPos = false, nil, nil
    Top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mainDrag = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then mainDrag = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if mainDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Tab Bar
    local TabFrame = Instance.new("Frame", Main)
    TabFrame.Size = UDim2.new(1, -16, 0, 30)
    TabFrame.Position = UDim2.fromOffset(8, 42)
    TabFrame.BackgroundColor3 = C.TabBg
    TabFrame.BorderSizePixel = 0
    Instance.new("UICorner", TabFrame).CornerRadius = UDim.new(0, 6)

    local TabList = Instance.new("UIListLayout", TabFrame)
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.VerticalAlignment = Enum.VerticalAlignment.Center
    TabList.Padding = UDim.new(0, 4)

    local Content = Instance.new("ScrollingFrame", Main)
    Content.Size = UDim2.new(1, -16, 1, -82)
    Content.Position = UDim2.fromOffset(8, 76)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 2
    Content.ScrollBarImageColor3 = C.Red
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local CL = Instance.new("UIListLayout", Content)
    CL.Padding = UDim.new(0, 4)

    local Pages, TabBtns = {}, {}
    local function SetTab(name)
        for n, p in pairs(Pages) do p.Visible = (n == name) end
        for n, btn in pairs(TabBtns) do
            local isSel = (n == name)
            tw(btn, {BackgroundColor3 = isSel and Color3.fromRGB(38, 18, 24) or Color3.fromRGB(18, 20, 26)}, 0.15)
        end
    end

    local MakeTab = function(name, order)
        local btn = Instance.new("TextButton", TabFrame)
        btn.Size = UDim2.new(0.2, -4, 1, -4)
        btn.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
        btn.Text = name
        btn.TextColor3 = C.Txt
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.LayoutOrder = order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        TabBtns[name] = btn

        local page = Instance.new("Frame", Content)
        page.Size = UDim2.new(1, 0, 0, 0)
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1
        page.Visible = false
        local pl = Instance.new("UIListLayout", page)
        pl.Padding = UDim.new(0, 4)
        Pages[name] = page

        btn.MouseButton1Click:Connect(function() SetTab(name) end)
        return page
    end

    local function SetFlag(key, val)
        Flags[key] = val
        if ToggleUpdaters[key] then ToggleUpdaters[key](val) end
    end

    local function AddToggle(parent, label, key)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -54, 1, 0)
        l.Position = UDim2.fromOffset(10, 0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Txt
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        local b = Instance.new("TextButton", f)
        b.Size = UDim2.fromOffset(36, 18)
        b.Position = UDim2.new(1, -44, 0.5, -9)
        b.BackgroundColor3 = C.Off
        b.Text = ""
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)

        local k = Instance.new("Frame", b)
        k.Size = UDim2.fromOffset(12, 12)
        k.Position = UDim2.fromOffset(3, 3)
        k.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        Instance.new("UICorner", k).CornerRadius = UDim.new(1, 0)

        local function upd(on)
            tw(b, {BackgroundColor3 = (on and C.Red or C.Off)})
            tw(k, {Position = (on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3))})
        end

        ToggleUpdaters[key] = upd
        upd(Flags[key])

        b.MouseButton1Click:Connect(function()
            SetFlag(key, not Flags[key])
        end)
    end

    local function AddButton(parent, label, callback)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = C.Card
        b.Text = label
        b.TextColor3 = C.Txt
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = C.Border

        b.MouseButton1Click:Connect(function()
            tw(b, {BackgroundColor3 = C.Red}, 0.1)
            task.delay(0.2, function() tw(b, {BackgroundColor3 = C.Card}, 0.15) end)
            if callback then callback(b) end
        end)
        return b
    end

    local FarmPage   = MakeTab("Farm",   1)
    local PlotPage   = MakeTab("Plot",   2)
    local BattlePage = MakeTab("Battle", 3)
    local EventsPage = MakeTab("Events", 4)
    local InfoPage   = MakeTab("Info",   5)

    -- [[ HALAMAN FARM ]] --
    AddToggle(FarmPage, "Auto Take Eggs",       "AutoTakeEggs")
    AddToggle(FarmPage, "Auto Open Eggs",       "AutoOpenEggs")
    AddToggle(FarmPage, "Auto Grab Scraps",      "AutoGrabScraps")
    AddToggle(FarmPage, "Auto Recycle Scrap",    "AutoRecycleScrap")

    -- [[ FITUR AUTO SELL & FILTER RARITY ]] --
    AddToggle(FarmPage, "🔥 Auto Sell Chickens", "AutoSellChickens")
    AddButton(FarmPage, "⚡ SELL CHICKENS NOW (MANUAL)", function()
        ExecuteAutoSell()
    end)
    
    -- Sub-Section Filter Rarity
    AddToggle(FarmPage, "   Sell [Common]",     "SellCommon")
    AddToggle(FarmPage, "   Sell [Uncommon]",   "SellUncommon")
    AddToggle(FarmPage, "   Sell [Rare]",       "SellRare")
    AddToggle(FarmPage, "   Sell [Epic]",       "SellEpic")
    AddToggle(FarmPage, "   Sell [Legendary]",  "SellLegendary")
    AddToggle(FarmPage, "   Sell [Mythic/Divine]", "SellMythic")
    AddToggle(FarmPage, "   Sell [Cosmic]",     "SellCosmic")
    AddToggle(FarmPage, "   Sell [Secret]",     "SellSecret")

    -- [[ HALAMAN PLOT ]] --
    AddToggle(PlotPage, "Auto Rebirth",         "AutoRebirth")
    AddToggle(PlotPage, "Auto Buy Feeders",      "AutoBuyFeeders")
    AddToggle(PlotPage, "Auto Upgrade Feeder",   "AutoUpgradeFeeder")
    AddToggle(PlotPage, "Auto Upgrade Recycler", "AutoUpgradeRecycler")
    AddToggle(PlotPage, "Auto Upgrade Coop",     "AutoUpgradeCoop")

    -- [[ HALAMAN BATTLE ]] --
    AddToggle(BattlePage, "Auto Start Tower",     "AutoStartTower")
    AddToggle(BattlePage, "Auto Arena",           "AutoArena")
    AddToggle(BattlePage, "Auto Close Popups",   "AutoBypassPopups")

    -- [[ HALAMAN EVENTS & INFO ]] --
    AddToggle(EventsPage, "Auto UFO", "AutoUFO")

    local function AddInfo(k, v)
        local f = Instance.new("Frame", InfoPage)
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(0.5, 0, 1, 0)
        l.Position = UDim2.fromOffset(10, 0)
        l.BackgroundTransparency = 1
        l.Text = k
        l.TextColor3 = C.Txt
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        local r = Instance.new("TextLabel", f)
        r.Size = UDim2.new(0.5, -10, 1, 0)
        r.Position = UDim2.new(0.5, 0, 0, 0)
        r.BackgroundTransparency = 1
        r.Text = v
        r.TextColor3 = C.Red
        r.TextSize = 11
        r.Font = Enum.Font.GothamBold
        r.TextXAlignment = Enum.TextXAlignment.Right
    end

    AddInfo("User", player.Name)
    AddInfo("Hub Version", "v2.7 (Auto Sell)")

    SetTab("Farm")
end

local function InitSystem()
    local savedKey = nil
    pcall(function()
        if isfile and isfile(KEY_FILE) and readfile then
            savedKey = readfile(KEY_FILE):gsub("%s+", ""):upper()
        end
    end)

    if savedKey and #savedKey > 10 then
        local valid, msg = RequestValidation(savedKey)
        if valid then
            StartMainScript(false)
            return
        end
    end

    local isTrial, remainingTime = RequestServerTrial()
    if isTrial and remainingTime > 0 then
        StartMainScript(true, remainingTime)
    else
        LaunchKeyUI(true)
    end
end

InitSystem()
