fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Wari'
description 'Made by: dyyykmetrpadesat'
version '1.0.0' -- NO MAIN UPDATES

dependencies {
    'ox_lib',
    'ox_inventory'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/cl.lua'
}

server_scripts {
    'server/sv.lua'
}
