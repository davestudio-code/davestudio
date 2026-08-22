local dsui = {}
dsui.__index = dsui

local API_KEY_FILE = "davestudio/davestudio_key.txt"
dsui.API_KEY = ""
dsui.AccentColor = Color3.fromRGB(0, 200, 100)

local function loadCore()
    if isfolder and not isfolder("davestudio") then
        pcall(makefolder, "davestudio")
    end

    if isfile and readfile and isfile("davestudio/UI.lua") then
        local content = readfile("davestudio/UI.lua")
        if content and #content > 100 then
            local fn = loadstring(content)
            if fn then return fn() end
        end
    end

    local repoUrl = "https://raw.githubusercontent.com/davestudio-code/davestudio/main/davestudio/UI.lua"
    local ok, res = pcall(function()
        return game:HttpGet(repoUrl)
    end)
    if not ok or not res or #res < 100 then
        local fallbackUrl = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
        res = game:HttpGet(fallbackUrl)
    end

    if res and #res > 100 then
        if writefile then
            pcall(function()
                if isfolder and not isfolder("davestudio") then
                    makefolder("davestudio")
                end
                writefile("davestudio/UI.lua", res)
            end)
        end
        local fn = loadstring(res)
        if fn then return fn() end
    end

    error("Failed to load WindUI core library")
end

local WindUI = loadCore()
dsui.Core = WindUI

function dsui.GetHWID()
    local hwidStr = "N/A"
    pcall(function()
        if gethwid then hwidStr = gethwid()
        elseif get_hwid then hwidStr = get_hwid()
        elseif game:GetService("RbxAnalyticsService") and game:GetService("RbxAnalyticsService").GetClientId then
            hwidStr = game:GetService("RbxAnalyticsService"):GetClientId()
        elseif syn and syn.get_device_id then hwidStr = syn.get_device_id()
        elseif getgenv and getgenv().gethwid then hwidStr = getgenv().gethwid()
        end
    end)
    return hwidStr
end

function dsui.LoadKey()
    local key = ""
    if _G and (_G.DaveStudioKey or _G.DAVESTUDIO_API_KEY) then
        key = _G.DaveStudioKey or _G.DAVESTUDIO_API_KEY
    end
    if key and key ~= "" then
        dsui.API_KEY = key
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
        _G.DaveStudioKey = key
        _G.DAVESTUDIO_API_KEY = key
    end
    dsui.API_KEY = key
    return key
end

function dsui.SaveKey(value)
    local clean = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    dsui.API_KEY = clean
    if _G then
        _G.DaveStudioKey = clean
        _G.DAVESTUDIO_API_KEY = clean
    end
    if writefile then
        pcall(function()
            if isfolder and not isfolder("davestudio") and makefolder then
                makefolder("davestudio")
            end
            writefile(API_KEY_FILE, clean)
        end)
    end
end

function dsui.ClearKey()
    dsui.API_KEY = ""
    if _G then
        _G.DaveStudioKey = nil
        _G.DAVESTUDIO_API_KEY = nil
    end
    if delfile and isfile then
        pcall(function()
            if isfile(API_KEY_FILE) then
                delfile(API_KEY_FILE)
            end
        end)
    end
end

function dsui.VerifyKey(value)
    local clean = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if clean == "" then
        return false, "Key cannot be empty"
    end
    if not clean:find("^davestudio%.") then
        return false, "Invalid key format (must start with davestudio.)"
    end

    local R = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
        or (fluxus and fluxus.request)
        or (krnl and krnl.request)

    local hwid = dsui.GetHWID()
    local url = string.format("https://gag.davestudio.online/verify?key=%s&hwid=%s", clean, game:GetService("HttpService"):UrlEncode(hwid))

    local HS = game:GetService("HttpService")

    if R then
        local ok, res = pcall(function()
            return R({
                Url = url,
                Method = "GET"
            })
        end)
        if not ok or not res then
            return false, "Connection to authentication server failed"
        end
        local c = tonumber(res.StatusCode or res.status_code or res.Status)
        if c == 200 then
            local successDec, decoded = pcall(function()
                return HS:JSONDecode(res.Body or res.body)
            end)
            if successDec and decoded then
                if decoded.success then
                    return true, "Linked", decoded.expires or decoded.expires_at or decoded.expiry
                else
                    return false, decoded.message or "Invalid key"
                end
            end
        end
        if c == 403 then
            return false, "Key bound to another device or clone limit reached"
        end
        if c == 401 then
            return false, "That key is invalid or revoked"
        end
        return false, "Server Error: " .. tostring(c)
    else
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and res then
            local successDec, decoded = pcall(function()
                return HS:JSONDecode(res)
            end)
            if successDec and decoded then
                if decoded.success then
                    return true, "Linked", decoded.expires or decoded.expires_at or decoded.expiry
                else
                    return false, decoded.message or "Invalid key"
                end
            end
        end
        return false, "Failed to connect to authentication server"
    end
end

function dsui:CreateWindow(Config)
    Config = Config or {}

    local Title = Config.Title or "<font color=\"#FFFFFF\">dave</font><font color=\"#00C864\">studio</font>"
    local Icon = Config.Icon or "cat"
    local Folder = Config.Folder or "davestudio/sae"
    local Size = Config.Size or UDim2.fromOffset(640, 480)
    local Resizable = true
    if Config.Resizable ~= nil then
        Resizable = Config.Resizable
    end

    if isfolder and makefolder then
        pcall(function()
            if not isfolder("davestudio") then
                makefolder("davestudio")
            end
            if Folder and not isfolder(Folder) then
                makefolder(Folder)
            end
        end)
    end

    local Window = WindUI:CreateWindow({
        Title = Title,
        Icon = Icon,
        Author = Config.Author or nil,
        Folder = Folder,
        Size = Size,
        Theme = "Dark",
        Resizable = Resizable,
        Keybind = Config.Keybind or Enum.KeyCode.LeftControl
    })

    local originalTab = Window.Tab
    function Window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        tabConfig.IconColor = tabConfig.IconColor or dsui.AccentColor

        local tabObj = originalTab(Window, tabConfig)

        task.defer(function()
            pcall(function()
                local guiParent = gethui and gethui() or game:GetService("CoreGui")
                for _, gui in ipairs(guiParent:GetChildren()) do
                    if gui:IsA("ScreenGui") and (gui.Name:find("WindUI") or gui.Name:find("Window")) then
                        for _, desc in ipairs(gui:GetDescendants()) do
                            if desc:IsA("ImageLabel") and desc.Name:lower():find("icon") and desc.Parent and desc.Parent.Name:lower():find("tab") then
                                desc.ImageColor3 = dsui.AccentColor
                            end
                        end
                    end
                end
            end)
        end)

        return tabObj
    end

    return Window
end

function dsui:SetupKeySystem(Window, Options)
    Options = Options or {}
    local gameName = Options.GameName or "Steal an Egg"
    local DiscordLink = Options.DiscordLink or "discord.gg/nMkMhEQmBm"
    local onLoadTabs = Options.OnLoadTabs

    dsui.LoadKey()

    local lp = game:GetService("Players").LocalPlayer
    local startTime = os.time()
    local avatarUrl = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(lp.UserId) .. "&w=150&h=150"

    local ageDays = lp.AccountAge
    local ageYears = math.floor(ageDays / 365)
    local ageStr = ageYears >= 1 and (ageYears .. (ageYears == 1 and " Year" or " Years")) or (ageDays .. " Days")
    local joinDateStr = os.date("%b %d, %Y", os.time() - (ageDays * 86400))
    local isPrem = lp.MembershipType == Enum.MembershipType.Premium and "<font color=\"#00C864\"><b>Premium</b></font>" or "<font color=\"#ffffff\"><b>Standard</b></font>"

    local execName = "Unknown"
    pcall(function()
        if identifyexecutor then execName = identifyexecutor()
        elseif syn then execName = "Synapse"
        elseif getexecutorname then execName = getexecutorname()
        end
    end)

    local hwidStr = dsui.GetHWID()
    local displayHwid = hwidStr
    if #displayHwid > 16 then
        displayHwid = string.sub(displayHwid, 1, 14) .. "..."
    end

    local function getDetailsText(sessionStr)
        return string.format(
            "  <font color=\"#d1d5db\">Username:</font>  <font color=\"#ffffff\"><b>%s</b></font>\n" ..
            "  <font color=\"#d1d5db\">Member Since:</font>  <font color=\"#ffffff\"><b>%s</b></font>\n" ..
            "  <font color=\"#d1d5db\">Account Age:</font>  <font color=\"#ffffff\"><b>%s</b></font>\n" ..
            "  <font color=\"#d1d5db\">Membership:</font>  %s\n\n" ..
            "<font color=\"#00C864\"><b>SYSTEM & SESSION</b></font>\n" ..
            "  <font color=\"#d1d5db\">Executor:</font>  <font color=\"#ffffff\"><b>%s</b></font>\n" ..
            "  <font color=\"#d1d5db\">HWID:</font>  <font color=\"#ffffff\"><b>%s</b></font>\n" ..
            "  <font color=\"#d1d5db\">Session:</font>  <font color=\"#ffffff\"><b>%s</b></font>",
            lp.Name,
            joinDateStr,
            ageStr,
            isPrem,
            execName,
            displayHwid,
            sessionStr
        )
    end

    local AccountTab = Window:Tab({
        Title = "Account",
        Icon = "user",
        IconColor = dsui.AccentColor
    })

    local ProfileSection = AccountTab:Section({
        Title = "Player Profile",
        Opened = true
    })

    ProfileSection:Paragraph({
        Title = "Hi, " .. (lp.DisplayName ~= "" and lp.DisplayName or lp.Name) .. "!",
        Desc = "<font color=\"#00C864\"><b>● ONLINE</b></font>   <font color=\"#94a3b8\">@" .. lp.Name .. "</font>",
        Image = avatarUrl,
        ImageSize = 54
    })

    local detailsCard = ProfileSection:Paragraph({
        Title = "<font color=\"#00C864\"><b>ACCOUNT</b></font>",
        Desc = getDetailsText("00h 00m 00s")
    })

    task.spawn(function()
        while true do
            task.wait(1)
            local diff = os.time() - startTime
            local hrs = math.floor(diff / 3600)
            local mins = math.floor((diff % 3600) / 60)
            local secs = diff % 60
            local timerStr = string.format("%02dh %02dm %02ds", hrs, mins, secs)
            pcall(function()
                if detailsCard and detailsCard.SetDesc then
                    detailsCard:SetDesc(getDetailsText(timerStr))
                end
            end)
        end
    end)

    local KeySystemSection = AccountTab:Section({
        Title = "Key System",
        Opened = true
    })

    local statusCard = KeySystemSection:Paragraph({
        Title = "License Status",
        Desc = "<font color=\"#d1d5db\">Status:</font>  <font color=\"#FFE082\"><b>Initializing...</b></font>\n<font color=\"#d1d5db\">Expires:</font>  <font color=\"#94a3b8\">Checking...</font>",
        Image = "key",
        ImageSize = 24
    })

    local enteredKeyBuffer = dsui.API_KEY or ""

    local keyInputField = KeySystemSection:Input({
        Title = "License Key",
        Desc = "Enter your license key to unlock features",
        Placeholder = "davestudio.xxxx",
        Default = dsui.API_KEY or "",
        Callback = function(val)
            enteredKeyBuffer = tostring(val or ""):gsub("^%s+", ""):gsub("%s+$", "")
        end
    })

    local tabsLoaded = false
    local verifyButton

    local function trigger_load_tabs()
        if tabsLoaded then return end
        local currentKey = dsui.API_KEY
        if not currentKey or currentKey == "" then
            pcall(function()
                if statusCard and statusCard.SetDesc then
                    statusCard:SetDesc("<font color=\"#d1d5db\">Status:</font>  <font color=\"#FFB74D\"><b>Waiting for key...</b></font>\n<font color=\"#d1d5db\">Expires:</font>  <font color=\"#94a3b8\">No key provided</font>")
                end
            end)
            return
        end

        pcall(function()
            if statusCard and statusCard.SetDesc then
                statusCard:SetDesc("<font color=\"#d1d5db\">Status:</font>  <font color=\"#81D4FA\"><b>Verifying with server...</b></font>\n<font color=\"#d1d5db\">Expires:</font>  <font color=\"#94a3b8\">Checking...</font>")
            end
        end)

        task.spawn(function()
            local is_valid, key_status, expires = dsui.VerifyKey(currentKey)
            if not is_valid then
                pcall(function()
                    if statusCard and statusCard.SetDesc then
                        statusCard:SetDesc("<font color=\"#d1d5db\">Status:</font>  <font color=\"#FF8A80\"><b>" .. tostring(key_status or "Invalid") .. "</b></font>\n<font color=\"#d1d5db\">Expires:</font>  <font color=\"#94a3b8\">Unknown</font>")
                    end
                end)
                return
            end

            tabsLoaded = true
            local expiresText = "Never"
            if type(expires) == "number" then
                local secondsLeft = expires - os.time()
                if secondsLeft <= 0 then
                    expiresText = "Expired"
                else
                    local days = math.floor(secondsLeft / 86400)
                    if days >= 1 then
                        expiresText = tostring(days) .. " Day" .. (days > 1 and "s" or "")
                    else
                        local hours = math.floor(secondsLeft / 3600)
                        expiresText = tostring(hours) .. " Hour" .. (hours > 1 and "s" or "")
                    end
                end
            elseif type(expires) == "string" then
                expiresText = expires
            end

            local maskedKey = string.rep("•", #currentKey > 0 and math.min(#currentKey, 20) or 16)
            local isRevealed = false

            local function updateActiveKeyDesc()
                local displayed = isRevealed and currentKey or maskedKey
                return "<font color=\"#d1d5db\">Status:</font>  <font color=\"#00C864\"><b>● Linked</b></font>\n" ..
                    "<font color=\"#d1d5db\">Expires:</font>  <font color=\"#00C864\"><b>" .. expiresText .. "</b></font>\n" ..
                    "<font color=\"#d1d5db\">Key:</font>  <font color=\"#ffffff\"><b>" .. displayed .. "</b></font>"
            end

            pcall(function()
                if statusCard and statusCard.SetDesc then
                    statusCard:SetDesc(updateActiveKeyDesc())
                end
                if statusCard and statusCard.SetButtons then
                    statusCard:SetButtons({
                        {
                            Title = "Show / Hide",
                            Icon = "eye",
                            Variant = "Secondary",
                            Callback = function()
                                isRevealed = not isRevealed
                                statusCard:SetDesc(updateActiveKeyDesc())
                            end
                        },
                        {
                            Title = "Copy Key",
                            Icon = "copy",
                            Variant = "Secondary",
                            Callback = function()
                                if setclipboard then
                                    setclipboard(currentKey)
                                    WindUI:Notify({ Title = "Copied", Content = "License key copied to clipboard", Duration = 2 })
                                end
                            end
                        }
                    })
                end
            end)

            WindUI:Notify({
                Title = "Access Granted",
                Content = "Welcome to " .. gameName .. "!",
                Duration = 3
            })

            if onLoadTabs and type(onLoadTabs) == "function" then
                task.spawn(function()
                    pcall(onLoadTabs)
                end)
            end
        end)
    end

    verifyButton = KeySystemSection:Button({
        Title = "Verify & Save Key",
        Desc = "Authenticate key and unlock all game tabs",
        Icon = "check-circle",
        Callback = function()
            local value = tostring(enteredKeyBuffer or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if value == "" then
                WindUI:Notify({ Title = "Error", Content = "Key cannot be empty", Duration = 2 })
                return
            end
            pcall(function()
                if statusCard and statusCard.SetDesc then
                    statusCard:SetDesc("<font color=\"#d1d5db\">Status:</font>  <font color=\"#81D4FA\"><b>Verifying...</b></font>\n<font color=\"#d1d5db\">Expires:</font>  <font color=\"#94a3b8\">Checking...</font>")
                end
            end)
            task.spawn(function()
                local is_valid, key_status, expires = dsui.VerifyKey(value)
                if is_valid then
                    dsui.SaveKey(value)
                    trigger_load_tabs()
                else
                    pcall(function()
                        if statusCard and statusCard.SetDesc then
                            statusCard:SetDesc("<font color=\"#d1d5db\">Status:</font>  <font color=\"#FF8A80\"><b>" .. tostring(key_status or "Invalid key") .. "</b></font>\n<font color=\"#d1d5db\">Expires:</font>  <font color=\"#94a3b8\">Unknown</font>")
                        end
                    end)
                    WindUI:Notify({ Title = "Authentication Failed", Content = tostring(key_status or "Invalid Key"), Duration = 3 })
                end
            end)
        end
    })

    local SettingsTab = Window:Tab({
        Title = "Settings",
        Icon = "settings",
        IconColor = dsui.AccentColor
    })

    local InterfaceSection = SettingsTab:Section({
        Title = "Interface",
        Opened = true
    })

    InterfaceSection:Keybind({
        Title = "UI Toggle Key",
        Default = Enum.KeyCode.LeftControl,
        Callback = function()
            Window:Toggle()
        end
    })

    local CommunitySection = SettingsTab:Section({
        Title = "Community",
        Opened = true
    })

    CommunitySection:Button({
        Title = DiscordLink,
        Desc = "Click to copy invite link",
        Icon = "message-circle",
        Callback = function()
            if setclipboard then
                setclipboard("https://" .. string.gsub(DiscordLink, "https?://", ""))
                WindUI:Notify({ Title = "Copied", Content = "Discord link copied to clipboard", Duration = 2 })
            end
        end
    })

    local ScriptSection = SettingsTab:Section({
        Title = "Script Management",
        Opened = true
    })

    ScriptSection:Button({
        Title = "Unload Script",
        Desc = "Close and cleanup UI",
        Icon = "log-out",
        Callback = function()
            Window:Destroy()
        end
    })

    pcall(function()
        if AccountTab.Select then
            AccountTab:Select()
        end
    end)

    trigger_load_tabs()

    return {
        AccountTab = AccountTab,
        SettingsTab = SettingsTab
    }
end

function dsui:Notify(Title, Content, Duration)
    WindUI:Notify({
        Title = Title or "Notification",
        Content = Content or "",
        Duration = Duration or 4
    })
end

return dsui
