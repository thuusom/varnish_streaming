# Varnish Streaming Sample Project

This project demonstrates how to set up a simple HTTP Live Streaming (HLS) server using **NGINX** and configure **Varnish Cache** as a Content Delivery Network (CDN) to cache and serve streaming content efficiently.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup and Running](#setup-and-running)
  - [1. Start the Streamer](#1-start-the-streamer)
  - [2. Start the CDN](#2-start-the-cdn)
- [Testing the Setup](#testing-the-setup)
  - [Understanding Cache Headers](#understanding-cache-headers)
  - [Test Commands](#test-commands)
- [Viewing Logs](#viewing-logs)
  - [Streamer Logs](#streamer-logs)
  - [CDN Logs](#cdn-logs)
- [Configuration Details](#configuration-details)
  - [NGINX Configuration](#nginx-configuration)
  - [Varnish Configuration](#varnish-configuration)
- [Advanced Topics](#advanced-topics)
  - [Memory and Disk Space Usage in Varnish](#memory-and-disk-space-usage-in-varnish)
  - [Separating App Server and Streaming Server Caching](#separating-app-server-and-streaming-server-caching)
  - [Health Checks with VCL Probes](#health-checks-with-vcl-probes)
  - [Purging Cached Content](#purging-cached-content)
- [References](#references)

## Overview

The project consists of two main components:

- **Streamer**: An NGINX server serving HLS streaming content.
- **CDN**: A Varnish Cache server configured to cache streaming content efficiently.

The CDN caches segment files (`*.ts`) for faster delivery to clients while ensuring that manifest files (`*.m3u8`) are always fetched from the streamer to reflect the most recent playlist updates.

## Project Structure

```
.
|-- README.md
├── cdn
│   ├── default.vcl
│   ├── log.sh
│   └── start_cdn.sh
└── streamer
    ├── index.html
    ├── nginx.conf
    ├── start_streamer.sh
    └── stream
        ├── index.m3u8
        └── [HLS stream files...]
```

- **cdn/**: Contains Varnish Cache configuration and startup scripts.
- **streamer/**: Contains NGINX configuration, startup scripts, and HLS content.

## Prerequisites

- **Docker** installed on your system.
- Basic knowledge of command-line operations.
- An internet connection to download Docker images.

## Setup and Running

### 1. Start the Streamer

Navigate to the `streamer` directory and run the `fetch.sh` and the `start_streamer.sh` script:

```bash
cd streamer
./fetch.sh 
./start_streamer.sh
```

This does the following:

* Fetches a subset of the Apple HLS stream sample. Only needed once.
* Stops and removes any existing nginx-hls container.
* Starts a new NGINX container named nginx-hls.
* Maps port 8080 on the host to port 80 in the container.
* Mounts the current directory into the container’s web root (/usr/share/nginx/html).
* Uses the custom nginx.conf file provided.

### 2. Start the CDN

Navigate to the cdn directory and run the start_cdn.sh script:

```bash
cd ../cdn
./start_cdn.sh
```

This script does the following:

- Stops and removes any existing varnish-cache container.
- Starts a new Varnish Cache container named varnish-cache.
- Maps port 8090 on the host to port 80 in the container.
- Mounts the custom default.vcl configuration file into the container.

## Testing the Setup

After starting both the streamer and CDN, you can test the caching behavior using curl commands.

Understanding Cache Headers:

- -i Option in curl: Includes the HTTP response headers in the output.
- X-Cache Header: Custom header indicating whether the response was served from cache.
- X-Cache: cached means the content was served from Varnish Cache.
- X-Cache: uncached means the content was fetched from the backend streamer.

### Test Commands

#### 1. Access the Home Page (Should Not Be Cached):

```bash
curl -i http://localhost:8090/index.html
```

Expected Output:

- X-Cache: uncached
- The HTML content of index.html.

#### 2. Access the Main Manifest File (Should Not Be Cached):

```bash
curl -i http://localhost:8090/stream/index.m3u8
```

Expected Output:

- X-Cache: uncached
- The content of index.m3u8.

#### 3. Access a Variant Manifest File (Should Not Be Cached):

```bash
curl -i http://localhost:8090/stream/gear1/prog_index.m3u8
```

Expected Output:

- X-Cache: uncached
- The content of prog_index.m3u8.

#### 4. Access a Segment File (First Request, Not Cached):

```bash
curl -i http://localhost:8090/stream/gear1/main.ts
```

Expected Output:

- X-Cache: uncached
- Content-Length indicating the size of the .ts file.

#### 5. Access the Same Segment File Again (Should Be Cached):

```bash
curl -i http://localhost:8090/stream/gear1/main.ts
```

Expected Output:

- X-Cache: cached
- Age header indicating how long the content has been cached.

Note: The X-Cache header is added by Varnish in the vcl_deliver subroutine to indicate caching behavior.

## Viewing Logs

### Streamer Logs

To view the NGINX logs, you can access the logs inside the Docker container:

```bash
docker logs nginx-hls
```

### CDN Logs

To view Varnish Cache logs, use the log.sh script:

```bash
./log.sh
```

Note: Varnish doesn’t write logs to files by default. The varnishlog tool reads logs from shared memory.

## Configuration Details

### NGINX Configuration

File (nginx.conf):

- Configures NGINX to serve HLS content with the correct MIME types.
- Enables directory listing with autoindex on;.

### Varnish Configuration

File (default.vcl):

- Backend Definition: Points to the streamer running on host.docker.internal:8080.
- vcl_recv:
  - Logs incoming requests.
  - Determines caching strategy based on the request URL.
  - Does not cache manifest files (*.m3u8).

- vcl_backend_response:
  - Sets caching headers for segment files.
  - Ignores cache-busting headers from the backend.

- vcl_deliver:
  - Adds X-Cache header to indicate cache status.
  - Cleans up response headers for security.

## Advanced Topics

### Memory and Disk Space Usage in Varnish

By default, Varnish uses a small amount of memory for caching. You can configure the cache size using the -s option when starting Varnish.

#### Example (Start Varnish with 256MB Cache):

```bash
docker run -d -v $(pwd)/default.vcl:/etc/varnish/default.vcl:ro \
  -p 8090:80 \
  --name varnish-cache \
  varnish:latest \
  varnishd -f /etc/varnish/default.vcl \
  -s malloc,256m
  ```

- -s malloc,256m: Allocates 256MB of memory for caching.
- **Disk Storage**: You can also configure Varnish to use disk storage (-s file,/var/lib/varnish_storage.bin,1G) for larger cache sizes.

Reference: [Varnish Storage Backends](https://varnish-cache.org/docs/4.1/users-guide/storage-backends.html)

### Separating App Server and Streaming Server Caching

Resource Utilization: Streaming servers handle large amounts of data and require significant bandwidth and I/O capacity.

- Best Practice: Use separate caching nodes for app servers and streaming servers to optimize resource utilization and performance.
- App Server Caching: Often deals with smaller, dynamic content and may not require distributed caching.

### Health Checks with VCL Probes

You can configure Varnish to perform health checks on backend servers using probes.

Example (default.vcl):

```bash
backend default {
    .host = "host.docker.internal";
    .port = "8080";
    .probe = {
        .url = "/healthcheck";
        .interval = 5s;
        .timeout = 1s;
        .window = 5;
        .threshold = 3;
    }
```

- Varnish sends a request to /healthcheck every 5 seconds.
- If 3 out of 5 recent checks fail, the backend is marked as unhealthy.

#### Recovering from Backend Failure:
- Varnish can switch to a different backend if one becomes unhealthy.

Reference: [Varnish Probes Backends](https://varnish-cache.org/docs/4.1/users-guide/storage-backends.html)

### Purging Cached Content

To purge specific content from the cache, you can use the varnishadm tool.

#### Example (Purge Content Matching a URL):

```bash
docker exec -it varnish-cache varnishadm "ban req.url ~ /stream/gear1/main.ts"
````

- Purges any cached objects where the request URL matches /stream/gear1/main.ts.

Note: Purging requires access to the Varnish management interface.

Reference: [Varnish Cache Ban and Purge]()

## References

- [Varnish Cache Documentation]()
- [NGINX Documentation]()
- [HTTP Live Streaming (HLS) Overview]()
- [Varnish Configuration Language (VCL) Syntax]()


**Disclaimer**: This project is for educational purposes and should not be used in a production environment without proper security considerations.
