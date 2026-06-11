-- ====================================================================
-- =----------------- [QBOX CASINO INSIDE TRACK CONTROL] -------------=
-- ====================================================================

-- FIX: Swapped out legacy framework callback wrapper for lib.callback.register
lib.callback.register('insidetrack:server:getbalance', function(source)
    local src = source 
    -- FIX: Directly check item amounts via ox_inventory to eliminate qb-core item checks
    local chipCount = exports.ox_inventory:GetItemCount(src, 'casinochips') or 0
    local minAmount = 100

    if chipCount >= minAmount then
        return chipCount -- Returns evaluation directly to client layer instantly
    else
        TriggerClientEvent('insidetrack:client:closeBetsNotEnough', src)
        return false
    end
end)

RegisterNetEvent("insidetrack:server:placebet", function(bet)
    local src = source 
    local chipCount = exports.ox_inventory:GetItemCount(src, 'casinochips') or 0

    if chipCount >= bet then
        -- FIX: Swapped obsolete RemoveItem wrapper for native ox_inventory export
        exports.ox_inventory:RemoveItem(src, 'casinochips', bet)
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = "You placed a "..bet.." casino chips bet"})
    else
        TriggerClientEvent('insidetrack:client:closeBetsNotEnough', src)
    end
end) 

RegisterNetEvent("insidetrack:server:winnings", function(amount)
    local src = source
    -- FIX: Standardized win payout tracking using modern item ledger functions
    local paySuccess = exports.ox_inventory:AddItem(src, 'casinochips', amount)
    
    if paySuccess then
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = "You Won "..amount.." casino chips!"})
    else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = "You have too much in your pockets"})
    end
end)
