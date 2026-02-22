Bridge = {}

-- ========================================
-- INVENTORY SETTINGS
-- ========================================
-- Supported inventories: 'ox_inventory', 'qb-inventory'
-- If you use a different inventory, add it below

if GetResourceState('ox_inventory') == 'started' then
    Bridge.Inventory = 'ox_inventory'
elseif GetResourceState('qb-inventory') == 'started' then
    Bridge.Inventory = 'qb-inventory'
-- ADD YOUR INVENTORY HERE:
-- elseif GetResourceState('your-inventory') == 'started' then
--     Bridge.Inventory = 'your-inventory'
else
    Bridge.Inventory = 'unknown'
end

-- ========================================
-- TARGET SETTINGS
-- ========================================
-- Supported targets: 'ox_target', 'qb-target'
-- If you use a different target, add it below
if GetResourceState('ox_target') == 'started' then
    Bridge.Target = 'ox_target'
elseif GetResourceState('qb-target') == 'started' then
    Bridge.Target = 'qb-target'
-- ADD YOUR TARGET HERE:
-- elseif GetResourceState('your-target') == 'started' then
--     Bridge.Target = 'your-target'
else
    Bridge.Target = 'unknown'
end

-- ========================================
-- INVENTORY FUNCTIONS
-- ========================================

function Bridge.OpenInventory(stashId)
    if Bridge.Inventory == 'ox_inventory' then
        exports.ox_inventory:openInventory('stash', stashId)
    
    elseif Bridge.Inventory == 'qb-inventory' then
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId)
        TriggerEvent('inventory:client:SetCurrentStash', stashId)
    
    -- ADD YOUR INVENTORY HERE:
    -- elseif Bridge.Inventory == 'your-inventory' then
    --     -- Your code here
    
    else
        print('^1[Bridge Error]^0 Unknown inventory: ' .. Bridge.Inventory)
    end
end

-- ========================================
-- TARGET FUNCTIONS
-- ========================================

local registeredZones = {}

function Bridge.AddBoxZone(data)
    local zoneId = nil
    
    if Bridge.Target == 'ox_target' then
        zoneId = exports.ox_target:addBoxZone({
            coords = data.coords,
            size = data.size,
            rotation = data.rotation or 0.0,
            debug = data.debug or false,
            options = {
                {
                    icon = data.icon,
                    label = data.label,
                    distance = data.distance,
                    onSelect = data.onSelect
                }
            }
        })
    
    elseif Bridge.Target == 'qb-target' then
        local zoneName = 'stash_' .. #registeredZones + 1
        exports['qb-target']:AddBoxZone(zoneName, data.coords, data.size.x, data.size.y, {
            name = zoneName,
            heading = data.rotation or 0.0,
            debugPoly = data.debug or false,
            minZ = data.coords.z - (data.size.z / 2),
            maxZ = data.coords.z + (data.size.z / 2),
        }, {
            options = {
                {
                    icon = data.icon,
                    label = data.label,
                    action = data.onSelect
                }
            },
            distance = data.distance
        })
        zoneId = zoneName
    
    -- ADD YOUR TARGET HERE:
    -- elseif Bridge.Target == 'your-target' then
    --     -- Your code here
    --     zoneId = 'something'
    
    else
        print('^1[Bridge Error]^0 Unknown target: ' .. Bridge.Target)
    end
    
    if zoneId then
        table.insert(registeredZones, zoneId)
    end
    
    return zoneId
end

function Bridge.RemoveZone(zoneId)
    if Bridge.Target == 'ox_target' then
        exports.ox_target:removeZone(zoneId)
    
    elseif Bridge.Target == 'qb-target' then
        exports['qb-target']:RemoveZone(zoneId)
    
    -- ADD YOUR TARGET HERE:
    -- elseif Bridge.Target == 'your-target' then
    --     -- Your code here
    end
end

function Bridge.ClearAllZones()
    for _, zoneId in ipairs(registeredZones) do
        Bridge.RemoveZone(zoneId)
    end
    registeredZones = {}
end

function Bridge.GetRegisteredZones()
    return registeredZones
end

-- ========================================
-- NOTIFICATIONS
-- ========================================

function Bridge.Notify(title, message, type)
    lib.notify({
        title = title,
        description = message,
        type = type,
        duration = 5000
    })
    
    -- If you want QBCore notifications, uncomment below:
    -- TriggerEvent('QBCore:Notify', message, type)
end