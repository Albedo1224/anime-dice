"""Run with: python tests/animedice_claim_cache_spec.py /path/to/luau.exe"""
from pathlib import Path
import subprocess
import sys
import tempfile

source = Path(__file__).resolve().parents[1] / "animedice.lua"
text = source.read_text(encoding="utf-8")
claims = text[text.index("function App.claimState("):text.index("function App.parentOwned(")]
harness = r'''
local now = 100000
local tick = function() return now end
local os = { time = tick }
local calls = {}
local App = {
    Settings = {}, claimCache = {}, Modules = {},
    Net = { ClaimOffline = "offline", ClaimGroup = "group", ClaimDaily = "daily",
        ClaimQuest = "quest", RedeemCode = "code" },
    fire = function(remote, ...) calls[#calls + 1] = {remote, ...}; return true end,
    setStatus = function() end,
}
''' + claims + r'''
local state = App.claimState("test", 1)
assert(App.tryClaim(state, "test"))
for i = 1, 10000 do assert(not App.tryClaim(state, "test")) end
assert(#calls == 1 and not state.done)
now += 30
assert(App.tryClaim(state, "test") and state.nextAt == now + 60)
state.done = true
now += 3600
assert(not App.tryClaim(state, "test"))
assert(App.claimState("test", 2) ~= state)

calls = {}
App.Settings["Auto Redeem Codes"] = true
App.Modules.CodesConfig = { A_EXPIRED = {}, B_VALID = {}, C_OWNED = {} }
local data = { RedeemedCodes = { C_OWNED = true } }
assert(App.redeemCodes(data) and calls[1][2] == "A_EXPIRED")
now += 2
assert(App.redeemCodes(data) and calls[2][2] == "B_VALID")
data.RedeemedCodes.B_VALID = true
now += 2
App.redeemCodes(data)
assert(App.claimCache["code:B_VALID"].done)
assert(#calls == 2 and App.codesAt > now)
data.RedeemedCodes.A_EXPIRED = true
App.codesAt = 0
App.redeemCodes(data)
assert(App.codesAt == math.huge)

calls = {}
App.Settings["Auto Claim Daily"] = true
App.Modules.DailyRewardConfig = { Cooldown = 82800 }
data.LastDailyRewardClaim = now - 82790
App.claimRewards(data)
assert(#calls == 0 and App.rewardsAt == now + 10)
now += 10
App.claimRewards(data)
assert(#calls == 1 and calls[1][1] == "daily")
App.rewardsAt = 0
App.claimRewards(data)
assert(#calls == 1)
data.LastDailyRewardClaim = now
App.rewardsAt = 0
App.claimRewards(data)
assert(#calls == 1)

App.Settings["Auto Claim Group"] = true
data.ClaimedGroupReward = true
App.claimRewards(data)
assert(App.claimCache.group.done and #calls == 1)
App.Settings["Auto Claim Offline"] = true
data.PendingOfflineEarnings = 10
App.claimRewards(data)
assert(#calls == 2)
data.PendingOfflineEarnings = 0
App.rewardsAt = 0
App.claimRewards(data)
assert(App.claimCache.offline.done)
data.PendingOfflineEarnings = 20
App.rewardsAt = 0
App.claimRewards(data)
assert(#calls == 3)

calls = {}
App.Settings["Auto Claim Quests"] = true
App.Modules.QuestConfig = { Periods = { Daily = { quests = {
    {id = "A", target = 1}, {id = "B", target = 1}
} } } }
data.Quests = { Daily = { expiresAt = now + 1000,
    progress = {A = 1, B = 1}, claimed = {} } }
App.claimQuests(data)
now += 2
App.claimQuests(data)
assert(#calls == 2)
App.questsAt = 0
App.claimQuests(data)
assert(#calls == 2)
data.Quests.Daily.claimed = { A = true, B = true }
App.questsAt = 0
App.claimQuests(data)
assert(App.claimCache["quests:Daily"].done)
data.Quests.Daily.expiresAt += 1000
data.Quests.Daily.claimed = {}
App.questsAt = 0
App.claimQuests(data)
now += 2
App.claimQuests(data)
assert(#calls == 4 and not App.claimCache["quests:Daily"].done)
data.Quests.Daily.expiresAt = now - 1
App.questsAt = 0
App.claimQuests(data)
assert(#calls == 4)
print("PASS: claim confirmation, backoff, code fairness, daily deadline, offline reset, quest rollover")
'''
with tempfile.TemporaryDirectory(prefix="animedice-check-") as folder:
    check = Path(folder) / "claims.luau"
    check.write_text(harness, encoding="utf-8")
    subprocess.run([sys.argv[1], str(check)], check=True)
