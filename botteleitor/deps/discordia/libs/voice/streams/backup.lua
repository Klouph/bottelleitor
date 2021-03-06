--[[local PCMString = require('voice/streams/PCMString')
local PCMGenerator = require('voice/streams/PCMGenerator')
local FFmpegProcess = require('voice/streams/FFmpegProcess')
local YoutubeProcess = require('voice/streams/youtube')

local uv = require('uv')
local ffi = require('ffi')
local constants = require('constants')

local CHANNELS = 2
local SAMPLE_RATE = 48000 -- Hz

local MIN_BITRATE = 8000 -- bps
local MAX_BITRATE = 128000 -- bps
local MIN_DURATION = 5 -- ms
local MAX_DURATION = 60 -- ms
local MIN_COMPLEXITY = 0
local MAX_COMPLEXITY = 10

local MAX_SEQUENCE = 0xFFFF
local MAX_TIMESTAMP = 0xFFFFFFFF

local HEADER_FMT = '>BBI2I4I4'
local PADDING = string.rep('\0', 12)

local MS_PER_NS = 1 / (constants.NS_PER_US * constants.US_PER_MS)
local MS_PER_S = constants.MS_PER_S

local min, max = math.min, math.max
local band = bit.band
local hrtime = uv.hrtime
local ffi_string = ffi.string
local pack = string.pack -- luacheck: ignore

-- timer.sleep is redefined here to avoid a memory leak in the luvit module
local function sleep(delay)
	local thread = coroutine.running()
	local t = uv.new_timer()
	t:start(delay, 0, function()
		t:stop()
		t:close()
		return assert(coroutine.resume(thread))
	end)
	return coroutine.yield()
end

local function check(n, mn, mx)
	n = tonumber(n)
	return n and min(max(n, mn), mx)
end

local key_t = ffi.typeof('const unsigned char[32]')

local VoiceConnection, get = require('class')('VoiceConnection')

function VoiceConnection:__init(key, socket)

	self._key = key_t(key)

	self._socket = socket
	self._ip = socket._ip
	self._port = socket._port
	self._udp = socket._udp
	self._state = socket._state
	self._manager = socket._manager
	self._client = socket._client
	self._occupied = false

	self._seq = 0
	self._timestamp = 0

	self._encoder = self._manager._opus.Encoder(SAMPLE_RATE, CHANNELS)

	local options = self._client._options
	self:setBitrate(options.bitrate)
	self:setFrameDuration(options.frameDuration)
	self:setComplexity(5)
    
    print("created connection")
	self._manager:setConnection(self)
end

function VoiceConnection:getBitrate()
	return self._encoder:get(self._manager._opus.GET_BITRATE_REQUEST)
end

function VoiceConnection:setBitrate(bitrate)
	bitrate = check(bitrate, MIN_BITRATE, MAX_BITRATE)
	if bitrate then
		return self._encoder:set(self._manager._opus.SET_BITRATE_REQUEST, bitrate)
	end
end

function VoiceConnection:getFrameDuration()
	return self._frame_duration
end

function VoiceConnection:setFrameDuration(duration)
	duration = check(duration, MIN_DURATION, MAX_DURATION)
	if duration then
		self._frame_duration = duration
	end
end

function VoiceConnection:getComplexity()
	return self._encoder:get(self._manager._opus.GET_COMPLEXITY_REQUEST)
end

function VoiceConnection:setComplexity(complexity)
	complexity = check(complexity, MIN_COMPLEXITY, MAX_COMPLEXITY)
	if complexity then
		return self._encoder:set(self._manager._opus.SET_COMPLEXITY_REQUEST, complexity)
	end
end

---- debugging
local start = 10
local t0, m0
local t_sum, m_sum, n = 0, 0, 0
local function open()
	collectgarbage()
	m0 = collectgarbage('count')
	t0 = hrtime()
end
local function close()
	local dt = ((hrtime() - t0) * MS_PER_NS)
	local dm = (collectgarbage('count') - m0)
	n = n + 1
	if n > start then
		t_sum = t_sum + dt
		m_sum = m_sum + dm
		print(dt, dm, t_sum / (n - start), m_sum / (n - start))
	end
end
---- debugging

function VoiceConnection:_play(stream, duration)
	self._shouldstop = false
	self._occupied = true
	self._socket:setSpeaking(true)

	duration = tonumber(duration) or math.huge

	local elapsed = 0
	local udp, ip, port = self._udp, self._ip, self._port
	local ssrc, key = self._state.ssrc, self._key
	local encoder = self._encoder
	local encrypt = self._manager._sodium.encrypt

	local frame_duration = self._frame_duration
	local frame_size = SAMPLE_RATE * frame_duration / MS_PER_S
	local pcm_len = frame_size * CHANNELS

	local t = hrtime()

	while elapsed < duration do
		if self._shouldstop then stream:close() self._occupied = false break end
		local pcm = stream:read(pcm_len)
		if not pcm then self._occupied = false break end

		local data, len = encoder:encode(pcm, pcm_len, frame_size, pcm_len * 2)
		if not data then self._occupied = false break end

		local seq = self._seq
		local timestamp = self._timestamp

		local header = pack(HEADER_FMT, 0x80, 0x78, seq, timestamp, ssrc)

		self._seq = band(seq + 1, MAX_SEQUENCE)
		self._timestamp = band(timestamp + frame_size, MAX_TIMESTAMP)

		local encrypted, encrypted_len = encrypt(data, len, header .. PADDING, key)
		if not encrypted then self._occupied = false break end

		udp:send(header .. ffi_string(encrypted, encrypted_len), ip, port)

		elapsed = elapsed + frame_duration
		sleep(max(elapsed - (hrtime() - t) * MS_PER_NS, 0))
	end

	self._socket:setSpeaking(false)

end

function VoiceConnection:stop()
	self._shouldstop = true
end

function VoiceConnection:isOccupied()
	return self._occupied
end

function VoiceConnection:playPCM(source, duration)

	if self._closed then
		return nil, 'Cannot play audio on a closed connection'
	end

	local stream
	if type(source) == 'string' then
		stream = PCMString(source)
	elseif type(source) == 'function' then
		stream = PCMGenerator(source)
	end

	return self:_play(stream, duration)

end

function VoiceConnection:playFFmpeg(path, duration)

	if self._closed then
		return nil, 'Cannot play audio on a closed connection'
	end

	local stream = FFmpegProcess(path, SAMPLE_RATE, CHANNELS)
	self:_play(stream, duration)
	return stream:close()

end

function VoiceConnection:playYoutube(url)
--Takes url returns stream
	if self._closed then
		return nil, 'Cannot play audio on a closed connection'
	end

	local stream = YoutubeProcess(url, SAMPLE_RATE, CHANNELS)
	self:_play(stream, duration)
	return stream:close()
end

function VoiceConnection:close()
	local guild = self.guild
	self._client._shards[guild.shardId]:updateVoice(guild._id)
	return self._socket:disconnect()
end

function get.channel(self)
	local guild = self.guild
	return guild and guild._voice_channels:get(self._state.channel_id)
end

function get.guild(self)
	return self._client._guilds:get(self._state.guild_id)
end

return VoiceConnection--]]
