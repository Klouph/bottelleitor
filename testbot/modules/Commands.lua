local fs = require('fs')
local pathjoin = require('pathjoin')
local discordia = require("discordia")

local readFileSync, scanDirSync = fs.readFileSync, fs.scandirSync
local insert,getn = table.insert,table.getn
local joinPath = pathjoin.pathJoin

local enums = discordia.enums
local logger = discordia.Logger(3, '%F %T')

local Commands = {}

function Commands:__init()
	self._cmds = self:loadCommands("./commands")
	return Commands
end

function Commands:loadCommands(path)
	local files = {}
	local commands = {}
	local time = 0
	--Scan modules file in path
	for k,v in scanDirSync(path) do
		if k:find('.lua',-4) then
			insert(files,k)
		end
	end
	--Iterate through files and try to load them
	for _,v in pairs(files) do
		local n = v:gsub(".lua","")
		local s,e = pcall(function()
				local data = assert(readFileSync(joinPath(path,v)))
				local code = assert(loadstring(data))
				setfenv(code,getfenv())
				local cmdObject = code()
				for _,v in ipairs(cmdObject.cmdNames) do
					commands[v] = cmdObject
				end
			end)
		if s then logger:log(enums.logLevel.info,"[Command] Loaded ".. n) else logger:log(enums.logLevel.error," .. [Command] Failed to load " .. v .. " with error : \n" .. e) end 
	end
	return commands
end

function Commands:Run(command, args)
	local s,e = pcall(function() self._cmds[command](args) end)
	if not s then logger:log(enums.logLevel.error," [Command] Failed calling command " .. command .. " with arguments \n" .. " with error \n" .. e) return args.msg:reply("`Could not find command, use help command for a list of commands`") end
end

return Commands:__init()