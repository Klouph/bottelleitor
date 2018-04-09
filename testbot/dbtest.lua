local connect = require('coro-postgres').connect

local p = require('pretty-print').prettyPrint
local getenv = require('os').getenv
local wrap,running,yield,resume = coroutine.wrap,coroutine.running,coroutine.yield,coroutine.resume
local gsub,find = string.gsub,string.find


wrap(function()
	local dburl = getenv('DATABASE_URL') or "postgres://zqbavvbxcaplap:20989da44b9fc665da890c5c927a378ca6668f95a64fcddd937e698961090b4c@ec2-54-83-19-244.compute-1.amazonaws.com:5432/d88pn543duiueq"

	--local username = gsub(dburl,"%/(%a+):")
	--local password = gsub(dburl,"%:")


	--[[local psql = assert(connect({
		database = "d88pn543duiueq",
		username = "zqbavvbxcaplap",
		password = "20989da44b9fc665da890c5c927a378ca6668f95a64fcddd937e698961090b4c",
		tls = true,
		host = "ec2-54-83-19-244.compute-1.amazonaws.com"
	}))]]
	--

	local psql = assert(pgmoon.new({
		host = "localhost",
		port = "5432",
		database = "postgres",
		password = "salmos11891"
		}))
	p(psql:connect())
	p(psql:query("SELECT version();"))
    psql.close()
end)()