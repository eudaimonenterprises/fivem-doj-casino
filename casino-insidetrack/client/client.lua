-- ====================================================================
-- =------------------- [QBOX CASINO INSIDE TRACK] -----------------=
-- ====================================================================
local cooldown = 60
local tick = 0
local checkRaceStatus = false
local insideTrackActive = false
local gameOpen = false

local function OpenInsideTrack()
    -- FIX: Replaced envi-interact status text bar updates with a clean native QBox notification
    lib.notify({
        title = 'Diamond Casino Inside Track',
        description = 'Good luck on your track bets!',
        type = 'inform'
    })

    -- FIX: Replaced old QBCore script callbacks with native ox_lib/QBox callback hooks
    lib.callback('insidetrack:server:getbalance', false, function(balance)
        Utils.PlayerBalance = balance
    end)

    if insideTrackActive then
        return
    end
    insideTrackActive = true

    -- Scaleform Movie Config
    Utils.Scaleform = lib.requestScaleformMovie('HORSE_RACING_CONSOLE')
    DisplayHud(false)
    SetPlayerControl(cache.ped, false, 0)
    lib.requestAudioBank('DLC_VINEWOOD\\CASINO_GENERAL')
    Utils:ShowMainScreen()
    Utils:SetMainScreenCooldown(cooldown)
    
    -- Setup interactive layout parameters
    Utils:AddHorses()
    Utils:DrawInsideTrack()
    Utils:HandleControls()
end

-- FIX: Completely removed envi-interact's choice menus and swapped them to optimized ox_lib Context Menus
RegisterNetEvent("doj:casinoInsideTrack", function()
    lib.hideTextUI()
    local HasItem = exports.ox_inventory:GetItemCount("casino_member")

    if HasItem >= 1 then
        -- Registers a clean, high-performance context menu on the user's screen
        lib.registerContext({
            id = 'casino_insidetrack_menu',
            title = 'Diamond Casino Inside Track',
            options = {
                {
                    title = 'Place Bets',
                    description = 'Step up to the console and place your horse race bets',
                    icon = 'horse',
                    onSelect = function()
                        OpenInsideTrack()
                    end
                }
            }
        })
        lib.showContext('casino_insidetrack_menu')
    else
        -- Triggers an alert context dialog if the player lacks a membership card
        lib.registerContext({
            id = 'casino_insidetrack_denied',
            title = 'Diamond Casino Inside Track',
            options = {
                {
                    title = 'Access Denied',
                    description = 'You are not a member of the casino. Please go visit the front desk cashier cage.',
                    icon = 'ban',
                    disabled = true
                }
            }
        })
        lib.showContext('casino_insidetrack_denied')
    end
end)

function CloseHorseBets()
    insideTrackActive = false
    SetPlayerControl(cache.ped, true, 0)
    SetScaleformMovieAsNoLongerNeeded(Utils.Scaleform)
    Utils.Scaleform = -1
    StopSound(0)
end

local function LeaveInsideTrack()
    insideTrackActive = false
    SetPlayerControl(cache.ped, true, 0)
    SetScaleformMovieAsNoLongerNeeded(Utils.Scaleform)
    Utils.Scaleform = -1
    StopSound(0)
end

-- FIX: Replaced old envi-interact popup notifications with native framework notifications
RegisterNetEvent('QBCore:client:closeBetsNotEnough')
AddEventHandler('QBCore:client:closeBetsNotEnough', function()
    CloseHorseBets()
    lib.notify({
        title = 'Bets Closed',
        description = 'You do not have enough Casino Chips to place this bet.',
        type = 'error'
    })
end)

RegisterNetEvent('QBCore:client:closeBetsZeroChips')
AddEventHandler('QBCore:client:closeBetsZeroChips', function()
    CloseHorseBets()
    lib.notify({
        title = 'Bets Closed',
        description = 'You do not have any Casino Chips left in your inventory.',
        type = 'error'
    })
end)

function Utils:DrawInsideTrack()
    CreateThread(function()
        while insideTrackActive do
            Wait(0)
            local xMouse, yMouse = GetDisabledControlNormal(2, 239), GetDisabledControlNormal(2, 240)
            -- Fake cooldown calculator
            tick = (tick + 10)
            if (tick == 1000) then
                if (cooldown == 1) then
                    cooldown = 60
                end
                cooldown = (cooldown - 1)
                tick = 0
                Utils:SetMainScreenCooldown(cooldown)
            end
            -- Mouse layout controller
            BeginScaleformMovieMethod(Utils.Scaleform, 'SET_MOUSE_INPUT')
            ScaleformMovieMethodAddParamFloat(xMouse)
            ScaleformMovieMethodAddParamFloat(yMouse)
            EndScaleformMovieMethod()
            -- Render frame execution
            DrawScaleformMovieFullscreen(Utils.Scaleform, 255, 255, 255, 255)
        end
    end)
end

function Utils:HandleControls()
    CreateThread(function()
        while insideTrackActive do
            Wait(0)

            if IsControlJustPressed(2, 194) then
                LeaveInsideTrack()
            end

            if IsControlJustPressed(2, 202) then
                LeaveInsideTrack()
            end

            -- Left click registration
            if IsControlJustPressed(2, 237) then
                local clickedButton = Utils:GetMouseClickedButton()
 
                if Utils.ChooseHorseVisible then
                    if (clickedButton ~= 12) and (clickedButton ~= -1) then
                        if Utils.PlayerBalance < Utils.CurrentBet then
                            Utils.CurrentBet = math.floor(Utils.PlayerBalance / 100) * 100
                        end
                        Utils.CurrentHorse = (clickedButton - 1)
                        Utils:ShowBetScreen(Utils.CurrentHorse)
                        Utils.ChooseHorseVisible = false
                    end
                end

                -- Rules button trigger
                if (clickedButton == 15) then
                    Utils:ShowRules()
                end

                -- Close buttons configurations
                if (clickedButton == 12) then
                    if Utils.ChooseHorseVisible then
                        Utils.ChooseHorseVisible = false
                    end
                    
                    if Utils.BetVisible then
                        Utils:ShowHorseSelection()
                        Utils.BetVisible = false
                        Utils.CurrentHorse = -1
                    else
                        Utils:ShowMainScreen()
                    end
                end

                -- Start bet tracking
                if (clickedButton == 1) then
                    Utils:ShowHorseSelection()
                end

                -- Start race triggers
                if (clickedButton == 10) then
                    PlaySoundFrontend(-1, 'race_loop', 'dlc_vw_casino_inside_track_betting_single_event_sounds')
                    TriggerServerEvent("insidetrack:server:placebet", Utils.CurrentBet)
                    Utils:StartRace()
                    checkRaceStatus = true
                end

                -- Adjust current bet values
                if (clickedButton == 8) then
                    if (Utils.CurrentBet < Utils.PlayerBalance - 100) then
                        Utils.CurrentBet = (Utils.CurrentBet + 100)
                        Utils.CurrentGain = (Utils.CurrentBet * 2)
                        Utils:UpdateBetValues(Utils.CurrentHorse, Utils.CurrentBet, Utils.PlayerBalance, Utils.CurrentGain)
                    end
                end

                if (clickedButton == 9) then
                    if (Utils.CurrentBet > 100) then
                        Utils.CurrentBet = (Utils.CurrentBet - 100)
                        Utils.CurrentGain = (Utils.CurrentBet * 2)
                        Utils:UpdateBetValues(Utils.CurrentHorse, Utils.CurrentBet, Utils.PlayerBalance, Utils.CurrentGain)
                    end
                end

                if (clickedButton == 13) then
                    Utils:ShowMainScreen()
                end

                -- Manage active race completion check logic
                while checkRaceStatus do
                    Wait(0)
                    local raceFinished = Utils:IsRaceFinished()
                    if (raceFinished) then
                        StopSound(0)
                        if (Utils.CurrentHorse == Utils.CurrentWinner) then
                            TriggerServerEvent("insidetrack:server:winnings", Utils.CurrentGain)
                        end
                        
                        -- FIX: Standardized core callback wrapper loop execution to balance framework states
                        lib.callback('insidetrack:server:getbalance', false, function(balance)
                            Utils.PlayerBalance = balance
                        end)
                        
                        Utils:UpdateBetValues(Utils.CurrentHorse, Utils.CurrentBet, Utils.PlayerBalance, Utils.CurrentGain)
                        Utils:ShowResults()
                        Utils.CurrentHorse = -1
                        Utils.CurrentWinner = -1
                        Utils.HorsesPositions = {}
                        checkRaceStatus = false
                    end
                end
            end
        end
    end)
end

exports.ox_target:addModel(`ch_prop_casino_track_console_01a`, {
    {
        name = 'casino_inside_track_trigger',
        event = 'doj:casinoInsideTrack',
        icon = 'fas fa-horse',
        label = 'Play Inside Track',
        distance = 2.0
    }
})