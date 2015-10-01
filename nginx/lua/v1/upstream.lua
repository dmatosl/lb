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
local count_upstream, err = dict:get("s:" .. host .. ":count")

if count_upstream == nil then
	ngx.log(ngx.ERR, "count key not found on shared dict upstream: " .. host)
	ngx.exit(500)
end

local next_upstream, err = dict:incr("s:" .. host .. ":next_upstream", 1)

if not next_upstream and err == "not found" then
	dict:add("s:" .. host .. ":next_upstream", 0)
	next_upstream = dict:incr("s:" .. host .. ":next_upstream", 1)
end

if next_upstream > count_upstream then
	dict:set("s:" .. host .. ":next_upstream", 1)
	next_upstream = 1
end

local up, err = dict:get("s:" .. host .. next_upstream)
if err == "not found" then
	ngx.log(ngx.ERR, "upstream not found for " .. host)
end

-- put connection back to pool
local ok, err = red:set_keepalive(redis_idle,redis_pool_size)
if not ok then
	ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
end

-- return upstream var
ngx.var.upstream = up
