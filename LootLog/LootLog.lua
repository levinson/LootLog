local frame = CreateFrame("FRAME")
frame:RegisterEvent("LOOT_OPENED")

local function eventHandler(self, event, ...)
    local lootTable = LootLogSavedVars or {}
    local numLootItems = GetNumLootItems()

    for i = 1, numLootItems do
        local itemLink = GetLootSlotLink(i)

        if itemLink then
            local itemName, itemLink, itemRarity = GetItemInfo(itemLink)

            lootTable[#lootTable + 1] = {
                name = itemName,
                rarity = itemRarity,
                link = itemLink,
                timestamp = time(),
            }
        end
    end

    LootLogSavedVars = lootTable
end

frame:SetScript("OnEvent", eventHandler)
