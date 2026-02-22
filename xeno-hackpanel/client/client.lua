-- ============================================================
--  xeno-hackpanel | client/client.lua
--  Author: Xeno Shop
-- ============================================================

local isOpen       = false
local hackCallback = nil

-- ============================================================
--  Helpers
-- ============================================================

--- Build a table of enabled game definitions filtered by key list.
--- @param keys table  List of game-key strings (or nil = all enabled)
--- @return table
local function BuildGameList(keys)
    local list = {}

    if keys and #keys > 0 then
        for _, key in ipairs(keys) do
            local game = Config.HackGames[key]
            if game and game.enabled ~= false then
                list[#list + 1] = {
                    id          = key,
                    name        = game.name,
                    description = game.description,
                    difficulty  = game.difficulty,
                }
            end
        end
    else
        for key, game in pairs(Config.HackGames) do
            if game.enabled ~= false then
                list[#list + 1] = {
                    id          = key,
                    name        = game.name,
                    description = game.description,
                    difficulty  = game.difficulty,
                }
            end
        end
    end

    return list
end

--- Open the NUI panel and lock cursor + input focus.
--- @param payload table  Data forwarded to the React UI
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

--- Called by the React UI to request the current sound-enabled setting.
RegisterNUICallback('getConfig', function(_, cb)
    cb({
        soundEnabled = Config.UI.soundEnabled,
        closeKey     = Config.UI.closeKey,
    })
end)

-- ============================================================
--  Key Input – ESC closes the panel
-- ============================================================

CreateThread(function()
    while true do
        Wait(0)

        if isOpen and IsControlJustReleased(0, Config.UI.closeKey) then
            -- Let the NUI handle its own ESC; this is a safety fallback
            -- in case the JS layer misses it.
            SendNUIMessage({ action = 'escapeKey' })
        end
    end
end)

-- ============================================================
--  Exported API  –  exports['xeno-hackpanel']:StartHack(...)
-- ============================================================

--- Start one or more hacking mini-games.
---
--- @param options table
---   options.games      table|nil  List of game-key strings to include.
---                                 Pass nil / empty to include every enabled game.
---   options.title      string|nil Panel title override.
---   options.subtitle   string|nil Panel subtitle override.
---   options.timeLimit  number|nil Global time-limit override in seconds.
---   options.difficulty string|nil Force a difficulty filter ("easy","medium","hard","veryhard").
---   options.sequence   table|nil  Ordered list of game keys to play in sequence.
---                                 When set, games are played one-by-one; all must pass.
---
--- @param callback function  Called with (success: bool, data: table) when the session ends.
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

    -- Sequence mode: play an ordered list of specific games
    if options.sequence and #options.sequence > 0 then
        gameList = BuildGameList(options.sequence)
    -- Difficulty filter mode
    elseif options.difficulty then
        local keys = Config.GameCategories[string.lower(options.difficulty)]
        gameList = BuildGameList(keys)
    -- Explicit game list
    elseif options.games and #options.games > 0 then
        gameList = BuildGameList(options.games)
    -- Default: all enabled games
    else
        gameList = BuildGameList(nil)
    end

    if #gameList == 0 then
        if Config.Debug then
            print('[xeno-hackpanel] StartHack: no matching enabled games found.')
        end
        hackCallback = nil
        callback(false, { reason = 'no_games' })
        return
    end

    OpenPanel({
        games     = gameList,
        title     = options.title     or 'SYSTEM BREACH',
        subtitle  = options.subtitle  or 'INITIALISING HACK SEQUENCE',
        timeLimit = options.timeLimit or nil,
        sequence  = (options.sequence ~= nil and #options.sequence > 0),
    })
end)

-- ============================================================
--  Test Commands  (Config.TestCommands = true)
-- ============================================================

if Config.TestCommands then

    --- /testhack  – Opens the full panel with all enabled games.
    RegisterCommand('testhack', function()
        exports['xeno-hackpanel']:StartHack({}, function(success, data)
            local result = success and '^2[SUCCESS]^0' or '^1[FAILED]^0'
            print('[xeno-hackpanel] /testhack result: ' .. result)
            if Config.Debug then
                print(json.encode(data))
            end
        end)
    end, false)

    --- /testlockpick [difficulty] [timeLimit]
    RegisterCommand('testlockpick', function(_, args)
        local difficulty = args[1] or 'hard'
        local timeLimit  = tonumber(args[2]) or nil

        exports['xeno-hackpanel']:StartHack({
            games     = { 'lockpick' },
            title     = 'LOCKPICK TEST',
            subtitle  = 'AUDIO FREQUENCY BREACH',
            difficulty = difficulty,
            timeLimit  = timeLimit,
        }, function(success)
            local result = success and '^2[PICKED]^0' or '^1[FAILED]^0'
            print('[xeno-hackpanel] /testlockpick result: ' .. result)
        end)
    end, false)

    --- /testskillbar  – Opens the skill-bar game specifically.
    RegisterCommand('testskillbar', function()
        exports['xeno-hackpanel']:StartHack({
            games  = { 'circuitbreaker' },
            title  = 'SKILLBAR TEST',
            subtitle = 'CIRCUIT OVERRIDE',
        }, function(success)
            local result = success and '^2[SUCCESS]^0' or '^1[FAILED]^0'
            print('[xeno-hackpanel] /testskillbar result: ' .. result)
        end)
    end, false)

    --- /testhackeasy  – Easy games only.
    RegisterCommand('testhackeasy', function()
        exports['xeno-hackpanel']:StartHack({
            difficulty = 'easy',
            title      = 'EASY HACK TEST',
        }, function(success)
            print('[xeno-hackpanel] /testhackeasy result: ' .. (success and 'SUCCESS' or 'FAILED'))
        end)
    end, false)

    --- /testhackhard  – Hard games only.
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
        print('  /testhack | /testlockpick | /testskillbar')
        print('  /testhackeasy | /testhackhard | /testhacksequence')
    end
end
