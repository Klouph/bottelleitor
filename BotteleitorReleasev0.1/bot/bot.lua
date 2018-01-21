local discordia = require('discordia')
local logger = discordia.Logger(3, '%F %T')
local enums = discordia.enums

local log = logger.log

local loader = require('./loader')
local client = discordia.Client()
local utils = require('bot/utils')

client:on('ready', function()
	print('Logged in as '.. client.user.username)
	print("Bot v0.1")
end)

client:on('messageCreate', function(message)
	local cmd = isCommand(message.content)
	if cmd then
		local cmds = loader.commands
		if cmds and cmds[cmd[1]] then
			cmds[cmd[1]](cmd,message)
		end
	end
end)


client.voice:loadOpus()
client.voice:loadSodium()



client:run('Bot MzY1OTM4OTQ4NzgwMDY0Nzc5.DUahcg.3igwoaUwfzTsTYTFAAEqQtjk7sE')