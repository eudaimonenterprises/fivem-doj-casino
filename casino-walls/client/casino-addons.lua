-- ====================================================================
-- =------------------ [QBOX CASINO RECEPTION PACK] -----------------=
-- ====================================================================

-- Handles the 3D distance box boundaries using ox_lib spatial zones natively
local function CreateCasinoInteractions(name, zone)
    CreateThread(function()
        lib.zones.box({
            coords = zone.coords.xyz,
            size = zone.size,
            rotation = zone.coords.w,
            onEnter = function()
                lib.showTextUI('[E] - '..zone.text)
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                if IsControlJustReleased(0, 38) then
                    TriggerEvent(zone.event)
                end
            end,
            debug = false,
        })
    end)
end

-- 1. FRONT DESK MEMBERSHIP SYSTEM (Converted completely to ox_lib Context)
RegisterNetEvent("doj:casinoMembershipMenu", function()
    lib.hideTextUI()
    
    local hasMemberCard = exports.ox_inventory:GetItemCount("casino_member") >= 1
    local hasVipCard = exports.ox_inventory:GetItemCount("casino_vip") >= 1

    lib.registerContext({
        id = 'casino_membership_main',
        title = 'Diamond Casino Reception',
        options = {
            {
                title = 'Standard Membership',
                description = (hasMemberCard or hasVipCard) and 'You already possess an active membership tier.' or 'Purchase a standard casino gaming floor access card for $' .. Config.Casino.MemberCost,
                icon = 'id-card',
                disabled = (hasMemberCard or hasVipCard), -- Automatically disables if you are VIP!
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Purchase Membership?',
                        content = 'Would you like to buy a Standard Casino Membership for $' .. Config.Casino.MemberCost .. '?',
                        centered = true,
                        cancel = true
                    })
                    if confirm == 'confirm' then TriggerServerEvent('doj:server:purchaseMembership') end
                end
            },
            {
                title = 'V.I.P Membership',
                description = hasVipCard and 'You already possess an active V.I.P high-roller card.' or 'Purchase premium VIP lounge access perks for $' .. Config.Casino.VipCost,
                icon = 'crown',
                disabled = hasVipCard,
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Purchase VIP Access?',
                        content = 'Would you like to upgrade to a V.I.P Membership for $' .. Config.Casino.VipCost .. '? (Automatically includes floor access privileges)',
                        centered = true,
                        cancel = true
                    })
                    if confirm == 'confirm' then 
                        TriggerServerEvent('doj:server:purchaseVIPMembership')
                        -- FORCE SERVER EXPORT TO MINT BOTH ITEMS SIMULTANEOUSLY
                        TriggerServerEvent('doj:server:purchaseMembership') 
                    end
                end
            }
        }
    })
    lib.showContext('casino_membership_main')
end)

-- 2. CASHIER CHIP EXCHANGE SYSTEM (Converted to ox_lib Context with Input Prompts)
RegisterNetEvent("doj:casinoCashierMenu", function()
    lib.hideTextUI()
    
    if exports.ox_inventory:GetItemCount("casino_member") < 1 then
        lib.notify({ title = 'Cashier Counter', description = 'Access Denied: You must purchase a standard floor membership at reception first.', type = 'error' })
        return
    end

    lib.registerContext({
        id = 'casino_cashier_main',
        title = 'Casino Token Cashier',
        options = {
            {
                title = 'Purchase Chips',
                description = 'Exchange your cash wallet funds into playable chips. Rate: $' .. Config.Casino.ChipPrice .. ' per chip.',
                icon = 'coins',
                onSelect = function()
                    local input = lib.inputDialog('Chip Cashier Exchange', {
                        { type = 'number', label = 'Amount to Purchase', description = 'Minimum 1 token', min = 1, max = 50000, default = 10 }
                    })
                    if input and input[1] then TriggerServerEvent('doj:server:buySelectedAmount', input[1]) end
                end
            },
            {
                title = 'Sell All Chips',
                description = 'Cash out your entire chip balance back into straight dollar inventory bills.',
                icon = 'wallet',
                onSelect = function() TriggerServerEvent('doj:server:sellAllChips') end
            },
            {
                title = 'Sell Custom Amount',
                description = 'Exchange a targeted number of tokens back into cash funds.',
                icon = 'money-bill-wave',
                onSelect = function()
                    local input = lib.inputDialog('Token Sell Station', {
                        { type = 'number', label = 'Amount to Sell', description = 'Minimum 1 token', min = 1, max = 50000, default = 10 }
                    })
                    if input and input[1] then TriggerServerEvent('doj:server:sellSelectedAmount', input[1]) end
                end
            }
        }
    })
    lib.showContext('casino_cashier_main')
end)

-- 3. CASINO SOUVENIR VENDING SHOP (Converted cleanly to ox_lib layouts)
RegisterNetEvent("doj:casinoShopMenu", function()
    lib.hideTextUI()
    if exports.ox_inventory:GetItemCount("casino_member") >= 1 then
        TriggerEvent('doj:client:casinoShopCatalog')
    else
        lib.notify({ title = 'Gift Shop', description = 'Access Denied: Non-members are restricted from checking inventory catalog goods.', type = 'error' })
    end
end)

RegisterNetEvent("doj:client:casinoShopCatalog", function()
    local VendingItems = {}
    for k, v in pairs(Config.Vending) do
        local currentItemInfo = exports.ox_inventory:Items(v.Items)
        local displayLabel = currentItemInfo and currentItemInfo.label or v.Items
        
        VendingItems[#VendingItems + 1] = {
            title = displayLabel,
            icon = "nui://ox_inventory/web/images/" .. v.Items .. ".png",
            metadata = { { label = 'Price', value = '$' .. v.Price } },
            onSelect = function()
                TriggerServerEvent("doj:server:addVendingItems", v.Items, v.Price)
            end
        }
    end
    
    lib.registerContext({
        id = 'CasinoShops',
        title = 'Diamond Casino Refreshments',
        canClose = true,
        options = VendingItems,
    })
    lib.showContext('CasinoShops')
end)

-- Resource Boot listeners to bind structural boundaries to the active map layer grid space
AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end
    for name, zone in pairs(Config.CasinoInteractions) do CreateCasinoInteractions(name, zone) end
    TriggerEvent('doj:client:CreateCasinoZones')
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    for name, zone in pairs(Config.CasinoInteractions) do CreateCasinoInteractions(name, zone) end
    TriggerEvent('doj:client:CreateCasinoZones')
end)

RegisterNetEvent('doj:client:UpdateInteractSpeech', function(menu, text, time)
    -- Deprecated old speech system wrapper safely bypassed for optimization stability
end)
