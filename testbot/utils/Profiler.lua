Profiler = {}


function Profiler:start()
	return setmetatable({stop = function() if sTime then return os.clock()-sTime else return print("Profiler not initialized") end},{__call = function() sTime = os.clock() end })
end

function Profiler:sleep(a)
	local t = os.clock()
	while os.clock() < t+a do
		print(os.clock().." " .. t+a)
	end
end


return Profiler