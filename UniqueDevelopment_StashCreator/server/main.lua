-- ========================================
-- LOCALE LOADER
-- ========================================

local Locales = {}

local localeData = LoadResourceFile(GetCurrentResourceName(), 'locales/en.json')
if localeData then
    Locales = json.decode(localeData) or {}
end

function locale(key)
    return Locales[key] or key
end

-- ========================================
-- STASH CACHE (server memory)
-- ========================================

local LoadedStashes = {}

-- ========================================
-- HELPERS
-- ========================================

local function FormatStash(row)
    return {
        stash_id = row.stash_id,
        label    = row.label,
        slots    = row.slots,
        weight   = row.weight,
        coords   = { x = row.coords_x, y = row.coords_y, z = row.coords_z },
        size     = { x = row.size_x,   y = row.size_y,   z = row.size_z   },
        rotation = row.rotation,
        code     = row.code,
        debug    = row.debug == 1
    }
end

local function GetFormattedStashes()
    local result = {}
    for _, stash in ipairs(LoadedStashes) do
        table.insert(result, stash)
    end
    return result
end

local function FindStash(stashId)
    for _, stash in ipairs(LoadedStashes) do
        if stash.stash_id == stashId then
            return stash
        end
    end
    return nil
end

local function RemoveFromCache(stashId)
    for i, stash in ipairs(LoadedStashes) do
        if stash.stash_id == stashId then
            table.remove(LoadedStashes, i)
            return
        end
    end
end

-- ========================================
-- WEBHOOK LOGGING
-- ========================================

local function SendWebhook(url, title, description, color, fields)
    if not url or url == '' or url:find('xxx') then return end

    local embedFields = {}
    if fields then
        for _, field in ipairs(fields) do
            table.insert(embedFields, {
                name   = field.name  or '',
                value  = field.value or '',
                inline = field.inline or false
            })
        end
    end

    local payload = json.encode({
        embeds = {
            {
                title       = title,
                description = description,
                color       = color or 3447003,
                fields      = embedFields,
                footer      = {
                    text = 'UniqueDevelopment StashCreator'
                },
                timestamp   = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
    })

    PerformHttpRequest(url, function() end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

local function LogStashOpen(source, stash, success)
    local playerName = BridgeServer.GetPlayerName(source)
    local identifier = BridgeServer.GetPlayerIdentifier(source)
    local url        = success and Config.Webhooks.stashOpen or Config.Webhooks.stashFail
    local color      = success and 3066993 or 15158332

    SendWebhook(
        url,
        success and locale('stash_opened') or locale('stash_open_fail'),
        '',
        color,
        {
            { name = locale('player'),   value = playerName,         inline = true },
            { name = locale('identifier'), value = identifier,       inline = true },
            { name = locale('stash'),    value = stash.label,        inline = true },
            { name = locale('stash_id'), value = stash.stash_id,     inline = true },
        }
    )
end

local function LogAdminAction(source, action, data)
    local playerName = BridgeServer.GetPlayerName(source)
    local identifier = BridgeServer.GetPlayerIdentifier(source)

    SendWebhook(
        Config.Webhooks.adminLog,
        locale('admin_action_logged'),
        '',
        16776960,
        {
            { name = locale('admin'),      value = playerName,   inline = true },
            { name = locale('identifier'), value = identifier,   inline = true },
            { name = locale('action'),     value = action,       inline = true },
            { name = locale('data'),       value = tostring(data), inline = false },
        }
    )
end

-- ========================================
-- STARTUP: LOAD & REGISTER ALL STASHES
-- ========================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    Wait(500) -- allow DB connection to stabilize

    Database.GetAllStashes(function(rows)
        if not rows or #rows == 0 then
            if Config.Debug then
                print('^3[StashCreator]^0 No stashes found in database.')
            end
            return
        end

        for _, row in ipairs(rows) do
            local stash = FormatStash(row)
            table.insert(LoadedStashes, stash)

            -- Register with inventory system
            BridgeServer.RegisterStash(
                stash.stash_id,
                stash.label,
                stash.slots,
                stash.weight,
                vector3(stash.coords.x, stash.coords.y, stash.coords.z)
            )
        end

        if Config.Debug then
            print(string.format('^2[StashCreator]^0 Loaded %d stash(es) from database.', #LoadedStashes))
        end
    end)
end)

-- ========================================
-- lib.callback: GET CONFIG (client-needed values)
-- ========================================

lib.callback.register('UniqueStash:GetConfig', function(source)
    return {
        interactionType = Config.InteractionType,
        target          = Config.Target,
        text3D          = Config.Text3D,
        command         = Config.Command,
        keybind         = Config.Keybind,
    }
end)

-- ========================================
-- lib.callback: GET STASHES
-- ========================================

lib.callback.register('UniqueStash:GetStashes', function(source)
    return GetFormattedStashes()
end)

-- ========================================
-- lib.callback: IS ADMIN
-- ========================================

lib.callback.register('UniqueStash:IsAdmin', function(source)
    return BridgeServer.IsAdmin(source)
end)

-- ========================================
-- lib.callback: OPEN STASH (password validation)
-- ========================================

lib.callback.register('UniqueStash:OpenStash', function(source, stashId, enteredCode)
    local stash = FindStash(stashId)

    if not stash then
        return { success = false, reason = locale('unknown_stash') }
    end

    if stash.code ~= enteredCode then
        LogStashOpen(source, stash, false)
        return { success = false, reason = locale('notify_description') }
    end

    LogStashOpen(source, stash, true)

    -- For inventories that require server-side trigger to open, call it here
    BridgeServer.OpenStash(source, stashId, stash.label, stash.slots, stash.weight)

    return { success = true }
end)

-- ========================================
-- lib.callback: CREATE STASH (admin)
-- ========================================

lib.callback.register('UniqueStash:CreateStash', function(source, data)
    if not BridgeServer.IsAdmin(source) then
        return { success = false, reason = locale('notify_no_permission') }
    end

    -- Check duplicate ID
    local exists = false
    Database.StashExists(data.stash_id, function(result)
        exists = result
    end)

    -- StashExists uses async callback; for synchronous check use MySQL.scalar.await
    exists = MySQL.scalar.await('SELECT COUNT(*) FROM unique_stashes WHERE stash_id = ?', { data.stash_id })

    if exists and exists > 0 then
        return { success = false, reason = locale('stash_id_exists') }
    end

    local created = false
    Database.CreateStash(data, function(result)
        created = result
    end)

    -- Use sync variant for callback response
    local insertId = MySQL.insert.await(
        'INSERT INTO unique_stashes (stash_id, label, slots, weight, coords_x, coords_y, coords_z, size_x, size_y, size_z, rotation, code, debug) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            data.stash_id, data.label, data.slots, data.weight,
            data.coords.x, data.coords.y, data.coords.z,
            data.size.x, data.size.y, data.size.z,
            data.rotation or 0.0, data.code, data.debug and 1 or 0
        }
    )

    if not insertId or insertId <= 0 then
        return { success = false, reason = locale('stash_create_error') }
    end

    -- Add to cache
    local newStash = {
        stash_id = data.stash_id,
        label    = data.label,
        slots    = data.slots,
        weight   = data.weight,
        coords   = data.coords,
        size     = data.size,
        rotation = data.rotation or 0.0,
        code     = data.code,
        debug    = data.debug or false
    }
    table.insert(LoadedStashes, newStash)

    -- Register with inventory
    BridgeServer.RegisterStash(
        newStash.stash_id,
        newStash.label,
        newStash.slots,
        newStash.weight,
        vector3(newStash.coords.x, newStash.coords.y, newStash.coords.z)
    )

    -- Notify all clients to add the new zone
    TriggerClientEvent('UniqueStash:Client:AddZone', -1, newStash)

    -- Log admin action
    LogAdminAction(source, locale('create'), data.stash_id .. ' | ' .. data.label)

    if Config.Debug then
        print(string.format('^2[StashCreator]^0 Stash created: %s by %s', data.stash_id, BridgeServer.GetPlayerName(source)))
    end

    return { success = true, reason = locale('stash_created') }
end)

-- ========================================
-- lib.callback: UPDATE STASH (admin)
-- ========================================

lib.callback.register('UniqueStash:UpdateStash', function(source, data)
    if not BridgeServer.IsAdmin(source) then
        return { success = false, reason = locale('notify_no_permission') }
    end

    local rowsChanged = MySQL.update.await(
        'UPDATE unique_stashes SET label = ?, slots = ?, weight = ?, coords_x = ?, coords_y = ?, coords_z = ?, size_x = ?, size_y = ?, size_z = ?, rotation = ?, code = ?, debug = ? WHERE stash_id = ?',
        {
            data.label, data.slots, data.weight,
            data.coords.x, data.coords.y, data.coords.z,
            data.size.x, data.size.y, data.size.z,
            data.rotation or 0.0, data.code, data.debug and 1 or 0,
            data.stash_id
        }
    )

    if not rowsChanged or rowsChanged <= 0 then
        return { success = false, reason = locale('stash_update_error') }
    end

    -- Update cache
    RemoveFromCache(data.stash_id)
    local updatedStash = {
        stash_id = data.stash_id,
        label    = data.label,
        slots    = data.slots,
        weight   = data.weight,
        coords   = data.coords,
        size     = data.size,
        rotation = data.rotation or 0.0,
        code     = data.code,
        debug    = data.debug or false
    }
    table.insert(LoadedStashes, updatedStash)

    -- Update inventory weight if supported
    BridgeServer.SetMaxWeight(data.stash_id, data.weight)

    -- Notify all clients to update the zone
    TriggerClientEvent('UniqueStash:Client:UpdateZone', -1, updatedStash)

    -- Log admin action
    LogAdminAction(source, locale('update'), data.stash_id .. ' | ' .. data.label)

    if Config.Debug then
        print(string.format('^2[StashCreator]^0 Stash updated: %s by %s', data.stash_id, BridgeServer.GetPlayerName(source)))
    end

    return { success = true, reason = locale('stash_updated') }
end)

-- ========================================
-- lib.callback: DELETE STASH (admin)
-- ========================================

lib.callback.register('UniqueStash:DeleteStash', function(source, stashId)
    if not BridgeServer.IsAdmin(source) then
        return { success = false, reason = locale('notify_no_permission') }
    end

    local rowsChanged = MySQL.update.await('DELETE FROM unique_stashes WHERE stash_id = ?', { stashId })

    if not rowsChanged or rowsChanged <= 0 then
        return { success = false, reason = locale('stash_delete_error') }
    end

    -- Remove from cache
    RemoveFromCache(stashId)

    -- Clear inventory contents
    BridgeServer.ClearStashInventory(stashId)

    -- Notify all clients to remove the zone
    TriggerClientEvent('UniqueStash:Client:RemoveZone', -1, stashId)

    -- Log admin action
    LogAdminAction(source, locale('delete'), stashId)

    if Config.Debug then
        print(string.format('^1[StashCreator]^0 Stash deleted: %s by %s', stashId, BridgeServer.GetPlayerName(source)))
    end

    return { success = true, reason = locale('stash_deleted') }
end)

-- ========================================
-- lib.callback: VIEW STASH INVENTORY (admin)
-- ========================================

lib.callback.register('UniqueStash:ViewStash', function(source, stashId)
    if not BridgeServer.IsAdmin(source) then
        return { success = false, reason = locale('notify_no_permission') }
    end

    local stash = FindStash(stashId)
    if not stash then
        return { success = false, reason = locale('unknown_stash') }
    end

    BridgeServer.InspectInventory(source, stashId)

    -- Log admin action
    LogAdminAction(source, locale('view'), stashId .. ' | ' .. stash.label)

    return { success = true }
end)

-- ========================================
-- lib.callback: TELEPORT TO STASH (admin, server-side log only)
-- ========================================

lib.callback.register('UniqueStash:TeleportToStash', function(source, stashId)
    if not BridgeServer.IsAdmin(source) then
        return { success = false, reason = locale('notify_no_permission') }
    end

    LogAdminAction(source, locale('teleport'), stashId)

    return { success = true }
end)
