FROM 3scale/openresty
ADD supervisor/openresty.conf /etc/supervisor/conf.d/
ADD rate /opt/openresty/lualib/resty/rate/
ADD lib /opt/openresty/lualib/
ADD nginx /var/www
ADD redis /etc/redis

CMD ["supervisord"]
