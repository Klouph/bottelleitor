local insert,getn,remove = table.insert,table.getn,table.remove

local Events = {}

function Events.onMessage(msg)
	--Check if its a command, if it is then attempt to run it
	if msg.author.bot then return end
	local st = msg.content:find(Events._Prefix)
	if not st or not st == 1 then return print("Didn't find prefix")
	else
		local args = {}
		for k in msg.content:gmatch("%g+") do
			insert(args,k)
		end
		args.msg = msg
		local s,e = Commands:Run(remove(args,1):gsub(Events._Prefix,""),args)
	end
end


function Events:__init()
	if _G.dev then self._Prefix = Constants.cdev_Prefix else self._Prefix = Constants.c_Prefix end
	return Events
end


return Events:__init()