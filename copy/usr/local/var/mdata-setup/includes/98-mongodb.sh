#!/bin/bash

if /native/usr/sbin/mdata-get mongodb_url 1>/dev/null 2>&1; then
  MONGO_URL=$(/native/usr/sbin/mdata-get mongodb_url)
  sed -i \
       -e "s#Environment=MONGO_URL=mongodb://127.0.0.1:27017/rocket#Environment=MONGO_URL=${MONGO_URL}#" \
       /etc/systemd/system/rocketchat.service
else
  systemctl start mongodb
  echo 'rs.initiate()' | mongo
fi
