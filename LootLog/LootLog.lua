local frame = CreateFrame("FRAME")
frame:RegisterEvent("LOOT_OPENED")

local function eventHandler(self, event, ...)
    local lootTable = LootLogSavedVars or {}
    local numLootItems = GetNumLootItems()

    for i = 1, numLootItems do
        local itemLink = GetLootSlotLink(i)

        if itemLink then
            local itemName, itemLink, itemRarity = GetItemInfo(itemLink)
            local itemStats = GetItemStats(itemLink)           

            local hasSocket = "No"
            if itemStats["EMPTY_SOCKET_PRISMATIC"] then
                hasSocket = "Yes"
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

            print("Looted "..itemName.." (Socket: "..hasSocket.." / Tert: "..tertiaryStat..")")

            lootTable[#lootTable + 1] = {
                name = itemName,
                rarity = itemRarity,
                link = itemLink,
                socket = hasSocket,
                tert = tertiaryStat,
                timestamp = time(),
            }
        end
    end

    LootLogSavedVars = lootTable
end

frame:SetScript("OnEvent", eventHandler)
