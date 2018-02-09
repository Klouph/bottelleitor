local discordia = require('discordia')
local logger = discordia.Logger(3, '%F %T')
local enums = discordia.enums

local log = logger.log

local client = discordia.Client()
local cmds = require('modules/commands')
local utils = require('bot/utils')

client:on('ready', function()
	print('Logged in as '.. client.user.username)
	cmds:init(discordia,client)
	discordia.utils = utils
	print("Bot v0.1")
end)

client:on('messageCreate', function(message)
	local cmd = utils:isCommand(message.content)
	if cmd then
		if not (cmds:run(cmd[1],message)) then
			message.channel:send("`Command does not exist, for a list of commands use the help command`")
		end 
	end
end)



client.voice:loadOpus()
client.voice:loadSodium()



client:run('Bot MzY1OTM4OTQ4NzgwMDY0Nzc5.DUsQWw.cNZ0vAHsCDh9HuyqFWLl-Qn4zR8')