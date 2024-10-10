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

├── README.md
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

- **cdn/**: Contains Varnish Cache configuration and startup scripts.
- **streamer/**: Contains NGINX configuration, startup scripts, and HLS content.

## Prerequisites

- **Docker** installed on your system.
- Basic knowledge of command-line operations.
- An internet connection to download Docker images.

## Setup and Running

### 1. Start the Streamer

Navigate to the `streamer` directory and run the `start_streamer.sh` script:

```bash
cd streamer
./start_streamer.sh
```

This script does the following:

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

* Stops and removes any existing varnish-cache container.
* Starts a new Varnish Cache container named varnish-cache.
* Maps port 8090 on the host to port 80 in the container.
* Mounts the custom default.vcl configuration file into the container.

## Testing the Setup

After starting both the streamer and CDN, you can test the caching behavior using curl commands.

Understanding Cache Headers

* -i Option in curl: Includes the HTTP response headers in the output.
* X-Cache Header: Custom header indicating whether the response was served from cache.
* X-Cache: cached means the content was served from Varnish Cache.
* X-Cache: uncached means the content was fetched from the backend streamer.

### Test Commands

1. Access the Home Page (Should Not Be Cached):

```bash
curl -i http://localhost:8090/index.html
```

Expected Output:
* X-Cache: uncached
* The HTML content of index.html.
