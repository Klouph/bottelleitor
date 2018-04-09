--[[
	UTILS FOR MY OWN USAGE
--]]


local constant = dofile("bottelleitor/BotteleitorRelease/bot/Config/constant.lua")


--This function breaks down strings into words that are then placed inside a table
function stringToTable(arg)
	local tempTable = {}
	for string in string.gmatch(arg,"%a+") do
		table.insert(tempTable,string)
	end
	return tempTable
end

--Here we check if this is a command string we return a table with the needed arguments to call a command
function isCommand(arg)
	local test = string.find(arg,constant.COMMAND_PREFIX)
	if test == 1 then 
		local table = stringToTable(arg)
		return stringToTable(arg)
	else
		return false
	end
end

