-- ========================================
-- ADMIN PANEL STATE
-- ========================================

local AdminPanelOpen = false

-- ========================================
-- COMMAND & KEYBIND
-- ========================================
-- MINOR FIX #7: Removed reference to Config (server-only table, always nil on client).
--   The original expression `Config and Config.Command or 'StashCreator'` happened to
--   evaluate to 'StashCreator' silently via Lua short-circuit, but was a hidden landmine.
--   RegisterCommand now uses the literal default directly; the real command name is also
--   set dynamically below from the server config via RegisterKeyMapping.
-- ========================================

RegisterCommand('StashCreator', function()
    OpenAdminPanel()
end, false)

-- Register keybind using the command name and key from server config
CreateThread(function()
    Wait(500) -- allow server config callback to be available

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
    -- Fire-and-forget server log
    lib.callback('UniqueStash:TeleportToStash', false, function() end, data.stash_id or '')

    if data.coords then
        SetEntityCoords(PlayerPedId(), data.coords.x, data.coords.y, data.coords.z, false, false, false, true)
    end

    -- Close panel so the world is visible after teleport
    AdminPanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeUI' })

    cb({})
end)

-- View / inspect stash inventory (admin)
RegisterNUICallback('viewStash', function(data, cb)
    lib.callback('UniqueStash:ViewStash', false, function(result)
        if result and result.success then
            -- Inventory is force-opened server-side via BridgeServer.InspectInventory.
            -- Close NUI so the inventory UI is visible.
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
-- MINOR FIX #6: The previous version ran Wait(0) every single frame regardless of
--   whether the panel was open, burning CPU constantly. Now sleeps at Wait(500) when
--   the panel is closed and only switches to per-frame polling while it is open.
-- ========================================

CreateThread(function()
    while true do
        if AdminPanelOpen then
            if IsControlJustReleased(0, 200) then -- ESCAPE key
                AdminPanelOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'closeUI' })
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
