local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

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
            r:InvokeServer(table.unpack(args))
        elseif r:IsA("RemoteEvent") then
            r:FireServer(table.unpack(args))
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

local function TriggerFrontierFloorSequence()
    task.spawn(function()
        task.wait(0.7)
        local t0 = tick()
        local detectedFloor = nil
        local cam = workspace.CurrentCamera

        while tick() - t0 < 5.0 and not detectedFloor do
            local pg = player:FindFirstChild("PlayerGui")
            local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)

            if pg then
                for _, obj in ipairs(pg:GetDescendants()) do
                    if obj:IsA("TextLabel") and IsVisibleGui(obj) then
                        local pos = obj.AbsolutePosition
                        local size = obj.AbsoluteSize
                        local onScreen = pos.X >= -10 and pos.Y >= -10 and (pos.X + size.X) <= (vp.X + 100) and (pos.Y + size.Y) <= (vp.Y + 100) and size.X > 20 and size.Y > 10

                        if onScreen then
                            local t = obj.Text:lower()
                            if t:find("straight") and t:find("frontier") then
                                local num = tonumber(t:match("floor%s*(%d+)"))
                                if not num and obj.Parent then
                                    for _, sib in ipairs(obj.Parent:GetDescendants()) do
                                        if sib:IsA("TextLabel") and IsVisibleGui(sib) then
                                            local st = sib.Text:lower()
                                            if not st:find("k") and not st:find("m") and not st:find("b") then
                                                local n = tonumber(st:match("floor%s*(%d+)")) or tonumber(st:match("(%d+)"))
                                                if n and n >= 5 then num = n break end
                                            end
                                        end
                                    end
                                end
                                if num and num > 0 then
                                    detectedFloor = num
                                    break
                                end
                            end
                        end
                    end
                end
            end
            if not detectedFloor then task.wait(0.05) end
        end

        if detectedFloor then
            local rem = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("TowerElevator")
            if not rem then rem = rs:FindFirstChild("TowerElevator", true) end

            if rem then
                Notify("ERDEVA HUB", "Floor " .. tostring(detectedFloor) .. " Selected", 2.5)
                for _ = 1, 5 do
                    task.spawn(function()
                        pcall(function()
                            if rem:IsA("RemoteFunction") then
                                rem:InvokeServer(detectedFloor)
                            elseif rem:IsA("RemoteEvent") then
                                rem:FireServer(detectedFloor)
                            end
                        end)
                    end)
                    task.wait(0.15)
                end
            end
        end
    end)
end

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
    KeyGui.IgnoreGuiInset = true
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

    local HeaderFix = Instance.new("Frame", Header)
    HeaderFix.Size = UDim2.new(1, 0, 0.5, 0)
    HeaderFix.Position = UDim2.new(0, 0, 0.5, 0)
    HeaderFix.BackgroundColor3 = C.Top
    HeaderFix.BorderSizePixel = 0

    local TitleLabel = Instance.new("TextLabel", Header)
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = isExpiredTrial and "TRIAL EXPIRED" or "ERDEVA HUB v2.6"
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

    local InfoFoot = Instance.new("TextButton", Panel)
    InfoFoot.Size = UDim2.new(1, -20, 0, 24)
    InfoFoot.Position = UDim2.fromOffset(10, 186)
    InfoFoot.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    InfoFoot.Text = "Buy License: discord.gg/P7g4jpZTU"
    InfoFoot.TextColor3 = Color3.fromRGB(255, 255, 255)
    InfoFoot.TextSize = 10
    InfoFoot.Font = Enum.Font.GothamMedium
    InfoFoot.BorderSizePixel = 0
    Instance.new("UICorner", InfoFoot).CornerRadius = UDim.new(0, 6)

    InfoFoot.MouseButton1Click:Connect(function()
        local discordUrl = "https://discord.gg/P7g4jpZTU"
        pcall(function()
            if setclipboard then
                setclipboard(discordUrl)
            elseif toclipboard then
                toclipboard(discordUrl)
            end
            if openurl then openurl(discordUrl) end
            if syn and syn.open_url then syn.open_url(discordUrl) end
        end)
        InfoFoot.Text = "Link Copied to Clipboard"
        InfoFoot.TextColor3 = C.Green
        Notify("ERDEVA HUB", "Discord Link Copied to Clipboard!", 2.5)
        task.delay(2.5, function()
            InfoFoot.Text = "Buy License: discord.gg/P7g4jpZTU"
            InfoFoot.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end)

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
    local W, H = 445, 285

    if isTrialMode then
        local hoursLeft = math.floor(trialTimeLeft / 3600)
        local minsLeft = math.floor((trialTimeLeft % 3600) / 60)
        Notify("ERDEVA HUB", "Active Trial: " .. hoursLeft .. "h " .. minsLeft .. "m", 4)
    else
        Notify("ERDEVA HUB", "Script Loaded", 4)
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
        -- Auto Sell Chickens Flags
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

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        CurrentBatchScraps = 0
        ChickenInTower = false
        ChickenInArena = false
        TowerSentTime = 0
        ArenaSentTime = 0
        ChickenInPitUntil = 0
    end)

    local function IsOurEvent(...)
        local args = {...}
        if #args == 0 then return true end
        local first = args[1]
        if typeof(first) == "Instance" then
            if first == player or first == player.Character then return true end
            if first:IsDescendantOf(player) or (player.Character and first:IsDescendantOf(player.Character)) then return true end
            return false
        elseif type(first) == "string" then
            if first == player.Name or first == tostring(player.UserId) then return true end
            return false
        elseif type(first) == "number" then
            if first == player.UserId then return true end
            return false
        elseif type(first) == "table" then
            if first.Player == player or first.UserId == player.UserId or first.Name == player.Name or first.Username == player.Name then
                return true
            end
            for _, v in pairs(first) do
                if v == player or v == player.Name or v == player.UserId then return true end
            end
            return false
        end
        return true
    end

    local function BindCombatListener(remoteName, callback)
        local r = rs:FindFirstChild(remoteName, true)
        if r and r:IsA("RemoteEvent") then
            pcall(function()
                r.OnClientEvent:Connect(function(...)
                    if IsOurEvent(...) then
                        callback(...)
                    end
                end)
            end)
        end
    end

    BindCombatListener("BattleStarted", function() ChickenInArena = true; ArenaSentTime = tick() end)
    BindCombatListener("BattleEnded", function() ChickenInArena = false; ArenaSentTime = 0 end)
    BindCombatListener("TowerRunStarted", function() ChickenInTower = true; TowerSentTime = tick() end)
    BindCombatListener("TowerRunEnded", function() ChickenInTower = false; LastTowerFinishedAt = tick() end)
    BindCombatListener("TowerDefeat", function() ChickenInTower = false; LastTowerFinishedAt = tick() end)

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

    local function SendChickenToPit(tag, holdDuration)
        if not CanRunAction("SendChicken_" .. (tag or "general"), 4.0) then return end
        local patterns = {"to chaos", "chaos", "pit", "enter chaos"}
        TryClickGuiAction("PitChaosBtn", patterns, 2.5)
        TriggerNearbyPrompt("chaos", 20)
        TriggerNearbyPrompt("pit", 20)
        ChickenInArena = true
        if holdDuration and holdDuration > 0 then
            ChickenInPitUntil = tick() + holdDuration
        end
    end

    local function IsRealScrap(obj)
        if not obj:IsA("BasePart") or not obj.Parent then return false end
        local char = GetChar()
        if char and obj:IsDescendantOf(char) then return false end
        local anc = obj:FindFirstAncestorOfClass("Model")
        if anc and anc:FindFirstChildOfClass("Humanoid") then return false end
        local n = obj.Name:lower()
        local pn = obj.Parent.Name:lower()
        local ppn = (obj.Parent.Parent and obj.Parent.Parent.Name:lower()) or ""
        if n:find("fence") or n:find("wall") or n:find("floor") or n:find("base") or n:find("spawn") or n:find("grass") or n:find("terrain") then return false end
        if n:find("recycler") or n:find("feeder") or n:find("coop") or n:find("incubator") or n:find("shop") or n:find("pad") or n:find("button") then return false end
        if pn:find("recycler") or pn:find("feeder") or pn:find("coop") or pn:find("incubator") or pn:find("shop") or pn:find("plot") then return false end
        if ppn:find("plot") or ppn:find("base") or ppn:find("feeder") or ppn:find("recycler") then return false end

        if n:find("scrap") or n:find("plate") or n:find("drop") or n:find("trash") or n:find("sheet") or n:find("debris")
           or n:find("alien") or n:find("coin") or n:find("gold") or n:find("meteor")
           or pn:find("scrap") or pn:find("plate") or pn:find("drop") or pn:find("drops")
           or pn:find("alien") or pn:find("coin") or pn:find("debris") then
            return true
        end
        return false
    end

    local BlacklistedScraps = {}
    local function CleanupScrapBlacklist()
        local now = tick()
        for scrap, t in pairs(BlacklistedScraps) do
            if typeof(scrap) ~= "Instance" or not scrap.Parent or now - t > 3.0 then BlacklistedScraps[scrap] = nil end
        end
    end

    local function FindNearestArenaScrap()
        CleanupScrapBlacklist()
        local root = GetRoot()
        if not root then return nil end
        local best, bestDist = nil, 9999
        local pitScrap = workspace:FindFirstChild("PitScrap") or workspace:FindFirstChild("Pit")
        if pitScrap then
            for _, obj in ipairs(pitScrap:GetDescendants()) do
                if obj:IsA("BasePart") and not BlacklistedScraps[obj] and obj.Parent then
                    local d = FlatDist(root.Position, obj.Position)
                    if d < 800 and d < bestDist then best = obj bestDist = d end
                end
            end
        end
        if not best then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if IsRealScrap(obj) and not BlacklistedScraps[obj] then
                    local d = FlatDist(root.Position, obj.Position)
                    if d < 800 and d < bestDist then best = obj bestDist = d end
                end
            end
        end
        return best
    end

    local function CollectScrapPlate(scrap)
        if not scrap or not scrap.Parent then return false end
        local root = GetRoot()
        if not root or not GetChar() then return false end

        FastTouch(scrap)
        WalkTo(scrap.Position, 2.0, 2.0)
        FastTouch(scrap)
        TriggerNearbyPrompt("scrap", 16)

        CurrentBatchScraps = CurrentBatchScraps + 1
        BlacklistedScraps[scrap] = tick()
        return true
    end

    local function FindBasePad(keywords)
        local root = GetRoot()
        if not root then return nil end
        local bestPart, bestPrompt, bestDist = nil, nil, 9999
        for _, obj in ipairs(workspace:GetDescendants()) do
            local targetPart, prompt, matched = nil, nil, false
            if obj:IsA("ProximityPrompt") then
                local part = obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or obj:FindFirstAncestorWhichIsA("BasePart")
                if part then
                    local text = (obj.ActionText .. " " .. obj.ObjectText .. " " .. obj.Name .. " " .. part.Name):lower()
                    for _, kw in ipairs(keywords) do
                        if text:find(kw:lower()) then matched = true targetPart = part prompt = obj break end
                    end
                end
            elseif obj:IsA("BasePart") then
                local name = obj.Name:lower()
                local pName = obj.Parent and obj.Parent.Name:lower() or ""
                for _, kw in ipairs(keywords) do
                    local kl = kw:lower()
                    if name:find(kl) or pName:find(kl) then
                        matched = true targetPart = obj
                        prompt = obj:FindFirstChildOfClass("ProximityPrompt") or obj:FindFirstChildOfClass("ClickDetector")
                        break
                    end
                end
            end
            if matched and targetPart and targetPart:IsA("BasePart") then
                local d = (root.Position - targetPart.Position).Magnitude
                if d < 400 and d < bestDist then bestDist = d bestPart = targetPart bestPrompt = prompt end
            end
        end
        if bestPart then return { part = bestPart, prompt = bestPrompt } end
        return nil
    end

    local function DoRecycleAtBase()
        if not CanRunAction("RecycleScrapAction", 1.8) then return false end
        local targetPos = LOCKED_RECYCLER_POS
        local pad = nil
        if not targetPos then
            pad = FindBasePad({"recycler", "recycle", "sell scrap", "convert", "deposit"})
            if pad and pad.part then targetPos = pad.part.Position end
        end
        if not targetPos then
            local recs = workspace:FindFirstChild("Recyclers")
            if recs then
                local root = GetRoot()
                local bestR, bestRD = nil, 9999
                for _, r in ipairs(recs:GetChildren()) do
                    local p = r:IsA("BasePart") and r or r:FindFirstChildWhichIsA("BasePart", true)
                    if p and root then
                        local d = (root.Position - p.Position).Magnitude
                        if d < bestRD then bestR = p bestRD = d end
                    end
                end
                if bestR then targetPos = bestR.Position end
            end
        end
        if not targetPos then return false end

        local arrived = WalkTo(targetPos, 4.0, 3.5)
        if pad and pad.part then FastTouch(pad.part) end
        TriggerNearbyPrompt("recycle", 16)
        TriggerNearbyPrompt("deposit", 16)
        TryClickGuiAction("RecycleDeposit", {"recycle", "sell scrap", "convert", "deposit", "empty"}, 0.8)
        SafeCall("UpgradeRecycler")
        task.wait(0.3)

        CurrentBatchScraps = 0
        table.clear(BlacklistedScraps)
        return true
    end

    local function ExecuteBasePad(actionName, keywords, guiPatterns, cooldown)
        if not CanRunAction(actionName, cooldown or 2.0) then return false end
        local pad = FindBasePad(keywords)
        if pad and pad.part then
            FastTouch(pad.part)
            if pad.prompt and pad.prompt:IsA("ProximityPrompt") then
                TriggerPrompt(pad.prompt)
            elseif pad.prompt and pad.prompt:IsA("ClickDetector") and fireclickdetector then
                pcall(function() fireclickdetector(pad.prompt) end)
            else
                for _, kw in ipairs(keywords) do TriggerNearbyPrompt(kw, 12) end
            end
        end
        if guiPatterns then TryClickGuiAction(actionName, guiPatterns, cooldown or 2.0) end
        return true
    end

    local function DoUpgrades()
        if Flags.AutoBuyFeeders then
            for slot = 1, 2 do 
                SafeCall("BuyGenerator", slot)
                task.wait(0.1)
            end
            ExecuteBasePad("BuyFeeder", { "buy feeder", "new feeder", "feeder" }, { "buy feeder", "new feeder" }, 2.0)
        end
        if Flags.AutoUpgradeFeeder then
            for slot = 1, 2 do SafeCall("UpgradeGenerator", slot) end
            ExecuteBasePad("UpgradeFeeder", { "upgrade feeder", "feed speed", "speed upgrade" }, { "upgrade feeder", "upgrade speed" }, 0.1)
        end
        if Flags.AutoUpgradeRecycler then
            SafeCall("UpgradeRecycler")
            ExecuteBasePad("UpgradeRecycler", { "upgrade recycler", "recycler speed", "recycler level" }, { "upgrade recycler", "recycle speed" }, 2.5)
        end
        if Flags.AutoUpgradeCoop then
            SafeCall("ExpandCoop")
            ExecuteBasePad("UpgradeCoop", { "upgrade coop", "coop" }, { "upgrade coop" }, 2.5)
        end
        if Flags.AutoOpenEggs then
            SafeCall("HatchEggs", "common", 10)
            TryClickGuiAction("OpenEggs", { "hatch", "open egg", "open" }, 2.0)
        end
    end

    local function RunAutoTakeEggs()
        if not CanRunAction("AutoTakeEggsAction", 1.5) then return end
        SafeCall("IncubatorClaim")
        SafeCall("ClaimShopDust")

        local root = GetRoot()
        if not root then return end

        local nestEggs = workspace:FindFirstChild("NestEggs") or workspace:FindFirstChild("Incubators")
        if nestEggs then
            for _, obj in ipairs(nestEggs:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj.Enabled then
                    local p = obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or obj:FindFirstAncestorWhichIsA("BasePart")
                    if p and (root.Position - p.Position).Magnitude <= 24 then
                        TriggerPrompt(obj)
                    end
                elseif obj:IsA("BasePart") and (obj.Name:lower():find("egg") or obj.Parent.Name:lower():find("egg")) then
                    if (root.Position - obj.Position).Magnitude <= 100 then
                        FastTouch(obj)
                    end
                end
            end
        end

        TriggerNearbyPrompt("egg", 80)
        TriggerNearbyPrompt("incubator", 18)
        TriggerNearbyPrompt("claim", 18)
        TryClickGuiAction("TakeEggGui", {"claim", "collect egg", "take egg", "hatch"}, 1.5)
    end

    local function RunEventCheck()
        if Flags.AutoUFO then
            local ufoActive = false
            if workspace:FindFirstChild("UfoShow") or workspace:FindFirstChild("Ufo") then
                ufoActive = true
            end
            local pg = player:FindFirstChild("PlayerGui")
            if not ufoActive and pg then
                local meter = pg:FindFirstChild("BlessingVsCurseMeter")
                if meter and meter.Enabled then ufoActive = true end
            end
            if ufoActive then
                if tick() >= ChickenInPitUntil then
                    TryClickGuiAction("UfoChip", {"live-ufo"}, 2.0)
                    SendChickenToPit("UFO", 35)
                end
            end
        end
    end

    local function HasRebirthExclamationMark()
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then return false end
        local rail = pg:FindFirstChild("ArenaSideRail")
        local railRebirth = rail and rail:FindFirstChild("Rebirth", true)
        if not railRebirth then return false end

        for _, child in ipairs(railRebirth:GetDescendants()) do
            if child:IsA("TextLabel") and IsVisibleGui(child) and child.Text:find("!") then
                return true
            end
            if child:IsA("GuiObject") and IsVisibleGui(child) and (child.Name:lower():find("alert") or child.Name:lower():find("notify") or child.Name:lower():find("badge") or child.Name:lower():find("exclamation")) then
                return true
            end
        end
        return false
    end

    local function CheckAndDoRebirth()
        if not HasRebirthExclamationMark() then return false end
        if not CanRunAction("ExecuteRebirthAction", 6.0) then return false end

        if ChickenInTower then
            SafeCall("TowerSurrender")
            ChickenInTower = false
            TowerSentTime = 0
            LastTowerFinishedAt = tick()
            task.wait(1.0)
        end

        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            local rail = pg:FindFirstChild("ArenaSideRail")
            local railRebirth = rail and rail:FindFirstChild("Rebirth", true)
            if railRebirth and IsVisibleGui(railRebirth) then
                ClickGuiButton(railRebirth)
                task.wait(0.3)
            end

            local rebirthGui = pg:FindFirstChild("Rebirth")
            local confirmBtn = rebirthGui and rebirthGui:FindFirstChild("confirm", true)
            if confirmBtn then
                ClickGuiButton(confirmBtn)
            end
        end

        SafeCall("Rebirth")
        task.wait(0.3)
        TryClickGuiAction("RebirthConfirm", {"confirm", "yes", "do rebirth"}, 1.5)

        local pgAfter = player:FindFirstChild("PlayerGui")
        local rebirthGuiAfter = pgAfter and pgAfter:FindFirstChild("Rebirth")
        if rebirthGuiAfter then
            for _, b in ipairs(rebirthGuiAfter:GetDescendants()) do
                if (b:IsA("TextButton") or b:IsA("ImageButton")) and IsVisibleGui(b) then
                    local bt = ButtonText(b)
                    if bt:find("close") or bt:find("x") or b.Name:lower() == "x" or b.Name:lower() == "close" then
                        ClickGuiButton(b)
                        break
                    end
                end
            end
        end

        CurrentBatchScraps = 0
        table.clear(BlacklistedScraps)
        LastTowerFinishedAt = tick()
        return true
    end

    -- [[ AUTO SELL CHICKENS SYSTEM ]] --
    local ChickenDatabase = {}
    pcall(function()
        local cTypesMod = rs:FindFirstChild("Content")
            and rs.Content:FindFirstChild("Catalog")
            and rs.Content.Catalog:FindFirstChild("ChickenTypes")

        if not cTypesMod then
            cTypesMod = rs:FindFirstChild("ChickenTypes", true)
        end

        if cTypesMod then
            local raw = require(cTypesMod)
            if type(raw) == "table" then
                for id, info in pairs(raw) do
                    if type(info) == "table" then
                        local rarity = tostring(info.Rarity or info.rarity or "common"):lower()
                        local displayName = tostring(info.Name or info.DisplayName or info.name or id):lower()
                        ChickenDatabase[displayName] = rarity
                        ChickenDatabase[tostring(id):lower()] = rarity
                    end
                end
            end
        end
    end)

    local function ShouldSellRarity(rStr)
        if not rStr then return false end
        rStr = rStr:lower()
        if rStr:find("common") and not rStr:find("uncommon") then
            return Flags.SellCommon
        end
        if rStr:find("uncommon") then
            return Flags.SellUncommon
        end
        if rStr:find("rare") then
            return Flags.SellRare
        end
        if rStr:find("epic") then
            return Flags.SellEpic
        end
        if rStr:find("legendary") then
            return Flags.SellLegendary
        end
        if rStr:find("mythic") or rStr:find("celestial") or rStr:find("divine") then
            return Flags.SellMythic
        end
        if rStr:find("cosmic") then
            return Flags.SellCosmic
        end
        if rStr:find("secret") then
            return Flags.SellSecret
        end
        return false
    end

    local function GetChickenRarity(chickenBtn)
        if not chickenBtn then return "common" end

        local nameLbl = chickenBtn:FindFirstChild("ChickenName", true)
        local rawName = nameLbl and nameLbl.Text:lower() or ""

        if ChickenDatabase[rawName] then
            return ChickenDatabase[rawName]
        end

        local buttonName = chickenBtn.Name:lower()
        if ChickenDatabase[buttonName] then
            return ChickenDatabase[buttonName]
        end

        for _, obj in ipairs(chickenBtn:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local txt = obj.Text:lower()
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

    local function CheckBackpackFull()
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then return false end
        for _, lbl in ipairs(pg:GetDescendants()) do
            if lbl:IsA("TextLabel") and IsVisibleGui(lbl) then
                local cur, max = lbl.Text:match("(%d+)%s*/%s*(%d+)")
                if cur and max then
                    local current = tonumber(cur)
                    local maximum = tonumber(max)
                    if maximum and maximum >= 50 and current >= (maximum - 10) then
                        return true
                    end
                end
            end
        end
        return false
    end

    local isSellingNow = false
    local function ExecuteAutoSell()
        if isSellingNow or not CanRunAction("AutoSellChickensAction", 4.0) then return end
        isSellingNow = true

        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            local flock = pg and pg:FindFirstChild("Collection") and pg.Collection:FindFirstChild("Flock", true)
            if not flock then
                isSellingNow = false
                return
            end

            local scroll = flock:FindFirstChild("ScrollingFrame", true)
            local topButtons = flock:FindFirstChild("TopButtons")
            local sellModeBtn = topButtons and topButtons:FindFirstChild("Sell")
            local sellInfo = flock:FindFirstChild("SellInfoHolder", true)
            local confirmSellBtn = sellInfo and sellInfo:FindFirstChild("Sell")

            if not scroll or not sellModeBtn or not confirmSellBtn then
                isSellingNow = false
                return
            end

            if not sellInfo.Visible then
                ClickGuiButton(sellModeBtn)
                task.wait(0.3)
            end

            local selectedCount = 0
            for _, btn in ipairs(scroll:GetChildren()) do
                if btn:IsA("GuiButton") and btn.Name:sub(1, 1) == "c" and tonumber(btn.Name:sub(2)) then
                    local fav = btn:FindFirstChild("FavoriteIcon", true)
                    local isFav = fav and fav.Visible
                    if not isFav then
                        local rarity = GetChickenRarity(btn)
                        if ShouldSellRarity(rarity) then
                            ClickGuiButton(btn)
                            selectedCount = selectedCount + 1
                            if selectedCount % 15 == 0 then
                                task.wait(0.05)
                            end
                        end
                    end
                end
            end

            task.wait(0.2)

            local toSellLbl = sellInfo:FindFirstChild("ToSellCount", true) or sellInfo:FindFirstChild("Value", true)
            local toSellText = toSellLbl and toSellLbl.Text or ""
            local count = tonumber(toSellText:match("(%d+)")) or selectedCount

            if count > 0 then
                ClickGuiButton(confirmSellBtn)
                Notify("ERDEVA HUB", "Auto Sold " .. tostring(count) .. " Chickens!", 3)
                task.wait(0.3)
            end

            local cancelBtn = sellInfo:FindFirstChild("Cancel")
            if cancelBtn and sellInfo.Visible then
                ClickGuiButton(cancelBtn)
            elseif sellModeBtn and sellInfo.Visible then
                ClickGuiButton(sellModeBtn)
            end
        end)

        isSellingNow = false
    end

    -- LOOP 1: POPUPS, EGGS, UPGRADES
    task.spawn(function()
        while IsRunning do
            pcall(function()
                if Flags.AutoBypassPopups then
                    DismissPopups()
                end
                if Flags.AutoTakeEggs then
                    RunAutoTakeEggs()
                end
                if Flags.AutoUpgradeRecycler or Flags.AutoUpgradeFeeder or Flags.AutoBuyFeeders or Flags.AutoUpgradeCoop or Flags.AutoOpenEggs then
                    DoUpgrades()
                end
            end)
            task.wait(1.5)
        end
    end)

    -- LOOP AUTO SELL CHICKENS
    task.spawn(function()
        while IsRunning do
            pcall(function()
                if Flags.AutoSellChickens and CheckBackpackFull() then
                    ExecuteAutoSell()
                end
            end)
            task.wait(2.0)
        end
    end)

    -- LOOP 2: ARENA, TOWER, REBIRTH, CHAOS
    task.spawn(function()
        while IsRunning do
            pcall(function()
                local pg = player:FindFirstChild("PlayerGui")
                if not pg then return end

                if ChickenInTower and (tick() - TowerSentTime >= 90) then
                    ChickenInTower = false
                    TowerSentTime = 0
                    LastTowerFinishedAt = tick()
                end

                if ChickenInArena and (tick() - ArenaSentTime >= 70) then
                    ChickenInArena = false
                    ArenaSentTime = 0
                end

                if Flags.AutoArena then
                    DismissArenaResults()
                    TryClickGuiAction("ArenaGoBattleBtn", {"go to battle"}, 15.0)
                end

                if Flags.AutoNoThanks then
                    for _, obj in ipairs(pg:GetDescendants()) do
                        local isMatch = false
                        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and IsVisibleGui(obj) then
                            local t = obj.Text:lower()
                            if t:find("no thanks") or t:find("nothanks") or t:find("no, thanks") or t:find("keep climbing") then
                                isMatch = true
                            end
                        end
                        if isMatch then
                            local target = obj
                            if not obj:IsA("TextButton") and not obj:IsA("ImageButton") then
                                target = obj:FindFirstAncestorWhichIsA("TextButton") or obj:FindFirstAncestorWhichIsA("ImageButton") or obj.Parent
                            end
                            if target then
                                ClickGuiButton(target)
                                if ChickenInTower then
                                    ChickenInTower = false
                                    LastTowerFinishedAt = tick()
                                end
                                break
                            end
                        end
                    end
                end

                if Flags.AutoRebirth then
                    CheckAndDoRebirth()
                end

                local pitActiveHold = (tick() < ChickenInPitUntil)
                if Flags.AutoStartTower and not ChickenInTower and not ChickenInArena and not pitActiveHold and (tick() - LastTowerFinishedAt >= 30.0) then
                    if CanRunAction("SendChickenTower", 5.0) then
                        SafeCall("TowerStart")
                        TryClickGuiAction("TowerBtnDirect", {"tower"}, 2.0)
                        ChickenInTower = true
                        TowerSentTime = tick()
                        TriggerFrontierFloorSequence()
                    end
                end

                if Flags.AutoArena and not ChickenInTower and not ChickenInArena and not pitActiveHold then
                    if CanRunAction("ExecuteArenaFight", 3.0) then
                        SafeCall("ArenaFight")
                        TryClickGuiAction("OpenArenaRail", {"arena"}, 2.0)
                        ChickenInArena = true
                        ArenaSentTime = tick()
                    end
                end

                if Flags.AutoStartChaos then
                    SendChickenToPit("Chaos", 0)
                end
            end)
            task.wait(0.5)
        end
    end)

    local function GetArenaCenter()
        for _, obj in ipairs(workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if (n:find("arena") or n:find("pen") or n:find("chickenarena")) and obj:IsA("BasePart") then return obj.Position end
        end
        return nil
    end

    -- LOOP 3: FARM SCRAPS & RECYCLE
    task.spawn(function()
        while IsRunning do
            pcall(function()
                RunEventCheck()

                local shouldFarm = Flags.AutoGrabScraps or Flags.AutoRecycleScrap or Flags.AutoRebirth
                if not shouldFarm then task.wait(0.3) return end

                local root = GetRoot()
                local hum = GetHumanoid()
                if not root or not hum or hum.Health <= 0 then task.wait(0.3) return end

                if Flags.AutoRebirth then CheckAndDoRebirth() end

                local targetCap = tonumber(Flags.ScrapCapacity) or 20
                if Flags.AutoGrabScraps and (CurrentBatchScraps < targetCap or not Flags.AutoRecycleScrap) then
                    local scrap = FindNearestArenaScrap()
                    if scrap then
                        CollectScrapPlate(scrap)
                    else
                        local arenaPos = GetArenaCenter()
                        if arenaPos and FlatDist(root.Position, arenaPos) > 20 then
                            WalkTo(arenaPos, 3.0, 6.0)
                        else
                            task.wait(0.15)
                        end
                    end
                elseif Flags.AutoRecycleScrap and (CurrentBatchScraps >= targetCap or not Flags.AutoGrabScraps) then
                    DoRecycleAtBase()
                end
            end)
            task.wait(0.02)
        end
    end)

    local Gui = Instance.new("ScreenGui", CoreGui)
    Gui.Name = "ERDEVA_HUB"
    Gui.ResetOnSpawn = false
    Gui.IgnoreGuiInset = true
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

    local TopLine = Instance.new("Frame", Top)
    TopLine.Size = UDim2.new(1, 0, 0, 1)
    TopLine.Position = UDim2.new(0, 0, 1, -1)
    TopLine.BackgroundColor3 = C.Border
    TopLine.BorderSizePixel = 0

    local HeaderLogo = nil
    if LogoAssetId then
        HeaderLogo = Instance.new("ImageLabel", Top)
        HeaderLogo.Size = UDim2.fromOffset(22, 22)
        HeaderLogo.Position = UDim2.fromOffset(10, 7)
        HeaderLogo.BackgroundTransparency = 1
        HeaderLogo.Image = LogoAssetId
        Instance.new("UICorner", HeaderLogo).CornerRadius = UDim.new(0, 4)
    end

    local Title = Instance.new("TextLabel", Top)
    Title.Size = UDim2.new(1, HeaderLogo and -95 or -75, 1, 0)
    Title.Position = UDim2.fromOffset(HeaderLogo and 38 or 12, 0)
    Title.BackgroundTransparency = 1
    Title.Text = isTrialMode and "ERDEVA HUB [TRIAL 1H]" or "ERDEVA HUB v2.6"
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
    local CloseStroke = Instance.new("UIStroke", CloseBtn)
    CloseStroke.Color = C.Border
    CloseStroke.Thickness = 1

    CloseBtn.MouseEnter:Connect(function()
        tw(CloseBtn, {BackgroundColor3 = C.Red, TextColor3 = C.Txt}, 0.15)
        tw(CloseStroke, {Color = C.RedGlow}, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        tw(CloseBtn, {BackgroundColor3 = Color3.fromRGB(24, 27, 36), TextColor3 = C.Sub}, 0.15)
        tw(CloseStroke, {Color = C.Border}, 0.15)
    end)
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
    local MinStroke = Instance.new("UIStroke", MinBtn)
    MinStroke.Color = C.Border
    MinStroke.Thickness = 1

    MinBtn.MouseEnter:Connect(function()
        tw(MinBtn, {BackgroundColor3 = C.CardHover, TextColor3 = C.Txt}, 0.15)
        tw(MinStroke, {Color = C.Red}, 0.15)
    end)
    MinBtn.MouseLeave:Connect(function()
        tw(MinBtn, {BackgroundColor3 = Color3.fromRGB(24, 27, 36), TextColor3 = C.Sub}, 0.15)
        tw(MinStroke, {Color = C.Border}, 0.15)
    end)

    local MiniIcon = Instance.new("Frame", Gui)
    MiniIcon.Size = UDim2.fromOffset(50, 50)
    MiniIcon.Position = UDim2.new(0, 20, 0.5, -25)
    MiniIcon.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
    MiniIcon.BorderSizePixel = 0
    MiniIcon.Visible = false
    MiniIcon.Active = true
    Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 10)
    local MiniStroke = Instance.new("UIStroke", MiniIcon)
    MiniStroke.Color = C.Red
    MiniStroke.Thickness = 1.4

    if LogoAssetId then
        local IconImg = Instance.new("ImageLabel", MiniIcon)
        IconImg.Size = UDim2.new(1, -12, 1, -12)
        IconImg.Position = UDim2.fromOffset(6, 6)
        IconImg.BackgroundTransparency = 1
        IconImg.Image = LogoAssetId
        Instance.new("UICorner", IconImg).CornerRadius = UDim.new(0, 7)
    else
        local MiniLabel = Instance.new("TextLabel", MiniIcon)
        MiniLabel.Size = UDim2.new(1, 0, 1, 0)
        MiniLabel.BackgroundTransparency = 1
        MiniLabel.Text = "ERDEVA"
        MiniLabel.TextColor3 = C.Red
        MiniLabel.TextSize = 9
        MiniLabel.Font = Enum.Font.GothamBold
        MiniLabel.TextXAlignment = Enum.TextXAlignment.Center
    end

    local minState = false
    local function SetMinimized(state)
        minState = state
        if state then
            tw(Main, {Size = UDim2.fromOffset(W, 0), BackgroundTransparency = 1}, 0.2)
            task.delay(0.2, function()
                Main.Visible = false
                MiniIcon.Visible = true
                tw(MiniIcon, {BackgroundTransparency = 0}, 0.15)
            end)
        else
            MiniIcon.Visible = false
            Main.Visible = true
            Main.BackgroundTransparency = 0
            tw(Main, {Size = UDim2.fromOffset(W, H)}, 0.2)
        end
    end

    MinBtn.MouseButton1Click:Connect(function() SetMinimized(true) end)

    local miniDragging = false
    local miniDragStart = nil
    local miniStartPos = nil
    local miniMoveDist = 0

    MiniIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            miniDragging = true
            miniDragStart = input.Position
            miniStartPos = MiniIcon.Position
            miniMoveDist = 0

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    miniDragging = false
                    connection:Disconnect()
                    if miniMoveDist < 8 then
                        SetMinimized(false)
                    end
                end
            end)
        end
    end)

    local mainDrag = false
    local mainDragStart = nil
    local mainStartPos = nil

    Top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mainDrag = true
            mainDragStart = input.Position
            mainStartPos = Main.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    mainDrag = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            if mainDrag and not minState then
                local delta = input.Position - mainDragStart
                Main.Position = UDim2.new(0.5, math.clamp(mainStartPos.X.Offset + delta.X, -vs.X/2 + W/2 + 10, vs.X/2 - W/2 - 10),
                                          0.5, math.clamp(mainStartPos.Y.Offset + delta.Y, -vs.Y/2 + H/2 + 25, vs.Y/2 - H/2 - 10))
            end
            if miniDragging and MiniIcon.Visible then
                local delta = input.Position - miniDragStart
                miniMoveDist = (Vector2.new(delta.X, delta.Y)).Magnitude
                local curX = miniStartPos.X.Offset + delta.X
                local curY = miniStartPos.Y.Offset + delta.Y
                local curScaleX = miniStartPos.X.Scale
                local curScaleY = miniStartPos.Y.Scale
                local absX = curScaleX * vs.X + curX
                local absY = curScaleY * vs.Y + curY
                absX = math.clamp(absX, 4, vs.X - 56)
                absY = math.clamp(absY, 4, vs.Y - 56)
                MiniIcon.Position = UDim2.new(0, absX, 0, absY)
            end
        end
    end)

    local TabFrame = Instance.new("Frame", Main)
    TabFrame.Size = UDim2.new(1, -16, 0, 30)
    TabFrame.Position = UDim2.fromOffset(8, 42)
    TabFrame.BackgroundColor3 = C.TabBg
    TabFrame.BorderSizePixel = 0
    Instance.new("UICorner", TabFrame).CornerRadius = UDim.new(0, 6)
    local TabFrameStroke = Instance.new("UIStroke", TabFrame)
    TabFrameStroke.Color = C.Border
    TabFrameStroke.Thickness = 1

    local TabList = Instance.new("UIListLayout", TabFrame)
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabList.VerticalAlignment = Enum.VerticalAlignment.Center
    TabList.Padding = UDim.new(0, 4)

    local TabPadding = Instance.new("UIPadding", TabFrame)
    TabPadding.PaddingLeft = UDim.new(0, 3)
    TabPadding.PaddingRight = UDim.new(0, 3)
    TabPadding.PaddingTop = UDim.new(0, 3)
    TabPadding.PaddingBottom = UDim.new(0, 3)

    local Content = Instance.new("ScrollingFrame", Main)
    Content.Size = UDim2.new(1, -16, 1, -82)
    Content.Position = UDim2.fromOffset(8, 76)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 2
    Content.ScrollBarImageColor3 = C.Red
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local CL = Instance.new("UIListLayout", Content)
    CL.Padding = UDim.new(0, 4)

    local Pages, TabBtns = {}, {}
    local function SetTab(name)
        for n, p in pairs(Pages) do p.Visible = (n == name) end
        for n, btnData in pairs(TabBtns) do
            local isSel = (n == name)
            tw(btnData.btn, {BackgroundColor3 = isSel and Color3.fromRGB(38, 18, 24) or Color3.fromRGB(18, 20, 26)}, 0.15)
            tw(btnData.label, {TextColor3 = isSel and C.Txt or C.Sub}, 0.15)
            tw(btnData.icon, {ImageColor3 = isSel and C.Red or C.Sub}, 0.15)
            tw(btnData.stroke, {Color = isSel and C.Red or Color3.fromRGB(26, 29, 38)}, 0.15)
        end
    end

    local TabIcons = {
        Farm   = "rbxassetid://10734965572",
        Plot   = "rbxassetid://6031265976",
        Battle = "rbxassetid://10734975692",
        Events = "rbxassetid://6031075931",
        Info   = "rbxassetid://6031154871"
    }

    local MakeTab = function(name, order)
        local btn = Instance.new("TextButton", TabFrame)
        btn.Size = UDim2.new(0.2, -4, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        local bStroke = Instance.new("UIStroke", btn)
        bStroke.Color = Color3.fromRGB(26, 29, 38)
        bStroke.Thickness = 1

        local icon = Instance.new("ImageLabel", btn)
        icon.Size = UDim2.fromOffset(14, 14)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 8, 0.5, 0)
        icon.BackgroundTransparency = 1
        icon.Image = TabIcons[name] or "rbxassetid://6031154871"
        icon.ImageColor3 = C.Sub

        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.new(1, -26, 1, 0)
        label.Position = UDim2.fromOffset(24, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = C.Sub
        label.TextSize = 10
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left

        TabBtns[name] = { btn = btn, icon = icon, label = label, stroke = bStroke }

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

    local function AddToggle(parent, label, key, iconAsset)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border
        fStroke.Thickness = 1

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -54, 1, 0)
        l.Position = UDim2.fromOffset(10, 0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Txt
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        if iconAsset then
            local crown = Instance.new("ImageLabel", f)
            crown.Size = UDim2.fromOffset(14, 14)
            crown.Position = UDim2.fromOffset(88, 8)
            crown.BackgroundTransparency = 1
            crown.Image = "rbxassetid://7733765398"
            crown.ImageColor3 = Color3.fromRGB(241, 196, 15)
        end

        local b = Instance.new("TextButton", f)
        b.Size = UDim2.fromOffset(36, 18)
        b.Position = UDim2.new(1, -44, 0.5, -9)
        b.BackgroundColor3 = C.Off
        b.Text = ""
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = C.Border
        bStroke.Thickness = 1

        local k = Instance.new("Frame", b)
        k.Size = UDim2.fromOffset(12, 12)
        k.Position = UDim2.fromOffset(3, 3)
        k.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        Instance.new("UICorner", k).CornerRadius = UDim.new(1, 0)

        local function upd(on)
            tw(b, {BackgroundColor3 = (on and C.Red or C.Off)})
            tw(bStroke, {Color = (on and C.RedGlow or C.Border)})
            tw(k, {Position = (on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3))})
            tw(fStroke, {Color = (on and Color3.fromRGB(55, 26, 34) or C.Border)})
        end

        ToggleUpdaters[key] = upd
        upd(Flags[key])

        b.MouseButton1Click:Connect(function()
            local ns = not Flags[key]
            SetFlag(key, ns)
            if key == "AutoRebirth" then
                if ns then
                    SetFlag("AutoUpgradeRecycler", true)
                    SetFlag("AutoBuyFeeders", true)
                    SetFlag("AutoUpgradeFeeder", true)
                    SetFlag("AutoUpgradeCoop", true)
                    SetFlag("AutoStartTower", true)
                    SetFlag("AutoNoThanks", true)
                    SetFlag("AutoBypassPopups", true)
                else
                    SetFlag("AutoUpgradeRecycler", false)
                    SetFlag("AutoBuyFeeders", false)
                    SetFlag("AutoUpgradeFeeder", false)
                    SetFlag("AutoUpgradeCoop", false)
                    SetFlag("AutoStartTower", false)
                    SetFlag("AutoNoThanks", false)
                    SetFlag("AutoBypassPopups", false)
                end
            end
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
        bStroke.Thickness = 1

        b.MouseEnter:Connect(function()
            tw(b, {BackgroundColor3 = C.CardHover})
            tw(bStroke, {Color = C.Red})
        end)
        b.MouseLeave:Connect(function()
            tw(b, {BackgroundColor3 = C.Card})
            tw(bStroke, {Color = C.Border})
        end)

        b.MouseButton1Click:Connect(function()
            tw(b, {BackgroundColor3 = C.Red}, 0.1)
            task.delay(0.2, function() tw(b, {BackgroundColor3 = C.Card}, 0.15) end)
            if callback then callback(b) end
        end)
        return b
    end

    local function AddBadge(parent, label, badgeText)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border
        fStroke.Thickness = 1

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -95, 1, 0)
        l.Position = UDim2.fromOffset(10, 0)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Sub
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        local b = Instance.new("TextLabel", f)
        b.Size = UDim2.fromOffset(80, 20)
        b.Position = UDim2.new(1, -88, 0.5, -10)
        b.BackgroundColor3 = Color3.fromRGB(28, 31, 42)
        b.Text = badgeText
        b.TextColor3 = Color3.fromRGB(160, 170, 190)
        b.TextSize = 9
        b.Font = Enum.Font.GothamBold
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = Color3.fromRGB(40, 45, 60)
        bStroke.Thickness = 1
    end

    local function AddSlider(parent, label, maxV, defV, key)
        local f = Instance.new("Frame", parent)
        f.Size = UDim2.new(1, 0, 0, 36)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border
        fStroke.Thickness = 1

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -65, 0, 16)
        l.Position = UDim2.fromOffset(10, 3)
        l.BackgroundTransparency = 1
        l.Text = label
        l.TextColor3 = C.Txt
        l.TextSize = 11
        l.Font = Enum.Font.GothamMedium
        l.TextXAlignment = Enum.TextXAlignment.Left

        local vl = Instance.new("TextLabel", f)
        vl.Size = UDim2.fromOffset(50, 16)
        vl.Position = UDim2.new(1, -58, 0, 3)
        vl.BackgroundTransparency = 1
        vl.Text = tostring(defV) .. "/" .. tostring(maxV)
        vl.TextColor3 = C.Red
        vl.TextSize = 11
        vl.Font = Enum.Font.GothamBold
        vl.TextXAlignment = Enum.TextXAlignment.Right

        local bar = Instance.new("Frame", f)
        bar.Size = UDim2.new(1, -20, 0, 4)
        bar.Position = UDim2.fromOffset(10, 23)
        bar.BackgroundColor3 = Color3.fromRGB(36, 40, 52)
        bar.BorderSizePixel = 0
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", bar)
        fill.Size = UDim2.new(defV / maxV, 0, 1, 0)
        fill.BackgroundColor3 = C.Red
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local sld = false
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sld = true end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then sld = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if sld and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local r = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                fill.Size = UDim2.new(r, 0, 1, 0)
                local v = math.max(1, math.floor(r * maxV + 0.5))
                vl.Text = tostring(v) .. "/" .. tostring(maxV)
                Flags[key] = v
            end
        end)
    end

    local FarmPage   = MakeTab("Farm",   1)
    local PlotPage   = MakeTab("Plot",   2)
    local BattlePage = MakeTab("Battle", 3)
    local EventsPage = MakeTab("Events", 4)
    local InfoPage   = MakeTab("Info",   5)

    -- FARM PAGE CONTROLS
    AddToggle(FarmPage, "Auto Take Eggs",       "AutoTakeEggs")
    AddToggle(FarmPage, "Auto Grab Scraps",      "AutoGrabScraps")
    AddToggle(FarmPage, "Auto Recycle Scrap",    "AutoRecycleScrap")
    AddSlider(FarmPage, "Scrap Capacity", 50, 20, "ScrapCapacity")
    AddToggle(FarmPage, "Auto Open Eggs",        "AutoOpenEggs")

    -- AUTO SELL CHICKENS CONTROLS
    AddToggle(FarmPage, "Auto Sell Chickens",    "AutoSellChickens")
    AddButton(FarmPage, "SELL CHICKENS NOW", function()
        ExecuteAutoSell()
    end)
    AddToggle(FarmPage, "Sell [Common]",         "SellCommon")
    AddToggle(FarmPage, "Sell [Uncommon]",       "SellUncommon")
    AddToggle(FarmPage, "Sell [Rare]",           "SellRare")
    AddToggle(FarmPage, "Sell [Epic]",           "SellEpic")
    AddToggle(FarmPage, "Sell [Legendary]",      "SellLegendary")
    AddToggle(FarmPage, "Sell [Mythic/Divine]",  "SellMythic")
    AddToggle(FarmPage, "Sell [Cosmic]",         "SellCosmic")
    AddToggle(FarmPage, "Sell [Secret]",         "SellSecret")

    -- PLOT PAGE CONTROLS
    AddToggle(PlotPage, "Auto Rebirth", "AutoRebirth", true)
    AddButton(PlotPage, "[LOCK] Set Recycler Pad", function(btn)
        local root = GetRoot()
        if root then
            LOCKED_RECYCLER_POS = root.Position
            btn.Text = "Recycler Pad Locked"
            Notify("ERDEVA HUB", "Recycler Pad Locked", 3.0)
            task.delay(2.5, function() btn.Text = "[LOCK] Set Recycler Pad" end)
        end
    end)
    AddToggle(PlotPage, "Auto Buy Feeders",      "AutoBuyFeeders")
    AddToggle(PlotPage, "Auto Upgrade Feeder",   "AutoUpgradeFeeder")
    AddToggle(PlotPage, "Auto Upgrade Recycler", "AutoUpgradeRecycler")
    AddToggle(PlotPage, "Auto Upgrade Coop",     "AutoUpgradeCoop")

    -- BATTLE PAGE CONTROLS
    AddToggle(BattlePage, "Auto Start Tower",     "AutoStartTower")
    AddToggle(BattlePage, "Auto Arena",           "AutoArena")
    AddToggle(BattlePage, "Auto Close No Thanks", "AutoNoThanks")
    AddToggle(BattlePage, "Auto Close Popups",   "AutoBypassPopups")
    AddButton(BattlePage, "Send Chicken to Pit", function()
        SendChickenToPit("Manual", 0)
        Notify("ERDEVA HUB", "Sent chicken to Pit", 2)
    end)

    -- EVENTS PAGE CONTROLS
    AddToggle(EventsPage, "Auto UFO", "AutoUFO")
    AddBadge(EventsPage, "Auto Golden Goose",    "COMING SOON")
    AddBadge(EventsPage, "Auto Chicken Boss",    "COMING SOON")
    AddBadge(EventsPage, "Auto Admin Abuse",    "COMING SOON")

    local LiveCarriedLabel = nil
    local LiveTrialLabel = nil

    local function AddInfo(k, v, isLive, isTrial)
        local f = Instance.new("Frame", InfoPage)
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = C.Card
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local fStroke = Instance.new("UIStroke", f)
        fStroke.Color = C.Border
        fStroke.Thickness = 1

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

        if isLive then LiveCarriedLabel = r end
        if isTrial then LiveTrialLabel = r end
    end

    AddInfo("User",            player.Name, false, false)
    AddInfo("Hub Version",     "v2.6", false, false)
    AddInfo("Plates Grabbed",  "0 / 20", true, false)
    if isTrialMode then
        AddInfo("Trial Remaining", "Calculating...", false, true)
    else
        AddInfo("License Status", "VIP Premium", false, false)
    end

    local InfoSpacer = Instance.new("Frame", InfoPage)
    InfoSpacer.Size = UDim2.new(1, 0, 0, 4)
    InfoSpacer.BackgroundTransparency = 1

    local discBtn = AddButton(InfoPage, "Discord: discord.gg/P7g4jpZTU", function(btn)
        local discordUrl = "https://discord.gg/P7g4jpZTU"
        pcall(function()
            if setclipboard then
                setclipboard(discordUrl)
            elseif toclipboard then
                toclipboard(discordUrl)
            end
            if openurl then openurl(discordUrl) end
            if syn and syn.open_url then syn.open_url(discordUrl) end
        end)
        btn.Text = "Link Copied to Clipboard!"
        btn.BackgroundColor3 = C.Green
        Notify("ERDEVA HUB", "Discord Link Copied to Clipboard!", 2.5)
        task.delay(2.5, function()
            btn.Text = "Discord: discord.gg/P7g4jpZTU"
            btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        end)
    end)
    discBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

    task.spawn(function()
        while IsRunning do
            if LiveCarriedLabel and LiveCarriedLabel.Parent then
                LiveCarriedLabel.Text = tostring(CurrentBatchScraps) .. " / " .. tostring(Flags.ScrapCapacity or 20)
            end
            task.wait(0.1)
        end
    end)

    if isTrialMode then
        local currentRemaining = trialTimeLeft
        task.spawn(function()
            while IsRunning do
                if currentRemaining <= 0 then
                    IsRunning = false
                    Notify("ERDEVA HUB", "Trial Expired", 5)
                    Shutdown()
                    task.wait(0.5)
                    LaunchKeyUI(true)
                    break
                else
                    currentRemaining = currentRemaining - 1
                    local h = math.floor(currentRemaining / 3600)
                    local m = math.floor((currentRemaining % 3600) / 60)
                    local s = currentRemaining % 60
                    if LiveTrialLabel and LiveTrialLabel.Parent then
                        LiveTrialLabel.Text = string.format("%02dh %02dm %02ds", h, m, s)
                        LiveTrialLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
                    end
                end
                task.wait(1)
            end
        end)
    end

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
        else
            pcall(function() if delfile then delfile(KEY_FILE) end end)
        end
    end

    local isTrial, remainingTime, reason = RequestServerTrial()
    if isTrial and remainingTime > 0 then
        StartMainScript(true, remainingTime)
    else
        LaunchKeyUI(true)
    end
end

InitSystem()
