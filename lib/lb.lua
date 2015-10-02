local _M = {}

-- dict keys:
 -- s:host:count
   -- number of upstreams for a given host
 -- s:host:index
   -- 1 to n
 -- s:host:ip
   -- index:status:healthcheck_uri:interval:

function _M.getNextUpstream(host, dict, red)

	local upstream, err = dict:get("s:" .. host .. ":next_upstream")

	if upstream == nil then
		ngx.log(ngx.ERR, "next_upstream not found on shared dict, loading random upstream from redis: " .. host)
		local up, err = red:srandmember("s:" .. host )
		return up
	end

	return upstream
	-- end
end

function _M.updateNextUpstream(host, dict ,red)

	local count_upstream, err = dict:get("s:" .. host .. ":count")

	if count_upstream == nil then
		
		ngx.log(ngx.ERR, "count key not found on shared dict upstream, loading from redis: " .. host)
		count_upstream, err = red:scard("s:" .. host)

		if count_upstream == 0 then
			ngx.log(ngx.ERR, "count key not found on redis, aborting: " .. host)
			ngx.exit(500)
			return
		end

		dict:add("s:" .. host .. ":count", count_upstream)
		
	end

	local index = dict:incr("s:" .. host .. ":index",1)

	if index == nil then 
		ngx.log(ngx.INFO, "unable to incr key index. Not found on shared dict, adding index : " .. host)
		dict:add("s:" .. host .. ":index", 1)
		index = 1
	end

	if dict:get("s:" .. host .. ":index" ) > count_upstream then
		ngx.log(ngx.INFO,"reseting index: " .. host .. ", index: " .. index .. ", count:" .. count_upstream)
		index = 1
		dict:set("s:" .. host .. ":index", 1)
	end

	local upstream, err = dict:get("s:" .. host .. ":" .. index )

	if upstream == nil then
		ngx.log(ngx.INFO,"upstream not found on shared dict, loading from redis, " .. host .. " index: " .. index)
		local up, err = red:smembers("s:" .. host)
		upstream = up[index]
		dict:add("s:" .. host .. ":" .. index, upstream)
	end

	local ok, err = dict:set("s:" .. host .. ":next_upstream", upstream)

	if not ok then
		dict:add("s:" .. host .. ":next_upstream", upstream)
	end

	return

end

return _M