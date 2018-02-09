local music = require('modules/Music/music')


local uv = require('uv')



local yield, resume, running = coroutine.yield, coroutine.resume, coroutine.running

local Command = {
	commandTable = {},
}

Command.commandTable['help'] = function(msg)
	msg.channel:send("Não tem ajuda :)")
end



local function play(msg)
	local url,errors = music:getUrl(msg.content)
	local requester = msg.author
	local channel = msg.channel
	local voiceChannel = msg.member.voiceChannel

	if not voiceChannel then channel:send("`Error: Cannot insert music in queue | Reason: User not in Voice Channel`") return false end
	if not url then channel:send("`Error: Cannot insert music in queue | Reason: Could not find youtube video id on given arguments: content| "..errors.."`") return false end

	local info, err = music:getInformation(url)
	if not info[1] then channel:send("`Error: Youtube-dl could not get information on given url, please check if its a valid url. Or the given video can't be accessed by the bot`") return false
	else 	
		channel:send("`Music added to queue at position "..music:addToQueue(url,requester,info,channel,voiceChannel).."`")
	end
end

Command.commandTable['play'] = play
Command.commandTable['ply'] = play
Command.commandTable['paly'] = play
Command.commandTable['plya'] = play

Command.commandTable['playTest'] = function(msg)
	msg.member.voiceChannel:join()
	music:playTest()
end


Command.commandTable['skip'] = function(msg)
	if not music:skip() then msg.channel:send("`Error: nothing to skip you dummy`") end
end

function Command:init(disc,client)
	self.discordia = disc
	self.client = client
	music:init(disc,client)
end

function Command:run(command,msg)
	if self.commandTable[command] then self.commandTable[command](msg) return true
	else
		return false
	end
	
end



return Command
