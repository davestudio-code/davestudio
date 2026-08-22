local dsui = {}
dsui.__index = dsui

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
dsui.AccentColor = Color3.fromRGB(0, 200, 100)

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

function dsui:AddDefaultTabs(Window, Options)
    Options = Options or {}
    local rawKey = Options.Key or _G.DaveStudioKey or _G.DAVESTUDIO_API_KEY or "davestudio.SAMPLE_KEY_12345"
    local expiresText = Options.Expires or "28 Days"
    local DiscordLink = Options.DiscordLink or "discord.gg/nMkMhEQmBm"

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

    local hwidStr = "N/A"
    pcall(function()
        if gethwid then hwidStr = gethwid()
        elseif get_hwid then hwidStr = get_hwid()
        elseif syn and syn.get_device_id then hwidStr = syn.get_device_id()
        elseif getgenv and getgenv().gethwid then hwidStr = getgenv().gethwid()
        end
    end)
    if #hwidStr > 16 then
        hwidStr = string.sub(hwidStr, 1, 14) .. "..."
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
            hwidStr,
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

    local KeyInfoSection = AccountTab:Section({
        Title = "Key Info",
        Opened = false
    })

    local maskedKey = string.rep("•", #rawKey > 0 and math.min(#rawKey, 20) or 16)
    local isRevealed = false
    local keyStatusCard

    local function getKeyCardDesc()
        local currentKey = isRevealed and rawKey or maskedKey
        return "<font color=\"#d1d5db\">Expires:</font>  <font color=\"#00C864\"><b>" .. expiresText .. "</b></font>\n<font color=\"#d1d5db\">Key:</font>  <font color=\"#ffffff\"><b>" .. currentKey .. "</b></font>"
    end

    keyStatusCard = KeyInfoSection:Paragraph({
        Title = "Subscription License",
        Desc = getKeyCardDesc(),
        Image = "key",
        ImageSize = 24,
        Buttons = {
            {
                Title = "Show / Hide",
                Icon = "eye",
                Variant = "Secondary",
                Callback = function()
                    isRevealed = not isRevealed
                    if keyStatusCard and keyStatusCard.SetDesc then
                        keyStatusCard:SetDesc(getKeyCardDesc())
                    end
                end
            },
            {
                Title = "Copy Key",
                Icon = "copy",
                Variant = "Secondary",
                Callback = function()
                    if setclipboard then
                        setclipboard(rawKey)
                        WindUI:Notify({ Title = "Copied", Content = "License key copied to clipboard", Duration = 2 })
                    end
                end
            }
        }
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
