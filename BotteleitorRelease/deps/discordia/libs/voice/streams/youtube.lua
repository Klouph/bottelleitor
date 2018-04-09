local uv = require('uv')

local remove = table.remove
local unpack = string.unpack -- luacheck: ignore
local rep = string.rep
local yield, resume, running = coroutine.yield, coroutine.resume, coroutine.running

local function onExit() end

local fmt = setmetatable({}, {
	__index = function(self, n)
		self[n] = '<' .. rep('i2', n)
		return self[n]
	end
})

local YoutubeProcess = require('class')('YoutubeProcess')


function YoutubeProcess:__init(url, rate, channels)

	self._stdout = uv.new_pipe(false)
	self._stdin = uv.new_pipe(false)

	self._child = uv.spawn('youtube-dl', {
		args = {url,'-q','-f','m4a','-o','-'},
		stdio = {0, self._stdin, 2}
	}, onExit)

	self._child2 = uv.spawn('ffmpeg',{
		args = {'-i','pipe:0','-ar', rate, '-ac', channels, '-f', 's16le', 'pipe:1', '-loglevel', 'warning'},
		stdio = {self._stdin,self._stdout,2}
		}, onExit)

	self._buffer = ''

end

function YoutubeProcess:read(n)

	local buffer = self._buffer
	local stdout = self._stdout
	local bytes = n * 2

	if not self._eof and #buffer < bytes then

		local thread = running()
		stdout:read_start(function(err, chunk)
			if err or not chunk then
				self._eof = true
				self:close()
				return assert(resume(thread))
			elseif #chunk > 0 then
				buffer = buffer .. chunk
			end
			if #buffer >= bytes then
				stdout:read_stop()
				return assert(resume(thread))
			end
		end)
		yield()

	end

	if #buffer >= bytes then
		self._buffer = buffer:sub(bytes + 1)
		local pcm = {unpack(fmt[n], buffer)}
		remove(pcm)
		return pcm
	end

end

function YoutubeProcess:close()
	self._child:kill()
	self._child2:kill()
	if not self._stdout:is_closing() then
		self._stdout:close()
	end
end

return YoutubeProcess
