-- ============================================================
--  xeno-hackpanel | server/server.lua
--  Author: Xeno Shop
-- ============================================================

-- ============================================================
--  Runtime game registry
--  Other resources can add or remove games at runtime using
--  the server exports RegisterHackGame / UnregisterHackGame.
-- ============================================================

local customGames = {}

-- ============================================================
--  Utility
-- ============================================================

--- Validate that a game definition table contains the required fields.
--- @param gameId   string
--- @param gameDef  table
--- @return boolean, string|nil  (valid, errorMessage)
local function ValidateGameDef(gameId, gameDef)
    if type(gameId) ~= 'string' or gameId == '' then
        return false, 'gameId must be a non-empty string'
    end

    if type(gameDef) ~= 'table' then
        return false, 'gameDef must be a table'
    end

    if type(gameDef.name) ~= 'string' or gameDef.name == '' then
        return false, 'gameDef.name must be a non-empty string'
    end

    local validDifficulties = {
        easy     = true,
        Easy     = true,
        medium   = true,
        Medium   = true,
        hard     = true,
        Hard     = true,
        veryhard = true,
        ['Very Hard'] = true,
        VeryHard = true,
    }

    if gameDef.difficulty and not validDifficulties[gameDef.difficulty] then
        return false, 'gameDef.difficulty must be one of: easy, medium, hard, veryhard'
    end

    return true, nil
end

-- ============================================================
--  Server Exports
-- ============================================================

--- Register a new custom hack-game from an external resource.
---
--- @param gameId  string  Unique identifier for the game (e.g. 'mygame').
---                        Must not collide with a built-in game key in Config.HackGames.
--- @param gameDef table   Game definition:
---                          name        string   Display name shown in the UI.
---                          description string   Short description (optional).
---                          difficulty  string   "easy" | "medium" | "hard" | "veryhard"
---                          enabled     boolean  Whether the game is active (default true).
---
--- @return boolean, string  (success, message)
exports('RegisterHackGame', function(gameId, gameDef)
    local valid, err = ValidateGameDef(gameId, gameDef)

    if not valid then
        print(string.format('[xeno-hackpanel] RegisterHackGame FAILED for "%s": %s', tostring(gameId), err))
        return false, err
    end

    -- Prevent overwriting built-in games defined in config.lua
    if Config.HackGames[gameId] then
        local msg = string.format(
            '[xeno-hackpanel] RegisterHackGame FAILED: "%s" already exists as a built-in game.',
            gameId
        )
        print(msg)
        return false, 'game_id_reserved'
    end

    customGames[gameId] = {
        name        = gameDef.name,
        description = gameDef.description or '',
        difficulty  = gameDef.difficulty  or 'medium',
        enabled     = (gameDef.enabled ~= false), -- default true
        custom      = true,
    }

    if Config.Debug then
        print(string.format('[xeno-hackpanel] RegisterHackGame: registered "%s" (%s)', gameId, gameDef.name))
    end

    -- Notify all clients so they can update their local game lists
    TriggerClientEvent('xeno-hackpanel:gameRegistered', -1, gameId, customGames[gameId])

    return true, 'ok'
end)

--- Unregister a previously registered custom hack-game.
---
--- @param gameId string  The id that was used when calling RegisterHackGame.
--- @return boolean, string  (success, message)
exports('UnregisterHackGame', function(gameId)
    if type(gameId) ~= 'string' or gameId == '' then
        print('[xeno-hackpanel] UnregisterHackGame FAILED: gameId must be a non-empty string')
        return false, 'invalid_id'
    end

    if not customGames[gameId] then
        if Config.Debug then
            print(string.format('[xeno-hackpanel] UnregisterHackGame: "%s" not found in custom registry', gameId))
        end
        return false, 'not_found'
    end

    customGames[gameId] = nil

    if Config.Debug then
        print(string.format('[xeno-hackpanel] UnregisterHackGame: removed "%s"', gameId))
    end

    -- Notify all clients so they can drop the game from their local list
    TriggerClientEvent('xeno-hackpanel:gameUnregistered', -1, gameId)

    return true, 'ok'
end)

--- Return all currently registered custom games (read-only snapshot).
--- Useful for other server-side resources that need to enumerate available games.
---
--- @return table  Map of gameId -> gameDef
exports('GetCustomGames', function()
    local snapshot = {}
    for k, v in pairs(customGames) do
        snapshot[k] = v
    end
    return snapshot
end)

-- ============================================================
--  Server Events
-- ============================================================

--- A client can request the full custom-game registry (e.g. on resource start).
RegisterNetEvent('xeno-hackpanel:requestCustomGames', function()
    local src = source
    TriggerClientEvent('xeno-hackpanel:syncCustomGames', src, customGames)
end)

-- ============================================================
--  Resource lifecycle
-- ============================================================

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if Config.Debug then
        print('[xeno-hackpanel] Server started.')
        print(string.format('[xeno-hackpanel] Built-in games loaded: %d', (function()
            local n = 0
            for _ in pairs(Config.HackGames) do n = n + 1 end
            return n
        end)()))
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Clear custom game registry on stop
    customGames = {}

    if Config.Debug then
        print('[xeno-hackpanel] Server stopped. Custom game registry cleared.')
    end
end)
