fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Assadi'
description 'MDT Burgershot Event Notifier'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

files {
    'ui/assets/bell.mp3',
    'ui/index.html',
    'ui/style.css',
    'ui/assets/logo.png',
}

ui_page 'ui/index.html'

server_script 'server.lua'
client_script 'client.lua'

dependency 'qb-core'
dependency 'ox_lib'
