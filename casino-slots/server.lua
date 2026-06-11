-- ====================================================================
-- =------------------- [QBOX CASINO SLOT CONTROL] -----------------=
-- ====================================================================
local UsedSlots = {}
local Slots = {}

local function table_matches(t1, t2)
    local type1, type2 = type(t1), type(t2)
    if type1 ~= type2 then return false end
    if type1 ~= 'table' and type2 ~= 'table' then return t1 == t2 end
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not table_matches(v1, v2) then return false end
    end
    for k2, v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not table_matches(v1, v2) then return false end
    end
    return true
end

local function LeaveSlot(source)
    if not Slots[source] then return end
    if DoesEntityExist(Slots[source].Reel1) then DeleteEntity(Slots[source].Reel1) end
    if DoesEntityExist(Slots[source].Reel2) then DeleteEntity(Slots[source].Reel2) end
    if DoesEntityExist(Slots[source].Reel3) then DeleteEntity(Slots[source].Reel3) end
    UsedSlots[Slots[source].SlotNetID] = false
    Slots[source] = {}
end

RegisterNetEvent('dc-casino:slots:server:enter', function(netID, ReelLocation1, ReelLocation2, ReelLocation3, SlotModel)
    local src = source
    -- FIX: Swapped legacy QB functions with native QBox player data selectors
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local PlayerCoords = GetEntityCoords(GetPlayerPed(src))
    local SlotEntity = NetworkGetEntityFromNetworkId(netID)
    local SlotCoords = GetEntityCoords(SlotEntity)
    
    if not SlotReferences[SlotModel] then return end
    if #(PlayerCoords - SlotCoords) > 4 then return end
    if #(SlotCoords - ReelLocation1) > 2 or #(SlotCoords - ReelLocation2) > 2 or #(SlotCoords - ReelLocation3) > 2 then return end
    if UsedSlots[netID] then return end
    
    UsedSlots[netID] = true
    TriggerClientEvent('dc-casino:slots:client:enter', src)
    
    SetTimeout(1000, function()
        local ReelEntity1 = CreateObject(SlotReferences[SlotModel].reela, ReelLocation1.x, ReelLocation1.y, ReelLocation1.z, true, false, false)
        local ReelEntity2 = CreateObject(SlotReferences[SlotModel].reela, ReelLocation2.x, ReelLocation2.y, ReelLocation2.z, true, false, false)
        local ReelEntity3 = CreateObject(SlotReferences[SlotModel].reela, ReelLocation3.x, ReelLocation3.y, ReelLocation3.z, true, false, false)
        
        while not DoesEntityExist(ReelEntity1) do Wait(0) end
        while not DoesEntityExist(ReelEntity2) do Wait(0) end
        while not DoesEntityExist(ReelEntity3) do Wait(0) end
        
        Slots[src] = {
            Slot = NetworkGetEntityFromNetworkId(netID),
            Model = SlotModel,
            SlotNetID = netID,
            Reel1 = ReelEntity1,
            Reel2 = ReelEntity2,
            Reel3 = ReelEntity3,
            ReelLoc1 = ReelLocation1,
            ReelLoc2 = ReelLocation2,
            ReelLoc3 = ReelLocation3,
        }
        
        FreezeEntityPosition(Slots[src].Reel1, true)
        FreezeEntityPosition(Slots[src].Reel2, true)
        FreezeEntityPosition(Slots[src].Reel3, true)
        
        local SlotHeading = GetEntityHeading(SlotEntity)
        SetEntityRotation(Slots[src].Reel1, 0.0, 0.0, SlotHeading, 2, 1)
        SetEntityRotation(Slots[src].Reel2, 0.0, 0.0, SlotHeading, 2, 1)
        SetEntityRotation(Slots[src].Reel3, 0.0, 0.0, SlotHeading, 2, 1)
        
        -- FIX: Rebuilt old commented framework log calls into native ox_lib logger calls
        lib.logger(src, 'casino_enter', string.format("Entered a slot machine | Slot NetID: %s | Model: %s", netID, SlotModel))
    end)
end)

RegisterNetEvent('dc-casino:slots:server:spin', function(ChosenBetAmount)
    local src = source
    if not Slots[src] then return end
    
    local SlotModel = Slots[src].Model
    if not SlotReferences[SlotModel].betamounts[ChosenBetAmount] then return end
    
    local BetAmount = SlotReferences[SlotModel].betamounts[ChosenBetAmount]
    local SpinTime = math.random(4000, 6000)
    local ReelRewards = {math.random(0, 15), math.random(0, 15), math.random(0, 15)}
    local SlotHeading = GetEntityHeading(Slots[src].Slot)
    
    -- FIX: Replaced core balance parameters to track ox_inventory and qbx_core directly
    local hasEnoughFunds = false
    if UseCash then
        if exports.qbx_core:GetMoney(src, 'cash') >= BetAmount then
            exports.qbx_core:RemoveMoney(src, 'cash', BetAmount, 'Casino Slot Spin')
            hasEnoughFunds = true
        end
    elseif UseBank then
        if exports.qbx_core:GetMoney(src, 'bank') >= BetAmount then
            exports.qbx_core:RemoveMoney(src, 'bank', BetAmount, 'Casino Slot Spin')
            hasEnoughFunds = true
        end
    elseif UseItem then
        local chipCount = exports.ox_inventory:GetItemCount(src, 'casinochips')
        if chipCount >= BetAmount then
            exports.ox_inventory:RemoveItem(src, 'casinochips', BetAmount)
            hasEnoughFunds = true
        end
    end
    
    if not hasEnoughFunds then
        -- FIX: Converted legacy QB notifier event strings to native overextended library notifications
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough casino chips for this bet.' })
        return
    end
    
    for i = 1, #ReelRewards do
        if SlotReferences[SlotModel].misschance > math.random(1, 100) then 
            ReelRewards[i] = ReelRewards[i] + math.random(4, 6) / 10 
        end
    end
    
    local BlurryReel1 = CreateObject(SlotReferences[SlotModel].reelb, Slots[src].ReelLoc1.x, Slots[src].ReelLoc1.y, Slots[src].ReelLoc1.z, true, false, false)
    local BlurryReel2 = CreateObject(SlotReferences[SlotModel].reelb, Slots[src].ReelLoc2.x, Slots[src].ReelLoc2.y, Slots[src].ReelLoc2.z, true, false, false)
    local BlurryReel3 = CreateObject(SlotReferences[SlotModel].reelb, Slots[src].ReelLoc3.x, Slots[src].ReelLoc3.y, Slots[src].ReelLoc3.z, true, false, false)
    
    while not DoesEntityExist(BlurryReel1) do Wait(0) end
    while not DoesEntityExist(BlurryReel2) do Wait(0) end
    while not DoesEntityExist(BlurryReel3) do Wait(0) end
    
    FreezeEntityPosition(BlurryReel1, true)
    FreezeEntityPosition(BlurryReel2, true)
    FreezeEntityPosition(BlurryReel3, true)
    SetEntityRotation(BlurryReel1, 0.0, 0.0, SlotHeading, 2, true)
    SetEntityRotation(BlurryReel2, 0.0, 0.0, SlotHeading, 2, true)
    SetEntityRotation(BlurryReel3, 0.0, 0.0, SlotHeading, 2, true)
    
    local RewardMultiplier = 0
    for k, v in pairs(Rewards) do
        if table_matches(k, ReelRewards) then
            RewardMultiplier = v
            break
        end
    end
    
    if RewardMultiplier == 0 then
        for i = 1, #ReelRewards do
            if ReelRewards[i] == 4 or ReelRewards[i] == 11 or ReelRewards[i] == 15 then
                RewardMultiplier = RewardMultiplier + 1
            end
        end
        RewardMultiplier = SpecialReward[RewardMultiplier] or 0
    end
    
    TriggerClientEvent('dc-casino:slots:client:spinreels', src, SpinTime, ReelRewards, 
        NetworkGetNetworkIdFromEntity(BlurryReel1), 
        NetworkGetNetworkIdFromEntity(BlurryReel2), 
        NetworkGetNetworkIdFromEntity(BlurryReel3), 
        NetworkGetNetworkIdFromEntity(Slots[src].Reel1), 
        NetworkGetNetworkIdFromEntity(Slots[src].Reel2), 
        NetworkGetNetworkIdFromEntity(Slots[src].Reel3), RewardMultiplier)
        
    SetTimeout(SpinTime, function()
        local RewardAmount = BetAmount * RewardMultiplier
        lib.logger(src, 'casino_spin', string.format("Spinned a casino slot for %s and won %s", BetAmount, RewardAmount))
        
        if RewardMultiplier == 0 then return end
        
        -- FIX: Automated payout ledger distribution using native hooks
        if UseCash then
            exports.qbx_core:AddMoney(src, 'cash', RewardAmount, 'Casino Slot Spin')
        elseif UseBank then
            exports.qbx_core:AddMoney(src, 'bank', RewardAmount, 'Casino Slot Spin')
        elseif UseItem then
            exports.ox_inventory:AddItem(src, 'casinochips', RewardAmount)
        end
    end)
end)

RegisterNetEvent('dc-casino:slots:server:leave', function()
    LeaveSlot(source)
end)

AddEventHandler("playerDropped", function()
    LeaveSlot(source)
end)
