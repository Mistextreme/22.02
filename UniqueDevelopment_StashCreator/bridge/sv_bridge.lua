BridgeServer = {}

-- ========================================
-- FRAMEWORK DETECTION (AUTOMATIC)
-- ========================================

local Framework = nil
local ESX = nil

if GetResourceState('es_extended') == 'started' then
    Framework = 'ESX'
    ESX = exports["es_extended"]:getSharedObject()
elseif GetResourceState('qbx_core') == 'started' then
    Framework = 'QBX'
elseif GetResourceState('qb-core') == 'started' then
    Framework = 'QB'
end

BridgeServer.Framework = Framework

-- ========================================
-- INVENTORY SETTINGS
-- ========================================
-- Supported inventories: 'ox_inventory', 'qb-inventory'
if GetResourceState('ox_inventory') == 'started' then
    BridgeServer.Inventory = 'ox_inventory'
elseif GetResourceState('qb-inventory') == 'started' then
    BridgeServer.Inventory = 'qb-inventory'
end

-- ========================================
-- FRAMEWORK FUNCTIONS
-- ========================================

function BridgeServer.GetPlayer(source)
    if Framework == 'ESX' then
        return ESX.GetPlayerFromId(source)
    
    elseif Framework == 'QBX' then
        return exports.qbx_core:GetPlayer(source)
    
    elseif Framework == 'QB' then
        local QBCore = exports['qb-core']:GetCoreObject()
        return QBCore.Functions.GetPlayer(source)
    
    -- ADD YOUR FRAMEWORK HERE:
    -- elseif Framework == 'your-framework' then
    --     return YourFramework.GetPlayer(source)
    end
    
    return nil
end

function BridgeServer.GetPlayerName(source)
    if Framework == 'ESX' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.getName() or 'Unknown'
    
    elseif Framework == 'QBX' then
        local player = BridgeServer.GetPlayer(source)
        if player and player.PlayerData then
            local charinfo = player.PlayerData.charinfo
            return charinfo.firstname .. ' ' .. charinfo.lastname
        end
    
    elseif Framework == 'QB' then
        local player = BridgeServer.GetPlayer(source)
        if player then
            local charinfo = player.PlayerData.charinfo
            return charinfo.firstname .. ' ' .. charinfo.lastname
        end
    
    -- ADD YOUR FRAMEWORK HERE:
    -- elseif Framework == 'your-framework' then
    --     return YourFramework.GetPlayerName(source)
    end
    
    return 'Unknown'
end

function BridgeServer.GetPlayerIdentifier(source)
    if Framework == 'ESX' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.getIdentifier() or 'Unknown'
    
    elseif Framework == 'QBX' then
        local player = BridgeServer.GetPlayer(source)
        if player and player.PlayerData then
            return player.PlayerData.citizenid
        end
    
    elseif Framework == 'QB' then
        local player = BridgeServer.GetPlayer(source)
        if player then
            return player.PlayerData.citizenid
        end
    
    -- ADD YOUR FRAMEWORK HERE:
    -- elseif Framework == 'your-framework' then
    --     return YourFramework.GetIdentifier(source)
    end
    
    return 'Unknown'
end

function BridgeServer.IsAdmin(source)
    -- First check ACE permissions (works for all frameworks)
    if IsPlayerAceAllowed(source, 'command.stashadmin') then
        return true
    end
    
    if Framework == 'ESX' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        
        local group = xPlayer.getGroup()
        for _, adminGroup in ipairs(Config.AdminGroups) do
            if group == adminGroup then
                return true
            end
        end
    
    elseif Framework == 'QBX' then
        for _, adminGroup in ipairs(Config.AdminGroups) do
            if exports.qbx_core:HasGroup(source, adminGroup) then
                return true
            end
        end
    
    elseif Framework == 'QB' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            for _, adminGroup in ipairs(Config.AdminGroups) do
                if QBCore.Functions.HasPermission(source, adminGroup) then
                    return true
                end
            end
        end
    
    -- ADD YOUR FRAMEWORK HERE:
    -- elseif Framework == 'your-framework' then
    --     return YourFramework.IsAdmin(source)
    end
    
    return false
end

-- ========================================
-- STASH REGISTRATION
-- ========================================

function BridgeServer.RegisterStash(stashId, label, slots, weight, coords)
    if BridgeServer.Inventory == 'ox_inventory' then
        exports.ox_inventory:RegisterStash(stashId, label, slots, weight, nil, nil, coords)
    
    elseif BridgeServer.Inventory == 'qb-inventory' then
        
    -- ADD YOUR INVENTORY HERE:
    -- elseif BridgeServer.Inventory == 'your-inventory' then
    --     -- Your code here
    
    else
        print('^1[Bridge Error]^0 Unknown inventory: ' .. BridgeServer.Inventory)
    end
end

-- ========================================
-- OPEN STASH
-- ========================================

function BridgeServer.OpenStash(source, stashId, label, slots, weight)
    if BridgeServer.Inventory == 'ox_inventory' then
        exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
    
    elseif BridgeServer.Inventory == 'qb-inventory' then
        local data = {
            label = label or stashId,
            maxweight = weight or 100000,
            slots = slots or 50
        }
        exports['qb-inventory']:OpenInventory(source, stashId, data)
    end
end

-- ========================================
-- CLEAR STASH INVENTORY
-- ========================================

function BridgeServer.ClearStashInventory(stashId)
    if BridgeServer.Inventory == 'ox_inventory' then
        exports.ox_inventory:ClearInventory(stashId)
    
    elseif BridgeServer.Inventory == 'qb-inventory' then

    -- ADD YOUR INVENTORY HERE:
    -- elseif BridgeServer.Inventory == 'your-inventory' then
    --     -- Your code here
    end
end

-- ========================================
-- SET MAX WEIGHT
-- ========================================

function BridgeServer.SetMaxWeight(stashId, weight)
    if BridgeServer.Inventory == 'ox_inventory' then
        exports.ox_inventory:SetMaxWeight(stashId, weight)
    end
end

-- ========================================
-- INSPECT INVENTORY
-- ========================================

function BridgeServer.InspectInventory(source, stashId)
    if BridgeServer.Inventory == 'ox_inventory' then
        exports.ox_inventory:InspectInventory(source, stashId) -- exports.ox_inventory:forceOpenInventory(source, 'stash', stashId) for openmode
    elseif BridgeServer.Inventory == 'qb-inventory' then
       exports['qb-inventory']:OpenInventory(source, stashId)
    end
end