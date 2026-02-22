-- ============================================================
--  xeno-hackpanel | server/server.lua
--  Author: Xeno Shop
-- ============================================================

-- ============================================================
--  Runtime game registry
--  Other resources can add or remove games at runtime via:
--    exports['xeno-hackpanel']:RegisterHackGame(id, def)
--    exports['xeno-hackpanel']:UnregisterHackGame(id)
--    exports['xeno-hackpanel']:GetCustomGames()
--
--  NOTE: GetCustomGames is not listed in fxmanifest.lua under
--  server_exports. Add it there if external resources need it:
--    server_exports { 'RegisterHackGame', 'UnregisterHackGame', 'GetCustomGames' }
-- ============================================================

local customGames = {}

-- ============================================================
--  Utility
-- ============================================================

--- Validate that a game definition table contains the required fields.
--- @param gameId  string
--- @param gameDef table
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

    -- Accept both capitalised and lowercase variants to match config.lua style
    local validDifficulties = {
        easy        = true,
        Easy        = true,
        medium      = true,
        Medium      = true,
        hard        = true,
        Hard        = true,
        veryhard    = true,
        ['Very Hard'] = true,
        VeryHard    = true,
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
--- gameId   string  Unique identifier (e.g. 'mygame').
---                  Must not collide with a built-in key in Config.HackGames.
--- gameDef  table   {
---                    name        string   Display name shown in the UI.
---                    description string   Short description (optional).
---                    difficulty  string   "easy"|"medium"|"hard"|"veryhard"
---                    enabled     boolean  Active by default (default: true).
---                  }
---
--- Returns: boolean success, string message
exports('RegisterHackGame', function(gameId, gameDef)
    local valid, err = ValidateGameDef(gameId, gameDef)

    if not valid then
        print(string.format(
            '[xeno-hackpanel] RegisterHackGame FAILED for "%s": %s',
            tostring(gameId), err
        ))
        return false, err
    end

    -- Prevent overwriting built-in games defined in config.lua
    if Config.HackGames[gameId] then
        print(string.format(
            '[xeno-hackpanel] RegisterHackGame FAILED: "%s" is a reserved built-in game id.',
            gameId
        ))
        return false, 'game_id_reserved'
    end

    -- Also prevent double-registration of custom games
    if customGames[gameId] then
        print(string.format(
            '[xeno-hackpanel] RegisterHackGame FAILED: "%s" is already registered as a custom game.',
            gameId
        ))
        return false, 'game_id_duplicate'
    end

    customGames[gameId] = {
        name        = gameDef.name,
        description = gameDef.description or '',
        difficulty  = gameDef.difficulty  or 'medium',
        enabled     = (gameDef.enabled ~= false), -- default true
        custom      = true,
    }

    if Config.Debug then
        print(string.format(
            '[xeno-hackpanel] RegisterHackGame: registered "%s" (%s)',
            gameId, gameDef.name
        ))
    end

    -- Push the new game definition to all connected clients immediately
    TriggerClientEvent('xeno-hackpanel:gameRegistered', -1, gameId, customGames[gameId])

    return true, 'ok'
end)

--- Unregister a previously registered custom hack-game.
---
--- gameId  string  The id that was used when calling RegisterHackGame.
---
--- Returns: boolean success, string message
exports('UnregisterHackGame', function(gameId)
    if type(gameId) ~= 'string' or gameId == '' then
        print('[xeno-hackpanel] UnregisterHackGame FAILED: gameId must be a non-empty string')
        return false, 'invalid_id'
    end

    if not customGames[gameId] then
        if Config.Debug then
            print(string.format(
                '[xeno-hackpanel] UnregisterHackGame: "%s" not found in custom registry',
                gameId
            ))
        end
        return false, 'not_found'
    end

    customGames[gameId] = nil

    if Config.Debug then
        print(string.format('[xeno-hackpanel] UnregisterHackGame: removed "%s"', gameId))
    end

    -- Notify all connected clients to drop the game from their local list
    TriggerClientEvent('xeno-hackpanel:gameUnregistered', -1, gameId)

    return true, 'ok'
end)

--- Return a read-only snapshot of all currently registered custom games.
--- Useful for server-side resources that need to enumerate available games.
---
--- Returns: table  Map of gameId -> gameDef
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

--- A client requests the full custom-game registry.
--- Fired automatically by the client on resource start (onClientResourceStart).
RegisterNetEvent('xeno-hackpanel:requestCustomGames')
AddEventHandler('xeno-hackpanel:requestCustomGames', function()
    local src = source
    if src and src > 0 then
        TriggerClientEvent('xeno-hackpanel:syncCustomGames', src, customGames)
    end
end)

-- ============================================================
--  Resource lifecycle
-- ============================================================

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if Config.Debug then
        local n = 0
        for _ in pairs(Config.HackGames) do n = n + 1 end
        print(string.format(
            '[xeno-hackpanel] Server started. Built-in games: %d | Custom games: 0',
            n
        ))
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    -- Clear the runtime registry; server exports from other resources
    -- must re-register their games when this resource restarts.
    customGames = {}

    if Config.Debug then
        print('[xeno-hackpanel] Server stopped. Custom game registry cleared.')
    end
end)
