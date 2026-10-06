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
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local oldRemake = getgenv().AnimeDiceRemake
if type(oldRemake) == "table" then
    if type(oldRemake.cleanupTowerUi) == "function" then
        pcall(oldRemake.cleanupTowerUi)
    elseif type(oldRemake.restoreTowerVisuals) == "function" then
        pcall(oldRemake.restoreTowerVisuals)
    end
    local oldController = oldRemake.Modules and oldRemake.Modules.RollController
    if type(oldController) == "table" and type(oldRemake.originalCutscene) == "function" then
        oldController.PlayCutscene = oldRemake.originalCutscene
    end
end

getgenv().AnimeDiceRuntime = (tonumber(getgenv().AnimeDiceRuntime) or 0) + 1
if type(getgenv().AnimeDiceRestore) == "function" then
    pcall(getgenv().AnimeDiceRestore)
end

getgenv().AnimeDiceRemakeGeneration =
    (tonumber(getgenv().AnimeDiceRemakeGeneration) or 0) + 1
local generation = getgenv().AnimeDiceRemakeGeneration

local App = {
    pending = {},
    boostUntil = {},
    unitLabels = {},
    tradeLabels = {},
    towerRuns = 0,
    towerFloors = 0,
    towerBest = 0,
    towerLastRun = "-",
    towerRunFloor = 0,
    towerWasActive = false,
    trade = {
        partner = nil,
        state = nil,
        request = nil,
        sent = 0,
        received = 0,
    },
}

do
    local defaults = {
        ["Auto Roll"] = false,
        ["Skip Roll Animation"] = true,
        ["Auto Sell Below"] = false,
        ["Sell Below"] = 1000,
        ["Auto Use Potions"] = false,
        ["Potions"] = {},
        ["Use Potions On Weather"] = false,
        ["Anti AFK"] = true,
        ["Auto Rebirth"] = false,
        ["Auto Allocate Rebirth Stats"] = false,
        ["Rebirth Stat Mode"] = "Priority First",
        ["Rebirth Stat Selection"] = {},
        ["Rebirth Stat Priority"] = "Luck, Money, Damage, Health, Trait Luck, Grade Luck",
        ["Rebirth Stat Max Level"] = 0,
        ["Auto Equip Best"] = false,
        ["Auto Equip Best Gear"] = false,
        ["Auto Collect"] = false,
        ["Auto Upgrade Units"] = false,
        ["Upgrade Until Level"] = 50,
        ["Auto Dice Shop"] = false,
        ["Auto Equip Best Dice"] = false,
        ["Auto Claim Daily"] = false,
        ["Auto Claim Quests"] = false,
        ["Auto Redeem Codes"] = false,
        ["Auto Claim Offline"] = false,
        ["Auto Claim Group"] = false,
        ["Auto Buy Quest Shop Items"] = false,
        ["Quest Shop Items"] = {},
        ["Auto Upgrade Skill Tree"] = false,
        ["Skill Tree Groups"] = {},
        ["Auto Fuse"] = false,
        ["Fuse From"] = 0,
        ["Fuse Below"] = 0,
        ["Fuse Order"] = "Rarest First",
        ["Auto Trait Reroll"] = false,
        ["Trait"] = nil,
        ["Trait Unit"] = nil,
        ["Auto Grade Reroll"] = false,
        ["Grade"] = nil,
        ["Grade Unit"] = nil,
        ["Tower Mode"] = "Single",
        ["Tower"] = "Dragon Tower",
        ["Rotate Towers"] = {},
        ["Auto Equip Best Team"] = true,
        ["Auto Tower"] = false,
        ["Black Screen"] = false,
        ["FPS Boost"] = false,
        ["Delete Map"] = false,
        ["Trade Player"] = nil,
        ["Trade Entries"] = {},
        ["Trade Amount"] = 1,
        ["Send Max Quantity"] = false,
        ["Auto Send Trade"] = false,
        ["Auto Accept Trades"] = false,
        ["Accept Players"] = {},
        ["Use Trade Whitelist"] = false,
    }

    local function copy(value)
        if type(value) ~= "table" then
            return value
        end
        local result = {}
        for key, child in value do
            result[key] = copy(child)
        end
        return result
    end

    local function merge(target, source)
        if type(source) ~= "table" then
            return
        end
        for key, value in source do
            if type(value) == "table" and type(target[key]) == "table" then
                merge(target[key], value)
            else
                target[key] = copy(value)
            end
        end
    end

    local function safeName(value)
        return string.gsub(tostring(value or "Player"), "[\\/:*?\"<>|]", "_")
    end

    local path = "Nousigi Hub/AnimeDiceRemake_" .. safeName(plr.Name) .. ".json"
    local settings = copy(defaults)
    if type(getgenv().Config) == "table" then
        merge(settings, getgenv().Config)
    elseif type(isfile) == "function" and isfile(path) then
        local okRead, raw = pcall(readfile, path)
        local okDecode, saved = pcall(HttpService.JSONDecode, HttpService, okRead and raw or "")
        if okDecode and type(saved) == "table" then
            merge(settings, saved)
        elseif okRead and type(writefile) == "function" then
            pcall(writefile, path .. ".corrupt-" .. tostring(os.time()) .. ".txt", raw)
        end
    end
    getgenv().Settings = settings
    App.Settings = settings

    if type(isfolder) == "function" and type(makefolder) == "function"
    and not isfolder("Nousigi Hub") then
        pcall(makefolder, "Nousigi Hub")
    end

    local lastJson = nil
    local function save(force)
        local okEncode, json = pcall(HttpService.JSONEncode, HttpService, settings)
        if not okEncode or type(json) ~= "string" or not force and json == lastJson then
            return
        end
        if type(writefile) == "function" and pcall(writefile, path, json) then
            lastJson = json
        end
    end

    save(true)
    task.spawn(function()
        while generation == getgenv().AnimeDiceRemakeGeneration do
            task.wait(2)
            save(false)
        end
    end)
    App.save = save
end

do
    local Network = ReplicatedStorage:WaitForChild("Network")
    local Framework = ReplicatedStorage:WaitForChild("Framework")
    local function requireSafe(inst)
        local ok, result = pcall(require, inst)
        if ok then
            return result
        end
        return nil
    end

    App.Net = {
        SetAutoRoll = Network.RollService.RE.SetAutoRoll,
        UpdateAutoSell = Network.SellService.RE.UpdateAutoSell,
        SellInventory = Network.SellService.RF.SellInventory,
        UseBoost = Network.BoostService.RE.Use,
        Rebirth = Network.RebirthService.RE.Rebirth,
        AddRebirthStat = Network.RebirthService.RE.AddStat,
        BuyQuestItem = Network.QuestService.RE.Buy,
        EquipGear = Network.GearService.RE.Equip,
        CollectBalance = Network.PlotService.RE.CollectBalance,
        LevelUpSlot = Network.PlotService.RE.LevelUpSlot,
        EquipBest = Network.PlotService.RE.EquipBest,
        EquipBestTower = Network.Towers.RE.EquipBestTowerTeam,
        PlayTower = Network.Towers.RF.PlayTower,
        CompleteTowerFloor = Network.Towers.RF.CompleteTowerFloor,
        BuyUpgrade = Network.RE.BuyUpgrade,
        BuyDice = Network.DiceShopService.RE.BuyDice,
        EquipDice = Network.DiceShopService.RE.EquipDice,
        ClaimDaily = Network.DailyRewardService.RE.Claim,
        ClaimQuest = Network.QuestService.RE.Claim,
        RedeemCode = Network.CodesService.RE.RedeemCode,
        ClaimOffline = Network.OfflineEarningsService.RE.Claim,
        ClaimGroup = Network.GroupRewardService.RE.Claim,
        Fuse = Network.FusingService.RE.Fuse,
        TraitRoll = Network.TraitService.RE.Roll,
        GradeRoll = Network.GradeService.RE.Roll,
        RequestTrade = Network.TradeService.RE.RequestTrade,
        RespondTrade = Network.TradeService.RE.RespondToRequest,
        ChangeOffer = Network.TradeService.RE.ChangeOffer,
        AdvanceTrade = Network.TradeService.RE.AdvanceTrade,
        CancelTrade = Network.TradeService.RE.CancelTrade,
        SetTradeRequestsEnabled = Network.TradeService.RE.SetTradeRequestsEnabled,
        TradeEvent = Network.TradeService.RE.TradeEvent,
    }
    App.Modules = {
        DataController = requireSafe(Framework.Features.Data.DataController),
        EntryRegistry = requireSafe(Framework.Features.Inventory.EntryRegistry),
        RollController = requireSafe(Framework.Features.Rolling.RollController),
        RollCutscene = requireSafe(Framework.Features.Rolling.RollCutscene),
        Dice = requireSafe(Framework.Features.Rolling.Dice),
        Rebirths = requireSafe(Framework.Features.Rebirth.Rebirths),
        RebirthStatsConfig = requireSafe(Framework.Features.Rebirth.RebirthStatsConfig),
        QuestConfig = requireSafe(Framework.Features.Quests.QuestConfig),
        CodesConfig = requireSafe(Framework.Features.Codes.CodesConfig),
        GearConfig = requireSafe(Framework.Features.Inventory.Kinds.Gear.GearConfig),
        Upgrades = requireSafe(Framework.Features.Upgrades.Upgrades),
        UpgradeTree = requireSafe(Framework.Features.Upgrades.TreeStructure),
        Towers = requireSafe(Framework.Features.Towers.Towers),
        TowerRefs = requireSafe(Framework.Features.Towers.TowerRefs),
        FusingUtil = requireSafe(Framework.Features.Fusing.FusingUtil),
        Traits = requireSafe(Framework.Features.Traits.Traits),
        Grades = requireSafe(Framework.Features.Grades.Grades),
        TradeConfig = requireSafe(Framework.Features.Trading.TradeConfig),
    }
end

function App.data()
    local ok, client = pcall(require, ReplicatedStorage.Packages.Data.Client)
    if not ok or type(client) ~= "table" then
        return nil
    end
    local root = rawget(client, "data")
    return type(root) == "table" and rawget(root, "___X") or nil
end

function App.ready(key, delay)
    local now = tick()
    if now - (App.pending[key] or 0) < delay then
        return false
    end
    App.pending[key] = now
    return true
end

function App.fire(remote, ...)
    local args = { ... }
    return pcall(function()
        remote:FireServer(unpack(args))
    end)
end

function App.invoke(remote, ...)
    local args = { ... }
    return pcall(function()
        return remote:InvokeServer(unpack(args))
    end)
end

function App.setStatus(text)
    App.status = tostring(text)
    if App.statusLabel and App.statusLabel.setText then
        pcall(App.statusLabel.setText, "Status: " .. App.status)
    end
end

function App.parseSellBelow(value)
    local amount = tonumber(value)
    if not amount then
        local number, suffix = string.match(
            string.lower(string.gsub(tostring(value), "%s+", "")),
            "^([%d]*%.?[%d]+)(%a+)$"
        )
        local powers = { k = 3, m = 6, b = 9, t = 12, q = 15, sx = 21 }
        local power = powers[suffix]
        if not power then
            return nil
        end
        amount = tonumber(number) * 10 ^ power
    end
    if not amount or amount ~= amount then
        return nil
    end
    return math.min(1e26, math.max(0, amount))
end

function App.entryOdds(entry)
    if type(entry) ~= "table" or type(App.Modules.EntryRegistry) ~= "table" then
        return nil
    end
    local ok, config = pcall(App.Modules.EntryRegistry.getEntryConfig, entry.name)
    if not ok or type(config) ~= "table" or config.kind ~= "Unit"
    or type(config.chance) ~= "function" then
        return nil
    end
    local okChance, chance = pcall(config.chance, entry.attributes or {})
    return okChance and tonumber(chance) or nil
end

function App.protectedUnits(data)
    local protected = {}
    if type(data) ~= "table" then
        return protected
    end
    for _, slot in data.Slots or {} do
        if type(slot) == "table" and type(slot.unitId) == "string" then
            protected[slot.unitId] = true
        end
    end
    for _, key in data.TowerTeam or {} do
        protected[key] = true
    end
    return protected
end

function App.syncAutoRoll(data)
    local wanted = App.Settings["Auto Roll"] == true
    if type(data) == "table" and data.AutoRoll ~= wanted and App.ready("roll", 1.5) then
        App.fire(App.Net.SetAutoRoll, wanted)
        App.setStatus(wanted and "Enabling auto roll" or "Disabling auto roll")
    end
end

function App.syncRollAnimation()
    local controller = App.Modules.RollController
    if type(controller) ~= "table" or type(controller.PlayCutscene) ~= "function" then
        return
    end
    if not App.originalCutscene then
        App.originalCutscene = controller.PlayCutscene
    end
    if App.Settings["Skip Roll Animation"] == true then
        if controller.PlayCutscene ~= App.skipCutscene then
            App.skipCutscene = function(_, _, model)
                if typeof(model) == "Instance" then
                    model:Destroy()
                end
            end
            controller.PlayCutscene = App.skipCutscene
        end
        local rollCutscene = App.Modules.RollCutscene
        if type(rollCutscene) == "function" and not App.rollCutsceneHooked
        and type(hookfunction) == "function" then
            local ok, original = pcall(hookfunction, rollCutscene, App.skipCutscene)
            if ok then
                App.rollCutsceneTarget = rollCutscene
                App.originalRollCutscene = type(original) == "function" and original or rollCutscene
                App.rollCutsceneHooked = true
            end
        end
    else
        App.restoreRollAnimation()
    end
end

function App.restoreRollAnimation()
    local controller = App.Modules.RollController
    if type(controller) == "table" and App.originalCutscene
    and controller.PlayCutscene == App.skipCutscene then
        controller.PlayCutscene = App.originalCutscene
    end
    if App.rollCutsceneHooked and type(hookfunction) == "function" then
        pcall(hookfunction, App.rollCutsceneTarget, App.originalRollCutscene)
        App.rollCutsceneHooked = false
    end
end

getgenv().AnimeDiceRestore = App.restoreRollAnimation

function App.syncAutoSell(data)
    local wanted = App.Settings["Auto Sell Below"] == true
        and math.max(0, tonumber(App.Settings["Sell Below"]) or 0) or 0
    if type(data) == "table" and tonumber(data.AutoSell) ~= wanted
    and App.ready("autoSell", 1.5) then
        App.fire(App.Net.UpdateAutoSell, wanted)
        App.setStatus("Updating auto sell")
    end
end

function App.sellBelowNow(data)
    if type(data) ~= "table" or type(data.Inventory) ~= "table"
    or not App.ready("sellNow", 4) then
        return false
    end
    local limit = math.max(0, tonumber(App.Settings["Sell Below"]) or 0)
    local protected = App.protectedUnits(data)
    local keys = {}
    for key, entry in data.Inventory do
        local odds = App.entryOdds(entry)
        local locked = type(entry) == "table" and type(entry.attributes) == "table"
            and entry.attributes.locked == true
        if odds and odds < limit and not protected[key] and not locked then
            keys[#keys + 1] = key
        end
    end
    if #keys == 0 then
        return false
    end
    App.invoke(App.Net.SellInventory, keys)
    App.setStatus("Selling " .. tostring(#keys) .. " units")
    return true
end

function App.usePotions(data)
    if App.Settings["Auto Use Potions"] ~= true or type(data) ~= "table"
    or type(data.Inventory) ~= "table" or not App.ready("potions", 1) then
        return false
    end
    local selected = App.Settings["Potions"]
    for key, entry in data.Inventory do
        if type(entry) == "table" and (tonumber(entry.amount) or 0) > 0 then
            local name = entry.name or key
            if type(selected) == "table" and selected[name] == true
            and tick() >= (App.boostUntil[name] or 0) then
                local duration = 60
                local registry = App.Modules.EntryRegistry
                if type(registry) == "table" then
                    local ok, config = pcall(registry.getEntryConfig, name)
                    if ok and type(config) == "table" then
                        duration = tonumber(config.duration) or duration
                    end
                end
                App.fire(App.Net.UseBoost, name)
                App.boostUntil[name] = tick() + math.max(10, duration - 2)
                App.setStatus("Using " .. tostring(name))
                return true
            end
        end
    end
    return false
end

function App.inventoryAmount(data, itemName)
    local amount = 0
    if type(data) == "table" and type(data.Inventory) == "table" then
        for _, entry in data.Inventory do
            if type(entry) == "table" and entry.name == itemName then
                amount += tonumber(entry.amount) or 1
            end
        end
    end
    return amount
end

function App.buyQuestShopItems(data)
    local selected = App.Settings["Quest Shop Items"]
    local questConfig = App.Modules.QuestConfig
    if App.Settings["Auto Buy Quest Shop Items"] ~= true
    or type(data) ~= "table" or type(data.Inventory) ~= "table"
    or type(selected) ~= "table" or type(questConfig) ~= "table"
    or type(questConfig.Shop) ~= "table" then
        return false
    end

    local ticketEntry = data.Inventory.Tickets
    local tickets = type(ticketEntry) == "table" and tonumber(ticketEntry.amount) or 0
    local pending = App.questShopPending
    if pending then
        local bought = pending.gamepass and type(data.OwnedGamepasses) == "table"
            and data.OwnedGamepasses[pending.name] == true
            or not pending.gamepass and (tickets < pending.ticketsBefore
                or App.inventoryAmount(data, pending.name) >= pending.itemAmountBefore + pending.itemAmount)
        if bought then
            App.questShopPending = nil
        elseif tick() - pending.at < 5 then
            return false
        else
            App.questShopPending = nil
        end
    end
    if not App.ready("questShop", 1.5) then
        return false
    end

    for _, item in questConfig.Shop do
        if type(item) == "table" and type(item.name) == "string"
        and selected[item.name] == true and tickets >= (tonumber(item.tickets) or math.huge) then
            local owned = item.gamepass == true and type(data.OwnedGamepasses) == "table"
                and data.OwnedGamepasses[item.name] == true
            if not owned then
                local itemAmount = tonumber(item.amount) or 1
                if App.fire(App.Net.BuyQuestItem, item.name) then
                    App.questShopPending = {
                        name = item.name,
                        gamepass = item.gamepass == true,
                        ticketsBefore = tickets,
                        itemAmountBefore = App.inventoryAmount(data, item.name),
                        itemAmount = itemAmount,
                        at = tick(),
                    }
                    App.setStatus("Buying " .. item.name .. " with Tickets")
                    return true
                end
            end
        end
    end
    return false
end

function App.chooseRebirthStat(data)
    local config = App.Modules.RebirthStatsConfig
    local selection = App.Settings["Rebirth Stat Selection"]
    if type(data) ~= "table" or type(config) ~= "table"
    or type(config.Stats) ~= "table" or type(selection) ~= "table" then
        return nil, 0
    end

    local stats = {}
    local allowed = {}
    for _, stat in config.Stats do
        if type(stat) == "table" and type(stat.name) == "string"
        and selection[stat.name] == true then
            stats[#stats + 1] = stat.name
            allowed[stat.name] = true
        end
    end
    if #stats == 0 then
        return nil, 0
    end

    local order = {}
    local seen = {}
    local priority = tostring(App.Settings["Rebirth Stat Priority"] or "")
    for name in string.gmatch(priority .. ",", "(.-),") do
        name = string.match(name, "^%s*(.-)%s*$")
        if allowed[name] and not seen[name] then
            order[#order + 1] = name
            seen[name] = true
        end
    end
    for _, name in stats do
        if not seen[name] then
            order[#order + 1] = name
            seen[name] = true
        end
    end

    local rebirthStats = type(data.RebirthStats) == "table" and data.RebirthStats or {}
    local remaining = config.GetRemaining(tonumber(data.Rebirth) or 0, rebirthStats)
    if remaining < 1 then
        return nil, remaining
    end

    local maxLevel = math.max(0, tonumber(App.Settings["Rebirth Stat Max Level"]) or 0)
    local target = nil
    local lowest = math.huge
    for _, name in order do
        local level = tonumber(rebirthStats[name]) or 0
        if maxLevel == 0 or level < maxLevel then
            if not target or App.Settings["Rebirth Stat Mode"] == "Evenly" and level < lowest then
                target = name
                lowest = level
            end
        end
    end
    if not target then
        return nil, remaining
    end
    return target, remaining
end

function App.allocateRebirthStats(data)
    if App.Settings["Auto Allocate Rebirth Stats"] ~= true then
        return false
    end
    local target, remaining = App.chooseRebirthStat(data)
    if not target then
        App.rebirthStatPending = nil
        return false
    end
    local rebirthStats = type(data.RebirthStats) == "table" and data.RebirthStats or {}
    local pending = App.rebirthStatPending
    if pending then
        if (tonumber(rebirthStats[pending.name]) or 0) > pending.level
        or remaining < pending.remaining then
            App.rebirthStatPending = nil
        elseif tick() - pending.at < 1 then
            return false
        else
            App.rebirthStatPending = nil
        end
    end
    if not App.ready("rebirthStat", 0.5) then
        return false
    end

    local level = tonumber(rebirthStats[target]) or 0
    if App.fire(App.Net.AddRebirthStat, target) then
        App.rebirthStatPending = {
            name = target,
            level = level,
            remaining = remaining,
            at = tick(),
        }
        App.setStatus("Allocating rebirth point to " .. target)
        return true
    end
    return false
end

function App.gearScore(name)
    if type(name) ~= "string" or type(App.Modules.EntryRegistry) ~= "table" then
        return nil
    end
    local ok, config = pcall(App.Modules.EntryRegistry.getEntryConfig, name)
    if not ok or type(config) ~= "table" or config.kind ~= "Gear" then
        return nil
    end
    local score = 0
    for _, buff in config.buffs or {} do
        local amount = type(buff) == "table" and tonumber(buff.amount) or nil
        if amount then
            score += buff.bucket == "multiplier" and math.max(0, amount - 1) or amount
        end
    end
    return score, config.slot
end

function App.equipBestGear(data)
    local gearConfig = App.Modules.GearConfig
    if App.Settings["Auto Equip Best Gear"] ~= true
    or type(data) ~= "table" or type(data.Inventory) ~= "table"
    or type(gearConfig) ~= "table" or type(gearConfig.slots) ~= "table" then
        return false
    end

    local equipped = type(data.EquippedGear) == "table" and data.EquippedGear or {}
    local pending = App.gearEquipPending
    if pending then
        if equipped[pending.slot] == pending.name then
            App.gearEquipPending = nil
        elseif tick() - pending.at < 1 then
            return false
        else
            App.gearEquipPending = nil
        end
    end

    local best = {}
    for _, entry in data.Inventory do
        if type(entry) == "table" and (tonumber(entry.amount) or 0) > 0 then
            local score, slot = App.gearScore(entry.name)
            local current = score and type(slot) == "string" and best[slot] or nil
            if score and type(slot) == "string" and (not current or score > current.score
            or score == current.score and entry.name < current.name) then
                best[slot] = { name = entry.name, score = score }
            end
        end
    end

    for _, slot in gearConfig.slots do
        local candidate = best[slot]
        local currentName = equipped[slot]
        local currentScore = App.gearScore(currentName)
        if candidate and candidate.name ~= currentName
        and candidate.score > (currentScore or -math.huge)
        and App.ready("gearEquip", 0.75) then
            if App.fire(App.Net.EquipGear, slot, candidate.name) then
                App.gearEquipPending = { slot = slot, name = candidate.name, at = tick() }
                App.setStatus("Equipping " .. candidate.name)
                return true
            end
        end
    end
    return false
end

function App.progress(data)
    if type(data) ~= "table" then
        return false
    end
    if App.Settings["Auto Collect"] == true and App.ready("collect", 1.5) then
        for key, slot in data.Slots or {} do
            if type(slot) == "table" and (tonumber(slot.balance) or 0) > 0 then
                App.fire(App.Net.CollectBalance, tonumber(key) or key)
            end
        end
    end
    if App.Settings["Auto Equip Best"] == true and App.ready("equip", 4) then
        App.fire(App.Net.EquipBest)
    end
    if App.Settings["Auto Upgrade Units"] == true and App.ready("unitUpgrade", 0.8) then
        local limit = tonumber(App.Settings["Upgrade Until Level"]) or 50
        for key, slot in data.Slots or {} do
            local entry = type(slot) == "table" and type(data.Inventory) == "table"
                and data.Inventory[slot.unitId] or nil
            local level = entry and entry.attributes and tonumber(entry.attributes.level) or 1
            if entry and level < limit then
                App.fire(App.Net.LevelUpSlot, tonumber(key) or key)
                break
            end
        end
    end
    if App.Settings["Auto Rebirth"] == true and App.ready("rebirth", 3) then
        local rebirths = App.Modules.Rebirths
        if type(rebirths) == "table" and type(rebirths.GetNext) == "function" then
            local ok, nextRebirth = pcall(rebirths.GetNext, tonumber(data.Rebirth) or 0)
            if ok and type(nextRebirth) == "table"
            and (tonumber(data.Money) or 0) >= (tonumber(nextRebirth.cost) or math.huge) then
                App.fire(App.Net.Rebirth)
                App.setStatus("Rebirthing")
                return true
            end
        end
    end
    return false
end

function App.buyDice(data)
    if App.Settings["Auto Dice Shop"] ~= true or type(data) ~= "table"
    or not App.ready("dice", 2) then
        return false
    end
    local catalog = App.Modules.Dice
    if type(catalog) ~= "table" then
        return false
    end
    local owned = {}
    for _, name in data.OwnedDice or {} do
        owned[name] = true
    end
    local bestName, bestPrice = nil, nil
    for name, config in catalog do
        if type(name) == "string" and type(config) == "table" and not owned[name] then
            local price = tonumber(config.price or config.cost)
            if price and price <= (tonumber(data.Money) or 0)
            and (not bestPrice or price < bestPrice) then
                bestName, bestPrice = name, price
            end
        end
    end
    if not bestName then
        return false
    end
    App.fire(App.Net.BuyDice, bestName)
    if App.Settings["Auto Equip Best Dice"] == true then
        task.delay(0.5, function()
            if generation == getgenv().AnimeDiceRemakeGeneration then
                App.fire(App.Net.EquipDice, bestName)
            end
        end)
    end
    App.setStatus("Buying dice " .. bestName)
    return true
end

function App.claimRewards(data)
    if type(data) ~= "table" then
        return
    end
    if App.Settings["Auto Claim Offline"] == true
    and (tonumber(data.PendingOfflineEarnings) or 0) > 0 and App.ready("offline", 3) then
        App.fire(App.Net.ClaimOffline)
    end
    if App.Settings["Auto Claim Group"] == true
    and data.ClaimedGroupReward ~= true and App.ready("group", 5) then
        App.fire(App.Net.ClaimGroup)
    end
    local dailyState = tostring(data.DailyRewardsClaimed) .. ":" .. tostring(data.LastDailyRewardClaim)
    if App.Settings["Auto Claim Daily"] == true and App.dailyClaimState ~= dailyState
    and App.ready("daily", 5) then
        App.dailyClaimState = dailyState
        App.fire(App.Net.ClaimDaily)
    end
end

function App.claimQuests(data)
    local config = App.Modules.QuestConfig
    if App.Settings["Auto Claim Quests"] ~= true or type(data) ~= "table"
    or type(data.Quests) ~= "table" or type(config) ~= "table"
    or type(config.Periods) ~= "table" then
        return false
    end

    local pending = App.questClaimPending
    if pending then
        local state = data.Quests[pending.period]
        if type(state) ~= "table" then
            return false
        end
        if tonumber(state.expiresAt) == pending.expiresAt
        and type(state.claimed) == "table" and state.claimed[pending.id] ~= true
        and tick() - pending.at < 3 then
            return false
        end
        if tonumber(state.expiresAt) == pending.expiresAt
        and type(state.claimed) == "table" and state.claimed[pending.id] == true then
            App.questClaimPending = nil
            return false
        end
        App.questClaimPending = nil
    end

    if not App.ready("questClaim", 1) then
        return false
    end
    for _, period in { "Daily", "Weekly" } do
        local state = data.Quests[period]
        local periodConfig = config.Periods[period]
        local expiresAt = type(state) == "table" and tonumber(state.expiresAt) or nil
        if expiresAt and expiresAt > 0 and type(state.progress) == "table"
        and type(state.claimed) == "table" and type(periodConfig) == "table" then
            for _, quest in periodConfig.quests or {} do
                local progress = type(quest) == "table" and tonumber(state.progress[quest.id]) or nil
                local target = type(quest) == "table" and tonumber(quest.target) or nil
                if type(quest) == "table" and type(quest.id) == "string"
                and progress and target and progress >= target
                and state.claimed[quest.id] ~= true then
                    if App.fire(App.Net.ClaimQuest, period, quest.id, expiresAt) then
                        App.questClaimPending = {
                            period = period,
                            id = quest.id,
                            expiresAt = expiresAt,
                            at = tick(),
                        }
                        App.setStatus("Claiming " .. period .. " quest: " .. tostring(quest.title or quest.id))
                        return true
                    end
                end
            end
        end
    end
    return false
end

function App.redeemCodes(data)
    local codesConfig = App.Modules.CodesConfig
    if App.Settings["Auto Redeem Codes"] ~= true or type(data) ~= "table"
    or type(data.RedeemedCodes) ~= "table" or type(codesConfig) ~= "table" then
        return false
    end

    local pending = App.codeRedeemPending
    if pending then
        if data.RedeemedCodes[pending.code] == true then
            App.codeRedeemPending = nil
            return false
        end
        if tick() - pending.at < 4 then
            return false
        end
        App.codeRedeemPending = nil
    end
    if not App.ready("redeemCode", 1) then
        return false
    end

    local codes = {}
    for code in codesConfig do
        if type(code) == "string" then
            codes[#codes + 1] = code
        end
    end
    table.sort(codes)
    for _, code in codes do
        if data.RedeemedCodes[code] ~= true
        and App.fire(App.Net.RedeemCode, code) then
            App.codeRedeemPending = { code = code, at = tick() }
            App.setStatus("Redeeming code " .. code)
            return true
        end
    end
    return false
end

function App.parentOwned(owned, name)
    local tree = App.Modules.UpgradeTree
    if type(tree) ~= "table" or type(tree.GetParent) ~= "function" then
        return true
    end
    local ok, parent = pcall(tree.GetParent, name)
    return not ok or parent == nil or parent == "Start" or owned[parent] == true
end

function App.upgradeTree(data)
    if App.Settings["Auto Upgrade Skill Tree"] ~= true or type(data) ~= "table"
    or type(App.Modules.Upgrades) ~= "table" or not App.ready("tree", 1) then
        return false
    end
    local groups = App.Settings["Skill Tree Groups"]
    local owned = type(data.Upgrades) == "table" and data.Upgrades or {}
    local money = tonumber(data.Money) or 0
    local pick, price = nil, nil
    for name, config in App.Modules.Upgrades do
        local group = type(name) == "string" and string.match(name, "^(.-)%s+[IVX]+$") or nil
        local cost = type(config) == "table" and tonumber(config.price) or nil
        if name ~= "Start" and not owned[name] and cost and cost <= money
        and App.parentOwned(owned, name)
        and (type(groups) ~= "table" or next(groups) == nil or groups[group] == true)
        and (not price or cost < price) then
            pick, price = name, cost
        end
    end
    if pick then
        App.fire(App.Net.BuyUpgrade, pick)
        App.setStatus("Buying skill " .. pick)
        return true
    end
    return false
end

function App.fuse(data)
    if App.Settings["Auto Fuse"] ~= true or type(data) ~= "table"
    or type(data.Inventory) ~= "table" or not App.ready("fuse", 1) then
        return false
    end
    local util = App.Modules.FusingUtil
    if type(util) ~= "table" or type(util.GetChance) ~= "function" then
        return false
    end
    local from = math.max(0, tonumber(App.Settings["Fuse From"]) or 0)
    local below = math.max(0, tonumber(App.Settings["Fuse Below"]) or 0)
    local protected = App.protectedUnits(data)
    local units = {}
    for key, entry in data.Inventory do
        local ok, odds = pcall(util.GetChance, entry)
        odds = ok and tonumber(odds) or nil
        if odds and not protected[key] and (from == 0 or odds >= from)
        and (below == 0 or odds < below) then
            units[#units + 1] = { key = key, odds = odds }
        end
    end
    table.sort(units, function(a, b)
        if App.Settings["Fuse Order"] == "Rarest First" then
            return a.odds > b.odds
        end
        return a.odds < b.odds
    end)
    if #units < 3 then
        return false
    end
    App.fire(App.Net.Fuse, units[1].key, units[2].key, units[3].key)
    App.setStatus("Fusing 3 units")
    return true
end

function App.rollAttribute(data, kind)
    local isTrait = kind == "Trait"
    local enabledKey = isTrait and "Auto Trait Reroll" or "Auto Grade Reroll"
    local targetKey = isTrait and "Trait" or "Grade"
    local unitKey = isTrait and "Trait Unit" or "Grade Unit"
    local resource = isTrait and "Trait Reroll" or "Gems"
    if App.Settings[enabledKey] ~= true or type(data) ~= "table"
    or type(data.Inventory) ~= "table" or not App.ready(kind, isTrait and 0.25 or 0.3) then
        return false
    end
    local key = App.unitLabels[App.Settings[unitKey]]
    local entry = key and data.Inventory[key] or nil
    local target = App.Settings[targetKey]
    if type(entry) ~= "table" or type(target) ~= "string" or target == "" then
        return false
    end
    local current = entry.attributes and entry.attributes[string.lower(kind)]
    if current == target then
        App.Settings[enabledKey] = false
        App.setStatus(kind .. " target reached")
        return true
    end
    local stock = data.Inventory[resource]
    if type(stock) ~= "table" or (tonumber(stock.amount) or 0) <= 0 then
        App.Settings[enabledKey] = false
        App.setStatus("No " .. resource .. " left")
        return false
    end
    App.fire(isTrait and App.Net.TraitRoll or App.Net.GradeRoll, key, true)
    return true
end

function App.finishTowerRun()
    App.towerActive = false
    local rewards = {}
    for _, name in App.towerRewardOrder or {} do
        rewards[#rewards + 1] = tostring(App.towerRewards[name]) .. "x " .. name
    end
    App.towerLastRun = #rewards > 0 and table.concat(rewards, ", ") or "-"
    App.towerBest = math.max(App.towerBest, App.towerRunFloor)
end

function App.addTowerRewards(rewards)
    if type(rewards) ~= "table" then
        return
    end
    for key, value in rewards do
        local name = type(key) == "string" and key
            or type(value) == "table" and value.name or nil
        local amount = type(value) == "table" and tonumber(value.amount)
            or tonumber(value)
        if name and amount and amount > 0 then
            if not App.towerRewards[name] then
                App.towerRewardOrder[#App.towerRewardOrder + 1] = name
                App.towerRewards[name] = 0
            end
            App.towerRewards[name] = App.towerRewards[name] + amount
        end
    end
end

function App.readTowerSequence(sequence)
    local refs = App.Modules.TowerRefs
    local actions = type(refs) == "table" and refs.Actions or {}
    local ended = false
    local steps = sequence.action and { sequence } or sequence
    for _, step in steps do
        if type(step) == "table" then
            App.addTowerRewards(step.rewards)
            if step.action == actions.floorStarted or step.action == "floorStarted" then
                local floor = tonumber(step.floor) or App.towerRunFloor
                App.towerRunFloor = math.max(App.towerRunFloor, floor)
                App.towerBest = math.max(App.towerBest, App.towerRunFloor)
            elseif step.action == actions.floorCompleted or step.action == "floorCompleted" then
                local cleared = tonumber(step.floor) or App.towerRunFloor
                App.towerRunFloor = math.max(App.towerRunFloor, cleared)
                if not App.towerSeenFloors[cleared] then
                    App.towerSeenFloors[cleared] = true
                    App.towerFloors = App.towerFloors + 1
                end
            elseif step.action == actions.ended or step.action == "ended" then
                ended = true
            end
        end
    end
    if ended then
        App.finishTowerRun()
    end
    return ended
end

function App.towerNames(selectedOnly)
    local all = {}
    local towers = App.Modules.Towers
    if type(towers) == "table" and type(towers.GetAll) == "function" then
        local ok, configs = pcall(towers.GetAll)
        if ok and type(configs) == "table" then
            for name, config in configs do
                if not selectedOnly or App.Settings["Rotate Towers"][name] == true then
                    all[#all + 1] = { name = name, order = tonumber(config.order) or math.huge }
                end
            end
        end
    end
    table.sort(all, function(left, right)
        return left.order == right.order and left.name < right.name or left.order < right.order
    end)
    local names = {}
    for _, item in all do
        names[#names + 1] = item.name
    end
    return names
end

function App.towerPotionCount(towerName, data)
    local totals = {}
    for key, entry in type(data) == "table" and data.Inventory or {} do
        if type(entry) == "table" then
            local name = entry.name or key
            totals[name] = (totals[name] or 0) + (tonumber(entry.amount) or 1)
        end
    end
    local ok, configs = pcall(App.Modules.Towers.GetAll)
    local config = ok and configs[towerName] or nil
    local seen, count = {}, 0
    for _, drop in type(config) == "table" and config.drops or {} do
        for _, entry in type(drop) == "table" and drop.entries or {} do
            local name = type(entry) == "table" and entry.name or nil
            if name and not seen[name] then
                local okEntry, item = pcall(App.Modules.EntryRegistry.getEntryConfig, name)
                if okEntry and type(item) == "table" and item.kind == "Boost" then
                    seen[name] = true
                    count = count + (totals[name] or 0)
                end
            end
        end
    end
    return count
end

function App.chooseTower(data)
    local mode = App.Settings["Tower Mode"]
    if mode == "Single" then
        return App.Settings["Tower"]
    end
    local names = App.towerNames(true)
    if #names == 0 then
        return nil
    end
    if mode == "Potion Need" then
        local chosen, lowest = names[1], math.huge
        for _, name in names do
            local count = App.towerPotionCount(name, data)
            if count < lowest then
                chosen, lowest = name, count
            end
        end
        return chosen
    end
    App.towerIndex = (App.towerIndex or 0) % #names + 1
    return names[App.towerIndex]
end

function App.tower(data)
    if App.Settings["Auto Tower"] ~= true then
        return false
    end
    if App.towerActive then
        if not App.ready("towerFloor", 0.6) then
            return false
        end
        local ok, sequence = App.invoke(App.Net.CompleteTowerFloor)
        if not ok then
            return false
        end
        if type(sequence) == "table" then
            App.readTowerSequence(sequence)
        else
            App.towerState = "Resuming " .. tostring(App.towerName)
        end
        return true
    end
    if not App.ready("tower", 0.6) then
        return false
    end
    local tower = App.chooseTower(data)
    if not tower then
        App.towerState = "Pick the towers to rotate"
        return false
    end
    if App.Settings["Auto Equip Best Team"] == true then
        App.fire(App.Net.EquipBestTower)
    end
    local ok = App.invoke(App.Net.PlayTower, tower)
    if not ok then
        return false
    end
    App.towerActive = true
    App.towerStarted = true
    App.towerName = tower
    App.towerRunFloor = 0
    App.towerSeenFloors = {}
    App.towerRewards = {}
    App.towerRewardOrder = {}
    App.towerRuns = App.towerRuns + 1
    App.towerState = "Resuming " .. tostring(tower)
    return true
end

function App.updateTowerStatus()
    local state = App.Settings["Auto Tower"] == true
        and (App.towerState or "Waiting") or "Idle"
    if App.towerActive and App.towerRunFloor > 0 then
        state = tostring(App.towerName) .. " floor " .. tostring(App.towerRunFloor)
    end
    App.towerStatus = "Tower: " .. state
        .. "\n" .. tostring(App.towerRuns) .. " Runs  "
        .. tostring(App.towerFloors) .. " Floors Cleared  Best Floor "
        .. tostring(App.towerBest) .. "\nLast Run: " .. App.towerLastRun
    if App.towerStatusLabel and App.towerStatusLabel.setText then
        pcall(App.towerStatusLabel.setText, App.towerStatus)
    end
    if App.blackStatus then
        App.blackStatus.Text = App.towerStatus
    end
end

function App.ensureBlackScreen()
    if App.blackScreenGui then
        return
    end
    local old = game.CoreGui:FindFirstChild("AnimeDiceRemakeBlackScreen")
    if old then
        old:Destroy()
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "AnimeDiceRemakeBlackScreen"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100000
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = game.CoreGui

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BorderSizePixel = 0
    background.Size = UDim2.fromScale(1, 1)
    background.Parent = gui

    local status = Instance.new("TextLabel")
    status.Name = "TowerStatus"
    status.AnchorPoint = Vector2.new(0.5, 0.5)
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromScale(0.5, 0.5)
    status.Size = UDim2.fromScale(0.8, 0.25)
    status.Font = Enum.Font.GothamBold
    status.Text = App.towerStatus or "Tower: Idle"
    status.TextColor3 = Color3.new(1, 1, 1)
    status.TextSize = 24
    status.TextWrapped = true
    status.Parent = background

    local close = Instance.new("TextButton")
    close.Name = "Disable"
    close.AnchorPoint = Vector2.new(0.5, 1)
    close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    close.BorderSizePixel = 0
    close.Position = UDim2.fromScale(0.5, 0.95)
    close.Size = UDim2.fromOffset(220, 42)
    close.Font = Enum.Font.GothamSemibold
    close.Text = "Disable Black Screen"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.TextSize = 14
    close.Parent = background
    close.MouseButton1Click:Connect(function()
        App.Settings["Black Screen"] = false
        gui.Enabled = false
    end)

    App.blackScreenGui = gui
    App.blackStatus = status
end

function App.updateBlackScreen()
    if App.Settings["Black Screen"] == true then
        App.ensureBlackScreen()
    end
    if App.blackScreenGui then
        App.blackScreenGui.Enabled = App.Settings["Black Screen"] == true
    end
end

function App.boostFps()
    if App.fpsApplied then
        return
    end
    App.fpsApplied = true
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game.Lighting.GlobalShadows = false
    end)
    local removed = 0
    for _, item in game.Lighting:GetChildren() do
        if not item:IsA("Sky") then
            item:Destroy()
            removed = removed + 1
        end
    end
    for _, item in workspace:GetDescendants() do
        if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam")
        or item:IsA("Smoke") or item:IsA("Fire") or item:IsA("Sparkles")
        or item:IsA("Decal") or item:IsA("Texture") then
            item:Destroy()
            removed = removed + 1
        elseif item:IsA("BasePart") then
            item.Reflectance = 0
        end
    end
    App.setStatus("FPS boost stripped " .. tostring(removed) .. " effects")
end

function App.deleteMap()
    if App.mapDeleted then
        return
    end
    App.mapDeleted = true
    local removed = 0
    for _, name in { "Map", "AuraFuseMachine" } do
        local item = workspace:FindFirstChild(name)
        if item then
            item:Destroy()
            removed = removed + 1
        end
    end
    App.setStatus("Deleted " .. tostring(removed) .. " map models")
end

function App.cleanupTowerUi()
    if App.blackScreenGui then
        App.blackScreenGui:Destroy()
        App.blackScreenGui = nil
        App.blackStatus = nil
    end
    if App.tradeConnection then
        App.tradeConnection:Disconnect()
        App.tradeConnection = nil
    end
end

function App.resolvePlayer(value)
    if type(value) ~= "string" then
        return nil
    end
    local wanted = string.lower(value)
    for _, player in Players:GetPlayers() do
        if player ~= plr and (string.lower(player.Name) == wanted
        or string.lower(player.DisplayName) == wanted or tostring(player.UserId) == value) then
            return player
        end
    end
    return nil
end

function App.sendTradeRequest()
    local player = App.resolvePlayer(App.Settings["Trade Player"])
    if not player then
        App.setStatus("Trade player not found")
        return false
    end
    if not App.ready("tradeRequest", 6) then
        App.setStatus("Wait before sending another trade request")
        return false
    end
    App.trade.requestPending = player
    local ok = App.fire(App.Net.RequestTrade, player)
    if not ok then
        App.trade.requestPending = nil
        App.setStatus("Trade request failed")
        return false
    end
    App.setStatus("Sending trade request to " .. player.Name)
    task.delay(6, function()
        if generation == getgenv().AnimeDiceRemakeGeneration
        and App.trade.requestPending == player then
            App.trade.requestPending = nil
            App.setStatus("Trade request was not accepted by the server")
        end
    end)
    return true
end

function App.acceptAllowed(player)
    if not player then
        return false
    end
    if App.Settings["Use Trade Whitelist"] ~= true then
        return true
    end
    local list = App.Settings["Accept Players"]
    return type(list) == "table" and (list[player.Name] == true
        or list[tostring(player.UserId)] == true)
end

function App.syncTradeRequests(data)
    if App.Settings["Auto Accept Trades"] == true and type(data) == "table"
    and data.TradeRequestsEnabled ~= true and App.ready("tradeRequests", 1) then
        App.fire(App.Net.SetTradeRequestsEnabled, true)
    end
end

function App.tradeEntryInfo(key, entry)
    if type(entry) ~= "table" or type(entry.name) ~= "string" then
        return false, false
    end
    local config = App.Modules.TradeConfig
    if type(config) == "table" and table.find(config.UNTRADEABLE_ENTRIES or {}, entry.name) then
        return false, false
    end
    local registry = App.Modules.EntryRegistry
    if type(registry) ~= "table" then
        return false, false
    end
    local okEntry, entryConfig = pcall(registry.getEntryConfig, entry.name)
    local okKind, kindConfig = pcall(
        registry.getKindConfig,
        okEntry and entryConfig and entryConfig.kind
    )
    if not okKind or type(kindConfig) ~= "table" then
        return false, false
    end
    return not kindConfig.stackable or key == entry.name, kindConfig.stackable == true
end

function App.tradeAmount(value)
    local amount = tonumber(value == nil and App.Settings["Trade Amount"] or value) or 1
    if amount ~= amount or math.abs(amount) == math.huge then
        return 1
    end
    amount = math.floor(amount)
    return math.min(9007199254740991, math.max(1, amount))
end

function App.wantedTradeAmount(key, entry)
    local tradeable, stackable = App.tradeEntryInfo(key, entry)
    if not tradeable then
        return nil
    end
    if not stackable then
        return 1
    end
    local available = math.max(0, math.floor(tonumber(entry.amount) or 0))
    if App.Settings["Send Max Quantity"] == true then
        return available
    end
    return math.min(available, App.tradeAmount())
end

function App.offerTradeEntries(data)
    local state = App.trade.state
    if type(state) ~= "table" or state.phase ~= "Offer" or type(data) ~= "table" then
        return false
    end
    local selected = App.Settings["Trade Entries"]
    for label, on in selected or {} do
        local key = on and App.tradeLabels[label] or nil
        local entry = key and data.Inventory and data.Inventory[key] or nil
        if entry then
            local wanted = App.wantedTradeAmount(key, entry)
            local current = state.ownOffer and tonumber(state.ownOffer[key]) or 0
            if wanted and wanted > 0 and current ~= wanted
            and App.ready("offer:" .. key, 0.4) then
                App.fire(App.Net.ChangeOffer, key, wanted - current)
                return true
            end
        end
    end
    return false
end

function App.tradeOffersReady(data)
    local state = App.trade.state
    if type(state) ~= "table" or state.phase ~= "Offer" or type(data) ~= "table" then
        return false
    end
    local selected = 0
    for label, on in App.Settings["Trade Entries"] or {} do
        local key = on and App.tradeLabels[label] or nil
        local entry = key and data.Inventory and data.Inventory[key] or nil
        local wanted = entry and App.wantedTradeAmount(key, entry) or nil
        if wanted and wanted > 0 then
            selected = selected + 1
            if not state.ownOffer or tonumber(state.ownOffer[key]) ~= wanted then
                return false
            end
        end
    end
    return selected > 0
end

App.tradeConnection = App.Net.TradeEvent.OnClientEvent:Connect(function(event, payload)
    if generation ~= getgenv().AnimeDiceRemakeGeneration then
        return
    end
    if event == "RequestReceived" then
        App.trade.request = payload and payload.player
        if App.Settings["Auto Accept Trades"] == true
        and App.acceptAllowed(App.trade.request) then
            App.fire(App.Net.RespondTrade, true)
        end
    elseif event == "RequestSent" then
        App.trade.requestPending = nil
        App.trade.requested = payload and payload.player
        App.setStatus("Trade request sent to " .. tostring(App.trade.requested and App.trade.requested.Name))
    elseif event == "RequestClosed" or event == "RequestExpired" then
        App.trade.requestPending = nil
        App.trade.requested = nil
    elseif event == "Started" then
        App.trade.partner = payload and payload.partner
        App.trade.state = nil
    elseif event == "Updated" then
        App.trade.state = payload
        App.trade.partner = payload and payload.partner
    elseif event == "Ended" then
        App.trade.state = nil
        App.trade.partner = nil
        if payload and payload.reason == "Completed" then
            App.trade.sent = App.trade.sent + 1
        end
    end
end)

do
    local old = getgenv().AnimeDiceRemakeAntiAfk
    if old then
        pcall(function()
            old:Disconnect()
        end)
    end
    getgenv().AnimeDiceRemakeAntiAfk = plr.Idled:Connect(function()
        if generation == getgenv().AnimeDiceRemakeGeneration
        and App.Settings["Anti AFK"] == true then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end)
end

do
    local function listKeys(source)
        local result = {}
        if type(source) == "table" then
            for name in source do
                if type(name) == "string" then
                    result[#result + 1] = name
                end
            end
        end
        table.sort(result)
        return result
    end

    local function towerOptions()
        local names = App.towerNames(false)
        return #names > 0 and names or { "Dragon Tower" }
    end

    local function potionOptions()
        local result = {}
        local registry = App.Modules.EntryRegistry
        if type(registry) == "table" and type(registry.entriesOfKind) == "function" then
            pcall(function()
                for name in registry.entriesOfKind("Boost") do
                    result[name] = App.Settings["Potions"][name] == true
                end
            end)
        end
        return result
    end

    local function skillGroups()
        local result = {}
        for name in App.Modules.Upgrades or {} do
            local group = type(name) == "string" and string.match(name, "^(.-)%s+[IVX]+$") or nil
            if group then
                result[group] = App.Settings["Skill Tree Groups"][group] == true
            end
        end
        return result
    end

    local function questShopOptions()
        local result = {}
        local config = App.Modules.QuestConfig
        local selected = App.Settings["Quest Shop Items"]
        if type(selected) ~= "table" then
            selected = {}
        end
        if type(config) == "table" then
            for _, item in config.Shop or {} do
                if type(item) == "table" and type(item.name) == "string" then
                    result[item.name] = selected[item.name] == true
                end
            end
        end
        return result
    end

    local function rebirthStatOptions()
        local result = {}
        local config = App.Modules.RebirthStatsConfig
        local selected = App.Settings["Rebirth Stat Selection"]
        if type(selected) ~= "table" then
            selected = {}
        end
        if type(config) == "table" then
            for _, stat in config.Stats or {} do
                if type(stat) == "table" and type(stat.name) == "string" then
                    result[stat.name] = selected[stat.name] == true
                end
            end
        end
        return result
    end

    local Library = mainLib.Init({
        gameName = "Anime Dice Remake",
        keyToggleUI = Enum.KeyCode.RightControl,
        density = "auto",
    })
    App.Library = Library

    local Automation = Library.createPage({
        pageName = "Automation",
        pageTitle = "Automation",
        pageIcon = "refresh-cw",
    })
    local Roll = Automation.createSection({
        sectionName = "Auto Roll",
        sectionIcon = "dices",
        sectionSearch = true,
    })
    Roll.CheckBox({ title = "Auto Roll", description = "Keeps the game's replicated auto roll enabled.", isVisible = true, isChecked = App.Settings["Auto Roll"], callback = function(value) App.Settings["Auto Roll"] = value end })
    Roll.CheckBox({ title = "Auto Hide Roll Animation", description = "Hides the roll cutscene and animation while keeping the roll results.", searchAliases = { "skip roll animation", "fast roll", "hide roll" }, isVisible = true, isChecked = App.Settings["Skip Roll Animation"], callback = function(value) App.Settings["Skip Roll Animation"] = value end })
    App.statusLabel = Roll.Label({ title = "Status: Starting", searchAliases = "farm status", isVisible = true, isBold = true })

    local Sell = Automation.createSection({ sectionName = "Auto Sell", sectionIcon = "badge-dollar-sign", sectionSearch = true })
    Sell.CheckBox({ title = "Auto Sell Below", description = "Uses the game's native auto sell threshold.", isVisible = true, isChecked = App.Settings["Auto Sell Below"], callback = function(value) App.Settings["Auto Sell Below"] = value end })
    App.sellBelowBox = Sell.Box({ title = "Sell Below 1 In", description = "Enter a number or shorthand such as 1k, 2m, 1q, or 1sx.", searchAliases = { "odds", "rarity", "amount" }, isVisible = true, numberOnly = false, clearTextOnFocus = false, clearTextOnCallback = false, defaultValue = App.Settings["Sell Below"], callback = function(value)
        local amount = App.parseSellBelow(value)
        if amount then
            App.Settings["Sell Below"] = amount
        end
    end })
    Sell.Button({ title = "Sell Bag Below Now", description = "Sells matching unlocked units that are not equipped.", isVisible = true, buttonTitle = "Sell", callback = function() App.sellBelowNow(App.data()) end })

    local Potions = Automation.createSection({ sectionName = "Potions", sectionIcon = "flask-conical", sectionSearch = true })
    Potions.CheckBox({ title = "Auto Use Potions", description = "Uses only the selected potions when they are available.", isVisible = true, isChecked = App.Settings["Auto Use Potions"], callback = function(value) App.Settings["Auto Use Potions"] = value end })
    Potions.Select({ title = "Potions", dropdowntitle = "Potions", description = "Choose the boosts the worker may consume.", isVisible = true, search = true, options = potionOptions(), disableSelectedLayoutOrder = true, callback = function(name, enabled) App.Settings["Potions"][name] = enabled end })

    local Misc = Automation.createSection({ sectionName = "Misc", sectionIcon = "shield", sectionSearch = true })
    Misc.CheckBox({ title = "Anti AFK", description = "Prevents the idle timeout while this runtime is active.", isVisible = true, isChecked = App.Settings["Anti AFK"], callback = function(value) App.Settings["Anti AFK"] = value end })
    Misc.CheckBox({ title = "Black Screen", description = "Covers the full screen while keeping tower status visible.", searchAliases = { "blank screen", "performance" }, isVisible = true, isChecked = App.Settings["Black Screen"], callback = function(value) App.Settings["Black Screen"] = value; App.updateBlackScreen() end })
    Misc.CheckBox({ title = "FPS Boost", description = "Lowers rendering quality and removes current visual effects for this session.", searchAliases = { "performance", "lag", "effects" }, isVisible = true, isChecked = App.Settings["FPS Boost"], callback = function(value) App.Settings["FPS Boost"] = value; if value then App.boostFps() end end })
    Misc.CheckBox({ title = "Delete Map", description = "Deletes the map and aura fuse machine for this session.", searchAliases = { "remove map", "lag" }, isVisible = true, isChecked = App.Settings["Delete Map"], callback = function(value) App.Settings["Delete Map"] = value; if value then App.deleteMap() end end })

    local Progression = Library.createPage({ pageName = "Progression", pageTitle = "Progression", pageIcon = "trending-up" })
    local Plot = Progression.createSection({ sectionName = "Rebirth And Plot", sectionIcon = "star", sectionSearch = true })
    Plot.CheckBox({ title = "Auto Rebirth", description = "Rebirths when the replicated money meets the next cost.", isVisible = true, isChecked = App.Settings["Auto Rebirth"], callback = function(value) App.Settings["Auto Rebirth"] = value end })
    Plot.CheckBox({ title = "Auto Equip Best Gear", description = "Equips the owned gear with the strongest combined buffs in each slot.", isVisible = true, isChecked = App.Settings["Auto Equip Best Gear"], callback = function(value) App.Settings["Auto Equip Best Gear"] = value end })
    Plot.CheckBox({ title = "Auto Equip Best", description = "Equips the best available plot units.", isVisible = true, isChecked = App.Settings["Auto Equip Best"], callback = function(value) App.Settings["Auto Equip Best"] = value end })
    Plot.CheckBox({ title = "Auto Collect", description = "Collects replicated plot balances.", isVisible = true, isChecked = App.Settings["Auto Collect"], callback = function(value) App.Settings["Auto Collect"] = value end })
    Plot.CheckBox({ title = "Auto Upgrade Units", description = "Levels placed units up to the selected limit.", isVisible = true, isChecked = App.Settings["Auto Upgrade Units"], callback = function(value) App.Settings["Auto Upgrade Units"] = value end })
    Plot.Slider({ title = "Upgrade Until Level", description = "Stops upgrading a placed unit at this level.", isVisible = true, minValue = 1, maxValue = 100, defaultValue = App.Settings["Upgrade Until Level"], precise = false, callback = function(value) App.Settings["Upgrade Until Level"] = value end })

    local RebirthStats = Progression.createSection({ sectionName = "Rebirth Stats", sectionIcon = "star", sectionSearch = true })
    RebirthStats.CheckBox({ title = "Auto Allocate Rebirth Stats", description = "Spends available rebirth points on the selected stats.", isVisible = true, isChecked = App.Settings["Auto Allocate Rebirth Stats"], callback = function(value) App.Settings["Auto Allocate Rebirth Stats"] = value end })
    RebirthStats.Select({ title = "Selected Stats", dropdowntitle = "Stats", description = "Choose which stats automatic allocation may spend points on.", isVisible = true, search = true, options = rebirthStatOptions(), disableSelectedLayoutOrder = true, callback = function(name, enabled) App.Settings["Rebirth Stat Selection"][name] = enabled end })
    RebirthStats.Select({ title = "Allocation Mode", dropdowntitle = "Mode", description = "Priority First fills each stat to Max Level before moving down the order. Evenly balances selected stat levels.", isVisible = true, search = false, options = { "Priority First", "Evenly" }, defaultValue = App.Settings["Rebirth Stat Mode"], callback = function(value) App.Settings["Rebirth Stat Mode"] = value end })
    RebirthStats.Box({ title = "Priority Order", description = "Comma-separated stat order, for example Luck, Money, Damage. This order breaks ties in Evenly mode.", searchAliases = { "rebirth stat order", "max first" }, isVisible = true, numberOnly = false, clearTextOnFocus = false, clearTextOnCallback = false, defaultValue = App.Settings["Rebirth Stat Priority"], callback = function(value) App.Settings["Rebirth Stat Priority"] = tostring(value) end })
    RebirthStats.Box({ title = "Max Level Per Stat", description = "Optional target level. Reaching it advances to the next stat; use 0 for no cap.", searchAliases = { "stat cap", "target level" }, isVisible = true, numberOnly = true, clearTextOnFocus = false, clearTextOnCallback = false, defaultValue = App.Settings["Rebirth Stat Max Level"], callback = function(value) App.Settings["Rebirth Stat Max Level"] = math.max(0, math.floor(tonumber(value) or 0)) end })

    local DiceShop = Progression.createSection({ sectionName = "Dice Shop", sectionIcon = "store", sectionSearch = true })
    DiceShop.CheckBox({ title = "Auto Dice Shop", description = "Buys the cheapest affordable unowned die.", isVisible = true, isChecked = App.Settings["Auto Dice Shop"], callback = function(value) App.Settings["Auto Dice Shop"] = value end })
    DiceShop.CheckBox({ title = "Auto Equip Best Dice", description = "Equips a die after a confirmed purchase request.", isVisible = true, isChecked = App.Settings["Auto Equip Best Dice"], callback = function(value) App.Settings["Auto Equip Best Dice"] = value end })

    local Rewards = Progression.createSection({ sectionName = "Rewards", sectionIcon = "gift", sectionSearch = true })
    Rewards.CheckBox({ title = "Auto Claim Daily", description = "Requests an available daily reward.", isVisible = true, isChecked = App.Settings["Auto Claim Daily"], callback = function(value) App.Settings["Auto Claim Daily"] = value end })
    Rewards.CheckBox({ title = "Auto Claim Quests", description = "Claims completed Daily and Weekly quests.", isVisible = true, isChecked = App.Settings["Auto Claim Quests"], callback = function(value) App.Settings["Auto Claim Quests"] = value end })
    Rewards.CheckBox({ title = "Auto Redeem Codes", description = "Redeems unused codes listed in the game config.", isVisible = true, isChecked = App.Settings["Auto Redeem Codes"], callback = function(value) App.Settings["Auto Redeem Codes"] = value end })
    Rewards.CheckBox({ title = "Auto Claim Offline", description = "Claims replicated offline earnings when pending.", isVisible = true, isChecked = App.Settings["Auto Claim Offline"], callback = function(value) App.Settings["Auto Claim Offline"] = value end })
    Rewards.CheckBox({ title = "Auto Claim Group", description = "Claims the group reward when it is unclaimed.", isVisible = true, isChecked = App.Settings["Auto Claim Group"], callback = function(value) App.Settings["Auto Claim Group"] = value end })

    local QuestShop = Progression.createSection({ sectionName = "Quest Shop", sectionIcon = "ticket", sectionSearch = true })
    QuestShop.CheckBox({ title = "Auto Buy Quest Shop Items", description = "Buys selected items with Tickets whenever you can afford them.", isVisible = true, isChecked = App.Settings["Auto Buy Quest Shop Items"], callback = function(value) App.Settings["Auto Buy Quest Shop Items"] = value end })
    QuestShop.Select({ title = "Ticket Items", dropdowntitle = "Items", description = "Choose which Quest Shop items automatic buying may purchase.", searchAliases = { "quest shop", "tickets", "ticket item" }, isVisible = true, search = true, options = questShopOptions(), disableSelectedLayoutOrder = true, callback = function(name, enabled) App.Settings["Quest Shop Items"][name] = enabled end })

    local SkillTree = Progression.createSection({ sectionName = "Skill Tree", sectionIcon = "git-branch", sectionSearch = true })
    SkillTree.CheckBox({ title = "Auto Upgrade Skill Tree", description = "Buys the cheapest affordable upgrade with an owned parent.", isVisible = true, isChecked = App.Settings["Auto Upgrade Skill Tree"], callback = function(value) App.Settings["Auto Upgrade Skill Tree"] = value end })
    SkillTree.Select({ title = "Skill Tree Groups", dropdowntitle = "Groups", description = "Leave every group off to allow all groups.", isVisible = true, search = true, options = skillGroups(), disableSelectedLayoutOrder = true, callback = function(name, enabled) App.Settings["Skill Tree Groups"][name] = enabled end })

    local Inventory = Library.createPage({ pageName = "Inventory", pageTitle = "Inventory", pageIcon = "package" })
    local Fuse = Inventory.createSection({ sectionName = "Fuse", sectionIcon = "list", sectionSearch = true })
    Fuse.CheckBox({ title = "Auto Fuse", description = "Fuses three unlocked and unequipped units in the selected odds range.", isVisible = true, isChecked = App.Settings["Auto Fuse"], callback = function(value) App.Settings["Auto Fuse"] = value end })
    Fuse.Box({ title = "Fuse From 1 In", description = "Minimum odds. Use zero for no minimum.", isVisible = true, numberOnly = true, clearTextOnFocus = false, clearTextOnCallback = false, defaultValue = App.Settings["Fuse From"], callback = function(value) App.Settings["Fuse From"] = tonumber(value) or 0 end })
    Fuse.Box({ title = "Fuse Below 1 In", description = "Maximum odds. Use zero for no maximum.", isVisible = true, numberOnly = true, clearTextOnFocus = false, clearTextOnCallback = false, defaultValue = App.Settings["Fuse Below"], callback = function(value) App.Settings["Fuse Below"] = tonumber(value) or 0 end })
    Fuse.Select({ title = "Fuse Order", dropdowntitle = "Order", description = "Chooses which matching units are fused first.", isVisible = true, search = false, options = { "Rarest First", "Common First" }, defaultValue = App.Settings["Fuse Order"], callback = function(value) App.Settings["Fuse Order"] = value end })

    local Trait = Inventory.createSection({ sectionName = "Trait Reroll", sectionIcon = "sparkles", sectionSearch = true })
    Trait.CheckBox({ title = "Auto Trait Reroll", description = "Rerolls the chosen unit until the target trait is replicated.", isVisible = true, isChecked = App.Settings["Auto Trait Reroll"], callback = function(value) App.Settings["Auto Trait Reroll"] = value end })
    App.traitSelect = Trait.Select({ title = "Traits", dropdowntitle = "Trait", description = "Target trait.", isVisible = true, search = true, options = listKeys(App.Modules.Traits), defaultValue = App.Settings["Trait"], callback = function(value) App.Settings["Trait"] = value end })
    App.traitUnitSelect = Trait.Select({ title = "Trait Unit", dropdowntitle = "Unit", description = "Unit to reroll.", isVisible = true, search = true, options = {}, defaultValue = App.Settings["Trait Unit"], callback = function(value) App.Settings["Trait Unit"] = value end })

    local Grade = Inventory.createSection({ sectionName = "Grade Reroll", sectionIcon = "gem", sectionSearch = true })
    Grade.CheckBox({ title = "Auto Grade Reroll", description = "Rerolls the chosen unit until the target grade is replicated.", isVisible = true, isChecked = App.Settings["Auto Grade Reroll"], callback = function(value) App.Settings["Auto Grade Reroll"] = value end })
    App.gradeSelect = Grade.Select({ title = "Grades", dropdowntitle = "Grade", description = "Target grade.", isVisible = true, search = true, options = listKeys(App.Modules.Grades), defaultValue = App.Settings["Grade"], callback = function(value) App.Settings["Grade"] = value end })
    App.gradeUnitSelect = Grade.Select({ title = "Grade Unit", dropdowntitle = "Unit", description = "Unit to reroll.", isVisible = true, search = true, options = {}, defaultValue = App.Settings["Grade Unit"], callback = function(value) App.Settings["Grade Unit"] = value end })

    local TowerPage = Library.createPage({ pageName = "Tower", pageTitle = "Tower", pageIcon = "swords" })
    local Tower = TowerPage.createSection({ sectionName = "Auto Tower", sectionIcon = "swords", sectionSearch = true })
    Tower.Select({ title = "Mode", dropdowntitle = "Mode", description = "Single repeats one tower. Rotate cycles the pool. Potion Need picks the tower with the fewest boost potions owned.", isVisible = true, search = false, options = { "Single", "Rotate", "Potion Need" }, defaultValue = App.Settings["Tower Mode"], callback = function(value) App.Settings["Tower Mode"] = value; App.towerIndex = 0 end })
    Tower.Select({ title = "Tower", dropdowntitle = "Tower", description = "Tower repeated in Single mode.", isVisible = true, search = true, options = towerOptions(), defaultValue = App.Settings["Tower"], callback = function(value) App.Settings["Tower"] = value end })
    local rotation = {}
    for _, name in towerOptions() do
        rotation[name] = App.Settings["Rotate Towers"][name] == true
    end
    Tower.Select({ title = "Rotate Towers", dropdowntitle = "Towers", description = "Tower pool used by Rotate and Potion Need modes.", isVisible = true, search = true, options = rotation, disableSelectedLayoutOrder = true, callback = function(name, enabled) App.Settings["Rotate Towers"][name] = enabled; App.towerIndex = 0 end })
    Tower.CheckBox({ title = "Auto Equip Best Team", description = "Requests the best tower team before starting.", isVisible = true, isChecked = App.Settings["Auto Equip Best Team"], callback = function(value) App.Settings["Auto Equip Best Team"] = value end })
    Tower.CheckBox({ title = "Auto Tower", description = "Runs tower floors directly without opening the tower battle UI or reward popups.", isVisible = true, isChecked = App.Settings["Auto Tower"], callback = function(value) App.Settings["Auto Tower"] = value; if not value then App.towerActive = false; App.towerState = nil end end })
    App.towerStatusLabel = Tower.Label({ title = "Tower: Idle\n0 Runs  0 Floors Cleared  Best Floor 0\nLast Run: -", searchAliases = "tower status", isVisible = true, isBold = true })

    local TradePage = Library.createPage({ pageName = "Trade", pageTitle = "Trade", pageIcon = "handshake" })
    local Send = TradePage.createSection({ sectionName = "Send Trade", sectionIcon = "send", sectionSearch = true })
    App.playerSelect = Send.Select({ title = "Player", dropdowntitle = "Player", description = "Player who receives the trade request.", isVisible = true, search = true, options = {}, defaultValue = App.Settings["Trade Player"], callback = function(value) App.Settings["Trade Player"] = value end })
    App.tradeEntrySelect = Send.Select({ title = "Items And Units", dropdowntitle = "Entries", description = "Entries to add after a trade starts.", isVisible = true, search = true, options = { ["No entries"] = false }, disableSelectedLayoutOrder = true, callback = function(name, enabled) App.Settings["Trade Entries"][name] = enabled end })
    Send.Box({ title = "Amount Per Item", description = "Amount offered for stackable entries, limited only by the quantity owned.", searchAliases = { "trade amount", "quantity" }, isVisible = true, numberOnly = true, clearTextOnFocus = false, clearTextOnCallback = false, defaultValue = App.Settings["Trade Amount"], callback = function(value) App.Settings["Trade Amount"] = App.tradeAmount(value) end })
    Send.CheckBox({ title = "Send Max Quantity", description = "Offers every available copy of selected stackable entries.", isVisible = true, isChecked = App.Settings["Send Max Quantity"], callback = function(value) App.Settings["Send Max Quantity"] = value end })
    Send.Button({ title = "Send Trade", description = "Sends a trade request to the selected player.", isVisible = true, buttonTitle = "Send", callback = App.sendTradeRequest })
    Send.CheckBox({ title = "Auto Send At Amount", description = "Advances the trade after selected entries are offered.", isVisible = true, isChecked = App.Settings["Auto Send Trade"], callback = function(value) App.Settings["Auto Send Trade"] = value end })

    local Accept = TradePage.createSection({ sectionName = "Auto Accept", sectionIcon = "check", sectionSearch = true })
    Accept.CheckBox({ title = "Auto Accept Trades", description = "Accepts incoming requests from allowed players.", isVisible = true, isChecked = App.Settings["Auto Accept Trades"], callback = function(value) App.Settings["Auto Accept Trades"] = value end })
    Accept.CheckBox({ title = "Use Trade Whitelist", description = "Restricts automatic acceptance to selected players.", isVisible = true, isChecked = App.Settings["Use Trade Whitelist"], callback = function(value) App.Settings["Use Trade Whitelist"] = value end })
    App.acceptSelect = Accept.Select({ title = "Allowed Players", dropdowntitle = "Players", description = "Players allowed to trigger auto accept.", isVisible = true, search = true, options = { ["No players"] = false }, disableSelectedLayoutOrder = true, callback = function(name, enabled) App.Settings["Accept Players"][name] = enabled end })

    App.refreshOptions = function(data)
        local unitOptions = {}
        local tradeOptions = {}
        local inventoryStamp = {}
        App.unitLabels = {}
        App.tradeLabels = {}
        if type(data) == "table" and type(data.Inventory) == "table" then
            for key, entry in data.Inventory do
                if type(entry) == "table" and type(entry.name) == "string" then
                    local label = entry.name .. " [" .. string.sub(tostring(key), 1, 8) .. "]"
                    inventoryStamp[#inventoryStamp + 1] = label
                    local odds = App.entryOdds(entry)
                    if odds then
                        unitOptions[#unitOptions + 1] = label
                        App.unitLabels[label] = key
                    end
                    if App.tradeEntryInfo(key, entry) then
                        tradeOptions[label] = App.Settings["Trade Entries"][label] == true
                        App.tradeLabels[label] = key
                    end
                end
            end
        end
        table.sort(unitOptions)
        table.sort(inventoryStamp)
        local inventoryKey = table.concat(inventoryStamp, "\n")
        if App.inventoryStamp ~= inventoryKey then
            App.inventoryStamp = inventoryKey
            App.traitUnitSelect.updateOption(unitOptions)
            App.gradeUnitSelect.updateOption(unitOptions)
            App.tradeEntrySelect.updateOption(tradeOptions)
        end

        local playerOptions = {}
        local acceptOptions = {}
        for _, player in Players:GetPlayers() do
            if player ~= plr then
                playerOptions[#playerOptions + 1] = player.Name
                acceptOptions[player.Name] = App.Settings["Accept Players"][player.Name] == true
            end
        end
        table.sort(playerOptions)
        local playerKey = table.concat(playerOptions, "\n")
        if App.playerStamp ~= playerKey then
            App.playerStamp = playerKey
            App.playerSelect.updateOption(playerOptions)
            App.acceptSelect.updateOption(acceptOptions)
        end
    end

    Library.useNote.new({ content = "Auto Tower runs the same direct remote loop as BigFroot, so tower battle and reward UI never open.", duration = 7, placement = "search" })
end

task.spawn(function()
    local refreshAt = 0
    while generation == getgenv().AnimeDiceRemakeGeneration do
        local ok, err = xpcall(function()
            local data = App.data()
            App.syncRollAnimation()
            App.syncAutoRoll(data)
            App.syncAutoSell(data)
            App.usePotions(data)
            App.progress(data)
            App.buyQuestShopItems(data)
            App.allocateRebirthStats(data)
            App.equipBestGear(data)
            App.buyDice(data)
            App.claimRewards(data)
            App.claimQuests(data)
            App.redeemCodes(data)
            App.upgradeTree(data)
            App.fuse(data)
            App.rollAttribute(data, "Trait")
            App.rollAttribute(data, "Grade")
            App.tower(data)
            App.updateTowerStatus()
            App.updateBlackScreen()
            if App.Settings["FPS Boost"] == true then App.boostFps() end
            if App.Settings["Delete Map"] == true then App.deleteMap() end
            App.syncTradeRequests(data)
            App.offerTradeEntries(data)
            if App.Settings["Auto Send Trade"] == true and type(App.trade.state) == "table"
            and App.trade.state.phase == "Offer" and App.tradeOffersReady(data)
            and App.ready("advance", 1.5) then
                App.fire(App.Net.AdvanceTrade)
            end
            if tick() >= refreshAt then
                refreshAt = tick() + 2
                App.refreshOptions(data)
            end
            if type(data) ~= "table" then
                App.setStatus("Waiting for replicated data")
            elseif not App.status or App.status == "Starting" then
                App.setStatus("Idle")
            end
        end, debug.traceback)
        if not ok then
            App.lastError = tostring(err)
            App.setStatus("Worker error")
            warn("[AnimeDiceRemake] " .. tostring(err))
            task.wait(1)
        else
            task.wait(0.25)
        end
    end
end)

getgenv().AnimeDiceRemake = App


