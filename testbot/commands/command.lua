--COMMAND TEMPLATE
local Object = {
	name = "Command",
	usage = "No use, its just a template and should be disabled",
	cmdNames = {'command','template'}
}



function Object.callback(self,args)
	return args.msg:reply("Template for commands, without a reason to exist, It often gets depressed about its own existance. Either way, here is its usage: "..self.usage)
end

function Object:__init()
	setmetatable(Object,{__call = self.callback})
	return Object
end

return Object:__init()