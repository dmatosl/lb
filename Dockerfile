FROM 3scale/openresty
ADD supervisor/openresty.conf /etc/supervisor/conf.d/
ADD nginx /var/www
ADD redis /etc/redis

CMD ["supervisord"]
