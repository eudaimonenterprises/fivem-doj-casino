fx_version 'cerulean'
games      { 'gta5' }

lua54 'yes'

shared_scripts {
	'config/*.lua',
	'@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    '@qbx_core/shared/locale.lua',
}


client_scripts{
	'client/*.lua'
} 

server_scripts{
	'server/*.lua'
} 
