local uv = require('uv')

local yield, resume, running = coroutine.yield, coroutine.resume, coroutine.running
local insert,length,remove = table.insert, table.getn,table.remove



local Music = {}

function Music:init(disc,client)
	self.discordia = disc
	self.client = client
	self.voice = client.voice
	self.connection = {}
	self.lastTextChannel = nil

	self.queue = {}
	self.embedTypes = 
	{
	youtube = function(username,result)
			return { title = ("Pedido de música por " .. username), 
			fields = 
				{
					{name = "Título", value = result[1], inline = true},
					{name = "Duração", value = result[2], inline = true},
				},
			color = self.discordia.Color.fromRGB(114, 137, 218).value,
			timestamp = self.discordia.Date():toISO('T', 'Z')
			}
	end
	}
	self.client:on('playNext', self.handleNext)
end


function Music:getUrl(content)
	local url = "https://www.youtube.com/watch?v="
	local _, start = string.find(content,"v=")
	if not start then return false,content end
	local id = string.sub(content,start+1,start+11)
	return url .. id
end

function Music:addToQueue(url,requester,info,channel, voiceChannel)
	insert(self.queue,{info = info, channel =  channel, voiceChannel = voiceChannel, url = url, requester = requester})
	if length(self.queue)==1 then return length(self.queue), self.client:emit('playNext')
	else return length(self.queue) end
end

function Music:inform(author,info,channel)
	channel:send{embed = self.embedTypes.youtube(author.username,info)}
	self.lastTextChannel = channel
end

function Music:getInformation(url)
	local result = {}
	
	local stderr = 1
	local stdout = uv.new_pipe(false)

	local child = uv.spawn('youtube-dl', {
			args = {url,'--get-duration','--get-title'},
			stdio = {0, stdout, stderr}
	}, onExit)

	local thread = running()
		stdout:read_start(function(err, chunk)
			if not chunk then
				child:kill()
				stdout:read_stop()
				stdout:close()
				assert(resume(thread))
			elseif #chunk > 0 then
				table.insert(result,chunk)
			elseif err then
			end
	end)
	yield()
	return result,stderr
end


function Music:handleNext()
	self = Music

	local connection = self.connection
	if connection.conn and connection.conn.state then return false end

	local nextQ = remove(self.queue,1)

	if not nextQ then
		if connection.conn then
			connection.conn:close()
			connection.conn = nil
			self.lastTextChannel:send("`No more entries in queue, closing voice connections`") 
			return false 
		end 
	else
		local requester = nextQ.requester
		local url = nextQ.url
		local info = nextQ.info
		local channel = nextQ.channel
		local voiceChannel = nextQ.voiceChannel
		--We test if there is already a connection and if its the same as the requested voice channel
		if connection.conn and connection.voiceChannel == voiceChannel then
			self:inform(requester,info,channel)
			connection.conn:playYoutube(url)
			--If we don't have a voice connection we create a new one on the requested voice channel
		elseif not connection.conn then
			local temp = voiceChannel:join()
			if self.client:waitFor('voiceReady') then
				connection.conn = temp
				connection.voiceChannel = voiceChannel
				self:inform(requester,info,channel)
				connection.conn:playYoutube(url)
			else channel:send("`Error: could not create a connection to voice server`") end
		--If we ahve a connection and it is not the same as the requested voice channel we close it and open a new one
		elseif connection.conn and connection.voiceChannel ~= voiceChannel then
			connection.conn:close()
			local temp = voiceChannel:join()
			if self.client:waitFor('voiceReady') then
				connection.conn = temp
				connection.voiceChannel = voiceChannel
				self:inform(requester,info,channel)
				connection.conn:playYoutube(url)
			else channel:send("`Error: could not create a connection to voice server`") end
		else
			channel:send("`Error: This should NEVER happen`")
		end
	end
end


function Music:skip()
	if self.connection.conn then self.connection.conn:stop() return true
	else return false end
end


return Music