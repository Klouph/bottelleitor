--[[
	UTILS FOR MY OWN USAGE
--]]

--HERE WE IMPORT STUFF
local constant = dofile("bot/Config/constant.lua")

local Utils = {}

--This function breaks down strings into words that are then placed inside a table
function Utils:stringToTable(arg)
	local tempTable = {}
	for string in string.gmatch(arg,"%a+") do
		table.insert(tempTable,string)
	end
	return tempTable
end

--Here we check if this is a command string we return a table with the needed arguments to call a command
function Utils:isCommand(arg)
	local test = string.find(arg,constant.COMMAND_PREFIX)
	if test == 1 then 
		return self:stringToTable(arg)
	else
		return false
	end
end
--Deep print
function Utils:printTable(table,simple,limit)
	if not limit then limit = 3 end

	if type(table) ~= "table" then print(type(table)) return false end
	for k,v in pairs(table) do
		if simple then 
			if type(table[k]) == type(table) then
				if limit == 0 then 
					return true 
				else 
					limit = limit -  1
					self:printTable(table[k],false,limit) 
				end
				print(k,v)
			end
		else
			print(k,v)
		end
	end
end

return Utils