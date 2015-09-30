-- load redis settings
local redis_host = ngx.var.redis_host
local redis_port = ngx.var.redis_port
local redis_idle = ngx.var.redis_idle
local redis_pool_size = ngx.var.redis_pool_size
local redis_timeout = ngx.var.redis_timeout

-- simple http_host validation
local host = ngx.var.host
local ip = ngx.var.arg_ip

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
local ok, err = red:sadd("s:" .. host , ip)
if not ok then
    ngx.log(ngx.ERR, "unable to set upstream: ", err)
end

-- put connection back to pool
local ok, err = red:set_keepalive(redis_idle,redis_pool_size)
if not ok then
	ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
end

ngx.say('{ "operation_status" : "sucess" }')
