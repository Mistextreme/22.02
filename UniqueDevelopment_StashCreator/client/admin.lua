-- ========================================
-- ADMIN PANEL STATE
-- ========================================

local AdminPanelOpen = false

-- ========================================
-- COMMAND & KEYBIND
-- ========================================

RegisterCommand(Config and Config.Command or 'StashCreator', function()
    OpenAdminPanel()
end, false)

-- Keybind registration via ox_lib (preferred) or FiveM native
CreateThread(function()
    Wait(500) -- wait for config to arrive from server

    lib.callback('UniqueStash:GetConfig', false, function(config)
        if not config then return end

        RegisterKeyMapping(
            config.command or 'StashCreator',
            locale('keybind_description'),
            'keyboard',
            config.keybind or 'F7'
        )
    end)
end)

-- ========================================
-- OPEN ADMIN PANEL
-- ========================================

function OpenAdminPanel()
    lib.callback('UniqueStash:IsAdmin', false, function(isAdmin)
        if not isAdmin then
            Bridge.Notify(locale('notify_title'), locale('notify_no_permission'), 'error')
            return
        end

        lib.callback('UniqueStash:GetStashes', false, function(stashes)
            AdminPanelOpen = true
            SetNuiFocus(true, true)

            SendNUIMessage({
                action  = 'openUI',
                stashes = stashes or {},
                lang    = 'en'
            })
        end)
    end)
end

-- ========================================
-- NUI CALLBACKS
-- ========================================

-- Close panel
RegisterNUICallback('close', function(data, cb)
    AdminPanelOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

-- Get player current coords
RegisterNUICallback('getPlayerCoords', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    cb({ x = coords.x, y = coords.y, z = coords.z })
end)

-- Refresh stash list
RegisterNUICallback('getStashes', function(data, cb)
    lib.callback('UniqueStash:GetStashes', false, function(stashes)
        cb(stashes or {})
    end)
end)

-- Create stash
RegisterNUICallback('createStash', function(data, cb)
    lib.callback('UniqueStash:CreateStash', false, function(result)
        if result and result.success then
            Bridge.Notify(locale('notify_success'), locale('stash_created'), 'success')
        else
            Bridge.Notify(locale('notify_error'), result and result.reason or locale('stash_create_error'), 'error')
        end
        cb(result or { success = false })
    end, data)
end)

-- Update / edit stash
RegisterNUICallback('updateStash', function(data, cb)
    lib.callback('UniqueStash:UpdateStash', false, function(result)
        if result and result.success then
            Bridge.Notify(locale('notify_success'), locale('stash_updated'), 'success')
        else
            Bridge.Notify(locale('notify_error'), result and result.reason or locale('stash_update_error'), 'error')
        end
        cb(result or { success = false })
    end, data)
end)

-- Delete stash
RegisterNUICallback('deleteStash', function(data, cb)
    lib.callback('UniqueStash:DeleteStash', false, function(result)
        if result and result.success then
            Bridge.Notify(locale('notify_success'), locale('stash_deleted'), 'success')
        else
            Bridge.Notify(locale('notify_error'), result and result.reason or locale('stash_delete_error'), 'error')
        end
        cb(result or { success = false })
    end, data.stash_id)
end)

-- Teleport to stash coords
RegisterNUICallback('teleportToStash', function(data, cb)
    -- Log on server side (optional) and teleport locally
    lib.callback('UniqueStash:TeleportToStash', false, function(result)
        -- do nothing with result, teleport is client-side
    end, data.stash_id or '')

    if data.coords then
        local ped = PlayerPedId()
        SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z, false, false, false, true)
    end

    -- Close the UI after teleport
    AdminPanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeUI' })

    cb({})
end)

-- View / inspect stash inventory (admin)
RegisterNUICallback('viewStash', function(data, cb)
    lib.callback('UniqueStash:ViewStash', false, function(result)
        if result and result.success then
            -- Inventory will be forced-opened server-side via BridgeServer.InspectInventory
            -- Close NUI so the inventory is visible
            AdminPanelOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'closeUI' })
        else
            Bridge.Notify(locale('notify_error'), result and result.reason or locale('stash_open_fail'), 'error')
        end
        cb(result or { success = false })
    end, data.stash_id)
end)

-- ========================================
-- ESC KEY TO CLOSE
-- ========================================

CreateThread(function()
    while true do
        Wait(0)
        if AdminPanelOpen then
            if IsControlJustReleased(0, 200) then -- ESCAPE
                AdminPanelOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'closeUI' })
            end
        end
    end
end)
