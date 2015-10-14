-- GET /v1/rem?ip=10.0.0.1

-- load shared dict
local dict = ngx.shared.upstream

-- load redis settings
local redis_host = ngx.var.redis_host
local redis_port = ngx.var.redis_port
local redis_idle = ngx.var.redis_idle
local redis_pool_size = ngx.var.redis_pool_size
local redis_timeout = ngx.var.redis_timeout

-- simple http_host validation
local host = ngx.var.host
local ip = ngx.var.arg_ip
local port = ngx.var.arg_port

-- check host header
if not host then
    ngx.log(ngx.INFO, "HTTP Host not provided, assuming default")
    host = "default"
end

-- check ip param
if not ip then
    ngx.log(ngx.ERR, "IP not provided")
    nginx.exit(500)
end

-- check port param
if not port then
    ngx.log(ngx.ERR, "Port not provided")
    nginx.exit(500)
end

-- init redis object
local redis = require "resty.redis"
local red = redis:new()
red:set_timeout(redis_timeout)

-- init redis connection
local ok,err = red:connect(redis_host,redis_port)
if not ok then
    ngx.log(ngx.ERR, "failed to connect to redis server: ", err)
    return
end

-- do work

local index = dict:get("s:" .. host .. ":" .. ip .. ":" .. port)
if index == nil then
	ngx.log(ngx.INFO, "key not found, ignoring: " .. host .. ", ip: " .. ip .. ":" .. port)
	return
end

dict:delete("s:" .. host .. ":" .. index)
dict:delete("s:" .. host .. ":" .. ip .. ":" .. port)
red:srem("s:" .. host , ip .. ":" .. port)

local lb = require "lb"
lb.updateUpstreamTable(host, dict , red)
lb.updateNextUpstream(host, dict, red)

-- put connection back to pool
local ok, err = red:set_keepalive(redis_idle,redis_pool_size)
if not ok then
	ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
end

ngx.say('{ "operation_status" : "sucess" }')
