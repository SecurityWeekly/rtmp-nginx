#!/bin/bash
set -e

# Start nginx
echo "Creating config file from template:"
envsubst "$(env | awk -F = '{printf " $$%s", $$1}')" < /etc/nginx/nginx-rtmp.template > /etc/nginx/conf.d/nginx-rtmp.conf
envsubst "$(env | awk -F = '{printf " $$%s", $$1}')" < /etc/nginx/nginx-http.template > /etc/nginx/conf.d/nginx-http.conf
envsubst "$(env | awk -F = '{printf " $$%s", $$1}')" < /etc/nginx/nginx-https.template > /etc/nginx/conf.d/nginx-https.conf

echo "Starting Nginx:"
/usr/local/nginx/sbin/nginx -c /etc/nginx/nginx.conf -g "daemon off; error_log /dev/stderr info;"

status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start NGINX: $status"
  exit $status
fi
