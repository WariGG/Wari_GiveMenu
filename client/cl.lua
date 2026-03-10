local cachedItems = lib.callback.await('givemenu:getItems', false)

local function prepareItemList(items)
    local filteredItems = {}
    
    for _, item in pairs(items) do
        local isBlacklisted = false
        
        for blacklistedItem in string.gmatch(WariGiveMenu.BlacklistedItems, '([^, ]+)') do
            if blacklistedItem == item.name then
                isBlacklisted = true
                break
            end
        end
        
        if not isBlacklisted then
            table.insert(filteredItems, {
                value = item.name,
                label = string.format('%s (%s)', item.label, item.name),
                searchText = string.format('%s %s %s', 
                    item.label or '', 
                    item.name, 
                    item.description or ''
                ):lower()
            })
        end
    end
    
    table.sort(filteredItems, function(a, b)
        return a.label < b.label
    end)
    
    return filteredItems
end

local itemList = prepareItemList(cachedItems)

local function searchItems(query)
    if not query or query == '' then
        return itemList
    end

    local searchQuery = query:lower()
    local filteredResults = {}

    for _, item in pairs(itemList) do
        if item.searchText:find(searchQuery, 1, true) then
            table.insert(filteredResults, item)
        end
    end

    table.sort(filteredResults, function(a, b)
        local aPos = a.label:lower():find(searchQuery)
        local bPos = b.label:lower():find(searchQuery)
        return aPos < bPos
    end)

    return filteredResults
end

RegisterNetEvent('givemenu:open', function()
    local maxItemCount = tonumber(WariGiveMenu.CountLimit) or 500

    local inputData = lib.inputDialog('[GiveMenu]', {
        {
            type = 'input',
            label = WariGiveMenu.Lang.player_id,
            required = true,
            pattern = '^[0-9]+$',
            placeholder = WariGiveMenu.Lang.example_id,
            icon = 'user-tag'
        },
        {
            type = 'select',
            label = WariGiveMenu.Lang.item,
            required = true,
            options = itemList,
            search = function(searchTerm)
                return searchItems(searchTerm)
            end,
            searchPlaceholder = WariGiveMenu.Lang.search_item,
            searchIgnoreCase = false,
            clearable = true,
            icon = 'magnifying-glass'
        },
        {
            type = 'number',
            label = WariGiveMenu.Lang.number,
            default = 1,
            min = 1,
            max = maxItemCount,
            required = true,
            icon = 'hashtag'
        }
    })

    if not inputData then return end

    local targetPlayerId = tonumber(inputData[1])
    local selectedItem = inputData[2]
    local itemCount = tonumber(inputData[3])

    if itemCount > maxItemCount then
        itemCount = maxItemCount
        lib.notify({
            description = WariGiveMenu.Lang.limit_error:format(maxItemCount),
            type = 'error',
            duration = 5000
        })
    end

    lib.callback.await('givemenu:giveItem', false, targetPlayerId, selectedItem, itemCount)
end)