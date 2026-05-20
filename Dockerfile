# Tyler-Computer Editorial Defiant skin — nginx reverse proxy that injects
# our custom CSS into every LibreChat HTML response.
#
# Origin: ghcr.io/danny-avila/librechat-dev:latest (unchanged, running on Railway)
# Proxy: this nginx receives all family traffic, inserts <link> tags for
#        Fraunces+Source Serif fonts and our tc-skin.css, then forwards
#        everything to the LibreChat service via Railway's private network.
#
# Iterate by editing tc-skin.css + redeploying — no client rebuild needed.

FROM nginx:1.27-alpine

# Need sub_filter (built into mainline nginx) — confirm by checking conf later.
COPY nginx.conf       /etc/nginx/nginx.conf
COPY tc-skin.css      /usr/share/nginx/html/tc-skin.css
COPY tc-head-inject.html /usr/share/nginx/html/tc-head-inject.html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
