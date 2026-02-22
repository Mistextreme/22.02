-- ========================================
-- LOCALE LOADER
-- ========================================

local Locales = {}

CreateThread(function()
    Wait(100)
    local data = LoadResourceFile(GetCurrentResourceName(), 'locales/en.json')
    if data then
        Locales = json.decode(data) or {}
    end
end)

function locale(key)
    return Locales[key] or key
end

-- ========================================
-- STATE
-- ========================================

local ClientConfig  = {}
local ClientStashes = {}
local ActiveZones   = {}  -- [stash_id] = zoneId
local Initialized   = false

-- ========================================
-- STARTUP
-- ========================================

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    Wait(1500) -- wait for server-side stash loading to complete

    -- Fetch config from server
    lib.callback('UniqueStash:GetConfig', false, function(config)
        if config then
            ClientConfig = config
        end
    end)

    Wait(200)

    -- Fetch all stashes and register zones
    lib.callback('UniqueStash:GetStashes', false, function(stashes)
        if stashes then
            ClientStashes = stashes
            for _, stash in ipairs(stashes) do
                RegisterStashZone(stash)
            end
            Initialized = true
        end
    end)
end)

-- ========================================
-- ZONE REGISTRATION
-- ========================================

function RegisterStashZone(stash)
    if not stash or not stash.stash_id then return end

    if ClientConfig.interactionType == 'target' then
        local cfg    = ClientConfig.target or {}
        local zoneId = Bridge.AddBoxZone({
            coords    = vector3(stash.coords.x, stash.coords.y, stash.coords.z),
            size      = vector3(stash.size.x, stash.size.y, stash.size.z),
            rotation  = stash.rotation or 0.0,
            debug     = stash.debug or false,
            icon      = cfg.Icon or 'fa-solid fa-box',
            label     = stash.label,
            distance  = cfg.Distance or 1.5,
            onSelect  = function()
                OpenStashWithPassword(stash)
            end
        })
        ActiveZones[stash.stash_id] = zoneId

    -- 3dtext zones are rendered in the draw thread below
    -- we just ensure the stash is in ClientStashes
    end
end

function UnregisterStashZone(stashId)
    if ActiveZones[stashId] then
        Bridge.RemoveZone(ActiveZones[stashId])
        ActiveZones[stashId] = nil
    end
end

-- ========================================
-- 3D TEXT DRAW HELPER
-- ========================================

local function DrawText3D(x, y, z, text, font, scale, r, g, b, a)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist       = #(vector3(px, py, pz) - vector3(x, y, z))
    local drawScale  = (1 / dist) * 2 * ((1 / GetGameplayCamFov()) * 100)

    SetTextScale(0.0, drawScale)
    SetTextFont(font or 4)
    SetTextProportional(1)
    SetTextColour(r or 255, g or 255, b or 255, a or 200)
    SetTextDropShadow()
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

-- ========================================
-- 3D TEXT INTERACTION THREAD
-- ========================================

CreateThread(function()
    while true do
        if Initialized and ClientConfig.interactionType == '3dtext' and #ClientStashes > 0 then
            local cfg3d      = ClientConfig.text3D or {}
            local seeDist    = cfg3d.Distance or 3.0
            local actDist    = cfg3d.InteractDistance or 1.5
            local key        = cfg3d.Key or 38
            local keyLabel   = cfg3d.KeyLabel or '[E]'
            local font       = cfg3d.Font or 4
            local scale      = cfg3d.Scale or 0.35
            local color      = cfg3d.Color or { r = 255, g = 255, b = 255, a = 200 }

            local ped        = PlayerPedId()
            local pedCoords  = GetEntityCoords(ped)
            local nearestStash = nil
            local nearestDist  = math.huge

            for _, stash in ipairs(ClientStashes) do
                local stashCoords = vector3(stash.coords.x, stash.coords.y, stash.coords.z)
                local dist        = #(pedCoords - stashCoords)

                if dist < seeDist then
                    DrawText3D(
                        stash.coords.x,
                        stash.coords.y,
                        stash.coords.z + 1.1,
                        keyLabel .. ' ' .. stash.label,
                        font, scale,
                        color.r, color.g, color.b, color.a
                    )
                end

                if dist < actDist and dist < nearestDist then
                    nearestDist  = dist
                    nearestStash = stash
                end
            end

            if nearestStash and IsControlJustReleased(0, key) then
                OpenStashWithPassword(nearestStash)
            end

            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- ========================================
-- OPEN STASH WITH PASSWORD
-- ========================================

function OpenStashWithPassword(stash)
    -- Distance safety check
    local pedCoords   = GetEntityCoords(PlayerPedId())
    local stashCoords = vector3(stash.coords.x, stash.coords.y, stash.coords.z)

    if #(pedCoords - stashCoords) > 5.0 then
        Bridge.Notify(locale('notify_title'), locale('too_far'), 'error')
        return
    end

    local input = lib.inputDialog(locale('dialog_title'), {
        { type = 'input', label = locale('dialog_description'), required = true, password = true }
    })

    if not input or not input[1] or input[1] == '' then return end

    lib.callback('UniqueStash:OpenStash', false, function(result)
        if result and result.success then
            Bridge.Notify(locale('notify_title'), locale('stash_opened'), 'success')
            Bridge.OpenInventory(stash.stash_id)
        else
            Bridge.Notify(locale('notify_title'), locale('notify_description'), 'error')
        end
    end, stash.stash_id, input[1])
end

-- ========================================
-- CLIENT EVENTS: ZONE SYNC FROM SERVER
-- ========================================

-- New stash created by admin
RegisterNetEvent('UniqueStash:Client:AddZone', function(stash)
    -- Add to local cache
    local exists = false
    for _, s in ipairs(ClientStashes) do
        if s.stash_id == stash.stash_id then
            exists = true
            break
        end
    end

    if not exists then
        table.insert(ClientStashes, stash)
    end

    -- Register zone
    RegisterStashZone(stash)
end)

-- Stash updated by admin
RegisterNetEvent('UniqueStash:Client:UpdateZone', function(stash)
    -- Remove old zone
    UnregisterStashZone(stash.stash_id)

    -- Update cache
    for i, s in ipairs(ClientStashes) do
        if s.stash_id == stash.stash_id then
            ClientStashes[i] = stash
            break
        end
    end

    -- Re-register zone
    RegisterStashZone(stash)
end)

-- Stash deleted by admin
RegisterNetEvent('UniqueStash:Client:RemoveZone', function(stashId)
    -- Remove zone
    UnregisterStashZone(stashId)

    -- Remove from cache
    for i, s in ipairs(ClientStashes) do
        if s.stash_id == stashId then
            table.remove(ClientStashes, i)
            break
        end
    end
end)
