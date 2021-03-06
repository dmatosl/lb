-- GET /v1/list

-- load shared dict
local dict = ngx.shared.upstream

-- load redis settings
local redis_host = ngx.var.redis_host
local redis_port = ngx.var.redis_port
local redis_idle = ngx.var.redis_idle
local redis_pool_size = ngx.var.redis_pool_size
local redis_timeout = ngx.var.redis_timeout

local host = ngx.var.host

-- check host header
if not host then
	ngx.log(ngx.INFO, "Host not provided, assuming default")
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

local members, err = red:smembers("s:" .. host)
for key,value in pairs(members) do
	--ngx.say("redis: " .. key .. "=" .. value )
	ngx.say("shared_dict: " .. dict:get("s:" .. host .. ":" .. key))
		--.. ", shared_dict_ip: " .. dict:get("s:" .. host .. ":" .. key ) .. ", shared_dict_id: " .. dict:get("s:" .. host .. ":" .. value ))
	--ngx.say("shared_dict: " .. key .. "=" .. dict:get("s:" .. host .. ":" .. key ))
end
ngx.say("count: " .. red:scard("s:" .. host))
--ngx.say("count: " .. dict:get("s:" .. host .. ":count" ))

-- put connection back to pool
local ok, err = red:set_keepalive(redis_idle,redis_pool_size)
if not ok then
	ngx.log(ngx.ERR,"failed to set_keepalive: ", err)
end
