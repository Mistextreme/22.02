fx_version 'cerulean'
game 'gta5'

author 'Xeno Shop'
description 'Advanced Hacking Panel System with Multiple Mini-Games'
version '1.0.0'

ui_page 'web/dist/index.html'

escrow_ignore {
    'config.lua',
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    'server/server.lua'
}

files {
    'web/dist/index.html',
    'web/dist/**/*'
}

exports {
    'StartHack'
}

server_exports {
    'RegisterHackGame',
    'UnregisterHackGame'
}

dependency '/assetpacks'