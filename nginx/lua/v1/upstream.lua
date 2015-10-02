-- GET /

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

if not host then
    ngx.log(ngx.INFO, "HTTP Host not provided, assuming default")
    host = "default"
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
local lb = require "lb"
local up = lb.getNextUpstream(host, dict, red)
lb.updateNextUpstream(host, dict, red)

-- put connection back to pool
local ok, err = red:set_keepalive(redis_idle,redis_pool_size)
if not ok then
	ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
end

-- return upstream var
ngx.var.upstream = up
