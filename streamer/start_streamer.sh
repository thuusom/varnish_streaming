#!/bin/bash

docker stop nginx-hls
docker container rm nginx-hls
docker run --name nginx-hls \
  -p 8080:80 \
  -v $(pwd):/usr/share/nginx/html:ro \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  -d nginx