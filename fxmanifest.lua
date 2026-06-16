fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'filo_blips'
author 'filo studios.'
discord 'https://discord.gg/bErPEKvRXg'
description 'Blip manager for FiveM — create personal and server-wide map blips in-game with full sprite, color, scale, and coordinate control.'
version '1.0.2'

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