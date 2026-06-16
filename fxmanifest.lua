fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'filo_blips'
author 'filo studios.'
discord 'https://discord.gg/bErPEKvRXg'
description 'Blip manager'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/sh-*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv-*.lua'
}

client_scripts {
    'client/cl-*.lua'
}

dependencies {
    'community_bridge'
}