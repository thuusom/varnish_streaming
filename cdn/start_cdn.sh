#!/bin/bash
docker stop varnish-cache
docker container rm varnish-cache

docker run -d -v $(pwd)/default.vcl:/etc/varnish/default.vcl:ro -p 8090:80 --name varnish-cache varnish:latest

