local ESX = nil

TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)

local allowedGroups = {}
for group in string.gmatch(WariGiveMenu.Groups, '([^, ]+)') do
    table.insert(allowedGroups, group)
end

local function hasPermission(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    local playerGroup = xPlayer.getGroup()

    for _, allowedGroup in ipairs(allowedGroups) do
        if playerGroup == allowedGroup then
            return true
        end
    end

    return false
end

lib.addCommand('givemenu', {
    help = WariGiveMenu.Lang.command_description,    
}, function(source)
    if hasPermission(source) then
        TriggerClientEvent('givemenu:open', source)
    else
        lib.notify(source, {
            description = WariGiveMenu.Lang.no_permission,
            type = 'error',
            duration = 5000
        })
    end
end)

lib.callback.register('givemenu:getItems', function(source)
    local items = {}
    
    for itemName, itemData in pairs(exports.ox_inventory:Items()) do
        if not itemName:match('^test_') and not itemName:match('^debug_') then
            table.insert(items, {
                name = itemName,
                label = itemData.label,
                description = itemData.description
            })
        end
    end
    
    return items
end)

lib.callback.register('givemenu:giveItem', function(source, targetId, itemName, count)
    local maxCount = tonumber(WariGiveMenu.CountLimit) or 500
    
    if count > maxCount then
        lib.notify(source, {
            description = WariGiveMenu.Lang.limit_error:format(maxCount),
            type = 'error',
            duration = 5000
        })
        return false, WariGiveMenu.Lang.limit_error:format(maxCount)
    end

    if targetId == source and not WariGiveMenu.SelfGive then
        lib.notify(source, {
            description = WariGiveMenu.Lang.self_give_error,
            type = 'error',
            duration = 5000
        })
        return false
    end

    local targetPlayerName = GetPlayerName(targetId)
    if not targetPlayerName then
        lib.notify(source, {
            description = WariGiveMenu.Lang.player_offline,
            type = 'error',
            duration = 5000
        })
        return false, WariGiveMenu.Lang.player_offline
    end

    local itemData = exports.ox_inventory:Items(itemName)
    if not itemData then
        lib.notify(source, {
            description = WariGiveMenu.Lang.invalid_item,
            type = 'error',
            duration = 5000
        })
        return false, WariGiveMenu.Lang.invalid_item
    end

    local adminName = GetPlayerName(source)

    for blacklistedItem in string.gmatch(WariGiveMenu.BlacklistedItems, '([^, ]+)') do
        if blacklistedItem == itemName then
            lib.notify(source, {
                description = WariGiveMenu.Lang.invalid_item,
                type = 'error',
                duration = 5000
            })
            return false, WariGiveMenu.Lang.invalid_item
        end
    end

    local success = exports.ox_inventory:AddItem(targetId, itemName, count or 1)

    if success then
        lib.notify(source, {
            description = WariGiveMenu.Lang.admin_info:format(count, itemData.label, targetPlayerName),
            type = 'success',
            duration = 5000
        })
    
        lib.notify(targetId, {
            description = WariGiveMenu.Lang.player_info:format(adminName, count, itemData.label),
            type = 'success',
            duration = 9000
        })
    
        if WariGiveMenu.Logs and WariGiveMenu.Logs ~= "" then
            PerformHttpRequest(WariGiveMenu.Logs, function(err, text, headers) end, 'POST', json.encode({
                username = "GiveMenu Logs",
                embeds = {{
                    title = WariGiveMenu.Lang.log_title,
                    color = 16753920,
                    fields = {
                        { 
                            name = WariGiveMenu.Lang.log_admin, 
                            value = string.format("%s (`%s`)", adminName, source), 
                            inline = true 
                        },
                        { 
                            name = WariGiveMenu.Lang.log_player, 
                            value = string.format("%s (`%s`)", targetPlayerName, targetId), 
                            inline = false 
                        },
                        { 
                            name = WariGiveMenu.Lang.log_item, 
                            value = string.format("%s (`%s`)", itemData.label, itemName), 
                            inline = true 
                        },
                        { 
                            name = WariGiveMenu.Lang.log_count, 
                            value = tostring(count), 
                            inline = true 
                        }
                    },
                    footer = { text = "Wari • GiveMenu" },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            }), { ['Content-Type'] = 'application/json' })
        end
    
        return true
    else
        lib.notify(source, {
            description = WariGiveMenu.Lang.full_inventory,
            type = 'error',
            duration = 5000
        })
        return false
    end
end)