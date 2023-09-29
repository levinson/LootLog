local NAME, S = ...
S.VERSION = GetAddOnMetadata(NAME, "Version")
S.BUILD = "Release"

LootLog = LibStub("AceAddon-3.0"):NewAddon(NAME, "AceEvent-3.0", "LibSink-2.0")
local LL = LootLog

function usage()
    LL:Pour("[LootLog] Usage:")
    LL:Pour("/lootlog list [zone||expac] [#-#]")
    LL:Pour("/lootlog stats [zone||expac] [#-#]")
    LL:Pour("/lootlog reset [zone||expac] #-#")
    LL:Pour("")
    LL:Pour("Examples:")
    LL:Pour("/ll list")
    LL:Pour("/lootlog list zone 1-100")
    LL:Pour("/lootlog stats expac")
    LL:Pour("/lootlog reset 42")
end

function logLoot(index, link, tert, sockets)
    local upgrades = {}
    if (tert ~= "None") then
        upgrades[#upgrades + 1] = tert
    end
    if (sockets > 0) then
        upgrades[#upgrades + 1] = "Sockets: "..sockets
    end
    local prefix = "Loot #"..index.." "..link
    if (#upgrades > 0) then
        return prefix.." ("..table.concat(upgrades, " / ")..")"
    else
        return prefix
    end
end

function logQuery(prefix, index, lastIndex, zoneFilter, expacFilter)
    local msg = "[LootLog] "..prefix
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
    if (#filters > 0) then
        LL:Pour(msg.." where "..table.concat(filters, " and "))
    else
        LL:Pour(msg)
    end
end

function logLoots(index, count, zoneFilter, expacFilter)
    local lootTable = LootLogSavedVars or {}
    local lastIndex = math.min(index + count - 1, #lootTable)
    index = math.max(index, 1)

    logQuery("Listing", index, lastIndex, zoneFilter, expacFilter)

    for i = index, lastIndex do
        local link = ""
        local tert = ""
        local sockets = 0
        local zone = ""
        local expac = ""

        for k,v in pairs(lootTable[i]) do
            if (k == "link") then
                link = v
            end
            if (k == "tert") then
                tert = v
            end
            if (k == "sockets") then
                sockets = v
            end
            if (k == "zone") then
                zone = v
            end
            if (k == "expac") then
                expac = v
            end
        end

        if (zoneFilter ~= nil and zoneFilter ~= zone) then
        elseif (expacFilter ~= nil and expacFilter ~= expac) then
        else
            LL:Pour(logLoot(i, link, tert, sockets))
        end
    end
end

function resetLoots(index, count, zoneFilter, expacFilter)
    local lootTable = LootLogSavedVars or {}
    local lastIndex = math.min(index + count - 1, #lootTable)
    index = math.max(index, 1)

    logQuery("Resetting", index, lastIndex, zoneFilter, expacFilter)

    local updatedLoots = {}
    for i = 1, #lootTable do
        local zone = ""
        local expac = ""

        for k,v in pairs(lootTable[i]) do
            if (k == "zone") then
                zone = v
            end
            if (k == "expac") then
                expac = v
            end
        end

        if (i >= index and i <= lastIndex) then
            if (zoneFilter ~= nil and zoneFilter ~= zone) then
                updatedLoots[#updatedLoots + 1] = lootTable[i]
            elseif (expacFilter ~= nil and expacFilter ~= expac) then
                updatedLoots[#updatedLoots + 1] = lootTable[i]
            end
        else
            updatedLoots[#updatedLoots + 1] = lootTable[i]
        end
    end
    LootLogSavedVars = updatedLoots
end

function lootStats(index, count, zoneFilter, expacFilter)
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

    logQuery("Stats for", index, lastIndex, zoneFilter, expacFilter)

    for i = 1, #lootTable do
        if (i >= index and i <= lastIndex) then
            local rarity = ""
            local tert = "None"
            local sockets = 0
            local zone = ""
            local expac = ""
            local slot = ""
    
            for k,v in pairs(lootTable[i]) do
                if (k == "rarity") then
                    rarity = v
                end
                if (k == "tert") then
                    tert = v
                end
                if (k == "sockets") then
                    sockets = v
                end
                if (k == "zone") then
                    zone = v
                end
                if (k == "expac") then
                    expac = v
                end
                if (k == "slot") then
                    slot = v
                end
            end

            if (zoneFilter ~= nil and zoneFilter ~= zone) then
            elseif (expacFilter ~= nil and expacFilter ~= expac) then
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
        LL:Pour("No matching loots")
    else
        LL:Pour("Number of loots: "..numDrops.." ("..numCanProcSocketUpgrade.." socket proc eligible)")
        LL:Pour("Single upgrades: "..getCountAndPercent(numUpgrades, numDrops))
        LL:Pour("Double upgrades: "..getCountAndPercent(numDoubleUpgrades, numDrops))
        LL:Pour("Triple upgrades: "..getCountAndPercent(numTripleUpgrades, numDrops, numCanProcSocketUpgrade))
        LL:Pour("Epic upgrades: "..getCountAndPercent(numEpicUpgrades, numDrops))
        LL:Pour("Tert upgrades: "..getCountAndPercent(numTertUpgrades, numDrops))
        LL:Pour("Epic tert upgrades: "..getCountAndPercent(numEpicTertUpgrades, numDrops))
        LL:Pour("Socket upgrades: "..getCountAndPercent(numSocketUpgrades, numDrops, numCanProcSocketUpgrade))
        LL:Pour("Epic socket upgrades: "..getCountAndPercent(numEpicSocketUpgrades, numDrops, numCanProcSocketUpgrade))
        LL:Pour("Longest upgrade streak: "..longestUpgradeStreak)
        LL:Pour("Longest no-upgrade streak: "..longestNoUpgradeStreak)
    end
end

function getNumRange(args)
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

function getExpacID(instanceID)
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

function getExpacName(expacID)
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

function getFilters(args)
    -- parse filters from args
    local zoneFilter = nil
    local expacFilter = nil
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
                    LL:Pour("[LootLog] Failed to lookup expac based on current zone: "..instanceID)
                    expacFilter = ""
                end
            end
        end
        arg, args = args:match("%s*(%S+)(.*)")
    end

    return zoneFilter, expacFilter
end

function getPercent(count, total)
    return math.floor(count * 10000 / total) / 100
end

function getCountAndPercent(count, total, numEligible)
    if (numEligible == nil) then
        return count.." ("..getPercent(count, total).."%)"
    else
        return count.." ("..getPercent(count, total).."% of total or "..getPercent(count, numEligible).."% of eligible)"
    end
end

SLASH_LOOTLOG1 = "/lootlog"
SLASH_LOOTLOG2 = "/ll"
function SlashCmdList.LOOTLOG(msg)
    local cmd, args = msg:match("%s*(%S+)(.*)")
    local zoneFilter, expacFilter = getFilters(args)
    local lootTable = LootLogSavedVars or {}

    if (cmd == "list") then
        local index, count = getNumRange(args)

        -- Default to last 10 loots
        if (index == nil or count == nil) then
            index = math.max(#lootTable - 9, 1)
            count = 10
        end

        logLoots(index, count, zoneFilter, expacFilter)
    elseif (cmd == "reset") then
        local index, count = getNumRange(args)

        -- Default to all loots
        if (index == nil or count == nil) then
            LL:Pour("[LootLog] Must define a range for reset")
        else
            resetLoots(index, count, zoneFilter, expacFilter)
        end
    elseif (cmd == "stats" or cmd == "stat") then
        local index, count = getNumRange(args)

        -- Default to all loots
        if (index == nil or count == nil) then
            index = 1
            count = #lootTable
        end

        lootStats(index, count, zoneFilter, expacFilter)
    elseif (cmd ~= nil)then
        LL:Pour("[LootLog] Unsupported command: "..cmd)
        usage()
    else
        usage()
    end
end

-- global to avoid adding the drop twice if inventory is full
lootLogLastDropGuid = ""

function LL:LOOT_OPENED(event, msg)
    local lootTable = LootLogSavedVars or {}
    local numLootItems = GetNumLootItems()
    local targetGuid = UnitGUID("target")
    local targetName = GetUnitName("target") 
    local _, lootspecName = GetSpecializationInfoByID(GetLootSpecialization())
    if (C_Loot.IsLegacyLootModeEnabled() == true) then
        lootspecName = "Legacy"
    end

    for i = 1, numLootItems do
        local itemLink = GetLootSlotLink(i)

        if itemLink then
            local itemName, itemLink, itemQuality, _, _, itemType, _, _, itemEquipLoc, _, _, _, _, _, expacId = GetItemInfo(itemLink)

            if (itemQuality ~= nil and itemQuality >= 3 and itemQuality <= 5 and (itemType == "Armor" or itemType == "Weapon") and targetGuid ~= lootLogLastDropGuid) then
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

                lootLogLastDropGuid = targetGuid

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
                    droppedBy = targetName,
                    lootspec = lootspecName
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
                        end
                        if (k == "sockets") then
                            sockets = v
                        end
                        if (k == "tert") then
                            tert = v
                        end
                        if (k == "rarity") then
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
                local text = "[LootLog] "..logLoot(#lootTable, itemLink, tertiaryStat, numSockets)

                if (numTimesLooted == 1) then
                    text = text..". This is the first time I have looted this item."
                else
                    text = text..". I have looted this item "..numTimesLooted.." times"
                end

                if (numTimesLooted > 1) then
                    if (numTimesLooted ~= numTimesLootedVariation) then
                        local percent = getPercent(numTimesLootedVariation, numTimesLooted)
                        if (numTimesLootedVariation == 1) then
                            text = text.." and this is the first time I have looted this variation ("..percent.."% of the time)."
                        else
                            text = text.." and this variation "..numTimesLootedVariation.." times ("..percent.."% of the time)."
                        end
                    end
                else
                    text = text.."."
                end

                LL:Pour(text)
            end
        end
    end

    LootLogSavedVars = lootTable
end
