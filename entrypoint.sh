#!/bin/sh
# Tyler-Computer skin proxy entrypoint.
#
# Why this exists: Railway's container runtime gives each container its own
# /etc/resolv.conf with the project's internal DNS server. nginx's `resolver`
# directive cannot use $env vars directly — we have to patch them into the
# config at startup.
#
# Read /etc/resolv.conf, extract every `nameserver X` line, render them into
# nginx.conf wherever the literal placeholder `__RESOLVERS__` appears, then
# exec nginx.
#
# After this script runs, nginx.conf has a real `resolver 100.64.0.1 ...;`
# line and the dynamic $upstream variable works — TC-Skin survives LibreChat
# redeploys without needing its own redeploy.

set -e

# nginx resolver syntax requires IPv6 addresses to be wrapped in brackets
# (e.g. `[fd12::10]`), but /etc/resolv.conf lists them bare (`fd12::10`).
# Wrap any address that contains a colon (IPv6) and leave IPv4 alone.
RESOLVERS=$(grep -E "^nameserver " /etc/resolv.conf | awk '{print $2}' | while read -r addr; do
  case "$addr" in
    *:*) echo "[$addr]" ;;
    *)   echo "$addr" ;;
  esac
done | tr '\n' ' ' | sed 's/ $//')

if [ -z "$RESOLVERS" ]; then
  echo "[entrypoint] WARNING: /etc/resolv.conf has no nameserver entries. Falling back to 1.1.1.1." >&2
  RESOLVERS="1.1.1.1"
fi

echo "[entrypoint] Using resolvers from /etc/resolv.conf: $RESOLVERS" >&2

# In-place substitute. sed -i is fine because /etc/nginx/nginx.conf is in
# the image layer (not a volume).
sed -i "s|__RESOLVERS__|$RESOLVERS|g" /etc/nginx/nginx.conf

exec nginx -g 'daemon off;'
