local frame = CreateFrame("FRAME")
frame:RegisterEvent("LOOT_OPENED")

local function eventHandler(self, event, ...)
    local lootTable = LootLogSavedVars or {}
    local numLootItems = GetNumLootItems()

    for i = 1, numLootItems do
        local itemLink = GetLootSlotLink(i)

        if itemLink then
            local itemName, itemLink, itemQuality, _, _, itemType = GetItemInfo(itemLink)

            if (itemQuality >= 2 and (itemType == "Armor" or itemType == "Weapon")) then
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

                local itemRarity = tostring(itemQuality)
                if (itemQuality == 2) then
                    itemRarity = "Uncommon"
                elseif (itemQuality == 3) then
                    itemRarity = "Rare"
                elseif (itemQuality == 4) then
                    itemRarity = "Epic"
                elseif (itemQuality == 5) then
                    itemRarity = "Legendary"
                end

                print("Looted "..itemName.." ("..itemRarity.." / "..tertiaryStat.." / "..numSockets..")")

                local itemUpgraded = false
                if (numSockets > 0 or tertiaryStat ~= "None" or itemRarity == "Epic") then
                    itemUpgraded = true
                end

                local numTimesLooted = 0
                local numTimesLootedVariation = 0
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

                    -- overall stats
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

                print("You have looted this item "..numTimesLooted.." times before")

                if (numTimesLooted > 0) then
                    if (numTimesLooted ~= numTimesLootedVariation) then
                        print("You have looted this variation "..numTimesLootedVariation.." times before")
                        local percent = math.floor((numTimesLootedVariation + 1) * 10000 / (numTimesLooted + 1)) / 100
                        print("This variation has appeared "..percent.."% of the time")
                    end
                end

                lastUpgrade = lastUpgrade + 1
                lastEpic = lastEpic + 1
                lastTert = lastTert + 1
                lastSocket = lastSocket + 1

                print("Last upgrade was "..lastUpgrade.." loots ago (Epic: "..lastEpic.." Tert: "..lastTert.." Socket: "..lastSocket..")")

                lootTable[#lootTable + 1] = {
                    name = itemName,
                    link = itemLink,
                    rarity = itemRarity,
                    sockets = numSockets,
                    tert = tertiaryStat,
                    timestamp = time(),
                }
            end
        end
    end

    LootLogSavedVars = lootTable
end

frame:SetScript("OnEvent", eventHandler)
