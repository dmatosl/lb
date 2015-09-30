Description: Dinamic Load Balancer API on Top of Nginx, LUA and Redis (openresty)

USAGE:
Build docker image
  docker build -t dml/lb .
  docker run  --name lb --rm -i -p 80:8080 -t dml/lb


ADD New upstream
    curl -h 'Host: foo.bar' http://$(docker-machine ip YOUR_BOX)/v1/api/add?ip=10.0.0.1

Expected output:
{ "operation_status" : "success" }
