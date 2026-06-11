-- ====================================================================
-- =-------------------- [QBOX CASINO LUCKY WHEEL] ------------------=
-- ====================================================================
local h, _wheel, _base, _lights1, _lights2, _arrow1, _arrow2 = nil
local _isRolling = false

-- Initialize Wheel and Props
CreateThread(function()
    lib.requestAudioBank("DLC_VINEWOOD\\CASINO_GENERAL")
    local models = {'vw_prop_vw_luckywheel_02a', 'vw_prop_vw_luckywheel_01a', 'vw_prop_vw_luckylight_off', 'vw_prop_vw_luckylight_on', 'vw_prop_vw_jackpot_off', 'vw_prop_vw_jackpot_on'}
    for _, model in ipairs(models) do lib.RequestModel(GetHashKey(model)) end
    
    ClearArea(Config.WheelPos.x, Config.WheelPos.y, Config.WheelPos.z, 5.0, true, false, false, false)
    _wheel = CreateObject(GetHashKey('vw_prop_vw_luckywheel_02a'), Config.WheelPos.x, Config.WheelPos.y, Config.WheelPos.z, false, false, true)
    SetEntityHeading(_wheel, Config.WheelPos.h)
    _base = CreateObject(GetHashKey('vw_prop_vw_luckywheel_01a'), Config.WheelPos.x, Config.WheelPos.y, Config.WheelPos.z-0.26, false, false, true)
    SetEntityHeading(_base, Config.WheelPos.h)
    _lights1 = CreateObject(GetHashKey('vw_prop_vw_luckylight_off'), Config.WheelPos.x, Config.WheelPos.y, Config.WheelPos.z+0.35, false, false, true)
    SetEntityHeading(_lights1, Config.WheelPos.h)
    _lights2 = CreateObject(GetHashKey('vw_prop_vw_luckylight_on'), Config.WheelPos.x, Config.WheelPos.y, Config.WheelPos.z+0.35, false, false, true)
    SetEntityVisible(_lights2, false, 0)
    SetEntityHeading(_lights2, Config.WheelPos.h)
    _arrow1 = CreateObject(GetHashKey('vw_prop_vw_jackpot_off'), Config.WheelPos.x, Config.WheelPos.y, Config.WheelPos.z+2.5, false, false, true)
    SetEntityHeading(_arrow1, Config.WheelPos.h)
    _arrow2 = CreateObject(GetHashKey('vw_prop_vw_jackpot_on'), Config.WheelPos.x, Config.WheelPos.y, Config.WheelPos.z+2.5, false, false, true)
    SetEntityVisible(_arrow2, false, 0)
    SetEntityHeading(_arrow2, Config.WheelPos.h)
    h = GetEntityRotation(_wheel)
end)

-- Net Events
RegisterNetEvent("luckywheel:syncanim", function() doRoll(0) end)

RegisterNetEvent("luckywheel:startroll", function(s, index, p)
    Wait(1000)
    SetEntityVisible(_lights1, false, 0)
    SetEntityVisible(_lights2, true, 0)
    local win = (index - 1) * 18 + 0.0
    local j = 360
    if s == GetPlayerServerId(PlayerId()) then PlaySoundFromEntity(-1, "Spin_Start", _wheel, 'dlc_vw_casino_lucky_wheel_sounds', 1, 1) end
    
    -- Rotation Logic
    for i=1,1100,1 do
        SetEntityRotation(_wheel, h.x, j+0.0, h.z, 0, false)
        j = j - (i > 850 and (i == 850 and math.random(win-4, win+10) + 0.0 or 2.5) or 3.0) -- Simplified rotation speed
        if j < 0 then j = j + 360 end
        Wait(0)
    end
    Wait(300)
    SetEntityVisible(_arrow1, false, 0)
    SetEntityVisible(_arrow2, true, 0)
    
    -- Win Sound
    if s == GetPlayerServerId(PlayerId()) then
        PlaySoundFromEntity(-1, "Win_".. (p.sound == 'car' and 'Car' or p.sound == 'cash' and 'Cash' or 'Generic'), _wheel, 'dlc_vw_casino_lucky_wheel_sounds', 1, 1)
    end
    
    -- Spin Complete
    for i=1,15,1 do
        Wait(200)
        SetEntityVisible(_lights1, i%2==0, 0)
        SetEntityVisible(_arrow2, i%2==0, 0)
        SetEntityVisible(_lights2, i%2~=0, 0)
        SetEntityVisible(_arrow1, i%2~=0, 0)
        if i == 5 and s == GetPlayerServerId(PlayerId()) then TriggerServerEvent('luckywheel:give', s, p) end
    end
    Wait(1000)
    SetEntityVisible(_lights1, true, 0)
    SetEntityVisible(_lights2, false, 0)
    SetEntityVisible(_arrow1, true, 0)
    SetEntityVisible(_arrow2, false, 0)
    TriggerServerEvent('luckywheel:stoproll')
end)

RegisterNetEvent("luckywheel:rollFinished", function() _isRolling = false end)

-- Interaction and Vehicle Logic
function doRoll(index)
    if not _isRolling then
        lib.hideTextUI()
        _isRolling = true
        local playerPed = cache.ped
        local animDict = IsPedMale(playerPed) and 'anim_casino_a@amb@casino@games@lucky7wheel@male' or 'anim_casino_a@amb@casino@games@lucky7wheel@female'
        lib.requestAnimDict(animDict)
        
        local _movePos = GetObjectOffsetFromCoords(GetEntityCoords(_base), GetEntityHeading(_base),-0.9, -0.8, -1.0)
        TaskGoStraightToCoord(playerPed, _movePos.x, _movePos.y, _movePos.z, 1.0, 3000, GetEntityHeading(_base), 0.0)
        while #(GetEntityCoords(playerPed) - vector3(_movePos.x, _movePos.y, _movePos.z)) > 0.1 do Wait(0) end
        
        SetEntityHeading(playerPed, GetEntityHeading(_base))
        TaskPlayAnim(playerPed, animDict, 'enter_right_to_baseidle', 8.0, -8.0, -1, 0, 0, false, false, false)
        Wait(2000) -- Simplified anim wait
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_STRIP_WATCH_STAND", 0, true)
        Wait(4800)
        ClearPedTasks(playerPed)
    end
end

-- OX_LIB Context Menu
RegisterNetEvent("doj:casinoLuckyWheel", function() 
    lib.hideTextUI()
    if exports.ox_inventory:GetItemCount("casino_vip") >= 1 then
        lib.registerContext({
            id = 'casino_luckywheel_menu', title = 'Lucky Wheel',
            options = {{title = 'Spin', description = '$'..Config.startingPrice, icon = 'clover', onSelect = function() TriggerServerEvent("luckywheel:getwheel") end}}
        })
        lib.showContext('casino_luckywheel_menu')
    else
        lib.notify({title = 'Access Denied', description = 'V.I.P Membership Required', type = 'error'})
    end
end)

RegisterNetEvent('doj:client:winCar', function(vehicle, plate, vehicleId)
    local v = Config.Vehicle[1] -- Simplified example
    local netId = lib.callback.await('doj:server:spawnVehicle', false, vehicle, v.spawn, plate, vehicleId)
    local veh = NetToVeh(netId)
    local props = lib.getVehicleProperties(veh)
    SetVehicleColours(veh, v.colors[1], v.colors[2])
    SetVehicleExtraColours(veh, v.extraColors[1], v.extraColors[2])
    SetVehicleWindowTint(veh, 3)
    SetVehicleFuelLevel(veh, 100.0)
    -- TriggerServerEvent('qbx_vehiclekeys:server:addKey', plate) -- Example QBox fix
end)

-- Clean, optimized lucky wheel interaction targeting only the spinning face
exports.ox_target:addModel({ `vw_prop_vw_luckywheel_01a` }, {
    {
        name = 'casino_lucky_wheel_trigger',
        event = 'doj:casinoLuckyWheel',
        icon = 'fas fa-clover',
        label = 'Spin the Lucky Wheel',
        distance = 2.5
    }
})
