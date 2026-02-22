-- ============================================================
--  xeno-hackpanel | client/client.lua
--  Author: Xeno Shop
-- ============================================================

local isOpen       = false
local hackCallback = nil

-- Runtime custom-game registry (populated by server events)
local customGames  = {}

-- ============================================================
--  Helpers
-- ============================================================

--- Build a table of game definitions.
---
--- When explicit keys are supplied the enabled flag is intentionally ignored:
--- if a caller asks for a specific game by id it should always be returned
--- regardless of the enabled = false default in config.
---
--- When no keys are supplied (bulk / difficulty mode) the enabled flag IS
--- respected so disabled games are excluded from random selections.
---
--- @param keys          table|nil  Ordered list of game-key strings, or nil for all.
--- @param respectEnabled boolean   Pass true to honour the enabled flag (bulk mode).
--- @return table
local function BuildGameList(keys, respectEnabled)
    local list = {}

    -- Helper: build a single entry from a game definition.
    local function makeEntry(key, game)
        return {
            id          = key,
            name        = game.name,
            description = game.description,
            difficulty  = game.difficulty,
        }
    end

    if keys and #keys > 0 then
        -- Explicit key list: check built-in games first, then custom registry.
        -- enabled flag is NOT checked here; explicit requests always succeed.
        for _, key in ipairs(keys) do
            local game = Config.HackGames[key] or customGames[key]
            if game then
                list[#list + 1] = makeEntry(key, game)
            elseif Config.Debug then
                print(string.format('[xeno-hackpanel] BuildGameList: unknown game key "%s"', key))
            end
        end
    else
        -- Bulk mode: iterate built-in games, honour enabled flag.
        for key, game in pairs(Config.HackGames) do
            if not respectEnabled or game.enabled ~= false then
                list[#list + 1] = makeEntry(key, game)
            end
        end
        -- Also include any enabled custom games.
        for key, game in pairs(customGames) do
            if not respectEnabled or game.enabled ~= false then
                list[#list + 1] = makeEntry(key, game)
            end
        end
    end

    return list
end

--- Open the NUI panel and lock cursor + input focus.
--- @param payload table  Data forwarded to the React UI.
local function OpenPanel(payload)
    if isOpen then return end
    isOpen = true

    SetNuiFocus(true, true)

    SendNUIMessage({
        action  = 'openPanel',
        payload = payload,
        ui      = Config.UI,
    })
end

--- Close the NUI panel and release focus.
local function ClosePanel()
    if not isOpen then return end
    isOpen = false

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'closePanel',
    })
end

-- ============================================================
--  NUI Callbacks
-- ============================================================

--- Called by the React UI when the player successfully completes a hack.
RegisterNUICallback('hackSuccess', function(data, cb)
    cb('ok')
    ClosePanel()

    if hackCallback then
        local fn = hackCallback
        hackCallback = nil
        fn(true, data)
    end
end)

--- Called by the React UI when the player fails a hack (time-out or wrong input).
RegisterNUICallback('hackFail', function(data, cb)
    cb('ok')
    ClosePanel()

    if hackCallback then
        local fn = hackCallback
        hackCallback = nil
        fn(false, data)
    end
end)

--- Called by the React UI when the player presses ESC / close button.
RegisterNUICallback('hackClose', function(data, cb)
    cb('ok')
    ClosePanel()

    if hackCallback then
        local fn = hackCallback
        hackCallback = nil
        fn(false, data)
    end
end)

--- Called by the React UI to request the current sound and key config.
RegisterNUICallback('getConfig', function(_, cb)
    cb({
        soundEnabled = Config.UI.soundEnabled,
        closeKey     = Config.UI.closeKey,
    })
end)

-- ============================================================
--  Key Input – ESC closes the panel (safety fallback)
-- ============================================================

CreateThread(function()
    while true do
        -- Poll cheaply when closed; tighten the loop only while panel is open.
        if isOpen then
            Wait(0)
            if IsControlJustReleased(0, Config.UI.closeKey) then
                -- Notify the NUI layer; the JS handler will fire hackClose.
                SendNUIMessage({ action = 'escapeKey' })
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================================
--  Custom Game Sync (server → client)
-- ============================================================

--- Full sync: server sends the entire customGames table on request.
RegisterNetEvent('xeno-hackpanel:syncCustomGames', function(games)
    customGames = games or {}
    if Config.Debug then
        local n = 0
        for _ in pairs(customGames) do n = n + 1 end
        print(string.format('[xeno-hackpanel] Synced %d custom game(s) from server.', n))
    end
end)

--- Incremental add: a new custom game was registered server-side.
RegisterNetEvent('xeno-hackpanel:gameRegistered', function(gameId, gameDef)
    customGames[gameId] = gameDef
    if Config.Debug then
        print(string.format('[xeno-hackpanel] Custom game registered: "%s"', gameId))
    end
end)

--- Incremental remove: a custom game was unregistered server-side.
RegisterNetEvent('xeno-hackpanel:gameUnregistered', function(gameId)
    customGames[gameId] = nil
    if Config.Debug then
        print(string.format('[xeno-hackpanel] Custom game unregistered: "%s"', gameId))
    end
end)

--- On resource start, request the current custom-game snapshot from the server.
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TriggerServerEvent('xeno-hackpanel:requestCustomGames')
end)

-- ============================================================
--  Exported API  –  exports['xeno-hackpanel']:StartHack(...)
-- ============================================================

--- Start one or more hacking mini-games.
---
--- @param options table
---   options.games      table|nil  Explicit list of game-key strings to show.
---                                 Ignores the enabled flag — use this to always
---                                 launch a specific game regardless of config.
---   options.title      string|nil Panel title override.
---   options.subtitle   string|nil Panel subtitle override.
---   options.timeLimit  number|nil Global time-limit override in seconds.
---   options.difficulty string|nil Bulk-mode difficulty filter; only includes
---                                 enabled games in that category.
---                                 ("easy" | "medium" | "hard" | "veryhard")
---   options.sequence   table|nil  Ordered list of game keys to play one-by-one.
---                                 All games must be completed for success.
---                                 Ignores the enabled flag (explicit keys).
---
--- @param callback function  Called with (success: bool, data: table) on finish.
exports('StartHack', function(options, callback)
    if isOpen then
        if Config.Debug then
            print('[xeno-hackpanel] StartHack called while panel is already open.')
        end
        return
    end

    options  = options  or {}
    callback = callback or function() end

    hackCallback = callback

    local gameList

    -- Priority 1: sequence mode (explicit ordered keys, enabled ignored)
    if options.sequence and #options.sequence > 0 then
        gameList = BuildGameList(options.sequence, false)

    -- Priority 2: difficulty bulk filter (enabled flag IS respected)
    elseif options.difficulty then
        local categoryKey = string.lower(options.difficulty)
        -- Normalise "veryhard" / "very hard" variants
        categoryKey = categoryKey:gsub('%s+', '')
        local keys = Config.GameCategories[categoryKey]
        gameList = BuildGameList(keys, true)

    -- Priority 3: explicit game list (enabled ignored)
    elseif options.games and #options.games > 0 then
        gameList = BuildGameList(options.games, false)

    -- Priority 4: all enabled games
    else
        gameList = BuildGameList(nil, true)
    end

    if #gameList == 0 then
        if Config.Debug then
            print('[xeno-hackpanel] StartHack: no matching games found. '
                .. 'Hint: ensure the requested game keys exist and, for bulk '
                .. 'mode, that at least one game has enabled = true in config.')
        end
        hackCallback = nil
        callback(false, { reason = 'no_games' })
        return
    end

    OpenPanel({
        games     = gameList,
        title     = options.title    or 'SYSTEM BREACH',
        subtitle  = options.subtitle or 'INITIALISING HACK SEQUENCE',
        timeLimit = options.timeLimit or nil,
        sequence  = (options.sequence ~= nil and #options.sequence > 0),
    })
end)

-- ============================================================
--  Test Commands  (Config.TestCommands = true)
-- ============================================================

if Config.TestCommands then

    --- /testhack  – Opens the full panel with ALL games (enabled flag ignored).
    RegisterCommand('testhack', function()
        -- Pass explicit list of all built-in keys so enabled = false is bypassed.
        local allKeys = {}
        for key in pairs(Config.HackGames) do
            allKeys[#allKeys + 1] = key
        end
        for key in pairs(customGames) do
            allKeys[#allKeys + 1] = key
        end

        exports['xeno-hackpanel']:StartHack({
            games    = allKeys,
            title    = 'FULL HACK TEST',
            subtitle = 'ALL MODULES LOADED',
        }, function(success, data)
            local result = success and '^2[SUCCESS]^0' or '^1[FAILED]^0'
            print('[xeno-hackpanel] /testhack result: ' .. result)
            if Config.Debug then
                print(json.encode(data))
            end
        end)
    end, false)

    --- /testlockpick [timeLimit]
    --- Tests only the audio lockpick game. Optional arg sets time limit in seconds.
    RegisterCommand('testlockpick', function(_, args)
        local timeLimit = tonumber(args[1]) or nil

        exports['xeno-hackpanel']:StartHack({
            games     = { 'lockpick' },
            title     = 'LOCKPICK TEST',
            subtitle  = 'AUDIO FREQUENCY BREACH',
            timeLimit = timeLimit,
        }, function(success)
            local result = success and '^2[PICKED]^0' or '^1[FAILED]^0'
            print('[xeno-hackpanel] /testlockpick result: ' .. result)
        end)
    end, false)

    --- /testskillbar  – Opens the circuitbreaker (skill-bar style) game.
    RegisterCommand('testskillbar', function()
        exports['xeno-hackpanel']:StartHack({
            games    = { 'circuitbreaker' },
            title    = 'SKILLBAR TEST',
            subtitle = 'CIRCUIT OVERRIDE',
        }, function(success)
            local result = success and '^2[SUCCESS]^0' or '^1[FAILED]^0'
            print('[xeno-hackpanel] /testskillbar result: ' .. result)
        end)
    end, false)

    --- /testhackeasy  – All easy-category games (only those with enabled = true).
    RegisterCommand('testhackeasy', function()
        exports['xeno-hackpanel']:StartHack({
            difficulty = 'easy',
            title      = 'EASY HACK TEST',
        }, function(success)
            print('[xeno-hackpanel] /testhackeasy result: ' .. (success and 'SUCCESS' or 'FAILED'))
        end)
    end, false)

    --- /testhackhard  – All hard-category games (only those with enabled = true).
    RegisterCommand('testhackhard', function()
        exports['xeno-hackpanel']:StartHack({
            difficulty = 'hard',
            title      = 'HARD HACK TEST',
        }, function(success)
            print('[xeno-hackpanel] /testhackhard result: ' .. (success and 'SUCCESS' or 'FAILED'))
        end)
    end, false)

    --- /testhacksequence  – Plays flappybypass → lockpick → reaction in sequence.
    RegisterCommand('testhacksequence', function()
        exports['xeno-hackpanel']:StartHack({
            sequence = { 'flappybypass', 'lockpick', 'reaction' },
            title    = 'SEQUENCE TEST',
            subtitle = 'MULTI-STAGE BREACH',
        }, function(success)
            print('[xeno-hackpanel] /testhacksequence result: ' .. (success and 'ALL PASSED' or 'SEQUENCE BROKEN'))
        end)
    end, false)

    if Config.Debug then
        print('[xeno-hackpanel] Test commands registered:')
        print('  /testhack | /testlockpick [timeLimit] | /testskillbar')
        print('  /testhackeasy | /testhackhard | /testhacksequence')
    end
end
