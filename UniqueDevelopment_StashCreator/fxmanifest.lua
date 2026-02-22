fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'UniqueDevelopment'
description 'Stashes'
version "1.0.0"

client_scripts {
    'bridge/cl_bridge.lua',
    'client/client.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/sv_bridge.lua',
    'server/config.lua',
    'server/database.lua',
    'server/sv_version.lua',
    'server/main.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
}

ui_page 'web/index.html'

files {
    'locales/*.json',
    'web/index.html',
    'web/style.css',
    'web/script.js'
}

escrow_ignore {
    'bridge/cl_bridge.lua',
    'bridge/sv_bridge.lua',
    'server/config.lua',
    'locales/*.json',
}
dependency '/assetpacks'