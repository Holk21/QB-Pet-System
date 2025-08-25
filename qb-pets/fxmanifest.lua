fx_version 'cerulean'
game 'gta5'

name 'qb-pets'
author 'Braiden Marshall'
description 'QBCore Pets & Pet Shop with NUI'
version '1.0.0'

ui_page 'html/index.html'

files {
  'html/index.html',
  'html/style.css',
  'html/script.js'
}

shared_scripts {
  '@qb-core/shared/locale.lua',
  'config.lua'
}

client_scripts {
  'client/main.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/main.lua'
}
