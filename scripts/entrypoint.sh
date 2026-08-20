#!/bin/sh
set -e

panic() {
  echo "PANIC: $1" >&2
  exit 1
}

for dir in /config /etc/nginx/certs; do
  if ! mountpoint -q "$dir"; then
    panic "Critical volume not mounted at $dir" >&2
  fi
done

if [ ! -f /config/proxy.yaml ]; then
  panic "/config/proxy.yaml does not exist" >&2
fi

make -C /build all > /dev/null

echo "Starting nginx..."
exec nginx -g 'daemon off;'