local NAME, S = ...
S.VERSION = GetAddOnMetadata(NAME, "Version")
S.BUILD = "Release"

LootLog = LibStub("AceAddon-3.0"):NewAddon(NAME, "AceEvent-3.0", "LibSink-2.0")
local LL = LootLog

function LL:log(msg)
    print("|cffC1FFBA"..msg)
end

local function usage()
    LL:log("["..NAME.."] Usage:")
    LL:log("/lootlog list [zone|expac|boss|spec] [#]")
    LL:log("/lootlog stats [zone|expac|boss|spec] [#]")
    LL:log("/lootlog reset [zone|expac|boss|spec] #")
    LL:log("")
    LL:log("Examples:")
    LL:log("/ll list")
    LL:log("/lootlog list zone 1-100")
    LL:log("/lootlog stats expac")
    LL:log("/lootlog reset 42")
end

local function getPercent(count, total)
    return math.floor(count * 10000 / total) / 100
end

local function getCountAndPercent(count, total, numEligible)
    if (numEligible == nil) then
        return count.." ("..getPercent(count, total).."%)"
    else
        return count.." ("..getPercent(count, total).."% of total or "..getPercent(count, numEligible).."% of eligible)"
    end
end

local function lootSuffix(tert, sockets)
    local upgrades = {}
    if (tert ~= "None") then
        upgrades[#upgrades + 1] = tert
    end
    if (sockets > 0) then
        upgrades[#upgrades + 1] = "Sockets: "..sockets
    end
    if (#upgrades > 0) then
        return " ("..table.concat(upgrades, " / ")..")"
    else
        return ""
    end
end

local function logLoot(index, link, tert, sockets)
    local upgrades = {}
    if (tert ~= "None") then
        upgrades[#upgrades + 1] = tert
    end
    if (sockets > 0) then
        upgrades[#upgrades + 1] = "Sockets: "..sockets
    end
    local prefix = "Loot #"..index.." "..link
    return prefix..lootSuffix(tert, sockets)
end

local function logQuery(prefix, index, lastIndex, zoneFilter, expacFilter, bossFilter, specFilter)
    local msg = "["..NAME.."] "..prefix
    if (lastIndex == index) then
        msg = msg.." loot #"..index
    else
        msg = msg.." loots #"..index.."-"..lastIndex
    end

    local filters = {}
    if (zoneFilter ~= nil) then
        filters[#filters + 1] = "zone is "..zoneFilter
    end
    if (expacFilter ~= nil) then
        filters[#filters + 1] = "expac is "..expacFilter
    end
    if (bossFilter ~= nil) then
        filters[#filters + 1] = "boss is "..bossFilter
    end
    if (specFilter ~= nil) then
        filters[#filters + 1] = "spec is "..specFilter
    end
    if (#filters > 0) then
        LL:log(msg.." where "..table.concat(filters, " and "))
    else
        LL:log(msg)
    end
end

local function logLoots(index, count, zoneFilter, expacFilter, bossFilter, specFilter)
    local lootTable = LootLogSavedVars or {}
    local lastIndex = math.min(index + count - 1, #lootTable)
    index = math.max(index, 1)

    logQuery("Listing", index, lastIndex, zoneFilter, expacFilter, bossFilter, specFilter)

    for i = index, lastIndex do
        local link = ""
        local tert = ""
        local sockets = 0
        local zone = ""
        local expac = ""
        local droppedBy = ""
        local lootspec = ""

        for k,v in pairs(lootTable[i]) do
            if (k == "link") then
                link = v
            elseif (k == "tert") then
                tert = v
            elseif (k == "sockets") then
                sockets = v
            elseif (k == "zone") then
                zone = v
            elseif (k == "expac") then
                expac = v
            elseif (k == "droppedBy") then
                droppedBy = v
            elseif (k == "lootspec") then
                lootspec = v
            end
        end

        if (zoneFilter ~= nil and zoneFilter ~= zone) then
        elseif (expacFilter ~= nil and expacFilter ~= expac) then
        elseif (bossFilter ~= nil and bossFilter ~= droppedBy) then
        elseif (specFilter ~= nil and specFilter ~= lootspec) then
        else
            LL:log(logLoot(i, link, tert, sockets))
        end
    end
end

local function resetLoots(index, count, zoneFilter, expacFilter, bossFilter, specFilter)
    local lootTable = LootLogSavedVars or {}
    local lastIndex = math.min(index + count - 1, #lootTable)
    index = math.max(index, 1)

    logQuery("Resetting", index, lastIndex, zoneFilter, expacFilter, bossFilter, specFilter)

    local updatedLoots = {}
    for i = 1, #lootTable do
        local zone = ""
        local expac = ""
        local droppedBy = ""
        local lootspec = ""

        for k,v in pairs(lootTable[i]) do
            if (k == "zone") then
                zone = v
            elseif (k == "expac") then
                expac = v
            elseif (k == "droppedBy") then
                droppedBy = v
            elseif (k == "lootspec") then
                lootspec = v
            end
        end

        if (i >= index and i <= lastIndex) then
            if (zoneFilter ~= nil and zoneFilter ~= zone) then
                updatedLoots[#updatedLoots + 1] = lootTable[i]
            elseif (expacFilter ~= nil and expacFilter ~= expac) then
                updatedLoots[#updatedLoots + 1] = lootTable[i]
            elseif (bossFilter ~= nil and bossFilter ~= droppedBy) then
                updatedLoots[#updatedLoots + 1] = lootTable[i]
            elseif (specFilter ~= nil and specFilter ~= lootspec) then
                updatedLoots[#updatedLoots + 1] = lootTable[i]
            end
        else
            updatedLoots[#updatedLoots + 1] = lootTable[i]
        end
    end
    LootLogSavedVars = updatedLoots
end

local function itemStats(index)
    local lootTable = LootLogSavedVars or {}
    local itemName = ""
    for k,v in pairs(lootTable[index]) do
        if (k == "name") then
            itemName = v
        end
    end

    LL:log("["..NAME.."] Stats for loot: "..itemName)

    local countTable = {} -- key is (rarity, tert, sockets) value is count 
    local textTable = {} -- key is (rarity, tert, sockets) value is text
    local maxCount = 0
    local totalCount = 0

    for i = 1, #lootTable do
        local name = ""
        local link = ""
        local rarity = ""
        local tert = "None"
        local sockets = 0

        for k,v in pairs(lootTable[i]) do
            if (k == "name") then
                name = v
            elseif (k == "link") then
                link = v
            elseif (k == "rarity") then
                rarity = v
            elseif (k == "tert") then
                tert = v
            elseif (k == "sockets") then
                sockets = v
            end
        end

        if (name == itemName) then
            local combo = rarity..tert..sockets
            if (countTable[combo] == nil) then
                countTable[combo] = 1
                textTable[combo] = link..lootSuffix(tert, sockets)
                if (maxCount < 1) then
                    maxCount = 1
                end
            else
                local count = countTable[combo] + 1
                countTable[combo] = count
                if (count > maxCount) then
                    maxCount = count
                end
            end
            totalCount = totalCount + 1
        end
    end

    for i = maxCount, 1, -1 do
        for combo, count in pairs(countTable) do
            if (count == i) then
                local prefix = getCountAndPercent(i, totalCount)
                local text = textTable[combo]
                LL:log(prefix.." "..text)
            end
        end
    end
end

local function lootStats(index, count, zoneFilter, expacFilter, bossFilter, specFilter)
    local numDrops = 0
    local numUpgrades = 0
    local numDoubleUpgrades = 0
    local numTripleUpgrades = 0
    local numEpicUpgrades = 0
    local numTertUpgrades = 0
    local numSocketUpgrades = 0
    local numCanProcSocketUpgrade = 0
    local numDidProcSocketUpgrade = 0
    local numEpicSocketUpgrades = 0
    local numEpicTertUpgrades = 0

    local upgradeStreak = 0
    local noUpgradeStreak = 0
    local longestUpgradeStreak = 0
    local longestNoUpgradeStreak = 0

    local lootTable = LootLogSavedVars or {}
    local lastIndex = math.min(index + count - 1, #lootTable)
    index = math.max(index, 1)

    logQuery("Stats for", index, lastIndex, zoneFilter, expacFilter, bossFilter, specFilter)

    for i = 1, #lootTable do
        if (i >= index and i <= lastIndex) then
            local rarity = ""
            local tert = "None"
            local sockets = 0
            local zone = ""
            local expac = ""
            local slot = ""
            local droppedBy = ""
            local lootspec = ""
    
            for k,v in pairs(lootTable[i]) do
                if (k == "rarity") then
                    rarity = v
                elseif (k == "tert") then
                    tert = v
                elseif (k == "sockets") then
                    sockets = v
                elseif (k == "zone") then
                    zone = v
                elseif (k == "expac") then
                    expac = v
                elseif (k == "slot") then
                    slot = v
                elseif (k == "droppedBy") then
                    droppedBy = v
                elseif (k == "lootspec") then
                    lootspec = v
                end
            end

            if (zoneFilter ~= nil and zoneFilter ~= zone) then
            elseif (expacFilter ~= nil and expacFilter ~= expac) then
            elseif (bossFilter ~= nil and bossFilter ~= droppedBy) then
            elseif (specFilter ~= nil and specFilter ~= lootspec) then
            else
                numDrops = numDrops + 1

                local canProcSocket = false
                if (slot == "INVTYPE_FINGER" or slot == "INVTYPE_HEAD" or slot == "INVTYPE_NECK" or slot == "INVTYPE_WAIST" or slot == "INVTYPE_WRIST") then
                    canProcSocket = true
                    numCanProcSocketUpgrade = numCanProcSocketUpgrade + 1
                    if (sockets > 0) then
                        numDidProcSocketUpgrade = numDidProcSocketUpgrade + 1
                    end
                end
        
                local upgradeCount = 0
                if (rarity == "Epic") then
                    if (sockets > 0) then
                        numEpicSocketUpgrades = numEpicSocketUpgrades + 1
                    end
                    if (tert ~= "None") then
                        numEpicTertUpgrades = numEpicTertUpgrades + 1
                    end
                    numEpicUpgrades = numEpicUpgrades + 1
                    upgradeCount = upgradeCount + 1
                end
                if (tert ~= "None") then
                    numTertUpgrades = numTertUpgrades + 1
                    upgradeCount = upgradeCount + 1
                end
                if (sockets > 0) then
                    numSocketUpgrades = numSocketUpgrades + 1
                    upgradeCount = upgradeCount + 1
                end

                if (upgradeCount > 0) then
                    numUpgrades = numUpgrades + 1
                    upgradeStreak = upgradeStreak + 1
                    noUpgradeStreak = 0
                else
                    noUpgradeStreak = noUpgradeStreak + 1
                    upgradeStreak = 0
                end

                if (upgradeStreak > longestUpgradeStreak) then
                    longestUpgradeStreak = upgradeStreak
                end
                if (noUpgradeStreak > longestNoUpgradeStreak) then
                    longestNoUpgradeStreak = noUpgradeStreak
                end

                if (upgradeCount > 1) then
                    numDoubleUpgrades = numDoubleUpgrades + 1
                end
                if (upgradeCount > 2) then
                    numTripleUpgrades = numTripleUpgrades + 1
                end    
            end
        end
    end

    if (numDrops == 0) then
        LL:log("No matching loots")
    else
        LL:log("Number of loots: "..numDrops.." ("..numCanProcSocketUpgrade.." socket proc eligible)")
        LL:log("Single upgrades: "..getCountAndPercent(numUpgrades, numDrops))
        LL:log("Double upgrades: "..getCountAndPercent(numDoubleUpgrades, numDrops))
        LL:log("Triple upgrades: "..getCountAndPercent(numTripleUpgrades, numDrops, numCanProcSocketUpgrade))
        LL:log("Epic upgrades: "..getCountAndPercent(numEpicUpgrades, numDrops))
        LL:log("Tert upgrades: "..getCountAndPercent(numTertUpgrades, numDrops))
        LL:log("Epic tert upgrades: "..getCountAndPercent(numEpicTertUpgrades, numDrops))
        LL:log("Socket upgrades: "..getCountAndPercent(numSocketUpgrades, numDrops, numCanProcSocketUpgrade))
        LL:log("Epic socket upgrades: "..getCountAndPercent(numEpicSocketUpgrades, numDrops, numCanProcSocketUpgrade))
        LL:log("Longest upgrade streak: "..longestUpgradeStreak)
        LL:log("Longest no-upgrade streak: "..longestNoUpgradeStreak)
    end
end

local function getNumRange(args)
    local indexStr = nil
    local lastIndexStr = nil
    local index = nil
    local count = nil
    local arg, args = args:match("%s*(%S+)(.*)")
    while (arg ~= nil) do
        local indexStr, lastIndexStr = arg:match("(%d+)-(%d+)")
        if (indexStr == nil) then
            indexStr = arg:match("(%d+)")
            lastIndexStr = indexStr
        end

        if (indexStr ~= nil and lastIndexStr ~= nil) then
            index = tonumber(indexStr)
            count = tonumber(lastIndexStr) - index + 1
        end
        
        arg, args = args:match("%s*(%S+)(.*)")
    end

    return index, count
end

local function getExpacID(instanceID)
    local expacID = nil
    if (instanceID == 0 or instanceID == 1) then
        expacID = 0
    elseif (instanceID == 530) then
        expacID = 1
    elseif (instanceID == 571) then
        expacID = 2
    elseif (instanceID == 646 or instanceID == 730 or instanceID == 732) then
        expacID = 3
    elseif (instanceID == 860 or instanceID == 870 or instanceID == 1064) then
        expacID = 4
    elseif (instanceID == 1116 or instanceID == 1152 or instanceID == 1158 or instanceID == 1191 or instanceID == 1330 or instanceID == 1464) then
        expacID = 5
    elseif (instanceID == 1220 or instanceID == 1669) then
        expacID = 6
    elseif (instanceID == 1642 or instanceID == 1643 or instanceID == 1718) then
        expacID = 7
    elseif (instanceID == 2222 or instanceID == 2374) then
        expacID = 8
    elseif (instanceId == 2444) then
        expacID = 9
    end
    return expacID
end

local function getExpacName(expacID)
    local expacName = tostring(expacID)
    if (expacID == 0) then
        expacName = "Classic"
    elseif (expacID == 1) then
        expacName = "TBC"
    elseif (expacID == 2) then
        expacName = "Wrath"
    elseif (expacID == 3) then
        expacName = "Cata"
    elseif (expacID == 4) then
        expacName = "MoP"
    elseif (expacID == 5) then
        expacName = "WoD"
    elseif (expacID == 6) then
        expacName = "Legion"
    elseif (expacID == 7) then
        expacName = "BfA"
    elseif (expacID == 8) then
        expacName = "Shadowlands"
    elseif (expacID == 9) then
        expacName = "Dragonflight"
    end
    return expacName
end

local function getLootSpec()
    local _, lootspecName = GetSpecializationInfoByID(GetLootSpecialization())
    if (C_Loot.IsLegacyLootModeEnabled() == true) then
        lootspecName = "Legacy"
    end
    if (lootspecName == nil) then
        local currentSpec = GetSpecialization()
        if (currentSpec ~= nil) then
            _, lootspecName = GetSpecializationInfo(currentSpec)
        end
    end
    return lootspecName
end

local function getFilters(args)
    -- parse filters from args
    local zoneFilter = nil
    local expacFilter = nil
    local bossFilter = nil
    local specFilter = nil
    local lootTable = LootLogSavedVars or {}
    local zoneName, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    if (args == nil) then
        args = ""
    end
    local arg, args = args:match("%s*(%S+)(.*)")
    while (arg ~= nil) do
        if (arg == "zone") then
            zoneFilter = zoneName
        elseif (arg == "expac" or arg == "xpac") then
            local expacID = getExpacID(instanceID)
            if (expacID ~= nil) then
                expacFilter = getExpacName(expacID)
            end
            if (expacFilter == nil) then
                -- find a drop in my zone to lookup expac
                for k,v in pairs(lootTable) do
                    -- k is index, v is table
                    local zone = ""
                    local expac = ""
                    for k,v in pairs(v) do
                        if (k == "zone") then
                            zone = v
                        elseif (k == "expac") then
                            expac = v
                        end
                    end

                    if (zone == zoneName and expac ~= "") then
                        expacFilter = expac
                        break
                    end
                end

                if (expacFilter == nil) then
                    LL:log("["..NAME.."] Failed to lookup expac based on current zone: "..instanceID)
                    expacFilter = ""
                end
            end
        elseif (arg == "boss") then
            local targetName = GetUnitName("target")
            if (targetName == nil) then
                LL:log("["..NAME.."] Must have a target to use boss filter!")
                bossFilter = ""
            else
                bossFilter = targetName
            end
        elseif (arg == "spec")  then
            specFilter = getLootSpec()
        end
        arg, args = args:match("%s*(%S+)(.*)")
    end

    return zoneFilter, expacFilter, bossFilter, specFilter
end

SLASH_LOOTLOG1 = "/lootlog"
SLASH_LOOTLOG2 = "/ll"
function SlashCmdList.LOOTLOG(msg)
    local cmd, args = msg:match("%s*(%S+)(.*)")
    local zoneFilter, expacFilter, bossFilter, specFilter = getFilters(args)
    local lootTable = LootLogSavedVars or {}

    if (cmd == "list") then
        local index, count = getNumRange(args)

        -- Default number of loots when range not specified
        if (index == nil or count == nil) then
            if (zoneFilter == nil and expacFilter == nil and bossFilter == nil and specFilter == nil) then
                count = 10 -- No filters defined
            else
                count = 100 -- Filters defined
            end
            index = math.max(#lootTable - count + 1, 1)
        end

        logLoots(index, count, zoneFilter, expacFilter, bossFilter, specFilter)
    elseif (cmd == "reset") then
        local index, count = getNumRange(args)

        -- Default to all loots
        if (index == nil or count == nil) then
            LL:log("["..NAME.."] Must define a range for reset")
        else
            resetLoots(index, count, zoneFilter, expacFilter, bossFilter, specFilter)
        end
    elseif (cmd == "stats" or cmd == "stat") then
        local index, count = getNumRange(args)

        -- Default to all loots
        if (index == nil or count == nil) then
            index = 1
            count = #lootTable
        end

        if (count == 1) then
            itemStats(index)
        else
            lootStats(index, count, zoneFilter, expacFilter, bossFilter, specFilter)
        end
    elseif (cmd ~= nil)then
        LL:log("["..NAME.."] Unsupported command: "..cmd)
        usage()
    else
        usage()
    end
end

-- Avoid adding the drop twice if inventory is full
S.LastDropGuid = ""

function LL:LOOT_OPENED(event, msg)
    local lootTable = LootLogSavedVars or {}
    local numLootItems = GetNumLootItems()
    local targetGuid = UnitGUID("target")

    for i = 1, numLootItems do
        local itemLink = GetLootSlotLink(i)

        if itemLink then
            local itemName, itemLink, itemQuality, _, _, itemType, _, _, itemEquipLoc, _, _, _, _, _, expacId = GetItemInfo(itemLink)

            if (itemQuality ~= nil and itemQuality >= 3 and itemQuality <= 5 and (itemType == "Armor" or itemType == "Weapon") and targetGuid ~= S.LastDropGuid) then
                local itemStats = GetItemStats(itemLink)           

                local numSockets = 0
                local socketStat = itemStats["EMPTY_SOCKET_PRISMATIC"]
                if socketStat and socketStat > 0 then
                    numSockets = socketStat
                end

                local tertiaryStat = "None"
                if itemStats["ITEM_MOD_CR_SPEED_SHORT"] then
                    tertiaryStat = "Speed"
                elseif itemStats["ITEM_MOD_CR_LIFESTEAL_SHORT"] then
                    tertiaryStat = "Leech"
                elseif itemStats["ITEM_MOD_CR_AVOIDANCE_SHORT"] then
                    tertiaryStat = "Avoidance"
                elseif itemStats["ITEM_MOD_CR_STURDINESS_SHORT"] then
                    tertiaryStat = "Indestructible"
                end

                local itemRarity = ""
                if (itemQuality == 3) then
                    itemRarity = "Rare"
                elseif (itemQuality == 4) then
                    itemRarity = "Epic"
                elseif (itemQuality == 5) then
                    itemRarity = "Legendary"
                end

                local expacName = getExpacName(expacId)

                S.LastDropGuid = targetGuid

                -- append to loot table
                lootTable[#lootTable + 1] = {
                    name = itemName,
                    link = itemLink,
                    slot = itemEquipLoc,
                    rarity = itemRarity,
                    sockets = numSockets,
                    tert = tertiaryStat,
                    timestamp = time(),
                    zone = GetInstanceInfo(),
                    expac = expacName,
                    droppedBy = GetUnitName("target"),
                    lootspec = getLootSpec()
                }

                -- item stats
                local numTimesLooted = 0
                local numTimesLootedVariation = 0

                for k,v in pairs(lootTable) do
                    -- k is index, v is table
                    local name = ""
                    local sockets = 0
                    local tert = ""
                    local rarity = ""

                    for k,v in pairs(v) do
                        if (k == "name") then
                            name = v
                        elseif (k == "sockets") then
                            sockets = v
                        elseif (k == "tert") then
                            tert = v
                        elseif (k == "rarity") then
                            rarity = v
                        end
                    end

                    if (name == itemName) then
                        numTimesLooted = numTimesLooted + 1
                        if (sockets == numSockets and tert == tertiaryStat and rarity == itemRarity) then
                            numTimesLootedVariation = numTimesLootedVariation + 1
                        end
                    end
                end

                -- Build one message to output
                local text = "["..NAME.."] "..logLoot(#lootTable, itemLink, tertiaryStat, numSockets)

                if (numTimesLooted == 1) then
                    text = text..". This is the first time I have looted this item."
                else
                    text = text..". I have looted this item "..numTimesLooted.." times"
                    if (numTimesLooted ~= numTimesLootedVariation) then
                        local percent = getPercent(numTimesLootedVariation, numTimesLooted)
                        if (numTimesLootedVariation == 1) then
                            text = text.." and this is the first time I have looted this variation ("..percent.."% of the time)."
                        else
                            text = text.." and this variation "..numTimesLootedVariation.." times ("..percent.."% of the time)."
                        end
                    else
                        text = text.."."
                    end
                end

                LL:Pour(text)
            end
        end
    end

    LootLogSavedVars = lootTable
end
