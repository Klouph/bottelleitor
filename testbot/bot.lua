local fs = require('fs')
local joinpath = require('pathjoin')
local discordia = require('discordia')
local Profiler = require('utils/Profiler')

local client = discordia.Client()
local logger = discordia.Logger(3, '%F %T')
local enums = discordia.enums


local insert,getn = table.insert,table.getn
local readFileSync,scanDirSync = fs.readFileSync,fs.scandirSync
local joinPath = joinpath.pathJoin

_G["dev"] = true

local env = setmetatable({
	require = require,
	},{__index=_G})


local function loadModules(path)
	local files = {}
	--Scan modules file in path
	for k,v in scanDirSync(path) do
		if k:find('.lua',-4) then
			insert(files,k)
		end
	end
	--Iterate through files and try to load them
	for _,v in pairs(files) do
		local prf = Profiler:start()
		prf()
		local n = v:gsub(".lua","")
		local s,e = pcall(function()
				local data = assert(readFileSync(joinPath(path,v)))
				local code = assert(loadstring(data,n))
				setfenv(code,env)
				_G[n] = code()
			end)
		if s then logger:log(enums.logLevel.info,"[Module] Loaded ".. n.. " in " ..prf.stop() .."s") else logger:log(enums.logLevel.error,"[Module] Failed to load " .. v .. " with error : \n" .. e) end 
	end
end



coroutine.wrap(function()
local prf = Profiler:start()
prf()
loadModules("./modules")
client:on("messageCreate", Events.onMessage)
if not _G.dev then client:run('Bot '..Constants.Token) else client:run('Bot '..Constants.dev_Token) end
logger:log(enums.logLevel.info,("Time spent to load bot " .. prf.stop().. "s"))
end)()