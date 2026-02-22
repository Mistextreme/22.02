Config = {}

Config.CheckVersion = true
Config.Debug = true

-- Interaction Type: 'target', '3dtext'
Config.InteractionType = 'target'

-- Target Settings (ox_target)
Config.Target = {
    Distance = 1.5,
    Label = 'Stash',
    Icon = 'fa-solid fa-box'
}

-- 3D Text Settings
Config.Text3D = {
    Distance = 3.0,           -- Distance to see text
    InteractDistance = 1.5,   -- Distance to interact
    Key = 38,                 -- E key
    KeyLabel = '[E]',
    Font = 4,
    Scale = 0.35,
    Color = {r = 255, g = 255, b = 255, a = 200}
}

Config.Command = 'StashCreator'
Config.Keybind = 'F7'

Config.AdminGroups = {
    'developer',
    'admin'
}

Config.Webhooks = {
    stashOpen = "https://discord.com/api/webhooks/xxx",
    stashFail = "https://discord.com/api/webhooks/xxx",
    adminLog = "https://discord.com/api/webhooks/xxx"
}