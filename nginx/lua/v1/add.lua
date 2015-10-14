-- GET /v1/add?ip=10.x.x.x

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
local ok, err = red:sadd("s:" .. host , ip .. ":" .. port)
if not ok then
    ngx.log(ngx.ERR, "unable to set upstream: ", err)
    ngx.exit(500)
end

-- update members count in shared dict
local count, err = red:scard("s:" .. host)
if count > 0 then
	local ok, err = dict:set("s:" .. host .. ":count", count)
	local ok, err = dict:set("s:" .. host .. ":" .. count, ip .. ":" .. port)
    local ok, err = dict:set("s:" .. host .. ":" .. ip .. ":" .. port, count)
end

-- put connection back to pool
local ok, err = red:set_keepalive(redis_idle,redis_pool_size)
if not ok then
	ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
	ngx.exit(500)
end

ngx.say('{ "operation_status" : "sucess" }')
