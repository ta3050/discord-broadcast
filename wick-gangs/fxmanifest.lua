fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'wick-gangs'
author 'Wick Studio'
description 'Lightweight ESX gangs: tablet, full summon, rankings, blips, spray'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

shared_scripts {
    'config.lua',
    'locales/en.lua',
    'locales/ar.lua',
    'shared/locale.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua',
    'client/spray.lua',
    'client/blips.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/schema.lua',
    'server/main.lua',
    'server/sprays.lua'
}

dependencies {
    'es_extended',
    'oxmysql'
}
