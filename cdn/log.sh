#!/bin/bash

# Get log output. Varnish doesn't write to a log file but to memory for speed!
docker exec -it varnish-cache varnishlog | grep VCL_Log

# Apache access log format (no std.log output!)
#docker exec -it varnish-cache varnishncsa 
