vcl 4.0;

import std;

backend default {
    # Backend server definition
    .host = "host.docker.internal";  # Use 'host.docker.internal' to refer to the host machine from within Docker
    .port = "8080";
}

# Called when a request is received
sub vcl_recv {
    # Log the received URL (view using 'varnishlog -i Std')
    std.log("Received " + req.url);

    if (req.method == "GET" && req.url ~ "^/stream/") {
        # Check if the URL ends with '.m3u8' (manifest files)
        # Regex explanation:
        # '\.m3u8$' matches any string that ends with '.m3u8'
        # - '\.' escapes the dot character
        # - 'm3u8' matches the literal string 'm3u8'
        # - '$' denotes the end of the string
        if (req.url ~ "\.m3u8$") {
            std.log("Not caching manifest file: " + req.url);
            return (pass);  # Do not cache manifest files
        } else {
            std.log("Caching: " + req.url);
            return (hash);  # Proceed to cache lookup and possible caching
        }
    } else {
        std.log("Not caching (outside /stream/): " + req.url);
        return (pass);  # Do not cache other requests
    }
}

# Called after receiving response from the backend
sub vcl_backend_response {
    if (beresp.status == 200) {
        if (bereq.url ~ "^/stream/" && bereq.url !~ "\.m3u8$") {
            # Cache files under '/stream/' that are not manifest files
            # Force caching by ignoring backend's Cache-Control headers
            unset beresp.http.Cache-Control;
            unset beresp.http.Pragma;
            unset beresp.http.Expires;

            set beresp.ttl = 1h;         # Cache for 1 hour
            set beresp.grace = 30s;      # Serve stale content for 30 seconds if backend is down

            std.log("Caching " + bereq.url + " with TTL " + beresp.ttl);
        } else {
            # Do not cache manifest files or other responses
            set beresp.ttl = 0s;
            std.log("Not caching " + bereq.url);
        }
    } else {
        # Do not cache non-200 responses
        set beresp.ttl = 0s;
    }
}

# Called before delivering the response to the client
sub vcl_deliver {
    # Use 'resp.hits' instead of 'obj.hits' in Varnish 4.x and later
    if (obj.hits > 0) {
        set resp.http.X-Cache = "cached";
    } else {
        set resp.http.X-Cache = "uncached";
    }

    # Remove unnecessary headers for security and cleanliness
    unset resp.http.X-Powered-By;
    unset resp.http.Server;
    unset resp.http.Via;
    # unset resp.http.X-Varnish;  # Uncomment to remove the X-Varnish header

    return (deliver);
}