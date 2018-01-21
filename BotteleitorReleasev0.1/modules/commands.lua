local discordia = require("discordia")
local uv = require('uv')
local cspawn= require('coro-spawn')

local client = discordia.Client()
local voice = client.voice
local yield, resume, running = coroutine.yield, coroutine.resume, coroutine.running

--[[Modified methods]]
local emit = client.emit
--[[Variables]]
local connection = nil

local channelHistory = {}
local finished = false
local lastSearchResult = ''

local commandTable = {}

local function getInformation(url)
	local result = {}

	local stdout = uv.new_pipe(false)

	local child = uv.spawn('youtube-dl', {
			args = {url,'--get-duration','--get-title'},
			stdio = {0, stdout, 2}
	}, onExit)

	local thread = running()
		stdout:read_start(function(err, chunk)
			if err or not chunk then
				child:kill()
				stdout:read_stop()
				stdout:close()
				lastSearchResult = result
				assert(resume(thread))
			elseif #chunk > 0 then
				table.insert(result,chunk)
			end
	end)
	yield()
end

commandTable['help'] = function(_,msg)
	msg.channel:send("Não tem ajuda :)")
end

commandTable['join'] = function(_,msg)
	if msg.member.voiceChannel then 
		if msg.member.voiceChannel:join() then table.insert(channelHistory, msg.member.voiceChannel) else msg.channel:send("Não pude me conectar ao seu canal de aúdio") end
		
	else 
		msg.channel:send("Você não está em um canal de voz") 
	end
end

commandTable['playTest'] = function (_,msg)
	if msg.member.voiceChannel and connection then
		connection:playYoutube("https://www.youtube.com/watch?v=BwEZaariQQ4")
	elseif voice:getConnection() then connection = voice:getConnection()
		connection:playYoutube("https://www.youtube.com/watch?v=BwEZaariQQ4")
	else
		msg.channel:send("Não foi possível reproduzir a música")
	end
end

commandTable['play'] = function (_,msg)
	if msg.member.voiceChannel and msg.member.voiceChannel == channelHistory[1] then
			if not connection then 
				if voice:getConnection() then
					connection = voice:getConnection()
				end
			end
			if connection:isOccupied() then msg.channel:send("O bot está ocupado e uma função de queue ainda não foi implementada, por favor aguarde antes de pedir a música") return end
			local url = "https://www.youtube.com/watch?v="
			local _, start = string.find(msg.content,"v=")
			local id = string.sub(msg.content,start+1,start+11)
			url = url .. id
			getInformation(url)
			msg.channel:send {
				 embed = {
					   title = ("Pedido de música por " .. msg.author.username),
					    fields = {
				      		{name = "Título", value = lastSearchResult[1], inline = true},
				      		{name = "Duração", value = lastSearchResult[2], inline = true},
				    		},
				    		color = discordia.Color.fromRGB(114, 137, 218).value,
				    		timestamp = discordia.Date():toISO('T', 'Z')
						  	}
						}
			connection:playYoutube(url)
	else
		print("Either not on voice channel or is not in the same voice channel as the bot!")
	end
end


commandTable['stop'] = function(_,msg)
	if msg.member.voiceChannel then
		if connection then connection:stop() else msg.channel:send("? Não há conexões com canais de voz no momento, talvez você esteja brizando.") end
	end
end

commandTable['leave'] = function (_,msg)
	if msg.member.voiceChannel then
		if connection then connection:close() else 
			if voice:getConnection() then connection = voice:getConnection() connection:close() end
		end 
	end
end




return commandTable
