function printLoot(index, link, tert, sockets)
    local upgrades = {}
    if (tert ~= "None") then
        upgrades[#upgrades + 1] = tert
    end
    if (sockets > 0) then
        upgrades[#upgrades + 1] = "Sockets: "..sockets
    end
    local prefix = "Loot #"..index.." "..link
    if (#upgrades > 0) then
        print(prefix.." ("..table.concat(upgrades, " / ")..")")
    else
        print(prefix)
    end
end

function printLoots(index, count, zoneFilter, expacFilter)
    local lootTable = LootLogSavedVars or {}
    local lastIndex = math.min(index + count, #lootTable)
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
            printLoot(i, link, tert, sockets)
        end
    end
end

function getNumRange(arg)
    local lootTable = LootLogSavedVars or {}
    -- default to last 100 elements
    local index = math.max(#lootTable - 100, 1)
    local count = 100
    
    -- default to last 100 elements
    if (arg == nil) then
        return index, count
    end

    local index, lastIndex = arg:match("(%d+)-(%d+)")
    if (index == nil) then
        index = arg:match("(%d+)")
        lastIndex = index
    end

    if (index == nil or lastIndex == nil) then
        print("Failed to parse range: "..arg)
        return index, count
    else
        local start = tonumber(index)
        local count = tonumber(lastIndex) - start
        return start, count
    end
end

SLASH_LOOTLOG1 = "/lootlog"
function SlashCmdList.LOOTLOG(msg)
    -- parse command line
    local arg1, arg2, arg3
    arg1, arg2, arg3 = msg:match("%s*(%S+)%s+(%S+)%s+(%S+)%s*")
    if (arg1 == nil) then
        arg1, arg2 = msg:match("%s*(%S+)%s+(%S+)%s*")
    end
    if (arg1 == nil) then
        arg1 = msg:match("%s*(%S+)%s*")
    end

    local lootTable = LootLogSavedVars or {}

    if (arg1 ~= nil) then
        if (arg1 == "list") then
            if (arg2 == nil) then
                local index, count = getNumRange(nil)
                printLoots(index, count)
            elseif (arg2 ~= nil) then
                if (arg2 == "zone") then
                    local index, count = getNumRange(arg3)
                    local zoneFilter = GetInstanceInfo()
                    printLoots(index, count, zoneFilter)
                elseif (arg2 == "expac") then
                    -- Lookup expansion by finding drop from current zone
                    local zoneFilter = GetInstanceInfo()
                    local expacFilter = nil
                    for k,v in pairs(lootTable) do
                        -- k is index, v is table
                        local zone = ""
                        local expac = ""
                        for k,v in pairs(v) do
                            if (k == "zone") then
                                zone = v
                            end
                            if (k == "expac") then
                                expac = v
                            end
                        end

                        if (zone == zoneFilter and expac ~= "") then
                            expacFilter = expac
                            break
                        end
                    end

                    if (expacFilter ~= nil) then
                        local index, count = getNumRange(arg3)
                        printLoots(index, count, nil, expacFilter)
                    else
                        print("Failed to lookup expac based on current zone")
                    end
                else
                    local index, count = getNumRange(arg2)
                    printLoots(index, count)
                end
            end
        elseif (arg1 == "reset") then
            if (arg2 == nil) then
                LootLogSavedVars = {}
            else
                usage()
            end
        else
            usage()
        end
    else        
        usage()
    end
end

function usage()
    print("LootLog usage:")
    print("/lootlog list [zone|expac] [#[-#]]")
    print("/lootlog reset")
    print("")
    print("Examples:")
    print("/lootlog list")
    print("/lootlog list expac 1-100")
    print("/lootlog reset")
end

local frame = CreateFrame("FRAME")
frame:RegisterEvent("LOOT_OPENED")

local function eventHandler(self, event, ...)
    local lootTable = LootLogSavedVars or {}
    local numLootItems = GetNumLootItems()

    for i = 1, numLootItems do
        local itemLink = GetLootSlotLink(i)

        if itemLink then
            local itemName, itemLink, itemQuality, _, _, itemType, _, _, itemEquipLoc, _, _, _, _, _, expacId = GetItemInfo(itemLink)

            if (itemQuality >= 3 and itemQuality <= 5 and (itemType == "Armor" or itemType == "Weapon")) then
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

                local expansion = tostring(expacId)
                if (expacId == 0) then
                    expansion = "Classic"
                elseif (expacId == 1) then
                    expansion = "TBC"
                elseif (expacId == 2) then
                    expansion = "Wrath"
                elseif (expacId == 3) then
                    expansion = "Cata"
                elseif (expacId == 4) then
                    expansion = "MoP"
                elseif (expacId == 5) then
                    expansion = "WoD"
                elseif (expacId == 6) then
                    expansion = "Legion"
                elseif (expacId == 7) then
                    expansion = "BfA"
                elseif (expacId == 8) then
                    expansion = "Shadowlands"
                elseif (expacId == 9) then
                    expansion = "Dragonflight"
                end

                -- item stats
                local numTimesLooted = 1
                local numTimesLootedVariation = 1
                -- overall stats
                local lastUpgrade = 0
                local lastSocket = 0
                local lastTert = 0
                local lastEpic = 0
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

                    local upgraded = false
                    if (sockets > 0 or tert ~= "None" or rarity == "Epic") then
                        upgraded = true
                    end

                    if upgraded then
                        lastUpgrade = 0
                    else
                        lastUpgrade = lastUpgrade + 1
                    end

                    if (sockets > 0) then
                        lastSocket = 0
                    else 
                        lastSocket = lastSocket + 1
                    end

                    if (tert ~= "None") then
                        lastTert = 0
                    else 
                        lastTert = lastTert + 1
                    end

                    if (rarity == "Epic") then
                        lastEpic = 0
                    else
                        lastEpic = lastEpic + 1
                    end
                end

                printLoot(#lootTable + 1, itemLink, tertiaryStat, numSockets)

                if (numTimesLooted == 1) then
                    print("This is the first time you have looted this item")
                else
                    print("You have looted this item "..numTimesLooted.." times")
                end

                if (numTimesLooted > 1) then
                    if (numTimesLooted ~= numTimesLootedVariation) then
                        if (numTimesLootedVariation == 1) then
                            print("This is the first time you have looted this variation")
                        else
                            print("You have looted this variation "..numTimesLootedVariation.." times")
                        end

                        local percent = math.floor(numTimesLootedVariation * 10000 / numTimesLooted) / 100
                        print("This variation has appeared "..percent.."% of the time")
                    end
                end

                lastUpgrade = lastUpgrade + 1
                lastEpic = lastEpic + 1
                lastTert = lastTert + 1
                lastSocket = lastSocket + 1

                print("Last upgrade was "..lastUpgrade.." loots ago (Epic: "..lastEpic.." Tert: "..lastTert.." Socket: "..lastSocket..")")

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
                    expac = expansion
                }
            end
        end
    end

    LootLogSavedVars = lootTable
end

frame:SetScript("OnEvent", eventHandler)
