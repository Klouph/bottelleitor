local discordia = require('discordia')
--We should handle all interactivities here aside from message receiving and handling!
--[[
	TODO:
	Handle reactions to messages and shit

--]]

local getn, insert = table.getn,table.insert

local Response = {
	embeds = 
	{
	keyValueList = function(title,list)
		embed = 
		{
   			title = title,
    		color = discordia.Color.fromRGB(114, 137, 218).value,
    		fields = {},
    		timestamp = discordia.Date():toISO('T', 'Z')
  		}
  		for k,v in pairs(list) do
			insert(embed.fields,{name=k, value = v})
		end
  		return embed
  	end
	}
}





function Response.__init()
	return Response
end



return Response.__init()