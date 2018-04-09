local uv = require('uv')
local yield, resume, running = coroutine.yield, coroutine.resume, coroutine.running

local stdout = uv.new_pipe(false)

local child = uv.spawn('youtube-dl', {
		args = {'https://www.youtube.com/watch?v=G133kjKy91U','--get-duration','--get-title'},
		stdio = {0, stdout, 2}
}, onExit)

	local result = ''
	local thread = running()


	stdout:read_start(function(err, chunk)
		if err or not chunk then
			child:kill()
			if not stdout:is_closing() then stdout:close() end
			assert(resume(thread))
		elseif #chunk > 0 then
			result = result .. chunk
		end
	end)