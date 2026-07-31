local function later(fn)
    if task and task.defer then return task.defer(fn) end
    if task and task.spawn then return task.spawn(fn) end
    if spawn then return spawn(fn) end
    return coroutine.wrap(fn)()
end

local function cached_http_get(url, filename)
    local local_path = "davestudio/" .. filename
    if _G.BypassCache then
        local content = game:HttpGet(url)
        if writefile and content and content ~= "" then
            pcall(function() writefile(local_path, content) end)
        end
        return content
    end
    if isfile and readfile and isfile(local_path) then
        later(function()
            local success, content = pcall(function() return game:HttpGet(url) end)
            if success and content and content ~= "" then
                writefile(local_path, content)
            end
        end)
        return readfile(local_path)
    else
        local content = game:HttpGet(url)
        if writefile and content and content ~= "" then
            pcall(function() writefile(local_path, content) end)
        end
        return content
    end
end

local Library = loadstring(cached_http_get("https://raw.githubusercontent.com/davestudio-code/davestudio/main/davestudio/Library.lua?t=" .. tostring(os.time()), "Library.lua"))()
Library.Scheme.FontColor = Color3.fromRGB(160, 165, 175)
Library:UpdateColorsUsingRegistry()

local GlobalUI = {}
GlobalUI.Library = Library

function GlobalUI.CreateWindow(title)
    local formattedTitle = title
    if title == "davestudio" then
        formattedTitle = "<font color=\"#FFFFFF\">dave</font><font color=\"#00C864\">studio</font>"
    end
    local Window = Library:CreateWindow({
        Title = formattedTitle,
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2
    })
    return Window
end

function GlobalUI.MakeCollapsible(groupbox, startCollapsed)
    local collapsed = not not startCollapsed
    local originalResize = groupbox.Resize
    
    local arrow = Instance.new("TextButton")
    arrow.Size = UDim2.new(0, 30, 0, 30)
    arrow.Position = UDim2.new(1, -35, 0, 2)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
    arrow.TextSize = 14
    arrow.Font = Enum.Font.RobotoMono
    arrow.Text = collapsed and ">" or "v"
    arrow.ZIndex = 100
    arrow.Parent = groupbox.Holder
    
    local headerButton = Instance.new("TextButton")
    headerButton.Size = UDim2.new(1, 0, 0, 34)
    headerButton.BackgroundTransparency = 1
    headerButton.Text = ""
    headerButton.ZIndex = 99
    headerButton.Parent = groupbox.Holder
    
    if collapsed then
        groupbox.Container.Visible = false
        groupbox.Holder.Size = UDim2.new(1, 0, 0, 34)
    end
    
    groupbox.Resize = function(self)
        if collapsed then
            groupbox.Holder.Size = UDim2.new(1, 0, 0, 34)
        else
            originalResize(self)
        end
        if groupbox.Tab and groupbox.Tab.RefreshSides then
            groupbox.Tab:RefreshSides()
        end
    end
    
    local function toggle()
        collapsed = not collapsed
        arrow.Text = collapsed and ">" or "v"
        groupbox.Container.Visible = not collapsed
        groupbox:Resize()
    end
    
    arrow.MouseButton1Click:Connect(toggle)
    headerButton.MouseButton1Click:Connect(toggle)
end

GlobalUI.DiscordWebhookUrl = ""

function GlobalUI.SetupDiscordWebhook(url)
    GlobalUI.DiscordWebhookUrl = url
end

function GlobalUI.SendStatusNotification(status, gameName, reason)
    if status == "ONLINE" then
        return
    end
    local url = GlobalUI.DiscordWebhookUrl
    if not url or url == "" or not string.match(url, "^https://discord%.com/api/webhooks/") then
        return
    end
    local HS = game:GetService("HttpService")
    local P = game:GetService("Players")
    local player = P.LocalPlayer
    local username = player and player.Name or "Unknown"
    local userId = player and tostring(player.UserId) or "0"
    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
    pcall(function()
        local api = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=150x150&format=Png&isCircular=false"
        local response = game:HttpGet(api)
        local decoded = HS:JSONDecode(response)
        if decoded and decoded.data and decoded.data[1] and decoded.data[1].imageUrl then
            avatarUrl = decoded.data[1].imageUrl
        end
    end)
    local disconnectReason = reason or "Client disconnected or game closed"
    local R = syn and syn.request
        or http and http.request
        or http_request
        or request
        or fluxus and fluxus.request
        or krnl and krnl.request
    local embed = {
        title = "Disconnection Detected",
        color = 15158332,
        thumbnail = {
            url = avatarUrl
        },
        fields = {
            { name = "Player", value = username, inline = true },
            { name = "Reason", value = disconnectReason, inline = true }
        },
        footer = {
            text = "davestudio | " .. os.date("%B %d, %Y %I:%M%p"),
            icon_url = "https://raw.githubusercontent.com/davegamedeveloper/gag/main/static/logo.png"
        }
    }
    pcall(function()
        if R then
            R({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HS:JSONEncode({
                    embeds = { embed }
                })
            })
        end
    end)
end

function GlobalUI.SendCustomWebhook(title, description, color, fields)
    local url = GlobalUI.DiscordWebhookUrl
    if not url or url == "" or not string.match(url, "^https://discord%.com/api/webhooks/") then
        return
    end
    local HS = game:GetService("HttpService")
    local R = syn and syn.request
        or http and http.request
        or http_request
        or request
        or fluxus and fluxus.request
        or krnl and krnl.request
        
    local embed = {
        title = title,
        description = description,
        color = color or 65416,
        fields = fields or {},
        footer = {
            text = "davestudio | " .. os.date("%B %d, %Y %I:%M%p"),
            icon_url = "https://raw.githubusercontent.com/davegamedeveloper/gag/main/static/logo.png"
        }
    }
    
    local ok, err = pcall(function()
        if R then
            R({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HS:JSONEncode({
                    embeds = { embed }
                })
            })
        end
    end)
    if not ok then
        warn("SendCustomWebhook error: " .. tostring(err))
    end
end

function GlobalUI.SendGuildWebhook(totalPoints, pointsGained)
    local url = GlobalUI.DiscordWebhookUrl
    if not url or url == "" or not string.match(url, "^https://discord%.com/api/webhooks/") then
        return
    end
    local HS = game:GetService("HttpService")
    local R = syn and syn.request
        or http and http.request
        or http_request
        or request
        or fluxus and fluxus.request
        or krnl and krnl.request

    local lp = game:GetService("Players").LocalPlayer
    local username = lp and lp.Name or "Unknown"
    local userId = lp and tostring(lp.UserId) or "1"
    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
    pcall(function()
        local api = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=150x150&format=Png&isCircular=false"
        local response = game:HttpGet(api)
        local decoded = HS:JSONDecode(response)
        if decoded and decoded.data and decoded.data[1] and decoded.data[1].imageUrl then
            avatarUrl = decoded.data[1].imageUrl
        end
    end)

    local function commaFormat(n)
        local str = tostring(n)
        return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end

    local totalStr = commaFormat(totalPoints or 0)
    local gainedStr = "+" .. commaFormat(pointsGained or 0)

    local embed = {
        author = {
            name = username,
            icon_url = avatarUrl
        },
        title = "🛡️ Guild Points",
        color = 65416,
        fields = {
            { name = "Total Points", value = totalStr, inline = true },
            { name = "Points Earned", value = gainedStr, inline = true }
        },
        footer = {
            text = "davestudio | " .. os.date("%B %d, %Y %I:%M%p"),
            icon_url = "https://raw.githubusercontent.com/davegamedeveloper/gag/main/static/logo.png"
        }
    }

    pcall(function()
        if R then
            R({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HS:JSONEncode({
                    embeds = { embed }
                })
            })
        end
    end)
end

local API_KEY_FILE = "davestudio/davestudio_key.txt"
GlobalUI.API_KEY = ""

if makefolder then
    pcall(function()
        makefolder("davestudio")
    end)
end

function GlobalUI.LoadKey()
    local key = ""
    if _G and _G.DAVESTUDIO_API_KEY then
        key = _G.DAVESTUDIO_API_KEY
    end
    if key and key ~= "" then
        GlobalUI.API_KEY = key
        return key
    end
    if isfile and readfile then
        local ok, data = pcall(function()
            if isfile(API_KEY_FILE) then
                return readfile(API_KEY_FILE)
            end
            return nil
        end)
        if ok and data then
            local clean = tostring(data):gsub("^%s+", ""):gsub("%s+$", "")
            if clean ~= "" then
                key = clean
            end
        end
    end
    if key and key ~= "" and _G then
        _G.DAVESTUDIO_API_KEY = key
    end
    GlobalUI.API_KEY = key
    return key
end

function GlobalUI.SaveKey(value)
    local clean = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    GlobalUI.API_KEY = clean
    if _G then
        _G.DAVESTUDIO_API_KEY = clean
    end
    if writefile then
        pcall(function()
            writefile(API_KEY_FILE, clean)
        end)
    end
end

function GlobalUI.ClearKey(reason)
    GlobalUI.API_KEY = ""
    if _G then
        _G.DAVESTUDIO_API_KEY = ""
    end
    if delfile and isfile then
        pcall(function()
            if isfile(API_KEY_FILE) then
                delfile(API_KEY_FILE)
            end
        end)
    end
    if warn then
        pcall(warn, "[davestudio] Key cleared: " .. tostring(reason or ""))
    end
end

function GlobalUI.VerifyKey(value)
    local clean = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if clean == "" then
        return false, "Key cannot be empty"
    end
    local R = syn and syn.request
        or http and http.request
        or http_request
        or request
        or fluxus and fluxus.request
        or krnl and krnl.request
    if not R then
        return true, "open"
    end
    local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    local url = string.format("https://gag.davestudio.online/verify?key=%s&hwid=%s", clean, hwid)
    local ok, res = pcall(function()
        return R({
            Url = url,
            Method = "GET"
        })
    end)
    if not ok or not res then
        return false, "Connection to server failed"
    end
    local c = tonumber(res.StatusCode or res.status_code or res.Status)
    if c == 200 then
        local HS = game:GetService("HttpService")
        local successDec, decoded = pcall(function()
            return HS:JSONDecode(res.Body or res.body)
        end)
        if successDec and decoded then
            if decoded.success then
                return true, "open", decoded.expires or decoded.expires_at or decoded.expiry or decoded.expiresIn
            else
                return false, decoded.message or "Invalid key"
            end
        end
    end
    if c == 403 then
        return false, "This key is already used. Use a different key or ask dave to reset it."
    end
    if c == 401 then
        return false, "That key is invalid or revoked."
    end
    return false, "Server Error: " .. tostring(c)
end

function GlobalUI.HandleAuthResponse(status, body)
    local c = tonumber(status)
    if c == 403 then
        local msg = "This key is already used. Use a different key or ask dave to reset it."
        if warn then
            pcall(warn, "[davestudio] " .. msg)
        end
        return true
    end
    if c == 401 then
        GlobalUI.ClearKey("key was rejected")
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "davestudio",
                Text  = "That key is invalid or revoked.",
                Duration = 8,
            })
        end)
        return true
    end
    return false
end

function GlobalUI.SetupKeySystem(Window, gameName, onLoadTabs, webhookDefault, onWebhookChanged)
    GlobalUI.SetupDiscordWebhook(webhookDefault)
    local AccountTab = Window:AddTab("Account", "user")
    local AccountGroup = AccountTab:AddLeftGroupbox("Key System", "key")
    GlobalUI.MakeCollapsible(AccountGroup)

    local keyInput = AccountGroup:AddInput("Key", {
        Default = GlobalUI.API_KEY or "",
        Numeric = false,
        Finished = false,
        Text = "Enter your key",
        Placeholder = "e.g davestudio.Skibidi"
    })

    local expireLabel = AccountGroup:AddLabel("⏳ Expires: <font color=\"#B0BEC5\">Checking...</font>")
    expireLabel.TextLabel.RichText = true

    local WebhookTab = Window:AddTab("Webhook", "message-square")
    local WebhookGroup = WebhookTab:AddLeftGroupbox("Webhook Settings", "message-square")
    GlobalUI.MakeCollapsible(WebhookGroup)

    local webhookInput = WebhookGroup:AddInput("DiscordWebhook", {
        Default = webhookDefault or "",
        Numeric = false,
        Finished = false,
        Text = "Discord Webhook",
        Placeholder = "paste your discord webhook URL here..."
    })

    if onWebhookChanged then
        webhookInput:OnChanged(function(val)
            onWebhookChanged(val)
        end)
    end

    AccountGroup:AddDivider()

    local P = game:GetService("Players")
    local username = P.LocalPlayer and P.LocalPlayer.Name or "Unknown"

    local runnerLabel = AccountGroup:AddLabel("👤 Account: <font color=\"#B0BEC5\">" .. username .. "</font>")
    runnerLabel.TextLabel.RichText = true

    local gameLabel = AccountGroup:AddLabel("🎮 Game: <font color=\"#B0BEC5\">" .. gameName .. "</font>")
    gameLabel.TextLabel.RichText = true

    local statusLabel = AccountGroup:AddLabel("🔑 Status: <font color=\"#FFE082\">Initializing...</font>")
    statusLabel.TextLabel.RichText = true

    local textLabel = statusLabel.TextLabel
    textLabel.TextWrapped = true
    textLabel.Size = UDim2.new(1, -10, 0, 30)
    textLabel.BackgroundColor3 = Color3.fromRGB(13, 15, 20)
    textLabel.BackgroundTransparency = 0.3
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = textLabel
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(35, 35, 35)
    stroke.Thickness = 1
    stroke.Parent = textLabel
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = textLabel

    AccountGroup:Resize()
    WebhookGroup:Resize()

    local saveKeyButton
    local tabs_loaded = false

    local function trigger_load_tabs()
        if tabs_loaded then return end
        local currentKey = GlobalUI.API_KEY
        if not currentKey or currentKey == "" then
            statusLabel:SetText("🔑 Status: <font color=\"#FFB74D\">Waiting for key...</font>")
            expireLabel:SetText("⏳ Expires: <font color=\"#FFB74D\">No key provided</font>")
            keyInput:SetVisible(true)
            saveKeyButton:SetVisible(true)
            AccountGroup:Resize()
            return
        end
        
        statusLabel:SetText("🔑 Status: <font color=\"#81D4FA\">Verifying...</font>")
        local is_valid, key_status, expires = GlobalUI.VerifyKey(currentKey)
        if not is_valid then
            statusLabel:SetText("🔑 Status: <font color=\"#FF8A80\">" .. tostring(key_status or "Invalid") .. "</font>")
            expireLabel:SetText("⏳ Expires: <font color=\"#FF8A80\">Unknown</font>")
            keyInput:SetVisible(true)
            saveKeyButton:SetVisible(true)
            AccountGroup:Resize()
            return
        end
        
        tabs_loaded = true
        local display_status = tostring(key_status or "linked")
        if display_status == "open" then
            display_status = "linked"
        end
        display_status = display_status:sub(1, 1):upper() .. display_status:sub(2)
        statusLabel:SetText("🔑 Status: <font color=\"#B0BEC5\">" .. display_status .. "</font>")
        
        local expiresText = "Never"
        if type(expires) == "number" then
            local secondsLeft = expires - os.time()
            if secondsLeft <= 0 then
                expiresText = "Expired"
            else
                local days = math.floor(secondsLeft / 86400)
                if days >= 1 then
                    expiresText = tostring(days) .. " day" .. (days > 1 and "s" or "")
                else
                    local hours = math.floor(secondsLeft / 3600)
                    expiresText = tostring(hours) .. " hour" .. (hours > 1 and "s" or "")
                end
            end
        elseif type(expires) == "string" then
            expiresText = expires
        end
        expireLabel:SetText("⏳ Expires: <font color=\"#B0BEC5\">" .. expiresText .. "</font>")
        
        keyInput:SetVisible(false)
        saveKeyButton:SetVisible(false)
        AccountGroup:Resize()
        
        task.spawn(function()
            pcall(onLoadTabs)
        end)
    end

    saveKeyButton = AccountGroup:AddButton({
        Text = "Verify & Save",
        Func = function()
            local value = tostring(keyInput.Value or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if value == "" then
                statusLabel:SetText("🔑 Status: <font color=\"#FF8A80\">Key cannot be empty</font>")
                return
            end
            statusLabel:SetText("🔑 Status: <font color=\"#81D4FA\">Verifying the key...</font>")
            task.spawn(function()
                local is_valid, key_status = GlobalUI.VerifyKey(value)
                if is_valid then
                    GlobalUI.SaveKey(value)
                    trigger_load_tabs()
                else
                    statusLabel:SetText("🔑 Status: <font color=\"#FF8A80\">" .. tostring(key_status or "Key is invalid or bound to another account") .. "</font>")
                end
            end)
        end
    })

    if GlobalUI.API_KEY and GlobalUI.API_KEY ~= "" then
        keyInput:SetVisible(false)
        saveKeyButton:SetVisible(false)
        task.spawn(trigger_load_tabs)
    else
        keyInput:SetVisible(true)
        saveKeyButton:SetVisible(true)
        statusLabel:SetText("🔑 Status: <font color=\"#FFB74D\">Waiting for key...</font>")
        expireLabel:SetText("⏳ Expires: <font color=\"#FFB74D\">No key provided</font>")
    end
    return AccountTab, WebhookTab
end

return GlobalUI

