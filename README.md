# Description
Nginx simple Load Balancer with dinamic Nginx Upstream configuration API on top of Openresty (Nginx, LUA and Redis).

# Usage:

## Build docker image
```
  docker build -t dmatosl/lb .
  docker run  --name lb --rm -i -p 80:8080 -t dmatosl/lb
```

## ADD New upstream
```
    curl -H 'Host: foo.bar' http://192.168.99.100/v1/add?ip=10.0.0.1
```

## REMOVE upstream
```
	curl -H 'Host: foo.bar' http://192.168.99.100/v1/rem?ip=10.0.0.1
```

## LIST upstreams for a given Host:
```
	curl -H 'Host: foo.bar' http://192.168.99.100/v1/list
```
