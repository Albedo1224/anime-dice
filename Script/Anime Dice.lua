repeat task.wait()
until game:IsLoaded() and game:FindFirstChild("CoreGui") and pcall(function() return game.CoreGui end)


local wl_usertype, wl_timeremain, wl_userid, wl_key = 0, {0, 0}, "0", 0
-- WHITELIST SYSTEM THERE
loadstring([[function LPH_NO_VIRTUALIZE(f) return f end;function LPH_JIT(f) return f end]])()


local requestedAttempt, mainLib = 0, nil
while task.wait() do
    requestedAttempt = requestedAttempt + 1
    local s, e = pcall(function()
        mainLib = loadstring(game:HttpGet("https://api.nousigi.com/scripts/uilibrarynew.lua"))()
    end)
    if isfile("!uilib.lua") then mainLib = loadstring(readfile("!uilib.lua"))() end
    if not mainLib or e then
        if e and (
                string.find(e, "ConnectFail")
                or string.find(e, "DnsResolve")
                or string.find(e, "overflow")
            ) then
            requestedAttempt = 0
        end
        if requestedAttempt > 5 then
            return plr:Kick("Something went wrong with the exploit while trying to load the UI Library, please rejoin\n" .. tostring(e))
        else
            print(e .. "\nSomething went wrong with the exploit while try to load the UI Library, retry in 5 seconds")
            task.wait(5)
        end
    else
        break
    end
end

mainLib.updateUser({
    ["user"] = wl_usertype,
    ["timeRemain"] = wl_timeremain,
    ["key"] = wl_key,
})

local plr = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

getgenv().AnimeDiceRuntime = (tonumber(getgenv().AnimeDiceRuntime) or 0) + 1
local runtime = getgenv().AnimeDiceRuntime

if type(getgenv().AnimeDiceRestore) == "function" then
    pcall(getgenv().AnimeDiceRestore)
end

local function sanitizeName(name)
    local text = tostring(name or "Player")
    text = string.gsub(text, "[\\/:*?\"<>|]", "_")
    text = string.gsub(text, "%s+", " ")
    if text == "" then
        text = "Player"
    end
    return text
end

local gameName = "AnimeDice"
local filePath = "Nousigi Hub/" .. gameName .. "_" .. sanitizeName(plr.Name) .. ".json"

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nested in value do
        copy[key] = deepCopy(nested)
    end
    return copy
end

local function normalizeScalar(value)
    if value == "true" then
        return true
    end
    if value == "false" then
        return false
    end
    if type(value) == "string" then
        local numberValue = tonumber(value)
        if numberValue ~= nil then
            return numberValue
        end
    end
    return value
end

local function deepMerge(dst, src)
    if type(src) ~= "table" then
        return dst
    end
    for key, value in src do
        if type(value) == "table" and type(dst[key]) == "table" then
            deepMerge(dst[key], value)
        else
            dst[key] = type(value) == "table" and deepCopy(value) or normalizeScalar(value)
        end
    end
    return dst
end

local function fillMissing(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return
    end
    for key, value in src do
        if dst[key] == nil then
            dst[key] = deepCopy(value)
        elseif type(value) == "table" and type(dst[key]) == "table" then
            fillMissing(dst[key], value)
        end
    end
end

local defaultSettings = {
    ["Auto Roll"] = true,
    ["Skip Animation"] = true,
    ["Hide Black Screen"] = true,
    ["Display Tower"] = true,
    ["Auto Claim Quests"] = true,
    ["Auto Equip Best"] = true,
    ["Auto Claim Cash"] = true,
    ["Auto Upgrade"] = true,
    ["Auto Rebirth"] = true,
    ["Auto Sell Units"] = true,
    ["Auto Dice Shop"] = true,
    ["Auto Pick Tower"] = true,
    ["Auto Next Tower"] = true,
    ["Auto Infinity"] = true,
    ["Auto Rejoin"] = true,
    ["Auto Execute On Rejoin"] = true,
    ["Auto Jackpot Spin"] = true,
    ["Auto Use Lucky Spin"] = true,
    ["Auto Use Boost"] = true,
    ["Auto Redeem Codes"] = true,
    ["FPS Boost"] = true,
    ["Anti-AFK"] = true,
    ["Black Screen"] = true,
    ["Tower"] = "Dragon Tower",
    ["Tower Cleared"] = 0,
}

local Settings = deepCopy(defaultSettings)
if type(getgenv().Config) == "table" then
    deepMerge(Settings, getgenv().Config)
    fillMissing(Settings, defaultSettings)
else
    local loaded = nil
    if type(isfile) == "function" and isfile(filePath) then
        local okRead, raw = pcall(readfile, filePath)
        if okRead and type(raw) == "string" and raw ~= "" then
            local okJson, decoded = pcall(function()
                return HttpService:JSONDecode(raw)
            end)
            if okJson and type(decoded) == "table" then
                loaded = decoded
            elseif type(writefile) == "function" then
                pcall(writefile, filePath .. ".corrupt-" .. tostring(os.time()) .. ".txt", raw)
            end
        end
    end
    if type(loaded) == "table" then
        deepMerge(Settings, loaded)
    end
    fillMissing(Settings, defaultSettings)
end
getgenv().Settings = Settings

do
    if type(isfolder) == "function" and type(makefolder) == "function" then
        if not isfolder("Nousigi Hub") then
            pcall(makefolder, "Nousigi Hub")
        end
    end

    local lastEncoded = nil
    local function saveSettings(force)
        local okEncode, encoded = pcall(function()
            return HttpService:JSONEncode(Settings)
        end)
        if not okEncode or type(encoded) ~= "string" then
            return
        end
        if not force and encoded == lastEncoded then
            return
        end
        if type(writefile) ~= "function" then
            return
        end
        local okWrite = pcall(writefile, filePath, encoded)
        if okWrite then
            lastEncoded = encoded
        end
    end

    saveSettings(true)
    task.spawn(function()
        while runtime == getgenv().AnimeDiceRuntime do
            task.wait(2)
            if runtime ~= getgenv().AnimeDiceRuntime then
                return
            end
            saveSettings(false)
        end
    end)
    getgenv().AnimeDiceSaveSettings = saveSettings
end

do
    local Lighting = game:GetService("Lighting")
    local function dropLighting(inst)
        if typeof(inst) ~= "Instance" then
            return false
        end
        if string.find(inst.Name, "ImpactFrame", 1, true) or inst:IsA("ColorCorrectionEffect") then
            return false
        end
        return inst:IsA("BloomEffect")
            or inst:IsA("BlurEffect")
            or inst:IsA("SunRaysEffect")
            or inst:IsA("DepthOfFieldEffect")
            or inst:IsA("Atmosphere")
            or inst:IsA("Clouds")
            or inst:IsA("Sky")
    end

    local function keepImpactFrames()
        local names = {
            "WhiteImpactFrame",
            "BlackImpactFrame",
            "VFXImpactFrameWhite",
            "VFXImpactFrameBlack",
        }
        for _, name in names do
            if not Lighting:FindFirstChild(name) then
                local effect = Instance.new("ColorCorrectionEffect")
                effect.Name = name
                effect.Parent = Lighting
            end
        end
    end

    local function boostFpsNow()
        if Settings["FPS Boost"] ~= true then
            return
        end
        pcall(function()
            settings().Rendering.QualityLevel = 1
        end)
        pcall(function()
            local graphics = UserSettings():GetService("UserGameSettings")
            graphics.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel01
        end)
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1000000
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            Lighting.Brightness = 2
        end)
        pcall(function()
            Workspace.Terrain.Decoration = false
            Workspace.Terrain.WaterWaveSize = 0
            Workspace.Terrain.WaterWaveSpeed = 0
            Workspace.Terrain.WaterReflectance = 0
            Workspace.Terrain.WaterTransparency = 1
        end)
        for _, child in Lighting:GetChildren() do
            if dropLighting(child) then
                pcall(function()
                    child:Destroy()
                end)
            end
        end
        keepImpactFrames()
    end

    local oldConns = getgenv().AnimeDiceFpsConns
    if type(oldConns) == "table" then
        for _, conn in oldConns do
            pcall(function()
                conn:Disconnect()
            end)
        end
    end
    local conns = {}
    getgenv().AnimeDiceFpsConns = conns
    getgenv().AnimeDiceBoostFps = boostFpsNow

    conns[#conns + 1] = Lighting.DescendantAdded:Connect(LPH_NO_VIRTUALIZE(function(inst)
        if runtime ~= getgenv().AnimeDiceRuntime or Settings["FPS Boost"] ~= true then
            return
        end
        if dropLighting(inst) then
            pcall(function()
                inst:Destroy()
            end)
        end
    end))
    task.spawn(boostFpsNow)
end

local Network = ReplicatedStorage:WaitForChild("Network")
local Framework = ReplicatedStorage:WaitForChild("Framework")

local Net = {
    SetAutoRoll = Network.RollService.RE.SetAutoRoll,
    ClaimQuest = Network.QuestService.RE.Claim,
    EquipBest = Network.PlotService.RE.EquipBest,
    CollectBalance = Network.PlotService.RE.CollectBalance,
    BuyUpgrade = Network.RE.BuyUpgrade,
    Rebirth = Network.RebirthService.RE.Rebirth,
    BuyDice = Network.DiceShopService.RE.BuyDice,
    EquipDice = Network.DiceShopService.RE.EquipDice,
    SellInventory = Network.SellService.RF.SellInventory,
    EquipBestTower = Network.Towers.RE.EquipBestTowerTeam,
    CancelTower = Network.Towers.RF.CancelTower,
    CompleteTowerFloor = Network.Towers.RF.CompleteTowerFloor,
    BuyQuest = Network.QuestService.RE.Buy,
    UseSpin = Network.SpinService.RE.Use,
    UseBoost = Network.BoostService.RE.Use,
    RedeemCode = Network.MonetizationService.RE.RedeemCode,
    RollDice = Network.RollService.RF.RollDice,
}

local function tryRequire(inst)
    local ok, mod = pcall(require, inst)
    if ok then
        return mod
    end
    return nil
end

do
    local playerGui = plr:WaitForChild("PlayerGui", 30)
    if playerGui then
        playerGui:WaitForChild("Root", 30)
    end
end

local QuestConfig = tryRequire(Framework.Features.Quests.QuestConfig)
local RollController = tryRequire(Framework.Features.Rolling.RollController)
local DiceCatalog = tryRequire(Framework.Features.Rolling.Dice)
local UpgradeCatalog = tryRequire(Framework.Features.Upgrades.Upgrades)
local UpgradeTree = tryRequire(Framework.Features.Upgrades.TreeStructure)
local Rebirths = tryRequire(Framework.Features.Rebirth.Rebirths)
local TowerCatalog = tryRequire(Framework.Features.Towers.Towers)
local TowerController = tryRequire(Framework.Features.Towers.TowerController)
local DataController = tryRequire(Framework.Features.Data.DataController)
local SpinController = tryRequire(Framework.Features.Inventory.Kinds.Spin.SpinController)
local BuffController = tryRequire(Framework.Features.Buffs.BuffController)
local EntryRegistry = tryRequire(Framework.Features.Inventory.EntryRegistry)
local MonetizationConfig = tryRequire(Framework.Features.Monetization.MonetizationConfig)

local Farm = {
    status = "Idle",
    lastLog = "",
    lastLogAt = 0,
    autoRollAt = 0,
    hiddenAt = 0,
    hiddenAtom = nil,
    rollFn = nil,
    skipWaitOn = false,
    skipFns = {},
    claimAt = {},
    pending = {
        sell = tick(),
        tower = tick(),
    },
    statusLabel = nil,
    rejoining = false,
    rejoinWatch = false,
    boostUntil = {},
    floor = 0,
    floorSeen = 0,
    floorRun = 0,
    floorSession = 0,
    floorBest = 0,
    floorTower = "",
    floorLabel = nil,
    towerDisplay = nil,
    blackLabel = nil,
    floorHooked = false,
    getBuffHooked = false,
    getBuffTarget = nil,
    autoExecQueued = false,
    autoExecSaved = false,
    towerCleared = tonumber(Settings["Tower Cleared"]) or 0,
    towerArmed = false,
    towerWasIn = false,
    towerRunName = "",
    towerRunMax = 0,
    towerRunLow = nil,
    towerRetreat = false,
    towerRetreatPower = 0,
}

local function farmLog(key, text)
    local now = tick()
    if Farm.lastLog == key and now - Farm.lastLogAt < 4 then
        return
    end
    Farm.lastLog = key
    Farm.lastLogAt = now
    print("[AnimeDice] " .. tostring(text))
end

local function ready(key, waitTime)
    local now = tick()
    local last = Farm.pending[key] or 0
    if now - last < (waitTime or 1) then
        return false
    end
    Farm.pending[key] = now
    return true
end

local function fireRemote(remote, ...)
    if not remote then
        return false
    end
    local args = { ... }
    local ok = pcall(function()
        if typeof(remote) == "Instance" then
            remote:FireServer(unpack(args))
        elseif type(remote) == "table" and type(remote.Fire) == "function" then
            remote:Fire(unpack(args))
        end
    end)
    return ok
end

local function invokeRemote(remote, ...)
    if not remote then
        return false
    end
    local args = { ... }
    local ok, result = pcall(function()
        if typeof(remote) == "Instance" then
            return remote:InvokeServer(unpack(args))
        elseif type(remote) == "table" and type(remote.Invoke) == "function" then
            return remote:Invoke(unpack(args))
        end
    end)
    return ok, result
end

local function currentFloorLine()
    local towerName = Farm.floorTower
    if type(towerName) ~= "string" or towerName == "" then
        towerName = Settings["Tower"] or "Tower"
    end
    local line = "Current Floor " .. tostring(Farm.floor or 0) .. " | " .. tostring(towerName)
    if Farm.questHold then
        line = line .. " | Quests first"
        if type(Farm.questNote) == "string" and Farm.questNote ~= "" then
            line = line .. " " .. Farm.questNote
        end
    end
    return line
end

local function setStatus(text)
    local line = tostring(text) .. " | " .. currentFloorLine()
    Farm.status = line
    local label = Farm.statusLabel
    if label and label.setText then
        pcall(label.setText, "Status: " .. line)
    end
end

local function getReplica()
    local ok, dataClient = pcall(require, ReplicatedStorage.Packages.Data.Client)
    if not ok or type(dataClient) ~= "table" then
        return nil
    end
    local data = rawget(dataClient, "data")
    if type(data) ~= "table" then
        return nil
    end
    local raw = rawget(data, "___X")
    if type(raw) == "table" then
        return raw
    end
    return nil
end

local function getHiddenAtom()
    if type(Farm.hiddenAtom) == "function" then
        return Farm.hiddenAtom
    end
    local now = tick()
    if now - Farm.hiddenAt < 2 then
        return nil
    end
    Farm.hiddenAt = now
    local gui = plr:FindFirstChild("PlayerGui")
    local root = gui and gui:FindFirstChild("Root")
    local rolling = root and root:FindFirstChild("Rolling")
    local options = rolling and rolling:FindFirstChild("Options")
    local button = options and options:FindFirstChild("HiddenRoll")
    if button and type(getconnections) == "function" then
        local ok, cons = pcall(getconnections, button.Activated)
        if ok and type(cons) == "table" then
            for _, connection in cons do
                local fn = connection.Function
                if type(fn) == "function" then
                    local src = ""
                    pcall(function()
                        src = tostring(debug.getinfo(fn).short_src or "")
                    end)
                    if string.find(src, "RollController") then
                        local okAtom, atom = pcall(debug.getupvalue, fn, 1)
                        if okAtom and type(atom) == "function" then
                            Farm.hiddenAtom = atom
                            return atom
                        end
                    end
                end
            end
        end
    end
    if type(getgc) ~= "function" then
        return nil
    end
    for _, obj in getgc(false) do
        if type(obj) == "function" then
            local okInfo, info = pcall(debug.getinfo, obj)
            if okInfo and info and info.short_src == "ReplicatedStorage.Framework.Features.Rolling.RollController"
            and info.nups == 1 then
                local okCons, constants = pcall(debug.getconstants, obj)
                local empty = true
                if okCons and type(constants) == "table" then
                    for _, value in constants do
                        if value ~= nil then
                            empty = false
                            break
                        end
                    end
                end
                if empty then
                    local okAtom, atom = pcall(debug.getupvalue, obj, 1)
                    if okAtom and type(atom) == "function" then
                        Farm.hiddenAtom = atom
                        return atom
                    end
                end
            end
        end
    end
    return nil
end

local origPlayCutscene = RollController and RollController.PlayCutscene
if type(getgenv().AnimeDiceOrigPlayCutscene) == "function" then
    origPlayCutscene = getgenv().AnimeDiceOrigPlayCutscene
elseif type(origPlayCutscene) == "function" then
    getgenv().AnimeDiceOrigPlayCutscene = origPlayCutscene
end

if RollController and type(origPlayCutscene) == "function" then
    pcall(function()
        RollController.PlayCutscene = function(...)
            if runtime ~= getgenv().AnimeDiceRuntime then
                return origPlayCutscene(...)
            end
            if Settings["Skip Animation"] == true then
                return
            end
            return origPlayCutscene(...)
        end
    end)
end

do
    local origShower = SpinController and SpinController.PlayShower
    if type(getgenv().AnimeDiceOrigPlayShower) == "function" then
        origShower = getgenv().AnimeDiceOrigPlayShower
    elseif type(origShower) == "function" then
        getgenv().AnimeDiceOrigPlayShower = origShower
    end
    if SpinController and type(origShower) == "function" then
        SpinController.PlayShower = function(...)
            if runtime ~= getgenv().AnimeDiceRuntime then
                return origShower(...)
            end
            if Settings["Skip Animation"] == true then
                return
            end
            return origShower(...)
        end
    end
end

local function findRollFn()
    if type(Farm.rollFn) == "function" then
        return Farm.rollFn
    end
    if type(getgc) ~= "function" then
        return nil
    end
    for _, obj in getgc(false) do
        if type(obj) == "function" then
            local okInfo, info = pcall(debug.getinfo, obj)
            if okInfo and info
            and info.name == "roll"
            and info.short_src == "ReplicatedStorage.Framework.Features.Rolling.RollController" then
                Farm.rollFn = obj
                return obj
            end
        end
    end
    return nil
end

local function findNamedFn(src, name)
    local cacheKey = src .. ":" .. name
    local cached = Farm.skipFns[cacheKey]
    if type(cached) == "function" then
        return cached
    end
    if cached == false and tick() - (Farm.pending[cacheKey] or 0) < 10 then
        return nil
    end
    if type(getgc) ~= "function" then
        return nil
    end
    for _, obj in getgc(false) do
        if type(obj) == "function" then
            local okInfo, info = pcall(debug.getinfo, obj)
            if okInfo and info and info.name == name and info.short_src == src then
                Farm.skipFns[cacheKey] = obj
                return obj
            end
        end
    end
    Farm.skipFns[cacheKey] = false
    Farm.pending[cacheKey] = tick()
    return nil
end

local function setRollWait(skipOn)
    local roll = findRollFn()
    if type(roll) == "function" and type(debug.setconstant) == "function" then
        if skipOn then
            pcall(debug.setconstant, roll, 11, 0)
            pcall(debug.setconstant, roll, 16, 0)
            pcall(debug.setconstant, roll, 19, 0)
            Farm.skipWaitOn = true
        else
            pcall(debug.setconstant, roll, 11, 4)
            pcall(debug.setconstant, roll, 16, 0.15)
            pcall(debug.setconstant, roll, 19, 0.3333333333333333)
            Farm.skipWaitOn = false
        end
    end
    if Farm.playSeqFn == nil then
        Farm.playSeqFn = findNamedFn("ReplicatedStorage.Framework.Features.Towers.TowerController", "playSequence") or false
    end
    local playSeq = Farm.playSeqFn
    if type(playSeq) == "function" and type(debug.setconstant) == "function" then
        if skipOn then
            pcall(debug.setconstant, playSeq, 14, 0)
            pcall(debug.setconstant, playSeq, 25, 0)
        else
            pcall(debug.setconstant, playSeq, 14, 0.08)
            pcall(debug.setconstant, playSeq, 25, 0.5)
        end
    end
end

local function hideRollingGui(hidden)
    local gui = plr:FindFirstChild("PlayerGui")
    local root = gui and gui:FindFirstChild("Root")
    local rolling = root and root:FindFirstChild("Rolling")
    if rolling then
        local frame = rolling:FindFirstChild("Frame")
        if frame and frame:IsA("GuiObject") and hidden then
            frame.Visible = false
        end
    end
end

local function applyBlackScreen()
    local hide = Settings["Hide Black Screen"] == true
    local gui = plr:FindFirstChild("PlayerGui")
    if not gui then
        return
    end
    local function setVis(inst)
        if inst and inst:IsA("GuiObject") then
            inst.Visible = not hide
            if hide and inst.BackgroundTransparency then
                inst.BackgroundTransparency = 1
            end
        end
    end
    setVis(gui:FindFirstChild("CutsceneBlackFade"))
    local fadeFrame = gui:FindFirstChild("CutsceneBlackFade")
    if fadeFrame then
        for _, child in fadeFrame:GetChildren() do
            setVis(child)
        end
    end
    local root = gui:FindFirstChild("Root")
    local rolling = root and root:FindFirstChild("Rolling")
    if rolling then
        setVis(rolling:FindFirstChild("DarkBackground"))
    end
    if type(Farm.refreshBlack) == "function" then
        Farm.refreshBlack()
    end
end

local function towerFolder()
    local gui = plr:FindFirstChild("PlayerGui")
    local root = gui and gui:FindFirstChild("Root")
    return root and root:FindFirstChild("Tower")
end

local function applyTowerHidden()
    local hideFn = findNamedFn(
        "ReplicatedStorage.Framework.Features.Towers.TowerController",
        "setTowerHidden"
    )
    if type(hideFn) ~= "function" then
        return
    end
    local hide = Settings["Display Tower"] ~= true
    local tower = towerFolder()
    local screen = tower and tower:FindFirstChild("Screen")
    local hidden = tower and tower:FindFirstChild("Hidden")
    local screenShown = screen and screen:IsA("GuiObject") and screen.Visible
    local chipShown = hidden and hidden:IsA("GuiObject") and hidden.Visible
    if hide and chipShown and not screenShown then
        return
    end
    if not hide and screenShown then
        return
    end
    pcall(hideFn, hide)
end

getgenv().AnimeDiceRestore = function()
    getgenv().AnimeDiceSkipRollDur = false
    if RollController and type(origPlayCutscene) == "function" then
        pcall(function()
            RollController.PlayCutscene = origPlayCutscene
        end)
    end
    if SpinController and type(getgenv().AnimeDiceOrigPlayShower) == "function" then
        pcall(function()
            SpinController.PlayShower = getgenv().AnimeDiceOrigPlayShower
        end)
    end
    if type(restorefunction) == "function" then
        local target = Farm.getBuffTarget
        if type(target) ~= "function" and BuffController then
            target = BuffController.GetBuff
        end
        if type(target) == "function" then
            pcall(restorefunction, target)
        end
    end
    if BuffController and type(getgenv().AnimeDiceOrigGetBuff) == "function" then
        pcall(function()
            BuffController.GetBuff = getgenv().AnimeDiceOrigGetBuff
        end)
    end
    setRollWait(false)
    hideRollingGui(false)
end

local function setHiddenRolls(wanted)
    local atom = getHiddenAtom()
    if type(atom) ~= "function" then
        return false
    end
    local okGet, current = pcall(atom)
    if okGet and current == wanted then
        return true
    end
    local okSet = pcall(atom, wanted)
    return okSet == true
end

local function skipGetBuff(name, ...)
    if name == "Roll Duration" and getgenv().AnimeDiceSkipRollDur == true then
        return 0
    end
    local orig = getgenv().AnimeDiceOrigGetBuff
    if type(orig) == "function" then
        return orig(name, ...)
    end
    return 0
end

local function applyRollDurationSkip(skipOn)
    getgenv().AnimeDiceSkipRollDur = skipOn == true
    local getBuff = BuffController and BuffController.GetBuff
    if type(getBuff) ~= "function" then
        return
    end
    if type(getgenv().AnimeDiceOrigGetBuff) ~= "function" then
        if type(clonefunction) == "function" then
            local okClone, cloned = pcall(clonefunction, getBuff)
            if okClone and type(cloned) == "function" then
                getgenv().AnimeDiceOrigGetBuff = cloned
            end
        end
        if type(getgenv().AnimeDiceOrigGetBuff) ~= "function" then
            getgenv().AnimeDiceOrigGetBuff = getBuff
        end
    end
    if skipOn then
        BuffController.GetBuff = skipGetBuff
    else
        BuffController.GetBuff = orig
    end
end

local function applySkipAnimation()
    local wanted = Settings["Skip Animation"] == true
    setHiddenRolls(wanted)
    applyBlackScreen()
    applyRollDurationSkip(wanted)
    if wanted then
        hideRollingGui(true)
        if Farm.skipWaitOn ~= true then
            task.spawn(function()
                pcall(setRollWait, true)
            end)
        end
    else
        setRollWait(false)
    end
end

local function syncAutoRoll()
    local data = getReplica()
    if type(data) ~= "table" then
        return false, "no data"
    end
    local wanted = Settings["Auto Roll"] == true
    if data.AutoRoll == wanted then
        return true, wanted and "on" or "off"
    end
    if not ready("autoRoll", 1.25) then
        return false, "pending"
    end
    fireRemote(Net.SetAutoRoll, wanted)
    return false, "sent"
end

local function doRoll(data)
    if Settings["Auto Roll"] ~= true or type(data) ~= "table" then
        return false
    end
    local money = tonumber(data.Money) or 0
    if money <= 0 then
        return false
    end
    invokeRemote(Net.RollDice)
    return true
end

local function questScore(tbl)
    local progress = rawget(tbl, "progress")
    if type(progress) ~= "table" then
        return -1
    end
    local total = 0
    for _, value in progress do
        total = total + (tonumber(value) or 0)
    end
    return total
end

local function freshQuestTable(expiresAt)
    -- ponytail: the quest node keeps a frozen copy. Scan once a second for the table that is still counting.
    if type(filtergc) ~= "function" or type(expiresAt) ~= "number" then
        return nil
    end
    local now = tick()
    local cache = Farm.questScan
    if type(cache) ~= "table" or now - (cache.at or 0) > 1 then
        cache = { at = now, byExp = {} }
        local ok, list = pcall(filtergc, "table", {
            Keys = { "expiresAt", "progress", "claimed" },
        })
        if ok and type(list) == "table" then
            for _, tbl in list do
                local exp = rawget(tbl, "expiresAt")
                if type(exp) == "number" and questScore(tbl) >= 0 then
                    local prev = cache.byExp[exp]
                    if not prev or questScore(tbl) > questScore(prev) then
                        cache.byExp[exp] = tbl
                    end
                end
            end
        end
        Farm.questScan = cache
    end
    return cache.byExp[expiresAt]
end

local function questLive(periodName, data)
    local seeded = nil
    if type(DataController) == "table" and type(DataController.Quests) == "table" then
        local node = DataController.Quests[periodName]
        if type(node) == "table" then
            local ok, called = pcall(function()
                return node()
            end)
            if ok and type(called) == "table" and type(rawget(called, "progress")) == "table" then
                seeded = called
            end
            if not seeded then
                local raw = rawget(node, "___X")
                if type(raw) == "table" and type(raw[periodName]) == "table" then
                    seeded = raw[periodName]
                end
            end
        end
    end
    if not seeded and type(data) == "table" and type(data.Quests) == "table" then
        local live = data.Quests[periodName]
        if type(live) == "table" then
            seeded = live
        end
    end
    if type(seeded) == "table" then
        local fresh = freshQuestTable(tonumber(seeded.expiresAt))
        if type(fresh) == "table" then
            return fresh
        end
    end
    return seeded
end

local function claimReadyQuests()
    if Settings["Auto Claim Quests"] ~= true then
        return 0
    end
    local data = getReplica()
    if type(QuestConfig) ~= "table" then
        return 0
    end
    local periods = QuestConfig.Periods
    if type(periods) ~= "table" then
        return 0
    end
    local claimed = 0
    local serverNow = Workspace:GetServerTimeNow()
    for periodName, period in periods do
        local live = questLive(periodName, data)
        if type(live) == "table" and type(period) == "table" and type(period.quests) == "table" then
            local expiresAt = tonumber(live.expiresAt)
            if expiresAt and serverNow < expiresAt then
                local progress = live.progress
                local already = live.claimed
                for _, quest in period.quests do
                    local id = quest and quest.id
                    local target = tonumber(quest and quest.target) or 0
                    if type(id) == "string" then
                        local have = 0
                        if type(progress) == "table" then
                            have = tonumber(progress[id]) or 0
                        end
                        local isClaimed = type(already) == "table" and already[id] == true
                        if have >= target and not isClaimed then
                            local key = periodName .. ":" .. id
                            if ready(key, 2) then
                                fireRemote(Net.ClaimQuest, periodName, id, expiresAt)
                                claimed = claimed + 1
                                farmLog(key, "Claim " .. periodName .. " " .. id)
                            end
                        end
                    end
                end
            end
        end
    end
    return claimed
end

local function slotBalance(data)
    local total = 0
    if type(data) ~= "table" or type(data.Slots) ~= "table" then
        return 0
    end
    for _, slot in data.Slots do
        if type(slot) == "table" then
            total = total + (tonumber(slot.balance) or 0)
        end
    end
    return total
end

local function claimCash(data)
    if Settings["Auto Claim Cash"] ~= true or type(data) ~= "table" then
        return false
    end
    if type(data.Slots) ~= "table" then
        return false
    end
    if slotBalance(data) < 1 then
        return false
    end
    if not ready("cash", 1) then
        return false
    end
    local did = false
    for key, slot in data.Slots do
        if type(slot) == "table" and (tonumber(slot.balance) or 0) >= 1 then
            local id = tonumber(key) or key
            fireRemote(Net.CollectBalance, id)
            if type(key) == "string" then
                fireRemote(Net.CollectBalance, key)
            end
            did = true
        end
    end
    if did then
        farmLog("cash", "Claim cash")
    end
    return did
end

local function equipBest()
    if Settings["Auto Equip Best"] ~= true then
        return false
    end
    if not ready("equipBest", 2.5) then
        return false
    end
    fireRemote(Net.EquipBest)
    fireRemote(Net.EquipBestTower)
    return true
end

local function parentOwned(owned, name)
    if name == nil or name == "Start" then
        return true
    end
    local ok, parent = pcall(UpgradeTree.GetParent, name)
    if not ok or parent == nil or parent == "Start" then
        return true
    end
    return owned[parent] == true
end

local function buyUpgrades(data)
    if Settings["Auto Upgrade"] ~= true or type(data) ~= "table" then
        return false
    end
    if type(UpgradeCatalog) ~= "table" then
        return false
    end
    if not ready("upgrade", 1.25) then
        return false
    end
    local money = tonumber(data.Money) or 0
    local owned = data.Upgrades
    if type(owned) ~= "table" then
        owned = {}
    end
    local bestName, bestPrice = nil, nil
    for name, cfg in UpgradeCatalog do
        if type(name) == "string" and name ~= "Start" and type(cfg) == "table" and owned[name] ~= true then
            local price = tonumber(cfg.price) or 0
            if price >= 0 and money >= price and parentOwned(owned, name) then
                if bestPrice == nil or price < bestPrice then
                    bestName = name
                    bestPrice = price
                end
            end
        end
    end
    if not bestName then
        return false
    end
    fireRemote(Net.BuyUpgrade, bestName)
    farmLog("upgrade", "Upgrade " .. bestName)
    return true
end

local function doRebirth(data)
    if Settings["Auto Rebirth"] ~= true or type(data) ~= "table" then
        return false
    end
    local current = tonumber(data.Rebirth) or 0
    local ok, nextInfo = pcall(Rebirths.GetNext, current)
    if not ok or type(nextInfo) ~= "table" then
        return false
    end
    local cost = tonumber(nextInfo.cost) or 0
    local money = tonumber(data.Money) or 0
    if cost <= 0 or money < cost then
        return false
    end
    if not ready("rebirth", 5) then
        return false
    end
    fireRemote(Net.Rebirth)
    farmLog("rebirth", "Rebirth " .. tostring(current + 1))
    return true
end

local function keptUnitIds(data)
    local keep = {}
    if type(data.Slots) == "table" then
        for _, slot in data.Slots do
            if type(slot) == "table" and type(slot.unitId) == "string" then
                keep[slot.unitId] = true
            end
        end
    end
    if type(data.TowerTeam) == "table" then
        for _, uid in data.TowerTeam do
            if type(uid) == "string" then
                keep[uid] = true
            end
        end
    end
    return keep
end

local function sellSpareUnits(data)
    if Settings["Auto Sell Units"] ~= true or type(data) ~= "table" then
        return false
    end
    if type(data.Inventory) ~= "table" then
        return false
    end
    if not ready("sell", 6) then
        return false
    end
    local keep = keptUnitIds(data)
    local toSell = {}
    for uid, entry in data.Inventory do
        if type(uid) == "string" and keep[uid] ~= true then
            local locked = false
            if type(entry) == "table" then
                locked = entry.locked == true
                if type(entry.attributes) == "table" and entry.attributes.locked == true then
                    locked = true
                end
            end
            if not locked then
                toSell[#toSell + 1] = uid
            end
        end
    end
    if #toSell == 0 then
        return false
    end
    invokeRemote(Net.SellInventory, toSell)
    farmLog("sell", "Sell spare units x" .. tostring(#toSell))
    return true
end

local function ownedDiceMap(data)
    local owned = {}
    local defaultDice = nil
    if type(DiceCatalog) == "table" and type(DiceCatalog.GetDefault) == "function" then
        defaultDice = DiceCatalog.GetDefault()
    end
    if type(defaultDice) == "string" then
        owned[defaultDice] = true
    end
    owned["Basic"] = true
    if type(data.Dice) == "string" then
        owned[data.Dice] = true
    end
    if type(data.OwnedDice) == "table" then
        for name, value in data.OwnedDice do
            if value == true then
                owned[tostring(name)] = true
            end
        end
    end
    return owned
end

local function diceList()
    local list = {}
    if type(DiceCatalog) ~= "table" or type(DiceCatalog.GetAll) ~= "function" then
        return list
    end
    local all = DiceCatalog.GetAll()
    if type(all) ~= "table" then
        return list
    end
    for name, cfg in all do
        if type(cfg) == "table" then
            list[#list + 1] = {
                name = name,
                price = tonumber(cfg.price) or 0,
                luck = tonumber(cfg.luck) or 0,
            }
        end
    end
    table.sort(list, function(a, b)
        if a.luck == b.luck then
            return a.price < b.price
        end
        return a.luck < b.luck
    end)
    return list
end

local function diceShop(data)
    if Settings["Auto Dice Shop"] ~= true or type(data) ~= "table" then
        return false
    end
    if not ready("dice", 2) then
        return false
    end
    local money = tonumber(data.Money) or 0
    local owned = ownedDiceMap(data)
    local list = diceList()
    local bestOwned = nil
    local nextBuy = nil
    for _, dice in list do
        if owned[dice.name] then
            bestOwned = dice
        elseif nextBuy == nil and dice.price > 0 and money >= dice.price then
            nextBuy = dice
        end
    end
    if nextBuy then
        fireRemote(Net.BuyDice, nextBuy.name)
        farmLog("dice", "Buy dice " .. nextBuy.name)
        return true
    end
    if bestOwned and data.Dice ~= bestOwned.name then
        fireRemote(Net.EquipDice, bestOwned.name)
        farmLog("dice", "Equip dice " .. bestOwned.name)
        return true
    end
    return false
end

local function towerNames()
    local names = {}
    if type(TowerCatalog) ~= "table" or type(TowerCatalog.GetAll) ~= "function" then
        return { "Dragon Tower" }
    end
    local all = TowerCatalog.GetAll()
    if type(all) ~= "table" then
        return { "Dragon Tower" }
    end
    local rows = {}
    for name, cfg in all do
        local order = 999
        if type(cfg) == "table" then
            order = tonumber(cfg.order) or 999
        end
        if order < 90 then
            rows[#rows + 1] = { name = name, order = order }
        end
    end
    table.sort(rows, function(a, b)
        return a.order < b.order
    end)
    for _, row in rows do
        names[#names + 1] = row.name
    end
    if #names == 0 then
        names[1] = "Dragon Tower"
    end
    return names
end

local function lowestTower()
    local names = towerNames()
    return names[1]
end

local function questsFinished(data)
    if type(QuestConfig) ~= "table" or type(QuestConfig.Periods) ~= "table" then
        return false
    end
    local periods = QuestConfig.Periods
    local serverNow = Workspace:GetServerTimeNow()
    local names = { "Daily", "Weekly" }
    for _, periodName in names do
        local period = periods[periodName]
        local live = questLive(periodName, data)
        if type(period) ~= "table" or type(period.quests) ~= "table" or type(live) ~= "table" then
            return false
        end
        local expiresAt = tonumber(live.expiresAt)
        if not expiresAt or expiresAt <= serverNow then
            return false
        end
        local progress = live.progress
        local already = live.claimed
        for _, quest in period.quests do
            local id = quest and quest.id
            local target = tonumber(quest and quest.target) or 0
            if id == "Towers" then
                local have = 0
                if type(progress) == "table" then
                    have = tonumber(progress[id]) or 0
                end
                local isClaimed = type(already) == "table" and already[id] == true
                if have < target and not isClaimed then
                    return false, periodName .. " " .. id .. " " .. tostring(math.floor(have)) .. "/" .. tostring(math.floor(target))
                end
            end
        end
    end
    return true, ""
end

local function wantedTower(data)
    if Settings["Auto Infinity"] == true then
        local done, note = questsFinished(data)
        Farm.questNote = note or ""
        if done then
            return "Infinity Tower"
        end
    else
        Farm.questNote = ""
    end
    return lowestTower()
end

local function runningTowerName()
    if type(debug) == "table" and type(debug.getupvalue) == "function"
    and type(TowerController) == "table" and type(TowerController.startTower) == "function" then
        local i = 1
        while i <= 12 do
            local ok, value = pcall(debug.getupvalue, TowerController.startTower, i)
            if not ok then
                break
            end
            if type(value) == "string" and value ~= "" then
                return value
            end
            i = i + 1
        end
    end
    if type(Farm.towerRunName) == "string" then
        return Farm.towerRunName
    end
    return ""
end

local function inTower()
    if type(debug) == "table" and type(debug.getupvalue) == "function"
    and type(TowerController) == "table" and type(TowerController.startTower) == "function" then
        local ok, running = pcall(debug.getupvalue, TowerController.startTower, 1)
        if ok and type(running) == "boolean" then
            return running
        end
    end
    local tower = towerFolder()
    if not tower then
        return false
    end
    local hidden = tower:FindFirstChild("Hidden")
    if hidden and hidden:IsA("GuiObject") and hidden.Visible then
        return true
    end
    if not Farm.towerArmed and not Farm.towerWasIn then
        return false
    end
    local screen = tower:FindFirstChild("Screen")
    if not (screen and screen:IsA("GuiObject") and screen.Visible) then
        return false
    end
    local floor = screen:FindFirstChild("Floor")
    if floor and floor:IsA("TextLabel") and string.find(floor.Text or "", "Floor") then
        return true
    end
    return false
end

local function parseFloorNumber(text)
    if type(text) ~= "string" then
        return 0
    end
    local n = string.match(text, "(%d+)")
    return tonumber(n) or 0
end

local function readTowerFloor()
    local tower = towerFolder()
    if not tower then
        return 0
    end
    local hidden = tower:FindFirstChild("Hidden")
    local hiddenLabel = hidden and hidden:FindFirstChild("Label")
    if hidden and hidden:IsA("GuiObject") and hidden.Visible
    and hiddenLabel and hiddenLabel:IsA("TextLabel") then
        local hiddenFloor = parseFloorNumber(hiddenLabel.Text)
        if hiddenFloor > 0 then
            return hiddenFloor
        end
    end
    local screen = tower:FindFirstChild("Screen")
    local label = screen and screen:FindFirstChild("Floor")
    if label and label:IsA("TextLabel") then
        return parseFloorNumber(label.Text)
    end
    return 0
end

local function updateFloorLabel()
    local label = Farm.floorLabel
    if not (label and label.setText) then
        return
    end
    local towerName = Farm.floorTower
    if type(towerName) ~= "string" or towerName == "" then
        towerName = Settings["Tower"] or "Tower"
    end
    local text = string.format(
        "Current Floor: %d  |  This run: %d  |  Session: %d  |  Best: %d  |  %s",
        Farm.floor or 0,
        Farm.floorRun or 0,
        Farm.floorSession or 0,
        Farm.floorBest or 0,
        towerName
    )
    pcall(label.setText, text)
    local display = Farm.towerDisplay
    if display and display.setText then
        local inFight = "Idle"
        if (Farm.floor or 0) > 0 then
            inFight = "Fighting"
        end
        local line = string.format(
            "Tower: %s  |  Current Floor %d  |  %s  |  Run %d  |  Session %d  |  Best %d",
            towerName,
            Farm.floor or 0,
            inFight,
            Farm.floorRun or 0,
            Farm.floorSession or 0,
            Farm.floorBest or 0
        )
        pcall(display.setText, line)
    end
end

local function noteFloorComplete(floor)
    floor = tonumber(floor) or 0
    if floor <= 0 then
        return
    end
    local towerName = Settings["Tower"]
    if type(towerName) == "string" then
        Farm.floorTower = towerName
    end
    if Farm.floorSeen <= 0 then
        Farm.floorSeen = floor
        Farm.floor = floor
        if floor > Farm.floorBest then
            Farm.floorBest = floor
        end
        updateFloorLabel()
        return
    end
    if floor > Farm.floorSeen then
        local gained = floor - Farm.floorSeen
        Farm.floorRun = (Farm.floorRun or 0) + gained
        Farm.floorSession = (Farm.floorSession or 0) + gained
        farmLog("floor:" .. tostring(floor), "Floor complete x" .. tostring(gained) .. " now " .. tostring(floor))
    elseif floor < Farm.floorSeen then
        Farm.floorRun = 0
    end
    Farm.floorSeen = floor
    Farm.floor = floor
    if floor > Farm.floorBest then
        Farm.floorBest = floor
    end
    updateFloorLabel()
end

local function trackTowerFloor()
    if inTower() then
        local floor = readTowerFloor()
        if floor > 0 then
            noteFloorComplete(floor)
        end
    end
end

local function settleTowerRun()
    if inTower() then
        if Farm.towerArmed then
            Farm.towerWasIn = true
        end
        return
    end
    if Farm.towerArmed and Farm.towerWasIn then
        Farm.towerArmed = false
        Farm.towerWasIn = false
    end
end

local function startNextTower(data)
    settleTowerRun()
    if Settings["Auto Next Tower"] ~= true then
        Farm.questHold = false
        return false
    end
    local name = wantedTower(data)
    Farm.questHold = Settings["Auto Infinity"] == true and name ~= "Infinity Tower"
    if inTower() then
        local running = runningTowerName()
        if running ~= "" and running ~= name then
            if ready("towerLeave", 3.2) then
                invokeRemote(Net.CancelTower)
                Farm.towerArmed = false
                Farm.towerWasIn = false
                Farm.towerStuckCancel = false
                farmLog("tower", "Leave " .. running .. " for " .. name)
            end
            return false
        end
        Farm.towerActive = true
        return false
    end
    if Farm.towerArmed and not Farm.towerWasIn then
        if tick() - (Farm.towerArmAt or 0) < 8 then
            return false
        end
        if Farm.towerStuckCancel ~= true then
            invokeRemote(Net.CancelTower)
            Farm.towerStuckCancel = true
            Farm.towerArmAt = tick()
            farmLog("tower", "Clear stuck tower")
            return false
        end
        Farm.towerArmed = false
        Farm.towerStuckCancel = false
    end
    if not ready("towerNext", 3.2) then
        return false
    end
    Settings["Tower"] = name
    fireRemote(Net.EquipBestTower)
    local started = false
    if type(TowerController) == "table" and type(TowerController.startTower) == "function" then
        local ok, result = pcall(TowerController.startTower, name)
        started = ok and result == true
    end
    if not started then
        local tries = Farm.towerStuckTries or 0
        if tries == 0 then
            invokeRemote(Net.CancelTower)
            farmLog("tower", "Clear stuck tower")
        elseif tries == 1 then
            invokeRemote(Net.CompleteTowerFloor)
        end
        Farm.towerStuckTries = (tries + 1) % 3
        return false
    end
    Farm.towerStuckTries = 0
    Farm.floorSeen = 0
    Farm.floorRun = 0
    Farm.towerRunName = name
    Farm.towerArmed = true
    Farm.towerArmAt = tick()
    Farm.towerWasIn = false
    Farm.towerRunMax = 0
    Farm.towerRunLow = nil
    farmLog("tower", "Next " .. name)
    return true
end

local function itemAmount(data, name)
    if type(data) ~= "table" or type(data.Inventory) ~= "table" then
        return 0
    end
    local item = data.Inventory[name]
    if type(item) ~= "table" then
        return 0
    end
    return tonumber(item.amount) or 0
end

local BlackRows = {
    { name = "Rolls", image = "rbxassetid://134047270790894", color = Color3.fromRGB(255, 214, 80) },
    { name = "Gems", image = "rbxassetid://99406696477560", color = Color3.fromRGB(80, 230, 255) },
    { name = "Trait Reroll", image = "rbxassetid://133531024200552", color = Color3.fromRGB(186, 120, 255) },
    { name = "Tickets", image = "rbxassetid://84743623119270", color = Color3.fromRGB(255, 176, 60) },
    { name = "Jackpot Spin", image = "rbxassetid://76821109669261", color = Color3.fromRGB(255, 86, 168) },
}

local function blackAmounts(data)
    local rolls = 0
    if type(data) == "table" then
        rolls = tonumber(data.Rolls) or 0
    end
    return {
        Rolls = rolls,
        Gems = itemAmount(data, "Gems"),
        ["Trait Reroll"] = itemAmount(data, "Trait Reroll"),
        Tickets = itemAmount(data, "Tickets"),
        ["Jackpot Spin"] = itemAmount(data, "Jackpot Spin"),
    }
end

local function ensureBlackGui()
    local gui = Farm.blackGui
    if gui and gui.Parent then
        return gui
    end
    local playerGui = plr:FindFirstChild("PlayerGui")
    if not playerGui then
        return nil
    end
    local old = playerGui:FindFirstChild("AnimeDiceBlack")
    if old then
        old:Destroy()
    end
    gui = Instance.new("ScreenGui")
    gui.Name = "AnimeDiceBlack"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 500
    gui.Parent = playerGui
    local frame = Instance.new("Frame")
    frame.Name = "Cover"
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.ZIndex = 1
    frame.Parent = gui
    local stats = Instance.new("Frame")
    stats.Name = "Stats"
    stats.BackgroundTransparency = 1
    stats.AnchorPoint = Vector2.new(0.5, 0.5)
    stats.Position = UDim2.new(0.5, 0, 0.5, 0)
    stats.Size = UDim2.fromOffset(760, 340)
    stats.Parent = frame
    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Padding = UDim.new(0, 8)
    list.Parent = stats
    local rowLabels = {}
    for _, row in BlackRows do
        local line = Instance.new("Frame")
        line.Name = row.name
        line.BackgroundTransparency = 1
        line.AutomaticSize = Enum.AutomaticSize.X
        line.Size = UDim2.fromOffset(0, 56)
        line.Parent = stats
        local rowList = Instance.new("UIListLayout")
        rowList.FillDirection = Enum.FillDirection.Horizontal
        rowList.VerticalAlignment = Enum.VerticalAlignment.Center
        rowList.Padding = UDim.new(0, 12)
        rowList.SortOrder = Enum.SortOrder.LayoutOrder
        rowList.Parent = line
        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.LayoutOrder = 1
        icon.Size = UDim2.fromOffset(52, 52)
        icon.Image = row.image
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Parent = line
        local text = Instance.new("TextLabel")
        text.Name = "Amount"
        text.BackgroundTransparency = 1
        text.LayoutOrder = 2
        text.AutomaticSize = Enum.AutomaticSize.X
        text.Size = UDim2.fromOffset(0, 56)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 48
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextColor3 = row.color
        text.Text = row.name .. ": 0"
        text.Parent = line
        rowLabels[row.name] = text
    end
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.BackgroundTransparency = 1
    status.AnchorPoint = Vector2.new(0.5, 1)
    status.Position = UDim2.new(0.5, 0, 1, -20)
    status.Size = UDim2.new(0.92, 0, 0, 36)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 22
    status.TextColor3 = Color3.fromRGB(230, 230, 230)
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.Text = ""
    status.ZIndex = 2
    status.Parent = frame
    Farm.blackGui = gui
    Farm.blackStatus = status
    Farm.blackCover = frame
    Farm.blackRows = rowLabels
    return gui
end

local function updateBlackScreen(data)
    if not ensureBlackGui() then
        return
    end
    Farm.blackCover.Visible = Settings["Black Screen"] ~= false
    local amounts = blackAmounts(data or getReplica())
    for _, row in BlackRows do
        local shown = row.name .. ": " .. tostring(amounts[row.name] or 0)
        local rowLabel = Farm.blackRows[row.name]
        if rowLabel and rowLabel.Text ~= shown then
            rowLabel.Text = shown
        end
    end
    local statusText = Farm.status or "Starting"
    if Farm.blackStatus and Farm.blackStatus.Text ~= statusText then
        Farm.blackStatus.Text = statusText
    end
end

Farm.refreshBlack = updateBlackScreen

local function shopCost(itemName)
    if type(QuestConfig) ~= "table" then
        return nil
    end
    local shop = QuestConfig.Shop
    if type(shop) ~= "table" then
        return nil
    end
    for _, item in shop do
        if type(item) == "table" and item.name == itemName and item.gamepass ~= true then
            return tonumber(item.tickets) or 0
        end
    end
    return nil
end

local function buyJackpot(data)
    if Settings["Auto Jackpot Spin"] ~= true or type(data) ~= "table" then
        return false
    end
    local cost = shopCost("Jackpot Spin")
    if not cost or cost <= 0 then
        return false
    end
    local tickets = itemAmount(data, "Tickets")
    if tickets < cost then
        return false
    end
    if not ready("jackpot", 1.5) then
        return false
    end
    fireRemote(Net.BuyQuest, "Jackpot Spin")
    farmLog("jackpot", "Buy Jackpot Spin")
    return true
end

local function useSpinItem(data, itemName, key)
    if type(data) ~= "table" or itemAmount(data, itemName) < 1 then
        return false
    end
    if not ready(key, 1.5) then
        return false
    end
    fireRemote(Net.UseSpin, itemName)
    farmLog(key, "Use " .. itemName)
    return true
end

local function useLuckySpin(data)
    if Settings["Auto Use Lucky Spin"] ~= true then
        return false
    end
    return useSpinItem(data, "Lucky Spin", "luckySpin")
end

local function useBoosts(data)
    if Settings["Auto Use Boost"] ~= true or type(data) ~= "table" then
        return false
    end
    if type(data.Inventory) ~= "table" then
        return false
    end
    if not ready("boost", 1.25) then
        return false
    end
    local now = tick()
    local used = false
    for key, entry in data.Inventory do
        if type(entry) == "table" and (tonumber(entry.amount) or 0) >= 1 then
            local name = entry.name or key
            local ok, cfg = pcall(EntryRegistry.getEntryConfig, name)
            if ok and type(cfg) == "table" and cfg.kind == "Boost" then
                local untilAt = Farm.boostUntil[name] or 0
                if now >= untilAt then
                    fireRemote(Net.UseBoost, name)
                    local duration = tonumber(cfg.duration) or 120
                    Farm.boostUntil[name] = now + math.max(duration - 2, 8)
                    farmLog("boost:" .. tostring(name), "Use boost " .. tostring(name))
                    used = true
                    break
                end
            end
        end
    end
    return used
end

local function redeemCodes(data)
    if Settings["Auto Redeem Codes"] ~= true then
        return false
    end
    if type(MonetizationConfig) ~= "table" then
        return false
    end
    local codes = MonetizationConfig.Codes
    if type(codes) ~= "table" then
        return false
    end
    local redeemed = {}
    if type(data) == "table" and type(data.RedeemedCodes) == "table" then
        redeemed = data.RedeemedCodes
    end
    if not ready("codes", 1.2) then
        return false
    end
    local did = false
    for code in codes do
        if type(code) == "string" and redeemed[code] ~= true then
            local key = "code:" .. code
            if ready(key, 8) then
                fireRemote(Net.RedeemCode, code)
                farmLog(key, "Redeem " .. code)
                did = true
                break
            end
        end
    end
    return did
end

local function promptMessage()
    local core = game:FindFirstChild("CoreGui")
    if not core then
        return nil
    end
    local texts = {}
    local function grab(root)
        if not root then
            return
        end
        for _, inst in root:GetDescendants() do
            if inst:IsA("TextLabel") or inst:IsA("TextButton") then
                local text = inst.Text
                if type(text) == "string" and text ~= "" then
                    texts[#texts + 1] = text
                end
            end
        end
    end
    local promptGui = core:FindFirstChild("RobloxPromptGui")
    local overlay = promptGui and promptGui:FindFirstChild("promptOverlay")
    local err = overlay and overlay:FindFirstChild("ErrorPrompt")
    if err and err.Visible then
        grab(err)
    end
    local rbxErr = core:FindFirstChild("RobloxGui")
    rbxErr = rbxErr and rbxErr:FindFirstChild("ErrorPrompt")
    if rbxErr and rbxErr.Visible then
        grab(rbxErr)
    end
    if #texts == 0 then
        local ok, msg = pcall(function()
            return GuiService:GetErrorMessage()
        end)
        if ok and type(msg) == "string" and msg ~= "" then
            return msg
        end
        return nil
    end
    return table.concat(texts, " ")
end

local function isDisconnectText(text)
    if type(text) ~= "string" or text == "" then
        return false
    end
    local lower = string.lower(text)
    local needles = {
        "disconnected",
        "disconnect",
        "lost connection",
        "connection was lost",
        "reconnect",
        "idled",
        "idle for",
        "kicked",
        "you have been kicked",
        "teleport failed",
        "error code",
        "please check your internet",
        "leave the experience",
    }
    for _, needle in needles do
        if string.find(lower, needle, 1, true) then
            return true
        end
    end
    return false
end

local autoExecPath = "Nousigi Hub/AnimeDice.lua"
local autoExecMarker = 'random00 = "how to hide a dead body"'
local autoExecLoader = [[
task.spawn(function()
    repeat task.wait() until game:IsLoaded() and game:FindFirstChild("CoreGui")
    getgenv().BridgeURL = "127.0.0.1:16384"
    getgenv().bridgeurl = "127.0.0.1:16384"
    getgenv().DisableInitialScriptDecompMapping = true
    if getgenv().MCP_Loaded ~= true and type(isfile) == "function" and isfile("MCP.lua") then
        local okMcp, mcpSrc = pcall(readfile, "MCP.lua")
        if okMcp and type(mcpSrc) == "string" and #mcpSrc > 100 then
            local mcpFn = loadstring(mcpSrc)
            if mcpFn then
                task.spawn(mcpFn)
            end
        end
    end
    local path = "Nousigi Hub/AnimeDice.lua"
    local tries = 0
    while tries < 40 do
        tries = tries + 1
        if type(isfile) == "function" and isfile(path) then
            local okRead, src = pcall(readfile, path)
            if okRead and type(src) == "string" and #src > 100 then
                local fn = loadstring(src)
                if fn then
                    fn()
                    return
                end
            end
        end
        task.wait(0.25)
    end
end)
]]

local function findScriptSource()
    local paths = {
        autoExecPath,
        "Anime Dice.lua",
        "!Anime Dice.lua",
        "Script/Anime Dice.lua",
        "D:/Downloads/OpXOyuApWKTlFzrV/Script Roblox/Script/Anime Dice.lua",
        "D:\\Downloads\\OpXOyuApWKTlFzrV\\Script Roblox\\Script\\Anime Dice.lua",
    }
    if type(getgenv().AnimeDiceSourcePath) == "string" then
        table.insert(paths, 1, getgenv().AnimeDiceSourcePath)
    end
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return nil
    end
    for _, path in paths do
        local okExists, exists = pcall(isfile, path)
        if okExists and exists then
            local okRead, src = pcall(readfile, path)
            if okRead and type(src) == "string" and string.find(src, autoExecMarker, 1, true) then
                return src
            end
        end
    end
    return nil
end

local function persistScript()
    local src = findScriptSource()
    if type(src) ~= "string" or src == "" then
        return false
    end
    if type(makefolder) == "function" and type(isfolder) == "function" then
        if not isfolder("Nousigi Hub") then
            pcall(makefolder, "Nousigi Hub")
        end
    end
    if type(writefile) ~= "function" then
        return false
    end
    local okWrite = pcall(writefile, autoExecPath, src)
    if okWrite then
        Farm.autoExecSaved = true
    end
    return okWrite == true
end

local function queueAutoExec()
    if Settings["Auto Execute On Rejoin"] ~= true then
        return false
    end
    persistScript()
    local queue = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if type(queue) ~= "function" then
        return false
    end
    local okQueue = pcall(queue, autoExecLoader)
    if okQueue then
        Farm.autoExecQueued = true
    end
    return okQueue == true
end

local function doRejoin(reason)
    if Farm.rejoining then
        return false
    end
    Farm.rejoining = true
    setStatus("Rejoining")
    farmLog("rejoin", tostring(reason or "rejoin"))
    if type(getgenv().AnimeDiceSaveSettings) == "function" then
        pcall(getgenv().AnimeDiceSaveSettings, true)
    end
    queueAutoExec()
    local placeId = game.PlaceId
    -- Full teleport replaces the Roblox process so MCP gets a new client.
    -- Same-job TeleportToPlaceInstance keeps the old clientId.
    task.spawn(function()
        pcall(function()
            TeleportService:Teleport(placeId, plr)
        end)
    end)
    return true
end

Farm.rejoin = doRejoin
Farm.promptMessage = promptMessage
Farm.queueAutoExec = queueAutoExec
pcall(queueAutoExec)

getgenv().AnimeDiceFarm = Farm

task.spawn(function()
    while runtime == getgenv().AnimeDiceRuntime do
        local okRoll, rollErr = xpcall(function()
            if Settings["Auto Roll"] ~= true then
                task.wait(0.2)
                return
            end
            local data = getReplica()
            if type(data) ~= "table" or (tonumber(data.Money) or 0) <= 0 then
                task.wait(0.2)
                return
            end
            local before = tonumber(data.Rolls) or 0
            doRoll(data)
            local timeout = 2.4
            if Settings["Skip Animation"] ~= true then
                timeout = 5
            end
            local deadline = tick() + timeout
            while runtime == getgenv().AnimeDiceRuntime and tick() < deadline do
                data = getReplica()
                local nowRolls = 0
                if type(data) == "table" then
                    nowRolls = tonumber(data.Rolls) or 0
                end
                if nowRolls > before then
                    return
                end
                task.wait(0.2)
            end
        end, debug.traceback)
        if not okRoll then
            farmLog("roll", tostring(rollErr))
            task.wait(0.4)
        end
    end
end)

task.spawn(function()
    local gui = plr:FindFirstChild("PlayerGui") or plr:WaitForChild("PlayerGui", 10)
    if gui then
        gui.ChildAdded:Connect(function(child)
            if runtime ~= getgenv().AnimeDiceRuntime then
                return
            end
            if Settings["Hide Black Screen"] == true then
                local n = child.Name
                if n == "CutsceneBlackFade" or n == "Cutscene" or n == "RollCutscene" or n == "DarkBackground" then
                    task.defer(function()
                        applyBlackScreen()
                    end)
                end
            end
        end)
    end
    while runtime == getgenv().AnimeDiceRuntime do
        if Settings["Hide Black Screen"] == true then
            applyBlackScreen()
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while runtime == getgenv().AnimeDiceRuntime do
        local okLoop, loopErr = xpcall(function()
        pcall(applySkipAnimation)
        local data = getReplica()
        updateBlackScreen(data)
        local autoOk, autoState = syncAutoRoll()
        local claimed = claimReadyQuests()
        local didCash = claimCash(data)
        local didEquip = equipBest()
        local didSell = sellSpareUnits(data)
        local didUpgrade = buyUpgrades(data)
        local didDice = diceShop(data)
        applyTowerHidden()
        trackTowerFloor()
        local didNextTower = startNextTower(data)
        local didCode = redeemCodes(data)
        local didSpin = useLuckySpin(data)
        local didJackpot = buyJackpot(data)
        local didBoost = useBoosts(data)
        local didRebirth = doRebirth(data)

        if type(data) ~= "table" then
            setStatus("Waiting for player data")
        elseif didRebirth then
            setStatus("Rebirthing")
        elseif didNextTower then
            setStatus("Starting next tower")
        elseif didCash then
            setStatus("Claiming cash")
        elseif didUpgrade then
            setStatus("Buying upgrade")
        elseif didDice then
            setStatus("Dice shop")
        elseif didSpin then
            setStatus("Using Lucky Spin")
        elseif didJackpot then
            setStatus("Buying Jackpot Spin")
        elseif didBoost then
            setStatus("Using boost")
        elseif didCode then
            setStatus("Redeeming codes")
        elseif didSell then
            setStatus("Selling spare units")
        elseif Settings["Auto Roll"] == true then
            local money = tonumber(data.Money) or 0
            if money <= 0 then
                setStatus("Auto roll on - need cash")
            elseif data.AutoRoll == true then
                setStatus("Auto rolling")
            elseif autoState == "pending" or autoState == "sent" then
                setStatus("Turning auto roll on")
            else
                setStatus("Auto roll waiting")
            end
        elseif claimed > 0 then
            setStatus("Claiming quests")
        elseif didEquip then
            setStatus("Equip best")
        else
            setStatus("Idle")
        end
        end, debug.traceback)
        if not okLoop then
            Farm.status = "Error"
            farmLog("loop", tostring(loopErr))
        end

        task.wait(0.35)
    end
end)

task.spawn(function()
    Farm.rejoinWatch = true
    while runtime == getgenv().AnimeDiceRuntime do
        if Settings["Auto Rejoin"] == true and not Farm.rejoining then
            local text = promptMessage()
            if isDisconnectText(text) then
                doRejoin(text)
            end
        end
        task.wait(0.8)
    end
end)

pcall(function()
    GuiService.ErrorMessageChanged:Connect(function()
        if runtime ~= getgenv().AnimeDiceRuntime then
            return
        end
        if Settings["Auto Rejoin"] ~= true or Farm.rejoining then
            return
        end
        local text = promptMessage()
        if isDisconnectText(text) then
            doRejoin(text)
        end
    end)
end)

if getgenv().AnimeDiceAntiAfk then
    pcall(function()
        getgenv().AnimeDiceAntiAfk:Disconnect()
    end)
end
getgenv().AnimeDiceAntiAfk = plr.Idled:Connect(function()
    if runtime ~= getgenv().AnimeDiceRuntime then
        return
    end
    if Settings["Anti-AFK"] ~= true then
        return
    end
    local VirtualUser = game:GetService("VirtualUser")
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

local Library = mainLib.Init({
    gameName = "Anime Dice",
    keyToggleUI = Enum.KeyCode.RightControl,
    density = "auto",
})

local rbxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
local rabbit = nil
if rbxGui then
    for _, child in rbxGui:GetDescendants() do
        if child.Name == "btn-hide" and child:IsA("GuiButton") then
            rabbit = child
            break
        end
    end
end
if rabbit then
    local old = plr.PlayerGui:FindFirstChild("AnimeDiceRabbit")
    if old then
        old:Destroy()
    end
    local holder = Instance.new("ScreenGui")
    holder.Name = "AnimeDiceRabbit"
    holder.ResetOnSpawn = false
    holder.DisplayOrder = 600
    holder.Parent = plr.PlayerGui
    local logo = rabbit:Clone()
    local note = logo:FindFirstChild("toggle-note")
    if note then
        note:Destroy()
    end
    logo.Parent = holder
    logo.MouseButton1Click:Connect(function()
        if runtime ~= getgenv().AnimeDiceRuntime then
            return
        end
        Settings["Black Screen"] = Settings["Black Screen"] == false
        if type(Farm.refreshBlack) == "function" then
            Farm.refreshBlack()
        end
    end)
end
if rbxGui then
    local hub = rbxGui:FindFirstChild("Nousigi Hub GUI")
    if hub then
        hub:Destroy()
    end
    local etc = rbxGui:FindFirstChild("Nousigi Hub GUI [ETC]")
    if etc then
        etc:Destroy()
    end
end
pcall(applyTowerHidden)
